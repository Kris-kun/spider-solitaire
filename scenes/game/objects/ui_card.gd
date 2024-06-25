class_name UiCard
extends Control

signal drag_started

const TEXTURE_WIDTH = 150
const TEXTURE_HEIGHT = 200
const TEXTURE_SIZE_RATIO = float(TEXTURE_HEIGHT) / float(TEXTURE_WIDTH)

var tween: Tween

var card_type: int:
	set(value):
		if value < 0 || value >= 52:
			return
		card_type = value
		_refresh_textures()

var revealed: bool:
	set(value):
		revealed = value
		_refresh_textures()
var disabled: bool:
	set(value):
		disabled = value
		$InvisibleButton.visible = revealed and not disabled

var _tableau

@onready var back_texture := $BackTexture
@onready var front_texture := $FrontTexture
@onready var invisible_button := $InvisibleButton


func _ready():
	_refresh_textures()


func _on_button_gui_input(event):
	if disabled:
		return
	
	if event is InputEventMouseButton && self.revealed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_started.emit(self)


func stop_tween() -> void:
	if tween != null:
		tween.pause()
		tween.custom_step(100.0) # i hope no animation is longer than 100 seconds
		tween.kill()
		tween = null


func stop_and_create_tween() -> void:
	stop_tween()
	tween = create_tween()


func get_tableau():
	return _tableau


func set_tableau(tableau: UiTableau):
	if _tableau == tableau:
		return
	
	if _tableau != null:
		_tableau._remove_card(self)
	_tableau = tableau
	if _tableau != null:
		_tableau._add_card(self)


func get_card_index() -> int:
	return get_parent().get_index()
	#return get_index()


func _refresh_textures():
	if front_texture == null: return
	
	back_texture.visible = not revealed
	front_texture.visible = revealed
	invisible_button.visible = revealed and not disabled
	if revealed:
		var atlas_region = front_texture.texture.region
		front_texture.texture.region.position.x = (card_type % 13) * atlas_region.size.x
		@warning_ignore("integer_division")
		front_texture.texture.region.position.y = (card_type / 13) * atlas_region.size.y
