class_name InventionPicture
extends Control
## Owner #78 (spec §21e): a picture of each invention for the Inventions book, drawn in code (our own look: bright,
## flat, friendly; no textures): the kite on its string, the striped hot-air balloon over its basket, Lilienthal-style
## bat wings, the 1903 biplane with its propellers, the swept-wing jet with its glow, the rocket with its fins and fire.
## `dim`: not invented yet (Survivor) shows it pale, like a plan on paper.

const SKY := Color("bfe6ff")
const INK := Color("3b2a18")
const RED := Color("e8403a")
const YELLOW := Color("ffd23f")
const TEAL := Color("1fb5a8")
const WHITE := Color("f6f8fb")
const CLOTH := Color("f3ead2")
const WOOD := Color("9a6a3a")
const WICKER := Color("b88a4e")
const GREY := Color("aab4c0")
const IRON := Color("4a4f5a")
const FLAME := Color("ffb02e")
const GLASS := Color("9fd8ff")
const KINDS: Array[StringName] = [&"kite", &"balloon", &"glider", &"plane", &"jet", &"rocket"]

var kind: StringName = &"kite":
	set(k):
		kind = k
		queue_redraw()
var dim := false:
	set(d):
		dim = d
		queue_redraw()
var sky := true


func _init(p_kind: StringName = &"kite", side: float = 96.0) -> void:
	kind = p_kind
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if sky:
		draw_rect(r, SKY if not dim else Color(0.85, 0.85, 0.82), true)
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	match kind:
		&"kite":
			_kite(o, s)
		&"balloon":
			_balloon(o, s)
		&"glider":
			_glider(o, s)
		&"plane":
			_plane(o, s)
		&"jet":
			_jet(o, s)
		&"rocket":
			_rocket(o, s)
	if dim:
		draw_rect(r, Color(1, 1, 1, 0.45), true)


