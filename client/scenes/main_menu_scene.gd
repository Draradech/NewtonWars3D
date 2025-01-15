extends Node3D

func _ready() -> void:
	$UI/MainMenu/VBox/Grid/Host.text = Global.config["host"]
	$UI/MainMenu/VBox/Grid/Port.text = str(Global.config["port"])

func get_host() -> String:
	return $UI/MainMenu/VBox/Grid/Host.text

func get_port() -> int:
	return int($UI/MainMenu/VBox/Grid/Port.text)

func _on_connect_pressed() -> void:
	get_parent()._on_connect()

func _on_quit_pressed() -> void:
	get_parent()._on_quit()
