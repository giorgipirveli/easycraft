class_name LifeIconsDanger
extends RefCounted
## Owner #118 (Life L3a: Water Safety, The Poisons Cupboard, Earth and Weather): the third wave of Life's pictures, drawn
## in code like LifeIcons (which asks here for any name LifeIconsMore doesn't draw). The same calm style: simple shapes,
## soft colours, a "no" in soft grey-blue, never red; people are friendly blocky figures, never hurt; water is a soft blue,
## a warning sign the real red diamond (the GHS's own colours, so a child knows it on a real bottle).

const NAMES: Array[String] = [
	# Water Safety
	"alone", "walk", "life_jacket", "ring_buoy", "reach_pole", "jump_in", "two_in_water", "flags", "rip_current",
	"swim_along", "float_wave", "quiet_swimmer", "waving", "splash", "still", "eye", "thin_ice", "arms_on_ice",
	"stand_on_ice", "crawl",
	# The Poisons Cupboard
	"warning_sign", "sym_flammable", "bottles", "fumes", "pills", "button_battery", "berries", "no_berries", "mushroom",
	"nose", "co_alarm",
	# Earth and Weather
	"table_shelter", "falling_tiles", "inside_wall", "lone_tree", "turn_around", "flood", "shade", "sun_hot", "hug_tree",
	"hide", "whistle", "layers", "shoes", "emergency_bag"]

const INK := LifeIcons.INK
const SKIN := LifeIcons.SKIN
const TEAL := LifeIcons.TEAL
const SOFT_NO := LifeIcons.SOFT_NO
const GOOD := LifeIcons.GOOD
const GOLD := LifeIcons.GOLD
const WOOD := LifeIcons.WOOD
const SKY := LifeIcons.SKY
const WHITE := LifeIcons.WHITE
const WATER := Color("5aa8e6")
const DEEP := Color("3a7be8")
const SAND := Color("ecd9a8")
const ICE := Color("cfe6f5")
const ORANGE := Color("ff7a2e")
const RED := Color("e8544e")
const LEAF := Color("3f8a3a")


static func has(name: String) -> bool:
	return NAMES.has(name)


