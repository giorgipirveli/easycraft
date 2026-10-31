extends GutTest
## Owner feedback #55 (spec §21): space as pure rules — the space line a flyer crosses, the climb that darkens the sky
## on the way, who may go, the "Where shall we land?" cards, the trip's saves (a space world remembers its home, the
## home world where the child took off) and the sky's space look.


# --- The line and the climb ---

func test_the_space_line_is_above_the_highest_block() -> void:
	assert_gt(SpaceRules.SPACE_Y, float(WorldService.MAX_Y), "nobody stands on a block up there")
	assert_lt(SpaceRules.CLIMB_FROM, SpaceRules.HINT_Y)
	assert_lt(SpaceRules.HINT_Y, SpaceRules.SPACE_Y)
	assert_lt(SpaceRules.REARM_Y, SpaceRules.SPACE_Y)
	assert_gt(SpaceRules.REARM_Y, SpaceRules.HINT_Y, "hovering just under the line does not open it twice")


func test_the_climb_goes_from_nothing_to_space() -> void:
	assert_eq(SpaceRules.climb(40.0), 0.0, "on the ground")
	assert_eq(SpaceRules.climb(SpaceRules.CLIMB_FROM), 0.0)
	var mid := SpaceRules.climb((SpaceRules.CLIMB_FROM + SpaceRules.SPACE_Y) * 0.5)
	assert_between(mid, 0.2, 0.8, "half way up")
	assert_eq(SpaceRules.climb(SpaceRules.SPACE_Y), 1.0)
	assert_eq(SpaceRules.climb(500.0), 1.0)
	assert_eq(SpaceRules.climb(NAN), 0.0, "no player")


func test_crossing_the_line_opens_space_once_until_the_child_comes_back_down() -> void:
	assert_false(SpaceRules.crossed(SpaceRules.SPACE_Y - 0.1, true))
	assert_true(SpaceRules.crossed(SpaceRules.SPACE_Y, true))
	assert_false(SpaceRules.crossed(SpaceRules.SPACE_Y + 5.0, false), "not armed: already open once")
	assert_false(SpaceRules.rearms(SpaceRules.SPACE_Y - 1.0), "hovering at the line")
	assert_true(SpaceRules.rearms(SpaceRules.REARM_Y - 0.1))
	assert_false(SpaceRules.rearms(NAN))


func test_space_is_where_flying_is_allowed() -> void:
	assert_true(SpaceRules.may_launch(ModeRules.SANDBOX))
	assert_true(SpaceRules.may_launch(ModeRules.SURVIVOR), "ruling 2: Survivor flies up too (paid flying)")
	assert_false(SpaceRules.may_launch(ModeRules.WAVE), "Monster Wave has no flying")


# --- The worlds ---

func test_the_space_worlds_are_off_the_ladder() -> void:
	assert_eq(SpaceRules.WORLDS, [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28] as Array[int],
		"the Moon, Boing, Rainbow Planet, Mars, Europa, Io, Titan, Mercury, Venus's cloud city, Saturn's rings, Pluto, "
		+ "Triton, Ganymede (§21b.2)")
	assert_eq(SpaceRules.MOON, 16)
	for u in SpaceRules.WORLDS:
		assert_true(SpaceRules.is_space(u), str(u))
	for u in range(1, 16):
		assert_false(SpaceRules.is_space(u), "universe %d is the ladder's (spec §5.1)" % u)
	assert_true(SpaceRules.is_space(SpaceRules.MARS), "the real solar system: spec §21b.2")
	assert_true(SpaceRules.is_space(SpaceRules.TRITON))
	assert_true(SpaceRules.is_space(40), "more planets after them")
	assert_false(SpaceRules.is_space(41))
	assert_lte(SpaceRules.LAST, UniverseRules.MAX_UNIVERSE, "a save keeps the number")


func test_home_is_the_ladder_world_the_trip_started_from() -> void:
	assert_eq(SpaceRules.home_for(3, 0), 3, "from Frostpeak")
	assert_eq(SpaceRules.home_for(SpaceRules.MOON, 2), 2, "from the Moon: the Moon's own home")
	assert_eq(SpaceRules.home_for(SpaceRules.MOON, 0), 1, "a Moon with no home: Green Meadows")
	assert_eq(SpaceRules.home_for(SpaceRules.MOON, 17), 1, "a home is never another space world")
	assert_eq(SpaceRules.home_for(0, 0), 1)


# --- "Where shall we land?" ---

func test_why_a_trip_cannot_happen() -> void:
	var avail: Array[int] = [16, 17]
	assert_eq(SpaceRules.refusal(16, 1, avail, 0), "")
	assert_eq(SpaceRules.refusal(16, 1, avail, 1), "friends")
	assert_eq(SpaceRules.refusal(18, 1, avail, 0), "coming_soon")
	assert_eq(SpaceRules.refusal(16, 16, avail, 0), "here")
	assert_eq(SpaceRules.refusal(3, 1, avail, 0), "coming_soon", "only space worlds are landed on")
	assert_ne(SpaceRules.message("friends"), "")
	assert_eq(SpaceRules.message("friends"), "Space trips work when you play alone.")


