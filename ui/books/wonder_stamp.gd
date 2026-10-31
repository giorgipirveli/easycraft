class_name WonderStamp
extends Control
## A wonder's stamp in the Wonders Passport (owner #78, spec §24): a round stamp in its own ink with the wonder's shape
## drawn in simple strokes (our own art, §3c: a stepped pyramid, terraces with a palm, a temple front, Zeus on his
## throne, the Mausoleum's stepped roof, the Colossus with its torch, the Lighthouse's three tiers and fire; the New Seven:
## the Great Wall over its hills with a tower, Petra's rose facade with its urn, the Colosseum's rows of arches broken on
## one side, El Castillo's steps and temple, Machu Picchu's terraces under its peak, the Taj Mahal's dome between two
## minarets, Christ the Redeemer's open arms on his mountain; nature's: the canyon's layers, the reef's corals and a fish,
## the Sugarloaf over the bay, Everest's snowy peak, the northern lights over a pine, Parícutin's glowing cone in its
## corn, the falls with a rainbow). Not stamped yet: a pale ring with a question mark. Drawn in code; nothing is loaded.

const INKS := {&"pyramid": Color("b8862b"), &"gardens": Color("3f8f3a"), &"artemis": Color("5a6fb0"),
	&"zeus": Color("b0782a"), &"mausoleum": Color("7a5a9a"), &"colossus": Color("a0602a"), &"lighthouse": Color("2f7fb0"),
	&"tour": Color("139e9b"),
	&"great_wall": Color("5f6670"), &"petra": Color("b0503f"), &"colosseum": Color("9a7a44"), &"chichen_itza": Color("5f8a3a"),
	&"machu_picchu": Color("2f7a5a"), &"taj_mahal": Color("7a5fb0"), &"christ_redeemer": Color("3f78a8"),
	&"tour_new": Color("c0602b"),
	&"grand_canyon": Color("b0502f"), &"barrier_reef": Color("1f8a95"), &"rio_harbour": Color("2f7f6a"),
	&"everest": Color("4a5f8f"), &"northern_lights": Color("2f8a5a"), &"paricutin": Color("7a2f22"),
	&"victoria_falls": Color("2f6fb0"), &"tour_nature": Color("3f8f3a")}
const PALE := Color(0.45, 0.4, 0.33, 0.35)

var wonder: StringName = &"":
	set(value):
		wonder = value
		queue_redraw()
var stamped := false:
	set(value):
		stamped = value
		queue_redraw()


func _init(id: StringName = &"", is_stamped: bool = false, px: float = 96.0) -> void:
	wonder = id
	stamped = is_stamped
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var r := s * 0.46
	if not stamped:
		draw_arc(c, r, 0.0, TAU, 48, PALE, s * 0.05, true)
		var f := get_theme_default_font()
		draw_string(f, c + Vector2(-s * 0.12, s * 0.14), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, int(s * 0.42), PALE)
		return
	var ink: Color = INKS.get(wonder, Color("5a3310"))
	draw_circle(c, r, Color(1, 0.98, 0.92, 0.9))
	draw_arc(c, r, 0.0, TAU, 48, ink, s * 0.05, true)
	draw_arc(c, r * 0.86, 0.0, TAU, 48, ink, s * 0.015, true)
	emblem(self, wonder, c, r * 0.7, ink)


