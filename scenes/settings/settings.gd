extends Control


var tmp_settings := Settings.global.duplicate(true)

@onready var animation_speed_slider := $VBoxContainer/CenterContainer/VBoxContainer/HBoxContainer/AnimationSpeedSlider

func _ready() -> void:
	_init_from_settings()


func _init_from_settings() -> void:
	animation_speed_slider.value = 1.0 / tmp_settings.animation_time_multiplier


func _on_animation_speed_value_changed(value: float) -> void:
	tmp_settings.animation_time_multiplier = 1.0 / value


func _on_apply_button_pressed() -> void:
	Settings.global = tmp_settings
	Settings.save()
	SceneUtils.change_scene_to_menu(get_tree())


func _on_default_button_pressed() -> void:
	tmp_settings = Settings.new()
	_init_from_settings()


func _on_cancel_button_pressed() -> void:
	SceneUtils.change_scene_to_menu(get_tree())
