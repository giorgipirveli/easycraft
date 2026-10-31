class_name SchoolPictureG5
extends RefCounted
## Owner #68, grade 5 maths: the picture kinds grade 5 adds, drawn from data onto a SchoolPicture's card (it calls
## `problem` and `draw` for these kinds; UI draw calls and the game's block icons only, no new art). Kinds and fields:
## - grid {x_max, y_max, x_step?, y_step?, points?: [{x, y, label?}], join?, x_name?, y_name?}: the first quadrant of a
##   coordinate grid (GridCheck); `join` draws a line through the points in order. GridAnswer taps the same grid.
## - cubes {boxes: [{l, w, h, fill?}] (1-2, side by side), labels?, unit?, unknown? ("l", "w", "h": the first box's side
##   shown "?"), grid? (false: a plain box), block?}: boxes of unit cubes; `fill` layers of cubes in a box outline.
## - family {tree?: "quadrilaterals", hide?: a family shown "?", mark?: a family in gold}: ShapeFamily's tree.
## - places {numbers: [text] (1-3, whole or to thousandths), highlight?: a place, times_ten?}: a place value chart; the
##   "× 10" steps between its columns are drawn (the font has no arrows).
## - area_model {cols: [text] (1-4), rows: [text] (1-3), cells?: [[text]]}: a rectangle split into parts, sized by
##   their numbers (equal when one is not a number).
## - fraction_area {cols, rows (1-12), shade_cols, shade_rows, w?, h?}: a square cut into columns and rows, the first
##   shade_cols columns and shade_rows rows shaded; where both meet is the product (w and h label the shaded sides).
## - column {rows: [text] (2-6: a number, or "+ ", "− ", "× ", "÷ " and a number), lines?: [row index]}: a written sum,
##   digits lined up at the decimal point, a rule under each row in `lines`.

const KINDS: Array[String] = ["grid", "cubes", "family", "places", "area_model", "fraction_area", "column"]
const PLACES: Array[String] = ["hundred thousands", "ten thousands", "thousands", "hundreds", "tens", "ones", "tenths",
	"hundredths", "thousandths"]
