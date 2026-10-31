extends GutTest
## M3 Task 17 (spec §5.12, §14.12): where the Theater stands. About 30 blocks from the world spawn
## on flat, dry ground without trees; the same place for the same seed; clear of the spawn, the M2
## trader's stall (12 blocks out) and the Totem (20 blocks out); its door faces the spawn; saved.

const SEEDS := [12345, 1, 42, 777, 20260923, 99991, 31337, 2024]


func _heights_ok(shape: MeadowsShape, site: Dictionary) -> String:
	var c: Vector3i = site.pos
	var lo := 1 << 30
	var hi := -(1 << 30)
	for x in range(c.x - TheaterSite.HALF, c.x + TheaterSite.HALF + 1):
		for z in range(c.z - TheaterSite.HALF, c.z + TheaterSite.HALF + 1):
			var h := shape.height_at(x, z)
			lo = mini(lo, h)
			hi = maxi(hi, h)
			if h <= MeadowsShape.SEA_LEVEL + 1 or shape.is_river(x, z):
				return "wet at %d,%d" % [x, z]
	if hi - lo > TheaterSite.MAX_STEP:
		return "not flat: %d..%d" % [lo, hi]
	if c.y != hi:
		return "floor %d is not the highest ground %d" % [c.y, hi]
	var m := TheaterSite.HALF + TheaterSite.TREE_MARGIN
	for x in range(c.x - m, c.x + m + 1):
		for z in range(c.z - m, c.z + m + 1):
			if shape.tree_at(x, z):
				return "tree at %d,%d" % [x, z]
	return ""


func test_real_worlds_get_a_theater_on_flat_dry_ground_about_30_blocks_out() -> void:
	var found := 0
	var near := 0
	for s: int in SEEDS:
		var shape := MeadowsShape.new(s)
		var spawn := shape.spawn_column()
		var site := TheaterSite.pick_for(shape)
		if site.is_empty():
			gut.p("seed %d: no site" % s)
			continue
		found += 1
		var c: Vector3i = site.pos
		var d := Vector2(c.x - spawn.x, c.z - spawn.y).length()
		gut.p("seed %d: spawn %s theater %s facing %d, %.1f blocks out" % [s, spawn, c, site.facing, d])
		assert_eq(_heights_ok(shape, site), "", "seed %d" % s)
		assert_between(d, float(TheaterSite.RADII.min()) - 0.5, float(TheaterSite.FAR_RADII.max()) + 0.5, "seed %d: near the spawn" % s)
		if d <= TheaterSite.RADII.max() + 0.5:
			near += 1
		assert_gte(TheaterSite.edge_distance(Vector2i(c.x, c.z), spawn), float(TheaterSite.MIN_EDGE_FROM_SPAWN),
			"seed %d: the building's nearest wall is beyond the Totem's ring" % s)
	assert_eq(found, SEEDS.size(), "every one of these worlds has a Theater")
	assert_gte(near, SEEDS.size() - 2, "most of them about 30 blocks out")


func test_the_same_seed_gives_the_same_place() -> void:
	for s: int in [12345, 42]:
		var a := TheaterSite.pick_for(MeadowsShape.new(s))
		var b := TheaterSite.pick_for(MeadowsShape.new(s))
		assert_eq(a, b)


func test_the_building_stays_clear_of_the_spawn_trader_and_totem() -> void:
	assert_eq(TheaterSite.MIN_EDGE_FROM_SPAWN, 24, "4 blocks past the Totem (20), 12 past the trader (12)")
	assert_gt(TheaterSite.MIN_EDGE_FROM_SPAWN, TheaterSite.TOTEM_DISTANCE)
	assert_gt(TheaterSite.MIN_EDGE_FROM_SPAWN, TheaterSite.TRADER_DISTANCE)
	assert_gt(TheaterSite.MIN_EDGE_FROM_SPAWN, TheaterSite.SPAWN_CLEAR, "never inside the spawn clearing")
	# Every spot of a 20-block ring (where the Totem and the trader stand) stays 4 blocks from the walls.
	for s: int in SEEDS:
		var shape := MeadowsShape.new(s)
		var site := TheaterSite.pick_for(shape)
		if site.is_empty():
			continue
		var spawn := shape.spawn_column()
		var c := Vector2i(site.pos.x, site.pos.z)
		for i in 72:
			var a := TAU * i / 72.0
			for r: int in [TheaterSite.TRADER_DISTANCE, TheaterSite.TOTEM_DISTANCE]:
				var p := spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
				assert_gte(TheaterSite.edge_distance(c, p), 3.0, "seed %d: %s" % [s, p])


