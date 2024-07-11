class_name CardMoveResult


var legal: bool
var stack_complete: bool


@warning_ignore("shadowed_variable")
func _init(legal: bool, stack_complete: bool = false) -> void:
	self.legal = legal
	self.stack_complete = stack_complete
