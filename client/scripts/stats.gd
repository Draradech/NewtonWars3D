class_name StatsLabel
extends Label

var cpu: float = 0

func _ready() -> void:
	RenderingServer.viewport_set_measure_render_time(get_tree().root.get_viewport_rid(), true)

func _process(delta: float) -> void:
	if visible:
		text = "\
		frame: %.1fms (%.0f fps)
		cpu:   %.1fms
		gpu:   %.1fms
		triangles: %.1fk
		draw calls: %d" % [
			delta * 1000, 1.0 / delta,
			RenderingServer.viewport_get_measured_render_time_cpu(get_tree().root.get_viewport_rid()) + RenderingServer.get_frame_setup_time_cpu() + cpu,
			RenderingServer.viewport_get_measured_render_time_gpu(get_tree().root.get_viewport_rid()),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) * .001,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		]
