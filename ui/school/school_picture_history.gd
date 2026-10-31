class_name SchoolPictureHistory
extends RefCounted
## Owner #70 and #73, grade 4 history ("How ancient people counted", research §6.4) and grade 5 history and geography
## (the Maya; latitude and longitude, time zones and climate zones, research §6.5): numbers of the past and the world's
## grid, drawn from data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only,
## no new art). Kinds and fields:
## - numerals {system: "egypt" | "babylon" | "maya", value, labels?}:
##   egypt (1-9,999): hieroglyph numbers, biggest first: a lotus flower for each 1,000, a coil of rope for each 100, a
##   heel bone for each 10 and a stroke for each 1, each drawn as many times as needed (no sign for zero: a place with
##   none is left out). labels: each group's worth under it ("300").
##   babylon (1-3,599): cuneiform in places of sixties: each place is corner wedges (tens) and upright wedges (ones) on a
##   clay tablet, the sixties' place on the left, a gap between the places. A number whose ones place would be empty
##   (120) is not drawn: the Babylonians left a gap there, which could not be told apart from no place at all.
##   labels: "sixties" and "ones" under the places.
##   maya (0-7,999): places of twenties stacked on bark paper, the biggest on top (400s, 20s, ones); each place a digit
##   0-19 drawn as bars (5 each) under dots (1 each), and a shell for 0. labels: "400s", "20s", "ones" beside the places.
## - latlong {lat_step? (10, 15, 20, 30, 45; 30), long_step? (15, 20, 30, 45, 60, 90; 30), lines?: ["tropics",
##   "polar"], points?: [{lat, long, label}] (up to 8; a label of 1-10 letters), night?: the longitude of midnight (the
##   half of the world around it shaded, the Sun over the other side), hours?: the hours from Greenwich over the meridians
##   (long_step 15 or 30), bands?: the climate bands shaded (tropical, temperate, polar)}: the whole world as a grid of
##   latitude (lines across, N and S of the Equator) and longitude (lines down, E and W of the Prime Meridian), the
##   Equator and the Prime Meridian drawn bold; no coastlines (places are dots with their names).

const KINDS: Array[String] = ["numerals", "latlong"]
const SYSTEMS: Array[String] = ["egypt", "babylon", "maya"]
const EGYPT_MAX := 9999
const BABYLON_MAX := 3599
const MAYA_MAX := 7999
const LAT_STEPS: Array[int] = [10, 15, 20, 30, 45]
const LONG_STEPS: Array[int] = [15, 20, 30, 45, 60, 90]
const LINES: Array[String] = ["tropics", "polar"]
const MAX_POINTS := 8
const MAX_PLACE_LABEL := 10
## The Tropics and the polar circles today (23°26′ and 66°34′; the lessons say "about 23.5°" and "about 66.5°").
const TROPIC := 23.44
const POLAR := 66.56
const INK := Color("1f2a4a")    # SchoolUi.INK
const CLAY := Color("dcb88c")
const CLAY_EDGE := Color("b08a5c")
const WEDGE := Color("5a3b22")
const LABEL := 18
const PAPER := Color("f1e3c2")    # Maya bark paper
const PAPER_EDGE := Color("c9ab78")
const MAYA_INK := Color("8b2a1a")
const OCEAN := Color("d6ebf8")
const GRID := Color("9fb7cf")
const EQUATOR := Color("d9463b")
const MERIDIAN := Color("1d4f91")
const TROPIC_LINE := Color("e08a00")
const POLAR_LINE := Color("3a7be8")
const NIGHT := Color(0.08, 0.12, 0.32, 0.38)
const SUN := Color("ffc93c")
const DOT := Color("f08a1c")
const BANDS := {"tropical": Color("fde2b0"), "temperate": Color("d8f0c8"), "polar": Color("e4f1ff")}
## A sign's width in cells (a cell is as wide as the signs are tall).
const EGYPT_WIDTH := {1000: 0.9, 100: 0.9, 10: 0.8, 1: 0.45}


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	if str(p.get("kind", "")) == "latlong":
		return _latlong_problem(p)
	var system := str(p.get("system", ""))
	if not SYSTEMS.has(system):
		return "numerals: system is egypt, babylon or maya"
	var v: Variant = p.get("value")
	if not _whole(v):
		return "numerals: a whole number value"
	var n := int(v)
	if system == "egypt" and (n < 1 or n > EGYPT_MAX):
		return "numerals: an Egyptian number is 1-%d" % EGYPT_MAX
	if system == "maya" and (n < 0 or n > MAYA_MAX):
		return "numerals: a Maya number is 0-%d (three places)" % MAYA_MAX
	if system == "babylon":
		if n < 1 or n > BABYLON_MAX:
			return "numerals: a Babylonian number is 1-%d (two places)" % BABYLON_MAX
		if n >= 60 and n % 60 == 0:
			return "numerals: a Babylonian number with an empty ones place (a gap) is not drawn"
	return ""


