class_name SchoolPictureG6Arts
extends RefCounted
## Owner #70 and #73, grade 6 computing, art and music (research §6.6): the picture kinds they add, drawn from data onto
## a SchoolPicture's card (it calls `problem` and `draw` for these kinds; UI draw calls only, no new art; the font has
## no music signs or arrows, so they are drawn). Kinds and fields:
## Computing
## - bit_cards {bits: "10110" (1-8 of 0 and 1), values? (true: each card's place value over it: 16, 8, 4, 2, 1), dots?
##   (each face-up card's dots; true up to 5 cards), total? (the number the cards make, under them)}: binary cards: a 1
##   is a card face up, a 0 a card face down (`bits_value`).
## - rgb_mix {r, g, b (0-255 each), view? ("bars": three bars and the colour they make; "lights": three torches' circles
##   of red, green and blue light, where they overlap the light adds up)}: a colour as three numbers of light.
## - logic_gate {gate: "AND" | "OR" | "NOT", inputs: [0 or 1] (two, or one for NOT), then? ("NOT": the output goes on
##   through a NOT gate), out? (true: the output shown; false: "?"), names? [text (6)] (the inputs' names)}: a logic gate
##   with its inputs lit (1) or not (0) (`gate_out`).
## - computer_parts {labels? (the parts named), mark? (a part of PARTS, orange), hide? (a part named "?")}: inside a
##   computer from the side: the processor, the memory, the storage, the power supply and the ports on a main board
##   (`part_at` says where each is, for label pins).
## - phish_mail {from (36), subject (36), lines: [text (44)] (1-4), link? (36, blue and underlined), button? (18), mark?
##   ("from", "subject", "link", "button" or a line's index: an orange ring)}: an email, to spot a trick.
## - privacy_panel {title? (22), rows: [[setting (22), CHOICES]] (1-5), mark? (a row's index)}: a game's privacy
##   settings: who can see or do each thing.
## - ai_examples {examples: [[SHAPES, a colour of SchoolPictureArts, label (10)]] (2-8, two labels), new? ([shape,
##   colour]: the one to guess, with "?")}: a computer's training examples in two groups, and a new one to sort.
## Art
## - art_principle {show: PRINCIPLES}: a small design that shows one principle (symmetry, asymmetry, radial balance,
##   contrast, emphasis, rhythm, unity, variety, movement, pattern).
## - illuminated {letter: "A"-"Z", text? (true: the page's lines of writing beside it)}: a medieval illuminated letter:
##   the capital in red on blue and gold, with vines.
## - star_pattern {points: 6 | 8 | 10 | 12, stage? (1: the circle and its points; 2: the lines joining them; 3: the
##   finished star, the default), tiled? (stars side by side)}: an Islamic geometric star, drawn with a compass and ruler.
## - ink_landscape {labels?, mark? (a part of INK_PARTS, orange)}: a Chinese landscape painting on a hanging scroll: far
##   mountains pale, near ones dark, mist, water, a tiny traveller and a poem with its seal (`part_at`).
## - tessellation {shape: TILES, colours? [2-3 colours of SchoolPictureArts]}: tiles that fit with no gaps (triangles,
##   squares, hexagons, bricks, rhombuses, octagons with squares), or leave gaps (pentagons, circles).
## - rotation_motif {order (2-12), motif: MOTIFS, mark? (the first copy orange), centre? (the centre dot)}: a motif turned
##   round a centre `order` times: rotational symmetry of that order, 360° ÷ order a turn.
## - two_point {eye: "above" | "level" | "below" (the box below, across or above the horizon), lines? (the lines to the
##   vanishing points), labels?, mark? (a part of TWO_POINT_PARTS, orange)}: a box in two-point perspective (`part_at`).
## - feeling_art {feeling: FEELINGS, body? (a whole figure in its pose), colour? (a background that fits the feeling)}:
##   a feeling shown by the face (and the body and colour).
## - print_layers {layers: [colours of SchoolPictureArts] (1-4, printed first to last), view? ("steps": the print after
##   each layer, the default; "final")}: a layered print: a background, then hills and a sun, a tree and a house, then
##   the darkest details.
## - stroke_letters {text: 1-6 of STROKE_LETTERS, serif? (serifs at the strokes' ends), contrast? (thick and thin
##   strokes, as a broad nib makes them), monogram? (two letters on top of each other, in two colours), guides?}: capitals
##   built from strokes.
## - letter_guides {word (1-8 small letters), labels?, mark? (a GUIDES line, orange)}: the lines handwriting and
##   lettering sit on: the ascender line, the x-height, the baseline and the descender line (`part_at`).
## - land_art {design: DESIGNS, material: MATERIALS}: land art: natural things laid on the ground in a design ("seeds":
##   a sunflower's seed head, its seeds in spirals).
## - masterwork {what: MASTERWORKS}: a small picture after a famous painting of the past (Hokusai's Great Wave, van Gogh's
##   The Starry Night, Bruegel's Hunters in the Snow), to describe and analyse.
## Music
## - key_signature {key: KEYS, notes? [STAVE_NOTES of SchoolPictureG4Arts] (0-8, written as naturals: the key signature
##   sharpens or flattens them), names? (each note's name under it, with its sharp or flat), title? (the key's name)}:
##   a key signature on the treble stave (`key_accidentals`).
## - twelve_bar {key: BLUES_KEYS, mark? (a bar 0-11, orange), hide? [bars shown "?"], numerals? (I, IV, V under the
##   chords)}: the 12-bar blues in a key, four bars a line (`twelve_bar_chords`).
## - hand_keys {hand: "right" | "left", from? (a white key, "C4"), keys? (8-12), fingers: [[note, 1-5]] (1-5), mark? (a
##   note)}: a keyboard with finger numbers on the keys, and the hand with its fingers numbered (the thumbs are 1).
## - world_instrument {what: INSTRUMENTS, labels?, mark? (a part, orange)}: an instrument of the world with its parts
##   (`part_at`).
## - decibel_scale {items? [[name (16), dB 0-140]] (2-7; everyday sounds when none), mark? (an item's index), safe?
##   (true: the 85 dB line)}: loudness in decibels, from a whisper to a jet engine.

const KINDS: Array[String] = ["bit_cards", "rgb_mix", "logic_gate", "computer_parts", "phish_mail", "privacy_panel",
	"ai_examples", "art_principle", "illuminated", "star_pattern", "ink_landscape", "tessellation", "rotation_motif",
	"two_point", "feeling_art", "print_layers", "stroke_letters", "letter_guides", "land_art", "masterwork",
	"key_signature", "twelve_bar", "hand_keys", "world_instrument", "decibel_scale"]
const GATES: Array[String] = ["AND", "OR", "NOT"]
## Each part's centre as a share of the picture's inner rectangle (SchoolPicture.MARGIN in from the card's edges).
const PARTS := {"power supply": Vector2(0.16, 0.24), "processor": Vector2(0.53, 0.33), "memory": Vector2(0.74, 0.36),
	"storage": Vector2(0.49, 0.77), "ports": Vector2(0.93, 0.75)}
const CHOICES: Array[String] = ["everyone", "friends", "only me", "on", "off"]
const SHAPES: Array[String] = ["circle", "square", "triangle", "star"]
const PRINCIPLES: Array[String] = ["symmetry", "asymmetry", "radial", "contrast", "emphasis", "rhythm", "unity",
	"variety", "movement", "pattern"]
const INK_PARTS := {"far mountains": Vector2(0.5, 0.17), "mist": Vector2(0.5, 0.4), "near mountains": Vector2(0.44, 0.62),
	"water": Vector2(0.5, 0.9), "traveller": Vector2(0.585, 0.745), "poem": Vector2(0.625, 0.2)}
const TILES: Array[String] = ["triangle", "square", "hexagon", "brick", "rhombus", "octagon", "pentagon", "circle"]
const MOTIFS: Array[String] = ["petal", "leaf", "hook", "drop", "flag"]
const EYES: Array[String] = ["above", "level", "below"]
const TWO_POINT_PARTS: Array[String] = ["left vp", "right vp", "horizon", "near edge"]
const FEELINGS: Array[String] = ["joy", "sadness", "anger", "fear", "surprise", "calm"]
const STROKE_LETTERS := "AEFHIKLMNTVWXYZ"
const GUIDES: Array[String] = ["ascender line", "x-height", "baseline", "descender line"]
## Each guide's height above the baseline in the font's size (the ascender line, the x-height), below it for the
## descender line; the word is drawn with its baseline on the baseline.
const GUIDE_AT := {"ascender line": 0.74, "x-height": 0.5, "baseline": 0.0, "descender line": -0.22}
const DESIGNS: Array[String] = ["spiral", "circle", "rings", "line", "mandala", "seeds"]
const MATERIALS: Array[String] = ["stones", "leaves", "sticks", "petals"]
const MASTERWORKS: Array[String] = ["great_wave", "starry_night", "hunters_snow"]
const KEYS: Array[String] = ["C", "G", "D", "A", "F", "Bb"]
## Each key's sharps or flats, in the order a key signature writes them (the notes they change).
const KEY_SIGNATURES := {"C": [], "G": ["F#"], "D": ["F#", "C#"], "A": ["F#", "C#", "G#"], "F": ["Bb"], "Bb": ["Bb", "Eb"]}
## Where each sign sits on the treble stave, in steps up from the bottom line (E4 = 0).
const SIGN_STEP := {"F#": 8, "C#": 5, "G#": 9, "Bb": 4, "Eb": 7}
const BLUES_KEYS: Array[String] = ["C", "G", "D", "A", "E"]
const INSTRUMENTS: Array[String] = ["sitar", "koto", "djembe", "bagpipes", "steelpan", "didgeridoo", "kora", "erhu"]
## Each instrument's parts, where they are as shares of the picture's inner rectangle.
const INSTRUMENT_PARTS := {
	"sitar": {"pegs": Vector2(0.14, 0.34), "neck": Vector2(0.38, 0.44), "frets": Vector2(0.52, 0.34),
		"gourd": Vector2(0.82, 0.62)},
	"koto": {"body": Vector2(0.5, 0.76), "strings": Vector2(0.24, 0.44), "bridges": Vector2(0.62, 0.44)},
	"djembe": {"skin": Vector2(0.5, 0.12), "shell": Vector2(0.5, 0.56), "ropes": Vector2(0.37, 0.34)},
	"bagpipes": {"bag": Vector2(0.5, 0.58), "drones": Vector2(0.65, 0.16), "chanter": Vector2(0.37, 0.84),
		"blowpipe": Vector2(0.285, 0.35)},
	"steelpan": {"notes": Vector2(0.5, 0.3), "skirt": Vector2(0.5, 0.73), "sticks": Vector2(0.84, 0.36)},
	"didgeridoo": {"mouthpiece": Vector2(0.07, 0.5), "tube": Vector2(0.5, 0.5)},
	"kora": {"gourd": Vector2(0.5, 0.78), "neck": Vector2(0.5, 0.1), "strings": Vector2(0.531, 0.36)},
	"erhu": {"sound box": Vector2(0.5, 0.82), "neck": Vector2(0.5, 0.3), "bow": Vector2(0.72, 0.62)}}
## Where each part's name goes when the parts are named (shares of the picture's inner rectangle), clear of the drawing.
const INSTRUMENT_LABELS := {
	"sitar": {"pegs": Vector2(0.12, 0.1), "neck": Vector2(0.36, 0.72), "frets": Vector2(0.52, 0.1), "gourd": Vector2(0.58, 0.9)},
	"koto": {"strings": Vector2(0.24, 0.12), "bridges": Vector2(0.72, 0.12), "body": Vector2(0.5, 0.96)},
	"djembe": {"skin": Vector2(0.82, 0.12), "ropes": Vector2(0.14, 0.34), "shell": Vector2(0.82, 0.56)},
	"bagpipes": {"drones": Vector2(0.86, 0.16), "blowpipe": Vector2(0.1, 0.3), "bag": Vector2(0.86, 0.58),
		"chanter": Vector2(0.12, 0.84)},
	"steelpan": {"notes": Vector2(0.08, 0.2), "sticks": Vector2(0.9, 0.08), "skirt": Vector2(0.9, 0.73)},
	"didgeridoo": {"mouthpiece": Vector2(0.12, 0.2), "tube": Vector2(0.5, 0.8)},
	"kora": {"neck": Vector2(0.8, 0.1), "strings": Vector2(0.8, 0.36), "gourd": Vector2(0.84, 0.78)},
	"erhu": {"neck": Vector2(0.8, 0.3), "bow": Vector2(0.9, 0.44), "sound box": Vector2(0.8, 0.86)}}
const DECIBELS: Array = [["rustling leaves", 20], ["whisper", 30], ["talking", 60], ["busy street", 80],
	["lawnmower", 90], ["rock concert", 110], ["jet engine", 140]]
const INK := Color("1f2a4a")    # SchoolUi.INK
const SHADE := Color("f08a1c")
const BLUE := Color("3a7be8")
const SOFT := Color("fce2b8")
const PAPER_WHITE := Color("fffdf7")
const GREY := Color("9aa3b5")
const GOLD := Color("d9a520")
const BOARD := Color("2f7d4a")
const SCROLL := Color("efe3c4")
const ON := Color("f2c12e")
const OFF := Color("8c96a8")


# --- checks ----------------------------------------------------------------------------------------------------------

