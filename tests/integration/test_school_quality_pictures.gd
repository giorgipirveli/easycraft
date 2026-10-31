extends GutTest
## Owner #94 (the lesson-quality brief): the picture kinds the older units needed (SchoolPictureQuality, drawn inside
## SchoolPicture): a number line with an inequality's solutions (open or filled circle, a ray with its arrowhead), a
## word built from its prefix, root and suffix blocks, a sentence cut into its tagged parts, and the coordinate plane's
## four quadrants. Every sample draws at
## the School's picture sizes; broken data is a problem the content test finds; the inequality's rule is worked out
## again here.

const SAMPLES: Array[Dictionary] = [
	{"kind": "inequality_line", "from": 0, "to": 10, "step": 1, "at": 5, "sign": ">"},
	{"kind": "inequality_line", "from": 0, "to": 10, "step": 1, "at": 4, "sign": "≤", "letter": "w"},
	{"kind": "inequality_line", "from": -6, "to": 6, "step": 1, "at": -3, "sign": "≥"},
	{"kind": "inequality_line", "from": -10, "to": 10, "step": 2, "at": 2.5, "sign": "<", "words": false},
	{"kind": "inequality_line", "from": 0, "to": 100, "step": 10, "at": 50, "sign": "≥", "letter": "c"},
	{"kind": "word_blocks", "parts": [{"text": "un", "role": "prefix", "means": "not"},
		{"text": "break", "role": "root", "means": "break"}, {"text": "able", "role": "suffix", "means": "can be"}],
		"means": "cannot be broken"},
	{"kind": "word_blocks", "parts": [{"text": "tele", "role": "root", "means": "far"},
		{"text": "scope", "role": "root", "means": "look"}]},
	{"kind": "word_blocks", "parts": [{"text": "hope", "role": "root"}, {"text": "ful", "role": "suffix"}]},
	{"kind": "word_blocks", "parts": [{"text": "in", "role": "prefix", "means": "not"},
		{"text": "cred", "role": "root", "means": "believe"}, {"text": "ible", "role": "suffix", "means": "can be"}],
		"means": "hard to believe"},
	{"kind": "word_blocks", "parts": [{"text": "photo", "means": "light"}, {"text": "graph", "means": "write, draw"}]},
	{"kind": "sentence_parts", "parts": [{"text": "When the wind blew,", "tag": "dependent clause"},
		{"text": "the door banged.", "tag": "independent clause"}]},
	{"kind": "sentence_parts", "parts": [{"text": "The dog", "tag": "subject"}, {"text": "barked", "tag": "verb"},
		{"text": "under the bridge.", "tag": "phrase"}]},
	{"kind": "sentence_parts", "parts": [{"text": "The wind blew,", "tag": "independent clause"},
		{"text": "and", "tag": "conjunction"}, {"text": "the door banged.", "tag": "independent clause"}],
		"tags": false},
	{"kind": "sentence_parts", "parts": [{"text": "Covered in mud,", "tag": "modifier"},
		{"text": "the dog ran inside.", "tag": "independent clause"}]},
	{"kind": "coordinate_plane", "range": 5, "points": [{"x": -4, "y": 3, "label": "A"}, {"x": 2, "y": -1, "label": "B"}]},
	{"kind": "coordinate_plane", "range": 10, "step": 2, "points": [{"x": 3, "y": 2}, {"x": 3, "y": -2},
		{"x": -3, "y": -2}, {"x": -3, "y": 2}], "join": true},
	{"kind": "coordinate_plane", "range": 2},
]
const BROKEN: Array[Dictionary] = [
	{"kind": "inequality_line", "from": 10, "to": 0, "step": 1, "at": 5, "sign": ">"},
	{"kind": "inequality_line", "from": 0, "to": 30, "step": 1, "at": 5, "sign": ">"},
	{"kind": "inequality_line", "from": 0, "to": 10, "step": 1, "at": 12, "sign": ">"},
	{"kind": "inequality_line", "from": 0, "to": 10, "step": 1, "at": 5, "sign": "="},
	{"kind": "inequality_line", "from": 0.5, "to": 10, "step": 1, "at": 5, "sign": ">"},
	{"kind": "word_blocks", "parts": []},
	{"kind": "word_blocks", "parts": [{"text": "un", "role": "middle"}]},
	{"kind": "word_blocks", "parts": [{"text": "antidisestablish"}]},
	{"kind": "sentence_parts", "parts": [{"text": "The dog barked.", "tag": "noun"}]},
	{"kind": "sentence_parts", "parts": [{"text": "", "tag": "verb"}]},
	{"kind": "coordinate_plane", "range": 12},
	{"kind": "coordinate_plane", "range": 5, "points": [{"x": 6, "y": 0}]},
	{"kind": "coordinate_plane", "range": 5, "step": 3},
	{"kind": "coordinate_plane", "range": 5, "points": [{"x": 1.5, "y": 0}]},
]
const SIZES: Array[Vector2] = [Vector2(560, 380), Vector2(580, 250), Vector2(240, 150)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_broken_data_is_a_problem() -> void:
	for d in BROKEN:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_every_kind_has_samples() -> void:
	var seen := {}
	for d in SAMPLES:
		seen[str(d.kind)] = true
		if d.has("sign"):
			seen["sign:" + str(d.sign)] = true
	for k in SchoolPictureQuality.KINDS:
		assert_true(seen.has(k), k)
	for s in SchoolPictureQuality.SIGNS:
		assert_true(seen.has("sign:" + s), s)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


## Owner #94 (a real bug in the table kind): a cell's words wider than their cell were drawn over the next cell.
## `SchoolPicture.table_font_size` shrinks them to fit (never below TABLE_LEAST_FONT); short words keep FONT.
func test_a_table_cell_shrinks_its_words_to_fit() -> void:
	var font := ThemeDB.fallback_font
	assert_eq(SchoolPicture.table_font_size(font, "cold", 186.0), SchoolPicture.FONT, "short words keep the font")
	var long := "Okafor, B. (2019) Busy Bees"
	var fs := SchoolPicture.table_font_size(font, long, 186.0)
	assert_lt(fs, SchoolPicture.FONT, "long words shrink")
	assert_gte(fs, SchoolPicture.TABLE_LEAST_FONT)
	assert_lte(font.get_string_size(long, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, 186.0, "and fit their cell")


## The four quadrants: (+, +) is I, (−, +) II, (−, −) III, (+, −) IV; a point on an axis is in none.
func test_the_quadrants() -> void:
	assert_eq(SchoolPictureQuality.quadrant(2, 5), 1)
	assert_eq(SchoolPictureQuality.quadrant(-4, 3), 2)
	assert_eq(SchoolPictureQuality.quadrant(-1, -6), 3)
	assert_eq(SchoolPictureQuality.quadrant(5, -2), 4)
	assert_eq(SchoolPictureQuality.quadrant(0, 7), 0)
	assert_eq(SchoolPictureQuality.quadrant(-7, 0), 0)


## The inequality's solutions, worked out here: x > 5 leaves out 5 (an open circle) and goes right; x ≤ 4 takes in 4
## (a filled circle) and goes left.
func test_the_inequality_line_shades_the_solutions() -> void:
	var more := {"kind": "inequality_line", "from": 0, "to": 10, "step": 1, "at": 5, "sign": ">"}
	assert_false(SchoolPictureQuality.holds(more, 5.0))
	assert_true(SchoolPictureQuality.holds(more, 5.5))
	assert_false(SchoolPictureQuality.holds(more, 4.0))
	assert_false(SchoolPictureQuality.filled(more))
	assert_eq(SchoolPictureQuality.ray_way(more), 1)
	var at_most := {"kind": "inequality_line", "from": 0, "to": 10, "step": 1, "at": 4, "sign": "≤"}
	assert_true(SchoolPictureQuality.holds(at_most, 4.0))
	assert_true(SchoolPictureQuality.holds(at_most, -1.0))
	assert_false(SchoolPictureQuality.holds(at_most, 4.5))
	assert_true(SchoolPictureQuality.filled(at_most))
	assert_eq(SchoolPictureQuality.ray_way(at_most), -1)
	var at_least := {"kind": "inequality_line", "from": -6, "to": 6, "step": 1, "at": -3, "sign": "≥"}
	assert_true(SchoolPictureQuality.holds(at_least, -3.0))
	assert_eq(SchoolPictureQuality.ray_way(at_least), 1)
	var less := {"kind": "inequality_line", "from": -6, "to": 6, "step": 1, "at": -3, "sign": "<"}
	assert_false(SchoolPictureQuality.holds(less, -3.0))
	assert_true(SchoolPictureQuality.holds(less, -4.0))
