extends GutTest
## Where online play meets the rest of the game (M4 Wave 1, Agent C; spec §17): the main menu's
## PLAY ONLINE button next to SANDBOX and SURVIVOR, the pause menu's INVITE row for the host of an
## online world (and the menu still fits 720 px), the HUD's online dot, and Session's section
## "M4 C: online play" (the service, the invite toast over every scene, host and join settings).

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."
const SCREEN := Vector2(1280, 720)

var DIR := "user://test_online_menus_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()


func after_each() -> void:
	Session.use_online_service(null)
	Session.online_reset()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


## A signed-in player (not added to the tree: Session.use_online_service or a test adds it).
func _service(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS, ready_player: bool = true) -> OnlineService:
	if ready_player:
		server.make_account(device, username, band, OnlineRules.CONSENT_VERIFIED if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = band
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.clock = func() -> int: return now
	return s


func _button(root: Node, prefix: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(prefix) and (b as Button).is_visible_in_tree():
			return b
	return null


# --- The main menu ---

func test_play_online_sits_next_to_sandbox_and_survivor_and_opens_the_online_screen() -> void:
	var s := _service("dev-a", "Pip")
	Session.use_online_service(s)
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_main")
	await wait_process_frames(3)
	var sandbox := _button(menu, "SANDBOX")
	var survivor := _button(menu, "SURVIVOR")
	var online := _button(menu, "PLAY ONLINE")
	assert_not_null(online, "a PLAY ONLINE button on the main screen")
	var screen := Rect2(Vector2.ZERO, menu.get_viewport().get_visible_rect().size)
	for b: Button in [sandbox, survivor, online]:
		assert_eq(b.get_global_rect().position.y, sandbox.get_global_rect().position.y, "one row: %s" % b.text)
		assert_true(screen.encloses(b.get_global_rect()), "%s is on the screen: %s in %s" % [b.text, b.get_global_rect(), screen])
		assert_gte(b.size.y, 200.0, "a main button: big")
	assert_gt(online.get_global_rect().position.x, survivor.get_global_rect().position.x, "right of SURVIVOR")
	online.pressed.emit()
	await wait_process_frames(4)
	var shown := menu.find_children("*", "PlayOnlineScreen", true, false)
	assert_eq(shown.size(), 1, "PLAY ONLINE opens its screen")
	assert_eq((shown[0] as PlayOnlineScreen).service, s)
	assert_eq(s.status, OnlineService.ONLINE, "it signs in")


# --- The pause menu's INVITE row ---

func _pause_menu(s: OnlineService, match_id: String) -> PauseMenu:
	var m := PauseMenu.new()
	add_child_autofree(m)
	m.show_monsters_setting(true)
	var director := BotDirector.new()
	add_child_autofree(director)
	m.friends = director
	m.online = s
	m.online_match = match_id
	m.online_world = "Sandbox"
	m.online_players = func() -> int: return 2
	return m


func test_the_online_host_invites_from_the_pause_menu_and_it_still_fits() -> void:
	var s := _service("dev-a", "Pip")
	add_child_autofree(s)
	s.prefs.safe_card_seen = now
	await s.sign_in()
	var m := _pause_menu(s, MATCH)
	m.open()
	await wait_process_frames(2)
	var panel := m.find_children("*", "PanelContainer", true, false)[0] as PanelContainer
	assert_lte(panel.size.y, 720.0 - 40.0, "RESUME to SAVE & QUIT with INVITE fits the 720 px screen")
	var ys: Array[float] = []
	for prefix in ["RESUME", "SETTINGS", "MONSTERS", "FRIENDS", "INVITE", "SAVE"]:
		assert_not_null(_button(m, prefix), prefix)
		ys.append(_button(m, prefix).get_global_rect().position.y)
	var sorted := ys.duplicate()
	sorted.sort()
	assert_eq(ys, sorted, "INVITE right above SAVE & QUIT")
	assert_eq(_button(m, "INVITE").get_parent(), _button(m, "BOARD").get_parent(), "INVITE shares its row with BOARD (M3 Task 12)")
	_button(m, "INVITE").pressed.emit()
	await wait_process_frames(2)
	var invite := m.find_children("*", "InvitePanel", true, false)
	assert_eq(invite.size(), 1)
	assert_eq((invite[0] as InvitePanel).match_id, MATCH)
	assert_eq((invite[0] as InvitePanel).world_name, "Sandbox")
	assert_eq((invite[0] as InvitePanel).players_label.text, "Players: 2 of 4")
	_button(m, "BACK").pressed.emit()
	await wait_process_frames(2)
	assert_not_null(_button(m, "RESUME"), "back to the pause buttons")
	m.close()


func test_no_invite_row_offline_on_lan_or_without_consent() -> void:
	var plain := _pause_menu(null, "")
	plain.open()
	await wait_process_frames(1)
	assert_null(_button(plain, "INVITE"), "solo and LAN: no INVITE")
	plain.close()
	var kit := _service("dev-k", "Kit", AgeBand.UNDER_13, false)
	add_child_autofree(kit)
	await kit.sign_in()
	var young := _pause_menu(kit, MATCH)
	young.open()
	await wait_process_frames(1)
	assert_null(_button(young, "INVITE"), "under-13 without consent: no INVITE")
	young.close()


# --- The HUD's online dot ---

func test_the_hud_shows_a_dot_beside_the_name_while_online() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	await wait_process_frames(1)
	assert_false(hud.online_dot.visible, "solo: no dot")
	var online := [true]
	hud.online_dot.source = func() -> bool: return online[0]
	hud.online_dot.refresh()
	assert_true(hud.online_dot.visible)
	assert_true(hud.online_dot.on)
	var dot := Rect2(Vector2(SCREEN.x + hud.online_dot.offset_left, hud.online_dot.offset_top),
		Vector2(hud.online_dot.offset_right - hud.online_dot.offset_left, hud.online_dot.offset_bottom - hud.online_dot.offset_top))
	var label_rect := Rect2(Vector2(SCREEN.x + hud.username_label.offset_left, hud.username_label.offset_top),
		Vector2(hud.username_label.offset_right - hud.username_label.offset_left, hud.username_label.offset_bottom - hud.username_label.offset_top))
	assert_false(dot.intersects(label_rect), "the name moves left for the dot")
	for b: TouchButton in [hud.physics_button, hud.more_button]:   # WALK and MORE (M2 Task 17)
		var r := Rect2(Vector2(SCREEN.x + b.offset_left, b.offset_top), Vector2(b.offset_right - b.offset_left, b.offset_bottom - b.offset_top))
		assert_false(dot.intersects(r), "clear of %s" % b.text)
	online[0] = false
	hud.online_dot.refresh()
	assert_false(hud.online_dot.visible)
	assert_eq(hud.username_label.offset_right, Hud.USERNAME_RIGHT, "the name goes back")


func test_the_dot_follows_session() -> void:
	assert_false(Session.online_dot_on(), "solo")
	var s := _service("dev-a", "Pip")
	Session.use_online_service(s)
	assert_false(Session.online_dot_on(), "made but not signed in")
	await s.sign_in()
	assert_true(Session.online_dot_on(), "signed in for friends")


# --- Session's section ---

func test_session_keeps_one_toast_that_follows_the_service() -> void:
	var toast := Session.invite_toast()
	assert_eq(Session.online_toast_blockers(), [toast] as Array[Control])
	assert_eq(toast.process_mode, Node.PROCESS_MODE_ALWAYS)
	var bob := _service("dev-b", "Bob")
	Session.use_online_service(bob)
	assert_eq(Session.online_service(), bob)
	assert_eq(bob.process_mode, Node.PROCESS_MODE_ALWAYS, "friends and invites in the pause menu too")
	assert_eq(toast.service, bob)
	await bob.sign_in()
	var pip_id: String = server.make_account("dev-a", "Pip")
	server.befriend(pip_id, bob.backend.user_id())
	server.notify(bob.backend.user_id(), OnlineRules.INVITE, {"match_id": MATCH, "from_username": "Pip", "world_name": "Survivor"}, pip_id)
	await wait_process_frames(1)
	assert_true(toast.visible, "the invite shows over whatever scene runs")
	assert_eq(toast.text_label.text, "Pip invites you to their world!")
	Session.use_online_service(null)
	assert_false(toast.visible)
	assert_eq(Session.invite_toast(), toast, "the same toast (the HUD keeps it as a blocker)")


func test_an_under_13_players_toast_never_shows_before_consent() -> void:
	var kit := _service("dev-k", "Kit", AgeBand.UNDER_13, false)
	Session.use_online_service(kit)
	await kit.sign_in()
	server.notify(kit.backend.user_id(), OnlineRules.INVITE, {"match_id": MATCH, "from_username": "Pip"}, "u-1")
	await wait_process_frames(1)
	assert_false(Session.invite_toast().visible)


func test_the_server_comes_from_online_config() -> void:
	var expected: Dictionary = OnlineConfig.parse_server("")
	var cfg := load("res://core/net/online_config.gd") as GDScript
	for m: Dictionary in cfg.get_script_method_list():
		if m.name == "default_server":
			expected = cfg.call("default_server")   # Agent D's: developer builds this PC, release the VPS
	assert_eq(Session.online_server(), expected)
	assert_eq(Session.online_service().server, expected, "the service Session makes uses it")


func test_host_and_join_settings() -> void:
	Session.prepare_online_host()
	assert_eq(Session.online_config.role, OnlineConfig.HOST)
	assert_eq(Session.online_config.server, Session.online_server())
	assert_true(Session.wants_online())
	assert_false(Session.prepare_online_join("not a match"))
	assert_true(Session.prepare_online_join("  3DCF6DCA-BA73-4E08-A89E-8C538234F741.  "))
	assert_eq(Session.online_config.role, OnlineConfig.JOIN)
	assert_eq(Session.online_config.match_id, MATCH, "normalised")
	assert_false(OnlineFlow.join("nope"), "JOIN with no match id changes nothing")
	assert_eq(Session.online_hosted_match(), "", "solo hosts no match")
	assert_eq(Session.online_players(), 1)