## "" when `p` (a kind of KINDS) can be drawn; otherwise what is wrong.
static func problem(p: Dictionary) -> String:
	var kind := str(p.get("kind", ""))
	match kind:
		"bit_cards":
			var bits := str(p.get("bits", ""))
			if not p.get("bits") is String or bits.length() < 1 or bits.length() > 8 \
					or bits.replace("0", "").replace("1", "") != "":
				return "bit_cards: bits is 1-8 of 0 and 1"
		"rgb_mix":
			for k: String in ["r", "g", "b"]:
				if not _in(_int(p, k, -1), 0, 255) or typeof(p.get(k)) not in [TYPE_INT, TYPE_FLOAT]:
					return "rgb_mix: r, g and b are 0-255"
			if p.has("view") and not str(p.view) in ["bars", "lights"]:
				return "rgb_mix: view is bars or lights"
		"logic_gate":
			var gate := str(p.get("gate", ""))
			var inputs: Variant = p.get("inputs")
			if not GATES.has(gate) or not inputs is Array or (inputs as Array).size() != (1 if gate == "NOT" else 2):
				return "logic_gate: a gate (AND, OR, NOT) and its inputs (two, or one for NOT)"
			for v: Variant in inputs:
				if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not int(v) in [0, 1]:
					return "logic_gate: an input is 0 or 1"
			if p.has("then") and str(p.then) != "NOT":
				return "logic_gate: then is NOT"
			if p.has("names") and not _texts(p.names, (inputs as Array).size(), 6):
				return "logic_gate: a name (6 letters) for each input"
		"computer_parts":
			for k: String in ["mark", "hide"]:
				if p.has(k) and not PARTS.has(str(p[k])):
					return "computer_parts: %s is one of %s" % [k, PARTS.keys()]
		"phish_mail":
			if not _short(p.get("from"), 36) or not _short(p.get("subject"), 36):
				return "phish_mail: from and subject, 36 letters each"
			var lines: Variant = p.get("lines")
			if not lines is Array or (lines as Array).is_empty() or not _texts(lines, (lines as Array).size(), 44) \
					or (lines as Array).size() > 4:
				return "phish_mail: 1-4 lines of 44 letters"
			if p.has("link") and not _short(p.link, 36):
				return "phish_mail: a link of 36 letters"
			if p.has("button") and not _short(p.button, 18):
				return "phish_mail: a button of 18 letters"
			if p.has("mark"):
				var m: Variant = p.mark
				var ok := str(m) in ["from", "subject"] or (str(m) == "link" and p.has("link")) \
					or (str(m) == "button" and p.has("button")) \
					or (typeof(m) in [TYPE_INT, TYPE_FLOAT] and _in(int(m), 0, (lines as Array).size() - 1))
				if not ok:
					return "phish_mail: mark is from, subject, link, button or a line's index"
		"privacy_panel":
			var rows: Variant = p.get("rows")
			if not rows is Array or (rows as Array).is_empty() or (rows as Array).size() > 5:
				return "privacy_panel: 1-5 rows"
			for row: Variant in rows:
				if not row is Array or (row as Array).size() != 2 or not _short(row[0], 22) or not CHOICES.has(str(row[1])):
					return "privacy_panel: a row is [setting (22 letters), %s]" % [CHOICES]
			if p.has("title") and not _short(p.title, 22):
				return "privacy_panel: a title of 22 letters"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, (rows as Array).size() - 1):
				return "privacy_panel: mark is a row's index"
		"ai_examples":
			var ex: Variant = p.get("examples")
			if not ex is Array or (ex as Array).size() < 2 or (ex as Array).size() > 8:
				return "ai_examples: 2-8 examples"
			var labels := {}
			for e: Variant in ex:
				if not e is Array or (e as Array).size() != 3 or not SHAPES.has(str(e[0])) \
						or not SchoolPictureArts.COLOURS.has(str(e[1])) or not _short(e[2], 10):
					return "ai_examples: an example is [shape, colour, label (10 letters)]"
				labels[str(e[2])] = true
			if labels.size() != 2:
				return "ai_examples: the examples have two labels"
			if p.has("new"):
				var n: Variant = p.new
				if not n is Array or (n as Array).size() != 2 or not SHAPES.has(str(n[0])) \
						or not SchoolPictureArts.COLOURS.has(str(n[1])):
					return "ai_examples: new is [shape, colour]"
		"art_principle":
			if not PRINCIPLES.has(str(p.get("show", ""))):
				return "art_principle: show is one of %s" % [PRINCIPLES]
		"illuminated":
			var letter := str(p.get("letter", ""))
			if letter.length() != 1 or not "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(letter):
				return "illuminated: letter is one capital A-Z"
		"star_pattern":
			if not _int(p, "points", 0) in [6, 8, 10, 12] or not _in(_int(p, "stage", 3), 1, 3):
				return "star_pattern: points 6, 8, 10 or 12, stage 1-3"
		"ink_landscape":
			if p.has("mark") and not INK_PARTS.has(str(p.mark)):
				return "ink_landscape: mark is one of %s" % [INK_PARTS.keys()]
		"tessellation":
			if not TILES.has(str(p.get("shape", ""))):
				return "tessellation: shape is one of %s" % [TILES]
			if p.has("colours"):
				var cs: Variant = p.colours
				if not cs is Array or (cs as Array).size() < 2 or (cs as Array).size() > 3:
					return "tessellation: 2-3 colours"
				for c: Variant in cs:
					if not SchoolPictureArts.COLOURS.has(str(c)):
						return "tessellation: '%s' is not a colour" % c
		"rotation_motif":
			if not _in(_int(p, "order", 0), 2, 12) or not MOTIFS.has(str(p.get("motif", ""))):
				return "rotation_motif: order 2-12 and a motif of %s" % [MOTIFS]
		"two_point":
			if not EYES.has(str(p.get("eye", ""))):
				return "two_point: eye is above, level or below"
			if p.has("mark") and not TWO_POINT_PARTS.has(str(p.mark)):
				return "two_point: mark is one of %s" % [TWO_POINT_PARTS]
		"feeling_art":
			if not FEELINGS.has(str(p.get("feeling", ""))):
				return "feeling_art: feeling is one of %s" % [FEELINGS]
		"print_layers":
			var layers: Variant = p.get("layers")
			if not layers is Array or (layers as Array).is_empty() or (layers as Array).size() > 4:
				return "print_layers: 1-4 layers"
			for c: Variant in layers:
				if not SchoolPictureArts.COLOURS.has(str(c)):
					return "print_layers: '%s' is not a colour" % c
			if p.has("view") and not str(p.view) in ["steps", "final"]:
				return "print_layers: view is steps or final"
		"stroke_letters":
			var text := str(p.get("text", ""))
			if not p.get("text") is String or text.length() < 1 or text.length() > 6:
				return "stroke_letters: text is 1-6 letters"
			for ch in text:
				if not STROKE_LETTERS.contains(ch):
					return "stroke_letters: '%s' is not one of %s" % [ch, STROKE_LETTERS]
			if bool(p.get("monogram", false)) and text.length() != 2:
				return "stroke_letters: a monogram is two letters"
		"letter_guides":
			var word := str(p.get("word", ""))
			if not p.get("word") is String or word.length() < 1 or word.length() > 8 or word != word.to_lower() \
					or not word.is_valid_identifier():
				return "letter_guides: a word of 1-8 small letters"
			if p.has("mark") and not GUIDES.has(str(p.mark)):
				return "letter_guides: mark is one of %s" % [GUIDES]
		"land_art":
			if not DESIGNS.has(str(p.get("design", ""))) or not MATERIALS.has(str(p.get("material", ""))):
				return "land_art: a design of %s and a material of %s" % [DESIGNS, MATERIALS]
		"masterwork":
			if not MASTERWORKS.has(str(p.get("what", ""))):
				return "masterwork: what is one of %s" % [MASTERWORKS]
		"key_signature":
			if not KEYS.has(str(p.get("key", ""))):
				return "key_signature: key is one of %s" % [KEYS]
			var notes: Variant = p.get("notes", [])
			if not notes is Array or (notes as Array).size() > 8:
				return "key_signature: 0-8 notes"
			for n: Variant in notes:
				if not SchoolPictureG4Arts.STAVE_NOTES.has(str(n)):
					return "key_signature: '%s' is not a stave note" % n
		"twelve_bar":
			if not BLUES_KEYS.has(str(p.get("key", ""))):
				return "twelve_bar: key is one of %s" % [BLUES_KEYS]
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, 11):
				return "twelve_bar: mark is a bar 0-11"
			if p.has("hide"):
				if not p.hide is Array:
					return "twelve_bar: hide lists bars"
				for b: Variant in p.hide:
					if typeof(b) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(b), 0, 11):
						return "twelve_bar: hide lists bars 0-11"
		"hand_keys":
			if not str(p.get("hand", "")) in ["right", "left"]:
				return "hand_keys: hand is right or left"
			var from := SchoolPictureG5Arts._pitch(str(p.get("from", "C4")))
			var keys := _int(p, "keys", 8)
			if from < 0 or str(p.get("from", "C4")).length() != 2 or not _in(keys, 8, 12):
				return "hand_keys: from is a white key (C4) and keys 8-12"
			var top := SchoolPictureG5Arts._white_pitch(from, keys - 1)
			var fingers: Variant = p.get("fingers")
			if not fingers is Array or (fingers as Array).is_empty() or (fingers as Array).size() > 5:
				return "hand_keys: 1-5 fingers"
			for f: Variant in fingers:
				if not f is Array or (f as Array).size() != 2 or typeof(f[1]) not in [TYPE_INT, TYPE_FLOAT] \
						or not _in(int(f[1]), 1, 5):
					return "hand_keys: a finger is [note, 1-5]"
				var at := SchoolPictureG5Arts._pitch(str(f[0]))
				if at < from or at > top:
					return "hand_keys: %s is not on the keyboard" % f[0]
			if p.has("mark") and SchoolPictureG5Arts._pitch(str(p.mark)) < 0:
				return "hand_keys: mark is a note"
		"world_instrument":
			var what := str(p.get("what", ""))
			if not INSTRUMENTS.has(what):
				return "world_instrument: what is one of %s" % [INSTRUMENTS]
			if p.has("mark") and not (INSTRUMENT_PARTS[what] as Dictionary).has(str(p.mark)):
				return "world_instrument: mark is one of %s" % [(INSTRUMENT_PARTS[what] as Dictionary).keys()]
		"decibel_scale":
			if p.has("items"):
				var items: Variant = p.items
				if not items is Array or (items as Array).size() < 2 or (items as Array).size() > 7:
					return "decibel_scale: 2-7 items"
				for it: Variant in items:
					if not it is Array or (it as Array).size() != 2 or not _short(it[0], 16) \
							or typeof(it[1]) not in [TYPE_INT, TYPE_FLOAT] or not _in(int(it[1]), 0, 140):
						return "decibel_scale: an item is [name (16 letters), 0-140 dB]"
			if p.has("mark") and not _in(_int(p, "mark", -1), 0, _items(p).size() - 1):
				return "decibel_scale: mark is an item's index"
	return ""


# --- facts the tests share -------------------------------------------------------------------------------------------

## The number binary digits stand for ("10110" is 16 + 4 + 2 = 22).
static func bits_value(bits: String) -> int:
	var n := 0
	for ch in bits:
		n = n * 2 + (1 if ch == "1" else 0)
	return n


## A logic gate's output: AND is 1 when both inputs are 1, OR when either is, NOT turns its input round.
static func gate_out(gate: String, inputs: Array) -> int:
	match gate:
		"AND":
			return 1 if int(inputs[0]) == 1 and int(inputs[1]) == 1 else 0
		"OR":
			return 1 if int(inputs[0]) == 1 or int(inputs[1]) == 1 else 0
	return 1 - int(inputs[0])


## The sharps or flats of a major key's signature ("G" -> ["F#"]).
static func key_accidentals(key: String) -> Array:
	return (KEY_SIGNATURES.get(key, []) as Array).duplicate()


## The 12-bar blues in `key`: the home chord (I) for four bars, IV for two, I for two, V, IV, I, I.
static func twelve_bar_chords(key: String) -> Array[String]:
	var letters := "CDEFGAB"
	var i := letters.find(key.left(1))
	var one := key
	var four := letters[(i + 3) % 7]
	var five := letters[(i + 4) % 7]
	var out: Array[String] = [one, one, one, one, four, four, one, one, five, four, one, one]
	return out


## Where a named part is in picture `d` drawn at `size` (the card's size, as a label exercise's LABEL_BOX), in the
## card's pixels; Vector2(-1, -1) when the picture has no such part.
static func part_at(d: Dictionary, part: String, size: Vector2) -> Vector2:
	var r := Rect2(Vector2(SchoolPicture.MARGIN, SchoolPicture.MARGIN), size - Vector2(2, 2) * SchoolPicture.MARGIN)
	var share := Vector2(-1, -1)
	match str(d.get("kind", "")):
		"computer_parts":
			share = PARTS.get(part, share)
		"ink_landscape":
			share = INK_PARTS.get(part, share)
		"world_instrument":
			share = (INSTRUMENT_PARTS.get(str(d.get("what", "")), {}) as Dictionary).get(part, share)
		"two_point":
			var g := _two_point_geometry(r, str(d.get("eye", "level")))
			match part:
				"left vp":
					return g.vl
				"right vp":
					return g.vr
				"horizon":
					return Vector2(r.position.x + r.size.x * 0.13, g.vl.y)
				"near edge":
					return (g.top as Vector2).lerp(g.bottom, 0.5)
		"letter_guides":
			if GUIDES.has(part):
				var g := _guides_geometry(r)
				return Vector2(r.position.x + r.size.x * 0.1, float(g[part]))
	if share == Vector2(-1, -1):
		return share
	return r.position + share * r.size


static func _items(p: Dictionary) -> Array:
	return p.get("items", DECIBELS) if p.get("items") is Array else DECIBELS


# --- drawing ---------------------------------------------------------------------------------------------------------

static func draw(pic: Control, d: Dictionary, r: Rect2) -> void:
	var font := pic.get_theme_default_font()
	match str(d.kind):
		"bit_cards":
			_draw_bits(pic, font, r, d)
		"rgb_mix":
			_draw_rgb(pic, font, r, d)
		"logic_gate":
			_draw_gate(pic, font, r, d)
		"computer_parts":
			_draw_computer(pic, font, r, d)
		"phish_mail":
			_draw_mail(pic, font, r, d)
		"privacy_panel":
			_draw_privacy(pic, font, r, d)
		"ai_examples":
			_draw_ai(pic, font, r, d)
		"art_principle":
			_draw_principle(pic, r, d)
		"illuminated":
			_draw_illuminated(pic, font, r, d)
		"star_pattern":
			_draw_star_pattern(pic, r, d)
		"ink_landscape":
			_draw_ink(pic, font, r, d)
		"tessellation":
			_draw_tiles(pic, r, d)
		"rotation_motif":
			_draw_rotation(pic, r, d)
		"two_point":
			_draw_two_point(pic, font, r, d)
		"feeling_art":
			_draw_feeling(pic, r, d)
		"print_layers":
			_draw_print_layers(pic, font, r, d)
		"stroke_letters":
			_draw_stroke_letters(pic, r, d)
		"letter_guides":
			_draw_guides(pic, font, r, d)
		"land_art":
			_draw_land_art(pic, r, d)
		"masterwork":
			_draw_masterwork(pic, r, d)
		"key_signature":
			_draw_key_signature(pic, font, r, d)
		"twelve_bar":
			_draw_twelve_bar(pic, font, r, d)
		"hand_keys":
			_draw_hand_keys(pic, font, r, d)
		"world_instrument":
			_draw_instrument(pic, font, r, d)
		"decibel_scale":
			_draw_decibels(pic, font, r, d)


# --- computing -------------------------------------------------------------------------------------------------------

