class_name SchoolPictureG5Arts
extends RefCounted
## Owner #70 and #73, grade 5 computing, art and music (research §6.5): the picture kinds they add, drawn from data onto
## a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the font has
## no music signs or arrows, so they are drawn). Kinds and fields:
## Computing
## - pen {lines: [text] (1-9, the code picture's lines: FORWARD n, TURN LEFT, TURN RIGHT, PEN UP, PEN DOWN, REPEAT n
##   TIMES, DEFINE name, a line that is a procedure's name calls it), cols? (3-12, 8), rows? (3-8, 6), start? ([x, y], a
##   corner of the squares; the bottom left), facing? ("N", "E", "S", "W"; "E"), code? (true: the program beside)}: a pen
##   on squared paper draws what the program says (`trace`; it must stay on the paper and draw something).
## - var_boxes {boxes: [[name (10 letters), value (8)]] (1-4), mark?}: variables as named boxes holding their values.
## - sim_frames {what: "ball" | "plant", values: [numbers 0-top] (2-8), top (1-1000), labels? [text] (8 letters)}: a
##   simulation's steps as frames: the ball at its height above the floor, or the plant grown to its height.
## - packets {message (2-24 letters), size (2-8 a packet; at most 6 packets), order? [the packets' indexes, as they
##   arrive], to? (12), from? (12)}: a message split into numbered packets ("2 of 4"), each an envelope with its address.
## - search_page {query (28), results: [{title (36), ad?, note? (36)}] (1-4), mark?}: a page of search results; an
##   advert has its "Ad" tag.
## - shadow_photo {things: ["tree" | "person" | "post"] (2-4), sun: "left" | "right", odd? (a thing whose shadow falls
##   towards the sun: pasted in)}: a sunny photo; shadows fall away from the sun.
## - column_chart {bars: [[label (10), value]] (2-6), from? (0), to, step (at most 10 steps), title? (28), mark?}: a
##   chart whose axis may start above 0 (a chart that misleads).
## - sheet {cells: [[text (16)]] (1-7 rows of 1-5, all as long), mark? ("B5"), show? ("values" | "formulas")}: a
##   spreadsheet: columns A-E, rows 1-7; a formula (=SUM(B2:B5), =MAX(…), =MIN(…), =B2+C2, =B2-C2, =B2*C2; grade 6:
##   =AVERAGE(…) and =B2/C2) shows its value (`value`) unless show is "formulas"; the marked cell's formula is in the
##   formula bar.
## - chat {messages: [["me" | "them", text (44)]] (1-5), name? (14), mark?}: a chat's bubbles.
## - access_feature {what: ACCESS}: a phone showing a feature that helps: captions, read aloud, big text, high contrast,
##   voice control, alt text for a picture.
## Art
## - perspective {scene: "road" | "room" | "rails", lines? (the lines to the vanishing point), mark? ("vanishing point"
##   | "horizon"), labels?, vp? (0.2-0.8 across)}: one-point perspective.
## - greek_column {orders: ["doric" | "ionic" | "corinthian"] (1-3), labels?, mark?}: the Greek orders' columns.
## - greek_vase {style: "black-figure" | "red-figure"}: an amphora with a running figure.
## - mosaic {rows: [text] (1-12 of 1-16 letters, all as long), key: {letter: a colour of SchoolPictureArts}, grout?
##   (true)}: tesserae set in grout; "." is grout only.
## - building {what: BUILDINGS}: famous buildings and the ways to span a gap (post and lintel, round and pointed arches).
## - still_life {objects: [OBJECTS] (1-4), light: "left" | "right", shade? (true), labels? (highlight, shadow, cast
##   shadow)}: objects on a table lit from one side.
## - abstract {style: "grid" | "shapes" | "circles", variant? (0-3)}: art of shapes and colours only.
## - dye {what: "rings" | "spiral" | "batik" | "tied", colour: a colour of SchoolPictureArts}: dyed cloth (tie-dye rings
##   and spirals, batik's wax lines) and cloth tied before dyeing.
## - comic {panels: [{caption? (30), say? (30), think? (30), sfx? (10), shot? ("wide" | "medium" | "close")}] (1-4),
##   mark?}: comic panels with a caption box, speech and thought bubbles and a sound word.
## Music
## - keyboard {from? (a white key, "C4"), keys? (white keys 8-15, 8), mark? [notes on it, "Eb4" and "D#4" alike], names?,
##   steps? (T or S between the marked notes), scale? ("major" | "minor": what the marked scale is), title? (28)}.
## - chord_stave {chords: [[STAVE_NOTES going up] (2-4)] (1-4), names? [text (4)], mark?}: chords stacked on the stave.
## - song_form {sections: [text (8)] (2-8), mark?}: a song's parts in order, the same part the same colour.
## - lifespans {people: [[name (14), born, died]] (1-5), from, to (at most 400 years), mark?, year?}: lives on a timeline.
## - beat_grid {rows: [[name (10), pattern of x and - (4-16)]] (1-4, all as long), mark?, count?}: a beat grid (each box
##   a step: half a beat for 8, a quarter for 16); `count` writes 1 & 2 & over it.
## - beat_pattern {beats: 2 | 3 | 4, mark?}: a conductor's beat pattern: where the hand goes on each beat.
## - tracks {tracks: [[name (10), [[start bar, bars]]]] (1-4), bars (2-8), loop? [from, to], mark?}: a music maker's
##   tracks (layers) and their clips; a loop's bars shaded.
## - waveform {levels: [0-10] (4-24), keep? [from, to]}: a recording's loudness; the part kept by trimming.

const KINDS: Array[String] = ["pen", "var_boxes", "sim_frames", "packets", "search_page", "shadow_photo",
	"column_chart", "sheet", "chat", "access_feature", "perspective", "greek_column", "greek_vase", "mosaic", "building",
	"still_life", "abstract", "dye", "comic", "keyboard", "chord_stave", "song_form", "lifespans", "beat_grid",
	"beat_pattern", "tracks", "waveform"]
const HEADINGS: Array[String] = ["N", "E", "S", "W"]
const STEP := {"N": Vector2i(0, -1), "E": Vector2i(1, 0), "S": Vector2i(0, 1), "W": Vector2i(-1, 0)}
const MAX_PEN_MOVES := 400
const SIM_WHAT: Array[String] = ["ball", "plant"]
const THINGS: Array[String] = ["tree", "person", "post"]
const ACCESS: Array[String] = ["captions", "read_aloud", "big_text", "high_contrast", "voice", "alt_text"]
const SCENES: Array[String] = ["road", "room", "rails"]
const ORDERS: Array[String] = ["doric", "ionic", "corinthian"]
const VASES: Array[String] = ["black-figure", "red-figure"]
const BUILDINGS: Array[String] = ["pyramid", "parthenon", "pantheon", "aqueduct", "cathedral", "taj_mahal", "pagoda",
	"skyscraper", "lintel", "round_arch", "pointed_arch"]
const OBJECTS: Array[String] = ["apple", "pear", "lemon", "jug", "bowl", "bottle", "cup"]
const STYLES: Array[String] = ["grid", "shapes", "circles"]
const DYES: Array[String] = ["rings", "spiral", "batik", "tied"]
const SHOTS: Array[String] = ["wide", "medium", "close"]
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const LETTERS := "CDEFGAB"
const SECTION_COLOURS := {"A": Color("3a7be8"), "B": Color("f08a1c"), "C": Color("3aa845"), "D": Color("8a3fb8"),
	"verse": Color("3a7be8"), "chorus": Color("f08a1c"), "bridge": Color("3aa845"), "intro": Color("8c8c8c"),
	"outro": Color("8c8c8c")}
const ROW_COLOURS: Array[Color] = [Color("e03a2f"), Color("3a7be8"), Color("3aa845"), Color("f2c12e")]
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const BLUE := Color("3a7be8")
const SOFT := Color("fce2b8")
const GRID_LINE := Color("b9c6dd")
const PAPER_WHITE := Color("fffdf7")
const SKY := Color("bfe0f7")
const GRASS := Color("8cc56a")
const STONE := Color("e6d9bd")
const STONE_DARK := Color("b9a67f")
const CLAY := Color("d9773a")
const GLAZE := Color("231a14")
const LINK := Color("1a55c0")


# --- checks ----------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	match str(p.get("kind", "")):
		"pen":
			var t := trace(p)
			if str(t.error) != "":
				return "pen: %s" % t.error
		"var_boxes":
			var boxes: Variant = p.get("boxes")
			if not boxes is Array or (boxes as Array).is_empty() or (boxes as Array).size() > 4:
				return "var_boxes: 1-4 boxes"
			for b: Variant in boxes:
				if not b is Array or (b as Array).size() != 2 or not _short(b[0], 10) or not _short(str(b[1]), 8):
					return "var_boxes: a box is [name (10 letters), value (8)]"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (boxes as Array).size() - 1):
				return "var_boxes: mark is a box's index"
		"sim_frames":
			var values: Variant = p.get("values")
			var top := _num(p, "top", 0.0)
			if not SIM_WHAT.has(str(p.get("what", ""))) or not values is Array or (values as Array).size() < 2 \
					or (values as Array).size() > 8 or top <= 0.0 or top > 1000.0:
				return "sim_frames: what (ball, plant), 2-8 values and a top of 1-1000"
			for v: Variant in values:
				if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or float(v) < 0.0 or float(v) > top:
					return "sim_frames: each value 0-top"
			if p.has("labels") and not _texts(p.labels, (values as Array).size(), 8):
				return "sim_frames: a label (8 letters) for every frame"
		"packets":
			if not _short(p.get("message"), 24) or str(p.message).length() < 2 or not _in(_int(p, "size", 0), 2, 8):
				return "packets: a message of 2-24 letters and a size of 2-8"
			var n := packets_of(str(p.message), _int(p, "size", 2)).size()
			if n > 6:
				return "packets: at most 6 packets"
			if p.has("order") and not _is_order(p.order, n):
				return "packets: order lists every packet once"
			for k: String in ["to", "from"]:
				if p.has(k) and not _short(p[k], 12):
					return "packets: %s is 1-12 letters" % k
		"search_page":
			var results: Variant = p.get("results")
			if not _short(p.get("query"), 28) or not results is Array or (results as Array).is_empty() \
					or (results as Array).size() > 4:
				return "search_page: a query (28 letters) and 1-4 results"
			for res: Variant in results:
				if not res is Dictionary or not _short(res.get("title"), 36) or (res.has("note") and not _short(res.note, 36)):
					return "search_page: a result has a title (36 letters) and maybe a note (36)"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (results as Array).size() - 1):
				return "search_page: mark is a result's index"
		"shadow_photo":
			var things: Variant = p.get("things")
			if not things is Array or (things as Array).size() < 2 or (things as Array).size() > 4:
				return "shadow_photo: 2-4 things"
			for t: Variant in things:
				if not THINGS.has(str(t)):
					return "shadow_photo: a thing is one of %s" % [THINGS]
			if not str(p.get("sun", "")) in ["left", "right"]:
				return "shadow_photo: sun is left or right"
			if p.has("odd") and not _in(_int(p, "odd", -1), 0, (things as Array).size() - 1):
				return "shadow_photo: odd is a thing's index"
		"column_chart":
			var bars: Variant = p.get("bars")
			var from := _num(p, "from", 0.0)
			var to := _num(p, "to", 0.0)
			var step := _num(p, "step", 0.0)
			if not bars is Array or (bars as Array).size() < 2 or (bars as Array).size() > 6:
				return "column_chart: 2-6 bars"
			if step <= 0.0 or to <= from or (to - from) / step > 10.001 \
					or absf((to - from) / step - roundf((to - from) / step)) > 0.001:
				return "column_chart: from < to in at most 10 steps"
			for b: Variant in bars:
				if not b is Array or (b as Array).size() != 2 or not _short(b[0], 10) \
						or typeof(b[1]) not in [TYPE_INT, TYPE_FLOAT] or float(b[1]) < from or float(b[1]) > to:
					return "column_chart: a bar is [label (10), a value from-to]"
			if p.has("title") and not _short(p.title, 28):
				return "column_chart: a title of 28 letters"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (bars as Array).size() - 1):
				return "column_chart: mark is a bar's index"
		"sheet":
			var cells: Variant = p.get("cells")
			if not cells is Array or (cells as Array).is_empty() or (cells as Array).size() > 7:
				return "sheet: 1-7 rows"
			var width := -1
			for row: Variant in cells:
				if not row is Array or (row as Array).is_empty() or (row as Array).size() > 5:
					return "sheet: a row of 1-5 cells"
				if width >= 0 and (row as Array).size() != width:
					return "sheet: every row as long"
				width = (row as Array).size()
				for c: Variant in row:
					if not c is String or str(c).length() > 16:   # grade 6: =AVERAGE(B2:B5) is 15
						return "sheet: a cell is text of 16 letters"
			for r in (cells as Array).size():
				for c in width:
					var t := str(cells[r][c])
					if t.begins_with("=") and is_nan(value(p, _ref(c, r))):
						return "sheet: %s's formula %s can't be worked out" % [_ref(c, r), t]
			if p.has("mark") and _cell_at(p, str(p.mark)) == null:
				return "sheet: mark is a cell (B5)"
			if p.has("show") and not str(p.show) in ["values", "formulas"]:
				return "sheet: show is values or formulas"
		"chat":
			var messages: Variant = p.get("messages")
			if not messages is Array or (messages as Array).is_empty() or (messages as Array).size() > 5:
				return "chat: 1-5 messages"
			for m: Variant in messages:
				if not m is Array or (m as Array).size() != 2 or not str(m[0]) in ["me", "them"] or not _short(m[1], 44):
					return "chat: a message is [me or them, text of 44 letters]"
			if p.has("name") and not _short(p.name, 14):
				return "chat: a name of 14 letters"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (messages as Array).size() - 1):
				return "chat: mark is a message's index"
		"access_feature":
			if not ACCESS.has(str(p.get("what", ""))):
				return "access_feature: what is one of %s" % [ACCESS]
		"perspective":
			if not SCENES.has(str(p.get("scene", ""))):
				return "perspective: scene is one of %s" % [SCENES]
			if p.has("mark") and not str(p.mark) in ["vanishing point", "horizon"]:
				return "perspective: mark is the vanishing point or the horizon"
			if p.has("vp") and (_num(p, "vp", 0.0) < 0.2 or _num(p, "vp", 0.0) > 0.8):
				return "perspective: vp is 0.2-0.8"
		"greek_column":
			var orders: Variant = p.get("orders")
			if not orders is Array or (orders as Array).is_empty() or (orders as Array).size() > 3:
				return "greek_column: 1-3 orders"
			for o: Variant in orders:
				if not ORDERS.has(str(o)):
					return "greek_column: an order is one of %s" % [ORDERS]
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (orders as Array).size() - 1):
				return "greek_column: mark is a column's index"
		"greek_vase":
			if not VASES.has(str(p.get("style", ""))):
				return "greek_vase: style is one of %s" % [VASES]
		"mosaic":
			var rows: Variant = p.get("rows")
			var key: Variant = p.get("key")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > 12 or not key is Dictionary:
				return "mosaic: 1-12 rows and a key"
			var w := str(rows[0]).length()
			for row: Variant in rows:
				if not row is String or str(row).length() != w or w < 1 or w > 16:
					return "mosaic: rows of 1-16 letters, all as long"
				for ch in str(row):
					if ch != "." and not SchoolPictureArts.COLOURS.has(str(key.get(ch, ""))):
						return "mosaic: '%s' needs a colour in the key" % ch
		"building":
			if not BUILDINGS.has(str(p.get("what", ""))):
				return "building: what is one of %s" % [BUILDINGS]
		"still_life":
			var objects: Variant = p.get("objects")
			if not objects is Array or (objects as Array).is_empty() or (objects as Array).size() > 4:
				return "still_life: 1-4 objects"
			for o: Variant in objects:
				if not OBJECTS.has(str(o)):
					return "still_life: an object is one of %s" % [OBJECTS]
			if not str(p.get("light", "")) in ["left", "right"]:
				return "still_life: light is left or right"
		"abstract":
			if not STYLES.has(str(p.get("style", ""))) or not _in(_int(p, "variant", 0), 0, 3):
				return "abstract: style is one of %s, variant 0-3" % [STYLES]
		"dye":
			if not DYES.has(str(p.get("what", ""))) or not SchoolPictureArts.COLOURS.has(str(p.get("colour", ""))):
				return "dye: what is one of %s and colour a paint colour" % [DYES]
		"comic":
			var panels: Variant = p.get("panels")
			if not panels is Array or (panels as Array).is_empty() or (panels as Array).size() > 4:
				return "comic: 1-4 panels"
			for pn: Variant in panels:
				if not pn is Dictionary:
					return "comic: a panel is a dictionary"
				for k: String in ["caption", "say", "think"]:
					if pn.has(k) and not _short(pn[k], 30):
						return "comic: a %s of 30 letters" % k
				if pn.has("sfx") and not _short(pn.sfx, 10):
					return "comic: a sound word of 10 letters"
				if pn.has("shot") and not SHOTS.has(str(pn.shot)):
					return "comic: shot is one of %s" % [SHOTS]
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (panels as Array).size() - 1):
				return "comic: mark is a panel's index"
		"keyboard":
			var from := _pitch(str(p.get("from", "C4")))
			var keys := _int(p, "keys", 8)
			if from < 0 or str(p.get("from", "C4")).length() != 2 or not _in(keys, 8, 15):
				return "keyboard: from is a white key (C4) and keys 8-15"
			var top := _white_pitch(from, keys - 1)
			for m: Variant in p.get("mark", []):
				var at := _pitch(str(m))
				if at < from or at > top:
					return "keyboard: %s is not on the keyboard" % m
			if p.has("scale") and not str(p.scale) in ["major", "minor"]:
				return "keyboard: scale is major or minor"
			if p.has("title") and not _short(p.title, 28):
				return "keyboard: a title of 28 letters"
		"chord_stave":
			var chords: Variant = p.get("chords")
			if not chords is Array or (chords as Array).is_empty() or (chords as Array).size() > 4:
				return "chord_stave: 1-4 chords"
			for ch: Variant in chords:
				if not ch is Array or (ch as Array).size() < 2 or (ch as Array).size() > 4:
					return "chord_stave: a chord of 2-4 notes"
				for i in (ch as Array).size():
					if not SchoolPictureG4Arts.STAVE_NOTES.has(str(ch[i])):
						return "chord_stave: '%s' is not a stave note" % ch[i]
					if i > 0 and SchoolPictureG4Arts.stave_step(str(ch[i])) <= SchoolPictureG4Arts.stave_step(str(ch[i - 1])):
						return "chord_stave: a chord's notes go up"
			if p.has("names") and not _texts(p.names, (chords as Array).size(), 4):
				return "chord_stave: a name (4 letters) for every chord"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (chords as Array).size() - 1):
				return "chord_stave: mark is a chord's index"
		"song_form":
			var sections: Variant = p.get("sections")
			if not sections is Array or (sections as Array).size() < 2 or (sections as Array).size() > 8 \
					or not _texts(sections, (sections as Array).size(), 8):
				return "song_form: 2-8 sections of 8 letters"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (sections as Array).size() - 1):
				return "song_form: mark is a section's index"
		"lifespans":
			var people: Variant = p.get("people")
			var from := _int(p, "from", 0)
			var to := _int(p, "to", 0)
			if to <= from or to - from > 400 or not people is Array or (people as Array).is_empty() \
					or (people as Array).size() > 5:
				return "lifespans: from < to (at most 400 years) and 1-5 people"
			for row: Variant in people:
				if not row is Array or (row as Array).size() != 3 or not _short(row[0], 14) \
						or typeof(row[1]) not in [TYPE_INT, TYPE_FLOAT] or typeof(row[2]) not in [TYPE_INT, TYPE_FLOAT] \
						or int(row[1]) >= int(row[2]) or int(row[1]) < from or int(row[2]) > to:
					return "lifespans: a life is [name, born, died] from-to"
			if p.has("year") and not _in(_int(p, "year", -1), from, to):
				return "lifespans: year is from-to"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (people as Array).size() - 1):
				return "lifespans: mark is a person's index"
		"beat_grid":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > 4:
				return "beat_grid: 1-4 rows"
			var n := -1
			for row: Variant in rows:
				if not row is Array or (row as Array).size() != 2 or not _short(row[0], 10) or not row[1] is String:
					return "beat_grid: a row is [name, pattern]"
				var pat := str(row[1])
				if pat.length() < 4 or pat.length() > 16 or (n >= 0 and pat.length() != n) \
						or pat.replace("x", "").replace("-", "") != "":
					return "beat_grid: patterns of 4-16 x and -, all as long"
				n = pat.length()
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (rows as Array).size() - 1):
				return "beat_grid: mark is a row's index"
		"beat_pattern":
			if not _in(_int(p, "beats", 0), 2, 4):
				return "beat_pattern: 2, 3 or 4 beats"
			if p.has("mark") and not _in(_int(p, "mark", -1), 1, _int(p, "beats", 0)):
				return "beat_pattern: mark is a beat (1 up)"
		"tracks":
			var tracks: Variant = p.get("tracks")
			var bars := _int(p, "bars", 0)
			if not _in(bars, 2, 8) or not tracks is Array or (tracks as Array).is_empty() or (tracks as Array).size() > 4:
				return "tracks: 2-8 bars and 1-4 tracks"
			for t: Variant in tracks:
				if not t is Array or (t as Array).size() != 2 or not _short(t[0], 10) or not t[1] is Array:
					return "tracks: a track is [name, clips]"
				for c: Variant in t[1]:
					if not c is Array or (c as Array).size() != 2 or int(c[0]) < 0 or int(c[1]) < 1 \
							or int(c[0]) + int(c[1]) > bars:
						return "tracks: a clip is [start bar, bars] inside the bars"
			if p.has("loop"):
				var lp: Variant = p.loop
				if not lp is Array or (lp as Array).size() != 2 or int(lp[0]) < 0 or int(lp[1]) <= int(lp[0]) \
						or int(lp[1]) > bars:
					return "tracks: loop is [from, to] bars"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (tracks as Array).size() - 1):
				return "tracks: mark is a track's index"
		"waveform":
			var levels: Variant = p.get("levels")
			if not levels is Array or (levels as Array).size() < 4 or (levels as Array).size() > 24:
				return "waveform: 4-24 levels"
			for v: Variant in levels:
				if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or float(v) < 0.0 or float(v) > 10.0:
					return "waveform: each level 0-10"
			if p.has("keep"):
				var k: Variant = p.keep
				if not k is Array or (k as Array).size() != 2 or int(k[0]) < 0 or int(k[1]) <= int(k[0]) \
						or int(k[1]) > (levels as Array).size():
					return "waveform: keep is [from, to]"
	return ""


