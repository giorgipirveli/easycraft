extends GutTest
## Owner #78 (spec §24), the second tour: the New Seven Wonders' blocks on block atlas pages 36 and 37 (ids 624-641;
## 642-655 are the third tour's), drawn in both styles (data/blocks/pages/wonders3*.png, wonders4*.png): the Great
## Wall's grey bricks, Petra's rose rock, its carved stone and columns, the Colosseum's travertine, Chichen Itza's Maya
## stone, its carved band, the serpent's head and the red jaguar throne, Machu Picchu's Inca stone, Christ the
## Redeemer's soapstone, the Taj Mahal's inlaid marble and its gate's red stone; five fake stones for the hidden rooms.

const ALL := [WondersBlocks.TILES_NEW, WondersBlocks.TILES_NEW_MORE]


func test_every_block_is_on_its_page_with_a_name() -> void:
	assert_eq(WondersBlocks.PAGE_NEW, 36)
	assert_eq(WondersBlocks.PAGE_NEW_MORE, 37)
	assert_eq(WondersBlocks.TILES_NEW.size() + WondersBlocks.TILES_NEW_MORE.size(), 18)
	for id: int in WondersBlocks.TILES_NEW:
		assert_between(id, 624, 639, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), 36, BlockIds.display_name(id))
	for id: int in WondersBlocks.TILES_NEW_MORE:
		assert_between(id, 640, 655, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), 37, BlockIds.display_name(id))
	for table: Dictionary in ALL:
		for id: int in table:
			assert_false(BlockIds.is_reserved(id))
			assert_true(BlockIds.is_valid(id), "%s can be placed" % BlockIds.display_name(id))
			assert_ne(BlockIds.display_name(id), "", "id %d has a name" % id)
			assert_false(ItemIds.is_item(id), "%d is no item's" % id)
	assert_gte(BlockIds.COUNT, 656, "past the New Seven's pages (Venus's 38 came next)")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 656)
	for id in range(642, 656):
		assert_true(WondersBlocks.TILES_NATURE.has(id), "id %d is the third tour's (test_wonders_nature_blocks)" % id)


func test_names_are_what_a_child_says() -> void:
	assert_eq(BlockIds.display_name(BlockIds.WALL_BRICK), "Wall Brick")
	assert_eq(BlockIds.display_name(BlockIds.ROSE_ROCK), "Rose Rock")
	assert_eq(BlockIds.display_name(BlockIds.TRAVERTINE), "Travertine")
	assert_eq(BlockIds.display_name(BlockIds.SERPENT_HEAD), "Serpent Head")
	assert_eq(BlockIds.display_name(BlockIds.JAGUAR_THRONE), "Jaguar Throne")
	assert_eq(BlockIds.display_name(BlockIds.INCA_STONE), "Inca Stone")
	assert_eq(BlockIds.display_name(BlockIds.SOAPSTONE), "Soapstone")
	assert_eq(BlockIds.display_name(BlockIds.INLAID_MARBLE), "Inlaid Marble")


func test_the_fake_stones_open_with_a_knock_and_look_like_their_stone() -> void:
	assert_eq(WondersBlocks.FAKES_NEW.size(), 5)
	for fake: int in WondersBlocks.FAKES_NEW:
		var real: int = WondersBlocks.FAKES_NEW[fake]
		assert_true(SecretRules.is_fake_wall(fake), BlockIds.display_name(fake))
		assert_false(SecretRules.is_fake_wall(real))
		assert_eq(BlockIds.display_name(fake), BlockIds.display_name(real), "a fake is named like its stone")
		assert_eq(GatherRules.DROPS.get(fake, -1), real, "breaks into its stone")
		assert_has(ChatCommands.NEVER_GIVEN, fake, "never given")
		assert_has(CaptureRules.GROUND, fake, "never captured")
	for fake: int in [BlockIds.FAKE_WALL_BRICK, BlockIds.FAKE_TRAVERTINE, BlockIds.FAKE_MAYA_STONE, BlockIds.FAKE_INCA_STONE]:
		var real: int = WondersBlocks.FAKES_NEW[fake]
		assert_eq(WondersBlocks.TILES_NEW[fake][0], WondersBlocks.TILES_NEW[real][0], "the same top")
	var white := (load(WondersBlocks.FILES_NEW_MORE[0]) as Texture2D).get_image()
	var theirs := (load(WondersBlocks.FILES_MORE[0]) as Texture2D).get_image()
	var mine := _mean(white, WondersBlocks.TILES_NEW_MORE[BlockIds.FAKE_WHITE_BRICK][0])
	var real_top := _mean(theirs, WondersBlocks.TILES_MORE[BlockIds.WHITE_BRICK][0])
	assert_almost_eq(mine.v, real_top.v, 0.03, "the fake white stone's top looks like white stone's")