static func _draw_bits(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var bits := str(d.bits)
	var n := bits.length()
	var values := bool(d.get("values", true))
	var dots := bool(d.get("dots", n <= 5))
	var total := bool(d.get("total", false))
	var fs := _fs(r, 0.11, 22)
	var top_h := fs * 1.5 if values else 0.0
	var bottom_h := fs * 1.8 if total else 0.0
	var gap := r.size.x * 0.025
	var room := r.size.y - top_h - bottom_h
	var cw := minf((r.size.x - gap * (n - 1)) / n, room / 1.35)
	var ch := minf(cw * 1.35, room)
	var x0 := r.position.x + (r.size.x - (cw * n + gap * (n - 1))) * 0.5
	var y0 := r.position.y + top_h + (room - ch) * 0.5
	for i in n:
		var value := 1 << (n - 1 - i)
		var box := Rect2(Vector2(x0 + i * (cw + gap), y0), Vector2(cw, ch))
		var up := bits[i] == "1"
		if values:
			_label(ci, font, Vector2(box.get_center().x, y0 - top_h * 0.5), str(value), _fit(font, str(value), fs, cw + gap))
		_rounded(ci, box.grow(1.5), INK, cw * 0.1)
		if up:
			_rounded(ci, box, PAPER_WHITE, cw * 0.1)
			var face := Rect2(box.position + Vector2(cw * 0.1, ch * 0.08), Vector2(cw * 0.8, ch * 0.66))
			if dots:
				_dots(ci, face, value, INK)
			else:
				_label(ci, font, face.get_center(), str(value), _fit(font, str(value), int(fs * 1.4), face.size.x))
		else:
			_rounded(ci, box, Color("2f5fb0"), cw * 0.1)
			var inner := box.grow(-cw * 0.12)
			for k in 7:
				var t := (k + 1) / 8.0
				ci.draw_line(inner.position + Vector2(inner.size.x * t, 0), inner.position + Vector2(0, inner.size.y * t),
					Color(1, 1, 1, 0.25), maxf(1.0, cw * 0.03))
				ci.draw_line(inner.end - Vector2(inner.size.x * t, 0), inner.end - Vector2(0, inner.size.y * t),
					Color(1, 1, 1, 0.25), maxf(1.0, cw * 0.03))
		var digit_c := Vector2(box.get_center().x, box.end.y - ch * 0.13)
		ci.draw_circle(digit_c, minf(cw * 0.2, ch * 0.11), SHADE if up else PAPER_WHITE)
		_label(ci, font, digit_c, bits[i], _fit(font, "0", int(minf(cw * 0.3, ch * 0.18)), cw * 0.3),
			Color.WHITE if up else INK)
	if total:
		var t := str(bits_value(bits))
		_label(ci, font, Vector2(r.get_center().x, r.end.y - bottom_h * 0.45), t, int(fs * 1.3), SHADE)


## `count` dots in a grid that fits `box`.
static func _dots(ci: CanvasItem, box: Rect2, count: int, col: Color) -> void:
	var cols := 1
	while cols * cols * box.size.y / maxf(box.size.x, 1.0) < count:
		cols += 1
	cols = maxi(1, mini(cols, count))
	var rows := int(ceil(count / float(cols)))
	var cell := minf(box.size.x / cols, box.size.y / rows)
	var o := box.get_center() - Vector2(cols, rows) * cell * 0.5
	for k in count:
		ci.draw_circle(o + Vector2((k % cols) + 0.5, (k / cols) + 0.5) * cell, cell * 0.32, col)


static func _draw_rgb(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var vals: Array[int] = [_int(d, "r", 0), _int(d, "g", 0), _int(d, "b", 0)]
	var chans: Array[Color] = [Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1)]
	var fs := _fs(r, 0.11, 22)
	if str(d.get("view", "bars")) == "lights":
		_rounded(ci, r, Color("15181f"), 10)
		var rad := minf(r.size.x * 0.24, r.size.y * 0.33)
		var c := r.get_center() + Vector2(0, rad * 0.08)
		var centres: Array[Vector2] = [c + Vector2(-rad * 0.52, -rad * 0.36), c + Vector2(rad * 0.52, -rad * 0.36),
			c + Vector2(0, rad * 0.52)]
		var circles: Array[PackedVector2Array] = []
		for k in 3:
			circles.append(_circle(centres[k], rad, 48))
		var on: Array[int] = []
		for k in 3:
			if vals[k] > 0:
				on.append(k)
				var v := vals[k] / 255.0
				ci.draw_colored_polygon(circles[k], Color(chans[k].r * v, chans[k].g * v, chans[k].b * v, 1))
		for a in on:   # where two lights overlap, then all three
			for b in on:
				if b <= a:
					continue
				var both := Geometry2D.intersect_polygons(circles[a], circles[b])
				if both.size() > 0:
					var mix := chans[a] * (vals[a] / 255.0) + chans[b] * (vals[b] / 255.0)
					ci.draw_colored_polygon(both[0], Color(mix.r, mix.g, mix.b, 1))
		if on.size() == 3:
			var ab := Geometry2D.intersect_polygons(circles[0], circles[1])
			if ab.size() > 0:
				var all := Geometry2D.intersect_polygons(ab[0], circles[2])
				if all.size() > 0:
					ci.draw_colored_polygon(all[0], Color(vals[0] / 255.0, vals[1] / 255.0, vals[2] / 255.0, 1))
		return
	var names: Array[String] = ["red", "green", "blue"]
	var sw := minf(r.size.y * 0.8, r.size.x * 0.3)
	var bars := Rect2(r.position, Vector2(r.size.x - sw - r.size.x * 0.06, r.size.y))
	var rh := bars.size.y / 3.0
	var name_w := fs * 3.6
	var num_w := fs * 2.4
	for k in 3:
		var y := bars.position.y + rh * k + rh * 0.5
		_label(ci, font, Vector2(bars.position.x + name_w * 0.45, y), names[k], _fit(font, names[k], fs, name_w * 0.95))
		var track := Rect2(Vector2(bars.position.x + name_w, y - rh * 0.26), Vector2(bars.size.x - name_w - num_w, rh * 0.52))
		_rounded(ci, track.grow(1.5), INK, 6)
		_rounded(ci, track, Color("20242c"), 5)
		if vals[k] > 0:
			_rounded(ci, Rect2(track.position, Vector2(track.size.x * vals[k] / 255.0, track.size.y)), chans[k], 5)
		_label(ci, font, Vector2(track.end.x + num_w * 0.5, y), str(vals[k]), _fit(font, "255", fs, num_w * 0.95))
	var box := Rect2(Vector2(r.end.x - sw, r.get_center().y - sw * 0.5), Vector2(sw, sw))
	_rounded(ci, box.grow(2), INK, 10)
	_rounded(ci, box, Color(vals[0] / 255.0, vals[1] / 255.0, vals[2] / 255.0), 9)


static func _circle(c: Vector2, rad: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(c + Vector2.from_angle(TAU * i / n) * rad)
	return pts


static func _draw_gate(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var gate := str(d.gate)
	var ins: Array = d.inputs
	var then_not := str(d.get("then", "")) == "NOT"
	var names: Array = d.get("names", [])
	var fs := _fs(r, 0.12, 24)
	var h := minf(r.size.y * 0.6, r.size.x * (0.26 if then_not else 0.32))
	var w := h * 1.15
	var bubble := fs * 0.9
	var left := r.position.x + (fs * 3.2 if not names.is_empty() else 0.0) + bubble
	var right := r.end.x - bubble
	var cx := r.position.x + r.size.x * (0.4 if then_not else 0.5)
	var cy := r.get_center().y
	var body := Rect2(Vector2(cx - w * 0.5, cy - h * 0.5), Vector2(w, h))
	var lw := maxf(3.0, h * 0.05)
	var ys: Array[float] = []
	if gate == "NOT":
		ys.append(cy)
	else:
		ys.append_array([cy - h * 0.27, cy + h * 0.27])
	for k in ins.size():
		var on := int(ins[k]) == 1
		var y := ys[k]
		ci.draw_line(Vector2(left, y), Vector2(body.position.x + (w * 0.14 if gate == "OR" else 0.0), y), ON if on else OFF, lw)
		_value_bubble(ci, font, Vector2(left, y), str(int(ins[k])), on, bubble)   # JSON numbers are floats
		if k < names.size():
			_label(ci, font, Vector2(r.position.x + fs * 1.5, y), str(names[k]), _fit(font, str(names[k]), fs, fs * 3.0))
	var out := gate_out(gate, ins)
	var end_x := _gate_shape(ci, font, gate, body, lw, fs)
	var final := out
	if then_not:
		var small := Rect2(Vector2(r.position.x + r.size.x * 0.68, cy - h * 0.28), Vector2(h * 0.62, h * 0.56))
		ci.draw_line(Vector2(end_x, cy), Vector2(small.position.x, cy), ON if out == 1 else OFF, lw)
		end_x = _gate_shape(ci, font, "NOT", small, lw, int(fs * 0.8))
		final = 1 - out
	var shown := bool(d.get("out", true))
	ci.draw_line(Vector2(end_x, cy), Vector2(right, cy), (ON if final == 1 else OFF) if shown else INK, lw)
	_value_bubble(ci, font, Vector2(right, cy), str(final) if shown else "?", shown and final == 1, bubble)


## A gate's symbol filled in `box`, its name inside; returns where its output wire starts.
static func _gate_shape(ci: CanvasItem, font: Font, gate: String, box: Rect2, lw: float, fs: int) -> float:
	var pts := PackedVector2Array()
	var x0 := box.position.x
	var y0 := box.position.y
	var w := box.size.x
	var h := box.size.y
	var cy := box.get_center().y
	var out_x := box.end.x
	match gate:
		"AND":
			pts.append(Vector2(x0, y0))
			pts.append(Vector2(x0 + w - h * 0.5, y0))
			for i in 25:
				pts.append(Vector2(x0 + w - h * 0.5, cy) + Vector2.from_angle(-PI * 0.5 + PI * i / 24.0) * h * 0.5)
			pts.append(Vector2(x0, y0 + h))
		"OR":
			var tip := Vector2(x0 + w, cy)
			for i in 17:
				pts.append(_bezier(Vector2(x0, y0), Vector2(x0 + w * 0.62, y0), tip, i / 16.0))
			for i in range(1, 17):
				pts.append(_bezier(tip, Vector2(x0 + w * 0.62, y0 + h), Vector2(x0, y0 + h), i / 16.0))
			for i in range(1, 16):
				pts.append(_bezier(Vector2(x0, y0 + h), Vector2(x0 + w * 0.3, cy), Vector2(x0, y0), i / 16.0))
		_:
			var rb := h * 0.09
			pts.append(Vector2(x0, y0))
			pts.append(Vector2(x0 + w - 2.0 * rb, cy))
			pts.append(Vector2(x0, y0 + h))
			out_x = x0 + w
	ci.draw_colored_polygon(pts, SOFT)
	var ring := pts.duplicate()
	ring.append(pts[0])
	ci.draw_polyline(ring, INK, lw * 0.8, true)
	if gate == "NOT":
		var rb := h * 0.09
		ci.draw_circle(Vector2(x0 + w - rb, cy), rb, SOFT)
		_ring(ci, Vector2(x0 + w - rb, cy), rb, INK, lw * 0.7)
		_label(ci, font, Vector2(x0 + w * 0.34, cy), "NOT", _fit(font, "NOT", fs, w * 0.5))
	else:
		_label(ci, font, Vector2(x0 + w * (0.4 if gate == "AND" else 0.45), cy), gate, _fit(font, gate, fs, w * 0.62))
	return out_x


static func _bezier(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)


static func _value_bubble(ci: CanvasItem, font: Font, c: Vector2, text: String, lit: bool, rad: float) -> void:
	ci.draw_circle(c, rad, ON if lit else PAPER_WHITE)
	_ring(ci, c, rad, INK, maxf(1.5, rad * 0.1))
	_label(ci, font, c, text, int(rad * 1.2))


static func _ring(ci: CanvasItem, c: Vector2, rad: float, col: Color, lw: float) -> void:
	ci.draw_arc(c, rad, 0.0, TAU, 40, col, lw, true)


static func _draw_computer(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var fs := _fs(r, 0.085, 17)
	var at := func(share: Vector2) -> Vector2: return r.position + share * r.size
	_rounded(ci, r, Color("d7dbe3"), 10)
	ci.draw_rect(r.grow(-2), Color("aab1bf"), false, 2.0)
	var board := Rect2(at.call(Vector2(0.34, 0.05)), r.size * Vector2(0.64, 0.9))
	_rounded(ci, board, BOARD, 6)
	for k in 9:   # the board's copper tracks
		var y := board.position.y + board.size.y * (0.08 + 0.1 * k)
		ci.draw_line(Vector2(board.position.x + board.size.x * 0.03, y), Vector2(board.position.x + board.size.x * 0.3, y),
			Color(0.85, 0.7, 0.3, 0.35), 1.5)
	var boxes := {}
	# the power supply: a box with its fan
	var psu := Rect2(at.call(Vector2(0.03, 0.06)), r.size * Vector2(0.26, 0.36))
	_rounded(ci, psu, Color("5b6170"), 6)
	var fan_c := psu.get_center()
	var fan_r := minf(psu.size.x, psu.size.y) * 0.36
	ci.draw_circle(fan_c, fan_r, Color("3a3f4b"))
	for k in 5:
		var a := TAU * k / 5.0
		ci.draw_line(fan_c, fan_c + Vector2.from_angle(a) * fan_r * 0.9, Color("9aa0ad"), maxf(2.0, fan_r * 0.12))
	boxes["power supply"] = psu
	# the processor: a chip with its pins
	var cpu := Rect2(at.call(Vector2(0.45, 0.14)), Vector2(r.size.y * 0.38, r.size.y * 0.38))
	cpu.position.x = at.call(PARTS["processor"]).x - cpu.size.x * 0.5
	ci.draw_rect(cpu, Color("c9a54a"))
	ci.draw_rect(cpu.grow(-cpu.size.x * 0.14), Color("3b3f48"))
	ci.draw_rect(cpu.grow(-cpu.size.x * 0.3), Color("9aa0ad"))
	boxes["processor"] = cpu
	# the memory: two sticks with chips
	var mem := Rect2(at.call(Vector2(0.69, 0.1)), r.size * Vector2(0.1, 0.52))
	for k in 2:
		var stick := Rect2(mem.position + Vector2(mem.size.x * 0.55 * k, 0), Vector2(mem.size.x * 0.42, mem.size.y))
		ci.draw_rect(stick, Color("1f6b3a"))
		for c in 4:
			ci.draw_rect(Rect2(stick.position + Vector2(stick.size.x * 0.18, stick.size.y * (0.06 + 0.24 * c)),
				Vector2(stick.size.x * 0.64, stick.size.y * 0.18)), Color("1c1f26"))
		ci.draw_rect(Rect2(Vector2(stick.position.x, stick.end.y - 3), Vector2(stick.size.x, 3)), GOLD)
	boxes["memory"] = mem
	# the storage: a solid-state drive
	var ssd := Rect2(at.call(Vector2(0.39, 0.66)), r.size * Vector2(0.2, 0.22))
	_rounded(ci, ssd, Color("24324f"), 5)
	ci.draw_rect(Rect2(ssd.position + ssd.size * Vector2(0.1, 0.25), ssd.size * Vector2(0.55, 0.5)), Color("dfe4ee"))
	ci.draw_rect(Rect2(Vector2(ssd.end.x - 4, ssd.position.y + ssd.size.y * 0.3), Vector2(4, ssd.size.y * 0.4)), GOLD)
	boxes["storage"] = ssd
	# the ports on the board's edge
	var ports := Rect2(at.call(Vector2(0.9, 0.6)), r.size * Vector2(0.07, 0.3))
	for k in 3:
		var p := Rect2(ports.position + Vector2(0, ports.size.y * 0.34 * k), Vector2(ports.size.x, ports.size.y * 0.26))
		ci.draw_rect(p, Color("c5cad4"))
		ci.draw_rect(p.grow(-p.size.y * 0.25), Color("2a2f3a"))
	boxes["ports"] = ports
	var mark := str(d.get("mark", ""))
	var hide := str(d.get("hide", ""))
	for part: String in boxes:
		var b: Rect2 = boxes[part]
		if part == mark:
			ci.draw_rect(b.grow(4), SHADE, false, 4.0)
		if bool(d.get("labels", false)) or part == hide:
			var text := "?" if part == hide else part
			var c: Vector2 = at.call(PARTS[part])
			var tfs := _fit(font, text, fs, r.size.x * 0.24)
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x + tfs * 0.8
			var tag := Rect2(c - Vector2(tw, tfs * 1.5) * 0.5, Vector2(tw, tfs * 1.5))
			tag.position.x = clampf(tag.position.x, r.position.x, r.end.x - tag.size.x)
			_rounded(ci, tag, SHADE if part == mark else PAPER_WHITE, 6)
			_label(ci, font, tag.get_center(), text, tfs, Color.WHITE if part == mark else INK)


static func _draw_mail(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var lines: Array = d.lines
	var rows := 2 + lines.size() + (1 if d.has("link") else 0) + (1 if d.has("button") else 0)
	var bar_h := minf(r.size.y * 0.1, 26.0)
	var rh := (r.size.y - bar_h) / (rows + 0.6)
	var fs := clampi(int(rh * 0.5), 9, 20)
	var mark: Variant = d.get("mark", null)
	_rounded(ci, r, Color("c3cad8"), 10)
	var win := r.grow(-2)
	_rounded(ci, win, PAPER_WHITE, 9)
	var bar := Rect2(win.position, Vector2(win.size.x, bar_h))
	_rounded(ci, bar, Color("dfe5f0"), 9)
	for k in 3:
		ci.draw_circle(bar.position + Vector2(bar_h * (0.6 + 0.55 * k), bar_h * 0.5), bar_h * 0.18, [Color("e05a4f"),
			Color("f2c12e"), Color("3aa845")][k])
	var x := win.position.x + fs * 0.8
	var y := bar.end.y + rh * 0.3
	var items: Array = [["from", "From: " + str(d.from)], ["subject", "Subject: " + str(d.subject)]]
	for i in lines.size():
		items.append([i, str(lines[i])])
	if d.has("link"):
		items.append(["link", str(d.link)])
	if d.has("button"):
		items.append(["button", str(d.button)])
	for it: Array in items:
		var key: Variant = it[0]
		var text := str(it[1])
		var size := _fit(font, text, fs, win.size.x - fs * 1.8)
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var box := Rect2(Vector2(x - fs * 0.3, y), Vector2(tw + fs * 0.6, rh))
		var col := INK
		if str(key) == "button":
			box = Rect2(Vector2(x, y + rh * 0.08), Vector2(tw + fs * 1.6, rh * 0.84))
			_rounded(ci, box, SHADE, 8)
			_label(ci, font, box.get_center(), text, size, Color.WHITE)
		else:
			if str(key) == "link":
				col = Color("1a55c0")
			var base := y + rh * 0.5 + (font.get_ascent(size) - font.get_descent(size)) * 0.5
			ci.draw_string(font, Vector2(x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
			if str(key) == "link":
				ci.draw_line(Vector2(x, base + 3), Vector2(x + tw, base + 3), col, 1.5)
			if str(key) == "subject":
				ci.draw_line(Vector2(win.position.x + 6, y + rh * 1.02), Vector2(win.end.x - 6, y + rh * 1.02), GREY, 1.0)
		if mark != null and str(mark) == str(key) and typeof(mark) == typeof(key):
			ci.draw_rect(box.grow(3), SHADE, false, 3.0)
		y += rh


static func _draw_privacy(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var rows: Array = d.rows
	var title_h := r.size.y * 0.18 if d.has("title") else 0.0
	var rh := minf((r.size.y - title_h) / rows.size(), r.size.y * 0.24)
	var fs := clampi(int(rh * 0.36), 9, 20)
	var mark := _int(d, "mark", -1)
	_rounded(ci, r, Color("e8edf5"), 12)
	if d.has("title"):
		_label(ci, font, Vector2(r.get_center().x, r.position.y + title_h * 0.55), str(d.title),
			_fit(font, str(d.title), int(fs * 1.2), r.size.x * 0.9))
	var y := r.position.y + title_h + (r.size.y - title_h - rh * rows.size()) * 0.5
	for i in rows.size():
		var row := Rect2(Vector2(r.position.x + 8, y + 3), Vector2(r.size.x - 16, rh - 6))
		_rounded(ci, row, PAPER_WHITE, 8)
		if i == mark:
			ci.draw_rect(row.grow(2), SHADE, false, 3.0)
		var setting := str(rows[i][0])
		var choice := str(rows[i][1])
		var sfs := _fit(font, setting, fs, row.size.x * 0.56)
		var base := row.get_center().y + (font.get_ascent(sfs) - font.get_descent(sfs)) * 0.5
		ci.draw_string(font, Vector2(row.position.x + fs * 0.7, base), setting, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, INK)
		if choice in ["on", "off"]:
			var track := Rect2(Vector2(row.end.x - rh * 1.5, row.get_center().y - rh * 0.2), Vector2(rh * 1.1, rh * 0.4))
			_rounded(ci, track, Color("3aa845") if choice == "on" else OFF, rh * 0.2)
			ci.draw_circle(Vector2(track.end.x - rh * 0.2 if choice == "on" else track.position.x + rh * 0.2,
				track.get_center().y), rh * 0.17, Color.WHITE)
			_label(ci, font, Vector2(track.position.x - fs * 1.2, track.get_center().y), choice.to_upper(), fs)
		else:
			var col := {"everyone": SHADE, "friends": BLUE, "only me": Color("3aa845")}[choice] as Color
			var cfs := _fit(font, choice, fs, row.size.x * 0.3)
			var pw := font.get_string_size(choice, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs).x + fs * 1.2
			var pill := Rect2(Vector2(row.end.x - pw - fs * 0.6, row.get_center().y - rh * 0.24), Vector2(pw, rh * 0.48))
			_rounded(ci, pill, col, rh * 0.24)
			_label(ci, font, pill.get_center(), choice, cfs, Color.WHITE)
		y += rh


static func _draw_ai(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var examples: Array = d.examples
	var labels: Array[String] = []
	for e: Array in examples:
		if not labels.has(str(e[2])):
			labels.append(str(e[2]))
	var fs := _fs(r, 0.1, 20)
	var has_new := d.has("new")
	var new_w := r.size.x * 0.2 if has_new else 0.0
	var gw := (r.size.x - new_w - 12.0) / 2.0
	for g in 2:
		var box := Rect2(Vector2(r.position.x + g * (gw + 6.0), r.position.y), Vector2(gw, r.size.y))
		_rounded(ci, box, Color("e8f0fb") if g == 0 else Color("fdeede"), 10)
		_label(ci, font, Vector2(box.get_center().x, box.position.y + fs * 0.9), labels[g], _fit(font, labels[g], fs, gw * 0.9))
		var mine: Array = examples.filter(func(e: Array) -> bool: return str(e[2]) == labels[g])
		var inner := Rect2(box.position + Vector2(6, fs * 1.8), box.size - Vector2(12, fs * 1.8 + 6))
		var cols := 2 if mine.size() <= 4 else 3
		var rows := int(ceil(mine.size() / float(cols)))
		var cell := minf(inner.size.x / cols, inner.size.y / maxi(rows, 1))
		var o := inner.get_center() - Vector2(cols, rows) * cell * 0.5
		for k in mine.size():
			var c := o + Vector2((k % cols) + 0.5, (k / cols) + 0.5) * cell
			_shape(ci, str(mine[k][0]), c, cell * 0.36, SchoolPictureArts.COLOURS[str(mine[k][1])])
	if has_new:
		var box := Rect2(Vector2(r.end.x - new_w, r.position.y), Vector2(new_w, r.size.y))
		_rounded(ci, box, Color("fff4d6"), 10)
		ci.draw_rect(box.grow(-2), SHADE, false, 2.0)
		var s := minf(new_w * 0.34, r.size.y * 0.22)
		_shape(ci, str(d.new[0]), box.get_center() - Vector2(0, s * 0.5), s, SchoolPictureArts.COLOURS[str(d.new[1])])
		_label(ci, font, Vector2(box.get_center().x, box.end.y - fs * 1.2), "?", int(fs * 1.6), SHADE)


static func _shape(ci: CanvasItem, shape: String, c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	match shape:
		"circle":
			pts = _circle(c, s, 32)
		"square":
			pts = PackedVector2Array([c + Vector2(-s, -s) * 0.85, c + Vector2(s, -s) * 0.85, c + Vector2(s, s) * 0.85,
				c + Vector2(-s, s) * 0.85])
		"triangle":
			pts = PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.95, s * 0.75), c + Vector2(-s * 0.95, s * 0.75)])
		_:
			for i in 10:
				pts.append(c + Vector2.from_angle(-PI * 0.5 + PI * i / 5.0) * (s if i % 2 == 0 else s * 0.45))
	ci.draw_colored_polygon(pts, col)
	var ring := pts.duplicate()
	ring.append(pts[0])
	ci.draw_polyline(ring, INK, maxf(1.5, s * 0.08), true)


# --- art -------------------------------------------------------------------------------------------------------------

static func _draw_principle(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var w := minf(r.size.x, r.size.y * 1.7)
	var a := Rect2(r.get_center() - Vector2(w, r.size.y) * 0.5, Vector2(w, r.size.y))
	_rounded(ci, a, PAPER_WHITE, 8)
	var at := func(x: float, y: float) -> Vector2: return a.position + Vector2(x, y) * a.size
	var u := a.size.y
	var orange := SHADE
	var dark := Color("27407a")
	match str(d.show):
		"symmetry":
			for side: float in [-1.0, 1.0]:
				var fx := func(x: float) -> float: return 0.5 + side * (0.5 - x)
				_shape(ci, "triangle", at.call(fx.call(0.3), 0.58), u * 0.22, BLUE)
				_shape(ci, "circle", at.call(fx.call(0.36), 0.24), u * 0.1, orange)
				_shape(ci, "square", at.call(fx.call(0.16), 0.78), u * 0.08, Color("3aa845"))
			_dashed(ci, at.call(0.5, 0.04), at.call(0.5, 0.96), GREY, 2.0)
		"asymmetry":
			var beam_y := a.position.y + u * 0.8
			ci.draw_line(at.call(0.12, 0.8), at.call(0.88, 0.8), INK, 3.0)
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.5, 0.8), at.call(0.46, 0.95), at.call(0.54, 0.95)]), INK)
			ci.draw_rect(Rect2(Vector2(a.position.x + a.size.x * 0.26 - u * 0.2, beam_y - u * 0.42), Vector2(u * 0.4, u * 0.42)), dark)
			for k in 3:
				_shape(ci, "circle", at.call(0.64 + 0.09 * k, 0.8) - Vector2(0, u * 0.08), u * 0.07, orange)
			_shape(ci, "circle", at.call(0.73, 0.8) - Vector2(0, u * 0.22), u * 0.07, orange)
		"radial":
			var c: Vector2 = at.call(0.5, 0.5)
			for k in 16:
				var p := c + Vector2.from_angle(TAU * k / 16.0) * u * 0.42
				ci.draw_circle(p, u * 0.035, BLUE)
			for k in 8:
				var ang := TAU * k / 8.0
				_ellipse_rot(ci, c + Vector2.from_angle(ang) * u * 0.23, Vector2(u * 0.11, u * 0.05), ang, orange)
			ci.draw_circle(c, u * 0.1, dark)
		"contrast":
			ci.draw_rect(Rect2(a.position, Vector2(a.size.x * 0.5, a.size.y)), Color("15181f"))
			ci.draw_rect(Rect2(at.call(0.2, 0.36), Vector2(u * 0.24, u * 0.24)), Color.WHITE)
			ci.draw_circle(at.call(0.74, 0.5), u * 0.34, Color("15181f"))
		"emphasis":
			for k in 15:
				var p: Vector2 = at.call(0.12 + 0.19 * (k % 5), 0.2 + 0.3 * (k / 5))
				if k != 8:
					ci.draw_circle(p, u * 0.06, Color("b6bcc8"))
			var focus: Vector2 = at.call(0.69, 0.5)
			ci.draw_circle(focus, u * 0.2, Color(1, 0.8, 0.5, 0.5))
			ci.draw_circle(focus, u * 0.14, Color("e03a2f"))
		"rhythm":
			for row in 2:
				for k in 7:
					var p: Vector2 = at.call(0.1 + 0.13 * k, 0.3 + 0.4 * row)
					if k % 2 == row % 2:
						_shape(ci, "square", p, u * 0.11, BLUE)
					else:
						_shape(ci, "circle", p, u * 0.05, orange)
		"unity":
			var blues: Array[Color] = [Color("1d3f8f"), Color("3a7be8"), Color("7fb0f5"), Color("2b5cc0"), Color("a9c9f7"),
				Color("16306b")]
			var spots: Array[Vector2] = [Vector2(0.24, 0.34), Vector2(0.46, 0.3), Vector2(0.7, 0.34), Vector2(0.3, 0.72),
				Vector2(0.52, 0.7), Vector2(0.76, 0.72)]
			var kinds: Array[String] = ["circle", "square", "triangle", "star", "circle", "square"]
			for k in 6:
				_shape(ci, kinds[k], at.call(spots[k].x, spots[k].y), u * 0.13, blues[k])
		"variety":
			var cols: Array[Color] = [Color("e03a2f"), Color("3aa845"), ON, BLUE, Color("8a3fb8"), orange]
			var spots: Array[Vector2] = [Vector2(0.18, 0.3), Vector2(0.42, 0.24), Vector2(0.72, 0.3), Vector2(0.3, 0.72),
				Vector2(0.58, 0.66), Vector2(0.84, 0.72)]
			var kinds: Array[String] = ["circle", "star", "triangle", "square", "triangle", "circle"]
			var sizes: Array[float] = [0.14, 0.1, 0.18, 0.08, 0.12, 0.06]
			for k in 6:
				_shape(ci, kinds[k], at.call(spots[k].x, spots[k].y), u * sizes[k], cols[k])
		"movement":
			var pts := PackedVector2Array()
			for k in 41:
				var t := k / 40.0
				pts.append(at.call(0.06 + 0.88 * t, 0.5 + 0.32 * sin(t * TAU * 0.9 + 0.6)))
			ci.draw_polyline(pts, Color("7fb0f5"), maxf(3.0, u * 0.03), true)
			for k in 6:
				var t := (k + 0.5) / 6.0
				var p := at.call(0.06 + 0.88 * t, 0.5 + 0.32 * sin(t * TAU * 0.9 + 0.6)) as Vector2
				ci.draw_circle(p, u * (0.025 + 0.018 * k), orange)
		"pattern":
			for k in 18:
				var p: Vector2 = at.call(0.1 + 0.16 * (k % 6), 0.2 + 0.3 * (k / 6))
				var col := BLUE if (k % 6 + k / 6) % 2 == 0 else orange
				for q in 4:
					ci.draw_circle(p + Vector2.from_angle(TAU * q / 4.0) * u * 0.05, u * 0.035, col)
				ci.draw_circle(p, u * 0.03, ON)


static func _ellipse_rot(ci: CanvasItem, c: Vector2, radii: Vector2, angle: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(cos(t) * radii.x, sin(t) * radii.y).rotated(angle))
	ci.draw_colored_polygon(pts, col)


static func _dashed(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, lw: float, dash := 10.0) -> void:
	var n := maxi(1, int(a.distance_to(b) / dash))
	for k in n:
		if k % 2 == 0:
			ci.draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), col, lw)


static func _draw_illuminated(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var text := bool(d.get("text", true))
	var s := minf(r.size.y, r.size.x * (0.5 if text else 1.0))
	var box := Rect2(Vector2(r.position.x + (r.size.x * 0.06 if text else (r.size.x - s) * 0.5), r.get_center().y - s * 0.5),
		Vector2(s, s))
	if text:
		ci.draw_rect(r, Color("f3e7c9"))
	ci.draw_rect(box, GOLD)
	var inner := box.grow(-s * 0.07)
	ci.draw_rect(inner, Color("1d3f8f"))
	for k in 12:   # gold dots on the blue
		var p := inner.position + Vector2(fposmod(k * 0.37, 1.0), fposmod(k * 0.61 + 0.1, 1.0)) * inner.size
		ci.draw_circle(p, s * 0.012, GOLD)
	var vine := Color("3aa845")
	for corner in 4:
		var c := inner.position + Vector2(0.14 if corner % 2 == 0 else 0.86, 0.14 if corner < 2 else 0.86) * inner.size
		var pts := PackedVector2Array()
		for i in 13:
			var t := i / 12.0
			pts.append(c + Vector2.from_angle(TAU * t * 0.8 + corner) * s * 0.09 * (1.0 - t * 0.6))
		ci.draw_polyline(pts, vine, maxf(1.5, s * 0.018), true)
		_ellipse_rot(ci, c + Vector2.from_angle(corner * 1.6) * s * 0.07, Vector2(s * 0.035, s * 0.016), corner * 1.6, vine)
		ci.draw_circle(c, s * 0.022, Color("e03a2f"))
	var letter := str(d.letter)
	var fs := int(s * 0.62)
	var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base := box.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	ci.draw_string_outline(font, Vector2(box.get_center().x - w * 0.5, base), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		maxi(2, int(s * 0.04)), GOLD)
	ci.draw_string(font, Vector2(box.get_center().x - w * 0.5, base), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("c8302a"))
	if text:
		var x0 := box.end.x + r.size.x * 0.05
		var lines := 7
		for k in lines:
			var y := r.position.y + r.size.y * (0.12 + 0.12 * k)
			var end := r.end.x - r.size.x * (0.04 + 0.06 * float(k % 3))
			ci.draw_line(Vector2(x0, y), Vector2(end, y), Color("5a4a3a"), maxf(2.0, r.size.y * 0.025))
			for q in int((end - x0) / (r.size.y * 0.09)):   # the words' gaps
				var gx := x0 + (q + 0.5) * r.size.y * 0.09 + fposmod(k * 7.3 + q * 3.1, 1.0) * r.size.y * 0.03
				ci.draw_line(Vector2(gx, y - 2), Vector2(gx, y + 2), Color("f3e7c9"), maxf(2.0, r.size.y * 0.02))


## The star {n/k}'s points (outer, on the circle of `rad`) and the inner corners between them.
static func _star_points(c: Vector2, rad: float, n: int, k: int, turn := 0.0) -> PackedVector2Array:
	var inner := rad * cos(PI * k / n) / cos(PI * (k - 1) / n)
	var pts := PackedVector2Array()
	for i in 2 * n:
		var ang := -PI * 0.5 + turn + PI * i / n
		pts.append(c + Vector2.from_angle(ang) * (rad if i % 2 == 0 else inner))
	return pts


static func _star_step(n: int) -> int:
	return {6: 2, 8: 2, 10: 3, 12: 5}[n] as int


static func _draw_star_pattern(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var n := _int(d, "points", 8)
	var k := _star_step(n)
	var stage := _int(d, "stage", 3)
	if bool(d.get("tiled", false)):
		ci.draw_rect(r, Color("c96f3b"))
		var cell := minf(r.size.x / 4.0, r.size.y / 2.0)
		var o := r.get_center() - Vector2(4, 2) * cell * 0.5
		for i in 8:
			var c := o + Vector2((i % 4) + 0.5, (i / 4) + 0.5) * cell
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -cell * 0.5), c + Vector2(cell * 0.5, 0),
				c + Vector2(0, cell * 0.5), c + Vector2(-cell * 0.5, 0)]), Color("2c7a6b"))
			_filled_star(ci, c, cell * 0.46, n, k)
		return
	var rad := minf(r.size.x, r.size.y) * 0.44
	var c := r.get_center()
	var lw := maxf(1.5, rad * 0.015)
	if stage == 3:
		ci.draw_rect(Rect2(c - Vector2(rad, rad) * 1.08, Vector2(rad, rad) * 2.16), Color("c96f3b"))
		_filled_star(ci, c, rad, n, k)
		return
	ci.draw_arc(c, rad, 0.0, TAU, 64, GREY, lw, true)
	var outer: Array[Vector2] = []
	for i in n:
		outer.append(c + Vector2.from_angle(-PI * 0.5 + TAU * i / n) * rad)
	if stage == 2:
		for i in n:
			ci.draw_line(outer[i], outer[(i + k) % n], INK, lw * 1.4, true)
	for p in outer:
		ci.draw_circle(p, rad * 0.055, SHADE)
	ci.draw_circle(c, rad * 0.03, INK)


