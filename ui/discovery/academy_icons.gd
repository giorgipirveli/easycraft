class_name AcademyIcons
extends RefCounted
## Owner #132 (W1), stage 3: the Discovery Academy's door pictures (owner #133: a child never has to read): a gear for
## the Maths Workshop, a flask for the Science Lab, an open book for the Word Tower, a heart for Life, angle brackets for
## the Code Lab, columns for the History Museum, a map pin for the Map Room, a dumbbell for the Health Gym, a note for the
## Music Hall, two friends holding hands for the Citizens' Hall, a palette for the Art Studio, a hammer for the Makers'
## Shed. Each is a few rectangles in a unit square (x right, y down; turned by degrees), so the same picture is drawn
## flat on a card (draw) and built as thin boxes on a door's sign in the world (AcademyBuildings).

const DARK := Color(0.1, 0.12, 0.2)

## name -> [[cx, cy, w, h, degrees, colour (null: the ink)], ...]
const PICTURES := {
	"gear": [[0.5, 0.5, 0.18, 0.9, 0.0, null], [0.5, 0.5, 0.18, 0.9, 45.0, null], [0.5, 0.5, 0.18, 0.9, 90.0, null],
		[0.5, 0.5, 0.18, 0.9, 135.0, null], [0.5, 0.5, 0.6, 0.6, 0.0, null], [0.5, 0.5, 0.6, 0.6, 45.0, null],
		[0.5, 0.5, 0.22, 0.22, 45.0, DARK]],
	"flask": [[0.5, 0.07, 0.34, 0.07, 0.0, null], [0.5, 0.26, 0.2, 0.34, 0.0, null], [0.5, 0.5, 0.36, 0.16, 0.0, null],
		[0.5, 0.64, 0.52, 0.14, 0.0, null], [0.5, 0.8, 0.68, 0.18, 0.0, null], [0.42, 0.72, 0.08, 0.08, 0.0, DARK],
		[0.58, 0.8, 0.06, 0.06, 0.0, DARK]],
	"book": [[0.28, 0.52, 0.4, 0.66, -8.0, null], [0.72, 0.52, 0.4, 0.66, 8.0, null], [0.5, 0.56, 0.05, 0.7, 0.0, DARK],
		[0.27, 0.4, 0.26, 0.04, -8.0, DARK], [0.27, 0.52, 0.26, 0.04, -8.0, DARK], [0.73, 0.4, 0.26, 0.04, 8.0, DARK],
		[0.73, 0.52, 0.26, 0.04, 8.0, DARK]],
	"heart": [[0.35, 0.4, 0.36, 0.36, 45.0, null], [0.65, 0.4, 0.36, 0.36, 45.0, null],
		[0.5, 0.56, 0.48, 0.48, 45.0, null]],
	"code": [[0.24, 0.39, 0.32, 0.09, -45.0, null], [0.24, 0.61, 0.32, 0.09, 45.0, null],
		[0.76, 0.39, 0.32, 0.09, 45.0, null], [0.76, 0.61, 0.32, 0.09, -45.0, null], [0.5, 0.5, 0.08, 0.62, 18.0, null]],
	"columns": [[0.5, 0.08, 0.34, 0.07, 0.0, null], [0.5, 0.15, 0.62, 0.08, 0.0, null], [0.5, 0.23, 0.86, 0.09, 0.0, null],
		[0.24, 0.55, 0.11, 0.52, 0.0, null], [0.5, 0.55, 0.11, 0.52, 0.0, null], [0.76, 0.55, 0.11, 0.52, 0.0, null],
		[0.5, 0.87, 0.9, 0.1, 0.0, null]],
	"pin": [[0.5, 0.4, 0.46, 0.46, 45.0, null], [0.5, 0.36, 0.16, 0.16, 45.0, DARK], [0.5, 0.92, 0.66, 0.06, 0.0, null]],
	"dumbbell": [[0.5, 0.5, 0.66, 0.09, 0.0, null], [0.22, 0.5, 0.13, 0.54, 0.0, null], [0.78, 0.5, 0.13, 0.54, 0.0, null],
		[0.11, 0.5, 0.08, 0.36, 0.0, null], [0.89, 0.5, 0.08, 0.36, 0.0, null]],
	"note": [[0.38, 0.77, 0.3, 0.22, -25.0, null], [0.5, 0.43, 0.07, 0.66, 0.0, null],
		[0.64, 0.2, 0.3, 0.08, 35.0, null], [0.64, 0.3, 0.3, 0.08, 35.0, null]],
	"people": [[0.32, 0.24, 0.18, 0.18, 0.0, null], [0.68, 0.24, 0.18, 0.18, 0.0, null], [0.32, 0.58, 0.26, 0.4, 0.0, null],
		[0.68, 0.58, 0.26, 0.4, 0.0, null], [0.5, 0.52, 0.3, 0.07, 0.0, null]],
	"palette": [[0.5, 0.52, 0.76, 0.66, 0.0, null], [0.5, 0.52, 0.56, 0.84, 0.0, null],
		[0.33, 0.36, 0.13, 0.13, 0.0, Color("e8443a")], [0.52, 0.28, 0.13, 0.13, 0.0, Color("ffcf3a")],
		[0.7, 0.38, 0.13, 0.13, 0.0, Color("3a7be8")], [0.32, 0.62, 0.13, 0.13, 0.0, Color("2fae4e")],
		[0.64, 0.66, 0.15, 0.15, 0.0, DARK]],
	"hammer": [[0.44, 0.62, 0.11, 0.62, 35.0, null], [0.64, 0.3, 0.52, 0.18, 35.0, null]],
	# the learning places' look (2026-10-18): the pictures on the places kept for the games that come
	"bread": [[0.5, 0.62, 0.84, 0.34, 0.0, null], [0.5, 0.44, 0.66, 0.24, 0.0, null], [0.5, 0.34, 0.42, 0.12, 0.0, null],
		[0.33, 0.47, 0.05, 0.2, 28.0, DARK], [0.5, 0.45, 0.05, 0.22, 28.0, DARK], [0.67, 0.47, 0.05, 0.2, 28.0, DARK]],
	"scales": [[0.5, 0.55, 0.07, 0.6, 0.0, null], [0.5, 0.86, 0.52, 0.08, 0.0, null], [0.5, 0.24, 0.84, 0.06, 0.0, null],
		[0.5, 0.2, 0.1, 0.1, 45.0, null], [0.17, 0.4, 0.03, 0.3, -14.0, null], [0.29, 0.4, 0.03, 0.3, 14.0, null],
		[0.71, 0.4, 0.03, 0.3, -14.0, null], [0.83, 0.4, 0.03, 0.3, 14.0, null], [0.23, 0.56, 0.3, 0.07, 0.0, null],
		[0.77, 0.56, 0.3, 0.07, 0.0, null]],
	"leaf": [[0.52, 0.44, 0.46, 0.46, 45.0, null], [0.64, 0.3, 0.26, 0.26, 45.0, null], [0.4, 0.58, 0.26, 0.26, 45.0, null],
		[0.5, 0.46, 0.04, 0.56, 45.0, DARK], [0.25, 0.8, 0.05, 0.24, 45.0, null]],
	# DISCOVER's magnifying glass (HudIcons' "discover" in rectangles): the Academy's emblem over its front
	"discover": [[0.69, 0.42, 0.22, 0.08, 90.0, null], [0.611, 0.611, 0.22, 0.08, 135.0, null],
		[0.42, 0.69, 0.22, 0.08, 180.0, null], [0.229, 0.611, 0.22, 0.08, 225.0, null], [0.15, 0.42, 0.22, 0.08, 270.0, null],
		[0.229, 0.229, 0.22, 0.08, 315.0, null], [0.42, 0.15, 0.22, 0.08, 0.0, null], [0.611, 0.229, 0.22, 0.08, 45.0, null],
		[0.76, 0.76, 0.36, 0.13, 45.0, null], [0.42, 0.42, 0.14, 0.14, 45.0, null]],
}


