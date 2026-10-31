class_name SchoolPictureQuality
extends RefCounted
## Owner #94 (the lesson-quality brief): the picture kinds the older units needed and no kind drew, drawn from data onto
## a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the font has no
## arrows, so they are drawn). Kinds and fields:
## - inequality_line {from, to (whole numbers), step (whole, 1-20 steps from `from` to `to`), at (a number from `from` to
##   `to`), sign (">", "<", "≥", "≤"), letter? (1-3 letters, "x"), words? (true: "x > 5" written over the line)}: a
##   number line with the solutions of "letter sign at" shaded: a circle at `at`, open when `at` is not a solution (> and
##   <), filled when it is (≥ and ≤), and a thick ray from it to the end, with an arrowhead (it goes on for ever).
##   `holds(d, v)` says whether v is a solution.
## - word_blocks {parts: [{text (1-10 letters), role? (ROLES: prefix, root, suffix), means? (1-14 letters)}] (1-4), means?
##   (the whole word's meaning, 1-30 letters)}: a word built from coloured blocks side by side, prefixes blue, roots
##   green, suffixes orange, each part's meaning under it, and "= the whole meaning" below.
## - sentence_parts {parts: [{text (1-28 letters), tag (TAGS)}] (1-4), tags? (true: each part's tag under it)}: a
##   sentence cut into its parts, each on a tinted band in its tag's colour (clauses, phrases, subjects, verbs,
##   joining words), so the parts can be seen and named.
## - coordinate_plane {range (2-10: both axes from −range to range), step? (1 or 2: the numbers written), points?: [{x,
##   y (whole numbers in range), label? (1-2 letters)}] (0-6), join? (the points joined in order, and back to the first
##   when there are 3 or more)}: the four quadrants (the first quadrant's grid is grade 5's `grid`), each quadrant
##   named I-IV faintly, the origin marked.

const KINDS: Array[String] = ["inequality_line", "word_blocks", "sentence_parts", "coordinate_plane"]
const SIGNS: Array[String] = [">", "<", "≥", "≤"]
const ROLES: Array[String] = ["prefix", "root", "suffix"]
const TAGS: Array[String] = ["independent clause", "dependent clause", "phrase", "subject", "verb", "conjunction",
	"modifier"]
const MAX_STEPS := 20
const INK := Color("1f2a4a")
const PAPER := Color("fdf6e3")
const ORANGE := Color("f08a24")
const SHADE := Color("3a7be8")
const ROLE_COLOURS := {"prefix": Color("7fb3f5"), "root": Color("8ed081"), "suffix": Color("f5b971")}
const TAG_COLOURS := {"independent clause": Color("8ed081"), "dependent clause": Color("f5b971"),
	"phrase": Color("7fb3f5"), "subject": Color("c9a7f0"), "verb": Color("f59a9a"), "conjunction": Color("f2dd6b"),
	"modifier": Color("9fd9d6")}


