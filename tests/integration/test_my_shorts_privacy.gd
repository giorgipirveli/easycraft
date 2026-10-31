extends GutTest
## MAKE MY SHORT: nothing leaves the device. A child's Shorts live in the profile on this device only: the account's
## server backup (the only payload made from the profile: ProfileBackup.to_backup) never has them, nor their hearts and
## seen marks, nor their words or photos' names; a merge with the server's copy keeps this device's; making, keeping,
## liking or deleting one never makes the profile sync write anything; and the maker's code calls nothing that talks
## to a network. No rewards either: making Shorts changes nothing else in the profile.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_my_shorts_privacy_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var msec := 100_000


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	msec = 100_000


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _recipe() -> Dictionary:
	return {"template": "built", "title": "My secret base", "photos": ["p_20261001_101500.jpg", "p_20261001_101600.jpg"],
		"captions": ["Look at my hidden door.", "I added lamps."], "ending": "Can you build one too?"}


func _profile_with_shorts() -> ProfileData:
	var p := ProfileData.new()
	p.username = "Pip"
	p.age_band = AgeBand.TEEN_PLUS
	p.updated_at = now
	var id := p.my_shorts.add(_recipe(), now)
	p.shorts.like(id, now)
	p.shorts.mark_seen(id)
	p.shorts.like("rocket_parts", now)
	p.shorts.mark_seen("moon_phases")
	return p


func test_the_profile_keeps_them_on_this_device() -> void:
	var p := _profile_with_shorts()
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.my_shorts.count(), 1)
	assert_eq(back.my_shorts.recipe("mine:1").title, "My secret base")
	assert_true(back.shorts.is_liked("mine:1"))


func test_the_server_backup_never_has_them() -> void:
	var text := ProfileBackup.to_backup(_profile_with_shorts())
	var d: Dictionary = JSON.parse_string(text)
	assert_false(d.has("my_shorts"))
	for secret: String in ["mine:", "My secret base", "hidden door", "p_20261001", "lamps"]:
		assert_false(text.contains(secret), secret)
	assert_true(text.contains("rocket_parts"), "the game's own Shorts' hearts still travel")
	assert_true(text.contains("moon_phases"))
	for g: Dictionary in ProfileBackup.group_texts(_profile_with_shorts()).values():
		assert_false(str(g.text).contains("mine:"))


func test_a_merge_with_the_server_s_copy_keeps_this_device_s() -> void:
	var local := _profile_with_shorts()
	var newer := ProfileData.new()
	newer.username = "Pip"
	newer.age_band = AgeBand.TEEN_PLUS
	newer.universe_unlocked = 3
	newer.updated_at = now + 500   # another device wrote later: its copy wins the rest
	var out: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(newer)).profile
	assert_eq(out.universe_unlocked, 3)
	assert_eq(out.my_shorts.count(), 1, "this device's Shorts stay")
	assert_true(out.shorts.is_liked("mine:1"), "and their hearts")
	var older: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(ProfileData.new())).profile
	assert_eq(older.my_shorts.count(), 1)


func _service(profile: ProfileData) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-a"
	s.profile = profile
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "dev-a.json"
	s.wallet_path = DIR + "wallet.json"
	s.clock = func() -> int: return now
	s.msec_clock = func() -> int: return msec
	s.prefs.safe_card_seen = now
	add_child_autofree(s)
	s.profile_sync.msec = func() -> int: return msec
	return s


func _wait_debounce(s: OnlineService) -> void:
	msec += ProfileBackup.MAX_WAIT_MSEC + 1000
	s.profile_sync.poll()
	for i in 10:
		await wait_process_frames(1)


func test_making_keeping_and_deleting_a_short_never_writes_to_the_server() -> void:
	var p := ProfileData.new()
	p.username = "Pip"
	p.age_band = AgeBand.TEEN_PLUS
	p.updated_at = now
	var s := _service(p)
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.claim_username("Pip"), "")
	var id: String = s.backend.user_id()
	var before: String = server.backup_of(id)
	var uploads := s.profile_sync.uploads
	var made := p.my_shorts.add(_recipe(), now)   # SAVE in the maker
	p.shorts.like(made, now)                       # a heart on it
	p.shorts.mark_seen(made)
	p.updated_at = now + 10
	s.profile_sync.mark_changed()                  # what Profile.save does
	await _wait_debounce(s)
	assert_eq(s.profile_sync.uploads, uploads, "nothing to send: the backup is the same")
	assert_eq(server.backup_of(id), before)
	p.my_shorts.remove(made)                       # DELETE
	p.shorts.forget(made)
	s.profile_sync.mark_changed()
	await _wait_debounce(s)
	assert_eq(s.profile_sync.uploads, uploads)
	p.universe_unlocked = 2                        # something that does travel
	p.my_shorts.add(_recipe(), now)
	s.profile_sync.mark_changed()
	await _wait_debounce(s)
	assert_eq(s.profile_sync.uploads, uploads + 1, "a real change still uploads…")
	assert_false(server.backup_of(id).contains("mine:"), "…without the child's Shorts")
	assert_false(server.backup_of(id).contains("My secret base"))


func test_the_maker_s_code_never_talks_to_a_network() -> void:
	var files: Array[String] = []
	for dir: String in ["res://core/shorts/mine", "res://ui/shorts/mine"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				files.append(dir.path_join(f))
	assert_gte(files.size(), 6)
	var never := ["HTTPRequest", "HTTPClient", "OnlineService", "Session.", "rpc(", "rpc_id(", "multiplayer", "Nakama",
		"JavaScriptBridge", "WebGlue", "StreamPeer", "PacketPeer", "WebSocket", "ENet", "ProfileSync", "shell_open",
		"PhotoShare", "clipboard_set", "SocialSender", "download_buffer", "OS.execute"]
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for word: String in never:
			assert_false(text.contains(word), "%s says %s" % [path, word])


func test_making_shorts_rewards_nothing() -> void:
	var p := ProfileData.new()
	var before := JSON.parse_string(p.to_json()) as Dictionary
	for i in 5:
		p.my_shorts.add(_recipe(), now + i)
	var after := JSON.parse_string(p.to_json()) as Dictionary
	for key: String in after:
		if key in ["my_shorts"]:
			continue
		assert_eq(after[key], before[key], key + ": no gold, stars, badges, stickers or counts for making Shorts")
