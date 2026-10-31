extends GutTest
## M3 Task 5 (spec §14.1): the portal hub's stone circle by every Survivor world's spawn. It stands on
## dry, nearly level ground a few steps from the spawn, clear of trees, Tilly's stall and the Totem, found from
## the seed alone (every game of a LAN world puts it in the same place); walking into it opens the hub.

const SPAWN := Vector2i(40, -12)


func _flat(_x: int, _z: int) -> int:
	return 30


func _dry(_x: int, _z: int) -> bool:
	return true


func _no_trees(_x: int, _z: int) -> bool:
	return false


func test_it_stands_a_few_steps_from_the_spawn_on_the_ground() -> void:
	var s := HubRules.circle_spot(7, SPAWN, _flat, _dry, _no_trees, [])
	var d := Vector2(s.pos.x - (SPAWN.x + 0.5), s.pos.z - (SPAWN.y + 0.5)).length()
	assert_between(d, float(HubRules.RADII.min()) - 1.0, float(HubRules.RADII.max()) + 1.0)
	assert_eq(s.pos.y, 30.0, "on the ground")


func test_the_same_world_always_puts_it_in_the_same_place() -> void:
	var a := HubRules.circle_spot(99, SPAWN, _flat, _dry, _no_trees, [])
	var b := HubRules.circle_spot(99, SPAWN, _flat, _dry, _no_trees, [])
	assert_eq(a, b)


func test_it_keeps_clear_of_tilly_and_the_totem() -> void:
	var first := HubRules.circle_spot(5, SPAWN, _flat, _dry, _no_trees, [])
	var avoid: Array[Vector3] = [first.pos]
	var other := HubRules.circle_spot(5, SPAWN, _flat, _dry, _no_trees, avoid)
	assert_gte(Vector2(other.pos.x - first.pos.x, other.pos.z - first.pos.z).length(), HubRules.CLEAR_OF)


func test_it_avoids_water_and_slopes_and_trees() -> void:
	var sea_west := func(x: int, _z: int) -> bool: return x >= SPAWN.x
	var s := HubRules.circle_spot(3, SPAWN, _flat, sea_west, _no_trees, [])
	for dx in range(-2, 3):
		assert_true(sea_west.call(int(floor(s.pos.x)) + dx, 0), "dry under the whole circle")
	var trees_north := func(_x: int, z: int) -> bool: return z < SPAWN.y
	var t := HubRules.circle_spot(3, SPAWN, _flat, _dry, trees_north, [])
	assert_gte(floori(t.pos.z) - HubRules.CLEAR_RADIUS, SPAWN.y, "no trunk inside the circle")


func test_walking_in_and_out() -> void:
	var c := Vector3(10.5, 30, 10.5)
	assert_true(HubRules.inside(c + Vector3(0.8, 0, -0.5), c), "in the middle")
	assert_false(HubRules.inside(c + Vector3(3.0, 0, 0), c), "outside the stones")
	assert_false(HubRules.inside(c + Vector3(0, 6, 0), c), "flying high over it")
	assert_false(HubRules.left(c + Vector3(2.0, 0, 0), c), "still close")
	assert_true(HubRules.left(c + Vector3(4.0, 0, 0), c), "walked away: it opens again next time")


func test_a_real_world_gets_a_circle_away_from_the_stall_and_the_totem() -> void:
	for world_seed in [1, 12345, 777]:
		var shape := MeadowsShape.new(world_seed)
		var spawn := shape.spawn_column()
		var s := HubRules.circle_for_world(world_seed, shape, spawn)
		var stall: Vector3 = TraderRules.stall_for_world(world_seed, shape, spawn).pos
		var totem: Vector3 = WaveRules.totem_for_world(world_seed, shape, spawn, stall).pos
		for p: Vector3 in [stall, totem]:
			assert_gte(Vector2(s.pos.x - p.x, s.pos.z - p.z).length(), HubRules.CLEAR_OF, "seed %d" % world_seed)
		assert_gt(int(s.pos.y), MeadowsShape.SEA_LEVEL + 1, "seed %d: dry land" % world_seed)