static func _latlong_problem(p: Dictionary) -> String:
	if p.has("lat_step") and not (_whole(p.lat_step) and LAT_STEPS.has(int(p.lat_step))):
		return "latlong: lat_step is one of %s" % [LAT_STEPS]
	if p.has("long_step") and not (_whole(p.long_step) and LONG_STEPS.has(int(p.long_step))):
		return "latlong: long_step is one of %s" % [LONG_STEPS]
	var lines: Variant = p.get("lines", [])
	if not lines is Array:
		return "latlong: lines is a list"
	for l: Variant in lines:
		if not LINES.has(str(l)):
			return "latlong: lines are %s" % [LINES]
	var points: Variant = p.get("points", [])
	if not points is Array or (points as Array).size() > MAX_POINTS:
		return "latlong: points is a list of at most %d" % MAX_POINTS
	for q: Variant in points:
		if not q is Dictionary or not _number(q.get("lat")) or not _number(q.get("long")):
			return "latlong: a point is {lat, long, label}"
		if absf(float(q.lat)) > 90.0 or absf(float(q.long)) > 180.0:
			return "latlong: a point's lat is -90 to 90 and its long -180 to 180"
		var label: Variant = q.get("label")
		if not label is String or str(label).strip_edges() == "" or str(label).length() > MAX_PLACE_LABEL:
			return "latlong: a point's label is 1-%d letters" % MAX_PLACE_LABEL
	if p.has("night") and (not _number(p.night) or absf(float(p.night)) > 180.0):
		return "latlong: night is a longitude, -180 to 180"
	if p.has("hours") and not p.hours is bool:
		return "latlong: hours is true or false"
	if bool(p.get("hours", false)) and not [15, 30].has(int(p.get("long_step", 30))):
		return "latlong: hours need long_step 15 or 30"
	if p.has("bands") and not p.bands is bool:
		return "latlong: bands is true or false"
	return ""


static func _whole(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v)))


static func _number(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT]


## The groups of signs an Egyptian number needs, biggest first: [worth, how many] for every digit that is not 0.
static func egypt_groups(n: int) -> Array:
	var out: Array = []
	for worth: int in [1000, 100, 10, 1]:
		var count := n / worth % 10
		if count > 0:
			out.append([worth, count])
	return out


## A Babylonian number's places, the sixties first: [tens, ones] in each (one place below 60).
static func babylon_places(n: int) -> Array:
	var places: Array[int] = [n]
	if n >= 60:
		places = [n / 60, n % 60]
	var out: Array = []
	for p in places:
		out.append([p / 10, p % 10])
	return out


## A Maya number's places, the biggest first: its digits in twenties (0 is one place: a shell).
static func maya_places(n: int) -> Array:
	var out: Array = []
	var left := n
	while true:
		out.push_front(left % 20)
		left /= 20
		if left == 0:
			break
	return out


## A Maya digit (0-19) as [bars, dots]: a bar is 5 and a dot 1; [0, 0] is the shell for zero.
static func maya_marks(digit: int) -> Array:
	return [digit / 5, digit % 5]


## "30°N", "0°", "45°S" (one decimal when not whole: "51.5°N").
static func lat_text(lat: float) -> String:
	return _deg(absf(lat)) + ("" if is_zero_approx(lat) else ("N" if lat > 0.0 else "S"))


## "60°E", "0°", "120°W", "180°".
static func long_text(lng: float) -> String:
	var plain := is_zero_approx(lng) or is_equal_approx(absf(lng), 180.0)
	return _deg(absf(lng)) + ("" if plain else ("E" if lng > 0.0 else "W"))


