class_name SchoolPictureG7Arts
extends RefCounted
## Owner #70 and #73, grade 7 computing, art and music (research §6.7): the picture kinds they add, drawn from data onto
## a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the font has
## no music signs, arrows or ticks, so they are drawn). Kinds and fields:
## Computing
## - text_code {lines: [text] (1-10, 36 letters; 4 spaces for each step in, at most 3), mark? (a line's index, shaded),
##   error? (a line's index: a wavy line under it and a sign in the margin), output? [text] (0-5 lines of 30: the output
##   panel), numbers? (the line numbers; true), blocks? [the grade 4 code picture's lines] (the same program as blocks on
##   the left; not with output)}: a program in a text language, coloured as an editor colours it (words of the
##   language, text in quotes, numbers, # comments).
## - list_boxes {items: [text (8)] (1-8), name? (10), index? (the indexes 0, 1, 2 … under the boxes; true), negative? (the
##   indexes from the end, -1 the last), mark? (an index or [indexes]), hide? (an index shown "?")}: a list as a row of
##   numbered boxes.
## - func_machine {name (12), params: [text (6)] (1-3), args? [text (6)] (one for each), body? (24: what it returns),
##   out? (8, or "?")}: a function as a machine: the arguments drop into its parameters and the result comes out.
## - search_steps {items: [whole numbers] (4-16; in order for binary), target, method: "linear" | "binary", steps? (the
##   checks shown; all of them)}: a search: each check ringed and numbered; binary search greys the half it throws away
##   (`search_checks`).
## - sort_bars {items: [1-99] (2-8), method: "bubble" | "merge", pass? (bubble: the list after this many passes; 0),
##   compare? (bubble: the pair at this index and the next ringed), view? ("bars"; "tree" for merge: split and merged
##   again)}: a sort (`bubble_after`, `merge_rows`).
## - internet_trip {view: "routes" | "dns", routes? [router letters, "ABC"] (1-3, each from the computer to the server
##   along ROUTER_LINKS), lost? (a route's index: its packet lost), mark? (a router), domain? (24), ip? (a.b.c.d), step?
##   (1-4: the DNS steps shown)}: packets taking routes through routers, or a DNS lookup (`route_hops`).
## - cipher_wheel {shift (0-25), mark? (a letter), word? (1-8 capitals: it and its code under the wheel), decode? (the
##   word is a code, its letters shown under)}: a Caesar cipher wheel (`caesar`).
## - data_sheet {head: [text (10)] (1-4), rows: [[text (10)]] (1-7, as long as head), flag? [[row, col]] (cells ringed),
##   strike? [rows] (crossed out: removed)}: collected data with its mistakes found.
## - phone_feed {labels?, mark? (a part of FEED_PARTS)}: a phone's feed and the tricks that keep you scrolling
##   (`part_at`).
## - licence_tags {tags: [LICENCES] (1-4), names? (true), mark?}: copyright and Creative Commons licences as badges.
## Art
## - old_master {what: OLD_MASTERS, lines? (the geometry: lines to the vanishing point, the triangle, the halfway
##   line)}: a simple picture after a Renaissance work (Leonardo's Mona Lisa and Vitruvian Man, Raphael's School of
##   Athens).
## - colour_scheme {scheme: SCHEMES, base: a colour of the 12-colour wheel, view? ("wheel", "swatches", "scene")}: a
##   colour scheme on the wheel, as swatches or as a painted scene (`scheme_colours`).
## - figure_study {view: "heads" | "gesture" | "mannequin", heads? (4-8 for "heads"; 8), pose? (POSES), line? (the line
##   of action), labels?, mark? (a FIGURE_PARTS line)}: a figure measured in heads, or a pose as a quick gesture or a
##   mannequin of shapes (`part_at`).
## - world_art_piece {what: PIECES, labels?, mark?}: art of 1450-1750: a Mughal miniature, an Iznik tile, a Japanese
##   woodblock print, a blue-and-white vase (`part_at`).
## - poster_layout {design: DESIGNS, grid? (the layout grid), labels?, mark? (a POSTER_PARTS part)}: a poster's layout or a
##   logo tested (`part_at`).
## - house_drawing {view: "plan" | "front" | "side", dims? (sizes in metres), scale? ("1:50" | "1:100": a scale bar),
##   labels? (the rooms), mark? (a part)}: one small house's plan and elevations (HOUSE, `part_at`).
## - thirds_frame {subject: [x, y] (0-1), thing? (THINGS), grid? (the thirds lines), horizon? (0.1-0.9), lines? ("road",
##   "river", "fence"), frame? ("arch", "trees")}: a photo's composition (`on_thirds`).
## - carved_block {rows: [text of # and .] (1-8, 1-10 long, all as long), view: "block" | "print" | "side", grid?}: a woodcut
##   block's face (# raised, it takes the ink; . cut away), a print (# dark ink, . white paper; a block prints its rows
##   mirrored: `print_rows`), or a cut through the block's first row.
## - gallery_wall {works (2-5), hang: "line" | "tops" | "messy", line? (the eye-level line at 1.5 m), mark?, labels?}:
##   artworks hung on a wall.
## Music
## - chord_chart {key: CHART_KEYS, chords: [NUMERALS] (1-8), names? (the chords' names), numerals? (true), mark?, hide?
##   [bars shown "?"]}: a chord chart, a bar a box (`chord_name`, `chord_letters`).
## - ornament_signs {type: ORNAMENTS, note: D4-F5 (a white key), played? (the notes played, written out after it)}: an
##   ornament's sign over a note (`ornament_notes`).
## - symphony_plan {view: "movements" | "sonata", mark?, hide?}: a Classical symphony's four movements, or sonata form.
## - drum_kit {labels?, mark? (a KIT_PARTS part)}: a drum kit (`part_at`).
## - piano_roll {notes: [SchoolSound notes: "C4", "E4:2", "-", "-:2"] (1-16, no chords), repeat? (1-4), mark? [indexes],
##   bar? (beats a bar; 4)}: a music maker's piano roll: time across, pitch up, a note a bar of its length.
## - film_strip {frames: [SCENES] (1-4), captions? [text (14)], mark?}: film frames, for the music that fits them.
## - mixer {faders: [[name (8), level 0-10]] (2-5), mark?, meters?}: a mixing desk: each part's loudness.
## - clef_stave {clef: "bass" | "treble" | "grand", notes: [notes] (1-8: bass E2-C4, treble C4-A5, grand both), values?
##   [VALUES], ties? [index: tied to the next], names?, mark?, time? (TIMES), bars?}: notes on the bass or treble clef or
##   the grand stave, with dotted notes and ties (`clef_step`).

const KINDS: Array[String] = ["text_code", "list_boxes", "func_machine", "search_steps", "sort_bars", "internet_trip",
	"cipher_wheel", "data_sheet", "phone_feed", "licence_tags", "old_master", "colour_scheme", "figure_study",
	"world_art_piece", "poster_layout", "house_drawing", "thirds_frame", "carved_block", "gallery_wall", "chord_chart",
	"ornament_signs", "symphony_plan", "drum_kit", "piano_roll", "film_strip", "mixer", "clef_stave"]
const MAX_CODE_LINES := 10
const MAX_CODE_LINE := 36
const MAX_OUTPUT := 5
const KEYWORDS: Array[String] = ["if", "elif", "else", "for", "while", "in", "def", "return", "and", "or", "not", "True",
	"False", "None"]
const BUILTINS: Array[String] = ["print", "len", "range", "str", "int", "max", "min", "sum", "abs", "append", "remove"]
## Routers on the routes map (shares of the picture) and the links between them; the computer joins A and D, the server
## C and F.
const ROUTERS := {"A": Vector2(0.3, 0.27), "B": Vector2(0.5, 0.17), "C": Vector2(0.7, 0.27), "D": Vector2(0.3, 0.73),
	"E": Vector2(0.5, 0.83), "F": Vector2(0.7, 0.73)}
const ROUTER_LINKS: Array[String] = ["AB", "BC", "AD", "CF", "DE", "EF", "BE"]
const FIRST_ROUTERS := "AD"
const LAST_ROUTERS := "CF"
const FEED_PARTS := {"notification": Vector2(0.465, 0.06), "likes": Vector2(0.43, 0.4), "autoplay": Vector2(0.35, 0.74),
	"endless scroll": Vector2(0.35, 0.94)}
const LICENCES: Array[String] = ["copyright", "CC0", "BY", "BY-SA", "BY-NC", "BY-ND"]
const LICENCE_NAMES := {"copyright": "all rights reserved", "CC0": "no rights reserved", "BY": "credit me",
	"BY-SA": "credit, share alike", "BY-NC": "credit, not to sell", "BY-ND": "credit, no changes"}
const OLD_MASTERS: Array[String] = ["mona_lisa", "school_athens", "vitruvian_man"]
const SCHEMES: Array[String] = ["complementary", "analogous", "triadic", "split", "monochrome", "warm", "cool"]
const VIEWS_SCHEME: Array[String] = ["wheel", "swatches", "scene"]
const FIGURE_VIEWS: Array[String] = ["heads", "gesture", "mannequin"]
const POSES: Array[String] = ["stand", "walk", "run", "jump", "reach", "throw", "sit"]
## The lines of a figure 8 heads tall, in heads from the top of the head.
const FIGURE_PARTS := {"chin": 1.0, "chest": 2.0, "elbows": 3.0, "hips": 4.0, "fingertips": 5.0, "knees": 6.0,
	"feet": 8.0}
const PIECES: Array[String] = ["mughal", "iznik", "ukiyo_e", "blue_white"]
const PIECE_PARTS := {
	"mughal": {"border": Vector2(0.34, 0.55), "gold sky": Vector2(0.5, 0.16), "pavilion": Vector2(0.58, 0.43),
		"pool": Vector2(0.44, 0.78)},
	"iznik": {"tulip": Vector2(0.5, 0.27), "carnation": Vector2(0.605, 0.66), "saz leaf": Vector2(0.415, 0.6),
		"border": Vector2(0.5, 0.955)},
	"ukiyo_e": {"cartouche": Vector2(0.64, 0.2), "seal": Vector2(0.64, 0.86), "kimono pattern": Vector2(0.44, 0.62),
		"umbrella": Vector2(0.44, 0.19)}}
const DESIGNS: Array[String] = ["clear", "crowded", "centred", "logo_sizes", "logo_busy", "logo_mono"]
const POSTER_PARTS := {"headline": Vector2(0.43, 0.1), "image": Vector2(0.5, 0.45), "details": Vector2(0.4, 0.82),
	"white space": Vector2(0.58, 0.68), "logo": Vector2(0.62, 0.93)}
const HOUSE_VIEWS: Array[String] = ["plan", "front", "side"]
## The house (metres): 10 m wide, 6 m deep, walls 3 m high, the roof's ridge 5.5 m up; each room [x, y, w, d] on the
## plan (x across from the left, y from the back wall), the front door and windows on the front wall (y = 6).
const HOUSE := {"width": 10.0, "depth": 6.0, "wall": 3.0, "ridge": 5.5,
	"rooms": {"bedroom": [0.0, 0.0, 4.0, 3.0], "bathroom": [4.0, 0.0, 2.0, 3.0], "kitchen": [0.0, 3.0, 4.0, 3.0],
		"hall": [4.0, 3.0, 2.0, 3.0], "living room": [6.0, 0.0, 4.0, 6.0]},
	"door": [4.5, 1.0, 2.0], "windows": [[1.0, 2.0, 1.2, 1.0], [7.0, 2.0, 1.2, 1.0]]}
const HOUSE_PARTS: Array[String] = ["front door", "window", "bedroom", "kitchen", "living room", "bathroom", "roof",
	"wall"]
const THINGS: Array[String] = ["tree", "buddy", "tower", "boat"]
const HANGS: Array[String] = ["line", "tops", "messy"]
const CHART_KEYS: Array[String] = ["C", "G", "D", "F", "A"]
const NUMERALS: Array[String] = ["I", "ii", "iii", "IV", "V", "vi"]
const ORNAMENTS: Array[String] = ["trill", "mordent", "turn"]
const KIT_PARTS := {"hi-hat": Vector2(0.14, 0.3), "crash cymbal": Vector2(0.84, 0.13), "tom-toms": Vector2(0.5, 0.35),
	"snare drum": Vector2(0.3, 0.58), "kick drum": Vector2(0.52, 0.72)}
const SCENES: Array[String] = ["hero", "villain", "chase", "storm", "sunrise", "sneak", "comedy", "farewell"]
const CLEFS: Array[String] = ["bass", "treble", "grand"]
const VALUES: Array[String] = ["semibreve", "dotted minim", "minim", "dotted crotchet", "crotchet", "dotted quaver",
	"quaver", "semiquaver"]
const VALUE_BEATS := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "dotted crotchet": 1.5, "crotchet": 1.0,
	"dotted quaver": 0.75, "quaver": 0.5, "semiquaver": 0.25}
const TIMES := {"2/4": 2.0, "3/4": 3.0, "4/4": 4.0, "6/8": 3.0}
const LETTERS := "CDEFGAB"
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const MAJOR := [0, 2, 4, 5, 7, 9, 11]
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const BLUE := Color("3a7be8")
const SOFT := Color("fce2b8")
const PAPER_WHITE := Color("fffdf7")
const GREY := Color("9aa3b5")
const PALE := Color("e4e8f0")
const GOLD := Color("d9a520")
const RED := Color("e03a2f")
const GREEN := Color("3aa845")
const WOOD := Color("c89a62")
const WOOD_DARK := Color("8a6036")
const COBALT := Color("1d4fa8")
const TURQUOISE := Color("2aa8a0")
const CODE_BG := Color("f7f4ea")
const KEYWORD := Color("8a3fb8")
const BUILTIN := Color("1a55c0")
const STRING := Color("2e8b3e")
const NUMBER := Color("c0591a")
const COMMENT := Color("8c8c8c")


# --- checks ----------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"text_code":
			var lines: Variant = p.get("lines")
			if not lines is Array or (lines as Array).is_empty() or (lines as Array).size() > MAX_CODE_LINES:
				return "text_code: 1-%d lines" % MAX_CODE_LINES
			for l: Variant in lines:
				if not l is String or str(l).length() > MAX_CODE_LINE or str(l).strip_edges() == "":
					return "text_code: a line is text of 1-%d letters" % MAX_CODE_LINE
				var lead := str(l).length() - str(l).lstrip(" ").length()
				if lead % 4 != 0 or lead > 12:
					return "text_code: 4 spaces a step in, at most 3 steps"
			for k: String in ["mark", "error"]:
				if p.has(k) and not _in(_int(p, k, -1), 0, (lines as Array).size() - 1):
					return "text_code: %s is a line's index" % k
			if p.has("output"):
				var out: Variant = p.output
				if not out is Array or (out as Array).size() > MAX_OUTPUT:
					return "text_code: an output of 0-%d lines" % MAX_OUTPUT
				for o: Variant in out:
					if not o is String or str(o).length() > 30:
						return "text_code: an output line is text of 30 letters"
			if p.has("blocks"):
				if p.has("output"):
					return "text_code: blocks or an output, not both"
				var why := SchoolPictureG4Arts.problem({"kind": "code", "lines": p.blocks})
				if why != "":
					return "text_code: its blocks: %s" % why
		"list_boxes":
			var items: Variant = p.get("items")
			if not items is Array or (items as Array).is_empty() or (items as Array).size() > 8 \
					or not _texts(items, (items as Array).size(), 8):
				return "list_boxes: 1-8 items of 8 letters"
			if p.has("name") and not _short(p.name, 10):
				return "list_boxes: a name of 10 letters"
			var n := (items as Array).size()
			if p.has("hide") and not _in(_int(p, "hide", -1), 0, n - 1):
				return "list_boxes: hide is an index"
			if p.has("mark"):
				var marks: Array = p.mark if p.mark is Array else [p.mark]
				for m: Variant in marks:
					if typeof(m) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(m), 0, n - 1):
						return "list_boxes: mark is an index or indexes"
		"func_machine":
			if not _short(p.get("name"), 12):
				return "func_machine: a name of 12 letters"
			var params: Variant = p.get("params")
			if not params is Array or not _in((params as Array).size(), 1, 3) or not _texts(params, (params as Array).size(), 6):
				return "func_machine: 1-3 parameters of 6 letters"
			if p.has("args") and not _texts(p.args, (params as Array).size(), 6):
				return "func_machine: an argument (6 letters) for each parameter"
			if p.has("body") and not _short(p.body, 24):
				return "func_machine: a body of 24 letters"
			if p.has("out") and not _short(p.out, 8):
				return "func_machine: out is 8 letters"
		"search_steps":
			var items: Variant = p.get("items")
			if not items is Array or not _in((items as Array).size(), 4, 16):
				return "search_steps: 4-16 items"
			for v: Variant in items:
				if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or float(v) != floorf(float(v)) or absf(float(v)) > 9999:
					return "search_steps: the items are whole numbers"
			if typeof(p.get("target")) not in [TYPE_INT, TYPE_FLOAT]:
				return "search_steps: a target number"
			var method := str(p.get("method", ""))
			if not method in ["linear", "binary"]:
				return "search_steps: method is linear or binary"
			if method == "binary":
				for i in (items as Array).size() - 1:
					if float(items[i]) > float(items[i + 1]):
						return "search_steps: binary search needs the items in order"
			if p.has("steps") and not _in(_int(p, "steps", -1), 0, 16):
				return "search_steps: steps is 0-16"
		"sort_bars":
			var items: Variant = p.get("items")
			if not items is Array or not _in((items as Array).size(), 2, 8):
				return "sort_bars: 2-8 items"
			for v: Variant in items:
				if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(v), 1, 99) or float(v) != floorf(float(v)):
					return "sort_bars: the items are 1-99"
			var method := str(p.get("method", ""))
			if not method in ["bubble", "merge"]:
				return "sort_bars: method is bubble or merge"
			var n := (items as Array).size()
			if p.has("pass") and not _in(_int(p, "pass", -1), 0, n - 1):
				return "sort_bars: pass is 0-%d" % (n - 1)
			if p.has("compare") and (method != "bubble" or not _in(_int(p, "compare", -1), 0, n - 2)):
				return "sort_bars: compare is a pair's first index (bubble)"
			if p.has("view") and not str(p.view) in ["bars", "tree"]:
				return "sort_bars: view is bars or tree"
			if str(p.get("view", "bars")) == "tree" and method != "merge":
				return "sort_bars: the tree is merge sort's"
		"internet_trip":
			var view := str(p.get("view", ""))
			if view == "routes":
				var routes: Variant = p.get("routes")
				if not routes is Array or not _in((routes as Array).size(), 1, 3):
					return "internet_trip: 1-3 routes"
				for route: Variant in routes:
					if not route is String or not _route_ok(str(route)):
						return "internet_trip: a route goes from A or D along the links to C or F: %s" % str(route)
				if p.has("lost") and not _in(_int(p, "lost", -1), 0, (routes as Array).size() - 1):
					return "internet_trip: lost is a route's index"
				if p.has("mark") and not ROUTERS.has(str(p.mark)):
					return "internet_trip: mark is a router, A-F"
			elif view == "dns":
				if not _short(p.get("domain"), 24) or not _ip_ok(str(p.get("ip", ""))):
					return "internet_trip: a domain (24 letters) and an IP address"
				if p.has("step") and not _in(_int(p, "step", -1), 1, 4):
					return "internet_trip: step is 1-4"
			else:
				return "internet_trip: view is routes or dns"
		"cipher_wheel":
			if typeof(p.get("shift")) not in [TYPE_INT, TYPE_FLOAT] or not _in(_int(p, "shift", -1), 0, 25):
				return "cipher_wheel: a shift of 0-25"
			if p.has("mark") and not _is_capital(str(p.mark), 1, 1):
				return "cipher_wheel: mark is a capital letter"
			if p.has("word") and not _is_capital(str(p.word), 1, 8):
				return "cipher_wheel: a word of 1-8 capital letters"
		"data_sheet":
			var head: Variant = p.get("head")
			if not head is Array or not _in((head as Array).size(), 1, 4) or not _texts(head, (head as Array).size(), 10):
				return "data_sheet: 1-4 headings of 10 letters"
			var rows: Variant = p.get("rows")
			if not rows is Array or not _in((rows as Array).size(), 1, 7):
				return "data_sheet: 1-7 rows"
			for row: Variant in rows:
				if not row is Array or (row as Array).size() != (head as Array).size():
					return "data_sheet: every row has a cell for each heading"
				for c: Variant in row:
					if not c is String or str(c).length() > 10:
						return "data_sheet: a cell is text of 10 letters"
			for f: Variant in p.get("flag", []):
				if not f is Array or (f as Array).size() != 2 or not _in(int(f[0]), 0, (rows as Array).size() - 1) \
						or not _in(int(f[1]), 0, (head as Array).size() - 1):
					return "data_sheet: a flag is [row, column]"
			for s: Variant in p.get("strike", []):
				if typeof(s) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(s), 0, (rows as Array).size() - 1):
					return "data_sheet: strike lists rows"
		"phone_feed":
			if p.has("mark") and not FEED_PARTS.has(str(p.mark)):
				return "phone_feed: mark is one of %s" % [FEED_PARTS.keys()]
		"licence_tags":
			var tags: Variant = p.get("tags")
			if not tags is Array or not _in((tags as Array).size(), 1, 4):
				return "licence_tags: 1-4 tags"
			for t: Variant in tags:
				if not LICENCES.has(str(t)):
					return "licence_tags: a tag is one of %s" % [LICENCES]
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (tags as Array).size() - 1):
				return "licence_tags: mark is a tag's index"
		"old_master":
			if not OLD_MASTERS.has(str(p.get("what", ""))):
				return "old_master: what is one of %s" % [OLD_MASTERS]
		"colour_scheme":
			if not SCHEMES.has(str(p.get("scheme", ""))):
				return "colour_scheme: scheme is one of %s" % [SCHEMES]
			if not SchoolPictureG4Arts.WHEEL.has(str(p.get("base", ""))):
				return "colour_scheme: base is a colour of the 12-colour wheel"
			if p.has("view") and not VIEWS_SCHEME.has(str(p.view)):
				return "colour_scheme: view is wheel, swatches or scene"
		"figure_study":
			var view := str(p.get("view", ""))
			if not FIGURE_VIEWS.has(view):
				return "figure_study: view is heads, gesture or mannequin"
			if p.has("heads") and (view != "heads" or not _in(_int(p, "heads", -1), 4, 8)):
				return "figure_study: heads is 4-8 (heads view)"
			if p.has("pose") and not POSES.has(str(p.pose)):
				return "figure_study: pose is one of %s" % [POSES]
			if p.has("mark") and (view != "heads" or not FIGURE_PARTS.has(str(p.mark))):
				return "figure_study: mark is a line of %s (heads view)" % [FIGURE_PARTS.keys()]
		"world_art_piece":
			var what := str(p.get("what", ""))
			if not PIECES.has(what):
				return "world_art_piece: what is one of %s" % [PIECES]
			if p.has("mark") and not (PIECE_PARTS.get(what, {}) as Dictionary).has(str(p.mark)):
				return "world_art_piece: mark is a part of the %s" % what
		"poster_layout":
			if not DESIGNS.has(str(p.get("design", ""))):
				return "poster_layout: design is one of %s" % [DESIGNS]
			if p.has("mark") and (str(p.design) != "clear" or not POSTER_PARTS.has(str(p.mark))):
				return "poster_layout: mark is a part of the clear poster"
		"house_drawing":
			var view := str(p.get("view", ""))
			if not HOUSE_VIEWS.has(view):
				return "house_drawing: view is plan, front or side"
			if p.has("scale") and not str(p.scale) in ["1:50", "1:100"]:
				return "house_drawing: scale is 1:50 or 1:100"
			if p.has("mark") and not HOUSE_PARTS.has(str(p.mark)):
				return "house_drawing: mark is one of %s" % [HOUSE_PARTS]
		"thirds_frame":
			var s: Variant = p.get("subject")
			if not s is Array or (s as Array).size() != 2 or typeof(s[0]) not in [TYPE_INT, TYPE_FLOAT] \
					or typeof(s[1]) not in [TYPE_INT, TYPE_FLOAT] or float(s[0]) < 0.08 or float(s[0]) > 0.92 \
					or float(s[1]) < 0.12 or float(s[1]) > 0.88:
				return "thirds_frame: subject is [x, y], 0.08-0.92 across and 0.12-0.88 down"
			if p.has("thing") and not THINGS.has(str(p.thing)):
				return "thirds_frame: thing is one of %s" % [THINGS]
			if p.has("horizon") and (typeof(p.horizon) not in [TYPE_INT, TYPE_FLOAT] or float(p.horizon) < 0.1 \
					or float(p.horizon) > 0.9):
				return "thirds_frame: horizon is 0.1-0.9"
			if p.has("lines") and not str(p.lines) in ["road", "river", "fence"]:
				return "thirds_frame: lines is road, river or fence"
			if p.has("frame") and not str(p.frame) in ["arch", "trees"]:
				return "thirds_frame: frame is arch or trees"
		"carved_block":
			var rows: Variant = p.get("rows")
			if not rows is Array or not _in((rows as Array).size(), 1, 8):
				return "carved_block: 1-8 rows"
			var w := str(rows[0]).length()
			for row: Variant in rows:
				if not row is String or str(row).length() != w or not _in(w, 1, 10) \
						or str(row).replace("#", "").replace(".", "") != "":
					return "carved_block: rows of # and . (1-10), all as long"
			if not str(p.get("view", "")) in ["block", "print", "side"]:
				return "carved_block: view is block, print or side"
		"gallery_wall":
			if typeof(p.get("works")) not in [TYPE_INT, TYPE_FLOAT] or not _in(_int(p, "works", -1), 2, 5):
				return "gallery_wall: 2-5 works"
			if not HANGS.has(str(p.get("hang", ""))):
				return "gallery_wall: hang is line, tops or messy"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, _int(p, "works", 0) - 1):
				return "gallery_wall: mark is a work's index"
		"chord_chart":
			if not CHART_KEYS.has(str(p.get("key", ""))):
				return "chord_chart: key is one of %s" % [CHART_KEYS]
			var chords: Variant = p.get("chords")
			if not chords is Array or not _in((chords as Array).size(), 1, 8):
				return "chord_chart: 1-8 chords"
			for c: Variant in chords:
				if not NUMERALS.has(str(c)):
					return "chord_chart: a chord is one of %s" % [NUMERALS]
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (chords as Array).size() - 1):
				return "chord_chart: mark is a bar"
			for h: Variant in p.get("hide", []):
				if typeof(h) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(h), 0, (chords as Array).size() - 1):
					return "chord_chart: hide lists bars"
		"ornament_signs":
			if not ORNAMENTS.has(str(p.get("type", ""))):
				return "ornament_signs: type is one of %s" % [ORNAMENTS]
			if not str(p.get("note", "")) in ["D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5"]:
				return "ornament_signs: note is a white key D4-F5"
		"symphony_plan":
			if not str(p.get("view", "")) in ["movements", "sonata"]:
				return "symphony_plan: view is movements or sonata"
			for k: String in ["mark", "hide"]:
				if p.has(k) and not _in(_int(p, k, -1), 0, 3):
					return "symphony_plan: %s is a panel, 0-3" % k
		"drum_kit":
			if p.has("mark") and not KIT_PARTS.has(str(p.mark)):
				return "drum_kit: mark is one of %s" % [KIT_PARTS.keys()]
		"piano_roll":
			var notes: Variant = p.get("notes")
			if not notes is Array or not _in((notes as Array).size(), 1, 16):
				return "piano_roll: 1-16 notes"
			var pitched := 0
			for n: Variant in notes:
				var name := str(n).split(":")[0]
				if not n is String or str(n).contains("+") or SchoolSound.problem({"kind": "notes", "notes": [n]}) != "":
					return "piano_roll: '%s' is not a note or a rest" % str(n)
				if name != "-":
					pitched += 1
			if pitched == 0:
				return "piano_roll: at least one note"
			if p.has("repeat") and not _in(_int(p, "repeat", -1), 1, 4):
				return "piano_roll: repeat is 1-4"
			if _roll_beats(notes) * _int(p, "repeat", 1) > 32:
				return "piano_roll: at most 32 beats"
			var span := _roll_span(p)
			if span.y - span.x > 24:
				return "piano_roll: at most two octaves"
			for m: Variant in p.get("mark", []):
				if typeof(m) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(m), 0, (notes as Array).size() - 1):
					return "piano_roll: mark lists notes"
		"film_strip":
			var frames: Variant = p.get("frames")
			if not frames is Array or not _in((frames as Array).size(), 1, 4):
				return "film_strip: 1-4 frames"
			for f: Variant in frames:
				if not SCENES.has(str(f)):
					return "film_strip: a frame is one of %s" % [SCENES]
			if p.has("captions") and not _texts(p.captions, (frames as Array).size(), 14):
				return "film_strip: a caption (14 letters) for each frame"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (frames as Array).size() - 1):
				return "film_strip: mark is a frame's index"
		"mixer":
			var faders: Variant = p.get("faders")
			if not faders is Array or not _in((faders as Array).size(), 2, 5):
				return "mixer: 2-5 faders"
			for f: Variant in faders:
				if not f is Array or (f as Array).size() != 2 or not _short(f[0], 8) \
						or typeof(f[1]) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(f[1]), 0, 10):
					return "mixer: a fader is [name (8 letters), 0-10]"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (faders as Array).size() - 1):
				return "mixer: mark is a fader's index"
		"clef_stave":
			var clef := str(p.get("clef", ""))
			if not CLEFS.has(clef):
				return "clef_stave: clef is bass, treble or grand"
			var notes: Variant = p.get("notes")
			if not notes is Array or not _in((notes as Array).size(), 1, 8):
				return "clef_stave: 1-8 notes"
			for n: Variant in notes:
				if clef_step(str(n), clef) == -99:
					return "clef_stave: %s is not on the %s stave" % [str(n), clef]
			var values: Variant = p.get("values", [])
			if not values is Array or ((values as Array).size() > 0 and (values as Array).size() != (notes as Array).size()):
				return "clef_stave: a value for each note"
			for v: Variant in values:
				if not VALUES.has(str(v)):
					return "clef_stave: a value is one of %s" % [VALUES]
			for t: Variant in p.get("ties", []):
				var i := int(t) if typeof(t) in [TYPE_INT, TYPE_FLOAT] else -1
				if not _in(i, 0, (notes as Array).size() - 2) or str(notes[i]) != str(notes[i + 1]):
					return "clef_stave: a tie joins a note to the next one of the same pitch"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (notes as Array).size() - 1):
				return "clef_stave: mark is a note's index"
			if p.has("time") and not TIMES.has(str(p.time)):
				return "clef_stave: time is one of %s" % [TIMES.keys()]
			if bool(p.get("bars", false)) and not p.has("time"):
				return "clef_stave: bars need a time"
		_:
			return "not a grade 7 arts kind"
	return ""


