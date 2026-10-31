class_name VehicleRules
extends RefCounted
## Owner #109 (spec §3b "Cars"): driving and flying a ready-made car (CarKinds), as pure rules shared by the host (it
## moves every car: Vehicle) and the games (the RIDE button, the garage). Arcade and kind:
## - the stick's forward and back speed the car up to its top speed and back it up slowly; letting go rolls it to a
##   stop; left and right turn it (fully from TURN_FULL_SPEED, a little even standing still: a child is never stuck);
##   it grips the ground (never slides sideways); in the air a ground car keeps going and does not steer;
## - it hops up a step it can climb (CarKinds.climb) and bumps off a higher one (RideRules.bump); a body in its way stops
##   it and is pushed gently aside (push_aside), never run over;
## - a flying car flies like the dragon, gently: forward and back, turns on the spot, JUMP climbs, CROUCH dives, let go
##   it hovers; never over its ceiling (ceiling_y: FLY_CEILING, and a hover car its few blocks over the ground);
## - in water a ground car floats like a boat at FLOAT_SPEED (RideRules' water rules).
## The host decides who gets in (can_board, free_seat: the first in drives), where a called car goes (place_spot), which
## car goes home when a child has too many out (goes_home); the garage's ownership lives in the profile (owned_kinds).

const GRAVITY := 20.0
const BRAKE := 18.0               # m/s²: pressing against the way it goes
const COAST := 3.5                # m/s²: nothing pressed, it rolls to a stop
const GRIP := 40.0                # m/s²: any sideways slide is gone this quickly
const TURN_FULL_SPEED := 4.0      # m/s: from this speed it turns at its full rate
const TURN_STILL := 0.35          # the share of its turn standing still
const FLOAT_SPEED := 3.0          # m/s: a ground car paddling in water
## Flying: gentler than the dragon (RideRules.FLY_CLIMB 6, FLY_DIVE 8).
const FLY_CLIMB := 5.0
const FLY_DIVE := 6.0
const FLY_VERTICAL_ACCEL := 12.0
const FLY_ACCEL := 8.0
## The highest a flying car goes: under the sky's darkening (SpaceRules.CLIMB_FROM 160) and far under the space line (200):
## a car never takes a child to space (the rocket does).
const FLY_CEILING := SpaceRules.CLIMB_FROM - 10.0
const SINK_OVER := 2.0            # m/s down when over the ceiling
## A take-off's first push up, and how fast a LAND comes down.
const TAKE_OFF := 4.0
const LAND_SPEED := 4.0
const HOP_EXTRA := 0.3            # a hop clears its step by this much
const HOP_FORWARD := 3.0          # m/s: a hop keeps going over the step at least this fast
## A body in the way: pushed aside this fast (m/s), with a little hop; a body is pushed at most this often.
const PUSH := 3.0
const PUSH_UP := 2.0
const PUSH_EVERY := 0.5
## Getting in: the feet within this many blocks of the car's side (the host allows a little more: a guest's lag).
const BOARD_REACH := 2.5
const HOST_TOLERANCE := 1.0
## The host decides (water, steps, landings, riders) 10 times a second; the driver's stick comes as the rides' does.
const DECIDE_EVERY := 0.1
const INPUT_STALE := RideRules.INPUT_STALE
const HORN_EVERY := 0.8
## A world holds at most this many cars; a child has at most PER_PLAYER out at once (one of each kind).
const MAX_CARS := 12
const PER_PLAYER := 4
## The pickup's bed: at most CARGO_MAX blocks of up to CARGO_KINDS kinds; a tap loads LOAD_STEP; CARGO_SHOWN cubes show.
const CARGO_MAX := 32
const CARGO_KINDS := 4
const LOAD_STEP := 8
const CARGO_SHOWN := 8
## The camera swings round behind a car going faster than this, this quickly (radians a second at most).
const CHASE_FROM := 2.0
const CHASE_RATE := 1.6
## A called car's place: this far past the car's own half size in front of the child (else beside or behind; a little
## further when those are taken: never out of BOARD_REACH).
const PLACE_GAP := 1.4
const STOP := 0.05

