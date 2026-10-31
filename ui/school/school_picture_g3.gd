class_name SchoolPictureG3
extends RefCounted
## Owner #70, grade 3 maths: the picture kinds grade 3 adds, drawn from data onto a SchoolPicture's card (it calls
## `problem` and `draw` for these kinds; UI draw calls and the game's block icons only, no new art). Kinds and fields:
## - pictogram {rows: [[label, value]] (1-6), each (what one symbol stands for), unit?, block?}: a picture graph; a value
##   is a whole or half number of symbols (0-10); a half is half a symbol. The key under it: "(symbol) = each unit".
## - bar_graph {bars: [[label, value]] (1-6), step, top (a multiple of step, at most 10 steps), name?}: a bar graph with
##   a scale: a line and a number at every step; a value may end between two lines.
## - jug {top, fill, step, unit ("L" | "mL"), minor?, label?} or {jugs: [{top, fill, label?}] (1-3), step, unit, minor?}:
##   measuring jugs with a mark and its number at every step (top: the highest mark), `minor` small marks between.
## - dial_scale {top, step, value, unit ("g" | "kg"), minor?, block?}: a kitchen scale's dial, 0 at the top, a number at
##   every step (2-12 of them), its needle at `value`; `block` sits on the plate.
## - ruler {to (1-15 cm), length, from? (text numbers: "7.5", "29/4"), mm?}: a centimetre ruler (millimetre marks when
##   mm) with a stick from `from` to `from + length` above it.
## - cut_shape {shape ("circle", "square", "rectangle", "hexagon", "triangle"), parts, shade?, way? ("strips", "grid",
##   "diagonals"), unequal?}: a shape cut into parts (see CUTS), the first `shade` of them shaded; `unequal` cuts a circle
##   or a strip-cut rectangle into parts of different sizes.
## - unit_squares {rows: ["##..", …] (1-10 rows of 1-12 of ".#abc", all as long), grid? (true), labels?, per?, unit?}: a
##   shape of unit squares ("a", "b", "c": squares in the colours of a split); labels: each straight side's length
##   (squares × per, and the unit).
## - side_lengths {what (a ShapeFacts shape, not the circle) | points: [[x, y], …] (3-8 corners, 0-12), labels: [text per
##   side, from the first corner]}: a shape with its sides' lengths ("?" for a missing one).
## - fraction_plot {from, to (whole numbers), parts (1, 2 or 4 marks a whole), counts: {"2", "2½", "¾", …: X marks},
##   unit?}: a line plot of measurements in wholes, halves and quarters.
## - bar_model {bars: [{name?, parts: [{text, size}] (1-10), total?}] (1-3), diff?}: Singapore bar models: bars of parts
##   sized by `size`, a bracket with the total above a bar, and for two bars `diff` on the shorter bar's gap.
## - digital_clock {h (0-23), m, twelve?}: a digital clock ("15:07"; twelve: "3:07").
## - times_grid {rows, cols (1-12), r0?, c0? (the first row's and column's numbers, 1), op? ("×" | "+"), hide?: [[row
##   number, column number], …] shown "?", shade_row?, shade_col?}: a times table (or an adding table) and its headers.
## - fraction_wall {rows: [{den (1-12), shade (0-den)}] (1-4), labels?}: a fraction wall, every row as long, cut into
##   `den` equal parts with the first `shade` shaded; no words unless `labels` (then "shade/den" at each row's left;
##   the base kind "bar" always writes them, which would give an answer away).

const KINDS: Array[String] = ["pictogram", "bar_graph", "jug", "dial_scale", "ruler", "cut_shape", "unit_squares",
	"side_lengths", "fraction_plot", "bar_model", "digital_clock", "times_grid", "fraction_wall"]
## How each shape may be cut: shape -> way -> the part counts allowed ([] = any 1-12).
const CUTS := {"circle": {"sectors": []}, "square": {"strips": [], "grid": [4, 6, 8, 9, 12], "diagonals": [2, 4]},
	"rectangle": {"strips": [], "grid": [4, 6, 8, 9, 12]}, "hexagon": {"sectors": [2, 3, 6]},
	"triangle": {"sectors": [2, 3, 4]}}
const GRID_CUTS := {4: Vector2i(2, 2), 6: Vector2i(3, 2), 8: Vector2i(4, 2), 9: Vector2i(3, 3), 12: Vector2i(4, 3)}
const UNEVEN: Array[float] = [1.0, 1.8, 0.7, 1.4, 0.9, 1.6, 0.8, 1.3, 1.1, 1.7, 0.75, 1.25]
const QUARTERS := {"": 0, "¼": 1, "½": 2, "¾": 3}
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const SOFT := Color("fce2b8")
const BLUE := Color("3a7be8")
const PALE_BLUE := Color("d9e6ff")
const WATER := Color("5aa9f0")
const GOLD := Color("f2c230")
const GRID_LINE := Color("b9c6dd")
const RED := Color("d9463b")
const BAR_COLORS: Array[Color] = [Color("3a7be8"), Color("f08a1c"), Color("2fae4e"), Color("c04fd0"), Color("e5b700"),
	Color("d9463b")]
const SQUARE_COLORS := {"#": Color("fce2b8"), "a": Color("bfe3ff"), "b": Color("ffd59e"), "c": Color("c9f0c1")}