static func _route_ok(route: String) -> bool:
	if route.length() < 1 or not FIRST_ROUTERS.contains(route[0]) or not LAST_ROUTERS.contains(route[route.length() - 1]):
		return false
	for i in route.length():
		if not ROUTERS.has(route[i]):
			return false
		if i > 0 and not (ROUTER_LINKS.has(route[i - 1] + route[i]) or ROUTER_LINKS.has(route[i] + route[i - 1])):
			return false
	return true


static func _ip_ok(ip: String) -> bool:
	var parts := ip.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int() or int(part) < 0 or int(part) > 255:
			return false
	return true


static func _is_capital(t: String, lo: int, hi: int) -> bool:
	if not _in(t.length(), lo, hi):
		return false
	for ch in t:
		if ch.unicode_at(0) < 65 or ch.unicode_at(0) > 90:
			return false
	return true


# --- facts the tests share -------------------------------------------------------------------------------------------

## The indexes a search checks, in order: linear from the start until it finds the target (or has checked them all);
## binary looks at the middle ((low + high) ÷ 2, rounded down) and keeps the half the target can be in.
static func search_checks(items: Array, target: int, method: String) -> Array[int]:
	var out: Array[int] = []
	if method == "linear":
		for i in items.size():
			out.append(i)
			if int(items[i]) == target:
				break
		return out
	var lo := 0
	var hi := items.size() - 1
	while lo <= hi:
		var mid := (lo + hi) / 2
		out.append(mid)
		if int(items[mid]) == target:
			break
		if int(items[mid]) < target:
			lo = mid + 1
		else:
			hi = mid - 1
	return out


## The list after `passes` passes of bubble sort (each pass compares every pair of neighbours and swaps those in the
## wrong order).
static func bubble_after(items: Array, passes: int) -> Array:
	var a := items.duplicate()
	for _p in passes:
		for i in a.size() - 1:
			if int(a[i]) > int(a[i + 1]):
				var t: Variant = a[i]
				a[i] = a[i + 1]
				a[i + 1] = t
	return a


## Merge sort's rows: the list, split in halves until every group is one item, then merged in pairs back to one sorted
## list. Each row is its groups: [[5, 2, 8, 1]], [[5, 2], [8, 1]], [[5], [2], [8], [1]], [[2, 5], [1, 8]], [[1, 2, 5, 8]].
static func merge_rows(items: Array) -> Array:
	var rows: Array = [[items.duplicate()]]
	while true:
		var last: Array = rows[-1]
		var next: Array = []
		var split := false
		for g: Array in last:
			if g.size() > 1:
				var h := (g.size() + 1) / 2
				next.append(g.slice(0, h))
				next.append(g.slice(h))
				split = true
			else:
				next.append(g)
		if not split:
			break
		rows.append(next)
	var splits := rows.size()
	for k in range(splits - 2, -1, -1):
		var merged: Array = []
		for g: Array in rows[k]:
			var s := g.duplicate()
			s.sort()
			merged.append(s)
		rows.append(merged)
	return rows


## The routers a route's packet passes through.
static func route_hops(route: String) -> int:
	return route.length()


## `text` with every capital letter moved `shift` places along the alphabet (Z goes round to A); a negative shift
## decodes.
static func caesar(text: String, shift: int) -> String:
	var out := ""
	for ch in text:
		var c := ch.unicode_at(0)
		out += String.chr(65 + posmod(c - 65 + shift, 26)) if c >= 65 and c <= 90 else ch
	return out


## A colour scheme's colours on the 12-colour wheel: complementary (the base and the colour opposite), analogous (the
## base and its two neighbours), triadic (three a third of the wheel apart), split (the base and the two beside its
## opposite), monochrome (the base only: its tints and shades), warm and cool (the five clear warm or cool colours).
static func scheme_colours(scheme: String, base: String) -> Array[String]:
	var wheel: Array[String] = SchoolPictureG4Arts.WHEEL
	var b := wheel.find(base)
	var out: Array[String] = []
	if b < 0:
		return out
	var steps: Array = {"complementary": [0, 6], "analogous": [11, 0, 1], "triadic": [0, 4, 8], "split": [0, 5, 7],
		"monochrome": [0]}.get(scheme, [])
	for s: int in steps:
		out.append(wheel[(b + s) % 12])
	if scheme == "warm":
		out.assign(SchoolPictureG4Arts.WARM)
	elif scheme == "cool":
		out.assign(SchoolPictureG4Arts.COOL)
	return out


## A key's chord for a numeral, as a chart writes it: "C", "Dm", "Bb", "F#m" (a small numeral is a minor chord).
static func chord_name(key: String, numeral: String) -> String:
	var letters := chord_letters(key, numeral)
	if letters.is_empty():
		return ""
	return letters[0] + ("m" if numeral == numeral.to_lower() else "")


## A key's chord for a numeral as its three notes' names ("A", "C", "E"): the scale's notes 1, 3 and 5 from that degree.
static func chord_letters(key: String, numeral: String) -> Array[String]:
	var out: Array[String] = []
	var d := NUMERALS.find(numeral)
	if d < 0 or not SEMIS.has(key.left(1)):
		return out
	var home := posmod(int(SEMIS[key.left(1)]) + (-1 if key.ends_with("b") else 0), 12)
	var li := LETTERS.find(key.left(1))
	for k in [0, 2, 4]:
		var step: int = d + k
		var letter := LETTERS[(li + step) % 7]
		var want := posmod(home + int(MAJOR[step % 7]), 12)
		var diff := posmod(want - int(SEMIS[letter]) + 6, 12) - 6
		out.append(letter + ("#" if diff == 1 else ("b" if diff == -1 else "")))
	return out


## The notes an ornament plays (octaves as in the note): a Baroque trill starts on the note above and turns between the
## two; a mordent is the note, the one above and the note; a turn is the note above, the note, the one below, the note.
static func ornament_notes(type: String, note: String) -> Array[String]:
	var up := _step_note(note, 1)
	var down := _step_note(note, -1)
	var out: Array[String] = []
	match type:
		"trill":
			out.assign([up, note, up, note, up, note, up, note])
		"mordent":
			out.assign([note, up, note])
		"turn":
			out.assign([up, note, down, note])
	return out


## The white-key note `k` letters up (or down) from `note` ("B4" up 1 is "C5").
static func _step_note(note: String, k: int) -> String:
	var i := LETTERS.find(note.left(1)) + 7 * int(note.right(1)) + k
	return LETTERS[posmod(i, 7)] + str(floori(i / 7.0))


## Is (x, y) on a third line (within 0.04 of 1/3 or 2/3 across or down)?
static func on_thirds(x: float, y: float) -> bool:
	return _near_third(x) or _near_third(y)


## "top left", "top right", "bottom left", "bottom right" when (x, y) is on a crossing of the thirds lines, else "".
static func power_point(x: float, y: float) -> String:
	if not (_near_third(x) and _near_third(y)):
		return ""
	return ("top " if y < 0.5 else "bottom ") + ("left" if x < 0.5 else "right")


static func _near_third(v: float) -> bool:
	return absf(v - 1.0 / 3.0) < 0.04 or absf(v - 2.0 / 3.0) < 0.04


## The print a woodcut block makes: every row mirrored, left to right.
static func print_rows(rows: Array) -> Array:
	var out: Array = []
	for row: Variant in rows:
		out.append(str(row).reverse())
	return out


