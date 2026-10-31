class_name VrGrabRules
extends RefCounted
## Owner #110, VR round 4's frozen contract (docs/superpowers/plans/2026-10-16-vr-round4.md; the research's rulings R1-R4,
## R8 in docs/devlog/parts/vr-ideas-research.md §7): how a hand takes, pulls and throws a VrGrabbable. Pure. VR-HANDS
## builds the grabber on these numbers; the names never change.

## A VrGrabbable this close to the hand (m) is taken by the grip (R1).
const NEAR_REACH := 0.12
## The laser reaches a VrGrabbable this far (m) for the far pull (R4: glow, lock, a flick pulls it in).
const FAR_RANGE := 4.0
## Holding the grip this long on a far thing pulls it in too, for children who can't flick (s; R4).
const PULL_HOLD := 0.6
## A throw takes the hand's fastest moment in this last stretch before the release (s; R3).
const THROW_WINDOW := 0.1
## ... times this ...
const THROW_SCALE := 1.5
## ... and never faster than this (m/s).
const THROW_MAX := 12.0
## Other players' hands and heads stay out of this sphere round a child's head (m; R8).
const BUBBLE := 0.5


## The velocity a released thing flies with: of `samples` ([{"t": seconds, "v": Vector3}], oldest first) those within
## THROW_WINDOW of the last, the fastest, times THROW_SCALE, capped at THROW_MAX (its direction kept). None: ZERO.
static func throw_velocity(samples: Array) -> Vector3:
	if samples.is_empty():
		return Vector3.ZERO
	var last := float((samples[samples.size() - 1] as Dictionary).get("t", 0.0))
	var best := Vector3.ZERO
	for s: Dictionary in samples:
		if last - float(s.get("t", 0.0)) > THROW_WINDOW:
			continue
		var v: Vector3 = s.get("v", Vector3.ZERO)
		if v.length() > best.length():
			best = v
	return (best * THROW_SCALE).limit_length(THROW_MAX)

# --- VR-HANDS' body (owner #110, round 4; docs/devlog/parts/vr-r4-hands.md): the numbers and sums the grabber uses.
# Distances are the child's own metres (the play space's: a world distance divided by Vr.world_scale()). ---

## The laser's far pick finds a far_pull thing within this cone round the beam (magnetism; degrees).
const FAR_CONE_DEGREES := 6.0
## The near pick favours a thing ahead of the palm by this much at most (m; magnetism along the hand's forward).
const NEAR_FORWARD := 0.03
## A flick: the hand's speed towards the head or upwards over this (m/s) within FLICK_WINDOW (s) pulls a locked thing.
const FLICK_SPEED := 1.2
const FLICK_WINDOW := 0.3
## A pulled thing flies to the hand in this long (s), rising PULL_RISE (m) at the middle: it arrives catchable.
const PULL_TIME := 0.35
const PULL_RISE := 0.25
## Over the shoulder (the shoulder bag): the hand behind the head's plane by SHOULDER_BACK at least, no lower than
## SHOULDER_DOWN under the eyes, and no further than SHOULDER_REACH from the head.
const SHOULDER_BACK := 0.04
const SHOULDER_DOWN := 0.3
const SHOULDER_REACH := 0.6
## Two hands stretch a &"two_hand" thing between these scales of its own.
const STRETCH_MIN := 0.5
const STRETCH_MAX := 3.0
## The hand's picture is a ball this big that stops at a block's face (R2); the real hand's outline shows when the two
## are further apart than GHOST_GAP.
const HAND_RADIUS := 0.05
const GHOST_GAP := 0.03
## The grip as a press: down from GRIP_ON, up under GRIP_OFF (VrRules.trigger_down's numbers).
const GRIP_ON := 0.6
const GRIP_OFF := 0.35
## Samples kept per hand for the throw and the flick (s).
const SAMPLE_SPAN := 0.35


## The thing a hand takes by the grip: of `things` ([{pos: Vector3, radius: float}], the child's metres), the nearest
## whose surface is within NEAR_REACH of the grip point, one ahead of the palm (along `grip`'s -Z) favoured by up to
## NEAR_FORWARD; -1 for none.
static func near_pick(grip: Transform3D, things: Array) -> int:
	var forward := -grip.basis.z.normalized()
	var best := -1
	var best_score := INF
	for i in things.size():
		var t: Dictionary = things[i]
		var to: Vector3 = (t.get("pos", Vector3.INF) as Vector3) - grip.origin
		if not to.is_finite():
			continue
		var gap := to.length() - maxf(float(t.get("radius", 0.0)), 0.0)
		if gap > NEAR_REACH:
			continue
		var ahead := clampf(to.normalized().dot(forward), 0.0, 1.0) if to.length() > 0.0001 else 0.0
		var score := gap - ahead * NEAR_FORWARD
		if score < best_score:
			best_score = score
			best = i
	return best


