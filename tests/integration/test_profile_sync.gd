extends GutTest
## The profile backup against the fake server (M4 Wave 2, agent F; owner #67; spec §7.4, §17.1): the first
## backup at the claim and at sign-in, a reinstall on the same device restored, the newer copy winning, changes
## uploaded debounced and at once on quit, and codes used offline recorded on the server at the next sign-in.
## Owner #67: the backup carries no gold (the wallet brings it), every write is by version (another device of the
## account wrote in between: read, merge, write again), and a claimed account's profile has the account's name.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const FIRST_CODE_HASH := "a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a"

var DIR := "user://test_profile_sync_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var msec := 100_000
var saves: Array[String] = []


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	saves.clear()
	msec = 100_000


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _service(device: String, profile: ProfileData, wallet_file: String = "") -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = profile
	s.save_profile = func() -> void: saves.append(device)
	s.prefs_path = DIR + device + ".json"
	s.wallet_path = DIR + (wallet_file if wallet_file != "" else "wallet_" + device + ".json")
	s.clock = func() -> int: return now
	s.msec_clock = func() -> int: return msec
	s.prefs.safe_card_seen = now
	add_child_autofree(s)
	s.profile_sync.msec = func() -> int: return msec
	return s


func _profile(username: String, universe: int = 1, at: int = 0) -> ProfileData:
	var p := ProfileData.new()
	p.username = username
	p.age_band = AgeBand.TEEN_PLUS
	p.universe_unlocked = universe
	p.updated_at = at
	return p


func _backup(id: String) -> ProfileData:
	var text: String = server.backup_of(id)
	assert_ne(text, "", "a backup is on the server")
	return ProfileData.from_json(text)


func _backup_dict(id: String) -> Dictionary:
	return JSON.parse_string(server.backup_of(id))


func test_the_first_claim_uploads_the_first_backup() -> void:
	var s := _service("dev-a", _profile("Pip", 2, now))
	assert_eq(await s.sign_in(), "")
	var id: String = s.backend.user_id()
	assert_eq(server.backup_of(id), "", "nothing before the claim: nothing to restore to")
	assert_eq(await s.claim_username("Pip"), "")
	assert_eq(_backup(id).universe_unlocked, 2)
	assert_eq(_backup(id).username, "Pip")


func test_sign_in_uploads_a_newer_phone_profile() -> void:
	var id: String = server.make_account("dev-a", "Pip")
	var old := _profile("Pip", 2, now - 500)
	server.storage[id] = {"profiles/profile": {"value": ProfileBackup.to_backup(old), "version": "v1"}}
	var p := _profile("Pip", 3, now)
	p.settings.music_volume = 0.25
	p.stamps = {"settings": now}
	var s := _service("dev-a", p)
	assert_eq(await s.sign_in(), "")
	assert_eq(s.profile.universe_unlocked, 3, "the phone was newer")
	assert_eq(_backup(id).universe_unlocked, 3)
	assert_almost_eq(float(_backup(id).settings.music_volume), 0.25, 0.001)
	assert_false(saves.has("dev-a"), "the phone's profile was not touched")


func test_a_reinstall_on_the_same_device_restores_the_backup_and_the_wallet_its_gold() -> void:
	var id: String = server.make_account("dev-a", "Pip")
	var played := _profile("Pip", 2, now - 3600)
	played.codes_redeemed.append(FIRST_CODE_HASH)
	played.cosmetics.append("hat.party")
	played.settings.graphics = "high"
	server.storage[id] = {"profiles/profile": {"value": ProfileBackup.to_backup(played), "version": "v1"}}
	server.wallets[id] = 900   # owner #67: the gold is the wallet's
	# A new install: the age gate and the name again, nothing played yet, graphics picked here.
	var fresh := _profile("Pip", 1, now)
	fresh.settings.graphics = "low"
	var s := _service("dev-a", fresh)
	var restored: Array = []
	s.profile_sync.restored.connect(func() -> void: restored.append(true))
	assert_eq(await s.sign_in(), "")
	assert_eq(restored, [true])
	assert_eq(s.profile, fresh, "the same profile object (the game holds on to it)")
	assert_eq(fresh.survivor_gold, 900, "from the wallet")
	assert_eq(fresh.universe_unlocked, 2)
	assert_true(fresh.cosmetics.has("hat.party"))
	assert_eq(fresh.settings.graphics, "low", "this phone's own setting")
	assert_true(saves.has("dev-a"), "the restored profile is saved on the phone")


