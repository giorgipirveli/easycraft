extends GutTest
## Friends' direct messages from the friends list (M4 Wave 2, Agent E; spec §5.13, §17.4): TALK on a
## friend's row opens the chat page; 13+ type or use the wheel; under-13 have the wheel and emotes
## only; a friend's message opens MUTE and REPORT; history for 13+; the page fits the menu's panel.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)   # the main menu's panel (test_online_screens.gd)

var DIR := "user://test_online_dm_%d/" % OS.get_process_id()
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


func _pair(band: StringName = AgeBand.TEEN_PLUS) -> Array:   # [mine, friend]
	var mine := await _player("dev-me", "Hopper", band)
	var friend := await _player("dev-pip", "Pip")
	server.befriend(mine.backend.user_id(), friend.backend.user_id())
	await mine.refresh_friends()
	await friend.refresh_friends()
	return [mine, friend]


## PLAY ONLINE's FRIENDS page in the main menu's panel, then TALK on Pip's row.
func _chat_page(s: OnlineService) -> DmPanel:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var screen := PlayOnlineScreen.new()
	screen.service = s
	panel.add_child(screen)
	await wait_process_frames(3)
	_button(screen, "FRIENDS").pressed.emit()
	await wait_process_frames(3)
	var talk := _button(screen, "TALK")
	assert_not_null(talk, "TALK on a friend's row")
	talk.pressed.emit()
	await wait_process_frames(3)
	var pages := screen.find_children("*", "DmPanel", true, false)
	assert_eq(pages.size(), 1, "the chat page")
	return pages[0] as DmPanel if not pages.is_empty() else null


func _buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append(b)
	return out


func _button(root: Node, prefix: String) -> Button:
	for b in _buttons(root):
		if b.text.begins_with(prefix):
			return b
	return null


func _screen_of(page: Control) -> Control:
	var n: Node = page
	while n and not (n is PlayOnlineScreen):
		n = n.get_parent()
	return n as Control


func _check_fits(page: DmPanel, what: String) -> void:
	await wait_process_frames(2)
	var screen := _screen_of(page)
	var size := screen.get_combined_minimum_size()
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in _buttons(page):
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
		assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


func test_a_teen_types_to_a_friend_from_the_friends_list() -> void:
	var got := await _pair()
	var friend: OnlineService = got[1]
	var page := await _chat_page(got[0])
	assert_ne(page.channel_id, "")
	assert_not_null(page.field, "13+: a keyboard")
	await _check_fits(page, "the chat page")
	page.field.text = "want to build a castle?"
	_button(page, "SEND").pressed.emit()
	await wait_process_frames(2)
	assert_eq(page.lines(), ["Hopper: want to build a castle?"] as Array[String])
	assert_eq(page.field.text, "")
	var theirs := await friend.open_dm(got[0].backend.user_id())
	await friend.send_phrase(theirs.channel_id, "Let's build!")
	await wait_process_frames(1)
	assert_eq(page.lines().back(), "Pip: Let's build!")
	await _check_fits(page, "the chat page with messages")


func test_a_teen_can_use_the_wheel_too() -> void:
	var got := await _pair()
	var page := await _chat_page(got[0])
	_button(page, "QUICK").pressed.emit()
	assert_true(page.wheel.visible)
	page.wheel.chosen.emit("Good job!")
	await wait_process_frames(2)
	assert_eq(page.lines(), ["Hopper: Good job!"] as Array[String])


func test_an_under_13_child_has_the_wheel_and_emotes_only() -> void:
	var got := await _pair(AgeBand.UNDER_13)
	var page := await _chat_page(got[0])
	assert_null(page.field, "no keyboard under 13")
	assert_eq(page.find_children("*", "LineEdit", true, false).size(), 0)
	await _check_fits(page, "the under-13 chat page")
	_button(page, "QUICK CHAT").pressed.emit()
	assert_true(page.wheel.visible)
	page.wheel.chosen.emit("Hi!")
	await wait_process_frames(2)
	_button(page, "EMOTES").pressed.emit()
	assert_true(page.emotes.visible)
	page.emotes.chosen.emit(&"wave")
	await wait_process_frames(2)
	assert_eq(page.lines(), ["Hopper: Hi!", "Hopper: *Wave*"] as Array[String])


