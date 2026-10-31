extends GutTest
## NakamaOnlineBackend against the development server (M4 Wave 1, Agent C): signing in, the game's
## RPCs, and Nakama's own friends API with its notifications and online status, which work on any
## server. Skipped when no Nakama answers on 127.0.0.1:7350 (server/dev.sh up).

const NakamaProbe := preload("res://tests/integration/nakama_probe.gd")

const SERVER := {"scheme": "http", "host": OnlineConfig.DEFAULT_HOST, "port": OnlineConfig.DEFAULT_PORT}

var _backends: Array[NakamaOnlineBackend] = []


func should_skip_script():   # untyped like GutTest's own: "-> Variant" fails to parse in a full run
	var why: String = await NakamaProbe.why_not_up(self)
	return false if why == "" else why


func after_each() -> void:
	for b in _backends:
		if is_instance_valid(b):
			b.sign_out()
	await wait_seconds(0.3)   # NakamaLink.leave frees each link after its leave message
	for b in _backends:
		if is_instance_valid(b):
			b.free()
	_backends.clear()


func _signed_in(device: String = DeviceId.generate()) -> Array:   # [backend, sign-in answer]
	var b := NakamaOnlineBackend.new()
	add_child(b)
	_backends.append(b)
	var r := await b.sign_in(SERVER, device)
	assert_eq(r.get("ok"), true, "signed in: %s" % r)
	return [b, r]


## A 13+ player who claimed a name, signed in again (the server lets only such accounts, or an under-13
## with consent, use friends: M4 B; the session carries the claimed name after a new sign-in).
func _claimed() -> Array:   # [backend, the claimed name]
	var device := DeviceId.generate()
	var first: NakamaOnlineBackend = (await _signed_in(device))[0]
	var letters := "abcdefghijklmnopqrstuvwxyz"
	var name := "Tst"
	for i in 8:
		name += letters[randi() % letters.length()]
	var claim := await first.call_rpc("claim_username", {"username": name, "age_band": "13_plus"})
	assert_eq(claim.get("ok"), true, "claimed: %s" % claim)
	first.sign_out()
	return [(await _signed_in(device))[0], name]


func _state_of(b: NakamaOnlineBackend, other_id: String) -> int:
	var r := await b.list_friends()
	for f: Dictionary in r.get("friends", []):
		if f.id == other_id:
			return f.state
	return -1


func test_signs_in_and_calls_the_modules_rpcs() -> void:
	var got := await _signed_in()
	var b: NakamaOnlineBackend = got[0]
	assert_true(b.is_signed_in())
	assert_eq(got[1].user_id, b.user_id())
	assert_ne(str(got[1].username), "", "Nakama's random username until the claim")
	var health := await b.call_rpc("healthcheck")
	assert_eq(health.get("ok"), true, str(health))
	assert_eq(health.get("user_id"), b.user_id())
	var missing := await b.call_rpc("no_such_rpc_here")
	assert_eq(missing, {"ok": false, "error": "not_yet"}, "an RPC the server does not have yet")


func test_no_server_is_a_network_error() -> void:
	var b := NakamaOnlineBackend.new()
	add_child(b)
	_backends.append(b)
	var r := await b.sign_in({"scheme": "http", "host": "127.0.0.1", "port": 1}, DeviceId.generate())
	assert_eq(r.get("ok"), false)
	assert_eq(OnlineRules.message(str(r.get("error"))), OnlineRules.message("network"))
	assert_false(b.is_signed_in())
	assert_eq(await b.call_rpc("healthcheck"), OnlineBackend.NOT_SIGNED_IN)


func test_a_friend_request_notification_accept_presence_and_block() -> void:
	var a_got := await _claimed()
	var b_got := await _claimed()
	var a: NakamaOnlineBackend = a_got[0]
	var b: NakamaOnlineBackend = b_got[0]
	var b_heard: Array = []
	b.notified.connect(func(code: int, _content: String, sender: String) -> void: b_heard.append([code, sender]))
	assert_eq(await a.add_friend_by_name(str(b_got[1]).to_upper()), {"ok": true}, "by name, in any case")
	var give_up := Time.get_ticks_msec() + 5000
	while b_heard.is_empty() and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	assert_eq(b_heard, [[OnlineRules.FRIEND_REQUEST, a.user_id()]], "Nakama's own friend-request notification")
	assert_eq(await _state_of(a, b.user_id()), 1, "asked")
	assert_eq(await _state_of(b, a.user_id()), 2, "asked me")
	assert_eq(await b.add_friend_by_id(a.user_id()), {"ok": true})
	assert_eq(await _state_of(a, b.user_id()), 0, "friends")
	var friends := await a.list_friends()
	var seen_online := false
	for f: Dictionary in friends.friends:
		if f.id == b.user_id():
			seen_online = f.online
	assert_true(seen_online, "B's connection appears online to friends")
	var presence: Array = []
	a.presence_changed.connect(func(id: String, online: bool) -> void: presence.append([id, online]))
	await a.follow([b.user_id()] as Array[String])
	assert_true(presence.has([b.user_id(), true]), "following reports who is online now")
	var b_id := b.user_id()
	b.sign_out()
	give_up = Time.get_ticks_msec() + 5000
	while not presence.has([b_id, false]) and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)
	assert_true(presence.has([b_id, false]), "and when they leave")
	assert_eq(await a.block(b_id), {"ok": true})
	assert_eq(await _state_of(a, b_id), 3, "blocked")


func test_friend_errors_become_codes() -> void:
	var a: NakamaOnlineBackend = (await _claimed())[0]
	var r := await a.add_friend_by_name("nobody_" + str(randi() % 100000))
	assert_eq(r, {"ok": false, "error": "no_such_player"})
	var me := await a.add_friend_by_id(a.user_id())
	assert_eq(me.get("ok"), false)
	assert_eq(OnlineRules.message(str(me.get("error"))), OnlineRules.message("self"), str(me))


## M4 B: a fresh account that never claimed a name (or an under-13 without consent) can't use friends.
func test_an_account_without_a_claimed_name_cannot_add_friends() -> void:
	var fresh: NakamaOnlineBackend = (await _signed_in())[0]
	var other: Array = await _claimed()
	var r := await fresh.add_friend_by_name(str(other[1]))
	assert_eq(r, {"ok": false, "error": "not_allowed_online"})

