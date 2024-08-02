class_name HandoutResult


var handout_cards: Array[Card]
var stack_complete_pile_indices: Array[int]
var _error_any_pile_empty: bool


@warning_ignore("shadowed_variable")
func _init(handout_cards: Array[Card], stack_complete_pile_indices: Array[int] = []) -> void:
	self.handout_cards = handout_cards
	self.stack_complete_pile_indices = stack_complete_pile_indices


static func error_any_pile_empty() -> HandoutResult:
	var result := HandoutResult.new([])
	result._error_any_pile_empty = true
	return result


func has_error_any_pile_empty() -> bool:
	return _error_any_pile_empty
