extends Node3D

@export var material: BaseMaterial3D

func _ready():
	for i in range(100):
		var lin = Line3D.new(material)
		var dir = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized()
		var pos = Vector3(0, 0, 0)
		for j in range(2000):
			var axis = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized()
			dir = dir.rotated(axis, randf_range(deg_to_rad(1), deg_to_rad(5)))
			pos += dir
			lin.addPoint(pos)
		lin.finalize()
		add_child(lin)
