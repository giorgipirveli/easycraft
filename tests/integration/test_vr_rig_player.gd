extends GutTest
## Owner #101 (VR on the Meta Quest), on a real Player in a stub world (stone under y 80) with Vr.simulate's fake head
## and hands: the aim seam (every world tap goes along Player.aim_ray: the camera's ray off VR, exactly as before; the
## pointing hand's laser in VR), the CameraRig's VR mode (first person, the head's yaw and pitch; no look, no CAM, no
## shake; a yaw the game writes turns the origin round the head), room scale (the body walks after a head that stepped,
## the view never moves; a head in a wall goes black), no knockback on a VR body, the spawn's black and its blink, the
## avatar facing the head, walking where the hand points, and Feel in VR (no shake, buzzes in the hands, a capped tint).

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 80


var p: Player
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	var w := FloorWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.visible = true
	p.global_position = Vector3(0.5, 80, 0.5)
	p.rig.snap_to_target()
	Feel.reset()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Profile.data.settings = _settings
	Feel.reset()


## The session, the player as the anchor (as its _ready does), one tick and one frame.
func _vr() -> void:
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func _frame() -> void:
	Vr.step_physics()
	Vr.step_physics()
	Vr.step(1.0 / 72.0)
	p.rig._process(1.0 / 72.0)


func test_the_local_player_is_the_headsets_anchor() -> void:
	assert_eq(Vr.anchor_node(), p, "a local player anchors the headset at its feet (off VR only remembered)")
	assert_eq(Vr.anchor_kind(), &"feet")


func test_off_vr_the_aim_is_the_cameras_ray_as_before() -> void:
	var center := get_viewport().get_visible_rect().size * 0.5
	var ray := p.aim_ray(center)
	assert_eq(ray[0], p.camera().project_ray_origin(center))
	assert_eq(ray[1], p.camera().project_ray_normal(center))


func test_in_vr_every_tap_aims_along_the_pointing_hand() -> void:
	_vr()
	# the right hand, a little in front of the chest, points down at the ground two blocks ahead
	var at := Vector3(0.2, 1.1, -0.3)
	var down_ahead := Basis.looking_at(Vector3(0, -1.0, -1.2), Vector3.UP)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(down_ahead, at))
	var ray := p.aim_ray(Vector2(5, 5))   # the screen point means nothing in VR
	var hand := Vr.pointer_ray()
	assert_eq(ray, hand)
	var hit := p.get_node("BlockInteractor").ray_at(Vector2.ZERO) as BlockHit
	assert_not_null(hit, "the laser finds the ground")
	assert_eq(hit.position.y, 79, "the top of the stone")
	assert_lt(hit.position.z, 0, "ahead, where the hand points (not where the head looks)")


func test_the_rig_follows_the_head_in_first_person() -> void:
	_vr()
	Vr.sim_head(Transform3D(Basis.from_euler(Vector3(-0.3, 0.7, 0.0)), Vector3(0, 1.4, 0)))
	_frame()
	assert_almost_eq(angle_difference(p.rig.yaw, VrRules.yaw_of(Vr.head_transform().basis)), 0.0, 0.001)
	assert_almost_eq(p.rig.pitch, -0.3, 0.001)
	assert_eq(p.rig.arm.spring_length, 0.0, "no spring arm")
	assert_almost_eq(p.camera().global_position.distance_to(Vr.head_transform().origin), 0.0, 0.01,
		"the player's camera stands where the head is (everything that asks it sees the head)")


func test_a_stick_a_finger_or_a_mouse_never_turns_the_view() -> void:
	_vr()
	var yaw := p.rig.yaw
	p.look_delta(Vector2(300, 0))
	p.rig.look(Vector2(0, 200), 1.0)
	_frame()
	assert_almost_eq(angle_difference(yaw, p.rig.yaw), 0.0, 0.001)
	var fp := p.rig.first_person
	p.toggle_camera()
	assert_eq(p.rig.first_person, fp, "no CAM in VR")
	p.rig.shake(0.3, 1.0)
	assert_eq(p.rig.shake_amplitude(), 0.0, "no shake")


func test_a_yaw_the_game_writes_turns_the_origin_round_the_head() -> void:
	_vr()
	var head := Vr.head_transform().origin
	p.rig.yaw = 2.0   # a portal's arrival, a world's saved facing
	_frame()
	assert_almost_eq(angle_difference(VrRules.yaw_of(Vr.head_transform().basis), 2.0), 0.0, 0.01, "the head looks that way")
	assert_almost_eq(p.rig.yaw, 2.0, 0.01)
	assert_almost_eq(Vr.head_transform().origin.distance_to(head), 0.0, 0.01, "turned on the spot")


func test_at_the_start_the_head_looks_where_the_player_looked() -> void:
	p.rig.yaw = -1.1
	_vr()
	assert_almost_eq(angle_difference(VrRules.yaw_of(Vr.head_transform().basis), -1.1), 0.0, 0.01)


