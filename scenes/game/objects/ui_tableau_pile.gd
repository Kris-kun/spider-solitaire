class_name UiTableauPile
extends Control

# we can't use the cardContainer in _add_card because cards are added to a temporary
# pile before adding it to the scene
@onready var _card_container: LineOrientation = $LineOrientation


func _ready():
	_card_container.set_spacing_calculation(_calculate_spacing)


func _calculate_spacing(node: Control) -> float:
	var card_height = size.x * UiCard.TEXTURE_SIZE_RATIO
	return card_height * 0.25 if node.get_child(0).revealed else card_height * 0.075


func add_card(card: UiCard):
	card.set_tableau_pile(self)


func _add_card(card: UiCard):
	# add parent control for card because this makes it easy to animate
	# because we can just use position 0x0 instead of calculating where the
	# card should go
	var parent = Control.new()
	parent.add_child(card)
	card.anchors_preset = PRESET_FULL_RECT
	$LineOrientation.add_child(parent)


func remove_card(card: UiCard):
	card.set_tableau(null)


func _remove_card(card: UiCard):
	$LineOrientation.remove_child(card.get_parent())
	card.get_parent().remove_child(card)


func get_cards():
	return _card_container.get_children().map(func(parent): return parent.get_child(0))


func get_card(idx: int) -> UiCard:
	return _card_container.get_child(idx).get_child(0)


func get_card_count() -> int:
	return _card_container.get_child_count()


@warning_ignore("integer_division")
func get_tableau_pile_index() -> int:
	return get_index() / 2


func reveal_topmost_card():
	if get_card_count() > 0:
		get_card(-1).revealed = true
