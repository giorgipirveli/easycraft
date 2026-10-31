extends Node
## The steps of tools/net_test_friends.gd.

const TIMEOUT := 120.0
const NAKAMA_BACKEND := "res://net/nakama_online_backend.gd"

var _role := ""
var _me := ""
var _other := ""
var service: OnlineService


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var server := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--role="):
			_role = a.trim_prefix("--role=")
		elif a.begins_with("--me="):
			_me = a.trim_prefix("--me=")
		elif a.begins_with("--other="):
			_other = a.trim_prefix("--other=")
		elif a.begins_with("--server="):
			server = a.trim_prefix("--server=")
	get_tree().create_timer(TIMEOUT).timeout.connect(func() -> void: _done(false, "timeout"))
	service = OnlineService.new()
	service.backend = (load(NAKAMA_BACKEND) as GDScript).new()
	service.server = OnlineConfig.parse_server(server)
	Session.use_online_service(service)
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	var err: String = await service.sign_in()
	if err != "":
		_done(false, "sign in: %s" % err)
		return
	err = await service.claim_username(_me)
	if err != "":
		_done(false, "claim %s: %s" % [_me, err])
		return
	print("NETFRIENDS %s signed in as %s" % [_role, _me])
	if _role == "host":
		var asked := await _until(func() -> bool: return await service.add_friend(_other) == "", 60.0)
		if not asked:
			_done(false, "could not ask %s" % _other)
			return
		print("NETFRIENDS host asked %s" % _other)
	else:
		var said_yes := await _until(func() -> bool:
			await service.refresh_friends()
			for f: Dictionary in service.friends:
				if f.username == _other and f.state == OnlineRules.RECEIVED:
					return await service.accept(f.id) == ""
			return false, 60.0)
		if not said_yes:
			_done(false, "no request from %s" % _other)
			return
	var friends := await _until(func() -> bool:
		await service.refresh_friends()
		for f: Dictionary in service.friends:
			if f.username == _other and f.state == OnlineRules.FRIEND:
				return true
		return false, 60.0)
	_done(friends, "friends with %s" % _other if friends else "not friends with %s" % _other)


func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		if await cond.call():
			return true
		await get_tree().create_timer(1.0).timeout
	return false


func _done(ok: bool, why: String) -> void:
	print("NETFRIENDS %s %s %s" % [_role, "ok" if ok else "FAIL", why])
	get_tree().quit(0 if ok else 1)
