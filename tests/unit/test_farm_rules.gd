extends GutTest
## M3 Task 10: the Gold Farm's pure rules (spec §5.6, §14.8, §6): Survivor only, rate_per_hour ×
## 2^(u−1) for the time away, only when the player was inside the farm when they left, capped at 12 h
## (upgrades raise the rate and the cap: 3 levels each at fixed prices), a clock that goes backwards
## pays nothing and never takes gold, and nothing is random.

const HOUR := 3600
const NOW := 1_800_000_000   # unix seconds (2027)


func _farm(rate := 0, cap := 0) -> Dictionary:
	return FarmRules.new_farm(Vector3i(10, 30, -4), 0, rate, cap)


func _left(farm: Dictionary, at: int) -> Dictionary:
	return FarmRules.left_inside(farm, at, false)


func test_only_survivor_worlds_have_a_farm() -> void:
	assert_true(FarmRules.wants_farm(ModeRules.SURVIVOR))
	assert_false(FarmRules.wants_farm(ModeRules.SANDBOX))


func test_a_new_farm_makes_20_gold_an_hour_and_holds_12_hours() -> void:
	assert_eq(FarmRules.rate_per_hour(0), 20)
	assert_eq(FarmRules.cap_hours(0), 12)
	assert_eq(FarmRules.earned(0, 0, 1, HOUR), 20)
	assert_eq(FarmRules.earned(0, 0, 1, 12 * HOUR), 240, "a whole night: the brief's 240 gold")
	assert_eq(FarmRules.earned(0, 0, 1, 30 * 60), 10, "half an hour")
	assert_eq(FarmRules.earned(0, 0, 1, 179), 0, "rounded down: never more than made")


func test_gold_scales_by_the_universe() -> void:
	for u in [1, 2, 3, 4]:
		assert_eq(FarmRules.earned(0, 0, u, HOUR), 20 * (1 << (u - 1)), "universe %d" % u)
		assert_eq(FarmRules.rate_per_hour(0, u), 20 * (1 << (u - 1)))
	assert_eq(FarmRules.price(1), FarmRules.PRICE)
	assert_eq(FarmRules.price(3), FarmRules.PRICE * 4, "Tilly's prices scale too")


func test_the_time_away_is_capped_at_12_hours() -> void:
	assert_eq(FarmRules.earned(0, 0, 1, 12 * HOUR), FarmRules.earned(0, 0, 1, 40 * HOUR))
	assert_eq(FarmRules.earned(0, 0, 1, 365 * 24 * HOUR), 240, "a year away: still one full barn")
	var w := FarmRules.welcome(_left(_farm(), NOW - 20 * HOUR), NOW, 1)
	assert_eq(w.gold, 240)
	assert_true(w.capped)
	assert_eq(w.away, 20 * HOUR)


func test_upgrades_raise_the_rate_and_the_cap_three_levels_each() -> void:
	assert_eq(FarmRules.RATES, [20, 30, 40, 50] as Array[int])
	assert_eq(FarmRules.CAP_HOURS, [12, 16, 20, 24] as Array[int])
	var f := _farm()
	for i in 3:
		assert_true(FarmRules.can_upgrade(f, FarmRules.RATE))
		f = FarmRules.upgraded(f, FarmRules.RATE)
	assert_false(FarmRules.can_upgrade(f, FarmRules.RATE), "three levels, then the top")
	assert_eq(FarmRules.upgraded(f, FarmRules.RATE).rate, 3, "never past the top")
	assert_eq(FarmRules.earned(f.rate, f.cap, 1, HOUR), 50)
	for i in 3:
		f = FarmRules.upgraded(f, FarmRules.CAP)
	assert_eq(f.cap, 3)
	assert_eq(FarmRules.cap_hours(f.cap), 24, "the server's cap too (MAX_CAP_HOURS)")
	assert_eq(FarmRules.earned(f.rate, f.cap, 1, 30 * HOUR), 50 * 24)


