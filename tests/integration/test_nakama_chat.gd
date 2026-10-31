extends GutTest
## NakamaOnlineBackend's chat channels against the development server (M4 Wave 2, Agent E; spec
## §17.4) with Agent B's module: a DM between two 13+ friends (sent, heard, kept), a DM with a
## stranger refused, the filter at the text level, and a match's team room only for its players.
## Skipped when no Nakama answers on 127.0.0.1:7350 (server/dev.sh up).

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


func _signed_in(device: String) -> NakamaOnlineBackend:
	var b := NakamaOnlineBackend.new()
	add_child(b)
	_backends.append(b)
	var r := await b.sign_in(SERVER, device)
	assert_eq(r.get("ok"), true, "signed in: %s" % r)
	return b


## A 13+ player who claimed a name, signed in again (the session then carries the claimed name).
func _teen() -> NakamaOnlineBackend:
	var device := DeviceId.generate()
	var first := await _signed_in(device)
	var letters := "bdfgkmnprtvxz"   # no vowels next to digits: never a blocked word or a phone number
	var name := "Chat"
	for i in 5:
		name += letters[randi() % letters.length()] + str(randi() % 10)
	var claim := await first.call_rpc("claim_username", {"username": name, "age_band": "13_plus"})
	assert_eq(claim.get("ok"), true, "claimed: %s" % claim)
	first.sign_out()
	return await _signed_in(device)


func _befriend(a: NakamaOnlineBackend, b: NakamaOnlineBackend) -> void:
	assert_eq(await a.add_friend_by_id(b.user_id()), {"ok": true})
	assert_eq(await b.add_friend_by_id(a.user_id()), {"ok": true})


func _heard(b: NakamaOnlineBackend) -> Array:
	var got: Array = []
	b.chat_message.connect(func(m: Dictionary) -> void: got.append(m))
	return got


func _wait_for(list: Array, count: int) -> void:
	var give_up := Time.get_ticks_msec() + 5000
	while list.size() < count and Time.get_ticks_msec() < give_up:
		await wait_process_frames(1)


func test_two_teen_friends_chat_in_a_dm_and_it_is_kept() -> void:
	var a := await _teen()
	var b := await _teen()
	await _befriend(a, b)
	var ja := await a.join_chat(b.user_id(), OnlineChatRules.TYPE_DM, true)
	var jb := await b.join_chat(a.user_id(), OnlineChatRules.TYPE_DM, true)
	assert_eq(ja.get("ok"), true, str(ja))
	assert_eq(ja.get("channel_id"), jb.get("channel_id"), "one channel for the two of them")
	var heard := _heard(b)
	var sent := await a.send_chat(ja.channel_id, {"text": "  want to build a castle?  "})
	assert_eq(sent.get("ok"), true, str(sent))
	assert_ne(str(sent.get("message_id", "")), "")
	await _wait_for(heard, 1)
	assert_eq(heard.size(), 1, "B heard it")
	var msg := OnlineChatRules.parse(heard[0], b.user_id(), AgeBand.TEEN_PLUS)
	assert_eq(msg.text, "want to build a castle?", "the server's cleaned text")
	assert_eq(msg.from_id, a.user_id())
	assert_true(msg.from.begins_with("Chat"), "the claimed name")
	assert_gt(int(msg.time), 0, "a readable time")
	var history := await b.chat_history(jb.channel_id, 10)
	assert_eq(history.get("ok"), true, str(history))
	assert_eq((history.messages as Array).size(), 1, "kept for two 13+ players")
	var emote := await a.send_chat(ja.channel_id, {"emote": "wave"})
	assert_eq(emote.get("ok"), true, "an emote: %s" % emote)
	await _wait_for(heard, 2)
	assert_eq(OnlineChatRules.parse(heard.back(), b.user_id(), AgeBand.TEEN_PLUS).get("emote"), &"wave")
	assert_eq((await a.leave_chat(ja.channel_id)).get("ok"), true)


func test_a_dm_with_a_stranger_is_refused() -> void:
	var a := await _teen()
	var b := await _teen()
	var r := await a.join_chat(b.user_id(), OnlineChatRules.TYPE_DM, true)
	assert_eq(r, {"ok": false, "error": "not_friends"}, "the server's code, for OnlineChatRules.message")


func test_the_filter_at_the_text_level() -> void:
	var a := await _teen()
	var b := await _teen()
	await _befriend(a, b)
	var ja := await a.join_chat(b.user_id(), OnlineChatRules.TYPE_DM, true)
	assert_eq(await a.send_chat(ja.channel_id, {"text": "call me 555 123 4567"}), {"ok": false, "error": "personal_info"})
	assert_eq(await a.send_chat(ja.channel_id, {"text": "hi", "emote": "wave"}), {"ok": false, "error": "bad_message"})


func test_a_matchs_team_room_is_for_its_players_only() -> void:
	var host := await _teen()
	var other := await _teen()
	var link: NakamaLink = host._link
	assert_eq(await link.create_match(), "", "a relayed match")
	var match_id := link.match_id()
	var room := OnlineChatRules.team_room(match_id)
	assert_ne(room, "", match_id)
	var j := await host.join_chat(room, OnlineChatRules.TYPE_ROOM, false)
	assert_eq(j.get("ok"), true, "the host is in its match: %s" % j)
	var heard := _heard(host)
	assert_eq((await host.send_chat(j.channel_id, {"text": "Follow me!"})).get("ok"), true)
	await _wait_for(heard, 1)
	assert_eq(heard.size(), 1, "the sender hears its own message")
	var refused := await other.join_chat(room, OnlineChatRules.TYPE_ROOM, false)
	assert_eq(refused, {"ok": false, "error": "room_not_allowed"})
