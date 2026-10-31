extends GutTest
## M3 Task 21b: two blocks on atlas page 10 — the TROPHY SHELF (217), an open cabinet whose shelves show the world
## owner's badges, and the BOOKSHELF (218), whose tap opens the books. Both styles, Tilly's HOME, the palette's
## SMART page (a HOME row), /give; never painted.


func test_the_ids_are_the_allocated_ones() -> void:
	assert_eq(BlockIds.TROPHY_SHELF, 217)
	assert_eq(BlockIds.BOOKSHELF, 218)
	for id in [BlockIds.TROPHY_SHELF, BlockIds.BOOKSHELF]:
		assert_eq(BlockLibrary.page_of(id), PortalPage.PAGE)
		assert_true(BlockIds.is_valid(id))
		assert_true(BlockIds.is_solid(id), "you can't walk through a shelf")
		assert_false(ItemIds.is_item(id), "blocks and items share one id space")
		assert_true(Inventory.ownable(id))
		assert_false(PaintRules.paintable(id), "a block with a job is never painted")
		assert_false(BlockIds.PLACEABLE.has(id), "in the SMART page's HOME row, not the block grid")
		assert_has(BlockPalette.HOME_BLOCKS, id)
	assert_eq(BlockIds.display_name(BlockIds.TROPHY_SHELF), "Trophy Shelf")
	assert_eq(BlockIds.display_name(BlockIds.BOOKSHELF), "Bookshelf")


func test_their_tiles_are_their_own_in_both_styles() -> void:
	PortalPage.register()
	var shelf := BlockLibrary.tiles_of(BlockIds.TROPHY_SHELF)
	var books := BlockLibrary.tiles_of(BlockIds.BOOKSHELF)
	assert_eq(shelf, [Vector2i(3, 2), Vector2i(2, 2), Vector2i(3, 2)], "tiles 2 × (217 − 208): side (2, 2), top (3, 2)")
	assert_eq(books, [Vector2i(5, 2), Vector2i(4, 2), Vector2i(5, 2)], "tiles 2 × (218 − 208)")
	var all := PortalPage.all_tiles()
	for id: int in all:
		if id in [BlockIds.TROPHY_SHELF, BlockIds.BOOKSHELF]:
			continue
		for t: Vector2i in (all[id] as Array).slice(0, 3):
			assert_false(t in shelf or t in books, "keeps off %s's tiles" % BlockIds.display_name(id))
	var pixel := Image.load_from_file(ProjectSettings.globalize_path(PortalPage.FILES[0]))
	var albedo := Image.load_from_file(ProjectSettings.globalize_path(PortalPage.FILES[1]))
	for t: Vector2i in [Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)]:
		assert_gt(pixel.get_pixel(t.x * 16 + 8, t.y * 16 + 8).a, 0.9, "drawn, solid: %s" % t)
		assert_gt(albedo.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.9, "realistic, solid: %s" % t)
	# the trophy shelf's side: a wooden frame round two open shelves (see-through where the trophies stand)
	var side := Vector2i(2, 2)
	assert_gt(pixel.get_pixel(side.x * 16 + 0, side.y * 16 + 8).a, 0.9, "the frame's post")
	assert_lt(pixel.get_pixel(side.x * 16 + 8, side.y * 16 + 4).a, 0.5, "the upper opening")
	assert_lt(pixel.get_pixel(side.x * 16 + 8, side.y * 16 + 11).a, 0.5, "the lower opening")
	assert_lt(albedo.get_pixel(side.x * 256 + 128, side.y * 256 + 64).a, 0.5, "open in the realistic style too")
	assert_gt(albedo.get_pixel(side.x * 256 + 8, side.y * 256 + 128).a, 0.9)


func test_every_world_has_them() -> void:
	var lib := BlockLibrary.build()
	var shelf := lib.models[BlockIds.TROPHY_SHELF] as VoxelBlockyModelCube
	var books := lib.models[BlockIds.BOOKSHELF] as VoxelBlockyModelCube
	assert_not_null(shelf)
	assert_not_null(books)
	assert_false(shelf.collision_aabbs.is_empty(), "solid")
	assert_same(shelf.get_material_override(0), BlockLibrary.page_material(PortalPage.PAGE, &"cutout"), "see-through")
	assert_same(books.get_material_override(0), BlockLibrary.page_material(PortalPage.PAGE, &"opaque"))


func test_tilly_sells_them_and_give_knows_them() -> void:
	for id in [BlockIds.TROPHY_SHELF, BlockIds.BOOKSHELF]:
		assert_true(ShopRules.catalog(ShopRules.HOME).has(id))
		assert_gt(ShopRules.price(id), 0)
		assert_eq(ShopRules.price(id, 2), ShopRules.price(id) * 2, "× 2^(u−1)")
		assert_eq(ShopRules.sell_price(id), 0)
	assert_eq(ChatCommands.item_for_name("trophyshelf"), BlockIds.TROPHY_SHELF)
	assert_eq(ChatCommands.item_for_name("bookshelf"), BlockIds.BOOKSHELF)
