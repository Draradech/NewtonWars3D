@tool
extends EditorPlugin

var exporter
func _enter_tree() -> void:
	exporter = GitVersionExporterPlugin.new()
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)

func _build() -> bool:
	exporter.update_version()
	return true

class GitVersionExporterPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "GitVersionExporterPlugin"
	
	func get_git_description() -> String:
		var output: Array = []
		OS.execute("git", PackedStringArray(["describe", "--tags", "--dirty", "--match", "v*"]), output)
		if output.is_empty() or output[0].is_empty():
			push_error("Failed to fetch version. Make sure you have git installed and project is inside a valid git directory.")
			return "v0.0.0-unknown"
		return output[0].trim_suffix("\n")
	
	func update_version():
		var version: = get_git_description()
		var stripped: = version.trim_prefix("v").split("-")[0]
		ProjectSettings.set_setting("application/config/version", stripped)
		var script: GDScript = GDScript.new()
		script.source_code = "extends Node\nconst version: String = \"%s\"" % version
		var err: int = ResourceSaver.save(script, "res://scripts/version.gd")
		if err:
			push_error("Failed to save version as script. Error: %s" % error_string(err))
	
	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		update_version()
