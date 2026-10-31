extends GutTest
## Owner #79 (spec §25.3): the child steers (a gentle turn); the autopilot keeps it safe: never a crash, kind
## corrections ("Nudge left to aim at the Moon!"). FlightSteering keeps where the target is from the rocket's nose
## (degrees; x right, y up), turns it with the child's stick (keys, a drag), lets it wander a little when nobody steers
## (something to do) and brings it back itself after a while.


func _steering() -> FlightSteering:
	var s := FlightSteering.new(7)
	s.target_name = "the Moon"
	s.active = true
	return s


func test_steering_toward_the_target_brings_it_to_the_middle() -> void:
	var s := _steering()
	s.off = Vector2(-15, 0)   # the Moon is left of the nose
	for i in 3:
		s.tick(0.1, Vector2(-1, 0))   # steer left
	assert_lt(absf(s.off.x), 15.0 - 8.0)
	s.off = Vector2(0, 10)   # above
	for i in 2:
		s.tick(0.1, Vector2(0, 1))   # nose up
	assert_lt(absf(s.off.y), 10.0 - 5.0)


func test_the_target_never_gets_away() -> void:
	var s := _steering()
	for i in 200:
		s.tick(0.1, Vector2(1, 1))
	assert_lte(s.off.length(), FlightSteering.MAX_OFF + 0.001, "never lost: never a crash")


func test_nobody_steering_it_wanders_then_the_autopilot_brings_it_back() -> void:
	var s := _steering()
	var most := 0.0
	for i in 400:
		s.tick(0.1, Vector2.ZERO)
		most = maxf(most, s.off.length())
	assert_gt(most, FlightSteering.ON_TARGET, "it wanders: something to do")
	assert_lte(most, FlightSteering.MAX_OFF + 0.001)
	for i in int((FlightSteering.AUTOPILOT_AFTER + 0.3) * 10.0):
		s.off = Vector2(18, 0)
		s.tick(0.1, Vector2.ZERO)
	assert_true(s.autopilot, "the autopilot took over")
	for i in 10:
		s.tick(0.1, Vector2.ZERO)
	assert_lt(s.off.length(), 18.0 - 5.0, "and brings it back toward the middle")


func test_the_child_steering_takes_the_controls_back() -> void:
	var s := _steering()
	for i in int((FlightSteering.AUTOPILOT_AFTER + 0.5) * 10.0):
		s.off = Vector2(18, 0)
		s.tick(0.1, Vector2.ZERO)
	assert_true(s.autopilot)
	s.tick(0.1, Vector2(1, 0))
	assert_false(s.autopilot, "the child steers again")


func test_kind_words_say_which_way() -> void:
	var s := _steering()
	s.off = Vector2(-16, 2)
	for i in int(FlightSteering.HELP_AFTER * 10.0) + 2:
		s.tick(0.1, Vector2.ZERO)
		s.off = Vector2(-16, 2)
	assert_eq(s.hint(), "Nudge left to aim at the Moon!")
	s.off = Vector2(1, -14)
	assert_eq(s.hint(), "Nudge down to aim at the Moon!")
	s.off = Vector2.ZERO
	for i in 12:
		s.tick(0.1, Vector2.ZERO)
		s.off = Vector2.ZERO
	assert_true(s.on_target())
	assert_eq(s.hint(), "Right on target!")


func test_off_duty_it_holds_the_course() -> void:
	var s := _steering()
	s.active = false
	s.off = Vector2(10, -10)
	for i in 30:
		s.tick(0.1, Vector2(1, 0))
	assert_lt(s.off.length(), 1.0, "outside steering steps the autopilot flies straight")
	assert_eq(s.hint(), "")
