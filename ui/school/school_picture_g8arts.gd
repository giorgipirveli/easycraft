class_name SchoolPictureG8Arts
extends RefCounted
## Owner #70, #73 and #111, grade 8 computing, art and music (research §6.8): the picture kinds they add, drawn from data
## onto a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the font
## has no arrows, music signs or ticks, so they are drawn). A diagram's `labels` name its parts in bands along its top
## and bottom, each with a line to its part; `mark` (a part) is orange and `hide` (a part) shows "?"; its parts' places
## are `part_at`'s, so a label exercise's pins can point at them. Kinds and fields:
## Computing
## - structure_chart {top (18), parts: [[name (16), [sub (16)] (0-3)]] (2-4), mark? (a name), hide? (a name, shown
##   "?")}: a program planned in modules: the whole job at the top, its modules under it and their parts under them.
## - step_growth {lines: [GROWTH] (1-3), upto (4-64: the items n along the bottom), at? (1-upto: a dashed line there
##   with each line's steps)}: how an algorithm's worst-case steps grow with the items it works on: linear search n,
##   binary search ⌊log₂ n⌋ + 1, bubble sort's comparisons n(n − 1) ÷ 2 (`steps_for`).
## - state_machine {states: [name (14)] (2-5), arrows: [[from, to, event (14)]] (1-8, state indexes, from ≠ to),
##   current? (a state's index, green), mark? (an arrow's index, orange)}: a model's states and the events that move it
##   from one to the next (a traffic light, a game).
## - abstract_map {view: "real" | "model", route? [STOPS] (2+, each next to the last on a line: drawn thick and orange),
##   mark? (a stop)}: a town's real map (winding streets, a river, the sea, buildings) or the same railway as a model:
##   straight lines and evenly spaced stops, as Harry Beck drew the London Underground in 1931 (`stops_between`).
## - cpu_cycle {view: "cycle" | "machine", step? ("fetch" | "decode" | "execute": orange), memory? [[address (0-99),
##   contents (12)]] (1-8; machine), pc? (an address: its row ringed and in the program counter), acc? (the accumulator:
##   a number or "?"), labels?, mark?, hide? (CPU_PARTS)}: the fetch-decode-execute cycle, or inside a processor: the
##   control unit, the ALU and the registers, joined to memory by the bus (`part_at`).
## - sampled_wave {samples: [whole 0 to 2^bits − 1] (4-24), bits (1-4: 2^bits levels, the grid's lines), wave? (true:
##   the smooth sound wave behind), view? ("dots", "bars" or "steps": the sound as it is stored)}: a sound sampled.
## - gate_circuit {expr: a gate ["AND" | "OR", a, b] or ["NOT", a] whose inputs are gates or letters "A"-"D" (1-3
##   gates), inputs: {letter: 0 or 1} (every letter used), out? (true: the output and its lamp; false: "?"), lit? (true:
##   each wire's 0 or 1, a 1 orange)}: a logic circuit, inputs on the left and a lamp on the right (`circuit_out`).
## - db_table {name (12), fields: [text (10)] (2-5), rows: [[text (10)]] (1-7, as long as fields), key? (the primary
##   key's field index: underlined, with a key), pick? [row indexes] (the records a query finds, shaded), field? (a field
##   index, shaded), query? (60: shown above)}: a database table: its field names and records.
## - scatter_learn {axes: [x (16), y (16)], groups: [name (16), name (16)], points: [[x, y, group 0 or 1]] (2-16; x and y
##   0-10), new? ([x, y]: the one to classify, "?"), near? (1-5: the new one's nearest points ringed and joined to it),
##   line? ([x0, y0, x1, y1]: a dividing line)}: training examples measured two ways (`nearest`).
## - threat_card {threat: THREATS, name? (true: its name under it)}: a cyber threat: a virus spreading through files, a
##   worm through a network, a trojan hidden in a free download, ransomware locking files, spyware watching the keys, a
##   phishing hook, someone looking over a shoulder.
## - app_screen {design: SCREENS, labels?, mark?, hide? (SCREEN_PARTS: the clear design's)}: a homework planner app on
##   a phone, designed clearly or with one usability problem (tiny buttons, low contrast, clutter, colour alone, icons
##   with no words) (`part_at`).
## Art
## - light_series {times: [TIMES] (1-4), names? (true: each time under its painting)}: a haystack painted at different
##   times of day and year, as Claude Monet painted his series: the light's colour and the shadows' colour change.
## - brushwork {style: "smooth" | "broken" | "dots"}: one sunset over water painted smoothly blended, in Impressionist
##   broken strokes side by side, or in Pointillist dots of pure colour.
## - movement_piece {style: MOVEMENTS}: a picture in a modern art movement's way: realist fruit, a Cubist guitar of facets
##   seen from many sides, a Surrealist melting clock, a Pop Art grid of bright tins, a Fauvist landscape in wild colours.
## - camera_obscura {labels?, mark?, hide? (OBSCURA_PARTS)}: a dark box with a pinhole: light from a tree crosses at the
##   hole and makes an upside-down picture on the back (`part_at`).
## - raster_vector {view: "raster" | "vector", zoom? (true: a part zoomed in beside it)}: a circle stored as pixels
##   (blocky when zoomed in) or as a vector path through points (smooth at any size).
## - symbol_portrait {symbols: [SYMBOLS] (0-6), names? (true), mark? (a symbol)}: a self-portrait with symbols round it
##   that say who the person is.
## - grid_enlarge {rows: [text] (2-6 rows of 2-6 letters, all as long), key: {letter: a colour of SchoolPictureArts},
##   done? (squares copied onto the wall, in reading order; all), sizes? [design (10), wall (10)] (one square's size
##   on each)}: a mural's small design with a grid, and the wall with the same grid made big.
## - object_design {what: OBJECTS, labels?, mark?, hide? (OBJECT_PARTS[what])}: a designed object and its parts: a
##   balanced-arm lamp, a stacking chair, a dial telephone, a smartphone (`part_at`).
## - flip_frames {count (4-12), ease? (true: slow in and slow out: the frames bunch at the top), squash? (true: squashed
##   on the ground, stretched when fast), view? ("onion": every frame over one scene, the default; "strip": frames side by
##   side), mark? (a frame's index, orange)}: a bouncing ball's animation frames (`ball_at`).
## - mobile_balance {left: [[weight 1-10, distance 1-5]] (1-2), right: (the same), numbers? (true), hide? ([side, index]:
##   that weight shown "?"), still? (true: drawn level, held still, for "which way will it tip?")}: a hanging mobile's arm: it balances when weight × distance is the same on both sides; it
##   tips to the side that turns more (`turning`).
## - gallery_plan {works: [[name (10), x, y]] (1-6, 0.08-0.92 of the room), door: "bottom" | "left", path? [work
##   indexes] (the visitors' way from the door, dashed), mark? (a work's index), size? [width (6), depth (6)]}: a room's
##   plan from above with the works placed in it.
## - wall_label {title (26), artist (26), date (16), medium (30), size? (20), lines? [text (36)] (0-3)}: a museum label.
## Music
## - swing_beats {rows: ["straight" | "swing"] (1-2, each once), beats (2-4), mark? (a row's index)}: quavers in pairs,
##   each pair one beat: straight pairs split the beat in half, swung pairs long-short (two thirds, then one third).
## - jazz_band {labels?, mark?, hide? (BAND_PARTS)}: a jazz band on a stage: the front line (trumpet, saxophone,
##   trombone) and the rhythm section (piano, double bass, drums) (`part_at`).
## - instrument_ranges {instruments: [RANGE_NAMES] (1-6), note? (a note "E1"-"C8": a line across at it), mark? (an
##   instrument), names? (true: the lowest and highest notes)}: each instrument's range (the notes it can play) over
##   a keyboard (`range_of`, `pitch_of`).
## - opera_house {labels?, mark?, hide? (OPERA_PARTS)}: an opera house from the side: the audience, the orchestra pit
##   and its conductor, the stage and its curtain, the surtitles above (`part_at`).

const KINDS: Array[String] = ["structure_chart", "step_growth", "state_machine", "abstract_map", "cpu_cycle",
	"sampled_wave", "gate_circuit", "db_table", "scatter_learn", "threat_card", "app_screen", "light_series", "brushwork",
	"movement_piece", "camera_obscura", "raster_vector", "symbol_portrait", "grid_enlarge", "object_design",
	"flip_frames", "mobile_balance", "gallery_plan", "wall_label", "jazz_band", "instrument_ranges", "opera_house",
	"swing_beats"]
const INK := Color("1f2a4a")    # SchoolUi.INK
const PAPER := Color("fdf6e3")  # SchoolUi.PAPER
const ORANGE := Color("f08a1c")
const SOFT := Color("fce2b8")
const RED := Color("d9433b")
const BLUE := Color("3a7be8")
const GREEN := Color("3fa34d")
const GREY := Color("9aa1ad")
const PALE := Color("eef1f6")
const GOLD := Color("e0b23a")
const SKIN := Color("e0ac7e")
const HAIR := Color("4a3222")
const WOOD := Color("9a6a3c")

## Each labelled diagram is drawn in a box of this shape (width ÷ height), so its parts' places are worked out from the
## picture's size alone.
const RATIOS := {"cpu_cycle": 2.2, "camera_obscura": 2.2, "object_design": 2.2, "jazz_band": 2.2, "opera_house": 2.2,
	"app_screen": 2.2}

# --- Computing ---
const MAX_TOP := 18
const MAX_MODULE := 16
const GROWTH: Array[String] = ["linear", "binary", "bubble"]
const GROWTH_NAMES := {"linear": "linear search", "binary": "binary search", "bubble": "bubble sort"}
const GROWTH_COLOURS := {"linear": Color("2f6fdc"), "binary": Color("2e8b3e"), "bubble": Color("d9433b")}
const MAX_STATE := 14
const MAX_EVENT := 14
const STOPS: Array[String] = ["Hill", "Park", "Market", "Station", "Harbour", "School", "Castle"]
## The railway's two lines, stop by stop (Market is on both).
const RAIL_LINES := {"red": ["Hill", "Park", "Market", "Station", "Harbour"], "blue": ["School", "Market", "Castle"]}
const RAIL_COLOURS := {"red": Color("d9433b"), "blue": Color("2f6fdc")}
## Where each stop is on the town's real map and on the model (shares of the picture).
const REAL_AT := {"Hill": Vector2(0.08, 0.2), "Park": Vector2(0.24, 0.46), "Market": Vector2(0.44, 0.58),
	"Station": Vector2(0.63, 0.36), "Harbour": Vector2(0.86, 0.62), "School": Vector2(0.3, 0.9), "Castle": Vector2(0.7, 0.13)}
const MODEL_AT := {"Hill": Vector2(0.08, 0.5), "Park": Vector2(0.27, 0.5), "Market": Vector2(0.46, 0.5),
	"Station": Vector2(0.66, 0.5), "Harbour": Vector2(0.88, 0.5), "School": Vector2(0.46, 0.13), "Castle": Vector2(0.46, 0.87)}
const CYCLE_STEPS: Array[String] = ["fetch", "decode", "execute"]
const CYCLE_SAID := {"fetch": "get the next instruction", "decode": "work out what it means", "execute": "do it"}
const CPU_PARTS: Array[String] = ["control unit", "ALU", "program counter", "accumulator", "memory", "bus"]
const CPU_AT := {"control unit": Vector2(0.17, 0.35), "ALU": Vector2(0.4, 0.35), "program counter": Vector2(0.17, 0.75),
	"accumulator": Vector2(0.4, 0.75), "memory": Vector2(0.84, 0.1), "bus": Vector2(0.615, 0.5)}
const MAX_MEMORY := 8
const MAX_CONTENTS := 12
const GATES: Array[String] = ["AND", "OR", "NOT"]
const INPUT_LETTERS: Array[String] = ["A", "B", "C", "D"]
const MAX_GATES := 3
const MAX_FIELDS := 5
const MAX_RECORDS := 7
const MAX_CELL := 10
const MAX_QUERY := 60
const MAX_POINTS := 16
const THREATS: Array[String] = ["virus", "worm", "trojan", "ransomware", "spyware", "phishing", "shoulder_surfing"]
const THREAT_NAMES := {"virus": "virus", "worm": "worm", "trojan": "trojan", "ransomware": "ransomware",
	"spyware": "spyware", "phishing": "phishing", "shoulder_surfing": "shoulder surfing"}
const SCREENS: Array[String] = ["clear", "tiny", "low_contrast", "cluttered", "colour_only", "no_words"]
const SCREEN_PARTS: Array[String] = ["back button", "title", "task list", "add button"]
const SCREEN_AT := {"back button": Vector2(0.385, 0.12), "title": Vector2(0.53, 0.12), "task list": Vector2(0.5, 0.47),
	"add button": Vector2(0.5, 0.81)}
# --- Art ---
const TIMES: Array[String] = ["morning", "noon", "evening", "winter"]
## Each time's colours: sky (top, bottom), sun, ground, the haystack's lit side, its shadow side; where the sun is.
const TIME_COLOURS := {
	"morning": [Color("f4cfc7"), Color("cfe0f2"), Color("fff1c4"), Color("b9d39a"), Color("f2c27a"), Color("8f9fc9")],
	"noon": [Color("7fbaf0"), Color("d4eafb"), Color("fffbe0"), Color("c6d670"), Color("f6dc6e"), Color("a88f52")],
	"evening": [Color("ee7f3a"), Color("f7c66b"), Color("ffd27a"), Color("b5864c"), Color("e8743c"), Color("6d4a8a")],
	"winter": [Color("d5dbe6"), Color("eef1f5"), Color("f8f4e8"), Color("eef2f7"), Color("d9c7a8"), Color("8d9bbd")]}
const SUN_AT := {"morning": Vector2(0.16, 0.36), "noon": Vector2(0.5, 0.1), "evening": Vector2(0.84, 0.38),
	"winter": Vector2(0.78, 0.3)}
const STYLES: Array[String] = ["smooth", "broken", "dots"]
const MOVEMENTS: Array[String] = ["realist", "cubist", "surreal", "pop", "fauve"]
const OBSCURA_PARTS: Array[String] = ["object", "light rays", "pinhole", "dark box", "upside-down image"]
const OBSCURA_AT := {"object": Vector2(0.11, 0.38), "light rays": Vector2(0.3, 0.37), "pinhole": Vector2(0.5, 0.52),
	"dark box": Vector2(0.64, 0.18), "upside-down image": Vector2(0.75, 0.62)}
const SYMBOLS: Array[String] = ["book", "ball", "music", "brush", "plant", "cat", "rocket", "home"]
## Where each of up to six symbols sits round the portrait (shares of the picture).
const SYMBOL_SLOTS: Array[Vector2] = [Vector2(0.14, 0.22), Vector2(0.86, 0.22), Vector2(0.1, 0.56), Vector2(0.9, 0.56),
	Vector2(0.18, 0.86), Vector2(0.82, 0.86)]
const MAX_GRID := 6
const OBJECTS: Array[String] = ["lamp", "chair", "dial_phone", "smartphone"]
const OBJECT_PARTS := {"lamp": ["base", "arm", "springs", "joint", "shade"], "chair": ["backrest", "seat", "legs", "frame"],
	"dial_phone": ["handset", "earpiece", "mouthpiece", "dial", "cord"],
	"smartphone": ["screen", "camera", "button", "speaker", "microphone"]}
const OBJECT_AT := {
	"lamp": {"base": Vector2(0.5, 0.9), "arm": Vector2(0.52, 0.335), "springs": Vector2(0.497, 0.655),
		"joint": Vector2(0.42, 0.45), "shade": Vector2(0.69, 0.36)},
	"chair": {"backrest": Vector2(0.585, 0.26), "seat": Vector2(0.49, 0.5), "legs": Vector2(0.42, 0.84),
		"frame": Vector2(0.5, 0.74)},
	"dial_phone": {"handset": Vector2(0.5, 0.4), "earpiece": Vector2(0.31, 0.46), "mouthpiece": Vector2(0.69, 0.46),
		"dial": Vector2(0.5, 0.68), "cord": Vector2(0.18, 0.68)},
	"smartphone": {"screen": Vector2(0.5, 0.5), "camera": Vector2(0.5, 0.115), "button": Vector2(0.6, 0.32),
		"speaker": Vector2(0.455, 0.905), "microphone": Vector2(0.545, 0.905)}}
const MAX_FRAMES := 12
const MAX_WEIGHT := 10
const MAX_DISTANCE := 5
const MAX_WORKS := 6
const MAX_WORK := 10
# --- Music ---
const BAND_PARTS: Array[String] = ["trumpet", "saxophone", "trombone", "piano", "double bass", "drums"]
const BAND_AT := {"piano": Vector2(0.17, 0.4), "double bass": Vector2(0.5, 0.36), "drums": Vector2(0.83, 0.42),
	"trumpet": Vector2(0.29, 0.76), "saxophone": Vector2(0.5, 0.76), "trombone": Vector2(0.71, 0.76)}
## Each instrument's or voice's range, the notes as they sound (rounded to the commonly taught limits; a player may go
## beyond the top).
const RANGES := {"flute": ["C4", "C7"], "clarinet": ["D3", "B6"], "trumpet": ["E3", "B5"], "trombone": ["E2", "F5"],
	"tuba": ["D1", "F4"], "violin": ["G3", "A7"], "viola": ["C3", "E6"], "cello": ["C2", "A5"],
	"double bass": ["E1", "G4"], "soprano": ["C4", "A5"], "alto": ["F3", "D5"], "tenor": ["C3", "A4"], "bass": ["E2", "E4"]}
const RANGE_NAMES: Array[String] = ["flute", "clarinet", "trumpet", "trombone", "tuba", "violin", "viola", "cello",
	"double bass", "soprano", "alto", "tenor", "bass"]
const OPERA_PARTS: Array[String] = ["audience", "orchestra pit", "conductor", "stage", "curtain", "surtitles"]
const OPERA_AT := {"audience": Vector2(0.19, 0.72), "orchestra pit": Vector2(0.47, 0.86), "conductor": Vector2(0.385, 0.66),
	"stage": Vector2(0.8, 0.68), "curtain": Vector2(0.575, 0.36), "surtitles": Vector2(0.79, 0.07)}
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const LETTERS := "CDEFGAB"


# --- Facts the tests share -----------------------------------------------------------------------------------------------

## An algorithm's worst-case steps for n items: linear search n checks, binary search ⌊log₂ n⌋ + 1, bubble sort
## n(n − 1) ÷ 2 comparisons (every pass to the end).
static func steps_for(kind: String, n: int) -> int:
	match kind:
		"linear":
			return n
		"binary":
			var k := 0
			while (1 << k) <= n:
				k += 1
			return k
		"bubble":
			return n * (n - 1) / 2
	return -1


## How many stops a journey from `a` to `b` passes on the railway (the fewest; changing at Market is free), -1 if none.
static func stops_between(a: String, b: String) -> int:
	if not STOPS.has(a) or not STOPS.has(b):
		return -1
	var dist := {a: 0}
	var queue: Array[String] = [a]
	while not queue.is_empty():
		var s: String = queue.pop_front()
		for n: String in _neighbours(s):
			if not dist.has(n):
				dist[n] = int(dist[s]) + 1
				queue.append(n)
	return int(dist.get(b, -1))


static func _neighbours(s: String) -> Array[String]:
	var out: Array[String] = []
	for line: String in RAIL_LINES:
		var stops: Array = RAIL_LINES[line]
		var i := stops.find(s)
		if i > 0:
			out.append(str(stops[i - 1]))
		if i >= 0 and i < stops.size() - 1:
			out.append(str(stops[i + 1]))
	return out


## A logic circuit's output (0 or 1) for its inputs; -1 when it is not a circuit.
static func circuit_out(expr: Variant, inputs: Dictionary) -> int:
	if expr is String:
		return int(inputs.get(expr, -1))
	if not expr is Array or (expr as Array).is_empty():
		return -1
	var g := str(expr[0])
	if g == "NOT" and (expr as Array).size() == 2:
		var v := circuit_out(expr[1], inputs)
		return -1 if v < 0 else 1 - v
	if (g == "AND" or g == "OR") and (expr as Array).size() == 3:
		var a := circuit_out(expr[1], inputs)
		var b := circuit_out(expr[2], inputs)
		if a < 0 or b < 0:
			return -1
		return (a & b) if g == "AND" else (a | b)
	return -1


