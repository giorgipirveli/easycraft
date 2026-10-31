extends GutTest
## Owner #79, #83 (spec §25.2, §25.5): the main menu's INVITE and GOLD SHOP sit in one row with SCHOOL, AVATAR and
## SETTINGS, on the screen at 16:9 and 20:9; after the name, a new player is asked for a friend's code (the web page's
## ?invite= fills it in) and NO CODE goes on to BOY / GIRL / JUST ME; friends' good news shows on a card over the main
## menu once; SETTINGS offers FRIEND'S CODE once. The menu works on a fresh profile and a fake online service.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const SCREENS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(2400, 1080)]

var menu: Node
var window: Vector2i
var _profile: ProfileData
var service: OnlineService


func before_all() -> void:
	window = get_window().size


func after_all() -> void:
	get_window().size = window
	Audio.stop_all()


func before_each() -> void:
	_profile = Profile.data
	Profile.data = ProfileData.new()
	Profile.data.username = "Kid_1"
	Profile.data.age_band = AgeBand.TEEN_PLUS
	service = OnlineService.new()
	service.backend = FakeBackend.new(FakeServer.new())
	service.device_id = "dev-menu-test"
	service.profile = Profile.data
	service.save_profile = func() -> void: pass
	service.prefs_path = "user://test_invite_menu_%d.json" % OS.get_process_id()
	Session.use_online_service(service)


func after_each() -> void:
	Session.use_online_service(null)
	Profile.data = _profile


func _open_menu(px: Vector2i = SCREENS[0]) -> void:
	get_window().size = px
	menu = load("res://ui/menus/menu.tscn").instantiate()
	menu.set("web_invite_code", func() -> String: return "")
	add_child_autofree(menu)
	await wait_frames(3)


func _button(text: String) -> Button:
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _find(type_name: String) -> Node:
	for n in menu.find_children("*", "", true, false):
		if n.get_script() and (n.get_script() as Script).get_global_name() == type_name and n.is_inside_tree():
			return n
	return null


func test_invite_and_gold_shop_sit_in_one_row_on_every_screen() -> void:
	for px in SCREENS:
		await _open_menu(px)
		menu.call("_show_main")
		await wait_seconds(0.3)
		var row: Array[Button] = []
		for t in ["DISCOVER", "INVITE", "GOLD SHOP", "AVATAR", "SETTINGS"]:   # owner #122: DISCOVER
			var b := _button(t)
			assert_not_null(b, "%s at %s" % [t, px])
			if b:
				row.append(b)
		var screen := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
		for b in row:
			assert_eq(b.get_global_rect().position.y, row[0].get_global_rect().position.y, "one row: %s" % b.text)
			assert_true(screen.encloses(b.get_global_rect()), "%s on the screen at %s" % [b.text, px])
		menu.queue_free()
		await wait_frames(2)


func test_invite_opens_the_invite_page_and_back_returns() -> void:
	await _open_menu()
	menu.call("_show_main")
	await wait_frames(2)
	_button("INVITE").pressed.emit()
	await wait_frames(2)
	var page := _find("InvitePage") as InvitePage
	assert_not_null(page)
	assert_eq(page.service, service)
	page.closed.emit()
	await wait_frames(2)
	assert_not_null(_button("SANDBOX\nBuild anything!"))


func test_gold_shop_opens_and_back_returns() -> void:
	await _open_menu()
	menu.call("_show_main")
	await wait_frames(2)
	_button("GOLD SHOP").pressed.emit()
	await wait_frames(2)
	var shop := _find("GoldShop") as GoldShop
	assert_not_null(shop)
	shop.closed.emit()
	await wait_frames(2)
	assert_not_null(_button("SANDBOX\nBuild anything!"))


func test_after_the_name_a_friend_s_code_is_asked_and_no_code_goes_on() -> void:
	await _open_menu()
	menu.set("web_invite_code", func() -> String: return "BLUE-OTTER-42")
	menu.call("_show_code_step")
	await wait_frames(2)
	var box := _find("InviteCodeBox") as InviteCodeBox
	assert_not_null(box)
	assert_eq(box.edit.text, "BLUE-OTTER-42", "the invite link's code, filled in")
	box.skip_button.pressed.emit()
	await wait_frames(2)
	assert_not_null(_find("LookChoice"), "then BOY / GIRL / JUST ME")


func test_a_web_invite_link_is_kept_for_a_child_who_already_plays() -> void:
	get_window().size = SCREENS[0]
	menu = load("res://ui/menus/menu.tscn").instantiate()
	menu.set("web_invite_code", func() -> String: return "RED-FOX-11")
	add_child_autofree(menu)
	await wait_frames(3)
	assert_eq(Profile.data.invite.pending_code, "RED-FOX-11", "the next sign-in asks the server")


func test_good_news_from_friends_shows_on_a_card_once() -> void:
	await _open_menu()
	service.invite_news.append({"what": "learned", "name": "Sam_22", "gold": 250})
	menu.call("_show_main")
	await wait_frames(3)
	var card := _find("InviteNewsCard") as InviteNewsCard
	assert_not_null(card)
	var texts := card.find_children("*", "Label", true, false).map(func(l: Node) -> String: return (l as Label).text)
	assert_has(texts, "Your friend Sam_22 joined and learned! +250 gold")
	card.closed.emit()
	await wait_frames(3)
	assert_null(_find("InviteNewsCard"), "once")
	assert_not_null(_button("SANDBOX\nBuild anything!"))


func test_settings_offer_a_friend_s_code_once() -> void:
	var panel := SettingsPanel.new()
	panel.make_service = func() -> OnlineService: return service
	add_child_autofree(panel)
	await wait_frames(2)
	panel.show_page(SettingsPanel.WORDS)
	await wait_frames(1)
	var code := panel.find_child("FriendsCode", true, false) as Button
	assert_not_null(code)
	code.pressed.emit()
	await wait_frames(1)
	var box := panel.find_child("InviteCodeBox", true, false) as InviteCodeBox
	assert_not_null(box)
	assert_eq(box.skip_button.text, "BACK")
	box.skip_button.pressed.emit()
	await wait_frames(1)
	assert_null(panel.find_child("InviteCodeBox", true, false))
	Profile.data.invite.used = true
	var again := SettingsPanel.new()
	add_child_autofree(again)
	await wait_frames(2)
	assert_null(again.find_child("FriendsCode", true, false), "not after a code was used")
