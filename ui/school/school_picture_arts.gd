class_name SchoolPictureArts
extends RefCounted
## Owner #70 and #73, grade 3 computing, art and music (research §6.3): the picture kinds they add, drawn from data onto
## a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the font has
## no music signs or arrows, so they are drawn). Kinds and fields:
## - swatches {items: [text] (1-8), names? (true), shape? ("square", "circle", "triangle")}: paint patches in a row; an
##   item is a colour of COLOURS, maybe with a shape after it ("red circle"), or "+", "=" or "?" (an empty patch to
##   fill); `names` writes each colour's name under its patch (false when the name would give the answer away).
## - notation {beats: [text] (1-8 beats in all), words? (false), bars? (false), time? ("2/4", "3/4", "4/4")}: a rhythm on
##   one line: "crotchet" (1 beat, "ta"), "quavers" (two joined, 1 beat, "ti-ti"), "rest" (a crotchet rest, 1 beat),
##   "minim" (2 beats, "ta-a"), "dotted minim" (3 beats, "ta-a-a"), "semibreve" (4 beats, "ta-a-a-a") or "?" (a beat to
##   find); `words` writes the rhythm names under the notes, `bars` a bar line every 4 beats (every bar of `time`, whose
##   time signature is drawn at the start: grade 4).
## - melody {notes: [text] (2-12: SchoolSound note names, "-" a rest; 2 notes at least), mark? (a note's index)}: a
##   tune's shape: a dot for each note, higher for a higher note, joined in order (a rest leaves a gap); `mark` shows one
##   note in orange.
## - robot {cols, rows (2-8), start: [x, y], facing? ("N", "E", "S", "W"), goal?, gems?, walls?, path?}: a "code the
##   robot" board (RobotCheck's fields; x from the left, y from the top, both from 0) drawn as RobotAnswer draws it: the
##   robot (a pointer shows the way it faces), a flag at `goal`, `gems` and `walls` lists of squares, and `path` (squares
##   in order, each next to the one before) as the robot's trail.
## - marks {what: a MARKS name or 1-4 of them, names? (false)}: the marks an artist makes: kinds of line and textures
##   (hatching, cross-hatching, stippling, scribble), side by side, each named under it when `names`.

const KINDS: Array[String] = ["swatches", "notation", "melody", "robot", "marks"]
## Paint colours as the lessons name them (ColourMix's names: lilac, cream). A tint is a colour with white mixed in
## (TINTS), a shade one with black (SHADES); brown is what the three primaries make mixed together.
const COLOURS := {
	"red": Color("e03a2f"), "yellow": Color("f7d21e"), "blue": Color("2f6fdc"),
	"orange": Color("f28a1c"), "green": Color("3aa845"), "purple": Color("8a3fb8"),
	"white": Color(1, 1, 1), "black": Color(0, 0, 0), "grey": Color("8c8c8c"), "brown": Color("7a4a24"),
	"pink": Color("f7aaa6"), "light blue": Color("a4c6f6"), "light green": Color("aee3b0"),
	"lilac": Color("d4b0ea"), "cream": Color("fdf3b8"), "light orange": Color("fbcb96"),
	"light grey": Color("cfcfcf"),
	"dark red": Color("851b15"), "dark blue": Color("172f6b"), "dark green": Color("1b5222"),
	"dark purple": Color("45205e"), "dark yellow": Color("8f7a0c"), "dark orange": Color("9a4d0b"),
	"dark grey": Color("454545"),
	# grade 4: the tertiary colours of the painters' wheel (ColourMix: 2 of the named primary, 1 of the other)
	"red-orange": Color("ea5a22"), "yellow-orange": Color("f5ae1f"), "yellow-green": Color("9cc93a"),
	"blue-green": Color("1f9e9a"), "blue-purple": Color("5a4fc4"), "red-purple": Color("b0306f"),
}
const TINTS := {"pink": "red", "light blue": "blue", "light green": "green", "lilac": "purple", "cream": "yellow",
	"light orange": "orange", "light grey": "grey"}