const OWNED_PREFIX := "car:"

const _WORDS := {
	"not_owned": "Buy the %s in the garage first!",
	"unknown": "That car isn't in the garage.",
	"too_far": "Get closer to the car!",
	"full": "That car is full!",
	"busy": "You can't get in right now.",
	"no_room": "No room for your %s here! Try a flat, open spot.",
	"world_full": "There are lots of cars here already! Call one you have.",
	"ridden": "Someone is in your %s! Wait for them to hop off.",
	"arena": "No cars in the arena!",
	"gold": "You need more gold for the %s!",
	"owned": "The %s is yours already! CALL it.",
	"bed_full": "The truck's bed is full!",
	"not_a_block": "Hold some blocks to load the truck!",
	"no_blocks": "You don't have those blocks!",
}


## A synced or sent stick, checked: finite, each part in -1..1 (x: steer right, y: up/down, z: forward).
static func clean_input(wish: Vector3) -> Vector3:
	if not wish.is_finite():
		return Vector3.ZERO
	return Vector3(clampf(wish.x, -1.0, 1.0), clampf(wish.y, -1.0, 1.0), clampf(wish.z, -1.0, 1.0))


## One step on the ground (or floating): `steer` -1 left .. 1 right, `throttle` -1 back .. 1 forward. In the air (not
## on_floor) a ground car keeps what it had. `parked`: nobody drives it: it brakes to a stop at once (an empty car never
## rolls off alone). {"velocity", "yaw"}; gravity and hops are the body's.
static func drive_step(kind: StringName, velocity: Vector3, yaw: float, steer: float, throttle: float, on_floor: bool,
		delta: float, top_speed: float = -1.0, parked: bool = false) -> Dictionary:
	steer = clampf(steer, -1.0, 1.0)
	throttle = clampf(throttle, -1.0, 1.0)
	if not on_floor:
		return {"velocity": velocity, "yaw": yaw}
	var top := CarKinds.speed(kind) if top_speed < 0.0 else top_speed
	var fwd := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	var h := Vector3(velocity.x, 0.0, velocity.z)
	var f := h.dot(fwd)
	var side := h - fwd * f
	var target := 0.0
	var rate := BRAKE if parked else COAST
	if throttle > 0.0:
		target = top * throttle
		rate = CarKinds.accel(kind) if f >= -0.1 else BRAKE
	elif throttle < 0.0:
		target = -minf(CarKinds.reverse_speed(kind), top) * -throttle
		rate = BRAKE if f > 0.1 else CarKinds.accel(kind)
	f = move_toward(f, target, rate * delta)
	side = side.move_toward(Vector3.ZERO, GRIP * delta)
	if absf(steer) > 0.05:
		var share := clampf(absf(f) / TURN_FULL_SPEED, TURN_STILL, 1.0)
		var way := -1.0 if f < -0.5 or (absf(f) <= 0.5 and throttle < 0.0) else 1.0
		yaw -= steer * CarKinds.turn(kind) * share * way * delta
	fwd = Basis(Vector3.UP, yaw) * Vector3.FORWARD
	h = (fwd * f + side).limit_length(maxf(top, CarKinds.reverse_speed(kind)))
	return {"velocity": Vector3(h.x, velocity.y, h.z), "yaw": wrapf(yaw, -PI, PI)}


