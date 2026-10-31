extends GutTest
## M3 Task 8: block atlas page 12 holds the 16 painted blocks in both styles. One page is one shared material,
## so every tint in a chunk costs that chunk one draw call together (the ruling's measurement: a chunk of stone
## meshes into one surface, the same chunk with all 16 tints into two).


func test_every_painted_block_is_on_page_12_with_its_own_tile() -> void:
	PaintPage.register()
	var seen := {}
	for t in PaintRules.COUNT:
		var id := PaintRules.block_of(t)
		assert_eq(BlockLibrary.page_of(id), PaintPage.PAGE)
		var tiles := BlockLibrary.tiles_of(id)
		assert_eq(tiles.size(), 3, BlockIds.display_name(id))
		assert_eq(tiles[0], PaintPage.tile_of(t))
		assert_eq(tiles[1], tiles[0], "one tile on every face")
		assert_false(seen.has(tiles[0]), "its own tile")
		seen[tiles[0]] = true


func test_both_styles_share_the_pages_layout() -> void:
	var pixel := load(PaintPage.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for f: String in [PaintPage.FILES[1], PaintPage.FILES[2]]:
		var tex := load(f) as Texture2D
		assert_not_null(tex, f)
		assert_eq(tex.get_width(), 2048 if f == PaintPage.FILES[1] else 1024, "8 tiles of 256 px across (the normal map imported at half size; rows: test_page_sizes.gd): %s" % f)


## The pixel tiles are drawn in PaintRules' colours (tools/make_paint_page.gd keeps its own copy).
func test_the_pixel_tiles_are_the_tints() -> void:
	var img := (load(PaintPage.FILES[0]) as Texture2D).get_image()
	for t in PaintRules.COUNT:
		var tile := PaintPage.tile_of(t)
		var sum := Color(0, 0, 0, 0)
		for y in range(4, 12):
			for x in range(4, 12):
				sum += img.get_pixel(tile.x * 16 + x, tile.y * 16 + y)
		var avg := Color(sum.r / 64.0, sum.g / 64.0, sum.b / 64.0)
		var want := PaintRules.color(t)
		assert_almost_eq(avg.r, want.r, 0.06, PaintRules.tint_name(t))
		assert_almost_eq(avg.g, want.g, 0.06, PaintRules.tint_name(t))
		assert_almost_eq(avg.b, want.b, 0.06, PaintRules.tint_name(t))


func test_all_sixteen_tints_share_one_material() -> void:
	var lib := BlockLibrary.build()
	var first := (lib.models[BlockIds.PAINTED_WHITE] as VoxelBlockyModel).get_material_override(0)
	assert_same(first, BlockLibrary.page_material(PaintPage.PAGE, &"opaque"))
	for t in PaintRules.COUNT:
		var m := lib.models[PaintRules.block_of(t)] as VoxelBlockyModelCube
		assert_not_null(m)
		assert_same(m.get_material_override(0), first, PaintRules.tint_name(t))
		assert_false(m.collision_aabbs.is_empty(), "solid")


## Draw calls per chunk: the blocky mesher makes one surface per material a chunk uses.
func test_painting_adds_one_draw_call_to_a_chunk() -> void:
	var mesher := VoxelMesherBlocky.new()
	mesher.library = BlockLibrary.build()
	var buf := VoxelBuffer.new()
	buf.create(18, 18, 18)   # a 16³ chunk plus the mesher's 1-block padding
	buf.fill_area(BlockIds.STONE, Vector3i(1, 1, 1), Vector3i(17, 9, 17), VoxelBuffer.CHANNEL_TYPE)
	var plain := mesher.build_mesh(buf, [])
	assert_eq(plain.get_surface_count(), 1, "stone: one draw call")
	for t in PaintRules.COUNT:
		buf.set_voxel(PaintRules.block_of(t), 1 + t, 9, 4, VoxelBuffer.CHANNEL_TYPE)
	var painted := mesher.build_mesh(buf, [])
	assert_eq(painted.get_surface_count(), 2, "stone and all 16 tints: two draw calls")
