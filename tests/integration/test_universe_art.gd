extends GutTest
## M5 Task 2 (spec §15.2): every universe's own little scene on its cards (and behind its own menu screens), drawn
## from its own block tiles and colours in owner #43's look, with the brand's buddy exploring it.


func after_each() -> void:
	UniverseRegistry.reset()


func test_every_universe_has_its_own_scene_of_equal_rows() -> void:
	var seen := {}
	for u in range(1, UniverseRegistry.size() + 1):
		var rows := UniverseArt.layout(u)
		assert_eq(rows.size(), UniverseArt.ROWS, "universe %d" % u)
		for r: String in rows:
			assert_eq(r.length(), UniverseArt.COLUMNS, "universe %d: every row as wide" % u)
		seen["\n".join(rows)] = u
	assert_eq(seen.size(), UniverseRegistry.size(), "five different scenes")


func test_every_block_in_a_scene_has_a_tile_to_draw() -> void:
	for u in range(1, UniverseRegistry.size() + 1):
		var legend := UniverseArt.legend(u)
		for r: String in UniverseArt.layout(u):
			for ch in r:
				if ch == ".":
					continue
				assert_true(legend.has(ch), "universe %d: '%s' is in its legend" % [u, ch])
				var id: int = legend.get(ch, 0)
				if id > 0:
					assert_false(BlockLibrary.tiles_of(id).is_empty(), "universe %d: block %d has tiles" % [u, id])
					assert_not_null(UniverseArt.tile(id, UniverseArt.SIDE), "universe %d: block %d's side tile" % [u, id])


func test_each_scene_is_built_from_its_own_universes_blocks() -> void:
	for u in range(2, UniverseRegistry.size() + 1):
		var own := UniverseRegistry.trader_stock(u).keys()
		var used := {}
		for r: String in UniverseArt.layout(u):
			for ch in r:
				var id: int = UniverseArt.legend(u).get(ch, 0)
				if own.has(id):
					used[id] = true
		assert_gte(used.size(), 3, "universe %d uses at least three of its own blocks: %s" % [u, used.keys()])
	var meadows := {}
	for r: String in UniverseArt.layout(1):
		for ch in r:
			meadows[UniverseArt.legend(1).get(ch, 0)] = true
	for id in [BlockIds.GRASS, BlockIds.DIRT, BlockIds.LOG, BlockIds.LEAVES]:
		assert_true(meadows.has(id), "Green Meadows: %s" % BlockIds.display_name(id))


func test_tiles_come_from_the_blocks_own_page_and_are_cached() -> void:
	var t := UniverseArt.tile(BlockIds.SNOW, UniverseArt.SIDE) as AtlasTexture
	assert_same(t.atlas, BlockLibrary.pixel_atlas_of(BlockIds.SNOW), "Frostpeak's own page")
	var tile := t.atlas.get_width() / BlockLibrary.ATLAS_TILES.x
	var want: Vector2i = BlockLibrary.tiles_of(BlockIds.SNOW)[1]
	assert_eq(t.region, Rect2(want.x * tile, want.y * tile, tile, tile), "its side tile, whatever size a page is")
	assert_same(UniverseArt.tile(BlockIds.SNOW, UniverseArt.SIDE), t, "made once")
	var top := UniverseArt.tile(BlockIds.GRASS, UniverseArt.TOP) as AtlasTexture
	var grass_top: Vector2i = BlockLibrary.tiles_of(BlockIds.GRASS)[0]
	assert_eq(top.region.position, Vector2(grass_top * tile), "a top tile when asked")


func test_the_dragon_realms_card_is_a_sunrise_not_a_violet_void() -> void:
	var c := UniverseRegistry.card_colors(5)
	for key: String in ["top", "bottom", "ground"]:
		var col: Color = c[key]
		assert_false(col.h > 0.66 and col.h < 0.86 and col.s > 0.25, "%s is not violet (%s)" % [key, col.to_html(false)])


func test_a_card_draws_its_universes_scene_and_a_locked_card_hides_it() -> void:
	var card := UniverseCard.new(3, true)
	add_child_autofree(card)
	assert_eq(card.picture.universe, 3, "Frostpeak's scene")
	var locked := UniverseCard.new(4, false)
	add_child_autofree(locked)
	assert_eq(locked.picture.universe, 4)
	assert_true(locked.picture.locked, "greyed, with a question mark")
	await wait_frames(2)
	assert_gt(card.picture.drawn, 0, "it drew its blocks")


func test_a_backdrop_fills_its_rect_without_asking_for_room() -> void:
	var b := UniverseBackdrop.new(2)
	add_child_autofree(b)
	assert_eq(b.get_combined_minimum_size(), Vector2.ZERO, "it never makes a panel bigger")
	assert_eq(b.mouse_filter, Control.MOUSE_FILTER_IGNORE, "taps go to the buttons")
	assert_eq(b.universe, 2)
	assert_gt(b.veil.a, 0.4, "a soft veil keeps the words readable")
