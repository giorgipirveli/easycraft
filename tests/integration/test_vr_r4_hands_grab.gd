extends GutTest
## Owner #110, VR round 4 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md): the shared grab with fake hands (Vr.simulate)
## on a real Player: a near grab (the glow, the grip), the grip stepping the hotbar when nothing is near (R1), the far
## pull by a flick and by the 0.6 s hold (R4), a throw (R3) with a RigidBody3D, the two-hand stretch, the shoulder bag,
## the trigger used while holding (never the world's then), the hand's picture stopped at a block's face (R2), and
## nothing at all off VR.

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


## A thing with a bag of its own: over the shoulder it goes in.
class Bagged:
	extends Node3D
	var bagged := 0

	func vr_into_bag(_side: StringName) -> bool:
		bagged += 1
		return true


class Taps:
	extends RefCounted
	var placed := 0

	func place_crosshair() -> bool:
		placed += 1
		return true

	func break_crosshair() -> bool:
		return true

	func show_break_progress(_hit: Variant, _p: float) -> void:
		pass

	func ray_at(_pos: Vector2) -> BlockHit:
		return null


const DT := 1.0 / 72.0

var p: Player
var _settings := {}
var heard: Dictionary


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	heard = {"hovered": [], "grabbed": [], "released": [], "used": []}
	var w := FloorWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.get_node("BlockInteractor").set_process_unhandled_input(false)
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
	Input.flush_buffered_events()
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame(delta: float = DT) -> void:
	Vr.step_physics()
	Vr.step(delta)
	Input.flush_buffered_events()
	p.rig._process(delta)
	p._process(delta)


func _frames(seconds: float) -> void:
	for i in ceili(seconds / DT):
		_frame()


## A thing at `at` (world) with a grabbable of `kind`, its signals heard.
func _thing(at: Vector3, kind: StringName = &"hold", body: Node3D = null) -> VrGrabbable:
	var t := body if body != null else Node3D.new()
	add_child_autofree(t)
	t.global_position = at
	var g := VrGrabbable.new()
	g.kind = kind
	t.add_child(g)
	g.hovered.connect(func(side: StringName, on: bool) -> void: heard.hovered.append([side, on]))
	g.grabbed.connect(func(side: StringName) -> void: heard.grabbed.append(side))
	g.released.connect(func(side: StringName, v: Vector3) -> void: heard.released.append([side, v]))
	g.used.connect(func(side: StringName, amount: float) -> void: heard.used.append([side, amount]))
	return g


func _grip(side: StringName, value: float) -> void:
	Vr.sim_input(side, &"grip", value)
	_frame()


## The right hand in the play space at `at`, pointing along `dir`.
func _hand(at: Vector3, dir: Vector3 = Vector3.FORWARD, side: StringName = VrRules.RIGHT) -> void:
	Vr.sim_hand(side, Transform3D(Basis.looking_at(dir), at))


func _hand_world(side: StringName = VrRules.RIGHT) -> Vector3:
	return Vr.hand_grip(side).origin


func test_a_hand_near_a_thing_glows_it_and_the_grip_takes_it() -> void:
	var g := _thing(_hand_world() + Vector3(0.0, 0.0, -0.06))
	_frame()
	assert_true(heard.hovered.has([VrRules.RIGHT, true]), "the hand near it: it glows")
	assert_gt(Vr.haptics, 0, "a soft tick")
	_grip(VrRules.RIGHT, 1.0)
	assert_eq(heard.grabbed, [VrRules.RIGHT], "the grip took it")
	assert_eq(g.held_by(), VrRules.RIGHT)
	_hand(Vector3(0.3, 1.4, -0.35))
	_frame()
	assert_almost_eq(g.thing().global_position.distance_to(_hand_world()), 0.0, 0.01, "it moves with the hand")
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(g.held_by(), &"", "let go")
	assert_eq((heard.released[0] as Array)[0], VrRules.RIGHT)


func test_the_grip_steps_the_hotbar_when_nothing_is_near_r1() -> void:
	_grip(VrRules.RIGHT, 1.0)
	assert_true(Input.is_action_pressed(&"hotbar_next"), "nothing to take: the hotbar's slot after, as before")
	_grip(VrRules.RIGHT, 0.0)
	assert_false(Input.is_action_pressed(&"hotbar_next"))
	_thing(_hand_world() + Vector3(0.0, 0.0, -0.05))
	_frame()
	_grip(VrRules.RIGHT, 1.0)
	assert_false(Input.is_action_pressed(&"hotbar_next"), "something to take: the grip takes it instead")
	assert_eq(heard.grabbed, [VrRules.RIGHT])


