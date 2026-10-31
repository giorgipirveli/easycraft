extends GutTest
## Owner #110 (VR round 4, idea 7): the two music blocks, ids 752-753 on block atlas page 44 (754-767 kept for more
## instruments on it; the next page is 45), drawn in both styles by tools/make_music_page.gd: the xylophone's eight
## rainbow bars on a wooden frame, longer bars lower; the bongos' big and small skins on red shells. Solid cubes a child
## builds with anywhere: the Sandbox palette's HOME row, the Workbench in Survivor, never painted (a painted one would
## hide what it is).


func test_both_blocks_are_on_page_44() -> void:
	assert_eq(MusicPage.PAGE, 44)
	assert_eq(BlockIds.XYLOPHONE, 752)
	assert_eq(BlockIds.DRUM, 753)
	for id: int in [BlockIds.XYLOPHONE, BlockIds.DRUM]:
		assert_eq(BlockLibrary.page_of(id), MusicPage.PAGE, BlockIds.display_name(id))
		assert_true(MusicPage.TILES.has(id))
		assert_false(BlockIds.is_reserved(id))
		assert_true(BlockIds.is_valid(id), "%s may be placed" % BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s holds a child up" % BlockIds.display_name(id))
	assert_eq(MusicPage.TILES.size(), 2, "ids 752-753 (754-767 kept for more instruments)")
	assert_gte(BlockIds.COUNT, 754)
	assert_eq(BlockIds.NEXT_PAGE_FIRST_ID, 784, "the next block page is 46 (universe 6, the Glow Caves, took 45)")
	assert_eq(BlockIds.display_name(BlockIds.XYLOPHONE), "Xylophone")
	assert_eq(BlockIds.display_name(BlockIds.DRUM), "Bongo Drums")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in MusicPage.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		assert_same(m.get_material_override(0), BlockLibrary.page_material(MusicPage.PAGE, &"opaque"))
		assert_eq(BlockLibrary.tiles_of(id), (MusicPage.TILES[id] as Array).slice(0, 3))


func test_a_child_finds_them_in_the_palette_and_at_the_workbench_and_never_paints_them() -> void:
	for id: int in [BlockIds.XYLOPHONE, BlockIds.DRUM]:
		assert_has(BlockPalette.HOME_BLOCKS, id, "the Sandbox palette's HOME row")
		assert_has(PaintRules.JOBS, id, "never painted")
		var made := false
		for r: Dictionary in Recipes.LIST:
			if int(r.makes) == id:
				made = true
				assert_eq(r.at, Recipes.TABLE, "at a Workbench")
		assert_true(made, "%s has a recipe" % BlockIds.display_name(id))


func test_both_styles_draw_every_tile() -> void:
	assert_eq(MusicPage.FILES, ["res://data/blocks/pages/music.png", "res://data/blocks/pages/music_albedo.png",
		"res://data/blocks/pages/music_normal.png"])
	var pixel := (load(MusicPage.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var albedo := load(MusicPage.FILES[1]) as Texture2D
	assert_eq(albedo.get_width(), 2048)
	assert_eq(albedo.get_height(), 256, "one row of tiles kept")
	assert_eq((load(MusicPage.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	var real := albedo.get_image()
	if real.is_compressed():
		real.decompress()
	for id: int in MusicPage.TILES:
		for i in 3:
			var t: Vector2i = MusicPage.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_eq(seen, 256, "%s tile %s is drawn whole" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1,
				"%s tile %s is painted" % [BlockIds.display_name(id), t])


func test_the_xylophones_top_shows_its_bars_in_their_colours_low_on_the_west() -> void:
	var pixel := (load(MusicPage.FILES[0]) as Texture2D).get_image()
	var top: Vector2i = MusicPage.TILES[BlockIds.XYLOPHONE][0]
	for bar in MusicBlockRules.BARS:
		var c := pixel.get_pixel(top.x * 16 + bar * 2, top.y * 16 + 8)
		var want := MusicBlockRules.BAR_COLORS[bar]
		assert_almost_eq(c.h if want.s > 0.1 else 0.0, want.h if want.s > 0.1 else 0.0, 0.06,
			"bar %d (%s) in its colour" % [bar, MusicBlockRules.NOTES[bar]])
	var long := 0
	var short := 0
	for y in 16:
		if pixel.get_pixel(top.x * 16 + 0, top.y * 16 + y).is_equal_approx(pixel.get_pixel(top.x * 16, top.y * 16 + 8)):
			long += 1
		if pixel.get_pixel(top.x * 16 + 14, top.y * 16 + y).is_equal_approx(pixel.get_pixel(top.x * 16 + 14,
				top.y * 16 + 8)):
			short += 1
	assert_gt(long, short, "the low C's bar is longer than the high C's")
