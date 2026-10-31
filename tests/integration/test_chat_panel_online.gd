extends GutTest
## The in-game chat with the quick-chat wheel and online team chat (M4 Wave 2, Agent E; spec §5.13,
## §17.4): under-13 players chat with the wheel only; in an online match the chat panel talks in the
## match's team room (the server's rules) instead of the host's relay chat; a grown-up's "chat off"
## holds; a message from someone else can be muted or reported right from the chat.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."

var DIR := "user://test_chat_panel_online_%d/" % OS.get_process_id()
var panel: ChatPanel
var server: RefCounted
var commands: Array[String] = []
var now := int(Time.get_unix_time_from_datetime_string("2026-09-24T12:00:00"))


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	server.now_unix = now
	commands.clear()
	panel = ChatPanel.new()
	add_child_autofree(panel)
	panel.command_entered.connect(func(t: String) -> void: commands.append(t))


func after_each() -> void:
	Session.chat_reset()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


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


## This panel's player and a friend, both in MATCH, with the panel on the team room.
func _team(band: StringName = AgeBand.TEEN_PLUS) -> Array:   # [mine, friend's service]
	var mine := await _player("dev-me", "Hopper", band)
	var friend := await _player("dev-friend", "Pip")
	server.match_members[MATCH] = [mine.backend.user_id(), friend.backend.user_id()]
	panel.setup("Hopper", band)
	await panel.use_team_chat(mine, MATCH)
	assert_true(panel.team_chat_on())
	await friend.open_team(MATCH)
	return [mine, friend]


## Where the newest history line is on the screen, once the history has been laid out.
func _last_line() -> Vector2:
	await get_tree().process_frame
	return panel.line_position(panel._lines.size() - 1)


func _shown() -> Array[String]:
	var out: Array[String] = []
	for l: Dictionary in panel._lines:
		out.append(l.text)
	return out


# --- The quick-chat wheel ---

func test_under_13_chat_opens_the_wheel_and_never_a_keyboard() -> void:
	panel.setup("Kiddo", AgeBand.UNDER_13)
	panel.open()
	assert_true(panel.wheel.visible, "the wheel")
	assert_false(panel._bar.visible, "no text field")
	assert_true(panel.is_open())
	panel.wheel.chosen.emit("Hi!")
	assert_false(panel.is_open())
	assert_true(_shown().has("Kiddo: Hi!"), "sent through the host's chat (solo here)")


func test_under_13_reaches_the_commands_from_the_wheel() -> void:
	panel.setup("Kiddo", AgeBand.UNDER_13)
	panel.open()
	panel.wheel.commands_requested.emit()
	assert_true(panel._bar.visible)
	assert_eq(panel._field.text, "/")
	# owner feedback #40: every command this child may use in this mode
	assert_eq(panel._choices.get_child_count(),
		ChatCommands.suggestions("/", [], {"mode": Game.mode, "enabled": Session.commands_enabled}).size())


func test_13_plus_has_the_keyboard_and_the_wheel_one_tap_away() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	panel.open()
	assert_true(panel._bar.visible)
	assert_false(panel.wheel.visible)
	panel.quick_button.pressed.emit()
	assert_true(panel.wheel.visible)
	assert_false(panel._bar.visible)
	panel.close()
	assert_false(panel.is_open())


func test_the_wheel_and_the_menu_block_building_behind_them() -> void:
	panel.setup("Kiddo", AgeBand.UNDER_13)
	var b := panel.blockers()
	assert_true(b.has(panel.wheel))
	assert_true(b.has(panel.line_menu))
	for l in panel._labels:
		assert_false(b.has(l), "the history never blocks building; a tap on a friend's line is taken by the chat")


## The chat hears touches before the look area (a later sibling): a tap on a friend's line opens the
## menu and is used up, so it never looks around or builds; a tap on a game line goes on to the world.
func test_a_touch_on_a_friends_line_opens_the_menu_and_is_used_up() -> void:
	var got := await _team()
	var friend: OnlineService = got[1]
	await friend.send_phrase(friend.team_channel(), "Look!")
	var at := await _last_line()
	for pressed in [true, false]:
		var t := InputEventScreenTouch.new()
		t.position = at
		t.pressed = pressed
		get_viewport().push_input(t, true)
	assert_true(panel.line_menu.visible, "MUTE / REPORT")
	panel.close()
	panel.add_line("Pip joined the game.")
	var game_line := await _last_line()
	var down := InputEventScreenTouch.new()
	down.position = game_line
	down.pressed = true
	panel._touch_on_lines(down)
	assert_false(panel.line_menu.visible)
	assert_eq(panel._touch_line, -1, "a game line is left to the world")


# --- Team chat in an online match ---

