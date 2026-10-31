extends GutTest
## Owner #70, #73 and #111: grade 8 computing, art and music generators (SchoolGen "g8c.<name>",
## core/school/gen/g8_arts_gen.gd). Every answer is worked out again here from the exercise's data, picture, sound or
## prompt with this test's own rules: programs are run by the tests' own text-code interpreter
## (tests/fakes/text_code_runner.gd); worst cases, state machines, the little machine, ASCII, file sizes, logic circuits
## and truth tables, queries, nearest neighbours, percentages, passwords, user tests and energy; and the art and music
## rules below.

const Runner := preload("res://tests/fakes/text_code_runner.gd")
const COMPUTING: Array[String] = ["module_trace", "step_count", "state_next", "model_keep", "machine_trace", "char_code",
	"file_size", "gate_out", "truth_rows", "db_query", "nearest_guess", "accuracy", "password_space", "trick_sort",
	"user_test", "device_energy"]
const ART: Array[String] = ["art_order", "tech_order", "artist_movement", "pixel_count", "face_measure", "grid_scale",
	"paint_tins", "form_function", "frame_count", "balance_mobile", "maquette", "hang_height"]
const MUSIC: Array[String] = ["composer_match", "music_order", "whole_tone", "loop_lcm", "swing_hear", "blues_scale",
	"chorus_count", "loop_time", "eq_band", "transpose", "range_fit", "texture_hear", "culture_match", "form_plan",
	"note_read", "bar_check", "motif_move", "chord_fit"]
const SEEDS := 50


func _gens() -> Array[String]:
	return COMPUTING + ART + MUSIC


