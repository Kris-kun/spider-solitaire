class_name StackCompleteHistory
extends History


var pile_index: int


@warning_ignore("shadowed_variable")
func _init(pile_index: int) -> void:
	self.pile_index = pile_index
	has_previous = true
