extends Node

var next_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		var switch_to = next_mode
		next_mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(switch_to)
