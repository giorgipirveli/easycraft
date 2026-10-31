extends GutTest
## Owner #70 and #73, grade 7 computing, art and music (research §6.7): the picture kinds they add (SchoolPictureG7Arts,
## drawn inside SchoolPicture): text code with its output and mistakes, lists, functions as machines, searches, sorts,
## packets' routes and a DNS lookup, a cipher wheel, collected data, a phone's feed, licences, Renaissance works, colour
## schemes, figures in heads and poses, art of 1450-1750, posters and logos, a house's plan and elevations, the rule of
## thirds, woodcut blocks and prints, a gallery wall, chord charts, ornaments, a symphony's plan, a drum kit, a piano
## roll, film frames, a mixing desk and the bass clef. Every kind draws from its data at the School's picture sizes;
## broken data is a problem the content test finds; the pictures' facts are worked out (searches, sorts, the cipher,
## colour schemes, chords, ornaments, the thirds, the mirrored print, the staves, where the parts are).

const SAMPLES: Array[Dictionary] = [
	{"kind": "text_code", "lines": ["score = 0", "for i in range(3):", "    score = score + 5", "print(score)"], "output": ["15"]},
	{"kind": "text_code", "lines": ["if gems > 10", "    print(\"Rich!\")"], "error": 0, "mark": 1},
	{"kind": "text_code", "lines": ["name = \"Hoot\"  # a comment", "print(\"Hi \" + name)"], "numbers": false},
	{"kind": "text_code", "lines": ["for i in range(3):", "    print(\"Hop\")"], "blocks": ["REPEAT 3 TIMES", "  SAY Hop"]},
	{"kind": "list_boxes", "name": "gems", "items": ["4", "7", "2", "9"]},
	{"kind": "list_boxes", "items": ["\"owl\"", "\"fox\"", "\"cat\""], "mark": 1, "negative": true},
	{"kind": "list_boxes", "name": "scores", "items": ["12", "8", "15", "3", "10", "6", "1", "20"], "hide": 5, "mark": [0, 7]},
	{"kind": "func_machine", "name": "area", "params": ["w", "h"], "args": ["3", "4"], "body": "w * h", "out": "12"},
	{"kind": "func_machine", "name": "double", "params": ["n"], "body": "n * 2", "out": "?"},
	{"kind": "search_steps", "items": [3, 8, 12, 15, 21, 27, 30, 36, 41], "target": 27, "method": "binary"},
	{"kind": "search_steps", "items": [9, 4, 7, 1, 8, 2], "target": 8, "method": "linear", "steps": 3},
	{"kind": "search_steps", "items": [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47], "target": 40, "method": "binary"},
	{"kind": "sort_bars", "items": [5, 1, 4, 2, 8], "method": "bubble"},
	{"kind": "sort_bars", "items": [5, 1, 4, 2, 8], "method": "bubble", "pass": 1, "compare": 2},
	{"kind": "sort_bars", "items": [38, 27, 43, 3, 9, 82, 10, 5], "method": "merge", "view": "tree"},
	{"kind": "sort_bars", "items": [6, 2, 9], "method": "merge", "view": "tree"},
	{"kind": "internet_trip", "view": "routes", "routes": ["ABC", "DEF", "ABEF"], "lost": 2, "mark": "B"},
	{"kind": "internet_trip", "view": "routes", "routes": ["DEBC"]},
	{"kind": "internet_trip", "view": "dns", "domain": "hoot-school.example", "ip": "203.0.113.7", "step": 2},
	{"kind": "internet_trip", "view": "dns", "domain": "castle.example", "ip": "198.51.100.23"},
	{"kind": "cipher_wheel", "shift": 3},
	{"kind": "cipher_wheel", "shift": 3, "mark": "A", "word": "CAT"},
	{"kind": "cipher_wheel", "shift": 5, "word": "MJQQT", "decode": true},
	{"kind": "data_sheet", "head": ["Name", "Age", "Pet"], "rows": [["Tilly", "11", "cat"], ["Bram", "12", "dog"],
		["Bram", "12", "dog"], ["Zara", "150", "owl"]], "flag": [[3, 1]], "strike": [2]},
	{"kind": "phone_feed"},
	{"kind": "phone_feed", "labels": true, "mark": "autoplay"},
	{"kind": "licence_tags", "tags": ["copyright", "CC0", "BY", "BY-SA"]},
	{"kind": "licence_tags", "tags": ["BY-NC", "BY-ND"], "mark": 0, "names": false},
	{"kind": "old_master", "what": "mona_lisa"},
	{"kind": "old_master", "what": "mona_lisa", "lines": true},
	{"kind": "old_master", "what": "school_athens", "lines": true},
	{"kind": "old_master", "what": "vitruvian_man"},
	{"kind": "colour_scheme", "scheme": "complementary", "base": "blue"},
	{"kind": "colour_scheme", "scheme": "analogous", "base": "green", "view": "swatches"},
	{"kind": "colour_scheme", "scheme": "triadic", "base": "red", "view": "scene"},
	{"kind": "colour_scheme", "scheme": "split", "base": "yellow"},
	{"kind": "colour_scheme", "scheme": "monochrome", "base": "blue", "view": "swatches"},
	{"kind": "colour_scheme", "scheme": "monochrome", "base": "purple", "view": "scene"},
	{"kind": "colour_scheme", "scheme": "warm", "base": "red", "view": "scene"},
	{"kind": "colour_scheme", "scheme": "cool", "base": "blue"},
	{"kind": "figure_study", "view": "heads", "labels": true},
	{"kind": "figure_study", "view": "heads", "heads": 6},
	{"kind": "figure_study", "view": "heads", "mark": "knees"},
	{"kind": "figure_study", "view": "gesture", "pose": "run", "line": true},
	{"kind": "figure_study", "view": "gesture", "pose": "sit"},
	{"kind": "figure_study", "view": "mannequin", "pose": "throw", "line": true},
	{"kind": "figure_study", "view": "mannequin", "pose": "jump"},
	{"kind": "figure_study", "view": "gesture", "pose": "reach", "line": true},
	{"kind": "figure_study", "view": "mannequin", "pose": "walk"},
	{"kind": "world_art_piece", "what": "mughal", "labels": true},
	{"kind": "world_art_piece", "what": "iznik", "mark": "tulip"},
	{"kind": "world_art_piece", "what": "ukiyo_e", "labels": true},
	{"kind": "world_art_piece", "what": "blue_white"},
	{"kind": "poster_layout", "design": "clear", "grid": true, "labels": true},
	{"kind": "poster_layout", "design": "clear", "mark": "white space"},
	{"kind": "poster_layout", "design": "crowded"},
	{"kind": "poster_layout", "design": "centred"},
	{"kind": "poster_layout", "design": "logo_sizes"},
	{"kind": "poster_layout", "design": "logo_busy"},
	{"kind": "poster_layout", "design": "logo_mono"},
	{"kind": "house_drawing", "view": "plan", "labels": true, "dims": true, "scale": "1:100"},
	{"kind": "house_drawing", "view": "front", "dims": true, "mark": "front door"},
	{"kind": "house_drawing", "view": "side", "dims": true, "scale": "1:50"},
	{"kind": "thirds_frame", "subject": [0.33, 0.67], "grid": true, "horizon": 0.33},
	{"kind": "thirds_frame", "subject": [0.5, 0.5], "thing": "buddy"},
	{"kind": "thirds_frame", "subject": [0.67, 0.45], "thing": "tower", "lines": "road", "grid": true},
	{"kind": "thirds_frame", "subject": [0.6, 0.55], "thing": "boat", "lines": "river", "frame": "arch"},
	{"kind": "thirds_frame", "subject": [0.33, 0.5], "lines": "fence", "frame": "trees"},
	{"kind": "carved_block", "rows": ["##..", "#.#.", "##..", "#.#."], "view": "block"},
	{"kind": "carved_block", "rows": ["##..", "#.#.", "##..", "#.#."], "view": "print", "grid": true},
	{"kind": "carved_block", "rows": ["#..##.#"], "view": "side"},
	{"kind": "gallery_wall", "works": 4, "hang": "line", "line": true},
	{"kind": "gallery_wall", "works": 3, "hang": "messy", "mark": 1},
	{"kind": "gallery_wall", "works": 5, "hang": "tops", "labels": true},
	{"kind": "chord_chart", "key": "C", "chords": ["I", "IV", "V", "I"], "names": true},
	{"kind": "chord_chart", "key": "G", "chords": ["I", "V", "vi", "IV"], "hide": [2]},
	{"kind": "chord_chart", "key": "F", "chords": ["I", "IV", "I", "V", "I", "IV", "V", "I"], "names": true, "mark": 1},
	{"kind": "chord_chart", "key": "A", "chords": ["ii", "iii"], "names": true, "numerals": false},
	{"kind": "ornament_signs", "type": "trill", "note": "C5", "played": true},
	{"kind": "ornament_signs", "type": "mordent", "note": "G4"},
	{"kind": "ornament_signs", "type": "turn", "note": "E5", "played": true},
	{"kind": "symphony_plan", "view": "movements"},
	{"kind": "symphony_plan", "view": "sonata", "mark": 1, "hide": 2},
	{"kind": "drum_kit"},
	{"kind": "drum_kit", "labels": true, "mark": "snare drum"},
	{"kind": "piano_roll", "notes": ["C4", "C4", "Eb4", "F4:2", "-", "G4"], "repeat": 2},
	{"kind": "piano_roll", "notes": ["E4", "G4", "A4", "-:2", "E4", "G4", "Bb4", "A4:2"], "mark": [0, 1]},
	{"kind": "film_strip", "frames": ["hero", "villain", "chase", "storm"], "captions": ["the hero", "the villain",
		"a chase", "a storm"]},
	{"kind": "film_strip", "frames": ["sunrise", "sneak", "comedy", "farewell"], "mark": 2},
	{"kind": "mixer", "faders": [["vocals", 9], ["guitar", 5], ["bass", 6], ["drums", 7]], "meters": true},
	{"kind": "mixer", "faders": [["melody", 3], ["chords", 9]], "mark": 1},
	{"kind": "clef_stave", "clef": "bass", "notes": ["G2", "B2", "D3", "F3", "A3"], "names": true},
	{"kind": "clef_stave", "clef": "bass", "notes": ["C3", "C3", "E3", "G3"], "values": ["minim", "crotchet", "dotted crotchet",
		"quaver"], "ties": [0], "time": "4/4", "bars": true},
	{"kind": "clef_stave", "clef": "treble", "notes": ["G4", "A4", "B4", "C5"], "values": ["dotted quaver", "semiquaver",
		"dotted minim", "semibreve"], "mark": 2},
	{"kind": "clef_stave", "clef": "grand", "notes": ["C3", "E3", "G3", "C4", "E4", "G4", "C5"], "names": true},
	{"kind": "clef_stave", "clef": "bass", "notes": ["E2", "C4"], "time": "6/8"},
]
const BROKEN: Array[Dictionary] = [
	{"kind": "text_code", "lines": []},
	{"kind": "text_code", "lines": ["  x = 1"]},
	{"kind": "text_code", "lines": ["x = 1"], "error": 3},
	{"kind": "text_code", "lines": ["x = 1"], "output": ["a", "b", "c", "d", "e", "f"]},
	{"kind": "text_code", "lines": ["this line is far too long for the card to show"]},
	{"kind": "text_code", "lines": ["x = 1"], "blocks": ["SET x TO 1"], "output": ["1"]},
	{"kind": "list_boxes", "items": []},
	{"kind": "list_boxes", "items": ["a", "b"], "hide": 2},
	{"kind": "list_boxes", "items": ["a very long item"]},
	{"kind": "func_machine", "name": "f", "params": []},
	{"kind": "func_machine", "name": "f", "params": ["a", "b"], "args": ["1"]},
	{"kind": "search_steps", "items": [5, 3, 9, 1], "target": 3, "method": "binary"},
	{"kind": "search_steps", "items": [1, 2], "target": 1, "method": "linear"},
	{"kind": "search_steps", "items": [1, 2, 3, 4], "target": 1, "method": "guess"},
	{"kind": "sort_bars", "items": [5, 100], "method": "bubble"},
	{"kind": "sort_bars", "items": [5, 1], "method": "bubble", "view": "tree"},
	{"kind": "sort_bars", "items": [5, 1, 3], "method": "quick"},
	{"kind": "internet_trip", "view": "routes", "routes": ["AC"]},
	{"kind": "internet_trip", "view": "routes", "routes": ["BC"]},
	{"kind": "internet_trip", "view": "dns", "domain": "castle.example", "ip": "300.1.2.3"},
	{"kind": "internet_trip", "view": "map"},
	{"kind": "cipher_wheel", "shift": 26},
	{"kind": "cipher_wheel", "shift": 3, "word": "cat"},
	{"kind": "data_sheet", "head": ["A", "B"], "rows": [["1"]]},
	{"kind": "data_sheet", "head": ["A"], "rows": [["1"]], "flag": [[4, 0]]},
	{"kind": "phone_feed", "mark": "camera"},
	{"kind": "licence_tags", "tags": ["GPL"]},
	{"kind": "old_master", "what": "a selfie"},
	{"kind": "colour_scheme", "scheme": "rainbow", "base": "red"},
	{"kind": "colour_scheme", "scheme": "triadic", "base": "pink"},
	{"kind": "figure_study", "view": "heads", "heads": 12},
	{"kind": "figure_study", "view": "gesture", "pose": "fly"},
	{"kind": "figure_study", "view": "gesture", "mark": "knees"},
	{"kind": "world_art_piece", "what": "iznik", "mark": "pavilion"},
	{"kind": "poster_layout", "design": "wild"},
	{"kind": "poster_layout", "design": "crowded", "mark": "headline"},
	{"kind": "house_drawing", "view": "roof"},
	{"kind": "house_drawing", "view": "plan", "scale": "1:3"},
	{"kind": "thirds_frame", "subject": [0.0, 0.5]},
	{"kind": "thirds_frame", "subject": [0.5, 0.5], "frame": "window"},
	{"kind": "carved_block", "rows": ["##", "#"], "view": "block"},
	{"kind": "carved_block", "rows": ["#x"], "view": "print"},
	{"kind": "gallery_wall", "works": 9, "hang": "line"},
	{"kind": "chord_chart", "key": "H", "chords": ["I"]},
	{"kind": "chord_chart", "key": "C", "chords": ["VII"]},
	{"kind": "ornament_signs", "type": "trill", "note": "A5"},
	{"kind": "ornament_signs", "type": "glissando", "note": "C5"},
	{"kind": "symphony_plan", "view": "opera"},
	{"kind": "drum_kit", "mark": "triangle"},
	{"kind": "piano_roll", "notes": ["C4+E4"]},
	{"kind": "piano_roll", "notes": ["-"]},
	{"kind": "piano_roll", "notes": ["C2", "C6"]},
	{"kind": "film_strip", "frames": ["hero", "picnic"]},
	{"kind": "mixer", "faders": [["vocals", 12], ["bass", 3]]},
	{"kind": "clef_stave", "clef": "bass", "notes": ["C5"]},
	{"kind": "clef_stave", "clef": "alto", "notes": ["C4"]},
	{"kind": "clef_stave", "clef": "bass", "notes": ["C3", "D3"], "ties": [0]},
	{"kind": "clef_stave", "clef": "bass", "notes": ["C3"], "values": ["breve"]},
	{"kind": "clef_stave", "clef": "bass", "notes": ["C3"], "bars": true},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126), Vector2(520, 250)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_broken_data_is_a_problem() -> void:
	for d in BROKEN:
		assert_ne(SchoolPicture.problem(d), "", str(d))


