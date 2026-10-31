extends Node
## The steps of one game of tools/ghost_net_test.sh (M4 ghost races), over the real Nakama client and server:
## hopper: signs in, claims his name, asks Mia to be friends, puts his showcase up with a course and shares his
##   best run on it (share_ghost), waits for Mia's sticker in his guestbook, then deletes his test account.
## mia: signs in, claims her name, says yes to Hopper, waits for his ghost (list_ghosts), visits his showcase (the
##   real visit scene) and races his ghost there, leaves a sticker, finds the showcase kept on her device for
##   offline races, then deletes her test account.

const TIMEOUT := 200.0
const NAKAMA_BACKEND := "res://net/nakama_online_backend.gd"
const WORLD := "networld:1"
const ORIGIN := Vector3i(0, 20, 0)
const START := Vector3i(1, 0, 1)
const FINISH := Vector3i(8, 0, 1)

var role := ""
var hopper_name := ""
var mia_name := ""
var service: OnlineService
var _fails: Array[String] = []
var _t0 := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_t0 = Time.get_ticks_msec()
	var server := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--role="):
			role = a.trim_prefix("--role=")
		elif a.begins_with("--server="):
			server = a.trim_prefix("--server=")
		elif a.begins_with("--hopper="):
			hopper_name = a.trim_prefix("--hopper=")
		elif a.begins_with("--mia="):
			mia_name = a.trim_prefix("--mia=")
	service = OnlineService.new()
	service.backend = (load(NAKAMA_BACKEND) as GDScript).new()
	service.server = OnlineConfig.parse_server(server)
	Session.use_online_service(service)
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	var watchdog := get_tree().create_timer(TIMEOUT)
	watchdog.timeout.connect(func() -> void:
		_check(false, "timeout")
		_done())
	if role == "hopper":
		await _hopper()
	else:
		await _mia()
	_done()


func _hopper() -> void:
	if not await _sign_in(hopper_name):
		return
	var asked := await _until_ok(func() -> String: return await service.add_friend(mia_name), 60.0)
	_check(asked, "Hopper asks Mia to be friends")
	_check(await _until(func() -> bool: return await _friend_state(mia_name) == OnlineRules.FRIEND, 60.0), "Mia said yes")
	_check(await service.publish_showcase(_area()) == "", "Hopper's showcase is up")
	var g := _run_ghost()
	var t := Time.get_ticks_msec()
	var r: Dictionary = await service.share_showcase_ghosts([{"start": ORIGIN + START, "ghost": g}] as Array[Dictionary],
		WORLD, ORIGIN, Vector3i(10, 3, 4))
	print("GHOSTNET MEASURE share_ghost %d ms" % (Time.get_ticks_msec() - t))
	_check(r.text == "" and int(r.shared) == 1, "his race is on it (%s)" % r.text)
	var signed := await _until(func() -> bool:
		var mine: Dictionary = await service.my_showcase()
		return (mine.guestbook as Array).any(func(e: Dictionary) -> bool: return e.from == mia_name and e.sticker == "trophy"), 120.0)
	_check(signed, "Mia raced his ghost and left him a trophy")
	await _delete()


func _mia() -> void:
	if not await _sign_in(mia_name):
		return
	var said_yes := await _until(func() -> bool:
		await service.refresh_friends()
		for f: Dictionary in service.friends:
			if f.username == hopper_name and f.state == OnlineRules.RECEIVED:
				return await service.accept(f.id) == ""
		return false, 60.0)
	_check(said_yes, "Mia says yes to Hopper")
	var found: Array[String] = []   # a lambda captures locals by value: an array carries the id out
	await _until(func() -> bool:
		await service.refresh_friends()
		for f: Dictionary in service.friends:
			if f.username == hopper_name and f.state == OnlineRules.FRIEND:
				found.append(str(f.id))
		return not found.is_empty(), 30.0)
	var hopper_id := found[0] if not found.is_empty() else ""
	var got := await _until(func() -> bool: return ((await service.ghosts_of(hopper_id)).ghosts as Array).size() == 1, 60.0)
	_check(got, "Hopper's ghost is there for Mia (list_ghosts)")
	var t := Time.get_ticks_msec()
	var r: Dictionary = await service.showcase_of(hopper_id)
	print("GHOSTNET MEASURE the showcase with its ghosts %d ms" % (Time.get_ticks_msec() - t))
	_check(r.text == "" and (r.showcase.get("ghosts", []) as Array).size() == 1, "the showcase comes with his ghost")
	Session.start_visit(r.showcase)
	var arrived := await _until(func() -> bool:
		var v := get_tree().current_scene as VisitWorld
		return v != null and v.player != null and v.player.is_spawned(), 30.0)
	_check(arrived, "Mia is in the visit")
	if arrived:
		await _race((get_tree().current_scene as VisitWorld), r.showcase.ghosts[0])
	_check(await service.sign_guestbook(hopper_id, "trophy") == "", "Mia leaves a trophy")
	var kept := service.kept_showcase(hopper_id)
	_check(kept.get("offline", false) and (kept.get("ghosts", []) as Array).size() == 1, "kept on her device for offline races")
	# Hopper deletes his account once he has seen her sticker (deleting hers first would take the sticker away).
	await _until(func() -> bool: return str((await service.ghosts_of(hopper_id)).text) != "", 60.0)
	await _delete()


