@tool
extends EditorPlugin

var export_plugin = preload("editor-export-plugin.gd").new()

func _enter_tree() -> void:
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
