extends GutTest
## The owner's Quest 3 session (2026-10-17 22:43-23:00): #126 "in the rocket i cannt see my hands": in space the
## flight's camera draws only its own layers and the head copies them (Vr.view_like), so the hands, on the world's
## layer, were gone; now the hands have a layer of their own the head always draws.
## #124 "weapon holding and targeting … not aiming corectly": a held item hung on the controller's GRIP pose (its -Z: the
## straightened index finger) while the laser and the shots used the AIM pose, at another angle on the Quest, and shots
## left the eye: now the item turns to the aim pose (the barrel and the blade point where the laser points), shots leave
## the weapon in the hand, and a drawn bow shoots straight along its arrow. The simulator gains a grip pose (it had only
## the aim pose: grip = aim, which hid it). #128: a held sword hits by swinging it. (#127, the HUD on a raised forearm,
## is tested below as it is built.)

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
	Session._last_attack.erase(p.peer_id)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func after_each() -> void:
	Vr.view_default()
	Vr.simulate(false)
	Vr.anchor(null)
	Session._last_attack.erase(multiplayer.get_unique_id())
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame(delta: float = 1.0 / 72.0) -> void:
	Vr.step_physics()
	Vr.step(delta)
	p.rig._process(delta)
	p._process(delta)


func _hand_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		for m in (Vr.hand_models[side] as Node).find_children("*", "MeshInstance3D", true, false):
			out.append(m as MeshInstance3D)
	return out


# --- #126: the hands in the rocket ---

func test_the_hands_show_in_space_where_the_flight_draws_only_its_own_layers() -> void:
	var flight_camera := Camera3D.new()
	flight_camera.cull_mask = RocketFlight.LAYER | RocketFlight.ROCKET_LAYER   # the flight in space
	add_child_autofree(flight_camera)
	Vr.view_like(flight_camera)
	_frame()
	assert_false(_hand_meshes().is_empty())
	for m in _hand_meshes():
		assert_ne(Vr.camera.cull_mask & m.layers, 0, "%s is drawn in space" % m.get_path())
	assert_eq(Vr.camera.cull_mask & 1, 0, "the world's own layer stays hidden in space")


func test_back_on_the_ground_the_head_draws_everything_again() -> void:
	var flight_camera := Camera3D.new()
	flight_camera.cull_mask = RocketFlight.LAYER
	add_child_autofree(flight_camera)
	Vr.view_like(flight_camera)
	Vr.view_default()
	for m in _hand_meshes():
		assert_ne(Vr.camera.cull_mask & m.layers, 0)
	assert_ne(Vr.camera.cull_mask & 1, 0)


# --- #128: "when i hold a sword and i am waving it should work without clicking … sword is not a pistol" ---

func _swing_once() -> void:
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.4, 1.3, -0.4)))
	_frame(0.02)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(-0.2, 1.1, -0.5)))   # 0.6 m in 0.02 s: a hard swing
	_frame(0.02)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(-0.2, 1.1, -0.5)))
	_frame(0.02)


func _hold(item: int) -> void:
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	interactor.hotbar[0] = item
	interactor.select_slot(0)


func test_a_held_sword_hits_by_swinging_it_with_no_button() -> void:
	Profile.data.settings.erase(VrRules.SWING)   # the default
	_hold(ItemIds.SWORD)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_swing_once()
	assert_eq(Vr.input.swings, 1, "the sword in the hand: a swing is a hit, no trigger")


func test_waving_empty_hands_hits_nothing() -> void:
	Profile.data.settings.erase(VrRules.SWING)
	_hold(BlockIds.DIRT)   # a block, not a weapon: waving to a friend never punches
	_swing_once()
	assert_eq(Vr.input.swings, 0)


func test_a_bow_or_a_wand_in_the_hand_is_not_swung() -> void:
	Profile.data.settings.erase(VrRules.SWING)
	_hold(ItemIds.BOW)
	_swing_once()
	assert_eq(Vr.input.swings, 0, "a bow is drawn, not swung")


func test_the_setting_still_turns_sword_swings_off() -> void:
	Profile.data.settings[VrRules.SWING] = false
	_hold(ItemIds.SWORD)
	_swing_once()
	assert_eq(Vr.input.swings, 0)


# --- #124: the held weapon points where the laser points; shots leave the weapon ---