## Draws `name` with `p` (0..100 coordinates to the canvas) and `u` (one unit); false for a name not drawn here.
static func paint(ci: CanvasItem, name: String, p: Callable, u: float) -> bool:
	match name:
		"alone":
			ci.draw_arc(p.call(50, 52), 40 * u, 0, TAU, 36, SOFT_NO, 3 * u)
			LifeIconsMore._child(ci, p, u, Vector2(50, 16), 0.9, TEAL)
		"walk":
			ci.draw_circle(p.call(50, 18), 10 * u, SKIN)
			ci.draw_line(p.call(50, 28), p.call(50, 58), TEAL, 11 * u)
			ci.draw_line(p.call(50, 58), p.call(40, 88), Color("3a5aa8"), 7 * u)
			ci.draw_line(p.call(50, 58), p.call(60, 88), Color("3a5aa8"), 7 * u)
			ci.draw_line(p.call(50, 36), p.call(40, 54), TEAL, 6 * u)
			ci.draw_line(p.call(50, 36), p.call(60, 54), TEAL, 6 * u)
		"life_jacket":
			ci.draw_colored_polygon(PackedVector2Array([p.call(26, 22), p.call(42, 14), p.call(50, 30), p.call(58, 14),
				p.call(74, 22), p.call(78, 86), p.call(22, 86)]), ORANGE)
			for y: float in [50, 68]:
				ci.draw_line(p.call(24, y), p.call(76, y), INK, 4 * u)
				ci.draw_rect(Rect2(p.call(45, y - 4), Vector2(10, 8) * u), INK)
		"ring_buoy":
			_ring(ci, p, u, Vector2(50, 50), 1.0)
		"reach_pole":
			_water(ci, p, u, 60)
			_kneeling(ci, p, u, Vector2(18, 34))
			ci.draw_line(p.call(30, 50), p.call(80, 66), GOLD, 6 * u)
			_head_in_water(ci, p, u, Vector2(82, 62), Color("ffb347"))
		"jump_in":
			_water(ci, p, u, 62)
			ci.draw_circle(p.call(64, 24), 9 * u, SKIN)
			ci.draw_line(p.call(60, 32), p.call(40, 48), TEAL, 10 * u)
			ci.draw_line(p.call(40, 48), p.call(26, 52), Color("3a5aa8"), 7 * u)
			ci.draw_line(p.call(64, 30), p.call(78, 44), TEAL, 6 * u)
		"two_in_water":
			_water(ci, p, u, 52)
			_head_in_water(ci, p, u, Vector2(34, 52), Color("ffb347"))
			_head_in_water(ci, p, u, Vector2(66, 52), TEAL)
			ci.draw_arc(p.call(50, 54), 34 * u, PI * 0.1, PI * 0.9, 16, Color(1, 1, 1, 0.7), 3 * u)
		"flags":
			_water(ci, p, u, 62)
			ci.draw_rect(Rect2(p.call(0, 80), Vector2(100, 20) * u), SAND)
			for x: float in [18, 78]:
				ci.draw_line(p.call(x, 20), p.call(x, 84), INK, 4 * u)
				ci.draw_rect(Rect2(p.call(x + 2, 20), Vector2(16, 9) * u), RED)
				ci.draw_rect(Rect2(p.call(x + 2, 29), Vector2(16, 9) * u), GOLD)
			LifeIconsMore._child(ci, p, u, Vector2(46, 46), 0.4, TEAL)
		"rip_current":
			ci.draw_rect(Rect2(p.call(0, 0), Vector2(100, 76) * u), WATER)
			ci.draw_rect(Rect2(p.call(0, 76), Vector2(100, 24) * u), SAND)
			ci.draw_rect(Rect2(p.call(38, 0), Vector2(24, 76) * u), DEEP.darkened(0.1))
			for y: float in [16, 40, 62]:
				_arrow(ci, p, u, Vector2(50, y + 10), Vector2(50, y - 6), WHITE)
			for x: float in [6, 76]:
				ci.draw_line(p.call(x, 30), p.call(x + 18, 30), WHITE, 4 * u)
		"swim_along":
			ci.draw_rect(Rect2(p.call(0, 0), Vector2(100, 70) * u), WATER)
			ci.draw_rect(Rect2(p.call(0, 70), Vector2(100, 30) * u), SAND)
			ci.draw_rect(Rect2(p.call(62, 0), Vector2(20, 70) * u), DEEP.darkened(0.1))
			_head_in_water(ci, p, u, Vector2(66, 44), TEAL)
			_arrow(ci, p, u, Vector2(56, 44), Vector2(16, 44), GOLD)
		"float_wave":
			_water(ci, p, u, 56)
			ci.draw_circle(p.call(50, 52), 11 * u, SKIN)
			ci.draw_line(p.call(58, 50), p.call(70, 16), SKIN.darkened(0.1), 7 * u)
			for r: float in [12, 20]:
				ci.draw_arc(p.call(72, 14), r * u, -0.9, 0.3, 8, WHITE, 3 * u)
		"quiet_swimmer":
			_water(ci, p, u, 50)
			ci.draw_circle(p.call(50, 46), 12 * u, SKIN)
			ci.draw_rect(Rect2(p.call(0, 50), Vector2(100, 50) * u), WATER)
			ci.draw_circle(p.call(46, 42), 2.5 * u, INK)
			ci.draw_circle(p.call(56, 42), 2.5 * u, INK)
			ci.draw_line(p.call(48, 49), p.call(54, 49), INK, 2 * u)
		"waving", "splash":
			_water(ci, p, u, 56)
			_head_in_water(ci, p, u, Vector2(50, 54), Color("e85a9a"))
			if name == "waving":
				ci.draw_line(p.call(60, 50), p.call(74, 20), SKIN.darkened(0.1), 7 * u)
				ci.draw_arc(p.call(50, 52), 6 * u, 0.2, PI - 0.2, 8, INK, 2.5 * u)
			else:
				for d: Vector2 in [Vector2(24, 40), Vector2(36, 30), Vector2(66, 30), Vector2(78, 42)]:
					ci.draw_circle(p.call(d.x, d.y), 5 * u, WHITE)
		"still":
			_water(ci, p, u, 56)
			_head_in_water(ci, p, u, Vector2(50, 54), TEAL)
			for r: float in [18, 28]:
				ci.draw_arc(p.call(50, 58), r * u, PI * 0.15, PI * 0.85, 14, Color(1, 1, 1, 0.8), 3 * u)
		"eye":
			ci.draw_colored_polygon(PackedVector2Array([p.call(10, 50), p.call(50, 26), p.call(90, 50), p.call(50, 74)]), WHITE)
			ci.draw_circle(p.call(50, 50), 16 * u, SKY)
			ci.draw_circle(p.call(50, 50), 7 * u, INK)
		"thin_ice", "stand_on_ice":
			ci.draw_rect(Rect2(p.call(0, 56), Vector2(100, 44) * u), ICE)
			for a: float in [0.3, 1.2, 2.2, 2.9]:
				ci.draw_line(p.call(50, 76), p.call(50 + cos(a) * 34, 76 + sin(a) * 14), Color("37506b"), 3 * u)
			if name == "stand_on_ice":
				LifeIconsMore._child(ci, p, u, Vector2(50, 0), 0.9, TEAL)
			else:
				ci.draw_rect(Rect2(p.call(14, 14), Vector2(36, 26) * u), WHITE)
				ci.draw_rect(Rect2(p.call(14, 14), Vector2(36, 26) * u), RED, false, 3 * u)
				ci.draw_line(p.call(30, 40), p.call(30, 56), WOOD, 4 * u)
		"arms_on_ice":
			ci.draw_rect(Rect2(p.call(0, 0), Vector2(100, 46) * u), ICE)
			ci.draw_rect(Rect2(p.call(0, 46), Vector2(100, 54) * u), WATER.darkened(0.2))
			ci.draw_circle(p.call(50, 56), 12 * u, SKIN)
			ci.draw_line(p.call(40, 44), p.call(12, 38), SKIN.darkened(0.1), 7 * u)
			ci.draw_line(p.call(60, 44), p.call(88, 38), SKIN.darkened(0.1), 7 * u)
		"crawl":
			ci.draw_rect(Rect2(p.call(0, 70), Vector2(100, 30) * u), ICE)
			ci.draw_circle(p.call(24, 52), 9 * u, SKIN)
			ci.draw_line(p.call(32, 56), p.call(70, 58), TEAL, 11 * u)
			ci.draw_line(p.call(34, 58), p.call(30, 72), TEAL, 6 * u)
			ci.draw_line(p.call(68, 60), p.call(80, 72), Color("3a5aa8"), 6 * u)
		"warning_sign":
			_diamond(ci, p, u, Vector2(50, 50), 1.0)
			ci.draw_line(p.call(50, 32), p.call(50, 56), INK, 7 * u)
			ci.draw_circle(p.call(50, 66), 4 * u, INK)
		"sym_flammable":
			_diamond(ci, p, u, Vector2(50, 50), 1.0)
			ci.draw_colored_polygon(PackedVector2Array([p.call(40, 62), p.call(44, 40), p.call(50, 48), p.call(54, 30),
				p.call(60, 62)]), INK)
			ci.draw_line(p.call(36, 66), p.call(64, 66), INK, 4 * u)
		"bottles":
			for b: Array in [[30, Color("f4f6f8")], [66, DEEP]]:
				var x: float = b[0]
				ci.draw_rect(Rect2(p.call(x - 12, 30), Vector2(24, 60) * u), b[1])
				ci.draw_rect(Rect2(p.call(x - 5, 18), Vector2(10, 12) * u), INK)
				_diamond(ci, p, u, Vector2(x, 60), 0.32)
		"fumes":
			ci.draw_rect(Rect2(p.call(28, 60), Vector2(44, 32) * u), DEEP)
			for c: Vector2 in [Vector2(38, 44), Vector2(52, 36), Vector2(64, 46), Vector2(48, 22), Vector2(62, 24)]:
				ci.draw_circle(p.call(c.x, c.y), 11 * u, Color(0.62, 0.72, 0.58, 0.85))
		"pills":
			ci.draw_rect(Rect2(p.call(18, 30), Vector2(26, 50) * u), Color("ffb02e"))
			ci.draw_rect(Rect2(p.call(16, 22), Vector2(30, 10) * u), WHITE)
			var cols := [Color("e85a9a"), DEEP, GOLD, GOOD]
			for i in 4:
				ci.draw_circle(p.call(58 + (i % 2) * 18, 52 + (i / 2) * 18), 7 * u, cols[i])
		"button_battery":
			ci.draw_circle(p.call(50, 50), 32 * u, Color("c9ced6"))
			ci.draw_arc(p.call(50, 50), 32 * u, 0, TAU, 36, Color("9aa7b5"), 4 * u)
			ci.draw_line(p.call(42, 50), p.call(58, 50), INK, 4 * u)
			ci.draw_line(p.call(50, 42), p.call(50, 58), INK, 4 * u)
			ci.draw_circle(p.call(38, 36), 5 * u, Color(1, 1, 1, 0.7))
		"berries", "no_berries":
			ci.draw_circle(p.call(50, 50), 34 * u, LEAF)
			for d: Vector2 in [Vector2(36, 40), Vector2(52, 34), Vector2(64, 48), Vector2(44, 58), Vector2(58, 64)]:
				ci.draw_circle(p.call(d.x, d.y), 6 * u, RED)
			if name == "no_berries":
				ci.draw_arc(p.call(50, 50), 44 * u, 0, TAU, 36, SOFT_NO, 6 * u)
				ci.draw_line(p.call(20, 80), p.call(80, 20), SOFT_NO, 6 * u)
		"mushroom":
			for m: Array in [[34, 1.0], [66, 0.8]]:
				var x: float = m[0]
				var k: float = m[1]
				ci.draw_rect(Rect2(p.call(x - 6 * k, 56), Vector2(12 * k, 30) * u), Color("f4efe2"))
				ci.draw_arc(p.call(x, 58), 20 * k * u, PI, TAU, 16, WHITE, 18 * k * u)
		"nose":
			ci.draw_colored_polygon(PackedVector2Array([p.call(30, 20), p.call(48, 64), p.call(30, 70)]), SKIN)
			for i in 3:
				ci.draw_arc(p.call(60 + i * 10, 50), 8 * u, -1.2, 1.2, 8, SOFT_NO, 3 * u)
		"co_alarm":
			ci.draw_circle(p.call(50, 50), 34 * u, WHITE)
			ci.draw_arc(p.call(50, 50), 34 * u, 0, TAU, 36, Color("c9ced6"), 4 * u)
			ci.draw_arc(p.call(42, 50), 9 * u, 0.6, TAU - 0.6, 14, INK, 4 * u)
			ci.draw_arc(p.call(60, 50), 9 * u, 0, TAU, 14, INK, 4 * u)
			ci.draw_circle(p.call(70, 30), 4 * u, GOOD)
		"table_shelter":
			ci.draw_rect(Rect2(p.call(10, 30), Vector2(80, 8) * u), WOOD)
			for x: float in [14, 80]:
				ci.draw_rect(Rect2(p.call(x, 38), Vector2(6, 52) * u), WOOD.darkened(0.2))
			ci.draw_circle(p.call(40, 62), 9 * u, SKIN)
			ci.draw_line(p.call(48, 66), p.call(68, 74), TEAL, 11 * u)
			ci.draw_line(p.call(44, 58), p.call(78, 46), SKIN.darkened(0.1), 5 * u)
		"falling_tiles":
			ci.draw_rect(Rect2(p.call(30, 40), Vector2(40, 60) * u), WOOD)
			for t: Vector2 in [Vector2(20, 12), Vector2(50, 6), Vector2(70, 18)]:
				ci.draw_rect(Rect2(p.call(t.x, t.y), Vector2(16, 8) * u), Color("b5553a"))
				ci.draw_line(p.call(t.x + 8, t.y + 10), p.call(t.x + 8, t.y + 20), SOFT_NO, 2 * u)
		"inside_wall":
			ci.draw_rect(Rect2(p.call(8, 8), Vector2(18, 86) * u), Color("d7d2c8"))
			ci.draw_circle(p.call(46, 66), 10 * u, SKIN)
			ci.draw_line(p.call(36, 60), p.call(56, 58), TEAL, 6 * u)
			ci.draw_line(p.call(48, 74), p.call(74, 82), TEAL, 11 * u)
		"lone_tree":
			ci.draw_circle(p.call(26, 20), 14 * u, Color(0.6, 0.63, 0.7))
			ci.draw_circle(p.call(44, 16), 12 * u, Color(0.6, 0.63, 0.7))
			ci.draw_colored_polygon(PackedVector2Array([p.call(0, 100), p.call(50, 64), p.call(100, 100)]), GOOD.darkened(0.2))
			ci.draw_rect(Rect2(p.call(60, 50), Vector2(6, 22) * u), WOOD)
			ci.draw_circle(p.call(63, 44), 12 * u, GOOD)
		"turn_around":
			ci.draw_arc(p.call(50, 46), 22 * u, PI, TAU, 16, GOOD, 9 * u)
			ci.draw_line(p.call(28, 46), p.call(28, 80), GOOD, 9 * u)
			ci.draw_line(p.call(72, 46), p.call(72, 70), GOOD, 9 * u)
			ci.draw_colored_polygon(PackedVector2Array([p.call(18, 74), p.call(38, 74), p.call(28, 90)]), GOOD)
		"flood":
			ci.draw_rect(Rect2(p.call(0, 50), Vector2(100, 50) * u), Color(0.48, 0.55, 0.62))
			for y: float in [62, 78]:
				_arrow(ci, p, u, Vector2(10, y), Vector2(90, y), WHITE)
			ci.draw_rect(Rect2(p.call(42, 20), Vector2(16, 30) * u), Color("d8d2c4"))
		"shade":
			ci.draw_circle(p.call(80, 16), 12 * u, Color(1.0, 0.92, 0.5))
			ci.draw_rect(Rect2(p.call(36, 40), Vector2(8, 40) * u), WOOD)
			ci.draw_circle(p.call(40, 32), 24 * u, GOOD)
			ci.draw_rect(Rect2(p.call(14, 82), Vector2(56, 8) * u), Color(0.2, 0.35, 0.2, 0.5))
			ci.draw_rect(Rect2(p.call(56, 64), Vector2(8, 18) * u), Color(0.7, 0.88, 1.0))
		"sun_hot":
			ci.draw_circle(p.call(50, 50), 22 * u, Color(1.0, 0.85, 0.3))
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(p.call(50 + cos(a) * 30, 50 + sin(a) * 30), p.call(50 + cos(a) * 42, 50 + sin(a) * 42),
					Color(1.0, 0.75, 0.25), 5 * u)
		"hug_tree":
			ci.draw_rect(Rect2(p.call(42, 6), Vector2(16, 90) * u), WOOD)
			ci.draw_circle(p.call(30, 40), 9 * u, SKIN)
			ci.draw_line(p.call(30, 50), p.call(30, 76), TEAL, 10 * u)
			ci.draw_line(p.call(32, 54), p.call(64, 54), SKIN.darkened(0.1), 5 * u)
		"hide":
			ci.draw_circle(p.call(50, 64), 30 * u, LEAF)
			ci.draw_circle(p.call(50, 36), 10 * u, SKIN)
			ci.draw_circle(p.call(46, 34), 2 * u, INK)
			ci.draw_circle(p.call(54, 34), 2 * u, INK)
		"whistle":
			ci.draw_rect(Rect2(p.call(20, 44), Vector2(30, 22) * u), RED)
			ci.draw_circle(p.call(52, 58), 14 * u, RED)
			ci.draw_circle(p.call(52, 58), 5 * u, WHITE)
			for r: float in [10, 18, 26]:
				ci.draw_arc(p.call(70, 40), r * u, -1.0, 0.2, 8, SOFT_NO, 3 * u)
		"layers":
			ci.draw_rect(Rect2(p.call(24, 44), Vector2(52, 46) * u), DEEP)
			ci.draw_rect(Rect2(p.call(32, 50), Vector2(36, 40) * u), RED)
			ci.draw_arc(p.call(50, 30), 16 * u, PI, TAU, 12, GOLD, 12 * u)
			ci.draw_rect(Rect2(p.call(32, 30), Vector2(36, 6) * u), GOLD.darkened(0.15))
		"shoes":
			for x: float in [18, 54]:
				ci.draw_rect(Rect2(p.call(x, 48), Vector2(28, 22) * u), DEEP)
				ci.draw_rect(Rect2(p.call(x - 2, 68), Vector2(34, 8) * u), INK)
		"emergency_bag":
			ci.draw_rect(Rect2(p.call(22, 28), Vector2(56, 62) * u), RED)
			ci.draw_arc(p.call(50, 28), 14 * u, PI, TAU, 12, RED.darkened(0.2), 6 * u)
			ci.draw_rect(Rect2(p.call(44, 46), Vector2(12, 30) * u), WHITE)
			ci.draw_rect(Rect2(p.call(35, 55), Vector2(30, 12) * u), WHITE)
		_:
			return false
	return true


