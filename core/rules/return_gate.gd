class_name ReturnGate
extends RefCounted
## "The portal back stands at the arrival point" (owner feedback #39, spec §14.2a), as pure rules. A child who came
## through a universe portal arrives in front of a portal to the universe they came from: the world's own one when it
## has one (arrival), else the game builds one (plan) a few steps in front of where they stand: a 1 x 2 doorway facing
## them, a whole ring of frames with its corners, that universe's core in the bottom row at their feet's level minus
## one, the doorway and a cell in front of and behind it cleared (so it always has a way out) — never a cell the
## child stands in.

const DISTANCE := 3               # blocks from the child's feet to the doorway


## The world's own portal to universe u: {pos (its exit), yaw (facing away from it)}, or {} when it has none.
static func arrival(gates: PortalGates, u: int) -> Dictionary:
	var core: Variant = gates.gate_to(u)
	if core == null:
		return {}
	var p := gates.shape_of(core)
	var exit: Vector3 = p.exit
	return {"pos": exit, "yaw": PortalRules.exit_yaw(p, exit)}


## The blocks of a new portal to universe u in front of `feet` looking along `yaw`: {edits: [[cell, id], ...] in
## order (the doorway cleared, the frames, the core last), core: Vector3i}; {} when u has no core or feet is not a
## place. block_at(cell) -> int is read for nothing but the child's own cells (kept free whatever stands there).
static func plan(feet: Vector3, yaw: float, u: int, _block_at: Callable = Callable()) -> Dictionary:
	var core_id := CrystalRules.core_of(u)
	if core_id < 0 or not feet.is_finite():
		return {}
	var fwd := _snap(Vector3(-sin(yaw), 0.0, -cos(yaw)))
	var along := Vector3i(absi(fwd.z), 0, absi(fwd.x))   # the doorway runs across the way the child looks
	var foot := Vector3i(feet.floor())
	var lo := foot + fwd * DISTANCE
	var mine: Array[Vector3i] = [foot, foot + Vector3i.UP]
	var edits: Array = []
	for j in 2:
		edits.append([lo + Vector3i(0, j, 0), BlockIds.AIR])
		edits.append([lo - fwd + Vector3i(0, j, 0), BlockIds.AIR])   # room to step out on the child's side ...
		edits.append([lo + fwd + Vector3i(0, j, 0), BlockIds.AIR])   # ... and behind it (a dune or a wall)
	for c: Vector3i in [lo - along + Vector3i.DOWN, lo + along + Vector3i.DOWN, lo - along, lo + along,
			lo - along + Vector3i.UP, lo + along + Vector3i.UP, lo - along + Vector3i(0, 2, 0), lo + Vector3i(0, 2, 0),
			lo + along + Vector3i(0, 2, 0)]:
		edits.append([c, BlockIds.PORTAL_FRAME])
	var core := lo + Vector3i.DOWN
	edits.append([core, core_id])
	var out: Array = []
	for e: Array in edits:
		if not mine.has(e[0]):
			out.append(e)
	return {"edits": out, "core": core}


## The nearest of the four flat directions.
static func _snap(v: Vector3) -> Vector3i:
	if absf(v.x) > absf(v.z):
		return Vector3i(signi(roundi(v.x * 10.0)), 0, 0)
	return Vector3i(0, 0, -1 if v.z < 0.0 else 1)
