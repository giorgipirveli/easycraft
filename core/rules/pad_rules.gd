class_name PadRules
extends RefCounted
## Jump pads and speed pads (M3 Task 6, spec §14.3), for any body standing on one: players, animals,
## monsters. One PadRules per body keeps its cooldown and its speed burst.
## - A jump pad throws the body up at LAUNCH_SPEED (about 5 blocks in normal gravity, 15 on the Moon).
## - A speed pad sends it along the way it was going (the way it faces when standing still) at
##   BOOST_SPEED for BOOST_TIME, easing back over the last BOOST_FADE. Blocks have no facing yet, so
##   the direction comes from the body, not the pad.
## - After any pad fires, the body's pads wait COOLDOWN: two pads can never bounce a body back and
##   forth faster than that. Launches and bursts set a speed, never add one, so chains never grow.
## - Cosmos: Europa's water plumes, Io's volcanoes and hot lava throw straight up; Triton's nitrogen geyser puffs a body
##   up gently and its thin wind then drifts it north-east until its feet touch the ground (drift_left).
## Usage per physics step: tick(delta); fired := touch(pad_under(...), velocity, facing) when on the
## floor; velocity = apply(velocity, fired).

const LAUNCH_SPEED := 16.0
const BOOST_SPEED := 14.0
const BOOST_TIME := 1.5
const BOOST_FADE := 0.5
const COOLDOWN := 0.5
const MIN_TRAVEL := 0.5          # slower than this, a speed pad pushes the way the body faces
const EDGE := 0.7                # the footprint's corners checked, as a share of the body's radius
## M3 Task 7: the Game Blocks' bounce pad, a trampoline: higher than a jump pad (about 9 blocks), keeping the run.
const BOUNCE_SPEED := 21.0
## M3 Task 14a: the launch pad, the action kit's: very high (about 19 blocks), keeping the run; a player who
## owns a glider opens it by itself at the top of the throw (Player, section "M3 Task 14a").
const LAUNCH_PAD_SPEED := 30.0
## Cosmos (Europa, spec §21b.2): a geyser vent's water plume throws a child up like a jump pad (about 41 blocks in
## Europa's 0.13 gravity, then a long float down), keeping the run.
const GEYSER_SPEED := LAUNCH_SPEED
## Cosmos (Io, spec §21b.2; friendly, §3c): hot lava never hurts: touching it, a warm bounce throws a child up and out
## (about 7 blocks in Io's 0.18 gravity, gentler than a jump there: out of a lava lake's moat, nearly 4 s in the air to
## steer away), keeping the run. An Io volcano's vent throws a child up like Europa's plumes (GEYSER_SPEED: ~30 blocks).
const LAVA_SPEED := 8.0
## Cosmos (Triton, spec §21b.2; safe and fun, §3c): a nitrogen geyser's gentle puff carries a child up (about 32 blocks in
## Triton's 0.079 gravity, a ride of ~11 s), and Triton's thin wind drifts the rider north-east (WIND: the way Voyager 2 saw
## the geysers' dark dust carried) at DRIFT_SPEED while it floats, easing out over the last DRIFT_FADE of DRIFT_TIME; the
## child still steers across the wind, and landing ends the drift.
const PUFF_SPEED := 11.0
const WIND := Vector3(0.70710678, 0.0, -0.70710678)   # north-east: east is +x, north is -z (MY MAP)
const DRIFT_SPEED := 2.5
const DRIFT_TIME := 12.0
const DRIFT_FADE := 1.5

var cooldown_left := 0.0
var boost_left := 0.0
var boost_dir := Vector3.ZERO
var drift_left := 0.0   # cosmos: Triton's wind still carrying a geyser's rider


static func is_pad(id: int) -> bool:
	return id == BlockIds.JUMP_PAD or id == BlockIds.SPEED_PAD or id == BlockIds.BOUNCE \
		or id == BlockIds.LAUNCH_PAD \
		or id == BlockIds.GEYSER_VENT or id == BlockIds.VOLCANO_VENT or id == BlockIds.HOT_LAVA \
		or id == BlockIds.NITROGEN_GEYSER
	# M3 Task 7: the bounce pad; M3 Task 14a: the launch pad; cosmos: Europa's plumes, Io's volcanoes and its hot lava,
	# Triton's nitrogen geysers