static var _plot_key := RegEx.create_from_string("^([0-9]*)([¼½¾]?)$")


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"pictogram":
			var each := _num(p, "each")
			if not _pairs_ok(p.get("rows"), 6) or is_nan(each) or each < 1:
				return "pictogram: 1-6 rows of [label, value] and each (1 or more)"
			for row: Array in p.rows:
				var n := float(row[1]) / each
				if n < 0.0 or n > 10.0 or absf(n * 2.0 - roundf(n * 2.0)) > 0.001:
					return "pictogram: a value is 0-10 whole or half symbols: %s" % [row]
			if p.has("block") and BlockIcons.icon(_int(p, "block", 0)) == null:
				return "pictogram: no such block %s" % p.block
		"bar_graph":
			var step := _int(p, "step", 0)
			var top := _int(p, "top", 0)
			if not _pairs_ok(p.get("bars"), 6) or step < 1 or top < step or top % step != 0 or top > step * 10:
				return "bar_graph: 1-6 bars of [label, value], a step and a top of 1-10 steps"
			for bar: Array in p.bars:
				if float(bar[1]) < 0.0 or float(bar[1]) > top:
					return "bar_graph: a bar from 0 to top: %s" % [bar]
		"jug":
			var jugs := jugs_of(p)
			var step := _num(p, "step")
			if jugs.is_empty() or jugs.size() > 3 or is_nan(step) or step <= 0.0 or not ["L", "mL"].has(str(p.get("unit", ""))):
				return "jug: 1-3 jugs, a step and a unit (L or mL)"
			if not _in(_int(p, "minor", 0), 0, 9):
				return "jug: minor 0-9"
			for j: Dictionary in jugs:
				var top := _num(j, "top")
				var fill := _num(j, "fill")
				if is_nan(top) or is_nan(fill) or top < step or absf(top / step - roundf(top / step)) > 0.001 \
						or top / step > 10.0 or fill < 0.0 or fill > top:
					return "jug: a top of 1-10 steps and a fill from 0 to top: %s" % [j]
		"dial_scale":
			var top := _num(p, "top")
			var step := _num(p, "step")
			var value := _num(p, "value")
			if is_nan(top) or is_nan(step) or is_nan(value) or step <= 0.0 or absf(top / step - roundf(top / step)) > 0.001 \
					or top / step < 2.0 or top / step > 12.0 or value < 0.0 or value > top:
				return "dial_scale: a top of 2-12 steps and a value from 0 to top"
			if not ["g", "kg"].has(str(p.get("unit", ""))) or not _in(_int(p, "minor", 0), 0, 9):
				return "dial_scale: unit g or kg, minor 0-9"
			if p.has("block") and BlockIcons.icon(_int(p, "block", 0)) == null:
				return "dial_scale: no such block %s" % p.block
		"ruler":
			var to := _int(p, "to", 0)
			var length := NumberAnswer.value(str(p.get("length", "")))
			var from := NumberAnswer.value(str(p.get("from", "0")))
			if not _in(to, 1, 15) or is_nan(length) or is_nan(from) or length <= 0.0 or from < 0.0 or from + length > to + 0.0001:
				return "ruler: to 1-15 cm, and a stick from `from` of `length` on the ruler"
		"cut_shape":
			var shape := str(p.get("shape", ""))
			if not CUTS.has(shape):
				return "cut_shape: a shape of %s" % [CUTS.keys()]
			var way := cut_way(p)
			var parts := _int(p, "parts", 0)
			if not (CUTS[shape] as Dictionary).has(way):
				return "cut_shape: a %s is cut into %s" % [shape, (CUTS[shape] as Dictionary).keys()]
			var allowed: Array = CUTS[shape][way]
			if not _in(parts, 1, 12) or (not allowed.is_empty() and not allowed.has(parts)):
				return "cut_shape: a %s cut into %s takes %s parts" % [shape, way, str(allowed) if not allowed.is_empty() else "1-12"]
			if not _in(_int(p, "shade", 0), 0, parts):
				return "cut_shape: shade 0 to parts"
			if bool(p.get("unequal", false)) and (way not in ["sectors", "strips"] or shape in ["hexagon", "triangle"] or parts < 2):
				return "cut_shape: only a circle or strips can be cut unequally (2 or more parts)"
		"unit_squares":
			var rows: Variant = p.get("rows")
			if not rows is Array or not _in((rows as Array).size(), 1, 10):
				return "unit_squares: 1-10 rows"
			var width := -1
			var filled := 0
			for row: Variant in rows:
				if not row is String or not _in(str(row).length(), 1, 12) or (width >= 0 and str(row).length() != width):
					return "unit_squares: rows of 1-12 letters, all as long"
				width = str(row).length()
				for ch in str(row):
					if not ".#abc".contains(ch):
						return "unit_squares: a row of . # a b c: %s" % row
					filled += 0 if ch == "." else 1
			if filled == 0 or not _in(_int(p, "per", 1), 1, 100):
				return "unit_squares: some squares, per 1-100"
		"side_lengths":
			var pts := side_points(p)
			if pts.size() < 3 or pts.size() > 8:
				return "side_lengths: a shape (not the circle) or 3-8 points from 0 to 12"
			var labels: Variant = p.get("labels")
			if not labels is Array or (labels as Array).size() != pts.size():
				return "side_lengths: one label per side (%d)" % pts.size()
		"fraction_plot":
			var from := _int(p, "from", -1)
			var to := _int(p, "to", -1)
			var parts := _int(p, "parts", 0)
			if from < 0 or to <= from or not [1, 2, 4].has(parts) or (to - from) * parts > 16 or not p.get("counts") is Dictionary:
				return "fraction_plot: from < to, parts 1, 2 or 4 (at most 16 marks) and counts"
			for k: Variant in p.counts:
				var q := quarters_of(str(k))
				if q < from * 4 or q > to * 4 or q % int(4.0 / parts) != 0 or not _in(int(p.counts[k]), 0, 8):
					return "fraction_plot: a count off the plot or not on a mark: %s" % k
		"bar_model":
			var bars: Variant = p.get("bars")
			if not bars is Array or not _in((bars as Array).size(), 1, 3):
				return "bar_model: 1-3 bars"
			for b: Variant in bars:
				if not b is Dictionary or not (b as Dictionary).get("parts") is Array or not _in((b.parts as Array).size(), 1, 10):
					return "bar_model: a bar is {name?, parts: 1-10 of {text, size}, total?}"
				for part: Variant in b.parts:
					if not part is Dictionary or is_nan(_num(part, "size")) or _num(part, "size") <= 0.0:
						return "bar_model: a part is {text, size above 0}"
			if p.has("diff") and (bars as Array).size() != 2:
				return "bar_model: diff compares two bars"
		"digital_clock":
			if not _in(_int(p, "h", -1), 0, 23) or not _in(_int(p, "m", -1), 0, 59):
				return "digital_clock: h 0-23, m 0-59"
		"times_grid":
			var rows := _int(p, "rows", 0)
			var cols := _int(p, "cols", 0)
			var r0 := _int(p, "r0", 1)
			var c0 := _int(p, "c0", 1)
			if not _in(rows, 1, 12) or not _in(cols, 1, 12) or not _in(r0, 0, 12) or not _in(c0, 0, 12) \
					or r0 + rows - 1 > 12 or c0 + cols - 1 > 12 or not ["×", "+"].has(str(p.get("op", "×"))):
				return "times_grid: rows and cols 1-12, headers up to 12, op × or +"
			for cell: Variant in p.get("hide", []):
				if not cell is Array or (cell as Array).size() != 2 or not _in(int(cell[0]), r0, r0 + rows - 1) \
						or not _in(int(cell[1]), c0, c0 + cols - 1):
					return "times_grid: a hidden cell off the grid: %s" % [cell]
		"fraction_wall":
			var rows: Variant = p.get("rows")
			if not rows is Array or not _in((rows as Array).size(), 1, 4):
				return "fraction_wall: 1-4 rows"
			for row: Variant in rows:
				if not row is Dictionary or not _in(_int(row, "den", 0), 1, 12) or not _in(_int(row, "shade", -1), 0, _int(row, "den", 0)):
					return "fraction_wall: a row is {den: 1-12, shade: 0-den}"
		_:
			return "not a grade 3 kind"
	return ""


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"pictogram":
			_draw_pictogram(pic, font, r, d)
		"bar_graph":
			_draw_bar_graph(pic, font, r, d)
		"jug":
			_draw_jugs(pic, font, r, d)
		"dial_scale":
			_draw_dial_scale(pic, font, r, d)
		"ruler":
			_draw_ruler(pic, font, r, d)
		"cut_shape":
			_draw_cut_shape(pic, r, d)
		"unit_squares":
			_draw_unit_squares(pic, font, r, d)
		"side_lengths":
			_draw_side_lengths(pic, font, r, d)
		"fraction_plot":
			_draw_fraction_plot(pic, font, r, d)
		"bar_model":
			_draw_bar_model(pic, font, r, d)
		"digital_clock":
			_draw_digital_clock(pic, font, r, d)
		"times_grid":
			_draw_times_grid(pic, font, r, d)
		"fraction_wall":
			_draw_fraction_wall(pic, font, r, d)