func test_in_an_online_match_the_chat_talks_in_the_team_room() -> void:
	var got := await _team()
	var friend: OnlineService = got[1]
	var relayed := Session.chat_received.get_connections().size()
	panel.open()
	await panel._submit("anyone want to build?")
	assert_eq(server.chat_delivered.back().content, {"text": "anyone want to build?"}, "through the team room")
	assert_eq(_shown().back(), "Hopper: anyone want to build?", "the server's echo")
	await friend.send_phrase(friend.team_channel(), "Let's build!")
	assert_eq(_shown().back(), "Pip: Let's build!")
	Session.chat_received.emit("Pip", "an old relay line", &"chat")
	assert_false(_shown().has("Pip: an old relay line"), "players talk in the room only")
	Session.chat_received.emit("", "Pip joined the game.", &"system")
	assert_eq(_shown().back(), "Pip joined the game.", "the game's own lines still come")
	assert_eq(Session.chat_received.get_connections().size(), relayed)


func test_the_wheel_sends_to_the_team_room_too() -> void:
	await _team()
	panel.open_wheel()
	panel.wheel.chosen.emit("Follow me!")
	await get_tree().process_frame
	assert_eq(server.chat_delivered.back().content, {"text": "Follow me!"})


func test_an_under_13_player_in_an_online_match_has_the_wheel_only() -> void:
	var got := await _team(AgeBand.UNDER_13)
	panel.open()
	assert_true(panel.wheel.visible)
	panel.wheel.commands_requested.emit()
	await panel._submit("hello everyone")
	assert_eq(_shown().back(), ChatRules.message("quick_chat_only"))
	assert_eq(server.chat_delivered.size(), 0, "nothing sent")
	assert_true(got[0] is OnlineService)


func test_a_grown_ups_chat_off_holds_in_an_online_match() -> void:
	var mine := await _player("dev-me", "Hopper", AgeBand.UNDER_13)
	server.accounts[mine.backend.user_id()].chat = OnlineRules.CHAT_OFF
	await mine.refresh_account()
	panel.setup("Hopper", AgeBand.UNDER_13)
	await panel.use_team_chat(mine, MATCH)
	assert_false(panel.team_chat_on())
	panel.wheel.chosen.emit("Hi!")
	assert_eq(_shown().back(), "A grown-up turned chat off.")
	assert_false(_shown().has("Hopper: Hi!"), "not even through the host")
	Session.chat_received.emit("Pip", "Hi!", &"chat")
	assert_false(_shown().has("Pip: Hi!"), "and nothing comes in")
	panel.open("/")
	await panel._submit("/day")
	assert_eq(commands, ["/day"] as Array[String], "commands still work")


func test_without_a_signed_in_service_the_host_chat_stays() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	assert_false(panel.team_chat_on())
	panel.open()
	await panel._submit("hello")
	assert_true(_shown().has("Hopper: hello"), "LAN and developer matches keep the host's chat")


## M4 Task 10 review (handed over by the M3 review): a message, a wheel phrase or a report still on its way when
## the world closes (the HUD and its chat are freed) resumed the chat's function on a freed panel: "Resumed
## function after await, but class instance is gone". The answer now goes nowhere, quietly; the message and the
## report still reach the server.
func test_a_message_or_report_on_its_way_when_the_world_closes_ends_quietly() -> void:
	var got := await _team()
	var mine: OnlineService = got[0]
	var friend: OnlineService = got[1]
	await friend.send_phrase(friend.team_channel(), "Bye!")
	mine.backend.latency_frames = 3   # the network is slow now
	panel._menu_msg = panel._lines.back().msg
	panel._report_from_menu("mean_words")   # not awaited: all three are on their way ...
	panel.open()
	panel._submit("anyone want to build?")
	panel._send_phrase("Follow me!")
	panel.free()   # ... when the world closes
	for i in 12:
		await get_tree().process_frame
	assert_eq(server.reports.size(), 1, "the report still reached the server")
	assert_eq(server.reports.back().reason, "mean_words")


func test_leaving_the_game_leaves_the_team_room() -> void:
	var got := await _team()
	var mine: OnlineService = got[0]
	var room := mine.team_channel()
	assert_ne(room, "")
	remove_child(panel)
	assert_eq(mine.team_channel(), "")
	add_child(panel)


# --- Mute and report from a message ---

func test_a_friends_line_opens_mute_and_report() -> void:
	var got := await _team()
	var mine: OnlineService = got[0]
	var friend: OnlineService = got[1]
	await friend.send_phrase(friend.team_channel(), "Look!")
	var at := await _last_line()
	assert_true(at.is_finite(), "the line is on screen")
	panel.tap_line(at)
	assert_true(panel.line_menu.visible)
	assert_string_contains(panel.menu_text(), "Pip: Look!")
	panel.menu_button("Mute").pressed.emit()
	assert_false(panel.line_menu.visible)
	assert_true(mine.is_muted(friend.backend.user_id()))
	assert_false(_shown().has("Pip: Look!"), "the line goes")
	await friend.send_phrase(friend.team_channel(), "Hi!")
	assert_false(_shown().has("Pip: Hi!"), "no more from them")


