extends GutTest
## Owner #101 (VR on the Meta Quest), P3 on a real Player in a stub world (stone under y 80) with Vr.simulate's fakes:
## the teleport (the turning stick up aims the arc, let go and the child is there behind a blink; never while asleep),
## the vignette stronger for motion the child did not make, a knock-out's dim, sleep's slow fade with the origin held
## while the body goes onto the bed, Size Magic as the play space's scale, a hiding spot's eye inside it, a guest's mount
## followed smoothly, and a seat carrying the child's whole frame.

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
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame() -> void:
	Vr.step_physics()
	Vr.step_physics()
	Vr.step(1.0 / 72.0)
	p.rig._process(1.0 / 72.0)


func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await get_tree().process_frame
	return bool(cond.call())


func test_the_turning_stick_up_aims_a_teleport_and_letting_go_goes_there() -> void:
	# the right hand points ahead and a little up: the arc lands on the ground a few metres ahead
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis.looking_at(Vector3(0, 0.35, -1), Vector3.UP), Vector3(0.2, 1.2, -0.2)))
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2(0, 1))
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(Vr.teleport.aiming, "the arc shows")
	assert_true(bool(Vr.teleport.aim.get("ok", false)), "a good spot: %s" % Vr.teleport.aim.get("why", "?"))
	var at: Vector3 = Vr.teleport.aim.at
	var yaw := VrRules.yaw_of(Vr.head_transform().basis)
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2.ZERO)
	assert_true(await _until(func() -> bool: return Vr.fade_amount() >= 1.0, 1.0), "black first")
	assert_true(await _until(func() -> bool: return p.global_position.distance_to(at) < 0.01, 1.0), "there")
	assert_true(await _until(func() -> bool: return Vr.fade_amount() <= 0.0, 1.0), "and the fade in")
	assert_eq(Vr.teleport.jumps, 1)
	assert_almost_eq(angle_difference(yaw, VrRules.yaw_of(Vr.head_transform().basis)), 0.0, 0.01, "no turn by it")


func test_the_turning_stick_pushed_up_never_snap_turns() -> void:
	var yaw := VrRules.yaw_of(Vr.head_transform().basis)
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2(0.6, 0.9))   # up and a little sideways
	await get_tree().process_frame
	await get_tree().process_frame
	assert_almost_eq(angle_difference(yaw, VrRules.yaw_of(Vr.head_transform().basis)), 0.0, 0.001)
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2.ZERO)


func test_no_teleport_asleep_riding_or_hidden_nor_when_switched_off() -> void:
	assert_true(p.vr_may_teleport())
	p.sleeping = true
	assert_false(p.vr_may_teleport(), "asleep")
	p.sleeping = false
	Profile.data.settings[VrRules.TELEPORT] = false
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2(0, 1))
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(Vr.teleport.aiming, "VR COMFORT's teleport off")
	Vr.sim_input(VrRules.RIGHT, &"primary", Vector2.ZERO)


func test_the_vignette_is_stronger_for_a_ride_than_for_walking_as_fast() -> void:
	Vr.rig.velocity = Vector3(3.5, 0, 0)
	for i in 30:
		Vr.step(1.0 / 72.0)
		Vr.rig.velocity = Vector3(3.5, 0, 0)
	var walking := Vr.vignette_amount()
	p.gadget_move = GadgetRules.Move.GLIDE
	assert_true(p.vr_passive_motion(), "gliding is motion the child did not make")
	for i in 30:
		Vr.step(1.0 / 72.0)
		Vr.rig.velocity = Vector3(3.5, 0, 0)
	assert_gt(walking, 0.0)
	assert_gt(Vr.vignette_amount(), walking)
	p.gadget_move = GadgetRules.Move.NONE


func test_a_knock_out_dims_the_view_and_waking_clears_it() -> void:
	p.set_knocked_out(true)
	assert_almost_eq(Vr.fade_amount(), VrRules.KNOCKOUT_DIM, 0.001, "40 % left to see")
	assert_almost_eq(Vr.head_transform().origin.y, 80.0 + CameraRig.HEAD_HEIGHT, 0.01, "the head is never laid down")
	p.set_knocked_out(false)
	assert_eq(Vr.fade_amount(), 0.0)


