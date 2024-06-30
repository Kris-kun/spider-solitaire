@tool
class_name LineOrientation
extends Container

var _spacing_calculation

@export var size_by_children: bool = true:
	set(value):
		size_by_children = value
		notify_property_list_changed()
		queue_sort()

@export var child_ratio: float = 1.0:
	set(value):
		child_ratio = value
		queue_sort()

@export var spacing := 20:
	set(value):
		spacing = value
		queue_sort()

@export var orientation := Orientation.VERTICAL:
	set(value):
		orientation = value
		queue_sort()


func _validate_property(property: Dictionary) -> void:
	if property.name == "child_ratio":
		property.usage = PROPERTY_USAGE_NO_EDITOR if size_by_children else PROPERTY_USAGE_DEFAULT


func _notification(what: int):
	match what:
		NOTIFICATION_SORT_CHILDREN, NOTIFICATION_RESIZED:
			resize()


func set_spacing_calculation(calculation: Callable):
	_spacing_calculation = calculation


func resize():
	if size_by_children:
		_resize_by_children()
	else:
		_resize_by_parent()


func _resize_by_children():
	#var newSize := Vector2()
	
	var calc_spacing: Callable
	if _spacing_calculation == null:
		calc_spacing = func(_node): return spacing
	else:
		calc_spacing = _spacing_calculation
	
	var offset := 0.0
	match self.orientation:
		VERTICAL:
			for i in get_child_count():
				var child: Control = get_child(i)
				child.set_position(Vector2(0, offset))
				offset += calc_spacing.call(child)
				
				#newSize.y = max(newSize.y, child.position.y + child.size.y)
				#newSize.x = max(newSize.x, child.size.x)
		HORIZONTAL:
			for i in get_child_count():
				var child: Control = get_child(i)
				child.set_position(Vector2(offset, 0))
				offset += calc_spacing.call(child)
				
				#newSize.x = max(newSize.x, child.position.x + child.size.x)
				#newSize.y = max(newSize.y, child.size.y)
	
	#size = newSize


func _resize_by_parent():
	var calc_spacing: Callable
	if _spacing_calculation == null:
		calc_spacing = func(_node): return spacing
	else:
		calc_spacing = _spacing_calculation
	
	var offset := 0.0
	match self.orientation:
		VERTICAL:
			for i in get_child_count():
				var child: Control = get_child(i)
				child.set_position(Vector2(0, offset))
				offset += calc_spacing.call(child)
				child.size = Vector2(size.x, size.x*child_ratio)
		HORIZONTAL:
			for i in get_child_count():
				var child: Control = get_child(i)
				child.set_position(Vector2(offset, 0))
				offset += calc_spacing.call(child)
				child.size = Vector2(size.y*child_ratio, size.y)
