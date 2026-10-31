extends GutTest
## Potions (M2 Task 6, spec §12.6): one use, drunk by tapping the hotbar slot. Moon Jump (jumps
## x 1.8, 60 s), Invisibility (30 s), Speed (x 1.5, 60 s).


func test_every_potion_has_an_effect_and_a_duration() -> void:
	assert_eq(PotionRules.seconds(ItemIds.POTION_JUMP), 60.0)
	assert_eq(PotionRules.seconds(ItemIds.POTION_INVIS), 30.0)
	assert_eq(PotionRules.seconds(ItemIds.POTION_SPEED), 60.0)
	for id in ItemIds.POTIONS:
		assert_true(PotionRules.is_potion(id), ItemIds.display_name(id))
		assert_ne(PotionRules.effect_name(id), "", str(id))
	for id in [ItemIds.SWORD, ItemIds.WAND, BlockIds.DIRT, 0]:
		assert_false(PotionRules.is_potion(id), str(id))
		assert_eq(PotionRules.seconds(id), 0.0)


func test_nothing_is_active_at_first() -> void:
	var e := PotionRules.Effects.new()
	assert_eq(e.jump_velocity_factor(), 1.0)
	assert_eq(e.speed_factor(), 1.0)
	assert_false(e.is_invisible())
	assert_eq(e.active_ids(), [])
	assert_eq(e.time_left(ItemIds.POTION_SPEED), 0.0)


func test_moon_jump_jumps_1_8_times_as_high_for_60_seconds() -> void:
	var e := PotionRules.Effects.new()
	assert_true(e.start(ItemIds.POTION_JUMP))
	var v := e.jump_velocity_factor()
	assert_almost_eq(v * v, 1.8, 0.0001, "height grows with the square of the take-off speed")
	e.tick(59.9)
	assert_true(e.is_active(ItemIds.POTION_JUMP))
	assert_almost_eq(e.time_left(ItemIds.POTION_JUMP), 0.1, 0.0001)
	e.tick(0.2)
	assert_false(e.is_active(ItemIds.POTION_JUMP))
	assert_eq(e.jump_velocity_factor(), 1.0, "back to normal")


func test_speed_runs_1_5_times_as_fast_for_60_seconds() -> void:
	var e := PotionRules.Effects.new()
	e.start(ItemIds.POTION_SPEED)
	assert_eq(e.speed_factor(), 1.5)
	e.tick(60.01)
	assert_eq(e.speed_factor(), 1.0)


func test_invisibility_lasts_30_seconds() -> void:
	var e := PotionRules.Effects.new()
	e.start(ItemIds.POTION_INVIS)
	assert_true(e.is_invisible())
	assert_eq(e.visibility(), 0.0, "monsters see nothing (stealth §12.5)")
	e.tick(29.0)
	assert_true(e.is_invisible())
	e.tick(1.5)
	assert_false(e.is_invisible())
	assert_eq(e.visibility(), 1.0)


func test_potions_work_side_by_side_and_one_kind_does_not_stack() -> void:
	var e := PotionRules.Effects.new()
	assert_true(e.start(ItemIds.POTION_SPEED))
	e.tick(10.0)
	assert_true(e.start(ItemIds.POTION_JUMP))
	assert_eq(e.active_ids(), [ItemIds.POTION_JUMP, ItemIds.POTION_SPEED], "shown in potion order")
	assert_false(e.start(ItemIds.POTION_SPEED), "already working: not wasted")
	assert_almost_eq(e.time_left(ItemIds.POTION_SPEED), 50.0, 0.0001, "the timer did not restart")
	assert_false(e.start(ItemIds.SWORD), "not a potion")
	e.clear()
	assert_eq(e.active_ids(), [])


## The host's decision when a player taps a potion slot (Survivor takes one from the inventory).
func test_who_may_drink() -> void:
	var e := PotionRules.Effects.new()
	assert_eq(PotionRules.refusal(ItemIds.POTION_SPEED, e, true, 0), "", "Sandbox: unlimited")
	assert_eq(PotionRules.refusal(ItemIds.POTION_SPEED, e, false, 2), "", "Survivor: has two")
	assert_string_contains(PotionRules.refusal(ItemIds.POTION_SPEED, e, false, 0), "no Speed Potion")
	e.start(ItemIds.POTION_SPEED)
	assert_string_contains(PotionRules.refusal(ItemIds.POTION_SPEED, e, false, 2), "still working")
	assert_eq(PotionRules.refusal(ItemIds.SWORD, e, true, 1), "?", "not a potion: ignored")


## The host's word on how long a potion has left (LAN guests, late joiners).
func test_the_time_left_can_be_set_by_the_host() -> void:
	var e := PotionRules.Effects.new()
	e.set_left(ItemIds.POTION_SPEED, 20.0)
	assert_almost_eq(e.time_left(ItemIds.POTION_SPEED), 20.0, 0.0001)
	e.set_left(ItemIds.POTION_SPEED, 500.0)
	assert_almost_eq(e.time_left(ItemIds.POTION_SPEED), 60.0, 0.0001, "never more than the potion lasts")
	e.set_left(ItemIds.POTION_SPEED, NAN)
	assert_almost_eq(e.time_left(ItemIds.POTION_SPEED), 60.0, 0.0001, "a broken number: the full time")
	e.set_left(ItemIds.POTION_SPEED, 0.0)
	assert_false(e.is_active(ItemIds.POTION_SPEED), "nothing left")
	e.set_left(ItemIds.SWORD, 10.0)
	assert_eq(e.active_ids(), [] as Array[int], "not a potion")
