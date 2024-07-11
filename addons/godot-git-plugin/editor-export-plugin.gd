@tool
extends EditorExportPlugin

const PATH_EXTENSION_DEF = "res://.godot/extension_list.cfg"

var extension_definition_buffer : String

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var file_extension_list := FileAccess.open(PATH_EXTENSION_DEF, FileAccess.READ)
	var extensions : String = file_extension_list.get_as_text()
	file_extension_list.close()

	extension_definition_buffer = extensions
	var lines : PackedStringArray = extensions.split("\n")
	var extensions_without_git : String = ""
	for line in lines:
		if "git_plugin.gdextension" in line:
			continue
		extensions_without_git += line + "\n"
	extensions_without_git = extensions_without_git.trim_suffix("\n")

	file_extension_list = FileAccess.open(PATH_EXTENSION_DEF, FileAccess.WRITE)
	file_extension_list.store_string(extensions_without_git)
	file_extension_list.close()

func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if "godot-git-plugin" in path:
		skip()

func _export_end() -> void:
	var file_extension_list := FileAccess.open(PATH_EXTENSION_DEF, FileAccess.WRITE)
	file_extension_list.store_string(extension_definition_buffer)
	file_extension_list.close()

func _get_name() -> String:
	return "ZZ-git-export-plugin"