## A note's place on the stave in half-gaps from its bottom line (bass: G2 = 0, up to A3 = 8 on the top line, C4 = 10 on
## a ledger line above, E2 = -2 on one below; treble: E4 = 0, C4 = -2, A5 = 10); on the grand stave the bass stave's
## steps for notes below C4 and 1000 + the treble's for C4 up; -99 when the stave doesn't show it.
static func clef_step(note: String, clef: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([2-5])$").search(note)
	if m == null:
		return -99
	var pos := LETTERS.find(m.get_string(1)) + 7 * int(m.get_string(2))   # C0 = 0
	var bass := pos - (LETTERS.find("G") + 14)
	var treble := pos - (LETTERS.find("E") + 28)
	match clef:
		"bass":
			return bass if _in(bass, -2, 10) else -99
		"treble":
			return treble if _in(treble, -2, 10) else -99
		"grand":
			if _in(treble, -2, 10):
				return 1000 + treble
			return bass if _in(bass, -2, 9) else -99
	return -99


## Where a named part is in picture `d` drawn at `size` (the card's size, as a label exercise's LABEL_BOX), in the
## card's pixels; Vector2(-1, -1) when the picture has no such part.
static func part_at(d: Dictionary, part: String, size: Vector2) -> Vector2:
	var r := Rect2(Vector2(SchoolPicture.MARGIN, SchoolPicture.MARGIN), size - Vector2(2, 2) * SchoolPicture.MARGIN)
	var share := Vector2(-1, -1)
	match str(d.get("kind", "")):
		"phone_feed":
			share = FEED_PARTS.get(part, share)
		"world_art_piece":
			share = (PIECE_PARTS.get(str(d.get("what", "")), {}) as Dictionary).get(part, share)
		"poster_layout":
			if str(d.get("design", "")) == "clear":
				share = POSTER_PARTS.get(part, share)
		"drum_kit":
			share = KIT_PARTS.get(part, share)
		"figure_study":
			if str(d.get("view", "")) == "heads" and _int(d, "heads", 8) == 8 and FIGURE_PARTS.has(part):
				var g := _figure_geometry(r, 8)
				var y: float = g.top + float(FIGURE_PARTS[part]) * float(g.head)
				return Vector2(float(g.x) + float(g.head) * 0.9, y)
		"house_drawing":
			return _house_part(r, d, part)
	if share == Vector2(-1, -1):
		return share
	return r.position + share * r.size


# --- drawing ---------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"text_code":
			_draw_text_code(pic, font, r, d)
		"list_boxes":
			_draw_list(pic, font, r, d)
		"func_machine":
			_draw_machine(pic, font, r, d)
		"search_steps":
			_draw_search(pic, font, r, d)
		"sort_bars":
			_draw_sort(pic, font, r, d)
		"internet_trip":
			_draw_trip(pic, font, r, d)
		"cipher_wheel":
			_draw_cipher(pic, font, r, d)
		"data_sheet":
			_draw_data_sheet(pic, font, r, d)
		"phone_feed":
			_draw_feed(pic, font, r, d)
		"licence_tags":
			_draw_licences(pic, font, r, d)
		"old_master":
			_draw_old_master(pic, r, d)
		"colour_scheme":
			_draw_scheme(pic, font, r, d)
		"figure_study":
			_draw_figure(pic, font, r, d)
		"world_art_piece":
			_draw_piece(pic, font, r, d)
		"poster_layout":
			_draw_poster(pic, font, r, d)
		"house_drawing":
			_draw_house(pic, font, r, d)
		"thirds_frame":
			_draw_thirds(pic, r, d)
		"carved_block":
			_draw_block(pic, font, r, d)
		"gallery_wall":
			_draw_gallery(pic, font, r, d)
		"chord_chart":
			_draw_chart(pic, font, r, d)
		"ornament_signs":
			_draw_ornament(pic, font, r, d)
		"symphony_plan":
			_draw_symphony(pic, font, r, d)
		"drum_kit":
			_draw_kit(pic, font, r, d)
		"piano_roll":
			_draw_roll(pic, font, r, d)
		"film_strip":
			_draw_film(pic, font, r, d)
		"mixer":
			_draw_mixer(pic, font, r, d)
		"clef_stave":
			_draw_clef_stave(pic, font, r, d)


# --- computing -------------------------------------------------------------------------------------------------------

static func _draw_text_code(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var box := r
	if d.has("blocks"):
		var left := Rect2(r.position, Vector2(r.size.x * 0.44, r.size.y))
		SchoolPictureG4Arts.draw(ci as Control, {"kind": "code", "lines": d.blocks}, left)
		var ax := r.position.x + r.size.x * 0.465
		_arrow(ci, Vector2(ax, r.get_center().y), Vector2(ax + r.size.x * 0.04, r.get_center().y), INK, maxf(2.0, r.size.y * 0.012))
		box = Rect2(Vector2(r.position.x + r.size.x * 0.52, r.position.y), Vector2(r.size.x * 0.48, r.size.y))
	var out: Array = d.get("output", [])
	var has_out := d.has("output")
	var code_box := box
	var out_box := Rect2()
	if has_out:
		code_box = Rect2(box.position, Vector2(box.size.x * 0.64, box.size.y))
		out_box = Rect2(Vector2(box.position.x + box.size.x * 0.67, box.position.y), Vector2(box.size.x * 0.33, box.size.y))
	var lines: Array = d.lines
	var n := lines.size()
	var numbers := bool(d.get("numbers", true))
	var mark := _int(d, "mark", -1)
	var error := _int(d, "error", -1)
	_rounded(ci, code_box, CODE_BG, 10.0)
	var rh := minf((code_box.size.y - 12.0) / maxf(n, 3), 46.0)
	var fs := clampi(int(rh * 0.62), 9, 28)
	var gutter := font.get_string_size("10", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 12.0 if numbers else 8.0
	var widest := 0.0
	for l: Variant in lines:
		widest = maxf(widest, font.get_string_size(str(l), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var room := code_box.size.x - gutter - 14.0
	while fs > 8 and widest > room:
		fs -= 1
		widest = 0.0
		for l: Variant in lines:
			widest = maxf(widest, font.get_string_size(str(l), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var y0 := code_box.position.y + (code_box.size.y - rh * n) * 0.5
	if numbers:
		ci.draw_rect(Rect2(code_box.position + Vector2(4, 4), Vector2(gutter - 4, code_box.size.y - 8)), PALE)
	var space_w := font.get_string_size("    ", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	for i in n:
		var line := str(lines[i])
		var row := Rect2(Vector2(code_box.position.x + 4, y0 + i * rh), Vector2(code_box.size.x - 8, rh))
		if i == mark:
			ci.draw_rect(row, SOFT)
			ci.draw_rect(Rect2(row.position, Vector2(4, rh)), SHADE)
		var base := row.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		if numbers:
			var num := str(i + 1)
			var nw := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_string(font, Vector2(code_box.position.x + gutter - 6 - nw, base), num, HORIZONTAL_ALIGNMENT_LEFT, -1,
				fs, GREY)
		var steps := (line.length() - line.lstrip(" ").length()) / 4
		var x := code_box.position.x + gutter + 6.0
		for s in steps:
			ci.draw_line(Vector2(x + s * space_w + 2, row.position.y), Vector2(x + s * space_w + 2, row.end.y), PALE.darkened(0.1), 1.0)
		x += steps * space_w
		var start_x := x
		for tok: Array in _code_pieces(line.strip_edges()):
			var text := str(tok[0])
			ci.draw_string(font, Vector2(x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tok[1])
			x += font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		if i == error:
			var wy := row.end.y - rh * 0.1
			var pts := PackedVector2Array()
			var k := 0
			var wx := start_x
			while wx <= maxf(x, start_x + 20.0):
				pts.append(Vector2(wx, wy + (2.0 if k % 2 == 0 else -1.5)))
				wx += 4.0
				k += 1
			ci.draw_polyline(pts, RED, 1.8, true)
			var sign_c := Vector2(code_box.end.x - rh * 0.5, row.get_center().y)
			ci.draw_circle(sign_c, rh * 0.36, RED)
			_label(ci, font, sign_c, "!", clampi(int(rh * 0.6), 8, 20), Color.WHITE)
	if has_out:
		_rounded(ci, out_box, Color("24303f"), 10.0)
		var hfs := clampi(int(fs * 0.8), 8, 16)
		ci.draw_string(font, out_box.position + Vector2(10, 8 + font.get_ascent(hfs)), "OUTPUT", HORIZONTAL_ALIGNMENT_LEFT,
			-1, hfs, Color("9fb3c8"))
		var oy := out_box.position.y + 16 + font.get_ascent(hfs) + 4
		var ofs := fs
		for o: Variant in out:
			ofs = mini(ofs, _fit(font, str(o), fs, out_box.size.x - 18))
		for i in out.size():
			ci.draw_string(font, Vector2(out_box.position.x + 10, oy + (i + 0.8) * rh * 0.95), str(out[i]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, ofs, Color("e8f0f8"))


## A line's pieces [text, colour]: words of the language, the built-in commands, "text", numbers, # comments.
static func _code_pieces(line: String) -> Array:
	var out: Array = []
	var i := 0
	while i < line.length():
		var ch := line[i]
		if ch == "#":
			out.append([line.substr(i), COMMENT])
			break
		if ch == "\"" or ch == "'":
			var j := line.find(ch, i + 1)
			j = line.length() - 1 if j < 0 else j
			out.append([line.substr(i, j - i + 1), STRING])
			i = j + 1
			continue
		if ch.is_valid_int():
			var j := i
			while j < line.length() and (line[j].is_valid_int() or line[j] == "."):
				j += 1
			out.append([line.substr(i, j - i), NUMBER])
			i = j
			continue
		if ch == "_" or ch.to_lower() != ch.to_upper():
			var j := i
			while j < line.length() and (line[j] == "_" or line[j].is_valid_int() or line[j].to_lower() != line[j].to_upper()):
				j += 1
			var w := line.substr(i, j - i)
			out.append([w, KEYWORD if KEYWORDS.has(w) else (BUILTIN if BUILTINS.has(w) else INK)])
			i = j
			continue
		out.append([ch, INK])
		i += 1
	return out


static func _draw_list(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var items: Array = d.items
	var n := items.size()
	var name := str(d.get("name", ""))
	var index := bool(d.get("index", true))
	var negative := bool(d.get("negative", false))
	var marks: Array = d.mark if d.get("mark") is Array else ([d.mark] if d.has("mark") else [])
	var hide := _int(d, "hide", -1)
	var fs := _fs(r, 0.14, 24)
	var name_w := font.get_string_size(name + " =", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 14.0 if name != "" else 0.0
	var rows_h := 1.0 + (0.45 if index else 0.0) + (0.45 if negative else 0.0)
	var bw := minf((r.size.x - name_w) / n, r.size.y / (rows_h * 1.1))
	var bh := bw * 0.9
	var total_w := name_w + bw * n
	var x0 := r.position.x + (r.size.x - total_w) * 0.5
	var y0 := r.position.y + (r.size.y - bh * rows_h) * 0.5
	if name != "":
		ci.draw_string(font, Vector2(x0, y0 + bh * 0.5 + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5), name + " =",
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	for i in n:
		var box := Rect2(Vector2(x0 + name_w + i * bw, y0), Vector2(bw, bh))
		var marked := marks.has(i) or marks.has(float(i))
		ci.draw_rect(box.grow(-2), SOFT if marked else PAPER_WHITE)
		ci.draw_rect(box.grow(-2), SHADE if marked else INK, false, 4.0 if marked else 2.0)
		var text := "?" if i == hide else str(items[i])
		_label(ci, font, box.get_center(), text, _fit(font, text, int(bh * 0.42), bw * 0.86), SHADE if i == hide else INK)
		var ifs := clampi(int(bh * 0.3), 9, 18)
		if index:
			_label(ci, font, Vector2(box.get_center().x, box.end.y + bh * 0.22), str(i), ifs, BLUE)
		if negative:
			_label(ci, font, Vector2(box.get_center().x, box.end.y + bh * (0.62 if index else 0.22)), str(i - n), ifs, GREY)


static func _draw_machine(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var params: Array = d.params
	var args: Array = d.get("args", [])
	var name := str(d.name)
	var fs := _fs(r, 0.1, 20)
	var mw := minf(r.size.x * 0.5, r.size.y * 1.3)
	var mh := r.size.y * 0.42
	var body := Rect2(Vector2(r.get_center().x - mw * 0.5, r.position.y + r.size.y * 0.3), Vector2(mw, mh))
	# the inputs: a funnel for each parameter, its argument dropping in
	var k := params.size()
	for i in k:
		var cx := body.position.x + mw * (i + 0.5) / k
		var top := r.position.y + r.size.y * 0.02
		var funnel := PackedVector2Array([Vector2(cx - mw * 0.14 / k * 2, body.position.y - r.size.y * 0.12),
			Vector2(cx + mw * 0.14 / k * 2, body.position.y - r.size.y * 0.12), Vector2(cx + mw * 0.05, body.position.y),
			Vector2(cx - mw * 0.05, body.position.y)])
		ci.draw_colored_polygon(funnel, Color("c6d3ea"))
		ci.draw_polyline(PackedVector2Array([funnel[0], funnel[3], funnel[2], funnel[1]]), INK, 2.0)
		var said := str(params[i]) + (" = " + str(args[i]) if i < args.size() else "")
		var bubble := Rect2(Vector2(cx - mw * 0.48 / k, top), Vector2(mw * 0.96 / k, r.size.y * 0.13))
		_rounded(ci, bubble, SOFT if i < args.size() else PAPER_WHITE, 8.0)
		_label(ci, font, bubble.get_center(), said, _fit(font, said, fs, bubble.size.x - 6), INK)
	_rounded(ci, body, Color("5a7fc4"), 12.0)
	_rounded(ci, body.grow(-5), Color("7b9ad6"), 9.0)
	var head := "def %s(%s):" % [name, ", ".join(PackedStringArray(params))]
	_label(ci, font, Vector2(body.get_center().x, body.position.y + mh * 0.3), head, _fit(font, head, fs, mw - 16), Color.WHITE)
	if d.has("body"):
		var ret := "return " + str(d.body)
		_label(ci, font, Vector2(body.get_center().x, body.position.y + mh * 0.68), ret, _fit(font, ret, fs, mw - 16),
			Color("fff2c4"))
	for g in 3:   # little gears on the side
		var gc := Vector2(body.end.x - mw * 0.06, body.position.y + mh * (0.25 + g * 0.25))
		ci.draw_circle(gc, mh * 0.06, Color("f2c12e"))
	# the output chute
	var chute_top := body.end.y
	var oc := Vector2(body.get_center().x, r.end.y - r.size.y * 0.1)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(oc.x - mw * 0.06, chute_top), Vector2(oc.x + mw * 0.06, chute_top),
		Vector2(oc.x + mw * 0.04, oc.y - r.size.y * 0.08), Vector2(oc.x - mw * 0.04, oc.y - r.size.y * 0.08)]), Color("c6d3ea"))
	if d.has("out"):
		var o := str(d.out)
		var ob := Rect2(Vector2(oc.x - mw * 0.2, oc.y - r.size.y * 0.09), Vector2(mw * 0.4, r.size.y * 0.16))
		_rounded(ci, ob, SHADE if o == "?" else Color("3aa845"), 10.0)
		_label(ci, font, ob.get_center(), o, _fit(font, o, int(fs * 1.2), ob.size.x - 8), Color.WHITE)


static func _draw_search(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var items: Array = d.items
	var n := items.size()
	var target := int(d.target)
	var method := str(d.method)
	var checks := search_checks(items, target, method)
	var shown := mini(_int(d, "steps", checks.size()), checks.size())
	var fs := _fs(r, 0.1, 20)
	var title := "Looking for %d (%s search)" % [target, method]
	_label(ci, font, Vector2(r.get_center().x, r.position.y + fs * 0.7), title, _fit(font, title, fs, r.size.x), INK)
	var bw := minf(r.size.x / n, r.size.y * 0.3)
	var x0 := r.position.x + (r.size.x - bw * n) * 0.5
	var y := r.position.y + r.size.y * 0.42
	# binary search: the part still to search after the shown checks
	var lo := 0
	var hi := n - 1
	if method == "binary":
		for s in shown:
			var mid := checks[s]
			if int(items[mid]) == target:
				lo = mid
				hi = mid
				break
			if int(items[mid]) < target:
				lo = mid + 1
			else:
				hi = mid - 1
	for i in n:
		var box := Rect2(Vector2(x0 + i * bw, y), Vector2(bw, bw))
		var out_of_range := method == "binary" and (i < lo or i > hi)
		var found := shown > 0 and checks[shown - 1] == i and int(items[i]) == target
		ci.draw_rect(box.grow(-1.5), Color("d7f0d9") if found else (PALE if out_of_range else PAPER_WHITE))
		ci.draw_rect(box.grow(-1.5), GREY if out_of_range else INK, false, 1.5)
		_label(ci, font, box.get_center(), str(int(items[i])), _fit(font, str(int(items[i])), int(bw * 0.42), bw * 0.9),
			GREY if out_of_range else INK)
		_label(ci, font, Vector2(box.get_center().x, box.end.y + bw * 0.25), str(i), clampi(int(bw * 0.26), 8, 14), BLUE)
	for s in shown:
		var i := checks[s]
		var c := Vector2(x0 + (i + 0.5) * bw, y + bw * 0.5)
		_ring(ci, c, bw * 0.46, SHADE, maxf(2.0, bw * 0.06))
		var tag := Vector2(c.x, y - bw * 0.42)
		ci.draw_circle(tag, bw * 0.24, SHADE)
		_label(ci, font, tag, str(s + 1), clampi(int(bw * 0.3), 8, 16), Color.WHITE)


static func _draw_sort(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var items: Array = d.items
	if str(d.get("view", "bars")) == "tree":
		_draw_merge_tree(ci, font, r, items)
		return
	var passes := _int(d, "pass", 0)
	var a := bubble_after(items, passes) if str(d.method) == "bubble" else items.duplicate()
	var n := a.size()
	var compare := _int(d, "compare", -1)
	var top := 99
	var biggest := 1
	for v: Variant in a:
		biggest = maxi(biggest, int(v))
	top = biggest
	var bw := r.size.x / n
	var floor_y := r.end.y - r.size.y * 0.12
	var hmax := r.size.y * 0.72
	for i in n:
		var h := hmax * int(a[i]) / float(top)
		var bar := Rect2(Vector2(r.position.x + i * bw + bw * 0.12, floor_y - h), Vector2(bw * 0.76, h))
		var done := str(d.method) == "bubble" and passes > 0 and i >= n - passes
		ci.draw_rect(bar, GREEN if done else BLUE)
		ci.draw_rect(bar, INK, false, 1.5)
		_label(ci, font, Vector2(bar.get_center().x, floor_y - h - r.size.y * 0.06), str(int(a[i])),
			clampi(int(minf(bw * 0.38, r.size.y * 0.1)), 9, 22), INK)
		_label(ci, font, Vector2(bar.get_center().x, floor_y + r.size.y * 0.06), str(i), clampi(int(r.size.y * 0.07), 8, 14), GREY)
	ci.draw_line(Vector2(r.position.x, floor_y), Vector2(r.end.x, floor_y), INK, 2.0)
	if compare >= 0:
		var cx := r.position.x + (compare + 1) * bw
		var ring := Rect2(Vector2(cx - bw * 0.95, floor_y - hmax - r.size.y * 0.12), Vector2(bw * 1.9, hmax + r.size.y * 0.13))
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.set_border_width_all(4)
		sb.border_color = SHADE
		sb.set_corner_radius_all(int(bw * 0.2))
		ci.draw_style_box(sb, ring)


static func _draw_merge_tree(ci: CanvasItem, font: Font, r: Rect2, items: Array) -> void:
	var rows := merge_rows(items)
	var nr := rows.size()
	var n := items.size()
	var rh := r.size.y / nr
	var cw := minf(r.size.x / (n + (n - 1) * 0.5), rh * 0.9 * 1.4)
	var fs := clampi(int(minf(cw, rh) * 0.5), 8, 20)
	var splits := (nr + 1) / 2
	for k in nr:
		var groups: Array = rows[k]
		var gaps := groups.size() - 1
		var gap := cw * 0.5
		var width := cw * n + gap * gaps
		var x := r.position.x + (r.size.x - width) * 0.5
		var y := r.position.y + k * rh + rh * 0.1
		var merged := k >= splits
		for g: Array in groups:
			var box := Rect2(Vector2(x, y), Vector2(cw * g.size(), rh * 0.8))
			ci.draw_rect(box, Color("d7f0d9") if merged else PAPER_WHITE)
			ci.draw_rect(box, GREEN.darkened(0.2) if merged else INK, false, 2.0)
			for j in g.size():
				if j > 0:
					ci.draw_line(Vector2(x + j * cw, y), Vector2(x + j * cw, y + rh * 0.8), GREY, 1.0)
				_label(ci, font, Vector2(x + (j + 0.5) * cw, y + rh * 0.4), str(int(g[j])), fs, INK)
			x += cw * g.size() + gap


static func _draw_trip(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	if str(d.view) == "dns":
		_draw_dns(ci, font, r, d)
		return
	var s := minf(r.size.y * 0.13, r.size.x * 0.07)
	var comp := r.position + Vector2(0.07, 0.5) * r.size
	var server := r.position + Vector2(0.93, 0.5) * r.size
	var at := func(letter: String) -> Vector2: return r.position + (ROUTERS[letter] as Vector2) * r.size
	for link: String in ROUTER_LINKS:
		ci.draw_line(at.call(link[0]), at.call(link[1]), GREY, 3.0)
	for l in FIRST_ROUTERS:
		ci.draw_line(comp, at.call(l), GREY, 3.0)
	for l in LAST_ROUTERS:
		ci.draw_line(server, at.call(l), GREY, 3.0)
	var routes: Array = d.get("routes", [])
	var colours: Array[Color] = [Color("e03a2f"), Color("3a7be8"), Color("3aa845")]
	var lost := _int(d, "lost", -1)
	for k in routes.size():
		var route := str(routes[k])
		var pts := PackedVector2Array([comp])
		for l in route:
			pts.append(at.call(l))
		pts.append(server)
		var off := Vector2(0, (k - (routes.size() - 1) * 0.5) * 5.0)
		for i in pts.size() - 1:
			var a: Vector2 = pts[i] + off
			var b: Vector2 = pts[i + 1] + off
			if k == lost and i >= pts.size() - 3:
				continue
			ci.draw_line(a, b, colours[k], 4.0)
		var env: Vector2 = pts[1] + off
		if k == lost:
			env = (pts[pts.size() - 3] as Vector2).lerp(pts[pts.size() - 2], 0.5) + off
		var eb := Rect2(env + Vector2(-s * 0.45, -s * 1.15), Vector2(s * 0.9, s * 0.6))
		ci.draw_rect(eb, colours[k])
		ci.draw_polyline(PackedVector2Array([eb.position, eb.get_center() + Vector2(0, s * 0.05), Vector2(eb.end.x, eb.position.y)]),
			Color.WHITE, 1.5)
		_label(ci, font, eb.get_center() + Vector2(0, s * 0.12), str(k + 1), clampi(int(s * 0.4), 8, 16), Color.WHITE)
		if k == lost:
			var q := env + Vector2(s * 0.9, -s * 0.9)
			ci.draw_line(q + Vector2(-s * 0.25, -s * 0.25), q + Vector2(s * 0.25, s * 0.25), RED, 3.0)
			ci.draw_line(q + Vector2(-s * 0.25, s * 0.25), q + Vector2(s * 0.25, -s * 0.25), RED, 3.0)
	for l: String in ROUTERS:
		var c: Vector2 = at.call(l)
		var marked := str(d.get("mark", "")) == l
		_rounded(ci, Rect2(c - Vector2(s * 0.7, s * 0.45), Vector2(s * 1.4, s * 0.9)), SHADE if marked else Color("5a6a86"), s * 0.2)
		_label(ci, font, c, l, clampi(int(s * 0.62), 9, 22), Color.WHITE)
	SchoolPictureG4Arts._device(ci, "laptop", comp, s * 1.3)
	SchoolPictureG4Arts._server(ci, server, s * 1.3)
	var fs := clampi(int(s * 0.45), 8, 16)
	_label(ci, font, comp + Vector2(0, s * 1.2), "you", fs, INK)
	_label(ci, font, server + Vector2(0, s * 1.2), "server", fs, INK)


static func _draw_dns(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var step := _int(d, "step", 4)
	# the machines in the top half, the steps written below them
	var top := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.52))
	var s := minf(top.size.y * 0.36, r.size.x * 0.08)
	var comp := top.position + Vector2(0.1, 0.74) * top.size
	var dns := top.position + Vector2(0.5, 0.2) * top.size
	var web := top.position + Vector2(0.9, 0.74) * top.size
	var fs := clampi(int(r.size.y * 0.075), 8, 16)
	SchoolPictureG4Arts._device(ci, "laptop", comp, s)
	SchoolPictureG4Arts._server(ci, dns, s)
	SchoolPictureG4Arts._server(ci, web, s)
	_label(ci, font, comp + Vector2(0, s * 0.85), "you", fs, INK)
	_label(ci, font, dns + Vector2(s * 1.9, 0), "DNS server", fs, INK)
	_label(ci, font, web + Vector2(0, s * 0.85), "web server", fs, INK)
	var said: Array[String] = ["Where is %s?" % d.domain, "It is at %s." % d.ip, "Please send me the page.",
		"Here is the page."]
	var legs: Array = [[comp, dns, 1.0], [dns, comp, 1.0], [comp, web, 1.0], [web, comp, 1.0]]   # there and back: either side
	for i in 4:
		if i + 1 > step:
			break
		var a: Vector2 = legs[i][0]
		var b: Vector2 = legs[i][1]
		var side: float = legs[i][2]
		var dir := (b - a).normalized()
		var normal := Vector2(-dir.y, dir.x) * side * s * 0.5
		var from := a + dir * s * 0.8 + normal
		var to := b - dir * s * 0.8 + normal
		var col := SHADE if i + 1 == step else BLUE
		_arrow(ci, from, to, col, 3.0)
		var tag := from.lerp(to, 0.5 if i < 2 else (0.3 if i == 2 else 0.7)) + normal * 0.9
		ci.draw_circle(tag, fs * 0.75, col)
		_label(ci, font, tag, str(i + 1), fs, Color.WHITE)
		var row := Vector2(r.position.x + r.size.x * (0.02 + (i / 2) * 0.5), r.position.y + r.size.y * (0.64 + (i % 2) * 0.18))
		var t := "%d  %s" % [i + 1, said[i]]
		var tfs := _fit(font, t, fs, r.size.x * 0.47)
		ci.draw_string(font, row + Vector2(0, tfs * 0.4), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, col.darkened(0.25))


static func _draw_cipher(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var shift := _int(d, "shift", 0)
	var word := str(d.get("word", ""))
	var decode := bool(d.get("decode", false))
	var word_h := r.size.y * 0.3 if word != "" else 0.0
	var wheel_box := Rect2(r.position, Vector2(r.size.x if word == "" else r.size.x * 0.55, r.size.y))
	var rad := minf(wheel_box.size.x, wheel_box.size.y) * 0.48
	var c := wheel_box.get_center()
	var mark := str(d.get("mark", ""))
	ci.draw_circle(c, rad, Color("fdf1d6"))
	ci.draw_circle(c, rad * 0.74, Color("d9e6fb"))
	_ring(ci, c, rad, INK, 2.0)
	_ring(ci, c, rad * 0.74, INK, 1.5)
	_ring(ci, c, rad * 0.48, INK, 1.5)
	var fs := clampi(int(rad * 0.13), 7, 18)
	for i in 26:
		var ang := -PI / 2.0 + TAU * i / 26.0
		var dir := Vector2(cos(ang), sin(ang))
		var plain := String.chr(65 + i)
		var code := String.chr(65 + (i + shift) % 26)
		var on := plain == mark
		if on:
			var tip := c + dir * rad * 0.99
			ci.draw_line(c + dir * rad * 0.5, tip, SHADE, maxf(3.0, rad * 0.05))
		_label(ci, font, c + dir * rad * 0.87, plain, fs, SHADE if on else INK)
		_label(ci, font, c + dir * rad * 0.61, code, fs, SHADE if on else COBALT)
		ci.draw_line(c + dir * rad * 0.74, c + dir * rad * 0.77, GREY, 1.0)
	var cfs := clampi(int(rad * 0.2), 8, 22)
	_label(ci, font, c + Vector2(0, -cfs * 0.55), "shift", clampi(int(cfs * 0.7), 7, 16), INK)
	_label(ci, font, c + Vector2(0, cfs * 0.55), str(shift), cfs, SHADE)
	if word == "":
		return
	var right := Rect2(Vector2(r.position.x + r.size.x * 0.58, r.position.y), Vector2(r.size.x * 0.42, r.size.y))
	var other := caesar(word, -shift if decode else shift)
	var top_word := word
	var bottom_word := other
	var cw := minf(right.size.x / word.length(), word_h * 0.8)
	var x0 := right.position.x + (right.size.x - cw * word.length()) * 0.5
	var y1 := right.get_center().y - cw * 0.7
	var y2 := right.get_center().y + cw * 0.7
	var wfs := clampi(int(cw * 0.6), 8, 26)
	_label(ci, font, Vector2(right.get_center().x, y1 - cw * 0.9), "code" if decode else "plain", clampi(int(wfs * 0.6), 8, 16), GREY)
	_label(ci, font, Vector2(right.get_center().x, y2 + cw * 0.9), "plain" if decode else "code", clampi(int(wfs * 0.6), 8, 16), GREY)
	for i in word.length():
		var bx := x0 + (i + 0.5) * cw
		ci.draw_rect(Rect2(Vector2(bx - cw * 0.44, y1 - cw * 0.44), Vector2(cw * 0.88, cw * 0.88)), PAPER_WHITE)
		ci.draw_rect(Rect2(Vector2(bx - cw * 0.44, y1 - cw * 0.44), Vector2(cw * 0.88, cw * 0.88)), INK, false, 1.5)
		_label(ci, font, Vector2(bx, y1), top_word[i], wfs, INK)
		ci.draw_rect(Rect2(Vector2(bx - cw * 0.44, y2 - cw * 0.44), Vector2(cw * 0.88, cw * 0.88)), Color("d9e6fb"))
		ci.draw_rect(Rect2(Vector2(bx - cw * 0.44, y2 - cw * 0.44), Vector2(cw * 0.88, cw * 0.88)), INK, false, 1.5)
		_label(ci, font, Vector2(bx, y2), bottom_word[i], wfs, COBALT)


static func _draw_data_sheet(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var head: Array = d.head
	var rows: Array = d.rows
	var cols := head.size()
	var nr := rows.size() + 1
	var rh := minf(r.size.y / nr, 40.0)
	var cw := r.size.x / cols
	var y0 := r.position.y + (r.size.y - rh * nr) * 0.5
	var fs := clampi(int(rh * 0.5), 8, 20)
	var flags: Array = d.get("flag", [])
	var strikes: Array = d.get("strike", [])
	for c in cols:
		var cell := Rect2(Vector2(r.position.x + c * cw, y0), Vector2(cw, rh))
		ci.draw_rect(cell, Color("dfe7f5"))
		ci.draw_rect(cell, INK, false, 1.0)
		_label(ci, font, cell.get_center(), str(head[c]), _fit(font, str(head[c]), fs, cw - 6), INK)
	for i in rows.size():
		var struck := strikes.has(i) or strikes.has(float(i))
		for c in cols:
			var cell := Rect2(Vector2(r.position.x + c * cw, y0 + (i + 1) * rh), Vector2(cw, rh))
			var flagged := false
			for f: Array in flags:
				flagged = flagged or (int(f[0]) == i and int(f[1]) == c)
			ci.draw_rect(cell, SOFT if flagged else (PALE if struck else PAPER_WHITE))
			ci.draw_rect(cell, GREY, false, 1.0)
			var t := str(rows[i][c])
			_label(ci, font, cell.get_center(), t, _fit(font, t, fs, cw - 6), GREY if struck else INK)
			if flagged:
				var sb := StyleBoxFlat.new()
				sb.draw_center = false
				sb.set_border_width_all(3)
				sb.border_color = SHADE
				sb.set_corner_radius_all(int(rh * 0.4))
				ci.draw_style_box(sb, cell.grow(-2))
		if struck:
			var y := y0 + (i + 1.5) * rh
			ci.draw_line(Vector2(r.position.x + 4, y), Vector2(r.position.x + cols * cw - 4, y), RED, 2.5)


static func _draw_feed(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var labels := bool(d.get("labels", false))
	var mark := str(d.get("mark", ""))
	var ph := r.size.y
	var pw := r.size.x * 0.3   # the phone spans 0.2-0.5 across, so FEED_PARTS land on it at any card size
	var phone := Rect2(Vector2(r.position.x + r.size.x * 0.2, r.position.y), Vector2(pw, ph))
	_rounded(ci, phone, Color("2b3140"), pw * 0.12)
	var screen := phone.grow(-pw * 0.06)
	_rounded(ci, screen, Color("f4f6fb"), pw * 0.06)
	# the post: a picture of a castle and a buddy
	var post := Rect2(screen.position + Vector2(screen.size.x * 0.06, screen.size.y * 0.1),
		Vector2(screen.size.x * 0.88, screen.size.y * 0.52))
	ci.draw_rect(post, Color("bfe0f7"))
	ci.draw_rect(Rect2(post.position + Vector2(0, post.size.y * 0.7), Vector2(post.size.x, post.size.y * 0.3)), Color("8cc56a"))
	var tower := Rect2(post.position + Vector2(post.size.x * 0.2, post.size.y * 0.25), Vector2(post.size.x * 0.2, post.size.y * 0.5))
	ci.draw_rect(tower, Color("b9a67f"))
	for k in 3:
		ci.draw_rect(Rect2(tower.position + Vector2(k * tower.size.x * 0.36, -tower.size.x * 0.18), Vector2(tower.size.x * 0.25,
			tower.size.x * 0.2)), Color("b9a67f"))
	ci.draw_circle(post.position + Vector2(post.size.x * 0.55, post.size.y * 0.62), post.size.y * 0.11, Color("f2c12e"))
	# likes: a heart and a number, at the post's right
	var heart_c := r.position + (FEED_PARTS["likes"] as Vector2) * r.size
	_heart(ci, heart_c, pw * 0.07, RED)
	var fs := clampi(int(pw * 0.08), 7, 16)
	_label(ci, font, heart_c + Vector2(0, pw * 0.11), "999", fs, INK)
	# the notification badge
	var bell := r.position + (FEED_PARTS["notification"] as Vector2) * r.size
	ci.draw_circle(bell, pw * 0.07, RED)
	_label(ci, font, bell, "9", fs, Color.WHITE)
	# autoplay: the next video in 3
	var auto_c := r.position + (FEED_PARTS["autoplay"] as Vector2) * r.size
	var auto := Rect2(Vector2(screen.position.x + screen.size.x * 0.06, auto_c.y - screen.size.y * 0.045),
		Vector2(screen.size.x * 0.88, screen.size.y * 0.09))
	_rounded(ci, auto, Color("24303f"), 6.0)
	var t := "Next video in 3"
	_label(ci, font, auto.get_center(), t, _fit(font, t, fs, auto.size.x - 8), Color.WHITE)
	# endless scroll: the next post peeking at the bottom
	var next := Rect2(Vector2(post.position.x, screen.position.y + screen.size.y * 0.86), Vector2(post.size.x, screen.size.y * 0.14))
	ci.draw_rect(next, Color("f7d9a6"))
	var tip := r.position + (FEED_PARTS["endless scroll"] as Vector2) * r.size
	ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-pw * 0.06, -pw * 0.03), tip + Vector2(pw * 0.06, -pw * 0.03),
		tip + Vector2(0, pw * 0.04)]), INK)
	if mark != "" and FEED_PARTS.has(mark):
		_ring(ci, r.position + (FEED_PARTS[mark] as Vector2) * r.size, pw * 0.13, SHADE, 4.0)
	if labels:
		var lfs := clampi(int(r.size.y * 0.07), 9, 18)
		for part: String in FEED_PARTS:
			var p: Vector2 = r.position + (FEED_PARTS[part] as Vector2) * r.size
			var lx := r.position.x + r.size.x * 0.58
			ci.draw_line(p, Vector2(lx - 4, p.y), GREY, 1.5)
			ci.draw_string(font, Vector2(lx, p.y + lfs * 0.35), part, HORIZONTAL_ALIGNMENT_LEFT, -1, lfs, INK)


static func _heart(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-s * 0.5, -s * 0.3), s * 0.55, col)
	ci.draw_circle(c + Vector2(s * 0.5, -s * 0.3), s * 0.55, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.02, -s * 0.12), c + Vector2(s * 1.02, -s * 0.12),
		c + Vector2(0, s * 1.0)]), col)


static func _draw_licences(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var tags: Array = d.tags
	var n := tags.size()
	var names := bool(d.get("names", true))
	var mark := _int(d, "mark", -1)
	var tw := r.size.x / n
	var th := minf(r.size.y * (0.55 if names else 0.8), tw * 0.62)
	var fs := clampi(int(th * 0.2), 8, 18)
	for i in n:
		var tag := str(tags[i])
		var box := Rect2(Vector2(r.position.x + i * tw + tw * 0.06, r.get_center().y - th * (0.75 if names else 0.5)),
			Vector2(tw * 0.88, th))
		_rounded(ci, box, Color("24303f"), th * 0.2)
		if i == mark:
			var sb := StyleBoxFlat.new()
			sb.draw_center = false
			sb.set_border_width_all(4)
			sb.border_color = SHADE
			sb.set_corner_radius_all(int(th * 0.24))
			ci.draw_style_box(sb, box.grow(4))
		var icons: Array[String] = []
		match tag:
			"copyright":
				icons = ["copyright"]
			"CC0":
				icons = ["cc", "zero"]
			_:
				icons = ["cc", "by"]
				if tag.ends_with("SA"):
					icons.append("sa")
				elif tag.ends_with("NC"):
					icons.append("nc")
				elif tag.ends_with("ND"):
					icons.append("nd")
		var isz := minf(box.size.y * 0.52, box.size.x / (icons.size() + 0.6))
		for k in icons.size():
			var ic := Vector2(box.position.x + box.size.x * (k + 0.5) / icons.size(), box.position.y + box.size.y * 0.4)
			_licence_icon(ci, font, ic, isz * 0.46, icons[k])
		var label := "All rights" if tag == "copyright" else tag
		_label(ci, font, Vector2(box.get_center().x, box.end.y - box.size.y * 0.14), label, _fit(font, label, fs, box.size.x - 6),
			Color.WHITE)
		if names:
			var nm := str(LICENCE_NAMES[tag])
			_label(ci, font, Vector2(box.get_center().x, box.end.y + th * 0.3), nm, _fit(font, nm, fs, tw * 0.96), INK)


static func _licence_icon(ci: CanvasItem, font: Font, c: Vector2, rad: float, what: String) -> void:
	ci.draw_circle(c, rad, Color.WHITE)
	var lw := maxf(1.5, rad * 0.16)
	match what:
		"copyright", "cc":
			var a0 := 0.7 if what == "copyright" else 0.6
			var pts := PackedVector2Array()
			if what == "copyright":
				for i in 17:
					var t := a0 + (TAU - 2.0 * a0) * i / 16.0
					pts.append(c + Vector2(cos(t), sin(t)) * rad * 0.52)
				ci.draw_polyline(pts, INK, lw, true)
			else:
				for off: float in [-0.3, 0.3]:
					var q := PackedVector2Array()
					for i in 13:
						var t := a0 + (TAU - 2.0 * a0) * i / 12.0
						q.append(c + Vector2(off * rad, 0) + Vector2(cos(t), sin(t)) * rad * 0.3)
					ci.draw_polyline(q, INK, lw, true)
		"zero":
			SchoolPictureG4Arts._ellipse_line(ci, c, Vector2(rad * 0.32, rad * 0.5))
			ci.draw_line(c + Vector2(-rad * 0.2, rad * 0.35), c + Vector2(rad * 0.2, -rad * 0.35), INK, lw)
		"by":
			ci.draw_circle(c + Vector2(0, -rad * 0.45), rad * 0.17, INK)
			ci.draw_rect(Rect2(c + Vector2(-rad * 0.22, -rad * 0.22), Vector2(rad * 0.44, rad * 0.5)), INK)
			ci.draw_line(c + Vector2(-rad * 0.1, rad * 0.25), c + Vector2(-rad * 0.1, rad * 0.62), INK, lw)
			ci.draw_line(c + Vector2(rad * 0.1, rad * 0.25), c + Vector2(rad * 0.1, rad * 0.62), INK, lw)
		"sa":
			var pts := PackedVector2Array()
			for i in 15:
				var t := -2.4 + 4.4 * i / 14.0
				pts.append(c + Vector2(cos(t), sin(t)) * rad * 0.5)
			ci.draw_polyline(pts, INK, lw, true)
			var tip := pts[0]
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-rad * 0.22, -rad * 0.05), tip + Vector2(rad * 0.22, -rad * 0.05),
				tip + Vector2(0, rad * 0.25)]), INK)
		"nc":
			ci.draw_circle(c, rad * 0.5, GOLD)
			_label(ci, font, c, "G", clampi(int(rad * 0.7), 7, 20), INK)
			ci.draw_line(c + Vector2(-rad * 0.7, -rad * 0.7), c + Vector2(rad * 0.7, rad * 0.7), RED, lw * 1.3)
		"nd":
			ci.draw_line(c + Vector2(-rad * 0.45, -rad * 0.16), c + Vector2(rad * 0.45, -rad * 0.16), INK, lw * 1.3)
			ci.draw_line(c + Vector2(-rad * 0.45, rad * 0.16), c + Vector2(rad * 0.45, rad * 0.16), INK, lw * 1.3)


# --- art -------------------------------------------------------------------------------------------------------------

static func _draw_old_master(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var lines := bool(d.get("lines", false))
	match str(d.what):
		"mona_lisa":
			var w := minf(r.size.x, r.size.y * 0.72)
			var b := Rect2(Vector2(r.get_center().x - w * 0.5, r.position.y), Vector2(w, r.size.y))
			ci.draw_rect(b, Color("7a4a24"))
			var p := b.grow(-w * 0.04)
			# the misty landscape: blue and pale far away (aerial perspective), warmer and darker near
			ci.draw_rect(p, Color("a9b9a4"))
			ci.draw_rect(Rect2(p.position, Vector2(p.size.x, p.size.y * 0.3)), Color("c3cfc0"))
			ci.draw_colored_polygon(PackedVector2Array([p.position + Vector2(0, p.size.y * 0.34), p.position + Vector2(p.size.x * 0.2, p.size.y * 0.24),
				p.position + Vector2(p.size.x * 0.35, p.size.y * 0.32), p.position + Vector2(p.size.x * 0.35, p.size.y * 0.5),
				p.position + Vector2(0, p.size.y * 0.5)]), Color("8fa7a6"))
			ci.draw_colored_polygon(PackedVector2Array([p.position + Vector2(p.size.x, p.size.y * 0.3), p.position + Vector2(p.size.x * 0.78, p.size.y * 0.22),
				p.position + Vector2(p.size.x * 0.65, p.size.y * 0.33), p.position + Vector2(p.size.x * 0.65, p.size.y * 0.5),
				p.position + Vector2(p.size.x, p.size.y * 0.5)]), Color("8fa7a6"))
			var road := PackedVector2Array()
			for i in 12:
				var t := i / 11.0
				road.append(p.position + Vector2(p.size.x * (0.1 + 0.12 * sin(t * 5.0)), p.size.y * (0.52 - t * 0.2)))
			ci.draw_polyline(road, Color("b8864a"), maxf(2.0, w * 0.012))
			# the sitter: dark dress, folded hands, a soft face (sfumato: no hard lines)
			var cx := p.get_center().x
			var shoulders := p.position.y + p.size.y * 0.5
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - p.size.x * 0.46, p.end.y), Vector2(cx - p.size.x * 0.36, shoulders),
				Vector2(cx - p.size.x * 0.1, shoulders - p.size.y * 0.04), Vector2(cx + p.size.x * 0.1, shoulders - p.size.y * 0.04),
				Vector2(cx + p.size.x * 0.36, shoulders), Vector2(cx + p.size.x * 0.46, p.end.y)]), Color("2e2a1f"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - p.size.x * 0.13, shoulders - p.size.y * 0.04),
				Vector2(cx + p.size.x * 0.13, shoulders - p.size.y * 0.04), Vector2(cx, shoulders + p.size.y * 0.1)]), Color("d9ae7e"))
			var face := Vector2(cx, p.position.y + p.size.y * 0.33)
			for k in 4:   # sfumato: the face's edge fades in soft steps
				SchoolPictureG4Arts._ellipse(ci, face, Vector2(p.size.x * (0.13 + 0.012 * (3 - k)), p.size.y * (0.12 + 0.01 * (3 - k))),
					Color("d9ae7e", 0.35 + 0.2 * k))
			SchoolPictureG4Arts._ellipse(ci, face + Vector2(0, -p.size.y * 0.06), Vector2(p.size.x * 0.16, p.size.y * 0.08), Color("3b2a1a"))
			ci.draw_rect(Rect2(face + Vector2(-p.size.x * 0.17, -p.size.y * 0.06), Vector2(p.size.x * 0.05, p.size.y * 0.2)), Color("3b2a1a"))
			ci.draw_rect(Rect2(face + Vector2(p.size.x * 0.12, -p.size.y * 0.06), Vector2(p.size.x * 0.05, p.size.y * 0.2)), Color("3b2a1a"))
			for e: float in [-1.0, 1.0]:
				ci.draw_circle(face + Vector2(e * p.size.x * 0.05, 0), p.size.x * 0.012, Color("3b2a1a"))
			var smile := PackedVector2Array([face + Vector2(-p.size.x * 0.035, p.size.y * 0.055), face + Vector2(0, p.size.y * 0.062),
				face + Vector2(p.size.x * 0.035, p.size.y * 0.055)])
			ci.draw_polyline(smile, Color("8a5a3a"), maxf(1.0, w * 0.006))
			var hands := Vector2(cx, p.position.y + p.size.y * 0.86)
			SchoolPictureG4Arts._ellipse(ci, hands, Vector2(p.size.x * 0.14, p.size.y * 0.04), Color("d9ae7e"))
			if lines:   # the calm triangle (a pyramid): from the head down to the hands and the arms
				var tri := PackedVector2Array([face + Vector2(0, -p.size.y * 0.16), Vector2(cx - p.size.x * 0.44, p.end.y - p.size.y * 0.04),
					Vector2(cx + p.size.x * 0.44, p.end.y - p.size.y * 0.04), face + Vector2(0, -p.size.y * 0.16)])
				ci.draw_polyline(tri, SHADE, 3.0)
		"school_athens":
			var b := r
			var vp := Vector2(b.get_center().x, b.position.y + b.size.y * 0.52)
			ci.draw_rect(b, Color("e9dcc0"))
			# the floor's tiles and the walls, all lines running to one vanishing point
			var floor_y := b.position.y + b.size.y * 0.72
			ci.draw_rect(Rect2(Vector2(b.position.x, floor_y), Vector2(b.size.x, b.end.y - floor_y)), Color("c9b48f"))
			for k in range(-4, 5):
				var foot := Vector2(vp.x + k * b.size.x * 0.12, b.end.y)
				var t := (floor_y - vp.y) / (foot.y - vp.y)
				ci.draw_line(vp.lerp(foot, t), foot, Color("a88f63"), 1.5)
			for k in 3:   # three arches, each smaller and further
				var s := 1.0 - k * 0.27
				var aw := b.size.x * 0.7 * s
				var ah := b.size.y * 0.62 * s
				var base_y := vp.y + (floor_y - vp.y) * s
				var a := Rect2(Vector2(vp.x - aw * 0.5, base_y - ah), Vector2(aw, ah))
				var arch := PackedVector2Array()
				arch.append(Vector2(a.position.x, a.end.y))
				for i in 17:
					var t := PI + PI * i / 16.0
					arch.append(Vector2(vp.x + cos(t) * aw * 0.5, a.position.y + aw * 0.5 + sin(t) * aw * 0.5))
				arch.append(a.end)
				ci.draw_polyline(arch, Color("8a7650"), maxf(2.0, 6.0 * s))
			ci.draw_rect(Rect2(Vector2(b.position.x, b.position.y), Vector2(b.size.x * 0.08, floor_y - b.position.y)), Color("b9a27a"))
			ci.draw_rect(Rect2(Vector2(b.end.x - b.size.x * 0.08, b.position.y), Vector2(b.size.x * 0.08, floor_y - b.position.y)), Color("b9a27a"))
			# the two thinkers in the middle, at the vanishing point, and groups either side
			for k: float in [-1.0, 1.0]:
				_person(ci, Vector2(vp.x + k * b.size.x * 0.025, floor_y - b.size.y * 0.02), b.size.y * 0.2,
					Color("c0503a") if k < 0 else Color("3a6fc0"))
			for k in 8:
				var side := -1.0 if k < 4 else 1.0
				var x := vp.x + side * b.size.x * (0.14 + (k % 4) * 0.08)
				_person(ci, Vector2(x, floor_y + (k % 2) * b.size.y * 0.05), b.size.y * 0.17,
					[Color("6a8a4a"), Color("b07a3a"), Color("7a5aa0"), Color("3a8a8a")][k % 4])
			if lines:
				for q: Vector2 in [b.position, Vector2(b.end.x, b.position.y), Vector2(b.position.x, b.end.y), b.end,
						Vector2(b.position.x, floor_y), Vector2(b.end.x, floor_y)]:
					ci.draw_line(q, vp, SHADE, 2.0)
				ci.draw_circle(vp, 5.0, SHADE)
		"vitruvian_man":
			var s := minf(r.size.x, r.size.y)
			var b := Rect2(r.get_center() - Vector2(s, s) * 0.5, Vector2(s, s))
			ci.draw_rect(b, Color("efe3c4"))
			var side := s * 0.8
			var sq := Rect2(Vector2(b.get_center().x - side * 0.5, b.end.y - side - s * 0.04), Vector2(side, side))
			var navel := Vector2(b.get_center().x, sq.end.y - side * 0.62)
			var rad := side * 0.62
			ci.draw_rect(sq, Color("7a4a24"), false, 2.0)
			_ring(ci, navel, rad, Color("7a4a24"), 2.0)
			var head_c := Vector2(sq.get_center().x, sq.position.y + side * 0.065)
			var ink := Color("5a3a1a")
			var lw := maxf(2.0, s * 0.012)
			ci.draw_circle(head_c, side * 0.06, ink)
			var neck := head_c + Vector2(0, side * 0.08)
			var hip := Vector2(sq.get_center().x, sq.position.y + side * 0.5)
			ci.draw_line(neck, hip, ink, lw * 2.0)
			var shoulder := neck + Vector2(0, side * 0.06)
			# arms straight out: the arm span is as wide as the man is tall (the square)
			ci.draw_line(shoulder, Vector2(sq.position.x, shoulder.y), ink, lw)
			ci.draw_line(shoulder, Vector2(sq.end.x, shoulder.y), ink, lw)
			# arms raised and legs apart touch the circle
			for k: float in [-1.0, 1.0]:
				var hand := navel + Vector2(cos(-PI / 2.0 + k * 1.0), sin(-PI / 2.0 + k * 1.0)) * rad
				ci.draw_line(shoulder, hand, Color(ink, 0.55), lw)
				var foot := navel + Vector2(cos(PI / 2.0 - k * 0.52), sin(PI / 2.0 - k * 0.52)) * rad
				ci.draw_line(hip, foot, Color(ink, 0.55), lw)
				ci.draw_line(hip, Vector2(hip.x + k * side * 0.05, sq.end.y), ink, lw)
			if lines:   # halfway down the figure is the hips
				ci.draw_line(Vector2(sq.position.x, hip.y), Vector2(sq.end.x, hip.y), SHADE, 2.0)


