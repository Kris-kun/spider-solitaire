extends Control


const MAX_SIZE_RATIO: float = 2.5


func _ready() -> void:
	call_deferred("_resize_child")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_resize_child()


func _resize_child() -> void:
	var child := get_child(0)
	var max_width := size.y * MAX_SIZE_RATIO
	if size.x > max_width:
		child.position = Vector2(size.x/2 - max_width/2, 0)
		child.size = Vector2(max_width, size.y)
