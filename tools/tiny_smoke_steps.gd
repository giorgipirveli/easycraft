extends Node
## The steps of tools/tiny_smoke.gd (M3 Task 21c), in a new Sandbox world of seed 12345 with the real terrain, physics,
## spawner and save: the nearest mouse village is in the generated terrain (its door, its lintel, the pumpkin by it);
## a normal-size child walking at the door stays outside; a tiny child walks in through it and finds the village;
## the mouse family and the tiny chest come; the chest holds the cheese; the wand wakes it as a chest mimic that hops,
## gives a present and goes back to sleep; a child who grows in the room is shown out; a pumpkin wakes as a pumpkin
## buddy; /secret mice; the save.

const SEED := 12345
const TIMEOUT := 240.0
const STEP_TIMEOUT := 40.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _village := {}
var _walk_t := 0.0
var _mimic_seen := false
var _pumpkin := Vector3i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Session.magic_feedback.connect(func(text: String) -> void: print("TINY_SMOKE said %s" % text))
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Game.new_world_seed = SEED
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	_step_t += delta
	if _t > TIMEOUT or _step_t > STEP_TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_run_step(sandbox, delta)


func _run_step(sandbox: Node, delta: float) -> void:
	var p: Player = sandbox.player
	var world: WorldService = p.world
	var secrets: SecretDirector = sandbox.get_node("Secrets")
	match _step:
		0:
			var rules := secrets.rules
			var home := Vector3(rules.spawn.x, 40, rules.spawn.y)
			var best := INF
			for s: Dictionary in rules.tiny_near(home, 700.0):
				var d := Vector2(s.anchor.x - home.x, s.anchor.z - home.z).length()
				if d < best:
					best = d
					_village = s
			_check(not _village.is_empty(), "a mouse village near the spawn (terrain %d)" % world.terrain_version)
			if _village.is_empty():
				_finish()
				return
			print("TINY_SMOKE info village=%s variant=%s door=%s dir=%s distance=%d" % [_village.id, _village.variant,
				_village.door, _village.dir, roundi(best)])
			p.spawn_at(_at(_village.visit) + Vector3(0, 0.2, 0))
			_next(1.0)
		1:
			var ready: bool = world.is_area_ready(Vector3(_village.anchor)) and world.is_area_ready(Vector3(_village.visit)) \
				and world.is_area_ready(Vector3(_village.lo)) and world.is_area_ready(Vector3(_village.hi) - Vector3.ONE)
			if _wait_for(ready, "the village's terrain is loaded"):
				var door: Vector3i = _village.door
				_check(world.get_block(door) == BlockIds.AIR, "the door is open")
				_check(BlockIds.is_solid(world.get_block(door + Vector3i.UP)), "and one block high")
				_check(world.get_block(_village.markers[0]) == BlockIds.PUMPKIN, "a pumpkin by the door")
				_check(world.get_block(_village.anchor) == BlockIds.AIR, "the room")
				var wrong := 0
				var cells := 0
				for b: Array in _village.boxes:
					var lo: Vector3i = b[0]
					var hi: Vector3i = b[1]
					for x in range(lo.x, hi.x):
						for y in range(lo.y, hi.y):
							for z in range(lo.z, hi.z):
								var c := Vector3i(x, y, z)
								cells += 1
								if world.get_block(c) != secrets.rules.block_at(c):
									wrong += 1
				_check(wrong == 0, "every block of the village is in the generated terrain (%d cells, %d differ)" % [cells, wrong])
				_face(p, _village.dir)
				_walk_t = 0.0
				Input.action_press(&"move_forward")
				_next(0.0)
		2:   # a normal-size child walks at the door for 3 s: it stays outside
			_walk_t += delta
			if _walk_t < 3.0:
				return
			Input.action_release(&"move_forward")
			var along := _along(p.global_position)
			_check(along < 0.8, "a normal-size child stays outside the tiny door (along %.2f)" % along)
			p.set_size_mode(SizeMagic.Mode.TINY)
			p.spawn_at(_at(_village.visit) + Vector3(0, 0.1, 0))
			_next(0.6)
		3:
			_face(p, _village.dir)
			_walk_t = 0.0
			Input.action_press(&"move_forward")
			_next(0.0)
		4:   # the tiny child walks in
			_walk_t += delta
			var feet := Vector3i(p.global_position.floor())
			var room: Array = _village.room
			if SecretRules._contains(room[0], room[1], feet) and _along(p.global_position) >= float(MouseVillages.MIDDLE) - 0.5:
				Input.action_release(&"move_forward")
				_check(true, "a tiny child walks through the door into the room (%.1f s)" % _walk_t)
				_next(1.2)
			elif _walk_t > 12.0:
				Input.action_release(&"move_forward")
				_check(false, "a tiny child walks into the room (stuck at %s, along %.2f)" % [p.global_position, _along(p.global_position)])
				_finish()
		5:
			var family := secrets.thing("mice_" + _village.id) as MouseFamily
			var chest := secrets.thing("chest_" + _village.id) as TreasureChest
			if _wait_for(family != null and chest != null, "the mouse family and the tiny chest are there"):
				_check(secrets.state.found.has(_village.id), "walking in found the mouse village")
				_check(int(Profile.data.secret_book.get(String(MouseVillages.KIND), 0)) > 0, "the Secret Book has it")
				_check(absf(chest.scale.x - MouseVillages.CHEST_SCALE) < 0.01, "a tiny chest")
				_check(family.greeting(), "the mice wave at the tiny child")
				Session.request_open_chest(chest.name)
				_check(Profile.data.treasures.has(BlockIds.CHEESE), "the mice's cheese on the Secret Book's shelf")
				var i: BlockInteractor = p.get_node("BlockInteractor")
				i.set_slot_block(i.selected_slot, ItemIds.WAND)
				Session.request_wake_chest(chest.name)
				_next(0.3)
		6:
			var mimic := secrets.thing("mimic_" + _village.id) as ChestMimic
			_mimic_seen = _mimic_seen or mimic != null
			if not _mimic_seen:
				_wait_for(false, "the wand wakes the opened chest")
				return
			if mimic == null:
				_check(true, "the chest mimic hopped, gave its present and went back to sleep")
				_check(secrets.state.solved.has(TinyDirector.mimic_key(_village.id)), "once per chest")
				var chest := secrets.thing("chest_" + _village.id) as TreasureChest
				_check(chest != null and chest.visible, "the still chest is back")
				p.set_size_mode(SizeMagic.Mode.NORMAL)   # grows in the room
				_next(1.2)
		7:
			_check(_along(p.global_position) < 0.0, "a child who grows in the mice's room is shown out (along %.2f)" %
				_along(p.global_position))
			_pumpkin = _lone_spot(world)
			p.spawn_at(_at(_village.visit) + Vector3(0, 0.1, 0))
			_next(0.6)
		8:
			_check(Session.request_set_block(_pumpkin, BlockIds.PUMPKIN), "a pumpkin placed")
			_next(0.3)
		9:
			_check(world.get_block(_pumpkin) == BlockIds.PUMPKIN, "the pumpkin is in the world at %s" % _pumpkin)
			var got := CaptureRules.capture(_pumpkin, world.get_block)
			var ids := {}
			for c: Vector3i in got.get("blocks", {}):
				ids[BlockIds.display_name(got.blocks[c])] = int(ids.get(BlockIds.display_name(got.blocks[c]), 0)) + 1
			print("TINY_SMOKE info the wand would take %s %s" % [ids, got.get("error", "")])
			Session.request_spark(_pumpkin)
			_next(0.5)
		10:
			var woke: Buddy = null
			for b in sandbox.get_node("Buddies").get_children():
				if b is Buddy and (b as Buddy).wake_kind == WakeKinds.PUMPKIN:
					woke = b
			_check(woke != null and WakeKinds.NAMES[WakeKinds.PUMPKIN].has(woke.buddy_name), "the wand wakes a pumpkin buddy (%s)" %
				(woke.buddy_name if woke else "none"))
			var line := secrets.hint(MouseVillages.KIND, Vector3(rulesless_spawn(secrets)))
			_check(line.begins_with("Nearest mouse village:") or line.begins_with("No mouse village"), "/secret mice: %s" % line)
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.secrets.found.has(_village.id), "the find is saved")
			_check(meta.secrets.solved.has(TinyDirector.mimic_key(_village.id)), "the mimic's present is saved")
			_finish()


