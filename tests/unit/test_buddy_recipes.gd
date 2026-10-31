extends GutTest
## Secret buddy shapes (M3 Task 20b, spec §14.21, research D1): a block pattern woken with the wand becomes a
## special buddy. Matching is tolerant (turned four ways, mirrored, one spare block) and near-misses stay plain.


## A build from recipe cells ([pos, class]): each cell takes the class's block number `pick` (wrapping).
func _build(cells: Array, pick: int = 0) -> Dictionary:
	var out := {}
	for c: Array in cells:
		var ids: Array = BuddyRecipes.CLASSES[c[1]] if c[1] != BuddyRecipes.ANY else [BlockIds.PLANKS, BlockIds.RED]
		out[c[0]] = ids[pick % ids.size()]
	return _normalised(out)


## Blocks moved so the lowest corner is at 0 (like a captured buddy).
func _normalised(blocks: Dictionary) -> Dictionary:
	var lo := Vector3i(1 << 20, 1 << 20, 1 << 20)
	for p: Vector3i in blocks:
		lo = Vector3i(mini(lo.x, p.x), mini(lo.y, p.y), mini(lo.z, p.z))
	var out := {}
	for p: Vector3i in blocks:
		out[p - lo] = blocks[p]
	return out


## Turned a quarter `k` times about the up axis, and mirrored left to right.
func _turned(blocks: Dictionary, k: int, mirror: bool) -> Dictionary:
	var out := {}
	for p: Vector3i in blocks:
		var q := Vector3i(-p.x, p.y, p.z) if mirror else p
		for i in k:
			q = Vector3i(q.z, q.y, -q.x)
		out[q] = blocks[p]
	return _normalised(out)


func _recipe(id: StringName) -> Dictionary:
	return BuddyRecipes.recipe(id)


func test_there_are_eight_recipes_each_with_a_name_a_hint_and_a_personality() -> void:
	assert_eq(BuddyRecipes.RECIPES.size(), 8)
	var ids := {}
	for r: Dictionary in BuddyRecipes.RECIPES:
		assert_false(ids.has(r.id), "unique ids")
		ids[r.id] = true
		assert_ne(str(r.name), "", str(r.id))
		assert_ne(str(r.title), "", str(r.id))
		assert_gt(str(r.hint).length(), 10, "a riddle in a few words: %s" % r.id)
		assert_true(BuddyRecipes.ACTS.has(r.act), "a known personality: %s" % r.id)
		assert_gt(float(r.every), 1.0, "it acts now and then, not every frame")
		assert_gte((r.cells as Array).size(), 3)
	for want: StringName in [&"snowman", &"robot", &"flower_pot", &"castle", &"lighthouse", &"pup", &"caterpillar",
			&"fairy"]:
		assert_true(ids.has(want), str(want))


func test_every_recipe_matches_its_own_shape_and_nothing_else() -> void:
	for r: Dictionary in BuddyRecipes.RECIPES:
		var b := _build(r.cells)
		assert_eq(BuddyRecipes.match_blocks(b), r.id, str(r.id))
		for other: Dictionary in BuddyRecipes.RECIPES:
			if other.id != r.id:
				assert_false(BuddyRecipes.matches(other, b), "%s is not a %s" % [r.id, other.id])


func test_any_block_of_a_class_counts() -> void:
	for r: Dictionary in BuddyRecipes.RECIPES:
		for pick in 4:
			assert_eq(BuddyRecipes.match_blocks(_build(r.cells, pick)), r.id, "%s with blocks %d" % [r.id, pick])


func test_every_recipe_matches_turned_and_mirrored() -> void:
	for r: Dictionary in BuddyRecipes.RECIPES:
		var b := _build(r.cells)
		for k in 4:
			for mirror in [false, true]:
				assert_eq(BuddyRecipes.match_blocks(_turned(b, k, mirror)), r.id, "%s turned %d mirror %s" % [r.id, k, mirror])


func test_one_spare_block_is_fine_but_two_are_not() -> void:
	var cells: Array = _recipe(&"snowman").cells
	var b := _build(cells)
	b[Vector3i(0, 3, 0)] = BlockIds.PAINTED_BLACK            # a hat on the head
	assert_eq(BuddyRecipes.match_blocks(b), &"snowman", "one spare block: still a snowman")
	b[Vector3i(0, 1, 1)] = BlockIds.PLANKS                    # and an arm
	assert_eq(BuddyRecipes.match_blocks(b), &"", "two spare blocks: a plain buddy")


