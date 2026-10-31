extends GutTest
## M2 Task 7: where Tilly's stall stands (flat ground 12 blocks from the world spawn, deterministic
## from the seed, Survivor worlds only), and how close a player must be to trade.

const SPAWN := Vector2i(40, -8)


static func _flat(_x: int, _z: int) -> int:
	return 30


static func _dry(_x: int, _z: int) -> bool:
	return true


static func _no_trees(_x: int, _z: int) -> bool:
	return false


static func _cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.z))


func _heights_around(c: Vector2i, height_at: Callable) -> Array[int]:
	var hs: Array[int] = []
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			hs.append(int(height_at.call(c.x + dx, c.y + dz)))
	return hs


func test_only_survivor_worlds_have_a_trader() -> void:
	assert_true(TraderRules.wants_trader(ModeRules.SURVIVOR))
	assert_false(TraderRules.wants_trader(ModeRules.SANDBOX))


func test_the_stall_stands_12_blocks_from_the_spawn_on_the_ground_facing_it() -> void:
	var spot := TraderRules.stall_spot(7, SPAWN, _flat, _dry, _no_trees)
	var pos: Vector3 = spot.pos
	var c := _cell(pos)
	assert_almost_eq(Vector2(c).distance_to(Vector2(SPAWN)), 12.0, 0.75)
	assert_eq(pos.y, 30.0, "feet on the ground")
	assert_eq(Vector2(pos.x, pos.z), Vector2(c) + Vector2(0.5, 0.5), "in the middle of a cell")
	var front := Vector3(-sin(spot.yaw), 0, -cos(spot.yaw))   # the stall's -Z
	var to_spawn := (Vector3(SPAWN.x + 0.5, 0, SPAWN.y + 0.5) - Vector3(pos.x, 0, pos.z)).normalized()
	assert_gt(front.dot(to_spawn), 0.99, "Tilly faces the spawn")


func test_the_spot_is_deterministic_from_the_seed() -> void:
	var a := TraderRules.stall_spot(1234, SPAWN, _flat, _dry, _no_trees)
	assert_eq(TraderRules.stall_spot(1234, SPAWN, _flat, _dry, _no_trees), a)
	var spots := {}
	for s in 8:
		spots[TraderRules.stall_spot(s * 7919, SPAWN, _flat, _dry, _no_trees).pos] = true
	assert_gt(spots.size(), 1, "different worlds put her in different places")


func test_the_stall_needs_level_ground() -> void:
	# Bumpy everywhere except a level patch at the far side of the ring.
	var patch := SPAWN + Vector2i(-12, 0)
	var bumpy := func(x: int, z: int) -> int:
		if absi(x - patch.x) <= 2 and absi(z - patch.y) <= 2:
			return 30
		return 30 + (x * 7 + z * 13) % 3
	var c := _cell(TraderRules.stall_spot(99, SPAWN, bumpy, _dry, _no_trees).pos)
	assert_eq(_heights_around(c, bumpy), [30, 30, 30, 30, 30, 30, 30, 30, 30] as Array[int], "3 x 3 level cells")


func test_the_stall_keeps_out_of_water_and_away_from_trees() -> void:
	var tree := SPAWN + Vector2i(12, 0)
	var trees := func(x: int, z: int) -> bool: return Vector2i(x, z) == tree
	var dry_north := func(_x: int, z: int) -> bool: return z < SPAWN.y   # the whole south half is sea
	var c := _cell(TraderRules.stall_spot(5, SPAWN, _flat, dry_north, trees).pos)
	assert_lt(c.y, SPAWN.y - 1, "all of the stall on dry land")
	assert_gt(maxi(absi(c.x - tree.x), absi(c.y - tree.y)), TraderRules.CLEAR_RADIUS, "no trunk next to the stall")


func test_with_no_good_spot_she_still_comes() -> void:
	var nowhere := func(_x: int, _z: int) -> bool: return false
	var spot := TraderRules.stall_spot(3, SPAWN, _flat, nowhere, _no_trees)
	assert_almost_eq(Vector2(_cell(spot.pos)).distance_to(Vector2(SPAWN)), 12.0, 0.75)


