extends GutTest
## M2 Task 5 (spec §12.5): stealth as pure rules — visibility, sight, noise, the monster's mind
## (wander → ? → ! → search → wander), hiding spots, crouching, the HUD's eye and noise bars and the
## danger arrow (research A3).

const EYE := Vector3(0.5, 31.0, 0.5)


func _open(_p: Vector3i) -> bool:
	return false


# --- Visibility (§12.5): every factor and their product ---

func test_daylight_night_and_a_dark_cave() -> void:
	assert_eq(StealthRules.light_level(1.0, 0.0, false), 1.0, "daylight")
	assert_eq(StealthRules.light_level(0.0, 0.0, false), 0.45, "night")
	assert_eq(StealthRules.light_level(1.0, 1.0, false), 0.3, "a dark cave at noon")
	assert_eq(StealthRules.light_level(0.0, 1.0, false), 0.3, "a dark cave at night")
	assert_almost_eq(StealthRules.light_level(0.5, 0.0, false), 0.725, 0.001, "dusk is in between")
	assert_almost_eq(StealthRules.light_level(1.0, 0.5, false), 0.65, 0.001, "half way down into a cave")


func test_a_lantern_or_light_block_nearby_lights_you_up() -> void:
	assert_eq(StealthRules.light_level(0.0, 0.0, true), 1.0, "night, next to a lantern")
	assert_eq(StealthRules.light_level(0.0, 1.0, true), 1.0, "a lit cave")
	assert_true(StealthRules.LIGHT_BLOCKS.has(BlockIds.LANTERN))
	assert_true(StealthRules.LIGHT_BLOCKS.has(BlockIds.LIGHT))


func test_crouching_halves_visibility() -> void:
	assert_eq(StealthRules.visibility(1.0, true, false, false), 0.5)
	assert_eq(StealthRules.visibility(1.0, false, false, false), 1.0)


func test_hiding_or_the_invisibility_potion_make_you_invisible() -> void:
	assert_eq(StealthRules.visibility(1.0, false, true, false), 0.0, "inside a hiding spot")
	assert_eq(StealthRules.visibility(1.0, false, false, true), 0.0, "the Invisibility potion")
	assert_eq(StealthRules.visibility(1.0, true, true, true), 0.0)


func test_the_factors_multiply() -> void:
	var night := StealthRules.light_level(0.0, 0.0, false)
	assert_almost_eq(StealthRules.visibility(night, true, false, false), 0.225, 0.0001, "crouching at night")
	var cave := StealthRules.light_level(1.0, 1.0, false)
	assert_almost_eq(StealthRules.visibility(cave, true, false, false), 0.15, 0.0001, "crouching in a dark cave")
	assert_eq(StealthRules.visibility(StealthRules.light_level(0.0, 1.0, true), true, false, false), 0.5,
		"crouching by a lantern in a cave")


# --- Sight: 16 × visibility, a 120° view, a clear line ---

func test_sight_range_is_16_blocks_times_visibility() -> void:
	assert_eq(StealthRules.sight_range(1.0), 16.0)
	assert_eq(StealthRules.sight_range(0.45), 7.2)
	assert_almost_eq(StealthRules.sight_range(0.225), 3.6, 0.0001)
	assert_eq(StealthRules.sight_range(0.0), 0.0)
	assert_eq(StealthRules.sight_range(3.0), 16.0, "never further than 16")


func test_a_monster_sees_within_its_sight_range_only() -> void:
	var near := EYE + Vector3(0, 0, -7.0)
	var far := EYE + Vector3(0, 0, -15.0)
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, far, 1.0, _open), StealthRules.Sight.FULL, "daylight: 15 blocks")
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, near, 0.45, _open), StealthRules.Sight.FULL, "night: 7 blocks")
	assert_ne(StealthRules.sight(EYE, Vector3.FORWARD, far, 0.45, _open), StealthRules.Sight.FULL, "night: not 15 blocks")


func test_a_crouching_player_in_the_dark_is_not_seen_from_far_away() -> void:
	var vis := StealthRules.visibility(StealthRules.light_level(0.0, 0.0, false), true, false, false)
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -3.0), vis, _open), StealthRules.Sight.FULL)
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -8.0), vis, _open), StealthRules.Sight.NONE,
		"review focus 5: 8 blocks away in the dark, crouching: unseen")


func test_just_beyond_sight_is_half_seen() -> void:
	# half-seen reaches HALF_SEEN × the sight range: a shape at the edge of what it can make out
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -20.0), 1.0, _open), StealthRules.Sight.HALF)
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -25.0), 1.0, _open), StealthRules.Sight.NONE)
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -9.0), 0.45, _open), StealthRules.Sight.HALF)


