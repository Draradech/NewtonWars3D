extends Node3D
@export var material: BaseMaterial3D

func _ready():
	for i in range(24):
		var sph = BeamSphere.new(Vector3(randf_range(-1000, 1000), randf_range(-500, 500), randf_range(-500, 500)), randf_range(20, 40), .5)
		sph.mesh.surface_set_material(0, material)
		add_child(sph)
