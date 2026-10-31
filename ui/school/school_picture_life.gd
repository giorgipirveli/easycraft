class_name SchoolPictureLife
extends RefCounted
## Grade 3 health and PE, design and technology, and projects (owner #70, #73): the picture kinds they add, drawn from
## data onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art).
## Kinds and fields:
## - net {rows: ["#…", …] (1-6 rows of 1-6 letters, all as long; "." empty, "#" a square, "A"-"F" a lettered square)}:
##   squares of card joined edge to edge (a net of a cube, or a shape that is not one).
## - plate {hide?: a PLATE_PARTS part (shown grey with "?"), water?: false}: the balanced plate of food groups (the UK's
##   healthy plate for children: about a third fruit and vegetables, about a third starchy foods, some protein, some
##   dairy, a little oil) with its key, and a glass of water.
## - lever {pivot, load, effort (0-10 along the bar, all different), tags?: {pivot?, load?, effort?} (12 letters each)}:
##   a bar on its pivot, a crate for the load and a pushing arrow for the effort, each named (by its tag, or its word).
## - frame {frames: [FRAMES] (1-3, side by side), labels?: [text] (one each)}: bars joined at their corners: a square, a
##   square braced with a diagonal (two triangles), a triangle, and a square pushed out of shape.
## - weave {rows: ["ouou", …] (1-6 rows of 2-8 letters, all as long: "o" the weft goes over the warp, "u" under),
##   weft?: [THREADS names] (row by row, repeating), numbers?: true (each row's number at its left)}: a weave on a loom.
## - stitch {what: STITCHES}: a running stitch (up and down, even gaps, the needle at its end), backstitch (no gaps) or
##   overstitch (over the edge of two pieces).
## - pose {poses: [POSES] (1-4, side by side), labels?: [text] (14 letters each, one each)}: stick figures showing how
##   to move, facing right (the far arm and leg paler).

