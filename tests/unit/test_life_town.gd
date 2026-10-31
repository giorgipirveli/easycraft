extends GutTest
## Owner #112 (docs/design/life-skills.md §7, Life Town; Life L2): a small district a short walk from the spawn of
## every home world, placed like the Launch Site (the seed finds flat, dry ground with no tree, facing the spawn; never
## on the Theater or the Launch Site, nor hiding behind them seen from the spawn; the save keeps it): the practice house
## (Fire Escape), the clinic (Little Lifesaver), the market (My Money Stall), the street (Safe Streets), the kitchen
## house (The Kitchen) and the park bench (Calm Corner). Walking up to one starts its Experience. Its buildings are
## models (nothing stamped into the world); a child's build in the way moves it elsewhere (natural).

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
	for lx in range(LifeTown.PLAZA_MIN.x, LifeTown.PLAZA_MAX.x + 1):
		for lz in range(LifeTown.PLAZA_MIN.y, LifeTown.PLAZA_MAX.y + 1):
			out.append(LifeTown.to_world(site, Vector2i(lx, lz)))
	return out


func test_every_experience_has_its_building_and_the_spots_stand_apart() -> void:
	var experiences := {}
	for id: String in LifeTown.SPOTS:
		var spot: Dictionary = LifeTown.SPOTS[id]
		assert_has(LifeExperience.IDS, str(spot.experience), id)
		experiences[spot.experience] = true
		assert_ne(str(spot.get("sign", "")), "", id + " has its sign")
		for other: String in LifeTown.SPOTS:
			if other != id:
				var d := (spot.door as Vector2).distance_to(LifeTown.SPOTS[other].door)
				assert_gt(d, LifeTown.REACH * 2.0, "%s and %s: walking up to one never opens the other" % [id, other])
	for id: String in MarketPlaza.SPOTS:   # owner #115 (S3): the shop and the Market Square on the second plaza
		experiences[MarketPlaza.SPOTS[id].experience] = true
	assert_eq(experiences.size(), LifeExperience.IDS.size(),
		"every Experience, each with its place (Real Builder: the site; Life L3b's second row: L3b's three and Success S2's four; Life L3c's third row; Success S3's two on the Market Square)")
	for id: String in SuccessExperiences.IDS:
		assert_true(experiences.has(id), id + ": its place in the second row (owner #115) or on the Market Square (S3)")


## Life L3b (owner #118, #115): the plaza's second row, nearest the spawn: seven places side by side, their doors facing
## the spawn, each inside the plaza, none on another's footprint.
func test_the_second_row_faces_the_spawn_and_nothing_overlaps() -> void:
	var second := 0
	for id: String in LifeTown.SPOTS:
		var s: Dictionary = LifeTown.SPOTS[id]
		var door: Vector2 = s.door
		assert_true(door.x >= LifeTown.PLAZA_MIN.x and door.x <= LifeTown.PLAZA_MAX.x + 1 and door.y >= LifeTown.PLAZA_MIN.y
			and door.y <= LifeTown.PLAZA_MAX.y + 1, id + ": its door on the plaza")
		if (s.min as Vector2i).y >= LifeTown.SECOND_ROW_Z and (s.min as Vector2i).y < LifeTown.THIRD_ROW_Z:   # Life L3c: a third
			second += 1
			assert_gt(door.y, float((s.max as Vector2i).y), id + ": its door in front, towards the spawn")
		for other: String in LifeTown.SPOTS:
			if other == id:
				continue
			var o: Dictionary = LifeTown.SPOTS[other]
			var apart := (s.max as Vector2i).x < (o.min as Vector2i).x or (o.max as Vector2i).x < (s.min as Vector2i).x \
				or (s.max as Vector2i).y < (o.min as Vector2i).y or (o.max as Vector2i).y < (s.min as Vector2i).y
			assert_true(apart, "%s and %s don't overlap" % [id, other])
	assert_eq(second, 7, "the second row: L3b's three and Success S2's four")


