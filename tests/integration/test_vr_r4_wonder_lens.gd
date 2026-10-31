extends GutTest
## Owner #110, VR round 4 (VR-WONDER, idea 2 "lens tools"; docs/devlog/parts/vr-r4-wonder.md): the telescope and the
## magnifier (items 500, 501) with fake hands (Vr.simulate) on a real Player. The one chosen in the hotbar is in the
## pointing hand (VrLens, a VrGrabbable &"tool" given by VR-HANDS' grabber); its trigger zooms 2x to 8x **only inside the
## lens** (ruling R7: the head's view never changes); its view is steadied; the magnifier over sand shows the sand's
## grains and their fact; another item puts it away; the VR palette offers both; nothing off VR.

const DT := 1.0 / 72.0


class SandWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.SAND if pos.y < 80 else BlockIds.AIR


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


var p: Player
var interactor: BlockInteractor
var _settings := {}
var _mode := &""


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	_mode = Game.mode
	Game.mode = ModeRules.SANDBOX
	var w := SandWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	interactor = p.get_node("BlockInteractor") as BlockInteractor
	interactor.set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.visible = true
	p.global_position = Vector3(0.5, 80, 0.5)
	interactor.hotbar[0] = BlockIds.STONE
	interactor.hotbar[1] = ItemIds.TELESCOPE
	interactor.hotbar[2] = ItemIds.MAGNIFIER
	interactor.select_slot(0)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	Game.mode = _mode
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


func _lens() -> VrLens:
	return Vr.grabber.get_node_or_null(^"VrLens") as VrLens if Vr.grabber != null else null


func _hold(item: int) -> VrLens:
	interactor.select_slot(interactor.hotbar.find(item))
	_frame()
	_frame()
	return _lens()


func test_the_telescope_chosen_in_the_hotbar_is_in_the_pointing_hand() -> void:
	assert_null(_lens(), "a block in the hand: no lens")
	var lens := _hold(ItemIds.TELESCOPE)
	assert_not_null(lens, "the telescope comes into the hand")
	assert_eq(lens.kind, LensRules.TELESCOPE)
	assert_eq(lens.grabbable.kind, &"tool")
	assert_eq(lens.grabbable.held_by(), Vr.pointing_hand(), "held by the hand that points")
	assert_eq(Vr.grabber.held(Vr.pointing_hand()), lens.grabbable)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.25, 1.3, -0.4)))
	_frame()
	assert_almost_eq(lens.global_position.distance_to(Vr.hand_grip(VrRules.RIGHT).origin), 0.0, 0.01, "it moves with the hand")
	assert_true(lens.viewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS, "its view is drawn while held")


func test_the_trigger_zooms_only_inside_the_lens_r7() -> void:
	var taps := Taps.new()
	Vr.input.target = taps
	var head_fov := Vr.camera.fov
	var lens := _hold(ItemIds.TELESCOPE)
	var eye := Vr.head_transform().origin
	var r := VrLens.TELESCOPE_RADIUS
	var d := eye.distance_to(lens.disc.global_position)
	assert_almost_eq(lens.camera.fov, LensRules.fov_degrees(r, d, 2.0), 0.05, "2x with the trigger let go")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_frame()
	_frame()
	d = Vr.head_transform().origin.distance_to(lens.disc.global_position)
	assert_almost_eq(lens.zoom, 8.0, 0.01, "squeezed: 8x")
	assert_almost_eq(lens.camera.fov, LensRules.fov_degrees(r, d, 8.0), 0.05, "the lens's camera narrows")
	assert_eq(Vr.camera.fov, head_fov, "the head's view never zooms")
	assert_eq(p.get_viewport().get_camera_3d(), Vr.camera, "the head is the view")
	assert_eq(lens.camera.get_viewport(), lens.viewport, "the lens camera draws only the lens's own picture")
	assert_eq(lens.disc.layers, VrLens.LENS_LAYER, "the lens on its own layer")
	assert_eq(lens.camera.cull_mask & VrLens.LENS_LAYER, 0, "its camera never sees its own disc (no feedback)")
	assert_ne(Vr.camera.cull_mask & VrLens.LENS_LAYER, 0, "the head sees it")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_frame()
	assert_eq(taps.placed, 0, "the trigger was the telescope's, never a block placed")
	assert_true(Vr.hand_busy(VrRules.RIGHT), "the laser is off while it is held")


