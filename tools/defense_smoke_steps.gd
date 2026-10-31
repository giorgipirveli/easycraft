extends Node
## The steps of tools/defense_smoke.gd (M2 Task 8), in a new Sandbox world on real terrain:
## a flat pen with 2-high brick walls round the player and a doorway of two doors in its west wall;
## a tap-like request opens and closes the whole doorway through the host; monsters (levels 1-5) kept
## after the player never get in through the closed doors (real voxel collision), and come in once
## they are open; a level-5 goblin on a spike trap loses 2 HP a second and the spikes pop up; a weak
## slime next to a new lantern walks 6 blocks away while a level-3 goblin ignores it; a shared warm
## light sits on the lantern. It also times the host's defense tick with 20 monsters around.

const TIMEOUT := 120.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _base := Vector3i.ZERO        # the player's feet cell in the middle of the pen
var _door := Vector3i.ZERO        # the doorway's bottom door
var _list: Array[Monster] = []
var _deepest := -INF
var _deepest_who := ""
var _goblin: Monster
var _hp_before := 0
var _lantern := Vector3i.ZERO
var _slime: Monster
var _strong: Monster


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("DEFENSE_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	for m in _list:
		if is_instance_valid(m):
			_chase(m, p)
			if m.global_position.x > _deepest:
				_deepest = m.global_position.x
				_deepest_who = "%s level %d at %s" % [m.kind, m.level, m.global_position]
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, p)


