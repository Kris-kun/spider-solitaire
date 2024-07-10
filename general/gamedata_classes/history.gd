class_name History
extends Node


var has_previous: bool = false # if this history came directly after another history entry


class HandoutHistory extends History:
	pass


class MoveHistory extends History:
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


class RevealHistory extends History:
	var pile_index: int
	
	@warning_ignore("shadowed_variable")
	func _init(pile_index: int) -> void:
		self.pile_index = pile_index
		has_previous = true


class StackCompleteHistory extends History:
	var pile_index: int
	
	@warning_ignore("shadowed_variable")
	func _init(pile_index: int) -> void:
		self.pile_index = pile_index
		has_previous = true


class CardMoveResult:
	var legal: bool
	var stack_complete: bool
	
	@warning_ignore("shadowed_variable")
	func _init(legal: bool, stack_complete: bool = false) -> void:
		self.legal = legal
		self.stack_complete = stack_complete


class HandoutResult:
	var handout_cards: Array[Card]
	var stack_complete_pile_indices: Array[int]
	
	@warning_ignore("shadowed_variable")
	func _init(handout_cards: Array[Card], stack_complete_pile_indices: Array[int] = []) -> void:
		self.handout_cards = handout_cards
		self.stack_complete_pile_indices = stack_complete_pile_indices