## The Quest's two poses of one controller: the grip (the index finger's line) and the aim, tilted down from it.
const AIM_TILT := -0.75   # radians about the grip's x: about 43 degrees, near what the Quest 3 gives
const HAND_AT := Vector3(0.25, 1.3, -0.35)


func _quest_hand(side: StringName, at: Vector3 = HAND_AT, yaw: float = 0.0) -> Transform3D:
	var grip := Transform3D(Basis(Vector3.UP, yaw), at)
	Vr.sim_grip(side, grip)
	var aim := Transform3D(grip.basis * Basis(Vector3.RIGHT, AIM_TILT), at + grip.basis * Vector3(0, 0.01, -0.05))
	Vr.sim_hand(side, aim)
	return aim


func _angle(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(a.normalized().angle_to(b.normalized()))


func test_a_held_weapon_points_where_its_hands_laser_points() -> void:
	_quest_hand(VrRules.RIGHT)
	_hold(ItemIds.SWORD)
	p.held_item = ItemIds.SWORD
	_frame()
	_frame()
	var anchor := (Vr.hand_models[VrRules.RIGHT] as VrHandModel).item_anchor()
	var laser: Vector3 = Vr.hand_ray(VrRules.RIGHT)[1]
	assert_gt(_angle(-Vr.hand_grip(VrRules.RIGHT).basis.z, laser), 30.0, "the two poses really differ here")
	assert_lt(_angle(-anchor.global_transform.basis.z, laser), 2.0, "the blade along the laser, not the grip's line")
	_quest_hand(VrRules.RIGHT, HAND_AT, 1.0)   # the hand turned: the blade turns with it
	_frame()
	var laser2: Vector3 = Vr.hand_ray(VrRules.RIGHT)[1]
	assert_lt(_angle(-anchor.global_transform.basis.z, laser2), 2.0)


func test_a_blaster_shot_leaves_the_gun_in_the_hand_towards_the_lasers_point() -> void:
	_quest_hand(VrRules.RIGHT)
	_hold(ItemIds.FOAM_BLASTER)
	p.held_item = ItemIds.FOAM_BLASTER
	Game.mode = ModeRules.SANDBOX
	_frame()
	_frame()
	watch_signals(Session)
	var target := Vr.hand_grip(VrRules.RIGHT).origin + Vector3(0, 0, -6)
	var blasters := p.get_node("BlockInteractor").weapons.get_node("Blasters") as BlasterUser
	assert_true(blasters.fire(ItemIds.FOAM_BLASTER, target))
	var muzzle: Vector3 = Vr.muzzle(ItemIds.FOAM_BLASTER)
	assert_lt(muzzle.distance_to(Vr.hand_grip(VrRules.RIGHT).origin), 0.4, "the muzzle is on the hand")
	var from: Vector3 = Session.shot_origin(p)
	assert_almost_eq(from.distance_to(muzzle), 0.0, 0.01, "the host starts the shot at the gun, not the eye")
	var params: Variant = get_signal_parameters(Session, "blast_requested")
	assert_not_null(params)
	if params:
		assert_lt(_angle(params[2], target - muzzle), 1.0, "from the gun to where the laser points")


func test_the_host_never_starts_a_shot_far_from_the_player() -> void:
	Session._host_shot_origin(p.peer_id, p.eye_position() + Vector3(0, 0, -40))
	assert_eq(Session.shot_origin(p), p.eye_position(), "a hand is never 40 m away: the eye")
	assert_eq(Session.shot_origin(p), p.eye_position(), "nothing kept: the eye")


func test_a_drawn_bow_shoots_straight_along_the_arrow() -> void:
	_hold(ItemIds.BOW)
	watch_signals(Session)
	Vr.sim_hand(VrRules.LEFT, Transform3D(Basis(), Vector3(-0.05, 1.3, -0.55)))   # the bow hand ahead
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.0, 1.3, -0.45)))
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_frame()
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.0, 1.45, 0.1)))   # drawn back and a little up: aims down
	_frame()
	var bow := Vr.hand_grip(VrRules.LEFT).origin
	var string := Vr.hand_grip(VrRules.RIGHT).origin
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_frame()
	assert_eq(Vr.input.shots, 1)
	var params: Variant = get_signal_parameters(Session, "attack_requested")
	assert_not_null(params)
	if params:
		assert_lt(_angle(params[2], bow - string), 1.0, "along the arrow, not lobbed to a far point")
	assert_lt(Session.shot_origin(p).distance_to(bow), 0.3, "the arrow leaves the bow")