func _all(gen: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g8c." + gen, s, level)
			ex["_level"] = level
			out.append(ex)
	return out


func _right(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func _value(ex: Dictionary) -> float:
	return NumberAnswer.value(str(ex.answer))


func test_every_generator_is_listed_here() -> void:
	var listed := _gens()
	for id in SchoolGen.ids():
		if id.begins_with("g8c."):
			assert_true(listed.has(id.trim_prefix("g8c.")), "%s is tested here" % id)
	for g in listed:
		assert_true(SchoolGen.exists("g8c." + g), "g8c.%s exists" % g)


func test_every_exercise_is_valid_with_data_a_hint_and_a_worked_answer() -> void:
	for g in _gens():
		for ex in _all(g):
			var where := "%s level %d: %s" % [g, ex._level, ex.prompt]
			assert_eq(ExerciseCheck.problem(ex), "", where)
			assert_true(ex.has("data"), "%s has data" % where)
			assert_gt(str(ex.hint).length(), 10, "%s: a hint" % where)
			assert_gt(str(ex.get("explain", "")).length(), 10, "%s: a worked answer" % where)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % where)


# --- Computing -----------------------------------------------------------------------------------------------------------

func test_module_trace_prints_what_the_runner_prints() -> void:
	for ex in _all("module_trace"):
		var st := Runner.run(ex.data.lines)
		assert_eq(str(st.error), "", "%s runs" % [ex.data.lines])
		assert_eq((st.out as Array).size(), 1, "one line printed")
		assert_almost_eq(_value(ex), float(st.out[0]), 0.0001, str(ex.data.lines))


## Worst cases: linear n, binary ⌊log₂ n⌋ + 1 (this test's own halving count), bubble n(n − 1) ÷ 2.
func _binary(n: int) -> int:
	var k := 0
	var v := n
	while v >= 1:
		k += 1
		v /= 2
	return k


func test_step_count_works_out_the_worst_cases() -> void:
	for ex in _all("step_count"):
		var n := int(ex.data.n)
		var want := 0
		match str(ex.data.kind):
			"linear":
				want = n
			"binary":
				want = _binary(n)
			"bubble":
				want = n * (n - 1) / 2
			"gap":
				want = n - _binary(n)
		assert_eq(int(_value(ex)), want, str(ex.prompt))


func test_state_next_follows_the_arrows() -> void:
	for ex in _all("state_next"):
		var pic: Dictionary = ex.picture
		var s := int(ex.data.start)
		assert_eq(int(pic.current), s, "the picture starts where the prompt does")
		for e: Variant in ex.data.events:
			for a: Array in pic.arrows:
				if int(a[0]) == s and str(a[2]) == str(e):
					s = int(a[1])
					break
		assert_eq(_right(ex), str(pic.states[s]), str(ex.prompt))
		assert_true(str(ex.prompt).contains(str(pic.states[int(ex.data.start)])), "the prompt names the start")


## The details a model keeps (they change its answer; this test's own list): everything else is left out.
const KEPT: Array[String] = ["the order of the stops", "where to change lines", "the names of the stops", "its colours",
	"how long each colour stays on", "the order of the colours", "the height it drops from", "how bouncy it is",
	"the pull of gravity", "air pressure", "temperature", "wind speed", "how wet the air is", "pupils arriving each minute",
	"how long serving takes", "how many serving points", "rabbits born each month", "rabbits that die each month",
	"the food there is", "how dry the trees are", "the wind's direction", "how close the trees are",
	"the floors it stops at", "how many people fit", "the buttons pressed", "how full it is", "the power the screen uses",
	"how long apps run"]


func test_model_keep_sorts_by_what_matters() -> void:
	for ex in _all("model_keep"):
		var kinds := {}
		for i in (ex.items as Array).size():
			var item := str(ex.items[i])
			assert_eq(int(ex.answer[i]), 0 if KEPT.has(item) else 1, "%s: %s" % [ex.data.purpose, item])
			kinds[int(ex.answer[i])] = true
		assert_eq(kinds.size(), 2, "both groups used")


func test_machine_trace_runs_the_little_machine() -> void:
	for ex in _all("machine_trace"):
		var acc := 0
		var outs: Array[int] = []
		var ran := 0
		for row: Array in ex.data.memory:
			ran += 1
			var op := str(row[1]).split(" ")
			if op[0] == "LOAD":
				acc = int(op[1])
			elif op[0] == "ADD":
				acc += int(op[1])
			elif op[0] == "SUB":
				acc -= int(op[1])
			elif op[0] == "OUT":
				outs.append(acc)
			elif op[0] == "HALT":
				break
			assert_gte(acc, 0, "the accumulator never goes below 0")
		match str(ex.data.ask):
			"out":
				assert_eq(int(_value(ex)), outs[0], str(ex.data.memory))
			"second":
				assert_eq(int(_value(ex)), outs[1], str(ex.data.memory))
			"count":
				assert_eq(int(_value(ex)), ran, str(ex.data.memory))


func test_char_code_uses_ascii() -> void:
	for ex in _all("char_code"):
		match str(ex.data.ask):
			"code":
				assert_eq(int(_value(ex)), str(ex.data.char).unicode_at(0), str(ex.prompt))
			"char":
				assert_eq(_right(ex), String.chr(int(ex.data.code)), str(ex.prompt))
			"word":
				var codes: Array[String] = []
				for ch in str(ex.data.word):
					codes.append(str(ch.unicode_at(0)))
				assert_eq(_right(ex), ", ".join(codes), str(ex.prompt))


func test_file_size_multiplies_it_out() -> void:
	for ex in _all("file_size"):
		var d: Dictionary = ex.data
		var want := 0
		match str(d.kind):
			"image_bits":
				want = int(d.w) * int(d.h) * int(d.bits)
			"image_bytes":
				want = int(d.w) * int(d.h) * int(d.bits) / 8
			"sound_bits":
				want = int(d.rate) * int(d.bits) * int(d.seconds)
			"sound_bytes":
				want = int(d.rate) * int(d.bits) * int(d.seconds) / 8
			"text_bytes":
				want = int(d.chars) * 8
		assert_eq(int(_value(ex)), want, str(ex.prompt))


## This test's own gates.
func _gate(e: Variant, inputs: Dictionary) -> int:
	if e is String:
		return int(inputs[e])
	if str(e[0]) == "NOT":
		return 1 - _gate(e[1], inputs)
	var a := _gate(e[1], inputs)
	var b := _gate(e[2], inputs)
	return (a * b) if str(e[0]) == "AND" else mini(a + b, 1)


func test_gate_out_lights_the_lamp_right() -> void:
	for ex in _all("gate_out"):
		var v := _gate(ex.data.expr, ex.data.inputs)
		assert_eq(_right(ex).begins_with("yes"), v == 1, "%s with %s" % [ex.data.expr, ex.data.inputs])
		assert_eq(ex.picture.out, false, "the lamp is hidden")


func _letters(e: Variant, out: Array) -> void:
	if e is String:
		if not out.has(e):
			out.append(e)
		return
	for i in range(1, (e as Array).size()):
		_letters(e[i], out)


func test_truth_rows_counts_every_row() -> void:
	for ex in _all("truth_rows"):
		if ex.data.has("inputs"):
			assert_eq(int(_value(ex)), 1 << int(ex.data.inputs), str(ex.prompt))
			continue
		var letters: Array = []
		_letters(ex.data.expr, letters)
		var ones := 0
		for row in 1 << letters.size():
			var inputs := {}
			for k in letters.size():
				inputs[letters[k]] = (row >> k) & 1
			ones += _gate(ex.data.expr, inputs)
		assert_eq(int(_value(ex)), ones, str(ex.prompt))


## This test's own WHERE: "animal = 'cat'", "age > 3", "age < 3", or two joined by AND or OR.
func _where(row: Array, cond: String) -> bool:
	if cond.contains(" AND "):
		var p := cond.split(" AND ")
		return _where(row, p[0]) and _where(row, p[1])
	if cond.contains(" OR "):
		var p := cond.split(" OR ")
		return _where(row, p[0]) or _where(row, p[1])
	var w := cond.split(" ")
	if w[0] == "animal":
		return str(row[2]) == w[2].replace("'", "")
	return int(row[3]) > int(w[2]) if w[1] == ">" else int(row[3]) < int(w[2])


func test_db_query_counts_the_records() -> void:
	for ex in _all("db_query"):
		var n := 0
		for row: Array in ex.data.rows:
			if _where(row, str(ex.data.cond)):
				n += 1
		assert_eq(int(_value(ex)), n, str(ex.picture.query))
		assert_true(str(ex.picture.query).ends_with(str(ex.data.cond)), "the picture shows the query")
		var ids := {}
		for row: Array in ex.data.rows:
			assert_false(ids.has(row[0]), "the key is unique")
			ids[row[0]] = true


func test_nearest_guess_takes_the_nearest_vote() -> void:
	for ex in _all("nearest_guess"):
		var pts: Array = ex.data.points
		var nx := float(ex.data.new[0])
		var ny := float(ex.data.new[1])
		var idx: Array = range(pts.size())
		idx.sort_custom(func(a: int, b: int) -> bool:
			var da := Vector2(float(pts[a][0]) - nx, float(pts[a][1]) - ny).length()
			var db := Vector2(float(pts[b][0]) - nx, float(pts[b][1]) - ny).length()
			return da < db or (is_equal_approx(da, db) and a < b))
		var votes := [0, 0]
		for i in int(ex.data.k):
			votes[int(pts[idx[i]][2])] += 1
		var want := 0 if votes[0] > votes[1] else 1
		assert_eq(_right(ex), str(ex.picture.groups[want]), "%s new %s" % [pts, ex.data.new])


func test_accuracy_works_out_the_percentages() -> void:
	for ex in _all("accuracy"):
		var d: Dictionary = ex.data
		var want := 0.0
		if d.has("right"):
			want = float(d.right) * 100.0 / float(d.of)
		elif d.has("few"):
			want = float(d.few) * 100.0 / float(d.total)
		else:
			want = absf(float(d.a) - float(d.b_of_50) * 2.0)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))
		assert_eq(want, roundf(want), "a whole percentage")
		assert_gt(want, 0.0, "never 0")


