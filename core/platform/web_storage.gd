class_name WebStorage
extends RefCounted
## M7 Task 5 (spec §20.3): saves that survive a reload in the browser. A web build keeps user:// in the browser's
## IndexedDB: Godot copies the whole folder there after a FileAccess write is closed (JSON saves do that themselves),
## but Voxel Tools writes a world's blocks (VoxelStreamSQLite) with its own file I/O, which does not. So once the blocks
## are written, sync() writes a tiny stamp file and the copy that follows carries the world database too (the lead's
## browser check, 2026-09-27: without it a reload lost the edit). At boot the browser is asked once to keep the site's
## storage (ask_persistent). Off the web every function here does nothing.

const STAMP := "user://web_sync.txt"
## How long sync_when_written waits for the blocks at most: a stuck save still pushes everything else.
const WAIT_MS := 10_000

## Tests point this elsewhere (parallel runs share user://).
static var stamp_path := STAMP
## Whether this run asked the browser to keep its storage.
static var asked := false


## In a browser: writes the stamp, which makes the engine copy all of user:// to the browser's storage. `f`: the
## platform ({}: this device). Returns whether it wrote.
static func sync(f: Dictionary = {}) -> bool:
	if not PlatformRules.syncs_storage(f if not f.is_empty() else PlatformRules.current()):
		return false
	var file := FileAccess.open(stamp_path, FileAccess.WRITE)
	if file == null:
		push_warning("WebStorage: can't write %s (%s)" % [stamp_path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(str(Time.get_unix_time_from_system()))
	file.close()
	return true


## sync() as soon as `tracker` (a VoxelSaveCompletionTracker, or anything with is_complete()) says the blocks are
## written, or after `wait_ms`. Static, so it finishes even when the world that saved is freed meanwhile.
static func sync_when_written(tracker: Object, f: Dictionary = {}, wait_ms: int = WAIT_MS) -> void:
	var platform := f if not f.is_empty() else PlatformRules.current()
	if not PlatformRules.syncs_storage(platform):
		return
	var tree := Engine.get_main_loop() as SceneTree
	var deadline := Time.get_ticks_msec() + wait_ms
	while tracker != null and tree != null and not tracker.call("is_complete") and Time.get_ticks_msec() < deadline:
		await tree.process_frame
	sync(platform)


## At boot: asks the browser once per run to keep the site's storage (WebGlue.ask_persistent_storage). Returns whether
## it asked now.
static func ask_persistent(f: Dictionary = {}) -> bool:
	if asked or not PlatformRules.syncs_storage(f if not f.is_empty() else PlatformRules.current()):
		return false
	asked = true
	WebGlue.ask_persistent_storage()
	return true
