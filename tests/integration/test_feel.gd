extends GutTest
## M2 Task 11 (spec §12.10) and the lead's child-psychology notes: the local camera shakes, the
## phone buzzes and the screen's edges flash when this device's player is hurt; the Vibration and
## Reduce motion settings are respected; never more than 3 flashes a second.

var _rig: CameraRig
var _saved := {}


func before_each() -> void:
	for key: String in ["vibration", "reduce_motion"]:
		_saved[key] = Profile.data.settings[key]
	Profile.data.settings.vibration = true
	Profile.data.settings.reduce_motion = false
	Feel.set_process(false)
	Feel.reset()
	_rig = _make_rig()


func after_each() -> void:
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]
	Feel.reset()
	Feel.set_process(true)


## A camera rig like the player's (CameraRig > SpringArm3D > Camera3D), current, following a target.
func _make_rig() -> CameraRig:
	var target := Node3D.new()
	add_child_autofree(target)
	var rig: CameraRig = load("res://entities/player/camera_rig.gd").new()
	rig.name = "CameraRig"
	var arm := SpringArm3D.new()
	arm.name = "SpringArm3D"
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	arm.add_child(cam)
	rig.add_child(arm)
	add_child_autofree(rig)
	rig.set_process(false)
	rig.set_target(target)
	cam.current = true
	return rig


func _run_rig(seconds: float, step: float = 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds - 0.00001:
		_rig._process(step)
		t += step


func test_camera_shake_wobbles_the_view_then_settles_back_to_zero() -> void:
	_rig.shake(0.2, 0.5)
	var moved := false
	for i in 20:
		_rig._process(1.0 / 60.0)
		moved = moved or absf(_rig.camera.h_offset) > 0.001 or absf(_rig.camera.v_offset) > 0.001
	assert_true(moved, "the view wobbles")
	_run_rig(0.5)
	assert_eq(_rig.shake_amplitude(), 0.0)
	assert_eq(_rig.camera.h_offset, 0.0)
	assert_eq(_rig.camera.v_offset, 0.0)


func test_a_small_shake_never_cuts_a_big_one_short() -> void:
	_rig.shake(0.3, 1.0)
	_run_rig(0.1)
	var big := _rig.shake_amplitude()
	_rig.shake(0.02, 0.1)
	assert_almost_eq(_rig.shake_amplitude(), big, 0.0001)
	_run_rig(0.2)
	assert_gt(_rig.shake_amplitude(), 0.0)


func test_feel_shake_moves_the_local_camera() -> void:
	Feel.shake(0.2, 0.5)
	assert_gt(_rig.shake_amplitude(), 0.0)


func test_vibration_off_means_no_shake() -> void:
	Profile.data.settings.vibration = false
	Feel.shake(0.2, 0.5)
	assert_eq(_rig.shake_amplitude(), 0.0)


func test_reduce_motion_means_no_shake_and_no_camera_bob() -> void:
	assert_true(Feel.motion_allowed())
	Profile.data.settings.reduce_motion = true
	assert_false(Feel.motion_allowed())
	Feel.shake(0.2, 0.5)
	assert_eq(_rig.shake_amplitude(), 0.0)


func test_the_local_player_being_hurt_shakes_and_flashes() -> void:
	Session.player_hurt.emit(multiplayer.get_unique_id(), 17, Vector3(3, 60, 3))
	assert_gt(_rig.shake_amplitude(), 0.0)
	assert_eq(Feel.flashes, 1)
	assert_gt(Feel.flash_alpha(), 0.0)


func test_a_knock_out_shakes_more_than_a_hit() -> void:
	Session.player_hurt.emit(multiplayer.get_unique_id(), 17, Vector3.ZERO)
	var hit := _rig.shake_amplitude()
	_run_rig(1.0)
	Feel.tick(1.0)
	Session.player_hurt.emit(multiplayer.get_unique_id(), 0, Vector3.ZERO)
	assert_gt(_rig.shake_amplitude(), hit)


func test_someone_else_being_hurt_is_not_felt_here() -> void:
	Session.player_hurt.emit(multiplayer.get_unique_id() + 41, 5, Vector3.ZERO)
	assert_eq(_rig.shake_amplitude(), 0.0)
	assert_eq(Feel.flashes, 0)


func test_heals_and_respawns_are_not_felt() -> void:
	Session.player_hurt.emit(multiplayer.get_unique_id(), 12, Vector3.ZERO)
	_run_rig(1.0)
	Feel.tick(1.0)
	Session.player_hurt.emit(multiplayer.get_unique_id(), 13, Vector3.INF)
	Session.player_hurt.emit(multiplayer.get_unique_id(), Health.MAX_HP, Vector3.INF)
	assert_eq(_rig.shake_amplitude(), 0.0)
	assert_eq(Feel.flashes, 1)


func test_never_more_than_three_flashes_a_second_however_fast_the_hits() -> void:
	var hp := Health.MAX_HP
	for i in 60:                       # a hit every frame for one second
		hp = maxi(hp - 1, 1)
		Session.player_hurt.emit(multiplayer.get_unique_id(), hp, Vector3.ZERO)
		Feel.tick(1.0 / 60.0)
	assert_between(Feel.flashes, 1, 3)


func test_a_flash_fades_away_and_hides_its_overlay() -> void:
	Feel.flash(0.3)
	assert_gt(Feel.flash_alpha(), 0.0)
	Feel.tick(1.0)
	assert_eq(Feel.flash_alpha(), 0.0)
	assert_false(Feel.flash_visible(), "no invisible full-screen overlay left drawing")


func test_reduce_motion_softens_flashes() -> void:
	Feel.flash(0.3)
	var full := Feel.flash_alpha()
	Feel.tick(1.0)
	Profile.data.settings.reduce_motion = true
	Feel.flash(0.3)
	assert_lt(Feel.flash_alpha(), full * 0.5)
	assert_gt(Feel.flash_alpha(), 0.0)


func test_the_flash_overlay_never_takes_touches() -> void:
	assert_eq(Feel.flash_overlay().mouse_filter, Control.MOUSE_FILTER_IGNORE)


## The Stone Golem's slam (Task 10) shakes hardest next to it and not at all far away.
func test_slam_shakes_by_distance() -> void:
	Feel.slam(2.0)
	var near := _rig.shake_amplitude()
	assert_gt(near, 0.0)
	_run_rig(2.0)
	Feel.slam(FeelRules.SLAM_REACH + 1.0)
	assert_eq(_rig.shake_amplitude(), 0.0)
	Feel.slam(FeelRules.SLAM_REACH * 0.75)
	assert_between(_rig.shake_amplitude(), 0.0001, near)
