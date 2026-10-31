extends GutTest
## Weapons as pure rules (M1b Task 11): the weapon table, melee cone and aim assist, host checks
## (reach, cooldown), knockback (and damage: dummies, monsters, animals), arrows, the boomerang and the bullseye.

const DT := 1.0 / 60.0

var no_blocks := func(_cell: Vector3i) -> bool: return false


func _target(pos: Vector3, radius: float = 0.3) -> Dictionary:
	return {"pos": pos, "radius": radius}


# --- The weapon table ---

func test_weapon_table_is_complete_and_sane() -> void:
	for id in [ItemIds.SWORD, ItemIds.BOW, ItemIds.BOOMERANG, ItemIds.HAMMER, ItemIds.AXE, ItemIds.PICKAXE]:
		assert_true(WeaponRules.is_weapon(id), ItemIds.display_name(id))
		var w := WeaponRules.stats(id)
		for key in ["kind", "damage", "reach", "cooldown", "knockback", "arc", "max_hits", "power", "sound"]:
			assert_true(w.has(key), "%s has %s" % [ItemIds.display_name(id), key])
		assert_gt(int(w.damage), 0, ItemIds.display_name(id))
		assert_gt(float(w.cooldown), 0.0, ItemIds.display_name(id))
		assert_gt(float(w.reach), 0.0, ItemIds.display_name(id))
		assert_gt(float(w.knockback), 0.0, ItemIds.display_name(id))
		assert_gt(int(w.max_hits), 0, ItemIds.display_name(id))
		assert_true(w.kind in [WeaponRules.MELEE, WeaponRules.BOW, WeaponRules.BOOMERANG], ItemIds.display_name(id))
	for id in [BlockIds.STONE, ItemIds.WAND, ItemIds.DUMMY, ItemIds.BULLSEYE, 999]:
		assert_false(WeaponRules.is_weapon(id), str(id))
		assert_eq(WeaponRules.stats(id), {})


func test_hammer_is_slow_and_hits_hardest() -> void:
	var hammer := WeaponRules.stats(ItemIds.HAMMER)
	for id in WeaponRules.WEAPONS:
		if id != ItemIds.HAMMER:
			assert_gt(float(hammer.cooldown), float(WeaponRules.stats(id).cooldown), ItemIds.display_name(id))
			assert_gt(float(hammer.knockback), float(WeaponRules.stats(id).knockback), ItemIds.display_name(id))


func test_tools_have_their_block_powers() -> void:
	assert_eq(WeaponRules.stats(ItemIds.AXE).power, WeaponRules.POWER_FELL)
	assert_eq(WeaponRules.stats(ItemIds.PICKAXE).power, WeaponRules.POWER_TUNNEL)
	assert_eq(WeaponRules.stats(ItemIds.HAMMER).power, WeaponRules.POWER_SMASH)
	assert_eq(WeaponRules.stats(ItemIds.SWORD).power, &"")


# --- Melee cone and aim assist ---

func test_melee_cone_hits_in_front_within_reach() -> void:
	var o := Vector3(0, 1, 0)
	var fwd := Vector3(0, 0, -1)
	assert_true(WeaponRules.in_cone(o, fwd, Vector3(0, 1, -2), 3.0, 55.0), "straight ahead")
	assert_true(WeaponRules.in_cone(o, fwd, Vector3(1, 0.6, -2), 3.0, 55.0), "a bit to the side and lower")
	assert_false(WeaponRules.in_cone(o, fwd, Vector3(0, 1, 2), 3.0, 55.0), "behind")
	assert_false(WeaponRules.in_cone(o, fwd, Vector3(2, 1, 0), 3.0, 55.0), "beside")
	assert_false(WeaponRules.in_cone(o, fwd, Vector3(0, 1, -5), 3.0, 55.0), "too far")
	assert_true(WeaponRules.in_cone(o, fwd, Vector3(0, 1, -3.4), 3.0, 55.0, 0.5), "a big body reaches into range")
	assert_false(WeaponRules.in_cone(o, fwd, Vector3(0, 5, -1), 3.0, 55.0), "far above")