func test_sleep_fades_slowly_to_black_and_back_never_gliding_onto_the_bed() -> void:
	var stood := Vr.head_transform().origin
	var bed := Vector3i(2, 80, 0)
	p.set_sleeping(true, bed)
	assert_true(Vr.frozen(), "the origin holds while the view fades")
	_frame()
	assert_almost_eq(Vr.head_transform().origin.distance_to(stood), 0.0, 0.01, "no glide onto the bed")
	assert_true(await _until(func() -> bool: return Vr.fade_amount() >= 1.0 and not Vr.frozen(), 3.0), "black, then held")
	_frame()
	var lie := BedRules.lie_position(bed)
	assert_almost_eq(Vector2(Vr.head_transform().origin.x, Vr.head_transform().origin.z).distance_to(Vector2(lie.x, lie.z)),
		0.0, 0.05, "at the bed, behind the black")
	p.set_sleeping(false, bed)
	assert_true(await _until(func() -> bool: return Vr.fade_amount() <= 0.0, 3.0), "and the view back")
	var feet := p.global_position
	assert_almost_eq(Vector2(Vr.head_transform().origin.x, Vr.head_transform().origin.z).distance_to(Vector2(feet.x, feet.z)),
		0.0, 0.05, "over the woken body")


func test_size_magic_is_the_play_spaces_scale() -> void:
	p.set_size_mode(SizeMagic.Mode.GIANT)
	var s := SizeMagic.scale(SizeMagic.Mode.GIANT)
	assert_almost_eq(Vr.world_scale(), s, 0.001, "a giant: 1 real metre is %s game metres" % s)
	assert_almost_eq(XRServer.world_scale, s, 0.001)
	assert_eq(Vr.fade_amount(), 1.0, "behind a blink")
	_frame()
	assert_almost_eq(Vr.rig.head_local().origin.y, Vr.PREVIEW_EYE * s, 0.01, "the tracked head moves 3× as far")
	assert_almost_eq(Vr.head_transform().origin.y, p.global_position.y + CameraRig.HEAD_HEIGHT * s, 0.02,
		"the eye at the giant's height")
	p.set_size_mode(SizeMagic.Mode.NORMAL)
	_frame()
	assert_almost_eq(Vr.world_scale(), 1.0, 0.001)
	Vr.simulate(false)
	assert_eq(XRServer.world_scale, 1.0, "the end of the session puts it back")


func test_inside_a_hiding_spot_the_eye_looks_out_from_it() -> void:
	var cell := Vector3i(3, 80, 3)
	p.set_hidden(true, cell)
	_frame()
	var peek := Vector3(cell) + Vector3(0.5, Player.PEEK_HEIGHT, 0.5)
	assert_almost_eq(Vr.head_transform().origin.distance_to(peek), 0.0, 0.01, "inside the barrel, a little cockpit")
	assert_eq(Vr.rig.comfort.head_block, 0.0, "never black for being inside it")
	p.set_hidden(false, cell)
	_frame()
	assert_false(Vr.rig.eye_override.is_finite())


func test_a_guests_mount_is_followed_smoothly() -> void:
	Vr.rig.predict = true
	var dt := 1.0 / 60.0
	var x := 0.0
	var biggest := 0.0
	var last := Vr.rig.global_position.x
	for i in 120:   # 5 m/s, the place arriving in steps 10 times a second
		if i % 6 == 0:
			x = i * dt * 5.0
		Vr.rig.record(Vector3(x, 81.55, 0.5), dt)
		Vr.rig.follow(1.0, 0.0)
		if i > 60:
			biggest = maxf(biggest, Vr.rig.global_position.x - last)
		last = Vr.rig.global_position.x
	assert_lt(biggest, 6.0 * dt * 5.0 * 0.5, "no step as big as a sync's: it glides between them")
	Vr.rig.predict = false


func test_a_seat_carries_the_whole_frame_and_turns_happen_in_it() -> void:
	var seat := Node3D.new()
	add_child_autofree(seat)
	seat.global_transform = Transform3D(Basis(Vector3.UP, 0.6), Vector3(5, 100, 5))
	Vr.sit(seat)
	assert_true(Vr.seated())
	Vr.step(0.01)
	assert_almost_eq(Vr.head_transform().origin.distance_to(Vector3(5, 100, 5)), 0.0, 0.01, "the eye on the seat")
	assert_almost_eq(VrRules.yaw_of(Vr.head_transform().basis), 0.6, 0.01, "facing the seat's way")
	seat.global_transform = Transform3D(Basis(Vector3.RIGHT, 0.3) * Basis(Vector3.UP, 0.6), Vector3(5, 140, 5))
	Vr.follow_now()
	assert_almost_eq(Vr.head_transform().origin.distance_to(Vector3(5, 140, 5)), 0.0, 0.01, "carried up with it")
	var b := Vr.head_transform().basis
	assert_almost_eq(Quaternion(b).angle_to(Quaternion(seat.global_basis)), 0.0, 0.01, "its pitch too: the capsule's frame")
	Vr.turn(deg_to_rad(45.0))
	assert_almost_eq(Vr.head_transform().origin.distance_to(Vector3(5, 140, 5)), 0.0, 0.01, "a snap turn in the seat")
	Vr.release(seat)
	assert_false(Vr.seated())
	assert_eq(Vr.anchor_node(), p, "back at the player's feet")
	assert_gt(Vr.fade_amount(), 0.0, "behind a blink")