func test_a_far_thing_under_the_laser_is_locked_by_the_grip_and_flies_in_on_a_flick_r4() -> void:
	var ray := Vr.hand_ray(VrRules.RIGHT)
	var g := _thing((ray[0] as Vector3) + (ray[1] as Vector3) * 2.5)
	_frame()
	assert_true(heard.hovered.has([VrRules.RIGHT, true]), "the laser on it: it glows")
	_grip(VrRules.RIGHT, 1.0)
	assert_eq(Vr.grabber.state(VrRules.RIGHT), VrGrabber.LOCK, "locked: moving the hand keeps it")
	assert_eq(heard.grabbed, [], "not in the hand yet")
	var where := g.thing().global_position
	_frame()
	assert_almost_eq(g.thing().global_position.distance_to(where), 0.0, 0.001, "it waits for the flick")
	_hand(Vector3(0.2, 1.25, -0.24))   # the wrist flicked back towards the head, 6 cm in a frame
	_frame()
	assert_eq(Vr.grabber.state(VrRules.RIGHT), VrGrabber.PULL, "the flick pulls it")
	_frames(VrGrabRules.PULL_TIME + 0.05)
	assert_eq(heard.grabbed, [VrRules.RIGHT], "it arrived in the hand")
	assert_almost_eq(g.thing().global_position.distance_to(_hand_world()), 0.0, 0.01)


func test_holding_the_grip_on_a_far_thing_pulls_it_in_for_a_child_who_cant_flick() -> void:
	var ray := Vr.hand_ray(VrRules.RIGHT)
	var g := _thing((ray[0] as Vector3) + (ray[1] as Vector3) * 3.0)
	_frame()
	_grip(VrRules.RIGHT, 1.0)
	_frames(VrGrabRules.PULL_HOLD - 0.1)
	assert_eq(Vr.grabber.state(VrRules.RIGHT), VrGrabber.LOCK, "not yet")
	_frames(0.15)
	assert_eq(Vr.grabber.state(VrRules.RIGHT), VrGrabber.PULL, "held 0.6 s: it comes")
	_frames(VrGrabRules.PULL_TIME + 0.05)
	assert_eq(g.held_by(), VrRules.RIGHT)


func test_letting_go_of_a_locked_thing_before_the_pull_leaves_it() -> void:
	var ray := Vr.hand_ray(VrRules.RIGHT)
	var g := _thing((ray[0] as Vector3) + (ray[1] as Vector3) * 2.0)
	_frame()
	_grip(VrRules.RIGHT, 1.0)
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(Vr.grabber.state(VrRules.RIGHT), VrGrabber.IDLE)
	assert_eq(g.held_by(), &"")
	assert_eq(heard.grabbed, [])


func test_a_flick_of_the_hand_throws_a_rigid_body_at_its_peak_speed_scaled_r3() -> void:
	var ball := RigidBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	(shape.shape as SphereShape3D).radius = 0.05
	ball.add_child(shape)
	ball.gravity_scale = 0.0
	var g := _thing(_hand_world() + Vector3(0.0, 0.0, -0.05), &"hold", ball)
	_frame()
	_grip(VrRules.RIGHT, 1.0)
	assert_true(ball.freeze, "kinematic while held")
	for i in 4:   # forward at 2 m/s
		_hand(Vector3(0.2, 1.2, -0.3 - 2.0 * DT * (i + 1)))
		_frame()
	_grip(VrRules.RIGHT, 0.0)
	assert_false(ball.freeze, "let go: physics again")
	var v: Vector3 = (heard.released[0] as Array)[1]
	assert_almost_eq(v.length(), 2.0 * VrGrabRules.THROW_SCALE, 0.25, "the hand's speed × THROW_SCALE")
	assert_gt(v.normalized().dot(Vr.rig.global_basis * Vector3.FORWARD), 0.9, "along the throw")
	assert_almost_eq(ball.linear_velocity.distance_to(v), 0.0, 0.001, "the body flies with it")
	assert_eq(g.held_by(), &"")


