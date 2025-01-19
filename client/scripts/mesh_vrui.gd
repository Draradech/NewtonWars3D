extends MeshInstance3D

const NO_INTERSECTION: = Vector2(-1, -1)

@export var controller: XRController3D
@export var button_action: = "trigger_click"
@export var layer_viewport: SubViewport
@onready var pointer: MeshInstance3D = $Pointer

var was_pressed: = false
var was_intersect: = NO_INTERSECTION

func _intersect_to_global_pos(intersect: Vector2) -> Vector3:
	if intersect != NO_INTERSECTION:
		var local_pos: = (intersect - Vector2(.5, .5)) * (mesh as QuadMesh).size
		return global_transform * Vector3(local_pos.x, -local_pos.y, 0)
	else:
		return Vector3()

func _intersect_to_viewport_pos(intersect: Vector2) -> Vector2i:
	if layer_viewport and intersect != NO_INTERSECTION:
		var pos: = intersect * Vector2(layer_viewport.size)
		return Vector2i(pos)
	else:
		return Vector2i(-1, -1)

func _intersects_ray(origin: Vector3, direction: Vector3) -> Vector2:
	var quad_size: = (mesh as QuadMesh).size
	var quad_transform: = get_global_transform()
	var quad_normal: = quad_transform.basis.z
	
	var denom: = quad_normal.dot(direction)
	if absf(denom) > 0.0001 :
		var vector: = quad_transform.origin - origin
		var t: = vector.dot(quad_normal) / denom
		if t < 0.0:
			return NO_INTERSECTION
		var intersection: = origin + direction * t
		
		var relative_point: = intersection - quad_transform.origin
		var projected_point: = Vector2(
				relative_point.dot(quad_transform.basis.x),
				relative_point.dot(quad_transform.basis.y))
		if absf(projected_point.x) > quad_size.x / 2.0:
			return NO_INTERSECTION
		if absf(projected_point.y) > quad_size.y / 2.0:
			return NO_INTERSECTION
		
		var u: = 0.5 + (projected_point.x / quad_size.x)
		var v: = 1.0 - (0.5 + (projected_point.y / quad_size.y))
		
		return Vector2(u, v)
	
	return Vector2(-1.0, -1.0);

func _process(_delta: float) -> void:
	pointer.visible = false
	if controller and layer_viewport:
		var controller_t: = controller.global_transform
		var intersect: = _intersects_ray(controller_t.origin, -controller_t.basis.z)
		if intersect != NO_INTERSECTION:
			var is_pressed: = controller.is_button_pressed(button_action)
			var pos: =_intersect_to_global_pos(intersect)
			pointer.visible = true
			pointer.global_position = pos
			if was_intersect != NO_INTERSECTION and intersect != was_intersect:
				var event: = InputEventMouseMotion.new()
				var from: = _intersect_to_viewport_pos(was_intersect)
				var to: = _intersect_to_viewport_pos(intersect)
				if was_pressed:
					event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.relative = to - from
				event.position = to
				layer_viewport.push_input(event)
			if not is_pressed and was_pressed:
				var event: = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = false
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)
			elif is_pressed and not was_pressed:
				var event: = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.pressed = true
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)
			was_pressed = is_pressed
			was_intersect = intersect
		else:
			was_pressed = false
			was_intersect = NO_INTERSECTION
