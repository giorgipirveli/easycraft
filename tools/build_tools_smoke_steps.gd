extends Node
## The steps of tools/build_tools_smoke.gd (M3 Task 8), in a new Sandbox world on real terrain, through the same
## calls a child's taps make (BuildToolUser, the sandbox's screens): paint and its undo, a LINE, a 4,096-block FILL
## and its one undo (timed), COPY and a turned paste, Build Rewind (recording, the time-lapse, saved with the world),
## Build-and-Wear through the wand's card (the hat on the avatar, in the profile); then the ruling's measurements:
## the block library's size and bake time, and Build Rewind's preview (MultiMesh) against remeshing its box with
## the blocky mesher. The player flies above the ground so big edits never drop it through a chunk being remeshed.

const TIMEOUT := 180.0

var _t := 0.0
var _step := 0
var _step_t := 0.0
var _fails: Array[String] = []
var _base := Vector3i.ZERO
var _free := 0
var _undo_before := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Profile.data.avatar.builds = {}
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player)


func _run_step(sandbox: Node, p: Player) -> void:
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	var tools := interactor.tools
	var world: WorldService = sandbox.world
	match _step:
		0:   # stand still in the air, facing north
			if _step_t < 1.5:
				return
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.global_position += Vector3(0, 6, 0)
			p.velocity = Vector3.ZERO
			p.rig.yaw = 0.0
			_base = Vector3i(p.global_position.floor()) + Vector3i(0, 0, -4)
			_check(tools != null and sandbox.get("build_bar") != null and sandbox.get("rewind_view") != null \
				and sandbox.get("wear_card") != null, "the tools, the bar, the time-lapse and the card are there")
			_next()
		1:   # REWIND starts, then paint and its undo
			if _step_t < 0.5:
				return
			tools.rewind_at(_base)
			Session.request_set_block(_base, BlockIds.STONE)
			tools.paint(_base, ItemIds.PAINT_RED)
			_check(world.get_block(_base) == BlockIds.PAINTED_RED, "paint turned the stone red")
			interactor.undo()
			_check(world.get_block(_base) == BlockIds.STONE, "undo gave the stone back")
			_next()
		2:   # a LINE of the block held last
			interactor.set_slot_block(interactor.selected_slot, BlockIds.BRICK)
			interactor.set_slot_block(interactor.selected_slot, ItemIds.LINE_TOOL)
			tools.tap(ItemIds.LINE_TOOL, _base + Vector3i(1, 4, 0))
			tools.tap(ItemIds.LINE_TOOL, _base + Vector3i(6, 7, 0))
			var n := 0
			for c in PowerTools.line_cells(_base + Vector3i(1, 4, 0), _base + Vector3i(6, 7, 0)):
				if world.get_block(c) == BlockIds.BRICK:
					n += 1
			_check(n == 9, "a line of 9 bricks (%d)" % n)
			_next()
		3:   # FILL 16 x 16 x 16 high above: accepted at once, written a slice a frame
			var a := _base + Vector3i(-8, 12, -20)
			var b := a + Vector3i(15, 15, 15)
			_free = PowerTools.fill_edits(a, b, BlockIds.GLASS, world.get_block).size()
			interactor.set_slot_block(interactor.selected_slot, BlockIds.GLASS)
			interactor.set_slot_block(interactor.selected_slot, ItemIds.FILL_TOOL)
			_undo_before = interactor.undo_size()
			Session.tool_slowest_slice_ms = 0.0
			tools.tap(ItemIds.FILL_TOOL, a)
			var t0 := Time.get_ticks_usec()
			tools.tap(ItemIds.FILL_TOOL, b)
			print("BUILD_SMOKE time fill_tap_ms=%.1f (the child's side and the host's checks) load=%s" % [
				(Time.get_ticks_usec() - t0) / 1000.0, _load()])
			_next()
		4:
			if Session.tool_busy():
				return
			var a := _base + Vector3i(-8, 12, -20)
			var b := a + Vector3i(15, 15, 15)
			var glass := PowerTools.fill_edits(a, b, BlockIds.GLASS, func(c: Vector3i) -> int:
				return BlockIds.AIR if world.get_block(c) == BlockIds.GLASS else BlockIds.STONE).size()
			_check(glass == _free and _free > 4000, "FILL put %d glass blocks (%d empty cells)" % [glass, _free])
			_check(interactor.undo_size() == _undo_before + 1, "one undo step")
			print("BUILD_SMOKE time fill_slowest_frame_ms=%.1f (budget %.0f ms, %d cells a chunk) written_after_s=%.2f" % [
				Session.tool_slowest_slice_ms, Session.TOOL_FRAME_MS, Session.TOOL_CHUNK, _step_t])
			Session.tool_slowest_slice_ms = 0.0
			interactor.undo()
			_next()
		5:
			if Session.tool_busy():
				return
			var a := _base + Vector3i(-8, 12, -20)
			_check(world.get_block(a) != BlockIds.GLASS and world.get_block(a + Vector3i(15, 15, 15)) != BlockIds.GLASS,
				"one undo took it away")
			print("BUILD_SMOKE time undo_slowest_frame_ms=%.1f undone_after_s=%.2f" % [Session.tool_slowest_slice_ms, _step_t])
			_next()
		6:   # COPY an L and paste it turned
			if _step_t < 1.0:
				return
			var at := _base + Vector3i(-6, 5, -2)
			Session.request_set_blocks([[at, BlockIds.RED], [at + Vector3i(1, 0, 0), BlockIds.BLUE],
				[at + Vector3i(0, 1, 0), BlockIds.YELLOW]])
			interactor.set_slot_block(interactor.selected_slot, ItemIds.COPY_TOOL)
			tools.tap(ItemIds.COPY_TOOL, at)
			tools.tap(ItemIds.COPY_TOOL, at + Vector3i(1, 1, 0))
			_check(tools.clipboard.size() == 3, "COPY holds 3 blocks")
			tools.turn()
			var anchor := _base + Vector3i(-6, 5, -8)
			tools.paste(anchor)
			var got := 0
			for dx in range(-3, 4):
				for dz in range(-3, 4):
					for dy in 2:
						if world.get_block(anchor + Vector3i(dx, dy, dz)) in [BlockIds.RED, BlockIds.BLUE, BlockIds.YELLOW]:
							got += 1
			_check(got == 3, "the paste put 3 blocks (%d)" % got)
			_next()
		7:   # Build Rewind: the recording, the time-lapse, saved with the world
			_check(tools.rewind.size() >= 12, "Rewind recorded %d edits" % tools.rewind.size())
			var view: RewindView = sandbox.rewind_view
			var t0 := Time.get_ticks_usec()
			tools.rewind_at(_base)
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			_check(view.visible and view.playing, "the time-lapse opened")
			print("BUILD_SMOKE time rewind_open_ms=%.1f edits=%d" % [ms, tools.rewind.size()])
			for i in 50:
				view.step(0.5)
			_check(not view.playing and view.preview.shown == tools.rewind.size(), "it played to the end")
			view.close()
			_check(not get_tree().paused and not get_viewport().disable_3d, "closed: the game runs and draws again")
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(RewindLog.from_save(meta.rewind).size() == tools.rewind.size(), "the world saved the recording")
			_next()
		8:   # Build-and-Wear: the wand on a small build, HAT
			var at := _base + Vector3i(3, 0, -3)
			Session.request_set_blocks([[at, BlockIds.PAINTED_PINK], [at + Vector3i(0, 1, 0), BlockIds.GOLD]])
			interactor.set_slot_block(interactor.selected_slot, ItemIds.WAND)
			var card: WearCard = sandbox.wear_card
			_check(tools.offer_wear(at) and card.visible, "the wand's card opened")
			card.choose(WearRules.HAT)
			_check(Profile.data.avatar.builds.has(WearRules.HAT), "the profile wears it")
			_check(p.avatar.find_child("built_hat", true, false) != null, "the avatar wears it")
			_check(world.get_block(at) == BlockIds.PAINTED_PINK, "the build stays in the world")
			_next()
		9:
			_measure_edits(world, p)
			_measure()
			_finish()


