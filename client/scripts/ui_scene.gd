class_name UiScene
extends Control

@onready var main_menu: PanelContainer = $MainMenu
@onready var esc_menu: PanelContainer = $EscMenu
@onready var disconnect_message: PanelContainer = $DisconnectMessage
@onready var score_message: PanelContainer = $ScoreMessage
@onready var score_board: RichTextLabel = $ScoreMessage/VBox/ScoreBoard
@onready var help_message: PanelContainer = $HelpMessage
@onready var stats: StatsLabel = $Stats
@onready var missile_input: MissileInput = $MissileInput
@onready var player_list: RichTextLabel = $PlayerList
@onready var round_time: Label = $RoundTime
@onready var picker_self: PanelContainer = $ColorPickerSelfDialog
@onready var picker_other: PanelContainer = $ColorPickerOtherDialog
@onready var picker_self_btn: ColorButton = $EscMenu/VBox/GridContainer/ColorSelfButton
@onready var picker_other_btn: ColorButton = $EscMenu/VBox/GridContainer/ColorOtherButton
@onready var render_res: Label = $VrSettingsDialog/VBox/GridContainer/RenderResLbl
@onready var vr_dialog: PanelContainer = $VrSettingsDialog

func _ready() -> void:
	($MainMenu/VBox/Grid/Name as LineEdit).text = Global.config["name"]
	($MainMenu/VBox/Grid/Host as LineEdit).text = Global.config["host"]
	($MainMenu/VBox/Grid/Port as LineEdit).text = str(Global.config["port"])
	($MainMenu/VBox/Version as Label).text = Version.version
	($ColorPickerSelfDialog/VBox/ColorPickerSelf as ColorPicker).color = Global.config["color_self"]
	picker_self_btn.color = Global.config["color_self"]
	($ColorPickerOtherDialog/VBox/ColorPickerOther as ColorPicker).color = Global.config["color_other"]
	picker_other_btn.color = Global.config["color_other"]
	($EscMenu/VBox/GridContainer/ShotsOther as SpinBox).value = Global.config["num_shots_other"]
	($EscMenu/VBox/GridContainer/ShotsSelf as SpinBox).value = Global.config["num_shots_self"]
	($EscMenu/VBox/GridContainer/UiScale as SpinBox).value = Global.config["ui_scale"]
	($EscMenu/VBox/GridContainer/Glow as CheckBox).button_pressed = Global.config["glow"]
	var msaa: RenderingServer.ViewportMSAA = Global.config["msaa"]
	RenderingServer.viewport_set_msaa_3d(get_tree().root.get_viewport_rid(), msaa)
	($EscMenu/VBox/GridContainer/MSAA as OptionButton).selected = msaa
	($VrSettingsDialog/VBox/GridContainer/MSAA as OptionButton).selected = msaa
	var preset: int = Global.config["vr_preset"]
	($VrSettingsDialog/VBox/GridContainer/Preset as OptionButton).selected = preset
	if preset == 2:
		($VrSettingsDialog/VBox/GridContainer/WorldScale as SpinBox).value = Global.config["world_scale"]
		($VrSettingsDialog/VBox/GridContainer/WorldDst as SpinBox).value = Global.config["world_distance"]
		($VrSettingsDialog/VBox/GridContainer/WorldHeight as SpinBox).value = Global.config["world_height"]
		($VrSettingsDialog/VBox/GridContainer/Rotate as CheckBox).button_pressed = Global.config["world_rotate"]
	else: _on_preset_item_selected(preset)
	if Global.root.xr:
		($EscMenu/VBox/VrSettings as Control).visible = true
		($EscMenu/VBox/InputHelp as Control).visible = false
		($EscMenu/VBox/GridContainer/Glow as Control).visible = false
		($EscMenu/VBox/GridContainer/GlowLbl as Control).visible = false
		($EscMenu/VBox/GridContainer/UiScale as Control).visible = false
		($EscMenu/VBox/GridContainer/UiScaleLbl as Control).visible = false
		($EscMenu/VBox/GridContainer/MSAA as Control).visible = false
		($EscMenu/VBox/GridContainer/MSAALbl as Control).visible = false
		($VrSettingsDialog/VBox/GridContainer/RenderScale as SpinBox).value = Global.config["render_scale"]
		Global.root.xr_interface.render_target_size_multiplier = Global.config["render_scale"]
		var res: = Global.root.xr_interface.get_render_target_size()
		render_res.text = "%dx%d per eye" % [res.x, res.y]
	else:
		var uiscale: float = Global.config["ui_scale"]
		get_tree().root.content_scale_factor = uiscale
		Global.root.world_environment.environment.glow_enabled = Global.config["glow"]
	disable_all_context_menus(self)

