extends GutTest
## M5 Task 2 (spec §15.2): the moves monsters and bosses share (CreatureMoves), as plain numbers: a jumper's
## crouch before it pounces, the lean back when a hit lands, a boss's breath while it stands and its cheer when it
## wins a fight. Poses only: nothing here makes a material.


func test_a_crouch_goes_low_and_wide_and_keeps_its_bulk() -> void:
	assert_eq(CreatureMoves.crouch(0.0), Vector3.ONE, "no crouch before the wind-up")
	var half := CreatureMoves.crouch(0.5)
	var deep := CreatureMoves.crouch(1.0)
	assert_lt(deep.y, 0.8, "low")
	assert_gt(deep.x, 1.1, "wide")
	assert_eq(deep.x, deep.z)
	assert_between(deep.x * deep.y * deep.z, 0.9, 1.15, "squashed, not shrunk")
	assert_between(half.y, deep.y, 1.0, "lower as the wind-up goes on")
	assert_eq(CreatureMoves.crouch(3.0), deep, "held at the bottom")


func test_a_recoil_leans_back_at_once_and_eases_home() -> void:
	assert_almost_eq(CreatureMoves.recoil(0.0, 0.3), 0.0, 0.0001, "done: standing straight")
	var peak := 0.0
	for i in 21:
		peak = maxf(peak, CreatureMoves.recoil(i / 20.0, 0.3))
	assert_almost_eq(peak, 0.3, 0.02, "leans back as far as it is told")
	assert_gt(CreatureMoves.recoil(1.0, 0.3), 0.15, "at once when the hit lands")
	assert_gt(CreatureMoves.recoil(0.9, 0.3), 0.0, "back is +x (models face -Z)")
	assert_lt(CreatureMoves.recoil(0.1, 0.3), CreatureMoves.recoil(0.6, 0.3), "then eases home")


func test_a_breath_is_small_slow_and_repeats() -> void:
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for i in 60:
		var b := CreatureMoves.breath(CreatureMoves.BREATH_PERIOD * i / 60.0)
		lo = lo.min(b)
		hi = hi.max(b)
	assert_gt(hi.x - lo.x, 0.02, "the chest rises and falls")
	assert_lt(hi.x - lo.x, 0.12, "a little")
	assert_gt(hi.y - lo.y, 0.05, "the arms sway")
	assert_lt(maxf(absf(lo.y), absf(hi.y)), 0.2, "a little")
	assert_between(CreatureMoves.BREATH_PERIOD, 2.0, 4.0, "slow")
	var t := 0.37
	assert_almost_eq(CreatureMoves.breath(t), CreatureMoves.breath(t + CreatureMoves.BREATH_PERIOD), Vector3.ONE * 0.0001)


func test_a_cheer_pumps_the_arms_up_hops_and_ends_at_rest() -> void:
	var arms_top := 0.0
	var hop_top := 0.0
	var pumps := 0
	var rising := false
	var last := 0.0
	for i in 200:
		var c := CreatureMoves.cheer(CreatureMoves.WIN_TIME * i / 200.0)
		arms_top = maxf(arms_top, c.y)
		hop_top = maxf(hop_top, c.x)
		if c.y < last and rising:
			pumps += 1
		rising = c.y > last
		last = c.y
	assert_gt(arms_top, 2.2, "arms up over the head")
	assert_gt(hop_top, 0.1, "a hop")
	assert_gte(pumps, 2, "the arms pump, not just go up")
	assert_true(CreatureMoves.cheering(0.5))
	assert_false(CreatureMoves.cheering(CreatureMoves.WIN_TIME))
	assert_almost_eq(CreatureMoves.cheer(CreatureMoves.WIN_TIME), Vector3.ZERO, Vector3.ONE * 0.02, "back to rest")
	assert_almost_eq(CreatureMoves.cheer(0.0), Vector3.ZERO, Vector3.ONE * 0.02, "from rest")
	assert_between(CreatureMoves.WIN_TIME, 1.5, 2.5)


func test_the_pounce_is_short_and_fair() -> void:
	assert_between(CreatureMoves.POUNCE_WINDUP, 0.25, 0.5, "long enough to see, short enough to stay a slime")
	assert_between(CreatureMoves.POUNCE_RANGE, 2.0, 4.0)
