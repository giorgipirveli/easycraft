extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5, §3.5b, §3.6, §3.8, §3.10, §4.3, §4.6): Balance Altar's
## catalogue (`data/play/altar/`). Every room plays for a unit the School has written; the Entrance Hall is three
## taught altars and eight judged (the model's), the Great Altar last; the Sky Room is six judged balloon altars, a
## transfer; every line Hoot says is short (at most 12 words) and spoken, so a question never needs reading (the world
## or pictures answer it); every room has its hook and see-why lines; the ladder is wings 5-8.

const MAX_WORDS := 12
## The phase A models' judged altars (hall_model.py's HALL, sky_room_model.py's SKY).
const MODEL_HALL := ["add_L", "add_R", "mul_L", "add_L", "mul_R", "add_R", "mul_L", "two_L"]
const MODEL_SKY := ["sub_L", "sub_L", "add_L", "sub_R", "mul_L", "subtwo_L"]


func test_every_room_names_a_written_unit() -> void:
	assert_eq(AltarHalls.ids(), ["entrance", "sky"] as Array[String], "phase B's two rooms, in the board's order")
	for id in AltarHalls.ids():
		var unit := AltarHalls.unit(id)
		assert_eq(unit, "g6.maths.equations", "%s: one main unit a room (ruling 13)" % id)
		assert_true(Curriculum.has_content(unit), "%s plays for %s, a written unit" % [id, unit])
	assert_eq(AltarHalls.unit("nope"), "")


func test_the_entrance_hall_teaches_three_altars_and_judges_the_model_s_eight() -> void:
	var altars := AltarHalls.altars("entrance")
	assert_eq(altars.size(), 11)
	var taught := altars.filter(func(a: Dictionary) -> bool: return bool(a.get("taught", false)))
	assert_eq(taught.map(func(a: Dictionary) -> int: return int(a.n)), [1, 2, 5], "the ghost's twin, the trap, the bowls")
	var judged := altars.filter(func(a: Dictionary) -> bool: return not bool(a.get("taught", false)))
	assert_eq(judged.map(func(a: Dictionary) -> String: return str(a.form)), MODEL_HALL)
	assert_true(bool(altars[10].get("great", false)), "the Great Altar is the last")
	assert_eq(AltarHalls.tools("entrance"), ["bowls", "gem_bag"] as Array[String])
	assert_eq(str(altars[0].get("demo", "")), "twin_take")
	assert_eq(str(altars[4].get("demo", "")), "bowls")
	assert_eq(str(altars[1].get("demo", "")), "", "the trap has no ghost")
	for a: Dictionary in taught:
		var s := AltarHalls.altar_state(a, RandomNumberGenerator.new())
		assert_true(s.holds(), "taught altar %d holds" % a.n)
	var five := AltarHalls.altar_state(altars[4], RandomNumberGenerator.new())
	assert_true(five.same(AltarState.make(2, 0, 0, 6, 3)), "H13 says two crystals weighed six, one weighs three")


func test_the_sky_room_is_six_judged_balloon_altars_a_transfer_after_the_hall() -> void:
	var altars := AltarHalls.altars("sky")
	assert_eq(altars.map(func(a: Dictionary) -> String: return str(a.form)), MODEL_SKY)
	for a: Dictionary in altars:
		assert_false(bool(a.get("taught", false)), "a transfer room shows nothing first")
	assert_true(bool(altars[5].get("great", false)))
	assert_true(AltarHalls.is_transfer("sky"))
	assert_false(AltarHalls.is_transfer("entrance"))
	assert_ne(AltarHalls.setting("sky"), "", "a transfer names where it is (the record's note)")
	assert_true(AltarHalls.tools("sky").has("pump"), "the balloon pump")
	assert_true(AltarHalls.unlocked("entrance", []))
	assert_false(AltarHalls.unlocked("sky", []), "the great door opens after the hall")
	assert_true(AltarHalls.unlocked("sky", ["entrance"]))


func test_each_altar_s_kind_when_freed_first_time() -> void:
	var hall := AltarHalls.altars("entrance")
	assert_eq(AltarHalls.solved_kind("entrance", hall[2]), SkillShown.SOLVED)
	assert_eq(AltarHalls.solved_kind("entrance", hall[10]), SkillShown.NEW_SETTING,
		"the lead's ruling 6: the Great Altar's two moves count as transfer evidence")
	assert_eq(AltarHalls.solved_kind("sky", AltarHalls.altars("sky")[0]), SkillShown.NEW_SETTING)


