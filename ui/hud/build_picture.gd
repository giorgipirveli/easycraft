class_name BuildPicture
extends Control
## A small picture of a build (M3 Task 20b): a grid of block cells (BuddyPicture: the front of a buddy; a secret
## shape's silhouette), each drawn with its block's own icon (BlockIcons: the atlas tiles, no new texture or
## material). `shadow` draws every cell as a dark shape (a secret shape not found yet).

const SHADOW := Color(0.23, 0.16, 0.09, 0.85)

var w := 0
var h := 0
## Block ids row by row from the top left (0: empty).
var cells := PackedInt32Array()
var shadow := false:
	set(value):
		shadow = value
		queue_redraw()


func _init(px: float = 72.0) -> void:
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Shows a BuddyPicture code ("" or a broken one: nothing).
func show_code(code: String) -> void:
	var d := BuddyPicture.decode(code)
	set_cells(int(d.get("w", 0)), int(d.get("h", 0)), d.get("cells", PackedInt32Array()))


func set_cells(width: int, height: int, ids: PackedInt32Array) -> void:
	w = width
	h = height
	cells = ids if ids.size() == w * h else PackedInt32Array()
	queue_redraw()


func _draw() -> void:
	if w <= 0 or h <= 0 or cells.is_empty():
		return
	var cell := minf(size.x / w, size.y / h)
	var origin := (size - Vector2(w, h) * cell) * 0.5
	for row in h:
		for col in w:
			var id := cells[row * w + col]
			if id == 0:
				continue
			var r := Rect2(origin + Vector2(col, row) * cell, Vector2(cell, cell))
			var tex := BlockIcons.icon(id)
			if tex == null or shadow:
				draw_rect(r.grow(-0.5), SHADOW)
			else:
				draw_texture_rect(tex, r, false)
