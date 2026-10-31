extends GutTest
## Owner #101 (VR on the Meta Quest), the VR-RIG side's pure rules (VrRules): the snap turn and the smooth turn, the
## comfort vignette, the head in a wall, the auto-step's head spring, the fades' steps, turning the origin round the
## head (never round the feet: the child would slide sideways), and the head's yaw and pitch.


func test_a_snap_turn_turns_once_per_push_and_again_only_after_the_stick_rests() -> void:
	var s := VrRules.snap_step(0.9, true, 45.0)
	assert_almost_eq(s.turn, -deg_to_rad(45.0), 0.0001, "pushed right: one step clockwise (a negative yaw)")
	assert_false(s.armed, "it waits for the stick to come back")
	s = VrRules.snap_step(0.95, s.armed, 45.0)
	assert_eq(s.turn, 0.0, "held: no second step")
	s = VrRules.snap_step(0.5, s.armed, 45.0)
	assert_false(s.armed, "half-way back is not a rest yet")
	s = VrRules.snap_step(0.1, s.armed, 45.0)
	assert_true(s.armed, "back in the middle: armed again")
	s = VrRules.snap_step(-0.8, s.armed, 30.0)
	assert_almost_eq(s.turn, deg_to_rad(30.0), 0.0001, "pushed left: anticlockwise, by the setting's 30")


func test_smooth_turning_is_opt_in_and_never_moves_inside_the_dead_middle() -> void:
	assert_eq(VrRules.smooth_turn(0.1, 0.1), 0.0, "a resting stick is often a little off")
	assert_almost_eq(VrRules.smooth_turn(1.0, 0.5), -deg_to_rad(VrRules.SMOOTH_TURN_DEGREES) * 0.5, 0.0001)
	assert_lt(VrRules.smooth_turn(-0.5, 0.1), deg_to_rad(VrRules.SMOOTH_TURN_DEGREES) * 0.1, "half a tilt turns slower")


func test_the_vignette_grows_with_speed_and_follows_the_setting() -> void:
	assert_eq(VrRules.vignette("light", 0.0, false), 0.0, "standing still: no vignette")
	assert_eq(VrRules.vignette("off", 6.0, true), 0.0, "off is off")
	var light := VrRules.vignette("light", VrRules.VIGNETTE_SPEED_FULL, false)
	var strong := VrRules.vignette("strong", VrRules.VIGNETTE_SPEED_FULL, false)
	assert_gt(light, 0.0)
	assert_gt(strong, light, "strong darkens more")
	assert_lt(VrRules.vignette("light", 2.0, false), light, "slower: less")
	assert_eq(VrRules.vignette("light", 0.0, true), light, "a smooth turn is full vignette at once")
	assert_eq(VrRules.vignette("nonsense", 6.0, false), light, "an unknown setting reads the default")


func test_the_view_fades_when_the_head_goes_into_a_wall() -> void:
	assert_eq(VrRules.head_fade(0.0, false), 0.0, "head over the body: clear")
	assert_eq(VrRules.head_fade(VrRules.HEAD_FADE_FROM, false), 0.0, "leaning a little: clear")
	assert_almost_eq(VrRules.head_fade((VrRules.HEAD_FADE_FROM + VrRules.HEAD_FADE_FULL) * 0.5, false), 0.5, 0.01)
	assert_eq(VrRules.head_fade(VrRules.HEAD_FADE_FULL + 1.0, false), 1.0, "far into it: black")
	assert_eq(VrRules.head_fade(0.0, true), 1.0, "inside a solid block: black (no x-ray through hills or hiding spots)")


func test_turning_the_origin_round_the_head_keeps_the_head_where_it_is() -> void:
	var origin := Transform3D(Basis(Vector3.UP, 0.3), Vector3(5, 10, -2))
	var head_local := Vector3(0.4, 1.5, -0.6)
	var head_before := origin * head_local
	var turned := VrRules.turn_about(origin, head_before, deg_to_rad(45.0))
	var head_after := turned * head_local
	assert_almost_eq(head_after.distance_to(head_before), 0.0, 0.0001, "the child turns on the spot")
	assert_almost_eq(VrRules.yaw_of(turned.basis), 0.3 + deg_to_rad(45.0), 0.0001)
	assert_almost_eq(turned.origin.y, 10.0, 0.0001, "never up or down")


func test_the_heads_yaw_and_pitch_are_the_camera_rigs() -> void:
	var b := Basis.from_euler(Vector3(-0.4, 1.1, 0.0))
	assert_almost_eq(VrRules.yaw_of(b), 1.1, 0.0001, "the same yaw CameraRig.forward_flat uses")
	assert_almost_eq(VrRules.pitch_of(b), -0.4, 0.0001)
	var rolled := Basis.from_euler(Vector3(0.2, -0.7, 0.3))
	assert_almost_eq(VrRules.yaw_of(rolled), -0.7, 0.05, "a tilted head keeps its yaw")
	assert_almost_eq(VrRules.yaw_of(Basis.from_euler(Vector3(-1.5, 0.9, 0.0))), 0.9, 0.0001, "looking almost straight down")


func test_the_auto_steps_hop_is_eased_for_the_head_but_falls_and_big_jumps_are_not() -> void:
	var y := VrRules.step_ease(10.0, 11.0, 1.0 / 72.0)
	assert_gt(y, 10.0)
	assert_lt(y, 11.0, "a step up is eased (the hop's 7.6 m/s would jerk the head)")
	assert_eq(VrRules.step_ease(10.0, 9.0, 1.0 / 72.0), 9.0, "down: at once (a lagging head would sink into the ground)")
	assert_eq(VrRules.step_ease(10.0, 20.0, 1.0 / 72.0), 20.0, "a big jump in place snaps (behind a fade)")
	assert_eq(VrRules.step_ease(NAN, 4.0, 0.01), 4.0, "nothing yet: the target")


func test_a_fade_steps_towards_its_target_at_its_speed() -> void:
	assert_almost_eq(VrRules.fade_step(0.0, 1.0, 0.2, 0.1), 0.5, 0.0001)
	assert_eq(VrRules.fade_step(0.9, 1.0, 0.2, 0.1), 1.0, "never past the target")
	assert_eq(VrRules.fade_step(1.0, 0.0, 0.0, 0.01), 0.0, "no time: at once")
	assert_almost_eq(VrRules.fade_step(1.0, 0.0, 0.25, 0.05), 0.8, 0.0001)


func test_a_big_change_of_eye_height_happens_behind_a_fade() -> void:
	assert_false(VrRules.needs_height_fade(1.55, 1.40), "a few centimetres: smooth")
	assert_true(VrRules.needs_height_fade(1.55, 0.9), "a crouch's half metre: a fade")
	assert_true(VrRules.needs_height_fade(1.55, 4.65), "a giant")


func test_walking_goes_where_the_head_or_the_hand_looks() -> void:
	assert_eq(VrRules.walk_yaw("head", 0.5, 2.0), 0.5)
	assert_eq(VrRules.walk_yaw("hand", 0.5, 2.0), 2.0)
	assert_eq(VrRules.walk_yaw("odd", 0.5, 2.0), 0.5, "the default: the head")


func test_a_trigger_squeezes_past_on_and_lets_go_under_off() -> void:
	assert_true(VrRules.trigger_down(0.7, false))
	assert_false(VrRules.trigger_down(0.5, false), "not far enough")
	assert_true(VrRules.trigger_down(0.5, true), "held: stays down until it is let go")
	assert_false(VrRules.trigger_down(0.2, true))