func test_password_space_counts_the_possibilities() -> void:
	for ex in _all("password_space"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.kind):
			"pin":
				want = pow(10, int(d.n))
			"letters":
				want = pow(26, int(d.n))
			"brake":
				want = 24.0 * 60.0 / float(d.minutes) * float(d.tries)
			"more":
				want = float(d.symbols)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


## Safe or a risk: this test's own words for the risks.
const RISK_WORDS: Array[String] = ["tell anyone", "scary message", "one password", "public wireless", "unknown site",
	"unlocked", "read a code out", "send a password", "found outside"]


func test_trick_sort_finds_the_risks() -> void:
	for ex in _all("trick_sort"):
		for i in (ex.items as Array).size():
			var risky := false
			for w in RISK_WORDS:
				risky = risky or str(ex.items[i]).contains(w)
			assert_eq(int(ex.answer[i]), 1 if risky else 0, str(ex.items[i]))


func test_user_test_numbers() -> void:
	for ex in _all("user_test"):
		var d: Dictionary = ex.data
		var want := 0.0
		if d.has("times"):
			var total := 0.0
			for t: Variant in d.times:
				total += float(t)
			want = total / (d.times as Array).size()
			assert_eq(want, roundf(want), "a whole mean")
		elif d.has("a"):
			want = float(d.b) * 100.0 / float(d.of) - float(d.a) * 100.0 / float(d.of)
		else:
			want = float(d.k) * 100.0 / float(d.of)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


