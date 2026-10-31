extends GutTest
## Owner #132 (W1), stage 3: the Discovery Academy by every home world's spawn: a tall tower with Professor Hoot on top
## and twelve doors round it, one per subject family and Life's. Placed by Life Town's own search (a third plaza), after
## the town and the Market Square (they keep their meadows), never on their plazas nor hidden behind them, nor on the
## Theater or the Launch Site; a world with no room gets it as a small island floating over the spawn. Each door is a
## picture (no words, owner #133), its name spoken as the child walks up; Maths opens its real play (#134), Life opens
## Life, the rest a calm "coming soon" until their games come.

const SEED := 4242


func _flat(_x: int, _z: int) -> int:
	return 70


func _dry(_x: int, _z: int) -> bool:
	return true


func _no_tree(_x: int, _z: int) -> bool:
	return false


func test_twelve_doors_one_per_subject_family_and_life() -> void:
	var subjects := []
	for id: String in AcademyPlaza.DOORS:
		var s: Dictionary = AcademyPlaza.SPOTS[id]
		subjects.append(str(s.subject))
		assert_false(str(s.name).is_empty(), "%s has a name to say" % id)
		assert_true(AcademyIcons.knows(str(s.picture)), "%s has a picture" % id)
	assert_eq(subjects.size(), 12)
	for sub: String in ["maths", "science", "english", "history", "geography", "citizenship", "computing", "art",
			"music", "health_pe", "design_tech", "life"]:
		assert_has(subjects, sub)
	for g in SchoolData.GRADES:
		for sub: Dictionary in Curriculum.subjects(g):
			if str(sub.id) != "projects":
				assert_has(subjects, str(sub.id), "grade %d's %s has a door" % [g, sub.id])


func test_doors_are_more_than_two_reaches_apart() -> void:
	var ids: Array = AcademyPlaza.DOORS
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Vector2 = AcademyPlaza.SPOTS[ids[i]].door
			var b: Vector2 = AcademyPlaza.SPOTS[ids[j]].door
			assert_gt(a.distance_to(b), 2.0 * LifeTown.REACH, "%s and %s" % [ids[i], ids[j]])


func test_the_maths_door_faces_the_spawn() -> void:
	var door: Vector2 = AcademyPlaza.SPOTS["maths"].door
	assert_gt(door.y, 7.0, "the front (+Z faces the spawn)")
	assert_almost_eq(door.x, 0.0, 0.01)


func test_walking_up_to_a_door() -> void:
	var site := {"pos": Vector3i(100, 70, 40), "facing": 1}
	for id: String in AcademyPlaza.DOORS:
		var at := AcademyPlaza.door_position(site, id)
		assert_eq(AcademyPlaza.near(site, at), id)
		assert_eq(AcademyPlaza.near(site, at + Vector3(0, 0, 0.6)), id, "near enough")
	var middle := LifeTown.to_world_point(site, Vector2.ZERO, 70.0)
	assert_eq(AcademyPlaza.near(site, middle), "", "the tower's middle is no door")


func test_what_each_door_opens() -> void:
	assert_eq(AcademyPlaza.opens("life"), AcademyPlaza.LIFE, "Life: Life")
	for id: String in AcademyPlaza.DOORS:
		if id != "life":
			assert_eq(AcademyPlaza.opens(id), AcademyPlaza.PLAY,
				"%s: its subject's play in G0's place (coming soon where none plays yet)" % id)


func test_the_search_avoids_the_town_and_the_market_square() -> void:
	var spawn := Vector2i.ZERO
	var town := LifeTown.pick(spawn, SEED, _flat, _dry, _no_tree)
	var market := MarketPlaza.pick(spawn, SEED, _flat, _dry, _no_tree, town)
	var site := AcademyPlaza.pick(spawn, SEED, _flat, _dry, _no_tree, {}, {}, town, market)
	assert_false(site.is_empty())
	assert_false(site.get("island", false))
	for id: String in AcademyPlaza.SPOTS:
		var s: Dictionary = AcademyPlaza.SPOTS[id]
		for lx in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):
			for lz in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
				var k := LifeTown.to_world(site, Vector2i(lx, lz))
				assert_false(LifeTown.on_plaza(town, k), "off the town's plaza")
				assert_false(LifeTown.on_plaza(market, k, MarketPlaza.LAYOUT), "off the Market Square")
	for other: Dictionary in [town, market]:
		var a := Vector2(site.pos.x - spawn.x, site.pos.z - spawn.y)
		var b := Vector2(other.pos.x - spawn.x, other.pos.z - spawn.y)
		assert_gte(rad_to_deg(absf(a.angle_to(b))), LifeTown.PLAZA_SIGHT_GAP, "beside it, never behind it")
	var d := Vector2(site.pos.x, site.pos.z).length()
	assert_lte(d, LifeTown.MAX_FROM_SPAWN, "seen from the spawn")


