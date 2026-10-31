extends GutTest
## Owner #81, #82, #85 (brief 2026-09-30 items 3-4): the FRIENDS page against the fake server. With no friends it says
## so kindly and offers INVITE A FRIEND; each friend shows the friendship level and the next one's shared reward; GIFT
## picks a present (one a day to each friend) that the friend OPENs into the game and THANKs; a friend's proud moment is
## cheered with kind words only; study buddies ask and say yes. The main menu has FRIENDS in its row. Every page fits
## the menu's frame.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_friendship_page_%d/" % OS.get_process_id()
var server: RefCounted
var page: FriendsPage


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	Audio.stop_all()


func _service(device: String, username: String) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.in_online_world = func() -> bool: return false
	add_child_autofree(s)
	return s


func _open(s: OnlineService) -> FriendsPage:
	page = FriendsPage.new()
	page.service = s
	add_child_autofree(page)
	for i in 30:
		await wait_process_frames(1)
		if page.view == FriendsPage.FRIENDS:
			break
	return page


func _wait_view(v: StringName) -> void:
	for i in 30:
		if page.view == v:
			return
		await wait_process_frames(1)


func _button(node_name: String) -> Button:
	var found := page.find_children(node_name, "Button", true, false)
	for b: Button in found:
		if b.is_visible_in_tree():
			return b
	return null


func _labels() -> String:
	var out: Array[String] = []
	for l in page.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	return " | ".join(out)


func _fits(what: String) -> void:
	await wait_process_frames(2)
	var size := page.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [what, size])
	assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [what, size])


func _pair() -> Array[OnlineService]:
	var a: String = server.make_account("dev-alex", "Alex_7")
	var b: String = server.make_account("dev-sam", "Sam_22")
	server.befriend(a, b)
	var alex := _service("dev-alex", "Alex_7")
	var sam := _service("dev-sam", "Sam_22")
	return [alex, sam] as Array[OnlineService]


func test_no_friends_yet_says_so_kindly_and_offers_invite() -> void:
	server.make_account("dev-alex", "Alex_7")
	await _open(_service("dev-alex", "Alex_7"))
	assert_eq(page.view, FriendsPage.FRIENDS)
	assert_string_contains(_labels(), FriendshipRules.NO_FRIENDS)
	var asked := [0]
	page.invite_requested.connect(func() -> void: asked[0] += 1)
	_button("InviteAFriend").pressed.emit()
	assert_eq(asked[0], 1, "the menu opens INVITE")
	await _fits("friends, empty")


## Owner #93: without the internet the page says what still works alone, and still fits.
func test_no_internet_says_what_works_alone() -> void:
	server.make_account("dev-alex", "Alex_7")
	server.set("down", true)
	await _open(_service("dev-alex", "Alex_7"))
	await _wait_view(FriendsPage.FAILED)
	assert_eq(page.view, FriendsPage.FAILED)
	assert_string_contains(_labels(), OnlineRules.PLAY_ALONE)
	await _fits("friends, no internet")


func test_a_friends_level_a_present_opened_and_thanked() -> void:
	var pair := _pair()
	var alex := pair[0]
	var sam := pair[1]
	await _open(alex)
	assert_string_contains(_labels(), "Sam_22  -  Friends")
	assert_string_contains(_labels(), FriendshipRules.next_words(0))
	await _fits("friends")
	_button("Gift").pressed.emit()
	await _wait_view(FriendsPage.PICK_PRESENT)
	assert_string_contains(_labels(), "A present for Sam_22")
	await _fits("pick a present")
	_button("Kind_seeds").pressed.emit()
	await _wait_view(FriendsPage.FRIENDS)
	await wait_process_frames(2)
	assert_string_contains(_labels(), "Your present is on its way!")
	assert_string_contains(_labels(), "Sam_22  -  Good friends", "a present is a day together")
	# Sam opens it: the game gives the seeds; THANK YOU.
	page.queue_free()
	await wait_process_frames(1)
	await _open(sam)
	_button("Tab_presents").pressed.emit()
	await wait_process_frames(2)
	assert_eq(page.view, FriendsPage.PRESENTS)
	assert_string_contains(_labels(), "Alex_7 sent you seeds!")
	await _fits("presents")
	_button("Open").pressed.emit()
	await _wait_view(FriendsPage.PRESENTS)
	await wait_process_frames(4)
	assert_eq(int(sam.profile.backpack.get(BlockIds.WHEAT, 0)), FriendPresents.SEEDS, "the game gave the seeds")
	assert_string_contains(_labels(), "backpack")
	var alex_id: String = server.id_of("Alex_7")
	var before := int(server.wallets.get(alex_id, 0))
	_button("ThankYou").pressed.emit()
	await wait_process_frames(6)
	assert_string_contains(_labels(), "Thank you sent!")
	assert_eq(int(server.wallets.get(alex_id, 0)), before + FriendPresents.THANK_GOLD, "a small gift back")