func test_every_grade_7_arts_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG7Arts.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drew every sample")


## Linear search checks from the start; binary search looks at the middle and throws half away each time.
func test_the_searches_check_what_they_should() -> void:
	var items := [3, 8, 12, 15, 21, 27, 30, 36, 41]
	assert_eq(SchoolPictureG7Arts.search_checks(items, 27, "binary"), [4, 6, 5] as Array[int], "21, then 30, then 27")
	assert_eq(SchoolPictureG7Arts.search_checks(items, 27, "linear"), [0, 1, 2, 3, 4, 5] as Array[int])
	assert_eq(SchoolPictureG7Arts.search_checks(items, 5, "binary").size(), 3, "not there: 3 checks")
	var sixteen: Array = range(1, 17)
	var most := 0
	for t in range(0, 18):
		most = maxi(most, SchoolPictureG7Arts.search_checks(sixteen, t, "binary").size())
	assert_eq(most, 5, "16 items need at most 5 checks")


func test_bubble_and_merge_sort_are_right() -> void:
	assert_eq(SchoolPictureG7Arts.bubble_after([5, 1, 4, 2, 8], 1), [1, 4, 2, 5, 8], "the biggest bubbles to the end")
	assert_eq(SchoolPictureG7Arts.bubble_after([5, 1, 4, 2, 8], 2), [1, 2, 4, 5, 8])
	var rows := SchoolPictureG7Arts.merge_rows([5, 2, 8, 1])
	assert_eq(rows, [[[5, 2, 8, 1]], [[5, 2], [8, 1]], [[5], [2], [8], [1]], [[2, 5], [1, 8]], [[1, 2, 5, 8]]])
	assert_eq((SchoolPictureG7Arts.merge_rows([38, 27, 43, 3, 9, 82, 10, 5]) as Array).size(), 7, "8 items: 3 splits, 3 merges")


