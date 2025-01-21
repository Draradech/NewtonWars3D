class_name XRSetup
extends XROrigin3D

@export var viewport_back_wall: XRToolsViewport2DIn3D
@export var keyboard: XRToolsViewport2DIn3D

signal shoot

func _on_right_hand_button_pressed(action_name: String) -> void:
	if action_name == "btna_click":
		if Global.ui.help_message.visible:
			Global.ui.help_message.visible = false
		else:
			Global.ui.esc_menu.visible = !Global.ui.esc_menu.visible
			if !Global.ui.esc_menu.visible:
				Global.save_config()
	if action_name == "trigger_click":
		if not Global.ui.is_menu_open():
			shoot.emit()