func test_every_altar_has_its_glimmer_and_every_glimmer_is_one_we_draw() -> void:
	for id in AltarHalls.ids():
		for a: Dictionary in AltarHalls.altars(id):
			assert_true(AltarHalls.GLIMMERS.has(str(a.get("glimmer", ""))), "%s altar %d: %s" % [id, a.n, a.get("glimmer")])
	assert_eq(str(AltarHalls.altars("entrance")[0].glimmer), "fox", "the first light is a fox (§3.5 step 2)")


func test_every_line_is_at_most_twelve_words() -> void:
	var lines := AltarHalls.lines()
	assert_gte(lines.size(), 43, "H1-H22, R1-R4, S1-S6, P1-P6, G1-G5")
	for l: Dictionary in lines:
		var n := PlayReadless.words(str(l.text))
		assert_between(n, 1, MAX_WORDS, "%s has %d words: %s" % [l.id, n, l.text])
	for id: String in ["H1", "H22", "R1", "R4", "S1", "S6", "P1", "P6", "G1", "G5"]:
		assert_ne(AltarHalls.line(id), "", id)
	assert_eq(AltarHalls.line("H1"), "Welcome to the Sky Temple! Its crystals are frozen.")


func test_a_question_is_answered_by_the_world_or_by_pictures() -> void:
	var questions := 0
	for l: Dictionary in AltarHalls.lines():
		if not str(l.text).contains("?"):
			continue
		questions += 1
		var answer: Variant = l.get("answer")
		if answer is String:
			assert_eq(answer, AltarHalls.WORLD, "%s: a question with no picture is answered by what happens" % l.id)
		else:
			assert_true(answer is Array and not (answer as Array).is_empty(), "%s names its answer" % l.id)
			for p: Variant in answer:
				assert_true(AltarHalls.PICTURES.has(str(p)), "%s: %s is a picture a HUD draws" % [l.id, p])
	assert_gte(questions, 3, "Another hall? Need a rest? Leave the temple?")


func test_every_room_has_its_hook_and_see_why_lines_and_every_cue_names_a_line() -> void:
	for id in AltarHalls.ids():
		var cues := AltarHalls.cues(id)
		assert_ne(AltarHalls.line(str(cues.get("hook", ""))), "", "%s's hook" % id)
		var why: Array = cues.get("see_why", [])
		assert_false(why.is_empty(), "%s has see-why lines" % id)
		for cue: String in cues:
			for l: Variant in (cues[cue] if cues[cue] is Array else [cues[cue]]):
				assert_ne(AltarHalls.line(str(l)), "", "%s's cue %s names line %s" % [id, cue, l])
	assert_eq(AltarHalls.line("nope"), "", "an unknown line says nothing")


func test_a_line_s_number_is_said_as_a_word() -> void:
	assert_eq(AltarHalls.say("H6", {"n": 4}), "Free! It weighs four gems!")
	assert_eq(AltarHalls.say("H6", {"n": 1}), "Free! It weighs one gem!")
	assert_eq(AltarHalls.say("H6", {"n": 12}), "Free! It weighs twelve gems!")
	assert_eq(AltarHalls.say("H5"), "Fair and square! The altar stays level.")


func test_the_rooms_music_is_in_the_repo() -> void:
	for id in AltarHalls.ids():
		var music: Dictionary = AltarHalls.room(id).get("music", {})
		assert_false(music.is_empty(), id)
		for what: String in music:
			var path := "res://assets/music/classical/%s.ogg" % music[what]
			assert_true(ResourceLoader.exists(path), "%s's %s: %s" % [id, what, path])


func test_the_ladder_is_four_wings_from_grade_5_to_8() -> void:
	var wings := AltarHalls.wings()
	assert_eq(wings.map(func(w: Dictionary) -> int: return int(w.wing)), [5, 6, 7, 8])
	for w: Dictionary in wings:
		assert_eq(int(w.grade), int(w.wing))
		assert_ne(str(w.get("name", "")), "")
		assert_false((w.get("units", []) as Array).is_empty(), "wing %d names its units" % w.wing)
		for u: Variant in w.units:
			assert_false(Curriculum.unit(str(u)).is_empty(), "wing %d: %s is in the outline" % [w.wing, u])
	assert_has(wings[1].rooms, "entrance", "the Entrance Hall is wing 6's first room")
	assert_has(wings[1].rooms, "sky")
	assert_eq(AltarHalls.start_stage(6), AltarRunes.PICTURES, "grade 6 starts with pictures (§3.6)")
	assert_eq(AltarHalls.start_stage(7), AltarRunes.LETTERS)
	assert_eq(AltarHalls.start_stage(8), AltarRunes.RUNES)
