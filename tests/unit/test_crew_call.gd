extends GutTest
## Crew flights (spec §21d.6 phase 2): the pilot's call, as a pure state machine (CrewCall). LAUNCH with friends here
## calls them (a card with a countdown: TAKE MY SEAT, STAY HERE); when everyone answered or the time is up, the crew
## is who took a seat (a friend who did not answer in time comes along: nobody is left behind for reading slowly,
## ruling 2) if the rocket carries them all; else the pilot chooses: fly with the ones who fit (the first to take a
## seat) or wait and add crew capsules. Everyone called who does not fly is left behind (their world flies away).

const T0 := 100.0


func _call(friends: Array[int], rocket: Dictionary) -> CrewCall:
	return CrewCall.new(friends, rocket, T0)


func _two() -> Dictionary:
	return load("res://tests/unit/test_crew_flight_rules.gd").two_seats()


func _one() -> Dictionary:
	return load("res://tests/unit/test_crew_flight_rules.gd").one_seat()


func test_it_counts_down_from_the_call() -> void:
	var c := _call([2, 3], _two())
	assert_eq(c.state, CrewCall.CALLING)
	assert_almost_eq(c.seconds_left(T0), CrewFlightRules.CALL_SECONDS, 0.001)
	assert_almost_eq(c.seconds_left(T0 + 4.0), CrewFlightRules.CALL_SECONDS - 4.0, 0.001)
	assert_eq(c.seconds_left(T0 + 99.0), 0.0)
	assert_eq(c.tick(T0 + 1.0), CrewCall.CALLING, "still calling")


func test_a_friend_who_takes_a_seat_flies_when_everyone_answered() -> void:
	var c := _call([2], _two())
	assert_true(c.answer(2, true))
	assert_eq(c.tick(T0 + 1.0), CrewCall.GO, "everyone answered: no need to wait")
	assert_eq(c.crew(), [2] as Array[int])
	assert_eq(c.left_behind(), [] as Array[int])


func test_a_friend_who_stays_is_left_behind() -> void:
	var c := _call([2, 3], _two())
	c.answer(2, false)
	c.answer(3, true)
	assert_eq(c.tick(T0 + 1.0), CrewCall.GO)
	assert_eq(c.crew(), [3] as Array[int])
	assert_eq(c.left_behind(), [2] as Array[int])
	assert_true(c.stayed(2))
	assert_false(c.stayed(3))


func test_the_first_answer_counts() -> void:
	var c := _call([2], _two())
	assert_true(c.answer(2, false))
	assert_false(c.answer(2, true), "a second answer changes nothing")
	assert_false(c.answer(9, true), "a player who was not called")
	c.tick(T0 + 1.0)
	assert_eq(c.crew(), [] as Array[int])


func test_a_friend_who_does_not_answer_in_time_comes_along() -> void:
	var c := _call([2, 3], _two())
	c.answer(3, false)
	assert_eq(c.tick(T0 + CrewFlightRules.CALL_SECONDS - 0.5), CrewCall.CALLING, "2 has not answered yet")
	assert_eq(c.tick(T0 + CrewFlightRules.CALL_SECONDS + 0.1), CrewCall.GO, "the time is up")
	assert_eq(c.crew(), [2] as Array[int], "never left behind for reading slowly (ruling 2)")
	assert_eq(c.left_behind(), [3] as Array[int])


func test_launch_now_decides_at_once() -> void:
	var c := _call([2, 3], _two())
	c.answer(3, false)
	c.launch_now()
	assert_eq(c.tick(T0 + 0.5), CrewCall.GO)
	assert_eq(c.crew(), [2] as Array[int])


func test_too_few_seats_lets_the_pilot_choose() -> void:
	var c := _call([2, 3, 4], _two())
	c.answer(4, true)
	c.answer(2, true)
	c.answer(3, true)
	assert_eq(c.tick(T0 + 1.0), CrewCall.CHOOSING, "3 friends want to fly, 1 seat is free")
	assert_eq(c.room(), 1)
	assert_eq(c.words(), "3 friends want to fly and the rocket has 2 seats: add crew capsules!")
	c.choose(true)
	assert_eq(c.state, CrewCall.GO)
	assert_eq(c.crew(), [4] as Array[int], "the first to take a seat flies")
	assert_eq(c.left_behind(), [2, 3] as Array[int])
	assert_false(c.stayed(2), "no seat for them: they did not choose to stay")


func test_the_pilot_may_wait_and_add_capsules() -> void:
	var c := _call([2], _one())
	c.answer(2, true)
	assert_eq(c.tick(T0 + 1.0), CrewCall.CHOOSING)
	assert_eq(c.room(), 0, "one seat: the pilot's")
	c.choose(false)
	assert_eq(c.state, CrewCall.CANCELLED)
	assert_eq(c.crew(), [] as Array[int])
	assert_eq(c.left_behind(), [] as Array[int], "a launch that waits leaves nobody behind")


func test_the_pilot_may_fly_alone() -> void:
	var c := _call([2], _one())
	c.answer(2, true)
	c.tick(T0 + 1.0)
	c.choose(true)
	assert_eq(c.state, CrewCall.GO)
	assert_eq(c.crew(), [] as Array[int])
	assert_eq(c.left_behind(), [2] as Array[int])


func test_a_friend_who_leaves_meanwhile_is_not_waited_for() -> void:
	var c := _call([2, 3], _two())
	c.answer(3, true)
	c.gone(2)
	assert_eq(c.tick(T0 + 1.0), CrewCall.GO, "the one still here answered")
	assert_eq(c.crew(), [3] as Array[int])
	assert_eq(c.left_behind(), [] as Array[int], "gone is gone: nothing to tell them")


func test_a_friend_who_arrives_meanwhile_is_called_too() -> void:
	var c := _call([2], _two())
	c.answer(2, false)
	c.add(5)
	assert_eq(c.tick(T0 + 1.0), CrewCall.CALLING, "the newcomer has not answered")
	c.answer(5, true)
	assert_eq(c.tick(T0 + 1.5), CrewCall.GO)
	assert_eq(c.crew(), [5] as Array[int])


func test_cancel_ends_the_call_for_everyone() -> void:
	var c := _call([2], _two())
	c.answer(2, true)
	c.cancel()
	assert_eq(c.state, CrewCall.CANCELLED)
	assert_eq(c.tick(T0 + 20.0), CrewCall.CANCELLED)
	assert_eq(c.crew(), [] as Array[int])


func test_a_seat_each_in_the_order_they_answered() -> void:
	var c := _call([2, 3, 4], _two())
	c.answer(3, true)
	c.answer(2, true)
	assert_eq(c.takers(), [3, 2] as Array[int])
	assert_eq(c.seat_of(3), 1, "the pilot sits in seat 0")
	assert_eq(c.seat_of(2), 2)
	assert_eq(c.seat_of(4), -1, "no answer yet")
