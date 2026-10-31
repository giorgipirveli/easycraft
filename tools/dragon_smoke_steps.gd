extends Node
## The steps of tools/dragon_smoke.gd (owner feedback #39), in a new Survivor world of universe 5 (the Dragon Realm,
## Cozy), through the real systems: the player stands on the home island's sky grass with the realm's rules (its
## secrets, the void); a crystal spire and a giant mushroom stand near the spawn; the nearest dragon nest is really
## there with its egg's cell (air on a nest block), and its egg hatches into the child's pet dragon (the lead, owner
## 39's egg); the player pushed off the island's edge falls below
## DragonRules.RESCUE_Y and the wind carries it back onto the island ("Whoosh!"); a monster that falls into the void
## puffs away and a sheep comes back beside the player (the host's VoidWatch); the arena of universe 5 is flat. It
## ends with a short cost window on the home island.

const TIMEOUT := 300.0
const U := 5

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _first := true
var _fails: Array[String] = []
var _plants := {}
var _nest := {}
var _safe := Vector3.INF
var _low := INF
var _carried: Array = []
var _monster: Monster
var _sheep: Animal
var _frames: Array[Vector2] = []
var _stood := 0.0
var _egg_phase := 0   # the lead's addition: 0 check the cell, 1 find the egg, 2 its dragon hatched


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = U
	Game.new_world_difficulty = DifficultyRules.COZY
	Game.start_new_world = true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("DRAGON_SMOKE begin universe=%d" % Game.universe)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null:
		return
	var p: Player = sandbox.player
	if _step == 4 and _step_t > 0.0:
		_low = minf(_low, p.global_position.y)   # the fall is watched while the player is not spawned too
	if not p.is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	var first := _first
	_first = false
	_run_step(sandbox, first)


