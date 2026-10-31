extends GutTest
## Owner #123: the updater's whole way, with a local folder in the server's place (UpdateFetch.source: the folder is laid
## out as the server's play/ folder, as tools/deploy_android_update.sh --to writes it) and a fake for a failing network:
## the background check reads the signed manifest, downloads the patch for this app's own build, checks its size and
## SHA-256 and keeps it; the next start loads it (a real pack, made here with PCKPacker), counts the try, and falls back
## to the app's own build after two starts that never reached the menu. A start that LOADS a pack runs in a Godot of its
## own (tests/integration/update_start_child.gd), as a phone's next start is a new process: a loaded pack stays for the
## whole process (and DirAccess then lists res://'s hidden folders too), so the suite's own run takes none of these.

const Flow := preload("res://core/platform/update_flow.gd")
const Fetch := preload("res://core/platform/update_fetch.gd")
const UPDATER := "res://autoloads/updater.gd"
const CHILD := "res://tests/integration/update_start_child.gd"
const BASE := {"kind": "phone", "commit": "aaaa1111", "version": "1.0.6", "engine": "4.7.2.stable"}
const GAME := "bbbb2222"
const FILE := "phone-aaaa1111-bbbb2222.pck"

static var _key: CryptoKey
static var _made := 0
var _keys := {}
var _root := ""
var _server := ""   # the server's play/ folder
var _app := ""      # the app's user://update
var _probe := ""


## A network that gives no manifest (offline) and stops every file halfway.
class FakeFetch:
	extends Node

	func get_text(_url: String) -> Dictionary:
		await Engine.get_main_loop().process_frame
		return {"ok": false, "why": "offline"}

	func get_file(_url: String, path: String, size: int) -> Dictionary:
		await Engine.get_main_loop().process_frame
		var f := FileAccess.open(path, FileAccess.WRITE)
		var half := PackedByteArray()
		half.resize(size / 2)
		f.store_buffer(half)
		f.close()
		return {"ok": true}

	func metered() -> bool:
		return false


func before_all() -> void:
	if _key == null:
		_key = Crypto.new().generate_rsa(2048)


func before_each() -> void:
	_keys = {"t1": _key.save_to_string(true)}
	_made += 1
	_root = "user://update_flow_test_%d_%d" % [OS.get_process_id(), _made]
	_server = _root.path_join("server")
	_app = _root.path_join("app")
	DirAccess.make_dir_recursive_absolute(_server.path_join("android"))
	DirAccess.make_dir_recursive_absolute(_app)
	_probe = "res://tests/_update_probe_%d_%d.txt" % [OS.get_process_id(), _made]


func after_each() -> void:
	_remove(_root)


