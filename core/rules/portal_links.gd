class_name PortalLinks
extends RefCounted
## Which portal cores are linked (M3 Task 5, spec §14.2), a world's own (saved in WorldMeta.portals). Cores
## link in pairs in the order they were placed: the first with the second, the third with the fourth; a
## core whose partner is broken waits and links with the next one placed. A pair works while both have a
## whole frame (shape: PortalRules' portal, {} = no whole frame). At most MAX cores per world.

const MAX := 32
const _FAR := 100000000.0

var order: Array[Vector3i] = []
var _partner := {}   # core -> core
var _shape := {}     # core -> PortalRules portal ({} = no whole frame)


## A new core (placed): links with the core waiting longest. False when it is known or there are MAX.
func add(core: Vector3i) -> bool:
	if order.has(core) or order.size() >= MAX:
		return false
	order.append(core)
	_shape[core] = {}
	_pair()
	return true


## A core broken (or undone): its partner waits for the next one.
func remove(core: Vector3i) -> void:
	if not order.has(core):
		return
	order.erase(core)
	_shape.erase(core)
	if _partner.has(core):
		_partner.erase(_partner[core])
		_partner.erase(core)
	_pair()


func has(core: Vector3i) -> bool:
	return order.has(core)


## The linked core, or null.
func partner_of(core: Vector3i) -> Variant:
	return _partner.get(core)


func shape_of(core: Vector3i) -> Dictionary:
	return _shape.get(core, {})


func set_shape(core: Vector3i, p: Dictionary) -> void:
	if order.has(core):
		_shape[core] = p


## This core's portal and its partner's both have whole frames.
func works(core: Vector3i) -> bool:
	var other: Variant = partner_of(core)
	return other != null and not shape_of(core).is_empty() and not shape_of(other).is_empty()


## Every portal that works (both ends whole), in order: what swirls.
func active() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for core in order:
		if works(core):
			out.append(shape_of(core))
	return out


func _pair() -> void:
	var waiting: Variant = null
	for core in order:
		if _partner.has(core):
			continue
		if waiting == null:
			waiting = core
		else:
			_partner[waiting] = core
			_partner[core] = waiting
			waiting = null


## [{core: [x, y, z], partner?: [x, y, z], axis?, lo?, size?, exit?}, ...] in placing order.
func to_save() -> Array:
	var out := []
	for core in order:
		var e := {"core": [core.x, core.y, core.z]}
		var other: Variant = partner_of(core)
		if other != null:
			e.partner = [other.x, other.y, other.z]
		var p := shape_of(core)
		if not p.is_empty():
			var lo: Vector3i = p.lo
			var size: Vector2i = p.size
			var exit: Vector3 = p.get("exit", Vector3.INF)
			e.axis = int(p.axis)
			e.lo = [lo.x, lo.y, lo.z]
			e.size = [size.x, size.y]
			if exit.is_finite():
				e.exit = [exit.x, exit.y, exit.z]
		out.append(e)
	return out


## Never fails: broken entries are dropped, a partner that isn't in the list (or doesn't link back) is
## forgotten, a shape no frame can have reads as no frame; waiting cores pair up again.
static func from_save(data: Variant) -> PortalLinks:
	var l := PortalLinks.new()
	if not data is Array:
		return l
	var partners := {}
	for entry: Variant in data:
		if not entry is Dictionary or l.order.size() >= MAX:
			continue
		var e: Dictionary = entry
		var core: Variant = _cell(e.get("core"))
		if core == null or l.order.has(core):
			continue
		l.order.append(core)
		l._shape[core] = _parse_shape(core, e)
		var other: Variant = _cell(e.get("partner"))
		if other != null:
			partners[core] = other
	for core: Vector3i in partners:
		var other: Vector3i = partners[core]
		if l.order.has(other) and partners.get(other) == core:
			l._partner[core] = other
	l._pair()
	return l


static func _parse_shape(core: Vector3i, e: Dictionary) -> Dictionary:
	var lo: Variant = _cell(e.get("lo"))
	var size: Variant = e.get("size")
	var axis: Variant = e.get("axis")
	if lo == null or not size is Array or (size as Array).size() != 2 or not typeof(axis) in [TYPE_INT, TYPE_FLOAT]:
		return {}
	if not (size as Array).all(func(v: Variant) -> bool: return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))):
		return {}
	var w := int(size[0])
	var h := int(size[1])
	var a := int(axis)
	if a not in [PortalRules.AXIS_X, PortalRules.AXIS_Z] or w < PortalRules.MIN_WIDTH or w > PortalRules.MAX_WIDTH \
			or h < PortalRules.MIN_HEIGHT or h > PortalRules.MAX_HEIGHT:
		return {}
	var p := {"core": core, "axis": a, "lo": lo, "size": Vector2i(w, h), "exit": Vector3.INF}
	if not PortalRules.ring_cells(p).has(core) or (lo as Vector3i).y != core.y + 1:
		return {}
	var exit: Variant = e.get("exit")
	if exit is Array and (exit as Array).size() == 3 and (exit as Array).all(_finite):
		var at := Vector3(float(exit[0]), float(exit[1]), float(exit[2]))
		if at.distance_to(PortalRules.center(p)) < 4.0:
			p.exit = at
	return p


static func _cell(v: Variant) -> Variant:
	if not v is Array or (v as Array).size() != 3 or not (v as Array).all(_finite):
		return null
	return Vector3i(int(v[0]), int(v[1]), int(v[2]))


static func _finite(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < _FAR
