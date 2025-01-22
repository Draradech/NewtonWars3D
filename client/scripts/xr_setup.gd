class_name XRSetup
extends XROrigin3D

@export var viewport_back_wall: XRToolsViewport2DIn3D
@export var keyboard: XRToolsViewport2DIn3D
@export var num_keyboard_hand: XRToolsViewport2DIn3D
@export var hand_controller: XRToolsViewport2DIn3D
@export var cam: XRCamera3D
@export var laser: XRToolsFunctionPointer

signal shoot

func _on_right_hand_button_pressed(action_name: String) -> void:
	if action_name == "btna_click":
		Global.ui.menu_action()
	if action_name == "btnb_touch":
		if Global.game:
			for pl: Player in Global.game.space.players.values():
				pl.vr_name_label()
	if action_name == "btnb_click":
		#cycle info panel
		pass

func _on_right_hand_button_released(action_name: String) -> void:
	if action_name == "btnb_touch":
		if Global.game:
			for pl: Player in Global.game.space.players.values():
				pl.name_label.visible = false

func _on_left_hand_button_pressed(action_name: String) -> void:
	if action_name == "trigger_click":
		shoot.emit()
	if action_name == "btna_click":
		Global.game.space.clear_shots()
	if action_name == "btnb_click":
		Global.game.space.reset_aim()

func _process(_delta: float) -> void:
	var vp: Viewport = viewport_back_wall.get_node("Viewport")
	var focus: = vp.gui_get_focus_owner()
	keyboard.visible = (focus is LineEdit)
	vp = hand_controller.get_node("Viewport")
	focus = vp.gui_get_focus_owner()
	num_keyboard_hand.visible = (focus is LineEdit)
	update_laser.call_deferred()

func update_laser() -> void:
	var laser_length: float = laser.get_node("Laser").mesh.size.z
	laser.laser_material.set_shader_parameter("full_length", laser_length)
	laser.laser_material.set_shader_parameter("fade_length", clampf(laser_length, 0, 0.4))
