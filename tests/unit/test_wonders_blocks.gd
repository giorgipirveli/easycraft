extends GutTest
## Owner #78 (spec §24): the world's wonders' blocks on block atlas pages 33 and 34 (ids 576-597; 598-607 free for the
## next tours), drawn in both styles (data/blocks/pages/wonders*.png and their realistic twins): the pyramid's limestone,
## its white casing and pink granite; marble, a fluted column, its scrolled top and a carved band; bronze, ivory, gold
## leaf and ebony; Babylon's yellow and blue glazed bricks; the Lighthouse's fire and white stone, the tour's paving, the
## wonder plaque, the water screw and olive leaves; three fake stones for the hidden rooms.

const ALL := [WondersBlocks.TILES, WondersBlocks.TILES_MORE]


func test_every_block_is_on_its_page_with_a_name() -> void:
	assert_eq(WondersBlocks.PAGE, 33)
	assert_eq(WondersBlocks.PAGE_MORE, 34)
	assert_eq(WondersBlocks.TILES.size() + WondersBlocks.TILES_MORE.size(), 22)
	for id: int in WondersBlocks.TILES:
		assert_between(id, 576, 591, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), 33, BlockIds.display_name(id))
	for id: int in WondersBlocks.TILES_MORE:
		assert_between(id, 592, 607, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), 34, BlockIds.display_name(id))
	for table: Dictionary in ALL:
		for id: int in table:
			assert_false(BlockIds.is_reserved(id))
			assert_true(BlockIds.is_valid(id), "%s can be placed" % BlockIds.display_name(id))
			assert_ne(BlockIds.display_name(id), "", "id %d has a name" % id)
			assert_false(ItemIds.is_item(id), "%d is no item's" % id)
	assert_gte(BlockIds.COUNT, 656, "past the New Seven Wonders' pages 36-37 (owner #78's second tour; 38 is Venus's)")
	for id in range(598, 608):
		assert_false(BlockIds.is_valid(id), "id %d is free for the next tour" % id)


func test_names_are_what_a_child_says() -> void:
	assert_eq(BlockIds.display_name(BlockIds.LIMESTONE), "Limestone")
	assert_eq(BlockIds.display_name(BlockIds.GRANITE), "Granite")
	assert_eq(BlockIds.display_name(BlockIds.MARBLE_COLUMN), "Marble Column")
	assert_eq(BlockIds.display_name(BlockIds.BRONZE), "Bronze")
	assert_eq(BlockIds.display_name(BlockIds.WONDER_PLAQUE), "Wonder Plaque")
	assert_eq(BlockIds.display_name(BlockIds.SCREW_PUMP), "Water Screw")


func test_the_fake_stones_open_with_a_knock_and_look_like_their_stone() -> void:
	for fake: int in WondersBlocks.FAKES:
		var real: int = WondersBlocks.FAKES[fake]
		assert_true(SecretRules.is_fake_wall(fake), BlockIds.display_name(fake))
		assert_false(SecretRules.is_fake_wall(real))
		assert_eq(BlockIds.display_name(fake), BlockIds.display_name(real), "a fake is named like its stone")
		assert_eq(WondersBlocks.TILES[fake][0], WondersBlocks.TILES[real][0], "the same top")
		assert_eq(GatherRules.DROPS.get(fake, -1), real, "breaks into its stone")
		assert_has(ChatCommands.NEVER_GIVEN, fake, "never given")


func test_the_glowing_and_cut_out_blocks() -> void:
	assert_eq(WondersBlocks.TILES_MORE[BlockIds.BEACON_FIRE][3], &"glow", "the Lighthouse's fire glows")
	assert_eq(WondersBlocks.TILES_MORE[BlockIds.OLIVE_LEAVES][3], &"cutout", "leaves have gaps")
	assert_true(BlockIds.is_solid(BlockIds.WONDER_PLAQUE))


func test_the_library_builds_each_block_with_its_pages_material() -> void:
	var lib := BlockLibrary.build()
	for page: int in [WondersBlocks.PAGE, WondersBlocks.PAGE_MORE]:
		var table: Dictionary = WondersBlocks.TILES if page == WondersBlocks.PAGE else WondersBlocks.TILES_MORE
		for id: int in table:
			var m: VoxelBlockyModel = lib.models[id]
			assert_true(m is VoxelBlockyModelCube, BlockIds.display_name(id))
			# its kind's material, or the sway material of its leaves (the visuals brief, test_look_sway.gd)
			assert_same(m.get_material_override(0), BlockLibrary.block_material(page, table[id]), BlockIds.display_name(id))