## The letters a circuit uses, each once, in the order they first appear.
static func circuit_letters(expr: Variant) -> Array[String]:
	var out: Array[String] = []
	if expr is String:
		out.append(str(expr))
	elif expr is Array:
		for i in range(1, (expr as Array).size()):
			for l in circuit_letters(expr[i]):
				if not out.has(l):
					out.append(l)
	return out


static func _gate_count(expr: Variant) -> int:
	if not expr is Array:
		return 0
	var n := 1
	for i in range(1, (expr as Array).size()):
		n += _gate_count(expr[i])
	return n


## The indexes of the `k` points nearest (x, y) (straight-line distance; on a tie the earlier point first).
static func nearest(points: Array, x: float, y: float, k: int) -> Array[int]:
	var idx: Array[int] = []
	for i in points.size():
		idx.append(i)
	var d := func(i: int) -> float: return Vector2(float(points[i][0]) - x, float(points[i][1]) - y).length_squared()
	idx.sort_custom(func(a: int, b: int) -> bool:
		var da: float = d.call(a)
		var db: float = d.call(b)
		return da < db - 0.000001 or (absf(da - db) <= 0.000001 and a < b))
	return idx.slice(0, mini(k, idx.size()))


## The bouncing ball's place in frame `i` of `count` (shares of the scene): it falls from the top left to the ground in
## the middle and rises to the top right. With `ease` it moves as a real ball does (slow at the top, fast at the bottom),
## so the frames bunch at the top; without it, at one speed all the way.
static func ball_at(i: int, count: int, ease: bool) -> Vector2:
	var t := float(i) / float(maxi(count - 1, 1))
	var up := absf(2.0 * t - 1.0)
	var height := 1.0 - (1.0 - up) * (1.0 - up) if ease else up
	return Vector2(0.1 + 0.8 * t, 0.86 - 0.7 * height)


## A mobile's turning: weight × distance on the left less on the right (0: it balances; more than 0: it tips left).
static func turning(p: Dictionary) -> int:
	var t := 0
	for side: String in ["left", "right"]:
		for wd: Variant in p.get(side, []):
			t += int(wd[0]) * int(wd[1]) * (1 if side == "left" else -1)
	return t


## A note's pitch in semitones ("C4" = 48), -1 for anything else.
static func pitch_of(note: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([0-8])$").search(note)
	if m == null:
		return -1
	var s := int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else (-1 if m.get_string(2) == "b" else 0))
	return 12 * int(m.get_string(3)) + s


## An instrument's or a voice's lowest and highest pitches ([] when it has no range here).
static func range_of(name: String) -> Array[int]:
	if not RANGES.has(name):
		return []
	return [pitch_of(str(RANGES[name][0])), pitch_of(str(RANGES[name][1]))]


## Where the part named `label` is drawn on a picture of `size` (a SchoolPicture's whole size), for a label's line;
## (-1, -1) when the picture has no such part.
static func part_at(p: Dictionary, label: String, size: Vector2) -> Vector2:
	var none := Vector2(-1, -1)
	var kind := str(p.get("kind", ""))
	if not RATIOS.has(kind) or (kind == "cpu_cycle" and str(p.get("view", "")) != "machine") \
			or (kind == "app_screen" and str(p.get("design", "")) != "clear"):
		return none
	var at: Dictionary = _anchor_table(p)
	if not at.has(label):
		return none
	var a := _diagram_box(p, _rect(size))
	return _at(a, at[label].x, at[label].y)


static func _anchor_table(p: Dictionary) -> Dictionary:
	match str(p.get("kind", "")):
		"cpu_cycle":
			return CPU_AT
		"camera_obscura":
			return OBSCURA_AT
		"object_design":
			return OBJECT_AT.get(str(p.get("what", "")), {})
		"jazz_band":
			return BAND_AT
		"opera_house":
			return OPERA_AT
		"app_screen":
			return SCREEN_AT
	return {}


static func _anchors(p: Dictionary, a: Rect2) -> Dictionary:
	var out := {}
	var at := _anchor_table(p)
	for part: String in at:
		out[part] = _at(a, at[part].x, at[part].y)
	return out


## A diagram's box in `r`: its label bands taken off, then its shape (RATIOS) centred.
static func _diagram_box(p: Dictionary, r: Rect2) -> Rect2:
	var fs := _fs(r)
	return _fit_box(_inner(r, fs, bool(p.get("labels", false))), float(RATIOS.get(str(p.get("kind", "")), 2.0)))


# --- Checks --------------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"structure_chart":
			if not _text_ok(p.get("top"), MAX_TOP):
				return "structure_chart: top is text of 1-%d letters" % MAX_TOP
			var parts: Variant = p.get("parts")
			if not parts is Array or (parts as Array).size() < 2 or (parts as Array).size() > 4:
				return "structure_chart: 2-4 parts"
			var names := [str(p.top)]
			for part: Variant in parts:
				if not part is Array or (part as Array).size() != 2 or not _text_ok(part[0], MAX_MODULE) \
						or not part[1] is Array or (part[1] as Array).size() > 3:
					return "structure_chart: a part is [name (%d letters), [up to 3 subparts]]" % MAX_MODULE
				names.append(str(part[0]))
				for s: Variant in part[1]:
					if not _text_ok(s, MAX_MODULE):
						return "structure_chart: a subpart is text of 1-%d letters" % MAX_MODULE
					names.append(str(s))
			for key: String in ["mark", "hide"]:
				if p.has(key) and not names.has(str(p[key])):
					return "structure_chart: %s is a name in the chart" % key
		"step_growth":
			var why := _list_problem(p, "lines", GROWTH, 3)
			if why != "":
				return "step_growth: " + why
			if not _whole(p.get("upto")) or int(p.upto) < 4 or int(p.upto) > 64:
				return "step_growth: upto is 4-64"
			if p.has("at") and (not _whole(p.at) or int(p.at) < 1 or int(p.at) > int(p.upto)):
				return "step_growth: at is 1-upto"
		"state_machine":
			var states: Variant = p.get("states")
			if not states is Array or (states as Array).size() < 2 or (states as Array).size() > 5:
				return "state_machine: 2-5 states"
			for s: Variant in states:
				if not _text_ok(s, MAX_STATE):
					return "state_machine: a state is 1-%d letters" % MAX_STATE
			var n := (states as Array).size()
			var arrows: Variant = p.get("arrows")
			if not arrows is Array or (arrows as Array).is_empty() or (arrows as Array).size() > 8:
				return "state_machine: 1-8 arrows"
			for a: Variant in arrows:
				if not a is Array or (a as Array).size() != 3 or not _index_ok(a[0], n) or not _index_ok(a[1], n) \
						or int(a[0]) == int(a[1]) or not _text_ok(a[2], MAX_EVENT):
					return "state_machine: an arrow is [from, to, event (%d letters)] between two states" % MAX_EVENT
			if p.has("current") and not _index_ok(p.current, n):
				return "state_machine: current is a state's index"
			if p.has("mark") and not _index_ok(p.mark, (arrows as Array).size()):
				return "state_machine: mark is an arrow's index"
		"abstract_map":
			if not str(p.get("view", "")) in ["real", "model"]:
				return "abstract_map: view is real or model"
			if p.has("mark") and not STOPS.has(str(p.mark)):
				return "abstract_map: mark is a stop"
			if p.has("route"):
				var route: Variant = p.route
				if not route is Array or (route as Array).size() < 2:
					return "abstract_map: a route is 2 or more stops"
				for i in (route as Array).size():
					if not STOPS.has(str(route[i])):
						return "abstract_map: a route's stops are STOPS"
					if i > 0 and not _neighbours(str(route[i - 1])).has(str(route[i])):
						return "abstract_map: each stop of a route is next to the last on a line"
		"cpu_cycle":
			var view := str(p.get("view", ""))
			if not view in ["cycle", "machine"]:
				return "cpu_cycle: view is cycle or machine"
			if p.has("step") and not CYCLE_STEPS.has(str(p.step)):
				return "cpu_cycle: step is fetch, decode or execute"
			if view == "machine":
				var mem: Variant = p.get("memory", [])
				if not mem is Array or (mem as Array).size() > MAX_MEMORY:
					return "cpu_cycle: memory is 0-%d rows" % MAX_MEMORY
				var addrs := {}
				for row: Variant in mem:
					if not row is Array or (row as Array).size() != 2 or not _whole(row[0]) or int(row[0]) < 0 \
							or int(row[0]) > 99 or str(row[1]).length() > MAX_CONTENTS:
						return "cpu_cycle: a memory row is [address 0-99, contents (%d letters)]" % MAX_CONTENTS
					addrs[int(row[0])] = true
				if p.has("pc") and (not _whole(p.pc) or not addrs.has(int(p.pc))):
					return "cpu_cycle: pc is an address in the memory shown"
				if p.has("acc") and str(p.acc).length() > 6:
					return "cpu_cycle: acc is a short number"
				return _flags_problem(p, CPU_PARTS)
		"sampled_wave":
			if not _whole(p.get("bits")) or int(p.bits) < 1 or int(p.bits) > 4:
				return "sampled_wave: bits is 1-4"
			var samples: Variant = p.get("samples")
			if not samples is Array or (samples as Array).size() < 4 or (samples as Array).size() > 24:
				return "sampled_wave: 4-24 samples"
			for s: Variant in samples:
				if not _whole(s) or int(s) < 0 or int(s) >= (1 << int(p.bits)):
					return "sampled_wave: a sample is a whole number from 0 to 2^bits − 1"
			if p.has("view") and not str(p.view) in ["dots", "bars", "steps"]:
				return "sampled_wave: view is dots, bars or steps"
		"gate_circuit":
			var expr: Variant = p.get("expr")
			if not _expr_ok(expr) or _gate_count(expr) < 1 or _gate_count(expr) > MAX_GATES:
				return "gate_circuit: expr is 1-%d gates of AND, OR and NOT on inputs A-D" % MAX_GATES
			var inputs: Variant = p.get("inputs")
			if not inputs is Dictionary:
				return "gate_circuit: inputs is {letter: 0 or 1}"
			for l in circuit_letters(expr):
				if not (inputs as Dictionary).has(l) or not int(inputs[l]) in [0, 1] or not _whole(inputs[l]):
					return "gate_circuit: every input it uses is 0 or 1"
		"db_table":
			if not _text_ok(p.get("name"), 12):
				return "db_table: name is 1-12 letters"
			var fields: Variant = p.get("fields")
			if not fields is Array or (fields as Array).size() < 2 or (fields as Array).size() > MAX_FIELDS:
				return "db_table: 2-%d fields" % MAX_FIELDS
			for f: Variant in fields:
				if not _text_ok(f, MAX_CELL):
					return "db_table: a field's name is 1-%d letters" % MAX_CELL
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > MAX_RECORDS:
				return "db_table: 1-%d records" % MAX_RECORDS
			for row: Variant in rows:
				if not row is Array or (row as Array).size() != (fields as Array).size():
					return "db_table: every record has a value for every field"
				for c: Variant in row:
					if str(c).length() > MAX_CELL:
						return "db_table: a value is at most %d letters" % MAX_CELL
			for key: String in ["key", "field"]:
				if p.has(key) and not _index_ok(p[key], (fields as Array).size()):
					return "db_table: %s is a field's index" % key
			if p.has("pick"):
				if not p.pick is Array:
					return "db_table: pick is a list of records"
				for i: Variant in p.pick:
					if not _index_ok(i, (rows as Array).size()):
						return "db_table: pick lists records' indexes"
			if p.has("query") and not _text_ok(p.query, MAX_QUERY):
				return "db_table: a query is 1-%d letters" % MAX_QUERY
		"scatter_learn":
			for key: String in ["axes", "groups"]:
				var two: Variant = p.get(key)
				if not two is Array or (two as Array).size() != 2 or not _text_ok(two[0], 16) or not _text_ok(two[1], 16):
					return "scatter_learn: %s is two names" % key
			var pts: Variant = p.get("points")
			if not pts is Array or (pts as Array).size() < 2 or (pts as Array).size() > MAX_POINTS:
				return "scatter_learn: 2-%d points" % MAX_POINTS
			for pt: Variant in pts:
				if not pt is Array or (pt as Array).size() != 3 or not _in10(pt[0]) or not _in10(pt[1]) \
						or not int(pt[2]) in [0, 1]:
					return "scatter_learn: a point is [x, y, group] with x and y 0-10"
			if p.has("new") and (not p.new is Array or (p.new as Array).size() != 2 or not _in10(p.new[0]) \
					or not _in10(p.new[1])):
				return "scatter_learn: new is [x, y]"
			if p.has("near") and (not p.has("new") or not _whole(p.near) or int(p.near) < 1 or int(p.near) > 5 \
					or int(p.near) > (pts as Array).size()):
				return "scatter_learn: near is 1-5 points (with new)"
			if p.has("line") and (not p.line is Array or (p.line as Array).size() != 4):
				return "scatter_learn: line is [x0, y0, x1, y1]"
		"threat_card":
			if not THREATS.has(str(p.get("threat", ""))):
				return "threat_card: threat is one of %s" % [THREATS]
		"app_screen":
			if not SCREENS.has(str(p.get("design", ""))):
				return "app_screen: design is one of %s" % [SCREENS]
			if str(p.design) != "clear" and (p.has("labels") or p.has("mark") or p.has("hide")):
				return "app_screen: only the clear design names its parts"
			return _flags_problem(p, SCREEN_PARTS)
		"light_series":
			var why := _list_problem(p, "times", TIMES, 4)
			if why != "":
				return "light_series: " + why
		"brushwork":
			if not STYLES.has(str(p.get("style", ""))):
				return "brushwork: style is smooth, broken or dots"
		"movement_piece":
			if not MOVEMENTS.has(str(p.get("style", ""))):
				return "movement_piece: style is one of %s" % [MOVEMENTS]
		"camera_obscura":
			return _flags_problem(p, OBSCURA_PARTS)
		"raster_vector":
			if not str(p.get("view", "")) in ["raster", "vector"]:
				return "raster_vector: view is raster or vector"
		"symbol_portrait":
			var syms: Variant = p.get("symbols", [])
			if not syms is Array or (syms as Array).size() > 6:
				return "symbol_portrait: 0-6 symbols"
			for s: Variant in syms:
				if not SYMBOLS.has(str(s)) or (syms as Array).count(s) > 1:
					return "symbol_portrait: each symbol once, from %s" % [SYMBOLS]
			if p.has("mark") and not (syms as Array).has(p.mark):
				return "symbol_portrait: mark is one of its symbols"
		"grid_enlarge":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).size() < 2 or (rows as Array).size() > MAX_GRID:
				return "grid_enlarge: 2-%d rows" % MAX_GRID
			var w := str(rows[0]).length()
			var key: Variant = p.get("key")
			if not key is Dictionary:
				return "grid_enlarge: key is {letter: colour}"
			for row: Variant in rows:
				if not row is String or str(row).length() != w or w < 2 or w > MAX_GRID:
					return "grid_enlarge: rows of 2-%d letters, all as long" % MAX_GRID
				for ch in str(row):
					if not (key as Dictionary).has(ch) or not SchoolPictureArts.COLOURS.has(str(key[ch])):
						return "grid_enlarge: every letter is in the key, a colour of SchoolPictureArts"
			if p.has("done") and (not _whole(p.done) or int(p.done) < 0 or int(p.done) > w * (rows as Array).size()):
				return "grid_enlarge: done is 0 to every square"
			if p.has("sizes") and (not p.sizes is Array or (p.sizes as Array).size() != 2 \
					or not _text_ok(p.sizes[0], 10) or not _text_ok(p.sizes[1], 10)):
				return "grid_enlarge: sizes is [design, wall] (10 letters each)"
		"object_design":
			var what := str(p.get("what", ""))
			if not OBJECTS.has(what):
				return "object_design: what is one of %s" % [OBJECTS]
			return _flags_problem(p, OBJECT_PARTS[what])
		"flip_frames":
			if not _whole(p.get("count")) or int(p.count) < 4 or int(p.count) > MAX_FRAMES:
				return "flip_frames: count is 4-%d" % MAX_FRAMES
			if p.has("view") and not str(p.view) in ["onion", "strip"]:
				return "flip_frames: view is onion or strip"
			if p.has("mark") and not _index_ok(p.mark, int(p.count)):
				return "flip_frames: mark is a frame's index"
		"mobile_balance":
			for side: String in ["left", "right"]:
				var hang: Variant = p.get(side)
				if not hang is Array or (hang as Array).is_empty() or (hang as Array).size() > 2:
					return "mobile_balance: %s is 1-2 weights" % side
				var seen := {}
				for wd: Variant in hang:
					if not wd is Array or (wd as Array).size() != 2 or not _whole(wd[0]) or not _whole(wd[1]) \
							or int(wd[0]) < 1 or int(wd[0]) > MAX_WEIGHT or int(wd[1]) < 1 or int(wd[1]) > MAX_DISTANCE:
						return "mobile_balance: a weight is [1-%d, distance 1-%d]" % [MAX_WEIGHT, MAX_DISTANCE]
					if seen.has(int(wd[1])):
						return "mobile_balance: one weight at each distance"
					seen[int(wd[1])] = true
			if p.has("hide") and (not p.hide is Array or (p.hide as Array).size() != 2 \
					or not str(p.hide[0]) in ["left", "right"] or not _index_ok(p.hide[1], (p[str(p.hide[0])] as Array).size())):
				return "mobile_balance: hide is [side, a weight's index]"
		"gallery_plan":
			var works: Variant = p.get("works")
			if not works is Array or (works as Array).is_empty() or (works as Array).size() > MAX_WORKS:
				return "gallery_plan: 1-%d works" % MAX_WORKS
			for wk: Variant in works:
				if not wk is Array or (wk as Array).size() != 3 or not _text_ok(wk[0], MAX_WORK) or not _share(wk[1]) \
						or not _share(wk[2]):
					return "gallery_plan: a work is [name (%d letters), x, y (0.08-0.92)]" % MAX_WORK
			if not str(p.get("door", "")) in ["bottom", "left"]:
				return "gallery_plan: door is bottom or left"
			if p.has("path"):
				if not p.path is Array or (p.path as Array).is_empty():
					return "gallery_plan: path lists works"
				for i: Variant in p.path:
					if not _index_ok(i, (works as Array).size()):
						return "gallery_plan: path lists works' indexes"
			if p.has("mark") and not _index_ok(p.mark, (works as Array).size()):
				return "gallery_plan: mark is a work's index"
			if p.has("size") and (not p.size is Array or (p.size as Array).size() != 2 or not _text_ok(p.size[0], 6) \
					or not _text_ok(p.size[1], 6)):
				return "gallery_plan: size is [width, depth] (6 letters each)"
		"wall_label":
			for key: String in ["title", "artist"]:
				if not _text_ok(p.get(key), 26):
					return "wall_label: %s is 1-26 letters" % key
			if not _text_ok(p.get("date"), 16) or not _text_ok(p.get("medium"), 30):
				return "wall_label: a date (16 letters) and a medium (30)"
			if p.has("size") and not _text_ok(p.size, 20):
				return "wall_label: size is 1-20 letters"
			if p.has("lines"):
				if not p.lines is Array or (p.lines as Array).size() > 3:
					return "wall_label: 0-3 lines"
				for l: Variant in p.lines:
					if not _text_ok(l, 36):
						return "wall_label: a line is 1-36 letters"
		"jazz_band":
			return _flags_problem(p, BAND_PARTS)
		"swing_beats":
			var why := _list_problem(p, "rows", ["straight", "swing"], 2)
			if why != "":
				return "swing_beats: " + why
			if not _whole(p.get("beats")) or int(p.beats) < 2 or int(p.beats) > 4:
				return "swing_beats: beats is 2-4"
			if p.has("mark") and not _index_ok(p.mark, (p.rows as Array).size()):
				return "swing_beats: mark is a row's index"
		"instrument_ranges":
			var why := _list_problem(p, "instruments", RANGE_NAMES, 6)
			if why != "":
				return "instrument_ranges: " + why
			if p.has("note") and (pitch_of(str(p.note)) < pitch_of("E1") or pitch_of(str(p.note)) > pitch_of("C8")):
				return "instrument_ranges: note is a note from E1 to C8"
			if p.has("mark") and not (p.instruments as Array).has(p.mark):
				return "instrument_ranges: mark is one of its instruments"
		"opera_house":
			return _flags_problem(p, OPERA_PARTS)
		_:
			return "unknown grade 8 arts kind '%s'" % kind
	return ""


static func _text_ok(v: Variant, most: int) -> bool:
	return v is String and str(v).strip_edges() != "" and str(v).length() <= most


static func _whole(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v)))


