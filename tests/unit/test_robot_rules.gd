extends GutTest
## Owner #86 (spec §21f): "on the planets we should have some aliens, robots as well". The robots' rules: where the
## helper robot stands by the landing pad, its science quest (dig, explore, come back and answer), its questions'
## gold (once each, right the first time), the rover buddy that follows and the drone that scouts ahead.

const PAD := Vector2(100, 200)


func test_the_helper_stands_front_right_of_the_landing_child() -> void:
	var at := RobotRules.helper_spot(PAD, Vector2(0, -1))   # facing north (-z): right is +x
	assert_almost_eq(at.distance_to(PAD), RobotRules.HELPER_RING, 0.01, "a few steps from the pad's middle")
	assert_gt(at.x, PAD.x, "to the right")
	assert_lt(at.y, PAD.y, "and in front: the child sees it")


func test_the_helper_never_stands_in_the_portal_home_or_where_the_lander_parks() -> void:
	for fwd: Vector2 in [Vector2(0, -1), Vector2(1, 0), Vector2(-0.6, 0.8), Vector2(0, 1)]:
		var at := RobotRules.helper_spot(PAD, fwd)
		var portal := PAD + fwd.normalized() * RobotRules.PORTAL_AHEAD
		var right := Vector2(-fwd.normalized().y, fwd.normalized().x)
		var lander := PAD - right * RobotRules.LANDER_LEFT
		assert_gt(at.distance_to(portal), RobotRules.PORTAL_R + 1.0, "clear of the portal home (%s)" % fwd)
		assert_gt(at.distance_to(lander), RobotRules.LANDER_R + 1.0, "clear of the lander (%s)" % fwd)


func test_the_helper_moves_round_tilly_and_the_thermometer() -> void:
	var first := RobotRules.helper_spot(PAD, Vector2(0, -1))
	var moved := RobotRules.helper_spot(PAD, Vector2(0, -1), [{"at": first, "r": 2.0}])
	assert_ne(moved, first, "a stall where it would stand: it picks another spot")
	assert_gt(moved.distance_to(first), 2.0 + RobotRules.CLEAR - 0.01)
	var everywhere: Array = []
	for deg in RobotRules.ANGLES:
		var a := deg_to_rad(deg)
		everywhere.append({"at": PAD + (Vector2(0, -1) * cos(a) + Vector2(1, 0) * sin(a)) * RobotRules.HELPER_RING, "r": 1.0})
	assert_eq(RobotRules.helper_spot(PAD, Vector2(0, -1), everywhere), first, "nowhere free: the first spot anyway")


func test_it_turns_to_face_what_it_points_at() -> void:
	var from := Vector3(0, 40, 0)
	var yaw := RobotRules.yaw_to(from, Vector3(10, 40, 0))
	var front := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	assert_almost_eq(front, Vector3.RIGHT, Vector3.ONE * 0.001, "its front (-Z) turned towards +x")
	yaw = RobotRules.yaw_to(from, Vector3(0, 40, -5))
	assert_almost_eq(yaw, 0.0, 0.001, "already facing -z")


func test_the_science_quest_goes_dig_explore_and_come_back() -> void:
	var found := {}
	assert_eq(RobotRules.quest_step(found), RobotRules.OFFER)
	RobotRules.start_quest(found, &"volcano")
	assert_eq(RobotRules.quest_place(found), "sight:volcano", "the guide's next place")
	assert_eq(RobotRules.quest_step(found), RobotRules.DIG)
	assert_true(RobotRules.dig(found))
	assert_false(RobotRules.dig(found), "one sample per world")
	assert_eq(RobotRules.quest_step(found), RobotRules.FIND)
	found["sight:volcano"] = true   # SpaceSights keeps a find so
	assert_eq(RobotRules.quest_step(found), RobotRules.BACK)
	assert_true(RobotRules.finish(found))
	assert_eq(RobotRules.quest_step(found), RobotRules.FINISHED)
	assert_false(RobotRules.finish(found), "once")


func test_a_planet_without_sights_sends_the_child_to_the_aliens() -> void:
	var found := {}
	RobotRules.start_quest(found, &"")
	assert_eq(RobotRules.quest_place(found), RobotRules.CAMP_PLACE)
	RobotRules.dig(found)
	assert_eq(RobotRules.quest_step(found), RobotRules.FIND)
	found[RobotRules.CAMP] = true
	assert_eq(RobotRules.quest_step(found), RobotRules.BACK)