func test_upgrade_prices_are_fixed_and_scale_by_the_universe() -> void:
	var f := _farm()
	assert_eq(FarmRules.upgrade_price(f, FarmRules.RATE, 1), 200)
	assert_eq(FarmRules.upgrade_price(f, FarmRules.CAP, 1), 150)
	assert_eq(FarmRules.upgrade_price(f, FarmRules.RATE, 2), 400)
	f = FarmRules.upgraded(FarmRules.upgraded(f, FarmRules.RATE), FarmRules.RATE)
	assert_eq(FarmRules.upgrade_price(f, FarmRules.RATE, 1), 800)
	f = FarmRules.upgraded(f, FarmRules.RATE)
	assert_eq(FarmRules.upgrade_price(f, FarmRules.RATE, 1), 0, "nothing left to buy")
	assert_eq(FarmRules.upgrade_price(f, &"magic", 1), 0)


func test_workers_come_with_the_rate_upgrades() -> void:
	assert_eq(FarmRules.workers(0), 1)
	assert_eq(FarmRules.workers(1), 2)
	assert_eq(FarmRules.workers(2), 3)
	assert_eq(FarmRules.workers(3), 3, "at most three")


func test_only_time_away_inside_the_farm_pays() -> void:
	var f := _farm()
	assert_eq(FarmRules.welcome(f, NOW, 1).gold, 0, "never left inside: nothing")
	var inside := _left(f, NOW - 3 * HOUR)
	assert_eq(FarmRules.welcome(inside, NOW, 1).gold, 60)
	var outside := FarmRules.left_outside(inside)
	assert_false(outside.has("away"))
	assert_eq(FarmRules.welcome(outside, NOW, 1).gold, 0, "walked out before leaving: nothing")
	assert_eq(FarmRules.welcome({}, NOW, 1).gold, 0, "no farm")


func test_a_clock_that_goes_backwards_pays_nothing_and_takes_nothing() -> void:
	var f := _left(_farm(), NOW)
	var w := FarmRules.welcome(f, NOW - 5 * HOUR, 1)
	assert_eq(w.gold, 0)
	assert_eq(w.away, 0)
	assert_eq(FarmRules.earned(0, 0, 1, -7 * HOUR), 0, "never negative")
	assert_eq(FarmRules.welcome(f, NOW, 1).gold, 0, "no time away")


func test_leaving_again_keeps_the_levels_and_marks_the_time() -> void:
	var f := FarmRules.upgraded(_farm(), FarmRules.CAP)
	var left := FarmRules.left_inside(f, NOW, true)
	assert_eq(left.cap, 1)
	assert_eq(left.away, {"at": NOW, "server": true})
	assert_false(f.has("away"), "a copy: the farm given is not changed")
	assert_eq(FarmRules.paid(left), f, "after the welcome, the record is gone")


func test_the_farm_saves_and_loads() -> void:
	var f := FarmRules.left_inside(FarmRules.upgraded(_farm(), FarmRules.RATE), NOW, true)
	var back := FarmRules.clean(JSON.parse_string(JSON.stringify(FarmRules.to_save(f))))
	assert_eq(back, f)
	assert_eq(FarmRules.clean(JSON.parse_string(JSON.stringify(FarmRules.to_save({})))), {}, "no farm")


func test_a_broken_save_is_no_farm_or_a_safe_one() -> void:
	for bad: Variant in [null, 3, "farm", [], {"pos": [1, 2]}, {"pos": [1, 2, "x"]}, {"pos": [1, 2, 3], "facing": 7},
			{"pos": [1.5, 2, 3], "facing": 0}, {"pos": [INF, 2, 3], "facing": 0}]:
		assert_eq(FarmRules.clean(bad), {}, str(bad))
	var odd := FarmRules.clean({"pos": [1, 2, 3], "facing": 1, "rate": 99, "cap": -4, "away": {"at": "soon"}})
	assert_eq(odd.rate, FarmRules.MAX_LEVEL, "levels clamped")
	assert_eq(odd.cap, 0)
	assert_false(odd.has("away"), "a broken away record pays nothing")
	var old := FarmRules.clean({"pos": [1, 2, 3], "facing": 2})
	assert_eq(old.rate, 0)
	assert_eq(old.cap, 0)


