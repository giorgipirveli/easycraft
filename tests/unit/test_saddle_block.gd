extends GutTest
## M3 Task 20a: the SADDLE is a block on atlas page 10 (id 216), in both styles. Built into a buddy it makes
## the buddy rideable (RideRules); the wand wakes it like any build block. Sandbox: free in the palette's MAGIC
## row beside the wand. Survivor: bought from Tilly at a fixed price, × 2^(u−1) in universe u.


func test_the_saddle_is_a_block_on_page_10() -> void:
	assert_eq(BlockIds.SADDLE, 216)
	assert_eq(BlockLibrary.page_of(BlockIds.SADDLE), PortalPage.PAGE)
	assert_true(BlockIds.is_valid(BlockIds.SADDLE))
	assert_true(BlockIds.is_solid(BlockIds.SADDLE))
	assert_true(BlockIds.is_breakable(BlockIds.SADDLE))
	assert_eq(BlockIds.display_name(BlockIds.SADDLE), "Saddle")
	assert_false(ItemIds.is_item(BlockIds.SADDLE), "blocks and items share one id space")
	assert_gt(BlockIds.COUNT, BlockIds.SADDLE)
	assert_true(Inventory.ownable(BlockIds.SADDLE), "a bag can hold it")


func test_the_wand_wakes_a_build_with_a_saddle() -> void:
	assert_true(CaptureRules.is_capturable(BlockIds.SADDLE))
	var cells := {Vector3i(0, 0, 0): BlockIds.PLANKS, Vector3i(0, 1, 0): BlockIds.SADDLE}
	var got := CaptureRules.capture(Vector3i.ZERO, func(p: Vector3i) -> int: return cells.get(p, BlockIds.AIR))
	assert_eq((got.blocks as Dictionary).size(), 2, "the saddle comes along")


func test_its_tiles_are_on_the_page_in_both_styles() -> void:
	PortalPage.register()
	var tiles := BlockLibrary.tiles_of(BlockIds.SADDLE)
	assert_eq(tiles, [Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 2)], "two tiles per id: 2 × (216 − 208)")
	for id: int in PortalPage.TILES:
		if id != BlockIds.SADDLE:
			for t: Vector2i in (PortalPage.TILES[id] as Array).slice(0, 3):
				assert_false(t in tiles, "the saddle keeps off %s's tiles" % BlockIds.display_name(id))
	var pixel := Image.load_from_file(ProjectSettings.globalize_path(PortalPage.FILES[0]))   # the source files
	var albedo := Image.load_from_file(ProjectSettings.globalize_path(PortalPage.FILES[1]))
	for t: Vector2i in tiles:
		assert_gt(pixel.get_pixel(t.x * 16 + 8, t.y * 16 + 8).a, 0.9, "drawn in the pixel page %s" % t)
		var c := albedo.get_pixel(t.x * 256 + 128, t.y * 256 + 40)
		assert_gt(c.r, c.b, "brown leather in the realistic page %s" % t)


func test_every_world_has_it_with_the_pages_material() -> void:
	var lib := BlockLibrary.build()
	var m := lib.models[BlockIds.SADDLE] as VoxelBlockyModelCube
	assert_not_null(m)
	assert_false(m.collision_aabbs.is_empty(), "solid")
	assert_same(m.get_material_override(0), BlockLibrary.page_material(PortalPage.PAGE, &"opaque"))


func test_its_icon_comes_from_the_page() -> void:
	BlockLibrary.build()
	BlockIcons._cache.erase(BlockIds.SADDLE)
	var icon := BlockIcons.icon(BlockIds.SADDLE) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, PortalPage.FILES[0])


func test_tilly_sells_it_at_a_fixed_price_scaled_per_universe() -> void:
	assert_true(ShopRules.catalog(ShopRules.HOME).has(BlockIds.SADDLE))
	assert_eq(ShopRules.price(BlockIds.SADDLE), 60, "six minutes of paid flying")
	assert_eq(ShopRules.price(BlockIds.SADDLE, 3), 240, "× 2^(u−1)")
	assert_eq(ShopRules.amount(BlockIds.SADDLE), 1)
	assert_eq(ShopRules.sell_price(BlockIds.SADDLE), 0, "Tilly doesn't buy it back")


func test_give_knows_it() -> void:
	assert_eq(ChatCommands.item_for_name("saddle"), BlockIds.SADDLE)
