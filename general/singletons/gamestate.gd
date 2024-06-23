extends Node

enum Mode {
	_SAME_MODE = 0,
	SINGLE_COLOR = 1,
	TWO_COLORS = 2,
	FOUR_COLORS = 4,
}

const COLUMNS = 10

### values are the card types
var stockpile: Array[int]:
	set(value):
		_savestate.stockpile = value
	get:
		return _savestate.stockpile
### array of 10 tableaus, each holding an array with every card [type + visible]
var tableaus: Array[Tableau]:
	set(value):
		_savestate.tableaus = value
	get:
		return _savestate.tableaus
### values are the card colors
var completed_stacks: Array[int]:
	set(value):
		_savestate.completed_stacks = value
	get:
		return _savestate.completed_stacks

var _mode: Mode:
	set(value):
		_savestate.mode = value
	get:
		return _savestate.mode
var _history: Array[History]
var _savestate: Savestate = Savestate.new()


func _init():
	reset(Mode.SINGLE_COLOR)


func reset(mode: Mode = Mode._SAME_MODE):
	if mode == Mode._SAME_MODE:
		mode = _mode
	
	_savestate = Savestate.new()
	_mode = mode # because the savestate is new and the mode is inside it
	
	_init_stockpile()
	_create_initial_face_down_cards()
	_create_initial_face_up_cards()


func save():
	_savestate.save()


func load():
	var savestate := Savestate.load()
	if savestate == null:
		return
	
	_savestate = savestate
	_history = []


## Moves all cards with index >= first_card_index from the source to the destination tableau
## returns true if it is a legal move, false if not (meaning nothing changes)
func move_cards(tableau_index_source: int, first_card_index: int, tableau_index_destination: int) -> CardMoveResult:
	if tableau_index_source == tableau_index_destination:
		return CardMoveResult.new(false)
	
	var source_tableau := tableaus[tableau_index_source]
	var source_card := source_tableau.cards[first_card_index]
	var dest_tableau := tableaus[tableau_index_destination]
	
	# check if it's a legal move first
	if not dest_tableau.cards.is_empty():
		var dest_card_parent := dest_tableau.cards[-1]
		if source_card.get_value() + 1 != dest_card_parent.get_value():
			return CardMoveResult.new(false)
	
	_history.push_back(MoveHistory.new(tableau_index_source, first_card_index, tableau_index_destination, dest_tableau.cards.size()))
	
	# really move the cards now
	var moving_cards: Array[Card] = []
	while source_tableau.cards.size() > first_card_index:
		moving_cards.push_front(source_tableau.cards.pop_back())
	dest_tableau.cards += moving_cards
	
	_reveal_tableau_card(tableau_index_source)
	
	var result := CardMoveResult.new(true)
	
	# check if we got a full stack
	if check_complete_stack(dest_tableau):
		completed_stacks.push_back(dest_tableau.cards[-1].get_color())
		dest_tableau.cards.resize(dest_tableau.cards.size() - 13)
		
		_history.push_back(StackCompleteHistory.new(tableau_index_destination))
		_reveal_tableau_card(tableau_index_destination)
		
		result.stack_complete = true
	
	if completed_stacks.size() == 8:
		Savestate.delete()
	else:
		save()
	_print_state()
	
	return result


func check_can_move(tableau_index: int, card_index: int) -> bool:
	var tableau := tableaus[tableau_index]
	
	var card := tableau.cards[card_index]
	var value := card.get_value()
	var color := card.get_color()
	for i in range(card_index + 1, tableau.cards.size()):
		card = tableau.cards[i]
		value -= 1
		if card.get_value() != value or card.get_color() != color:
			return false
	
	return true


func check_complete_stack(tableau: Tableau) -> bool:
	if tableau.cards.size() < 13:
		return false
	
	var value := 1
	var color = tableau.cards[-1].get_color()
	for i in tableau.cards.size():
		var card := tableau.cards[-1 - i]
		if card.get_value() != value or card.get_color() != color:
			return false
		elif value == 13:
			return true
		value += 1
	
	return false


func handout() -> Array[Card]:
	if stockpile.is_empty():
		return []
	
	var any_tableau_empty = tableaus.any(func(tableau): return tableau.cards.is_empty())
	if any_tableau_empty:
		return []
	
	var cards: Array[Card] = []
	for tableau in tableaus:
		var card = Card.new(stockpile.pop_back(), true)
		cards.append(card)
		tableau.cards.append(card)
	
	_history.push_back(HandoutHistory.new())
	
	save()
	_print_state()
	
	# TODO: emit signal?
	
	return cards


