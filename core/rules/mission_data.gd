class_name MissionData
extends RefCounted
## The missions' part of the profile (spec §21d, §25.3; ProfileData.missions): the rocket parts this child bought for
## Sandbox rockets (Survivor's go into the bag) and the worlds flown to by a mission (the route, MissionRules.route).
## Account-wide, parsed field by field, kept by the server backup (merge_from never loses a part or a flight).
##
## Owner #98 (bug 3): one account on two devices pays for each device's parts (each spend reaches the server's wallet,
## WalletSync), so the parts add up too: each install counts what it bought under its own key (`by`, device_key(): a
## random id in a device-only file, never the sign-in id), a merge keeps the bigger count per device, and the parts
## owned are the sum, plus `older` (what a copy from before owner #98 held, merged as before by the bigger count).
## `parts` is that total (what the game reads; the save keeps it too, for an older game).
## Owner #106: a crash breaks some of the rocket's parts; in the Sandbox they are gone from what the child owns. Each
## install counts what it lost under its own key too (`lost`, merged by the bigger count like `by`), so the server
## backup's older copy never brings a broken part back: the parts owned are what was bought less what broke.

const MAX_PER_PART := 9999
const MAX_DEVICES := 64
## Owner #106: the most of one part a device can have lost (all it could ever have counted).
const MAX_LOST := MAX_PER_PART * MAX_DEVICES
## This install's key for its own purchases (device-only; never in the profile's other fields).
const DEVICE_PATH := "user://rocket_parts_device.json"

## This install's key ("" until device_key() reads or makes it; tests set their own).
static var device := ""

## Block id -> how many of that part the child owns (older + every device's).
var parts := {}
## Owner #98: device key -> {block id: how many that device bought}.
var by := {}
## Owner #98: the parts of a copy from before the counts per device ({block id: count}).
var older := {}
## Owner #106: device key -> {block id: how many of the parts that device owned broke in a crash}.
var lost := {}
## Worlds reached by a mission, in the order they were flown.
var flown: Array[int] = []
## Crew flights (spec §21d.6 phase 2): the crew badges ("Crew of the Moon mission with Anna and Sam").
var crews := CrewBadges.new()
## This copy came from a save with no counts per device (an older game's).
var legacy := false


func is_empty() -> bool:
	return parts.is_empty() and flown.is_empty() and crews.is_empty()


func add_part(id: int, n: int = 1) -> void:
	if not RocketParts.is_part(id) or n <= 0:
		return
	var key := device_key()
	var mine: Dictionary = by.get(key, {})
	mine[id] = mini(int(mine.get(id, 0)) + n, MAX_PER_PART)
	by[key] = mine
	_total()


func owned() -> Dictionary:
	return parts.duplicate()


## Owner #106: a crash broke these parts ({id: count}): gone from what the child owns (never more than it has; what is
## not a part is ignored).
func lose_parts(counts: Dictionary) -> void:
	var key := device_key()
	var mine: Dictionary = lost.get(key, {})
	for id: Variant in counts:
		if not (id is int and RocketParts.is_part(id)):
			continue
		var n := mini(int(counts[id]), int(parts.get(id, 0)))
		if n > 0:
			mine[id] = mini(int(mine.get(id, 0)) + n, MAX_LOST)
	if not mine.is_empty() and (lost.has(key) or lost.size() < MAX_DEVICES):
		lost[key] = mine
	_total()


## A mission flew to world u: true the first time.
func fly(u: int) -> bool:
	if not MissionRules.has_mission(u) or flown.has(u):
		return false
	flown.append(u)
	return true


## This install's key for its purchases: kept in DEVICE_PATH (made once, crash-safe), or a new one for this session if
## it can't be kept.
static func device_key() -> String:
	if device != "":
		return device
	var text := JsonStore.read_text(DEVICE_PATH)
	var json := JSON.new()
	if text != "" and json.parse(text) == OK and json.data is Dictionary:
		var k := str((json.data as Dictionary).get("key", ""))
		if _good_key(k):
			device = k
			return device
	device = Crypto.new().generate_random_bytes(8).hex_encode()
	JsonStore.write_atomic(DEVICE_PATH, JSON.stringify({"key": device}))
	return device


func to_dict() -> Dictionary:
	var devices := {}
	for key: String in by:
		devices[key] = _out(by[key])
	var broke := {}
	for key: String in lost:
		broke[key] = _out(lost[key])
	return {"parts": _out(parts), "older": _out(older), "by": devices, "lost": broke, "flown": flown.duplicate(),
		"crews": crews.to_array()}