func test_a_flat_world_gets_the_town_a_short_walk_from_the_spawn_facing_it() -> void:
	var site := LifeTown.pick(SPAWN, 4242, _flat, _dry, _no_tree)
	assert_false(site.is_empty())
	assert_eq((site.pos as Vector3i).y, GROUND, "the ground at its middle")
	var near := INF
	var far := 0.0
	for c in _cells(site):
		near = minf(near, Vector2(c - SPAWN).length())
		far = maxf(far, Vector2(c - SPAWN).length())
	assert_gte(near, float(LifeTown.MIN_EDGE_FROM_SPAWN))
	assert_lte(far, LifeTown.MAX_FROM_SPAWN)
	assert_eq(site.facing, TheaterSite.facing_towards(Vector2i(site.pos.x, site.pos.z), SPAWN), "its doors face the spawn")
	assert_eq(LifeTown.pick(SPAWN, 4242, _flat, _dry, _no_tree), site, "the same seed, the same place")


func test_never_on_the_theater_or_the_launch_site_nor_behind_them() -> void:
	for seed_ in [1, 7, 99, 4242, 31337]:
		var theater := TheaterSite.pick(SPAWN, seed_, _flat, _dry, _no_tree)
		var launch := LaunchSite.pick(SPAWN, seed_, _flat, _dry, _no_tree, theater)
		var site := LifeTown.pick(SPAWN, seed_, _flat, _dry, _no_tree, theater, launch)
		assert_false(site.is_empty(), "seed %d" % seed_)
		var s := Vector2i(site.pos.x, site.pos.z)
		for other: Dictionary in [theater, launch]:
			var o := Vector2i(other.pos.x, other.pos.z)
			var angle := rad_to_deg(absf(Vector2(s - SPAWN).angle_to(Vector2(o - SPAWN))))
			assert_gte(angle, LifeTown.SIGHT_GAP, "seed %d: in sight of both landmarks" % seed_)
		for c in _cells(site):
			assert_gte(TheaterSite.edge_distance(Vector2i(theater.pos.x, theater.pos.z), c), float(LifeTown.CLEAR),
				"seed %d: clear of the Theater" % seed_)
			assert_false(LifeTown.on_launch_site(launch, c), "seed %d: never on the Launch Site's plaza" % seed_)


func test_dry_land_without_trees() -> void:
	var dry := func(x: int, _z: int) -> bool: return x > -5
	var trees := func(x: int, z: int) -> bool: return x > 0 and z > 0 and (x + z) % 5 == 0
	var site := LifeTown.pick(SPAWN, 5, _flat, dry, trees)
	assert_false(site.is_empty())
	for id: String in LifeTown.SPOTS:   # trees may grow between the places, never in or right round one
		var s: Dictionary = LifeTown.SPOTS[id]
		for lx in range((s.min as Vector2i).x - LifeTown.TREE_MARGIN, (s.max as Vector2i).x + LifeTown.TREE_MARGIN + 1):
			for lz in range((s.min as Vector2i).y - LifeTown.TREE_MARGIN, (s.max as Vector2i).y + LifeTown.TREE_MARGIN + 1):
				var k := LifeTown.to_world(site, Vector2i(lx, lz))
				assert_false(trees.call(k.x, k.y), "%s: no tree at %s" % [id, k])
		for lx in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):
			for lz in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
				var k := LifeTown.to_world(site, Vector2i(lx, lz))
				assert_true(dry.call(k.x, k.y), "%s on dry land at %s" % [id, k])


## Meadows are wooded: a site among trees is still found (the last tier), and the trees and plants in and right round
## its places are cleared once by the host, like the Launch Site's stamp.
func test_trees_in_the_way_are_cleared_like_the_launch_sites() -> void:
	var everywhere := func(_x: int, _z: int) -> bool: return true
	var site := LifeTown.pick(SPAWN, 8, _flat, _dry, everywhere)
	assert_false(site.is_empty(), "a wood still gets its town")
	var house := LifeTown.to_world(site, Vector2i(-9, -4))
	var trunk := Vector3i(house.x, GROUND, house.y)
	var read := func(at: Vector3i) -> int:
		if at == trunk or at == trunk + Vector3i.UP:
			return BlockIds.LOG
		if at == trunk + Vector3i(0, 3, 0):
			return BlockIds.LEAVES
		return BlockIds.GRASS if at.y < GROUND else BlockIds.AIR
	assert_true(LifeTown.natural(site, read), "a tree is the world's own")
	var cleared := {}
	for c: Array in LifeTown.clear_changes(site, read):
		assert_eq(int(c[1]), BlockIds.AIR)
		cleared[c[0]] = true
	assert_true(cleared.has(trunk) and cleared.has(trunk + Vector3i.UP) and cleared.has(trunk + Vector3i(0, 3, 0)),
		"the tree in the practice house's way")
	assert_eq(cleared.size(), 3, "nothing else: the ground stays")


