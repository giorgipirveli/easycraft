extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.7 VR, §4.4 VR; the lead's review 5; the B2 brief): a voyage in
## a headset (a simulated one: Vr.simulate, sim_hand, sim_input). The child stands at the garden's spot (Vr.anchor); the
## can is lifted and tilted over the soil; a hand on the leaf grows the garden round the feet (the head never moves);
## inside, the child swims (a pulled grip moves the body the other way, thick air stops it), the laser grapple glides to
## a door, both hands squeeze a door shut and pull it open, one hand's trigger toggles one, a hand carries a sugar to
## the gold pipe; Hoot flies at the shoulder; the HUD is the forearm's panel, never the flat tap area.

const UNIT := "g5.science.plants_air_water"

var host: LeafVoyageHost
var layer: CanvasLayer
var screen: Control
var _path := ""


func before_each() -> void:
	Profile.data.settings.reduce_motion = true
	_path = "user://test_leaf_host_vr_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	screen = Control.new()
	layer.add_child(screen)


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		Vr.sim_input(side, &"grip", 0.0)
		Vr.sim_input(side, &"trigger", 0.0)
	Vr.simulate(false)
	Profile.data.settings.reduce_motion = false
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(voyage: String = "5.1") -> void:
	Vr.simulate(true)
	await wait_process_frames(2)
	host = LeafVoyageHost.new()
	host.progress_path = _path
	host.setup(UNIT, {"id": UNIT, "exercises": [], "play": {"game": "leaf_voyage", "params": {"voyage": voyage}}}, 7,
		0, {})
	host.open(screen)
	await wait_physics_frames(2)
	await wait_process_frames(2)
	host.set_process(false)


func _step(seconds: float, dt: float = 0.1) -> void:
	var t := 0.0
	while t < seconds - 0.0001 and is_instance_valid(host) and not host.closed:
		host.step(dt)
		t += dt


## Puts a simulated hand at `world` (its aim and grip), pointing along `basis` (world).
func _hand_at(side: StringName, world: Vector3, basis: Basis = Basis()) -> void:
	var rig := Vr.rig.global_transform
	Vr.sim_hand(side, Transform3D(rig.basis.inverse() * basis, rig.affine_inverse() * world))


func _grip(side: StringName, on: bool) -> void:
	Vr.sim_input(side, &"grip", 1.0 if on else 0.0)
	await wait_process_frames(1)


func _inside() -> void:
	host.water_now()
	host.tap_target("leaf")
	_step(LeafJourney.DIVE_TIME + LeafJourney.UNDER_TIME + 0.3)
	await wait_physics_frames(2)
	await wait_process_frames(1)


func test_vr_the_child_stands_in_the_garden_and_the_hud_is_on_the_panel() -> void:
	await _open()
	assert_true(host.vr)
	assert_eq(Vr.anchor_node(), host.stand, "the child stands at the garden's spot")
	assert_lt(host.stand.global_position.distance_to(host.garden.vr_stand(LeafGarden.GARDEN).origin), 0.01)
	assert_eq(host.hud.tap_area.mouse_filter, Control.MOUSE_FILTER_IGNORE, "no flat tap area in VR")
	assert_true(host.hud.vr, "the HUD is the forearm's panel")


func test_vr_the_can_is_lifted_and_tilted_over_the_soil_and_pours() -> void:
	await _open()
	var g := host.garden
	_hand_at(VrRules.RIGHT, g.target_position("can"))
	await wait_process_frames(1)
	await _grip(VrRules.RIGHT, true)
	host.step(0.1)
	var tilt := Basis(Vector3.RIGHT, -0.9)
	var soil := g.target_position("soil")
	var rose := tilt * (LeafVrHands.CAN_IN_HAND * LeafGarden.ROSE)
	_hand_at(VrRules.RIGHT, soil + Vector3(0, 0.25, 0) - rose, tilt)
	await wait_process_frames(1)
	_step(LeafVrHands.POUR_HOLD + 0.3)
	assert_true(host.journey.watered, "tilted over the soil, the can poured")
	assert_true(g.watered, "the soil darkened")
	await _grip(VrRules.RIGHT, false)
	host.step(0.1)


func test_vr_a_hand_on_the_leaf_grows_the_garden_round_the_feet() -> void:
	await _open()
	host.water_now()
	var stood := host.stand.global_position
	_hand_at(VrRules.LEFT, host.garden.target_position("leaf"))
	await wait_process_frames(1)
	host.step(0.1)
	assert_eq(host.journey.stage, LeafJourney.DIVE, "touched: Size Magic")
	_step(LeafJourney.DIVE_TIME * 0.5)
	assert_gt(host.garden.scale.x, 2.0, "the garden grows round the child")
	assert_lt(host.stand.global_position.distance_to(stood), 0.001, "the head never moves")
	_step(LeafJourney.DIVE_TIME * 0.5 + 0.2)
	assert_eq(host.journey.stage, LeafJourney.UNDER)
	assert_false(host.garden.visible)
	assert_lt(host.stand.global_position.distance_to(host.place.vr_stand(LeafPlace.UNDER).origin), 0.01,
		"under the leaf, behind a blink")


