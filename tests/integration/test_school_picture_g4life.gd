extends GutTest
## Grade 4 health and PE, design and technology, and projects: the picture kinds they add (SchoolPictureG4Life, drawn
## inside SchoolPicture): a circuit of real-looking parts round a loop of wire (a switch open or closed, a gap with or
## without something in it, bulbs lit or not), the beach flags, a food label's traffic lights, players on a pitch finding
## space (and a rounders field's posts), a plan seen from above (an orienteering map, a river town), a vehicle's chassis
## with its axles and wheels, and the helping hand of trusted adults. Every kind draws from its data at the School's
## picture sizes; broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "circuit", "parts": ["cell", "bulb"]},
	{"kind": "circuit", "parts": ["cell", "switch", "bulb"], "switch": "open", "names": true},
	{"kind": "circuit", "parts": ["cell", "switch", "bulb", "bulb"], "lit": true},
	{"kind": "circuit", "parts": ["cell", "gap", "buzzer", "led", "motor"], "gap": "paper clip", "names": true},
	{"kind": "circuit", "parts": ["cell", "cell", "switch", "motor", "gap", "bulb"], "switch": "closed"},
	{"kind": "beach_flags", "flags": ["red_yellow"]},
	{"kind": "beach_flags", "flags": ["red_yellow", "chequered", "red", "windsock"], "labels": ["A", "B", "C", "D"]},
	{"kind": "food_label", "rows": [["Fat", "2.1 g", "low"], ["Saturates", "0.4 g", "low"], ["Sugars", "24 g", "high"],
		["Salt", "0.9 g", "medium"]], "name": "Oat crunch"},
	{"kind": "food_label", "rows": [["Energy", "420 kJ", "none"], ["Sugars", "3.2 g", "?"]], "per": "per 100 mL"},
	{"kind": "pitch", "cols": 12, "rows": 7, "players": [[3, 3, "a", "A"], [6, 1, "a", "B"], [7, 5, "a", "C"],
		[5, 2, "d"], [8, 5, "d"], [9, 3, "d"]], "ball": 0},
	{"kind": "pitch", "cols": 10, "rows": 8, "layout": "rounders", "players": [[5, 7, "a"], [8, 5, "d", "A"],
		[2, 2, "d", "B"]]},
	{"kind": "pitch", "cols": 8, "rows": 5, "layout": "court", "players": [[1.5, 2.5, "a", "A"], [6.5, 2.5, "d"]]},
	{"kind": "site_plan", "rows": ["..T.2", "S.TT.", "..~~.", "1.=~F"]},
	{"kind": "site_plan", "rows": ["^^..TT", "..pp..", "~~=~~~", "##.HM.", "##.H.."], "grid": true, "key": true},
	{"kind": "site_plan", "rows": ["r"], "north": false},
	{"kind": "chassis", "axles": ["square", "square"]},
	{"kind": "chassis", "axles": ["square", "crooked"], "labels": true},
	{"kind": "chassis", "axles": ["square", "square", "square"], "wheels": "mixed"},
	{"kind": "hand", "labels": ["Mum", "Grandad", "my teacher", "Aunt Rosa", "coach Sam"]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_part_flag_and_symbol_has_a_sample() -> void:
	var kinds := {}
	var parts := {}
	var flags := {}
	var levels := {}
	var symbols := {}
	var layouts := {}
	for d in SAMPLES:
		kinds[d.kind] = true
		for p: String in d.get("parts", []):
			parts[p] = true
		for f: String in d.get("flags", []):
			flags[f] = true
		if d.kind == "food_label":
			for row: Array in d.rows:
				levels[row[2]] = true
		if d.kind == "site_plan":
			for row: String in d.rows:
				for ch in row:
					symbols[ch if not ch.is_valid_int() else "1"] = true
		if d.kind == "pitch":
			layouts[str(d.get("layout", "invasion"))] = true
	for k: String in SchoolPictureG4Life.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	assert_eq(kinds.size(), SchoolPictureG4Life.KINDS.size())
	for p: String in SchoolPictureG4Life.PARTS:
		assert_true(parts.has(p), "a sample of the part %s" % p)
	for f: String in SchoolPictureG4Life.FLAGS:
		assert_true(flags.has(f), "a sample of the flag %s" % f)
	for l: String in SchoolPictureG4Life.LEVELS:
		assert_true(levels.has(l), "a sample of the label level %s" % l)
	for s: String in SchoolPictureG4Life.SYMBOLS:
		assert_true(symbols.has(s) or (s.is_valid_int() and symbols.has("1")), "a sample of the plan symbol %s" % s)
	for l: String in SchoolPictureG4Life.LAYOUTS:
		assert_true(layouts.has(l), "a sample of the pitch layout %s" % l)


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
			{"kind": "circuit"}, {"kind": "circuit", "parts": ["cell"]}, {"kind": "circuit", "parts": ["cell", "fan"]},
			{"kind": "circuit", "parts": ["cell", "bulb", "bulb", "bulb", "bulb", "bulb", "bulb"]},
			{"kind": "circuit", "parts": ["cell", "bulb"], "switch": "open"},
			{"kind": "circuit", "parts": ["cell", "switch", "bulb"], "switch": "half"},
			{"kind": "circuit", "parts": ["cell", "gap", "gap"]},
			{"kind": "circuit", "parts": ["cell", "bulb"], "gap": "foil"},
			{"kind": "circuit", "parts": ["cell", "gap"], "gap": "a very long thing indeed"},
			{"kind": "circuit", "parts": ["cell", "bulb"], "lit": "yes"},
			{"kind": "beach_flags"}, {"kind": "beach_flags", "flags": []}, {"kind": "beach_flags", "flags": ["blue"]},
			{"kind": "beach_flags", "flags": ["red", "red", "red", "red", "red"]},
			{"kind": "beach_flags", "flags": ["red"], "labels": ["A", "B"]},
			{"kind": "food_label"}, {"kind": "food_label", "rows": []},
			{"kind": "food_label", "rows": [["Fat", "2 g"]]}, {"kind": "food_label", "rows": [["Fat", "2 g", "purple"]]},
			{"kind": "food_label", "rows": [["Fat", "2 g", "low"], ["Fat", "2 g", "low"], ["Fat", "2 g", "low"],
				["Fat", "2 g", "low"], ["Fat", "2 g", "low"], ["Fat", "2 g", "low"]]},
			{"kind": "food_label", "rows": [["Polyunsaturates", "2 g", "low"]]},
			{"kind": "food_label", "rows": [["Fat", "2 g", "low"]], "name": "a name that is much too long for it"},
			{"kind": "pitch", "cols": 12, "rows": 7}, {"kind": "pitch", "cols": 3, "rows": 7, "players": [[1, 1, "a"]]},
			{"kind": "pitch", "cols": 12, "rows": 7, "players": [[13, 1, "a"]]},
			{"kind": "pitch", "cols": 12, "rows": 7, "players": [[1, 1, "x"]]},
			{"kind": "pitch", "cols": 12, "rows": 7, "players": [[1, 1, "a", "ABC"]]},
			{"kind": "pitch", "cols": 12, "rows": 7, "players": [[1, 1, "a"]], "ball": 1},
			{"kind": "pitch", "cols": 12, "rows": 7, "players": [[1, 1, "a"]], "layout": "tennis"},
			{"kind": "site_plan"}, {"kind": "site_plan", "rows": []}, {"kind": "site_plan", "rows": ["..", "."]},
			{"kind": "site_plan", "rows": ["..Q"]}, {"kind": "site_plan", "rows": ["............."]},
			{"kind": "site_plan", "rows": [".", ".", ".", ".", ".", ".", ".", ".", "."]},
			{"kind": "chassis"}, {"kind": "chassis", "axles": []}, {"kind": "chassis", "axles": ["bent"]},
			{"kind": "chassis", "axles": ["square", "square", "square", "square"]},
			{"kind": "chassis", "axles": ["square", "square"], "wheels": "square"},
			{"kind": "hand"}, {"kind": "hand", "labels": ["a", "b", "c", "d"]},
			{"kind": "hand", "labels": ["a", "b", "c", "d", "someone far too long"]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))
