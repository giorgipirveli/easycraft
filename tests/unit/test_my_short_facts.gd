extends GutTest
## MAKE MY SHORT: "3 facts about…" uses the game's own facts and pictures: a planet, a moon or the Sun (the Star Map's
## facts), a wonder (WonderFacts: the Wonders Passport's) or a real animal (the Animal Book's fact first, then two more
## the game keeps for the Shorts). Every offered thing has at least three facts that fit a caption.


func test_three_kinds_of_subject() -> void:
	assert_eq(MyShortFacts.KINDS, [MyShortFacts.PLANET, MyShortFacts.WONDER, MyShortFacts.ANIMAL] as Array[String])
	for k: String in MyShortFacts.KINDS:
		assert_gte(MyShortFacts.things(k).size(), 8, k)
		assert_ne(MyShortFacts.kind_words(k), "", k)


func test_every_offered_thing_has_three_facts_that_fit_a_caption() -> void:
	var n := 0
	for k: String in MyShortFacts.KINDS:
		for id: String in MyShortFacts.things(k):
			var facts := MyShortFacts.facts(k, id)
			assert_gte(facts.size(), MyShortRules.FACT_COUNT, "%s %s" % [k, id])
			for f in facts:
				assert_lte(f.length(), MyShortRules.MAX_FACT, f)
				assert_true(f.ends_with(".") or f.ends_with("!") or f.ends_with("?"), f)
				assert_lte(ShortRules.speech_seconds(f), ShortRules.SCENE_MAX - 2.0, f)
			assert_ne(MyShortFacts.name_of(k, id), "", id)
			assert_lte(MyShortFacts.title_for(k, id).length(), ShortRules.MAX_TITLE, MyShortFacts.title_for(k, id))
			n += 1
	assert_gt(n, 50)


func test_planets_facts_are_the_star_map_s() -> void:
	var mars := MyShortFacts.facts(MyShortFacts.PLANET, "mars")
	assert_eq(mars, StarMap.body(&"mars").facts)
	assert_true(MyShortFacts.things(MyShortFacts.PLANET).has("moon"))
	assert_true(MyShortFacts.things(MyShortFacts.PLANET).has("sun"))
	for id: String in MyShortFacts.things(MyShortFacts.PLANET):
		var kind := str(StarMap.body(StringName(id)).kind)
		assert_true(kind in ["star", "planet", "dwarf", "moon"], "%s: real bodies only (%s)" % [id, kind])
	assert_eq(MyShortFacts.title_for(MyShortFacts.PLANET, "mars"), "3 facts about Mars")
	assert_eq(MyShortFacts.title_for(MyShortFacts.PLANET, "moon"), "3 facts about the Moon")
	assert_eq(MyShortFacts.link_of(MyShortFacts.PLANET, "mars"), {"star_map": true})


func test_wonders_facts_are_the_passport_s() -> void:
	for id: String in MyShortFacts.things(MyShortFacts.WONDER):
		var theirs: Array = WonderFacts.of(StringName(id)).facts
		for f in MyShortFacts.facts(MyShortFacts.WONDER, id):
			assert_true(theirs.has(f), f)
	assert_true(MyShortFacts.things(MyShortFacts.WONDER).has("pyramid"))
	assert_eq(MyShortFacts.link_of(MyShortFacts.WONDER, "pyramid"), {"star_map": true})


func test_animals_are_real_and_open_with_their_book_fact() -> void:
	var list := MyShortFacts.things(MyShortFacts.ANIMAL)
	for fantasy: String in ["pip", "dragon", "gummy_bunny", "candy_bird", "moon_bunny"]:
		assert_false(list.has(fantasy), fantasy + ": the Shorts teach true things")
	for id: String in list:
		assert_true(AnimalRules.SPECIES.has(StringName(id)), id)
		assert_eq(MyShortFacts.facts(MyShortFacts.ANIMAL, id)[0], AnimalBookRules.fact_of(StringName(id)), id)
	assert_eq(MyShortFacts.link_of(MyShortFacts.ANIMAL, "fox"), {}, "nothing to open for an animal")
	assert_eq(MyShortFacts.title_for(MyShortFacts.ANIMAL, "polar_bear"), "3 facts about polar bears")


func test_unknown_things_have_nothing() -> void:
	assert_eq(MyShortFacts.facts(MyShortFacts.PLANET, "vulcan"), [] as Array[String])
	assert_eq(MyShortFacts.facts("dinosaur", "t_rex"), [] as Array[String])
	assert_false(MyShortFacts.has(MyShortFacts.ANIMAL, "pip"))
	assert_true(MyShortFacts.has(MyShortFacts.ANIMAL, "fox"))
