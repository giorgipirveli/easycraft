extends GutTest
## M3 Task 15 (spec §14.9): "Pip's playground", laid out near the spawn by pure rules — on level, dry ground with
## no tree, within the treasure pack's 60-block spawn circle (where no treasure place ever stands), clear of the
## spawn, Tilly, the Totem, the stone circle, the Theater and the quest giver; the course's cells (a pad, the hole
## to jump, the hole to bridge, the wall, the bushes, the Workbench) and where the child stands.

const SPAWN := Vector2i(0, 0)


func _flat(h: int = 40) -> Callable:
	return func(_x: int, _z: int) -> int: return h


func _dry() -> Callable:
	return func(_x: int, _z: int) -> bool: return true


func _no_trees() -> Callable:
	return func(_x: int, _z: int) -> bool: return false


func _pick(height_at: Callable = _flat(), is_dry: Callable = _dry(), has_tree: Callable = _no_trees(),
		avoid: Array = [], accept := Callable()) -> Dictionary:
	return TutorialCourse.pick(SPAWN, 7, height_at, is_dry, has_tree, avoid, accept)


func _rect(site: Dictionary) -> Rect2:
	var cols := TutorialCourse.footprint(site)
	var lo := Vector2(cols[0])
	var hi := Vector2(cols[0])
	for c: Vector2i in cols:
		lo = lo.min(Vector2(c))
		hi = hi.max(Vector2(c))
	return Rect2(lo, hi - lo + Vector2.ONE)


# --- Where it goes ---

func test_flat_ground_gives_a_playground_near_the_spawn() -> void:
	var site := _pick()
	assert_false(site.is_empty())
	var o: Vector3i = site.origin
	assert_eq(o.y, 40, "the pad is at the ground's height (feet level)")
	assert_true(site.dir in [0, 1, 2, 3])
	for c: Vector2i in TutorialCourse.footprint(site):
		assert_lte(Vector2(c - SPAWN).length(), TreasurePlaces.CLEAR_OF_SPAWN, "inside the 60-block spawn circle: %s" % c)
	assert_eq(TutorialCourse.footprint(site).size(), (TutorialCourse.A_MAX - TutorialCourse.A_MIN + 1) * (2 * TutorialCourse.S_HALF + 1))


func test_it_never_covers_the_spawn() -> void:
	var r := _rect(_pick()).grow(TutorialCourse.SPAWN_KEEP - 1)
	assert_false(r.has_point(Vector2(SPAWN) + Vector2(0.5, 0.5)), "the child never spawns on the playground")


func test_it_keeps_clear_of_the_landmarks() -> void:
	var first := _pick()
	var mid := _rect(first).get_center()
	var avoid := [{"at": mid, "r": 6.0}]
	var site := _pick(_flat(), _dry(), _no_trees(), avoid)
	assert_false(site.is_empty())
	var r := _rect(site)
	var nearest := Vector2(clampf(mid.x, r.position.x, r.end.x), clampf(mid.y, r.position.y, r.end.y))
	assert_gte(nearest.distance_to(mid), 6.0, "clear of Tilly, the Totem, the stone circle, the Theater, the giver")


func test_never_into_water() -> void:
	var dry_east := func(x: int, _z: int) -> bool: return x >= 0   # the sea to the west
	var site := _pick(_flat(), dry_east)
	assert_false(site.is_empty())
	assert_gte(_rect(site).position.x, 1.0, "dry ground only (and a column of dry ground around it)")


func test_never_on_a_tree() -> void:
	var trees := func(x: int, z: int) -> bool: return posmod(x * 7 + z * 13, 40) == 0 and absi(x) > 3
	var site := _pick(_flat(), _dry(), trees)
	assert_false(site.is_empty())
	var r := _rect(site).grow(TutorialCourse.TREE_MARGIN)
	for x in range(int(r.position.x), int(r.end.x)):
		for z in range(int(r.position.y), int(r.end.y)):
			assert_false(trees.call(x, z), "no trunk within %d of the playground" % TutorialCourse.TREE_MARGIN)


func test_only_level_ground_and_the_most_level_first() -> void:
	var slope := func(x: int, _z: int) -> int: return 40 + int(floor(x / 4.0))   # 1 up every 4 blocks east
	var site := _pick(slope)
	assert_false(site.is_empty())
	var lo := 999
	var hi := -999
	for c: Vector2i in TutorialCourse.footprint(site):
		lo = mini(lo, slope.call(c.x, c.y))
		hi = maxi(hi, slope.call(c.x, c.y))
	assert_lte(hi - lo, 2, "the flattest the slope allows: it runs along the level way")
	var o: Vector3i = site.origin
	assert_lte(absi(hi - o.y), 1)
	assert_lte(absi(lo - o.y), 1)
	var steep := func(x: int, z: int) -> int: return 40 + x + z
	assert_true(_pick(steep).is_empty(), "no pad deeper than %d blocks: no playground" % TutorialCourse.TOLERANCES[-1])


func test_the_accept_rule_can_turn_a_site_down() -> void:
	var first := _pick()
	var seen := []
	var accept := func(s: Dictionary) -> bool:
		seen.append(s.origin)
		return s.origin != first.origin
	var site := _pick(_flat(), _dry(), _no_trees(), [], accept)
	assert_false(site.is_empty())
	assert_ne(site.origin, first.origin, "a site with a child's build on it is turned down")


