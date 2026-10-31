extends GutTest
## Owner #68, the grade 4 agent: grade 4 physical science's generators (G4PhysicalGen, "g4p": energy and speed, energy
## on the move, waves, light and seeing, messages with patterns), checked against what they show, with the arithmetic
## and the codes done here (the real international Morse code).

const SEEDS := 60
## International Morse code (ITU): the letters the generators use.
const MORSE := {"A": ".-", "D": "-..", "E": ".", "H": "....", "I": "..", "M": "--", "N": "-.", "O": "---", "R": ".-.",
	"S": "...", "T": "-"}


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if not ex.is_empty():
				check.call(ex, level)


func _shown_order(ex: Dictionary) -> Array:
	var out: Array = []
	for i: Variant in ex.answer:
		out.append(str(ex.items[int(i)]))
	return out


# --- Energy and speed ---------------------------------------------------------------------------------------------

func test_the_faster_of_identical_things_has_more_energy() -> void:
	_each("g4p.faster_energy", func(ex: Dictionary, _l: int) -> void:
		var speeds: Dictionary = ex.data.speeds   # owner -> [metres, seconds]
		var best := ""
		var top := -1.0
		var tie := false
		for who: String in speeds:
			var v := float(speeds[who][0]) / float(speeds[who][1])
			if is_equal_approx(v, top):
				tie = true
			elif v > top:
				top = v
				best = who
				tie = false
		var right := ExerciseCheck.answer_text(ex)
		if tie:
			assert_true(right.begins_with("They "), "equal speeds, equal energy: %s" % ex.prompt)
		else:
			assert_true(right.begins_with(best + "'s"), "%s: the fastest is %s's" % [ex.prompt, best])
		for who: String in speeds:
			assert_true(str(ex.prompt).contains(who) or str(ex.get("picture", "")).contains(who), "%s is shown" % who))


func test_energy_goes_up_with_speed_in_the_order() -> void:
	_each("g4p.energy_order", func(ex: Dictionary, _l: int) -> void:
		var metres: Array = []
		for item in _shown_order(ex):
			metres.append(int(item.get_slice(" ", 1)))
		var sorted := metres.duplicate()
		sorted.sort()
		assert_eq(metres, sorted, "least energy first: %s" % [_shown_order(ex)]))


# --- Energy on the move -------------------------------------------------------------------------------------------

func test_energy_travels_by_the_way_its_situation_says() -> void:
	var seen := {}
	_each("g4p.energy_travels", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ex.choices.size(), 4)
		for row: Array in G4PhysicalGen.TRAVELS:
			if str(ex.prompt).contains(str(row[0])):
				assert_eq(ExerciseCheck.answer_text(ex), "by " + str(row[1]), str(ex.prompt))
				seen[row[0]] = true)
	assert_gte(seen.size(), 10, "many situations are used")


func test_every_device_changes_the_energy_it_was_built_for() -> void:
	_each("g4p.energy_changes", func(ex: Dictionary, level: int) -> void:
		var found := false
		for row: Array in G4PhysicalGen.DEVICES:
			if str(ex.prompt).contains(str(row[0]) + " "):
				found = true
				assert_eq(ExerciseCheck.answer_text(ex), str(row[2]), str(ex.prompt))
				assert_eq(str(ex.prompt).contains("makes electricity"), str(row[1]) == "into electricity")
		assert_true(found, str(ex.prompt)))


# --- Waves --------------------------------------------------------------------------------------------------------

func test_the_compared_wave_is_the_right_one() -> void:
	_each("g4p.wave_compare", func(ex: Dictionary, _l: int) -> void:
		var waves: Array = ex.picture.waves
		var asked := str(ex.data.asked)   # "bigger amplitude", "smaller amplitude", "longer wavelength", …
		var by_amp := asked.ends_with("amplitude") or asked == "most energy"
		var want_big := asked.begins_with("bigger") or asked.begins_with("longer") or asked == "most energy"
		var values: Array = []
		for w: Dictionary in waves:
			# a longer wavelength is fewer waves across the same width
			values.append(int(w.amp) if by_amp else -int(w.count))
		var best: int = values.max() if want_big else values.min()
		var right := ExerciseCheck.answer_text(ex)
		if values.count(best) > 1:
			assert_eq(right, "They are the same", str(ex.prompt))
		else:
			assert_eq(right, "wave " + ["A", "B", "C"][values.find(best)], str(ex.prompt))
		if asked == "most energy":
			for w: Dictionary in waves:
				assert_eq(int(w.count), int(waves[0].count), "energy is asked only when the wavelengths match"))


func test_the_wavelengths_are_counted() -> void:
	_each("g4p.wave_count", func(ex: Dictionary, _l: int) -> void:
		var count := int(ex.picture.waves[0].count)
		if ex.data.has("length"):
			assert_eq(int(str(ex.answer)) * count, int(ex.data.length), str(ex.prompt))
		else:
			assert_eq(int(str(ex.answer)), count, str(ex.prompt)))


