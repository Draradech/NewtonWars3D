class_name Space
extends Node3D

signal update_label(player: Player)

@export
var material: StandardMaterial3D

var time: float = -1
var player_id: int = -1
var planets: Dictionary[int, Planet]
var players: Dictionary[int, Player]
var shots: Dictionary[int, Shot]
var missileInput

var pot_init = false
func gpot(loc: Vector3) -> float:
	var pot: float = 0
	for planet: Planet in planets.values():
		var d: = (loc - planet.location).length()
		if d <= planet.radius:
			return -1
		pot += planet.mass / d
	return pot

func pot_eval():
	var sum: float = 0
	var num: int = 0
	var pots: PackedFloat32Array
	pots.resize(320000)
	var i: int = 0
	for x in range(-1200, 1200, 30):
		for y in range(-800, 800, 32):
			for z in range(-1200, 1200, 30):
				var loc = Vector3(x, y, z)
				var pot = gpot(loc)
				pots[i] = pot
				i += 1
				if pot > 0:
					num += 1
					sum += pot
	var pmax = 1.35 * sum / num
	var pmin = pmax - 10
	var mma: MultiMesh = $GPotBandAllow.multimesh
	var mmd: MultiMesh = $GPotBandDisallow.multimesh
	mma.instance_count = 320000
	mmd.instance_count = 320000
	i = 0
	var ia: int = 0
	var id: int = 0
	for x in range(-1200, 1200, 30):
		for y in range(-800, 800, 32):
			for z in range(-1200, 1200, 30):
				var loc = Vector3(x, y, z)
				var pot = pots[i]
				i += 1
				if pot > pmin:
					var xform = Transform3D()
					xform.origin = loc
					if pot < pmax:
						mma.set_instance_transform(ia, xform)
						ia += 1
					else:
						mmd.set_instance_transform(id, xform)
						id += 1
	mma.visible_instance_count = ia
	mmd.visible_instance_count = id
	pot_init = true

func _process(_delta: float) -> void:
	if get_parent().is_menu_open(): return
	if Input.is_action_just_pressed("clear"):
		for player: Player in players.values():
			for shot: Shot in player.shots:
				shot.queue_free()
				shots.erase(shot.mid)
			player.shots.clear()
	if Input.is_action_just_pressed("reset"):
		players[player_id].pitch = 0
		players[player_id].yaw = 0
		players[player_id].speed = 8
		get_parent().get_node("MissileInput").update_label(players[player_id])
	if Input.is_action_just_pressed("wire"):
		if get_tree().root.get_viewport().debug_draw == Viewport.DEBUG_DRAW_DISABLED:
			get_tree().root.get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		else: get_tree().root.get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	if Input.is_action_just_pressed("bandallow"):
		if not pot_init: pot_eval()
		$GPotBandAllow.visible = !$GPotBandAllow.visible
	if Input.is_action_just_pressed("banddisallow"):
		if not pot_init: pot_eval()
		$GPotBandDisallow.visible = !$GPotBandDisallow.visible

func prepare_frame():
	for shot: Shot in shots.values():
		if shot.render_live:
			shot.prepare_render(time)

func update_planet(pnid: int, loc: Vector3, rad: float):
	if not planets.has(pnid):
		planets.set(pnid, Planet.new(loc, rad, material))
		add_child(planets[pnid])
	else:
		planets[pnid].location = loc
		planets[pnid].radius = rad
	pot_init = false
	$GPotBandAllow.visible = false
	$GPotBandDisallow.visible = false

func update_player_pos(pyid: int, loc: Vector3, rad: float):
	if not players.has(pyid):
		var ply_mat: StandardMaterial3D = material.duplicate()
		ply_mat.albedo_color = Color(1, .5, 0) if pyid == player_id else Color(0, .5, 1)
		players.set(pyid, Player.new(loc, rad, pyid == player_id, ply_mat))
		add_child(players[pyid])
		if pyid == player_id: emit_signal("update_label", players[pyid])
	else:
		players[pyid].location = loc
		players[pyid].radius = rad

func set_my_pyid(pyid: int):
	player_id = pyid

func player_disconnect(pyid: int):
	players[pyid].queue_free()
	for os: Shot in players[pyid].shots:
		shots.erase(os.mid)
		os.queue_free()
	players.erase(pyid)

func new_shot(pyid: int, mid: int):
	var s = Shot.new(mid, players[pyid].material)
	if pyid != player_id: s.material.albedo_color *= .5
	if players[pyid].shots.size() > (Global.config["num_shots_self"] if pyid == player_id else Global.config["num_shots_other"]) - 1:
		var os = players[pyid].shots.pop_front()
		shots.erase(os.mid)
		os.queue_free()
	for sh: Shot in players[pyid].shots:
		sh.material.albedo_color *= .8
	players[pyid].shots.append(s)
	shots[mid] = s
	add_child(s)

func update_shot_pos(mid: int, ts: float, loc: Vector3):
	if shots.has(mid):
		shots[mid].timed_locations.append([ts, loc])

func ray_sphere_intersection(ray_origin: Vector3, ray_dir: Vector3, sphere_center: Vector3, sphere_radius: float) -> float:
	var oc: = ray_origin - sphere_center
	var a: = ray_dir.dot(ray_dir)
	var b: = 2.0 * oc.dot(ray_dir)
	var c: = oc.dot(oc) - sphere_radius * sphere_radius
	var discriminant: = b * b - 4 * a * c
	if discriminant < 0.0:
		return -1.0
	var t1: = (-b - sqrt(discriminant)) / (2.0 * a)
	var t2: = (-b + sqrt(discriminant)) / (2.0 * a)
	return min(t1, t2) if t1 >= 0 else (t2 if t2 >= 0 else -1.0)

func find_closest_intersection(ray_origin: Vector3, ray_dir: Vector3) -> Vector3:
	var closest_dist: float = INF
	var closest_object_center: = Vector3.INF
	# Check planets
	for planet: Planet in planets.values():
		var t = ray_sphere_intersection(ray_origin, ray_dir, planet.location, planet.radius + 1)
		if t > 0.0 and t < closest_dist:
			closest_dist = t
			closest_object_center = planet.location
	# Check players
	for player: Player in players.values():
		var t = ray_sphere_intersection(ray_origin, ray_dir, player.location, player.radius + 10)
		if t > 0.0 and t < closest_dist:
			closest_dist = t
			closest_object_center = player.location
	return closest_object_center