func test_changes_upload_after_a_quiet_moment() -> void:
	server.make_account("dev-a", "Pip")
	var s := _service("dev-a", _profile("Pip", 1, now))
	await s.sign_in()
	var sync := s.profile_sync
	var id: String = s.backend.user_id()
	var before := sync.uploads
	s.profile.universe_unlocked = 2
	sync.mark_changed()
	sync.poll()
	await wait_process_frames(1)
	assert_eq(sync.uploads, before, "not at once")
	msec += ProfileBackup.QUIET_MSEC - 1
	sync.mark_changed()
	s.profile.universe_unlocked = 3
	msec += ProfileBackup.QUIET_MSEC - 1
	sync.poll()
	await wait_process_frames(1)
	assert_eq(sync.uploads, before, "still changing")
	msec += 1
	sync.poll()
	await wait_process_frames(2)
	assert_eq(sync.uploads, before + 1, "one upload for both changes")
	assert_eq(_backup(id).universe_unlocked, 3)
	assert_false(sync.is_dirty())


func test_a_save_with_nothing_new_uploads_nothing() -> void:
	server.make_account("dev-a", "Pip")
	var s := _service("dev-a", _profile("Pip", 1, now))
	await s.sign_in()
	var before := s.profile_sync.uploads
	var writes: int = server.calls.count("write_storage")
	s.profile.updated_at += 60   # an autosave: only the time changed
	s.profile.survivor_gold += 40   # owner #67: and the gold, which the wallet carries, not the backup
	s.profile_sync.mark_changed()
	msec += ProfileBackup.MAX_WAIT_MSEC
	s.profile_sync.poll()
	await wait_process_frames(2)
	assert_eq(s.profile_sync.uploads, before, "no write for the same profile")
	assert_eq(server.calls.count("write_storage"), writes)
	assert_false(s.profile_sync.is_dirty())


func test_quitting_uploads_at_once() -> void:
	server.make_account("dev-a", "Pip")
	var s := _service("dev-a", _profile("Pip", 1, now))
	await s.sign_in()
	var id: String = s.backend.user_id()
	s.profile.universe_unlocked = 4
	s.profile_sync.mark_changed()
	s.profile_sync.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await wait_process_frames(3)
	assert_eq(_backup(id).universe_unlocked, 4)


func test_changes_while_offline_go_up_at_the_next_sign_in() -> void:
	server.make_account("dev-a", "Pip")
	var s := _service("dev-a", _profile("Pip", 1, now))
	await s.sign_in()
	var id: String = s.backend.user_id()
	(s.backend as OnlineBackend).call("drop")
	s.profile.universe_unlocked = 2
	s.profile.updated_at = now + 10
	s.profile_sync.mark_changed()
	msec += ProfileBackup.MAX_WAIT_MSEC
	s.profile_sync.poll()
	await wait_process_frames(1)
	assert_eq(_backup(id).universe_unlocked, 1, "no upload while offline")
	assert_eq(await s.sign_in(), "")
	assert_eq(_backup(id).universe_unlocked, 2)


func test_a_failed_upload_is_tried_again() -> void:
	server.make_account("dev-a", "Pip")
	var s := _service("dev-a", _profile("Pip", 1, now))
	await s.sign_in()
	var id: String = s.backend.user_id()
	server.fail_next["write_storage"] = "network"
	s.profile.universe_unlocked = 2
	s.profile_sync.mark_changed()
	msec += ProfileBackup.QUIET_MSEC
	s.profile_sync.poll()
	await wait_process_frames(2)
	assert_eq(s.profile_sync.last_error, "network")
	assert_true(s.profile_sync.is_dirty())
	msec += ProfileBackup.QUIET_MSEC
	s.profile_sync.poll()
	await wait_process_frames(2)
	assert_eq(_backup(id).universe_unlocked, 2)


