extends Node3D

@export var mat_shot: BaseMaterial3D
@export var mat_player: BaseMaterial3D
@export var mat_planet: BaseMaterial3D

var shots: Array[Shot] = []
var planets: Array[Planet] = []
var players: Array[Player] = []
var sim_time: float = 0
var render_time: float = 0
var pmin: float = 0
var pmax: float = 0
var speed: float = 8
var pitch: float = 0
var yaw: float = 0

func gpot(loc: Vector3) -> float:
	var pot: float = 0
	for planet in planets:
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
	pmax = 1.35 * sum / num
	pmin = pmax - 10
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

func _ready() -> void:
	for i in range(25):
		var loc: Vector3
		var rad: float
		while true:
			loc = Vector3(randf_range(-900, 900), randf_range(-500, 500), randf_range(-900, 900))
			rad = randf_range(20, 40)
			if Vector2(loc.x, loc.z).length() > 900: continue # corner planets
			var collision = false
			for planet in planets:
				if (planet.location - loc).length() < planet.radius + rad:
					collision = true
					break
			if collision: continue # collision with other planet
			break
		var p: = Planet.new(loc, rad, mat_planet)
		planets.append(p)
		add_child(p)
	print("start eval")
	pot_eval()
	print("eval pmin: %.1f pmax: %.1f" % [pmin, pmax])
	for i in range(3):
		var loc: Vector3
		var rad: = 5.0
		while true:
			loc = Vector3(randf_range(-900, 900), randf_range(-500, 500), randf_range(-900, 900))
			var pot = gpot(loc)
			if pot > pmax or pot < pmin: continue # not in pot band
			var collision = false
			for player in players:
				if (player.location - loc).length() < 400.:
					collision = true
					break
			if collision: continue # too close to other player
			for planet in planets:
				if (planet.location - loc).length() < planet.radius + rad:
					collision = true
					break
			if collision: continue # collision with planet
			break
		var p: = Player.new(loc, rad, mat_player)
		players.append(p)
		add_child(p)
	players[1].material.albedo_color = Color(1, .5, 0)
	players[2].material.albedo_color = Color(1, .5, 0)
	updateLabel(0)

func _process(delta: float) -> void:
	if render_time + delta >= sim_time:
		return
	render_time += delta
	for shot in shots:
		if not shot.render_live:
			continue
		shot.prepare_render(render_time)

var which: int = 0
var digit: int = 0
func updateLabel(delta: float):
	var pitchstring: = "%15.10f" % pitch
	var yawstring: = "%15.10f" % yaw
	var speedstring: = "%15.10f" % speed
	if which == 0:
		pitch += delta
		pitchstring = ("%15.10f" % pitch).insert((5 if digit < 0 else 4) - digit, "[/color]")
		pitchstring = pitchstring.insert((4 if digit < 0 else 3) - digit, "[color=007fff]")
	if which == 1:
		yaw += delta
		yawstring = ("%15.10f" % yaw).insert((5 if digit < 0 else 4) - digit, "[/color]")
		yawstring = yawstring.insert((4 if digit < 0 else 3) - digit, "[color=007fff]")
	if which == 2:
		speed += delta
		speedstring = ("%15.10f" % speed).insert((5 if digit < 0 else 4) - digit, "[/color]")
		speedstring = speedstring.insert((4 if digit < 0 else 3) - digit, "[color=007fff]")
	var bbstring: = "[center]"
	bbstring += "Pitch: "
	bbstring += pitchstring
	bbstring += "\nYaw:   "
	bbstring += yawstring
	bbstring += "\nSpeed: "
	bbstring += speedstring
	bbstring += "[/center]"
	$RichTextLabel.text = bbstring

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		var delta: float = 0
		if event.keycode == KEY_TAB:
			which = (which + 1) % 3
		if event.keycode == KEY_UP:
			delta = pow(10, digit)
		if event.keycode == KEY_DOWN:
			delta = -pow(10, digit)
		if event.keycode == KEY_LEFT:
			digit += 1
		if event.keycode == KEY_RIGHT:
			digit -= 1
		updateLabel(delta)

var step: int = 0
const slow_factor: int = 1
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("fire"):
		if shots.size() > 5:
			var rem: Shot = shots.pop_front()
			remove_child(rem)
		for shot in shots:
			shot.material.albedo_color *= .7
		var loc = players[0].location
		var vel = Vector3.RIGHT * speed
		vel = vel.rotated(Vector3.FORWARD, deg_to_rad(-pitch))
		vel = vel.rotated(Vector3.UP, deg_to_rad(-yaw))
		var shot = Shot.new(loc, vel, sim_time, planets, players, mat_shot)
		shots.append(shot)
		add_child(shot)
	if Input.is_action_just_pressed("clear"):
		for shot in shots:
			remove_child(shot)
		shots.clear()
	if Input.is_action_just_pressed("reset"):
		pitch = 0
		yaw = 0
		speed = 5
		updateLabel(0)
	if Input.is_action_just_pressed("wire"):
		if get_tree().root.get_viewport().debug_draw == Viewport.DEBUG_DRAW_DISABLED:
			get_tree().root.get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		else: get_tree().root.get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	if Input.is_action_just_pressed("bandallow"):
		$GPotBandAllow.visible = !$GPotBandAllow.visible
	if Input.is_action_just_pressed("banddisallow"):
		$GPotBandDisallow.visible = !$GPotBandDisallow.visible
	step += 1
	if not step % slow_factor == 0: return
	sim_time += delta * slow_factor
	for shot in shots:
		if not shot.sim_live:
			continue
		shot.simulate(sim_time, delta * slow_factor)
