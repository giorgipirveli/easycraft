class_name StarBody
extends Button
## One body on the Star Map (spec §21b.1): a planet, moon, star or universe drawn from StarMap's data (its colours, a
## band, Saturn's rings), its name under it, a glow where the child is or where home is, dimmed while it is still to
## come or locked. The button is at least 64 × 64 (a child's finger), however small the body is drawn.

const MIN_SIDE := 64.0
const NAME_SIZE := 15

var body_id: StringName
var data: Dictionary
var state: StringName = StarMap.LOOK
## The drawn radius (StarMap's size; a star is cut by the screen's edge).
var radius := 8.0


func _init(d: Dictionary) -> void:
	data = d
	body_id = d.id
	name = "Body_" + str(d.id)
	radius = float(d.size)
	flat = true
	focus_mode = Control.FOCUS_NONE
	text = ""
	var side := maxf(MIN_SIDE, radius * 2.0 + 8.0)
	var wide := maxf(side, radius * 3.6 + 8.0) if bool(d.get("ring", false)) else side   # the rings fit too
	custom_minimum_size = Vector2(wide, side + NAME_SIZE + 6.0)
	size = custom_minimum_size
	tooltip_text = str(d.name)


func set_state(s: StringName) -> void:
	state = s
	queue_redraw()


## Where the body's middle is, inside the button.
func centre() -> Vector2:
	return Vector2(size.x * 0.5, (size.y - NAME_SIZE - 6.0) * 0.5)


func _draw() -> void:
	var c := centre()
	var dim := state in [StarMap.COMING_SOON, StarMap.LOCKED]
	var col: Color = data.color
	var col2: Color = data.color2
	if dim:
		col = col.lerp(Color(0.35, 0.37, 0.45), 0.45)
		col2 = col2.lerp(Color(0.35, 0.37, 0.45), 0.45)
	if state in [StarMap.HERE, StarMap.HOME]:
		draw_circle(c, radius + 9.0, Color(1.0, 0.92, 0.45, 0.35))
		draw_arc(c, radius + 6.0, 0.0, TAU, 48, Color("ffe14d"), 3.0)
	elif state == StarMap.LAND:   # a world to land on: a green ring
		draw_arc(c, radius + 6.0, 0.0, TAU, 48, Color("5be37a"), 3.0)
	if str(data.kind) == "star":
		for i in 3:
			draw_circle(c, radius + 14.0 - i * 4.0, Color(col2, 0.12 + 0.08 * i))
	var ring := bool(data.get("ring", false))
	if ring:   # the back half of the rings, behind the planet
		_draw_ring(c, col2, true)
	draw_circle(c, radius, col)
	# a band or a patch in its second colour, and a soft shine
	draw_circle(c + Vector2(-radius * 0.25, radius * 0.2), radius * 0.45, Color(col2, 0.55))
	draw_circle(c + Vector2(radius * 0.3, -radius * 0.35), radius * 0.28, Color(1, 1, 1, 0.18))
	if ring:
		_draw_ring(c, col2, false)
	if str(data.kind) == "universe" and state == StarMap.COMING_SOON:
		var f := get_theme_default_font()
		draw_string(f, c + Vector2(-radius * 0.35, radius * 0.4), "?", HORIZONTAL_ALIGNMENT_LEFT, -1,
			int(radius * 1.2), Color(1, 1, 1, 0.85))
	var font := get_theme_default_font()
	var words := str(data.name)
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_CENTER, -1, NAME_SIZE).x
	var at := Vector2((size.x - w) * 0.5, size.y - 4.0)
	draw_string(font, at + Vector2(1, 1), words, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, Color(0, 0, 0, 0.7))
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE,
		Color(1, 1, 1, 0.55) if dim else Color(1, 1, 1, 0.95))


func _draw_ring(c: Vector2, col: Color, back: bool) -> void:
	var rx := radius * 1.75
	var ry := radius * 0.42
	var pts := PackedVector2Array()
	for i in 25:
		var a := (PI if back else 0.0) + PI * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, Color(col, 0.85), maxf(2.0, radius * 0.16), true)
