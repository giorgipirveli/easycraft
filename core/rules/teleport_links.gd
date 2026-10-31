class_name TeleportLinks
extends RefCounted
## Which teleport pads are linked (M3 Task 7, spec §14.4), a world's own (saved in WorldMeta.smart). A new
## pad links with the nearest pad that has no partner yet; when a pad goes, its partner links again with
## the nearest free pad. At most MAX pads per world. Pure (the host's SmartDirector keeps one).

const MAX := 64
const _FAR := 100000000.0

var _order: Array[Vector3i] = []
var _partner := {}   # pad -> pad


func has(pad: Vector3i) -> bool:
	return _order.has(pad)


## Every pad, in placing order.
func pads() -> Array[Vector3i]:
	return _order.duplicate()


## The linked pad, or null.
func partner_of(pad: Vector3i) -> Variant:
	return _partner.get(pad)


## A pad placed: it links with the nearest free pad. False when it is known or there are MAX.
func add(pad: Vector3i) -> bool:
	if _order.has(pad) or _order.size() >= MAX:
		return false
	_order.append(pad)
	_link(pad)
	return true


## A pad broken (or undone): its partner links again with the nearest free pad.
func remove(pad: Vector3i) -> void:
	if not _order.has(pad):
		return
	_order.erase(pad)
	var other: Variant = _partner.get(pad)
	_partner.erase(pad)
	if other != null:
		_partner.erase(other)
		_link(other)


## Links `pad` (free) with the nearest free pad, if there is one.
func _link(pad: Vector3i) -> void:
	var best: Variant = null
	var best_d := INF
	for other in _order:
		if other == pad or _partner.has(other):
			continue
		var d := Vector3(other - pad).length_squared()
		if d < best_d:
			best_d = d
			best = other
	if best != null:
		_partner[pad] = best
		_partner[best] = pad


## [[x, y, z] or [x, y, z, px, py, pz], ...] in placing order.
func to_save() -> Array:
	var out := []
	for pad in _order:
		var e := [pad.x, pad.y, pad.z]
		var other: Variant = _partner.get(pad)
		if other != null:
			e.append_array([other.x, other.y, other.z])
		out.append(e)
	return out


## Never fails: broken entries are dropped, a pad counted once, a partner that isn't there (or doesn't
## link back) forgotten; free pads then pair up nearest first.
static func from_save(data: Variant) -> TeleportLinks:
	var l := TeleportLinks.new()
	if not data is Array:
		return l
	var wanted := {}
	for entry: Variant in data:
		if not entry is Array or l._order.size() >= MAX:
			continue
		var e: Array = entry
		if (e.size() != 3 and e.size() != 6) or not e.all(_finite):
			continue
		var pad := Vector3i(int(e[0]), int(e[1]), int(e[2]))
		if l._order.has(pad):
			continue
		l._order.append(pad)
		if e.size() == 6:
			wanted[pad] = Vector3i(int(e[3]), int(e[4]), int(e[5]))
	for pad: Vector3i in wanted:
		var other: Vector3i = wanted[pad]
		if other != pad and l._order.has(other) and wanted.get(other) == pad:
			l._partner[pad] = other
	for pad in l._order:
		if not l._partner.has(pad):
			l._link(pad)
	return l


static func _finite(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < _FAR
