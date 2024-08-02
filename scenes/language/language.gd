extends Control


@onready var languages_list := $VBoxContainer/ScrollContainer/ItemList


func _ready() -> void:
	_init_language_items()


func _init_language_items() -> void:
	for locale in TranslationServer.get_loaded_locales():
		var language_name := TranslationServer.get_translation_object(locale).get_message("LANGUAGE_NAME")
		var language_texture := load("res://assets/img/lang/" + locale + ".png")
		var idx: int = languages_list.add_item(language_name, language_texture)
		if locale == Settings.global.locale:
			languages_list.select(idx)


func _on_item_list_item_selected(index: int) -> void:
	var locale := TranslationServer.get_loaded_locales()[index]
	TranslationServer.set_locale(locale)
	Settings.global.locale = locale
	Settings.save()
