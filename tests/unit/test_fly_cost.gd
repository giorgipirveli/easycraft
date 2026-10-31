extends GutTest
## M2 Task 7: flying in Survivor costs 10 gold a minute, charged every 6 s (spec §12.7).

var _gold := 0
var _charges: Array[int] = []


func before_each() -> void:
	_gold = 100
	_charges.clear()


func _pay(amount: int) -> bool:
	if amount > _gold:
		return false
	_gold -= amount
	_charges.append(amount)
	return true


## Flies (or walks) for `seconds` in physics steps of 1/60 s; false once a charge could not be paid.
func _fly(meter: FlyCost, seconds: float, flying: bool = true) -> bool:
	for i in roundi(seconds * 60.0):
		if not meter.tick(1.0 / 60.0, flying, _pay):
			return false
	return true


func test_a_minute_of_flying_costs_ten_gold() -> void:
	var meter := FlyCost.new()
	assert_true(_fly(meter, 59.9))
	assert_eq(100 - _gold, FlyCost.GOLD_PER_MINUTE)
	assert_eq(_charges.size(), 10, "one charge every 6 s")


func test_the_first_six_seconds_are_paid_at_take_off() -> void:
	var meter := FlyCost.new()
	assert_true(_fly(meter, 1.0 / 60.0))
	assert_eq(_charges, [1] as Array[int])
	assert_true(_fly(meter, 5.9))
	assert_eq(_charges, [1] as Array[int], "still paid for")
	assert_true(_fly(meter, 0.2))
	assert_eq(_charges, [1, 1] as Array[int])


func test_walking_costs_nothing_and_short_hops_do_not_fly_free() -> void:
	var meter := FlyCost.new()
	assert_true(_fly(meter, 120.0, false))
	assert_eq(_charges.size(), 0, "walking is free")
	for hop in 12:   # 12 hops of 4.9 s: almost a minute in the air
		assert_true(_fly(meter, 4.9))
		assert_true(_fly(meter, 3.0, false))
	assert_eq(100 - _gold, 10, "landing does not reset the clock")


func test_a_charge_that_cannot_be_paid_says_land() -> void:
	_gold = 2
	var meter := FlyCost.new()
	assert_true(_fly(meter, 11.9), "two charges paid")
	assert_eq(_gold, 0)
	assert_false(_fly(meter, 0.5), "the third can't be paid: land")
	assert_eq(_gold, 0, "never negative")


func test_taking_off_needs_gold_in_survivor_but_sandbox_flies_free() -> void:
	assert_false(FlyCost.can_take_off(false, 0))
	assert_true(FlyCost.can_take_off(false, FlyCost.GOLD_PER_CHARGE))
	assert_true(FlyCost.can_take_off(true, 0), "FREE_FLY")
	assert_ne(FlyCost.REFUSED_MESSAGE, "")
	assert_ne(FlyCost.LANDED_MESSAGE, "")


func test_bad_time_steps_charge_nothing() -> void:
	var meter := FlyCost.new()
	assert_true(meter.tick(-5.0, true, _pay))
	assert_true(meter.tick(NAN, true, _pay))
	assert_eq(_charges.size(), 1, "only the take-off charge")