func test_the_view_is_120_degrees() -> void:
	var at := func(deg: float) -> Vector3: return EYE + Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(deg)) * 8.0
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, at.call(0.0), 1.0, _open), StealthRules.Sight.FULL, "straight ahead")
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, at.call(58.0), 1.0, _open), StealthRules.Sight.FULL, "58° to the side")
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, at.call(-58.0), 1.0, _open), StealthRules.Sight.FULL)
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, at.call(62.0), 1.0, _open), StealthRules.Sight.NONE, "62°: outside")
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, at.call(180.0), 1.0, _open), StealthRules.Sight.NONE, "behind it")
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, 1.5), 1.0, _open), StealthRules.Sight.NONE,
		"right behind it, too: a monster has no eyes in the back of its head")


func test_a_wall_blocks_the_line_of_sight() -> void:
	var wall := func(p: Vector3i) -> bool: return p.z == -5
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -10.0), 1.0, wall), StealthRules.Sight.NONE)
	var low_wall := func(p: Vector3i) -> bool: return p.z == -5 and p.y <= 30
	assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -10.0), 1.0, low_wall), StealthRules.Sight.FULL,
		"a wall below the eyes blocks nothing")


func test_glass_bushes_water_and_open_doors_do_not_block_sight() -> void:
	for id in [BlockIds.AIR, BlockIds.GLASS, BlockIds.BUSH, BlockIds.WATER, BlockIds.DOOR_OPEN]:
		assert_false(StealthRules.blocks_sight(id), BlockIds.display_name(id))
	for id in [BlockIds.STONE, BlockIds.LEAVES, BlockIds.DOOR, BlockIds.BARREL, BlockIds.CLOSET]:
		assert_true(StealthRules.blocks_sight(id), BlockIds.display_name(id))


func test_hidden_players_are_never_seen() -> void:
	var vis := StealthRules.visibility(1.0, false, true, false)
	for d in [0.5, 1.0, 3.0, 10.0]:
		assert_eq(StealthRules.sight(EYE, Vector3.FORWARD, EYE + Vector3(0, 0, -d), vis, _open), StealthRules.Sight.NONE,
			"%.1f blocks in front, in daylight" % d)


# --- Noise (§12.5) ---

func test_noise_radii() -> void:
	assert_eq(StealthRules.NOISE_SPRINT, 12.0)
	assert_eq(StealthRules.NOISE_WALK, 6.0)
	assert_eq(StealthRules.NOISE_CROUCH, 1.5)
	assert_eq(StealthRules.NOISE_LANDING, 8.0)
	assert_eq(StealthRules.NOISE_BREAK, 7.0)
	assert_eq(StealthRules.NOISE_ATTACK, 6.0)


func test_moving_makes_noise_by_speed_and_crouching_is_quiet() -> void:
	assert_eq(StealthRules.move_noise(0.0, false), 0.0, "standing still is silent")
	assert_eq(StealthRules.move_noise(0.3, false), 0.0)
	assert_eq(StealthRules.move_noise(6.0, false), 6.0, "walking")
	assert_eq(StealthRules.move_noise(9.0, false), 12.0, "running (the Speed potion, flying)")
	assert_eq(StealthRules.move_noise(3.0, true), 1.5, "crouching")
	assert_eq(StealthRules.move_noise(9.0, true), 1.5, "crouching is quiet at any speed")
	assert_eq(StealthRules.move_noise(0.0, true), 0.0)


func test_a_noise_is_heard_within_its_radius() -> void:
	assert_true(StealthRules.hears(Vector3(0, 10, 0), Vector3(5.9, 10, 0), StealthRules.NOISE_WALK))
	assert_false(StealthRules.hears(Vector3(0, 10, 0), Vector3(6.1, 10, 0), StealthRules.NOISE_WALK))
	assert_true(StealthRules.hears(Vector3(0, 10, 0), Vector3(1.4, 10, 0), StealthRules.NOISE_CROUCH))
	assert_false(StealthRules.hears(Vector3(0, 10, 0), Vector3(2.0, 10, 0), StealthRules.NOISE_CROUCH), "crouching past it")
	assert_false(StealthRules.hears(Vector3(0, 10, 0), Vector3(0, 10, 0), 0.0), "silence is never heard")


