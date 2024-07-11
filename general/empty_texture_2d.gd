@tool
class_name EmptyTexture2D
extends Texture2D


func _draw(_to_canvas_item: RID, _pos: Vector2, _modulate: Color, _transpose: bool) -> void:
	pass


func _draw_rect(_to_canvas_item: RID, _rect: Rect2, _tile: bool, _modulate: Color, _transpose: bool) -> void:
	pass


func _draw_rect_region(_to_canvas_item: RID, _rect: Rect2, _src_rect: Rect2, _modulate: Color, _transpose: bool, _clip_uv: bool) -> void:
	pass


func _get_height() -> int:
	return 0


func _get_width() -> int:
	return 0


func _has_alpha() -> bool:
	return true


func _is_pixel_opaque(_x: int, _y: int) -> bool:
	return true
