extends Node3D

@onready
var network: Network = $Network
@onready
var space: Space = $Space

var host
var port
var playername

var ui
func _ready():
	$UI/EscMenu/VBox/GridContainer/ShotsOther.value = Global.config["num_shots_other"]
	$UI/EscMenu/VBox/GridContainer/ShotsSelf.value = Global.config["num_shots_self"]
	$UI/EscMenu/VBox/GridContainer/UiScale.value = Global.config["ui_scale"]
	get_tree().root.content_scale_factor = Global.config["ui_scale"]
	$UI/EscMenu/VBox/GridContainer/Glow.button_pressed = Global.config["glow"]
	get_tree().root.get_node("RootScene").get_node("WorldEnvironment").environment.glow_enabled = Global.config["glow"]
	$UI/EscMenu/VBox/GridContainer/MSAA.selected = Global.config["msaa"]
	$UI/EscMenu/VBox/GridContainer/ColorSelf.color = Global.config["color_self"]
	$UI/EscMenu/VBox/GridContainer/ColorOther.color = Global.config["color_other"]
	RenderingServer.viewport_set_msaa_3d(get_tree().root.get_viewport_rid(), Global.config["msaa"])
	network.tcp_connect(host, port, playername)
	ui = $UI
	if get_parent().is_vr():
		remove_child(ui)
		$ViewportVRUI.add_child(ui)
		$MeshVRUI.visible = true

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
	var start: = Time.get_ticks_usec()
	if Input.is_action_just_pressed("menu"):
		ui.get_node("EscMenu").visible = !ui.get_node("EscMenu").visible
		ui.get_node("Stats").visible = ui.get_node("EscMenu").visible
		if !ui.get_node("EscMenu").visible:
			Global.save_config()
	if Input.is_action_just_pressed("stats"):
		ui.get_node("Stats").visible = !ui.get_node("Stats").visible
	
	######## main game loop here ########
	if network.read_network(space, delta):
		if synchronize(delta):
			space.prepare_frame()
	######## main game loop here ########
	
	var end: = Time.get_ticks_usec()
	ui.get_node("Stats").cpu = (end - start) * 1e-3

func is_menu_open() -> bool:
	return \
		ui.get_node("EscMenu").visible \
		or ui.get_node("ScoreBoardMessage").visible \
		or ui.get_node("DisconnectMessage").visible \
		or space.player_id == -1

func _on_continue_pressed() -> void:
	ui.get_node("EscMenu").visible = false
	ui.get_node("Stats").visible = false
	Global.save_config()

func _on_disconnect_pressed() -> void:
	Global.save_config()
	get_parent()._on_disconnect()

func _on_quit_pressed() -> void:
	Global.save_config()
	get_parent()._on_quit()

func _on_ui_scale_value_changed(value: float) -> void:
	get_tree().root.content_scale_factor = value
	Global.config["ui_scale"] = value
	for player: Player in $Space.players.values():
		player.name_label.pixel_size = 1./930 * value

func _on_shots_other_value_changed(value: float) -> void:
	Global.config["num_shots_other"] = value
	$Space.trim_and_recolor_shots()

func _on_shots_self_value_changed(value: float) -> void:
	Global.config["num_shots_self"] = value
	$Space.trim_and_recolor_shots()

func _on_glow_toggled(toggled_on: bool) -> void:
	Global.config["glow"] = toggled_on
	get_tree().root.get_node("RootScene").get_node("WorldEnvironment").environment.glow_enabled = Global.config["glow"]

func _on_msaa_item_selected(index: int) -> void:
	Global.config["msaa"] = index
	RenderingServer.viewport_set_msaa_3d(get_tree().root.get_viewport_rid(), Global.config["msaa"])

func _on_btn_ok_rnd_end_pressed() -> void:
	ui.get_node("ScoreBoardMessage").visible = false

func _on_color_self_color_changed(color: Color) -> void:
	Global.config["color_self"] = color
	$Space.update_player_colors()

func _on_color_other_color_changed(color: Color) -> void:
	Global.config["color_other"] = color
	$Space.update_player_colors()
