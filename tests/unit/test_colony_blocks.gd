extends GutTest
## Colonies under domes (owner #77, spec §21c): the colony's blocks, ids 544-559 on block atlas page 31 (between Mercury's
## page 30 and the rocket parts' page 32), drawn in both styles (data/blocks/pages/colony.png and its realistic twin): the
## domes' glass, white habitat panels and floor tiles, the greenhouse's soil and pink grow lamps, warm lights, fruit
## leaves, the water plant's tank and ice melter, the oxygen maker, the control room's screens and big map, the airlock's
## striped frames, the big rocket's steel, printed regolith (the homes' shield) and a table. Built by the generator in the
## Moon's and Mars's colonies; sold by Tilly there (build your own).

const GLOWS: Array[int] = [BlockIds.GROW_LAMP, BlockIds.COLONY_LIGHT, BlockIds.WATER_TANK, BlockIds.ICE_MELTER,
	BlockIds.OXYGEN_MAKER, BlockIds.CONTROL_SCREEN, BlockIds.COLONY_MAP]
const CUTOUTS: Array[int] = [BlockIds.DOME_GLASS, BlockIds.FRUIT_LEAVES, BlockIds.COLONY_TABLE]


func test_every_colony_block_is_on_page_31() -> void:
	assert_eq(ColonyBlocks.PAGE, 31)
	assert_eq(ColonyBlocks.TILES.size(), 16, "the whole page: 544-559")
	for id in range(544, 560):
		assert_true(ColonyBlocks.TILES.has(id), "id %d is the colony's" % id)
		assert_eq(BlockLibrary.page_of(id), ColonyBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_gte(BlockIds.COUNT, 560, "past the colony's page")
	for other: int in [MercuryBlocks.PAGE, RocketPage.PAGE, MarsBlocks.PAGE, MoonBlocks.PAGE, LabPage.PAGE, TitanBlocks.PAGE]:
		assert_ne(other, ColonyBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	for id: int in ColonyBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = ColonyBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(ColonyBlocks.PAGE, kind), BlockIds.display_name(id))


func test_glass_leaves_and_the_table_are_cut_out_and_the_machines_glow() -> void:
	for id: int in ColonyBlocks.TILES:
		var want: StringName = &"glow" if GLOWS.has(id) else (&"cutout" if CUTOUTS.has(id) else &"opaque")
		assert_eq(ColonyBlocks.TILES[id][3], want, BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s is solid (a child stands on it)" % BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(ColonyBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


## The domes are one smooth sheet of glass: glass hides the faces between two glass blocks (its own transparency index,
## culling its neighbours), while the ground and the plants behind it still show through.
func test_dome_glass_is_one_clear_sheet() -> void:
	var lib := BlockLibrary.build()
	var glass := lib.models[BlockIds.DOME_GLASS] as VoxelBlockyModel
	assert_eq(glass.transparency_index, ColonyBlocks.GLASS_TRANSPARENCY)
	assert_eq(ColonyBlocks.GLASS_TRANSPARENCY, 7, "1-6 are taken (leaves, glass, water, the desert's, frosted/sugar, starglass)")
	assert_true(glass.culls_neighbors, "no inner faces between two panes")
	var leaves := lib.models[BlockIds.FRUIT_LEAVES] as VoxelBlockyModel
	assert_eq(leaves.transparency_index, 1, "leaves like every tree's")
	var starglass := lib.models[BlockIds.STARGLASS] as VoxelBlockyModel
	assert_false(starglass.culls_neighbors, "the other pages' cut-outs are as they were")


func test_both_styles_draw_every_tile() -> void:
	assert_eq(ColonyBlocks.FILES, ["res://data/blocks/pages/colony.png", "res://data/blocks/pages/colony_albedo.png",
		"res://data/blocks/pages/colony_normal.png"])
	var pixel := (load(ColonyBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(ColonyBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(ColonyBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(ColonyBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in ColonyBlocks.TILES:
		for i in 3:
			var t: Vector2i = ColonyBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 25 if id == BlockIds.DOME_GLASS else 90, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			var painted := 0
			for p: Vector2i in [Vector2i(128, 128), Vector2i(20, 20), Vector2i(236, 20), Vector2i(20, 236), Vector2i(128, 16)]:
				if real.get_pixel(t.x * 256 + p.x, t.y * 256 + p.y).a > 0.1:
					painted += 1
			assert_gt(painted, 0, "%s tile %s is painted" % [BlockIds.display_name(id), t])


## Glass is mostly clear (a thin frame and a glint), the leaves have fruit in them, the lamps glow pink (red and blue
## light), the panels are white and the rocket silver.
func test_the_colonys_own_look() -> void:
	var pixel := (load(ColonyBlocks.FILES[0]) as Texture2D).get_image()
	var glass: Vector2i = ColonyBlocks.TILES[BlockIds.DOME_GLASS][1]
	var clear := 0
	for y in 16:
		for x in 16:
			if pixel.get_pixel(glass.x * 16 + x, glass.y * 16 + y).a < 0.1:
				clear += 1
	assert_gt(clear, 150, "see-through glass (%d clear pixels)" % clear)
	var lamp := _mean(pixel, ColonyBlocks.TILES[BlockIds.GROW_LAMP][1])
	assert_gt(lamp.r, lamp.g + 0.2, "a pink lamp: red ... (%s)" % lamp)
	assert_gt(lamp.b, lamp.g + 0.1, "... and blue (%s)" % lamp)
	var panel := _mean(pixel, ColonyBlocks.TILES[BlockIds.COLONY_PANEL][1])
	assert_gt(panel.get_luminance(), 0.75, "white panels (%s)" % panel)
	var hull := _mean(pixel, ColonyBlocks.TILES[BlockIds.ROCKET_HULL][1])
	assert_between(hull.get_luminance(), 0.55, 0.9, "shiny steel (%s)" % hull)
	assert_lt(maxf(hull.r, maxf(hull.g, hull.b)) - minf(hull.r, minf(hull.g, hull.b)), 0.12, "silver, not coloured")
	var leaves: Vector2i = ColonyBlocks.TILES[BlockIds.FRUIT_LEAVES][1]
	var orange := 0
	var green := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(leaves.x * 16 + x, leaves.y * 16 + y)
			if c.a < 0.1:
				continue
			if c.r > 0.8 and c.g > 0.35 and c.g < 0.75 and c.b < 0.3:
				orange += 1
			elif c.g > c.r and c.g > c.b:
				green += 1
	assert_gt(orange, 6, "fruit in the leaves (%d)" % orange)
	assert_gt(green, 80, "green leaves (%d)" % green)
	var water := _mean(pixel, ColonyBlocks.TILES[BlockIds.WATER_TANK][1])
	assert_gt(water.b, water.r + 0.1, "a tank of blue water (%s)" % water)


func _mean(img: Image, t: Vector2i) -> Color:
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var n := 0
	for y in 16:
		for x in 16:
			var c := img.get_pixel(t.x * 16 + x, t.y * 16 + y)
			if c.a < 0.1:
				continue
			r += c.r
			g += c.g
			b += c.b
			n += 1
	n = maxi(n, 1)
	return Color(r / n, g / n, b / n)


func test_names_and_validity() -> void:
	for id: int in ColonyBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id), "/give knows %s" % BlockIds.display_name(id))
		assert_true(Inventory.ownable(id), "a bag holds %s" % BlockIds.display_name(id))
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not a planet's ground" % BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.DOME_GLASS), "Dome Glass")
	assert_eq(BlockIds.display_name(BlockIds.GROW_LAMP), "Grow Lamp")
	assert_eq(BlockIds.display_name(BlockIds.OXYGEN_MAKER), "Oxygen Maker")
	assert_eq(BlockIds.display_name(BlockIds.PRINTED_REGOLITH), "Printed Regolith")


## Gifts and showcases carry the colony's blocks (blocks up to 1023, the server's BuildRules the same).
func test_they_travel_in_gifts() -> void:
	for id: int in ColonyBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.DOME_GLASS, Vector3i(1, 0, 0): BlockIds.GROW_LAMP})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.DOME_GLASS)
	assert_eq(back.get(Vector3i(1, 0, 0)), BlockIds.GROW_LAMP)
