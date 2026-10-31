extends GutTest
## Session's online path against the development server (server/dev.sh up; M4 early spike). The
## whole script is skipped when no Nakama answers on 127.0.0.1:7350.

const NakamaProbe := preload("res://tests/integration/nakama_probe.gd")

var DIR := "user://test_session_online_up_%d/" % OS.get_process_id()


func should_skip_script():   # untyped like GutTest's own: "-> Variant" fails to parse in a full run
	var why: String = await NakamaProbe.why_not_up(self)
	return false if why == "" else why


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


func test_a_host_switches_to_the_relay_and_close_goes_back_to_solo() -> void:
	Session.online_config = OnlineConfig.from_args(["--online-host"])
	watch_signals(Session)
	Session.host_online()
	await wait_for_signal(Session.online_match_ready, NakamaLink.TIMEOUT_SEC * 2)
	assert_signal_emitted(Session, "online_match_ready")
	assert_true(Session.is_online())
	assert_true(multiplayer.multiplayer_peer is NakamaMultiplayerPeer, "the relay's peer")
	assert_eq(multiplayer.get_unique_id(), 1)
	assert_true(Session.is_host())
	# Session.close() calls close() on any peer that is not offline; NakamaMultiplayerPeer has no
	# _close(), which is an engine error in Godot 4.7 (GUT fails the test on it).
	Session.close()
	assert_false(Session.is_online())
	assert_false(Session.wants_online())
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


func test_a_guest_joining_a_match_that_is_not_there_ends_the_game() -> void:
	Session.online_config = OnlineConfig.from_args(["--online-join=3dcf6dca-ba73-4e08-a89e-8c538234f741."])
	watch_signals(Session)
	Session.join_online(Session.online_config.match_id)
	await wait_for_signal(Session.disconnected, NakamaLink.TIMEOUT_SEC * 3)
	assert_signal_emitted(Session, "disconnected")
	assert_signal_emitted(Session, "online_failed")
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer)
