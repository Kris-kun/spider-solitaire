class_name UiTableauPile
extends Control

const UNREVEALED_CARD_SPACING_MODIFIER := 0.075
const REVEALED_CARD_SPACING_MODIFIER := 0.25

var _spacing_modifier = 1.0

# we can't use the cardContainer in _add_card because cards are added to a temporary
# pile before adding it to the scene
@onready var _card_container: LineOrientation = $LineOrientation


func _ready():
	_card_container.set_spacing_calculation(_calculate_spacing)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_spacing_multiplier()


func _calculate_spacing(node: Control) -> float:
	var card_height := _calculate_card_height()
	var modifier := 1.0
	if get_parent() is TableauPileContainer:
		modifier = _spacing_modifier
	if node.get_child(0).revealed:
		modifier *= REVEALED_CARD_SPACING_MODIFIER
	else:
		modifier *= UNREVEALED_CARD_SPACING_MODIFIER
	return card_height * modifier


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
	_update_spacing_multiplier()


func remove_card(card: UiCard):
	card.set_tableau_pile(null)


func _remove_card(card: UiCard):
	$LineOrientation.remove_child(card.get_parent())
	card.get_parent().remove_child(card)
	_update_spacing_multiplier()


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
		_update_spacing_multiplier()


func _calculate_card_height() -> float:
	return size.x * UiCard.TEXTURE_SIZE_RATIO


func _update_spacing_multiplier() -> void:
	var card_height := _calculate_card_height()
	
	var sum_spacing_modifier := _calculate_spacing_modifier_sum()
	
	var max_card_bottom_y := sum_spacing_modifier * card_height + card_height
	var height_diff := max_card_bottom_y - size.y
	
	var new_spacing_modifier := 1.0
	if height_diff > 0.0:
		const min_spacing_modifier := 0.5
		var fitting_spacing_sum := (size.y / float(card_height)) - 1.0 # das gleiche wie obendrüber
		
		new_spacing_modifier = fitting_spacing_sum / sum_spacing_modifier
		if new_spacing_modifier < min_spacing_modifier:
			new_spacing_modifier = min_spacing_modifier
	
	if absf(new_spacing_modifier - _spacing_modifier) > 0.00001:
		_spacing_modifier = new_spacing_modifier
		_card_container.resize()


func _calculate_spacing_modifier_sum() -> float:
	if get_card_count() < 2:
		return 0.0
	
	var first_revealed_index = 0
	for idx in get_card_count():
		if get_card(idx).revealed:
			first_revealed_index = idx
			break
	
	var unrevealed_amount = first_revealed_index
	var revealed_amount = get_card_count() - first_revealed_index - 1 # -1 because if we have e.g 1 card, there's no spacing
	
	return UNREVEALED_CARD_SPACING_MODIFIER * unrevealed_amount + REVEALED_CARD_SPACING_MODIFIER * revealed_amount
