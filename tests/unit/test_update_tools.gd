extends GutTest
## Owner #123: the deploy's side of the Android apps' updates (tools/android_update.py, tools/export_android_update.sh,
## tools/deploy_android_update.sh), checked with the game's side: the manifest the Python tool signs (openssl) opens in
## UpdateRules; the check refuses a patch for a change only a new APK/AAB carries; the scripts' dry runs change nothing;
## the deploy into a local folder gives what the updater's flow downloads. All with a key made here (never the real one)
## and temporary folders; never the server.

const Flow := preload("res://core/platform/update_flow.gd")
const Fetch := preload("res://core/platform/update_fetch.gd")
const Rules := preload("res://core/platform/update_rules.gd")
const UpdateRulesTest := preload("res://tests/unit/test_update_rules.gd")
const BASE_COMMIT := "aaaa1111"
const GAME_COMMIT := "bbbb2222"
const ENGINE := "4.7.2.stable"
const PATCH := "phone-aaaa1111-bbbb2222.pck"

static var _key: CryptoKey
static var _made := 0
var _dir := ""      # absolute
var _priv := ""
var _pub := ""


func before_all() -> void:
	if _key == null:
		_key = Crypto.new().generate_rsa(2048)


func before_each() -> void:
	_made += 1
	_dir = ProjectSettings.globalize_path("user://update_tools_test_%d_%d" % [OS.get_process_id(), _made])
	DirAccess.make_dir_recursive_absolute(_dir.path_join("out/phone"))
	DirAccess.make_dir_recursive_absolute(_dir.path_join("bases"))
	_priv = _dir.path_join("test-signing.pem")
	_pub = _dir.path_join("test-public.pem")
	_write(_priv, _key.save_to_string(false))
	_write(_pub, _key.save_to_string(true))


func after_each() -> void:
	OS.execute("rm", ["-rf", _dir])


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## A pack with a build's identity (data/build_info.json), its settings (project.binary) and any other files.
func _build_pack(path: String, commit: String, settings: Dictionary, files: Dictionary = {}) -> void:
	var p := PCKPacker.new()
	assert_eq(p.pck_start(path), OK)
	p.add_file_from_buffer("res://data/build_info.json", JSON.stringify({"commit": commit,
		"date": "2026-10-18T10:00:00+04:00", "net": "abcdef123456"}).to_utf8_buffer())
	p.add_file_from_buffer("res://project.binary", UpdateRulesTest.project_binary(settings))
	for f: String in files:
		p.add_file_from_buffer(f, (files[f] as String).to_utf8_buffer())
	assert_eq(p.flush(), OK)


func _tool(args: Array) -> Dictionary:
	var out := []
	var code := OS.execute("/usr/bin/python3", ["-B", ProjectSettings.globalize_path("res://tools/android_update.py")]
		+ args, out, true)
	return {"code": code, "out": "\n".join(out)}


func _sh(env: Array, script: String, args: Array) -> Dictionary:
	var out := []
	var code := OS.execute("env", env + ["bash", ProjectSettings.globalize_path("res://tools/" + script)] + args, out,
		true)
	return {"code": code, "out": "\n".join(out)}


## A kept base (as `android_update.py base` keeps it), the newest game's pack and a patch for that base.
func _deploy_folder() -> void:
	var base_pack := _dir.path_join("base.pck")
	_build_pack(base_pack, BASE_COMMIT, {"application/config/version": "1.0.6"})
	var kept := _tool(["base", "phone", base_pack, "--bases", _dir.path_join("bases"), "--engine", ENGINE, "--code", "16"])
	assert_eq(kept.code, 0, kept.out)
	_build_pack(_dir.path_join("out/phone/game.pck"), GAME_COMMIT, {"application/config/version": "1.0.7"})
	_build_pack(_dir.path_join("out/phone").path_join(PATCH), GAME_COMMIT, {"application/config/version": "1.0.7"},
		{"res://tests/_update_tools_probe.txt": "the newer game"})