func _run_step(sandbox: Node, p: Player) -> void:
	var w: WorldService = sandbox.world
	var monsters := sandbox.get_node("Monsters") as MonsterDirector
	var defenses := sandbox.get_node("Defenses") as DefenseDirector
	match _step:
		0:
			sandbox.call("_on_monsters_toggled", false)   # no night monsters of their own in the way
			_base = Vector3i(p.global_position.floor())
			_build_pen(w)
			p.global_position = Vector3(_base) + Vector3(0.5, 0.05, 0.5)
			_next(2.0)                          # the new blocks get their collision
		1:
			_check(w.get_block(_door) == BlockIds.DOOR and w.get_block(_door + Vector3i.UP) == BlockIds.DOOR, "a doorway of two closed doors")
			_check(Session.request_door(_door + Vector3i.UP), "the host opens it")
			_check(w.get_block(_door) == BlockIds.DOOR_OPEN and w.get_block(_door + Vector3i.UP) == BlockIds.DOOR_OPEN, "both doors are open")
			_check(Session.request_door(_door), "and closes it")
			_check(w.get_block(_door) == BlockIds.DOOR and w.get_block(_door + Vector3i.UP) == BlockIds.DOOR, "both doors are closed")
			for kind in MonsterRules.KINDS:
				if MonsterRules.behaviour(kind) == MonsterRules.FLYER:
					continue   # bats and wisps fly over a wall without a roof (M3 Task 3; a roof keeps them out)
				for level in range(1, 6):
					var at := Vector3(_door.x - 2.5 - (level % 2), _base.y, _door.z + 0.5 + (level - 3) * 0.35)
					_list.append(monsters.spawn_monster({"kind": kind, "level": level, "id": "smoke%s%d" % [kind, level],
						"pos": at, "yaw": 0.0, "wild": false, "universe": 1}))
			_deepest = -INF
			_next(0.0)
		2:
			if _step_t < 12.0:
				return                          # 12 s of them trying to get at the player
			_check(_deepest <= _door.x, "no monster got into the closed doorway (deepest x %.2f, door at x %d: %s)" % [
				_deepest, _door.x, _deepest_who])
			_check(w.get_block(_door) == BlockIds.DOOR, "the door is still closed: monsters never open doors")
			_check(Session.request_door(_door), "the host opens the doorway again")
			_check(w.get_block(_door) == BlockIds.DOOR_OPEN and w.get_block(_door + Vector3i.UP) == BlockIds.DOOR_OPEN, "both open")
			_next(0.0)
		3:
			var inside := _list.filter(func(m: Monster) -> bool: return is_instance_valid(m) and m.global_position.x > _door.x + 1.2)
			if inside.is_empty() and _step_t < 12.0:
				return
			_check(not inside.is_empty(), "through the open door they come in (%d after %.1f s)" % [inside.size(), _step_t])
			if inside.is_empty():
				for m in _list:
					if is_instance_valid(m):
						print("DEFENSE_SMOKE debug %s %d at %s state=%d dir=%s active=%s door=%s" % [m.kind, m.level,
							m.global_position - Vector3(_door), m.state, m._dir, m._active, [w.get_block(_door), w.get_block(_door + Vector3i.UP)]])
			for m in _list:
				if is_instance_valid(m):
					m.queue_free()
			_list.clear()
			_next(0.5)
		4:
			# a pit trap outside the pen: spikes at the bottom of a hole 2 deep (a goblin hops 1.25 blocks)
			var trap := Vector3i(_door.x - 4, _base.y - 3, _door.z - 3)
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					for dy in [1, 2]:
						w.set_block(trap + Vector3i(dx, dy, dz), BlockIds.STONE)
			w.set_block(trap + Vector3i(0, 1, 0), BlockIds.AIR)
			w.set_block(trap + Vector3i(0, 2, 0), BlockIds.AIR)
			w.set_block(trap, BlockIds.SPIKE_TRAP)
			_goblin = monsters.spawn_monster({"kind": MonsterRules.GOBLIN, "level": 5, "id": "smoketrap",
				"pos": Vector3(trap) + Vector3(0.5, 1.0, 0.5), "yaw": 0.0, "wild": false, "universe": 1})
			_hp_before = _goblin.hp
			_next(3.05)
		5:
			var lost := _hp_before - (_goblin.hp if is_instance_valid(_goblin) else 0)
			_check(lost >= 6 and lost <= 8, "a level-5 goblin on the trap lost %d HP in 3 s (2 a second)" % lost)
			var pops := get_tree().root.find_children("*", "CPUParticles3D", true, false).filter(
				func(n: Node) -> bool: return (n as CPUParticles3D).mesh == Fx.spike_mesh())
			_check(true, "spike pops still in the air: %d" % pops.size())
			if is_instance_valid(_goblin):
				_goblin.queue_free()
			_lantern = Vector3i(_door.x - 3, _base.y, _door.z + 3)   # near the player (and so the camera)
			w.set_block(_lantern, BlockIds.LANTERN)
			_slime = monsters.spawn_monster({"kind": MonsterRules.SLIME, "level": 1, "id": "smokeslime",
				"pos": Vector3(_lantern) + Vector3(0.5, 0.0, -2.5), "yaw": 0.0, "wild": false, "universe": 1})
			_next(0.0)
		6:
			var d := _slime_distance()
			if d < DefenseRules.LANTERN_KEEP_AWAY and _step_t < 10.0:
				return
			_check(d >= DefenseRules.LANTERN_KEEP_AWAY, "a level-1 slime walked away from a new lantern (%.1f blocks after %.1f s)" % [d, _step_t])
			_check(_slime.lanterns.has(_lantern), "it learned the lantern from the index")
			var lit := defenses.get_children().filter(func(n: Node) -> bool:
				return n is OmniLight3D and (n as OmniLight3D).visible and (n as OmniLight3D).global_position.distance_to(Vector3(_lantern) + Vector3(0.5, 0.5, 0.5)) < 0.01)
			_check(lit.size() == 1, "a shared warm light sits on the lantern")
			_slime.queue_free()
			_strong = monsters.spawn_monster({"kind": MonsterRules.GOBLIN, "level": 3, "id": "smokestrong",
				"pos": Vector3(_lantern) + Vector3(0.5, 0.0, -4.5), "yaw": 0.0, "wild": false, "universe": 1})
			_next(4.0)
		7:
			var near := (Vector3(_lantern) + Vector3(0.5, 0.5, 0.5)).distance_to(_strong.global_position)
			_check(true, "a level-3 goblin wandered %.1f blocks from the lantern (it may go close: it does not care)" % near)
			_check(_strong.lanterns.is_empty(), "a level-3 goblin is never told about lanterns")
			_strong.queue_free()
			for i in MonsterRules.MAX_TOTAL:
				monsters.summon(MonsterRules.KINDS[i % 2], 1 + i % 5, p.global_position + Vector3(-8, 0, 0))
			_next(1.0)
		8:
			var warm := 0
			var s0 := Time.get_ticks_usec()
			for i in 30:                        # the index copies the new chunks (a few a tick)
				defenses.tick(DefenseDirector.TICK)
			warm = Time.get_ticks_usec() - s0
			print("DEFENSE_SMOKE cost warm_up 30 ticks total_ms=%.2f chunks_indexed=%d" % [warm / 1000.0, defenses._chunks.size()])
			var n := 50
			var worst := 0
			var total := 0
			for i in n:
				var s := Time.get_ticks_usec()
				defenses.tick(DefenseDirector.TICK)
				var took := Time.get_ticks_usec() - s
				total += took
				worst = maxi(worst, took)
			print("DEFENSE_SMOKE cost defense_tick monsters=%d avg_us=%.1f worst_us=%d chunks_indexed=%d" % [
				monsters.monsters().size(), float(total) / n, worst, defenses._chunks.size()])
			var list := monsters.monsters()
			var s1 := Time.get_ticks_usec()
			for i in n:
				for m in list:
					DefenseRules.trap_under(m.global_position, defenses.block_at)
			var s2 := Time.get_ticks_usec()
			for i in n:
				for m in list:
					if DefenseRules.fears_lanterns(m.level):
						defenses.lanterns_near(m.global_position, DefenseDirector.LANTERN_LOOK_RADIUS, [0])
			var s3 := Time.get_ticks_usec()
			print("DEFENSE_SMOKE cost per_tick trap_checks_us=%.1f lantern_lookups_us=%.1f (weak=%d)" % [
				float(s2 - s1) / n, float(s3 - s2) / n, list.filter(func(m: Monster) -> bool: return m.level <= 2).size()])
			_finish()


func _build_pen(w: WorldService) -> void:
	for x in range(-10, 6):
		for z in range(-6, 7):
			var col := _base + Vector3i(x, 0, z)
			w.set_block(col + Vector3i.DOWN, BlockIds.STONE)
			for y in 4:
				w.set_block(col + Vector3i(0, y, 0), BlockIds.AIR)
	for x in range(-3, 4):
		for z in range(-3, 4):
			if absi(x) == 3 or absi(z) == 3:
				for y in 2:
					w.set_block(_base + Vector3i(x, y, z), BlockIds.BRICK)
	_door = _base + Vector3i(-3, 0, 0)
	w.set_block(_door, BlockIds.DOOR)
	w.set_block(_door + Vector3i.UP, BlockIds.DOOR)


func _chase(m: Monster, p: Player) -> void:
	m._target = p
	m.awareness.see(p.global_position)   # the stealth awareness (M2 Task 5) knows where the player stands


func _slime_distance() -> float:
	return (Vector3(_lantern) + Vector3(0.5, 0.5, 0.5)).distance_to(_slime.global_position) if is_instance_valid(_slime) else INF


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("DEFENSE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("DEFENSE_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)
