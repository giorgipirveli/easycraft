extends GutTest
## Owner #78 (spec §21e): the line of flight in history's order — the kite, the hot-air balloon, the glider, the plane
## with an engine, the jet, the rocket — each with its real story (people of history only, never living people), its
## science, what it opens, its "try it", what it is made of at a Workbench and the School unit on its science.


func test_the_line_is_in_history_s_order() -> void:
	assert_eq(InventionLine.ORDER, [InventionLine.KITE, InventionLine.BALLOON, InventionLine.GLIDER, InventionLine.PLANE,
		InventionLine.JET, InventionLine.ROCKET] as Array[StringName])
	var last := -100000
	for id in InventionLine.ORDER:
		var e := InventionLine.entry(id)
		assert_false(e.is_empty(), "%s is in the table" % id)
		assert_gt(int(e.year), last, "%s comes after the one before" % id)
		last = int(e.year)
	assert_eq(int(InventionLine.entry(InventionLine.BALLOON).year), 1783)
	assert_eq(int(InventionLine.entry(InventionLine.PLANE).year), 1903)
	assert_eq(int(InventionLine.entry(InventionLine.JET).year), 1939)
	assert_eq(int(InventionLine.entry(InventionLine.ROCKET).year), 1957)
	assert_true(InventionLine.entry(&"teleporter").is_empty())


func test_each_has_its_story_its_science_and_what_it_opens() -> void:
	for id in InventionLine.ORDER:
		var e := InventionLine.entry(id)
		for key: String in ["name", "when", "where", "story", "science", "opens", "try", "try_done", "made_of"]:
			assert_true(str(e.get(key, "")).length() > 3, "%s has its %s" % [id, key])
		assert_true(InventionLine.index(id) == InventionLine.ORDER.find(id))
	assert_string_contains(InventionLine.entry(InventionLine.PLANE).story, "12 seconds")
	assert_string_contains(InventionLine.entry(InventionLine.BALLOON).science, "lighter than cold air")
	assert_string_contains(InventionLine.entry(InventionLine.ROCKET).story, "1969")
	assert_string_contains(InventionLine.entry(InventionLine.ROCKET).opens, "Launch Site")


func test_only_people_of_history_are_named() -> void:
	for id in InventionLine.ORDER:
		var people: Array = InventionLine.entry(id).people
		assert_false(people.is_empty(), "%s names who did it" % id)
		for p: Array in people:
			assert_eq(p.size(), 3, "%s: [name, born, died]" % id)
			assert_lt(int(p[1]), int(p[2]), "%s was born before they died" % p[0])
			assert_lt(int(p[2]), 2026, "%s is a person of history (never a living person)" % p[0])
			assert_string_contains(str(InventionLine.entry(id).story), str(p[0]).split(" ")[-1],
				"the story tells of %s" % p[0])


func test_each_is_made_from_real_materials_at_a_workbench() -> void:
	for id in InventionLine.ORDER:
		var needs: Array = InventionLine.entry(id).needs
		assert_false(needs.is_empty(), "%s is made of something" % id)
		for n: Array in needs:
			assert_true(InventionLine.MATERIALS.has(n[0]), "%s: a known material (%s)" % [id, n[0]])
			assert_gt(int(n[1]), 0)
			assert_true(str(n[2]).length() > 3, "%s: why it needs %s" % [id, n[0]])
			for thing: int in InventionLine.MATERIALS[n[0]].ids:
				assert_true(Inventory.ownable(thing), "%s: a bag holds %s" % [n[0], thing])
	var kite := InventionLine.needs_of(InventionLine.KITE)
	assert_eq(kite[&"sticks"], 4)
	assert_eq(kite[&"cloth"], 3)
	assert_true(InventionLine.MATERIALS[&"cloth"].ids.has(BlockIds.SAIL), "sail cloth is cloth")
	assert_true(InventionLine.MATERIALS[&"cloth"].ids.has(BlockIds.RED), "a sheep's wool is cloth")
	assert_true(InventionLine.needs_of(InventionLine.JET).has(&"kerosene"), "a jet burns kerosene")


func test_each_costs_a_little_gold_or_its_school_unit() -> void:
	var before := 0
	for id in InventionLine.ORDER:
		var e := InventionLine.entry(id)
		assert_gt(int(e.gold), before, "%s costs more than the one before" % id)
		before = int(e.gold)
		assert_true(SchoolData.valid_id(str(e.unit)), "%s: a School unit id (%s)" % [id, e.unit])
		assert_false(Curriculum.unit(str(e.unit)).is_empty(), "%s: the unit is in the School" % id)
		assert_true(Curriculum.has_content(str(e.unit)), "%s: the unit is written" % id)
	assert_lte(int(InventionLine.entry(InventionLine.ROCKET).gold), 200, "a little gold: under a day of learning")


func test_the_words_read_well() -> void:
	assert_eq(InventionLine.needs_words(InventionLine.KITE), "4 Sticks, 3 Cloth")
	assert_string_contains(InventionLine.material_name(&"cloth"), "Cloth")
	assert_eq(InventionLine.material_name(&"nothing"), "")
