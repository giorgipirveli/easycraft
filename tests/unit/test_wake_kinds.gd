extends GutTest
## M3 Task 21c: the Magic Wand wakes more things (spec §16 "wake more objects"): a cactus (the desert's), a
## snowman (a snowman's head on snow blocks: Frostpeak's mouse holes have one), a pumpkin (or a jack-o-lantern, or a
## scarecrow with a pumpkin head) come alive with a personality of their own; and an empty treasure chest wakes as
## a chest mimic that hops after you, giggles and gives a small present — never scary, never harmful.
## Task 20b's secret buddy shapes are recipes of their own (a snowman of snow blocks with an orange nose is one of
## them): WakeKinds never takes a build without its own blocks (a cactus, a pumpkin, a snowman's head).


func _column(ids: Array) -> Dictionary:
	var b := {}
	for i in ids.size():
		b[Vector3i(0, i, 0)] = ids[i]
	return b


func test_a_cactus_wakes_as_a_cactus() -> void:
	assert_eq(WakeKinds.kind_of(_column([BlockIds.CACTUS, BlockIds.CACTUS, BlockIds.CACTUS])), WakeKinds.CACTUS)
	assert_eq(WakeKinds.kind_of(_column([BlockIds.CACTUS])), WakeKinds.CACTUS)
	var arms := _column([BlockIds.CACTUS, BlockIds.CACTUS, BlockIds.CACTUS])
	arms[Vector3i(1, 1, 0)] = BlockIds.CACTUS
	arms[Vector3i(-1, 2, 0)] = BlockIds.CACTUS
	assert_eq(WakeKinds.kind_of(arms), WakeKinds.CACTUS, "a cactus with arms")
	assert_eq(WakeKinds.kind_of(_column([BlockIds.CACTUS, BlockIds.PLANKS, BlockIds.PLANKS])), WakeKinds.NONE,
		"a house with one cactus is still a house")


func test_a_pumpkin_wakes_as_a_pumpkin() -> void:
	assert_eq(WakeKinds.kind_of(_column([BlockIds.PUMPKIN])), WakeKinds.PUMPKIN)
	var in_flowers := _column([BlockIds.PUMPKIN])
	for p: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1)]:
		in_flowers[p] = BlockIds.FLOWERS
	assert_eq(WakeKinds.kind_of(in_flowers), WakeKinds.PUMPKIN, "flowers it grew among (the wand takes them along) don't count")
	assert_eq(WakeKinds.kind_of(_column([BlockIds.JACK_O_LANTERN])), WakeKinds.PUMPKIN)
	assert_eq(WakeKinds.kind_of(_column([BlockIds.PLANKS, BlockIds.PLANKS, BlockIds.JACK_O_LANTERN])), WakeKinds.PUMPKIN,
		"a scarecrow with a pumpkin head")
	assert_eq(WakeKinds.kind_of(_column([BlockIds.PUMPKIN, BlockIds.PLANKS, BlockIds.PLANKS])), WakeKinds.NONE,
		"a pumpkin at the bottom of a tower doesn't make it a pumpkin")


func test_a_snowman_wakes_as_a_snowman() -> void:
	assert_eq(WakeKinds.kind_of(_column([BlockIds.PACKED_SNOW, BlockIds.PACKED_SNOW, BlockIds.SNOWMAN_HEAD])),
		WakeKinds.SNOWMAN)
	assert_eq(WakeKinds.kind_of(_column([BlockIds.SNOW_BRICK, BlockIds.SNOWMAN_HEAD])), WakeKinds.SNOWMAN)
	assert_eq(WakeKinds.kind_of(_column([BlockIds.SNOWMAN_HEAD])), WakeKinds.SNOWMAN, "a head alone is a little snowman")
	assert_eq(WakeKinds.kind_of(_column([BlockIds.SNOWMAN_HEAD, BlockIds.PACKED_SNOW])), WakeKinds.NONE,
		"the head goes on top")
	assert_eq(WakeKinds.kind_of(_column([BlockIds.PLANKS, BlockIds.PLANKS, BlockIds.PLANKS, BlockIds.SNOWMAN_HEAD])),
		WakeKinds.NONE, "a wooden tower with a snowman's head is not a snowman")


## Task 20b's recipes stay theirs: snow blocks with an orange nose, and ordinary builds, are not wake kinds.
func test_builds_without_their_own_blocks_are_ordinary_buddies() -> void:
	var nose := _column([BlockIds.PACKED_SNOW, BlockIds.PACKED_SNOW, BlockIds.PACKED_SNOW])
	nose[Vector3i(0, 2, -1)] = BlockIds.PAINTED_ORANGE
	assert_eq(WakeKinds.kind_of(nose), WakeKinds.NONE)
	assert_eq(WakeKinds.kind_of(_column([BlockIds.PLANKS, BlockIds.BRICK])), WakeKinds.NONE)
	assert_eq(WakeKinds.kind_of({}), WakeKinds.NONE)