func test_report_from_a_line_names_the_message() -> void:
	var got := await _team()
	var friend: OnlineService = got[1]
	await friend.send_phrase(friend.team_channel(), "Bye!")
	var msg_id := str(panel._lines.back().msg.id)
	assert_ne(msg_id, "")
	panel.tap_line(await _last_line())
	panel.menu_button("Report").pressed.emit()
	assert_true(panel.line_menu.visible, "the reasons")
	panel.menu_button("Reason_mean_words").pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(server.reports.back().message_id, msg_id)
	assert_eq(server.reports.back().reason, "mean_words")
	assert_false(panel.line_menu.visible)
	assert_eq(_shown().back(), "Thank you for telling us. A grown-up will look at it.")


func test_my_own_lines_and_the_games_lines_open_nothing() -> void:
	await _team()
	panel.open()
	await panel._submit("hello")
	panel.close()
	panel.tap_line(await _last_line())
	assert_false(panel.line_menu.visible, "my own line")
	panel.add_line("Pip joined the game.")
	panel.tap_line(await _last_line())
	assert_false(panel.line_menu.visible, "a game line")


func test_the_wheel_passes_a_tap_on_a_line_to_the_menu() -> void:
	var got := await _team(AgeBand.UNDER_13)
	var friend: OnlineService = got[1]
	await friend.send_phrase(friend.team_channel(), "Help!")
	panel.open()
	assert_true(panel.wheel.visible)
	panel.wheel.tapped_outside.emit(await _last_line())
	assert_true(panel.line_menu.visible, "an under-13 child can mute and report too")


# --- The M4 Task 10 review's finding B: online, no relay-chat stand-in for the team room ---
# The host's relay chat trusted each guest's own name and band. Online, when the team room can't open, the chat says
# it is resting (typed words wait for the room) and the quick phrases still go through the host, which passes quick
# phrases only online; the room is tried again when the chat opens.

func test_when_the_team_room_cant_open_online_chat_rests_and_quick_phrases_still_work() -> void:
	var mine := await _player("dev-me", "Hopper")   # 13+ with text chat, but not in MATCH as the server sees it
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	await panel.use_team_chat(mine, MATCH)
	assert_false(panel.team_chat_on())
	assert_eq(_shown().back(), OnlineChatRules.message("chat_resting"), "a kind line says so")
	panel.open()
	assert_true(panel.wheel.visible, "the wheel, even for 13+: typed words wait for the room")
	panel.open("/")
	await panel._submit("anyone want to build?")
	assert_eq(_shown().back(), OnlineChatRules.message("chat_resting"))
	assert_false(_shown().has("Hopper: anyone want to build?"), "free text never goes through the host online")
	panel._send_phrase("Hi!")
	assert_eq(_shown().back(), "Hopper: Hi!", "a quick phrase goes through the host")
	assert_eq(server.chat_delivered.size(), 0)


func test_online_a_relay_line_that_is_not_a_quick_phrase_never_shows() -> void:
	var mine := await _player("dev-me", "Hopper")
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	await panel.use_team_chat(mine, MATCH)
	Session.chat_received.emit("Pip", "my number is five five five", &"chat")
	assert_false(_shown().has("Pip: my number is five five five"), "a modified host's free text stays out")
	Session.chat_received.emit("Pip", "Hi!", &"chat")
	assert_eq(_shown().back(), "Pip: Hi!")


func test_when_signing_in_fails_online_chat_rests_too() -> void:
	server.make_account("dev-me", "Hopper")
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-me"
	s.profile = ProfileData.new()
	s.profile.username = "Hopper"
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "dev-me.json"
	s.clock = func() -> int: return now
	add_child_autofree(s)
	server.down = true
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	await panel.use_team_chat(s, MATCH)
	assert_false(panel.team_chat_on())
	panel.open("/")
	await panel._submit("hello")
	assert_eq(_shown().back(), OnlineChatRules.message("chat_resting"))
	assert_false(_shown().has("Hopper: hello"))


func test_the_team_room_is_tried_again_when_the_chat_opens() -> void:
	var mine := await _player("dev-me", "Hopper")
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	await panel.use_team_chat(mine, MATCH)
	assert_false(panel.team_chat_on())
	server.match_members[MATCH] = [mine.backend.user_id()]   # now the server has the player in the match
	panel.open()
	for i in 4:
		await get_tree().process_frame
	assert_true(panel.team_chat_on(), "the room opened on the next try")
	panel.close()
	panel.open()
	await panel._submit("hello team")
	assert_eq(server.chat_delivered.back().content, {"text": "hello team"}, "and typed words go there")
