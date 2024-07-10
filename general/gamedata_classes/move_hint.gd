class_name MoveHint
extends Node

var pile_index_source: int
var card_index_source: int
var pile_index_destination: int

func _init(pile_index_source: int, card_index_source: int, pile_index_destination: int) -> void:
	self.pile_index_source = pile_index_source
	self.card_index_source = card_index_source
	self.pile_index_destination = pile_index_destination