func disable_all_context_menus(node: Node) -> void:
	if node is LineEdit:
		(node as LineEdit).context_menu_enabled = false
	for child in node.get_children(true):
		disable_all_context_menus(child)

func close_submenus() -> void:
	score_message.visible = false
	picker_self.visible = false
	picker_other.visible = false
	help_message.visible = false
	vr_dialog.visible = false

func close_menu() -> void:
	if esc_menu.visible:
		esc_menu.visible = false
		Global.save_config()

func menu_action() -> void:
	close_submenus()
	if not is_menu_open():
		esc_menu.visible = true
	elif esc_menu.visible:
		esc_menu.visible = false
		Global.save_config()
	elif score_message.visible:
		_on_btn_ok_rnd_end_pressed()
	elif disconnect_message.visible:
		_on_disconnect_pressed()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		menu_action()
	if Input.is_action_just_pressed("stats"):
		stats.visible = !stats.visible

func game_mode() -> void:
	main_menu.visible = false
	missile_input.visible = true
	player_list.visible = true
	round_time.visible = true

func main_menu_mode() -> void:
	main_menu.visible = true
	missile_input.visible = false
	player_list.visible = false
	round_time.visible = false

func is_menu_open() -> bool:
	return \
		main_menu.visible \
		or esc_menu.visible \
		or score_message.visible \
		or disconnect_message.visible \
		or picker_self.visible \
		or picker_other.visible \
		or help_message.visible \
		or vr_dialog.visible

func _on_name_text_changed(new_text: String) -> void:
	Global.config["name"] = new_text

func _on_host_text_changed(new_text: String) -> void:
	Global.config["host"] = new_text

func _on_port_text_changed(new_text: String) -> void:
	Global.config["port"] = int(new_text)

func _on_continue_pressed() -> void:
	menu_action()

func _on_connect_pressed() -> void:
	Global.save_config()
	Global.root._on_connect()

func _on_quit_pressed() -> void:
	Global.save_config()
	Global.root._on_quit()

func _on_disconnect_pressed() -> void:
	Global.save_config()
	disconnect_message.visible = false
	esc_menu.visible = false
	Global.root._on_disconnect()

func _on_ui_scale_value_changed(value: float) -> void:
	Global.config["ui_scale"] = value
	get_tree().root.content_scale_factor = value

func _on_shots_other_value_changed(value: float) -> void:
	Global.config["num_shots_other"] = value
	if Global.game: Global.game.space.trim_and_recolor_shots()

func _on_shots_self_value_changed(value: float) -> void:
	Global.config["num_shots_self"] = value
	if Global.game: Global.game.space.trim_and_recolor_shots()

func _on_glow_toggled(toggled_on: bool) -> void:
	Global.config["glow"] = toggled_on
	Global.root.world_environment.environment.glow_enabled = Global.config["glow"]

func _on_msaa_item_selected(index: int) -> void:
	Global.config["msaa"] = index
	var msaa: RenderingServer.ViewportMSAA = Global.config["msaa"]
	RenderingServer.viewport_set_msaa_3d(get_tree().root.get_viewport_rid(), msaa)

func _on_btn_ok_rnd_end_pressed() -> void:
	score_message.visible = false

func _on_btn_ok_help_pressed() -> void:
	menu_action()

