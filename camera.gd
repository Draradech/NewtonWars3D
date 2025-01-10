class_name OrbitCamera extends Camera3D

# Mouse state
var _mouse_move = Vector2(0.0, 0.0)

# Movement state
var _distance = 2000
var _pitch = 0
var _yaw = 0
var poff: = Vector3.ZERO

func _input(event):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_move = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_RIGHT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_WHEEL_UP: # Decreases distance
				_distance = clamp(_distance / 1.05, 100, 3000)
			MOUSE_BUTTON_WHEEL_DOWN: # Increases distance
				_distance = clamp(_distance * 1.05, 100, 3000)

func _process(_delta):
	var pos = Vector3(0, 0, _distance)
	
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			_mouse_move *= 0.25
			_yaw -= _mouse_move.x
			_pitch -= _mouse_move.y
			_mouse_move = Vector2(0, 0)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			poff += Vector3(-_mouse_move.x, _mouse_move.y, 0) \
				.rotated(Vector3.RIGHT, deg_to_rad(_pitch)) \
				.rotated(Vector3.UP, deg_to_rad(_yaw)) * _distance / 1000
			_mouse_move = Vector2(0, 0)
			
		# Prevents looking up/down too far
		_pitch = clamp(_pitch, -89, 89)
	
	rotation.x = deg_to_rad(_pitch)
	rotation.y = deg_to_rad(_yaw)
	pos = pos.rotated(Vector3.RIGHT, deg_to_rad(_pitch))
	pos = pos.rotated(Vector3.UP, deg_to_rad(_yaw))
	position = pos + poff
