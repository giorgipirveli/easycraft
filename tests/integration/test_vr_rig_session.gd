extends GutTest
## Owner #101 (VR on the Meta Quest), the VR-RIG body of Vr with fake trackers (Vr.simulate: a head and two hands on the
## XRServer, no headset): the rig is made at the start and freed at the end, the head is the view while it runs and the
## camera before it comes back after; the hands' rays come from their aim poses; the origin puts the tracked head at the
## anchor's eye ("game height": whatever the child's real height), turns only round the head, keeps following in a
## paused game, and every jump in place is black (the fades, the safety net's blink).

var _anchor: Node3D
var _cam: Camera3D


func before_each() -> void:
	_cam = Camera3D.new()
	add_child_autofree(_cam)
	_cam.make_current()
	_anchor = Node3D.new()
	add_child_autofree(_anchor)
	_anchor.global_position = Vector3(10, 20, 30)


func after_each() -> void:
	get_tree().paused = false
	Vr.simulate(false)
	Vr.anchor(null)
	Profile.data.settings.erase("left_handed")
	Profile.data.settings.erase(VrRules.HEIGHT)


func _settle() -> void:
	Vr.step_physics()
	Vr.step_physics()
	Vr.step(1.0 / 72.0)


func test_a_session_makes_the_rig_and_gives_the_view_back_after() -> void:
	Vr.simulate(true)
	assert_not_null(Vr.rig, "the rig")
	assert_true(Vr.rig.is_inside_tree())
	assert_true(Vr.camera is XRCamera3D, "the head is an XRCamera3D")
	assert_eq(get_viewport().get_camera_3d(), Vr.camera, "the head is the view")
	assert_eq(Vr.rig.hands.size(), 2, "two hands")
	assert_true(Vr.input is VrInput)
	assert_true(Vr.hand is VrHand)
	Vr.simulate(false)
	assert_null(Vr.rig)
	assert_null(Vr.camera)
	assert_eq(get_viewport().get_camera_3d(), _cam, "the camera from before the session is the view again")


func test_the_head_stays_the_view_whatever_camera_asks_for_it() -> void:
	Vr.simulate(true)
	_cam.make_current()   # a menu's, a photo's or a rocket's camera
	Vr.step(0.016)
	assert_eq(get_viewport().get_camera_3d(), Vr.camera, "in VR only the head is drawn")


func test_off_vr_there_is_nothing_and_the_fades_are_instant() -> void:
	assert_null(Vr.rig)
	assert_eq(Vr.pointer_ray(), [])
	assert_eq(Vr.fade_amount(), 0.0)
	var t := Time.get_ticks_msec()
	await Vr.fade_out()
	await Vr.fade_in()
	assert_lt(Time.get_ticks_msec() - t, 100, "instant off VR")
	assert_eq(get_viewport().get_camera_3d(), _cam, "nothing changed the view")


func test_a_hands_ray_comes_from_its_aim_pose_in_the_world() -> void:
	Vr.simulate(true)
	Vr.anchor(_anchor, &"menu")
	_settle()
	var aim := Transform3D(Basis(Vector3.UP, 0.5), Vector3(0.3, 1.1, -0.2))
	Vr.sim_hand(VrRules.RIGHT, aim)
	var ray := Vr.hand_ray(VrRules.RIGHT)
	var want := Vr.rig.global_transform * aim
	assert_almost_eq((ray[0] as Vector3).distance_to(want.origin), 0.0, 0.001, "where the controller is")
	assert_almost_eq((ray[1] as Vector3).distance_to(-want.basis.z), 0.0, 0.001, "where it points")
	var left := Vr.hand_ray(VrRules.LEFT)
	assert_ne(left[0], ray[0], "the other hand is its own")


func test_a_left_handed_child_points_with_the_left_hand() -> void:
	Vr.simulate(true)
	assert_eq(Vr.pointing_hand(), VrRules.RIGHT)
	Profile.data.settings["left_handed"] = true
	assert_eq(Vr.pointing_hand(), VrRules.LEFT)
	assert_eq(Vr.pointer_ray(), Vr.hand_ray(VrRules.LEFT))


