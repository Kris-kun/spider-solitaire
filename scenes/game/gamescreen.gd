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


func _ready():
	TransformUtils.set_size(stockpile, CARD_SIZE, TransformUtils.Anchor.BOTTOM_RIGHT)
	complete_stacks_container.position = Vector2(size.x - stockpile.position.x - stockpile.size.x, stockpile.position.y)
	Gamestate.stack_completed.connect(_on_stack_completed)
	create_frontend_cards()


func _process(_delta):
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
		
		for value in range(1, 14):
			var card := Card.fromColorAndValue(color, value)
			var ui_card = create_card_instance(card.type)
			ui_card.revealed = true
			ui_card.disabled = true
			stack.add_child(ui_card)
		
		complete_stacks_container.add_child(stack)


func handout_cards():
	var cards := Gamestate.handout()
	
	# create cards
	for i in cards.size():
		var tableau := handout_box.get_child(i) as UiTableau
		var card := create_card_instance(cards[i].type)
		card.revealed = cards[i].revealed
		tableau.add_card(card)
		
		call_deferred("_animate_handout_card", card, i)
	
	# hide stockpile
	stockpile.visible = not Gamestate.stockpile.is_empty()


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
		dragging_tableau_origin.get_card(card_index).set_tableau(dragging_tableau)
	
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
	
	# if we couldn't find a proper tableau, just return the cards to the original one
	if target_tableau == null:
		target_tableau = dragging_tableau_origin
	else:
		var legal_move = Gamestate.move_cards(
				dragging_tableau_origin.get_index(),
				dragging_tableau_origin.get_card_count(),
				target_tableau.get_index()
		)
		print_debug("Legal move: ", legal_move)
		if not legal_move:
			target_tableau = dragging_tableau_origin
	
	for tmp_card in dragging_tableau.get_cards():
		var pos = tmp_card.global_position
		tmp_card.set_tableau(target_tableau)
		
		call_deferred("_animate_card_move", tmp_card, pos)
	
	dragging_tableau.queue_free()
	dragging_tableau = null
	
	dragging_tableau_origin.reveal_topmost_card()


func _on_stack_completed(tableau_index: int):
	# don't remove cards at this moment because the drag&drop was not completed yet
	call_deferred("_on_stack_completed_deferred", tableau_index)


func _on_stack_completed_deferred(tableau_index: int):
	var stack = Control.new()
	
	var tableau := handout_box.get_child(tableau_index) as UiTableau
	for i in 13:
		var card := tableau.get_card(-13 + i) # -13+i for correct order in ui
		var pos := card.global_position
		card.disabled = true
		tableau.remove_card(card)
		stack.add_child(card)
		call_deferred("_animate_stack_complete", card, pos)
	tableau.reveal_topmost_card()
	
	complete_stacks_container.add_child(stack)


func _on_stockpile_button_pressed() -> void:
	handout_cards()


func _animate_handout_card(card: UiCard, tableau_index: int):
	card.global_position = stockpile.global_position
	var tween = card.create_tween()
	tween.tween_property(card, "position", Vector2(), 0.15).set_delay(0.05 * tableau_index)
	tween.tween_property(card, "disabled", false, 0).from(true)


func _animate_card_move(card: UiCard, initial_position: Vector2):
	card.global_position = initial_position
	var tween = card.create_tween()
	tween.tween_property(card, "position", Vector2(), 0.05)
	tween.tween_property(card, "disabled", false, 0).from(true)


func _animate_stack_complete(card: UiCard, initial_position: Vector2):
	card.global_position = initial_position
	var tween = card.create_tween()
	var index = complete_stacks_container.get_child_count()-1
	tween.tween_property(card, "position", Vector2(index * complete_stacks_container.spacing, 0), 10.25)


func _on_undo_pressed() -> void:
	var histories := Gamestate.undo()
	if histories.is_empty():
		print_debug("Nothing to undo")
	for history in histories:
		_undo_history(history)


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
			var card := stack.get_child(-1) as UiCard
			stack.remove_child(card)
			card.disabled = false
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
	
	print(Gamestate.tableaus[2].cards.size())
	
	create_frontend_cards()
