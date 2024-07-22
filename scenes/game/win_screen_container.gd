extends Control

signal menu_pressed
signal replay_pressed
signal newgame_pressed
signal quit_pressed


func _on_menu_pressed() -> void:
	menu_pressed.emit()


func _on_replay_pressed() -> void:
	replay_pressed.emit()


func _on_newgame_pressed() -> void:
	newgame_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
