class_name UiTableau
extends Control

# we can't use the cardContainer in _add_card because cards are added to a temporary
# tableau before adding it to the scene
@onready var _card_container: LineOrientation = $LineOrientation
@onready var _texture = $TextureRect


func _ready():
	# why the hell can we not change the internal mode without reading it?
	#remove_child(texture)
	#add_child(texture, false, INTERNAL_MODE_FRONT)
	_texture.size = Vector2(size.x, size.x * UiCard.TEXTURE_SIZE_RATIO)
	
	_card_container.set_spacing_calculation(_calculate_spacing)


func _calculate_spacing(node: Control) -> float:
	return 50 if node.get_child(0).revealed else 20


func _notification(what: int):
	if _texture == null:
		return
	
	match what:
		NOTIFICATION_RESIZED:
			_texture.size = Vector2(size.x, size.x*UiCard.TEXTURE_SIZE_RATIO)


func add_card(card: UiCard):
	card.set_tableau(self)


func _add_card(card: UiCard):
	var parent = Control.new()
	parent.add_child(card)
	$LineOrientation.add_child(parent)
	#$LineOrientation.add_child(card)


func remove_card(card: UiCard):
	card.set_tableau(null)


func _remove_card(card: UiCard):
	$LineOrientation.remove_child(card.get_parent())
	card.get_parent().remove_child(card)
	#$LineOrientation.remove_child(card)


func get_cards():
	return _card_container.get_children().map(func(parent): return parent.get_child(0))
	#return _card_container.get_children()


func get_card(idx: int) -> UiCard:
	return _card_container.get_child(idx).get_child(0)
	#return _card_container.get_child(idx)


func get_card_count() -> int:
	return _card_container.get_child_count()


func reveal_topmost_card():
	if get_card_count() > 0:
		get_card(-1).revealed = true
