extends Node
## The steps of tools/action_kit_smoke.gd (M3 Task 14b), in a new Survivor world (Cozy), through the real
## systems (Session's checks, the BlasterDirector's pool, the MonsterDirector, the DropDirector): foam darts
## defeat a summoned goblin and use up ammo; a bubble traps a level 2 goblin; a summoned goblin archer backs
## off, draws its bow and hits the player standing still; a Party Piñata floats down 8-30 blocks away, lands
## and bursts after 3 hits into supplies; a supply balloon comes in a wave from 3, settles by the Totem and
## pops into ammo and a potion; then a cost window: foam darts at 8 monsters for 5 s.

const TIMEOUT := 300.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _m: Monster
var _hp_before := 0
var _count_before := 0
var _winding_seen := false
var _arrow_seen := false
var _pin: PartyPinata
var _hits := 0
var _hit_t := 0.0
var _frames: Array[Vector2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 1
	Game.new_world_difficulty = DifficultyRules.COZY
	Game.start_new_world = true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("ACTION_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	var blasters := sandbox.get_node("Blasters") as BlasterDirector
	var monsters := sandbox.get_node("Monsters") as MonsterDirector
	var drops := sandbox.get_node("Drops") as DropDirector
	var inv := Session.inventory_of(p.peer_id)
	match _step:
		0:
			print("ACTION_SMOKE info seed=%d spawn=%s" % [sandbox.meta.seed, Vector3i(p.global_position.floor())])
			sandbox.call("set_time_of_day", ChatCommands.TIME_NOON)
			for id in [ItemIds.FOAM_BLASTER, ItemIds.BUBBLE_CANNON, ItemIds.CONFETTI_ROCKET]:
				inv.add(id, 1)
			inv.add(ItemIds.FOAM_DARTS, 60)
			inv.add(ItemIds.BUBBLE_SOAP, 6)
			interactor.hotbar[0] = ItemIds.FOAM_BLASTER
			interactor.select_slot(0)
			_check(drops.running and drops.survivor, "the drops' clock runs in a Survivor world")
			_next(0.5)
		1:
			_check(monsters.summon(MonsterRules.GOBLIN, 1, p.global_position) == "", "a goblin was summoned")
			_m = monsters.monsters()[-1]
			_count_before = inv.count(ItemIds.FOAM_DARTS)
			_next(0.3)
		2:
			if is_instance_valid(_m) and not _m.is_queued_for_deletion() and _step_t < 15.0:
				interactor.weapons.blasters.fire(ItemIds.FOAM_BLASTER, _m.hit_center())
				return
			_check(not is_instance_valid(_m) or _m.is_queued_for_deletion(), "foam darts defeated it (%.1f s)" % _step_t)
			var used := _count_before - inv.count(ItemIds.FOAM_DARTS)
			# owner #53: a dart hits for 3 now, so a level 1 goblin takes 2 darts (a miss or two may add some)
			var need := ceili(float(MonsterRules.hp(MonsterRules.GOBLIN, 1)) / BlasterRules.damage(ItemIds.FOAM_BLASTER))
			_check(used >= need and used <= need + 3, "one dart per shot from the bag (%d used, %d needed)" % [used, need])
			_check(monsters.summon(MonsterRules.GOBLIN, 2, p.global_position) == "", "a level 2 goblin")
			_m = monsters.monsters()[-1]
			interactor.hotbar[1] = ItemIds.BUBBLE_CANNON
			interactor.select_slot(1)
			_next(0.3)
		3:
			if not is_instance_valid(_m):
				_check(false, "the goblin is gone")
				_next(0.0)
				return
			if not _m.bubbled() and _step_t < 6.0:
				interactor.weapons.blasters.fire(ItemIds.BUBBLE_CANNON, _m.hit_center())
				return
			_check(_m.bubbled(), "a bubble traps it (%.1f s)" % _step_t)
			_check(blasters.marks_shown() >= 1, "everyone sees the bubble")
			_m.take_hit(100000, p.global_position, Vector3.ZERO)
			_check(monsters.summon(MonsterRules.ARCHER, 2, p.global_position) == "", "a goblin archer was summoned")
			_m = monsters.monsters()[-1]
			_hp_before = p.health.hp
			_next(0.0)
		4:
			if not is_instance_valid(_m):
				_check(false, "the archer is gone")
				_next(0.0)
				return
			_winding_seen = _winding_seen or _m.winding
			_arrow_seen = _arrow_seen or blasters.active_shots() > 0
			if p.health.hp >= _hp_before and _step_t < 40.0:
				return
			var d := Vector2(_m.global_position.x - p.global_position.x, _m.global_position.z - p.global_position.z).length()
			print("ACTION_SMOKE info archer %.1f blocks away after %.1f s" % [d, _step_t])
			_check(d >= 6.0, "it backed off from 4 blocks")
			_check(_winding_seen, "it drew its bow first (the signal)")
			_check(_arrow_seen, "its arrow flew in the pool")
			_check(p.health.hp < _hp_before, "the arrow hit the player standing still (%d -> %d)" % [_hp_before, p.health.hp])
			_m.take_hit(100000, p.global_position, Vector3.ZERO)
			p.health.heal(Health.MAX_HP)
			_next(0.5)
		5:
			_check(drops.spawn_pinata_now(), "a Party Piñata comes")
			_pin = drops.pinata()
			if _pin:
				var flat := Vector2(_pin.global_position.x - p.global_position.x, _pin.global_position.z - p.global_position.z).length()
				_check(flat >= 7.0 and flat <= 31.0, "8-30 blocks away (%.1f)" % flat)
				_check(_pin.chute_open(), "on its parachute")
			_next(0.0)
		6:
			if _pin == null or not is_instance_valid(_pin):
				_check(false, "the piñata is gone")
				_next(0.0)
				return
			if not _pin.landed and _step_t < 25.0:
				return
			_check(_pin.landed, "it landed (%.1f s)" % _step_t)
			p.global_position = _pin.global_position + Vector3(2.0, 0.3, 0.0)
			_count_before = _items(inv)   # every item counted: a burst's supplies may all be kinds already in the bag
			_hits = 0
			_hit_t = 0.0
			_next(0.5)
		7:
			_hit_t += get_process_delta_time()
			if is_instance_valid(_pin) and not _pin.is_queued_for_deletion() and _hits < 6:
				if _hit_t >= 0.4:
					_hit_t = 0.0
					_hits += 1
					_pin.take_hit(1, p.global_position, Vector3.ZERO)
				return
			_check(not is_instance_valid(_pin) or _pin.is_queued_for_deletion(), "3 hits burst it (%d hits)" % _hits)
			_check(inv.count(ItemIds.FOAM_DARTS) + inv.count(ItemIds.SNOWBALLS) + inv.count(ItemIds.PAINT_BLOBS)
				+ inv.count(ItemIds.BUBBLE_SOAP) + inv.count(ItemIds.PARTY_ROCKETS) > 0, "ammo in the bag")
			_check(_items(inv) > _count_before, "supplies in the bag (%d -> %d items)" % [_count_before, _items(inv)])
			var totem: Vector3 = (sandbox.call("waves") as WaveDirector).totem_position()
			if not totem.is_finite():
				# Owner #44: Survivor has no Totem waves (Monster Wave has them); balloons come with those waves.
				print("ACTION_SMOKE ok no Totem in a Survivor world (owner #44): the wave balloon is Monster Wave's")
				for i in 8:
					monsters.summon(MonsterRules.GOBLIN if i % 2 == 0 else MonsterRules.SLIME, 3, p.global_position)
				interactor.select_slot(0)
				_step = 8   # _next goes on to the cost window
				_next(0.5)
				return
			p.global_position = totem + Vector3(0, 0.3, -4)
			drops.wave_now = func() -> int: return 3
			_count_before = inv.count(ItemIds.POTION_JUMP) + inv.count(ItemIds.POTION_INVIS) + inv.count(ItemIds.POTION_SPEED)
			_next(0.0)
		8:
			var balloons := drops.drops().filter(func(d: PartyPinata) -> bool: return d.kind == PartyPinata.BALLOON)
			if balloons.is_empty() or _step_t < DropRules.BALLOON_DRIFT + DropRules.BALLOON_SETTLE + DropRules.BALLOON_DELAY + 1.0:
				if _step_t < 40.0:
					return
			_check(not balloons.is_empty(), "a supply balloon came in wave 3")
			if not balloons.is_empty():
				var b: PartyPinata = balloons[0]
				var off := Vector2(b.global_position.x - p.global_position.x, b.global_position.z - p.global_position.z - 4.0)
				print("ACTION_SMOKE info balloon at %s" % b.global_position)
				_check(off.length() < 5.0, "it settled beside the Totem")
				b.take_hit(1, p.global_position, Vector3.ZERO)
				var potions := inv.count(ItemIds.POTION_JUMP) + inv.count(ItemIds.POTION_INVIS) + inv.count(ItemIds.POTION_SPEED)
				_check(potions > _count_before, "popping it gave a potion")
			drops.wave_now = func() -> int: return 0
			for i in 8:
				monsters.summon(MonsterRules.GOBLIN if i % 2 == 0 else MonsterRules.SLIME, 3, p.global_position)
			interactor.select_slot(0)
			_next(0.5)
		9:
			if _step_t < 5.0:
				var list := monsters.monsters()
				if not list.is_empty():
					interactor.weapons.blasters.fire(ItemIds.FOAM_BLASTER, list[0].hit_center())
				_frames.append(Vector2(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
					Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
				return
			var worst := Vector2.ZERO
			var total := Vector2.ZERO
			for f in _frames:
				worst = worst.max(f)
				total += f
			var avg := total / maxf(_frames.size(), 1.0)
			print("ACTION_SMOKE cost frames=%d physics_avg_ms=%.2f physics_worst_ms=%.2f process_avg_ms=%.2f process_worst_ms=%.2f load=%s"
				% [_frames.size(), avg.x, worst.x, avg.y, worst.y, OS.get_environment("LOAD")])
			_check(blasters.active_shots() <= ShotPool.SIZE, "the pool held")
			_finish()


func _items(inv: Inventory) -> int:
	var n := 0
	for id in inv.ids():
		n += inv.count(id)
	return n


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("ACTION_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("ACTION_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(1 if not _fails.is_empty() else 0))