func _manifest() -> Dictionary:
	return _tool(["manifest", "phone", _dir.path_join("out/phone/game.pck"), _dir.path_join("out/phone"), "--bases",
		_dir.path_join("bases"), "--key", _priv, "--public", _pub, "--engine", ENGINE, "--serial", "1234"])


func test_a_kept_base_knows_its_build_from_its_own_files() -> void:
	_deploy_folder()
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		_dir.path_join("bases/phone/%s/base.json" % BASE_COMMIT)))
	assert_eq([meta.commit, meta.version, meta.engine, int(meta.code), meta.file],
		[BASE_COMMIT, "1.0.6", ENGINE, 16, "base.pck"])
	var listed := _tool(["bases", "phone", "--bases", _dir.path_join("bases")])
	assert_string_contains(listed.out, BASE_COMMIT + "\t1.0.6\t" + ENGINE)


func test_the_manifest_the_tool_signs_opens_in_the_game() -> void:
	_deploy_folder()
	var made := _manifest()
	assert_eq(made.code, 0, made.out)
	var opened: Dictionary = Rules.open_envelope(FileAccess.get_file_as_string(_dir.path_join("out/phone/update.json")),
		{"k1": _key.save_to_string(true)})
	assert_true(opened.ok, str(opened))
	var m: Dictionary = opened.manifest
	assert_eq([m.kind, int(m.serial), m.engine, m.game.commit, m.game.version, m.min_base],
		["phone", 1234, ENGINE, GAME_COMMIT, "1.0.7", "1.0.6"])
	assert_eq(m.bases[BASE_COMMIT].file, PATCH)
	assert_eq(m.bases[BASE_COMMIT].sha256, Flow.sha256_of(_dir.path_join("out/phone").path_join(PATCH)))
	assert_false(Rules.open_envelope(FileAccess.get_file_as_string(_dir.path_join("out/phone/update.json"))).ok,
		"signed with a test key: the game's own key refuses it")


func test_the_tool_refuses_a_key_the_game_does_not_hold() -> void:
	_deploy_folder()
	var made := _tool(["manifest", "phone", _dir.path_join("out/phone/game.pck"), _dir.path_join("out/phone"),
		"--bases", _dir.path_join("bases"), "--key", _priv, "--engine", ENGINE])
	assert_ne(made.code, 0, "the game's public key is not this key's")
	assert_string_contains(made.out, "does not verify")
	assert_false(FileAccess.file_exists(_dir.path_join("out/phone/update.json")))


func test_the_check_refuses_what_only_a_new_apk_carries() -> void:
	var base := _dir.path_join("b.pck")
	var jump := {"deadzone": 0.5, "events": []}
	_build_pack(base, BASE_COMMIT, {"application/config/version": "1.0.6", "autoload/Game": "*res://a.gd",
		"input/jump": jump})
	var fine := _dir.path_join("fine.pck")
	_build_pack(fine, GAME_COMMIT, {"application/config/version": "1.0.7", "autoload/Game": "*res://a.gd",
		"input/jump": {"deadzone": 0.2, "events": []}, "input/rocket": jump, "threads/count/ratio.web": 0.5,
		"openxr/enabled.quest": true})
	var patch := _dir.path_join("patch.pck")
	_build_pack(patch, GAME_COMMIT, {}, {"res://x.gdc": "x"})
	var ok := _tool(["check", "phone", base, fine, patch])
	assert_eq(ok.code, 0, "the version, the input map and other platforms' settings: a patch carries them\n" + ok.out)
	var autoload := _dir.path_join("autoload.pck")
	_build_pack(autoload, GAME_COMMIT, {"application/config/version": "1.0.7", "autoload/Game": "*res://a.gd",
		"autoload/Vr": "*res://vr.gd", "input/jump": jump})
	var refused := _tool(["check", "phone", base, autoload, patch])
	assert_eq(refused.code, 3)
	assert_string_contains(refused.out, "NEEDS A NEW APK/AAB: project setting autoload/Vr added")
	assert_eq(_tool(["check", "quest", base, fine, patch]).code, 3, "the Quest reads its .quest settings at start")
	var native := _dir.path_join("native.pck")
	_build_pack(native, GAME_COMMIT, {}, {"res://addons/zylann.voxel/bin/libvoxel.android.so": "elf"})
	assert_eq(_tool(["check", "phone", base, fine, native]).code, 3, "native code never comes as a patch")
	var updater := _dir.path_join("updater.pck")
	_build_pack(updater, GAME_COMMIT, {}, {"res://autoloads/updater.gdc": "x"})
	var warned := _tool(["check", "phone", base, fine, updater])
	assert_eq(warned.code, 0)
	assert_string_contains(warned.out, "WARNING the updater's own autoloads/updater.gdc changed")


