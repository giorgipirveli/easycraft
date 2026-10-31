extends GutTest
## Missions (spec §21d.1, §21d.5): the Mission Board's missions in the real order people did or plan them (the Moon,
## Mars, then every real planet world that exists), each with where, how long the real trip takes and what the rocket
## needs; and the route: a planet reached once (a mission, or a landing before missions: the Space Book's LANDED) can be
## landed on from the Star Map; one not reached needs a mission. Boing and Rainbow stay reachable by flying up.


func after_each() -> void:
	UniverseRegistry.reset()


func test_the_moon_then_mars_then_every_real_planet_world() -> void:
	var worlds: Array[int] = []
	for m: Dictionary in MissionRules.MISSIONS:
		worlds.append(int(m.world))
	assert_eq(worlds, [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.EUROPA, SpaceRules.IO, SpaceRules.TITAN,
		SpaceRules.MERCURY, SpaceRules.VENUS, SpaceRules.RINGS, SpaceRules.PLUTO, SpaceRules.TRITON,
		SpaceRules.GANYMEDE] as Array[int])
	for u in SpaceRules.WORLDS:
		var game_planet := u == SpaceRules.BOING or u == SpaceRules.RAINBOW
		assert_eq(MissionRules.has_mission(u), not game_planet, "world %d" % u)
	assert_false(MissionRules.has_mission(1), "Green Meadows is a home world")


func test_each_mission_says_where_how_long_and_what_the_rocket_needs() -> void:
	for m: Dictionary in MissionRules.MISSIONS:
		assert_ne(str(m.name), "")
		assert_string_starts_with(str(m.name), "Mission to ")
		assert_ne(str(m.trip), "", "%s: how long the real trip takes" % m.name)
		assert_ne(str(m.fact), "", "%s: one line of its real trip" % m.name)
		assert_gt(int(m.days), 0)
		assert_eq(float((m.legs as Array)[0][1]), 9.4, "%s: first Earth orbit, 9.4 km/s" % m.name)
		assert_false(StarMap.body(m.body).is_empty(), "%s is a Star Map body" % m.name)
		assert_eq(StarMap.body_for_world(int(m.world)), m.body)
		assert_false(MissionRules.needs_words(m).is_empty())
	var moon := MissionRules.for_world(SpaceRules.MOON)
	assert_almost_eq(MissionRules.need(moon), 15.3, 0.001, "9.4 + 3.3 + 2.6")
	assert_eq(int(moon.days), 3)
	assert_false(bool(moon.air), "no air on the Moon: no parachute, no heat shield")
	var mars := MissionRules.for_world(SpaceRules.MARS)
	assert_almost_eq(MissionRules.need(mars), 16.1, 0.001, "9.4 + 3.6 + 2.1 + 1.0")
	assert_eq(int(mars.days), 210, "about 7 months")
	assert_true(bool(mars.air))
	assert_true(bool(MissionRules.for_world(SpaceRules.TITAN).air), "Titan's air is thicker than Earth's")
	assert_gt(MissionRules.need(MissionRules.for_world(SpaceRules.MERCURY)),
		MissionRules.need(MissionRules.for_world(SpaceRules.EUROPA)), "Mercury is the hardest to land on")
	assert_true(MissionRules.for_world(99).is_empty())


func test_the_route_is_where_the_child_has_landed() -> void:
	var w := WonderData.new()
	var flown: Array[int] = []
	assert_eq(MissionRules.route(w, flown), [] as Array[int])
	w.land_on_world(SpaceRules.MARS)   # landed before missions existed
	w.see_body(&"europa")              # only its card: not reached
	flown.append(SpaceRules.MOON)      # a mission flown there
	assert_eq(MissionRules.route(w, flown), [SpaceRules.MOON, SpaceRules.MARS] as Array[int])
	var route := MissionRules.route(w, flown)
	assert_false(MissionRules.needs_mission(SpaceRules.MOON, route))
	assert_false(MissionRules.needs_mission(SpaceRules.MARS, route))
	assert_true(MissionRules.needs_mission(SpaceRules.EUROPA, route))
	assert_false(MissionRules.needs_mission(SpaceRules.BOING, route), "Planet Boing: fly up")
	assert_false(MissionRules.needs_mission(SpaceRules.RAINBOW, route))
	assert_false(MissionRules.needs_mission(1, route), "a home world is never a mission")


func test_who_may_launch() -> void:
	assert_eq(MissionRules.launch_refusal(true, false, 0), "")
	assert_eq(MissionRules.launch_refusal(false, false, 0), MissionRules.NOT_READY)
	assert_eq(MissionRules.launch_refusal(true, true, 0), MissionRules.GUEST, "a friend in someone else's world")
	assert_eq(MissionRules.launch_refusal(true, false, 2), "", "the world's owner flies; friends are told")
	assert_ne(MissionRules.message(MissionRules.GUEST), "")
	assert_ne(MissionRules.message(MissionRules.NOT_READY), "")
	assert_string_contains(MissionRules.launched_words("Alex", MissionRules.for_world(SpaceRules.MOON)), "Alex")
	assert_string_contains(MissionRules.launched_words("Alex", MissionRules.for_world(SpaceRules.MOON)), "Moon")


func test_mission_data_keeps_parts_and_flights_and_never_loses_them() -> void:
	var d := MissionData.new()
	assert_true(d.is_empty())
	d.add_part(BlockIds.ROCKET_ENGINE, 3)
	d.add_part(BlockIds.STONE, 5)   # not a part: nothing
	d.fly(SpaceRules.MOON)
	d.fly(SpaceRules.MOON)
	d.fly(1)   # not a mission: nothing
	assert_eq(d.owned(), {BlockIds.ROCKET_ENGINE: 3})
	assert_eq(d.flown, [SpaceRules.MOON] as Array[int])
	var back := MissionData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_eq(back.owned(), {BlockIds.ROCKET_ENGINE: 3})
	assert_eq(back.flown, [SpaceRules.MOON] as Array[int])
	var other := MissionData.new()
	other.add_part(BlockIds.ROCKET_ENGINE, 5)
	other.add_part(BlockIds.FUEL_TANK, 2)
	other.fly(SpaceRules.MARS)
	back.merge_from(other)
	assert_eq(back.owned(), {BlockIds.ROCKET_ENGINE: 5, BlockIds.FUEL_TANK: 2}, "the bigger count of each")
	assert_eq(back.flown, [SpaceRules.MOON, SpaceRules.MARS] as Array[int])
	for bad: Variant in [null, 3, "x", {"parts": {"560": -4, "3": 2, "abc": 1, "561": 1.5}, "flown": [16, 16, 2, "x"]}]:
		var clean := MissionData.from_dict(bad)
		assert_true(clean.owned().is_empty(), str(bad))
	assert_eq(MissionData.from_dict({"flown": [16, 16, 2, "x"]}).flown, [16] as Array[int])


func test_a_profile_keeps_its_missions() -> void:
	var p := ProfileData.new()
	p.missions.add_part(BlockIds.FUEL_TANK, 4)
	p.missions.fly(SpaceRules.MOON)
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.missions.owned(), {BlockIds.FUEL_TANK: 4})
	assert_eq(back.missions.flown, [SpaceRules.MOON] as Array[int])
	assert_false(ProfileBackup.is_new(back), "rocket parts bought are progress")
