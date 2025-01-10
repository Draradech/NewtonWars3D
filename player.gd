class_name Player
extends MeshInstance3D

var material: StandardMaterial3D
var radius: float
var radius_sq: float
var location: Vector3

func _init(loc: Vector3, rad: float, mat: StandardMaterial3D):
	radius = rad
	radius_sq = rad * rad
	location = loc
	material = mat.duplicate()
	mesh = SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	position = location
	scale = Vector3.ONE * radius * 2
	mesh.surface_set_material(0, material)
