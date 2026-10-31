class_name LabArt
extends RefCounted
## Spec §23: the Science Lab's drawings, in code (UI draw calls only, no art files; our own friendly look, spec §3c): a
## small picture per experiment kind for the Lab's cards and the Lab Book (`card`), and the pieces the scenes are drawn
## from: a water tank, a horseshoe magnet, a beaker, a lab burner, a thermometer in °C, a plant pot, a bulb, a battery,
## a switch and a star.

const INK := Color("1f2a4a")
const GLASS := Color(0.78, 0.92, 1.0, 0.35)
const GLASS_EDGE := Color("5aa9cf")
const WATER := Color(0.24, 0.55, 0.95, 0.45)
const METAL := Color("8e98a4")
const METAL_DARK := Color("5d6772")
const FLAME := Color("3a8ef0")
const FLAME_HI := Color("a8dcff")
const MAGNET_RED := Color("d9463b")
const POT := Color("c8683a")
const SOIL := Color("6b4a2f")
const LEAF := Color("3fae4a")
const PALE := Color("e8dc8a")   # a shoot grown in the dark
const COPPER := Color("c46a2a")
const GOLD := Color("ffd23f")


## The picture of an experiment of `kind` (a card, the Lab Book) in `r`.
static func card(ci: CanvasItem, kind: String, r: Rect2) -> void:
	var s := minf(r.size.x, r.size.y)
	var c := r.get_center()
	match kind:
		"tank":
			var t := Rect2(c - Vector2(s * 0.7, s * 0.4), Vector2(s * 1.4, s * 0.8))
			var surface := tank(ci, t, 0.65, false)
			LabThings.draw(ci, "wood", Rect2(Vector2(t.position.x + t.size.x * 0.22, surface - s * 0.16), Vector2(s * 0.3, s * 0.3)))
			LabThings.draw(ci, "stone", Rect2(Vector2(t.position.x + t.size.x * 0.58, t.end.y - s * 0.3), Vector2(s * 0.28, s * 0.28)))
			tank_water(ci, t, 0.65)
		"magnet":
			magnet(ci, c + Vector2(-s * 0.15, -s * 0.08), s * 0.62)
			LabThings.draw(ci, "iron", Rect2(c + Vector2(-s * 0.4, s * 0.14), Vector2(s * 0.5, s * 0.5)))
			LabThings.draw(ci, "clip", Rect2(c + Vector2(s * 0.3, s * 0.05), Vector2(s * 0.36, s * 0.36)))
		"heat":
			burner(ci, c + Vector2(-s * 0.25, s * 0.36), s * 0.3, true)
			beaker(ci, Rect2(c + Vector2(-s * 0.5, -s * 0.36), Vector2(s * 0.5, s * 0.56)), 1, false)
			thermometer(ci, Rect2(c + Vector2(s * 0.3, -s * 0.45), Vector2(s * 0.24, s * 0.9)), 0, -20, 110, false)
		"colours":
			var rr := s * 0.26
			for i in 3:
				var at := c + Vector2(cos(TAU * i / 3.0 - PI / 2.0), sin(TAU * i / 3.0 - PI / 2.0)) * rr * 0.7
				ci.draw_circle(at, rr, Color([Color(1, 0.2, 0.2, 0.7), Color(0.2, 0.9, 0.3, 0.7), Color(0.25, 0.45, 1, 0.7)][i]))
		"plants":
			var w := s * 0.42
			for i in 3:
				var look: StringName = [LabPlants.PLANT, LabPlants.PALE_SHOOT, LabPlants.SEED][i]
				pot(ci, Rect2(c + Vector2((i - 1) * w * 1.1 - w * 0.5, -s * 0.45), Vector2(w, s * 0.9)), look)
		"circuit":
			var b := Rect2(c + Vector2(-s * 0.7, -s * 0.12), Vector2(s * 0.34, s * 0.5))
			battery(ci, b)
			var bulb_at := c + Vector2(s * 0.35, -s * 0.18)
			var pts := PackedVector2Array([b.position + Vector2(b.size.x * 0.5, 0), Vector2(b.position.x + b.size.x * 0.5, c.y - s * 0.4),
				Vector2(bulb_at.x, c.y - s * 0.4), bulb_at + Vector2(0, -s * 0.12)])
			ci.draw_polyline(pts, COPPER, maxf(2.0, s * 0.04))
			ci.draw_polyline(PackedVector2Array([bulb_at + Vector2(0, s * 0.14), Vector2(bulb_at.x, c.y + s * 0.42),
				Vector2(b.position.x + b.size.x * 0.5, c.y + s * 0.42), b.end - Vector2(b.size.x * 0.5, 0)]), COPPER, maxf(2.0, s * 0.04))
			bulb(ci, bulb_at, s * 0.16, 1.0)


