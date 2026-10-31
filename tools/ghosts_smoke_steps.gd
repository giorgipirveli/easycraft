extends Node
## The steps of tools/ghosts_smoke.gd (M4 ghost races), on real terrain through the real systems: Hopper's new
## Sandbox world with this device's OnlineService on the game's fake server; a course of real blocks raced with
## his feet on them (M3 Task 7's watcher and timer); SHARE's MY SHOWCASE (his race goes with it); a faster run (it
## replaces his ghost); GIFT A BUILD of the whole course (his race comes too); Mia visits his showcase and races
## his ghost (the visit scene), again offline from her device's copy, then stamps his gift in her own new world
## and races his ghost there. MEASURE lines time the runs, the ghost's frames and the visit.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const TIMEOUT := 300.0
const LENGTH := 6                  # FINISH is this many blocks from START

var server: RefCounted
var hopper: OnlineService
var mia: OnlineService
var _t := 0.0
var _step := -1
var _step_t := 0.0
var _fails: Array[String] = []
var _busy := false
var _start := Vector3i.ZERO
var _finish := Vector3i.ZERO
var _hopper_ms := 0
var _dir := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup()


func _setup() -> void:
	_busy = true
	_dir = OS.get_user_data_dir()
	server = FakeServer.new()
	server.make_account("smoke-hopper", "Hopper")
	server.make_account("smoke-mia", "Mia_2")
	server.befriend(server.id_of("Hopper"), server.id_of("Mia_2"))
	hopper = _service("smoke-hopper", "Hopper")
	mia = _service("smoke-mia", "Mia_2")
	add_child(mia)
	Session.use_online_service(hopper)
	_use_books(hopper)
	_check(await hopper.sign_in() == "", "Hopper signs in (the fake server)")
	_check(await mia.sign_in() == "", "Mia signs in")
	await hopper.refresh_friends()
	await mia.refresh_friends()
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	_step = 0
	_busy = false


func _service(device: String, username: String) -> OnlineService:
	var s := OnlineService.new()
	s.name = "Smoke_" + username
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = _dir.path_join(device + "_online.json")
	s.gift_book = GiftStampBook.new()
	s.gift_book_path = _dir.path_join(device + "_gifts.json")
	s.ghost_book = GhostBook.new()
	s.ghost_book_path = _dir.path_join(device + "_ghosts.json")
	s.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	return s


## The game reads this device's books (the stamps' blocks, the ghosts): the player whose device it is now.
func _use_books(s: OnlineService) -> void:
	GiftStampBook.use(s.gift_book, s.gift_book_path)
	GhostBook.use(s.ghost_book, s.ghost_book_path)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish_run()
		return
	if _busy or _step < 0:
		return
	_step_t += delta
	var scene := get_tree().current_scene
	if scene == null or scene.get("player") == null or not (scene.player as Player).is_spawned():
		return
	_busy = true
	await _run_step(scene)
	_busy = false


func _next() -> void:
	_step += 1
	_step_t = 0.0


