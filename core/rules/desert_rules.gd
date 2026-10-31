class_name DesertRules
extends RefCounted
## The Sandstorm Desert's hazards as pure rules (M3 Task 2, spec §14.1 "pyramids with traps").
## - A cactus pushes whoever walks into it a little, with a small hop (never hurts; the brief: "decide
##   gently").
## - An arrow slit (DesertSecretRules' pyramids: {cell, dir}) shoots a dart across the corridor when a
##   child stands in its lane: a click and a puff of dust first (DART_DELAY), then the dart; it hurts
##   whoever is still in the lane (DART_DAMAGE, gentle). The sand pit needs no rules: its lid is trap sand.

const BODY_RADIUS := 0.3          # a child's half width (Player's capsule)
const TOUCH := 0.12               # this close to a cactus's face counts as walking into it
const CACTUS_PUSH := 4.0          # m/s away from it ...
const CACTUS_HOP := 2.5           # ... and a little up
const CACTUS_COOLDOWN := 0.8
const CACTUS_DAMAGE := 0
const LANE := 4                   # the dart crosses this many cells in front of its slit
const DART_DELAY := 0.6
const DART_COOLDOWN := 3.0
const DART_DAMAGE := 2
const DART_SPEED := 14.0          # the picture's speed (the hit is decided when it flies)
const SIDES: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]


## The push a child whose feet are at `feet` gets from the cacti they touch (at their feet, their head or
## under them), or ZERO. block_at(cell) -> id.
static func cactus_push(feet: Vector3, block_at: Callable) -> Vector3:
	var push := Vector3.ZERO
	var cell := Vector3i(feet.floor())
	for dy in 2:
		for side in SIDES:
			var c := cell + side + Vector3i(0, dy, 0)
			if block_at.call(c) != BlockIds.CACTUS:
				continue
			# the gap between the body's edge and the cactus's face on that side
			var face := float(c.x) if side.x > 0 else (float(c.x) + 1.0 if side.x < 0 else 0.0)
			var gap := face - feet.x if side.x > 0 else (feet.x - face if side.x < 0 else 0.0)
			if side.z != 0:
				face = float(c.z) if side.z > 0 else float(c.z) + 1.0
				gap = face - feet.z if side.z > 0 else feet.z - face
			if gap - BODY_RADIUS <= TOUCH:
				push -= Vector3(side)
	if block_at.call(cell + Vector3i.DOWN) == BlockIds.CACTUS:
		push += Vector3(0.0, 1.0, 0.0)
	if push == Vector3.ZERO:
		return push
	var flat := Vector3(push.x, 0.0, push.z)
	var out := flat.normalized() * CACTUS_PUSH if flat.length() > 0.01 else Vector3.ZERO
	return out + Vector3.UP * CACTUS_HOP


## Does a child whose feet are at `feet` stand in the lane of trap {cell, dir}? The lane is LANE cells in
## front of the slit, at the slit's height and the one below (head and body).
static func in_lane(trap: Dictionary, feet: Vector3) -> bool:
	var cell: Vector3i = trap.cell
	var dir: Vector3i = trap.dir
	var f := Vector3i(feet.floor())
	if f.y < cell.y - 1 or f.y > cell.y:
		return false
	for k in range(1, LANE + 1):
		var c := cell + dir * k
		if f.x == c.x and f.z == c.z:
			return true
	return false