## Where a 4,096-block edit's time goes on the host: reading cells, the checks, writing them (with every listener
## of block_changed), each one call per cell.
func _measure_edits(world: WorldService, p: Player) -> void:
	var a := _base + Vector3i(-8, 12, -20)
	var cells := PowerTools.box_cells(a, a + Vector3i(15, 15, 15))
	var t0 := Time.get_ticks_usec()
	for c in cells:
		world.get_block(c)
	var get_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var eye := p.eye_position()
	var bodies := Session._player_bodies()
	t0 = Time.get_ticks_usec()
	for c in cells:
		PlacementRules.validate_edit(c, BlockIds.GLASS, BlockIds.AIR, eye, bodies, PowerTools.REACH)
	var check_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var listeners := world.block_changed.get_connections()
	t0 = Time.get_ticks_usec()
	for c in cells:
		world.set_block(c, BlockIds.GLASS)
	var set_ms := (Time.get_ticks_usec() - t0) / 1000.0
	for conn: Dictionary in listeners:
		world.block_changed.disconnect(conn.callable)
	t0 = Time.get_ticks_usec()
	for c in cells:
		world.set_block(c, BlockIds.AIR)
	var bare_ms := (Time.get_ticks_usec() - t0) / 1000.0
	for conn: Dictionary in listeners:
		world.block_changed.connect(conn.callable, conn.flags)
	var who: Array[String] = []
	for conn: Dictionary in listeners:
		var cb: Callable = conn.callable
		who.append("%s.%s" % [cb.get_object().get_class() if cb.get_object() else "?", cb.get_method()])
	print("BUILD_SMOKE measure 4096 get_ms=%.1f check_ms=%.1f set_ms=%.1f set_without_listeners_ms=%.1f listeners=%s" % [
		get_ms, check_ms, set_ms, bare_ms, ", ".join(who)])
	t0 = Time.get_ticks_usec()
	world.blocks_at(cells)
	var bulk_get_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var glass: Array = cells.map(func(c: Vector3i) -> Array: return [c, BlockIds.GLASS])
	var air: Array = cells.map(func(c: Vector3i) -> Array: return [c, BlockIds.AIR])
	t0 = Time.get_ticks_usec()
	world.set_blocks(glass)
	var bulk_set_ms := (Time.get_ticks_usec() - t0) / 1000.0
	t0 = Time.get_ticks_usec()
	world.set_blocks(air)
	print("BUILD_SMOKE measure 4096 bulk_get_ms=%.1f bulk_set_ms=%.1f bulk_set_back_ms=%.1f (one copy and one paste, every cell announced)" % [
		bulk_get_ms, bulk_set_ms, (Time.get_ticks_usec() - t0) / 1000.0])
	for conn: Dictionary in listeners:   # each listener alone, through real edits (4,096 in, 4,096 out)
		for other: Dictionary in listeners:
			world.block_changed.disconnect(other.callable)
		var cb: Callable = conn.callable
		world.block_changed.connect(cb, conn.flags)
		t0 = Time.get_ticks_usec()
		for c in cells:
			world.set_block(c, BlockIds.GLASS)
		for c in cells:
			world.set_block(c, BlockIds.AIR)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		world.block_changed.disconnect(cb)
		for other: Dictionary in listeners:
			world.block_changed.connect(other.callable, other.flags)
		print("BUILD_SMOKE measure listener %s.%s 8192_edits_ms=%.1f" % [cb.get_object(), cb.get_method(), ms])


