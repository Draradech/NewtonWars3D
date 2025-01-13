extends Node3D

@onready
var network: Network = $Network
@onready
var display: Display = $Display

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
	if network.read_network(display):
		if synchronize(delta):
			display.prepare_frame()