static func _index_ok(v: Variant, n: int) -> bool:
	return _whole(v) and int(v) >= 0 and int(v) < n


static func _in10(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) >= 0.0 and float(v) <= 10.0


static func _share(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) >= 0.08 and float(v) <= 0.92


static func _expr_ok(e: Variant) -> bool:
	if e is String:
		return INPUT_LETTERS.has(str(e))
	if not e is Array or (e as Array).is_empty() or not GATES.has(str(e[0])):
		return false
	var want := 2 if str(e[0]) == "NOT" else 3
	if (e as Array).size() != want:
		return false
	for i in range(1, want):
		if not _expr_ok(e[i]):
			return false
	return true


## `key` of `p`: 1-`most` different items from `allowed`.
static func _list_problem(p: Dictionary, key: String, allowed: Array, most: int) -> String:
	var items: Variant = p.get(key)
	if not items is Array or (items as Array).is_empty() or (items as Array).size() > most:
		return "%s is 1-%d items" % [key, most]
	for it: Variant in items:
		if not allowed.has(it) or (items as Array).count(it) > 1:
			return "%s: each once, from %s" % [key, allowed]
	return ""


## A diagram's labels? (true or false) and its mark and hide (a part of `parts`).
static func _flags_problem(p: Dictionary, parts: Array) -> String:
	if p.has("labels") and not p.labels is bool:
		return "%s: labels is true or false" % p.kind
	for key: String in ["mark", "hide"]:
		if p.has(key) and not parts.has(str(p[key])):
			return "%s: %s is one of %s" % [p.kind, key, parts]
	return ""


# --- Drawing -------------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"structure_chart":
			_draw_structure(pic, font, r, d)
		"step_growth":
			_draw_growth(pic, font, r, d)
		"state_machine":
			_draw_states(pic, font, r, d)
		"abstract_map":
			_draw_rail(pic, font, r, d)
		"cpu_cycle":
			_draw_cpu(pic, font, r, d)
		"sampled_wave":
			_draw_samples(pic, font, r, d)
		"gate_circuit":
			_draw_gates(pic, font, r, d)
		"db_table":
			_draw_db(pic, font, r, d)
		"scatter_learn":
			_draw_scatter(pic, font, r, d)
		"threat_card":
			_draw_threat(pic, font, r, d)
		"app_screen":
			_draw_app(pic, font, r, d)
		"light_series":
			_draw_light_series(pic, font, r, d)
		"brushwork":
			_draw_brushwork(pic, r, d)
		"movement_piece":
			_draw_movement(pic, r, d)
		"camera_obscura":
			_draw_obscura(pic, font, r, d)
		"raster_vector":
			_draw_raster_vector(pic, font, r, d)
		"symbol_portrait":
			_draw_portrait(pic, font, r, d)
		"grid_enlarge":
			_draw_enlarge(pic, font, r, d)
		"object_design":
			_draw_object(pic, font, r, d)
		"flip_frames":
			_draw_frames(pic, r, d)
		"mobile_balance":
			_draw_mobile(pic, font, r, d)
		"gallery_plan":
			_draw_plan(pic, font, r, d)
		"wall_label":
			_draw_wall_label(pic, font, r, d)
		"jazz_band":
			_draw_band(pic, font, r, d)
		"instrument_ranges":
			_draw_ranges(pic, font, r, d)
		"opera_house":
			_draw_opera(pic, font, r, d)
		"swing_beats":
			_draw_swing(pic, font, r, d)


# --- Shared drawing helpers ----------------------------------------------------------------------------------------------

## The drawing area of a SchoolPicture of `size` (its MARGIN all round).
static func _rect(size: Vector2) -> Rect2:
	return Rect2(Vector2(SchoolPicture.MARGIN, SchoolPicture.MARGIN), size - Vector2(2, 2) * SchoolPicture.MARGIN)


static func _fs(r: Rect2, per: float = 14.0) -> int:
	return clampi(int(minf(r.size.y / per, r.size.x / (per * 2.0))), 9, 18)


static func _text_w(font: Font, text: String, fs: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## Text centred on `c`, with a white edge so it reads over lines.
static func _say(ci: CanvasItem, font: Font, c: Vector2, text: String, fs: int, colour: Color = INK,
		edge: bool = true) -> void:
	var w := _text_w(font, text, fs)
	var base := Vector2(c.x - w * 0.5, c.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
	if edge:
		ci.draw_string_outline(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color.WHITE)
	ci.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)


## Text starting at `at` (left, vertically centred), or ending there when `right`.
static func _say_from(ci: CanvasItem, font: Font, at: Vector2, text: String, fs: int, colour: Color = INK,
		right: bool = false, edge: bool = true) -> void:
	var w := _text_w(font, text, fs)
	_say(ci, font, Vector2(at.x - w * 0.5 if right else at.x + w * 0.5, at.y), text, fs, colour, edge)


## The largest size up to `fs` at which `text` fits in `room` pixels (at least 7).
static func _fit(font: Font, text: String, fs: int, room: float) -> int:
	var f := fs
	while f > 7 and _text_w(font, text, f) > room:
		f -= 1
	return f


static func _arrow(ci: CanvasItem, from: Vector2, to: Vector2, colour: Color, width: float) -> void:
	if from.distance_to(to) < 1.0:
		return
	var dir := (to - from).normalized()
	var head := maxf(7.0, width * 3.0)
	ci.draw_line(from, to - dir * head * 0.6, colour, width, true)
	_head(ci, to, dir, head, colour)


static func _head(ci: CanvasItem, tip: Vector2, dir: Vector2, head: float, colour: Color) -> void:
	var side := Vector2(-dir.y, dir.x)
	ci.draw_colored_polygon(PackedVector2Array([tip, tip - dir * head + side * head * 0.5, tip - dir * head - side * head * 0.5]),
		colour)


static func _box(ci: CanvasItem, rect: Rect2, fill: Color, border: Color, radius: int = 6, width: int = 2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	ci.draw_style_box(sb, rect)


static func _poly(ci: CanvasItem, pts: Array, fill: Color, line: Color = INK, width: float = 1.5) -> void:
	var p := PackedVector2Array(pts)
	ci.draw_colored_polygon(p, fill)
	if width > 0.0:
		p.append(p[0])
		ci.draw_polyline(p, line, width, true)


static func _dashed(ci: CanvasItem, a: Vector2, b: Vector2, colour: Color, width: float, dash: float = 7.0) -> void:
	var length := a.distance_to(b)
	if length < 1.0:
		return
	var dir := (b - a) / length
	var t := 0.0
	while t < length:
		ci.draw_line(a + dir * t, a + dir * minf(t + dash, length), colour, width, true)
		t += dash * 2.0


## A label's words and colour: orange when marked, "?" when hidden.
static func _label_of(d: Dictionary, key: String, words: String) -> Array:
	if d.has("hide") and str(d.hide) == key:
		return ["?", ORANGE]
	return [words, ORANGE if d.has("mark") and str(d.mark) == key else INK]


## The height of a band of labels.
static func _band(fs: int) -> float:
	return fs * 1.45 + 6.0


## `r` less its label bands (when the picture has labels).
static func _inner(r: Rect2, fs: int, labels: bool) -> Rect2:
	if not labels:
		return r
	var b := _band(fs)
	return Rect2(r.position + Vector2(0, b), r.size - Vector2(0, 2.0 * b))


## Part labels in bands along the top and bottom of `r` (a part goes to the band nearer its anchor), spread so they
## never overlap, each with a line to its anchor; orange when marked, "?" when hidden. Without labels, a marked part
## gets an orange ring.
static func _label_parts(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, anchors: Dictionary, fs: int) -> void:
	if not bool(d.get("labels", false)):
		if d.has("mark") and anchors.has(str(d.mark)):
			ci.draw_arc(anchors[str(d.mark)], fs * 1.3, 0.0, TAU, 28, ORANGE, 3.0, true)
		return
	for on_top: bool in [true, false]:
		var row: Array = []
		for part: String in anchors:
			var at: Vector2 = anchors[part]
			if (at.y < r.get_center().y) == on_top:
				row.append([at.x, 0.0, part, _label_of(d, part, part)])
		if row.is_empty():
			continue
		var lfs := fs
		while lfs > 8:
			var total := 0.0
			for b: Array in row:
				total += _text_w(font, str(b[3][0]), lfs) + 16.0
			if total <= r.size.x:
				break
			lfs -= 1
		for b: Array in row:
			b[1] = _text_w(font, str(b[3][0]), lfs) + 10.0
		var centres := _spread(row, r.position.x + 1.0, r.end.x - 1.0, 5.0)
		var h := lfs * 1.35 + 4.0
		var ly := r.position.y + h * 0.5 + 1.0 if on_top else r.end.y - h * 0.5 - 1.0
		for k in row.size():
			var b: Array = row[k]
			var said: Array = b[3]
			var at: Vector2 = anchors[str(b[2])]
			var marked: bool = said[1] == ORANGE
			ci.draw_line(at, Vector2(centres[k], ly + (h * 0.5 if on_top else -h * 0.5)), INK, 1.5, true)
			ci.draw_circle(at, 3.0, ORANGE if marked else INK)
			_box(ci, Rect2(centres[k] - float(b[1]) * 0.5, ly - h * 0.5, float(b[1]), h), SOFT if marked else Color.WHITE,
				ORANGE if marked else INK, 5, 2 if marked else 1)
			_say(ci, font, Vector2(centres[k], ly), str(said[0]), lfs, INK, false)


## Centres for boxes [wanted centre, width, …] in a row from lo to hi, at least `gap` apart, as near their wanted
## centres as the room allows.
static func _spread(boxes: Array, lo: float, hi: float, gap: float) -> Array[float]:
	var order: Array = range(boxes.size())
	order.sort_custom(func(a: int, b: int) -> bool: return float(boxes[a][0]) < float(boxes[b][0]))
	var left: Array[float] = []
	left.resize(boxes.size())
	var edge := lo
	for i: int in order:
		left[i] = maxf(float(boxes[i][0]) - float(boxes[i][1]) * 0.5, edge)
		edge = left[i] + float(boxes[i][1]) + gap
	edge = hi
	for k in range(order.size() - 1, -1, -1):
		var i: int = order[k]
		left[i] = minf(left[i], edge - float(boxes[i][1]))
		edge = left[i] - gap
	var out: Array[float] = []
	for i in boxes.size():
		out.append(maxf(left[i], lo) + float(boxes[i][1]) * 0.5)
	return out


## A point of a unit box `a` (fractions of its width and height).
static func _at(a: Rect2, fx: float, fy: float) -> Vector2:
	return a.position + Vector2(a.size.x * fx, a.size.y * fy)


static func _pts(a: Rect2, fracs: Array) -> Array:
	var out: Array = []
	for f: Vector2 in fracs:
		out.append(_at(a, f.x, f.y))
	return out


## The part of the unit box `a` from (x0, y0) to (x1, y1), as a rectangle.
static func _sub(a: Rect2, x0: float, y0: float, x1: float, y1: float) -> Rect2:
	return Rect2(_at(a, x0, y0), Vector2(a.size.x * (x1 - x0), a.size.y * (y1 - y0)))


## The widest box of aspect `ratio` (width ÷ height) centred in `r`.
static func _fit_box(r: Rect2, ratio: float) -> Rect2:
	var w := minf(r.size.x, r.size.y * ratio)
	var h := w / ratio
	return Rect2(r.get_center() - Vector2(w, h) * 0.5, Vector2(w, h))


## Text in a box, on two lines when one is too wide.
static func _text_in(ci: CanvasItem, font: Font, box: Rect2, text: String, fs: int, colour: Color = INK) -> void:
	var room := box.size.x - 8.0
	if _text_w(font, text, fs) <= room or not text.contains(" "):
		_say(ci, font, box.get_center(), text, _fit(font, text, fs, room), colour, false)
		return
	var cut := text.rfind(" ", text.length() / 2 + 2)
	if cut <= 0:
		cut = text.find(" ")
	var lines := [text.substr(0, cut), text.substr(cut + 1)]
	var f := mini(_fit(font, lines[0], fs, room), _fit(font, lines[1], fs, room))
	f = mini(f, int(box.size.y / 2.4))
	_say(ci, font, box.get_center() - Vector2(0, f * 0.6), lines[0], maxi(f, 7), colour, false)
	_say(ci, font, box.get_center() + Vector2(0, f * 0.6), lines[1], maxi(f, 7), colour, false)


## A point `t` (0-1) along the curve from p0 pulled towards p1 to p2.
static func _bez(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return p0 * (1.0 - t) * (1.0 - t) + p1 * 2.0 * t * (1.0 - t) + p2 * t * t


static func _curve(p0: Vector2, p1: Vector2, p2: Vector2, n: int = 16) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		out.append(_bez(p0, p1, p2, float(i) / n))
	return out


## A smooth line through `pts` (Catmull-Rom), for streets, rivers and sound waves.
static func _smooth(pts: Array, per: int = 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.size() < 2:
		return out
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		for k in per:
			var t := float(k) / per
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[-1])
	return out


## A steady pseudo-random number 0-1 for dab `i` (the same picture every time it is drawn).
static func _rand(i: int, salt: float) -> float:
	return fposmod(sin(float(i) * 12.9898 + salt * 78.233) * 43758.5453, 1.0)


static func _int(d: Dictionary, key: String, fallback: int) -> int:
	return int(d.get(key, fallback))


## A value as a table shows it: a whole number without ".0" (JSON's numbers are decimals), anything else as it is.
static func _cell_text(v: Variant) -> String:
	if typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v))):
		return str(int(v))
	return str(v)


## A short brush stroke from `c` along `angle`.
static func _dab(ci: CanvasItem, c: Vector2, length: float, angle: float, width: float, colour: Color) -> void:
	var v := Vector2(cos(angle), sin(angle)) * length * 0.5
	ci.draw_line(c - v, c + v, colour, width, true)


# --- Structure chart -----------------------------------------------------------------------------------------------------

static func _chart_box(ci: CanvasItem, font: Font, d: Dictionary, rect: Rect2, name: String, fill: Color, fs: int) -> void:
	var said := _label_of(d, name, name)
	var marked: bool = said[1] == ORANGE
	_box(ci, rect, SOFT if marked else fill, ORANGE if marked else INK, 6, 3 if marked else 2)
	_text_in(ci, font, rect, str(said[0]), fs)


static func _draw_structure(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var parts: Array = d.parts
	var n := parts.size()
	var fs := _fs(r, 12.0)
	var top := Rect2(Vector2(r.get_center().x - r.size.x * 0.2, r.position.y + r.size.y * 0.02), Vector2(r.size.x * 0.4, r.size.y * 0.16))
	var col := r.size.x / n
	var part_h := r.size.y * 0.15
	var part_y := r.position.y + r.size.y * 0.33
	var bar_y := r.position.y + r.size.y * 0.26
	ci.draw_line(Vector2(top.get_center().x, top.end.y), Vector2(top.get_center().x, bar_y), INK, 2.0, true)
	ci.draw_line(Vector2(r.position.x + col * 0.5, bar_y), Vector2(r.position.x + col * (n - 0.5), bar_y), INK, 2.0, true)
	for i in n:
		var cx := r.position.x + col * (i + 0.5)
		ci.draw_line(Vector2(cx, bar_y), Vector2(cx, part_y), INK, 2.0, true)
		var box := Rect2(Vector2(cx - col * 0.45, part_y), Vector2(col * 0.9, part_h))
		var subs: Array = parts[i][1]
		var sub_h := r.size.y * 0.135
		var y := box.end.y
		for k in subs.size():
			var sy := part_y + part_h + r.size.y * 0.045 + k * (sub_h + r.size.y * 0.03)
			ci.draw_line(Vector2(cx, y), Vector2(cx, sy), INK, 1.5, true)
			_chart_box(ci, font, d, Rect2(Vector2(cx - col * 0.46, sy), Vector2(col * 0.92, sub_h)), str(subs[k]), Color.WHITE,
				fs - 1)
			y = sy + sub_h
		_chart_box(ci, font, d, box, str(parts[i][0]), Color("fff1d6"), fs)
	_chart_box(ci, font, d, top, str(d.top), Color("dbe8ff"), fs + 1)


# --- Step growth ---------------------------------------------------------------------------------------------------------

static func _nice_top(v: float) -> float:
	var p := pow(10.0, floor(log(maxf(v, 1.0)) / log(10.0)))
	for m: float in [1.0, 2.0, 5.0, 10.0]:
		if m * p >= v:
			return m * p
	return 10.0 * p


static func _draw_growth(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var lines: Array = d.lines
	var upto := int(d.upto)
	var fs := _fs(r, 13.0)
	var most := 1.0
	for kind: Variant in lines:
		most = maxf(most, float(steps_for(str(kind), upto)))
	var top := _nice_top(most)
	var plot := Rect2(r.position + Vector2(fs * 3.2, fs * 1.7), r.size - Vector2(fs * 3.2 + fs * 7.5, fs * 4.3))
	ci.draw_rect(plot, Color.WHITE)
	var parts := 5 if int(top) % 5 == 0 else (4 if int(top) % 4 == 0 else int(top))
	for t in parts + 1:
		var y := plot.end.y - plot.size.y * t / float(parts)
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), PALE, 1.0)
		_say_from(ci, font, Vector2(plot.position.x - 4, y), GenKit.fmt(int(top * t / parts)), fs - 2, INK, true, false)
	var xstep := 1
	for c: int in [1, 2, 4, 5, 8, 10, 16, 20]:
		xstep = c
		if upto / c <= 6:
			break
	for v in range(0, upto + 1, xstep):
		var x := plot.position.x + plot.size.x * v / float(upto)
		_say(ci, font, Vector2(x, plot.end.y + fs * 0.8), str(v), fs - 2, INK, false)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.0)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.0)
	_say(ci, font, Vector2(plot.get_center().x, plot.end.y + fs * 2.0), "items (n)", fs - 1, INK, false)
	_say_from(ci, font, Vector2(r.position.x, r.position.y + fs * 0.6), "steps", fs - 1, INK, false, false)
	var ends: Array = []
	for kind: Variant in lines:
		var k := str(kind)
		var pts := PackedVector2Array()
		for n in range(1, upto + 1):
			pts.append(Vector2(plot.position.x + plot.size.x * n / float(upto),
				plot.end.y - plot.size.y * minf(float(steps_for(k, n)) / top, 1.0)))
		ci.draw_polyline(pts, GROWTH_COLOURS[k], 3.0, true)
		ends.append([pts[-1].y, k])
	ends.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var last_y := -INF
	for e: Array in ends:
		var y := maxf(float(e[0]), last_y + fs * 1.3)
		_say_from(ci, font, Vector2(plot.end.x + 6, y), str(GROWTH_NAMES[str(e[1])]), fs - 1, GROWTH_COLOURS[str(e[1])])
		last_y = y
	if d.has("at"):
		var n := int(d.at)
		var x := plot.position.x + plot.size.x * n / float(upto)
		_dashed(ci, Vector2(x, plot.position.y), Vector2(x, plot.end.y), ORANGE, 2.0)
		var said: Array = []
		for kind: Variant in lines:
			var v := steps_for(str(kind), n)
			var y := plot.end.y - plot.size.y * minf(float(v) / top, 1.0)
			ci.draw_circle(Vector2(x, y), 5.0, GROWTH_COLOURS[str(kind)])
			said.append([y, v, str(kind)])
		said.sort_custom(func(p: Array, q: Array) -> bool: return float(p[0]) > float(q[0]))
		var floor_y := INF
		for e: Array in said:   # from the lowest up, each label at least a line above the one below it
			var ly := minf(float(e[0]) - fs * 0.6, floor_y - fs * 1.15)
			_say_from(ci, font, Vector2(x + 7, ly), GenKit.fmt(int(e[1])), fs - 1, GROWTH_COLOURS[str(e[2])])
			floor_y = ly


# --- State machine -------------------------------------------------------------------------------------------------------

