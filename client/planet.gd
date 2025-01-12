class_name Planet
extends Node3D

var location: Vector3
var radius: float:
	set(value):
		radius = value
		radius_sq = radius * radius
		mass = radius_sq * radius * 0.1
var radius_sq: float
var mass: float

func _init(loc: Vector3, rad: float, mat: StandardMaterial3D) -> void:
	location = loc
	radius = rad
	var sph = BeamSphere.new(loc, rad, 0.5)
	sph.mesh.surface_set_material(0, mat)
	add_child(sph)
