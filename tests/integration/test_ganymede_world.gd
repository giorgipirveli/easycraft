extends GutTest
## Cosmos: a world of number 28 is Ganymede (spec §21b.2). WorldService.setup(..., 28) takes Ganymede's terrain rules and
## generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn, bright
## grooved ice round it and the Jupiter Lookout by it; the developer argument opens it. Ganymede's blocks (page 43) go
## into the real terrain: its mesher builds them (a body is stopped by one) and its SQLite stream saves and loads them.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_ganymede_world_%d/" % OS.get_process_id()


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


func test_world_28_is_ganymede() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 28)
	add_child_autofree(w)
	assert_eq(w.universe, 28)
	assert_eq(w.descriptor().get("name"), &"ganymede")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.GANYMEDE)
	var ref := SpaceShape.new(77, SpaceShape.GANYMEDE)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_ganymede_generates_its_landing_pad_its_bright_ice_and_the_lookout() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 28)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var ground := Vector3i(spawn.x - SpaceShape.FLAT_RADIUS, h - 1, spawn.y)
	var deeper := pad + Vector3i(3, -9, 2)
	var g := (w.generator_shape() as SpaceShape).ganymede
	var scope := Vector3i(g.lookout.x + 1, g.lookout_y + 3, g.lookout.y)
	var crust := ground + Vector3i(0, -3, 0)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(ground) and w.is_editable(deeper) \
		and w.is_editable(scope) and w.is_editable(crust), 15.0, "terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_eq(w.get_block(ground), BlockIds.GROOVED_ICE, "Ganymede's bright ice round it")
	assert_eq(w.get_block(crust), BlockIds.GROOVED_ICE, "bright ice a few blocks down")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	assert_eq(w.get_block(scope), BlockIds.TELESCOPE, "the Jupiter Lookout's telescope")
	var gen := SpaceGenerator.new()
	gen.planet = SpaceShape.GANYMEDE
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "Ganymede's generator's block")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func _open_ganymede() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 77, false, 28)
	add_child(world)
	var sp := world.spawn_column()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(sp.x, world.surface_height(sp.x, sp.y) + 4, sp.y)
	world.add_child(viewer)
	return world


func test_ganymedes_blocks_save_and_load() -> void:
	var world := _open_ganymede()
	var sp := world.spawn_column()
	var y := world.surface_height(sp.x, sp.y) + 3
	var cells := {}
	var i := 0
	for id: int in GanymedeBlocks.TILES:
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
	var again := _open_ganymede()
	await wait_until(func() -> bool: return again.is_editable(first) and again.is_editable(last), 15.0, "terrain loads again")
	for p: Vector3i in cells:
		assert_eq(again.get_block(p), cells[p], "%s (%d) comes back" % [BlockIds.display_name(cells[p]), cells[p]])
	again.free()


func test_ganymedes_blocks_mesh_with_collision() -> void:
	var world := _open_ganymede()
	var sp := world.spawn_column()
	var cell := Vector3i(sp.x + 2, world.surface_height(sp.x, sp.y) + 6, sp.y + 3)
	await wait_until(func() -> bool: return world.is_editable(cell), 15.0, "terrain loads")
	world.set_block(cell, BlockIds.GROOVED_ICE)
	await wait_until(func() -> bool: return _ray_hits(world, cell), 10.0, "grooved ice gets its mesh and collision")
	assert_true(_ray_hits(world, cell), "a body is stopped by grooved ice (id %d)" % BlockIds.GROOVED_ICE)
	world.set_block(cell, BlockIds.AURORA_CRYSTAL)
	await wait_physics_frames(10)
	assert_true(_ray_hits(world, cell), "and by an aurora crystal")
	world.free()


func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 0, -2), c + Vector3(0, 0, 2), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func test_the_developer_argument_opens_ganymede() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=28"]), 28)
