extends GutTest
## M2 Task 16 (spec §12.16, §13.2, §6): what treasure holds. Deterministic per chest (seed + position), gold
## 20–150 × 2^(u−1) in Survivor only, rare blocks, sometimes a better tool or a potion, a treasure map, and
## decorations that exist only in treasure. Never bought, never random for money.

const KINDS: Array[StringName] = [&"buried", &"room", &"temple", &"sky", &"wanderer"]


func _items(loot: Dictionary) -> Array[int]:
	var ids: Array[int] = []
	for e: Array in loot.items:
		ids.append(e[0])
	return ids


func test_the_same_chest_always_holds_the_same_loot() -> void:
	var key := LootRules.chest_key(12345, Vector3i(40, 30, -7))
	assert_eq(LootRules.roll(&"room", key, 1, true), LootRules.roll(&"room", key, 1, true))
	assert_eq(key, LootRules.chest_key(12345, Vector3i(40, 30, -7)))
	assert_ne(key, LootRules.chest_key(12346, Vector3i(40, 30, -7)), "another world")
	assert_ne(key, LootRules.chest_key(12345, Vector3i(41, 30, -7)), "another chest")
	var different := {}
	for i in 50:
		different[str(LootRules.roll(&"buried", LootRules.chest_key(1, Vector3i(i, 0, 0)), 1, true))] = true
	assert_gt(different.size(), 25, "chests differ from each other")


func test_gold_by_kind_scales_with_the_universe() -> void:
	for kind in KINDS:
		var range_: Array = LootRules.TABLES[kind].gold
		assert_gte(int(range_[0]), 20, String(kind))
		assert_lte(int(range_[1]), 150, String(kind))
		for i in 60:
			var key := LootRules.chest_key(7, Vector3i(i, 2, 3))
			var g1: int = LootRules.roll(kind, key, 1, true).gold
			var g2: int = LootRules.roll(kind, key, 2, true).gold
			assert_between(g1, int(range_[0]), int(range_[1]), String(kind))
			assert_eq(g2, g1 * 2, "universe 2 pays twice as much")
			assert_eq(LootRules.roll(kind, key, 3, true).gold, g1 * 4)


func test_sandbox_treasure_has_no_gold_but_the_same_things() -> void:
	for i in 40:
		var key := LootRules.chest_key(9, Vector3i(i, -5, i))
		var survivor := LootRules.roll(&"temple", key, 1, true)
		var sandbox := LootRules.roll(&"temple", key, 1, false)
		assert_eq(sandbox.gold, 0)
		assert_eq(sandbox.items, survivor.items)


func test_every_chest_holds_rare_blocks() -> void:
	for kind in [&"buried", &"room", &"temple", &"sky"]:
		for i in 30:
			var loot := LootRules.roll(kind, LootRules.chest_key(3, Vector3i(i, 0, 1)), 1, true)
			var blocks := _items(loot).filter(func(id: int) -> bool: return BlockIds.is_valid(id) and not LootRules.TREASURE_ONLY.has(id))
			assert_eq(blocks.size(), 1, String(kind))


func test_temples_and_sky_islands_always_hold_a_decoration() -> void:
	for kind in [&"temple", &"sky"]:
		for i in 40:
			var ids := _items(LootRules.roll(kind, LootRules.chest_key(4, Vector3i(0, i, 0)), 1, true))
			assert_true(ids.has(BlockIds.TROPHY) or ids.has(BlockIds.GOLD_LAMP), String(kind))


## Shares over many chests: maps, potions, better tools and decorations show up "sometimes".
func test_maps_potions_tools_and_decorations_sometimes() -> void:
	var counts := {"map": 0, "potion": 0, "tool": 0, "decoration": 0}
	var n := 400
	for i in n:
		var ids := _items(LootRules.roll(&"room", LootRules.chest_key(5, Vector3i(i, 1, 2)), 1, true))
		for id in ids:
			if id == ItemIds.TREASURE_MAP:
				counts.map += 1
			elif ItemIds.POTIONS.has(id):
				counts.potion += 1
			elif ItemIds.TIERED.has(id):
				counts.tool += 1
			elif id == BlockIds.TROPHY or id == BlockIds.GOLD_LAMP:
				counts.decoration += 1
	for what: String in counts:
		var share: float = counts[what] / float(n)
		assert_between(share, 0.1, 0.6, "%s share %.2f" % [what, share])


