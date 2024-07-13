extends Node

enum Mode {
	SAME_COLOR_SAME_SEED = 0,
	SAME_COLOR_DIFFERENT_SEED = 3,
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
### array of 10 tableau piles, each holding an array with every card [type + visible]
var tableau_piles: Array[TableauPile]:
	set(value):
		_savestate.tableau_piles = value
	get:
		return _savestate.tableau_piles
### values are the card colors
var completed_stacks: Array[int]:
	set(value):
		_savestate.completed_stacks = value
	get:
		return _savestate.completed_stacks

## if multiple steps should be done in one call
## for example moving a card might immediately complete a stack if this is set to true
var multiple_steps_at_once: bool

var _mode: Mode:
	set(value):
		_savestate.mode = value
	get:
		return _savestate.mode
var _history: Array[History]
var _savestate: Savestate = Savestate.new()
var _rng = RandomNumberGenerator.new()
var _last_hint_pile_index := -1


func reset(mode: Mode):
	if mode == Mode.SAME_COLOR_SAME_SEED:
		mode = _mode
	elif mode == Mode.SAME_COLOR_DIFFERENT_SEED:
		mode = _mode
		_rng.randomize()
	else:
		_rng.randomize()
	
	_savestate = Savestate.new()
	_mode = mode # because the savestate is new and the mode is inside it
	_history = []
	_last_hint_pile_index = -1
	
	_savestate.deck_seed = _rng.seed
	seed(_savestate.deck_seed)
	
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
	_last_hint_pile_index = -1


func get_stockpile_stacks_amount() -> int:
	@warning_ignore("integer_division")
	return stockpile.size() / 10


## Moves all cards with index >= first_card_index from the source to the destination tableau pile
## returns true if it is a legal move, false if not (meaning nothing changes)
func move_cards(pile_index_source: int, first_card_index: int, pile_index_destination: int) -> CardMoveResult:
	if pile_index_source == pile_index_destination:
		return CardMoveResult.new(false)
	
	var source_pile := tableau_piles[pile_index_source]
	var source_card := source_pile.cards[first_card_index]
	var dest_pile := tableau_piles[pile_index_destination]
	
	# check if it's a legal move first
	if not dest_pile.cards.is_empty():
		var dest_card_parent := dest_pile.cards[-1]
		if source_card.get_value() + 1 != dest_card_parent.get_value():
			return CardMoveResult.new(false)
	
	_history.push_back(MoveHistory.new(pile_index_source, first_card_index, pile_index_destination, dest_pile.cards.size()))
	
	# really move the cards now
	var moving_cards: Array[Card] = []
	while source_pile.cards.size() > first_card_index:
		moving_cards.push_front(source_pile.cards.pop_back())
	dest_pile.cards += moving_cards
	
	_reveal_tableau_card(pile_index_source)
	_last_hint_pile_index = -1
	
	var result := CardMoveResult.new(true)
	
	# check if we got a full stack
	if multiple_steps_at_once:
		if _check_complete_stack(dest_pile):
			_remove_complete_stack(pile_index_destination)
			result.stack_complete = true
	
	_save_or_delete()
	
	return result


func check_can_move(pile_index: int, card_index: int) -> bool:
	var pile := tableau_piles[pile_index]
	
	var card := pile.cards[card_index]
	if not card.revealed:
		return false
	
	var value := card.get_value()
	var color := card.get_color()
	for i in range(card_index + 1, pile.cards.size()):
		card = pile.cards[i]
		value -= 1
		if card.get_value() != value or card.get_color() != color:
			return false
	
	return true


func try_complete_stack(pile_idx: int) -> bool:
	var pile := tableau_piles[pile_idx]
	if _check_complete_stack(pile):
		_remove_complete_stack(pile_idx)
		_save_or_delete()
		return true
	return false


func _check_complete_stack(pile: TableauPile) -> bool:
	if pile.cards.size() < 13:
		return false
	
	var value := 1
	var color = pile.cards[-1].get_color()
	for i in pile.cards.size():
		var card := pile.cards[-1 - i]
		if card.get_value() != value or card.get_color() != color:
			return false
		elif value == 13:
			return true
		value += 1
	
	return false


func handout() -> HandoutResult:
	if stockpile.is_empty():
		return HandoutResult.new([])
	
	var any_pile_empty = tableau_piles.any(func(pile): return pile.cards.is_empty())
	if any_pile_empty:
		return HandoutResult.new([])
	
	var cards: Array[Card] = []
	var result := HandoutResult.new(cards)
	for pile in tableau_piles:
		var card = Card.new(stockpile.pop_back(), true)
		cards.append(card)
		pile.cards.append(card)
	