func _race(v: VisitWorld, g: RaceGhost) -> void:
	var start := v.generator.origin + g.start
	var finish := v.generator.origin + g.finish
	v.races.look_around()
	var runner := v.races.runner_at(start)
	_check(runner != null and runner.avatar.look().hat == &"crown", "his ghost waits on his START, in his look")
	_check(runner != null and runner.find_children("*", "CollisionObject3D", true, false).is_empty(), "it can't be touched")
	var got: Array = []
	v.courses.state_changed.connect(func(s: Dictionary) -> void: got.append(s))
	var p := v.player
	p.set_physics_process(false)
	p.global_position = CourseRules.top_of(start)
	for i in 20:
		await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:
		p.global_position = CourseRules.top_of(start).lerp(CourseRules.top_of(finish), (Time.get_ticks_msec() - t0) / 1500.0)
		await get_tree().process_frame
	p.global_position = CourseRules.top_of(finish)
	await _until(func() -> bool: return got.any(func(s: Dictionary) -> bool: return s.get("event") == "finish"), 5.0)
	var done: Array = got.filter(func(s: Dictionary) -> bool: return s.get("event") == "finish")
	var line := str(done.back().get("ghost_line", "")) if not done.is_empty() else ""
	print("GHOSTNET mia finish %s" % [done.back() if not done.is_empty() else {}])
	_check(line.begins_with("You beat %s's ghost!" % hopper_name), "she beats his ghost: %s" % line)
	_check(runner != null and runner.t > 0.0, "the ghost ran")


func _sign_in(username: String) -> bool:
	var err: String = await service.sign_in()
	_check(err == "", "%s signs in (%s)" % [role, err])
	if err != "":
		return false
	var claim: String = await service.claim_username(username)
	_check(claim == "", "%s claims %s (%s)" % [role, username, claim])
	return claim == ""


func _friend_state(username: String) -> StringName:
	await service.refresh_friends()
	for f: Dictionary in service.friends:
		if f.username == username:
			return f.state
	return &""


## A 10 x 3 x 4 area: a stone floor with a course, START at (1, 0, 1), FINISH at (8, 0, 1).
func _area() -> String:
	var b := {}
	for x in 10:
		for z in 4:
			b[Vector3i(x, 0, z)] = BlockIds.STONE
	b[START] = BlockIds.START
	b[FINISH] = BlockIds.FINISH
	return BuildCodec.encode(b, Vector3i(10, 3, 4))


## Hopper's 3 s run along the course (10 samples a second), in his look (a crown).
func _run_ghost() -> RaceGhost:
	var run := RecordedRun.new(CourseRules.top_of(START))
	for i in 31:
		run.add(CourseRules.top_of(START).lerp(CourseRules.top_of(FINISH), i / 30.0))
	var look := AvatarLook.new()
	look.hat = &"crown"
	return RaceGhost.from_run(run, 3000, START, FINISH, look.to_code())


func _delete() -> void:
	var start: Dictionary = await service.delete_account_start()
	var err: String = await service.delete_account(str(start.get("confirm", ""))) if start.get("text", "") == "" else str(start.text)
	_check(err == "", "%s's test account is deleted (%s)" % [role, err])


func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		if await cond.call():
			return true
		await get_tree().create_timer(0.5).timeout
	return false


func _until_ok(call: Callable, seconds: float) -> bool:
	return await _until(func() -> bool: return await call.call() == "", seconds)


func _check(ok: bool, what: String) -> void:
	print("GHOSTNET %s %s %s" % [role, "ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


var _finished := false


func _done() -> void:
	if _finished:
		return
	_finished = true
	print("GHOSTNET %s done failed=%d in %d ms" % [role, _fails.size(), Time.get_ticks_msec() - _t0])
	Session.use_online_service(null)
	get_tree().quit(0 if _fails.is_empty() else 1)
