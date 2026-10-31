class_name OnlinePrefs
extends RefCounted
## What this device remembers about online play (M4 Wave 1, Agent C): when the "stay safe online"
## card was last seen and whom this device muted (§17.3: mute is on the device). Kept in its own
## file, never in profile.json, so a restored profile backup (§7.4) never carries another phone's
## mutes. Written crash-safe by JsonStore.

const PATH := "user://online.json"
const MAX_MUTED := 200
const MAX_ID := 64   # Nakama user ids are UUIDs (36 characters)

var safe_card_seen := 0   # unix seconds; 0 = never
var muted: Array[String] = []
## Owner #105: the online name this player's account had here ("" = none yet). A device that had one never makes a new
## account by itself when its link is gone (another device logged in: OnlineService.sign_in with create=false).
var account_name := ""
## Owner #105 (the final review's 7): that account's user id, so LOG IN knows "the same account as before" by id, not by a
## name another account may have claimed since.
var account_id := ""
## Owner #105: when this player was asked to make a password (unix seconds; 0 = never): asked once, LATER in SETTINGS.
var password_asked := 0
## Owner #105: the last "someone tried to log in as you" this player was told of (the server's tried_ms).
var tried_seen := 0


static func load_from(path: String = PATH) -> OnlinePrefs:
	return from_json(JsonStore.read_text(path))


func save_to(path: String = PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return JsonStore.write_atomic(path, to_json())


static func from_json(text: String) -> OnlinePrefs:
	var p := OnlinePrefs.new()
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return p
	var d: Dictionary = json.data
	var seen: Variant = d.get("safe_card_seen", 0)
	if typeof(seen) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(seen)) and float(seen) > 0.0:
		p.safe_card_seen = int(seen)
	var named: Variant = d.get("account_name", "")
	if named is String and UsernameRules.validate(named) == "":
		p.account_name = named
	var aid: Variant = d.get("account_id", "")
	if aid is String and (aid as String).length() <= 64:
		p.account_id = aid
	var asked: Variant = d.get("password_asked", 0)
	if typeof(asked) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(asked)) and float(asked) > 0.0:
		p.password_asked = int(asked)
	var tried: Variant = d.get("tried_seen", 0)
	if typeof(tried) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(tried)) and float(tried) > 0.0:
		p.tried_seen = int(tried)
	var ids: Variant = d.get("muted", [])
	if ids is Array:
		for id: Variant in ids:
			if id is String:
				p.mute(id)
	return p


func to_json() -> String:
	return JSON.stringify({"safe_card_seen": safe_card_seen, "muted": muted, "account_name": account_name, "account_id": account_id,
		"password_asked": password_asked, "tried_seen": tried_seen}, "\t")


## True when `user_id` was not muted before.
func mute(user_id: String) -> bool:
	if user_id == "" or user_id.length() > MAX_ID or muted.has(user_id):
		return false
	muted.append(user_id)
	while muted.size() > MAX_MUTED:
		muted.remove_at(0)
	return true


func unmute(user_id: String) -> void:
	muted.erase(user_id)


func is_muted(user_id: String) -> bool:
	return muted.has(user_id)