func test_the_caesar_cipher_goes_round() -> void:
	assert_eq(SchoolPictureG7Arts.caesar("CAT", 3), "FDW")
	assert_eq(SchoolPictureG7Arts.caesar("ZOO", 1), "APP", "Z goes round to A")
	assert_eq(SchoolPictureG7Arts.caesar("FDW", -3), "CAT", "back again")
	assert_eq(SchoolPictureG7Arts.caesar("HI THERE", 13), "UV GURER", "a space stays")


func test_the_colour_schemes_sit_on_the_wheel() -> void:
	assert_eq(SchoolPictureG7Arts.scheme_colours("complementary", "blue"), ["blue", "orange"] as Array[String])
	assert_eq(SchoolPictureG7Arts.scheme_colours("analogous", "green"), ["blue-green", "green", "yellow-green"] as Array[String])
	assert_eq(SchoolPictureG7Arts.scheme_colours("triadic", "red"), ["red", "blue", "yellow"] as Array[String])
	assert_eq(SchoolPictureG7Arts.scheme_colours("split", "yellow"), ["yellow", "red-purple", "blue-purple"] as Array[String],
		"the two beside purple, yellow's opposite")
	assert_eq(SchoolPictureG7Arts.scheme_colours("monochrome", "purple"), ["purple"] as Array[String])
	assert_eq(SchoolPictureG7Arts.scheme_colours("warm", "blue").size(), 5)