func test_codes_used_offline_are_recorded_on_the_server_at_sign_in() -> void:
	var id: String = server.make_account("dev-a", "Pip")
	var p := _profile("Pip", 1, now)
	p.survivor_gold = 1025
	p.codes_redeemed.append(FIRST_CODE_HASH)   # redeemed offline (CodeRules on the phone)
	var s := _service("dev-a", p)
	assert_eq(await s.sign_in(), "")
	assert_eq(server.server_codes.get(id, []), [FIRST_CODE_HASH], "recorded")
	assert_eq(int(server.wallets.get(id, 0)), 1025, "the phone's gold went up once (sign-in); the code never paid again")
	var r: Dictionary = await s.redeem_code("SASA192974", CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ALREADY_USED)
	assert_eq(s.profile.survivor_gold, 1025)


# --- Owner #67: the account on every device ---

func test_the_backup_never_carries_the_gold() -> void:
	var id: String = server.make_account("dev-a", "Pip")
	var p := _profile("Pip", 2, now)
	p.survivor_gold = 5000
	var s := _service("dev-a", p)
	assert_eq(await s.sign_in(), "")
	assert_false(_backup_dict(id).has("survivor_gold"), "the wallet ledger keeps it (%s)" % server.backup_of(id))
	assert_eq(int(_backup_dict(id).backup), ProfileBackup.BACKUP_VERSION)


func test_two_devices_of_one_account_never_write_over_each_other() -> void:
	var id: String = server.make_account("phone", "Pip")
	server.link_device(id, "tablet")
	var phone := _service("phone", _profile("Pip", 2, now))
	var tablet := _service("tablet", _profile("Pip", 2, now))
	assert_eq(await phone.sign_in(), "")
	assert_eq(await tablet.sign_in(), "")
	# The phone finds a treasure; the tablet (which read the server before that) changes the music.
	phone.profile.record_secret(&"treasure")
	now += 10
	phone.profile.updated_at = now
	assert_eq(await phone.profile_sync.upload(), "")
	tablet.profile.settings.music_volume = 0.1
	now += 10
	tablet.profile.updated_at = now
	tablet.profile.stamps.settings = now
	var restored: Array = []
	tablet.profile_sync.restored.connect(func() -> void: restored.append(true))
	assert_eq(await tablet.profile_sync.upload(), "", "the version check failed once: read, merged, written again")
	var kept := _backup(id)
	assert_eq(int(kept.secret_book.get("treasure", 0)), 1, "the phone's treasure")
	assert_almost_eq(float(kept.settings.music_volume), 0.1, 0.001, "the tablet's music")
	assert_eq(int(tablet.profile.secret_book.get("treasure", 0)), 1, "the tablet has the treasure now too")
	assert_eq(restored, [true])


func test_a_claimed_accounts_profile_has_the_accounts_name() -> void:
	var id: String = server.make_account("dev-a", "Pip_7")
	var fresh := _profile("Hopper", 1, now)   # a reinstall: the first-launch screen gave another name
	var s := _service("dev-a", fresh)
	assert_eq(await s.sign_in(), "")
	assert_eq(fresh.username, "Pip_7")
	assert_true(s.claimed())
	assert_eq(_backup(id).username, "Pip_7")


func test_leaving_a_world_uploads_what_changed_there() -> void:
	server.make_account("dev-a", "Pip")
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-a"
	s.profile = _profile("Pip", 1, now)
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "dev-a.json"
	s.wallet_path = DIR + "wallet_dev-a.json"
	s.clock = func() -> int: return now
	Session.use_online_service(s)
	assert_eq(await s.sign_in(), "")
	var id: String = s.backend.user_id()
	s.profile.universe_unlocked = 2   # the Golem fell in a world just now
	s.profile_sync.mark_changed()
	Session.online_autostart()   # the menu opens (menu.gd _ready)
	await wait_process_frames(3)
	assert_eq(_backup(id).universe_unlocked, 2, "at once, not after the quiet moment")
	Session.use_online_service(null)


func test_a_refused_backup_is_not_tried_again_until_it_changes() -> void:
	server.make_account("dev-a", "Pip")
	var s := _service("dev-a", _profile("Pip", 1, now))
	await s.sign_in()
	server.fail_next["write_storage"] = "bad_profile"
	s.profile.universe_unlocked = 2
	s.profile_sync.mark_changed()
	msec += ProfileBackup.QUIET_MSEC
	s.profile_sync.poll()
	await wait_process_frames(2)
	assert_eq(s.profile_sync.last_error, "bad_profile")
	assert_false(s.profile_sync.is_dirty(), "the same profile would be refused again")
