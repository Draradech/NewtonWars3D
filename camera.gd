extends Camera3D

var mouse_move: = Vector2(0.0, 0.0)
var distance: = 2000.0
var pitch: = 0.0
var yaw: = 0.0
var poff: = Vector3.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_move = event.relative
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE, \
			MOUSE_BUTTON_RIGHT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
				mouse_move = Vector2(0, 0)
			MOUSE_BUTTON_WHEEL_UP:
				distance = clamp(distance / 1.05, 100, 3000)
			MOUSE_BUTTON_WHEEL_DOWN:
				distance = clamp(distance * 1.05, 100, 3000)

func _process(_delta):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# camera rotation
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			mouse_move *= 0.25
			yaw -= mouse_move.x
			pitch -= mouse_move.y
			pitch = clamp(pitch, -89, 89)
		# camera move
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			poff += Vector3(-mouse_move.x, mouse_move.y, 0) \
				.rotated(Vector3.RIGHT, deg_to_rad(pitch)) \
				.rotated(Vector3.UP, deg_to_rad(yaw)) * distance / 1000
		mouse_move = Vector2(0, 0)
	
	rotation.x = deg_to_rad(pitch)
	rotation.y = deg_to_rad(yaw)
	var pos = Vector3(0, 0, distance)
	pos = pos.rotated(Vector3.RIGHT, deg_to_rad(pitch))
	pos = pos.rotated(Vector3.UP, deg_to_rad(yaw))
	position = pos + poff
