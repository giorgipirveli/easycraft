class_name FeelRules
extends RefCounted
## Screen shake, phone buzz and hurt flashes (M2 spec §12.10), as pure rules. Feel (autoload) plays
## them. Children's-game limits (the lead's child-psychology notes, 2026-09-24):
## - The Vibration setting turns off the buzz and the shake; Reduce motion turns off the shake (and
##   any camera bob) and softens flashes.
## - Never more than 3 flashes in any second (photosensitivity guidance): flashes start at least
##   MIN_FLASH_INTERVAL apart, however fast the hits come.
## - Shakes are small (a few centimetres of view wobble, never over MAX_SHAKE) and short.

const HURT_SHAKE := 0.07          # metres of view wobble for a 3-HP hit (harder hits up to × 1.6)
const HURT_SHAKE_TIME := 0.25
const HURT_BUZZ_MS := 40
const HURT_FLASH := 0.3           # alpha of the red edge flash
const KNOCKOUT_SHAKE := 0.2
const KNOCKOUT_SHAKE_TIME := 0.6
const KNOCKOUT_BUZZ_MS := 250
const KNOCKOUT_FLASH := 0.45
## The Stone Golem's slam (Task 10, §12.9): Feel.slam(distance) on every peer.
const SLAM_SHAKE := 0.16
const SLAM_SHAKE_TIME := 0.5
const SLAM_BUZZ_MS := 120
const SLAM_RADIUS := 7.0          # the shockwave ring: full shake and a buzz inside it
const SLAM_REACH := 20.0          # the shake fades out to nothing here

const MAX_SHAKE := 0.35
const MAX_BUZZ_MS := 600
const FLASH_TIME := 0.3           # a flash fades out in this time
const REDUCED_FLASH := 0.35       # Reduce motion: flashes at this share of their strength...
const REDUCED_FLASH_TIME := 0.5   # ...fading out more gently
const MIN_FLASH_INTERVAL := 0.35  # > 1/3 s: at most 3 flash starts in any closed one-second window


## The view wobble `elapsed` seconds into a shake of `strength` metres lasting `seconds`: eases out
## (quadratic) to exactly zero at the end.
static func shake_amplitude(strength: float, seconds: float, elapsed: float) -> float:
	if not (strength > 0.0) or not (seconds > 0.0) or elapsed >= seconds:
		return 0.0
	var k := 1.0 - maxf(elapsed, 0.0) / seconds
	return minf(strength, MAX_SHAKE) * k * k


## A smooth, irregular wobble (sums of sines at unrelated rates) within ±amplitude on each axis.
static func shake_offset(amplitude: float, t: float) -> Vector2:
	if amplitude <= 0.0:
		return Vector2.ZERO
	var x := 0.6 * sin(t * 47.0) + 0.4 * sin(t * 83.0 + 1.3)
	var y := 0.6 * sin(t * 59.0 + 0.7) + 0.4 * sin(t * 97.0 + 2.1)
	return Vector2(x, y) * amplitude


static func can_shake(vibration: bool, reduce_motion: bool) -> bool:
	return vibration and not reduce_motion


## How long the phone buzzes (0 = not at all): only with the setting on, only on a phone.
static func vibration_ms(ms: int, enabled: bool, on_phone: bool) -> int:
	if not enabled or not on_phone or ms <= 0:
		return 0
	return mini(ms, MAX_BUZZ_MS)


## What the local player feels when their hearts go from old_hp to new_hp: {} for a heal, a respawn
## or no change; else {shake (m), seconds, buzz_ms, flash (alpha)}. A knock-out feels biggest.
static func hurt_feel(old_hp: int, new_hp: int) -> Dictionary:
	if new_hp >= old_hp:
		return {}
	if new_hp <= 0:
		return {"shake": KNOCKOUT_SHAKE, "seconds": KNOCKOUT_SHAKE_TIME, "buzz_ms": KNOCKOUT_BUZZ_MS,
			"flash": KNOCKOUT_FLASH}
	var k := clampf((old_hp - new_hp) / 3.0, 0.6, 1.6)
	return {"shake": HURT_SHAKE * k, "seconds": HURT_SHAKE_TIME, "buzz_ms": HURT_BUZZ_MS,
		"flash": HURT_FLASH}


## What a player `distance` blocks from the Golem's slam feels: {} beyond SLAM_REACH, else {shake,
## seconds, buzz_ms}: full inside the shockwave, fading linearly outside it (no buzz there).
static func slam_feel(distance: float) -> Dictionary:
	if not (distance < SLAM_REACH):
		return {}
	var k := 1.0 - clampf((distance - SLAM_RADIUS) / (SLAM_REACH - SLAM_RADIUS), 0.0, 1.0)
	return {"shake": SLAM_SHAKE * k, "seconds": SLAM_SHAKE_TIME,
		"buzz_ms": SLAM_BUZZ_MS if distance <= SLAM_RADIUS else 0}


## A new flash may start at `now` when the last one started at least MIN_FLASH_INTERVAL ago.
static func can_flash(now: float, last_start: float) -> bool:
	return now - last_start >= MIN_FLASH_INTERVAL


static func flash_alpha(alpha: float, reduce_motion: bool) -> float:
	return alpha * REDUCED_FLASH if reduce_motion else alpha


static func flash_time(reduce_motion: bool) -> float:
	return REDUCED_FLASH_TIME if reduce_motion else FLASH_TIME


## A flash of `peak` alpha, `elapsed` seconds after it started, fading out (ease-out) over `duration`.
static func flash_alpha_at(peak: float, elapsed: float, duration: float) -> float:
	if duration <= 0.0 or elapsed >= duration:
		return 0.0
	var k := 1.0 - maxf(elapsed, 0.0) / duration
	return peak * k * k


# --- M5 Task 1: Reduce motion calms the bursts too (gadgets, piñatas, blasters, coin showers; spec §15.1a) ---

const CALM_AMOUNT := 0.5          # half the pieces
const CALM_SPEED := 0.6           # slower


## How many pieces a burst of `amount` has (Reduce motion: half, never none).
static func burst_amount(amount: int, reduce_motion: bool) -> int:
	return maxi(1, roundi(amount * CALM_AMOUNT)) if reduce_motion else amount


## How fast a burst plays (its particles' speed_scale).
static func burst_speed_scale(reduce_motion: bool) -> float:
	return CALM_SPEED if reduce_motion else 1.0