func _run_step(sandbox: Node, first: bool) -> void:
	var p: Player = sandbox.player
	var w: WorldService = sandbox.world
	var shape := w.generator_shape() as DragonShape
	var secrets := sandbox.get_node("Secrets") as SecretDirector
	var monsters := sandbox.get_node("Monsters") as MonsterDirector
	match _step:
		0:
			print("DRAGON_SMOKE info seed=%d spawn=%s" % [sandbox.meta.seed, Vector3i(p.global_position.floor())])
			_check(w.universe == U and shape != null, "a Dragon Realm world (universe %d)" % w.universe)
			var feet := Vector3i(p.global_position.floor())
			_check(w.get_block(feet + Vector3i.DOWN) == BlockIds.SKY_GRASS, "standing on sky grass (block %d)" % w.get_block(feet + Vector3i.DOWN))
			_check(shape.is_island(feet.x, feet.z) and Vector2(feet.x - shape.home.x, feet.z - shape.home.y).length() < 30.0,
				"on the home island")
			_check(p.in_void_world(), "this world floats over the void")
			_check(sandbox.get("void_watch") != null, "the host watches the void")
			_check(secrets.rules is DragonSecretRules, "its secrets are the realm's")
			p.carried_back.connect(func(to: Vector3) -> void: _carried.append(to))
			_next(0.0)
		1:
			if first:
				var s := shape.spawn_column()
				for r in range(4, 72):
					for i in maxi(r * 6, 1):
						var a := TAU * i / maxi(r * 6, 1)
						var x := s.x + roundi(cos(a) * r)
						var z := s.y + roundi(sin(a) * r)
						var kind := shape.plant_at(x, z)
						if kind != DragonShape.NO_PLANT and not _plants.has(kind):
							_plants[kind] = Vector3i(x, shape.height_at(x, z), z)
			var ready := true
			for kind: int in _plants:
				ready = ready and w.is_editable(_plants[kind])
			if not ready and _step_t < 25.0:
				return
			for kind: int in [DragonShape.SPIRE, DragonShape.MUSHROOM]:
				var at: Vector3i = _plants.get(kind, Vector3i.MAX)
				var want := BlockIds.CRYSTAL_SPIRE if kind == DragonShape.SPIRE else BlockIds.MUSHROOM_STEM
				_check(at != Vector3i.MAX and w.get_block(at) == want,
					"a %s near the spawn at %s" % [BlockIds.display_name(want), at])
			_next(0.0)
		2:
			if first:
				_nest = _nearest_secret(secrets.rules, p.global_position, SecretRules.ISLAND)
				if _nest.is_empty():
					_check(false, "a dragon nest nearby")
					_step = 3
					return
				print("DRAGON_SMOKE info nest=%s egg=%s" % [_nest.id, _nest.egg])
				_safe = p.global_position
				p.spawn_at(Vector3(_nest.chest as Vector3i) + Vector3(-0.5, 0.0, 0.5) + Vector3(1, 0, 0))
				return
			var egg: Vector3i = _nest.egg
			if _egg_phase == 0:
				if not (w.is_editable(egg) and w.is_editable(egg + Vector3i.DOWN)) and _step_t < 25.0:
					return
				_check(w.get_block(egg) == BlockIds.AIR and w.get_block(egg + Vector3i.UP) == BlockIds.AIR,
					"the nest's egg cell is free (%d)" % w.get_block(egg))
				_check(w.get_block(egg + Vector3i.DOWN) == BlockIds.NEST, "the egg lies on the nest")
				_check(SecretRules._contains(_nest.inside[0], _nest.inside[1], egg), "inside the nest island's box")
				p.spawn_at(Vector3(egg) + Vector3(0.5, 0.0, 0.5))   # the egg is a tap box: the child stands by it
				_egg_phase = 1
				_step_t = 0.0
				return
			var thing := secrets.thing("egg_" + str(_nest.id))
			if _egg_phase == 1:
				if thing == null and _step_t < 30.0:
					return
				_check(thing is DragonEgg, "the nest's dragon egg is there to tap")
				if thing:
					Session.request_hatch(String(thing.name))   # a tap on the egg (SecretTaps: use_tap)
				_egg_phase = 2
				_step_t = 0.0
				return
			var pets := sandbox.get_node("Pets") as PetDirector
			var dragon: Animal = null
			for a in pets.pets_of(p.peer_id):
				if a.species == PetRules.DRAGON:
					dragon = a
			if dragon == null and _step_t < 5.0:
				return
			_check(dragon != null, "the egg hatched into the child's pet dragon")
			_check(secrets.state.opened.has(DragonNests.key_of(str(_nest.id))), "once: the world remembers it hatched")
			_check(secrets.thing("egg_" + str(_nest.id)) == null or secrets.thing("egg_" + str(_nest.id)).is_queued_for_deletion(),
				"the egg is gone")
			if dragon:
				dragon.sitting = true   # it waits on its nest: the void checks below are the player's own
			p.spawn_at(_safe)
			_next(1.0)
		3:
			var under := w.get_block(Vector3i((p.global_position + Vector3(0, -0.05, 0)).floor()))
			if not (p.is_on_floor() and BlockIds.is_solid(under)):
				_stood = 0.0   # still landing (a far teleport can land before the collision is built: the wind helps)
			_stood += get_process_delta_time()
			if _stood < 1.0 and _step_t < 30.0:
				return
			_check(_stood >= 1.0, "standing on the island before the push")
			var from := Vector3i(p.global_position.floor())
			var edge := Vector3i.MAX
			for r in range(2, 200):
				if not shape.is_island(from.x + r, from.z) and not shape.is_island(from.x + r + 1, from.z):
					edge = Vector3i(from.x + r + 1, from.y, from.z)
					break
			print("DRAGON_SMOKE info safe=%s void=%s" % [Vector3i(p.global_position.floor()), edge])
			_safe = p.global_position
			p.global_position = Vector3(edge) + Vector3(0.5, 1.0, 0.5)   # pushed off the island's edge
			p.velocity = Vector3.ZERO
			_low = INF
			if not _carried.is_empty():
				print("DRAGON_SMOKE info the wind already caught %d fall(s) (a far teleport landed before its collision)" % _carried.size())
			_carried.clear()
			_next(0.0)
		4:
			if _carried.is_empty() and _step_t < 15.0:
				return
			_check(_low < DragonShape.MIN_BOTTOM, "fell into the void, under every island (down to y %.1f, the line at %.0f)" % [
				_low, DragonRules.RESCUE_Y])
			_check(not _carried.is_empty(), "the wind carried the player back")
			var feet := Vector3i(p.global_position.floor())
			_check(BlockIds.is_solid(w.get_block(feet + Vector3i.DOWN)) and shape.is_island(feet.x, feet.z),
				"back on the island at %s" % feet)
			_check(Vector2(p.global_position.x - _safe.x, p.global_position.z - _safe.z).length() < 1.5,
				"where it last stood (%s, stood at %s)" % [feet, Vector3i(_safe.floor())])
			var toast := sandbox.hud.get("_toast_label") as Label
			_check(toast != null and toast.text == DragonRules.CARRIED_BACK, "it says \"%s\"" % (toast.text if toast else ""))
			_check(not p.knocked_out, "no knock-out")
			_next(0.5)
		5:
			if first:
				_check(monsters.summon(MonsterRules.SLIME, 1, p.global_position) == "", "a monster was summoned")
				_monster = monsters.monsters()[-1]
				_monster.global_position = Vector3(p.global_position.x + 40.0, DragonRules.RESCUE_Y - 2.0, p.global_position.z)
				_check(sandbox.summon_animal(&"sheep", p.global_position) == "", "a sheep was summoned")
				for a: Animal in sandbox.call("_animal_nodes"):
					_sheep = a
				_sheep.global_position = Vector3(p.global_position.x - 40.0, DragonRules.RESCUE_Y - 3.0, p.global_position.z)
				return
			if _step_t < 1.0:
				return
			_check(not is_instance_valid(_monster) or _monster.is_queued_for_deletion(), "the monster in the void puffed away")
			_check(is_instance_valid(_sheep) and Vector2(_sheep.global_position.x - p.global_position.x,
				_sheep.global_position.z - p.global_position.z).length() < 4.0 and _sheep.global_position.y > DragonRules.RESCUE_Y,
				"the sheep came back beside the player (%s)" % (Vector3i(_sheep.global_position.floor()) if is_instance_valid(_sheep) else Vector3i.ZERO))
			_next(0.0)
		6:
			var arena := ArenaShape.new(sandbox.meta.seed, U)
			var flat := true
			for i in 40:
				flat = flat and arena.height_at(i * 37 - 700, 500 - i * 29) == ArenaShape.FLOOR
			_check(flat and arena.palette.top == BlockIds.SKY_GRASS, "the arena of universe 5 is flat sky grass")
			_check(not DragonRules.world_has_void(w.descriptor(), true), "the arena has no void")
			_next(0.0)
		7:
			_frames.append(Vector2(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
				Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
			if _step_t < 4.0:
				return
			var total := Vector2.ZERO
			var worst := Vector2.ZERO
			for f in _frames:
				total += f
				worst = Vector2(maxf(worst.x, f.x), maxf(worst.y, f.y))
			var avg := total / maxf(_frames.size(), 1.0)
			print("DRAGON_SMOKE cost frames=%d physics_avg_ms=%.2f physics_worst_ms=%.2f process_avg_ms=%.2f process_worst_ms=%.2f" % [
				_frames.size(), avg.x, worst.x, avg.y, worst.y])
			_finish()


func _nearest_secret(rules: SecretRules, from: Vector3, kind: StringName) -> Dictionary:
	var best := {}
	var best_d := INF
	for s: Dictionary in rules.secrets_near(from, 400.0):
		if s.kind != kind:
			continue
		var d := Vector2(s.anchor.x - from.x, s.anchor.z - from.z).length()
		if d < best_d:
			best_d = d
			best = s
	return best


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0
	_first = true


func _check(ok: bool, what: String) -> void:
	print("DRAGON_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("DRAGON_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(1 if not _fails.is_empty() else 0))