func test_vr_swimming_moves_the_body_the_other_way_and_thick_air_stops_it() -> void:
	await _open()
	await _inside()
	var start := host.stand.global_position
	var hand := host.stand.global_position + Vector3(0.3, -0.3, -0.4)
	_hand_at(VrRules.RIGHT, hand)
	await wait_process_frames(1)
	await _grip(VrRules.RIGHT, true)
	host.step(1.0 / 30.0)
	for i in 6:   # the hand pulls back towards the child: the body goes forward (-Z)
		hand += Vector3(0, 0, 0.05)
		_hand_at(VrRules.RIGHT, hand)
		await wait_process_frames(1)
		host.step(1.0 / 30.0)
	assert_lt(host.stand.global_position.z, start.z - 0.05, "pulled back, it moved forward")
	assert_lte(host.vr_hands.speed(), LeafSwimRules.MAX_SPEED + 0.001, "never faster than the cap")
	await _grip(VrRules.RIGHT, false)
	_step(LeafSwimRules.STOP_TIME + 0.05, 1.0 / 30.0)
	assert_lt(host.vr_hands.speed(), 0.1, "the hands rest: it stops within a quarter second")


func test_vr_the_laser_grapple_glides_to_a_door() -> void:
	await _open()
	await _inside()
	var door := host.place.target_position("door_0")   # the nearest door: nothing in front of it
	var from := host.stand.global_position + Vector3(0.2, -0.3, -0.2)
	_hand_at(Vr.pointing_hand(), from, Basis.looking_at(door - from, Vector3.UP))
	await wait_process_frames(1)
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 1.0)
	await wait_process_frames(2)
	host.step(0.05)
	assert_true(host.vr_hands.grappling(), "the trigger on a door: a glide there")
	_step(LeafVrHands.GRAPPLE + 0.1, 0.05)
	assert_lt(host.stand.global_position.distance_to(host.place.vr_stand("door_0").origin), 0.05, "at the door's stand")
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 0.0)


func test_vr_a_child_who_chose_the_strong_vignette_blinks_to_the_door_instead() -> void:
	var was: Variant = Profile.data.settings.get(VrRules.VIGNETTE, VrRules.VIGNETTE_DEFAULT)
	Profile.data.settings[VrRules.VIGNETTE] = "strong"
	await _open()
	await _inside()
	var door := host.place.target_position("door_0")
	var from := host.stand.global_position + Vector3(0.2, -0.3, -0.2)
	_hand_at(Vr.pointing_hand(), from, Basis.looking_at(door - from, Vector3.UP))
	await wait_process_frames(1)
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 1.0)
	await wait_process_frames(2)
	host.step(0.05)
	assert_false(host.vr_hands.grappling(), "no glide ...")
	assert_lt(host.stand.global_position.distance_to(host.place.vr_stand("door_0").origin), 0.05, "... a blink there")
	Vr.sim_input(Vr.pointing_hand(), &"trigger", 0.0)
	Profile.data.settings[VrRules.VIGNETTE] = was


func test_vr_two_hands_squeeze_a_door_shut_and_pull_it_open() -> void:
	await _open()
	await _inside()
	var run := host.journey.run
	assert_true(run.sim.doors[2], "act 1: the doors are open")
	var a := host.place.target_position("door_2_a")
	var b := host.place.target_position("door_2_b")
	_hand_at(VrRules.LEFT, a)
	_hand_at(VrRules.RIGHT, b)
	await wait_process_frames(1)
	Vr.sim_input(VrRules.LEFT, &"grip", 1.0)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	await wait_process_frames(1)
	host.step(0.05)
	var mid := (a + b) * 0.5
	_hand_at(VrRules.LEFT, mid + (a - mid) * 0.5)
	_hand_at(VrRules.RIGHT, mid + (b - mid) * 0.5)
	await wait_process_frames(1)
	host.step(0.05)
	assert_false(run.sim.doors[2], "squeezed together: shut")
	_hand_at(VrRules.LEFT, mid + (a - mid) * 1.8)
	_hand_at(VrRules.RIGHT, mid + (b - mid) * 1.8)
	await wait_process_frames(1)
	host.step(0.05)
	assert_true(run.sim.doors[2], "pulled apart: open")


func test_vr_one_hands_trigger_on_a_door_toggles_it() -> void:
	await _open()
	await _inside()
	var run := host.journey.run
	var other := VrRules.LEFT if Vr.pointing_hand() == VrRules.RIGHT else VrRules.RIGHT
	_hand_at(other, host.place.target_position("door_3"))
	await wait_process_frames(1)
	host.step(0.05)
	Vr.sim_input(other, &"trigger", 1.0)
	await wait_process_frames(1)
	host.step(0.05)
	assert_false(run.sim.doors[3], "one trigger: the door toggles (for one-handed play)")
	Vr.sim_input(other, &"trigger", 0.0)


func test_vr_a_hand_carries_a_sugar_to_the_gold_pipe() -> void:
	await _open()
	await _inside()
	var run := host.journey.run
	run.sim.made = 3.0
	host.step(0.1)
	var spot := host.place.waiting_spots()[0]
	_hand_at(VrRules.RIGHT, host.place.target_position("sugar_%d" % spot))
	await wait_process_frames(1)
	await _grip(VrRules.RIGHT, true)
	host.step(0.05)
	assert_eq(run.carried(), 1, "the hexagon follows the hand")
	_hand_at(VrRules.RIGHT, host.place.target_position("gold_pipe"))
	await wait_process_frames(1)
	host.step(0.05)
	await _grip(VrRules.RIGHT, false)
	host.step(0.05)
	assert_eq(run.sim.delivered, 1, "let go at the gold pipe's mouth: it whooshes to the bud")


func test_vr_hoot_flies_at_the_childs_shoulder_inside() -> void:
	await _open()
	await _inside()
	host.step(0.05)
	var hoot := host.vr_hands.hoot
	assert_not_null(hoot)
	assert_true(hoot.visible)
	assert_lt(hoot.global_position.distance_to(Vr.head_transform().origin), 0.8, "at the shoulder")