func test_both_pictures_have_every_tile_drawn() -> void:
	for pair: Array in [[WondersBlocks.FILES, WondersBlocks.TILES, 3], [WondersBlocks.FILES_MORE, WondersBlocks.TILES_MORE, 2]]:
		var files: Array = pair[0]
		var table: Dictionary = pair[1]
		var pixel := (load(files[0]) as Texture2D).get_image()
		assert_eq(pixel.get_size(), Vector2i(128, 128))
		var real := (load(files[1]) as Texture2D).get_image()
		if real.is_compressed():
			real.decompress()
		assert_eq(real.get_width(), 2048)
		var normal := (load(files[2]) as Texture2D).get_image()
		assert_eq(normal.get_width(), 1024, "the normal map is imported at half size (M5 Task 3)")
		var rows := BlockLibrary.texture_rows(load(files[1]) as Texture2D)
		assert_eq(rows, int(pair[2]), "the page's rows")
		for id: int in table:
			var cut: bool = table[id][3] == &"cutout"
			for i in 3:
				var t: Vector2i = table[id][i]
				assert_lt(t.y, rows, "%s's tile %s is in the realistic page's rows" % [BlockIds.display_name(id), t])
				assert_gt(_mean(pixel, t).a, 0.25 if cut else 0.9, "%s's tile %s is drawn" % [BlockIds.display_name(id), t])
				assert_gt(_mean_real(real, t).a, 0.25 if cut else 0.9, "%s's realistic tile %s" % [BlockIds.display_name(id), t])


## Our own look (spec §3c), and what a child sees: limestone golden, casing and marble white, granite pink, bronze
## golden-brown, gold bright, ebony near black, the glazed bricks blue, the fire orange.
func test_each_block_looks_like_what_it_is() -> void:
	var pixel := (load(WondersBlocks.FILES[0]) as Texture2D).get_image()
	var lime := _mean(pixel, WondersBlocks.TILES[BlockIds.LIMESTONE][1])
	assert_gt(lime.r, lime.b + 0.15, "limestone is golden (%s)" % lime)
	var casing := _mean(pixel, WondersBlocks.TILES[BlockIds.CASING_STONE][1])
	assert_gt(casing.v, 0.85, "the casing is white (%s)" % casing)
	var marble := _mean(pixel, WondersBlocks.TILES[BlockIds.MARBLE][1])
	assert_gt(marble.v, 0.85, "marble is white (%s)" % marble)
	assert_lt(marble.s, 0.1)
	var granite := _mean(pixel, WondersBlocks.TILES[BlockIds.GRANITE][1])
	assert_gt(granite.r, granite.g + 0.1, "granite is pink-red (%s)" % granite)
	var bronze := _mean(pixel, WondersBlocks.TILES[BlockIds.BRONZE][1])
	assert_gt(bronze.r, bronze.b + 0.3, "bronze is golden-brown (%s)" % bronze)
	var gold := _mean(pixel, WondersBlocks.TILES[BlockIds.GOLD_LEAF][1])
	assert_gt(gold.r, 0.8, "gold is bright (%s)" % gold)
	var ebony := _mean(pixel, WondersBlocks.TILES[BlockIds.EBONY][1])
	assert_lt(ebony.v, 0.3, "ebony is near black (%s)" % ebony)
	var glaze := _mean(pixel, WondersBlocks.TILES[BlockIds.GLAZED_BRICK][1])
	assert_gt(glaze.b, glaze.r + 0.3, "glazed bricks are blue (%s)" % glaze)
	var more := (load(WondersBlocks.FILES_MORE[0]) as Texture2D).get_image()
	var fire := _mean(more, WondersBlocks.TILES_MORE[BlockIds.BEACON_FIRE][1])
	assert_gt(fire.r, fire.b + 0.5, "the fire is orange (%s)" % fire)


func _mean(img: Image, t: Vector2i) -> Color:
	var sum := Color(0, 0, 0, 0)
	for y in 16:
		for x in 16:
			sum += img.get_pixel(t.x * 16 + x, t.y * 16 + y)
	return sum / 256.0


func _mean_real(img: Image, t: Vector2i) -> Color:
	var cell := img.get_width() / 8
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for y in range(8, cell - 8, 16):
		for x in range(8, cell - 8, 16):
			sum += img.get_pixel(t.x * cell + x, t.y * cell + y)
			n += 1
	return sum / float(n)
