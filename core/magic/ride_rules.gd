class_name RideRules
extends RefCounted
## Rideable buddies (M3 Task 20a, spec §16 "the dragon you built and fly"). A buddy built with a SADDLE block
## can be ridden, and what it does comes from its shape:
## - WINGS (blocks sticking out left and right in its upper half, at least 2 each side): it FLIES like a
##   dragon. The stick steers, JUMP climbs, CROUCH dives.
## - WHEELS (blocks at the four bottom corners, with a gap between the front and back ones): it DRIVES like a
##   car. It turns, bumps gently off walls and climbs 1 block, never 2.
## - On WATER, anything but a flyer SAILS like a boat.
## - Anything else is a gentle WALK mount: the player's speed + 20 %.
## Nothing rides faster than M2's paid Fly (Player.FLY_SPEED). Pure: blocks are the Buddy's (Vector3i offset,
## min corner 0 -> id). A buddy's face is its -z side, so its left and right are -x and +x.

## Owner #41 (spec §14.19): GALLOP (a saddled horse) and TREK (a saddled camel) are animal mounts (AnimalRideRules);
## they turn as they like, like WALK. Appended, so the synced numbers of the others stay.
enum Kind { NONE, WALK, FLY, DRIVE, SAIL, GALLOP, TREK }

## Top speeds (m/s, level). WALK is Player.WALK_SPEED (6) + 20 %; FLY is Player.FLY_SPEED (11), under the
## brief's 12, so a dragon never beats paid Fly. Owner #41: a horse gallops at 9.5 (capped under the paid Fly),
## a camel treks at 6.5.
const SPEED := {Kind.WALK: 7.2, Kind.FLY: 11.0, Kind.DRIVE: 10.0, Kind.SAIL: 6.0, Kind.GALLOP: 9.5, Kind.TREK: 6.5}
const ACCEL := {Kind.WALK: 30.0, Kind.FLY: 12.0, Kind.DRIVE: 10.0, Kind.SAIL: 5.0, Kind.GALLOP: 14.0, Kind.TREK: 10.0}
## How fast it turns to face the stick (radians a second); a walk mount turns as it likes.
const TURN := {Kind.WALK: 10.0, Kind.FLY: 3.2, Kind.DRIVE: 2.4, Kind.SAIL: 1.6, Kind.GALLOP: 8.0, Kind.TREK: 6.0}
## The mounts that go where the stick points and turn to face it (the others steer by facing).
const FREE_TURN: Array[int] = [Kind.WALK, Kind.GALLOP, Kind.TREK]
## Facing away from the stick it still goes this share of its speed forward while it turns (a turning circle).
const MIN_ALIGN := {Kind.FLY: 0.35, Kind.DRIVE: 0.25, Kind.SAIL: 0.2}
const FLY_CLIMB := 6.0
const FLY_DIVE := 8.0
const FLY_VERTICAL_ACCEL := 16.0
## A bump off a wall: this share of the speed into the wall comes back out, and the rest slides on at half.
const BUMP_BACK := 0.3
const BUMP_SLIDE := 0.5
## Getting on: the player's feet within this many blocks of the buddy's side (the host allows a little more).
const MOUNT_REACH := 2.5
const HOST_TOLERANCE := 1.0
## The host decides (water, steps, landings, riders) 10 times a second; the rider's stick goes to the host at
## most 20 times a second (and every quarter second while held), and a stick not heard for 0.6 s lets go.
const DECIDE_EVERY := 0.1
const INPUT_EVERY := 0.05
const INPUT_KEEPALIVE := 0.25
const INPUT_STALE := 0.6
## A flyer off the ground this long has taken off (Survivor: its ride ends when it lands again).
const AIRBORNE_AFTER := 0.4
## A boat floats this deep in the water.
const DRAFT := 0.35
## Hop heights (blocks) onto a 1-block step; a boat hops from the water onto a bank.
const HOP_HEIGHT := 1.25
const SAIL_HOP_HEIGHT := 1.7
const NO_SADDLE := Vector3i(0, -1, 0)


static func has_saddle(blocks: Dictionary) -> bool:
	return blocks.values().has(BlockIds.SADDLE)


## The saddle the rider sits on: the highest one (then the front-most, then the left-most); NO_SADDLE for none.
static func saddle_of(blocks: Dictionary) -> Vector3i:
	var best := NO_SADDLE
	for p: Vector3i in blocks:
		if blocks[p] != BlockIds.SADDLE:
			continue
		if best == NO_SADDLE or p.y > best.y or (p.y == best.y and (p.z < best.z or (p.z == best.z and p.x < best.x))):
			best = p
	return best