# --- facts the tests share -------------------------------------------------------------------------------------------

## Runs a pen picture's program: {segments: [[Vector2i, Vector2i]] (each a square's side drawn), pos, facing, moves (the
## sides drawn), error ("" when it can be drawn)}.
static func trace(d: Dictionary) -> Dictionary:
	var cols := _int(d, "cols", 8)
	var rows := _int(d, "rows", 6)
	var state := {"segments": [], "pos": Vector2i(0, rows), "facing": str(d.get("facing", "E")), "pen": true,
		"moves": 0, "steps": 0, "error": "", "cols": cols, "rows": rows}
	var lines: Variant = d.get("lines")
	if not _in(cols, 3, 12) or not _in(rows, 3, 8):
		state.error = "cols 3-12 and rows 3-8"
		return state
	if not HEADINGS.has(str(state.facing)):
		state.error = "facing is N, E, S or W"
		return state
	if d.has("start"):
		var s: Variant = d.start
		if not s is Array or (s as Array).size() != 2 or not _in(int(s[0]), 0, cols) or not _in(int(s[1]), 0, rows):
			state.error = "start is a corner on the paper"
			return state
		state.pos = Vector2i(int(s[0]), int(s[1]))
	if not lines is Array or (lines as Array).is_empty() or (lines as Array).size() > 9:
		state.error = "1-9 lines"
		return state
	var procs := {}
	var top: Array[int] = []
	for i in (lines as Array).size():
		var l: Variant = lines[i]
		if not l is String or str(l).strip_edges() == "" or str(l).length() > 32:
			state.error = "a line of 1-32 letters"
			return state
		var depth := SchoolPictureG4Arts._depth(str(l))
		var before := SchoolPictureG4Arts._depth(str(lines[i - 1])) if i > 0 else -1
		if depth > before + 1 or (depth == before + 1 and i > 0 and not _opens(str(lines[i - 1]))):
			state.error = "only REPEAT and DEFINE have lines inside them"
			return state
		if depth == 0:
			top.append(i)
			if str(l).begins_with("DEFINE "):
				procs[str(l).substr(7)] = i
	_pen_run(lines, top, procs, state, 0)
	if str(state.error) == "" and (state.segments as Array).is_empty():
		state.error = "the pen draws nothing"
	state.erase("steps")
	return state


static func _opens(line: String) -> bool:
	var t := line.strip_edges()
	return t.begins_with("REPEAT ") or t.begins_with("DEFINE ")


static func _pen_run(lines: Array, which: Array[int], procs: Dictionary, st: Dictionary, calls: int) -> void:
	for i in which:
		if str(st.error) != "":
			return
		var t := str(lines[i]).strip_edges()
		var words := t.split(" ")
		if words[0] == "DEFINE":
			continue
		if words[0] == "REPEAT" and words.size() >= 2 and words[1].is_valid_int() and _in(int(words[1]), 1, 12) \
				and (words.size() == 2 or (words.size() == 3 and words[2] == "TIMES")):
			var inner := _inner(lines, i)
			if inner.is_empty():
				st.error = "REPEAT with nothing inside"
				return
			for k in int(words[1]):
				_pen_run(lines, inner, procs, st, calls)
		elif words[0] == "FORWARD" and (words.size() == 1 or (words.size() == 2 and words[1].is_valid_int()
				and _in(int(words[1]), 1, 12))):
			for k in (1 if words.size() == 1 else int(words[1])):
				var next: Vector2i = st.pos + STEP[st.facing]
				if next.x < 0 or next.y < 0 or next.x > int(st.cols) or next.y > int(st.rows):
					st.error = "the pen goes off the paper"
					return
				if st.pen:
					(st.segments as Array).append([st.pos, next])
					st.moves = int(st.moves) + 1
				st.pos = next
				st.steps = int(st.steps) + 1
				if int(st.steps) > MAX_PEN_MOVES:
					st.error = "too many moves"
					return
		elif t == "TURN LEFT" or t == "TURN RIGHT":
			st.facing = HEADINGS[(HEADINGS.find(str(st.facing)) + (3 if t == "TURN LEFT" else 1)) % 4]
		elif t == "PEN UP" or t == "PEN DOWN":
			st.pen = t == "PEN DOWN"
		elif procs.has(t):
			if calls >= 8:
				st.error = "a procedure calls itself for ever"
				return
			_pen_run(lines, _inner(lines, int(procs[t])), procs, st, calls + 1)
		else:
			st.error = "'%s' is not a pen command" % t
			return


static func _inner(lines: Array, at: int) -> Array[int]:
	var out: Array[int] = []
	var d := SchoolPictureG4Arts._depth(str(lines[at]))
	for j in range(at + 1, lines.size()):
		var dj := SchoolPictureG4Arts._depth(str(lines[j]))
		if dj <= d:
			break
		if dj == d + 1:
			out.append(j)
	return out


## A message split into packets of `size` letters: "HELLO GRAN" in fours is HELL, O GR, AN.
static func packets_of(message: String, size: int) -> Array[String]:
	var out: Array[String] = []
	var at := 0
	while at < message.length() and size > 0:
		out.append(message.substr(at, size))
		at += size
	return out


## A spreadsheet cell's value ("B5"): a number, or its formula worked out; NAN for text, a missing cell or a formula
## that can't be worked out (or refers to itself).
static func value(d: Dictionary, ref: String, depth: int = 0) -> float:
	var c: Variant = _cell_at(d, ref)
	if c == null or depth > 20:
		return NAN
	var t := str(c).strip_edges()
	if not t.begins_with("="):
		return float(t) if t.is_valid_float() else NAN
	var f := t.substr(1)
	var fn := RegEx.create_from_string("^(SUM|MAX|MIN|AVERAGE)\\(([A-E])([1-7]):([A-E])([1-7])\\)$").search(f)
	if fn != null:
		var values: Array[float] = []
		for col in range(fn.get_string(2).unicode_at(0), fn.get_string(4).unicode_at(0) + 1):
			for row in range(int(fn.get_string(3)), int(fn.get_string(5)) + 1):
				values.append(value(d, String.chr(col) + str(row), depth + 1))
		if values.is_empty():
			return NAN
		var out: float = 0.0 if fn.get_string(1) in ["SUM", "AVERAGE"] else values[0]
		for v in values:
			if is_nan(v):
				return NAN
			match fn.get_string(1):
				"SUM", "AVERAGE":
					out += v
				"MAX":
					out = maxf(out, v)
				"MIN":
					out = minf(out, v)
		return out / values.size() if fn.get_string(1) == "AVERAGE" else out
	var op := RegEx.create_from_string("^([A-E][1-7]|\\d+)([+*/-])([A-E][1-7]|\\d+)$").search(f)
	if op == null:
		return NAN
	var a := float(op.get_string(1)) if op.get_string(1).is_valid_int() else value(d, op.get_string(1), depth + 1)
	var b := float(op.get_string(3)) if op.get_string(3).is_valid_int() else value(d, op.get_string(3), depth + 1)
	match op.get_string(2):
		"+":
			return a + b
		"-":
			return a - b
		"/":   # grade 6: a share (NAN when it divides by 0)
			return a / b if b != 0.0 else NAN
	return a * b


static func _cell_at(d: Dictionary, ref: String) -> Variant:
	if ref.length() < 2 or not ref.substr(1).is_valid_int():
		return null
	var col := ref.unicode_at(0) - "A".unicode_at(0)
	var row := int(ref.substr(1)) - 1
	var cells: Variant = d.get("cells")
	if not cells is Array or row < 0 or row >= (cells as Array).size() or not cells[row] is Array or col < 0 \
			or col >= (cells[row] as Array).size():
		return null
	return cells[row][col]


static func _ref(col: int, row: int) -> String:
	return String.chr("A".unicode_at(0) + col) + str(row + 1)


## A note's pitch in semitones ("C4" = 48, "Eb4" = 51, "F#3" = 42); -1 for anything else.
static func _pitch(note: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([2-6])$").search(note)
	if m == null:
		return -1
	return 12 * int(m.get_string(3)) + int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else \
		(-1 if m.get_string(2) == "b" else 0))


## The pitch of the white key `k` keys above the white key at `from`.
static func _white_pitch(from: int, k: int) -> int:
	var letter := 0
	for i in 7:
		if int(SEMIS[LETTERS[i]]) == posmod(from, 12):
			letter = i
	var octave := from / 12
	var idx := letter + k
	return 12 * (octave + idx / 7) + int(SEMIS[LETTERS[idx % 7]])


# --- drawing ---------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"pen":
			_draw_pen(pic, font, r, d)
		"var_boxes":
			_draw_boxes(pic, font, r, d)
		"sim_frames":
			_draw_frames(pic, font, r, d)
		"packets":
			_draw_packets(pic, font, r, d)
		"search_page":
			_draw_search(pic, font, r, d)
		"shadow_photo":
			_draw_shadows(pic, r, d)
		"column_chart":
			_draw_chart(pic, font, r, d)
		"sheet":
			_draw_sheet(pic, font, r, d)
		"chat":
			_draw_chat(pic, font, r, d)
		"access_feature":
			_draw_access(pic, font, r, d)
		"perspective":
			_draw_perspective(pic, font, r, d)
		"greek_column":
			_draw_columns(pic, font, r, d)
		"greek_vase":
			_draw_vase(pic, r, d)
		"mosaic":
			_draw_mosaic(pic, r, d)
		"building":
			_draw_building(pic, r, d)
		"still_life":
			_draw_still_life(pic, font, r, d)
		"abstract":
			_draw_abstract(pic, r, d)
		"dye":
			_draw_dye(pic, r, d)
		"comic":
			_draw_comic(pic, font, r, d)
		"keyboard":
			_draw_keyboard(pic, font, r, d)
		"chord_stave":
			_draw_chord_stave(pic, font, r, d)
		"song_form":
			_draw_form(pic, font, r, d)
		"lifespans":
			_draw_lifespans(pic, font, r, d)
		"beat_grid":
			_draw_beat_grid(pic, font, r, d)
		"beat_pattern":
			_draw_beat_pattern(pic, font, r, d)
		"tracks":
			_draw_tracks(pic, font, r, d)
		"waveform":
			_draw_waveform(pic, r, d)