## "" when `d` can be drawn; otherwise what is wrong.
static func problem(d: Dictionary) -> String:
	match str(d.get("kind", "")):
		"inequality_line":
			for k: String in ["from", "to", "step"]:
				if not _whole(d.get(k)):
					return "%s must be a whole number" % k
			var from := int(d.from)
			var to := int(d.to)
			var step := int(d.step)
			if step < 1 or to <= from or (to - from) % step != 0 or (to - from) / step > MAX_STEPS:
				return "from < to, and 1-%d whole steps between them" % MAX_STEPS
			if typeof(d.get("at")) not in [TYPE_INT, TYPE_FLOAT] or float(d.at) < from or float(d.at) > to:
				return "at: a number on the line"
			if not SIGNS.has(str(d.get("sign", ""))):
				return "sign: one of %s" % [SIGNS]
			var letter := str(d.get("letter", "x"))
			if letter.length() < 1 or letter.length() > 3:
				return "letter: 1-3 letters"
		"word_blocks":
			var parts: Variant = d.get("parts")
			if not parts is Array or (parts as Array).is_empty() or (parts as Array).size() > 4:
				return "1-4 parts"
			for p: Variant in parts:
				if not p is Dictionary:
					return "a part is {text, role?, means?}"
				var t := str((p as Dictionary).get("text", ""))
				if t.length() < 1 or t.length() > 10:
					return "a part's text is 1-10 letters"
				if (p as Dictionary).has("role") and not ROLES.has(str(p.role)):
					return "role: one of %s" % [ROLES]
				if str((p as Dictionary).get("means", "")).length() > 14:
					return "a part's meaning is at most 14 letters"
			if str(d.get("means", "")).length() > 30:
				return "the word's meaning is at most 30 letters"
		"sentence_parts":
			var parts: Variant = d.get("parts")
			if not parts is Array or (parts as Array).is_empty() or (parts as Array).size() > 4:
				return "1-4 parts"
			for p: Variant in parts:
				if not p is Dictionary:
					return "a part is {text, tag}"
				var t := str((p as Dictionary).get("text", ""))
				if t.length() < 1 or t.length() > 28:
					return "a part's text is 1-28 letters"
				if not TAGS.has(str((p as Dictionary).get("tag", ""))):
					return "tag: one of %s" % [TAGS]
		"coordinate_plane":
			if not _whole(d.get("range")) or int(d.range) < 2 or int(d.range) > 10:
				return "range: a whole number 2-10"
			if d.has("step") and not (_whole(d.step) and int(d.step) in [1, 2]):
				return "step: 1 or 2"
			var pts: Variant = d.get("points", [])
			if not pts is Array or (pts as Array).size() > 6:
				return "0-6 points"
			for pt: Variant in pts:
				if not pt is Dictionary or not _whole((pt as Dictionary).get("x")) or not _whole(pt.get("y")) \
						or absi(int(pt.x)) > int(d.range) or absi(int(pt.y)) > int(d.range):
					return "a point is {x, y} with whole numbers on the plane"
				if str((pt as Dictionary).get("label", "")).length() > 2:
					return "a point's label is 1-2 letters"
		_:
			return "not a quality kind"
	return ""


## Which quadrant (1-4) a point is in; 0 on an axis.
static func quadrant(x: int, y: int) -> int:
	if x == 0 or y == 0:
		return 0
	if x > 0:
		return 1 if y > 0 else 4
	return 2 if y > 0 else 3


## An inequality_line's rule: is v a solution of "letter sign at"?
static func holds(d: Dictionary, v: float) -> bool:
	var at := float(d.at)
	match str(d.sign):
		">":
			return v > at
		"<":
			return v < at
		"≥":
			return v >= at
		"≤":
			return v <= at
	return false


## Where the ray goes: +1 to the right (> and ≥), −1 to the left.
static func ray_way(d: Dictionary) -> int:
	return 1 if str(d.sign) in [">", "≥"] else -1


## Is the circle at `at` filled (at is a solution)?
static func filled(d: Dictionary) -> bool:
	return str(d.sign) in ["≥", "≤"]


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"inequality_line":
			_draw_inequality(pic, font, r, d)
		"word_blocks":
			_draw_word(pic, font, r, d)
		"sentence_parts":
			_draw_sentence(pic, font, r, d)
		"coordinate_plane":
			_draw_plane(pic, font, r, d)


