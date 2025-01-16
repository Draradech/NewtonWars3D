@tool
extends EditorPlugin

var exporter
func _enter_tree() -> void:
	exporter = GitVersionExporterPlugin.new()
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)

class GitVersionExporterPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return "GitVersionExporterPlugin"
	
	func get_git_commit_count() -> String:
		var output: Array = []
		OS.execute("git", PackedStringArray(["rev-list", "--count", "HEAD"]), output)
		if output.is_empty() or output[0].is_empty():
			push_error("Failed to fetch version. Make sure you have git installed and project is inside a valid git directory.")
			return ""
		return output[0].trim_suffix("\n")
	
	func get_git_commit_hash() -> String:
		var output: Array = []
		OS.execute("git", PackedStringArray(["rev-parse", "--short=8", "HEAD"]), output)
		if output.is_empty() or output[0].is_empty():
			push_error("Failed to fetch version. Make sure you have git installed and project is inside a valid git directory.")
			return ""
		return output[0].trim_suffix("\n")
	
	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		var version: = "0.1."
		version += get_git_commit_count()
		ProjectSettings.set_setting("application/config/version", version)
		ProjectSettings.save()
		version += "-"
		version += get_git_commit_hash()
		print(version)
		var script: GDScript = GDScript.new()
		script.source_code = "extends Node\nconst version: String = \"%s\"" % version
		var err: int = ResourceSaver.save(script, "res://scripts/version.gd")
		if err:
			push_error("Failed to save version as script. Error: %s" % error_string(err))
