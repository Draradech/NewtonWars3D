class_name Space
extends Node3D

@export
var material: StandardMaterial3D

var time: float = -1
var player_id: int = -1
var planets: Dictionary[int, Planet]
var players: Dictionary[int, Player]
var shots: Dictionary[int, Shot]
var round_time: int

var ui: UiScene

var pot_init: = false
func gpot(loc: Vector3) -> float:
	var pot: float = 0
	for planet: Planet in planets.values():
		var d: = (loc - planet.location).length()
		if d <= planet.radius:
			return -1
		pot += planet.mass / d
	return pot

func pot_eval() -> void:
	var sum: float = 0
	var num: int = 0
	var pots: PackedFloat32Array
	@warning_ignore("return_value_discarded")
	pots.resize(320000)
	var i: int = 0
	for x in range(-1200, 1200, 30):
		for y in range(-800, 800, 32):
			for z in range(-1200, 1200, 30):
				var loc: = Vector3(x, y, z)
				var pot: = gpot(loc)
				pots[i] = pot
				i += 1
				if pot > 0:
					num += 1
					sum += pot
	var pmax: = 1.35 * sum / num
	var pmin: = pmax - 10
	var mmi3da: MultiMeshInstance3D = $GPotBandAllow
	var mmi3dd: MultiMeshInstance3D = $GPotBandDisallow
	var mma: MultiMesh = mmi3da.multimesh
	var mmd: MultiMesh = mmi3dd.multimesh
	mma.instance_count = 320000
	mmd.instance_count = 320000
	i = 0
	var ia: int = 0
	var id: int = 0
	for x in range(-1200, 1200, 30):
		for y in range(-800, 800, 32):
			for z in range(-1200, 1200, 30):
				var loc: = Vector3(x, y, z)
				var pot: = pots[i]
				i += 1
				if pot > pmin:
					var xform: = Transform3D()
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
	if ui.is_menu_open(): return
	if Input.is_action_just_pressed("clear"):
		for player: Player in players.values():
			for shot: Shot in player.shots:
				shot.queue_free()
				if not shots.erase(shot.mid):
					push_warning("trying to erase non-existent shot (clear)")
			player.shots.clear()
	if Input.is_action_just_pressed("reset"):
		players[player_id].pitch = 0
		players[player_id].yaw = 0
		players[player_id].speed = 8
		ui.missile_input.update_label(players[player_id], digit)
	if Input.is_action_just_pressed("wire"):
		if get_tree().root.get_viewport().debug_draw == Viewport.DEBUG_DRAW_DISABLED:
			get_tree().root.get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		else: get_tree().root.get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	if Input.is_action_just_pressed("bandallow"):
		var mmi3da: MultiMeshInstance3D = $GPotBandAllow
		if not pot_init: pot_eval()
		mmi3da.visible = !mmi3da.visible
	if Input.is_action_just_pressed("banddisallow"):
		var mmi3dd: MultiMeshInstance3D = $GPotBandDisallow
		if not pot_init: pot_eval()
		mmi3dd.visible = !mmi3dd.visible

func prepare_frame() -> void:
	for shot: Shot in shots.values():
		if not shot.render_live:
			if shot.stale:
				if not shots.erase(shot.mid):
					push_warning("trying to erase non-existent shot (stale, prepare_frame)")
				shot.queue_free()
				for player: Player in players.values():
					player.shots.erase(shot)
		else:
			shot.prepare_render(time)

func update_player_list() -> void:
	if not player_id in players: return
	var bbstring: = ""
	#bbstring += "[color=ff7f00]%s\n%.1f[/color]\n\n" % [players[player_id].pname, players[player_id].score]
	bbstring += "%s\n%.2f\n\n" % [players[player_id].pname, players[player_id].score]
	for pid in players:
		if pid == player_id: continue
		var player : Player = players[pid]
		#bbstring += "[color=007fff]%s\n%.1f[/color]\n\n" % [player.pname, player.score]
		bbstring += "%s\n%.2f\n\n" % [player.pname, player.score]
	ui.player_list.text = bbstring

func update_player_name(pyid: int, pname: String) -> void:
	players[pyid].pname = pname
	update_player_list()

func update_player_score(pyid: int, score: float) -> void:
	players[pyid].score = score
	update_player_list()

func update_planet(pnid: int, loc: Vector3, rad: float) -> void:
	if not planets.has(pnid):
		planets[pnid] = Planet.new(loc, rad, material)
		add_child(planets[pnid])
	else:
		var op: = planets[pnid]
		planets[pnid] = Planet.new(loc, rad, material)
		add_child(planets[pnid])
		op.queue_free()
	pot_init = false
	var mmi3da: MultiMeshInstance3D = $GPotBandAllow
	var mmi3dd: MultiMeshInstance3D = $GPotBandDisallow
	mmi3da.visible = false
	mmi3dd.visible = false