# --- Shared facts (tests and generators use them too) -------------------------------------------------------------------

## A jug picture's jugs: its `jugs`, or the picture itself as one jug.
static func jugs_of(p: Dictionary) -> Array:
	if p.get("jugs") is Array:
		return (p.jugs as Array).filter(func(j: Variant) -> bool: return j is Dictionary)
	return [p] if p.has("top") else []


static func cut_way(p: Dictionary) -> String:
	var shape := str(p.get("shape", ""))
	if shape in ["circle", "hexagon", "triangle"]:
		return "sectors"
	return str(p.get("way", "strips"))


## A fraction plot's key in quarters: "2½" -> 10, "¾" -> 3, "3" -> 12; -1 when it is not a key.
static func quarters_of(key: String) -> int:
	var m := _plot_key.search(key)
	if m == null or key == "":
		return -1
	return int(m.get_string(1)) * 4 + int(QUARTERS[m.get_string(2)])


## A number of quarters as a plot's words: 10 -> "2½", 3 -> "¾", 12 -> "3".
static func quarter_text(q: int) -> String:
	var whole := int(q / 4.0)
	var rest := q % 4
	var sym := ""
	for k: String in QUARTERS:
		if int(QUARTERS[k]) == rest:
			sym = k
	return (str(whole) if whole > 0 or rest == 0 else "") + sym


