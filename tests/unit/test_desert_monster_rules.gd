extends GutTest
## M3 Task 2 (spec §14.1, §5.2, §14.1 "new behaviours"): the Sandstorm Desert's monsters as pure rules.
## - Mummy: a slow tank (more health, a heavy slow grab it signals with raised arms, hard to push); at
##   level 3 and up it unwraps into two halves when defeated (a crawling top and a pair of walking legs).
## - Scorpion: a spitter. It keeps its distance, raises its glowing tail (the signal) and spits a poison
##   glob that leads its shot (where the child will be), a little at most, so a change of direction
##   dodges it; it hits only where it lands.

const M := MonsterRules.MUMMY
const SC := MonsterRules.SCORPION


func test_the_desert_kinds_exist_beside_the_meadows_ones() -> void:
	for k in [M, SC]:
		assert_true(MonsterRules.KINDS.has(k), String(k))
	assert_eq(MonsterRules.behaviour(M), MonsterRules.TANK)
	assert_eq(MonsterRules.behaviour(SC), MonsterRules.SPITTER)
	assert_eq(MonsterRules.DESERT_KINDS, [M, SC] as Array[StringName])
	assert_eq(MonsterRules.MEADOWS_KINDS, [MonsterRules.SLIME, MonsterRules.GOBLIN] as Array[StringName])


func test_mummy_stats_a_tank() -> void:
	var hp := [10, 15, 20, 25, 30]     # 10 + 5(l-1): more than a goblin at every level
	var hit := [2, 3, 4, 5, 6]
	var gold := [4, 8, 12, 16, 20]     # 4l
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(M, l), hp[l - 1], "mummy hp %d" % l)
		assert_eq(MonsterRules.hit(M, l), hit[l - 1], "mummy hit %d" % l)
		assert_eq(MonsterRules.gold(M, l), gold[l - 1], "mummy gold %d" % l)
		assert_gt(MonsterRules.hp(M, l), MonsterRules.hp(MonsterRules.GOBLIN, l))
		assert_lt(MonsterRules.speed(M, l), MonsterRules.speed(MonsterRules.GOBLIN, l), "slower than a goblin")
		assert_lt(MonsterRules.speed(SC, l), 6.0, "slower than a walking child")
	assert_eq(MonsterRules.hp(M, 3, 2), 40, "universe 2 doubles its health")


func test_scorpion_stats() -> void:
	var hp := [5, 8, 11, 14, 17]
	var hit := [1, 2, 2, 3, 3]
	var gold := [3, 6, 9, 12, 15]
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(SC, l), hp[l - 1])
		assert_eq(MonsterRules.hit(SC, l), hit[l - 1])
		assert_eq(MonsterRules.gold(SC, l), gold[l - 1])


func test_the_meadows_monsters_are_unchanged() -> void:
	assert_eq(MonsterRules.hp(MonsterRules.SLIME, 3), 10)
	assert_eq(MonsterRules.hp(MonsterRules.GOBLIN, 3), 14)
	assert_eq(MonsterRules.windup(MonsterRules.GOBLIN), MonsterRules.GOBLIN_WINDUP)
	assert_eq(MonsterRules.pick_kind(0.0), MonsterRules.SLIME)
	assert_eq(MonsterRules.pick_kind(0.99), MonsterRules.GOBLIN)


func test_night_spawns_pick_among_the_universes_kinds() -> void:
	assert_eq(MonsterRules.pick_kind(0.1, MonsterRules.DESERT_KINDS), M, "three in five are mummies")
	assert_eq(MonsterRules.pick_kind(0.9, MonsterRules.DESERT_KINDS), SC)
	var none: Array[StringName] = []
	assert_eq(MonsterRules.pick_kind(0.1, none), MonsterRules.SLIME, "no kinds: Green Meadows'")


func test_every_attack_is_signalled_first() -> void:
	assert_gt(MonsterRules.windup(M), MonsterRules.GOBLIN_WINDUP, "the slow grab: longer than a goblin's club")
	assert_between(MonsterRules.windup(SC), 0.7, 1.2, "the tail goes up for most of a second")
	assert_true(MonsterRules.winds_up(M))
	assert_true(MonsterRules.winds_up(SC))
	assert_true(MonsterRules.winds_up(MonsterRules.GOBLIN))
	assert_false(MonsterRules.winds_up(MonsterRules.SLIME), "a slime bumps")


