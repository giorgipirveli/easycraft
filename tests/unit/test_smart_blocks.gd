extends GutTest
## M3 Task 7 (spec §14.4, §3a): smart blocks and Game Blocks live on block atlas page 9 (ids 192-207), in
## both styles. The "on" states (a pressed button, a lever or light switch that is on, an open powered door,
## a lit lamp) are made only by power and give back their plain block when broken; an open powered door and
## a coin are walked through; the bounce pad is a strong pad (PadRules). A hotbar slot or a bag holds block
## and item ids alike, so none of them may be an item id.

const ALL := [BlockIds.BUTTON, BlockIds.BUTTON_ON, BlockIds.LEVER, BlockIds.LEVER_ON, BlockIds.POWERED_DOOR,
	BlockIds.POWERED_DOOR_OPEN, BlockIds.LAMP, BlockIds.LAMP_ON, BlockIds.LIGHT_SWITCH, BlockIds.LIGHT_SWITCH_ON,
	BlockIds.TELEPORT_PAD, BlockIds.START, BlockIds.CHECKPOINT, BlockIds.FINISH, BlockIds.COIN, BlockIds.BOUNCE]
const ON_STATES := {BlockIds.BUTTON_ON: BlockIds.BUTTON, BlockIds.LEVER_ON: BlockIds.LEVER,
	BlockIds.POWERED_DOOR_OPEN: BlockIds.POWERED_DOOR, BlockIds.LAMP_ON: BlockIds.LAMP,
	BlockIds.LIGHT_SWITCH_ON: BlockIds.LIGHT_SWITCH}


func test_every_smart_block_is_on_page_9_with_its_own_id() -> void:
	var seen := {}
	for id: int in ALL:
		assert_between(id, 192, 207, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), SmartPage.PAGE, BlockIds.display_name(id))
		assert_false(seen.has(id), "one id each")
		seen[id] = true
		assert_true(BlockIds.is_valid(id), "the host accepts it: %d" % id)
		assert_true(BlockIds.is_breakable(id))
		assert_ne(BlockIds.display_name(id), "")
		assert_false(ItemIds.is_item(id), "%d is no item's id" % id)
		assert_true(SmartPage.TILES.has(id), "drawn: %s" % BlockIds.display_name(id))
	assert_eq(SmartPage.PAGE, 9)


func test_they_stay_out_of_the_block_grid_and_have_their_own_tab_rows() -> void:
	for id: int in ALL:
		assert_false(BlockIds.PLACEABLE.has(id), "the BLOCKS grid keeps its size: %s" % BlockIds.display_name(id))
	var rows: Array = SmartPage.SMART_ROW + SmartPage.GAME_ROW
	for id: int in [BlockIds.BUTTON, BlockIds.LEVER, BlockIds.PRESSURE_PLATE, BlockIds.POWERED_DOOR, BlockIds.LAMP,
			BlockIds.LIGHT_SWITCH, BlockIds.TELEPORT_PAD, BlockIds.START, BlockIds.CHECKPOINT, BlockIds.FINISH,
			BlockIds.COIN, BlockIds.BOUNCE]:
		assert_eq(rows.count(id), 1, "on the SMART tab once: %s" % BlockIds.display_name(id))
	for id: int in ON_STATES:
		assert_false(rows.has(id), "power makes the on states, nobody picks them")


func test_an_open_powered_door_and_a_coin_are_walked_through() -> void:
	assert_false(BlockIds.is_solid(BlockIds.POWERED_DOOR_OPEN))
	assert_false(BlockIds.is_solid(BlockIds.COIN))
	assert_true(BlockIds.is_solid(BlockIds.POWERED_DOOR))
	for id in [BlockIds.BUTTON, BlockIds.LEVER, BlockIds.LAMP, BlockIds.TELEPORT_PAD, BlockIds.START,
			BlockIds.FINISH, BlockIds.CHECKPOINT, BlockIds.BOUNCE]:
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))


