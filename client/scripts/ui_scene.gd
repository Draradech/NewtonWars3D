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
	($EscMenu/VBox/GridContainer/MSAA as OptionButton).selected = Global.config["msaa"]
	var msaa: RenderingServer.ViewportMSAA = Global.config["msaa"]
	RenderingServer.viewport_set_msaa_3d(get_tree().root.get_viewport_rid(), msaa)
	if Global.root.xr:
		($EscMenu/VBox/InputHelp as Control).visible = false
		($EscMenu/VBox/GridContainer/Glow as Control).visible = false
		($EscMenu/VBox/GridContainer/GlowLbl as Control).visible = false
		($EscMenu/VBox/GridContainer/UiScale as Control).visible = false
		($EscMenu/VBox/GridContainer/UiScaleLbl as Control).visible = false
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

func picker_closed() -> void:
	esc_menu.visible = true

func picker_open() -> bool:
	return picker_self.visible or picker_other.visible

func close_picker() -> void:
	picker_self.visible = false
	picker_other.visible = false

func menu_action() -> void:
	if picker_open():
		close_picker()
	if not is_menu_open():
		esc_menu.visible = true
	else:
		close_menu()

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

func close_menu() -> void:
	if esc_menu.visible:
		esc_menu.visible = false
		Global.save_config()
	score_message.visible = false
	help_message.visible = false

func is_menu_open() -> bool:
	return \
		main_menu.visible \
		or esc_menu.visible \
		or score_message.visible \
		or disconnect_message.visible \
		or help_message.visible

func _on_name_text_changed(new_text: String) -> void:
	Global.config["name"] = new_text

func _on_host_text_changed(new_text: String) -> void:
	Global.config["host"] = new_text

func _on_port_text_changed(new_text: String) -> void:
	Global.config["port"] = int(new_text)

func _on_continue_pressed() -> void:
	close_menu()

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
	help_message.visible = false

func _on_input_help_pressed() -> void:
	close_menu()
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
	picker_closed()

func _on_color_picker_other_closed() -> void:
	picker_closed()

func _on_color_self_button_pressed() -> void:
	esc_menu.visible = false
	picker_self.visible = true

func _on_color_other_button_pressed() -> void:
	esc_menu.visible = false
	picker_other.visible = true