# --- The pieces -----------------------------------------------------------------------------------------------------

## A glass tank with water up to `frac` of its height (the water drawn after what is in it: tank_water). Returns the
## water's surface y.
static func tank(ci: CanvasItem, r: Rect2, frac: float, with_water: bool = true) -> float:
	ci.draw_rect(r, Color(0.9, 0.97, 1.0, 0.6))
	var surface := r.end.y - r.size.y * frac
	if with_water:
		tank_water(ci, r, frac)
	return surface


## The tank's water, drawn over the things in it (so a floater shows above the surface and is tinted below it).
static func tank_water(ci: CanvasItem, r: Rect2, frac: float) -> void:
	var surface := r.end.y - r.size.y * frac
	ci.draw_rect(Rect2(Vector2(r.position.x, surface), Vector2(r.size.x, r.end.y - surface)), WATER)
	ci.draw_line(Vector2(r.position.x, surface), Vector2(r.end.x, surface), Color(1, 1, 1, 0.7), maxf(1.5, r.size.y * 0.012))
	ci.draw_rect(r, GLASS_EDGE, false, maxf(2.0, r.size.y * 0.02))


## A horseshoe magnet opening downwards, `size` wide, its top at `c` less a little; returns the two poles' tips.
static func magnet(ci: CanvasItem, c: Vector2, size: float) -> Array[Vector2]:
	var w := size * 0.2
	var r := size * 0.4
	ci.draw_arc(c, r, PI, TAU, 24, MAGNET_RED, w)
	var legs := [c + Vector2(-r, 0), c + Vector2(r, 0)]
	var tips: Array[Vector2] = []
	for p: Vector2 in legs:
		ci.draw_rect(Rect2(p - Vector2(w * 0.5, 0), Vector2(w, size * 0.34)), MAGNET_RED)
		ci.draw_rect(Rect2(p + Vector2(-w * 0.5, size * 0.34), Vector2(w, size * 0.16)), Color("d7dde4"))
		tips.append(p + Vector2(0, size * 0.5))
	ci.draw_arc(c, r, PI * 1.15, PI * 1.4, 8, Color(1, 1, 1, 0.45), w * 0.25)
	return tips