func test_the_waves_are_put_in_order() -> void:
	_each("g4p.wave_order", func(ex: Dictionary, _l: int) -> void:
		var waves: Array = ex.picture.waves
		var by_amp := str(ex.prompt).contains("amplitude")
		var last := -INF
		for item in _shown_order(ex):
			var w: Dictionary = waves[["wave A", "wave B", "wave C"].find(item)]
			var v := float(w.amp) if by_amp else -float(w.count)   # the shortest wavelength (most waves) first
			assert_gt(v, last, "%s in order" % item)
			last = v)


# --- Light and seeing ---------------------------------------------------------------------------------------------

func test_light_goes_from_its_source_to_the_thing_and_into_the_eyes() -> void:
	_each("g4p.light_path", func(ex: Dictionary, level: int) -> void:
		var path := _shown_order(ex)
		assert_true(G4PhysicalGen.SOURCES.any(func(s: Array) -> bool: return str(s[0]) == path[0]), "starts at a source")
		assert_true(path.back().ends_with("eyes"), "ends in the eyes")
		assert_eq(path.has("the mirror"), level == 3)
		if level == 3:
			assert_eq(path[path.size() - 2], "the mirror", "the mirror just before the eyes"))


func test_a_light_source_makes_its_own_light() -> void:
	_each("g4p.light_source", func(ex: Dictionary, level: int) -> void:
		var sources: Array = G4PhysicalGen.MAKES_LIGHT
		var not_sources: Array = G4PhysicalGen.NO_LIGHT
		if str(ex.type) == "truefalse":
			var thing := str(ex.data.thing)
			assert_eq(ex.answer, sources.has(thing), thing)
			assert_true(sources.has(thing) or not_sources.has(thing))
		else:
			var right := ExerciseCheck.answer_text(ex)
			var is_not := str(ex.prompt).contains("NOT")
			assert_eq(not_sources.has(right) if is_not else sources.has(right), true, str(ex.prompt))
			for c: Variant in ex.choices:
				if str(c) != right:
					assert_eq(sources.has(str(c)) if is_not else not_sources.has(str(c)), true, "%s is the other kind" % c))


# --- Sending messages with patterns -------------------------------------------------------------------------------

func test_the_dark_squares_are_counted() -> void:
	_each("g4p.pixel_count", func(ex: Dictionary, _l: int) -> void:
		var want := "1" if str(ex.prompt).contains("dark") else "0"
		var n := 0
		for row: String in ex.picture.rows:
			n += row.count(want)
		assert_eq(int(str(ex.answer)), n, str(ex.prompt)))


func test_a_row_is_sent_as_its_own_numbers() -> void:
	_each("g4p.pixel_row", func(ex: Dictionary, _l: int) -> void:
		var right: Variant = ex.choices[int(ex.answer)]
		if right is Dictionary:
			var sent := str(ex.data.rows)
			assert_eq(" / ".join(right.picture.rows), sent, "the picture the numbers make")
		else:
			assert_eq(str(right).replace(" ", ""), str(ex.picture.rows[int(ex.data.row)]), str(ex.prompt)))


func test_a_picture_takes_one_number_per_square() -> void:
	_each("g4p.pixel_size", func(ex: Dictionary, _l: int) -> void:
		var n := int(ex.data.w) * int(ex.data.h)
		assert_eq(int(str(ex.answer)), n / int(ex.data.get("per_second", 1)), str(ex.prompt)))


func test_the_drum_code_is_read_beat_by_beat() -> void:
	_each("g4p.beat_code", func(ex: Dictionary, _l: int) -> void:
		var word := str(ex.data.word)
		var beats: Array = []
		var total := 0
		for ch in word:
			beats.append(ch.unicode_at(0) - "A".unicode_at(0) + 1)
			total += beats.back()
		if str(ex.type) == "number":
			assert_eq(int(str(ex.answer)), total, word)
		else:
			assert_eq(ExerciseCheck.answer_text(ex), word)
			assert_true(str(ex.prompt).contains(", ".join(beats.map(func(b: int) -> String: return str(b)))), str(ex.prompt)))


func test_morse_is_the_real_morse_code() -> void:
	for letter: String in G4PhysicalGen.MORSE:
		var shown := str(G4PhysicalGen.MORSE[letter]).replace("•", ".").replace("—", "-").replace(" ", "")
		assert_eq(shown, MORSE.get(letter, "?"), letter)
	_each("g4p.morse_word", func(ex: Dictionary, _l: int) -> void:
		var word := str(ex.data.word)
		var code: Array = []
		for ch in word:
			code.append(str(G4PhysicalGen.MORSE[ch]))
		var sent := " / ".join(code)
		if str(ex.prompt).contains(sent):
			assert_eq(ExerciseCheck.answer_text(ex), word, str(ex.prompt))
		else:
			assert_eq(ExerciseCheck.answer_text(ex), sent, str(ex.prompt))
		assert_eq(ex.picture.kind, "table", "the code's table is shown"))