func test_real_worlds_get_a_level_dry_spot() -> void:
	for world_seed: int in [1, 42, 777, 20260924]:
		var shape := MeadowsShape.new(world_seed)
		var spawn := shape.spawn_column()
		var spot := TraderRules.stall_for_world(world_seed, shape, spawn)
		var c := _cell(spot.pos)
		var hs := _heights_around(c, shape.height_at)
		assert_eq(hs.min(), hs.max(), "seed %d: level" % world_seed)
		assert_gt(hs[0], MeadowsShape.SEA_LEVEL + 1, "seed %d: dry land, not a beach" % world_seed)
		assert_eq(int(spot.pos.y), hs[0], "seed %d: on the ground" % world_seed)
		assert_eq(TraderRules.stall_for_world(world_seed, shape, spawn), spot, "seed %d: the same every time" % world_seed)


func test_a_new_survivor_world_gets_her_stall_once_and_keeps_it() -> void:
	var meta := WorldMeta.new()
	meta.seed = 42
	var shape := MeadowsShape.new(meta.seed)
	assert_true(TraderRules.place_in(meta, ModeRules.SURVIVOR, shape, shape.spawn_column()))
	assert_true(meta.has_trader())
	var spot := TraderRules.stall_for_world(meta.seed, shape, shape.spawn_column())
	assert_eq(meta.trader_pos, spot.pos)
	assert_eq(meta.trader_yaw, spot.yaw)
	meta.trader_pos = Vector3(1.5, 40, 2.5)   # a saved stall stays where it was saved
	assert_true(TraderRules.place_in(meta, ModeRules.SURVIVOR, shape, shape.spawn_column()))
	assert_eq(meta.trader_pos, Vector3(1.5, 40, 2.5))


func test_sandbox_worlds_never_get_a_trader() -> void:
	var meta := WorldMeta.new()
	var shape := MeadowsShape.new(meta.seed)
	assert_false(TraderRules.place_in(meta, ModeRules.SANDBOX, shape, shape.spawn_column()))
	assert_false(meta.has_trader())


func test_the_spawn_data_shows_the_hint_until_the_first_visit() -> void:
	var meta := WorldMeta.new()
	meta.trader_pos = Vector3(3.5, 30, 4.5)
	meta.trader_yaw = 0.5
	assert_eq(TraderRules.spawn_data(meta), {"pos": Vector3(3.5, 30, 4.5), "yaw": 0.5, "hint": true})
	meta.trader_visited = true
	assert_false(TraderRules.spawn_data(meta).hint)


func test_trading_needs_the_player_near_tilly() -> void:
	var tilly := Vector3(10.5, 30, 4.5)
	var chest := tilly + Vector3(0, TraderRules.CHEST_HEIGHT, 0)
	assert_true(TraderRules.in_reach(chest + Vector3(0, 0, -3), tilly, TraderRules.TAP_REACH))
	assert_false(TraderRules.in_reach(chest + Vector3(0, 0, -(TraderRules.TAP_REACH + 0.5)), tilly, TraderRules.TAP_REACH))
	assert_gt(TraderRules.HOST_REACH, TraderRules.TAP_REACH, "the host allows for network lag")
	assert_false(TraderRules.in_reach(Vector3(NAN, 0, 0), tilly, TraderRules.HOST_REACH))


func test_a_tap_ray_finds_tilly() -> void:
	var tilly := Vector3(0.5, 30, 0.5)
	var eye := Vector3(0.5, 31.6, -4.0)
	var at_her := (tilly + Vector3(0, 1.2, 0) - eye).normalized()
	var d := TraderRules.ray_hit(eye, at_her, tilly)
	assert_gt(d, 3.0)
	assert_lt(d, 5.0)
	assert_eq(TraderRules.ray_hit(eye, Vector3(1, 0, 0), tilly), -1.0, "looking away")
	assert_eq(TraderRules.ray_hit(eye, -at_her, tilly), -1.0, "behind the eye")
