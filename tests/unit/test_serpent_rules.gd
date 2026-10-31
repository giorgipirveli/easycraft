extends GutTest
## M3 Task 2 (spec §14.1, §5.3 "clearly signalled attacks, health scales with team size", research G3
## "honest help"): the Sand Serpent, the Sandstorm Desert's boss, as pure rules. It dives through the sand
## (nobody can hit it then) towards a child, marks the spot where it will burst out (a shaking ring of
## sand, long enough to step away), bursts up, and while it is up it can be hit: then its tail sweeps round
## (jump over it) or it spits a ball of sand (step aside), in a fixed order children can learn. After a
## sweep it is dizzy (double damage). Its health grows with the team like the Golem's; the help after
## lost fights is the Golem's too.

const P := SerpentRules.Phase


func test_health_grows_with_the_team_and_a_tired_serpent_has_less() -> void:
	assert_eq(SerpentRules.max_hp(1), SerpentRules.BASE_HP)
	assert_eq(SerpentRules.max_hp(2), roundi(SerpentRules.BASE_HP * 1.5))
	assert_eq(SerpentRules.max_hp(4), roundi(SerpentRules.BASE_HP * 2.5))
	assert_eq(SerpentRules.max_hp(0), SerpentRules.BASE_HP, "nobody counts as one")
	assert_eq(SerpentRules.max_hp(1, true), roundi(SerpentRules.BASE_HP * BossRules.TIRED_SHARE))
	assert_gt(SerpentRules.BASE_HP, BossRules.BASE_HP, "a bigger boss than the first universe's")


func test_the_schedule_dive_warn_burst_up_then_sweep_or_spit_in_turn() -> void:
	assert_eq(SerpentRules.next_phase(P.RISE, 0), P.UP)
	assert_eq(SerpentRules.next_phase(P.DIVE, 0), P.WARN)
	assert_eq(SerpentRules.next_phase(P.WARN, 0), P.BURST)
	assert_eq(SerpentRules.next_phase(P.BURST, 0), P.UP)
	assert_eq(SerpentRules.next_phase(P.UP, 0), P.SWEEP_WARN, "the first time up: the tail")
	assert_eq(SerpentRules.next_phase(P.UP, 1), P.SPIT_WARN, "the next: the sand ball")
	assert_eq(SerpentRules.next_phase(P.UP, 2), P.SWEEP_WARN, "and so on, always the same")
	assert_eq(SerpentRules.next_phase(P.SWEEP_WARN, 0), P.DIZZY, "the sweep lands as its wind-up ends")
	assert_eq(SerpentRules.next_phase(P.DIZZY, 0), P.DIVE)
	assert_eq(SerpentRules.next_phase(P.SPIT_WARN, 0), P.DIVE, "the ball flies as its wind-up ends")
	assert_eq(SerpentRules.next_phase(P.DOWN, 0), P.DOWN)


func test_every_attack_is_signalled_long_enough() -> void:
	assert_gte(SerpentRules.phase_time(P.WARN), 1.2, "the sand shakes where it will burst")
	assert_gte(SerpentRules.phase_time(P.SWEEP_WARN), 1.0)
	assert_gte(SerpentRules.phase_time(P.SPIT_WARN), 0.9)
	for p in [P.WARN, P.SWEEP_WARN, P.SPIT_WARN]:
		assert_true(SerpentRules.is_warning(p))
	assert_false(SerpentRules.is_warning(P.UP))


func test_it_can_be_hit_only_when_it_is_up() -> void:
	for p in [P.UP, P.BURST, P.SWEEP_WARN, P.SPIT_WARN, P.DIZZY]:
		assert_true(SerpentRules.hittable(p), "phase %d" % p)
	for p in [P.RISE, P.DIVE, P.WARN, P.DOWN]:
		assert_false(SerpentRules.hittable(p), "under the sand (or rising): phase %d" % p)
	assert_eq(SerpentRules.hit_taken(5, true), 10, "dizzy: double")
	assert_eq(SerpentRules.hit_taken(5, false), 5)
	assert_eq(SerpentRules.hit_taken(-3, true), 0)


func test_under_the_sand_it_moves_towards_its_target_slower_than_a_child() -> void:
	assert_lt(SerpentRules.DIVE_SPEED, 6.0)
	var next := SerpentRules.dive_step(Vector3(0, 30, 0), Vector3(10, 30, 0), 0.5)
	assert_almost_eq(next, Vector3(SerpentRules.DIVE_SPEED * 0.5, 30, 0), Vector3.ONE * 0.001)
	assert_eq(SerpentRules.dive_step(Vector3(0, 30, 0), Vector3(0.1, 30, 0), 1.0), Vector3(0.1, 30, 0), "never past it")
	var home := Vector3(100, 30, 100)
	var far := SerpentRules.keep_in_arena(Vector3(200, 30, 100), home)
	assert_almost_eq(Vector2(far.x - home.x, far.z - home.z).length(), SerpentRules.ROAM, 0.01, "it stays near its lair")


## The burst marks where the child stood when the sand began to shake: a child who walks away is safe.
func test_the_burst_hits_only_near_the_marked_spot() -> void:
	var spot := Vector3(5, 30, 5)
	var targets := [{"pos": spot + Vector3(1, 0, 1), "grounded": true}, {"pos": spot + Vector3(4, 0, 0), "grounded": true},
		{"pos": spot + Vector3(0, 6, 0), "grounded": false}]
	assert_eq(SerpentRules.burst_hits(spot, targets), [0] as Array[int])
	assert_gt(SerpentRules.BURST_RADIUS, 1.5)
	assert_lt(SerpentRules.BURST_RADIUS, 3.5, "two steps take a child out of it")


func test_the_tail_sweep_hits_the_ground_around_it_and_a_jump_clears_it() -> void:
	var center := Vector3(0, 30, 0)
	var targets := [{"pos": Vector3(3, 30, 0), "grounded": true}, {"pos": Vector3(3, 31.2, 0), "grounded": false},
		{"pos": Vector3(SerpentRules.SWEEP_RADIUS + 1.0, 30, 0), "grounded": true}]
	assert_eq(SerpentRules.sweep_hits(center, targets), [0] as Array[int])


func test_damage_is_the_golems_size() -> void:
	assert_eq(SerpentRules.damage(SerpentRules.BURST), 4)
	assert_eq(SerpentRules.damage(SerpentRules.SWEEP), 4)
	assert_eq(SerpentRules.damage(SerpentRules.SPIT), 3)


func test_words_for_children() -> void:
	assert_eq(SerpentRules.TITLE, "SAND SERPENT")
	assert_eq(SerpentRules.WIN_MESSAGE, "You beat the Sand Serpent!")
	assert_string_contains(SerpentRules.TIRED_MESSAGE, "tired")
	var words := BossRules.words(&"serpent")
	assert_eq(words.title, SerpentRules.TITLE)
	assert_eq(words.name, "Sand Serpent")
	assert_eq(BossRules.words(&"golem").name, "Stone Golem")
	assert_eq(BossRules.words(&"").name, "Stone Golem", "the Golem by default")
	assert_eq(WaveRules.refusal_message(&"no_boss", "Sand Serpent"), "Win wave 5 to wake the Sand Serpent!")
	assert_eq(WaveRules.refusal_message(&"no_boss"), "Win wave 5 to wake the Stone Golem!", "unchanged by default")
	assert_eq(WaveRules.boss_word("Sand Serpent"), "The Sand Serpent!")
