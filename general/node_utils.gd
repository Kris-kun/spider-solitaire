class_name NodeUtils

static func remove_children_queue_free(parent: Node):
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
