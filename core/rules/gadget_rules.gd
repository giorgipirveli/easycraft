class_name GadgetRules
extends RefCounted
## The action kit's gadgets and movement (M3 Task 14a, spec §13.3, §14.13; our own designs): the glider,
## the grappling hook, ziplines, instant builds (Quick Wall, Floor, Ramp, Fort) and the Boing and Dance
## orbs. Pure numbers and checks shared by the player's own game (it moves its body), the host (Session
## section "M3 Task 14a" checks every use: reach, cooldowns, what the player owns) and the directors.
## The launch pad is a PadRules pad; zipline links are ZiplineLinks.

## How a player's body moves with a gadget (Player.gadget_move, synced so everyone sees it).
enum Move { NONE, GLIDE, HOOK, ZIP }

const ORBS: Array[int] = [ItemIds.IMPULSE_ORB, ItemIds.DANCE_ORB]
const BUILDS: Array[int] = [ItemIds.BUILD_WALL, ItemIds.BUILD_FLOOR, ItemIds.BUILD_RAMP, ItemIds.BUILD_FORT]


static func is_gadget(id: int) -> bool:
	return ItemIds.GADGETS.has(id)


static func is_orb(id: int) -> bool:
	return ORBS.has(id)


static func is_build(id: int) -> bool:
	return BUILDS.has(id)


## Gadgets kept like tools (nobody needs two; Tilly never sells a second): everything but the orbs.
static func is_kept(id: int) -> bool:
	return is_gadget(id) and not is_orb(id)


static func valid_move(m: int) -> int:
	return m if m >= Move.NONE and m <= Move.ZIP else Move.NONE

# --- Glider ---------------------------------------------------------------------------------------------

const GLIDE_FALL_SPEED := 3.0    # m/s down at most while gliding
const GLIDE_SPEED := 8.0         # steering with the stick (walking is 6)
const GLIDE_IDLE_SPEED := 4.0    # the stick let go: it drifts on the way it was going
const GLIDE_ACCEL := 8.0
const GLIDE_BRAKE := 36.0        # a fast fall slows to GLIDE_FALL_SPEED this quickly (m/s²): the canopy opens
const GLIDE_MIN_AIR := 3         # blocks of air under the feet before it may open
## The glider's looks (a cosmetic slot: M3 Task 9's avatar unlocks can add more); the first is free.
const GLIDER_LOOKS: Array[StringName] = [&"classic", &"sky", &"sunset"]


## Sandbox (unlimited) always has one; Survivor needs one in the bag (Tilly sells it).
static func has_glider(unlimited: bool, owned: int) -> bool:
	return unlimited or owned > 0


## Blocks of air under the feet, counted down to `limit`.
static func air_below(feet: Vector3, is_solid: Callable, limit: int = GLIDE_MIN_AIR) -> int:
	var cell := Vector3i(floori(feet.x), floori(feet.y - 0.05), floori(feet.z))
	for i in limit:
		if is_solid.call(cell - Vector3i(0, i, 0)):
			return i
	return limit


## `walking`: the physics switch walks (not flying, a ghost or zero-G).
static func can_open_glider(on_floor: bool, walking: bool, water_state: int, air: int) -> bool:
	return not on_floor and walking and water_state < SwimRules.State.SWIMMING and air >= GLIDE_MIN_AIR


## JUMP in the air opens it once every air jump is used (a triple jump, then glide).
static func glide_on_jump(jumps_used: int, max_jumps: int) -> bool:
	return jumps_used >= max_jumps


## The glide lands on the ground, in water, or when the physics switch flies.
static func glide_ends(on_floor: bool, water_state: int, walking: bool) -> bool:
	return on_floor or water_state >= SwimRules.State.SWIMMING or not walking


## One step of gliding: the stick steers at GLIDE_SPEED (let go, it drifts on at GLIDE_IDLE_SPEED); a
## rising body slows with `gravity` and never climbs; falling, it is braked to GLIDE_FALL_SPEED.
static func glide_velocity(v: Vector3, dir: Vector3, delta: float, gravity: float) -> Vector3:
	var flat := Vector2(v.x, v.z)
	var want := Vector2.ZERO
	var stick := Vector2(dir.x, dir.z)
	if stick.length() > 0.1:
		want = stick.normalized() * GLIDE_SPEED * minf(stick.length(), 1.0)
	elif flat.length() > 0.01:
		want = flat.normalized() * GLIDE_IDLE_SPEED
	flat = flat.move_toward(want, GLIDE_ACCEL * delta)
	var vy := v.y
	if vy > -GLIDE_FALL_SPEED:
		vy = maxf(vy - gravity * delta, -GLIDE_FALL_SPEED)
	else:
		vy = move_toward(vy, -GLIDE_FALL_SPEED, GLIDE_BRAKE * delta)
	return Vector3(flat.x, vy, flat.y)


