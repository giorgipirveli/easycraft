extends GutTest
## Cosmos: a world of number 25 is Saturn's rings (spec §21b.2). WorldService.setup(..., 25) takes the rings' terrain
## rules and generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn
## on the landing chunk's frosty ice, open space under it (no bedrock) and the Saturn scope by the pad; the developer
## argument opens it. The rings' blocks (page 40) go through the real terrain's SQLite stream and back, and mesh with
## collision. A real player who steps off the landing chunk floats down slowly, and the space suit's little jets carry it
## back to the ice long before the void line.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_rings_world_%d/" % OS.get_process_id()


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


func test_world_25_is_saturns_rings() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 25)
	add_child_autofree(w)
	assert_eq(w.universe, 25)
	assert_eq(w.descriptor().get("name"), &"rings")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.RINGS)
	var ref := SpaceShape.new(77, SpaceShape.RINGS)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_the_rings_generate_the_pad_the_landing_chunk_and_open_space_under_it() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 25)
	add_child_autofree(w)
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	assert_eq(h, RingsTerrain.TOP_BASE)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var frost := Vector3i(spawn.x + 9, h - 1, spawn.y)
	var ice := Vector3i(spawn.x, h - 4, spawn.y)
	var tube := Vector3i(spawn.x, h + 1, spawn.y - RingsTerrain.SCOPE_OUT)
	var under := Vector3i(spawn.x, 20, spawn.y)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(frost) and w.is_editable(tube) \
		and w.is_editable(under), 20.0, "terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_eq(w.get_block(frost), BlockIds.RING_FROST, "the landing chunk's frosty top round it")
	assert_eq(w.get_block(ice), BlockIds.RING_ICE, "ice under the frost")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	assert_eq(w.get_block(tube), BlockIds.TELESCOPE, "the Saturn scope by the pad")
	assert_eq(w.get_block(under), BlockIds.AIR, "open space far under the chunk")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func _open_rings() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 77, false, 25)
	add_child(world)
	var sp := world.spawn_column()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(sp.x, world.surface_height(sp.x, sp.y) + 4, sp.y)
	world.add_child(viewer)
	return world


func test_the_rings_blocks_save_and_load() -> void:
	var world := _open_rings()
	var sp := world.spawn_column()
	var y := world.surface_height(sp.x, sp.y) + 3
	var cells := {}
	var i := 0
	for id: int in RingsBlocks.TILES:
		cells[Vector3i(sp.x - 8 + i, y, sp.y + 4)] = id
		i += 1
	var first: Vector3i = cells.keys()[0]
	var last: Vector3i = cells.keys()[-1]
	await wait_until(func() -> bool: return world.is_editable(first) and world.is_editable(last), 15.0, "terrain loads")
	for p: Vector3i in cells:
		world.set_block(p, cells[p])
		assert_eq(world.get_block(p), cells[p], "%s placed" % BlockIds.display_name(cells[p]))
	await world.save_and_wait(5.0)
	world.free()
	var again := _open_rings()
	await wait_until(func() -> bool: return again.is_editable(first) and again.is_editable(last), 15.0, "terrain loads again")
	for p: Vector3i in cells:
		assert_eq(again.get_block(p), cells[p], "%s (%d) comes back" % [BlockIds.display_name(cells[p]), cells[p]])
	again.free()


func test_the_rings_blocks_mesh_with_collision() -> void:
	var world := _open_rings()
	var sp := world.spawn_column()
	var cell := Vector3i(sp.x + 2, world.surface_height(sp.x, sp.y) + 6, sp.y - 3)
	await wait_until(func() -> bool: return world.is_editable(cell), 15.0, "terrain loads")
	world.set_block(cell, BlockIds.RING_ICE)
	await wait_until(func() -> bool: return _ray_hits(world, cell), 10.0, "ring ice gets its mesh and collision")
	assert_true(_ray_hits(world, cell), "a body is stopped by ring ice (id %d)" % BlockIds.RING_ICE)
	world.set_block(cell, BlockIds.RING_BEACON)
	await wait_physics_frames(10)
	assert_true(_ray_hits(world, cell), "and by a beacon")
	world.free()


func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 0, -2), c + Vector3(0, 0, 2), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## A real player on the landing chunk steps off its edge into the open space between the chunks: it floats down slowly
## (0.05 of Earth's gravity), and long before it could reach anything (the void line under every chunk) the space suit's
## little jets carry it back to where it last stood, unhurt.
func test_a_player_who_steps_off_is_carried_back_to_the_ice() -> void:
	var world := _open_rings()
	LabRules.world_gravity = 0.05
	var r := (world.generator_shape() as SpaceShape).rings
	var sp := world.spawn_column()
	var edge := sp + Vector2i(0, -16)
	var beyond := Vector2i.ZERO
	for k in range(26, 120):   # the first column of open space north of the landing chunk (and round it)
		var c := sp + Vector2i(0, -k)
		var clear := true
		for d: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			clear = clear and r.kind_at(c.x + d.x, c.y + d.y) == RingsTerrain.VOID
		if clear:
			beyond = c
			break
	assert_ne(beyond, Vector2i.ZERO, "open space to step into")
	var player: Player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child(player)
	var carried: Array = []
	player.carried_back.connect(func(to: Vector3) -> void: carried.append(to))
	assert_true(player.in_void_world(), "the chunks float over open space")
	player.spawn_at(Vector3(edge.x + 0.5, RingsTerrain.TOP_BASE + 0.05, edge.y + 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 15.0, "spawned on the chunk")
	await wait_seconds(0.8)
	var hp := player.health.hp
	player.global_position = Vector3(beyond.x + 0.5, RingsTerrain.TOP_BASE + 0.5, beyond.y + 0.5)   # off the edge
	player.velocity = Vector3.ZERO
	var t0 := Time.get_ticks_msec()
	var low := [INF]
	await wait_until(func() -> bool:
		low[0] = minf(low[0], player.global_position.y)
		return not carried.is_empty(), 14.0, "the suit's jets carry it back")
	var seconds := (Time.get_ticks_msec() - t0) / 1000.0
	gut.p("RINGS_FALL %.1f s, lowest %.1f" % [seconds, low[0]])
	assert_eq(carried.size(), 1, "once")
	assert_between(seconds, 2.0, 9.0, "a slow float down, then back (%.1f s)" % seconds)
	assert_gt(low[0], RingsTerrain.LIFT_Y - 3.0, "never far under the rings (lowest %.1f)" % low[0])
	var to: Vector3 = carried[0]
	assert_almost_eq(Vector2(to.x, to.z), Vector2(edge.x + 0.5, edge.y + 0.5), Vector2(0.8, 0.8), "back where it stood")
	await wait_until(func() -> bool: return player.is_spawned(), 5.0, "standing again")
	await wait_physics_frames(3)
	assert_gt(player.global_position.y, RingsTerrain.TOP_BASE - 0.5, "on the ice again")
	assert_eq(player.health.hp, hp, "no damage")
	player.free()
	world.free()


func test_the_developer_argument_opens_the_rings() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=25"]), 25)