func test_two_hands_stretch_a_two_hand_thing() -> void:
	_hand(Vector3(-0.1, 1.2, -0.35), Vector3.FORWARD, VrRules.LEFT)
	_hand(Vector3(0.1, 1.2, -0.35))
	_frame()
	var mid := (_hand_world(VrRules.LEFT) + _hand_world()) * 0.5
	var g := _thing(mid, &"two_hand")
	g.radius = 0.1
	_frame()
	_grip(VrRules.LEFT, 1.0)
	_grip(VrRules.RIGHT, 1.0)
	assert_eq(g.held_by(), &"both", "both hands on it")
	_hand(Vector3(-0.2, 1.2, -0.35), Vector3.FORWARD, VrRules.LEFT)
	_hand(Vector3(0.2, 1.2, -0.35))
	_frame()
	assert_almost_eq(g.stretch, 2.0, 0.05, "twice as far apart: twice as big")
	assert_almost_eq(g.thing().scale.x, 2.0, 0.05)
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(g.held_by(), VrRules.LEFT, "one hand keeps it")


func test_over_the_shoulder_a_thing_goes_into_its_bag() -> void:
	var t := Bagged.new()
	var g := _thing(_hand_world() + Vector3(0.0, 0.0, -0.05), &"hold", t)
	_frame()
	_grip(VrRules.RIGHT, 1.0)
	_hand(Vector3(0.15, 1.65, 0.15))   # behind the head, by the ear
	_frame()
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(t.bagged, 1, "into the bag")
	assert_eq((heard.released[0] as Array)[1], Vector3.ZERO, "no throw over the shoulder")
	assert_eq(g.held_by(), &"")


func test_the_trigger_is_the_held_things_and_never_the_worlds() -> void:
	var taps := Taps.new()
	Vr.input.target = taps
	_thing(_hand_world() + Vector3(0.0, 0.0, -0.05), &"tool")
	_frame()
	_grip(VrRules.RIGHT, 1.0)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.7)
	_frame()
	assert_true(heard.used.size() > 0 and is_equal_approx(float((heard.used[-1] as Array)[1]), 0.7), "used: 0.7")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_frame()
	assert_eq(taps.placed, 0, "the tap was the tool's, not a block placed")
	assert_true(Vr.hand_busy(VrRules.RIGHT), "the laser's hand is busy while it holds")


func test_the_hands_picture_stops_at_a_blocks_face_and_its_outline_shows_where_the_real_hand_is() -> void:
	var feet_y := p.global_position.y
	var local := Vr.rig.global_transform.affine_inverse() * Vector3(0.7, feet_y + 0.3, -0.3)
	_hand(local)
	_frame()
	var model := Vr.hand_models[VrRules.RIGHT] as VrHandModel
	assert_false(model.ghost_shown(), "in the air: one hand")
	local = Vr.rig.global_transform.affine_inverse() * Vector3(0.7, feet_y - 0.25, -0.3)   # pushed 25 cm into the stone
	_hand(local)
	_frame()
	assert_gte(model.global_position.y, feet_y + VrGrabRules.HAND_RADIUS * 0.5, "the picture stays on the floor's face")
	assert_true(model.ghost_shown(), "a faint outline where the real hand is")


func test_a_pickup_bag_is_taken_by_the_hand_through_the_host() -> void:
	var bag := PickupBag.new()
	bag.setup({"id": "bag_vr", "pos": _hand_world() + Vector3(0.0, -0.3, -0.08), "owner": "", "items": []})
	add_child_autofree(bag)
	bag.global_position = _hand_world() + Vector3(0.0, -0.3, -0.08)
	_frames(VrGrabber.ATTACH_EVERY + 0.05)
	assert_true(bag.has_node(^"VrGrabbable"), "a bag is a thing a hand takes in VR")
	var asked := []
	var heard_take := func(_peer: int, bag_name: String) -> void: asked.append(bag_name)
	Session.bag_take_requested.connect(heard_take)
	_grip(VrRules.RIGHT, 1.0)
	Session.bag_take_requested.disconnect(heard_take)
	assert_eq(asked, ["bag_vr"], "the grip asks the host for it, as a tap does")
	assert_almost_eq(bag.global_position.distance_to(_hand_world() + Vector3(0.0, -0.3, -0.08)), 0.0, 0.001,
		"it never moves on this game alone")


func test_off_vr_a_grabbable_is_just_a_node() -> void:
	Vr.simulate(false)
	var g := _thing(Vector3(0, 81, 0))
	assert_null(Vr.grabber, "no grabber off VR")
	assert_eq(g.held_by(), &"")
	assert_false(Vr.hand_busy(VrRules.RIGHT))