## A synced look index, checked (anything unknown is the free classic look).
static func glider_look(i: int) -> int:
	return i if i >= 0 and i < GLIDER_LOOKS.size() else 0

# --- Grappling hook -------------------------------------------------------------------------------------

const HOOK_RANGE := 24.0
const HOOK_SLACK := 1.5          # the host's allowance for a guest's latency
const HOOK_COOLDOWN := 1.0
const HOOK_SPEED := 22.0         # the pull
const HOOK_ARRIVE := 1.4         # the chest this close to the hook point: there
const HOOK_MAX_TIME := 2.5
const HOOK_STUCK_TIME := 0.25    # no closer for this long (a wall on the way): let go
const HOOK_HOP := 9.0            # letting go: a hop up (about 1.7 blocks: onto the ledge) and on towards the wall
const HOOK_ON := 3.0
const _HOOK_MESSAGES := {
	"block": "Hook onto a block!",
	"far": "That's too far for the hook!",
	"wall": "Something is in the way!",
}


## The host's (and the thrower's own) check of a hook thrown from `eye` at block `cell`: a solid block
## within reach, and the first solid block a grid ray from the eye meets (never through walls; water and
## air never stop it). {ok, error, point}: point is the middle of the face that faces the thrower.
static func hook_check(eye: Vector3, cell: Vector3i, is_solid: Callable, reach: float = HOOK_RANGE + HOOK_SLACK) -> Dictionary:
	if not is_solid.call(cell):
		return {"ok": false, "error": "block", "point": Vector3.INF}
	var center := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
	var dist := eye.distance_to(center)
	if dist > reach:
		return {"ok": false, "error": "far", "point": Vector3.INF}
	var hit := GridRay.cast(eye, center - eye, dist + 1.0, is_solid)
	if hit == null or hit.position != cell:
		return {"ok": false, "error": "wall", "point": Vector3.INF}
	return {"ok": true, "error": "", "point": center + Vector3(hit.previous_position - hit.position) * 0.5}


static func hook_message(error: String) -> String:
	return _HOOK_MESSAGES.get(error, "")


static func hook_ready(last_ms: int, now_ms: int) -> bool:
	return last_ms < 0 or now_ms - last_ms >= int(HOOK_COOLDOWN * 1000.0)


static func hook_velocity(chest: Vector3, point: Vector3) -> Vector3:
	var to := point - chest
	return to.normalized() * HOOK_SPEED if to.length() > 0.001 else Vector3.ZERO


static func hook_arrived(chest: Vector3, point: Vector3) -> bool:
	return chest.distance_to(point) <= HOOK_ARRIVE


## Letting go of the hook: a hop up, and a little on towards where it held.
static func hook_release(chest: Vector3, point: Vector3) -> Vector3:
	var flat := Vector3(point.x - chest.x, 0.0, point.z - chest.z)
	if flat.length() > 0.01:
		flat = flat.normalized() * HOOK_ON
	return flat + Vector3.UP * HOOK_HOP

# --- Ziplines -------------------------------------------------------------------------------------------

const ZIP_MAX_LENGTH := 48.0
const ZIP_MIN_LENGTH := 3.0      # closer posts make no line
const ZIP_ATTACH := 2.0          # the line runs this far above a post's top (a pole and a wheel are drawn)
const ZIP_HANG := 2.0            # a rider's feet hang this far under the line (hands up on the handle)
const ZIP_GAP := 1.0             # a ride starts and ends this far from the posts (never into one)
const ZIP_START_SPEED := 5.0
const ZIP_MIN_SPEED := 3.0       # uphill it crawls, it never stops
const ZIP_MAX_SPEED := 18.0
const ZIP_GRAVITY := 16.0        # along the line: gravity less the handle's friction
const ZIP_GRAB := 6.0            # how close (across and up/down) to a post to grab its line
const ZIP_COOLDOWN := 0.5
const ZIP_JUMP_OFF := 5.0        # JUMP lets go with a little hop


## Where a post's line hangs: over the middle of its top.
static func attach_point(post: Vector3i) -> Vector3:
	return Vector3(post.x + 0.5, post.y + 1.0 + ZIP_ATTACH, post.z + 0.5)


static func can_link(a: Vector3i, b: Vector3i) -> bool:
	var d := Vector3(a).distance_to(Vector3(b))
	return d <= ZIP_MAX_LENGTH and d >= ZIP_MIN_LENGTH