func test_landing_a_jump_thuds_but_stepping_down_a_block_does_not() -> void:
	assert_true(StealthRules.landed(-9.0, 0.0), "a jump from the ground lands at 9 m/s")
	assert_false(StealthRules.landed(-6.9, 0.0), "stepping down one block")
	assert_false(StealthRules.landed(-9.0, -9.5), "still falling")


# --- The mind: wander → ? → ! → search the last known spot 6 s → wander ---

func test_a_calm_monster_wanders() -> void:
	var m := StealthRules.Awareness.new()
	assert_eq(m.state, StealthRules.Alert.NONE)
	assert_eq(m.mark(), StealthRules.MARK_NONE)
	m.update(0.3, Vector3.INF, Vector3.INF, Vector3.ZERO)
	assert_eq(m.state, StealthRules.Alert.NONE)


func test_a_noise_makes_it_suspicious_and_it_walks_to_the_noise() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3.INF, Vector3(8, 0, 0), Vector3.ZERO)
	assert_eq(m.state, StealthRules.Alert.SUSPICIOUS)
	assert_eq(m.mark(), StealthRules.MARK_QUESTION, "?")
	assert_eq(m.spot, Vector3(8, 0, 0), "where it goes")
	m.update(0.3, Vector3.INF, Vector3(9, 0, 0), Vector3(2, 0, 0))
	assert_eq(m.spot, Vector3(9, 0, 0), "a newer noise moves the spot")


func test_suspicious_at_the_noise_it_searches_for_6_seconds_then_wanders() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3.INF, Vector3(8, 0, 0), Vector3.ZERO)
	m.update(0.3, Vector3.INF, Vector3.INF, Vector3(7.5, 0, 0))
	assert_eq(m.state, StealthRules.Alert.SEARCH, "got there: looks around")
	assert_eq(m.mark(), StealthRules.MARK_QUESTION)
	_run(m, 5.7)
	assert_eq(m.state, StealthRules.Alert.SEARCH, "5.7 s into the search")
	_run(m, 0.6)
	assert_eq(m.state, StealthRules.Alert.NONE, "after 6 s: back to wandering")
	assert_false(m.spot.is_finite())


func test_a_suspicious_monster_that_never_gets_there_gives_up() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3.INF, Vector3(30, 0, 0), Vector3.ZERO)
	_run(m, StealthRules.SUSPICIOUS_TIME - 0.5)
	assert_eq(m.state, StealthRules.Alert.SUSPICIOUS)
	_run(m, 0.6)
	assert_eq(m.state, StealthRules.Alert.SEARCH, "stuck: it looks around where it is")


func test_seeing_you_is_alert_and_it_chases() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3(5, 0, 0), Vector3.INF, Vector3.ZERO)
	assert_eq(m.state, StealthRules.Alert.ALERT)
	assert_eq(m.mark(), StealthRules.MARK_BANG, "!")
	assert_true(m.sees)
	assert_eq(m.spot, Vector3(5, 0, 0))
	for from in [StealthRules.Alert.SUSPICIOUS, StealthRules.Alert.SEARCH]:
		var n := StealthRules.Awareness.new()
		n.state = from
		n.update(0.3, Vector3(5, 0, 0), Vector3.INF, Vector3.ZERO)
		assert_eq(n.state, StealthRules.Alert.ALERT, "from %d" % from)


func test_losing_sight_it_goes_to_the_last_known_spot_then_searches_6_seconds() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3(10, 0, 0), Vector3.INF, Vector3.ZERO)
	m.update(0.3, Vector3.INF, Vector3.INF, Vector3(4, 0, 0))
	assert_eq(m.state, StealthRules.Alert.ALERT, "still after you, on the way to where you were")
	assert_false(m.sees)
	assert_eq(m.spot, Vector3(10, 0, 0), "the last known spot")
	m.update(0.3, Vector3.INF, Vector3.INF, Vector3(9.2, 0, 0))
	assert_eq(m.state, StealthRules.Alert.SEARCH, "there: searches")
	assert_eq(m.spot, Vector3(10, 0, 0), "around the last known spot")
	_run(m, StealthRules.SEARCH_TIME - 0.3)
	assert_eq(m.state, StealthRules.Alert.SEARCH)
	_run(m, 0.6)
	assert_eq(m.state, StealthRules.Alert.NONE, "gives up: wanders again")


func test_a_lost_chase_searches_after_5_seconds_even_if_it_never_gets_there() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3(20, 0, 0), Vector3.INF, Vector3.ZERO)
	_run(m, StealthRules.LOST_TIME - 0.4)
	assert_eq(m.state, StealthRules.Alert.ALERT)
	_run(m, 0.6)
	assert_eq(m.state, StealthRules.Alert.SEARCH)