## The far_pull thing the laser (from `origin` along `dir`) points at: of `things` ([{pos, radius}]), those within
## `max_range` and FAR_CONE_DEGREES of the beam (a big thing widens the cone), the one nearest the beam (then the
## nearer); -1 for none.
static func far_pick(origin: Vector3, dir: Vector3, things: Array, max_range: float = FAR_RANGE) -> int:
	var d := dir.normalized()
	var best := -1
	var best_angle := INF
	var best_dist := INF
	for i in things.size():
		var t: Dictionary = things[i]
		var to: Vector3 = (t.get("pos", Vector3.INF) as Vector3) - origin
		if not to.is_finite():
			continue
		var dist := to.length()
		if dist < 0.0001 or dist > max_range:
			continue
		var widen := rad_to_deg(atan2(maxf(float(t.get("radius", 0.0)), 0.0), dist))
		var a := maxf(rad_to_deg(d.angle_to(to)) - widen, 0.0)
		if a > FAR_CONE_DEGREES:
			continue
		if a < best_angle - 0.01 or (absf(a - best_angle) <= 0.01 and dist < best_dist):
			best = i
			best_angle = a
			best_dist = dist
	return best


## A flick (R4): within the last FLICK_WINDOW of `samples` ([{t, v}] the hand's velocity, oldest first) the hand moved
## towards `head_dir` (from the hand to the head) or upwards faster than FLICK_SPEED.
static func flick(samples: Array, head_dir: Vector3) -> bool:
	if samples.is_empty():
		return false
	var last := float((samples[samples.size() - 1] as Dictionary).get("t", 0.0))
	var toward := head_dir.normalized()
	for s: Dictionary in samples:
		if last - float(s.get("t", 0.0)) > FLICK_WINDOW:
			continue
		var v: Vector3 = s.get("v", Vector3.ZERO)
		if maxf(v.dot(toward), v.y) > FLICK_SPEED:
			return true
	return false


## The hand is over the shoulder (the shoulder bag): behind the head's plane, no lower than SHOULDER_DOWN under the
## eyes, within SHOULDER_REACH of the head; `head` and `hand` in one space (the child's metres).
static func over_shoulder(head: Transform3D, hand: Vector3) -> bool:
	var back := head.basis.z
	back.y = 0.0
	if back.length_squared() < 0.000001:
		return false
	back = back.normalized()
	var to := hand - head.origin
	return to.dot(back) >= SHOULDER_BACK and to.y >= -SHOULDER_DOWN and to.length() <= SHOULDER_REACH


## Where a pulled thing is `t` (0..1) of the way from `from` to the hand at `to`: eased in and out, rising PULL_RISE at
## the middle (less for a pull shorter than a metre).
static func pull_point(from: Vector3, to: Vector3, t: float) -> Vector3:
	var k := clampf(t, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var rise := PULL_RISE * minf(from.distance_to(to), 1.0) * 4.0 * k * (1.0 - k)
	return from.lerp(to, e) + Vector3(0.0, rise, 0.0)


## Two hands holding a &"two_hand" thing: its scale over its own when they took it `start_apart` apart and are `apart`
## now, between STRETCH_MIN and STRETCH_MAX.
static func stretch(start_apart: float, apart: float) -> float:
	if start_apart <= 0.0001:
		return 1.0
	return clampf(apart / start_apart, STRETCH_MIN, STRETCH_MAX)


## A hand's velocity samples for the throw and the flick: {t, v} added to `samples`, those older than SAMPLE_SPAN
## dropped (the same array, returned).
static func add_sample(samples: Array, t: float, v: Vector3) -> Array:
	samples.append({"t": t, "v": v})
	while samples.size() > 1 and t - float((samples[0] as Dictionary).t) > SAMPLE_SPAN:
		samples.pop_front()
	return samples


## The grip as a press (GRIP_ON / GRIP_OFF).
static func grip_down(value: float, was_down: bool) -> bool:
	return value > GRIP_OFF if was_down else value >= GRIP_ON
