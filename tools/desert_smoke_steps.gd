extends Node
## The steps of tools/desert_smoke.gd (M3 Task 2), in a new Survivor world of universe 2 (the Sandstorm
## Desert), through the real systems: the player stands on open sand with the desert's directors (its
## monsters, its boss, its secrets, the sandstorm, the traps); at night mummies and scorpions come; a
## summoned scorpion spits at the player standing still and hurts them; a big mummy unwraps into two
## halves; a sandstorm blows (the player half as visible, the view closed in to half and tinted) and
## ends; the Sand Serpent rises, dives, warns, bursts and is beaten (the portal opens); the nearest
## pyramid is really there (golden tip, arrow slits, the sand pit, the plates) and walking into its
## chamber finds it. It ends with a cost window: 20 desert monsters around the player.

const TIMEOUT := 300.0
const DESERT_GROUND: Array[int] = [BlockIds.SAND, BlockIds.RED_SAND, BlockIds.SANDSTONE, BlockIds.RED_SANDSTONE]

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scorpion: Monster
var _hp_before := 0
var _light_clear := -1.0
var _fog_clear := 0.0
var _phases := {}
var _pyramid := {}
var _quiet: Array[Vector2] = []
var _busy: Array[Vector2] = []
var _cost_t := 0.0
var _tries := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 2
	Game.new_world_difficulty = DifficultyRules.COZY   # half damage: the player lasts the Serpent's whole show
	Game.start_new_world = true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("DESERT_SMOKE begin universe=%d" % Game.universe)


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
	var w: WorldService = sandbox.world
	var monsters := sandbox.get_node("Monsters") as MonsterDirector
	var boss := sandbox.get_node("Boss") as BossDirector
	var secrets := sandbox.get_node("Secrets") as SecretDirector
	match _step:
		0:
			print("DESERT_SMOKE info seed=%d spawn=%s" % [sandbox.meta.seed, Vector3i(p.global_position.floor())])
			_check(w.universe == 2 and w.generator_shape() is DesertShape, "a desert world (universe %d)" % w.universe)
			var feet := Vector3i(p.global_position.floor())
			var below := w.get_block(feet + Vector3i.DOWN)
			_check(DESERT_GROUND.has(below), "standing on the desert (block %d)" % below)
			_check((w.generator_shape() as DesertShape).terrain_at(feet.x, feet.z) == DesertShape.DESERT, "on open sand, not a mesa or an oasis")
			_check(monsters.kinds == MonsterRules.DESERT_KINDS, "its night brings mummies and scorpions")
			_check(boss.boss_kind == BossRules.SERPENT, "its boss is the Sand Serpent")
			_check(sandbox.get_node_or_null("Sandstorm") != null, "it has sandstorms")
			_check(sandbox.get_node_or_null("DesertTraps") != null, "it has traps")
			_check(secrets.rules is DesertSecretRules, "its secrets are the desert's")
			sandbox.call("set_time_of_day", ChatCommands.TIME_NIGHT)
			_next(0.0)
		1:
			var list := monsters.monsters()
			if list.size() < 3 and _step_t < 30.0:
				return
			_check(not list.is_empty(), "night monsters came (%d after %.1f s)" % [list.size(), _step_t])
			for m in list:
				_check(MonsterRules.DESERT_KINDS.has(m.kind) and m.universe == 2,
					"%s %d of universe %d at %s" % [m.kind, m.level, m.universe, Vector3i(m.global_position.floor())])
			sandbox.call("set_time_of_day", ChatCommands.TIME_NOON)
			monsters.puff_all()
			_next(0.5)
		2:
			_check(monsters.summon(MonsterRules.SCORPION, 1, p.global_position) == "", "a scorpion was summoned")
			_scorpion = monsters.monsters()[-1]
			_hp_before = p.health.hp
			_next(0.0)
		3:
			if not is_instance_valid(_scorpion):
				_check(false, "the scorpion is gone")
				_next(0.0)
				return
			if p.health.hp >= _hp_before and _step_t < 15.0:
				return
			_check(p.health.hp < _hp_before, "its spit hit the player standing still (%d -> %d after %.1f s)" % [_hp_before, p.health.hp, _step_t])
			_scorpion.take_hit(1000, p.global_position, Vector3.ZERO)
			_check(monsters.summon(MonsterRules.MUMMY, 3, p.global_position) == "", "a level 3 mummy was summoned")
			_next(0.3)
		4:
			var mummy: Monster = null
			for m in monsters.monsters():
				if m.kind == MonsterRules.MUMMY and m.level == 3:
					mummy = m
			_check(mummy != null, "the big mummy is there")
			if mummy:
				mummy.take_hit(1000, p.global_position, Vector3.ZERO)
			_next(0.3)
		5:
			var halves := monsters.monsters().filter(func(m: Monster) -> bool: return m.kind == MonsterRules.MUMMY and m.half != MonsterRules.WHOLE)
			_check(halves.size() == 2, "it unwrapped into two halves (%d)" % halves.size())
			monsters.puff_all()
			_light_clear = p.stealth_light
			_fog_clear = w.environment().fog_depth_end
			(sandbox.get_node("Sandstorm") as SandstormDirector).force(true)
			_next(5.0)
		6:
			var storm := sandbox.get_node("Sandstorm") as SandstormDirector
			_check(storm.strength >= 0.99, "the sandstorm blows (%.2f)" % storm.strength)
			_check(absf(p.stealth_light - _light_clear * 0.5) < 0.02, "the player is half as visible (%.2f -> %.2f)" % [_light_clear, p.stealth_light])
			var fog := w.environment().fog_depth_end
			_check(absf(fog - _fog_clear * 0.5) < 1.0, "the view closes in to half (%.0f -> %.0f)" % [_fog_clear, fog])
			storm.force(false)
			_next(5.0)
		7:
			var storm := sandbox.get_node("Sandstorm") as SandstormDirector
			_check(storm.strength <= 0.01, "the sandstorm is over")
			_check(absf(w.environment().fog_depth_end - _fog_clear) < 1.0, "the view is back")
			var said: String = sandbox.call("start_boss", p.global_position + Vector3(4, 0, 4))
			_check(said == "" and boss.golem() is SandSerpent, "the Sand Serpent rose (%s)" % said)
			_next(0.0)
		8:
			var g := boss.golem()
			if g:
				_phases[g.phase] = true
			if _step_t < 18.0 and g != null:
				return
			for ph in [SerpentRules.Phase.UP, SerpentRules.Phase.DIVE, SerpentRules.Phase.WARN, SerpentRules.Phase.BURST]:
				_check(_phases.has(ph), "it went through phase %d (seen %s)" % [ph, _phases.keys()])
			_check(sandbox.hud.boss_bar.title() == SerpentRules.TITLE or g == null, "the bar says %s" % sandbox.hud.boss_bar.title())
			if g:
				g.start_phase(SerpentRules.Phase.UP)
				g.take_hit(100000, p.global_position, Vector3.ZERO)
			_next(1.0)
		9:
			if p.knocked_out and _step_t < 10.0:
				return                          # the Serpent's last hit knocked them out: get up at home first
			_check(boss.portals().size() == 1, "the portal opened")
			_check(sandbox.hud.boss_bar.title() == SerpentRules.WIN_MESSAGE, "the bar says %s" % sandbox.hud.boss_bar.title())
			_pyramid = _nearest_pyramid(secrets.rules, p.global_position)
			_check(not _pyramid.is_empty(), "a pyramid nearby")
			if _pyramid.is_empty():
				_finish()
				return
			print("DESERT_SMOKE info pyramid=%s tip=%s hp=%d" % [_pyramid.id, _pyramid.tip, p.health.hp])
			p.spawn_at(Vector3(_pyramid.anchor) + Vector3(0.5, 0.0, 0.5))
			_next(1.0)
		10:
			if _step_t < 30.0 and not (w.is_area_ready(Vector3(_pyramid.tip)) and secrets.state.found.has(_pyramid.id)):
				# A teleport 80 blocks away can land before the collision there is built (the collision viewer
				# follows the visual one): the player then falls through and gets up at home. Try again.
				if _step_t > 4.0 * (_tries + 1) and _tries < 4 and not secrets.state.found.has(_pyramid.id):
					_tries += 1
					print("DESERT_SMOKE info teleport again (%d): the player is at %s" % [_tries, Vector3i(p.global_position.floor())])
					p.spawn_at(Vector3(_pyramid.anchor) + Vector3(0.5, 0.0, 0.5))
				return
			_check(w.get_block(_pyramid.tip) == BlockIds.PYRAMID_GOLD, "the golden tip is there")
			for t: Dictionary in _pyramid.traps:
				_check(w.get_block(t.cell) == BlockIds.ARROW_SLIT, "an arrow slit at %s" % t.cell)
			for c: Vector3i in _pyramid.pits:
				_check(w.get_block(c) == BlockIds.TRAP_SAND, "the sand pit's lid at %s" % c)
			for c: Vector3i in _pyramid.plates:
				_check(w.get_block(c) == BlockIds.PRESSURE_PLATE, "a plate at %s" % c)
			_check(secrets.state.found.has(_pyramid.id), "walking into the chamber found the pyramid (the player at %s, inside %s..%s)" % [
				Vector3i(p.global_position.floor()), _pyramid.inside[0], _pyramid.inside[1]])
			_check(secrets.thing("chest_" + _pyramid.id) != null, "its locked chest is in the treasure room")
			_next(0.0)
		11:
			_sample(_quiet)
			if _step_t < 3.0:
				return
			var shape := w.generator_shape()
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
				monsters.spawn_monster({"kind": MonsterRules.DESERT_KINDS[i % 2], "level": 1 + i % 5, "id": "cost%d" % i,
					"pos": Vector3(x + 0.5, y, z + 0.5), "yaw": 0.0, "wild": false, "universe": 2})
				n += 1
			print("DESERT_SMOKE info cost window with %d monsters" % n)
			_next(0.0)
		12:
			_sample(_busy)
			if _step_t < 8.0:
				return
			print("DESERT_SMOKE cost quiet %s" % _summary(_quiet))
			print("DESERT_SMOKE cost busy(%d monsters) %s" % [monsters.monsters().size(), _summary(_busy)])
			_finish()


func _nearest_pyramid(rules: SecretRules, from: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for s: Dictionary in rules.secrets_near(from, 400.0):
		if s.kind != SecretRules.TEMPLE:
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


func _check(ok: bool, what: String) -> void:
	print("DESERT_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("DESERT_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)


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
