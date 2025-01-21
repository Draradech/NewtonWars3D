extends PanelContainer

func get_first_focusable_child(node: Node) -> Control:
	if node is Control:
		if (node as Control).visible:
			if (node as Control).focus_mode != Control.FOCUS_NONE:
				return node
		else:
			return null
	for child in node.get_children(true):
		var found: = get_first_focusable_child(child)
		if found:
			return found
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var focus: = get_viewport().gui_get_focus_owner()
		if focus:
			focus.release_focus()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		if not Rect2(global_position, size).has_point((event as InputEventMouseButton).position):
			var focus: = get_viewport().gui_get_focus_owner()
			if focus:
				focus.release_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_focus_next"):
		if not get_viewport().gui_get_focus_owner():
			var first_focusable: = get_first_focusable_child(self)
			if first_focusable:
				first_focusable.grab_focus()
