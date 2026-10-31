extends Node
## Owner #123 (2026-10-17): "make windows and phone use same version always … i mean game version but of course mobile
## should be mobile". The web game is deployed from the newest code almost every day; an installed Android app (the
## phone's APK, the Play AAB, the Quest's APK) changed only with a new APK. Now each deploy puts a patch pack for every
## Android build in the wild on our server (tools/export_android_update.sh, tools/deploy_android_update.sh), and this
## updater keeps the app on the newest game: docs/devlog/parts/same-version.md (the spike, the rulings, the release rule).
##
## - At the start (_init), before anything else of the game is loaded: if a downloaded, verified pack for THIS app's own
##   build (its kind, its commit, its engine) is waiting or in use, its SHA-256 is checked, the try is counted and saved,
##   and it is loaded over the app's files (load_resource_pack(path, true)); then the version and the input map are taken
##   from the pack's project.binary (the engine read the app's own before any script ran).
## - A pack that started the game twice without the menu ever showing is dropped: the app's own build comes back.
## - Once the menu shows (menu_shown, from ui/menus/menu.gd), in the background: the signed manifest from our server, the
##   patch this build needs, its size and SHA-256 checked, kept for the next start; the menu's note then says "A new
##   EasyCraft is ready: it starts next time". A child never waits for any of it.
##
## The FIRST autoload: the engine loads and makes the autoloads one by one, so a pack loaded here changes every later
## autoload's script too (the spike). For that this script and its own (UpdateRules, UpdateFlow, UpdateFetch, preloaded
## below) name nothing else of the game: whatever they loaded would be the app's own copy for the whole run, so a change
## to these four reaches an app only in a new APK/AAB (tests/unit/test_updater.gd). Off Android it is idle (the editor,
## the tests, the web, a PC), unless a developer names a folder: --update-dir=<folder> [--update-kind=phone|quest]
## [--update-source=<a folder laid out as the server's play/ folder>] (the base pack's check on a PC, §6 of the notes).

const Rules := preload("res://core/platform/update_rules.gd")
const Flow := preload("res://core/platform/update_flow.gd")
const Fetch := preload("res://core/platform/update_fetch.gd")

## A newer game is downloaded and checked: it starts next time.
signal update_ready

const ANDROID_DIR := "user://update"
const STATE_FILE := "state.json"
## The app's own build's identity, read before any pack is in (tools/write_build_info.py writes it for every export).
const BUILD_INFO := "res://data/build_info.json"
const PROJECT_BINARY := "res://project.binary"
## Ruling 6: the background check starts this long after the menu shows (its first seconds stay the menu's).
const CHECK_DELAY := 15.0
## Ruling 6: an app brought back from the background looks again when its last look is this old.
const RECHECK_SECONDS := 3 * 3600

var enabled := false
var kind := ""
var dir := ""
## "" = our server over HTTPS; a folder only in a developer's run on a computer.
var source := ""
## This app's own build: {kind, commit, version, engine}.
var base := {}
## The pack in use ({} = the app's own build).
var running := {}
var state := {}
## A pack was dropped at this start after two starts that never reached the menu.
var fell_back := false
## The last background check's result: UpdateRules' words, "ready", "offline", "bad_manifest", "bad_file",
## "download_failed" ("" before any).
var status := ""
var auto_check := true
var check_delay := CHECK_DELAY
var keys: Dictionary = Rules.PUBLIC_KEYS
var _menu_seen := false
var _checking := false
var _last_check := 0.0


func _init() -> void:
	var setup := setup_from(OS.get_cmdline_user_args(), OS.has_feature("android"), OS.has_feature("quest"))
	if setup.enabled:
		start(setup)


## Where the updater works: on Android always (our server, user://update); elsewhere only with --update-dir (a
## developer's run). {"enabled", "kind", "dir", "source"}.
static func setup_from(args: PackedStringArray, android: bool, quest: bool) -> Dictionary:
	if android:
		return {"enabled": true, "kind": Rules.kind_of(quest), "dir": ANDROID_DIR, "source": ""}
	var out := {"enabled": false, "kind": "phone", "dir": "", "source": ""}
	for a: String in args:
		if a.begins_with("--update-dir="):
			out.dir = a.trim_prefix("--update-dir=")
		elif a.begins_with("--update-kind="):
			out.kind = Rules.kind_of(a.trim_prefix("--update-kind=") == "quest")
		elif a.begins_with("--update-source="):
			out.source = a.trim_prefix("--update-source=")
	out.enabled = out.dir != ""
	return out


## This app's own build, or {} when it has no build_info.json (an export that skipped tools/write_build_info.py: such a
## build cannot be matched to a patch and keeps its own game).
static func own_build(app_kind: String) -> Dictionary:
	if not FileAccess.file_exists(BUILD_INFO):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(BUILD_INFO)) != OK or not json.data is Dictionary:
		return {}
	var commit: Variant = (json.data as Dictionary).get("commit")
	if not Rules.is_hex(commit):
		return {}
	return {"kind": app_kind, "commit": commit, "version": str(ProjectSettings.get_setting("application/config/version", "")),
		"engine": Rules.engine_id(Engine.get_version_info())}