func test_the_library_builds_them_with_the_pages_shared_materials() -> void:
	var lib := BlockLibrary.build()
	for id: int in ALL:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, BlockIds.display_name(id))
	for id in [BlockIds.POWERED_DOOR_OPEN, BlockIds.COIN]:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_true(m.collision_aabbs.is_empty(), "%s: no box" % BlockIds.display_name(id))
		assert_false(m.is_mesh_collision_enabled(0), "%s: no physics surface either (M2 Task 8's lesson)" % BlockIds.display_name(id))
		assert_same(m.get_material_override(0), BlockLibrary.page_material(SmartPage.PAGE, &"cutout"))
	var lamp := (lib.models[BlockIds.LAMP_ON] as VoxelBlockyModel).get_material_override(0) as BaseMaterial3D
	assert_same(lamp, BlockLibrary.page_material(SmartPage.PAGE, &"glow"), "a lit lamp glows")
	assert_eq(lamp.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_same((lib.models[BlockIds.LAMP] as VoxelBlockyModel).get_material_override(0),
		BlockLibrary.page_material(SmartPage.PAGE, &"opaque"), "an unlit lamp does not")
	assert_false((lib.models[BlockIds.START] as VoxelBlockyModelCube).collision_aabbs.is_empty(), "START is stood on")


func test_both_styles_share_the_pages_layout() -> void:
	assert_eq((load(SmartPage.FILES[0]) as Texture2D).get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for path: String in [SmartPage.FILES[1], SmartPage.FILES[2]]:
		assert_eq((load(path) as Texture2D).get_width(), 2048 if path == SmartPage.FILES[1] else 1024, path)   # M5 Task 3: normal maps at half size
	for id: int in SmartPage.TILES:
		for t: Vector2i in (SmartPage.TILES[id] as Array).slice(0, 3):
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t))
	var img := (load(SmartPage.FILES[0]) as Texture2D).get_image()
	for id: int in SmartPage.TILES:
		var side: Vector2i = SmartPage.TILES[id][1]
		var drawn := 0
		for y in 16:
			for x in 16:
				if img.get_pixel(side.x * 16 + x, side.y * 16 + y).a > 0.5:
					drawn += 1
		assert_gt(drawn, 40, "%s has a picture" % BlockIds.display_name(id))


func test_the_icons_come_from_the_page() -> void:
	SmartPage.register()
	BlockIcons._cache.erase(BlockIds.START)
	var icon := BlockIcons.icon(BlockIds.START) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, SmartPage.FILES[0])


func test_on_states_give_back_their_plain_block() -> void:
	for id: int in ON_STATES:
		assert_eq(GatherRules.drop(id, GatherRules.NONE), ON_STATES[id], BlockIds.display_name(id))
		assert_eq(GatherRules.cost(id), ON_STATES[id], "an undo of a lever that was switched on gives the lever back")
		assert_eq(GatherRules.change(id, BlockIds.AIR, true, GatherRules.NONE), {ON_STATES[id]: 1})
	for id: int in [BlockIds.BUTTON, BlockIds.TELEPORT_PAD, BlockIds.START, BlockIds.COIN, BlockIds.BOUNCE]:
		assert_eq(GatherRules.drop(id, GatherRules.NONE), id, BlockIds.display_name(id))


## A plate a child bought and placed comes back as a plate (temple plates too: Tilly never buys them).
func test_a_broken_pressure_plate_gives_a_plate() -> void:
	assert_eq(GatherRules.drop(BlockIds.PRESSURE_PLATE, GatherRules.NONE), BlockIds.PRESSURE_PLATE)
	assert_eq(ShopRules.sell_price(BlockIds.PRESSURE_PLATE), 0)


func test_a_bounce_pad_throws_harder_than_a_jump_pad_and_keeps_the_run() -> void:
	assert_true(PadRules.is_pad(BlockIds.BOUNCE))
	var pads := PadRules.new()
	assert_eq(pads.touch(BlockIds.BOUNCE, Vector3(5, 0, 0), Vector3.FORWARD), BlockIds.BOUNCE)
	var v := pads.apply(Vector3(5, 0, 0), BlockIds.BOUNCE)
	assert_gt(v.y, PadRules.LAUNCH_SPEED, "stronger than a jump pad")
	assert_eq(v.y, PadRules.BOUNCE_SPEED)
	assert_eq(v.x, 5.0, "it keeps the run")
	assert_eq(pads.touch(BlockIds.BOUNCE, v, Vector3.FORWARD), 0, "and rests like every pad")
	var under := func(p: Vector3i) -> int: return BlockIds.BOUNCE if p == Vector3i(0, 9, 0) else BlockIds.AIR
	assert_eq(PadRules.pad_under(Vector3(0.5, 10.0, 0.5), 0.3, under), BlockIds.BOUNCE)


func test_tilly_sells_every_smart_block_at_a_fixed_price() -> void:
	var home := ShopRules.catalog(ShopRules.HOME)
	for id: int in SmartPage.SMART_ROW + SmartPage.GAME_ROW + [BlockIds.JUMP_PAD, BlockIds.SPEED_PAD]:
		assert_true(home.has(id), "Tilly sells %s" % BlockIds.display_name(id))
		assert_gt(ShopRules.price(id), 0)
		assert_eq(ShopRules.price(id, 2), ShopRules.price(id) * 2, "scaled per universe")
		assert_eq(ShopRules.sell_price(id), 0, "never bought back: no loop mints gold")
	assert_eq(ShopRules.amount(BlockIds.TELEPORT_PAD), 2, "pads come as a pair")
	for id: int in ON_STATES:
		assert_false(home.has(id))
