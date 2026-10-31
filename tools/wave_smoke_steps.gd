extends Node
## The steps of tools/wave_smoke.gd (M2 Task 9), in a new world on real terrain: the Totem stands on
## the ground about 20 blocks from the spawn and is saved; a real tap through the camera opens its
## panel and START counts down 5 s on the HUD while it glows; wave 1's five monsters appear on solid
## ground at the edge of the 25-block circle and walk towards the Totem; defeating them wins the wave
## (10 gold in Survivor, none in Sandbox) and N becomes 2 in world.json; a knock-out during wave 2 ends
## it and the Totem offers TRY AGAIN and an easier wave. Last, a cost window: wave 9 (20 monsters in
## Survivor, 8 in Sandbox) heading for the Totem next to the player (desktop, headless: a hint, not the
## emulator's numbers).

const TIMEOUT := 150.0

## Owner feedback #44 (spec §12.20): Survivor has no Totem any more, so the run uses a Sandbox world unless asked
## for Survivor (--smoke-survivor: its Totem is gone, the run then fails at the Totem).
var _sandbox_mode := not OS.get_cmdline_user_args().has("--smoke-survivor")
var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _gold_before := 0
var _start_dist := 0.0
var _busy: Array[Vector2] = []
var _quiet: Array[Vector2] = []
var _arrivals: Array[Dictionary] = []   # every wave monster where it appeared: {kind, level, r, below}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX if _sandbox_mode else ModeRules.SURVIVOR
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	print("WAVE_SMOKE begin mode=%s" % Game.mode)


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
	_run_step(sandbox, sandbox.get_node("Waves") as WaveDirector)


