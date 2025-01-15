class_name Shot
extends Node3D

var timed_locations: Array = []
var line: Line3D
var line_time: float
var material: StandardMaterial3D
var mid: int
var render_live: bool

func _init(id: int, mat: StandardMaterial3D) -> void:
	mid = id;
	material = mat.duplicate()
	line = Line3D.new(0.5, material)
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
	else:
		if line.points.size() == 0: return
		var p1 = line.points[-1]
		var t1 = line_time
		var p2 = timed_locations[0][1]
		var t2 = timed_locations[0][0]
		var t = render_time
		line.tmpEnd(p1 + (p2 - p1) * (t - t1) / (t2 - t1))
