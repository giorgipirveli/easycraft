class_name SchoolPictureG4Arts
extends RefCounted
## Owner #70 and #73, grade 4 computing, art and music (research §6.4): the picture kinds they add, drawn from data onto
## a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the font has
## no music signs, arrows or hieroglyphs, so they are drawn). Kinds and fields:
## - stave {notes: [STAVE_NOTES] (1-8), values? (each "semibreve", "minim" or "crotchet"; default crotchet; grade 5:
##   "dotted minim" and "quaver", half a beat, with its flag), names? (false: the letter under each note), words? (grade
##   5: a syllable under each note, 8 letters each, instead of the letters), mark? (a note's index, in orange), time?
##   ("2/4", "3/4", "4/4"), bars? (a bar line after every full bar; needs time)}: notes on the treble stave, the clef
##   drawn, middle C on a ledger line.
## - code {lines: [text] (1-9, 32 letters each; two spaces in front for each step in, at most 3), mark? (a line's
##   index)}: a program as blocks; the first word gives the colour: WHEN (events), IF, ELSE, REPEAT, FOREVER, WAIT
##   (control: their inner lines hang from a bar), SET, CHANGE (variables), DEFINE (grade 5: a procedure, its lines
##   hanging from its bar; a line that is only its name calls it, in the same colour), any other word an action.
## - flowchart {steps: [{shape: "start" | "end" | "step" | "decision", text (24 letters), no? (a decision's "no" box, 24
##   letters, that joins the next step), back? (a decision's "no" arrow back to an earlier step's index)}] (2-6)}: a
##   plan top to bottom; a decision's "yes" goes down to the next step, and its "no" box joins the step after that
##   (or the next one when there is none).
## - network {devices: [DEVICES] (1-5), wired? (the devices joined by a cable; the rest by radio, drawn dashed), router?
##   (true), internet? (false), server? (false), mark? ("router", "internet", "server" or a device's index)}: a home
##   network: the devices, the router, the internet and a server beyond it.
## - colour_wheel {size: 6 | 12, blank? [colours] (shown white with "?"), mark? [colours] (outlined), line? [two
##   colours] (joined across the middle: complementary), half? ("warm" | "cool": its five clear colours outlined),
##   names? (true for 6, false for 12)}: the painters' wheel, yellow at the top, going round by orange and red.
## - shading {shape: "sphere" | "cube" | "cylinder", light: "left" | "right", labels? (highlight, shadow, cast shadow),
##   flat? (only an outline filled flat: before shading), lamp? (true: the light drawn)}: a form lit from one side.
## - face {guides? (true), mark? ("eyes", "nose", "mouth", "ears"), eyes? ("halfway" | "high": a common mistake)}: a
##   head's proportions: eyes halfway down, the nose halfway from the eyes to the chin, the mouth a third of the way from
##   the nose to the chin, ears between the eye and nose lines, a face five eyes wide.
## - landscape {mark? ("foreground", "middle ground", "background", "horizon"), labels?}: near, middle and far.
## - pixel_art {rows: [text] (1-12 rows of 1-16 letters, all as long), key: {letter: a colour of SchoolPictureArts},
##   grid? (true)}: "." is an empty square.
## - relief {what: "low" | "high" | "sunken" | "round"}: a carving seen from the side and from the front ("round": a
##   statue standing free, for comparing).
## - print {items: [{text (1-2 letters or digits), on: "block" | "paper", flip? ("none", "mirror", "upside down")}]
##   (1-3), arrows?}: a printing block and what it prints, side by side.
## - orchestra {mark? (a FAMILIES name), hide? (its name shown as "?")}: the seats from above, the audience below.
## - glyphs {signs: [GLYPHS] (1-6), cartouche?, names? (the sound under each)}: Egyptian hieroglyphs that stand for sounds.

const KINDS: Array[String] = ["stave", "code", "flowchart", "network", "colour_wheel", "shading", "face", "landscape",
	"pixel_art", "relief", "print", "orchestra", "glyphs"]
## The treble stave's naturals, middle C (C4, a ledger line below) up to A5 (a ledger line above).
const STAVE_NOTES: Array[String] = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5"]
const NOTE_VALUES: Array[String] = ["semibreve", "dotted minim", "minim", "crotchet", "quaver"]
const VALUE_BEATS := {"semibreve": 4, "dotted minim": 3, "minim": 2, "crotchet": 1}
## Each value's length in half beats (a quaver is half a beat): the bars are counted in these.
const VALUE_HALVES := {"semibreve": 8, "dotted minim": 6, "minim": 4, "crotchet": 2, "quaver": 1}
const MAX_WORD := 8
const TIMES := {"2/4": 2, "3/4": 3, "4/4": 4}
const MAX_STAVE := 8
const MAX_CODE := 9
const MAX_CODE_LINE := 32
const MAX_DEPTH := 3
const EVENT_WORDS: Array[String] = ["WHEN"]
const CONTROL_WORDS: Array[String] = ["IF", "ELSE", "REPEAT", "FOREVER", "WAIT"]
const VARIABLE_WORDS: Array[String] = ["SET", "CHANGE"]
const PROCEDURE_WORD := "DEFINE"
const EVENT := Color("f2c12e")
const CONTROL := Color("f08a1c")
const VARIABLE := Color("d9507a")
const ACTION := Color("3a7be8")
const PROCEDURE := Color("8e5bd6")
const FLOW_SHAPES: Array[String] = ["start", "end", "step", "decision"]
const MAX_FLOW := 6
const MAX_FLOW_TEXT := 24
const DEVICES: Array[String] = ["laptop", "tablet", "phone", "computer", "printer", "speaker"]
const MAX_DEVICES := 5
const NET_PARTS: Array[String] = ["router", "internet", "server"]
## The painters' colour wheel from the top, clockwise: each colour's complementary colour is the one opposite.
const WHEEL: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]
const WHEEL6: Array[String] = ["yellow", "orange", "red", "purple", "blue", "green"]
## The clearly warm and cool colours (yellow-green and red-purple sit on the border and are left out).
const WARM: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red"]
const COOL: Array[String] = ["purple", "blue-purple", "blue", "blue-green", "green"]
const SHADED: Array[String] = ["sphere", "cube", "cylinder"]
const SIDES: Array[String] = ["left", "right"]
const FACE_PARTS: Array[String] = ["eyes", "nose", "mouth", "ears"]
const GROUNDS: Array[String] = ["foreground", "middle ground", "background", "horizon"]
const MAX_PIXELS := Vector2i(16, 12)
const RELIEFS: Array[String] = ["low", "high", "sunken", "round"]
const PRINT_ON: Array[String] = ["block", "paper"]
const FLIPS: Array[String] = ["none", "mirror", "upside down"]
const FAMILIES: Array[String] = ["strings", "woodwind", "brass", "percussion", "conductor"]
## Hieroglyphs that stand for one sound (their usual English letters).
const GLYPHS := {"water": "n", "mouth": "r", "bread": "t", "stool": "p", "basket": "k", "reed": "i", "foot": "b"}
const MAX_GLYPHS := 6
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const BLUE := Color("3a7be8")
const SOFT := Color("fce2b8")
const GRID_LINE := Color("b9c6dd")
const PAPER_WHITE := Color("fffdf7")


## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"stave":
			var notes: Variant = p.get("notes")
			if not notes is Array or (notes as Array).is_empty() or (notes as Array).size() > MAX_STAVE:
				return "stave: 1-%d notes" % MAX_STAVE
			for n: Variant in notes:
				if not n is String or not STAVE_NOTES.has(n):
					return "stave: '%s' is not one of %s" % [n, STAVE_NOTES]
			if p.has("values"):
				var values: Variant = p.values
				if not values is Array or (values as Array).size() != (notes as Array).size():
					return "stave: a value for every note"
				for v: Variant in values:
					if not v is String or not NOTE_VALUES.has(v):
						return "stave: a value is one of %s" % [NOTE_VALUES]
			if p.has("words"):
				var words: Variant = p.words
				if not words is Array or (words as Array).size() != (notes as Array).size():
					return "stave: a word for every note"
				for w: Variant in words:
					if not _short_text(w, MAX_WORD):
						return "stave: a word of 1-%d letters" % MAX_WORD
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (notes as Array).size() - 1):
				return "stave: mark is a note's index"
			if p.has("time") and not TIMES.has(str(p.time)):
				return "stave: time is one of %s" % [TIMES.keys()]
			if bool(p.get("bars", false)) and not p.has("time"):
				return "stave: bars need a time"
		"code":
			var lines: Variant = p.get("lines")
			if not lines is Array or (lines as Array).is_empty() or (lines as Array).size() > MAX_CODE:
				return "code: 1-%d lines" % MAX_CODE
			for l: Variant in lines:
				if not l is String or str(l).strip_edges() == "" or str(l).length() > MAX_CODE_LINE:
					return "code: a line of 1-%d letters" % MAX_CODE_LINE
				if _depth(str(l)) > MAX_DEPTH or (str(l).length() - str(l).lstrip(" ").length()) % 2 != 0:
					return "code: two spaces for each step in, at most %d" % MAX_DEPTH
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (lines as Array).size() - 1):
				return "code: mark is a line's index"
		"flowchart":
			var steps: Variant = p.get("steps")
			if not steps is Array or (steps as Array).size() < 2 or (steps as Array).size() > MAX_FLOW:
				return "flowchart: 2-%d steps" % MAX_FLOW
			for i in (steps as Array).size():
				var s: Variant = steps[i]
				if not s is Dictionary or not FLOW_SHAPES.has(str(s.get("shape", ""))):
					return "flowchart: a step's shape is one of %s" % [FLOW_SHAPES]
				if not _short_text(s.get("text"), MAX_FLOW_TEXT):
					return "flowchart: a step's text, 1-%d letters" % MAX_FLOW_TEXT
				if str(s.shape) == "decision":
					if i == (steps as Array).size() - 1:
						return "flowchart: a decision needs a step after it"
					if s.has("no") == s.has("back"):
						return "flowchart: a decision has a no box or a back arrow"
					if s.has("no") and not _short_text(s.no, MAX_FLOW_TEXT):
						return "flowchart: the no box's text, 1-%d letters" % MAX_FLOW_TEXT
					if s.has("back") and not _in(_int(s, "back", -1), 0, i - 1):
						return "flowchart: back goes to an earlier step"
				elif s.has("no") or s.has("back"):
					return "flowchart: only a decision has no or back"
		"network":
			var devices: Variant = p.get("devices")
			if not devices is Array or (devices as Array).is_empty() or (devices as Array).size() > MAX_DEVICES:
				return "network: 1-%d devices" % MAX_DEVICES
			for dv: Variant in devices:
				if not dv is String or not DEVICES.has(dv):
					return "network: a device is one of %s" % [DEVICES]
			for w: Variant in p.get("wired", []):
				if typeof(w) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(w), 0, (devices as Array).size() - 1):
					return "network: wired lists devices' indexes"
			if p.has("mark"):
				var m: Variant = p.mark
				var ok := (typeof(m) in [TYPE_INT, TYPE_FLOAT] and _in(int(m), 0, (devices as Array).size() - 1)) \
					or (m is String and NET_PARTS.has(m))
				if not ok:
					return "network: mark is a device's index or one of %s" % [NET_PARTS]
		"colour_wheel":
			var size := _int(p, "size", 0)
			if size != 6 and size != 12:
				return "colour_wheel: size 6 or 12"
			var wheel := WHEEL if size == 12 else WHEEL6
			for k: String in ["blank", "mark", "line"]:
				var cs: Variant = p.get(k, [])
				if not cs is Array:
					return "colour_wheel: %s is a list of colours" % k
				for c: Variant in cs:
					if not wheel.has(str(c)):
						return "colour_wheel: '%s' is not on the wheel of %d" % [c, size]
			if p.has("line") and (p.line as Array).size() != 2:
				return "colour_wheel: line joins two colours"
			if p.has("half") and not ["warm", "cool"].has(str(p.half)):
				return "colour_wheel: half is warm or cool"
		"shading":
			if not SHADED.has(str(p.get("shape", ""))) or not SIDES.has(str(p.get("light", ""))):
				return "shading: shape one of %s, light one of %s" % [SHADED, SIDES]
		"face":
			if p.has("mark") and not FACE_PARTS.has(str(p.mark)):
				return "face: mark is one of %s" % [FACE_PARTS]
			if p.has("eyes") and not ["halfway", "high"].has(str(p.eyes)):
				return "face: eyes halfway or high"
		"landscape":
			if p.has("mark") and not GROUNDS.has(str(p.mark)):
				return "landscape: mark is one of %s" % [GROUNDS]
		"pixel_art":
			var rows: Variant = p.get("rows")
			var key: Variant = p.get("key")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > MAX_PIXELS.y \
					or not key is Dictionary:
				return "pixel_art: 1-%d rows and a key" % MAX_PIXELS.y
			for k: Variant in key:
				if str(k).length() != 1 or str(k) == "." or not SchoolPictureArts.COLOURS.has(str(key[k])):
					return "pixel_art: the key gives letters colours of SchoolPictureArts"
			var w := str(rows[0]).length()
			for row: Variant in rows:
				if not row is String or str(row).length() != w or w < 1 or w > MAX_PIXELS.x:
					return "pixel_art: rows of 1-%d letters, all as long" % MAX_PIXELS.x
				for ch in str(row):
					if ch != "." and not key.has(ch):
						return "pixel_art: '%s' is not in the key" % ch
		"relief":
			if not RELIEFS.has(str(p.get("what", ""))):
				return "relief: what is one of %s" % [RELIEFS]
		"print":
			var items: Variant = p.get("items")
			if not items is Array or (items as Array).is_empty() or (items as Array).size() > 3:
				return "print: 1-3 items"
			for it: Variant in items:
				if not it is Dictionary or not _short_text(it.get("text"), 2) \
						or not PRINT_ON.has(str(it.get("on", ""))) or not FLIPS.has(str(it.get("flip", "none"))):
					return "print: an item is {text (1-2 letters), on: block or paper, flip?}"
		"orchestra":
			for k: String in ["mark", "hide"]:
				if p.has(k) and not FAMILIES.has(str(p[k])):
					return "orchestra: %s is one of %s" % [k, FAMILIES]
		"glyphs":
			var signs: Variant = p.get("signs")
			if not signs is Array or (signs as Array).is_empty() or (signs as Array).size() > MAX_GLYPHS:
				return "glyphs: 1-%d signs" % MAX_GLYPHS
			for s: Variant in signs:
				if not GLYPHS.has(str(s)):
					return "glyphs: a sign is one of %s" % [GLYPHS.keys()]
		_:
			return "not a grade 4 arts kind"
	return ""


## A note's place on the treble stave in half-gaps from the bottom line (E4 = 0: even on a line, odd in a space; middle
## C is -2, on a ledger line below); -99 for a note the stave doesn't show.
static func stave_step(note: String) -> int:
	var i := STAVE_NOTES.find(note)
	return i - 2 if i >= 0 else -99


## The colour opposite `colour` on the painters' wheel of 12 (its complementary colour).
static func opposite(colour: String) -> String:
	var i := WHEEL.find(colour)
	return WHEEL[(i + 6) % WHEEL.size()] if i >= 0 else ""


## A pixel picture's pixels: all of them ("") or those of one letter ("." the empty ones).
static func pixels_of(d: Dictionary, letter: String) -> int:
	var n := 0
	for row: Variant in d.get("rows", []):
		n += str(row).length() if letter == "" else str(row).count(letter)
	return n


static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"stave":
			_draw_stave(pic, font, r, d)
		"code":
			_draw_code(pic, font, r, d)
		"flowchart":
			_draw_flowchart(pic, font, r, d)
		"network":
			_draw_network(pic, font, r, d)
		"colour_wheel":
			_draw_wheel(pic, font, r, d)
		"shading":
			_draw_shading(pic, font, r, d)
		"face":
			_draw_face(pic, r, d)
		"landscape":
			_draw_landscape(pic, font, r, d)
		"pixel_art":
			_draw_pixels(pic, r, d)
		"relief":
			_draw_relief(pic, font, r, d)
		"print":
			_draw_print(pic, font, r, d)
		"orchestra":
			_draw_orchestra(pic, font, r, d)
		"glyphs":
			_draw_glyphs(pic, font, r, d)


# --- stave -----------------------------------------------------------------------------------------------------------

static func _draw_stave(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var notes: Array = d.notes
	var values: Array = d.get("values", [])
	var words: Array = d.get("words", [])
	var names := bool(d.get("names", false)) or not words.is_empty()
	var time := str(d.get("time", ""))
	var bars := bool(d.get("bars", false))
	var mark := _int(d, "mark", -1)
	var fs := clampi(int(r.size.y * 0.12), 11, 22)
	var name_h := fs * 1.4 if names else 0.0
	var n := notes.size()
	# u: half a gap between lines. The picture spans steps -3.5 (the clef's tail) to 11.5 (its top); the clef is 4 u
	# wide, a time signature 3 u, each note 5 u.
	var lead := 5.0 + (3.2 if time != "" else 0.0)
	var slot := 4.4
	var u := minf((r.size.y - name_h) / 15.5, r.size.x / (lead + n * slot + 1.0))
	var base_y := r.position.y + (r.size.y - name_h) * 0.5 + 4.0 * u   # the bottom line (E4): the stave's middle line centred
	var width := (lead + n * slot + 1.0) * u
	var x0 := r.position.x + (r.size.x - width) * 0.5
	var lw := maxf(1.2, u * 0.12)
	for i in 5:
		var y := base_y - i * 2.0 * u
		ci.draw_line(Vector2(x0, y), Vector2(x0 + width, y), INK, lw)
	_treble_clef(ci, Vector2(x0 + 2.2 * u, base_y), u, lw)
	var at := x0 + 5.0 * u
	if time != "":
		var tfs := clampi(int(u * 3.6), 10, 64)
		_label(ci, font, Vector2(at + 1.4 * u, base_y - 6.0 * u), time.get_slice("/", 0), tfs)
		_label(ci, font, Vector2(at + 1.4 * u, base_y - 2.0 * u), time.get_slice("/", 1), tfs)
		at += 3.2 * u
	var per_bar := int(TIMES.get(time, 4)) * 2   # in half beats
	var beats := 0
	var total := 0
	for i in n:
		total += int(VALUE_HALVES[str(values[i]) if i < values.size() else "crotchet"])
	for i in n:
		var note := str(notes[i])
		var value := str(values[i]) if i < values.size() else "crotchet"
		var s := stave_step(note)
		var c := Vector2(at + slot * 0.5 * u, base_y - s * u)
		var col := SHADE if i == mark else INK
		for ledger: int in [-2, 10]:
			if (ledger < 0 and s <= ledger) or (ledger > 0 and s >= ledger):
				var ly := base_y - ledger * u
				ci.draw_line(Vector2(c.x - 1.9 * u, ly), Vector2(c.x + 1.9 * u, ly), INK, lw)
		_stave_note(ci, c, u, lw, value, s < 4, col)
		if names:
			var said := str(words[i]) if not words.is_empty() else note.left(1)
			_label(ci, font, Vector2(c.x, r.end.y - name_h * 0.5), said, _fit(font, said, fs, slot * u * 0.98), col)
		at += slot * u
		beats += int(VALUE_HALVES[value])
		if bars and beats % per_bar == 0:
			var bx := at - 0.2 * u
			if beats < total:
				ci.draw_line(Vector2(bx, base_y), Vector2(bx, base_y - 8.0 * u), INK, lw)
			else:
				ci.draw_line(Vector2(bx - 0.9 * u, base_y), Vector2(bx - 0.9 * u, base_y - 8.0 * u), INK, lw)
				ci.draw_line(Vector2(bx, base_y), Vector2(bx, base_y - 8.0 * u), INK, lw * 2.6)


## A note's head (filled for a crotchet and a quaver, open for a minim and a semibreve) and its stem (none for a
## semibreve): up on the right below the middle line, down on the left from it upwards; a quaver's flag, a dotted
## minim's dot.
static func _stave_note(ci: CanvasItem, c: Vector2, u: float, lw: float, value: String, up: bool, col: Color) -> void:
	var rx := u * (1.45 if value == "semibreve" else 1.2)
	var ry := u * 0.9
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(cos(t) * rx, sin(t) * ry).rotated(-0.35 if value != "semibreve" else -0.15))
	if value == "crotchet" or value == "quaver":
		ci.draw_colored_polygon(pts, col)
	else:
		var ring := pts.duplicate()
		ring.append(pts[0])
		ci.draw_polyline(ring, col, lw * (2.2 if value == "semibreve" else 1.8), true)
	if value == "semibreve":
		return
	var sx := c.x + (rx * 0.92 if up else -rx * 0.92)
	var tip := Vector2(sx, c.y + (-7.0 * u if up else 7.0 * u))
	ci.draw_line(Vector2(sx, c.y), tip, col, lw * 1.2)
	if value == "dotted minim":
		ci.draw_circle(c + Vector2(rx + u * 0.9, -u * 0.35), u * 0.38, col)
	elif value == "quaver":   # the flag: from the stem's tip, curving out to the right and back towards the head
		var dir := 1.0 if up else -1.0
		var flag := PackedVector2Array([tip, tip + Vector2(u * 0.9, dir * u * 1.6), tip + Vector2(u * 1.7, dir * u * 3.0),
			tip + Vector2(u * 1.2, dir * u * 4.6)])
		ci.draw_polyline(_catmull(flag, 5), col, lw * 1.6, true)


