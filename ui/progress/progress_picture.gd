class_name ProgressPicture
extends Control
## One picture of the board, the badges or the presents (ProgressPictures), drawn in its own square.
## `dim`: a badge or sticker still to find, shown as a shadow.

var picture: StringName = &"":
	set(value):
		picture = value
		queue_redraw()
var dim := false:
	set(value):
		dim = value
		queue_redraw()


func _init(pic: StringName = &"", px: float = 64.0) -> void:
	picture = pic
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	var s := minf(size.x, size.y)
	ProgressPictures.draw(self, picture, Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s)), dim)
