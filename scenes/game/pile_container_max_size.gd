extends Control


const MAX_SIZE_RATIO: float = 2.5


func _ready() -> void:
	# have to resize it because the it is triggered once before _ready, but not afterwards
	# and on my android phone, it seems to resize the child afterwards without resizing this parent
	# so... somehow the size of the child is toooo large. don't really know why
	_notification(NOTIFICATION_RESIZED)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		var child := get_child(0)
		var max_width := size.y * MAX_SIZE_RATIO
		if size.x > max_width:
			child.position = Vector2(size.x/2 - max_width/2, 0)
			child.size = Vector2(max_width, size.y)
