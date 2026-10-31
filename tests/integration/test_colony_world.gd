extends GutTest
## Colonies under domes (owner #77, spec §21c) in the real voxel terrain: a Mars (19) and a Moon (16) world grow their
## colony from the generator (the Great Dome's glass and grass, the lab's bench), its blocks mesh with collision (a child
## stands on the floor, the glass stops a body), and a child's changes to it (a pane broken, a grow lamp placed) go through
## the terrain's SQLite stream and come back, while the rest of the colony is the generator's again.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_colony_world_%d/" % OS.get_process_id()


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


func _open(u: int, dir: String = DIR) -> WorldService:
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(dir, 77, false, u)
	add_child(world)
	var c := (world.generator_shape() as SpaceShape).colony
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(c.centre.x, c.ground + 4, c.centre.y)
	world.add_child(viewer)
	return world


func test_the_colony_grows_in_the_real_terrain_on_both_worlds() -> void:
	for u: int in [SpaceRules.MARS, SpaceRules.MOON]:
		var world := _open(u, "")
		var c := (world.generator_shape() as SpaceShape).colony
		assert_not_null(c, "world %d has a colony" % u)
		var g := c.world(7, 7)
		var glass := Vector3i(g.x, c.ground + 2, g.y)
		var lawn := Vector3i(c.centre.x, c.ground - 1, c.centre.y)
		var lab := c.world(ColonyLayout.DOMES[ColonyRules.LAB].x - 1, ColonyLayout.DOMES[ColonyRules.LAB].y + 3)
		var bench := Vector3i(lab.x, c.ground, lab.y)
		await wait_until(func() -> bool: return world.is_editable(glass) and world.is_editable(lawn) \
			and world.is_editable(bench), 20.0, "terrain loads")
		assert_eq(world.get_block(glass), BlockIds.DOME_GLASS, "the Great Dome's glass (%d)" % u)
		assert_eq(world.get_block(lawn), BlockIds.GRASS, "its grass")
		assert_eq(world.get_block(bench), BlockIds.LAB_BENCH, "the lab's bench")
		assert_eq(world.find_standing_y(c.centre.x, c.centre.y), c.ground, "a child stands on the dome's grass")
		world.free()


func test_the_glass_stops_a_body() -> void:
	var world := _open(SpaceRules.MARS, "")
	var c := (world.generator_shape() as SpaceShape).colony
	var g := c.world(7, 7)
	var cell := Vector3i(g.x, c.ground + 2, g.y)
	await wait_until(func() -> bool: return _ray_hits(world, cell), 20.0, "the dome's glass gets its mesh and collision")
	assert_true(_ray_hits(world, cell), "a body is stopped by the dome's glass")
	world.free()


func test_a_childs_changes_save_and_load() -> void:
	var world := _open(SpaceRules.MARS)
	var c := (world.generator_shape() as SpaceShape).colony
	var g := c.world(7, 7)
	var pane := Vector3i(g.x, c.ground + 2, g.y)
	var other := c.world(7, -7)
	var kept := Vector3i(other.x, c.ground + 2, other.y)
	var lamp := Vector3i(c.centre.x + 1, c.ground, c.centre.y + 1)
	await wait_until(func() -> bool: return world.is_editable(pane) and world.is_editable(kept) and world.is_editable(lamp),
		20.0, "terrain loads")
	world.set_block(pane, BlockIds.AIR)
	world.set_block(lamp, BlockIds.GROW_LAMP)
	await world.save_and_wait(5.0)
	world.free()
	var again := _open(SpaceRules.MARS)
	await wait_until(func() -> bool: return again.is_editable(pane) and again.is_editable(kept) and again.is_editable(lamp),
		20.0, "terrain loads again")
	assert_eq(again.get_block(pane), BlockIds.AIR, "the broken pane stays broken")
	assert_eq(again.get_block(lamp), BlockIds.GROW_LAMP, "the grow lamp comes back")
	assert_eq(again.get_block(kept), BlockIds.DOME_GLASS, "the rest is the colony as it was built")
	again.free()


func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 2, 0), c + Vector3(0, -0.4, 0), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
