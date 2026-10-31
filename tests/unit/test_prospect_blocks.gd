extends GutTest
## Prospecting on Earth (owner #80, spec §26): the riches' blocks on block atlas page 35 (ids 608-623), drawn in both
## styles (data/blocks/pages/prospect.png and its realistic twin): gold quartz, gold gravel, copper ore, malachite (the
## copper's green stain), banded iron, rusty rock (the iron's sign), fern shale (the coal's sign), an oil seep, rock salt,
## a salt crust, and what refining makes: copper, table salt, drums of crude oil and kerosene, plastic, and the refinery.
## Page 31 (ids 544-559) was held for the colony domes; the colonies (spec §21c) have it now (owner #78's wonders took
## pages 33-34 and 36-37).


func test_every_block_is_on_page_35() -> void:
	assert_eq(ProspectPage.PAGE, 35)
	assert_eq(ProspectPage.TILES.size(), 16, "ten found in the ground, five refined, the refinery")
	for id: int in ProspectPage.TILES:
		assert_between(id, 608, 623, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), ProspectPage.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id))
		assert_true(BlockIds.is_valid(id), "%s can be placed" % BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s is solid" % BlockIds.display_name(id))
		assert_ne(BlockIds.display_name(id), "", "id %d has a name" % id)
		assert_false(ItemIds.is_item(id), "%d is no item's" % id)
	assert_gte(BlockIds.COUNT, 672, "past the riches' page: the New Seven Wonders' 36-37, Venus's 38, and on")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 672)
	assert_eq(BlockLibrary.page_of(624), 36, "the riches' page is followed by page 36")


## The page held for the domes is the colonies' now (the wonders' second tour, 2026-09-30: the colonies were merged
## after this test was written; every block there is ColonyBlocks').
func test_the_held_page_is_the_colony_domes_now() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	assert_eq(BlockLibrary.page_of(544), 31)
	assert_eq(ColonyBlocks.PAGE, 31)
	for id: int in ColonyBlocks.TILES:
		assert_between(id, 544, 559, BlockIds.display_name(id))
		assert_true(BlockIds.is_valid(id), "%s is the colonies'" % BlockIds.display_name(id))


func test_the_library_builds_each_block_with_its_pages_material() -> void:
	var lib := BlockLibrary.build()
	for id: int in ProspectPage.TILES:
		var m: VoxelBlockyModel = lib.models[id]
		assert_true(m is VoxelBlockyModelCube, BlockIds.display_name(id))
		var kind: StringName = ProspectPage.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(ProspectPage.PAGE, kind), BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(ProspectPage.TILES[id][i]))


func test_both_pictures_have_every_tile_drawn() -> void:
	var pixel := (load(ProspectPage.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128))
	var real := (load(ProspectPage.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	var normal := (load(ProspectPage.FILES[2]) as Texture2D).get_image()
	assert_eq(real.get_width(), 2048)
	assert_eq(normal.get_width(), 1024, "the normal map is imported at half size (M5 Task 3)")
	var rows := BlockLibrary.texture_rows(load(ProspectPage.FILES[1]) as Texture2D)
	assert_eq(rows, 4, "the page draws four rows")
	for id: int in ProspectPage.TILES:
		for i in 3:
			var t: Vector2i = ProspectPage.TILES[id][i]
			assert_lt(t.y, rows, "%s's tile %s is in the realistic page's rows" % [BlockIds.display_name(id), t])
			assert_gt(_mean(pixel, t).a, 0.9, "%s's tile %s is drawn" % [BlockIds.display_name(id), t])
			var r := _mean_real(real, t)
			assert_gt(r.a, 0.9, "%s's realistic tile %s is drawn" % [BlockIds.display_name(id), t])


## Our own look (spec §3c), and what a child learns to read: the quartz is white with gold, malachite green, rusty rock
## red-brown, the oil seep near black, the salt crust white, kerosene's drum blue, crude oil's black.
func test_each_block_looks_like_what_it_is() -> void:
	var pixel := (load(ProspectPage.FILES[0]) as Texture2D).get_image()
	var quartz := _mean(pixel, ProspectPage.TILES[BlockIds.GOLD_QUARTZ][1])
	assert_gt(quartz.v, 0.7, "quartz is light (%s)" % quartz)
	assert_true(_has_gold(pixel, ProspectPage.TILES[BlockIds.GOLD_QUARTZ][1]), "gold specks in the quartz")
	assert_true(_has_gold(pixel, ProspectPage.TILES[BlockIds.GOLD_GRAVEL][0]), "gold flakes in the gravel")
	var green := _mean(pixel, ProspectPage.TILES[BlockIds.MALACHITE][1])
	assert_gt(green.g, green.r + 0.1, "malachite is green (%s)" % green)
	var rust := _mean(pixel, ProspectPage.TILES[BlockIds.RUSTY_ROCK][0])
	assert_gt(rust.r, rust.b + 0.2, "rusty rock is red-brown (%s)" % rust)
	var seep := _mean(pixel, ProspectPage.TILES[BlockIds.OIL_SEEP][0])
	assert_lt(seep.v, 0.3, "an oil seep is near black (%s)" % seep)
	var crust := _mean(pixel, ProspectPage.TILES[BlockIds.SALT_CRUST][0])
	assert_gt(crust.v, 0.85, "a salt crust is white (%s)" % crust)
	assert_lt(crust.s, 0.15)
	var kerosene := _mean(pixel, ProspectPage.TILES[BlockIds.KEROSENE][1])
	assert_gt(kerosene.b, kerosene.r + 0.15, "kerosene's drum is blue (%s)" % kerosene)
	var crude := _mean(pixel, ProspectPage.TILES[BlockIds.CRUDE_OIL][1])
	assert_lt(crude.v, 0.35, "crude oil's drum is dark (%s)" % crude)
	var copper := _mean(pixel, ProspectPage.TILES[BlockIds.COPPER][1])
	assert_gt(copper.r, copper.b + 0.25, "copper is orange (%s)" % copper)


func test_names_are_what_a_child_says() -> void:
	assert_eq(BlockIds.display_name(BlockIds.GOLD_QUARTZ), "Gold Quartz")
	assert_eq(BlockIds.display_name(BlockIds.OIL_SEEP), "Oil Seep")
	assert_eq(BlockIds.display_name(BlockIds.KEROSENE), "Kerosene")
	assert_eq(BlockIds.display_name(BlockIds.REFINERY), "Refinery")


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


func _has_gold(img: Image, t: Vector2i) -> bool:
	for y in 16:
		for x in 16:
			var c := img.get_pixel(t.x * 16 + x, t.y * 16 + y)
			if c.r > 0.85 and c.g > 0.6 and c.b < 0.4:
				return true
	return false


## The riches found in the ground are the world's own (the wand never wakes them, bots' builds may lean on them); what
## refining makes, and the Refinery, are a child's.
func test_the_found_blocks_are_the_worlds_own_ground() -> void:
	for id in ProspectPage.FOUND:
		assert_false(CaptureRules.is_capturable(id), "%s is ground" % BlockIds.display_name(id))
		assert_has(BotRules.NATURAL, id)
	for id in ProspectPage.REFINED + [BlockIds.REFINERY]:
		if id == BlockIds.CRUDE_OIL or id == BlockIds.REFINERY or ProspectPage.REFINED.has(id):
			assert_true(CaptureRules.is_capturable(id), "%s is built" % BlockIds.display_name(id))
			assert_does_not_have(BotRules.NATURAL, id)