const SHADES := {"dark red": "red", "dark blue": "blue", "dark green": "green", "dark purple": "purple",
	"dark yellow": "yellow", "dark orange": "orange", "dark grey": "grey"}
const SHAPES: Array[String] = ["square", "circle", "triangle"]
const SYMBOLS: Array[String] = ["+", "=", "?"]
const MAX_SWATCHES := 8
## Rhythm signs and their beats; the words children say for them (the Kodaly names many schools use).
const NOTE_BEATS := {"crotchet": 1, "quavers": 1, "rest": 1, "minim": 2, "dotted minim": 3, "semibreve": 4, "?": 1}
const NOTE_WORDS := {"crotchet": "ta", "quavers": "ti-ti", "rest": "rest", "minim": "ta-a", "dotted minim": "ta-a-a",
	"semibreve": "ta-a-a-a", "?": "?"}
## Time signatures (grade 4): beats in a bar over the crotchet.
const TIMES := {"2/4": 2, "3/4": 3, "4/4": 4}
const MAX_BEATS := 8
const MAX_TUNE := 12
const HEADINGS := {"N": Vector2.UP, "E": Vector2.RIGHT, "S": Vector2.DOWN, "W": Vector2.LEFT}
const MAX_ROBOT_GRID := 8
const MARKS: Array[String] = ["straight", "curved", "zigzag", "wavy", "spiral", "loops", "dotted", "dashed", "thick",
	"thin", "hatching", "cross-hatching", "stippling", "scribble"]
const MAX_MARKS := 4
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const BLUE := Color("3a7be8")
const SOFT := Color("fce2b8")
## The robot board's look (RobotAnswer's): the same robot, walls, gems and flag in pictures and in the answer.
const ROBOT := Color("5b6b8a")
const POINTER := Color("ffd23f")
const GEM := Color("2fc7e0")
const WALL := Color("8a5a3a")
const WALL_TOP := Color("a8744c")
const FLAG := Color("e8413b")
const POLE := Color("444444")
const TRAIL := Color(0.2, 0.55, 0.95, 0.8)
const BOARD := Color("fdf6e3")
const BOARD_LINE := Color(0.3, 0.3, 0.4, 0.5)
const GRID_LINE := Color("b9c6dd")


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"swatches":
			var items: Variant = p.get("items")
			if not items is Array or (items as Array).is_empty() or (items as Array).size() > MAX_SWATCHES:
				return "swatches: 1-%d items" % MAX_SWATCHES
			for it: Variant in items:
				if not it is String or (not SYMBOLS.has(it) and swatch(it).is_empty()):
					return "swatches: '%s' is not a colour (maybe with a shape), + , = or ?" % [it]
			if p.has("shape") and not SHAPES.has(str(p.shape)):
				return "swatches: shape is one of %s" % [SHAPES]
		"notation":
			var beats: Variant = p.get("beats")
			if not beats is Array or (beats as Array).is_empty():
				return "notation: 1-%d beats" % MAX_BEATS
			for b: Variant in beats:
				if not b is String or not NOTE_BEATS.has(b):
					return "notation: '%s' is not one of %s" % [b, NOTE_BEATS.keys()]
			if beats_of(beats) > MAX_BEATS:
				return "notation: at most %d beats" % MAX_BEATS
			if p.has("time") and not TIMES.has(str(p.time)):
				return "notation: time is one of %s" % [TIMES.keys()]
		"melody":
			var notes: Variant = p.get("notes")
			if not notes is Array or (notes as Array).size() < 2 or (notes as Array).size() > MAX_TUNE:
				return "melody: 2-%d notes" % MAX_TUNE
			var sounding := 0
			for n: Variant in notes:
				if not n is String or (n != "-" and SchoolSound.frequency(n) <= 0.0):
					return "melody: '%s' is not a note (C4, F#3) or - for a rest" % [n]
				if n != "-":
					sounding += 1
			if sounding < 2:
				return "melody: at least 2 notes"
			if p.has("mark"):
				var m := _int(p, "mark", -1)
				if not _in(m, 0, (notes as Array).size() - 1) or str(notes[m]) == "-":
					return "melody: mark is a note's index"
		"robot":
			var cols := _int(p, "cols", 0)
			var rows := _int(p, "rows", 0)
			if not _in(cols, 2, MAX_ROBOT_GRID) or not _in(rows, 2, MAX_ROBOT_GRID):
				return "robot: cols and rows 2-%d" % MAX_ROBOT_GRID
			var size := Vector2i(cols, rows)
			if not _cell_ok(p.get("start"), size):
				return "robot: start is a square [x, y] on the grid"
			if p.has("goal") and not _cell_ok(p.goal, size):
				return "robot: goal is a square [x, y] on the grid"
			if p.has("facing") and not HEADINGS.has(str(p.facing)):
				return "robot: facing is one of %s" % [HEADINGS.keys()]
			for k: String in ["gems", "walls", "path"]:
				var cells: Variant = p.get(k, [])
				if not cells is Array or (cells as Array).size() > cols * rows:
					return "robot: %s is a list of squares" % k
				for c: Variant in cells:
					if not _cell_ok(c, size):
						return "robot: %s has a square off the grid: %s" % [k, c]
			var walls := {}
			for w: Variant in p.get("walls", []):
				walls[_cell(w)] = true
			for k: String in ["start", "goal"]:
				if p.has(k) and walls.has(_cell(p[k])):
					return "robot: the %s is on a wall" % k
			for g: Variant in p.get("gems", []):
				if walls.has(_cell(g)):
					return "robot: a gem on a wall"
			var path: Array = p.get("path", [])
			for i in range(1, path.size()):
				var step := _cell(path[i]) - _cell(path[i - 1])
				if absi(step.x) + absi(step.y) != 1:
					return "robot: each square of the path is next to the one before"
				if walls.has(_cell(path[i])):
					return "robot: the path goes through a wall"
		"marks":
			var what := marks_of(p)
			if what.is_empty() or what.size() > MAX_MARKS:
				return "marks: what is 1-%d of %s" % [MAX_MARKS, MARKS]
			for m in what:
				if not MARKS.has(m):
					return "marks: '%s' is not one of %s" % [m, MARKS]
		_:
			return "not an arts kind"
	return ""


