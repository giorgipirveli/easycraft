extends GutTest
## Physics Lab (M3 Task 6, spec §14.3): the LAB button's modes, which game modes allow them, and each
## mode's movement rules as pure functions (gravity, slow-motion time, zero-G drift and push-off).

const L := LabRules.Mode


# --- The LAB cycle and what each game mode allows ---

func test_the_lab_button_cycles_every_mode_in_sandbox() -> void:
	var seen: Array[int] = []
	var m: int = L.NORMAL
	for i in LabRules.CYCLE.size():
		seen.append(m)
		m = LabRules.next(m, ModeRules.SANDBOX)
	assert_eq(seen, [L.NORMAL, L.MOON, L.ZERO_G, L.FLY, L.GHOST, L.SLOW])
	assert_eq(m, L.NORMAL, "and round again")


func test_survivor_keeps_normal_and_paid_fly_only() -> void:
	assert_eq(LabRules.next(L.NORMAL, ModeRules.SURVIVOR), L.FLY, "Moon and Zero-G are skipped")
	assert_eq(LabRules.next(L.FLY, ModeRules.SURVIVOR), L.NORMAL, "Ghost and Slow are skipped")
	for m: int in [L.MOON, L.ZERO_G, L.GHOST, L.SLOW]:
		assert_false(LabRules.allowed(m, ModeRules.SURVIVOR), "survivor: no %s" % LabRules.label(m))
		assert_true(LabRules.allowed(m, ModeRules.SANDBOX), "sandbox: %s" % LabRules.label(m))
	for m: int in [L.NORMAL, L.FLY]:
		assert_true(LabRules.allowed(m, ModeRules.SURVIVOR))


func test_leaving_a_forbidden_mode_goes_to_an_allowed_one() -> void:
	for m: int in [L.MOON, L.ZERO_G, L.GHOST, L.SLOW]:
		assert_true(LabRules.allowed(LabRules.next(m, ModeRules.SURVIVOR), ModeRules.SURVIVOR), LabRules.label(m))


func test_the_lab_is_a_sandbox_rule() -> void:
	assert_true(ModeRules.allows(ModeRules.SANDBOX, ModeRules.PHYSICS_LAB))
	assert_false(ModeRules.allows(ModeRules.SURVIVOR, ModeRules.PHYSICS_LAB))


func test_bad_values_are_normal() -> void:
	assert_eq(LabRules.valid(-1), L.NORMAL)
	assert_eq(LabRules.valid(99), L.NORMAL)
	assert_eq(LabRules.valid(L.SLOW), L.SLOW)
	assert_eq(LabRules.next(99, ModeRules.SANDBOX), L.MOON, "a broken mode counts as Normal")


func test_every_mode_has_a_short_label_and_a_toast() -> void:
	var labels := {}
	for m: int in LabRules.CYCLE:
		assert_ne(LabRules.label(m), "")
		assert_lte(LabRules.label(m).length(), 6, "fits a round HUD button")
		assert_ne(LabRules.toast(m), "")
		labels[LabRules.label(m)] = true
	assert_eq(labels.size(), LabRules.CYCLE.size(), "every label differs")
	assert_eq(LabRules.label(L.NORMAL), "WALK", "the same word as the WALK/FLY/GHOST button")


# --- Lab modes and the physics switch (Normal / Fly / Ghost) ---

func test_each_lab_mode_moves_the_body_like_its_physics_mode() -> void:
	assert_eq(LabRules.physics_mode(L.NORMAL), PhysicsMode.Mode.NORMAL)
	assert_eq(LabRules.physics_mode(L.MOON), PhysicsMode.Mode.NORMAL, "walks, with less gravity")
	assert_eq(LabRules.physics_mode(L.SLOW), PhysicsMode.Mode.NORMAL, "walks, slowly")
	assert_eq(LabRules.physics_mode(L.ZERO_G), PhysicsMode.Mode.FLY, "floats, and still bumps into blocks")
	assert_eq(LabRules.physics_mode(L.FLY), PhysicsMode.Mode.FLY)
	assert_eq(LabRules.physics_mode(L.GHOST), PhysicsMode.Mode.GHOST)