static func _fs(r: Rect2, share: float = 0.11, most: int = 22) -> int:
	return clampi(int(r.size.y * share), 10, most)


# --- computing -------------------------------------------------------------------------------------------------------

static func _draw_pen(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var t := trace(d)
	var area := r
	if bool(d.get("code", false)):
		var left := Rect2(r.position, Vector2(r.size.x * 0.46, r.size.y))
		SchoolPictureG4Arts._draw_code(ci, font, left, {"lines": d.lines})
		area = Rect2(r.position + Vector2(r.size.x * 0.5, 0), Vector2(r.size.x * 0.5, r.size.y))
	var cols := int(t.cols)
	var rows := int(t.rows)
	var cell := minf(area.size.x / cols, area.size.y / rows)
	var o := area.position + (area.size - Vector2(cols, rows) * cell) * 0.5
	ci.draw_rect(Rect2(o, Vector2(cols, rows) * cell), PAPER_WHITE)
	for x in cols + 1:
		ci.draw_line(o + Vector2(x * cell, 0), o + Vector2(x * cell, rows * cell), GRID_LINE, 1.0)
	for y in rows + 1:
		ci.draw_line(o + Vector2(0, y * cell), o + Vector2(cols * cell, y * cell), GRID_LINE, 1.0)
	var w := clampf(cell * 0.16, 2.5, 6.0)
	for s: Array in t.segments:
		var a: Vector2i = s[0]
		var b: Vector2i = s[1]
		ci.draw_line(o + Vector2(a) * cell, o + Vector2(b) * cell, BLUE, w, true)
	var start: Vector2i = Vector2i(0, rows)
	if d.has("start"):
		start = Vector2i(int(d.start[0]), int(d.start[1]))
	ci.draw_circle(o + Vector2(start) * cell, w * 1.1, Color("3aa845"))
	var end_at: Vector2i = t.pos
	var step_v: Vector2i = STEP[str(t.facing)]
	var at := o + Vector2(end_at) * cell
	var dir := Vector2(step_v)
	var side := Vector2(-dir.y, dir.x)
	var s2 := maxf(cell * 0.28, 6.0)
	ci.draw_colored_polygon(PackedVector2Array([at + dir * s2, at - dir * s2 * 0.5 + side * s2 * 0.6,
		at - dir * s2 * 0.5 - side * s2 * 0.6]), SHADE)


static func _draw_boxes(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var boxes: Array = d.boxes
	var n := boxes.size()
	var mark := _int(d, "mark", -1)
	var bw := minf(r.size.x / n * 0.8, r.size.y * 0.9)
	var gap := (r.size.x - bw * n) / (n + 1)
	var fs := clampi(int(bw * 0.18), 10, 24)
	for i in n:
		var x := r.position.x + gap + i * (bw + gap)
		var body := Rect2(Vector2(x, r.position.y + r.size.y * 0.12), Vector2(bw, r.size.y * 0.58))
		var col := SHADE if i == mark else BLUE
		SchoolPictureG4Arts._rounded(ci, body.grow(3), col, bw * 0.1)
		SchoolPictureG4Arts._rounded(ci, body, PAPER_WHITE, bw * 0.08)
		var v := str(boxes[i][1])
		SchoolPictureG4Arts._label(ci, font, body.get_center(), v, SchoolPictureG4Arts._fit(font, v, int(fs * 1.5),
			bw * 0.9))
		var tag := Rect2(Vector2(x, body.end.y + r.size.y * 0.06), Vector2(bw, r.size.y * 0.2))
		SchoolPictureG4Arts._rounded(ci, tag, col, 6)
		var name := str(boxes[i][0])
		SchoolPictureG4Arts._label(ci, font, tag.get_center(), name, SchoolPictureG4Arts._fit(font, name, fs, bw * 0.92),
			Color.WHITE)


static func _draw_frames(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var values: Array = d.values
	var n := values.size()
	var top := _num(d, "top", 1.0)
	var labels: Array = d.get("labels", [])
	var fs := _fs(r, 0.1, 18)
	var lab_h := fs * 1.5
	var fw := r.size.x / n
	for i in n:
		var box := Rect2(Vector2(r.position.x + i * fw + 3, r.position.y), Vector2(fw - 6, r.size.y - lab_h))
		SchoolPictureG4Arts._rounded(ci, box, SKY if str(d.what) == "ball" else Color("eaf5e0"), 6)
		var floor_y := box.end.y - box.size.y * 0.1
		ci.draw_rect(Rect2(Vector2(box.position.x, floor_y), Vector2(box.size.x, box.end.y - floor_y)),
			Color("c9a36b") if str(d.what) == "plant" else Color("8a8a8a"))
		var h := (floor_y - box.position.y - box.size.y * 0.08) * float(values[i]) / top
		var cx := box.get_center().x
		if str(d.what) == "ball":
			var rad := minf(box.size.x * 0.22, box.size.y * 0.1)
			h = (floor_y - box.position.y - 2.0 * rad - 3.0) * float(values[i]) / top   # the whole ball stays in its frame
			ci.draw_circle(Vector2(cx, floor_y - h - rad), rad, Color("e03a2f"))
			ci.draw_circle(Vector2(cx - rad * 0.35, floor_y - h - rad * 1.35), rad * 0.25, Color(1, 1, 1, 0.7))
		else:
			if h > 0.5:
				ci.draw_line(Vector2(cx, floor_y), Vector2(cx, floor_y - h), Color("2f8a3a"), maxf(2.0, box.size.x * 0.05))
				var leaf := minf(box.size.x * 0.18, 14.0)
				for k in int(clampf(h / (leaf * 1.6), 1.0, 5.0)):
					var ly := floor_y - h * (k + 1) / (clampf(h / (leaf * 1.6), 1.0, 5.0) + 0.5)
					var sgn := 1.0 if k % 2 == 0 else -1.0
					SchoolPictureG4Arts._ellipse(ci, Vector2(cx + sgn * leaf * 0.6, ly), Vector2(leaf * 0.6, leaf * 0.3),
						Color("3aa845"))
			ci.draw_circle(Vector2(cx, floor_y), maxf(2.0, box.size.x * 0.05), Color("6b4a2a"))
		var label := str(labels[i]) if not labels.is_empty() else str(i + 1)
		SchoolPictureG4Arts._label(ci, font, Vector2(cx, r.end.y - lab_h * 0.5), label,
			SchoolPictureG4Arts._fit(font, label, fs, fw - 4))


static func _draw_packets(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var parts := packets_of(str(d.message), int(d.size))
	var n := parts.size()
	var order: Array = d.get("order", range(n))
	var per_row := mini(n, 3)
	var lines := int(ceil(n / 3.0))
	var ew := r.size.x / per_row
	var eh := r.size.y / lines
	var fs := clampi(int(eh * 0.2), 9, 22)
	for k in n:
		var i := int(order[k])
		var box := Rect2(r.position + Vector2((k % 3) * ew, (k / 3) * eh), Vector2(ew, eh)).grow(-4)
		ci.draw_rect(box, Color("fff4d6"))
		ci.draw_rect(box, INK, false, 1.5)
		ci.draw_polyline(PackedVector2Array([box.position, box.position + Vector2(box.size.x * 0.5, box.size.y * 0.32),
			Vector2(box.end.x, box.position.y)]), Color("c9a36b"), 1.5)
		SchoolPictureG4Arts._label(ci, font, box.position + Vector2(box.size.x * 0.5, box.size.y * 0.16),
			"%d of %d" % [i + 1, n], clampi(int(fs * 0.8), 9, 18), Color("8a5a3a"))
		var text := parts[i].replace(" ", "·")
		SchoolPictureG4Arts._label(ci, font, box.position + Vector2(box.size.x * 0.5, box.size.y * 0.58), text,
			SchoolPictureG4Arts._fit(font, text, int(fs * 1.3), box.size.x * 0.9))
		if d.has("to"):
			var to := "to %s" % d.to + (" from %s" % d.from if d.has("from") else "")
			SchoolPictureG4Arts._label(ci, font, box.position + Vector2(box.size.x * 0.5, box.size.y * 0.86), to,
				SchoolPictureG4Arts._fit(font, to, int(fs * 0.75), box.size.x * 0.92), BLUE)


static func _draw_search(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var results: Array = d.results
	var mark := _int(d, "mark", -1)
	var bar_h := r.size.y * 0.2
	var fs := clampi(int(bar_h * 0.5), 9, 22)
	var bar := Rect2(r.position + Vector2(r.size.x * 0.04, 0), Vector2(r.size.x * 0.92, bar_h))
	SchoolPictureG4Arts._rounded(ci, bar, Color.WHITE, bar_h * 0.5)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(2)
	sb.border_color = GRID_LINE
	sb.set_corner_radius_all(int(bar_h * 0.5))
	ci.draw_style_box(sb, bar)
	var glass := bar.position + Vector2(bar_h * 0.5, bar_h * 0.45)
	ci.draw_arc(glass, bar_h * 0.2, 0, TAU, 16, INK, 2.0)
	ci.draw_line(glass + Vector2(bar_h * 0.14, bar_h * 0.14), glass + Vector2(bar_h * 0.3, bar_h * 0.3), INK, 2.5)
	var q := str(d.query)
	ci.draw_string(font, bar.position + Vector2(bar_h * 0.95, bar_h * 0.5 + fs * 0.35), q, HORIZONTAL_ALIGNMENT_LEFT,
		bar.size.x - bar_h * 1.2, SchoolPictureG4Arts._fit(font, q, fs, bar.size.x - bar_h * 1.2), INK)
	var rh := (r.size.y - bar_h * 1.3) / results.size()
	for i in results.size():
		var res: Dictionary = results[i]
		var box := Rect2(Vector2(bar.position.x, r.position.y + bar_h * 1.3 + i * rh), Vector2(bar.size.x, rh - 4))
		if i == mark:
			var mb := StyleBoxFlat.new()
			mb.draw_center = false
			mb.set_border_width_all(3)
			mb.border_color = SHADE
			mb.set_corner_radius_all(6)
			ci.draw_style_box(mb, box.grow(2))
		var x := box.position.x + 6
		var tfs := clampi(int(rh * (0.34 if res.has("note") else 0.42)), 9, 22)
		var ty := box.position.y + (rh * 0.36 if res.has("note") else rh * 0.5)
		if bool(res.get("ad", false)):
			var tag := Rect2(Vector2(x, ty - tfs * 0.6), Vector2(tfs * 1.6, tfs * 1.2))
			SchoolPictureG4Arts._rounded(ci, tag, Color("222222"), 4)
			SchoolPictureG4Arts._label(ci, font, tag.get_center(), "Ad", int(tfs * 0.8), Color.WHITE)
			x = tag.end.x + 6
		var title := str(res.title)
		var size := SchoolPictureG4Arts._fit(font, title, tfs, box.end.x - x - 4)
		ci.draw_string(font, Vector2(x, ty + size * 0.35), title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, LINK)
		if res.has("note"):
			var note := str(res.note)
			var ns := SchoolPictureG4Arts._fit(font, note, int(tfs * 0.8), box.size.x - 12)
			ci.draw_string(font, Vector2(box.position.x + 6, box.position.y + rh * 0.78), note, HORIZONTAL_ALIGNMENT_LEFT,
				-1, ns, Color("5a6478"))


static func _draw_shadows(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var things: Array = d.things
	var left := str(d.sun) == "left"
	var odd := _int(d, "odd", -1)
	var ground_y := r.position.y + r.size.y * 0.55
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, ground_y - r.position.y)), SKY)
	ci.draw_rect(Rect2(Vector2(r.position.x, ground_y), Vector2(r.size.x, r.end.y - ground_y)), GRASS)
	var sun := Vector2(r.position.x + r.size.x * (0.08 if left else 0.92), r.position.y + r.size.y * 0.14)
	ci.draw_circle(sun, r.size.y * 0.09, Color("ffd23f"))
	for k in 8:
		var a := TAU * k / 8.0
		ci.draw_line(sun + Vector2(cos(a), sin(a)) * r.size.y * 0.12, sun + Vector2(cos(a), sin(a)) * r.size.y * 0.16,
			Color("ffd23f"), 2.0)
	var n := things.size()
	for i in n:
		var base := Vector2(r.position.x + r.size.x * (0.2 + 0.6 * i / maxf(1.0, n - 1.0)), r.position.y + r.size.y * 0.8)
		var h := r.size.y * 0.42
		var away := (1.0 if left else -1.0) * (-1.0 if i == odd else 1.0)   # shadows fall away from the sun
		SchoolPictureG4Arts._ellipse(ci, base + Vector2(away * h * 0.42, h * 0.03), Vector2(h * 0.44, h * 0.06),
			Color(0.1, 0.2, 0.1, 0.45))
		match str(things[i]):
			"tree":
				ci.draw_rect(Rect2(base + Vector2(-h * 0.05, -h * 0.5), Vector2(h * 0.1, h * 0.5)), Color("7a4a24"))
				ci.draw_circle(base + Vector2(0, -h * 0.72), h * 0.28, Color("2f8a3a"))
			"person":
				ci.draw_line(base + Vector2(-h * 0.06, 0), base + Vector2(0, -h * 0.35), INK, 3.0)
				ci.draw_line(base + Vector2(h * 0.06, 0), base + Vector2(0, -h * 0.35), INK, 3.0)
				ci.draw_rect(Rect2(base + Vector2(-h * 0.08, -h * 0.72), Vector2(h * 0.16, h * 0.38)), Color("3a7be8"))
				ci.draw_circle(base + Vector2(0, -h * 0.82), h * 0.1, Color("c68b5b"))
			"post":
				ci.draw_rect(Rect2(base + Vector2(-h * 0.03, -h), Vector2(h * 0.06, h)), Color("5a5a5a"))
				ci.draw_circle(base + Vector2(0, -h), h * 0.07, Color("fff2a8"))


static func _draw_chart(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var bars: Array = d.bars
	var from := _num(d, "from", 0.0)
	var to := _num(d, "to", 1.0)
	var step := _num(d, "step", 1.0)
	var mark := _int(d, "mark", -1)
	var fs := _fs(r, 0.09, 18)
	var title_h := fs * 1.5 if d.has("title") else 0.0
	if d.has("title"):
		SchoolPictureG4Arts._label(ci, font, Vector2(r.get_center().x, r.position.y + title_h * 0.45), str(d.title), fs)
	var axis_w := font.get_string_size(_num_text(to), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 8
	var plot := Rect2(r.position + Vector2(axis_w, title_h + fs * 0.5), Vector2(r.size.x - axis_w, r.size.y - title_h
		- fs * 2.2))
	var ticks := int(round((to - from) / step))
	var every := 1 if plot.size.y / ticks >= fs * 1.1 else 2   # crowded: a number on every other line
	for k in ticks + 1:
		var y := plot.end.y - plot.size.y * k / ticks
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID_LINE, 1.0)
		if k % every == 0:
			var t := _num_text(from + k * step)
			ci.draw_string(font, Vector2(r.position.x, y + fs * 0.35), t, HORIZONTAL_ALIGNMENT_RIGHT, axis_w - 6, fs, INK)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.0)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.0)
	var bw := plot.size.x / bars.size()
	for i in bars.size():
		var v := float(bars[i][1])
		var h := plot.size.y * (v - from) / (to - from)
		var box := Rect2(Vector2(plot.position.x + i * bw + bw * 0.18, plot.end.y - h), Vector2(bw * 0.64, h))
		ci.draw_rect(box, SHADE if i == mark else BLUE)
		var label := str(bars[i][0])
		SchoolPictureG4Arts._label(ci, font, Vector2(box.get_center().x, plot.end.y + fs * 0.9), label,
			SchoolPictureG4Arts._fit(font, label, fs, bw * 0.95))


static func _num_text(v: float) -> String:
	return str(int(round(v))) if absf(v - round(v)) < 0.001 else str(snappedf(v, 0.01))


static func _draw_sheet(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var cells: Array = d.cells
	var rows := cells.size()
	var cols := (cells[0] as Array).size()
	var formulas := str(d.get("show", "values")) == "formulas"
	var mark := str(d.get("mark", ""))
	var bar_h := r.size.y * 0.16 if mark != "" else 0.0
	var fs := clampi(int((r.size.y - bar_h) / (rows + 1) * 0.5), 9, 20)
	if mark != "":   # the formula bar: the marked cell and what is in it
		var bar := Rect2(r.position, Vector2(r.size.x, bar_h * 0.8))
		ci.draw_rect(bar, Color.WHITE)
		ci.draw_rect(bar, GRID_LINE, false, 1.5)
		var said := "%s   %s" % [mark, str(_cell_at(d, mark))]
		ci.draw_string(font, bar.position + Vector2(6, bar.size.y * 0.5 + fs * 0.35), said, HORIZONTAL_ALIGNMENT_LEFT,
			bar.size.x - 12, SchoolPictureG4Arts._fit(font, said, fs, bar.size.x - 12), INK)
	var head_w := r.size.x * 0.08
	var cw := (r.size.x - head_w) / cols
	var ch := (r.size.y - bar_h) / (rows + 1)
	var o := r.position + Vector2(0, bar_h)
	ci.draw_rect(Rect2(o, Vector2(r.size.x, ch)), Color("dfe6f2"))
	ci.draw_rect(Rect2(o, Vector2(head_w, ch * (rows + 1))), Color("dfe6f2"))
	for c in cols:
		SchoolPictureG4Arts._label(ci, font, o + Vector2(head_w + (c + 0.5) * cw, ch * 0.5), String.chr(65 + c), fs)
	for rr in rows:
		SchoolPictureG4Arts._label(ci, font, o + Vector2(head_w * 0.5, (rr + 1.5) * ch), str(rr + 1), fs)
		for c in cols:
			var box := Rect2(o + Vector2(head_w + c * cw, (rr + 1) * ch), Vector2(cw, ch))
			ci.draw_rect(box, Color.WHITE)
			var raw := str(cells[rr][c])
			var shown := raw
			var number := raw.is_valid_float()
			if raw.begins_with("=") and not formulas:
				shown = _num_text(value(d, _ref(c, rr)))
				number = true
			var size := SchoolPictureG4Arts._fit(font, shown, fs, cw - 8)
			ci.draw_string(font, box.position + Vector2(4, ch * 0.5 + size * 0.35), shown,
				HORIZONTAL_ALIGNMENT_RIGHT if number else HORIZONTAL_ALIGNMENT_LEFT, cw - 8, size, INK)
	for c in cols + 1:
		ci.draw_line(o + Vector2(head_w + c * cw, 0), o + Vector2(head_w + c * cw, ch * (rows + 1)), GRID_LINE, 1.0)
	for rr in rows + 2:
		ci.draw_line(o + Vector2(0, rr * ch), o + Vector2(r.size.x, rr * ch), GRID_LINE, 1.0)
	if mark != "":
		var mc := mark.unicode_at(0) - 65
		var mr := int(mark.substr(1)) - 1
		ci.draw_rect(Rect2(o + Vector2(head_w + mc * cw, (mr + 1) * ch), Vector2(cw, ch)), SHADE, false, 3.0)


static func _draw_chat(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var messages: Array = d.messages
	var mark := _int(d, "mark", -1)
	var name_h := 0.0
	var fs := clampi(int(r.size.y / (messages.size() + 1) * 0.42), 9, 20)
	if d.has("name"):
		name_h = fs * 1.4
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x, name_h)), Color("dfe6f2"))
		SchoolPictureG4Arts._label(ci, font, r.position + Vector2(r.size.x * 0.5, name_h * 0.5), str(d.name), fs)
	var mh := (r.size.y - name_h) / messages.size()
	for i in messages.size():
		var me := str(messages[i][0]) == "me"
		var text := str(messages[i][1])
		var size := SchoolPictureG4Arts._fit(font, text, fs, r.size.x * 0.74 - 16)
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 20
		var box := Rect2(Vector2(r.end.x - tw - 4 if me else r.position.x + 4, r.position.y + name_h + i * mh + mh * 0.12),
			Vector2(tw, mh * 0.76))
		SchoolPictureG4Arts._rounded(ci, box, BLUE if me else Color("e4e7ee"), mh * 0.3)
		if i == mark:
			var mb := StyleBoxFlat.new()
			mb.draw_center = false
			mb.set_border_width_all(3)
			mb.border_color = SHADE
			mb.set_corner_radius_all(int(mh * 0.3))
			ci.draw_style_box(mb, box.grow(2))
		ci.draw_string(font, box.position + Vector2(10, box.size.y * 0.5 + size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, size, Color.WHITE if me else INK)


static func _draw_access(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var ph := r.size.y
	var pw := minf(r.size.x * 0.9, ph * 1.6)
	var phone := Rect2(r.position + Vector2((r.size.x - pw) * 0.5, 0), Vector2(pw, ph))
	SchoolPictureG4Arts._rounded(ci, phone, Color("2b2f3a"), ph * 0.08)
	var screen := phone.grow(-ph * 0.06)
	var what := str(d.what)
	ci.draw_rect(screen, Color("111111") if what == "high_contrast" else Color.WHITE)
	var fs := clampi(int(screen.size.y * 0.13), 9, 22)
	match what:
		"captions":
			ci.draw_rect(screen, SKY)
			ci.draw_rect(Rect2(Vector2(screen.position.x, screen.position.y + screen.size.y * 0.6), Vector2(screen.size.x,
				screen.size.y * 0.4)), GRASS)
			var fc := screen.position + Vector2(screen.size.x * 0.5, screen.size.y * 0.4)
			ci.draw_circle(fc, screen.size.y * 0.16, Color("f2c9a0"))
			ci.draw_circle(fc + Vector2(-screen.size.y * 0.05, -screen.size.y * 0.02), 2.5, INK)
			ci.draw_circle(fc + Vector2(screen.size.y * 0.05, -screen.size.y * 0.02), 2.5, INK)
			ci.draw_arc(fc + Vector2(0, screen.size.y * 0.03), screen.size.y * 0.06, 0.3, PI - 0.3, 8, INK, 2.0)
			var cap := Rect2(Vector2(screen.position.x + screen.size.x * 0.08, screen.end.y - screen.size.y * 0.3),
				Vector2(screen.size.x * 0.84, screen.size.y * 0.22))
			ci.draw_rect(cap, Color(0, 0, 0, 0.8))
			var said := "Hello! Let's build a boat."
			SchoolPictureG4Arts._label(ci, font, cap.get_center(), said, SchoolPictureG4Arts._fit(font, said, fs,
				cap.size.x - 8), Color.WHITE)
		"read_aloud":
			for k in 4:
				ci.draw_rect(Rect2(screen.position + Vector2(screen.size.x * 0.06, screen.size.y * (0.14 + k * 0.18)),
					Vector2(screen.size.x * (0.5 if k == 3 else 0.62), screen.size.y * 0.07)), Color("c3c9d6"))
			var sp := screen.position + Vector2(screen.size.x * 0.8, screen.size.y * 0.5)
			var s := screen.size.y * 0.12
			ci.draw_colored_polygon(PackedVector2Array([sp + Vector2(-s, -s * 0.5), sp + Vector2(-s * 0.4, -s * 0.5),
				sp + Vector2(0, -s), sp + Vector2(0, s), sp + Vector2(-s * 0.4, s * 0.5), sp + Vector2(-s, s * 0.5)]), BLUE)
			for k in 3:
				ci.draw_arc(sp, s * (0.7 + k * 0.45), -0.7, 0.7, 10, BLUE, 2.5)
		"big_text":
			ci.draw_string(font, screen.position + Vector2(screen.size.x * 0.08, screen.size.y * 0.35), "Aa",
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 0.8), INK)
			ci.draw_string(font, screen.position + Vector2(screen.size.x * 0.4, screen.size.y * 0.58), "Aa",
				HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 2.6), INK)
			var y := screen.position.y + screen.size.y * 0.8
			ci.draw_line(Vector2(screen.position.x + screen.size.x * 0.1, y), Vector2(screen.end.x - screen.size.x * 0.1, y),
				GRID_LINE, 4.0)
			ci.draw_circle(Vector2(screen.position.x + screen.size.x * 0.72, y), screen.size.y * 0.06, BLUE)
		"high_contrast":
			for k in 3:
				ci.draw_rect(Rect2(screen.position + Vector2(screen.size.x * 0.08, screen.size.y * (0.16 + k * 0.24)),
					Vector2(screen.size.x * (0.84 - k * 0.12), screen.size.y * 0.12)), Color("ffe600"))
			ci.draw_rect(screen.grow(-3), Color.WHITE, false, 2.0)
		"voice":
			var m := screen.position + Vector2(screen.size.x * 0.25, screen.size.y * 0.5)
			var s := screen.size.y * 0.16
			SchoolPictureG4Arts._rounded(ci, Rect2(m - Vector2(s * 0.45, s * 1.1), Vector2(s * 0.9, s * 1.5)), BLUE, s * 0.45)
			ci.draw_arc(m + Vector2(0, -s * 0.1), s * 0.75, 0.2, PI - 0.2, 12, BLUE, 2.5)
			ci.draw_line(m + Vector2(0, s * 0.65), m + Vector2(0, s * 1.1), BLUE, 2.5)
			var bubble := Rect2(screen.position + Vector2(screen.size.x * 0.45, screen.size.y * 0.3),
				Vector2(screen.size.x * 0.5, screen.size.y * 0.3))
			SchoolPictureG4Arts._rounded(ci, bubble, Color("e4e7ee"), 8)
			SchoolPictureG4Arts._label(ci, font, bubble.get_center(), "Open the map",
				SchoolPictureG4Arts._fit(font, "Open the map", fs, bubble.size.x - 8))
		"alt_text":
			var pic := Rect2(screen.position + Vector2(screen.size.x * 0.1, screen.size.y * 0.06),
				Vector2(screen.size.x * 0.8, screen.size.y * 0.5))
			ci.draw_rect(pic, SKY)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(pic.position.x, pic.end.y), pic.position + Vector2(pic.size.x
				* 0.35, pic.size.y * 0.3), Vector2(pic.position.x + pic.size.x * 0.7, pic.end.y)]), Color("7c8a9c"))
			ci.draw_rect(Rect2(pic.position + Vector2(pic.size.x * 0.55, pic.size.y * 0.72), Vector2(pic.size.x * 0.3,
				pic.size.y * 0.14)), Color("e03a2f"))
			var alt := "Picture: a red boat on a lake"
			var box := Rect2(Vector2(pic.position.x, pic.end.y + screen.size.y * 0.08), Vector2(pic.size.x,
				screen.size.y * 0.26))
			SchoolPictureG4Arts._rounded(ci, box, Color("fff4d6"), 6)
			SchoolPictureG4Arts._label(ci, font, box.get_center(), alt, SchoolPictureG4Arts._fit(font, alt, fs,
				box.size.x - 8))


