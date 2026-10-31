extends Node
## The steps of tools/portals_smoke.gd (owner feedback #39), on real terrain through the real systems: the host's
## edits build portal frames, a child's placed core goes through Session (in Survivor paid with the crystal from the
## bag), the PortalDirector sees them, walking into a doorway travels, and the destination builds its portal back.

const TIMEOUT := 300.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _left: Node
var _gate_lo := Vector3i.ZERO     # the first portal's doorway (its lowest opening cell)
var _gate_exit := Vector3.INF


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Profile.data.universe_unlocked = 2
	Profile.data.crystals_given = 0
	Profile.data.crystal_gifts.clear()
	WorldSaves.delete(ModeRules.slot(ModeRules.SANDBOX, 2))
	WorldSaves.delete(ModeRules.slot(ModeRules.SURVIVOR, 2))
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("PORTALS_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if sandbox != _scene:
		_scene = sandbox
		_wait = 1.5   # a new world: let it settle (and build its portal back)
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var frames: PortalDirector = sandbox.get_node("PortalFrames")
	match _step:
		0:
			_check(Game.mode == ModeRules.SANDBOX and Game.slot() == "sandbox_1", "Green Meadows' Sandbox world (%s)" % Game.slot())
			var feet := Vector3i(p.global_position.floor())
			_gate_lo = feet + Vector3i(0, 0, -3)
			_build_frame(p.world, _gate_lo)
			var placed := Session.request_set_block(_gate_lo + Vector3i.DOWN, BlockIds.CORE_DESERT)   # the child's crystal
			_check(placed, "the Desert Crystal's core goes into the frame's core slot through the host")
			_next(0.6)
		1:
			var core := _gate_lo + Vector3i.DOWN
			_check(frames.gates.works(core) and frames.gates.universe_of(core) == 2, "a universe portal to the desert")
			_check(frames.swirls().size() == 1 and frames.swirls()[0].material_override == PortalSwirl.material_for(2),
				"it swirls in the desert's colours")
			_gate_exit = frames.gates.shape_of(core).get("exit", Vector3.INF)
			sandbox.call("save_world")
			p.global_position = Vector3(_gate_lo) + Vector3(0.5, 0.05, 0.5)
			_left = sandbox
			_next(0.1)
		2:
			if sandbox == _left:
				if _step_t > 8.0:
					_check(false, "walking into the portal travelled")
					_finish()
				return
			_check(Game.mode == ModeRules.SANDBOX and Game.universe == 2 and Game.slot() == "sandbox_2",
				"the desert's own Sandbox world (%s, universe %d)" % [Game.slot(), Game.universe])
			_check(p.world.universe == 2, "its world is the desert's")
			var monsters: MonsterDirector = sandbox.get_node("Monsters")
			_check(monsters.universe == 1, "Sandbox never scales (%d)" % monsters.universe)
			var back: Variant = frames.gates.gate_to(1)
			_check(back != null, "a portal back to Green Meadows stands at the arrival point (%s)" % str(frames.gates.to_save()))
			if back == null:
				_finish()
				return
			var shape := frames.gates.shape_of(back)
			var d := Vector2(PortalRules.center(shape).x - p.global_position.x, PortalRules.center(shape).z - p.global_position.z).length()
			_check(d < 6.0, "a few steps from the child (%.1f)" % d)
			_check(p.world.get_block(back) == BlockIds.CORE_MEADOWS, "with the Meadows Crystal's core")
			p.global_position = Vector3(shape.lo as Vector3i) + Vector3(0.5, 0.05, 0.5)
			_left = sandbox
			_next(0.1)
		3:
			if sandbox == _left:
				if _step_t > 8.0:
					_check(false, "walking into the portal back travelled")
					_finish()
				return
			_check(Game.slot() == "sandbox_1", "back in Green Meadows' Sandbox world (%s)" % Game.slot())
			var d := p._spawn_target.distance_to(_gate_exit) if _gate_exit.is_finite() else INF
			_check(d < 0.5, "out in front of the portal to the desert, not at the spawn (%.2f)" % d)
			_next(0.5)
		4:
			Profile.data.universe_unlocked = 2
			Profile.data.crystals_given = 0
			Session.close()
			Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.COZY, 1)
			_left = sandbox
			_next(0.1)
		5:
			if sandbox == _left:
				return
			var bag := Session.inventory_of(p.peer_id)
			_check(bag.count(ItemIds.CRYSTAL_MEADOWS) == 1 and bag.count(ItemIds.CRYSTAL_DESERT) == 1,
				"the crystals of the universes reached came into the bag (%d, %d)" % [bag.count(ItemIds.CRYSTAL_MEADOWS),
				bag.count(ItemIds.CRYSTAL_DESERT)])
			_check(Profile.data.crystals_given == 2, "once (%d)" % Profile.data.crystals_given)
			bag.add(ItemIds.SWORD_COSMIC, 1)
			bag.add(BlockIds.PORTAL_FRAME, 10)
			var feet := Vector3i(p.global_position.floor())
			_gate_lo = feet + Vector3i(0, 0, -3)
			_build_frame(p.world, _gate_lo)
			var placed := Session.request_set_block(_gate_lo + Vector3i.DOWN, BlockIds.CORE_DESERT)
			_check(placed and bag.count(ItemIds.CRYSTAL_DESERT) == 0, "placing the desert's core used the Desert Crystal (%d left)" % bag.count(ItemIds.CRYSTAL_DESERT))
			_next(0.6)
		6:
			_check(frames.gates.works(_gate_lo + Vector3i.DOWN), "a universe portal in Survivor")
			p.global_position = Vector3(_gate_lo) + Vector3(0.5, 0.05, 0.5)
			_left = sandbox
			_next(0.1)
		7:
			if sandbox == _left:
				if _step_t > 8.0:
					_check(false, "walking into the Survivor portal travelled")
					_finish()
				return
			_check(Game.mode == ModeRules.SURVIVOR and Game.slot() == "survivor_u2", "the desert's Survivor world (%s)" % Game.slot())
			var bag := Session.inventory_of(p.peer_id)
			_check(bag.count(ItemIds.SWORD_COSMIC) == 1, "the bag came along")
			_check(frames.gates.gate_to(1) != null, "a portal back to Green Meadows stands at the arrival point")
			_next(1.0)
		8:
			_finish()


## A 1 x 2 doorway along X whose lowest opening cell is `lo` (the host sets the frames like a child's edits would;
## the core goes through Session): frames round it, the doorway and the cells in front of and behind it open.
func _build_frame(world: WorldService, lo: Vector3i) -> void:
	for dy in range(-1, 3):
		for dx in range(-1, 2):
			var c := lo + Vector3i(dx, dy, 0)
			var inside := dx == 0 and dy >= 0 and dy <= 1
			var core := dx == 0 and dy == -1   # left open: the child's crystal goes there
			world.set_block(c, BlockIds.AIR if inside or core else BlockIds.PORTAL_FRAME)
	for dz in [-1, 1]:
		world.set_block(lo + Vector3i(0, 0, dz), BlockIds.AIR)
		world.set_block(lo + Vector3i(0, 1, dz), BlockIds.AIR)
		world.set_block(lo + Vector3i(0, -1, dz), BlockIds.STONE)


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("PORTALS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("PORTALS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
