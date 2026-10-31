extends GutTest
## Owner #110, VR round 4's frozen contract (docs/superpowers/plans/2026-10-16-vr-round4.md): the names and numbers the
## three round-4 agents build on (VrGrabbable, VrGrabRules, Vr.haptic's frequency). They never change after this commit.


func after_each() -> void:
	Vr.simulate(false)


func test_the_grab_rules_numbers_are_the_plans() -> void:
	assert_eq(VrGrabRules.NEAR_REACH, 0.12)
	assert_eq(VrGrabRules.FAR_RANGE, 4.0)
	assert_eq(VrGrabRules.PULL_HOLD, 0.6)
	assert_eq(VrGrabRules.THROW_WINDOW, 0.1)
	assert_eq(VrGrabRules.THROW_SCALE, 1.5)
	assert_eq(VrGrabRules.THROW_MAX, 12.0)
	assert_eq(VrGrabRules.BUBBLE, 0.5)


func test_a_throw_takes_the_fastest_moment_of_the_last_tenth_of_a_second_scaled_and_capped() -> void:
	assert_eq(VrGrabRules.throw_velocity([]), Vector3.ZERO, "no samples: it drops")
	var samples := [
		{"t": 0.00, "v": Vector3(0, 0, -9.0)},   # too long ago: not counted
		{"t": 0.25, "v": Vector3(0, 0, -2.0)},
		{"t": 0.30, "v": Vector3(0, 1, -3.0)},   # the peak in the window
		{"t": 0.35, "v": Vector3(0, 0, -1.0)},
	]
	var v := VrGrabRules.throw_velocity(samples)
	assert_almost_eq(v.length(), Vector3(0, 1, -3.0).length() * VrGrabRules.THROW_SCALE, 0.001)
	assert_almost_eq(v.normalized().dot(Vector3(0, 1, -3.0).normalized()), 1.0, 0.001, "its direction")
	var hard := VrGrabRules.throw_velocity([{"t": 1.0, "v": Vector3(30, 0, 0)}])
	assert_almost_eq(hard.length(), VrGrabRules.THROW_MAX, 0.001, "never faster than THROW_MAX")


func test_a_grabbable_is_a_component_with_the_frozen_names() -> void:
	var g := VrGrabbable.new()
	add_child_autofree(g)
	assert_eq(g.kind, &"hold")
	assert_true(g.throwable)
	assert_true(g.far_pull)
	assert_eq(g.hold_offset, Transform3D.IDENTITY)
	assert_eq(g.held_by(), &"", "nobody holds it")
	for s in ["hovered", "grabbed", "released", "used"]:
		assert_true(g.has_signal(s), s)


func test_a_buzz_can_name_its_frequency_and_off_vr_nothing_happens() -> void:
	var before: int = Vr.haptics
	Vr.haptic(&"right", 0.5, 0.1, 160.0)
	assert_eq(Vr.haptics, before, "off VR: no rig, no buzz")
	Vr.simulate(true)
	Vr.haptic(&"right", 0.5, 0.1, 160.0)
	Vr.haptic(&"left", 0.3, 0.05)
	assert_eq(Vr.haptics, before + 2, "in VR both forms buzz (the old one unchanged)")