func test_game_height_puts_the_eye_at_the_avatars_whatever_the_childs_height() -> void:
	Vr.simulate(true)
	for tracked_y: float in [1.1, 1.75]:   # a small child sitting, a tall one standing
		Vr.sim_head(Transform3D(Basis(), Vector3(0.4, tracked_y, -0.3)))
		Vr.anchor(_anchor, &"feet")
		_settle()
		var head := Vr.head_transform().origin
		assert_almost_eq(head.y, 20.0 + CameraRig.HEAD_HEIGHT, 0.001, "the eye at the avatar's height (%s m)" % tracked_y)
		assert_almost_eq(Vector2(head.x, head.z).distance_to(Vector2(10, 30)), 0.0, 0.001, "over the feet")


func test_real_height_puts_the_origin_on_the_feet() -> void:
	Profile.data.settings[VrRules.HEIGHT] = "real"
	Vr.simulate(true)
	Vr.sim_head(Transform3D(Basis(), Vector3(0.0, 1.3, 0.0)))
	Vr.anchor(_anchor, &"feet")
	_settle()
	assert_almost_eq(Vr.head_transform().origin.y, 21.3, 0.001, "the child's own eye height over the feet")


func test_the_origin_follows_its_anchor_between_the_ticks() -> void:
	Vr.simulate(true)
	Vr.anchor(_anchor, &"feet")
	_settle()
	var before := Vr.head_transform().origin
	_anchor.global_position += Vector3(0.1, 0, 0)   # a step of a walk (6 m/s at 60 ticks)
	Vr.step_physics()
	Vr.rig.follow(0.5, 0.0)
	assert_almost_eq(Vr.head_transform().origin.x - before.x, 0.05, 0.001, "half-way between the ticks")
	Vr.rig.follow(1.0, 0.0)
	assert_almost_eq(Vr.head_transform().origin.x - before.x, 0.1, 0.001)
	assert_eq(Vr.fade_amount(), 0.0, "a walk is no jump")


func test_a_turn_turns_on_the_spot_round_the_head() -> void:
	Vr.simulate(true)
	Vr.sim_head(Transform3D(Basis(), Vector3(0.3, 1.5, -0.4)))
	Vr.anchor(_anchor, &"feet")
	_settle()
	var head := Vr.head_transform()
	Vr.turn(deg_to_rad(45.0))
	var after := Vr.head_transform()
	assert_almost_eq(after.origin.distance_to(head.origin), 0.0, 0.001, "never a slide sideways")
	assert_almost_eq(angle_difference(VrRules.yaw_of(head.basis), VrRules.yaw_of(after.basis)), deg_to_rad(45.0), 0.001)
	_settle()
	assert_almost_eq(Vr.head_transform().origin.distance_to(head.origin), 0.0, 0.001, "and it stays turned there")


func test_face_turns_the_head_to_a_yaw() -> void:
	Vr.simulate(true)
	Vr.anchor(_anchor, &"feet")
	_settle()
	Vr.face(1.2)
	assert_almost_eq(VrRules.yaw_of(Vr.head_transform().basis), 1.2, 0.001)


func test_a_menu_spot_faces_its_way() -> void:
	_anchor.rotation.y = -0.8
	Vr.simulate(true)
	Vr.anchor(_anchor, &"menu")
	_settle()
	assert_almost_eq(VrRules.yaw_of(Vr.head_transform().basis), -0.8, 0.001)
	assert_almost_eq(Vr.head_transform().origin.distance_to(_anchor.global_position), 0.0, 0.001, "the eye at the spot")


func test_the_rig_keeps_following_in_a_paused_game() -> void:
	Vr.simulate(true)
	get_tree().paused = true   # the pause menu: a frozen head would stick the world to the face
	assert_true(Vr.rig.can_process(), "the rig")
	assert_true(Vr.input.can_process(), "the controllers")
	assert_true(Vr.can_process())