func test_a_friends_message_opens_mute_and_report() -> void:
	var got := await _pair()
	var mine: OnlineService = got[0]
	var friend: OnlineService = got[1]
	var page := await _chat_page(mine)
	var theirs := await friend.open_dm(mine.backend.user_id())
	await friend.send_text(theirs.channel_id, "you are silly")
	await wait_process_frames(1)
	var row := _button(page, "Pip: you are silly")
	assert_not_null(row, "the message is a button")
	row.pressed.emit()
	await wait_process_frames(1)
	await _check_fits(page, "a message's MUTE / REPORT")
	_button(page, "REPORT").pressed.emit()
	await wait_process_frames(1)
	_button(page, "MEAN WORDS").pressed.emit()
	await wait_process_frames(3)
	assert_eq(server.reports.back().message_id, "msg-1")
	assert_eq(page.message.text, "Thank you for telling us. A grown-up will look at it.")
	assert_true(mine.is_muted(friend.backend.user_id()))
	assert_eq(page.lines(), [] as Array[String], "their messages go")


func test_mute_from_a_message_and_my_own_messages_open_nothing() -> void:
	var got := await _pair()
	var mine: OnlineService = got[0]
	var friend: OnlineService = got[1]
	var page := await _chat_page(mine)
	await mine.send_phrase(page.channel_id, "Hi!")
	await wait_process_frames(1)
	var own := _button(page, "Hopper: Hi!")
	assert_not_null(own)
	assert_true(own.disabled, "my own message has no MUTE / REPORT")
	var theirs := await friend.open_dm(mine.backend.user_id())
	await friend.send_phrase(theirs.channel_id, "Wow!")
	await wait_process_frames(1)
	_button(page, "Pip: Wow!").pressed.emit()
	_button(page, "MUTE").pressed.emit()
	await wait_process_frames(1)
	assert_true(mine.is_muted(friend.backend.user_id()))
	assert_eq(page.lines(), ["Hopper: Hi!"] as Array[String])


func test_a_teen_dm_brings_back_its_history() -> void:
	var got := await _pair()
	var mine: OnlineService = got[0]
	var friend: OnlineService = got[1]
	var theirs := await friend.open_dm(mine.backend.user_id())
	await mine.open_dm(friend.backend.user_id())
	await friend.send_text(theirs.channel_id, "see you tomorrow")
	mine.close_chat(theirs.channel_id)
	var page := await _chat_page(mine)
	assert_eq(page.lines(), ["Pip: see you tomorrow"] as Array[String])


func test_back_returns_to_the_list_and_leaves_the_chat() -> void:
	var got := await _pair()
	var mine: OnlineService = got[0]
	var page := await _chat_page(mine)
	var screen := _screen_of(page)
	var channel := page.channel_id
	_button(screen, "BACK").pressed.emit()
	await wait_process_frames(3)
	assert_false(mine.chats.has(channel), "the chat is closed")
	assert_not_null(_button(screen, "TALK"), "the list again")


func test_no_talk_when_a_grown_up_switched_chat_off() -> void:
	var got := await _pair(AgeBand.UNDER_13)
	var mine: OnlineService = got[0]
	server.accounts[mine.backend.user_id()].chat = OnlineRules.CHAT_OFF
	await mine.refresh_account()
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var screen := PlayOnlineScreen.new()
	screen.service = mine
	panel.add_child(screen)
	await wait_process_frames(3)
	_button(screen, "FRIENDS").pressed.emit()
	await wait_process_frames(3)
	assert_null(_button(screen, "TALK"))
