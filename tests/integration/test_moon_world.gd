extends GutTest
## Owner feedback #55 (spec §21): a world of number 16 is the Moon. WorldService.setup(..., 16) takes the Moon's terrain
## rules and generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the
## spawn and moon dust round it; a player stands on the pad; its descriptor's gravity is what the world scene sets.


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func test_world_16_is_the_moon() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 16)
	add_child_autofree(w)
	assert_eq(w.universe, 16)
	assert_eq(w.descriptor().get("name"), &"moon")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq(w.spawn_column(), SpaceShape.new(77, SpaceShape.MOON).spawn_column())
	assert_eq(w.surface_height(10, 20), SpaceShape.new(77, SpaceShape.MOON).height_at(10, 20))


func test_the_moon_generates_its_landing_pad_under_the_spawn() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 16)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var dust := Vector3i(spawn.x + SpaceShape.FLAT_RADIUS, h - 1, spawn.y)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(dust), 15.0, "terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_eq(w.get_block(dust), BlockIds.MOON_DUST, "moon dust round it")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	var gen := SpaceGenerator.new()
	gen.world_seed = 77
	var deeper := pad + Vector3i(3, -6, 2)
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "the Moon's generator's block")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func test_the_developer_argument_opens_the_moon() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=16"]), 16)