static func _draw_inequality(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var from := int(d.from)
	var to := int(d.to)
	var step := int(d.step)
	var n := (to - from) / step
	var fs := clampi(int(r.size.y * 0.12), 14, 24)
	var y := r.position.y + r.size.y * 0.58
	var x0 := r.position.x + 34.0
	var x1 := r.end.x - 34.0
	var at_x := func(v: float) -> float: return x0 + (v - from) / float(to - from) * (x1 - x0)
	ci.draw_line(Vector2(x0 - 22, y), Vector2(x1 + 22, y), INK, 3.0)
	for i in n + 1:
		var x: float = at_x.call(from + i * step)
		ci.draw_line(Vector2(x, y - 10), Vector2(x, y + 10), INK, 2.0)
		_text(ci, font, Vector2(x, y + 14 + fs), _num(from + i * step), fs - (4 if n > 12 else 0), INK)
	var cx: float = at_x.call(float(d.at))
	var way := ray_way(d)
	var end_x := x1 + 20.0 if way > 0 else x0 - 20.0
	ci.draw_line(Vector2(cx + way * 11.0, y), Vector2(end_x - way * 12.0, y), SHADE, 9.0)
	var tip := Vector2(end_x + way * 6.0, y)
	ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-way * 20.0, -12.0), tip + Vector2(-way * 20.0, 12.0)]),
		SHADE)
	ci.draw_circle(Vector2(cx, y), 11.0, SHADE if filled(d) else Color.WHITE)
	ci.draw_arc(Vector2(cx, y), 11.0, 0, TAU, 28, SHADE, 3.0, true)
	if bool(d.get("words", true)):
		var words := "%s %s %s" % [str(d.get("letter", "x")), str(d.sign), _num(float(d.at))]
		_text(ci, font, Vector2(r.get_center().x, r.position.y + fs * 1.6), words, fs + 6, INK)


