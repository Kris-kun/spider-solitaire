extends Control


func _ready() -> void:
	$CenterContainer/VBoxContainer/VBoxContainer/ContinueButton.visible = Savestate.exists()


func _on_play_pressed(colors: int) -> void:
	match colors:
		1:
			Gamestate.reset(Gamestate.Mode.SINGLE_COLOR)
		2:
			Gamestate.reset(Gamestate.Mode.TWO_COLORS)
		4:
			Gamestate.reset(Gamestate.Mode.FOUR_COLORS)
		_:
			Gamestate.reset() # safety. shouldn't happen though
	
	Gamestate.save()
	
	_open_gamescreen()


func _on_continue_pressed() -> void:
	if not Savestate.exists(): # safety
		return
	
	Gamestate.load()
	_open_gamescreen()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _open_gamescreen():
	get_tree().change_scene_to_file("res://scenes/game/gamescreen.tscn")
	#var asdf = preload("res://gamescreen.tscn") #.instantiate()
	#get_tree().change_scene_to_packed(asdf)
