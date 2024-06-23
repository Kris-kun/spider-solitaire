extends Control


# temporary. TODO: remove
func _ready() -> void:
	call_deferred("_on_play_pressed", 1)


func _on_play_pressed(colors: int):
	match colors:
		1:
			Gamestate.reset(Gamestate.Mode.SINGLE_COLOR)
		2:
			Gamestate.reset(Gamestate.Mode.TWO_COLORS)
		4:
			Gamestate.reset(Gamestate.Mode.FOUR_COLORS)
		_:
			Gamestate.reset() # safety. shouldn't happen though
	
	get_tree().change_scene_to_file("res://scenes/game/gamescreen.tscn")
	#var asdf = preload("res://gamescreen.tscn") #.instantiate()
	#get_tree().change_scene_to_packed(asdf)


func _on_quit_pressed():
	get_tree().quit()

