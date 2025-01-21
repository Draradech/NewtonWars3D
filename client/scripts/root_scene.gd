class_name RootScene
extends Node3D

var game_scene: = preload("res://scenes/game_scene.tscn")
var ui_scene: = preload("res://scenes/ui_scene.tscn")
var xr_setup:= preload("res://scenes/xr_setup.tscn")
var flat_setup:= preload("res://scenes/flat_setup.tscn")

@export var world_environment: WorldEnvironment

var xr: XRSetup
var flat: FlatSetup

func _ready() -> void:
	Global.root = self
	var xr_interface: = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		xr = xr_setup.instantiate()
		xr.viewport_back_wall.scene = ui_scene
		add_child(xr)
	else:
		flat = flat_setup.instantiate()
		add_child(flat)
		Global.ui = ui_scene.instantiate()
		add_child(Global.ui)
	if Global.config["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func is_vr() -> bool:
	return xr_setup != null

func _on_connect() -> void:
	Global.game = game_scene.instantiate()
	if is_vr():
		Global.game.scale = Vector3.ONE * 0.001
		Global.game.position = Vector3(0, 1, 0)
		@warning_ignore("return_value_discarded")
		xr.shoot.connect(Global.game.network._on_shoot)
	add_child(Global.game)
	Global.ui.game_mode()

func _on_disconnect() -> void:
	Global.ui.main_menu_mode()
	remove_child(Global.game)
	Global.game.queue_free()
	Global.game = null
	reset_camera()

func reset_camera() -> void:
	if not is_vr():
		flat.cam.distance = 2000.0
		flat.cam.pitch = 0.0
		flat.cam.yaw = 0.0
		flat.cam.poff = Vector3.ZERO

func _on_quit() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	if not Global.ui and xr.viewport_back_wall.scene_node:
		Global.ui = xr.viewport_back_wall.scene_node
	if Input.is_action_just_pressed("fullscreen"):
		if Global.config["fullscreen"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			Global.config["fullscreen"] = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			Global.config["fullscreen"] = true
		Global.save_config()
