extends GutTest
## Owner #101 (VR on the Meta Quest), P4: `vr_pose`, the head and both hands of a VR player in a few bytes (VrPoseRules),
## sent with the player's 20 Hz sync: small (under 1 KB/s), close enough to nod, look round and wave, safe to read
## from anyone (empty, short, garbage or another version's bytes are no pose, never an error), and the bow and swing
## rules of the hands (two-handed draw, opt-in swings).


func _close(a: Transform3D, b: Transform3D, pos: float, ang: float, what: String) -> void:
	assert_almost_eq(a.origin.distance_to(b.origin), 0.0, pos, "%s: where" % what)
	assert_almost_eq(Quaternion(a.basis.orthonormalized()).angle_to(Quaternion(b.basis.orthonormalized())), 0.0, ang,
		"%s: which way" % what)


func test_a_pose_is_21_bytes_and_under_1_kb_a_second() -> void:
	var b := VrPoseRules.encode(Transform3D(Basis(), Vector3(0, 1.55, 0)), Transform3D(), Transform3D(), Vector4.ZERO, 1.55, 1.0)
	assert_eq(b.size(), VrPoseRules.SIZE)
	assert_eq(b[0], VrPoseRules.VERSION, "the version first: a later layout is never misread")
	assert_lt(VrPoseRules.SIZE * VrPoseRules.HZ, 1000.0, "the research's +1 KB/s at most per VR player")


func test_the_head_and_hands_come_back_close_enough_to_nod_and_wave() -> void:
	var head := Transform3D(Basis.from_euler(Vector3(0.4, -1.0, 0.1)), Vector3(0.1, 1.6, -0.2))
	var left := Transform3D(Basis(Vector3(0.3, 1, 0.2).normalized(), 0.8), Vector3(-0.3, 1.1, -0.45))
	var right := Transform3D(Basis.from_euler(Vector3(-0.7, 0.5, 1.2)), Vector3(0.35, 1.3, -0.6))
	var b := VrPoseRules.encode(head, left, right, Vector4(1.0, 0.2, 0.0, 0.8), 1.55, 1.0)
	var p := VrPoseRules.decode(b, 1.55, 1.0)
	assert_false(p.is_empty())
	_close(p.head, head, 0.005, 0.03, "the head")
	_close(p.left, left, 0.012, 0.03, "the left hand")
	_close(p.right, right, 0.012, 0.03, "the right hand")
	assert_almost_eq(float(p.left_grip), 1.0, 0.07)
	assert_almost_eq(float(p.left_trigger), 0.2, 0.07)
	assert_almost_eq(float(p.right_grip), 0.0, 0.07)
	assert_almost_eq(float(p.right_trigger), 0.8, 0.07)


func test_a_giants_pose_is_sent_at_the_giants_size() -> void:
	var s := 3.0
	var head := Transform3D(Basis(), Vector3(0.0, 1.55 * s, 0.0))
	var right := Transform3D(Basis(), Vector3(0.9, 1.2 * s, -1.5))
	var p := VrPoseRules.decode(VrPoseRules.encode(head, Transform3D(Basis(), Vector3(0, 1.2 * s, 0)), right, Vector4.ZERO,
		1.55 * s, s), 1.55 * s, s)
	_close(p.right, right, 0.04, 0.03, "a giant's reach")


func test_a_hand_too_far_is_held_at_arms_length_never_wrapped_round() -> void:
	var far := Transform3D(Basis(), Vector3(5.0, 1.55, 0.0))
	var p := VrPoseRules.decode(VrPoseRules.encode(Transform3D(Basis(), Vector3(0, 1.55, 0)), far, far, Vector4.ZERO, 1.55,
		1.0), 1.55, 1.0)
	assert_gt((p.right as Transform3D).origin.x, 1.0, "at the edge on the same side")


func test_nothing_is_ever_misread_as_a_pose() -> void:
	assert_eq(VrPoseRules.decode(PackedByteArray(), 1.55, 1.0), {}, "a phone or the web: no pose")
	assert_eq(VrPoseRules.decode(PackedByteArray([1, 2, 3]), 1.55, 1.0), {}, "too short")
	var b := VrPoseRules.encode(Transform3D(Basis(), Vector3(0, 1.55, 0)), Transform3D(), Transform3D(), Vector4.ZERO, 1.55, 1.0)
	b[0] = VrPoseRules.VERSION + 1
	assert_eq(VrPoseRules.decode(b, 1.55, 1.0), {}, "a later layout: no pose until this game knows it")
	var longer := VrPoseRules.encode(Transform3D(Basis(), Vector3(0, 1.55, 0)), Transform3D(), Transform3D(), Vector4.ZERO,
		1.55, 1.0)
	longer.append_array(PackedByteArray([9, 9, 9]))
	assert_false(VrPoseRules.decode(longer, 1.55, 1.0).is_empty(), "this layout with more after it: what it knows")
	var garbage := PackedByteArray()
	garbage.resize(VrPoseRules.SIZE)
	garbage.fill(255)
	garbage[0] = VrPoseRules.VERSION
	var g := VrPoseRules.decode(garbage, 1.55, 1.0)
	assert_true((g.head as Transform3D).is_finite(), "any bytes: a finite pose")


func test_the_bow_is_drawn_by_pulling_the_string_hand_back_from_the_bow_hand() -> void:
	assert_true(VrRules.bow_grabs(0.1), "the string hand at the bow")
	assert_false(VrRules.bow_grabs(0.4), "too far to take the string")
	assert_eq(VrRules.bow_power(0.1), 0.0, "not pulled yet")
	assert_almost_eq(VrRules.bow_power(VrRules.BOW_FULL_DRAW), 1.0, 0.001, "a full draw")
	assert_lt(VrRules.bow_power(0.35), 1.0)
	assert_gt(VrRules.bow_power(0.35), 0.0)


func test_a_swing_is_one_attack_and_a_held_swords_swing_is_on_by_default() -> void:
	assert_true(VrRules.setting({}, VrRules.SWING), "owner #128: a held sword hits by swinging it")
	assert_true(VrRules.setting({"vr_swing": false}, VrRules.SWING), "P4's old opt-in, saved off, no longer decides")
	var s := VrRules.swing_step(3.0, false)
	assert_true(s.hit, "a fast swing hits")
	assert_true(s.swinging)
	s = VrRules.swing_step(2.5, s.swinging)
	assert_false(s.hit, "the same swing: one hit")
	s = VrRules.swing_step(0.5, s.swinging)
	assert_false(s.swinging, "slowed down: the next swing may hit")
	assert_false(VrRules.swing_step(1.2, false).hit, "a wave is no swing")
