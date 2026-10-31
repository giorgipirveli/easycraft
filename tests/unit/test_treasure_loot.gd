extends GutTest
## Owner feedback #42 (spec §12.16b, §13.2, §6): chest rarities. Each of the pack's chests is common, rare,
## epic or legendary, glows in its §13.2 colour, and holds things from a fixed table for its rarity and its
## universe: a fixed amount of Survivor gold (never random), a pick without repeats that is always the same
## for that chest. No gold loops: a chest opens once (the director) and nothing in it is money.

const CHESTS := {&"camp": ItemRarity.COMMON, &"ruins": ItemRarity.COMMON, &"shipwreck": ItemRarity.RARE,
	&"sunken": ItemRarity.RARE, &"cart": ItemRarity.RARE, &"hollowtree": ItemRarity.RARE, &"cove": ItemRarity.EPIC,
	&"waterfall": ItemRarity.EPIC, &"haunted": ItemRarity.EPIC, &"vault": ItemRarity.LEGENDARY}


func _ids(loot: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for e: Array in loot.items:
		out.append(int(e[0]))
	return out


func test_every_chest_of_the_pack_has_its_rarity() -> void:
	for kind: StringName in CHESTS:
		assert_true(TreasureLoot.handles(kind), String(kind))
		assert_eq(TreasureLoot.rarity_of(kind), int(CHESTS[kind]), String(kind))
		var loot := TreasureLoot.roll(kind, 12345, 1, true)
		assert_eq(int(loot.rarity), int(CHESTS[kind]), "the chest glows in its rarity: %s" % kind)
	assert_false(TreasureLoot.handles(&"buried"), "the M2 chests keep LootRules' tables")
	assert_eq(LootRules.rarity_color(ItemRarity.EPIC), Color("a54df2"), "§13.2 purple")


func test_four_rarities_common_rare_epic_legendary() -> void:
	var seen := {}
	for kind: StringName in CHESTS:
		seen[CHESTS[kind]] = true
	assert_eq(seen.keys().size(), 4)
	for r: int in [ItemRarity.COMMON, ItemRarity.RARE, ItemRarity.EPIC, ItemRarity.LEGENDARY]:
		assert_true(seen.has(r), ItemRarity.label(r))


func test_gold_is_fixed_by_rarity_and_scales_with_the_universe() -> void:
	for kind: StringName in CHESTS:
		var golds := {}
		for i in 30:
			golds[int(TreasureLoot.roll(kind, LootRules.chest_key(3, Vector3i(i, 7, -i)), 1, true).gold)] = true
		assert_eq(golds.size(), 1, "never random for money: %s" % kind)
		var g1 := int(TreasureLoot.roll(kind, 5, 1, true).gold)
		assert_eq(g1, int(TreasureLoot.GOLD[CHESTS[kind]]))
		assert_eq(int(TreasureLoot.roll(kind, 5, 2, true).gold), g1 * 2)
		assert_eq(int(TreasureLoot.roll(kind, 5, 3, true).gold), g1 * 4)
		assert_eq(int(TreasureLoot.roll(kind, 5, 1, false).gold), 0, "Sandbox: no gold")
	assert_lt(int(TreasureLoot.GOLD[ItemRarity.COMMON]), int(TreasureLoot.GOLD[ItemRarity.RARE]))
	assert_lt(int(TreasureLoot.GOLD[ItemRarity.RARE]), int(TreasureLoot.GOLD[ItemRarity.EPIC]))
	assert_lt(int(TreasureLoot.GOLD[ItemRarity.EPIC]), int(TreasureLoot.GOLD[ItemRarity.LEGENDARY]))
	assert_lte(int(TreasureLoot.GOLD[ItemRarity.LEGENDARY]), 150, "the spec's range")


func test_the_same_chest_always_holds_the_same_things() -> void:
	for kind: StringName in CHESTS:
		var key := LootRules.chest_key(99, Vector3i(4, 5, 6))
		assert_eq(TreasureLoot.roll(kind, key, 1, true), TreasureLoot.roll(kind, key, 1, true))
		assert_eq(TreasureLoot.roll(kind, key, 1, false).items, TreasureLoot.roll(kind, key, 1, true).items,
			"both modes find the same things")
	var different := {}
	for i in 40:
		different[str(TreasureLoot.roll(&"cove", LootRules.chest_key(1, Vector3i(i, 0, 0)), 1, true).items)] = true
	assert_gt(different.size(), 4, "chests differ from each other")


func test_no_chest_holds_the_same_thing_twice() -> void:
	for kind: StringName in CHESTS:
		for u in [1, 2, 3, 4]:
			for i in 40:
				var ids := _ids(TreasureLoot.roll(kind, LootRules.chest_key(i, Vector3i(1, i, 2)), u, true))
				var unique := {}
				for id in ids:
					unique[id] = true
				assert_eq(unique.size(), ids.size(), "no dupes in a %s chest: %s" % [kind, ids])


func test_contents_come_from_the_rarity_and_universe_table() -> void:
	for kind: StringName in CHESTS:
		var rarity: int = CHESTS[kind]
		for u in [1, 2, 3]:
			var allowed := {}
			for e: Array in TreasureLoot.table(rarity, u):
				allowed[int(e[0])] = int(e[1])
			for e: Array in TreasureLoot.ALWAYS[rarity]:
				allowed[int(e[0])] = int(e[1])
			for i in 30:
				var loot := TreasureLoot.roll(kind, LootRules.chest_key(i, Vector3i(8, 8, i)), u, true)
				assert_eq((loot.items as Array).size(), int(TreasureLoot.PICKS[rarity]) + (TreasureLoot.ALWAYS[rarity] as Array).size())
				for e: Array in loot.items:
					assert_true(allowed.has(int(e[0])), "%s in universe %d: %s" % [kind, u, e])
					assert_eq(int(e[1]), int(allowed.get(int(e[0]), -1)), "a fixed count")


func test_each_universe_has_its_own_common_supplies() -> void:
	var meadows := TreasureLoot.table(ItemRarity.COMMON, 1).map(func(e: Array) -> int: return int(e[0]))
	var desert := TreasureLoot.table(ItemRarity.COMMON, 2).map(func(e: Array) -> int: return int(e[0]))
	var frost := TreasureLoot.table(ItemRarity.COMMON, 3).map(func(e: Array) -> int: return int(e[0]))
	assert_true(meadows.has(BlockIds.LANTERN))
	assert_true(desert.has(BlockIds.DESERT_LAMP))
	assert_true(frost.has(BlockIds.ICE_LANTERN))
	assert_ne(meadows, desert)
	assert_eq(TreasureLoot.table(ItemRarity.COMMON, 4), TreasureLoot.table(ItemRarity.COMMON, 1), "a universe without its own: Green Meadows'")


func test_epic_chests_always_hold_gold_blocks_and_legendary_ones_a_golden_trophy() -> void:
	for i in 30:
		var key := LootRules.chest_key(i, Vector3i(2, 2, 2))
		assert_true(_ids(TreasureLoot.roll(&"cove", key, 1, true)).has(BlockIds.GOLD))
		assert_true(_ids(TreasureLoot.roll(&"vault", key, 1, true)).has(BlockIds.TROPHY))


## Nothing in a chest is money, and everything can be held (in ItemIds.ALL or a valid block).
func test_no_gold_loops_nothing_in_a_chest_is_money() -> void:
	for rarity: int in [ItemRarity.COMMON, ItemRarity.RARE, ItemRarity.EPIC, ItemRarity.LEGENDARY]:
		for u in [1, 2, 3]:
			for e: Array in TreasureLoot.table(rarity, u) + (TreasureLoot.ALWAYS[rarity] as Array):
				var id := int(e[0])
				assert_true(ItemIds.is_hotbar_valid(id), "holdable: %d" % id)
				assert_false(ChatCommands.NEVER_GIVEN.has(id) and not LootRules.TREASURE_ONLY.has(id),
					"no secret's own block: %d" % id)
				assert_between(int(e[1]), 1, 16)


func test_lootrules_hands_the_packs_chests_to_treasureloot() -> void:
	var key := LootRules.chest_key(7, Vector3i(1, 2, 3))
	assert_eq(LootRules.roll(&"vault", key, 2, true), TreasureLoot.roll(&"vault", key, 2, true))


## §6: no random gold anywhere — the M2 kinds' gold is fixed per kind now too (their items are unchanged).
func test_the_m2_chests_gold_is_fixed_per_kind() -> void:
	for kind: StringName in [&"buried", &"room", &"temple", &"sky", &"wanderer"]:
		var golds := {}
		for i in 30:
			golds[int(LootRules.roll(kind, LootRules.chest_key(3, Vector3i(i, 0, i)), 1, true).gold)] = true
		assert_eq(golds.size(), 1, String(kind))
		var t: Dictionary = LootRules.TABLES[kind]
		assert_eq(golds.keys()[0], (int(t.gold[0]) + int(t.gold[1])) / 2, "the middle of its old range")
	var g := {}
	for i in 20:
		g[int(LootRules.golden_reward(LootRules.chest_key(i, Vector3i.ONE), 1, true).gold)] = true
	assert_eq(g.size(), 1, "a golden animal's pile too")