func test_the_library_builds_each_block_with_its_pages_material() -> void:
	var lib := BlockLibrary.build()
	for page: int in [WondersBlocks.PAGE_NEW, WondersBlocks.PAGE_NEW_MORE]:
		var table: Dictionary = WondersBlocks.TILES_NEW if page == WondersBlocks.PAGE_NEW else WondersBlocks.TILES_NEW_MORE
		for id: int in table:
			var m: VoxelBlockyModel = lib.models[id]
			assert_true(m is VoxelBlockyModelCube, BlockIds.display_name(id))
			var kind: StringName = table[id][3]
			assert_same(m.get_material_override(0), BlockLibrary.page_material(page, kind), BlockIds.display_name(id))


func test_both_pictures_have_every_tile_drawn() -> void:
	for pair: Array in [[WondersBlocks.FILES_NEW, WondersBlocks.TILES_NEW, 3],
			[WondersBlocks.FILES_NEW_MORE, WondersBlocks.TILES_NEW_MORE, 4]]:   # (page 37's rows 1-3: the third tour's)
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
			for i in 3:
				var t: Vector2i = table[id][i]
				assert_lt(t.y, rows, "%s's tile %s is in the realistic page's rows" % [BlockIds.display_name(id), t])
				assert_gt(_mean(pixel, t).a, 0.9, "%s's tile %s is drawn" % [BlockIds.display_name(id), t])
				assert_gt(_mean_real(real, t).a, 0.9, "%s's realistic tile %s" % [BlockIds.display_name(id), t])


## Our own look (spec §3c), and what a child sees: the wall bricks grey, the rose rock rose-red, travertine cream, Maya
## stone pale grey, the jaguar throne red, Inca stone grey, soapstone pale, the inlaid marble white, the gate's stone red.
func test_each_block_looks_like_what_it_is() -> void:
	var pixel := (load(WondersBlocks.FILES_NEW[0]) as Texture2D).get_image()
	var wall := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.WALL_BRICK][1])
	assert_lt(wall.s, 0.2, "wall bricks are grey (%s)" % wall)
	var rose := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.ROSE_ROCK][1])
	assert_gt(rose.r, rose.b + 0.2, "Petra's rock is rose-red (%s)" % rose)
	var trav := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.TRAVERTINE][1])
	assert_gt(trav.v, 0.7, "travertine is pale cream (%s)" % trav)
	assert_gt(trav.r, trav.b, "a warm cream")
	var maya := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.MAYA_STONE][1])
	assert_gt(maya.v, 0.6, "Maya stone is pale (%s)" % maya)
	var jaguar := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.JAGUAR_THRONE][1])
	assert_gt(jaguar.r, jaguar.g + 0.25, "the jaguar is red (%s)" % jaguar)
	var inca := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.INCA_STONE][1])
	assert_lt(inca.s, 0.2, "Inca granite is grey (%s)" % inca)
	var soap := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.SOAPSTONE][1])
	assert_gt(soap.v, 0.65, "soapstone is pale (%s)" % soap)
	var inlay := _mean(pixel, WondersBlocks.TILES_NEW[BlockIds.INLAID_MARBLE][1])
	assert_gt(inlay.v, 0.8, "the Taj Mahal's marble is white (%s)" % inlay)
	var more := (load(WondersBlocks.FILES_NEW_MORE[0]) as Texture2D).get_image()
	var red := _mean(more, WondersBlocks.TILES_NEW_MORE[BlockIds.MUGHAL_RED][1])
	assert_gt(red.r, red.g + 0.2, "the gate's sandstone is red (%s)" % red)


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
