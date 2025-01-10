class_name Shot
extends Node3D

var sim_live: bool
var render_live: bool
var timed_locations: Array = []
var planets: Array[Planet]
var players: Array[Player]
var location: Vector3
var velocity: Vector3
var acceleration: = Vector3.ZERO
var line: Line3D
var line_time: float
var material: StandardMaterial3D

const segmentSteps: = 25

func acc(loc: Vector3) -> Vector3:
	var a: = Vector3.ZERO
	for planet in planets:
		var an: = planet.location - loc
		var ll: = an.length_squared()
		an = an.normalized() * planet.mass / ll
		a += an
	return a

func integrate():
	var dt: = 1.0 / segmentSteps
	var new_loc: = location + velocity * dt + acceleration * 0.5 * dt * dt
	var new_acc: = acc(new_loc)
	var new_vel: = velocity + (acceleration + new_acc) * 0.5 * dt
	location = new_loc
	velocity = new_vel
	acceleration = new_acc

func _init(loc: Vector3, vel: Vector3, sim_time: float, plan: Array[Planet], play: Array[Player], mat: StandardMaterial3D) -> void:
	material = mat.duplicate()
	planets = plan
	players = play
	location = loc
	velocity = vel
	acceleration = acc(loc)
	line = Line3D.new()
	timed_locations.append([sim_time, loc])
	line.material = material
	sim_live = true
	render_live = true
	add_child(line)

func prepare_render(render_time: float):
	while timed_locations.size() > 0 and timed_locations[0][0] < render_time:
		var tloc = timed_locations.pop_front()
		line.addPoint(tloc[1])
		line_time = tloc[0]
	if timed_locations.size() == 0:
		line.finalize()
		render_live = false
		if sim_live: print("no timed location in live shot")
		if (players[1].location - location).length_squared() < players[1].radius_sq:
			players[1].material.albedo_color = Color.WHITE
		if (players[2].location - location).length_squared() < players[2].radius_sq:
			players[2].material.albedo_color = Color.WHITE
	else:
		if line.points.size() == 0: return
		var p1 = line.points[-1]
		var t1 = line_time
		var p2 = timed_locations[0][1]
		var t2 = timed_locations[0][0]
		var t = render_time
		line.tmpEnd(p1 + (p2 - p1) * (t - t1) / (t2 - t1))

func simulate(sim_time: float, delta: float):
	var t: = sim_time - delta
	for i in range(segmentSteps):
		if not sim_live: break
		integrate()
		t += delta / segmentSteps
		for planet in planets:
			if (planet.location - location).length_squared() < planet.radius_sq: sim_live = false
		if (players[1].location - location).length_squared() < players[1].radius_sq: sim_live = false
		if (players[2].location - location).length_squared() < players[2].radius_sq: sim_live = false
	timed_locations.append([t, location])
