extends GutTest
## M7 Task 4 (spec §20.3): home Wi-Fi play (LAN, ENet) can't work in a browser, so there it is never offered and never
## started: Session refuses to open an ENet host or join, the developer menu has no HOST LAN / JOIN (never a dead
## button; a line points to PLAY ONLINE instead), and the grown-ups' pages don't promise it. On Android and the desktop
## everything stays as it was.

const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
const DESKTOP_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
const PORT_BASE := 46_000

var _window_size: Vector2i


func before_all() -> void:
	_window_size = get_window().size


func before_each() -> void:
	PlatformRules.shader_warmup = false   # its menus pretend to be a browser: no shader warm-up under the root here


func after_each() -> void:
	PlatformRules.simulated = {}
	PlatformRules.shader_warmup = true
	Session.close()


func after_all() -> void:
	get_window().size = _window_size


func _port() -> int:
	return PORT_BASE + OS.get_process_id() % 1000


func test_in_a_browser_session_opens_no_enet_host() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	assert_eq(Session.host_lan(_port()), ERR_UNAVAILABLE, "refused")
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "still solo")


func test_in_a_browser_session_joins_no_lan_game() -> void:
	PlatformRules.simulated = DESKTOP_BROWSER
	assert_eq(Session.join_lan("192.168.1.20", _port()), ERR_UNAVAILABLE, "refused")
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "still solo")


func test_on_the_desktop_lan_hosting_works_as_before() -> void:
	assert_eq(Session.host_lan(_port()), OK)
	assert_true(multiplayer.multiplayer_peer is ENetMultiplayerPeer)


# --- The developer menu (debug builds; a debug web export has it too) ---

func _dev_menu() -> Node:
	get_window().size = Vector2i(2400, 1080)
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_show_dev")
	await wait_frames(4)
	return menu


func _visible_texts(root: Node, type: String) -> PackedStringArray:
	var out := PackedStringArray()
	for c in root.find_children("*", type, true, false):
		if (c as Control).is_visible_in_tree():
			out.append(str(c.get("text")))
	return out


func test_in_a_browser_the_developer_menu_offers_no_lan() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var menu: Node = await _dev_menu()
	var buttons := _visible_texts(menu, "Button")
	assert_false(buttons.has("HOST LAN"), "no HOST LAN: %s" % [buttons])
	assert_false(buttons.has("JOIN"), "no JOIN")
	assert_true(buttons.has("AUTOPILOT BLOCKY"), "the rest of the developer menu stays")
	assert_true(buttons.has("BACK"))
	assert_true(_visible_texts(menu, "LineEdit").is_empty(), "no address to type")
	assert_string_contains("\n".join(_visible_texts(menu, "Label")), "PLAY ONLINE", "a line points to online play")


func test_on_the_desktop_the_developer_menu_keeps_lan() -> void:
	var menu: Node = await _dev_menu()
	var buttons := _visible_texts(menu, "Button")
	assert_true(buttons.has("HOST LAN"), "HOST LAN: %s" % [buttons])
	assert_true(buttons.has("JOIN"))
	assert_eq(_visible_texts(menu, "LineEdit").size(), 1, "the host's address")


# --- The grown-ups' DELETE MY ONLINE ACCOUNT page says what keeps working ---

func test_the_delete_page_promises_home_wifi_play_only_where_there_is_some() -> void:
	assert_string_contains(DeleteAccountPage.stays_words(true), "home Wi-Fi play")
	var web := DeleteAccountPage.stays_words(false)
	assert_false(web.contains("Wi-Fi"), "not in a browser: %s" % web)
	assert_string_contains(web, "bot friends")
	assert_string_contains(web, "can't be undone")


# --- No quitting a browser tab (a tab is closed by the browser) ---

func _main_menu() -> Node:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_show_main")
	await wait_frames(2)
	return menu


func test_in_a_browser_back_on_the_main_screen_does_not_quit() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var menu: Node = await _main_menu()
	var quits: Array[int] = [0]
	menu.set("quit_game", func() -> void: quits[0] += 1)
	menu.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(quits[0], 0, "the game stays on its menu")


func test_elsewhere_back_on_the_main_screen_quits_as_before() -> void:
	var menu: Node = await _main_menu()
	var quits: Array[int] = [0]
	menu.set("quit_game", func() -> void: quits[0] += 1)
	menu.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(quits[0], 1)
