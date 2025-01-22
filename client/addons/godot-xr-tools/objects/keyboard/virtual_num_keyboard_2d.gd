@tool
class_name XRToolsVirtualNumKeyboard2D
extends XRToolsVirtualKeyboardBase2D


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return super(name) or name == "XRToolsVirtualNumKeyboard2D"


# Handle key pressed from VirtualKey
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
