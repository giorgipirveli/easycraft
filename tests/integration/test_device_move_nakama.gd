extends GutTest
## Owner #99 end to end over the real Nakama client (module 0.2.20): the child's phone plays and backs up; a computer
## types the same name, asks to move the game there and shows its 6-digit code; the phone hears the ask over its realtime
## socket (notification 110) and a grown-up types the code there; the computer hears "approved", takes its one-time key
## and signs in to the account (name, progress, look, gold); the phone stays signed in and hears "moved". Against
## EASYCRAFT_TEST_SERVER=<host:port> (default 127.0.0.1:7350): skipped when no server answers, pending when its module is
## older than 0.2.20 (the lead's development server runs the main checkout's build until the deploy step).

const FIRST_CODE := "sasa192974"   # only in tests: 1000 gold, once per account

var server := OnlineConfig.parse_server(OS.get_environment("EASYCRAFT_TEST_SERVER"))
var DIR := "user://test_device_move_nakama_%d/" % OS.get_process_id()
var _nodes: Array[Node] = []


func should_skip_script():   # untyped like GutTest's own: "-> Variant" fails to parse in a full run
	var http := HTTPRequest.new()
	http.timeout = 5.0
	add_child(http)
	var err := http.request("http://%s:%d/healthcheck" % [server.host, server.port])
	var answer: Array = await http.request_completed if err == OK else [HTTPRequest.RESULT_CANT_CONNECT, 0]
	http.queue_free()
	if int(answer[0]) == HTTPRequest.RESULT_SUCCESS and int(answer[1]) == 200:
		return false
	return "no Nakama server at %s:%d (server/dev.sh up)" % [server.host, server.port]


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	for n in _nodes:
		if is_instance_valid(n) and n.has_method("sign_out"):
			n.call("sign_out")
	await wait_seconds(0.3)   # NakamaLink.leave frees each link after its leave message
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func before_all() -> void:
	DeviceMoveRules.enabled = true   # the move by code ships off (the quick-ship round); these tests are for its return


func after_all() -> void:
	DeviceMoveRules.enabled = false
	DirAccess.remove_absolute(DIR)


func _service(tag: String, profile: ProfileData) -> OnlineService:
	var s := OnlineService.new()
	s.backend = NakamaOnlineBackend.new()
	s.server = server
	s.device_id = DeviceId.generate()
	s.profile = profile
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + tag + "_prefs.json"
	s.wallet_path = DIR + tag + "_wallet.json"
	s.gift_book_path = DIR + tag + "_gifts.json"
	s.ghost_book_path = DIR + tag + "_ghosts.json"
	s.move_card = false
	add_child(s)
	_nodes.append(s)
	return s


func _profile(username: String) -> ProfileData:
	var p := ProfileData.new()
	p.username = username
	p.age_band = AgeBand.TEEN_PLUS
	p.updated_at = int(Time.get_unix_time_from_system()) - 60
	return p


func _new_enough(s: OnlineService) -> bool:
	var r: Dictionary = await s.backend.call_rpc("healthcheck", {})
	var v := str(r.get("version", "0.0.0")).split(".")
	var ok := v.size() == 3 and (int(v[0]) > 0 or int(v[1]) > 2 or (int(v[1]) == 2 and int(v[2]) >= 20))
	if not ok:
		pending("the server runs module %s; owner #99 needs 0.2.20" % r.get("version", "?"))
		return false
	var on: Dictionary = await s.backend.call_rpc("move_approve", {"action": "list"})
	if str(on.get("error", "")) == "not_available":
		pending("the move by code is off on this server (MoveRules.ENABLED, the quick-ship round)")
		return false
	return ok


func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		if cond.call():
			return true
		await wait_seconds(0.1)
	return false


func test_the_code_from_the_computer_typed_on_the_phone_moves_the_game() -> void:
	var name := "Mv"
	for i in 10:
		name += "abcdefghijklmnopqrstuvwxyz"[randi() % 26]
	var played := _profile(name)
	played.universe_unlocked = 3
	played.avatar.hat = &"party"
	played.cosmetics.append("hat.party")
	played.survivor_gold = 0
	var phone := _service("phone", played)
	assert_eq(await phone.sign_in(), "")
	if not await _new_enough(phone):
		return
	assert_eq(await phone.claim_username(name), "")
	assert_eq((await phone.redeem_code(FIRST_CODE, CodeTries.new(), 0)).status, CodeRules.ACCEPTED)
	await phone.profile_sync.upload()
	var news: Array[String] = []
	phone.move_news.connect(func(t: String) -> void: news.append(t))

	var computer := _service("computer", _profile(name))
	assert_eq(await computer.sign_in(), "")
	var t0 := Time.get_ticks_msec()
	assert_eq(await computer.claim_username(name), OnlineRules.message("taken"))
	var asked: Dictionary = await computer.move_start(name.to_lower(), "computer")
	assert_eq(asked.text, "")
	assert_true(await _until(func() -> bool: return phone.move_asks.size() == 1, 5.0), "the phone heard the ask")
	print("MEASURE owner99 ask reached the phone: %d ms" % (Time.get_ticks_msec() - t0))
	var nudged: Array[String] = []
	computer.move_nudged.connect(func(w: String) -> void: nudged.append(w))
	assert_true((await phone.move_approve(phone.move_asks[0].id, asked.code)).done)
	assert_true(await _until(func() -> bool: return not nudged.is_empty(), 5.0), "the computer heard: approved")
	var st: Dictionary = await computer.move_status(asked.id)
	assert_eq(st.state, "approved")
	var t1 := Time.get_ticks_msec()
	assert_eq(await computer.move_sign_in(st.username, st.key), "")
	print("MEASURE owner99 one-time key sign-in to a loaded account: %d ms; the whole move from the claim: %d ms" % [
		Time.get_ticks_msec() - t1, Time.get_ticks_msec() - t0])
	assert_eq(computer.backend.user_id(), phone.backend.user_id(), "the same account")
	assert_eq(computer.profile.universe_unlocked, 3)
	assert_eq(computer.profile.avatar.hat, &"party")
	assert_eq(computer.profile.survivor_gold, 1000, "the wallet's gold")
	assert_eq(phone.status, OnlineService.ONLINE, "the phone stays signed in")
	assert_true(await _until(func() -> bool: return not news.is_empty(), 5.0))
	assert_eq(news[0], "Your game is on a computer now too.")
