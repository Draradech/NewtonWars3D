class_name ColorButton
extends Button

@export var color: Color

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		var r: = Rect2(Vector2(4, 4), size - Vector2(8, 8))
		draw_rect(r, color)