## A meridian's hours from Greenwich (15° is 1 hour): "+9", "0", "−5".
static func hour_text(lng: float) -> String:
	var h := roundi(lng / 15.0)
	return "0" if h == 0 else ("+%d" % h if h > 0 else "−%d" % -h)


static func _deg(v: float) -> String:
	return ("%d°" % roundi(v)) if is_equal_approx(v, roundf(v)) else ("%.1f°" % v)


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	if str(d.kind) == "latlong":
		_draw_latlong(pic, font, r, d)
	elif str(d.system) == "egypt":
		_draw_egypt(pic, font, r, int(d.value), bool(d.get("labels", false)))
	elif str(d.system) == "maya":
		_draw_maya(pic, font, r, int(d.value), bool(d.get("labels", false)))
	else:
		_draw_babylon(pic, font, r, int(d.value), bool(d.get("labels", false)))


# --- Egypt ------------------------------------------------------------------------------------------------------------

static func _draw_egypt(ci: CanvasItem, font: Font, r: Rect2, n: int, labels: bool) -> void:
	var groups := egypt_groups(n)
	var gap := 0.6
	var units := -gap
	var most_rows := 1
	for g: Array in groups:
		var shape := _egypt_shape(int(g[1]))
		units += shape.x * float(EGYPT_WIDTH[int(g[0])]) + gap
		most_rows = maxi(most_rows, shape.y)
	var label_h := LABEL + 10.0 if labels else 0.0
	var s := minf(minf(r.size.x / units, (r.size.y - label_h) / (most_rows * 1.08)), 96.0)
	var x := r.get_center().x - units * s * 0.5
	var top := r.get_center().y - (most_rows * 1.08 * s + label_h) * 0.5
	for g: Array in groups:
		var worth := int(g[0])
		var count := int(g[1])
		var shape := _egypt_shape(count)
		var w := float(EGYPT_WIDTH[worth]) * s
		var rows_top := top + (most_rows - shape.y) * 0.54 * s
		for i in count:
			var row := i / shape.x
			var col := i % shape.x
			var in_row := mini(shape.x, count - row * shape.x)
			var offset := (shape.x - in_row) * w * 0.5   # a shorter second row sits in the middle
			var cell := Rect2(Vector2(x + offset + col * w, rows_top + row * 1.08 * s), Vector2(w, s))
			_egypt_sign(ci, worth, cell, s)
		if labels:
			_label(ci, font, Vector2(x + shape.x * w * 0.5, top + most_rows * 1.08 * s + label_h * 0.5 + 2),
				GenKit.fmt(worth * count), LABEL)
		x += shape.x * w + gap * s


## Columns and rows of a group of `count` signs: one row of up to 4, else two rows (the longer on top).
static func _egypt_shape(count: int) -> Vector2i:
	if count <= 4:
		return Vector2i(count, 1)
	return Vector2i(int(ceil(count / 2.0)), 2)


static func _egypt_sign(ci: CanvasItem, worth: int, c: Rect2, s: float) -> void:
	var cx := c.get_center().x
	var top := c.position.y + 0.08 * s
	var bottom := c.end.y - 0.08 * s
	var lw := maxf(2.0, s * 0.09)
	match worth:
		1:   # a stroke
			ci.draw_line(Vector2(cx, top), Vector2(cx, bottom), INK, lw)
		10:   # a heel bone: an arch like an upside-down U
			var rad := 0.26 * s
			var mid := top + rad
			var pts := PackedVector2Array([Vector2(cx - rad, bottom)])
			for k in 13:
				var a := PI + PI * k / 12.0
				pts.append(Vector2(cx + cos(a) * rad, mid + sin(a) * rad))
			pts.append(Vector2(cx + rad, bottom))
			ci.draw_polyline(pts, INK, lw, true)
		100:   # a coil of rope: a spiral with its end hanging down
			var centre := Vector2(cx, top + 0.42 * s)
			var pts := PackedVector2Array()
			for k in 41:
				var t := 3.0 * PI * k / 40.0
				var rad := 0.05 * s + 0.3 * s * t / (3.0 * PI)
				pts.append(centre + Vector2(cos(t), sin(t)) * rad)
			pts.append(Vector2(pts[pts.size() - 1].x, bottom))
			ci.draw_polyline(pts, INK, maxf(2.0, s * 0.07), true)
		1000:   # a lotus flower on its stem, with a leaf
			var head_y := top + 0.36 * s
			ci.draw_line(Vector2(cx, head_y), Vector2(cx, bottom), INK, lw * 0.8)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx, top), Vector2(cx + 0.13 * s, top + 0.2 * s),
				Vector2(cx + 0.09 * s, head_y), Vector2(cx - 0.09 * s, head_y), Vector2(cx - 0.13 * s, top + 0.2 * s)]), INK)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 0.05 * s, head_y), Vector2(cx - 0.34 * s, top + 0.1 * s),
				Vector2(cx - 0.2 * s, head_y + 0.02 * s)]), INK)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx + 0.05 * s, head_y), Vector2(cx + 0.34 * s, top + 0.1 * s),
				Vector2(cx + 0.2 * s, head_y + 0.02 * s)]), INK)
			ci.draw_polyline(PackedVector2Array([Vector2(cx, bottom - 0.22 * s), Vector2(cx - 0.18 * s, bottom - 0.3 * s),
				Vector2(cx - 0.32 * s, bottom - 0.18 * s), Vector2(cx - 0.12 * s, bottom - 0.14 * s),
				Vector2(cx, bottom - 0.22 * s)]), INK, maxf(1.5, lw * 0.6), true)