func _remove(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_remove(dir.path_join(d))
	DirAccess.remove_absolute(dir)


## A real pack with one probe file saying `words`.
func _make_pack(path: String, words: String) -> void:
	var p := PCKPacker.new()
	assert_eq(p.pck_start(path), OK)
	assert_eq(p.add_file_from_buffer(_probe, words.to_utf8_buffer()), OK)
	assert_eq(p.flush(), OK)


func _publish(manifest: Dictionary, key: CryptoKey = null) -> void:
	var signed := JSON.stringify(manifest)
	var sig := Crypto.new().sign(HashingContext.HASH_SHA256, signed.sha256_buffer(), key if key != null else _key)
	var f := FileAccess.open(_server.path_join("android/update.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"key": "t1", "signed": signed, "signature": Marshalls.raw_to_base64(sig)}))
	f.close()


## The deploy's work: the patch on the "server" and its manifest. `sha` overrides the manifest's SHA-256.
func _deploy(words: String = "the newer game", sha: String = "") -> void:
	var pack := _server.path_join("android").path_join(FILE)
	_make_pack(pack, words)
	_publish({"format": 1, "kind": "phone", "serial": 1000, "engine": "4.7.2.stable",
		"game": {"commit": GAME, "date": "2026-10-18T10:00:00+04:00", "version": "1.0.7", "net": "abcdef123456"},
		"min_base": "1.0.6", "bases": {"aaaa1111": {"file": FILE, "size": FileAccess.get_file_as_bytes(pack).size(),
			"sha256": sha if sha != "" else Flow.sha256_of(pack)}}})


func _fetch() -> Node:
	var f: Node = Fetch.new()
	f.source = ProjectSettings.globalize_path(_server)
	f.metered_here = false
	add_child_autofree(f)
	return f


func _updater() -> Node:
	var u: Node = load(UPDATER).new()   # its _init: idle here (no folder named on the command line)
	u.keys = _keys
	u.auto_check = false
	add_child_autofree(u)
	return u


func _start(u: Node, source: String = "") -> void:
	u.start({"enabled": true, "kind": "phone", "dir": _app, "source": source, "base": BASE.duplicate()})


## The updater's start in a Godot of its own (the app's next start): {"running", "fell_back", "probe" (the probe file's
## words as that game reads them, or null)}; `menu`: the menu then shows.
func _start_apart(menu: bool = false) -> Dictionary:
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", CHILD, "--",
		"--dir=" + ProjectSettings.globalize_path(_app), "--base=" + Marshalls.utf8_to_base64(JSON.stringify(BASE)),
		"--probe=" + _probe]   # base64: a command line's quotes do not reach the other Godot's arguments
	if menu:
		args.append("--menu")
	var out := []
	OS.execute(OS.get_executable_path(), args, out, true)
	for line: String in "\n".join(out).split("\n"):
		if line.begins_with("UPDATE_START "):
			var v: Variant = JSON.parse_string(line.trim_prefix("UPDATE_START "))
			if v is Dictionary:
				return v
	fail_test("the start in its own Godot said nothing:\n" + "\n".join(out))
	return {}


func _state() -> Dictionary:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(_app.path_join("state.json")))
	return v if v is Dictionary else {}


func _write_state(s: Dictionary) -> void:
	var f := FileAccess.open(_app.path_join("state.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(s))
	f.close()


# --- the background check -----------------------------------------------------------------------------------------------

func test_the_check_downloads_verifies_and_keeps_the_patch() -> void:
	_deploy()
	var r: Dictionary = await Flow.check(_fetch(), BASE, {"base": BASE}, _app, false, _keys)
	assert_eq(r.status, "ready", str(r))
	assert_eq(r.state.ready.file, FILE)
	assert_eq(r.state.ready.commit, GAME)
	assert_eq(int(r.state.serial), 1000, "this manifest's serial: an older one is refused from now on")
	assert_true(FileAccess.file_exists(_app.path_join(FILE)))
	assert_eq(Flow.sha256_of(_app.path_join(FILE)), r.state.ready.sha256)
	assert_false(FileAccess.file_exists(_app.path_join(FILE + ".part")), "the piece in progress is gone")


func test_a_damaged_or_short_download_is_thrown_away() -> void:
	_deploy("the newer game", "00".repeat(32))
	var r: Dictionary = await Flow.check(_fetch(), BASE, {"base": BASE}, _app, false, _keys)
	assert_eq(r.status, "bad_file")
	assert_false(r.state.has("ready"))
	assert_eq(DirAccess.get_files_at(_app).size(), 0, "nothing kept")
	_deploy()
	var short := FakeFetch.new()
	add_child_autofree(short)
	# The manifest from the folder, the file from a network that stops halfway.
	var r2: Dictionary = await Flow.check(_HalfFetch.new(_fetch(), short), BASE, {"base": BASE}, _app, false, _keys)
	assert_eq(r2.status, "bad_file", str(r2))
	assert_eq(DirAccess.get_files_at(_app).size(), 0)


## The manifest through one fetcher, the file through another.
class _HalfFetch:
	extends RefCounted
	var text_from: Object
	var file_from: Object

	func _init(t: Object, f: Object) -> void:
		text_from = t
		file_from = f

	func get_text(url: String) -> Dictionary:
		return await text_from.get_text(url)

	func get_file(url: String, path: String, size: int) -> Dictionary:
		return await file_from.get_file(url, path, size)

	func metered() -> bool:
		return false


func test_no_network_or_a_manifest_we_did_not_sign_changes_nothing() -> void:
	var offline := FakeFetch.new()
	add_child_autofree(offline)
	var r: Dictionary = await Flow.check(offline, BASE, {"base": BASE}, _app, false, _keys)
	assert_eq(r.status, "offline")
	assert_eq(r.state, {"base": BASE})
	_deploy()
	_publish({"format": 1, "kind": "phone", "serial": 5, "engine": "4.7.2.stable", "game": {"commit": GAME,
		"version": "1.0.7"}, "min_base": "1.0.6", "bases": {}}, Crypto.new().generate_rsa(1024))
	var r2: Dictionary = await Flow.check(_fetch(), BASE, {"base": BASE}, _app, false, _keys)
	assert_eq(r2.status, "bad_manifest")
	assert_eq(DirAccess.get_files_at(_app).size(), 0)


func test_nothing_new_is_said_and_remembered() -> void:
	_deploy()
	var playing := {"base": BASE, "active": {"commit": GAME, "file": FILE, "tries": 0}}
	var r: Dictionary = await Flow.check(_fetch(), BASE, playing, _app, false, _keys)
	assert_eq(r.status, UpdateRules.UP_TO_DATE)
	assert_eq(int(r.state.serial), 1000)
	assert_eq(DirAccess.get_files_at(_app).size(), 0, "no download")


# --- the start --------------------------------------------------------------------------------------------------------------

func test_the_next_start_loads_the_kept_pack_and_counts_the_try() -> void:
	_deploy("the newer game")
	var r: Dictionary = await Flow.check(_fetch(), BASE, {"base": BASE}, _app, false, _keys)
	_write_state(r.state)
	var started := _start_apart()
	assert_eq((started.get("running", {}) as Dictionary).get("commit"), GAME)
	assert_eq(started.get("probe"), "the newer game", "the pack's file is that game's now")
	assert_eq(int(_state().active.tries), 1, "counted (and saved) before the menu")
	var again := _start_apart(true)
	assert_eq(again.get("probe"), "the newer game")
	assert_eq(int(_state().active.tries), 0, "the menu showed: it started the game")
	assert_false(FileAccess.file_exists(_probe), "this run never loaded it")


func test_a_pack_that_never_reached_the_menu_twice_is_dropped() -> void:
	var pack := _app.path_join(FILE)
	_make_pack(pack, "a broken game")
	_write_state({"base": BASE, "active": {"commit": GAME, "file": FILE, "sha256": Flow.sha256_of(pack),
		"size": 100, "tries": 2}})
	var u := _updater()
	_start(u)
	assert_eq(u.running, {}, "the app's own build")
	assert_true(u.fell_back)
	assert_false(FileAccess.file_exists(pack))
	assert_false(FileAccess.file_exists(_probe))
	assert_eq(_state().bad, [GAME])


func test_a_pack_whose_file_changed_is_not_loaded() -> void:
	var pack := _app.path_join(FILE)
	_make_pack(pack, "changed on the device")
	_write_state({"base": BASE, "active": {"commit": GAME, "file": FILE, "sha256": "11".repeat(32), "size": 100,
		"tries": 0}})
	var u := _updater()
	_start(u)
	assert_eq(u.running, {})
	assert_false(FileAccess.file_exists(_probe))
	assert_false(FileAccess.file_exists(pack))
	assert_false(_state().has("active"))
	assert_false(_state().has("bad"), "not the game's fault: it comes again")


func test_the_whole_way_check_after_the_menu_then_the_next_start() -> void:
	_deploy("the game of the next start")
	var u := _updater()
	u.auto_check = true
	u.check_delay = 0.0
	_start(u, ProjectSettings.globalize_path(_server))
	assert_eq(u.running, {})
	u.menu_shown()
	await wait_for_signal(u.update_ready, 10)
	assert_true(u.has_ready())
	assert_eq(u.status, "ready")
	assert_false(FileAccess.file_exists(_probe), "not in this run: it starts next time")
	var next := _start_apart()
	assert_eq((next.get("running", {}) as Dictionary).get("commit"), GAME)
	assert_eq(next.get("probe"), "the game of the next start")