func test_the_physics_switch_picks_the_plain_lab_mode() -> void:
	assert_eq(LabRules.from_physics(PhysicsMode.Mode.NORMAL), L.NORMAL)
	assert_eq(LabRules.from_physics(PhysicsMode.Mode.FLY), L.FLY)
	assert_eq(LabRules.from_physics(PhysicsMode.Mode.GHOST), L.GHOST)
	assert_eq(LabRules.from_physics(42), L.NORMAL)


# --- Gravity and time ---

func test_gravity_factors() -> void:
	assert_eq(LabRules.gravity_factor(L.NORMAL), 1.0)
	assert_almost_eq(LabRules.gravity_factor(L.MOON), 0.35, 0.0001)
	assert_eq(LabRules.gravity_factor(L.ZERO_G), 0.0)
	assert_eq(LabRules.gravity_factor(L.SLOW), 1.0, "slow motion slows time, not gravity")


func test_moon_jumps_go_higher_and_hang_longer() -> void:
	var normal := LabRules.jump_height(L.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY)
	var moon := LabRules.jump_height(L.MOON, Player.JUMP_VELOCITY, Player.GRAVITY)
	assert_almost_eq(normal, 81.0 / 48.0, 0.001, "about 1.7 blocks")
	assert_almost_eq(moon, normal / 0.35, 0.001, "almost 3 times as high")
	assert_gt(moon, 4.5, "over a small house")
	assert_almost_eq(LabRules.air_time(L.MOON, Player.JUMP_VELOCITY, Player.GRAVITY),
		LabRules.air_time(L.NORMAL, Player.JUMP_VELOCITY, Player.GRAVITY) / 0.35, 0.001, "floaty")


func test_slow_motion_runs_the_body_at_four_tenths_time() -> void:
	assert_almost_eq(LabRules.time_factor(L.SLOW), 0.4, 0.0001)
	for m: int in [L.NORMAL, L.MOON, L.ZERO_G, L.FLY, L.GHOST]:
		assert_eq(LabRules.time_factor(m), 1.0, LabRules.label(m))
	assert_almost_eq(LabRules.body_delta(L.SLOW, 0.1), 0.04, 0.00001)
	assert_eq(LabRules.body_delta(L.NORMAL, 0.1), 0.1)


func test_a_slow_motion_jump_is_as_high_and_takes_longer() -> void:
	var v := Player.JUMP_VELOCITY
	var g := Player.GRAVITY
	assert_almost_eq(LabRules.jump_height(L.SLOW, v, g), LabRules.jump_height(L.NORMAL, v, g), 0.0001)
	assert_almost_eq(LabRules.air_time(L.SLOW, v, g), LabRules.air_time(L.NORMAL, v, g) / 0.4, 0.0001)


func test_without_gravity_nothing_comes_back_down() -> void:
	assert_eq(LabRules.jump_height(L.ZERO_G, 9.0, 24.0), INF)
	assert_eq(LabRules.air_time(L.ZERO_G, 9.0, 24.0), INF)


# --- Zero-G ---

func test_zero_g_has_no_gravity_so_a_still_body_stays_still() -> void:
	var v := Vector3.ZERO
	for i in 60:
		v = LabRules.zero_g_velocity(v, Vector3.ZERO, 1.0 / 60.0)
	assert_eq(v, Vector3.ZERO)


func test_zero_g_drift_keeps_going_and_fades_only_slightly() -> void:
	var v := Vector3(5, 0, 0)
	for i in 60:
		v = LabRules.zero_g_velocity(v, Vector3.ZERO, 1.0 / 60.0)
	assert_lt(v.length(), 5.0, "a little damping")
	assert_gt(v.length(), 3.5, "but it drifts on")
	assert_almost_eq(v.normalized(), Vector3.RIGHT, Vector3.ONE * 0.0001, "the same way")


