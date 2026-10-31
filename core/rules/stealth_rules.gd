class_name StealthRules
extends RefCounted
## Stealth as pure rules (M2 spec §12.5, plan Task 5): how visible someone is (the light around them,
## crouching, a hiding spot, the Invisibility potion), what a monster sees (16 blocks × visibility, a
## 120° view, a clear line over the voxel data; a little further it "half-sees" a shape) and hears
## (noise radii), the monster's mind (wander → ? → ! → search the last known spot → wander), hiding
## spots (BUSH: crouch in it; BARREL and CLOSET: go inside), crouching, the HUD's eye and noise bars,
## and the danger arrow (research A3). Hidden players are never seen.

# --- Visibility (§12.5) ---

const DAYLIGHT := 1.0
const NIGHT := 0.45
const DARK_CAVE := 0.3
const NEAR_LIGHT := 1.0
const CROUCH_FACTOR := 0.5
## A lantern or a light block this close (blocks, in a box around the body) lights you up (ruling).
const LIGHT_RADIUS := 6
const LIGHT_BLOCKS: Array[int] = [BlockIds.LANTERN, BlockIds.LIGHT, BlockIds.SPORE_LAMP]   # universe 6: the spore lamp

# --- Sight ---

const SIGHT := 16.0               # blocks, at full visibility
const VIEW_ANGLE := 120.0         # degrees, centred on where the monster faces
## Beyond the sight range, up to this many times it, a monster half-sees you: "?", it comes to look.
const HALF_SEEN := 1.5

enum Sight { NONE, HALF, FULL }

# --- Noise (§12.5): how far away a monster hears it (blocks) ---

const NOISE_SPRINT := 12.0
const NOISE_WALK := 6.0
const NOISE_CROUCH := 1.5
const NOISE_LANDING := 8.0
const NOISE_BREAK := 7.0
const NOISE_ATTACK := 6.0
const MOVING := 0.5               # m/s: slower than this is standing still (silent)
const RUNNING := 7.0              # m/s: faster than walking (6) is running: the Speed potion, flying
const LANDING_SPEED := 8.0        # a landing this fast (m/s) thuds; a jump lands at 9, a 1-block step at 6.9
const NOISE_TIME := 0.5           # an event noise (landing, breaking, attacking) is heard this long

# --- The mind ---

## NONE: wanders. SUSPICIOUS "?": heard or half-saw something, walks there. ALERT "!": sees you,
## chases and attacks (or, having lost you, goes to the last known spot). SEARCH "?": looks around
## that spot for SEARCH_TIME, then wanders again.
enum Alert { NONE, SUSPICIOUS, ALERT, SEARCH }

const SEARCH_TIME := 6.0
const LOST_TIME := 5.0            # a lost chase searches after this long, even if it never got there
const SUSPICIOUS_TIME := 10.0     # ... and so does a walk to a noise
const ARRIVE := 1.5               # this close to the spot is there
const MARK_NONE := 0
const MARK_QUESTION := 1
const MARK_BANG := 2

# --- Crouching ---

const CROUCH_SPEED := 0.5         # half speed
const CROUCH_EYE := 0.6           # the eyes (and the camera) at this share of the standing height
const CROUCH_BODY := 0.78         # the body's look is this tall

# --- Hiding ---

const HIDING_BLOCKS: Array[int] = [BlockIds.BARREL, BlockIds.CLOSET]
const HIDE_REACH := 4.0           # eye to the block's centre: walk up to it
const HIDE_SLACK := 1.0           # host-side slack (network latency)
const TOO_FAR_MESSAGE := "Get closer to hide inside!"
const TAKEN_MESSAGE := "Someone is hiding in there already!"
const SIDES: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]

# --- HUD ---

const EYE_CLOSED := 0
const EYE_HALF := 1
const EYE_OPEN := 2
const EYE_OPEN_FROM := 0.7

# --- The danger arrow (research A3) ---

const ARROW_TIME := 2.2           # seconds from glowing to gone
const ARROW_FADE_IN := 0.15
const ARROW_HOLD := 1.1
const ARROW_COOLDOWN := 8.0       # the same monster brings no new arrow this soon (never nags)
const ARROW_PULSE := 0.12


## The light around someone: daylight(t) 1 by day, 0 at night (DayCycle.daylight), underground 0..1
## (AmbienceRules.underground_target), and a lantern or light block within LIGHT_RADIUS.
static func light_level(daylight: float, underground: float, near_light: bool) -> float:
	if near_light:
		return NEAR_LIGHT
	var d := clampf(daylight, 0.0, 1.0)
	var u := clampf(underground, 0.0, 1.0)
	var sky := NIGHT * (1.0 - d) + DAYLIGHT * d
	return sky * (1.0 - u) + minf(sky, DARK_CAVE) * u


