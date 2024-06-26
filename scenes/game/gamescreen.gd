extends Control

const COLUMN_GAP = 30.0

## the temporary tableau with the cards we are dragging
var dragging_tableau: UiTableau
## the original tableau of the cards we are dragging
var dragging_tableau_origin: UiTableau
var drag_offset: Vector2

const TABLEAU_RESOURCE = preload("res://scenes/game/objects/ui_tableau.tscn")
const CARD_RESOURCE = preload("res://scenes/game/objects/ui_card.tscn")
@onready var handout_box := $HandoutBox
@onready var stockpile := $StockpileButton
@onready var complete_stacks_container := $CompleteStacksContainer
@onready var COLUMN_WIDTH = (handout_box.size.x - COLUMN_GAP*(Gamestate.COLUMNS-1)) / Gamestate.COLUMNS
@onready var CARD_SIZE = Vector2(COLUMN_WIDTH, COLUMN_WIDTH * UiCard.TEXTURE_SIZE_RATIO)

@onready var mouse_coords_label := $MarginContainer3/MouseCoordsLabel


func _ready():
	TransformUtils.set_size(stockpile, CARD_SIZE * 0.75, TransformUtils.Anchor.BOTTOM_RIGHT)
	complete_stacks_container.position = Vector2(size.x - stockpile.position.x - stockpile.size.x, stockpile.position.y)
	create_frontend_cards()


func _process(_delta):
	# TODO: remove the MouseCoordsLabel
	mouse_coords_label.text = "%d x %d" % [get_global_mouse_position().x, get_global_mouse_position().y]
	if dragging_tableau != null:
		dragging_tableau.global_position = get_global_mouse_position() - drag_offset


func _unhandled_input(event):
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed && dragging_tableau != null:
			_on_card_drag_stopped()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")


func create_frontend_cards():
	for column in Gamestate.tableaus.size():
		var tableau_container := create_tableau_instance()
		tableau_container.set_position(Vector2(column*COLUMN_WIDTH + column*COLUMN_GAP, 0))
		handout_box.add_child(tableau_container)
		
		for row in Gamestate.tableaus[column].cards.size():
			var card := create_card_instance(Gamestate.tableaus[column].cards[row].type)
			card.revealed = Gamestate.tableaus[column].cards[row].revealed
			tableau_container.add_card(card)
	
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
	var cards := Gamestate.handout()
	
	# create cards
	for i in cards.size():
		var tableau := handout_box.get_child(i) as UiTableau
		var card := create_card_instance(cards[i].type)
		card.size = stockpile.size # because stockpile size might differ from normal card size
		card.revealed = cards[i].revealed
		tableau.add_card(card)
		
		call_deferred("_animate_handout_card", card, i)
	
	# hide stockpile
	stockpile.visible = not Gamestate.stockpile.is_empty()
	
	_update_movable_state()


func create_tableau_instance() -> UiTableau:
	var node = TABLEAU_RESOURCE.instantiate() as UiTableau
	node.size = CARD_SIZE
	node.custom_minimum_size = CARD_SIZE
	return node


func create_card_instance(type: int) -> UiCard:
	var node := CARD_RESOURCE.instantiate() as UiCard
	node.size = CARD_SIZE
	node.card_type = type
	node.drag_started.connect(_on_card_drag_started)
	return node


func _on_card_drag_started(card: UiCard):
	print_debug("card drag started")
	
	if dragging_tableau != null:
		print_debug("already dragging tableau")
		return # safety check
	
	var card_index = card.get_card_index()
	var tableau_index = card.get_tableau().get_index()
	
	if not Gamestate.check_can_move(tableau_index, card_index):
		print_debug("cannot move card")
		return
	
	drag_offset = get_global_mouse_position() - card.global_position
	dragging_tableau_origin = card.get_tableau()
	
	dragging_tableau = create_tableau_instance()
	while dragging_tableau_origin.get_card_count() > card_index:
		var tmp_card := dragging_tableau_origin.get_card(card_index)
		tmp_card.stop_tween()
		tmp_card.set_tableau(dragging_tableau)
	
	handout_box.get_parent().add_child(dragging_tableau)