static func _state_rects(r: Rect2, n: int, fs: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var w := minf(r.size.x * 0.26, fs * 9.0)
	var h := minf(r.size.y * 0.2, fs * 2.6)
	var c := r.get_center()
	var rx := r.size.x * 0.5 - w * 0.55
	var ry := r.size.y * 0.5 - h * 0.6
	for i in n:
		var ang := -PI * 0.5 + TAU * i / n if n > 2 else PI + PI * i
		var p := c + Vector2(cos(ang) * rx, sin(ang) * ry)
		out.append(Rect2(p - Vector2(w, h) * 0.5, Vector2(w, h)))
	return out


## Where the line from the centre of `rect` towards `dir` leaves it.
static func _edge(rect: Rect2, dir: Vector2) -> Vector2:
	var c := rect.get_center()
	var hx := rect.size.x * 0.5 + 4.0
	var hy := rect.size.y * 0.5 + 4.0
	var tx := hx / maxf(absf(dir.x), 0.0001)
	var ty := hy / maxf(absf(dir.y), 0.0001)
	return c + dir * minf(tx, ty)


static func _draw_states(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var states: Array = d.states
	var fs := _fs(r, 12.0)
	var rects := _state_rects(r, states.size(), fs)
	var arrows: Array = d.arrows
	var pairs := {}
	for a: Array in arrows:
		pairs[Vector2i(int(a[0]), int(a[1]))] = true
	for k in arrows.size():
		var a: Array = arrows[k]
		var r0: Rect2 = rects[int(a[0])]
		var r1: Rect2 = rects[int(a[1])]
		var dir := (r1.get_center() - r0.get_center()).normalized()
		var side := Vector2(-dir.y, dir.x)
		# an arrow with no arrow back bends outwards, away from the middle (a pair keeps opposite sides)
		if not pairs.has(Vector2i(int(a[1]), int(a[0]))) \
				and side.dot((r0.get_center() + r1.get_center()) * 0.5 - r.get_center()) < 0.0:
			side = -side
		var bend := r0.get_center().distance_to(r1.get_center()) * 0.16
		var from := _edge(r0, (dir + side * 0.35).normalized())
		var to := _edge(r1, (-dir + side * 0.35).normalized())
		var mid := (from + to) * 0.5 + side * bend
		var colour := ORANGE if _int(d, "mark", -1) == k else INK
		var pts := _curve(from, mid, to, 18)
		ci.draw_polyline(pts.slice(0, pts.size() - 1), colour, 2.5 if colour == ORANGE else 2.0, true)
		_head(ci, to, (to - pts[pts.size() - 3]).normalized(), 11.0, colour)
		var lp := _bez(from, mid, to, 0.5) + side * fs * 0.85
		_say(ci, font, lp, str(a[2]), fs - 2, colour)
	for i in states.size():
		var current := _int(d, "current", -1) == i
		_box(ci, rects[i], Color("c9efc9") if current else Color.WHITE, GREEN if current else INK, 10, 3 if current else 2)
		_text_in(ci, font, rects[i], str(states[i]), fs)


# --- Abstract map --------------------------------------------------------------------------------------------------------

static func _stop_at(view: String, stop: String, r: Rect2) -> Vector2:
	var f: Vector2 = (REAL_AT if view == "real" else MODEL_AT)[stop]
	return _at(r, f.x, f.y)


static func _draw_rail(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var view := str(d.view)
	var fs := _fs(r, 13.0)
	var route: Array = d.get("route", [])
	if view == "real":
		ci.draw_rect(r, Color("eef0e2"))
		ci.draw_rect(_sub(r, 0.93, 0.0, 1.0, 1.0), Color("9fc8ec"))
		var river := _smooth(_pts(r, [Vector2(0.52, 0.0), Vector2(0.56, 0.25), Vector2(0.5, 0.45), Vector2(0.58, 0.7),
			Vector2(0.62, 1.0)]))
		ci.draw_polyline(river, Color("9fc8ec"), r.size.y * 0.05, true)
		ci.draw_circle(_at(r, 0.2, 0.42), r.size.y * 0.13, Color("bfe0a8"))
		for i in 26:
			var p := _at(r, 0.04 + 0.86 * _rand(i, 1.0), 0.05 + 0.9 * _rand(i, 2.0))
			if p.distance_to(_at(r, 0.2, 0.42)) < r.size.y * 0.14:
				continue
			ci.draw_rect(Rect2(p, Vector2(r.size.y * 0.06, r.size.y * 0.045)), Color("c9c3b8"))
		for street: Array in [[Vector2(0.0, 0.7), Vector2(0.3, 0.62), Vector2(0.55, 0.75), Vector2(0.9, 0.7)],
				[Vector2(0.15, 0.0), Vector2(0.3, 0.3), Vector2(0.42, 0.6), Vector2(0.35, 1.0)],
				[Vector2(0.6, 0.0), Vector2(0.65, 0.4), Vector2(0.8, 0.55), Vector2(0.93, 0.6)]]:
			ci.draw_polyline(_smooth(_pts(r, street)), Color.WHITE, r.size.y * 0.035, true)
	else:
		ci.draw_rect(r, Color.WHITE)
	for line: String in RAIL_LINES:
		var stops: Array = RAIL_LINES[line]
		var pts: Array = []
		for s: Variant in stops:
			pts.append(_stop_at(view, str(s), r))
		var drawn := _smooth(pts) if view == "real" else PackedVector2Array(pts)
		ci.draw_polyline(drawn, RAIL_COLOURS[line], 5.0, true)
	for i in range(1, route.size()):
		ci.draw_line(_stop_at(view, str(route[i - 1]), r), _stop_at(view, str(route[i]), r), ORANGE, 9.0, true)
	for s: String in STOPS:
		var p := _stop_at(view, s, r)
		var marked := d.has("mark") and str(d.mark) == s
		ci.draw_circle(p, 8.0 if s == "Market" else 6.5, Color.WHITE)
		ci.draw_arc(p, 8.0 if s == "Market" else 6.5, 0.0, TAU, 20, ORANGE if marked else INK, 3.0, true)
		var below := view == "model" and s in ["Hill", "Park", "Station", "Harbour"]
		var off := Vector2(0, fs * 1.1) if below or (view == "real" and p.y < r.get_center().y) else Vector2(0, -fs * 1.1)
		if view == "model" and s in ["School", "Castle"]:
			off = Vector2(fs * 0.7 + _text_w(font, s, fs) * 0.5, 0)
		elif view == "model" and s == "Market":
			off = Vector2(fs * 0.5 + _text_w(font, s, fs) * 0.5, -fs * 1.0)
		_say(ci, font, p + off, s, fs, ORANGE if marked else INK)


# --- CPU -----------------------------------------------------------------------------------------------------------------

static func _draw_cpu(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	if str(d.view) == "cycle":
		_draw_cycle(ci, font, r, d, fs)
		return
	var a := _diagram_box(d, r)
	var cpu := _sub(a, 0.02, 0.04, 0.56, 0.96)
	_box(ci, cpu, Color("e3ebf7"), INK, 10, 2)
	_say(ci, font, _at(a, 0.29, 0.12), "processor (CPU)", _fit(font, "processor (CPU)", fs - 1, cpu.size.x * 0.9), INK, false)
	var boxes := {"control unit": _sub(a, 0.06, 0.21, 0.28, 0.49), "ALU": _sub(a, 0.3, 0.21, 0.51, 0.49),
		"program counter": _sub(a, 0.06, 0.61, 0.28, 0.89), "accumulator": _sub(a, 0.3, 0.61, 0.51, 0.89)}
	var shown := {"control unit": "control unit", "ALU": "ALU", "program counter": "PC  %s" % _cell_text(d.get("pc", "")),
		"accumulator": "ACC  %s" % _cell_text(d.get("acc", ""))}
	for part: String in boxes:
		_box(ci, boxes[part], Color.WHITE if part in ["control unit", "ALU"] else Color("fff6dd"), INK, 6, 2)
		_text_in(ci, font, boxes[part], str(shown[part]).strip_edges(), fs)
	var mem := _sub(a, 0.68, 0.06, 0.98, 0.94)
	_box(ci, mem, Color.WHITE, INK, 6, 2)
	var rows: Array = d.get("memory", [])
	var rh := mem.size.y / float(maxi(rows.size(), 4) + 1)
	_say(ci, font, Vector2(mem.get_center().x, mem.position.y + rh * 0.5), "memory", fs - 1, INK, false)
	for i in rows.size():
		var y := mem.position.y + rh * (i + 1)
		var row_rect := Rect2(Vector2(mem.position.x + 3, y), Vector2(mem.size.x - 6, rh))
		if d.has("pc") and int(rows[i][0]) == int(d.pc):
			_box(ci, row_rect, SOFT, ORANGE, 4, 2)
		ci.draw_line(Vector2(mem.position.x, y), Vector2(mem.end.x, y), PALE, 1.0)
		var said := _cell_text(rows[i][1])
		var rfs := _fit(font, said, fs - 1, mem.size.x * 0.66)
		_say_from(ci, font, Vector2(mem.position.x + 6, y + rh * 0.5), str(int(rows[i][0])), rfs, GREY, false, false)
		_say_from(ci, font, Vector2(mem.position.x + mem.size.x * 0.3, y + rh * 0.5), said, rfs, INK, false, false)
	for dy: float in [0.42, 0.58]:
		ci.draw_line(_at(a, 0.56, dy), _at(a, 0.68, dy), Color("6a7486"), 5.0, true)
	_label_parts(ci, font, r, d, _anchors(d, a), fs)


static func _draw_cycle(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary, fs: int) -> void:
	var at := {"fetch": _at(r, 0.5, 0.2), "decode": _at(r, 0.8, 0.72), "execute": _at(r, 0.2, 0.72)}
	var w := minf(r.size.x * 0.3, fs * 11.0)
	var h := r.size.y * 0.3
	var step := str(d.get("step", ""))
	for i in 3:
		var a: Vector2 = at[CYCLE_STEPS[i]]
		var b: Vector2 = at[CYCLE_STEPS[(i + 1) % 3]]
		var mid := (a + b) * 0.5 + (r.get_center() - (a + b) * 0.5).normalized() * -r.size.y * 0.08
		var from := a + (mid - a).normalized() * h * 0.62
		var to := b + (mid - b).normalized() * h * 0.62
		var pts := _curve(from, mid, to, 16)
		ci.draw_polyline(pts, INK, 3.0, true)
		_head(ci, to, (to - pts[pts.size() - 3]).normalized(), 13.0, INK)
	for s: String in CYCLE_STEPS:
		var c: Vector2 = at[s]
		var box := Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))
		var on := s == step
		_box(ci, box, SOFT if on else Color.WHITE, ORANGE if on else INK, 10, 3 if on else 2)
		_say(ci, font, c - Vector2(0, h * 0.18), s.to_upper(), fs + 2, ORANGE if on else INK, false)
		var said := str(CYCLE_SAID[s])
		_say(ci, font, c + Vector2(0, h * 0.2), said, _fit(font, said, fs - 1, w - 10), INK, false)


# --- Sampled wave --------------------------------------------------------------------------------------------------------

static func _draw_samples(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var levels := 1 << int(d.bits)
	var samples: Array = d.samples
	var plot := Rect2(r.position + Vector2(fs * 2.2, fs * 0.5), r.size - Vector2(fs * 2.6, fs * 2.2))
	ci.draw_rect(plot, Color.WHITE)
	for v in levels:
		var y := plot.end.y - plot.size.y * (v + 0.5) / levels
		ci.draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), PALE, 1.0)
		if levels <= 8 or v % 3 == 0 or v == levels - 1:
			_say_from(ci, font, Vector2(plot.position.x - 4, y), str(v), fs - 3, GREY, true, false)
	var n := samples.size()
	var pts: Array = []
	for i in n:
		pts.append(Vector2(plot.position.x + plot.size.x * (i + 0.5) / n, plot.end.y - plot.size.y * (int(samples[i]) + 0.5) / levels))
	if bool(d.get("wave", true)):
		ci.draw_polyline(_smooth(pts, 10), Color("b8c4d8"), 3.0, true)
	var view := str(d.get("view", "dots"))
	for i in n:
		var p: Vector2 = pts[i]
		match view:
			"bars":
				ci.draw_rect(Rect2(Vector2(p.x - plot.size.x * 0.3 / n, p.y), Vector2(plot.size.x * 0.6 / n, plot.end.y - p.y)),
					Color("8fb8f0"))
			"steps":
				var x0 := plot.position.x + plot.size.x * i / float(n)
				var x1 := plot.position.x + plot.size.x * (i + 1) / float(n)
				ci.draw_line(Vector2(x0, p.y), Vector2(x1, p.y), BLUE, 3.0, true)
				if i < n - 1:
					ci.draw_line(Vector2(x1, p.y), Vector2(x1, pts[i + 1].y), BLUE, 3.0, true)
			_:
				ci.draw_line(Vector2(p.x, plot.end.y), p, Color("8fb8f0"), 2.0, true)
				ci.draw_circle(p, 5.0, BLUE)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.0)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.0)
	_say(ci, font, Vector2(plot.get_center().x, plot.end.y + fs * 0.9), "time", fs - 1, INK, false)


# --- Logic circuits ------------------------------------------------------------------------------------------------------

## A gate's or an input's place: the depth from the output (0 is the last gate) and the rows its inputs take.
static func _gate_layout(e: Variant, depth: int, rows: Array, out: Array) -> float:
	if e is String:
		rows.append(e)
		var y := float(rows.size() - 1)
		out.append({"leaf": e, "y": y, "depth": depth})
		return y
	var ys: Array[float] = []
	var here := {"gate": str(e[0]), "depth": depth, "kids": []}
	out.append(here)
	for i in range(1, (e as Array).size()):
		ys.append(_gate_layout(e[i], depth + 1, rows, out))
		here.kids.append(out.size() - 1 if e[i] is String else _last_gate(out, depth + 1))
	var y := 0.0
	for v in ys:
		y += v
	here.y = y / ys.size()
	here.expr = e
	return here.y


static func _last_gate(out: Array, depth: int) -> int:
	for i in range(out.size() - 1, -1, -1):
		if out[i].has("gate") and int(out[i].depth) == depth and not out[i].has("taken"):
			out[i].taken = true
			return i
	return -1


static func _tree_depth(e: Variant) -> int:
	if not e is Array:
		return 0
	var m := 0
	for i in range(1, (e as Array).size()):
		m = maxi(m, _tree_depth(e[i]))
	return m + 1


static func _draw_gates(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var expr: Variant = d.expr
	var inputs: Dictionary = d.inputs
	var lit := bool(d.get("lit", false))
	var show_out := bool(d.get("out", true))
	var rows: Array = []
	var nodes: Array = []
	_gate_layout(expr, 0, rows, nodes)
	var depth := _tree_depth(expr)
	var fs := _fs(r, 12.0)
	var left := r.position.x + fs * 2.6
	var right := r.end.x - r.size.y * 0.22
	var colw := (right - left) / float(depth + 1)
	var rowh := r.size.y / float(rows.size())
	var gh := minf(rowh * 0.9, r.size.y * 0.32) if rows.size() > 1 else r.size.y * 0.4
	gh = minf(gh, colw * 0.75)
	var place := func(node: Dictionary) -> Vector2:
		var x: float = left if node.has("leaf") else right - colw * (int(node.depth) + 0.5)
		return Vector2(x, r.position.y + rowh * (float(node.y) + 0.5))
	# wires first, from each gate's inputs back to what feeds them
	for node: Dictionary in nodes:
		if not node.has("gate"):
			continue
		var c: Vector2 = place.call(node)
		var kids: Array = node.kids
		for k in kids.size():
			var kid: Dictionary = nodes[int(kids[k])]
			var kp: Vector2 = place.call(kid)
			var src := kp + (Vector2(gh * 0.56, 0) if kid.has("gate") else Vector2(fs * 0.9, 0))
			var in_y := c.y + (0.0 if kids.size() == 1 else (-gh * 0.25 if k == 0 else gh * 0.25))
			var dst := Vector2(c.x - gh * 0.5, in_y)
			var v := circuit_out(kid.get("expr", kid.get("leaf", "")), inputs)
			var colour := ORANGE if lit and v == 1 else INK
			var mx := (src.x + dst.x) * 0.5 if kid.has("gate") else dst.x - colw * 0.25
			ci.draw_polyline(PackedVector2Array([src, Vector2(mx, src.y), Vector2(mx, dst.y), dst]), colour, 2.5, true)
			if lit:
				_say(ci, font, Vector2(dst.x - fs * 0.6, dst.y - fs * 0.6), str(v), fs - 3, colour)
	# the output wire and lamp
	var root: Dictionary = nodes[0]
	var rp: Vector2 = place.call(root)
	var out_x := rp.x + gh * 0.56
	var lamp := Vector2(r.end.x - r.size.y * 0.12, rp.y)
	var v_out := circuit_out(expr, inputs)
	ci.draw_line(Vector2(out_x, rp.y), lamp - Vector2(r.size.y * 0.09, 0), ORANGE if lit and show_out and v_out == 1 else INK, 2.5, true)
	var glow := show_out and v_out == 1
	ci.draw_circle(lamp, r.size.y * 0.09, Color("ffe066") if glow else Color("e4e7ec"))
	ci.draw_arc(lamp, r.size.y * 0.09, 0.0, TAU, 24, INK, 2.0, true)
	_say(ci, font, lamp + Vector2(0, r.size.y * 0.16), str(v_out) if show_out else "?", fs, ORANGE if not show_out else INK, false)
	for node: Dictionary in nodes:
		var p: Vector2 = place.call(node)
		if node.has("leaf"):
			var l := str(node.leaf)
			var box := Rect2(p - Vector2(fs * 2.3, fs * 0.8), Vector2(fs * 3.2, fs * 1.6))
			var one := int(inputs.get(l, 0)) == 1
			_box(ci, box, Color("ffe7b8") if one else Color.WHITE, INK, 5, 2)
			_say(ci, font, box.get_center(), "%s = %d" % [l, int(inputs.get(l, 0))], _fit(font, "A = 0", fs, box.size.x - 4), INK, false)
		else:
			_gate_symbol(ci, font, str(node.gate), p, gh, fs)


static func _gate_symbol(ci: CanvasItem, font: Font, gate: String, c: Vector2, h: float, fs: int) -> void:
	var w := h * 1.1
	var x0 := c.x - h * 0.5
	match gate:
		"AND":
			var pts := PackedVector2Array([Vector2(x0, c.y - h * 0.5)])
			for i in 17:
				var ang := -PI * 0.5 + PI * i / 16.0
				pts.append(Vector2(x0 + w * 0.5, c.y) + Vector2(cos(ang) * w * 0.5, sin(ang) * h * 0.5))
			pts.append(Vector2(x0, c.y + h * 0.5))
			_poly(ci, pts, Color("dfe9fb"), INK, 2.0)
		"OR":
			var pts := PackedVector2Array()
			for i in 17:
				pts.append(_bez(Vector2(x0, c.y - h * 0.5), Vector2(x0 + w * 0.6, c.y - h * 0.5), Vector2(x0 + w, c.y), i / 16.0))
			for i in range(1, 17):
				pts.append(_bez(Vector2(x0 + w, c.y), Vector2(x0 + w * 0.6, c.y + h * 0.5), Vector2(x0, c.y + h * 0.5), i / 16.0))
			for i in range(1, 16):
				pts.append(_bez(Vector2(x0, c.y + h * 0.5), Vector2(x0 + w * 0.25, c.y), Vector2(x0, c.y - h * 0.5), i / 16.0))
			_poly(ci, pts, Color("e2f4df"), INK, 2.0)
		"NOT":
			_poly(ci, [Vector2(x0, c.y - h * 0.4), Vector2(x0 + w * 0.8, c.y), Vector2(x0, c.y + h * 0.4)], Color("fbe3df"), INK, 2.0)
			ci.draw_circle(Vector2(x0 + w * 0.8 + h * 0.09, c.y), h * 0.09, Color.WHITE)
			ci.draw_arc(Vector2(x0 + w * 0.8 + h * 0.09, c.y), h * 0.09, 0.0, TAU, 14, INK, 2.0, true)
	_say(ci, font, Vector2(x0 + w * (0.4 if gate == "NOT" else 0.45), c.y), gate, _fit(font, gate, fs - 1, w * 0.62), INK, false)


# --- Database table ------------------------------------------------------------------------------------------------------

static func _draw_db(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fields: Array = d.fields
	var rows: Array = d.rows
	var fs := _fs(r, 13.0)
	var y := r.position.y
	if d.has("query"):
		var q := str(d.query)
		var qr := Rect2(Vector2(r.position.x, y), Vector2(r.size.x, fs * 1.8))
		_box(ci, qr, Color("2b3140"), Color("2b3140"), 6, 1)
		_say(ci, font, qr.get_center(), q, _fit(font, q, fs, qr.size.x - 12), Color("ffe7a6"), false)
		y += fs * 2.2
	var tab := str(d.name)
	var tab_w := _text_w(font, tab, fs) + 18.0
	_box(ci, Rect2(Vector2(r.position.x, y), Vector2(tab_w, fs * 1.6)), Color("dbe8ff"), INK, 5, 2)
	_say(ci, font, Vector2(r.position.x + tab_w * 0.5, y + fs * 0.8), tab, fs, INK, false)
	y += fs * 1.6
	var table := Rect2(Vector2(r.position.x, y), Vector2(r.size.x, r.end.y - y))
	var nrow := rows.size() + 1
	var rh := minf(table.size.y / nrow, fs * 2.4)
	var cw := table.size.x / fields.size()
	var key := _int(d, "key", -1)
	var picked: Array = d.get("pick", [])
	var field := _int(d, "field", -1)
	ci.draw_rect(Rect2(table.position, Vector2(table.size.x, rh * nrow)), Color.WHITE)
	if field >= 0:
		ci.draw_rect(Rect2(table.position + Vector2(cw * field, 0), Vector2(cw, rh * nrow)), Color("dcecff"))
	for i in rows.size():
		if picked.has(i) or picked.has(float(i)):
			ci.draw_rect(Rect2(table.position + Vector2(0, rh * (i + 1)), Vector2(table.size.x, rh)), SOFT)
	ci.draw_rect(Rect2(table.position, Vector2(table.size.x, rh)), Color("e7ebf2"))
	for c in fields.size():
		var t := str(fields[c])
		var cx := table.position.x + cw * (c + 0.5)
		var f := _fit(font, t, fs, cw - (fs * 1.6 if c == key else 8.0))
		_say(ci, font, Vector2(cx + (fs * 0.5 if c == key else 0.0), table.position.y + rh * 0.5), t, f, INK, false)
		if c == key:
			var w := _text_w(font, t, f)
			var ux := cx + fs * 0.5 - w * 0.5
			ci.draw_line(Vector2(ux, table.position.y + rh * 0.78), Vector2(ux + w, table.position.y + rh * 0.78), INK, 2.0)
			_key_icon(ci, Vector2(ux - fs * 0.9, table.position.y + rh * 0.5), fs * 0.5)
		for i in rows.size():
			var v := _cell_text(rows[i][c])
			_say(ci, font, Vector2(cx, table.position.y + rh * (i + 1.5)), v, _fit(font, v, fs, cw - 8.0), INK, false)
	for i in nrow + 1:
		ci.draw_line(table.position + Vector2(0, rh * i), table.position + Vector2(table.size.x, rh * i), GREY, 1.0)
	for c in fields.size() + 1:
		ci.draw_line(table.position + Vector2(cw * c, 0), table.position + Vector2(cw * c, rh * nrow), GREY, 1.0)


static func _key_icon(ci: CanvasItem, c: Vector2, s: float) -> void:
	ci.draw_arc(c - Vector2(s * 0.4, 0), s * 0.38, 0.0, TAU, 14, GOLD, 2.5, true)
	ci.draw_line(c, c + Vector2(s * 0.9, 0), GOLD, 2.5, true)
	ci.draw_line(c + Vector2(s * 0.65, 0), c + Vector2(s * 0.65, s * 0.35), GOLD, 2.0, true)


# --- Scatter of training examples ----------------------------------------------------------------------------------------

static func _draw_scatter(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var groups: Array = d.groups
	var axes: Array = d.axes
	var plot := Rect2(r.position + Vector2(fs * 2.2, fs * 2.0), r.size - Vector2(fs * 2.6, fs * 4.0))
	ci.draw_rect(plot, Color.WHITE)
	var to_px := func(x: float, y: float) -> Vector2:
		return Vector2(plot.position.x + plot.size.x * x / 10.0, plot.end.y - plot.size.y * y / 10.0)
	for t in [0, 5, 10]:
		var x: Vector2 = to_px.call(float(t), 0.0)
		var y: Vector2 = to_px.call(0.0, float(t))
		ci.draw_line(Vector2(x.x, plot.position.y), Vector2(x.x, plot.end.y), PALE, 1.0)
		ci.draw_line(Vector2(plot.position.x, y.y), Vector2(plot.end.x, y.y), PALE, 1.0)
		_say(ci, font, Vector2(x.x, plot.end.y + fs * 0.7), str(t), fs - 3, GREY, false)
		_say_from(ci, font, Vector2(plot.position.x - 4, y.y), str(t), fs - 3, GREY, true, false)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, INK, 2.0)
	ci.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), INK, 2.0)
	_say(ci, font, Vector2(plot.get_center().x, plot.end.y + fs * 1.6), str(axes[0]), fs - 1, INK, false)
	_say_from(ci, font, Vector2(plot.position.x - fs * 1.8, plot.position.y - fs * 1.1), str(axes[1]), fs - 1, INK, false, false)
	# the key: a circle for the first group, a triangle for the second (shape and colour, so either tells them apart)
	var kx := plot.end.x - fs * 0.5
	for g in [1, 0]:
		var name := str(groups[g])
		var w := _text_w(font, name, fs - 1)
		_say_from(ci, font, Vector2(kx, r.position.y + fs * 0.7), name, fs - 1, INK, true, false)
		_mark_point(ci, Vector2(kx - w - fs * 0.8, r.position.y + fs * 0.7), int(g), fs * 0.45)
		kx -= w + fs * 2.6
	if d.has("line"):
		var l: Array = d.line
		_dashed(ci, to_px.call(float(l[0]), float(l[1])), to_px.call(float(l[2]), float(l[3])), GREY, 2.0)
	var pts: Array = d.points
	var ringed: Array[int] = []
	if d.has("new") and d.has("near"):
		ringed = nearest(pts, float(d.new[0]), float(d.new[1]), int(d.near))
		for i in ringed:
			_dashed(ci, to_px.call(float(d.new[0]), float(d.new[1])), to_px.call(float(pts[i][0]), float(pts[i][1])), GREEN, 2.0, 5.0)
	for i in pts.size():
		var p: Vector2 = to_px.call(float(pts[i][0]), float(pts[i][1]))
		_mark_point(ci, p, int(pts[i][2]), fs * 0.5)
		if ringed.has(i):
			ci.draw_arc(p, fs * 0.95, 0.0, TAU, 20, GREEN, 2.5, true)
	if d.has("new"):
		var p: Vector2 = to_px.call(float(d.new[0]), float(d.new[1]))
		ci.draw_circle(p, fs * 0.75, Color.WHITE)
		ci.draw_arc(p, fs * 0.75, 0.0, TAU, 20, INK, 2.5, true)
		_say(ci, font, p, "?", fs, INK, false)


