class_name HandoutResult


var handout_cards: Array[Card]
var stack_complete_pile_indices: Array[int]


@warning_ignore("shadowed_variable")
func _init(handout_cards: Array[Card], stack_complete_pile_indices: Array[int] = []) -> void:
	self.handout_cards = handout_cards
	self.stack_complete_pile_indices = stack_complete_pile_indices