# --- art ---------------------------------------------------------------------------------------------------------------

static func _draw_perspective(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var scene := str(d.scene)
	var hy := r.position.y + r.size.y * (0.42 if scene != "room" else 0.45)
	var vp := Vector2(r.position.x + r.size.x * _num(d, "vp", 0.5), hy)
	var lines := bool(d.get("lines", false))
	var dash := Color(0.9, 0.3, 0.1, 0.8)
	match scene:
		"road", "rails":
			ci.draw_rect(Rect2(r.position, Vector2(r.size.x, hy - r.position.y)), SKY)
			ci.draw_rect(Rect2(Vector2(r.position.x, hy), Vector2(r.size.x, r.end.y - hy)), GRASS)
			var bl := Vector2(r.position.x + r.size.x * (0.18 if scene == "road" else 0.3), r.end.y)
			var br := Vector2(r.position.x + r.size.x * (0.82 if scene == "road" else 0.7), r.end.y)
			if scene == "road":
				ci.draw_colored_polygon(PackedVector2Array([bl, br, vp]), Color("8a8a8a"))
				for k in 7:   # the centre line's dashes: shorter and closer further away
					var a := _toward(Vector2((bl.x + br.x) * 0.5, r.end.y), vp, 1.0 - 1.0 / (1.0 + k * 0.55))
					var b := _toward(Vector2((bl.x + br.x) * 0.5, r.end.y), vp, 1.0 - 1.0 / (1.0 + k * 0.55 + 0.25))
					ci.draw_line(a, b, Color.WHITE, maxf(1.0, 6.0 / (1.0 + k * 0.6)))
			else:
				for k in 10:   # sleepers
					var t := 1.0 - 1.0 / (1.0 + k * 0.45)
					var a := _toward(bl + Vector2(-r.size.x * 0.05, 0), vp, t)
					var b := _toward(br + Vector2(r.size.x * 0.05, 0), vp, t)
					ci.draw_line(a, b, Color("7a4a24"), maxf(1.5, 7.0 / (1.0 + k * 0.5)))
				ci.draw_line(bl, vp, Color("5a5a5a"), 3.0)
				ci.draw_line(br, vp, Color("5a5a5a"), 3.0)
			for k in 5:   # posts or trees beside it, smaller as they go back
				var t := 1.0 - 1.0 / (1.0 + k * 0.7)
				var foot := _toward(Vector2(r.position.x + r.size.x * 0.06, r.end.y - r.size.y * 0.04), vp, t)
				var hh := r.size.y * 0.42 * (1.0 - t)
				if scene == "road":
					ci.draw_rect(Rect2(foot + Vector2(-hh * 0.05, -hh * 0.55), Vector2(hh * 0.1, hh * 0.55)), Color("7a4a24"))
					ci.draw_circle(foot + Vector2(0, -hh * 0.75), hh * 0.28, Color("2f8a3a"))
				else:
					ci.draw_line(foot, foot + Vector2(0, -hh), Color("5a3a24"), maxf(1.5, hh * 0.06))
					ci.draw_line(foot + Vector2(-hh * 0.15, -hh * 0.9), foot + Vector2(hh * 0.15, -hh * 0.9), Color("5a3a24"),
						maxf(1.0, hh * 0.04))
				if lines and k == 0:
					ci.draw_dashed_line(foot + Vector2(0, -hh), vp, dash, 1.5, 6.0)
					ci.draw_dashed_line(foot, vp, dash, 1.5, 6.0)
			if lines:
				ci.draw_dashed_line(bl, vp, dash, 1.5, 6.0)
				ci.draw_dashed_line(br, vp, dash, 1.5, 6.0)
		"room":
			var k_back := 0.36   # the back wall: the frame shrunk towards the vanishing point, so every edge meets there
			var back := Rect2(vp + (r.position - vp) * k_back, r.size * k_back)
			var tl := r.position
			var tr := Vector2(r.end.x, r.position.y)
			var bl := Vector2(r.position.x, r.end.y)
			var brr := r.end
			ci.draw_colored_polygon(PackedVector2Array([tl, tr, Vector2(back.end.x, back.position.y), back.position]),
				Color("f4efe4"))
			ci.draw_colored_polygon(PackedVector2Array([bl, brr, back.end, Vector2(back.position.x, back.end.y)]),
				Color("c9a36b"))
			ci.draw_colored_polygon(PackedVector2Array([tl, back.position, Vector2(back.position.x, back.end.y), bl]),
				Color("e3d6bd"))
			ci.draw_colored_polygon(PackedVector2Array([tr, brr, back.end, Vector2(back.end.x, back.position.y)]),
				Color("dccbaa"))
			ci.draw_rect(back, Color("efe6d2"))
			ci.draw_rect(back, INK, false, 1.5)
			ci.draw_rect(Rect2(back.position + Vector2(back.size.x * 0.38, back.size.y * 0.35), Vector2(back.size.x * 0.24,
				back.size.y * 0.65)), Color("8a5a3a"))
			for k in 5:   # floorboards to the vanishing point
				var x := bl.x + (brr.x - bl.x) * (k + 1) / 6.0
				ci.draw_line(Vector2(x, r.end.y), _toward(Vector2(x, r.end.y), vp, 1.0 - k_back), Color("9a7a4a"), 1.2)
			var w0 := _toward(tl + Vector2(0, r.size.y * 0.3), vp, 0.25)   # a window on the left wall
			var w1 := _toward(tl + Vector2(0, r.size.y * 0.3), vp, 0.6)
			var w2 := _toward(tl + Vector2(0, r.size.y * 0.62), vp, 0.6)
			var w3 := _toward(tl + Vector2(0, r.size.y * 0.62), vp, 0.25)
			ci.draw_colored_polygon(PackedVector2Array([w0, w1, w2, w3]), SKY)
			ci.draw_polyline(PackedVector2Array([w0, w1, w2, w3, w0]), INK, 1.5)
			for c: Vector2 in [tl, tr, bl, brr]:
				ci.draw_line(c, _toward(c, vp, 1.0 - k_back), INK, 1.5)
				if lines:
					ci.draw_dashed_line(c, vp, dash, 1.5, 6.0)
	var fs := _fs(r, 0.09, 18)
	var mark := str(d.get("mark", ""))
	if scene != "room" or mark == "horizon" or bool(d.get("labels", false)):
		ci.draw_line(Vector2(r.position.x, hy), Vector2(r.end.x, hy), SHADE if mark == "horizon" else INK,
			maxf(4.0, r.size.y * 0.025) if mark == "horizon" else 1.2)
	if mark == "vanishing point" or bool(d.get("labels", false)):
		ci.draw_circle(vp, 6.0, SHADE)
		ci.draw_arc(vp, 11.0, 0, TAU, 20, SHADE, 2.0)
	if bool(d.get("labels", false)):
		var lx := r.position.x + r.size.x * (0.84 if scene == "room" else 0.16)
		SchoolPictureG4Arts._label(ci, font, Vector2(lx, hy - fs * 0.8), "horizon line", fs)
		SchoolPictureG4Arts._label(ci, font, vp + Vector2(0, -fs * 1.4), "vanishing point", fs)


static func _toward(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a + (b - a) * t


static func _draw_columns(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var orders: Array = d.orders
	var n := orders.size()
	var labels := bool(d.get("labels", false))
	var mark := _int(d, "mark", -1)
	var fs := _fs(r, 0.1, 20)
	var lab_h := fs * 1.4 if labels else 0.0
	var slot := r.size.x / n
	var h := r.size.y - lab_h
	var w := minf(slot * 0.34, h * 0.2)
	for i in n:
		var cx := r.position.x + slot * (i + 0.5)
		var order := str(orders[i])
		var cap_h := h * (0.12 if order == "doric" else (0.13 if order == "ionic" else 0.2))
		var base_h := 0.0 if order == "doric" else h * 0.06
		var top := r.position.y + h * 0.04
		var abacus := Rect2(Vector2(cx - w * 0.75, top), Vector2(w * 1.5, h * 0.04))
		var shaft := Rect2(Vector2(cx - w * 0.5, top + h * 0.04 + cap_h), Vector2(w, h * 0.92 - cap_h - base_h - h * 0.04))
		ci.draw_rect(shaft, STONE)
		for k in 5:   # flutes
			var x := shaft.position.x + shaft.size.x * (k + 1) / 6.0
			ci.draw_line(Vector2(x, shaft.position.y + 2), Vector2(x, shaft.end.y - 2), STONE_DARK, 1.2)
		ci.draw_rect(Rect2(Vector2(cx - w * 0.8, r.position.y + h * 0.96), Vector2(w * 1.6, h * 0.04)), STONE_DARK)
		if base_h > 0.0:   # a base of two rings (Ionic and Corinthian)
			ci.draw_rect(Rect2(Vector2(cx - w * 0.62, shaft.end.y), Vector2(w * 1.24, base_h * 0.5)), STONE)
			ci.draw_rect(Rect2(Vector2(cx - w * 0.7, shaft.end.y + base_h * 0.5), Vector2(w * 1.4, base_h * 0.5)), STONE)
			ci.draw_rect(Rect2(Vector2(cx - w * 0.7, shaft.end.y), Vector2(w * 1.4, base_h)), STONE_DARK, false, 1.0)
		var cap_top := top + h * 0.04
		match order:
			"doric":   # a plain cushion under a square slab
				ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.72, cap_top), Vector2(cx + w * 0.72, cap_top),
					Vector2(cx + w * 0.5, cap_top + cap_h), Vector2(cx - w * 0.5, cap_top + cap_h)]), STONE)
			"ionic":   # two scrolls
				ci.draw_rect(Rect2(Vector2(cx - w * 0.7, cap_top), Vector2(w * 1.4, cap_h * 0.45)), STONE)
				for sgn: float in [-1.0, 1.0]:
					var c := Vector2(cx + sgn * w * 0.62, cap_top + cap_h * 0.5)
					var pts := PackedVector2Array()
					for k in 40:
						var a := k * 0.35 * sgn
						var rad := cap_h * 0.5 * (1.0 - k / 44.0)
						pts.append(c + Vector2(cos(a), sin(a)) * rad)
					ci.draw_polyline(pts, INK, 1.5, true)
			"corinthian":   # a bell of leaves with small scrolls at the corners
				ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - w * 0.7, cap_top), Vector2(cx + w * 0.7, cap_top),
					Vector2(cx + w * 0.5, cap_top + cap_h), Vector2(cx - w * 0.5, cap_top + cap_h)]), STONE)
				for row in 2:
					for k in 4:
						var lx := cx - w * 0.45 + w * 0.3 * k
						var ly := cap_top + cap_h * (0.95 - row * 0.42)
						ci.draw_colored_polygon(PackedVector2Array([Vector2(lx - w * 0.12, ly), Vector2(lx, ly - cap_h * 0.5),
							Vector2(lx + w * 0.12, ly)]), Color("a9b98a"))
				for sgn: float in [-1.0, 1.0]:
					ci.draw_arc(Vector2(cx + sgn * w * 0.62, cap_top + cap_h * 0.15), cap_h * 0.14, 0, TAU, 12, INK, 1.2)
		ci.draw_rect(abacus, STONE)
		ci.draw_rect(Rect2(abacus.position, Vector2(abacus.size.x, cap_top + cap_h - abacus.position.y)), STONE_DARK,
			false, 1.0)
		if i == mark:
			ci.draw_rect(Rect2(Vector2(cx - w * 0.95, top - 4), Vector2(w * 1.9, cap_h + h * 0.04 + 8)), SHADE, false, 3.0)
		if labels:
			SchoolPictureG4Arts._label(ci, font, Vector2(cx, r.end.y - lab_h * 0.5), order.capitalize(),
				SchoolPictureG4Arts._fit(font, order.capitalize(), fs, slot - 4))


