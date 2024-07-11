class_name MoveHistory
extends History


var pile_index_source: int
var first_card_index: int
var pile_index_destination: int
var pile_size_destination: int # need this so we know how to undo this


@warning_ignore("shadowed_variable")
func _init(pile_index_source: int, first_card_index: int, pile_index_destination: int, pile_size_destination: int) -> void:
	self.pile_index_source = pile_index_source
	self.first_card_index = first_card_index
	self.pile_index_destination = pile_index_destination
	self.pile_size_destination = pile_size_destination
