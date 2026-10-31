extends GutTest
## Owner #67 (spec §5.13, §17.1): the account on every device. A grown-up makes a sign-in key on a device where
## the child plays; on a new phone or a browser whose storage was wiped, the child's name and that key sign the
## device in to the same account (the server links a new device id of this device to it), and everything the
## account keeps comes back: the name, the look, progress, the Secret Book, things owned, and the gold from the
## wallet. The new device's own never-claimed account goes. Against the fake server (module 0.2.12's answers).

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_account_key_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var saves: Array[String] = []


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	saves.clear()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _service(device: String, profile: ProfileData) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.device_id_path = DIR + device + "_device_id.json"
	s.profile = profile
	s.save_profile = func() -> void: saves.append(device)
	s.prefs_path = DIR + device + ".json"
	s.wallet_path = DIR + "wallet_" + device + ".json"
	s.clock = func() -> int: return now
	s.prefs.safe_card_seen = now
	add_child_autofree(s)
	return s


func _profile(username: String, band: StringName = AgeBand.UNDER_13) -> ProfileData:
	var p := ProfileData.new()
	p.username = username
	p.age_band = band
	p.updated_at = now
	return p


## The child's account as a grown-up left it on the phone: played, backed up, gold on the server, a key made.
func _childs_phone() -> OnlineService:
	server.make_account("phone-1", "Sasa_7", AgeBand.UNDER_13, OnlineRules.CONSENT_VERIFIED)
	var played := _profile("Sasa_7")
	played.universe_unlocked = 3
	played.cosmetics.append("hat.party")
	played.avatar.hat = &"party"
	played.record_secret(&"treasure")
	played.settings.simple_controls = true
	played.stamps = {"look": now, "settings": now}
	var phone := _service("phone-1", played)
	assert_eq(await phone.sign_in(), "")
	server.wallets[phone.backend.user_id()] = 100_915
	return phone


func test_a_grown_up_makes_a_key_on_the_childs_device() -> void:
	var phone := await _childs_phone()
	var before: Dictionary = await phone.account_key_state()
	assert_eq(before.text, "")
	assert_false(before.has_key)
	var made: Dictionary = await phone.make_account_key()
	assert_eq(made.text, "")
	assert_eq(made.username, "Sasa_7")
	assert_true(RegEx.create_from_string("^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$").search(made.key) != null, made.key)
	var after: Dictionary = await phone.account_key_state()
	assert_true(after.has_key)
	assert_eq(int(after.devices), 1)


func test_a_new_device_signs_in_with_the_name_and_key_and_the_account_feels_loaded() -> void:
	var phone := await _childs_phone()
	var child_id: String = phone.backend.user_id()
	var key: String = (await phone.make_account_key()).key
	var fresh := _profile("Hopper")   # a new browser: the first-launch screen, nothing played
	var browser := _service("browser-1", fresh)
	assert_eq(await browser.sign_in(), "")
	var own_id: String = browser.backend.user_id()
	assert_false(browser.claimed())
	var restored: Array = []
	browser.profile_sync.restored.connect(func() -> void: restored.append(true))
	assert_eq(await browser.sign_in_with_key("sasa_7", key.to_lower()), "")
	assert_eq(browser.status, OnlineService.ONLINE)
	assert_eq(browser.backend.user_id(), child_id, "the same account")
	assert_true(browser.claimed())
	assert_eq(fresh.username, "Sasa_7")
	assert_eq(fresh.universe_unlocked, 3)
	assert_true(fresh.cosmetics.has("hat.party"))
	assert_eq(fresh.avatar.hat, &"party", "the look")
	assert_eq(int(fresh.secret_book.get("treasure", 0)), 1)
	assert_true(fresh.settings.simple_controls, "the child's own settings")
	assert_eq(fresh.survivor_gold, 100_915, "the wallet's gold")
	assert_eq(restored, [true])
	assert_ne(browser.device_id, "browser-1", "this device signs in with its new, linked id now")
	assert_eq(server.linked.get(browser.device_id, ""), child_id)
	assert_true(server.accounts.has(own_id), "its own empty account stays on the server (the 13-month clean-up removes it)")


