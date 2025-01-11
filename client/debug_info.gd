extends Label

func _ready():
	RenderingServer.viewport_set_measure_render_time(get_tree().root.get_viewport_rid(), true)

func _process(delta):
	text = "\
	mspf: %.1f
	cpu setup: %.1f
	cpu: %.1f
	gpu: %.1f
	triangles: %.1fk
	draw calls: %d" % [
		delta * 1000,
		RenderingServer.get_frame_setup_time_cpu(),
		RenderingServer.viewport_get_measured_render_time_cpu(get_tree().root.get_viewport_rid()),
		RenderingServer.viewport_get_measured_render_time_gpu(get_tree().root.get_viewport_rid()),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) * .001,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
	]