func _on_input_help_pressed() -> void:
	esc_menu.visible = false
	help_message.visible = true

func _on_color_picker_other_color_changed(color: Color) -> void:
	Global.config["color_other"] = color
	picker_other_btn.color = color
	if Global.game: Global.game.space.update_player_colors()

func _on_color_picker_self_color_changed(color: Color) -> void:
	Global.config["color_self"] = color
	picker_self_btn.color = color
	if Global.game: Global.game.space.update_player_colors()

func _on_color_picker_self_closed() -> void:
	menu_action()

func _on_color_picker_other_closed() -> void:
	menu_action()

func _on_color_self_button_pressed() -> void:
	esc_menu.visible = false
	picker_self.visible = true

func _on_color_other_button_pressed() -> void:
	esc_menu.visible = false
	picker_other.visible = true

var supress_preset: = false
func _on_world_scale_value_changed(value: float) -> void:
	Global.config["world_scale"] = value
	if Global.game: Global.game.scale = Vector3.ONE * 0.001 * Global.config["world_scale"]
	if not supress_preset:
		($VrSettingsDialog/VBox/GridContainer/Preset as OptionButton).selected = 2
		Global.config["vr_preset"] = 2

func _on_rotate_toggled(toggled_on: bool) -> void:
	Global.config["world_rotate"] = toggled_on
	if not supress_preset:
		($VrSettingsDialog/VBox/GridContainer/Preset as OptionButton).selected = 2
		Global.config["vr_preset"] = 2

func _on_world_dst_value_changed(value: float) -> void:
	Global.config["world_distance"] = value
	var height: float = Global.config["world_height"]
	var dist: float = Global.config["world_distance"]
	if Global.game: Global.game.position = Vector3(0, height, -dist)
	if not supress_preset:
		($VrSettingsDialog/VBox/GridContainer/Preset as OptionButton).selected = 2
		Global.config["vr_preset"] = 2

func _on_world_height_value_changed(value: float) -> void:
	Global.config["world_height"] = value
	var height: float = Global.config["world_height"]
	var dist: float = Global.config["world_distance"]
	if Global.game: Global.game.position = Vector3(0, height, -dist)
	Global.root.xr.keyboard.position.y = height - 0.3
	Global.root.xr.viewport_back_wall.position.y = height + 0.4
	if not supress_preset:
		($VrSettingsDialog/VBox/GridContainer/Preset as OptionButton).selected = 2
		Global.config["vr_preset"] = 2

func _on_render_scale_value_changed(value: float) -> void:
	Global.config["render_scale"] = value
	Global.root.xr_interface.render_target_size_multiplier = Global.config["render_scale"]
	var res: = Global.root.xr_interface.get_render_target_size()
	render_res.text = "%dx%d per eye" % [res.x, res.y]

func _on_vr_settings_pressed() -> void:
	esc_menu.visible = false
	vr_dialog.visible = true

func _on_vr_ok_pressed() -> void:
	menu_action()

func _on_preset_item_selected(index: int) -> void:
	supress_preset = true
	match index:
		0:
			# seated
			($VrSettingsDialog/VBox/GridContainer/WorldScale as SpinBox).value = 0.25
			($VrSettingsDialog/VBox/GridContainer/WorldDst as SpinBox).value = 0.5
			($VrSettingsDialog/VBox/GridContainer/WorldHeight as SpinBox).value = 0.7
			($VrSettingsDialog/VBox/GridContainer/Rotate as CheckBox).button_pressed = true
		1:
			# room
			($VrSettingsDialog/VBox/GridContainer/WorldScale as SpinBox).value = 1
			($VrSettingsDialog/VBox/GridContainer/WorldDst as SpinBox).value = 0
			($VrSettingsDialog/VBox/GridContainer/WorldHeight as SpinBox).value = 1.1
			($VrSettingsDialog/VBox/GridContainer/Rotate as CheckBox).button_pressed = false
	supress_preset = false
	Global.config["vr_preset"] = index
