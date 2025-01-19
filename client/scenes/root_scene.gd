class_name RootScene
extends Node3D

var game_scene: = preload("res://scenes/game_scene.tscn")
var ui_scene: = preload("res://scenes/ui_scene.tscn")

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var environment: = world_environment.environment

var ui: UiScene
var game: GameScene

var xr_interface: XRInterface
func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	ui = ui_scene.instantiate()
	ui.root = self
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		var origin: XROrigin3D = $XROrigin3D
		origin.world_scale = 1000
		var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
		xr_camera.make_current()
		var vrui_viewport: SubViewport = $ViewportVRUI
		vrui_viewport.add_child(ui)
		$Camera3D.queue_free()
		remove_child($Camera3D)
	else:
		var cam: MainCamera = $Camera3D
		cam.make_current()
		cam.root = self
		add_child(ui)
	if Global.config["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func is_vr() -> bool:
	return xr_interface.is_initialized()

func _on_connect() -> void:
	game = game_scene.instantiate()
	game.root = self
	game.ui = ui
	add_child(game)
	ui.game_mode(game)

func _on_disconnect() -> void:
	ui.main_menu_mode()
	remove_child(game)
	game.queue_free()
	game = null
	reset_camera()

func reset_camera() -> void:
	if not is_vr():
		var cam: MainCamera = $Camera3D
		cam.distance = 2000.0
		cam.pitch = 0.0
		cam.yaw = 0.0
		cam.poff = Vector3.ZERO

func _on_quit() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if Global.config["fullscreen"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			Global.config["fullscreen"] = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			Global.config["fullscreen"] = true
		Global.save_config()