## Nothing solid between two points (a line through a hill never links).
static func line_clear(a: Vector3, b: Vector3, is_solid: Callable) -> bool:
	var d := a.distance_to(b)
	return d < 0.01 or GridRay.cast(a, b - a, d, is_solid) == null


## The rider's speed along the line after `delta`: faster downhill, a crawl uphill, never stopped.
static func zip_speed(speed: float, dir: Vector3, delta: float) -> float:
	return clampf(speed - ZIP_GRAVITY * dir.y * delta, ZIP_MIN_SPEED, ZIP_MAX_SPEED)


## The rider's feet `s` along the line from `from` to `to`.
static func zip_feet(from: Vector3, to: Vector3, s: float) -> Vector3:
	return from + (to - from).normalized() * s - Vector3(0, ZIP_HANG, 0)


## Where along the line the ride ends (ZIP_GAP before the far post).
static func zip_ride_end(from: Vector3, to: Vector3) -> float:
	return maxf(from.distance_to(to) - ZIP_GAP, ZIP_GAP)


## Sliding off the end with the ride's speed.
static func zip_leave(from: Vector3, to: Vector3, speed: float) -> Vector3:
	return (to - from).normalized() * speed


static func can_grab(feet: Vector3, post: Vector3i) -> bool:
	var across := Vector2(feet.x - (post.x + 0.5), feet.z - (post.z + 0.5)).length()
	return across <= ZIP_GRAB and absf(feet.y - post.y) <= ZIP_GRAB


## A player's body (feet to head, the middle column) is clear of blocks at `feet`.
static func body_fits(feet: Vector3, is_solid: Callable) -> bool:
	for up: float in [0.1, 0.95, 1.75]:
		if is_solid.call(Vector3i((feet + Vector3(0, up, 0)).floor())):
			return false
	return true

# --- Orbs ------------------------------------------------------------------------------------------------

const ORB_SPEED := 15.0
const ORB_LIFT := 0.3            # thrown a little over the aim
const ORB_GRAVITY := 18.0
const ORB_STEP := 0.05           # the flight is followed in steps this long (the host, once per throw)
const ORB_MAX_TIME := 3.0
const ORB_COOLDOWN := 1.0
const ORB_RADIUS := 5.0          # the Boing Orb's burst and the Dance Orb's bubble
const ORB_DAMAGE := 0            # orbs never hurt anyone
const IMPULSE_PUSH := 15.0       # monsters: m/s away from the burst at its middle (monsters cap pushes at 20)
const IMPULSE_LIFT := 5.0
const IMPULSE_BOUNCE := 13.0     # players: a big bounce up, never damage
const IMPULSE_BOUNCE_OUT := 6.0
const DANCE_TIME := 5.0
const BOSS_DANCE_TIME := 2.0
const BOSS_DANCE_GAP := 20.0     # a boss dances at most once in this many seconds


static func orb_velocity(dir: Vector3) -> Vector3:
	var d := dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	return (d + Vector3.UP * ORB_LIFT).normalized() * ORB_SPEED


static func orb_position(from: Vector3, velocity: Vector3, t: float) -> Vector3:
	return from + velocity * t + Vector3.DOWN * 0.5 * ORB_GRAVITY * t * t


## Where a thrown orb bursts and when: the first solid block its arc meets (a grid ray per step), or
## where it is after ORB_MAX_TIME. {point, time}. Every game flies the same arc; the host bursts it.
static func orb_path(from: Vector3, velocity: Vector3, is_solid: Callable) -> Dictionary:
	var t := 0.0
	var prev := from
	while t < ORB_MAX_TIME - 0.0001:
		var t1 := minf(t + ORB_STEP, ORB_MAX_TIME)
		var p := orb_position(from, velocity, t1)
		var seg := p - prev
		var length := seg.length()
		if length > 0.0001:
			var hit := GridRay.cast(prev, seg, length, is_solid)
			if hit:
				var k := clampf(hit.distance / length, 0.0, 1.0)
				return {"point": prev + seg * k - seg.normalized() * 0.05, "time": t + (t1 - t) * k}
		prev = p
		t = t1
	return {"point": prev, "time": ORB_MAX_TIME}


static func orb_ready(last_ms: int, now_ms: int) -> bool:
	return last_ms < 0 or now_ms - last_ms >= int(ORB_COOLDOWN * 1000.0)


static func in_bubble(center: Vector3, pos: Vector3) -> bool:
	return center.distance_to(pos) <= ORB_RADIUS


