extends Node
## Developer autopilot for the M1 acceptance checks (dev menu -> AUTOPILOT, or --autopilot).
## Phase 1 (60 s): walk in circles, triple-jump and place/break blocks — the "play" FPS check. It
## always starts on the ground at the world spawn, walking (a continued world may have saved the
## last run's flight: mid-air, in ghost mode), so every run measures the same place.
## Phase 2: ghost-fly straight for 2 km (through hills, terrain still streams) — the
## "no holes, no hitches" check. A stall of 10 s ends the run with a "stuck" report.
## Logs lines starting with "AUTOPILOT" (logcat on Android). Returns to the menu when done.

const PLAY_SECONDS := 60.0
const FLY_DISTANCE := 2000.0
const WARMUP := 3.0

var sandbox: Node
static var results: Array[String] = []   # the printed lines, kept for tools that cannot read stdout
var _phase := &"wait"
var _t := 0.0
var _frames := 0
var _time := 0.0
var _max_frame := 0.0
var _slow_frames := 0
var _start := Vector3.ZERO
var _next_action := 0.0
var _next_log := 5.0
var _last_progress := 0.0
var _last_progress_t := 0.0
var _grounded := false


func _process(delta: float) -> void:
	var player: Player = sandbox.player
	if player == null or not player.is_spawned():
		return
	_t += delta
	match _phase:
		&"wait":
			if not _grounded:
				_grounded = true
				var column: Vector2i = sandbox.world.spawn_column()
				player.set_physics_mode(PhysicsMode.Mode.NORMAL)
				player.spawn_on_surface(column.x, column.y)   # waits for the terrain there
				_t = 0.0
				return
			if _t > WARMUP:
				if Game.autopilot_buddies:
					_spawn_buddies(player)
				if Game.autopilot_night:
					_start_night(player)
				_begin(&"play")
				Input.action_press(&"move_forward")
		&"play":
			_measure(delta)
			player.rig.yaw += delta * 0.6   # walk in a big circle
			if _t >= _next_action:
				_next_action = _t + 1.5
				_play_action(player)
			if _t >= PLAY_SECONDS:
				_report()
				player.autopilot_ghost = true   # Survivor worlds (dev menu WORLD) refuse Ghost mode otherwise
				player.set_physics_mode(PhysicsMode.Mode.GHOST)
				player.global_position.y += 12.0
				_begin(&"fly")
		&"fly":
			_measure(delta)
			var flown := Vector2(player.global_position.x - _start.x, player.global_position.z - _start.z).length()
			if _t >= _next_log:
				_next_log = _t + 10.0
				print("AUTOPILOT fly distance=%d fps=%.1f max_frame_ms=%.1f" % [flown, Engine.get_frames_per_second(), _max_frame * 1000.0])
			if flown > _last_progress + 1.0:
				_last_progress = flown
				_last_progress_t = _t
			elif _t - _last_progress_t > 10.0:
				_log("AUTOPILOT stuck distance=%d" % flown)
				flown = FLY_DISTANCE
			if flown >= FLY_DISTANCE:
				_report()
				Input.action_release(&"move_forward")
				_phase = &"done"
				print("AUTOPILOT done")
				Game.quit_to_menu.call_deferred()


func _begin(phase: StringName) -> void:
	_phase = phase
	_t = 0.0
	_frames = 0
	_time = 0.0
	_max_frame = 0.0
	_slow_frames = 0
	_next_action = 0.0
	_next_log = 5.0
	_last_progress = 0.0
	_last_progress_t = 0.0
	_start = sandbox.player.global_position
	print("AUTOPILOT begin %s renderer=%s view=%d graphics=%s style=%s at=%s mode=%d night=%s world=%s universe=%d" % [phase,
		RenderingServer.get_current_rendering_method(), Profile.data.settings.view_distance,
		Profile.data.settings.graphics, BlockLibrary.style, Vector3i(_start), sandbox.player.physics_mode,
		Game.autopilot_night, Game.mode, Game.universe])