## Wonder `id`'s shape drawn on `ci` round `c` within radius r, in `ink`.
static func emblem(ci: CanvasItem, id: StringName, c: Vector2, r: float, ink: Color) -> void:
	var w := r * 0.12
	match id:
		&"pyramid":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, r * 0.6), c + Vector2(r, r * 0.6),
				c + Vector2(0, -r * 0.75)]), Color("e2c98f"))
			for i in 4:
				var y := r * (0.6 - 0.34 * i)
				var hw := r * (1.0 - 0.25 * i)
				ci.draw_line(c + Vector2(-hw, y), c + Vector2(hw, y), ink, w * 0.5)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r, r * 0.6), c + Vector2(0, -r * 0.75),
				c + Vector2(r, r * 0.6), c + Vector2(-r, r * 0.6)]), ink, w)
		&"gardens":
			for i in 3:
				var hw := r * (0.95 - 0.28 * i)
				var y := r * (0.55 - 0.4 * i)
				ci.draw_rect(Rect2(c + Vector2(-hw, y - r * 0.3), Vector2(hw * 2, r * 0.3)), Color("d8b56a"))
				ci.draw_rect(Rect2(c + Vector2(-hw, y - r * 0.36), Vector2(hw * 2, r * 0.08)), Color("4f9a3a"))
			ci.draw_line(c + Vector2(r * 0.1, -r * 0.62), c + Vector2(r * 0.1, -r * 0.95), Color("7a5a2a"), w)
			for a: float in [-2.6, -1.9, -1.2, -0.5]:
				ci.draw_line(c + Vector2(r * 0.1, -r * 0.95), c + Vector2(r * 0.1, -r * 0.95) + Vector2(cos(a), sin(a) * 0.5)
					* r * 0.35, Color("3f8f3a"), w)
		&"artemis", &"zeus", &"mausoleum":
			_temple(ci, id, c, r, ink, w)
		&"colossus":
			var bronze := Color("c98f3c")
			ci.draw_rect(Rect2(c + Vector2(-r * 0.35, r * 0.62), Vector2(r * 0.7, r * 0.2)), Color("e9e6df"))
			ci.draw_line(c + Vector2(-r * 0.1, r * 0.62), c + Vector2(-r * 0.08, r * 0.05), bronze, w * 1.4)
			ci.draw_line(c + Vector2(r * 0.1, r * 0.62), c + Vector2(r * 0.08, r * 0.05), bronze, w * 1.4)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.2, -r * 0.4), Vector2(r * 0.4, r * 0.48)), bronze)
			ci.draw_circle(c + Vector2(0, -r * 0.55), r * 0.14, bronze)
			ci.draw_line(c + Vector2(r * 0.2, -r * 0.35), c + Vector2(r * 0.45, -r * 0.85), bronze, w * 1.2)
			ci.draw_circle(c + Vector2(r * 0.47, -r * 0.92), r * 0.09, Color("ff9a1f"))
			for a in 5:
				var ang := -PI * 0.5 + (a - 2) * 0.45
				ci.draw_line(c + Vector2(0, -r * 0.55) + Vector2(cos(ang), sin(ang)) * r * 0.16,
					c + Vector2(0, -r * 0.55) + Vector2(cos(ang), sin(ang)) * r * 0.3, Color("f2c53d"), w * 0.6)
		&"lighthouse":
			var stone := Color("f0ede4")
			ci.draw_rect(Rect2(c + Vector2(-r * 0.4, 0), Vector2(r * 0.8, r * 0.7)), stone)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.27, -r * 0.45), Vector2(r * 0.54, r * 0.45)), stone)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.16, -r * 0.72), Vector2(r * 0.32, r * 0.27)), stone)
			for rect: Rect2 in [Rect2(c + Vector2(-r * 0.4, 0), Vector2(r * 0.8, r * 0.7)),
					Rect2(c + Vector2(-r * 0.27, -r * 0.45), Vector2(r * 0.54, r * 0.45)),
					Rect2(c + Vector2(-r * 0.16, -r * 0.72), Vector2(r * 0.32, r * 0.27))]:
				ci.draw_rect(rect, ink, false, w * 0.5)
			ci.draw_circle(c + Vector2(0, -r * 0.84), r * 0.13, Color("ff9a1f"))
			ci.draw_line(c + Vector2(-r * 0.95, r * 0.75), c + Vector2(r * 0.95, r * 0.75), Color("2f7fb0"), w)
		&"great_wall", &"petra", &"colosseum", &"chichen_itza", &"machu_picchu", &"taj_mahal", &"christ_redeemer":
			_new_seven(ci, id, c, r, ink, w)
		&"grand_canyon", &"barrier_reef", &"rio_harbour", &"everest", &"northern_lights", &"paricutin", &"victoria_falls":
			_nature(ci, id, c, r, ink, w)
		_:
			ci.draw_circle(c, r * 0.5, ink)