## The pad under a body's feet (0 = none): the centre first, then the footprint's corners, so a foot
## on the pad's edge counts. radius 0: the centre only (one lookup, for animals).
static func pad_under(feet: Vector3, radius: float, get_block: Callable) -> int:
	var y := floori(feet.y - 0.05)
	var id: int = get_block.call(Vector3i(floori(feet.x), y, floori(feet.z)))
	if is_pad(id) or radius <= 0.0:
		return id if is_pad(id) else 0
	var r := radius * EDGE
	for c: Vector2 in [Vector2(r, r), Vector2(-r, r), Vector2(r, -r), Vector2(-r, -r)]:
		id = get_block.call(Vector3i(floori(feet.x + c.x), y, floori(feet.z + c.y)))
		if is_pad(id):
			return id
	return 0


## A jump pad's throw: up at LAUNCH_SPEED, keeping the run (never slows a faster body).
static func launch_velocity(v: Vector3) -> Vector3:
	return Vector3(v.x, maxf(v.y, LAUNCH_SPEED), v.z)


## A bounce pad's throw (M3 Task 7): up at BOUNCE_SPEED, keeping the run (never slows a faster body).
static func bounce_velocity(v: Vector3) -> Vector3:
	return Vector3(v.x, maxf(v.y, BOUNCE_SPEED), v.z)


## The level direction a speed pad sends a body: where it is going, or where it faces.
static func travel_dir(velocity: Vector3, facing: Vector3) -> Vector3:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() < MIN_TRAVEL:
		flat = Vector3(facing.x, 0.0, facing.z)
	return flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD


## The speed a burst holds with `time_left` of it to go.
static func boost_floor(time_left: float) -> float:
	return BOOST_SPEED * clampf(time_left / BOOST_FADE, 0.0, 1.0)


## `v` with at least boost_floor(time_left) along `dir` (level); sideways and up/down stay as they are.
static func boosted(v: Vector3, dir: Vector3, time_left: float) -> Vector3:
	var along := v.x * dir.x + v.z * dir.z
	var hold := boost_floor(time_left)
	if along < hold:
		v += dir * (hold - along)
	return v


func tick(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	boost_left = maxf(boost_left - delta, 0.0)
	drift_left = maxf(drift_left - delta, 0.0)


## A body touching `pad` (a block id): the pad that fires (0 = none, or cooling down).
func touch(pad: int, velocity: Vector3, facing: Vector3) -> int:
	if drift_left > 0.0 and cooldown_left <= 0.0 and pad != BlockIds.NITROGEN_GEYSER:
		drift_left = 0.0   # cosmos: a geyser's rider is on the ground again (touch is only called there)
	if not is_pad(pad) or cooldown_left > 0.0:
		return 0
	cooldown_left = COOLDOWN
	if pad == BlockIds.SPEED_PAD:
		boost_left = BOOST_TIME
		boost_dir = travel_dir(velocity, facing)
	elif pad == BlockIds.NITROGEN_GEYSER:
		drift_left = DRIFT_TIME
	return pad


## This step's velocity: the throw of a jump pad that just fired, and a speed pad's burst while it lasts.
func apply(velocity: Vector3, fired: int) -> Vector3:
	var v := velocity
	if fired == BlockIds.JUMP_PAD:
		v = launch_velocity(v)
	elif fired == BlockIds.BOUNCE:
		v = bounce_velocity(v)
	elif fired == BlockIds.LAUNCH_PAD:   # M3 Task 14a
		v = Vector3(v.x, maxf(v.y, LAUNCH_PAD_SPEED), v.z)
	elif fired == BlockIds.GEYSER_VENT or fired == BlockIds.VOLCANO_VENT:   # cosmos: a water plume, a volcano's plume
		v = Vector3(v.x, maxf(v.y, GEYSER_SPEED), v.z)
	elif fired == BlockIds.HOT_LAVA:   # cosmos: Io's hot lava bounces a child out (never hurts)
		v = Vector3(v.x, maxf(v.y, LAVA_SPEED), v.z)
	elif fired == BlockIds.NITROGEN_GEYSER:   # cosmos: Triton's geyser puffs a child up
		v = Vector3(v.x, maxf(v.y, PUFF_SPEED), v.z)
	if boost_left > 0.0:
		v = boosted(v, boost_dir, boost_left)
	if drift_left > 0.0:   # cosmos: Triton's thin wind carries the rider north-east
		var along := v.x * WIND.x + v.z * WIND.z
		var hold := DRIFT_SPEED * clampf(drift_left / DRIFT_FADE, 0.0, 1.0)
		if along < hold:
			v += WIND * (hold - along)
	return v


func reset() -> void:
	cooldown_left = 0.0
	boost_left = 0.0
	boost_dir = Vector3.ZERO
	drift_left = 0.0
