class_name SceneUtils


static func change_scene_to_menu(tree: SceneTree) -> void:
	change_scene(tree, "res://scenes/main_menu/menu.tscn")


static func change_scene_to_gamescreen(tree: SceneTree) -> void:
	change_scene(tree, "res://scenes/game/gamescreen.tscn")


static func change_scene(tree: SceneTree, path: String) -> void:
	# on android, i got ERROR: can_process: Condition "!is_inside_tree()" is true. Returned: false
	# people said this would crash when exporting with RELEASE instead of DEBUG where it would just print the error
	# so we have to work around this by deferring the call until this bug is fixed
	tree.call_deferred("change_scene_to_file", path)
