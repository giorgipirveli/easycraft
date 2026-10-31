extends Node
## The steps of tools/frost_smoke.gd (M3 Task 3), in a new Survivor world of universe 3 (Frostpeak), through
## the real systems: the player stands in a snowy valley with Frostpeak's directors (its monsters, its boss,
## its secrets, the snowstorm); at night yetis and ice bats come; a summoned yeti's snowball (or smash) hurts
## the player standing still; a summoned ice bat flies, signals and dives at them; a snowstorm blows (the
## player half as visible, the view closed in to half and white) and ends; the Frost Giant climbs out,
## stomps (the ground turns icy for a while, no block changes), breathes, pants, throws, and is beaten (the
## portal opens, universe 4 unlocks); a cost window with 20 Frostpeak monsters around the player; the nearest
## igloo with a secret room is really there and a knock opens its floor and finds the room; a frozen lake's
## ice is under the player's feet and slippery.

const TIMEOUT := 360.0
const FROST_GROUND: Array[int] = [BlockIds.SNOWY_GRASS, BlockIds.SNOW, BlockIds.PACKED_SNOW]

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _yeti: Monster
var _bat: Monster
var _hp_before := 0
var _winding_seen := false
var _bat_high := false
var _light_clear := -1.0
var _fog_clear := 0.0
var _phases := {}
var _icy_seen := false
var _room := {}
var _lake := Vector3i.ZERO
var _quiet: Array[Vector2] = []
var _busy: Array[Vector2] = []
var _tries := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 3
	Game.new_world_difficulty = DifficultyRules.COZY   # half damage: the player lasts the Giant's whole show
	Game.start_new_world = true
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-seed="):
			Game.new_world_seed = int(a.trim_prefix("--smoke-seed="))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("FROST_SMOKE begin universe=%d" % Game.universe)


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
			print("FROST_SMOKE info seed=%d spawn=%s" % [sandbox.meta.seed, Vector3i(p.global_position.floor())])
			_check(w.universe == 3 and w.generator_shape() is FrostShape, "a Frostpeak world (universe %d)" % w.universe)
			var feet := Vector3i(p.global_position.floor())
			var below := w.get_block(feet + Vector3i.DOWN)
			_check(FROST_GROUND.has(below), "standing on snow (block %d)" % below)
			_check((w.generator_shape() as FrostShape).terrain_at(feet.x, feet.z) == FrostShape.VALLEY, "in a snowy valley")
			_check(monsters.kinds == MonsterRules.FROST_KINDS, "its night brings yetis and ice bats")
			_check(boss.boss_kind == BossRules.FROST_GIANT, "its boss is the Frost Giant")
			var storm := sandbox.get_node_or_null("Snowstorm") as SandstormDirector
			_check(storm != null and storm.snow, "it has snowstorms")
			_check(sandbox.get_node_or_null("DesertTraps") == null, "no desert traps")
			_check(secrets.rules is FrostSecretRules, "its secrets are Frostpeak's")
			sandbox.call("set_time_of_day", ChatCommands.TIME_NIGHT)
			_next(0.0)
		1:
			var list := monsters.monsters()
			if list.size() < 3 and _step_t < 30.0:
				return
			_check(not list.is_empty(), "night monsters came (%d after %.1f s)" % [list.size(), _step_t])
			for m in list:
				_check(MonsterRules.FROST_KINDS.has(m.kind) and m.universe == 3,
					"%s %d of universe %d at %s" % [m.kind, m.level, m.universe, Vector3i(m.global_position.floor())])
			sandbox.call("set_time_of_day", ChatCommands.TIME_NOON)
			monsters.puff_all()
			_next(0.5)
		2:
			_check(monsters.summon(MonsterRules.YETI, 1, p.global_position) == "", "a yeti was summoned")
			_yeti = monsters.monsters()[-1]
			_hp_before = p.health.hp
			_next(0.0)
		3:
			if not is_instance_valid(_yeti):
				_check(false, "the yeti is gone")
				_next(0.0)
				return
			_winding_seen = _winding_seen or _yeti.winding
			if p.health.hp >= _hp_before and _step_t < 20.0:
				return
			_check(_winding_seen, "it lifted its snowball first")
			_check(p.health.hp < _hp_before, "its snowball hit the player standing still (%d -> %d after %.1f s)" % [_hp_before, p.health.hp, _step_t])
			_yeti.take_hit(100000, p.global_position, Vector3.ZERO)
			_check(monsters.summon(MonsterRules.ICE_BAT, 1, p.global_position) == "", "an ice bat was summoned")
			_bat = monsters.monsters()[-1]
			_hp_before = p.health.hp
			_winding_seen = false
			_next(0.0)
		4:
			if not is_instance_valid(_bat):
				_check(false, "the ice bat is gone")
				_next(0.0)
				return
			_winding_seen = _winding_seen or _bat.winding
			_bat_high = _bat_high or _bat.global_position.y > p.global_position.y + 2.0
			# watch until it has both flown high and bitten (summoned beside the player, it can bite first)
			if (p.health.hp >= _hp_before or not _bat_high) and _step_t < 25.0:
				return
			_check(_bat_high, "the bat flew above the ground")
			_check(_winding_seen, "it hovered and screeched first")
			_check(p.health.hp < _hp_before, "its dive hit the player standing still (%d -> %d after %.1f s)" % [_hp_before, p.health.hp, _step_t])
			monsters.puff_all()
			_light_clear = p.stealth_light
			_fog_clear = w.environment().fog_depth_end
			(sandbox.get_node("Snowstorm") as SandstormDirector).force(true)
			_next(5.0)
		5:
			var storm := sandbox.get_node("Snowstorm") as SandstormDirector
			_check(storm.strength >= 0.99, "the snowstorm blows (%.2f)" % storm.strength)
			_check(absf(p.stealth_light - _light_clear * 0.5) < 0.02, "the player is half as visible (%.2f -> %.2f)" % [_light_clear, p.stealth_light])
			var fog := w.environment().fog_depth_end
			_check(absf(fog - _fog_clear * 0.5) < 1.0, "the view closes in to half (%.0f -> %.0f)" % [_fog_clear, fog])
			var c := w.environment().fog_light_color
			_check(minf(c.r, minf(c.g, c.b)) > 0.8, "the fog is white (%s)" % c)
			storm.force(false)
			_next(5.0)
		6:
			var storm := sandbox.get_node("Snowstorm") as SandstormDirector
			_check(storm.strength <= 0.01, "the snowstorm is over")
			_check(absf(w.environment().fog_depth_end - _fog_clear) < 1.0, "the view is back")
			var said: String = sandbox.call("start_boss", p.global_position + Vector3(4, 0, 4))
			_check(said == "" and boss.golem() is FrostGiant, "the Frost Giant rose (%s)" % said)
			_next(0.0)
		7:
			var g := boss.golem()
			if g:
				_phases[g.phase] = true
			_icy_seen = _icy_seen or IcyGround.active(Time.get_ticks_msec() / 1000.0)
			if _step_t < 22.0 and g != null:
				return
			for ph in [FrostGiantRules.Phase.WALK, FrostGiantRules.Phase.STOMP_WARN, FrostGiantRules.Phase.BREATH_WARN,
					FrostGiantRules.Phase.BREATH, FrostGiantRules.Phase.PANTING, FrostGiantRules.Phase.THROW_WARN]:
				_check(_phases.has(ph), "it went through phase %d (seen %s)" % [ph, _phases.keys()])
			_check(_icy_seen, "its stomp made the ground icy for a while")
			_check(sandbox.hud.boss_bar.title() == FrostGiantRules.TITLE or g == null, "the bar says %s" % sandbox.hud.boss_bar.title())
			if g:
				g.start_phase(FrostGiantRules.Phase.WALK)
				g.take_hit(100000, p.global_position, Vector3.ZERO)
			_next(1.0)
		8:
			if p.knocked_out and _step_t < 10.0:
				return                          # the Giant's last hit knocked them out: get up at home first
			_check(boss.portals().size() == 1, "the portal opened")
			_check(boss.portals().size() == 1 and boss.portals()[0].target == 4, "it leads to universe 4")
			_check(Profile.data.universe_unlocked >= 4, "universe 4 is unlocked (%d)" % Profile.data.universe_unlocked)
			_check(sandbox.hud.boss_bar.title() == FrostGiantRules.WIN_MESSAGE, "the bar says %s" % sandbox.hud.boss_bar.title())
			_next(1.0)
		9:
			_sample(_quiet)                     # the cost window, where the world has settled round the spawn
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
				monsters.spawn_monster({"kind": MonsterRules.FROST_KINDS[i % 2], "level": 1 + i % 5, "id": "cost%d" % i,
					"pos": Vector3(x + 0.5, y, z + 0.5), "yaw": 0.0, "wild": false, "universe": 3})
				n += 1
			print("FROST_SMOKE info cost window with %d monsters" % n)
			_next(0.0)
		10:
			_sample(_busy)
			if _step_t < 8.0:
				return
			print("FROST_SMOKE cost quiet %s" % _summary(_quiet))
			print("FROST_SMOKE cost busy(%d monsters) %s" % [monsters.monsters().size(), _summary(_busy)])
			monsters.puff_all()
			_room = _nearest(secrets.rules, p.global_position, SecretRules.ROOM)
			_check(not _room.is_empty(), "an igloo with a secret room nearby")
			if _room.is_empty():
				_finish()
				return
			print("FROST_SMOKE info room=%s igloo=%s hp=%d" % [_room.id, _room.stairs_top, p.health.hp])
			p.spawn_at(Vector3(_room.stairs_top) + Vector3(0.5, 0.0, 0.5))
			_next(1.0)
		11:
			var igloo: Vector3i = _room.stairs_top
			var feet := Vector3i(p.global_position.floor())
			if _step_t < 30.0 and not (w.is_area_ready(Vector3(igloo)) and feet == igloo):
				# A long teleport can land before the collision there is built (the desert's smoke run found it):
				# the player falls through and gets up at home. Try again.
				if _step_t > 4.0 * (_tries + 1) and _tries < 4:
					_tries += 1
					print("FROST_SMOKE info teleport again (%d): the player is at %s" % [_tries, feet])
					p.spawn_at(Vector3(igloo) + Vector3(0.5, 0.0, 0.5))
				return
			_check(feet == igloo, "standing in the igloo (%s, its floor's middle %s)" % [feet, igloo])
			_check(w.get_block(igloo + Vector3i(0, 3, 0)) == BlockIds.SNOW_BRICK, "under its snow-brick dome")
			var fake: Array = _room.fake_wall
			for c: Vector3i in fake:
				_check(w.get_block(c) == BlockIds.FAKE_SNOW, "the fake floor at %s" % c)
			secrets.call("_on_knock_requested", p.peer_id, fake[0])
			_next(0.5)
		12:
			for c: Vector3i in _room.fake_wall:
				_check(w.get_block(c) == BlockIds.AIR, "the knock opened the floor at %s" % c)
			_check(secrets.state.found.has(_room.id), "the knock found the secret room")
			_lake = _nearest_ice(w.generator_shape() as FrostShape, p.global_position)
			_check(_lake != Vector3i.ZERO, "a frozen lake nearby")
			if _lake == Vector3i.ZERO:
				_finish()
				return
			print("FROST_SMOKE info lake ice at %s" % _lake)
			_tries = 0
			p.spawn_at(Vector3(_lake) + Vector3(0.5, 1.0, 0.5))
			_next(1.0)
		13:
			var feet := Vector3i(p.global_position.floor())
			if _step_t < 30.0 and not (w.is_area_ready(Vector3(_lake)) and p.is_on_floor() and feet.y == _lake.y + 1):
				if _step_t > 4.0 * (_tries + 1) and _tries < 4:
					_tries += 1
					p.spawn_at(Vector3(_lake) + Vector3(0.5, 1.0, 0.5))
				return
			var under := w.get_block(FrostRules.floor_cell(p.global_position))
			_check(under == BlockIds.ICE, "standing on the lake's ice (block %d at %s)" % [under, feet])
			_check(FrostRules.grip_at(p.global_position, w.get_block) < 0.5, "and it is slippery")
			_finish()

func _nearest(rules: SecretRules, from: Vector3, kind: StringName) -> Dictionary:
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


## The ice cell of the frozen lake nearest to `from` (a column well inside a lake), or ZERO.
func _nearest_ice(shape: FrostShape, from: Vector3) -> Vector3i:
	for r in range(0, 400, 4):
		for i in maxi(r / 2, 1):
			var a := TAU * i / maxi(r / 2, 1)
			var x := floori(from.x + cos(a) * r)
			var z := floori(from.z + sin(a) * r)
			if shape.column(x, z).y == FrostShape.LAKE and shape.height_at(x, z) < MeadowsShape.SEA_LEVEL - 2:
				return Vector3i(x, MeadowsShape.SEA_LEVEL - 1, z)
	return Vector3i.ZERO


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("FROST_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("FROST_SMOKE result fails=%d" % _fails.size())
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