func test_melee_hits_the_closest_targets_up_to_the_weapon_limit() -> void:
	var o := Vector3(0, 1, 0)
	var targets: Array[Dictionary] = []
	for z in [-2.5, -1.0, -1.5, -2.0, -0.8]:
		targets.append(_target(Vector3(0, 1, z)))
	targets.append(_target(Vector3(0, 1, 2)))            # behind
	var hits := WeaponRules.melee_hits(o, Vector3.FORWARD, targets, ItemIds.SWORD)
	assert_eq(hits, [4, 1, 2], "the three closest in front")
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, targets, ItemIds.AXE), [4], "the axe hits one")


func test_sword_finisher_spins_and_hits_all_around() -> void:
	var o := Vector3(0, 1, 0)
	var targets: Array[Dictionary] = [_target(Vector3(0, 1, 2))]
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, targets, ItemIds.SWORD, 0), [])
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, targets, ItemIds.SWORD, WeaponRules.COMBO_STEPS - 1), [0])


func test_aim_assist_snaps_within_the_assist_angle_only() -> void:
	var o := Vector3.ZERO
	var fwd := Vector3(0, 0, -1)
	var near := Vector3(sin(deg_to_rad(10.0)), 0, -cos(deg_to_rad(10.0))) * 2.0
	var wide := Vector3(sin(deg_to_rad(60.0)), 0, -cos(deg_to_rad(60.0))) * 2.0
	var snapped := WeaponRules.aim_assist(o, fwd, [near], 5.0, 20.0)
	assert_almost_eq(snapped.angle_to(near), 0.0, 0.001, "snaps onto a target 10 degrees off")
	assert_almost_eq(WeaponRules.aim_assist(o, fwd, [wide], 5.0, 20.0).angle_to(fwd), 0.0, 0.001, "60 degrees off: no snap")
	assert_almost_eq(WeaponRules.aim_assist(o, fwd, [near * 5.0], 5.0, 20.0).angle_to(fwd), 0.0, 0.001, "too far: no snap")
	var two := WeaponRules.aim_assist(o, fwd, [wide, near, Vector3(-0.2, 0, -2)], 5.0, 20.0)
	assert_almost_eq(two.angle_to(Vector3(-0.2, 0, -2)), 0.0, 0.001, "the target closest to the aim wins")
	assert_eq(WeaponRules.assist_target(o, fwd, [wide, near, Vector3(-0.2, 0, -2)], 5.0, 20.0), 2)
	assert_eq(WeaponRules.assist_target(o, fwd, [wide], 5.0, 20.0), -1)


func _at_angle(o: Vector3, degrees: float, dist: float) -> Vector3:
	return o + Vector3(sin(deg_to_rad(degrees)), 0, -cos(deg_to_rad(degrees))) * dist


func test_aim_assist_turns_a_near_miss_into_a_hit() -> void:
	var o := Vector3(0, 1, 0)
	var arc := float(WeaponRules.stats(ItemIds.AXE).arc)
	assert_lt(arc, WeaponRules.ASSIST_ANGLE, "the axe swings narrower than the assist")
	var slightly_off: Array[Dictionary] = [_target(_at_angle(o, arc + 3.0, 2.0))]
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, slightly_off, ItemIds.AXE), [0], "assisted")
	var way_off: Array[Dictionary] = [_target(_at_angle(o, WeaponRules.ASSIST_ANGLE + 10.0, 2.0))]
	assert_eq(WeaponRules.melee_hits(o, Vector3.FORWARD, way_off, ItemIds.AXE), [], "no help that far off")


# --- Host checks ---

func test_host_rejects_hits_beyond_reach() -> void:
	var o := Vector3(0, 1, 0)
	var reach := float(WeaponRules.stats(ItemIds.SWORD).reach)
	assert_true(WeaponRules.hit_in_reach(o, o + Vector3(0, 0, -reach), ItemIds.SWORD))
	assert_true(WeaponRules.hit_in_reach(o, o + Vector3(0, 0, -(reach + WeaponRules.REACH_TOLERANCE * 0.9)), ItemIds.SWORD), "latency slack")
	assert_false(WeaponRules.hit_in_reach(o, o + Vector3(0, 0, -(reach + WeaponRules.REACH_TOLERANCE + 0.5)), ItemIds.SWORD))
	assert_false(WeaponRules.hit_in_reach(o, o, 999), "not a weapon")


