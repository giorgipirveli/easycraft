class_name BuildInfo
extends RefCounted
## Owner #123 (2026-10-17): the phone app and the web game both said "v1.0.5" while they were different builds. Every
## export writes `PATH` (tools/write_build_info.py, run by the export scripts; git-ignored): the commit it was built
## from, the date and `net`, online play's fingerprint (what two games must share to play together: their remote calls
## and their blocks). The menu shows the build beside the version; online play compares `net` (NetVersionCheck). A run
## without the file (the editor, the tests) shows the version alone and its `net` is "" (unknown).

const PATH := "res://data/build_info.json"
const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

static var _cached: Variant = null


## This build's info ({} without the file).
static func current() -> Dictionary:
	if _cached == null:
		_cached = read(PATH)
	return _cached


## The file's commit (8-40 hex), date (ISO "YYYY-MM-DDTHH:MM…") and net (8-40 hex); anything else is dropped.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()   # its parse() reports a bad file quietly (JSON.parse_string logs an engine error)
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	var parsed: Dictionary = json.data
	var out := {}
	for key: String in ["commit", "net"]:
		var v: Variant = parsed.get(key)
		if v is String and _is_hex(v):
			out[key] = v
	var date: Variant = parsed.get("date")
	if date is String and _date_parts(date).size() == 3:
		out.date = date
	return out


## "v1.0.6 (17 Oct, 90e976cc)", or "v1.0.6" without the build's info.
static func label(version: String, info: Dictionary) -> String:
	var parts: Array[String] = []
	var d := _date_parts(str(info.get("date", "")))
	if d.size() == 3:
		parts.append("%d %s" % [d[2], MONTHS[d[1] - 1]])
	if info.has("commit"):
		parts.append(str(info.commit).left(8))
	return "v%s" % version if parts.is_empty() else "v%s (%s)" % [version, ", ".join(parts)]


## Online play's fingerprint, or "" when unknown.
static func net(info: Dictionary) -> String:
	return str(info.get("net", ""))


static func _is_hex(s: String) -> bool:
	if s.length() < 8 or s.length() > 40:
		return false
	for c in s:
		if not "0123456789abcdef".contains(c):
			return false
	return true


## [year, month, day] of an ISO date, or [] when it is not one.
static func _date_parts(s: String) -> Array[int]:
	var bits := s.left(10).split("-")
	if s.length() < 10 or bits.size() != 3 or not (bits[0].is_valid_int() and bits[1].is_valid_int() and bits[2].is_valid_int()):
		return []
	var m := bits[1].to_int()
	var day := bits[2].to_int()
	if m < 1 or m > 12 or day < 1 or day > 31:
		return []
	return [bits[0].to_int(), m, day]