static func _draw_vase(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var black := str(d.style) == "black-figure"
	var body_col := CLAY if black else GLAZE
	var fig_col := GLAZE if black else CLAY
	var h := r.size.y
	var cx := r.get_center().x
	var w := h * 0.62
	# the amphora's side, top to bottom (x from the middle, y down)
	var side: Array[Vector2] = [Vector2(0.2, 0.0), Vector2(0.17, 0.08), Vector2(0.15, 0.2), Vector2(0.3, 0.3),
		Vector2(0.44, 0.45), Vector2(0.45, 0.58), Vector2(0.36, 0.75), Vector2(0.2, 0.88), Vector2(0.14, 0.92),
		Vector2(0.24, 1.0)]
	var pts := PackedVector2Array()
	for p in side:
		pts.append(Vector2(cx + p.x * w, r.position.y + p.y * h))
	for i in range(side.size() - 1, -1, -1):
		pts.append(Vector2(cx - side[i].x * w, r.position.y + side[i].y * h))
	ci.draw_colored_polygon(pts, body_col)
	for sgn: float in [-1.0, 1.0]:   # handles
		ci.draw_polyline(PackedVector2Array([Vector2(cx + sgn * 0.16 * w, r.position.y + 0.1 * h),
			Vector2(cx + sgn * 0.34 * w, r.position.y + 0.1 * h), Vector2(cx + sgn * 0.36 * w, r.position.y + 0.24 * h),
			Vector2(cx + sgn * 0.3 * w, r.position.y + 0.3 * h)]), body_col, maxf(3.0, h * 0.03))
	var band := Color(0.95, 0.85, 0.7) if not black else GLAZE
	for y: float in [0.33, 0.78]:   # bands with a key pattern
		var y0 := r.position.y + y * h
		var half := (0.33 if y < 0.5 else 0.3) * w
		ci.draw_line(Vector2(cx - half, y0), Vector2(cx + half, y0), band, 1.5)
		var x := cx - half
		while x < cx + half - h * 0.04:
			ci.draw_polyline(PackedVector2Array([Vector2(x, y0 + h * 0.03), Vector2(x, y0 + h * 0.008),
				Vector2(x + h * 0.025, y0 + h * 0.008), Vector2(x + h * 0.025, y0 + h * 0.022)]), band, 1.2)
			x += h * 0.04
	# a running figure in the middle panel
	var c := Vector2(cx, r.position.y + 0.56 * h)
	var s := h * 0.1
	ci.draw_circle(c + Vector2(s * 0.3, -s * 1.5), s * 0.34, fig_col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * 1.1), c + Vector2(s * 0.6, -s * 1.1),
		c + Vector2(s * 0.3, s * 0.2), c + Vector2(-s * 0.3, s * 0.2)]), fig_col)
	for leg: Array in [[Vector2(0, s * 0.2), Vector2(-s * 0.8, s * 1.0), Vector2(-s * 1.1, s * 1.5)],
			[Vector2(0, s * 0.2), Vector2(s * 0.7, s * 0.8), Vector2(s * 0.5, s * 1.5)],
			[Vector2(s * 0.3, -s * 0.9), Vector2(s * 1.0, -s * 0.5), Vector2(s * 1.3, -s * 1.0)],
			[Vector2(0, -s * 0.9), Vector2(-s * 0.7, -s * 0.6), Vector2(-s * 1.0, -s * 1.1)]]:
		ci.draw_polyline(PackedVector2Array([c + leg[0], c + leg[1], c + leg[2]]), fig_col, maxf(2.0, s * 0.22))
	if not black:   # red figures: their details are painted in thin black lines
		ci.draw_line(c + Vector2(0, -s * 0.8), c + Vector2(s * 0.4, -s * 0.2), GLAZE, 1.2)


