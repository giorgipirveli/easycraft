extends GutTest
## M3 Task 21c: the wonder pack's blocks on block atlas page 14 (ids 272-275), drawn in both styles
## (data/blocks/pages/tiny.png and its realistic twin): the pumpkin and the glowing jack-o-lantern and the snowman's
## head (the Magic Wand wakes them: WakeKinds), and the mice's cheese (the mouse villages' tiny treasure only).


func test_every_block_is_on_page_14() -> void:
	assert_eq(TinyPage.PAGE, 14)
	assert_eq(BlockLibrary.page_of(272), 14)
	assert_eq(BlockLibrary.page_of(287), 14)
	for id: int in TinyPage.TILES:
		assert_between(id, 272, 287, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), TinyPage.PAGE, BlockIds.display_name(id))
	assert_eq([BlockIds.PUMPKIN, BlockIds.JACK_O_LANTERN, BlockIds.SNOWMAN_HEAD, BlockIds.CHEESE], [272, 273, 274, 275])
	assert_gte(BlockIds.COUNT, 276)


## Block ids go past 255 (the voxel type channel is 16-bit); no item may take one of page 14's.
func test_no_item_takes_a_page_14_id() -> void:
	for id in range(272, 288):
		assert_false(ItemIds.is_item(id), "%d is a block of page 14" % id)
		assert_false(ItemIds.is_gift_stamp(id), str(id))


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in TinyPage.TILES:
		var m := lib.models[id] as VoxelBlockyModel
		assert_not_null(m, "%s has a model" % BlockIds.display_name(id))
		assert_false(m is VoxelBlockyModelEmpty, BlockIds.display_name(id))
		var kind: StringName = TinyPage.TILES[id][3] if (TinyPage.TILES[id] as Array).size() > 3 else &"opaque"
		assert_same(m.get_material_override(0), BlockLibrary.page_material(TinyPage.PAGE, kind), BlockIds.display_name(id))
	assert_eq(BlockLibrary.tiles_of(BlockIds.PUMPKIN), (TinyPage.TILES[BlockIds.PUMPKIN] as Array).slice(0, 3))


func test_the_jack_o_lantern_glows_and_the_others_are_solid() -> void:
	assert_eq(TinyPage.TILES[BlockIds.JACK_O_LANTERN][3], &"glow")
	for id in [BlockIds.PUMPKIN, BlockIds.JACK_O_LANTERN, BlockIds.SNOWMAN_HEAD, BlockIds.CHEESE]:
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))


func test_tiles_stay_inside_the_8_by_8_page() -> void:
	for id: int in TinyPage.TILES:
		var t: Array = TinyPage.TILES[id]
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t[i]), "%s tile %d" % [BlockIds.display_name(id), i])


func test_both_styles_have_the_page_files() -> void:
	assert_eq(TinyPage.FILES, ["res://data/blocks/pages/tiny.png", "res://data/blocks/pages/tiny_albedo.png",
		"res://data/blocks/pages/tiny_normal.png"])
	var pixel := load(TinyPage.FILES[0]) as Texture2D
	assert_not_null(pixel)
	if pixel:
		assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for f: String in [TinyPage.FILES[1], TinyPage.FILES[2]]:
		var tex := load(f) as Texture2D
		assert_not_null(tex, f)
		if tex:
			assert_eq(tex.get_width(), 2048 if f == TinyPage.FILES[1] else 1024, "8 tiles of 256 px across (the normal map imported at half size; rows: test_page_sizes.gd): %s" % f)


func test_names_children_can_read() -> void:
	assert_eq(BlockIds.display_name(BlockIds.PUMPKIN), "Pumpkin")
	assert_eq(BlockIds.display_name(BlockIds.JACK_O_LANTERN), "Jack-o-Lantern")
	assert_eq(BlockIds.display_name(BlockIds.SNOWMAN_HEAD), "Snowman Head")
	assert_eq(BlockIds.display_name(BlockIds.CHEESE), "Tiny Cheese")
	assert_eq(ChatCommands.parse("/give pumpkin").get("id"), BlockIds.PUMPKIN)
	assert_eq(ChatCommands.parse("/give jack o lantern").get("id"), BlockIds.JACK_O_LANTERN)
	assert_eq(ChatCommands.parse("/give snowman head").get("id"), BlockIds.SNOWMAN_HEAD)


## The wand wakes what children build with them (the natural ground never).
func test_they_can_come_alive() -> void:
	for id in [BlockIds.PUMPKIN, BlockIds.JACK_O_LANTERN, BlockIds.SNOWMAN_HEAD, BlockIds.CHEESE]:
		assert_true(CaptureRules.is_capturable(id), BlockIds.display_name(id))


## The Sandbox palette's golden MAGIC row has the pumpkin, the jack-o-lantern and the snowman's head (things the
## wand wakes); Tilly sells them in Survivor (HOME).
func test_the_palette_and_tilly_have_them() -> void:
	for id in [BlockIds.PUMPKIN, BlockIds.JACK_O_LANTERN, BlockIds.SNOWMAN_HEAD]:
		assert_true(BlockPalette.MAGIC_BLOCKS.has(id), BlockIds.display_name(id))
		assert_gt(int(ShopRules.HOME_PRICES.get(id, 0)), 0, "Tilly sells %s" % BlockIds.display_name(id))
	assert_false(BlockPalette.MAGIC_BLOCKS.has(BlockIds.CHEESE), "the cheese is found, never picked")
	assert_false(ShopRules.HOME_PRICES.has(BlockIds.CHEESE), "never sold")


## The cheese is the mice's present: found in a mouse village's tiny chest, never given or sold (spec §6).
func test_the_cheese_is_treasure_only() -> void:
	assert_true(LootRules.TREASURE_ONLY.has(BlockIds.CHEESE))
	assert_false(ChatCommands.giveable_ids().has(BlockIds.CHEESE), "/give never hands it out")
	assert_eq(LootRules.rarity_of(BlockIds.CHEESE), LootRules.LEGENDARY, "treasure-only decorations glow gold")