func test_zero_g_thrust_is_gentle() -> void:
	var v := Vector3.ZERO
	for i in 30:
		v = LabRules.zero_g_velocity(v, Vector3.FORWARD, 1.0 / 60.0)
	assert_gt(v.dot(Vector3.FORWARD), 0.5, "the stick pushes a little")
	assert_lt(v.length(), Player.WALK_SPEED * 0.5, "much slower than walking")
	for i in 600:
		v = LabRules.zero_g_velocity(v, Vector3.FORWARD, 1.0 / 60.0)
	assert_almost_eq(v.length(), LabRules.THRUST_SPEED, 0.05, "never faster than THRUST_SPEED by thrust alone")


func test_jump_and_down_thrust_up_and_down_gently() -> void:
	var up := Vector3.ZERO
	var down := Vector3.ZERO
	for i in 60:
		up = LabRules.zero_g_velocity(up, LabRules.wish(Vector3.ZERO, 1.0), 1.0 / 60.0)
		down = LabRules.zero_g_velocity(down, LabRules.wish(Vector3.ZERO, -1.0), 1.0 / 60.0)
	assert_gt(up.y, 0.5)
	assert_lt(down.y, -0.5)
	assert_lte(up.length(), LabRules.THRUST_SPEED + 0.001)


func test_thrust_never_brakes_a_faster_drift() -> void:
	var fast := Vector3(0, 0, -LabRules.PUSH_OFF_SPEED)
	var v := LabRules.zero_g_velocity(fast, Vector3.FORWARD, 1.0 / 60.0)
	assert_gt(v.length(), LabRules.THRUST_SPEED, "only damping slows a push-off down")


func test_zero_g_speed_is_capped() -> void:
	var v := LabRules.zero_g_velocity(Vector3(100, 0, 0), Vector3.ZERO, 1.0 / 60.0)
	assert_almost_eq(v.length(), LabRules.ZERO_G_MAX_SPEED, 0.001)


func test_moving_into_a_wall_pushes_off_it() -> void:
	var wall := Vector3.RIGHT   # the wall's normal: the wall is on the -X side
	assert_true(LabRules.wants_push_off(wall, Vector3.LEFT), "pushing into it")
	assert_false(LabRules.wants_push_off(wall, Vector3.RIGHT), "moving away")
	assert_false(LabRules.wants_push_off(wall, Vector3.FORWARD), "sliding along it")
	assert_false(LabRules.wants_push_off(wall, Vector3.ZERO), "not touching the stick")
	var v := LabRules.push_off_velocity(Vector3(-0.1, 0, -2.0), wall)
	assert_almost_eq(v.x, LabRules.PUSH_OFF_SPEED, 0.0001, "away from the wall")
	assert_almost_eq(v.z, -2.0, 0.0001, "keeps sliding along it")
	assert_gt(LabRules.PUSH_OFF_SPEED, LabRules.THRUST_SPEED * 2.0, "a kick is the fast way to get around")


func test_pushing_down_on_the_floor_kicks_up() -> void:
	var v := LabRules.push_off_velocity(Vector3.ZERO, Vector3.UP)
	assert_true(LabRules.wants_push_off(Vector3.UP, LabRules.wish(Vector3.ZERO, -1.0)))
	assert_almost_eq(v, Vector3(0, LabRules.PUSH_OFF_SPEED, 0), Vector3.ONE * 0.0001)


func test_zero_g_scales_with_size() -> void:
	var giant := LabRules.push_off_velocity(Vector3.ZERO, Vector3.UP, 1.7)
	assert_almost_eq(giant.y, LabRules.PUSH_OFF_SPEED * 1.7, 0.0001)
	var v := Vector3.ZERO
	for i in 600:
		v = LabRules.zero_g_velocity(v, Vector3.FORWARD, 1.0 / 60.0, 0.6)
	assert_almost_eq(v.length(), LabRules.THRUST_SPEED * 0.6, 0.05)


func test_the_wish_combines_the_stick_and_up_down() -> void:
	assert_eq(LabRules.wish(Vector3.FORWARD, 0.0), Vector3.FORWARD)
	assert_eq(LabRules.wish(Vector3.ZERO, 1.0), Vector3.UP)
	assert_almost_eq(LabRules.wish(Vector3.FORWARD, 1.0).length(), 1.0, 0.0001, "never more than full thrust")
