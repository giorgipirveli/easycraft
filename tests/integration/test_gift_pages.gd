extends GutTest
## GIFT and VISIT on a friend's row, PRESENTS and MY SHOWCASE on PLAY ONLINE's friends page (M4 Wave 3,
## agent I; spec §17.5): a build from the child's shelf or a bottle goes to the friend; presents open into
## stamps, are deleted or reported; stickers left on my showcase are read and deleted; VISIT fetches the
## friend's showcase. Every page fits the main menu's panel, with big buttons.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)   # the main menu's panel (test_online_screens.gd)

var DIR := "user://test_gift_pages_%d/" % OS.get_process_id()
var server: RefCounted
var mine: OnlineService
var mia: OnlineService
var panel: OnlineFriendsPanel


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	mine = await _player("dev-me", "Hopper")
	mia = await _player("dev-mia", "Mia_2")
	server.befriend(mine.backend.user_id(), mia.backend.user_id())
	await mine.refresh_friends()
	await mia.refresh_friends()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _player(device: String, username: String) -> OnlineService:
	server.make_account(device, username)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.gift_book = GiftStampBook.new()
	s.gift_book_path = DIR + device + "_gifts.json"
	add_child_autofree(s)
	s.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	assert_eq(await s.sign_in(), "")
	return s


func _cube(n: int, id: int = BlockIds.PLANKS) -> String:
	var b := {}
	for x in n:
		for y in n:
			for z in n:
				b[Vector3i(x, y, z)] = id
	return BuildCodec.encode(b)


## PLAY ONLINE's friends page for `s` in the main menu's panel.
func _panel(s: OnlineService) -> OnlineFriendsPanel:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = PANEL_CONTENT
	add_child_autofree(holder)
	var p := OnlineFriendsPanel.new()
	p.service = s
	p.visit_starts = false
	holder.add_child(p)
	await wait_process_frames(3)
	return p


func _find(root: Node, node_name: String) -> Button:
	return root.find_child(node_name, true, false) as Button


func _fits(p: Control, what: String) -> void:
	await wait_process_frames(3)
	var size := p.get_combined_minimum_size()
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	for b: Button in p.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and b.text != "x":
			assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is big" % [what, b.name])


func test_a_friends_row_has_gift_and_visit_and_the_page_has_presents_and_my_showcase() -> void:
	var p := await _panel(mine)
	var row := p.list.find_child("Friend_Mia_2", true, false)
	assert_not_null(row)
	for n in ["Gift", "Visit", "More"]:
		assert_not_null(_find(row, n), n)
	assert_not_null(_find(p, "Presents"))
	assert_not_null(_find(p, "MyShowcase"))
	await _fits(p, "the friends page")
	assert_lte((row as Control).get_combined_minimum_size().x, OnlineFriendsPanel.LIST_WIDTH, "the row fits the list")


func test_gift_a_build_from_my_shelf() -> void:
	var p := await _panel(mine)
	_find(p.list, "Gift").pressed.emit()
	await wait_process_frames(2)
	_find(p, "ABuild").pressed.emit()
	await wait_process_frames(2)
	assert_string_contains((p.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
		as Array).reduce(func(a: String, b: String) -> String: return a + " " + b, ""), "MORE, then SHARE", "how to pick one")
	mine.gift_book.keep_mine(_cube(3))
	p.back_button.pressed.emit()   # BACK: to the choice first
	await wait_process_frames(1)
	assert_not_null(_find(p, "ABuild"), "back on the choice")
	_find(p, "ABuild").pressed.emit()
	await wait_process_frames(2)
	await _fits(p, "the shelf")
	_find(p, "Build1").pressed.emit()
	await wait_until(func() -> bool: return (server.gifts.get(mia.backend.user_id(), []) as Array).size() == 1, 5.0)
	assert_eq(BuildCodec.count_of(server.gifts[mia.backend.user_id()][0].build), 27)
	p.back_button.pressed.emit()
	await wait_process_frames(1)
	p.back_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(p.picked.is_empty(), "back on the list")


