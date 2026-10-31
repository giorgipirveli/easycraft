extends GutTest
## Cosmos: a world of number 26 is Pluto (spec §21b.2). WorldService.setup(..., 26) takes Pluto's terrain rules and
## generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn, Pluto's
## frost round it and the Charon Lookout by it; the developer argument opens it. Pluto's blocks (page 41) go into the
## real terrain: its mesher builds them (a body is stopped by one) and its SQLite stream saves and loads them.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_pluto_world_%d/" % OS.get_process_id()


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


func test_world_26_is_pluto() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 26)
	add_child_autofree(w)
	assert_eq(w.universe, 26)
	assert_eq(w.descriptor().get("name"), &"pluto")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.PLUTO)
	var ref := SpaceShape.new(77, SpaceShape.PLUTO)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_pluto_generates_its_landing_pad_frost_and_the_lookout() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 26)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var ground := Vector3i(spawn.x + SpaceShape.FLAT_RADIUS, h - 1, spawn.y)
	var deeper := pad + Vector3i(3, -9, 2)
	var p := (w.generator_shape() as SpaceShape).pluto
	var scope := Vector3i(p.lookout.x - 2, p.lookout_y + 3, p.lookout.y)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(ground) and w.is_editable(deeper) \
		and w.is_editable(scope), 15.0, "terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_eq(w.get_block(ground), BlockIds.PLUTO_FROST, "Pluto's frost round it")
	assert_eq(w.get_block(ground + Vector3i(0, -1, 0)), BlockIds.PLUTO_FROST, "frost under the top")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	assert_eq(w.get_block(scope), BlockIds.TELESCOPE, "the Charon Lookout's telescope")
	var gen := SpaceGenerator.new()
	gen.planet = SpaceShape.PLUTO
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "Pluto's generator's block")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func _open_pluto() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 77, false, 26)
	add_child(world)
	var sp := world.spawn_column()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(sp.x, world.surface_height(sp.x, sp.y) + 4, sp.y)
	world.add_child(viewer)
	return world


func test_plutos_blocks_save_and_load() -> void:
	var world := _open_pluto()
	var sp := world.spawn_column()
	var y := world.surface_height(sp.x, sp.y) + 3
	var cells := {}
	var i := 0
	for id: int in PlutoBlocks.TILES:
		cells[Vector3i(sp.x - 6 + i, y, sp.y + 4)] = id
		i += 1
	var first: Vector3i = cells.keys()[0]
	var last: Vector3i = cells.keys()[-1]
	await wait_until(func() -> bool: return world.is_editable(first) and world.is_editable(last), 15.0, "terrain loads")
	for p: Vector3i in cells:
		world.set_block(p, cells[p])
		assert_eq(world.get_block(p), cells[p], "%s placed" % BlockIds.display_name(cells[p]))
	await world.save_and_wait(5.0)
	world.free()
	var again := _open_pluto()
	await wait_until(func() -> bool: return again.is_editable(first) and again.is_editable(last), 15.0, "terrain loads again")
	for p: Vector3i in cells:
		assert_eq(again.get_block(p), cells[p], "%s (%d) comes back" % [BlockIds.display_name(cells[p]), cells[p]])
	again.free()


func test_plutos_blocks_mesh_with_collision() -> void:
	var world := _open_pluto()
	var sp := world.spawn_column()
	var cell := Vector3i(sp.x + 2, world.surface_height(sp.x, sp.y) + 6, sp.y - 3)
	await wait_until(func() -> bool: return world.is_editable(cell), 15.0, "terrain loads")
	world.set_block(cell, BlockIds.NITROGEN_ICE)
	await wait_until(func() -> bool: return _ray_hits(world, cell), 10.0, "nitrogen ice gets its mesh and collision")
	assert_true(_ray_hits(world, cell), "a body is stopped by nitrogen ice (id %d)" % BlockIds.NITROGEN_ICE)
	world.set_block(cell, BlockIds.THOLIN_DUST)
	await wait_physics_frames(10)
	assert_true(_ray_hits(world, cell), "and by tholin dust")
	world.free()


func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 0, -2), c + Vector3(0, 0, 2), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func test_the_developer_argument_opens_pluto() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=26"]), 26)
