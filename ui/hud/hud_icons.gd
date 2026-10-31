class_name HudIcons
extends RefCounted
## The HUD buttons' pictures (M2 Task 17: icon-first buttons with a word under each), drawn in code
## into the button's own canvas item: a few shapes each, no textures and no materials, redrawn only
## when a button changes. `draw` fits a picture into a square.

const INK := Color.WHITE   # opaque: overlapping shapes show no seams
const DARK := Color(0.1, 0.12, 0.2, 0.95)

## Every picture a button may show.
const SYMBOLS: Array[StringName] = [&"jump", &"up", &"down", &"crouch", &"attack", &"walk", &"fly", &"ghost",
	&"moon", &"zero_g", &"slow", &"size", &"camera", &"undo", &"mirror", &"emote", &"photo", &"lab", &"book",
	&"pause", &"chat", &"more", &"sleep", &"wake", &"home", &"heart",
	&"gift", &"glide",   # M4 I: SHARE; M3 Task 14a: glide
	&"ride",   # M3 Task 20a: RIDE
	&"quests",   # owner #45a: the quest book (MORE → QUESTS)
	&"map",   # owner #45b: the world map (MAP)
	&"shop",   # owner #37: MORE → SHOP (Tilly's way, trading)
	&"dig",   # spec §26: MORE → DIG (Gemma's prospecting quests)
	&"invent",   # owner #78: MORE → INVENT (the Inventions book: a kite on its string)
	&"car", &"horn",   # owner #109: MORE → CARS, DRIVE; HORN
	&"table", &"model",   # owner #110: MORE → BUILD TABLE, MODEL VIEW (in a headset only)
	&"discover"]   # owner #132 (W1): MORE → DISCOVER (a magnifying glass, a sparkle in its lens: learning in the world)


static func knows(symbol: StringName) -> bool:
	return SYMBOLS.has(symbol)


## Draws `symbol` into the square `r` of the canvas item `ci` (called from its _draw).
static func draw(ci: CanvasItem, symbol: StringName, r: Rect2, ink: Color = INK) -> void:
	_draw_on(ci, symbol, r, ink)


## P5 (VR draws): the same picture into a CanvasBatch (a headset's HUD: one draw for the whole picture).
static func draw_into(batch: CanvasBatch, symbol: StringName, r: Rect2, ink: Color = INK) -> void:
	_draw_on(batch, symbol, r, ink)


