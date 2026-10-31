extends GutTest
## Io's agent (2026-09-29): page 21 (ids 384-399) was the last block page below the items' ids (400-499, ItemIds).
## Block pages go on from page 29 (ids 512-527 …); ids 400-511 stay the items'. However far BlockIds.COUNT grows past
## them, no item id is ever taken for a block: not solid, not placeable, not a saved block.


func test_items_are_never_blocks() -> void:
	for id: int in [ItemIds.GLIDER, ItemIds.TREAT_BISCUIT, ItemIds.GIFT_STAMP_FIRST, ItemIds.MY_STAMP_FIRST, 400, 511]:
		assert_true(BlockIds.is_reserved(id), "%d is the items'" % id)
		assert_false(BlockIds.is_block_id(id), "%d is not a block id" % id)
		assert_false(BlockIds.is_solid(id), "%d is not solid" % id)
		assert_false(BlockIds.is_valid(id), "%d can't be placed" % id)


func test_the_next_block_page_starts_past_the_items() -> void:
	assert_eq(BlockIds.RESERVED_FIRST, 400)
	assert_eq(BlockIds.RESERVED_END, 512)
	assert_eq(BlockLibrary.page_of(512), 29, "Titan's page (every later world's goes on from there) starts at id 512")
	assert_eq(BlockIds.NEXT_PAGE_FIRST_ID, 784,
		"where the next block page's ids begin (Titan took page 29, Mercury 30, the colony domes keep 31, missions 32, "
		+ "the wonders took 33-34, prospecting took 35, the New Seven Wonders took 36-37, Venus took 38, space's riches 39, "
		+ "Saturn's rings took 40, Pluto 41, Triton 42, Ganymede 43, the music blocks 44 (owner #110), the Glow Caves 45)")
	assert_eq(BlockLibrary.page_of(BlockIds.NEXT_PAGE_FIRST_ID), 46)
	assert_lte(BlockIds.COUNT, BlockIds.NEXT_PAGE_FIRST_ID, "no block past the next free page")


func test_real_blocks_are_block_ids() -> void:
	for id: int in [BlockIds.STONE, BlockIds.LAB_BENCH, BlockIds.EUROPA_ICE]:
		assert_true(BlockIds.is_block_id(id), str(id))
