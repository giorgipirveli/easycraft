class_name SchoolPictureG4Core
extends RefCounted
## Owner #70 and #73, grade 4 maths, science and English (research §6.4): the picture kinds of the research's new units,
## drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, and
## the Science Lab's own bulb, battery and switch, so a lesson's circuit looks like the Lab's). Kinds and fields:
## - line_graph {points: [[label, value]] (2-8), step, top, from? (0), name?, mark? (a point's index, drawn big and
##   orange)}: a line graph: a scale up the side with a line and a number at every step (1-10 steps from `from` to
##   `top`; a value may end between two lines), the labels (times, days, weeks) along the bottom, the points joined.
## - pie_chart {slices: [[label, parts]] (2-6; each 1 or more parts), whole? (the parts in all: 2-12, the slices' sum),
##   lines? (every part's edge drawn faintly, so equal parts can be counted), key? (true: colours and names beside the
##   circle; false: the names on the slices)}: slices in turn from the top, clockwise.
## - circuit {parts: ["bulb" | "buzzer" | "motor"] (1-3, along the top), switch? ("open" | "closed", on the right),
##   gap? (a break in the bottom wire), bridge? (what lies across the gap: 1-14 letters; needs a gap), conducts? (the
##   bridge lets electricity through), cell? (true: a battery on the left), glow? ("auto" | "?": the parts shown with a
##   question mark, for "will it work?")}: a loop of wire. The parts work (a bulb glows, a buzzer buzzes, a motor spins)
##   only when the loop is complete (`works`); two or three bulbs in one loop glow more dimly.
## - thermometer {from, to, step (2-14 steps), value | values (1-3), names? (one each, 12 letters), minor? (0-9 small
##   marks between the numbers)}: thermometers in °C side by side, their red columns up to their values; numbers below 0
##   written with a minus sign. One thermometer on a wide, short card lies down, its scale under it.
## - states {show: ["solid" | "liquid" | "gas"] (1-3, each once), names?, mark? (one of them, outlined in orange)}:
##   jars: a solid keeps its own shape, a liquid takes the jar's shape with a flat top, a gas fills the closed jar.
## - teeth {set? ("adult" | "milk"), labels? (each kind its colour, and a key), mark? (a kind: incisors, canines,
##   premolars, molars; drawn orange)}: one jaw from above, the front teeth at the bottom (`jaw`: 16 adult teeth, or 10
##   milk teeth with no premolars).
## - digestion {labels?, mark? (an organ of ORGANS, drawn orange)}: the digestive system in a body: mouth, gullet,
##   stomach, small intestine (coiled) and large intestine (round it, down to the rectum).

const KINDS: Array[String] = ["line_graph", "pie_chart", "lab_circuit", "thermometer", "states", "teeth", "digestion"]
const PARTS: Array[String] = ["bulb", "buzzer", "motor"]
const STATES: Array[String] = ["solid", "liquid", "gas"]
const TOOTH_KINDS: Array[String] = ["incisors", "canines", "premolars", "molars"]
const ORGANS: Array[String] = ["mouth", "gullet", "stomach", "small intestine", "large intestine"]
const MAX_STEPS := 10
const MAX_THERMO_STEPS := 14
const MAX_LABEL := 14
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const BLUE := Color("3a7be8")
const GRID_LINE := Color("b9c6dd")
const RED := Color("e0453a")
const WIRE := Color("b8642a")
const GLASS := Color("eef6ff")
const WATER := Color("5aa9f0")
const GAS := Color("9a86c9")
const STONE := Color("aab0b8")
const IVORY := Color("fffaf0")
const GUM := Color("f3a3a8")
const SKIN := Color("f8e1cf")
const SKIN_EDGE := Color("c79a7c")
const ORGAN := Color("f2a6a0")
const ORGAN_EDGE := Color("a9473f")
const SLICE_COLORS: Array[Color] = [Color("5b9bf0"), Color("f5a04a"), Color("5cc46f"), Color("c77ad6"), Color("f2cf3a"),
	Color("ec6f63")]
const TOOTH_COLORS := {"incisors": Color("8fc3f7"), "canines": Color("f7b267"), "premolars": Color("95dba0"),
	"molars": Color("cfa8ea")}
## Where the gas's dots sit in its jar (0-1 each way), the same every time.
const GAS_DOTS: Array[Vector2] = [Vector2(0.18, 0.12), Vector2(0.55, 0.08), Vector2(0.82, 0.2), Vector2(0.35, 0.27),
	Vector2(0.68, 0.36), Vector2(0.15, 0.42), Vector2(0.48, 0.5), Vector2(0.86, 0.55), Vector2(0.28, 0.62),
	Vector2(0.62, 0.68), Vector2(0.12, 0.8), Vector2(0.45, 0.84), Vector2(0.8, 0.86), Vector2(0.3, 0.95),
	Vector2(0.66, 0.94), Vector2(0.9, 0.04)]


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"line_graph":
			return _line_problem(p)
		"pie_chart":
			return _pie_problem(p)
		"lab_circuit":
			return _circuit_problem(p)
		"thermometer":
			return _thermometer_problem(p)
		"states":
			var show: Variant = p.get("show")
			if not show is Array or not _in((show as Array).size(), 1, 3):
				return "states: show 1-3 states"
			var seen := {}
			for s: Variant in show:
				if not STATES.has(str(s)) or seen.has(str(s)):
					return "states: solid, liquid or gas, each once"
				seen[str(s)] = true
			if p.has("mark") and not seen.has(str(p.mark)):
				return "states: the mark is one of the states shown"
		"teeth":
			var which := str(p.get("set", "adult"))
			if not ["adult", "milk"].has(which):
				return "teeth: the set is adult or milk"
			if p.has("mark") and (not TOOTH_KINDS.has(str(p.mark)) or int(jaw(which)[str(p.mark)]) == 0):
				return "teeth: the mark is a kind of tooth the set has"
		"digestion":
			if p.has("mark") and not ORGANS.has(str(p.mark)):
				return "digestion: the mark is one of %s" % ", ".join(ORGANS)
		_:
			return "unknown picture kind '%s'" % p.get("kind", "")
	return ""


