class_name SocialData
extends RefCounted
## Owner #81, #82, #85 (brief 2026-09-30 items 2-5): better together's part of the profile (ProfileData.social).
## - postcards: the moments whose postcard was offered (PostcardRules: once, never nagging), account-wide;
## - learned_day: the last UTC day this device learned (a round finished, the Daily Mission) that the server has not
##   heard yet (-1: nothing waits); units: units mastered the server has not heard yet (the crew page's week);
## - moments: proud moments ({kind, place}) friends have not been told yet (sent at the next sign-in);
## - map_pieces: treasure map pieces friends gave (a hook for the prospecting quests).
## What waits for the server stays on this device (a merge never sends another device's twice); postcards offered and
## map pieces are never lost (ProfileBackup).

const MAX_UNITS := 12
const MAX_MOMENTS := 5

var postcards: Array[String] = []
var learned_day := -1
var units: Array[String] = []
var moments: Array[Dictionary] = []
var map_pieces := 0


func is_empty() -> bool:
	return postcards.is_empty() and learned_day < 0 and units.is_empty() and moments.is_empty() and map_pieces == 0


## This device learned on `day` (and mastered `unit`, when given): kept until the server hears it.
func note_learned(day: int, unit: String = "") -> void:
	learned_day = maxi(learned_day, day)
	if unit != "" and SchoolData.valid_id(unit) and not units.has(unit) and units.size() < MAX_UNITS:
		units.append(unit)


## A proud moment to tell friends (SocialRules' kinds and places).
func note_moment(kind: String, place: String) -> bool:
	if not PostcardRules.KINDS.has(kind) or PostcardRules.PLACE_RE.search(place) == null:
		return false
	for m in moments:
		if m.kind == kind and m.place == place:
			return false
	moments.append({"kind": kind, "place": place})
	while moments.size() > MAX_MOMENTS:
		moments.pop_front()
	return true


## What the server should hear: social_learned payloads (one per unit, or one plain), then social_moment payloads.
func learned_to_send() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in units:
		out.append({"unit": u})
	if out.is_empty() and learned_day >= 0:
		out.append({})
	return out


func mark_learned_sent(payload: Dictionary) -> void:
	units.erase(str(payload.get("unit", "")))
	if units.is_empty():
		learned_day = -1


func mark_moment_sent(m: Dictionary) -> void:
	for i in range(moments.size() - 1, -1, -1):
		if moments[i].kind == str(m.get("kind", "")) and moments[i].place == str(m.get("place", "")):
			moments.remove_at(i)


func to_dict() -> Dictionary:
	var d := {}
	if not postcards.is_empty():
		d.postcards = postcards.duplicate()
	if learned_day >= 0:
		d.learned_day = learned_day
	if not units.is_empty():
		d.units = units.duplicate()
	if not moments.is_empty():
		d.moments = moments.duplicate(true)
	if map_pieces > 0:
		d.map_pieces = map_pieces
	return d


static func from_dict(v: Variant) -> SocialData:
	var out := SocialData.new()
	if not v is Dictionary:
		return out
	var d: Dictionary = v
	if d.get("postcards") is Array:
		for k: Variant in d.postcards:
			if k is String and (k as String).length() <= 80 and (k as String).contains(":") and not out.postcards.has(k) \
					and out.postcards.size() < PostcardRules.MAX_OFFERED:
				out.postcards.append(k)
	var day: Variant = d.get("learned_day")
	if typeof(day) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(day)) and float(day) >= 0.0 and float(day) < 1e7:
		out.learned_day = int(day)
	if d.get("units") is Array:
		for u: Variant in d.units:
			if u is String and SchoolData.valid_id(u) and not out.units.has(u) and out.units.size() < MAX_UNITS:
				out.units.append(u)
	if d.get("moments") is Array:
		for m: Variant in d.moments:
			if m is Dictionary:
				out.note_moment(str((m as Dictionary).get("kind", "")), str((m as Dictionary).get("place", "")))
	var pieces: Variant = d.get("map_pieces")
	if typeof(pieces) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(pieces)):
		out.map_pieces = clampi(int(pieces), 0, 9999)
	return out


## Another copy of the account's profile: every postcard offered, the most map pieces. What waits for the server stays
## this device's own.
func merge_from(other: SocialData) -> void:
	for k in other.postcards:
		if not postcards.has(k) and postcards.size() < PostcardRules.MAX_OFFERED:
			postcards.append(k)
	map_pieces = maxi(map_pieces, other.map_pieces)
