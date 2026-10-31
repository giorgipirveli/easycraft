class_name ProspectPictures
extends RefCounted
## Prospecting's pictures (spec §26), drawn in code like the world map's (WorldMapPanel.draw_picture): a picture for each
## kind of deposit, on Gemma's quest cards and on MY MAP (the marks' kinds are "deposit_<kind>"). A few shapes each, no
## textures.

const PREFIX := "deposit_"


## The MY MAP kind of a deposit kind (&"deposit_gold").
static func map_kind(kind: StringName) -> StringName:
	return StringName(PREFIX + String(kind))


## True for the MY MAP kinds these pictures draw.
static func knows(kind: StringName) -> bool:
	var k := String(kind)
	return k.begins_with(PREFIX) and DepositKinds.is_kind(StringName(k.trim_prefix(PREFIX)))


## Draws `kind` (a deposit kind, or its MY MAP kind) in the square `r` of `ci`; false when it is not one of these.
static func draw(ci: CanvasItem, kind: StringName, r: Rect2) -> bool:
	var k := StringName(String(kind).trim_prefix(PREFIX))
	if not DepositKinds.is_kind(k):
		return false
	var pic := StringName(DepositKinds.data(k).get("picture", k))   # spec §26.5: both meteorites share one
	var at := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var poly := func(pts: Array, col: Color) -> void:
		var out := PackedVector2Array()
		for i in range(0, pts.size(), 2):
			out.append(at.call(pts[i], pts[i + 1]))
		ci.draw_colored_polygon(out, col)
	var disc := func(x: float, y: float, rad: float, col: Color) -> void:
		ci.draw_circle(at.call(x, y), rad * r.size.x, col)
	var line := func(x0: float, y0: float, x1: float, y1: float, w: float, col: Color) -> void:
		ci.draw_line(at.call(x0, y0), at.call(x1, y1), col, w * r.size.x)
	match pic:
		&"gold":   # a gold nugget with a shine, in a pan
			poly.call([0.06, 0.62, 0.94, 0.62, 0.8, 0.86, 0.2, 0.86], Color("8a8f98"))
			poly.call([0.26, 0.6, 0.34, 0.36, 0.54, 0.26, 0.72, 0.38, 0.76, 0.6], Color("f5c542"))
			poly.call([0.38, 0.4, 0.5, 0.32, 0.56, 0.4], Color("fff0a8"))
			disc.call(0.2, 0.52, 0.035, Color("f5c542"))
			disc.call(0.84, 0.54, 0.03, Color("f5c542"))
		&"copper":   # green-stained rock and a copper bar
			poly.call([0.08, 0.7, 0.2, 0.34, 0.5, 0.22, 0.66, 0.4, 0.6, 0.7], Color("8a8c8e"))
			disc.call(0.3, 0.46, 0.08, Color("2f9a5c"))
			disc.call(0.46, 0.36, 0.06, Color("5fcf8a"))
			poly.call([0.46, 0.8, 0.56, 0.62, 0.94, 0.62, 0.86, 0.8], Color("d9803a"))
			poly.call([0.56, 0.62, 0.62, 0.54, 0.98, 0.54, 0.94, 0.62], Color("f4a867"))
		&"iron":   # striped red rock and a compass needle turned to it
			poly.call([0.1, 0.82, 0.14, 0.4, 0.46, 0.3, 0.6, 0.5, 0.56, 0.82], Color("a63a28"))
			line.call(0.14, 0.52, 0.56, 0.5, 0.05, Color("8d9098"))
			line.call(0.13, 0.68, 0.57, 0.66, 0.05, Color("3b3c44"))
			disc.call(0.76, 0.34, 0.17, Color("f3e2b8"))
			line.call(0.76, 0.34, 0.62, 0.42, 0.05, Color("d9302a"))
			line.call(0.76, 0.34, 0.88, 0.27, 0.04, Color("5a3d1e"))
		&"coal":   # a black lump with a fern print beside it
			poly.call([0.14, 0.78, 0.2, 0.44, 0.44, 0.34, 0.62, 0.5, 0.58, 0.8], Color("25262b"))
			poly.call([0.26, 0.5, 0.36, 0.42, 0.4, 0.5], Color("5a5d66"))
			line.call(0.78, 0.84, 0.78, 0.24, 0.03, Color("2e7d32"))
			for i in 4:
				var y := 0.3 + i * 0.13
				line.call(0.78, y, 0.66, y - 0.07, 0.025, Color("2e7d32"))
				line.call(0.78, y, 0.9, y - 0.07, 0.025, Color("2e7d32"))
		&"oil":   # a derrick over a drop of oil
			line.call(0.3, 0.86, 0.46, 0.1, 0.035, Color("8d9098"))
			line.call(0.62, 0.86, 0.46, 0.1, 0.035, Color("8d9098"))
			line.call(0.34, 0.66, 0.58, 0.66, 0.03, Color("8d9098"))
			line.call(0.38, 0.46, 0.54, 0.46, 0.03, Color("8d9098"))
			line.call(0.34, 0.66, 0.54, 0.46, 0.025, Color("8d9098"))
			poly.call([0.78, 0.5, 0.88, 0.7, 0.78, 0.84, 0.68, 0.7], Color("1c1714"))
			disc.call(0.78, 0.72, 0.1, Color("1c1714"))
			disc.call(0.75, 0.68, 0.025, Color("6b5a4a"))
		&"salt":   # white salt cubes on a crust
			poly.call([0.04, 0.8, 0.96, 0.8, 0.9, 0.9, 0.1, 0.9], Color("d9d3c8"))
			for c: Array in [[0.18, 0.5, 0.2], [0.44, 0.38, 0.26], [0.72, 0.52, 0.18]]:
				var x: float = c[0]
				var y: float = c[1]
				var s: float = c[2]
				poly.call([x, y, x + s, y, x + s, y + s, x, y + s], Color("f7f4f4"))
				poly.call([x, y, x + s * 0.3, y - s * 0.3, x + s * 1.3, y - s * 0.3, x + s, y], Color("ffffff"))
				poly.call([x + s, y, x + s * 1.3, y - s * 0.3, x + s * 1.3, y + s * 0.7, x + s, y + s], Color("e6cccc"))
		# Spec §26.5: the Moon's and Mars's riches.
		&"moon_ice":   # a dark crater with frosty ice sparkling in its floor
			disc.call(0.5, 0.56, 0.42, Color("b4b8c0"))
			disc.call(0.5, 0.6, 0.32, Color("5d626c"))
			disc.call(0.5, 0.66, 0.2, Color("cfe4f7"))
			for c: Array in [[0.42, 0.62], [0.56, 0.7], [0.5, 0.6], [0.6, 0.62]]:
				disc.call(c[0], c[1], 0.03, Color("ffffff"))
		&"ilmenite":   # dark sea dust with black blade crystals
			poly.call([0.06, 0.78, 0.94, 0.78, 0.84, 0.92, 0.16, 0.92], Color("4a4f5c"))
			for b: Array in [[0.24, 0.3, 0.44, 0.7], [0.46, 0.22, 0.6, 0.72], [0.62, 0.34, 0.8, 0.7]]:
				line.call(b[0], b[1], b[2], b[3], 0.07, Color("1c1d22"))
			line.call(0.47, 0.26, 0.5, 0.36, 0.025, Color("8b90a0"))
		&"helium3":   # the Sun's wind blowing onto grey dust: a sun, rays, a flask with a "3"
			disc.call(0.2, 0.22, 0.13, Color("ffd23f"))
			for i in 3:
				line.call(0.34, 0.24 + i * 0.1, 0.6, 0.34 + i * 0.1, 0.025, Color("ffb347"))
			poly.call([0.04, 0.8, 0.96, 0.8, 0.9, 0.92, 0.1, 0.92], Color("4a4f5c"))
			poly.call([0.64, 0.42, 0.86, 0.42, 0.86, 0.78, 0.64, 0.78], Color("c3c8cf"))
			line.call(0.68, 0.52, 0.82, 0.52, 0.04, Color("139e9b"))
			line.call(0.72, 0.62, 0.8, 0.66, 0.03, Color("0c7876"))
			line.call(0.8, 0.66, 0.72, 0.72, 0.03, Color("0c7876"))
		&"kreep":   # a pale speckled rock beside a horseshoe magnet
			poly.call([0.06, 0.8, 0.12, 0.44, 0.4, 0.34, 0.56, 0.52, 0.52, 0.8], Color("b9ad98"))
			for c: Array in [[0.2, 0.56], [0.34, 0.48], [0.4, 0.66], [0.26, 0.7]]:
				disc.call(c[0], c[1], 0.035, Color("9a6a44"))
			line.call(0.66, 0.3, 0.66, 0.66, 0.08, Color("d9302a"))
			line.call(0.9, 0.3, 0.9, 0.66, 0.08, Color("d9302a"))
			line.call(0.66, 0.66, 0.9, 0.66, 0.08, Color("d9302a"))
			line.call(0.66, 0.26, 0.66, 0.34, 0.08, Color("dfe5ec"))
			line.call(0.9, 0.26, 0.9, 0.34, 0.08, Color("dfe5ec"))
		&"meteorite":   # a dark iron lump with a shiny cut face and a streak of its fall
			line.call(0.1, 0.1, 0.4, 0.4, 0.04, Color("ffb347"))
			poly.call([0.28, 0.72, 0.34, 0.42, 0.58, 0.32, 0.8, 0.46, 0.78, 0.76, 0.5, 0.84], Color("3a2f2a"))
			poly.call([0.44, 0.5, 0.64, 0.44, 0.7, 0.62, 0.5, 0.68], Color("a9adb4"))
			line.call(0.46, 0.52, 0.66, 0.6, 0.015, Color("7d828b"))
			line.call(0.62, 0.46, 0.5, 0.66, 0.015, Color("7d828b"))
		&"mars_ice":   # a small crater in red dust with white ice in its floor
			disc.call(0.5, 0.56, 0.42, Color("c46a3c"))
			disc.call(0.5, 0.6, 0.3, Color("9c4f2c"))
			disc.call(0.5, 0.64, 0.18, Color("f2f5f8"))
			disc.call(0.46, 0.6, 0.05, Color("ffffff"))
		&"hematite":   # red dust with grey blueberries
			poly.call([0.04, 0.3, 0.96, 0.3, 0.96, 0.9, 0.04, 0.9], Color("c46a3c"))
			for c: Array in [[0.2, 0.44], [0.4, 0.62], [0.62, 0.42], [0.78, 0.7], [0.3, 0.8], [0.56, 0.78], [0.84, 0.46]]:
				disc.call(c[0], c[1], 0.06, Color("5b5f6b"))
				disc.call(c[0] - 0.02, c[1] - 0.02, 0.02, Color("8b90a0"))
		&"dark_sand":   # a dark dune with a magnet holding iron grains
			poly.call([0.04, 0.86, 0.36, 0.5, 0.7, 0.62, 0.96, 0.86], Color("2c2a2c"))
			line.call(0.56, 0.14, 0.56, 0.38, 0.07, Color("d9302a"))
			line.call(0.8, 0.14, 0.8, 0.38, 0.07, Color("d9302a"))
			line.call(0.56, 0.14, 0.8, 0.14, 0.07, Color("d9302a"))
			for c: Array in [[0.56, 0.44], [0.8, 0.45], [0.6, 0.48], [0.77, 0.5]]:
				disc.call(c[0], c[1], 0.025, Color("454247"))
		&"mars_salt":   # a pale cracked crust over the red ground, an oxygen bubble
			poly.call([0.04, 0.5, 0.96, 0.5, 0.96, 0.9, 0.04, 0.9], Color("9c4f2c"))
			poly.call([0.04, 0.42, 0.96, 0.42, 0.96, 0.6, 0.04, 0.6], Color("f0e6e2"))
			line.call(0.2, 0.42, 0.28, 0.6, 0.02, Color("c9aea4"))
			line.call(0.6, 0.42, 0.52, 0.6, 0.02, Color("c9aea4"))
			disc.call(0.7, 0.22, 0.1, Color("bfe0f5"))
			disc.call(0.5, 0.18, 0.06, Color("bfe0f5"))
	return true
