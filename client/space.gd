extends Node3D

@onready
var network: Network = $Network
@onready
var display: Display = $Display

var host
var port
var menu
func menu_data(h, p, m) -> void:
	host = h
	port = p
	menu = m

func _ready():
	network.tcp_connect(host, port)

func synchronize(delta: float) -> bool:
	if network.time < 0: return false
	if display.time < 0: display.time = network.time - 0.05
	var next_display_time: = display.time + delta
	var target_time_delta: = (network.time - 0.05) - next_display_time
	var speedup: = 0.0
	if target_time_delta < -1./60:
		speedup = target_time_delta / 0.05 / 100.0 # 1% slowdown per 50ms buffer underrun
	elif target_time_delta > 1./60:
		speedup = target_time_delta / 0.05 / 100.0 # 1% speedup per 50ms buffer overfill
	next_display_time = display.time + delta * (1 + speedup)
	if next_display_time > network.time:
		return false
	display.time = next_display_time
	return true

func _process(delta: float) -> void:
	var start: = Time.get_ticks_usec()
	if Input.is_action_just_pressed("menu"):
		$MenuContainer.visible = !$MenuContainer.visible
	if Input.is_action_just_pressed("stats"):
		$Stats.visible = !$Stats.visible
	if network.read_network(display, delta):
		if synchronize(delta):
			display.prepare_frame()
	var end: = Time.get_ticks_usec()
	$Stats.cpu = (end - start) * 1e-3

func _on_disconnect_pressed() -> void:
	get_tree().root.add_child(menu)
	get_tree().root.remove_child(self)
	network.tcp_disconnect()
	queue_free()

func _on_continue_pressed() -> void:
	$MenuContainer.visible = false

func get_self_shots() -> int:
	return $MenuContainer/Background/VBox/GridContainer/ShotsSelf.value

func get_other_shots() -> int:
	return $MenuContainer/Background/VBox/GridContainer/ShotsOther.value

func input_blocked() -> bool:
	return $MenuContainer.visible or $DisconnectMessage.visible
