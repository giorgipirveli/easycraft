extends Node
## The steps of tools/bots_smoke.gd (M2 Task 15), in a new Sandbox world on real terrain: three bot
## friends join, pop up next to the player after a long jump, a builder builds next to the player's
## block, a fighter hits a stand-in monster, a knocked-out friend comes back, the friends are saved,
## and one says bye. Prints the physics time while the friends play (desktop numbers, a rough guide).

const TIMEOUT := 120.0

## Stands in for Task 4's monsters (group "monsters", take_hit).
class SmokeMonster:
	extends Node3D
	var hits := 0

	func take_hit(_damage: int, _from: Vector3, _knockback: Vector3) -> void:
		hits += 1


var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _anchor := Vector3i.ZERO
var _monster: SmokeMonster
var _worst_physics := 0.0
var _physics_sum := 0.0
var _frames := 0
var _bots: Array[BotFriend] = []  # their physics steps run (and are timed) here
var _bot_us := 0
var _bot_worst_us := 0
var _bot_frames := 0
var _slow: Array[String] = []    # single friend steps over 4 ms, with what the friend was doing
## A fixed workload timed the same way each frame: on a busy PC, wall-clock spikes that it shows too
## are the scheduler's, not the friends'.
var _control_worst_us := 0
var _control_spikes := 0
var _bot_spikes := 0
## Single friend steps by kind: [count, spikes over 4 ms, total us]; a decision step thinks, a move
## step only moves (move_and_slide).
var _kinds := {&"decide": [0, 0, 0], &"move": [0, 0, 0]}
var _by_personality := {}        # personality -> [decision steps, total us]


## Runs every friend's physics step itself, to time the friends alone (all three, per frame).
func _physics_process(delta: float) -> void:
	var us := 0
	var n := 0
	for b in _bots:
		if is_instance_valid(b) and b.is_inside_tree():
			var before := b.behaviour
			var kind := &"decide" if float(b.get("_ai_t")) - delta <= 0.0 else &"move"
			var t0 := Time.get_ticks_usec()
			b._physics_process(delta)
			var one := Time.get_ticks_usec() - t0
			var k: Array = _kinds[kind]
			if kind == &"decide":
				var byp: Array = _by_personality.get(b.personality, [0, 0])
				byp[0] += 1
				byp[1] += one
				_by_personality[b.personality] = byp
			k[0] += 1
			k[1] += 1 if one > 4000 else 0
			k[2] += one
			us += one
			n += 1
			if one > 4000:
				_slow.append("%.1f ms %s %s->%s step=%d decisions=%d" % [one / 1000.0, b.personality, before, b.behaviour, _step, b.decisions])
	if n == 0:
		return
	var c0 := Time.get_ticks_usec()
	var v := Vector3.ONE
	for i in 400:
		v = (v * 1.0001 + Vector3(0.1, 0.2, 0.3)).normalized()
	var control := Time.get_ticks_usec() - c0
	_control_worst_us = maxi(_control_worst_us, control)
	if control > 4000:
		_control_spikes += 1
	if us > 4000:
		_bot_spikes += 1
	_bot_us += us
	_bot_worst_us = maxi(_bot_worst_us, us)
	_bot_frames += 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _step >= 1:
		var ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		_worst_physics = maxf(_worst_physics, ms)
		_physics_sum += ms
		_frames += 1
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player)


func _director(sandbox: Node) -> BotDirector:
	return sandbox.get("_bot_director") as BotDirector


