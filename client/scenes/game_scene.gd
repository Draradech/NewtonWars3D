extends Node3D

@onready
var network: Network = $Network
@onready
var space: Space = $Space

var host
var port
func set_server(h, p) -> void:
	host = h
	port = p

func _ready():
	$UI/EscMenu/VBox/GridContainer/ShotsOther.value = Global.config["num_shots_other"]
	$UI/EscMenu/VBox/GridContainer/ShotsSelf.value = Global.config["num_shots_self"]
	$UI/EscMenu/VBox/GridContainer/UiScale.value = Global.config["ui_scale"]
	network.tcp_connect(host, port)

func synchronize(delta: float) -> bool:
	if network.time < 0: return false
	if space.time < 0: space.time = network.time - 0.05
	var next_space_time: = space.time + delta
	var target_time_delta: = (network.time - 0.05) - next_space_time
	var speedup: = 0.0
	if target_time_delta < -1./60:
		speedup = target_time_delta / 0.05 / 100.0 # 1% slowdown per 50ms buffer underrun
	elif target_time_delta > 1./60:
		speedup = target_time_delta / 0.05 / 100.0 # 1% speedup per 50ms buffer overfill
	next_space_time = space.time + delta * (1 + speedup)
	if next_space_time > network.time:
		return false
	space.time = next_space_time
	return true

func _process(delta: float) -> void:
	var start: = Time.get_ticks_usec()
	if Input.is_action_just_pressed("menu"):
		$UI/EscMenu.visible = !$UI/EscMenu.visible
		if !$UI/EscMenu.visible:
			Global.save_config()
	if Input.is_action_just_pressed("stats"):
		$UI/Stats.visible = !$UI/Stats.visible
	
	######## main game loop here ########
	if network.read_network(space, delta):
		if synchronize(delta):
			space.prepare_frame()
	######## main game loop here ########
	
	var end: = Time.get_ticks_usec()
	$UI/Stats.cpu = (end - start) * 1e-3

func is_menu_open() -> bool:
	return \
		$UI/EscMenu.visible \
		or $UI/DisconnectMessage.visible \
		or space.player_id == -1

func _on_continue_pressed() -> void:
	$UI/EscMenu.visible = false
	Global.save_config()

func _on_disconnect_pressed() -> void:
	Global.save_config()
	get_parent()._on_disconnect()

func _on_ui_scale_value_changed(value: float) -> void:
	get_tree().root.content_scale_factor = value
	Global.config["ui_scale"] = value

func _on_shots_other_value_changed(value: float) -> void:
	Global.config["num_shots_other"] = value

func _on_shots_self_value_changed(value: float) -> void:
	Global.config["num_shots_self"] = value
