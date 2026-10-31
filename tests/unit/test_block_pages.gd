extends GutTest
## M3 Task 1: block atlas pages. Page 0 is the M1/M2 atlas (ids < 64); each later 16-id range gets its
## own 8 x 8 page with a realistic twin and its own shared, long-lived materials: desert 64-79, frost
## 80-95, and — items own 100-175 and 400+ (one id space: a bag holds either) — candy 176-191, smart and
## game blocks 192-207, portals/pads/lab 208-223, the Dragon Realm 224-239 (owner #39), paint 240-255 (M3 Task 8),
## the wild meadows 256-271 (owner #45b); blocks may use up to 399 (the voxel type channel is 16-bit).
## Worlds made before pages render exactly as before.

## A page no universe or system owns (M3 Task 2 registers the desert's page 1 for real, so the tests
## register and unregister a free one): unregistering a real page here would take it away from every later test (page
## 12 went to M3 Task 8's paint, page 13 to owner #45b's meadows, page 21, the last page under the items' ids, to Io).
## Page 99 is far past any block's (the library grows to reach a registered page's ids).
const TEST_PAGE := 99
const TEST_ID := 1638   # 64 + 98 x 16 + 6: page 99


func after_each() -> void:
	BlockLibrary.unregister_page(TEST_PAGE)


func test_page_ranges() -> void:
	assert_eq(BlockLibrary.page_of(0), 0)
	assert_eq(BlockLibrary.page_of(63), 0)
	assert_eq(BlockLibrary.page_of(64), 1, "desert")
	assert_eq(BlockLibrary.page_of(79), 1)
	assert_eq(BlockLibrary.page_of(80), 2, "frost")
	assert_eq(BlockLibrary.page_of(176), 8, "candy")
	assert_eq(BlockLibrary.page_of(192), 9, "smart and game blocks")
	assert_eq(BlockLibrary.page_of(208), 10, "portals, pads, lab")
	assert_eq(BlockLibrary.page_of(224), 11, "the Dragon Realm")
	assert_eq(BlockLibrary.page_of(240), 12, "paint")
	assert_eq(BlockLibrary.page_of(256), 13, "the wild meadows")
	assert_eq(BlockLibrary.page_of(399), 21, "the last page under the items' ids (Io's)")
	assert_eq(BlockLibrary.page_of(512), 29, "the first page past them (Titan's)")
	assert_eq(BlockLibrary.page_of(528), 30, "Mercury's")
	assert_eq(BlockLibrary.page_of(656), 38, "Venus's cloud city's")
	assert_eq(BlockLibrary.page_of(688), 40, "Saturn's rings' (39 is the riches of the Moon and Mars)")
	assert_eq(BlockLibrary.page_of(704), 41, "Pluto's")
	assert_eq(BlockLibrary.page_of(720), 42, "Triton's")
	assert_eq(BlockLibrary.page_of(736), 43, "Ganymede's")
	assert_eq(BlockLibrary.page_of(544), 31, "kept for the colony domes")
	assert_eq(BlockLibrary.page_of(560), 32, "the rocket parts' (spec §21d)")
	assert_eq(BlockLibrary.page_of(576), 33, "the world's wonders (owner #78)")
	assert_eq(BlockLibrary.page_of(592), 34, "the world's wonders' second page")
	assert_eq(BlockLibrary.page_of(608), 35, "prospecting's riches (spec §26)")
	assert_eq(BlockLibrary.page_of(624), 36, "the New Seven Wonders (owner #78's second tour)")
	assert_eq(BlockLibrary.page_of(640), 37, "the New Seven Wonders' second page")
	assert_eq(BlockLibrary.page_of(672), 39, "the riches of the Moon and Mars (spec §26.5)")
	assert_eq(BlockLibrary.page_of(TEST_ID), TEST_PAGE, "this test's page")


## A hotbar slot or a bag holds a block id or an item id, so no item may ever take an id of the block
## pages (T5 found the first plan's ranges from 100 up were item ids: a portal frame at 128 would have
## broken into a Crystal Bow).
func test_no_item_takes_an_id_of_the_block_pages() -> void:
	for id in range(BlockLibrary.FIRST_PAGED_ID, 100):
		assert_false(ItemIds.is_item(id), "%d is a desert/frost block id" % id)
	for id in range(176, 400):
		assert_false(ItemIds.is_item(id), "%d is a block page id (176-399)" % id)