## The ruling's numbers: the library (every id below 256), a fresh bake, a chunk's draw calls with paint; Build
## Rewind's preview of 5,000 edits against remeshing their box with the blocky mesher.
func _measure() -> void:
	var t0 := Time.get_ticks_usec()
	var lib := BlockLibrary.build()
	print("BUILD_SMOKE measure library_models=%d bake_ms=%.1f" % [lib.models.size(), (Time.get_ticks_usec() - t0) / 1000.0])
	var r := RewindLog.new()
	r.start(Vector3i.ZERO)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for i in RewindLog.MAX_EDITS:
		var c := Vector3i(rng.randi_range(-30, 30), rng.randi_range(-10, 30), rng.randi_range(-30, 30))
		r.record(c, BlockIds.AIR, [BlockIds.BRICK, BlockIds.PLANKS, BlockIds.GLASS, BlockIds.PAINTED_RED][i % 4])
	var p := RewindPreview.new()
	add_child(p)
	t0 = Time.get_ticks_usec()
	p.setup(r)
	var setup_ms := (Time.get_ticks_usec() - t0) / 1000.0
	t0 = Time.get_ticks_usec()
	p.seek(r.size())
	var all_ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("BUILD_SMOKE measure preview_5000 setup_ms=%.1f all_edits_ms=%.2f per_frame_ms=%.3f draw_calls=%d" % [
		setup_ms, all_ms, all_ms / (RewindLog.MAX_SECONDS * 60.0), p.ids().size()])
	p.free()
	var buf := VoxelBuffer.new()
	buf.create(63, 43, 63)
	var final := r.blocks_after(r.size())
	for pos: Vector3i in final:
		buf.set_voxel(final[pos], pos.x + 31, pos.y + 11, pos.z + 31, VoxelBuffer.CHANNEL_TYPE)
	var mesher := VoxelMesherBlocky.new()
	mesher.library = lib
	t0 = Time.get_ticks_usec()
	var mesh := mesher.build_mesh(buf, [])
	print("BUILD_SMOKE measure remesh_box_63x43x63_ms=%.1f surfaces=%d (one remesh; a time-lapse would need one a step)" % [
		(Time.get_ticks_usec() - t0) / 1000.0, mesh.get_surface_count() if mesh else 0])


func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("BUILD_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("BUILD_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	get_tree().quit(0 if _fails.is_empty() else 1)