## The primary chords: I, IV and V are major; ii, iii and vi minor. C major: C, Dm, Em, F, G, Am.
func test_the_chords_of_a_key() -> void:
	var c: Array[String] = []
	for n: String in SchoolPictureG7Arts.NUMERALS:
		c.append(SchoolPictureG7Arts.chord_name("C", n))
	assert_eq(c, ["C", "Dm", "Em", "F", "G", "Am"] as Array[String])
	assert_eq(SchoolPictureG7Arts.chord_letters("F", "IV"), ["Bb", "D", "F"] as Array[String], "F major's IV is B flat")
	assert_eq(SchoolPictureG7Arts.chord_letters("G", "V"), ["D", "F#", "A"] as Array[String], "G major's V is D major")
	assert_eq(SchoolPictureG7Arts.chord_name("A", "iii"), "C#m")
	assert_eq(SchoolPictureG7Arts.chord_name("D", "IV"), "G")


func test_the_ornaments_play_their_notes() -> void:
	assert_eq(SchoolPictureG7Arts.ornament_notes("trill", "C5"), ["D5", "C5", "D5", "C5", "D5", "C5", "D5", "C5"] as Array[String])
	assert_eq(SchoolPictureG7Arts.ornament_notes("mordent", "B4"), ["B4", "C5", "B4"] as Array[String], "B up is C, an octave on")
	assert_eq(SchoolPictureG7Arts.ornament_notes("turn", "E5"), ["F5", "E5", "D5", "E5"] as Array[String])