## The corners of a side_lengths picture (unit coordinates, y down); [] when it has none.
static func side_points(p: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	if p.has("what"):
		var what := str(p.what)
		if ShapeFacts.knows(what) and what != "circle":
			return ShapeFacts.points(what)
		return out
	var pts: Variant = p.get("points")
	if not pts is Array:
		return out
	for q: Variant in pts:
		if not q is Array or (q as Array).size() != 2 or typeof(q[0]) not in [TYPE_INT, TYPE_FLOAT] \
				or typeof(q[1]) not in [TYPE_INT, TYPE_FLOAT] or float(q[0]) < 0 or float(q[0]) > 12 \
				or float(q[1]) < 0 or float(q[1]) > 12:
			return PackedVector2Array()
		out.append(Vector2(float(q[0]), float(q[1])))
	return out


## Each straight side of a unit_squares shape: {len (squares), mid (in squares, y down), out (the outside's direction)}.
static func square_sides(rows: Array) -> Array:
	var h := rows.size()
	var w := str(rows[0]).length()
	var filled := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and str(rows[y])[x] != "."
	var out: Array = []
	for y in h + 1:   # horizontal sides: between row y - 1 and row y
		var run := 0
		var side := 0
		for x in w + 1:
			var s := 0
			if x < w:
				var above: bool = filled.call(x, y - 1)
				var below: bool = filled.call(x, y)
				s = (1 if below else -1) if above != below else 0   # 1: the shape is below (a top side)
			if s != side or s == 0:
				if side != 0 and run > 0:
					out.append({"len": run, "mid": Vector2(x - run * 0.5, y), "out": Vector2(0, -side)})
				run = 0
			side = s
			if s != 0:
				run += 1
	for x in w + 1:   # vertical sides: between column x - 1 and column x
		var run := 0
		var side := 0
		for y in h + 1:
			var s := 0
			if y < h:
				var left: bool = filled.call(x - 1, y)
				var right: bool = filled.call(x, y)
				s = (1 if right else -1) if left != right else 0   # 1: the shape is to the right (a left side)
			if s != side or s == 0:
				if side != 0 and run > 0:
					out.append({"len": run, "mid": Vector2(x, y - run * 0.5), "out": Vector2(-side, 0)})
				run = 0
			side = s
			if s != 0:
				run += 1
	return out


# --- pictogram and bar_graph ----------------------------------------------------------------------------------------------

static func _draw_pictogram(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var each := _num(d, "each")
	var tex: Texture2D = BlockIcons.icon(_int(d, "block", 0)) if d.has("block") else null
	var key_h := 38.0
	var label_w := 0.0
	var fs := clampi(int((r.size.y - key_h) / rows.size() * 0.42), 13, 22)
	for row: Array in rows:
		label_w = maxf(label_w, font.get_string_size(str(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0)
	label_w = minf(label_w, r.size.x * 0.34)
	var rh := (r.size.y - key_h) / rows.size()
	var cell := minf(minf(rh * 0.78, (r.size.x - label_w - 16.0) / 10.5), 40.0)
	var x0 := r.position.x + label_w + 10.0
	for i in rows.size():
		var row: Array = rows[i]
		var y := r.position.y + rh * i
		if i > 0:
			ci.draw_line(Vector2(r.position.x, roundf(y)), Vector2(r.end.x, roundf(y)), GRID_LINE, 2.0)
		_label(ci, font, Vector2(r.position.x + label_w * 0.5, y + rh * 0.5), str(row[0]), fs)
		var n := float(row[1]) / each
		var whole := int(floorf(n + 0.001))
		for k in whole:
			_symbol(ci, tex, Rect2(x0 + k * cell * 1.05, y + (rh - cell) * 0.5, cell, cell), false)
		if n - whole > 0.25:
			_symbol(ci, tex, Rect2(x0 + whole * cell * 1.05, y + (rh - cell) * 0.5, cell, cell), true)
	ci.draw_line(Vector2(x0 - 6, r.position.y), Vector2(x0 - 6, r.end.y - key_h), INK, 2.0)
	var ky := r.end.y - key_h * 0.5
	var key_words := "= %s %s" % [_fmt(each), str(d.get("unit", ""))]
	var kw := font.get_string_size(key_words.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ks := minf(key_h - 8.0, 30.0)
	var kx := r.get_center().x - (ks + 8.0 + kw) * 0.5
	ci.draw_rect(Rect2(kx - 10, ky - key_h * 0.5 + 2, ks + kw + 28, key_h - 4), PALE_BLUE)
	_symbol(ci, tex, Rect2(kx, ky - ks * 0.5, ks, ks), false)
	_label(ci, font, Vector2(kx + ks + 8.0 + kw * 0.5, ky), key_words.strip_edges(), fs)


## One symbol of a pictogram (the block's icon, or a gold coin), or its left half.
static func _symbol(ci: CanvasItem, tex: Texture2D, box: Rect2, half: bool) -> void:
	if tex:
		if half:
			ci.draw_texture_rect_region(tex, Rect2(box.position, Vector2(box.size.x * 0.5, box.size.y)),
				Rect2(Vector2.ZERO, Vector2(tex.get_width() * 0.5, tex.get_height())))
		else:
			ci.draw_texture_rect(tex, box, false)
		return
	var c := box.get_center()
	var rad := box.size.x * 0.46
	if half:
		var pts := PackedVector2Array()
		for k in 17:
			var a := PI * 0.5 + PI * k / 16.0
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		ci.draw_colored_polygon(pts, GOLD)
		pts.append(pts[0])
		ci.draw_polyline(pts, INK, 2.0, true)
		return
	ci.draw_circle(c, rad, GOLD)
	ci.draw_arc(c, rad, 0, TAU, 28, INK, 2.0, true)
	ci.draw_arc(c, rad * 0.62, 0, TAU, 24, Color("c9971a"), 2.0, true)


static func _draw_bar_graph(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var bars: Array = d.bars
	var step := _int(d, "step", 1)
	var top := _int(d, "top", step)
	var n := int(top / float(step))
	var name := str(d.get("name", ""))
	var fs := clampi(int(r.size.y / 13.0), 13, 20)
	var left := font.get_string_size(_fmt(top), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 18.0
	var head := 12.0 + (fs + 8.0 if name != "" else 0.0)
	var plot := Rect2(r.position + Vector2(left, head), Vector2(r.size.x - left - 10.0, r.size.y - head - fs - 16.0))
	ci.draw_rect(plot, Color.WHITE)
	var every := maxi(1, ceili((fs + 2.0) / (plot.size.y / n)))   # small pictures: a number on every other line
	for i in n + 1:
		var y := plot.end.y - plot.size.y * i / n
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID_LINE, 1.5)
		if i % every != 0:
			continue
		var t := _fmt(i * step)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_label(ci, font, Vector2(plot.position.x - 8.0 - tw * 0.5, y), t, fs)
	var slot := plot.size.x / bars.size()
	var bw := minf(slot * 0.62, 80.0)
	for i in bars.size():
		var bar: Array = bars[i]
		var h := plot.size.y * float(bar[1]) / top
		var x := plot.position.x + slot * (i + 0.5)
		if h > 0.0:
			var rect := Rect2(x - bw * 0.5, plot.end.y - h, bw, h)
			ci.draw_rect(rect, BAR_COLORS[i % BAR_COLORS.size()])
			ci.draw_rect(rect, INK, false, 2.0)
		var words := str(bar[0])
		var lfs := fs
		while lfs > 11 and font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs).x > slot - 4.0:
			lfs -= 1
		_label(ci, font, Vector2(x, plot.end.y + fs * 0.5 + 8.0), words, lfs)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.5)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.5)
	if name != "":
		_label(ci, font, Vector2(r.get_center().x, r.position.y + 6.0 + fs * 0.5), name, fs, BLUE)


# --- jug, dial_scale and ruler -------------------------------------------------------------------------------------------

static func _draw_jugs(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var jugs := jugs_of(d)
	var step := _num(d, "step")
	var unit := str(d.get("unit", "L"))
	var minor := _int(d, "minor", 0)
	var fs := clampi(int(r.size.y / 14.0), 12, 19)
	var slot := r.size.x / jugs.size()
	for i in jugs.size():
		var j: Dictionary = jugs[i]
		var top := _num(j, "top")
		var fill := _num(j, "fill")
		var label := str(j.get("label", ""))
		var mark_w := font.get_string_size("%s %s" % [_fmt(top), unit], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 10.0
		var bottom := r.end.y - (fs + 12.0 if label != "" else 6.0)
		var body_h := bottom - r.position.y - 8.0
		var body_w := minf(slot - mark_w - 24.0, body_h * 0.7)
		var x := r.position.x + slot * i + (slot - body_w - mark_w) * 0.5
		var body := Rect2(x, bottom - body_h, body_w, body_h)
		var full := body_h * 0.86   # the top mark's height above the bottom
		var at := func(v: float) -> float: return bottom - full * v / top
		ci.draw_rect(body, Color(1, 1, 1, 0.8))
		if fill > 0.0:
			var wy: float = at.call(fill)
			ci.draw_rect(Rect2(body.position.x, wy, body_w, bottom - wy), Color(WATER, 0.85))
			ci.draw_line(Vector2(body.position.x, wy), Vector2(body.end.x, wy), Color("2f7fd8"), 2.0)
		var marks := roundi(top / step)
		for k in range(1, marks + 1):
			var y: float = at.call(k * step)
			ci.draw_line(Vector2(body.end.x - 18.0, y), Vector2(body.end.x, y), INK, 2.5)
			_label(ci, font, Vector2(body.end.x + 8.0 + (mark_w - 10.0) * 0.5, y), "%s %s" % [_fmt(k * step), unit], fs)
		for k in marks * (minor + 1):
			if k % (minor + 1) != 0:
				var y: float = at.call(k * step / (minor + 1))
				ci.draw_line(Vector2(body.end.x - 9.0, y), Vector2(body.end.x, y), INK, 1.5)
		ci.draw_polyline(PackedVector2Array([body.position - Vector2(10, 6), body.position, Vector2(body.position.x, bottom),
			Vector2(body.end.x, bottom), Vector2(body.end.x, body.position.y)]), INK, 3.0, true)
		ci.draw_arc(Vector2(body.position.x - 2, body.get_center().y), body_h * 0.18, PI * 0.5, PI * 1.5, 16, INK, 3.0, true)
		if label != "":
			_label(ci, font, Vector2(body.get_center().x, r.end.y - fs * 0.5 - 2.0), label, fs, BLUE)


static func _draw_dial_scale(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var top := _num(d, "top")
	var step := _num(d, "step")
	var minor := _int(d, "minor", 0)
	var thing := clampf(r.size.y * 0.14, 16.0, 40.0) if d.has("block") else 0.0   # the block on the plate
	var rad := minf(r.size.x * 0.4, (r.size.y - thing - 8.0 - 28.0) * 0.5)
	var c := Vector2(r.get_center().x, r.end.y - rad - 14.0)
	var sweep := TAU * 5.0 / 6.0   # 0 at the top, the top number five sixths round
	var angle := func(v: float) -> float: return -PI * 0.5 + sweep * v / top
	var case_rect := Rect2(c - Vector2(rad + 12.0, rad + 12.0), Vector2(rad + 12.0, rad + 12.0) * 2.0)
	ci.draw_rect(case_rect, Color("9fb4d8"))
	ci.draw_rect(case_rect, INK, false, 2.5)
	ci.draw_rect(Rect2(case_rect.position.x - 14.0, case_rect.position.y - 8.0, case_rect.size.x + 28.0, 8.0), INK)
	if d.has("block"):
		var tex := BlockIcons.icon(_int(d, "block", 0))
		var s := thing
		if tex:
			ci.draw_texture_rect(tex, Rect2(c.x - s * 0.5, case_rect.position.y - 8.0 - s, s, s), false)
	ci.draw_circle(c, rad, Color.WHITE)
	ci.draw_arc(c, rad, 0, TAU, 64, INK, 3.0, true)
	var marks := roundi(top / step)
	var longest := _fmt(top).length()
	var fs := clampi(int(rad * (0.22 if longest <= 2 else (0.18 if longest == 3 else 0.16)) * (1.0 if marks <= 10 else 0.9)), 11, 20)
	for k in marks * (minor + 1) + 1:
		var a: float = angle.call(step * k / (minor + 1))
		var dir := Vector2(cos(a), sin(a))
		var big := k % (minor + 1) == 0
		ci.draw_line(c + dir * rad * (0.8 if big else 0.88), c + dir * rad * 0.97, INK, 2.5 if big else 1.5)
		if big:
			_label(ci, font, c + dir * rad * 0.64, _fmt(step * k / (minor + 1)), fs)
	var needle: float = angle.call(_num(d, "value"))
	ci.draw_line(c, c + Vector2(cos(needle), sin(needle)) * rad * 0.86, RED, 4.0, true)
	ci.draw_circle(c, 6.0, INK)
	_label(ci, font, c + Vector2(0, -rad * 0.3), str(d.unit), fs + 2, BLUE)


static func _draw_ruler(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var to := _int(d, "to", 10)
	var from := NumberAnswer.value(str(d.get("from", "0")))
	var length := NumberAnswer.value(str(d.get("length", "1")))
	var mm := bool(d.get("mm", false))
	var body := Rect2(r.position.x + 6.0, r.get_center().y + 4.0, r.size.x - 12.0, minf(r.size.y * 0.4, 76.0))
	var x0 := body.position.x + 18.0
	var cm := (body.size.x - 74.0) / to   # room after the last mark for "cm"
	var fs := clampi(int(minf(cm * 0.5, body.size.y * 0.3)), 11, 20)
	ci.draw_rect(body, Color("fbe9a6"))
	ci.draw_rect(body, INK, false, 2.0)
	var ticks := to * (10 if mm else 2)
	for k in ticks + 1:
		var x := x0 + cm * k / (10.0 if mm else 2.0)
		var whole := k % (10 if mm else 2) == 0
		var half := mm and k % 5 == 0
		var h := body.size.y * (0.42 if whole else (0.3 if half else 0.18)) if mm else body.size.y * (0.42 if whole else 0.28)
		ci.draw_line(Vector2(x, body.position.y), Vector2(x, body.position.y + h), INK, 2.0 if whole else 1.2)
		if whole:
			_label(ci, font, Vector2(x, body.position.y + body.size.y * 0.72), str(roundi(k / (10.0 if mm else 2.0))), fs)
	_label(ci, font, Vector2((x0 + cm * to + body.end.x) * 0.5 + 6.0, body.position.y + body.size.y * 0.72), "cm", fs - 2, BLUE)
	var sx := x0 + cm * from
	var ex := x0 + cm * (from + length)
	var stick := Rect2(sx, body.position.y - 34.0, ex - sx, 24.0)
	ci.draw_rect(stick, SHADE)
	ci.draw_rect(stick, INK, false, 2.0)
	for x: float in [sx, ex]:
		ci.draw_dashed_line(Vector2(x, stick.end.y), Vector2(x, body.position.y), INK, 1.5, 4.0)


# --- cut_shape -----------------------------------------------------------------------------------------------------------

## The parts of a cut_shape picture as polygons in `box` (the first ones are the shaded ones).
static func cut_parts(d: Dictionary, box: Rect2) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var shape := str(d.shape)
	var parts := _int(d, "parts", 1)
	var unequal := bool(d.get("unequal", false))
	var way := cut_way(d)
	var weights: Array[float] = []
	var total := 0.0
	for k in parts:
		weights.append(UNEVEN[k % UNEVEN.size()] if unequal else 1.0)
		total += weights[k]
	match shape:
		"circle":
			var c := box.get_center()
			var rad := minf(box.size.x, box.size.y) * 0.5
			var a := -PI * 0.5
			for k in parts:
				var sweep := TAU * weights[k] / total
				var poly := PackedVector2Array([c]) if parts > 1 else PackedVector2Array()
				var steps := maxi(4, int(48.0 * sweep / TAU))
				for s in steps + 1:
					var t := a + sweep * s / steps
					poly.append(c + Vector2(cos(t), sin(t)) * rad)
				out.append(poly)
				a += sweep
		"square", "rectangle":
			if way == "strips":
				var x := box.position.x
				for k in parts:
					var w := box.size.x * weights[k] / total
					out.append(_quad(Rect2(x, box.position.y, w, box.size.y)))
					x += w
			elif way == "grid":
				var g: Vector2i = GRID_CUTS[parts]
				var cell := box.size / Vector2(g)
				for y in g.y:
					for x in g.x:
						out.append(_quad(Rect2(box.position + cell * Vector2(x, y), cell)))
			else:   # diagonals
				var tl := box.position
				var tr := Vector2(box.end.x, box.position.y)
				var br := box.end
				var bl := Vector2(box.position.x, box.end.y)
				if parts == 2:
					out.append(PackedVector2Array([tl, tr, bl]))
					out.append(PackedVector2Array([tr, br, bl]))
				else:
					var c := box.get_center()
					for pair: Array in [[tl, tr], [tr, br], [br, bl], [bl, tl]]:
						out.append(PackedVector2Array([c, pair[0], pair[1]]))
		"hexagon":
			var pts := _fit(ShapeFacts.points("hexagon"), box)
			var c := box.get_center()
			if parts == 6:
				for k in 6:
					out.append(PackedVector2Array([c, pts[k], pts[(k + 1) % 6]]))
			elif parts == 3:
				for k in 3:
					out.append(PackedVector2Array([c, pts[2 * k], pts[2 * k + 1], pts[(2 * k + 2) % 6]]))
			else:
				out.append(PackedVector2Array([pts[0], pts[1], pts[2], pts[3]]))
				out.append(PackedVector2Array([pts[3], pts[4], pts[5], pts[0]]))
		"triangle":
			var pts := _fit(ShapeFacts.points("triangle_equal"), box)
			var a := pts[0]
			var b := pts[1]
			var c := pts[2]
			if parts == 2:
				var m := (b + c) * 0.5
				out.append(PackedVector2Array([a, b, m]))
				out.append(PackedVector2Array([a, m, c]))
			elif parts == 3:
				var g := (a + b + c) / 3.0
				out.append(PackedVector2Array([g, a, b]))
				out.append(PackedVector2Array([g, b, c]))
				out.append(PackedVector2Array([g, c, a]))
			else:
				var ab := (a + b) * 0.5
				var bc := (b + c) * 0.5
				var ca := (c + a) * 0.5
				out.append(PackedVector2Array([a, ab, ca]))
				out.append(PackedVector2Array([ab, b, bc]))
				out.append(PackedVector2Array([ca, bc, c]))
				out.append(PackedVector2Array([ab, bc, ca]))
	return out


static func _draw_cut_shape(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var side := minf(r.size.x, r.size.y) * 0.9
	var size := Vector2(side, side)
	if str(d.shape) == "rectangle":
		size = Vector2(minf(r.size.x * 0.9, side * 1.7), side * 0.8)
	var box := Rect2(r.get_center() - size * 0.5, size)
	var polys := cut_parts(d, box)
	var shade := _int(d, "shade", 0)
	for k in polys.size():
		ci.draw_colored_polygon(polys[k], SHADE if k < shade else Color.WHITE)
	for poly in polys:
		var loop := poly.duplicate()
		loop.append(poly[0])
		ci.draw_polyline(loop, INK, 3.0, true)


# --- unit_squares and side_lengths ----------------------------------------------------------------------------------------

static func _draw_unit_squares(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var h := rows.size()
	var w := str(rows[0]).length()
	var labels := bool(d.get("labels", false))
	var grid := bool(d.get("grid", true))
	var pad := Vector2(52.0, 34.0) if labels else Vector2(6.0, 6.0)
	var cell := minf(minf((r.size.x - 2.0 * pad.x) / w, (r.size.y - 2.0 * pad.y) / h), 44.0)
	var o := r.get_center() - Vector2(w, h) * cell * 0.5
	for y in h:
		for x in w:
			var ch := str(rows[y])[x]
			if ch == ".":
				continue
			var rect := Rect2(o + Vector2(x, y) * cell, Vector2(cell, cell))
			ci.draw_rect(rect, SQUARE_COLORS[ch])
			if grid:
				ci.draw_rect(rect, Color(INK, 0.45), false, 1.5)
	var sides := square_sides(rows)
	for s: Dictionary in sides:
		var mid: Vector2 = s.mid
		var along := Vector2(absf((s.out as Vector2).y), absf((s.out as Vector2).x)) * float(s.len) * 0.5
		ci.draw_line(o + (mid - along) * cell, o + (mid + along) * cell, INK, 3.0, true)
	if labels:
		var per := _int(d, "per", 1)
		var unit := str(d.get("unit", ""))
		var fs := clampi(int(cell * 0.5), 13, 20)
		for s: Dictionary in sides:
			var words := ("%s %s" % [_fmt(int(s.len) * per), unit]).strip_edges()
			var tw := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var out: Vector2 = s.out
			var at := o + (s.mid as Vector2) * cell + out * (fs * 0.9 if out.y != 0 else tw * 0.5 + 8.0)
			_label(ci, font, at, words, fs)


static func _draw_side_lengths(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var pts := _fit(side_points(d), r.grow(-clampf(minf(r.size.x, r.size.y) * 0.2, 16.0, 44.0)))
	var labels: Array = d.labels
	ci.draw_colored_polygon(pts, SOFT)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, INK, 3.0, true)
	var fs := clampi(int(minf(r.size.x, r.size.y) * 0.08), 12, 19)
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var mid := (a + b) * 0.5
		var n := (b - a).orthogonal().normalized()
		if Geometry2D.is_point_in_polygon(mid + n * 4.0, pts):
			n = -n
		var words := str(labels[i])
		var tw := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var reach := 12.0 + absf(n.x) * tw * 0.5 + absf(n.y) * fs * 0.5
		_label(ci, font, mid + n * reach, words, fs, SHADE if words == "?" else INK)


## Points (any units) scaled into `box`, keeping their shape, centred.
static func _fit(pts: PackedVector2Array, box: Rect2) -> PackedVector2Array:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var k := minf(box.size.x / maxf(hi.x - lo.x, 0.01), box.size.y / maxf(hi.y - lo.y, 0.01))
	var offset := box.get_center() - (lo + hi) * 0.5 * k
	var out := PackedVector2Array()
	for p in pts:
		out.append(offset + p * k)
	return out


static func _quad(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)])


# --- fraction_plot, bar_model -------------------------------------------------------------------------------------------

static func _draw_fraction_plot(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var from := _int(d, "from", 0)
	var to := _int(d, "to", 1)
	var parts := _int(d, "parts", 1)
	var n := (to - from) * parts
	var unit := str(d.get("unit", ""))
	var y := r.end.y - (58.0 if unit != "" else 40.0)
	var x0 := r.position.x + 30.0
	var x1 := r.end.x - 30.0
	var fs := 20 if n <= 8 else 17
	ci.draw_line(Vector2(x0 - 14, y), Vector2(x1 + 14, y), INK, 3.0)
	var counts := {}
	for k: Variant in d.counts:
		counts[quarters_of(str(k))] = int(d.counts[k])
	var xs := (y - r.position.y - 10.0) / 8.0
	for i in n + 1:
		var q := from * 4 + i * int(4.0 / parts)
		var x := x0 + (x1 - x0) * i / n
		var whole := q % 4 == 0
		ci.draw_line(Vector2(x, y - (10 if whole else 6)), Vector2(x, y + (10 if whole else 6)), INK, 2.0)
		if whole or q % 2 == 0 or n <= 12:
			_label(ci, font, Vector2(x, y + 24.0), quarter_text(q), fs if whole else fs - 3)
		for j in int(counts.get(q, 0)):
			_label(ci, font, Vector2(x, y - 20.0 - j * minf(xs, 24.0)), "X", fs, BLUE)
	if unit != "":
		_label(ci, font, Vector2((x0 + x1) * 0.5, r.end.y - 12.0), unit, fs - 2, BLUE)


static func _draw_bar_model(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var bars: Array = d.bars
	var name_w := 0.0
	var fs := 19
	for b: Dictionary in bars:
		if str(b.get("name", "")) != "":
			name_w = maxf(name_w, font.get_string_size(str(b.name), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16.0)
	var longest := 0.0
	for b: Dictionary in bars:
		longest = maxf(longest, _bar_length(b))
	var x0 := r.position.x + name_w + 8.0
	var px := (r.end.x - 10.0 - x0) / longest
	var row := r.size.y / bars.size()
	var bh := minf(row * 0.42, 50.0)
	var ends: Array[float] = []
	var ys: Array[float] = []
	for i in bars.size():
		var b: Dictionary = bars[i]
		var y := r.position.y + row * i + row - bh - 8.0
		if str(b.get("name", "")) != "":
			_label(ci, font, Vector2(r.position.x + name_w * 0.5, y + bh * 0.5), str(b.name), fs)
		var x := x0
		for k in (b.parts as Array).size():
			var part: Dictionary = b.parts[k]
			var w := _num(part, "size") * px
			var rect := Rect2(x, y, w, bh)
			ci.draw_rect(rect, PALE_BLUE if i % 2 == 0 else SOFT)
			ci.draw_rect(rect, INK, false, 2.5)
			var words := str(part.get("text", ""))
			var pfs := fs
			while pfs > 11 and font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs).x > w - 4.0:
				pfs -= 1
			_label(ci, font, rect.get_center(), words, pfs, SHADE if words == "?" else INK)
			x += w
		ends.append(x)
		ys.append(y)
		if str(b.get("total", "")) != "":
			var by := y - 10.0
			ci.draw_line(Vector2(x0, by), Vector2(x, by), BLUE, 2.5)
			ci.draw_line(Vector2(x0, by), Vector2(x0, by + 8.0), BLUE, 2.5)
			ci.draw_line(Vector2(x, by), Vector2(x, by + 8.0), BLUE, 2.5)
			_label(ci, font, Vector2((x0 + x) * 0.5, by - fs * 0.6 - 2.0), str(b.total), fs, SHADE if str(b.total) == "?" else BLUE)
	if d.has("diff") and bars.size() == 2:
		var short := 0 if ends[0] < ends[1] else 1
		var gap := Rect2(ends[short], ys[short], ends[1 - short] - ends[short], bh)
		if gap.size.x > 1.0:
			for side: Array in [[gap.position, Vector2(gap.end.x, gap.position.y)], [Vector2(gap.end.x, gap.position.y), gap.end],
					[gap.end, Vector2(gap.position.x, gap.end.y)]]:
				ci.draw_dashed_line(side[0], side[1], RED, 2.5, 8.0)
			_label(ci, font, gap.get_center(), str(d.diff), fs, SHADE if str(d.diff) == "?" else RED)


static func _bar_length(b: Dictionary) -> float:
	var total := 0.0
	for part: Dictionary in b.parts:
		total += _num(part, "size")
	return total


# --- digital_clock and times_grid -------------------------------------------------------------------------------------------

static func _draw_digital_clock(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var h := _int(d, "h", 0)
	var m := _int(d, "m", 0)
	var words := ("%d:%02d" % [(h + 11) % 12 + 1, m]) if bool(d.get("twelve", false)) else "%02d:%02d" % [h, m]
	var size := Vector2(minf(r.size.x * 0.66, 320.0), minf(r.size.y * 0.62, 130.0))
	var box := Rect2(r.get_center() - size * 0.5, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("23303f")
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(5)
	sb.border_color = Color("8d9bb0")
	ci.draw_style_box(sb, box)
	_label(ci, font, box.get_center(), words, int(size.y * 0.6), Color("7cf2a4"))


static func _draw_times_grid(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows := _int(d, "rows", 1)
	var cols := _int(d, "cols", 1)
	var r0 := _int(d, "r0", 1)
	var c0 := _int(d, "c0", 1)
	var op := str(d.get("op", "×"))
	var hidden := {}
	for cell: Array in d.get("hide", []):
		hidden[Vector2i(int(cell[1]), int(cell[0]))] = true
	var shade_row := _int(d, "shade_row", -1)
	var shade_col := _int(d, "shade_col", -1)
	var cw := minf(r.size.x / (cols + 1), 64.0)
	var ch := minf(r.size.y / (rows + 1), 46.0)
	var o := r.get_center() - Vector2(cw * (cols + 1), ch * (rows + 1)) * 0.5
	var fs := clampi(int(minf(cw * 0.42, ch * 0.62)), 10, 22)
	for y in rows + 1:
		for x in cols + 1:
			var rect := Rect2(o + Vector2(x * cw, y * ch), Vector2(cw, ch))
			var rn := r0 + y - 1
			var cn := c0 + x - 1
			var head := x == 0 or y == 0
			var fill := PALE_BLUE if head else Color.WHITE
			if not head and (rn == shade_row or cn == shade_col):
				fill = SOFT
			ci.draw_rect(rect, fill)
			ci.draw_rect(rect, Color(INK, 0.6), false, 1.5)
			var words := ""
			var color := INK
			if x == 0 and y == 0:
				words = op
				color = BLUE
			elif y == 0:
				words = str(cn)
			elif x == 0:
				words = str(rn)
			elif hidden.has(Vector2i(cn, rn)):
				words = "?"
				color = SHADE
			else:
				words = str(rn * cn if op == "×" else rn + cn)
			_label(ci, font, rect.get_center(), words, fs, color)


static func _draw_fraction_wall(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var labels := bool(d.get("labels", false))
	var label_w := 76.0 if labels else 0.0
	var h := minf(r.size.y / rows.size(), 72.0)
	var y := r.position.y + (r.size.y - h * rows.size()) * 0.5
	for row: Dictionary in rows:
		var den := _int(row, "den", 1)
		var shade := _int(row, "shade", 0)
		var bar := Rect2(r.position.x + label_w, y + 5.0, r.size.x - label_w, h - 10.0)
		var w := bar.size.x / den
		for k in den:
			var cell := Rect2(bar.position + Vector2(k * w, 0), Vector2(w, bar.size.y))
			ci.draw_rect(cell, SHADE if k < shade else Color.WHITE)
			ci.draw_rect(cell, INK, false, 2.0)
		if labels:
			_label(ci, font, Vector2(r.position.x + label_w * 0.5, y + h * 0.5), "%d/%d" % [shade, den], 22)
		y += h


# --- Helpers ---------------------------------------------------------------------------------------------------------

static func _label(ci: CanvasItem, font: Font, c: Vector2, text: String, size: int, color: Color = INK) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := c.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	ci.draw_string(font, Vector2(c.x - w * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## A number as the pictures write it: whole numbers with commas ("1,000"), others as they are ("2.5").
static func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0001:
		return GenKit.fmt(roundi(v))
	return String.num(v, 2)


## [label, value] pairs, 1 to `most`.
static func _pairs_ok(rows: Variant, most: int) -> bool:
	if not rows is Array or not _in((rows as Array).size(), 1, most):
		return false
	for row: Variant in rows:
		if not row is Array or (row as Array).size() != 2 or typeof(row[1]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	return true


## A field as a number: a JSON number, or text NumberAnswer reads ("2.5", "5/2"); NAN when neither.
static func _num(p: Dictionary, key: String) -> float:
	var v: Variant = p.get(key)
	if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
		return float(v)
	if v is String:
		return NumberAnswer.value(v)
	return NAN


static func _int(p: Dictionary, key: String, default: int) -> int:
	var v: Variant = p.get(key, default)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _in(v: int, lo: int, hi: int) -> bool:
	return v >= lo and v <= hi
