extends GutTest
## Owner feedback #39 (spec §14.2a): the Dragon Realm's two monsters as pure rules, gentle and fair like every
## monster (§6, §12.4, §14.1's flyer).
## - Shadow bat: a small dark-violet flyer. It hovers over a child's side, flares its wings, brightens its eyes and
##   squeaks (the signal, longer than an ice bat's: it is hard to see in the dark), dives in a straight line at
##   where the child stood (a sidestep dodges it), then flies up and away to rest before it comes back.
## - Wisp spirit: a floating light that never walks. It keeps its distance from a child, brightens, chimes and
##   grows a ring (the signal), then throws a slow spark in a straight line at where the child stood: slower
##   than a walking child, so a child who moves dodges it; a wall stops it; a small hit.
## - Both: levels 1-5, × 2^(u-1) in universe u; they keep to where islands are, and one that ends up below y 0
##   with nothing under it puffs away.

const S := MonsterRules.SHADOW_BAT
const W := MonsterRules.WISP


func _open(_c: Vector3i) -> bool:
	return false


func test_the_dragon_kinds_exist_beside_the_others() -> void:
	for k in [S, W]:
		assert_true(MonsterRules.KINDS.has(k), String(k))
		assert_eq(MonsterRules.behaviour(k), MonsterRules.FLYER, "%s flies: it never walks" % k)
		assert_false(MonsterRules.splits(k, 5))
	assert_eq(MonsterRules.DRAGON_KINDS, [S, W] as Array[StringName])
	assert_eq(String(S), "shadow_bat")
	assert_eq(String(W), "wisp")
	assert_eq(MonsterRules.pick_kind(0.1, MonsterRules.DRAGON_KINDS), S, "shadow bats are 3 in 5 at night")
	assert_eq(MonsterRules.pick_kind(0.9, MonsterRules.DRAGON_KINDS), W)


func test_shadow_bat_stats() -> void:
	var hp := [3, 5, 7, 9, 11]
	var hit := [1, 2, 2, 3, 3]
	var gold := [3, 6, 9, 12, 15]
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(S, l), hp[l - 1], "shadow bat hp %d" % l)
		assert_eq(MonsterRules.hit(S, l), hit[l - 1], "shadow bat nip %d" % l)
		assert_eq(MonsterRules.gold(S, l), gold[l - 1], "shadow bat gold %d" % l)
	assert_lt(MonsterRules.size_of(S, 1).y, 0.5, "small")
	assert_eq(MonsterRules.hp(S, 1, 5), 48, "universe 5 multiplies its health by 16")
	assert_eq(MonsterRules.hit(S, 2, 5), 32)
	assert_eq(MonsterRules.gold(S, 1, 5), 48)


func test_wisp_stats() -> void:
	var hp := [4, 6, 8, 10, 12]
	var hit := [1, 2, 2, 3, 3]
	var gold := [3, 6, 9, 12, 15]
	for l in range(1, 6):
		assert_eq(MonsterRules.hp(W, l), hp[l - 1], "wisp hp %d" % l)
		assert_eq(MonsterRules.hit(W, l), hit[l - 1], "wisp spark %d" % l)
		assert_eq(MonsterRules.gold(W, l), gold[l - 1], "wisp gold %d" % l)
	assert_eq(MonsterRules.hp(W, 1, 5), 64, "universe 5 multiplies its health by 16")
	assert_eq(MonsterRules.hit(W, 1, 2), 2, "and its hits by 2 in universe 2")
	assert_gt(MonsterRules.size_of(W, 5).y, MonsterRules.size_of(W, 1).y, "bigger at higher levels")


## "Gentle": never above the fair budget of the monsters before them (§12.4: a nip, slower than a child, no more
## health than a yeti), whatever the level.
func test_never_above_the_fair_budget() -> void:
	for k in [S, W]:
		for l in range(1, 6):
			assert_lte(MonsterRules.hit(k, l), MonsterRules.hit(MonsterRules.GOBLIN, l), "%s %d hits no harder than a goblin" % [k, l])
			assert_lt(MonsterRules.speed(k, l), Player.WALK_SPEED, "%s %d is slower than a walking child" % [k, l])
			assert_lt(MonsterRules.hp(k, l), MonsterRules.hp(MonsterRules.YETI, l), "%s %d is no tank" % [k, l])
	assert_lt(MonsterRules.speed(W, 5), MonsterRules.speed(S, 1), "a wisp drifts slowly")
	assert_lte(MonsterRules.SPARK_SPEED, Player.WALK_SPEED - 0.5, "a walking child can outrun a spark")


