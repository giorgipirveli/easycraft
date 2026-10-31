extends GutTest
## Cosmos: a world of number 20 is Europa (spec §21b.2). WorldService.setup(..., 20) takes Europa's terrain rules and
## generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn and white
## Europa ice round it; a player stands on the pad; the developer argument opens it.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func test_world_20_is_europa() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 20)
	add_child_autofree(w)
	assert_eq(w.universe, 20)
	assert_eq(w.descriptor().get("name"), &"europa")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.EUROPA)
	var ref := SpaceShape.new(77, SpaceShape.EUROPA)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_europa_generates_its_landing_pad_and_white_ice() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 20)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var ice := Vector3i(spawn.x + SpaceShape.FLAT_RADIUS, h - 1, spawn.y)
	var deeper := pad + Vector3i(3, -9, 2)   # in the chunk under the pad's (a busy PC streams it later)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(ice) and w.is_editable(deeper), 15.0,
		"terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_eq(w.get_block(ice), BlockIds.EUROPA_ICE, "white Europa ice round it")
	assert_eq(w.get_block(ice + Vector3i(0, -1, 0)), BlockIds.EUROPA_ICE)
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	var gen := SpaceGenerator.new()
	gen.planet = SpaceShape.EUROPA
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "Europa's generator's block")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func test_the_developer_argument_opens_europa() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=20"]), 20)
