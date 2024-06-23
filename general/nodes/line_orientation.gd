@tool
class_name LineOrientation
extends Container

var _spacing_calculation

@export var spacing := 20:
	set(value):
		spacing = value
		resort()

@export var orientation := Orientation.VERTICAL:
	set(value):
		orientation = value
		resort()


func _notification(what: int):
	match what:
		NOTIFICATION_SORT_CHILDREN:
			resort()


func set_spacing_calculation(calculation: Callable):
	_spacing_calculation = calculation


func resort():
	var newSize := Vector2()
	
	var calc_spacing: Callable
	if _spacing_calculation == null:
		calc_spacing = func(_node): return spacing
	else:
		calc_spacing = _spacing_calculation
	
	var offset := 0
	match self.orientation:
		VERTICAL:
			for i in get_child_count():
				var child: Control = get_child(i)
				child.set_position(Vector2(0, offset))
				offset += calc_spacing.call(child)
				
				newSize.y = max(newSize.y, child.position.y + child.size.y)
				newSize.x = max(newSize.x, child.size.x)
		HORIZONTAL:
			for i in get_child_count():
				var child: Control = get_child(i)
				child.set_position(Vector2(offset, 0))
				offset += calc_spacing.call(child)
				
				newSize.x = max(newSize.x, child.position.x + child.size.x)
				newSize.y = max(newSize.y, child.size.y)
	
	size = newSize
