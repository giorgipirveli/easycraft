extends Node
## The steps of tools/tutorial_smoke.gd (M3 Task 15): a new solo Survivor world on real terrain, the child's
## profile fresh for the tutorial. The offer comes (and owner #37's shop tip waits); PLAY WITH PIP; the playground
## goes into the world; then every step is done with simulated input — the stick (move_forward) and the camera's
## yaw to walk and look, JUMP pressed three times over the hole, the same edit requests a tap sends for the bridge
## and the wall, CROUCH in the bush while the practice slime is near, the bag's CRAFT page and the craft request for
## sticks, and a walk to Tilly after the shop tip's arrow. At the end: 500 gold, Pip's Cap, Pip for keeps, the
## world exactly as it was, the child never hurt by the practice slime.

const TIMEOUT := 300.0
const STEP_TIMEOUT := 60.0

var _t := 0.0
var _phase := &"load"
var _phase_t := 0.0
var _fails: Array[String] = []
var _passes := 0
var _gold_before := 0
var _record: Array = []
var _held: Dictionary = {}
var _stuck_t := 0.0
var _jumping := false
var _jump_tries := 0
var _looked := 0.0
var _crouched := false
var _hp_min := 99
var _sub := 0
var _wait := 0.0
var _report_t := 0.0
var _detour_t := 0.0
var _detour_side := 1.0
var _jump_busy := false
var _last_seen := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var seed_arg := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_arg = a.substr(7)
	Profile.data.tutorial = TutorialData.new()
	Profile.data.pip = {}
	Profile.data.cosmetics.erase("hat.pip_cap")
	Profile.data.hints_seen.erase(ShopGuide.TIP)
	Profile.data.settings.simple_controls = false
	Game.new_world_seed = int(seed_arg) if seed_arg != "" else 20260925
	Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.NORMAL, 1, SurvivorGames.CLASSIC)


func _process(delta: float) -> void:
	_t += delta
	_phase_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout in %s (step %d)" % [_phase, _tutorial().step if _tutorial() else -1])
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	if p.health:
		_hp_min = mini(_hp_min, p.health.hp)
	_run(sandbox, p, delta)


func _tutorial() -> TutorialDirector:
	var s := get_tree().current_scene
	return s.get("tutorial") as TutorialDirector if s else null


func _go(phase: StringName) -> void:
	print("TUTORIAL_SMOKE phase %s at %.1f s" % [phase, _t])
	_phase = phase
	_phase_t = 0.0
	_sub = 0
	_stuck_t = 0.0
	Input.action_release(&"move_forward")


