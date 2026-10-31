extends GutTest
## Owner #110 (VR round 4, idea 8; the research's §5.3): the cockpit you touch, pure. STAGE, LEGS and LIGHTS are big
## buttons on the rocket's dashboard (at least 40 x 40 mm, twice Meta's 22 mm, and 15 mm apart), in a row above its
## screens; the index fingertip of the child's hand pokes them: a press when it comes in through the panel's face over a
## button, again only after it came back out. On the burns the controllers rumble low, stronger with more throttle,
## always in pulses (never one long buzz) and capped; the stage separation is a thump; the countdown's last three
## seconds tick.

const BAND := Rect2(0, 200, 1280, 520)   # FlightCockpit.dashboard_rect of the 1280 x 720 canvas
const QUAD := Vector2(0.72, 0.2925)       # VrUi's dashboard quad (DASHBOARD_WIDTH, its band's height)


func test_the_three_buttons_and_their_words() -> void:
	assert_eq(CockpitTouchRules.BUTTONS, [&"stage", &"legs", &"lights"] as Array[StringName])
	assert_eq(CockpitTouchRules.STAGE, FlightPlan.STAGE, "STAGE does the flight's STAGE")
	assert_eq(CockpitTouchRules.LEGS, FlightPlan.LEGS)
	assert_eq(CockpitTouchRules.word(&"lights"), "LIGHTS")


func test_a_dashboard_pixel_is_about_half_a_millimetre() -> void:
	assert_almost_eq(CockpitTouchRules.mm_per_px(), 0.5625, 0.0001, "0.72 m over 1280 px")
	assert_almost_eq(CockpitTouchRules.quad_size(), QUAD, Vector2.ONE * 0.0001)


func test_the_buttons_are_big_far_enough_apart_and_in_a_row_over_the_screens() -> void:
	var rects := CockpitTouchRules.button_rects(BAND)
	assert_eq(rects.size(), 3)
	var mm := CockpitTouchRules.mm_per_px()
	var last := -INF
	for b: StringName in CockpitTouchRules.BUTTONS:
		var r: Rect2 = rects[b]
		assert_gte(r.size.x * mm, 40.0, "%s: 40 mm wide or more" % b)
		assert_gte(r.size.y * mm, 40.0, "%s: 40 mm high or more" % b)
		assert_true(BAND.encloses(r), "%s on the dashboard" % b)
		assert_gt(r.position.x, last, "left to right: STAGE, LEGS, LIGHTS")
		if last > -INF:
			assert_gte((r.position.x - last) * mm, 15.0, "15 mm apart or more")
		last = r.end.x
		assert_lte(r.end.y, BAND.end.y - FlightCockpit.DASH_H + 22.0, "over the screens")
		assert_gte(r.position.x, 170.0, "clear of the throttle lever")
		assert_lte(r.end.x, BAND.end.x - 222.0, "clear of ACTION")


func test_a_point_on_the_quad_is_its_canvas_pixel() -> void:
	assert_almost_eq(CockpitTouchRules.to_canvas(Vector3.ZERO, BAND), BAND.get_center(), Vector2.ONE * 0.01, "the middle")
	assert_almost_eq(CockpitTouchRules.to_canvas(Vector3(-QUAD.x * 0.5, QUAD.y * 0.5, 0.0), BAND), BAND.position,
		Vector2.ONE * 0.01, "the top left corner")
	var one_cm := CockpitTouchRules.to_canvas(Vector3(0.01, 0.0, 0.0), BAND) - BAND.get_center()
	assert_almost_eq(one_cm.x, 10.0 / CockpitTouchRules.mm_per_px(), 0.01, "a centimetre right")
	assert_lt(CockpitTouchRules.to_canvas(Vector3(0.0, 0.01, 0.0), BAND).y, BAND.get_center().y, "up is up")


