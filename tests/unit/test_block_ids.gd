extends GutTest


func test_placeable_blocks() -> void:
	assert_eq(BlockIds.PLACEABLE.size(), 35)   # + pads (M3 Task 6), hiding spots (M2 Task 5), defenses (M2 Task 8), portals (M3 Task 5), crafting table and furnace (§12.19)
	assert_false(BlockIds.PLACEABLE.has(BlockIds.AIR))
	assert_false(BlockIds.PLACEABLE.has(BlockIds.BEDROCK), "bedrock is never placeable")


func test_underground_blocks_are_placeable() -> void:
	for id in [BlockIds.DEEPSTONE, BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL]:
		assert_true(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_valid(id))
		assert_true(BlockIds.is_solid(id))


func test_bedrock_is_solid_but_never_placed_or_broken() -> void:
	assert_true(BlockIds.is_solid(BlockIds.BEDROCK))
	assert_false(BlockIds.is_valid(BlockIds.BEDROCK))
	assert_false(BlockIds.is_breakable(BlockIds.BEDROCK))
	assert_true(BlockIds.is_breakable(BlockIds.STONE))
	assert_true(BlockIds.is_breakable(BlockIds.DIAMOND))
	assert_eq(BlockIds.display_name(BlockIds.BEDROCK), "Bedrock")


func test_placeable_ids_are_unique() -> void:
	var seen := {}
	for id in BlockIds.PLACEABLE:
		assert_false(seen.has(id), "duplicate %d" % id)
		seen[id] = true


func test_every_block_has_a_name() -> void:
	for id in BlockIds.PLACEABLE:
		assert_ne(BlockIds.display_name(id), "", str(id))


func test_solidity() -> void:
	assert_false(BlockIds.is_solid(BlockIds.AIR))
	assert_false(BlockIds.is_solid(BlockIds.WATER))
	assert_true(BlockIds.is_solid(BlockIds.STONE))
	assert_true(BlockIds.is_solid(BlockIds.GLASS))


func test_validity() -> void:
	assert_true(BlockIds.is_valid(BlockIds.PURPLE))
	assert_false(BlockIds.is_valid(BlockIds.AIR), "air is not a placeable block")
	assert_false(BlockIds.is_valid(-1))
	assert_false(BlockIds.is_valid(999))


func test_bed_is_placeable_solid_and_breakable() -> void:
	assert_true(BlockIds.PLACEABLE.has(BlockIds.BED))
	assert_true(BlockIds.is_valid(BlockIds.BED))
	assert_true(BlockIds.is_solid(BlockIds.BED))
	assert_true(BlockIds.is_breakable(BlockIds.BED))
	assert_eq(BlockIds.display_name(BlockIds.BED), "Bed")


## M2 allocations (plan "Allocations"): doors, spike trap, lantern (Task 8), bush, barrel, closet
## (Task 5). An open door and a bush can be walked through.
func test_m2_blocks_are_allocated() -> void:
	assert_eq([BlockIds.DOOR, BlockIds.DOOR_OPEN, BlockIds.SPIKE_TRAP, BlockIds.LANTERN, BlockIds.BUSH,
		BlockIds.BARREL, BlockIds.CLOSET], [25, 26, 27, 28, 29, 30, 31])
	assert_gte(BlockIds.COUNT, 38, "M2 Task 16 adds 32..35, M3 Task 6 36..37; M3 pages go on past 64")
	for id in range(BlockIds.DOOR, BlockIds.CLOSET + 1):
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), str(id))
		assert_true(BlockIds.is_breakable(id), str(id))
	assert_false(BlockIds.is_solid(BlockIds.DOOR_OPEN), "walk through an open door")
	assert_false(BlockIds.is_solid(BlockIds.BUSH), "walk into a bush to hide")
	assert_true(BlockIds.is_solid(BlockIds.DOOR))
	assert_true(BlockIds.is_solid(BlockIds.BARREL))


## M2 Task 16 (secrets): the fake wall, the temple's pressure plates and two decorations that exist only
## in treasure, so none of them is in the Sandbox palette.
func test_secret_blocks_are_allocated_and_never_in_the_palette() -> void:
	assert_eq([BlockIds.FAKE_WALL, BlockIds.PRESSURE_PLATE, BlockIds.TROPHY, BlockIds.GOLD_LAMP], [32, 33, 34, 35])
	for id in [BlockIds.FAKE_WALL, BlockIds.PRESSURE_PLATE, BlockIds.TROPHY, BlockIds.GOLD_LAMP]:
		assert_false(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_valid(id), "a found decoration can sit in a hotbar: %s" % BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.FAKE_WALL), "Stone", "a fake wall is named like the stone it hides in")
	assert_eq(BlockIds.display_name(BlockIds.TROPHY), "Golden Trophy")
	assert_eq(BlockIds.display_name(BlockIds.GOLD_LAMP), "Golden Lamp")

## M3 Task 6 (Physics Lab): jump and speed pads are solid, placeable, breakable blocks. Ids 36 and 37
## until M3 Task 1's block pages (then 128-135); 32-35 belong to M2 Task 16.
func test_pads_are_placeable_blocks() -> void:
	assert_eq([BlockIds.JUMP_PAD, BlockIds.SPEED_PAD], [36, 37])
	assert_gte(BlockIds.COUNT, 38)
	for id in [BlockIds.JUMP_PAD, BlockIds.SPEED_PAD]:
		assert_true(BlockIds.PLACEABLE.has(id), str(id))
		assert_true(BlockIds.is_valid(id), str(id))
		assert_true(BlockIds.is_solid(id), str(id))
		assert_true(BlockIds.is_breakable(id), str(id))
	assert_eq(BlockIds.display_name(BlockIds.JUMP_PAD), "Jump Pad")
	assert_eq(BlockIds.display_name(BlockIds.SPEED_PAD), "Speed Pad")


## An id below COUNT that no block owns yet (a gap left for a task running in parallel) is never
## placed: the host refuses it.
func test_an_unowned_id_is_not_placeable() -> void:
	for id in range(1, BlockIds.COUNT):
		if BlockIds.display_name(id) == "":
			assert_false(BlockIds.is_valid(id), "id %d has no block yet" % id)

## M2 Task 5 (§12.5): the hiding spots can be placed (Tilly sells them; Sandbox has them in the
## palette). A bush is walked into; barrels and closets are solid (tap to hide inside).
func test_hiding_spots_are_placeable() -> void:
	for id in [BlockIds.BUSH, BlockIds.BARREL, BlockIds.CLOSET]:
		assert_true(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
	assert_false(BlockIds.is_solid(BlockIds.BUSH))
	assert_true(BlockIds.is_solid(BlockIds.CLOSET))

## M2 Task 8: doors, spike traps and lanterns join the palette; an open door is only ever made by
## opening a door (a tap), never picked.
func test_defense_blocks_are_placeable() -> void:
	for id in [BlockIds.DOOR, BlockIds.SPIKE_TRAP, BlockIds.LANTERN]:
		assert_true(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
	assert_false(BlockIds.PLACEABLE.has(BlockIds.DOOR_OPEN))
	assert_true(BlockIds.is_solid(BlockIds.SPIKE_TRAP), "monsters stand on it")
	assert_true(BlockIds.is_solid(BlockIds.LANTERN))