static func _mark_point(ci: CanvasItem, p: Vector2, group: int, s: float) -> void:
	if group == 0:
		ci.draw_circle(p, s, BLUE)
		ci.draw_arc(p, s, 0.0, TAU, 16, INK, 1.5, true)
	else:
		_poly(ci, [p + Vector2(0, -s * 1.2), p + Vector2(s * 1.1, s * 0.8), p + Vector2(-s * 1.1, s * 0.8)], ORANGE, INK, 1.5)


# --- Threats -------------------------------------------------------------------------------------------------------------

static func _file_icon(ci: CanvasItem, c: Vector2, s: float, fill: Color = Color.WHITE) -> Rect2:
	var rect := Rect2(c - Vector2(s * 0.38, s * 0.5), Vector2(s * 0.76, s))
	_poly(ci, [rect.position, rect.position + Vector2(rect.size.x * 0.7, 0), rect.position + Vector2(rect.size.x, rect.size.y * 0.25),
		rect.end, Vector2(rect.position.x, rect.end.y)], fill, INK, 2.0)
	for k in 3:
		var y := rect.position.y + rect.size.y * (0.45 + 0.15 * k)
		ci.draw_line(Vector2(rect.position.x + s * 0.1, y), Vector2(rect.end.x - s * 0.1, y), GREY, 1.5)
	return rect


static func _germ(ci: CanvasItem, c: Vector2, s: float) -> void:
	for k in 8:
		var ang := TAU * k / 8.0
		ci.draw_line(c, c + Vector2(cos(ang), sin(ang)) * s * 1.5, Color("4d9e3a"), 2.0, true)
		ci.draw_circle(c + Vector2(cos(ang), sin(ang)) * s * 1.5, s * 0.25, Color("4d9e3a"))
	ci.draw_circle(c, s, Color("7cc35a"))
	ci.draw_arc(c, s, 0.0, TAU, 16, Color("2f6e22"), 1.5, true)


static func _screen_box(ci: CanvasItem, c: Vector2, s: float) -> Rect2:
	var scr := Rect2(c - Vector2(s * 0.55, s * 0.42), Vector2(s * 1.1, s * 0.7))
	_box(ci, scr.grow(3), Color("3a4252"), INK, 4, 2)
	ci.draw_rect(scr, Color("dbe8ff"))
	ci.draw_rect(Rect2(Vector2(c.x - s * 0.1, scr.end.y + 3), Vector2(s * 0.2, s * 0.12)), Color("3a4252"))
	ci.draw_rect(Rect2(Vector2(c.x - s * 0.3, scr.end.y + 3 + s * 0.12), Vector2(s * 0.6, s * 0.06)), Color("3a4252"))
	return scr


