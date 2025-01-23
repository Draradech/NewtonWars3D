class_name XRSetup
extends XROrigin3D

@export var viewport_back_wall: XRToolsViewport2DIn3D
@export var keyboard: XRToolsViewport2DIn3D
@export var num_keyboard_hand: XRToolsViewport2DIn3D
@export var hand_controller: XRToolsViewport2DIn3D
@export var hand_info_panel: XRToolsViewport2DIn3D
@export var cam: XRCamera3D
@export var laser: XRToolsFunctionPointer
@export var rh_grip: MeshInstance3D

signal shoot

func _on_right_hand_button_pressed(action_name: String) -> void:
	if action_name == "btna_click":
		Global.ui.menu_action()
	if action_name == "btnb_touch":
		if Global.game:
			for pl: Player in Global.game.space.players.values():
				pl.vr_name_label()
	if action_name == "btnb_click":
		var panel_vp: XRToolsViewport2DIn3D = Global.root.xr.hand_info_panel
		var panel: HandInfoPanel = panel_vp.get_scene_instance()
		if panel.debug_stats.visible:
			panel.debug_stats.visible = false
			panel.player_list.visible = true
		else:
			panel.debug_stats.visible = true
			panel.player_list.visible = false

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
	var ang: = rad_to_deg(Vector3.UP.angle_to(rh_grip.global_transform.basis.x))
	var ratio: = clampf(1.0 - (ang - 20.0) / 30.0, 0.0, 1.0)
	if ratio == 0.0:
		hand_info_panel.visible = false
	else:
		hand_info_panel.visible = true
		hand_info_panel.screen_size.y = 0.22 * ratio
		hand_info_panel.position.y = 0.22 * ratio * 0.5
		hand_info_panel.viewport_size.y = 220.0 * ratio

func update_laser() -> void:
	var mesh3d: MeshInstance3D = laser.get_node("Laser")
	var box: BoxMesh = mesh3d.mesh
	var laser_length: float = box.size.z
	var laser_material: ShaderMaterial = laser.laser_material
	laser_material.set_shader_parameter("full_length", laser_length)
	laser_material.set_shader_parameter("fade_length", clampf(laser_length, 0, 0.4))
