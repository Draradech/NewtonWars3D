extends Control

func _on_connect_pressed() -> void:
	var host = $VBox/Grid/Host.text
	var port = int($VBox/Grid/Port.text)
	var space = load("res://space.tscn").instantiate()
	space.menu_data(host, port, self)
	get_tree().root.add_child(space)
	get_tree().root.remove_child(self)
	Global.config["host"] = $VBox/Grid/Host.text
	Global.config["port"] = $VBox/Grid/Port.text
	Global.save_config()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _ready() -> void:
	$VBox/Grid/Host.text = Global.config["host"]
	$VBox/Grid/Port.text = Global.config["port"]
