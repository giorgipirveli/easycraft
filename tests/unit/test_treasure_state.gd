extends GutTest
## Owner feedback #42: what the treasure pack keeps in a world's save (inside SecretState, WorldMeta.secrets):
## the dawns seen (the rainbows' and the well's days), the rainbows so far, who took which pot of gold and
## who wished on which day. Loading never fails; broken parts read as nothing.


func test_it_saves_and_loads_again() -> void:
	var t := TreasureState.new()
	t.dawns = 7
	t.rainbows = 3
	t.take_pot(3, "Ana")
	TreasureRules.wish(t.wishes, "Ana", 7)
	var back := TreasureState.from_save(JSON.parse_string(JSON.stringify(t.to_save())))
	assert_eq(back.dawns, 7)
	assert_eq(back.rainbows, 3)
	assert_true(back.took_pot(3, "Ana"))
	assert_false(back.took_pot(3, "Beka"))
	assert_false(TreasureRules.may_wish(back.wishes, "Ana", 7), "the wish is remembered")


func test_a_pot_is_taken_once_per_rainbow_for_each_player() -> void:
	var t := TreasureState.new()
	assert_true(t.take_pot(1, "Ana"))
	assert_false(t.take_pot(1, "Ana"), "once")
	assert_true(t.take_pot(1, "Beka"), "each player their own")
	assert_true(t.take_pot(2, "Ana"), "the next rainbow again")


func test_broken_saves_never_fail() -> void:
	for bad: Variant in [null, 5, "x", [], {"dawns": "many", "rainbows": -4, "pots": 7, "wishes": [1, 2]},
			{"dawns": INF, "pots": [1, "2:Ana", null], "wishes": {"Ana": "x", 5: 3, "Beka": 2.0}}]:
		var t := TreasureState.from_save(bad)
		assert_gte(t.dawns, 0)
		assert_gte(t.rainbows, 0)
	var t := TreasureState.from_save({"pots": [1, "2:Ana", null], "wishes": {"Ana": "x", "Beka": 2.0}})
	assert_true(t.took_pot(2, "Ana"))
	assert_eq(t.pots.size(), 1)
	assert_eq(t.wishes, {"Beka": 2})


func test_it_never_grows_without_end() -> void:
	var t := TreasureState.new()
	for i in TreasureState.MAX_ENTRIES + 50:
		t.take_pot(i, "p%d" % i)
		TreasureRules.wish(t.wishes, "p%d" % i, i)
	var back := TreasureState.from_save(t.to_save())
	assert_lte(back.pots.size(), TreasureState.MAX_ENTRIES)
	assert_lte(back.wishes.size(), TreasureState.MAX_ENTRIES)
	assert_true(back.took_pot(TreasureState.MAX_ENTRIES + 49, "p%d" % (TreasureState.MAX_ENTRIES + 49)), "the newest kept")


func test_the_secrets_save_carries_it_and_old_saves_still_load() -> void:
	var s := SecretState.new()
	s.more.dawns = 4
	s.more.take_pot(2, "Ana")
	var back := SecretState.from_save(JSON.parse_string(JSON.stringify(s.to_save())))
	assert_eq(back.more.dawns, 4)
	assert_true(back.more.took_pot(2, "Ana"))
	var old := SecretState.from_save({"found": ["temple_1_2_3"], "dusks": 2})
	assert_eq(old.more.dawns, 0, "a world saved before the pack")
	assert_true(old.found.has("temple_1_2_3"))