## A small standing figure (a robe and a head) whose feet are at `foot`.
static func _person(ci: CanvasItem, foot: Vector2, h: float, col: Color) -> void:
	var body := PackedVector2Array([foot + Vector2(-h * 0.16, 0), foot + Vector2(h * 0.16, 0), foot + Vector2(h * 0.1, -h * 0.78),
		foot + Vector2(-h * 0.1, -h * 0.78)])
	ci.draw_colored_polygon(body, col)
	ci.draw_circle(foot + Vector2(0, -h * 0.87), h * 0.1, Color("d9ae7e"))


static func _draw_scheme(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var scheme := str(d.scheme)
	var base := str(d.base)
	var colours := scheme_colours(scheme, base)
	var view := str(d.get("view", "wheel"))
	var fs := _fs(r, 0.09, 18)
	match view:
		"wheel":
			var marks: Array = []
			marks.assign(colours)
			var wd := {"kind": "colour_wheel", "size": 12, "mark": marks, "names": false}
			if scheme == "complementary":
				wd["line"] = colours
			SchoolPictureG4Arts.draw(ci as Control, wd, r)
			if scheme in ["triadic", "split"]:
				var s := minf(r.size.x, r.size.y)
				var c := r.get_center()
				var pts := PackedVector2Array()
				for col: String in colours:
					var i := SchoolPictureG4Arts.WHEEL.find(col)
					var ang := -PI / 2.0 + TAU * i / 12.0
					pts.append(c + Vector2(cos(ang), sin(ang)) * s * 0.3)
				pts.append(pts[0])
				ci.draw_polyline(pts, INK, 3.0, true)
		"swatches":
			var shades: Array[Color] = []
			if scheme == "monochrome":
				var col: Color = SchoolPictureArts.COLOURS[base]
				for t: float in [0.65, 0.35, 0.0]:
					shades.append(col.lerp(Color.WHITE, t))
				for t: float in [0.3, 0.55]:
					shades.append(col.lerp(Color.BLACK, t))
			else:
				for c: String in colours:
					shades.append(SchoolPictureArts.COLOURS[c])
			var n := shades.size()
			var sw := r.size.x / n
			for i in n:
				var box := Rect2(Vector2(r.position.x + i * sw + sw * 0.06, r.position.y + r.size.y * 0.08), Vector2(sw * 0.88, r.size.y * 0.66))
				_rounded(ci, box, shades[i], 8.0)
				if scheme != "monochrome":
					_label(ci, font, Vector2(box.get_center().x, r.end.y - r.size.y * 0.1), colours[i], _fit(font, colours[i], fs, sw * 0.98), INK)
		"scene":
			var pal: Array[Color] = []
			if scheme == "monochrome":
				var col: Color = SchoolPictureArts.COLOURS[base]
				pal.assign([col.lerp(Color.WHITE, 0.7), col.lerp(Color.WHITE, 0.35), col, col.lerp(Color.BLACK, 0.35), col.lerp(Color.BLACK, 0.6)])
			else:
				for c: String in colours:
					pal.append(SchoolPictureArts.COLOURS[c])
				while pal.size() < 5:
					var k := pal.size()
					pal.append((pal[k % colours.size()] as Color).lerp(Color.WHITE if k % 2 == 0 else Color.BLACK, 0.35))
			_scene(ci, r, pal)


## A small landscape painted with `pal` (5 colours: sky, far hills, near hills, the sun, the tree and house).
static func _scene(ci: CanvasItem, r: Rect2, pal: Array[Color]) -> void:
	ci.draw_rect(r, pal[0])
	ci.draw_circle(r.position + Vector2(r.size.x * 0.78, r.size.y * 0.25), r.size.y * 0.12, pal[3])
	var far := PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.position.y + r.size.y * 0.55)])
	for i in 9:
		far.append(r.position + Vector2(r.size.x * i / 8.0, r.size.y * (0.5 + 0.08 * sin(i * 1.3))))
	far.append(r.end)
	ci.draw_colored_polygon(far, pal[1])
	var near := PackedVector2Array([Vector2(r.position.x, r.end.y)])
	for i in 9:
		near.append(r.position + Vector2(r.size.x * i / 8.0, r.size.y * (0.72 + 0.06 * cos(i * 0.9))))
	near.append(r.end)
	ci.draw_colored_polygon(near, pal[2])
	var trunk := r.position + Vector2(r.size.x * 0.22, r.size.y * 0.75)
	ci.draw_rect(Rect2(trunk - Vector2(r.size.x * 0.012, r.size.y * 0.15), Vector2(r.size.x * 0.024, r.size.y * 0.15)), pal[4])
	ci.draw_circle(trunk - Vector2(0, r.size.y * 0.2), r.size.y * 0.1, pal[4])
	var house := Rect2(r.position + Vector2(r.size.x * 0.52, r.size.y * 0.6), Vector2(r.size.x * 0.12, r.size.y * 0.14))
	ci.draw_rect(house, pal[3].lerp(Color.WHITE, 0.3))
	ci.draw_colored_polygon(PackedVector2Array([house.position, Vector2(house.end.x, house.position.y),
		Vector2(house.get_center().x, house.position.y - r.size.y * 0.08)]), pal[4])