## One step in the air (a flying car): forward and back, turns on the spot, `vertical` 1 climbs .. -1 dives, 0 hovers.
static func fly_step(kind: StringName, velocity: Vector3, yaw: float, steer: float, throttle: float, vertical: float,
		delta: float) -> Dictionary:
	steer = clampf(steer, -1.0, 1.0)
	throttle = clampf(throttle, -1.0, 1.0)
	vertical = clampf(vertical, -1.0, 1.0)
	var top := CarKinds.fly_speed(kind)
	if absf(steer) > 0.05:
		yaw -= steer * CarKinds.turn(kind) * delta
	var fwd := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	var h := Vector3(velocity.x, 0.0, velocity.z)
	var f := h.dot(fwd)
	var side := h - fwd * f
	var target := top * throttle if throttle >= 0.0 else -minf(CarKinds.reverse_speed(kind), top) * -throttle
	f = move_toward(f, target, (FLY_ACCEL if throttle != 0.0 else COAST * 2.0) * delta)
	side = side.move_toward(Vector3.ZERO, GRIP * delta)
	h = (fwd * f + side).limit_length(top)
	var want := FLY_CLIMB * vertical if vertical > 0.0 else FLY_DIVE * vertical
	var vy := move_toward(velocity.y, want, FLY_VERTICAL_ACCEL * delta)
	return {"velocity": Vector3(h.x, clampf(vy, -FLY_DIVE, FLY_CLIMB), h.z), "yaw": wrapf(yaw, -PI, PI)}


## The highest a flying car of `kind` may be over ground at height `ground_y`.
static func ceiling_y(kind: StringName, ground_y: float) -> float:
	var above := CarKinds.above_ground(kind)
	return minf(FLY_CEILING, ground_y + above) if above > 0.0 else FLY_CEILING


## Never climbing past `ceiling` (and sinking back when over it: faster the further over, as when a cliff drops away
## under a hover car; never faster than a dive).
static func held_under(v: Vector3, y: float, ceiling: float) -> Vector3:
	if y > ceiling + 0.05:
		return Vector3(v.x, minf(v.y, -clampf((y - ceiling) * 2.0, SINK_OVER, FLY_DIVE)), v.z)
	if y >= ceiling - 0.05:
		return Vector3(v.x, minf(v.y, 0.0), v.z)
	return v


## A step of `height` blocks ahead: hopped up when the car climbs it (a monster truck 3, an off-roader 2, the rest 1).
static func wants_hop(kind: StringName, height: int) -> bool:
	return height >= 1 and height <= CarKinds.climb(kind)


static func hop_velocity(height: int, gravity: float) -> float:
	return sqrt(2.0 * gravity * (height + HOP_EXTRA))


## A body at `body` in the way of a car at `car` going `velocity`: pushed aside (to the side it stands on, away from
## the car's line), gently, with a little hop.
static func push_aside(velocity: Vector3, car: Vector3, body: Vector3) -> Vector3:
	var along := Vector3(velocity.x, 0.0, velocity.z)
	along = along.normalized() if along.length() > 0.01 else Vector3.FORWARD
	var right := along.cross(Vector3.UP).normalized()
	var off := (body - car).dot(right)
	var side := right * (1.0 if off >= 0.0 else -1.0)
	return side * PUSH + Vector3.UP * PUSH_UP


# --- Getting in and out -----------------------------------------------------------------------------------------

## Is a player's `feet` close enough to get into a car of `kind` at `center` (its feet) turned `yaw`?
static func can_board(feet: Vector3, center: Vector3, kind: StringName, yaw: float, tolerance := 0.0) -> bool:
	if not feet.is_finite() or not center.is_finite():
		return false
	var s := CarKinds.size(kind)
	var local := Basis(Vector3.UP, -yaw) * (feet - center)
	var dx := maxf(absf(local.x) - s.x * 0.5, 0.0)
	var dz := maxf(absf(local.z) - s.z * 0.5, 0.0)
	if Vector2(dx, dz).length() > BOARD_REACH + tolerance:
		return false
	return feet.y >= center.y - 2.0 - tolerance and feet.y <= center.y + s.y + 1.5 + tolerance


static func empty_seats(kind: StringName) -> PackedInt32Array:
	var seats := PackedInt32Array()
	seats.resize(CarKinds.seats(kind))
	seats.fill(0)
	return seats


