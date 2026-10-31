extends GutTest
## Owner #115 (the S3 brief): the Market Square, a second plaza beside Life Town (Life Town is full after L3c's third
## row), placed by Life Town's own search (MarketPlaza: LifeTown.pick with its layout and the town's site). Its two
## places (the bakery: My Business's shop; the stalls and the Price Board: the Market Square) stand apart from each other
## and from every one of the town's doors (walking up to one never opens another); it is never on the town's plaza nor
## behind it, never on the Theater or the Launch Site; its trees are cleared like the town's and a child's build moves it;
## the world's save keeps it with the town. Measured on the real meadows: Life Town keeps its 6 of 8, and the towns get
## their Market Square.

const SPAWN := Vector2i(0, 0)
const GROUND := 70


func _flat(_x: int, _z: int) -> int:
	return GROUND


func _dry(_x: int, _z: int) -> bool:
	return true


func _no_tree(_x: int, _z: int) -> bool:
	return false


func _cells(site: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for lx in range(MarketPlaza.PLAZA_MIN.x, MarketPlaza.PLAZA_MAX.x + 1):
		for lz in range(MarketPlaza.PLAZA_MIN.y, MarketPlaza.PLAZA_MAX.y + 1):
			out.append(MarketPlaza.to_world(site, Vector2i(lx, lz)))
	return out


func _footprint_cells(site: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for id: String in MarketPlaza.SPOTS:
		var s: Dictionary = MarketPlaza.SPOTS[id]
		for lx in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):
			for lz in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
				out.append(MarketPlaza.to_world(site, Vector2i(lx, lz)))
	return out


func test_the_shop_and_the_market_each_have_their_place() -> void:
	var experiences := {}
	for id: String in MarketPlaza.SPOTS:
		var s: Dictionary = MarketPlaza.SPOTS[id]
		experiences[str(s.experience)] = true
		assert_has(LifeExperience.IDS, str(s.experience))
		assert_false(LifeTown.SPOTS.has(id), id + ": its own name, never one of the town's")
		for other: String in MarketPlaza.SPOTS:
			if other != id:
				assert_gt((s.door as Vector2).distance_to(MarketPlaza.SPOTS[other].door), LifeTown.REACH * 2.0)
	assert_eq(experiences.keys(), ["my_shop", "market_square"])


func test_a_flat_world_gets_it_beside_the_town_facing_the_spawn() -> void:
	for seed_: int in [1, 7, 99, 4242, 31337]:
		var theater := TheaterSite.pick(SPAWN, seed_, _flat, _dry, _no_tree)
		var launch := LaunchSite.pick(SPAWN, seed_, _flat, _dry, _no_tree, theater)
		var town := LifeTown.pick(SPAWN, seed_, _flat, _dry, _no_tree, theater, launch)
		var site := MarketPlaza.pick(SPAWN, seed_, _flat, _dry, _no_tree, town, theater, launch)
		assert_false(site.is_empty(), "seed %d" % seed_)
		assert_eq(site.facing, TheaterSite.facing_towards(Vector2i(site.pos.x, site.pos.z), SPAWN), "its doors face the spawn")
		var s := Vector2i(site.pos.x, site.pos.z)
		var t := Vector2i(town.pos.x, town.pos.z)
		assert_gte(rad_to_deg(absf(Vector2(s - SPAWN).angle_to(Vector2(t - SPAWN)))), LifeTown.TOWN_GAP, "beside the town")
		assert_lt(Vector2(s - t).length(), 50.0, "seed %d: near the town (%.0f m)" % [seed_, Vector2(s - t).length()])
		for c in _cells(site):
			var d := Vector2(c - SPAWN).length()
			assert_between(d, float(LifeTown.MIN_EDGE_FROM_SPAWN) - 0.01, LifeTown.MAX_FROM_SPAWN + 0.01)
		for c in _footprint_cells(site):
			assert_false(LifeTown.on_plaza(town, c), "seed %d: never on the town's plaza" % seed_)
			assert_false(LifeTown.on_launch_site(launch, c))
			assert_gte(TheaterSite.edge_distance(Vector2i(theater.pos.x, theater.pos.z), c), float(LifeTown.CLEAR))
		for other: Dictionary in [theater, launch]:
			var o := Vector2i(other.pos.x, other.pos.z)
			assert_gte(rad_to_deg(absf(Vector2(s - SPAWN).angle_to(Vector2(o - SPAWN)))), LifeTown.PLAZA_SIGHT_GAP)
		assert_eq(MarketPlaza.pick(SPAWN, seed_, _flat, _dry, _no_tree, town, theater, launch), site, "the same each time")


func test_walking_up_to_one_never_opens_another() -> void:
	var town := LifeTown.pick(SPAWN, 4242, _flat, _dry, _no_tree)
	var site := MarketPlaza.pick(SPAWN, 4242, _flat, _dry, _no_tree, town)
	for id: String in MarketPlaza.SPOTS:
		var door := MarketPlaza.door_position(site, id)
		assert_eq(MarketPlaza.near(site, door + Vector3(0.5, 0, 0.3)), id)
		assert_eq(MarketPlaza.experience_at(site, door), str(MarketPlaza.SPOTS[id].experience))
		assert_eq(LifeTown.near(town, door), "", id + ": no town door here")
		for t: String in LifeTown.SPOTS:
			var d := LifeTown.door_position(town, t)
			assert_gt(Vector2(door.x - d.x, door.z - d.z).length(), LifeTown.REACH * 2.0, "%s and the town's %s" % [id, t])
	assert_eq(MarketPlaza.near({}, Vector3.ZERO), "")
	assert_true(MarketPlaza.pick(SPAWN, 1, _flat, _dry, _no_tree, {}).is_empty(), "no town, no Market Square")


func test_trees_are_cleared_and_a_childs_build_moves_it() -> void:
	var town := LifeTown.pick(SPAWN, 8, _flat, _dry, _no_tree)
	var site := MarketPlaza.pick(SPAWN, 8, _flat, _dry, func(_x: int, _z: int) -> bool: return true, town)
	assert_false(site.is_empty(), "a wood still gets its Market Square")
	var bakery := MarketPlaza.to_world(site, Vector2i(-5, -1))
	var trunk := Vector3i(bakery.x, GROUND, bakery.y)
	var read := func(at: Vector3i) -> int:
		if at == trunk:
			return BlockIds.LOG
		return BlockIds.GRASS if at.y < GROUND else BlockIds.AIR
	assert_true(MarketPlaza.natural(site, read))
	var cleared := MarketPlaza.clear_changes(site, read)
	assert_eq(cleared.size(), 1)
	assert_eq(cleared[0][0], trunk)
	var corner := MarketPlaza.to_world(site, Vector2i(0, 0))
	var built := func(at: Vector3i) -> int:
		return BlockIds.PLANKS if at == Vector3i(corner.x, GROUND + 1, corner.y) else (BlockIds.GRASS if at.y < GROUND else BlockIds.AIR)
	assert_false(MarketPlaza.natural(site, built), "a child's planks: it goes elsewhere")


func test_the_save_keeps_the_town_and_its_market_square() -> void:
	var town := LifeTown.pick(SPAWN, 4242, _flat, _dry, _no_tree)
	assert_eq(LifeTown.to_save(town).size(), 4, "a town without its Market Square yet")
	var site := MarketPlaza.pick(SPAWN, 4242, _flat, _dry, _no_tree, town)
	var both := town.duplicate()
	both.market = site
	var saved := LifeTown.to_save(both)
	assert_eq(saved.size(), 8)
	var back := LifeTown.from_save(saved)
	assert_eq(back.pos, town.pos)
	assert_eq(back.market, site)
	assert_eq(LifeTown.from_save(saved.slice(0, 4)), town, "an older save: the town alone")
	var m := WorldMeta.new_random()
	m.life_town = saved
	assert_eq(WorldMeta.from_json(m.to_json()).life_town, saved, "the world's save keeps both")
	var broken := saved.duplicate()
	broken[7] = 9
	assert_false(LifeTown.from_save(broken).has("market"), "a broken Market Square: placed again")


## The brief's measurement: Green Meadows' real generator, the eight seeds Life Town is measured on.
func test_real_meadows_keep_their_town_and_get_their_market_square() -> void:
	var towns := 0
	var markets := 0
	var slowest := 0
	var far := 0.0
	var seeds := [1, 2, 3, 42, 777, 2024, 31337, 123456]
	for s: int in seeds:
		var shape := MeadowsShape.new(s)
		var theater := TheaterSite.pick_for(shape)
		var launch := LaunchSite.pick_for(shape, theater)
		var town := LifeTown.pick_for(shape, theater, launch)
		if town.is_empty():
			continue
		towns += 1
		var t0 := Time.get_ticks_msec()
		var site := MarketPlaza.pick_for(shape, town, theater, launch)
		slowest = maxi(slowest, Time.get_ticks_msec() - t0)
		if site.is_empty():
			continue
		markets += 1
		var apart := Vector2(site.pos.x - town.pos.x, site.pos.z - town.pos.z).length()
		far = maxf(far, apart)
		var sp := shape.spawn_column()
		var deg := func(d: Dictionary) -> float:
			return rad_to_deg(Vector2(d.pos.x - sp.x, d.pos.z - sp.y).angle()) if not d.is_empty() else NAN
		gut.p("SUCCESS3_PLAZA seed %d: %.0f m from the town's middle, %.0f m from the spawn; angles: town %.0f, market %.0f, theater %.0f, launch %.0f"
			% [s, apart, Vector2(site.pos.x - sp.x, site.pos.z - sp.y).length(), deg.call(town), deg.call(site),
			deg.call(theater), deg.call(launch)])
		for id: String in MarketPlaza.SPOTS:
			var w := MarketPlaza.to_world(site, Vector2i((MarketPlaza.SPOTS[id].door as Vector2).floor()))
			assert_true(shape.height_at(w.x, w.y) > MeadowsShape.SEA_LEVEL + 1, "seed %d: %s's door is dry" % [s, id])
	gut.p("SUCCESS3_PLAZA towns %d of %d, Market Squares %d of %d towns, slowest search %d ms, farthest %.0f m from the town"
		% [towns, seeds.size(), markets, towns, slowest, far])
	assert_gte(towns, 6, "Life Town keeps its 6 of 8 (L3c's measurement)")
	assert_gte(markets, towns - 1, "nearly every town gets its Market Square")
	assert_lte(far, 40.0, "beside its town (measured 2026-10-17: 26-34 m from the town's middle)")