static func _draw_threat(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var named := bool(d.get("name", false))
	var a := Rect2(r.position, r.size - Vector2(0, fs * 1.8 if named else 0.0))
	var s := minf(a.size.y * 0.5, a.size.x * 0.22)
	var c := a.get_center()
	match str(d.threat):
		"virus":
			_file_icon(ci, c - Vector2(s * 1.2, 0), s * 1.3)
			_germ(ci, c - Vector2(s * 1.2, -s * 0.05), s * 0.22)
			for k in 2:
				var p := c + Vector2(s * 1.3, (k - 0.5) * s * 1.2)
				_file_icon(ci, p, s * 0.9)
				_arrow(ci, c - Vector2(s * 0.5, 0), p - Vector2(s * 0.45, 0), RED, 3.0)
				_germ(ci, p + Vector2(0, s * 0.05), s * 0.14)
		"worm":
			var pcs := [c + Vector2(-s * 1.6, s * 0.3), c + Vector2(0, -s * 0.4), c + Vector2(s * 1.6, s * 0.3)]
			ci.draw_line(pcs[0], pcs[1], GREY, 4.0, true)
			ci.draw_line(pcs[1], pcs[2], GREY, 4.0, true)
			for p: Vector2 in pcs:
				_screen_box(ci, p, s * 0.8)
			var mid: Vector2 = (pcs[1] + pcs[2]) * 0.5
			var body := PackedVector2Array()
			for k in 12:
				body.append(mid + Vector2(-s * 0.4 + s * 0.07 * k, sin(k * 1.2) * s * 0.07 - s * 0.05))
			ci.draw_polyline(body, Color("d97a8c"), s * 0.13, true)
			ci.draw_circle(body[-1], s * 0.09, Color("c25a6e"))
		"trojan":
			var box := Rect2(c - Vector2(s * 0.9, s * 0.5), Vector2(s * 1.8, s * 1.2))
			ci.draw_rect(box, Color("e8564b"))
			ci.draw_rect(Rect2(Vector2(c.x - s * 0.12, box.position.y), Vector2(s * 0.24, box.size.y)), GOLD)
			ci.draw_rect(Rect2(box.position - Vector2(s * 0.08, s * 0.3), Vector2(box.size.x + s * 0.16, s * 0.32)), Color("d0463c"))
			ci.draw_circle(Vector2(c.x - s * 0.22, box.position.y - s * 0.36), s * 0.2, GOLD)
			ci.draw_circle(Vector2(c.x + s * 0.22, box.position.y - s * 0.36), s * 0.2, GOLD)
			_say(ci, font, Vector2(c.x - s * 0.5, c.y + s * 0.15), "FREE", _fit(font, "FREE", fs, s * 0.6), Color.WHITE, false)
			_germ(ci, Vector2(box.end.x - s * 0.25, box.end.y - s * 0.25), s * 0.16)
			ci.draw_rect(Rect2(Vector2(box.end.x - s * 0.55, box.end.y - s * 0.5), Vector2(s * 0.5, s * 0.5)), Color(0, 0, 0, 0.18))
		"ransomware":
			for k in 3:
				_file_icon(ci, c + Vector2((k - 1) * s * 0.7, s * 0.1), s * 1.1, Color("eef1f6"))
			var lock := Rect2(c + Vector2(-s * 0.45, -s * 0.05), Vector2(s * 0.9, s * 0.7))
			ci.draw_arc(Vector2(c.x, lock.position.y), s * 0.3, PI, TAU, 16, INK, s * 0.12, true)
			_box(ci, lock, GOLD, INK, 6, 2)
			ci.draw_circle(lock.get_center() - Vector2(0, s * 0.06), s * 0.09, INK)
			ci.draw_rect(Rect2(lock.get_center() - Vector2(s * 0.03, 0), Vector2(s * 0.06, s * 0.18)), INK)
		"spyware":
			var scr := _screen_box(ci, c - Vector2(0, s * 0.25), s * 1.6)
			var eye := scr.get_center()
			var pts := PackedVector2Array()
			for k in 21:
				var t := float(k) / 20.0
				pts.append(eye + Vector2((t - 0.5) * s * 1.2, -sin(t * PI) * s * 0.3))
			for k in range(1, 20):
				var t := 1.0 - float(k) / 20.0
				pts.append(eye + Vector2((t - 0.5) * s * 1.2, sin(t * PI) * s * 0.3))
			_poly(ci, pts, Color.WHITE, INK, 2.0)
			ci.draw_circle(eye, s * 0.2, Color("3a7be8"))
			ci.draw_circle(eye, s * 0.09, INK)
			var kb := Rect2(Vector2(c.x - s * 0.95, c.y + s * 0.62), Vector2(s * 1.9, s * 0.35))
			_box(ci, kb, Color("c9ced8"), INK, 4, 2)
			for k in 8:
				ci.draw_rect(Rect2(Vector2(kb.position.x + s * 0.08 + k * s * 0.225, kb.position.y + s * 0.08), Vector2(s * 0.17, s * 0.19)), Color.WHITE)
		"phishing":
			var env := Rect2(c - Vector2(s * 0.9, s * 0.2), Vector2(s * 1.8, s * 1.0))
			_box(ci, env, Color.WHITE, INK, 4, 2)
			ci.draw_polyline(PackedVector2Array([env.position, Vector2(c.x, env.position.y + env.size.y * 0.55),
				Vector2(env.end.x, env.position.y)]), INK, 2.0, true)
			var hook := Vector2(c.x + s * 0.15, env.position.y + s * 0.12)
			ci.draw_line(Vector2(hook.x + s * 0.15, a.position.y), Vector2(hook.x + s * 0.15, hook.y), Color("6a7486"), 2.0, true)
			ci.draw_arc(hook, s * 0.15, 0.0, PI, 14, Color("6a7486"), 4.0, true)
			ci.draw_line(Vector2(hook.x - s * 0.15, hook.y), Vector2(hook.x - s * 0.15, hook.y - s * 0.12), Color("6a7486"), 4.0, true)
			_head(ci, Vector2(hook.x - s * 0.15, hook.y - s * 0.2), Vector2(0, -1), s * 0.12, Color("6a7486"))
		"shoulder_surfing":
			var phone := Rect2(c + Vector2(-s * 0.95, -s * 0.15), Vector2(s * 0.5, s * 0.85))
			_person_head(ci, c + Vector2(-s * 1.2, -s * 0.5), s * 0.42, HAIR)
			ci.draw_rect(Rect2(c + Vector2(-s * 1.6, -s * 0.05), Vector2(s * 0.8, s * 1.1)), Color("4f7fd0"))
			_box(ci, phone, Color("dbe8ff"), INK, 5, 2)
			for k in 4:
				ci.draw_circle(phone.position + Vector2(s * (0.12 + 0.09 * k), s * 0.3), s * 0.03, INK)
			_person_head(ci, c + Vector2(s * 0.75, -s * 0.85), s * 0.42, Color("2a2c31"))
			ci.draw_rect(Rect2(c + Vector2(s * 0.35, -s * 0.4), Vector2(s * 0.8, s * 1.4)), Color("7a8a9c"))
			_dashed(ci, c + Vector2(s * 0.55, -s * 0.85), phone.get_center(), RED, 2.0, 5.0)
	if named:
		_say(ci, font, Vector2(r.get_center().x, r.end.y - fs * 0.7), str(THREAT_NAMES[str(d.threat)]), fs, INK, false)


static func _person_head(ci: CanvasItem, c: Vector2, s: float, hair: Color) -> void:
	ci.draw_circle(c, s, SKIN)
	ci.draw_arc(c, s, PI * 1.05, TAU * 0.98, 16, hair, s * 0.45, true)
	ci.draw_circle(c + Vector2(-s * 0.32, -s * 0.05), s * 0.08, INK)
	ci.draw_circle(c + Vector2(s * 0.32, -s * 0.05), s * 0.08, INK)


# --- App screen ----------------------------------------------------------------------------------------------------------

static func _draw_app(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var a := _diagram_box(d, r)
	var design := str(d.design)
	var phone := _sub(a, 0.345, 0.02, 0.655, 0.98)
	_box(ci, phone, Color("2b3140"), INK, 14, 2)
	var scr := phone.grow(-a.size.y * 0.035)
	var bg := Color.WHITE
	var text := INK if design != "low_contrast" else Color("c9ced8")
	ci.draw_rect(scr, bg)
	var head := Rect2(scr.position, Vector2(scr.size.x, a.size.y * 0.13))
	ci.draw_rect(head, Color("3a7be8") if design != "low_contrast" else Color("e8edf5"))
	var head_text := Color.WHITE if design != "low_contrast" else Color("c9d2e2")
	var tfs := _fit(font, "Homework", fs, scr.size.x * 0.6)
	if design == "tiny":
		tfs = maxi(tfs - 5, 7)
	_say(ci, font, _at(a, 0.53, 0.12), "Homework", tfs, head_text, false)
	_head(ci, _at(a, 0.37, 0.12), Vector2(-1, 0), a.size.y * (0.03 if design == "tiny" else 0.06), head_text)
	var tasks := ["Maths p. 12", "Read ch. 3", "Spelling"]
	var colours := [GREEN, RED, GREEN]
	for i in 3:
		var y := a.position.y + a.size.y * (0.29 + 0.12 * i)
		var row := Rect2(Vector2(scr.position.x + 4, y), Vector2(scr.size.x - 8, a.size.y * 0.1))
		ci.draw_rect(row, Color("f4f6fa") if design != "low_contrast" else Color("fbfbfc"))
		var mark_c := Vector2(row.position.x + row.size.y * 0.5, row.get_center().y)
		if design == "colour_only":
			ci.draw_circle(mark_c, row.size.y * 0.22, colours[i])
		elif design == "no_words":
			ci.draw_rect(Rect2(mark_c - Vector2(row.size.y * 0.2, row.size.y * 0.2), Vector2(row.size.y * 0.4, row.size.y * 0.4)), Color("c9ced8"))
		else:
			ci.draw_rect(Rect2(mark_c - Vector2(row.size.y * 0.22, row.size.y * 0.22), Vector2(row.size.y * 0.44, row.size.y * 0.44)), Color.WHITE)
			ci.draw_rect(Rect2(mark_c - Vector2(row.size.y * 0.22, row.size.y * 0.22), Vector2(row.size.y * 0.44, row.size.y * 0.44)), text, false, 2.0)
			if i != 1:
				ci.draw_polyline(PackedVector2Array([mark_c + Vector2(-row.size.y * 0.15, 0), mark_c + Vector2(-row.size.y * 0.03, row.size.y * 0.13),
					mark_c + Vector2(row.size.y * 0.18, -row.size.y * 0.15)]), GREEN, 3.0, true)
		var rfs := _fit(font, str(tasks[i]), fs - 2, row.size.x - row.size.y * 1.2)
		if design == "tiny":
			rfs = maxi(rfs - 4, 7)
		if design == "no_words":
			ci.draw_rect(Rect2(Vector2(row.position.x + row.size.y * 1.1, row.get_center().y - 3), Vector2(row.size.x * 0.5, 6)), Color("dde2ea"))
		else:
			_say_from(ci, font, Vector2(row.position.x + row.size.y * 1.05, row.get_center().y), str(tasks[i]), rfs, text, false, false)
	if design == "cluttered":
		for k in 5:
			var p := _at(a, 0.37 + 0.055 * k, 0.66 + 0.05 * (k % 2))
			ci.draw_rect(Rect2(p, Vector2(a.size.x * 0.04, a.size.y * 0.05)), [RED, GOLD, Color("8a3fb8"), GREEN, ORANGE][k])
		ci.draw_rect(_sub(a, 0.36, 0.2, 0.64, 0.27), Color("f7d21e"))
		_say(ci, font, _at(a, 0.5, 0.235), "WIN A PRIZE!", _fit(font, "WIN A PRIZE!", fs - 2, a.size.x * 0.26), RED, false)
	var add := _sub(a, 0.4, 0.75, 0.6, 0.87)
	if design == "tiny":
		add = _sub(a, 0.49, 0.79, 0.51, 0.83)
	_box(ci, add, Color("3fa34d") if design != "low_contrast" else Color("e9f5ea"), Color("2e7d3a") if design != "low_contrast" else Color("e0eee2"), 10, 2)
	var label := "+" if design == "no_words" else ("ADD TASK" if design != "tiny" else "+")
	_say(ci, font, add.get_center(), label, _fit(font, label, fs, add.size.x - 8), Color.WHITE if design != "low_contrast" else Color("c9d8cc"), false)
	if design == "clear":
		_label_parts(ci, font, r, d, _anchors(d, a), fs)


# --- Light at different times (Monet's series) ---------------------------------------------------------------------------

static func _draw_light_series(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var times: Array = d.times
	var names := bool(d.get("names", false))
	var fs := _fs(r, 12.0)
	var n := times.size()
	var gap := 8.0
	var pw := (r.size.x - gap * (n - 1)) / n
	var ph := r.size.y - (fs * 1.8 if names else 0.0)
	for i in n:
		var t := str(times[i])
		var p := Rect2(Vector2(r.position.x + i * (pw + gap), r.position.y), Vector2(pw, ph))
		_haystack(ci, p, t, i)
		ci.draw_rect(p, Color("6b4b2a"), false, 3.0)
		if names:
			_say(ci, font, Vector2(p.get_center().x, r.end.y - fs * 0.7), t, fs, INK, false)


static func _haystack(ci: CanvasItem, p: Rect2, t: String, salt: int) -> void:
	var col: Array = TIME_COLOURS[t]
	var horizon := p.position.y + p.size.y * 0.58
	var bands := 10
	for k in bands:
		var c: Color = (col[0] as Color).lerp(col[1], float(k) / (bands - 1))
		ci.draw_rect(Rect2(Vector2(p.position.x, p.position.y + (horizon - p.position.y) * k / bands),
			Vector2(p.size.x, (horizon - p.position.y) / bands + 1)), c)
	ci.draw_rect(Rect2(Vector2(p.position.x, horizon), Vector2(p.size.x, p.end.y - horizon)), col[3])
	var sun: Vector2 = SUN_AT[t]
	var sp := p.position + Vector2(p.size.x * sun.x, p.size.y * sun.y)
	ci.draw_circle(sp, minf(p.size.x, p.size.y) * 0.07, col[2])
	var base := Vector2(p.get_center().x, p.position.y + p.size.y * 0.8)
	var w := minf(p.size.x * 0.5, p.size.y * 0.42)
	var body_h := p.size.y * 0.16
	var roof_h := p.size.y * 0.2
	# the cast shadow falls away from the sun, long when the sun is low, and stays in the painting
	var away := -1.0 if sun.x > 0.5 else 1.0
	var length := p.size.y * (0.06 if t == "noon" else 0.4)
	var shadow: Array = [base + Vector2(-w * 0.5, 0), base + Vector2(w * 0.5, 0),
		base + Vector2(w * 0.5 + away * length, p.size.y * 0.07), base + Vector2(-w * 0.5 + away * length, p.size.y * 0.07)]
	for i in shadow.size():
		shadow[i] = Vector2(clampf(shadow[i].x, p.position.x + 2, p.end.x - 2), shadow[i].y)
	ci.draw_colored_polygon(PackedVector2Array(shadow), (col[5] as Color).lerp(col[3], 0.25))
	var top := base + Vector2(0, -body_h - roof_h)
	var left_foot := base + Vector2(-w * 0.5, 0)
	var right_foot := base + Vector2(w * 0.5, 0)
	var left_eave := base + Vector2(-w * 0.55, -body_h)
	var right_eave := base + Vector2(w * 0.55, -body_h)
	ci.draw_colored_polygon(PackedVector2Array([left_foot, left_eave, top, right_eave, right_foot]), col[4])
	# the half away from the sun is in shadow (at noon the light is from above: only under the eaves)
	if t == "noon":
		ci.draw_colored_polygon(PackedVector2Array([left_foot, left_eave + Vector2(0, body_h * 0.25), right_eave + Vector2(0, body_h * 0.25),
			right_foot]), (col[5] as Color).lerp(col[4], 0.55))
	elif away < 0.0:
		ci.draw_colored_polygon(PackedVector2Array([left_foot, left_eave, top, base + Vector2(0, -body_h), base]),
			(col[5] as Color).lerp(col[4], 0.3))
	else:
		ci.draw_colored_polygon(PackedVector2Array([base, base + Vector2(0, -body_h), top, right_eave, right_foot]),
			(col[5] as Color).lerp(col[4], 0.3))
	if t == "winter":
		ci.draw_colored_polygon(PackedVector2Array([top, top + Vector2(-w * 0.22, roof_h * 0.45), top + Vector2(w * 0.22, roof_h * 0.45)]),
			Color.WHITE)
	# painterly dabs of broken colour: sky colours in the sky, the ground's in the field
	for k in 34:
		var x := p.position.x + p.size.x * _rand(k, 3.0 + salt)
		var y := p.position.y + p.size.y * _rand(k, 4.0 + salt)
		var c: Color = (col[1] if y < horizon else col[3]) as Color
		c = c.lerp(col[2] if _rand(k, 5.0) < 0.5 else col[5], 0.3)
		_dab(ci, Vector2(x, y), minf(p.size.x, p.size.y) * 0.05, -0.3 + 0.6 * _rand(k, 6.0), 3.0, Color(c, 0.55))


# --- Brushwork -----------------------------------------------------------------------------------------------------------

static func _draw_brushwork(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var style := str(d.style)
	var horizon := r.position.y + r.size.y * 0.52
	var sun := Vector2(r.get_center().x, horizon - r.size.y * 0.1)
	var sky_top := Color("f2a65a")
	var sky_low := Color("f7d488")
	var sea_top := Color("4f6fa8")
	var sea_low := Color("27406e")
	ci.draw_rect(r, Color("f7e6c4"))
	match style:
		"smooth":
			for k in 40:
				var t := float(k) / 39.0
				ci.draw_rect(Rect2(Vector2(r.position.x, r.position.y + (horizon - r.position.y) * t), Vector2(r.size.x, (horizon - r.position.y) / 39.0 + 1)),
					sky_top.lerp(sky_low, t))
				ci.draw_rect(Rect2(Vector2(r.position.x, horizon + (r.end.y - horizon) * t), Vector2(r.size.x, (r.end.y - horizon) / 39.0 + 1)),
					sea_top.lerp(sea_low, t))
			ci.draw_circle(sun, r.size.y * 0.09, Color("fff1c4"))
			for k in 6:
				var y := horizon + (r.end.y - horizon) * (0.1 + 0.15 * k)
				ci.draw_rect(Rect2(Vector2(sun.x - r.size.x * (0.08 - 0.008 * k), y), Vector2(r.size.x * (0.16 - 0.016 * k), 4)), Color("f7c66b", 0.7))
		"broken":
			var palette_sky := [Color("f08a3c"), Color("f7c66b"), Color("ef9fa8"), Color("fbe3a0")]
			var palette_sea := [Color("3a5d9c"), Color("6a5aa8"), Color("2b4a7e"), Color("5b86c8")]
			var i := 0
			var y := r.position.y + 4.0
			while y < r.end.y:
				var x := r.position.x + 4.0 + fmod(y * 0.37, 9.0)
				while x < r.end.x:
					var near_sun := absf(x - sun.x) < r.size.x * 0.08 and y > horizon
					var pal: Array = palette_sky if y < horizon else palette_sea
					var c: Color = pal[int(_rand(i, 7.0) * pal.size()) % pal.size()]
					if near_sun and _rand(i, 8.0) < 0.6:
						c = Color("f7b54a")
					_dab(ci, Vector2(x, y), 15.0, -0.15 + 0.3 * _rand(i, 9.0), 6.0, c)
					x += 11.0
					i += 1
				y += 7.0
			ci.draw_circle(sun, r.size.y * 0.085, Color("fff1c4"))
			for k in 10:
				_dab(ci, sun + Vector2((_rand(k, 10.0) - 0.5) * r.size.y * 0.14, (_rand(k, 11.0) - 0.5) * r.size.y * 0.14), 10.0, 0.3, 5.0, Color("ffd27a"))
		"dots":
			var i := 0
			var y := r.position.y + 4.0
			while y < r.end.y:
				var x := r.position.x + 4.0 + (4.0 if int((y - r.position.y) / 8.0) % 2 == 1 else 0.0)
				while x < r.end.x:
					var roll := _rand(i, 12.0)
					var c := Color.WHITE
					if Vector2(x, y).distance_to(sun) < r.size.y * 0.09:
						c = Color("fff1c4") if roll < 0.6 else Color("f7d21e")
					elif y < horizon:
						var near := (y - r.position.y) / (horizon - r.position.y)
						c = Color("f7d21e") if roll < 0.3 + 0.35 * near else (Color("f28a1c") if roll < 0.8 else Color("e03a2f"))
					elif absf(x - sun.x) < r.size.x * 0.06 and roll < 0.6:
						c = Color("f7d21e")
					else:
						c = Color("2f6fdc") if roll < 0.55 else (Color("8a3fb8") if roll < 0.8 else Color("1f3a7a"))
					ci.draw_circle(Vector2(x, y), 3.0, c)
					x += 8.0
					i += 1
				y += 8.0


# --- Modern movements ----------------------------------------------------------------------------------------------------

static func _draw_movement(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var a := _fit_box(r, 1.6)
	match str(d.style):
		"realist":
			ci.draw_rect(a, Color("e9dcc4"))
			ci.draw_rect(_sub(a, 0.0, 0.62, 1.0, 1.0), Color("8b5a33"))
			ci.draw_colored_polygon(PackedVector2Array(_pts(a, [Vector2(0.28, 0.66), Vector2(0.72, 0.66), Vector2(0.64, 0.82),
				Vector2(0.36, 0.82)])), Color("dfe6ee"))
			ci.draw_colored_polygon(PackedVector2Array(_pts(a, [Vector2(0.4, 0.83), Vector2(0.86, 0.83), Vector2(0.78, 0.9),
				Vector2(0.42, 0.9)])), Color(0, 0, 0, 0.18))
			for fruit: Array in [[Vector2(0.42, 0.56), Color("d9433b")], [Vector2(0.57, 0.55), Color("f28a1c")], [Vector2(0.5, 0.45), Color("8cc152")]]:
				var c := _at(a, fruit[0].x, fruit[0].y)
				var s := a.size.y * 0.11
				for k in 6:
					ci.draw_circle(c + Vector2(s * 0.06 * k, s * 0.04 * k), s * (1.0 - 0.13 * k), (fruit[1] as Color).darkened(0.3 - 0.07 * k).lightened(0.04 * k))
				ci.draw_circle(c - Vector2(s * 0.35, s * 0.35), s * 0.18, Color(1, 1, 1, 0.7))
		"cubist":
			ci.draw_rect(a, Color("b7a17f"))
			var facets := [[Vector2(0.1, 0.1), Vector2(0.5, 0.05), Vector2(0.45, 0.5), Vector2(0.12, 0.6)],
				[Vector2(0.45, 0.05), Vector2(0.9, 0.12), Vector2(0.85, 0.55), Vector2(0.5, 0.5)],
				[Vector2(0.12, 0.55), Vector2(0.5, 0.48), Vector2(0.55, 0.95), Vector2(0.15, 0.92)],
				[Vector2(0.5, 0.5), Vector2(0.88, 0.5), Vector2(0.9, 0.92), Vector2(0.52, 0.95)],
				[Vector2(0.3, 0.25), Vector2(0.62, 0.3), Vector2(0.58, 0.72), Vector2(0.28, 0.68)]]
			var cols := [Color("8a6a42"), Color("c9b48c"), Color("6b5a44"), Color("a88d62"), Color("d8c7a2")]
			for k in facets.size():
				_poly(ci, _pts(a, facets[k]), cols[k], Color("2a2420"), 2.5)
			ci.draw_circle(_at(a, 0.44, 0.5), a.size.y * 0.09, Color("2a2420"))
			ci.draw_arc(_at(a, 0.62, 0.42), a.size.y * 0.08, 0.0, TAU, 16, Color("2a2420"), 3.0, true)
			for k in 4:
				ci.draw_line(_at(a, 0.3 + 0.02 * k, 0.15), _at(a, 0.42 + 0.02 * k, 0.88), Color("f3ead6"), 1.5, true)
				ci.draw_line(_at(a, 0.58 + 0.02 * k, 0.2), _at(a, 0.66 + 0.02 * k, 0.75), Color("f3ead6"), 1.5, true)
			ci.draw_arc(_at(a, 0.28, 0.72), a.size.y * 0.2, -PI * 0.5, PI * 0.5, 16, Color("2a2420"), 3.0, true)
		"surreal":
			for k in 12:
				ci.draw_rect(Rect2(Vector2(a.position.x, a.position.y + a.size.y * 0.6 * k / 12.0), Vector2(a.size.x, a.size.y * 0.6 / 12.0 + 1)),
					Color("2f5fa8").lerp(Color("f2d49b"), k / 11.0))
			ci.draw_rect(_sub(a, 0.0, 0.6, 1.0, 1.0), Color("c99a5a"))
			ci.draw_rect(_sub(a, 0.08, 0.5, 0.36, 0.7), Color("8a6a42"))
			ci.draw_line(_at(a, 0.3, 0.5), _at(a, 0.42, 0.18), Color("5a4630"), 6.0, true)
			ci.draw_line(_at(a, 0.38, 0.27), _at(a, 0.62, 0.24), Color("5a4630"), 4.0, true)
			var clock := PackedVector2Array(_pts(a, [Vector2(0.44, 0.2), Vector2(0.62, 0.2), Vector2(0.66, 0.3),
				Vector2(0.6, 0.48), Vector2(0.55, 0.6), Vector2(0.52, 0.46), Vector2(0.45, 0.36)]))
			_poly(ci, clock, Color("e8d89a"), Color("6b5320"), 2.5)
			ci.draw_line(_at(a, 0.54, 0.3), _at(a, 0.56, 0.4), INK, 2.0, true)
			ci.draw_line(_at(a, 0.54, 0.3), _at(a, 0.6, 0.28), INK, 2.0, true)
			for k in 6:
				ci.draw_circle(_at(a, 0.47 + 0.03 * k, 0.24 + 0.04 * (k % 3)), 1.8, INK)
			_poly(ci, _pts(a, [Vector2(0.72, 0.72), Vector2(0.92, 0.7), Vector2(0.88, 0.78), Vector2(0.74, 0.8)]), Color("e8d89a"), Color("6b5320"), 2.0)
			ci.draw_colored_polygon(PackedVector2Array(_pts(a, [Vector2(0.36, 0.7), Vector2(0.95, 0.86), Vector2(0.95, 0.92), Vector2(0.3, 0.72)])), Color(0, 0, 0, 0.2))
		"pop":
			var cols := [Color("e03a2f"), Color("f7d21e"), Color("2f6fdc"), Color("e85fb0")]
			var backs := [Color("f7d21e"), Color("2f6fdc"), Color("e85fb0"), Color("3aa845")]
			for k in 4:
				var cell := _sub(a, 0.5 * (k % 2), 0.5 * (k / 2), 0.5 * (k % 2) + 0.5, 0.5 * (k / 2) + 0.5)
				ci.draw_rect(cell, backs[k])
				var x := cell.position.x + 4.0
				while x < cell.end.x:
					var y := cell.position.y + 4.0
					while y < cell.end.y:
						ci.draw_circle(Vector2(x, y), 1.8, (backs[k] as Color).darkened(0.25))
						y += 8.0
					x += 8.0
				var can := _sub(cell, 0.32, 0.18, 0.68, 0.86)
				ci.draw_rect(can, Color("e8e8e8"))
				ci.draw_rect(_sub(can, 0.0, 0.25, 1.0, 0.75), cols[k])
				ci.draw_rect(can, Color.BLACK, false, 3.0)
				var star := can.get_center()
				var s := can.size.x * 0.22
				var pts: Array = []
				for j in 10:
					var ang := -PI * 0.5 + TAU * j / 10.0
					pts.append(star + Vector2(cos(ang), sin(ang)) * (s if j % 2 == 0 else s * 0.45))
				_poly(ci, pts, Color.WHITE, Color.BLACK, 2.0)
				ci.draw_rect(cell, Color.BLACK, false, 3.0)
		"fauve":
			ci.draw_rect(a, Color("c6e84a"))
			_poly(ci, _pts(a, [Vector2(0.0, 0.55), Vector2(0.25, 0.3), Vector2(0.5, 0.5), Vector2(0.75, 0.25), Vector2(1.0, 0.45),
				Vector2(1.0, 1.0), Vector2(0.0, 1.0)]), Color("8a3fb8"), Color("5a2a80"), 3.0)
			_poly(ci, _pts(a, [Vector2(0.0, 0.75), Vector2(0.35, 0.6), Vector2(0.7, 0.72), Vector2(1.0, 0.62), Vector2(1.0, 1.0),
				Vector2(0.0, 1.0)]), Color("f28a1c"), Color("c25a10"), 3.0)
			for tree: Vector2 in [Vector2(0.2, 0.7), Vector2(0.55, 0.66), Vector2(0.8, 0.7)]:
				ci.draw_line(_at(a, tree.x, tree.y), _at(a, tree.x, tree.y - 0.22), Color("e03a2f"), 7.0, true)
				ci.draw_circle(_at(a, tree.x, tree.y - 0.3), a.size.y * 0.12, Color("2f9fdc"))
				ci.draw_circle(_at(a, tree.x + 0.03, tree.y - 0.34), a.size.y * 0.07, Color("e85fb0"))
			ci.draw_circle(_at(a, 0.85, 0.15), a.size.y * 0.08, Color("e03a2f"))
	ci.draw_rect(a, INK, false, 2.0)


# --- Camera obscura ------------------------------------------------------------------------------------------------------

static func _tree(ci: CanvasItem, a: Rect2, base: Vector2, top: float, crown: Vector2, crown_r: float) -> void:
	ci.draw_line(_at(a, base.x, base.y), _at(a, base.x, top), Color("7a4a24"), a.size.y * 0.04, true)
	ci.draw_circle(_at(a, crown.x, crown.y), a.size.y * crown_r, Color("3fa34d"))


static func _draw_obscura(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var a := _diagram_box(d, r)
	ci.draw_rect(_sub(a, 0.0, 0.86, 0.48, 0.9), Color("bfe0a8"))
	_tree(ci, a, Vector2(0.11, 0.86), 0.5, Vector2(0.11, 0.38), 0.16)
	var box := _sub(a, 0.5, 0.18, 0.8, 0.86)
	ci.draw_rect(box, Color("2b3140"))
	ci.draw_rect(_sub(a, 0.77, 0.2, 0.79, 0.84), Color("f2ead8"))
	ci.draw_rect(Rect2(_at(a, 0.495, 0.5), Vector2(a.size.x * 0.012, a.size.y * 0.04)), Color("fff3c4"))
	# rays from the tree's top and foot cross at the pinhole
	var hole := _at(a, 0.5, 0.52)
	for ray: Array in [[Vector2(0.11, 0.22), Color("f2b84a")], [Vector2(0.11, 0.86), Color("f08a3c")]]:
		var from := _at(a, ray[0].x, ray[0].y)
		var dir := (hole - from).normalized()
		var to := hole + dir * (_at(a, 0.775, 0).x - hole.x) / maxf(dir.x, 0.001)
		ci.draw_line(from, to, ray[1], 2.5, true)
		_head(ci, from.lerp(hole, 0.55), dir, 9.0, ray[1])
	# the picture on the back, upside down and smaller
	var flip := func(f: Vector2) -> Vector2: return Vector2(0.765, 0.52 + (0.52 - f.y) * 0.7)
	var cb: Vector2 = flip.call(Vector2(0.11, 0.86))
	var ct: Vector2 = flip.call(Vector2(0.11, 0.5))
	var cc: Vector2 = flip.call(Vector2(0.11, 0.38))
	ci.draw_line(_at(a, cb.x, cb.y), _at(a, ct.x, ct.y), Color("7a4a24"), a.size.y * 0.03, true)
	ci.draw_circle(_at(a, cc.x, cc.y), a.size.y * 0.11, Color("3fa34d"))
	ci.draw_rect(box, INK, false, 2.0)
	_label_parts(ci, font, r, d, _anchors(d, a), fs)


# --- Raster and vector ---------------------------------------------------------------------------------------------------

static func _draw_raster_vector(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var zoom := bool(d.get("zoom", false))
	var raster := str(d.view) == "raster"
	var left := _fit_box(_sub(r, 0.0, 0.0, 0.5 if zoom else 1.0, 0.86), 1.0)
	var c := left.get_center()
	var rad := left.size.y * 0.38
	if raster:
		var n := 14
		var cell := left.size.y / n
		for y in n:
			for x in n:
				var p := left.position + Vector2(x + 0.5, y + 0.5) * cell
				if p.distance_to(c) <= rad:
					ci.draw_rect(Rect2(left.position + Vector2(x, y) * cell, Vector2(cell, cell)), BLUE)
	else:
		ci.draw_circle(c, rad, BLUE)
		for k in 4:
			var ang := PI * 0.5 * k
			var p := c + Vector2(cos(ang), sin(ang)) * rad
			var t := Vector2(-sin(ang), cos(ang)) * rad * 0.55
			ci.draw_line(p - t, p + t, ORANGE, 1.5, true)
			ci.draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color.WHITE)
			ci.draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), INK, false, 1.5)
			ci.draw_circle(p - t, 3.0, ORANGE)
			ci.draw_circle(p + t, 3.0, ORANGE)
	_say(ci, font, Vector2(left.get_center().x, r.end.y - fs * 0.7), "pixels" if raster else "points and curves", fs, INK, false)
	if not zoom:
		return
	var right := _fit_box(_sub(r, 0.5, 0.0, 1.0, 0.86), 1.0)
	var spot := c + Vector2(rad * 0.7, -rad * 0.7)
	ci.draw_arc(spot, left.size.y * 0.12, 0.0, TAU, 20, INK, 2.0, true)
	ci.draw_line(spot + Vector2(left.size.y * 0.12, 0), right.position + Vector2(0, right.size.y * 0.5), GREY, 1.5, true)
	ci.draw_rect(right, Color.WHITE)
	if raster:
		var grid := 14
		var small := left.size.y / grid
		var at := Vector2i(int((spot.x - left.position.x) / small), int((spot.y - left.position.y) / small))
		var n := 5
		var cell := right.size.y / n
		for y in n:
			for x in n:
				var g := Vector2(at.x - 2 + x + 0.5, at.y - 2 + y + 0.5) * small + left.position
				if g.distance_to(c) <= rad:
					ci.draw_rect(Rect2(right.position + Vector2(x, y) * cell, Vector2(cell, cell)).grow(-1), BLUE)
	else:
		var pts := PackedVector2Array([right.position + Vector2(0, right.size.y)])
		for k in 17:
			var ang := PI + PI * 0.5 * k / 16.0
			pts.append(right.position + Vector2(right.size.x, right.size.y) + Vector2(cos(ang), sin(ang)) * right.size.x * 0.9)
		pts.append(right.end)
		ci.draw_colored_polygon(pts, BLUE)
	ci.draw_rect(right, INK, false, 2.0)
	_say(ci, font, Vector2(right.get_center().x, r.end.y - fs * 0.7), "zoomed in", fs, INK, false)


# --- Symbol portrait -----------------------------------------------------------------------------------------------------

static func _draw_portrait(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var syms: Array = d.get("symbols", [])
	var names := bool(d.get("names", false))
	var c := Vector2(r.get_center().x, r.position.y + r.size.y * 0.5)
	var s := r.size.y * 0.3
	ci.draw_set_transform(c, 0.0, Vector2(0.78, 1.0))
	ci.draw_circle(Vector2.ZERO, s * 1.45, Color("f7e8c8"))
	ci.draw_arc(Vector2.ZERO, s * 1.45, 0.0, TAU, 40, Color("b08a5a"), 6.0, true)
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.85, s * 1.4), c + Vector2(-s * 0.6, s * 0.75),
		c + Vector2(s * 0.6, s * 0.75), c + Vector2(s * 0.85, s * 1.4)]), Color("3a7be8"))
	ci.draw_rect(Rect2(c + Vector2(-s * 0.14, s * 0.45), Vector2(s * 0.28, s * 0.35)), SKIN)
	ci.draw_circle(c, s * 0.55, SKIN)
	ci.draw_arc(c, s * 0.56, PI * 1.02, TAU * 0.99, 20, HAIR, s * 0.3, true)
	ci.draw_circle(c + Vector2(-s * 0.2, s * 0.02), s * 0.06, INK)
	ci.draw_circle(c + Vector2(s * 0.2, s * 0.02), s * 0.06, INK)
	ci.draw_arc(c + Vector2(0, s * 0.18), s * 0.2, PI * 0.2, PI * 0.8, 10, INK, 2.0, true)
	for i in syms.size():
		var slot: Vector2 = SYMBOL_SLOTS[i]
		var p := _at(r, slot.x, slot.y)
		var marked := d.has("mark") and str(d.mark) == str(syms[i])
		if marked:
			ci.draw_arc(p, s * 0.45, 0.0, TAU, 24, ORANGE, 3.0, true)
		_symbol(ci, str(syms[i]), p, s * 0.38)
		if names:
			_say(ci, font, p + Vector2(0, s * 0.6), str(syms[i]), fs - 2, INK)


static func _symbol(ci: CanvasItem, what: String, c: Vector2, s: float) -> void:
	match what:
		"book":
			_poly(ci, [c + Vector2(-s, -s * 0.6), c + Vector2(0, -s * 0.4), c + Vector2(0, s * 0.7), c + Vector2(-s, s * 0.5)], Color.WHITE, INK, 2.0)
			_poly(ci, [c + Vector2(s, -s * 0.6), c + Vector2(0, -s * 0.4), c + Vector2(0, s * 0.7), c + Vector2(s, s * 0.5)], Color("fbf3e0"), INK, 2.0)
			for k in 3:
				ci.draw_line(c + Vector2(-s * 0.8, -s * 0.3 + s * 0.25 * k), c + Vector2(-s * 0.15, -s * 0.15 + s * 0.25 * k), GREY, 1.5)
		"ball":
			ci.draw_circle(c, s * 0.9, Color.WHITE)
			ci.draw_arc(c, s * 0.9, 0.0, TAU, 20, INK, 2.0, true)
			var pts: Array = []
			for k in 5:
				var ang := -PI * 0.5 + TAU * k / 5.0
				pts.append(c + Vector2(cos(ang), sin(ang)) * s * 0.32)
			_poly(ci, pts, INK, INK, 1.0)
		"music":
			for k in 2:
				var x := c.x + (k - 0.5) * s * 0.9
				ci.draw_circle(Vector2(x - s * 0.2, c.y + s * 0.5), s * 0.24, INK)
				ci.draw_line(Vector2(x, c.y + s * 0.5), Vector2(x, c.y - s * 0.6), INK, 2.5, true)
			ci.draw_line(Vector2(c.x - s * 0.45, c.y - s * 0.6), Vector2(c.x + s * 0.45, c.y - s * 0.6), INK, s * 0.2, true)
		"brush":
			ci.draw_line(c + Vector2(-s * 0.8, s * 0.8), c + Vector2(s * 0.3, -s * 0.3), WOOD, s * 0.22, true)
			ci.draw_line(c + Vector2(s * 0.3, -s * 0.3), c + Vector2(s * 0.8, -s * 0.8), RED, s * 0.32, true)
			ci.draw_circle(c + Vector2(-s * 0.6, -s * 0.5), s * 0.2, Color("2f6fdc"))
		"plant":
			_poly(ci, [c + Vector2(-s * 0.5, s * 0.2), c + Vector2(s * 0.5, s * 0.2), c + Vector2(s * 0.38, s * 0.9), c + Vector2(-s * 0.38, s * 0.9)], Color("c2703c"), INK, 2.0)
			for ang: float in [-0.9, 0.0, 0.9]:
				var tip := c + Vector2(sin(ang) * s * 0.8, -cos(ang) * s * 0.9) + Vector2(0, s * 0.1)
				ci.draw_line(c + Vector2(0, s * 0.2), tip, GREEN, s * 0.25, true)
		"cat":
			ci.draw_circle(c, s * 0.7, Color("f2a65a"))
			_poly(ci, [c + Vector2(-s * 0.65, -s * 0.2), c + Vector2(-s * 0.55, -s * 0.95), c + Vector2(-s * 0.15, -s * 0.6)], Color("f2a65a"), INK, 1.5)
			_poly(ci, [c + Vector2(s * 0.65, -s * 0.2), c + Vector2(s * 0.55, -s * 0.95), c + Vector2(s * 0.15, -s * 0.6)], Color("f2a65a"), INK, 1.5)
			ci.draw_arc(c, s * 0.7, 0.0, TAU, 20, INK, 1.5, true)
			ci.draw_circle(c + Vector2(-s * 0.25, -s * 0.1), s * 0.08, INK)
			ci.draw_circle(c + Vector2(s * 0.25, -s * 0.1), s * 0.08, INK)
		"rocket":
			_poly(ci, [c + Vector2(0, -s), c + Vector2(s * 0.35, -s * 0.3), c + Vector2(s * 0.35, s * 0.6), c + Vector2(-s * 0.35, s * 0.6),
				c + Vector2(-s * 0.35, -s * 0.3)], Color("e8edf5"), INK, 2.0)
			ci.draw_circle(c + Vector2(0, -s * 0.2), s * 0.15, BLUE)
			_poly(ci, [c + Vector2(-s * 0.35, s * 0.2), c + Vector2(-s * 0.7, s * 0.8), c + Vector2(-s * 0.35, s * 0.6)], RED, INK, 1.5)
			_poly(ci, [c + Vector2(s * 0.35, s * 0.2), c + Vector2(s * 0.7, s * 0.8), c + Vector2(s * 0.35, s * 0.6)], RED, INK, 1.5)
			ci.draw_circle(c + Vector2(0, s * 0.85), s * 0.2, ORANGE)
		"home":
			_poly(ci, [c + Vector2(-s * 0.7, -s * 0.05), c + Vector2(0, -s * 0.8), c + Vector2(s * 0.7, -s * 0.05)], RED, INK, 2.0)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.05), Vector2(s * 1.1, s * 0.85)), Color("f7e1b0"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.05), Vector2(s * 1.1, s * 0.85)), INK, false, 2.0)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.15, s * 0.35), Vector2(s * 0.3, s * 0.45)), WOOD)