static func _filled_star(ci: CanvasItem, c: Vector2, rad: float, n: int, k: int) -> void:
	var pts := _star_points(c, rad, n, k)
	ci.draw_colored_polygon(pts, Color("1d3f8f"))
	var ring := pts.duplicate()
	ring.append(pts[0])
	ci.draw_polyline(ring, GOLD, maxf(2.0, rad * 0.06), true)
	var inner := rad * cos(PI * k / n) / cos(PI * (k - 1) / n)
	var mid := PackedVector2Array()
	for i in n:
		mid.append(c + Vector2.from_angle(-PI * 0.5 + PI / n + TAU * i / n) * inner * 0.55)
	ci.draw_colored_polygon(mid, Color("f3e7c9"))
	ci.draw_circle(c, inner * 0.22, Color("c8302a"))


static func _draw_ink(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var at := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var scroll := Rect2(at.call(0.32, 0.03), r.size * Vector2(0.36, 0.94))
	ci.draw_rect(Rect2(at.call(0.3, 0.0), r.size * Vector2(0.4, 0.03)), Color("6b4a2a"))
	ci.draw_rect(Rect2(at.call(0.3, 0.97), r.size * Vector2(0.4, 0.03)), Color("6b4a2a"))
	ci.draw_rect(scroll, SCROLL)
	var sx := scroll.position.x
	var sw := scroll.size.x
	var ridge := func(y0: float, peaks: Array, col: Color, depth: float) -> void:
		var pts := PackedVector2Array()
		pts.append(Vector2(sx, r.position.y + r.size.y * (y0 + depth)))
		for p: Vector2 in peaks:
			pts.append(Vector2(sx + sw * p.x, r.position.y + r.size.y * p.y))
		pts.append(Vector2(sx + sw, r.position.y + r.size.y * (y0 + depth)))
		ci.draw_colored_polygon(pts, col)
	ridge.call(0.3, [Vector2(0.0, 0.3), Vector2(0.18, 0.16), Vector2(0.34, 0.24), Vector2(0.5, 0.08), Vector2(0.66, 0.22),
		Vector2(0.82, 0.14), Vector2(1.0, 0.28)], Color("c9c3b6"), 0.1)
	ci.draw_rect(Rect2(Vector2(sx, r.position.y + r.size.y * 0.34), Vector2(sw, r.size.y * 0.12)), Color("f7f1e2"))
	ridge.call(0.8, [Vector2(0.0, 0.5), Vector2(0.14, 0.46), Vector2(0.3, 0.56), Vector2(0.46, 0.48), Vector2(0.62, 0.66),
		Vector2(0.72, 0.8)], Color("4d4a45"), 0.0)
	for k in 5:   # pines on the near mountains
		var base: Vector2 = at.call(0.35 + 0.035 * k, 0.56 + 0.02 * (k % 2))
		ci.draw_line(base, base - Vector2(0, r.size.y * 0.08), Color("2a2724"), 2.0)
		for q in 3:
			var y := base.y - r.size.y * (0.03 + 0.025 * q)
			ci.draw_line(Vector2(base.x - r.size.y * 0.025, y), Vector2(base.x + r.size.y * 0.025, y), Color("2a2724"), 2.5)
	ci.draw_rect(Rect2(Vector2(sx, r.position.y + r.size.y * 0.84), Vector2(sw, r.size.y * 0.13)), Color("d9dcd6"))
	for k in 3:
		var y := r.position.y + r.size.y * (0.87 + 0.035 * k)
		ci.draw_line(Vector2(sx + sw * 0.15, y), Vector2(sx + sw * 0.55, y), Color("a3aaa4"), 1.5)
	var path_a: Vector2 = at.call(0.52, 0.8)
	var path_b: Vector2 = at.call(0.62, 0.7)
	ci.draw_line(path_a, path_b, Color("b8ad96"), 3.0)
	var tv: Vector2 = INK_PARTS["traveller"] * r.size + r.position
	ci.draw_line(tv, tv + Vector2(0, r.size.y * 0.03), Color("2a2724"), 2.0)
	ci.draw_circle(tv - Vector2(0, r.size.y * 0.008), r.size.y * 0.012, Color("c8302a"))
	for k in 4:   # the poem: a column of characters, and the red seal under it
		var p: Vector2 = at.call(0.625, 0.1 + 0.05 * k)
		ci.draw_rect(Rect2(p - Vector2(r.size.y * 0.014, r.size.y * 0.014), Vector2(r.size.y * 0.028, r.size.y * 0.028)),
			Color("3b3833"))
	ci.draw_rect(Rect2(at.call(0.61, 0.32), Vector2(r.size.y * 0.035, r.size.y * 0.035)), Color("c8302a"))
	var fs := _fs(r, 0.075, 16)
	var mark := str(d.get("mark", ""))
	for part: String in INK_PARTS:
		var p: Vector2 = r.position + (INK_PARTS[part] as Vector2) * r.size
		if part == mark:
			_ring(ci, p, r.size.y * 0.07, SHADE, 3.0)
		if bool(d.get("labels", false)):
			var left: bool = (INK_PARTS[part] as Vector2).x < 0.55 and part != "water"
			var tx := r.position.x + r.size.x * (0.15 if left else 0.85)
			var tfs := _fit(font, part, fs, r.size.x * 0.27)
			_label(ci, font, Vector2(tx, p.y), part, tfs, SHADE if part == mark else INK)
			var edge := tx + (1.0 if left else -1.0) * font.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x * 0.55
			ci.draw_line(Vector2(edge, p.y), p, GREY, 1.5)
			ci.draw_circle(p, 3.0, INK)


## The tiles of a tessellation: [polygon, colour index] covering `r` (and a little beyond; the drawing clips them).
static func _tile_polygons(shape: String, r: Rect2, s: float) -> Array:
	var out: Array = []
	var cols := int(r.size.x / s) + 3
	var rows := int(r.size.y / s) + 3
	var o := r.position - Vector2(s, s)
	match shape:
		"square":
			for j in rows:
				for i in cols:
					var p := o + Vector2(i, j) * s
					out.append([PackedVector2Array([p, p + Vector2(s, 0), p + Vector2(s, s), p + Vector2(0, s)]), (i + j) % 2])
		"brick":
			for j in rows:
				for i in cols / 2 + 2:
					var p := o + Vector2(i * 2.0 * s - (s if j % 2 == 1 else 0.0), j * s)
					out.append([PackedVector2Array([p, p + Vector2(2.0 * s, 0), p + Vector2(2.0 * s, s), p + Vector2(0, s)]),
						(i + j) % 2])
		"triangle":
			var h := s * sqrt(3.0) / 2.0
			for j in int(r.size.y / h) + 3:
				for i in cols * 2:
					var x := o.x + i * s * 0.5
					var y := o.y + j * h
					var up := (i + j) % 2 == 0
					var tri := PackedVector2Array([Vector2(x, y + h), Vector2(x + s * 0.5, y), Vector2(x + s, y + h)]) if up \
						else PackedVector2Array([Vector2(x, y), Vector2(x + s, y), Vector2(x + s * 0.5, y + h)])
					out.append([tri, 0 if up else 1])
		"hexagon":
			var rad := s * 0.6
			var w := sqrt(3.0) * rad
			for j in int(r.size.y / (1.5 * rad)) + 3:
				for i in int(r.size.x / w) + 3:
					var c := o + Vector2(i * w + (w * 0.5 if j % 2 == 1 else 0.0), j * 1.5 * rad)
					var hex := PackedVector2Array()
					for q in 6:
						hex.append(c + Vector2.from_angle(PI / 6.0 + TAU * q / 6.0) * rad)
					out.append([hex, (i + j * 2) % 3])
		"rhombus":
			var b := Vector2(s * 0.5, s * sqrt(3.0) / 2.0)
			for j in int(r.size.y / b.y) + 3:
				for i in cols + 4:
					var p := o + Vector2(i * s, 0) + b * j - Vector2(j * s * 0.5 + s, 0)
					out.append([PackedVector2Array([p, p + Vector2(s, 0), p + Vector2(s, 0) + b, p + b]), (i + j) % 2])
		"octagon":
			var t := s / (1.0 + sqrt(2.0))
			for j in rows:
				for i in cols:
					var c := o + Vector2(i, j) * s
					var oct := PackedVector2Array()
					for q in 8:
						oct.append(c + Vector2.from_angle(PI / 8.0 + TAU * q / 8.0) * (s * 0.5 / cos(PI / 8.0)))
					out.append([oct, 0])
					var sq := c + Vector2(s * 0.5, s * 0.5)
					out.append([PackedVector2Array([sq + Vector2(0, -t / sqrt(2.0)), sq + Vector2(t / sqrt(2.0), 0),
						sq + Vector2(0, t / sqrt(2.0)), sq + Vector2(-t / sqrt(2.0), 0)]), 1])
		"pentagon":
			for j in rows:
				for i in cols:
					var c := o + Vector2(i, j) * s + Vector2(s * 0.5, s * 0.5)
					var pent := PackedVector2Array()
					for q in 5:
						pent.append(c + Vector2.from_angle(-PI * 0.5 + TAU * q / 5.0) * s * 0.52)
					out.append([pent, (i + j) % 2])
		_:
			for j in rows:
				for i in cols:
					out.append([_circle(o + Vector2(i, j) * s + Vector2(s * 0.5, s * 0.5), s * 0.5, 32), (i + j) % 2])
	return out


static func _draw_tiles(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var shape := str(d.shape)
	var names: Array = d.get("colours", ["blue", "yellow", "red"])
	var cols: Array[Color] = []
	for c: Variant in names:
		cols.append(SchoolPictureArts.COLOURS[str(c)])
	while cols.size() < 3:
		cols.append(cols[cols.size() % 2])
	var gaps := shape in ["pentagon", "circle"]
	ci.draw_rect(r, Color.WHITE if gaps else INK)
	var frame := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var s := r.size.y / (3.4 if shape != "brick" else 4.2)
	for t: Array in _tile_polygons(shape, r, s):
		for piece in Geometry2D.intersect_polygons(t[0], frame):
			ci.draw_colored_polygon(piece, cols[int(t[1]) % cols.size()])
			var ring := piece.duplicate()
			ring.append(piece[0])
			ci.draw_polyline(ring, INK, 2.0, true)
	if gaps:   # the gaps between the tiles: hatched, so they show
		ci.draw_rect(r, INK, false, 2.0)


static func _motif(motif: String, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match motif:
		"petal":
			for i in 21:
				var t := i / 20.0
				pts.append(Vector2(sin(t * PI) * rad * 0.2, -rad * (0.2 + 0.8 * t)))
			for i in range(19, 0, -1):
				var t := i / 20.0
				pts.append(Vector2(-sin(t * PI) * rad * 0.2, -rad * (0.2 + 0.8 * t)))
		"leaf":
			for i in 21:
				var t := i / 20.0
				pts.append(Vector2(sin(t * PI) * rad * 0.26, -rad * (0.18 + 0.82 * t)))
			for i in range(19, 0, -1):
				var t := i / 20.0
				pts.append(Vector2(-sin(t * PI) * rad * 0.06, -rad * (0.18 + 0.82 * t)))
		"hook":
			for i in 25:
				var t := i / 24.0
				var a := -PI * 0.5 + t * PI * 1.2
				pts.append(Vector2(0, -rad * 0.6) + Vector2.from_angle(a) * rad * (0.38 - 0.1 * t))
			for i in range(24, -1, -1):
				var t := i / 24.0
				var a := -PI * 0.5 + t * PI * 1.2
				pts.append(Vector2(0, -rad * 0.6) + Vector2.from_angle(a) * rad * (0.24 - 0.12 * t))
		"drop":
			for i in 25:
				var a := TAU * i / 24.0
				var p := Vector2(cos(a), sin(a)) * rad * 0.2
				if sin(a) < 0:
					p.y *= 2.6
				pts.append(p + Vector2(0, -rad * 0.5))
		_:
			pts = PackedVector2Array([Vector2(-rad * 0.04, -rad * 0.2), Vector2(rad * 0.04, -rad * 0.2),
				Vector2(rad * 0.04, -rad * 0.66), Vector2(rad * 0.4, -rad * 0.8), Vector2(rad * 0.04, -rad * 0.96),
				Vector2(-rad * 0.04, -rad * 1.0)])
	return pts


static func _draw_rotation(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var order := _int(d, "order", 4)
	var rad := minf(r.size.x, r.size.y) * 0.48
	var c := r.get_center()
	var base := _motif(str(d.motif), rad)
	for i in order:
		var turned := PackedVector2Array()
		for p in base:
			turned.append(c + p.rotated(TAU * i / order))
		var col := SHADE if i == 0 and bool(d.get("mark", false)) else (BLUE if i % 2 == 0 else Color("2b5cc0"))
		ci.draw_colored_polygon(turned, col)
		var ring := turned.duplicate()
		ring.append(turned[0])
		ci.draw_polyline(ring, INK, 1.5, true)
	if bool(d.get("centre", true)):
		ci.draw_circle(c, rad * 0.05, INK)


## Where two-point perspective puts things in `r`: the vanishing points, the near edge's top and bottom, the side faces'
## far corners, and the top face's back corner (seen from above) or the bottom face's (from below).
static func _two_point_geometry(r: Rect2, eye: String) -> Dictionary:
	var hy := r.position.y + r.size.y * ({"above": 0.16, "level": 0.5, "below": 0.84}[eye] as float)
	var box_top := r.position.y + r.size.y * ({"above": 0.4, "level": 0.24, "below": 0.26}[eye] as float)
	var box_bottom := r.position.y + r.size.y * ({"above": 0.76, "level": 0.76, "below": 0.62}[eye] as float)
	var vl := Vector2(r.position.x + r.size.x * 0.03, hy)
	var vr := Vector2(r.end.x - r.size.x * 0.03, hy)
	var xc := r.position.x + r.size.x * 0.46
	var top := Vector2(xc, box_top)
	var bottom := Vector2(xc, box_bottom)
	var xl := xc - r.size.x * 0.2
	var xr := xc + r.size.x * 0.24
	var on := func(p: Vector2, v: Vector2, x: float) -> Vector2: return p + (v - p) * ((x - p.x) / (v.x - p.x))
	var g := {"vl": vl, "vr": vr, "top": top, "bottom": bottom, "lt": on.call(top, vl, xl), "lb": on.call(bottom, vl, xl),
		"rt": on.call(top, vr, xr), "rb": on.call(bottom, vr, xr), "hy": hy}
	var back_of := func(a: Vector2, b: Vector2) -> Vector2:
		var hit: Variant = Geometry2D.line_intersects_line(a, vr - a, b, vl - b)
		return hit if hit is Vector2 else a
	g["back_top"] = back_of.call(g.lt, g.rt)
	g["back_bottom"] = back_of.call(g.lb, g.rb)
	return g


static func _draw_two_point(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var eye := str(d.eye)
	var g := _two_point_geometry(r, eye)
	var mark := str(d.get("mark", ""))
	var fs := _fs(r, 0.085, 17)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, float(g.hy) - r.position.y)), Color("e3f0fb"))
	ci.draw_rect(Rect2(Vector2(r.position.x, g.hy), Vector2(r.size.x, r.end.y - float(g.hy))), Color("eef3e6"))
	if bool(d.get("lines", false)):   # every edge that goes back runs to a vanishing point
		for key: String in ["top", "bottom"]:
			_dashed(ci, g[key], g.vl, GREY, 1.5, 8.0)
			_dashed(ci, g[key], g.vr, GREY, 1.5, 8.0)
		for pair: Array in [["lt", "vr"], ["rt", "vl"], ["lb", "vr"], ["rb", "vl"]]:
			_dashed(ci, g[pair[0]], g[pair[1]], GREY, 1.0, 6.0)
	# a box in cool greys, so an orange mark stands out on it
	ci.draw_colored_polygon(PackedVector2Array([g.lt, g.top, g.bottom, g.lb]), Color("c9d6ea"))
	ci.draw_colored_polygon(PackedVector2Array([g.top, g.rt, g.rb, g.bottom]), Color("93a8c9"))
	if eye == "above":
		ci.draw_colored_polygon(PackedVector2Array([g.top, g.lt, g.back_top, g.rt]), Color("e8eef8"))
	elif eye == "below":
		ci.draw_colored_polygon(PackedVector2Array([g.bottom, g.lb, g.back_bottom, g.rb]), Color("6f84a8"))
	for pair: Array in [["lt", "top"], ["top", "rt"], ["rt", "rb"], ["rb", "bottom"], ["bottom", "lb"], ["lb", "lt"],
			["top", "bottom"]]:
		ci.draw_line(g[pair[0]], g[pair[1]], INK, 2.0, true)
	if eye == "above":
		ci.draw_polyline(PackedVector2Array([g.lt, g.back_top, g.rt]), INK, 2.0, true)
	elif eye == "below":
		ci.draw_polyline(PackedVector2Array([g.lb, g.back_bottom, g.rb]), INK, 2.0, true)
	ci.draw_line(Vector2(r.position.x, g.hy), Vector2(r.end.x, g.hy), SHADE if mark == "horizon" else BLUE,
		4.0 if mark == "horizon" else 2.0)
	for side: String in ["vl", "vr"]:
		var p: Vector2 = g[side]
		var marked := (mark == "left vp" and side == "vl") or (mark == "right vp" and side == "vr")
		ci.draw_circle(p, 7.0 if marked else 5.0, SHADE if marked else INK)
		if marked:
			_ring(ci, p, 14.0, SHADE, 3.0)
		if bool(d.get("labels", false)):
			var above := float(g.hy) > r.position.y + fs * 2.0
			_label(ci, font, p + Vector2(fs * (1.3 if side == "vl" else -1.3), -fs * 0.9 if above else fs * 0.9), "VP", fs)
	if mark == "near edge":
		ci.draw_line(g.top, g.bottom, SHADE, 7.0)
	if bool(d.get("labels", false)):
		var hx := r.position.x + r.size.x * 0.13
		var below_hy := float(g.hy) + fs * 0.8 if float(g.hy) < r.end.y - fs * 1.5 else float(g.hy) - fs * 0.8
		_label(ci, font, Vector2(hx, below_hy), "horizon", fs, BLUE)


## A face showing `feeling`: eyebrows, eyes and mouth.
static func _feeling_face(ci: CanvasItem, c: Vector2, rad: float, feeling: String) -> void:
	ci.draw_circle(c, rad, Color("f6c89f"))
	_ring(ci, c, rad, INK, maxf(1.5, rad * 0.05))
	var lw := maxf(2.0, rad * 0.07)
	var ex := rad * 0.36
	var ey := c.y - rad * 0.12
	for side: float in [-1.0, 1.0]:
		var e := Vector2(c.x + side * ex, ey)
		var brow_in := e + Vector2(-side * rad * 0.16, -rad * 0.26)
		var brow_out := e + Vector2(side * rad * 0.18, -rad * 0.26)
		match feeling:
			"anger":
				brow_in.y += rad * 0.12
				brow_out.y -= rad * 0.06
			"sadness", "fear":
				brow_in.y -= rad * 0.1
				brow_out.y += rad * 0.06
			"surprise":
				brow_in.y -= rad * 0.14
				brow_out.y -= rad * 0.14
		ci.draw_line(brow_in, brow_out, INK, lw, true)
		match feeling:
			"joy":
				ci.draw_arc(e + Vector2(0, rad * 0.04), rad * 0.1, PI, TAU, 10, INK, lw, true)
			"calm":
				ci.draw_arc(e - Vector2(0, rad * 0.04), rad * 0.1, 0.0, PI, 10, INK, lw, true)
			"surprise", "fear":
				ci.draw_circle(e, rad * 0.12, Color.WHITE)
				_ring(ci, e, rad * 0.12, INK, lw * 0.6)
				ci.draw_circle(e, rad * 0.05, INK)
			_:
				ci.draw_circle(e, rad * 0.06, INK)
	var m := Vector2(c.x, c.y + rad * 0.42)
	match feeling:
		"joy":
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-rad * 0.36, -rad * 0.08), m + Vector2(rad * 0.36, -rad * 0.08),
				m + Vector2(rad * 0.2, rad * 0.16), m + Vector2(0, rad * 0.22), m + Vector2(-rad * 0.2, rad * 0.16)]), Color("b8342c"))
		"sadness":
			ci.draw_arc(m + Vector2(0, rad * 0.16), rad * 0.24, PI * 1.15, PI * 1.85, 12, INK, lw, true)
		"anger":
			ci.draw_rect(Rect2(m + Vector2(-rad * 0.26, -rad * 0.06), Vector2(rad * 0.52, rad * 0.14)), Color.WHITE)
			ci.draw_rect(Rect2(m + Vector2(-rad * 0.26, -rad * 0.06), Vector2(rad * 0.52, rad * 0.14)), INK, false, lw * 0.7)
		"surprise":
			SchoolPictureG4Arts._ellipse(ci, m, Vector2(rad * 0.12, rad * 0.17), Color("5a1f1a"))
		"fear":
			var pts := PackedVector2Array()
			for i in 9:
				pts.append(m + Vector2(-rad * 0.26 + rad * 0.065 * i, (rad * 0.05 if i % 2 == 0 else -rad * 0.05)))
			ci.draw_polyline(pts, INK, lw, true)
		_:
			ci.draw_arc(m - Vector2(0, rad * 0.14), rad * 0.2, PI * 0.25, PI * 0.75, 10, INK, lw, true)