func test_the_snowmans_near_misses_stay_plain() -> void:
	var w := BlockIds.PAINTED_WHITE
	var nose := BlockIds.PAINTED_ORANGE
	var right := {Vector3i(0, 0, 0): w, Vector3i(0, 1, 0): w, Vector3i(0, 2, 0): w, Vector3i(1, 2, 0): nose}
	assert_eq(BuddyRecipes.match_blocks(right), &"snowman")
	var blue_nose := right.duplicate()
	blue_nose[Vector3i(1, 2, 0)] = BlockIds.BLUE
	assert_eq(BuddyRecipes.match_blocks(blue_nose), &"", "a blue nose is no carrot")
	var no_nose := {Vector3i(0, 0, 0): w, Vector3i(0, 1, 0): w, Vector3i(0, 2, 0): w}
	assert_eq(BuddyRecipes.match_blocks(no_nose), &"", "no nose")
	var low_nose := {Vector3i(0, 0, 0): w, Vector3i(0, 1, 0): w, Vector3i(0, 2, 0): w, Vector3i(1, 0, 0): nose}
	assert_eq(BuddyRecipes.match_blocks(low_nose), &"", "the nose goes on the head, not the feet (upside down)")
	var short := {Vector3i(0, 0, 0): w, Vector3i(0, 1, 0): w, Vector3i(1, 1, 0): nose}
	assert_eq(BuddyRecipes.match_blocks(short), &"", "two white blocks are too short")
	var brown := {Vector3i(0, 0, 0): BlockIds.PLANKS, Vector3i(0, 1, 0): w, Vector3i(0, 2, 0): w, Vector3i(1, 2, 0): nose}
	assert_eq(BuddyRecipes.match_blocks(brown), &"", "a wooden bottom is no snow")


func test_other_near_misses_stay_plain() -> void:
	var castle := _build(_recipe(&"castle").cells)
	castle.erase(castle.keys().filter(func(p: Vector3i) -> bool: return p.y == 1)[0])   # a corner tower gone
	assert_eq(BuddyRecipes.match_blocks(castle), &"", "a castle needs all four towers")
	var worm := {Vector3i(0, 0, 0): BlockIds.RED, Vector3i(1, 0, 0): BlockIds.GREEN, Vector3i(2, 0, 0): BlockIds.YELLOW,
		Vector3i(3, 0, 0): BlockIds.BLUE, Vector3i(4, 0, 0): BlockIds.PURPLE}
	assert_eq(BuddyRecipes.match_blocks(worm), &"", "the rainbow's colours out of order")
	var robot := {Vector3i(0, 0, 0): BlockIds.PAINTED_SILVER, Vector3i(0, 1, 0): BlockIds.PAINTED_SILVER,
		Vector3i(0, 2, 0): BlockIds.LANTERN}
	assert_eq(BuddyRecipes.match_blocks(robot), &"", "a robot needs its arms")
	var standing_worm := {}
	for y in 5:
		standing_worm[Vector3i(0, y, 0)] = [BlockIds.RED, BlockIds.YELLOW, BlockIds.GREEN, BlockIds.BLUE, BlockIds.PURPLE][y]
	assert_eq(BuddyRecipes.match_blocks(standing_worm), &"", "never tipped on its end: only turned about the up axis")


func test_big_builds_are_plain_buddies() -> void:
	var b := {}
	for x in 6:
		for y in 6:
			for z in 5:
				b[Vector3i(x, y, z)] = BlockIds.PAINTED_WHITE
	assert_eq(BuddyRecipes.match_blocks(b), &"")
	assert_eq(BuddyRecipes.match_blocks({}), &"")


func test_every_recipe_block_can_be_woken_by_the_wand() -> void:
	for cls: StringName in BuddyRecipes.CLASSES:
		for id: int in BuddyRecipes.CLASSES[cls]:
			assert_true(CaptureRules.is_capturable(id), "%s: %s" % [cls, BlockIds.display_name(id)])


func test_the_silhouette_is_the_front_view_of_the_shape() -> void:
	var s := BuddyRecipes.silhouette(&"snowman")
	assert_eq(s.w, 2)
	assert_eq(s.h, 3)
	assert_eq((s.cells as Array).size(), 6)
	assert_eq(s.cells[0], BuddyRecipes.WHITE, "the head, top left")
	assert_eq(s.cells[1], BuddyRecipes.NOSE, "the carrot nose sticks out")
	assert_eq(s.cells[3], &"", "nothing beside the body")
	assert_eq(s.cells[4], BuddyRecipes.WHITE, "the feet, bottom left")
	var castle := BuddyRecipes.silhouette(&"castle")
	assert_eq([castle.w, castle.h], [3, 2])
	assert_eq(castle.cells, [BuddyRecipes.WALL, &"", BuddyRecipes.WALL, BuddyRecipes.WALL, BuddyRecipes.WALL, BuddyRecipes.WALL])


func test_a_class_shows_as_its_first_block() -> void:
	assert_eq(BuddyRecipes.block_of(BuddyRecipes.WHITE), BuddyRecipes.CLASSES[BuddyRecipes.WHITE][0])
	assert_eq(BuddyRecipes.block_of(BuddyRecipes.ANY), BlockIds.PLANKS)
	assert_eq(BuddyRecipes.block_of(&""), BlockIds.AIR)


func test_unknown_ids_are_no_recipe() -> void:
	assert_true(BuddyRecipes.recipe(&"nope").is_empty())
	assert_true(BuddyRecipes.is_recipe(&"snowman"))
	assert_false(BuddyRecipes.is_recipe(&""))
