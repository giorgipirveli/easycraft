extends GutTest
## Owner #70 and #73, grade 4 computing, art and music (research §6.4): the picture kinds they add (SchoolPictureG4Arts,
## drawn inside SchoolPicture): notes on the treble stave, block code, flowcharts, a home network, the colour wheel, a
## shaded form, a face's proportions, a landscape's grounds, pixel art, relief sculpture seen from the side, a print and
## its block, the orchestra's seats and Egyptian hieroglyphs; and grade 3's rhythms gain semibreves, dotted minims and
## time signatures. Every kind draws from its data at the School's picture sizes; broken data is a problem the content
## test finds; the pictures' facts are the lessons' (E G B D F on the lines, F A C E in the spaces; opposites on the wheel).

const SAMPLES: Array[Dictionary] = [
	{"kind": "stave", "notes": ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"], "names": true},
	{"kind": "stave", "notes": ["G4"], "mark": 0},
	{"kind": "stave", "notes": ["F5", "A5", "C4", "E5"], "values": ["semibreve", "minim", "crotchet", "minim"]},
	{"kind": "stave", "notes": ["E4", "G4", "B4", "D5", "C5", "A4", "F4", "E4"], "values": ["minim", "minim",
		"crotchet", "crotchet", "crotchet", "crotchet", "minim", "minim"], "time": "4/4", "bars": true},
	{"kind": "stave", "notes": ["C5", "A4", "G4"], "time": "3/4", "values": ["crotchet", "crotchet", "crotchet"]},
	{"kind": "code", "lines": ["WHEN START is tapped", "SET score TO 0", "REPEAT 3 TIMES", "  CHANGE score BY 10",
		"IF score > 20", "  SAY You win!", "ELSE", "  SAY Try again"], "mark": 3},
	{"kind": "code", "lines": ["WHEN LEFT is tapped", "  TURN LEFT"]},
	{"kind": "flowchart", "steps": [{"shape": "start", "text": "START"}, {"shape": "step", "text": "Fill the cup"},
		{"shape": "decision", "text": "Is it full?", "back": 1}, {"shape": "end", "text": "END"}]},
	{"kind": "flowchart", "steps": [{"shape": "start", "text": "START"}, {"shape": "decision", "text": "Is it raining?",
		"no": "Wear a sun hat"}, {"shape": "step", "text": "Take an umbrella"}, {"shape": "step", "text": "Go out"},
		{"shape": "end", "text": "END"}]},
	{"kind": "network", "devices": ["laptop", "tablet", "phone", "printer"], "wired": [3], "internet": true,
		"server": true, "mark": "router"},
	{"kind": "network", "devices": ["computer", "computer", "computer"], "wired": [0, 1, 2]},
	{"kind": "colour_wheel", "size": 12, "line": ["red", "green"]},
	{"kind": "colour_wheel", "size": 6, "blank": ["green"], "names": true},
	{"kind": "colour_wheel", "size": 12, "half": "warm", "mark": ["yellow-orange"]},
	{"kind": "shading", "shape": "sphere", "light": "left", "labels": true},
	{"kind": "shading", "shape": "cube", "light": "right"},
	{"kind": "shading", "shape": "cylinder", "light": "left"},
	{"kind": "shading", "shape": "sphere", "light": "right", "flat": true},
	{"kind": "face"},
	{"kind": "face", "mark": "eyes", "guides": true},
	{"kind": "face", "eyes": "high", "guides": false},
	{"kind": "face", "mark": "ears"},
	{"kind": "landscape", "labels": true},
	{"kind": "landscape", "mark": "background"},
	{"kind": "pixel_art", "rows": ["..rr..rr..", ".rrrrrrrr.", ".rrrrrrrr.", "..rrrrrr..", "...rrrr...", "....rr...."],
		"key": {"r": "red"}},
	{"kind": "pixel_art", "rows": ["yb", "by"], "key": {"y": "yellow", "b": "blue"}, "grid": false},
	{"kind": "relief", "what": "low"},
	{"kind": "relief", "what": "high"},
	{"kind": "relief", "what": "sunken"},
	{"kind": "relief", "what": "round"},
	{"kind": "print", "items": [{"text": "R", "on": "block", "flip": "mirror"}, {"text": "R", "on": "paper"}],
		"arrows": true},
	{"kind": "print", "items": [{"text": "F", "on": "paper", "flip": "upside down"}]},
	{"kind": "orchestra"},
	{"kind": "orchestra", "mark": "brass", "hide": "brass"},
	{"kind": "glyphs", "signs": ["water", "mouth", "bread", "stool"], "names": true},
	{"kind": "glyphs", "signs": ["basket", "reed", "foot"], "cartouche": true},
	{"kind": "notation", "beats": ["semibreve", "minim", "minim"], "time": "4/4", "bars": true, "words": true},
	{"kind": "notation", "beats": ["dotted minim", "crotchet", "quavers", "crotchet"], "time": "3/4", "bars": true},
	{"kind": "swatches", "items": ["red", "+", "orange", "=", "red-orange"]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_grade_4_arts_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG4Arts.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "stave"}, {"kind": "stave", "notes": []}, {"kind": "stave", "notes": ["H4"]},
			{"kind": "stave", "notes": ["C3"]}, {"kind": "stave", "notes": ["B5"]}, {"kind": "stave", "notes": ["F#4"]},
			{"kind": "stave", "notes": ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5"]},
			{"kind": "stave", "notes": ["C4", "D4"], "values": ["minim"]},
			{"kind": "stave", "notes": ["C4"], "values": ["semiquaver"]}, {"kind": "stave", "notes": ["C4"], "mark": 1},
			{"kind": "stave", "notes": ["C4"], "time": "5/8"}, {"kind": "stave", "notes": ["C4"], "bars": true},
			{"kind": "code"}, {"kind": "code", "lines": []}, {"kind": "code", "lines": ["x".repeat(40)]},
			{"kind": "code", "lines": ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]},
			{"kind": "code", "lines": ["        TOO DEEP"]}, {"kind": "code", "lines": ["A"], "mark": 3},
			{"kind": "flowchart"}, {"kind": "flowchart", "steps": [{"shape": "start", "text": "START"}]},
			{"kind": "flowchart", "steps": [{"shape": "star", "text": "A"}, {"shape": "end", "text": "B"}]},
			{"kind": "flowchart", "steps": [{"shape": "start", "text": "A"}, {"shape": "decision", "text": "B?"}]},
			{"kind": "flowchart", "steps": [{"shape": "start", "text": "A"}, {"shape": "decision", "text": "B?",
				"back": 5}, {"shape": "end", "text": "C"}]},
			{"kind": "network"}, {"kind": "network", "devices": ["toaster"]},
			{"kind": "network", "devices": ["phone"], "wired": [2]},
			{"kind": "network", "devices": ["phone", "phone", "phone", "phone", "phone", "phone"]},
			{"kind": "network", "devices": ["phone"], "mark": "moon"},
			{"kind": "colour_wheel", "size": 8}, {"kind": "colour_wheel", "size": 6, "blank": ["red-orange"]},
			{"kind": "colour_wheel", "size": 12, "line": ["red"]}, {"kind": "colour_wheel", "size": 12, "half": "hot"},
			{"kind": "shading", "shape": "cone", "light": "left"}, {"kind": "shading", "shape": "cube", "light": "up"},
			{"kind": "face", "mark": "chin"}, {"kind": "face", "eyes": "low"},
			{"kind": "landscape", "mark": "sea"},
			{"kind": "pixel_art", "rows": ["rr", "r"], "key": {"r": "red"}},
			{"kind": "pixel_art", "rows": ["rx"], "key": {"r": "red"}},
			{"kind": "pixel_art", "rows": ["r"], "key": {"r": "sky"}},
			{"kind": "pixel_art", "rows": ["rrrrrrrrrrrrrrrrr"], "key": {"r": "red"}},
			{"kind": "relief", "what": "deep"},
			{"kind": "print", "items": []}, {"kind": "print", "items": [{"text": "", "on": "paper"}]},
			{"kind": "print", "items": [{"text": "R", "on": "wall"}]},
			{"kind": "print", "items": [{"text": "R", "on": "paper", "flip": "sideways"}]},
			{"kind": "orchestra", "mark": "choir"}, {"kind": "glyphs", "signs": ["owl-ish"]},
			{"kind": "glyphs", "signs": []},
			{"kind": "notation", "beats": ["semibreve", "semibreve", "crotchet"]},
			{"kind": "notation", "beats": ["crotchet"], "time": "7/4"}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## The treble stave: E G B D F on the lines from the bottom, F A C E in the spaces, middle C on a ledger line below.
func test_the_stave_puts_every_note_on_its_line_or_space() -> void:
	var lines: Array[String] = []
	var spaces: Array[String] = []
	for n: String in SchoolPictureG4Arts.STAVE_NOTES:
		var s := SchoolPictureG4Arts.stave_step(n)
		if s >= 0 and s <= 8:
			if s % 2 == 0:
				lines.append(n.left(1))
			else:
				spaces.append(n.left(1))
	assert_eq("".join(lines), "EGBDF", "the lines from the bottom")
	assert_eq("".join(spaces), "FACE", "the spaces from the bottom")
	assert_eq(SchoolPictureG4Arts.stave_step("C4"), -2, "middle C: a ledger line below the stave")
	assert_eq(SchoolPictureG4Arts.stave_step("G4"), 2, "the treble clef curls round the G line, the second from the bottom")
	for i in range(1, SchoolPictureG4Arts.STAVE_NOTES.size()):
		assert_eq(SchoolPictureG4Arts.stave_step(SchoolPictureG4Arts.STAVE_NOTES[i]),
			SchoolPictureG4Arts.stave_step(SchoolPictureG4Arts.STAVE_NOTES[i - 1]) + 1, "a step up the stave")
		assert_gt(SchoolSound.frequency(SchoolPictureG4Arts.STAVE_NOTES[i]),
			SchoolSound.frequency(SchoolPictureG4Arts.STAVE_NOTES[i - 1]), "higher on the stave sounds higher")


## The painters' colour wheel: primaries a third of the way round from each other, each secondary between the two that
## make it, complementary colours opposite (red and green, yellow and purple, blue and orange), and every colour drawn
## with its own paint (the tertiaries between their neighbours' hues).
func test_the_colour_wheel_is_the_painters() -> void:
	var w: Array[String] = SchoolPictureG4Arts.WHEEL
	assert_eq(w.size(), 12)
	assert_eq(SchoolPictureG4Arts.opposite("red"), "green")
	assert_eq(SchoolPictureG4Arts.opposite("yellow"), "purple")
	assert_eq(SchoolPictureG4Arts.opposite("blue"), "orange")
	assert_eq(SchoolPictureG4Arts.opposite("red-orange"), "blue-green")
	assert_eq(SchoolPictureG4Arts.opposite("yellow-orange"), "blue-purple")
	assert_eq(SchoolPictureG4Arts.opposite("yellow-green"), "red-purple")
	assert_eq(absi(w.find("red") - w.find("yellow")), 4, "primaries a third of the wheel apart")
	assert_eq(absi(w.find("blue") - w.find("red")), 4)
	for c: String in w:
		assert_true(SchoolPictureArts.COLOURS.has(c), "%s can be painted" % c)
		assert_eq(SchoolPicture.problem({"kind": "swatches", "items": [c]}), "", c)
	var col: Dictionary = SchoolPictureArts.COLOURS
	assert_between((col["red-orange"] as Color).h, (col.red as Color).h, (col.orange as Color).h, "red-orange")
	assert_between((col["yellow-orange"] as Color).h, (col.orange as Color).h, (col.yellow as Color).h, "yellow-orange")
	assert_between((col["yellow-green"] as Color).h, (col.yellow as Color).h, (col.green as Color).h, "yellow-green")
	assert_between((col["blue-green"] as Color).h, (col.green as Color).h, (col.blue as Color).h, "blue-green")
	assert_between((col["blue-purple"] as Color).h, (col.blue as Color).h, (col.purple as Color).h, "blue-purple")
	assert_between((col["red-purple"] as Color).h, (col.purple as Color).h, 1.0, "red-purple: between purple and red")


func test_the_new_rhythm_signs_count_their_beats() -> void:
	assert_eq(SchoolPictureArts.beats_of(["semibreve"]), 4)
	assert_eq(SchoolPictureArts.beats_of(["dotted minim", "crotchet"]), 4)
	assert_eq(SchoolPictureArts.beats_of(["minim", "crotchet", "quavers"]), 4)


## A pixel picture counts its pixels as the lessons do (rows × columns, and each colour's own).
func test_a_pixel_picture_counts_its_pixels() -> void:
	var d := {"kind": "pixel_art", "rows": ["rr.", ".bb"], "key": {"r": "red", "b": "blue"}}
	assert_eq(SchoolPictureG4Arts.pixels_of(d, ""), 6)
	assert_eq(SchoolPictureG4Arts.pixels_of(d, "r"), 2)
	assert_eq(SchoolPictureG4Arts.pixels_of(d, "."), 2)
