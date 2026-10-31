extends GutTest
## Spec §23.1: the lab bench (id 352, block atlas page 19, LabPage), a white bench with a glass flask and a tiny burner
## in both styles (data/blocks/pages/lab.png and its realistic twin). The Sandbox has it in the palette's HOME row;
## Survivor crafts it at a Workbench (planks, glass and iron) and finds one in some village houses; /give knows it; it is
## never painted (a block with a job).


func test_the_id_and_the_page_are_the_allocated_ones() -> void:
	assert_eq(BlockIds.LAB_BENCH, 352)
	assert_eq(LabPage.PAGE, 19)
	assert_eq(BlockLibrary.page_of(BlockIds.LAB_BENCH), LabPage.PAGE)
	assert_gt(BlockIds.COUNT, BlockIds.LAB_BENCH)
	assert_eq(BlockLibrary.page_of(367), LabPage.PAGE, "page 19 runs to 367")
	assert_ne(BlockLibrary.page_of(368), LabPage.PAGE, "368 is the next page's (Europa's)")
	for id in range(352, 368):
		assert_false(ItemIds.is_item(id), "%d is a block id of page 19" % id)
	for other: int in [MarsBlocks.PAGE, MoonBlocks.PAGE, TinyPage.PAGE, PortalPage.PAGE, SmartPage.PAGE]:
		assert_ne(other, LabPage.PAGE, "a page of its own")
	assert_eq(BlockIds.display_name(BlockIds.LAB_BENCH), "Lab Bench")
	assert_true(BlockIds.is_valid(BlockIds.LAB_BENCH))
	assert_true(BlockIds.is_solid(BlockIds.LAB_BENCH), "you can't walk through a bench")
	assert_true(Inventory.ownable(BlockIds.LAB_BENCH))
	assert_false(PaintRules.paintable(BlockIds.LAB_BENCH), "a block with a job is never painted")
	assert_false(BlockIds.PLACEABLE.has(BlockIds.LAB_BENCH), "in the palette's HOME row, not the block grid")
	assert_has(BlockPalette.HOME_BLOCKS, BlockIds.LAB_BENCH)
	assert_eq(ChatCommands.item_for_name("lab bench"), BlockIds.LAB_BENCH)


func test_every_world_has_it_in_both_styles() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	var m := lib.models[BlockIds.LAB_BENCH] as VoxelBlockyModelCube
	assert_not_null(m)
	assert_false(m.collision_aabbs.is_empty(), "solid")
	assert_same(m.get_material_override(0), BlockLibrary.page_material(LabPage.PAGE, &"opaque"))
	var t := BlockLibrary.tiles_of(BlockIds.LAB_BENCH)
	assert_eq(t, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], "top, side, bottom")
	assert_eq(LabPage.FILES, ["res://data/blocks/pages/lab.png", "res://data/blocks/pages/lab_albedo.png",
		"res://data/blocks/pages/lab_normal.png"])
	var pixel := Image.load_from_file(ProjectSettings.globalize_path(LabPage.FILES[0]))
	var albedo := Image.load_from_file(ProjectSettings.globalize_path(LabPage.FILES[1]))
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	assert_eq(albedo.get_width(), 2048)
	for tile: Vector2i in t:
		assert_gt(pixel.get_pixel(tile.x * 16 + 8, tile.y * 16 + 12).a, 0.9, "drawn, solid: %s" % tile)
		assert_gt(albedo.get_pixel(tile.x * 256 + 128, tile.y * 256 + 200).a, 0.9, "realistic, solid: %s" % tile)
	# our own look: a white bench (the cabinet's doors on the side) with a flask of green liquid above the worktop
	var white := pixel.get_pixel(1 * 16 + 4, 12)
	assert_gt(white.get_luminance(), 0.8, "the white cabinet")
	var found_green := false
	for y in range(1, 8):
		for x in 16:
			var c := pixel.get_pixel(16 + x, y)
			found_green = found_green or (c.g > 0.55 and c.g > c.r + 0.2 and c.g > c.b + 0.1)
	assert_true(found_green, "a flask of green liquid on the side's shelf")


func test_survivor_crafts_it_at_a_workbench_from_planks_glass_and_iron() -> void:
	var r := Recipes.for_result(BlockIds.LAB_BENCH)
	assert_false(r.is_empty())
	assert_eq(r.at, Recipes.TABLE)
	assert_eq((r.needs as Dictionary).keys().size(), 3)
	for id: int in [BlockIds.PLANKS, BlockIds.GLASS, BlockIds.IRON]:
		assert_true((r.needs as Dictionary).has(id), BlockIds.display_name(id))
	assert_eq(int(r.count), 1)
	assert_eq(Recipes.problems(Recipes.LIST), [] as Array[String])
