class_name WalletSync
extends RefCounted
## The phone's Survivor gold and the server's wallet ledger (M4 Wave 2, agent F; spec §17.1, §6).
## Online worlds keep the server's balance (the host reads a guest's gold from the server and reports
## every change: OnlineWallets). Changes the server can't see (solo play, LAN, codes used offline,
## shopping in the menu) go up when signed in: the difference from a marker kept on this device, the
## phone's gold the server already accounts for (per account, in its own device-only file). A first
## sync on a device (no marker) sends only what the server lacks, and a server that has more gives
## it to the phone; what the server's limits refuse stays on the phone and goes up at a later sync.
## Owner #67 (one account on several devices, a sign-in key): the phone follows the wallet. After a
## sync the phone has the server's balance plus its own changes the server has not taken yet, so gold
## the server got elsewhere (another device, a farm collected there, a grown-up's gift) comes to the
## phone, and gold spent on another device is gone here too (never spent twice). Never below 0.

const PATH := "user://wallet_sync.json"
const MAX_GOLD := 999_999_999


## What to report ("report": + earned, − spent): this phone's change since the marker. A first sync counts
## from the smaller of the two (only what the server lacks goes up; no spending is guessed).
static func plan(phone: int, marker: int, server: int) -> Dictionary:
	var since := marker if marker >= 0 else mini(phone, server)
	return {"report": phone - since, "phone": server + phone - since}


## After reporting (`credited`: what the server took, signed): the phone's gold (the server's new balance plus
## what it did not take) and the new marker (the server's new balance).
static func settle(_phone: int, _marker: int, server: int, planned: Dictionary, credited: int) -> Dictionary:
	var balance := clampi(server + credited, 0, MAX_GOLD)
	return {"phone": clampi(balance + int(planned.report) - credited, 0, MAX_GOLD), "marker": balance}


## The marker of `user_id`, or -1 (none yet: a first sync on this device).
static func marker_of(path: String, user_id: String) -> int:
	var v: Variant = _markers(path).get(user_id, -1)
	return int(v)


static func set_marker(path: String, user_id: String, marker: int) -> void:
	if user_id == "":
		return
	var m := _markers(path)
	m[user_id] = clampi(marker, 0, MAX_GOLD)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	JsonStore.write_atomic(path, JSON.stringify(m))


static func _markers(path: String) -> Dictionary:
	var out := {}
	var json := JSON.new()
	var text := JsonStore.read_text(path)
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return out
	for k: Variant in json.data:
		var v: Variant = json.data[k]
		if k is String and typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and float(v) >= 0.0 \
				and float(v) <= MAX_GOLD:
			out[k] = int(v)
	return out