static func size_of(blocks: Dictionary) -> Vector3i:
	var mx := Vector3i.ZERO
	for p: Vector3i in blocks:
		mx = Vector3i(maxi(mx.x, p.x), maxi(mx.y, p.y), maxi(mx.z, p.z))
	return mx + Vector3i.ONE if not blocks.is_empty() else Vector3i.ZERO


## Where the rider's feet go, in the buddy's own space (its feet at the middle of its footprint): on top of the saddle.
static func seat_offset(blocks: Dictionary, size: Vector3i) -> Vector3:
	var s := saddle_of(blocks)
	if s == NO_SADDLE:
		return Vector3(0.0, size.y, 0.0)
	return Vector3(s.x + 0.5 - size.x * 0.5, s.y + 1.0, s.z + 0.5 - size.z * 0.5)


## What a buddy with these blocks does when ridden (NONE without a saddle).
static func kind_of(blocks: Dictionary) -> int:
	if not has_saddle(blocks):
		return Kind.NONE
	if not wings_along(blocks, 0).is_empty() or not wings_along(blocks, 2).is_empty():
		return Kind.FLY
	if has_wheels_along(blocks, 2) or has_wheels_along(blocks, 0):
		return Kind.DRIVE
	return Kind.WALK


## Its wings left and right ({"left": cells, "right": cells}), or {} when it has none.
static func wings(blocks: Dictionary) -> Dictionary:
	return wings_along(blocks, 0)


## Wings sticking out along `axis` (0: x, left and right; 2: z): the cells of its upper half (from the middle
## row up) beyond both ends of its lower half along that axis, at least 2 on each side; {} otherwise.
static func wings_along(blocks: Dictionary, axis: int) -> Dictionary:
	var size := size_of(blocks)
	var half := size.y / 2
	var lo := 1 << 30
	var hi := -(1 << 30)
	for p: Vector3i in blocks:
		if p.y < half:
			lo = mini(lo, p[axis])
			hi = maxi(hi, p[axis])
	if lo > hi:
		return {}   # no lower half (one layer high): nothing to stick out from
	var left: Array[Vector3i] = []
	var right: Array[Vector3i] = []
	for p: Vector3i in blocks:
		if p.y >= half and p[axis] < lo:
			left.append(p)
		elif p.y >= half and p[axis] > hi:
			right.append(p)
	if left.size() < 2 or right.size() < 2:
		return {}
	return {"left": left, "right": right}


## Wheels: its bottom layer has blocks at the four corners, the front and back ones at least 2 apart along
## `axis` with a gap between them on both sides, and it is more than one layer high.
static func has_wheels_along(blocks: Dictionary, axis: int) -> bool:
	var other := 2 if axis == 0 else 0
	if size_of(blocks).y < 2:
		return false
	var a0 := 1 << 30
	var a1 := -(1 << 30)
	var b0 := 1 << 30
	var b1 := -(1 << 30)
	for p: Vector3i in blocks:
		if p.y == 0:
			a0 = mini(a0, p[axis])
			a1 = maxi(a1, p[axis])
			b0 = mini(b0, p[other])
			b1 = maxi(b1, p[other])
	if a1 - a0 < 2 or b1 <= b0:
		return false
	for a in [a0, a1]:
		for b in [b0, b1]:
			if not blocks.has(_cell(axis, a, b)):
				return false
	for b in [b0, b1]:
		var gap := false
		for a in range(a0 + 1, a1):
			if not blocks.has(_cell(axis, a, b)):
				gap = true
				break
		if not gap:
			return false
	return true


static func _cell(axis: int, a: int, b: int) -> Vector3i:
	return Vector3i(a, 0, b) if axis == 0 else Vector3i(b, 0, a)


## A saddled buddy whose wings stick out along z (or whose wheels are apart along x) turns a quarter so it
## flies or drives forwards (its face, -z, looks where it goes): {"blocks", "yaw" (keeps its look in the world),
## "turned"}. Anything else comes back as it is.
static func normalise(blocks: Dictionary) -> Dictionary:
	var turn := false
	if has_saddle(blocks) and wings_along(blocks, 0).is_empty():
		if not wings_along(blocks, 2).is_empty():
			turn = true
		elif not has_wheels_along(blocks, 2) and has_wheels_along(blocks, 0):
			turn = true
	if not turn:
		return {"blocks": blocks, "yaw": 0.0, "turned": false}
	var size := size_of(blocks)
	var out := {}
	for p: Vector3i in blocks:
		out[Vector3i(p.z, p.y, size.x - 1 - p.x)] = blocks[p]
	return {"blocks": out, "yaw": -PI * 0.5, "turned": true}


