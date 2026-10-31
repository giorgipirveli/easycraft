extends GutTest
## M3 Task 3 (spec §14.1, §5.2, §14.1 "new behaviours"): Frostpeak's monsters as pure rules.
## - Yeti: a tank (slow, heavy, hard to push: it takes two children or good tools). It lifts a big
##   snowball over its head (the signal) and throws it where the child will be, leading a runner a little
##   like the desert's scorpion; never through a wall, and it only hits where it lands. Up close it smashes
##   the snowball down instead.
## - Ice bat: the flyer. It flutters above the ground, circles over a child it sees, hovers and screeches
##   (the signal), then dives in a straight line at where the child was (a sidestep dodges it), stays low
##   for a moment (a sword reaches it) and climbs back; tired, it hangs under a ceiling or a branch to rest.

const Y := MonsterRules.YETI
const B := MonsterRules.ICE_BAT


func _open(_c: Vector3i) -> bool:
	return false


func test_the_frost_kinds_exist_beside_the_others() -> void:
	for k in [Y, B]:
		assert_true(MonsterRules.KINDS.has(k), String(k))
	assert_eq(MonsterRules.behaviour(Y), MonsterRules.TANK)
	assert_eq(MonsterRules.behaviour(B), MonsterRules.FLYER)
	assert_eq(MonsterRules.FROST_KINDS, [Y, B] as Array[StringName])
	assert_eq(String(B), "bat", "/summon bat")


func test_yeti_stats_a_tank() -> void:
	var hp := [14, 21, 28, 35, 42]     # 14 + 7(l-1): more than a mummy at every level
	var hit := [2, 3, 4, 5, 6]
	var gold := [5, 10, 15, 20, 25]
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(Y, l), hp[l - 1], "yeti hp %d" % l)
		assert_eq(MonsterRules.hit(Y, l), hit[l - 1], "yeti hit %d" % l)
		assert_eq(MonsterRules.gold(Y, l), gold[l - 1], "yeti gold %d" % l)
		assert_gt(MonsterRules.hp(Y, l), MonsterRules.hp(MonsterRules.MUMMY, l), "a bigger tank than a mummy")
		assert_lt(MonsterRules.speed(Y, l), MonsterRules.speed(MonsterRules.MUMMY, l), "slower than a mummy")
	assert_eq(MonsterRules.hp(Y, 3, 3), 112, "universe 3 multiplies its health by 4")
	assert_lt(MonsterRules.push_scale(Y), 0.5, "hard to push")
	assert_false(MonsterRules.splits(Y, 5), "a yeti never splits")


func test_bat_stats_small_and_quick_to_beat() -> void:
	var hp := [3, 5, 7, 9, 11]
	var hit := [1, 2, 2, 3, 3]
	var gold := [3, 6, 9, 12, 15]
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(B, l), hp[l - 1], "bat hp %d" % l)
		assert_eq(MonsterRules.hit(B, l), hit[l - 1], "bat nip %d" % l)
		assert_eq(MonsterRules.gold(B, l), gold[l - 1])
		assert_lt(MonsterRules.speed(B, l), 6.0, "slower than a walking child")
		assert_false(MonsterRules.splits(B, l))
	assert_lt(MonsterRules.size_of(B, 1).y, 0.5, "small")


func test_every_frost_attack_is_signalled_first() -> void:
	assert_gt(MonsterRules.windup(Y), MonsterRules.GOBLIN_WINDUP, "the snowball goes up for longer than a club")
	assert_between(MonsterRules.windup(B), 0.6, 1.2, "the bat hovers and screeches before it dives")
	assert_true(MonsterRules.winds_up(Y))
	assert_true(MonsterRules.winds_up(B))


# --- The yeti's snowball --------------------------------------------------------------------------

func test_it_throws_from_a_distance_and_smashes_up_close() -> void:
	assert_true(MonsterRules.may_throw(Vector3.ZERO, Vector3(0, 0, -9)))
	assert_false(MonsterRules.may_throw(Vector3.ZERO, Vector3(0, 0, -(MonsterRules.THROW_RANGE + 1.0))), "too far")
	assert_false(MonsterRules.may_throw(Vector3.ZERO, Vector3(0, 7, -3)), "too far up")
	assert_false(MonsterRules.may_throw(Vector3.ZERO, Vector3(0, 0, -1.5)), "this close it smashes instead")
	assert_gt(MonsterRules.THROW_RANGE, MonsterRules.SPIT_RANGE, "a big arm")


func test_the_snowball_leads_a_runner_like_the_scorpion() -> void:
	var from := Vector3(0, 2.5, 0)
	var child := Vector3(0, 0, -8)
	assert_almost_eq(MonsterRules.throw_aim(from, child, Vector3.ZERO, _open), child, Vector3.ONE * 0.01, "a still child: at their feet")
	var running := MonsterRules.throw_aim(from, child, Vector3(3, 0, 0), _open)
	assert_eq(running, MonsterRules.spit_aim(from, child, Vector3(3, 0, 0)), "the scorpion's lead")
	assert_gt(running.x, child.x + 1.0)
	assert_lte(running.x - child.x, MonsterRules.MAX_LEAD + 0.001)