# --- Pieces ------------------------------------------------------------------------------------------------------------

static func _water(ci: CanvasItem, p: Callable, u: float, top: float) -> void:
	ci.draw_rect(Rect2(p.call(0, top), Vector2(100, 100 - top) * u), WATER)
	ci.draw_line(p.call(0, top), p.call(100, top), Color(1, 1, 1, 0.7), 3 * u)


static func _head_in_water(ci: CanvasItem, p: Callable, u: float, at: Vector2, colour: Color) -> void:
	ci.draw_circle(p.call(at.x, at.y - 6), 11 * u, SKIN)
	ci.draw_rect(Rect2(p.call(at.x - 10, at.y + 2), Vector2(20, 6) * u), colour)
	ci.draw_circle(p.call(at.x - 4, at.y - 8), 2 * u, INK)
	ci.draw_circle(p.call(at.x + 4, at.y - 8), 2 * u, INK)
	ci.draw_rect(Rect2(p.call(at.x - 14, at.y + 2), Vector2(28, 4) * u), WATER)


static func _kneeling(ci: CanvasItem, p: Callable, u: float, head: Vector2) -> void:
	ci.draw_circle(p.call(head.x, head.y), 9 * u, SKIN)
	ci.draw_line(p.call(head.x, head.y + 8), p.call(head.x + 4, head.y + 28), TEAL, 10 * u)
	ci.draw_line(p.call(head.x + 4, head.y + 28), p.call(head.x + 16, head.y + 30), Color("3a5aa8"), 7 * u)