# --- Babylon ----------------------------------------------------------------------------------------------------------

## Widths in units: a corner wedge column 0.7, an upright wedge column 0.5, 0.25 between tens and ones, 1.2 between
## places; heights: 3 rows of ones at 0.8 each.
static func _draw_babylon(ci: CanvasItem, font: Font, r: Rect2, n: int, labels: bool) -> void:
	var places := babylon_places(n)
	var place_gap := 1.2
	var units := -place_gap
	for p: Array in places:
		units += _place_width(int(p[0]), int(p[1])) + place_gap
	var label_h := LABEL + 10.0 if labels else 0.0
	var pad := 0.35
	var u := minf(minf((r.size.x - 8.0) / (units + 2 * pad), (r.size.y - label_h - 8.0) / (2.4 + 2 * pad)), 60.0)
	var tablet := Rect2(r.get_center() - Vector2((units + 2 * pad) * u, (2.4 + 2 * pad) * u + label_h) * 0.5,
		Vector2((units + 2 * pad) * u, (2.4 + 2 * pad) * u))
	var sb := StyleBoxFlat.new()
	sb.bg_color = CLAY
	sb.border_color = CLAY_EDGE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(u * 0.5))
	ci.draw_style_box(sb, tablet)
	var x := tablet.position.x + pad * u
	var top := tablet.position.y + pad * u
	var words: Array[String] = ["ones"]
	if places.size() == 2:
		words = ["sixties", "ones"]
	for i in places.size():
		var tens := int(places[i][0])
		var ones := int(places[i][1])
		var width := _place_width(tens, ones)
		var tens_cols := int(ceil(tens / 3.0))
		for k in tens:   # corner wedges in columns of 3
			var col := k / 3
			var row := k % 3
			var in_col := mini(3, tens - col * 3)
			var y := top + (3 - in_col) * 0.4 * u + row * 0.8 * u
			_corner_wedge(ci, Rect2(Vector2(x + col * 0.7 * u, y + 0.1 * u), Vector2(0.6 * u, 0.6 * u)))
		var ox := x + tens_cols * 0.7 * u + (0.25 * u if tens > 0 else 0.0)
		var ones_rows := int(ceil(ones / 3.0))
		for k in ones:   # upright wedges in rows of 3, the rows in the middle of the tablet
			var row := k / 3
			var col := k % 3
			var y := top + (3 - ones_rows) * 0.4 * u + row * 0.8 * u
			_upright_wedge(ci, Rect2(Vector2(ox + col * 0.5 * u, y), Vector2(0.42 * u, 0.75 * u)))
		if labels:
			_label(ci, font, Vector2(x + width * u * 0.5, tablet.end.y + label_h * 0.5 + 2), words[i], LABEL)
		x += (width + place_gap) * u


static func _place_width(tens: int, ones: int) -> float:
	var w := ceilf(tens / 3.0) * 0.7 + mini(ones, 3) * 0.5
	if tens > 0 and ones > 0:
		w += 0.25
	return w