## Undo the last action.[br]
## [br]
## An action can consist of multiple histories, for example if you
## move a card from tableau 1 to tableau 2 and the card in tableau 1 will be revealed.[br]
## This will consist of two histories:[br]
## - The first will be the RevealHistory (because this happened afterwards)[br]
## - The second will be the MoveHistory
func undo() -> Array[History]:
	if _history.is_empty():
		return []
	
	var histories: Array[History] = []
	histories.push_back(_history.pop_back())
	
	while histories[-1].has_previous:
		histories.push_back(_history.pop_back())
	
	for history in histories:
		_undo_history(history)
	
	save()
	_print_state()
	
	return histories


func _init_stockpile():
	stockpile = []
	
	var unique_cards: int = 13 * _mode
	for i in 104:
		stockpile.append(i % unique_cards)
	
	randomize()
	stockpile.shuffle()


func _create_initial_face_down_cards():
	tableaus = []
	tableaus.resize(COLUMNS)
	
	for column in 4:
		tableaus[column] = Tableau.new()
		for row in 6:
			tableaus[column].cards.append(Card.new(stockpile.pop_back()))
	for column in range(4, COLUMNS):
		tableaus[column] = Tableau.new()
		for row in 5:
			tableaus[column].cards.append(Card.new(stockpile.pop_back()))


func _create_initial_face_up_cards():
	for tableau in tableaus:
		tableau.cards.append(Card.new(stockpile.pop_back(), true))
	
	# TODO: remove
	#for type in 12:
		#tableaus[6].cards.append(Card.new(12-type, true))
	#tableaus[7].cards.append(Card.new(0, true))
	#for type in 12:
		#tableaus[8].cards.append(Card.new(12-type, true))
	#tableaus[9].cards.append(Card.new(0, true))


func _reveal_tableau_card(tableau_index: int):
	var tableau := tableaus[tableau_index]
	if tableau.cards.is_empty():
		return
	if tableau.cards[-1].revealed:
		return
	
	tableau.cards[-1].revealed = true
	_history.push_back(RevealHistory.new(tableau_index))


func _undo_history(history: History):
	if history is HandoutHistory:
		for i in tableaus.size():
			var card: Card = tableaus[-1 - i].cards.pop_back()
			stockpile.push_back(card.type)
	elif history is MoveHistory:
		var moving_cards: Array[Card] = []
		var tableau_from := tableaus[history.tableau_index_destination]
		var tableau_to := tableaus[history.tableau_index_source]
		while tableau_from.cards.size() > history.tableau_size_destination:
			moving_cards.push_front(tableau_from.cards.pop_back())
		tableau_to.cards += moving_cards
	elif history is RevealHistory:
		tableaus[history.tableau_index].cards[-1].revealed = false
	elif history is StackCompleteHistory:
		var tableau := tableaus[history.tableau_index]
		var color = completed_stacks.pop_back()
		for i in 13:
			var card = Card.fromColorAndValue(color, 13 - i, true)
			tableau.cards.push_back(card)


## temporary. TODO: delete
func _print_state():
	print("###############################")
	
	var row = 0
	while true:
		var line := ""
		var stop := true
		for tableau in tableaus:
			if tableau.cards.size() <= row:
				line += "  -"
			else:
				line += " %2s" % tableau.cards[row].get_value_str()
				stop = false
		
		if stop:
			break
		
		print(line)
		row += 1
	
	print("###############################")


class History:
	var has_previous: bool = false # if this history came directly after another history entry

class HandoutHistory extends History:
	pass

class MoveHistory extends History:
	var tableau_index_source: int
	var first_card_index: int
	var tableau_index_destination: int
	var tableau_size_destination: int # need this so we know how to undo this
	
	@warning_ignore("shadowed_variable")
	func _init(tableau_index_source: int, first_card_index: int, tableau_index_destination: int, tableau_size_destination: int) -> void:
		self.tableau_index_source = tableau_index_source
		self.first_card_index = first_card_index
		self.tableau_index_destination = tableau_index_destination
		self.tableau_size_destination = tableau_size_destination

class RevealHistory extends History:
	var tableau_index: int
	
	@warning_ignore("shadowed_variable")
	func _init(tableau_index: int) -> void:
		self.tableau_index = tableau_index
		has_previous = true

class StackCompleteHistory extends History:
	var tableau_index: int
	
	@warning_ignore("shadowed_variable")
	func _init(tableau_index: int) -> void:
		self.tableau_index = tableau_index
		has_previous = true

class CardMoveResult:
	var legal: bool
	var stack_complete: bool
	
	@warning_ignore("shadowed_variable")
	func _init(legal: bool, stack_complete: bool = false) -> void:
		self.legal = legal
		self.stack_complete = stack_complete
