extends GutTest
## M3 Task 5 (spec §14.2): the Portal Frame and the Portal Core are blocks on atlas page 10 (ids 208–223),
## in every world (Sandbox's palette, Tilly's shop in Survivor), drawn in both styles; the core glows. A
## hotbar slot or a bag holds block and item ids alike, so no block may take an item's id.


func test_the_portal_blocks_are_on_their_page() -> void:
	for id in [BlockIds.PORTAL_FRAME, BlockIds.PORTAL_CORE]:
		assert_eq(BlockLibrary.page_of(id), PortalPage.PAGE, BlockIds.display_name(id))
		assert_between(id, 208, 223)
		assert_true(BlockIds.PLACEABLE.has(id))
		assert_true(BlockIds.is_valid(id))
		assert_true(BlockIds.is_solid(id))
		assert_true(BlockIds.is_breakable(id))
	assert_eq(BlockIds.display_name(BlockIds.PORTAL_FRAME), "Portal Frame")
	assert_eq(BlockIds.display_name(BlockIds.PORTAL_CORE), "Portal Core")


func test_no_block_takes_an_item_id() -> void:
	for id in range(1, BlockIds.COUNT):
		if BlockIds.is_valid(id) or BlockIds.display_name(id) != "":
			assert_false(ItemIds.is_item(id), "block %d (%s) is also an item id" % [id, BlockIds.display_name(id)])


func test_every_world_has_them_with_their_page_material() -> void:
	var lib := BlockLibrary.build()
	for id in [BlockIds.PORTAL_FRAME, BlockIds.PORTAL_CORE]:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, BlockIds.display_name(id))
		assert_false(m.collision_aabbs.is_empty(), "solid")
	var frame_mat := (lib.models[BlockIds.PORTAL_FRAME] as VoxelBlockyModel).get_material_override(0)
	var core_mat := (lib.models[BlockIds.PORTAL_CORE] as VoxelBlockyModel).get_material_override(0) as BaseMaterial3D
	assert_same(frame_mat, BlockLibrary.page_material(PortalPage.PAGE, &"opaque"), "one material per page")
	assert_same(core_mat, BlockLibrary.page_material(PortalPage.PAGE, &"glow"))
	assert_eq(core_mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "the core glows")


func test_both_styles_share_the_pages_layout() -> void:
	var pixel := load(PortalPage.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for path: String in [PortalPage.FILES[1], PortalPage.FILES[2]]:
		assert_eq((load(path) as Texture2D).get_width(), 2048 if path == PortalPage.FILES[1] else 1024, path)   # M5 Task 3: normal maps at half size
	for id: int in PortalPage.all_tiles():   # the crafting table and the furnace too (spec §12.19)
		for t: Vector2i in (PortalPage.all_tiles()[id] as Array).slice(0, 3):
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t))
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	assert_eq(BlockLibrary.page_material(PortalPage.PAGE, &"opaque").albedo_texture.resource_path, PortalPage.FILES[1])
	BlockLibrary.set_style("blocky")
	assert_eq(BlockLibrary.page_material(PortalPage.PAGE, &"opaque").albedo_texture.resource_path, PortalPage.FILES[0])
	BlockLibrary.set_style(before)


func test_the_icons_come_from_the_page() -> void:
	BlockLibrary.build()
	BlockIcons._cache.erase(BlockIds.PORTAL_CORE)
	var icon := BlockIcons.icon(BlockIds.PORTAL_CORE) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, PortalPage.FILES[0])


func test_tilly_sells_frames_in_fours_and_cores() -> void:
	assert_true(ShopRules.catalog(ShopRules.HOME).has(BlockIds.PORTAL_FRAME))
	assert_true(ShopRules.catalog(ShopRules.HOME).has(BlockIds.PORTAL_CORE))
	assert_eq(ShopRules.amount(BlockIds.PORTAL_FRAME), 4)
	assert_eq(ShopRules.amount(BlockIds.PORTAL_CORE), 1)
	assert_gt(ShopRules.price(BlockIds.PORTAL_CORE), ShopRules.price(BlockIds.PORTAL_FRAME))
	assert_eq(ShopRules.sell_price(BlockIds.PORTAL_CORE), 0, "Tilly doesn't buy them back")


func test_give_names_blocks_only_where_items_share_the_ids() -> void:
	assert_eq(ChatCommands.item_for_name("portal core"), BlockIds.PORTAL_CORE)
	assert_eq(ChatCommands.item_for_name("crystal bow"), ItemIds.BOW_CRYSTAL, "128 is still the Crystal Bow")
	assert_eq(ChatCommands.giveable_ids().count(BlockIds.PORTAL_CORE), 1, "listed once")