# --- Grid enlargement (a mural) ------------------------------------------------------------------------------------------

static func _draw_enlarge(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var key: Dictionary = d.key
	var fs := _fs(r, 13.0)
	var nr := rows.size()
	var nc := str(rows[0]).length()
	var sizes: Array = d.get("sizes", [])
	var area := Rect2(r.position, r.size - Vector2(0, fs * 1.9 if not sizes.is_empty() else 0.0))
	var small := _fit_box(_sub(area, 0.02, 0.2, 0.3, 0.8), float(nc) / nr)
	var big := _fit_box(_sub(area, 0.38, 0.0, 1.0, 1.0), float(nc) / nr)
	ci.draw_rect(big.grow(10), Color("c9a27a"))
	for y in int(big.grow(10).size.y / 12.0):
		var by := big.grow(10).position.y + y * 12.0
		ci.draw_line(Vector2(big.grow(10).position.x, by), Vector2(big.grow(10).end.x, by), Color("b08a5a"), 1.0)
	var done := _int(d, "done", nr * nc)
	for grid: Array in [[small, nr * nc], [big, done]]:
		var box: Rect2 = grid[0]
		var cell := box.size.x / nc
		var k := 0
		for y in nr:
			for x in nc:
				var ch := str(rows[y])[x]
				var rect := Rect2(box.position + Vector2(x, y) * cell, Vector2(cell, cell))
				if k < int(grid[1]):
					ci.draw_rect(rect, SchoolPictureArts.COLOURS[str(key[ch])])
				elif box == big:
					ci.draw_rect(rect, Color("e9dcc4"))
				k += 1
		for x in nc + 1:
			ci.draw_line(box.position + Vector2(x * cell, 0), box.position + Vector2(x * cell, box.size.y), INK, 1.5)
		for y in nr + 1:
			ci.draw_line(box.position + Vector2(0, y * cell), box.position + Vector2(box.size.x, y * cell), INK, 1.5)
	_arrow(ci, Vector2(small.end.x + 6, small.get_center().y), Vector2(big.position.x - 14, small.get_center().y), ORANGE, 3.0)
	if not sizes.is_empty():
		_say(ci, font, Vector2(small.get_center().x, r.end.y - fs * 0.7), str(sizes[0]), fs - 1, INK, false)
		_say(ci, font, Vector2(big.get_center().x, r.end.y - fs * 0.7), str(sizes[1]), fs - 1, INK, false)


# --- Designed objects ----------------------------------------------------------------------------------------------------

static func _draw_object(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var a := _diagram_box(d, r)
	match str(d.what):
		"lamp":
			ci.draw_rect(_sub(a, 0.36, 0.86, 0.64, 0.94), Color("3a4252"))
			ci.draw_line(_at(a, 0.5, 0.86), _at(a, 0.42, 0.45), Color("d9433b"), a.size.y * 0.035, true)
			var springs := PackedVector2Array()
			for k in 15:
				var t := float(k) / 14.0
				var p := _at(a, 0.5, 0.86).lerp(_at(a, 0.42, 0.45), t) + Vector2(a.size.x * 0.035, 0)
				springs.append(p + Vector2(a.size.y * 0.018 * (1 if k % 2 == 0 else -1), 0))
			ci.draw_polyline(springs, Color("6a7486"), 2.0, true)
			ci.draw_line(_at(a, 0.42, 0.45), _at(a, 0.62, 0.22), Color("d9433b"), a.size.y * 0.035, true)
			ci.draw_circle(_at(a, 0.42, 0.45), a.size.y * 0.035, INK)
			ci.draw_circle(_at(a, 0.62, 0.22), a.size.y * 0.03, INK)
			_poly(ci, _pts(a, [Vector2(0.62, 0.2), Vector2(0.68, 0.22), Vector2(0.76, 0.46), Vector2(0.62, 0.5)]), Color("d9433b"), INK, 2.0)
			ci.draw_colored_polygon(PackedVector2Array(_pts(a, [Vector2(0.62, 0.5), Vector2(0.76, 0.46), Vector2(0.9, 0.86), Vector2(0.62, 0.86)])),
				Color(1.0, 0.93, 0.6, 0.35))
		"chair":
			var steel := Color("6a7486")
			ci.draw_line(_at(a, 0.6, 0.92), _at(a, 0.58, 0.12), steel, a.size.y * 0.03, true)
			_poly(ci, _pts(a, [Vector2(0.56, 0.12), Vector2(0.62, 0.13), Vector2(0.61, 0.4), Vector2(0.56, 0.38)]), Color("3a7be8"), INK, 2.0)
			_poly(ci, _pts(a, [Vector2(0.38, 0.48), Vector2(0.6, 0.48), Vector2(0.6, 0.53), Vector2(0.38, 0.53)]), Color("3a7be8"), INK, 2.0)
			ci.draw_line(_at(a, 0.42, 0.53), _at(a, 0.42, 0.92), steel, a.size.y * 0.03, true)
			ci.draw_line(_at(a, 0.42, 0.74), _at(a, 0.59, 0.74), steel, a.size.y * 0.02, true)
			ci.draw_line(_at(a, 0.3, 0.93), _at(a, 0.7, 0.93), GREY, 2.0, true)
		"dial_phone":
			_poly(ci, _pts(a, [Vector2(0.33, 0.5), Vector2(0.67, 0.5), Vector2(0.72, 0.86), Vector2(0.28, 0.86)]), Color("2b2b2b"), INK, 2.0)
			ci.draw_circle(_at(a, 0.5, 0.68), a.size.y * 0.12, Color("e8e8e8"))
			for k in 10:
				var ang := PI * 0.75 + TAU * 0.8 * k / 10.0
				ci.draw_circle(_at(a, 0.5, 0.68) + Vector2(cos(ang), sin(ang)) * a.size.y * 0.085, a.size.y * 0.018, Color("2b2b2b"))
			ci.draw_line(_at(a, 0.31, 0.42), _at(a, 0.69, 0.42), Color("2b2b2b"), a.size.y * 0.06, true)
			ci.draw_circle(_at(a, 0.31, 0.46), a.size.y * 0.065, Color("2b2b2b"))
			ci.draw_circle(_at(a, 0.69, 0.46), a.size.y * 0.065, Color("2b2b2b"))
			var cord := PackedVector2Array()
			for k in 40:
				var t := float(k) / 39.0
				var p := _bez(_at(a, 0.29, 0.8), _at(a, 0.08, 0.72), _at(a, 0.27, 0.48), t)
				cord.append(p + Vector2(cos(t * 60.0), sin(t * 60.0)) * a.size.y * 0.015)
			ci.draw_polyline(cord, Color("2b2b2b"), 2.0, true)
		"smartphone":
			_box(ci, _sub(a, 0.4, 0.06, 0.6, 0.95), Color("2b3140"), INK, 14, 2)
			ci.draw_rect(_sub(a, 0.413, 0.15, 0.587, 0.86), Color("bfe0f7"))
			for k in 3:
				ci.draw_rect(_sub(a, 0.43 + 0.05 * k, 0.2, 0.47 + 0.05 * k, 0.28), [GREEN, ORANGE, BLUE][k])
			ci.draw_circle(_at(a, 0.5, 0.115), a.size.y * 0.018, Color("0d0f14"))
			ci.draw_rect(_sub(a, 0.6, 0.27, 0.607, 0.37), Color("6a7486"))
			for k in 4:
				ci.draw_circle(_at(a, 0.44 + 0.01 * k, 0.905), a.size.y * 0.007, Color("9aa1ad"))
			ci.draw_circle(_at(a, 0.545, 0.905), a.size.y * 0.009, Color("9aa1ad"))
	_label_parts(ci, font, r, d, _anchors(d, a), fs)


# --- Animation frames ----------------------------------------------------------------------------------------------------

static func _draw_frames(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var n := int(d.count)
	var ease := bool(d.get("ease", false))
	var squash := bool(d.get("squash", false))
	var mark := _int(d, "mark", -1)
	if str(d.get("view", "onion")) == "strip":
		var per := mini(n, 6)
		var rows := (n + per - 1) / per
		var w := r.size.x / per
		var h := r.size.y / rows
		for i in n:
			var cell := Rect2(r.position + Vector2((i % per) * w, (i / per) * h), Vector2(w, h)).grow(-3)
			ci.draw_rect(cell, Color.WHITE)
			ci.draw_line(Vector2(cell.position.x, cell.end.y - cell.size.y * 0.1), Vector2(cell.end.x, cell.end.y - cell.size.y * 0.1), GREY, 2.0)
			var f := ball_at(i, n, ease)
			var p := Vector2(cell.get_center().x, cell.position.y + cell.size.y * (0.1 + 0.71 * (f.y - 0.16) / 0.7))
			_ball(ci, p, cell.size.y * 0.09, _ball_scale(i, n, ease, squash), 1.0)
			ci.draw_rect(cell, ORANGE if i == mark else INK, false, 3.0 if i == mark else 1.5)
		return
	ci.draw_rect(r, Color.WHITE)
	var ground := r.position.y + r.size.y * 0.92
	ci.draw_line(Vector2(r.position.x, ground), Vector2(r.end.x, ground), GREY, 3.0)
	var rad := r.size.y * 0.06
	for i in n:
		var f := ball_at(i, n, ease)
		var p := r.position + Vector2(r.size.x * f.x, r.size.y * f.y)
		var alpha := 0.35 + 0.65 * float(i + 1) / n
		_ball(ci, p, rad, _ball_scale(i, n, ease, squash), alpha)
		if i == mark:
			ci.draw_arc(p, rad * 1.6, 0.0, TAU, 20, ORANGE, 3.0, true)


## A ball's stretch: squashed flat on the ground, stretched tall when moving fast (with squash), round otherwise.
static func _ball_scale(i: int, n: int, ease: bool, squash: bool) -> Vector2:
	if not squash:
		return Vector2.ONE
	var f := ball_at(i, n, ease)
	if f.y > 0.84:
		return Vector2(1.35, 0.7)
	var speed := (ball_at(mini(i + 1, n - 1), n, ease) - ball_at(maxi(i - 1, 0), n, ease)).length()
	return Vector2(1.0 - minf(speed, 0.4) * 0.4, 1.0 + minf(speed, 0.4) * 0.6)


static func _ball(ci: CanvasItem, p: Vector2, rad: float, scale: Vector2, alpha: float) -> void:
	ci.draw_set_transform(p, 0.0, scale)
	ci.draw_circle(Vector2.ZERO, rad, Color(0.94, 0.33, 0.24, alpha))
	ci.draw_arc(Vector2.ZERO, rad, 0.0, TAU, 20, Color(0.12, 0.16, 0.29, alpha), 2.0, true)
	ci.draw_circle(Vector2(-rad * 0.35, -rad * 0.35), rad * 0.22, Color(1, 1, 1, alpha * 0.8))
	ci.draw_set_transform(Vector2.ZERO)


# --- Mobile --------------------------------------------------------------------------------------------------------------

static func _draw_mobile(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var numbers := bool(d.get("numbers", true))
	var hide: Array = d.get("hide", [])
	var pivot := Vector2(r.get_center().x, r.position.y + r.size.y * 0.28)
	ci.draw_line(Vector2(pivot.x, r.position.y), pivot, INK, 2.0, true)
	var t := turning(d)
	var tilt := 0.0 if bool(d.get("still", false)) else clampf(-float(t) * 0.02, -0.18, 0.18)
	var unit := r.size.x * 0.085
	var dir := Vector2(cos(tilt), sin(tilt))
	ci.draw_line(pivot - dir * unit * 5.3, pivot + dir * unit * 5.3, WOOD, 6.0, true)
	ci.draw_circle(pivot, 5.0, INK)
	for k in range(1, 6):
		for s: float in [-1.0, 1.0]:
			var p := pivot + dir * unit * k * s
			ci.draw_line(p + Vector2(0, -5), p + Vector2(0, 5), Color("5a3a1c"), 2.0, true)
			if numbers:
				_say(ci, font, p + Vector2(0, -fs * 0.9), str(k), fs - 3, GREY, false)
	var shapes := [Color("e03a2f"), Color("2f6fdc"), Color("f7d21e"), Color("3aa845")]
	var i := 0
	for side: String in ["left", "right"]:
		var hang: Array = d[side]
		for k in hang.size():
			var w := int(hang[k][0])
			var dist := int(hang[k][1])
			var p := pivot + dir * unit * dist * (-1.0 if side == "left" else 1.0)
			var drop := r.size.y * (0.22 + 0.08 * (k % 2))
			ci.draw_line(p, p + Vector2(0, drop), INK, 1.5, true)
			var rad := r.size.y * (0.045 + 0.008 * w)
			var c := p + Vector2(0, drop + rad)
			ci.draw_circle(c, rad, shapes[i % 4])
			ci.draw_arc(c, rad, 0.0, TAU, 20, INK, 2.0, true)
			var hidden := hide.size() == 2 and str(hide[0]) == side and int(hide[1]) == k
			if numbers or hidden:
				_say(ci, font, c, "?" if hidden else str(w), fs, ORANGE if hidden else INK)
			i += 1


# --- Gallery plan --------------------------------------------------------------------------------------------------------

static func _draw_plan(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var room := _fit_box(r.grow(-fs * 1.2), 1.5)
	ci.draw_rect(room, Color("f3ead8"))
	ci.draw_rect(room, INK, false, 5.0)
	var door := str(d.door)
	var gap: Array = []
	if door == "bottom":
		gap = [Vector2(room.position.x + room.size.x * 0.1, room.end.y), Vector2(room.position.x + room.size.x * 0.24, room.end.y)]
	else:
		gap = [Vector2(room.position.x, room.position.y + room.size.y * 0.66), Vector2(room.position.x, room.position.y + room.size.y * 0.86)]
	ci.draw_line(gap[0], gap[1], Color("f3ead8"), 7.0)
	var door_at: Vector2 = (gap[0] + gap[1]) * 0.5
	_say(ci, font, door_at + (Vector2(0, fs * 0.9) if door == "bottom" else Vector2(-fs * 1.6, 0)), "door", fs - 2, INK)
	var works: Array = d.works
	var spots: Array = []
	for wk: Array in works:
		spots.append(_at(room, float(wk[1]), float(wk[2])))
	var path: Array = d.get("path", [])
	var from := door_at
	for idx: Variant in path:
		var to: Vector2 = spots[int(idx)]
		_dashed(ci, from, to, GREEN, 2.5, 6.0)
		_head(ci, to - (to - from).normalized() * fs * 1.3, (to - from).normalized(), 10.0, GREEN)
		from = to
	for i in works.size():
		var p: Vector2 = spots[i]
		var marked := _int(d, "mark", -1) == i
		var s := fs * 1.1
		_box(ci, Rect2(p - Vector2(s, s), Vector2(s, s) * 2.0), SOFT if marked else Color("dbe8ff"), ORANGE if marked else INK, 4, 2)
		_say(ci, font, p + Vector2(0, s + fs * 0.8), str(works[i][0]), fs - 2, ORANGE if marked else INK)
		_say(ci, font, p, str(i + 1), fs - 1, INK, false)
	var size: Array = d.get("size", [])
	if size.size() == 2:
		_say(ci, font, Vector2(room.get_center().x, room.position.y - fs * 0.7), str(size[0]), fs - 1, INK, false)
		_say_from(ci, font, Vector2(room.end.x + 6, room.get_center().y), str(size[1]), fs - 1, INK, false, false)


# --- Wall label ----------------------------------------------------------------------------------------------------------

static func _draw_wall_label(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 12.0)
	var lines: Array = d.get("lines", [])
	var card := _fit_box(r, 1.9)
	ci.draw_rect(Rect2(card.position + Vector2(4, 4), card.size), Color(0, 0, 0, 0.12))
	_box(ci, card, Color.WHITE, Color("c9ced8"), 3, 2)
	var x := card.position.x + card.size.x * 0.07
	var room := card.size.x * 0.86
	var y := card.position.y + card.size.y * 0.15
	var rows: Array = [[str(d.title), fs + 3, INK], [str(d.artist), fs, INK], [str(d.date), fs - 1, GREY],
		[str(d.medium), fs - 1, GREY]]
	if d.has("size"):
		rows.append([str(d.size), fs - 1, GREY])
	for line: Variant in lines:
		rows.append([str(line), fs - 2, INK])
	var step := (card.size.y * 0.78) / rows.size()
	for row: Array in rows:
		_say_from(ci, font, Vector2(x, y), str(row[0]), _fit(font, str(row[0]), int(row[1]), room), row[2], false, false)
		y += step


# --- Jazz band -----------------------------------------------------------------------------------------------------------

static func _draw_band(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var a := _diagram_box(d, r)
	ci.draw_rect(_sub(a, 0.0, 0.0, 1.0, 1.0), Color("3a2f45"))
	ci.draw_rect(_sub(a, 0.0, 0.58, 1.0, 1.0), Color("8b5a33"))
	var s := a.size.y
	var brass := Color("e3b23c")
	# piano: a grand piano from the side
	var pc := _at(a, 0.17, 0.4)
	_poly(ci, [pc + Vector2(-s * 0.25, -s * 0.05), pc + Vector2(s * 0.2, -s * 0.05), pc + Vector2(s * 0.28, s * 0.05),
		pc + Vector2(-s * 0.25, s * 0.05)], Color("161616"), Color.WHITE, 1.0)
	ci.draw_line(pc + Vector2(-s * 0.2, s * 0.05), pc + Vector2(-s * 0.2, s * 0.22), Color("161616"), 4.0)
	ci.draw_line(pc + Vector2(s * 0.2, s * 0.05), pc + Vector2(s * 0.2, s * 0.22), Color("161616"), 4.0)
	ci.draw_line(pc + Vector2(-s * 0.25, -s * 0.05), pc + Vector2(s * 0.05, -s * 0.28), Color("161616"), 3.0, true)
	for k in 7:
		ci.draw_rect(Rect2(pc + Vector2(-s * 0.26 + k * s * 0.025, s * 0.0), Vector2(s * 0.02, s * 0.05)), Color.WHITE)
	# double bass: a big upright body and neck
	var bc := _at(a, 0.5, 0.36)
	ci.draw_set_transform(bc + Vector2(0, s * 0.04), 0.0, Vector2(0.65, 1.0))
	ci.draw_circle(Vector2(0, s * 0.05), s * 0.1, Color("9a5a2a"))
	ci.draw_circle(Vector2(0, -s * 0.08), s * 0.075, Color("9a5a2a"))
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_line(bc + Vector2(0, -s * 0.04), bc + Vector2(0, -s * 0.3), Color("3a2414"), 4.0, true)
	ci.draw_line(bc + Vector2(0, s * 0.18), bc + Vector2(0, s * 0.22), GREY, 2.0, true)
	# drums: a bass drum, a snare and two cymbals
	var dc := _at(a, 0.83, 0.42)
	ci.draw_circle(dc + Vector2(0, s * 0.04), s * 0.11, Color("f2f2f2"))
	ci.draw_arc(dc + Vector2(0, s * 0.04), s * 0.11, 0.0, TAU, 20, RED, 4.0, true)
	ci.draw_rect(Rect2(dc + Vector2(-s * 0.24, -s * 0.06), Vector2(s * 0.12, s * 0.06)), Color("d9d9d9"))
	ci.draw_line(dc + Vector2(-s * 0.18, 0.0), dc + Vector2(-s * 0.18, s * 0.15), GREY, 2.0)
	for cx: float in [-0.2, 0.2]:
		ci.draw_line(dc + Vector2(cx * s, -s * 0.18), dc + Vector2(cx * s, s * 0.15), GREY, 2.0)
		ci.draw_line(dc + Vector2(cx * s - s * 0.08, -s * 0.19), dc + Vector2(cx * s + s * 0.08, -s * 0.17), brass, 4.0, true)
	# trumpet: a straight horn with valves and a bell
	var tc := _at(a, 0.29, 0.76)
	ci.draw_line(tc + Vector2(-s * 0.16, 0), tc + Vector2(s * 0.1, 0), brass, 5.0, true)
	_poly(ci, [tc + Vector2(s * 0.1, -s * 0.02), tc + Vector2(s * 0.17, -s * 0.07), tc + Vector2(s * 0.17, s * 0.07),
		tc + Vector2(s * 0.1, s * 0.02)], brass, Color("9a7a20"), 1.5)
	for k in 3:
		ci.draw_line(tc + Vector2(-s * 0.04 + k * s * 0.035, -s * 0.06), tc + Vector2(-s * 0.04 + k * s * 0.035, 0), Color("9a7a20"), 3.0)
	# saxophone: a J with the bell turned up
	var sc := _at(a, 0.5, 0.76)
	var sax := PackedVector2Array()
	for k in 13:
		var t := float(k) / 12.0
		sax.append(_bez(sc + Vector2(-s * 0.03, -s * 0.11), sc + Vector2(-s * 0.05, s * 0.14), sc + Vector2(s * 0.07, s * 0.02), t))
	ci.draw_polyline(sax, brass, 7.0, true)
	ci.draw_circle(sc + Vector2(s * 0.07, 0.0), s * 0.035, brass)
	# trombone: a long slide
	var mc := _at(a, 0.71, 0.76)
	ci.draw_line(mc + Vector2(-s * 0.2, -s * 0.02), mc + Vector2(s * 0.1, -s * 0.02), brass, 3.0, true)
	ci.draw_line(mc + Vector2(-s * 0.2, s * 0.03), mc + Vector2(s * 0.1, s * 0.03), brass, 3.0, true)
	ci.draw_line(mc + Vector2(-s * 0.2, -s * 0.02), mc + Vector2(-s * 0.2, s * 0.03), brass, 3.0, true)
	_poly(ci, [mc + Vector2(s * 0.1, -s * 0.04), mc + Vector2(s * 0.19, -s * 0.09), mc + Vector2(s * 0.19, s * 0.05),
		mc + Vector2(s * 0.1, 0.0)], brass, Color("9a7a20"), 1.5)
	_label_parts(ci, font, r, d, _anchors(d, a), fs)


# --- Instrument ranges ---------------------------------------------------------------------------------------------------

## A note's place along the keyboard, in white keys from C1.
static func _key_x(note_pitch: int) -> float:
	var oct := note_pitch / 12
	var s := note_pitch % 12
	var whites := [0, 0.5, 1, 1.5, 2, 3, 3.5, 4, 4.5, 5, 5.5, 6]
	return float(oct - 1) * 7.0 + float(whites[s]) + 0.5


static func _draw_ranges(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var names: Array = d.instruments
	var label_w := fs * 6.4
	var kb := Rect2(Vector2(r.position.x + label_w, r.end.y - r.size.y * 0.2), Vector2(r.size.x - label_w, r.size.y * 0.16))
	var keys := 7 * 7 + 1   # C1 to C8
	var kw := kb.size.x / keys
	for k in keys:
		ci.draw_rect(Rect2(kb.position + Vector2(k * kw, 0), Vector2(kw, kb.size.y)), Color.WHITE)
		ci.draw_rect(Rect2(kb.position + Vector2(k * kw, 0), Vector2(kw, kb.size.y)), GREY, false, 1.0)
		if k % 7 in [0, 1, 3, 4, 5] and k < keys - 1:
			ci.draw_rect(Rect2(kb.position + Vector2(k * kw + kw * 0.65, 0), Vector2(kw * 0.7, kb.size.y * 0.6)), Color("1d1d1d"))
		if k % 7 == 0:
			_say(ci, font, Vector2(kb.position.x + k * kw + kw * 0.5, kb.end.y + fs * 0.55), "C%d" % (k / 7 + 1), fs - 4, GREY, false)
	var top := r.position.y + (fs * 1.6 if d.has("note") else 0.0)
	var rh := (kb.position.y - top - 4.0) / names.size()
	for i in names.size():
		var name := str(names[i])
		var rg := range_of(name)
		var y := top + rh * (i + 0.5)
		var marked := d.has("mark") and str(d.mark) == name
		var colour := ORANGE if marked else Color("6a9fe8")
		var x0 := kb.position.x + _key_x(rg[0]) * kw
		var x1 := kb.position.x + _key_x(rg[1]) * kw
		_box(ci, Rect2(Vector2(x0, y - rh * 0.3), Vector2(maxf(x1 - x0, 4.0), rh * 0.6)), colour, INK, 5, 1)
		_say_from(ci, font, Vector2(r.position.x, y), name, _fit(font, name, fs - 1, label_w - 6), ORANGE if marked else INK, false, false)
		if bool(d.get("names", false)):
			var lo := str(RANGES[name][0])
			var hi := str(RANGES[name][1])
			_say_from(ci, font, Vector2(x0 - 3, y), lo, fs - 3, INK, true)
			_say_from(ci, font, Vector2(x1 + 3, y), hi, fs - 3, INK)
	if d.has("note"):
		var x := kb.position.x + _key_x(pitch_of(str(d.note))) * kw
		_dashed(ci, Vector2(x, r.position.y + fs * 1.2), Vector2(x, kb.end.y), RED, 2.0)
		_say(ci, font, Vector2(x, r.position.y + fs * 0.55), str(d.note), fs, RED)


# --- Opera house ---------------------------------------------------------------------------------------------------------

static func _draw_opera(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 13.0)
	var a := _diagram_box(d, r)
	ci.draw_rect(a, Color("3a2030"))
	# the audience's seats rising to the back (left)
	for k in 5:
		var x := 0.04 + 0.06 * k
		var y := 0.84 - 0.08 * (4 - k)
		ci.draw_rect(_sub(a, x, y, x + 0.06, 0.95), Color("6b2a3a"))
		ci.draw_circle(_at(a, x + 0.03, y - 0.04), a.size.y * 0.03, Color("e0ac7e"))
	ci.draw_rect(_sub(a, 0.0, 0.95, 0.36, 1.0), Color("6b2a3a"))
	# the orchestra pit, below the stage's front
	ci.draw_rect(_sub(a, 0.36, 0.72, 0.56, 1.0), Color("231520"))
	for k in 4:
		ci.draw_circle(_at(a, 0.42 + 0.035 * k, 0.86), a.size.y * 0.025, Color("e0ac7e"))
		ci.draw_line(_at(a, 0.42 + 0.035 * k, 0.88), _at(a, 0.43 + 0.035 * k, 0.95), Color("c9a27a"), 2.0)
	# the conductor, standing at the pit's audience end, facing the stage
	ci.draw_circle(_at(a, 0.385, 0.6), a.size.y * 0.035, Color("e0ac7e"))
	ci.draw_line(_at(a, 0.385, 0.64), _at(a, 0.385, 0.8), Color("111111"), 6.0)
	ci.draw_line(_at(a, 0.385, 0.67), _at(a, 0.43, 0.6), Color("f2f2f2"), 1.5, true)
	# the stage, its curtain and scenery, with two singers
	ci.draw_rect(_sub(a, 0.56, 0.68, 1.0, 1.0), Color("8b5a33"))
	ci.draw_rect(_sub(a, 0.62, 0.16, 0.98, 0.68), Color("2f5f8a"))
	ci.draw_circle(_at(a, 0.9, 0.3), a.size.y * 0.06, Color("f7e6a0"))
	_poly(ci, _pts(a, [Vector2(0.62, 0.68), Vector2(0.72, 0.42), Vector2(0.82, 0.68)]), Color("4a7a3a"), INK, 0.0)
	_poly(ci, _pts(a, [Vector2(0.56, 0.16), Vector2(0.62, 0.16), Vector2(0.6, 0.68), Vector2(0.56, 0.68)]), Color("b8263a"), INK, 0.0)
	ci.draw_rect(_sub(a, 0.56, 0.12, 1.0, 0.16), Color("b8263a"))
	for sx: float in [0.76, 0.88]:
		ci.draw_circle(_at(a, sx, 0.47), a.size.y * 0.04, Color("e0ac7e"))
		_poly(ci, _pts(a, [Vector2(sx - 0.03, 0.66), Vector2(sx, 0.51), Vector2(sx + 0.03, 0.66)]), Color("f2c12e") if sx < 0.8 else Color("9b59b6"), INK, 1.0)
	# the surtitles above the stage
	ci.draw_rect(_sub(a, 0.62, 0.03, 0.96, 0.11), Color("0d0d0d"))
	for k in 2:
		ci.draw_line(_at(a, 0.66, 0.055 + 0.03 * k), _at(a, 0.92 - 0.06 * k, 0.055 + 0.03 * k), Color("f2f2f2"), 2.0)
	_label_parts(ci, font, r, d, _anchors(d, a), fs)


# --- Swing -------------------------------------------------------------------------------------------------------------

static func _draw_swing(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var beats := int(d.beats)
	var fs := _fs(r, 11.0)
	var name_w := r.size.x * 0.2
	var count_h := fs * 1.6
	var area := Rect2(Vector2(r.position.x + name_w, r.position.y + count_h), Vector2(r.size.x - name_w, r.size.y - count_h))
	var bw := area.size.x / beats
	var rh := minf(area.size.y / rows.size(), bw * 0.7)
	var top := area.position.y + (area.size.y - rh * rows.size()) * 0.5
	for b in beats:
		_say(ci, font, Vector2(area.position.x + bw * (b + 0.5), top - fs * 0.8), str(b + 1), fs, INK, false)
	for i in rows.size():
		var swung := str(rows[i]) == "swing"
		var y := top + rh * i
		var marked := _int(d, "mark", -1) == i
		_say_from(ci, font, Vector2(r.position.x, y + rh * 0.5), str(rows[i]), _fit(font, str(rows[i]), fs, name_w - 8),
			ORANGE if marked else INK, false, false)
		for b in beats:
			var x0 := area.position.x + bw * b
			var split := bw * (2.0 / 3.0 if swung else 0.5)
			var long_box := Rect2(Vector2(x0 + 3, y + rh * 0.15), Vector2(split - 6, rh * 0.7))
			var short_box := Rect2(Vector2(x0 + split + 3, y + rh * 0.15), Vector2(bw - split - 6, rh * 0.7))
			_box(ci, long_box, Color("e8564b") if swung else BLUE, INK, 6, 1)
			_box(ci, short_box, Color("f2a65a") if swung else Color("7fb0f0"), INK, 6, 1)
		if marked:
			ci.draw_rect(Rect2(Vector2(area.position.x, y), Vector2(area.size.x, rh)), ORANGE, false, 3.0)
	for b in beats + 1:
		var x := area.position.x + bw * b
		ci.draw_line(Vector2(x, top - 2), Vector2(x, top + rh * rows.size() + 2), INK, 2.0)
