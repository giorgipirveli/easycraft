extends GutTest
## Prospecting on the Moon and Mars (owner #80, spec §26.5): the riches' blocks on block atlas page 39 (ids 672-687),
## drawn in both styles (data/blocks/pages/prospect_space.png and its realistic twin). Found in the ground: the Moon's icy
## regolith (the dark craters' ice), mare dust (the dark seas' titanium-rich dust, with helium-3), ilmenite, KREEP rock
## (rare earths), an iron meteorite (both worlds); Mars's ground ice, blueberry soil and hematite (the "blueberries"),
## dark sand (iron-rich, a magnet picks it up) and Mars salt (perchlorate). What in-situ resource use makes: an oxygen
## tank, hydrogen fuel, titanium, rare earths, helium-3, and the Solar Oven (a station). Pages 36-37 are the New Seven
## Wonders' (another agent's), 38 Venus's.

const ALL_IDS: Array[int] = [BlockIds.ICY_REGOLITH, BlockIds.MARE_DUST, BlockIds.ILMENITE, BlockIds.KREEP_ROCK,
	BlockIds.IRON_METEORITE, BlockIds.GROUND_ICE, BlockIds.BLUEBERRY_SOIL, BlockIds.HEMATITE, BlockIds.DARK_SAND,
	BlockIds.MARS_SALT, BlockIds.OXYGEN_TANK, BlockIds.HYDROGEN_FUEL, BlockIds.TITANIUM, BlockIds.RARE_EARTHS,
	BlockIds.HELIUM_3, BlockIds.SOLAR_OVEN]


func test_every_block_is_on_page_39() -> void:
	assert_eq(ProspectSpacePage.PAGE, 39)
	assert_eq(ProspectSpacePage.TILES.size(), 16, "ten found in the ground, five made, the Solar Oven")
	for i in ALL_IDS.size():
		assert_eq(ALL_IDS[i], 672 + i, "ids in order from 672 (%s)" % BlockIds.display_name(ALL_IDS[i]))
	for id: int in ProspectSpacePage.TILES:
		assert_between(id, 672, 687, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), ProspectSpacePage.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id))
		assert_true(BlockIds.is_valid(id), "%s can be placed" % BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s is solid" % BlockIds.display_name(id))
		assert_ne(BlockIds.display_name(id), "", "id %d has a name" % id)
		assert_false(ItemIds.is_item(id), "%d is no item's" % id)
	assert_gte(BlockIds.COUNT, 688, "past the riches of space (Saturn's rings' page 40 came next)")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 688)
	assert_eq(BlockLibrary.page_of(688), 40, "the next page is 40")


func test_the_pages_held_for_others_are_theirs() -> void:
	for id in range(624, 656):   # the New Seven Wonders' pages 36-37 (another agent's)
		assert_false(id in ProspectSpacePage.TILES, "id %d is the New Seven Wonders'" % id)
	for id in range(656, 672):
		assert_false(id in ProspectSpacePage.TILES, "id %d is Venus's" % id)
		assert_eq(BlockLibrary.page_of(id), 38)


func test_the_library_builds_each_block_with_its_pages_material() -> void:
	var lib := BlockLibrary.build()
	for id: int in ProspectSpacePage.TILES:
		var m: VoxelBlockyModel = lib.models[id]
		assert_true(m is VoxelBlockyModelCube, BlockIds.display_name(id))
		var kind: StringName = ProspectSpacePage.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(ProspectSpacePage.PAGE, kind),
			BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(ProspectSpacePage.TILES[id][i]))