## A figure `heads` heads tall: where it stands and how big a head is, at a card's inner rectangle.
static func _figure_geometry(r: Rect2, heads: int) -> Dictionary:
	var head := (r.size.y * 0.94) / 8.0
	var top := r.position.y + r.size.y * 0.03 + (8 - heads) * head
	return {"head": head, "top": top, "x": r.position.x + r.size.x * 0.3}


static func _draw_figure(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var view := str(d.view)
	if view == "heads":
		var heads := _int(d, "heads", 8)
		var g := _figure_geometry(r, heads)
		var h: float = g.head
		var top: float = g.top
		var cx: float = g.x
		var fs := clampi(int(h * 0.42), 8, 16)
		# the ruler of heads beside the figure
		for k in heads + 1:
			var y := top + k * h
			ci.draw_line(Vector2(cx - h * 1.6, y), Vector2(cx + h * 1.6, y), Color(GREY, 0.6), 1.0)
			if k < heads:
				SchoolPictureG4Arts._ellipse(ci, Vector2(cx - h * 2.4, y + h * 0.5), Vector2(h * 0.3, h * 0.42), Color("e6d3b8"))
				_label(ci, font, Vector2(cx - h * 2.4, y + h * 0.5), str(k + 1), fs, INK)
		_standing(ci, Vector2(cx, top), h, heads, Color("7b9ad6"))
		var labels := bool(d.get("labels", false))
		var mark := str(d.get("mark", ""))
		if heads == 8:
			for part: String in FIGURE_PARTS:
				var y: float = top + float(FIGURE_PARTS[part]) * h
				if part == mark:
					ci.draw_line(Vector2(cx - h * 1.7, y), Vector2(cx + h * 1.7, y), SHADE, 3.0)
				if labels:
					ci.draw_string(font, Vector2(cx + h * 2.0, y + fs * 0.35), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		return
	var pose := str(d.get("pose", "stand"))
	var s := minf(r.size.y, r.size.x * 0.9)
	var box := Rect2(r.get_center() - Vector2(s, s) * 0.5, Vector2(s, s))
	var j := _pose_joints(pose)
	var at := func(k: String) -> Vector2: return box.position + (j[k] as Vector2) * box.size
	if view == "gesture":
		var lw := maxf(3.0, s * 0.025)
		for bone: Array in [["head", "neck"], ["neck", "hips"], ["neck", "l_elbow"], ["l_elbow", "l_hand"], ["neck", "r_elbow"],
				["r_elbow", "r_hand"], ["hips", "l_knee"], ["l_knee", "l_foot"], ["hips", "r_knee"], ["r_knee", "r_foot"]]:
			ci.draw_line(at.call(bone[0]), at.call(bone[1]), INK, lw)
		ci.draw_circle(at.call("head"), s * 0.06, INK)
	else:
		var lw := maxf(6.0, s * 0.055)
		var skin := Color("c89a62")
		for bone: Array in [["hips", "l_knee"], ["l_knee", "l_foot"], ["hips", "r_knee"], ["r_knee", "r_foot"], ["neck", "l_elbow"],
				["l_elbow", "l_hand"], ["neck", "r_elbow"], ["r_elbow", "r_hand"]]:
			ci.draw_line(at.call(bone[0]), at.call(bone[1]), skin, lw)
			ci.draw_circle(at.call(bone[1]), lw * 0.55, skin.darkened(0.2))
		var n: Vector2 = at.call("neck")
		var hp: Vector2 = at.call("hips")
		var mid := n.lerp(hp, 0.5)
		var torso_len := n.distance_to(hp)
		var ang := (hp - n).angle() - PI / 2.0
		var pts := PackedVector2Array()
		for i in 20:
			var t := TAU * i / 20.0
			pts.append(mid + Vector2(cos(t) * s * 0.07, sin(t) * torso_len * 0.55).rotated(ang))
		ci.draw_colored_polygon(pts, skin.lightened(0.1))
		ci.draw_circle(at.call("head"), s * 0.065, skin.lightened(0.15))
		ci.draw_circle(hp, lw * 0.7, skin.darkened(0.2))
	if bool(d.get("line", false)):
		var line: Array = j.line
		var pts := PackedVector2Array()
		for p: Vector2 in line:
			pts.append(box.position + p * box.size)
		ci.draw_polyline(SchoolPictureG4Arts._catmull(pts, 8), SHADE, maxf(3.0, s * 0.02), true)


## A standing figure (a simple mannequin) `heads` heads tall from `top` (the top of its head at `top`).
static func _standing(ci: CanvasItem, top: Vector2, h: float, heads: int, col: Color) -> void:
	var head_c := top + Vector2(0, h * 0.5)
	SchoolPictureG4Arts._ellipse(ci, head_c, Vector2(h * 0.36, h * 0.5), Color("e6c9a0"))
	var neck_y := top.y + h
	var chest_w := h * (0.95 if heads >= 7 else 0.75)
	var hips_y := top.y + h * (4.0 if heads == 8 else heads * 0.5)
	var feet_y := top.y + h * heads
	var torso := PackedVector2Array([Vector2(top.x - chest_w, neck_y + h * 0.25), Vector2(top.x + chest_w, neck_y + h * 0.25),
		Vector2(top.x + chest_w * 0.8, hips_y), Vector2(top.x - chest_w * 0.8, hips_y)])
	ci.draw_colored_polygon(torso, col)
	ci.draw_rect(Rect2(Vector2(top.x - h * 0.12, neck_y - h * 0.05), Vector2(h * 0.24, h * 0.32)), Color("e6c9a0"))
	var lw := h * 0.3
	for side: float in [-1.0, 1.0]:
		var sh := Vector2(top.x + side * chest_w * 0.95, neck_y + h * 0.35)
		var el := Vector2(top.x + side * chest_w * 1.05, top.y + h * (3.0 if heads == 8 else heads * 0.375))
		var hand := Vector2(top.x + side * chest_w * 1.08, top.y + h * (5.0 if heads == 8 else heads * 0.6))
		ci.draw_line(sh, el, col.darkened(0.1), lw)
		ci.draw_line(el, hand, Color("e6c9a0"), lw * 0.85)
		var hip := Vector2(top.x + side * chest_w * 0.42, hips_y)
		var knee := Vector2(top.x + side * chest_w * 0.42, top.y + h * (6.0 if heads == 8 else heads * 0.75))
		var foot := Vector2(top.x + side * chest_w * 0.45, feet_y - h * 0.08)
		ci.draw_line(hip, knee, Color("4a5a7a"), lw * 1.2)
		ci.draw_line(knee, foot, Color("4a5a7a"), lw)
		ci.draw_line(foot, foot + Vector2(side * h * 0.25, 0), INK, lw * 0.8)


## Each pose's joints (shares of a square box) and its line of action (3-4 points).
static func _pose_joints(pose: String) -> Dictionary:
	match pose:
		"walk":
			return {"head": Vector2(0.52, 0.12), "neck": Vector2(0.51, 0.22), "hips": Vector2(0.5, 0.52),
				"l_elbow": Vector2(0.42, 0.37), "l_hand": Vector2(0.4, 0.5), "r_elbow": Vector2(0.6, 0.37), "r_hand": Vector2(0.64, 0.48),
				"l_knee": Vector2(0.42, 0.7), "l_foot": Vector2(0.36, 0.9), "r_knee": Vector2(0.58, 0.71), "r_foot": Vector2(0.62, 0.9),
				"line": [Vector2(0.53, 0.08), Vector2(0.5, 0.5), Vector2(0.4, 0.92)]}
		"run":
			return {"head": Vector2(0.6, 0.14), "neck": Vector2(0.57, 0.24), "hips": Vector2(0.47, 0.5),
				"l_elbow": Vector2(0.45, 0.32), "l_hand": Vector2(0.38, 0.42), "r_elbow": Vector2(0.7, 0.35), "r_hand": Vector2(0.72, 0.24),
				"l_knee": Vector2(0.62, 0.62), "l_foot": Vector2(0.58, 0.82), "r_knee": Vector2(0.38, 0.68), "r_foot": Vector2(0.22, 0.78),
				"line": [Vector2(0.64, 0.08), Vector2(0.48, 0.48), Vector2(0.22, 0.8)]}
		"jump":
			return {"head": Vector2(0.5, 0.12), "neck": Vector2(0.5, 0.22), "hips": Vector2(0.5, 0.48),
				"l_elbow": Vector2(0.38, 0.14), "l_hand": Vector2(0.32, 0.04), "r_elbow": Vector2(0.62, 0.14), "r_hand": Vector2(0.68, 0.04),
				"l_knee": Vector2(0.4, 0.62), "l_foot": Vector2(0.42, 0.8), "r_knee": Vector2(0.6, 0.62), "r_foot": Vector2(0.58, 0.8),
				"line": [Vector2(0.3, 0.1), Vector2(0.5, 0.36), Vector2(0.5, 0.82)]}
		"reach":
			return {"head": Vector2(0.44, 0.2), "neck": Vector2(0.46, 0.3), "hips": Vector2(0.52, 0.58),
				"l_elbow": Vector2(0.56, 0.18), "l_hand": Vector2(0.7, 0.06), "r_elbow": Vector2(0.4, 0.42), "r_hand": Vector2(0.38, 0.55),
				"l_knee": Vector2(0.54, 0.75), "l_foot": Vector2(0.56, 0.93), "r_knee": Vector2(0.46, 0.76), "r_foot": Vector2(0.42, 0.93),
				"line": [Vector2(0.7, 0.05), Vector2(0.48, 0.4), Vector2(0.55, 0.93)]}
		"throw":
			return {"head": Vector2(0.42, 0.16), "neck": Vector2(0.45, 0.26), "hips": Vector2(0.52, 0.54),
				"l_elbow": Vector2(0.34, 0.3), "l_hand": Vector2(0.22, 0.28), "r_elbow": Vector2(0.62, 0.2), "r_hand": Vector2(0.74, 0.08),
				"l_knee": Vector2(0.4, 0.72), "l_foot": Vector2(0.3, 0.92), "r_knee": Vector2(0.62, 0.73), "r_foot": Vector2(0.72, 0.92),
				"line": [Vector2(0.76, 0.06), Vector2(0.5, 0.42), Vector2(0.3, 0.92)]}
		"sit":
			return {"head": Vector2(0.4, 0.2), "neck": Vector2(0.4, 0.3), "hips": Vector2(0.42, 0.6),
				"l_elbow": Vector2(0.48, 0.44), "l_hand": Vector2(0.58, 0.55), "r_elbow": Vector2(0.34, 0.44), "r_hand": Vector2(0.4, 0.56),
				"l_knee": Vector2(0.68, 0.6), "l_foot": Vector2(0.7, 0.88), "r_knee": Vector2(0.66, 0.64), "r_foot": Vector2(0.64, 0.9),
				"line": [Vector2(0.38, 0.14), Vector2(0.42, 0.6), Vector2(0.68, 0.62)]}
	return {"head": Vector2(0.5, 0.1), "neck": Vector2(0.5, 0.2), "hips": Vector2(0.5, 0.5),
		"l_elbow": Vector2(0.42, 0.36), "l_hand": Vector2(0.4, 0.5), "r_elbow": Vector2(0.58, 0.36), "r_hand": Vector2(0.6, 0.5),
		"l_knee": Vector2(0.45, 0.7), "l_foot": Vector2(0.44, 0.92), "r_knee": Vector2(0.55, 0.7), "r_foot": Vector2(0.56, 0.92),
		"line": [Vector2(0.5, 0.06), Vector2(0.52, 0.5), Vector2(0.5, 0.94)]}


static func _draw_piece(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var what := str(d.what)
	var parts: Dictionary = PIECE_PARTS.get(what, {})
	match what:
		"mughal":
			var w := minf(r.size.x * 0.6, r.size.y * 0.8)
			var b := Rect2(Vector2(r.get_center().x - w * 0.5, r.position.y), Vector2(w, r.size.y))
			ci.draw_rect(b, Color("e9d6a8"))
			for i in 14:   # the border's flower sprays
				var t := i / 14.0
				for p: Vector2 in [Vector2(b.position.x + b.size.x * 0.05, b.position.y + b.size.y * (0.04 + t * 0.92)),
						Vector2(b.end.x - b.size.x * 0.05, b.position.y + b.size.y * (0.04 + t * 0.92))]:
					ci.draw_circle(p, b.size.x * 0.018, [Color("c0503a"), Color("3a8a5a"), Color("3a6fc0")][i % 3])
			var inner := b.grow(-b.size.x * 0.11)
			ci.draw_rect(inner.grow(3), GOLD)
			ci.draw_rect(inner, Color("5f8f4a"))
			ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.24)), GOLD.lightened(0.25))
			var pav := Rect2(inner.position + Vector2(inner.size.x * 0.44, inner.size.y * 0.24), Vector2(inner.size.x * 0.46, inner.size.y * 0.34))
			ci.draw_rect(pav, Color("f3ead6"))
			ci.draw_rect(Rect2(pav.position - Vector2(inner.size.x * 0.03, inner.size.y * 0.04), Vector2(pav.size.x + inner.size.x * 0.06,
				inner.size.y * 0.05)), Color("c0503a"))
			for k in 3:
				ci.draw_rect(Rect2(pav.position + Vector2(pav.size.x * (0.1 + k * 0.33), 0), Vector2(pav.size.x * 0.05, pav.size.y)), Color("c9b48f"))
			_person(ci, pav.position + Vector2(pav.size.x * 0.5, pav.size.y * 0.92), pav.size.y * 0.6, Color("e0a03a"))
			_person(ci, inner.position + Vector2(inner.size.x * 0.22, inner.size.y * 0.62), inner.size.y * 0.24, Color("3a6fc0"))
			var pool := Rect2(inner.position + Vector2(inner.size.x * 0.18, inner.size.y * 0.7), Vector2(inner.size.x * 0.64, inner.size.y * 0.16))
			ci.draw_rect(pool, Color("7fb4d9"))
			ci.draw_rect(pool, Color("f3ead6"), false, 3.0)
			for k in 4:
				ci.draw_circle(inner.position + Vector2(inner.size.x * (0.12 + k * 0.25), inner.size.y * 0.95), inner.size.x * 0.03, Color("3a8a5a"))
		"iznik":
			var s := minf(r.size.x, r.size.y)
			var b := Rect2(r.get_center() - Vector2(s, s) * 0.5, Vector2(s, s))
			ci.draw_rect(b, Color("fbfaf4"))
			ci.draw_rect(b, COBALT, false, maxf(4.0, s * 0.04))
			var p := func(v: Vector2) -> Vector2: return r.position + v * r.size
			# the saz leaf: a long curving serrated leaf
			var saz := PackedVector2Array()
			var c: Vector2 = p.call(parts["saz leaf"])
			for i in 13:
				var t := i / 12.0
				saz.append(c + Vector2(-s * 0.25 + s * 0.5 * t, -s * 0.18 * sin(t * PI) + s * 0.12 * (t - 0.5)) + Vector2(0, -s * 0.03))
			for i in 13:
				var t := 1.0 - i / 12.0
				saz.append(c + Vector2(-s * 0.25 + s * 0.5 * t, -s * 0.18 * sin(t * PI) + s * 0.12 * (t - 0.5)) + Vector2(0, s * 0.05))
			ci.draw_colored_polygon(saz, Color("2e8b57"))
			# the tulip: red petals on a stem
			var tc: Vector2 = p.call(parts["tulip"])
			ci.draw_line(tc + Vector2(0, s * 0.06), tc + Vector2(0, s * 0.3), Color("2e8b57"), maxf(2.0, s * 0.015))
			for k: float in [-1.0, 0.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([tc + Vector2(k * s * 0.04, s * 0.07), tc + Vector2(k * s * 0.07 - s * 0.03, -s * 0.06),
					tc + Vector2(k * s * 0.05, -s * 0.12), tc + Vector2(k * s * 0.07 + s * 0.03, -s * 0.06)]), RED)
			# the carnation: a fan of frilled petals
			var cc: Vector2 = p.call(parts["carnation"])
			for k in 5:
				var ang := -PI * 0.9 + k * PI * 0.2
				ci.draw_circle(cc + Vector2(cos(ang), sin(ang)) * s * 0.06, s * 0.035, TURQUOISE if k % 2 == 0 else COBALT)
			ci.draw_circle(cc, s * 0.03, RED)
			for k in 8:
				var ang := TAU * k / 8.0
				ci.draw_circle(b.get_center() + Vector2(cos(ang), sin(ang)) * s * 0.4, s * 0.02, TURQUOISE)
		"ukiyo_e":
			var w := minf(r.size.x * 0.6, r.size.y * 0.7)
			var b := Rect2(Vector2(r.get_center().x - w * 0.5, r.position.y), Vector2(w, r.size.y))
			ci.draw_rect(b, Color("f1e3c3"))
			for k in 18:   # rain
				var x := b.position.x + b.size.x * fmod(k * 0.137, 1.0)
				var y := b.position.y + b.size.y * fmod(k * 0.291, 1.0)
				ci.draw_line(Vector2(x, y), Vector2(x - w * 0.03, y + w * 0.1), Color("7f93a8"), 1.0)
			var um: Vector2 = r.position + (parts["umbrella"] as Vector2) * r.size
			ci.draw_colored_polygon(PackedVector2Array([um + Vector2(-w * 0.3, w * 0.12), um + Vector2(0, -w * 0.1), um + Vector2(w * 0.3, w * 0.12)]),
				Color("c0503a"))
			ci.draw_polyline(PackedVector2Array([um + Vector2(-w * 0.3, w * 0.12), um + Vector2(0, -w * 0.1), um + Vector2(w * 0.3, w * 0.12)]),
				INK, 2.5)
			var kc: Vector2 = r.position + (parts["kimono pattern"] as Vector2) * r.size
			var robe := PackedVector2Array([um + Vector2(-w * 0.1, w * 0.2), um + Vector2(w * 0.1, w * 0.2), kc + Vector2(w * 0.2, b.size.y * 0.25),
				kc + Vector2(-w * 0.2, b.size.y * 0.25)])
			ci.draw_colored_polygon(robe, Color("2f4f8a"))
			ci.draw_polyline(PackedVector2Array([robe[0], robe[1], robe[2], robe[3], robe[0]]), INK, 2.5)
			for k in 6:
				ci.draw_circle(kc + Vector2((k % 3 - 1) * w * 0.1, (k / 3) * w * 0.14 - w * 0.07), w * 0.03, Color("f2c12e"))
			ci.draw_circle(um + Vector2(0, w * 0.15), w * 0.075, Color("f7ead8"))   # the face, under the umbrella
			_ring(ci, um + Vector2(0, w * 0.15), w * 0.075, INK, 2.0)
			SchoolPictureG4Arts._ellipse(ci, um + Vector2(0, w * 0.1), Vector2(w * 0.08, w * 0.035), INK)   # black hair
			ci.draw_line(um + Vector2(0, -w * 0.1), um + Vector2(0, w * 0.12), INK, 2.0)
			var cart: Vector2 = r.position + (parts["cartouche"] as Vector2) * r.size
			var cb := Rect2(cart - Vector2(w * 0.08, b.size.y * 0.13), Vector2(w * 0.16, b.size.y * 0.26))
			ci.draw_rect(cb, Color("e9d9a8"))
			ci.draw_rect(cb, INK, false, 1.5)
			for k in 4:
				ci.draw_line(cb.position + Vector2(cb.size.x * 0.5, cb.size.y * (0.15 + k * 0.2)), cb.position + Vector2(cb.size.x * 0.5,
					cb.size.y * (0.25 + k * 0.2)), INK, 2.0)
			var seal: Vector2 = r.position + (parts["seal"] as Vector2) * r.size
			ci.draw_rect(Rect2(seal - Vector2(w * 0.05, w * 0.05), Vector2(w * 0.1, w * 0.1)), RED)
		"blue_white":
			var s := minf(r.size.x * 0.5, r.size.y)
			var c := r.get_center()
			var vase := PackedVector2Array()
			var prof: Array[float] = [0.12, 0.1, 0.16, 0.3, 0.38, 0.36, 0.28, 0.18, 0.16]
			for i in prof.size():
				vase.append(c + Vector2(-prof[i] * s, -s * 0.48 + s * 0.96 * i / (prof.size() - 1)))
			for i in range(prof.size() - 1, -1, -1):
				vase.append(c + Vector2(prof[i] * s, -s * 0.48 + s * 0.96 * i / (prof.size() - 1)))
			ci.draw_colored_polygon(vase, Color("fbfaf4"))
			ci.draw_polyline(vase + PackedVector2Array([vase[0]]), COBALT, 2.5)
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.12), c + Vector2(s * 0.3, -s * 0.12), COBALT, 3.0)
			ci.draw_line(c + Vector2(-s * 0.3, s * 0.22), c + Vector2(s * 0.3, s * 0.22), COBALT, 3.0)
			for k in 5:
				var q := c + Vector2(-s * 0.24 + k * s * 0.12, s * 0.05)
				ci.draw_circle(q, s * 0.04, COBALT)
				ci.draw_circle(q, s * 0.018, Color("fbfaf4"))
	if bool(d.get("labels", false)) or d.has("mark"):
		var fs := clampi(int(r.size.y * 0.07), 9, 16)
		for part: String in parts:
			var at: Vector2 = r.position + (parts[part] as Vector2) * r.size
			if part == str(d.get("mark", "")):
				_ring(ci, at, r.size.y * 0.08, SHADE, 3.0)
			if bool(d.get("labels", false)):
				var lx := r.end.x - r.size.x * 0.16 if at.x > r.get_center().x else r.position.x + r.size.x * 0.02
				ci.draw_line(at, Vector2(lx + (0.0 if at.x > r.get_center().x else r.size.x * 0.14), at.y), GREY, 1.5)
				ci.draw_string(font, Vector2(lx, at.y - 3), part, HORIZONTAL_ALIGNMENT_LEFT, -1, _fit(font, part, fs, r.size.x * 0.2), INK)


