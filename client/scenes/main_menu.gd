extends Control

func _on_connect_pressed() -> void:
	var host = $VBox/Grid/Host.text
	var port = int($VBox/Grid/Port.text)
	var game_scene = load("res://scenes/game_scene.tscn").instantiate()
	game_scene.menu_data(host, port, self)
	get_tree().root.add_child(game_scene)
	visible = false
	Global.config["host"] = $VBox/Grid/Host.text
	Global.config["port"] = $VBox/Grid/Port.text
	Global.save_config()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _ready() -> void:
	$VBox/Grid/Host.text = Global.config["host"]
	$VBox/Grid/Port.text = Global.config["port"]
