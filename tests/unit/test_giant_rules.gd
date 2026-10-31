extends GutTest
## M3 Task 3 (spec §14.1): the Frost Giant, Frostpeak's boss, as pure rules. A fixed order children can
## learn, every attack signalled: a freezing STOMP (a leg lifted high, frost gathering: a ring along the
## ground hurts whoever stands in it, a jump clears it, and the ground there turns icy for a few seconds),
## an icy BREATH (it breathes in, its mouth glowing: a cone of cold; hide behind a snow wall: a block in
## the way stops it), then it pants (double damage), and a giant SNOWBALL (held up, thrown in an arc).
## Health by team size like the Golem's; the honest help, gold and portal are the BossDirector's.

const P := FrostGiantRules.Phase


func _open(_c: Vector3i) -> bool:
	return false


func test_health_grows_with_the_team_and_a_tired_giant_has_less() -> void:
	assert_eq(FrostGiantRules.max_hp(1), FrostGiantRules.BASE_HP)
	assert_gt(FrostGiantRules.BASE_HP, SerpentRules.BASE_HP, "the third universe's boss is the biggest yet")
	assert_eq(FrostGiantRules.max_hp(3), roundi(FrostGiantRules.BASE_HP * 2.0), "two more friends: +50 % each")
	assert_eq(FrostGiantRules.max_hp(1, true), roundi(FrostGiantRules.BASE_HP * BossRules.TIRED_SHARE))
	assert_eq(BossRules.max_hp_of(BossRules.FROST_GIANT, 2), FrostGiantRules.max_hp(2))


func test_a_fixed_order_with_a_walk_between_and_every_attack_signalled() -> void:
	var seen: Array[int] = []
	var phase := P.RISE
	var step := 0
	for i in 16:
		var next := FrostGiantRules.next_phase(phase, step)
		if phase == P.WALK:
			step += 1
		phase = next
		seen.append(phase)
	assert_eq(seen.slice(0, 10), [P.WALK, P.STOMP_WARN, P.WALK, P.BREATH_WARN, P.BREATH, P.PANTING, P.WALK, P.THROW_WARN,
		P.WALK, P.STOMP_WARN] as Array[int], "stomp, breath, snowball, again")
	for w in [P.STOMP_WARN, P.BREATH_WARN, P.THROW_WARN]:
		assert_true(FrostGiantRules.is_warning(w))
		assert_between(FrostGiantRules.phase_time(w), 1.0, 1.6, "a signal long enough to see")
	assert_gt(FrostGiantRules.phase_time(P.WALK), 1.5, "a breather between attacks")


func test_it_takes_hits_once_it_stands_and_double_while_it_pants() -> void:
	assert_false(FrostGiantRules.hittable(P.RISE))
	assert_false(FrostGiantRules.hittable(P.DOWN))
	for p in [P.WALK, P.STOMP_WARN, P.BREATH_WARN, P.BREATH, P.PANTING, P.THROW_WARN]:
		assert_true(FrostGiantRules.hittable(p))
	assert_eq(FrostGiantRules.hit_taken(5, true), 10)
	assert_eq(FrostGiantRules.hit_taken(5, false), 5)
	assert_eq(FrostGiantRules.hit_taken(-3, true), 0)


## The stomp: everyone standing on the ground in the ring; a jump clears it (the Golem's slam's rule).
func test_the_stomp_hits_the_ground_and_a_jump_clears_it() -> void:
	var targets := [{"pos": Vector3(4, 10, 0), "grounded": true}, {"pos": Vector3(4, 11.5, 0), "grounded": false},
		{"pos": Vector3(FrostGiantRules.STOMP_RADIUS + 1.0, 10, 0), "grounded": true}]
	assert_eq(FrostGiantRules.stomp_hits(Vector3(0, 10, 0), targets), [0] as Array[int])
	assert_gt(FrostGiantRules.ICY_RADIUS, FrostGiantRules.STOMP_RADIUS, "the ice spreads a little past the ring")
	assert_between(FrostGiantRules.ICY_TIME, 2.0, 6.0, "icy for a few seconds")


## The breath: a cone in front of its mouth; a child to the side, too far, or behind a wall is safe.
func test_the_breath_is_a_cone_and_a_wall_shields() -> void:
	var mouth := Vector3(0.5, 14, 0.5)
	var dir := Vector3(0, 0, -1)
	assert_true(FrostGiantRules.in_breath(mouth, dir, Vector3(0.5, 11, -6.5), _open), "in front")
	assert_true(FrostGiantRules.in_breath(mouth, dir, Vector3(2.5, 11, -6.5), _open), "a little to the side")
	assert_false(FrostGiantRules.in_breath(mouth, dir, Vector3(6.5, 11, -2.5), _open), "well to the side")
	assert_false(FrostGiantRules.in_breath(mouth, dir, Vector3(0.5, 11, 5.5), _open), "behind it")
	assert_false(FrostGiantRules.in_breath(mouth, dir, Vector3(0.5, 11, -(FrostGiantRules.BREATH_LENGTH + 2.0)), _open), "too far")
	var wall := func(c: Vector3i) -> bool: return c.z == -4 and c.y <= 12
	assert_false(FrostGiantRules.in_breath(mouth, dir, Vector3(0.5, 11, -6.5), wall), "hidden behind a snow wall")
	assert_eq(FrostGiantRules.damage(FrostGiantRules.BREATH) * FrostGiantRules.BREATH_TICKS, 3, "a whole breath: 3 hearts")
	assert_almost_eq(FrostGiantRules.BREATH_TIME / FrostGiantRules.BREATH_TICKS, FrostGiantRules.BREATH_TICK, 0.001)


func test_its_words() -> void:
	var w := BossRules.words(BossRules.FROST_GIANT)
	assert_eq(w.name, "Frost Giant")
	assert_eq(w.win, "You beat the Frost Giant!")
	assert_string_contains(w.tired, "tired")
	assert_string_contains(String(w.summon) % "Mia", "Mia")
