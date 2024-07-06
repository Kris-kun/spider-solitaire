extends Control

signal game_finished

const COLUMN_GAP = 30.0

## the original tableau pile of the cards we are dragging
var dragging_pile_origin: UiTableauPile
var drag_offset: Vector2

const CARD_RESOURCE = preload("res://scenes/game/objects/ui_card.tscn")
@onready var pile_container := $PileContainerMaxSize/PileContainer
@onready var stockpile := $StockpileButton
@onready var complete_stacks_container := $CompleteStacksContainer
@onready var dragging_pile := $DraggingPile


func _ready() -> void:
	create_frontend_cards()


func _process(_delta):
	if dragging_pile.visible:
		dragging_pile.global_position = get_global_mouse_position() - drag_offset


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed and dragging_pile.visible:
				get_viewport().set_input_as_handled()
				_on_card_drag_stopped()


func reset_cards():
	NodeUtils.remove_children_queue_free(complete_stacks_container)
	for pile: UiTableauPile in get_tableau_piles():
		for card in pile.get_cards():
			pile.remove_card(card)
	create_frontend_cards()


func create_frontend_cards():
	for column in Gamestate.tableau_piles.size():
		var pile := get_tableau_pile(column)
		
		for row in Gamestate.tableau_piles[column].cards.size():
			var card := create_card_instance(Gamestate.tableau_piles[column].cards[row].type)
			card.revealed = Gamestate.tableau_piles[column].cards[row].revealed
			pile.add_card(card)
	
	stockpile.visible = not Gamestate.stockpile.is_empty()
	
	for color in Gamestate.completed_stacks:
		var stack = Control.new()
		
		for value in 13:
			var card := Card.fromColorAndValue(color, 13 - value)
			var ui_card = create_card_instance(card.type)
			ui_card.size = stockpile.size
			ui_card.revealed = true
			ui_card.disabled = true
			stack.add_child(ui_card)
		
		complete_stacks_container.add_child(stack)
	
	_update_movable_state()


func handout_cards():
	var result := Gamestate.handout()
	var cards := result.handout_cards
	
	print(result)
	
	# create cards
	for i in cards.size():
		var pile := get_tableau_pile(i) as UiTableauPile
		var card := create_card_instance(cards[i].type)
		card.size = stockpile.size # because stockpile size might differ from normal card size
		card.revealed = cards[i].revealed
		pile.add_card(card)
		
		call_deferred("_animate_handout_card", card, i)
	
	# move complete stacks
	if not result.stack_complete_pile_indices.is_empty():
		for i in result.stack_complete_pile_indices:
			_complete_stack(i)
	
	# hide stockpile
	stockpile.visible = not Gamestate.stockpile.is_empty()
	
	_update_movable_state()


func _complete_stack(pile_index: int):
	var stack := Control.new()
	var pile := get_tableau_pile(pile_index)
	
	# get cards to move (from dragging pile and target pile)
	var cards = []
	var king_index = pile.get_card_count() - 13
	for idx in range(king_index, pile.get_card_count()):
		cards.push_back(pile.get_card(idx))
	
	# move cards to completed stack
	for tmp_card in cards:
		var pos = tmp_card.global_position
		tmp_card.disabled = true
		tmp_card.movable = true # not really movable but we don't want darkened cards there
		tmp_card.get_tableau_pile().remove_card(tmp_card)
		stack.add_child(tmp_card)
		call_deferred("_animate_stack_complete", tmp_card, pos)
	pile.reveal_topmost_card()
	
	complete_stacks_container.add_child(stack)
	
	if is_game_finished():
		game_finished.emit()


func create_card_instance(type: int) -> UiCard:
	var node := CARD_RESOURCE.instantiate() as UiCard
	node.card_type = type
	node.drag_started.connect(_on_card_drag_started)
	return node


func get_tableau_pile(idx: int) -> UiTableauPile:
	return pile_container.get_tableau_pile(idx)


func get_tableau_piles() -> Array[Node]:
	return pile_container.get_tableau_piles()


func undo() -> void:
	if is_game_finished():
		print_debug("Cannot undo. Game already won")
		return
	
	if dragging_pile.visible:
		print_debug("Cannot undo while moving cards")
		return
	
	var histories := Gamestate.undo()
	if histories.is_empty():
		print_debug("Nothing to undo")
		return
	
	# complete all currently running animations
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card: UiCard in all_cards:
		card.stop_tween()
	
	# finally undo the history entries
	for history in histories:
		_undo_history(history)
	_update_movable_state()


func is_game_finished() -> bool:
	return complete_stacks_container.get_child_count() == 8


func _on_card_drag_started(card: UiCard):
	print_debug("card drag started")
	
	if dragging_pile.visible:
		print_debug("already dragging pile")
		return # safety check
	
	var card_index = card.get_card_index()
	var pile_index = card.get_tableau_pile().get_tableau_pile_index()
	
	if not Gamestate.check_can_move(pile_index, card_index):
		print_debug("cannot move card")
		return
	
	drag_offset = get_global_mouse_position() - card.global_position
	dragging_pile_origin = card.get_tableau_pile()
	
	while dragging_pile_origin.get_card_count() > card_index:
		var tmp_card := dragging_pile_origin.get_card(card_index)
		tmp_card.stop_tween()
		tmp_card.set_tableau_pile(dragging_pile)
	
	dragging_pile.size.x = get_tableau_pile(0).size.x
	dragging_pile.visible = true


