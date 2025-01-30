@tool
class_name XRToolsVirtualKeyboard2D
extends XRToolsVirtualKeyboardBase2D


## Enumeration of keyboard view modes
enum KeyboardMode {
	LOWER_CASE,		## Lower-case keys mode
	UPPER_CASE,		## Upper-case keys mode
	ALTERNATE		## Alternate keys mode
}


# Shift button down
var _shift_down := false

# Caps button down
var _caps_down := false

# Alt button down
var _alt_down := false

# Current keyboard mode
var _mode: int = KeyboardMode.LOWER_CASE


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return super(name) or name == "XRToolsVirtualKeyboard2D"


# Handle key pressed from VirtualKeyChar
func on_key_pressed(scan_code_text: String, unicode: int, shift: bool):
	# Find the scan code
	var scan_code := OS.find_keycode_from_string(scan_code_text)

	# Create the InputEventKey
	var input := InputEventKey.new()
	input.physical_keycode = scan_code
	input.unicode = unicode if unicode else scan_code
	input.pressed = true
	input.keycode = scan_code
	input.shift_pressed = shift

	# Dispatch the input event
	Input.parse_input_event(input)

	# Pop any temporary shift key
	if _shift_down:
		_shift_down = false
		_update_visible()


func _on_toggle_shift(pressed: bool) -> void:
	# Update toggle keys
	_shift_down = pressed
	_caps_down = false
	_alt_down = false
	_update_visible()


func _on_toggle_caps(pressed: bool) -> void:
	# Update toggle keys
	_caps_down = pressed
	_shift_down = false
	_alt_down = false
	_update_visible()


func _on_toggle_alt(pressed: bool) -> void:
	# Update toggle keys
	_alt_down = pressed
	_shift_down = false
	_caps_down = false
	_update_visible()


# Update switching the visible case keys
func _update_visible() -> void:
	# Ensure the control buttons are set correctly
	$Background/Standard/ToggleShift.set_toggle_state(_shift_down)
	$Background/Standard/ToggleCaps.set_toggle_state(_caps_down)
	$Background/Standard/ToggleAlt.set_toggle_state(_alt_down)

	# Evaluate the new mode
	var new_mode: int
	if _alt_down:
		new_mode = KeyboardMode.ALTERNATE
	elif _shift_down or _caps_down:
		new_mode = KeyboardMode.UPPER_CASE
	else:
		new_mode = KeyboardMode.LOWER_CASE

	# Skip if no change
	if new_mode == _mode:
		return

	# Update the visible mode
	_mode = new_mode
	$Background/LowerCase.visible = _mode == KeyboardMode.LOWER_CASE
	$Background/UpperCase.visible = _mode == KeyboardMode.UPPER_CASE
	$Background/Alternate.visible = _mode == KeyboardMode.ALTERNATE
