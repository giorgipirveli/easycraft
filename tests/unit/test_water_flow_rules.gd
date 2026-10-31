extends GutTest
## Flowing water: falls first, spreads up to 5 blocks on a floor, merges into water below, stops at
## walls, bounded per tick and per flood; starts when water is placed or a block next to water is
## broken; removing water never makes water rush back in.

var world := {}   # Vector3i -> block id; anything missing is AIR, below floor_y is STONE
var floor_y := 0


func _block_at(p: Vector3i) -> int:
	if world.has(p):
		return world[p]
	return BlockIds.STONE if p.y < floor_y else BlockIds.AIR


func before_each() -> void:
	world.clear()
	floor_y = 0


## Runs the simulation to rest, applying fills like the WaterFlow node does. Returns all fills.
func _run(queue: Array[Vector4i], budget: int = 1000) -> Array[Vector4i]:
	var all: Array[Vector4i] = []
	var flood_left := WaterFlowRules.MAX_FLOOD
	for i in 500:
		if queue.is_empty() or flood_left <= 0:
			break
		var r := WaterFlowRules.step(queue, _block_at, budget, flood_left)
		for c: Vector4i in r.fill:
			world[Vector3i(c.x, c.y, c.z)] = BlockIds.WATER
			all.append(c)
		flood_left -= (r.fill as Array).size()
		queue = r.queue
	return all


func _source(p: Vector3i) -> Array[Vector4i]:
	world[p] = BlockIds.WATER
	var q: Array[Vector4i] = [Vector4i(p.x, p.y, p.z, 0)]
	return q


func test_water_falls_before_it_spreads() -> void:
	var r := WaterFlowRules.step(_source(Vector3i(0, 5, 0)), _block_at, 100, 100)
	assert_eq(r.fill, [Vector4i(0, 4, 0, 0)] as Array[Vector4i], "only straight down")


func test_water_spreads_five_blocks_on_a_floor() -> void:
	var fills := _run(_source(Vector3i(0, 0, 0)))
	var farthest := 0
	for c in fills:
		assert_eq(c.y, 0, "stays on the floor")
		var d := absi(c.x) + absi(c.z)
		assert_lte(d, WaterFlowRules.MAX_SPREAD)
		farthest = maxi(farthest, d)
	assert_eq(farthest, WaterFlowRules.MAX_SPREAD)
	assert_eq(fills.size(), 60, "a diamond of radius 5 minus the source")


func test_water_pours_off_a_ledge_and_keeps_its_spread_distance() -> void:
	for x in range(-10, 11):                       # a platform at y = 5 that ends at x = 2
		for z in range(-10, 11):
			if x <= 2:
				world[Vector3i(x, 4, z)] = BlockIds.STONE
	var fills := _run(_source(Vector3i(0, 5, 0)))
	var reached_ground := false
	for c in fills:
		if c.y == 0:
			reached_ground = true
			assert_lte(absi(c.x) + absi(c.z), WaterFlowRules.MAX_SPREAD, "falling never resets the spread")
	assert_true(reached_ground, "water pours down the edge")


func test_walls_stop_water() -> void:
	for x in range(-2, 3):
		for z in range(-2, 3):
			if absi(x) == 2 or absi(z) == 2:
				world[Vector3i(x, 0, z)] = BlockIds.BRICK
	var fills := _run(_source(Vector3i(0, 0, 0)))
	for c in fills:
		assert_true(absi(c.x) < 2 and absi(c.z) < 2, "inside the wall: %s" % c)
	assert_eq(fills.size(), 8)


func test_water_landing_on_water_merges_instead_of_stacking() -> void:
	for x in range(-8, 9):
		for z in range(-8, 9):
			world[Vector3i(x, 0, z)] = BlockIds.WATER   # a lake
	var fills := _run(_source(Vector3i(0, 6, 0)))
	for c in fills:
		assert_gt(c.y, 0, "nothing is added on top of the lake: %s" % c)
		assert_eq(Vector2i(c.x, c.z), Vector2i.ZERO, "only the falling column")