## The Seven Natural Wonders' shapes: the canyon's layered walls over its river, the reef's corals and a fish in blue
## water, the Sugarloaf rising from the bay with its cable car's line, Everest's snowy peak with a flag, the northern
## lights' green curtains over a pine, Parícutin's cone glowing over its corn, Victoria Falls' water pouring down with
## its spray and a rainbow.
static func _nature(ci: CanvasItem, id: StringName, c: Vector2, r: float, ink: Color, w: float) -> void:
	var at := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * r
	match id:
		&"grand_canyon":
			var bands: Array[Color] = [Color("d9cfb2"), Color("e4d0a2"), Color("b5533a"), Color("a6785f"), Color("6f7a67")]
			for i in bands.size():
				var y := -0.6 + i * 0.25
				var gap := 0.15 + i * 0.12
				ci.draw_rect(Rect2(at.call(-0.95, y), Vector2(r * (0.95 - gap), r * 0.25)), bands[i])
				ci.draw_rect(Rect2(at.call(gap, y), Vector2(r * (0.95 - gap), r * 0.25)), bands[i])
			ci.draw_line(at.call(-0.12, 0.62), at.call(0.12, 0.62), Color("2f6fd0"), w * 1.2)
		&"barrier_reef":
			ci.draw_rect(Rect2(at.call(-0.9, -0.7), Vector2(r * 1.8, r * 1.4)), Color("4fb8d8"))
			ci.draw_circle(at.call(-0.45, 0.45), r * 0.25, Color("c9c050"))
			for a in 4:
				var base: Vector2 = at.call(0.35, 0.65)
				ci.draw_line(base, base + Vector2(cos(-PI * 0.5 + (a - 1.5) * 0.4), sin(-PI * 0.5 + (a - 1.5) * 0.4)) * r * 0.5,
					Color("ef8fb0"), w)
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.3, -0.25), at.call(0.15, -0.4), at.call(0.15, -0.1)]),
				Color("ff9a1f"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.15, -0.25), at.call(0.35, -0.4), at.call(0.35, -0.1)]),
				Color("ff9a1f"))
		&"rio_harbour":
			ci.draw_rect(Rect2(at.call(-0.95, 0.35), Vector2(r * 1.9, r * 0.4)), Color("3f8fd8"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.05, 0.4), at.call(0.15, -0.35), at.call(0.35, -0.6),
				at.call(0.6, -0.35), at.call(0.75, 0.4)]), Color("8a8072"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.6, 0.4), at.call(-0.35, -0.05), at.call(-0.05, 0.4)]),
				Color("6f8a5a"))
			ci.draw_line(at.call(-0.35, -0.05), at.call(0.35, -0.6), ink, w * 0.3)
			ci.draw_rect(Rect2(at.call(-0.02, -0.38), Vector2(r * 0.12, r * 0.09)), Color("e1b12c"))
		&"everest":
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.95, 0.65), at.call(0, -0.75), at.call(0.95, 0.65)]),
				Color("7a7f88"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.35, -0.25), at.call(0, -0.75), at.call(0.35, -0.25),
				at.call(0.12, -0.32), at.call(-0.1, -0.22)]), Color("f4f6fa"))
			ci.draw_line(at.call(0, -0.75), at.call(0, -0.95), ink, w * 0.4)
			for i in 3:
				ci.draw_rect(Rect2(at.call(0.02 + i * 0.1, -0.95), Vector2(r * 0.09, r * 0.1)),
					[Color("2f6fd0"), Color("d03a30"), Color("f0d030")][i])
		&"northern_lights":
			ci.draw_circle(c, r * 0.95, Color("12203a"))
			for k in 3:
				var pts := PackedVector2Array()
				for i in 9:
					var x := -0.85 + i * 0.21
					pts.append(at.call(x, -0.35 + k * 0.18 + sin(i * 0.9 + k) * 0.12))
				ci.draw_polyline(pts, Color(0.4, 1.0, 0.6, 0.9 - k * 0.2), w * (1.4 - k * 0.3))
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.2, 0.75), at.call(0, 0.15), at.call(0.2, 0.75)]),
				Color("1f5a32"))
		&"paricutin":
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.85, 0.6), at.call(-0.25, -0.35), at.call(0.25, -0.35),
				at.call(0.85, 0.6)]), Color("3a2622"))
			ci.draw_line(at.call(-0.2, -0.35), at.call(0.2, -0.35), Color("ff7a1f"), w * 0.8)
			for i in 3:
				ci.draw_circle(at.call(-0.15 + i * 0.15, -0.55 - i * 0.12), r * (0.1 + i * 0.03), Color(0.75, 0.75, 0.78, 0.8))
			for x: float in [-0.9, -0.75, 0.75, 0.9]:
				ci.draw_line(at.call(x, 0.75), at.call(x, 0.4), Color("5aa040"), w * 0.6)
				ci.draw_circle(at.call(x, 0.5), r * 0.04, Color("e8c840"))
		&"victoria_falls":
			ci.draw_rect(Rect2(at.call(-0.9, -0.5), Vector2(r * 1.8, r * 0.25)), Color("3f8f3a"))
			for i in 7:
				var x := -0.75 + i * 0.25
				ci.draw_line(at.call(x, -0.25), at.call(x, 0.55), Color("bfe0ff") if i % 2 else Color("6fb0f0"), w * 0.9)
			ci.draw_rect(Rect2(at.call(-0.9, 0.5), Vector2(r * 1.8, r * 0.25)), Color(1, 1, 1, 0.85))
			for b in 3:
				ci.draw_arc(at.call(0, 0.55), r * (0.55 - b * 0.08), PI, TAU, 18,
					[Color("ff4040"), Color("ffe640"), Color("40a0ff")][b], w * 0.35)


