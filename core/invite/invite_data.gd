class_name InviteData
extends RefCounted
## Owner #79 (spec §25.2): the invite program's part of the profile (ProfileData.invite), account-wide and offline-first.
## - pending_code: a friend's code typed at the start, in SETTINGS or brought by the web page's ?invite=, that the
##   server has not taken yet (it goes up at the next sign-in; "" when none);
## - used: the server took a code for this account (the box is not offered again);
## - guide: the in-game name of whoever brought this child (the missions say "Your guide ALEX flew this one");
## - learned_day: the day this child first mastered a School unit (0: not yet); landed: places first landed on;
## - sent: what the server has heard ("learned", "landed:moon"), so nothing is reported twice;
## - code: this account's own invite code, as the server made it (shown offline too; "" until the INVITE page read it).
## merge_from never loses a report or a day learned (ProfileBackup).

const MAX_SENT := 16
const PLACES: Array[String] = ["moon"]

var pending_code := ""
var used := false
var guide := ""
var learned_day := 0
var landed: Array[String] = []
var sent: Array[String] = []
var code := ""


func is_empty() -> bool:
	return pending_code == "" and not used and guide == "" and learned_day == 0 and landed.is_empty() and sent.is_empty() \
		and code == ""


## The first unit mastered, on `day`: true the first time.
func note_learned(day: int) -> bool:
	if learned_day > 0 or day <= 0:
		return false
	learned_day = day
	return true


## A first landing on `where` (PLACES): true the first time.
func note_landed(where: String) -> bool:
	if not PLACES.has(where) or landed.has(where):
		return false
	landed.append(where)
	return true


## What the server should hear now: invite_progress payloads.
func events_to_send() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if learned_day > 0 and not sent.has("learned"):
		out.append({"event": "learned"})
	for where in landed:
		if not sent.has("landed:" + where):
			out.append({"event": "landed", "where": where})
	return out


## The server heard `key` ("learned" or "landed:<where>").
func mark_sent(key: String) -> void:
	if not sent.has(key) and sent.size() < MAX_SENT:
		sent.append(key)


static func key_of(event: Dictionary) -> String:
	return "landed:" + str(event.get("where", "")) if str(event.get("event", "")) == "landed" else str(event.get("event", ""))


func to_dict() -> Dictionary:
	var d := {}
	if pending_code != "":
		d.pending_code = pending_code
	if used:
		d.used = true
	if guide != "":
		d.guide = guide
	if learned_day > 0:
		d.learned_day = learned_day
	if not landed.is_empty():
		d.landed = landed.duplicate()
	if not sent.is_empty():
		d.sent = sent.duplicate()
	if code != "":
		d.code = code
	return d


## Field by field: a broken one falls back on its own.
static func from_dict(v: Variant) -> InviteData:
	var out := InviteData.new()
	if not v is Dictionary:
		return out
	var d: Dictionary = v
	var typed := str(d.get("pending_code", "")) if d.get("pending_code") is String else ""
	out.pending_code = InviteRules.shown(typed) if InviteRules.looks_like_code(typed) else ""
	out.used = d.get("used") is bool and bool(d.used)
	var g: Variant = d.get("guide")
	out.guide = g if g is String and UsernameRules.validate(g) == "" else ""
	var day: Variant = d.get("learned_day")
	if typeof(day) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(day)) and float(day) > 0.0 and float(day) < 1e7:
		out.learned_day = int(day)
	if d.get("landed") is Array:
		for w: Variant in d.landed:
			if w is String and PLACES.has(w) and not out.landed.has(w):
				out.landed.append(w)
	var mine: Variant = d.get("code")
	out.code = InviteRules.shown(mine) if mine is String and InviteRules.looks_like_code(mine) else ""
	if d.get("sent") is Array:
		for s: Variant in d.sent:
			if s is String and (s == "learned" or (s as String).begins_with("landed:")) and not out.sent.has(s) \
					and out.sent.size() < MAX_SENT:
				out.sent.append(s)
	return out


## Another copy of the account's profile: nothing learned or reported is lost; a code waits only while none was used.
func merge_from(other: InviteData) -> void:
	used = used or other.used
	if guide == "":
		guide = other.guide
	if other.learned_day > 0 and (learned_day == 0 or other.learned_day < learned_day):
		learned_day = other.learned_day
	for w in other.landed:
		if not landed.has(w):
			landed.append(w)
	for s in other.sent:
		mark_sent(s)
	if code == "":
		code = other.code
	if pending_code == "":
		pending_code = other.pending_code
	if used:
		pending_code = ""
