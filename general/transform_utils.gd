class_name TransformUtils

enum Anchor {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_LEFT,
	CENTER,
}

## Set the size of node and keep the position based on a specific anchor
static func set_size(node: Control, size: Vector2, anchor: Anchor):
	var anchor_position := _get_anchor_position(anchor)
	node.position += (node.size - size) * anchor_position
	node.size = size


static func _get_anchor_position(anchor: Anchor) -> Vector2:
	match anchor:
		Anchor.TOP_LEFT:
			return Vector2(0.0, 0.0)
		Anchor.TOP_RIGHT:
			return Vector2(1.0, 0.0)
		Anchor.BOTTOM_RIGHT:
			return Vector2(1.0, 1.0)
		Anchor.BOTTOM_LEFT:
			return Vector2(0.0, 1.0)
		Anchor.CENTER:
			return Vector2(0.5, 0.5)
		_:
			printerr("Unknown anchor ", anchor)
			return Vector2()
