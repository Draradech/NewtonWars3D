class_name XRSetup
extends XROrigin3D

@export var viewport_back_wall: XRToolsViewport2DIn3D
@export var keyboard: XRToolsViewport2DIn3D

signal shoot

func _on_right_hand_button_pressed(action_name: String) -> void:
	if action_name == "btna_click":
		Global.ui.menu_action()

func _on_left_hand_button_pressed(action_name: String) -> void:
	if action_name == "trigger_click":
		if not Global.ui.is_menu_open():
			shoot.emit()

func _process(_delta: float) -> void:
	var vp: Viewport = viewport_back_wall.get_node("Viewport")
	var focus: = vp.gui_get_focus_owner()
	keyboard.visible = (focus is LineEdit)
