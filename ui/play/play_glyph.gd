class_name PlayGlyph
extends Control
## Owner #133 (rule 0): the play's buttons as pictures, not words, while the voice speaks (PlayHud): drawn in code (no
## font needs a symbol), white on the button's colour, centred in its parent.
## - GO: a triangle (play, test it); NEXT: an arrow; PAUSE: two bars (I need a break); STOP: a door (stop for now);
##   EYE: an eye (show me: watch, then do); CLOSE: a cross;
## - PIPS: the round's challenges as dots, the ones done filled (`value` of `total`), in place of "2 of 6".

const GO := "go"
const NEXT := "next"
const PAUSE := "pause"
const STOP := "stop"
const EYE := "eye"
const CLOSE := "close"
const PIPS := "pips"

var kind := GO
var value := 0
var total := 0
var ink := Color.WHITE


func _init(glyph: String = GO, side: float = 48.0) -> void:
	kind = glyph
	name = "Glyph"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(side, side) if glyph != PIPS else Vector2(side * 4.0, side * 0.5)


## Centred over `button` (its words hidden: the tooltip keeps them for a grown-up's pointer).
static func on_button(button: Button, glyph: String, side: float = 48.0) -> PlayGlyph:
	var g := PlayGlyph.new(glyph, side)
	g.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	g.offset_left = -side * 0.5
	g.offset_right = side * 0.5
	g.offset_top = -side * 0.5
	g.offset_bottom = side * 0.5
	button.add_child(g)
	return g


func set_pips(done: int, of: int) -> void:
	value = done
	total = of
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y) if kind != PIPS else size.y
	var c := size * 0.5
	var u := s * 0.5
	match kind:
		GO:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.55, -0.7) * u, c + Vector2(0.75, 0) * u,
				c + Vector2(-0.55, 0.7) * u]), ink)
		NEXT:
			var w := u * 0.22
			draw_rect(Rect2(c + Vector2(-0.8, -w / u * 0.5) * u, Vector2(1.0 * u, w)), ink)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0.1, -0.6) * u, c + Vector2(0.85, 0) * u,
				c + Vector2(0.1, 0.6) * u]), ink)
		PAUSE:
			draw_rect(Rect2(c + Vector2(-0.5, -0.65) * u, Vector2(0.32, 1.3) * u), ink)
			draw_rect(Rect2(c + Vector2(0.18, -0.65) * u, Vector2(0.32, 1.3) * u), ink)
		STOP:
			draw_rect(Rect2(c + Vector2(-0.5, -0.75) * u, Vector2(1.0, 1.5) * u), ink, false, maxf(u * 0.14, 2.0))
			draw_circle(c + Vector2(0.25, 0.05) * u, maxf(u * 0.1, 2.0), ink)
		EYE:
			var pts := PackedVector2Array()
			for i in 25:
				var a := TAU * i / 24.0
				pts.append(c + Vector2(cos(a) * 0.85, sin(a) * 0.45) * u)
			draw_polyline(pts, ink, maxf(u * 0.12, 2.0), true)
			draw_circle(c, u * 0.28, ink)
		CLOSE:
			var w := maxf(u * 0.2, 3.0)
			draw_line(c + Vector2(-0.6, -0.6) * u, c + Vector2(0.6, 0.6) * u, ink, w, true)
			draw_line(c + Vector2(-0.6, 0.6) * u, c + Vector2(0.6, -0.6) * u, ink, w, true)
		PIPS:
			if total <= 0:
				return
			var r := size.y * 0.32
			var step := minf(size.x / total, r * 3.2)
			var x0 := c.x - step * (total - 1) * 0.5
			for i in total:
				var at := Vector2(x0 + step * i, c.y)
				if i < value:
					draw_circle(at, r, ink)
				else:
					draw_arc(at, r * 0.85, 0.0, TAU, 18, ink, maxf(r * 0.25, 1.5), true)
