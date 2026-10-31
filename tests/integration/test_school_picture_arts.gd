extends GutTest
## Owner #70 and #73, grade 3 computing, art and music (research §6.3): the picture kinds they add (SchoolPictureArts,
## drawn inside SchoolPicture): colour swatches for mixing, tints, shades and patterns; rhythms written in crotchets,
## quavers and rests; a tune's shape; a robot on a grid for programs; and the marks an artist makes (lines and
## textures). Every kind draws from its data at the School's picture sizes; broken data is a problem the content test
## finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "swatches", "items": ["red", "+", "yellow", "=", "orange"]},
	{"kind": "swatches", "items": ["blue", "+", "white", "=", "?"], "names": false},
	{"kind": "swatches", "items": ["red circle", "blue square", "red circle", "blue square", "?"], "names": false},
	{"kind": "swatches", "items": ["light blue", "blue", "dark blue"], "shape": "circle"},
	{"kind": "swatches", "items": ["green triangle"]},
	{"kind": "notation", "beats": ["crotchet", "crotchet", "quavers", "rest"]},
	{"kind": "notation", "beats": ["quavers", "quavers", "crotchet", "rest", "crotchet", "quavers", "minim"],
		"words": true, "bars": true},
	{"kind": "notation", "beats": ["crotchet", "?", "quavers", "crotchet"], "words": true},
	{"kind": "melody", "notes": ["C4", "D4", "E4", "F4", "G4"]},
	{"kind": "melody", "notes": ["G4", "E4", "-", "G4", "E4", "C4"], "mark": 5},
	{"kind": "melody", "notes": ["C4", "C4"]},
	{"kind": "robot", "cols": 5, "rows": 4, "start": [0, 3], "goal": [4, 0]},
	{"kind": "robot", "cols": 6, "rows": 6, "start": [1, 1], "goal": [4, 4], "walls": [[2, 1], [2, 2], [2, 3]],
		"gems": [[3, 0], [5, 5]], "path": [[1, 1], [1, 2], [1, 3], [1, 4], [2, 4], [3, 4], [4, 4]], "facing": "S"},
	{"kind": "robot", "cols": 3, "rows": 2, "start": [2, 1], "facing": "W"},
	{"kind": "marks", "what": "zigzag"},
	{"kind": "marks", "what": ["straight", "curved", "wavy", "spiral"], "names": true},
	{"kind": "marks", "what": ["dotted", "dashed", "thick", "thin"], "names": true},
	{"kind": "marks", "what": ["hatching", "cross-hatching", "stippling", "scribble"], "names": true},
	{"kind": "marks", "what": ["loops"]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_arts_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureArts.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	assert_eq(kinds.size(), SchoolPictureArts.KINDS.size())


func test_every_mark_and_every_colour_can_be_drawn() -> void:
	for m: String in SchoolPictureArts.MARKS:
		assert_eq(SchoolPicture.problem({"kind": "marks", "what": m}), "", m)
	for c: String in SchoolPictureArts.COLOURS:
		assert_eq(SchoolPicture.problem({"kind": "swatches", "items": [c]}), "", c)


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
			{"kind": "swatches"}, {"kind": "swatches", "items": []}, {"kind": "swatches", "items": ["sky"]},
			{"kind": "swatches", "items": ["red hexagon"]}, {"kind": "swatches", "items": ["red"], "shape": "star"},
			{"kind": "swatches", "items": ["red", "red", "red", "red", "red", "red", "red", "red", "red"]},
			{"kind": "notation"}, {"kind": "notation", "beats": []}, {"kind": "notation", "beats": ["drum"]},
			{"kind": "notation", "beats": ["minim", "minim", "minim", "minim", "minim"]},
			{"kind": "melody"}, {"kind": "melody", "notes": ["C4"]}, {"kind": "melody", "notes": ["C4", "H4"]},
			{"kind": "melody", "notes": ["-", "-"]}, {"kind": "melody", "notes": ["C4", "D4"], "mark": 2},
			{"kind": "melody", "notes": ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5"]},
			{"kind": "robot", "cols": 1, "rows": 4, "start": [0, 0]}, {"kind": "robot", "cols": 9, "rows": 4,
				"start": [0, 0]}, {"kind": "robot", "cols": 4, "rows": 4, "start": [4, 0]},
			{"kind": "robot", "cols": 4, "rows": 4}, {"kind": "robot", "cols": 4, "rows": 4, "start": [0, 0],
				"goal": [0, 5]}, {"kind": "robot", "cols": 4, "rows": 4, "start": [0, 0], "walls": [[0, 0]]},
			{"kind": "robot", "cols": 4, "rows": 4, "start": [0, 0], "path": [[0, 0], [2, 0]]},
			{"kind": "robot", "cols": 4, "rows": 4, "start": [0, 0], "facing": "up"},
			{"kind": "robot", "cols": 4, "rows": 4, "start": [0, 0], "goal": [1, 1], "walls": [[1, 1]]},
			{"kind": "marks"}, {"kind": "marks", "what": "sparkly"}, {"kind": "marks", "what": []},
			{"kind": "marks", "what": ["dotted", "dashed", "thick", "thin", "wavy"]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_a_rhythm_counts_its_beats() -> void:
	assert_eq(SchoolPictureArts.beats_of(["crotchet", "quavers", "rest", "minim"]), 5)
	assert_eq(SchoolPictureArts.beats_of(["quavers", "quavers"]), 2)


## The swatches look like what they are called: every tint lighter and every shade darker than its colour (by
## SchoolPictureArts.TINTS and SHADES), and each secondary colour's hue between its two primaries' hues.
func test_the_swatches_look_like_their_names() -> void:
	var c: Dictionary = SchoolPictureArts.COLOURS
	for tint: String in SchoolPictureArts.TINTS:
		var of := str(SchoolPictureArts.TINTS[tint])
		assert_gt((c[tint] as Color).get_luminance(), (c[of] as Color).get_luminance() + 0.1, "%s is lighter than %s" % [tint, of])
	for shade: String in SchoolPictureArts.SHADES:
		var of := str(SchoolPictureArts.SHADES[shade])
		assert_lt((c[shade] as Color).get_luminance(), (c[of] as Color).get_luminance() - 0.1, "%s is darker than %s" % [shade, of])
	# hues (0-1 round the wheel): red 0, orange about 0.08, yellow about 0.15, green about 0.33, blue about 0.6, purple 0.8
	assert_between((c.orange as Color).h, (c.red as Color).h, (c.yellow as Color).h, "orange: between red and yellow")
	assert_between((c.green as Color).h, (c.yellow as Color).h, (c.blue as Color).h, "green: between yellow and blue")
	assert_between((c.purple as Color).h, (c.blue as Color).h, 1.0, "purple: between blue and red (round the wheel)")
	assert_lt((c.brown as Color).get_luminance(), (c.orange as Color).get_luminance(), "brown is a dark orange")
	assert_almost_eq((c.white as Color).get_luminance(), 1.0, 0.001)
	assert_almost_eq((c.black as Color).get_luminance(), 0.0, 0.001)
