extends GutTest
## The profile backup and the economy calls over the real Nakama client (M4 Wave 2, agent F):
## NakamaOnlineBackend's read_storage / write_storage (a private "profiles" object), and a whole
## OnlineService sign-in that uploads the backup. Against the development server on 127.0.0.1:7350,
## or EASYCRAFT_TEST_SERVER=<host:port> (agent F's own server while the lead's runs an older module);
## skipped when none answers.

var server := OnlineConfig.parse_server(OS.get_environment("EASYCRAFT_TEST_SERVER"))
var DIR := "user://test_nakama_profile_backup_%d/" % OS.get_process_id()
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


func test_storage_reads_what_it_wrote_and_is_private() -> void:
	var b := NakamaOnlineBackend.new()
	add_child(b)
	_nodes.append(b)
	assert_eq((await b.sign_in(server, DeviceId.generate())).get("ok"), true)
	var none := await b.read_storage(ProfileBackup.COLLECTION, ProfileBackup.KEY)
	assert_eq(none, {"ok": true, "value": "", "version": ""}, "nothing yet")
	var p := ProfileData.new()
	p.username = "Pip"
	p.universe_unlocked = 4   # owner #67: gold is the wallet's, never in the backup
	var w := await b.write_storage(ProfileBackup.COLLECTION, ProfileBackup.KEY, ProfileBackup.to_backup(p))
	assert_eq(w.get("ok"), true, str(w))
	assert_ne(str(w.get("version", "")), "")
	var r := await b.read_storage(ProfileBackup.COLLECTION, ProfileBackup.KEY)
	assert_eq(r.get("ok"), true)
	assert_eq(ProfileData.from_json(str(r.value)).universe_unlocked, 4, "the same profile back (Nakama reorders the JSON)")
	var refused := await b.write_storage("parent", "consent", '{"status": "verified"}')
	assert_eq(refused.get("ok"), false, "a game writes only its own profile backup")


func test_a_claimed_account_backs_its_profile_up_at_sign_in() -> void:
	var s := OnlineService.new()
	s.backend = NakamaOnlineBackend.new()
	s.server = server
	s.device_id = DeviceId.generate()
	s.profile = ProfileData.new()
	s.profile.username = "Bk"
	for i in 8:
		s.profile.username += "abcdefghijklmnopqrstuvwxyz"[randi() % 26]
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.profile.universe_unlocked = 3
	s.profile.survivor_gold = 77
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "prefs.json"
	add_child(s)
	_nodes.append(s)
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.claim_username(s.profile.username), "")
	var r := await s.backend.read_storage(ProfileBackup.COLLECTION, ProfileBackup.KEY)
	assert_eq(ProfileData.from_json(str(r.get("value", ""))).universe_unlocked, 3, "the first backup at the claim")
	assert_eq(s.profile_sync.last_error, "")
	# What the backup and the wallet cost once signed in (printed for docs/devlog/parts/m4-f.md).
	var backup_ms: Array[float] = []
	var wallet_ms: Array[float] = []
	s.profile_sync.uploaded.disconnect(s.sync_wallet)   # timed one by one here
	await wait_seconds(0.5)   # the claim's own sync finishes first
	for i in 5:
		s.profile.universe_unlocked += 1
		s.profile.survivor_gold += 1
		var t0 := Time.get_ticks_usec()
		await s.profile_sync.upload()
		backup_ms.append((Time.get_ticks_usec() - t0) / 1000.0)
		t0 = Time.get_ticks_usec()
		await s.sync_wallet()
		wallet_ms.append((Time.get_ticks_usec() - t0) / 1000.0)
	backup_ms.sort()
	wallet_ms.sort()
	print("MEASURE profile upload median %.1f ms (max %.1f); wallet sync median %.1f ms (max %.1f)" %
		[backup_ms[2], backup_ms[4], wallet_ms[2], wallet_ms[4]])
	var fresh: Dictionary = await s.backend.call_rpc("get_account_state", {})
	if fresh.has("gold"):   # a server with the wallet in its answer (0.2.0 and later)
		assert_eq(int(fresh.gold), 82, "the server's ledger follows the phone (77 + 5)")