static func _line_problem(p: Dictionary) -> String:
	var points: Variant = p.get("points")
	if not _pairs_ok(points, 2, 8):
		return "line_graph: 2-8 points, each [label, value]"
	var step := _num(p, "step")
	var top := _num(p, "top")
	var from := _num(p, "from") if p.has("from") else 0.0
	if is_nan(step) or is_nan(top) or is_nan(from) or step <= 0.0 or top <= from:
		return "line_graph: a step above 0 and a top above from"
	var n := (top - from) / step
	if absf(n - roundf(n)) > 0.001 or n > MAX_STEPS + 0.001:
		return "line_graph: from and top 1-%d steps apart" % MAX_STEPS
	for pt: Array in points:
		if float(pt[1]) < from - 0.0001 or float(pt[1]) > top + 0.0001:
			return "line_graph: %s is off the scale" % [pt]
	if p.has("mark") and (typeof(p.mark) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(p.mark), 0, (points as Array).size() - 1)):
		return "line_graph: the mark is a point's index"
	return ""


static func _pie_problem(p: Dictionary) -> String:
	var slices: Variant = p.get("slices")
	if not _pairs_ok(slices, 2, 6):
		return "pie_chart: 2-6 slices, each [label, parts]"
	for s: Array in slices:
		if float(s[1]) < 1.0 or absf(float(s[1]) - roundf(float(s[1]))) > 0.0001:
			return "pie_chart: each slice is 1 or more whole parts"
	var sum := 0
	for n in pie_parts(p):
		sum += n
	if not _in(sum, 2, 12):
		return "pie_chart: 2-12 parts in all"
	if p.has("whole") and (typeof(p.whole) not in [TYPE_INT, TYPE_FLOAT] or int(p.whole) != sum):
		return "pie_chart: the slices must make the whole"
	return ""


static func _circuit_problem(p: Dictionary) -> String:
	var parts: Variant = p.get("parts")
	if not parts is Array or not _in((parts as Array).size(), 1, 3):
		return "circuit: 1-3 parts"
	for part: Variant in parts:
		if not PARTS.has(str(part)):
			return "circuit: a part is a bulb, a buzzer or a motor"
	if p.has("switch") and not ["open", "closed"].has(str(p.switch)):
		return "circuit: a switch is open or closed"
	if p.has("bridge"):
		if not bool(p.get("gap", false)):
			return "circuit: a bridge lies across a gap"
		if not p.bridge is String or not _in(str(p.bridge).length(), 1, MAX_LABEL):
			return "circuit: a bridge is named in 1-%d letters" % MAX_LABEL
	if p.has("conducts") and not p.has("bridge"):
		return "circuit: only a bridge conducts or not"
	if p.has("glow") and not ["auto", "?"].has(str(p.glow)):
		return "circuit: glow is auto or ?"
	return ""


static func _thermometer_problem(p: Dictionary) -> String:
	var from := _num(p, "from")
	var to := _num(p, "to")
	var step := _num(p, "step")
	if is_nan(from) or is_nan(to) or is_nan(step) or step <= 0.0 or to <= from:
		return "thermometer: from below to, and a step above 0"
	var n := (to - from) / step
	if absf(n - roundf(n)) > 0.001 or n < 1.999 or n > MAX_THERMO_STEPS + 0.001:
		return "thermometer: from and to 2-%d steps apart" % MAX_THERMO_STEPS
	var values := values_of(p)
	if not _in(values.size(), 1, 3):
		return "thermometer: a value, or 1-3 values"
	for v: Variant in values:
		if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or float(v) < from - 0.0001 or float(v) > to + 0.0001:
			return "thermometer: %s is off the scale" % str(v)
	if p.has("names"):
		if not p.names is Array or (p.names as Array).size() != values.size():
			return "thermometer: a name for each value"
		for n_: Variant in p.names:
			if not n_ is String or str(n_).length() > 12:
				return "thermometer: names of 12 letters at most"
	if not _in(_int(p, "minor", 0), 0, 9):
		return "thermometer: minor 0-9"
	return ""


# --- Shared facts (tests and generators use them too) -------------------------------------------------------------------

## A circuit works (its bulbs glow) only as a complete loop: a cell, no open switch, and no gap that a conductor does not
## bridge.
static func works(d: Dictionary) -> bool:
	if not bool(d.get("cell", true)) or str(d.get("switch", "")) == "open":
		return false
	if bool(d.get("gap", false)):
		return d.has("bridge") and bool(d.get("conducts", false))
	return true


## The teeth of one jaw: an adult's (16: 32 in both jaws, with the wisdom teeth) or a child's milk teeth (10: 20).
static func jaw(which: String) -> Dictionary:
	if which == "milk":
		return {"incisors": 4, "canines": 2, "premolars": 0, "molars": 4}
	return {"incisors": 4, "canines": 2, "premolars": 4, "molars": 6}


static func pie_parts(d: Dictionary) -> Array:
	var out: Array = []
	for s: Array in d.get("slices", []):
		out.append(int(s[1]))
	return out