func test_known_spots_are_avoided() -> void:
	var flat := func(_x: int, _z: int) -> int: return 40
	var dry := func(_x: int, _z: int) -> bool: return true
	var no_tree := func(_x: int, _z: int) -> bool: return false
	var first := TheaterSite.pick(Vector2i.ZERO, 5, flat, dry, no_tree)
	assert_false(first.is_empty())
	var avoid := Vector2i(first.pos.x, first.pos.z)
	var second := TheaterSite.pick(Vector2i.ZERO, 5, flat, dry, no_tree, [avoid])
	assert_false(second.is_empty())
	assert_gte(TheaterSite.edge_distance(Vector2i(second.pos.x, second.pos.z), avoid), float(TheaterSite.KEEP_CLEAR))


## Seen from the spawn, the Theater never stands right behind a landmark near it (Tilly's stall, the
## Totem): in the 0.3.0 desert its sign hid behind the SHOP sign (M2 dev log 19:30). A landmark within
## LANDMARK_NEAR blocks of the spawn keeps SIGHT_GAP degrees of directions free.
func test_seen_from_the_spawn_the_theater_is_not_behind_a_landmark() -> void:
	var flat := func(_x: int, _z: int) -> int: return 40
	var dry := func(_x: int, _z: int) -> bool: return true
	var no_tree := func(_x: int, _z: int) -> bool: return false
	for s: int in SEEDS:
		var free := TheaterSite.pick(Vector2i.ZERO, s, flat, dry, no_tree)
		var c := Vector2(free.pos.x, free.pos.z)
		var stall := Vector2i((c.normalized() * 12.0).round())   # a stall right in front of that spot
		var site := TheaterSite.pick(Vector2i.ZERO, s, flat, dry, no_tree, [stall])
		assert_false(site.is_empty())
		var dir := Vector2(site.pos.x, site.pos.z)
		assert_gte(rad_to_deg(absf(dir.angle_to(Vector2(stall)))), TheaterSite.SIGHT_GAP - 0.01, "seed %d" % s)
	var far := Vector2i(200, 0)   # a spot far out hides nothing
	var site := TheaterSite.pick(Vector2i.ZERO, 7, flat, dry, no_tree, [far])
	assert_false(site.is_empty())


func test_flat_ground_at_30_blocks_facing_the_spawn() -> void:
	var flat := func(_x: int, _z: int) -> int: return 40
	var dry := func(_x: int, _z: int) -> bool: return true
	var no_tree := func(_x: int, _z: int) -> bool: return false
	for s: int in SEEDS:
		var site := TheaterSite.pick(Vector2i(100, -50), s, flat, dry, no_tree)
		var c: Vector3i = site.pos
		var d := Vector2(c.x - 100, c.z + 50).length()
		assert_almost_eq(d, 30.0, 1.0, "the first choice is 30 blocks out")
		assert_eq(c.y, 40, "the floor is on the ground")
		var door := TheaterSite.door_dir(site.facing)
		var to_spawn := Vector2(100 - c.x, -50 - c.z).normalized()
		assert_gt(Vector2(door).dot(to_spawn), 0.7, "the door faces the spawn")


