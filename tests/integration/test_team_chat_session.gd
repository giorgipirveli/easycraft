extends GutTest
## The match an online game plays in, for its team room (M4 Wave 2, Agent E): Session.online_match_id
## is the relayed match's id while hosting (and while a guest), "" in solo and LAN. Against the
## development server; skipped when no Nakama answers on 127.0.0.1:7350.

const NakamaProbe := preload("res://tests/integration/nakama_probe.gd")

var DIR := "user://test_team_chat_session_%d/" % OS.get_process_id()


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


func test_the_hosted_match_names_the_team_room() -> void:
	assert_eq(Session.online_match_id(), "", "solo: no match")
	Session.online_config = OnlineConfig.from_args(["--online-host"])
	Session.host_online()
	await wait_for_signal(Session.online_match_ready, NakamaLink.TIMEOUT_SEC * 2)
	var id := Session.online_match_id()
	assert_ne(id, "")
	assert_eq(id, str(Session.online_link().call(&"match_id")))
	assert_eq(OnlineChatRules.team_room(id), id, "a relayed match id is its team room's name")
	Session.close()
	assert_eq(Session.online_match_id(), "", "back to solo")