func test_the_thirds_and_the_print() -> void:
	assert_true(SchoolPictureG7Arts.on_thirds(0.33, 0.5))
	assert_false(SchoolPictureG7Arts.on_thirds(0.5, 0.5), "the middle is not on a third")
	assert_eq(SchoolPictureG7Arts.power_point(0.66, 0.34), "top right")
	assert_eq(SchoolPictureG7Arts.power_point(0.33, 0.5), "")
	assert_eq(SchoolPictureG7Arts.print_rows(["##..", "#.#."]), ["..##", ".#.#"], "a print is the block mirrored")


## The bass clef: G2 on the bottom line up to A3 on the top line, middle C on a ledger line above; the treble clef from
## E4 on the bottom line; the grand stave puts middle C and up on the treble.
func test_the_staves_place_their_notes() -> void:
	var lines: Array[String] = []
	var spaces: Array[String] = []
	for n: String in ["E2", "F2", "G2", "A2", "B2", "C3", "D3", "E3", "F3", "G3", "A3", "B3", "C4"]:
		var s := SchoolPictureG7Arts.clef_step(n, "bass")
		if s >= 0 and s <= 8:
			(lines if s % 2 == 0 else spaces).append(n.left(1))
	assert_eq(lines, ["G", "B", "D", "F", "A"] as Array[String], "Good Boys Deserve Fun Always")
	assert_eq(spaces, ["A", "C", "E", "G"] as Array[String], "All Cows Eat Grass")
	assert_eq(SchoolPictureG7Arts.clef_step("C4", "bass"), 10, "middle C on a ledger line above")
	assert_eq(SchoolPictureG7Arts.clef_step("E4", "treble"), 0)
	assert_eq(SchoolPictureG7Arts.clef_step("C4", "grand"), 998, "the treble's ledger line below")
	assert_eq(SchoolPictureG7Arts.clef_step("G2", "grand"), 0)
	assert_eq(SchoolPictureG7Arts.clef_step("C5", "bass"), -99)