static func _ring(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float) -> void:
	for i in 8:
		var a0 := TAU * i / 8.0
		ci.draw_arc(p.call(at.x, at.y), 30 * k * u, a0, a0 + TAU / 8.0, 6, ORANGE if i % 2 == 0 else WHITE, 14 * k * u)


static func _diamond(ci: CanvasItem, p: Callable, u: float, at: Vector2, k: float) -> void:
	var r := 40.0 * k
	ci.draw_colored_polygon(PackedVector2Array([p.call(at.x, at.y - r), p.call(at.x + r, at.y), p.call(at.x, at.y + r),
		p.call(at.x - r, at.y)]), RED)
	var w := r * 0.8
	ci.draw_colored_polygon(PackedVector2Array([p.call(at.x, at.y - w), p.call(at.x + w, at.y), p.call(at.x, at.y + w),
		p.call(at.x - w, at.y)]), WHITE)


static func _arrow(ci: CanvasItem, p: Callable, u: float, from: Vector2, to: Vector2, colour: Color) -> void:
	ci.draw_line(p.call(from.x, from.y), p.call(to.x, to.y), colour, 5 * u)
	var d := (to - from).normalized()
	var side := Vector2(-d.y, d.x)
	ci.draw_colored_polygon(PackedVector2Array([p.call(to.x + d.x * 6, to.y + d.y * 6),
		p.call(to.x - d.x * 4 + side.x * 7, to.y - d.y * 4 + side.y * 7), p.call(to.x - d.x * 4 - side.x * 7, to.y - d.y * 4 - side.y * 7)]),
		colour)