func test_the_export_scripts_dry_run_changes_nothing() -> void:
	_deploy_folder()
	var out_dir := _dir.path_join("dry_out")
	var r := _sh(["EASYCRAFT_UPDATE_OUT=" + out_dir, "EASYCRAFT_UPDATE_BASES=" + _dir.path_join("bases"),
		"EASYCRAFT_UPDATE_KEY=" + _priv], "export_android_update.sh", ["--kind", "phone", "--dry-run"])
	assert_eq(r.code, 0, r.out)
	assert_string_contains(r.out, "DRY RUN")
	assert_string_contains(r.out, "would run: nice godot --headless --path . --export-pack Android Phone")
	assert_string_contains(r.out, "base %s (v1.0.6) -> phone-%s-" % [BASE_COMMIT, BASE_COMMIT])
	assert_string_contains(r.out, "--export-patch Android Phone")
	assert_string_contains(r.out, "would run: /usr/bin/python3 -B")
	assert_false(DirAccess.dir_exists_absolute(out_dir), "nothing written")
	var b := _sh(["EASYCRAFT_UPDATE_OUT=" + out_dir, "EASYCRAFT_UPDATE_BASES=" + _dir.path_join("bases")],
		"export_android_update.sh", ["base", "quest", "--dry-run"])
	assert_eq(b.code, 0, b.out)
	assert_string_contains(b.out, "--export-pack Quest")
	assert_false(DirAccess.dir_exists_absolute(out_dir))


func test_the_deploy_into_a_local_folder_gives_what_the_updater_downloads() -> void:
	_deploy_folder()
	assert_eq(_manifest().code, 0)
	var env := ["EASYCRAFT_UPDATE_OUT=" + _dir.path_join("out"), "EASYCRAFT_UPDATE_PUBLIC=" + _pub]
	var dry := _sh(env, "deploy_android_update.sh", ["--dry-run", "--to", _dir.path_join("play")])
	assert_eq(dry.code, 0, dry.out)
	assert_string_contains(dry.out, "VERIFY")
	assert_string_contains(dry.out, "would put android")
	assert_false(DirAccess.dir_exists_absolute(_dir.path_join("play")), "a dry run puts nothing anywhere")
	var put := _sh(env, "deploy_android_update.sh", ["--to", _dir.path_join("play")])
	assert_eq(put.code, 0, put.out)
	var landed := Array(DirAccess.get_files_at(_dir.path_join("play/android")))
	landed.sort()
	assert_eq(landed, [PATCH, PATCH + ".gz", "update.json"], "the patch, its gzip and the manifest; never game.pck")
	var fetch: Node = Fetch.new()
	fetch.source = _dir.path_join("play")
	add_child_autofree(fetch)
	var app := _dir.path_join("app")
	var base := {"kind": "phone", "commit": BASE_COMMIT, "version": "1.0.6", "engine": ENGINE}
	var r: Dictionary = await Flow.check(fetch, base, {"base": base}, app, false, {"k1": _key.save_to_string(true)})
	assert_eq(r.status, "ready", str(r))
	assert_true(FileAccess.file_exists(app.path_join(PATCH)))