## The treble (G) clef: a spiral round the G line, up to a loop above the stave, then down through it to a hook.
static func _treble_clef(ci: CanvasItem, g_line_left: Vector2, u: float, lw: float) -> void:
	# points in (x, steps up from the bottom line), x in u from the clef's middle
	var raw: Array[Vector2] = [Vector2(0.35, 2.9), Vector2(-0.35, 2.7), Vector2(-0.55, 1.9), Vector2(0.0, 1.1),
		Vector2(1.0, 1.0), Vector2(1.7, 1.9), Vector2(1.6, 3.4), Vector2(0.6, 4.3), Vector2(-0.8, 4.1),
		Vector2(-1.7, 2.9), Vector2(-1.7, 1.1), Vector2(-0.8, -0.2), Vector2(0.6, -0.5), Vector2(1.3, 0.2),
		Vector2(1.2, 2.2), Vector2(0.5, 5.5), Vector2(0.2, 8.0), Vector2(0.5, 10.2), Vector2(1.1, 11.2),
		Vector2(1.2, 10.2), Vector2(0.5, 8.7), Vector2(-0.4, 7.2), Vector2(-0.3, 5.0), Vector2(0.2, 2.0),
		Vector2(0.6, -1.0), Vector2(0.6, -2.6), Vector2(0.0, -3.3), Vector2(-0.7, -3.0)]
	var pts := PackedVector2Array()
	for p in raw:
		pts.append(g_line_left + Vector2(p.x * u, -p.y * u))
	var smooth := _catmull(pts, 6)
	ci.draw_polyline(smooth, INK, lw * 2.0, true)
	ci.draw_circle(g_line_left + Vector2(-0.55 * u, 2.55 * u), u * 0.55, INK)


# --- code ------------------------------------------------------------------------------------------------------------

static func _draw_code(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var lines: Array = d.lines
	var n := lines.size()
	var mark := _int(d, "mark", -1)
	var rh := minf(r.size.y / n, 58.0)
	var fs := clampi(int(rh * 0.6), 11, 26)
	var iw := rh * 0.8
	var y0 := r.position.y + (r.size.y - rh * n) * 0.5
	var widest := 0.0
	for l: Variant in lines:
		widest = maxf(widest, _depth(str(l)) * iw + font.get_string_size(str(l).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT,
			-1, fs).x + rh * 0.7)
	var x0 := r.position.x + maxf(0.0, (r.size.x - widest) * 0.5)
	var procs := {}   # grade 5: DEFINE name, and lines that call it by its name
	for l: Variant in lines:
		if _first_word(str(l).strip_edges()) == PROCEDURE_WORD:
			procs[str(l).strip_edges().substr(PROCEDURE_WORD.length() + 1)] = true
	for i in n:   # the control blocks' bars first, under their inner lines
		var text := str(lines[i]).strip_edges()
		var word := _first_word(text)
		if not (CONTROL_WORDS.has(word) or word == PROCEDURE_WORD) or word == "WAIT":
			continue
		var depth := _depth(str(lines[i]))
		var last := i
		for j in range(i + 1, n):
			if _depth(str(lines[j])) <= depth:
				break
			last = j
		if last > i:
			var bar := Rect2(Vector2(x0 + depth * iw, y0 + i * rh + rh * 0.5), Vector2(iw * 0.42, (last - i) * rh + rh * 0.4))
			ci.draw_rect(bar, _block_colour(text))
	for i in n:
		var text := str(lines[i]).strip_edges()
		var depth := _depth(str(lines[i]))
		var colour := PROCEDURE if procs.has(text) else _block_colour(text)
		var x := x0 + depth * iw
		var fsize := _fit(font, text, fs, r.end.x - x - rh * 0.6)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + rh * 0.6
		var box := Rect2(Vector2(x, y0 + i * rh + rh * 0.07), Vector2(w, rh * 0.86))
		var sb := StyleBoxFlat.new()
		sb.bg_color = colour
		sb.set_corner_radius_all(int(rh * 0.2))
		if _first_word(text) in ["WHEN", PROCEDURE_WORD]:   # an event's or a procedure's hat: a rounder top
			sb.corner_radius_top_left = int(rh * 0.42)
			sb.corner_radius_top_right = int(rh * 0.42)
		sb.set_border_width_all(4 if i == mark else 1)
		sb.border_color = SHADE if i == mark else colour.darkened(0.3)
		ci.draw_style_box(sb, box)
		var ink := INK if colour.get_luminance() > 0.55 else Color.WHITE
		var base := box.get_center().y + (font.get_ascent(fsize) - font.get_descent(fsize)) * 0.5
		ci.draw_string(font, Vector2(x + rh * 0.3, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, ink)
		if i == mark:   # grade 5: a pointer at the marked line, so "the marked line" is plain at any size
			var tip := Vector2(box.end.x + rh * 0.12, box.get_center().y)
			ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(rh * 0.55, -rh * 0.36),
				tip + Vector2(rh * 0.55, rh * 0.36)]), SHADE)


static func _depth(line: String) -> int:
	return int((line.length() - line.lstrip(" ").length()) / 2.0)


static func _first_word(text: String) -> String:
	return text.get_slice(" ", 0).to_upper()


static func _block_colour(text: String) -> Color:
	var w := _first_word(text)
	if EVENT_WORDS.has(w):
		return EVENT
	if CONTROL_WORDS.has(w):
		return CONTROL
	if VARIABLE_WORDS.has(w):
		return VARIABLE
	if w == PROCEDURE_WORD:
		return PROCEDURE
	return ACTION


# --- flowchart -------------------------------------------------------------------------------------------------------