func _run(sandbox: Node, p: Player, delta: float) -> void:
	var tut := _tutorial()
	match _phase:
		&"load":
			if not tut.offer.is_open() and _phase_t < 10.0:
				return
			_check(tut.offer.is_open(), "the first solo Survivor start offers PLAY WITH PIP / SKIP (%.1f s after the spawn)" % _phase_t)
			_check(not Profile.data.hints_seen.has(ShopGuide.TIP) and tut.holds_tip(), "the shop tip waits for it")
			_gold_before = Profile.data.survivor_gold
			tut.offer.play_button.pressed.emit()
			_go(&"placed")
		&"placed":
			if not tut.is_laid_out():
				if _phase_t > 20.0:
					_check(false, "the playground never went in (site %s)" % tut.site)
					_finish()
				return
			_record = tut.record.duplicate(true)
			var world: WorldService = sandbox.world
			for e: Array in _record:
				_held[Vector3i(e[0], e[1], e[2])] = int(e[3])
			var meta: WorldMeta = sandbox.meta
			_check(meta.tutorial_props == _record, "the playground is recorded in the world's meta (%d cells)" % _record.size())
			var saved := WorldSaves.load_meta(Game.slot())
			_check(saved.tutorial_props.size() == _record.size(), "and saved to disk before it went in")
			_check(world.get_block(TutorialCourse.bench(tut.site)) == BlockIds.CRAFTING_TABLE, "Pip's Workbench stands at %s" % TutorialCourse.bench(tut.site))
			_check(tut.pip_node.call() != null, "a visiting Pip rolls beside the child")
			for a: int in [-1, 0, 1]:
				var col := []
				for dy in range(-3, 4):
					col.append(world.get_block(TutorialCourse.cell(tut.site, a, 0, dy)))
				print("TUTORIAL_SMOKE   start column a %d (y0-3..y0+3): %s" % [a, col])
			print("TUTORIAL_SMOKE site %s dir %d, %.1f blocks from the spawn" % [tut.site.origin, tut.site.dir,
				Vector2(tut.site.origin.x, tut.site.origin.z).distance_to(Vector2(sandbox.world.spawn_column()))])
			_go(&"move")
		&"move":
			if tut.step > 0:
				_check(true, "move and look (%.1f s)" % _phase_t)
				_go(&"jump")
				return
			if _steer(p, TutorialCourse.start_pos(tut.site), delta):
				p.rig.yaw += delta * 2.0   # look around
				_looked += delta * 2.0
			_timeout(tut)
		&"jump":
			_jump_step(tut, p, delta)
		&"bridge":
			if tut.step > 2:
				_check(true, "the bridge (%.1f s)" % _phase_t)
				_go(&"wall")
				return
			if _sub == 0:   # a step back from the hole (never where the blocks go), this side or the far one
				var past := TutorialCourse.local(tut.site, p.global_position).x > TutorialCourse.BRIDGE_TO
				var stand := TutorialCourse.BRIDGE_TO + 2 if past else TutorialCourse.LAND_FROM + 1
				if _steer(p, TutorialCourse.spot(tut.site, stand, 0), delta):
					_sub = 1
			elif _sub == 1:
				for a in range(TutorialCourse.BRIDGE_FROM, TutorialCourse.BRIDGE_TO + 1):
					Session.request_set_block(TutorialCourse.cell(tut.site, a, 0, -1), BlockIds.PLANKS)
				_sub = 2
				_wait = 1.5
			elif _sub == 2:
				_wait -= delta
				if _wait <= 0.0:
					_sub = 0   # a block was refused (someone stood there): again
			_timeout(tut)
		&"wall":
			if tut.step > 3:
				_check(true, "the wall (%.1f s)" % _phase_t)
				_go(&"hide")
				return
			if _sub == 0:
				if _steer(p, TutorialCourse.spot(tut.site, TutorialCourse.WALL_A - 1, 0), delta):
					_sub = 1
			elif _sub == 1:
				for dy in TutorialCourse.WALL_HIGH:
					Session.request_set_block(TutorialCourse.cell(tut.site, TutorialCourse.WALL_A, 0, dy), BlockIds.AIR)
				_sub = 2
			_timeout(tut)
		&"hide":
			if tut.step > 4:
				_check(true, "hid in the bush from the practice slime (%.1f s)" % _phase_t)
				if p.crouching:
					_tap(&"crouch")
				_go(&"craft")
				return
			var bush: Vector2i = TutorialCourse.BUSHES[0]
			if _sub == 0:
				if _steer(p, TutorialCourse.spot(tut.site, TutorialCourse.WALL_A, 0), delta):
					_sub = 1
			elif _sub == 1:
				if _steer(p, TutorialCourse.spot(tut.site, bush.x, bush.y), delta):
					_sub = 2
					_wait = 0.0
			elif _sub == 2:
				_wait -= delta
				if not p.crouching and _wait <= 0.0:
					_tap(&"crouch")   # C: crouch in the bush
					_wait = 1.0
			_timeout(tut)
		&"craft":
			if tut.step > 5:
				_check(true, "made sticks (%.1f s)" % _phase_t)
				_go(&"tilly")
				return
			if _sub == 0:
				var hud: Hud = sandbox.hud
				hud.palette.open()
				_check(hud.palette.tab_bar.current_tab == BlockPalette.CRAFT_PAGE, "the bag opens on CRAFT")
				hud.palette.visible = false
				Session.request_craft(&"sticks")
				_sub = 1
			_timeout(tut)
		&"tilly":
			if not tut.is_running():
				_check(true, "visited Tilly (%.1f s)" % _phase_t)
				_go(&"end")
				return
			if _phase_t < 0.3:
				return
			if _sub == 0:
				_check(Profile.data.hints_seen.has(ShopGuide.TIP), "owner #37's shop tip and its arrow at Tilly")
				_sub = 1
			var t: Node3D = tut.tilly.call()
			if t:
				_steer(p, t.global_position, delta)
				_wait -= delta
				if _wait <= 0.0:
					_wait = 5.0
					var hub: UniverseHub = sandbox.get("universe_hub")
					print("TUTORIAL_SMOKE walking to Tilly: at %s, she is at %s (%.1f blocks); hub circle at %s, velocity %s, floor %s" % [
						p.global_position.snapped(Vector3.ONE * 0.1), t.global_position.snapped(Vector3.ONE * 0.1),
						p.eye_position().distance_to(t.global_position), hub.circle.position if hub and hub.circle else "-",
						p.velocity.snapped(Vector3.ONE * 0.1), p.is_on_floor()])
					var ahead := Vector3i((p.global_position + p.rig.forward_flat() * 0.8).floor())
					var col := []
					for dy in range(-1, 4):
						col.append((sandbox.world as WorldService).get_block(ahead + Vector3i(0, dy, 0)))
					print("TUTORIAL_SMOKE   ahead %s: %s; crouching %s hiding %s" % [ahead, col, p.crouching, p.is_hiding()])
					for n in sandbox.find_children("*", "CollisionObject3D", true, false):
						var b := n as Node3D
						if b != p and b.global_position.distance_to(p.global_position) < 4.0:
							print("TUTORIAL_SMOKE   near body %s at %s" % [b.get_path(), b.global_position.snapped(Vector3.ONE * 0.1)])
			_timeout(tut)
		&"end":
			if tut.is_clearing() and _phase_t < 10.0:
				return   # the cells go back a batch a tick
			_end_checks(sandbox, tut)
			_finish()