static func _draw_mosaic(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var key: Dictionary = d.key
	var h := rows.size()
	var w := str(rows[0]).length()
	var cell := minf(r.size.x / w, r.size.y / h)
	var o := r.position + (r.size - Vector2(w, h) * cell) * 0.5
	var grout := bool(d.get("grout", true))
	ci.draw_rect(Rect2(o, Vector2(w, h) * cell), Color("d8d2c4") if grout else Color.WHITE)
	var gap := cell * 0.12 if grout else 0.0
	for y in h:
		for x in w:
			var ch := str(rows[y])[x]
			if ch == ".":
				continue
			var col: Color = SchoolPictureArts.COLOURS[str(key[ch])]
			var j := Vector2(float((x * 7 + y * 13) % 5 - 2), float((x * 11 + y * 3) % 5 - 2)) * cell * 0.012 \
				if grout else Vector2.ZERO   # hand-set tiles sit a little unevenly
			var tile := Rect2(o + Vector2(x, y) * cell + Vector2(gap, gap) * 0.5 + j, Vector2(cell - gap, cell - gap))
			ci.draw_rect(tile, col.lerp(Color.WHITE, 0.1) if grout and (x + y) % 3 == 0 else col)


static func _draw_building(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var what := str(d.what)
	var ground := r.position.y + r.size.y * 0.9
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, ground - r.position.y)), SKY)
	ci.draw_rect(Rect2(Vector2(r.position.x, ground), Vector2(r.size.x, r.end.y - ground)),
		Color("e3c58a") if what == "pyramid" else Color("9fbf7a"))
	var cx := r.get_center().x
	var h := ground - r.position.y
	var u := minf(r.size.x / 10.0, h / 6.0)   # one unit of the drawing
	match what:
		"pyramid":
			for k: Array in [[cx + u * 2.6, u * 3.0, 0.75], [cx - u * 0.6, u * 4.6, 1.0]]:
				var peak := Vector2(float(k[0]), ground - float(k[1]))
				var half := float(k[1]) * 1.05
				ci.draw_colored_polygon(PackedVector2Array([Vector2(peak.x - half, ground), peak,
					Vector2(peak.x + half, ground)]), Color("d9b36a").darkened(0.12 * (1.0 - float(k[2]))))
				ci.draw_colored_polygon(PackedVector2Array([peak, Vector2(peak.x + half, ground), Vector2(peak.x + half * 0.2,
					ground)]), Color("b8924f"))
				for s in 6:
					var y := ground - float(k[1]) * s / 6.0
					var ww := half * (1.0 - float(s) / 6.0)
					ci.draw_line(Vector2(peak.x - ww, y), Vector2(peak.x + ww, y), Color(0.5, 0.4, 0.2, 0.4), 1.0)
		"parthenon":
			_temple_front(ci, Rect2(Vector2(cx - u * 4.2, ground - u * 4.4), Vector2(u * 8.4, u * 4.4)), 8)
		"pantheon":
			var drum := Rect2(Vector2(cx - u * 3.4, ground - u * 3.0), Vector2(u * 6.8, u * 3.0))
			SchoolPictureG4Arts._ellipse(ci, Vector2(cx, drum.position.y), Vector2(u * 3.2, u * 1.5), Color("c9c0ac"))
			ci.draw_rect(drum, STONE_DARK)
			ci.draw_rect(Rect2(Vector2(cx - u * 0.4, drum.position.y - u * 1.55), Vector2(u * 0.8, u * 0.18)), SKY)
			_temple_front(ci, Rect2(Vector2(cx - u * 2.4, ground - u * 3.2), Vector2(u * 4.8, u * 3.2)), 6)
		"aqueduct":
			var top := ground - u * 5.0
			var body := Rect2(Vector2(r.position.x, top), Vector2(r.size.x, u * 5.0))
			ci.draw_rect(body, Color("c9a77a"))
			for tier in 2:
				var ty := top + u * 0.4 + tier * u * 2.3
				var arch_h := u * (1.9 if tier == 0 else 2.3)
				var n := 5 if tier == 0 else 4
				var span := r.size.x / n
				for k in n:
					var ax := r.position.x + span * (k + 0.5)
					_arch_hole(ci, Vector2(ax, ty + arch_h), span * 0.36, arch_h, SKY, false)
			ci.draw_rect(Rect2(Vector2(r.position.x, top - u * 0.3), Vector2(r.size.x, u * 0.3)), Color("b08f62"))
		"cathedral":
			var body := Rect2(Vector2(cx - u * 3.4, ground - u * 3.6), Vector2(u * 6.8, u * 3.6))
			ci.draw_rect(body, Color("cfc6b4"))
			for sgn: float in [-1.0, 1.0]:
				var tower := Rect2(Vector2(cx + sgn * u * 2.6 - u * 0.9, ground - u * 4.8), Vector2(u * 1.8, u * 4.8))
				ci.draw_rect(tower, Color("c4bba8"))
				ci.draw_colored_polygon(PackedVector2Array([tower.position, Vector2(tower.get_center().x, tower.position.y
					- u * 1.2), Vector2(tower.end.x, tower.position.y)]), Color("8a8272"))
				_arch_hole(ci, Vector2(tower.get_center().x, tower.position.y + u * 2.4), u * 0.35, u * 1.2, Color("3a3f5a"), true)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(body.position.x + u * 1.7, body.position.y),
				Vector2(cx, body.position.y - u * 1.3), Vector2(body.end.x - u * 1.7, body.position.y)]), Color("c4bba8"))
			ci.draw_circle(Vector2(cx, body.position.y + u * 1.0), u * 0.75, Color("3a5fb0"))
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_line(Vector2(cx, body.position.y + u), Vector2(cx, body.position.y + u) + Vector2(cos(a), sin(a)) *
					u * 0.75, Color("e8d890"), 1.5)
			_arch_hole(ci, Vector2(cx, ground), u * 0.8, u * 1.9, Color("5a3a24"), true)
		"taj_mahal":
			ci.draw_rect(Rect2(Vector2(cx - u * 4.4, ground - u * 0.5), Vector2(u * 8.8, u * 0.5)), Color("f2efe8"))
			var body := Rect2(Vector2(cx - u * 2.4, ground - u * 2.9), Vector2(u * 4.8, u * 2.4))
			ci.draw_rect(body, Color("f7f4ee"))
			_arch_hole(ci, Vector2(cx, body.end.y - u * 0.1), u * 0.8, u * 2.0, Color("d8d2c4"), true)
			ci.draw_rect(Rect2(Vector2(cx - u * 1.0, body.position.y - u * 0.8), Vector2(u * 2.0, u * 0.8)), Color("efebe2"))
			var dome_c := Vector2(cx, body.position.y - u * 0.35)
			var bulb := PackedVector2Array()
			for k in 25:   # an onion dome: wide in its middle, pointed at the top
				var t := PI * k / 24.0
				var rx := u * 1.45 * sin(t) * (1.0 + 0.25 * sin(t))
				var yy := -u * 1.2 * (1.0 - cos(t)) - u * 0.9 * pow(maxf(0.0, t / PI - 0.55), 2.0) * 4.0
				bulb.append(dome_c + Vector2(-rx, yy))
			for k in range(24, -1, -1):
				var t := PI * k / 24.0
				var rx := u * 1.45 * sin(t) * (1.0 + 0.25 * sin(t))
				var yy := -u * 1.2 * (1.0 - cos(t)) - u * 0.9 * pow(maxf(0.0, t / PI - 0.55), 2.0) * 4.0
				bulb.append(dome_c + Vector2(rx, yy))
			ci.draw_colored_polygon(bulb, Color("f7f4ee"))
			ci.draw_polyline(bulb, Color("c9c2b2"), 1.0)
			for sgn: float in [-1.0, 1.0]:
				for x: float in [4.0, 2.9]:
					var mx := cx + sgn * u * x
					var mh := u * (4.0 if x == 4.0 else 1.2)
					var base_y := ground - u * 0.5 if x == 4.0 else body.position.y
					ci.draw_rect(Rect2(Vector2(mx - u * 0.18, base_y - mh), Vector2(u * 0.36, mh)), Color("f2efe8"))
					ci.draw_circle(Vector2(mx, base_y - mh), u * 0.28, Color("f2efe8"))
		"pagoda":
			var floors := 5
			var fh := h * 0.78 / floors
			for k in floors:
				var wk := u * (3.4 - k * 0.45)
				var y := ground - (k + 1) * fh
				ci.draw_rect(Rect2(Vector2(cx - wk * 0.6, y + fh * 0.3), Vector2(wk * 1.2, fh * 0.7)), Color("b8322a"))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - wk * 1.05, y + fh * 0.4), Vector2(cx - wk * 0.75,
					y + fh * 0.28), Vector2(cx - wk * 0.5, y), Vector2(cx + wk * 0.5, y), Vector2(cx + wk * 0.75,
					y + fh * 0.28), Vector2(cx + wk * 1.05, y + fh * 0.4)]), Color("3d4a3a"))
			ci.draw_line(Vector2(cx, ground - floors * fh), Vector2(cx, ground - floors * fh - u * 0.9), Color("c9a33a"), 3.0)
		"skyscraper":
			for k: Array in [[-3.2, 2.6, 1.6], [2.8, 3.2, 1.8], [0.0, 5.2, 2.0]]:
				var tw := u * float(k[2])
				var th := u * float(k[1])
				var box := Rect2(Vector2(cx + u * float(k[0]) - tw * 0.5, ground - th), Vector2(tw, th))
				ci.draw_rect(box, Color("7d8ea8") if float(k[0]) != 0.0 else Color("5f7596"))
				var rows := int(th / (u * 0.4))
				for rr in rows:
					for c in 3:
						ci.draw_rect(Rect2(box.position + Vector2(tw * (0.12 + c * 0.3), u * 0.15 + rr * u * 0.4),
							Vector2(tw * 0.18, u * 0.2)), Color("cfe3f7"))
			ci.draw_line(Vector2(cx, ground - u * 5.2), Vector2(cx, ground - u * 5.9), Color("5f7596"), 2.5)
		"lintel":
			for sgn: float in [-1.0, 1.0]:
				ci.draw_rect(Rect2(Vector2(cx + sgn * u * 2.2 - u * 0.6, ground - u * 4.0), Vector2(u * 1.2, u * 4.0)), STONE)
				ci.draw_rect(Rect2(Vector2(cx + sgn * u * 2.2 - u * 0.6, ground - u * 4.0), Vector2(u * 1.2, u * 4.0)),
					STONE_DARK, false, 1.5)
			var beam := Rect2(Vector2(cx - u * 3.2, ground - u * 5.0), Vector2(u * 6.4, u * 1.0))
			ci.draw_rect(beam, STONE)
			ci.draw_rect(beam, STONE_DARK, false, 1.5)
		"round_arch", "pointed_arch":
			var pointed := what == "pointed_arch"
			ci.draw_rect(Rect2(Vector2(cx - u * 3.6, ground - u * 5.2), Vector2(u * 7.2, u * 5.2)), STONE)
			var half := u * 1.8
			var height := u * (3.9 if pointed else 3.3)
			var spring := height - (half * sqrt(3.0) if pointed else half)
			var foot := Vector2(cx, ground)
			var inner := _arch_points(foot, half, spring, pointed, 0.0)
			var outer := _arch_points(foot, half, spring, pointed, u * 0.9)
			var ring := PackedVector2Array(outer)
			for k in range(inner.size() - 1, -1, -1):
				ring.append(inner[k])
			ci.draw_colored_polygon(ring, Color("d9c9a0"))   # the ring of wedge stones
			_arch_hole(ci, foot, half, height, SKY, pointed)
			for k in range(0, inner.size(), 3):   # the joints between the wedge stones
				ci.draw_line(inner[k], outer[k], STONE_DARK, 1.5)
			if not pointed:   # the keystone at the top
				var mid := inner.size() / 2
				ci.draw_line(inner[mid - 1], outer[mid - 1], INK, 2.0)
				ci.draw_line(inner[mid + 1], outer[mid + 1], INK, 2.0)


## A temple's front: steps, columns, the beam and the triangular pediment.
static func _temple_front(ci: CanvasItem, box: Rect2, columns: int) -> void:
	var step_h := box.size.y * 0.06
	for k in 3:
		ci.draw_rect(Rect2(Vector2(box.position.x - k * step_h * 0.5, box.end.y - (k + 1) * step_h), Vector2(box.size.x
			+ k * step_h, step_h)), STONE.darkened(0.05 * k))
	var col_top := box.position.y + box.size.y * 0.36
	var col_bottom := box.end.y - step_h * 3
	var span := box.size.x / columns
	for k in columns:
		var x := box.position.x + span * (k + 0.5)
		ci.draw_rect(Rect2(Vector2(x - span * 0.22, col_top), Vector2(span * 0.44, col_bottom - col_top)), STONE)
		ci.draw_line(Vector2(x, col_top), Vector2(x, col_bottom), STONE_DARK, 1.0)
	ci.draw_rect(Rect2(Vector2(box.position.x, col_top - box.size.y * 0.1), Vector2(box.size.x, box.size.y * 0.1)), STONE)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(box.position.x - 2, col_top - box.size.y * 0.1),
		Vector2(box.get_center().x, box.position.y), Vector2(box.end.x + 2, col_top - box.size.y * 0.1)]), STONE)
	ci.draw_polyline(PackedVector2Array([Vector2(box.position.x - 2, col_top - box.size.y * 0.1),
		Vector2(box.get_center().x, box.position.y), Vector2(box.end.x + 2, col_top - box.size.y * 0.1),
		Vector2(box.position.x - 2, col_top - box.size.y * 0.1)]), STONE_DARK, 1.5)


## An arch's opening from the ground at `foot` (its middle): `half` wide each side, `height` to its top; round (a half
## circle) or pointed (two arcs of twice the half-width, each centred on the other side, meeting at the top).
static func _arch_hole(ci: CanvasItem, foot: Vector2, half: float, height: float, col: Color, pointed: bool) -> void:
	var spring := height - (half * sqrt(3.0) if pointed else half)
	var pts := PackedVector2Array([foot + Vector2(-half, 0)])
	pts.append_array(_arch_points(foot, half, spring, pointed, 0.0))
	pts.append(foot + Vector2(half, 0))
	ci.draw_colored_polygon(pts, col)


## The arch's curve from its left springing point (`spring` above the foot) over the top to its right one; `grow`
## further out for the ring of stones round it.
static func _arch_points(foot: Vector2, half: float, spring: float, pointed: bool, grow: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if pointed:
		var rad := 2.0 * half + grow
		for k in 13:   # the left arc, centred on the right springing point
			var a := lerpf(PI, acos(-half / rad), k / 12.0)
			pts.append(foot + Vector2(half + cos(a) * rad, -spring - sin(a) * rad))
		for k in range(1, 13):   # the right arc, centred on the left one
			var a := lerpf(acos(half / rad), 0.0, k / 12.0)
			pts.append(foot + Vector2(-half + cos(a) * rad, -spring - sin(a) * rad))
	else:
		var rad := half + grow
		for k in 25:
			var a := PI - PI * k / 24.0
			pts.append(foot + Vector2(cos(a) * rad, -spring - sin(a) * rad))
	return pts


static func _draw_still_life(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var objects: Array = d.objects
	var left := str(d.light) == "left"
	var shade := bool(d.get("shade", true))
	var table_y := r.position.y + r.size.y * 0.72
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, table_y - r.position.y)), Color("efe6d2"))
	ci.draw_rect(Rect2(Vector2(r.position.x, table_y), Vector2(r.size.x, r.end.y - table_y)), Color("b98a5a"))
	var n := objects.size()
	var slot := r.size.x * 0.8 / n
	var u := minf(slot * 0.55, r.size.y * 0.36)
	var lit := Vector2(-1.0 if left else 1.0, -0.8).normalized()   # towards the light
	var fs := _fs(r, 0.08, 16)
	for i in n:
		var foot := Vector2(r.position.x + r.size.x * 0.1 + slot * (i + 0.5), table_y + r.size.y * 0.06 + (i % 2) * u * 0.12)
		var what := str(objects[i])
		var base: Color = {"apple": Color("d63a2f"), "pear": Color("b5c43a"), "lemon": Color("f2d22e"),
			"jug": Color("5b8fd6"), "bowl": Color("efe2c0"), "bottle": Color("3f9a5a"), "cup": Color("f4f4f0")}[what]
		var size: Vector2 = Vector2(u, u) * {"apple": Vector2(0.9, 0.85), "pear": Vector2(0.8, 1.1), "lemon": Vector2(1.0, 0.7),
			"jug": Vector2(0.9, 1.6), "bowl": Vector2(1.4, 0.6), "bottle": Vector2(0.55, 1.9), "cup": Vector2(0.7, 0.7)}[what]
		var centre := foot - Vector2(0, size.y * 0.5)
		if shade:   # the cast shadow on the table, away from the light
			SchoolPictureG4Arts._ellipse(ci, foot + Vector2(-lit.x * size.x * 0.6, 0), Vector2(size.x * 0.75, size.y * 0.12),
				Color(0.25, 0.15, 0.05, 0.35))
		_still_object(ci, what, centre, size, base, shade, lit)
		if i == 0 and bool(d.get("labels", false)) and shade:
			var hl := centre + Vector2(lit.x * size.x * 0.22, -size.y * 0.2)
			SchoolPictureG4Arts._callout(ci, font, hl, Vector2(hl.x + (-1.0 if left else 1.0) * u * 0.2,
				r.position.y + fs), "highlight", fs)
			var dark := centre + Vector2(-lit.x * size.x * 0.38, size.y * 0.1)
			SchoolPictureG4Arts._callout(ci, font, dark, Vector2(dark.x - lit.x * u * 0.9, r.position.y + fs * 2.4),
				"shadow", fs)
			var cast := foot + Vector2(-lit.x * size.x * 0.9, 0)
			SchoolPictureG4Arts._callout(ci, font, cast, Vector2(cast.x - lit.x * u * 0.3, r.end.y - fs * 0.6),
				"cast shadow", fs)


static func _still_object(ci: CanvasItem, what: String, c: Vector2, s: Vector2, base: Color, shade: bool,
		lit: Vector2) -> void:
	var dark := base.darkened(0.45) if shade else base
	var mid := base
	var light := base.lightened(0.35) if shade else base
	match what:
		"apple", "lemon", "pear":
			if what == "pear":
				SchoolPictureG4Arts._ellipse(ci, c + Vector2(0, -s.y * 0.28), Vector2(s.x * 0.32, s.y * 0.3), dark)
			SchoolPictureG4Arts._ellipse(ci, c + Vector2(0, s.y * (0.12 if what == "pear" else 0.0)),
				Vector2(s.x * 0.5, s.y * (0.38 if what == "pear" else 0.5)), dark)
			if shade:   # lighter layers towards the light: the shadow side stays dark
				var off := Vector2(lit.x * s.x * 0.08, lit.y * s.y * 0.08)
				if what == "pear":
					SchoolPictureG4Arts._ellipse(ci, c + Vector2(0, -s.y * 0.28) + off, Vector2(s.x * 0.26, s.y * 0.25), mid)
				SchoolPictureG4Arts._ellipse(ci, c + off + Vector2(0, s.y * (0.12 if what == "pear" else 0.0)),
					Vector2(s.x * 0.42, s.y * (0.32 if what == "pear" else 0.42)), mid)
				SchoolPictureG4Arts._ellipse(ci, c + off * 2.6, Vector2(s.x * 0.2, s.y * 0.2), light)
				ci.draw_circle(c + off * 3.6, maxf(2.0, s.x * 0.06), Color(1, 1, 1, 0.9))
			if what == "apple":
				ci.draw_line(c + Vector2(0, -s.y * 0.45), c + Vector2(s.x * 0.06, -s.y * 0.7), Color("6b4a2a"), 2.0)
		"bowl":
			SchoolPictureG4Arts._ellipse(ci, c, Vector2(s.x * 0.5, s.y * 0.5), dark, true)
			if shade:
				SchoolPictureG4Arts._ellipse(ci, c + Vector2(lit.x * s.x * 0.06, 0), Vector2(s.x * 0.42, s.y * 0.42), mid, true)
				SchoolPictureG4Arts._ellipse(ci, c + Vector2(lit.x * s.x * 0.2, s.y * 0.1), Vector2(s.x * 0.1, s.y * 0.14), light)
			SchoolPictureG4Arts._ellipse(ci, c, Vector2(s.x * 0.5, s.y * 0.12), base.darkened(0.2))
		"jug", "bottle", "cup":
			var body := Rect2(c - s * 0.5 + Vector2(0, s.y * (0.25 if what == "bottle" else 0.12)), Vector2(s.x,
				s.y * (0.75 if what == "bottle" else 0.88)))
			ci.draw_rect(body, dark if shade else base)
			if shade:
				var lit_side := body.position.x if lit.x < 0.0 else body.position.x + body.size.x * 0.3
				ci.draw_rect(Rect2(Vector2(lit_side, body.position.y), Vector2(body.size.x * 0.7, body.size.y)), mid)
				ci.draw_rect(Rect2(Vector2(body.position.x + body.size.x * (0.14 if lit.x < 0.0 else 0.72), body.position.y
					+ 3), Vector2(body.size.x * 0.12, body.size.y - 6)), light)
			if what == "bottle":
				ci.draw_rect(Rect2(Vector2(c.x - s.x * 0.16, c.y - s.y * 0.5), Vector2(s.x * 0.32, s.y * 0.3)), mid)
			elif what == "jug":
				ci.draw_colored_polygon(PackedVector2Array([body.position, body.position + Vector2(-s.x * 0.18, -s.y * 0.08),
					body.position + Vector2(s.x * 0.2, 0)]), mid)
				ci.draw_arc(Vector2(body.end.x, body.get_center().y), s.y * 0.2, -PI * 0.5, PI * 0.5, 12, dark, 3.0)
			else:
				ci.draw_arc(Vector2(body.end.x, body.get_center().y), s.y * 0.18, -PI * 0.5, PI * 0.5, 12, dark, 3.0)
	if not shade:   # a flat drawing: only outlines
		if what in ["jug", "bottle", "cup"]:
			ci.draw_rect(Rect2(c - s * 0.5 + Vector2(0, s.y * (0.25 if what == "bottle" else 0.12)), Vector2(s.x,
				s.y * (0.75 if what == "bottle" else 0.88))), INK, false, 1.5)
		elif what != "bowl":
			SchoolPictureG4Arts._ellipse_line(ci, c, s * 0.5)