## The start: the waiting or used pack for this build, checked and loaded (setup.base for a test; else own_build()).
func start(setup: Dictionary) -> void:
	kind = str(setup.kind)
	dir = str(setup.dir)
	source = str(setup.get("source", ""))
	base = setup.get("base", own_build(kind))
	if base.is_empty():
		print("EasyCraft: updates off: this build has no build_info.json")
		return
	enabled = true
	DirAccess.make_dir_recursive_absolute(dir)
	state = _read_state()
	var plan := Rules.start_plan(state, base)
	state = plan.state
	fell_back = plan.fell_back
	for f: String in plan.drop:
		_delete(f)
	var entry: Dictionary = plan.load
	if not entry.is_empty():
		var path := dir.path_join(str(entry.file))
		if not FileAccess.file_exists(path) or Flow.sha256_of(path) != str(entry.get("sha256", "")):
			print("EasyCraft: the update %s changed on this device: dropped" % entry.get("commit"))
			state = Rules.drop_active(state, false)
			_delete(str(entry.file))
			entry = {}
	_write_state()   # the try counts before the pack is loaded: a crash while it loads counts too
	if fell_back:
		print("EasyCraft: the update never reached the menu twice: this app's own build again")
	if entry.is_empty():
		return
	var own_settings := _project_binary()
	if not ProjectSettings.load_resource_pack(dir.path_join(str(entry.file)), true):
		print("EasyCraft: the update %s did not load: dropped" % entry.get("commit"))
		state = Rules.drop_active(state, true)
		_delete(str(entry.file))
		_write_state()
		return
	running = entry
	apply_changes(Rules.project_changes(own_settings, _project_binary()))
	print("EasyCraft: the game of %s (%s, v%s) on this app's own build %s (try %d)" % [str(entry.get("date", "")).left(10),
		entry.get("commit"), entry.get("version", "?"), base.commit, int(state.active.get("tries", 0))])


## The pack's version and input map (UpdateRules.project_changes) into the running settings.
static func apply_changes(ch: Dictionary) -> void:
	if str(ch.version) != "":
		ProjectSettings.set_setting("application/config/version", ch.version)
	for k: String in ch.set:
		ProjectSettings.set_setting(k, ch.set[k])
	for k: String in ch.erase:
		ProjectSettings.set_setting(k, null)
	if not (ch.set as Dictionary).is_empty() or not (ch.erase as Array).is_empty():
		InputMap.load_from_project_settings()


## The menu showed (ui/menus/menu.gd): the pack in use started the game; the background check follows. True when this
## app's updater is on (the menu's note then asks it, not the web page).
func menu_shown() -> bool:
	if not enabled:
		return false
	if _menu_seen:
		return true
	_menu_seen = true
	state = Rules.menu_reached(state)
	_write_state()
	if auto_check and is_inside_tree():
		get_tree().create_timer(check_delay).timeout.connect(check_now)
	return true


## A newer game is downloaded and checked, waiting for the next start.
func has_ready() -> bool:
	return enabled and state.get("ready") is Dictionary


## The background check (UpdateFlow.check): once after the menu, again when the app comes back after RECHECK_SECONDS.
func check_now() -> void:
	if not enabled or _checking:
		return
	_checking = true
	_last_check = Time.get_unix_time_from_system()
	status = "checking"
	var fetch: Node = Fetch.new()
	fetch.source = source
	add_child(fetch)
	var metered: bool = fetch.metered()
	var r: Dictionary = await Flow.check(fetch, base, state, dir, metered, keys)
	fetch.queue_free()
	state = r.state
	for f: String in r.get("drop", []):
		_delete(f)
	_write_state()
	status = str(r.status)
	_checking = false
	print("EasyCraft: update check: %s%s (metered %s)" % [status, " (%s)" % r.why if r.has("why") else "", metered])
	if status == "ready":
		update_ready.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and enabled and _menu_seen and auto_check \
			and Time.get_unix_time_from_system() - _last_check > RECHECK_SECONDS:
		check_now()


func _project_binary() -> Dictionary:
	if not FileAccess.file_exists(PROJECT_BINARY):
		return {}
	return Rules.read_project_binary(FileAccess.get_file_as_bytes(PROJECT_BINARY))


func _read_state() -> Dictionary:
	var path := dir.path_join(STATE_FILE)
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	return json.data


## Written whole to a new file, then put in place (a phone that dies mid-write keeps the old state).
func _write_state() -> void:
	var path := dir.path_join(STATE_FILE)
	var f := FileAccess.open(path + ".new", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(state, "\t"))
	f.close()
	DirAccess.open(dir).rename(STATE_FILE + ".new", STATE_FILE)


func _delete(file: String) -> void:
	if Rules.safe_file(file) and FileAccess.file_exists(dir.path_join(file)):
		DirAccess.remove_absolute(dir.path_join(file))
