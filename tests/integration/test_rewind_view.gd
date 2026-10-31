extends GutTest
## M3 Task 8 (spec §14.5, §3a): Build Rewind's time-lapse. RewindPreview shows the recorded cells as MultiMeshes
## (one per block id, each block's cube in its own shared material) in a world of its own, and moves through the
## edits in order; RewindView plays it in at most 20 s around an orbiting camera (PhotoOrbit) with AGAIN, NEW and
## CLOSE, and never touches the world. The recording is saved with the world (WorldMeta.rewind).


func _log(n: int = 6) -> RewindLog:
	var r := RewindLog.new()
	r.start(Vector3i(50, 20, -10))
	for i in n:
		r.record(Vector3i(50 + i, 20, -10), BlockIds.AIR, BlockIds.BRICK if i % 2 == 0 else BlockIds.PAINTED_BLUE)
	r.record(Vector3i(50, 20, -10), BlockIds.BRICK, BlockIds.AIR)   # the first one broken again
	return r


func _visible(p: RewindPreview) -> Dictionary:
	return p.visible_cells()


func test_the_preview_shows_the_blocks_after_each_edit() -> void:
	var r := _log()
	var p := RewindPreview.new()
	add_child_autofree(p)
	p.setup(r)
	for n in [0, 1, 3, 6, 7, 2, 0, 7]:   # forwards, and back again
		p.seek(n)
		var want := {}
		var after := r.blocks_after(n)
		for pos: Vector3i in after:
			want[pos - r.center] = after[pos]
		assert_eq(_visible(p), want, "after %d edits" % n)


func test_one_multimesh_per_block_id_in_its_own_material() -> void:
	var r := _log()
	var p := RewindPreview.new()
	add_child_autofree(p)
	p.setup(r)
	p.seek(r.size())
	var multis := p.find_children("*", "MultiMeshInstance3D", true, false)
	assert_eq(multis.size(), 2, "brick and painted blue")
	for m: MultiMeshInstance3D in multis:
		var mesh := m.multimesh.mesh as ArrayMesh
		assert_not_null(mesh)
		assert_eq(m.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_same((p.find_children("*", "MultiMeshInstance3D", true, false)[0] as MultiMeshInstance3D).multimesh.mesh,
		WearMesh.cube(p.ids()[0]), "the shared cube of that block")


func test_the_view_plays_to_the_end_in_at_most_20_seconds() -> void:
	var v := RewindView.new()
	add_child_autofree(v)
	var r := _log()
	assert_true(v.open(r))
	assert_true(v.visible)
	assert_true(v.playing)
	var steps := 0
	while v.playing and steps < 400:
		v.step(0.1)
		steps += 1
	assert_false(v.playing, "it ends")
	assert_lte(steps * 0.1, RewindLog.MAX_SECONDS + RewindView.END_PAUSE + 0.2)
	assert_eq(v.preview.shown, r.size(), "every edit shown")
	var cam_before := v.camera.global_transform
	v.step(0.5)
	assert_ne(v.camera.global_transform, cam_before, "the camera keeps orbiting")
	v.again()
	assert_true(v.playing)
	assert_eq(v.preview.shown, 0, "AGAIN starts over")
	v.close()
	assert_false(v.visible)


func test_nothing_recorded_nothing_to_watch() -> void:
	var v := RewindView.new()
	add_child_autofree(v)
	var r := RewindLog.new()
	r.start(Vector3i.ZERO)
	assert_false(v.open(r))
	assert_false(v.visible)


## The time-lapse has a world of its own: the game's world is never touched, and the game's view is not drawn
## behind it while it shows (it is back when it closes).
func test_it_never_touches_the_world() -> void:
	var v := RewindView.new()
	add_child_autofree(v)
	var world := WorldService.new()
	add_child_autofree(world)
	var changes: Array = []
	world.block_changed.connect(func(p: Vector3i, _o: int, _n: int) -> void: changes.append(p))
	v.open(_log())
	for i in 30:
		v.step(0.1)
	assert_eq(changes, [])
	assert_true(v.viewport.own_world_3d, "a world of its own")
	assert_ne(v.preview.get_world_3d(), world.get_world_3d())
	assert_true(v.get_viewport().disable_3d, "the game's view is not drawn behind it")
	v.close()
	assert_false(v.get_viewport().disable_3d, "and is drawn again")


## The HUD hides while it shows (its buttons read touches before any GUI control) and comes back.
func test_the_hud_hides_while_it_shows() -> void:
	var v := RewindView.new()
	add_child_autofree(v)
	var hud := Control.new()
	add_child_autofree(hud)
	v.hud = hud
	v.open(_log())
	assert_false(hud.visible)
	v.close()
	assert_true(hud.visible)


func test_new_asks_for_a_new_recording_and_share_waits_for_m5() -> void:
	var v := RewindView.new()
	add_child_autofree(v)
	v.open(_log())
	watch_signals(v)
	v.new_recording()
	assert_signal_emitted(v, "restart_requested")
	assert_false(v.visible)
	assert_false(v.share_button.visible, "the video export comes in M5")
	assert_false(v.export_video(), "the hook is there")


func test_the_world_keeps_its_recording() -> void:
	var m := WorldMeta.new()
	m.rewind = _log().to_save()
	var back := WorldMeta.from_json(m.to_json())
	var r := RewindLog.from_save(back.rewind)
	assert_eq(r.size(), 7)
	assert_eq(r.center, Vector3i(50, 20, -10))
	assert_eq(WorldMeta.from_json(WorldMeta.new().to_json()).rewind, {}, "none: nothing saved")
