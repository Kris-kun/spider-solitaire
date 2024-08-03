@tool
extends Control

@export var close_button_visible: bool = false:
	set(value):
		close_button_visible = value
		$MarginContainer/MarginContainer/CloseButton.visible = value
