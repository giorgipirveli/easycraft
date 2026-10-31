extends Node
## The steps of tools/treasure_smoke.gd (owner feedback #42), in a new Sandbox world of seed 12345, with the
## real terrain, spawner, smart blocks and save: a campsite (its tent in the generated terrain, the supply
## chest opens once), a dungeon vault (the generated levers flipped by real taps in the note's order open the
## golden door; the legendary chest), a friendly haunted house (the ghosts come, the right answer opens the
## chest), a wishing well (a wish once a day), a rainbow (/secret rainbow; walking to the pot finds it) and the
## save.

const SEED := 12345
const TIMEOUT := 240.0
const STEP_TIMEOUT := 40.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _rules: SecretRules
var _camp := {}
var _vault := {}
var _haunted := {}
var _well := {}
var _lever := 0


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
			_camp = _nearest(home, TreasurePlaces.CAMP)
			_vault = _nearest(home, TreasurePlaces.VAULT)
			_haunted = _nearest(home, TreasurePlaces.HAUNTED)
			_well = _nearest(home, TreasurePlaces.WELL)
			var all := not _camp.is_empty() and not _vault.is_empty() and not _haunted.is_empty() and not _well.is_empty()
			_check(all, "found a campsite, a vault, a haunted house and a well near the spawn")
			if not all:
				_finish()
				return
			print("TREASURE_SMOKE info camp=%s vault=%s haunted=%s well=%s" % [_camp.anchor, _vault.anchor, _haunted.anchor, _well.well])
			p.spawn_at(Vector3(_camp.visit) + Vector3(0.5, 0.2, 0.5))
			_next(0.5)
		1:
			var chest_name: String = "chest_" + _camp.id
			if _wait_for(secrets.thing(chest_name) != null and world.is_area_ready(Vector3(_camp.chest)), "the camp's chest came near"):
				var cloth := _cloth_cell(_camp)
				_check(world.get_block(cloth) in [BlockIds.RED, BlockIds.YELLOW], "the tent is in the generated terrain")
				_check((secrets.thing(chest_name) as TreasureChest).rarity == ItemRarity.COMMON, "a common chest")
				p.spawn_at(Vector3(_camp.chest) + Vector3(0.5, 0.2, 2.5))
				_next(0.4)
		2:
			Session.request_open_chest("chest_" + _camp.id)
			_check(secrets.state.opened.has(_camp.id), "the supply chest opened")
			var hall := _hall_spot(_vault)
			p.spawn_at(hall)
			_next(0.8)
		3:
			var marks := secrets.thing("levers_" + _vault.id)
			if _wait_for(marks != null and world.is_area_ready(Vector3(_vault.levers[0])), "the vault's lever pictures came near"):
				for cell: Vector3i in _vault.levers:
					_check(world.get_block(cell) == BlockIds.LEVER, "a generated lever at %s" % cell)
				for cell: Vector3i in _vault.vault:
					_check(world.get_block(cell) == BlockIds.YELLOW, "the golden door at %s" % cell)
				_check((secrets.thing("chest_" + _vault.id) as TreasureChest).locked, "the legendary chest is locked")
				_lever = 0
				_next(0.4)
		4:
			if _lever < 3:
				var cell: Vector3i = _vault.levers[_vault.order[_lever]]
				_check(Session.request_smart_tap(cell), "a tap flips lever %d" % _vault.order[_lever])
				_lever += 1
				_wait = 0.4
				return
			_next(0.4)
		5:
			_check(secrets.state.solved.has(_vault.id), "the levers in the note's order open the vault")
			for v: Vector3i in _vault.vault:
				_check(world.get_block(v) == BlockIds.AIR, "the golden door opened")
			var chest := secrets.thing("chest_" + _vault.id) as TreasureChest
			_check(chest != null and not chest.locked, "the chest is unlocked")
			p.spawn_at(Vector3(_vault.chest) + Vector3(0.5, 0.2, 0.5) - Vector3(_vault.dir) * 2)
			_next(0.4)
		6:
			Session.request_open_chest("chest_" + _vault.id)
			_check(secrets.state.opened.has(_vault.id), "the vault's chest opened")
			_check(Profile.data.treasures.has(BlockIds.TROPHY), "a golden trophy on the Secret Book's shelf")
			p.spawn_at(_center(_haunted.inside) + Vector3(0.5, 0.2, 0.5))
			_next(0.8)
		7:
			var ghost := secrets.thing("ghost_%s_0" % _haunted.id) as FriendlyGhost
			if _wait_for(ghost != null, "a friendly ghost floats in the house"):
				_check((secrets.thing("chest_" + _haunted.id) as TreasureChest).locked, "the house's chest is locked")
				Session.request_wanderer_answer(ghost.name, int(ghost.question().answer))
				_next(0.3)
		8:
			_check(secrets.state.solved.has(_haunted.id), "the ghost's riddle opened the chest")
			p.spawn_at(Vector3(_well.visit) + Vector3(0.5, 0.2, 0.5))
			_next(0.8)
		9:
			var well := secrets.thing("well_" + _well.id)
			if _wait_for(well != null, "the wishing well came near"):
				_check(world.get_block(Vector3i(_well.well) + Vector3i.DOWN) == BlockIds.WATER, "water in the well")
				Session.request_wish(well.name)
				_next(0.3)
		10:
			_check(secrets.state.found.has(_well.id), "a wish finds the well")
			_check(not TreasureRules.may_wish(secrets.state.more.wishes, secrets.treasures.player_key(p.peer_id),
				secrets.state.more.dawns), "one wish a day")
			var line := secrets.hint(TreasurePlaces.RAINBOW, p.global_position)
			_check(line.contains("rainbow"), "/secret rainbow: %s" % line)
			_next(0.5)
		11:
			var pot := secrets.thing("pot_%d" % secrets.state.more.rainbows)
			if _wait_for(pot != null and secrets.thing("rainbow_%d" % secrets.state.more.rainbows) != null, "a rainbow and its pot"):
				var at := pot.global_position
				p.spawn_at(Vector3(at.x, world.find_standing_y(floori(at.x), floori(at.z)), at.z))
				_next(1.2)
		12:
			_check(int(Profile.data.secret_book.get("rainbow", 0)) > 0, "walking to the pot finds it")
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.secrets.solved.has(_vault.id) and meta.secrets.solved.has(_haunted.id), "solved places saved")
			_check(meta.secrets.more.rainbows >= 1, "the rainbows saved")
			for kind in ["camp", "vault", "haunted", "well"]:
				_check(int(Profile.data.secret_book.get(kind, 0)) > 0, "the Secret Book has the %s" % kind)
			_finish()


## A tent cell of a camp (from its boxes).
func _cloth_cell(s: Dictionary) -> Vector3i:
	for b: Array in s.boxes:
		if int(b[2]) in [BlockIds.RED, BlockIds.YELLOW]:
			return b[0]
	return s.anchor


## A spot in a vault's hall two blocks from its levers' wall.
func _hall_spot(s: Dictionary) -> Vector3:
	var mid: Vector3i = (s.levers as Array)[1]
	return Vector3(mid + (s.side as Vector3i) * 2 + Vector3i.DOWN) + Vector3(0.5, 0.1, 0.5)


func _center(box: Array) -> Vector3:
	var lo: Vector3i = box[0]
	var hi: Vector3i = box[1]
	return Vector3(floori((lo.x + hi.x) / 2.0), lo.y, floori((lo.z + hi.z) / 2.0))


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
	print("TREASURE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("TREASURE_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)
