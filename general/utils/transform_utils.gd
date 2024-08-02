class_name TransformUtils

enum Anchor {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM_CENTER,
	BOTTOM_LEFT,
	CENTER_LEFT,
	CENTER_TOP,
	CENTER_RIGHT,
	CENTER_BOTTOM,
	CENTER,
}

## Set the size of node and keep the position based on a specific anchor
static func set_size(node: Control, size: Vector2, anchor: Anchor):
	var anchor_position := get_anchor_position(anchor)
	node.position += (node.size - size) * anchor_position
	node.size = size


static func get_position(node: Control, anchor: Anchor) -> Vector2:
	var anchor_position := get_anchor_position(anchor)
	return node.position + node.size * anchor_position


static func get_global_position(node: Control, anchor: Anchor) -> Vector2:
	var anchor_position := get_anchor_position(anchor)
	return node.global_position + node.size * anchor_position


static func get_anchor_position(anchor: Anchor) -> Vector2:
	match anchor:
		Anchor.TOP_LEFT:
			return Vector2(0.0, 0.0)
		Anchor.TOP_RIGHT:
			return Vector2(1.0, 0.0)
		Anchor.BOTTOM_RIGHT:
			return Vector2(1.0, 1.0)
		Anchor.BOTTOM_LEFT:
			return Vector2(0.0, 1.0)
		Anchor.CENTER_LEFT:
			return Vector2(0.0, 0.5)
		Anchor.CENTER_TOP:
			return Vector2(0.5, 0.0)
		Anchor.CENTER_RIGHT:
			return Vector2(1.0, 0.5)
		Anchor.CENTER_BOTTOM:
			return Vector2(0.5, 1.0)
		Anchor.CENTER:
			return Vector2(0.5, 0.5)
		_:
			printerr("Unknown anchor ", anchor)
			return Vector2()