func _jump_step(tut: TutorialDirector, p: Player, delta: float) -> void:
	if tut.step > 1:
		_check(true, "jumped the hole (%d tries, %.1f s)" % [_jump_tries + 1, _phase_t])
		Input.action_release(&"move_forward")
		_go(&"bridge")
		return
	var here := TutorialCourse.local(tut.site, p.global_position)
	var seen := "%d/%s/%s" % [TutorialCourse.zone(tut.site, p.global_position), p.is_on_floor(), tut._jump.armed]
	if seen != _last_seen:
		_last_seen = seen
		print("TUTORIAL_SMOKE   jump zone/floor/armed %s at course %s y %.1f" % [seen, here, p.global_position.y])
	match _sub:
		0:   # back to the start, facing along the course
			if _steer(p, TutorialCourse.start_pos(tut.site), delta) and not _jump_busy and p.is_on_floor():
				var d := TutorialCourse.dir_of(tut.site)
				p.rig.yaw = atan2(-float(d.x), -float(d.y))
				_jumping = false
				_sub = 1
		1:   # run at the hole, three jumps from its edge (the first from the ground)
			Input.action_press(&"move_forward")
			if here.x >= 1 and not _jumping and not _jump_busy and p.is_on_floor():
				_jumping = true
				_triple_jump()
			if TutorialCourse.zone(tut.site, p.global_position) == TutorialCourse.PIT and p.is_on_floor():
				_jump_tries += 1
				_jumping = false
				Input.action_release(&"move_forward")
				_sub = 0   # fell in: climb out and try again
	_timeout(tut)


