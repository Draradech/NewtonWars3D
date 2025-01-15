extends Node3D

@onready
var network: Network = $Network
@onready
var space: Space = $Space

var host
var port
var menu
func menu_data(h, p, m) -> void:
	host = h
	port = p
	menu = m

var xr_interface: XRInterface
func _ready():
	$EscMenu/Background/VBox/GridContainer/ShotsOther.value = Global.config["num_shots_other"]
	$EscMenu/Background/VBox/GridContainer/ShotsSelf.value = Global.config["num_shots_self"]
	$EscMenu/Background/VBox/GridContainer/UiScale.value = Global.config["ui_scale"]
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		$XROrigin3D/XRCamera3D.make_current()
	else:
		$Camera3D.make_current()
	
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
		$EscMenu.visible = !$EscMenu.visible
		if !$EscMenu.visible:
			Global.save_config()
	if Input.is_action_just_pressed("stats"):
		$Stats.visible = !$Stats.visible
	
	if network.read_network(space, delta):
		if synchronize(delta):
			space.prepare_frame()
	
	var end: = Time.get_ticks_usec()
	$Stats.cpu = (end - start) * 1e-3

func _on_disconnect_pressed() -> void:
	menu.visible = true
	get_tree().root.remove_child(self)
	network.tcp_disconnect()
	queue_free()

func _on_continue_pressed() -> void:
	$EscMenu.visible = false
	Global.save_config()

func input_blocked() -> bool:
	return \
		$EscMenu.visible \
		or $DisconnectMessage.visible \
		or space.player_id == -1

func _on_ui_scale_value_changed(value: float) -> void:
	get_tree().root.content_scale_factor = value
	Global.config["ui_scale"] = value

func _on_shots_other_value_changed(value: float) -> void:
	Global.config["num_shots_other"] = value

func _on_shots_self_value_changed(value: float) -> void:
	Global.config["num_shots_self"] = value
