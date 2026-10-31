extends GutTest
## Owner #127 (2026-10-17, on the Quest 3): "the menu i see always on the screen should be shows not always, only when i
## raise my elbow like covering a shield". While playing, the HUD shows only on the forearm of the hand that does not
## point, raised in front of the face like a shield (VrPanelRules.shield_up), on a small panel just above that hand
## facing the eyes (shield_transform); the arm down, nothing.

const HEAD := Transform3D(Basis(), Vector3(0, 1.6, 0))   # looking along -Z


## The left hand at `at` (head-relative metres: x right, y up, z back), its fingers' line along `line`.
func _hand(at: Vector3, line: Vector3) -> Transform3D:
	var z := -line.normalized()
	var x := Vector3.UP.cross(z).normalized() if absf(z.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	return Transform3D(Basis(x, z.cross(x), z), HEAD.origin + at)


func test_a_forearm_raised_across_the_face_is_a_shield() -> void:
	assert_true(VrPanelRules.shield_up(HEAD, _hand(Vector3(-0.05, -0.2, -0.35), Vector3.RIGHT), false))


func test_a_hand_down_by_the_side_or_pointing_ahead_is_not() -> void:
	assert_false(VrPanelRules.shield_up(HEAD, _hand(Vector3(-0.25, -0.75, -0.1), Vector3.FORWARD), false), "down by the side")
	assert_false(VrPanelRules.shield_up(HEAD, _hand(Vector3(-0.1, -0.25, -0.45), Vector3.FORWARD), false),
		"reaching ahead to grab or point: the hand's line is not across the body")
	assert_false(VrPanelRules.shield_up(HEAD, _hand(Vector3(-0.1, -0.2, 0.3), Vector3.RIGHT), false), "behind the head")
	assert_false(VrPanelRules.shield_up(HEAD, _hand(Vector3(-0.8, -0.2, -0.3), Vector3.RIGHT), false), "far to the side")


func test_it_holds_at_the_edge_and_never_flickers() -> void:
	var edge := _hand(Vector3(-0.05, -0.2, -(VrPanelRules.SHIELD_AHEAD.y + 0.04)), Vector3.RIGHT)
	assert_false(VrPanelRules.shield_up(HEAD, edge, false), "just past the edge: not raised yet")
	assert_true(VrPanelRules.shield_up(HEAD, edge, true), "once up, the same place keeps it up")


func test_it_follows_where_the_head_looks() -> void:
	var turned := Transform3D(Basis(Vector3.UP, PI * 0.5), HEAD.origin)   # looking along -X
	var hand := Transform3D(Basis(Vector3.UP, PI * 0.5) * _hand(Vector3(0.05, -0.2, -0.35), Vector3.RIGHT).basis,
		HEAD.origin + Vector3(-0.35, -0.2, -0.05))
	assert_true(VrPanelRules.shield_up(turned, hand, false))


func test_the_panel_rides_just_above_the_hand_and_faces_the_eyes() -> void:
	var hand := _hand(Vector3(-0.05, -0.2, -0.35), Vector3.RIGHT)
	var t := VrPanelRules.shield_transform(HEAD.origin, hand)
	assert_almost_eq(t.origin.y - hand.origin.y, VrPanelRules.SHIELD_LIFT, 0.001)
	assert_lt(t.origin.distance_to(hand.origin), 0.2)
	assert_gt(t.basis.z.normalized().dot((HEAD.origin - t.origin).normalized()), 0.99, "its front faces the eyes")
	assert_almost_eq(VrPanelRules.SHIELD_SIZE.x / VrPanelRules.SHIELD_SIZE.y, 16.0 / 9.0, 0.01, "the canvas's shape")