static func _draw_poster(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var design := str(d.design)
	if design.begins_with("logo"):
		_draw_logos(ci, font, r, design)
		return
	var w := minf(r.size.x * 0.5, r.size.y * 0.72)
	var p := Rect2(Vector2(r.get_center().x - w * 0.5, r.position.y), Vector2(w, r.size.y))
	ci.draw_rect(p, Color.WHITE)
	ci.draw_rect(p, INK, false, 1.5)
	var m := w * 0.08
	var inner := p.grow(-m)
	match design:
		"clear":
			if bool(d.get("grid", false)):
				for k in 3:
					var x := inner.position.x + inner.size.x * k / 2.0
					ci.draw_line(Vector2(x, p.position.y), Vector2(x, p.end.y), Color("8fd0f0"), 1.0)
				ci.draw_rect(inner, Color("8fd0f0"), false, 1.0)
			var hf := _fit(font, "CASTLE CLUB", int(w * 0.14), inner.size.x)
			ci.draw_string(font, Vector2(inner.position.x, inner.position.y + font.get_ascent(hf)), "CASTLE CLUB",
				HORIZONTAL_ALIGNMENT_LEFT, -1, hf, Color("c0503a"))
			var img := Rect2(Vector2(inner.position.x, inner.position.y + r.size.y * 0.2), Vector2(inner.size.x, r.size.y * 0.42))
			ci.draw_rect(img, Color("bfe0f7"))
			ci.draw_rect(Rect2(img.position + Vector2(img.size.x * 0.3, img.size.y * 0.3), Vector2(img.size.x * 0.4, img.size.y * 0.7)),
				Color("b9a67f"))
			for k in 3:
				ci.draw_rect(Rect2(img.position + Vector2(img.size.x * (0.3 + k * 0.15), img.size.y * 0.2), Vector2(img.size.x * 0.1,
					img.size.y * 0.1)), Color("b9a67f"))
			var dfs := clampi(int(w * 0.055), 7, 16)
			var dy := img.end.y + r.size.y * 0.08
			for t: String in ["Build together", "Saturday, 2 pm", "The library"]:
				ci.draw_string(font, Vector2(inner.position.x, dy), t, HORIZONTAL_ALIGNMENT_LEFT, -1, dfs, INK)
				dy += dfs * 1.35
			var logo := r.position + (POSTER_PARTS["logo"] as Vector2) * r.size
			ci.draw_circle(logo, w * 0.05, Color("c0503a"))
			ci.draw_rect(Rect2(logo - Vector2(w * 0.02, w * 0.025), Vector2(w * 0.04, w * 0.05)), Color.WHITE)
		"crowded":
			var words: Array = [["CASTLE", 0.16, Color("c0503a")], ["CLUB!!!", 0.14, Color("3a7be8")], ["BUILD", 0.12, GREEN],
				["SAT 2PM", 0.12, Color("8a3fb8")], ["LIBRARY", 0.11, SHADE], ["FREE", 0.13, RED], ["FUN!", 0.12, Color("2aa8a0")]]
			var y := p.position.y + w * 0.02
			for k in words.size():
				var fsz := int(w * float(words[k][1]))
				var x := p.position.x + (w * 0.1 if k % 2 == 0 else w * 0.3)
				ci.draw_string(font, Vector2(x, y + font.get_ascent(fsz)), str(words[k][0]), HORIZONTAL_ALIGNMENT_LEFT, w * 0.9, fsz, words[k][2])
				y += fsz * 1.02
			for k in 5:
				ci.draw_circle(p.position + Vector2(w * (0.15 + k * 0.18), p.size.y * (0.2 + 0.15 * (k % 3))), w * 0.05,
					[Color("f2c12e"), Color("8cc56a"), Color("f7aaa6")][k % 3])
		"centred":
			var hf := _fit(font, "CASTLE CLUB", int(w * 0.13), inner.size.x)
			_label(ci, font, Vector2(p.get_center().x, inner.position.y + hf * 0.8), "CASTLE CLUB", hf, Color("c0503a"))
			var img := Rect2(Vector2(p.get_center().x - inner.size.x * 0.35, inner.position.y + r.size.y * 0.2), Vector2(inner.size.x * 0.7, r.size.y * 0.38))
			ci.draw_rect(img, Color("bfe0f7"))
			ci.draw_rect(Rect2(img.position + Vector2(img.size.x * 0.3, img.size.y * 0.3), Vector2(img.size.x * 0.4, img.size.y * 0.7)), Color("b9a67f"))
			var dfs := clampi(int(w * 0.055), 7, 16)
			var dy := img.end.y + r.size.y * 0.1
			for t: String in ["Build together", "Saturday, 2 pm", "The library"]:
				_label(ci, font, Vector2(p.get_center().x, dy), t, dfs, INK)
				dy += dfs * 1.4
	if bool(d.get("labels", false)) and design == "clear":
		var fs := clampi(int(r.size.y * 0.07), 9, 16)
		for part: String in POSTER_PARTS:
			var at: Vector2 = r.position + (POSTER_PARTS[part] as Vector2) * r.size
			var lx := p.end.x + r.size.x * 0.03
			ci.draw_line(at, Vector2(lx - 3, at.y), GREY, 1.5)
			ci.draw_string(font, Vector2(lx, at.y + fs * 0.35), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var mark := str(d.get("mark", ""))
	if mark != "" and design == "clear":
		_ring(ci, r.position + (POSTER_PARTS[mark] as Vector2) * r.size, r.size.y * 0.08, SHADE, 3.0)


static func _draw_logos(ci: CanvasItem, font: Font, r: Rect2, design: String) -> void:
	var fs := _fs(r, 0.08, 16)
	match design:
		"logo_sizes":
			var sizes: Array[float] = [0.34, 0.18, 0.08]
			var x := r.position.x + r.size.x * 0.12
			for s: float in sizes:
				var rad := r.size.y * s
				_owl_logo(ci, Vector2(x + rad, r.get_center().y), rad, true)
				x += rad * 2.0 + r.size.x * 0.1
		"logo_busy":
			for k in 2:
				var cx := r.position.x + r.size.x * (0.25 + k * 0.5)
				var big := r.size.y * 0.28
				if k == 0:
					_busy_logo(ci, font, Vector2(cx - big * 0.5, r.position.y + r.size.y * 0.35), big)
					_busy_logo(ci, font, Vector2(cx + big * 0.9, r.position.y + r.size.y * 0.35), big * 0.22)
				else:
					_owl_logo(ci, Vector2(cx - big * 0.5, r.position.y + r.size.y * 0.35), big, true)
					_owl_logo(ci, Vector2(cx + big * 0.9, r.position.y + r.size.y * 0.35), big * 0.22, true)
				var t := "busy" if k == 0 else "simple"
				_label(ci, font, Vector2(cx, r.end.y - r.size.y * 0.12), t, fs, INK)
		"logo_mono":
			var rad := minf(r.size.y * 0.3, r.size.x * 0.13)
			var names: Array[String] = ["colour", "one colour", "reversed"]
			for k in 3:
				var c := Vector2(r.position.x + r.size.x * (0.18 + k * 0.32), r.position.y + r.size.y * 0.42)
				if k == 2:
					_rounded(ci, Rect2(c - Vector2(rad, rad) * 1.25, Vector2(rad, rad) * 2.5), INK, 10.0)
				_owl_logo(ci, c, rad, k == 0, Color.WHITE if k == 2 else INK)
				_label(ci, font, Vector2(c.x, r.end.y - r.size.y * 0.08), names[k], fs, INK)


## A simple owl logo: a circle, two eyes and a beak; one colour when `colour` is false.
static func _owl_logo(ci: CanvasItem, c: Vector2, rad: float, colour: bool, one: Color = INK) -> void:
	var body := Color("7a4a24") if colour else one
	var eye_bg := Color("f2c12e") if colour else (INK if one == Color.WHITE else Color.WHITE)
	ci.draw_circle(c, rad, body)
	for k: float in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(k * rad * 0.38, -rad * 0.15), rad * 0.3, eye_bg)
		ci.draw_circle(c + Vector2(k * rad * 0.38, -rad * 0.15), rad * 0.12, body)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-rad * 0.12, rad * 0.12), c + Vector2(rad * 0.12, rad * 0.12),
		c + Vector2(0, rad * 0.4)]), Color("f08a1c") if colour else eye_bg)


## A busy logo: thin lines, small words and many colours, which turn to a smudge when small.
static func _busy_logo(ci: CanvasItem, font: Font, c: Vector2, rad: float) -> void:
	ci.draw_circle(c, rad, Color("f7d9a6"))
	for k in 12:
		var ang := TAU * k / 12.0
		ci.draw_line(c, c + Vector2(cos(ang), sin(ang)) * rad, [Color("c0503a"), Color("3a7be8"), GREEN][k % 3], maxf(0.6, rad * 0.02))
	for k in 6:
		ci.draw_circle(c + Vector2(cos(k), sin(k)) * rad * 0.6, rad * 0.1, [Color("8a3fb8"), Color("2aa8a0")][k % 2])
	if rad > 20.0:
		_label(ci, font, c + Vector2(0, rad * 0.75), "the castle builders club", clampi(int(rad * 0.12), 6, 12), INK)


## The house's part `part` on a drawing of view d.view, in the card's pixels.
static func _house_part(r: Rect2, d: Dictionary, part: String) -> Vector2:
	var g := _house_geometry(r, str(d.get("view", "plan")))
	var m: float = g.m
	var o: Vector2 = g.o
	match str(d.get("view", "plan")):
		"plan":
			var rooms: Dictionary = HOUSE.rooms
			if rooms.has(part):
				var q: Array = rooms[part]
				return o + Vector2(float(q[0]) + float(q[2]) * 0.5, float(q[1]) + float(q[3]) * 0.5) * m
			match part:
				"front door":
					return o + Vector2(5.0, 6.0) * m
				"window":
					return o + Vector2(2.0, 6.0) * m
		"front":
			match part:
				"front door":
					return o + Vector2(5.0, 5.5 - 1.0) * m
				"window":
					return o + Vector2(2.0, 5.5 - 1.6) * m
				"roof":
					return o + Vector2(5.0, 5.5 - 4.25) * m
				"wall":
					return o + Vector2(6.25, 5.5 - 1.5) * m
		"side":
			match part:
				"roof":
					return o + Vector2(3.0, 5.5 - 4.25) * m
				"wall":
					return o + Vector2(1.0, 5.5 - 1.0) * m
	return Vector2(-1, -1)


## Where the house is drawn: `o` the top-left corner of its metres (plan: the back-left corner; front and side: the
## top of a 5.5 m high box) and `m` pixels a metre.
static func _house_geometry(r: Rect2, view: String) -> Dictionary:
	var w: float = HOUSE.width if view != "side" else HOUSE.depth
	var h: float = HOUSE.depth if view == "plan" else HOUSE.ridge
	var room := r.grow(-r.size.y * 0.1)
	room.size.y -= r.size.y * 0.06
	var m := minf(room.size.x * 0.78 / w, room.size.y / h)
	var o := Vector2(r.get_center().x - w * m * 0.5, room.position.y + (room.size.y - h * m) * 0.5)
	return {"m": m, "o": o, "w": w, "h": h}