## A glass beaker: `ice` parts of LabHeat.ICE_PARTS still ice (cubes), the rest water; bubbles and steam when boiling.
static func beaker(ci: CanvasItem, r: Rect2, ice: int, boiling: bool) -> void:
	var inner := r.grow(-r.size.x * 0.06)
	var level := inner.end.y - inner.size.y * 0.6
	if ice < LabHeat.ICE_PARTS:   # water
		ci.draw_rect(Rect2(Vector2(inner.position.x, level), Vector2(inner.size.x, inner.end.y - level)), Color(0.3, 0.6, 1.0, 0.55))
	var cube := inner.size.x * 0.28
	var cubes := 3 if ice == LabHeat.ICE_PARTS else (2 if ice > 0 else 0)
	for i in cubes:
		var at := Vector2(inner.position.x + inner.size.x * (0.1 + 0.3 * i), (inner.end.y - cube * (1.05 + 0.3 * (i % 2)))
			if ice == LabHeat.ICE_PARTS else level - cube * 0.35)
		ci.draw_rect(Rect2(at, Vector2(cube, cube)), Color("d8f3ff"))
		ci.draw_rect(Rect2(at, Vector2(cube, cube)), Color("7cc3e3"), false, maxf(1.0, cube * 0.06))
	if boiling:
		for i in 7:
			var p := Vector2(inner.position.x + inner.size.x * fmod(0.13 + i * 0.37, 1.0), level + (inner.end.y - level) * fmod(0.2 + i * 0.29, 0.9))
			ci.draw_arc(p, inner.size.x * 0.035, 0, TAU, 10, Color(1, 1, 1, 0.9), maxf(1.0, inner.size.x * 0.012))
		for i in 3:   # steam rising
			var x := inner.position.x + inner.size.x * (0.25 + 0.25 * i)
			var pts := PackedVector2Array()
			for k in 8:
				pts.append(Vector2(x + sin(k * 0.9 + i) * inner.size.x * 0.05, r.position.y - k * r.size.y * 0.06))
			ci.draw_polyline(pts, Color(1, 1, 1, 0.8), maxf(2.0, inner.size.x * 0.03))
	# the glass: sides and bottom, a lip at the top, a few measuring marks
	var edge := maxf(2.0, r.size.x * 0.03)
	ci.draw_rect(r, Color(0.85, 0.95, 1.0, 0.18))
	ci.draw_polyline(PackedVector2Array([r.position, Vector2(r.position.x, r.end.y), r.end, Vector2(r.end.x, r.position.y)]), GLASS_EDGE, edge)
	for i in 3:
		var y := r.end.y - r.size.y * (0.25 + 0.2 * i)
		ci.draw_line(Vector2(r.end.x - r.size.x * 0.2, y), Vector2(r.end.x - edge, y), GLASS_EDGE, maxf(1.0, edge * 0.5))


## A lab burner on its foot, its blue flame when `lit`.
static func burner(ci: CanvasItem, c: Vector2, size: float, lit: bool) -> void:
	ci.draw_rect(Rect2(c + Vector2(-size * 0.5, size * 0.3), Vector2(size, size * 0.14)), METAL_DARK)
	ci.draw_rect(Rect2(c + Vector2(-size * 0.12, -size * 0.1), Vector2(size * 0.24, size * 0.42)), METAL)
	if lit:
		var tip := c + Vector2(0, -size * 0.75)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-size * 0.16, -size * 0.1), tip, c + Vector2(size * 0.16, -size * 0.1)]), FLAME)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-size * 0.07, -size * 0.1), c + Vector2(0, -size * 0.45),
			c + Vector2(size * 0.07, -size * 0.1)]), FLAME_HI)


