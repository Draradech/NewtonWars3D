class_name Shot
extends Node3D

class TimeLocation:
	var time: float
	var location: Vector3
	func _init(t: float, l: Vector3) -> void:
		time = t
		location = l

var timed_locations: Array[TimeLocation] = []
var line: Line3D
var line_time: float
var material: StandardMaterial3D
var mid: int
var render_live: bool
var stale: = false

func _init(id: int, mat: StandardMaterial3D) -> void:
	mid = id;
	material = mat.duplicate()
	line = Line3D.new(0.5, material)
	render_live = true
	add_child(line)

func prepare_render(render_time: float) -> void:
	while timed_locations.size() > 0 and timed_locations[0].time < render_time:
		var tloc: TimeLocation = timed_locations.pop_front()
		line.addPoint(tloc.location)
		line_time = tloc.time
	if timed_locations.size() == 0:
		line.finalize()
		render_live = false
	else:
		if line.points.size() == 0: return
		var p1: = line.points[-1]
		var t1: = line_time
		var p2: = timed_locations[0].location
		var t2: = timed_locations[0].time
		var t: = render_time
		line.tmpEnd(p1 + (p2 - p1) * (t - t1) / (t2 - t1))