func test_a_child_who_steps_in_the_room_walks_the_body_and_the_view_stays() -> void:
	_vr()
	var head := Vr.head_transform().origin
	var feet := p.global_position
	Vr.sim_head(Transform3D(Basis(), Vector3(0.5, 1.6, 0.0)))   # half a metre to the right, in the room
	var moved_head := Vr.rig.global_transform * Vector3(0.5, 1.6, 0.0)
	p._vr_room_scale()
	assert_almost_eq(Vector2(p.global_position.x, p.global_position.z).distance_to(
		Vector2(moved_head.x, moved_head.z)), 0.0, 0.02, "the body is under the head again")
	assert_gt(p.global_position.distance_to(feet), 0.4, "it walked")
	_frame()
	assert_almost_eq(Vr.head_transform().origin.distance_to(moved_head), 0.0, 0.02, "the view did not move")
	assert_eq(Vr.fade_amount(), 0.0, "no wall: clear")
	assert_ne(head, moved_head)


func test_a_head_inside_a_block_goes_black() -> void:
	_vr()
	Vr.sim_head(Transform3D(Basis(), Vector3(0.0, -0.3, 0.0)))   # ducking far below the eye: into the stone
	_frame()
	p._vr_room_scale()
	assert_eq(Vr.fade_amount(), 1.0, "no x-ray through the ground")
	Vr.sim_head(Transform3D(Basis(), Vector3(0.0, 1.6, 0.0)))
	_frame()
	p._vr_room_scale()
	assert_eq(Vr.fade_amount(), 0.0)


func test_no_knockback_on_a_vr_body() -> void:
	_vr()
	p.velocity = Vector3.ZERO
	p.knockback(Vector3(8, 4, 0))
	assert_eq(p.velocity, Vector3.ZERO, "the hit is a buzz and a tint, never a push of the view")
	Vr.simulate(false)
	p.knockback(Vector3(8, 4, 0))
	assert_eq(p.velocity, Vector3(8, 4, 0), "off VR: as before")


func test_a_spawn_is_black_until_the_body_stands_then_fades_in() -> void:
	_vr()
	p.spawn_at(Vector3(20.5, 80, 0.5))
	assert_eq(Vr.fade_amount(), 1.0, "black while the world loads")
	p.global_position = Vector3(20.5, 80, 0.5)
	p.rig.snap_to_target()   # _try_spawn's, once the ground is there
	Vr.step(VrRules.FADE_IN * 0.5)
	assert_gt(Vr.fade_amount(), 0.0)
	assert_lt(Vr.fade_amount(), 1.0, "fading in")
	Vr.step(VrRules.FADE_IN)
	assert_eq(Vr.fade_amount(), 0.0)


func test_friends_see_the_avatar_face_where_the_head_looks() -> void:
	_vr()
	p.rig.yaw = 1.0
	_frame()
	p._update_avatar(0.016, Vector3.ZERO)
	assert_almost_eq(p.avatar.rotation.y, p.rig.yaw, 0.001)


func test_walking_goes_where_the_walking_hand_points_when_asked() -> void:
	_vr()
	assert_almost_eq(p._walk_yaw(), p.rig.yaw, 0.0001, "the head by default")
	Profile.data.settings[VrRules.WALK_DIR] = "hand"
	Vr.sim_hand(VrRules.LEFT, Transform3D(Basis(Vector3.UP, 0.9), Vector3(-0.2, 1.1, -0.3)))
	assert_almost_eq(angle_difference(p._walk_yaw(), 0.9 + Vr.rig.yaw), 0.0, 0.001, "the left hand's way")


func test_feel_in_vr_buzzes_the_hands_and_tints_but_never_shakes() -> void:
	_vr()
	assert_false(Feel.motion_allowed(), "everything that moves the view takes its calm way")
	Feel.shake(0.3, 1.0)
	assert_eq(p.rig.shake_amplitude(), 0.0)
	var buzzes := Vr.haptics
	Feel.vibrate(120)
	assert_eq(Vr.haptics, buzzes + 2, "both controllers")
	Feel.flash(0.8)
	assert_gt(Vr.rig.comfort.tint.a, 0.0, "a red tint over the view")
	assert_lte(Vr.rig.comfort.tint.a, VrRules.TINT_MAX)
	assert_false(Feel.flash_visible(), "the phone's red edges stay hidden (no full-screen overlay for nothing)")


func test_feel_off_vr_is_as_before() -> void:
	assert_true(Feel.motion_allowed() == not bool(Profile.data.settings.get("reduce_motion", false)))
	var buzzes := Vr.haptics
	Feel.vibrate(120)
	assert_eq(Vr.haptics, buzzes, "no hands to buzz")
