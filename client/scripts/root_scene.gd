class_name RootScene
extends Node3D

var game_scene: = preload("res://scenes/game_scene.tscn")
var ui_scene: = preload("res://scenes/ui_scene.tscn")
var xr_setup:= preload("res://scenes/xr_setup.tscn")
var flat_setup:= preload("res://scenes/flat_setup.tscn")

@export var world_environment: WorldEnvironment

var xr: XRSetup
var flat: FlatSetup
var xr_interface: OpenXRInterface

func _ready() -> void:
	Global.root = self
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		xr_interface.render_target_size_multiplier = Global.config["render_scale"]
		xr = xr_setup.instantiate()
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

func _on_connect() -> void:
	Global.game = game_scene.instantiate()
	if xr:
		Global.game.scale = Vector3.ONE * 0.001 * Global.config["world_scale"]
		var height: float = Global.config["world_height"]
		var dist: float = Global.config["world_distance"]
		Global.game.position = Vector3(0, height, -dist)
		@warning_ignore("return_value_discarded")
		xr.shoot.connect(Global.game.network._on_shoot)
	add_child(Global.game)
	Global.ui.game_mode()

func _on_disconnect() -> void:
	Global.ui.main_menu_mode()
	remove_child(Global.game)
	Global.game.queue_free()
	Global.game = null
	if xr:
		xr.hand_controller.visible = false
		var ctrl_scene: HandController = xr.hand_controller.get_scene_instance()
		ctrl_scene.player = null
	if flat: flat.cam.reset_camera()

func _on_quit() -> void:
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		if Global.config["fullscreen"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			Global.config["fullscreen"] = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			Global.config["fullscreen"] = true
		Global.save_config()

var t1: = 0.0
var t2: = 0.0
var pt1: = 0.0
var pt2: = 0.0
var phy_running: = false

func _process(_delta: float) -> void:
	t1 = Time.get_ticks_usec() / 1000.0
	if phy_running:
		pt2 = t1
		phy_running = false
	def1.call_deferred()
	if not Global.ui and xr and xr.viewport_back_wall.scene_node:
		Global.ui = xr.viewport_back_wall.scene_node
	if xr and Global.ui:
		xr.viewport_back_wall.visible = Global.ui.is_menu_open()

func _physics_process(_delta: float) -> void:
	pt1 = Time.get_ticks_usec() / 1000.0
	phy_running = true

func def1() -> void:
	def2.call_deferred()

func def2() -> void:
	t2 = Time.get_ticks_usec() / 1000.0
	if xr:
		var panel_vp: XRToolsViewport2DIn3D = Global.root.xr.hand_info_panel
		var panel: HandInfoPanel = panel_vp.get_scene_instance()
		panel.debug_stats.cpu = t2 - t1
		panel.debug_stats.pcpu = pt2 - pt1
	else:
		Global.ui.stats.cpu = t2 - t1
		Global.ui.stats.pcpu = pt2 - pt1
