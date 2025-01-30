@tool
class_name XRToolsVirtualKeyToggle
extends XRToolsVirtualKey


# Key toggle event
signal toggled(toggled_on: bool)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Call the base
	super()
	_button.toggle_mode = true
	_button.toggled.connect(_on_button_toggled)


func _on_button_toggled(toggled_on: bool) -> void:
	toggled.emit(toggled_on)


func set_toggle_state(toggled: bool) -> void:
	_button.button_pressed = toggled