static func _draw_feeling(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var feeling := str(d.feeling)
	if bool(d.get("colour", false)):
		var bg := {"joy": Color("ffd166"), "sadness": Color("8fb3e0"), "anger": Color("e8574a"), "fear": Color("6c5b8f"),
			"surprise": Color("f7a1c4"), "calm": Color("a8dcc4")}[feeling] as Color
		_rounded(ci, r, bg, 10)
	if not bool(d.get("body", false)):
		_feeling_face(ci, r.get_center(), minf(r.size.x, r.size.y) * 0.42, feeling)
		return
	var h := r.size.y
	var lw := maxf(4.0, h * 0.06)
	var hip := r.get_center() + Vector2(0, h * 0.18)
	var neck := hip - Vector2(0, h * 0.34)
	var head_r := h * 0.15
	var lean := {"joy": 0.0, "sadness": 0.18, "anger": 0.12, "fear": -0.1, "surprise": -0.14, "calm": 0.0}[feeling] as float
	neck += Vector2(lean * h * 0.4, lean * h * 0.08 if feeling == "sadness" else 0.0)
	var head := neck + Vector2(lean * h * 0.3, -head_r * (0.7 if feeling == "sadness" else 1.1))
	var body := Color("27407a")
	ci.draw_line(hip, neck, body, lw, true)
	var legs := {"joy": [Vector2(-0.14, 0.26), Vector2(0.14, 0.26)], "sadness": [Vector2(-0.05, 0.3), Vector2(0.05, 0.3)],
		"anger": [Vector2(-0.12, 0.3), Vector2(0.14, 0.3)], "fear": [Vector2(-0.12, 0.28), Vector2(0.02, 0.3)],
		"surprise": [Vector2(-0.1, 0.3), Vector2(0.12, 0.3)], "calm": [Vector2(-0.06, 0.3), Vector2(0.06, 0.3)]}[feeling] as Array
	for l: Vector2 in legs:
		ci.draw_line(hip, hip + l * h, body, lw, true)
	var shoulder := neck.lerp(hip, 0.12)
	var arms := {"joy": [Vector2(-0.22, -0.26), Vector2(0.22, -0.26)], "sadness": [Vector2(-0.04, 0.26), Vector2(0.1, 0.26)],
		"anger": [Vector2(-0.16, 0.02), Vector2(0.18, 0.04)], "fear": [Vector2(0.1, -0.2), Vector2(0.16, -0.16)],
		"surprise": [Vector2(-0.26, -0.12), Vector2(0.26, -0.12)], "calm": [Vector2(-0.1, 0.22), Vector2(0.1, 0.22)]}[feeling] as Array
	for arm: Vector2 in arms:
		var elbow := shoulder + arm * h * 0.55 + Vector2(0, h * 0.04 if feeling == "anger" else 0.0)
		ci.draw_line(shoulder, elbow, body, lw, true)
		ci.draw_line(elbow, shoulder + arm * h, body, lw, true)
		ci.draw_circle(shoulder + arm * h, lw * (0.9 if feeling == "anger" else 0.6), Color("f6c89f"))
	_feeling_face(ci, head, head_r, feeling)


static func _draw_print_layers(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var layers: Array = d.layers
	var steps := str(d.get("view", "steps")) == "steps"
	var n := layers.size() if steps else 1
	var fs := _fs(r, 0.1, 18)
	var gap := r.size.x * 0.03
	var pw := minf((r.size.x - gap * (n - 1)) / n, (r.size.y - fs * 1.6) * 1.2)
	var ph := pw / 1.2
	var x0 := r.position.x + (r.size.x - (pw * n + gap * (n - 1))) * 0.5
	var y0 := r.position.y + (r.size.y - fs * 1.6 - ph) * 0.5
	for k in n:
		var paper := Rect2(Vector2(x0 + k * (pw + gap), y0), Vector2(pw, ph))
		ci.draw_rect(paper, PAPER_WHITE)
		ci.draw_rect(paper, GREY, false, 1.5)
		var upto := k if steps else layers.size() - 1
		for li in upto + 1:
			_print_layer(ci, paper.grow(-pw * 0.07), li, SchoolPictureArts.COLOURS[str(layers[li])])
		if steps:
			var t := "layer %d" % (k + 1)
			_label(ci, font, Vector2(paper.get_center().x, paper.end.y + fs * 0.9), t, _fit(font, t, fs, pw))


## A layered print's layer `li` in its colour: the background, then the hills and the sun, then a tree and a house,
## then the details.
static func _print_layer(ci: CanvasItem, b: Rect2, li: int, col: Color) -> void:
	var at := func(x: float, y: float) -> Vector2: return b.position + Vector2(x, y) * b.size
	match li:
		0:
			ci.draw_rect(b, col)
		1:
			ci.draw_circle(at.call(0.8, 0.24), b.size.y * 0.14, col)
			var hill := PackedVector2Array()
			for i in 21:
				var t := i / 20.0
				hill.append(at.call(t, 0.72 - 0.16 * sin(t * PI * 1.4)))
			hill.append(at.call(1.0, 1.0))
			hill.append(at.call(0.0, 1.0))
			ci.draw_colored_polygon(hill, col)
		2:
			ci.draw_rect(Rect2(at.call(0.2, 0.5), b.size * Vector2(0.26, 0.3)), col)
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.16, 0.5), at.call(0.33, 0.32), at.call(0.5, 0.5)]), col)
			ci.draw_rect(Rect2(at.call(0.68, 0.5), b.size * Vector2(0.04, 0.26)), col)
			ci.draw_circle(at.call(0.7, 0.46), b.size.y * 0.13, col)
		_:
			ci.draw_rect(Rect2(at.call(0.29, 0.62), b.size * Vector2(0.08, 0.18)), col)
			ci.draw_rect(Rect2(at.call(0.22, 0.56), b.size * Vector2(0.05, 0.06)), col)
			ci.draw_rect(Rect2(at.call(0.39, 0.56), b.size * Vector2(0.05, 0.06)), col)
			for k in 2:
				var bird: Vector2 = at.call(0.5 + 0.1 * k, 0.2 + 0.06 * k)
				ci.draw_polyline(PackedVector2Array([bird - Vector2(b.size.x * 0.03, 0), bird + Vector2(0, b.size.y * 0.02),
					bird + Vector2(b.size.x * 0.03, 0)]), col, 2.0, true)
			ci.draw_rect(Rect2(at.call(0.0, 0.94), b.size * Vector2(1.0, 0.06)), col)