## What it does now: a flyer flies anywhere; anything else on water sails.
static func mode(kind: int, on_water: bool) -> int:
	if kind == Kind.NONE or kind == Kind.FLY:
		return kind
	return Kind.SAIL if on_water else kind


## The short line when a saddled buddy wakes ("" without a saddle).
static func wake_line(kind: int, on_water: bool) -> String:
	match mode(kind, on_water):
		Kind.FLY:
			return "Your dragon can fly!"
		Kind.DRIVE:
			return "Vroom! A car!"
		Kind.SAIL:
			return "Ahoy! A boat!"
		Kind.WALK:
			return "Giddy-up! You can ride it!"
	return ""


## What the rider hears on getting on.
static func mount_line(ride_mode: int) -> String:
	match ride_mode:
		Kind.FLY:
			return "Up we go! JUMP climbs, CROUCH dives."
		Kind.DRIVE:
			return "Vroom! Steer with the stick."
		Kind.SAIL:
			return "Ahoy! Sail on the water."
		Kind.GALLOP:
			return "Giddy-up! Gallop with the stick. JUMP hops off."
		Kind.TREK:
			return "Off we go, slow and steady! JUMP hops off."
	return "Giddy-up! JUMP hops off."


## Water at (or just under) its feet.
static func on_water(feet: Vector3, get_block: Callable) -> bool:
	return get_block.call(Vector3i((feet + Vector3(0, 0.2, 0)).floor())) == BlockIds.WATER \
		or get_block.call(Vector3i((feet - Vector3(0, 0.3, 0)).floor())) == BlockIds.WATER


## The height of the water's top around its feet, or NAN with no water there.
static func water_surface(feet: Vector3, get_block: Callable) -> float:
	var x := floori(feet.x)
	var z := floori(feet.z)
	var y := floori(feet.y - 0.5)
	if get_block.call(Vector3i(x, y, z)) != BlockIds.WATER:
		y += 1
		if get_block.call(Vector3i(x, y, z)) != BlockIds.WATER:
			return NAN
	for i in 64:
		if get_block.call(Vector3i(x, y + 1, z)) != BlockIds.WATER:
			break
		y += 1
	return y + 1.0


## One step of a ridden buddy: the stick `wish` (world x/z, length up to 1) and `vertical` (-1 dive .. 1 climb,
## flyers only) move it towards its target speed. Gravity and hops are the body's. {"velocity", "yaw"}.
static func step(ride_mode: int, velocity: Vector3, yaw: float, wish: Vector3, vertical: float, delta: float) -> Dictionary:
	var v := velocity
	var flat := Vector3(wish.x, 0.0, wish.z).limit_length(1.0)
	var amount := flat.length()
	var target := Vector3.ZERO
	if ride_mode in FREE_TURN:
		target = flat * float(SPEED[ride_mode])
		if amount > 0.1:
			yaw = lerp_angle(yaw, atan2(-flat.x, -flat.z), clampf(float(TURN[ride_mode]) * delta, 0.0, 1.0))
	elif SPEED.has(ride_mode) and amount > 0.1:
		var want := atan2(-flat.x, -flat.z)
		var turn := float(TURN[ride_mode]) * delta
		yaw += clampf(angle_difference(yaw, want), -turn, turn)
		var align := maxf(cos(angle_difference(yaw, want)), float(MIN_ALIGN[ride_mode]))
		target = Basis(Vector3.UP, yaw) * Vector3.FORWARD * float(SPEED[ride_mode]) * amount * align
	var h := Vector3(v.x, 0.0, v.z).move_toward(target, float(ACCEL.get(ride_mode, 0.0)) * delta)
	v.x = h.x
	v.z = h.z
	if ride_mode == Kind.FLY:
		var up := clampf(vertical, -1.0, 1.0)
		v.y = move_toward(v.y, FLY_CLIMB * up if up > 0.0 else FLY_DIVE * up, FLY_VERTICAL_ACCEL * delta)
	return {"velocity": capped(ride_mode, v), "yaw": wrapf(yaw, -PI, PI)}


## Never faster than the mode's top speed (and a flyer climbs and dives at most its own rates).
static func capped(ride_mode: int, v: Vector3) -> Vector3:
	var top := float(SPEED.get(ride_mode, 0.0))
	var h := Vector2(v.x, v.z)
	if h.length() > top:
		h = h.normalized() * top
	var y := clampf(v.y, -FLY_DIVE, FLY_CLIMB) if ride_mode == Kind.FLY else v.y
	return Vector3(h.x, y, h.y)