const ONES := 5                 # PLACES' index of "ones"
const MAX_PLACES := 7
const MAX_ROW := 14             # the cubes' boxes side by side, in cubes
const MAX_SIDE := 10
const OPS: Array[String] = ["+", "−", "×", "÷"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const SOFT := Color("fce2b8")
const BLUE := Color("3a7be8")
const PALE_BLUE := Color("d9e6ff")
const GRID_LINE := Color("b9c6dd")
const CELL_COLORS: Array[Color] = [Color("dbeafe"), Color("fde7c7"), Color("d8f3dc"), Color("f3dcf5")]

static var _column_row := RegEx.create_from_string("^(?:([+−×÷]) )?([0-9?][0-9?,]*(?:\\.[0-9?]+)?)$")
static var _place_number := RegEx.create_from_string("^[0-9][0-9,]*(\\.[0-9]{1,3})?$")


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"grid":
			return GridCheck.problem(p)
		"cubes":
			var boxes: Variant = p.get("boxes")
			if not boxes is Array or (boxes as Array).is_empty() or (boxes as Array).size() > 2:
				return "cubes: 1-2 boxes"
			var long := 0
			for b: Variant in boxes:
				if not b is Dictionary:
					return "a box is {l, w, h, fill?}"
				for k: String in ["l", "w", "h"]:
					if not _in(_int(b, k, 0), 1, MAX_SIDE):
						return "a box's l, w and h: 1-%d" % MAX_SIDE
				if not _in(_int(b, "fill", _int(b, "h", 0)), 0, _int(b, "h", 0)):
					return "fill: 0 to the box's height"
				long += _int(b, "l", 0)
			if long > MAX_ROW:
				return "the boxes side by side: at most %d cubes long" % MAX_ROW
			if p.has("unknown") and not ["l", "w", "h"].has(str(p.unknown)):
				return "unknown: l, w or h"
			if p.has("block") and BlockIcons.icon(_int(p, "block", 0)) == null:
				return "no such block %s" % p.block
		"family":
			if str(p.get("tree", "quadrilaterals")) != "quadrilaterals":
				return "family: the quadrilaterals' tree"
			for k: String in ["hide", "mark"]:
				if p.has(k) and not ShapeFamily.NODES.has(str(p[k])):
					return "%s: one of %s" % [k, ShapeFamily.NODES]
		"places":
			var numbers: Variant = p.get("numbers")
			if not numbers is Array or (numbers as Array).is_empty() or (numbers as Array).size() > 3:
				return "places: 1-3 numbers"
			for n: Variant in numbers:
				if not n is String or not _place_number.search(n):
					return "places: whole numbers or decimals to thousandths, not %s" % [n]
			var cols := places_of(numbers)
			if cols.size() > MAX_PLACES or cols.is_empty() or cols[0] == "":
				return "places: at most %d columns, hundred thousands to thousandths" % MAX_PLACES
			if p.has("highlight") and not cols.has(str(p.highlight)):
				return "highlight: a place the chart shows (%s)" % [cols]
		"area_model":
			var cols: Variant = p.get("cols")
			var rows: Variant = p.get("rows")
			if not cols is Array or not _in((cols as Array).size(), 1, 4) or not rows is Array \
					or not _in((rows as Array).size(), 1, 3):
				return "area_model: 1-4 cols and 1-3 rows"
			if p.has("cells"):
				var cells: Variant = p.cells
				if not cells is Array or (cells as Array).size() != (rows as Array).size():
					return "cells: one row of texts per row"
				for row: Variant in cells:
					if not row is Array or (row as Array).size() != (cols as Array).size():
						return "cells: one text per col"
		"fraction_area":
			var c := _int(p, "cols", 0)
			var r := _int(p, "rows", 0)
			if not _in(c, 1, 12) or not _in(r, 1, 12) or not _in(_int(p, "shade_cols", -1), 0, c) \
					or not _in(_int(p, "shade_rows", -1), 0, r):
				return "fraction_area: cols and rows 1-12, shade_cols 0-cols, shade_rows 0-rows"
		"column":
			var rows: Variant = p.get("rows")
			if not rows is Array or not _in((rows as Array).size(), 2, 6):
				return "column: 2-6 rows"
			for t: Variant in rows:
				if not t is String or not _column_row.search(t) or str(t).length() > 14:
					return "column: a row is a number, maybe after + − × ÷ and a space: %s" % [t]
			for i: Variant in p.get("lines", []):
				if typeof(i) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(i), 0, (rows as Array).size() - 1):
					return "column: lines are row indexes"
		_:
			return "not a grade 5 kind"
	return ""


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"grid":
			draw_grid(pic, font, r, d)
		"cubes":
			_draw_cubes(pic, font, r, d)
		"family":
			_draw_family(pic, font, r, d)
		"places":
			_draw_places(pic, font, r, d)
		"area_model":
			_draw_area_model(pic, font, r, d)
		"fraction_area":
			_draw_fraction_area(pic, font, r, d)
		"column":
			_draw_column(pic, font, r, d)


# --- grid ------------------------------------------------------------------------------------------------------------

## Where grid g sits in r: {origin (the screen point of (0, 0)), unit (px per step), step, lines}.
static func grid_frame(r: Rect2, g: Dictionary) -> Dictionary:
	var n := GridCheck.lines(g)
	var left := 40.0
	var bottom := 34.0
	var top := 16.0 if str(g.get("y_name", "")) == "" else 34.0
	var right := 18.0 if str(g.get("x_name", "")) == "" else 30.0 + 11.0 * str(g.x_name).length()
	var room := Vector2(r.size.x - left - right, r.size.y - top - bottom)
	var unit := minf(room.x / maxi(n.x, 1), room.y / maxi(n.y, 1))
	var used := Vector2(n.x, n.y) * unit
	var origin := Vector2(r.position.x + left + (room.x - used.x) * 0.5, r.position.y + top + (room.y + used.y) * 0.5)
	return {"origin": origin, "unit": unit, "step": GridCheck.step(g), "lines": n}


## The screen point of the grid's point p.
static func grid_at(frame: Dictionary, p: Vector2i) -> Vector2:
	var s: Vector2i = frame.step
	return (frame.origin as Vector2) + Vector2(float(p.x) / s.x, -float(p.y) / s.y) * float(frame.unit)