## Each capital as strokes from point to point in a box 1 high (x from 0 to its width).
const STROKES := {
	"A": [[Vector2(0, 1), Vector2(0.45, 0)], [Vector2(0.45, 0), Vector2(0.9, 1)], [Vector2(0.2, 0.62), Vector2(0.7, 0.62)]],
	"E": [[Vector2(0, 0), Vector2(0, 1)], [Vector2(0, 0), Vector2(0.6, 0)], [Vector2(0, 0.5), Vector2(0.5, 0.5)],
		[Vector2(0, 1), Vector2(0.6, 1)]],
	"F": [[Vector2(0, 0), Vector2(0, 1)], [Vector2(0, 0), Vector2(0.6, 0)], [Vector2(0, 0.5), Vector2(0.5, 0.5)]],
	"H": [[Vector2(0, 0), Vector2(0, 1)], [Vector2(0.75, 0), Vector2(0.75, 1)], [Vector2(0, 0.5), Vector2(0.75, 0.5)]],
	"I": [[Vector2(0, 0), Vector2(0, 1)]],
	"K": [[Vector2(0, 0), Vector2(0, 1)], [Vector2(0.65, 0), Vector2(0, 0.6)], [Vector2(0.22, 0.42), Vector2(0.7, 1)]],
	"L": [[Vector2(0, 0), Vector2(0, 1)], [Vector2(0, 1), Vector2(0.6, 1)]],
	"M": [[Vector2(0, 1), Vector2(0, 0)], [Vector2(0, 0), Vector2(0.45, 0.7)], [Vector2(0.45, 0.7), Vector2(0.9, 0)],
		[Vector2(0.9, 0), Vector2(0.9, 1)]],
	"N": [[Vector2(0, 1), Vector2(0, 0)], [Vector2(0, 0), Vector2(0.75, 1)], [Vector2(0.75, 1), Vector2(0.75, 0)]],
	"T": [[Vector2(0, 0), Vector2(0.8, 0)], [Vector2(0.4, 0), Vector2(0.4, 1)]],
	"V": [[Vector2(0, 0), Vector2(0.42, 1)], [Vector2(0.42, 1), Vector2(0.84, 0)]],
	"W": [[Vector2(0, 0), Vector2(0.25, 1)], [Vector2(0.25, 1), Vector2(0.5, 0.3)], [Vector2(0.5, 0.3), Vector2(0.75, 1)],
		[Vector2(0.75, 1), Vector2(1.0, 0)]],
	"X": [[Vector2(0, 0), Vector2(0.75, 1)], [Vector2(0.75, 0), Vector2(0, 1)]],
	"Y": [[Vector2(0, 0), Vector2(0.4, 0.5)], [Vector2(0.8, 0), Vector2(0.4, 0.5)], [Vector2(0.4, 0.5), Vector2(0.4, 1)]],
	"Z": [[Vector2(0, 0), Vector2(0.7, 0)], [Vector2(0.7, 0), Vector2(0, 1)], [Vector2(0, 1), Vector2(0.7, 1)]]}


static func _letter_width(ch: String) -> float:
	var w := 0.0
	for s: Array in STROKES[ch]:
		w = maxf(w, maxf((s[0] as Vector2).x, (s[1] as Vector2).x))
	return w


static func _draw_stroke_letters(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var text := str(d.text)
	var serif := bool(d.get("serif", false))
	var contrast := bool(d.get("contrast", false))
	var mono := bool(d.get("monogram", false))
	var h := r.size.y * 0.66
	var gap := h * (0.45 if serif else 0.3)
	var width := 0.0
	for ch in text:
		width += _letter_width(ch) * h + gap
	width -= gap
	if not mono and width > r.size.x * 0.92:
		h *= r.size.x * 0.92 / width
		gap = h * (0.45 if serif else 0.3)
		width = r.size.x * 0.92
	var base := h * 0.1
	var top := r.get_center().y - h * 0.5
	if bool(d.get("guides", false)):
		for y: float in [top, top + h]:
			ci.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("9fc1ee"), 1.5)
	var x := r.get_center().x - (width if not mono else _letter_width(text[0]) * h) * 0.5
	for i in text.length():
		var ch := text[i]
		var col := INK
		var o := Vector2(x, top)
		if mono:
			col = BLUE if i == 0 else SHADE
			o = Vector2(r.get_center().x - _letter_width(ch) * h * 0.5 + (h * 0.12 if i == 1 else -h * 0.12), top)
		_stroke_letter(ci, ch, o, h, base, serif, contrast, col)
		x += _letter_width(ch) * h + gap


static func _stroke_letter(ci: CanvasItem, ch: String, o: Vector2, h: float, base: float, serif: bool, contrast: bool,
		col: Color) -> void:
	var strokes: Array = STROKES[ch]
	var ends := {}
	for s: Array in strokes:
		for p: Vector2 in s:
			ends[p] = int(ends.get(p, 0)) + 1
	for s: Array in strokes:
		var a := o + (s[0] as Vector2) * h
		var b := o + (s[1] as Vector2) * h
		var w := base
		if contrast:   # a broad nib held at 25°: a stroke along the nib is thin, across it thick
			var ang := (b - a).angle()
			w = base * (0.15 + 1.6 * pow(absf(sin(ang - deg_to_rad(-25.0))), 2.0))
		ci.draw_line(a, b, col, w, true)
		ci.draw_circle(a, w * 0.5, col)
		ci.draw_circle(b, w * 0.5, col)
		if serif:
			for p: Vector2 in s:
				if int(ends[p]) > 1:
					continue
				var at := o + p * h
				var flat := absf((s[1] as Vector2).y - (s[0] as Vector2).y) < 0.01
				if flat:
					ci.draw_line(at + Vector2(0, -base * 1.1), at + Vector2(0, base * 1.1), col, base * 0.45)
				elif p.y < 0.01 or p.y > 0.99:
					ci.draw_line(at + Vector2(-base * 1.5, 0), at + Vector2(base * 1.5, 0), col, base * 0.45)


## The guide lines' heights in `r` and the word's font size.
static func _guides_geometry(r: Rect2) -> Dictionary:
	var fs := r.size.y * 0.62
	var baseline := r.position.y + r.size.y * 0.7
	var g := {"size": fs}
	for k: String in GUIDE_AT:
		g[k] = baseline - float(GUIDE_AT[k]) * fs
	return g


