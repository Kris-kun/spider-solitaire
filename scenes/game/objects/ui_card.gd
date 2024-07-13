class_name UiCard
extends Control

signal drag_started

const TEXTURE_WIDTH := 150
const TEXTURE_HEIGHT := 200
const TEXTURE_SIZE_RATIO := float(TEXTURE_HEIGHT) / float(TEXTURE_WIDTH)

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
		_refresh_textures()
var movable: bool = true:
	set(value):
		movable = value
		_refresh_textures()

var _tableau_pile: UiTableauPile
var _grayout_material

## we need this because the hint animation might have a delay (via await)
## this way, if we start the animation with a delay for 1 second,
## but stop it after 0.5 seconds, it will try to stop it even though it didn't even start
## and after the 1 second timeout, the animation would start anyway
var _hint_animation_explicitly_stopped: bool

@onready var back_texture := $BackTexture
@onready var front_texture := $FrontTexture
@onready var hint_texture := $HintTexture
@onready var invisible_button := $InvisibleButton
@onready var hint_animation := $HintAnimationPlayer


func _ready() -> void:
	_grayout_material = front_texture.material
	_refresh_textures()


func _on_button_gui_input(event) -> void:
	if disabled:
		return
	
	if event is InputEventMouseButton and self.revealed:
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


func tween_finished() -> void:
	if tween != null:
		await tween.finished


func get_tableau_pile() -> UiTableauPile:
	return _tableau_pile


func set_tableau_pile(pile: UiTableauPile) -> void:
	if _tableau_pile == pile:
		return
	
	if _tableau_pile != null:
		_tableau_pile._remove_card(self)
	_tableau_pile = pile
	if _tableau_pile != null:
		_tableau_pile._add_card(self)


func get_card_index() -> int: 
	return get_parent().get_index()


func animate_hint(delay: float = 0.0) -> void:
	_hint_animation_explicitly_stopped = false
	hint_animation.stop()
	if delay > 0.00001:
		await get_tree().create_timer(delay).timeout
		
	if not _hint_animation_explicitly_stopped:
		hint_animation.play("hint_animation")
	else:
		_hint_animation_explicitly_stopped = false


func stop_hint_animation() -> void:
	_hint_animation_explicitly_stopped = true
	hint_animation.stop()


func _refresh_textures() -> void:
	if front_texture == null: return
	
	back_texture.visible = not revealed
	front_texture.visible = revealed
	invisible_button.visible = revealed and not disabled and movable
	front_texture.material = _grayout_material if revealed and not movable else null
	
	if revealed:
		var atlas_region = front_texture.texture.region
		front_texture.texture.region.position.x = (card_type % 13) * atlas_region.size.x
		@warning_ignore("integer_division")
		front_texture.texture.region.position.y = (card_type / 13) * atlas_region.size.y
