extends Node
## The steps of tools/monster_smoke.gd (M2 Task 4), in a new world: night falls, monsters come on the
## surface 18-40 blocks away, a summoned goblin sees the player, winds up and hurts them, a defeat
## bursts into coins that fly to the player and pay once (Survivor) or only confetti (Sandbox), the
## Sandbox's MONSTERS: OFF sends them away, and sunrise puffs the wild ones away. It also prints the
## worst physics and process frame times while monsters were around (desktop, headless: a hint, not
## the emulator's numbers).

const TIMEOUT := 90.0

var _sandbox_mode := OS.get_cmdline_user_args().has("--smoke-sandbox")
var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _goblin: Monster
var _gold_before := 0
var _coin_value := 0
var _worst_physics := 0.0
var _worst_process := 0.0
var _most := 0
var _quiet: Array[Vector2] = []        # per frame: (physics ms, process ms)
var _busy: Array[Vector2] = []
var _arrivals: Array[Dictionary] = []   # every monster where it appeared: {kind, level, wild, dist, below, at}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX if _sandbox_mode else ModeRules.SURVIVOR
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("MONSTER_SMOKE begin mode=%s" % Game.mode)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var director := sandbox.get_node("Monsters") as MonsterDirector
	if director.monsters().size() > 0:
		_most = maxi(_most, director.monsters().size())
		_worst_physics = maxf(_worst_physics, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		_worst_process = maxf(_worst_process, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, director)


func _run_step(sandbox: Node, director: MonsterDirector) -> void:
	var p: Player = sandbox.player
	match _step:
		0:
			_check(director.monsters().is_empty(), "no monsters in the morning")
			director.get_node("List").child_entered_tree.connect(func(n: Node) -> void: _arrived(n as Monster, p))
			sandbox.call("set_time_of_day", ChatCommands.TIME_NIGHT)
			_next(0.0)
		1:
			var list := director.monsters()
			if list.size() < 3 and _step_t < 25.0:
				return                          # they come a few a second, where the ground is ready
			_check(not list.is_empty(), "night monsters came (%d after %.1f s)" % [list.size(), _step_t])
			var cap := MonsterRules.GENTLE_MAX if _sandbox_mode else MonsterRules.MAX_PER_PLAYER
			_check(list.size() <= cap, "at most %d (%d)" % [cap, list.size()])
			for a in _arrivals:
				var what := "%s %d at %s" % [a.kind, a.level, a.at]
				_check(a.dist >= MonsterRules.SPAWN_MIN and a.dist <= MonsterRules.SPAWN_MAX, "%s: %.1f blocks from the player" % [what, a.dist])
				_check(BlockIds.is_solid(a.below) and a.below != BlockIds.LEAVES, "%s: on solid ground (block %d)" % [what, a.below])
				_check(a.level <= 2, "%s: near the world spawn, level 1 +- 1" % what)
				_check(a.wild, "%s: wild" % what)
			_next(0.0)
		2:
			_gold_before = Profile.data.survivor_gold
			var said: String = sandbox.call("summon_monster", MonsterRules.GOBLIN, 2, p.global_position)
			_check(said == "", "summoned a level 2 goblin (%s)" % said)
			for m in director.monsters():
				if not m.wild:
					_goblin = m
			_check(_goblin != null and _goblin.level == 2, "the summoned goblin is there")
			_next(0.0)
		3:
			if _goblin == null or not is_instance_valid(_goblin):
				_check(false, "the goblin is gone")
				_finish()
				return
			if p.health.hp == Health.MAX_HP and _step_t < 12.0:
				return                          # it sees the player, comes over, winds up and swings
			_check(p.health.hp < Health.MAX_HP, "the goblin hurt the player (%d HP after %.1f s)" % [p.health.hp, _step_t])
			_next(0.0)
		4:
			var coins_before := director.coins().size()
			_goblin.take_hit(100, p.global_position, Vector3.ZERO)
			var fresh := director.coins().size() - coins_before
			if _sandbox_mode:
				_check(fresh == 0, "Sandbox: confetti only, no coins (%d)" % fresh)
			else:
				_check(fresh == MonsterRules.MAX_COINS_PER_DEFEAT, "Survivor: 5 coins for 6 gold (%d)" % fresh)
			_next(1.2)                          # the coins land
		5:
			if _sandbox_mode:
				sandbox.call("_on_monsters_toggled", false)
				_next(0.3)
				return
			var coins := director.coins()
			if coins.is_empty():
				_check(false, "coins are lying there")
				_next(0.0)
				return
			_coin_value = coins[0].value
			p.global_position = coins[0].global_position + Vector3(0, -Coin.HOVER, 0)   # stand on it
			_next(1.5)
		6:
			if _sandbox_mode:
				_check(director.monsters().is_empty(), "MONSTERS: OFF sends them all away (%d left)" % director.monsters().size())
				_check(not sandbox.meta.monsters_on, "the world remembers OFF")
				sandbox.call("_on_monsters_toggled", true)
				sandbox.call("set_time_of_day", ChatCommands.TIME_NIGHT)
				_next(3.0)
				return
			var got := Profile.data.survivor_gold - _gold_before
			_check(got >= _coin_value and got <= MonsterRules.gold(MonsterRules.GOBLIN, 2),
				"coins flew to the player and paid (%d gold)" % got)
			_next(0.0)
		7:
			sandbox.call("set_time_of_day", DayCycle.SUNRISE + 0.01)
			_next(1.6)
		8:
			var wild := director.monsters().filter(func(m: Monster) -> bool: return m.wild)
			_check(wild.is_empty(), "the wild ones puffed away at sunrise (%d left)" % wild.size())
			print("MONSTER_SMOKE startup most_monsters=%d worst_physics_ms=%.2f worst_process_ms=%.2f (streaming too)" % [
				_most, _worst_physics, _worst_process])
			for m in director.monsters():
				m.queue_free()
			_next(0.0)
		9:
			# Cost: first a quiet window without monsters (the world has settled by now) ...
			if _step_t < 4.0:
				_sample(_quiet)
				return
			for i in MonsterRules.MAX_TOTAL:
				director.summon(MonsterRules.KINDS[i % 2], 1 + i % 5, p.global_position)
			_next(1.0)
		10:
			# ... then the same with 20 monsters (all levels) around the player, all simulated.
			if _step_t < 6.0:
				_sample(_busy)
				return
			var active := director.monsters().filter(func(m: Monster) -> bool: return m._active)
			_check(director.monsters().size() == MonsterRules.MAX_TOTAL, "20 monsters (%d)" % director.monsters().size())
			print("MONSTER_SMOKE cost quiet %s" % _summary(_quiet))
			print("MONSTER_SMOKE cost 20_monsters active=%d %s" % [active.size(), _summary(_busy)])
			_finish()


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("MONSTER_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("MONSTER_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)


## A new monster: where it appeared, how far from the player, what it stands on.
func _arrived(m: Monster, p: Player) -> void:
	if m == null or not m.wild:
		return
	var at := m.global_position
	_arrivals.append({"kind": m.kind, "level": m.level, "wild": m.wild, "at": Vector3i(at.floor()),
		"dist": Vector2(at.x - p.global_position.x, at.z - p.global_position.z).length(),
		"below": p.world.get_block(Vector3i((at + Vector3(0, -0.5, 0)).floor()))})


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