static func _draw_guides(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var g := _guides_geometry(r)
	var fs := int(g.size)
	var mark := str(d.get("mark", ""))
	var lfs := _fs(r, 0.075, 16)
	var labels := bool(d.get("labels", false))
	var right := r.end.x - (r.size.x * 0.26 if labels else 0.0)
	var cols := {"ascender line": Color("9fc1ee"), "x-height": Color("e05a4f"), "baseline": INK, "descender line": Color("9fc1ee")}
	for k: String in GUIDES:
		var y := float(g[k])
		ci.draw_line(Vector2(r.position.x, y), Vector2(right, y), SHADE if k == mark else cols[k], 4.0 if k == mark else 2.0)
		if labels:
			_label(ci, font, Vector2(right + r.size.x * 0.13, y), k, _fit(font, k, lfs, r.size.x * 0.25), SHADE if k == mark else INK)
	var word := str(d.word)
	var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := r.position.x + ((right - r.position.x) - w) * 0.5 + r.size.x * 0.06
	ci.draw_string(font, Vector2(x, g.baseline), word, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("27407a"))


## A number from 0 to 1 that looks random but is the same every time for `i` (the land art's stones and leaves).
static func _jitter(i: int, salt := 0.0) -> float:
	return fposmod(sin(i * 12.9898 + salt * 78.233) * 43758.5453, 1.0)


static func _draw_land_art(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var design := str(d.design)
	var material := str(d.material)
	var ground := {"stones": Color("8cc56a"), "leaves": Color("7fb85c"), "sticks": Color("e2cc98"), "petals": Color("6fae55")}[material] as Color
	_rounded(ci, r, ground, 10)
	for k in 40:   # grass or sand texture
		var p := r.position + Vector2(_jitter(k, 1.0), _jitter(k, 2.0)) * r.size
		ci.draw_line(p, p + Vector2(2, -5), ground.darkened(0.15), 1.5)
	var c := r.get_center()
	var rad := minf(r.size.x, r.size.y) * 0.44
	var spots: Array = []   # [position, direction angle, size, shade 0-1]
	match design:
		"spiral":
			var th := 0.6
			while th < 5.6 * PI:
				var rr := rad * th / (5.6 * PI)
				var p := c + Vector2.from_angle(th) * rr
				spots.append([p, th + PI * 0.5, rad * 0.07, th / (5.6 * PI)])
				th += (rad * 0.13) / maxf(rr, rad * 0.15)
		"circle":
			for k in 22:
				var a := TAU * k / 22.0
				spots.append([c + Vector2.from_angle(a) * rad * 0.8, a + PI * 0.5, rad * 0.08, k / 22.0])
		"rings":
			for ring in 3:
				var n := 8 + ring * 7
				for k in n:
					var a := TAU * k / n
					spots.append([c + Vector2.from_angle(a) * rad * (0.3 + 0.3 * ring), a + PI * 0.5, rad * 0.07, ring / 2.0])
		"line":
			for k in 22:
				var t := k / 21.0
				var p := Vector2(r.position.x + r.size.x * (0.05 + 0.9 * t), c.y + sin(t * TAU) * r.size.y * 0.25)
				spots.append([p, atan2(cos(t * TAU) * r.size.y * 0.25 * TAU, r.size.x * 0.9), rad * 0.08, t])
		"mandala":
			spots.append([c, 0.0, rad * 0.1, 0.0])
			for ring in 3:
				var n := 6 * (ring + 1)
				for k in n:
					var a := TAU * k / n + ring * 0.2
					spots.append([c + Vector2.from_angle(a) * rad * (0.28 + 0.3 * ring), a, rad * (0.08 - 0.01 * ring),
						float(ring % 2)])
		_:
			ci.draw_circle(c, rad * 0.98, Color("f2c12e"))
			for k in 18:
				var a := TAU * k / 18.0
				_ellipse_rot(ci, c + Vector2.from_angle(a) * rad * 0.98, Vector2(rad * 0.2, rad * 0.07), a, Color("f7d21e"))
			ci.draw_circle(c, rad * 0.8, Color("5a3a1e"))
			var golden := deg_to_rad(137.508)
			for k in 200:
				var p := c + Vector2.from_angle(k * golden) * rad * 0.78 * sqrt(k / 200.0)
				ci.draw_circle(p, rad * 0.028, Color("c28a3a") if k % 2 == 0 else Color("8a5a2a"))
			return
	for i in spots.size():
		var s: Array = spots[i]
		_natural(ci, material, s[0], float(s[1]), float(s[2]), float(s[3]), i)


## One stone, leaf, stick or petal of land art.
static func _natural(ci: CanvasItem, material: String, p: Vector2, angle: float, size: float, shade: float, i: int) -> void:
	match material:
		"stones":
			var g := 0.45 + 0.35 * _jitter(i, 3.0)
			SchoolPictureG4Arts._ellipse(ci, p, Vector2(size * (0.9 + 0.3 * _jitter(i, 4.0)), size * 0.7), Color(g, g, g * 1.05))
		"leaves":
			var col := Color("f7d21e").lerp(Color("e03a2f"), shade)
			var pts := PackedVector2Array()
			for k in 13:
				var t := k / 12.0
				pts.append(Vector2(size * (2.0 * t - 1.0), sin(t * PI) * size * 0.45))
			for k in range(11, 0, -1):
				var t := k / 12.0
				pts.append(Vector2(size * (2.0 * t - 1.0), -sin(t * PI) * size * 0.45))
			var turned := PackedVector2Array()
			for q in pts:
				turned.append(p + q.rotated(angle))
			ci.draw_colored_polygon(turned, col)
			ci.draw_line(p - Vector2.from_angle(angle) * size, p + Vector2.from_angle(angle) * size, col.darkened(0.3), 1.0)
		"sticks":
			var dir := Vector2.from_angle(angle)
			ci.draw_line(p - dir * size * 1.5, p + dir * size * 1.5, Color("6b4a2a"), maxf(4.0, size * 0.55), true)
		_:
			SchoolPictureG4Arts._ellipse(ci, p, Vector2(size * 0.8, size * 0.55),
				Color("f7a1c4").lerp(Color.WHITE, 0.6 * shade))


static func _draw_masterwork(ci: CanvasItem, r: Rect2, d: Dictionary) -> void:
	var at := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	match str(d.what):
		"great_wave":
			ci.draw_rect(r, Color("efe2c2"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.56, 0.78), at.call(0.66, 0.6), at.call(0.76, 0.78)]),
				Color("5b6f8f"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.63, 0.65), at.call(0.66, 0.6), at.call(0.69, 0.65)]),
				Color.WHITE)
			var wave := PackedVector2Array()
			wave.append(at.call(0.0, 1.0))
			for k in 31:
				var t := k / 30.0
				wave.append(at.call(0.02 + 0.44 * t, 0.9 - 0.75 * sin(t * PI * 0.62)))
			for k in 16:
				var t := k / 15.0
				wave.append(at.call(0.46 - 0.12 * t, 0.2 + 0.24 * t) + Vector2(sin(t * PI) * r.size.x * 0.06, 0))
			wave.append(at.call(0.5, 0.95))
			wave.append(at.call(1.0, 0.86))
			wave.append(at.call(1.0, 1.0))
			ci.draw_colored_polygon(wave, Color("1d3f8f"))
			for k in 9:   # the foam's claws
				var t := k / 8.0
				var p: Vector2 = at.call(0.1 + 0.34 * t, 0.62 - 0.44 * sin(t * PI * 0.62))
				ci.draw_circle(p, r.size.y * 0.035, Color.WHITE)
				ci.draw_circle(p + Vector2(r.size.y * 0.03, r.size.y * 0.02), r.size.y * 0.02, Color.WHITE)
			for k in 3:   # the boats under the wave
				var b: Vector2 = at.call(0.2 + 0.24 * k, 0.86 - 0.04 * k)
				SchoolPictureG4Arts._ellipse(ci, b, Vector2(r.size.x * 0.07, r.size.y * 0.025), Color("e8d48a"))
				for q in 4:
					ci.draw_circle(b + Vector2(r.size.x * (-0.03 + 0.02 * q), -r.size.y * 0.02), r.size.y * 0.012, Color("2a3550"))
		"starry_night":
			ci.draw_rect(r, Color("1b2d6b"))
			for k in 5:   # the swirling sky
				var c: Vector2 = at.call(0.2 + 0.18 * k, 0.28 + 0.08 * (k % 2))
				var pts := PackedVector2Array()
				for q in 30:
					var t := q / 29.0
					pts.append(c + Vector2.from_angle(t * TAU * 1.4) * r.size.y * (0.03 + 0.1 * t))
				ci.draw_polyline(pts, Color("7fb0f5"), 3.0, true)
			for s: Vector2 in [Vector2(0.14, 0.15), Vector2(0.4, 0.12), Vector2(0.62, 0.2), Vector2(0.34, 0.42), Vector2(0.72, 0.4)]:
				ci.draw_circle(at.call(s.x, s.y), r.size.y * 0.06, Color(1, 0.9, 0.4, 0.35))
				ci.draw_circle(at.call(s.x, s.y), r.size.y * 0.03, Color("f7d21e"))
			ci.draw_circle(at.call(0.88, 0.16), r.size.y * 0.09, Color("f7d21e"))
			ci.draw_circle(at.call(0.905, 0.14), r.size.y * 0.075, Color("1b2d6b"))
			var hills := PackedVector2Array()
			for k in 21:
				var t := k / 20.0
				hills.append(at.call(t, 0.66 + 0.06 * sin(t * PI * 2.0)))
			hills.append(at.call(1.0, 1.0))
			hills.append(at.call(0.0, 1.0))
			ci.draw_colored_polygon(hills, Color("22385e"))
			for k in 7:   # the village's houses and the church's spire
				var h: Vector2 = at.call(0.34 + 0.07 * k, 0.8)
				ci.draw_rect(Rect2(h - Vector2(r.size.x * 0.025, r.size.y * 0.05), Vector2(r.size.x * 0.05, r.size.y * 0.06)),
					Color("3b4a6b"))
				ci.draw_rect(Rect2(h - Vector2(r.size.x * 0.008, r.size.y * 0.03), Vector2(r.size.x * 0.012, r.size.y * 0.02)),
					Color("f7d21e"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.6, 0.76), at.call(0.615, 0.5), at.call(0.63, 0.76)]),
				Color("3b4a6b"))
			var tree := PackedVector2Array()   # the cypress: a dark flame
			for k in 13:
				var t := k / 12.0
				tree.append(at.call(0.14 + 0.02 * sin(t * PI * 3.0) - 0.055 * (1.0 - t) - 0.004, 1.0 - 0.95 * t))
			for k in 13:
				var t := 1.0 - k / 12.0
				tree.append(at.call(0.14 + 0.02 * sin(t * PI * 3.0) + 0.055 * (1.0 - t) + 0.004, 1.0 - 0.95 * t))
			ci.draw_colored_polygon(tree, Color("1c2a1a"))
		_:
			ci.draw_rect(r, Color("b9c8c0"))
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.55, 0.5), at.call(0.66, 0.2), at.call(0.74, 0.36),
				at.call(0.84, 0.14), at.call(1.0, 0.4), at.call(1.0, 0.55)]), Color("e8ecea"))
			ci.draw_rect(Rect2(at.call(0.3, 0.55), r.size * Vector2(0.7, 0.45)), Color("dfe6e2"))
			for pond: Rect2 in [Rect2(0.42, 0.62, 0.22, 0.08), Rect2(0.7, 0.7, 0.26, 0.1)]:
				ci.draw_rect(Rect2(r.position + pond.position * r.size, pond.size * r.size), Color("9fb4ad"))
				for q in 4:   # skaters
					var sk := r.position + (pond.position + Vector2(pond.size.x * (0.2 + 0.2 * q), pond.size.y * 0.5)) * r.size
					ci.draw_line(sk, sk - Vector2(0, r.size.y * 0.03), Color("2a2724"), 2.0)
			var slope := PackedVector2Array([at.call(0.0, 0.3), at.call(0.45, 0.56), at.call(0.45, 1.0), at.call(0.0, 1.0)])
			ci.draw_colored_polygon(slope, Color("f4f6f5"))
			for k in 4:   # bare trees down the slope
				var base: Vector2 = at.call(0.08 + 0.1 * k, 0.72 + 0.06 * k)
				ci.draw_line(base, base - Vector2(0, r.size.y * 0.6), Color("2a2724"), 3.0)
				for q in 5:
					var y := base.y - r.size.y * (0.2 + 0.08 * q)
					ci.draw_line(Vector2(base.x, y), Vector2(base.x + r.size.y * (0.08 if q % 2 == 0 else -0.08), y - r.size.y * 0.05),
						Color("2a2724"), 1.5)
			for k in 3:   # the hunters and their dogs, dark on the snow
				var h: Vector2 = at.call(0.14 + 0.08 * k, 0.5 + 0.04 * k)
				ci.draw_line(h, h - Vector2(0, r.size.y * 0.08), Color("2a2724"), 4.0)
				ci.draw_circle(h - Vector2(0, r.size.y * 0.09), r.size.y * 0.018, Color("2a2724"))
				ci.draw_line(h + Vector2(r.size.x * 0.02, 0), h + Vector2(r.size.x * 0.045, 0), Color("2a2724"), 3.0)


# --- music -----------------------------------------------------------------------------------------------------------

## A sharp sign centred on `c` (u: half the gap between the stave's lines).
static func _sharp(ci: CanvasItem, c: Vector2, u: float, lw: float, col: Color = INK) -> void:
	ci.draw_line(c + Vector2(-0.38 * u, -1.5 * u), c + Vector2(-0.38 * u, 1.8 * u), col, lw)
	ci.draw_line(c + Vector2(0.38 * u, -1.8 * u), c + Vector2(0.38 * u, 1.5 * u), col, lw)
	for dy: float in [-0.55, 0.55]:
		ci.draw_line(c + Vector2(-0.95 * u, (dy + 0.28) * u), c + Vector2(0.95 * u, (dy - 0.28) * u), col, lw * 2.4)


## A flat sign: its belly on `c`.
static func _flat(ci: CanvasItem, c: Vector2, u: float, lw: float, col: Color = INK) -> void:
	ci.draw_line(c + Vector2(-0.5 * u, -3.0 * u), c + Vector2(-0.5 * u, 0.9 * u), col, lw * 1.2)
	var belly := SchoolPictureG4Arts._catmull(PackedVector2Array([c + Vector2(-0.5 * u, -0.2 * u), c + Vector2(0.3 * u, -0.6 * u),
		c + Vector2(0.75 * u, -0.1 * u), c + Vector2(0.2 * u, 0.55 * u), c + Vector2(-0.5 * u, 0.9 * u)]), 5)
	ci.draw_polyline(belly, col, lw * 1.8, true)


static func _key_name(key: String) -> String:
	return key.replace("b", " flat") + " major"