func test_both_pictures_have_every_tile_drawn() -> void:
	var pixel := (load(ProspectSpacePage.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128))
	var real := (load(ProspectSpacePage.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	var normal := (load(ProspectSpacePage.FILES[2]) as Texture2D).get_image()
	assert_eq(real.get_width(), 2048)
	assert_eq(normal.get_width(), 1024, "the normal map is imported at half size (M5 Task 3)")
	var rows := BlockLibrary.texture_rows(load(ProspectSpacePage.FILES[1]) as Texture2D)
	assert_eq(rows, 4, "the page draws four rows")
	for id: int in ProspectSpacePage.TILES:
		for i in 3:
			var t: Vector2i = ProspectSpacePage.TILES[id][i]
			assert_lt(t.y, rows, "%s's tile %s is in the realistic page's rows" % [BlockIds.display_name(id), t])
			assert_gt(_mean(pixel, t).a, 0.9, "%s's tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(_mean_real(real, t).a, 0.9, "%s's realistic tile %s is drawn" % [BlockIds.display_name(id), t])


## What a child learns to read: ice is pale, mare dust darker than the Moon's own dust, ilmenite near black, Mars's
## ground ice pale over red dust, blueberry soil red, dark sand dark, the salt crust pale, titanium silvery grey.
func test_each_block_looks_like_what_it_is() -> void:
	var pixel := (load(ProspectSpacePage.FILES[0]) as Texture2D).get_image()
	var moon := (load(MoonBlocks.FILES[0]) as Texture2D).get_image()
	var ice := _mean(pixel, ProspectSpacePage.TILES[BlockIds.ICY_REGOLITH][0])
	assert_gt(ice.v, 0.5, "icy regolith glints pale (%s)" % ice)
	var mare := _mean(pixel, ProspectSpacePage.TILES[BlockIds.MARE_DUST][0])
	var dust := _mean(moon, MoonBlocks.TILES[BlockIds.MOON_DUST][0])
	assert_lt(mare.v, dust.v - 0.12, "the dark seas' dust is darker than the Moon's own (%s < %s)" % [mare, dust])
	var ilmenite := _mean(pixel, ProspectSpacePage.TILES[BlockIds.ILMENITE][1])
	assert_lt(ilmenite.v, 0.35, "ilmenite is near black (%s)" % ilmenite)
	var ground_ice := _mean(pixel, ProspectSpacePage.TILES[BlockIds.GROUND_ICE][0])
	assert_gt(ground_ice.v, 0.7, "Mars's ground ice is white (%s)" % ground_ice)
	var soil := _mean(pixel, ProspectSpacePage.TILES[BlockIds.BLUEBERRY_SOIL][0])
	assert_gt(soil.r, soil.b + 0.15, "blueberry soil is Mars's red (%s)" % soil)
	var sand := _mean(pixel, ProspectSpacePage.TILES[BlockIds.DARK_SAND][0])
	assert_lt(sand.v, 0.35, "dark sand is dark (%s)" % sand)
	var salt := _mean(pixel, ProspectSpacePage.TILES[BlockIds.MARS_SALT][0])
	assert_gt(salt.v, 0.75, "the salt crust is pale (%s)" % salt)
	var titanium := _mean(pixel, ProspectSpacePage.TILES[BlockIds.TITANIUM][1])
	assert_lt(titanium.s, 0.2, "titanium is silvery grey (%s)" % titanium)
	assert_gt(titanium.v, 0.5)


func test_names_are_what_a_child_says() -> void:
	assert_eq(BlockIds.display_name(BlockIds.ICY_REGOLITH), "Icy Regolith")
	assert_eq(BlockIds.display_name(BlockIds.KREEP_ROCK), "KREEP Rock")
	assert_eq(BlockIds.display_name(BlockIds.HELIUM_3), "Helium-3")
	assert_eq(BlockIds.display_name(BlockIds.HYDROGEN_FUEL), "Hydrogen Fuel")
	assert_eq(BlockIds.display_name(BlockIds.SOLAR_OVEN), "Solar Oven")


## The riches found in the ground are the planets' own (the wand never wakes them, bots' builds may lean on them, never
## painted); what is made, and the Solar Oven, are a child's.
func test_the_found_blocks_are_the_worlds_own_ground() -> void:
	assert_eq(ProspectSpacePage.FOUND.size() + ProspectSpacePage.MADE.size() + 1, 16)
	for id in ProspectSpacePage.FOUND:
		assert_false(CaptureRules.is_capturable(id), "%s is ground" % BlockIds.display_name(id))
		assert_has(BotRules.NATURAL, id)
	for id in ProspectSpacePage.MADE + [BlockIds.SOLAR_OVEN]:
		assert_true(CaptureRules.is_capturable(id), "%s is built" % BlockIds.display_name(id))
		assert_does_not_have(BotRules.NATURAL, id)
	assert_has(PaintRules.JOB_PAGES, ProspectSpacePage.PAGE, "never painted: painted ice would hide what it is")


## Survivor: the ores need the pickaxe their plain ore needs (iron's: wood); dust, soil, sand and salt come by hand.
func test_what_digs_them() -> void:
	for id: int in [BlockIds.ICY_REGOLITH, BlockIds.ILMENITE, BlockIds.KREEP_ROCK, BlockIds.IRON_METEORITE,
			BlockIds.GROUND_ICE, BlockIds.HEMATITE]:
		assert_eq(GatherRules.NEEDS_TIER.get(id, GatherRules.NONE), GatherRules.WOOD, BlockIds.display_name(id))
	for id: int in [BlockIds.MARE_DUST, BlockIds.BLUEBERRY_SOIL, BlockIds.DARK_SAND, BlockIds.MARS_SALT]:
		assert_eq(GatherRules.NEEDS_TIER.get(id, GatherRules.NONE), GatherRules.NONE, BlockIds.display_name(id))


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
