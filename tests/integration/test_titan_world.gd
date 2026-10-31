extends GutTest
## Cosmos: a world of number 22 is Titan (spec §21b.2). WorldService.setup(..., 22) takes Titan's terrain rules and
## generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn and
## Titan's soil round it; the developer argument opens it. Titan's blocks are the first past the items' ids (400-511):
## the real terrain meshes them (a body stands on them) and its SQLite stream saves and loads them.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_titan_world_%d/" % OS.get_process_id()


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


func test_world_22_is_titan() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 22)
	add_child_autofree(w)
	assert_eq(w.universe, 22)
	assert_eq(w.descriptor().get("name"), &"titan")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.TITAN)
	var ref := SpaceShape.new(77, SpaceShape.TITAN)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_titan_generates_its_landing_pad_and_soil() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 22)
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
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(ground) and w.is_editable(deeper), 15.0,
		"terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_has([BlockIds.TITAN_SOIL, BlockIds.ICE_PEBBLES], w.get_block(ground), "Titan's soil round it")
	assert_eq(w.get_block(ground + Vector3i(0, -1, 0)), BlockIds.TITAN_SOIL, "soil under the top")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	var gen := SpaceGenerator.new()
	gen.planet = SpaceShape.TITAN
	gen.world_seed = 77
	assert_eq(w.get_block(deeper), gen.reference_block(deeper.x, deeper.y, deeper.z), "Titan's generator's block")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func _open_titan() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 77, false, 22)
	add_child(world)
	var sp := world.spawn_column()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(sp.x, world.surface_height(sp.x, sp.y) + 4, sp.y)
	world.add_child(viewer)
	return world


## The big id gap: Titan's blocks (512 and up) go into the real terrain, through its SQLite stream and back.
func test_titans_blocks_save_and_load_past_the_items_ids() -> void:
	var world := _open_titan()
	var sp := world.spawn_column()
	var y := world.surface_height(sp.x, sp.y) + 3
	var cells := {}
	var i := 0
	for id: int in TitanBlocks.TILES:
		cells[Vector3i(sp.x - 5 + i, y, sp.y + 4)] = id
		i += 1
	var first: Vector3i = cells.keys()[0]
	var last: Vector3i = cells.keys()[-1]
	await wait_until(func() -> bool: return world.is_editable(first) and world.is_editable(last), 15.0, "terrain loads")
	for p: Vector3i in cells:
		world.set_block(p, cells[p])
		assert_eq(world.get_block(p), cells[p], "%s placed" % BlockIds.display_name(cells[p]))
	await world.save_and_wait(5.0)
	world.free()
	var again := _open_titan()
	await wait_until(func() -> bool: return again.is_editable(first) and again.is_editable(last), 15.0, "terrain loads again")
	for p: Vector3i in cells:
		assert_eq(again.get_block(p), cells[p], "%s (%d) comes back" % [BlockIds.display_name(cells[p]), cells[p]])
	again.free()


## The mesher builds Titan's blocks (their page's cubes): a body is stopped by one.
func test_titans_blocks_mesh_with_collision() -> void:
	var world := _open_titan()
	var sp := world.spawn_column()
	var cell := Vector3i(sp.x + 2, world.surface_height(sp.x, sp.y) + 6, sp.y - 3)
	await wait_until(func() -> bool: return world.is_editable(cell), 15.0, "terrain loads")
	world.set_block(cell, BlockIds.ICY_ROCK)
	await wait_until(func() -> bool: return _ray_hits(world, cell), 10.0, "Titan's icy rock gets its mesh and collision")
	assert_true(_ray_hits(world, cell), "a body is stopped by icy rock (id %d)" % BlockIds.ICY_ROCK)
	world.set_block(cell, BlockIds.DUNE_SAND)
	await wait_physics_frames(10)
	assert_true(_ray_hits(world, cell), "and by dune grains")
	world.free()


func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 0, -2), c + Vector3(0, 0, 2), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func test_the_developer_argument_opens_titan() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=22"]), 22)
