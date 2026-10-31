class_name UpdateFlow
extends RefCounted
## Owner #123: the updater's background check (autoloads/updater.gd, after the menu shows): the signed manifest from our
## server, the plan for this app's own build (UpdateRules.plan_download), the patch downloaded next to where it goes
## (".part"), its size and SHA-256 checked, then put in place and kept for the next start (UpdateRules.keep_ready).
## Nothing it does is in the way of play: the downloads run on HTTPRequest's thread.
##
## `fetch` is UpdateFetch (our server over HTTPS, or a local folder laid out as the server's play/ folder) or a test's
## fake: get_text(url) -> {ok, text}, get_file(url, path, size) -> {ok}, both coroutines. Part of the updater's own set
## (frozen in each APK/AAB: tests/unit/test_updater.gd).

const Rules := preload("res://core/platform/update_rules.gd")
const PIECE := 1 << 20


## {"status": "ready" | UpdateRules' words | "offline" | "bad_manifest" | "download_failed" | "bad_file",
##  "state": the new state (save it), "drop": [files to delete], "why": (for bad_manifest)}.
static func check(fetch: Object, base: Dictionary, state: Dictionary, dir: String, metered: bool,
		keys: Dictionary = Rules.PUBLIC_KEYS) -> Dictionary:
	var got: Dictionary = await fetch.get_text(Rules.manifest_url(str(base.kind)))
	if not got.get("ok", false):
		return {"status": "offline", "state": state}
	var env := Rules.open_envelope(str(got.get("text", "")), keys)
	if not env.ok:
		return {"status": "bad_manifest", "why": env.why, "state": state}
	var m: Dictionary = env.manifest
	var s := state.duplicate(true)
	var plan := Rules.plan_download(m, base, s, metered)
	if not [Rules.OTHER_APP, Rules.OTHER_ENGINE, Rules.OLDER_MANIFEST].has(plan.get("why", "")):
		s.serial = maxi(int(s.get("serial", 0)), int(m.serial))   # an older manifest sent again is refused from now on
	if plan.do != "download":
		return {"status": plan.why, "state": s}
	var entry: Dictionary = plan.entry
	var final := dir.path_join(str(entry.file))
	var part := final + ".part"
	DirAccess.make_dir_recursive_absolute(dir)
	var got_file: Dictionary = await fetch.get_file(Rules.file_url(str(base.kind), str(entry.file)), part, int(entry.size))
	if not got_file.get("ok", false):
		_remove(part)
		return {"status": "download_failed", "state": s}
	if not FileAccess.file_exists(part) or FileAccess.open(part, FileAccess.READ).get_length() != int(entry.size) \
			or sha256_of(part) != str(entry.sha256):
		_remove(part)
		return {"status": "bad_file", "state": s}
	_remove(final)
	if DirAccess.open(dir).rename(part.get_file(), final.get_file()) != OK:
		_remove(part)
		return {"status": "download_failed", "state": s}
	var kept := Rules.keep_ready(s, plan)
	return {"status": "ready", "state": kept.state, "drop": kept.drop}


## The file's SHA-256 as 64 hex characters ("" when it cannot be read), in 1 MiB pieces.
static func sha256_of(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var size := f.get_length()
	while f.get_position() < size:
		ctx.update(f.get_buffer(PIECE))
	return ctx.finish().hex_encode()


static func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