func test_a_world_of_sea_has_no_town() -> void:
	assert_true(LifeTown.pick(SPAWN, 3, _flat, func(_x: int, _z: int) -> bool: return false, _no_tree).is_empty())


func test_walking_up_to_a_door_names_its_experience() -> void:
	var site := LifeTown.pick(SPAWN, 4242, _flat, _dry, _no_tree)
	for id: String in LifeTown.SPOTS:
		var door := LifeTown.door_position(site, id)
		assert_eq(LifeTown.near(site, door + Vector3(0.6, 0, 0.4)), id, id)
		assert_eq(LifeTown.experience_at(site, door), str(LifeTown.SPOTS[id].experience))
	var middle := LifeTown.to_world_point(site, Vector2(0, -6.5), GROUND)
	assert_eq(LifeTown.near(site, middle + Vector3(0, 0, 0)), "", "behind the buildings: nothing opens")
	assert_eq(LifeTown.near(site, LifeTown.door_position(site, "house") + Vector3(0, 6, 0)), "", "far above: nothing")
	assert_eq(LifeTown.near({}, Vector3.ZERO), "")


func test_a_childs_build_in_the_way_is_never_covered() -> void:
	var site := LifeTown.pick(SPAWN, 4242, _flat, _dry, _no_tree)
	var natural := func(at: Vector3i) -> int: return BlockIds.GRASS if at.y < GROUND else BlockIds.AIR
	assert_true(LifeTown.natural(site, natural), "ground and air")
	var planted := func(at: Vector3i) -> int:
		return BlockIds.FLOWERS if at.y == GROUND else natural.call(at)
	assert_true(LifeTown.natural(site, planted), "flowers are the world's own")
	var corner := LifeTown.to_world(site, Vector2i(2, 1))
	var built := func(at: Vector3i) -> int:
		return BlockIds.PLANKS if at == Vector3i(corner.x, GROUND + 1, corner.y) else natural.call(at)
	assert_false(LifeTown.natural(site, built), "a child's planks: the town goes elsewhere")


func test_the_save_keeps_the_town() -> void:
	var site := LifeTown.pick(SPAWN, 4242, _flat, _dry, _no_tree)
	var saved := LifeTown.to_save(site)
	assert_eq(LifeTown.from_save(saved), site)
	assert_eq(LifeTown.from_save([1, 2]), {}, "a broken save: placed again")
	assert_eq(LifeTown.from_save([1, 2, 3, 9]), {}, "a bad facing")
	assert_eq(LifeTown.to_save({}), [])


## Real home worlds (Green Meadows' generator): most seeds get their town, with the Theater and the Launch Site where
## their own searches put them, and the search stays cheap enough for a worker (measured, printed).
func test_real_meadows_get_their_town() -> void:
	var found := 0
	var slowest := 0
	var seeds := [1, 2, 3, 42, 777, 2024, 31337, 123456]
	for s: int in seeds:
		var shape := MeadowsShape.new(s)
		var theater := TheaterSite.pick_for(shape)
		var launch := LaunchSite.pick_for(shape, theater)
		var t0 := Time.get_ticks_msec()
		var site := LifeTown.pick_for(shape, theater, launch)
		slowest = maxi(slowest, Time.get_ticks_msec() - t0)
		if not site.is_empty():
			found += 1
			for id: String in LifeTown.SPOTS:
				var w := LifeTown.to_world(site, Vector2i((LifeTown.SPOTS[id].door as Vector2).floor()))
				assert_true(shape.height_at(w.x, w.y) > MeadowsShape.SEA_LEVEL + 1, "seed %d: %s's door is dry" % [s, id])
	gut.p("LIFE_TOWN found %d of %d seeds, slowest search %d ms" % [found, seeds.size(), slowest])
	assert_gte(found, seeds.size() - 2, "nearly every meadow has its town")


func test_the_worlds_save_keeps_life_town() -> void:
	var m := WorldMeta.new_random()
	m.life_town = [40, 70, -12, 1]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.life_town, [40, 70, -12, 1])
	var older: Dictionary = JSON.parse_string(m.to_json())
	older.erase("life_town")
	assert_eq(WorldMeta.from_json(JSON.stringify(older)).life_town, [], "an older world: placed when it is next played")
	older["life_town"] = ["x"]
	assert_eq(WorldMeta.from_json(JSON.stringify(older)).life_town, [], "a broken save: placed again")