func _run_step(scene: Node) -> void:
	match _step:
		0:   # Hopper builds a course: a planks lane with START and FINISH, at his feet's level
			var p: Player = scene.player
			var feet := Vector3i(p.global_position.floor())
			_start = feet + Vector3i(0, -1, 3)
			_finish = _start + Vector3i(LENGTH, 0, 0)
			var changes: Array = []
			for x in range(0, LENGTH + 1):   # 7 wide: a gift is 8 at most
				for dz in [-1, 0, 1]:
					var c := _start + Vector3i(x, 0, dz)
					changes.append([c, BlockIds.PLANKS])
					for up in range(1, 4):
						changes.append([c + Vector3i(0, up, 0), BlockIds.AIR])
			changes.append([_start, BlockIds.START])
			changes.append([_finish, BlockIds.FINISH])
			Session.request_set_blocks(changes)
			await _frames(10)
			_check(scene.world.get_block(_start) == BlockIds.START and scene.world.get_block(_finish) == BlockIds.FINISH,
				"a course from %s to %s" % [_start, _finish])
			_next()
		1:   # he races it: 3 s along the lane, his feet on the real blocks
			var s := await _race(scene, scene.player, scene.get("_courses"), _start, _finish, 3.0)
			_check(str(s.get("event", "")) == "finish", "FINISH stops his clock (%s)" % [s])
			_check(bool(s.get("mine_best", false)), "his own best on his own course")
			var book: CourseBook = (scene.get("_courses") as CourseDirector).book
			_check(book.mine(_start) != null and book.mine(_start).size() >= 20, "his run is recorded")
			_hopper_ms = book.mine_ms(_start)
			print("MEASURE Hopper's first run %d ms" % _hopper_ms)
			_next()
		2:   # SHARE → MY SHOWCASE → SHOW IT: his race goes with it
			var panel: SharePanel = scene.get("share_panel")
			panel.open()
			panel.start_area()
			panel.publish()
			await _until(func() -> bool: return not panel.visible, 15.0)
			var ghosts: Array = server.showcase_ghosts.get(server.id_of("Hopper"), [])
			_check(ghosts.size() == 1, "his race is on his showcase (%s)" % panel.message.text)
			if ghosts.size() == 1:
				_check(int(ghosts[0].ms) == _hopper_ms, "with his time")
				_check(ghosts[0].look == Profile.data.avatar.to_code(), "in his look")
			_next()
		3:   # a faster run: the new best replaces his ghost
			var s := await _race(scene, scene.player, scene.get("_courses"), _start, _finish, 2.0)
			_check(bool(s.get("mine_best", false)), "a new best")
			var book: CourseBook = (scene.get("_courses") as CourseDirector).book
			var best := book.mine_ms(_start)
			await _until(func() -> bool: return int(_ghost_ms()) == best, 5.0)
			_check(_ghost_ms() == best and best < _hopper_ms, "it replaced his ghost on the showcase (%d -> %d ms)" % [_hopper_ms, best])
			_hopper_ms = best
			_next()
		4:   # GIFT A BUILD: the whole course, his race comes too
			var panel: SharePanel = scene.get("share_panel")
			panel.open()
			panel.start_pick()
			panel.pick_cell(_start)
			_check(panel.picked_ghost != null, "the picked course carries his race (%d blocks)" % (panel.picked.get("blocks", {}) as Dictionary).size())
			_check(panel.find_child("RaceComes", true, false) != null, "the panel says so")
			panel.show_friends()
			(panel.find_child("Friend_Mia_2", true, false) as Button).pressed.emit()
			await _until(func() -> bool: return not panel.visible, 5.0)
			var sent: Array = server.gifts.get(server.id_of("Mia_2"), [])
			_check(sent.size() == 1 and (sent[0] as Dictionary).has("ghost"), "Mia's present has his race in it")
			await mia.refresh_gifts()
			if not mia.gifts.is_empty():
				_gift_slot = int((await mia.open_gift(mia.gifts[0].id)).slot)
			_check(_gift_slot >= 0 and mia.ghost_race_in_slot(_gift_slot), "Mia opens it: a stamp with his race")
			_next()
		5:   # Mia visits Hopper's showcase (he is away)
			var r: Dictionary = await mia.showcase_of(hopper.backend.user_id())
			_check(r.text == "" and (r.showcase.get("ghosts", []) as Array).size() == 1, "Mia gets the showcase with his ghost")
			hopper.sign_out()
			Session.use_online_service(mia)
			_use_books(mia)
			_visit_start = Time.get_ticks_msec()
			Session.start_visit(r.showcase)
			_next()
		6:   # in the visit: his ghost waits on his START; she races it
			var v := scene as VisitWorld
			if v == null:
				return
			print("MEASURE visit: the visitor stands on the island %d ms after VISIT" % (Time.get_ticks_msec() - _visit_start))
			await _race_visit(v, "online")
			await _frames(5)
			server.down = true
			mia.sign_out()
			var kept := mia.kept_showcase(server.id_of("Hopper"))
			_check(kept.get("offline", false) and (kept.get("ghosts", []) as Array).size() == 1, "offline: her device kept it")
			Session.start_visit(kept)
			_next()
		7:   # the offline visit
			var v := scene as VisitWorld
			if v == null or not v.showcase.get("offline", false):
				return
			await _race_visit(v, "offline")
			server.down = false
			_check(await mia.sign_in() == "", "Mia is back online")
			Game.start_new_world = true
			get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
			_next()
		8:   # Mia's own new world: she stamps Hopper's gift; his race waits on its START
			if scene is VisitWorld or not scene.has_method(&"gh_world_key"):
				return
			var p: Player = scene.player
			p.set_physics_process(false)
			p.rig.yaw = 0.0
			var feet := Vector3i(p.global_position.floor())
			var anchor := feet + Vector3i(0, 0, -4)
			var clear: Array = []
			for x in range(-5, 6):
				for z in range(-6, -1):
					clear.append([feet + Vector3i(x, -1, z), BlockIds.STONE])
					for up in range(0, 3):
						clear.append([feet + Vector3i(x, up, z), BlockIds.AIR])
			Session.request_set_blocks(clear)
			await _frames(5)
			var item := GiftStampBook.item_of(_gift_slot)
			var ok: bool = scene.get("_interactor").call("_stamp", item, anchor)
			await _frames(5)
			var g: RaceGhost = GhostBook.current().gift_entry(_gift_slot).get("ghost")
			var start := GhostShare.stamped_start(g, GiftStampBook.current().blocks_of(_gift_slot), anchor, Vector3i(0, 0, -1))
			_check(ok and scene.world.get_block(start) == BlockIds.START, "the stamp puts his course down (START at %s)" % start)
			var races: GhostRaces = scene.get("ghost_races")
			races.look_around()
			_check(races.runner_at(start) != null, "his race waits on its START in her world")
			var finish := start + Vector3i(LENGTH, 0, 0)
			_check(scene.world.get_block(finish) == BlockIds.FINISH, "and its FINISH")
			var s := await _race(scene, p, scene.get("_courses"), start, finish, 1.5)
			_check(str(s.get("ghost_line", "")).begins_with("You beat Hopper's ghost!"), "she beats his ghost: %s" % s.get("ghost_line", ""))
			_check(s.get("medal", "") == String(CourseRules.GOLD), "gold against his time")
			_check(not GhostBook.current().placed_in(scene.call("gh_world_key")).is_empty(), "kept for her next visit to this world")
			_next()
		_:
			_finish_run()


