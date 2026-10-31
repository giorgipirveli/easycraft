class_name SchoolPictureG5Core
extends RefCounted
## Owner #70 and #73, grade 5 maths, science and English (research §6.5): the picture kinds of the research's new units,
## drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new
## art; the font has no arrows, so they are drawn). Kinds and fields:
## - hundred_square {shaded (0-100), label? (SQUARE_LABELS: "none", the default, so an exercise's square never gives its
##   answer away; "percent" 35%, "fraction" 35/100 or "decimal" 0.35 beside it)}: a big 10 × 10 square, its shaded
##   small squares filling whole rows first, from the top left, so they can be counted in tens.
## - angle_facts {figure: FIGURES, angles: [whole degrees], labels?: [text] (one each, 0-5 letters: "" shows nothing,
##   "?" the unknown, "a" a letter; without labels every angle shows its degrees), ticks?: [side] (triangle and quad:
##   equal sides marked, side 0 from the first corner to the second)}: "straight" (2-4 angles on a straight line, 180°),
##   "point" (2-5 angles round a point, 360°), "cross" (two straight lines crossing: [a, b, a, b], a + b = 180°, the
##   vertically opposite angles equal), "triangle" (3 angles, 180°: bottom left, bottom right, top) or "quad" (4 angles
##   under 180° each, 360°: bottom left, bottom right, top right, top left). A right angle is drawn as a small square.
## - circuit_symbols {symbols: [SYMBOLS] (1-6), names? (true, the default: each named under it)}: circuit symbols in a
##   row; or a circuit diagram {cells? (1-3, the default 1: on the bottom wire), series?: [PARTS] (1-4, along the top
##   wire) | branches: [[PARTS] (1-2 each)] (2-3 parallel rows, each with a lamp, buzzer or motor) and main?: ["open" |
##   "closed"] (0-2 switches on the bottom wire, before the branches split), tags? (every lamp, buzzer and motor lettered
##   A, B, C in order), lit? (lamps glow as bright as `power` says, buzzers sound, motors turn)}.
## - force_arrows {thing: THINGS, arrows: [[DIRS, size (1-3), label? (0-18 letters)]] (1-4, one a direction), ground?
##   (GROUNDS: under a block or a car), moving? (DIRS: speed lines behind the thing)}: forces as arrows, longer for
##   bigger forces; a boat sits on water; a parachute, a skydiver and a ball are in the air.
## - life_cycle {stages: [text] (3-6, 1-14 letters), title? (1-16 letters, in the middle), hide? (a stage shown "?"),
##   mark? (a stage in orange)}: a cycle of boxes, clockwise from the top, joined by arrows.
## - flower_parts {labels? ("parts": petal, sepal, anther, filament, stigma, style, ovary and stem named; "groups": petal,
##   sepal, stamen and carpel), mark? (a part or a group, in orange), hide? (a named part or group shown "?"), bee? (a bee
##   at an anther, pollen on its back)}: a flower cut in half.
## - lungs {breath? ("in": the diaphragm down and flatter, the lungs bigger, air going in; "out"), labels?, mark?
##   (LUNG_PARTS: in orange)}: the chest from the front: windpipe, lungs, heart, diaphragm and ribs.
## - blood_loop {labels? (arteries and veins named; the lungs, heart and body always are), mark? (LOOP_PARTS, in orange),
##   hide? (a LOOP_PARTS name shown "?"), arrows? (true, the default: the way the blood flows)}: the double loop: blue
##   blood low in oxygen from the body to the heart and on to the lungs, red blood rich in oxygen back to the heart and
##   out to the body.