func update_player_pos(pyid: int, loc: Vector3, rad: float) -> void:
	if not players.has(pyid):
		var ply_mat: StandardMaterial3D = material.duplicate()
		ply_mat.albedo_color = Global.config["color_self"] if pyid == player_id else Global.config["color_other"]
		players[pyid] = Player.new(loc, rad, pyid == player_id, ply_mat)
		add_child(players[pyid])
		if pyid == player_id: ui.missile_input.update_label(players[pyid], digit)
	else:
		players[pyid].location = loc
		players[pyid].radius = rad
	for os: Shot in players[pyid].shots.duplicate():
		if os.render_live:
			os.stale = true
		else:
			if not shots.erase(os.mid):
				push_warning("trying to erase non-existent shot (stale, update_player_pos)")
			players[pyid].shots.erase(os)
			os.queue_free()
	
func update_round_time(rt: int) -> void:
	if rt < 0 and round_time >= 0:
		var bb: = "Round Ended\n\n[table=2]\n"
		var sorted: Array[Player] = players.values()
		sorted.sort_custom(func cmp(p1: Player, p2: Player) -> bool: return p1.score > p2.score)
		for player: Player in sorted:
			bb += "[cell]%s  [/cell][cell] %.2f [/cell]\n" % [player.pname, player.score]
		bb += "[/table]"
		ui.score_board.text = bb
		ui.score_message.visible = true
		ui.root.reset_camera()
	round_time = rt
	ui.round_time.text = "%s%02d:%02d" % ["-" if signi(round_time) < 0 else "", absi(round_time) / 60, absi(round_time) % 60]

func set_my_pyid(pyid: int) -> void:
	player_id = pyid

func player_disconnect(pyid: int) -> void:
	for os: Shot in players[pyid].shots:
		if not shots.erase(os.mid):
			push_warning("trying to erase non-existent shot (disconnect)")
		os.queue_free()
	players[pyid].queue_free()
	if not players.erase(pyid):
		push_warning("trying to erase non-existent player (disconnect)")

func trim_and_recolor_shots() -> void:
	for pyid in players:
		var player: = players[pyid]
		var nss: int = Global.config["num_shots_self"]
		var nso: int = Global.config["num_shots_other"]
		var numshots: = (nss if pyid == player_id else nso)
		while player.shots.size() > numshots:
			var os: Shot = player.shots.pop_front()
			if not shots.erase(os.mid):
				push_warning("trying to erase non-existent shot (trim_and_recolor_shots)")
			os.queue_free()
		var i: = player.shots.size() - 1
		for sh: Shot in player.shots:
			sh.material.albedo_color = player.material.albedo_color * pow(maxf(.7, pow(0.2, 1.0 / (numshots + 1))), i)
			i -= 1

func update_player_colors() -> void:
	for pyid in players:
		var player: = players[pyid]
		var col_s: Color = Global.config["color_self"]
		var col_o: Color = Global.config["color_other"]
		var color: = (col_s if pyid == player_id else col_o)
		player.material.albedo_color = color
		if pyid == player_id:
			player.pointer_h.material.albedo_color = color * 0.5
	trim_and_recolor_shots()
	ui.missile_input.update_label(players[player_id], digit)

func new_shot(pyid: int, mid: int) -> void:
	var s: = Shot.new(mid, players[pyid].material)
	players[pyid].shots.append(s)
	shots[mid] = s
	trim_and_recolor_shots()
	add_child(s)

func update_shot_pos(mid: int, ts: float, loc: Vector3) -> void:
	if shots.has(mid):
		shots[mid].timed_locations.append(Shot.TimeLocation.new(ts, loc))

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
		var t: = ray_sphere_intersection(ray_origin, ray_dir, planet.location, planet.radius + 1)
		if t > 0.0 and t < closest_dist:
			closest_dist = t
			closest_object_center = planet.location
	# Check players
	for player: Player in players.values():
		var t: = ray_sphere_intersection(ray_origin, ray_dir, player.location, player.radius + 10)
		if t > 0.0 and t < closest_dist:
			closest_dist = t
			closest_object_center = player.location
	return closest_object_center

func _input(event: InputEvent) -> void:
	if player_id == -1: return
	if not players.has(player_id): return
	if ui.is_menu_open(): return
	var player: = players[player_id]
	if event is InputEventKey:
		var iek: InputEventKey = event
		if iek.keycode == KEY_SHIFT:
			for pl2: Player in players.values():
				if iek.is_pressed():
					pl2.name_label.pixel_size = 1.16 / get_tree().root.get_visible_rect().size.y
				pl2.name_label.visible = iek.is_pressed()
		elif iek.is_pressed():
			match(iek.key_label):
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
			ui.missile_input.update_label(player, digit)