func test_the_seed_turns_the_theater_around_the_spawn() -> void:
	var flat := func(_x: int, _z: int) -> int: return 40
	var dry := func(_x: int, _z: int) -> bool: return true
	var no_tree := func(_x: int, _z: int) -> bool: return false
	var places := {}
	for s: int in SEEDS:
		places[TheaterSite.pick(Vector2i.ZERO, s, flat, dry, no_tree).pos] = true
	assert_gt(places.size(), 3, "different worlds, different directions")


func test_no_site_in_the_sea() -> void:
	var low := func(_x: int, _z: int) -> int: return 10
	var wet := func(_x: int, _z: int) -> bool: return false
	var no_tree := func(_x: int, _z: int) -> bool: return false
	assert_eq(TheaterSite.pick(Vector2i.ZERO, 1, low, wet, no_tree), {})


func test_steep_ground_and_trees_are_refused() -> void:
	var steep := func(x: int, _z: int) -> int: return 40 + x   # one block up per block
	var dry := func(_x: int, _z: int) -> bool: return true
	var no_tree := func(_x: int, _z: int) -> bool: return false
	assert_eq(TheaterSite.pick(Vector2i.ZERO, 1, steep, dry, no_tree), {}, "too steep everywhere")
	var flat := func(_x: int, _z: int) -> int: return 40
	var forest := func(_x: int, _z: int) -> bool: return true
	assert_eq(TheaterSite.pick(Vector2i.ZERO, 1, flat, dry, forest), {}, "trees everywhere")


func test_inside_is_the_room_behind_the_door() -> void:
	var site := {"pos": Vector3i(10, 40, -20), "facing": 0}
	assert_true(TheaterSite.is_inside(site, Vector3(10.5, 40.0, -19.5)), "the middle of the room")
	assert_true(TheaterSite.is_inside(site, Vector3(7.2, 41.0, -22.8)), "a back corner")
	assert_false(TheaterSite.is_inside(site, Vector3(10.5, 40.0, -15.2)), "standing in the doorway")
	assert_false(TheaterSite.is_inside(site, Vector3(10.5, 40.0, -14.0)), "in front of the door")
	assert_false(TheaterSite.is_inside(site, Vector3(10.5, 47.5, -19.5)), "on the roof")
	assert_false(TheaterSite.is_inside(site, Vector3(10.5, 36.0, -19.5)), "under the floor")
	assert_false(TheaterSite.is_inside(site, Vector3.INF), "not spawned")
	assert_false(TheaterSite.is_inside({}, Vector3(10.5, 40.0, -19.5)), "no Theater")


func test_the_site_is_saved_and_loaded() -> void:
	var site := {"pos": Vector3i(31, 44, -7), "facing": 3}
	var saved := TheaterSite.to_save(site)
	assert_eq(saved, [31, 44, -7, 3])
	assert_eq(TheaterSite.from_save(saved), site)
	assert_eq(TheaterSite.from_save(JSON.parse_string(JSON.stringify(saved))), site, "through JSON (floats)")
	for bad: Variant in [null, [], [1, 2, 3], [1, 2, 3, 9], ["a", 2, 3, 0], [1.5, 2, 3, 0], [INF, 2, 3, 0], {"pos": 1}, "x"]:
		assert_eq(TheaterSite.from_save(bad), {}, "broken: %s" % [bad])
	assert_eq(TheaterSite.to_save({}), [])


func test_world_meta_keeps_the_theater() -> void:
	var m := WorldMeta.new_random()
	assert_eq(m.theater, [], "a new world has no Theater until it is placed")
	m.theater = [31, 44, -7, 3]
	var q := WorldMeta.from_json(m.to_json())
	assert_eq(q.theater, [31, 44, -7, 3])
	var broken := WorldMeta.from_json('{"version":1,"seed":5,"theater":[1,"x",3,0]}')
	assert_eq(broken.theater, [], "a broken entry is dropped, so the Theater is placed again")
	var old := WorldMeta.from_json('{"version":1,"seed":5}')
	assert_eq(old.theater, [], "worlds from before M3 get one on their next load")