func _run_step(sandbox: Node, p: Player) -> void:
	var d := _director(sandbox)
	match _step:
		0:
			_check(d != null, "the host has a BotDirector")
			_check(sandbox.pause_menu.friends == d, "the pause menu has the FRIENDS row")
			for personality in BotRules.PERSONALITIES:
				_check(d.add(personality) != null, "added a %s" % personality)
			_check(d.add(BotRules.FIGHTER) == null, "a fourth is refused")
			for b in d.bots():
				b.set_physics_process(false)
				_bots.append(b)
			_next(3.0)
		1:
			for b in d.bots():
				_check(b.global_position.distance_to(p.global_position) < 20.0, "%s stays near the player" % b.bot_name)
				_check(b.global_position.y > p.global_position.y - 4.0, "%s did not fall through the ground" % b.bot_name)
			p.global_position += Vector3(40, 0, 0)      # a long jump away (like /tp)
			p.global_position.y = p.world.find_standing_y(floori(p.global_position.x), floori(p.global_position.z)) + 0.05
			_next(0.0)
		2:
			var behind: Array[String] = []
			for b in d.bots():
				if Vector2(b.global_position.x - p.global_position.x, b.global_position.z - p.global_position.z).length() >= 6.0:
					behind.append(b.bot_name)
			if not behind.is_empty() and _step_t < 20.0:
				return                  # they wait until the ground there is loaded
			_check(behind.is_empty(), "every friend caught up after %.1f s %s" % [_step_t, behind])
			var x := floori(p.global_position.x) + 3
			var z := floori(p.global_position.z)
			_anchor = Vector3i(x, p.world.find_standing_y(x, z), z)
			Session.request_set_block(_anchor, BlockIds.BRICK)
			for b in d.bots():
				if b.personality == BotRules.BUILDER:
					b.set("_build_t", 0.0)
			_next(0.0)
		3:
			var built := 0
			for b in d.bots():
				if b.personality == BotRules.BUILDER and b.get("_plan").is_empty() and b.get("_build_t") > 20.0:
					built = 1
			if built == 0 and _step_t < 25.0:
				return
			var builder := _bot_of(d, BotRules.BUILDER)
			if built == 0:
				_why_no_build(p.world, _anchor)
			_check(built == 1, "the builder built next to the player's block (%s, plan %d, anchor %s, block %d, %.1f m away)" % [
				builder.behaviour, builder.get("_plan").size(), d.build_anchor(p.global_position),
				p.world.get_block(_anchor), builder.global_position.distance_to(Vector3(_anchor))])
			_check(p.world.get_block(_anchor) == BlockIds.BRICK, "the player's block is untouched")
			_monster = SmokeMonster.new()
			_monster.add_to_group(&"monsters")
			sandbox.add_child(_monster)
			_monster.global_position = p.global_position + Vector3(0, 0, -3)
			_next(0.0)
		4:
			if _monster.hits == 0 and _step_t < 10.0:
				return
			var fighter := _bot_of(d, BotRules.FIGHTER)
			_check(_monster.hits > 0, "the fighter hit the monster (%d hits; %s, %.1f m away, player %.1f m away)" % [
				_monster.hits, fighter.behaviour, fighter.global_position.distance_to(_monster.global_position),
				p.global_position.distance_to(_monster.global_position)])
			_monster.queue_free()
			fighter.hurt(Health.MAX_HP, fighter.global_position + Vector3(1, 0, 0))
			_check(fighter.knocked_out, "the fighter was knocked out")
			_next(0.0)
		5:
			var fighter := _bot_of(d, BotRules.FIGHTER)
			if fighter.knocked_out and _step_t < 13.0:
				return
			_check(not fighter.knocked_out and fighter.visible, "the fighter came back after %.1f s" % _step_t)
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.bots.size() == 3, "3 friends saved (%d)" % meta.bots.size())
			_check(d.remove(d.bots()[0].bot_name), "one said bye")
			_next(1.0)
		6:
			_check(d.bots().size() == 2, "two friends left")
			_time_pieces(p)
			print("BOTS_SMOKE physics avg_ms=%.2f worst_ms=%.2f frames=%d (whole physics frame; desktop, headless)" % [
				_physics_sum / maxf(_frames, 1), _worst_physics, _frames])
			print("BOTS_SMOKE bots avg_ms=%.3f worst_ms=%.3f frames=%d (all friends' own physics steps)" % [
				_bot_us / 1000.0 / maxf(_bot_frames, 1), _bot_worst_us / 1000.0, _bot_frames])
			print("BOTS_SMOKE spikes over 4 ms: friends %d, control %d (worst control %.1f ms)" % [
				_bot_spikes, _control_spikes, _control_worst_us / 1000.0])
			for personality: StringName in _by_personality:
				var byp: Array = _by_personality[personality]
				print("BOTS_SMOKE %s decisions=%d avg_ms=%.3f" % [personality, byp[0], byp[1] / 1000.0 / maxf(byp[0], 1)])
			for kind: StringName in _kinds:
				var k: Array = _kinds[kind]
				print("BOTS_SMOKE %s steps=%d avg_ms=%.3f over_4ms=%d (%.2f%%)" % [kind, k[0], k[2] / 1000.0 / maxf(k[0], 1),
					k[1], 100.0 * k[1] / maxf(k[0], 1)])
			_finish()