## An upright wedge (1): a triangular head pressed by the reed's corner, and its tail.
static func _upright_wedge(ci: CanvasItem, b: Rect2) -> void:
	var cx := b.get_center().x
	ci.draw_colored_polygon(PackedVector2Array([b.position, Vector2(b.end.x, b.position.y),
		Vector2(cx, b.position.y + b.size.y * 0.38)]), WEDGE)
	ci.draw_line(Vector2(cx, b.position.y + b.size.y * 0.3), Vector2(cx, b.end.y), WEDGE, maxf(2.0, b.size.x * 0.2))


## A corner wedge (10): an angle opening to the right, its head at the point.
static func _corner_wedge(ci: CanvasItem, b: Rect2) -> void:
	var tip := Vector2(b.position.x, b.get_center().y)
	var lw := maxf(2.0, b.size.x * 0.14)
	ci.draw_line(tip, Vector2(b.end.x, b.position.y), WEDGE, lw)
	ci.draw_line(tip, Vector2(b.end.x, b.end.y), WEDGE, lw)
	ci.draw_colored_polygon(PackedVector2Array([tip, Vector2(b.position.x + b.size.x * 0.42, b.position.y + b.size.y * 0.24),
		Vector2(b.position.x + b.size.x * 0.42, b.end.y - b.size.y * 0.24)]), WEDGE)


# --- The Maya ---------------------------------------------------------------------------------------------------------

## In units (u): a place is 3.4 wide and 3.0 tall with 0.6 between places; bars 2.8 × 0.5 every 0.7 from the bottom,
## dots of radius 0.25 every 0.68 above them; the paper has 0.5 all round.
static func _draw_maya(ci: CanvasItem, font: Font, r: Rect2, n: int, labels: bool) -> void:
	var places := maya_places(n)
	var words: Array[String] = ["400s", "20s", "ones"]
	words = words.slice(3 - places.size())
	var label_w := 0.0
	if labels:
		for w in words:
			label_w = maxf(label_w, font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL).x + 16.0)
	var units_h := places.size() * 3.0 + (places.size() - 1) * 0.6 + 1.0
	var u := minf(minf((r.size.y - 8.0) / units_h, (r.size.x - label_w - 8.0) / 4.4), 44.0)
	var paper := Rect2(Vector2(r.get_center().x - (4.4 * u + label_w) * 0.5, r.get_center().y - units_h * u * 0.5),
		Vector2(4.4 * u, units_h * u))
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = PAPER_EDGE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(int(u * 0.3))
	ci.draw_style_box(sb, paper)
	for i in places.size():
		var slot := Rect2(Vector2(paper.position.x + 0.5 * u, paper.position.y + 0.5 * u + i * 3.6 * u),
			Vector2(3.4 * u, 3.0 * u))
		if i > 0:
			var y := slot.position.y - 0.3 * u
			ci.draw_dashed_line(Vector2(paper.position.x + 0.3 * u, y), Vector2(paper.end.x - 0.3 * u, y), PAPER_EDGE,
				maxf(1.5, u * 0.06), maxf(4.0, u * 0.25))
		_maya_digit(ci, int(places[i]), slot, u)
		if labels:
			var base := slot.get_center().y + (font.get_ascent(LABEL) - font.get_descent(LABEL)) * 0.5
			ci.draw_string(font, Vector2(paper.end.x + 12.0, base), words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL, INK)


## One Maya digit in the middle of its place: bars at the bottom, dots on top, or a shell for 0.
static func _maya_digit(ci: CanvasItem, digit: int, slot: Rect2, u: float) -> void:
	var cx := slot.get_center().x
	if digit == 0:   # a shell: an oval with ridges
		var c := slot.get_center()
		var pts := PackedVector2Array()
		for k in 33:
			var a := TAU * k / 32.0
			pts.append(c + Vector2(cos(a) * 1.15 * u, sin(a) * 0.62 * u))
		ci.draw_colored_polygon(pts, Color("fbf4e2"))
		ci.draw_polyline(pts, MAYA_INK, maxf(2.0, u * 0.1), true)
		for k: int in [-1, 0, 1]:
			var x := c.x + k * 0.45 * u
			var dy := absf(k) * 0.1 * u
			ci.draw_line(Vector2(x, c.y - 0.42 * u + dy), Vector2(x + k * 0.12 * u, c.y + 0.42 * u - dy), MAYA_INK,
				maxf(1.5, u * 0.07))
		return
	var marks := maya_marks(digit)
	var bars := int(marks[0])
	var dots := int(marks[1])
	var tall := bars * 0.7 + (0.7 if dots > 0 else 0.0)
	var bottom := slot.get_center().y + tall * 0.5 * u
	for b in bars:
		var sb := StyleBoxFlat.new()
		sb.bg_color = MAYA_INK
		sb.set_corner_radius_all(int(u * 0.2))
		ci.draw_style_box(sb, Rect2(Vector2(cx - 1.4 * u, bottom - (b + 1) * 0.7 * u + 0.1 * u), Vector2(2.8 * u, 0.5 * u)))
	var y := bottom - bars * 0.7 * u - 0.35 * u
	for k in dots:
		ci.draw_circle(Vector2(cx + (k - (dots - 1) * 0.5) * 0.68 * u, y), 0.25 * u, MAYA_INK)


