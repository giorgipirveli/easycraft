extends GutTest
## Owner #110, VR round 4 (VR-WONDER, idea 4 "the Lab bench by hand"; docs/devlog/parts/vr-r4-wonder.md): in a headset
## the Lab's float-or-sink and magnets are done with the hands on a bench at hand height (VrLabBench, made by LabPanel),
## driven with fake hands (Vr.simulate) on a real Player and the real Lab (LabScreen on its own profile). A cube put in a
## basket is the prediction (the Lab's own sort); after TRY IT a cube let go over the tank is dropped in and floats or
## sinks as the Lab's tested model says; the magnet pulls the magnetic things to it from further away and leaves the rest;
## the handle lifts the bench; the bench goes with the Lab's experiment; nothing of it off VR.

const DT := 1.0 / 72.0


class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


var p: Player
var panel: LabPanel
var profile: ProfileData
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	LabExperiments.clear_cache()
	profile = ProfileData.new()
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
	panel = LabPanel.new()
	panel.screen_profile = profile
	add_child_autofree(panel)


func after_each() -> void:
	if is_instance_valid(panel):
		panel.close()
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func after_all() -> void:
	Audio.stop_all()


func _frame(delta: float = DT) -> void:
	Vr.step_physics()
	Vr.step(delta)
	Input.flush_buffered_events()
	p.rig._process(delta)
	p._process(delta)
	if is_instance_valid(panel):
		panel.vr_step()
		if panel.vr_bench != null and is_instance_valid(panel.vr_bench):
			panel.vr_bench.step(delta)


func _frames(seconds: float) -> void:
	for i in ceili(seconds / DT):
		_frame()


## The Lab open on experiment `id` (its PREDICT page), its saves kept off the disk.
func _lab(id: String) -> LabScreen:
	panel.open()
	panel.screen.save_profile = func() -> void: pass
	panel.screen.open(id)
	_frame()
	return panel.screen


func _hand_to(side: StringName, at: Vector3) -> void:
	Vr.sim_hand(side, Transform3D(Basis(), Vr.rig.global_transform.affine_inverse() * at / Vr.world_scale()))


## Takes thing `i` with the right hand and lets it go at `at` (the bench's own space).
func _carry(i: int, at: Vector3, side: StringName = VrRules.RIGHT) -> void:
	var b := panel.vr_bench
	_hand_to(side, b.thing(i).global_position)
	_frame()
	Vr.sim_input(side, &"grip", 1.0)
	_frame()
	assert_eq(b.thing_grabbable(i).held_by(), side, "thing %d in the hand" % i)
	_hand_to(side, b.global_transform * at)
	_frame()
	Vr.sim_input(side, &"grip", 0.0)
	_frame()


func _sort_all(screen: LabScreen) -> void:
	var things: Array = (screen.experiment.scene as Dictionary).things
	for i in things.size():
		_carry(i, LabBenchRules.BASKETS[i % 2] + Vector3(0.0, 0.06, 0.0))


func test_in_vr_float_or_sink_opens_a_bench_at_hand_height() -> void:
	var screen := _lab("float_sink")
	assert_eq(screen.page, LabScreen.PREDICT)
	var b := panel.vr_bench
	assert_not_null(b, "a real bench in front of the child")
	var head := Vr.head_transform().origin
	assert_almost_eq(b.global_position.y, head.y - LabBenchRules.START_DROP, 0.01, "at hand height")
	assert_almost_eq(Vector2(b.global_position.x - head.x, b.global_position.z - head.z).length(), LabBenchRules.START_AHEAD,
		0.01)
	assert_eq(b.thing_count(), 8, "a shelf of eight cubes")
	for i in 8:
		var want := b.global_transform * LabBenchRules.shelf_spot(i, 8)
		assert_almost_eq(b.thing(i).global_position.distance_to(want), 0.0, 0.005, "cube %d on the shelf" % i)
	assert_eq(b.basket_words(), ["FLOATS", "SINKS"] as Array[String], "the baskets say the experiment's groups")
	assert_true(b.has_tank(), "the tank of water")
	assert_false(b.has_magnet())