func test_each_step_is_bounded() -> void:
	var r := WaterFlowRules.step(_source(Vector3i(0, 0, 0)), _block_at, 3, 100)
	assert_eq((r.fill as Array).size(), 3)
	for c: Vector4i in r.fill:
		world[Vector3i(c.x, c.y, c.z)] = BlockIds.WATER
	var rest := _run(r.queue as Array[Vector4i], 3)
	assert_eq((r.fill as Array).size() + rest.size(), 60, "the rest arrives in later steps")


func test_a_flood_is_capped() -> void:
	floor_y = -300                                  # a small platform over a very deep drop
	for x in range(-1, 2):
		for z in range(-1, 2):
			world[Vector3i(x, 0, z)] = BlockIds.STONE
	var fills := _run(_source(Vector3i(0, 1, 0)))
	assert_eq(fills.size(), WaterFlowRules.MAX_FLOOD, "the waterfalls stop at the flood cap")


func test_unloaded_places_are_closed() -> void:
	var loaded := func(p: Vector3i) -> int: return -1 if p.x > 1 else _block_at(p)
	world[Vector3i(0, 0, 0)] = BlockIds.WATER
	var queue: Array[Vector4i] = [Vector4i(0, 0, 0, 0)]
	for i in 20:
		var r := WaterFlowRules.step(queue, loaded, 100, 100)
		for c: Vector4i in r.fill:
			assert_lte(c.x, 1, "never into unloaded terrain")
			world[Vector3i(c.x, c.y, c.z)] = BlockIds.WATER
		queue = r.queue


func test_breaking_a_block_next_to_a_lake_lets_water_in() -> void:
	world[Vector3i(-1, 0, 0)] = BlockIds.WATER
	world[Vector3i(0, 1, 0)] = BlockIds.WATER
	var src := WaterFlowRules.sources_for_change(Vector3i(0, 0, 0), BlockIds.DIRT, BlockIds.AIR, _block_at)
	assert_eq(src.size(), 2, "the lake beside and the water above")
	var fills := _run(src)
	assert_true(fills.has(Vector4i(0, 0, 0, 0)) or world.get(Vector3i(0, 0, 0)) == BlockIds.WATER, "the hole fills")


func test_placed_water_starts_flowing() -> void:
	var src := WaterFlowRules.sources_for_change(Vector3i(3, 0, 3), BlockIds.AIR, BlockIds.WATER, _block_at)
	assert_eq(src, [Vector4i(3, 0, 3, 0)] as Array[Vector4i])


func test_removing_water_never_pulls_water_back() -> void:
	world[Vector3i(1, 0, 0)] = BlockIds.WATER
	assert_eq(WaterFlowRules.sources_for_change(Vector3i(0, 0, 0), BlockIds.WATER, BlockIds.AIR, _block_at).size(), 0)


func test_water_never_flows_upward() -> void:
	world[Vector3i(0, -1, 0)] = BlockIds.AIR       # a hole below the broken block...
	world[Vector3i(0, -2, 0)] = BlockIds.WATER     # ...with water further down
	assert_eq(WaterFlowRules.sources_for_change(Vector3i(0, -1, 0), BlockIds.DIRT, BlockIds.AIR, _block_at).size(), 0)


## Found in the game: a river's surface water has water below it, and it must still pour into a
## channel dug beside it (it only must not lay a layer on top of water).
func test_lake_water_pours_into_a_channel_dug_beside_it() -> void:
	floor_y = -3
	for x in range(-6, 0):
		for y in range(-3, 1):
			for z in range(-3, 4):
				world[Vector3i(x, y, z)] = BlockIds.WATER   # a lake 4 deep, surface at y = 0
	for x in range(0, 8):
		for y in range(-3, 0):
			world[Vector3i(x, y, 0)] = BlockIds.STONE      # the channel floor at y = -1
	var src := WaterFlowRules.sources_for_change(Vector3i(0, 0, 0), BlockIds.DIRT, BlockIds.AIR, _block_at)
	var fills := _run(src)
	assert_true(fills.has(Vector4i(0, 0, 0, 1)), "the channel's first block fills")
	assert_true(fills.has(Vector4i(4, 0, 0, 5)), "and water runs 5 blocks along it")
	for c in fills:
		assert_ne(_block_at(Vector3i(c.x, c.y - 1, c.z)) == BlockIds.WATER and c.x < 0, true, "no layer on the lake")