## A gentle bump off a wall (its normal): some of the speed into it comes back, the rest slides on slower.
static func bump(v: Vector3, normal: Vector3) -> Vector3:
	var n := Vector3(normal.x, 0.0, normal.z)
	if n.length() < 0.01:
		return v
	n = n.normalized()
	var h := Vector3(v.x, 0.0, v.z)
	var into := -h.dot(n)
	if into <= 0.0:
		return v
	h = (h + n * into) * BUMP_SLIDE + n * into * BUMP_BACK
	return Vector3(h.x, v.y, h.z)


## A body resting on the ground may sit a little into it (a buddy's box starts just above its feet): its feet's
## cell is the one FEET_LIFT above them.
const FEET_LIFT := 0.25


## How many blocks high the ground rises `reach` ahead of `feet` going `dir` (0 flat, up to 3).
static func climb_height(feet: Vector3, dir: Vector3, reach: float, is_solid: Callable) -> int:
	var d := Vector3(dir.x, 0.0, dir.z)
	if d.length() < 0.01:
		return 0
	var ahead := feet + d.normalized() * reach
	var base := Vector3i(floori(ahead.x), floori(feet.y + FEET_LIFT), floori(ahead.z))
	var h := 0
	while h < 3 and is_solid.call(base + Vector3i(0, h, 0)):
		h += 1
	return h


## Walkers, cars and boats hop onto a 1-block step; 2 blocks stop them (a car bumps); flyers fly up.
static func wants_hop(ride_mode: int, height: int) -> bool:
	return height == 1 and ride_mode in [Kind.WALK, Kind.DRIVE, Kind.SAIL, Kind.GALLOP, Kind.TREK]


static func hop_velocity(ride_mode: int, gravity: float) -> float:
	return sqrt(2.0 * gravity * (SAIL_HOP_HEIGHT if ride_mode == Kind.SAIL else HOP_HEIGHT))


## Is a player's `feet` close enough to get on a buddy standing at `center` (its feet) of `size`?
static func can_mount(feet: Vector3, center: Vector3, size: Vector3i, tolerance := 0.0) -> bool:
	if not feet.is_finite() or not center.is_finite():
		return false
	var reach := maxf(size.x, size.z) * 0.5 + MOUNT_REACH + tolerance
	if Vector2(feet.x - center.x, feet.z - center.z).length() > reach:
		return false
	return feet.y >= center.y - 2.0 - tolerance and feet.y <= center.y + size.y + 1.5 + tolerance


## Where a rider gets off (feet, in the middle of a cell), never inside blocks: beside the buddy (left, right,
## behind, in front; level, a step up, a step down, two up) on ground if any, else the first free spot beside it
## (a flyer in the air: the rider drifts down), else on top of it.
static func dismount_spot(center: Vector3, size: Vector3i, yaw: float, is_solid: Callable) -> Vector3:
	var hx := size.x * 0.5 + 0.7
	var hz := size.z * 0.5 + 0.7
	var turn := Basis(Vector3.UP, yaw)
	var sides: Array[Vector3] = [Vector3(-hx, 0, 0), Vector3(hx, 0, 0), Vector3(0, 0, hz), Vector3(0, 0, -hz)]
	var y0 := floori(center.y + FEET_LIFT)
	var free := Vector3.INF
	for dy: int in [0, 1, -1, 2]:
		for side in sides:
			var at := center + turn * side
			var cell := Vector3i(floori(at.x), y0 + dy, floori(at.z))
			if not _room(cell, is_solid):
				continue
			var spot := Vector3(cell.x + 0.5, cell.y + 0.01, cell.z + 0.5)
			if is_solid.call(cell + Vector3i.DOWN):
				return spot
			if not free.is_finite():
				free = spot
	if free.is_finite():
		return free
	var top := Vector3i(floori(center.x), y0 + maxi(size.y, 1), floori(center.z))
	for i in 64:
		if _room(top, is_solid):
			break
		top.y += 1
	return Vector3(top.x + 0.5, top.y + 0.01, top.z + 0.5)


static func _room(cell: Vector3i, is_solid: Callable) -> bool:
	return not is_solid.call(cell) and not is_solid.call(cell + Vector3i.UP)


## Survivor (no free flying): a flight lasts until the flyer lands again after taking off.
static func ride_over(ride_mode: int, free_fly: bool, was_airborne: bool, on_floor: bool) -> bool:
	return ride_mode == Kind.FLY and not free_fly and was_airborne and on_floor


## The host's copy of a rider's stick: finite, level part no longer than 1, up/down in -1..1.
static func clean_wish(wish: Vector3) -> Vector3:
	if not wish.is_finite():
		return Vector3.ZERO
	var h := Vector2(wish.x, wish.z).limit_length(1.0)
	return Vector3(h.x, clampf(wish.y, -1.0, 1.0), h.y)