const KINDS: Array[String] = ["hundred_square", "angle_facts", "circuit_symbols", "force_arrows", "life_cycle",
	"flower_parts", "lungs", "blood_loop"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const SOFT := Color("fce2b8")

const SQUARE_LABELS: Array[String] = ["none", "percent", "fraction", "decimal"]
const FIGURES: Array[String] = ["straight", "point", "cross", "triangle", "quad"]
## How many angles each figure has ([fewest, most]) and what they add up to.
const FIGURE_ANGLES := {"straight": [2, 4], "point": [2, 5], "cross": [4, 4], "triangle": [3, 3], "quad": [4, 4]}
const SUMS := {"straight": 180, "point": 360, "cross": 360, "triangle": 180, "quad": 360}
const MAX_ANGLE_LABEL := 5
const ARC_COLORS: Array[Color] = [Color("f08a1c"), Color("3a7be8"), Color("5cae4f"), Color("b35fcf"), Color("d9433b")]

const SYMBOLS: Array[String] = ["cell", "battery", "lamp", "open", "closed", "buzzer", "motor", "wire"]
const SYMBOL_NAMES := {"cell": "cell", "battery": "battery", "lamp": "lamp", "open": "open switch",
	"closed": "closed switch", "buzzer": "buzzer", "motor": "motor", "wire": "wire"}
const PARTS: Array[String] = ["lamp", "open", "closed", "buzzer", "motor"]
const LOADS: Array[String] = ["lamp", "buzzer", "motor"]
const MAX_SYMBOLS := 6
const MAX_SERIES := 4
const MAX_CELLS := 3
const GLOW := Color("ffe066")

const THINGS: Array[String] = ["block", "car", "parachute", "skydiver", "boat", "ball"]
const GROUNDS: Array[String] = ["ice", "wood", "carpet", "sand", "grass"]
const DIRS: Array[String] = ["left", "right", "up", "down"]
const MAX_FORCE_LABEL := 18
const GROUND_COLORS := {"ice": Color("cfeaf7"), "wood": Color("c98b4f"), "carpet": Color("b8474f"),
	"sand": Color("ecd08c"), "grass": Color("6cbf4f")}

const MAX_STAGES := 6
const MAX_STAGE := 14
const MAX_TITLE := 16

const FLOWER_PARTS: Array[String] = ["petal", "sepal", "anther", "filament", "stigma", "style", "ovary", "stem"]
const FLOWER_GROUPS := {"stamen": ["anther", "filament"], "carpel": ["stigma", "style", "ovary"]}
const FLOWER_LABELS: Array[String] = ["parts", "groups"]

const BREATHS: Array[String] = ["in", "out"]
const LUNG_PARTS: Array[String] = ["windpipe", "lungs", "heart", "diaphragm", "ribs"]
const LOOP_PARTS: Array[String] = ["lungs", "heart", "body", "arteries", "veins"]
const PINK := Color("f4a7b0")
const PINK_EDGE := Color("b44b5a")
const HEART := Color("d8474f")
const SKIN := Color("f8e1cf")
const SKIN_EDGE := Color("c79a7c")
const RICH := Color("d9433b")    # blood rich in oxygen
const POOR := Color("3a6fd8")    # blood low in oxygen


# --- Rules the pictures draw by (tested with the samples) ------------------------------------------------------------

## The four angles where two straight lines cross, one of them `a`: vertically opposite angles are equal, and angles
## side by side on a straight line add up to 180°.
static func cross_angles(a: int) -> Array:
	return [a, 180 - a, a, 180 - a]


## A circuit diagram's lamps, buzzers and motors, in order (series along the top; or each branch in turn).
static func loads(d: Dictionary) -> Array:
	var out: Array = []
	for row: Variant in _rows(d):
		for p: Variant in row:
			if LOADS.has(str(p)):
				out.append(str(p))
	return out


## How hard each load (in `loads` order) works: 0 when its path is broken by an open switch; otherwise its cells shared
## by the loads on its path (1.0 = one lamp on one cell). In series every load shares one path; in parallel each branch
## is its own path from the cells, so a lamp there is as bright as a lamp alone.
static func power(d: Dictionary) -> Array:
	var out: Array = []
	var cells := float(d.get("cells", 1))
	var main_closed := not (d.get("main", []) as Array).has("open")
	for row: Variant in _rows(d):
		var closed := main_closed and not (row as Array).has("open")
		var n := 0
		for p: Variant in row:
			if LOADS.has(str(p)):
				n += 1
		for p: Variant in row:
			if LOADS.has(str(p)):
				out.append(cells / n if closed else 0.0)
	return out


## A part's colour: orange when it is the picture's `mark`, its own colour otherwise (a picture with no mark, or a line
## that is no named part, keeps its own colours).
static func part_colour(mark: String, part: String, normal: Color) -> Color:
	return ORANGE if part != "" and mark == part else normal


static func _rows(d: Dictionary) -> Array:
	if d.has("branches"):
		return d.branches
	return [d.get("series", [])]


# --- Checks ----------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"hundred_square":
			if not _whole(p.get("shaded")) or int(p.shaded) < 0 or int(p.shaded) > 100:
				return "shaded is 0-100 small squares"
			if p.has("label") and not SQUARE_LABELS.has(str(p.label)):
				return "label is one of %s" % [SQUARE_LABELS]
		"angle_facts":
			return _angle_problem(p)
		"circuit_symbols":
			return _circuit_problem(p)
		"force_arrows":
			return _force_problem(p)
		"life_cycle":
			var stages: Variant = p.get("stages")
			if not stages is Array or (stages as Array).size() < 3 or (stages as Array).size() > MAX_STAGES:
				return "a life cycle has 3-%d stages" % MAX_STAGES
			for s: Variant in stages:
				if not s is String or str(s).length() < 1 or str(s).length() > MAX_STAGE:
					return "a stage is 1-%d letters" % MAX_STAGE
			if p.has("title") and (not p.title is String or str(p.title).length() < 1 or str(p.title).length() > MAX_TITLE):
				return "a title is 1-%d letters" % MAX_TITLE
			for k: String in ["hide", "mark"]:
				if p.has(k) and (not _whole(p[k]) or int(p[k]) < 0 or int(p[k]) >= (stages as Array).size()):
					return "%s is a stage's index" % k
		"flower_parts":
			if p.has("labels") and not FLOWER_LABELS.has(str(p.labels)):
				return "labels is parts or groups"
			for k: String in ["mark", "hide"]:
				if p.has(k) and not (FLOWER_PARTS.has(str(p[k])) or FLOWER_GROUPS.has(str(p[k]))):
					return "%s is a part or a group of the flower" % k
			if p.has("hide"):
				if not p.has("labels"):
					return "hide needs labels"
				if not str(p.hide) in _flower_names(str(p.labels)):
					return "hide is a part the labels name"
			return _bool_problem(p, ["bee"])
		"lungs":
			if p.has("breath") and not BREATHS.has(str(p.breath)):
				return "breath is in or out"
			if p.has("mark") and not LUNG_PARTS.has(str(p.mark)):
				return "mark is one of %s" % [LUNG_PARTS]
			return _bool_problem(p, ["labels"])
		"blood_loop":
			for k: String in ["mark", "hide"]:
				if p.has(k) and not LOOP_PARTS.has(str(p[k])):
					return "%s is one of %s" % [k, LOOP_PARTS]
			if p.has("hide") and str(p.hide) in ["arteries", "veins"] and not bool(p.get("labels", false)):
				return "hiding arteries or veins needs labels"
			return _bool_problem(p, ["labels", "arrows"])
	return ""


static func _angle_problem(p: Dictionary) -> String:
	var figure := str(p.get("figure", ""))
	if not FIGURES.has(figure):
		return "figure is one of %s" % [FIGURES]
	var angles: Variant = p.get("angles")
	var span: Array = FIGURE_ANGLES[figure]
	if not angles is Array or (angles as Array).size() < int(span[0]) or (angles as Array).size() > int(span[1]):
		return "a %s has %d-%d angles" % [figure, span[0], span[1]]
	var total := 0
	for a: Variant in angles:
		if not _whole(a) or int(a) < 1 or int(a) >= (360 if figure == "point" else 180):
			return "each angle of a %s is 1-%d°" % [figure, 359 if figure == "point" else 179]
		total += int(a)
	if total != int(SUMS[figure]):
		return "a %s's angles add up to %d°" % [figure, SUMS[figure]]
	if figure == "cross":
		var want := cross_angles(int(angles[0]))
		for i in 4:
			if int(angles[i]) != int(want[i]):
				return "a cross's angles are a, 180 − a, a, 180 − a"
	if p.has("labels"):
		var labels: Variant = p.labels
		if not labels is Array or (labels as Array).size() != (angles as Array).size():
			return "one label each"
		for l: Variant in labels:
			if not l is String or str(l).length() > MAX_ANGLE_LABEL:
				return "a label is 0-%d letters" % MAX_ANGLE_LABEL
	if p.has("ticks"):
		if not figure in ["triangle", "quad"]:
			return "ticks are for triangles and quads"
		var ticks: Variant = p.ticks
		if not ticks is Array:
			return "ticks are sides"
		var seen := {}
		for t: Variant in ticks:
			if not _whole(t) or int(t) < 0 or int(t) >= (angles as Array).size() or seen.has(int(t)):
				return "ticks are different sides"
			seen[int(t)] = true
	return ""


static func _circuit_problem(p: Dictionary) -> String:
	if p.has("symbols"):
		for k: String in ["series", "branches", "main", "cells"]:
			if p.has(k):
				return "a row of symbols has no %s" % k
		var symbols: Variant = p.symbols
		if not symbols is Array or (symbols as Array).is_empty() or (symbols as Array).size() > MAX_SYMBOLS:
			return "1-%d symbols" % MAX_SYMBOLS
		for s: Variant in symbols:
			if not SYMBOLS.has(str(s)):
				return "a symbol is one of %s" % [SYMBOLS]
		return _bool_problem(p, ["names"])
	if p.has("cells") and (not _whole(p.cells) or int(p.cells) < 1 or int(p.cells) > MAX_CELLS):
		return "1-%d cells" % MAX_CELLS
	if p.has("series") == p.has("branches"):
		return "a circuit has series parts or branches"
	if p.has("series"):
		if p.has("main"):
			return "main switches are for branches"
		var series: Variant = p.series
		if not series is Array or (series as Array).is_empty() or (series as Array).size() > MAX_SERIES:
			return "1-%d parts in series" % MAX_SERIES
		var why := _parts_problem(series)
		if why != "":
			return why
	else:
		var branches: Variant = p.branches
		if not branches is Array or (branches as Array).size() < 2 or (branches as Array).size() > 3:
			return "2-3 branches"
		for b: Variant in branches:
			if not b is Array or (b as Array).is_empty() or (b as Array).size() > 2:
				return "a branch has 1-2 parts"
			var why := _parts_problem(b)
			if why != "":
				return why
		var main: Variant = p.get("main", [])
		if not main is Array or (main as Array).size() > 2:
			return "0-2 main switches"
		for s: Variant in main:
			if not str(s) in ["open", "closed"]:
				return "main parts are switches"
	return _bool_problem(p, ["tags", "lit"])


## A row of a circuit's parts: known, with a lamp, buzzer or motor in it (a row of only switches would short the cell).
static func _parts_problem(row: Variant) -> String:
	var has_load := false
	for x: Variant in row:
		if not PARTS.has(str(x)):
			return "a part is one of %s" % [PARTS]
		has_load = has_load or LOADS.has(str(x))
	return "" if has_load else "every path needs a lamp, buzzer or motor"


static func _force_problem(p: Dictionary) -> String:
	var thing := str(p.get("thing", ""))
	if not THINGS.has(thing):
		return "thing is one of %s" % [THINGS]
	var arrows: Variant = p.get("arrows")
	if not arrows is Array or (arrows as Array).is_empty() or (arrows as Array).size() > 4:
		return "1-4 arrows"
	var seen := {}
	for a: Variant in arrows:
		if not a is Array or (a as Array).size() < 2 or (a as Array).size() > 3:
			return "an arrow is [direction, size, label?]"
		if not DIRS.has(str(a[0])) or seen.has(str(a[0])):
			return "each arrow a different direction of %s" % [DIRS]
		seen[str(a[0])] = true
		if not _whole(a[1]) or int(a[1]) < 1 or int(a[1]) > 3:
			return "an arrow's size is 1-3"
		if (a as Array).size() == 3 and (not a[2] is String or str(a[2]).length() > MAX_FORCE_LABEL):
			return "a label is 0-%d letters" % MAX_FORCE_LABEL
	if p.has("ground"):
		if not thing in ["block", "car"]:
			return "only a block or a car stands on the ground"
		if not GROUNDS.has(str(p.ground)):
			return "ground is one of %s" % [GROUNDS]
	if p.has("moving") and not DIRS.has(str(p.moving)):
		return "moving is one of %s" % [DIRS]
	return ""


static func _flower_names(labels: String) -> Array:
	return FLOWER_PARTS.duplicate() if labels == "parts" else ["petal", "sepal", "stamen", "carpel"]


static func _bool_problem(p: Dictionary, keys: Array) -> String:
	for k: String in keys:
		if p.has(k) and not p[k] is bool:
			return "%s is true or false" % k
	return ""


static func _whole(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) == floorf(float(v))


# --- Drawing -------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"hundred_square":
			_draw_square(pic, font, r, d)
		"angle_facts":
			_draw_angles(pic, font, r, d)
		"circuit_symbols":
			if d.has("symbols"):
				_draw_symbol_row(pic, font, r, d)
			else:
				_draw_circuit(pic, font, r, d)
		"force_arrows":
			_draw_forces(pic, font, r, d)
		"life_cycle":
			_draw_cycle(pic, font, r, d)
		"flower_parts":
			_draw_flower(pic, font, r, d)
		"lungs":
			_draw_lungs(pic, font, r, d)
		"blood_loop":
			_draw_loop(pic, font, r, d)


# --- hundred_square ----------------------------------------------------------------------------------------------------

## The label beside a hundred square: "35%", "35/100" or "0.35".
static func square_label(shaded: int, label: String) -> String:
	match label:
		"percent":
			return "%d%%" % shaded
		"fraction":
			return "%d/100" % shaded
		"decimal":
			if shaded == 100:
				return "1"
			return ("0.%d" % (shaded / 10)) if shaded % 10 == 0 else "0.%02d" % shaded
	return ""


static func _draw_square(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var shaded := int(d.shaded)
	var text := square_label(shaded, str(d.get("label", "none")))
	var fs := clampi(int(r.size.y * 0.16), 14, 40)
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + fs if text != "" else 0.0
	var side := minf(r.size.y, r.size.x - text_w)
	var cell := side / 10.0
	var at := Vector2(r.get_center().x - (side + text_w) * 0.5, r.get_center().y - side * 0.5)
	for k in 100:
		var box := Rect2(at + Vector2(k % 10, k / 10) * cell, Vector2(cell, cell))
		ci.draw_rect(box, ORANGE if k < shaded else Color.WHITE)
		ci.draw_rect(box, Color(INK, 0.55), false, 1.0)
	ci.draw_rect(Rect2(at, Vector2(side, side)), INK, false, 2.5)
	if text != "":
		ci.draw_string(font, Vector2(at.x + side + fs * 0.5, r.get_center().y + fs * 0.36), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


# --- angle_facts -------------------------------------------------------------------------------------------------------

static func _angle_label(d: Dictionary, i: int) -> String:
	if d.has("labels"):
		return str(d.labels[i])
	return "%d°" % int(d.angles[i])


static func _draw_angles(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := clampi(int(minf(r.size.y * 0.12, r.size.x * 0.06)), 12, 24)
	match str(d.figure):
		"straight", "point", "cross":
			_draw_rays(ci, font, r, d, fs)
		"triangle", "quad":
			_draw_polygon(ci, font, r, d, fs)


## Angles round one point: on a straight line (the upper half), round a point, or where two lines cross.
static func _draw_rays(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, fs: int) -> void:
	var figure := str(d.figure)
	var angles: Array = d.angles
	var half := figure == "straight"
	var reach := minf(r.size.x * 0.46, (r.size.y - fs * 0.6) * (0.92 if half else 0.47))
	var c := Vector2(r.get_center().x, r.end.y - fs * 0.6 if half else r.get_center().y)
	var dir := func(deg: float) -> Vector2: return Vector2(cos(deg_to_rad(deg)), -sin(deg_to_rad(deg)))
	var w := maxf(2.5, reach * 0.018)
	var start := 0.0 if figure != "point" else 20.0
	# the angles' arcs and labels first, so the lines sit on top
	var at := start
	for i in angles.size():
		var a := float(angles[i])
		_angle_mark(ci, font, c, at, a, reach, _angle_label(d, i), ARC_COLORS[i % ARC_COLORS.size()], fs)
		at += a
	if half:
		ci.draw_line(c - Vector2(reach, 0), c + Vector2(reach, 0), INK, w, true)
	elif figure == "cross":   # the lines reach as far as the card lets them, each its own way
		for deg: float in [0.0, float(angles[0])]:
			var s := absf(sin(deg_to_rad(deg)))
			var long := minf(r.size.x * 0.46, (r.size.y * 0.47) / s if s > 0.01 else INF)
			ci.draw_line(c - dir.call(deg) * long, c + dir.call(deg) * long, INK, w, true)
	at = start
	for i in angles.size():
		if figure != "cross" and not (half and (i == 0)):
			ci.draw_line(c, c + dir.call(at) * reach, INK, w, true)
		at += float(angles[i])
	ci.draw_circle(c, w * 1.4, INK)


## One angle at `c` from `from` degrees, `a` degrees anticlockwise: an arc (a square for 90°) and its label.
static func _angle_mark(ci: CanvasItem, font: Font, c: Vector2, from: float, a: float, reach: float, label: String,
		col: Color, fs: int) -> void:
	var arc := minf(reach * 0.2, 46.0)
	var mid := deg_to_rad(from + a * 0.5)
	var bis := Vector2(cos(mid), -sin(mid))
	if absf(a - 90.0) < 0.01:
		var u := Vector2(cos(deg_to_rad(from)), -sin(deg_to_rad(from))) * arc * 0.6
		var v := Vector2(cos(deg_to_rad(from + 90.0)), -sin(deg_to_rad(from + 90.0))) * arc * 0.6
		ci.draw_polyline(PackedVector2Array([c + u, c + u + v, c + v]), col, 2.5, true)
	else:
		ci.draw_arc(c, arc, -deg_to_rad(from), -deg_to_rad(from + a), maxi(8, int(a / 6.0)), col, 3.0, true)
	if label == "":
		return
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var s := sin(deg_to_rad(minf(a, 179.0) * 0.5))
	var dist := clampf((tw * 0.5 + fs * 0.4) / maxf(s, 0.2), maxf(arc + fs * 0.8, reach * 0.5), reach * 0.85)
	var p := c + bis * dist
	_text_col(ci, font, p + Vector2(0, fs * 0.36), label, fs, col.darkened(0.25))


## A triangle or a quadrilateral with its angles marked inside each corner.
static func _draw_polygon(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, fs: int) -> void:
	var pts: Array[Vector2] = triangle_points(d.angles) if str(d.figure) == "triangle" else quad_points(d.angles)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for q in pts:
		lo = lo.min(q)
		hi = hi.max(q)
	var room := r.size - Vector2(fs * 1.2, fs * 1.2)
	var k := minf(room.x / maxf(hi.x - lo.x, 0.01), room.y / maxf(hi.y - lo.y, 0.01))
	var off := r.get_center() - (lo + hi) * 0.5 * k
	var p: Array[Vector2] = []
	for q in pts:
		p.append(off + q * k)
	var poly := PackedVector2Array(p)
	ci.draw_colored_polygon(poly, SOFT)
	var n := p.size()
	var w := maxf(2.5, k * 0.012)
	for i in n:
		var a := p[i]
		var b := p[(i + 1) % n]
		ci.draw_line(a, b, INK, w, true)
	for t: Variant in d.get("ticks", []):
		var a := p[int(t)]
		var b := p[(int(t) + 1) % n]
		var m := (a + b) * 0.5
		var nrm := (b - a).normalized().orthogonal() * minf(10.0, k * 0.06)
		ci.draw_line(m - nrm, m + nrm, INK, 2.5, true)
	for i in n:
		var here := p[i]
		var prev := p[(i - 1 + n) % n]
		var next := p[(i + 1) % n]
		var u := (next - here).normalized()
		var v := (prev - here).normalized()
		var a := float(d.angles[i])
		var short := minf(here.distance_to(next), here.distance_to(prev))
		var arc := minf(short * 0.22, 40.0)
		var col := ARC_COLORS[i % ARC_COLORS.size()]
		if absf(a - 90.0) < 0.01:
			ci.draw_polyline(PackedVector2Array([here + u * arc * 0.7, here + (u + v) * arc * 0.7, here + v * arc * 0.7]), col,
				2.5, true)
		else:
			var a0 := u.angle()
			var a1 := v.angle()
			var sweep := wrapf(a1 - a0, -PI, PI)
			ci.draw_arc(here, arc, a0, a0 + sweep, maxi(8, int(a / 6.0)), col, 3.0, true)
		var label := _angle_label(d, i)
		if label == "":
			continue
		var bis := (u + v).normalized()
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var s := sin(deg_to_rad(a * 0.5))
		var dist := clampf((tw * 0.5 + fs * 0.35) / maxf(s, 0.25), arc + fs * 0.6, maxf(short * 0.6, arc + fs * 0.6))
		_text_col(ci, font, here + bis * dist + Vector2(0, fs * 0.36), label, fs, col.darkened(0.25))


## A triangle's corners (screen y down) from its angles at the bottom left, bottom right and top: a base of 1.
static func triangle_points(angles: Array) -> Array[Vector2]:
	var a := deg_to_rad(float(angles[0]))
	var b := deg_to_rad(float(angles[1]))
	var c := deg_to_rad(float(angles[2]))
	var side := sin(b) / sin(c)   # from the bottom left to the top (the law of sines)
	return [Vector2(0, 0), Vector2(1, 0), Vector2(cos(a), -sin(a)) * side]


## A convex quadrilateral's corners (screen y down) from its angles, bottom left first, anticlockwise: two triangles on
## the diagonal from the bottom left to the top right, the first angle split between them.
static func quad_points(angles: Array) -> Array[Vector2]:
	var aa := float(angles[0])
	var bb := float(angles[1])
	var cc := float(angles[2])
	var dd := float(angles[3])
	var lo := maxf(0.0, 180.0 - bb - cc)
	var hi := minf(aa, 180.0 - bb)
	var a1 := (lo + hi) * 0.5
	var c1 := 180.0 - bb - a1
	var a2 := aa - a1
	var c2 := cc - c1
	# the diagonal from P0 to P2 has length 1; P1 below it (turned clockwise by a1), P3 above (anticlockwise by a2)
	var p1_len := sin(deg_to_rad(c1)) / sin(deg_to_rad(bb))
	var p3_len := sin(deg_to_rad(c2)) / sin(deg_to_rad(dd))
	var math: Array[Vector2] = [Vector2.ZERO, Vector2(cos(deg_to_rad(-a1)), sin(deg_to_rad(-a1))) * p1_len, Vector2(1, 0),
		Vector2(cos(deg_to_rad(a2)), sin(deg_to_rad(a2))) * p3_len]
	var out: Array[Vector2] = []
	for q in math:
		var t := q.rotated(deg_to_rad(a1))   # P0 to P1 along the bottom
		out.append(Vector2(t.x, -t.y))
	return out


# --- circuit_symbols -------------------------------------------------------------------------------------------------

static func _draw_symbol_row(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var symbols: Array = d.symbols
	var names := bool(d.get("names", true))
	var n := symbols.size()
	var per_row := n if n <= 3 else ceili(n / 2.0)   # more than three: two rows
	var rows := ceili(float(n) / per_row)
	var cw := r.size.x / per_row
	var rh := r.size.y / rows
	var fs := clampi(int(minf(rh * 0.16, cw * 0.13)), 12, 22)
	var name_h := fs * 1.5 if names else 0.0
	var s := minf(cw * 0.34, (rh - name_h) * 0.6)
	for i in n:
		var col := i % per_row
		var row := int(i / float(per_row))
		var c := Vector2(r.position.x + cw * (col + 0.5), r.position.y + rh * row + (rh - name_h) * 0.5)
		var w := maxf(2.5, s * 0.08)
		var sym := str(symbols[i])
		var half := _symbol_half(sym, s)
		ci.draw_line(c - Vector2(s * 1.25, 0), c - Vector2(half, 0), INK, w, true)
		ci.draw_line(c + Vector2(half, 0), c + Vector2(s * 1.25, 0), INK, w, true)
		_symbol(ci, font, c, sym, s, w, -1.0)
		if names:
			_text(ci, font, Vector2(c.x, r.position.y + rh * (row + 1) - fs * 0.35), str(SYMBOL_NAMES[sym]), fs)


## Half the width a symbol takes on its wire (the wire stops there).
static func _symbol_half(sym: String, s: float) -> float:
	match sym:
		"cell":
			return s * 0.18
		"battery":
			return s * 0.5
		"open", "closed":
			return s * 0.55
		"wire":
			return 0.0
	return s * 0.5


## A symbol centred on a horizontal wire at `c`, `s` its size; `glow` > 0 draws a lamp lit (bigger for more), a
## buzzer sounding or a motor turning.
static func _symbol(ci: CanvasItem, font: Font, c: Vector2, sym: String, s: float, w: float, glow: float) -> void:
	match sym:
		"cell":
			_cell(ci, c, s, w)
		"battery":
			_cell(ci, c - Vector2(s * 0.28, 0), s, w)
			_cell(ci, c + Vector2(s * 0.28, 0), s, w)
			ci.draw_line(c - Vector2(s * 0.1, 0), c + Vector2(s * 0.1, 0), INK, w * 0.7, true)
		"lamp":
			var rad := s * 0.5
			if glow > 0.0:
				var reach := rad * (1.25 + 0.35 * clampf(glow, 0.25, 3.0))
				ci.draw_circle(c, rad, GLOW)
				for k in 8:
					var ang := k * TAU / 8.0 + PI / 8.0
					var u := Vector2(cos(ang), sin(ang))
					ci.draw_line(c + u * rad * 1.12, c + u * reach, ORANGE, maxf(2.0, w * 0.8), true)
			else:
				ci.draw_circle(c, rad, Color.WHITE)
			ci.draw_arc(c, rad, 0, TAU, 28, INK, w, true)
			var q := rad * 0.7071
			ci.draw_line(c + Vector2(-q, -q), c + Vector2(q, q), INK, w, true)
			ci.draw_line(c + Vector2(-q, q), c + Vector2(q, -q), INK, w, true)
		"open", "closed":
			var a := c - Vector2(s * 0.5, 0)
			var b := c + Vector2(s * 0.5, 0)
			var tip := b if sym == "closed" else a + Vector2(cos(-0.55), sin(-0.55)) * s
			ci.draw_line(a, tip, INK, w, true)
			for q: Vector2 in [a, b]:
				ci.draw_circle(q, w * 1.3, PAPER)
				ci.draw_arc(q, w * 1.3, 0, TAU, 12, INK, w * 0.6, true)
		"buzzer":
			var rad := s * 0.45
			var top := c + Vector2(0, -rad * 0.2)
			var pts := PackedVector2Array()
			for k in 17:
				var ang := PI + k * PI / 16.0
				pts.append(top + Vector2(cos(ang), sin(ang)) * rad)
			pts.append(top + Vector2(-rad, 0))
			ci.draw_colored_polygon(pts, Color.WHITE)
			ci.draw_polyline(pts, INK, w, true)
			ci.draw_line(c - Vector2(s * 0.5, 0), c - Vector2(rad * 0.5, 0), INK, w, true)
			ci.draw_line(c + Vector2(rad * 0.5, 0), c + Vector2(s * 0.5, 0), INK, w, true)
			ci.draw_line(c - Vector2(rad * 0.5, 0), top - Vector2(rad * 0.5, 0), INK, w, true)
			ci.draw_line(c + Vector2(rad * 0.5, 0), top + Vector2(rad * 0.5, 0), INK, w, true)
			if glow > 0.0:
				for k in 2:
					var rr := rad * (1.3 + k * 0.35)
					ci.draw_arc(top, rr, -PI * 0.38, -PI * 0.12, 8, ORANGE, maxf(2.0, w * 0.7), true)
					ci.draw_arc(top, rr, -PI * 0.88, -PI * 0.62, 8, ORANGE, maxf(2.0, w * 0.7), true)
		"motor":
			var rad := s * 0.5
			ci.draw_circle(c, rad, Color.WHITE)
			ci.draw_arc(c, rad, 0, TAU, 28, INK, w, true)
			var fs := maxi(10, int(rad * 1.1))
			_text(ci, font, c + Vector2(0, fs * 0.36), "M", fs)
			if glow > 0.0:
				var rr := rad * 1.35
				ci.draw_arc(c, rr, -PI * 0.9, -PI * 0.2, 12, ORANGE, maxf(2.0, w * 0.8), true)
				var tip := c + Vector2(cos(-PI * 0.2), sin(-PI * 0.2)) * rr
				_head(ci, tip, Vector2(cos(-PI * 0.2 + PI * 0.5), sin(-PI * 0.2 + PI * 0.5)), rad * 0.5, ORANGE)
		"wire":
			ci.draw_line(c - Vector2(s * 0.5, 0), c + Vector2(s * 0.5, 0), INK, w, true)


## A cell: a long thin plate (the + end) and a short thick one (the − end), across the wire.
static func _cell(ci: CanvasItem, c: Vector2, s: float, w: float) -> void:
	var gap := s * 0.12
	ci.draw_line(c + Vector2(-gap, -s * 0.5), c + Vector2(-gap, s * 0.5), INK, w, true)
	ci.draw_line(c + Vector2(gap, -s * 0.26), c + Vector2(gap, s * 0.26), INK, w * 2.0, true)


static func _draw_circuit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = _rows(d)
	var branches := d.has("branches")
	var cells := int(d.get("cells", 1))
	var tags := bool(d.get("tags", false))
	var lit := bool(d.get("lit", false))
	var powers := power(d)
	var fs := clampi(int(r.size.y * 0.1), 12, 22)
	var bottom := r.end.y - r.size.y * 0.14
	var left := r.position.x + r.size.x * 0.1
	var right := r.end.x - r.size.x * 0.1
	var n_rows := rows.size()
	var most := 1
	for row: Array in rows:
		most = maxi(most, row.size())
	var top := r.position.y + r.size.y * 0.1
	var row_gap := (bottom - top) / (n_rows + (0.6 if branches else 0.0))
	var s := minf(minf(row_gap * 0.55, (right - left) / (most + 1) * 0.55), r.size.y * 0.2)
	# the top row's lamps (with their glow and tags) stay on the card
	top = r.position.y + maxf(r.size.y * 0.1, s * 0.62 + (fs * 1.1 if tags else 0.0) + (s * 0.4 if lit else 0.0))
	row_gap = (bottom - top) / (n_rows + (0.6 if branches else 0.0))
	s = minf(s, row_gap * 0.55)
	var w := maxf(2.5, s * 0.07)
	var wire := func(a: Vector2, b: Vector2) -> void: ci.draw_line(a, b, INK, w, true)
	# the bottom wire: the main switches, then the cells in the middle
	var main: Array = d.get("main", [])
	var bottom_parts: Array = []
	bottom_parts.append_array(main)
	var cell_w := s * (0.36 + 0.5 * (cells - 1)) + s * 0.2
	var cell_c := Vector2((left + right) * 0.5 + (s * 0.9 if not main.is_empty() else 0.0), bottom)
	var stops: Array = []   # [x from, x to] pieces of the bottom wire left open for parts
	stops.append([cell_c.x - cell_w * 0.5, cell_c.x + cell_w * 0.5])
	for k in cells:
		_cell(ci, cell_c + Vector2((k - (cells - 1) * 0.5) * s * 0.5, 0), s, w)
	for k in cells - 1:
		var x := cell_c.x + (k + 0.5 - (cells - 1) * 0.5) * s * 0.5
		wire.call(Vector2(x - s * 0.13, bottom), Vector2(x + s * 0.13, bottom))
	var main_x: Array = []
	for i in main.size():
		var x := left + (cell_c.x - cell_w * 0.5 - left) * (i + 1) / (main.size() + 1)
		main_x.append(x)
		stops.append([x - _symbol_half(str(main[i]), s), x + _symbol_half(str(main[i]), s)])
		_symbol(ci, font, Vector2(x, bottom), str(main[i]), s, w, -1.0)
	stops.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var x0 := left
	for st: Array in stops:
		wire.call(Vector2(x0, bottom), Vector2(float(st[0]), bottom))
		x0 = float(st[1])
	wire.call(Vector2(x0, bottom), Vector2(right, bottom))
	# the sides, and each row of parts across
	var first_y := top
	var last_y := top + row_gap * (n_rows - 1)
	wire.call(Vector2(left, first_y), Vector2(left, bottom))
	wire.call(Vector2(right, first_y), Vector2(right, bottom))
	var load_i := 0
	var letters := "ABCDEFGH"
	for ri in n_rows:
		var y := top + row_gap * ri
		var row: Array = rows[ri]
		var xs: Array = []
		for j in row.size():
			xs.append(left + (right - left) * (j + 1) / (row.size() + 1))
		var x := left
		for j in row.size():
			var half := _symbol_half(str(row[j]), s)
			wire.call(Vector2(x, y), Vector2(float(xs[j]) - half, y))
			x = float(xs[j]) + half
		wire.call(Vector2(x, y), Vector2(right, y))
		for j in row.size():
			var sym := str(row[j])
			var glow := -1.0
			if LOADS.has(sym):
				if lit:
					glow = float(powers[load_i])
				if tags:
					_text(ci, font, Vector2(float(xs[j]), y - s * 0.62 - fs * 0.2), letters[load_i], fs)
				load_i += 1
			_symbol(ci, font, Vector2(float(xs[j]), y), sym, s, w, glow if glow > 0.0 else -1.0)
		if branches and ri > 0:
			ci.draw_circle(Vector2(left, y), w * 1.5, INK)
			ci.draw_circle(Vector2(right, y), w * 1.5, INK)


# --- force_arrows ----------------------------------------------------------------------------------------------------

static func _draw_forces(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var thing := str(d.thing)
	var fs := clampi(int(r.size.y * 0.12), 14, 22)
	var unit := minf(r.size.y * 0.15, r.size.x * 0.1)
	for a: Array in d.arrows:   # the thing and its longest arrow each way fit the card
		var dv := _dir(str(a[0]))
		var reach := _edge(thing, dv) * 2.0 + 0.5 + 0.55 * int(a[1])
		if dv.y == 0.0:
			unit = minf(unit, (r.size.x * 0.5 - fs * 0.5) / reach)
		else:
			unit = minf(unit, (r.size.y * 0.5 - fs * 0.3) / reach)
	var c := r.get_center()
	var body := unit * 2.0   # the thing's size
	var ground_y := c.y + body * 0.5
	match thing:
		"block", "car":
			c.y = r.position.y + r.size.y * 0.52
			ground_y = c.y + body * 0.5
			_ground(ci, Rect2(Vector2(r.position.x, ground_y), Vector2(r.size.x, minf(r.size.y * 0.14, unit))),
				str(d.get("ground", "wood")))
		"boat":
			c.y = r.position.y + r.size.y * 0.52
			ground_y = c.y + body * 0.25
			var water := Rect2(Vector2(r.position.x, ground_y), Vector2(r.size.x, r.end.y - ground_y))
			ci.draw_rect(water, Color("7fbef0"))
			for k in 6:
				var x := r.position.x + (k + 0.5) * r.size.x / 6.0
				ci.draw_arc(Vector2(x, ground_y + unit * 0.2), unit * 0.25, PI * 1.15, PI * 1.85, 8, Color.WHITE, 2.0, true)
	var behind := false   # an arrow already drawn behind the thing leaves no room for speed lines
	if d.has("moving"):
		for a: Array in d.arrows:
			behind = behind or _dir(str(a[0])) == -_dir(str(d.moving))
	if d.has("moving") and not behind:
		var mv := _dir(str(d.moving))
		for k in 3:
			var side := mv.orthogonal() * (k - 1) * body * 0.28
			var from := c - mv * body * (0.75 + 0.1 * k) + side
			ci.draw_line(from, from - mv * body * 0.4, Color(INK, 0.45), 2.0, true)
	match thing:
		"block":
			var box := Rect2(c - Vector2(body, body) * 0.5, Vector2(body, body))
			ci.draw_rect(box, Color("c98b4f"))
			ci.draw_rect(box, INK, false, 2.0)
			for k in 2:
				var y := box.position.y + box.size.y * (k + 1) / 3.0
				ci.draw_line(Vector2(box.position.x, y), Vector2(box.end.x, y), Color("8a5a36"), 2.0)
		"car":
			var bw := body * 1.5
			var base := Rect2(Vector2(c.x - bw * 0.5, c.y - body * 0.1), Vector2(bw, body * 0.36))
			var cab := Rect2(Vector2(c.x - bw * 0.25, c.y - body * 0.42), Vector2(bw * 0.5, body * 0.34))
			ci.draw_rect(cab, Color("5b9bd5"))
			ci.draw_rect(cab, INK, false, 2.0)
			ci.draw_rect(base, Color("e0453a"))
			ci.draw_rect(base, INK, false, 2.0)
			for sx: float in [-0.3, 0.3]:
				var wc := Vector2(c.x + sx * bw, ground_y - body * 0.18)
				ci.draw_circle(wc, body * 0.18, INK)
				ci.draw_circle(wc, body * 0.07, Color("d5d9e0"))
		"parachute":
			var canopy_c := c + Vector2(0, -body * 0.35)
			var cr := body * 0.95
			var pts := PackedVector2Array()
			for k in 25:
				var ang := PI + k * PI / 24.0
				pts.append(canopy_c + Vector2(cos(ang) * cr, sin(ang) * cr * 0.65))
			ci.draw_colored_polygon(pts, Color("f5a04a"))
			ci.draw_polyline(pts, INK, 2.0, true)
			ci.draw_line(canopy_c - Vector2(cr, 0), canopy_c + Vector2(cr, 0), INK, 2.0, true)
			var person := c + Vector2(0, body * 0.55)
			for sx: float in [-1.0, -0.4, 0.4, 1.0]:
				ci.draw_line(canopy_c + Vector2(sx * cr, 0), person + Vector2(0, -body * 0.12), Color(INK, 0.7), 1.5, true)
			_stick_person(ci, person, body * 0.5, false)
		"skydiver":
			_stick_person(ci, c, body * 0.6, true)
		"boat":
			var hw := body * 0.9
			var hull := PackedVector2Array([c + Vector2(-hw, -body * 0.05), c + Vector2(hw, -body * 0.05),
				c + Vector2(hw * 0.7, body * 0.35), c + Vector2(-hw * 0.7, body * 0.35)])
			ci.draw_colored_polygon(hull, Color("c98b4f"))
			ci.draw_polyline(hull + PackedVector2Array([hull[0]]), INK, 2.0, true)
			ci.draw_line(c + Vector2(0, -body * 0.05), c + Vector2(0, -body * 0.85), INK, 2.5, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(4, -body * 0.8), c + Vector2(4, -body * 0.15),
				c + Vector2(hw * 0.75, -body * 0.15)]), Color.WHITE)
		"ball":
			ci.draw_circle(c, body * 0.4, Color("f2cf3a"))
			ci.draw_arc(c, body * 0.4, 0, TAU, 28, INK, 2.0, true)
	for a: Array in d.arrows:
		var dv := _dir(str(a[0]))
		var size := int(a[1])
		var from := c + dv * body * _edge(thing, dv)
		var to := from + dv * unit * (0.5 + 0.55 * size)
		_arrow(ci, from, to, ORANGE.darkened(0.1), maxf(3.0, unit * 0.12))
		if a.size() == 3 and str(a[2]) != "":
			var label := str(a[2])
			var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var at: Vector2
			if dv.y == 0.0:
				at = to + Vector2(-dv.x * tw * 0.3, -fs * 0.7)
				at.x = clampf(at.x, r.position.x + tw * 0.5, r.end.x - tw * 0.5)
			else:
				at = to + Vector2(tw * 0.5 + fs * 0.4, dv.y * fs * -0.2 + fs * 0.36)
				at.x = minf(at.x, r.end.x - tw * 0.5)
				at.y = clampf(at.y, r.position.y + fs, r.end.y - fs * 0.2)
			_text(ci, font, at, label, fs)


## How far from the thing's centre (in its sizes) an arrow that way starts: at its edge.
static func _edge(thing: String, dv: Vector2) -> float:
	if dv.y == 0.0:
		return 0.8 if thing == "car" else 0.55
	if thing == "parachute":
		return 1.05 if dv == Vector2.UP else 1.0
	return 0.6


static func _dir(name: String) -> Vector2:
	match name:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
	return Vector2.DOWN


static func _ground(ci: CanvasItem, box: Rect2, ground: String) -> void:
	var col: Color = GROUND_COLORS.get(ground, GROUND_COLORS.wood)
	ci.draw_rect(box, col)
	ci.draw_line(box.position, Vector2(box.end.x, box.position.y), INK, 2.0)
	var n := 14
	for k in n:
		var x := box.position.x + (k + 0.5) * box.size.x / n
		var y := box.position.y + box.size.y * 0.5
		match ground:
			"ice":
				ci.draw_line(Vector2(x - 6, y + 3), Vector2(x + 6, y - 3), Color.WHITE, 2.0, true)
			"wood":
				ci.draw_line(Vector2(x, box.position.y), Vector2(x, box.end.y), Color(col).darkened(0.25), 1.5)
			"carpet":
				ci.draw_circle(Vector2(x, y), 2.0, Color(col).lightened(0.3))
				ci.draw_circle(Vector2(x + 5, y + 5), 1.5, Color(col).darkened(0.3))
			"sand":
				ci.draw_circle(Vector2(x, y - 2), 1.8, Color(col).darkened(0.3))
				ci.draw_circle(Vector2(x + 6, y + 4), 1.5, Color(col).darkened(0.2))
			"grass":
				ci.draw_line(Vector2(x, box.position.y), Vector2(x - 3, box.position.y - 7), Color(col).darkened(0.2), 2.0)
				ci.draw_line(Vector2(x + 4, box.position.y), Vector2(x + 6, box.position.y - 6), Color(col).darkened(0.2), 2.0)


## A stick person: standing (arms down, legs down) or spread flat as a skydiver falls (arms and legs out).
static func _stick_person(ci: CanvasItem, c: Vector2, h: float, spread: bool) -> void:
	var w := maxf(2.5, h * 0.08)
	var head := c + Vector2(0, -h * 0.55)
	var hip := c + Vector2(0, h * 0.2)
	ci.draw_line(head + Vector2(0, h * 0.15), hip, INK, w, true)
	var shoulder := head + Vector2(0, h * 0.28)
	if spread:
		for s: float in [-1.0, 1.0]:
			ci.draw_polyline(PackedVector2Array([shoulder, shoulder + Vector2(s * h * 0.4, -h * 0.1),
				shoulder + Vector2(s * h * 0.7, -h * 0.3)]), INK, w, true)
			ci.draw_polyline(PackedVector2Array([hip, hip + Vector2(s * h * 0.35, h * 0.25),
				hip + Vector2(s * h * 0.55, h * 0.5)]), INK, w, true)
	else:
		for s: float in [-1.0, 1.0]:
			ci.draw_line(shoulder, shoulder + Vector2(s * h * 0.3, -h * 0.25), INK, w, true)
			ci.draw_line(hip, hip + Vector2(s * h * 0.2, h * 0.45), INK, w, true)
	ci.draw_circle(head, h * 0.15, SKIN)
	ci.draw_arc(head, h * 0.15, 0, TAU, 20, INK, w * 0.7, true)


# --- life_cycle --------------------------------------------------------------------------------------------------------

static func _draw_cycle(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var stages: Array = d.stages
	var n := stages.size()
	var c := r.get_center()
	var widest := 1.0
	for s: Variant in stages:
		widest = maxf(widest, font.get_string_size(str(s), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x)
	var bw := r.size.x * (0.36 if n <= 4 else 0.26)
	var bh := minf(r.size.y * 0.2, 44.0)
	var fs := clampi(int(minf(bh * 0.5, 20.0 * bw * 0.86 / widest)), 9, 20)
	var rx := (r.size.x - bw) * 0.5
	var ry := (r.size.y - bh) * 0.5
	var boxes: Array[Rect2] = []
	for i in n:
		var ang := -PI * 0.5 + i * TAU / n
		var at := c + Vector2(cos(ang) * rx, sin(ang) * ry)
		boxes.append(Rect2(at - Vector2(bw, bh) * 0.5, Vector2(bw, bh)))
	for i in n:
		var a := boxes[i]
		var b := boxes[(i + 1) % n]
		var from := _box_edge(a, b.get_center())
		var to := _box_edge(b, a.get_center())
		var along := (to - from)
		if along.length() > 12.0:
			_arrow(ci, from + along.normalized() * 3.0, to - along.normalized() * 3.0, Color(INK, 0.8), 2.5)
	if d.has("title"):
		var tf := clampi(int(fs * 1.1), 10, 22)
		_text_col(ci, font, c + Vector2(0, tf * 0.36), str(d.title), tf, Color(INK, 0.7))
	for i in n:
		var box := boxes[i]
		var style := StyleBoxFlat.new()
		var marked := d.has("mark") and int(d.mark) == i
		style.bg_color = ORANGE.lightened(0.45) if marked else Color("e3efd8")
		style.set_corner_radius_all(int(bh * 0.3))
		style.border_color = ORANGE.darkened(0.2) if marked else INK
		style.set_border_width_all(2)
		ci.draw_style_box(style, box)
		var text := "?" if d.has("hide") and int(d.hide) == i else str(stages[i])
		_text(ci, font, box.get_center() + Vector2(0, fs * 0.36), text, fs)


## Where the line from `box`'s centre to `to` leaves the box.
static func _box_edge(box: Rect2, to: Vector2) -> Vector2:
	var c := box.get_center()
	var v := to - c
	if v.length() < 0.001:
		return c
	var sx := (box.size.x * 0.5) / absf(v.x) if absf(v.x) > 0.001 else INF
	var sy := (box.size.y * 0.5) / absf(v.y) if absf(v.y) > 0.001 else INF
	return c + v * minf(minf(sx, sy), 1.0)


# --- flower_parts ----------------------------------------------------------------------------------------------------

static func _flower_col(d: Dictionary, part: String, normal: Color) -> Color:
	var mark := str(d.get("mark", ""))
	if mark == part or (FLOWER_GROUPS.has(mark) and (FLOWER_GROUPS[mark] as Array).has(part)):
		return ORANGE
	return normal


static func _draw_flower(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := str(d.get("labels", ""))
	var fs := clampi(int(r.size.y * 0.075), 10, 18)
	var side := fs * 6.5 if labels != "" else 0.0
	var h := minf(r.size.y, (r.size.x - side * 2.0) * 1.0)
	var cx := r.get_center().x
	var base := Vector2(cx, r.position.y + r.size.y * 0.66)   # where the petals, sepals and ovary meet
	var u := h / 10.0
	var w := maxf(2.0, u * 0.18)
	# the stem
	ci.draw_line(base, Vector2(cx, r.end.y), _flower_col(d, "stem", Color("4e9a3a")), maxf(4.0, u * 0.55), true)
	# petals, behind: one each side
	for s: float in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for k in 21:
			var t := k / 20.0
			var y := -t * u * 5.6
			var x := s * (u * 0.9 + sin(t * PI) * u * 2.8 + t * u * 0.6)
			pts.append(base + Vector2(x, y))
		for k in range(20, -1, -1):
			var t := k / 20.0
			pts.append(base + Vector2(s * (u * 0.6 + t * u * 0.4), -t * u * 5.2))
		ci.draw_colored_polygon(pts, _flower_col(d, "petal", Color("f49ac1")))
		ci.draw_polyline(pts, Color("b44b7a"), 1.5, true)
	# sepals: small green leaves under the petals
	for s: float in [-1.0, 1.0]:
		var sep := PackedVector2Array([base + Vector2(s * u * 0.5, u * 0.3), base + Vector2(s * u * 2.2, -u * 0.6),
			base + Vector2(s * u * 1.1, -u * 0.1)])
		ci.draw_colored_polygon(sep, _flower_col(d, "sepal", Color("5cae4f")))
		ci.draw_polyline(sep + PackedVector2Array([sep[0]]), Color("2f6b25"), 1.5, true)
	# the ovary with its ovules
	var ovary := base + Vector2(0, -u * 0.9)
	var ov_col := _flower_col(d, "ovary", Color("a8d67a"))
	_ellipse(ci, ovary, Vector2(u * 1.0, u * 1.1), ov_col, Color("2f6b25"))
	for k in 3:
		ci.draw_circle(ovary + Vector2((k - 1) * u * 0.45, u * 0.15), u * 0.2, Color("f7f2c4"))
	# the style and the stigma
	var stigma := base + Vector2(0, -u * 5.3)
	ci.draw_line(ovary + Vector2(0, -u * 1.0), stigma + Vector2(0, u * 0.3), _flower_col(d, "style", Color("8fc36b")),
		maxf(3.0, u * 0.35), true)
	_ellipse(ci, stigma, Vector2(u * 0.6, u * 0.35), _flower_col(d, "stigma", Color("c6d94a")), Color("2f6b25"))
	# stamens: a filament and an anther on each side of the carpel
	var anthers: Array[Vector2] = []
	for s: float in [-1.0, 1.0]:
		for k in 2:
			var tip := base + Vector2(s * u * (1.1 + k * 0.9), -u * (4.0 - k * 0.7))
			ci.draw_line(base + Vector2(s * u * 0.5, -u * 0.3), tip, _flower_col(d, "filament", Color("7b8a3a")), w, true)
			_ellipse(ci, tip + Vector2(0, -u * 0.2), Vector2(u * 0.28, u * 0.42), _flower_col(d, "anther", Color("f4b73a")),
				Color("9a6a10"))
			anthers.append(tip + Vector2(0, -u * 0.2))
	if bool(d.get("bee", false)):
		var a := anthers[2]
		var bee := a + Vector2(u * 1.3, -u * 0.9)
		_ellipse(ci, bee, Vector2(u * 0.75, u * 0.5), Color("f2cf3a"), INK)
		for k in 2:
			ci.draw_line(bee + Vector2((k - 0.3) * u * 0.4, -u * 0.45), bee + Vector2((k - 0.3) * u * 0.4, u * 0.45), INK,
				maxf(2.0, u * 0.14))
		_ellipse(ci, bee + Vector2(-u * 0.1, -u * 0.6), Vector2(u * 0.45, u * 0.3), Color(1, 1, 1, 0.8), Color(INK, 0.5))
		for k in 5:
			ci.draw_circle(bee + Vector2(-u * 0.5 + k * u * 0.22, u * 0.55), maxf(1.5, u * 0.09), Color("f4b73a"))
	if labels == "":
		return
	var hide := str(d.get("hide", ""))
	var spots: Dictionary
	if labels == "parts":
		spots = {"stigma": [stigma, -1], "anther": [anthers[0], -1], "petal": [base + Vector2(-u * 3.0, -u * 3.4), -1],
			"sepal": [base + Vector2(-u * 1.6, -u * 0.3), -1], "style": [base + Vector2(0, -u * 3.4), 1],
			"filament": [base + Vector2(u * 1.4, -u * 2.0), 1], "ovary": [ovary + Vector2(u * 0.8, 0), 1],
			"stem": [Vector2(cx, r.end.y - u * 1.2), 1]}
	else:
		spots = {"petal": [base + Vector2(-u * 3.0, -u * 3.4), -1], "sepal": [base + Vector2(-u * 1.6, -u * 0.3), -1],
			"stamen": [anthers[3] + Vector2(0, u * 1.2), 1], "carpel": [base + Vector2(0, -u * 3.0), 1]}
	var left_n := 0
	var right_n := 0
	for k: String in spots:
		if int(spots[k][1]) < 0:
			left_n += 1
		else:
			right_n += 1
	var li := 0
	var rj := 0
	for k: String in spots:
		var target: Vector2 = spots[k][0]
		var on_left := int(spots[k][1]) < 0
		var idx := li if on_left else rj
		var count := left_n if on_left else right_n
		var y := r.position.y + fs + (r.size.y - fs * 1.6) * (idx + 0.5) / count
		var text := "?" if hide == k else k
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x := r.position.x + 2.0 if on_left else r.end.x - tw - 2.0
		ci.draw_string(font, Vector2(x, y + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		var from := Vector2(x + tw + 4.0 if on_left else x - 4.0, y)
		ci.draw_line(from, target, Color(INK, 0.55), 1.2, true)
		if on_left:
			li += 1
		else:
			rj += 1


static func _ellipse(ci: CanvasItem, c: Vector2, radii: Vector2, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var ang := k * TAU / 24.0
		pts.append(c + Vector2(cos(ang) * radii.x, sin(ang) * radii.y))
	ci.draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	ci.draw_polyline(pts, edge, 1.5, true)


# --- lungs -------------------------------------------------------------------------------------------------------------

static func _lung_col(d: Dictionary, part: String, normal: Color) -> Color:
	return part_colour(str(d.get("mark", "")), part, normal)


static func _draw_lungs(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var breath_in := str(d.get("breath", "")) == "in"
	var labels := bool(d.get("labels", false))
	var fs := clampi(int(r.size.y * 0.075), 10, 18)
	var side := fs * 5.5 if labels else 0.0
	var h := minf(r.size.y, (r.size.x - side * 2.0) * 1.1)
	var u := h / 10.0
	var cx := r.get_center().x
	var top := r.position.y + (r.size.y - h) * 0.5
	# the body: head, neck and chest
	var head := Vector2(cx, top + u * 0.9)
	ci.draw_circle(head, u * 0.85, SKIN)
	ci.draw_arc(head, u * 0.85, 0, TAU, 28, SKIN_EDGE, 2.0, true)
	var chest := PackedVector2Array([Vector2(cx - u * 0.45, top + u * 1.7), Vector2(cx - u * 0.45, top + u * 2.2),
		Vector2(cx - u * 3.2, top + u * 2.7), Vector2(cx - u * 3.4, top + u * 9.9), Vector2(cx + u * 3.4, top + u * 9.9),
		Vector2(cx + u * 3.2, top + u * 2.7), Vector2(cx + u * 0.45, top + u * 2.2), Vector2(cx + u * 0.45, top + u * 1.7)])
	ci.draw_colored_polygon(chest, SKIN)
	ci.draw_polyline(chest, SKIN_EDGE, 2.0, true)
	var grow := 1.08 if breath_in else 1.0
	var dia_y := top + u * (8.3 if breath_in else 7.6)
	# the lungs: two lobes, the left one (on our right) smaller, beside the heart
	for s: float in [-1.0, 1.0]:
		var c := Vector2(cx + s * u * 1.55, top + u * 5.0)
		var rx := u * (1.25 if s < 0 else 1.05) * grow
		var pts := PackedVector2Array()
		for k in 28:
			var ang := k * TAU / 28.0
			var y := sin(ang) * u * 2.4 * grow
			var x := cos(ang) * rx
			if y > 0.0:
				y = minf(y, dia_y - c.y - u * 0.15)
			pts.append(c + Vector2(x, y))
		ci.draw_colored_polygon(pts, _lung_col(d, "lungs", PINK))
		pts.append(pts[0])
		ci.draw_polyline(pts, PINK_EDGE, 2.0, true)
	# the ribs
	for k in 4:
		var y := top + u * (3.4 + k * 1.1)
		for s: float in [-1.0, 1.0]:
			ci.draw_arc(Vector2(cx, y - u * 0.6), u * (3.0 + (0.15 if breath_in else 0.0)), PI * 0.5 - s * PI * 0.12,
				PI * 0.5 - s * PI * 0.42, 10, _lung_col(d, "ribs", Color("d9cbb8")), maxf(2.0, u * 0.14), true)
	# the windpipe and its two branches
	var pipe := _lung_col(d, "windpipe", Color("e8d7c0"))
	var fork := Vector2(cx, top + u * 3.6)
	ci.draw_line(Vector2(cx, top + u * 1.7), fork, pipe, maxf(4.0, u * 0.5), true)
	for k in 4:
		var y := top + u * (1.95 + k * 0.42)
		ci.draw_line(Vector2(cx - u * 0.25, y), Vector2(cx + u * 0.25, y), Color("b8a58c"), 1.5)
	for s: float in [-1.0, 1.0]:
		ci.draw_line(fork, fork + Vector2(s * u * 1.0, u * 0.9), pipe, maxf(3.0, u * 0.36), true)
	# the heart between the lungs, a little to the body's left (our right)
	var heart_c := Vector2(cx + u * 0.45, top + u * 6.1)
	_ellipse(ci, heart_c, Vector2(u * 0.85, u * 1.0), _lung_col(d, "heart", HEART), Color("7a1f24"))
	# the diaphragm: domed when breathing out, lower and flatter when breathing in
	var dia := PackedVector2Array()
	var rise := u * (0.35 if breath_in else 1.1)
	for k in 21:
		var t := k / 20.0
		var x := cx - u * 3.3 + t * u * 6.6
		dia.append(Vector2(x, dia_y - sin(t * PI) * rise))
	ci.draw_polyline(dia, _lung_col(d, "diaphragm", Color("c0605a")), maxf(3.0, u * 0.3), true)
	# the air: in through the mouth, or out
	if d.has("breath"):
		var mouth := head + Vector2(u * 0.9, u * 0.25)
		var far := mouth + Vector2(u * 1.3, -u * 0.3)
		if breath_in:
			_arrow(ci, far, mouth, BLUE, maxf(2.5, u * 0.16))
		else:
			_arrow(ci, mouth, far, BLUE, maxf(2.5, u * 0.16))
		var arrow_x := cx - u * 3.0
		var y0 := top + u * 8.4
		if breath_in:
			_arrow(ci, Vector2(arrow_x, dia_y - u * 0.9), Vector2(arrow_x, dia_y - u * 0.1), RED, maxf(2.0, u * 0.12))
		else:
			_arrow(ci, Vector2(arrow_x, y0), Vector2(arrow_x, y0 - u * 0.9), RED, maxf(2.0, u * 0.12))
	if not labels:
		return
	var spots := {"windpipe": [Vector2(cx - u * 0.2, top + u * 2.4), -1], "ribs": [Vector2(cx - u * 2.9, top + u * 4.0), -1],
		"diaphragm": [Vector2(cx - u * 2.0, dia_y - rise * 0.6), -1], "lungs": [Vector2(cx + u * 1.9, top + u * 4.2), 1],
		"heart": [heart_c + Vector2(u * 0.5, 0), 1]}
	var li := 0
	var rj := 0
	for k: String in spots:
		var target: Vector2 = spots[k][0]
		var on_left := int(spots[k][1]) < 0
		var y := r.position.y + fs + (r.size.y - fs * 1.6) * ((li if on_left else rj) + 0.5) / (3.0 if on_left else 2.0)
		var tw := font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x := r.position.x + 2.0 if on_left else r.end.x - tw - 2.0
		ci.draw_string(font, Vector2(x, y + fs * 0.36), k, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		ci.draw_line(Vector2(x + tw + 4.0 if on_left else x - 4.0, y), target, Color(INK, 0.55), 1.2, true)
		if on_left:
			li += 1
		else:
			rj += 1


# --- blood_loop --------------------------------------------------------------------------------------------------------

static func _draw_loop(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", false))
	var arrows := bool(d.get("arrows", true))
	var mark := str(d.get("mark", ""))
	var hide := str(d.get("hide", ""))
	var fs := clampi(int(r.size.y * 0.085), 10, 20)
	var side: float = fs * 4.6 if labels else float(fs)
	var area := Rect2(r.position + Vector2(side, 0), Vector2(r.size.x - side * 2.0, r.size.y))
	var bw := minf(area.size.x * 0.5, 200.0)
	var bh := minf(area.size.y * 0.2, 46.0)
	var cx := area.get_center().x
	var lungs := Rect2(Vector2(cx - bw * 0.5, area.position.y + 2.0), Vector2(bw, bh))
	var heart := Rect2(Vector2(cx - bw * 0.35, area.get_center().y - bh * 0.5), Vector2(bw * 0.7, bh))
	var body := Rect2(Vector2(cx - bw * 0.5, area.end.y - bh - 2.0), Vector2(bw, bh))
	var lw := maxf(5.0, bh * 0.16)
	var lx := cx - bw * 0.75   # the blue side, on our left (the heart's right side)
	var rx := cx + bw * 0.75   # the red side
	var vessel := func(pts: Array, col: Color, part: String) -> void:
		var c := part_colour(mark, part, col)
		ci.draw_polyline(PackedVector2Array(pts), c, lw, true)
	var hl := Vector2(heart.position.x, heart.get_center().y)
	var hr := Vector2(heart.end.x, heart.get_center().y)
	# the lungs' loop: blue from the heart up to the lungs, red back down
	vessel.call([hl + Vector2(0, -bh * 0.2), Vector2(lx + bw * 0.12, hl.y - bh * 0.2), Vector2(lx + bw * 0.12,
		lungs.get_center().y), Vector2(lungs.position.x, lungs.get_center().y)], POOR, "")
	vessel.call([Vector2(lungs.end.x, lungs.get_center().y), Vector2(rx - bw * 0.12, lungs.get_center().y),
		Vector2(rx - bw * 0.12, hr.y - bh * 0.2), hr + Vector2(0, -bh * 0.2)], RICH, "")
	# the body's loop: red arteries from the heart down to the body, blue veins back up
	vessel.call([hr + Vector2(0, bh * 0.2), Vector2(rx, hr.y + bh * 0.2), Vector2(rx, body.get_center().y),
		Vector2(body.end.x, body.get_center().y)], RICH, "arteries")
	vessel.call([Vector2(body.position.x, body.get_center().y), Vector2(lx, body.get_center().y),
		Vector2(lx, hl.y + bh * 0.2), hl + Vector2(0, bh * 0.2)], POOR, "veins")
	if arrows:
		var hs := lw * 2.4
		_head(ci, Vector2(lx + bw * 0.12, (hl.y + lungs.get_center().y) * 0.5 - hs * 0.5), Vector2.UP, hs, Color.WHITE)
		_head(ci, Vector2(rx - bw * 0.12, (hr.y + lungs.get_center().y) * 0.5 + hs * 0.5), Vector2.DOWN, hs, Color.WHITE)
		_head(ci, Vector2(rx, (hr.y + body.get_center().y) * 0.5 + hs * 0.5), Vector2.DOWN, hs, Color.WHITE)
		_head(ci, Vector2(lx, (hl.y + body.get_center().y) * 0.5 - hs * 0.5), Vector2.UP, hs, Color.WHITE)
	for pair: Array in [[lungs, "lungs", PINK], [heart, "heart", HEART.lightened(0.35)], [body, "body", SKIN]]:
		var box: Rect2 = pair[0]
		var part := str(pair[1])
		var style := StyleBoxFlat.new()
		style.bg_color = ORANGE.lightened(0.4) if mark == part else pair[2]
		style.set_corner_radius_all(int(bh * 0.3))
		style.border_color = INK
		style.set_border_width_all(2)
		ci.draw_style_box(style, box)
		if part == "heart":
			ci.draw_line(Vector2(box.get_center().x, box.position.y + 4), Vector2(box.get_center().x, box.end.y - 4),
				Color(INK, 0.5), 2.0)
		_text(ci, font, box.get_center() + Vector2(0, fs * 0.36), "?" if hide == part else part, fs)
	if labels:
		var vy := (hl.y + body.get_center().y) * 0.5
		_text(ci, font, Vector2(lx - fs * 2.6, vy + fs * 0.36), "?" if hide == "veins" else "veins", fs)
		_text(ci, font, Vector2(rx + fs * 2.9, vy + fs * 0.36), "?" if hide == "arteries" else "arteries", fs)


# --- helpers -------------------------------------------------------------------------------------------------------

## A straight arrow from `a` to `b`, its head at `b`.
static func _arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		return
	var head := w * 3.2
	ci.draw_line(a, b - dir * head * 0.8, col, w, true)
	_head(ci, b, dir, head, col)


static func _head(ci: CanvasItem, tip: Vector2, dir: Vector2, size: float, col: Color) -> void:
	var side := Vector2(-dir.y, dir.x) * size * 0.55
	ci.draw_colored_polygon(PackedVector2Array([tip, tip - dir * size + side, tip - dir * size - side]), col)


static func _text(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int) -> void:
	_text_col(ci, font, center_base, text, fs, INK)


static func _text_col(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(font, Vector2(center_base.x - w * 0.5, center_base.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
