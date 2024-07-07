extends Control


func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(800, 400))
	
	$CenterContainer/VBoxContainer/ContinueButton.visible = Savestate.exists()
	
	# add color icons to the buttons
	# we need a space around the icons because otherwise they will be displayed too high
	_append_colors($CenterContainer/VBoxContainer/VBoxContainer/PlayButton1, "♠")
	_append_colors($CenterContainer/VBoxContainer/VBoxContainer/PlayButton2, "♠♥")
	_append_colors($CenterContainer/VBoxContainer/VBoxContainer/PlayButton4, "♠♥♣♦")


func _on_play_pressed(colors: int) -> void:
	match colors:
		1:
			Gamestate.reset(Gamestate.Mode.SINGLE_COLOR)
		2:
			Gamestate.reset(Gamestate.Mode.TWO_COLORS)
		4:
			Gamestate.reset(Gamestate.Mode.FOUR_COLORS)
	
	Gamestate.save()
	SceneUtils.change_scene_to_gamescreen(get_tree())


func _on_continue_pressed() -> void:
	if not Savestate.exists(): # safety
		return
	
	Gamestate.load()
	SceneUtils.change_scene_to_gamescreen(get_tree())


func _on_quit_pressed() -> void:
	get_tree().quit()


func _append_colors(node: Button, colors: String) -> void:
	node.text = " " + colors + " \n" + tr(node.text)
