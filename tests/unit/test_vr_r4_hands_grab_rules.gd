extends GutTest
## Owner #110, VR round 4 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md): VrGrabRules' body, the sums the grabber uses on
## the frozen numbers: the near pick with its magnetism, the laser's far pick in its cone, the flick and the 0.6 s hold
## (R4), the shoulder bag, the pull's catchable flight, the two-hand stretch, the samples kept, the grip as a press.


func test_the_near_pick_takes_the_nearest_within_reach_counted_from_the_surface() -> void:
	var grip := Transform3D(Basis(), Vector3(0, 1, 0))
	var things := [
		{"pos": Vector3(0.0, 1.0, -0.30), "radius": 0.0},    # 30 cm: out of reach
		{"pos": Vector3(0.10, 1.0, 0.0), "radius": 0.0},     # 10 cm: in reach
		{"pos": Vector3(0.0, 1.0, -0.40), "radius": 0.35},   # a planet 40 cm away, its surface 5 cm: nearer
	]
	assert_eq(VrGrabRules.near_pick(grip, things), 2, "a big thing's surface counts")
	things.pop_back()
	assert_eq(VrGrabRules.near_pick(grip, things), 1)
	assert_eq(VrGrabRules.near_pick(grip, [things[0]]), -1, "nothing within NEAR_REACH")
	assert_eq(VrGrabRules.near_pick(grip, []), -1)


func test_the_near_pick_favours_a_thing_ahead_of_the_palm() -> void:
	var grip := Transform3D(Basis(), Vector3.ZERO)   # the palm faces -Z
	var behind := {"pos": Vector3(0, 0, 0.08), "radius": 0.0}
	var ahead := {"pos": Vector3(0, 0, -0.09), "radius": 0.0}
	assert_eq(VrGrabRules.near_pick(grip, [behind, ahead]), 1, "a centimetre further but ahead of the fingers")


func test_the_far_pick_finds_the_thing_in_the_lasers_cone_within_range() -> void:
	var things := [
		{"pos": Vector3(0.5, 1.0, -3.0), "radius": 0.0},   # about 9.5 degrees off: outside the cone
		{"pos": Vector3(0.2, 1.0, -3.0), "radius": 0.0},   # about 3.8 degrees off: inside
		{"pos": Vector3(0.0, 1.0, -5.0), "radius": 0.0},   # dead ahead but past FAR_RANGE
	]
	assert_eq(VrGrabRules.far_pick(Vector3(0, 1, 0), Vector3.FORWARD, things), 1)
	things.remove_at(1)
	assert_eq(VrGrabRules.far_pick(Vector3(0, 1, 0), Vector3.FORWARD, things), -1, "none in the cone within range")
	var big := [{"pos": Vector3(0.5, 1.0, -3.0), "radius": 0.4}]
	assert_eq(VrGrabRules.far_pick(Vector3(0, 1, 0), Vector3.FORWARD, big), 0, "a big thing widens the cone")


func test_the_far_pick_prefers_the_one_nearest_the_beam() -> void:
	var things := [{"pos": Vector3(0.2, 0, -2.0), "radius": 0.0}, {"pos": Vector3(0.0, 0, -3.0), "radius": 0.0}]
	assert_eq(VrGrabRules.far_pick(Vector3.ZERO, Vector3.FORWARD, things), 1)


func test_a_flick_is_a_quick_pull_towards_the_head_or_upwards() -> void:
	var to_head := Vector3(0, 0, 1)   # the head is behind the hand
	assert_false(VrGrabRules.flick([], to_head))
	assert_false(VrGrabRules.flick([{"t": 0.0, "v": Vector3(0, 0, 0.8)}], to_head), "too slow")
	assert_true(VrGrabRules.flick([{"t": 0.0, "v": Vector3(0, 0, 1.5)}], to_head), "towards the head")
	assert_true(VrGrabRules.flick([{"t": 0.0, "v": Vector3(0, 1.4, 0)}], to_head), "upwards")
	assert_false(VrGrabRules.flick([{"t": 0.0, "v": Vector3(0, 0, -3.0)}], to_head), "a push away is no pull")
	var old := [{"t": 0.0, "v": Vector3(0, 2.0, 0)}, {"t": 0.5, "v": Vector3.ZERO}]
	assert_false(VrGrabRules.flick(old, to_head), "older than FLICK_WINDOW")


func test_over_the_shoulder_is_behind_the_heads_plane_and_not_too_low() -> void:
	var head := Transform3D(Basis(), Vector3(0, 1.6, 0))   # looks along -Z
	assert_true(VrGrabRules.over_shoulder(head, Vector3(0.15, 1.65, 0.12)), "behind the head, by the ear")
	assert_false(VrGrabRules.over_shoulder(head, Vector3(0.15, 1.5, -0.3)), "in front")
	assert_false(VrGrabRules.over_shoulder(head, Vector3(0.15, 1.0, 0.12)), "down by the hip")
	assert_false(VrGrabRules.over_shoulder(head, Vector3(0.0, 1.6, 0.9)), "too far behind")
	var turned := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 1.6, 0))   # looks along -X
	assert_true(VrGrabRules.over_shoulder(turned, Vector3(0.12, 1.65, 0.1)), "the head's own back")


func test_a_pulled_thing_flies_from_where_it_was_to_the_hand_rising_on_the_way() -> void:
	var from := Vector3(0, 0, -3)
	var to := Vector3(0, 1, 0)
	assert_almost_eq(VrGrabRules.pull_point(from, to, 0.0).distance_to(from), 0.0, 0.0001)
	assert_almost_eq(VrGrabRules.pull_point(from, to, 1.0).distance_to(to), 0.0, 0.0001, "at the hand: caught")
	var mid := VrGrabRules.pull_point(from, to, 0.5)
	assert_gt(mid.y, from.lerp(to, 0.5).y + 0.1, "an arc, not a line")


func test_two_hands_stretch_between_the_limits() -> void:
	assert_almost_eq(VrGrabRules.stretch(0.3, 0.6), 2.0, 0.0001)
	assert_almost_eq(VrGrabRules.stretch(0.3, 3.0), VrGrabRules.STRETCH_MAX, 0.0001)
	assert_almost_eq(VrGrabRules.stretch(0.3, 0.01), VrGrabRules.STRETCH_MIN, 0.0001)
	assert_almost_eq(VrGrabRules.stretch(0.0, 0.5), 1.0, 0.0001, "no start: no stretch")


func test_the_samples_keep_only_the_last_span() -> void:
	var s: Array = []
	for i in 20:
		VrGrabRules.add_sample(s, i * 0.05, Vector3(i, 0, 0))
	assert_lte(float(s[s.size() - 1].t) - float(s[0].t), VrGrabRules.SAMPLE_SPAN + 0.0001)
	assert_eq(VrGrabRules.throw_velocity(s).x, minf(19.0 * VrGrabRules.THROW_SCALE, VrGrabRules.THROW_MAX),
		"the frozen throw reads them")


func test_the_grip_is_a_press_with_hysteresis() -> void:
	assert_false(VrGrabRules.grip_down(0.5, false))
	assert_true(VrGrabRules.grip_down(0.7, false))
	assert_true(VrGrabRules.grip_down(0.4, true), "held while above GRIP_OFF")
	assert_false(VrGrabRules.grip_down(0.3, true))
