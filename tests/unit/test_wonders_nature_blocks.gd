extends GutTest
## Owner #78 (spec §24), the third tour: the Seven Natural Wonders' blocks on block atlas page 37's rows 1-3 (ids
## 642-655, under the New Seven's row), drawn in both styles (data/blocks/pages/wonders4*.png): the Grand Canyon's rock
## layers, a sea fossil, the reef's corals, Parícutin's cinders and corn, Everest's prayer flags and the falls' spray.

const T := WondersBlocks.TILES_NATURE
const ROCKS := [BlockIds.KAIBAB_LIMESTONE, BlockIds.COCONINO_SANDSTONE, BlockIds.SUPAI_REDBED, BlockIds.REDWALL_LIMESTONE,
	BlockIds.CANYON_SHALE, BlockIds.VISHNU_SCHIST]
const SEE_THROUGH := [BlockIds.CORN, BlockIds.PRAYER_FLAGS, BlockIds.SPRAY]


func test_every_block_is_on_page_37_with_a_name_and_no_new_page() -> void:
	assert_eq(T.size(), 14, "fourteen blocks: page 37's free ids")
	for id: int in T:
		assert_between(id, 642, 655, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), WondersBlocks.PAGE_NEW_MORE, BlockIds.display_name(id))
		assert_true(BlockIds.is_valid(id), "%s can be placed" % BlockIds.display_name(id))
		assert_ne(BlockIds.display_name(id), "", "id %d has a name" % id)
		assert_false(ItemIds.is_item(id), "%d is no item's" % id)
		assert_true(WondersBlocks.page_37_tiles().has(id), "registered with page 37")
	for id in range(642, 656):
		assert_true(T.has(id), "id %d is the third tour's" % id)
	assert_gte(BlockIds.COUNT, 736, "no new page: the third tour fits page 37 (page 43 went to Ganymede, cosmos, later)")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 736)
	assert_eq(BlockLibrary.page_of(642), 37, "the third tour's ids are page 37's")


func test_names_are_what_a_child_says() -> void:
	assert_eq(BlockIds.display_name(BlockIds.KAIBAB_LIMESTONE), "Kaibab Limestone")
	assert_eq(BlockIds.display_name(BlockIds.VISHNU_SCHIST), "Vishnu Schist")
	assert_eq(BlockIds.display_name(BlockIds.SEA_FOSSIL), "Sea Fossil")
	assert_eq(BlockIds.display_name(BlockIds.BRAIN_CORAL), "Brain Coral")
	assert_eq(BlockIds.display_name(BlockIds.CINDER), "Cinders")
	assert_eq(BlockIds.display_name(BlockIds.CORN), "Corn")
	assert_eq(BlockIds.display_name(BlockIds.PRAYER_FLAGS), "Prayer Flags")
	assert_eq(BlockIds.display_name(BlockIds.SPRAY), "Waterfall Spray")


func test_corn_flags_and_spray_are_walked_through_the_rest_are_solid() -> void:
	for id: int in T:
		assert_eq(BlockIds.is_solid(id), not SEE_THROUGH.has(id), BlockIds.display_name(id))
	var lib := BlockLibrary.build()
	var page := WondersBlocks.PAGE_NEW_MORE
	for id: int in T:
		var m: VoxelBlockyModel = lib.models[id]
		var kind: StringName = T[id][3]
		var want := BlockLibrary.page_material(page, &"cutout" if kind == &"pass" else kind)
		assert_same(m.get_material_override(0), want, BlockIds.display_name(id))
		if SEE_THROUGH.has(id):
			assert_eq(m.collision_aabbs.size(), 0, "%s has nothing to bump into" % BlockIds.display_name(id))
	assert_true(lib.models[BlockIds.CORN] is VoxelBlockyModelMesh, "corn: two crossed pictures, like wheat")
	assert_true((lib.models[BlockIds.SPRAY] as VoxelBlockyModelCube).culls_neighbors, "a cloud of spray: one surface")