func test_real_worlds_find_one_quickly() -> void:
	for u in [1, 2, 3, 4]:
		for world_seed in [20260923, 12345, 777]:
			var shape := UniverseRegistry.shape_for(u, world_seed, WorldMeta.TERRAIN_LATEST)
			var spawn := shape.spawn_column()
			var t0 := Time.get_ticks_usec()
			var site := TutorialCourse.pick_for(shape, spawn, [])
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			assert_false(site.is_empty(), "universe %d seed %d has a playground" % [u, world_seed])
			assert_lt(ms, 400.0, "universe %d seed %d: %.0f ms" % [u, world_seed, ms])
			gut.p("universe %d seed %d: %s in %.1f ms" % [u, world_seed, site.get("origin"), ms])


# --- The course's shape ---

func test_the_stations_come_in_order_along_the_course() -> void:
	var site := {"origin": Vector3i(10, 40, 20), "dir": 0}
	assert_lt(TutorialCourse.GAP_TO, TutorialCourse.LAND_FROM)
	assert_lt(TutorialCourse.LAND_TO, TutorialCourse.BRIDGE_FROM)
	assert_lt(TutorialCourse.BRIDGE_TO, TutorialCourse.WALL_A)
	assert_lt(TutorialCourse.WALL_A, TutorialCourse.BUSHES[0].x)
	assert_eq(TutorialCourse.GAP_TO - TutorialCourse.GAP_FROM + 1, 6, "6 wide: one jump carries 4.5 m, so it takes a double or triple jump")
	assert_eq(TutorialCourse.BRIDGE_TO - TutorialCourse.BRIDGE_FROM + 1, 3, "a 3-block bridge")
	assert_eq(TutorialCourse.cell(site, 0, 0, 0), Vector3i(10, 40, 20))
	assert_eq(TutorialCourse.cell(site, 3, 0, 0), Vector3i(10, 40, 23), "dir 0 runs along +Z")
	var east := {"origin": Vector3i(0, 40, 0), "dir": 1}
	assert_eq(TutorialCourse.cell(east, 3, 0, -1), Vector3i(3, 39, 0), "dir 1 runs along +X")


func test_zones_for_the_jump() -> void:
	for dir in 4:
		var site := {"origin": Vector3i(5, 40, -3), "dir": dir}
		var at := func(a: int, s: int, dy: float = 0.0) -> Vector3:
			return Vector3(TutorialCourse.cell(site, a, s, 0)) + Vector3(0.5, dy, 0.5)
		assert_eq(TutorialCourse.zone(site, at.call(0, 0)), TutorialCourse.NEAR, "dir %d" % dir)
		assert_eq(TutorialCourse.zone(site, at.call(1, 2)), TutorialCourse.NEAR)
		assert_eq(TutorialCourse.zone(site, at.call(-4, 0, 2.0)), TutorialCourse.NEAR, "behind the pad, on higher ground")
		assert_eq(TutorialCourse.zone(site, at.call(4, 0)), TutorialCourse.GAP)
		assert_eq(TutorialCourse.zone(site, at.call(4, 0, -2.0)), TutorialCourse.PIT, "down in the hole")
		assert_eq(TutorialCourse.zone(site, at.call(9, -1)), TutorialCourse.FAR)
		assert_eq(TutorialCourse.zone(site, at.call(15, 0)), TutorialCourse.FAR, "anywhere past the hole counts")
		assert_eq(TutorialCourse.zone(site, at.call(12, 0, -2.0)), TutorialCourse.FAR, "a triple jump into the bridge's hole crossed the jump's hole")
		assert_eq(TutorialCourse.zone(site, at.call(5, 3)), TutorialCourse.OUTSIDE, "beside the playground")


func test_where_each_step_happens() -> void:
	var site := {"origin": Vector3i(0, 40, 0), "dir": 0}
	for id: StringName in TutorialRules.step_ids():
		if id == &"tilly":
			continue
		var p := TutorialCourse.station(site, id)
		assert_true(p.is_finite(), str(id))
		assert_lte(absf(p.y - 40.0), 1.0, "%s: on the pad" % id)
	assert_true(TutorialCourse.outline(site, &"bridge").size() == 3, "the bridge's 3 cells glow")
	assert_eq(TutorialCourse.outline(site, &"wall").size(), 2 * (2 * TutorialCourse.S_HALF + 1))
	assert_eq(TutorialCourse.outline(site, &"hide"), [TutorialCourse.cell(site, TutorialCourse.BUSHES[0].x, TutorialCourse.BUSHES[0].y, 0),
		TutorialCourse.cell(site, TutorialCourse.BUSHES[1].x, TutorialCourse.BUSHES[1].y, 0)] as Array[Vector3i])
	assert_eq(TutorialCourse.outline(site, &"craft"), [TutorialCourse.bench(site)] as Array[Vector3i])


func test_standing_on_the_playground() -> void:
	var site := {"origin": Vector3i(0, 40, 0), "dir": 0}
	assert_true(TutorialCourse.on_footprint(site, Vector3(0.5, 40, 5.5), 1))
	assert_true(TutorialCourse.on_footprint(site, Vector3(3.5, 40, 5.5), 1), "one column beside it counts")
	assert_false(TutorialCourse.on_footprint(site, Vector3(5.5, 40, 5.5), 1))
	assert_false(TutorialCourse.on_footprint(site, Vector3(0.5, 40, -4.5), 1))
