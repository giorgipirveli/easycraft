extends GutTest
## Cosmos: a world of number 24 is Venus's cloud city (spec §21b.2). WorldService.setup(..., 24) takes Venus's terrain
## rules and generator (UniverseRegistry, world.descriptor()); the real voxel terrain has the landing pad under the spawn
## on its cream deck over a float hull, the yellow clouds far below and the cloud scope by the pad; the developer
## argument opens it. Venus's blocks (page 38) go through the real terrain's SQLite stream and back, and mesh with
## collision. A real player who steps off the landing deck falls, and a warm breeze lifts it back to the city.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_venus_world_%d/" % OS.get_process_id()


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


func test_world_24_is_venus() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 24)
	add_child_autofree(w)
	assert_eq(w.universe, 24)
	assert_eq(w.descriptor().get("name"), &"venus")
	assert_true(w.generator_shape() is SpaceShape)
	assert_eq((w.generator_shape() as SpaceShape).planet, SpaceShape.VENUS)
	var ref := SpaceShape.new(77, SpaceShape.VENUS)
	assert_eq(w.spawn_column(), ref.spawn_column())
	assert_eq(w.surface_height(10, 20), ref.height_at(10, 20))


func test_venus_generates_its_pad_its_deck_its_hull_and_the_clouds_below() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 77, false, 24)
	add_child_autofree(w)
	var v := (w.generator_shape() as SpaceShape).venus
	var spawn := w.spawn_column()
	var h := w.surface_height(spawn.x, spawn.y)
	assert_eq(h, VenusTerrain.DECK_Y)
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	viewer.position = Vector3(spawn.x, h, spawn.y)
	w.add_child(viewer)
	var pad := Vector3i(spawn.x, h - 1, spawn.y)
	var deck := Vector3i(spawn.x + 9, h - 1, spawn.y)
	var hull := Vector3i(spawn.x, h - 4, spawn.y)
	var out := -v.north()
	var scope := spawn + out * VenusTerrain.SCOPE_OUT
	var tube := Vector3i(scope.x, h + 1, scope.y)
	var open := spawn + out * 30
	var cloud := Vector3i(open.x, v.cloud_top(open.x, open.y) - 1, open.y)
	await wait_until(func() -> bool: return w.is_editable(pad) and w.is_editable(deck) and w.is_editable(tube) \
		and w.is_editable(cloud), 20.0, "terrain loads")
	assert_eq(w.get_block(pad), BlockIds.LANDING_PAD, "the landing pad under the spawn")
	assert_eq(w.get_block(deck), BlockIds.CLOUD_DECK, "the landing deck round it")
	assert_eq(w.get_block(hull), BlockIds.FLOAT_HULL, "over a float hull")
	assert_eq(w.get_block(pad + Vector3i.UP), BlockIds.AIR)
	assert_eq(w.get_block(tube), BlockIds.TELESCOPE, "the cloud scope by the pad")
	assert_eq(w.get_block(cloud), BlockIds.VENUS_CLOUD, "the yellow clouds far below")
	assert_eq(w.get_block(Vector3i(open.x, 60, open.y)), BlockIds.AIR, "open air between them and the city")
	assert_eq(w.find_standing_y(spawn.x, spawn.y), h, "a child stands on the pad")


func _open_venus() -> WorldService:
	DirAccess.make_dir_recursive_absolute(DIR)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup(DIR, 77, false, 24)
	add_child(world)
	var sp := world.spawn_column()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 32
	viewer.requires_collisions = true
	viewer.position = Vector3(sp.x, world.surface_height(sp.x, sp.y) + 4, sp.y)
	world.add_child(viewer)
	return world


func test_venus_blocks_save_and_load() -> void:
	var world := _open_venus()
	var sp := world.spawn_column()
	var y := world.surface_height(sp.x, sp.y) + 3
	var cells := {}
	var i := 0
	for id: int in VenusBlocks.TILES:
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
	var again := _open_venus()
	await wait_until(func() -> bool: return again.is_editable(first) and again.is_editable(last), 15.0, "terrain loads again")
	for p: Vector3i in cells:
		assert_eq(again.get_block(p), cells[p], "%s (%d) comes back" % [BlockIds.display_name(cells[p]), cells[p]])
	again.free()


func test_venus_blocks_mesh_with_collision() -> void:
	var world := _open_venus()
	var sp := world.spawn_column()
	var cell := Vector3i(sp.x + 2, world.surface_height(sp.x, sp.y) + 6, sp.y - 3)
	await wait_until(func() -> bool: return world.is_editable(cell), 15.0, "terrain loads")
	world.set_block(cell, BlockIds.CLOUD_DECK)
	await wait_until(func() -> bool: return _ray_hits(world, cell), 10.0, "a cloud deck gets its mesh and collision")
	assert_true(_ray_hits(world, cell), "a body is stopped by a cloud deck (id %d)" % BlockIds.CLOUD_DECK)
	world.set_block(cell, BlockIds.BLIMP_SKIN)
	await wait_physics_frames(10)
	assert_true(_ray_hits(world, cell), "and by the blimp's skin")
	world.free()


func _ray_hits(world: WorldService, cell: Vector3i) -> bool:
	var c := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3(0, 0, -2), c + Vector3(0, 0, 2), 1)
	return not world.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## A real player on the landing deck steps off its edge: it falls toward the clouds, and long before them (the void
## line far over them) a warm breeze lifts it back to where it last stood, unhurt.
func test_a_player_who_steps_off_is_lifted_back_to_the_city() -> void:
	var world := _open_venus()
	LabRules.world_gravity = 0.9
	var v := (world.generator_shape() as SpaceShape).venus
	var sp := world.spawn_column()
	var out := -v.north()
	var edge := sp + out * 16
	var player: Player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child(player)
	var carried: Array = []
	player.carried_back.connect(func(to: Vector3) -> void: carried.append(to))
	assert_true(player.in_void_world(), "the city floats over the clouds")
	player.spawn_at(Vector3(edge.x + 0.5, VenusTerrain.DECK_Y + 0.05, edge.y + 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 15.0, "spawned on the deck")
	await wait_seconds(0.8)
	var hp := player.health.hp
	var beyond := sp + out * 40
	player.global_position = Vector3(beyond.x + 0.5, VenusTerrain.DECK_Y + 0.5, beyond.y + 0.5)   # off the edge
	player.velocity = Vector3.ZERO
	var low := [INF]
	await wait_until(func() -> bool:
		low[0] = minf(low[0], player.global_position.y)
		return not carried.is_empty(), 8.0, "the warm breeze lifts it back")
	assert_eq(carried.size(), 1, "once")
	assert_gt(low[0], float(VenusTerrain.CLOUD_HIGH), "never down into the clouds (lowest %.1f)" % low[0])
	var to: Vector3 = carried[0]
	assert_almost_eq(Vector2(to.x, to.z), Vector2(edge.x + 0.5, edge.y + 0.5), Vector2(0.8, 0.8), "back where it stood")
	await wait_until(func() -> bool: return player.is_spawned(), 5.0, "standing again")
	await wait_physics_frames(3)
	assert_gt(player.global_position.y, VenusTerrain.DECK_Y - 0.5, "on the deck again")
	assert_eq(player.health.hp, hp, "no damage")
	player.free()
	world.free()


func test_the_developer_argument_opens_venus() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	assert_eq(main.call(&"_universe_arg", ["--survivor", "--new-world", "--universe=24"]), 24)
