extends GutTest
## Owner #112, #113 (docs/design/life-skills.md §10: "big, forgiving targets"): where a hand, a laser, a finger and the
## head are, in the practice rooms' terms: a hand touches a thing near it, a laser points at it, a finger taps near it on
## the screen (never less than a fingertip's room), the head is low under the smoke, the hands cover the face, a roll.


func test_a_hand_touches_a_thing_within_its_reach_and_a_little_more() -> void:
	assert_true(LifeReach.touching(Vector3(0, 1, 0), Vector3(0, 1, 0), 0.1))
	assert_true(LifeReach.touching(Vector3(0.14, 1, 0), Vector3(0, 1, 0), 0.1), "a forgiving slack")
	assert_false(LifeReach.touching(Vector3(0.4, 1, 0), Vector3(0, 1, 0), 0.1))


func test_a_laser_hits_a_round_target() -> void:
	assert_gt(LifeReach.ray_hit(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, -3), 0.3), 0.0)
	assert_lt(LifeReach.ray_hit(Vector3.ZERO, Vector3(0, 0, -1), Vector3(1, 0, -3), 0.3), 0.0, "missed")
	assert_lt(LifeReach.ray_hit(Vector3.ZERO, Vector3(0, 0, -1), Vector3(0, 0, 3), 0.3), 0.0, "behind the hand")


func test_where_across_a_target_the_laser_is() -> void:
	var u := LifeReach.across(Vector3(0.2, 0, 0), Vector3(0, 0, -1), Vector3(0, 0, -2), Vector3.RIGHT, 0.4)
	assert_almost_eq(u, 0.5, 0.01)
	assert_true(is_nan(LifeReach.across(Vector3(2, 0, 0), Vector3(0, 0, -1), Vector3(0, 0, -2), Vector3.RIGHT, 0.4)))


func test_a_finger_picks_the_nearest_target_within_reach() -> void:
	var at := {"phone": Vector2(100, 100), "cloth": Vector2(300, 100)}
	var radius := {"phone": 20.0, "cloth": 20.0}
	assert_eq(LifeReach.screen_pick(Vector2(130, 110), at, radius), "phone", "at least a fingertip's room")
	assert_eq(LifeReach.screen_pick(Vector2(280, 90), at, radius), "cloth")
	assert_eq(LifeReach.screen_pick(Vector2(200, 400), at, radius), "")
	assert_eq(LifeReach.screen_pick(Vector2(200, 100), {"a": Vector2(150, 100), "b": Vector2(240, 100)},
		{"a": 80.0, "b": 80.0}), "b", "the nearer one when both reach")


func test_the_head_is_low_when_it_drops_30_centimetres() -> void:
	assert_false(LifeReach.head_low(1.4, 1.5))
	assert_true(LifeReach.head_low(1.15, 1.5))


func test_both_hands_cover_the_face() -> void:
	var head := Transform3D(Basis(), Vector3(0, 1.4, 0))
	assert_true(LifeReach.hands_at_face(Vector3(-0.08, 1.38, -0.12), Vector3(0.08, 1.38, -0.12), head))
	assert_false(LifeReach.hands_at_face(Vector3(-0.08, 1.38, -0.12), Vector3(0.4, 0.9, -0.2), head))


func test_a_roll_is_the_head_going_side_to_side() -> void:
	var roll := LifeReach.Roll.new()
	var rolled := false
	for x: float in [0.0, -0.1, -0.2, -0.1, 0.0, 0.1, 0.2, 0.1, 0.0, -0.2]:
		rolled = rolled or roll.feed(x)
	assert_true(rolled, "left, right and left again")
	var from_a_side := LifeReach.Roll.new()
	rolled = false
	for x: float in [0.2, -0.2, 0.2, -0.2]:
		rolled = rolled or from_a_side.feed(x)
	assert_true(rolled, "a roll that starts at one side counts too")
	var still := LifeReach.Roll.new()
	var moved := false
	for x: float in [0.0, 0.02, -0.02, 0.01]:
		moved = moved or still.feed(x)
	assert_false(moved)
