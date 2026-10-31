extends GutTest
## OnlineService's chat against the in-memory fake server (M4 Wave 2, Agent E; spec §5.13, §17.2,
## §17.4): friends' DMs and a match's team room over channels, the age rules (under-13: quick phrases
## and emotes only, nothing kept), history for 13+, mute and report from a message, and leaving.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."

var DIR := "user://test_online_chat_%d/" % OS.get_process_id()
var server: RefCounted
var now := int(Time.get_unix_time_from_datetime_string("2026-09-24T12:00:00"))


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	server.now_unix = now


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


## A signed-in player who went through the whole flow (a claimed name; consent for under-13).
func _player(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS) -> OnlineService:
	server.make_account(device, username, band,
		OnlineRules.CONSENT_VERIFIED if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = band
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.clock = func() -> int: return now
	add_child_autofree(s)
	s.prefs.safe_card_seen = now
	assert_eq(await s.sign_in(), "")
	return s


func _uid(s: OnlineService) -> String:
	return s.backend.user_id()


func _friends(a: OnlineService, b: OnlineService) -> void:
	server.befriend(_uid(a), _uid(b))
	await a.refresh_friends()
	await b.refresh_friends()


func _texts(s: OnlineService, channel_id: String) -> Array[String]:
	var out: Array[String] = []
	for m in s.messages(channel_id):
		out.append(OnlineChatRules.line(m))
	return out


# --- Friends' direct messages ---

func test_two_teen_friends_chat_in_a_dm_and_both_see_it() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	await _friends(pip, max)
	var a := await pip.open_dm(_uid(max))
	var b := await max.open_dm(_uid(pip))
	assert_eq(a.get("error", ""), "")
	assert_eq(a.channel_id, b.channel_id, "one channel for the two of them")
	watch_signals(max)
	assert_eq(await pip.send_text(a.channel_id, "want to build a castle?"), "")
	assert_eq(_texts(max, b.channel_id), ["Pip: want to build a castle?"] as Array[String])
	assert_eq(_texts(pip, a.channel_id), ["Pip: want to build a castle?"] as Array[String], "the sender sees it too")
	assert_true(pip.messages(a.channel_id)[0].mine)
	assert_signal_emitted(max, "chat_message")
	assert_eq(await max.send_phrase(b.channel_id, "Let's build!"), "")
	assert_eq(_texts(pip, a.channel_id).back(), "Max: Let's build!")


func test_only_friends_can_open_a_dm() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	var r := await pip.open_dm(_uid(max))
	assert_eq(r.error, "You can chat with your friends only.")
	assert_false(server.calls.has("join_chat"), "the client knows: not asked")
	server.befriend(_uid(pip), _uid(max))   # the list here is old: the server still decides
	server.edges[_uid(max)].erase(_uid(pip))
	pip.friends.append({"id": _uid(max), "username": "Max", "state": OnlineRules.FRIEND, "online": true})
	r = await pip.open_dm(_uid(max))
	assert_eq(r.error, "You can chat with your friends only.", "the server says no")


func test_a_teen_dm_keeps_its_history_for_30_days() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	await _friends(pip, max)
	var a := await pip.open_dm(_uid(max))
	await max.open_dm(_uid(pip))
	await pip.send_text(a.channel_id, "one")
	await pip.send_text(a.channel_id, "two")
	pip.close_chat(a.channel_id)
	max.close_chat(a.channel_id)
	await get_tree().process_frame
	var again := await max.open_dm(_uid(pip))
	assert_eq(_texts(max, again.channel_id), ["Pip: one", "Pip: two"] as Array[String], "oldest first")
	max.close_chat(again.channel_id)
	now += 31 * 86400
	again = await max.open_dm(_uid(pip))
	assert_eq(_texts(max, again.channel_id), [] as Array[String], "gone after 30 days")


func test_an_under_13_child_has_the_wheel_and_nothing_is_kept() -> void:
	var kid := await _player("dev-kid", "Kiddo", AgeBand.UNDER_13)
	var teen := await _player("dev-teen", "Max")
	await _friends(kid, teen)
	assert_false(kid.can_type(), "under-13: the quick-chat wheel only")
	assert_true(teen.can_type())
	var a := await kid.open_dm(_uid(teen))
	var b := await teen.open_dm(_uid(kid))
	var sends: int = server.chat_delivered.size()
	assert_eq(await kid.send_text(a.channel_id, "whats your address"), ChatRules.message("quick_chat_only"))
	assert_eq(server.chat_delivered.size(), sends, "never sent")
	assert_eq(await kid.send_phrase(a.channel_id, "Hi!"), "")
	assert_eq(await teen.send_text(b.channel_id, "hello kiddo how are you"), ChatRules.message("quick_chat_only"),
		"the channel has an under-13 player: the server takes quick phrases only")
	assert_eq(await teen.send_phrase(b.channel_id, "Good job!"), "")
	assert_eq(_texts(kid, a.channel_id), ["Kiddo: Hi!", "Max: Good job!"] as Array[String])
	assert_eq(await kid.send_emote(a.channel_id, &"wave"), "")
	assert_eq(_texts(teen, b.channel_id).back(), "Kiddo: *Wave*")
	assert_eq((server.channels[a.channel_id].history as Array).size(), 0, "nothing retained with an under-13 player")
	assert_eq(await kid.send_phrase(a.channel_id, "hello there"), ChatRules.message("quick_chat_only"), "only the wheel's phrases")


func test_a_grown_up_can_switch_chat_off() -> void:
	var kid := await _player("dev-kid", "Kiddo", AgeBand.UNDER_13)
	var teen := await _player("dev-teen", "Max")
	await _friends(kid, teen)
	server.accounts[_uid(kid)].chat = OnlineRules.CHAT_OFF
	await kid.refresh_account()
	assert_eq(kid.chat_level(), OnlineRules.CHAT_OFF)
	var r := await kid.open_dm(_uid(teen))
	assert_eq(r.error, "A grown-up turned chat off.")
	assert_false(server.calls.has("join_chat"))
	r = await teen.open_dm(_uid(kid))
	assert_eq(r.error, "Your friend can't chat right now.")


# --- The team room of an online match ---

func test_players_in_a_match_share_its_team_room() -> void:
	var host := await _player("dev-host", "Pip")
	var guest := await _player("dev-guest", "Max")
	var stranger := await _player("dev-other", "Zed")
	server.match_members[MATCH] = [_uid(host), _uid(guest)]
	var a := await host.open_team(MATCH)
	var b := await guest.open_team(MATCH)
	assert_eq(a.get("error", ""), "")
	assert_eq(a.channel_id, b.channel_id)
	assert_eq(host.team_channel(), a.channel_id)
	assert_eq((await stranger.open_team(MATCH)).error, "Team chat opens when you play together.")
	assert_eq((await host.open_team("not a match")).error, "Team chat opens when you play together.")
	assert_eq(await guest.send_phrase(b.channel_id, "Follow me!"), "")
	assert_eq(_texts(host, a.channel_id), ["Max: Follow me!"] as Array[String])
	assert_eq((server.channels[a.channel_id].history as Array).size(), 0, "team rooms keep nothing")


func test_leaving_a_channel_stops_its_messages() -> void:
	var host := await _player("dev-host", "Pip")
	var guest := await _player("dev-guest", "Max")
	server.match_members[MATCH] = [_uid(host), _uid(guest)]
	var a := await host.open_team(MATCH)
	await guest.open_team(MATCH)
	guest.close_chat(guest.team_channel())
	await get_tree().process_frame
	assert_eq(guest.team_channel(), "")
	await host.send_phrase(a.channel_id, "Hi!")
	assert_eq(guest.messages(a.channel_id), [] as Array[Dictionary])
	assert_eq(await guest.send_phrase(a.channel_id, "Hi!"), "This chat is closed now.")
	host.sign_out()
	assert_true(host.chats.is_empty(), "signing out closes every chat")


# --- Mute and report from a message ---

func test_mute_from_a_message_hides_that_player() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	var zed := await _player("dev-zed", "Zed")
	server.match_members[MATCH] = [_uid(pip), _uid(max), _uid(zed)]
	var room: String = (await pip.open_team(MATCH)).channel_id
	await max.open_team(MATCH)
	await zed.open_team(MATCH)
	await max.send_phrase(room, "Hi!")
	await zed.send_phrase(room, "Look!")
	var from_max: Dictionary = pip.messages(room)[0]
	pip.mute_sender(from_max)
	assert_eq(_texts(pip, room), ["Zed: Look!"] as Array[String], "what they said is gone too")
	assert_true(pip.is_muted(_uid(max)))
	await max.send_phrase(room, "Bye!")
	assert_eq(_texts(pip, room), ["Zed: Look!"] as Array[String])
	pip.unmute(_uid(max))
	await max.send_phrase(room, "Wow!")
	assert_eq(_texts(pip, room).back(), "Max: Wow!")


func test_report_from_a_message_tells_the_server_which_one_and_mutes() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	await _friends(pip, max)
	var a := await pip.open_dm(_uid(max))
	await max.open_dm(_uid(pip))
	await max.send_text(a.channel_id, "you are silly")
	var msg: Dictionary = pip.messages(a.channel_id)[0]
	assert_eq(await pip.report_message(msg, OnlineService.REPORT_MEAN), "")
	var report: Dictionary = server.reports.back()
	assert_eq(report.user_id, _uid(max))
	assert_eq(report.reason, "mean_words")
	assert_eq(report.message_id, msg.id)
	assert_eq(report.channel_id, a.channel_id)
	assert_true(pip.is_muted(_uid(max)))
	assert_eq(pip.messages(a.channel_id), [] as Array[Dictionary])
	assert_eq(await pip.report_message({}, OnlineService.REPORT_MEAN), OnlineChatRules.message("bad_message"),
		"a message without a sender can't be reported")


## Nakama's socket keeps the random name it gave until the next sign-in, so a name claimed in this
## session (B's gotcha) must not reach the screen: the friends list and the account know better.
func test_names_come_from_the_friends_list_and_the_account() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	await _friends(pip, max)
	var a := await pip.open_dm(_uid(max))
	for who: Array in [[_uid(max), "Rnd1234567"], [_uid(pip), "Rnd7654321"]]:
		pip.backend.chat_message.emit({"channel_id": a.channel_id, "message_id": "m-" + str(who[1]), "sender_id": who[0],
			"username": who[1], "content": "{\"text\":\"Hi!\"}", "create_time": "2026-09-24T12:00:00Z", "code": 0})
	assert_eq(_texts(pip, a.channel_id), ["Max: Hi!", "Pip: Hi!"] as Array[String])


func test_my_own_message_offers_no_mute_or_report() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	await _friends(pip, max)
	var a := await pip.open_dm(_uid(max))
	await pip.send_phrase(a.channel_id, "Hi!")
	var mine: Dictionary = pip.messages(a.channel_id)[0]
	assert_false(pip.can_report(mine))
	var reports: int = server.reports.size()
	assert_eq(await pip.report_message(mine, OnlineService.REPORT_MEAN), OnlineRules.message("self"))
	assert_eq(server.reports.size(), reports)


# --- Care ---

func test_sending_fast_is_slowed_down_kindly() -> void:
	var pip := await _player("dev-pip", "Pip")
	var max := await _player("dev-max", "Max")
	await _friends(pip, max)
	var a := await pip.open_dm(_uid(max))
	for i in ChatRules.RATE_COUNT:
		assert_eq(await pip.send_phrase(a.channel_id, "Hi!"), "")
	assert_eq(await pip.send_phrase(a.channel_id, "Hi!"), ChatRules.message("too_fast"))
	now += int(ChatRules.RATE_WINDOW) + 1
	assert_eq(await pip.send_phrase(a.channel_id, "Hi!"), "")


func test_nothing_opens_before_signing_in_or_without_consent() -> void:
	server.make_account("dev-kid", "Kiddo", AgeBand.UNDER_13)   # no consent yet
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-kid"
	s.profile = ProfileData.new()
	s.profile.username = "Kiddo"
	s.profile.age_band = AgeBand.UNDER_13
	s.prefs_path = DIR + "kid.json"
	s.clock = func() -> int: return now
	add_child_autofree(s)
	assert_eq((await s.open_team(MATCH)).error, OnlineChatRules.message("not_signed_in"))
	await s.sign_in()
	assert_eq(s.chat_level(), OnlineRules.CHAT_OFF)
	assert_eq((await s.open_team(MATCH)).error, OnlineRules.message("consent_needed"))
	assert_false(server.calls.has("join_chat"))