func _measure(delta: float) -> void:
	_frames += 1
	_time += delta
	_max_frame = maxf(_max_frame, delta)
	if delta > 0.1:
		_slow_frames += 1
		if _slow_frames <= 20:   # when the budget breaks, to line up with what happened then
			print("AUTOPILOT slow phase=%s t=%.2f ms=%.1f" % [_phase, _t, delta * 1000.0])


func _report() -> void:
	_log("AUTOPILOT result phase=%s avg_fps=%.1f max_frame_ms=%.1f frames_over_100ms=%d seconds=%.0f monsters=%d" % [
		_phase, _frames / maxf(_time, 0.001), _max_frame * 1000.0, _slow_frames, _time, _monster_count()])


func _log(line: String) -> void:
	print(line)
	results.append(line)


func _play_action(player: Player) -> void:
	var interactor: BlockInteractor = player.get_node("BlockInteractor")
	var center := get_viewport().get_visible_rect().size * 0.5
	var act := randi() % 3
	print("AUTOPILOT act t=%.2f %s" % [_t, ["triple jump", "place", "break"][act]])
	match act:
		0:
			for i in 3:
				Input.action_press(&"jump")
				await get_tree().create_timer(0.05).timeout
				Input.action_release(&"jump")
				await get_tree().create_timer(0.2).timeout
		1:
			interactor.select_slot(randi() % 7)
			interactor.place_at_screen(center + Vector2(0, 120))
		2:
			interactor.break_at_screen(center + Vector2(0, 140))


## Owner feedback #9: ten house-sized buddies (the capture limit) around the player.
func _spawn_buddies(player: Player) -> void:
	var house := Blueprints.local(ItemIds.STAMP_HOUSE)
	var lo := Vector3i(999, 999, 999)
	for k: Vector3i in house:
		if house[k] != BlockIds.AIR:
			lo = lo.min(k)
	var blocks := {}
	for k: Vector3i in house:
		if house[k] != BlockIds.AIR:
			blocks[k - lo] = house[k]
	for i in WorldMeta.MAX_BUDDIES:
		var a := TAU * i / WorldMeta.MAX_BUDDIES
		sandbox.call(&"_spawn_buddy", blocks, player.global_position + Vector3(cos(a) * 12.0, 6.0, sin(a) * 12.0), 0.0, "Big%d" % i, player.peer_id)
	_log("AUTOPILOT buddies=%d blocks_each=%d" % [WorldMeta.MAX_BUDDIES, blocks.size()])


# --- M2 Task 12: the autopilot at night with monsters (acceptance row 13) ---

## [kind, level] for each monster a night run summons: a full player's worth (MonsterRules.MAX_PER_PLAYER),
## the night's share of slimes, levels 1-3 as Meadows nights bring them.
static func night_lineup() -> Array:
	var lineup := []
	var slimes := roundi(MonsterRules.MAX_PER_PLAYER * MonsterRules.SLIME_SHARE)
	for i in MonsterRules.MAX_PER_PLAYER:
		lineup.append([MonsterRules.SLIME if i < slimes else MonsterRules.GOBLIN, 1 + i % 3])
	return lineup


## Night falls and the monsters come (summoned: not wild, so they stay the whole run).
func _start_night(player: Player) -> void:
	sandbox.call(&"set_time_of_day", DayCycle.MIDNIGHT)
	var md := sandbox.get(&"_monsters") as MonsterDirector
	var came := 0
	for e: Array in night_lineup():
		if md and md.summon(e[0], e[1], player.global_position) == "":
			came += 1
	_log("AUTOPILOT night monsters=%d of %d" % [came, night_lineup().size()])


func _monster_count() -> int:
	var md := sandbox.get(&"_monsters") as MonsterDirector
	return md.monsters().size() if md else 0
