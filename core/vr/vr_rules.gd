class_name VrRules
extends RefCounted
## VR on the Meta Quest (owner #101; docs/superpowers/plans/2026-10-15-vr-quest.md): the comfort settings' keys and their
## defaults, and the numbers both VR sides share. Pure: no nodes, no XR server. The VR-RIG agent adds the locomotion,
## turn, vignette and eye-height curves here; the defaults are the plan's ruling 3 (comfort first, for children).

## The interfaces Vr.start() knows: OpenXR in the native Quest APK (feature tag "quest") and WebXR in the Quest's browser
## (the Web VR export, feature tag "webxr").
const OPENXR := &"openxr"
## Owner #126: the child's own hands draw on the world's layer and on this one, which the head always draws (a flight in
## space shows only its own layers: Vr.view_like). Free in the game's layers (the lens 1 << 16, the selfie 1 << 17, the
## flight 1 << 18 and 1 << 19).
const HANDS_LAYER := 1 << 15
const WEBXR := &"webxr"

## Settings keys (ProfileData's settings, the VR COMFORT page) and their defaults.
const TURN := "vr_turn"                 # "snap45" | "snap30" | "smooth"
const TURN_DEFAULT := "snap45"
const VIGNETTE := "vr_vignette"         # "strong" | "light" | "off"
const VIGNETTE_DEFAULT := "light"
const WALK_DIR := "vr_walk_dir"         # "head" | "hand"
const WALK_DIR_DEFAULT := "head"
const TELEPORT := "vr_teleport"         # true: right stick up aims a teleport arc (P3)
const TELEPORT_DEFAULT := true
const HEIGHT := "vr_height"             # "game": the eye at the avatar's height; "real": the floor's
const HEIGHT_DEFAULT := "game"
const BREAK_MINUTES := "vr_break_minutes"   # a break card after this long in the headset (0: never)
const BREAK_MINUTES_DEFAULT := 30

const DEFAULTS := {
	TURN: TURN_DEFAULT,
	VIGNETTE: VIGNETTE_DEFAULT,
	WALK_DIR: WALK_DIR_DEFAULT,
	TELEPORT: TELEPORT_DEFAULT,
	HEIGHT: HEIGHT_DEFAULT,
	BREAK_MINUTES: BREAK_MINUTES_DEFAULT,
	SWING: SWING_DEFAULT,   # owner #128: a held sword hits by swinging it (VrRules.SWING)
}

## Every jump in place (a teleport, a portal, a spawn, a scene change) is a black fade: out, then in.
const FADE_OUT := 0.15
const FADE_IN := 0.25
## The anchor moved further than this in one frame without the child walking: the safety net fades.
const JUMP_FADE_METRES := 2.0

## Hands.
const RIGHT := &"right"
const LEFT := &"left"


## A setting's value from `settings` (ProfileData.settings-like), or its default; an unknown key reads null.
static func setting(settings: Dictionary, key: String) -> Variant:
	if not DEFAULTS.has(key):
		return null
	var v: Variant = settings.get(key, DEFAULTS[key])
	return v if typeof(v) == typeof(DEFAULTS[key]) else DEFAULTS[key]


## The snap turn's angle in degrees for a turn setting (0 for smooth turning).
static func snap_degrees(turn: String) -> float:
	match turn:
		"snap30":
			return 30.0
		"smooth":
			return 0.0
		_:
			return 45.0


## The hand that points and acts: the right one, or the left for a left-handed child (the existing left_handed setting).
static func pointing_hand(left_handed: bool) -> StringName:
	return LEFT if left_handed else RIGHT

# --- The VR-RIG side (owner #101, P1): turning, the vignette, the head in a wall, the head's spring, the fades ---