static func _draw_word(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var parts: Array = d.parts
	var fs := clampi(int(r.size.y * 0.2), 16, 44)
	var widths: Array[float] = []
	var total := 0.0
	for p: Dictionary in parts:
		var w := maxf(font.get_string_size(str(p.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28.0, 70.0)
		widths.append(w)
		total += w
	var scale := minf(1.0, (r.size.x - 8.0) / total)
	fs = maxi(12, int(fs * scale))
	var bh := fs * 1.7
	var has_means := str(d.get("means", "")) != ""
	var y0 := r.position.y + (r.size.y - bh - fs * 1.4 - (fs * 1.5 if has_means else 0.0)) * 0.5
	var x := r.get_center().x - total * scale * 0.5
	var mfs := maxi(11, int(fs * 0.5))
	for i in parts.size():
		var p: Dictionary = parts[i]
		var w := widths[i] * scale
		var box := Rect2(Vector2(x, y0), Vector2(w, bh))
		var colour: Color = ROLE_COLOURS.get(str(p.get("role", "root")), ROLE_COLOURS["root"])
		ci.draw_rect(box, colour)
		ci.draw_rect(box, INK, false, 2.0)
		_text(ci, font, Vector2(box.get_center().x, box.get_center().y + fs * 0.35), str(p.text), fs, INK)
		var under := str(p.get("means", ""))
		if under != "":
			_text(ci, font, Vector2(box.get_center().x, box.end.y + mfs * 1.5), under, _fit(font, under, w + 6.0, mfs), INK)
		if p.has("role"):
			_text(ci, font, Vector2(box.get_center().x, box.position.y - 6.0), str(p.role), maxi(10, int(mfs * 0.85)),
				Color(INK, 0.6))
		x += w
	if has_means:
		var line := "= " + str(d.means)
		_text(ci, font, Vector2(r.get_center().x, y0 + bh + fs * 1.4 + mfs * 2.2), line, _fit(font, line, r.size.x, mfs + 4),
			INK)


static func _draw_sentence(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var parts: Array = d.parts
	var tags := bool(d.get("tags", true))
	var fs := clampi(int(r.size.y * 0.13), 14, 28)
	var tfs := maxi(10, int(fs * 0.62))
	# Lay the parts out in rows that fit the card, a gap between parts.
	var rows: Array = [[]]
	var row_w := 0.0
	var gap := fs * 0.6
	for p: Dictionary in parts:
		var w := font.get_string_size(str(p.text), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16.0
		w = maxf(w, font.get_string_size(str(p.tag), HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x + 8.0) if tags else w
		if row_w > 0.0 and row_w + gap + w > r.size.x:
			rows.append([])
			row_w = 0.0
		(rows[-1] as Array).append([p, w])
		row_w += (gap if row_w > 0.0 else 0.0) + w
	var line_h := fs * 1.6 + (tfs * 1.6 if tags else 0.0)
	var y := r.position.y + (r.size.y - line_h * rows.size()) * 0.5
	for row: Array in rows:
		var width := 0.0
		for item: Array in row:
			width += float(item[1])
		width += gap * (row.size() - 1)
		var x := r.get_center().x - width * 0.5
		for item: Array in row:
			var p: Dictionary = item[0]
			var w := float(item[1])
			var colour: Color = TAG_COLOURS[str(p.tag)]
			var band := Rect2(Vector2(x, y), Vector2(w, fs * 1.4))
			ci.draw_rect(band, Color(colour, 0.45))
			ci.draw_line(Vector2(band.position.x, band.end.y), band.end, colour.darkened(0.3), 4.0)
			_text(ci, font, Vector2(band.get_center().x, band.position.y + fs * 1.05), str(p.text), fs, INK)
			if tags:
				_text(ci, font, Vector2(band.get_center().x, band.end.y + tfs * 1.3), str(p.tag), tfs,
					colour.darkened(0.45))
			x += w + gap
		y += line_h


static func _draw_plane(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var n := int(d.range)
	var step := int(d.get("step", 1 if n <= 6 else 2))
	var side := minf(r.size.x, r.size.y) - 8.0
	var cell := side / (2 * n)
	var c := r.get_center()
	var at := func(x: float, y: float) -> Vector2: return c + Vector2(x * cell, -y * cell)
	var fs := clampi(int(cell * 0.62), 9, 18)
	for i in range(-n, n + 1):
		var col := Color(INK, 0.12)
		ci.draw_line(at.call(i, -n), at.call(i, n), col, 1.0)
		ci.draw_line(at.call(-n, i), at.call(n, i), col, 1.0)
	ci.draw_line(at.call(-n - 0.4, 0), at.call(n + 0.4, 0), INK, 2.5)
	ci.draw_line(at.call(0, -n - 0.4), at.call(0, n + 0.4), INK, 2.5)
	for i in range(-n, n + 1):
		if i == 0 or i % step != 0:
			continue
		_text(ci, font, at.call(i, 0) + Vector2(0, fs + 3), _num(i), fs, INK)
		_text(ci, font, at.call(0, i) + Vector2(-fs * 0.9, fs * 0.35), _num(i), fs, INK)
	_text(ci, font, at.call(n + 0.4, 0) + Vector2(0, -6), "x", fs + 2, INK)
	_text(ci, font, at.call(0, n + 0.4) + Vector2(10, 4), "y", fs + 2, INK)
	for q: Array in [["I", 1, 1], ["II", -1, 1], ["III", -1, -1], ["IV", 1, -1]]:
		_text(ci, font, at.call(float(q[1]) * n * 0.75, float(q[2]) * n * 0.8), str(q[0]), fs + 4, Color(INK, 0.22))
	ci.draw_circle(at.call(0, 0), 3.5, INK)
	var pts: Array = d.get("points", [])
	if bool(d.get("join", false)) and pts.size() >= 2:
		var line := PackedVector2Array()
		for pt: Dictionary in pts:
			line.append(at.call(float(pt.x), float(pt.y)))
		if pts.size() >= 3:
			line.append(line[0])
		ci.draw_polyline(line, SHADE, 3.0, true)
	for pt: Dictionary in pts:
		var pos: Vector2 = at.call(float(pt.x), float(pt.y))
		ci.draw_circle(pos, maxf(4.0, cell * 0.22), ORANGE)
		ci.draw_arc(pos, maxf(4.0, cell * 0.22), 0, TAU, 20, INK, 1.5, true)
		var label := str(pt.get("label", ""))
		if label != "":
			_text(ci, font, pos + Vector2(cell * 0.55, -cell * 0.3), label, fs + 2, INK)


static func _whole(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) == floorf(float(v))


static func _num(v: float) -> String:
	var s := str(roundi(v)) if absf(v - roundf(v)) < 0.0001 else str(v)
	return s.replace("-", "−")


static func _fit(font: Font, text: String, width: float, fs: int) -> int:
	var size := fs
	while size > 9 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	return size


static func _text(ci: CanvasItem, font: Font, center_base: Vector2, text: String, fs: int, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(font, Vector2(center_base.x - w * 0.5, center_base.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
