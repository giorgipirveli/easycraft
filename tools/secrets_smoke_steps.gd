extends Node
## The steps of tools/secrets_smoke.gd (M2 Task 16), in a new Sandbox world of seed 12345: goes to the
## nearest buried treasure (the X, the chest under it, opened once), hidden room (the fake wall in the
## generated terrain, a knock opens it), puzzle temple (plates in the note's order open the golden vault),
## calls the Wanderer at dusk (his riddle is rewarded once) and saves the world.

const SEED := 12345
const TIMEOUT := 180.0
const STEP_TIMEOUT := 40.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _rules: SecretRules
var _treasure := {}
var _room := {}
var _temple := {}
var _plate := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var world: WorldService = p.world
	var secrets: SecretDirector = sandbox.get_node("Secrets")
	match _step:
		0:
			_rules = SecretRules.new(SEED, world.generator_shape())   # owner #45b: the world's own terrain
			var home := Vector3(_rules.spawn.x, 40, _rules.spawn.y)
			_treasure = _nearest(home, SecretRules.TREASURE)
			_room = _nearest(home, SecretRules.ROOM)
			_temple = _nearest(home, SecretRules.TEMPLE)
			_check(not _treasure.is_empty() and not _room.is_empty() and not _temple.is_empty(), "found a treasure, a room and a temple near the spawn")
			if _treasure.is_empty() or _room.is_empty() or _temple.is_empty():
				_finish()
				return
			print("SECRETS_SMOKE info treasure=%s room=%s temple=%s" % [_treasure.chest, _room.fake_wall[0], _temple.anchor])
			var c: Vector3i = _treasure.chest
			p.spawn_on_surface(c.x + 2, c.z)
			_next(0.5)
		1:
			if _wait_for(secrets.thing("chest_" + _treasure.id) != null, "the chest came near the player"):
				var c: Vector3i = _treasure.chest
				var top := world.surface_height(c.x, c.z) - 1
				_check(world.get_block(Vector3i(c.x, top, c.z)) == BlockIds.SAND, "an X of pebbles over the treasure")
				_check(world.get_block(c) == BlockIds.AIR, "room for the chest under the X")
				Session.request_open_chest("chest_" + _treasure.id)
				_next(0.5)
		2:
			_check(secrets.state.opened.has(_treasure.id), "the chest opened")
			_check(secrets.state.found.has(_treasure.id), "the buried treasure counts as found")
			_check(sandbox.hud.banner.showing() != "", "a banner: %s" % sandbox.hud.banner.showing())
			var cell: Vector3i = _room.fake_wall[0] + (_room.dir as Vector3i)
			p.spawn_at(Vector3(cell) + Vector3(0.5, 0.0, 0.5))
			_next(0.5)
		3:
			var wall: Vector3i = _room.fake_wall[0]
			if _wait_for(world.is_area_ready(Vector3(wall)), "the hidden room's stairs are loaded"):
				_check(world.get_block(wall) == BlockIds.FAKE_WALL, "the generated fake wall is there")
				_check(world.get_block(_room.chest) == BlockIds.AIR, "the room behind it")
				Session.request_knock(wall)
				_next(0.4)
		4:
			for c: Vector3i in _room.fake_wall:
				_check(world.get_block(c) == BlockIds.AIR, "the knock opened %s" % c)
			_check(secrets.state.found.has(_room.id), "the hidden room is found")
			p.spawn_at(Vector3(_temple.anchor) + Vector3(0.5, 0.0, 0.5))
			_next(0.8)
		5:
			if _wait_for(secrets.state.found.has(_temple.id) and secrets.thing("marks_" + _temple.id) != null,
					"walked into the temple (found, pictures on the plates)"):
				for plate: Vector3i in _temple.plates:
					_check(world.get_block(plate) == BlockIds.PRESSURE_PLATE, "a pressure plate at %s" % plate)
				_check((secrets.thing("chest_" + _temple.id) as TreasureChest).locked, "the vault's chest is locked")
				_plate = 0
				_next(0.2)
		6:
			if _plate < 3:
				var cell: Vector3i = _temple.plates[_temple.order[_plate]]
				p.global_position = Vector3(cell) + Vector3(0.5, BlockLibrary.PLATE_HEIGHT, 0.5)
				p.velocity = Vector3.ZERO
				_plate += 1
				_wait = 0.4
				return
			_next(0.3)
		7:
			_check(secrets.state.solved.has(_temple.id), "the plates in the note's order solve the temple")
			for v: Vector3i in _temple.vault:
				_check(world.get_block(v) == BlockIds.AIR, "the golden vault door opened")
			_check(not (secrets.thing("chest_" + _temple.id) as TreasureChest).locked, "the chest is unlocked")
			var out: Vector3i = (_temple.anchor as Vector3i) + (_temple.dir as Vector3i) * 9   # out of the door
			p.spawn_on_surface(out.x, out.z)
			sandbox.set_time_of_day(DayCycle.DUSK_START - 0.002)
			_next(3.0)
		8:
			var w := secrets.wanderer()
			if _wait_for(w != null, "the Wanderer came at dusk"):
				var r := w.question()
				p.global_position = w.global_position + Vector3(1.5, 0.5, 0)
				Session.request_wanderer_answer(w.name, int(r.answer))
				_next(0.5)
		9:
			_check(secrets.state.wanderer_rewarded == secrets.state.dusks, "the right answer was rewarded")
			_check(secrets.wanderer() == null, "and he vanished")
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.secrets.opened.has(_treasure.id) and meta.secrets.solved.has(_temple.id), "saved with the world")
			_check(int(Profile.data.secret_book.get("temple", 0)) > 0, "the Secret Book has the temple")
			_check(secrets.book_counts().x >= 3, "found %s of the explored places' secrets" % secrets.book_counts())
			_finish()


## Checks `ok` only when the step has waited long enough; returns ok (the step may go on).
func _wait_for(ok: bool, what: String) -> bool:
	if ok:
		_check(true, what)
	elif _step_t > STEP_TIMEOUT - 1.0:
		_check(false, what)
		_finish()
	return ok


func _nearest(from: Vector3, kind: StringName) -> Dictionary:
	var best := {}
	var best_d := INF
	for s: Dictionary in _rules.secrets_near(from, 700.0):
		var d := Vector2(s.anchor.x - from.x, s.anchor.z - from.z).length()
		if s.kind == kind and d < best_d:
			best_d = d
			best = s
	return best


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("SECRETS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("SECRETS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)