func test_a_present_for_a_new_friend_waits_on_the_code() -> void:
	server.make_account("dev-alex", "Alex_7")
	var alex := _service("dev-alex", "Alex_7")
	await _open(alex)
	_button("Tab_presents").pressed.emit()
	await wait_process_frames(2)
	_button("GiftNewFriend").pressed.emit()
	await _wait_view(FriendsPage.PICK_PRESENT)
	assert_string_contains(_labels(), "A present for a new friend")
	_button("Kind_buddy_egg").pressed.emit()
	await _wait_view(FriendsPage.PRESENTS)
	await wait_process_frames(2)
	assert_string_contains(_labels(), "Your present waits on your invite code for a new friend!")
	assert_string_contains(_labels(), "1 of 3 waiting")


func test_cheer_a_friends_moment_with_kind_words() -> void:
	var pair := _pair()
	var alex := pair[0]
	var sam := pair[1]
	assert_eq(await alex.sign_in(), "")
	SocialSender.moment(PostcardRules.landed("moon"), alex.profile)
	await alex.send_social_events()
	await _open(sam)
	assert_string_contains(_labels(), "Alex_7 just landed on the Moon! Send a cheer?")
	_button("Cheer0").pressed.emit()
	await _wait_view(FriendsPage.CHEER)
	await _fits("cheer")
	for id: String in FriendshipRules.CHEER_IDS:
		assert_not_null(_button("Cheer_" + id), "only the kind words: %s" % id)
	assert_eq(page.find_children("*", "LineEdit", true, false).size(), 0, "never typed")
	_button("Cheer_so_proud").pressed.emit()
	await _wait_view(FriendsPage.FRIENDS)
	await wait_process_frames(2)
	assert_string_contains(_labels(), "Your cheer is on its way!")
	assert_null(_button("Cheer0"), "cheered once: the moment is gone")
	await wait_process_frames(8)   # Alex's open game heard note 109: the cheer is on the menu's card
	var words: Array = alex.take_invite_news().map(func(n: Dictionary) -> String: return InviteRules.news_words(n))
	assert_has(words, "Sam_22 cheered: So proud of you! (you landed on the Moon)")


func test_a_cheer_at_one_tap() -> void:
	var pair := _pair()
	var alex := pair[0]
	var sam := pair[1]
	assert_eq(await alex.sign_in(), "")
	SocialSender.moment(PostcardRules.unit("g4.maths.big_numbers", "Big numbers"), alex.profile)
	await alex.send_social_events()
	await _open(sam)
	var one := _button("Cheer0_amazing")
	assert_not_null(one, "one tap")
	assert_eq(one.text, "AMAZING!")
	assert_not_null(_button("Cheer0_well_done"))
	await _fits("friends with a moment")
	one.pressed.emit()
	await _wait_view(FriendsPage.FRIENDS)
	await wait_process_frames(4)
	assert_string_contains(_labels(), "Your cheer is on its way!")
	assert_eq(server.soc[server.id_of("Sam_22")].feed, [], "cheered once")
	await wait_process_frames(8)
	var words: Array = alex.take_invite_news().map(func(n: Dictionary) -> String: return InviteRules.news_words(n))
	assert_has(words, "Sam_22 cheered: Amazing! (you mastered Big numbers)")


func test_study_buddies_ask_and_yes() -> void:
	var pair := _pair()
	var alex := pair[0]
	var sam := pair[1]
	await _open(alex)
	_button("BuddyAsk").pressed.emit()
	await wait_process_frames(6)
	assert_string_contains(_labels(), "Asked! When your friend says yes, you're study buddies.")
	assert_true(_button("BuddyAsk").disabled, "asked once")
	page.queue_free()
	await wait_process_frames(1)
	await _open(sam)
	_button("BuddyYes").pressed.emit()
	await wait_process_frames(6)
	assert_string_contains(_labels(), FriendshipRules.BUDDY_GOAL)
	assert_string_contains(_labels(), FriendshipRules.buddy_words(0))
	assert_not_null(_button("BuddyStop"))


func test_the_main_menu_has_friends_in_its_row_on_every_screen() -> void:
	var saved := Profile.data
	Profile.data = ProfileData.new()
	Profile.data.username = "Kid_1"
	Profile.data.age_band = AgeBand.TEEN_PLUS
	var s := _service("dev-menu", "Kid_1")
	Session.use_online_service(s)
	var window := get_window().size
	for px: Vector2i in [Vector2i(1280, 720), Vector2i(2400, 1080)]:
		get_window().size = px
		var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
		menu.set("web_invite_code", func() -> String: return "")
		add_child_autofree(menu)
		await wait_process_frames(3)
		menu.call("_show_main")
		await wait_seconds(0.3)
		var row: Array[Button] = []
		for t in ["DISCOVER", "INVITE", "FRIENDS", "GOLD SHOP", "AVATAR", "SETTINGS"]:   # owner #122: DISCOVER
			for b in menu.find_children("*", "Button", true, false):
				if (b as Button).text == t and (b as Button).is_visible_in_tree():
					row.append(b)
		assert_eq(row.size(), 6, "six at %s" % px)
		var screen := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
		for b in row:
			assert_eq(b.get_global_rect().position.y, row[0].get_global_rect().position.y, "one row: %s" % b.text)
			assert_true(screen.encloses(b.get_global_rect()), "%s on the screen at %s" % [b.text, px])
		menu.queue_free()
		await wait_process_frames(1)
	get_window().size = window
	Session.use_online_service(null)
	Profile.data = saved