func test_both_pictures_have_every_tile_drawn_under_the_new_sevens_row() -> void:
	var files: Array = WondersBlocks.FILES_NEW_MORE
	var pixel := (load(files[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128))
	var real := (load(files[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq(BlockLibrary.texture_rows(load(files[1]) as Texture2D), 4, "the New Seven's row and nature's three")
	for id: int in T:
		for i in 3:
			var t: Vector2i = T[id][i]
			assert_between(t.y, 1, 3, "%s's tile %s is in nature's rows" % [BlockIds.display_name(id), t])
			if SEE_THROUGH.has(id):
				continue
			assert_gt(_mean(pixel, t).a, 0.9, "%s's tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(_mean_real(real, t).a, 0.9, "%s's realistic tile %s" % [BlockIds.display_name(id), t])
	for id: int in SEE_THROUGH:
		var t: Vector2i = T[id][1]
		var a := _mean(pixel, t).a
		assert_between(a, 0.05, 0.85, "%s is partly see-through (%.2f)" % [BlockIds.display_name(id), a])
		assert_between(_mean_real(real, t).a, 0.05, 0.9, "and in the realistic style")
	var flags_top: Vector2i = T[BlockIds.PRAYER_FLAGS][0]
	assert_lt(_mean(pixel, flags_top).a, 0.05, "a string of flags has no top")
	var row0 := _mean(pixel, WondersBlocks.TILES_NEW_MORE[BlockIds.MUGHAL_RED][1])
	assert_gt(row0.r, row0.g + 0.2, "the New Seven's row is kept (the gate's red stone)")


## Our own look (spec §3c), and what a child sees.
func test_each_block_looks_like_what_it_is() -> void:
	var pixel := (load(WondersBlocks.FILES_NEW_MORE[0]) as Texture2D).get_image()
	var side := func(id: int) -> Color: return _mean(pixel, T[id][1])
	var kaibab: Color = side.call(BlockIds.KAIBAB_LIMESTONE)
	assert_gt(kaibab.v, 0.7, "the Kaibab limestone is pale (%s)" % kaibab)
	var coconino: Color = side.call(BlockIds.COCONINO_SANDSTONE)
	assert_gt(coconino.v, 0.7, "the Coconino sandstone is cream (%s)" % coconino)
	assert_gt(coconino.r, coconino.b + 0.1, "a warm cream")
	var supai: Color = side.call(BlockIds.SUPAI_REDBED)
	assert_gt(supai.r, supai.b + 0.25, "the Supai beds are red (%s)" % supai)
	var redwall: Color = side.call(BlockIds.REDWALL_LIMESTONE)
	assert_gt(redwall.r, redwall.b + 0.1, "the Redwall is stained red (%s)" % redwall)
	assert_lt(redwall.s, supai.s, "but greyer than the beds above it")
	var shale: Color = side.call(BlockIds.CANYON_SHALE)
	assert_gte(shale.g, shale.r, "the shale is green-grey (%s)" % shale)
	var schist: Color = side.call(BlockIds.VISHNU_SCHIST)
	assert_lt(schist.v, 0.45, "the schist is dark (%s)" % schist)
	var brain: Color = side.call(BlockIds.BRAIN_CORAL)
	assert_gt(brain.g, brain.b + 0.1, "brain coral is green-gold (%s)" % brain)
	var staghorn: Color = side.call(BlockIds.STAGHORN_CORAL)
	assert_gt(staghorn.r, staghorn.g + 0.1, "staghorn coral is pink (%s)" % staghorn)
	var fan: Color = side.call(BlockIds.SEA_FAN)
	assert_gt(fan.b, fan.g + 0.1, "a sea fan is purple (%s)" % fan)
	var cinder: Color = side.call(BlockIds.CINDER)
	assert_lt(cinder.v, 0.4, "cinders are dark (%s)" % cinder)
	assert_gt(cinder.r, cinder.b, "red-black")
	var fossil: Color = side.call(BlockIds.SEA_FOSSIL)
	assert_lt(fossil.s, 0.25, "a grey limestone (%s)" % fossil)
	assert_ne(T[BlockIds.SEA_FOSSIL][1], T[BlockIds.SEA_FOSSIL][0], "its side shows the fossil, its top plain stone")
	var flags := _colours(pixel, T[BlockIds.PRAYER_FLAGS][1])
	assert_gte(flags, 5, "flags in five colours (%d)" % flags)


func _mean(img: Image, t: Vector2i) -> Color:
	var sum := Color(0, 0, 0, 0)
	for y in 16:
		for x in 16:
			sum += img.get_pixel(t.x * 16 + x, t.y * 16 + y)
	return sum / 256.0


## How many clearly different colours a tile shows (drawn pixels, by hue).
func _colours(img: Image, t: Vector2i) -> int:
	var hues := {}
	for y in 16:
		for x in 16:
			var c := img.get_pixel(t.x * 16 + x, t.y * 16 + y)
			if c.a < 0.5:
				continue
			hues["w" if c.s < 0.2 else str(int(c.h * 12.0))] = true
	return hues.size()


func _mean_real(img: Image, t: Vector2i) -> Color:
	var cell := img.get_width() / 8
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for y in range(8, cell - 8, 16):
		for x in range(8, cell - 8, 16):
			sum += img.get_pixel(t.x * cell + x, t.y * cell + y)
			n += 1
	return sum / float(n)