## Visibility 0..1: the light, halved by crouching; 0 inside a hiding spot or while invisible.
static func visibility(light: float, crouching: bool, hidden: bool, invisible: bool) -> float:
	if hidden or invisible:
		return 0.0
	return clampf(light, 0.0, 1.0) * (CROUCH_FACTOR if crouching else 1.0)


static func sight_range(vis: float) -> float:
	return SIGHT * clampf(vis, 0.0, 1.0)


## Is `to` (from the eyes) inside the view centred on `facing`? Flat angles; straight up or down counts.
static func in_view(facing: Vector3, to: Vector3) -> bool:
	var look := Vector2(facing.x, facing.z)
	var flat := Vector2(to.x, to.z)
	if look.length() < 0.001 or flat.length() < 0.001:
		return true
	return rad_to_deg(absf(look.angle_to(flat))) <= VIEW_ANGLE * 0.5


## Does a block stop a monster's look? Air, water, glass, bushes and open doors do not.
static func blocks_sight(id: int) -> bool:
	return BlockIds.is_solid(id) and id != BlockIds.GLASS


## What a monster whose eyes are at `eye`, facing `facing`, makes out of someone whose eyes are at
## `target` and who is `vis` visible: FULL within sight_range(vis), HALF up to HALF_SEEN times that,
## both only inside the view and with a clear line (one grid ray; is_blocking(cell) -> bool).
static func sight(eye: Vector3, facing: Vector3, target: Vector3, vis: float, is_blocking: Callable) -> Sight:
	var reach := sight_range(vis)
	if reach <= 0.0:
		return Sight.NONE
	var to := target - eye
	var dist := to.length()
	if dist > reach * HALF_SEEN or not in_view(facing, to):
		return Sight.NONE
	if dist > 0.001:
		var hit := GridRay.cast(eye, to, dist, is_blocking)
		if hit != null and hit.position != Vector3i(target.floor()):
			return Sight.NONE
	return Sight.FULL if dist <= reach else Sight.HALF


## How far someone moving at `speed` (m/s, flat) is heard: silent standing still, quiet crouching.
static func move_noise(speed: float, crouching: bool) -> float:
	if speed < MOVING:
		return 0.0
	if crouching:
		return NOISE_CROUCH
	return NOISE_SPRINT if speed > RUNNING else NOISE_WALK


static func hears(listener: Vector3, source: Vector3, radius: float) -> bool:
	return radius > 0.0 and listener.distance_to(source) <= radius


## A body that was falling at `before` (m/s, up is +) and now falls at `now` has landed with a thud.
static func landed(before: float, now: float) -> bool:
	return before <= -LANDING_SPEED and now > -1.0


# --- Hiding spots ---

static func is_hiding_block(id: int) -> bool:
	return HIDING_BLOCKS.has(id)


## In a bush: the block at the feet or the one above them is a BUSH.
static func in_bush(feet_block: int, body_block: int) -> bool:
	return feet_block == BlockIds.BUSH or body_block == BlockIds.BUSH


## Hidden: inside a barrel or closet, or crouching in a bush.
static func is_hidden(inside_spot: bool, crouching: bool, bush: bool) -> bool:
	return inside_spot or (crouching and bush)


## Why the player whose eyes are at `eye` may not hide in `cell` holding `id` ("" = they may; "?" =
## nothing to tell them). `taken`: someone else is inside it. The host adds HIDE_SLACK to the reach.
static func hide_refusal(eye: Vector3, cell: Vector3i, id: int, taken: bool, slack: float = 0.0) -> String:
	if not eye.is_finite() or not is_hiding_block(id):
		return "?"
	if not PlacementRules.in_reach(eye, cell, HIDE_REACH + slack):
		return TOO_FAR_MESSAGE
	if taken:
		return TAKEN_MESSAGE
	return ""


## Where a monster that saw someone go into `cell` searches, and where they come out: the free side of
## the block nearest to `from` (feet), at the block's feet height. is_solid(cell) -> bool.
static func search_spot(cell: Vector3i, from: Vector3, is_solid: Callable) -> Vector3:
	var best := Vector3(cell.x + 0.5, cell.y + 1.0, cell.z + 0.5)   # boxed in: on top of it
	var best_d := INF
	for side in SIDES:
		var c := cell + side
		if is_solid.call(c) or is_solid.call(c + Vector3i.UP):
			continue
		var p := Vector3(c.x + 0.5, cell.y, c.z + 0.5)
		var d := Vector2(p.x - from.x, p.z - from.z).length()
		if d < best_d:
			best_d = d
			best = p
	return best


# --- HUD ---

static func eye(vis: float) -> int:
	if vis <= 0.001:
		return EYE_CLOSED
	return EYE_OPEN if vis >= EYE_OPEN_FROM else EYE_HALF