func test_host_rejects_attacks_faster_than_the_cooldown() -> void:
	var cd_ms := int(float(WeaponRules.stats(ItemIds.HAMMER).cooldown) * 1000.0)
	assert_true(WeaponRules.cooldown_ok(-1, 5000, ItemIds.HAMMER), "first attack")
	assert_false(WeaponRules.cooldown_ok(5000, 5000 + cd_ms / 4, ItemIds.HAMMER), "far too fast")
	assert_true(WeaponRules.cooldown_ok(5000, 5000 + cd_ms, ItemIds.HAMMER))
	assert_true(WeaponRules.cooldown_ok(5000, 5000 + int(cd_ms * 0.9), ItemIds.HAMMER), "network jitter slack")
	assert_false(WeaponRules.cooldown_ok(-1, 5000, ItemIds.WAND), "not a weapon")


# --- Knockback, never damage, for players and buddies (animals: owner feedback #26) ---

func test_players_and_buddies_get_knockback_but_no_damage() -> void:
	for kind in [WeaponRules.PLAYER, WeaponRules.BUDDY, WeaponRules.BULLSEYE_TARGET]:
		for id in WeaponRules.WEAPONS:
			assert_eq(WeaponRules.damage_to(kind, id), 0, "%s by %s" % [kind, ItemIds.display_name(id)])
	for id in WeaponRules.WEAPONS:
		assert_gt(WeaponRules.damage_to(WeaponRules.DUMMY, id), 0, ItemIds.display_name(id))
		assert_gt(WeaponRules.damage_to(WeaponRules.MONSTER, id), 0, ItemIds.display_name(id))
		assert_gt(WeaponRules.damage_to(WeaponRules.ANIMAL, id), 0, "animals are hurt too (#26): %s" % ItemIds.display_name(id))
	var push := WeaponRules.knockback(Vector3(0, 1, 0), Vector3(0, 0.5, -2), ItemIds.HAMMER)
	assert_lt(push.z, -5.0, "pushed away from the attacker")
	assert_gt(push.y, 0.0, "and up a little")
	assert_gt(push.length(), WeaponRules.knockback(Vector3(0, 1, 0), Vector3(0, 0.5, -2), ItemIds.PICKAXE).length(), "the hammer pushes hardest")
	assert_gt(WeaponRules.knockback(Vector3.ZERO, Vector3.ZERO, ItemIds.SWORD).length(), 0.0, "even point blank")


func test_sword_combo_counts_up_within_the_window_and_the_finisher_hits_harder() -> void:
	assert_eq(WeaponRules.combo_next(ItemIds.SWORD, 0, 0.3), 1)
	assert_eq(WeaponRules.combo_next(ItemIds.SWORD, 1, 0.3), 2)
	assert_eq(WeaponRules.combo_next(ItemIds.SWORD, 2, 0.3), 0, "starts over after the finisher")
	assert_eq(WeaponRules.combo_next(ItemIds.SWORD, 1, WeaponRules.COMBO_WINDOW + 0.1), 0, "too slow")
	assert_eq(WeaponRules.combo_next(ItemIds.HAMMER, 0, 0.3), 0, "only the sword combos")
	assert_gt(WeaponRules.damage_to(WeaponRules.DUMMY, ItemIds.SWORD, 2), WeaponRules.damage_to(WeaponRules.DUMMY, ItemIds.SWORD, 0))


# --- Arrows ---

func test_arrow_falls_under_gravity() -> void:
	var s := {"pos": Vector3(0.5, 60.5, 0.5), "vel": Vector3(20, 0, 0)}
	for i in 30:
		s = WeaponRules.arrow_step(s.pos, s.vel, DT, no_blocks)
	assert_false(s.stuck)
	assert_lt(s.vel.y, 0.0)
	assert_lt(s.pos.y, 60.5)
	assert_almost_eq(s.pos.x, 0.5 + 20.0 * 0.5, 0.01)


func test_arrow_stops_at_the_first_solid_block() -> void:
	var walls := func(c: Vector3i) -> bool: return c.x == 10 or c.x == 12
	var s := {"pos": Vector3(0.5, 5.5, 0.5), "vel": Vector3(30, 0, 0), "stuck": false}
	for i in 120:
		s = WeaponRules.arrow_step(s.pos, s.vel, DT, walls)
		if s.stuck:
			break
	assert_true(s.stuck)
	assert_eq((s.cell as Vector3i).x, 10, "stuck in the first wall")
	assert_between(float(s.pos.x), 9.9, 10.001, "at its face")


