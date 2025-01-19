extends ColorPickerButton

func _on_picker_created() -> void:
	var picker: = get_picker()
	var popup: = get_popup()
	picker.can_add_swatches = false
	picker.sampler_visible = false
	picker.color_modes_visible = false
	picker.hex_visible = false
	picker.presets_visible = false
	var threedot: HBoxContainer = picker.get_child(0, true).get_child(0, true).get_child(5, true)
	threedot.visible = false
	var panel: Panel = popup.get_child(0, true)
	panel.remove_theme_stylebox_override("panel")
