extends Node
## The steps of tools/net_test_move.gd (owner #99: the same name on a new device, with proof).

const TIMEOUT := 150.0
const NAKAMA_BACKEND := "res://net/nakama_online_backend.gd"
const UNIVERSE := 3   # the old game's progress, which must reach the new one

var _role := ""
var _me := ""
var _code_file := ""
var service: OnlineService
var _news: Array[String] = []
var _nudged := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var server := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--role="):
			_role = a.trim_prefix("--role=")
		elif a.begins_with("--me="):
			_me = a.trim_prefix("--me=")
		elif a.begins_with("--server="):
			server = a.trim_prefix("--server=")
		elif a.begins_with("--code-file="):
			_code_file = a.trim_prefix("--code-file=")
	if not DeviceMoveRules.enabled:   # the quick-ship round: the move by code is off (and on the server: 0.2.20)
		print("NETMOVE %s SKIP the move by code is off (DeviceMoveRules.enabled, MoveRules.ENABLED)" % _role)
		get_tree().quit(3)
		return
	get_tree().create_timer(TIMEOUT).timeout.connect(func() -> void: _done(false, "timeout"))
	service = OnlineService.new()
	service.backend = (load(NAKAMA_BACKEND) as GDScript).new()
	service.server = OnlineConfig.parse_server(server)
	service.move_card = false
	Session.use_online_service(service)
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	service.move_news.connect(func(t: String) -> void: _news.append(t))
	service.move_nudged.connect(func(_w: String) -> void: _nudged = true)
	var err: String = await service.sign_in()
	if err != "":
		_done(false, "sign in: %s" % err)
		return
	if _role == "old":
		await _old()
	else:
		await _new()


func _old() -> void:
	var err: String = await service.claim_username(_me)
	if err != "":
		_done(false, "claim %s: %s" % [_me, err])
		return
	Profile.data.universe_unlocked = UNIVERSE
	Profile.save()
	await service.profile_sync.sync()
	print("NETMOVE old ready as %s (universe %d backed up)" % [_me, UNIVERSE])
	if not await _until(func() -> bool:
			if service.move_asks.is_empty():
				await service.refresh_move_asks()
			return not service.move_asks.is_empty(), 60.0):
		_done(false, "no ask reached this device")
		return
	var ask: Dictionary = service.move_asks[0]
	print("NETMOVE old the card: %s" % DeviceMoveRules.ask_text(_me, str(ask.kind)))
	var got := {"code": ""}   # a lambda's locals are its own copies: shared through a dictionary
	if not await _until(func() -> bool:
			got.code = DeviceMoveRules.normalize_code(FileAccess.get_file_as_string(_code_file)) if FileAccess.file_exists(_code_file) else ""
			return got.code != "", 60.0):
		_done(false, "no code to type")
		return
	var code: String = got.code
	var wrong := "000000" if code != "000000" else "111111"
	var w: Dictionary = await service.move_approve(str(ask.id), wrong)
	if w.get("done", false) or int(w.get("tries_left", -1)) != 2:
		_done(false, "a wrong code was not refused: %s" % w)
		return
	print("NETMOVE old a wrong code: %s" % w.text)
	var t0 := Time.get_ticks_msec()
	var r: Dictionary = await service.move_approve(str(ask.id), code)
	if not r.get("done", false):
		_done(false, "the right code: %s" % r)
		return
	print("NETMOVE old the right code: %s" % r.text)
	if not await _until(func() -> bool: return not _news.is_empty(), 60.0):
		_done(false, "no word that the game moved")
		return
	print("NETMOVE old heard \"%s\" %d ms after the code" % [_news[0], Time.get_ticks_msec() - t0])
	_done(_news[0] == DeviceMoveRules.moved_text("computer") and service.status == OnlineService.ONLINE,
		"still signed in as %s (both play)" % service.account.get("username", "?"))


func _new() -> void:
	var taken: String = await service.claim_username(_me)
	if taken != OnlineRules.message("taken"):
		_done(false, "the name was not taken: %s" % taken)
		return
	print("NETMOVE new %s" % DeviceMoveRules.taken_text(_me))
	var t0 := Time.get_ticks_msec()
	var asked: Dictionary = await service.move_start(_me, "computer")
	if str(asked.get("text", "")) != "":
		_done(false, "move_start: %s" % asked.text)
		return
	print("NETMOVE new code=%s" % asked.code)
	var got := {"st": {}}   # a lambda's locals are its own copies: shared through a dictionary
	if not await _until(func() -> bool:
			got.st = await service.move_status(str(asked.id))
			return (got.st as Dictionary).get("state") == "approved", 90.0):
		_done(false, "never approved (last: %s)" % got.st)
		return
	var st: Dictionary = got.st
	print("NETMOVE new approved (heard it at once: %s)" % _nudged)
	var t1 := Time.get_ticks_msec()
	var err: String = await service.move_sign_in(str(st.username), str(st.key))
	if err != "":
		_done(false, "sign in with the one-time key: %s" % err)
		return
	print("NETMOVE new signed in with the one-time key in %d ms; the move took %d ms" % [Time.get_ticks_msec() - t1,
		Time.get_ticks_msec() - t0])
	var ok := service.claimed() and Profile.data.username == _me and Profile.data.universe_unlocked == UNIVERSE
	print("NETMOVE new %s" % DeviceMoveRules.welcome_text(Profile.data.username))
	_done(ok, "plays as %s, universe %d" % [Profile.data.username, Profile.data.universe_unlocked])


func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		if await cond.call():
			return true
		await get_tree().create_timer(1.0).timeout
	return false


func _done(ok: bool, why: String) -> void:
	print("NETMOVE %s %s %s" % [_role, "ok" if ok else "FAIL", why])
	get_tree().quit(0 if ok else 1)