func test_a_bottle_with_a_phrase_and_a_tiny_build() -> void:
	mine.gift_book.keep_mine(_cube(2, BlockIds.RED))
	mine.gift_book.keep_mine(_cube(6))   # too big for a bottle: not offered
	var p := await _panel(mine)
	_find(p.list, "Gift").pressed.emit()
	await wait_process_frames(2)
	_find(p, "ABottle").pressed.emit()
	await wait_process_frames(2)
	await _fits(p, "the bottle page")
	var send := _find(p, "Send")
	assert_true(send.disabled, "a phrase first")
	assert_null(_find(p, "Tiny2"), "only builds that fit a bottle")
	_find(p, "Phrase_Hi").pressed.emit()
	_find(p, "Tiny1").pressed.emit()
	assert_false(send.disabled)
	send.pressed.emit()
	await wait_until(func() -> bool: return (server.bottles.get(mia.backend.user_id(), []) as Array).size() == 1, 5.0)
	var b: Dictionary = server.bottles[mia.backend.user_id()][0]
	assert_eq(b.phrase, "Hi!")
	assert_eq(b.build, _cube(2, BlockIds.RED))


func test_presents_open_into_stamps_are_deleted_or_reported() -> void:
	await mine.send_gift(mia.backend.user_id(), _cube(2))
	await mine.send_gift(mia.backend.user_id(), _cube(1))
	await mine.send_gift(mia.backend.user_id(), _cube(3))
	await mia.refresh_gifts()
	var p := await _panel(mia)
	assert_eq(_find(p, "Presents").text, "PRESENTS (3)")
	_find(p, "Presents").pressed.emit()
	await wait_process_frames(3)
	await _fits(p, "the presents page")
	var page := p.find_child("Presents", true, false) as GiftsPage
	var first := page.list.get_child(0)
	_find(first, "Open").pressed.emit()
	await wait_until(func() -> bool: return mia.gift_book.slots().size() == 1, 5.0)
	assert_string_contains(page.message.text, "GIFTS page")
	var next := page.list.get_child(0)
	_find(next, "Delete").pressed.emit()
	await wait_until(func() -> bool: return mia.gifts.size() == 1, 5.0)
	_find(page.list.get_child(0), "Report").pressed.emit()
	await wait_process_frames(1)
	_find(page, "Reason_bad_build").pressed.emit()
	await wait_until(func() -> bool: return server.build_reports.size() == 1, 5.0)
	assert_eq(server.build_reports[0].what, "gift")
	assert_true(mia.is_muted(mine.backend.user_id()))
	await wait_process_frames(2)
	var stamps := page.list.find_children("Stamp_*", "", true, false)
	assert_eq(stamps.size(), 1, "the opened stamp is listed with DELETE")
	_find(stamps[0], "Delete").pressed.emit()
	assert_eq(mia.gift_book.slots(), [] as Array[int])


func test_my_showcase_lists_stickers_to_delete_and_can_come_down() -> void:
	await mine.publish_showcase(_cube(4))
	await mia.sign_guestbook(mine.backend.user_id(), "star")
	var p := await _panel(mine)
	_find(p, "MyShowcase").pressed.emit()
	await wait_until(func() -> bool: return p.find_child("Sticker_*", true, false) != null, 5.0)
	await _fits(p, "my showcase page")
	var row := p.find_child("Sticker_*", true, false)
	assert_string_contains((row.find_children("*", "Label", true, false)[0] as Label).text, "Mia_2")
	_find(row, "Delete").pressed.emit()
	await wait_until(func() -> bool: return (server.guestbooks.get(mine.backend.user_id(), []) as Array).is_empty(), 5.0)
	_find(p, "TakeDown").pressed.emit()
	await wait_until(func() -> bool: return not server.showcases.has(mine.backend.user_id()), 5.0)


func test_visit_fetches_the_friends_showcase_or_says_there_is_none() -> void:
	var p := await _panel(mine)
	watch_signals(p)
	_find(p.list, "Visit").pressed.emit()
	await wait_until(func() -> bool: return not p.message.text.begins_with("One moment"), 5.0)
	assert_eq(p.message.text, GiftRules.message("no_showcase"))
	assert_signal_not_emitted(p, "visit_requested")
	await mia.publish_showcase(_cube(5, BlockIds.BRICK))
	_find(p.list, "Visit").pressed.emit()
	await wait_until(func() -> bool: return get_signal_emit_count(p, "visit_requested") == 1, 5.0)
	var shown: Dictionary = get_signal_parameters(p, "visit_requested")[0]
	assert_eq(shown.owner, "Mia_2")
	assert_eq(shown.build, _cube(5, BlockIds.BRICK))