## A monster's push from a Boing Orb burst at `center`: away (straight out when it stands on it), a little
## up, harder near the middle; nothing outside the bubble.
static func impulse_push(center: Vector3, pos: Vector3) -> Vector3:
	var d := center.distance_to(pos)
	if d > ORB_RADIUS:
		return Vector3.ZERO
	var out := Vector3(pos.x - center.x, 0.0, pos.z - center.z)
	out = out.normalized() if out.length() > 0.05 else Vector3.FORWARD
	var k := lerpf(1.0, 0.45, d / ORB_RADIUS)
	return out * IMPULSE_PUSH * k + Vector3.UP * IMPULSE_LIFT


## A player's bounce (never damage): mostly up, a little out.
static func impulse_bounce(center: Vector3, pos: Vector3) -> Vector3:
	var d := center.distance_to(pos)
	if d > ORB_RADIUS:
		return Vector3.ZERO
	var out := Vector3(pos.x - center.x, 0.0, pos.z - center.z)
	out = out.normalized() if out.length() > 0.05 else Vector3.ZERO
	return out * IMPULSE_BOUNCE_OUT + Vector3.UP * IMPULSE_BOUNCE


## How long a monster caught in a Dance Orb dances (0 = not now). A boss dances BOSS_DANCE_TIME, and only
## if its last dance was BOSS_DANCE_GAP ago (`last_s` < 0: never).
static func dance_seconds(boss: bool, last_s: float, now_s: float) -> float:
	if not boss:
		return DANCE_TIME
	return BOSS_DANCE_TIME if last_s < 0.0 or now_s - last_s >= BOSS_DANCE_GAP else 0.0

# --- Instant builds --------------------------------------------------------------------------------------

const BUILD_COOLDOWN := 0.6
## How far in front of the feet each build starts (its blueprint's anchor).
const BUILD_AHEAD := {ItemIds.BUILD_WALL: 2, ItemIds.BUILD_FLOOR: 1, ItemIds.BUILD_RAMP: 1, ItemIds.BUILD_FORT: 1}
const NOTHING_TO_BUILD := "No room to build that here!"


## Where a build goes for a player standing at `feet` looking along `yaw`: {anchor, forward}.
static func build_anchor(feet: Vector3, yaw: float, item: int) -> Dictionary:
	var forward := Blueprints.facing_for_yaw(yaw)
	var base := Vector3i(floori(feet.x), floori(feet.y + 0.01), floori(feet.z))
	return {"anchor": base + forward * int(BUILD_AHEAD.get(item, 2)), "forward": forward}


## Its cells [[pos, id], ...] from the stamps' blueprints (Blueprints, spec §3a), in planks.
static func build_cells(item: int, anchor: Vector3i, forward: Vector3i) -> Array:
	return Blueprints.place(item, anchor, forward) if is_build(item) else []


## Only cells that are empty now (air or water): a build never replaces a block.
static func empty_cells(cells: Array, block_at: Callable) -> Array:
	var out: Array = []
	for c: Array in cells:
		var id: int = block_at.call(c[0])
		if id == BlockIds.AIR or id == BlockIds.WATER:
			out.append(c)
	return out


## Planks when there are enough, else stone; 0 when short of both (Survivor pays from the bag).
static func build_material(planks: int, stone: int, need: int) -> int:
	if planks >= need:
		return BlockIds.PLANKS
	if stone >= need:
		return BlockIds.STONE
	return 0


static func with_material(cells: Array, material: int) -> Array:
	var out: Array = []
	for c: Array in cells:
		out.append([c[0], material if c[1] == BlockIds.PLANKS else c[1]])
	return out


static func short_message(need: int) -> String:
	return Lang.t("Need %d Planks!") % need


static func build_ready(last_ms: int, now_ms: int) -> bool:
	return last_ms < 0 or now_ms - last_ms >= int(BUILD_COOLDOWN * 1000.0)

# --- Tilly's prices (fixed; × 2^(u-1) per universe like everything she sells) ------------------------------

const PRICES := {ItemIds.GLIDER: 60, ItemIds.GRAPPLE: 80, ItemIds.BUILD_WALL: 20, ItemIds.BUILD_FLOOR: 20,
	ItemIds.BUILD_RAMP: 20, ItemIds.BUILD_FORT: 50, ItemIds.IMPULSE_ORB: 12, ItemIds.DANCE_ORB: 15,
	BlockIds.ZIPLINE_POST: 15, BlockIds.LAUNCH_PAD: 10}
## (Orbs come three to a pack and posts in pairs: ShopRules.PACKS.)
