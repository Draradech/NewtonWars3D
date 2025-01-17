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
		name_label.position = location + Vector3.UP * radius
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
var pointer_h: Line3D
var pointer_v: Line3D
var torus: MeshInstance3D
var sphere: MeshInstance3D
var shots: Array[Shot]
var score: float = 0
var pname: String = "":
	set(value):
		pname = value
		name_label.text = value
var name_label: Label3D

func update_pointer():
	if pointer:
		var vel = Vector3.RIGHT * 50
		vel = vel.rotated(Vector3.FORWARD, deg_to_rad(-pitch))
		vel = vel.rotated(Vector3.UP, deg_to_rad(-yaw))
		var vel_xz = Vector3(vel.x, 0, vel.z);
		pointer.points[0] = location
		pointer.tmpEnd(location + vel)
		pointer_h.points[0] = location
		pointer_h.tmpEnd(location + vel_xz)
		pointer_v.points[0] = location + vel_xz
		pointer_v.tmpEnd(location + vel)
		var d = vel_xz.length()
		torus.mesh.inner_radius = d - 0.25
		torus.mesh.outer_radius = d + 0.25
		torus.position = location

func _init(loc: Vector3, rad: float, do_pointer: bool, mat: StandardMaterial3D):
	if do_pointer:
		var pointermat: StandardMaterial3D = mat.duplicate()
		pointermat.albedo_color = Color.WHITE
		pointer = Line3D.new(0.5, pointermat)
		pointer.addPoint(loc)
		add_child(pointer)
		pointermat = mat.duplicate()
		pointermat.albedo_color *= 0.5
		pointer_h = Line3D.new(0.25, pointermat)
		pointer_h.addPoint(loc)
		add_child(pointer_h)
		pointer_v = Line3D.new(0.25, pointermat)
		pointer_v.addPoint(loc)
		add_child(pointer_v)
		torus = MeshInstance3D.new()
		torus.mesh = TorusMesh.new()
		torus.mesh.rings = 64
		torus.mesh.ring_segments = 8
		torus.mesh.surface_set_material(0, pointermat)
		add_child(torus)
	
	material = mat.duplicate()
	sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.mesh.radial_segments = 16
	sphere.mesh.rings = 8
	sphere.mesh.surface_set_material(0, material)
	add_child(sphere)
	
	name_label = Label3D.new()
	name_label.fixed_size = true
	name_label.pixel_size = 1./930 * Global.config["ui_scale"] 
	name_label.font_size = 16
	name_label.outline_size = 8
	name_label.double_sided = false
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)
	name_label.visible = false
	
	radius = rad
	location = loc