## `ci`: a CanvasItem, or a CanvasBatch (the same draw_* calls).
static func _draw_on(ci: Object, symbol: StringName, r: Rect2, ink: Color) -> void:
	var d := _Pen.new(ci, r, ink)
	match symbol:
		&"jump":
			d.arrow_up(0.5, 0.06, 0.62, 0.32, 0.28)
			d.line(0.14, 0.9, 0.86, 0.9, 1.3)
		&"up":
			d.arrow_up(0.5, 0.06, 0.84, 0.42, 0.34)
		&"down":
			d.arrow_down(0.5, 0.94, 0.16, 0.42, 0.34)
		&"crouch":
			d.disc(0.64, 0.24, 0.13)
			d.poly([0.6, 0.4, 0.34, 0.62, 0.66, 0.66, 0.5, 0.88], 1.6)
			d.line(0.52, 0.48, 0.78, 0.56, 1.3)
			d.line(0.12, 0.94, 0.88, 0.94, 1.0)
		&"attack":
			_sword(d)
		&"walk":
			d.oval(0.34, 0.62, 0.12, 0.2, -0.25)
			d.oval(0.66, 0.36, 0.12, 0.2, 0.25)
			for p: Vector2 in [Vector2(0.24, 0.36), Vector2(0.34, 0.33), Vector2(0.44, 0.36),
					Vector2(0.56, 0.1), Vector2(0.66, 0.07), Vector2(0.76, 0.1)]:
				d.disc(p.x, p.y, 0.045)
		&"fly":
			d.fill([0.08, 0.66, 0.36, 0.3, 0.92, 0.14, 0.72, 0.4, 0.9, 0.42, 0.66, 0.58, 0.8, 0.62, 0.42, 0.76])
		&"ghost":
			d.disc(0.5, 0.42, 0.3)
			d.box(0.2, 0.42, 0.8, 0.78)
			for x: float in [0.3, 0.5, 0.7]:
				d.disc(x, 0.78, 0.1)
			d.disc(0.4, 0.42, 0.065, DARK)
			d.disc(0.6, 0.42, 0.065, DARK)
		&"moon":
			d.crescent(0.5, 0.5, 0.4)
		&"zero_g":
			d.disc(0.5, 0.5, 0.2)
			d.ring_tilted(0.5, 0.5, 0.44, 0.15, -0.4)
			d.disc(0.14, 0.18, 0.04)
			d.disc(0.86, 0.84, 0.04)
		&"slow":
			d.ring(0.58, 0.46, 0.25, 1.2)
			d.ring(0.58, 0.46, 0.11, 1.0)
			d.line(0.12, 0.76, 0.9, 0.76, 1.8)
			d.line(0.16, 0.76, 0.12, 0.5, 1.2)
			d.disc(0.12, 0.46, 0.05)
		&"size":
			d.box(0.08, 0.56, 0.36, 0.84)
			d.box(0.44, 0.16, 0.92, 0.84)
		&"camera":
			d.arc(0.5, 0.8, 0.5, 216.9, 323.1, 1.2)   # the lids: arcs through the corners (0.1 and 0.9)
			d.arc(0.5, 0.2, 0.5, 36.9, 143.1, 1.2)
			d.disc(0.5, 0.5, 0.14)
			d.disc(0.5, 0.5, 0.065, DARK)
		&"undo":
			d.arc(0.56, 0.56, 0.28, -90.0, 90.0, 1.4)
			d.line(0.56, 0.28, 0.3, 0.28, 1.4)
			d.line(0.56, 0.84, 0.32, 0.84, 1.4)
			d.fill([0.08, 0.28, 0.32, 0.1, 0.32, 0.46])
		&"mirror":
			d.fill([0.42, 0.2, 0.42, 0.8, 0.08, 0.8])
			d.fill([0.58, 0.2, 0.58, 0.8, 0.92, 0.8], Color(ink, ink.a * 0.5))
			for y: float in [0.06, 0.3, 0.54, 0.78]:
				d.line(0.5, y, 0.5, y + 0.14, 0.8)
		&"emote":
			d.disc(0.5, 0.2, 0.12)
			d.line(0.5, 0.32, 0.5, 0.64, 1.4)
			d.poly([0.2, 0.2, 0.34, 0.46, 0.5, 0.4, 0.66, 0.46, 0.8, 0.2], 1.3)
			d.poly([0.3, 0.92, 0.5, 0.64, 0.7, 0.92], 1.4)
		&"photo":
			d.box(0.28, 0.2, 0.46, 0.32)
			d.box(0.1, 0.3, 0.9, 0.8)
			d.disc(0.5, 0.55, 0.19, DARK)
			d.disc(0.5, 0.55, 0.11, Color(0.45, 0.7, 1.0))
		&"lab":
			d.fill([0.26, 0.6, 0.74, 0.6, 0.88, 0.9, 0.12, 0.9], Color(ink, ink.a * 0.6))
			d.poly([0.4, 0.08, 0.4, 0.38, 0.12, 0.9, 0.88, 0.9, 0.6, 0.38, 0.6, 0.08], 1.2)
			d.line(0.34, 0.08, 0.66, 0.08, 1.2)
			d.disc(0.46, 0.72, 0.05, DARK)
			d.disc(0.6, 0.8, 0.035, DARK)
		&"book":
			d.fill([0.08, 0.18, 0.47, 0.26, 0.47, 0.88, 0.08, 0.8])
			d.fill([0.53, 0.26, 0.92, 0.18, 0.92, 0.8, 0.53, 0.88])
			for y: float in [0.4, 0.54, 0.68]:
				d.line(0.16, y - 0.02, 0.4, y + 0.02, 0.7, DARK)
				d.line(0.6, y + 0.02, 0.84, y - 0.02, 0.7, DARK)
		&"pause":
			d.box(0.24, 0.16, 0.42, 0.84)
			d.box(0.58, 0.16, 0.76, 0.84)
		&"chat":
			d.box(0.08, 0.14, 0.92, 0.66)
			d.fill([0.26, 0.64, 0.48, 0.64, 0.22, 0.9])
			for x: float in [0.3, 0.5, 0.7]:
				d.disc(x, 0.4, 0.065, DARK)
		&"more":
			for x: float in [0.2, 0.5, 0.8]:
				d.disc(x, 0.5, 0.11)
		&"sleep":
			d.crescent(0.42, 0.56, 0.36)
			d.poly([0.66, 0.08, 0.9, 0.08, 0.66, 0.32, 0.9, 0.32], 1.0)
		&"wake":
			d.disc(0.5, 0.5, 0.2)
			for i in 8:
				var a := TAU * i / 8.0
				d.line(0.5 + cos(a) * 0.3, 0.5 + sin(a) * 0.3, 0.5 + cos(a) * 0.44, 0.5 + sin(a) * 0.44, 1.2)
		&"home":
			d.fill([0.5, 0.08, 0.94, 0.48, 0.06, 0.48])
			d.box(0.18, 0.46, 0.82, 0.92)
			d.box(0.42, 0.62, 0.58, 0.92, DARK)
		&"heart":
			d.disc(0.33, 0.38, 0.19)
			d.disc(0.67, 0.38, 0.19)
			d.fill([0.15, 0.46, 0.85, 0.46, 0.5, 0.9])
		&"ride":   # M3 Task 20a: a saddle with its stirrup (RIDE)
			d.fill([0.08, 0.34, 0.24, 0.3, 0.4, 0.44, 0.62, 0.44, 0.78, 0.22, 0.94, 0.26, 0.9, 0.52, 0.72, 0.64,
				0.3, 0.64, 0.12, 0.54])
			d.disc(0.86, 0.22, 0.08)
			d.line(0.5, 0.64, 0.5, 0.78, 0.9)
			d.ring(0.5, 0.86, 0.09, 0.9)
		&"gift":   # M4 I: a present with a bow (SHARE)
			d.box(0.12, 0.42, 0.88, 0.92)
			d.box(0.06, 0.3, 0.94, 0.44)
			d.box(0.44, 0.3, 0.56, 0.92, DARK)
			d.fill([0.5, 0.3, 0.2, 0.08, 0.26, 0.3])
			d.fill([0.5, 0.3, 0.8, 0.08, 0.74, 0.3])
		&"quests":   # owner #45a: a story scroll with a "!" (the quest book)
			d.box(0.2, 0.14, 0.8, 0.86)
			d.disc(0.2, 0.14, 0.1)
			d.disc(0.8, 0.86, 0.1)
			d.box(0.44, 0.26, 0.56, 0.6, DARK)
			d.disc(0.5, 0.72, 0.07, DARK)
		&"dig":   # spec §26: a prospector's pick over a nugget (DIG)
			d.line(0.2, 0.9, 0.62, 0.34, 1.4)
			d.fill([0.3, 0.2, 0.62, 0.2, 0.9, 0.44, 0.66, 0.3, 0.56, 0.3])
			d.fill([0.56, 0.2, 0.72, 0.18, 0.78, 0.3, 0.62, 0.36])
			d.disc(0.78, 0.8, 0.12)
			d.disc(0.74, 0.76, 0.04, DARK)
		&"invent":   # owner #78: a kite on its string with a bowed tail (INVENT)
			d.fill([0.62, 0.06, 0.9, 0.34, 0.62, 0.62, 0.34, 0.34])
			d.line(0.62, 0.1, 0.62, 0.58, 0.8, DARK)
			d.line(0.38, 0.34, 0.86, 0.34, 0.8, DARK)
			d.line(0.62, 0.62, 0.5, 0.76, 0.9)
			d.line(0.5, 0.76, 0.56, 0.9, 0.9)
			d.fill([0.5, 0.76, 0.42, 0.71, 0.42, 0.81])
			d.fill([0.5, 0.76, 0.58, 0.81, 0.58, 0.71])
			d.line(0.34, 0.34, 0.08, 0.94, 0.7)
		&"map":   # owner #45b: a folded map with a path to an X (MAP)
			d.fill([0.06, 0.2, 0.36, 0.1, 0.36, 0.82, 0.06, 0.92])
			d.fill([0.38, 0.1, 0.62, 0.2, 0.62, 0.92, 0.38, 0.82])
			d.fill([0.64, 0.2, 0.94, 0.1, 0.94, 0.82, 0.64, 0.92])
			d.line(0.16, 0.74, 0.3, 0.6, 0.6, DARK)
			d.line(0.44, 0.56, 0.56, 0.46, 0.6, DARK)
			d.line(0.72, 0.28, 0.86, 0.42, 0.9, DARK)
			d.line(0.86, 0.28, 0.72, 0.42, 0.9, DARK)
		&"shop":   # owner #37: a stall's striped awning over a counter with a coin on it (SHOP)
			d.fill([0.08, 0.36, 0.2, 0.12, 0.8, 0.12, 0.92, 0.36])
			d.box(0.3, 0.14, 0.42, 0.36, DARK)
			d.box(0.58, 0.14, 0.7, 0.36, DARK)
			d.box(0.14, 0.36, 0.2, 0.9)
			d.box(0.8, 0.36, 0.86, 0.9)
			d.box(0.08, 0.66, 0.92, 0.9)
			d.disc(0.5, 0.52, 0.12)
			d.disc(0.5, 0.52, 0.06, DARK)
		&"glide":   # M3 Task 14a: a wide wing over a little flyer holding its bar
			d.fill([0.02, 0.5, 0.5, 0.12, 0.98, 0.5, 0.5, 0.34])
			d.line(0.3, 0.44, 0.42, 0.7, 0.8)
			d.line(0.7, 0.44, 0.58, 0.7, 0.8)
			d.line(0.34, 0.7, 0.66, 0.7, 1.1)
			d.disc(0.5, 0.82, 0.1)
		&"car":   # owner #109: a little car from the side, its cabin's window dark, two wheels
			d.box(0.06, 0.46, 0.94, 0.72)
			d.fill([0.24, 0.46, 0.34, 0.24, 0.68, 0.24, 0.8, 0.46])
			d.fill([0.33, 0.44, 0.39, 0.3, 0.52, 0.3, 0.52, 0.44], DARK)
			d.fill([0.57, 0.44, 0.57, 0.3, 0.66, 0.3, 0.72, 0.44], DARK)
			d.disc(0.27, 0.74, 0.12)
			d.disc(0.73, 0.74, 0.12)
			d.disc(0.27, 0.74, 0.05, DARK)
			d.disc(0.73, 0.74, 0.05, DARK)
		&"horn":   # owner #109: a horn's bell, its sound coming out in two arcs
			d.fill([0.08, 0.42, 0.3, 0.42, 0.62, 0.16, 0.62, 0.84, 0.3, 0.58, 0.08, 0.58])
			d.box(0.02, 0.38, 0.1, 0.62)
			d.line(0.74, 0.32, 0.8, 0.5, 0.8)
			d.line(0.8, 0.5, 0.74, 0.68, 0.8)
			d.line(0.86, 0.2, 0.96, 0.5, 0.8)
			d.line(0.96, 0.5, 0.86, 0.8, 0.8)
		&"table":   # owner #110: a table top on two legs, two little blocks on it (BUILD TABLE)
			d.box(0.06, 0.52, 0.94, 0.62)
			d.box(0.14, 0.62, 0.22, 0.92)
			d.box(0.78, 0.62, 0.86, 0.92)
			d.box(0.3, 0.3, 0.5, 0.5)
			d.box(0.54, 0.38, 0.68, 0.5)
			d.line(0.3, 0.3, 0.5, 0.3, 0.6, DARK)
		&"discover":   # owner #132 (W1): a magnifying glass with a four-pointed sparkle in its lens (DISCOVER)
			d.ring(0.42, 0.42, 0.29, 1.5)
			d.line(0.63, 0.63, 0.9, 0.9, 2.4)
			d.fill([0.42, 0.24, 0.47, 0.37, 0.6, 0.42, 0.47, 0.47, 0.42, 0.6, 0.37, 0.47, 0.24, 0.42, 0.37, 0.37])
		&"model":   # owner #110: the world as a model on a plate: a hill, a house, a tree (MODEL VIEW)
			d.box(0.04, 0.74, 0.96, 0.84)
			d.fill([0.08, 0.74, 0.34, 0.42, 0.6, 0.74])
			d.box(0.56, 0.52, 0.8, 0.74)
			d.fill([0.52, 0.53, 0.68, 0.36, 0.84, 0.53])
			d.box(0.63, 0.6, 0.71, 0.74, DARK)
			d.disc(0.88, 0.5, 0.08)
			d.box(0.86, 0.56, 0.9, 0.74)