## A swatch item's colour and shape: {colour, shape} ({} when it is not a colour, maybe with a shape after it).
static func swatch(item: String) -> Dictionary:
	if COLOURS.has(item):
		return {"colour": item, "shape": ""}
	var at := item.rfind(" ")
	if at > 0 and SHAPES.has(item.substr(at + 1)) and COLOURS.has(item.substr(0, at)):
		return {"colour": item.substr(0, at), "shape": item.substr(at + 1)}
	return {}


## Beats a rhythm lasts (NOTE_BEATS).
static func beats_of(beats: Array) -> int:
	var n := 0
	for b: Variant in beats:
		n += int(NOTE_BEATS.get(str(b), 0))
	return n


## The marks a picture shows, as a list.
static func marks_of(p: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var what: Variant = p.get("what")
	if what is String:
		out.append(what)
	elif what is Array:
		for m: Variant in what:
			out.append(str(m))
	return out


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"swatches":
			_draw_swatches(pic, font, r, d)
		"notation":
			_draw_notation(pic, font, r, d)
		"melody":
			_draw_melody(pic, r, d)
		"robot":
			_draw_robot(pic, r, d)
		"marks":
			_draw_marks(pic, font, r, d)


# --- swatches --------------------------------------------------------------------------------------------------------

static func _draw_swatches(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var items: Array = d.items
	var names := bool(d.get("names", true))
	var units := 0.0
	for it: Variant in items:
		units += 0.55 if str(it) in ["+", "="] else 1.0
	var fs := clampi(int(r.size.y * 0.13), 12, 22)
	var name_h := fs * 1.5 if names else 0.0
	var unit := minf(r.size.x / units, (r.size.y - name_h) / 0.95)
	var side := unit * 0.8
	var x := r.position.x + (r.size.x - unit * units) * 0.5
	var cy := r.position.y + (r.size.y - name_h) * 0.5
	for it: Variant in items:
		var t := str(it)
		if t in ["+", "="]:
			_label(ci, font, Vector2(x + unit * 0.275, cy), t, clampi(int(side * 0.6), 14, 48))
			x += unit * 0.55
			continue
		var box := Rect2(Vector2(x + (unit - side) * 0.5, cy - side * 0.5), Vector2(side, side))
		if t == "?":
			_dashed_rect(ci, box, INK)
			_label(ci, font, box.get_center(), "?", clampi(int(side * 0.55), 14, 48), SHADE)
		else:
			var s := swatch(t)
			var shape: String = s.shape if s.shape != "" else str(d.get("shape", "square"))
			_patch(ci, box, COLOURS[s.colour], shape)
			if names:
				_label(ci, font, Vector2(box.get_center().x, box.end.y + name_h * 0.5), str(s.colour), _fit(font,
					str(s.colour), fs, unit - 4.0))
		x += unit


static func _patch(ci: CanvasItem, box: Rect2, colour: Color, shape: String) -> void:
	match shape:
		"circle":
			ci.draw_circle(box.get_center(), box.size.x * 0.5, colour)
			ci.draw_arc(box.get_center(), box.size.x * 0.5, 0.0, TAU, 40, INK, 2.0, true)
		"triangle":
			var pts := PackedVector2Array([Vector2(box.get_center().x, box.position.y), box.end,
				Vector2(box.position.x, box.end.y)])
			ci.draw_colored_polygon(pts, colour)
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, 2.0, true)
		_:
			var sb := StyleBoxFlat.new()
			sb.bg_color = colour
			sb.set_corner_radius_all(int(box.size.x * 0.12))
			sb.set_border_width_all(2)
			sb.border_color = INK
			ci.draw_style_box(sb, box)


# --- notation --------------------------------------------------------------------------------------------------------

static func _draw_notation(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var beats: Array = d.beats
	var total := beats_of(beats)
	var words := bool(d.get("words", false))
	var bars := bool(d.get("bars", false))
	var time := str(d.get("time", ""))
	var per_bar := int(TIMES.get(time, 4))
	var lead := 0.9 if time != "" else 0.0   # room for the time signature, in beats
	var fs := clampi(int(r.size.y * 0.13), 12, 24)
	var word_h := fs * 1.6 if words else 0.0
	var bw := minf(r.size.x / (total + 0.6 + lead), (r.size.y - word_h) * 0.75)   # one beat's width
	var x0 := r.position.x + (r.size.x - bw * (total + 0.6 + lead)) * 0.5 + bw * (0.3 + lead)
	var h := minf(r.size.y - word_h, bw * 1.4)   # a note's height with its stem
	var line_y := r.position.y + (r.size.y - word_h) * 0.5 + h * 0.32
	var head := Vector2(bw * 0.2, bw * 0.14)
	var stem := h * 0.72
	var lw := maxf(1.5, bw * 0.045)
	ci.draw_line(Vector2(x0 - bw * 0.2, line_y), Vector2(x0 + bw * total + bw * 0.1, line_y), GRID_LINE, lw)
	if time != "":   # the time signature: beats in a bar over the crotchet's 4
		var tx := x0 - bw * 0.55
		var tfs := clampi(int(h * 0.42), 12, 44)
		_label(ci, font, Vector2(tx, line_y - h * 0.52), time.get_slice("/", 0), tfs)
		_label(ci, font, Vector2(tx, line_y - h * 0.08), time.get_slice("/", 1), tfs)
	var at := 0
	for b: Variant in beats:
		var kind := str(b)
		var n := int(NOTE_BEATS[kind])
		var cx := x0 + (at + 0.5) * bw
		match kind:
			"crotchet":
				_note(ci, Vector2(cx, line_y), head, stem, lw, true)
			"minim":
				_note(ci, Vector2(x0 + (at + 1.0) * bw, line_y), head, stem, lw, false)
			"dotted minim":
				var mc := Vector2(x0 + (at + 1.3) * bw, line_y)
				_note(ci, mc, head, stem, lw, false)
				ci.draw_circle(mc + Vector2(head.x * 2.0, -head.y * 0.2), maxf(2.0, head.y * 0.35), INK)
			"semibreve":   # an open head, a little wider, and no stem
				var sc := Vector2(x0 + (at + 2.0) * bw, line_y)
				var ring := PackedVector2Array()
				for i in 25:
					var t := TAU * i / 24.0
					ring.append(sc + Vector2(cos(t) * head.x * 1.25, sin(t) * head.y * 1.1).rotated(-0.2))
				ci.draw_polyline(ring, INK, lw * 1.6, true)
			"quavers":
				var a := Vector2(cx - bw * 0.22, line_y)
				var c := Vector2(cx + bw * 0.22, line_y)
				_note(ci, a, head * 0.9, stem, lw, true)
				_note(ci, c, head * 0.9, stem, lw, true)
				var sa := a + Vector2(head.x * 0.9 * 0.85, -stem)
				var sc := c + Vector2(head.x * 0.9 * 0.85, -stem)
				ci.draw_colored_polygon(PackedVector2Array([sa - Vector2(lw * 0.5, 0), sc + Vector2(lw * 0.5, 0),
					sc + Vector2(lw * 0.5, bw * 0.1), sa + Vector2(-lw * 0.5, bw * 0.1)]), INK)
			"rest":
				_rest(ci, Vector2(cx, line_y - h * 0.3), h * 0.62, lw)
			"?":
				var box := Rect2(Vector2(cx - bw * 0.36, line_y - h * 0.78), Vector2(bw * 0.72, h * 0.9))
				_dashed_rect(ci, box, INK)
				_label(ci, font, box.get_center(), "?", clampi(int(box.size.y * 0.5), 12, 44), SHADE)
		if words:
			var word := str(NOTE_WORDS[kind])
			_label(ci, font, Vector2(x0 + (at + n * 0.5) * bw, r.end.y - word_h * 0.45), word, _fit(font, word, fs,
				bw * n - 4.0))
		at += n
		if bars and at % per_bar == 0 and at < total:
			var bx := x0 + at * bw
			ci.draw_line(Vector2(bx, line_y - h * 0.8), Vector2(bx, line_y + h * 0.2), INK, lw)
	if bars:
		var ex := x0 + total * bw
		ci.draw_line(Vector2(ex - lw * 2.5, line_y - h * 0.8), Vector2(ex - lw * 2.5, line_y + h * 0.2), INK, lw)
		ci.draw_line(Vector2(ex, line_y - h * 0.8), Vector2(ex, line_y + h * 0.2), INK, lw * 2.2)


## A note head (filled or open, tilted) with its stem up on the right.
static func _note(ci: CanvasItem, c: Vector2, head: Vector2, stem: float, lw: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(cos(t) * head.x, sin(t) * head.y).rotated(-0.35))
	if filled:
		ci.draw_colored_polygon(pts, INK)
	else:
		var ring := pts.duplicate()
		ring.append(pts[0])
		ci.draw_polyline(ring, INK, lw * 1.2, true)
	var top := c + Vector2(head.x * 0.85, 0)
	ci.draw_line(top, top - Vector2(0, stem), INK, lw)


## A crotchet rest: a zigzag, then a small hook at the bottom.
static func _rest(ci: CanvasItem, c: Vector2, h: float, lw: float) -> void:
	var w := h * 0.28
	var pts := PackedVector2Array([c + Vector2(-w * 0.3, -h * 0.5), c + Vector2(w * 0.45, -h * 0.18),
		c + Vector2(-w * 0.35, h * 0.08), c + Vector2(w * 0.4, h * 0.32), c + Vector2(-w * 0.2, h * 0.3),
		c + Vector2(0.0, h * 0.5)])
	ci.draw_polyline(pts, INK, lw * 1.8, true)


# --- melody ----------------------------------------------------------------------------------------------------------

static func _draw_melody(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var notes: Array = d.notes
	var pitches: Array[float] = []
	var lo := INF
	var hi := -INF
	for n: Variant in notes:
		var p := -1.0 if str(n) == "-" else 12.0 * log(SchoolSound.frequency(str(n)) / 440.0) / log(2.0) + 69.0
		pitches.append(p)
		if p >= 0.0:
			lo = minf(lo, p)
			hi = maxf(hi, p)
	for i in 5:   # faint guide lines
		var gy := r.position.y + r.size.y * (0.1 + 0.2 * i)
		ci.draw_line(Vector2(r.position.x, gy), Vector2(r.end.x, gy), GRID_LINE, 1.5)
	var step := r.size.x / notes.size()
	var dot := clampf(minf(step, r.size.y) * 0.13, 5.0, 16.0)
	var mark := _int(d, "mark", -1)
	var prev := Vector2.INF
	var points: Array[Vector2] = []
	for i in notes.size():
		if pitches[i] < 0.0:
			points.append(Vector2.INF)
			prev = Vector2.INF
			continue
		var f := 0.5 if hi - lo < 0.5 else (pitches[i] - lo) / (hi - lo)
		var p := Vector2(r.position.x + (i + 0.5) * step, r.end.y - dot - 4.0 - f * (r.size.y - 2.0 * dot - 8.0))
		if prev != Vector2.INF:
			ci.draw_line(prev, p, BLUE, maxf(2.0, dot * 0.35), true)
		points.append(p)
		prev = p
	for i in points.size():
		if points[i] != Vector2.INF:
			ci.draw_circle(points[i], dot * (1.35 if i == mark else 1.0), SHADE if i == mark else INK)


# --- robot -----------------------------------------------------------------------------------------------------------

static func _draw_robot(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var cols := _int(d, "cols", 2)
	var rows := _int(d, "rows", 2)
	var cell := minf(r.size.x / cols, r.size.y / rows)
	var o := r.position + (r.size - Vector2(cols, rows) * cell) * 0.5
	var lw := clampf(cell * 0.05, 1.0, 2.0)
	ci.draw_rect(Rect2(o, Vector2(cols, rows) * cell), BOARD)
	for x in cols + 1:
		ci.draw_line(o + Vector2(x * cell, 0), o + Vector2(x * cell, rows * cell), BOARD_LINE, lw)
	for y in rows + 1:
		ci.draw_line(o + Vector2(0, y * cell), o + Vector2(cols * cell, y * cell), BOARD_LINE, lw)
	var inset := cell * 0.08
	for w: Variant in d.get("walls", []):
		var box := _square_at(o, cell, _cell(w)).grow(-inset)
		ci.draw_rect(box, WALL)
		ci.draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * 0.3)), WALL_TOP)
	var path: Array = d.get("path", [])
	for i in range(1, path.size()):
		ci.draw_line(_square_at(o, cell, _cell(path[i - 1])).get_center(), _square_at(o, cell, _cell(path[i])).get_center(),
			TRAIL, maxf(2.0, cell * 0.12))
	for g: Variant in d.get("gems", []):
		var c := _square_at(o, cell, _cell(g)).get_center()
		var s := cell * 0.22
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s),
			c + Vector2(-s, 0)]), GEM)
	if d.has("goal"):
		var m := _square_at(o, cell, _cell(d.goal)).get_center()
		ci.draw_line(m + Vector2(-cell * 0.15, cell * 0.32), m + Vector2(-cell * 0.15, -cell * 0.32), POLE,
			maxf(1.5, cell * 0.06))
		ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-cell * 0.15, -cell * 0.32),
			m + Vector2(cell * 0.3, -cell * 0.18), m + Vector2(-cell * 0.15, -cell * 0.04)]), FLAG)
	_draw_robot_figure(ci, _square_at(o, cell, _cell(d.start)).get_center(), cell, str(d.get("facing", "")))