func test_every_dragon_attack_is_signalled_first() -> void:
	assert_true(MonsterRules.winds_up(S))
	assert_true(MonsterRules.winds_up(W))
	assert_gt(MonsterRules.windup(S), MonsterRules.windup(MonsterRules.ICE_BAT), "a longer signal than an ice bat's: it is dark")
	assert_lte(MonsterRules.windup(S), 1.5)
	assert_gte(MonsterRules.windup(W), 1.0, "a wisp brightens, chimes and grows its ring for a second or more")
	assert_gt(MonsterRules.SPARK_COOLDOWN, MonsterRules.windup(W), "time between sparks")


# --- The shadow bat ------------------------------------------------------------------------------------

## After its swoop it flies up and away (on its own side of the child) to rest before it comes back.
func test_a_shadow_bat_rests_up_and_away_on_its_own_side() -> void:
	var child := Vector3(0.5, 10, 0.5)
	var rest := MonsterRules.shadow_rest_spot(child, Vector3(3.5, 11, 0.5))
	assert_almost_eq(Vector2(rest.x - child.x, rest.z - child.z).length(), MonsterRules.SHADOW_AWAY, 0.01, "away from the child")
	assert_gt(rest.x, child.x, "on the side it is on")
	assert_almost_eq(rest.y, child.y + MonsterRules.SHADOW_AWAY_UP, 0.01, "and up")
	assert_gt(MonsterRules.SHADOW_AWAY_UP, MonsterRules.BAT_HOVER, "higher than where it hovers to dive")
	var over := MonsterRules.shadow_rest_spot(child, child + Vector3(0, 2, 0))
	assert_almost_eq(Vector2(over.x - child.x, over.z - child.z).length(), MonsterRules.SHADOW_AWAY, 0.01, "right over the child: any side")
	assert_gt(MonsterRules.SHADOW_REST, 1.5, "a real rest between swoops")


## Its dive is the ice bat's (no lead: a sidestep dodges it), fast enough to read as a swoop.
func test_a_shadow_bats_dive_has_a_dodge_window() -> void:
	var child := Vector3(0.5, 10, 0.5)
	var aim := MonsterRules.dive_aim(child)
	assert_true(MonsterRules.dive_hits(aim, child), "still there: hit")
	assert_false(MonsterRules.dive_hits(aim, child + Vector3(0, 0, 1.6)), "stepped aside: missed")
	assert_gt(MonsterRules.BAT_DIVE_SPEED, MonsterRules.speed(S, 5))


# --- The wisp --------------------------------------------------------------------------------------------

func test_a_wisp_keeps_its_distance_above_and_to_its_own_side() -> void:
	var child := Vector3(0.5, 10, 0.5)
	var spot := MonsterRules.wisp_spot(child, Vector3(-2.5, 14, 0.5))
	assert_almost_eq(Vector2(spot.x - child.x, spot.z - child.z).length(), MonsterRules.WISP_KEEP, 0.01)
	assert_lt(spot.x, child.x, "on its own side")
	assert_almost_eq(spot.y, child.y + MonsterRules.WISP_HOVER, 0.01, "floating above their head")
	assert_gt(MonsterRules.WISP_KEEP, MonsterRules.WISP_TOO_CLOSE)
	assert_gt(MonsterRules.WISP_TOO_CLOSE, MonsterRules.ATTACK_RANGE + 1.0, "never up close like a goblin")
	assert_lt(Vector3(MonsterRules.WISP_KEEP, MonsterRules.WISP_HOVER, 0).length(), MonsterRules.WISP_RANGE, "it throws from where it keeps")
	assert_true(MonsterRules.may_spark(spot, MonsterRules.spark_aim(child)))
	assert_false(MonsterRules.may_spark(child + Vector3(0, 3, MonsterRules.WISP_RANGE + 1.0), MonsterRules.spark_aim(child)), "too far")


