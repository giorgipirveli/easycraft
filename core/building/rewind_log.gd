class_name RewindLog
extends RefCounted
## Build Rewind's record (M3 Task 8; spec §14.5, §3a): this player's block edits within RADIUS of a spot (a cube),
## in order, at most MAX_EDITS; the replay rebuilds them as a time-lapse of at most MAX_SECONDS. Seven bytes an
## edit in memory (the offset from the spot on each axis, then the old and the new id in two bytes each, low byte
## first: block ids go past 255 since owner #45b's page 13), saved with the world deflated and in base64
## (WorldMeta.rewind, "v": 2). A recording saved before (5 bytes an edit, one byte an id, no "v") still loads. A
## broken save is dropped; an id no block owns replays as air. Pure: RewindRecorder feeds it, RewindView shows it.

const MAX_EDITS := 5000
const RADIUS := 32
const MAX_SECONDS := 20.0
## A small build shows a quarter second an edit; a big one goes faster, so the whole replay fits MAX_SECONDS.
const SLOW_STEP := 0.25
const BYTES := 7
const OLD_BYTES := 5   # the first saves (2026-09-25, before block ids went past 255)
const VERSION := 2

var active := false
var center := Vector3i.ZERO
var _bytes := PackedByteArray()


## Starts a new recording around `spot` (the old one is forgotten).
func start(spot: Vector3i) -> void:
	active = true
	center = spot
	_bytes = PackedByteArray()


## Stops and forgets.
func clear() -> void:
	active = false
	center = Vector3i.ZERO
	_bytes = PackedByteArray()


## Keeps one edit: false when not recording, full, outside the cube, not a change or not a block id.
func record(pos: Vector3i, old: int, new: int) -> bool:
	if not active or is_full() or old == new or not _id_ok(old) or not _id_ok(new):
		return false
	var d := pos - center
	if absi(d.x) > RADIUS or absi(d.y) > RADIUS or absi(d.z) > RADIUS:
		return false
	_bytes.append_array(PackedByteArray([d.x + RADIUS, d.y + RADIUS, d.z + RADIUS, old & 0xff, old >> 8, new & 0xff,
		new >> 8]))
	return true


func size() -> int:
	return _bytes.size() / BYTES


func is_full() -> bool:
	return size() >= MAX_EDITS


## Edit i: {pos, old, new}.
func edit(i: int) -> Dictionary:
	var k := i * BYTES
	return {"pos": center + Vector3i(_bytes[k] - RADIUS, _bytes[k + 1] - RADIUS, _bytes[k + 2] - RADIUS),
		"old": _bytes[k + 3] | (_bytes[k + 4] << 8), "new": _bytes[k + 5] | (_bytes[k + 6] << 8)}


## The recorded cells' blocks after the first `n` edits ({pos: id}, air left out): before its first edit a cell
## holds what that edit found there.
func blocks_after(n: int) -> Dictionary:
	var out := {}
	var seen := {}
	for i in size():
		var e := edit(i)
		if not seen.has(e.pos):
			seen[e.pos] = true
			if e.old != BlockIds.AIR:
				out[e.pos] = e.old
	for i in mini(n, size()):
		var e := edit(i)
		if e.new == BlockIds.AIR:
			out.erase(e.pos)
		else:
			out[e.pos] = e.new
	return out


func step_seconds() -> float:
	return minf(SLOW_STEP, MAX_SECONDS / maxf(size(), 1.0))


func duration() -> float:
	return step_seconds() * size()


## How many edits the replay shows `t` seconds after it starts.
func shown_at(t: float) -> int:
	if size() == 0:
		return 0
	return clampi(floori(t / step_seconds() + 0.0001), 0, size())


func to_save() -> Dictionary:
	if not active:
		return {}
	return {"v": VERSION, "c": [center.x, center.y, center.z], "n": size(),
		"e": Marshalls.raw_to_base64(_bytes.compress(FileAccess.COMPRESSION_DEFLATE)) if size() > 0 else ""}


## A recording from a save; anything broken gives an empty, stopped one.
static func from_save(d: Variant) -> RewindLog:
	var r := RewindLog.new()
	if not d is Dictionary:
		return r
	var c: Variant = d.get("c")
	var n: Variant = d.get("n")
	var e: Variant = d.get("e")
	if not c is Array or (c as Array).size() != 3 or typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not e is String:
		return r
	for v: Variant in c:
		if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)) or absf(float(v)) > 1.0e7:
			return r
	var count := int(n)
	if count < 0 or count > MAX_EDITS:
		return r
	var v: Variant = d.get("v", 1)
	if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not int(v) in [1, VERSION]:
		return r
	var width := BYTES if int(v) == VERSION else OLD_BYTES
	var bytes := PackedByteArray()
	if count > 0:
		var packed := _base64(e as String)
		if packed.is_empty():
			return r
		var raw := packed.decompress(count * width, FileAccess.COMPRESSION_DEFLATE)
		if raw.size() != count * width:
			return r
		bytes.resize(count * BYTES)
		for i in count:
			var at := i * width
			for k in 3:
				if raw[at + k] > RADIUS * 2:
					return r
				bytes[i * BYTES + k] = raw[at + k]
			var ids := [raw[at + 3], raw[at + 4]] if width == OLD_BYTES \
				else [raw[at + 3] | (raw[at + 4] << 8), raw[at + 5] | (raw[at + 6] << 8)]
			for j in 2:
				var id: int = ids[j] if _id_ok(ids[j]) else BlockIds.AIR
				bytes[i * BYTES + 3 + j * 2] = id & 0xff
				bytes[i * BYTES + 4 + j * 2] = id >> 8
	r.start(Vector3i(int(c[0]), int(c[1]), int(c[2])))
	r._bytes = bytes
	return r


static func _id_ok(id: int) -> bool:
	return id == BlockIds.AIR or (id >= 0 and id < BlockIds.COUNT and BlockIds.is_valid(id))


## The bytes of a base64 text, or none (checked first: Marshalls logs an engine error for bad text).
static func _base64(text: String) -> PackedByteArray:
	if text == "" or text.length() % 4 != 0:
		return PackedByteArray()
	for ch in text:
		if not (ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="):
			return PackedByteArray()
	return Marshalls.base64_to_raw(text)