## The grid point nearest a screen point.
static func grid_value(frame: Dictionary, at: Vector2) -> Vector2i:
	var s: Vector2i = frame.step
	var n: Vector2i = frame.lines
	var rel := (at - (frame.origin as Vector2)) / float(frame.unit)
	return Vector2i(clampi(roundi(rel.x), 0, n.x) * s.x, clampi(roundi(-rel.y), 0, n.y) * s.y)


static func draw_grid(ci: CanvasItem, font: Font, r: Rect2, g: Dictionary) -> Dictionary:
	var f := grid_frame(r, g)
	var n: Vector2i = f.lines
	var s: Vector2i = f.step
	var unit: float = f.unit
	var o: Vector2 = f.origin
	var fs := clampi(int(unit * 0.62), 14, 20)
	var top := grid_at(f, Vector2i(0, n.y * s.y))
	var right := grid_at(f, Vector2i(n.x * s.x, 0))
	ci.draw_rect(Rect2(Vector2(o.x, top.y), Vector2(right.x - o.x, o.y - top.y)), Color.WHITE)
	for i in range(1, n.x + 1):
		var x := o.x + i * unit
		ci.draw_line(Vector2(x, top.y), Vector2(x, o.y), GRID_LINE, 1.5)
	for j in range(1, n.y + 1):
		var y := o.y - j * unit
		ci.draw_line(Vector2(o.x, y), Vector2(right.x, y), GRID_LINE, 1.5)
	_arrow(ci, o, Vector2(right.x + 14, o.y), INK, 3.0)
	_arrow(ci, o, Vector2(o.x, top.y - 12), INK, 3.0)
	for i in n.x + 1:
		_label(ci, font, Vector2(o.x + i * unit, o.y + 16), str(i * s.x), fs)
	for j in range(1, n.y + 1):
		var t := str(j * s.y)
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_label(ci, font, Vector2(o.x - 10 - w * 0.5, o.y - j * unit), t, fs)
	if str(g.get("x_name", "")) != "":
		var w := font.get_string_size(str(g.x_name), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_label(ci, font, Vector2(right.x + 22 + w * 0.5, o.y), str(g.x_name), fs, BLUE)
	if str(g.get("y_name", "")) != "":
		_label(ci, font, Vector2(o.x, top.y - 24), str(g.y_name), fs, BLUE)
	var pts: Array = g.get("points", [])
	if bool(g.get("join", false)) and pts.size() > 1:
		var line := PackedVector2Array()
		for p: Dictionary in pts:
			line.append(grid_at(f, Vector2i(int(p.x), int(p.y))))
		ci.draw_polyline(line, BLUE, 3.0, true)
	for p: Dictionary in pts:
		var at := grid_at(f, Vector2i(int(p.x), int(p.y)))
		dot(ci, at, unit, SHADE)
		if str(p.get("label", "")) != "":
			var lw := font.get_string_size(str(p.label), HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 2).x
			var place := at + Vector2(lw * 0.5 + 10, -14)
			if place.x + lw * 0.5 > r.end.x:
				place.x = at.x - lw * 0.5 - 10
			_label(ci, font, place, str(p.label), fs + 2, INK)
	return f


## A point on the grid: a dot with a dark ring.
static func dot(ci: CanvasItem, at: Vector2, unit: float, color: Color) -> void:
	var rad := clampf(unit * 0.2, 5.0, 10.0)
	ci.draw_circle(at, rad, color)
	ci.draw_arc(at, rad, 0, TAU, 20, INK, 2.0, true)


# --- cubes -----------------------------------------------------------------------------------------------------------

static func _draw_cubes(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var boxes: Array = d.boxes
	var labels := bool(d.get("labels", false))
	var grid := bool(d.get("grid", true))
	var long := 0
	var deep := 0
	var tall := 0
	for b: Dictionary in boxes:
		long += _int(b, "l", 1)
		deep = maxi(deep, _int(b, "w", 1))
		tall = maxi(tall, _int(b, "h", 1))
	var k := 0.5   # the depth drawn at 45 degrees, half size
	var pad := Vector2(64.0, 40.0) if labels else Vector2(16.0, 12.0)
	var s := minf(minf((r.size.x - 2.0 * pad.x) / (long + deep * k), (r.size.y - 2.0 * pad.y) / (tall + deep * k)), 46.0)
	var used := Vector2(long + deep * k, tall + deep * k) * s
	var base := Vector2(r.position.x + (r.size.x - used.x) * 0.5, r.end.y - (r.size.y - used.y) * 0.5)
	var tex := BlockIcons.icon(_int(d, "block", BlockIds.PLANKS))
	var fs := clampi(int(s * 0.62), 13, 22)
	var x0 := 0
	for i in boxes.size():
		var b: Dictionary = boxes[i]
		var l := _int(b, "l", 1)
		var w := _int(b, "w", 1)
		var h := _int(b, "h", 1)
		var fill := _int(b, "fill", h)
		var at := func(x: float, y: float, z: float) -> Vector2:
			return base + Vector2((x0 + x) * s + z * k * s, -(y * s) - z * k * s)
		if grid:
			for y in fill:   # the front face, the right side and the top of the filled layers
				for x in l:
					_face(ci, [at.call(x, y, 0), at.call(x + 1, y, 0), at.call(x + 1, y + 1, 0), at.call(x, y + 1, 0)], tex, 0.92)
				for z in w:
					_face(ci, [at.call(l, y, z), at.call(l, y, z + 1), at.call(l, y + 1, z + 1), at.call(l, y + 1, z)], tex, 0.66)
			if fill > 0:
				for z in w:
					for x in l:
						_face(ci, [at.call(x, fill, z), at.call(x + 1, fill, z), at.call(x + 1, fill, z + 1),
							at.call(x, fill, z + 1)], tex, 1.12)
		else:
			_face(ci, [at.call(0, 0, 0), at.call(l, 0, 0), at.call(l, h, 0), at.call(0, h, 0)], null, 1.0, SOFT)
			_face(ci, [at.call(l, 0, 0), at.call(l, 0, w), at.call(l, h, w), at.call(l, h, 0)], null, 1.0, SOFT.darkened(0.18))
			_face(ci, [at.call(0, h, 0), at.call(l, h, 0), at.call(l, h, w), at.call(0, h, w)], null, 1.0, SOFT.lightened(0.3))
		# the box's edges (the whole box, also where it is not filled yet)
		var edge := INK if fill == h or not grid else Color(INK, 0.55)
		for pair: Array in [[[0, 0, 0], [l, 0, 0]], [[l, 0, 0], [l, h, 0]], [[l, h, 0], [0, h, 0]], [[0, h, 0], [0, 0, 0]],
				[[l, 0, 0], [l, 0, w]], [[l, 0, w], [l, h, w]], [[l, h, w], [0, h, w]], [[0, h, w], [0, h, 0]], [[l, h, 0], [l, h, w]]]:
			var a: Array = pair[0]
			var e: Array = pair[1]
			ci.draw_line(at.call(a[0], a[1], a[2]), at.call(e[0], e[1], e[2]), edge, 2.5, true)
		if labels:
			var unit := str(d.get("unit", ""))
			var unknown := str(d.get("unknown", "")) if i == 0 else ""
			var word := func(side: String, n: int) -> String:
				return "?" if unknown == side else ("%d %s" % [n, unit]).strip_edges()
			_label(ci, font, (at.call(0, 0, 0) + at.call(l, 0, 0)) * 0.5 + Vector2(0, 18), word.call("l", l), fs)
			var hw := font.get_string_size(word.call("h", h), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if i == 0:
				_label(ci, font, (at.call(0, 0, 0) + at.call(0, h, 0)) * 0.5 - Vector2(hw * 0.5 + 10, 0), word.call("h", h), fs)
			else:
				_label(ci, font, (at.call(l, 0, w) + at.call(l, h, w)) * 0.5 + Vector2(hw * 0.5 + 10, 0), word.call("h", h), fs)
			var ww := font.get_string_size(word.call("w", w), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if boxes.size() == 2 and i == 0:   # the next box hides this one's right side: the top-left edge
				var top: Vector2 = (at.call(0, h, 0) + at.call(0, h, w)) * 0.5
				_label(ci, font, top - Vector2(ww * 0.5 + 8, 8), word.call("w", w), fs)
			else:
				var mid: Vector2 = (at.call(l, 0, 0) + at.call(l, 0, w)) * 0.5
				_label(ci, font, mid + Vector2(ww * 0.5 + 10, 6), word.call("w", w), fs)
		x0 += l


## A face of a cube (4 corners), with the block's picture shaded by `light`, or a plain colour.
static func _face(ci: CanvasItem, corners: Array, tex: Texture2D, light: float, color: Color = Color.WHITE) -> void:
	var pts := PackedVector2Array(corners)
	if tex:
		ci.draw_colored_polygon(pts, Color(light, light, light * 1.02), PackedVector2Array([Vector2(0, 1), Vector2(1, 1),
			Vector2(1, 0), Vector2(0, 0)]), tex)
	else:
		ci.draw_colored_polygon(pts, color)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, Color(0, 0, 0, 0.45), 1.5, true)


# --- family ----------------------------------------------------------------------------------------------------------

static func _draw_family(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var hide := str(d.get("hide", ""))
	var mark := str(d.get("mark", ""))
	var box := Vector2(minf(r.size.x / 3.2, 178.0), minf(r.size.y / 4.0 * 0.82, 56.0))
	var gap := (r.size.y - box.y) / 3.0
	var centres := {}
	var per_level := {0: ["quadrilateral"], 1: ["trapezium", "parallelogram", "kite"], 2: ["rectangle", "rhombus"],
		3: ["square"]}
	var xs := {0: [0.5], 1: [1.0 / 6.0, 0.5, 5.0 / 6.0], 2: [1.0 / 3.0, 2.0 / 3.0], 3: [0.5]}
	for level: int in per_level:
		for i in (per_level[level] as Array).size():
			centres[per_level[level][i]] = Vector2(r.position.x + r.size.x * float(xs[level][i]),
				r.position.y + box.y * 0.5 + level * gap)
	for node: String in ShapeFamily.NODES:
		for parent: String in ShapeFamily.parents(node):
			ci.draw_line(centres[parent] + Vector2(0, box.y * 0.5), centres[node] - Vector2(0, box.y * 0.5), INK, 2.5, true)
	var fs := clampi(int(box.y * 0.36), 12, 20)
	for node: String in ShapeFamily.NODES:
		var c: Vector2 = centres[node]
		var rect := Rect2(c - box * 0.5, box)
		var sb := StyleBoxFlat.new()
		sb.bg_color = SchoolUi.GOLD if node == mark else Color.WHITE
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(3 if node == mark else 2)
		sb.border_color = INK
		ci.draw_style_box(sb, rect)
		var icon := Rect2(rect.position + Vector2(6, 6), Vector2(box.y - 12, box.y - 12))
		_shape_icon(ci, node, icon)
		var text := "?" if node == hide else node
		var room := rect.size.x - icon.size.x - 16.0
		var size := fs + (8 if node == hide else 0)
		while size > 10 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > room:
			size -= 1
		_label(ci, font, Vector2(icon.end.x + 4 + room * 0.5, c.y), text, size, SHADE if node == hide else INK)


static func _shape_icon(ci: CanvasItem, what: String, box: Rect2) -> void:
	var unit := ShapeFamily.points(what)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in unit:
		lo = lo.min(p)
		hi = hi.max(p)
	var k := minf(box.size.x / maxf(hi.x - lo.x, 0.01), box.size.y / maxf(hi.y - lo.y, 0.01))
	var offset := box.get_center() - (lo + hi) * 0.5 * k
	var pts := PackedVector2Array()
	for p in unit:
		pts.append(offset + p * k)
	ci.draw_colored_polygon(pts, SOFT)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, INK, 2.0, true)


# --- places ----------------------------------------------------------------------------------------------------------

## The chart's columns for these numbers: from their highest place (at least the ones) to their lowest.
static func places_of(numbers: Array) -> Array[String]:
	var whole := 1
	var parts := 0
	for n: Variant in numbers:
		var t := str(n).replace(",", "")
		whole = maxi(whole, t.get_slice(".", 0).length())
		if t.contains("."):
			parts = maxi(parts, t.get_slice(".", 1).length())
	var out: Array[String] = []
	if whole > ONES + 1 or parts > PLACES.size() - ONES - 1:
		return [""] as Array[String]
	for i in range(ONES + 1 - whole, ONES + 1 + parts):
		out.append(PLACES[i])
	return out


static func _draw_places(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var numbers: Array = d.numbers
	var cols := places_of(numbers)
	var n := cols.size()
	var arrows := bool(d.get("times_ten", false)) and n > 1
	var cw := minf(r.size.x / n, 140.0)
	var arrow_h := 34.0 if arrows else 0.0
	var head_h := clampf(r.size.y * 0.26, 34.0, 58.0)
	var rh := minf((r.size.y - head_h - arrow_h) / numbers.size(), 76.0)
	var origin := Vector2(r.position.x + (r.size.x - cw * n) * 0.5,
		r.position.y + (r.size.y - head_h - arrow_h - rh * numbers.size()) * 0.5 + arrow_h)
	var hs := 20
	for name in cols:
		for word in name.split(" "):
			while hs > 11 and font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x > cw - 8:
				hs -= 1
	hs = mini(hs, int(head_h * 0.36))
	var ds := clampi(int(rh * 0.62), 14, 46)
	var hl := str(d.get("highlight", ""))
	for i in n:
		var col := Rect2(origin + Vector2(i * cw, 0), Vector2(cw, head_h + rh * numbers.size()))
		ci.draw_rect(Rect2(col.position, Vector2(cw, head_h)), PALE_BLUE)
		ci.draw_rect(Rect2(col.position + Vector2(0, head_h), Vector2(cw, col.size.y - head_h)),
			SOFT if cols[i] == hl else Color.WHITE)
		var words := cols[i].split(" ")
		for w in words.size():
			var y := col.position.y + head_h * 0.5 + (w - (words.size() - 1) * 0.5) * hs * 1.15
			_label(ci, font, Vector2(col.get_center().x, y), words[w], hs)
		ci.draw_rect(col, INK, false, 2.0)
		ci.draw_line(col.position + Vector2(0, head_h), col.position + Vector2(cw, head_h), INK, 2.0)
	var ones := cols.find("ones")
	for row in numbers.size():
		var t := str(numbers[row]).replace(",", "")
		var whole := t.get_slice(".", 0)
		var part := t.get_slice(".", 1) if t.contains(".") else ""
		var y := origin.y + head_h + (row + 0.5) * rh
		for k in whole.length():
			var i := ones - (whole.length() - 1 - k)
			_label(ci, font, Vector2(origin.x + (i + 0.5) * cw, y), whole[k], ds)
		for k in part.length():
			_label(ci, font, Vector2(origin.x + (ones + 1 + k + 0.5) * cw, y), part[k], ds)
		if t.contains("."):
			ci.draw_circle(Vector2(origin.x + (ones + 1) * cw, y + ds * 0.3), maxf(3.5, ds * 0.13), INK)
		if row > 0:
			ci.draw_line(Vector2(origin.x, y - rh * 0.5), Vector2(origin.x + n * cw, y - rh * 0.5), Color(INK, 0.4), 1.5)
	if arrows:
		for i in n - 1:
			var a := Vector2(origin.x + (i + 1.5) * cw, origin.y - 4)
			var b := Vector2(origin.x + (i + 0.5) * cw, origin.y - 4)
			var mid := (a + b) * 0.5 - Vector2(0, arrow_h * 0.55)
			var curve := PackedVector2Array()
			for s in 13:
				var t := s / 12.0
				curve.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
			ci.draw_polyline(curve, BLUE, 2.0, true)
			var tip := curve[curve.size() - 1]
			var back := (curve[curve.size() - 3] - tip).normalized() * 9.0
			ci.draw_colored_polygon(PackedVector2Array([tip, tip + back + back.orthogonal() * 0.6,
				tip + back - back.orthogonal() * 0.6]), BLUE)
			_label(ci, font, mid + Vector2(0, -2), "× 10", clampi(int(cw * 0.2), 11, 16), BLUE)


# --- area model --------------------------------------------------------------------------------------------------------

static func _draw_area_model(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var cols: Array = d.cols
	var rows: Array = d.rows
	var cells: Array = d.get("cells", [])
	var fs := clampi(int(r.size.y * 0.1), 13, 24)
	var left := 16.0
	for t: Variant in rows:
		left = maxf(left, font.get_string_size(str(t), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0)
	var top := fs + 14.0
	var area := Rect2(r.position + Vector2(left, top), r.size - Vector2(left + 8.0, top + 6.0))
	var ws := _shares(cols)
	var hs := _shares(rows)
	var x := area.position.x
	for i in cols.size():
		var w := area.size.x * ws[i]
		var y := area.position.y
		for j in rows.size():
			var h := area.size.y * hs[j]
			var cell := Rect2(x, y, w, h)
			ci.draw_rect(cell, CELL_COLORS[(i + j) % CELL_COLORS.size()])
			ci.draw_rect(cell, INK, false, 2.0)
			if j < cells.size() and i < (cells[j] as Array).size():
				var t := str(cells[j][i])
				var size := fs
				while size > 10 and font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w - 6:
					size -= 1
				_label(ci, font, cell.get_center(), t, size, SHADE if t == "?" else INK)
			if i == 0:
				_label(ci, font, Vector2(area.position.x - left * 0.5, cell.get_center().y), str(rows[j]), fs,
					SHADE if str(rows[j]) == "?" else BLUE)
			y += h
		_label(ci, font, Vector2(x + w * 0.5, area.position.y - top * 0.5), str(cols[i]), fs,
			SHADE if str(cols[i]) == "?" else BLUE)
		x += w


## Each part's share of the side: by its number (none below 0.12), or equal when one is not a number.
static func _shares(parts: Array) -> Array[float]:
	var values: Array[float] = []
	var total := 0.0
	for t: Variant in parts:
		var v := NumberAnswer.value(str(t))
		if is_nan(v) or v <= 0.0:
			values.clear()
			break
		values.append(v)
		total += v
	var out: Array[float] = []
	if values.is_empty():
		for t: Variant in parts:
			out.append(1.0 / parts.size())
		return out
	var sum := 0.0
	for v in values:
		out.append(maxf(v / total, 0.12))
		sum += out.back()
	for i in out.size():
		out[i] /= sum
	return out


# --- fraction area -------------------------------------------------------------------------------------------------------

static func _draw_fraction_area(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var cols := _int(d, "cols", 1)
	var rows := _int(d, "rows", 1)
	var sc := _int(d, "shade_cols", 0)
	var sr := _int(d, "shade_rows", 0)
	var fs := clampi(int(r.size.y * 0.09), 13, 22)
	var left := 20.0 if str(d.get("h", "")) == "" else font.get_string_size(str(d.h), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 30.0
	var top := 12.0 if str(d.get("w", "")) == "" else fs + 22.0
	var side := minf(r.size.x - left - 20.0, r.size.y - top - 10.0)
	var o := Vector2(r.position.x + left + (r.size.x - left - 20.0 - side) * 0.5, r.position.y + top)
	var cw := side / cols
	var ch := side / rows
	for j in rows:
		for i in cols:
			var both := i < sc and j < sr
			var color := SHADE if both else (Color("a9c8f5") if i < sc else (Color("fbe38e") if j < sr else Color.WHITE))
			ci.draw_rect(Rect2(o + Vector2(i * cw, j * ch), Vector2(cw, ch)), color)
	for i in range(1, cols):
		ci.draw_line(o + Vector2(i * cw, 0), o + Vector2(i * cw, side), Color(INK, 0.55), 1.5)
	for j in range(1, rows):
		ci.draw_line(o + Vector2(0, j * ch), o + Vector2(side, j * ch), Color(INK, 0.55), 1.5)
	ci.draw_rect(Rect2(o, Vector2(side, side)), INK, false, 3.0)
	if str(d.get("w", "")) != "" and sc > 0:
		var y := o.y - 10.0
		ci.draw_line(Vector2(o.x, y), Vector2(o.x + sc * cw, y), BLUE, 2.5)
		for x: float in [o.x, o.x + sc * cw]:
			ci.draw_line(Vector2(x, y - 6), Vector2(x, y + 6), BLUE, 2.5)
		_label(ci, font, Vector2(o.x + sc * cw * 0.5, y - fs * 0.7), str(d.w), fs, BLUE)
	if str(d.get("h", "")) != "" and sr > 0:
		var x := o.x - 10.0
		ci.draw_line(Vector2(x, o.y), Vector2(x, o.y + sr * ch), Color("b38600"), 2.5)
		for y: float in [o.y, o.y + sr * ch]:
			ci.draw_line(Vector2(x - 6, y), Vector2(x + 6, y), Color("b38600"), 2.5)
		var w := font.get_string_size(str(d.h), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_label(ci, font, Vector2(x - 10 - w * 0.5, o.y + sr * ch * 0.5), str(d.h), fs, Color("b38600"))


# --- column --------------------------------------------------------------------------------------------------------------

static func _draw_column(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var ops: Array[String] = []
	var wholes: Array[String] = []   # with their commas
	var parts: Array[String] = []    # the digits after the point
	var points: Array[bool] = []
	var most_whole := 0
	var most_part := 0
	for t: Variant in rows:
		var m := _column_row.search(str(t))
		ops.append(m.get_string(1))
		var body := m.get_string(2)
		wholes.append(body.get_slice(".", 0))
		parts.append(body.get_slice(".", 1) if body.contains(".") else "")
		points.append(body.contains("."))
		most_whole = maxi(most_whole, wholes.back().replace(",", "").length())
		most_part = maxi(most_part, parts.back().length())
	var fs := clampi(int(minf(r.size.y / (rows.size() * 1.35), 40.0)), 12, 40)
	var cells := 1.4 + most_whole + (0.5 if most_part > 0 else 0.0) + most_part   # in digit widths
	var cw := font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 1.3
	while fs > 12 and cw * cells > r.size.x:
		fs -= 1
		cw = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 1.3
	var lh := fs * 1.3
	var o := Vector2(r.get_center().x - cw * cells * 0.5, r.get_center().y - lh * rows.size() * 0.5)
	var ones_end := o.x + cw * (1.4 + most_whole)   # the right edge of the ones column
	var lines: Array = d.get("lines", [])
	for i in rows.size():
		var y := o.y + (i + 0.5) * lh
		if ops[i] != "":
			_label(ci, font, Vector2(o.x + cw * 0.5, y), ops[i], fs, BLUE)
		var k := 0   # digits from the right
		for j in range(wholes[i].length() - 1, -1, -1):
			var ch := wholes[i][j]
			var x := ones_end - k * cw
			if ch == ",":
				_label(ci, font, Vector2(x, y + fs * 0.28), ",", int(fs * 0.8))
				continue
			_label(ci, font, Vector2(x - cw * 0.5, y), ch, fs, SHADE if ch == "?" else INK)
			k += 1
		if points[i]:
			ci.draw_circle(Vector2(ones_end + cw * 0.25, y + fs * 0.3), maxf(2.5, fs * 0.09), INK)
		for j in parts[i].length():
			var ch := parts[i][j]
			_label(ci, font, Vector2(ones_end + cw * 0.5 + (j + 0.5) * cw, y), ch, fs, SHADE if ch == "?" else INK)
		if lines.has(i) or lines.has(float(i)):
			ci.draw_line(Vector2(o.x, o.y + (i + 1) * lh), Vector2(o.x + cw * cells, o.y + (i + 1) * lh), INK, 2.5)


# --- helpers ---------------------------------------------------------------------------------------------------------

## Text centred on `c` (both ways).
static func _label(ci: CanvasItem, font: Font, c: Vector2, text: String, size: int, color: Color = INK) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := c.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	ci.draw_string(font, Vector2(c.x - w * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func _arrow(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	ci.draw_line(from, to, color, width)
	var back := (from - to).normalized() * 12.0
	ci.draw_colored_polygon(PackedVector2Array([to, to + back + back.orthogonal() * 0.5, to + back - back.orthogonal() * 0.5]),
		color)


static func _int(p: Dictionary, key: String, default: int) -> int:
	var v: Variant = p.get(key, default)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _in(v: int, lo: int, hi: int) -> bool:
	return v >= lo and v <= hi
