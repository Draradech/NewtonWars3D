class_name OrbitCamera extends Camera3D

# Mouse state
var _mouse_move = Vector2(0.0, 0.0)

# Movement state
var _distance = 2000
var _pitch = 0
var _yaw = 0

func _input(event):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_move = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT: # Only allows rotation if right click down
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_WHEEL_UP: # Decreases distance
				_distance = clamp(_distance / 1.1, 1, 2000)
			MOUSE_BUTTON_WHEEL_DOWN: # Increases distance
				_distance = clamp(_distance * 1.1, 1, 2000)

func _process(_delta):
	var pos = Vector3(0, 0, _distance)
	
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_move *= 0.25
		_yaw -= _mouse_move.x
		_pitch -= _mouse_move.y
		_mouse_move = Vector2(0, 0)
		
		# Prevents looking up/down too far
		_pitch = clamp(_pitch, -80, 80)
	
	rotation.x = deg_to_rad(_pitch)
	rotation.y = deg_to_rad(_yaw)
	pos = pos.rotated(Vector3.RIGHT, deg_to_rad(_pitch))
	pos = pos.rotated(Vector3.UP, deg_to_rad(_yaw))
	position = pos