## The spark flies in a straight line, slowly, to the chest where the child stood (no lead).
func test_the_spark_is_slow_and_straight() -> void:
	var from := Vector3(7.5, 13, 0.5)
	var child := Vector3(0.5, 10, 0.5)
	var to := MonsterRules.spark_aim(child)
	assert_almost_eq(to, child + Vector3(0, MonsterRules.SPARK_AT, 0), Vector3.ONE * 0.001, "the chest where they stand: no lead")
	var time := MonsterRules.spark_time(from, to)
	assert_almost_eq(time, from.distance_to(to) / MonsterRules.SPARK_SPEED, 0.001)
	assert_almost_eq(MonsterRules.spark_point(from, to, time * 0.5), from.lerp(to, 0.5), Vector3.ONE * 0.01, "a straight line")
	assert_almost_eq(MonsterRules.spark_point(from, to, time * 3.0), to, Vector3.ONE * 0.001, "never past where it was thrown")
	assert_almost_eq(MonsterRules.spark_point(from, to, 0.0), from, Vector3.ONE * 0.001)


## The dodge window: even from close by the spark takes over half a second, and a walking child is out of its
## reach far sooner; one who stands still is hit.
func test_the_spark_has_a_dodge_window() -> void:
	var child := Vector3(0.5, 10, 0.5)
	var to := MonsterRules.spark_aim(child)
	var close := child + Vector3(0, 3.0, MonsterRules.WISP_TOO_CLOSE - 1.5)
	assert_gte(MonsterRules.spark_time(close, to), 0.5, "from close by it still takes time")
	var leave := (MonsterRules.SPARK_REACH + 0.35) / Player.WALK_SPEED
	assert_lt(leave * 2.0, MonsterRules.spark_time(close, to), "a walking child steps out of its way in time")
	assert_true(MonsterRules.spark_hits(to, child), "standing still: hit")
	assert_true(MonsterRules.spark_hits(to + Vector3(0.3, 0.5, 0), child), "anywhere on the body")
	assert_false(MonsterRules.spark_hits(to, child + Vector3(1.5, 0, 0)), "a sidestep dodges it")
	assert_false(MonsterRules.spark_hits(to + Vector3(0, 2.2, 0), child), "over their head")


func test_a_wall_stops_the_spark() -> void:
	var from := Vector3(0.5, 12.5, 7.5)
	var to := MonsterRules.spark_aim(Vector3(0.5, 10, 0.5))
	assert_true(MonsterRules.clear_line(from, to, _open))
	var wall := func(c: Vector3i) -> bool: return c.z == 4 and c.y >= 10 and c.y <= 14
	assert_false(MonsterRules.clear_line(from, to, wall), "a wall between: no spark")


# --- Islands and the void -----------------------------------------------------------------------------------

## A flyer over the void (nothing within BAT_LOOK_DOWN below) keeps its height instead of sinking; one that ends
## up below y 0 over the void puffs away. A bat in a deep cave below y 0 has ground under it: it stays.
func test_the_void_rules() -> void:
	var island := func(c: Vector3i) -> bool: return c.y >= 38 and c.y < 40 and absi(c.x) < 6 and absi(c.z) < 6
	var over_island := Vector3(0.5, 43, 0.5)
	var over_void := Vector3(20.5, 43, 0.5)
	assert_false(MonsterRules.over_void(over_island, MonsterRules.ground_below(over_island, island)))
	assert_true(MonsterRules.over_void(over_void, MonsterRules.ground_below(over_void, island)))
	var low := Vector3(20.5, -2, 0.5)
	assert_true(MonsterRules.lost_in_void(low, MonsterRules.ground_below(low, island)), "below y 0 over nothing: puff")
	assert_false(MonsterRules.lost_in_void(over_void, MonsterRules.ground_below(over_void, island)), "high over the void: it flies back")
	var cave := func(c: Vector3i) -> bool: return c.y < -10
	var in_cave := Vector3(0.5, -6, 0.5)
	assert_false(MonsterRules.lost_in_void(in_cave, MonsterRules.ground_below(in_cave, cave)), "a cave below y 0 has a floor")
	assert_eq(MonsterRules.VOID_Y, 0.0)
