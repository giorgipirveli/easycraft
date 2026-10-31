extends GutTest
## Spec §17.3 "Safety in the world" (the M4 Task 10 review's finding A): the host removes a player from its world.
## Online the server takes them out of the match and off the invite list and tells their game (notification 107);
## their game goes to the menu with kind words and never tries to rejoin.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."

var DIR := "user://test_host_removes_guest_%d/" % OS.get_process_id()
var server: RefCounted
var notices: Array = []
var gone := [0]


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	notices.clear()
	gone[0] = 0
	Session.net_notice.connect(_on_notice)
	Session.disconnected.connect(_on_gone)


func after_each() -> void:
	Session.net_notice.disconnect(_on_notice)
	Session.disconnected.disconnect(_on_gone)
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func _on_notice(code: StringName, _words: String) -> void:
	notices.append(code)


func _on_gone() -> void:
	gone[0] += 1


func _service(device: String, username: String) -> OnlineService:
	server.make_account(device, username)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.prefs.safe_card_seen = 1
	add_child_autofree(s)
	return s


func test_the_host_asks_the_server_and_the_removed_players_game_hears_it() -> void:
	var host := _service("dev-host", "Hostie")
	var guest := _service("dev-guest", "Guesty")
	assert_eq(await host.sign_in(), "")
	assert_eq(await guest.sign_in(), "")
	watch_signals(guest)
	var guest_id := str(server.id_of("Guesty"))
	assert_eq(await host.remove_guest(guest_id, MATCH), "")
	assert_eq(server.removed, [{"from": server.id_of("Hostie"), "user_id": guest_id, "match_id": MATCH}])
	assert_signal_emitted_with_parameters(guest, "removed_from_world", [MATCH])


func test_the_words_are_kind_and_say_what_happens() -> void:
	assert_true(NetWords.CODES.has(NetWords.REMOVED))
	assert_string_contains(NetWords.text(NetWords.REMOVED), "The host asked you to leave their world")


func test_a_removed_guest_goes_to_the_menu_and_never_tries_to_rejoin() -> void:
	Session._leave_removed()
	assert_eq(notices, [NetWords.REMOVED])
	assert_eq(gone[0], 1, "back to the menu")
	assert_false(Session.a_rejoining(), "no rejoin")


func test_a_notice_for_another_world_changes_nothing() -> void:
	Session._on_removed_from_world(MATCH)   # this game is not in that match (not online at all)
	assert_eq(notices, [])
	assert_eq(gone[0], 0)


func test_only_a_host_with_that_guest_can_remove_them() -> void:
	assert_eq(await Session.host_remove_guest(12345), "?", "no such guest here")