func test_device_energy_in_watt_hours_and_kwh() -> void:
	for ex in _all("device_energy"):
		var d: Dictionary = ex.data
		var wh := float(d.watts) * float(d.hours)
		var want := wh if int(d.level) == 1 else (wh / 1000.0 if int(d.level) == 2 else wh * 365.0 / 1000.0)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


# --- Art -----------------------------------------------------------------------------------------------------------------

## This test's own years for the events in art and the inventions.
const YEARS := {"paint sold in tubes": 1841, "Monet paints Impression, Sunrise": 1872, "the first Impressionist show": 1874,
	"Seurat begins his dot painting": 1884, "van Gogh paints The Starry Night": 1889, "Monet paints his haystacks": 1890,
	"the Fauves shock Paris": 1905, "Picasso begins Cubism": 1907, "the Surrealists' first manifesto": 1924,
	"Tarsila do Amaral paints Abaporu": 1928, "Dali paints melting clocks": 1931, "Pop Art begins in Britain": 1956,
	"Warhol paints rows of soup cans": 1962, "Ibn al-Haytham explains the camera obscura": 1020,
	"the oldest photograph that survives": 1826, "the daguerreotype": 1839, "Muybridge's galloping horse": 1878,
	"the first film show": 1895, "colour photographs on glass": 1907, "films with sound": 1927,
	"the first digital camera": 1975}
## This test's own movements.
const MOVEMENT_OF := {"Claude Monet": "Impressionism", "Berthe Morisot": "Impressionism", "Camille Pissarro": "Impressionism",
	"Henri Matisse": "Fauvism", "Pablo Picasso": "Cubism", "Georges Braque": "Cubism", "Salvador Dali": "Surrealism",
	"René Magritte": "Surrealism", "Andy Warhol": "Pop Art", "Roy Lichtenstein": "Pop Art"}
## The features that help an object work (this test's own list); every other feature only changes its look.
const WORKS: Array[String] = ["springs hold the arm", "joints let it bend", "a heavy base stops it tipping",
	"the shade points the light", "legs that reach the floor", "a seat at the right height", "a backrest for support",
	"legs that let it stack", "a handle that stays cool", "a spout for pouring", "a lid that shuts tight",
	"a switch that turns off when it boils", "padded straps", "a zip that closes", "a waterproof base",
	"pockets for small things", "brakes that stop it", "a chain that turns the wheel", "a bell to warn people",
	"tyres that grip"]
## This test's own music facts.
const MUSIC_YEARS := {"Monteverdi's L'Orfeo": 1607, "Mozart's The Magic Flute": 1791, "Smetana's Vltava": 1874,
	"Tchaikovsky's Swan Lake": 1877, "Tchaikovsky's The Nutcracker": 1892, "Stravinsky's The Rite of Spring": 1913,
	"the theremin": 1920, "the musical Show Boat": 1927, "music from recorded sounds": 1948, "Cage's silent piece": 1952}
const KNOWN := {"Frédéric Chopin": "piano nocturnes", "Pyotr Tchaikovsky": "Swan Lake", "Bedrich Smetana": "the river Vltava",
	"Clara Schumann": "a great pianist", "Claude Debussy": "the whole-tone scale", "Igor Stravinsky": "The Rite of Spring",
	"Arnold Schoenberg": "all 12 notes equal", "John Cage": "a piece of silence", "Louis Armstrong": "jazz trumpet solos",
	"Ella Fitzgerald": "scat singing", "Claudio Monteverdi": "L'Orfeo"}
const STYLE_PLACE := {"tango": "Argentina and Uruguay", "flamenco": "Spain", "fado": "Portugal", "reggae": "Jamaica",
	"samba": "Brazil", "gamelan": "Indonesia", "calypso": "Trinidad and Tobago", "mariachi": "Mexico", "highlife": "Ghana"}
