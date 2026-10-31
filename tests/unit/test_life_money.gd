extends GutTest
## Owner #112, #115 (docs/design/life-skills.md §5 #3; docs/design/success-skills.md §2.1): My Money Stall's sums, the
## first step of My Business. Pretend coins of 1, 2, 5 and 10 (and a 20 note on the Big track); change given coin by
## coin; takings counted; the pretend bank's interest week by week (simple on the Middle track, compound on the Big);
## the values vary with the run's seed (spaced repeats come back a little different) and always add up.


func test_change_can_always_be_given_from_the_tray() -> void:
	assert_true(LifeMoney.can_make(3, [1, 2, 5]))
	assert_true(LifeMoney.can_make(7, [2, 5]))
	assert_false(LifeMoney.can_make(3, [2, 5]))
	assert_false(LifeMoney.can_make(0, [1]))


func test_the_fewest_coins() -> void:
	assert_eq(LifeMoney.fewest(8, [1, 2, 5]), [5, 2, 1])
	assert_eq(LifeMoney.fewest(10, [1, 2, 5, 10]), [10])


func test_simple_interest_adds_the_same_each_week() -> void:
	assert_eq(LifeMoney.simple(10, 10, 3), 13)
	assert_eq(LifeMoney.simple(20, 10, 2), 24)


func test_compound_interest_grows_on_the_interest_too() -> void:
	assert_eq(LifeMoney.compound(100, 10, 1), 110)
	assert_eq(LifeMoney.compound(100, 10, 2), 121)
	assert_eq(LifeMoney.compound(100, 10, 3), 133, "whole coins: 133.1 pays 133")
	assert_gt(LifeMoney.compound(100, 10, 3), LifeMoney.simple(100, 10, 3))


func test_each_tracks_values_add_up_for_many_seeds() -> void:
	for track: String in LifeData.TRACKS:
		for seed in 60:
			var v := LifeMoney.stall_vars(track, seed)
			assert_eq(int(v.change), int(v.paid) - int(v.cost), "%s %d: change" % [track, seed])
			assert_gt(int(v.change), 0)
			assert_true(LifeMoney.can_make(int(v.change), v.coins), "%s %d: the tray can make it" % [track, seed])
			assert_eq(int(v.takings), int(v.first_paid) + int(v.cost), "%s %d: the cash box" % [track, seed])
			assert_ne(int(v.takings_wrong_a), int(v.takings))
			assert_ne(int(v.takings_wrong_b), int(v.takings))
			assert_ne(int(v.takings_wrong_a), int(v.takings_wrong_b))


func test_the_bank_on_the_middle_and_big_tracks() -> void:
	var m := LifeMoney.stall_vars("middle", 3)
	assert_eq(int(m.bank_after), LifeMoney.simple(int(m.deposit), LifeMoney.RATE, LifeMoney.WEEKS))
	var b := LifeMoney.stall_vars("big", 3)
	assert_eq(int(b.bank_after), LifeMoney.compound(int(b.deposit), LifeMoney.RATE, LifeMoney.WEEKS))
	assert_eq(int(b.bank_simple), LifeMoney.simple(int(b.deposit), LifeMoney.RATE, LifeMoney.WEEKS))
	assert_ne(int(b.bank_after), int(b.bank_simple))


func test_the_seed_varies_the_customer() -> void:
	var seen := {}
	for seed in 30:
		var v := LifeMoney.stall_vars("middle", seed)
		seen["%d/%d" % [int(v.cost), int(v.paid)]] = true
	assert_gt(seen.size(), 2, "spaced repeats come back a little different")


func test_the_big_tracks_profit() -> void:
	for seed in 20:
		var v := LifeMoney.stall_vars("big", seed)
		assert_eq(int(v.profit), int(v.sales) - int(v.costs))
		assert_gt(int(v.profit), 0)