func test_arrow_sticks_into_the_ground() -> void:
	var floor_blocks := func(c: Vector3i) -> bool: return c.y < 0
	var s := {"pos": Vector3(0.5, 1.5, 0.5), "vel": WeaponRules.arrow_velocity(Vector3(1, 1, 0).normalized(), 0.5), "stuck": false}
	for i in 600:
		s = WeaponRules.arrow_step(s.pos, s.vel, DT, floor_blocks)
		if s.stuck:
			break
	assert_true(s.stuck)
	assert_eq((s.cell as Vector3i).y, -1)
	assert_gt(float(s.pos.x), 3.0, "it flew in an arc first")


func test_draw_power_sets_the_arrow_speed() -> void:
	var full := WeaponRules.arrow_velocity(Vector3.FORWARD, 1.0).length()
	assert_almost_eq(full, WeaponRules.ARROW_SPEED, 0.001)
	assert_lt(WeaponRules.arrow_velocity(Vector3.FORWARD, 0.5).length(), full)
	assert_almost_eq(WeaponRules.arrow_velocity(Vector3.FORWARD, 0.0).length(), WeaponRules.ARROW_SPEED * WeaponRules.MIN_DRAW, 0.001)
	assert_almost_eq(WeaponRules.arrow_velocity(Vector3.FORWARD, 7.0).length(), full, 0.001, "clamped")
	assert_almost_eq(WeaponRules.draw_power(0.0), WeaponRules.MIN_DRAW, 0.001)
	assert_almost_eq(WeaponRules.draw_power(WeaponRules.DRAW_TIME * 2.0), 1.0, 0.001)


func test_launch_direction_lobs_the_arrow_onto_the_aim_point() -> void:
	var from := Vector3(0, 2, 0)
	for to in [Vector3(20, 2, 0), Vector3(0, -3, -25), Vector3(12, 8, 12)]:
		var dir := WeaponRules.launch_direction(from, to, WeaponRules.ARROW_SPEED)
		var s := {"pos": from, "vel": dir * WeaponRules.ARROW_SPEED}
		var closest := INF
		for i in 240:
			s = WeaponRules.arrow_step(s.pos, s.vel, DT, no_blocks)
			closest = minf(closest, (s.pos as Vector3).distance_to(to))
		assert_lt(closest, 0.6, "reaches %s" % to)
	var out_of_range := WeaponRules.launch_direction(from, Vector3(500, 0, 0), WeaponRules.ARROW_SPEED)
	assert_almost_eq(out_of_range.length(), 1.0, 0.001, "still a direction when the point is out of range")


# --- Boomerang ---

func _fly(thrower_at: Callable, blocks: Callable = no_blocks) -> Dictionary:
	var s := WeaponRules.boomerang_start(thrower_at.call(0.0), Vector3(1, 0, 0))
	var farthest := 0.0
	for i in 600:
		s = WeaponRules.boomerang_step(s, thrower_at.call(i * DT), DT, blocks)
		farthest = maxf(farthest, (s.pos as Vector3).distance_to(thrower_at.call(i * DT)))
		if s.caught:
			break
	s.farthest = farthest
	return s


func test_boomerang_flies_out_and_returns_to_the_thrower() -> void:
	var s := _fly(func(_t: float) -> Vector3: return Vector3(0, 1.5, 0))
	assert_true(s.caught, "back in the hand")
	assert_almost_eq(float(s.farthest), float(WeaponRules.stats(ItemIds.BOOMERANG).reach), 0.5)
	assert_lt(float(s.t), WeaponRules.BOOMERANG_MAX_TIME)


func test_boomerang_finds_a_thrower_who_walked_away() -> void:
	var s := _fly(func(t: float) -> Vector3: return Vector3(0, 1.5, 5.0 * t))
	assert_true(s.caught)


func test_boomerang_turns_back_at_a_wall() -> void:
	var wall := func(c: Vector3i) -> bool: return c.x == 5
	var s := _fly(func(_t: float) -> Vector3: return Vector3(0.5, 1.5, 0.5), wall)
	assert_true(s.caught)
	assert_lt(float(s.farthest), 5.0, "never went through the wall")


# --- Targets ---

