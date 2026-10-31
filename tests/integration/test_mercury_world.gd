extends GutTest
## Cosmos: a world of number 23 is Mercury (spec §21b.2). WorldService.setup(..., 23) takes Mercury's terrain rules and
## generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn, Mercury's
## grey dust round it and the explorers' thermometer by it; the developer argument opens it. Mercury's blocks (page 30,
## past the items' ids) go through the real terrain's SQLite stream and back, and mesh with collision.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_mercury_world_%d/" % OS.get_process_id()


func before_all() -> void:
	_wipe()


func after_all() -> void:
	_wipe()


func after_each() -> void:
	UniverseRegistry.reset()
	LabRules.world_gravity = 1.0


func _wipe() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_world_23_is_mercury() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 23)
	add_child_autofree(w)
	assert_eq(w.universe, 23)
	assert_eq(w.descriptor().get("name"), &"mercury")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.MERCURY)
	var ref := SpaceShape.new(77, SpaceShape.MERCURY)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_mercury_generates_its_landing_pad_its_dust_and_the_thermometer() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 23)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var ground := Vector3i(spawn.x + SpaceShape.FLAT_RADIUS, h - 1, spawn.y)
	var t := (w.generator_shape() as SpaceShape).thermometer_column()
	var bulb := Vector3i(t.x, w.surface_height(t.x, t.y) + 1, t.y)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(ground) and w.is_editable(bulb), 15.0,
		"terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_has([BlockIds.MERCURY_DUST, BlockIds.DARK_DUST, BlockIds.RAY_DUST], w.get_block(ground), "Mercury's dust round it")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	assert_eq(w.get_block(bulb), BlockIds.THERMO_BULB, "the thermometer's red bulb by the pad")
	assert_eq(w.get_block(bulb + Vector3i.UP), BlockIds.THERMOMETER, "and its tube")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func _open_mercury() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 77, false, 23)
	add_child(world)
	var sp := world.spawn_column()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(sp.x, world.surface_height(sp.x, sp.y) + 4, sp.y)
	world.add_child(viewer)
	return world


func test_mercurys_blocks_save_and_load() -> void:
	var world := _open_mercury()
	var sp := world.spawn_column()
	var y := world.surface_height(sp.x, sp.y) + 3
	var cells := {}
	var i := 0
	for id: int in MercuryBlocks.TILES:
		cells[Vector3i(sp.x - 7 + i, y, sp.y + 4)] = id
		i += 1
	var first: Vector3i = cells.keys()[0]
	var last: Vector3i = cells.keys()[-1]
	await wait_until(func() -> bool: return world.is_editable(first) and world.is_editable(last), 15.0, "terrain loads")
	for p: Vector3i in cells:
		world.set_block(p, cells[p])
		assert_eq(world.get_block(p), cells[p], "%s placed" % BlockIds.display_name(cells[p]))
	await world.save_and_wait(5.0)
	world.free()
	var again := _open_mercury()
	await wait_until(func() -> bool: return again.is_editable(first) and again.is_editable(last), 15.0, "terrain loads again")
	for p: Vector3i in cells:
		assert_eq(again.get_block(p), cells[p], "%s (%d) comes back" % [BlockIds.display_name(cells[p]), cells[p]])
	again.free()


func test_mercurys_blocks_mesh_with_collision() -> void:
	var world := _open_mercury()
	var sp := world.spawn_column()
	var cell := Vector3i(sp.x + 2, world.surface_height(sp.x, sp.y) + 6, sp.y - 3)
	await wait_until(func() -> bool: return world.is_editable(cell), 15.0, "terrain loads")
	world.set_block(cell, BlockIds.MERCURY_ROCK)
	await wait_until(func() -> bool: return _ray_hits(world, cell), 10.0, "Mercury rock gets its mesh and collision")
	assert_true(_ray_hits(world, cell), "a body is stopped by Mercury rock (id %d)" % BlockIds.MERCURY_ROCK)
	world.set_block(cell, BlockIds.SUNSHADE)
	await wait_physics_frames(10)
	assert_true(_ray_hits(world, cell), "and by the sunshade")
	world.free()


func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 0, -2), c + Vector3(0, 0, 2), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func test_the_developer_argument_opens_mercury() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=23"]), 23)