static func _draw_house(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var view := str(d.view)
	var g := _house_geometry(r, view)
	var m: float = g.m
	var o: Vector2 = g.o
	var fs := clampi(int(m * 0.42), 8, 16)
	var dims := bool(d.get("dims", false))
	var labels := bool(d.get("labels", false))
	var lw := maxf(2.0, m * 0.12)
	match view:
		"plan":
			ci.draw_rect(Rect2(o, Vector2(10, 6) * m), Color("f7f1e1"))
			var rooms: Dictionary = HOUSE.rooms
			for name: String in rooms:
				var q: Array = rooms[name]
				ci.draw_rect(Rect2(o + Vector2(float(q[0]), float(q[1])) * m, Vector2(float(q[2]), float(q[3])) * m), INK, false, lw * 0.5)
				if labels:
					var c := o + Vector2(float(q[0]) + float(q[2]) * 0.5, float(q[1]) + float(q[3]) * 0.5) * m
					_label(ci, font, c, name, _fit(font, name, fs, float(q[2]) * m - 4), INK)
			ci.draw_rect(Rect2(o, Vector2(10, 6) * m), INK, false, lw)
			# the front door: a gap with its swing
			var door := o + Vector2(4.5, 6.0) * m
			ci.draw_line(door, door + Vector2(1.0 * m, 0), Color("f7f1e1"), lw * 1.4)
			ci.draw_line(door, door + Vector2(0, -1.0 * m), INK, 1.5)
			var arc := PackedVector2Array()
			for i in 9:
				var t := -PI / 2.0 + (PI / 2.0) * i / 8.0
				arc.append(door + Vector2(cos(t), sin(t)) * m)
			ci.draw_polyline(arc, GREY, 1.2)
			for win: Array in HOUSE.windows:
				var a := o + Vector2(float(win[0]), 6.0) * m
				ci.draw_rect(Rect2(a - Vector2(0, lw * 0.6), Vector2(float(win[1]) * m, lw * 1.2)), Color("bfe0f7"))
				ci.draw_rect(Rect2(a - Vector2(0, lw * 0.6), Vector2(float(win[1]) * m, lw * 1.2)), INK, false, 1.0)
			if dims:
				_dim(ci, font, o + Vector2(0, -0.5) * m, o + Vector2(10, -0.5) * m, "10 m", fs)
				_dim(ci, font, o + Vector2(-0.5, 0) * m, o + Vector2(-0.5, 6) * m, "6 m", fs)
		"front", "side":
			var width: float = g.w
			var ground := o + Vector2(0, 5.5) * m
			ci.draw_line(ground + Vector2(-m, 0), ground + Vector2((width + 1.0) * m, 0), Color("6a8a4a"), lw)
			ci.draw_rect(Rect2(ground - Vector2(0, 3.0 * m), Vector2(width * m, 3.0 * m)), Color("f3e3c8"))
			ci.draw_rect(Rect2(ground - Vector2(0, 3.0 * m), Vector2(width * m, 3.0 * m)), INK, false, lw * 0.6)
			if view == "front":
				var roof := Rect2(ground - Vector2(0.3 * m, 5.5 * m), Vector2((width + 0.6) * m, 2.5 * m))
				ci.draw_rect(roof, Color("a0503a"))
				ci.draw_rect(roof, INK, false, lw * 0.6)
				var door := ground + Vector2(4.5, -2.0) * m
				ci.draw_rect(Rect2(door, Vector2(1.0, 2.0) * m), Color("3a6fc0"))
				for win: Array in HOUSE.windows:
					var a := ground + Vector2(float(win[0]), -float(win[2]) - float(win[3])) * m
					ci.draw_rect(Rect2(a, Vector2(float(win[1]), float(win[3])) * m), Color("bfe0f7"))
					ci.draw_rect(Rect2(a, Vector2(float(win[1]), float(win[3])) * m), INK, false, 1.5)
				if dims:
					_dim(ci, font, ground + Vector2(0, 0.5) * m, ground + Vector2(10, 0.5) * m, "10 m", fs)
					_dim(ci, font, ground + Vector2(10.8, 0) * m, ground + Vector2(10.8, -3.0) * m, "3 m", fs)
					_dim(ci, font, ground + Vector2(-0.9, 0) * m, ground + Vector2(-0.9, -5.5) * m, "5.5 m", fs)
			else:
				var gable := PackedVector2Array([ground + Vector2(-0.3, -3.0) * m, ground + Vector2(3.0, -5.5) * m,
					ground + Vector2(6.3, -3.0) * m])
				ci.draw_colored_polygon(gable, Color("a0503a"))
				ci.draw_polyline(gable, INK, lw * 0.6)
				ci.draw_rect(Rect2(ground + Vector2(2.2, -2.2) * m, Vector2(1.6, 1.0) * m), Color("bfe0f7"))
				ci.draw_rect(Rect2(ground + Vector2(2.2, -2.2) * m, Vector2(1.6, 1.0) * m), INK, false, 1.5)
				if dims:
					_dim(ci, font, ground + Vector2(0, 0.5) * m, ground + Vector2(6, 0.5) * m, "6 m", fs)
					_dim(ci, font, ground + Vector2(6.8, 0) * m, ground + Vector2(6.8, -5.5) * m, "5.5 m", fs)
	if d.has("scale"):
		var bar_m := 5.0
		var a := Vector2(r.position.x + r.size.x * 0.02, r.end.y - fs * 0.6)
		ci.draw_rect(Rect2(a - Vector2(0, 4), Vector2(bar_m * m, 5)), INK)
		ci.draw_rect(Rect2(a - Vector2(0, 4), Vector2(bar_m * m * 0.5, 5)), PAPER_WHITE)
		ci.draw_rect(Rect2(a - Vector2(0, 4), Vector2(bar_m * m, 5)), INK, false, 1.0)
		ci.draw_string(font, a + Vector2(bar_m * m + 6, 3), "5 m   scale %s" % d.scale, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	var mark := str(d.get("mark", ""))
	if mark != "":
		var at := _house_part(r, d, mark)
		if at != Vector2(-1, -1):
			_ring(ci, at, m * 0.9, SHADE, 3.0)


## A dimension line from a to b with its measurement.
static func _dim(ci: CanvasItem, font: Font, a: Vector2, b: Vector2, text: String, fs: int) -> void:
	ci.draw_line(a, b, BLUE, 1.5)
	var n := (b - a).normalized().orthogonal() * 5.0
	ci.draw_line(a - n, a + n, BLUE, 1.5)
	ci.draw_line(b - n, b + n, BLUE, 1.5)
	var mid := a.lerp(b, 0.5)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_rounded(ci, Rect2(mid - Vector2(tw * 0.5 + 3, fs * 0.6), Vector2(tw + 6, fs * 1.2)), PAPER_WHITE, 4.0)
	_label(ci, font, mid, text, fs, BLUE)


static func _draw_thirds(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var w := minf(r.size.x, r.size.y * 1.5)
	var p := Rect2(Vector2(r.get_center().x - w * 0.5, r.get_center().y - w / 3.0), Vector2(w, w / 1.5))
	var hz := float(d.get("horizon", 0.55))
	var sky_h := p.size.y * hz
	ci.draw_rect(Rect2(p.position, Vector2(p.size.x, sky_h)), Color("bfe0f7"))
	ci.draw_rect(Rect2(p.position + Vector2(0, sky_h), Vector2(p.size.x, p.size.y - sky_h)), Color("8cc56a"))
	var subj := p.position + Vector2(float(d.subject[0]), float(d.subject[1])) * p.size
	match str(d.get("lines", "")):
		"road", "river":
			var col := Color("b9a67f") if str(d.lines) == "road" else Color("7fb4d9")
			ci.draw_colored_polygon(PackedVector2Array([Vector2(p.position.x + p.size.x * 0.2, p.end.y), Vector2(p.position.x + p.size.x * 0.8, p.end.y),
				subj + Vector2(p.size.x * 0.02, p.size.y * 0.06), subj + Vector2(-p.size.x * 0.02, p.size.y * 0.06)]), col)
		"fence":
			for k in 7:
				var t := k / 6.0
				var base := Vector2(p.position.x + p.size.x * 0.05, p.end.y).lerp(subj + Vector2(-p.size.x * 0.04, p.size.y * 0.06), t)
				ci.draw_line(base, base - Vector2(0, p.size.y * 0.14 * (1.0 - t * 0.7)), Color("7a4a24"), maxf(2.0, 5.0 * (1.0 - t * 0.6)))
			ci.draw_line(Vector2(p.position.x + p.size.x * 0.05, p.end.y - p.size.y * 0.1), subj + Vector2(-p.size.x * 0.04, p.size.y * 0.03),
				Color("7a4a24"), 3.0)
	var s := p.size.y * 0.22
	match str(d.get("thing", "tree")):
		"tree":
			ci.draw_rect(Rect2(subj + Vector2(-s * 0.08, -s * 0.1), Vector2(s * 0.16, s * 0.55)), Color("7a4a24"))
			ci.draw_circle(subj + Vector2(0, -s * 0.35), s * 0.4, Color("2e7d32"))
		"buddy":
			ci.draw_rect(Rect2(subj - Vector2(s * 0.3, s * 0.5), Vector2(s * 0.6, s * 0.7)), Color("f2c12e"))
			ci.draw_circle(subj + Vector2(-s * 0.12, -s * 0.3), s * 0.06, INK)
			ci.draw_circle(subj + Vector2(s * 0.12, -s * 0.3), s * 0.06, INK)
		"tower":
			ci.draw_rect(Rect2(subj - Vector2(s * 0.2, s * 0.9), Vector2(s * 0.4, s * 1.1)), Color("b9a67f"))
			ci.draw_colored_polygon(PackedVector2Array([subj + Vector2(-s * 0.28, -s * 0.9), subj + Vector2(s * 0.28, -s * 0.9),
				subj + Vector2(0, -s * 1.3)]), Color("a0503a"))
		"boat":
			ci.draw_colored_polygon(PackedVector2Array([subj + Vector2(-s * 0.5, 0), subj + Vector2(s * 0.5, 0), subj + Vector2(s * 0.35, s * 0.2),
				subj + Vector2(-s * 0.35, s * 0.2)]), Color("7a4a24"))
			ci.draw_colored_polygon(PackedVector2Array([subj + Vector2(0, -s * 0.8), subj + Vector2(s * 0.4, -s * 0.05), subj + Vector2(0, -s * 0.05)]),
				Color.WHITE)
	match str(d.get("frame", "")):
		"arch":
			var arch := PackedVector2Array([p.position, Vector2(p.end.x, p.position.y)])
			for i in 17:
				var t := i / 16.0
				arch.append(Vector2(p.end.x - p.size.x * 0.08 - (p.size.x * 0.84) * t, p.position.y + p.size.y * 0.25 - sin(t * PI) * p.size.y * 0.18))
			ci.draw_colored_polygon(arch, Color("8a7650"))
			ci.draw_rect(Rect2(p.position, Vector2(p.size.x * 0.08, p.size.y)), Color("8a7650"))
			ci.draw_rect(Rect2(Vector2(p.end.x - p.size.x * 0.08, p.position.y), Vector2(p.size.x * 0.08, p.size.y)), Color("8a7650"))
		"trees":
			for side: float in [0.0, 1.0]:
				var x := p.position.x + p.size.x * (0.04 if side == 0.0 else 0.96)
				ci.draw_rect(Rect2(Vector2(x - p.size.x * 0.02, p.position.y), Vector2(p.size.x * 0.04, p.size.y)), Color("5a3a1a"))
				var cx := p.position.x + p.size.x * (0.1 if side == 0.0 else 0.9)
				ci.draw_circle(Vector2(cx, p.position.y + p.size.y * 0.14), p.size.y * 0.13, Color("2e5d32"))
				ci.draw_rect(Rect2(Vector2(p.position.x if side == 0.0 else p.end.x - p.size.x * 0.1, p.position.y),
					Vector2(p.size.x * 0.1, p.size.y * 0.1)), Color("2e5d32"))
	ci.draw_rect(p, INK, false, 2.0)
	if bool(d.get("grid", false)):
		for k in [1, 2]:
			SchoolPictureG6Arts._dashed(ci, Vector2(p.position.x + p.size.x * k / 3.0, p.position.y), Vector2(p.position.x + p.size.x * k / 3.0, p.end.y),
				Color.WHITE, 2.0)
			SchoolPictureG6Arts._dashed(ci, Vector2(p.position.x, p.position.y + p.size.y * k / 3.0), Vector2(p.end.x, p.position.y + p.size.y * k / 3.0),
				Color.WHITE, 2.0)
		for kx in [1, 2]:
			for ky in [1, 2]:
				ci.draw_circle(p.position + Vector2(p.size.x * kx / 3.0, p.size.y * ky / 3.0), 4.0, SHADE)


static func _draw_block(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var view := str(d.view)
	var nr := rows.size()
	var nc := str(rows[0]).length()
	if view == "side":
		var row := str(rows[0])
		var cw := r.size.x * 0.8 / nc
		var x0 := r.position.x + r.size.x * 0.1
		var base_y := r.position.y + r.size.y * 0.82
		var bh := r.size.y * 0.22
		ci.draw_rect(Rect2(Vector2(x0, base_y - bh), Vector2(cw * nc, bh)), WOOD)
		for i in nc:
			var raised := row[i] == "#"
			var top := base_y - bh - (r.size.y * 0.1 if raised else 0.0)
			if raised:
				ci.draw_rect(Rect2(Vector2(x0 + i * cw, top), Vector2(cw, r.size.y * 0.1)), WOOD)
				ci.draw_rect(Rect2(Vector2(x0 + i * cw, top - 4), Vector2(cw, 4)), INK)
			else:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x0 + i * cw, base_y - bh), Vector2(x0 + (i + 0.5) * cw, base_y - bh + r.size.y * 0.06),
					Vector2(x0 + (i + 1) * cw, base_y - bh)]), PAPER_WHITE.lerp(WOOD, 0.3))
		ci.draw_rect(Rect2(Vector2(x0, base_y - bh - r.size.y * 0.1), Vector2(cw * nc, bh + r.size.y * 0.1)), WOOD_DARK, false, 1.5)
		var roller := Vector2(x0 + cw * nc * 0.75, base_y - bh - r.size.y * 0.3)
		ci.draw_circle(roller, r.size.y * 0.1, INK)
		ci.draw_line(roller, roller + Vector2(r.size.x * 0.12, -r.size.y * 0.15), GREY, 4.0)
		var fs := clampi(int(r.size.y * 0.08), 8, 16)
		ci.draw_string(font, Vector2(r.position.x, r.position.y + fs), "the raised parts take the ink", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
		return
	var cell := minf(r.size.x / nc, r.size.y / nr)
	var o := r.get_center() - Vector2(nc, nr) * cell * 0.5
	var show: Array = rows   # the block's face, or the print as it is (print_rows turns a block into its print)
	if view == "block":
		ci.draw_rect(Rect2(o - Vector2(6, 6), Vector2(nc, nr) * cell + Vector2(12, 12)), WOOD_DARK)
	else:
		ci.draw_rect(Rect2(o - Vector2(6, 6), Vector2(nc, nr) * cell + Vector2(12, 12)), Color.WHITE)
	for y in nr:
		for x in nc:
			var on := str(show[y])[x] == "#"
			var b := Rect2(o + Vector2(x, y) * cell, Vector2(cell, cell))
			if view == "block":
				ci.draw_rect(b, Color("2b2b33") if on else WOOD)
				if not on:
					ci.draw_line(b.position + Vector2(cell * 0.2, cell * 0.3), b.position + Vector2(cell * 0.8, cell * 0.4), WOOD_DARK, 1.0)
					ci.draw_line(b.position + Vector2(cell * 0.2, cell * 0.7), b.position + Vector2(cell * 0.8, cell * 0.6), WOOD_DARK, 1.0)
			else:
				ci.draw_rect(b, Color("1c1c24") if on else Color.WHITE)
			if bool(d.get("grid", false)):
				ci.draw_rect(b, Color(GREY, 0.5), false, 1.0)


static func _draw_gallery(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var n := _int(d, "works", 3)
	var hang := str(d.hang)
	var mark := _int(d, "mark", -1)
	ci.draw_rect(r, Color("efe6d6"))
	var floor_y := r.end.y - r.size.y * 0.1
	ci.draw_rect(Rect2(Vector2(r.position.x, floor_y), Vector2(r.size.x, r.end.y - floor_y)), Color("b08a5a"))
	var m := (floor_y - r.position.y) / 2.6   # pixels a metre: the wall is 2.6 m high
	var eye_y := floor_y - 1.5 * m
	var sizes: Array[Vector2] = [Vector2(0.6, 0.8), Vector2(0.9, 0.6), Vector2(0.5, 0.5), Vector2(0.7, 0.9), Vector2(0.6, 0.45)]
	var heights: Array[float] = [0.2, -0.25, 0.35, -0.1, 0.15]
	var gap := r.size.x / (n + 1)
	for i in n:
		var s: Vector2 = sizes[i] * m
		var cx := r.position.x + gap * (i + 1)
		var cy := eye_y
		if hang == "tops":
			cy = eye_y - 0.5 * m + s.y * 0.5
		elif hang == "messy":
			cy = eye_y + heights[i] * m
		var frame := Rect2(Vector2(cx - s.x * 0.5, cy - s.y * 0.5), s)
		ci.draw_rect(frame.grow(4), Color("7a4a24"))
		ci.draw_rect(frame, [Color("bfe0f7"), Color("f7d9a6"), Color("d7f0d9"), Color("f7aaa6"), Color("d4b0ea")][i])
		ci.draw_circle(frame.get_center(), minf(s.x, s.y) * 0.2, [Color("2f6fdc"), Color("f28a1c"), GREEN, RED, Color("8a3fb8")][i])
		if i == mark:
			ci.draw_rect(frame.grow(9), SHADE, false, 3.0)
		if bool(d.get("labels", false)):
			ci.draw_rect(Rect2(Vector2(frame.end.x + 6, cy - m * 0.05), Vector2(m * 0.16, m * 0.1)), Color.WHITE)
	if bool(d.get("line", false)):
		SchoolPictureG6Arts._dashed(ci, Vector2(r.position.x, eye_y), Vector2(r.end.x, eye_y), SHADE, 2.0)
		var fs := clampi(int(m * 0.16), 8, 16)
		ci.draw_string(font, Vector2(r.position.x + 4, eye_y - 4), "1.5 m", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SHADE)
	# a visitor for scale
	var px := r.end.x - r.size.x * 0.05
	ci.draw_circle(Vector2(px, floor_y - 1.62 * m), 0.11 * m, INK)
	ci.draw_rect(Rect2(Vector2(px - 0.14 * m, floor_y - 1.5 * m), Vector2(0.28 * m, 0.7 * m)), INK)
	ci.draw_rect(Rect2(Vector2(px - 0.12 * m, floor_y - 0.8 * m), Vector2(0.24 * m, 0.8 * m)), INK)


# --- music -----------------------------------------------------------------------------------------------------------

static func _draw_chart(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var key := str(d.key)
	var chords: Array = d.chords
	var n := chords.size()
	var per_row := n if n <= 4 else 4
	var nrows := (n + per_row - 1) / per_row
	var names := bool(d.get("names", false))
	var numerals := bool(d.get("numerals", true))
	var mark := _int(d, "mark", -1)
	var hide: Array = d.get("hide", [])
	var title_h := r.size.y * 0.16
	var bw := r.size.x / per_row
	var bh := minf((r.size.y - title_h) / nrows, bw * 0.9)
	var fs := clampi(int(bh * 0.3), 9, 26)
	_label(ci, font, Vector2(r.get_center().x, r.position.y + title_h * 0.45), "%s major" % key, clampi(int(title_h * 0.7), 9, 20), INK)
	for i in n:
		var box := Rect2(Vector2(r.position.x + (i % per_row) * bw, r.position.y + title_h + (i / per_row) * bh), Vector2(bw, bh))
		var hidden := hide.has(i) or hide.has(float(i))
		ci.draw_rect(box.grow(-3), SOFT if i == mark else PAPER_WHITE)
		ci.draw_rect(box.grow(-3), SHADE if i == mark else INK, false, 3.0 if i == mark else 1.5)
		var numeral := str(chords[i])
		if hidden:
			_label(ci, font, box.get_center(), "?", int(fs * 1.4), SHADE)
			continue
		if names:
			_chord_label(ci, font, box.get_center() + Vector2(0, -bh * (0.14 if numerals else 0.0)), chord_name(key, numeral), int(fs * 1.2))
		if numerals:
			_label(ci, font, box.get_center() + Vector2(0, bh * (0.22 if names else 0.0)), numeral, int(fs * (0.85 if names else 1.3)),
				BLUE if numeral == numeral.to_upper() else Color("8a3fb8"))


## A chord's name with a drawn flat ("Bb" shows B and a flat sign).
static func _chord_label(ci: CanvasItem, font: Font, c: Vector2, name: String, fs: int) -> void:
	if name.length() >= 2 and name[1] == "b":
		var text := name.left(1) + "  " + name.substr(2)
		_label(ci, font, c, text, fs, INK)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var fw := font.get_string_size(name.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		SchoolPictureG6Arts._flat(ci, Vector2(c.x - w * 0.5 + fw + fs * 0.3, c.y), fs * 0.18, maxf(1.5, fs * 0.08))
	else:
		_label(ci, font, c, name, fs, INK)


static func _draw_ornament(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var note := str(d.note)
	var type := str(d.type)
	var played := bool(d.get("played", false))
	var notes: Array = [note]
	var values: Array = ["crotchet"]
	if played:
		for n: String in ornament_notes(type, note):
			notes.append(n)
			values.append("semiquaver" if type == "trill" else "quaver")
	var sd := {"kind": "clef_stave", "clef": "treble", "notes": notes, "values": values}
	var g := _stave_layout(r, sd)
	_draw_clef_stave(ci, font, r, sd)
	var u: float = g.u
	var first := Vector2(float(g.first_x), float(g.base_y) - clef_step(note, "treble") * u)
	var sign_c := Vector2(first.x, float(g.base_y) - 11.5 * u)
	var lw := maxf(1.5, u * 0.22)
	match type:
		"trill":
			_label(ci, font, sign_c + Vector2(-u * 0.8, 0), "tr", clampi(int(u * 2.4), 8, 28), INK)
			var pts := PackedVector2Array()
			for i in 9:
				pts.append(sign_c + Vector2(u * 0.6 + i * u * 0.5, (u * 0.35 if i % 2 == 0 else -u * 0.35)))
			ci.draw_polyline(pts, INK, lw)
		"mordent":
			var pts := PackedVector2Array()
			for i in 5:
				pts.append(sign_c + Vector2(-u * 1.2 + i * u * 0.6, (u * 0.5 if i % 2 == 0 else -u * 0.5)))
			ci.draw_polyline(pts, INK, lw * 1.4)
		"turn":
			var pts := PackedVector2Array()
			for i in 25:
				var t := TAU * i / 24.0
				var x := -u * 1.4 + u * 2.8 * i / 24.0
				pts.append(sign_c + Vector2(x, -sin(t) * u * 0.6))
			ci.draw_polyline(pts, INK, lw * 1.4)
	if played:
		var ax := float(g.first_x) + float(g.slot) * u * 0.62
		_arrow(ci, Vector2(ax, float(g.base_y) - 13.0 * u), Vector2(ax + float(g.slot) * u * 0.5, float(g.base_y) - 13.0 * u), SHADE, lw)


static func _draw_symphony(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var sonata := str(d.view) == "sonata"
	var titles: Array[String] = []
	titles.assign(["Exposition", "Development", "Recapitulation", "Coda"] if sonata else ["1 Fast", "2 Slow", "3 Minuet",
		"4 Fast"])
	var lines: Array = [["two themes:", "home key,", "then a new key"], ["the themes", "changed, in", "many keys"],
		["both themes", "again, in the", "home key"], ["the ending"]] if sonata \
		else [["sonata form,", "lively"], ["a song-like", "tune, calm"], ["a dance in", "3 beats, with", "a trio"], ["a lively", "finale"]]
	var colours: Array[Color] = [Color("3a7be8"), Color("8a3fb8"), Color("3aa845"), Color("f08a1c")]
	var widths: Array[float] = []
	widths.assign([0.28, 0.28, 0.3, 0.14] if sonata else [0.25, 0.25, 0.25, 0.25])
	var mark := _int(d, "mark", -1)
	var hide := _int(d, "hide", -1)
	var x := r.position.x
	var fs := _fs(r, 0.1, 18)
	for i in 4:
		var w := r.size.x * widths[i]
		var box := Rect2(Vector2(x + 3, r.position.y + r.size.y * 0.1), Vector2(w - 6, r.size.y * 0.8))
		_rounded(ci, box, colours[i].lightened(0.55), 10.0)
		_rounded(ci, Rect2(box.position, Vector2(box.size.x, box.size.y * 0.26)), colours[i], 10.0)
		var t := "?" if i == hide else titles[i]
		_label(ci, font, Vector2(box.get_center().x, box.position.y + box.size.y * 0.13), t, _fit(font, t, fs, box.size.x - 6), Color.WHITE)
		var ly := box.position.y + box.size.y * 0.4
		for line: String in lines[i]:
			_label(ci, font, Vector2(box.get_center().x, ly), line, _fit(font, line, int(fs * 0.85), box.size.x - 6), INK)
			ly += fs * 1.2
		if i == mark:
			var sb := StyleBoxFlat.new()
			sb.draw_center = false
			sb.set_border_width_all(4)
			sb.border_color = SHADE
			sb.set_corner_radius_all(12)
			ci.draw_style_box(sb, box.grow(3))
		x += w


static func _draw_kit(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var at := func(part: String) -> Vector2: return r.position + (KIT_PARTS[part] as Vector2) * r.size
	var s := minf(r.size.y, r.size.x * 0.5)
	var kick: Vector2 = at.call("kick drum")
	ci.draw_circle(kick, s * 0.25, Color("c0503a"))
	ci.draw_circle(kick, s * 0.21, Color("f3e3c8"))
	_ring(ci, kick, s * 0.25, INK, 2.0)
	var snare: Vector2 = at.call("snare drum")
	ci.draw_rect(Rect2(snare - Vector2(s * 0.14, s * 0.02), Vector2(s * 0.28, s * 0.12)), Color("c0503a"))
	SchoolPictureG4Arts._ellipse(ci, snare, Vector2(s * 0.14, s * 0.04), Color("f3e3c8"))
	ci.draw_line(snare + Vector2(0, s * 0.1), snare + Vector2(0, s * 0.35), GREY, 2.0)
	var toms: Vector2 = at.call("tom-toms")
	for k: float in [-1.0, 1.0]:
		var c := toms + Vector2(k * s * 0.1, 0)
		ci.draw_rect(Rect2(c - Vector2(s * 0.08, 0), Vector2(s * 0.16, s * 0.1)), Color("c0503a"))
		SchoolPictureG4Arts._ellipse(ci, c, Vector2(s * 0.08, s * 0.03), Color("f3e3c8"))
	var hat: Vector2 = at.call("hi-hat")
	SchoolPictureG4Arts._ellipse(ci, hat, Vector2(s * 0.14, s * 0.025), GOLD)
	SchoolPictureG4Arts._ellipse(ci, hat + Vector2(0, s * 0.03), Vector2(s * 0.14, s * 0.025), GOLD.darkened(0.2))
	ci.draw_line(hat + Vector2(0, s * 0.05), hat + Vector2(0, s * 0.6), GREY, 2.0)
	var crash: Vector2 = at.call("crash cymbal")
	SchoolPictureG4Arts._ellipse(ci, crash, Vector2(s * 0.17, s * 0.03), GOLD)
	ci.draw_line(crash, crash + Vector2(-s * 0.08, s * 0.7), GREY, 2.0)
	var mark := str(d.get("mark", ""))
	if KIT_PARTS.has(mark):
		_ring(ci, at.call(mark), s * 0.12, SHADE, 3.0)
	if bool(d.get("labels", false)):
		var fs := clampi(int(r.size.y * 0.07), 8, 16)
		for part: String in KIT_PARTS:
			var p: Vector2 = at.call(part)
			_label(ci, font, p + Vector2(0, -s * 0.09 if part != "kick drum" else s * 0.29), part, fs, INK)


## Every beat a piano roll's notes take (a rest too).
static func _roll_beats(notes: Array) -> int:
	var beats := 0
	for n: Variant in notes:
		var parts := str(n).split(":")
		beats += int(parts[1]) if parts.size() > 1 else 1
	return beats


## The lowest and highest pitch (semitones, C4 = 48) a piano roll shows: its notes', or `low` and `high`.
static func _roll_span(p: Dictionary) -> Vector2i:
	var lo := 999
	var hi := -999
	for n: Variant in p.get("notes", []):
		var name := str(n).split(":")[0]
		if name == "-":
			continue
		var s := _semis(name)
		lo = mini(lo, s)
		hi = maxi(hi, s)
	if lo > hi:
		return Vector2i(48, 48)
	return Vector2i(lo, hi)


static func _semis(name: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([2-6])$").search(name)
	if m == null:
		return 0
	return 12 * int(m.get_string(3)) + int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else -1 if m.get_string(2) == "b" else 0)


static func _draw_roll(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var notes: Array = d.notes
	var repeat := _int(d, "repeat", 1)
	var span := _roll_span(d)
	var lo := span.x - 1
	var hi := span.y + 1
	var rows := hi - lo + 1
	var beats := _roll_beats(notes) * repeat
	var per_bar := _int(d, "bar", 4)
	var key_w := r.size.x * 0.1
	var bw := (r.size.x - key_w) / beats
	var rh := r.size.y / rows
	var marks: Array = d.get("mark", [])
	for k in rows:
		var pitch := hi - k
		var black := [1, 3, 6, 8, 10].has(posmod(pitch, 12))
		var y := r.position.y + k * rh
		ci.draw_rect(Rect2(Vector2(r.position.x + key_w, y), Vector2(r.size.x - key_w, rh)), Color("eef1f7") if black else PAPER_WHITE)
		ci.draw_rect(Rect2(Vector2(r.position.x, y), Vector2(key_w, rh)), INK if black else Color.WHITE)
		ci.draw_rect(Rect2(Vector2(r.position.x, y), Vector2(key_w, rh)), GREY, false, 1.0)
		if posmod(pitch, 12) == 0 and rh > 8:
			var cname := "C%d" % (pitch / 12)
			_label(ci, font, Vector2(r.position.x + key_w * 0.5, y + rh * 0.5), cname, clampi(int(rh * 0.8), 7, 14), INK)
	for b in beats + 1:
		var x := r.position.x + key_w + b * bw
		ci.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), INK if b % per_bar == 0 else PALE.darkened(0.08), 2.0 if b % per_bar == 0 else 1.0)
	var at := 0
	for rep in repeat:
		for i in notes.size():
			var parts := str(notes[i]).split(":")
			var beats_long := int(parts[1]) if parts.size() > 1 else 1
			if parts[0] != "-":
				var k := hi - _semis(parts[0])
				var box := Rect2(Vector2(r.position.x + key_w + at * bw + 1, r.position.y + k * rh + 1),
					Vector2(beats_long * bw - 2, rh - 2))
				var col := SHADE if (marks.has(i) or marks.has(float(i))) and rep == 0 else BLUE
				if rep > 0:
					col = col.lerp(Color.WHITE, 0.4)
				_rounded(ci, box, col, minf(rh * 0.3, 6.0))
			at += beats_long


static func _draw_film(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var frames: Array = d.frames
	var n := frames.size()
	var captions: Array = d.get("captions", [])
	var mark := _int(d, "mark", -1)
	var strip_h := minf(r.size.y * (0.78 if captions.is_empty() else 0.66), r.size.x / n * 0.9)
	var strip := Rect2(Vector2(r.position.x, r.position.y), Vector2(r.size.x, strip_h))
	ci.draw_rect(strip, Color("22262e"))
	var hole := strip_h * 0.07
	var k := 0.0
	while k < r.size.x:
		ci.draw_rect(Rect2(Vector2(r.position.x + k + hole * 0.5, strip.position.y + hole * 0.6), Vector2(hole, hole)), Color("f4f1e8"))
		ci.draw_rect(Rect2(Vector2(r.position.x + k + hole * 0.5, strip.end.y - hole * 1.6), Vector2(hole, hole)), Color("f4f1e8"))
		k += hole * 2.4
	var fw := r.size.x / n
	var fs := _fs(r, 0.09, 16)
	for i in n:
		var f := Rect2(Vector2(r.position.x + i * fw + fw * 0.05, strip.position.y + hole * 2.2), Vector2(fw * 0.9, strip_h - hole * 4.4))
		_scene_frame(ci, f, str(frames[i]))
		if i == mark:
			ci.draw_rect(f.grow(3), SHADE, false, 4.0)
		if i < captions.size():
			_label(ci, font, Vector2(f.get_center().x, strip.end.y + (r.end.y - strip.end.y) * 0.45), str(captions[i]),
				_fit(font, str(captions[i]), fs, fw * 0.96), INK)


## A film frame's scene, drawn simply.
static func _scene_frame(ci: CanvasItem, f: Rect2, scene: String) -> void:
	var sky := {"hero": Color("f7d9a6"), "villain": Color("3a3150"), "chase": Color("bfe0f7"), "storm": Color("4a5566"),
		"sunrise": Color("f7c08a"), "sneak": Color("1f2a4a"), "comedy": Color("d7f0d9"), "farewell": Color("f7b8a0")}
	ci.draw_rect(f, sky.get(scene, Color("bfe0f7")))
	var ground_y := f.position.y + f.size.y * 0.72
	var ground := Color("8cc56a") if scene in ["hero", "chase", "comedy", "sunrise"] else Color("3b4a3a")
	if scene == "farewell" or scene == "storm":
		ground = Color("4f7fb0")
	ci.draw_rect(Rect2(Vector2(f.position.x, ground_y), Vector2(f.size.x, f.end.y - ground_y)), ground)
	var s := f.size.y
	match scene:
		"hero":
			ci.draw_circle(f.position + Vector2(f.size.x * 0.8, f.size.y * 0.25), s * 0.12, Color("f2c12e"))
			_person(ci, Vector2(f.get_center().x, ground_y), s * 0.45, Color("c0503a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(f.get_center().x - s * 0.04, ground_y - s * 0.34),
				Vector2(f.get_center().x - s * 0.2, ground_y - s * 0.05), Vector2(f.get_center().x - s * 0.05, ground_y - s * 0.1)]), Color("e03a2f"))
		"villain":
			var t := Rect2(Vector2(f.get_center().x - s * 0.12, f.position.y + s * 0.2), Vector2(s * 0.24, ground_y - f.position.y - s * 0.2))
			ci.draw_rect(t, Color("15121f"))
			for kx in 3:
				ci.draw_rect(Rect2(t.position + Vector2(kx * s * 0.09, -s * 0.06), Vector2(s * 0.06, s * 0.06)), Color("15121f"))
			ci.draw_rect(Rect2(t.get_center() - Vector2(s * 0.03, s * 0.05), Vector2(s * 0.06, s * 0.05)), Color("f2c12e"))
		"chase":
			for kx in 2:
				var c := Vector2(f.position.x + f.size.x * (0.3 + kx * 0.4), ground_y - s * 0.08)
				ci.draw_rect(Rect2(c - Vector2(s * 0.12, s * 0.1), Vector2(s * 0.24, s * 0.1)), [Color("c0503a"), Color("3a6fc0")][kx])
				ci.draw_circle(c + Vector2(-s * 0.07, 0), s * 0.04, INK)
				ci.draw_circle(c + Vector2(s * 0.07, 0), s * 0.04, INK)
				for l in 3:
					ci.draw_line(c + Vector2(-s * 0.16, -s * 0.03 * l), c + Vector2(-s * 0.28, -s * 0.03 * l), Color.WHITE, 1.5)
		"storm":
			var bolt := PackedVector2Array([f.position + Vector2(f.size.x * 0.55, 0), f.position + Vector2(f.size.x * 0.45, f.size.y * 0.3),
				f.position + Vector2(f.size.x * 0.55, f.size.y * 0.3), f.position + Vector2(f.size.x * 0.42, f.size.y * 0.62)])
			ci.draw_polyline(bolt, Color("f2e14a"), maxf(2.0, s * 0.03))
			for kx in 4:
				var wx := f.position.x + f.size.x * kx / 4.0
				ci.draw_arc(Vector2(wx + f.size.x * 0.12, ground_y + s * 0.06), f.size.x * 0.12, PI, TAU, 8, Color.WHITE, 2.0)
		"sunrise":
			ci.draw_circle(Vector2(f.get_center().x, ground_y), s * 0.2, Color("f2a31e"))
			ci.draw_rect(Rect2(Vector2(f.position.x, ground_y), Vector2(f.size.x, f.end.y - ground_y)), Color("6fae4a"))
		"sneak":
			ci.draw_circle(f.position + Vector2(f.size.x * 0.8, f.size.y * 0.22), s * 0.08, Color("f4f1e8"))
			var c := Vector2(f.get_center().x, ground_y)
			_person(ci, c + Vector2(0, 0), s * 0.35, Color("15121f"))
			ci.draw_line(c + Vector2(-s * 0.05, 0), c + Vector2(-s * 0.15, -s * 0.05), Color("15121f"), 3.0)
		"comedy":
			var c := Vector2(f.get_center().x, ground_y - s * 0.12)
			ci.draw_rect(Rect2(c - Vector2(s * 0.12, s * 0.12), Vector2(s * 0.24, s * 0.24)), Color("f2c12e"))
			ci.draw_circle(c + Vector2(-s * 0.05, -s * 0.04), s * 0.025, INK)
			ci.draw_circle(c + Vector2(s * 0.05, -s * 0.04), s * 0.025, INK)
			ci.draw_arc(c + Vector2(0, s * 0.02), s * 0.06, 0.2, PI - 0.2, 8, INK, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.2, s * 0.12), c + Vector2(s * 0.36, s * 0.1), c + Vector2(s * 0.3, s * 0.14)]), Color("f2e14a"))
		"farewell":
			var boat := Vector2(f.position.x + f.size.x * 0.7, ground_y + s * 0.02)
			ci.draw_colored_polygon(PackedVector2Array([boat + Vector2(-s * 0.15, 0), boat + Vector2(s * 0.15, 0), boat + Vector2(s * 0.1, s * 0.07),
				boat + Vector2(-s * 0.1, s * 0.07)]), Color("7a4a24"))
			ci.draw_colored_polygon(PackedVector2Array([boat + Vector2(0, -s * 0.3), boat + Vector2(s * 0.12, -s * 0.02), boat + Vector2(0, -s * 0.02)]), Color.WHITE)
			ci.draw_rect(Rect2(Vector2(f.position.x, ground_y - s * 0.02), Vector2(f.size.x * 0.3, s * 0.04)), Color("8a6036"))
			_person(ci, Vector2(f.position.x + f.size.x * 0.18, ground_y - s * 0.02), s * 0.35, Color("8a3fb8"))


static func _draw_mixer(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var faders: Array = d.faders
	var n := faders.size()
	var mark := _int(d, "mark", -1)
	var meters := bool(d.get("meters", false))
	_rounded(ci, r, Color("2b3140"), 12.0)
	var cw := r.size.x / n
	var fs := clampi(int(minf(cw * 0.16, r.size.y * 0.08)), 8, 16)
	var top := r.position.y + r.size.y * 0.1
	var bottom := r.end.y - r.size.y * 0.2
	for i in n:
		var cx := r.position.x + (i + 0.5) * cw
		var level := int(faders[i][1])
		ci.draw_line(Vector2(cx, top), Vector2(cx, bottom), Color("11151c"), maxf(4.0, cw * 0.06))
		for t in 11:
			var y := bottom - (bottom - top) * t / 10.0
			ci.draw_line(Vector2(cx - cw * 0.16, y), Vector2(cx - cw * 0.1, y), Color("6a7486"), 1.0)
		if meters:
			for t in level:
				var y := bottom - (bottom - top) * (t + 0.5) / 10.0
				ci.draw_rect(Rect2(Vector2(cx + cw * 0.14, y - 3), Vector2(cw * 0.08, 6)), GREEN if t < 7 else (Color("f2c12e") if t < 9 else RED))
		var ky := bottom - (bottom - top) * level / 10.0
		var knob := Rect2(Vector2(cx - cw * 0.14, ky - r.size.y * 0.035), Vector2(cw * 0.28, r.size.y * 0.07))
		_rounded(ci, knob, SHADE if i == mark else Color("d9dde6"), 4.0)
		ci.draw_line(Vector2(knob.position.x + 3, ky), Vector2(knob.end.x - 3, ky), INK, 2.0)
		var name := str(faders[i][0])
		_label(ci, font, Vector2(cx, r.end.y - r.size.y * 0.12), name, _fit(font, name, fs, cw * 0.95), Color.WHITE)
		_label(ci, font, Vector2(cx, r.end.y - r.size.y * 0.04), str(level), clampi(int(fs * 0.85), 7, 14), Color("9fb3c8"))


## Where a clef stave's parts go: u (half a gap), the bottom line of the (lower) stave, the first note's x, a note's slot.
static func _stave_layout(r: Rect2, d: Dictionary) -> Dictionary:
	var notes: Array = d.notes
	var clef := str(d.clef)
	var names := bool(d.get("names", false))
	var fs := clampi(int(r.size.y * 0.1), 10, 20)
	var name_h := fs * 1.4 if names else 0.0
	var n := notes.size()
	var lead := 5.8 + (4.0 if d.has("time") else 0.0)
	var slot := 4.6
	var span := 15.5 if clef != "grand" else 29.0
	var u := minf((r.size.y - name_h) / span, r.size.x / (lead + n * slot + 1.0))
	var width := (lead + n * slot + 1.0) * u
	var x0 := r.position.x + (r.size.x - width) * 0.5
	var base_y := r.position.y + (r.size.y - name_h) * 0.5 + 4.0 * u
	if clef == "grand":   # the bass stave's bottom line; the treble's is 20 half-gaps up, its top 30 up
		base_y = r.position.y + (r.size.y - name_h) * 0.5 + 11.25 * u
	return {"u": u, "x0": x0, "width": width, "base_y": base_y, "lead": lead, "slot": slot, "fs": fs, "name_h": name_h,
		"first_x": x0 + lead * u + slot * 0.5 * u}


static func _draw_clef_stave(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var g := _stave_layout(r, d)
	var u: float = g.u
	var x0: float = g.x0
	var width: float = g.width
	var base_y: float = g.base_y
	var clef := str(d.clef)
	var notes: Array = d.notes
	var values: Array = d.get("values", [])
	var ties: Array = d.get("ties", [])
	var mark := _int(d, "mark", -1)
	var names := bool(d.get("names", false))
	var lw := maxf(1.2, u * 0.12)
	var staves: Array[float] = [base_y]   # the bottom line of each stave; the grand stave's treble is 12 half-gaps up
	if clef == "grand":
		staves = [base_y, base_y - 14.0 * u]   # middle C's ledger lines between them
	for sy: float in staves:
		for i in 5:
			var y := sy - i * 2.0 * u
			ci.draw_line(Vector2(x0, y), Vector2(x0 + width, y), INK, lw)
	if clef == "treble":
		SchoolPictureG4Arts._treble_clef(ci, Vector2(x0 + 2.2 * u, base_y), u, lw)
	elif clef == "bass":
		_bass_clef(ci, Vector2(x0 + 1.6 * u, base_y), u, lw)
	else:
		_bass_clef(ci, Vector2(x0 + 1.6 * u, staves[0]), u, lw)
		SchoolPictureG4Arts._treble_clef(ci, Vector2(x0 + 2.2 * u, staves[1]), u, lw)
		ci.draw_line(Vector2(x0, staves[1] - 8.0 * u), Vector2(x0, staves[0]), INK, lw * 2.0)
	var at := x0 + 5.8 * u
	if d.has("time"):
		var time := str(d.time)
		var tfs := clampi(int(u * 3.6), 10, 64)
		for sy: float in staves:
			_label(ci, font, Vector2(at + 2.1 * u, sy - 6.0 * u), time.get_slice("/", 0), tfs)
			_label(ci, font, Vector2(at + 2.1 * u, sy - 2.0 * u), time.get_slice("/", 1), tfs)
		at += 4.0 * u
	var slot: float = g.slot
	var per_bar := float(TIMES.get(str(d.get("time", "4/4")), 4.0))
	var beats := 0.0
	var total := 0.0
	for i in notes.size():
		total += float(VALUE_BEATS[str(values[i]) if i < values.size() else "crotchet"])
	var centres: Array[Vector2] = []
	for i in notes.size():
		var note := str(notes[i])
		var value := str(values[i]) if i < values.size() else "crotchet"
		var step := clef_step(note, clef)
		var sy: float = base_y
		if step >= 500:   # the grand stave's treble
			step -= 1000
			sy = staves[1]
		var c := Vector2(at + slot * 0.5 * u, sy - step * u)
		centres.append(c)
		var col := SHADE if i == mark else INK
		for ledger: int in [-2, 10]:
			if (ledger < 0 and step <= ledger) or (ledger > 0 and step >= ledger):
				var ly := sy - ledger * u
				ci.draw_line(Vector2(c.x - 1.9 * u, ly), Vector2(c.x + 1.9 * u, ly), INK, lw)
		_note_head(ci, c, u, lw, value, step < 4, col)
		if names:
			_label(ci, font, Vector2(c.x, r.end.y - float(g.name_h) * 0.5), note.left(1), _fit(font, note.left(1), int(g.fs), slot * u * 0.98), col)
		at += slot * u
		beats += float(VALUE_BEATS[value])
		if bool(d.get("bars", false)) and absf(fmod(beats, per_bar)) < 0.001:
			var bx := at - 0.2 * u
			for sy2: float in staves:
				if beats < total - 0.001:
					ci.draw_line(Vector2(bx, sy2), Vector2(bx, sy2 - 8.0 * u), INK, lw)
				else:
					ci.draw_line(Vector2(bx - 0.9 * u, sy2), Vector2(bx - 0.9 * u, sy2 - 8.0 * u), INK, lw)
					ci.draw_line(Vector2(bx, sy2), Vector2(bx, sy2 - 8.0 * u), INK, lw * 2.6)
	for t: Variant in ties:
		var i := int(t)
		var a: Vector2 = centres[i]
		var b: Vector2 = centres[i + 1]
		var st := clef_step(str(notes[i]), clef)
		var below := (st - 1000 if st >= 500 else st) >= 4
		var dir := 1.0 if below else -1.0
		var pts := PackedVector2Array()
		for k in 11:
			var s := k / 10.0
			pts.append(a.lerp(b, s) + Vector2(0, dir * (1.4 * u + sin(s * PI) * 1.4 * u)))
		ci.draw_polyline(pts, INK, lw * 1.6, true)


## A note's head and stem (flags for quavers and semiquavers, a dot for a dotted note).
static func _note_head(ci: CanvasItem, c: Vector2, u: float, lw: float, value: String, up: bool, col: Color) -> void:
	var plain := value.trim_prefix("dotted ")
	var map := {"semibreve": "semibreve", "minim": "minim", "crotchet": "crotchet", "quaver": "quaver", "semiquaver": "quaver"}
	SchoolPictureG4Arts._stave_note(ci, c, u, lw, str(map.get(plain, "crotchet")), up, col)
	var rx := u * (1.45 if plain == "semibreve" else 1.2)
	if value.begins_with("dotted "):
		ci.draw_circle(c + Vector2(rx + u * 0.9, -u * 0.35), u * 0.38, col)
	if plain == "semiquaver":   # a second flag under the first
		var sx := c.x + (rx * 0.92 if up else -rx * 0.92)
		var dir := 1.0 if up else -1.0
		var tip := Vector2(sx, c.y + (-7.0 * u if up else 7.0 * u)) + Vector2(0, dir * 1.6 * u)
		var flag := PackedVector2Array([tip, tip + Vector2(u * 0.9, dir * u * 1.4), tip + Vector2(u * 1.6, dir * u * 2.6),
			tip + Vector2(u * 1.1, dir * u * 3.8)])
		ci.draw_polyline(SchoolPictureG4Arts._catmull(flag, 5), col, lw * 1.6, true)


## The bass (F) clef: a dot on the F line (the fourth line up), a curl up round and down to the right, and two dots
## either side of the F line.
static func _bass_clef(ci: CanvasItem, bottom_left: Vector2, u: float, lw: float) -> void:
	var f_y := bottom_left.y - 6.0 * u
	var start := Vector2(bottom_left.x + 0.4 * u, f_y)
	ci.draw_circle(start, u * 0.7, INK)
	var raw: Array[Vector2] = [Vector2(0.2, 0.3), Vector2(0.8, 1.5), Vector2(1.9, 2.0), Vector2(2.9, 1.3), Vector2(3.3, -0.2),
		Vector2(2.9, -1.9), Vector2(1.9, -3.3), Vector2(0.5, -4.5)]
	var pts := PackedVector2Array()
	for p in raw:
		pts.append(Vector2(bottom_left.x + p.x * u, f_y - p.y * u))
	ci.draw_polyline(SchoolPictureG4Arts._catmull(pts, 6), INK, lw * 2.4, true)
	ci.draw_circle(Vector2(bottom_left.x + 4.3 * u, f_y - u), u * 0.38, INK)
	ci.draw_circle(Vector2(bottom_left.x + 4.3 * u, f_y + u), u * 0.38, INK)


# --- helpers ---------------------------------------------------------------------------------------------------------

static func _arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, lw: float) -> void:
	ci.draw_line(a, b, col, lw)
	var dir := (b - a).normalized()
	var side := dir.orthogonal()
	var head := maxf(6.0, lw * 3.0)
	ci.draw_colored_polygon(PackedVector2Array([b + dir * head * 0.3, b - dir * head + side * head * 0.6,
		b - dir * head - side * head * 0.6]), col)


static func _ring(ci: CanvasItem, c: Vector2, rad: float, col: Color, lw: float) -> void:
	ci.draw_arc(c, rad, 0.0, TAU, 40, col, lw, true)


static func _fs(r: Rect2, share: float = 0.11, most: int = 22) -> int:
	return clampi(int(r.size.y * share), 9, most)


static func _label(ci: CanvasItem, font: Font, c: Vector2, text: String, size: int, color: Color = INK) -> void:
	SchoolPictureG4Arts._label(ci, font, c, text, size, color)


static func _fit(font: Font, text: String, size: int, width: float) -> int:
	return SchoolPictureG4Arts._fit(font, text, size, width)


static func _rounded(ci: CanvasItem, box: Rect2, col: Color, radius: float) -> void:
	SchoolPictureG4Arts._rounded(ci, box, col, radius)


static func _short(t: Variant, most: int) -> bool:
	return t is String and str(t).strip_edges() != "" and str(t).length() <= most


static func _texts(a: Variant, n: int, most: int) -> bool:
	if not a is Array or (a as Array).size() != n:
		return false
	for t: Variant in a:
		if not _short(t, most):
			return false
	return true


static func _int(p: Dictionary, key: String, default: int) -> int:
	var v: Variant = p.get(key, default)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else default


static func _in(v: int, lo: int, hi: int) -> bool:
	return v >= lo and v <= hi