func test_bullseye_scores_rings_from_10_to_1() -> void:
	var r := WeaponRules.BULLSEYE_RADIUS
	assert_eq(WeaponRules.bullseye_score(0.0, r), 10)
	assert_eq(WeaponRules.bullseye_score(r * 0.05, r), 10)
	assert_eq(WeaponRules.bullseye_score(r * 0.55, r), 5)
	assert_eq(WeaponRules.bullseye_score(r * 0.99, r), 1)
	assert_eq(WeaponRules.bullseye_score(r * 1.01, r), 0, "a miss")
	var last := 11
	for i in 20:
		var s := WeaponRules.bullseye_score(r * i / 20.0, r)
		assert_lte(s, last)
		last = s


func test_segment_hits_a_disc_facing_it() -> void:
	var c := Vector3(0, 1, -5)
	var n := Vector3(0, 0, 1)
	var hit := WeaponRules.segment_hits_disc(Vector3(0.2, 1, -4), Vector3(0.2, 1, -6), c, n, 0.6)
	assert_almost_eq(hit, Vector3(0.2, 1, -5), Vector3.ONE * 0.001)
	assert_false(WeaponRules.segment_hits_disc(Vector3(1, 1, -4), Vector3(1, 1, -6), c, n, 0.6).is_finite(), "outside the rings")
	assert_false(WeaponRules.segment_hits_disc(Vector3(0, 1, -3), Vector3(0, 1, -4), c, n, 0.6).is_finite(), "not there yet")


func test_segment_hits_a_body() -> void:
	assert_gte(WeaponRules.segment_hits_sphere(Vector3(-2, 1, 0), Vector3(2, 1, 0), Vector3(0, 1.2, 0), 0.5), 0.0)
	assert_lt(WeaponRules.segment_hits_sphere(Vector3(-2, 1, 0), Vector3(2, 1, 0), Vector3(0, 3, 0), 0.5), 0.0)


func test_targets_stand_on_solid_ground_with_room_above() -> void:
	var ground := func(c: Vector3i) -> int: return BlockIds.GRASS if c.y < 10 else BlockIds.AIR
	assert_true(WeaponRules.target_spot_ok(Vector3i(0, 10, 0), ground))
	assert_false(WeaponRules.target_spot_ok(Vector3i(0, 12, 0), ground), "floating")
	assert_false(WeaponRules.target_spot_ok(Vector3i(0, 9, 0), ground), "inside the ground")
	var low_roof := func(c: Vector3i) -> int: return BlockIds.GRASS if c.y < 10 or c.y == 11 else BlockIds.AIR
	assert_false(WeaponRules.target_spot_ok(Vector3i(0, 10, 0), low_roof), "no room for a 2-block target")
	var water := func(c: Vector3i) -> int: return BlockIds.GRASS if c.y < 10 else BlockIds.WATER
	assert_false(WeaponRules.target_spot_ok(Vector3i(0, 10, 0), water), "not in water")


## Found by the weapons smoke run: the boomerang flew level whatever the aim, so a dummy one block
## below the thrower was flown over (0.83 above its centre). It follows the aim up or down now,
## never steeper than BOOMERANG_MAX_PITCH (a throw straight down still flies out, not into the feet).
func test_boomerang_follows_the_aim_up_or_down() -> void:
	var down := WeaponRules.boomerang_start(Vector3(0, 2, 0), Vector3(0, -0.4, -1))
	assert_lt((down.dir as Vector3).y, -0.3, "aimed down: it flies down")
	var s := down
	for i in 10:
		s = WeaponRules.boomerang_step(s, Vector3(0, 2, 0), DT, no_blocks)
	assert_lt((s.pos as Vector3).y, 2.0, "and goes lower on the way out")
	var steep := WeaponRules.boomerang_start(Vector3.ZERO, Vector3(0, -1, 0))
	assert_almost_eq((steep.dir as Vector3).length(), 1.0, 0.001)
	assert_lte(absf((steep.dir as Vector3).y), WeaponRules.BOOMERANG_MAX_PITCH + 0.001, "never steeper than the limit")
	assert_gt(Vector2((steep.dir as Vector3).x, (steep.dir as Vector3).z).length(), 0.5, "still flies out")
	var level := WeaponRules.boomerang_start(Vector3.ZERO, Vector3(1, 0, 0))
	assert_eq(level.dir, Vector3(1, 0, 0), "a level throw stays level")
