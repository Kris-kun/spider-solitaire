extends Control


@onready var animation_speed_slider := $VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/AnimationSpeedSlider


func _ready() -> void:
	animation_speed_slider.value = 1.0 / Settings.animation_time_multiplier


func _on_animation_speed_value_changed(value: float) -> void:
	Settings.animation_time_multiplier = 1.0 / value


func _on_back_button_pressed() -> void:
	SceneUtils.change_scene_to_menu(get_tree())


func _on_default_button_pressed() -> void:
	animation_speed_slider.value = 1.0
