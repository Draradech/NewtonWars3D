extends Node

var configPath = "user://config.nw3d"
var config: Dictionary = {
	"host": "localhost",
	"port": "3490",
	"num_shots_self": 6,
	"num_shots_other": 2,
	"ui_scale": 1.0,
	"fullscreen": true,
}

func _ready() -> void:
	if FileAccess.file_exists(configPath):
		var file = FileAccess.open(configPath, FileAccess.READ)
		var data = file.get_var()
		if data:
			for i in data:
				if config.has(i):
					config[i] = data[i]
		file.close()
	get_tree().root.content_scale_factor = config["ui_scale"]
	if config["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func save_config() -> void:
	var file = FileAccess.open(configPath, FileAccess.WRITE)
	file.store_var(config)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if config["fullscreen"]:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			config["fullscreen"] = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			config["fullscreen"] = true
		save_config()