var _visit_start := 0
var _gift_slot := -1


## Hopper's ghost's time on the server.
func _ghost_ms() -> int:
	var ghosts: Array = server.showcase_ghosts.get(server.id_of("Hopper"), [])
	return int(ghosts[0].ms) if not ghosts.is_empty() else -1


## A race in a visit: his ghost waits on START; she runs in 4 s against his time.
func _race_visit(v: VisitWorld, how: String) -> void:
	var g: RaceGhost = (v.showcase.ghosts as Array)[0]
	var start := v.generator.origin + g.start
	var finish := v.generator.origin + g.finish
	v.races.look_around()
	var runner := v.races.runner_at(start)
	_check(runner != null, "%s: his ghost waits on his START in the visit" % how)
	_check(runner != null and runner.avatar.look().to_code() == AvatarLook.from_code(g.look).to_code(), "%s: in his look" % how)
	_check(runner != null and runner.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s: it can't be touched" % how)
	_frame_ms.clear()
	var s := await _race(v, v.player, v.courses, start, finish, 4.0)
	var worst := 0.0
	var total := 0.0
	for f in _frame_ms:
		worst = maxf(worst, f)
		total += f
	print("MEASURE %s visit race: %d frames, avg %.1f ms, worst %.1f ms (headless, load %s)" % [how, _frame_ms.size(),
		total / maxf(_frame_ms.size(), 1), worst, _load()])
	_check(str(s.get("event", "")) == "finish", "%s: she finishes (%s)" % [how, s])
	_check(str(s.get("ghost_line", "")) == "Hopper's ghost got there first. Race again!%s" % _prize(int(s.get("ms", 0))),
		"%s: %s" % [how, s.get("ghost_line", "")])
	_check(runner == null or not runner.running or runner.t > 0.0, "%s: the ghost ran" % how)


func _prize(ms: int) -> String:
	var m := GhostRaceRules.medal(ms, _hopper_ms)
	return ("  " + String(m).to_upper() + "!") if m != &"" else ""


var _frame_ms: Array[float] = []


## Runs `p` from START's top to FINISH's top in `seconds` (its feet on the blocks: the course's watcher sees them),
## and gives back the finish state its game got.
func _race(scene: Node, p: Player, courses: CourseDirector, start: Vector3i, finish: Vector3i, seconds: float) -> Dictionary:
	p.set_physics_process(false)
	var got: Array = []
	var on_state := func(s: Dictionary) -> void: got.append(s)
	courses.state_changed.connect(on_state)
	p.global_position = CourseRules.top_of(start)
	await _frames(20)
	var from := CourseRules.top_of(start)
	var to := CourseRules.top_of(finish)
	var t0 := Time.get_ticks_msec()
	while true:
		var t := (Time.get_ticks_msec() - t0) / 1000.0
		p.global_position = from.lerp(to, minf(t / seconds, 1.0))
		var f0 := Time.get_ticks_usec()
		await get_tree().process_frame
		_frame_ms.append((Time.get_ticks_usec() - f0) / 1000.0)
		if t >= seconds:
			break
	await _until(func() -> bool: return got.any(func(s: Dictionary) -> bool: return s.get("event") == "finish"), 5.0)
	courses.state_changed.disconnect(on_state)
	p.global_position = to + Vector3(0, 0, 2)
	var done: Array = got.filter(func(s: Dictionary) -> bool: return s.get("event") == "finish")
	if is_instance_valid(scene) and scene.get("hud"):
		print("GHOSTS_SMOKE toast '%s'" % (scene.hud as Hud)._toast_label.text)
	return done.back() if not done.is_empty() else {}


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until(cond: Callable, seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < end:
		await get_tree().process_frame


func _load() -> String:
	var f := FileAccess.open("/proc/loadavg", FileAccess.READ)
	return f.get_line().split(" ")[0] if f else "?"


func _check(ok: bool, what: String) -> void:
	print("GHOSTS_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish_run() -> void:
	print("GHOSTS_SMOKE done failed=%d" % _fails.size())
	set_process(false)
	Session.use_online_service(null)
	get_tree().quit(0 if _fails.is_empty() else 1)