func test_hearing_you_during_a_search_makes_it_suspicious_again() -> void:
	var m := StealthRules.Awareness.new()
	m.state = StealthRules.Alert.SEARCH
	m.timer = 3.0
	m.update(0.3, Vector3.INF, Vector3(3, 0, 3), Vector3.ZERO)
	assert_eq(m.state, StealthRules.Alert.SUSPICIOUS)
	assert_eq(m.spot, Vector3(3, 0, 3))


func test_a_noise_during_a_lost_chase_moves_the_last_known_spot() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3(10, 0, 0), Vector3.INF, Vector3.ZERO)
	m.update(0.3, Vector3.INF, Vector3(10, 0, 6), Vector3(2, 0, 0))
	assert_eq(m.state, StealthRules.Alert.ALERT)
	assert_eq(m.spot, Vector3(10, 0, 6), "follows the sound")


func test_a_monster_that_saw_you_hide_searches_next_to_the_hiding_spot() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3(6, 0, 0), Vector3.INF, Vector3.ZERO)
	var spot := StealthRules.search_spot(Vector3i(7, 0, 0), Vector3(6.2, 0, 0.5), _open)
	assert_eq(spot, Vector3(6.5, 0, 0.5), "the side you went in from")
	m.saw_hide(spot)
	assert_eq(m.state, StealthRules.Alert.ALERT, "on its way there")
	assert_false(m.sees)
	m.update(0.3, Vector3.INF, Vector3.INF, Vector3(6.0, 0, 0.5))
	assert_eq(m.state, StealthRules.Alert.SEARCH, "searches next to it")
	assert_eq(m.spot, spot)
	_run(m, StealthRules.SEARCH_TIME + 0.3)
	assert_eq(m.state, StealthRules.Alert.NONE, "never finds you: fair, not a trick")


func test_a_calm_monster_is_not_sent_searching_by_a_hide_it_never_saw() -> void:
	var m := StealthRules.Awareness.new()
	m.saw_hide(Vector3(3, 0, 3))
	assert_eq(m.state, StealthRules.Alert.NONE)


func test_forgetting_a_target_calms_it_down() -> void:
	var m := StealthRules.Awareness.new()
	m.update(0.3, Vector3(5, 0, 0), Vector3.INF, Vector3.ZERO)
	m.forget()
	assert_eq(m.state, StealthRules.Alert.NONE)
	assert_false(m.sees)


