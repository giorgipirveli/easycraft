extends GutTest
## Owner #122 (docs/design/learning-is-play.md §5.1): every exercise type the School has is played through one of the
## generic mechanics (`data/play/mechanics.json`), so no written unit is slides and a quiz: Make it, Sort it, Order it,
## Connect it, Fix it, Build it, Code it, Beat it, Mix it, Find it, Choose by doing and Test it. A unit's play level is
## P0 (the generic mechanics) until it names a signature game of its own (P1: Inside a Leaf, the first, owner #134).


func test_every_exercise_type_has_a_mechanic() -> void:
	for t: String in ExerciseCheck.TYPES:
		assert_ne(PlayMechanics.of(t), "", "%s has a mechanic" % t)


func test_the_mechanics_by_type_are_the_designs() -> void:
	var want := {"number": "make", "sort": "sort", "order": "order", "match": "connect", "label": "fix", "build": "build",
		"robot": "code", "rhythm": "beat", "mix": "mix", "point": "find", "choice": "choose", "truefalse": "test"}
	for t: String in want:
		assert_eq(PlayMechanics.of(t), want[t], t)
	assert_eq(PlayMechanics.of("essay"), "", "an unknown type has none")


func test_each_mechanic_has_its_name_hook_and_go_words() -> void:
	assert_eq(PlayMechanics.ids().size(), 12)
	assert_eq(PlayMechanics.name_of("make"), "Make it")
	assert_eq(PlayMechanics.name_of("choose"), "Choose by doing")
	for id: String in PlayMechanics.ids():
		assert_ne(PlayMechanics.name_of(id), "", id)
		var hook := PlayMechanics.hook_of(id)
		assert_between(hook.split(" ").size(), 3, 16, "%s's hook is short: %s" % [id, hook])
		assert_ne(PlayMechanics.does(id), "", "%s says what a child does" % id)


func test_a_unit_s_mechanics_come_from_its_exercises_and_its_generators() -> void:
	var content := {"id": "g4.maths.x", "exercises": [{"type": "number"}, {"type": "choice"}, {"type": "choice"},
		{"type": "choice"}],
		"generators": [{"gen": "g4m.digit_value", "level": 1}]}
	var used := PlayMechanics.of_unit(content)
	assert_true(used.has("make"))
	assert_true(used.has("choose"))
	assert_eq(PlayMechanics.main_of(content), "choose", "the most common one")


func test_no_written_unit_has_a_type_without_a_mechanic() -> void:
	var units := 0
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				var c := Curriculum.content(str(u.id))
				if c.is_empty():
					continue
				units += 1
				assert_eq(PlayMechanics.unplayable(c), [] as Array[String], str(u.id))
	assert_gt(units, 790, "every written unit is checked")
	Curriculum.clear_cache()


func test_the_play_level_is_p0_until_a_signature_game_is_named() -> void:
	assert_eq(PlayMechanics.level({"id": "g4.maths.x"}), PlayMechanics.P0)
	assert_eq(PlayMechanics.level({"id": "g4.maths.x", "play": {"game": "generic"}}), PlayMechanics.P0)
	assert_eq(PlayMechanics.level({"id": "g4.maths.x", "play": {"game": "fraction_bakery"}}), PlayMechanics.P0,
		"a game not built yet plays the generic mechanics")
	for id: Variant in PlayMechanics.signature_games():   # owner #133, #134: each deep game built names its station or host
		var g: Dictionary = PlayMechanics.signature_games()[id]
		var path := str(g.get("script", g.get("host", "")))
		assert_true(ResourceLoader.exists(path), "%s names a script that exists: %s" % [id, path])


## Owner #134 (docs/design/future-lessons.md §7): written questions are never dressed as games: Choose by doing and
## Test it are shelved, each saying why; every kept mechanic is an action with a few words for the screen (rule 0).
func test_written_choices_and_claims_are_shelved_with_their_reason() -> void:
	for id in ["choose", "test"]:
		assert_false(PlayMechanics.kept(id), id)
		assert_ne(str(PlayMechanics.entry(id).get("why", "")), "", "%s says why it is shelved" % id)
	for id in ["make", "sort", "order", "connect", "fix", "build", "code", "beat", "mix", "find"]:
		assert_true(PlayMechanics.kept(id), id)
		var say := PlayMechanics.say_of(id)
		assert_ne(say, "", id)
		assert_lte(PlayReadless.words(say), 4, "%s: a few words on the screen" % id)
