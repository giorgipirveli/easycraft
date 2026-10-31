extends GutTest
## Owner #123 (2026-10-17): "make windows and phone use same version always … i mean game version but of course mobile
## should be mobile". An installed Android app (the phone's, the Quest's) takes the newest game from our server as a
## patch pack for its own build (docs/devlog/parts/same-version.md): these are the pure rules
## (core/platform/update_rules.gd) — the signed manifest, what to download for this base, the Wi-Fi rule, the start
## (a verified pack, two tries, the fall-back), and the version and input map a pack brings in its project.binary.

const R := preload("res://core/platform/update_rules.gd")
const BASE := {"kind": "phone", "commit": "aaaa1111", "version": "1.0.6", "engine": "4.7.2.stable"}
const FILE := "phone-aaaa1111-bbbb2222.pck"

var _key: CryptoKey
var _keys := {}


func before_all() -> void:
	_key = Crypto.new().generate_rsa(2048)
	_keys = {"t1": _key.save_to_string(true)}


func _manifest(over: Dictionary = {}) -> Dictionary:
	var m := {"format": 1, "kind": "phone", "serial": 1000, "engine": "4.7.2.stable",
		"game": {"commit": "bbbb2222", "date": "2026-10-18T10:00:00+04:00", "version": "1.0.7", "net": "abcdef123456"},
		"min_base": "1.0.6",
		"bases": {"aaaa1111": {"file": FILE, "size": 4000000, "sha256": "ab".repeat(32)}}}
	m.merge(over, true)
	return m


func _envelope(m: Variant, key_id: String = "t1", key: CryptoKey = null) -> String:
	var signed := JSON.stringify(m)
	var sig := Crypto.new().sign(HashingContext.HASH_SHA256, signed.sha256_buffer(), key if key != null else _key)
	return JSON.stringify({"key": key_id, "signed": signed, "signature": Marshalls.raw_to_base64(sig)})


## A project.binary as the engine writes it: "ECFG", the count, then each key and its encode_variant (with objects).
static func project_binary(settings: Dictionary) -> PackedByteArray:
	var out := "ECFG".to_ascii_buffer()
	var n := PackedByteArray()
	n.resize(4)
	n.encode_u32(0, settings.size())
	out.append_array(n)
	for k: String in settings:
		var kb := k.to_utf8_buffer()
		var vb := var_to_bytes_with_objects(settings[k])
		n.encode_u32(0, kb.size())
		out.append_array(n)
		out.append_array(kb)
		n.encode_u32(0, vb.size())
		out.append_array(n)
		out.append_array(vb)
	return out