## A thermometer in °C from `low` to `high`, its red column up to `temp`; `labels`: numbers every 20 degrees.
static func thermometer(ci: CanvasItem, r: Rect2, temp: int, low: int, high: int, labels: bool) -> void:
	var tube := Rect2(r.position + Vector2(r.size.x * 0.3, 0), Vector2(r.size.x * 0.4, r.size.y * 0.86))
	var bulb_c := Vector2(tube.get_center().x, tube.end.y + r.size.x * 0.12)
	ci.draw_rect(tube, Color("f4f8fc"))
	ci.draw_circle(bulb_c, r.size.x * 0.3, Color("e0453a"))
	var y_of := func(t: float) -> float: return tube.end.y - (t - low) / float(high - low) * tube.size.y * 0.94
	var top: float = y_of.call(clampf(temp, low, high))
	ci.draw_rect(Rect2(Vector2(tube.position.x + tube.size.x * 0.25, top), Vector2(tube.size.x * 0.5, tube.end.y - top + 2)), Color("e0453a"))
	ci.draw_rect(tube, INK, false, maxf(1.5, r.size.x * 0.03))
	var font := ThemeDB.fallback_font
	for t in range(low, high + 1, 10):
		var y: float = y_of.call(t)
		var long := t % 20 == 0
		ci.draw_line(Vector2(tube.end.x, y), Vector2(tube.end.x + tube.size.x * (0.5 if long else 0.25), y), INK, maxf(1.0, r.size.x * 0.02))
		if labels and long:
			var fs := int(clampf(r.size.x * 0.2, 12, 22))
			ci.draw_string(font, Vector2(tube.end.x + tube.size.x * 0.6, y + fs * 0.35), LabHeat.degrees(t).replace(" °C", ""),
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


## A plant pot showing `look` (LabPlants): a seed, a sprout, a plant, or their pale versions grown in the dark.
static func pot(ci: CanvasItem, r: Rect2, look: StringName) -> void:
	var w := r.size.x
	var base := r.end.y
	var top := base - r.size.y * 0.34
	var pts := PackedVector2Array([Vector2(r.position.x + w * 0.1, top), Vector2(r.end.x - w * 0.1, top),
		Vector2(r.end.x - w * 0.22, base), Vector2(r.position.x + w * 0.22, base)])
	ci.draw_colored_polygon(pts, POT)
	ci.draw_rect(Rect2(Vector2(r.position.x + w * 0.06, top - r.size.y * 0.05), Vector2(w * 0.88, r.size.y * 0.07)), Color("a8522a"))
	ci.draw_rect(Rect2(Vector2(r.position.x + w * 0.12, top + r.size.y * 0.02), Vector2(w * 0.76, r.size.y * 0.05)), SOIL)
	var ground := Vector2(r.get_center().x, top)
	var green := LEAF if look in [LabPlants.SPROUT, LabPlants.PLANT] else PALE
	var stem := maxf(2.0, w * 0.035)
	match look:
		LabPlants.SEED:   # a seed lying on the soil
			var seed := ground + Vector2(0, -w * 0.03)
			ci.draw_set_transform(seed, 0.4, Vector2(1.0, 0.65))
			ci.draw_circle(Vector2.ZERO, w * 0.075, Color("8a5a2b"))
			ci.draw_circle(Vector2(-w * 0.02, -w * 0.02), w * 0.025, Color("c49060"))
			ci.draw_set_transform(Vector2.ZERO)
		LabPlants.SPROUT, LabPlants.PALE_SPROUT:
			var h := r.size.y * (0.18 if look == LabPlants.SPROUT else 0.26)
			ci.draw_line(ground, ground - Vector2(0, h), green, stem)
			_leaf(ci, ground - Vector2(0, h), w * 0.12, -0.5, green)
			_leaf(ci, ground - Vector2(0, h), w * 0.12, PI + 0.5, green)
		LabPlants.PLANT:
			var h := r.size.y * 0.5
			ci.draw_line(ground, ground - Vector2(0, h), green, stem * 1.3)
			for k in 3:
				var at := ground - Vector2(0, h * (0.35 + 0.28 * k))
				_leaf(ci, at, w * (0.22 - 0.03 * k), -0.35, green)
				_leaf(ci, at, w * (0.22 - 0.03 * k), PI + 0.35, green)
		LabPlants.PALE_SHOOT:   # tall, thin and pale: stretching for light
			var h := r.size.y * 0.62
			ci.draw_polyline(PackedVector2Array([ground, ground - Vector2(w * 0.03, h * 0.5), ground - Vector2(-w * 0.02, h)]), green, stem * 0.8)
			_leaf(ci, ground - Vector2(-w * 0.02, h), w * 0.08, -0.6, green)
			_leaf(ci, ground - Vector2(-w * 0.02, h), w * 0.08, PI + 0.6, green)


static func _leaf(ci: CanvasItem, at: Vector2, length: float, angle: float, color: Color) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	var side := Vector2(-dir.y, dir.x) * length * 0.32
	ci.draw_colored_polygon(PackedVector2Array([at, at + dir * length * 0.5 + side, at + dir * length,
		at + dir * length * 0.5 - side]), color)


## A light bulb; `glow` 0 (off) to 1 (bright): a quarter is clearly dimmer, never invisible.
static func bulb(ci: CanvasItem, c: Vector2, r: float, glow: float) -> void:
	if glow > 0.0:
		var g := clampf(0.35 + 0.65 * sqrt(glow), 0.0, 1.0)
		for i in 4:
			ci.draw_circle(c, r * (2.6 - 0.4 * i) * g, Color(1.0, 0.92, 0.4, 0.12 + 0.05 * i))
	ci.draw_circle(c, r, Color(1.0, 0.95, 0.55) if glow > 0.0 else Color(0.92, 0.95, 1.0, 0.9))
	ci.draw_arc(c, r, 0, TAU, 24, GLASS_EDGE, maxf(1.5, r * 0.1))
	ci.draw_rect(Rect2(c + Vector2(-r * 0.5, r * 0.85), Vector2(r, r * 0.55)), METAL)
	ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.3, r * 0.8), c + Vector2(-r * 0.15, 0), c + Vector2(0, r * 0.25),
		c + Vector2(r * 0.15, 0), c + Vector2(r * 0.3, r * 0.8)]), Color("ff8c1a") if glow > 0.0 else METAL_DARK, maxf(1.0, r * 0.08))


