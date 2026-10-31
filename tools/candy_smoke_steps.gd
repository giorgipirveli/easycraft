extends Node
## The steps of tools/candy_smoke.gd (M3 Task 4), in a new Survivor world of universe 4 (the Candy Kingdom),
## through the real systems: the player stands on frosting with the kingdom's directors (its monsters, the Cake
## Monster, its secrets), the water looks like chocolate; at night gummy bears and candy sneakers come and
## sprinkles fall; a summoned gummy bear hurts the player standing still; a sneaker is dark at night, shimmers
## close by, jingles and swings; by day the sprinkles stop; the player swims in a chocolate river and bounces on a
## gumdrop hill; the Cake Monster rises, drops a layer (and says what comes next), is beaten: the portal leads to
## the Dragon Realm (universe 5) and the cosmic outfit is earned; the nearest gingerbread house is really there and found. It ends
## with a cost window: 20 candy monsters around the player.

const TIMEOUT := 420.0
const U := 4

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _target: Monster
var _hp_before := 0
var _phases := {}
var _spot := Vector3.INF
var _low := INF
var _rise := 0.0
var _landed := false
var _house := {}
var _tries := 0
var _said: Array[String] = []
var _first := true                # the first frame of a step
var _quiet: Array[Vector2] = []
var _busy: Array[Vector2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = U
	Game.new_world_difficulty = DifficultyRules.COZY   # half damage: the player lasts the Cake Monster's show
	Game.start_new_world = true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
	Session.magic_feedback.connect(func(text: String) -> void: _said.append(text))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("CANDY_SMOKE begin universe=%d" % Game.universe)


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
	var first := _first
	_first = false
	_run_step(sandbox, first)


func _run_step(sandbox: Node, first: bool) -> void:
	var p: Player = sandbox.player
	var w: WorldService = sandbox.world
	var monsters := sandbox.get_node("Monsters") as MonsterDirector
	var boss := sandbox.get_node("Boss") as BossDirector
	var secrets := sandbox.get_node("Secrets") as SecretDirector
	var shape := w.generator_shape() as CandyShape
	var sprinkles := sandbox.get_node_or_null("Sprinkles") as CandySprinkles
	match _step:
		0:
			print("CANDY_SMOKE info seed=%d spawn=%s" % [sandbox.meta.seed, Vector3i(p.global_position.floor())])
			_check(w.universe == U and shape != null, "a Candy Kingdom world (universe %d)" % w.universe)
			var feet := Vector3i(p.global_position.floor())
			_check(w.get_block(feet + Vector3i.DOWN) == BlockIds.FROSTING, "standing on frosting (block %d)" % w.get_block(feet + Vector3i.DOWN))
			_check(monsters.kinds == MonsterRules.CANDY_KINDS, "its night brings gummy bears and candy sneakers")
			_check(monsters.light_at.is_valid(), "the host measures the light for its sneakers")
			_check(boss.boss_kind == BossRules.CAKE, "its boss is the Cake Monster")
			_check(secrets.rules is CandySecretRules, "its secrets are the kingdom's")
			_check(BlockLibrary.liquid_chocolate() == 1.0, "its water looks like chocolate")
			var amb := sandbox.get_node_or_null("Ambience") as Ambience
			_check(amb != null and amb.chocolate, "the view under it is chocolate")
			_check(sprinkles != null, "it has sprinkles")
			sandbox.call("set_time_of_day", ChatCommands.TIME_NIGHT)
			_next(0.0)
		1:
			var list := monsters.monsters()
			if list.size() < 3 and _step_t < 30.0:
				return
			_check(not list.is_empty(), "night monsters came (%d after %.1f s)" % [list.size(), _step_t])
			for m in list:
				_check(MonsterRules.CANDY_KINDS.has(m.kind) and m.universe == U,
					"%s %d of universe %d at %s" % [m.kind, m.level, m.universe, Vector3i(m.global_position.floor())])
			_check(sprinkles != null and sprinkles.is_falling(), "sprinkles fall at night")
			monsters.puff_all()
			_next(0.5)
		2:
			_check(monsters.summon(MonsterRules.GUMMY, 1, p.global_position) == "", "a gummy bear was summoned")
			_target = monsters.monsters()[-1]
			_hp_before = p.health.hp
			_next(0.0)
		3:
			if not is_instance_valid(_target):
				_check(false, "the gummy bear is gone")
				_next(0.0)
				return
			if p.health.hp >= _hp_before and _step_t < 20.0:
				return
			_check(p.health.hp < _hp_before, "it hopped over and nipped the player (%d -> %d after %.1f s)" % [_hp_before, p.health.hp, _step_t])
			_target.take_hit(100000, p.global_position, Vector3.ZERO)
			_check(monsters.summon(MonsterRules.SNEAKER, 1, p.global_position) == "", "a candy sneaker was summoned")
			_target = monsters.monsters()[-1]
			_hp_before = p.health.hp
			_next(1.0)
		4:
			if not is_instance_valid(_target):
				_check(false, "the sneaker is gone")
				_next(0.0)
				return
			if first:
				_check(_target.dark, "the sneaker is dark at night (light %.2f)" % float(monsters.light_at.call(_target.global_position)))
				var body := _target.find_child("Body", true, false) as Node3D
				var shimmer := _target.find_child("Shimmer", true, false) as Node3D
				_check(body != null and not body.visible and shimmer != null and shimmer.visible,
					"close by, only its shimmer shows (%.1f blocks away)" % _target.global_position.distance_to(p.global_position))
			if p.health.hp >= _hp_before and _step_t < 20.0:
				return
			_check(_target.jingles >= 1, "it jingled before it swung (%d)" % _target.jingles)
			_check(p.health.hp < _hp_before, "its lollipop hit the player standing still (%d -> %d)" % [_hp_before, p.health.hp])
			_target.take_hit(100000, p.global_position, Vector3.ZERO)
			sandbox.call("set_time_of_day", ChatCommands.TIME_NOON)
			monsters.puff_all()
			_next(1.0)
		5:
			_check(sprinkles != null and not sprinkles.is_falling(), "the sprinkles stop by day")
			var river := _nearest(shape, p.global_position, CandyShape.RIVER, func(c: Vector3i) -> bool: return c.x <= MeadowsShape.SEA_LEVEL - 3)
			_check(river.is_finite(), "a chocolate river nearby (%s)" % river)
			if not river.is_finite():
				_next(0.0)
				_step = 7
				return
			_spot = river
			p.spawn_at(river)
			_next(1.0)
		6:
			if p.water_state < SwimRules.State.SWIMMING and _step_t < 20.0:
				if _step_t > 5.0 * (_tries + 1) and _tries < 3:
					_tries += 1
					p.spawn_at(_spot)
				return
			var at := Vector3i(p.global_position.floor())
			_check(p.water_state >= SwimRules.State.SWIMMING, "swimming in the chocolate river at %s (state %d)" % [at, p.water_state])
			_check(w.get_block(at + Vector3i.UP) == BlockIds.WATER, "the river is water (chocolate-coloured)")
			_tries = 0
			var hill := _nearest(shape, p.global_position, CandyShape.GREEN_HILL, func(c: Vector3i) -> bool: return c.x - c.z >= 5)
			if not hill.is_finite():
				hill = _nearest(shape, p.global_position, CandyShape.RED_HILL, func(c: Vector3i) -> bool: return c.x - c.z >= 5)
			_check(hill.is_finite(), "a gumdrop hill nearby (%s)" % hill)
			_spot = hill
			_low = INF
			_landed = false
			if hill.is_finite():
				p.spawn_at(hill)
			_next(2.0)
		7:
			if not _spot.is_finite():
				_next(0.0)
				return
			if _low == INF and not _landed:
				# A far teleport can land before the collision there is built (the player falls through and gets
				# up elsewhere): teleport again until the player stands on the hill (the desert's lesson).
				var feet := Vector3i(p.global_position.floor())
				var under := w.get_block(feet + Vector3i.DOWN)
				if not (CandyRules.is_gumdrop(under) and p.is_on_floor()):
					if _step_t > 4.0 * (_tries + 1) and _tries < 4:
						_tries += 1
						print("CANDY_SMOKE info teleport again (%d): the player is at %s on block %d" % [_tries, feet, under])
						p.spawn_at(_spot)
					if _step_t < 24.0:
						return
				_check(CandyRules.is_gumdrop(under), "standing on a gumdrop (block %d)" % under)
				p.global_position += Vector3(0, 4.0, 0)   # a drop of 4 blocks
				p.velocity = Vector3.ZERO
				_landed = false
				_low = -INF                   # the drop has begun
				_rise = 0.0
				_step_t = 0.0
				return
			if p.is_on_floor():
				_landed = true
				if _low == -INF:
					_low = p.global_position.y
			if _landed:
				_low = minf(_low, p.global_position.y)
				_rise = maxf(_rise, p.global_position.y - _low)
			if _step_t < 3.0:
				return
			_check(_rise > 1.0, "landing on the gumdrop bounced the player back up (%.2f blocks)" % _rise)
			p.spawn_on_surface(w.spawn_column().x, w.spawn_column().y)
			_next(2.0)
		8:
			if p.knocked_out and _step_t < 15.0:
				return
			p.health.heal(Health.MAX_HP)          # full hearts for the boss's show
			Session.broadcast_health(p.peer_id, p.health.hp)
			print("CANDY_SMOKE info before the boss: hp=%d at %s" % [p.health.hp, Vector3i(p.global_position.floor())])
			var said: String = sandbox.call("start_boss", p.global_position + Vector3(5, 0, 5))
			_check(said == "" and boss.golem() is CakeMonster, "the Cake Monster rose (%s)" % said)
			_next(0.0)
		9:
			var g := boss.golem() as CakeMonster
			if g:
				_phases[g.phase] = true
			if _step_t < 12.0 and g != null:
				return
			for ph in [CakeRules.Phase.WALK, CakeRules.Phase.WAVE_WARN, CakeRules.Phase.DIZZY]:
				_check(_phases.has(ph), "it went through phase %d (seen %s)" % [ph, _phases.keys()])
			_check(sandbox.hud.boss_bar.title() == CakeRules.TITLE, "the bar says %s" % sandbox.hud.boss_bar.title())
			_check(sandbox.hud.boss_bar.face() == BossRules.CAKE, "with the cake's face")
			if g:
				g.start_phase(CakeRules.Phase.WALK)
				g.take_hit(100000, p.global_position, Vector3.ZERO)
				_check(g.layers() == 2, "a layer fell off (%d left)" % g.layers())
			_next(0.5)
		10:
			_check(_said.has(CakeRules.LAYER_LINES[2]), "it said what comes next")
			var g := boss.golem() as CakeMonster
			for i in 3:
				if g and not g.is_down():
					g.start_phase(CakeRules.Phase.WALK)
					g.take_hit(100000, p.global_position, Vector3.ZERO)
			_next(1.0)
		11:
			if p.knocked_out and _step_t < 10.0:
				return
			_check(boss.golem() == null, "the Cake Monster is beaten")
			# Owner #39: the Dragon Realm (universe 5) comes after the Candy Kingdom now, so this portal leads there
			_check(boss.portals().size() == 1 and boss.portals()[0].target == UniverseRules.next_universe(4),
				"its portal leads to the Dragon Realm (universe 5)")
			_check(sandbox.hud.boss_bar.title() == CakeRules.WIN_MESSAGE, "the bar says %s" % sandbox.hud.boss_bar.title())
			_check(not _said.has(CakeRules.GRAND_WIN), "no grand celebration yet (the Dragon Realm is the last)")
			_check(AvatarUnlocks.is_owned("outfit.cosmic", Profile.data.cosmetics), "the cosmic outfit is earned")
			_house = _nearest_secret(secrets.rules, p.global_position, SecretRules.TEMPLE)
			_check(not _house.is_empty(), "a gingerbread house nearby")
			if _house.is_empty():
				_next(0.0)
				_step = 13
				return
			print("CANDY_SMOKE info house=%s tip=%s" % [_house.id, _house.tip])
			p.spawn_at(Vector3(_house.anchor) + Vector3(0.5, 0.0, 0.5))
			_tries = 0
			_next(1.0)
		12:
			if _step_t < 30.0 and not (w.is_area_ready(Vector3(_house.tip)) and secrets.state.found.has(_house.id)):
				if _step_t > 4.0 * (_tries + 1) and _tries < 4 and not secrets.state.found.has(_house.id):
					_tries += 1
					print("CANDY_SMOKE info teleport again (%d): the player is at %s" % [_tries, Vector3i(p.global_position.floor())])
					p.spawn_at(Vector3(_house.anchor) + Vector3(0.5, 0.0, 0.5))
				return
			_check(w.get_block(_house.tip) == BlockIds.GOLDEN_CANDY, "the golden candy on its roof")
			for c: Vector3i in _house.plates:
				_check(w.get_block(c) == BlockIds.PRESSURE_PLATE, "a plate at %s" % c)
			_check(secrets.state.found.has(_house.id), "walking in found the gingerbread house")
			_next(0.0)
		13:
			_sample(_quiet)
			if _step_t < 3.0:
				return
			var n := 0
			for i in 24:
				if n >= 20:
					break
				var a := TAU * i / 24.0
				var d := 9.0 + (i % 4) * 2.0
				var x := floori(p.global_position.x + cos(a) * d)
				var z := floori(p.global_position.z + sin(a) * d)
				var y := w.find_standing_y(x, z)
				if y >= shape.height_at(x, z) + 6:
					continue
				monsters.spawn_monster({"kind": MonsterRules.CANDY_KINDS[i % 2], "level": 1 + i % 5, "id": "cost%d" % i,
					"pos": Vector3(x + 0.5, y, z + 0.5), "yaw": 0.0, "wild": false, "universe": U})
				n += 1
			print("CANDY_SMOKE info cost window with %d monsters" % n)
			_next(0.0)
		14:
			_sample(_busy)
			if _step_t < 8.0:
				return
			print("CANDY_SMOKE cost quiet %s" % _summary(_quiet))
			print("CANDY_SMOKE cost busy(%d monsters) %s" % [monsters.monsters().size(), _summary(_busy)])
			_finish()


## The middle of the nearest column of `kind` (and `ok`) within 300 blocks, standing height, or INF.
func _nearest(shape: CandyShape, from: Vector3, kind: int, ok: Callable) -> Vector3:
	for r in range(0, 300, 4):
		var steps := maxi(r * 2, 1)
		for i in steps:
			var a := TAU * i / steps
			var x := floori(from.x + cos(a) * r)
			var z := floori(from.z + sin(a) * r)
			var col := shape.column(x, z)
			if col.y == kind and ok.call(col):
				return Vector3(x + 0.5, col.x, z + 0.5)
	return Vector3.INF


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
	print("CANDY_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("CANDY_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	Music.reset()
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(1 if not _fails.is_empty() else 0))


func _sample(into: Array[Vector2]) -> void:
	into.append(Vector2(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
		Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)


func _summary(frames: Array[Vector2]) -> String:
	var total := Vector2.ZERO
	var worst := Vector2.ZERO
	for f in frames:
		total += f
		worst = Vector2(maxf(worst.x, f.x), maxf(worst.y, f.y))
	var avg := total / maxf(frames.size(), 1.0)
	return "frames=%d physics_avg_ms=%.2f physics_worst_ms=%.2f process_avg_ms=%.2f process_worst_ms=%.2f" % [
		frames.size(), avg.x, worst.x, avg.y, worst.y]