static func _draw_flowchart(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var steps: Array = d.steps
	var n := steps.size()
	var side := false
	var back := false
	for s: Dictionary in steps:
		side = side or s.has("no")
		back = back or s.has("back")
	var rh := r.size.y / n
	var bh := minf(rh * 0.7, 60.0)
	var bw := minf(r.size.x * (0.4 if side else 0.56), bh * 5.0)
	var cx := r.position.x + r.size.x * (0.38 if side else 0.5) + (r.size.x * 0.05 if back else 0.0)
	var sx := r.position.x + r.size.x * 0.8
	var fs := clampi(int(bh * 0.46), 10, 20)
	var lw := clampf(bh * 0.05, 1.5, 3.0)
	var centres: Array[Vector2] = []
	for i in n:
		centres.append(Vector2(cx, r.position.y + (i + 0.5) * rh))
	for i in n - 1:   # arrows down (a decision's "yes")
		var a := centres[i] + Vector2(0, _half_height(steps[i], bh))
		var b := centres[i + 1] - Vector2(0, _half_height(steps[i + 1], bh))
		_arrow(ci, a, b, lw)
		if str(steps[i].shape) == "decision":
			_label(ci, font, a.lerp(b, 0.5) + Vector2(-fs * 1.3, 0), "yes", fs, INK)
	for i in n:
		var s: Dictionary = steps[i]
		_flow_box(ci, font, centres[i], Vector2(bw, bh), str(s.shape), str(s.text), fs, lw)
		if s.has("no"):
			var box_c := Vector2(sx, centres[i].y)
			var sbw := minf(r.size.x * 0.34, bh * 4.2)
			var from_x := centres[i].x + bw * 0.5
			_arrow(ci, Vector2(from_x, centres[i].y), box_c - Vector2(sbw * 0.5, 0), lw)
			_label(ci, font, Vector2((from_x + box_c.x - sbw * 0.5) * 0.5, centres[i].y - fs * 0.75), "no", fs, INK)
			_flow_box(ci, font, box_c, Vector2(sbw, bh), "step", str(s.no), fs, lw)
			var j := i + 2 if i + 2 < n else i + 1
			var join := centres[j] + Vector2(_half_width(steps[j], bw), 0)
			var corner := Vector2(box_c.x, join.y)
			ci.draw_line(box_c + Vector2(0, bh * 0.5), corner, INK, lw, true)
			_arrow(ci, corner, join, lw)
		if s.has("back"):
			var to := centres[int(s.back)] - Vector2(_half_width(steps[int(s.back)], bw), 0)
			var from := centres[i] - Vector2(bw * 0.5, 0)
			var lx := minf(from.x, to.x) - maxf(fs * 1.6, bw * 0.16)
			ci.draw_line(from, Vector2(lx, from.y), INK, lw, true)
			ci.draw_line(Vector2(lx, from.y), Vector2(lx, to.y), INK, lw, true)
			_arrow(ci, Vector2(lx, to.y), to, lw)
			_label(ci, font, Vector2(lx + (from.x - lx) * 0.5, from.y - fs * 0.7), "no", fs, INK)


static func _half_height(step: Dictionary, bh: float) -> float:
	return bh * (0.6 if str(step.shape) == "decision" else 0.5)


static func _half_width(step: Dictionary, bw: float) -> float:
	return bw * 0.5


static func _flow_box(ci: CanvasItem, font: Font, c: Vector2, size: Vector2, shape: String, text: String, fs: int,
		lw: float) -> void:
	var fill := {"start": Color("c9efc6"), "end": Color("f7c9c4"), "step": Color("d6e6fb"), "decision": Color("fdeaa8")}
	if shape == "decision":
		var h := size.y * 0.6
		var pts := PackedVector2Array([c + Vector2(0, -h), c + Vector2(size.x * 0.5, 0), c + Vector2(0, h),
			c + Vector2(-size.x * 0.5, 0)])
		ci.draw_colored_polygon(pts, fill[shape])
		pts.append(pts[0])
		ci.draw_polyline(pts, INK, lw, true)
		_label(ci, font, c, text, _fit(font, text, fs, size.x * 0.66), INK)
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill[shape]
	sb.set_corner_radius_all(int(size.y * 0.5) if shape in ["start", "end"] else 6)
	sb.set_border_width_all(int(maxf(1.0, lw)))
	sb.border_color = INK
	ci.draw_style_box(sb, Rect2(c - size * 0.5, size))
	_label(ci, font, c, text, _fit(font, text, fs, size.x - 10.0), INK)


## A line from a to b with an arrowhead at b.
static func _arrow(ci: CanvasItem, a: Vector2, b: Vector2, lw: float) -> void:
	if a.distance_to(b) < 1.0:
		return
	ci.draw_line(a, b, INK, lw, true)
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	var hl := maxf(6.0, lw * 3.5)
	ci.draw_colored_polygon(PackedVector2Array([b, b - dir * hl + side * hl * 0.55, b - dir * hl - side * hl * 0.55]), INK)


# --- network ---------------------------------------------------------------------------------------------------------

static func _draw_network(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var devices: Array = d.devices
	var n := devices.size()
	var wired: Array = d.get("wired", [])
	var internet := bool(d.get("internet", false))
	var server := bool(d.get("server", false))
	var has_router := bool(d.get("router", true))
	var mark: Variant = d.get("mark", null)
	var row := r.size.y / n
	var fs := clampi(int(row * 0.2), 10, 18)
	var s := minf(row - fs * 1.4, r.size.x * 0.13)
	var dev_x := r.position.x + r.size.x * 0.1
	var router_c := Vector2(r.position.x + r.size.x * (0.4 if internet or server else 0.62), r.get_center().y)
	var cloud_c := Vector2(r.position.x + r.size.x * 0.66, r.get_center().y)
	var server_c := Vector2(r.position.x + r.size.x * 0.9, r.get_center().y)
	var rs := minf(r.size.y * 0.3, r.size.x * 0.14)
	var hub := router_c if has_router else (cloud_c if internet else router_c)
	for i in n:   # links first, under the pictures
		var c := Vector2(dev_x, r.position.y + i * row + s * 0.5 + 2.0)
		var is_wired := false
		for w: Variant in wired:
			is_wired = is_wired or int(w) == i
		if is_wired:
			ci.draw_line(c + Vector2(s * 0.5, 0), hub - Vector2(rs * 0.5, 0), INK, 3.0, true)
		else:
			ci.draw_dashed_line(c + Vector2(s * 0.5, 0), hub - Vector2(rs * 0.5, 0), BLUE, 2.5, 7.0)
	if internet:
		ci.draw_line(router_c + Vector2(rs * 0.5, 0), cloud_c - Vector2(rs * 0.6, 0), INK, 3.0, true)
		if server:
			ci.draw_line(cloud_c + Vector2(rs * 0.6, 0), server_c - Vector2(rs * 0.3, 0), INK, 3.0, true)
	elif server:
		ci.draw_line(router_c + Vector2(rs * 0.5, 0), server_c - Vector2(rs * 0.3, 0), INK, 3.0, true)
	for i in n:
		var c := Vector2(dev_x, r.position.y + i * row + s * 0.5 + 2.0)
		var marked := typeof(mark) in [TYPE_INT, TYPE_FLOAT] and int(mark) == i
		if marked:
			ci.draw_circle(c, s * 0.62, SOFT)
		_device(ci, str(devices[i]), c, s)
		_label(ci, font, Vector2(c.x, c.y + s * 0.5 + fs * 0.6), str(devices[i]), fs, SHADE if marked else INK)
	if has_router:
		if str(mark) == "router":
			ci.draw_circle(router_c, rs * 0.7, SOFT)
		_router(ci, router_c, rs)
		_label(ci, font, router_c + Vector2(0, rs * 0.55 + fs * 0.7), "router", fs, SHADE if str(mark) == "router" else INK)
	if internet:
		if str(mark) == "internet":
			ci.draw_circle(cloud_c, rs * 0.75, SOFT)
		_cloud(ci, cloud_c, rs)
		_label(ci, font, cloud_c + Vector2(0, rs * 0.5 + fs * 0.7), "internet", fs, SHADE if str(mark) == "internet" else INK)
	if server:
		if str(mark) == "server":
			ci.draw_circle(server_c, rs * 0.7, SOFT)
		_server(ci, server_c, rs)
		_label(ci, font, server_c + Vector2(0, rs * 0.6 + fs * 0.7), "server", fs, SHADE if str(mark) == "server" else INK)


static func _device(ci: CanvasItem, what: String, c: Vector2, s: float) -> void:
	var body := Color("5b6b8a")
	var screen := Color("9fd3f5")
	match what:
		"laptop":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.4), Vector2(s * 0.8, s * 0.52)), body)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.34, -s * 0.34), Vector2(s * 0.68, s * 0.4)), screen)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.46, s * 0.14), c + Vector2(s * 0.46, s * 0.14),
				c + Vector2(s * 0.5, s * 0.26), c + Vector2(-s * 0.5, s * 0.26)]), body)
		"tablet":
			_rounded(ci, Rect2(c - Vector2(s * 0.3, s * 0.42), Vector2(s * 0.6, s * 0.84)), body, s * 0.06)
			ci.draw_rect(Rect2(c - Vector2(s * 0.24, s * 0.34), Vector2(s * 0.48, s * 0.68)), screen)
		"phone":
			_rounded(ci, Rect2(c - Vector2(s * 0.19, s * 0.4), Vector2(s * 0.38, s * 0.8)), body, s * 0.06)
			ci.draw_rect(Rect2(c - Vector2(s * 0.14, s * 0.32), Vector2(s * 0.28, s * 0.62)), screen)
		"computer":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.42), Vector2(s * 0.9, s * 0.6)), body)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.39, -s * 0.36), Vector2(s * 0.78, s * 0.48)), screen)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.06, s * 0.18), Vector2(s * 0.12, s * 0.14)), body)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.25, s * 0.3), Vector2(s * 0.5, s * 0.08)), body)
		"printer":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.44), Vector2(s * 0.52, s * 0.34)), PAPER_WHITE)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.44), Vector2(s * 0.52, s * 0.34)), INK, false, 1.0)
			_rounded(ci, Rect2(c + Vector2(-s * 0.45, -s * 0.16), Vector2(s * 0.9, s * 0.44)), body, s * 0.06)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, s * 0.1), Vector2(s * 0.6, s * 0.06)), Color("2a3346"))
		"speaker":
			_rounded(ci, Rect2(c - Vector2(s * 0.24, s * 0.42), Vector2(s * 0.48, s * 0.84)), body, s * 0.14)
			ci.draw_circle(c + Vector2(0, s * 0.1), s * 0.16, Color("2a3346"))
			ci.draw_circle(c + Vector2(0, -s * 0.22), s * 0.07, Color("2a3346"))


static func _router(ci: CanvasItem, c: Vector2, s: float) -> void:
	var body := Color("3c4a66")
	ci.draw_line(c + Vector2(-s * 0.3, -s * 0.12), c + Vector2(-s * 0.38, -s * 0.5), body, maxf(2.0, s * 0.05), true)
	ci.draw_line(c + Vector2(s * 0.3, -s * 0.12), c + Vector2(s * 0.38, -s * 0.5), body, maxf(2.0, s * 0.05), true)
	_rounded(ci, Rect2(c - Vector2(s * 0.5, s * 0.16), Vector2(s, s * 0.36)), body, s * 0.08)
	for i in 4:
		ci.draw_circle(c + Vector2(-s * 0.3 + i * s * 0.2, s * 0.02), maxf(2.0, s * 0.04), Color("7be08a"))


static func _cloud(ci: CanvasItem, c: Vector2, s: float) -> void:
	var col := Color("cfe3fb")
	for p: Vector3 in [Vector3(-0.35, 0.05, 0.28), Vector3(0.0, -0.12, 0.36), Vector3(0.35, 0.05, 0.28),
			Vector3(0.0, 0.12, 0.3)]:
		ci.draw_circle(c + Vector2(p.x, p.y) * s, p.z * s, col)
	for p: Vector3 in [Vector3(-0.35, 0.05, 0.28), Vector3(0.0, -0.12, 0.36), Vector3(0.35, 0.05, 0.28)]:
		ci.draw_arc(c + Vector2(p.x, p.y) * s, p.z * s, PI * 0.9, PI * 2.1, 16, BLUE.darkened(0.2), 1.5, true)