## A synced seat list, checked: the car's number of seats, each a player's id or 0.
static func clean_seats(seats: PackedInt32Array, n: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(n)
	out.fill(0)
	for i in mini(seats.size(), n):
		out[i] = seats[i] if seats[i] > 0 else 0
	return out


## The seat the next one in takes: the driver's while it is free, else the first free one; -1 when full.
static func free_seat(seats: PackedInt32Array) -> int:
	for i in seats.size():
		if seats[i] == 0:
			return i
	return -1


static func seat_of(seats: PackedInt32Array, peer: int) -> int:
	return seats.find(peer) if peer != 0 else -1


static func riders(seats: PackedInt32Array) -> Array[int]:
	var out: Array[int] = []
	for p in seats:
		if p != 0:
			out.append(p)
	return out


## The RIDE button's word next to a car: DRIVE while the driver's seat is free, else GET IN; "" when full.
static func board_word(seats: PackedInt32Array) -> String:
	var i := free_seat(seats)
	if i < 0:
		return ""
	return "DRIVE" if i == 0 else "GET IN"


# --- Where a car goes ---------------------------------------------------------------------------------------------

## The car's box in the world (axis-aligned round its turned box: a little bigger than it, so it is a safe check).
static func car_aabb(pos: Vector3, yaw: float, kind: StringName) -> AABB:
	var b := CarKinds.box(kind)
	var c := absf(cos(yaw))
	var s := absf(sin(yaw))
	var w := b.x * c + b.z * s
	var l := b.x * s + b.z * c
	return AABB(Vector3(pos.x - w * 0.5, pos.y, pos.z - l * 0.5), Vector3(w, b.y, l))


## Is there room for a car at `pos` (its feet) turned `yaw`: no solid block in its box, no body in it?
static func box_free(pos: Vector3, yaw: float, kind: StringName, is_solid: Callable, bodies: Array) -> bool:
	var box := car_aabb(pos, yaw, kind)
	var lo := Vector3i(floori(box.position.x + 0.05), floori(box.position.y + 0.05), floori(box.position.z + 0.05))
	var hi := Vector3i(floori(box.end.x - 0.05), floori(box.end.y - 0.05), floori(box.end.z - 0.05))
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				if is_solid.call(Vector3i(x, y, z)):
					return false
	for b: Variant in bodies:
		if b is AABB and box.intersects(b):
			return false
	return true


## Where a called car goes, near a child at `feet` looking `yaw`: in front of them, else to their right, left or
## behind, on the ground (level, a step up or down, two), with room for its box and no friend in it; facing the way the
## child looks. {"pos", "yaw"}; {} when there is no room anywhere near.
static func place_spot(feet: Vector3, yaw: float, kind: StringName, is_solid: Callable, bodies: Array) -> Dictionary:
	var s := CarKinds.size(kind)
	var turn := Basis(Vector3.UP, yaw)
	var offsets: Array[Vector3] = []
	for gap: float in [PLACE_GAP, PLACE_GAP + 0.8]:   # always within reach (BOARD_REACH) of the child's feet
		var ahead := s.z * 0.5 + gap
		var beside := s.x * 0.5 + gap
		offsets.append_array([Vector3(0, 0, -ahead), Vector3(beside, 0, 0), Vector3(-beside, 0, 0), Vector3(0, 0, ahead)])
	var y0 := floori(feet.y + 0.25)
	for off in offsets:
		var at := feet + turn * off
		var cell := Vector3i(floori(at.x), y0, floori(at.z))
		for dy: int in [0, 1, -1, 2, -2]:
			var ground := cell + Vector3i(0, dy - 1, 0)
			if not is_solid.call(ground):
				continue
			var pos := Vector3(at.x, ground.y + 1.0, at.z)
			if box_free(pos, yaw, kind, is_solid, bodies):
				return {"pos": pos, "yaw": wrapf(yaw, -PI, PI)}
	return {}


# --- The garage's limits -------------------------------------------------------------------------------------------

## A child `owner` wants one more car out: the index (in `cars`: {"owner", "born", "ridden"}) of their oldest parked car
## that goes back to the garage, or -1 while they have room.
static func goes_home(cars: Array, owner: String) -> int:
	var mine := 0
	var oldest := -1
	for i in cars.size():
		var c: Dictionary = cars[i]
		if str(c.get("owner", "")) != owner:
			continue
		mine += 1
		if not bool(c.get("ridden", false)) and (oldest < 0 or int(c.born) < int(cars[oldest].born)):
			oldest = i
	return oldest if mine >= PER_PLAYER else -1


static func owned_id(kind: StringName) -> String:
	return OWNED_PREFIX + String(kind)


## The kinds a profile owns (its bought list's "car:<kind>"), known kinds only, in the garage's order.
static func owned_kinds(bought: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for kind in CarKinds.ORDER:
		if bought.has(owned_id(kind)):
			out.append(kind)
	return out


## May a child get this kind out: the Sandbox (`unlimited`) every kind; Survivor the kinds `owned`. "" or why not.
static func may_get(kind: StringName, unlimited: bool, owned: Array) -> String:
	if not CarKinds.exists(kind):
		return "unknown"
	if not unlimited and not owned.has(kind):
		return "not_owned"
	return ""


## A refusal's words for a child (the car's name filled in where it has a place for one).
static func words(reason: String, kind: StringName = &"") -> String:
	var text := str(_WORDS.get(reason, ""))
	return text % CarKinds.display_name(kind) if text.contains("%s") and CarKinds.exists(kind) else text.replace("%s", "car")


# --- The save -------------------------------------------------------------------------------------------------------

## Parked cars from a save: known kinds, finite places, a colour, at most one of a kind per child, at most MAX_CARS.
static func clean_save(v: Variant) -> Array:
	var out: Array = []
	if not v is Array:
		return out
	var seen := {}
	for e: Variant in v:
		if out.size() >= MAX_CARS:
			break
		if not e is Dictionary:
			continue
		var d: Dictionary = e
		var kind := StringName(str(d.get("kind", "")))
		var p: Variant = d.get("pos")
		if not CarKinds.exists(kind) or not p is Array or (p as Array).size() != 3:
			continue
		var pos := Vector3(_f(p[0]), _f(p[1]), _f(p[2]))
		if not pos.is_finite():
			continue
		var owner := str(d.get("owner", "")).left(64)
		var key := "%s|%s" % [owner, kind]
		if seen.has(key):
			continue
		seen[key] = true
		var yaw := _f(d.get("yaw", 0.0))
		var colour: Variant = d.get("colour", 0)
		out.append({"kind": String(kind), "owner": owner, "pos": [pos.x, pos.y, pos.z],
			"yaw": wrapf(yaw, -PI, PI) if is_finite(yaw) else 0.0,
			"colour": CarKinds.colour_index(int(colour)) if typeof(colour) in [TYPE_INT, TYPE_FLOAT] else 0,
			"cargo": Array(clean_cargo(d.get("cargo", [])))})
	return out


static func _f(v: Variant) -> float:
	return float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else NAN


# --- The pickup's bed ------------------------------------------------------------------------------------------------

## A block the bed takes: a real, placeable block (never water, never an item).
static func loadable(id: int) -> bool:
	return BlockIds.is_valid(id) and id != BlockIds.WATER


static func cargo_total(cargo: PackedInt32Array) -> int:
	var n := 0
	for i in range(1, cargo.size(), 2):
		n += cargo[i]
	return n


## Up to `n` of block `id` into the bed: {"cargo", "added"} (a full bed, a fifth kind or not a block: 0 added).
static func cargo_add(cargo: PackedInt32Array, id: int, n: int) -> Dictionary:
	var out := cargo.duplicate()
	var room := CARGO_MAX - cargo_total(out)
	var add := mini(maxi(n, 0), room)
	if add <= 0 or not loadable(id):
		return {"cargo": out, "added": 0}
	for i in range(0, out.size() - 1, 2):
		if out[i] == id:
			out[i + 1] += add
			return {"cargo": out, "added": add}
	if out.size() / 2 >= CARGO_KINDS:
		return {"cargo": out, "added": 0}
	out.append_array([id, add])
	return {"cargo": out, "added": add}


## A saved or synced load, checked: pairs of a loadable block and a count, CARGO_MAX at most in all.
static func clean_cargo(v: Variant) -> PackedInt32Array:
	var out := PackedInt32Array()
	if not (v is Array or v is PackedInt32Array):
		return out
	var list: Array = Array(v)
	for i in range(0, list.size() - 1, 2):
		if typeof(list[i]) in [TYPE_INT, TYPE_FLOAT] and typeof(list[i + 1]) in [TYPE_INT, TYPE_FLOAT]:
			out = cargo_add(out, int(list[i]), int(list[i + 1])).cargo
	return out


## The cubes that show the load in the bed, in order (CARGO_SHOWN at most).
static func cargo_shown(cargo: PackedInt32Array) -> Array[int]:
	var out: Array[int] = []
	for i in range(0, cargo.size() - 1, 2):
		for k in cargo[i + 1]:
			if out.size() >= CARGO_SHOWN:
				return out
			out.append(cargo[i])
	return out


## The Sandbox's UNLOAD: where `n` blocks tip out round `at` (behind the truck, at its feet): a small pile, the lowest
## free cells first (each on solid ground or on a cell just filled), never more than 1.5 blocks from the middle.
static func tip_cells(at: Vector3, n: int, is_free: Callable, is_solid: Callable) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var mid := Vector3i(floori(at.x), floori(at.y + 0.25), floori(at.z))
	var ring: Array[Vector3i] = [Vector3i.ZERO]
	for r in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1), Vector3i(1, 0, 1),
			Vector3i(-1, 0, 1), Vector3i(1, 0, -1), Vector3i(-1, 0, -1)]:
		ring.append(r)
	var filled := {}
	for dy in range(-1, 4):
		for off in ring:
			if out.size() >= n:
				return out
			var c := mid + off + Vector3i(0, dy, 0)
			var below := c + Vector3i.DOWN
			if not is_free.call(c) or filled.has(c):
				continue
			if is_solid.call(below) or filled.has(below):
				out.append(c)
				filled[c] = true
	return out