func test_names_and_wake_lines() -> void:
	var cactus := _column([BlockIds.CACTUS, BlockIds.CACTUS])
	assert_true(WakeKinds.NAMES[WakeKinds.CACTUS].has(WakeKinds.name_for(cactus)))
	assert_eq(WakeKinds.name_for(cactus), WakeKinds.name_for(cactus.duplicate()), "the same build, the same name")
	var plain := _column([BlockIds.PLANKS, BlockIds.BRICK])
	assert_eq(WakeKinds.name_for(plain), BuddyNames.name_for(plain), "an ordinary buddy keeps its name")
	for kind: StringName in [WakeKinds.CACTUS, WakeKinds.PUMPKIN, WakeKinds.SNOWMAN]:
		var line := WakeKinds.wake_line(kind, "Bo")
		assert_true(line.begins_with("Bo is awake!"), line)
		assert_lt(line.length(), 60, "short words for children: " + line)
	assert_eq(WakeKinds.wake_line(WakeKinds.NONE, "Bo"), "")
	assert_true(WakeKinds.wake_line(WakeKinds.CACTUS, "Bo").contains("never prickle"), "a cactus friend never hurts")


func test_a_jack_o_lantern_buddy_glows_orange() -> void:
	assert_true(WakeKinds.glows(_column([BlockIds.JACK_O_LANTERN])))
	assert_false(WakeKinds.glows(_column([BlockIds.PUMPKIN])))

# --- The chest mimic ---------------------------------------------------------------------------------------------


## It hops towards the child a step at a time, never closer than KEEP, never up or down a cliff.
func test_a_mimic_hops_after_you_but_keeps_a_little_space() -> void:
	var flat := func(_x: int, _z: int) -> float: return 10.0
	var at := Vector3(0.5, 10.0, 0.5)
	var child := Vector3(8.5, 10.0, 0.5)
	var hops := 0
	while hops < 20:
		var next := WakeKinds.mimic_hop(at, child, flat)
		if next == at:
			break
		assert_lte(Vector2(next.x - at.x, next.z - at.z).length(), WakeKinds.HOP_STEP + 0.001, "one small hop")
		at = next
		hops += 1
	assert_almost_eq(Vector2(child.x - at.x, child.z - at.z).length(), WakeKinds.KEEP, 0.3, "it stops beside you")
	assert_gt(hops, 3)
	var cliff := func(x: int, _z: int) -> float: return 10.0 if x < 2 else 14.0
	assert_eq(WakeKinds.mimic_hop(Vector3(1.5, 10.0, 0.5), child, cliff), Vector3(1.5, 10.0, 0.5), "never up a cliff")
	var none := func(_x: int, _z: int) -> float: return NAN
	assert_eq(WakeKinds.mimic_hop(Vector3(0.5, 10.0, 0.5), child, none), Vector3(0.5, 10.0, 0.5), "never into the unknown")
	var step := func(x: int, _z: int) -> float: return 10.0 if x < 2 else 11.0
	assert_eq(WakeKinds.mimic_hop(Vector3(1.5, 10.0, 0.5), child, step).y, 11.0, "a one-block step is a hop")


## A small present, the same for the same chest, never gold (spec §6); a different chest may give another.
func test_a_mimics_present_is_small_and_fixed() -> void:
	var seen := {}
	for key in 40:
		var gift := WakeKinds.mimic_present(key * 7919, 1)
		assert_eq(int(gift.get("gold", 0)), 0, "never gold")
		assert_eq((gift.items as Array).size(), 1)
		assert_eq(WakeKinds.mimic_present(key * 7919, 1), gift, "the same chest, the same present")
		var e: Array = gift.items[0]
		assert_between(int(e[1]), 1, 4, "small")
		assert_true(ItemIds.is_hotbar_valid(int(e[0])), ItemIds.display_name(int(e[0])))
		assert_false(LootRules.TREASURE_ONLY.has(int(e[0])), "never treasure")
		seen[int(e[0])] = true
	assert_gte(seen.size(), 3, "presents differ from chest to chest")


func test_a_mimic_is_never_scary() -> void:
	for line: String in [WakeKinds.MIMIC_WAKE, WakeKinds.MIMIC_PRESENT, WakeKinds.MIMIC_AGAIN, WakeKinds.MIMIC_CLOSED]:
		assert_ne(line, "")
		for word in ["bite", "eat", "attack", "scary", "monster", "hurt"]:
			assert_false(line.to_lower().contains(word), "%s: %s" % [word, line])
	assert_gt(WakeKinds.MIMIC_HOPS, 2)
	assert_between(WakeKinds.MAX_MIMICS, 1, 4)


## Where a hopping mimic lands in a column: on the floor next to its own level (a step up or down at most), never
## inside a wall, never in the air: NAN then (it stays).
func test_a_mimic_lands_on_the_floor_beside_it() -> void:
	var floor10 := func(c: Vector3i) -> bool: return c.y < 10
	assert_eq(WakeKinds.feet_near(3, 4, 10.0, floor10), 10.0)
	var step := func(c: Vector3i) -> bool: return c.y < 11
	assert_eq(WakeKinds.feet_near(3, 4, 10.0, step), 11.0, "a step up")
	var down := func(c: Vector3i) -> bool: return c.y < 9
	assert_eq(WakeKinds.feet_near(3, 4, 10.0, down), 9.0, "a step down")
	var wall := func(_c: Vector3i) -> bool: return true
	assert_true(is_nan(WakeKinds.feet_near(3, 4, 10.0, wall)), "never into a wall")
	var air := func(_c: Vector3i) -> bool: return false
	assert_true(is_nan(WakeKinds.feet_near(3, 4, 10.0, air)), "never over nothing")
