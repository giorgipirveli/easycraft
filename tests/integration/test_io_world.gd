extends GutTest
## Cosmos: a world of number 21 is Io (spec §21b.2). WorldService.setup(..., 21) takes Io's terrain rules and generator
## (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn and sulphur round
## it; a player stands on the pad; the developer argument opens it.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func test_world_21_is_io() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 21)
	add_child_autofree(w)
	assert_eq(w.universe, 21)
	assert_eq(w.descriptor().get("name"), &"io")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.IO)
	var ref := SpaceShape.new(77, SpaceShape.IO)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_io_generates_its_landing_pad_and_sulphur() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 21)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var ground := Vector3i(spawn.x + SpaceShape.FLAT_RADIUS, h - 1, spawn.y)
	var deeper := pad + Vector3i(3, -9, 2)   # in the chunk under the pad's (a busy PC streams it later)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(ground) and w.is_editable(deeper), 15.0,
		"terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_has([BlockIds.SULPHUR, BlockIds.ORANGE_SULPHUR, BlockIds.SULPHUR_FROST], w.get_block(ground), "sulphur round it")
	assert_eq(w.get_block(ground + Vector3i(0, -1, 0)), BlockIds.SULPHUR, "a blanket of sulphur")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	var gen := SpaceGenerator.new()
	gen.planet = SpaceShape.IO
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "Io's generator's block")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func test_the_developer_argument_opens_io() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=21"]), 21)