static func knows(picture: String) -> bool:
	return PICTURES.has(picture)


## Draws `picture` into the square `r` of the canvas item `ci` (from its _draw) in `ink`.
static func draw(ci: CanvasItem, picture: String, r: Rect2, ink: Color = Color.WHITE) -> void:
	var side := minf(r.size.x, r.size.y)
	var o := r.position + (r.size - Vector2(side, side)) * 0.5
	for e: Array in PICTURES.get(picture, []):
		var c: Color = ink if e[5] == null else e[5]
		ci.draw_set_transform(o + Vector2(e[0], e[1]) * side, deg_to_rad(float(e[4])), Vector2.ONE)
		var w := float(e[2]) * side
		var h := float(e[3]) * side
		ci.draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), c)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A picture as a Control (the "coming soon" card).
class Picture:
	extends Control
	var picture := ""
	var ink := Color.WHITE
	var back := Color(0, 0, 0, 0)

	func _init(p: String = "", px: float = 160.0, background: Color = Color(0, 0, 0, 0)) -> void:
		picture = p
		back = background
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if back.a > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), back)
		var pad := minf(size.x, size.y) * 0.14
		AcademyIcons.draw(self, picture, Rect2(Vector2(pad, pad), size - Vector2(pad, pad) * 2.0), ink)
