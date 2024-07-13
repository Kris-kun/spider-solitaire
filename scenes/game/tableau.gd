extends Control

signal game_finished

const COLUMN_GAP = 30.0

## the original tableau pile of the cards we are dragging
var dragging_pile_origin: UiTableauPile
var drag_offset: Vector2

const CARD_RESOURCE = preload("res://scenes/game/objects/ui_card.tscn")

@onready var pile_container := $PileContainerMaxSize/PileContainer
@onready var complete_stacks_container := $CompleteStacksContainer
@onready var stockpile_button := $StockpileButton
@onready var stockpile_container := $StockpileContainer
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
	NodeUtils.remove_children_queue_free(stockpile_container)
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
	
	_update_stockpile()
	
	for color in Gamestate.completed_stacks:
		var stack = Control.new()
		
		for value in 13:
			var card := Card.fromColorAndValue(color, 13 - value)
			var ui_card := create_card_instance(card.type)
			ui_card.size = stockpile_container.size
			ui_card.revealed = true
			ui_card.disabled = true
			stack.add_child(ui_card)
		
		complete_stacks_container.add_child(stack)
	
	_update_movable_state()


func handout_cards():
	var result := Gamestate.handout()
	var cards := result.handout_cards
	var moving_cards = []
	
	# create cards
	for pile_idx in cards.size():
		var pile := get_tableau_pile(pile_idx) as UiTableauPile
		var card := create_card_instance(cards[pile_idx].type)
		card.size = stockpile_container.size # because stockpile size might differ from normal card size
		card.revealed = cards[pile_idx].revealed
		pile.add_card(card)
		moving_cards.push_back(card)
	
	_update_stockpile()
	_update_movable_state()
	
	var tween := _animate_handout_card(moving_cards)
	
	# move complete stacks
	for pile: UiTableauPile in get_tableau_piles():
		if tween.is_running(): # why is there no is_finished()?
			await tween.finished
		
		if Gamestate.try_complete_stack(pile.get_tableau_pile_index()):
			# get cards to move (from dragging pile and target pile)
			var cardsArr = []
			var king_index = pile.get_card_count() - 13
			for idx in range(king_index, pile.get_card_count()):
				var card := pile.get_card(idx)
				cardsArr.push_back([card, card.global_position])
			
			var stack := Control.new()
			# move cards to completed stack
			for arr in cardsArr:
				var card: UiCard = arr[0]
				card.disabled = true
				card.movable = true # not really movable but we don't want darkened cards there
				card.get_tableau_pile().remove_card(card)
				stack.add_child(card)
			complete_stacks_container.add_child(stack)
			complete_stacks_container.resize()
			
			for arr in cardsArr:
				arr[0].global_position = arr[1]
			
			tween = _animate_stack_complete(cardsArr.map(func(v): return v[0]))
			
			pile.reveal_topmost_card()
			_update_movable_state()
	
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


## returns true if another hint is available, false if not
func show_hint() -> bool:
	if dragging_pile.visible:
		print_debug("Cannot show hint while dragging cards")
		return true
	
	var hint := Gamestate.get_next_hint()
	if hint == null:
		return false
	
	# stop current hint animation first
	for pile: UiTableauPile in get_tableau_piles():
		for card_index in range(pile.get_card_count() - 1, -1, -1):
			var card := pile.get_card(card_index)
			if not card.revealed:
				break
			card.stop_hint_animation()
	
	# start new hint animation
	var pile_source := get_tableau_pile(hint.pile_index_source)
	for i in range(hint.card_index_source, pile_source.get_card_count()):
		pile_source.get_card(i).animate_hint()
	get_tableau_pile(hint.pile_index_destination).get_card(-1).animate_hint(0.25)
	return true
	


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
	dragging_pile.visible = false
	
	# check in which pile we want to put our card
	var target_pile := _get_intersecting_pile(dragging_pile.get_card(0))
	
	# check in which pile we have to move the cards
	#var stack_complete := false
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
		#stack_complete = result.stack_complete
		print_debug("Legal move: ", result.legal)
		if not result.legal:
			target_pile = dragging_pile_origin
	
	var moving_cards: Array = dragging_pile.get_cards().map(func(card): return [card, card.global_position])
	
	for arr in moving_cards:
		arr[0].set_tableau_pile(target_pile)
		arr[0].global_position = arr[1]
	
	var tween := _animate_cards_move_to_0(moving_cards.map(func(v): return v[0]))
	
	dragging_pile_origin.reveal_topmost_card()
	_update_movable_state()
	
	# check for completed stacks only after the animation finished
	await tween.finished
	if Gamestate.try_complete_stack(target_pile.get_tableau_pile_index()):
		var stack = Control.new()
		complete_stacks_container.add_child(stack)
		
		# get cards to move (from dragging pile and target pile)
		var cardsArr = []
		var king_index = target_pile.get_card_count() - 13
		for idx in range(king_index, target_pile.get_card_count()):
			var card := target_pile.get_card(idx)
			cardsArr.push_back([card, card.global_position])
		
		# move cards to completed stack
		for arr in cardsArr:
			var card: UiCard = arr[0]
			card.disabled = true
			card.movable = true # not really movable but we don't want darkened cards there
			card.get_tableau_pile().remove_card(card)
			stack.add_child(card)
			card.global_position = arr[1]
		
		target_pile.reveal_topmost_card()
		_update_movable_state()
		
		tween = _animate_stack_complete(cardsArr.map(func(v): return v[0]))
		
		await tween.finished
		if is_game_finished():
			game_finished.emit()


