extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.8, §4.6): Inside a Leaf's catalogue (`data/play/leaf/`). Every
## voyage plays for a unit the School has written; every line Hoot says is short (at most 12 words) and spoken, so a
## question never needs reading: the world answers it, or pictures do; every voyage has its hook and its see-why lines;
## the board opens the desert after the sunflower; the ladder is grades 4-8.

const MAX_WORDS := 12


func test_every_voyage_names_a_written_unit() -> void:
	var ids := LeafVoyages.ids()
	assert_eq(ids, ["5.1", "5.T1"] as Array[String], "phase B's two voyages, in the board's order")
	for id in ids:
		var unit := LeafVoyages.unit(id)
		assert_true(Curriculum.has_content(unit), "%s plays for %s, a written unit" % [id, unit])
		assert_false(Curriculum.unit(unit).is_empty(), "%s: %s is in the outline" % [id, unit])
	assert_eq(LeafVoyages.unit("9.9"), "", "an unknown voyage has no unit")


func test_every_line_is_at_most_twelve_words() -> void:
	var lines := LeafVoyages.lines()
	assert_gte(lines.size(), 49, "the design's 49 lines: L1-L27, D1-D10, P1-P7, G1-G5")
	for l: Dictionary in lines:
		var n := PlayReadless.words(str(l.text))
		assert_between(n, 1, MAX_WORDS, "%s has %d words: %s" % [l.id, n, l.text])


func test_a_question_is_answered_by_the_world_or_by_pictures() -> void:
	var questions := 0
	for l: Dictionary in LeafVoyages.lines():
		if not str(l.text).contains("?"):
			continue
		questions += 1
		var answer: Variant = l.get("answer")
		if answer is String:
			assert_eq(answer, LeafVoyages.WORLD, "%s: a question with no picture is answered by what happens" % l.id)
		else:
			assert_true(answer is Array and not (answer as Array).is_empty(), "%s names its answer" % l.id)
			for p: Variant in answer:
				assert_true(LeafVoyages.PICTURES.has(str(p)), "%s: %s is a picture a HUD draws" % [l.id, p])
	assert_gte(questions, 5, "Another voyage? Need a rest? Leave the voyage? Feel that cool air? When does it cool down?")


func test_every_voyage_has_a_hook_and_see_why_lines_that_exist() -> void:
	for id in LeafVoyages.ids():
		var v := LeafVoyages.voyage(id)
		var hook := str(v.lines.get("hook", ""))
		assert_ne(LeafVoyages.line(hook), "", "%s's hook (%s) is a line" % [id, hook])
		var why: Array = v.lines.get("see_why", [])
		assert_false(why.is_empty(), "%s has see-why lines" % id)
		for w: Variant in why:
			assert_ne(LeafVoyages.line(str(w)), "", "%s's see-why %s is a line" % [id, w])
		for cue: String in v.lines:
			for l: Variant in (v.lines[cue] if v.lines[cue] is Array else [v.lines[cue]]):
				assert_ne(LeafVoyages.line(str(l)), "", "%s's cue %s names line %s" % [id, cue, l])
	assert_eq(LeafVoyages.line("L1"), "Oh no! Our sunflower is drooping in the heat.")
	assert_eq(LeafVoyages.line("nope"), "", "an unknown line says nothing")


func test_the_board_opens_the_desert_after_the_sunflower() -> void:
	assert_true(LeafVoyages.unlocked("5.1", []), "everyone's first voyage")
	assert_false(LeafVoyages.unlocked("5.T1", []), "the desert waits for the sunflower")
	assert_true(LeafVoyages.unlocked("5.T1", ["5.1"]))
	assert_false(LeafVoyages.unlocked("9.9", ["5.1"]), "no such voyage")


func test_the_desert_is_a_transfer_voyage_for_the_same_idea() -> void:
	assert_false(LeafVoyages.is_transfer("5.1"))
	assert_true(LeafVoyages.is_transfer("5.T1"))
	assert_eq(LeafVoyages.unit("5.T1"), LeafVoyages.unit("5.1"), "the same unit's idea, somewhere new")
	assert_ne(str(LeafVoyages.voyage("5.T1").get("setting", "")), "", "a transfer names where it is (the record's note)")


func test_the_ladder_is_five_rungs_from_grade_4_to_8() -> void:
	var rungs := LeafVoyages.rungs()
	assert_eq(rungs.map(func(r: Dictionary) -> int: return int(r.rung)), [4, 5, 6, 7, 8])
	for r: Dictionary in rungs:
		assert_eq(int(r.grade), int(r.rung), "rung %d is grade %d's" % [r.rung, r.grade])
		assert_ne(str(r.get("name", "")), "")
	for id in LeafVoyages.ids():
		assert_eq(int(LeafVoyages.voyage(id).rung), 5, "%s is on rung 5 (Built from Air)" % id)


func test_every_voyage_judges_at_least_a_round_of_beats_on_its_own_segments() -> void:
	for id in LeafVoyages.ids():
		var v := LeafVoyages.voyage(id)
		var segments := {}
		for s: Dictionary in v.script:
			assert_true(LeafVoyages.weather_kinds().has(str(s.kind)), "%s: %s is a kind of weather" % [id, s.kind])
			assert_gt(float(s.seconds), 0.0)
			segments[str(s.id)] = true
		var judged := 0
		for b: Dictionary in v.beats:
			judged += 1
			if b.has("segment"):
				assert_true(segments.has(str(b.segment)), "%s's beat %s judges segment %s" % [id, b.id, b.segment])
		assert_gte(judged, MasteryRules.ROUND_SIZE, "%s gives a full round of events" % id)
