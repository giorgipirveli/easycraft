extends GutTest


func _blocks(ids: Array) -> Dictionary:
	var d := {}
	for i in ids.size():
		d[Vector3i(i, 0, 0)] = ids[i]
	return d


func _many(id: int, n: int) -> Dictionary:
	var d := {}
	for i in n:
		d[Vector3i(i % 10, i / 10, 0)] = id
	return d


func test_small_buddies_are_faster_than_huge_ones() -> void:
	var small := BuddyTraits.from_blocks(_many(BlockIds.RED, 4))
	var huge := BuddyTraits.from_blocks(_many(BlockIds.RED, 150))
	assert_gt(small.speed, huge.speed)
	assert_gt(small.hop, huge.hop)


func test_light_blocks_make_it_glow() -> void:
	assert_true(BuddyTraits.from_blocks(_blocks([BlockIds.RED, BlockIds.LIGHT])).glow)
	assert_false(BuddyTraits.from_blocks(_blocks([BlockIds.RED, BlockIds.BLUE])).glow)


func test_mostly_glass_floats_like_a_ghost() -> void:
	assert_true(BuddyTraits.from_blocks(_blocks([BlockIds.GLASS, BlockIds.GLASS, BlockIds.RED])).floaty)
	assert_false(BuddyTraits.from_blocks(_blocks([BlockIds.GLASS, BlockIds.RED, BlockIds.RED])).floaty)


func test_names_are_stable_and_friendly() -> void:
	var a := _blocks([BlockIds.RED, BlockIds.BLUE])
	assert_eq(BuddyNames.name_for(a), BuddyNames.name_for(a.duplicate()))
	assert_ne(BuddyNames.name_for(a), "")
	assert_ne(BuddyNames.name_for(a), BuddyNames.name_for(_blocks([BlockIds.GREEN, BlockIds.GREEN, BlockIds.LIGHT])))
