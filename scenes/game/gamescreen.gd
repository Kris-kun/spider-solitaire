extends Control


@onready var win_screen_container := $WinScreenContainer
@onready var tableau := $Tableau


func _ready():
	win_screen_container.visible = false
	tableau.game_finished.connect(_on_game_finished)
	NotificationHandler.notification_added.connect(_on_notification_added)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_XBUTTON1:
			if event.pressed:
				get_viewport().set_input_as_handled()
				tableau.undo()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed():
		match event.keycode:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				SceneUtils.change_scene_to_menu(get_tree())
			KEY_Z: # basically ctrl+z but using ctrl is useless here
				get_viewport().set_input_as_handled()
				_on_undo_pressed()
			KEY_H: # h = hint
				get_viewport().set_input_as_handled()
				_on_hint_pressed()


func _on_game_finished() -> void:
	win_screen_container.visible = true


func _on_undo_pressed() -> void:
	tableau.undo()


func _on_menu_pressed() -> void:
	SceneUtils.change_scene_to_menu(get_tree())


func _on_replay_pressed() -> void:
	Gamestate.reset(Gamestate.Mode.SAME_COLOR_SAME_SEED)
	win_screen_container.visible = false
	tableau.reset_cards()


func _on_newgame_pressed() -> void:
	Gamestate.reset(Gamestate.Mode.SAME_COLOR_DIFFERENT_SEED)
	win_screen_container.visible = false
	tableau.reset_cards()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_hint_pressed() -> void:
	var hint_available: bool = tableau.show_hint()
	if not hint_available:
		NotificationHandler.add(
			NotificationHandler.NotificationType.HINT,
			"NOTIFICATION_HINT",
			$Header/HintButton,
			TransformUtils.Anchor.CENTER_LEFT
		)


func _on_notification_added(notification: Notification) -> void:
	add_child(notification)
