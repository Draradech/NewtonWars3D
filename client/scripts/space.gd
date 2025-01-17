class_name Space
extends Node3D

signal update_label(player: Player, digit: int)

@export
var material: StandardMaterial3D

var time: float = -1
var player_id: int = -1
var planets: Dictionary[int, Planet]
var players: Dictionary[int, Player]
var shots: Dictionary[int, Shot]
var round_time: int

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

var digit: int = 0
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
		emit_signal("update_label", players[player_id], digit)
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
		if not shot.render_live:
			if shot.stale:
				shots.erase(shot.mid)
				shot.queue_free()
				for player in players.values():
					player.shots.erase(shot)
		else:
			shot.prepare_render(time)

func update_player_list():
	if not player_id in players: return
	var bbstring: = ""
	#bbstring += "[color=ff7f00]%s\n%.1f[/color]\n\n" % [players[player_id].pname, players[player_id].score]
	bbstring += "%s\n%.2f\n\n" % [players[player_id].pname, players[player_id].score]
	for pid in players:
		if pid == player_id: continue
		var player : Player = players[pid]
		#bbstring += "[color=007fff]%s\n%.1f[/color]\n\n" % [player.pname, player.score]
		bbstring += "%s\n%.2f\n\n" % [player.pname, player.score]
	get_parent().ui.get_node("PlayerList").text = bbstring

func update_player_name(pyid: int, pname: String):
	players[pyid].pname = pname
	update_player_list()

func update_player_score(pyid: int, score: float):
	players[pyid].score = score
	update_player_list()

func update_planet(pnid: int, loc: Vector3, rad: float):
	if not planets.has(pnid):
		planets.set(pnid, Planet.new(loc, rad, material))
		add_child(planets[pnid])
	else:
		var op = planets[pnid]
		planets.set(pnid, Planet.new(loc, rad, material))
		add_child(planets[pnid])
		op.queue_free()
	pot_init = false
	$GPotBandAllow.visible = false
	$GPotBandDisallow.visible = false

func update_player_pos(pyid: int, loc: Vector3, rad: float):
	if not players.has(pyid):
		var ply_mat: StandardMaterial3D = material.duplicate()
		ply_mat.albedo_color = Global.config["color_self"] if pyid == player_id else Global.config["color_other"]
		players.set(pyid, Player.new(loc, rad, pyid == player_id, ply_mat))
		add_child(players[pyid])
		if pyid == player_id: emit_signal("update_label", players[pyid], digit)
	else:
		players[pyid].location = loc
		players[pyid].radius = rad
	for os: Shot in players[pyid].shots.duplicate():
		if os.render_live:
			os.stale = true
		else:
			shots.erase(os.mid)
			players[pyid].shots.erase(os)
			os.queue_free()
	
func update_round_time(rt: int):
	if rt < 0 and round_time >= 0:
		var sbm = get_parent().ui.get_node("ScoreBoardMessage")
		var sb: RichTextLabel = sbm.get_node("VBox").get_node("ScoreBoard")
		var bb: = "Round Ended\n\n[table=2]\n"
		var sorted = players.values()
		sorted.sort_custom(func cmp(p1, p2): return p1.score > p2.score)
		for player: Player in sorted:
			bb += "[cell]%s  [/cell][cell] %.2f [/cell]\n" % [player.pname, player.score]
		bb += "[/table]"
		sb.text = bb
		sbm.visible = true
		get_tree().root.get_node("RootScene").reset_camera()
	round_time = rt
	get_parent().ui.get_node("RoundTime").text = "%s%02d:%02d" % ["-" if signi(round_time) < 0 else "", absi(round_time) / 60, absi(round_time) % 60]

func set_my_pyid(pyid: int):
	player_id = pyid

func player_disconnect(pyid: int):
	for os: Shot in players[pyid].shots:
		shots.erase(os.mid)
		os.queue_free()
	players[pyid].queue_free()
	players.erase(pyid)

func trim_and_recolor_shots():
	for pyid in players:
		var player: = players[pyid]
		var numshots = (Global.config["num_shots_self"] if pyid == player_id else Global.config["num_shots_other"])
		while player.shots.size() > numshots:
			var os = player.shots.pop_front()
			shots.erase(os.mid)
			os.queue_free()
		var i = player.shots.size() - 1
		for sh: Shot in player.shots:
			sh.material.albedo_color = player.material.albedo_color * pow(maxf(.7, pow(0.2, 1.0 / (numshots + 1))), i)
			i -= 1

func update_player_colors():
	for pyid in players:
		var player: = players[pyid]
		var color = (Global.config["color_self"] if pyid == player_id else Global.config["color_other"])
		player.material.albedo_color = color
		if pyid == player_id:
			player.pointer_h.material.albedo_color = color * 0.5
	trim_and_recolor_shots()
	emit_signal("update_label", players[player_id], digit)

func new_shot(pyid: int, mid: int):
	var s = Shot.new(mid, players[pyid].material)
	players[pyid].shots.append(s)
	shots[mid] = s
	trim_and_recolor_shots()
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

func _input(event: InputEvent) -> void:
	if player_id == -1: return
	if not players.has(player_id): return
	if get_parent().is_menu_open(): return
	var player = players[player_id]
	if not player: return
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT:
			for pl2 in players.values():
				pl2.name_label.visible = event.is_pressed()
		elif event.is_pressed():
			match(event.key_label):
				KEY_PAGEUP:
					digit += 1
				KEY_PAGEDOWN:
					digit -= 1
				KEY_UP:
					player.pitch += pow(10, digit)
				KEY_DOWN:
					player.pitch -= pow(10, digit)
				KEY_RIGHT:
					player.yaw += pow(10, digit)
				KEY_LEFT:
					player.yaw -= pow(10, digit)
				KEY_PLUS:
					player.speed += pow(10, digit)
				KEY_MINUS:
					player.speed -= pow(10, digit)
			digit = clampi(digit, -8, 2)
			emit_signal("update_label", player, digit)