func test_one_farm_per_world_and_only_the_owner_buys_it() -> void:
	assert_eq(FarmRules.buy_refusal(true, false), "")
	assert_eq(FarmRules.buy_refusal(true, true), "farm_one")
	assert_eq(FarmRules.buy_refusal(false, false), "farm_owner")
	assert_ne(FarmRules.message("farm_one"), "")
	assert_ne(FarmRules.message("farm_owner"), "")


func test_upgrading_needs_the_owner_a_farm_and_the_gold() -> void:
	var f := _farm()
	assert_eq(FarmRules.upgrade_refusal(f, FarmRules.RATE, 200, 1, true), "")
	assert_eq(FarmRules.upgrade_refusal(f, FarmRules.RATE, 199, 1, true), "gold")
	assert_eq(FarmRules.upgrade_refusal(f, FarmRules.RATE, 200, 2, true), "gold", "universe 2 prices")
	assert_eq(FarmRules.upgrade_refusal(f, FarmRules.RATE, 9999, 1, false), "farm_owner")
	assert_eq(FarmRules.upgrade_refusal({}, FarmRules.RATE, 9999, 1, true), "farm_none")
	assert_eq(FarmRules.upgrade_refusal(f, &"magic", 9999, 1, true), "farm_top")
	var top := FarmRules.upgraded(FarmRules.upgraded(FarmRules.upgraded(f, FarmRules.CAP), FarmRules.CAP), FarmRules.CAP)
	assert_eq(FarmRules.upgrade_refusal(top, FarmRules.CAP, 9999, 1, true), "farm_top")


func test_the_welcome_words_say_the_exact_amount() -> void:
	assert_eq(FarmRules.welcome_text(240), "Your farm made 240 gold!")
	assert_eq(FarmRules.welcome_text(1440), "Your farm made 1,440 gold!")


func test_nothing_is_random() -> void:
	var f := _left(_farm(2, 1), NOW - 7 * HOUR)
	var a := FarmRules.welcome(f, NOW, 3)
	for i in 5:
		assert_eq(FarmRules.welcome(f, NOW, 3), a)


## The server's farm_collect (economy.ts, FarmRules.earned) pays floor(rate × 2^(u−1) × min(away, cap) / 1 h):
## the phone's rule must be the same, so an online and an offline return pay alike.
func test_the_phone_pays_like_the_server() -> void:
	var start := FarmRules.server_start(_farm(2, 1), 3)
	assert_eq(start, {"rate_per_hour": 40, "universe": 3, "cap_hours": 16})
	for away in [0, 59, 3599, 3600, 7 * HOUR + 123, 16 * HOUR, 20 * HOUR]:
		var server := floori(40.0 * 4.0 * mini(away, 16 * HOUR) / HOUR)
		assert_eq(FarmRules.earned(2, 1, 3, away), server, "away %d s" % away)


# --- Moving the farm: picked up as the FARM item, its levels kept ---

func test_a_packed_farm_keeps_its_levels_and_stands_nowhere() -> void:
	var f := FarmRules.left_inside(_farm(2, 1), NOW, true)
	var packed := FarmRules.packed(f)
	assert_eq(packed, {"packed": true, "rate": 2, "cap": 1})
	assert_false(FarmRules.standing(packed))
	assert_true(FarmRules.standing(f))
	assert_false(FarmRules.standing({}))
	assert_eq(FarmRules.welcome(packed, NOW + 5 * HOUR, 1).gold, 0, "no away record: nothing owed")
	var again := FarmRules.placed_again(packed, Vector3i(3, 40, 3), 2)
	assert_eq(again, FarmRules.new_farm(Vector3i(3, 40, 3), 2, 2, 1), "placed again with its levels")
	assert_eq(FarmRules.placed_again({}, Vector3i(3, 40, 3), 2), FarmRules.new_farm(Vector3i(3, 40, 3), 2), "a new farm")


func test_a_packed_farm_saves_and_loads() -> void:
	var packed := FarmRules.packed(_farm(3, 2))
	assert_eq(FarmRules.clean(JSON.parse_string(JSON.stringify(FarmRules.to_save(packed)))), packed)
	assert_eq(FarmRules.clean({"packed": true, "rate": 9, "cap": "x"}), {"packed": true, "rate": 3, "cap": 0})
	assert_eq(FarmRules.clean({"packed": "yes"}), {}, "not a real packed farm")