func test_the_new_id_is_kept_in_this_devices_file() -> void:
	var phone := await _childs_phone()
	var child_id: String = phone.backend.user_id()   # before the key LOG IN logs the phone out (one device at a time)
	var key: String = (await phone.make_account_key()).key
	var browser := _service("browser-2", _profile("Hopper"))
	browser.device_id = ""   # this install's own id, from its file
	var old_id := DeviceId.load_or_create(browser.device_id_path)
	assert_eq(await browser.sign_in(), "")
	assert_eq(await browser.sign_in_with_key("Sasa_7", key), "")
	var kept := DeviceId.load_or_create(browser.device_id_path)
	assert_ne(kept, old_id)
	assert_eq(server.linked.get(kept, ""), child_id)
	browser.sign_out()
	assert_eq(await browser.sign_in(), "")
	assert_eq(browser.backend.user_id(), child_id, "and the next start signs in to the account")


func test_a_wrong_key_says_so_and_changes_nothing() -> void:
	var phone := await _childs_phone()
	await phone.make_account_key()
	var browser := _service("browser-3", _profile("Hopper"))
	assert_eq(await browser.sign_in(), "")
	var own_id: String = browser.backend.user_id()
	assert_eq(await browser.sign_in_with_key("Sasa_7", "0000-0000"), OnlineRules.message("wrong_key"))
	assert_eq(await browser.sign_in_with_key("Nobody_1", "0000-0000"), OnlineRules.message("wrong_key"), "no hint who plays")
	assert_eq(browser.device_id, "browser-3")
	assert_eq(browser.backend.user_id(), own_id)
	assert_eq(browser.profile.username, "Hopper")


func test_too_many_wrong_keys_lock_for_a_while() -> void:
	var phone := await _childs_phone()
	var key: String = (await phone.make_account_key()).key
	var browser := _service("browser-4", _profile("Hopper"))
	assert_eq(await browser.sign_in(), "")
	for i in 10:   # counted per asking account (this device's own), never per name (the final review)
		await browser.sign_in_with_key("Sasa_7", "0000-0000")
	var said: String = await browser.sign_in_with_key("Sasa_7", key)
	assert_eq(said, OnlineRules.key_locked_message(3600))


func test_a_device_with_its_own_name_logs_in_as_the_keys_account_and_its_own_stays_on_the_server() -> void:
	# The final review's simple model: one player on a device. A key LOG IN makes this device the key's account (a fresh
	# player first, so nothing of Bro's merges into Sasa's); Bro's own account stays safe on the server.
	var phone := await _childs_phone()
	var key: String = (await phone.make_account_key()).key
	var bro_id: String = server.make_account("tablet-1", "Bro_9", AgeBand.TEEN_PLUS)
	var tablet := _service("tablet-1", _profile("Bro_9", AgeBand.TEEN_PLUS))
	assert_eq(await tablet.sign_in(), "")
	assert_eq(await tablet.sign_in_with_key("Sasa_7", key), "")
	assert_eq(tablet.profile.username, "Sasa_7")
	assert_true(server.accounts.has(bro_id), "Bro's account is safe on the server: LOG IN brings it back")


func test_sign_out_other_devices_leaves_only_this_one() -> void:
	var phone := await _childs_phone()
	var child_id: String = phone.backend.user_id()
	var key: String = (await phone.make_account_key()).key
	var browser := _service("browser-5", _profile("Hopper"))
	assert_eq(await browser.sign_in(), "")
	assert_eq(await browser.sign_in_with_key("Sasa_7", key), "")
	# The phone is lost: a grown-up signs it out from the browser.
	assert_eq(await browser.sign_out_other_devices(), "")
	assert_eq(browser.status, OnlineService.ONLINE, "this device signed in again")
	assert_eq(browser.backend.user_id(), child_id)
	assert_eq(int((await browser.account_key_state()).devices), 1)
	phone.sign_out()
	phone._set_status(OnlineService.OFFLINE)
	var accounts: int = server.accounts.size()
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT, "the lost phone can't reach the child's account any more")
	assert_eq(server.accounts.size(), accounts, "and it makes no new account for itself")


func test_no_key_or_device_changes_while_offline() -> void:
	var s := _service("dev-x", _profile("Hopper"))
	server.down = true
	assert_eq((await s.make_account_key()).text, OnlineRules.message("not_signed_in"))
	assert_ne(await s.sign_in_with_key("Sasa_7", "0000-0000"), "")
	assert_eq(s.device_id, "dev-x")
