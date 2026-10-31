class_name DiscoveryLog
extends RefCounted
## Owner #132 (W1): Professor Hoot's memory on this device (DiscoveryRules' {"worlds": {key: day}, "day": day}): which
## worlds he has come to and the day he came last. A world key and a day number say nothing about the child; the file
## is never sent anywhere and is not in the profile's backup (a new device just gets Hoot once more).

const PATH := "user://discovery.json"

## Where it is kept; "" keeps it in memory only (tests).
var path := PATH
var state := {}


func _init(at: String = PATH) -> void:
	path = at
	state = _read()


func save() -> void:
	if path == "":
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Discovery: could not write %s" % path)
		return
	f.store_string(JSON.stringify(state))


func _read() -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