## A battery standing up (+ at the top).
static func battery(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.35, 0), Vector2(r.size.x * 0.3, r.size.y * 0.08)), METAL)
	var body := Rect2(r.position + Vector2(0, r.size.y * 0.08), Vector2(r.size.x, r.size.y * 0.92))
	ci.draw_rect(body, Color("2b2f3a"))
	ci.draw_rect(Rect2(body.position, Vector2(body.size.x, body.size.y * 0.3)), Color("f0a020"))
	var font := ThemeDB.fallback_font
	var fs := int(clampf(r.size.x * 0.5, 12, 30))
	ci.draw_string(font, body.position + Vector2(body.size.x * 0.3, body.size.y * 0.26), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	ci.draw_string(font, body.position + Vector2(body.size.x * 0.34, body.size.y * 0.9), "−", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## A knife switch from `a` to `b`: closed (lying flat) or open (lifted).
static func switch(ci: CanvasItem, a: Vector2, b: Vector2, closed: bool, width: float) -> void:
	ci.draw_circle(a, width * 1.2, METAL_DARK)
	ci.draw_circle(b, width * 1.2, METAL_DARK)
	var arm := b - a
	var end := b if closed else a + arm.rotated(-0.6) * 0.95
	ci.draw_line(a, end, METAL, width)
	ci.draw_circle(end.lerp(a, 0.1), width * 0.8, Color("d9463b"))


## A five-pointed star (the Lab Book's), gold when `filled`.
static func star(ci: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var pts := SchoolUi.star_points(c, r)
	if filled:
		ci.draw_colored_polygon(pts, GOLD)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, Color("b8860b") if filled else Color(0.5, 0.45, 0.4, 0.6), maxf(1.5, r * 0.1), true)


## A Control that draws an experiment kind's card picture in its rect.
class Card:
	extends Control
	var kind := ""

	func _init(k: String = "", px: Vector2 = Vector2(200, 120)) -> void:
		kind = k
		custom_minimum_size = px
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		LabArt.card(self, kind, Rect2(Vector2.ZERO, size))


## A Control that draws a star (the Lab Book's mark).
class Star:
	extends Control
	var filled := false:
		set(v):
			filled = v
			queue_redraw()

	func _init(px: float = 32.0) -> void:
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := minf(size.x, size.y)
		LabArt.star(self, size * 0.5, s * 0.46, filled)
