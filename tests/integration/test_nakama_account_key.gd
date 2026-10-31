extends GutTest
## Owner #67 end to end over the real Nakama client: the child's phone plays, backs up and gets gold on the server;
## a grown-up makes a key; a new browser signs in with the name and the key, and the account feels loaded there
## (name, progress, look, gold). Owner #105 (module 0.2.20): one device at a time, so the phone is logged out at once:
## its connection closes, its writes no longer reach the account, and its next sign-in says so and makes no new account.
## Against EASYCRAFT_TEST_SERVER=<host:port> (default 127.0.0.1:7350), skipped
## when no server answers, pending when its module is older than 0.2.12 (the lead's development server runs the
## main checkout's build until the deploy step).

const FIRST_CODE := "sasa192974"   # only in tests: 1000 gold, once per account

var server := OnlineConfig.parse_server(OS.get_environment("EASYCRAFT_TEST_SERVER"))
var DIR := "user://test_nakama_account_key_%d/" % OS.get_process_id()
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


func after_all() -> void:
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
	add_child(s)
	_nodes.append(s)
	return s


func _profile(username: String) -> ProfileData:
	var p := ProfileData.new()
	p.username = username
	p.age_band = AgeBand.TEEN_PLUS
	p.updated_at = int(Time.get_unix_time_from_system()) - 60
	return p


## The module answers account_key (0.2.12 and later).
func _new_enough(s: OnlineService) -> bool:
	var r: Dictionary = await s.backend.call_rpc("healthcheck", {})
	var v := str(r.get("version", "0.0.0")).split(".")
	var ok := v.size() == 3 and (int(v[0]) > 0 or int(v[1]) > 2 or (int(v[1]) == 2 and int(v[2]) >= 12))
	if not ok:
		pending("the server runs module %s; owner #67 needs 0.2.12" % r.get("version", "?"))
	return ok


func test_a_new_browser_signs_in_with_the_key_and_the_account_feels_loaded() -> void:
	var name := "Ok"
	for i in 10:
		name += "abcdefghijklmnopqrstuvwxyz"[randi() % 26]
	var played := _profile(name)
	played.universe_unlocked = 3
	played.cosmetics.append("hat.party")
	played.avatar.hat = &"party"
	played.record_secret(&"treasure")
	played.survivor_gold = 0
	var phone := _service("phone", played)
	assert_eq(await phone.sign_in(), "")
	if not await _new_enough(phone):
		return
	assert_eq(await phone.claim_username(name), "")
	var code: Dictionary = await phone.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(code.status, CodeRules.ACCEPTED, "1000 gold into the account's wallet")
	await phone.profile_sync.upload()
	var made: Dictionary = await phone.make_account_key()
	assert_eq(made.text, "")
	var phone_id := phone.backend.user_id()
	var phone_closed: Array = []
	phone.status_changed.connect(func(st: StringName) -> void: phone_closed.append(st))
	var t0 := Time.get_ticks_msec()

	var browser := _service("browser", _profile("Hopper"))
	assert_eq(await browser.sign_in(), "")
	assert_eq(await browser.sign_in_with_key(name.to_lower(), str(made.key).to_lower().replace("-", " ")), "")
	print("MEASURE owner67 key sign-in to a loaded account: %d ms" % (Time.get_ticks_msec() - t0))
	var b := browser.profile
	assert_eq(browser.backend.user_id(), phone_id, "the same account")
	assert_true(browser.claimed())
	assert_eq(b.username, name)
	assert_eq(b.universe_unlocked, 3)
	assert_true(b.cosmetics.has("hat.party"))
	assert_eq(b.avatar.hat, &"party")
	assert_eq(int(b.secret_book.get("treasure", 0)), 1)
	assert_eq(b.survivor_gold, 1000, "the wallet's gold")

	# Owner #105: the phone is logged out by the browser's sign-in (one device at a time).
	await wait_seconds(1.0)
	assert_true(phone_closed.has(OnlineService.OFFLINE), "the phone's connection closed")
	b.record_secret(&"island")
	b.updated_at += 30
	assert_eq(await browser.profile_sync.upload(), "")
	phone.profile.universe_unlocked = 4
	phone.profile.updated_at += 60
	assert_ne(await phone.profile_sync.upload(), "", "the logged-out phone's write never reaches the account")
	var r: Dictionary = await browser.backend.read_storage(ProfileBackup.COLLECTION, ProfileBackup.KEY)
	var kept := ProfileData.from_json(str(r.get("value", "")))
	assert_eq(kept.universe_unlocked, 3, "not the logged-out phone's")
	assert_eq(int(kept.secret_book.get("island", 0)), 1, "the browser's")
	assert_false(JSON.parse_string(str(r.value)).has("survivor_gold"), "never the gold")
	phone.sign_out()
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT, "the phone says so, and never makes a new account")

	# SIGN OUT OTHER DEVICES (GROWN-UPS) still answers, and the browser plays on.
	assert_eq(await browser.sign_out_other_devices(), "")
	assert_eq(browser.status, OnlineService.ONLINE)

	assert_eq(await browser.delete_account((await browser.delete_account_start()).confirm), "")