func _triple_jump() -> void:
	_jump_busy = true
	for i in 3:
		Input.action_press(&"jump")
		await get_tree().create_timer(0.05).timeout
		Input.action_release(&"jump")
		await get_tree().create_timer(0.22).timeout
	_jump_busy = false


## Walks to `target` (the camera turned that way, the stick forward); jumps when stuck. True when there.
func _steer(p: Player, target: Vector3, delta: float) -> bool:
	var to := target - p.global_position
	to.y = 0.0
	if to.length() < 0.6:
		Input.action_release(&"move_forward")
		return true
	p.rig.yaw = atan2(-to.x, -to.z)
	if _detour_t > 0.0:   # stuck against something a jump can't clear (a stone of the circle): round it
		_detour_t -= delta
		p.rig.yaw += _detour_side * 1.2
	Input.action_press(&"move_forward")
	if Vector2(p.velocity.x, p.velocity.z).length() < 0.8:
		_stuck_t += delta
		if _stuck_t > 0.6 and p.is_on_floor() and not _jump_busy:
			_triple_jump()
		if _stuck_t > 2.0:
			_stuck_t = 0.0
			_detour_t = 1.2
			_detour_side = -_detour_side
	else:
		_stuck_t = 0.0
	return false


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().create_timer(0.05).timeout
	Input.action_release(action)


func _timeout(tut: TutorialDirector) -> void:
	_report_t -= get_process_delta_time()
	var p: Player = get_tree().current_scene.get("player")
	if _report_t <= 0.0 and p and not tut.site.is_empty():
		_report_t = 5.0
		print("TUTORIAL_SMOKE   %s: at %s (course %s), step %d, sub %d, velocity %s, floor %s" % [_phase,
			p.global_position.snapped(Vector3.ONE * 0.1), TutorialCourse.local(tut.site, p.global_position), tut.step, _sub,
			p.velocity.snapped(Vector3.ONE * 0.1), p.is_on_floor()])
	if _phase_t > STEP_TIMEOUT:
		_check(false, "step %d (%s) not done in %.0f s" % [tut.step, _phase, STEP_TIMEOUT])
		_finish()


func _end_checks(sandbox: Node, tut: TutorialDirector) -> void:
	_check(Profile.data.survivor_gold >= _gold_before + TutorialRules.REWARD_GOLD,
		"500 Survivor gold (%d -> %d)" % [_gold_before, Profile.data.survivor_gold])
	_check(Profile.data.cosmetics.has("hat.pip_cap"), "Pip's Cap")
	_check(not Profile.data.pip.is_empty() and tut.pip_node.call() != null, "Pip is the child's pet now, and stays")
	_check(Profile.data.tutorial.state == TutorialData.DONE and Profile.data.tutorial.rewarded, "done, rewarded once")
	_check(tut.offer.is_open(), "the reward card")
	var meta: WorldMeta = sandbox.meta
	_check(meta.tutorial_props.is_empty(), "nothing of the playground is kept in the meta")
	var world: WorldService = sandbox.world
	var wrong := 0
	for c: Vector3i in _held:
		if world.get_block(c) != int(_held[c]):
			wrong += 1
	_check(wrong == 0, "every one of the %d cells is back as it was (%d not)" % [_held.size(), wrong])
	_check(_hp_min >= Health.MAX_HP, "the practice slime never hurt the child (lowest hearts %d)" % _hp_min)
	var slimes := 0
	for m: Monster in (sandbox.get("_monsters") as MonsterDirector).monsters():
		if m.practice:
			slimes += 1
	_check(slimes == 0, "the practice slime is gone")


func _check(ok: bool, what: String) -> void:
	print("TUTORIAL_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if ok:
		_passes += 1
	else:
		_fails.append(what)


func _finish() -> void:
	Input.action_release(&"move_forward")
	print("TUTORIAL_SMOKE result passes=%d fails=%d" % [_passes, _fails.size()])
	get_tree().quit(0 if _fails.is_empty() else 1)
	set_process(false)
