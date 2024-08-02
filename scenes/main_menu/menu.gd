extends Control

var _pressed_colors: int


func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(800, 400))
	
	$CenterContainer/VBoxContainer/VBoxContainer/ContinueButton.visible = Savestate.exists()
	
	# add color icons to the buttons
	# we need a space around the icons because otherwise they will be displayed too high
	_append_colors($CenterContainer/VBoxContainer/VBoxContainer/PlayButton1, "♠")
	_append_colors($CenterContainer/VBoxContainer/VBoxContainer/PlayButton2, "♠♥")
	_append_colors($CenterContainer/VBoxContainer/VBoxContainer/PlayButton4, "♠♥♣♦")
	
	#$CenterContainer/VBoxContainer/ContinueButton.grab_focus()
	
	$ConfirmationDialog.get_ok_button().focus_mode = FOCUS_NONE
	$ConfirmationDialog.get_cancel_button().focus_mode = FOCUS_NONE


func _on_play_pressed(colors: int) -> void:
	if Savestate.exists():
		_pressed_colors = colors
		$PopupPanel.show()
		$ConfirmationDialog.show()
		return
	else:
		_start_game(colors)


func _start_game(colors: int) -> void:
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


func _on_confirmation_dialog_canceled() -> void:
	$PopupPanel.hide()


func _on_confirmation_dialog_confirmed() -> void:
	$PopupPanel.hide()
	_start_game(_pressed_colors)


func _on_settings_pressed() -> void:
	SceneUtils.change_scene_to_settings(get_tree())


func _on_language_button_pressed() -> void:
	$PopupPanel.show()
	$AcceptDialog.show()
	return


func _on_accept_dialog_confirmed() -> void:
	$PopupPanel.hide()