## Snap turn: the turning stick past SNAP_PUSH turns once; it turns again only after it rests under SNAP_REST.
const SNAP_PUSH := 0.7
const SNAP_REST := 0.3
## Smooth turning (opt-in, "smooth"): degrees a second at full tilt.
const SMOOTH_TURN_DEGREES := 90.0
## A stick's dead middle (a resting stick is often a little off).
const STICK_DEADZONE := 0.15
## How dark the comfort vignette's edge gets at full speed, per setting; it grows between these speeds (m/s).
const VIGNETTE_STRENGTH := {"strong": 0.9, "light": 0.6, "off": 0.0}
const VIGNETTE_SPEED_FROM := 1.0
const VIGNETTE_SPEED_FULL := 6.0
## Room scale: the body follows the head once it is this far off it (m). The view fades from black when the head is
## HEAD_FADE_FROM beyond where the body could go (leaning into a wall) and is black at HEAD_FADE_FULL; a head inside
## a solid block is black at once (no x-ray through hills, nor into a hiding spot).
const FOLLOW_DEADZONE := 0.02
const HEAD_FADE_FROM := 0.25
const HEAD_FADE_FULL := 0.4
## The auto-step's hop (7.6 m/s up a one-block ledge) is eased for the head: a spring of this time constant (s), for
## rises up to STEP_EASE_MAX (m); anything bigger snaps (a jump in place, behind a fade), and down is never eased.
const STEP_EASE_TIME := 0.08
const STEP_EASE_MAX := 1.2
## The eye height changes by more than this (m: a crouch, a size change): behind a fade.
const HEIGHT_FADE_METRES := 0.3
## A trigger counts as squeezed past TRIGGER_ON and as let go under TRIGGER_OFF (no flicker in between).
const TRIGGER_ON := 0.6
const TRIGGER_OFF := 0.35
## Controller buzzes: [amplitude 0..1, seconds].
const HAPTIC_PLACE := [0.25, 0.03]
const HAPTIC_BREAK := [0.5, 0.06]
const HAPTIC_TURN := [0.15, 0.02]
## Owner #106/#108 in the rocket: a soft touchdown, the lander's crash, the rocket hitting the ground by the pad (both
## hands; where the flat game shakes its camera).
const HAPTIC_TOUCHDOWN := [0.35, 0.12]
const HAPTIC_CRASH := [0.9, 0.35]
const HAPTIC_WRECK := [0.6, 0.3]
## Feel.flash in VR: a red tint over the view, never stronger than this (a headset fills the eyes).
const TINT_MAX := 0.25


## One frame of the snap turn: {turn: radians (a stick to the right turns clockwise: negative), armed: the next push
## turns}. `degrees` is the setting's (VrRules.snap_degrees).
static func snap_step(x: float, armed: bool, degrees: float) -> Dictionary:
	if armed and absf(x) >= SNAP_PUSH:
		return {"turn": -signf(x) * deg_to_rad(degrees), "armed": false}
	if not armed and absf(x) <= SNAP_REST:
		return {"turn": 0.0, "armed": true}
	return {"turn": 0.0, "armed": armed}


## Smooth turning's radians this frame (clockwise for a stick to the right), nothing in the dead middle.
static func smooth_turn(x: float, delta: float) -> float:
	var m := absf(x)
	if m <= STICK_DEADZONE:
		return 0.0
	var t := minf((m - STICK_DEADZONE) / (1.0 - STICK_DEADZONE), 1.0)
	return -signf(x) * t * deg_to_rad(SMOOTH_TURN_DEGREES) * delta


## The comfort vignette (0 clear .. 1 dark edges) for the setting at `speed` m/s; a smooth turn is full at once.
static func vignette(setting: String, speed: float, turning: bool) -> float:
	var k := float(VIGNETTE_STRENGTH.get(setting, VIGNETTE_STRENGTH[VIGNETTE_DEFAULT]))
	if turning:
		return k
	return k * clampf((speed - VIGNETTE_SPEED_FROM) / (VIGNETTE_SPEED_FULL - VIGNETTE_SPEED_FROM), 0.0, 1.0)


## How black the view is for a head `beyond` metres past where the body could go (0..1), or inside a solid block.
static func head_fade(beyond: float, in_solid: bool) -> float:
	if in_solid:
		return 1.0
	return clampf((beyond - HEAD_FADE_FROM) / (HEAD_FADE_FULL - HEAD_FADE_FROM), 0.0, 1.0)