static func _draw_abstract(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var v := _int(d, "variant", 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + v * 31
	var side := minf(r.size.x, r.size.y * 1.3)
	var box := Rect2(r.position + Vector2((r.size.x - side) * 0.5, 0), Vector2(side, r.size.y))
	var primaries: Array[Color] = [Color("d9302a"), Color("f2d22e"), Color("2451b3")]
	match str(d.style):
		"grid":   # black lines and blocks of the primary colours on white
			ci.draw_rect(box, Color("f6f3ea"))
			var xs: Array[float] = [0.0, 0.28 + 0.04 * v, 0.62, 0.84 - 0.03 * v, 1.0]
			var ys: Array[float] = [0.0, 0.35 - 0.03 * v, 0.7, 1.0]
			var layouts := [[[0, 0, 0], [3, 2, 2], [2, 1, 1]], [[1, 0, 2], [0, 2, 0], [3, 1, 1]],
				[[3, 0, 0], [0, 1, 2], [2, 2, 1]], [[0, 1, 0], [2, 0, 1], [3, 2, 2]]]
			for f: Array in layouts[v]:   # [column, row, colour]
				var cell := Rect2(box.position + Vector2(xs[f[0]] * box.size.x, ys[f[1]] * box.size.y),
					Vector2((xs[f[0] + 1] - xs[f[0]]) * box.size.x, (ys[f[1] + 1] - ys[f[1]]) * box.size.y))
				ci.draw_rect(cell, primaries[int(f[2])])
			var lw := maxf(3.0, box.size.y * 0.035)
			for x in xs.slice(1, 4):
				ci.draw_line(box.position + Vector2(x * box.size.x, 0), box.position + Vector2(x * box.size.x, box.size.y),
					Color.BLACK, lw)
			for y in ys.slice(1, 3):
				ci.draw_line(box.position + Vector2(0, y * box.size.y), box.position + Vector2(box.size.x, y * box.size.y),
					Color.BLACK, lw)
		"shapes":   # circles, triangles and lines that seem to move and sound
			ci.draw_rect(box, Color("efe8d8"))
			for k in 3:
				var c := box.position + Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.2, 0.8)) * box.size
				var rad := box.size.y * rng.randf_range(0.08, 0.2)
				ci.draw_circle(c, rad, primaries[(k + v) % 3])
				ci.draw_arc(c, rad * 1.25, 0, TAU, 24, Color.BLACK, 2.0)
			for k in 2:
				var a := box.position + Vector2(rng.randf_range(0.1, 0.9), rng.randf_range(0.1, 0.9)) * box.size
				var s := box.size.y * rng.randf_range(0.12, 0.22)
				ci.draw_colored_polygon(PackedVector2Array([a, a + Vector2(s, s * 0.3), a + Vector2(s * 0.2, s)]),
					[Color("3aa845"), Color("8a3fb8"), Color("f08a1c")][(k + v) % 3])
			for k in 4:
				ci.draw_line(box.position + Vector2(rng.randf(), rng.randf()) * box.size, box.position
					+ Vector2(rng.randf(), rng.randf()) * box.size, Color.BLACK, rng.randf_range(1.5, 4.0))
		"circles":   # squares, each with rings of colour inside
			var cols := 3
			var rows := 2
			var cw := box.size.x / cols
			var ch := box.size.y / rows
			var palette: Array[Color] = [Color("d9302a"), Color("f2d22e"), Color("2451b3"), Color("3aa845"),
				Color("8a3fb8"), Color("f08a1c"), Color("1f2a4a"), Color("f7aaa6")]
			for y in rows:
				for x in cols:
					var cell := Rect2(box.position + Vector2(x * cw, y * ch), Vector2(cw, ch))
					ci.draw_rect(cell, palette[rng.randi_range(0, 7)])
					var c := cell.get_center()
					var rad := minf(cw, ch) * 0.42
					for k in 4:
						ci.draw_circle(c, rad * (1.0 - k * 0.24), palette[(x + y * 3 + k * 3 + v) % 8])


static func _draw_dye(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var col: Color = SchoolPictureArts.COLOURS[str(d.colour)]
	var pale := col.lerp(Color.WHITE, 0.75)
	var side := minf(r.size.x, r.size.y)
	var cloth := Rect2(r.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))
	var c := cloth.get_center()
	match str(d.what):
		"rings":   # tied at the middle: rings of dye and undyed cloth
			ci.draw_rect(cloth, col)
			for k in range(6, 0, -1):
				ci.draw_circle(c, side * 0.08 * k, pale if k % 2 == 0 else col)
		"spiral":   # twisted round the middle: arms of dye
			ci.draw_rect(cloth, pale)
			for arm in 4:
				var pts := PackedVector2Array([c])
				for k in range(1, 30):
					var t := k / 29.0
					pts.append(c + Vector2(cos(arm * TAU / 4.0 + t * 4.0), sin(arm * TAU / 4.0 + t * 4.0)) * side * 0.49 * t)
				for k in range(29, 0, -1):
					var t := k / 29.0
					var a := arm * TAU / 4.0 + t * 4.0 + 0.55
					pts.append(c + Vector2(cos(a), sin(a)) * side * 0.49 * t)
				ci.draw_colored_polygon(pts, col)
			ci.draw_rect(cloth, col.darkened(0.2), false, 2.0)
		"batik":   # wax kept the dye off: pale lines of leaves and dots, and fine cracks
			ci.draw_rect(cloth, col)
			for k in 3:
				var leaf_c := cloth.position + Vector2(side * (0.25 + 0.25 * k), side * (0.3 + 0.2 * (k % 2)))
				var pts := PackedVector2Array()
				for a in 21:
					var t := PI * a / 20.0
					pts.append(leaf_c + Vector2(cos(t) * side * 0.14, sin(t) * side * 0.05 - side * 0.02).rotated(0.5 * k))
				for a in 21:
					var t := PI + PI * a / 20.0
					pts.append(leaf_c + Vector2(cos(t) * side * 0.14, sin(t) * side * 0.05 + side * 0.02).rotated(0.5 * k))
				ci.draw_polyline(pts, PAPER_WHITE, 2.5, true)
				ci.draw_line(leaf_c - Vector2(side * 0.12, 0).rotated(0.5 * k), leaf_c + Vector2(side * 0.12, 0).rotated(0.5 * k),
					PAPER_WHITE, 1.5)
			for k in 12:
				var p := cloth.position + Vector2(0.08 + 0.84 * ((k * 37) % 12) / 11.0, 0.72 + 0.2 * ((k * 5) % 3) / 2.0) * side
				ci.draw_circle(p, side * 0.02, PAPER_WHITE)
			for k in 6:
				var a := cloth.position + Vector2(((k * 29) % 10) / 10.0, ((k * 17) % 10) / 10.0) * side
				ci.draw_line(a, a + Vector2(side * 0.12, side * 0.07), col.darkened(0.35), 1.0)
		"tied":   # cloth bunched up and tied with bands before it goes in the dye
			var pts := PackedVector2Array()
			for k in 24:
				var a := TAU * k / 24.0
				var wob := 1.0 + 0.08 * sin(a * 5.0)
				pts.append(c + Vector2(cos(a) * side * 0.22, sin(a) * side * 0.42) * wob)
			ci.draw_colored_polygon(pts, col.lerp(Color("f2efe8"), 0.2))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Color("8c8c8c"), 1.5)
			for y: float in [-0.22, 0.0, 0.22]:
				ci.draw_line(c + Vector2(-side * 0.24, y * side), c + Vector2(side * 0.24, y * side), Color("7a4a24"), 4.0)