const BAND_OF := {"bass drum": "low", "bass guitar": "low", "tuba": "low", "double bass": "low", "singing voice": "middle",
	"guitar chords": "middle", "piano chords": "middle", "cymbals": "high", "hi-hat": "high", "triangle": "high",
	"whistle": "high"}
## Ranges as the notes sound: the lowest and highest pitch (C4 = 48).
const RANGE := {"flute": [48, 84], "clarinet": [38, 83], "trumpet": [40, 71], "trombone": [28, 65], "tuba": [14, 53],
	"violin": [43, 93], "viola": [36, 76], "cello": [24, 69], "double bass": [16, 55], "soprano": [48, 69],
	"alto": [41, 62], "tenor": [36, 57], "bass": [28, 52]}
const SEMI := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const SPELL := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


func test_the_orders_follow_the_years() -> void:
	for g: String in ["art_order", "tech_order"]:
		for ex in _all(g):
			var ordered: Array = []
			for i: Variant in ex.answer:
				ordered.append(ex.items[int(i)])
			for i in range(1, ordered.size()):
				assert_lt(int(YEARS[ordered[i - 1]]), int(YEARS[ordered[i]]), "%s before %s" % [ordered[i - 1], ordered[i]])
			assert_eq(ordered.size(), int(ex._level) + 2, "%s at level %d" % [g, ex._level])


func test_artist_movement_matches_the_movements() -> void:
	for ex in _all("artist_movement"):
		for i in (ex.items as Array).size():
			assert_eq(str(ex.matches[int(ex.answer[i])]), str(MOVEMENT_OF[str(ex.items[i])]), str(ex.items[i]))


func test_pixel_count_multiplies_and_divides() -> void:
	for ex in _all("pixel_count"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.ask):
			"pixels":
				want = float(d.w) * float(d.h)
			"megapixels":
				want = float(d.w) * float(d.h) / 1000000.0
			"print":
				want = float(d.pixels) / float(d.per)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


## A face (grade 4's proportions): eyes halfway, the nose's bottom three quarters down, the mouth a third of the way on to
## the chin (five sixths), and five eyes across.
func test_face_measure_uses_the_proportions() -> void:
	for ex in _all("face_measure"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.ask):
			"eyes":
				want = float(d.head) / 2.0
			"nose":
				want = float(d.head) * 0.75
			"mouth":
				want = float(d.head) * 0.75 + float(d.head) * 0.25 / 3.0
			"width":
				want = float(d.eye) * 5.0
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))
		assert_eq(want, roundf(want), "a whole number of cm")


func test_grid_scale_enlarges_right() -> void:
	for ex in _all("grid_scale"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.ask):
			"factor":
				want = float(d.big) / float(d.small)
			"width":
				want = float(d.w) * float(d.factor)
			"height":
				want = float(d.h) * float(d.factor)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))
		assert_eq(want, roundf(want), "a whole answer")


func test_paint_tins_rounds_up() -> void:
	for ex in _all("paint_tins"):
		var d: Dictionary = ex.data
		var want := float(d.area) if int(d.coats) == 0 else ceilf(float(d.area) / float(d.cover))
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


func test_form_function_sorts_the_features() -> void:
	for ex in _all("form_function"):
		for i in (ex.items as Array).size():
			assert_eq(int(ex.answer[i]), 0 if WORKS.has(str(ex.items[i])) else 1, str(ex.items[i]))


func test_frame_count_at_24_a_second() -> void:
	for ex in _all("frame_count"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.ask):
			"frames":
				want = 24.0 * float(d.seconds)
			"drawings":
				want = 12.0 * float(d.seconds)
			"seconds":
				want = float(d.frames) / 24.0
			"short":
				want = float(d.minutes) * 60.0 * 12.0
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