static func _key_event(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


# --- the signed manifest ------------------------------------------------------------------------------------------------

func test_a_signed_manifest_opens() -> void:
	var got: Dictionary = R.open_envelope(_envelope(_manifest()), _keys)
	assert_true(got.ok, str(got))
	assert_eq(got.manifest.game.commit, "bbbb2222")
	assert_eq(int(got.manifest.bases.aaaa1111.size), 4000000)


func test_a_changed_byte_another_key_or_no_signature_is_refused() -> void:
	var env: Dictionary = JSON.parse_string(_envelope(_manifest()))
	var tampered := env.duplicate()
	tampered.signed = str(env.signed).replace("bbbb2222", "cccc3333")
	assert_false(R.open_envelope(JSON.stringify(tampered), _keys).ok, "one changed commit")
	assert_false(R.open_envelope(_envelope(_manifest(), "t2"), _keys).ok, "a key the game does not have")
	var other := Crypto.new().generate_rsa(1024)
	assert_false(R.open_envelope(_envelope(_manifest(), "t1", other), _keys).ok, "signed by another key")
	var unsigned := env.duplicate()
	unsigned.erase("signature")
	assert_false(R.open_envelope(JSON.stringify(unsigned), _keys).ok, "no signature")
	var garbled := env.duplicate()
	garbled.signature = "not base64 at all!"
	assert_false(R.open_envelope(JSON.stringify(garbled), _keys).ok)
	assert_false(R.open_envelope("<html>not found</html>", _keys).ok, "a web page in its place")
	assert_false(R.open_envelope("", _keys).ok)


func test_the_game_holds_only_public_keys() -> void:
	assert_false(R.PUBLIC_KEYS.is_empty())
	for id: String in R.PUBLIC_KEYS:
		var k := CryptoKey.new()
		assert_eq(k.load_from_string(R.PUBLIC_KEYS[id], true), OK, "key %s is a public key" % id)
		assert_false(str(R.PUBLIC_KEYS[id]).contains("PRIVATE"))
	assert_false(FileAccess.get_file_as_string("res://core/platform/update_rules.gd").contains("PRIVATE KEY-----"))


func test_a_manifest_must_be_whole() -> void:
	assert_eq(R.check_manifest(_manifest()), "")
	assert_ne(R.check_manifest([]), "")
	assert_ne(R.check_manifest(_manifest({"format": 2})), "", "a newer format this app cannot read")
	assert_ne(R.check_manifest(_manifest({"kind": "tv"})), "")
	assert_ne(R.check_manifest(_manifest({"serial": 0})), "")
	assert_ne(R.check_manifest(_manifest({"engine": ""})), "")
	assert_ne(R.check_manifest(_manifest({"game": {"commit": "zz", "version": "1.0.7"}})), "")
	assert_ne(R.check_manifest(_manifest({"min_base": 3})), "")
	for bad_file: String in ["../x.pck", "a/b.pck", "x.so", "x.pck.gz", "", "https://evil.example/x.pck"]:
		var m := _manifest()
		m.bases.aaaa1111.file = bad_file
		assert_ne(R.check_manifest(m), "", "file %s" % bad_file)
	for bad_size: Variant in [0, -5, R.MAX_BYTES + 1, "big"]:
		var m := _manifest()
		m.bases.aaaa1111.size = bad_size
		assert_ne(R.check_manifest(m), "", "size %s" % [bad_size])
	var m2 := _manifest()
	m2.bases.aaaa1111.sha256 = "ab"
	assert_ne(R.check_manifest(m2), "")
	var m3 := _manifest()
	m3.bases = {"not-hex!": m3.bases.aaaa1111}
	assert_ne(R.check_manifest(m3), "")


# --- where files come from ------------------------------------------------------------------------------------------------

func test_files_come_only_from_our_server_over_https() -> void:
	assert_eq(R.manifest_url("phone"), "https://178-104-20-64.sslip.io/play/android/update.json")
	assert_eq(R.manifest_url("quest"), "https://178-104-20-64.sslip.io/play/quest/update.json")
	assert_eq(R.file_url("phone", FILE), "https://178-104-20-64.sslip.io/play/android/" + FILE)
	assert_eq(R.file_url("phone", "../x.pck"), "")
	assert_eq(R.file_url("tv", FILE), "")
	assert_true(R.is_our_url(R.file_url("quest", FILE)))
	assert_false(R.is_our_url("http://178-104-20-64.sslip.io/play/android/" + FILE), "never plain HTTP")
	assert_false(R.is_our_url("https://evil.example/play/android/" + FILE))
	assert_false(R.is_our_url("https://178-104-20-64.sslip.io.evil.example/play/android/" + FILE))
	assert_false(R.is_our_url("https://178-104-20-64.sslip.io/privacy"), "only the update folders")


func test_this_app_names_its_engine_and_kind() -> void:
	assert_eq(R.engine_id({"major": 4, "minor": 7, "patch": 2, "status": "stable"}), "4.7.2.stable")
	assert_eq(R.kind_of(false), "phone")
	assert_eq(R.kind_of(true), "quest")


func test_versions_compare_as_numbers() -> void:
	assert_true(R.version_less("1.0.9", "1.0.10"))
	assert_true(R.version_less("1.0.6", "1.1"))
	assert_false(R.version_less("1.0.6", "1.0.6"))
	assert_false(R.version_less("1.1", "1.0.9"))
	assert_false(R.version_less("2.0", "1.9.9"))


# --- what the background check downloads ---------------------------------------------------------------------------------

func test_the_check_downloads_the_patch_for_this_apps_own_build() -> void:
	var plan: Dictionary = R.plan_download(_manifest(), BASE, {}, false)
	assert_eq(plan.do, "download", str(plan))
	assert_eq(plan.entry.file, FILE)
	assert_eq(plan.game.commit, "bbbb2222")


func test_the_check_does_nothing_when_there_is_nothing_new_or_nothing_for_this_app() -> void:
	var m := _manifest()
	assert_eq(R.plan_download(m, BASE, {"active": {"commit": "bbbb2222"}}, false).why, R.UP_TO_DATE, "playing it already")
	var same_base := BASE.duplicate()
	same_base.commit = "bbbb2222"
	assert_eq(R.plan_download(m, same_base, {}, false).why, R.UP_TO_DATE, "this app was built from that game")
	assert_eq(R.plan_download(m, BASE, {"ready": {"commit": "bbbb2222"}}, false).why, R.ALREADY_READY)
	assert_eq(R.plan_download(m, BASE, {"bad": ["bbbb2222"]}, false).why, R.FAILED_HERE, "it failed to start here")
	var old := BASE.duplicate()
	old.version = "1.0.5"
	assert_eq(R.plan_download(m, old, {}, false).why, R.TOO_OLD, "the store has a newer app")
	var dev := BASE.duplicate()
	dev.commit = "dddd4444"
	assert_eq(R.plan_download(m, dev, {}, false).why, R.NO_PATCH, "a build the deploy does not know")
	var other_engine := BASE.duplicate()
	other_engine.engine = "4.8.0.stable"
	assert_eq(R.plan_download(m, other_engine, {}, false).why, R.OTHER_ENGINE)
	var quest := BASE.duplicate()
	quest.kind = "quest"
	assert_eq(R.plan_download(m, quest, {}, false).why, R.OTHER_APP, "the phone's game never goes to the Quest")
	assert_eq(R.plan_download(m, BASE, {"serial": 2000}, false).why, R.OLDER_MANIFEST, "an old manifest sent again")


func test_a_big_patch_waits_for_wifi_a_small_one_never_waits() -> void:
	assert_true(R.may_download(R.SMALL_BYTES, true, false), "small: any network")
	assert_false(R.may_download(R.SMALL_BYTES + 1, true, false), "big on mobile data: waits")
	assert_true(R.may_download(R.SMALL_BYTES + 1, false, false), "big on Wi-Fi")
	assert_true(R.may_download(R.SMALL_BYTES + 1, true, true), "the grown-ups allowed big updates on mobile data")
	var m := _manifest()
	m.bases.aaaa1111.size = R.SMALL_BYTES + 1
	assert_eq(R.plan_download(m, BASE, {}, true).why, R.WAITS_FOR_WIFI)
	assert_eq(R.plan_download(m, BASE, {}, false).do, "download")
	assert_eq(R.plan_download(m, BASE, {"big_on_mobile": true}, true).do, "download")


func test_a_verified_download_waits_for_the_next_start() -> void:
	var plan: Dictionary = R.plan_download(_manifest(), BASE, {}, false)
	var kept: Dictionary = R.keep_ready({"base": BASE, "ready": {"commit": "cccc0000", "file": "old.pck"}}, plan)
	assert_eq(kept.state.ready.commit, "bbbb2222")
	assert_eq(kept.state.ready.file, FILE)
	assert_eq(kept.state.ready.sha256, "ab".repeat(32))
	assert_eq(int(kept.state.ready.size), 4000000)
	assert_eq(kept.state.ready.version, "1.0.7")
	assert_eq(kept.drop, ["old.pck"], "the older waiting pack goes")


# --- the start ------------------------------------------------------------------------------------------------------------

func test_the_start_uses_the_pack_in_use_and_counts_the_try() -> void:
	var state := {"base": BASE, "active": {"commit": "bbbb2222", "file": FILE, "tries": 0}}
	var plan: Dictionary = R.start_plan(state, BASE)
	assert_eq(plan.load.file, FILE)
	assert_eq(int(plan.state.active.tries), 1, "counted before the pack is loaded: a crash counts")
	assert_false(plan.fell_back)
	assert_eq(plan.drop, [])
	assert_eq(int(state.active.tries), 0, "the given state is not changed")


func test_a_waiting_pack_is_used_from_the_next_start() -> void:
	var state := {"base": BASE, "active": {"commit": "bbbb2222", "file": FILE, "tries": 0},
		"ready": {"commit": "cccc3333", "file": "phone-aaaa1111-cccc3333.pck"}}
	var plan: Dictionary = R.start_plan(state, BASE)
	assert_eq(plan.load.commit, "cccc3333")
	assert_false(plan.state.has("ready"))
	assert_eq(plan.state.active.commit, "cccc3333")
	assert_eq(plan.drop, [FILE], "the pack it replaces goes")


func test_two_starts_that_never_reached_the_menu_bring_back_the_apps_own_build() -> void:
	var state := {"base": BASE, "active": {"commit": "bbbb2222", "file": FILE, "tries": R.MAX_TRIES}}
	var plan: Dictionary = R.start_plan(state, BASE)
	assert_eq(plan.load, {})
	assert_true(plan.fell_back)
	assert_false(plan.state.has("active"))
	assert_has(plan.state.bad, "bbbb2222", "never downloaded again for this app")
	assert_eq(plan.drop, [FILE])
	assert_eq(R.MAX_TRIES, 2)


func test_reaching_the_menu_clears_the_tries() -> void:
	var state := {"base": BASE, "active": {"commit": "bbbb2222", "file": FILE, "tries": 1}}
	assert_eq(int(R.menu_reached(state).active.tries), 0)
	assert_eq(R.menu_reached({"base": BASE}), {"base": BASE}, "the app's own build: nothing to clear")


func test_a_new_app_from_the_store_drops_the_packs_of_the_old_one() -> void:
	var state := {"base": BASE, "serial": 1000, "big_on_mobile": true, "bad": ["eeee5555"],
		"active": {"commit": "bbbb2222", "file": FILE, "tries": 0}, "ready": {"commit": "cccc3333", "file": "r.pck"}}
	var newer := BASE.duplicate()
	newer.commit = "ffff6666"
	newer.version = "1.0.8"
	var plan: Dictionary = R.start_plan(state, newer)
	assert_eq(plan.load, {})
	assert_eq(plan.state.base, newer)
	assert_false(plan.state.has("active") or plan.state.has("ready"))
	assert_eq(int(plan.state.serial), 1000, "an old manifest is still refused")
	assert_true(plan.state.big_on_mobile, "the grown-ups' choice stays")
	assert_false(plan.state.has("bad"), "a new app gives every game a new chance")
	assert_eq(plan.drop, [FILE, "r.pck"])


func test_dropping_the_pack_in_use() -> void:
	var state := {"base": BASE, "active": {"commit": "bbbb2222", "file": FILE, "tries": 1}}
	assert_false(R.drop_active(state, false).has("bad"), "a damaged file is not the game's fault: it comes again")
	assert_eq(R.drop_active(state, true).bad, ["bbbb2222"])
	var many := {"bad": range(30).map(func(i: int) -> String: return "%08x" % i), "active": {"commit": "bbbb2222"}}
	assert_eq(R.drop_active(many, true).bad.size(), R.KEEP_BAD, "a short list")


# --- what a pack brings in its project.binary -------------------------------------------------------------------------------

func test_a_project_binary_is_read_setting_by_setting() -> void:
	var raw: Dictionary = R.read_project_binary(project_binary({"application/config/version": "1.0.7", "a/b": 3}))
	assert_eq(raw.keys(), ["application/config/version", "a/b"])
	assert_eq(bytes_to_var(raw["a/b"]), 3)
	assert_eq(R.read_project_binary(PackedByteArray()), {})
	assert_eq(R.read_project_binary("ECFG garbage".to_ascii_buffer()), {}, "a short or broken file: nothing")


func test_the_pack_brings_its_version_and_its_input_map() -> void:
	var jump := {"deadzone": 0.5, "events": [_key_event(KEY_SPACE)]}
	var base_raw: Dictionary = R.read_project_binary(project_binary({
		"application/config/version": "1.0.6", "input/jump": jump, "input/old_action": jump,
		"input/ui_accept": jump, "rendering/x": 1}))
	var pack_raw: Dictionary = R.read_project_binary(project_binary({
		"application/config/version": "1.0.7", "input/jump": jump,
		"input/rocket_throttle": {"deadzone": 0.2, "events": [_key_event(KEY_W)]}, "rendering/x": 2}))
	var ch: Dictionary = R.project_changes(base_raw, pack_raw)
	assert_eq(ch.version, "1.0.7")
	assert_eq(ch.set.keys(), ["input/rocket_throttle"], "only what changed")
	assert_eq((ch.set["input/rocket_throttle"].events[0] as InputEventKey).physical_keycode, KEY_W)
	assert_eq(ch.erase, ["input/old_action"], "a removed action goes; a built-in ui_ action keeps its default")
	var none: Dictionary = R.project_changes(base_raw, base_raw)
	assert_eq([none.version, none.set, none.erase], ["", {}, []], "the same file: nothing to do")
	assert_eq(R.project_changes(base_raw, {}).erase, [], "a pack without project.binary changes nothing")


func test_the_menu_line_is_calm() -> void:
	assert_eq(R.READY_WORDS, "A new EasyCraft is ready: it starts next time")