static func _draw_comic(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var panels: Array = d.panels
	var n := panels.size()
	var mark := _int(d, "mark", -1)
	var pw := r.size.x / n
	var fs := clampi(int(minf(pw, r.size.y) * 0.1), 9, 18)
	for i in n:
		var p: Dictionary = panels[i]
		var box := Rect2(r.position + Vector2(i * pw + 3, 0), Vector2(pw - 6, r.size.y))
		ci.draw_rect(box, Color.WHITE)
		var shot := str(p.get("shot", "medium"))
		var ground := box.end.y - box.size.y * 0.12
		var head: Vector2
		var hr: float
		match shot:
			"wide":
				ci.draw_rect(Rect2(Vector2(box.position.x, ground), Vector2(box.size.x, box.end.y - ground)), GRASS)
				ci.draw_rect(Rect2(box.position + Vector2(box.size.x * 0.72, box.size.y * 0.45), Vector2(box.size.x * 0.06,
					ground - box.position.y - box.size.y * 0.45)), Color("7a4a24"))
				ci.draw_circle(box.position + Vector2(box.size.x * 0.75, box.size.y * 0.42), box.size.x * 0.12, Color("2f8a3a"))
				hr = box.size.y * 0.06
				head = Vector2(box.position.x + box.size.x * 0.35, ground - hr * 4.0)
				ci.draw_line(head + Vector2(0, hr), head + Vector2(0, hr * 3.0), INK, 2.0)
				ci.draw_line(head + Vector2(0, hr * 3.0), head + Vector2(-hr, hr * 4.0), INK, 2.0)
				ci.draw_line(head + Vector2(0, hr * 3.0), head + Vector2(hr, hr * 4.0), INK, 2.0)
			"close":
				hr = minf(box.size.x, box.size.y) * 0.3
				head = Vector2(box.get_center().x, box.end.y - hr * 0.8)
			_:
				hr = minf(box.size.x, box.size.y) * 0.13
				head = Vector2(box.get_center().x, box.end.y - hr * 2.6)
				SchoolPictureG4Arts._rounded(ci, Rect2(head + Vector2(-hr * 1.1, hr * 0.9), Vector2(hr * 2.2, hr * 2.0)),
					BLUE, hr * 0.5)
		ci.draw_circle(head, hr, Color("f2c9a0"))
		ci.draw_circle(head + Vector2(-hr * 0.35, -hr * 0.1), maxf(1.5, hr * 0.1), INK)
		ci.draw_circle(head + Vector2(hr * 0.35, -hr * 0.1), maxf(1.5, hr * 0.1), INK)
		ci.draw_arc(head + Vector2(0, hr * 0.2), hr * 0.35, 0.3, PI - 0.3, 8, INK, maxf(1.0, hr * 0.06))
		var top := box.position.y + 4
		if p.has("caption"):
			var cap := str(p.caption)
			var cs := SchoolPictureG4Arts._fit(font, cap, fs, box.size.x - 12)
			var cb := Rect2(box.position + Vector2(3, 3), Vector2(box.size.x - 6, cs * 1.6))
			ci.draw_rect(cb, Color("ffe68a"))
			ci.draw_rect(cb, INK, false, 1.2)
			SchoolPictureG4Arts._label(ci, font, cb.get_center(), cap, cs)
			top = cb.end.y + 4
		for k: String in ["say", "think"]:
			if not p.has(k):
				continue
			var text := str(p[k])
			var ts := SchoolPictureG4Arts._fit(font, text, fs, box.size.x * 0.84)
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
			var bc := Vector2(box.get_center().x, top + ts * 1.1)
			var radii := Vector2(minf(tw * 0.62 + 8, box.size.x * 0.48), ts * 1.1)
			var foot := bc + Vector2(0, radii.y * 0.8)
			var towards := (head + Vector2(0, -hr) - foot).normalized()
			var reach := minf((head + Vector2(0, -hr) - foot).length() * 0.6, box.size.y * 0.16)
			if k == "say":   # a speech bubble: its tail points at the speaker
				var tip := foot + towards * (reach + radii.y * 0.3)
				var tail := PackedVector2Array([foot + Vector2(-radii.y * 0.45, -radii.y * 0.3), foot + Vector2(radii.y * 0.45,
					-radii.y * 0.3), tip])
				ci.draw_colored_polygon(tail, Color.WHITE)
				ci.draw_polyline(tail, INK, 1.2)
				SchoolPictureG4Arts._ellipse(ci, bc, radii, Color.WHITE)
				SchoolPictureG4Arts._ellipse_line(ci, bc, radii)
			else:   # a thought: a cloud, and little circles down to the thinker
				var bumps := 10
				var bump := radii.y * 0.42
				for b in bumps:
					var a := TAU * b / bumps
					ci.draw_circle(bc + Vector2(cos(a) * radii.x, sin(a) * radii.y) * 0.92, bump + 1.3, INK)
				for b in bumps:
					var a := TAU * b / bumps
					ci.draw_circle(bc + Vector2(cos(a) * radii.x, sin(a) * radii.y) * 0.92, bump, Color.WHITE)
				SchoolPictureG4Arts._ellipse(ci, bc, radii * 0.98, Color.WHITE)
				for b in 2:
					var at := foot + towards * (radii.y * 0.4 + reach * (0.35 + b * 0.45))
					var rad := maxf(2.0, radii.y * (0.26 - b * 0.1))
					ci.draw_circle(at, rad + 1.2, INK)
					ci.draw_circle(at, rad, Color.WHITE)
			SchoolPictureG4Arts._label(ci, font, bc, text, ts)
			top = bc.y + radii.y + 6
		if p.has("sfx"):
			var word := str(p.sfx)
			var sc := box.position + Vector2(box.size.x * 0.66, box.size.y * 0.62)
			var star := PackedVector2Array()
			var big := minf(box.size.x, box.size.y) * 0.3
			for k in 16:
				var a := TAU * k / 16.0
				star.append(sc + Vector2(cos(a), sin(a) * 0.7) * big * (1.0 if k % 2 == 0 else 0.7))
			ci.draw_colored_polygon(star, Color("ffd23f"))
			SchoolPictureG4Arts._label(ci, font, sc, word, SchoolPictureG4Arts._fit(font, word, int(fs * 1.3), big * 1.3),
				Color("d9302a"))
		ci.draw_rect(box, SHADE if i == mark else INK, false, 4.0 if i == mark else 2.0)


# --- music -----------------------------------------------------------------------------------------------------------

static func _draw_keyboard(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var from := _pitch(str(d.get("from", "C4")))
	var keys := _int(d, "keys", 8)
	var marks: Array[int] = []
	for m: Variant in d.get("mark", []):
		marks.append(_pitch(str(m)))
	var fs := _fs(r, 0.1, 18)
	var title_h := fs * 1.5 if d.has("title") else 0.0
	var steps_h := fs * 1.4 if bool(d.get("steps", false)) else 0.0
	if d.has("title"):
		SchoolPictureG4Arts._label(ci, font, Vector2(r.get_center().x, r.position.y + title_h * 0.4), str(d.title), fs)
	var kw := minf(r.size.x / keys, (r.size.y - title_h - steps_h) * 0.3)
	var kh := minf(r.size.y - title_h - steps_h, kw * 4.5)
	var o := Vector2(r.position.x + (r.size.x - kw * keys) * 0.5, r.end.y - kh)
	var centres := {}
	for k in keys:
		var p := _white_pitch(from, k)
		var box := Rect2(o + Vector2(k * kw, 0), Vector2(kw, kh))
		ci.draw_rect(box, SHADE if marks.has(p) else Color.WHITE)
		ci.draw_rect(box, INK, false, 1.5)
		centres[p] = Vector2(box.get_center().x, box.position.y + kh * 0.8)
		if bool(d.get("names", false)):
			SchoolPictureG4Arts._label(ci, font, Vector2(box.get_center().x, box.end.y - fs * 0.8),
				LETTERS[_letter_index(p)], fs)
	for k in keys - 1:   # black keys between the white keys that have one
		var p := _white_pitch(from, k)
		if not posmod(p, 12) in [0, 2, 5, 7, 9]:
			continue
		var box := Rect2(o + Vector2((k + 1) * kw - kw * 0.3, 0), Vector2(kw * 0.6, kh * 0.6))
		ci.draw_rect(box, Color("c7621a") if marks.has(p + 1) else Color("1c1c1c"))
		centres[p + 1] = Vector2(box.get_center().x, box.position.y + kh * 0.45)
	if bool(d.get("steps", false)):
		for i in marks.size() - 1:
			var gap := marks[i + 1] - marks[i]
			if not centres.has(marks[i]) or not centres.has(marks[i + 1]) or not gap in [1, 2]:
				continue
			var mid := (float(centres[marks[i]].x) + float(centres[marks[i + 1]].x)) * 0.5
			SchoolPictureG4Arts._label(ci, font, Vector2(mid, o.y - steps_h * 0.5), "T" if gap == 2 else "S", fs,
				BLUE if gap == 2 else SHADE)


static func _letter_index(p: int) -> int:
	for i in 7:
		if int(SEMIS[LETTERS[i]]) == posmod(p, 12):
			return i
	return 0


static func _draw_chord_stave(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var chords: Array = d.chords
	var names: Array = d.get("names", [])
	var mark := _int(d, "mark", -1)
	var n := chords.size()
	var fs := _fs(r, 0.12, 22)
	var name_h := fs * 1.4 if not names.is_empty() else 0.0
	var u := minf((r.size.y - name_h) / 15.5, r.size.x / (5.0 + n * 6.0 + 1.0))
	var base_y := r.position.y + (r.size.y - name_h) * 0.5 + 4.0 * u
	var width := (5.0 + n * 6.0 + 1.0) * u
	var x0 := r.position.x + (r.size.x - width) * 0.5
	var lw := maxf(1.2, u * 0.12)
	for i in 5:
		var y := base_y - i * 2.0 * u
		ci.draw_line(Vector2(x0, y), Vector2(x0 + width, y), INK, lw)
	SchoolPictureG4Arts._treble_clef(ci, Vector2(x0 + 2.2 * u, base_y), u, lw)
	for i in n:
		var cx := x0 + (5.0 + 6.0 * i + 3.0) * u
		var col := SHADE if i == mark else INK
		for note: Variant in chords[i]:
			var s := SchoolPictureG4Arts.stave_step(str(note))
			var c := Vector2(cx, base_y - s * u)
			for ledger: int in [-2, 10]:
				if (ledger < 0 and s <= ledger) or (ledger > 0 and s >= ledger):
					ci.draw_line(Vector2(cx - 2.0 * u, base_y - ledger * u), Vector2(cx + 2.0 * u, base_y - ledger * u), INK, lw)
			SchoolPictureG4Arts._stave_note(ci, c, u, lw, "semibreve", true, col)
		if not names.is_empty():
			SchoolPictureG4Arts._label(ci, font, Vector2(cx, r.end.y - name_h * 0.5), str(names[i]), fs, col)
		if i < n - 1:
			var bx := cx + 3.0 * u
			ci.draw_line(Vector2(bx, base_y), Vector2(bx, base_y - 8.0 * u), INK, lw)


static func _draw_form(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var sections: Array = d.sections
	var n := sections.size()
	var mark := _int(d, "mark", -1)
	var w := r.size.x / n
	var h := minf(r.size.y * 0.6, w * 1.2)
	var fs := clampi(int(minf(w * 0.3, h * 0.35)), 9, 28)
	var extra := {}
	for i in n:
		var s := str(sections[i])
		var col: Color = SECTION_COLOURS.get(s, Color())
		if not SECTION_COLOURS.has(s):
			if not extra.has(s):
				extra[s] = ROW_COLOURS[extra.size() % ROW_COLOURS.size()]
			col = extra[s]
		var lift := h * 0.12 if i == mark else 0.0
		var box := Rect2(Vector2(r.position.x + i * w + 3, r.get_center().y - h * 0.5 - lift), Vector2(w - 6, h))
		SchoolPictureG4Arts._rounded(ci, box, col, 8)
		if i == mark:
			var mb := StyleBoxFlat.new()
			mb.draw_center = false
			mb.set_border_width_all(4)
			mb.border_color = INK
			mb.set_corner_radius_all(8)
			ci.draw_style_box(mb, box.grow(2))
		SchoolPictureG4Arts._label(ci, font, box.get_center(), s, SchoolPictureG4Arts._fit(font, s, fs, w - 12), Color.WHITE)


static func _draw_lifespans(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var people: Array = d.people
	var from := _int(d, "from", 0)
	var to := _int(d, "to", 1)
	var mark := _int(d, "mark", -1)
	var fs := _fs(r, 0.09, 18)
	var name_w := r.size.x * 0.24
	var axis_h := fs * 1.8
	var plot := Rect2(r.position + Vector2(name_w, 0), Vector2(r.size.x - name_w - fs, r.size.y - axis_h))
	var span := float(to - from)
	var tick := 50 if span > 150 else 25
	var y_axis := plot.end.y + 4
	ci.draw_line(Vector2(plot.position.x, y_axis), Vector2(plot.end.x, y_axis), INK, 2.0)
	var t := int(ceil(from / float(tick))) * tick
	while t <= to:
		var x := plot.position.x + plot.size.x * (t - from) / span
		ci.draw_line(Vector2(x, y_axis - 4), Vector2(x, y_axis + 4), INK, 1.5)
		SchoolPictureG4Arts._label(ci, font, Vector2(x, y_axis + fs * 0.9), str(t), fs)
		ci.draw_line(Vector2(x, plot.position.y), Vector2(x, y_axis), Color(GRID_LINE, 0.5), 1.0)
		t += tick
	var rh := plot.size.y / people.size()
	for i in people.size():
		var row: Array = people[i]
		var x0 := plot.position.x + plot.size.x * (int(row[1]) - from) / span
		var x1 := plot.position.x + plot.size.x * (int(row[2]) - from) / span
		var y := plot.position.y + rh * (i + 0.5)
		SchoolPictureG4Arts._rounded(ci, Rect2(Vector2(x0, y - rh * 0.3), Vector2(x1 - x0, rh * 0.6)),
			SHADE if i == mark else BLUE, rh * 0.2)
		var name := str(row[0])
		ci.draw_string(font, Vector2(r.position.x, y + fs * 0.35), name, HORIZONTAL_ALIGNMENT_RIGHT, name_w - 6,
			SchoolPictureG4Arts._fit(font, name, fs, name_w - 6), INK)
	if d.has("year"):
		var x := plot.position.x + plot.size.x * (_int(d, "year", from) - from) / span
		ci.draw_dashed_line(Vector2(x, plot.position.y), Vector2(x, y_axis), Color("d9302a"), 2.0, 5.0)


static func _draw_beat_grid(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var steps := str(rows[0][1]).length()
	var mark := _int(d, "mark", -1)
	var count := bool(d.get("count", false))
	var fs := _fs(r, 0.1, 18)
	var name_w := r.size.x * 0.2
	var count_h := fs * 1.4 if count else 0.0
	# a box for each step: as wide as fits, and up to twice as tall (16 steps would otherwise be tiny)
	var cw := minf((r.size.x - name_w) / steps, (r.size.y - count_h) / rows.size())
	var ch := minf((r.size.y - count_h) / rows.size(), cw * 2.0)
	var o := Vector2(r.position.x + name_w, r.position.y + count_h + (r.size.y - count_h - ch * rows.size()) * 0.5)
	if count:
		for st in steps:
			var word := ""
			if steps <= 8:
				word = str(st / 2 + 1) if st % 2 == 0 else "&"
			elif st % 4 == 0:
				word = str(st / 4 + 1)
			SchoolPictureG4Arts._label(ci, font, Vector2(o.x + (st + 0.5) * cw, o.y - count_h * 0.5), word, fs)
	for i in rows.size():
		var name := str(rows[i][0])
		var pat := str(rows[i][1])
		ci.draw_string(font, Vector2(r.position.x, o.y + (i + 0.5) * ch + fs * 0.35), name, HORIZONTAL_ALIGNMENT_RIGHT,
			name_w - 6, SchoolPictureG4Arts._fit(font, name, fs, name_w - 6), SHADE if i == mark else INK)
		for st in steps:
			var box := Rect2(o + Vector2(st * cw, i * ch), Vector2(cw, ch)).grow(-2)
			ci.draw_rect(box, ROW_COLOURS[i % ROW_COLOURS.size()] if pat[st] == "x" else Color.WHITE)
			ci.draw_rect(box, GRID_LINE, false, 1.0)
		if i == mark:
			ci.draw_rect(Rect2(o + Vector2(0, i * ch), Vector2(steps * cw, ch)), SHADE, false, 3.0)
	var per_beat := 2 if steps <= 8 else 4
	for st in range(0, steps + 1, per_beat):
		ci.draw_line(o + Vector2(st * cw, 0), o + Vector2(st * cw, rows.size() * ch), INK, 2.0 if st % (per_beat * 4) == 0
			else 1.2)


static func _draw_beat_pattern(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var beats := _int(d, "beats", 4)
	var mark := _int(d, "mark", -1)
	var s := minf(r.size.x, r.size.y) * 0.45
	var c := r.get_center()
	# where the hand is on each beat: 1 always down at the bottom, the last beat always up at the top (in 2, the hand
	# goes up from 2 to the top, ready to come down on 1)
	var spots: Array[Vector2] = []
	match beats:
		2:
			spots = [Vector2(0, 0.8), Vector2(0.45, 0.3)]
		3:
			spots = [Vector2(0, 0.8), Vector2(0.8, 0.35), Vector2(0.05, -0.8)]
		4:
			spots = [Vector2(0, 0.8), Vector2(-0.8, 0.3), Vector2(0.8, 0.35), Vector2(0.05, -0.8)]
	var top := c + Vector2(0.05, -0.8) * s
	var fs := clampi(int(s * 0.28), 10, 26)
	var stops: Array[Vector2] = [top]
	for sp in spots:
		stops.append(c + sp * s)
	if beats == 2:
		stops.append(top)
	for i in stops.size() - 1:
		var a := stops[i]
		var b := stops[i + 1]
		var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * (b - a).length() * 0.12
		var curve := SchoolPictureG4Arts._catmull(PackedVector2Array([a, mid, b]), 8)
		ci.draw_polyline(curve, Color(BLUE, 0.85), 3.0, true)
		SchoolPictureG4Arts._arrow(ci, curve[curve.size() - 4], b - (b - curve[curve.size() - 4]).normalized() * fs * 0.8,
			3.0)
	for i in beats:
		var at := c + spots[i] * s
		ci.draw_circle(at, fs * 0.8, SHADE if i + 1 == mark else INK)
		SchoolPictureG4Arts._label(ci, font, at, str(i + 1), fs, Color.WHITE)


static func _draw_tracks(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var tracks: Array = d.tracks
	var bars := _int(d, "bars", 4)
	var mark := _int(d, "mark", -1)
	var fs := _fs(r, 0.1, 18)
	var name_w := r.size.x * 0.2
	var head_h := fs * 1.5
	var bw := (r.size.x - name_w) / bars
	var th := (r.size.y - head_h) / tracks.size()
	var o := r.position + Vector2(name_w, head_h)
	if d.has("loop"):
		var lp: Array = d.loop
		var zone := Rect2(Vector2(o.x + int(lp[0]) * bw, r.position.y), Vector2((int(lp[1]) - int(lp[0])) * bw, r.size.y))
		ci.draw_rect(zone, Color(0.95, 0.85, 0.3, 0.35))
		ci.draw_rect(Rect2(zone.position, Vector2(zone.size.x, head_h * 0.8)), Color("f2c12e"))
		SchoolPictureG4Arts._label(ci, font, Vector2(zone.get_center().x, r.position.y + head_h * 0.4), "LOOP", fs)
	for b in bars:
		if not d.has("loop") or b < int(d.loop[0]) or b >= int(d.loop[1]):
			SchoolPictureG4Arts._label(ci, font, Vector2(o.x + (b + 0.5) * bw, r.position.y + head_h * 0.45), str(b + 1), fs)
	for b in bars + 1:
		ci.draw_line(Vector2(o.x + b * bw, o.y), Vector2(o.x + b * bw, r.end.y), GRID_LINE, 1.0)
	for i in tracks.size():
		var y := o.y + i * th
		var name := str(tracks[i][0])
		ci.draw_string(font, Vector2(r.position.x, y + th * 0.5 + fs * 0.35), name, HORIZONTAL_ALIGNMENT_RIGHT, name_w - 6,
			SchoolPictureG4Arts._fit(font, name, fs, name_w - 6), INK)
		for clip: Variant in tracks[i][1]:
			var box := Rect2(Vector2(o.x + int(clip[0]) * bw + 2, y + th * 0.15), Vector2(int(clip[1]) * bw - 4, th * 0.7))
			SchoolPictureG4Arts._rounded(ci, box, ROW_COLOURS[i % ROW_COLOURS.size()], 6)
			if i == mark:
				ci.draw_rect(box.grow(1), SHADE, false, 3.0)
			for k in 6:   # a few notes drawn on the clip
				var nx := box.position.x + box.size.x * (k + 0.5) / 6.0
				var ny := box.position.y + box.size.y * (0.3 + 0.4 * float((k * 3 + i) % 4) / 3.0)
				ci.draw_line(Vector2(nx - box.size.x * 0.03, ny), Vector2(nx + box.size.x * 0.03, ny), Color(1, 1, 1, 0.8), 2.0)


static func _draw_waveform(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var levels: Array = d.levels
	var n := levels.size()
	var keep: Array = d.get("keep", [0, n])
	var mid := r.get_center().y
	var w := r.size.x / n
	ci.draw_line(Vector2(r.position.x, mid), Vector2(r.end.x, mid), GRID_LINE, 1.0)
	for i in n:
		var h := r.size.y * 0.45 * float(levels[i]) / 10.0
		var kept := i >= int(keep[0]) and i < int(keep[1])
		ci.draw_rect(Rect2(Vector2(r.position.x + i * w + w * 0.15, mid - h), Vector2(w * 0.7, maxf(h * 2.0, 2.0))),
			BLUE if kept else Color("b8bfcc"))
	if d.has("keep"):
		for x: float in [r.position.x + int(keep[0]) * w, r.position.x + int(keep[1]) * w]:
			ci.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), SHADE, 3.0)


# --- helpers -----------------------------------------------------------------------------------------------------------

static func _short(t: Variant, most: int) -> bool:
	return t is String and str(t).strip_edges() != "" and str(t).length() <= most


static func _texts(a: Variant, n: int, most: int) -> bool:
	if not a is Array or (a as Array).size() != n:
		return false
	for t: Variant in a:
		if not _short(t, most):
			return false
	return true


static func _is_order(a: Variant, n: int) -> bool:
	if not a is Array or (a as Array).size() != n:
		return false
	var seen := {}
	for v: Variant in a:
		if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or int(v) < 0 or int(v) >= n or seen.has(int(v)):
			return false
		seen[int(v)] = true
	return true


static func _int(p: Dictionary, key: String, default: int) -> int:
	var v: Variant = p.get(key, default)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _num(p: Dictionary, key: String, default: float) -> float:
	var v: Variant = p.get(key, default)
	return float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _in(v: int, lo: int, hi: int) -> bool:
	return v >= lo and v <= hi
