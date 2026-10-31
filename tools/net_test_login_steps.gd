extends Node
## The steps of tools/net_test_login.gd (owner #105: LOG IN with the name and the password; one device at a time).

const TIMEOUT := 170.0   # the "b" game's asking account is brand new: the server makes it wait about 30 s
const NAKAMA_BACKEND := "res://net/nakama_online_backend.gd"
const UNIVERSE := 3   # the "a" game's progress, which must reach the "b" one

var _role := ""
var _me := ""
var _password := ""
var service: OnlineService


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var server := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--role="):
			_role = a.trim_prefix("--role=")
		elif a.begins_with("--me="):
			_me = a.trim_prefix("--me=")
		elif a.begins_with("--password="):
			_password = a.trim_prefix("--password=")
		elif a.begins_with("--server="):
			server = a.trim_prefix("--server=")
	get_tree().create_timer(TIMEOUT).timeout.connect(func() -> void: _done(false, "timeout"))
	service = OnlineService.new()
	service.backend = (load(NAKAMA_BACKEND) as GDScript).new()
	service.server = OnlineConfig.parse_server(server)
	service.move_card = false
	service.logged_out_card = false
	Session.use_online_service(service)
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	service.prefs.save_to(service.prefs_path)
	var err: String = await service.sign_in()
	if err != "":
		_done(false, "sign in: %s" % err)
		return
	if _role == "a":
		await _a()
	else:
		await _b()


func _a() -> void:
	var err: String = await service.claim_username(_me)
	if err != "":
		_done(false, "claim %s: %s" % [_me, err])
		return
	var weak: String = await service.make_password("123456", "123456")
	if weak == "":
		_done(false, "a weak password was taken")
		return
	print("NETLOGIN a a weak password: %s" % weak)
	err = await service.make_password(_password, _password)
	if err != "":
		_done(false, "make the password: %s" % err)
		return
	var state: Dictionary = await service.password_state()
	if state.get("has_password") != true:
		_done(false, "the password is not on the server: %s" % state)
		return
	Profile.data.universe_unlocked = UNIVERSE
	Profile.save()
	await service.profile_sync.sync()
	var tried := {"text": ""}
	service.tried_note.connect(func(t: String) -> void: tried.text = t)
	print("NETLOGIN a ready as %s (a password made, universe %d backed up)" % [_me, UNIVERSE])
	var t0 := Time.get_ticks_msec()
	if not await _until(func() -> bool: return not service.backend.is_signed_in(), 150.0):
		_done(false, "this device's link never closed (still signed in)")
		return
	print("NETLOGIN a the link closed by itself %d ms after ready" % (Time.get_ticks_msec() - t0))
	print("NETLOGIN a the account heard of the wrong try: %s" % (tried.text if tried.text != "" else "(not while online)"))
	service._set_status(OnlineService.OFFLINE)
	var id_before := FileAccess.get_file_as_string(service.device_id_path)
	var again: String = await service.sign_in()
	if again != PasswordRules.LOGGED_OUT or not service.logged_out:
		_done(false, "its next sign-in: %s" % again)
		return
	print("NETLOGIN a its next sign-in: %s" % again)
	var same_id := FileAccess.get_file_as_string(service.device_id_path) == id_before
	_done(same_id and service.status == OnlineService.OFFLINE and not service.backend.is_signed_in(),
		"logged out, no new account made (the same device id, offline)")


func _b() -> void:
	service.prepare_log_in()   # LOG IN opened: this device's asking account, early
	var t0 := Time.get_ticks_msec()
	var wrong: Dictionary = await service.log_in_with_password(_me, _password + "x")
	if str(wrong.get("text", "")) != PasswordRules.WRONG:
		_done(false, "a wrong password: %s" % wrong)
		return
	print("NETLOGIN b a wrong password: %s (%d ms)" % [wrong.text, Time.get_ticks_msec() - t0])
	var t1 := Time.get_ticks_msec()
	var err: String = await service.log_in(_me, _password)
	if err != "":
		_done(false, "LOG IN: %s" % err)
		return
	print("NETLOGIN b logged in in %d ms" % (Time.get_ticks_msec() - t1))
	if not await _until(func() -> bool: return Profile.data.universe_unlocked == UNIVERSE, 30.0):
		print("NETLOGIN b the profile backup did not come (universe %d)" % Profile.data.universe_unlocked)
	var ok := service.claimed() and Profile.data.username == _me and Profile.data.universe_unlocked == UNIVERSE
	_done(ok, "plays as %s, universe %d" % [Profile.data.username, Profile.data.universe_unlocked])


func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		if await cond.call():
			return true
		await get_tree().create_timer(0.5).timeout
	return false


func _done(ok: bool, why: String) -> void:
	print("NETLOGIN %s %s %s" % [_role, "ok" if ok else "FAIL", why])
	get_tree().quit(0 if ok else 1)