func test_the_view_through_the_lens_is_steadied() -> void:
	var lens := _hold(ItemIds.TELESCOPE)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	var at := Vector3(0.2, 1.3, -0.4)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), at))
	_frames(1.0)
	var cam0 := lens.camera.global_basis.get_rotation_quaternion()
	var hand0 := Vr.hand_grip(VrRules.RIGHT).basis.get_rotation_quaternion()
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(Vector3.UP, deg_to_rad(1.5)), at))   # a tremor
	_frame()
	var turned_hand := rad_to_deg(hand0.angle_to(Vr.hand_grip(VrRules.RIGHT).basis.get_rotation_quaternion()))
	var turned_cam := rad_to_deg(cam0.angle_to(lens.camera.global_basis.get_rotation_quaternion()))
	assert_almost_eq(turned_hand, 1.5, 0.05)
	assert_lt(turned_cam, turned_hand * 0.2, "a zoomed tremor is smoothed")
	assert_gt(turned_cam, 0.0, "but the view still follows")


func test_the_magnifier_over_sand_shows_its_grains_and_their_fact() -> void:
	var lens := _hold(ItemIds.MAGNIFIER)
	assert_eq(lens.kind, LensRules.MAGNIFIER)
	# the head looks straight down at the hand held low, pointing down: the glass 45 cm over the sand
	Vr.sim_head(Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(0.0, 1.6, 0.0)))
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(0.0, 0.57, 0.0)))
	_frames(0.2)
	assert_eq(lens.closeup_shown(), &"sand", "close up: the sand's grains")
	assert_true(lens.fact_label.visible)
	assert_string_contains(lens.fact_label.text, "Sand is tiny bits of rock and shell")
	assert_eq(lens.viewport.render_target_update_mode, SubViewport.UPDATE_DISABLED, "its own picture: no second render")
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(0.0, 1.35, 0.0)))
	_frames(0.2)
	assert_eq(lens.closeup_shown(), &"", "further away: the magnified world")
	assert_false(lens.fact_label.visible)
	assert_eq(lens.viewport.render_target_update_mode, SubViewport.UPDATE_ALWAYS)


func test_letting_go_of_the_grip_keeps_the_lens_in_the_hand() -> void:
	var lens := _hold(ItemIds.TELESCOPE)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_frame()
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	_frame()
	_frame()
	assert_eq(lens.grabbable.held_by(), Vr.pointing_hand(), "the hotbar's item stays in the hand")


func test_another_item_puts_the_lens_away() -> void:
	var lens := _hold(ItemIds.TELESCOPE)
	interactor.select_slot(0)
	_frame()
	_frame()
	assert_true(not is_instance_valid(lens) or lens.is_queued_for_deletion(), "a block in the hand: the lens goes")
	assert_eq(Vr.grabber.state(VrRules.RIGHT), VrGrabber.IDLE, "the hand is free (the laser again)")
	var m := _hold(ItemIds.MAGNIFIER)
	assert_eq(m.kind, LensRules.MAGNIFIER, "the other lens")


func test_the_vr_palette_offers_both_lenses_and_off_vr_none() -> void:
	var vr_palette := BlockPalette.new()
	add_child_autofree(vr_palette)
	assert_has(_names(vr_palette), "Telescope", "in a headset: the SMART page's LOOK row")
	assert_has(_names(vr_palette), "Magnifier")
	Vr.simulate(false)
	var flat := BlockPalette.new()
	add_child_autofree(flat)
	assert_does_not_have(_names(flat), "Telescope", "off VR the palette is as before")
	assert_does_not_have(_names(flat), "Magnifier")


## A hotbar saved in a headset may hold a lens on a phone later: a tap with it asks the host for nothing (no block 500,
## no "can't place that" message), as a pet treat.
func test_off_vr_a_lens_in_the_hotbar_does_nothing() -> void:
	Vr.simulate(false)
	Session.register_world(p.world)
	interactor.select_slot(1)
	var asked := []
	var heard := func(pos: Vector3i, id: int) -> void: asked.append([pos, id])
	Session.edit_rejected.connect(heard)
	var placed := interactor.place_block(Vector3i(1, 80, 0), ItemIds.TELESCOPE)
	var control := interactor.place_block(Vector3i(1, 80, 0), 999)   # an invalid block is refused by the host as before
	Session.edit_rejected.disconnect(heard)
	Session.register_world(null)
	assert_false(placed, "no block")
	assert_false(control)
	assert_eq(asked, [[Vector3i(1, 80, 0), 999]], "the lens asked the host for nothing (the control was refused)")
	assert_null(Vr.grabber, "no grabber, no lens off VR")


func _names(palette: BlockPalette) -> Array[String]:
	var out: Array[String] = []
	for b in palette.find_children("*", "Button", true, false):
		out.append((b as Button).tooltip_text)
	return out
