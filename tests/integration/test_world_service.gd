extends GutTest
## Loads a real VoxelTerrain (headless) and edits it through WorldService.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_world_%d/" % OS.get_process_id()

var world: WorldService


func before_each() -> void:
	_wipe()
	DirAccess.make_dir_recursive_absolute(DIR)
	world = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 42)
	add_child_autofree(world)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	viewer.position = Vector3(0, 40, 0)
	world.add_child(viewer)


func after_all() -> void:
	_wipe()


func _wipe() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_set_then_get_block() -> void:
	var pos := Vector3i(2, 40, 3)
	await wait_until(func() -> bool: return world.is_editable(pos), 10.0, "terrain loads")
	world.set_block(pos, BlockIds.BRICK)
	assert_eq(world.get_block(pos), BlockIds.BRICK)


func test_set_block_emits_change_with_old_id() -> void:
	var pos := Vector3i(1, 60, 1)
	await wait_until(func() -> bool: return world.is_editable(pos), 10.0, "terrain loads")
	var old := world.get_block(pos)
	watch_signals(world)
	world.set_block(pos, BlockIds.GLASS)
	assert_signal_emitted_with_parameters(world, "block_changed", [pos, old, BlockIds.GLASS])


func test_surface_height_matches_generator_shape() -> void:
	assert_eq(world.surface_height(10, 20), MeadowsShape.new(42).height_at(10, 20))


func test_raycast_hits_the_ground() -> void:
	var c := world.spawn_column()   # dry land (the origin may be ocean)
	for v: VoxelViewer in world.find_children("*", "VoxelViewer", false, false):
		v.position = Vector3(c.x, 40, c.y)
	var top := world.surface_height(c.x, c.y)
	await wait_until(func() -> bool: return world.is_editable(Vector3i(c.x, top - 1, c.y)), 10.0, "terrain loads")
	var hit := world.raycast(Vector3(c.x + 0.5, top + 5.0, c.y + 0.5), Vector3.DOWN, 20.0)
	assert_not_null(hit)
	if hit:
		assert_true(BlockIds.is_solid(world.get_block(hit.position)) or world.get_block(hit.position) == BlockIds.LEAVES)


func test_placed_water_flows_on_the_host() -> void:
	var c := world.spawn_column()
	for v: VoxelViewer in world.find_children("*", "VoxelViewer", false, false):
		v.position = Vector3(c.x, 40, c.y)
	var pos := Vector3i(c.x, world.surface_height(c.x, c.y) + 12, c.y)   # high above any tree
	await wait_until(func() -> bool: return world.is_editable(pos) and world.is_editable(pos + Vector3i(0, -2, 0)), 10.0, "terrain loads")
	assert_eq(world.get_block(pos + Vector3i.DOWN), BlockIds.AIR)
	world.set_block(pos, BlockIds.WATER)
	await wait_until(func() -> bool: return world.get_block(pos + Vector3i.DOWN) == BlockIds.WATER, 3.0, "water falls")
	assert_eq(world.get_block(pos + Vector3i.DOWN), BlockIds.WATER)


## Cave darkness in one game must never leak into the menu or the next world.
func test_each_world_has_its_own_environment() -> void:
	var other: WorldService = load("res://world/world.tscn").instantiate()
	other.setup("", 42)
	add_child_autofree(other)
	# (An earlier version compared with 0.01 and passed vacuously: the float32 read-back is not 0.01.)
	assert_ne(world.environment(), other.environment(), "separate Environment objects")
	world.environment().ambient_light_energy = 0.37
	assert_false(is_equal_approx(other.environment().ambient_light_energy, 0.37))
	assert_false(is_equal_approx(other.ambience_base.ambient, 0.37))


func test_raycast_from_under_water_reaches_the_floor() -> void:
	var c := world.spawn_column()
	for v: VoxelViewer in world.find_children("*", "VoxelViewer", false, false):
		v.position = Vector3(c.x, 40, c.y)
	var top := world.surface_height(c.x, c.y)
	await wait_until(func() -> bool: return world.is_editable(Vector3i(c.x, top + 11, c.y)) \
			and world.is_editable(Vector3i(c.x, top + 20, c.y)), 10.0, "terrain loads")
	for y in range(top + 12, top + 16):          # a water column high above the ground
		world.set_block(Vector3i(c.x, y, c.y), BlockIds.WATER)
	world.set_block(Vector3i(c.x, top + 11, c.y), BlockIds.BRICK)
	var hit := world.raycast(Vector3(c.x + 0.5, top + 15.5, c.y + 0.5), Vector3.DOWN, 10.0)
	assert_not_null(hit)
	if hit:
		assert_eq(world.get_block(hit.position), BlockIds.BRICK, "the brick under the water, not the water")


## Deferred M1 minor: an edit in terrain that is not loaded does nothing, so it must not announce a
## change (water, undo and buddies listen to block_changed).
func test_set_block_in_unloaded_terrain_changes_nothing() -> void:
	var far := Vector3i(900000, 40, 900000)
	assert_false(world.is_editable(far))
	watch_signals(world)
	world.set_block(far, BlockIds.BRICK)
	assert_signal_not_emitted(world, "block_changed")


## Found on the emulator: the menu's backdrop world applied REALISTIC (the saved style), and the
## Sky inside world.tscn's Environment is shared by every instance, so the next world captured the
## HDRI as its "blocky" sky — a blocky game then showed the photo sky.
func test_each_world_keeps_its_own_blocky_sky() -> void:
	var menu: WorldService = load("res://world/world.tscn").instantiate()
	menu.setup("", 7)
	add_child_autofree(menu)
	menu.apply_style("realistic")
	var game: WorldService = load("res://world/world.tscn").instantiate()
	game.setup("", 8)
	add_child_autofree(game)
	game.apply_style("blocky")
	assert_true(game.environment().sky.sky_material is ProceduralSkyMaterial, "the blocky world shows the painted sky")
	assert_true(menu.environment().sky.sky_material is PanoramaSkyMaterial, "the other world keeps its own")
	BlockLibrary.set_style("blocky")


## Emulator frame spikes (M1b acceptance run 1): the bed scan read 196 cells one locked get_voxel
## at a time (3-7 ms on the desktop, 4 times a second). box_reader copies the box once.
func test_box_reader_reads_the_same_blocks_as_get_block() -> void:
	var c := world.spawn_column()
	var top := world.surface_height(c.x, c.y)
	var origin := Vector3i(c.x - 3, top - 2, c.y - 3)
	var size := Vector3i(7, 4, 7)
	var loaded := func() -> bool:
		for y in size.y:
			for z in size.z:
				for x in size.x:
					if not world.is_editable(origin + Vector3i(x, y, z)):
						return false
		return true
	await wait_until(loaded, 10.0, "terrain loads (every block the box touches)")
	world.set_block(Vector3i(c.x + 1, top + 1, c.y), BlockIds.BED)
	var read := world.box_reader(origin, size)
	var solid := 0
	for y in size.y:
		for z in size.z:
			for x in size.x:
				var p := origin + Vector3i(x, y, z)
				assert_eq(read.call(p), world.get_block(p), "cell %s" % p)
				if BlockIds.is_solid(world.get_block(p)):
					solid += 1
	assert_gt(solid, 0, "the box holds ground, not only air")
	assert_eq(read.call(origin - Vector3i.ONE), BlockIds.AIR, "outside the box reads as air")
