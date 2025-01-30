class_name HandController
extends Control

@onready var digitEd: LineEdit = $HandControllerDialog/Grid/DigitText
@onready var yawEd: LineEdit = $HandControllerDialog/Grid/YawText
@onready var pitchEd: LineEdit = $HandControllerDialog/Grid/PitchText
@onready var speedEd: LineEdit = $HandControllerDialog/Grid/SpeedText

@export var col: Color

var player: Player

func update_values(pl: Player) -> void:
	if not player:
		Global.root.xr.hand_controller.visible = true
	player = pl
	if not digitEd.has_focus(): digitEd.text = "%.8f" % pow(10, player.digit)
	if not yawEd.has_focus(): yawEd.text = "%.8f" % player.yaw
	if not pitchEd.has_focus(): pitchEd.text = "%.8f" % player.pitch
	if not speedEd.has_focus(): speedEd.text = "%.8f" % player.speed

func _on_digit_p_btn_pressed() -> void:
	player.digit += 1

func _on_digit_m_btn_pressed() -> void:
	player.digit -= 1

func _on_yaw_p_btn_pressed() -> void:
	player.yaw += pow(10, player.digit)

func _on_yaw_m_btn_pressed() -> void:
	player.yaw -= pow(10, player.digit)

func _on_pitch_p_btn_pressed() -> void:
	player.pitch += pow(10, player.digit)

func _on_pitch_m_btn_pressed() -> void:
	player.pitch -= pow(10, player.digit)

func _on_speed_p_btn_pressed() -> void:
	player.speed += pow(10, player.digit)

func _on_speed_m_btn_pressed() -> void:
	player.speed -= pow(10, player.digit)


func _on_yaw_text_text_changed(new_text: String) -> void:
	if yawEd.has_focus(): player.yaw = float(new_text)

func _on_pitch_text_text_changed(new_text: String) -> void:
	if pitchEd.has_focus(): player.pitch = float(new_text)

func _on_speed_text_text_changed(new_text: String) -> void:
	if speedEd.has_focus(): player.speed = float(new_text)

func _on_yaw_text_focus_exited() -> void:
	player.yaw = float(yawEd.text)

func _on_pitch_text_focus_exited() -> void:
	player.pitch = float(pitchEd.text)

func _on_speed_text_focus_exited() -> void:
	player.speed = float(speedEd.text)