static func from_dict(v: Variant) -> MissionData:
	var d := MissionData.new()
	if not v is Dictionary:
		return d
	var devices: Variant = (v as Dictionary).get("by")
	if devices is Dictionary:
		d.older = _parse((v as Dictionary).get("older"))
		for key: Variant in devices:
			if key is String and _good_key(key) and d.by.size() < MAX_DEVICES:
				var counts := _parse(devices[key])
				if not counts.is_empty():
					d.by[key] = counts
		var losses: Variant = (v as Dictionary).get("lost")   # owner #106
		if losses is Dictionary:
			for key: Variant in losses:
				if key is String and _good_key(key) and d.lost.size() < MAX_DEVICES:
					var counts := _parse(losses[key], MAX_LOST)
					if not counts.is_empty():
						d.lost[key] = counts
	else:
		d.legacy = true
		d.older = _parse((v as Dictionary).get("parts"))
	d._total()
	var f: Variant = (v as Dictionary).get("flown")
	if f is Array:
		for u: Variant in f:
			if typeof(u) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(u)) and float(u) == floorf(float(u)):
				d.fly(int(u))
	d.crews = CrewBadges.from_array((v as Dictionary).get("crews"))   # spec §21d.6 phase 2
	return d


## Keeps the best of both copies: each device's bigger count of each part (owner #98: the devices' purchases add up),
## every flight, every crew badge. A copy from an older game holds only a total, which may already count this copy's
## purchases: what it has beyond them goes into `older`.
func merge_from(other: MissionData) -> void:
	for key: String in other.by:
		var mine: Dictionary = by.get(key, {})
		for id: int in other.by[key]:
			mine[id] = maxi(int(mine.get(id, 0)), int(other.by[key][id]))
		if not mine.is_empty() and (by.has(key) or by.size() < MAX_DEVICES):
			by[key] = mine
	for key: String in other.lost:   # owner #106: what broke stays broken
		var mine: Dictionary = lost.get(key, {})
		for id: int in other.lost[key]:
			mine[id] = maxi(int(mine.get(id, 0)), int(other.lost[key][id]))
		if not mine.is_empty() and (lost.has(key) or lost.size() < MAX_DEVICES):
			lost[key] = mine
	for id: int in other.older:
		var extra := int(other.older[id])
		if other.legacy:
			extra -= _bought(id)
		older[id] = maxi(int(older.get(id, 0)), extra)
	_total()
	for u in other.flown:
		fly(u)
	crews.merge_from(other.crews)


## How many of part `id` the devices bought (not counting `older`).
func _bought(id: int) -> int:
	var n := 0
	for key: String in by:
		n += int((by[key] as Dictionary).get(id, 0))
	return n


func _total() -> void:
	parts = {}
	for id: int in older:
		if int(older[id]) > 0:
			parts[id] = int(older[id])
	for key: String in by:
		for id: int in by[key]:
			parts[id] = int(parts.get(id, 0)) + int(by[key][id])
	for key: String in lost:   # owner #106: less what broke in a crash
		for id: int in lost[key]:
			parts[id] = int(parts.get(id, 0)) - int(lost[key][id])
	for id: int in parts.keys():
		if int(parts[id]) <= 0:
			parts.erase(id)
		else:
			parts[id] = mini(int(parts[id]), MAX_PER_PART)


static func _good_key(k: String) -> bool:
	return k.length() >= 4 and k.length() <= 64 and RegEx.create_from_string("^[A-Za-z0-9_-]+$").search(k) != null


## {"560": 3} -> {560: 3}: whole positive counts of rocket parts only.
static func _parse(v: Variant, most: int = MAX_PER_PART) -> Dictionary:
	var out := {}
	if not v is Dictionary:
		return out
	for k: Variant in v:
		var n: Variant = v[k]
		if not (k is String and (k as String).is_valid_int()) or typeof(n) not in [TYPE_INT, TYPE_FLOAT]:
			continue
		if not is_finite(float(n)) or float(n) != floorf(float(n)) or int(n) <= 0 or not RocketParts.is_part(int(k)):
			continue
		out[int(k)] = mini(int(n), most)
	return out


static func _out(counts: Dictionary) -> Dictionary:
	var out := {}
	for id: int in counts:
		out[str(id)] = int(counts[id])
	return out