func test_a_sample_dug_before_the_quest_still_counts() -> void:
	var found := {}
	RobotRules.dig(found)
	RobotRules.start_quest(found, &"")
	found[RobotRules.CAMP] = true
	assert_eq(RobotRules.quest_step(found), RobotRules.BACK)


func test_the_quests_marks_are_never_counted_as_secrets() -> void:
	var state := SecretState.new()
	RobotRules.start_quest(state.found, &"canyon")
	RobotRules.dig(state.found)
	state.found[RobotRules.CAMP] = true
	RobotRules.finish(state.found)
	state.explore(Vector2i(0, 0), 3)
	assert_eq(state.counts(), Vector2i(0, 3), "the Secret Book's count is its own")
	var back := SecretState.from_save(state.to_save())
	assert_eq(RobotRules.quest_step(back.found), RobotRules.FINISHED, "kept with the world")


func test_questions_pay_once_each_right_the_first_time() -> void:
	var data := CreatureData.new()
	var q := RobotRules.next_question(19, data)
	assert_eq(str(q.id), "mars_red", "the first one first")
	assert_false(RobotRules.is_right(q, 0))
	assert_true(RobotRules.is_right(q, int(q.answer)))
	assert_eq(RobotRules.quiz_gold(data, str(q.id), false), 0, "right after a miss: praise, no gold")
	assert_eq(RobotRules.quiz_gold(data, str(q.id), true), EarnRules.FACT_QUIZ_GOLD, "right the first time")
	assert_eq(RobotRules.quiz_gold(data, str(q.id), true), 0, "once per question")
	assert_eq(str(RobotRules.next_question(19, data).id), "mars_volcano", "the next one not paid")
	for each: Dictionary in CreatureWords.robot(19).questions:
		RobotRules.quiz_gold(data, str(each.id), true)
	assert_false(RobotRules.has_unpaid(19, data))
	assert_eq(str(RobotRules.next_question(19, data).id), "mars_red", "all paid: practice again, no gold")
	assert_eq(RobotRules.next_question(5, data), {}, "no robot there")


func test_the_rover_follows_behind_and_catches_up() -> void:
	var child := Vector3(0, 40, 0)
	var goal := RobotRules.rover_goal(child, Vector3.FORWARD)
	assert_gt(goal.z, child.z, "behind the child (who faces -z)")
	assert_gt(goal.x, child.x, "a little to the right")
	var at := Vector3(-10, 40, 0)
	var step := RobotRules.rover_step(at, goal, 0.1)
	assert_almost_eq(at.distance_to(step), RobotRules.ROVER_SPEED * 0.1, 0.01, "at its speed")
	assert_eq(RobotRules.rover_step(goal, goal, 0.1), goal, "there: it waits")
	assert_false(RobotRules.rover_teleports(at, child))
	assert_true(RobotRules.rover_teleports(Vector3(40, 40, 0), child), "left far behind: it comes at once")
	assert_true(RobotRules.rover_teleports(Vector3(0, 60, 0), child), "a big fall or climb too")


func test_the_drone_scouts_ahead_towards_the_next_place() -> void:
	var child := Vector3(0, 40, 0)
	var ahead := RobotRules.drone_goal(child, Vector3(0, 40, -100), 0.0)
	assert_almost_eq(ahead, Vector3(0, 40 + RobotRules.DRONE_HEIGHT, -RobotRules.DRONE_AHEAD), Vector3.ONE * 0.001)
	var near := RobotRules.drone_goal(child, Vector3(3, 40, 0), 0.0)
	assert_lt(Vector2(near.x, near.z).length(), 3.0, "never past the place itself")
	var circling := RobotRules.drone_goal(child, Vector3.INF, 1.0)
	assert_almost_eq(Vector2(circling.x, circling.z).length(), RobotRules.CIRCLE_R, 0.001, "no place: it circles over")
	var at := Vector3(0, 44, 10)
	var step := RobotRules.drone_step(at, ahead, 0.1)
	assert_lt(step.distance_to(ahead), at.distance_to(ahead), "it flies there")


func test_the_drone_says_where_the_place_is() -> void:
	var child := Vector3(0, 40, 0)
	assert_eq(RobotRules.drone_words(child, Vector3(0, 40, -125), "Great Canyon", false),
		"Your drone flew ahead: Great Canyon is 125 blocks north!")
	assert_eq(RobotRules.drone_words(child, Vector3(30, 40, 30), "", true),
		"Your drone flew ahead: the aliens are 42 blocks south-east!")
	assert_eq(RobotRules.drone_words(child, Vector3.INF, "", false), CreatureWords.DRONE_NOTHING)
