extends Control

func _on_connect_pressed() -> void:
	var host = $VBox/Grid/Host.text
	var port = int($VBox/Grid/Port.text)
	var space = load("res://space.tscn").instantiate()
	space.menu_data(host, port, self)
	get_tree().root.add_child(space)
	get_tree().root.remove_child(self)

func _on_quit_pressed() -> void:
	get_tree().quit()