## The explorer's look-around and a builder's plan, timed on their own (20 times each) where the
## player stands.
func _time_pieces(p: Player) -> void:
	var center := Vector3i(p.global_position.floor())
	var half := BotFriend.SCAN_HALF
	var origin := center - half
	var t0 := Time.get_ticks_usec()
	for i in 20:
		var finds := BotRules.find_in_buffer(p.world.copy_box(origin, half * 2 + Vector3i.ONE), origin, BotRules.SHINY)
		BotRules.nearest_open(center, finds, p.world.get_block, {})
	var look_us := (Time.get_ticks_usec() - t0) / 20.0
	var reader := p.world.box_reader(center - half - Vector3i.ONE, half * 2 + Vector3i(3, 3, 3))
	t0 = Time.get_ticks_usec()
	for i in 20:
		BotRules.find_shiny(center, reader, half, {})
	var find_us := (Time.get_ticks_usec() - t0) / 20.0
	var anchor := center + Vector3i(3, 0, 0)
	var build_reader := p.world.box_reader(anchor - Vector3i(6, 5, 6), Vector3i(14, 13, 14))
	t0 = Time.get_ticks_usec()
	for i in 20:
		BotRules.plan_build(anchor, BotRules.build_design(ModeRules.SANDBOX, i), build_reader, i * 5)
	var plan_us := (Time.get_ticks_usec() - t0) / 20.0
	print("BOTS_SMOKE pieces: explorer look (copy + byte search) %.3f ms, the same box cell by cell %.3f ms, plan_build %.3f ms" % [
		look_us / 1000.0, find_us / 1000.0, plan_us / 1000.0])


## Which of the spots around the player's block have ground, and which have room (a failed build).
func _why_no_build(w: WorldService, anchor: Vector3i) -> void:
	var bases := 0
	var fits := 0
	var below := {}
	var around := {}
	for side in BotRules._ring(BotRules.BUILD_GAP, BotRules.BUILD_GAP + 2):
		var column := anchor + Vector3i(side.x, 0, side.y)
		var base := BotRules._base_at(column, w.get_block)
		if base == BotRules.NO_CELL:
			for dy in range(2, -5, -1):
				var c := column + Vector3i(0, dy, 0)
				if w.get_block(c) == BlockIds.AIR:
					below[w.get_block(c + Vector3i.DOWN)] = int(below.get(w.get_block(c + Vector3i.DOWN), 0)) + 1
			continue
		bases += 1
		var plan: Array = [[base, BlockIds.PLANKS]]
		if BotRules.plan_fits(plan, w.get_block, [] as Array[AABB]):
			fits += 1
		else:
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var id := w.get_block(base + Vector3i(dx, 0, dz))
					around[id] = int(around.get(id, 0)) + 1
	print("BOTS_SMOKE build spots: 72 around, %d with ground, %d with room; ids under air (no ground): %s; ids around (no room): %s" % [
		bases, fits, below, around])


func _bot_of(d: BotDirector, personality: StringName) -> BotFriend:
	for b in d.bots():
		if b.personality == personality:
			return b
	return null


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("BOTS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("BOTS_SMOKE done failed=%d" % _fails.size())
	get_tree().quit(0 if _fails.is_empty() else 1)