const KINDS: Array[String] = ["net", "plate", "lever", "frame", "weave", "stitch", "pose"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const NET_CARD := Color("f6d98b")
const NET_EDGE := Color("a8742a")
const PLATE_PARTS: Array[String] = ["fruit_veg", "starchy", "protein", "dairy", "oils"]
const PLATE_NAMES := {"fruit_veg": "fruit and vegetables", "starchy": "starchy foods", "protein": "protein",
	"dairy": "dairy", "oils": "oils: a little"}
## Shares of the plate in hundredths (the healthy plate: 39, 37, 12, 8 and a sliver of oil, drawn a little bigger).
const PLATE_SHARES := {"fruit_veg": 39, "starchy": 36, "protein": 13, "dairy": 9, "oils": 3}
const PLATE_COLORS := {"fruit_veg": Color("5cb85c"), "starchy": Color("f0b43c"), "protein": Color("e8748a"),
	"dairy": Color("5b9bd5"), "oils": Color("a77bd1")}
const WATER := Color("8fc9f2")
const FRAMES: Array[String] = ["square", "braced", "triangle", "pushed"]
const BAR := Color("8a5a36")
const STITCHES: Array[String] = ["running", "back", "over"]
const FABRIC := Color("cfe3f7")
const THREAD := Color("d9433b")
const THREADS := {"red": Color("d9433b"), "blue": Color("3a7be8"), "yellow": Color("f2c230"), "green": Color("3fa34d"),
	"orange": Color("f08a1c"), "purple": Color("8e5bc8"), "pink": Color("f08fb0"), "brown": Color("8a5a36"),
	"white": Color("f7f7f2"), "grey": Color("9aa1ad")}
const WARP := Color("f3ead2")
const MAX_NET := 6
const MAX_NET_SQUARES := 12
const MAX_TAG := 12
const MAX_LABEL := 14
const MAX_FIGURES := 4
const MAX_FRAMES := 3
## A stick figure's joints: x forwards (right), y up; the feet on the ground at 0, the top of the head about 1 (arms up
## reach 1.2). "l" is the far side (drawn paler), "r" the near side: elbow e, hand h, knee k, foot f.
const JOINTS: Array[String] = ["head", "neck", "hip", "le", "lh", "re", "rh", "lk", "lf", "rk", "rf"]
const POSES := {
	"stand": {"head": Vector2(0, 0.9), "neck": Vector2(0, 0.79), "hip": Vector2(0, 0.45), "le": Vector2(-0.05, 0.63),
		"lh": Vector2(-0.07, 0.47), "re": Vector2(0.05, 0.63), "rh": Vector2(0.07, 0.47), "lk": Vector2(-0.04, 0.23),
		"lf": Vector2(-0.05, 0.0), "rk": Vector2(0.04, 0.23), "rf": Vector2(0.05, 0.0)},
	"run": {"head": Vector2(0.11, 0.88), "neck": Vector2(0.07, 0.78), "hip": Vector2(0, 0.46),
		"le": Vector2(0.15, 0.65), "lh": Vector2(0.24, 0.76), "re": Vector2(-0.09, 0.66), "rh": Vector2(-0.14, 0.53),
		"lk": Vector2(-0.07, 0.25), "lf": Vector2(-0.21, 0.06), "rk": Vector2(0.17, 0.33), "rf": Vector2(0.12, 0.12)},
	"crouch": {"head": Vector2(0.18, 0.67), "neck": Vector2(0.12, 0.58), "hip": Vector2(-0.03, 0.3),
		"le": Vector2(-0.01, 0.48), "lh": Vector2(-0.13, 0.4), "re": Vector2(0.01, 0.47), "rh": Vector2(-0.11, 0.38),
		"lk": Vector2(0.1, 0.18), "lf": Vector2(0.0, 0.0), "rk": Vector2(0.13, 0.17), "rf": Vector2(0.04, 0.0)},
	"jump": {"head": Vector2(0, 1.0), "neck": Vector2(0, 0.89), "hip": Vector2(0, 0.56), "le": Vector2(-0.13, 1.0),
		"lh": Vector2(-0.17, 1.16), "re": Vector2(0.13, 1.0), "rh": Vector2(0.17, 1.16), "lk": Vector2(-0.03, 0.34),
		"lf": Vector2(-0.05, 0.12), "rk": Vector2(0.03, 0.34), "rf": Vector2(0.05, 0.12)},
	"land": {"head": Vector2(0.15, 0.71), "neck": Vector2(0.1, 0.61), "hip": Vector2(0, 0.3), "le": Vector2(0.21, 0.58),
		"lh": Vector2(0.35, 0.61), "re": Vector2(0.23, 0.56), "rh": Vector2(0.37, 0.59), "lk": Vector2(0.12, 0.17),
		"lf": Vector2(0.0, 0.0), "rk": Vector2(0.15, 0.16), "rf": Vector2(0.05, 0.0)},
	"throw": {"head": Vector2(-0.02, 0.89), "neck": Vector2(-0.02, 0.79), "hip": Vector2(0, 0.45),
		"le": Vector2(0.15, 0.78), "lh": Vector2(0.3, 0.8), "re": Vector2(-0.15, 0.82), "rh": Vector2(-0.26, 0.94),
		"lk": Vector2(0.1, 0.24), "lf": Vector2(0.19, 0.0), "rk": Vector2(-0.08, 0.23), "rf": Vector2(-0.17, 0.0),
		"ball": Vector2(-0.3, 0.99)},
	"catch": {"head": Vector2(0.03, 0.89), "neck": Vector2(0.02, 0.79), "hip": Vector2(0, 0.45),
		"le": Vector2(0.13, 0.69), "lh": Vector2(0.24, 0.74), "re": Vector2(0.12, 0.67), "rh": Vector2(0.23, 0.71),
		"lk": Vector2(0.02, 0.23), "lf": Vector2(-0.06, 0.0), "rk": Vector2(0.07, 0.23), "rf": Vector2(0.08, 0.0),
		"ball": Vector2(0.31, 0.73)},
	"star": {"head": Vector2(0, 0.9), "neck": Vector2(0, 0.79), "hip": Vector2(0, 0.45), "le": Vector2(-0.16, 0.86),
		"lh": Vector2(-0.3, 0.96), "re": Vector2(0.16, 0.86), "rh": Vector2(0.3, 0.96), "lk": Vector2(-0.11, 0.23),
		"lf": Vector2(-0.21, 0.0), "rk": Vector2(0.11, 0.23), "rf": Vector2(0.21, 0.0)},
	"stork": {"head": Vector2(0, 0.9), "neck": Vector2(0, 0.79), "hip": Vector2(0, 0.45), "le": Vector2(-0.17, 0.78),
		"lh": Vector2(-0.33, 0.78), "re": Vector2(0.17, 0.78), "rh": Vector2(0.33, 0.78), "lk": Vector2(-0.01, 0.23),
		"lf": Vector2(-0.01, 0.0), "rk": Vector2(0.15, 0.36), "rf": Vector2(0.04, 0.25)},
	"tuck": {"head": Vector2(0.03, 0.5), "neck": Vector2(-0.02, 0.39), "hip": Vector2(-0.08, 0.05),
		"le": Vector2(0.08, 0.24), "lh": Vector2(0.15, 0.14), "re": Vector2(0.09, 0.22), "rh": Vector2(0.17, 0.13),
		"lk": Vector2(0.1, 0.26), "lf": Vector2(0.13, 0.02), "rk": Vector2(0.12, 0.25), "rf": Vector2(0.15, 0.01)},
	"stretch": {"head": Vector2(0, 0.95), "neck": Vector2(0, 0.84), "hip": Vector2(0, 0.5), "le": Vector2(-0.11, 0.97),
		"lh": Vector2(-0.13, 1.14), "re": Vector2(0.11, 0.97), "rh": Vector2(0.13, 1.14), "lk": Vector2(-0.02, 0.28),
		"lf": Vector2(-0.02, 0.05), "rk": Vector2(0.02, 0.28), "rf": Vector2(0.03, 0.05)},
	"clap": {"head": Vector2(0, 0.9), "neck": Vector2(0, 0.79), "hip": Vector2(0, 0.45), "le": Vector2(0.09, 0.66),
		"lh": Vector2(0.17, 0.76), "re": Vector2(0.1, 0.65), "rh": Vector2(0.18, 0.75), "lk": Vector2(-0.04, 0.23),
		"lf": Vector2(-0.05, 0.0), "rk": Vector2(0.04, 0.23), "rf": Vector2(0.05, 0.0)},
}


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"net":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > MAX_NET:
				return "a net has 1-%d rows" % MAX_NET
			var width := -1
			var squares := 0
			for r: Variant in rows:
				if not r is String or str(r).length() < 1 or str(r).length() > MAX_NET:
					return "each row of a net is 1-%d letters" % MAX_NET
				if width >= 0 and str(r).length() != width:
					return "the rows of a net are all as long"
				width = str(r).length()
				for ch in str(r):
					if not ".#ABCDEF".contains(ch):
						return "a net's letters: . for empty, # for a square, A-F for a lettered square"
					squares += 0 if ch == "." else 1
			if squares < 1 or squares > MAX_NET_SQUARES:
				return "a net has 1-%d squares" % MAX_NET_SQUARES
		"plate":
			if p.has("hide") and not PLATE_PARTS.has(str(p.hide)):
				return "hide one of %s" % [PLATE_PARTS]
		"lever":
			var at := {}
			for k: String in ["pivot", "load", "effort"]:
				var v: Variant = p.get(k)
				if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or int(v) < 0 or int(v) > 10:
					return "a lever's %s is 0-10 along the bar" % k
				at[int(v)] = true
			if at.size() != 3:
				return "the pivot, the load and the effort are in different places"
			var tags: Variant = p.get("tags", {})
			if not tags is Dictionary:
				return "tags: {pivot, load, effort}"
			for k: Variant in tags:
				if not ["pivot", "load", "effort"].has(str(k)) or str(tags[k]).length() > MAX_TAG:
					return "a tag names the pivot, the load or the effort in up to %d letters" % MAX_TAG
		"frame":
			var why := _list_problem(p, "frames", FRAMES, MAX_FRAMES)
			if why != "":
				return why
		"weave":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > 6:
				return "a weave has 1-6 rows"
			var width := -1
			for r: Variant in rows:
				if not r is String or str(r).length() < 2 or str(r).length() > 8:
					return "each row of a weave is 2-8 letters"
				if width >= 0 and str(r).length() != width:
					return "the rows of a weave are all as long"
				width = str(r).length()
				for ch in str(r):
					if not ch in ["o", "u"]:
						return "a weave's letters: o (over) and u (under)"
			for c: Variant in p.get("weft", []):
				if not THREADS.has(str(c)):
					return "a weft colour is one of %s" % [THREADS.keys()]
		"stitch":
			if not STITCHES.has(str(p.get("what", ""))):
				return "a stitch is one of %s" % [STITCHES]
		"pose":
			var why := _list_problem(p, "poses", POSES.keys(), MAX_FIGURES)
			if why != "":
				return why
	return ""


## `p[key]`: 1-most names from `known`; `p.labels`, when there, one short text each.
static func _list_problem(p: Dictionary, key: String, known: Array, most: int) -> String:
	var list: Variant = p.get(key)
	if not list is Array or (list as Array).is_empty() or (list as Array).size() > most:
		return "%s: 1-%d of them" % [key, most]
	for v: Variant in list:
		if not known.has(str(v)):
			return "%s: '%s' is not one of %s" % [key, v, known]
	if p.has("labels"):
		var labels: Variant = p.labels
		if not labels is Array or (labels as Array).size() != (list as Array).size():
			return "one label for each of the %s" % key
		for l: Variant in labels:
			if str(l).length() > MAX_LABEL:
				return "a label is at most %d letters" % MAX_LABEL
	return ""


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"net":
			_draw_net(pic, font, r, d)
		"plate":
			_draw_plate(pic, font, r, d)
		"lever":
			_draw_lever(pic, font, r, d)
		"frame":
			_draw_frames(pic, font, r, d)
		"weave":
			_draw_weave(pic, font, r, d)
		"stitch":
			_draw_stitch(pic, r, str(d.what))
		"pose":
			_draw_poses(pic, font, r, d)


# --- net -------------------------------------------------------------------------------------------------------------

static func _draw_net(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var cols := str(rows[0]).length()
	var u := minf(minf(r.size.x / cols, r.size.y / rows.size()), 64.0)
	var origin := r.position + (r.size - Vector2(cols, rows.size()) * u) * 0.5
	var fs := clampi(int(u * 0.55), 12, 30)
	for y in rows.size():
		for x in cols:
			var ch := str(rows[y])[x]
			if ch == ".":
				continue
			var cell := Rect2(origin + Vector2(x, y) * u, Vector2(u, u))
			ci.draw_rect(cell, NET_CARD)
			ci.draw_rect(cell, NET_EDGE, false, maxf(2.0, u * 0.05))
			if ch != "#":
				_text(ci, font, cell.get_center() + Vector2(0, fs * 0.36), ch, fs)


# --- plate -----------------------------------------------------------------------------------------------------------

static func _draw_plate(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var hide := str(d.get("hide", ""))
	var water := bool(d.get("water", true))
	var dia := minf(r.size.y, r.size.x * 0.42)
	var centre := Vector2(r.position.x + dia * 0.5 + 2.0, r.get_center().y)
	var rad := dia * 0.5
	ci.draw_circle(centre, rad, Color.WHITE)
	ci.draw_arc(centre, rad, 0, TAU, 64, Color("b9c6dd"), 3.0)
	var inner := rad * 0.86
	var start := -PI * 0.5
	for part: String in PLATE_PARTS:
		var sweep := TAU * float(PLATE_SHARES[part]) / 100.0
		var pts := PackedVector2Array([centre])
		var steps := maxi(3, int(sweep / 0.08))
		for i in steps + 1:
			var a := start + sweep * i / steps
			pts.append(centre + Vector2(cos(a), sin(a)) * inner)
		var col: Color = Color("d5d9e0") if part == hide else PLATE_COLORS[part]
		ci.draw_colored_polygon(pts, col)
		ci.draw_polyline(pts + PackedVector2Array([centre]), Color.WHITE, 2.0)
		if part == hide:
			var mid := start + sweep * 0.5
			var fs := clampi(int(rad * 0.3), 14, 30)
			_text(ci, font, centre + Vector2(cos(mid), sin(mid)) * inner * 0.62 + Vector2(0, fs * 0.36), "?", fs)
		start += sweep
	# the key (and the glass of water) on the right
	var names: Array[String] = []
	for part: String in PLATE_PARTS:
		names.append("?" if part == hide else str(PLATE_NAMES[part]))
	if water:
		names.append("water")
	var key_x := centre.x + rad + 14.0
	var room := r.end.x - key_x
	var fs := 18
	while fs > 10 and font.get_string_size("fruit and vegetables", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + fs * 1.4 > room:
		fs -= 1
	var line := minf(r.size.y / names.size(), fs * 1.7)
	var y := r.get_center().y - line * names.size() * 0.5
	for i in names.size():
		var sw := Rect2(Vector2(key_x, y + (line - fs) * 0.5), Vector2(fs, fs))
		if i < PLATE_PARTS.size():
			var part := PLATE_PARTS[i]
			ci.draw_rect(sw, Color("d5d9e0") if part == hide else PLATE_COLORS[part])
		else:   # a glass of water
			var g := PackedVector2Array([sw.position, sw.position + Vector2(sw.size.x, 0),
				sw.end - Vector2(sw.size.x * 0.15, 0), Vector2(sw.position.x + sw.size.x * 0.15, sw.end.y)])
			ci.draw_colored_polygon(g, WATER)
			ci.draw_polyline(g + PackedVector2Array([g[0]]), INK, 1.5)
		ci.draw_string(font, Vector2(key_x + fs * 1.4, y + line * 0.5 + fs * 0.36), names[i], HORIZONTAL_ALIGNMENT_LEFT,
			-1, fs, INK)
		y += line


# --- lever -----------------------------------------------------------------------------------------------------------

static func _draw_lever(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var tags: Dictionary = d.get("tags", {})
	var fs := clampi(int(r.size.y * 0.09), 12, 22)
	var left := r.position.x + r.size.x * 0.06
	var span := r.size.x * 0.88
	var ground := r.end.y - fs * 1.6
	var tri := minf(r.size.y * 0.28, span * 0.1)
	var beam_y := ground - tri
	var thick := maxf(6.0, r.size.y * 0.045)
	var at := func(v: int) -> float: return left + span * v / 10.0
	ci.draw_line(Vector2(r.position.x, ground), Vector2(r.end.x, ground), Color("9aa1ad"), 2.0)
	var px: float = at.call(int(d.pivot))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(px, beam_y + thick * 0.5), Vector2(px + tri * 0.6, ground),
		Vector2(px - tri * 0.6, ground)]), Color("7b8494"))
	# owner #94: the effort pushes its end down and the load rises (SchoolPictureMotion.lever_tilt): the bar, the crate
	# and the arrow turn about the pivot's top; the words follow them upright
	var tilt := SchoolPictureMotion.lever_tilt(d, SchoolPicture.time_of(ci))
	var turn := Transform2D(tilt, Vector2(px, beam_y) - Vector2(px, beam_y).rotated(tilt))
	if tilt != 0.0:
		ci.draw_set_transform_matrix(turn)
	ci.draw_rect(Rect2(Vector2(left, beam_y - thick * 0.5), Vector2(span, thick)), BAR)
	var crate := minf(tri * 1.1, span * 0.13)
	var lx: float = at.call(int(d.load))
	var box := Rect2(Vector2(lx - crate * 0.5, beam_y - thick * 0.5 - crate), Vector2(crate, crate))
	ci.draw_rect(box, Color("c98b4a"))
	ci.draw_rect(box, Color("7a4b22"), false, 2.0)
	ci.draw_line(box.position, box.end, Color("7a4b22"), 1.5)
	ci.draw_line(Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), Color("7a4b22"), 1.5)
	var ex: float = at.call(int(d.effort))
	var tip := Vector2(ex, beam_y - thick * 0.5 - 3.0)
	var tail := tip - Vector2(0, crate * 1.2)
	_arrow(ci, tail, tip, Color("d9433b"), maxf(3.0, thick * 0.5))
	var load_at := Vector2(lx, box.position.y - fs * 0.4)
	var effort_at := Vector2(ex, tail.y - fs * 0.4)
	if tilt != 0.0:
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
		load_at = turn * load_at
		effort_at = turn * effort_at
	_text(ci, font, Vector2(px, ground + fs * 1.2), str(tags.get("pivot", "pivot")), fs)
	_text(ci, font, load_at, str(tags.get("load", "load")), fs)
	_text(ci, font, effort_at, str(tags.get("effort", "effort")), fs)


# --- frames ----------------------------------------------------------------------------------------------------------

static func _draw_frames(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var frames: Array = d.frames
	var labels: Array = d.get("labels", [])
	var n := frames.size()
	var fs := clampi(int(r.size.y * 0.1), 12, 22)
	var cell_w := r.size.x / n
	var label_room := fs * 2.0 if not labels.is_empty() else 0.0
	var side := minf(cell_w * 0.62, r.size.y - label_room - 16.0)
	var w := maxf(3.0, side * 0.06)
	var top := r.position.y + (r.size.y - side - label_room) * 0.5
	for i in n:
		var c := Vector2(r.position.x + cell_w * (i + 0.5), top + side * 0.5)
		var h := side * 0.5
		var pts: Array[Vector2] = []
		match str(frames[i]):
			"triangle":
				pts = [c + Vector2(-h, h), c + Vector2(h, h), c + Vector2(0, -h)]
			"pushed":
				pts = [c + Vector2(-h, h), c + Vector2(h, h), c + Vector2(h + h * 0.55, -h), c + Vector2(-h + h * 0.55, -h)]
			_:
				pts = [c + Vector2(-h, h), c + Vector2(h, h), c + Vector2(h, -h), c + Vector2(-h, -h)]
		for j in pts.size():
			ci.draw_line(pts[j], pts[(j + 1) % pts.size()], BAR, w)
		if str(frames[i]) == "braced":
			ci.draw_line(pts[0], pts[2], BAR, w)
		if str(frames[i]) == "pushed":
			var y := c.y - h
			_arrow(ci, Vector2(c.x - h * 1.35, y), Vector2(c.x - h * 0.55, y), Color("d9433b"), maxf(2.5, w * 0.7))
		for p in pts:
			ci.draw_circle(p, w * 0.9, Color("5a3a22"))
		if not labels.is_empty():
			_text(ci, font, Vector2(c.x, c.y + h + fs * 1.4), str(labels[i]), fs)


# --- weave -----------------------------------------------------------------------------------------------------------

static func _draw_weave(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var wefts: Array = d.get("weft", ["blue"])
	var numbers := bool(d.get("numbers", false))
	var cols := str(rows[0]).length()
	var left_room := 34.0 if numbers else 0.0
	var u := minf(minf((r.size.x - left_room) / (cols + 0.6), r.size.y / (rows.size() + 0.6)), 56.0)
	var size := Vector2(cols + 0.6, rows.size() + 0.6) * u
	var origin := r.position + Vector2(left_room, 0) + (r.size - Vector2(left_room, 0) - size) * 0.5 + Vector2(0.3, 0.3) * u
	var strip := u * 0.7
	var edge := Color(0, 0, 0, 0.35)
	# the warp: threads stretched from top to bottom
	for x in cols:
		var wr := Rect2(origin + Vector2(x * u + (u - strip) * 0.5, -0.3 * u), Vector2(strip, (rows.size() + 0.6) * u))
		ci.draw_rect(wr, WARP)
		ci.draw_rect(wr, edge, false, 1.5)
	# the weft, row by row: always seen between the warp threads, and on top where it goes over
	for y in rows.size():
		var col: Color = THREADS.get(str(wefts[y % wefts.size()]), THREADS.blue)
		var top := origin.y + y * u + (u - strip) * 0.5
		var row := str(rows[y])
		for x in cols:
			var cell_x := origin.x + x * u
			var gap_l := Rect2(Vector2(cell_x - (u - strip) * 0.5, top), Vector2(u - strip, strip))
			ci.draw_rect(gap_l, col)
			if row[x] == "o":
				var over := Rect2(Vector2(cell_x + (u - strip) * 0.5, top), Vector2(strip, strip))
				ci.draw_rect(over, col)
				ci.draw_rect(over, edge, false, 1.5)
		var gap_r := Rect2(Vector2(origin.x + cols * u - (u - strip) * 0.5, top), Vector2(u - strip, strip))
		ci.draw_rect(gap_r, col)
		if numbers:
			var fs := clampi(int(u * 0.5), 12, 22)
			_text(ci, font, Vector2(origin.x - 0.3 * u - left_room * 0.5, top + strip * 0.5 + fs * 0.36), str(y + 1), fs)


# --- stitches --------------------------------------------------------------------------------------------------------

static func _draw_stitch(ci: CanvasItem, r: Rect2, what: String) -> void:
	var cloth := Rect2(r.position + Vector2(r.size.x * 0.05, r.size.y * 0.18), Vector2(r.size.x * 0.9, r.size.y * 0.64))
	var w := maxf(3.0, r.size.y * 0.03)
	var y := cloth.get_center().y
	if what == "over":   # two pieces edge to edge, the thread looping over the join
		var top := Rect2(cloth.position, Vector2(cloth.size.x, cloth.size.y * 0.5 - 2.0))
		var bottom := Rect2(Vector2(cloth.position.x, y + 2.0), Vector2(cloth.size.x, cloth.size.y * 0.5 - 2.0))
		ci.draw_rect(top, FABRIC)
		ci.draw_rect(bottom, Color("f7d9c4"))
		ci.draw_rect(top, Color("7d9cc0"), false, 2.0)
		ci.draw_rect(bottom, Color("c69a7c"), false, 2.0)
		var step := cloth.size.x / 9.0
		var reach := cloth.size.y * 0.16
		for i in 8:
			var x := cloth.position.x + step * (i + 0.8)
			ci.draw_line(Vector2(x, y - reach), Vector2(x + step * 0.55, y + reach), THREAD, w)
		return
	ci.draw_rect(cloth, FABRIC)
	ci.draw_rect(cloth, Color("7d9cc0"), false, 2.0)
	var x0 := cloth.position.x + cloth.size.x * 0.08
	var x1 := cloth.position.x + cloth.size.x * 0.78
	var n := 6
	var step := (x1 - x0) / n
	for i in n:
		var a := x0 + step * i
		var b := a + (step * 0.55 if what == "running" else step - 2.0)
		ci.draw_line(Vector2(a, y), Vector2(b, y), THREAD, w)
		ci.draw_circle(Vector2(a, y), w * 0.45, Color("3b4a66"))
		ci.draw_circle(Vector2(b, y), w * 0.45, Color("3b4a66"))
	if what == "running":   # the needle at the end, its thread behind it
		var tip := Vector2(cloth.end.x - cloth.size.x * 0.02, y - cloth.size.y * 0.1)
		var eye := Vector2(x1 + step * 0.2, y + cloth.size.y * 0.05)
		ci.draw_line(eye, tip, Color("8b93a1"), w * 1.1)
		ci.draw_circle(eye, w * 0.9, Color("8b93a1"))
		ci.draw_circle(eye, w * 0.35, FABRIC)
		ci.draw_line(Vector2(x1 - step * 0.45, y), eye, THREAD, w * 0.6)


# --- poses -----------------------------------------------------------------------------------------------------------

static func _draw_poses(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var poses: Array = d.poses
	var labels: Array = d.get("labels", [])
	var n := poses.size()
	var fs := clampi(int(r.size.y * 0.09), 12, 22)
	var label_room := fs * 1.6 if not labels.is_empty() else 4.0
	var cell_w := r.size.x / n
	var unit := minf((r.size.y - label_room - 6.0) / 1.25, cell_w / 0.8)
	var ground := r.end.y - label_room
	for i in n:
		var foot := Vector2(r.position.x + cell_w * (i + 0.5), ground)
		ci.draw_line(foot - Vector2(cell_w * 0.4, 0), foot + Vector2(cell_w * 0.4, 0), Color("9aa1ad"), 2.0)
		_figure(ci, POSES[str(poses[i])], foot, unit)
		if not labels.is_empty():
			_text(ci, font, Vector2(foot.x, ground + fs * 1.25), str(labels[i]), fs)


static func _figure(ci: CanvasItem, pose: Dictionary, foot: Vector2, unit: float) -> void:
	var at := func(k: String) -> Vector2:
		var p: Vector2 = pose[k]
		return foot + Vector2(p.x, -p.y) * unit
	var w := maxf(3.0, unit * 0.045)
	var far := Color("8d97ab")
	var neck: Vector2 = at.call("neck")
	var hip: Vector2 = at.call("hip")
	var shoulder := neck.lerp(hip, 0.14)   # the arms hang from the shoulders, a little below the neck
	var limb := func(from: Vector2, a: String, b: String, col: Color) -> void:
		ci.draw_polyline(PackedVector2Array([from, at.call(a), at.call(b)]), col, w, true)
		ci.draw_circle(at.call(b), w * 0.6, col)   # a hand or a foot
	limb.call(shoulder, "le", "lh", far)
	limb.call(hip, "lk", "lf", far)
	ci.draw_line(neck, hip, INK, w * 1.3, true)
	limb.call(hip, "rk", "rf", INK)
	limb.call(shoulder, "re", "rh", INK)
	var head: Vector2 = at.call("head")
	ci.draw_circle(head, unit * 0.095, Color("fbe3c8"))
	ci.draw_arc(head, unit * 0.095, 0, TAU, 24, INK, w * 0.8, true)
	if pose.has("ball"):
		ci.draw_circle(at.call("ball"), unit * 0.045, Color("f08a1c"))
		ci.draw_arc(at.call("ball"), unit * 0.045, 0, TAU, 16, Color("a4520b"), 1.5, true)


# --- helpers ---------------------------------------------------------------------------------------------------------

static func _text(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(font, Vector2(center_base.x - w * 0.5, center_base.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)


## A line with a drawn head at `to` (the font has no arrows).
static func _arrow(ci: CanvasItem, from: Vector2, to: Vector2, col: Color, w: float) -> void:
	var dir := (to - from).normalized()
	var side := Vector2(-dir.y, dir.x)
	var head := w * 3.2
	ci.draw_line(from, to - dir * head * 0.8, col, w)
	ci.draw_colored_polygon(PackedVector2Array([to, to - dir * head + side * head * 0.6, to - dir * head - side * head * 0.6]),
		col)
