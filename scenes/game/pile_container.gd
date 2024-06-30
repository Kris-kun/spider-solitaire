class_name TableauPileContainer
extends HBoxContainer


func get_tableau_pile(idx: int) -> UiTableauPile:
	return get_child(idx*2) as UiTableauPile


func get_tableau_piles() -> Array[Node]:
	return get_children().filter(func(child: Node): return child is UiTableauPile)