static func _server(ci: CanvasItem, c: Vector2, s: float) -> void:
	var body := Color("3c4a66")
	_rounded(ci, Rect2(c - Vector2(s * 0.28, s * 0.55), Vector2(s * 0.56, s * 1.1)), body, s * 0.05)
	for i in 4:
		var y := c.y - s * 0.42 + i * s * 0.26
		ci.draw_rect(Rect2(Vector2(c.x - s * 0.2, y), Vector2(s * 0.4, s * 0.12)), Color("56668a"))
		ci.draw_circle(Vector2(c.x + s * 0.14, y + s * 0.06), maxf(1.5, s * 0.025), Color("7be08a"))


# --- colour wheel ----------------------------------------------------------------------------------------------------

static func _draw_wheel(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var size := _int(d, "size", 12)
	var wheel := WHEEL if size == 12 else WHEEL6
	var names := bool(d.get("names", size == 6))
	var blank: Array = d.get("blank", [])
	var mark: Array = d.get("mark", [])
	var outside := names and size == 12
	var fs := clampi(int(r.size.y * 0.07), 10, 18)
	var c := r.get_center()
	var rad := minf(r.size.x, r.size.y) * 0.5 * (0.7 if outside else (0.82 if d.has("half") or not mark.is_empty() else 0.96))
	var inner := rad * 0.34
	var seg := TAU / size
	var half: Array = []
	if d.has("half"):
		half = WARM if str(d.half) == "warm" else COOL
	for i in size:
		var name := wheel[i]
		var a0 := -PI * 0.5 + (i - 0.5) * seg
		var pts := _ring_segment(c, inner, rad, a0, a0 + seg)
		var fill: Color = PAPER_WHITE if blank.has(name) else SchoolPictureArts.COLOURS[name]
		ci.draw_colored_polygon(pts, fill)
		var ring := pts.duplicate()
		ring.append(pts[0])
		ci.draw_polyline(ring, INK, 1.5, true)
		var mid := c + Vector2.from_angle(a0 + seg * 0.5) * (inner + rad) * 0.5
		if blank.has(name):
			_label(ci, font, mid, "?", clampi(int(rad * 0.2), 12, 40), SHADE)
		elif names and not outside:
			var ink := INK if fill.get_luminance() > 0.5 else Color.WHITE
			_label(ci, font, mid, name, _fit(font, name, fs, (rad - inner) * 0.95), ink)
		if outside:
			var at := c + Vector2.from_angle(a0 + seg * 0.5) * (rad + fs * 2.6)
			_label(ci, font, at, name, _fit(font, name, fs, r.size.x * 0.2), INK)
	for i in size:   # a marked colour: a dark outline, and a pointer outside the ring
		var name := wheel[i]
		if mark.has(name):
			var a0 := -PI * 0.5 + (i - 0.5) * seg
			var ring := _ring_segment(c, inner, rad, a0, a0 + seg)
			ring.append(ring[0])
			ci.draw_polyline(ring, Color.WHITE, 7.0, true)
			ci.draw_polyline(ring, INK, 3.5, true)
			var dir := Vector2.from_angle(a0 + seg * 0.5)
			var side := Vector2(-dir.y, dir.x)
			var tip := c + dir * (rad + 3.0)
			var tail := rad * 0.14
			ci.draw_colored_polygon(PackedVector2Array([tip, tip + dir * tail + side * tail * 0.6,
				tip + dir * tail - side * tail * 0.6]), INK)
	if not half.is_empty():   # an arc outside the group's colours, and its word
		var first := wheel.find(str(half[0]))
		var last := wheel.find(str(half[half.size() - 1]))
		if size == 6:
			first = wheel.find("yellow" if str(d.half) == "warm" else "purple")
			last = wheel.find("red" if str(d.half) == "warm" else "green")
		var a0 := -PI * 0.5 + (first - 0.5) * seg
		var a1 := -PI * 0.5 + (last + 0.5) * seg
		var col := Color("e0452c") if str(d.half) == "warm" else Color("2f6fdc")
		ci.draw_arc(c, rad + 8.0, a0, a1, 32, col, 7.0, true)
		var mid := (a0 + a1) * 0.5
		var word := str(d.half)
		var at := c + Vector2.from_angle(mid) * (rad + 10.0 + fs * 1.6)
		_label(ci, font, at, word, fs, col)
	if d.has("line"):
		var ends: Array[Vector2] = []
		for name: Variant in d.line:
			var i := wheel.find(str(name))
			ends.append(c + Vector2.from_angle(-PI * 0.5 + i * seg) * (inner + rad) * 0.5)
		ci.draw_line(ends[0], ends[1], INK, 3.0, true)
		for e in ends:
			ci.draw_circle(e, 6.0, INK)
			ci.draw_circle(e, 3.5, PAPER_WHITE)


static func _ring_segment(c: Vector2, inner: float, outer: float, a0: float, a1: float, steps := 8) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in steps + 1:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, float(k) / steps)) * outer)
	for k in steps + 1:
		pts.append(c + Vector2.from_angle(lerpf(a1, a0, float(k) / steps)) * inner)
	return pts


# --- shading ---------------------------------------------------------------------------------------------------------

