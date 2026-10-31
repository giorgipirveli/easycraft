class_name ReviveRing
extends Control
## The ring that fills while a teammate holds HELP UP (M4 Wave 2, Agent E; spec §17.5): a dark track
## and a green arc from the top, clockwise, with a small heart in the middle. Never takes a tap.

const TRACK := Color(0.05, 0.06, 0.1, 0.6)
const FILL := Color("7ee081")

var progress := 0.0:
	set(value):
		var v := clampf(value, 0.0, 1.0)
		if not is_equal_approx(v, progress):
			progress = v
			queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 6.0
	draw_circle(c, r + 5.0, Color(0, 0, 0, 0.35))
	draw_arc(c, r, 0.0, TAU, 48, TRACK, 9.0, true)
	if progress > 0.0:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * progress, maxi(4, int(48 * progress)), FILL, 9.0, true)
	ChatPictures.draw(self, &"thanks", Rect2(c - Vector2(r, r) * 0.55, Vector2(r, r) * 1.1), FILL)