	_history.push_back(HandoutHistory.new())
	_last_hint_pile_index = -1
	
	# check for completed stacks
	if multiple_steps_at_once:
		for i in tableau_piles.size():
			var pile := tableau_piles[i]
			if _check_complete_stack(pile):
				result.stack_complete_pile_indices.push_back(i)
				_remove_complete_stack(i)
	
	_save_or_delete()
	
	return result


## Undo the last action.[br]
## [br]
## An action can consist of multiple histories, for example if you
## move a card from pile 1 to pile 2 and the card in pile 1 will be revealed.[br]
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
	
	_last_hint_pile_index = -1
	save()
	
	return histories


func get_next_hint() -> MoveHint:
	# move from left to right
	# move from bottom to top as long as the card can be moved
	# check on the left and right if we can move it to the last card of the pile
	
	# also don't show moves to empty tableaus
	
	if _last_hint_pile_index >= tableau_piles.size() - 1:
		_last_hint_pile_index = -1
	
	for pile_index in range(_last_hint_pile_index + 1, tableau_piles.size()):
		_last_hint_pile_index = pile_index
		
		var pile := tableau_piles[pile_index]
		var card_index := -1
		for i in range(pile.cards.size() - 1, -1, -1):
			if not check_can_move(pile_index, i):
				break
			card_index = i
		
		if card_index < 0:
			continue
		
		var card := pile.cards[card_index]
		var card_above := null if card_index == 0 else pile.cards[card_index - 1]
		if card_above != null and not card_above.revealed:
			card_above = null
		
		for pile_index_dst in tableau_piles.size():
			if pile_index_dst == pile_index:
				continue
			
			var pile_dst := tableau_piles[pile_index_dst]
			if not pile_dst.cards.is_empty():
				var last_card := pile_dst.cards[-1]
				if card.get_value() + 1 == last_card.get_value():
					if (card.get_color() == last_card.get_color()
						or card_above == null
						or card.get_value() + 1 != card_above.get_value()):
						return MoveHint.new(pile_index, card_index, pile_index_dst)
	
	return null


func _init_stockpile():
	stockpile = []
	
	var unique_cards: int = 13 * _mode
	for i in 104:
		stockpile.append(i % unique_cards)
	
	stockpile.shuffle()


func _create_initial_face_down_cards():
	tableau_piles = []
	tableau_piles.resize(COLUMNS)
	
	for column in 4:
		tableau_piles[column] = TableauPile.new()
		for row in 6:
			tableau_piles[column].cards.append(Card.new(stockpile.pop_back()))
	for column in range(4, COLUMNS):
		tableau_piles[column] = TableauPile.new()
		for row in 5:
			tableau_piles[column].cards.append(Card.new(stockpile.pop_back()))


func _create_initial_face_up_cards():
	for pile in tableau_piles:
		pile.cards.append(Card.new(stockpile.pop_back(), true))


func _reveal_tableau_card(pile_index: int):
	var pile := tableau_piles[pile_index]
	if pile.cards.is_empty():
		return
	if pile.cards[-1].revealed:
		return
	
	pile.cards[-1].revealed = true
	_history.push_back(RevealHistory.new(pile_index))


func _remove_complete_stack(pile_index: int):
	var pile := tableau_piles[pile_index]
	completed_stacks.push_back(pile.cards[-1].get_color())
	pile.cards.resize(pile.cards.size() - 13)
	_history.push_back(StackCompleteHistory.new(pile_index))
	_reveal_tableau_card(pile_index)
	_last_hint_pile_index = -1


func _undo_history(history: History):
	if history is HandoutHistory:
		for i in tableau_piles.size():
			var card: Card = tableau_piles[-1 - i].cards.pop_back()
			stockpile.push_back(card.type)
	elif history is MoveHistory:
		var moving_cards: Array[Card] = []
		var pile_from := tableau_piles[history.pile_index_destination]
		var pile_to := tableau_piles[history.pile_index_source]
		while pile_from.cards.size() > history.pile_size_destination:
			moving_cards.push_front(pile_from.cards.pop_back())
		pile_to.cards += moving_cards
	elif history is RevealHistory:
		tableau_piles[history.pile_index].cards[-1].revealed = false
	elif history is StackCompleteHistory:
		var pile := tableau_piles[history.pile_index]
		var color = completed_stacks.pop_back()
		for i in 13:
			var card = Card.fromColorAndValue(color, 13 - i, true)
			pile.cards.push_back(card)


func _save_or_delete() -> void:
	if completed_stacks.size() == 8:
		Savestate.delete()
	else:
		save()
