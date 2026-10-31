extends GutTest
## M5 Task 3 (spec §15.3, the APK size pass): the realistic block pages were most of the APK. Every page was two
## 2048 x 2048 textures, 5.6 MB each once VRAM-compressed (stored raw in the APK), and most pages draw only two or
## three of their eight rows. The page tools now crop the rows under a page's last drawn tile and write a page with no
## see-through tile without alpha; the normal maps are imported at half size; the realistic materials stretch the
## 8 x 8 page's UVs over the rows kept (`uv1_scale`), so the meshes, the tile coordinates and the pixel pages stay
## exactly as they were.

const TILE := 256   # a realistic tile's pixels (240 px of texture in an 8 px border)


func before_all() -> void:
	BlockLibrary.build()   # registers the pages every world has (smart, portals, paint) besides the universes'


## page -> [pixel, realistic albedo, realistic normal] for page 0 and every page the game registers.
func _pages() -> Dictionary:
	var out := {0: BlockLibrary.PAGE_0_FILES}
	for page: int in BlockLibrary._pages:
		var files: Array = BlockLibrary._pages[page].files
		if page != 21 and (files[1] as String).begins_with("res://data/blocks/"):   # not test_block_pages' page
			out[page] = files
	return out


## The tiles a page's blocks use.
func _tiles(page: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var table: Dictionary = BlockLibrary.TILES if page == 0 else BlockLibrary._pages[page].tiles
	for id: int in table:
		for t: Variant in table[id]:
			if t is Vector2i:
				out.append(t)
	return out


func _source(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))


## True when a tile of the source image has a drawn (not fully transparent) pixel.
func _drawn(img: Image, tile: Vector2i) -> bool:
	if not img.detect_alpha():
		return true
	var s := img.get_width() / 8
	for y in range(0, s, 8):
		for x in range(0, s, 8):
			if img.get_pixel(tile.x * s + x, tile.y * s + y).a > 0.0:
				return true
	return false


func test_every_realistic_page_keeps_only_the_rows_it_draws() -> void:
	var pages := _pages()
	assert_gte(pages.size(), 10, "page 0 and the nine pages of the universes and systems")
	for page: int in pages:
		var albedo := _source(pages[page][1])
		assert_eq(albedo.get_width(), 8 * TILE, "page %d: eight tiles of 256 px across" % page)
		assert_eq(albedo.get_height() % TILE, 0, "page %d: whole rows" % page)
		var rows := albedo.get_height() / TILE
		var need := 0
		for t in _tiles(page):
			need = maxi(need, t.y + 1)
		assert_gte(rows, need, "page %d keeps every row its blocks use" % page)
		var last_row_drawn := false
		for x in 8:
			last_row_drawn = last_row_drawn or _drawn(albedo, Vector2i(x, rows - 1))
		assert_true(last_row_drawn, "page %d: no empty row at the bottom (%d rows)" % [page, rows])
		assert_eq(BlockLibrary.texture_rows(load(pages[page][1]) as Texture2D), rows, "page %d's rows, from its texture" % page)
	var desert := _source(DesertBlocks.FILES[1])
	assert_eq(desert.get_height(), 3 * TILE, "the desert draws three rows")


func test_the_normal_maps_are_imported_at_half_size_with_the_same_rows() -> void:
	var pages := _pages()
	for page: int in pages:
		var albedo := load(pages[page][1]) as Texture2D
		var normal := load(pages[page][2]) as Texture2D
		assert_eq(albedo.get_width(), 8 * TILE, "page %d's albedo stays at full size" % page)
		assert_eq(normal.get_width(), 4 * TILE, "page %d's normal map: 128 px tiles" % page)
		assert_eq(BlockLibrary.texture_rows(normal), BlockLibrary.texture_rows(albedo), "page %d: one layout" % page)
		var source := _source(pages[page][2])
		assert_eq(source.get_size(), Vector2i(albedo.get_size()), "page %d: the normal map's source keeps every pixel" % page)


## A page whose blocks are all solid (no cut-out or walk-through tile) is written without alpha: its albedo is then
## half the size once VRAM-compressed (ETC2 RGB), and nothing is see-through anyway.
func test_a_page_without_see_through_blocks_has_no_alpha() -> void:
	var pages := _pages()
	var without := 0
	for page: int in pages:
		if page == 0:
			continue   # leaves and glass
		var see_through := false
		var table: Dictionary = BlockLibrary._pages[page].tiles
		for id: int in table:
			var t: Array = table[id]
			if t.size() > 3 and (t[3] == &"cutout" or t[3] == &"pass"):
				see_through = true
		var albedo := _source(pages[page][1])
		if not see_through:
			without += 1
			assert_eq(albedo.get_format(), Image.FORMAT_RGB8, "page %d has no see-through block: no alpha" % page)
	assert_gte(without, 2, "the paint page and the Tiny world's page")
	assert_eq(_source(PaintPage.FILES[1]).get_format(), Image.FORMAT_RGB8)
	assert_eq(_source(TinyPage.FILES[1]).get_format(), Image.FORMAT_RGB8)