## A mobile: weight × distance on each side (this test's own sums).
func test_balance_mobile_turns_right() -> void:
	for ex in _all("balance_mobile"):
		var pic: Dictionary = ex.picture
		var sums := {"left": 0, "right": 0}
		for side: String in ["left", "right"]:
			for wd: Array in pic[side]:
				sums[side] += int(wd[0]) * int(wd[1])
		if str(ex.type) == "number":
			var hidden: Array = pic[str(pic.hide[0])][int(pic.hide[1])]
			assert_eq(int(_value(ex)), int(hidden[0]), "the hidden weight is the one drawn")
			assert_eq(int(sums.left), int(sums.right), "it balances: %s" % [pic])
			assert_lte(int(hidden[0]), 10, "a weight the picture can draw")
		else:
			var want := "left side down" if sums.left > sums.right else ("right side down" if sums.right > sums.left
				else "it balances")
			assert_eq(_right(ex), want, str(pic))
		assert_eq(SchoolPicture.problem(pic), "", "the mobile can be drawn")


func test_maquette_scales_right() -> void:
	for ex in _all("maquette"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.ask):
			"real":
				want = float(d.model) * float(d.scale)
			"model":
				want = float(d.real) / float(d.scale)
			"scale":
				want = float(d.scale)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


func test_hang_height_from_the_middle() -> void:
	for ex in _all("hang_height"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.ask):
			"top":
				want = 150.0 + float(d.h) / 2.0
			"bottom":
				want = 150.0 - float(d.h) / 2.0
			"hook":
				want = 150.0 + float(d.h) / 2.0 - float(d.drop)
			"gap":
				var used := 0.0
				for w: Variant in d.widths:
					used += float(w)
				want = (float(d.wall) - used) / float((d.widths as Array).size() + 1)
		assert_almost_eq(_value(ex), want, 0.0001, str(ex.prompt))


# --- Music -------------------------------------------------------------------------------------------------------------

## A note's pitch in semitones ("C4" = 48; "F#4", "Bb3"), from this test's own table.
func _pitch(note: String) -> int:
	var n := note.split(":")[0]
	var s := int(SEMI[n.left(1)])
	if n.contains("#"):
		s += 1
	elif n.length() > 2 and n[1] == "b":
		s -= 1
	return 12 * int(n.right(1)) + s


## "F sharp" or "B flat" as a pitch class 0-11.
func _named(name: String) -> int:
	var s := int(SEMI[name.left(1)])
	if name.contains("sharp") or name.contains("#"):
		s += 1
	elif name.contains("flat") or (name.length() > 1 and name[1] == "b"):
		s -= 1
	return posmod(s, 12)


func test_composer_match_and_music_order() -> void:
	for ex in _all("composer_match"):
		for i in (ex.items as Array).size():
			assert_eq(str(ex.matches[int(ex.answer[i])]), str(KNOWN[str(ex.items[i])]), str(ex.items[i]))
	for ex in _all("music_order"):
		var prev := -1
		for i: Variant in ex.answer:
			var y := int(MUSIC_YEARS[ex.items[int(i)]])
			assert_gt(y, prev, "in time order: %s" % ex.items[int(i)])
			prev = y


func test_whole_tone_scales() -> void:
	for ex in _all("whole_tone"):
		var start := int(ex.data.start)
		var classes: Array[int] = []
		for k in 6:
			classes.append(posmod(start + 2 * k, 12))
		match str(ex.data.ask):
			"notes":
				var got: Array[int] = []
				for n in _right(ex).split(", "):
					got.append(_named(n))
				assert_eq(got, classes, str(ex.prompt))
			"next":
				var after := _named(str(ex.data.after))
				assert_eq(_named(_right(ex)), posmod(after + 2, 12), str(ex.prompt))
				assert_true(classes.has(after), "the note asked about is in the scale")
			"not":
				assert_false(classes.has(_named(_right(ex))), str(ex.prompt))
				for i in (ex.choices as Array).size():
					if i != int(ex.answer):
						assert_true(classes.has(_named(str(ex.choices[i]))), "%s is in the scale" % ex.choices[i])


func test_loop_lcm() -> void:
	for ex in _all("loop_lcm"):
		var n := 1
		while true:
			var all_in := true
			for v: Variant in ex.data.loops:
				all_in = all_in and n % int(v) == 0
			if all_in:
				break
			n += 1
		assert_eq(int(_value(ex)), n, str(ex.prompt))


func test_swing_hear() -> void:
	for ex in _all("swing_hear"):
		var notes: Array = ex.sound.notes
		var long_short := str(notes[0]).ends_with(":2") and not str(notes[1]).contains(":")
		assert_eq(_right(ex).begins_with("swung"), long_short, str(notes))
		assert_eq(SchoolSound.problem(ex.sound), "", "the sound plays")