## The panel keeps the words, TRY IT! and WHAT HAPPENED?; the 2D cards and the 2D tank the bench does by hand are not
## drawn twice (P5's budget) and the panel says what to do on the bench.
func test_the_panel_says_what_to_do_on_the_bench_and_hides_its_2d_copies() -> void:
	var screen := _lab("float_sink")
	assert_false(screen.predict_answer.visible, "the cards to tap: the bench's cubes instead")
	assert_eq(panel.vr_words(), LabPanel.VR_SORT_WORDS)
	_sort_all(screen)
	screen.try_button.pressed.emit()
	_frame()
	assert_false(screen.view.visible, "the 2D tank: the bench's instead")
	assert_eq(panel.vr_words(), LabPanel.VR_TANK_WORDS)
	screen.show_list()
	_frame()
	assert_eq(panel.vr_words(), "", "no bench: no words")
	screen.open("magnets")
	_frame()
	_sort_all(screen)
	screen.try_button.pressed.emit()
	_frame()
	assert_eq(panel.vr_words(), LabPanel.VR_MAGNET_WORDS)
	panel.vr_bench.close()   # the bench gone (as when VR ends): the panel's own again
	panel.vr_bench = null
	Vr.simulate(false)
	_frame()
	assert_true(screen.view.visible, "off VR the 2D scene is back")


func test_a_cube_put_in_a_basket_is_the_guess_and_all_sorted_open_try_it() -> void:
	var screen := _lab("float_sink")
	var b := panel.vr_bench
	_carry(0, LabBenchRules.BASKETS[0] + Vector3(0.0, 0.08, 0.0))
	assert_eq(screen.predict_answer.picked[0], 0, "the wood guessed to float: the Lab's own sort")
	_frames(VrLabBench.GLIDE_TIME + 0.05)
	assert_eq(LabBenchRules.basket_at(b.global_transform.affine_inverse() * b.thing(0).global_position), 0, "it sits in the basket")
	_carry(0, LabBenchRules.BASKETS[1] + Vector3(0.0, 0.08, 0.0))
	assert_eq(screen.predict_answer.picked[0], 1, "moved to the other basket: the guess changes")
	_carry(1, Vector3(0.0, 0.2, -0.05))
	assert_eq(screen.predict_answer.picked[1], -1, "let go in the air: no guess, back on the shelf")
	_frames(VrLabBench.GLIDE_TIME + 0.05)
	assert_almost_eq(b.thing(1).global_position.distance_to(b.global_transform * LabBenchRules.shelf_spot(1, 8)), 0.0, 0.005)
	assert_true(screen.try_button.disabled, "not every thing guessed yet")
	_sort_all(screen)
	assert_false(screen.try_button.disabled, "every thing sorted: TRY IT! on the panel")


func test_dropped_in_the_tank_a_cube_floats_or_sinks_as_the_lab_says() -> void:
	var screen := _lab("float_sink")
	var b := panel.vr_bench
	_sort_all(screen)
	screen.try_button.pressed.emit()
	_frame()
	assert_eq(screen.page, LabScreen.TRY)
	var tank := screen.model as LabTank
	var above := LabBenchRules.TANK_AT + Vector3(0.0, LabBenchRules.TANK_SIZE.y + 0.05, 0.0)
	_carry(0, above)   # the wood
	assert_true(tank.is_dropped(0), "dropped in: the Lab's model")
	assert_eq(tank.last, "The wood floats!", "the Lab says what happened")
	_carry(1, above)   # the stone
	assert_eq(tank.last, "The stone sinks!")
	_frames(VrLabBench.GLIDE_TIME + 0.1)
	var wood := b.global_transform.affine_inverse() * b.thing(0).global_position
	var stone := b.global_transform.affine_inverse() * b.thing(1).global_position
	assert_almost_eq(wood.y, LabBenchRules.tank_spot(true, 0, 1).y, VrLabBench.BOB + 0.002, "the wood bobs at the top")
	assert_almost_eq(stone.y, LabBenchRules.tank_spot(false, 0, 1).y, 0.002, "the stone rests on the bottom")
	assert_false(b.thing_grabbable(0).enabled, "in the tank once: as a tap")
	_carry(2, Vector3(-0.1, 0.25, -0.05))   # the ice, let go in the air
	assert_false(tank.is_dropped(2), "only over the tank")
	for i in range(2, 8):
		_carry(i, above)
	assert_true(tank.done(), "every thing in the tank")
	assert_false(screen.what_button.disabled, "WHAT HAPPENED? opens")
	screen.what_button.pressed.emit()
	_frame()
	assert_eq(screen.page, LabScreen.WHY, "the why cards come after the doing")
	assert_true(profile.lab.has_star("float_sink"), "the Lab Book's star as before")
	assert_not_null(panel.vr_bench, "the bench stays while the why cards show")