static func _draw_shading(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var shape := str(d.shape)
	var from_left := str(d.light) == "left"
	var sgn := -1.0 if from_left else 1.0   # the side the light comes from
	var labels := bool(d.get("labels", false))
	var flat := bool(d.get("flat", false))
	var fs := clampi(int(r.size.y * 0.07), 10, 18)
	var c := r.get_center() + Vector2(0, -r.size.y * 0.04)
	var rad := minf(r.size.x * 0.22, r.size.y * 0.34)
	var ground := c.y + rad
	if bool(d.get("lamp", true)):
		var lamp := Vector2(c.x + sgn * minf(r.size.x * 0.4, rad * 2.6), r.position.y + rad * 0.45)
		ci.draw_circle(lamp, rad * 0.22, Color("ffc93c"))
		for k in 8:
			var dir := Vector2.from_angle(TAU * k / 8.0)
			ci.draw_line(lamp + dir * rad * 0.3, lamp + dir * rad * 0.42, Color("f0a500"), 2.0, true)
	if not flat:   # the cast shadow, on the ground away from the light
		_ellipse(ci, Vector2(c.x - sgn * rad * 0.75, ground - rad * 0.02), Vector2(rad * 1.15, rad * 0.2),
			Color(0.15, 0.15, 0.2, 0.45))
	var dark := Color("3b3f4a")
	var light := Color("f4f4f2")
	match shape:
		"sphere":
			if flat:
				ci.draw_circle(c, rad, Color("b9bcc4"))
			else:
				var hl := c + Vector2(sgn * rad * 0.38, -rad * 0.38)
				for k in 28:
					var t := k / 27.0
					ci.draw_circle(c.lerp(hl, t * 0.9), rad * (1.0 - t * 0.92), dark.lerp(light, pow(t, 0.8)))
			ci.draw_arc(c, rad, 0.0, TAU, 48, INK, 2.0, true)
		"cube":
			var s := rad * 1.3
			var depth := Vector2(-sgn * s * 0.42, -s * 0.34)   # the top and the side seen away from the light
			var front := Rect2(c - Vector2(s * 0.5, s * 0.3) - depth * 0.5, Vector2(s, s))
			ground = front.end.y
			var top := PackedVector2Array([front.position, front.position + depth, Vector2(front.end.x, front.position.y) + depth,
				Vector2(front.end.x, front.position.y)])
			var far_x := front.position.x if not from_left else front.end.x
			var side := PackedVector2Array([Vector2(far_x, front.position.y), Vector2(far_x, front.position.y) + depth,
				Vector2(far_x, front.end.y) + depth, Vector2(far_x, front.end.y)])
			ci.draw_colored_polygon(top, flat_or(flat, Color("e9e9e6")))
			ci.draw_colored_polygon(side, flat_or(flat, Color("5d6170")))
			ci.draw_rect(front, flat_or(flat, Color("a9acb4")))
			for poly: PackedVector2Array in [top, side]:
				var ring := poly.duplicate()
				ring.append(poly[0])
				ci.draw_polyline(ring, INK, 2.0, true)
			ci.draw_rect(front, INK, false, 2.0)
		"cylinder":
			var w := rad * 1.2
			var h := rad * 1.7
			var body := Rect2(c - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
			ground = body.end.y
			var strips := 24
			for k in strips:
				var t := (k + 0.5) / strips   # 0 at the left edge
				var lit := (1.0 - t) if from_left else t
				var col := Color("b9bcc4") if flat else dark.lerp(light, clampf(pow(lit, 0.9) * 1.1, 0.0, 1.0))
				ci.draw_rect(Rect2(Vector2(body.position.x + k * w / strips, body.position.y), Vector2(w / strips + 0.5, h)), col)
			_ellipse(ci, Vector2(c.x, body.end.y), Vector2(w * 0.5, w * 0.16), Color("b9bcc4") if flat else dark.lerp(light, 0.35), true)
			_ellipse(ci, Vector2(c.x, body.position.y), Vector2(w * 0.5, w * 0.16), Color("d9dade") if flat else light)
			_ellipse_line(ci, Vector2(c.x, body.position.y), Vector2(w * 0.5, w * 0.16))
			ci.draw_line(body.position, Vector2(body.position.x, body.end.y), INK, 2.0, true)
			ci.draw_line(Vector2(body.end.x, body.position.y), body.end, INK, 2.0, true)
	if labels and not flat:
		var lx := r.position.x + r.size.x * (0.14 if from_left else 0.86)
		var rx := r.position.x + r.size.x * (0.86 if from_left else 0.14)
		var hl_at := c + Vector2(sgn * rad * 0.4, -rad * 0.4)
		var shadow_at := c + Vector2(-sgn * rad * 0.6, rad * 0.35)
		var cast_at := Vector2(c.x - sgn * rad * 1.3, ground)
		_callout(ci, font, hl_at, Vector2(lx, c.y - rad * 0.3), "highlight", fs)
		_callout(ci, font, shadow_at, Vector2(rx, c.y - rad * 0.25), "shadow", fs)
		_callout(ci, font, cast_at, Vector2(rx, ground + fs * 0.2), "cast shadow", fs)


static func flat_or(flat: bool, col: Color) -> Color:
	return Color("b9bcc4") if flat else col


static func _callout(ci: CanvasItem, font: Font, at: Vector2, label_at: Vector2, text: String, fs: int) -> void:
	ci.draw_line(at, label_at, SHADE, 2.0, true)
	ci.draw_circle(at, 4.0, SHADE)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var box := Rect2(label_at - Vector2(w * 0.5 + 6.0, fs * 0.8), Vector2(w + 12.0, fs * 1.6))
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER_WHITE
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(2)
	sb.border_color = SHADE
	ci.draw_style_box(sb, box)
	_label(ci, font, label_at, text, fs, INK)


# --- face ------------------------------------------------------------------------------------------------------------

static func _draw_face(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var guides := bool(d.get("guides", true))
	var mark := str(d.get("mark", ""))
	var high := str(d.get("eyes", "halfway")) == "high"
	var c := r.get_center()
	var ry := r.size.y * 0.42
	var rx := minf(ry * 0.74, r.size.x * 0.3)
	var top := c.y - ry
	var chin := c.y + ry
	var skin := Color("f3cfae")
	var lw := clampf(ry * 0.02, 1.5, 3.0)
	# neck and ears behind the head
	ci.draw_rect(Rect2(Vector2(c.x - rx * 0.36, chin - ry * 0.3), Vector2(rx * 0.72, ry * 0.36)), skin.darkened(0.08))
	var eye_y := c.y - (ry * 0.42 if high else 0.0)
	var nose_y := c.y + (chin - c.y) * 0.5
	var mouth_y := nose_y + (chin - nose_y) / 3.0
	for side: float in [-1.0, 1.0]:
		var ear := Vector2(c.x + side * rx * 0.97, (c.y + nose_y) * 0.5)
		_ellipse(ci, ear, Vector2(rx * 0.14, (nose_y - c.y) * 0.55), SHADE if mark == "ears" else skin.darkened(0.05))
		_ellipse_line(ci, ear, Vector2(rx * 0.14, (nose_y - c.y) * 0.55))
	# the head: an egg, wider at the top
	var head := PackedVector2Array()
	for i in 48:
		var t := TAU * i / 48.0
		var y := sin(t)
		head.append(c + Vector2(cos(t) * rx * (1.0 - 0.12 * maxf(y, 0.0)), y * ry))
	ci.draw_colored_polygon(head, skin)
	var outline := head.duplicate()
	outline.append(head[0])
	ci.draw_polyline(outline, INK, lw, true)
	# hair: a cap over the top
	var hair := PackedVector2Array()
	for i in 25:   # over the top of the head, then a fringe back across the forehead
		var t := PI + 0.25 + (PI - 0.5) * i / 24.0
		hair.append(c + Vector2(cos(t) * rx * 1.02, sin(t) * ry * 1.02))
	var end_x := cos(0.25) * rx * 1.02
	for i in range(1, 24):
		var f := i / 24.0
		hair.append(c + Vector2(end_x * (1.0 - 2.0 * f), -ry * 0.26 - sin(f * PI) * ry * 0.36))
	ci.draw_colored_polygon(hair, Color("6b4226"))
	if guides:
		var gl := Color(0.23, 0.48, 0.91, 0.75)
		ci.draw_dashed_line(Vector2(c.x, top), Vector2(c.x, chin), gl, 1.5, 6.0)
		for y: float in [eye_y, nose_y, mouth_y]:
			ci.draw_dashed_line(Vector2(c.x - rx * 1.25, y), Vector2(c.x + rx * 1.25, y), gl, 1.5, 6.0)
		# the halfway marks: top of the head and chin, with the eye line between
		var mx := c.x + rx * 1.4
		ci.draw_line(Vector2(mx - 6, top), Vector2(mx + 6, top), gl, 2.0)
		ci.draw_line(Vector2(mx - 6, chin), Vector2(mx + 6, chin), gl, 2.0)
		ci.draw_line(Vector2(mx, top), Vector2(mx, chin), gl, 1.5)
		ci.draw_line(Vector2(mx - 6, c.y), Vector2(mx + 6, c.y), gl, 2.0)
	# eyes: five eyes across the face, one eye's gap between them
	var ew := rx * 2.0 / 5.0
	for side: float in [-1.0, 1.0]:
		var ec := Vector2(c.x + side * ew, eye_y)
		var eye := PackedVector2Array()
		for i in 24:
			var t := TAU * i / 24.0
			eye.append(ec + Vector2(cos(t) * ew * 0.48, sin(t) * ew * 0.22))
		ci.draw_colored_polygon(eye, SHADE if mark == "eyes" else Color.WHITE)
		var ring := eye.duplicate()
		ring.append(eye[0])
		ci.draw_polyline(ring, INK, lw, true)
		ci.draw_circle(ec, ew * 0.16, Color("4a3322"))
		ci.draw_line(ec + Vector2(-ew * 0.45, -ew * 0.42), ec + Vector2(ew * 0.45, -ew * 0.48), Color("6b4226"), lw * 1.6, true)
	# nose: a line down from between the eyes, its bottom on the nose line
	var nose_col := SHADE if mark == "nose" else INK
	ci.draw_line(Vector2(c.x, eye_y + ew * 0.3), Vector2(c.x - ew * 0.12, nose_y - ew * 0.1), nose_col,
		lw * (2.0 if mark == "nose" else 1.0), true)
	ci.draw_arc(Vector2(c.x, nose_y - ew * 0.18), ew * 0.26, PI * 0.15, PI * 0.85, 12, nose_col,
		lw * (2.0 if mark == "nose" else 1.0), true)
	# mouth: its corners under the middles of the eyes
	var mouth := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		mouth.append(Vector2(c.x - ew + t * ew * 2.0, mouth_y + sin(t * PI) * ew * 0.22))
	ci.draw_polyline(mouth, SHADE if mark == "mouth" else Color("b0413e"), lw * (2.4 if mark == "mouth" else 1.6), true)


# --- landscape -------------------------------------------------------------------------------------------------------

static func _draw_landscape(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var mark := str(d.get("mark", ""))
	var labels := bool(d.get("labels", false))
	var fs := clampi(int(r.size.y * 0.075), 10, 18)
	var w := r.size.x * (0.74 if labels else 1.0)
	var o := r.position
	var h := r.size.y
	var horizon := o.y + h * 0.42
	# the sky, lighter near the horizon
	for k in 12:
		var t := k / 12.0
		ci.draw_rect(Rect2(Vector2(o.x, o.y + t * (horizon - o.y)), Vector2(w, (horizon - o.y) / 12.0 + 1.0)),
			Color("8ec5f0").lerp(Color("e3f1fb"), t))
	# the background: far mountains, small, pale and blue-grey, with little detail
	var far := PackedVector2Array([Vector2(o.x, horizon)])
	var peaks := [0.0, 0.1, 0.22, 0.3, 0.42, 0.55, 0.63, 0.78, 0.88, 1.0]
	for i in peaks.size():
		far.append(Vector2(o.x + w * float(peaks[i]), horizon - h * (0.14 if i % 2 == 1 else 0.05)))
	far.append(Vector2(o.x + w, horizon))
	ci.draw_colored_polygon(far, Color("a9b9d0"))
	# the middle ground: rolling green hills with small trees and a house
	var mid_top := horizon
	var mid_bottom := o.y + h * 0.72
	var hills := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		hills.append(Vector2(o.x + t * w, mid_top + h * 0.05 + sin(t * TAU * 1.3) * h * 0.035))
	hills.append(Vector2(o.x + w, mid_bottom))
	hills.append(Vector2(o.x, mid_bottom))
	ci.draw_colored_polygon(hills, Color("7fbf6a"))
	for i in 4:
		var tx := o.x + w * (0.55 + i * 0.1)
		var ty := mid_top + h * 0.12 + (i % 2) * h * 0.03
		ci.draw_rect(Rect2(Vector2(tx - 1.5, ty), Vector2(3.0, h * 0.04)), Color("6b4a2a"))
		ci.draw_circle(Vector2(tx, ty), h * 0.03, Color("3f8a3a"))
	var house := Vector2(o.x + w * 0.44, mid_top + h * 0.15)
	ci.draw_rect(Rect2(house - Vector2(h * 0.045, 0), Vector2(h * 0.09, h * 0.06)), Color("f4e2c4"))
	ci.draw_colored_polygon(PackedVector2Array([house + Vector2(-h * 0.06, 0), house + Vector2(h * 0.06, 0),
		house + Vector2(0, -h * 0.05)]), Color("c0503c"))
	# the foreground: big, near, with the most detail: a tree, grass and flowers
	var fg := PackedVector2Array([Vector2(o.x, mid_bottom), Vector2(o.x + w, mid_bottom - h * 0.03),
		Vector2(o.x + w, o.y + h), Vector2(o.x, o.y + h)])
	ci.draw_colored_polygon(fg, Color("4c9a3f"))
	for i in 18:
		var gx := o.x + w * (i + 0.5) / 18.0
		var gy := o.y + h * (0.84 + (i % 3) * 0.045)
		ci.draw_line(Vector2(gx, gy), Vector2(gx - 3, gy - h * 0.05), Color("2f6e2a"), 2.0, true)
		ci.draw_line(Vector2(gx, gy), Vector2(gx + 4, gy - h * 0.06), Color("2f6e2a"), 2.0, true)
	for i in 4:
		var fp := Vector2(o.x + w * (0.52 + i * 0.12), o.y + h * (0.8 + (i % 2) * 0.1))
		for k in 5:
			ci.draw_circle(fp + Vector2.from_angle(TAU * k / 5.0) * h * 0.018, h * 0.014, Color("f4d23c") if i % 2 == 0 else Color("e8508a"))
		ci.draw_circle(fp, h * 0.011, Color("f08a1c"))
	var tree_x := o.x + maxf(w * 0.16, h * 0.2)
	ci.draw_rect(Rect2(Vector2(tree_x - h * 0.02, o.y + h * 0.52), Vector2(h * 0.04, h * 0.38)), Color("6b4a2a"))
	for p: Vector3 in [Vector3(0.0, 0.44, 0.15), Vector3(-0.08, 0.52, 0.11), Vector3(0.08, 0.52, 0.11)]:
		ci.draw_circle(Vector2(tree_x + h * p.x, o.y + h * p.y), h * p.z, Color("2f7a2e"))
	var bands := {"background": Rect2(Vector2(o.x, horizon - h * 0.15), Vector2(w, h * 0.15)),
		"middle ground": Rect2(Vector2(o.x, mid_top), Vector2(w, mid_bottom - mid_top)),
		"foreground": Rect2(Vector2(o.x, mid_bottom), Vector2(w, o.y + h - mid_bottom))}
	if mark == "horizon":   # a bold line with ends, over everything
		var lw := maxf(4.0, h * 0.02)
		ci.draw_line(Vector2(o.x, horizon), Vector2(o.x + w, horizon), SHADE, lw)
		for x: float in [o.x + lw, o.x + w - lw]:
			ci.draw_line(Vector2(x, horizon - lw * 2.0), Vector2(x, horizon + lw * 2.0), SHADE, lw)
	elif bands.has(mark):
		ci.draw_rect((bands[mark] as Rect2).grow(-2.0), SHADE, false, 4.0)
	if labels:
		var lx := o.x + w + (r.size.x - w) * 0.5
		for k: String in ["background", "middle ground", "foreground"]:
			var y := (bands[k] as Rect2).get_center().y
			ci.draw_line(Vector2(o.x + w - 10.0, y), Vector2(lx - (r.size.x - w) * 0.42, y), INK, 1.5)
			_label(ci, font, Vector2(lx, y), k, _fit(font, k, fs, r.size.x - w - 6.0), SHADE if k == mark else INK)


# --- pixel art -------------------------------------------------------------------------------------------------------

static func _draw_pixels(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var key: Dictionary = d.key
	var cols := str(rows[0]).length()
	var cell := minf(r.size.x / cols, r.size.y / rows.size())
	var o := r.position + (r.size - Vector2(cols, rows.size()) * cell) * 0.5
	var grid := bool(d.get("grid", true))
	for y in rows.size():
		var row := str(rows[y])
		for x in cols:
			var ch := row[x]
			var col: Color = PAPER_WHITE if ch == "." else SchoolPictureArts.COLOURS[str(key[ch])]
			ci.draw_rect(Rect2(o + Vector2(x, y) * cell, Vector2(cell, cell)), col)
	if grid:
		for x in cols + 1:
			ci.draw_line(o + Vector2(x * cell, 0), o + Vector2(x * cell, rows.size() * cell), GRID_LINE, 1.0)
		for y in rows.size() + 1:
			ci.draw_line(o + Vector2(0, y * cell), o + Vector2(cols * cell, y * cell), GRID_LINE, 1.0)
	ci.draw_rect(Rect2(o, Vector2(cols, rows.size()) * cell), INK, false, 2.0)


# --- relief ----------------------------------------------------------------------------------------------------------

static func _draw_relief(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var what := str(d.what)
	var fs := clampi(int(r.size.y * 0.08), 10, 18)
	var label_h := fs * 1.6
	var half := r.size.x * 0.5
	var stone := Color("d8cdb8")
	var stone_dark := Color("a8987c")
	var h := r.size.y - label_h
	# from the side: the wall on the left, what stands out of it (or is cut into it) to its right
	var side := Rect2(r.position, Vector2(half, h)).grow(-6.0)
	var wall := Rect2(side.position + Vector2(side.size.x * 0.12, 0), Vector2(side.size.x * 0.22, side.size.y))
	var face_x := wall.end.x
	var cy := side.get_center().y
	var bump := minf(side.size.y * 0.3, side.size.x * 0.3)
	if what != "round":
		ci.draw_rect(wall, stone)
	match what:
		"low":
			_half_bump(ci, Vector2(face_x, cy), bump * 0.25, bump, stone)
		"high":
			_half_bump(ci, Vector2(face_x, cy), bump * 1.1, bump, stone)
		"sunken":
			var cut := _half_bump_points(Vector2(face_x, cy), -bump * 0.3, bump * 0.8)
			ci.draw_colored_polygon(cut, Color("f6f1e6"))
			ci.draw_polyline(cut, stone_dark, 2.0, true)
		"round":
			_statue(ci, side, stone, stone_dark)
	if what != "round":
		ci.draw_rect(wall, INK, false, 2.0)
	_label(ci, font, Vector2(r.position.x + half * 0.5, r.end.y - label_h * 0.5), "from the side", fs, INK)
	# from the front: a sun carved on a slab (a statue for "round"), lit from the top left
	var front := Rect2(r.position + Vector2(half, 0), Vector2(half, h)).grow(-6.0)
	var fc := front.get_center()
	var s := minf(front.size.x, front.size.y) * 0.9
	var sun_r := s * 0.2
	if what == "round":   # the same statue: it has no front or back
		_statue(ci, front, stone, stone_dark)
	else:
		var slab := Rect2(fc - Vector2(s, s) * 0.45, Vector2(s, s) * 0.9)
		ci.draw_rect(slab, stone)
		var depth := {"low": 0.05, "high": 0.16, "sunken": -0.06}
		var off := sun_r * float(depth[what])
		var shadow := Color(0.25, 0.2, 0.15, 0.55)
		if what == "sunken":   # cut in: the shadow falls inside, on the lit side
			ci.draw_circle(fc, sun_r, Color("b3a386"))
			ci.draw_circle(fc + Vector2(-off, -off) * 2.0, sun_r * 0.96, stone.darkened(0.02))
			ci.draw_arc(fc, sun_r, PI, PI * 1.5, 16, shadow, maxf(3.0, sun_r * 0.12), true)
		else:   # stands out: the shadow falls outside, away from the light
			ci.draw_circle(fc + Vector2(off, off) * 2.0, sun_r, shadow)
			ci.draw_circle(fc, sun_r, stone.lightened(0.15))
		for k in 8:
			var dir := Vector2.from_angle(TAU * k / 8.0)
			ci.draw_line(fc + dir * sun_r * 1.25, fc + dir * sun_r * 1.7, stone_dark if what != "sunken" else Color("8c7c62"),
				maxf(2.0, sun_r * (0.12 if what == "high" else 0.08)), true)
		ci.draw_rect(slab, INK, false, 2.0)
	_label(ci, font, Vector2(r.position.x + half * 1.5, r.end.y - label_h * 0.5), "from the front", fs, INK)


## A statue on its base, standing free (sculpture in the round).
static func _statue(ci: CanvasItem, box: Rect2, stone: Color, stone_dark: Color) -> void:
	var base := Rect2(Vector2(box.position.x + box.size.x * 0.3, box.end.y - box.size.y * 0.12),
		Vector2(box.size.x * 0.4, box.size.y * 0.12))
	ci.draw_rect(base, stone_dark)
	var body := Rect2(Vector2(base.get_center().x - box.size.x * 0.08, box.position.y + box.size.y * 0.35),
		Vector2(box.size.x * 0.16, base.position.y - box.position.y - box.size.y * 0.35))
	ci.draw_rect(body, stone)
	ci.draw_rect(Rect2(body.end - Vector2(body.size.x * 0.35, body.size.y), Vector2(body.size.x * 0.35, body.size.y)),
		stone.darkened(0.12))
	var head := Vector2(base.get_center().x, box.position.y + box.size.y * 0.24)
	ci.draw_circle(head, box.size.y * 0.12, stone)
	ci.draw_arc(head, box.size.y * 0.12, -PI * 0.4, PI * 0.4, 12, stone.darkened(0.15), box.size.y * 0.05, true)


static func _half_bump_points(face: Vector2, depth: float, half_h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 17:
		var t := -PI * 0.5 + PI * k / 16.0
		pts.append(face + Vector2(cos(t) * depth, sin(t) * half_h))
	return pts


static func _half_bump(ci: CanvasItem, face: Vector2, depth: float, half_h: float, col: Color) -> void:
	var pts := _half_bump_points(face, depth, half_h)
	ci.draw_colored_polygon(pts, col)
	ci.draw_polyline(pts, INK, 2.0, true)


# --- print -----------------------------------------------------------------------------------------------------------

static func _draw_print(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var items: Array = d.items
	var arrows := bool(d.get("arrows", false))
	var n := items.size()
	var fs := clampi(int(r.size.y * 0.08), 10, 18)
	var label_h := fs * 1.6 if arrows else 0.0
	var gap := r.size.x * (0.12 if arrows and n > 1 else 0.04)
	var cell := minf((r.size.x - gap * (n - 1)) / n, r.size.y - label_h)
	var total := cell * n + gap * (n - 1)
	var x := r.position.x + (r.size.x - total) * 0.5
	var y := r.position.y + (r.size.y - label_h - cell) * 0.5
	for i in n:
		var it: Dictionary = items[i]
		var box := Rect2(Vector2(x, y), Vector2(cell, cell)).grow(-cell * 0.06)
		var on_block := str(it.on) == "block"
		if on_block:   # a lino block: the letter stands up and takes the ink
			ci.draw_rect(box, Color("b98a58"))
			ci.draw_rect(box.grow(-box.size.x * 0.06), Color("c99c6a"))
		else:
			ci.draw_rect(Rect2(box.position + Vector2(4, 4), box.size), Color(0, 0, 0, 0.15))
			ci.draw_rect(box, PAPER_WHITE)
		ci.draw_rect(box, INK, false, 2.0)
		var flip := str(it.get("flip", "none"))
		var scale := Vector2(-1, 1) if flip == "mirror" else (Vector2(-1, -1) if flip == "upside down" else Vector2.ONE)
		var fsz := int(box.size.y * 0.72)
		var text := str(it.text)
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		ci.draw_set_transform(box.get_center(), 0.0, scale)
		ci.draw_string(font, Vector2(-tw * 0.5, (font.get_ascent(fsz) - font.get_descent(fsz)) * 0.5), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color("2a2f5a") if on_block else Color("1d3f8f"))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if arrows:
			_label(ci, font, Vector2(box.get_center().x, r.end.y - label_h * 0.5), "block" if on_block else "print", fs, INK)
			if i < n - 1:
				_arrow(ci, Vector2(x + cell + gap * 0.15, y + cell * 0.5), Vector2(x + cell + gap * 0.85, y + cell * 0.5), 3.0)
		x += cell + gap


# --- orchestra -------------------------------------------------------------------------------------------------------

static func _draw_orchestra(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var mark := str(d.get("mark", ""))
	var hide := str(d.get("hide", ""))
	var fs := clampi(int(r.size.y * 0.075), 10, 20)
	var below := fs * 2.6
	var big := minf(r.size.y - below, r.size.x * 0.48)
	var c := Vector2(r.get_center().x, r.end.y - below)
	# the families, from the conductor outwards (the back of the stage at the top)
	var bands := [["strings", 0.14, 0.46, Color("e8a86b")], ["woodwind", 0.46, 0.63, Color("9fd08a")],
		["brass", 0.63, 0.8, Color("f2cf5b")], ["percussion", 0.8, 1.0, Color("b8a5e0")]]
	for b: Array in bands:
		var pts := _ring_segment(c, big * float(b[1]), big * float(b[2]), PI, TAU, 32)
		ci.draw_colored_polygon(pts, b[3])
		var ring := pts.duplicate()
		ring.append(pts[0])
		ci.draw_polyline(ring, SHADE if mark == str(b[0]) else INK, 4.0 if mark == str(b[0]) else 1.5, true)
		var name := "?" if hide == str(b[0]) else str(b[0])
		var thick := big * (float(b[2]) - float(b[1]))
		var size := int(thick * 0.95) if name == "?" else mini(fs, int(thick * 0.7))
		_label(ci, font, c + Vector2(0, -big * (float(b[1]) + float(b[2])) * 0.5), name,
			_fit(font, name, maxi(size, 10), big * 0.9), INK)
	# the conductor on the podium, facing the players
	var pod := big * 0.1
	ci.draw_circle(c + Vector2(0, -pod * 0.6), pod * 0.8, SHADE if mark == "conductor" else Color("5b6b8a"))
	ci.draw_circle(c + Vector2(0, -pod * 0.6), pod * 0.35, Color("f3cfae"))
	var cname := "?" if hide == "conductor" else "conductor"
	_label(ci, font, c + Vector2(0, fs * 0.75), cname, fs, SHADE if cname == "?" else INK)
	ci.draw_line(Vector2(r.position.x, r.end.y - fs * 0.9), Vector2(r.end.x, r.end.y - fs * 0.9), GRID_LINE, 1.0)
	_label(ci, font, Vector2(r.position.x + r.size.x * 0.12, r.end.y - fs * 0.35), "audience", _fit(font, "audience",
		mini(fs, 14), r.size.x * 0.2), INK)


# --- glyphs ----------------------------------------------------------------------------------------------------------

static func _draw_glyphs(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var signs: Array = d.signs
	var names := bool(d.get("names", false))
	var cartouche := bool(d.get("cartouche", false))
	var n := signs.size()
	var fs := clampi(int(r.size.y * 0.1), 10, 22)
	var name_h := fs * 1.5 if names else 0.0
	var cell := minf((r.size.x * (0.86 if cartouche else 1.0)) / n, (r.size.y - name_h) * (0.8 if cartouche else 1.0))
	var total := cell * n
	var x0 := r.position.x + (r.size.x - total) * 0.5
	var cy := r.position.y + (r.size.y - name_h) * 0.5
	if cartouche:   # an oval rope round a royal name, with a bar at its end
		var box := Rect2(Vector2(x0 - cell * 0.25, cy - cell * 0.62), Vector2(total + cell * 0.5, cell * 1.24))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("fbf3dc")
		sb.set_corner_radius_all(int(box.size.y * 0.5))
		sb.set_border_width_all(3)
		sb.border_color = INK
		ci.draw_style_box(sb, box)
		ci.draw_line(Vector2(box.end.x + 6.0, box.position.y + 4.0), Vector2(box.end.x + 6.0, box.end.y - 4.0), INK, 4.0)
	for i in n:
		var b := Rect2(Vector2(x0 + i * cell, cy - cell * 0.5), Vector2(cell, cell)).grow(-cell * 0.12)
		_glyph(ci, str(signs[i]), b)
		if names:
			_label(ci, font, Vector2(b.get_center().x, r.end.y - name_h * 0.5), str(GLYPHS[str(signs[i])]), fs, INK)


static func _glyph(ci: CanvasItem, sign: String, b: Rect2) -> void:
	var c := b.get_center()
	var s := b.size.x
	var lw := maxf(2.0, s * 0.05)
	match sign:
		"water":   # a row of little waves
			var pts := PackedVector2Array()
			for k in 13:
				pts.append(Vector2(b.position.x + s * k / 12.0, c.y + (-s * 0.07 if k % 2 == 0 else s * 0.07)))
			ci.draw_polyline(pts, Color("2f6fdc"), lw, true)
		"mouth":   # a lens, lying down
			var pts := PackedVector2Array()
			for k in 24:
				var t := TAU * k / 24.0
				pts.append(c + Vector2(cos(t) * s * 0.45, sin(t) * s * 0.14 * (1.0 - absf(cos(t)) * 0.3)))
			ci.draw_colored_polygon(pts, Color("d8573a"))
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, lw * 0.6, true)
		"bread":   # a small loaf: half a dome on a flat bottom
			var pts := PackedVector2Array()
			for k in 17:
				var t := PI + PI * k / 16.0
				pts.append(c + Vector2(cos(t) * s * 0.34, s * 0.12 + sin(t) * s * 0.26))
			ci.draw_colored_polygon(pts, Color("c98b3a"))
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, lw * 0.6, true)
		"stool":   # a small square seat
			var q := Rect2(c - Vector2(s * 0.24, s * 0.24), Vector2(s * 0.48, s * 0.48))
			ci.draw_rect(q, Color("2f6fdc"))
			ci.draw_rect(q, INK, false, lw * 0.6)
		"basket":   # a bowl with a handle at its side
			var pts := PackedVector2Array()
			for k in 17:
				var t := PI * k / 16.0
				pts.append(c + Vector2(-cos(t) * s * 0.36, sin(t) * s * 0.26 - s * 0.06))
			ci.draw_colored_polygon(pts, Color("3aa06a"))
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, lw * 0.6, true)
			ci.draw_arc(c + Vector2(s * 0.36, s * 0.04), s * 0.1, -PI * 0.5, PI * 0.5, 10, INK, lw * 0.8, true)
		"reed":   # a flowering reed: a tall leaf with its tip bent over
			var pts := PackedVector2Array([c + Vector2(-s * 0.05, s * 0.42), c + Vector2(-s * 0.12, s * 0.05),
				c + Vector2(-s * 0.08, -s * 0.3), c + Vector2(s * 0.06, -s * 0.44), c + Vector2(s * 0.14, -s * 0.36),
				c + Vector2(s * 0.04, -s * 0.26), c + Vector2(s * 0.06, s * 0.05), c + Vector2(s * 0.05, s * 0.42)])
			ci.draw_colored_polygon(pts, Color("4aa84a"))
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, lw * 0.6, true)
		"foot":   # a lower leg and its foot
			var pts := PackedVector2Array([c + Vector2(-s * 0.1, -s * 0.44), c + Vector2(s * 0.06, -s * 0.44),
				c + Vector2(s * 0.06, s * 0.22), c + Vector2(s * 0.4, s * 0.3), c + Vector2(s * 0.4, s * 0.42),
				c + Vector2(-s * 0.14, s * 0.42), c + Vector2(-s * 0.14, s * 0.2)])
			ci.draw_colored_polygon(pts, Color("d8a070"))
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, lw * 0.6, true)


# --- helpers ---------------------------------------------------------------------------------------------------------

static func _short_text(t: Variant, most: int) -> bool:
	return t is String and str(t).strip_edges() != "" and str(t).length() <= most


static func _catmull(p: PackedVector2Array, sub: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in p.size() - 1:
		var p0 := p[maxi(i - 1, 0)]
		var p1 := p[i]
		var p2 := p[i + 1]
		var p3 := p[mini(i + 2, p.size() - 1)]
		for k in sub:
			var t := float(k) / sub
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(p[p.size() - 1])
	return out


static func _ellipse(ci: CanvasItem, c: Vector2, radii: Vector2, col: Color, lower_half := false) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var t := (PI * i / 31.0) if lower_half else (TAU * i / 32.0)
		pts.append(c + Vector2(cos(t) * radii.x, sin(t) * radii.y))
	if lower_half:
		pts.append(c + Vector2(-radii.x, 0))
	ci.draw_colored_polygon(pts, col)


static func _ellipse_line(ci: CanvasItem, c: Vector2, radii: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		pts.append(c + Vector2(cos(t) * radii.x, sin(t) * radii.y))
	ci.draw_polyline(pts, INK, 1.5, true)


static func _rounded(ci: CanvasItem, box: Rect2, col: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(radius))
	ci.draw_style_box(sb, box)


## The biggest font size up to `size` at which `text` fits `width`.
static func _fit(font: Font, text: String, size: int, width: float) -> int:
	var fs := size
	while fs > 9 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
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