func test_no_room_floats_it_over_the_spawn() -> void:
	var water := func(_x: int, _z: int) -> bool: return false   # an ocean: nowhere dry
	var site := AcademyPlaza.pick(Vector2i(5, 9), SEED, _flat, water, _no_tree)
	assert_true(site.get("island", false))
	assert_eq(Vector2i(site.pos.x, site.pos.z), Vector2i(5, 9), "over the spawn")
	assert_eq(int(site.pos.y), 70 + AcademyPlaza.ISLAND_UP)


func test_the_save_keeps_the_site_and_the_island() -> void:
	var site := {"pos": Vector3i(12, 71, -30), "facing": 2}
	assert_eq(AcademyPlaza.from_save(AcademyPlaza.to_save(site)), site)
	var island := {"pos": Vector3i(0, 86, 0), "facing": 0, "island": true}
	assert_eq(AcademyPlaza.from_save(AcademyPlaza.to_save(island)), island)
	assert_eq(AcademyPlaza.from_save([1, 2]), {}, "a broken save: placed again")
	var m := WorldMeta.new()
	m.academy = AcademyPlaza.to_save(site)
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(AcademyPlaza.from_save(back.academy), site, "the world's save keeps it")


func test_real_meadows_keep_their_town_and_market_and_get_their_academy() -> void:
	var towns := 0
	var markets := 0
	var academies := 0
	var islands := 0
	var slowest := 0
	var seeds := [1, 2, 3, 42, 777, 2024, 31337, 123456]
	for s: int in seeds:
		var shape := MeadowsShape.new(s)
		var theater := TheaterSite.pick_for(shape)
		var launch := LaunchSite.pick_for(shape, theater)
		var town := LifeTown.pick_for(shape, theater, launch)
		var market := MarketPlaza.pick_for(shape, town, theater, launch) if not town.is_empty() else {}
		towns += 0 if town.is_empty() else 1
		markets += 0 if market.is_empty() else 1
		var t0 := Time.get_ticks_msec()
		var site := AcademyPlaza.pick_for(shape, theater, launch, town, market)
		slowest = maxi(slowest, Time.get_ticks_msec() - t0)
		assert_false(site.is_empty(), "seed %d: an Academy always (ground or island)" % s)
		var sp := shape.spawn_column()
		if bool(site.get("island", false)):
			islands += 1
			gut.p("W1_ACADEMY seed %d: no room: an island over the spawn" % s)
			continue
		academies += 1
		var from_spawn := Vector2(site.pos.x - sp.x, site.pos.z - sp.y).length()
		var from_town := Vector2(site.pos.x - town.pos.x, site.pos.z - town.pos.z).length() if not town.is_empty() else NAN
		gut.p("W1_ACADEMY seed %d: %.0f m from the spawn, %.0f m from the town's middle" % [s, from_spawn, from_town])
		for id: String in AcademyPlaza.DOORS:
			var w := LifeTown.to_world(site, Vector2i((AcademyPlaza.SPOTS[id].door as Vector2).floor()))
			assert_true(shape.height_at(w.x, w.y) > MeadowsShape.SEA_LEVEL + 1, "seed %d: %s's door is dry" % [s, id])
	gut.p("W1_ACADEMY towns %d of %d, Market Squares %d, Academies on the ground %d, islands %d, slowest search %d ms"
		% [towns, seeds.size(), markets, academies, islands, slowest])
	assert_gte(towns, 6, "Life Town keeps its 6 of 8")
	assert_gte(markets, 6, "the Market Square keeps its 6")
	assert_gte(academies, 5, "most worlds get the Academy on the ground")