## The origin turned by `radians` round the up axis through `pivot` (the head): the child turns on the spot.
static func turn_about(origin: Transform3D, pivot: Vector3, radians: float) -> Transform3D:
	var r := Basis(Vector3.UP, radians)
	var pos := pivot + r * (origin.origin - pivot)
	pos.y = origin.origin.y
	return Transform3D(r * origin.basis, pos)


## The yaw of a head's basis, as CameraRig.yaw (forward_flat = Basis(UP, yaw) * FORWARD); a head looking straight up
## or down takes it from its top.
static func yaw_of(b: Basis) -> float:
	var f := -b.z
	if Vector2(f.x, f.z).length() < 0.001:
		f = b.y if f.y < 0.0 else -b.y
	return atan2(-f.x, -f.z)


## The pitch of a head's basis (up is positive), as CameraRig.pitch.
static func pitch_of(b: Basis) -> float:
	return asin(clampf(-b.z.normalized().y, -1.0, 1.0))


## The head's height eased after `target` (the auto-step's hop); down and big jumps at once.
static func step_ease(current: float, target: float, delta: float) -> float:
	if is_nan(current):
		return target
	var d := target - current
	if d <= 0.0 or d > STEP_EASE_MAX:
		return target
	return current + d * (1.0 - exp(-delta / STEP_EASE_TIME))


## A fade's next value towards `target` when the whole way takes `seconds`.
static func fade_step(current: float, target: float, seconds: float, delta: float) -> float:
	if seconds <= 0.0:
		return target
	return move_toward(current, target, delta / seconds)


static func needs_height_fade(old_height: float, new_height: float) -> bool:
	return absf(new_height - old_height) > HEIGHT_FADE_METRES


## Which way the stick walks: where the head looks (default) or where the walking hand points.
static func walk_yaw(setting: String, head_yaw: float, hand_yaw: float) -> float:
	return hand_yaw if setting == "hand" else head_yaw


static func trigger_down(value: float, was_down: bool) -> bool:
	return value > TRIGGER_OFF if was_down else value >= TRIGGER_ON

# --- P3 (owner #101): motion the child did not make, the teleport stick, the seat, the guest's mount ---

## A fall faster than FALL_FROM m/s darkens the edges, fully at FALL_FULL (the strongest drop in VR: Survivor's falls).
const VIGNETTE_FALL_FROM := 4.0
const VIGNETTE_FALL_FULL := 12.0
## A ride's, a gadget's, a pad's or zero-G's acceleration (m/s²) darkens from ACCEL_FROM, fully at ACCEL_FULL; the
## child's own walking (45 m/s² to its 6 m/s) never counts.
const VIGNETTE_ACCEL_FROM := 1.0
const VIGNETTE_ACCEL_FULL := 8.0
## Motion the child did not make is this much stronger.
const VIGNETTE_PASSIVE := 1.5
## The vignette closes in this long (s) and opens again in this long.
const VIGNETTE_IN := 0.08
const VIGNETTE_OUT := 0.4
## The teleport: the turning stick pushed up past TELEPORT_PUSH aims; let back under TELEPORT_REST, it goes.
const TELEPORT_PUSH := 0.7
const TELEPORT_REST := 0.3
## The seated rocket's frame turns at most this fast (degrees a second: its pitch-over, its turn round, the steering).
const SEAT_TURN_DEGREES := 15.0
## A knock-out dims the view to 40 %; sleep fades to black and back this slowly (s).
const KNOCKOUT_DIM := 0.6
const SLEEP_FADE := 1.0
## The guest's own mount (it arrives from the host 10-20 times a second): an alpha-beta filter's gains.
const PREDICT_ALPHA := 0.3
const PREDICT_BETA := 0.04


