extends Node
## The steps of tools/boss_smoke.gd (M2 Task 10), in a new world on real terrain: the Golem rises by the
## "Totem" (a spot next to the player: Task 9's Totem is not in this branch) with the boss music and the
## HUD bar; its slam hurts the player standing next to it and it is dazed after (double damage); a win
## pays 300 gold and unlocks universe 2 (Survivor) or nothing (Sandbox), opens the portal on the ground
## and saves the world; a lost fight (knocked out in Survivor, walking away in Sandbox) shows how far
## the team got and is saved as help. It prints physics and process frame times without and with the
## Golem and near the portal (desktop, headless: a hint, not the emulator's numbers).

const TIMEOUT := 150.0

var _sandbox_mode := OS.get_cmdline_user_args().has("--smoke-sandbox")
var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _totem := Vector3.ZERO
var _gold_before := 0
var _quiet: Array[Vector2] = []
var _fight: Array[Vector2] = []
var _portal_frames: Array[Vector2] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX if _sandbox_mode else ModeRules.SURVIVOR
	Game.start_new_world = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--smoke-seed="):
			Game.new_world_seed = arg.trim_prefix("--smoke-seed=").to_int()   # repeat a world
	Profile.data.universe_unlocked = 1
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("BOSS_SMOKE begin mode=%s" % Game.mode)


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
	_run_step(sandbox, sandbox.get_node("Boss") as BossDirector)


