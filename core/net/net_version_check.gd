class_name NetVersionCheck
extends RefCounted
## Owner #123 (2026-10-17): an old phone app and the new web game played in one online world and saw different things.
## Each game in a relayed match sends its version (`payload`: BuildInfo's `net`, the version and the build's date) on
## its own op code (OP_CODE: the relay's bridge ignores codes it doesn't know, old games too), outside Godot's remote
## calls, which line up only between identical builds. It sends again every RESEND_SEC until it has heard every game it
## waits for (a host: each guest; a guest: the host). `heard` judges once: SAME plays; NEWER or OLDER (theirs, by the
## build's date, then the version's numbers) means the two games differ (a guest then leaves with plain words: Session).
## A game that never answers within WAIT_SEC is one older than this check (`overdue`: a gentle warning only, since
## phones on the store's old version can't update yet). A developer's run has net "" and plays with anyone.
## NakamaLink drives it (net/nakama_link.gd).

const OP_CODE := 9010   # the bridge's own: 9001 meta, 9002 packets; RelayBridge's: 9003 pieces, 9004 batches
const RESEND_SEC := 2.0
const WAIT_SEC := 12.0

const SAME := &"same"
const NEWER := &"newer"
const OLDER := &"older"
const UNKNOWN := &"unknown"   # the other game never answered (older than this check)

var own: Dictionary
var hosting: bool
var _clock := 0.0
var _last_sent := -INF
var _others := {}   # session id -> {"since": clock when met, "judged": bool, "told": bool}


func _init(own_info: Dictionary, is_host: bool) -> void:
	own = own_info
	hosting = is_host


## This build's version for the check.
static func own_info() -> Dictionary:
	var info := BuildInfo.current()
	return {"net": BuildInfo.net(info), "version": str(ProjectSettings.get_setting("application/config/version", "")),
		"date": str(info.get("date", ""))}


func payload() -> String:
	return JSON.stringify(own)


## A version message's content, or {} when it is not one a game sends.
static func parse(content: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(content) != OK or not json.data is Dictionary:
		return {}
	var d: Dictionary = json.data
	var net: Variant = d.get("net")
	var version: Variant = d.get("version")
	var date: Variant = d.get("date", "")
	if not (net is String and (net == "" or _is_hex(net))) or not (version is String and _is_version(version)) \
			or not (date is String and date.length() <= 32):
		return {}
	return {"net": net, "version": version, "date": date}


## SAME, or whether `theirs` is NEWER or OLDER than `mine`.
static func compare(mine: Dictionary, theirs: Dictionary) -> StringName:
	var a := str(mine.get("net", ""))
	var b := str(theirs.get("net", ""))
	if a == "" or b == "" or a == b:
		return SAME
	var da := str(mine.get("date", "")).left(19)
	var db := str(theirs.get("date", "")).left(19)
	if da.length() == 19 and db.length() == 19 and da != db:
		return NEWER if db > da else OLDER
	var va := str(mine.get("version", "")).split(".")
	var vb := str(theirs.get("version", "")).split(".")
	for i in maxi(va.size(), vb.size()):
		var x := va[i].to_int() if i < va.size() else 0
		var y := vb[i].to_int() if i < vb.size() else 0
		if x != y:
			return NEWER if y > x else OLDER
	return NEWER   # different games, no way to tell: this one is asked to update


## What a verdict does: {} (play on), {"leave": true, "reason": …} (a guest goes back; NetWords.code_for(reason) has
## the words) or {"leave": false, "notice": NetWords code}.
static func action(verdict: StringName, is_host: bool) -> Dictionary:
	match verdict:
		SAME:
			return {}
		NEWER, OLDER:
			if is_host:
				return {"leave": false, "notice": NetWords.FRIEND_DIFFERENT}
			return {"leave": true, "reason": "version: %s" % verdict}
	return {"leave": false, "notice": NetWords.MAYBE_DIFFERENT}


## A game this one waits for joined (a host: a guest; a guest: the host).
func met(session_id: String) -> void:
	if not _others.has(session_id):
		_others[session_id] = {"since": _clock, "judged": false, "told": false}


func left(session_id: String) -> void:
	_others.erase(session_id)


## A version message from `session_id`: SAME, NEWER or OLDER the first time, &"" after (or from a game a guest
## doesn't wait for: other guests).
func heard(session_id: String, content: String) -> StringName:
	if not _others.has(session_id):
		if not hosting:
			return &""
		met(session_id)
	var o: Dictionary = _others[session_id]
	var theirs := parse(content)
	if o.judged or theirs.is_empty():
		return &""
	o.judged = true
	return compare(own, theirs)


## Time passes; true when this game should send its version now.
func tick(delta: float) -> bool:
	_clock += delta
	var waiting := false
	for o: Dictionary in _others.values():
		if not o.judged and _clock - float(o.since) < WAIT_SEC:
			waiting = true
	if waiting and _clock - _last_sent >= RESEND_SEC:
		_last_sent = _clock
		return true
	return false


## The games that never answered within WAIT_SEC (each once).
func overdue() -> Array[String]:
	var out: Array[String] = []
	for id: String in _others:
		var o: Dictionary = _others[id]
		if not o.judged and not o.told and _clock - float(o.since) >= WAIT_SEC:
			o.told = true
			out.append(id)
	return out


static func _is_hex(s: String) -> bool:
	if s.length() < 8 or s.length() > 40:
		return false
	for c in s:
		if not "0123456789abcdef".contains(c):
			return false
	return true


static func _is_version(s: String) -> bool:
	var parts := s.split(".")
	if s.length() > 16 or parts.size() > 4:
		return false
	for p in parts:
		if not p.is_valid_int() or p.begins_with("-"):
			return false
	return true
