extends Node

var root: RootScene
var game: GameScene
var ui: UiScene

var configPath: = "user://config.nw3d"
var config: Dictionary[String, Variant] = {
	"host": "localhost",
	"port": 3490,
	"name": "Isaac",
	"num_shots_self": 6,
	"num_shots_other": 2,
	"ui_scale": 1.0,
	"fullscreen": true,
	"glow": false,
	"msaa": 3,
	"color_self": Color(1, .5, 0),
	"color_other": Color(0, .5, 1),
	"world_scale": 1.0,
	"world_distance": 0.0,
	"world_height": 1.0,
	"world_rotate": false
}

func _ready() -> void:
	if FileAccess.file_exists(configPath):
		var file: = FileAccess.open(configPath, FileAccess.READ)
		var data: Dictionary[String, Variant] = file.get_var()
		if data:
			for i in data:
				if config.has(i):
					config[i] = data[i]
		file.close()

func save_config() -> void:
	var file: = FileAccess.open(configPath, FileAccess.WRITE)
	if not file.store_var(config):
		push_error("Failed to save config")
