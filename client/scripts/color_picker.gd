extends ColorPicker

signal closed

func _ok_pressed() -> void:
	var grand_parent: Control = get_parent().get_parent()
	grand_parent.visible = false
	closed.emit()

func _ready() -> void:
	var ok_button: = Button.new()
	ok_button.text = "OK"
	@warning_ignore("return_value_discarded")
	ok_button.pressed.connect(_ok_pressed)
	var parent: Control = get_parent()
	parent.add_child.call_deferred(ok_button)
	setup_mouse_filters(self)

func setup_mouse_filters(ctrl: Control) -> void:
	for child in ctrl.get_children(true):
		if child is Control:
			var ctrl_child: Control = child
			if ctrl_child.visible:
				if ctrl_child is LineEdit:
					(ctrl_child as LineEdit).select_all_on_focus = false
				elif ctrl_child is SpinBox:
					ctrl_child.mouse_filter = Control.MOUSE_FILTER_STOP
				elif ctrl_child.mouse_filter == Control.MOUSE_FILTER_STOP:
					ctrl_child.mouse_filter = Control.MOUSE_FILTER_PASS
				setup_mouse_filters(ctrl_child)
