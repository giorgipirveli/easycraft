extends GutTest
## Pickup bags are saved with the world (M2 Task 2, spec §12.3): WorldMeta.bags, parsed defensively.


func test_bags_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.bags = [{"owner": "Mia", "pos": [3.5, 20.0, -4.5], "items": [[BlockIds.PLANKS, 16], [BlockIds.DIRT, 8]], "age": 42.5},
		{"owner": "", "pos": [0.5, -30.0, 0.5], "items": [[BlockIds.CRYSTAL, 1200]], "age": 0.0}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.bags.size(), 2)
	assert_eq(back.bags[0].owner, "Mia")
	assert_eq(back.bags[0].pos, [3.5, 20.0, -4.5])
	assert_eq(back.bags[0].items, [[BlockIds.PLANKS, 16], [BlockIds.DIRT, 8]])
	assert_almost_eq(float(back.bags[0].age), 42.5, 0.001)
	assert_eq(back.bags[1].owner, "")
	assert_eq(back.bags[1].items, [[BlockIds.CRYSTAL, 1200]], "a merged bag may hold more than 999")


func test_old_saves_have_no_bags() -> void:
	assert_eq(WorldMeta.from_json('{"seed": 5}').bags, [])
	assert_eq(WorldMeta.from_json('{"seed": 5, "bags": "junk"}').bags, [])


func test_broken_bags_are_dropped_and_the_list_is_capped() -> void:
	var list: Array = [
		{"owner": "Mia", "pos": [0, 0], "items": [[BlockIds.DIRT, 1]]},            # bad position
		{"owner": "Mia", "pos": [0, "x", 0], "items": [[BlockIds.DIRT, 1]]},
		{"owner": "Mia", "pos": [0, 0, 0], "items": [[ItemIds.SWORD, 1]]},        # no blocks in it
		{"owner": "Mia", "pos": [0, 0, 0], "items": "junk"},
		"junk",
		{"owner": 7, "pos": [1, 2, 3], "items": [[BlockIds.SAND, 2], [ItemIds.BOW, 1]], "age": -5},
		{"pos": [1, 2, 3], "items": [[BlockIds.SAND, 2]], "age": "old"},
	]
	for i in KnockoutRules.MAX_BAGS + 5:
		list.append({"owner": "P", "pos": [i, 10, 0], "items": [[BlockIds.STONE, 1]], "age": 1})
	var back := WorldMeta.from_json(JSON.stringify({"seed": 1, "bags": list}))
	assert_eq(back.bags.size(), KnockoutRules.MAX_BAGS)
	assert_eq(back.bags[0].owner, "", "not a name: anyone's")
	assert_eq(back.bags[0].items, [[BlockIds.SAND, 2]], "only blocks")
	assert_eq(float(back.bags[0].age), 0.0, "a negative age is 0")
	assert_eq(back.bags[1].owner, "", "no owner: anyone's")
	assert_eq(float(back.bags[1].age), 0.0)
