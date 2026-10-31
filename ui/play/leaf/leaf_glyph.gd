class_name LeafGlyph
extends Control
## Owner #133 (rule 0; docs/design/games/leaf-voyage.md §3.5 step 11, §4.4): the voyage's own pictures for its HUD, drawn
## in code like G0's PlayGlyph (no font needs a symbol): the camera button, the end card's "again", the plants on the end
## card and the voyage board (the sunflower, the cactus in its pot), a lock on a voyage not open yet, the gold's coin.

const CAMERA := "camera"
const AGAIN := "again"
const SUNFLOWER := "sunflower"
const CACTUS := "cactus"
const LOCK := "lock"
const COIN := "coin"

var kind := CAMERA
var ink := Color.WHITE


func _init(glyph: String = CAMERA, side: float = 48.0) -> void:
	kind = glyph
	name = "LeafGlyph"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(side, side)


## Centred over `button`.
static func on_button(button: Button, glyph: String, side: float = 48.0) -> LeafGlyph:
	var g := LeafGlyph.new(glyph, side)
	g.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	g.offset_left = -side * 0.5
	g.offset_right = side * 0.5
	g.offset_top = -side * 0.5
	g.offset_bottom = side * 0.5
	button.add_child(g)
	return g


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var u := s * 0.5
	var w := maxf(u * 0.12, 2.0)
	match kind:
		CAMERA:
			draw_rect(Rect2(c + Vector2(-0.8, -0.45) * u, Vector2(1.6, 1.0) * u), ink, false, w)
			draw_rect(Rect2(c + Vector2(-0.35, -0.65) * u, Vector2(0.55, 0.2) * u), ink)
			draw_arc(c + Vector2(0, 0.05) * u, u * 0.3, 0.0, TAU, 20, ink, w, true)
		AGAIN:
			draw_arc(c, u * 0.62, -PI * 0.35, PI * 1.35, 24, ink, maxf(u * 0.16, 3.0), true)
			var tip := c + Vector2(cos(-PI * 0.35), sin(-PI * 0.35)) * u * 0.62
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-0.32, -0.12) * u, tip + Vector2(0.18, -0.36) * u,
				tip + Vector2(0.14, 0.2) * u]), ink)
		SUNFLOWER:
			draw_rect(Rect2(c + Vector2(-0.05, 0.1) * u, Vector2(0.1, 0.9) * u), Color("5fa83c"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.05, 0.55) * u, c + Vector2(0.55, 0.3) * u,
				c + Vector2(0.15, 0.7) * u]), Color("5cc44c"))
			for k in 12:
				var a := TAU * k / 12.0
				draw_circle(c + Vector2(cos(a), sin(a)) * u * 0.42 + Vector2(0, -0.2) * u, u * 0.17, Color("ffd21f"))
			draw_circle(c + Vector2(0, -0.2) * u, u * 0.3, Color("6b3c18"))
		CACTUS:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.45, 0.45) * u, c + Vector2(0.45, 0.45) * u,
				c + Vector2(0.35, 0.95) * u, c + Vector2(-0.35, 0.95) * u]), Color("d8743c"))
			var green := Color("4f9a48")
			draw_rect(Rect2(c + Vector2(-0.18, -0.55) * u, Vector2(0.36, 1.0) * u), green)
			draw_circle(c + Vector2(0, -0.55) * u, u * 0.18, green)
			draw_rect(Rect2(c + Vector2(-0.55, -0.15) * u, Vector2(0.3, 0.14) * u), green)
			draw_rect(Rect2(c + Vector2(-0.55, -0.45) * u, Vector2(0.14, 0.42) * u), green)
			draw_rect(Rect2(c + Vector2(0.25, 0.0) * u, Vector2(0.3, 0.14) * u), green)
			draw_rect(Rect2(c + Vector2(0.41, -0.3) * u, Vector2(0.14, 0.42) * u), green)
			for k in 6:
				var a := TAU * k / 6.0
				draw_circle(c + Vector2(cos(a), sin(a)) * u * 0.12 + Vector2(0, -0.78) * u, u * 0.09, Color("fbfbf4"))
			draw_circle(c + Vector2(0, -0.78) * u, u * 0.06, Color("f6d65a"))
		LOCK:
			draw_arc(c + Vector2(0, -0.15) * u, u * 0.3, PI, TAU, 16, ink, w, true)
			draw_rect(Rect2(c + Vector2(-0.45, -0.15) * u, Vector2(0.9, 0.75) * u), ink)
		COIN:
			draw_circle(c, u * 0.8, Color("f2c230"))
			draw_arc(c, u * 0.58, 0.0, TAU, 24, Color("c48f10"), w, true)
