@tool
class_name XRToolsVirtualKey
extends Node2D


## Key pressed event
signal pressed


## Key size
@export var key_size := Vector2(32, 32) : set = _set_key_size

## Key text
@export var key_text := "" : set = _set_key_text


# Button node
var _button: Button


# Called when the node enters the scene tree for the first time.
func _ready():
	_button = Button.new()
	_button.focus_mode = Control.FOCUS_NONE
	add_child(_button)
	_button.pressed.connect(_on_button_pressed)
	_update_key_size()
	_update_key_text()


func _on_button_pressed() -> void:
	pressed.emit()


func _set_key_size(p_key_size : Vector2) -> void:
	key_size = p_key_size
	if is_inside_tree():
		_update_key_size()


func _set_key_text(p_key_text : String) -> void:
	key_text = p_key_text
	if is_inside_tree():
		_update_key_text()


func _update_key_size() -> void:
	_button.size = key_size


func _update_key_text() -> void:
	_button.text = key_text
