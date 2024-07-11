@tool
class_name TextureMix
extends Texture2D

## instead of having thousands of if statements, we will just use an empty texture
var _TEXTURE_PLACEHOLDER := EmptyTexture2D.new()

@export var background: Texture2D:
	set(value):
		background = value
		_background = value if value != null else _TEXTURE_PLACEHOLDER
		emit_changed()

@export var foreground: Texture2D:
	set(value):
		foreground = value
		_foreground = value if value != null else _TEXTURE_PLACEHOLDER
		emit_changed()

var _background: Texture2D = _TEXTURE_PLACEHOLDER
var _foreground: Texture2D = _TEXTURE_PLACEHOLDER


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	_background.draw(to_canvas_item, pos, modulate, transpose)
	_foreground.draw(to_canvas_item, pos, modulate, transpose)


func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	_background.draw_rect(to_canvas_item, rect, tile, modulate, transpose)
	_foreground.draw_rect(to_canvas_item, rect, tile, modulate, transpose)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	_background.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)
	_foreground.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)


func _get_height() -> int:
	return maxi(_background.get_height(), _foreground.get_height())


func _get_width() -> int:
	return maxi(_background.get_width(), _foreground.get_width())


func _has_alpha() -> bool:
	return _background.has_alpha() and _foreground.has_alpha()


func _is_pixel_opaque(x: int, y: int) -> bool:
	return _background._is_pixel_opaque(x, y) and _foreground._is_pixel_opaque(x, y)