func _on_card_drag_stopped():
	print_debug("Drag stopped")
	
	if dragging_tableau == null:
		print_debug("Not dragging anything")
		return # safety check
	
	var card = dragging_tableau.get_card(0)
	var target_tableau: UiTableau
	var target_tableau_distance: float
	
	# check in which tableau we want to put our card
	for tableau: UiTableau in handout_box.get_children():
		var last_card: UiCard = tableau.get_card(-1) if tableau.get_card_count() > 0 else null
		var is_inside: bool
		var distance: float
		
		if last_card != null:
			is_inside = card.get_global_rect().intersects(last_card.get_global_rect())
			distance = (last_card.global_position - card.global_position).length()
		else:
			is_inside = card.get_global_rect().intersects(tableau.get_global_rect())
			distance = (tableau.global_position - card.global_position).length()
		
		if is_inside:
			if target_tableau == null or distance < target_tableau_distance:
				target_tableau = tableau
				target_tableau_distance = distance
	
	# check in which tableau we have to move the cards
	var stack_complete := false
	if target_tableau == null:
		# if we couldn't find a proper tableau, just return the cards to the original one
		target_tableau = dragging_tableau_origin
	else:
		# otherwise, try to move it to the new tableau
		var result := Gamestate.move_cards(
				dragging_tableau_origin.get_index(),
				dragging_tableau_origin.get_card_count(),
				target_tableau.get_index()
		)
		stack_complete = result.stack_complete
		print_debug("Legal move: ", result.legal)
		if not result.legal:
			target_tableau = dragging_tableau_origin
	
	if stack_complete:
		var stack = Control.new()
		
		# get cards to move (from dragging tableau and target tableau)
		var cards = []
		var king_index = target_tableau.get_card_count() - 13 + dragging_tableau.get_card_count()
		for idx in range(king_index, target_tableau.get_card_count()):
			cards.push_back(target_tableau.get_card(idx))
		cards += dragging_tableau.get_cards()
		
		# move cards to completed stack
		for tmp_card in cards:
			var pos = tmp_card.global_position
			tmp_card.disabled = true
			tmp_card.movable = true # not really movable but we don't want darkened cards there
			tmp_card.get_tableau().remove_card(tmp_card)
			stack.add_child(tmp_card)
			call_deferred("_animate_stack_complete", tmp_card, pos)
		target_tableau.reveal_topmost_card()
		
		complete_stacks_container.add_child(stack)
	else:
		for tmp_card in dragging_tableau.get_cards():
			var pos = tmp_card.global_position
			tmp_card.set_tableau(target_tableau)
			
			if not stack_complete:
				call_deferred("_animate_card_move", tmp_card, pos)
	
	dragging_tableau.queue_free()
	dragging_tableau = null
	
	dragging_tableau_origin.reveal_topmost_card()
	_update_movable_state()


func _update_movable_state():
	for tableau: UiTableau in handout_box.get_children():
		for card: UiCard in tableau.get_cards():
			card.movable = Gamestate.check_can_move(tableau.get_index(), card.get_card_index())


func _on_stockpile_button_pressed() -> void:
	handout_cards()


func _animate_handout_card(card: UiCard, tableau_index: int):
	card.stop_and_create_tween()
	card.global_position = stockpile.global_position
	
	var duration = 0.15
	var delay = 0.05 * tableau_index
	card.tween.set_parallel()
	card.tween.tween_property(card, "position", Vector2(), duration).set_delay(delay)
	card.tween.tween_property(card, "size", CARD_SIZE, duration).set_delay(delay)
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
	card.tween.tween_property(card, "size", stockpile.size, duration)


func _on_undo_pressed() -> void:
	var histories := Gamestate.undo()
	if histories.is_empty():
		print_debug("Nothing to undo")
	for history in histories:
		_undo_history(history)
	_update_movable_state()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/menu.tscn")


func _undo_history(history: Gamestate.History):
	if history is Gamestate.HandoutHistory:
		print_debug("Undoing HandoutHistory")
		
		for tableau: UiTableau in handout_box.get_children():
			var card = tableau.get_card(-1)
			tableau.remove_card(card)
			card.queue_free()
		stockpile.visible = true
	elif history is Gamestate.MoveHistory:
		print_debug("Undoing MoveHistory")
		
		var tableau_from: UiTableau = handout_box.get_child(history.tableau_index_destination)
		var tableau_to: UiTableau = handout_box.get_child(history.tableau_index_source)
		while tableau_from.get_card_count() > history.tableau_size_destination:
			var card = tableau_from.get_card(history.tableau_size_destination)
			card.set_tableau(tableau_to)
	elif history is Gamestate.RevealHistory:
		print_debug("Undoing RevealHistory")
		
		handout_box.get_child(history.tableau_index).get_card(-1).revealed = false
	elif history is Gamestate.StackCompleteHistory:
		print_debug("Undoing StackCompleteHistory")
		
		var stack = complete_stacks_container.get_child(-1)
		complete_stacks_container.remove_child(stack)
		
		var tableau := handout_box.get_child(history.tableau_index) as UiTableau
		
		for i in 13:
			var card := stack.get_child(0) as UiCard
			stack.remove_child(card)
			card.disabled = false
			card.size = CARD_SIZE
			card.set_tableau(tableau)
		
		stack.queue_free()


func _on_save_pressed() -> void:
	print_debug("Saving savefile")
	Gamestate.save()


func _on_load_pressed() -> void:
	print_debug("Loading savefile")
	
	NodeUtils.remove_children_queue_free(handout_box)
	NodeUtils.remove_children_queue_free(stockpile)
	NodeUtils.remove_children_queue_free(complete_stacks_container)
	
	Gamestate.load()
	
	create_frontend_cards()
