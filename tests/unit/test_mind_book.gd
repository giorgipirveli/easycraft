extends GutTest
## MindBook (M2 Task 18, spec §12.17): each species in a world keeps one small learned table, saved
## in WorldMeta.minds (at most 2 KB for the whole world), parsed defensively.


func _teach(net: TinyNet, n: int) -> void:
	var x := PackedFloat32Array()
	x.resize(TinyNet.INPUTS)
	x.fill(0.5)
	for i in n:
		net.forward(x)
		net.learn(i % net.outputs, 1.0 if i % 2 == 0 else -1.0, 0.3, net.last_hidden())


func test_every_animal_of_a_species_shares_one_learned_table() -> void:
	var book := MindBook.new()
	var sheep := book.net_for(AnimalSpecies.table(&"sheep"))
	assert_same(book.net_for(AnimalSpecies.table(&"sheep")), sheep, "what one sheep learns, every sheep knows")
	assert_ne(book.net_for(AnimalSpecies.table(&"cow")), sheep)
	var a := Mind.create(AnimalSpecies.table(&"sheep"), "a1_1_0", sheep)
	assert_false(a.owns_net)


func test_only_learned_tables_are_saved_and_they_come_back() -> void:
	var book := MindBook.new()
	book.net_for(AnimalSpecies.table(&"cow"))
	var sheep := book.net_for(AnimalSpecies.table(&"sheep"))
	_teach(sheep, 30)
	var saved := book.to_save()
	assert_eq(saved.keys(), ["animal:sheep"], "a cow that learned nothing is not saved")
	var back := MindBook.new()
	back.load_save(JSON.parse_string(JSON.stringify(saved)))
	var again := back.net_for(AnimalSpecies.table(&"sheep"))
	assert_false(again.is_fresh(), "the world's sheep remember")
	var x := PackedFloat32Array()
	x.resize(TinyNet.INPUTS)
	x.fill(0.5)
	var s1 := sheep.forward(x)
	var s2 := again.forward(x)
	for i in s1.size():
		assert_almost_eq(s2[i], s1[i], 0.05)


func test_a_whole_world_of_learned_species_saves_in_two_kilobytes() -> void:
	# Owner #41: there are more kinds of animal than 2 KB holds (about 13 tables): the monsters' tables come first
	# (test_monster_mind), then the animals' tables that learned the most.
	var book := MindBook.new()
	var n := 0
	for sp: StringName in AnimalRules.SPECIES:
		_teach(book.net_for(AnimalSpecies.table(sp)), 8 + n)   # each kind taught a little more than the last
		n += 1
	var saved := book.to_save()
	assert_lte(JSON.stringify(saved).length(), MindBook.MAX_TOTAL, "saved minds ≤ 2 KB per world")
	assert_gte(saved.size(), 12, "a dozen tables fit")
	var kinds: Array = AnimalRules.SPECIES.keys()
	assert_true(saved.has("animal:%s" % kinds.back()), "the kind that learned the most is kept")
	assert_false(saved.has("animal:%s" % kinds[0]), "the one that learned the least is left out when it can't fit")
	var back := MindBook.new()
	back.load_save(saved)
	assert_eq(back.to_save(), saved, "saved tables not in use yet keep their place")


func test_a_saved_table_waits_for_its_species_and_is_kept_meanwhile() -> void:
	var book := MindBook.new()
	_teach(book.net_for(AnimalSpecies.table(&"rabbit")), 20)
	var back := MindBook.new()
	back.load_save(book.to_save())
	assert_eq(back.to_save(), book.to_save(), "no rabbit around yet: the table is still saved")


func test_broken_minds_in_a_save_are_dropped() -> void:
	var good := MindBook.new()
	_teach(good.net_for(AnimalSpecies.table(&"pig")), 10)
	var ok_text: String = good.to_save()["animal:pig"]
	var clean := MindBook.clean({"animal:pig": ok_text, "bad key!": ok_text, "animal:cow": 5,
		"animal:dog": "!!!!", "animal:cat": "x".repeat(5000)})
	assert_eq(clean.keys(), ["animal:pig"])
	assert_eq(MindBook.clean(null), {})
	assert_eq(MindBook.clean([1, 2]), {})
	var many := {}
	for i in 40:
		many["animal:x%d" % i] = ok_text
	assert_lte(JSON.stringify(MindBook.clean(many)).length(), MindBook.MAX_TOTAL)
	# a table of the wrong size is ignored when its species comes
	var book := MindBook.new()
	book.load_save({"animal:sheep": ok_text.substr(0, 8)})
	assert_true(book.net_for(AnimalSpecies.table(&"sheep")).is_fresh())


func test_world_meta_keeps_the_minds() -> void:
	var book := MindBook.new()
	_teach(book.net_for(AnimalSpecies.table(&"sheep")), 10)
	var meta := WorldMeta.new_random()
	meta.minds = book.to_save()
	var back := WorldMeta.from_json(meta.to_json())
	assert_eq(back.minds, meta.minds)
	var broken := JSON.parse_string(meta.to_json()) as Dictionary
	broken.minds = "nope"
	assert_eq(WorldMeta.from_json(JSON.stringify(broken)).minds, {})


func test_pets_and_friends_keep_their_minds_in_the_world_save() -> void:
	var dog := Mind.create(AnimalSpecies.table(&"dog"), "pet1")
	dog.memory.feel_about("Tina", 1.0, 0.0, 0.0)
	dog.memory.pin("Tina")
	var pip := Mind.create(BotSpecies.table(), "Pip")
	var meta := WorldMeta.new_random()
	meta.pets = [{"species": "dog", "name": "Rex", "pos": [1.0, 2.0, 3.0], "id": "pet1", "mind": dog.to_save()}]
	meta.bots = [{"name": "Pip", "personality": "builder", "look": 0, "mind": pip.to_save()}]
	var back := WorldMeta.from_json(meta.to_json())
	var dog2 := Mind.create(AnimalSpecies.table(&"dog"), "pet1")
	dog2.load_save(back.pets[0].mind)
	assert_true(dog2.memory.knows("Tina"), "the dog remembers its owner by name")
	assert_true(back.bots[0].has("mind"))
	var broken := JSON.parse_string(meta.to_json()) as Dictionary
	broken.pets[0].mind = "nope"
	broken.bots[0].mind = {"huge": "x".repeat(5000)}
	var parsed := WorldMeta.from_json(JSON.stringify(broken))
	assert_eq(parsed.pets.size(), 1, "the pet itself stays")
	assert_false(parsed.pets[0].has("mind"))
	assert_eq(parsed.bots.size(), 1)
	assert_false(parsed.bots[0].has("mind"), "a mind bigger than 2 KB is dropped")