# --- The camera ------------------------------------------------------------------------------------------------------

## The camera's yaw after `delta` seconds behind a car facing `car_yaw` going `speed` m/s, `since_look` seconds after the
## child last turned the camera: it swings round behind (never in VR: the caller's).
static func chase_yaw(cam_yaw: float, car_yaw: float, speed: float, since_look: float, delta: float) -> float:
	if speed < CHASE_FROM or since_look < SimpleControls.LOOK_REST:
		return cam_yaw
	var diff := angle_difference(cam_yaw, car_yaw)
	var step := clampf(diff, -CHASE_RATE * delta, CHASE_RATE * delta)
	return wrapf(cam_yaw + step, -PI, PI)


# --- The keys a driver hears --------------------------------------------------------------------------------------

const KEYBOARD := &"keyboard"
const PAD := &"pad"
const TOUCH := &"touch"


## What a driver hears on getting in: a PC's keys, a pad's (and the Quest's) buttons; a phone has its buttons on the
## screen (""). `flies`: a flying car (its FLY).
static func drive_hint(flies: bool, device: StringName) -> String:
	match device:
		KEYBOARD:
			return "W A S D drive%s · H horn · E hop off" % (" · Space flies (C dives)" if flies else "")
		PAD:
			return "The stick drives%s · Triangle / Y hops off" % (" · A flies up, B dives" if flies else " · A honks")
	return ""