## A sword pointing up-right: blade, cross-guard, grip and pommel.
static func _sword(d: _Pen) -> void:
	var tip := Vector2(0.86, 0.14)
	var base := Vector2(0.36, 0.64)
	var along := (tip - base).normalized()
	var side := Vector2(along.y, -along.x)
	var hw := 0.07
	var neck := tip - along * 0.1
	d.fill_points([base + side * hw, neck + side * hw, tip, neck - side * hw, base - side * hw])
	d.line_points(base + side * 0.17, base - side * 0.17, 1.5)
	var grip := base - along * 0.2
	d.line_points(base, grip, 1.6)
	d.disc(grip.x - along.x * 0.03, grip.y - along.y * 0.03, 0.06)


## Draws in a square's own units (0..1 across), so every picture scales with its button.
class _Pen:
	var ci: Object   # a CanvasItem, or a CanvasBatch (P5: a headset's HUD)
	var r: Rect2
	var ink: Color
	var w: float

	func _init(canvas: Object, square: Rect2, color: Color) -> void:
		ci = canvas
		r = square
		ink = color
		w = maxf(2.0, r.size.x * 0.07)

	func at(x: float, y: float) -> Vector2:
		return r.position + Vector2(x, y) * r.size

	func _pts(xy: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for i in range(0, xy.size(), 2):
			out.append(at(xy[i], xy[i + 1]))
		return out

	func line(x0: float, y0: float, x1: float, y1: float, width := 1.0, color := Color(0, 0, 0, 0)) -> void:
		ci.draw_line(at(x0, y0), at(x1, y1), ink if color.a == 0.0 else color, w * width, true)

	func line_points(a: Vector2, b: Vector2, width := 1.0) -> void:
		line(a.x, a.y, b.x, b.y, width)

	func poly(xy: Array, width := 1.0) -> void:
		ci.draw_polyline(_pts(xy), ink, w * width, true)

	func fill(xy: Array, color := Color(0, 0, 0, 0)) -> void:
		ci.draw_colored_polygon(_pts(xy), ink if color.a == 0.0 else color)

	func fill_points(points: Array) -> void:
		var xy: Array = []
		for p: Vector2 in points:
			xy.append_array([p.x, p.y])
		fill(xy)

	func disc(x: float, y: float, radius: float, color := Color(0, 0, 0, 0)) -> void:
		ci.draw_circle(at(x, y), radius * r.size.x, ink if color.a == 0.0 else color)

	func box(x0: float, y0: float, x1: float, y1: float, color := Color(0, 0, 0, 0)) -> void:
		ci.draw_rect(Rect2(at(x0, y0), Vector2(x1 - x0, y1 - y0) * r.size), ink if color.a == 0.0 else color)

	func ring(x: float, y: float, radius: float, width := 1.0) -> void:
		ci.draw_arc(at(x, y), radius * r.size.x, 0.0, TAU, 32, ink, w * width, true)

	func arc(x: float, y: float, radius: float, from_deg: float, to_deg: float, width := 1.0) -> void:
		ci.draw_arc(at(x, y), radius * r.size.x, deg_to_rad(from_deg), deg_to_rad(to_deg), 24, ink, w * width, true)

	func oval(x: float, y: float, rx: float, ry: float, angle: float) -> void:
		ci.draw_set_transform(at(x, y), angle, Vector2(rx / ry, 1.0))
		ci.draw_circle(Vector2.ZERO, ry * r.size.x, ink)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func ring_tilted(x: float, y: float, rx: float, ry: float, angle: float) -> void:
		ci.draw_set_transform(at(x, y), angle, Vector2(1.0, ry / rx))
		ci.draw_arc(Vector2.ZERO, rx * r.size.x, 0.0, TAU, 32, ink, w * 0.9, true)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## An arrow pointing up from its tip: head `head` deep and `width` wide, a shaft half as wide.
	func arrow_up(x: float, tip: float, bottom: float, head: float, width: float) -> void:
		fill([x, tip, x + width, tip + head, x - width, tip + head])
		box(x - width * 0.45, tip + head - 0.01, x + width * 0.45, bottom)

	func arrow_down(x: float, tip: float, top: float, head: float, width: float) -> void:
		fill([x, tip, x - width, tip - head, x + width, tip - head])
		box(x - width * 0.45, top, x + width * 0.45, tip - head + 0.01)

	## A crescent moon: a disc of radius `radius` with a smaller disc bitten out of its upper right.
	func crescent(x: float, y: float, radius: float) -> void:
		var r1 := radius
		var r2 := radius * 0.82
		var off := radius * 0.56
		var ix := (off * off + r1 * r1 - r2 * r2) / (2.0 * off)   # where the two circles cross
		var iy := sqrt(maxf(r1 * r1 - ix * ix, 0.0))
		var outer_from := atan2(iy, ix)
		var inner_from := atan2(-iy, ix - off)
		var inner_to := atan2(iy, ix - off)
		if inner_from < inner_to:
			inner_from += TAU
		var tilt := -0.6
		var xy: Array = []
		for i in 17:   # the outer edge, round the back of the moon
			var a := lerpf(outer_from, TAU - outer_from, i / 16.0)
			xy.append_array(_turned(Vector2(cos(a), sin(a)) * r1, tilt, x, y))
		for i in range(1, 16):   # the inner edge, back along the bite (its ends are the outer edge's)
			var a := lerpf(inner_from, inner_to, i / 16.0)
			xy.append_array(_turned(Vector2(off, 0) + Vector2(cos(a), sin(a)) * r2, tilt, x, y))
		fill(xy)

	func _turned(p: Vector2, angle: float, x: float, y: float) -> Array:
		var q := p.rotated(angle)
		return [x + q.x, y + q.y]