func test_every_block_of_today_is_on_page_0_within_the_8_by_8_atlas() -> void:
	for id: int in BlockLibrary.TILES:
		assert_eq(BlockLibrary.page_of(id), 0, BlockIds.display_name(id))
		for t: Vector2i in BlockLibrary.TILES[id]:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t), "%s tile %s" % [BlockIds.display_name(id), t])


func test_page_materials_are_shared_and_long_lived() -> void:
	var a := BlockLibrary.build()
	var b := BlockLibrary.build()
	var stone_a := (a.models[BlockIds.STONE] as VoxelBlockyModel).get_material_override(0)
	var stone_b := (b.models[BlockIds.STONE] as VoxelBlockyModel).get_material_override(0)
	assert_same(stone_a, stone_b, "one material for page 0's opaque blocks, however many libraries")
	assert_same(BlockLibrary.page_material(0, &"opaque"), stone_a)


func test_a_registered_page_gets_its_own_textures_and_materials() -> void:
	BlockLibrary.register_page(TEST_PAGE, BlockLibrary.PAGE_0_FILES, {TEST_ID: [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]})
	var lib := BlockLibrary.build()
	assert_gt(lib.models.size(), TEST_ID, "the library reaches the page's ids")
	var m := lib.models[TEST_ID] as VoxelBlockyModelCube
	assert_not_null(m, "the page's block has a cube model")
	var mat := m.get_material_override(0)
	assert_same(mat, BlockLibrary.page_material(TEST_PAGE, &"opaque"))
	assert_ne(mat, BlockLibrary.page_material(0, &"opaque"), "a page of its own: its own material")
	assert_eq(m.get_tile(VoxelBlockyModel.SIDE_POSITIVE_Y), Vector2i(1, 0))


func test_the_style_switch_restyles_every_page() -> void:
	BlockLibrary.register_page(TEST_PAGE, BlockLibrary.PAGE_0_FILES, {TEST_ID: [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 0)]})
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	for page: int in [0, TEST_PAGE]:
		var mat := BlockLibrary.page_material(page, &"opaque")
		assert_true(mat.normal_enabled, "page %d realistic" % page)
	BlockLibrary.set_style("blocky")
	for page: int in [0, TEST_PAGE]:
		assert_false(BlockLibrary.page_material(page, &"opaque").normal_enabled, "page %d blocky" % page)
	BlockLibrary.set_style(before)


func test_page_0_files_are_the_atlas_and_its_realistic_twin() -> void:
	assert_eq(BlockLibrary.PAGE_0_FILES, ["res://data/blocks/atlas.png", BlockLibrary.REALISTIC_ALBEDO, BlockLibrary.REALISTIC_NORMAL])
	var pixel := load(BlockLibrary.PAGE_0_FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(BlockLibrary.ATLAS_TILES * 16), "8 x 8 tiles of 16 px")


func test_a_paged_block_gets_its_icon_from_its_page() -> void:
	BlockLibrary.register_page(TEST_PAGE, BlockLibrary.PAGE_0_FILES, {TEST_ID: [Vector2i(1, 0), Vector2i(2, 3), Vector2i(3, 0)]})
	assert_eq(BlockLibrary.tiles_of(TEST_ID), [Vector2i(1, 0), Vector2i(2, 3), Vector2i(3, 0)])
	assert_eq(BlockLibrary.tiles_of(BlockIds.STONE), BlockLibrary.TILES[BlockIds.STONE])
	assert_eq(BlockLibrary.tiles_of(9999), [])
	assert_eq(BlockLibrary.pixel_atlas_of(TEST_ID).resource_path, BlockLibrary.PAGE_0_FILES[0])
	BlockIcons._cache.erase(TEST_ID)
	var icon := BlockIcons.icon(TEST_ID) as AtlasTexture
	assert_not_null(icon, "an icon from the page")
	assert_eq(icon.region, Rect2(2 * 16, 3 * 16, 16, 16), "its side tile")
	BlockIcons._cache.erase(TEST_ID)