func test_the_realistic_materials_stretch_the_page_over_its_rows() -> void:
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	var pages := _pages()
	for page: int in pages:
		var rows := BlockLibrary.texture_rows(load(pages[page][1]) as Texture2D)
		for kind: StringName in [&"opaque", &"cutout", &"glow"]:
			var mat := BlockLibrary.page_material(page, kind)
			assert_almost_eq(mat.uv1_scale, Vector3(1.0, 8.0 / rows, 1.0), Vector3.ONE * 0.0001, "page %d %s" % [page, kind])
	assert_almost_eq(BlockLibrary.page_material(DesertBlocks.PAGE, &"opaque").uv1_scale, Vector3(1.0, 8.0 / 3.0, 1.0),
		Vector3.ONE * 0.0001, "the desert's three rows fill its texture")
	BlockLibrary.set_style("blocky")
	for page: int in pages:
		for kind: StringName in [&"opaque", &"cutout", &"glow"]:
			assert_eq(BlockLibrary.page_material(page, kind).uv1_scale, Vector3.ONE, "page %d %s: the whole 8 x 8 pixel page" % [page, kind])
	BlockLibrary.set_style(before)


## What the pages cost in the APK (the imported textures, stored raw): about 31 MB, down from 112 MB. A new page of
## three rows without alpha adds about 1.6 MB (its albedo 1.0 MB, its half-size normal map 0.5 MB); the budget leaves
## room for a few. Cosmos, Mercury's agent (2026-09-29): the pages reached 39.3 MB with Titan's (page 29), so Mercury's
## (page 30) took the budget from 40 to 48 MB: room for about five more planets' pages (ruling in
## docs/devlog/parts/cosmos-mercury.md). Owner #78 (the wonders' pages 33-34, 2026-09-30): the rocket parts', the riches'
## and the wonders' pages brought them to 49.8 MB, so the budget went from 48 to 54 MB: room for the colony domes' page
## 31 and two more (ruling in docs/devlog/parts/wonders-ancient.md). The New Seven Wonders' pages 36-37 and Venus's page
## 38 (2026-09-30) brought them to about 56 MB, so the budget went from 54 to 60 MB (rulings in
## docs/devlog/parts/wonders-new-seven.md and cosmos-venus.md). Saturn's rings' page 40 (2026-09-30) brought them to
## 58.5 MB, and page 39 (the riches of the Moon and Mars) came too, so the budget went from 60 to 64 MB (ruling in
## docs/devlog/parts/cosmos-rings.md). Pluto's page 41 brought them to 62.2 MB and Triton's page 42 (2026-09-30) to
## 63.8, so the budget went from 64 to 70 MB: room for about four more pages (ruling in docs/devlog/parts/cosmos-triton.md).
## The Seven Natural Wonders' rows 1-3 on page 37 (2026-10-01; see-through corn, flags and spray: the page keeps alpha)
## brought them to 66.8 MB (ruling in docs/devlog/parts/wonders-nature.md). Ganymede's page 43 (2026-10-01, three rows
## without alpha) to 68.3 MB: still inside the 70 MB budget, room for one more page (ruling in
## docs/devlog/parts/cosmos-ganymede.md). The music page 44 (owner #110) brought them to 68.9 MB; universe 6, the Glow
## Caves' page 45 (2026-10-17: three rows with alpha, the stalactites and stalagmites are cut out) to 71.5 MB, so the
## budget went from 70 to 72 MB: the APK and each browser's realistic pack grow by 2.6 MB (ruling in
## docs/devlog/parts/glow-caves.md).
func test_the_realistic_pages_fit_their_budget() -> void:
	var bytes := 0
	var pages := _pages()
	for page: int in pages:
		for f: String in [pages[page][1], pages[page][2]]:
			bytes += (load(f) as Texture2D).get_image().get_data().size()
	gut.p("realistic pages: %.1f MB" % (bytes / 1e6))
	assert_lt(bytes, 72_000_000, "the realistic pages' VRAM textures")
