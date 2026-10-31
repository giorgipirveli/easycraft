class_name ProfileSync
extends Node
## The profile's backup on the game server (M4 Wave 2, agent F; owner #67; spec §7.4, §17.1), a child of the
## OnlineService. At sign-in (and right after the first username claim) it merges the server's copy with this
## device's profile (ProfileBackup.merge: earned things never lost, the newest choice per group, the newer copy
## for the rest; a new device takes the account's), saves this device's copy when that changed it and uploads
## when the two differ. Later changes (Profile.saved -> mark_changed) are uploaded debounced
## (ProfileBackup.upload_due), and at once when the game quits or goes to the background.
## Owner #67: one account may be on several devices (a sign-in key), so every write names the version of the
## server's copy it was merged with; when another device wrote in between, the server says so ("version_clash")
## and this reads the new copy, merges it and writes again (at most MAX_TRIES). Only for accounts that claimed a
## username (before the claim nothing is restorable).

## The backup changed this phone's profile (it was saved).
signal restored
signal uploaded

## Owner #67: read-merge-write rounds before giving up for now (the next change or sign-in tries again).
const MAX_TRIES := 3

var service: OnlineService
var msec := Callable()   # () -> int; default Time.get_ticks_msec (tests set one)

var uploads := 0          # uploads done (tests, measurements)
var last_error := ""      # the last failure's code ("" after a success)

var _first := -1          # the first change not uploaded yet (msec), -1 = none
var _last := -1           # the latest change
var _busy := false
var _saving := false
var _sent: Variant = null  # the server's copy as last seen, without its time (null = unknown)
var _version := ""         # owner #67: the server copy's version as last seen ("" = there is none)
var _known := false        # owner #67: whether _version is known since signing in


func _process(_delta: float) -> void:
	poll()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		flush.call_deferred()   # after the game has saved its profile


## The profile was saved on this phone.
func mark_changed() -> void:
	if _saving:
		return
	var now := _now()
	if _first < 0:
		_first = now
	_last = now


func is_dirty() -> bool:
	return _first >= 0


## Signed in with a claimed name.
func can_sync() -> bool:
	return service != null and service.status == OnlineService.ONLINE and service.claimed()


## Owner #67: a new sign-in (maybe another account): the server's copy is unknown until read again.
func forget_server_copy() -> void:
	_sent = null
	_version = ""
	_known = false


## Owner #99 (the second review's medium 4): a backup read or write is on its way (a switch of players waits).
func busy() -> bool:
	return _busy


## Owner #99, #105: this device's player changed (LOG OUT, LOG IN, DELETE: OnlineService.forget_session): nothing of the
## last one's backup stays.
func reset() -> void:
	forget_server_copy()
	_first = -1
	_last = -1
	last_error = ""


## Owner #99 (LOG OUT): after any upload on its way, merges with the server's copy and writes now. "" or plain words.
func save_now() -> String:
	while _busy and is_inside_tree():
		await get_tree().process_frame
	if not can_sync():
		return OnlineRules.message("not_signed_in")
	_busy = true
	var err := await _merge_and_write()
	_busy = false
	return err


## Merges the server's copy with this phone's and uploads if they differ. "" or plain words.
func sync() -> String:
	if not can_sync() or _busy:
		return ""
	_busy = true
	var err := await _merge_and_write()
	_busy = false
	return err


## Reads the server's copy, merges it into this device's profile and writes the result over exactly that copy;
## when another device wrote in between, the same again.
func _merge_and_write() -> String:
	var s := service.session
	for _attempt in MAX_TRIES:
		var r: Dictionary = await service.backend.read_storage(ProfileBackup.COLLECTION, ProfileBackup.KEY)
		if s != service.session:
			return ""   # owner #99: another player plays now: the last one's backup never lands in their profile
		if not r.get("ok", false):
			last_error = str(r.get("error", ""))
			return OnlineRules.message(last_error)
		var remote := str(r.get("value", ""))
		_version = str(r.get("version", "")) if remote != "" else ""
		_known = true
		_take(remote)
		var text := ProfileBackup.to_backup(service.profile)
		_sent = _content(remote)
		if _sent != null and _content(text) == _sent:
			_first = -1   # the same profile (maybe another time): nothing to write
			_last = -1
			return ""
		var err := await _write(text)
		if last_error != "version_clash":
			return err
	return OnlineRules.message("busy")


## The server's copy merged into this device's profile (saved, and `restored` said, when that changed it).
func _take(remote: String) -> void:
	var merged: ProfileData = ProfileBackup.merge(service.profile, remote).profile
	if merged.to_json() == service.profile.to_json():
		return
	ProfileBackup.copy_into(service.profile, merged)
	_saving = true   # our own save is no new change
	service.save_profile.call()
	_saving = false
	restored.emit()


## A debounced upload when it is due (every frame).
func poll() -> void:
	if not _busy and is_dirty() and can_sync() and ProfileBackup.upload_due(_first, _last, _now()):
		upload()


## Uploads now if anything changed (the game quits or goes to the background).
func flush() -> void:
	if not _busy and is_dirty() and can_sync():
		upload()


func upload() -> String:
	if _busy:
		return ""
	if not _known:
		return await sync()   # owner #67: never write without knowing which copy this replaces
	var text := ProfileBackup.to_backup(service.profile)
	if _sent != null and _content(text) == _sent:
		_first = -1   # only the time changed (an autosave): no write
		_last = -1
		return ""
	_busy = true
	var err := await _write(text)
	if last_error == "version_clash":
		err = await _merge_and_write()   # owner #67: another device of the account wrote first
	_busy = false
	return err


func _write(text: String) -> String:
	if text.length() > ProfileBackup.MAX_CHARS:
		last_error = "too_big"
		_first = -1   # it never fits: don't try every frame
		_last = -1
		return OnlineRules.message(last_error)
	var sent_changes := _last
	var s := service.session
	var r: Dictionary = await service.backend.write_storage(ProfileBackup.COLLECTION, ProfileBackup.KEY, text,
		_version if _version != "" else "*")
	if s != service.session:
		return ""   # owner #99: another player plays now: nothing of this write is theirs
	if not r.get("ok", false):
		last_error = str(r.get("error", ""))
		if last_error == "version_clash":
			return OnlineRules.message("busy")   # the caller reads, merges and writes again
		if last_error in ["bad_profile", "not_allowed", "too_big"]:
			_first = -1   # owner #67: the server refuses this profile: not again until it changes
			_last = -1
		elif is_dirty():
			_last = _now()   # try again after a quiet moment
		else:
			mark_changed()
		return OnlineRules.message(last_error)
	last_error = ""
	_sent = _content(text)
	_version = str(r.get("version", ""))
	uploads += 1
	if _last == sent_changes:   # nothing changed while it went up
		_first = -1
		_last = -1
	uploaded.emit()
	return ""


## A backup's content without its time, parsed (the server reorders the JSON; Nakama keeps JSONB),
## or null when there is none.
static func _content(text: String) -> Variant:
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	var d: Dictionary = json.data
	d.erase("updated_at")
	return d


func _now() -> int:
	return int(msec.call()) if msec.is_valid() else Time.get_ticks_msec()