## A doorstep cell whose sides and top touch nothing the wand takes along (a tree next to the doorstep would wake
## with the pumpkin, and then it is a tree).
func _lone_spot(world: WorldService) -> Vector3i:
	var dir: Vector3i = _village.dir
	var side := Vector3i(-dir.z, 0, dir.x)
	for along in [3, 1, 2]:
		for across in [-1, 1, 0]:
			var c: Vector3i = (_village.door as Vector3i) - dir * along + side * across
			if c == (_village.visit as Vector3i):
				continue
			var alone := true
			for n: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK, Vector3i.UP]:
				alone = alone and not CaptureRules.is_capturable(world.get_block(c + n))
			if alone:
				return c
	return (_village.door as Vector3i) - dir * 3


func rulesless_spawn(secrets: SecretDirector) -> Vector3:
	return Vector3(secrets.rules.spawn.x, 40, secrets.rules.spawn.y)


func _at(cell: Vector3i) -> Vector3:
	return Vector3(cell) + Vector3(0.5, 0.0, 0.5)


## How far into the hill a point is, from the door (0 = the door's cell), along the village's dir.
func _along(pos: Vector3) -> float:
	var door := _at(_village.door)
	var d := pos - door
	return Vector3(_village.dir).dot(Vector3(d.x, 0, d.z))


## Turns the camera (and so "forward") to face along dir.
func _face(p: Player, dir: Vector3i) -> void:
	p.rig.yaw = atan2(-float(dir.x), -float(dir.z))


func _wait_for(ok: bool, what: String) -> bool:
	if ok:
		_check(true, what)
	elif _step_t > STEP_TIMEOUT - 1.0:
		_check(false, what)
		_finish()
	return ok


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("TINY_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	Input.action_release(&"move_forward")
	print("TINY_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Audio.stop_all()
	Music.reset()
	get_tree().quit.call_deferred(1 if not _fails.is_empty() else 0)