## The New Seven's shapes.
static func _new_seven(ci: CanvasItem, id: StringName, c: Vector2, r: float, ink: Color, w: float) -> void:
	var at := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * r
	match id:
		&"great_wall":
			ci.draw_colored_polygon(PackedVector2Array([at.call(-1, 0.7), at.call(-0.5, 0.05), at.call(0, 0.4),
				at.call(0.5, -0.1), at.call(1, 0.7)]), Color("7fb069"))
			var line := PackedVector2Array([at.call(-0.95, 0.35), at.call(-0.5, -0.05), at.call(0, 0.25), at.call(0.5, -0.25),
				at.call(0.95, 0.2)])
			ci.draw_polyline(line, Color("8f9296"), w * 1.6)
			for i in line.size() - 1:
				var p: Vector2 = (line[i] as Vector2).lerp(line[i + 1], 0.5)
				ci.draw_rect(Rect2(p + Vector2(-r * 0.05, -r * 0.16), Vector2(r * 0.1, r * 0.08)), Color("8f9296"))
			ci.draw_rect(Rect2(at.call(0.4, -0.55), Vector2(r * 0.22, r * 0.34)), Color("8f9296"))
			ci.draw_rect(Rect2(at.call(0.4, -0.55), Vector2(r * 0.22, r * 0.34)), ink, false, w * 0.4)
		&"petra":
			ci.draw_rect(Rect2(at.call(-0.8, -0.85), Vector2(r * 1.6, r * 1.55)), Color("d48d78"))
			for i in 6:
				var x := -0.55 + i * 0.22
				ci.draw_line(at.call(x, 0.7), at.call(x, 0.15), Color("9c4f47"), w * 0.6)
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.45, 0.12), at.call(0.45, 0.12), at.call(0, -0.1)]),
				Color("9c4f47"))
			ci.draw_rect(Rect2(at.call(-0.16, -0.5), Vector2(r * 0.32, r * 0.34)), Color("9c4f47"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.2, -0.5), at.call(0.2, -0.5), at.call(0, -0.66)]),
				Color("9c4f47"))
			ci.draw_circle(at.call(0, -0.72), r * 0.07, Color("9c4f47"))
		&"colosseum":
			ci.draw_rect(Rect2(at.call(-0.9, -0.5), Vector2(r * 1.8, r * 1.15)), Color("e6d9bc"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.35, -0.52), at.call(0.92, -0.52), at.call(0.92, 0.0),
				at.call(0.35, -0.2)]), Color(1, 0.98, 0.92, 0.9))   # the broken side
			for row in 3:
				for i in 7:
					var x := -0.8 + i * 0.24
					var y := 0.35 - row * 0.3
					if row == 2 and x > 0.3:
						continue
					ci.draw_rect(Rect2(at.call(x, y - 0.18), Vector2(r * 0.12, r * 0.18)), ink)
		&"chichen_itza":
			for i in 5:
				var hw := 0.95 - i * 0.16
				var y := 0.6 - i * 0.2
				ci.draw_rect(Rect2(at.call(-hw, y - 0.2), Vector2(r * hw * 2, r * 0.2)), Color("cfc9bd"))
				ci.draw_rect(Rect2(at.call(-hw, y - 0.2), Vector2(r * hw * 2, r * 0.2)), ink, false, w * 0.3)
			ci.draw_rect(Rect2(at.call(-0.14, -0.4), Vector2(r * 0.28, r * 1.0)), Color("a39d91"))
			ci.draw_rect(Rect2(at.call(-0.26, -0.66), Vector2(r * 0.52, r * 0.26)), Color("cfc9bd"))
			ci.draw_rect(Rect2(at.call(-0.26, -0.66), Vector2(r * 0.52, r * 0.26)), ink, false, w * 0.4)
		&"machu_picchu":
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.1, 0.3), at.call(0.35, -0.9), at.call(0.8, 0.3)]),
				Color("2f7a3a"))
			for i in 4:
				var y := 0.7 - i * 0.14
				ci.draw_rect(Rect2(at.call(-0.95 + i * 0.1, y - 0.1), Vector2(r * (1.9 - i * 0.2), r * 0.1)), Color("7fb069"))
				ci.draw_line(at.call(-0.95 + i * 0.1, y), at.call(0.95 - i * 0.1, y), Color("8f8e88"), w * 0.4)
			for x: float in [-0.5, -0.2, 0.1]:
				ci.draw_rect(Rect2(at.call(x, 0.02), Vector2(r * 0.18, r * 0.14)), Color("9d9c96"))
				ci.draw_colored_polygon(PackedVector2Array([at.call(x - 0.02, 0.02), at.call(x + 0.2, 0.02),
					at.call(x + 0.09, -0.1)]), Color("c9a14a"))
		&"taj_mahal":
			var white := Color("f4f2ec")
			ci.draw_rect(Rect2(at.call(-0.55, 0.05), Vector2(r * 1.1, r * 0.6)), white)
			ci.draw_rect(Rect2(at.call(-0.55, 0.05), Vector2(r * 1.1, r * 0.6)), ink, false, w * 0.4)
			ci.draw_rect(Rect2(at.call(-0.14, 0.25), Vector2(r * 0.28, r * 0.4)), ink)
			ci.draw_circle(at.call(0, -0.2), r * 0.32, white)
			ci.draw_arc(at.call(0, -0.2), r * 0.32, PI, TAU, 16, ink, w * 0.4)
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.12, -0.46), at.call(0.12, -0.46), at.call(0, -0.72)]),
				white)
			ci.draw_line(at.call(0, -0.72), at.call(0, -0.85), Color("e1b12c"), w * 0.6)
			for x: float in [-0.85, 0.75]:
				ci.draw_rect(Rect2(at.call(x, -0.4), Vector2(r * 0.1, r * 1.05)), white)
				ci.draw_rect(Rect2(at.call(x, -0.4), Vector2(r * 0.1, r * 1.05)), ink, false, w * 0.3)
		&"christ_redeemer":
			ci.draw_colored_polygon(PackedVector2Array([at.call(-0.9, 0.75), at.call(0, 0.25), at.call(0.9, 0.75)]),
				Color("3f8f3a"))
			var soap := Color("e0e2d6")
			ci.draw_rect(Rect2(at.call(-0.12, -0.45), Vector2(r * 0.24, r * 0.75)), soap)
			ci.draw_rect(Rect2(at.call(-0.12, -0.45), Vector2(r * 0.24, r * 0.75)), ink, false, w * 0.3)
			ci.draw_rect(Rect2(at.call(-0.75, -0.42), Vector2(r * 1.5, r * 0.12)), soap)
			ci.draw_rect(Rect2(at.call(-0.75, -0.42), Vector2(r * 1.5, r * 0.12)), ink, false, w * 0.3)
			ci.draw_circle(at.call(0, -0.58), r * 0.1, soap)