func _get_intersecting_pile(card: UiCard) -> UiTableauPile:
	var target_pile: UiTableauPile
	var target_pile_distance: float
	
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
				target_pile_distance = distance#
	
	return target_pile


func _update_movable_state() -> void:
	for pile: UiTableauPile in get_tableau_piles():
		for card: UiCard in pile.get_cards():
			card.movable = Gamestate.check_can_move(pile.get_tableau_pile_index(), card.get_card_index())


func _update_stockpile() -> void:
	var amount := Gamestate.get_stockpile_stacks_amount()
	var diff = amount - stockpile_container.get_child_count()
	if diff > 0:
		for i in diff:
			var button := stockpile_button.duplicate()
			button.visible = true
			stockpile_container.add_child(button)
	elif diff < 0:
		for i in -diff:
			var child = stockpile_container.get_child(0)
			stockpile_container.remove_child(child)
			child.queue_free()


func _on_stockpile_button_pressed() -> void:
	handout_cards()


func _animate_handout_card(cards: Array) -> Tween:
	var tween := create_tween().set_parallel()
	const duration = 0.15
	const delay = 0.05
	
	for pile_idx in cards.size():
		var card: UiCard = cards[pile_idx]
		card.global_position = stockpile_container.global_position
		card.global_position += Vector2(stockpile_container.spacing * stockpile_container.get_child_count(), 0)
		card.set_deferred("size", stockpile_container.size)
		card.z_index = 100
		
		var card_delay = delay * pile_idx
		tween.tween_property(card, "position", Vector2(), duration).set_delay(card_delay)
		tween.tween_property(card, "size", _get_card_size(), duration).from(stockpile_container.size).set_delay(card_delay)
		
		# reset things
		tween.tween_property(card, "disabled", false, 0).from(true).set_delay(duration + card_delay)
		tween.tween_property(card, "z_index", 0, 0).set_delay(duration + card_delay)
	return tween


func _animate_cards_move_to_0(cards: Array) -> Tween:
	var tween := create_tween().set_parallel()
	var duration = 0.05
	
	for card in cards:
		tween.tween_property(card, "position", Vector2(), duration)
	return tween


func _animate_stack_complete(cards: Array) -> Tween:
	var tween := create_tween().set_parallel()
	var duration = 0.25
	
	for card in cards:
		tween.set_parallel()
		tween.tween_property(card, "position", Vector2(), duration)
		tween.tween_property(card, "size", stockpile_container.size, duration).from(_get_card_size())
	return tween


func _undo_history(history: History):
	if history is HandoutHistory:
		print_debug("Undoing HandoutHistory")
		
		for pile: UiTableauPile in get_tableau_piles():
			var card = pile.get_card(-1)
			pile.remove_card(card)
			card.queue_free()
		_update_stockpile()
	elif history is MoveHistory:
		print_debug("Undoing MoveHistory")
		
		var pile_from: UiTableauPile = get_tableau_pile(history.pile_index_destination)
		var pile_to: UiTableauPile = get_tableau_pile(history.pile_index_source)
		while pile_from.get_card_count() > history.pile_size_destination:
			var card = pile_from.get_card(history.pile_size_destination)
			card.set_tableau_pile(pile_to)
	elif history is RevealHistory:
		print_debug("Undoing RevealHistory")
		
		get_tableau_pile(history.pile_index).get_card(-1).revealed = false
	elif history is StackCompleteHistory:
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