func test_the_index_fingertip_is_where_the_hand_models_finger_ends() -> void:
	var right := CockpitTouchRules.fingertip(Transform3D.IDENTITY, &"right", 0.0)
	var tip_z := -(VrHandModel.PALM.z * 0.5 + VrHandModel.INDEX.z)
	assert_almost_eq(right.z, tip_z, 0.0001, "the fingers point along -Z")
	assert_lt(right.x, 0.0, "the right hand's index is on its left side (towards the body's middle)")
	var left := CockpitTouchRules.fingertip(Transform3D.IDENTITY, &"left", 0.0)
	assert_almost_eq(left.x, -right.x, 0.0001, "the left hand's on its right")
	var curled := CockpitTouchRules.fingertip(Transform3D.IDENTITY, &"right", 1.0)
	assert_gt(curled.z, right.z + 0.03, "the trigger curls the finger back")
	var moved := CockpitTouchRules.fingertip(Transform3D(Basis(), Vector3(1, 2, 3)), &"right", 0.0, 2.0)
	assert_almost_eq(moved, Vector3(1, 2, 3) + right * 2.0, Vector3.ONE * 0.0001, "the hand's place and size")


func test_a_poke_comes_in_through_the_face_and_presses_once() -> void:
	var rects := CockpitTouchRules.button_rects(BAND)
	var on: Vector2 = (rects[&"stage"] as Rect2).get_center()
	var s := {}
	assert_eq(CockpitTouchRules.poke(s, 0.05, on, rects), &"", "5 cm away: no press")
	assert_eq(CockpitTouchRules.hover(0.03, on, rects), &"stage", "close over it: it glows")
	assert_eq(CockpitTouchRules.poke(s, 0.01, on, rects), &"")
	assert_eq(CockpitTouchRules.poke(s, -0.002, on, rects), &"stage", "the fingertip at the face: pressed")
	assert_eq(CockpitTouchRules.poke(s, -0.01, on, rects), &"", "pushed on: still one press")
	assert_eq(CockpitTouchRules.poke(s, 0.005, on, rects), &"", "out a little: not yet again")
	assert_eq(CockpitTouchRules.poke(s, -0.002, on, rects), &"", "a wobble is no second press")
	assert_eq(CockpitTouchRules.poke(s, CockpitTouchRules.RELEASE + 0.005, on, rects), &"")
	assert_eq(CockpitTouchRules.poke(s, -0.001, on, rects), &"stage", "out and in again: a second press")


func test_a_finger_that_comes_in_beside_the_buttons_or_slides_on_behind_presses_nothing() -> void:
	var rects := CockpitTouchRules.button_rects(BAND)
	var stage: Rect2 = rects[&"stage"]
	var beside := Vector2(stage.position.x - 30.0, stage.get_center().y)
	var s := {}
	CockpitTouchRules.poke(s, 0.03, beside, rects)
	assert_eq(CockpitTouchRules.poke(s, -0.005, beside, rects), &"", "into the panel beside it")
	assert_eq(CockpitTouchRules.poke(s, -0.005, stage.get_center(), rects), &"", "slid onto it behind the face: no press")
	var far := {}
	assert_eq(CockpitTouchRules.poke(far, -0.2, stage.get_center(), rects), &"", "far behind the panel (a hand round it)")


func test_the_burn_rumbles_low_in_capped_pulses_stronger_with_more_throttle() -> void:
	assert_eq(CockpitTouchRules.rumble(0.0), 0.0, "no fire, no rumble")
	assert_eq(CockpitTouchRules.rumble(CockpitTouchRules.RUMBLE_FIRE * 0.5), 0.0)
	assert_gt(CockpitTouchRules.rumble(1.0), CockpitTouchRules.rumble(0.4), "more throttle: stronger")
	assert_lte(CockpitTouchRules.rumble(1.0), 0.5, "capped")
	assert_lt(CockpitTouchRules.RUMBLE_PULSE, CockpitTouchRules.RUMBLE_EVERY * 0.6, "pulses with gaps: never one long buzz")
	assert_lte(CockpitTouchRules.RUMBLE_HZ, 100.0, "low")
	assert_gt(float(CockpitTouchRules.THUMP[0]), CockpitTouchRules.rumble(1.0), "the stage separation is a thump")
	assert_eq(CockpitTouchRules.TICKS_FROM, 3, "the countdown's last three seconds tick")
