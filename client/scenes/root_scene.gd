extends Node3D

var game_scene = preload("res://scenes/game_scene.tscn")
var main_menu_scene = preload("res://scenes/main_menu_scene.tscn")

var main_menu
var game

var xr_interface: XRInterface
func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		$XROrigin3D/XRCamera3D.make_current()
	else:
		$Camera3D.make_current()
	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)

func is_menu_open() -> bool:
	if main_menu: return true
	return game.is_menu_open()

func _on_connect() -> void:
	var host = main_menu.get_host()
	var port = main_menu.get_port()
	game = game_scene.instantiate()
	game.set_server(host, port)
	add_child(game)
	remove_child(main_menu)
	main_menu.queue_free()
	main_menu = null
	Global.config["host"] = host
	Global.config["port"] = port
	Global.save_config()

func _on_disconnect() -> void:
	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
	remove_child(game)
	game.queue_free()
	game = null

func _on_quit() -> void:
	get_tree().quit()