## 0-3 bars for a noise radius: silent, crouching, walking (and landing, breaking, attacking), running.
static func noise_bars(radius: float) -> int:
	if radius <= 0.0:
		return 0
	if radius <= NOISE_CROUCH + 0.5:
		return 1
	return 2 if radius <= NOISE_LANDING else 3


# --- The danger arrow ---

## An arrow only for a monster the player cannot see on the screen (behind the camera or off-screen).
static func arrow_wanted(behind: bool, on_screen: bool) -> bool:
	return behind or not on_screen


## Where the arrow sits: on the screen's edge (`margin` inside it), from the centre towards `dir`.
static func arrow_edge(screen: Vector2, dir: Vector2, margin: float) -> Vector2:
	var center := screen * 0.5
	if dir.length() < 0.001:
		return center
	var d := dir.normalized()
	var half := center - Vector2(margin, margin)
	var t := INF
	if absf(d.x) > 0.0001:
		t = minf(t, half.x / absf(d.x))
	if absf(d.y) > 0.0001:
		t = minf(t, half.y / absf(d.y))
	return center + d * t


## How strongly the arrow shows `age` seconds after it appeared: in quickly, holds, fades out.
static func arrow_alpha(age: float, _reduce_motion: bool) -> float:
	if age < 0.0 or age >= ARROW_TIME:
		return 0.0
	if age < ARROW_FADE_IN:
		return age / ARROW_FADE_IN
	if age < ARROW_FADE_IN + ARROW_HOLD:
		return 1.0
	return 1.0 - (age - ARROW_FADE_IN - ARROW_HOLD) / (ARROW_TIME - ARROW_FADE_IN - ARROW_HOLD)


## The arrow's glow pulse (its size); none with Reduce motion.
static func arrow_scale(age: float, reduce_motion: bool) -> float:
	if reduce_motion:
		return 1.0
	return 1.0 + ARROW_PULSE * sin(age * TAU * 2.0)


## May the same monster bring a new arrow at `now`, its last one at `last`?
static func arrow_again(last: float, now: float) -> bool:
	return now - last >= ARROW_COOLDOWN


## A monster's awareness (its stealth "mind"; the learned Mind is core/mind/): what it knows about the players and bots around it, updated at every look (the
## monster decides where to go from it). Positions only; the monster keeps who its target is.
class Awareness:
	extends RefCounted

	var state: Alert = Alert.NONE
	var spot := Vector3.INF       # where it goes: the noise, the half-seen shape, the last known spot
	var timer := 0.0              # seconds in SUSPICIOUS or since it lost you (ALERT); left in SEARCH
	var sees := false             # it saw its target at the last look

	## One look, `delta` seconds after the last: `seen` is where the one it sees stands (INF: nobody),
	## `clue` where it heard or half-saw someone (INF: nothing); `here` is where it stands.
	func update(delta: float, seen: Vector3, clue: Vector3, here: Vector3) -> void:
		if seen.is_finite():
			see(seen)
			return
		sees = false
		if clue.is_finite():
			hear(clue)
		match state:
			Alert.ALERT:
				timer += delta
				if _there(here) or timer >= LOST_TIME:
					_search()
			Alert.SUSPICIOUS:
				timer += delta
				if _there(here) or timer >= SUSPICIOUS_TIME:
					_search()
			Alert.SEARCH:
				timer -= delta
				if timer <= 0.0:
					forget()

	## It sees someone at `pos`: "!".
	func see(pos: Vector3) -> void:
		state = Alert.ALERT
		spot = pos
		timer = 0.0
		sees = true

	## It heard (or half-saw) something at `pos`: "?" and it goes there; a lost chase follows the sound.
	func hear(pos: Vector3) -> void:
		spot = pos
		if state != Alert.ALERT:
			state = Alert.SUSPICIOUS
			timer = 0.0

	## Its target went into a hiding spot while it was after them: it goes to `spot`, next to it, and
	## searches there (fair: it never finds a hidden player).
	func saw_hide(pos: Vector3) -> void:
		if state != Alert.ALERT:
			return
		spot = pos
		timer = 0.0
		sees = false

	func forget() -> void:
		state = Alert.NONE
		spot = Vector3.INF
		timer = 0.0
		sees = false

	## What floats over its head: nothing, "?" or "!".
	func mark() -> int:
		match state:
			Alert.ALERT:
				return MARK_BANG
			Alert.SUSPICIOUS, Alert.SEARCH:
				return MARK_QUESTION
		return MARK_NONE

	func _search() -> void:
		state = Alert.SEARCH
		timer = SEARCH_TIME

	func _there(here: Vector3) -> bool:
		return spot.is_finite() and Vector2(here.x - spot.x, here.z - spot.z).length() <= ARRIVE
