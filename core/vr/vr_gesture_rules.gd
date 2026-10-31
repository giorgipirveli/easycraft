class_name VrGestureRules
extends RefCounted
## Owner #110, VR round 4 idea 3 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md, the research §5.3 "Wave and high-five",
## R8): what a child's hands say, as pure rules. A **wave**: a raised hand (no lower than WAVE_LOW under the eyes) that
## turns sideways twice within WAVE_WINDOW, each sweep WAVE_SWEEP at least. A **high-five**: two hands within FIVE_REACH
## closing faster than FIVE_SPEED. The **personal bubble** (R8): other players' hands shrink away inside BUBBLE_FADE of
## VrGrabRules.BUBBLE round the head and are gone inside it. **Eyes:** a buddy's pupil on its eyeball's front, towards the
## child. **Claps** ride on the VR pose as one byte after VrPoseRules' 21 (only once a clap happened): an older build
## reads the bytes it knows and leaves the rest (VrPoseRules.decode).

const WAVE_WINDOW := 1.2
const WAVE_SWEEP := 0.06
const WAVE_LOW := 0.3
const FIVE_SPEED := 1.0
const FIVE_REACH := 0.15
const BUBBLE_FADE := 0.15
## Buddies within this look at the child; the nearest within PAW_RANGE holds up a paw for PAW_SECONDS after a wave (a
## following buddy waits 3.5 m away: time to walk over and slap it).
const LOOK_RANGE := 8.0
const PAW_RANGE := 4.0
const PAW_SECONDS := 6.0
## Two claps of one high-five (seen by both games) within this are one.
const CLAP_ONCE := 0.5


## One sample of a hand's sideways place `x` (m, across the head's facing) at `t` (s); `high`: the hand is raised.
## `state` keeps the sweep. True once for each wave.
static func wave_step(state: Dictionary, t: float, x: float, high: bool) -> bool:
	if not high:
		state.clear()
		return false
	if not state.has("x"):
		state.merge({"x": x, "far": x, "dir": 0, "turns": []}, true)
		return false
	var dir := int(state.dir)
	var far := float(state.far)
	if dir == 0:
		if absf(x - far) >= WAVE_SWEEP * 0.5:
			state.dir = 1 if x > far else -1
			state.far = x
	elif (x - far) * dir > 0.0:
		state.far = x   # still going the same way
	elif absf(x - far) >= WAVE_SWEEP:
		var turns: Array = state.turns
		turns.append(t)
		while not turns.is_empty() and t - float(turns[0]) > WAVE_WINDOW:
			turns.pop_front()
		state.dir = -dir
		state.far = x
		if turns.size() >= 2:
			turns.clear()
			return true
	state.x = x
	return false


## Two hands at `a` and `b` moving at `va` and `vb` (m/s) high-five: close enough and closing fast enough.
static func meets(a: Vector3, va: Vector3, b: Vector3, vb: Vector3) -> bool:
	var d := b - a
	if d.length() > FIVE_REACH:
		return false
	if d.length() < 0.0001:
		return (va - vb).length() > FIVE_SPEED
	return (va - vb).dot(d.normalized()) > FIVE_SPEED


## How big another player's hand shows `distance` (m) from this child's head: 0 inside the bubble, whole beyond
## BUBBLE_FADE more, shrinking between.
static func bubble_scale(distance: float) -> float:
	return clampf((distance - VrGrabRules.BUBBLE) / BUBBLE_FADE, 0.0, 1.0)


## A pupil's place on an eyeball of radius `r` (its front is -Z) looking towards `local` (the target in the eyeball's
## space): on the ball, never turned past the side into the head.
static func pupil_position(local: Vector3, r: float) -> Vector3:
	var d := local.normalized() if local.length() > 0.0001 else Vector3.FORWARD
	d.z = minf(d.z, -0.45)
	return d.normalized() * r * 0.62


## The claps a VR pose carries (0 for none).
static func claps_of(pose: PackedByteArray) -> int:
	return int(pose[VrPoseRules.SIZE]) if pose.size() > VrPoseRules.SIZE else 0


## `pose` with the clap count after its bytes (a byte, wrapping); none yet: the pose as it is.
static func with_claps(pose: PackedByteArray, claps: int) -> PackedByteArray:
	if claps <= 0 or pose.size() < VrPoseRules.SIZE:
		return pose
	var out := pose.slice(0, VrPoseRules.SIZE)
	out.append(claps % 256 if claps % 256 != 0 else 1)
	return out