## The square at `c` of a grid whose top-left corner is `o`.
static func _square_at(o: Vector2, cell: float, c: Vector2i) -> Rect2:
	return Rect2(o + Vector2(c) * cell, Vector2(cell, cell))


## The robot as RobotAnswer draws it: a grey body with a yellow pointer the way it faces (none when `facing` is "").
static func _draw_robot_figure(ci: CanvasItem, m: Vector2, cell: float, facing: String) -> void:
	var r := cell * 0.34
	ci.draw_rect(Rect2(m - Vector2(r, r), Vector2(r, r) * 2.0), ROBOT)
	if HEADINGS.has(facing):
		var dir: Vector2 = HEADINGS[facing]
		var side := Vector2(-dir.y, dir.x)
		ci.draw_colored_polygon(PackedVector2Array([m + dir * r * 0.9, m - dir * r * 0.3 + side * r * 0.6,
			m - dir * r * 0.3 - side * r * 0.6]), POINTER)


# --- marks -----------------------------------------------------------------------------------------------------------

static func _draw_marks(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var what := marks_of(d)
	var names := bool(d.get("names", false))
	var fs := clampi(int(r.size.y * 0.12), 12, 22)
	var name_h := fs * 1.5 if names else 0.0
	var w := r.size.x / what.size()
	for i in what.size():
		var cell := Rect2(r.position + Vector2(i * w, 0), Vector2(w, r.size.y - name_h)).grow(-maxf(4.0, w * 0.06))
		_mark(ci, what[i], cell)
		if names:
			_label(ci, font, Vector2(r.position.x + (i + 0.5) * w, r.end.y - name_h * 0.45), what[i],
				_fit(font, what[i], fs, w - 6.0))


static func _mark(ci: CanvasItem, what: String, b: Rect2) -> void:
	var c := b.get_center()
	var lw := clampf(minf(b.size.x, b.size.y) * 0.03, 2.0, 4.0)
	var left := Vector2(b.position.x, c.y)
	var span := b.size.x
	var amp := minf(b.size.y * 0.3, b.size.x * 0.2)   # a narrow column gets a flatter line, not a squashed one
	var pts := PackedVector2Array()
	match what:
		"straight":
			ci.draw_line(Vector2(b.position.x, b.end.y - amp * 0.4), Vector2(b.end.x, b.position.y + amp * 0.4), INK, lw, true)
		"curved":
			for i in 33:
				var t := i / 32.0
				pts.append(Vector2(b.position.x + t * span, c.y + amp - 4.0 * amp * t * (1.0 - t) * 1.6))
			ci.draw_polyline(pts, INK, lw, true)
		"zigzag":
			var n := clampi(int(span / (amp * 1.2)), 3, 8)   # points about as far apart as they are tall
			for i in n + 1:
				pts.append(left + Vector2(span * i / n, -amp if i % 2 == 0 else amp))
			ci.draw_polyline(pts, INK, lw, true)
		"wavy":
			for i in 65:
				var t := i / 64.0
				pts.append(left + Vector2(t * span, sin(t * TAU * clampf(span / (amp * 4.0), 1.0, 2.0)) * amp))
			ci.draw_polyline(pts, INK, lw, true)
		"spiral":
			var rad := minf(b.size.x, b.size.y) * 0.46
			for i in 161:
				var t := i / 160.0
				pts.append(c + Vector2.from_angle(t * TAU * 3.0) * rad * t)
			ci.draw_polyline(pts, INK, lw, true)
		"loops":   # a curve that runs along and loops back over itself: x = a + k t - q sin t, y = -q cos t (q > k)
			var q := minf(amp * 0.9, span * 0.12)
			var k := (span - 2.0 * q) / (4.0 * TAU)
			for i in 161:
				var t := i / 160.0 * 4.0 * TAU
				pts.append(Vector2(b.position.x + q + k * t - q * sin(t), c.y - q * cos(t)))
			ci.draw_polyline(pts, INK, lw, true)
		"dotted":
			for i in 11:
				ci.draw_circle(left + Vector2(span * i / 10.0, 0), lw * 1.3, INK)
		"dashed":
			for i in 7:
				var x := b.position.x + span * i / 7.0
				ci.draw_line(Vector2(x, c.y), Vector2(x + span / 7.0 * 0.6, c.y), INK, lw, true)
		"thick":
			ci.draw_line(Vector2(b.position.x, c.y), Vector2(b.end.x, c.y), INK, clampf(b.size.y * 0.14, 6.0, 18.0), true)
		"thin":
			ci.draw_line(Vector2(b.position.x, c.y), Vector2(b.end.x, c.y), INK, 1.2, true)
		"hatching", "cross-hatching":
			var sq := _square(b)
			_hatch(ci, sq, 1.0, lw * 0.6)
			if what == "cross-hatching":
				_hatch(ci, sq, -1.0, lw * 0.6)
			ci.draw_rect(sq, GRID_LINE, false, 1.0)
		"stippling":   # many dots, packed closer to the right: darker there
			var sq := _square(b)
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			var dot := maxf(1.5, sq.size.x * 0.018)
			for i in 220:
				var q := Vector2(rng.randf(), rng.randf())
				if rng.randf() < 0.2 + 0.8 * q.x:
					ci.draw_circle(sq.position + q * sq.size, dot, INK)
		"scribble":   # a loopy line that wanders, turning a little at every step and bouncing off the edges
			var rng := RandomNumberGenerator.new()
			rng.seed = 11
			var sq := _square(b).grow(-4.0)
			var q := sq.get_center()
			var heading := 0.4
			var stride := sq.size.x * 0.05
			for i in 140:
				pts.append(q)
				heading += rng.randf_range(-0.9, 0.5)   # mostly one way round: loops
				var next := q + Vector2.from_angle(heading) * stride
				if not sq.has_point(next):
					heading += PI * 0.75
					next = (q + Vector2.from_angle(heading) * stride).clamp(sq.position, sq.end)
				q = next
			ci.draw_polyline(pts, INK, lw * 0.7, true)


static func _square(b: Rect2) -> Rect2:
	var s := minf(b.size.x, b.size.y)
	return Rect2(b.get_center() - Vector2(s, s) * 0.5, Vector2(s, s))


## Parallel diagonal lines across `sq` (`dir` 1: up to the right; -1: down to the right).
static func _hatch(ci: CanvasItem, sq: Rect2, dir: float, lw: float) -> void:
	var n := 9
	for i in range(1, 2 * n):
		var t := float(i) / n   # 0..2 along the diagonal
		var a := Vector2(minf(t, 1.0), maxf(t - 1.0, 0.0))
		var e := Vector2(maxf(t - 1.0, 0.0), minf(t, 1.0))
		if dir < 0.0:
			a = Vector2(1.0 - a.x, a.y)
			e = Vector2(1.0 - e.x, e.y)
		ci.draw_line(sq.position + a * sq.size, sq.position + e * sq.size, INK, lw, true)


# --- helpers ---------------------------------------------------------------------------------------------------------

static func _cell_ok(c: Variant, size: Vector2i) -> bool:
	if not c is Array or (c as Array).size() != 2:
		return false
	for v: Variant in c:
		if typeof(v) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	return _in(int(c[0]), 0, size.x - 1) and _in(int(c[1]), 0, size.y - 1)


static func _cell(c: Variant) -> Vector2i:
	return Vector2i(int(c[0]), int(c[1]))


static func _dashed_rect(ci: CanvasItem, box: Rect2, color: Color) -> void:
	var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	for i in 4:
		ci.draw_dashed_line(corners[i], corners[(i + 1) % 4], color, 2.0, 8.0)


## The biggest font size up to `size` at which `text` fits `width`.
static func _fit(font: Font, text: String, size: int, width: float) -> int:
	var fs := size
	while fs > 10 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
		fs -= 1
	return fs


## Text centred on `c` (both ways).
static func _label(ci: CanvasItem, font: Font, c: Vector2, text: String, size: int, color: Color = INK) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := c.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	ci.draw_string(font, Vector2(c.x - w * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func _int(p: Dictionary, key: String, default: int) -> int:
	var v: Variant = p.get(key, default)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _in(v: int, lo: int, hi: int) -> bool:
	return v >= lo and v <= hi