func test_a_fade_goes_black_and_back() -> void:
	Vr.simulate(true)
	Vr.fade_out(0.15)
	Vr.step(0.075)
	assert_almost_eq(Vr.fade_amount(), 0.5, 0.01, "half-way")
	Vr.step(0.1)
	assert_eq(Vr.fade_amount(), 1.0, "black")
	Vr.fade_in(0.25)
	Vr.step(0.25)
	assert_eq(Vr.fade_amount(), 0.0, "clear again")


func test_an_awaited_fade_ends_black() -> void:
	Vr.simulate(true)
	await Vr.fade_out(0.05)
	assert_eq(Vr.fade_amount(), 1.0)
	await Vr.fade_in(0.05)
	assert_eq(Vr.fade_amount(), 0.0)


func test_a_jump_in_place_blinks_and_is_never_glided_across() -> void:
	Vr.simulate(true)
	Vr.anchor(_anchor, &"feet")
	_settle()
	_anchor.global_position += Vector3(40, 0, 0)   # a portal, a rescue: nobody faded for it
	Vr.step_physics()
	assert_eq(Vr.fade_amount(), 1.0, "black at once")
	Vr.rig.follow(0.0, 0.0)
	assert_almost_eq(Vr.head_transform().origin.x, 50.0, 0.001, "already there: no glide across 40 m")
	Vr.step(VrRules.FADE_IN)
	assert_eq(Vr.fade_amount(), 0.0, "then the fade in")


func test_when_a_visits_player_goes_the_headset_is_back_at_the_one_before() -> void:
	Vr.simulate(true)
	Vr.anchor(_anchor, &"feet")
	_settle()
	var visit := Node3D.new()
	add_child(visit)
	visit.global_position = Vector3(-50, 5, 0)
	Vr.anchor(visit, &"feet")   # a friend's showcase: its own player
	_settle()
	assert_almost_eq(Vr.head_transform().origin.x, -50.0, 0.01)
	visit.free()   # the visit ends
	_settle()
	assert_eq(Vr.anchor_node(), _anchor, "the world's own player again")
	assert_almost_eq(Vr.head_transform().origin.x, 10.0, 0.01)
	assert_gt(Vr.fade_amount(), 0.0, "behind a blink")


## VR-UI's find (the lead, 2026-10-15): during a scene change the menu's anchor was out of the tree but not freed yet,
## and reading its place errored. The rig never reads an anchor out of the tree: it holds still, and follows again when
## the node is back.
func test_an_anchor_out_of_the_tree_but_not_freed_is_never_read() -> void:
	Vr.simulate(true)
	Vr.anchor(_anchor, &"menu")
	_settle()
	var held := Vr.head_transform().origin
	remove_child(_anchor)   # a scene change's frame: out of the tree, still a valid object
	Vr.step_physics()
	Vr.step(1.0 / 72.0)
	Vr.follow_now()
	Vr.snap_origin()
	Vr.blink()
	assert_almost_eq(Vr.head_transform().origin.distance_to(held), 0.0, 0.001, "the origin holds where it was")
	add_child(_anchor)
	_anchor.global_position = Vector3(10, 20, 30)
	_settle()
	assert_almost_eq(Vr.head_transform().origin.distance_to(Vector3(10, 20, 30)), 0.0, 0.001, "back in the tree: followed")


func test_feels_tint_is_capped_for_a_headset() -> void:
	Vr.simulate(true)
	Vr.tint(Color(1, 0, 0, 0.9))
	assert_almost_eq(Vr.rig.comfort.tint.a, VrRules.TINT_MAX, 0.0001)
	assert_true(Vr.rig.comfort.visible, "the sphere shows while tinted")
	Vr.tint(Color(1, 0, 0, 0.0))
	Vr.step(0.016)
	assert_false(Vr.rig.comfort.visible, "and hides when all is clear (no full-view blend for nothing)")


func test_a_simulated_session_leaves_the_graphics_alone() -> void:
	Vr.simulate(true)
	assert_false(GraphicsPreset.vr_session, "tests' sessions never change the presets")
