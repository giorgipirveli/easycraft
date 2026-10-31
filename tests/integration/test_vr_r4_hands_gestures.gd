extends GutTest
## Owner #110, VR round 4 idea 3 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md) with fake hands (Vr.simulate) on a real
## Player: a wave makes a buddy wave back and hold up a paw; slapping the paw is a high-five (a clap, both controllers
## buzz); a VR friend's drawn hand met fast is a high-five too, counted on this child's pose, and the friend's own count
## claps here; the personal bubble (R8) shrinks a friend's hand and hides a body inside 0.5 m of the head; buddies' eyes
## look at the child; nothing off VR.

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


const DT := 1.0 / 72.0

var p: Player
var buddy: Buddy
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
	p.set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 80, 0.5)
	buddy = Buddy.new()
	buddy.setup({"flat": Buddy.pack({Vector3i.ZERO: BlockIds.STONE}), "name": "Bo", "owner": 1,
		"pos": Vector3(0.5, 80, -1.5), "yaw": PI, "id": "BuddyVr"})   # facing the child
	add_child_autofree(buddy)
	buddy.set_physics_process(false)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame() -> void:
	Vr.step_physics()
	Vr.step(DT)
	Input.flush_buffered_events()
	p.rig._process(DT)
	p._process(DT)


func _hand_world(world_at: Vector3, side: StringName = VrRules.RIGHT) -> void:
	Vr.sim_hand(side, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * world_at))
	_frame()


## The right hand raised by the head, waving side to side for `seconds`.
func _wave(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.3 + 0.12 * sin(TAU * t / 0.5), 1.65, -0.25)))
		_frame()
		t += DT


func test_a_wave_makes_a_buddy_near_wave_back_and_hold_up_a_paw() -> void:
	_wave(1.2)
	assert_gte(Vr.gestures.waves, 1, "the wave heard")
	assert_gte(Vr.gestures.answered, 1, "the buddy waved back")
	assert_true(Vr.gestures.paw.visible, "a paw held up to slap")
	assert_lt(Vr.gestures.paw.global_position.distance_to(buddy.global_position), 1.5, "at the buddy")


func test_slapping_the_paw_is_a_high_five_with_a_clap_and_both_hands_buzzing() -> void:
	_wave(1.2)
	var at := Vr.gestures.paw.global_position
	_hand_world(at + Vector3(0.0, 0.0, 0.35))
	var buzzes := Vr.haptics
	_hand_world(at + Vector3(0.0, 0.0, 0.03))   # 32 cm in a frame: a slap
	assert_eq(Vr.gestures.clapped, 1, "a clap")
	assert_gte(Vr.haptics, buzzes + 2, "both controllers buzz")
	assert_false(Vr.gestures.paw.visible, "the paw was slapped")


func test_a_still_hand_is_no_wave() -> void:
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.3, 1.65, -0.25)))
	for i in 90:
		_frame()
	assert_eq(Vr.gestures.waves, 0)
	assert_false(Vr.gestures.paw.visible)


func _friend() -> Player:
	var other: Player = load("res://entities/player/player.tscn").instantiate()
	other.name = "7"
	add_child_autofree(other)
	other.set_physics_process(false)
	other.global_position = Vector3(0.5, 80, -0.8)
	other.avatar.rotation.y = PI   # facing this child
	return other


## The friend's right hand held out at `world_at`, as its pose says.
func _friend_hand(other: Player, world_at: Vector3, claps: int = 0) -> void:
	var body := Transform3D(Basis(Vector3.UP, other.avatar.rotation.y), other.global_position)
	var head := Transform3D(Basis(), Vector3(0, CameraRig.HEAD_HEIGHT, 0))
	var pose := VrPoseRules.encode(head, Transform3D(Basis(), Vector3(-0.3, 1.0, -0.2)), Transform3D(Basis(),
		body.affine_inverse() * world_at), Vector4(0, 0, 0.0, 0.0), CameraRig.HEAD_HEIGHT, 1.0)
	other.vr_pose = VrGestureRules.with_claps(pose, claps)
	other._process(DT)
	var vb := other.vr_body()
	if vb:
		vb.step(0.0)


func test_meeting_a_vr_friends_hand_fast_is_a_high_five_counted_on_the_pose() -> void:
	var other := _friend()
	var at := Vr.head_transform().origin + Vector3(0.1, -0.2, -0.65)
	_friend_hand(other, at)
	assert_true((other.vr_body().hands[VrRules.RIGHT] as VrHandModel).visible, "the friend's hand at arm's length")
	_hand_world(at + Vector3(0.0, 0.0, 0.3))
	_hand_world(at + Vector3(0.0, 0.0, 0.02))
	assert_eq(Vr.gestures.claps, 1, "a high-five")
	assert_eq(VrGestureRules.claps_of(Vr.pose_bytes(p)), 1, "sent on this child's pose")


func test_a_friends_high_five_heard_on_its_pose_claps_here_once() -> void:
	var other := _friend()
	var at := Vr.head_transform().origin + Vector3(0.1, -0.2, -0.65)
	_friend_hand(other, at, 0)
	_frame()
	_friend_hand(other, at, 1)
	_frame()
	assert_eq(Vr.gestures.clapped, 1, "their game's clap claps here")
	_frame()
	assert_eq(Vr.gestures.clapped, 1, "once")


func test_the_personal_bubble_shrinks_a_friends_hand_and_hides_a_body_in_the_childs_face() -> void:
	var other := _friend()
	var head := Vr.head_transform().origin
	_friend_hand(other, head + Vector3(0.0, 0.0, -0.3))
	assert_false((other.vr_body().hands[VrRules.RIGHT] as VrHandModel).visible, "30 cm from the face: gone")
	_friend_hand(other, head + Vector3(0.0, 0.0, -1.0))
	assert_true((other.vr_body().hands[VrRules.RIGHT] as VrHandModel).visible, "a metre away: there")
	assert_false(other.vr_bubbled())
	other.global_position = p.global_position + Vector3(0.0, 0.0, -0.2)
	other._process(DT)
	assert_true(other.vr_bubbled(), "its head in the child's bubble")
	assert_false(other.avatar.visible, "not drawn in the child's face")
	Vr.simulate(false)
	other._process(DT)
	assert_true(other.avatar.visible, "off VR: as before")


func test_a_buddys_eyes_look_at_the_child() -> void:
	_frame()
	buddy._process(DT)
	assert_true(buddy.look_target.is_finite(), "within 8 m: it looks")
	var pupil := buddy._pupils[0]
	var white := pupil.get_parent() as Node3D
	var to_eye := white.to_local(Vr.head_transform().origin).normalized()
	assert_gt(pupil.position.normalized().dot(to_eye), 0.8, "the pupil towards the child's eyes")
	buddy.global_position = Vector3(0.5, 80, -30)
	_frame()
	assert_false(buddy.look_target.is_finite(), "far: googly again")


func test_off_vr_nothing_waves_or_looks() -> void:
	Vr.simulate(false)
	assert_null(Vr.gestures)
	buddy._process(DT)
	assert_false(buddy.look_target.is_finite())
