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
var speed: float = 8:
	set(value):
		speed = value
		update_labels()
var pitch: float = 0:
	set(value):
		pitch = value
		update_labels()
		update_pointer()
var yaw: float = 0:
	set(value):
		yaw = value
		update_labels()
		update_pointer()
var digit: int = 0:
	set(value):
		digit = value
		update_labels()
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

func update_pointer() -> void:
	if pointer:
		var vel: = Vector3.RIGHT * 50
		vel = vel.rotated(Vector3.FORWARD, deg_to_rad(-pitch))
		vel = vel.rotated(Vector3.UP, deg_to_rad(-yaw))
		var vel_xz: = Vector3(vel.x, 0, vel.z);
		pointer.points[0] = location
		pointer.tmpEnd(location + vel)
		pointer_h.points[0] = location
		pointer_h.tmpEnd(location + vel_xz)
		pointer_v.points[0] = location + vel_xz
		pointer_v.tmpEnd(location + vel)
		var d: = vel_xz.length()
		(torus.mesh as TorusMesh).inner_radius = d - 0.25
		(torus.mesh as TorusMesh).outer_radius = d + 0.25
		torus.position = location

func _init(loc: Vector3, rad: float, do_pointer: bool, mat: StandardMaterial3D) -> void:
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
		(torus.mesh as TorusMesh).rings = 64
		(torus.mesh as TorusMesh).ring_segments = 8
		torus.mesh.surface_set_material(0, pointermat)
		add_child(torus)
	
	material = mat.duplicate()
	sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	(sphere.mesh as SphereMesh).radial_segments = 16
	(sphere.mesh as SphereMesh).rings = 8
	sphere.mesh.surface_set_material(0, material)
	add_child(sphere)
	
	name_label = Label3D.new()
	name_label.fixed_size = true
	name_label.font_size = 16
	name_label.outline_size = 8
	name_label.double_sided = false
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)
	name_label.visible = false
	
	radius = rad
	location = loc

func vr_name_label() -> void:
	name_label.pixel_size = 1.0
	name_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	name_label.visible = true
	var cam_pos: = Global.root.xr.cam.position
	var label_pos: = name_label.global_position
	var vec_dir_3d: = cam_pos - label_pos
	var vec_dir_2d: = Vector2(vec_dir_3d.z, vec_dir_3d.x)
	name_label.rotation.y = vec_dir_2d.angle()

func update_labels() -> void:
	var p: = clampf(pitch, -999, 999)
	if p != pitch: pitch = p
	var y: = clampf(yaw, -999, 999)
	if y != yaw: yaw = y
	var s: = clampf(speed, 0, 999)
	if s != speed: speed = s
	var d: = clampi(digit, -8, 2)
	if d != digit: digit = d
	if pitch != 0.0 and absf(pitch) < 1e-10: pitch = 0.0
	if yaw != 0.0 and absf(yaw) < 1e-10: yaw = 0.0
	if speed != 0.0 and absf(speed) < 1e-10: speed = 0.0
	if Global.root.xr:
		var hand_controller: HandController = Global.root.xr.hand_controller.get_scene_instance()
		hand_controller.update_values(self)
	else:
		Global.ui.missile_input.update_label(self)