static func _draw_key_signature(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var key := str(d.key)
	var signs := key_accidentals(key)
	var notes: Array = d.get("notes", [])
	var names := bool(d.get("names", false))
	var title := bool(d.get("title", false))
	var fs := _fs(r, 0.12, 22)
	var name_h := fs * 1.5 if names else 0.0
	var title_h := fs * 1.5 if title else 0.0
	var n := notes.size()
	var slot := 4.6
	var units := 6.0 + 2.4 * signs.size() + 1.0 + n * slot + 1.0
	var u := minf((r.size.y - name_h - title_h) / 15.5, r.size.x / units)
	var base_y := r.position.y + title_h + (r.size.y - name_h - title_h) * 0.5 + 4.0 * u
	var width := units * u
	var x0 := r.position.x + (r.size.x - width) * 0.5
	var lw := maxf(1.2, u * 0.12)
	if title:
		_label(ci, font, Vector2(r.get_center().x, r.position.y + title_h * 0.45), _key_name(key), fs)
	for i in 5:
		var y := base_y - i * 2.0 * u
		ci.draw_line(Vector2(x0, y), Vector2(x0 + width, y), INK, lw)
	SchoolPictureG4Arts._treble_clef(ci, Vector2(x0 + 2.2 * u, base_y), u, lw)
	var x := x0 + 6.2 * u
	for s: String in signs:
		var y := base_y - int(SIGN_STEP[s]) * u
		if s.ends_with("#"):
			_sharp(ci, Vector2(x, y), u, lw, SHADE)
		else:
			_flat(ci, Vector2(x, y), u, lw, SHADE)
		x += 2.4 * u
	x += 1.0 * u
	for i in n:
		var note := str(notes[i])
		var s := SchoolPictureG4Arts.stave_step(note)
		var c := Vector2(x + slot * 0.5 * u, base_y - s * u)
		for ledger: int in [-2, 10]:
			if (ledger < 0 and s <= ledger) or (ledger > 0 and s >= ledger):
				ci.draw_line(Vector2(c.x - 1.9 * u, base_y - ledger * u), Vector2(c.x + 1.9 * u, base_y - ledger * u), INK, lw)
		SchoolPictureG4Arts._stave_note(ci, c, u, lw, "crotchet", s < 4, INK)
		if names:
			var letter := note.left(1)
			var sign := ""
			for sg: String in signs:
				if sg.left(1) == letter:
					sign = sg.right(1)
			var nc := Vector2(c.x - (fs * 0.2 if sign != "" else 0.0), r.end.y - name_h * 0.5)
			_label(ci, font, nc, letter, fs, SHADE if sign != "" else INK)
			var su := fs * 0.2
			if sign == "#":
				_sharp(ci, nc + Vector2(fs * 0.6, 0), su, maxf(1.0, su * 0.25), SHADE)
			elif sign == "b":
				_flat(ci, nc + Vector2(fs * 0.55, fs * 0.05), su, maxf(1.0, su * 0.25), SHADE)
		x += slot * u


static func _draw_twelve_bar(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var key := str(d.key)
	var chords := twelve_bar_chords(key)
	var hide: Array[int] = []
	for b: Variant in d.get("hide", []):
		hide.append(int(b))
	var mark := _int(d, "mark", -1)
	var numerals := bool(d.get("numerals", false))
	var cw := r.size.x / 4.0
	var ch := r.size.y / 3.0
	var fs := clampi(int(ch * (0.36 if numerals else 0.46)), 10, 34)
	var small := clampi(int(ch * 0.2), 9, 16)
	for b in 12:
		var cell := Rect2(r.position + Vector2((b % 4) * cw, (b / 4) * ch), Vector2(cw, ch)).grow(-3)
		var chord := chords[b]
		var numeral := "I" if chord == key else ("IV" if b in [4, 5, 9] else "V")
		var col := {"I": SOFT, "IV": Color("dde8fb"), "V": Color("dff2d8")}[numeral] as Color
		if hide.has(b):
			col = Color("eceff4")
		_rounded(ci, cell, SHADE if b == mark else col, 8)
		_label(ci, font, cell.position + Vector2(small * 0.9, small * 0.8), str(b + 1), small, Color.WHITE if b == mark else GREY)
		var said := "?" if hide.has(b) else chord
		_label(ci, font, cell.get_center() - Vector2(0, ch * 0.1 if numerals else 0.0), said, fs, Color.WHITE if b == mark else INK)
		if numerals and not hide.has(b):
			_label(ci, font, cell.get_center() + Vector2(0, ch * 0.27), numeral, small, Color.WHITE if b == mark else INK)


static func _draw_hand_keys(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var from := SchoolPictureG5Arts._pitch(str(d.get("from", "C4")))
	var keys := _int(d, "keys", 8)
	var right := str(d.hand) == "right"
	var fs := _fs(r, 0.1, 18)
	var kw := minf(r.size.x / keys, r.size.y * 0.56 / 3.4)
	var kh := minf(r.size.y * 0.56, kw * 4.2)
	var o := Vector2(r.position.x + (r.size.x - kw * keys) * 0.5, r.end.y - kh)
	var mark := SchoolPictureG5Arts._pitch(str(d.get("mark", "")))
	var spots := {}
	for k in keys:
		var p := SchoolPictureG5Arts._white_pitch(from, k)
		var box := Rect2(o + Vector2(k * kw, 0), Vector2(kw, kh))
		ci.draw_rect(box, SOFT if p == mark else Color.WHITE)
		ci.draw_rect(box, INK, false, 1.5)
		spots[p] = Vector2(box.get_center().x, box.position.y + kh * 0.78)
	for k in keys - 1:
		var p := SchoolPictureG5Arts._white_pitch(from, k)
		if not posmod(p, 12) in [0, 2, 5, 7, 9]:
			continue
		var box := Rect2(o + Vector2((k + 1) * kw - kw * 0.3, 0), Vector2(kw * 0.6, kh * 0.6))
		ci.draw_rect(box, Color("c7621a") if p + 1 == mark else Color("1c1c1c"))
		spots[p + 1] = Vector2(box.get_center().x, box.position.y + kh * 0.45)
	for f: Array in d.fingers:
		var p := SchoolPictureG5Arts._pitch(str(f[0]))
		if spots.has(p):
			ci.draw_circle(spots[p], kw * 0.3, SHADE)
			_label(ci, font, spots[p], str(int(f[1])), int(kw * 0.42), Color.WHITE)
	# the hand from above, its fingers numbered: the thumb is 1 on both hands
	var area := Rect2(r.position, Vector2(r.size.x, r.size.y - kh - 6.0))
	var hh := area.size.y
	var palm := Rect2(Vector2(area.get_center().x - hh * 0.65, area.position.y + hh * 0.46), Vector2(hh * 1.3, hh * 0.52))
	_rounded(ci, palm, Color("f6c89f"), hh * 0.15)
	for i in 5:
		var finger := i + 1
		var slot := i if right else 4 - i
		var bx := palm.position.x + palm.size.x * (0.12 + 0.19 * slot)
		var length := hh * ([0.24, 0.38, 0.42, 0.38, 0.3][i] as float)
		var start := Vector2(bx, palm.position.y + (hh * 0.22 if finger == 1 else hh * 0.05))
		var tip := start - Vector2(0, length) + Vector2((-hh * 0.12 if right else hh * 0.12) if finger == 1 else 0.0, 0)
		ci.draw_line(start, tip, Color("f6c89f"), hh * 0.17, true)
		ci.draw_circle(tip, hh * 0.13, SHADE)
		_label(ci, font, tip, str(finger), int(hh * 0.2), Color.WHITE)
	var caption := "right hand" if right else "left hand"
	_label(ci, font, Vector2(palm.end.x + fs * 3.5, palm.get_center().y), caption, fs)


static func _draw_instrument(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var what := str(d.what)
	var at := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var wood := Color("a8743f")
	var dark := Color("5a3a1e")
	var metal := Color("c9ccd2")
	match what:
		"sitar":
			ci.draw_circle(at.call(0.12, 0.62), r.size.y * 0.12, Color("c98a4b"))
			ci.draw_rect(Rect2(at.call(0.06, 0.38), r.size * Vector2(0.7, 0.12)), wood)
			ci.draw_rect(Rect2(at.call(0.06, 0.38), r.size * Vector2(0.7, 0.025)), Color("c99a62"))
			for k in 4:
				ci.draw_rect(Rect2(at.call(0.09 + 0.035 * k, 0.27), r.size * Vector2(0.015, 0.12)), dark)
			for k in 11:
				var x: float = 0.27 + 0.042 * k
				ci.draw_arc(at.call(x, 0.4), r.size.y * 0.06, PI, TAU, 8, metal, 2.5, true)
			var gourd: Vector2 = at.call(0.82, 0.62)
			ci.draw_circle(gourd, r.size.y * 0.32, Color("c98a4b"))
			for k in 16:
				ci.draw_circle(gourd + Vector2.from_angle(TAU * k / 16.0) * r.size.y * 0.24, r.size.y * 0.018, Color("f3e7c9"))
			for k in 4:
				ci.draw_line(at.call(0.08, 0.41 + 0.02 * k), at.call(0.86, 0.5 + 0.02 * k), Color("e8e2cf"), 1.2)
		"koto":
			ci.draw_rect(Rect2(at.call(0.03, 0.62), r.size * Vector2(0.94, 0.26)), wood)
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.03, 0.3), at.call(0.97, 0.3), at.call(0.97, 0.62),
				at.call(0.03, 0.62)]), Color("d9b27a"))
			for k in 13:
				var y: float = 0.33 + 0.022 * k
				ci.draw_line(at.call(0.05, y), at.call(0.95, y), Color("f7f3e8"), 1.5)
				var b: Vector2 = at.call(0.5 + 0.02 * k, y)
				ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-5, 4), b + Vector2(0, -4), b + Vector2(5, 4)]),
					Color("fdfaf0"))
				ci.draw_polyline(PackedVector2Array([b + Vector2(-5, 4), b + Vector2(0, -4), b + Vector2(5, 4)]), INK, 1.0)
		"djembe":
			var pts := PackedVector2Array()
			var edge := func(y: float) -> float:
				if y < 0.62:
					return 0.2 - 0.13 * pow((y - 0.12) / 0.5, 0.8)
				return 0.07 + 0.11 * (y - 0.62) / 0.33
			for k in 21:
				var y := 0.12 + 0.83 * k / 20.0
				pts.append(at.call(0.5 - edge.call(y), y))
			for k in 21:
				var y := 0.95 - 0.83 * k / 20.0
				pts.append(at.call(0.5 + edge.call(y), y))
			ci.draw_colored_polygon(pts, Color("8a4f24"))
			for k in 8:   # the tuning ropes, zigzag down the bowl
				var y0 := 0.16
				var y1 := 0.5
				var x0: float = 0.5 + (k - 3.5) / 3.5 * edge.call(y0) * 0.95
				var x1: float = 0.5 + (k - 3.0 + (0.0 if k % 2 == 0 else -1.0)) / 3.5 * edge.call(y1) * 0.95
				ci.draw_line(at.call(x0, y0), at.call(x1, y1), Color("f3e7c9"), 2.0, true)
			SchoolPictureG4Arts._ellipse(ci, at.call(0.5, 0.12), Vector2(r.size.x * 0.2, r.size.y * 0.05), Color("efe0bd"))
			ci.draw_rect(Rect2(at.call(0.3, 0.14), r.size * Vector2(0.4, 0.03)), Color("f3e7c9"))
		"bagpipes":
			for k in 3:
				var a: Vector2 = at.call(0.54 + 0.04 * k, 0.38)
				var b: Vector2 = at.call(0.6 + 0.08 * k, 0.04 + 0.02 * k)
				ci.draw_line(a, b, Color("2a2724"), r.size.y * 0.035, true)
				ci.draw_circle(b, r.size.y * 0.03, Color("d8c8a0"))
			ci.draw_line(at.call(0.36, 0.46), at.call(0.2, 0.22), Color("2a2724"), r.size.y * 0.03, true)
			var bag: Vector2 = at.call(0.5, 0.58)
			SchoolPictureG4Arts._ellipse(ci, bag, Vector2(r.size.x * 0.17, r.size.y * 0.25), Color("b3262c"))
			for k in 5:   # a tartan cover
				var off := (k - 2) * r.size.y * 0.08
				ci.draw_line(bag + Vector2(-r.size.x * 0.14, off), bag + Vector2(r.size.x * 0.14, off), Color("1f3b2a"), 3.0)
				ci.draw_line(bag + Vector2(off * 1.2, -r.size.y * 0.2), bag + Vector2(off * 1.2, r.size.y * 0.2), Color("1f3b2a"), 3.0)
			ci.draw_line(at.call(0.42, 0.76), at.call(0.3, 0.96), Color("2a2724"), r.size.y * 0.04, true)
			for k in 4:
				ci.draw_circle(at.call(0.42, 0.76).lerp(at.call(0.3, 0.96), 0.25 + 0.17 * k), r.size.y * 0.009, Color("d8c8a0"))
		"steelpan":
			ci.draw_rect(Rect2(at.call(0.2, 0.3), r.size * Vector2(0.6, 0.6)), Color("8d949e"))
			SchoolPictureG4Arts._ellipse(ci, at.call(0.5, 0.9), Vector2(r.size.x * 0.3, r.size.y * 0.06), Color("8d949e"))
			for k in 3:
				ci.draw_line(at.call(0.2, 0.45 + 0.15 * k), at.call(0.8, 0.45 + 0.15 * k), Color("6d737c"), 2.0)
			SchoolPictureG4Arts._ellipse(ci, at.call(0.5, 0.3), Vector2(r.size.x * 0.3, r.size.y * 0.2), Color("dfe3e8"))
			for k in 8:
				var p: Vector2 = at.call(0.5, 0.3) + Vector2(cos(TAU * k / 8.0) * r.size.x * 0.21, sin(TAU * k / 8.0) * r.size.y * 0.13)
				_ellipse_line(ci, p, Vector2(r.size.x * 0.045, r.size.y * 0.04))
			for k in 3:
				_ellipse_line(ci, at.call(0.44 + 0.06 * k, 0.3), Vector2(r.size.x * 0.025, r.size.y * 0.03))
			for k in 2:
				var a: Vector2 = at.call(0.78 + 0.05 * k, 0.2)
				var b: Vector2 = at.call(0.9 + 0.05 * k, 0.5)
				ci.draw_line(a, b, wood, 4.0, true)
				ci.draw_circle(a, r.size.y * 0.035, Color("e03a2f"))
		"didgeridoo":
			var pts := PackedVector2Array()
			for k in 11:
				var x := 0.04 + 0.92 * k / 10.0
				pts.append(at.call(x, 0.5 - (0.05 + 0.05 * k / 10.0)))
			for k in 11:
				var x := 0.96 - 0.92 * k / 10.0
				pts.append(at.call(x, 0.5 + (0.1 - 0.05 * k / 10.0)))
			ci.draw_colored_polygon(pts, Color("b0632e"))
			for k in 6:
				var x: float = 0.2 + 0.13 * k
				ci.draw_line(at.call(x, 0.41), at.call(x, 0.59), Color("f3e7c9"), 3.0)
				for q in 3:
					ci.draw_circle(at.call(x + 0.05, 0.44 + 0.06 * q), r.size.y * 0.012, Color("f7d21e"))
			ci.draw_rect(Rect2(at.call(0.03, 0.43), r.size * Vector2(0.03, 0.14)), Color("2a2724"))
		"kora":
			var g: Vector2 = at.call(0.5, 0.6)
			var arc := PackedVector2Array()
			for k in 21:
				arc.append(g + Vector2(cos(PI * k / 20.0) * r.size.x * 0.24, sin(PI * k / 20.0) * r.size.y * 0.36))
			ci.draw_colored_polygon(arc, Color("c98a4b"))
			SchoolPictureG4Arts._ellipse(ci, g, Vector2(r.size.x * 0.24, r.size.y * 0.05), Color("efe0bd"))
			ci.draw_line(at.call(0.5, 0.72), at.call(0.5, 0.02), wood, r.size.y * 0.035, true)
			for k in 11:
				var bx: float = 0.44 + 0.012 * k
				var ty: float = 0.08 + 0.03 * k
				ci.draw_line(at.call(bx, 0.6), at.call(0.5, ty), Color("8a7a5a"), 1.2, true)
				ci.draw_line(at.call(1.0 - bx, 0.6), at.call(0.5, ty + 0.015), Color("8a7a5a"), 1.2, true)
			ci.draw_rect(Rect2(at.call(0.44, 0.56), r.size * Vector2(0.12, 0.05)), dark)
		_:
			ci.draw_line(at.call(0.5, 0.78), at.call(0.5, 0.03), dark, r.size.y * 0.03, true)
			for k in 2:
				ci.draw_line(at.call(0.5, 0.07 + 0.07 * k), at.call(0.44, 0.07 + 0.07 * k), dark, 4.0)
			var box: Vector2 = at.call(0.5, 0.82)
			var hexa := PackedVector2Array()
			for k in 6:
				hexa.append(box + Vector2(cos(TAU * k / 6.0) * r.size.x * 0.07, sin(TAU * k / 6.0) * r.size.y * 0.1))
			ci.draw_colored_polygon(hexa, Color("6b3a1e"))
			ci.draw_line(at.call(0.52, 0.8), at.call(0.52, 0.08), Color("f7f3e8"), 1.2)
			ci.draw_line(at.call(0.3, 0.72), at.call(0.92, 0.56), wood, 3.0, true)
			ci.draw_line(at.call(0.31, 0.74), at.call(0.91, 0.58), Color("f7f3e8"), 1.2, true)
	var parts := INSTRUMENT_PARTS[what] as Dictionary
	var fs := _fs(r, 0.08, 16)
	var mark := str(d.get("mark", ""))
	for part: String in parts:
		var p: Vector2 = r.position + (parts[part] as Vector2) * r.size
		if part == mark:
			_ring(ci, p, r.size.y * 0.07, SHADE, 3.0)
		if bool(d.get("labels", false)):
			var t: Vector2 = r.position + ((INSTRUMENT_LABELS[what] as Dictionary)[part] as Vector2) * r.size
			var tfs := _fit(font, part, fs, r.size.x * 0.2)
			var half := font.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x * 0.5 + 4.0
			var tip := t + Vector2(clampf(p.x - t.x, -half, half), 0 if absf(p.y - t.y) < tfs else signf(p.y - t.y) * tfs * 0.7)
			ci.draw_line(tip, p, GREY, 1.5)
			_label(ci, font, t, part, tfs, SHADE if part == mark else INK)
			ci.draw_circle(p, 3.0, INK)


static func _ellipse_line(ci: CanvasItem, c: Vector2, radii: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(cos(t) * radii.x, sin(t) * radii.y))
	ci.draw_polyline(pts, INK, 1.5, true)


static func _draw_decibels(ci: CanvasItem, font: Font, r: Rect2, d: Dictionary) -> void:
	var items := _items(d)
	var mark := _int(d, "mark", -1)
	var fs := _fs(r, 0.075, 16)
	var top := r.position.y + fs * 0.8
	var bottom := r.end.y - fs * 0.8
	var y_of := func(db: float) -> float: return bottom - (bottom - top) * db / 140.0
	var bar := Rect2(Vector2(r.position.x + fs * 3.2, top), Vector2(r.size.x * 0.06, bottom - top))
	for k in 28:
		var t := k / 28.0
		var col := Color("3aa845").lerp(Color("f2c12e"), t * 2.0) if t < 0.5 else Color("f2c12e").lerp(Color("e03a2f"), t * 2.0 - 1.0)
		ci.draw_rect(Rect2(Vector2(bar.position.x, bottom - (k + 1) * bar.size.y / 28.0), Vector2(bar.size.x, bar.size.y / 28.0 + 1)), col)
	ci.draw_rect(bar, INK, false, 1.5)
	for db in range(0, 141, 20):
		var y: float = y_of.call(float(db))
		ci.draw_line(Vector2(bar.position.x - 6, y), Vector2(bar.position.x, y), INK, 1.5)
		_label(ci, font, Vector2(bar.position.x - fs * 1.7, y), str(db), fs)
	_label(ci, font, Vector2(bar.get_center().x, r.position.y + fs * 0.1), "dB", fs)
	if bool(d.get("safe", false)):
		var y: float = y_of.call(85.0)
		_dashed(ci, Vector2(bar.position.x, y), Vector2(bar.end.x + r.size.x * 0.1, y), Color("e03a2f"), 2.0, 8.0)
		_label(ci, font, Vector2(r.end.x - fs * 2.2, y), "85 dB", fs, Color("e03a2f"))
	var ys: Array[float] = []
	for it: Array in items:
		ys.append(y_of.call(float(it[1])))
	for i in range(1, ys.size()):   # keep the names apart
		ys[i] = minf(ys[i], ys[i - 1] - fs * 1.35) if float(items[i][1]) >= float(items[i - 1][1]) else ys[i]
	var tx := bar.end.x + r.size.x * 0.12
	for i in items.size():
		var y := ys[i]
		var name := str(items[i][0])
		var tfs := _fit(font, name, fs, r.size.x * 0.45)
		var tw := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs).x
		ci.draw_line(Vector2(bar.end.x, y_of.call(float(items[i][1]))), Vector2(tx - 4, y), GREY, 1.5)
		var box := Rect2(Vector2(tx - 3, y - tfs * 0.75), Vector2(tw + 6, tfs * 1.5))
		if i == mark:
			_rounded(ci, box, SHADE, 5)
		var base := y + (font.get_ascent(tfs) - font.get_descent(tfs)) * 0.5
		ci.draw_string(font, Vector2(tx, base), name, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, Color.WHITE if i == mark else INK)


# --- helpers ---------------------------------------------------------------------------------------------------------

static func _fs(r: Rect2, share: float = 0.11, most: int = 22) -> int:
	return clampi(int(r.size.y * share), 10, most)


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