func _on_card_drag_stopped():
	print_debug("Drag stopped")
	
	if not dragging_pile.visible:
		print_debug("Not dragging anything")
		return # safety check
	
	var card = dragging_pile.get_card(0)
	var target_pile: UiTableauPile
	var target_pile_distance: float
	
	# check in which pile we want to put our card
	for pile: UiTableauPile in get_tableau_piles():
		var last_card: UiCard = pile.get_card(-1) if pile.get_card_count() > 0 else null
		var is_inside: bool
		var distance: float
		
		if last_card != null:
			is_inside = card.get_global_rect().intersects(last_card.get_global_rect())
			distance = (last_card.global_position - card.global_position).length()
		else:
			is_inside = card.get_global_rect().intersects(pile.get_global_rect())
			distance = (pile.global_position - card.global_position).length()
		
		if is_inside:
			if target_pile == null or distance < target_pile_distance:
				target_pile = pile
				target_pile_distance = distance
	
	# check in which pile we have to move the cards
	var stack_complete := false
	if target_pile == null:
		# if we couldn't find a proper pile, just return the cards to the original one
		target_pile = dragging_pile_origin
	else:
		# otherwise, try to move it to the new pile
		var result := Gamestate.move_cards(
				dragging_pile_origin.get_tableau_pile_index(),
				dragging_pile_origin.get_card_count(),
				target_pile.get_tableau_pile_index()
		)
		stack_complete = result.stack_complete
		print_debug("Legal move: ", result.legal)
		if not result.legal:
			target_pile = dragging_pile_origin
	
	if stack_complete:
		var stack = Control.new()
		
		# get cards to move (from dragging pile and target pile)
		var cards = []
		var king_index = target_pile.get_card_count() - 13 + dragging_pile.get_card_count()
		for idx in range(king_index, target_pile.get_card_count()):
			cards.push_back(target_pile.get_card(idx))
		cards += dragging_pile.get_cards()
		
		# move cards to completed stack
		for tmp_card in cards:
			var pos = tmp_card.global_position
			tmp_card.disabled = true
			tmp_card.movable = true # not really movable but we don't want darkened cards there
			tmp_card.get_tableau_pile().remove_card(tmp_card)
			stack.add_child(tmp_card)
			call_deferred("_animate_stack_complete", tmp_card, pos)
		target_pile.reveal_topmost_card()
		
		complete_stacks_container.add_child(stack)
	else:
		for tmp_card in dragging_pile.get_cards():
			var pos = tmp_card.global_position
			tmp_card.set_tableau_pile(target_pile)
			
			if not stack_complete:
				call_deferred("_animate_card_move", tmp_card, pos)
	
	dragging_pile.visible = false
	
	dragging_pile_origin.reveal_topmost_card()
	_update_movable_state()
	
	if is_game_finished():
		game_finished.emit()


func _update_movable_state():
	for pile: UiTableauPile in get_tableau_piles():
		for card: UiCard in pile.get_cards():
			card.movable = Gamestate.check_can_move(pile.get_tableau_pile_index(), card.get_card_index())


func _on_stockpile_button_pressed() -> void:
	handout_cards()


func _animate_handout_card(card: UiCard, pile_index: int):
	card.stop_and_create_tween()
	card.global_position = stockpile.global_position
	card.size = stockpile.size
	
	var duration = 0.15
	var delay = 0.05 * pile_index
	card.tween.set_parallel()
	card.tween.tween_property(card, "position", Vector2(), duration).set_delay(delay)
	card.tween.tween_property(card, "size", _get_card_size(), duration).from(stockpile.size).set_delay(delay)
	card.tween.tween_property(card, "disabled", false, 0).from(true).set_delay(duration + delay)


func _animate_card_move(card: UiCard, initial_position: Vector2):
	card.stop_and_create_tween()
	card.global_position = initial_position
	card.tween.tween_property(card, "position", Vector2(), 0.05)


func _animate_stack_complete(card: UiCard, initial_position: Vector2):
	card.stop_and_create_tween()
	card.global_position = initial_position
	
	var duration = 0.25
	card.tween.set_parallel()
	card.tween.tween_property(card, "position", Vector2(), duration)
	card.tween.tween_property(card, "size", stockpile.size, duration).from(_get_card_size())


func _undo_history(history: Gamestate.History):
	if history is Gamestate.HandoutHistory:
		print_debug("Undoing HandoutHistory")
		
		for pile: UiTableauPile in get_tableau_piles():
			var card = pile.get_card(-1)
			pile.remove_card(card)
			card.queue_free()
		stockpile.visible = true
	elif history is Gamestate.MoveHistory:
		print_debug("Undoing MoveHistory")
		
		var pile_from: UiTableauPile = get_tableau_pile(history.pile_index_destination)
		var pile_to: UiTableauPile = get_tableau_pile(history.pile_index_source)
		while pile_from.get_card_count() > history.pile_size_destination:
			var card = pile_from.get_card(history.pile_size_destination)
			card.set_tableau_pile(pile_to)
	elif history is Gamestate.RevealHistory:
		print_debug("Undoing RevealHistory")
		
		get_tableau_pile(history.pile_index).get_card(-1).revealed = false
	elif history is Gamestate.StackCompleteHistory:
		print_debug("Undoing StackCompleteHistory")
		
		var stack = complete_stacks_container.get_child(-1)
		complete_stacks_container.remove_child(stack)
		
		var pile := get_tableau_pile(history.pile_index) as UiTableauPile
		
		for i in 13:
			var card := stack.get_child(0) as UiCard
			stack.remove_child(card)
			card.disabled = false
			card.set_tableau_pile(pile)
		
		stack.queue_free()


func _get_card_size() -> Vector2:
	var pile = get_tableau_pile(0)
	return Vector2(pile.size.x, pile.size.x * UiCard.TEXTURE_SIZE_RATIO)
