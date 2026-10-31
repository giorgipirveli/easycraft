extends GutTest
## Survivor's counted blocks and owned items (M2 §12.2).


func test_blocks_are_counted_added_and_taken() -> void:
	var inv := Inventory.new()
	assert_eq(inv.count(BlockIds.STONE), 0)
	assert_eq(inv.add(BlockIds.STONE, 5), 5)
	assert_true(inv.take(BlockIds.STONE, 3))
	assert_eq(inv.count(BlockIds.STONE), 2)
	assert_false(inv.take(BlockIds.STONE, 3), "not enough: nothing is taken")
	assert_eq(inv.count(BlockIds.STONE), 2)
	assert_true(inv.take(BlockIds.STONE, 2))
	assert_false(inv.has(BlockIds.STONE), "an empty count disappears")


func test_counts_cap_at_999() -> void:
	var inv := Inventory.new()
	inv.add(BlockIds.DIRT, 990)
	assert_eq(inv.add(BlockIds.DIRT, 20), 9, "only what fits is added")
	assert_eq(inv.count(BlockIds.DIRT), Inventory.MAX_COUNT)


func test_items_are_counted_the_same_way() -> void:
	var inv := Inventory.new()
	inv.add(ItemIds.SWORD, 1)
	inv.add(ItemIds.BULLSEYE, 2)
	assert_eq(inv.count(ItemIds.BULLSEYE), 2)
	assert_eq(inv.ids(), [ItemIds.SWORD, ItemIds.BULLSEYE] as Array[int], "in the order they came")


func test_bad_ids_and_amounts_are_refused() -> void:
	var inv := Inventory.new()
	assert_eq(inv.add(BlockIds.AIR, 3), 0, "air is nothing")
	assert_eq(inv.add(BlockIds.BEDROCK, 1), 0, "bedrock is never owned")
	assert_eq(inv.add(9999, 1), 0)
	assert_eq(inv.add(BlockIds.STONE, -4), 0)
	assert_false(inv.take(BlockIds.STONE, -1))


func test_save_round_trip_and_broken_saves() -> void:
	var inv := Inventory.new()
	inv.add(BlockIds.PLANKS, 16)
	inv.add(ItemIds.PICKAXE, 1)
	var back := Inventory.from_save(inv.to_save())
	assert_eq(back.count(BlockIds.PLANKS), 16)
	assert_eq(back.count(ItemIds.PICKAXE), 1)
	var broken := Inventory.from_save([[BlockIds.STONE, "x"], "junk", [BlockIds.BEDROCK, 3], [BlockIds.DIRT, 5000], [BlockIds.SAND, 2]])
	assert_eq(broken.ids(), [BlockIds.DIRT, BlockIds.SAND] as Array[int])
	assert_eq(broken.count(BlockIds.DIRT), Inventory.MAX_COUNT)


func test_the_starter_kit() -> void:
	var inv := Inventory.starter_kit()
	assert_eq(inv.count(ItemIds.SWORD), 1)
	assert_eq(inv.count(ItemIds.PICKAXE), 1)
	assert_eq(inv.count(BlockIds.PLANKS), 16)
	assert_eq(inv.count(BlockIds.DIRT), 8)
