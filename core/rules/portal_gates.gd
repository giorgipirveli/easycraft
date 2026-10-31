class_name PortalGates
extends RefCounted
## A world's universe portals (owner feedback #39, spec §14.2a), saved in WorldMeta.gates: frame rings (PortalRules)
## with a universe crystal's core in their core slot. Each leads to its core's universe and needs no partner; it
## works while its frame is whole (shape: PortalRules' portal with its exit; {} = no whole frame). At most MAX per
## world, in placing order (the first working one to a universe is where a traveller from there arrives).

const MAX := 32
const _FAR := 100000000.0

var order: Array[Vector3i] = []
var _universe := {}   # core -> universe
var _shape := {}      # core -> PortalRules portal ({} = no whole frame)


## A universe core placed (or loaded): false when it is known already or there are MAX.
func add(core: Vector3i, universe: int) -> bool:
	if order.has(core) or order.size() >= MAX or not CrystalRules.CORES.has(universe):
		return false
	order.append(core)
	_universe[core] = universe
	_shape[core] = {}
	return true


func remove(core: Vector3i) -> void:
	order.erase(core)
	_universe.erase(core)
	_shape.erase(core)


func has(core: Vector3i) -> bool:
	return order.has(core)


func universe_of(core: Vector3i) -> int:
	return int(_universe.get(core, 0))


func shape_of(core: Vector3i) -> Dictionary:
	return _shape.get(core, {})


func set_shape(core: Vector3i, p: Dictionary) -> void:
	if order.has(core):
		_shape[core] = p


func works(core: Vector3i) -> bool:
	return not shape_of(core).is_empty()


## Every working universe portal, in order, each its PortalRules portal plus `universe` (what swirls, and in which
## colours).
func active() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for core in order:
		if works(core):
			var p := shape_of(core).duplicate()
			p.universe = universe_of(core)
			out.append(p)
	return out


## The first working portal to universe u whose exit is open (where a traveller from u arrives), or null.
func gate_to(u: int) -> Variant:
	for core in order:
		if universe_of(core) == u and works(core) and (shape_of(core).get("exit", Vector3.INF) as Vector3).is_finite():
			return core
	return null


## [{core: [x, y, z], universe, axis?, lo?, size?, exit?}, ...] in placing order.
func to_save() -> Array:
	var out := []
	for core in order:
		var e := {"core": [core.x, core.y, core.z], "universe": universe_of(core)}
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


## Never fails: an entry without a good core or universe is dropped; a frame no portal can have reads as none.
static func from_save(data: Variant) -> PortalGates:
	var g := PortalGates.new()
	if not data is Array:
		return g
	for entry: Variant in data:
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry
		var core: Variant = _cell(e.get("core"))
		var u: Variant = e.get("universe")
		if core == null or not typeof(u) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(u)):
			continue
		if g.add(core, int(u)):
			g._shape[core] = PortalLinks._parse_shape(core, e)
	return g


static func _cell(v: Variant) -> Variant:
	if not v is Array or (v as Array).size() != 3:
		return null
	for c: Variant in v:
		if not typeof(c) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(c)) or absf(float(c)) >= _FAR:
			return null
	return Vector3i(int(v[0]), int(v[1]), int(v[2]))