static func pie_whole(d: Dictionary) -> int:
	var sum := 0
	for n: int in pie_parts(d):
		sum += n
	return sum


## A thermometer picture's values: its `values`, or its one `value`.
static func values_of(d: Dictionary) -> Array:
	if d.get("values") is Array:
		return d.values
	return [d.value] if d.has("value") else []


## A temperature as the School writes it: −5, 0, 12 (the minus sign, not a hyphen).
static func degrees(v: float) -> String:
	var t := _fmt(absf(v))
	return ("−" + t) if v < -0.0001 else t


# --- Drawing -----------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"line_graph":
			_draw_line_graph(pic, font, r, d)
		"pie_chart":
			_draw_pie(pic, font, r, d)
		"lab_circuit":
			_draw_circuit(pic, font, r, d)
		"thermometer":
			_draw_thermometers(pic, font, r, d)
		"states":
			_draw_states(pic, font, r, d)
		"teeth":
			_draw_teeth(pic, font, r, d)
		"digestion":
			_draw_digestion(pic, font, r, d)


static func _draw_line_graph(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var points: Array = d.points
	var step := _num(d, "step")
	var top := _num(d, "top")
	var from := _num(d, "from") if d.has("from") else 0.0
	var n := roundi((top - from) / step)
	var name := str(d.get("name", ""))
	var fs := clampi(int(r.size.y / 13.0), 12, 20)
	var left := maxf(font.get_string_size(degrees(top), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x,
		font.get_string_size(degrees(from), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) + 18.0
	var head := 12.0 + (fs + 8.0 if name != "" else 0.0)
	var plot := Rect2(r.position + Vector2(left, head), Vector2(r.size.x - left - 12.0, r.size.y - head - fs - 16.0))
	ci.draw_rect(plot, Color.WHITE)
	var every := maxi(1, ceili((fs + 2.0) / (plot.size.y / n)))   # small pictures: a number on every other line
	for i in n + 1:
		var y := plot.end.y - plot.size.y * i / n
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID_LINE, 1.5)
		if i % every != 0:
			continue
		var t := degrees(from + i * step)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_label(ci, font, Vector2(plot.position.x - 8.0 - tw * 0.5, y), t, fs)
	var slot := plot.size.x / points.size()
	var line := PackedVector2Array()
	for i in points.size():
		var x := plot.position.x + slot * (i + 0.5)
		ci.draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), Color(GRID_LINE, 0.55), 1.0)
		line.append(Vector2(x, plot.end.y - plot.size.y * (float(points[i][1]) - from) / (top - from)))
		var words := str(points[i][0])
		var lfs := fs
		while lfs > 10 and font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs).x > slot - 2.0:
			lfs -= 1
		_label(ci, font, Vector2(x, plot.end.y + fs * 0.5 + 8.0), words, lfs)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.5)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.5)
	ci.draw_polyline(line, BLUE, maxf(2.0, fs * 0.18), true)
	var dot := maxf(3.5, fs * 0.28)
	for i in line.size():
		var marked := d.has("mark") and int(d.mark) == i
		ci.draw_circle(line[i], dot * (1.7 if marked else 1.0), SHADE if marked else BLUE)
		ci.draw_circle(line[i], dot * (0.8 if marked else 0.45), Color.WHITE)
	if name != "":
		_label(ci, font, Vector2(r.get_center().x, r.position.y + 6.0 + fs * 0.5), name, fs, BLUE)