func test_the_magnet_pulls_magnetic_things_from_further_away_and_leaves_the_rest() -> void:
	var screen := _lab("magnets")
	var b := panel.vr_bench
	assert_true(b.has_magnet(), "the magnet rests on the bench")
	assert_false(b.has_tank())
	assert_eq(b.basket_words(), ["STICKS", "DOES NOT STICK"] as Array[String])
	_sort_all(screen)
	screen.try_button.pressed.emit()
	_frame()
	var magnet := screen.model as LabMagnet
	_hand_to(VrRules.RIGHT, b.magnet().global_position)
	_frame()
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_frame()
	assert_eq(b.magnet_grabbable().held_by(), VrRules.RIGHT, "the magnet in the hand")
	var iron := b.thing(1)   # the iron nail
	var wood := b.thing(0)
	var buzzes := Vr.haptics
	_point_tip(b, iron.global_position, 0.08)
	assert_true(magnet.is_tested(1), "the nail felt the pull from 8 cm")
	assert_true(magnet.sticks(1))
	assert_gt(Vr.haptics, buzzes, "a buzz as it clicks on")
	_frames(0.3)
	assert_almost_eq(iron.global_position.distance_to(b.magnet_tip()), LabBenchRules.CUBE * 0.5, 0.03, "stuck to the tip")
	_point_tip(b, wood.global_position, 0.08)
	assert_false(magnet.is_tested(0), "the wood feels nothing from 8 cm")
	var wood_at := wood.global_position
	_point_tip(b, wood.global_position, 0.02)
	assert_true(magnet.is_tested(0), "touched: tried")
	assert_eq(magnet.last, "The wooden block does not stick.")
	_frames(0.3)
	assert_almost_eq(wood.global_position.distance_to(wood_at), 0.0, 0.01, "and it stays where it was")


## The magnet's tip `gap` m beside the surface of a cube at `at` (from the cube's side towards the child).
func _point_tip(b: VrLabBench, at: Vector3, gap: float) -> void:
	var tip_from_hand := b.magnet_tip() - Vr.hand_grip(VrRules.RIGHT).origin
	var tip_at := at + (b.global_basis.z.normalized() * (LabBenchRules.CUBE * 0.5 + gap))
	_hand_to(VrRules.RIGHT, tip_at - tip_from_hand)
	_frame()
	_frame()


func test_the_handle_lifts_and_lowers_the_bench_within_reach() -> void:
	_lab("float_sink")
	var b := panel.vr_bench
	var y0 := b.global_position.y
	_hand_to(VrRules.LEFT, b.handle_position())
	_frame()
	Vr.sim_input(VrRules.LEFT, &"grip", 1.0)
	_frame()
	_hand_to(VrRules.LEFT, b.handle_position() + Vector3(0.0, 0.1, 0.0))
	_frame()
	assert_almost_eq(b.global_position.y, y0 + 0.1, 0.005, "up with the hand")
	_hand_to(VrRules.LEFT, b.handle_position() + Vector3(0.0, 2.0, 0.0))
	_frame()
	assert_almost_eq(b.global_position.y, Vr.head_transform().origin.y - LabBenchRules.LIFT.x, 0.01, "never above the chest")
	Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
	_frame()


func test_the_bench_goes_with_the_experiment_and_the_lab() -> void:
	var screen := _lab("float_sink")
	var b := panel.vr_bench
	screen.show_list()
	_frame()
	assert_true(not is_instance_valid(b) or b.is_queued_for_deletion(), "back to the list: the bench goes")
	assert_null(panel.vr_bench)
	screen.open("melting")
	_frame()
	assert_null(panel.vr_bench, "the heat experiment stays on the panel")
	screen.open("magnets")
	_frame()
	assert_not_null(panel.vr_bench)
	var m := panel.vr_bench
	panel.close()
	_frame()
	assert_true(not is_instance_valid(m) or m.is_queued_for_deletion(), "the Lab closed: the bench goes")


func test_off_vr_the_lab_is_as_before() -> void:
	Vr.simulate(false)
	var screen := _lab("float_sink")
	assert_eq(screen.page, LabScreen.PREDICT)
	assert_null(panel.vr_bench, "no bench off VR")
	assert_true(screen.predict_answer.visible, "the cards to tap, as before")
	assert_eq(panel.vr_words(), "")