func _run_step(sandbox: Node, waves: WaveDirector) -> void:
	var p: Player = sandbox.player
	var hud: Hud = sandbox.hud
	var totem := waves.totem()
	match _step:
		0:
			_check(totem != null, "the Totem is there")
			if totem == null:
				_finish()
				return
			var spawn: Vector2i = p.world.spawn_column()
			var d := Vector2(totem.global_position.x - spawn.x - 0.5, totem.global_position.z - spawn.y - 0.5).length()
			_check(absf(d - WaveRules.TOTEM_DISTANCE) <= 1.0, "about 20 blocks from the spawn (%.1f)" % d)
			_check(sandbox.meta.has_totem() and sandbox.meta.totem_pos == totem.global_position, "saved in the world")
			var list_node := (sandbox.get_node("Monsters") as MonsterDirector).get_node("List")
			list_node.child_entered_tree.connect(func(n: Node) -> void: _arrived(n as Monster, p, totem))
			# Stand 3 blocks in front of it, on the ground, and wait for the terrain there.
			var front := totem.global_position + Vector3(0, 0, -3.0).rotated(Vector3.UP, totem.rotation.y)
			p.spawn_on_surface(floori(front.x), floori(front.z))
			_next(0.5)
		1:
			if not p.is_spawned() or not p.world.is_area_ready(totem.global_position):
				return
			var below := p.world.get_block(Vector3i((totem.global_position + Vector3(0, -0.5, 0)).floor()))
			_check(BlockIds.is_solid(below), "it stands on the ground (block %d under it)" % below)
			var d := totem.global_position + Vector3(0, 1.8, 0) - p.eye_position()
			p.rig.yaw = atan2(-d.x, -d.z)   # face the Totem (forward is -Z turned by yaw)
			p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
			if not p.rig.first_person:
				p.toggle_camera()   # the camera at the eye: nothing between it and the Totem
			p.rig.snap_to_target()
			_next(0.6)
		2:
			var cam := p.camera()
			var at := totem.global_position + Vector3(0, 1.8, 0)
			var interactor: BlockInteractor = p.get_node("BlockInteractor")
			_check(not cam.is_position_behind(at) and interactor.place_at_screen(cam.unproject_position(at)), "a tap on the Totem")
			_check(hud.totem_panel.visible, "a tap through the camera opens the Totem's panel")
			_check(hud.totem_panel.wave_text() == "Wave 1", "it offers wave 1 (%s)" % hud.totem_panel.wave_text())
			_gold_before = Profile.data.survivor_gold
			hud.totem_panel.start_button.pressed.emit()
			_check(not hud.totem_panel.visible, "START closes it")
			_next(0.1)
		3:
			_check(waves.phase == WaveDirector.Phase.COUNTDOWN, "the countdown runs")
			_check(hud.wave_line.visible and hud.wave_line.text().begins_with("Wave 1 starts in"), "the HUD says \"%s\"" % hud.wave_line.text())
			_check(totem.glowing(), "the Totem glows")
			_next(0.0)
		4:
			if waves.wave_monsters().size() < WaveRules.size(1, _sandbox_mode) and _step_t < 20.0:
				return
			var list := waves.wave_monsters()
			_check(list.size() == WaveRules.size(1, _sandbox_mode), "wave 1: %d monsters after %.1f s" % [list.size(), _step_t + WaveRules.COUNTDOWN])
			for a in _arrivals:
				_check(a.r >= 7.5 and a.r <= WaveRules.RING + 3.0, "%s %d appeared %.1f blocks from the Totem" % [a.kind, a.level, a.r])
				_check(BlockIds.is_solid(a.below) and a.below != BlockIds.LEAVES, "%s %d appeared on solid ground (block %d)" % [a.kind, a.level, a.below])
			_start_dist = 0.0
			for m in list:
				_check(not m.wild and m.wave == 1, "%s belongs to the wave" % m.kind)
				_start_dist += Vector2(m.global_position.x - totem.global_position.x, m.global_position.z - totem.global_position.z).length()
			_start_dist /= maxf(list.size(), 1.0)
			_check(hud.wave_line.text() == "Wave 1 — %d left" % list.size(), "the HUD says \"%s\"" % hud.wave_line.text())
			_next(0.0)
		5:
			if _step_t < 8.0:
				return
			var list := waves.wave_monsters()
			var dist := 0.0
			for m in list:
				dist += Vector2(m.global_position.x - totem.global_position.x, m.global_position.z - totem.global_position.z).length()
			dist /= maxf(list.size(), 1.0)
			_check(dist < _start_dist - 2.0, "they came towards the Totem (%.1f -> %.1f blocks on average)" % [_start_dist, dist])
			for m in list:
				m.take_hit(1000, m.global_position, Vector3.ZERO)
			_next(0.0)
		6:
			if not waves.wave_monsters().is_empty():   # small slimes (none at level 1-2), coins land
				for m in waves.wave_monsters():
					m.take_hit(1000, m.global_position, Vector3.ZERO)
				return
			if waves.phase != WaveDirector.Phase.IDLE and _step_t < 3.0:
				return
			_check(waves.phase == WaveDirector.Phase.IDLE and waves.next_wave == 2, "wave 1 won: the Totem offers wave 2")
			var got := Profile.data.survivor_gold - _gold_before
			if _sandbox_mode:
				_check(got == 0, "Sandbox: no gold (%d)" % got)
			else:
				_check(got >= 10, "Survivor: +10 gold for the wave (+%d with any coins)" % got)
			_check(not totem.glowing() and not hud.wave_line.visible, "the glow and the wave line are gone")
			sandbox.call("save_world")
			var saved := WorldSaves.load_meta(Game.slot())
			_check(saved.wave_next == 2, "world.json keeps wave 2 (%d)" % saved.wave_next)
			_check(waves.request_start(p.peer_id, 2) == &"", "wave 2 starts")
			_next(WaveRules.COUNTDOWN + 1.0)
		7:
			Session.hurt_player(p.peer_id, 100, p.global_position + Vector3(1, 0, 0))
			_next(0.5)
		8:
			if not _sandbox_mode:
				_check(waves.phase == WaveDirector.Phase.IDLE and waves.lost == 2, "a knock-out ends wave 2 (lost=%d)" % waves.lost)
				_check(waves.wave_monsters().is_empty(), "its monsters went home")
				_check(waves.next_wave == 2, "N stays 2")
			else:
				_check(waves.phase == WaveDirector.Phase.IDLE and waves.lost == 2, "Sandbox: getting knocked out ends it too")
			_next(3.0)                          # up again
		9:
			var front := totem.global_position + Vector3(0, 0, -3.0).rotated(Vector3.UP, totem.rotation.y)
			p.spawn_on_surface(floori(front.x), floori(front.z))
			hud.open_totem(totem)
			_check(hud.totem_panel.again_button.visible and hud.totem_panel.easier_button.visible,
				"the Totem offers \"%s\" and \"%s\"" % [WaveRules.TRY_AGAIN, WaveRules.TRY_EASIER])
			hud.totem_panel.close()
			_next(1.0)
		10:
			if _step_t < 3.0:
				_sample(_quiet)
				return
			waves.next_wave = 9
			waves.start(9)
			_next(WaveRules.COUNTDOWN + 0.2)
		11:
			if _step_t < 12.0:
				_sample(_busy)
				return
			var n := waves.wave_monsters().size()
			_check(n == WaveRules.size(9, _sandbox_mode), "wave 9 brought %d monsters" % n)
			var active := waves.wave_monsters().filter(func(m: Monster) -> bool: return m._active)
			print("WAVE_SMOKE cost quiet %s" % _summary(_quiet))
			print("WAVE_SMOKE cost wave_9 monsters=%d active=%d %s" % [n, active.size(), _summary(_busy)])
			waves.stop()
			_finish()


## A new wave monster: how far from the Totem it appeared and what it stands on.
func _arrived(m: Monster, p: Player, totem: Totem) -> void:
	if m == null or m.wave == 0 or _arrivals.size() >= 8:
		return
	var at := m.global_position
	_arrivals.append({"kind": m.kind, "level": m.level,
		"r": Vector2(at.x - totem.global_position.x, at.z - totem.global_position.z).length(),
		"below": p.world.get_block(Vector3i((at + Vector3(0, -0.5, 0)).floor()))})


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("WAVE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("WAVE_SMOKE result fails=%d" % _fails.size())
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