static func _draw_pie(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var slices: Array = d.slices
	var whole := pie_whole(d)
	var key := bool(d.get("key", true))
	var fs := clampi(int(r.size.y / 11.0), 11, 22)
	var key_w := 0.0
	if key:
		for s: Array in slices:
			key_w = maxf(key_w, font.get_string_size(str(s[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		key_w += fs * 1.6 + 16.0
	var radius := maxf(8.0, minf((r.size.x - key_w) * 0.5, r.size.y * 0.5) - 6.0)
	var c := Vector2(r.position.x + (r.size.x - key_w) * 0.5 if key else r.get_center().x, r.get_center().y)
	var edges: Array[float] = []
	var at := 0
	for i in slices.size():
		var parts := int(slices[i][1])
		var a0 := -PI * 0.5 + TAU * at / whole
		var a1 := -PI * 0.5 + TAU * (at + parts) / whole
		var poly := PackedVector2Array([c])
		var segs := maxi(4, int(64.0 * parts / whole))
		for k in segs + 1:
			poly.append(c + Vector2.from_angle(lerpf(a0, a1, float(k) / segs)) * radius)
		ci.draw_colored_polygon(poly, SLICE_COLORS[i % SLICE_COLORS.size()])
		edges.append(a0)
		at += parts
	if bool(d.get("lines", false)):
		for k in whole:
			ci.draw_line(c, c + Vector2.from_angle(-PI * 0.5 + TAU * k / whole) * radius, Color(1, 1, 1, 0.9), 1.5)
	for a in edges:
		ci.draw_line(c, c + Vector2.from_angle(a) * radius, INK, 2.5)
	ci.draw_arc(c, radius, 0.0, TAU, 72, INK, 3.0, true)
	if key:
		var row := fs * 1.5
		var y0 := r.get_center().y - row * (slices.size() - 1) * 0.5
		var x0 := c.x + radius + 16.0
		for i in slices.size():
			var y := y0 + row * i
			var box := Rect2(Vector2(x0, y - fs * 0.5), Vector2(fs, fs))
			ci.draw_rect(box, SLICE_COLORS[i % SLICE_COLORS.size()])
			ci.draw_rect(box, INK, false, 1.5)
			var t := str(slices[i][0])
			var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			_label(ci, font, Vector2(x0 + fs + 8.0 + tw * 0.5, y), t, fs)
	else:   # the names on the slices
		at = 0
		for i in slices.size():
			var parts := int(slices[i][1])
			var mid := -PI * 0.5 + TAU * (at + parts * 0.5) / whole
			var t := str(slices[i][0])
			var lfs := fs
			while lfs > 9 and font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs).x > radius * 0.9:
				lfs -= 1
			_label(ci, font, c + Vector2.from_angle(mid) * radius * 0.62, t, lfs)
			at += parts


static func _draw_circuit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var parts: Array = d.parts
	var on := works(d)
	var ask := str(d.get("glow", "auto")) == "?"
	var bridge := str(d.get("bridge", ""))
	var fs := clampi(int(r.size.y / 12.0), 10, 20)
	var loop := Rect2(r.position + Vector2(r.size.x * 0.14, r.size.y * 0.3),
		Vector2(r.size.x * 0.72, r.size.y * (0.5 if bridge != "" else 0.56)))
	var lw := maxf(2.5, r.size.y * 0.018)
	var mid_y := loop.get_center().y
	var mid_x := loop.get_center().x
	# the cell on the left
	var cell_h := loop.size.y * 0.62
	var cell_w := minf(cell_h * 0.42, loop.size.x * 0.12)
	var has_cell := bool(d.get("cell", true))
	if has_cell:
		ci.draw_line(loop.position, Vector2(loop.position.x, mid_y - cell_h * 0.5), WIRE, lw)
		ci.draw_line(Vector2(loop.position.x, mid_y + cell_h * 0.5), Vector2(loop.position.x, loop.end.y), WIRE, lw)
	else:
		ci.draw_line(loop.position, Vector2(loop.position.x, loop.end.y), WIRE, lw)
	ci.draw_line(loop.position, Vector2(loop.end.x, loop.position.y), WIRE, lw)
	# the switch on the right
	var sw := str(d.get("switch", ""))
	var sw_half := loop.size.y * 0.2
	if sw != "":
		ci.draw_line(Vector2(loop.end.x, loop.position.y), Vector2(loop.end.x, mid_y - sw_half), WIRE, lw)
		ci.draw_line(Vector2(loop.end.x, mid_y + sw_half), loop.end, WIRE, lw)
	else:
		ci.draw_line(Vector2(loop.end.x, loop.position.y), loop.end, WIRE, lw)
	# the gap in the bottom
	var gap_half := loop.size.x * 0.09
	if bool(d.get("gap", false)):
		ci.draw_line(Vector2(loop.position.x, loop.end.y), Vector2(mid_x - gap_half, loop.end.y), WIRE, lw)
		ci.draw_line(Vector2(mid_x + gap_half, loop.end.y), loop.end, WIRE, lw)
		ci.draw_circle(Vector2(mid_x - gap_half, loop.end.y), lw * 1.3, INK)
		ci.draw_circle(Vector2(mid_x + gap_half, loop.end.y), lw * 1.3, INK)
		if bridge != "":
			var b := Rect2(Vector2(mid_x - gap_half * 1.5, loop.end.y - lw * 2.6), Vector2(gap_half * 3.0, lw * 5.2))
			ci.draw_rect(b, Color("fff3c4"))
			ci.draw_rect(b, INK, false, 2.0)
			_label(ci, font, Vector2(mid_x, b.end.y + fs * 0.75), bridge, fs)
	else:
		ci.draw_line(Vector2(loop.position.x, loop.end.y), loop.end, WIRE, lw)
	if has_cell:
		LabArt.battery(ci, Rect2(Vector2(loop.position.x - cell_w * 0.5, mid_y - cell_h * 0.5), Vector2(cell_w, cell_h)))
	if sw != "":
		LabArt.switch(ci, Vector2(loop.end.x, mid_y - sw_half), Vector2(loop.end.x, mid_y + sw_half), sw == "closed", lw * 1.4)
	# the parts along the top
	var bulbs := parts.count("bulb")
	var size := minf(loop.size.x / (parts.size() + 1) * 0.32, r.size.y * 0.12)
	for i in parts.size():
		var x := loop.position.x + loop.size.x * (i + 1) / (parts.size() + 1)
		var at := Vector2(x, loop.position.y)
		match str(parts[i]):
			"bulb":
				var c := at - Vector2(0, size * 1.4)
				LabArt.bulb(ci, c, size, 0.0 if ask or not on else 1.0 / (bulbs * bulbs))
				if ask:
					_label(ci, font, c, "?", int(size * 1.2))
			"buzzer":
				var box := Rect2(at - Vector2(size, size * 1.2), Vector2(size * 2.0, size * 1.2))
				ci.draw_rect(box, Color("3d4350"))
				ci.draw_circle(Vector2(at.x, box.position.y), size * 0.55, Color("5b6272"))
				ci.draw_rect(box, INK, false, 2.0)
				if ask:
					_label(ci, font, box.get_center(), "?", int(size * 1.0), Color.WHITE)
				elif on:
					for k in 3:
						ci.draw_arc(Vector2(box.end.x, box.get_center().y), size * (0.45 + 0.35 * k), -0.7, 0.7, 10, INK, 2.0)
			"motor":
				ci.draw_circle(at, size, Color("dfe3ea"))
				ci.draw_arc(at, size, 0.0, TAU, 32, INK, 2.0)
				_label(ci, font, at, "?" if ask else "M", int(size * 1.0))
				if on and not ask:
					for k in 2:
						var a := PI * k
						ci.draw_arc(at, size * 1.35, a - 0.9, a - 0.1, 10, SHADE, 2.5)


static func _draw_thermometers(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var values := values_of(d)
	var names: Array = d.get("names", [])
	var from := _num(d, "from")
	var to := _num(d, "to")
	var step := _num(d, "step")
	var n := roundi((to - from) / step)
	var minor := _int(d, "minor", 0)
	var fs := clampi(int(r.size.y / 12.0), 11, 22)
	if values.size() == 1 and names.is_empty() and r.size.x > r.size.y * 1.8:   # a wide, short card: lying down
		_draw_thermometer_across(ci, font, r, from, to, step, minor, float(values[0]), clampi(int(r.size.y / 8.5), 12, 24))
		return
	var slot := r.size.x / values.size()
	var foot := fs + 10.0 if not names.is_empty() else 4.0
	for i in values.size():
		var tube_w := clampf(r.size.y * 0.085, 8.0, 26.0)
		var bulb_r := tube_w * 0.95
		var scale_w := 0.0
		for v in [from, to]:
			scale_w = maxf(scale_w, font.get_string_size(degrees(v), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		var x := r.position.x + slot * i + (slot - tube_w - scale_w - 14.0) * 0.5
		var tube := Rect2(Vector2(x, r.position.y + fs + 8.0), Vector2(tube_w, r.size.y - fs - 8.0 - foot - bulb_r * 1.6))
		var bulb_c := Vector2(tube.get_center().x, tube.end.y + bulb_r * 0.7)
		var y0 := tube.end.y - tube_w * 0.3
		var y1 := tube.position.y + tube_w * 0.4
		var y_of := func(t: float) -> float: return y0 - (t - from) / (to - from) * (y0 - y1)
		ci.draw_rect(tube, GLASS)
		var top: float = y_of.call(float(values[i]))
		ci.draw_rect(Rect2(Vector2(tube.position.x + tube_w * 0.25, top), Vector2(tube_w * 0.5, tube.end.y - top + 2.0)), RED)
		ci.draw_circle(bulb_c, bulb_r, RED)
		ci.draw_rect(tube, INK, false, 2.0)
		ci.draw_arc(bulb_c, bulb_r, 0.0, TAU, 24, INK, 2.0)
		var gap: float = (y0 - y1) / n
		var every := maxi(1, ceili((fs + 1.0) / gap))
		for k in n + 1:
			var y: float = y_of.call(from + k * step)
			ci.draw_line(Vector2(tube.end.x, y), Vector2(tube.end.x + tube_w * 0.7, y), INK, 2.0)
			if k % every == 0:
				var t := degrees(from + k * step)
				var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				_label(ci, font, Vector2(tube.end.x + tube_w * 0.7 + 5.0 + tw * 0.5, y), t, fs)
			if k < n:
				for m in minor:
					var ym := y - gap * (m + 1) / (minor + 1)
					ci.draw_line(Vector2(tube.end.x, ym), Vector2(tube.end.x + tube_w * 0.35, ym), INK, 1.2)
		_label(ci, font, Vector2(tube.get_center().x + tube_w * 0.8, r.position.y + fs * 0.5 + 2.0), "°C", fs, BLUE)
		if i < names.size():
			_label(ci, font, Vector2(tube.get_center().x + scale_w * 0.4, r.end.y - fs * 0.5 - 2.0), str(names[i]), fs)


## One thermometer lying down, its bulb on the left and its scale under the tube (so a wide card's numbers are big).
static func _draw_thermometer_across(ci: CanvasItem, font: Font, r: Rect2, from: float, to: float, step: float, minor: int,
		value: float, fs: int) -> void:
	var n := roundi((to - from) / step)
	var tube_h := clampf(r.size.y * 0.15, 10.0, 32.0)
	var bulb_r := tube_h * 0.95
	var unit_w := font.get_string_size("°C", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 10.0
	var cy := r.get_center().y - fs * 0.6
	var tube := Rect2(Vector2(r.position.x + 8.0 + bulb_r * 1.6, cy - tube_h * 0.5),
		Vector2(r.size.x - 16.0 - bulb_r * 1.6 - unit_w, tube_h))
	var x0 := tube.position.x + tube_h * 0.4
	var x1 := tube.end.x - tube_h * 0.5
	var x_of := func(t: float) -> float: return x0 + (t - from) / (to - from) * (x1 - x0)
	ci.draw_rect(tube, GLASS)
	var end: float = x_of.call(value)
	ci.draw_rect(Rect2(Vector2(tube.position.x - 2.0, cy - tube_h * 0.25), Vector2(end - tube.position.x + 2.0, tube_h * 0.5)),
		RED)
	var bulb_c := Vector2(tube.position.x - bulb_r * 0.7, cy)
	ci.draw_circle(bulb_c, bulb_r, RED)
	ci.draw_rect(tube, INK, false, 2.0)
	ci.draw_arc(bulb_c, bulb_r, 0.0, TAU, 24, INK, 2.0)
	var gap := (x1 - x0) / n
	var widest := maxf(font.get_string_size(degrees(from), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x,
		font.get_string_size(degrees(to), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var every := maxi(1, ceili((widest + 8.0) / gap))
	for k in n + 1:
		var x: float = x_of.call(from + k * step)
		ci.draw_line(Vector2(x, tube.end.y), Vector2(x, tube.end.y + tube_h * 0.7), INK, 2.0)
		if k % every == 0:
			_label(ci, font, Vector2(x, tube.end.y + tube_h * 0.7 + fs * 0.7), degrees(from + k * step), fs)
		if k < n:
			for m in minor:
				var xm := x + gap * (m + 1) / (minor + 1)
				ci.draw_line(Vector2(xm, tube.end.y), Vector2(xm, tube.end.y + tube_h * 0.35), INK, 1.2)
	_label(ci, font, Vector2(tube.end.x + unit_w * 0.5, cy), "°C", fs, BLUE)


static func _draw_states(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var show: Array = d.show
	var names := bool(d.get("names", false))
	var fs := clampi(int(r.size.y / 12.0), 10, 20)
	var slot := r.size.x / show.size()
	var foot := fs + 12.0 if names else 6.0
	var h := r.size.y - foot - 12.0
	var w := minf(slot * 0.62, h * 0.8)
	for i in show.size():
		var jar := Rect2(Vector2(r.position.x + slot * (i + 0.5) - w * 0.5, r.position.y + 10.0), Vector2(w, h))
		var state := str(show[i])
		ci.draw_rect(jar, GLASS)
		match state:
			"solid":
				var s := w * 0.46
				var cube := Rect2(Vector2(jar.get_center().x - s * 0.5, jar.end.y - s), Vector2(s, s))
				var depth := s * 0.22
				ci.draw_colored_polygon(PackedVector2Array([cube.position, cube.position + Vector2(depth, -depth),
					Vector2(cube.end.x + depth, cube.position.y - depth), Vector2(cube.end.x, cube.position.y)]), STONE.lightened(0.3))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(cube.end.x, cube.position.y),
					Vector2(cube.end.x + depth, cube.position.y - depth), Vector2(cube.end.x + depth, cube.end.y - depth), cube.end]),
					STONE.darkened(0.2))
				ci.draw_rect(cube, STONE)
				ci.draw_rect(cube, INK, false, 2.0)
			"liquid":
				var level := jar.size.y * 0.45
				var water := Rect2(Vector2(jar.position.x, jar.end.y - level), Vector2(jar.size.x, level))
				ci.draw_rect(water, WATER)
				ci.draw_line(water.position, Vector2(water.end.x, water.position.y), WATER.lightened(0.45), 3.0)
			"gas":
				for dot in GAS_DOTS:
					ci.draw_circle(jar.position + Vector2(jar.size.x * (0.08 + dot.x * 0.84), jar.size.y * (0.06 + dot.y * 0.88)),
						maxf(2.5, w * 0.035), GAS)
				ci.draw_rect(Rect2(jar.position - Vector2(w * 0.06, h * 0.06), Vector2(w * 1.12, h * 0.06)), INK)
		ci.draw_line(jar.position, Vector2(jar.position.x, jar.end.y), INK, 2.5)
		ci.draw_line(Vector2(jar.end.x, jar.position.y), jar.end, INK, 2.5)
		ci.draw_line(Vector2(jar.position.x, jar.end.y), jar.end, INK, 2.5)
		if str(d.get("mark", "")) == state:
			ci.draw_rect(jar.grow(6.0), SHADE, false, 4.0)
		if names:
			_label(ci, font, Vector2(jar.get_center().x, r.end.y - fs * 0.5 - 4.0), state, fs)


## One jaw from above: the gum's U, the front teeth at the bottom; each tooth sits along it by its width.
static func _draw_teeth(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var which := str(d.get("set", "adult"))
	var labels := bool(d.get("labels", false))
	var mark := str(d.get("mark", ""))
	var fs := clampi(int(r.size.y / 12.0), 10, 20)
	var key_w := 0.0
	if labels:
		for k: String in TOOTH_KINDS:
			if int(jaw(which)[k]) > 0:
				key_w = maxf(key_w, font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		key_w += fs + 24.0
	var area := Rect2(r.position + Vector2(8, 8), Vector2(r.size.x - key_w - 16.0, r.size.y - 16.0))
	# half the jaw from the middle of the front: [kind, width in units]
	var half: Array = []
	var widths := {"incisors": 0.8, "canines": 0.9, "premolars": 1.0, "molars": 1.3}
	for k: String in TOOTH_KINDS:
		for _j in int(jaw(which)[k]) / 2:
			half.append([k, widths[k]])
	var units := 0.0
	for t: Array in half:
		units += float(t[1]) + 0.12
	# the arch: a half ellipse, the front at the bottom, as wide and tall as the picture allows; the teeth fill it
	var pad := minf(area.size.x, area.size.y) * 0.08
	var top := Vector2.ZERO
	var path := PackedVector2Array()
	var u := 0.0
	for _pass in 2:
		top = Vector2(area.get_center().x, area.position.y + pad)
		path = _arch(top, area.size.x * 0.5 - pad, area.size.y - pad * 2.0)
		u = minf(_length(path) / units, area.size.y * 0.2)
		pad = u * 0.75
	var fit := units * u / _length(path)
	if fit < 1.0:   # smaller teeth than the arch holds: a smaller arch, still at the top
		for k in path.size():
			path[k] = top + (path[k] - top) * fit
	for side: float in [-1.0, 1.0]:   # the gum
		var gum := PackedVector2Array()
		for q in path:
			gum.append(Vector2(top.x + side * (q.x - top.x), q.y))
		ci.draw_polyline(gum, GUM, u * 1.25, true)
	for side: float in [-1.0, 1.0]:
		var s := 0.06 * u
		for t: Array in half:
			var kind := str(t[0])
			var tw := float(t[1]) * u
			var at := _along(path, s + tw * 0.5)
			var p: Vector2 = at[0]
			var dir: Vector2 = at[1]
			var fill := IVORY
			if mark != "":
				fill = SHADE if kind == mark else IVORY
			elif labels:
				fill = TOOTH_COLORS[kind]
			_tooth(ci, kind, Vector2(top.x + side * (p.x - top.x), p.y), Vector2(side * dir.x, dir.y), tw, u, fill, side)
			s += tw + 0.12 * u
	if labels:
		var shown: Array[String] = []
		for k: String in TOOTH_KINDS:
			if int(jaw(which)[k]) > 0:
				shown.append(k)
		var row := fs * 1.5
		var y0 := r.get_center().y - row * (shown.size() - 1) * 0.5
		var x0 := r.end.x - key_w + 6.0
		for i in shown.size():
			var box := Rect2(Vector2(x0, y0 + row * i - fs * 0.5), Vector2(fs, fs))
			ci.draw_rect(box, TOOTH_COLORS[shown[i]])
			ci.draw_rect(box, INK, false, 1.5)
			var tw := font.get_string_size(shown[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			_label(ci, font, Vector2(x0 + fs + 8.0 + tw * 0.5, y0 + row * i), shown[i], fs)


## One side of a jaw's arch from the middle of the front (`top` + ry down) round to the back (`top` + rx across).
static func _arch(top: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 49:
		var a := PI * 0.5 * k / 48.0
		out.append(top + Vector2(rx * sin(a), ry * cos(a)))
	return out


static func _length(path: PackedVector2Array) -> float:
	var sum := 0.0
	for k in range(1, path.size()):
		sum += path[k].distance_to(path[k - 1])
	return maxf(sum, 0.001)


## [the point `s` along `path`, the path's direction there].
static func _along(path: PackedVector2Array, s: float) -> Array:
	var left := s
	for k in range(1, path.size()):
		var seg := path[k].distance_to(path[k - 1])
		if left <= seg or k == path.size() - 1:
			var dir := (path[k] - path[k - 1]).normalized()
			return [path[k - 1] + dir * minf(left, seg), dir]
		left -= seg
	return [path[0], Vector2.RIGHT]


## A tooth at `p`, lying along `along` (the jaw's direction there), `w` wide along the jaw; `side` -1 on the left, so a
## canine's point faces out of the mouth on both sides.
static func _tooth(ci: CanvasItem, kind: String, p: Vector2, along: Vector2, w: float, u: float, fill: Color,
		side: float = 1.0) -> void:
	var across := Vector2(-along.y, along.x) * side
	var shape: Array = []
	match kind:
		"incisors":   # a thin blade for cutting
			shape = [[-0.5, -0.28], [0.5, -0.28], [0.5, 0.28], [-0.5, 0.28]]
		"canines":   # pointed, for tearing
			shape = [[-0.5, 0.0], [-0.3, -0.42], [0.0, -0.5], [0.3, -0.42], [0.5, 0.0], [0.0, 0.62]]
		"premolars":
			for k in 10:
				var a := TAU * k / 10.0
				shape.append([cos(a) * 0.5, sin(a) * 0.46])
		_:   # molars: wide and flat, for grinding
			shape = [[-0.5, -0.36], [-0.36, -0.46], [0.36, -0.46], [0.5, -0.36], [0.5, 0.36], [0.36, 0.46], [-0.36, 0.46],
				[-0.5, 0.36]]
	var poly := PackedVector2Array()
	var depth := u * 0.9
	for q: Array in shape:
		poly.append(p + along * float(q[0]) * w + across * float(q[1]) * depth)
	ci.draw_colored_polygon(poly, fill)
	poly.append(poly[0])
	ci.draw_polyline(poly, INK, maxf(1.2, u * 0.08), true)
	if kind == "molars":
		ci.draw_line(p - along * w * 0.25, p + along * w * 0.25, Color(INK, 0.5), maxf(1.0, u * 0.05))
		ci.draw_line(p - across * depth * 0.22, p + across * depth * 0.22, Color(INK, 0.5), maxf(1.0, u * 0.05))
	elif kind == "premolars":
		ci.draw_line(p - along * w * 0.2, p + along * w * 0.2, Color(INK, 0.5), maxf(1.0, u * 0.05))


static func _draw_digestion(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", false))
	var mark := str(d.get("mark", ""))
	var fs := clampi(int(r.size.y / 14.0), 9, 18)
	var h := r.size.y - 8.0
	var head_r := h * 0.11
	var cx := r.get_center().x
	var head_c := Vector2(cx, r.position.y + 4.0 + head_r)
	var torso_w := minf(h * 0.5, r.size.x * (0.42 if labels else 0.6))
	var torso := Rect2(Vector2(cx - torso_w * 0.5, head_c.y + head_r * 1.35), Vector2(torso_w, r.end.y - 4.0 - head_c.y - head_r * 1.35))
	# the body
	ci.draw_rect(Rect2(Vector2(cx - head_r * 0.38, head_c.y + head_r * 0.8), Vector2(head_r * 0.76, head_r * 0.7)), SKIN)
	var body := StyleBoxFlat.new()
	body.bg_color = SKIN
	body.border_color = SKIN_EDGE
	body.set_border_width_all(2)
	body.set_corner_radius_all(int(torso_w * 0.22))
	ci.draw_style_box(body, torso)
	ci.draw_circle(head_c, head_r, SKIN)
	ci.draw_arc(head_c, head_r, 0.0, TAU, 32, SKIN_EDGE, 2.0)
	var col := func(organ: String) -> Color: return SHADE if organ == mark else ORGAN
	var edge := maxf(1.5, h * 0.006)
	var T := torso
	# the large intestine: up the body's right side (the picture's left), across, down, then to the rectum
	var li := PackedVector2Array([Vector2(cx - T.size.x * 0.3, T.position.y + T.size.y * 0.86),
		Vector2(cx - T.size.x * 0.3, T.position.y + T.size.y * 0.5), Vector2(cx + T.size.x * 0.3, T.position.y + T.size.y * 0.5),
		Vector2(cx + T.size.x * 0.3, T.position.y + T.size.y * 0.84), Vector2(cx + T.size.x * 0.05, T.position.y + T.size.y * 0.9),
		Vector2(cx, T.position.y + T.size.y * 0.97)])
	var li_w := T.size.x * 0.12
	ci.draw_polyline(li, ORGAN_EDGE, li_w + edge * 2.0, true)
	ci.draw_polyline(li, col.call("large intestine"), li_w, true)
	# the small intestine: coiled inside it
	var si := PackedVector2Array([Vector2(cx + T.size.x * 0.1, T.position.y + T.size.y * 0.42)])
	var rows := 4
	for k in rows:
		var y := T.position.y + T.size.y * (0.58 + 0.07 * k)
		var l := Vector2(cx - T.size.x * 0.18, y)
		var rr := Vector2(cx + T.size.x * 0.18, y)
		si.append(rr if k % 2 == 0 else l)
		si.append(l if k % 2 == 0 else rr)
	si.append(Vector2(cx - T.size.x * 0.3, T.position.y + T.size.y * 0.84))
	var si_w := T.size.x * 0.055
	ci.draw_polyline(si, ORGAN_EDGE, si_w + edge * 2.0, true)
	ci.draw_polyline(si, col.call("small intestine"), si_w, true)
	# the gullet, from the back of the mouth to the stomach
	var gullet := PackedVector2Array([head_c + Vector2(0, head_r * 0.55), Vector2(cx, T.position.y + T.size.y * 0.12),
		Vector2(cx + T.size.x * 0.08, T.position.y + T.size.y * 0.24)])
	var g_w := T.size.x * 0.06
	ci.draw_polyline(gullet, ORGAN_EDGE, g_w + edge * 2.0, true)
	ci.draw_polyline(gullet, col.call("gullet"), g_w, true)
	# the stomach: a bag on the body's left (the picture's right)
	var st_c := Vector2(cx + T.size.x * 0.14, T.position.y + T.size.y * 0.32)
	var st := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		st.append(st_c + Vector2(cos(a) * T.size.x * 0.2, sin(a) * T.size.y * 0.1).rotated(0.45))
	ci.draw_colored_polygon(st, col.call("stomach"))
	st.append(st[0])
	ci.draw_polyline(st, ORGAN_EDGE, edge, true)
	# the mouth
	var m_c := head_c + Vector2(0, head_r * 0.35)
	ci.draw_arc(m_c, head_r * 0.32, 0.25, PI - 0.25, 12, SHADE if mark == "mouth" else ORGAN_EDGE, maxf(2.5, head_r * 0.16))
	for eye: float in [-1.0, 1.0]:
		ci.draw_circle(head_c + Vector2(eye * head_r * 0.35, -head_r * 0.2), maxf(1.5, head_r * 0.09), INK)
	if labels:
		var tags := {"mouth": [m_c, -1.0], "gullet": [Vector2(cx, T.position.y + T.size.y * 0.08), -1.0],
			"stomach": [st_c + Vector2(T.size.x * 0.12, 0), 1.0],
			"small intestine": [Vector2(cx + T.size.x * 0.12, T.position.y + T.size.y * 0.66), 1.0],
			"large intestine": [Vector2(cx - T.size.x * 0.3, T.position.y + T.size.y * 0.62), -1.0]}
		for organ: String in ORGANS:
			var at: Vector2 = tags[organ][0]
			var side: float = tags[organ][1]
			var tw := font.get_string_size(organ, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var end_x := T.position.x - 10.0 if side < 0.0 else T.end.x + 10.0
			ci.draw_line(at, Vector2(end_x, at.y), INK, 1.5)
			_label(ci, font, Vector2(end_x + side * (tw * 0.5 + 4.0), at.y), organ, fs, SHADE.darkened(0.2) if organ == mark else INK)


# --- Helpers -----------------------------------------------------------------------------------------------------------

static func _label(ci: CanvasItem, font: Font, c: Vector2, text: String, size: int, color: Color = INK) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := c.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	ci.draw_string(font, Vector2(c.x - w * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## A number as the pictures write it: whole numbers with commas ("1,000"), others as they are ("2.5").
static func _fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.0001:
		return GenKit.fmt(roundi(v))
	return String.num(v, 2)


## [label, value] pairs, `least` to `most`, each label 1-MAX_LABEL letters.
static func _pairs_ok(rows: Variant, least: int, most: int) -> bool:
	if not rows is Array or not _in((rows as Array).size(), least, most):
		return false
	for row: Variant in rows:
		if not row is Array or (row as Array).size() != 2 or typeof(row[1]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		if not row[0] is String or not _in(str(row[0]).length(), 1, MAX_LABEL):
			return false
	return true


static func _num(p: Dictionary, key: String) -> float:
	var v: Variant = p.get(key)
	if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
		return float(v)
	return NAN


static func _int(p: Dictionary, key: String, default: int) -> int:
	var v: Variant = p.get(key, default)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _in(v: int, lo: int, hi: int) -> bool:
	return v >= lo and v <= hi
