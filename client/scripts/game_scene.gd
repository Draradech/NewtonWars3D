class_name GameScene
extends Node3D

@export var network: Network
@export var space: Space

func _ready() -> void:
	network.tcp_connect()

func synchronize(delta: float) -> bool:
	if network.time < 0: return false
	if space.time < 0: space.time = network.time - 0.05
	var next_space_time: = space.time + delta
	var target_time_delta: = (network.time - 0.05) - next_space_time
	var speedup: = 0.0
	if target_time_delta < -1./60: # +/- 1 sim frame always ok
		speedup = target_time_delta / 0.05 / 100.0 # 1% slowdown per 50ms buffer underrun
	elif target_time_delta > 1./60: # +/- 1 sim frame always ok
		speedup = target_time_delta / 0.05 / 100.0 # 1% speedup per 50ms buffer overfill
	next_space_time = space.time + delta * (1 + speedup)
	if next_space_time > network.time:
		return false
	space.time = next_space_time
	return true

func _process(delta: float) -> void:
	if network.process_network(space, delta):
		if synchronize(delta):
			space.prepare_frame()