func test_the_rarity_is_the_best_thing_inside() -> void:
	var saw_legendary := false
	for i in 60:
		var loot := LootRules.roll(&"buried", LootRules.chest_key(6, Vector3i(i, 0, 0)), 1, true)
		var best := LootRules.COMMON
		for id in _items(loot):
			best = maxi(best, LootRules.rarity_of(id))
		assert_eq(loot.rarity, best)
		saw_legendary = saw_legendary or loot.rarity == LootRules.LEGENDARY
	assert_true(saw_legendary)
	assert_eq(LootRules.rarity_of(BlockIds.TROPHY), LootRules.LEGENDARY)
	assert_eq(LootRules.rarity_of(ItemIds.SWORD_STONE), LootRules.UNCOMMON)
	assert_eq(LootRules.rarity_of(ItemIds.PICKAXE_IRON), LootRules.RARE)
	assert_eq(LootRules.rarity_of(ItemIds.SWORD_CRYSTAL), LootRules.EPIC)
	assert_eq(LootRules.rarity_of(BlockIds.DIRT), LootRules.COMMON)
	assert_eq(LootRules.RARITY_COLORS.size(), 5, "grey, green, blue, purple, gold (§13.2)")


## §6: treasure is found by playing. It is in no palette row, and /give never gives it.
func test_treasure_only_things_are_never_picked_or_given() -> void:
	for id in LootRules.TREASURE_ONLY:
		assert_false(BlockIds.PLACEABLE.has(id), ItemIds.display_name(id))
		assert_false(ItemIds.MAGIC.has(id) or ItemIds.TOOLS.has(id), ItemIds.display_name(id))
		assert_false(ChatCommands.giveable_ids().has(id), ItemIds.display_name(id))
		assert_true(ItemIds.is_hotbar_valid(id), "once found, it can be held: %s" % ItemIds.display_name(id))


func test_a_golden_animal_gives_a_pile_of_gold_or_a_trophy() -> void:
	var key := LootRules.chest_key(8, Vector3i(1, 2, 3))
	var survivor := LootRules.golden_reward(key, 1, true)
	assert_between(int(survivor.gold), 60, 100)
	assert_eq(survivor.items, [])
	assert_eq(LootRules.golden_reward(key, 2, true).gold, survivor.gold * 2)
	var sandbox := LootRules.golden_reward(key, 1, false)
	assert_eq(sandbox.gold, 0)
	assert_eq(sandbox.items, [[BlockIds.TROPHY, 1]])
	assert_eq(sandbox.rarity, LootRules.LEGENDARY)


## Hook for §13.5 (M3 content): a Party Piñata bursts into supplies.
func test_a_pinata_bursts_into_supplies() -> void:
	var loot := LootRules.roll(&"pinata", LootRules.chest_key(2, Vector3i.ZERO), 1, true)
	assert_eq(loot.gold, 0, "supplies, not gold")
	assert_gt(loot.items.size(), 0)


func test_describe_names_everything_in_a_short_line() -> void:
	var text := LootRules.describe({"gold": 85, "items": [[BlockIds.DIAMOND, 6], [BlockIds.TROPHY, 1]], "rarity": 4})
	assert_eq(text, "85 gold, 6 Diamond, Golden Trophy")
	assert_eq(LootRules.describe({"gold": 0, "items": [[ItemIds.TREASURE_MAP, 1]], "rarity": 3}), "Treasure Map")



## Merge of Tasks 6 and 16: chests glow in the same rarity colours as tier items (one table, §13.2).
func test_loot_uses_the_item_rarity_colours() -> void:
	assert_eq(LootRules.RARITY_COLORS, ItemRarity.COLORS)
