extends GutTest
## Owner #110, VR round 4 idea 3 (VR-HANDS; the research §5.3 "Wave and high-five"): VrGestureRules. A wave is two
## turns of a raised hand within 1.2 s; a high-five is two hands meeting while closing faster than 1 m/s; the personal
## bubble shrinks other players' hands to nothing inside 0.5 m of the head (R8); a buddy's pupils look at the child; a
## clap rides on the VR pose's spare byte (old builds read the 21 bytes they know).


## Feeds a sideways sweep: x positions at 1/30 s apart.
func _sweep(state: Dictionary, t0: float, xs: Array, high: bool = true) -> Array:
	var out := []
	for i in xs.size():
		out.append(VrGestureRules.wave_step(state, t0 + i / 30.0, float(xs[i]), high))
	return out


func test_two_turns_of_a_raised_hand_are_a_wave() -> void:
	var s := {}
	var heard := _sweep(s, 0.0, [0.0, 0.05, 0.1, 0.15, 0.1, 0.05, 0.0, -0.05, -0.02, 0.03, 0.08])
	assert_true(heard.has(true), "right, left, right: a wave")
	assert_eq(heard.count(true), 1, "heard once")


func test_a_slow_or_small_or_low_sway_is_no_wave() -> void:
	var small := {}
	assert_false(_sweep(small, 0.0, [0.0, 0.02, 0.03, 0.02, 0.0, 0.02, 0.03]).has(true), "too small")
	var low := {}
	assert_false(_sweep(low, 0.0, [0.0, 0.05, 0.1, 0.15, 0.1, 0.05, 0.0, -0.05, -0.02, 0.03, 0.08], false).has(true),
		"a hand by the hip")
	var slow := {}
	var heard := []
	for i in 80:   # one sweep every two seconds: turns too far apart
		heard.append(VrGestureRules.wave_step(slow, i * 0.1, 0.15 * sin(i * 0.1 * PI * 0.5), true))
	assert_false(heard.has(true), "turns more than WAVE_WINDOW apart")


func test_hands_that_meet_fast_are_a_high_five() -> void:
	assert_true(VrGestureRules.meets(Vector3(0, 0, 0), Vector3(0, 0, -1.5), Vector3(0, 0, -0.1), Vector3.ZERO))
	assert_false(VrGestureRules.meets(Vector3(0, 0, 0), Vector3(0, 0, -0.4), Vector3(0, 0, -0.1), Vector3.ZERO),
		"a slow touch")
	assert_false(VrGestureRules.meets(Vector3(0, 0, 0), Vector3(0, 0, -2.0), Vector3(0, 0, -0.5), Vector3.ZERO),
		"not touching yet")
	assert_false(VrGestureRules.meets(Vector3(0, 0, 0), Vector3(0, 0, 2.0), Vector3(0, 0, -0.1), Vector3.ZERO),
		"moving apart")
	assert_true(VrGestureRules.meets(Vector3(0, 0, 0), Vector3(0, 0, -0.6), Vector3(0, 0, -0.1), Vector3(0, 0, 0.6)),
		"both moving: their closing speed")


func test_the_personal_bubble_shrinks_other_hands_to_nothing_inside_half_a_metre() -> void:
	assert_eq(VrGestureRules.bubble_scale(0.3), 0.0, "inside the bubble: gone")
	assert_eq(VrGestureRules.bubble_scale(VrGrabRules.BUBBLE), 0.0)
	assert_eq(VrGestureRules.bubble_scale(VrGrabRules.BUBBLE + VrGestureRules.BUBBLE_FADE + 0.01), 1.0, "outside: whole")
	var mid := VrGestureRules.bubble_scale(VrGrabRules.BUBBLE + VrGestureRules.BUBBLE_FADE * 0.5)
	assert_almost_eq(mid, 0.5, 0.01, "it shrinks on the way in")


func test_a_pupil_looks_towards_the_target_and_never_into_the_head() -> void:
	var r := 0.2
	var p := VrGestureRules.pupil_position(Vector3(1, 0, -1), r)
	assert_gt(p.x, 0.0, "to the right")
	assert_lt(p.z, 0.0, "on the eye's front")
	assert_almost_eq(p.length(), r * 0.62, 0.0001, "on the eyeball")
	var behind := VrGestureRules.pupil_position(Vector3(0, 0, 5), r)
	assert_lt(behind.z, 0.0, "a child behind: it still looks out of its face")


func test_the_clap_count_rides_on_the_poses_spare_byte() -> void:
	var pose := PackedByteArray()
	pose.resize(VrPoseRules.SIZE)
	pose[0] = VrPoseRules.VERSION
	assert_eq(VrGestureRules.claps_of(pose), 0, "none yet")
	assert_eq(VrGestureRules.with_claps(pose, 0).size(), VrPoseRules.SIZE, "no clap: the 21 bytes as before")
	var clapped := VrGestureRules.with_claps(pose, 3)
	assert_eq(clapped.size(), VrPoseRules.SIZE + 1)
	assert_eq(VrGestureRules.claps_of(clapped), 3)
	assert_false(VrPoseRules.decode(clapped, 1.5, 1.0).is_empty(), "an older build reads the pose it knows")
	assert_eq(VrGestureRules.claps_of(VrGestureRules.with_claps(pose, 257)), 1, "a byte: it wraps")
	assert_eq(VrGestureRules.claps_of(PackedByteArray()), 0)
