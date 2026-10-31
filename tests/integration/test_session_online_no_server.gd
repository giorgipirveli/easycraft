extends GutTest
## Session's online path when no Nakama answers (runs everywhere; M4 early spike): a host stays solo,
## a guest ends in `disconnected`, and neither is left on a relay peer.

const NO_SERVER := {"scheme": "http", "host": "127.0.0.1", "port": 1}

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_session_online_%d/" % OS.get_process_id()


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	Session.online_device_id_path = DIR + "device_id.json"


func after_each() -> void:
	Session.online_reset()
	Session.online_device_id_path = DeviceId.PATH
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func test_a_host_that_cannot_sign_in_stays_solo() -> void:
	Session.online_config = {"role": OnlineConfig.HOST, "match_id": "", "server": NO_SERVER}
	watch_signals(Session)
	Session.host_online()
	assert_true(Session.is_host(), "plays solo while it signs in")
	await wait_for_signal(Session.online_failed, NakamaLink.TIMEOUT_SEC + 2)
	assert_signal_emitted(Session, "online_failed")
	assert_false(Session.is_online())
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer)
	assert_true(Session.is_host())
	assert_signal_not_emitted(Session, "disconnected", "a host is never sent to the menu for this")


func test_a_guest_is_never_the_host_while_it_joins_and_a_failure_ends_the_game() -> void:
	Session.online_config = {"role": OnlineConfig.JOIN, "match_id": "3dcf6dca-ba73-4e08-a89e-8c538234f741.", "server": NO_SERVER}
	watch_signals(Session)
	Session.join_online(Session.online_config.match_id)
	assert_false(Session.is_host(), "a joining guest must not apply edits itself")
	await wait_for_signal(Session.disconnected, NakamaLink.TIMEOUT_SEC + 2)
	assert_signal_emitted(Session, "disconnected")
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


func test_the_device_id_is_kept_where_session_is_told() -> void:
	Session.online_config = {"role": OnlineConfig.HOST, "match_id": "", "server": NO_SERVER}
	Session.host_online()
	await wait_for_signal(Session.online_failed, NakamaLink.TIMEOUT_SEC + 2)
	assert_true(FileAccess.file_exists(DIR + "device_id.json"))


func test_leaving_forgets_the_online_settings() -> void:
	Session.online_config = {"role": OnlineConfig.HOST, "match_id": "", "server": NO_SERVER}
	assert_true(Session.wants_online())
	Session.online_reset()
	assert_false(Session.wants_online(), "the next game from the menu is solo or LAN")