## The vignette for the body's `velocity` (m/s), its `accel` (m/s²) and whether the child made the motion (`passive`:
## a ride, the dragon and flyers, the glider, the hook, a zipline, a pad's throw, zero-G); a smooth turn is full at once.
static func vignette_motion(setting: String, velocity: Vector3, accel: float, passive: bool, turning: bool) -> float:
	var k := float(VIGNETTE_STRENGTH.get(setting, VIGNETTE_STRENGTH[VIGNETTE_DEFAULT]))
	if k <= 0.0:
		return 0.0
	if turning:
		return k
	var flat := Vector2(velocity.x, velocity.z).length()
	var amount := clampf((flat - VIGNETTE_SPEED_FROM) / (VIGNETTE_SPEED_FULL - VIGNETTE_SPEED_FROM), 0.0, 1.0)
	amount = maxf(amount, clampf((-velocity.y - VIGNETTE_FALL_FROM) / (VIGNETTE_FALL_FULL - VIGNETTE_FALL_FROM), 0.0, 1.0))
	if passive:
		amount = maxf(amount, clampf((accel - VIGNETTE_ACCEL_FROM) / (VIGNETTE_ACCEL_FULL - VIGNETTE_ACCEL_FROM), 0.0, 1.0))
		amount = minf(amount * VIGNETTE_PASSIVE, 1.0)
	return k * amount


## The shown vignette after `delta` s towards `target`: quick to close, slow to open (no flicker).
static func ease_vignette(current: float, target: float, delta: float) -> float:
	var seconds := VIGNETTE_IN if target > current else VIGNETTE_OUT
	return move_toward(current, target, delta / seconds)


## One frame of the teleport stick (`y`: pushed away is +): {aim: the arc shows, go: it was let go while aiming}.
static func teleport_step(y: float, aiming: bool) -> Dictionary:
	if not aiming:
		return {"aim": y >= TELEPORT_PUSH, "go": false}
	if y <= TELEPORT_REST:
		return {"aim": false, "go": true}
	return {"aim": true, "go": false}


## `from` turned towards `to` by at most `max_radians` (the seated rocket's frame).
static func turn_toward(from: Basis, to: Basis, max_radians: float) -> Basis:
	var a := Quaternion(from.orthonormalized())
	var b := Quaternion(to.orthonormalized())
	var angle := a.angle_to(b)
	if angle <= max_radians or angle < 0.0001:
		return to
	return Basis(a.slerp(b, max_radians / angle))


## Owner #128 (2026-10-17: "when i hold a sword and i am waving it should work without clicking … sword is not a
## pistol"): a melee weapon held in the hand hits by swinging it, on by default; empty hands, blocks, a bow or a wand are
## never swung (waving to a friend never punches). The setting can turn it off. Its key is new ("vr_swing" was P4's
## opt-in, off by default and saved in every profile: the old key is left behind so the new default reaches everyone).
const SWING := "vr_sword_swing"
const SWING_DEFAULT := true
## A swing: the pointing hand faster than SWING_FROM m/s (in the play space: walking never counts) hits once; it may
## hit again after slowing under SWING_REST.
const SWING_FROM := 2.2
const SWING_REST := 1.0
## The bow drawn with two hands: the string hand takes the string within BOW_GRAB m of the bow hand and pulls; the arrow
## flies at full power from BOW_FULL_DRAW m apart.
const BOW_GRAB := 0.22
const BOW_NOCK := 0.12
const BOW_FULL_DRAW := 0.6


## One frame of a swing: {hit: this frame starts one, swinging}.
static func swing_step(speed: float, swinging: bool) -> Dictionary:
	if not swinging and speed >= SWING_FROM:
		return {"hit": true, "swinging": true}
	return {"hit": false, "swinging": swinging and speed > SWING_REST}


## The string hand (`apart` m from the bow hand) can take the string.
static func bow_grabs(apart: float) -> bool:
	return apart <= BOW_GRAB


## The draw's power (0..1) with the hands `apart` m apart.
static func bow_power(apart: float) -> float:
	return clampf((apart - BOW_NOCK) / (BOW_FULL_DRAW - BOW_NOCK), 0.0, 1.0)


## One tick of the guest's mount: the place `x` and speed `v` shown, the place `z` the game has now; [x, v] next.
static func alpha_beta(x: Vector3, v: Vector3, z: Vector3, dt: float) -> Array:
	if dt <= 0.0:
		return [x, v]
	var predicted := x + v * dt
	var r := z - predicted
	return [predicted + r * PREDICT_ALPHA, v + r * (PREDICT_BETA / dt)]