## "Never through walls": with a wall between the yeti's hands and the child, it does not throw; with a
## wall only where a runner is going, it throws at the child's feet (no lead into the wall).
func test_the_snowball_never_goes_through_a_wall() -> void:
	var from := Vector3(0.5, 2.5, 0.5)
	var child := Vector3(0.5, 0, -7.5)
	var wall := func(c: Vector3i) -> bool: return c.z == -4 and c.y <= 4
	assert_eq(MonsterRules.throw_aim(from, child, Vector3.ZERO, wall), Vector3.INF, "a wall between: no throw")
	var side := func(c: Vector3i) -> bool: return c.x >= 2 and c.x <= 4 and c.z <= -5
	var aim := MonsterRules.throw_aim(from, child, Vector3(3, 0, 0), side)
	assert_almost_eq(aim, child, Vector3.ONE * 0.01, "no lead into the wall: at the child's feet")
	assert_true(MonsterRules.snowball_hits(child, child + Vector3(0.5, 0, 0), _open))
	var between := func(c: Vector3i) -> bool: return c == Vector3i(1, 0, -8) or c == Vector3i(1, 1, -8)
	assert_false(MonsterRules.snowball_hits(Vector3(0.5, 0, -7.5), Vector3(1.5, 0, -8.5), between), "a snow wall shields")
	assert_false(MonsterRules.snowball_hits(child, child + Vector3(2.0, 0, 0), _open), "a sidestep dodges it")


# --- The ice bat ------------------------------------------------------------------------------------

func test_a_bat_flies_above_the_ground_and_hovers_over_its_target() -> void:
	var ground := func(c: Vector3i) -> bool: return c.y < 10
	assert_eq(MonsterRules.ground_below(Vector3(0.5, 16.2, 0.5), ground), 10.0, "the ground's top under it")
	assert_eq(MonsterRules.ground_below(Vector3(0.5, 40, 0.5), ground), 40.0 - MonsterRules.BAT_LOOK_DOWN, "none near: far below")
	assert_almost_eq(MonsterRules.cruise_y(10.0), 10.0 + MonsterRules.BAT_CRUISE, 0.001)
	var over := MonsterRules.hover_spot(Vector3(0.5, 10, 0.5), Vector3(8.5, 14, 0.5))
	assert_almost_eq(over.y, 10.0 + MonsterRules.BAT_HOVER, 0.001, "above the child")
	assert_almost_eq(Vector2(over.x - 0.5, over.z - 0.5).length(), MonsterRules.BAT_CIRCLE, 0.01, "at the circle's edge, on its side")
	assert_gt(over.x, 0.5)


func test_the_dive_goes_where_the_child_was_and_a_sidestep_dodges_it() -> void:
	var from := Vector3(4.5, 14, 0.5)
	var child := Vector3(0.5, 10, 0.5)
	var aim := MonsterRules.dive_aim(child)
	assert_almost_eq(aim, child + Vector3(0, MonsterRules.BAT_DIVE_AT, 0), Vector3.ONE * 0.001, "the child's chest, no lead")
	var mid := from.lerp(aim, 0.9)
	assert_true(MonsterRules.dive_hits(mid, child), "still there: hit")
	assert_false(MonsterRules.dive_hits(mid, child + Vector3(0, 0, 2.0)), "stepped aside: missed")
	assert_gt(MonsterRules.BAT_DIVE_SPEED, MonsterRules.speed(B, 5), "the dive is fast ...")
	assert_gt(MonsterRules.BAT_LOW_TIME, 0.8, "... then it stays low long enough to be hit")


## "Lands to rest on ceilings/branches": a tired bat looks up for a solid block with room under it and
## hangs there; in the open sky there is nothing to hang from.
func test_a_tired_bat_finds_a_ceiling_or_a_branch() -> void:
	var branch := Vector3i(3, 15, 0)
	var tree := func(c: Vector3i) -> bool: return c == branch or c.y < 10
	var perch := MonsterRules.perch_spot(Vector3(3.5, 12.4, 0.5), tree)
	assert_eq(perch, Vector3(3.5, 15.0 - MonsterRules.size_of(B, 1).y, 0.5), "hangs under the branch")
	assert_eq(MonsterRules.perch_spot(Vector3(20.5, 12.4, 0.5), tree), Vector3.INF, "open sky: nowhere to hang")
	var cave := func(c: Vector3i) -> bool: return c.y >= 14 or c.y < 10
	assert_true(MonsterRules.perch_spot(Vector3(8.5, 11, 0.5), cave).is_finite(), "a cave's ceiling")
	assert_eq(MonsterRules.perch_spot(Vector3(8.5, 11, 0.5), func(c: Vector3i) -> bool: return c.y >= 11 + MonsterRules.BAT_PERCH_UP + 1),
		Vector3.INF, "too high to reach")
