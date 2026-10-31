extends GutTest
## Owner feedback #54 (2026-09-28) and #75 (2026-09-29: "when i click on jump several times i should start fliying and
## going up not only down"), spec §3b: quick taps on JUMP take off flying at once, on the second quick tap where
## flying is free (the Sandbox), on the third where it costs gold (Survivor: two taps stay its double jump). Flying,
## each tap lifts the player higher (the player's part). One tap and slow taps never take off.

const DT := 1.0 / 60.0

var taps: JumpTaps


func before_each() -> void:
	taps = JumpTaps.new()


## Taps with `pattern` seconds between one tap and the next (the first tap at once); `need`: the quick taps that take
## off; `not_counting`: the tap numbers (1 = the first) made where taps do not count. Returns the tap numbers that took
## off.
func _play(pattern: Array, need: int = 2, not_counting: Array = []) -> Array:
	var took_off: Array = []
	var gaps: Array = [0.0]
	gaps.append_array(pattern)
	for k in gaps.size():
		for i in roundi(float(gaps[k]) / DT):
			taps.tick(DT)
		if taps.tap(not not_counting.has(k + 1), need):
			took_off.append(k + 1)
	return took_off


func test_the_numbers_suit_a_childs_thumb() -> void:
	assert_almost_eq(JumpTaps.DOUBLE_TAP_TIME, 0.35, 0.001, "the next tap within 0.35 s belongs to the row")
	assert_between(JumpTaps.TAKE_OFF_LIFT, 0.3, 0.6, "a clear rise when it takes off")
	assert_between(JumpTaps.TAP_LIFT, 0.15, 0.5, "each tap while flying lifts a little more")


func test_the_second_quick_tap_takes_off_at_once() -> void:
	assert_eq(_play([0.15]), [2])


func test_a_third_of_a_second_apart_still_counts() -> void:
	assert_eq(_play([0.33]), [2])


func test_several_quick_taps_take_off_once_at_the_second() -> void:
	assert_eq(_play([0.15, 0.15, 0.15, 0.15, 0.15]), [2], "the taps after it are the flying's lifts")
	taps = JumpTaps.new()
	assert_eq(_play([0.25, 0.25, 0.25, 0.25]), [2], "a steady rhythm too")


func test_one_tap_never_takes_off() -> void:
	assert_eq(_play([]), [])


func test_a_slow_second_tap_never_takes_off() -> void:
	assert_eq(_play([0.45]), [], "a slow second tap is a double jump")


func test_a_slow_tap_then_two_quick_ones_take_off_at_the_third() -> void:
	assert_eq(_play([0.5, 0.15]), [3])


func test_where_flying_costs_gold_the_third_quick_tap_takes_off() -> void:
	assert_eq(_play([0.15], 3), [], "two taps stay the double jump (no gold spent)")
	taps = JumpTaps.new()
	assert_eq(_play([0.15, 0.15], 3), [3], "tap tap tap: flying")
	taps = JumpTaps.new()
	assert_eq(_play([0.15, 0.15, 0.15, 0.15], 3), [3], "once")


func test_a_tap_where_taps_do_not_count_spoils_its_row() -> void:
	assert_eq(_play([0.15, 0.15], 2, [1]), [], "the row began under the glider, swimming or flying")
	taps = JumpTaps.new()
	assert_eq(_play([0.15, 0.6, 0.15], 2, [1]), [4], "a fresh row after a pause takes off")


func test_reset_forgets_the_taps() -> void:
	assert_false(taps.tap())
	taps.reset()
	assert_false(taps.tap(), "after a reset this is the first tap of a new row")
	assert_true(taps.tap(), "and this the second")


func test_the_taps_needed_depend_on_what_flying_costs() -> void:
	assert_eq(JumpTaps.needed(true), 2, "the Sandbox flies free: a double tap")
	assert_eq(JumpTaps.needed(false), 3, "Survivor pays gold: tap tap tap")


func test_taps_count_where_flying_is_allowed_and_the_body_walks() -> void:
	var none := GadgetRules.Move.NONE
	var dry := SwimRules.State.DRY
	assert_true(JumpTaps.counts(true, true, dry, none), "on land or in the air")
	assert_true(JumpTaps.counts(true, true, SwimRules.State.WADING, none), "wading is walking")
	assert_false(JumpTaps.counts(false, true, dry, none), "Monster Wave has no flying: the jumps and the glider")
	assert_false(JumpTaps.counts(true, false, dry, none), "already flying, a ghost or zero-G: JUMP is UP")
	assert_false(JumpTaps.counts(true, true, SwimRules.State.SWIMMING, none), "swimming: JUMP swims up")
	assert_false(JumpTaps.counts(true, true, dry, GadgetRules.Move.GLIDE), "gliding: the taps went to the glider")
	assert_false(JumpTaps.counts(true, true, dry, GadgetRules.Move.ZIP), "on a zipline JUMP lets go")
	assert_false(JumpTaps.counts(true, true, dry, GadgetRules.Move.HOOK))