func test_a_mummy_is_hard_to_push() -> void:
	assert_lt(MonsterRules.push_scale(M), 0.6)
	assert_eq(MonsterRules.push_scale(MonsterRules.GOBLIN), 1.0)


## §14.1: "unwraps into two halves at level ≥ 3": a crawling top and walking legs, level 1, each with half
## a level-1 mummy's health, faster (lighter), never unwrapping again. Slimes still split.
func test_a_big_mummy_unwraps_into_two_halves() -> void:
	for l in range(1, 6):
		assert_eq(MonsterRules.splits(M, l), l >= 3, "mummy level %d" % l)
		assert_false(MonsterRules.splits(SC, l), "scorpions never split")
		assert_eq(MonsterRules.splits(MonsterRules.SLIME, l), l >= 3)
	assert_eq(MonsterRules.halves(M), [MonsterRules.HALF_TOP, MonsterRules.HALF_LEGS])
	assert_eq(MonsterRules.halves(MonsterRules.SLIME), [MonsterRules.WHOLE, MonsterRules.WHOLE], "two small slimes")
	for half in [MonsterRules.HALF_TOP, MonsterRules.HALF_LEGS]:
		assert_eq(MonsterRules.hp(M, 1, 1, half), 5, "half a level-1 mummy")
		assert_gt(MonsterRules.speed(M, 1, half), MonsterRules.speed(M, 1), "lighter: faster")
		assert_lt(MonsterRules.size_of(M, 1, half).y, MonsterRules.size_of(M, 1).y * 0.7)
		assert_false(MonsterRules.splits(M, 1, half), "a half never unwraps again")
	assert_eq(MonsterRules.gold(M, 1, 1, MonsterRules.HALF_TOP), 2, "half the coins")


# --- The scorpion's spit ---------------------------------------------------------------------------

func test_it_spits_from_a_distance_and_backs_off_when_the_child_is_close() -> void:
	assert_true(MonsterRules.may_spit(Vector3.ZERO, Vector3(0, 0, -6)))
	assert_false(MonsterRules.may_spit(Vector3.ZERO, Vector3(0, 0, -(MonsterRules.SPIT_RANGE + 1.0))), "too far")
	assert_false(MonsterRules.may_spit(Vector3.ZERO, Vector3(0, 6, -3)), "too far up")
	assert_gt(MonsterRules.SPIT_KEEP, 3.0, "it stays a few blocks away")
	assert_lt(MonsterRules.SPIT_KEEP, MonsterRules.SPIT_RANGE)


func test_the_spit_leads_a_moving_child_but_only_a_little() -> void:
	var from := Vector3(0, 1, 0)
	var child := Vector3(0, 0, -8)
	var still := MonsterRules.spit_aim(from, child, Vector3.ZERO)
	assert_almost_eq(still, child, Vector3.ONE * 0.01, "a still child: at their feet")
	var running := MonsterRules.spit_aim(from, child, Vector3(3, 0, 0))
	assert_gt(running.x, child.x + 1.0, "it aims where a runner will be")
	var t := MonsterRules.spit_time(from, running)
	assert_almost_eq(running.x, child.x + 3.0 * t, 0.2, "velocity × flight time")
	var fast := MonsterRules.spit_aim(from, child, Vector3(40, 0, 0))
	assert_lte(Vector2(fast.x - child.x, fast.z - child.z).length(), MonsterRules.MAX_LEAD + 0.001, "never far ahead")
	var jumping := MonsterRules.spit_aim(from, child, Vector3(0, 9, 0))
	assert_eq(jumping.y, child.y, "the ground they stand over, not the air")


func test_the_glob_is_slow_enough_to_dodge_and_hits_only_where_it_lands() -> void:
	var from := Vector3(0, 1, 0)
	var to := Vector3(0, 0, -8)
	assert_gt(MonsterRules.spit_time(from, to), 0.6, "a child sees it coming")
	var mid := MonsterRules.spit_point(from, to, 0.5)
	assert_gt(mid.y, (from.y + to.y) * 0.5, "it arcs")
	assert_eq(MonsterRules.spit_point(from, to, 1.0), to)
	assert_true(MonsterRules.spit_hits(to, to + Vector3(0.6, 0, 0)))
	assert_false(MonsterRules.spit_hits(to, to + Vector3(2.0, 0, 0)), "a sidestep dodges it")
	assert_false(MonsterRules.spit_hits(to, to + Vector3(0, 3.0, 0)), "above it, on a ledge")