func _p(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * s


func _poly(o: Vector2, s: float, pts: Array, c: Color) -> void:
	var out := PackedVector2Array()
	for i in range(0, pts.size(), 2):
		out.append(_p(o, s, pts[i], pts[i + 1]))
	draw_colored_polygon(out, c)


func _line(o: Vector2, s: float, a: Vector2, b: Vector2, c: Color, w: float) -> void:
	draw_line(_p(o, s, a.x, a.y), _p(o, s, b.x, b.y), c, maxf(1.0, w * s / 100.0), true)


func _kite(o: Vector2, s: float) -> void:
	_poly(o, s, [0.62, 0.1, 0.84, 0.34, 0.62, 0.62, 0.4, 0.34], RED)
	_poly(o, s, [0.62, 0.1, 0.84, 0.34, 0.62, 0.34], YELLOW)
	_poly(o, s, [0.62, 0.34, 0.62, 0.62, 0.4, 0.34], YELLOW)
	_line(o, s, Vector2(0.62, 0.1), Vector2(0.62, 0.62), WOOD, 2.0)
	_line(o, s, Vector2(0.4, 0.34), Vector2(0.84, 0.34), WOOD, 2.0)
	var prev := Vector2(0.62, 0.62)
	for k in 5:   # the tail with its bows
		var next := Vector2(0.62 + sin(k * 1.4) * 0.04, 0.68 + k * 0.06)
		_line(o, s, prev, next, INK, 1.2)
		var bow := TEAL if k % 2 == 0 else RED   # a bow: two little triangles meeting on the tail
		_poly(o, s, [next.x, next.y, next.x - 0.035, next.y - 0.02, next.x - 0.035, next.y + 0.02], bow)
		_poly(o, s, [next.x, next.y, next.x + 0.035, next.y + 0.02, next.x + 0.035, next.y - 0.02], bow)
		prev = next
	for k in 8:   # the string, sagging down to the flier's hand
		var t0 := k / 8.0
		var t1 := (k + 1) / 8.0
		_line(o, s, _string(t0), _string(t1), INK, 1.2)
	draw_circle(_p(o, s, 0.14, 0.86), 0.05 * s, TEAL)   # the child flying it


func _string(t: float) -> Vector2:
	var a := Vector2(0.62, 0.62)
	var b := Vector2(0.16, 0.84)
	return a.lerp(b, t) + Vector2(0, sin(t * PI) * 0.08)


func _balloon(o: Vector2, s: float) -> void:
	var c := _p(o, s, 0.5, 0.38)
	var r := 0.3 * s
	draw_circle(c, r, RED)
	for k in 3:   # stripes down the bag
		var x := -0.2 + k * 0.2
		_poly(o, s, [0.5 + x - 0.045, 0.1, 0.5 + x + 0.045, 0.1, 0.5 + x * 1.1 + 0.035, 0.66, 0.5 + x * 1.1 - 0.035, 0.66],
			YELLOW if k != 1 else TEAL)
	_poly(o, s, [0.36, 0.6, 0.64, 0.6, 0.57, 0.7, 0.43, 0.7], RED)   # the bag narrows to its mouth
	for x: float in [0.44, 0.56]:
		_line(o, s, Vector2(x, 0.7), Vector2(x, 0.8), INK, 1.2)
	_poly(o, s, [0.42, 0.8, 0.58, 0.8, 0.56, 0.9, 0.44, 0.9], WICKER)   # the basket
	_poly(o, s, [0.47, 0.71, 0.53, 0.71, 0.5, 0.77], FLAME)   # the burner's flame


func _glider(o: Vector2, s: float) -> void:
	_poly(o, s, [0.08, 0.42, 0.3, 0.24, 0.5, 0.3, 0.7, 0.24, 0.92, 0.42, 0.76, 0.38, 0.62, 0.44, 0.5, 0.38, 0.38, 0.44,
		0.24, 0.38], CLOTH)
	for x: float in [0.2, 0.35, 0.65, 0.8]:   # the ribs, like a bird's wing
		_line(o, s, Vector2(0.5, 0.33), Vector2(x, 0.3 + absf(x - 0.5) * 0.3), WOOD, 1.5)
	draw_circle(_p(o, s, 0.5, 0.47), 0.04 * s, INK)   # the pilot hanging under it
	_line(o, s, Vector2(0.5, 0.5), Vector2(0.5, 0.64), INK, 4.0)
	_line(o, s, Vector2(0.5, 0.64), Vector2(0.46, 0.74), INK, 3.0)
	_line(o, s, Vector2(0.5, 0.64), Vector2(0.55, 0.74), INK, 3.0)
	_poly(o, s, [0.0, 0.9, 0.35, 0.78, 0.6, 0.95, 0.0, 1.0], Color("7cc36b"))   # the hill


func _plane(o: Vector2, s: float) -> void:
	for y: float in [0.34, 0.56]:
		_poly(o, s, [0.06, y, 0.94, y, 0.94, y + 0.05, 0.06, y + 0.05], CLOTH)
	for x: float in [0.14, 0.32, 0.68, 0.86]:
		_line(o, s, Vector2(x, 0.39), Vector2(x, 0.56), WOOD, 1.6)
	for x: float in [0.4, 0.6]:   # the propellers behind the wings
		_poly(o, s, [x - 0.012, 0.36, x + 0.012, 0.36, x + 0.012, 0.58, x - 0.012, 0.58], WOOD)
	_poly(o, s, [0.4, 0.66, 0.6, 0.66, 0.6, 0.69, 0.4, 0.69], CLOTH)   # the elevator
	draw_circle(_p(o, s, 0.5, 0.52), 0.035 * s, TEAL)   # the pilot
	_line(o, s, Vector2(0.3, 0.61), Vector2(0.28, 0.74), WOOD, 1.5)   # the skids
	_line(o, s, Vector2(0.7, 0.61), Vector2(0.72, 0.74), WOOD, 1.5)


func _jet(o: Vector2, s: float) -> void:
	_poly(o, s, [0.1, 0.5, 0.22, 0.42, 0.8, 0.44, 0.9, 0.5, 0.8, 0.56, 0.22, 0.56], WHITE)   # the body
	_poly(o, s, [0.4, 0.5, 0.62, 0.5, 0.48, 0.74, 0.38, 0.74], GREY)   # the swept wing
	_poly(o, s, [0.72, 0.45, 0.8, 0.45, 0.86, 0.26, 0.8, 0.26], RED)   # the tail fin
	_poly(o, s, [0.2, 0.44, 0.3, 0.38, 0.38, 0.44], GLASS)   # the canopy
	_poly(o, s, [0.22, 0.47, 0.8, 0.47, 0.8, 0.49, 0.22, 0.49], TEAL)
	_poly(o, s, [0.9, 0.47, 0.99, 0.5, 0.9, 0.53], FLAME)   # air rushing out of the back


func _rocket(o: Vector2, s: float) -> void:
	_poly(o, s, [0.42, 0.26, 0.58, 0.26, 0.58, 0.74, 0.42, 0.74], WHITE)
	_poly(o, s, [0.42, 0.26, 0.5, 0.08, 0.58, 0.26], RED)   # the nose
	draw_circle(_p(o, s, 0.5, 0.38), 0.045 * s, GLASS)   # the window
	_poly(o, s, [0.42, 0.5, 0.58, 0.5, 0.58, 0.54, 0.42, 0.54], TEAL)
	_poly(o, s, [0.42, 0.62, 0.32, 0.8, 0.42, 0.74], RED)   # the fins
	_poly(o, s, [0.58, 0.62, 0.68, 0.8, 0.58, 0.74], RED)
	_poly(o, s, [0.44, 0.74, 0.56, 0.74, 0.58, 0.8, 0.42, 0.8], IRON)   # the engine's bell
	_poly(o, s, [0.43, 0.8, 0.57, 0.8, 0.5, 0.97], FLAME)   # the fire pushing down