# --- The trip's saves ---

func test_a_new_space_world_remembers_its_home_and_the_portal_home() -> void:
	var m := SpaceRules.arrival_meta(null, 16, ModeRules.SANDBOX, DifficultyRules.COZY, 3)
	assert_eq(m.universe, 16)
	assert_eq(m.mode, ModeRules.SANDBOX)
	assert_eq(m.space_home, 3)
	assert_eq(m.arrival_gate, 3, "the portal home (owner #39) by the landing pad")
	assert_false(m.has_player_pos(), "on the landing pad (the world spawn)")
	assert_eq(m.difficulty, DifficultyRules.COZY)
	assert_true(m.inventories.is_empty(), "ruling: no starter kit in space (the bag comes along)")


func test_a_space_world_visited_before_keeps_everything_but_where_the_child_left() -> void:
	var old := WorldMeta.new_random()
	old.seed = 42
	old.player_pos = Vector3(3, 230, 4)   # left by flying up
	old.physics_mode = PhysicsMode.Mode.FLY
	old.lab_mode = LabRules.Mode.FLY
	old.buddies.append({"name": "Bob"})
	var m := SpaceRules.arrival_meta(old, 17, ModeRules.SURVIVOR, DifficultyRules.NORMAL, 2)
	assert_same(m, old)
	assert_eq(m.seed, 42, "the same world")
	assert_false(m.has_player_pos(), "arrives on the pad again, not in the sky")
	assert_eq(m.physics_mode, PhysicsMode.Mode.NORMAL, "lands walking")
	assert_eq(m.lab_mode, LabRules.Mode.NORMAL)
	assert_eq(m.space_home, 2, "the home of this trip")
	assert_eq(m.arrival_gate, 2)
	assert_eq(m.mode, ModeRules.SURVIVOR)


func test_the_home_world_remembers_the_column_the_child_took_off_from() -> void:
	assert_eq(SpaceRules.landing_column(Vector3(10.7, 201.0, -3.2)), [10, -4])
	assert_eq(SpaceRules.landing_column(Vector3.INF), [], "no player: the spawn as always")


func test_space_saves_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.universe = 16
	m.space_home = 4
	m.space_return = [12, -7]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.universe, 16, "a space world's number survives the save")
	assert_eq(back.space_home, 4)
	assert_eq(back.space_return, [12, -7])


func test_broken_space_saves_read_as_none() -> void:
	var m := WorldMeta.from_json('{"space_home": 17, "space_return": [1]}')
	assert_eq(m.space_home, 1, "a home is a ladder world")
	assert_eq(m.space_return, [])
	m = WorldMeta.from_json('{"space_home": "x", "space_return": ["a", 2]}')
	assert_eq(m.space_home, 1)
	assert_eq(m.space_return, [])
	m = WorldMeta.from_json('{"space_return": [1e12, 2]}')
	assert_eq(m.space_return, [], "far beyond any world")


# --- The sky's space look ---

func _day_look() -> Dictionary:
	return DayCycle.look(DayCycle.NOON)


func test_the_space_look_turns_the_sky_dark_and_starry() -> void:
	var day := _day_look()
	var space := SpaceRules.space_look(day.duplicate(), 1.0)
	assert_eq(space.stars, 1.0, "every star shines")
	assert_lt((space.sky_top as Color).get_luminance(), 0.1, "a black sky")
	assert_lt((space.sky_horizon as Color).get_luminance(), 0.2)
	assert_lt((space.fog_color as Color).get_luminance(), 0.2)
	assert_eq(space.light_energy, day.light_energy, "the sun still shines in space")
	var none := SpaceRules.space_look(day.duplicate(), 0.0)
	assert_eq(none.sky_top, day.sky_top, "nothing changes on the ground")
	assert_eq(none.stars, day.stars)
	var half := SpaceRules.space_look(day.duplicate(), 0.5)
	assert_between(float(half.stars), float(day.stars), 1.0)
	assert_lt((half.sky_top as Color).get_luminance(), (day.sky_top as Color).get_luminance())


func test_the_space_look_dims_a_photo_sky() -> void:
	var day := _day_look()
	var space := SpaceRules.space_look(day.duplicate(), 1.0)
	assert_lt(float(space.sky_energy), float(day.sky_energy), "the realistic style's sky goes dark too")


func test_landing_words_name_the_world() -> void:
	assert_string_contains(SpaceRules.landing_words("The Moon"), "The Moon")
	assert_string_contains(SpaceRules.landing_words("Planet Boing"), "Planet Boing")
