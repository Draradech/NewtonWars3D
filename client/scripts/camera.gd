class_name MainCamera
extends Camera3D

var mouse_move: = Vector2(0.0, 0.0)
var distance: = 2000.0
var pitch: = 0.0
var yaw: = 0.0
var poff: = Vector3.ZERO
var root: RootScene

var checked: = false
func _input(event: InputEvent) -> void:
	if not root.game: return
	
	if event is InputEventMouseMotion:
		var iemm: InputEventMouseMotion = event
		mouse_move = iemm.screen_relative
	
	if event is InputEventMouseButton:
		var iemb: InputEventMouseButton = event
		match iemb.button_index:
			MOUSE_BUTTON_MIDDLE, \
			MOUSE_BUTTON_RIGHT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if iemb.pressed else Input.MOUSE_MODE_VISIBLE)
				mouse_move = Vector2(0, 0)
			MOUSE_BUTTON_WHEEL_UP:
				distance = clamp(distance / 1.05, 10, 3000)
			MOUSE_BUTTON_WHEEL_DOWN:
				distance = clamp(distance * 1.05, 10, 3000)
			MOUSE_BUTTON_LEFT:
				if iemb.double_click:
					var ray_dir: = project_ray_normal(get_viewport().get_mouse_position())
					var target_pos: = root.game.space.find_closest_intersection(position, ray_dir)
					if target_pos.x < 10000.0:
						@warning_ignore("return_value_discarded")
						create_tween().tween_method(func(value: Vector3) -> void: poff = value, poff, target_pos, .5).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	if not root.game: return
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		# camera rotation
		if \
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
		and not Input.is_key_pressed(KEY_CTRL):
			mouse_move *= 0.25
			yaw -= mouse_move.x
			pitch -= mouse_move.y
		
		# camera move
		if \
		Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) \
		or (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		and Input.is_key_pressed(KEY_CTRL)
		):
			poff += Vector3(-mouse_move.x, mouse_move.y, 0) \
				.rotated(Vector3.RIGHT, deg_to_rad(pitch)) \
				.rotated(Vector3.UP, deg_to_rad(yaw)) * distance / 1000
		mouse_move = Vector2(0, 0)
	
	# camera move
	if Input.is_key_pressed(KEY_CTRL):
		var off: = Vector3.ZERO
		if Input.is_key_pressed(KEY_I):
			off.y -= 200 * delta;
		if Input.is_key_pressed(KEY_K):
			off.y += 200 * delta;
		if Input.is_key_pressed(KEY_J):
			off.x += 200 * delta;
		if Input.is_key_pressed(KEY_L):
			off.x -= 200 * delta;
		poff += off \
			.rotated(Vector3.RIGHT, deg_to_rad(pitch)) \
			.rotated(Vector3.UP, deg_to_rad(yaw)) * distance / 1000
	
	# camera rotation
	else:
		if Input.is_key_pressed(KEY_I):
			pitch += 50 * delta;
		if Input.is_key_pressed(KEY_K):
			pitch -= 50 * delta;
		if Input.is_key_pressed(KEY_J):
			yaw += 50 * delta;
		if Input.is_key_pressed(KEY_L):
			yaw -= 50 * delta;
	
	# camera distance
	if Input.is_key_pressed(KEY_U):
		distance = clamp(distance / pow(2, delta), 10, 3000)
	if Input.is_key_pressed(KEY_O):
		distance = clamp(distance * pow(2, delta), 10, 3000)
	
	pitch = clamp(pitch, -89, 89)
	rotation.x = deg_to_rad(pitch)
	rotation.y = deg_to_rad(yaw)
	var pos: = Vector3(0, 0, distance)
	pos = pos.rotated(Vector3.RIGHT, deg_to_rad(pitch))
	pos = pos.rotated(Vector3.UP, deg_to_rad(yaw))
	position = pos + poff