func _run_step(sandbox: Node, boss: BossDirector) -> void:
	var p: Player = sandbox.player
	var hud: Hud = sandbox.hud
	match _step:
		0:
			if _step_t < 3.0:
				_sample(_quiet)             # the world settles; a quiet window to compare with
				return
			print("BOSS_SMOKE world seed=%d (repeat it with -- --smoke-seed=%d)" % [sandbox.meta.seed, sandbox.meta.seed])
			_check(not boss.fighting() and not hud.boss_bar.visible, "no Golem and no bar at first")
			_gold_before = Profile.data.survivor_gold
			_totem = p.global_position + Vector3(4, 0, 0)
			var said: String = sandbox.call("summon_boss" if _sandbox_mode else "start_boss", _totem)
			_check(said == "", "the Golem comes (%s)" % said)
			_check(boss.golem() != null, "a Golem is in the world")
			_next(0.1)
		1:
			var g := boss.golem()
			if g == null:
				_check(false, "the Golem vanished")
				_finish()
				return
			if g.phase == BossRules.Phase.RISE:
				return
			_check(hud.boss_bar.visible and is_equal_approx(hud.boss_bar.fraction(), 1.0), "the HUD bar shows a full Golem")
			_check(Music.current() == MusicRules.BOSS, "the boss music plays (%s)" % Music.current())
			var ground := BossRules.stand_y(g.global_position.x, g.global_position.z, g.global_position.y, p.world.get_block)
			_check(absf(g.global_position.y - ground) < 0.6, "it stands on the ground (y %.2f, ground %.1f)" % [g.global_position.y, ground])
			_check(g.max_hp == 300, "one player: 300 HP (%d)" % g.max_hp)
			_next(0.0)
		2:
			# Stand next to it on the ground until its slam lands (the first attack of every fight).
			var g := boss.golem()
			if g == null:
				_check(false, "the Golem vanished before its slam")
				_finish()
				return
			_sample(_fight)
			if g.phase != BossRules.Phase.DAZED and _step_t < 12.0:
				if p.global_position.distance_to(g.global_position) > 4.0:
					var spot := _ground_beside(g.global_position, 3.0, p.world.get_block)
					if spot.is_finite():
						p.global_position = spot
						p.velocity = Vector3.ZERO
				return
			_check(g.phase == BossRules.Phase.DAZED, "the slam came and it is dazed (%.1f s)" % _step_t)
			_check(p.health.hp < Health.MAX_HP, "the slam hurt the player standing next to it (%d HP; %s)" % [p.health.hp, _where(p, g)])
			var before := g.hp
			g.take_hit(10, p.global_position, Vector3.ZERO)
			_check(before - g.hp == 20, "dazed: a 10-damage hit takes 20 (%d)" % (before - g.hp))
			_next(0.0)
		3:
			var g := boss.golem()
			if g:
				g.take_hit(100000, p.global_position, Vector3.ZERO)
			_next(0.5)
		4:
			_check(hud.boss_bar.title() == BossRules.WIN_MESSAGE, "the bar says they won (%s)" % hud.boss_bar.title())
			var portals := boss.portals()
			_check(portals.size() == 1, "a portal opened (%d)" % portals.size())
			if not portals.is_empty():
				var at := portals[0].global_position
				var ground := BossRules.stand_y(at.x, at.z, at.y, p.world.get_block)
				_check(absf(at.y - ground) < 0.01, "on the ground by the Totem (%s)" % at)
				_check(portals[0].message() == portals[0].words(), "it says: %s" % portals[0].message())   # M3 Task 5: where it leads
			var gold := Profile.data.survivor_gold - _gold_before
			if _sandbox_mode:
				_check(gold == 0, "Sandbox: no gold (%d)" % gold)
				_check(Profile.data.universe_unlocked == 1, "Sandbox: no universe opens (%d)" % Profile.data.universe_unlocked)
			else:
				_check(gold == BossRules.GOLD, "300 gold for the only player (%d)" % gold)
				_check(Profile.data.universe_unlocked == 2, "universe 2 unlocked (%d)" % Profile.data.universe_unlocked)
			var saved := WorldSaves.load_meta(Game.slot())
			_check(saved.has_portal(), "the portal is saved with the world")
			_check(saved.boss_help.wins == 1, "the win is saved (%s)" % saved.boss_help)
			var by_portal := _ground_beside(boss.portal_pos, 2.5, p.world.get_block)   # walk up to it
			if by_portal.is_finite():
				p.global_position = by_portal
				p.velocity = Vector3.ZERO
			_next(0.0)
		5:
			_sample(_portal_frames)
			if _step_t < 3.0:
				return
			var portal := boss.portals()[0]
			_check(portal.is_blowing(), "sand and wind near the portal (%.1f blocks away; sand %s wind %s; hp %d; spawned %s players %d processing %s)" % [
				p.global_position.distance_to(boss.portal_pos), portal._sand.emitting, portal._wind.playing, p.health.hp,
				p.is_spawned(), Monster.players_now(get_tree()).size(), portal.is_processing()])
			var said: String = sandbox.call("summon_boss" if _sandbox_mode else "start_boss", _totem)
			_check(said == "", "the Golem comes again (%s)" % said)
			_next(2.5)
		6:
			# A lost fight: knocked out (Survivor) or walking away (Sandbox).
			var g := boss.golem()
			if g == null:
				_check(false, "no second Golem")
				_finish()
				return
			g.take_hit(150, p.global_position, Vector3.ZERO)
			if _sandbox_mode:
				p.global_position += Vector3(80, 0, 0)
				p.velocity = Vector3.ZERO
			else:
				Session.hurt_player(p.peer_id, Health.MAX_HP, g.global_position)
			_next(0.0)
		7:
			if boss.fighting() and _step_t < BossRules.LEAVE_TIME + 3.0:
				return
			_check(not boss.fighting(), "the fight is lost (%.1f s)" % _step_t)
			_check(hud.boss_bar.title() == BossRules.loss_message(50), "the bar says how far they got (%s)" % hud.boss_bar.title())
			var saved := WorldSaves.load_meta(Game.slot())
			_check(saved.boss_help.losses == 1 and saved.boss_help.best == 50, "the loss is saved as help (%s)" % saved.boss_help)
			print("BOSS_SMOKE cost quiet %s" % _summary(_quiet))
			print("BOSS_SMOKE cost golem_fight %s" % _summary(_fight))
			print("BOSS_SMOKE cost near_portal %s" % _summary(_portal_frames))
			_finish()


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("BOSS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("BOSS_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)


## A place to stand `dist` blocks from `center` on the same ground (within half a block of its height:
## not up a tree or down a hole), trying eight directions; INF when there is none.
func _ground_beside(center: Vector3, dist: float, block_at: Callable) -> Vector3:
	for i in 8:
		var a := TAU * i / 8.0
		var x := center.x + cos(a) * dist
		var z := center.z + sin(a) * dist
		var y := BossRules.stand_y(x, z, center.y, block_at)
		if absf(y - center.y) <= 0.5 and BlockIds.is_solid(block_at.call(Vector3i(floori(x), floori(y) - 1, floori(z)))):
			return Vector3(x, y, z)
	return Vector3.INF


## Where the player stands next to the Golem (for a failed slam check).
func _where(p: Player, g: StoneGolem) -> String:
	var d := p.global_position - g.global_position
	var below := p.world.get_block(Vector3i((p.global_position + Vector3(0, -0.3, 0)).floor()))
	return "flat %.1f dy %.1f vel_y %.1f floor %s mode %d water %d below %d protected %s" % [Vector2(d.x, d.z).length(), d.y,
		p.velocity.y, p.is_on_floor(), p.physics_mode, p.water_state, below, p.health.is_protected()]


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