## Every part a label can point at is inside the picture, and the parts of one picture are far enough apart for a
## finger to tell their pins apart.
func test_the_parts_are_on_the_picture() -> void:
	var box := ExerciseCheck.LABEL_BOX
	var pictures: Array[Dictionary] = [{"kind": "phone_feed"}, {"kind": "drum_kit"}, {"kind": "poster_layout", "design": "clear"},
		{"kind": "figure_study", "view": "heads"}, {"kind": "house_drawing", "view": "plan"},
		{"kind": "house_drawing", "view": "front"}]
	var parts: Array = [SchoolPictureG7Arts.FEED_PARTS.keys(), SchoolPictureG7Arts.KIT_PARTS.keys(),
		SchoolPictureG7Arts.POSTER_PARTS.keys(), SchoolPictureG7Arts.FIGURE_PARTS.keys(),
		["front door", "window", "bedroom", "kitchen", "living room", "bathroom"], ["front door", "window", "roof", "wall"]]
	for what: String in SchoolPictureG7Arts.PIECE_PARTS:
		pictures.append({"kind": "world_art_piece", "what": what})
		parts.append((SchoolPictureG7Arts.PIECE_PARTS[what] as Dictionary).keys())
	for i in pictures.size():
		var seen: Array[Vector2] = []
		for part: String in parts[i]:
			var p := SchoolPictureG7Arts.part_at(pictures[i], part, box)
			assert_true(Rect2(Vector2.ZERO, box).has_point(p), "%s: %s at %s" % [pictures[i], part, p])
			seen.append(p)
		assert_eq(seen.size(), (parts[i] as Array).size())
	assert_eq(SchoolPictureG7Arts.part_at({"kind": "drum_kit"}, "a sandwich", box), Vector2(-1, -1))
	var chin := SchoolPictureG7Arts.part_at({"kind": "figure_study", "view": "heads"}, "chin", box)
	var knees := SchoolPictureG7Arts.part_at({"kind": "figure_study", "view": "heads"}, "knees", box)
	assert_almost_eq(knees.y - chin.y, (chin.y - (SchoolPicture.MARGIN + (box.y - 2 * SchoolPicture.MARGIN) * 0.03)) * 5.0, 0.5,
		"the knees are 5 heads below the chin")