## The blues scale: the root, a minor third, a fourth, a sharpened fourth, a fifth and a minor seventh.
func test_blues_scale() -> void:
	for ex in _all("blues_scale"):
		var root := _named(str(ex.data.key))
		var classes: Array[int] = []
		for st: int in [0, 3, 5, 6, 7, 10]:
			classes.append(posmod(root + st, 12))
		var not_in := str(ex.prompt).contains(" not ")
		assert_eq(classes.has(_named(_right(ex))), not not_in, str(ex.prompt))
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_eq(classes.has(_named(str(ex.choices[i]))), not_in, "%s: %s" % [ex.prompt, ex.choices[i]])


func test_chorus_count_and_loop_time() -> void:
	for ex in _all("chorus_count"):
		var c := float(ex.data.choruses)
		var want := 12.0 * c if ex.data.ask == "bars" else (3.0 * c if ex.data.ask == "fours" else 48.0 * c * 60.0 / float(ex.data.bpm))
		assert_almost_eq(_value(ex), want, 0.001, str(ex.prompt))
	for ex in _all("loop_time"):
		var d: Dictionary = ex.data
		var want := 0.0
		match str(d.ask):
			"beats":
				want = float(d.bars) * float(d.per)
			"seconds":
				want = float(d.bars) * float(d.per) * 60.0 / float(d.bpm)
			"echo":
				want = 60000.0 / float(d.bpm)
			"loops":
				want = float(d.bpm) / float(d.beats)
		assert_almost_eq(_value(ex), want, 0.001, str(ex.prompt))


func test_eq_band() -> void:
	for ex in _all("eq_band"):
		if str(ex.data.ask) == "fix":
			assert_eq(_right(ex), "the low band" if bool(ex.data.muddy) else "the high band", str(ex.prompt))
		else:
			assert_eq(_right(ex), "the %s band" % str(BAND_OF[str(ex.data.sound)]), str(ex.prompt))


func test_transpose() -> void:
	for ex in _all("transpose"):
		var mel: Array = ex.data.melody
		var got := _right(ex).replace(" and ", ", ").split(", ")
		assert_eq(got.size(), mel.size(), str(ex.prompt))
		for i in mel.size():
			var a := _pitch(str(mel[i]))
			var b := _pitch(got[i])
			match int(ex.data.level):
				1:
					assert_eq(absi(b - a), 12, "%s: an octave" % ex.prompt)
					assert_eq(got[i].left(1), str(mel[i]).left(1), "the same letter")
				2:
					assert_eq(posmod("CDEFGAB".find(got[i].left(1)) - "CDEFGAB".find(str(mel[i]).left(1)), 7), 1, "the next letter")
					assert_true(b - a == 1 or b - a == 2, "a step of C major")
				3:
					assert_eq(b - a, 2, "%s: a whole tone" % ex.prompt)


func test_range_fit() -> void:
	for ex in _all("range_fit"):
		var p := _pitch(str(ex.data.note))
		for i in (ex.choices as Array).size():
			var name := str(ex.choices[i]).trim_prefix("the ")
			var can: bool = p >= int(RANGE[name][0]) and p <= int(RANGE[name][1])
			var right := i == int(ex.answer)
			assert_eq(can, right if ex.data.ask == "can" else not right, "%s: %s" % [ex.prompt, name])


func test_texture_hear() -> void:
	for ex in _all("texture_hear"):
		var parts: Array = ex.sound.get("parts", [])
		var kind := "mono"
		if not parts.is_empty():
			kind = "homo" if str(parts[0].notes[0]).contains("+") else "poly"
		assert_true(_right(ex).begins_with({"mono": "monophonic", "homo": "homophonic", "poly": "polyphonic"}[kind]),
			"%s: %s" % [kind, _right(ex)])
		assert_eq(SchoolSound.problem(ex.sound), "", "the sound plays")


func test_culture_match() -> void:
	for ex in _all("culture_match"):
		if str(ex.type) == "choice":
			var style := str(ex.prompt).trim_prefix("Where did ").trim_suffix(" grow?")
			assert_eq(_right(ex), str(STYLE_PLACE[style]), str(ex.prompt))
		else:
			for i in (ex.items as Array).size():
				assert_eq(str(ex.matches[int(ex.answer[i])]), str(STYLE_PLACE[str(ex.items[i])]), str(ex.items[i]))