## A temple front (Artemis), a temple with Zeus inside (Zeus), a podium with columns and a stepped roof (Mausoleum).
static func _temple(ci: CanvasItem, id: StringName, c: Vector2, r: float, ink: Color, w: float) -> void:
	var marble := Color("f1f0ec")
	var base := c.y + r * 0.62
	if id == &"mausoleum":
		ci.draw_rect(Rect2(Vector2(c.x - r * 0.7, base - r * 0.45), Vector2(r * 1.4, r * 0.45)), marble)
		ci.draw_rect(Rect2(Vector2(c.x - r * 0.7, base - r * 0.45), Vector2(r * 1.4, r * 0.45)), ink, false, w * 0.5)
		for i in 5:
			var x := c.x - r * 0.6 + i * r * 0.3
			ci.draw_line(Vector2(x, base - r * 0.45), Vector2(x, base - r * 0.9), ink, w * 0.7)
		for i in 4:
			var hw := r * (0.7 - 0.15 * i)
			var y := base - r * (0.95 + 0.12 * i)
			ci.draw_rect(Rect2(Vector2(c.x - hw, y), Vector2(hw * 2, r * 0.1)), marble)
			ci.draw_rect(Rect2(Vector2(c.x - hw, y), Vector2(hw * 2, r * 0.1)), ink, false, w * 0.4)
		ci.draw_rect(Rect2(Vector2(c.x - r * 0.2, base - r * 1.55), Vector2(r * 0.4, r * 0.12)), ink)
		return
	ci.draw_rect(Rect2(Vector2(c.x - r * 0.85, base - r * 0.12), Vector2(r * 1.7, r * 0.12)), marble)
	ci.draw_rect(Rect2(Vector2(c.x - r * 0.85, base - r * 0.12), Vector2(r * 1.7, r * 0.12)), ink, false, w * 0.5)
	var n := 6 if id == &"artemis" else 4
	for i in n:
		var x := c.x - r * 0.7 + i * r * 1.4 / (n - 1)
		ci.draw_line(Vector2(x, base - r * 0.12), Vector2(x, base - r * 0.9), ink, w * 0.8)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - r * 0.9, base - r * 0.9), Vector2(c.x + r * 0.9, base - r * 0.9),
		Vector2(c.x, base - r * 1.35)]), marble)
	ci.draw_polyline(PackedVector2Array([Vector2(c.x - r * 0.9, base - r * 0.9), Vector2(c.x + r * 0.9, base - r * 0.9),
		Vector2(c.x, base - r * 1.35), Vector2(c.x - r * 0.9, base - r * 0.9)]), ink, w * 0.6)
	if id == &"zeus":   # Zeus on his throne between the columns: gold robe, ivory head
		ci.draw_rect(Rect2(Vector2(c.x - r * 0.18, base - r * 0.6), Vector2(r * 0.36, r * 0.46)), Color("f2c53d"))
		ci.draw_circle(Vector2(c.x, base - r * 0.7), r * 0.11, Color("f4e8cc"))
