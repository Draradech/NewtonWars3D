class_name Player
extends Node3D

var material: StandardMaterial3D
var radius: float:
	set(value):
		radius = value
		radius_sq = radius * radius
		sphere.scale = Vector3.ONE * radius * 2
var radius_sq: float
var location: Vector3:
	set(value):
		location = value
		sphere.position = location
		update_pointer()
var speed: float = 8
var pitch: float = 0:
	set(value):
		pitch = value
		update_pointer()
var yaw: float = 0:
	set(value):
		yaw = value
		update_pointer()
var pointer: Line3D
var sphere: MeshInstance3D
var shots: Array[Shot]

func update_pointer():
	var vel = Vector3.RIGHT * 50
	vel = vel.rotated(Vector3.FORWARD, deg_to_rad(-pitch))
	vel = vel.rotated(Vector3.UP, deg_to_rad(-yaw))
	pointer.tmpEnd(location + vel)

func _init(loc: Vector3, rad: float, mat: StandardMaterial3D):
	material = mat.duplicate()
	sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.mesh.radial_segments = 16
	sphere.mesh.rings = 8
	radius = rad
	location = loc
	sphere.mesh.surface_set_material(0, material)
	add_child(sphere)
	
	var pointermat: StandardMaterial3D = mat.duplicate()
	pointermat.albedo_color = Color.WHITE
	pointer = Line3D.new(0.5, pointermat)
	pointer.addPoint(loc)
	add_child(pointer)