func test_form_plan() -> void:
	for ex in _all("form_plan"):
		var mins: Array = ex.data.minutes
		var total := 0
		for m: Variant in mins:
			total += int(m)
		if str(ex.data.ask) == "total":
			assert_eq(int(_value(ex)), total, str(ex.prompt))
		else:
			assert_eq(int(_value(ex)), int(mins[int(ex.data.hide)]), str(ex.prompt))
			assert_true(str(ex.prompt).contains("lasts %d minutes" % total), "the whole is stated")


func test_note_read() -> void:
	for ex in _all("note_read"):
		if ex.data.has("mark"):
			assert_eq(_right(ex), str(ex.data.notes[int(ex.data.mark)]).left(1), str(ex.data.notes))
		else:
			var note := str(ex.data.notes[int(ex.data.ask)])
			var want := "F sharp" if str(ex.data.key) == "G" else "B flat"
			assert_eq(note.left(1), want.left(1), "the note asked about is the one the key changes")
			assert_eq(_right(ex), want, str(ex.prompt))


const BEAT_OF := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "crotchet": 1.0, "quaver": 0.5}


func test_bar_check() -> void:
	for ex in _all("bar_check"):
		if ex.data.has("values"):
			var total := 0.0
			for v: Variant in ex.data.values:
				total += float(BEAT_OF[v])
			assert_almost_eq(_value(ex), total, 0.001, str(ex.data.values))
		else:
			var have := 0.0
			for v: Variant in ex.data.have:
				have += float(BEAT_OF[v])
			assert_almost_eq(float(BEAT_OF[_right(ex).trim_prefix("a ")]), float(ex.data.per) - have, 0.001, str(ex.prompt))


## A motif's changes, by this test's own rules on the C major scale's letters.
func test_motif_move() -> void:
	for ex in _all("motif_move"):
		var m: Array = ex.data.motif
		var idx := func(n: String) -> int: return "CDEFGAB".find(n.left(1)) + 7 * int(n.split(":")[0].right(1))
		var name := func(i: int) -> String: return "%s%d" % ["CDEFGAB"[posmod(i, 7)], floori(i / 7.0)]
		var want: Array = []
		match str(ex.data.how):
			"sequence":
				for n: Variant in m:
					want.append(name.call(int(idx.call(str(n))) + 1))
			"sequence down":
				for n: Variant in m:
					want.append(name.call(int(idx.call(str(n))) - 1))
			"inversion":
				var base: int = idx.call(str(m[0]))
				for n: Variant in m:
					want.append(name.call(2 * base - int(idx.call(str(n)))))
			"retrograde":
				want = m.duplicate()
				want.reverse()
			"augmentation":
				for n: Variant in m:
					want.append(str(n) + ":2")
		assert_eq(ex.data.right, want, "%s %s" % [ex.data.how, m])
		var heard: Array = ex.sound.notes
		assert_eq(heard.slice(0, 3), m, "the motif is heard first")
		assert_eq(heard.slice(4), want, "then its change")
		assert_true(_right(ex).contains({"sequence": "higher", "sequence down": "lower", "inversion": "upside down",
			"retrograde": "backwards", "augmentation": "longer"}[str(ex.data.how)]), _right(ex))


const CHORDS := {"C": {"I": ["C", "E", "G"], "IV": ["F", "A", "C"], "V": ["G", "B", "D"]},
	"G": {"I": ["G", "B", "D"], "IV": ["C", "E", "G"], "V": ["D", "F sharp", "A"]},
	"F": {"I": ["F", "A", "C"], "IV": ["B flat", "D", "F"], "V": ["C", "E", "G"]}}


func test_chord_fit() -> void:
	for ex in _all("chord_fit"):
		var chords: Dictionary = CHORDS[str(ex.data.key)]
		var holders: Array = []
		for c: String in chords:
			var all_in := true
			for n: Variant in ex.data.notes:
				all_in = all_in and (chords[c] as Array).has(n)
			if all_in:
				holders.append(c)
		assert_eq(holders.size(), 1, "one chord fits: %s" % [ex.data.notes])
		assert_true(_right(ex).begins_with(str(holders[0]) + ":"), "%s: %s" % [ex.prompt, _right(ex)])