# --- The world's grid ---------------------------------------------------------------------------------------------------

static func _draw_latlong(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := clampi(int(r.size.y / 17.0), 10, 16)
	var small := maxi(fs - 2, 9)
	var lat_step := int(d.get("lat_step", 30))
	var long_step := int(d.get("long_step", 30))
	var hours := bool(d.get("hours", false))
	var left := font.get_string_size("90°N", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8.0
	if hours:   # the word "hours" sits left of the hours row
		left = maxf(left, font.get_string_size("hours", HORIZONTAL_ALIGNMENT_LEFT, -1, small).x + 14.0
			+ font.get_string_size("−12", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5)
	var top := fs + 8.0 if hours else 4.0
	var w := r.size.x - left - 8.0
	var h := r.size.y - top - (fs + 8.0)
	var mw := minf(w, 2.0 * h)
	var map := Rect2(Vector2(r.position.x + left + (w - mw) * 0.5, r.position.y + top + (h - mw * 0.5) * 0.5),
		Vector2(mw, mw * 0.5))
	# The sea, or the climate bands.
	ci.draw_rect(map, OCEAN)
	if bool(d.get("bands", false)):
		for band: Array in [["polar", 90.0, POLAR], ["temperate", POLAR, TROPIC], ["tropical", TROPIC, -TROPIC],
				["temperate", -TROPIC, -POLAR], ["polar", -POLAR, -90.0]]:
			var a := _at(map, float(band[1]), -180.0)
			ci.draw_rect(Rect2(a, _at(map, float(band[2]), 180.0) - a), BANDS[str(band[0])])
	# Night: the half of the world within 90° of the midnight meridian; the Sun over the noon meridian.
	if d.has("night"):
		var mid := float(d.night)
		for off: float in [-360.0, 0.0, 360.0]:
			var from := maxf(mid - 90.0 + off, -180.0)
			var to := minf(mid + 90.0 + off, 180.0)
			if to > from:
				var a := _at(map, 90.0, from)
				ci.draw_rect(Rect2(a, _at(map, -90.0, to) - a), NIGHT)
		var sun := _at(map, 0.0, fposmod(mid + 360.0, 360.0) - 180.0)
		var rad := maxf(6.0, map.size.y * 0.06)
		ci.draw_circle(sun, rad, SUN)
		ci.draw_arc(sun, rad, 0.0, TAU, 24, Color("e0a000"), 2.0)
	# The grid, then the special lines.
	var lat := -90 + lat_step
	while lat < 90:
		if lat != 0:
			ci.draw_line(_at(map, lat, -180.0), _at(map, lat, 180.0), GRID, 1.5)
		lat += lat_step
	var lng := -180 + long_step
	while lng < 180:
		if lng != 0:
			ci.draw_line(_at(map, 90.0, lng), _at(map, -90.0, lng), GRID, 1.5)
		lng += long_step
	var lines: Array = d.get("lines", [])
	var named := map.size.y >= 150.0
	for line: Array in [["tropics", TROPIC, "Tropic of Cancer", TROPIC_LINE],
			["tropics", -TROPIC, "Tropic of Capricorn", TROPIC_LINE], ["polar", POLAR, "Arctic Circle", POLAR_LINE],
			["polar", -POLAR, "Antarctic Circle", POLAR_LINE]]:
		if not lines.has(line[0]):
			continue
		var a := _at(map, float(line[1]), -180.0)
		var b := _at(map, float(line[1]), 180.0)
		ci.draw_dashed_line(a, b, line[3], 2.0, 8.0)
		if named:
			_note(ci, font, Vector2(b.x - 4.0, a.y - 3.0), str(line[2]), small, line[3], true)
	ci.draw_line(_at(map, 0.0, -180.0), _at(map, 0.0, 180.0), EQUATOR, 3.0)
	ci.draw_line(_at(map, 90.0, 0.0), _at(map, -90.0, 0.0), MERIDIAN, 3.0)
	if named:   # the Equator's name at the left (the other lines' names are at the right)
		var e := _at(map, 0.0, -180.0)
		_note(ci, font, Vector2(e.x + 4.0, e.y - 3.0), "Equator", small, EQUATOR, false)
		var m := _at(map, 90.0, 0.0)
		_note(ci, font, Vector2(m.x + 4.0, m.y + small + 2.0), "Prime Meridian", small, MERIDIAN, false)
	ci.draw_rect(map, INK, false, 2.0)
	# Labels: latitude on the left, longitude below, hours above; every k-th line so they never crowd, 0 always.
	var lat_every := maxi(1, ceili(fs * 1.25 / (map.size.y * lat_step / 180.0)))
	for k in range(-90 / lat_step, 90 / lat_step + 1):
		if k % lat_every != 0 or hours and k * lat_step == 90:   # the word "hours" sits where 90°N would
			continue
		var t := lat_text(k * lat_step)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var y := _at(map, k * lat_step, 0.0).y + fs * 0.35
		ci.draw_string(font, Vector2(map.position.x - tw - 5.0, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var widest := font.get_string_size("180°W", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + fs   # room for 180° kept under the edge
	var long_every := maxi(1, ceili(widest / (map.size.x * long_step / 360.0)))
	for k in range(-180 / long_step, 180 / long_step + 1):
		if k % long_every != 0:
			continue
		var x := _at(map, 0.0, k * long_step).x
		var t := long_text(k * long_step)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tx := clampf(x - tw * 0.5, map.position.x, map.end.x - tw)   # 180° at the edges stays under the map
		ci.draw_string(font, Vector2(tx, map.end.y + fs + 3.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		if hours:
			var ht := hour_text(k * long_step)
			var hw := font.get_string_size(ht, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_string(font, Vector2(x - hw * 0.5, map.position.y - 5.0), ht, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, MERIDIAN)
	if hours:
		var hw := font.get_string_size("hours", HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
		var edge := font.get_string_size("−12", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5 + 6.0
		ci.draw_string(font, Vector2(map.position.x - hw - edge, map.position.y - 5.0), "hours", HORIZONTAL_ALIGNMENT_LEFT,
			-1, small, MERIDIAN)
	# The places: a dot and its name (on the dot's left near the right edge).
	for q: Dictionary in d.get("points", []):
		var c := _at(map, float(q.lat), float(q.long))
		var rad := maxf(4.0, map.size.y * 0.025)
		ci.draw_circle(c, rad + 1.5, INK)
		ci.draw_circle(c, rad, DOT)
		var t := str(q.label)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x := c.x + rad + 4.0 if c.x + rad + 4.0 + tw < map.end.x else c.x - rad - 4.0 - tw
		var y := clampf(c.y + fs * 0.35, map.position.y + fs, map.end.y - 3.0)
		ci.draw_string_outline(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.WHITE)
		ci.draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


## Where latitude `lat` and longitude `lng` are on `map` (the whole world, 360° across and 180° down).
static func _at(map: Rect2, lat: float, lng: float) -> Vector2:
	return Vector2(map.position.x + (lng + 180.0) / 360.0 * map.size.x, map.position.y + (90.0 - lat) / 180.0 * map.size.y)


## A line's name, ending at `at` (right) or starting there, with a white edge so it reads over the grid.
static func _note(ci: CanvasItem, font: Font, at: Vector2, text: String, size: int, colour: Color, right: bool) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := Vector2(at.x - w if right else at.x, at.y)
	ci.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color.WHITE)
	ci.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)


static func _label(ci: CanvasItem, font: Font, c: Vector2, text: String, size: int) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var base := c.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	ci.draw_string(font, Vector2(c.x - w * 0.5, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)