func _run(m: StealthRules.Awareness, seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		m.update(0.1, Vector3.INF, Vector3.INF, Vector3(100, 0, 100))
		t += 0.1


# --- Hiding spots ---

func test_barrels_and_closets_are_hiding_spots_and_a_bush_is_cover() -> void:
	assert_true(StealthRules.is_hiding_block(BlockIds.BARREL))
	assert_true(StealthRules.is_hiding_block(BlockIds.CLOSET))
	assert_false(StealthRules.is_hiding_block(BlockIds.BUSH), "a bush: walk in and crouch")
	assert_false(StealthRules.is_hiding_block(BlockIds.PLANKS))


func test_crouching_in_a_bush_hides_you() -> void:
	assert_true(StealthRules.in_bush(BlockIds.BUSH, BlockIds.AIR))
	assert_true(StealthRules.in_bush(BlockIds.AIR, BlockIds.BUSH))
	assert_false(StealthRules.in_bush(BlockIds.AIR, BlockIds.LEAVES))
	assert_true(StealthRules.is_hidden(false, true, true), "in a bush, crouching")
	assert_false(StealthRules.is_hidden(false, false, true), "in a bush, standing up")
	assert_false(StealthRules.is_hidden(false, true, false), "crouching in the open")
	assert_true(StealthRules.is_hidden(true, false, false), "inside a barrel")


func test_hiding_needs_a_barrel_or_closet_close_by() -> void:
	var eye := Vector3(0.5, 11.55, 0.5)
	assert_eq(StealthRules.hide_refusal(eye, Vector3i(2, 10, 0), BlockIds.BARREL, false), "")
	assert_eq(StealthRules.hide_refusal(eye, Vector3i(0, 10, 3), BlockIds.CLOSET, false), "")
	assert_eq(StealthRules.hide_refusal(eye, Vector3i(8, 10, 0), BlockIds.BARREL, false), StealthRules.TOO_FAR_MESSAGE)
	assert_eq(StealthRules.hide_refusal(eye, Vector3i(2, 10, 0), BlockIds.PLANKS, false), "?", "not a hiding spot: nothing to say")
	assert_eq(StealthRules.hide_refusal(eye, Vector3i(2, 10, 0), BlockIds.BARREL, true), StealthRules.TAKEN_MESSAGE)
	assert_eq(StealthRules.hide_refusal(Vector3.INF, Vector3i(2, 10, 0), BlockIds.BARREL, false), "?")


func test_the_search_spot_is_the_free_side_you_went_in_from() -> void:
	var cell := Vector3i(0, 10, 0)
	assert_eq(StealthRules.search_spot(cell, Vector3(0.5, 10, 2.1), _open), Vector3(0.5, 10, 1.5))
	assert_eq(StealthRules.search_spot(cell, Vector3(-1.5, 10, 0.4), _open), Vector3(-0.5, 10, 0.5))
	var walled := func(p: Vector3i) -> bool: return p == Vector3i(0, 10, 1)
	assert_eq(StealthRules.search_spot(cell, Vector3(0.5, 10, 2.1), walled), Vector3(1.5, 10, 0.5),
		"that side is a wall: the nearest free side")


# --- Crouching ---

func test_crouching_halves_speed_and_lowers_the_eyes() -> void:
	assert_eq(StealthRules.CROUCH_SPEED, 0.5)
	assert_lt(StealthRules.CROUCH_EYE, 0.7)


# --- The HUD: an eye and noise bars (icons, not numbers) ---

func test_the_eye_is_open_half_or_closed() -> void:
	assert_eq(StealthRules.eye(1.0), StealthRules.EYE_OPEN)
	assert_eq(StealthRules.eye(0.7), StealthRules.EYE_OPEN)
	assert_eq(StealthRules.eye(0.45), StealthRules.EYE_HALF, "night")
	assert_eq(StealthRules.eye(0.15), StealthRules.EYE_HALF)
	assert_eq(StealthRules.eye(0.0), StealthRules.EYE_CLOSED, "hidden")


func test_noise_bars() -> void:
	assert_eq(StealthRules.noise_bars(0.0), 0)
	assert_eq(StealthRules.noise_bars(StealthRules.NOISE_CROUCH), 1)
	assert_eq(StealthRules.noise_bars(StealthRules.NOISE_WALK), 2)
	assert_eq(StealthRules.noise_bars(StealthRules.NOISE_LANDING), 2)
	assert_eq(StealthRules.noise_bars(StealthRules.NOISE_SPRINT), 3)


# --- The danger arrow (research A3) ---

func test_the_arrow_shows_only_for_a_monster_behind_or_off_screen() -> void:
	assert_true(StealthRules.arrow_wanted(true, false), "behind the camera")
	assert_true(StealthRules.arrow_wanted(false, false), "off the screen")
	assert_false(StealthRules.arrow_wanted(false, true), "on the screen: you can see it")


func test_the_arrow_sits_on_the_screen_edge_towards_the_monster() -> void:
	var screen := Vector2(1280, 720)
	var right := StealthRules.arrow_edge(screen, Vector2(1, 0), 60.0)
	assert_almost_eq(right, Vector2(1220, 360), Vector2.ONE * 0.5)
	var down := StealthRules.arrow_edge(screen, Vector2(0, 1), 60.0)
	assert_almost_eq(down, Vector2(640, 660), Vector2.ONE * 0.5)
	var corner := StealthRules.arrow_edge(screen, Vector2(-1, -1), 60.0)
	assert_almost_eq(corner, Vector2(340, 60), Vector2.ONE * 0.5, "up-left: on the top edge")


func test_the_arrow_glows_then_fades_and_never_nags() -> void:
	assert_gt(StealthRules.arrow_alpha(0.3, false), 0.8)
	assert_eq(StealthRules.arrow_alpha(StealthRules.ARROW_TIME + 0.1, false), 0.0, "gone")
	assert_lt(StealthRules.arrow_alpha(StealthRules.ARROW_TIME - 0.1, false), 0.3, "fading")
	assert_eq(StealthRules.arrow_scale(0.4, true), 1.0, "reduce motion: no pulsing")
	assert_ne(StealthRules.arrow_scale(0.4, false), 1.0, "it pulses otherwise")
	assert_true(StealthRules.arrow_again(-INF, 0.0))
	assert_false(StealthRules.arrow_again(0.0, StealthRules.ARROW_COOLDOWN - 0.1), "the same monster: not again so soon")
	assert_true(StealthRules.arrow_again(0.0, StealthRules.ARROW_COOLDOWN + 0.1))
