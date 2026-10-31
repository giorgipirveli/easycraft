class_name RecordedRun
extends RefCounted
## Where a runner was, DT apart (10 times a second, positions only), for at most MAX_SAMPLES (3 minutes)
## (M3 Task 7). A bot friend replays a course's best run as its own (cheap, no pathfinding); M4's ghost
## races can reuse it. Saved compact: each sample as three 16-bit decimetres from `origin` (the START's
## top), base64 — 3 minutes are about 14 KB; checked when loaded.

const DT := 0.1
const MAX_SAMPLES := 1800
const SCALE := 10.0              # decimetres
const _LIMIT := 32767
const _FAR := 100000000.0

var origin := Vector3.ZERO
var points := PackedVector3Array()
## True once a sample was refused (the run went on longer than MAX_SAMPLES): not kept whole.
var full := false


func _init(start: Vector3 = Vector3.ZERO) -> void:
	origin = start


## One more sample (the next DT). False when the recording is full.
func add(pos: Vector3) -> bool:
	if points.size() >= MAX_SAMPLES or not pos.is_finite():
		full = full or points.size() >= MAX_SAMPLES
		return false
	points.append(pos)
	return true


func size() -> int:
	return points.size()


## Seconds from the first sample to the last.
func duration() -> float:
	return maxf(points.size() - 1, 0) * DT


## Where the runner was at `t` seconds (between two samples; the ends outside).
func sample_at(t: float) -> Vector3:
	if points.is_empty():
		return origin
	var f := clampf(t / DT, 0.0, points.size() - 1)
	var i := floori(f)
	if i >= points.size() - 1:
		return points[points.size() - 1]
	return points[i].lerp(points[i + 1], f - i)


## The level way the runner was going at `t` (ZERO when standing).
func facing_at(t: float) -> Vector3:
	var d := sample_at(t + DT * 0.5) - sample_at(t - DT * 0.5)
	d.y = 0.0
	return d.normalized() if d.length() > 0.001 else Vector3.ZERO


## {"o": [x, y, z], "p": base64 of little-endian int16 triplets (decimetres from o, clamped)}.
func to_save() -> Dictionary:
	var bytes := PackedByteArray()
	bytes.resize(points.size() * 6)
	for i in points.size():
		var d := (points[i] - origin) * SCALE
		for k in 3:
			bytes.encode_s16(i * 6 + k * 2, clampi(roundi(d[k]), -_LIMIT, _LIMIT))
	return {"o": [origin.x, origin.y, origin.z], "p": Marshalls.raw_to_base64(bytes)}


## A recorded run from its save, or null when anything about it is broken (not base64, not whole
## samples, fewer than 2 or more than MAX_SAMPLES, a bad origin).
static func from_save(data: Variant) -> RecordedRun:
	if not data is Dictionary:
		return null
	var o: Variant = (data as Dictionary).get("o")
	var p: Variant = (data as Dictionary).get("p")
	if not o is Array or (o as Array).size() != 3 or not (o as Array).all(_finite) or not p is String:
		return null
	var text: String = p
	if text.length() % 4 != 0 or text.length() > (MAX_SAMPLES * 6 / 3 + 1) * 4 or not _is_base64(text):
		return null
	var bytes := Marshalls.base64_to_raw(text)
	var n := bytes.size() / 6
	if bytes.size() % 6 != 0 or n < 2 or n > MAX_SAMPLES:
		return null
	var r := RecordedRun.new(Vector3(float(o[0]), float(o[1]), float(o[2])))
	for i in n:
		r.points.append(r.origin + Vector3(bytes.decode_s16(i * 6), bytes.decode_s16(i * 6 + 2),
			bytes.decode_s16(i * 6 + 4)) / SCALE)
	return r


static var _base64 := RegEx.create_from_string("^[A-Za-z0-9+/]*={0,2}$")


static func _is_base64(text: String) -> bool:
	return _base64.search(text) != null


static func _finite(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < _FAR
