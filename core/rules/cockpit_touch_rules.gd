class_name CockpitTouchRules
extends RefCounted
## Owner #110 (VR round 4, idea 8; docs/devlog/parts/vr-ideas-research.md §5.3, the notes docs/devlog/parts/vr-r4-sound.md):
## the cockpit you touch, pure. In a headset the rocket's dashboard (FlightCockpit's band on VrUi's quad at
## RocketFlight.vr_dashboard(), 0.55 m ahead of the seated child) has three big buttons in a row over its screens: STAGE
## and LEGS light up when the flight waits for them, LIGHTS turns the capsule's cabin lights off and on. The index
## fingertip of either hand pokes them (VR-UI's ruling 22, "the dashboard is a display", stays for everything else; A and
## the trigger keep working). On the burns both controllers rumble low, stronger with more throttle, in short pulses
## (never one long buzz) and capped; the stage separation is a thump; the countdown's last three seconds tick.

const STAGE := FlightPlan.STAGE
const LEGS := FlightPlan.LEGS
const LIGHTS := &"lights"
const BUTTONS: Array[StringName] = [STAGE, LEGS, LIGHTS]
const _WORDS := {STAGE: "STAGE", LEGS: "LEGS", LIGHTS: "LIGHTS"}

## A button (canvas px: 84 x 54 mm on the quad, Meta's minimum is 22 mm) and the gap between two (17 mm).
const BUTTON_PX := Vector2(150, 96)
const GAP_PX := 30.0
## The row's bottom this far over the screens' top (px).
const ROW_ABOVE := 10.0

## A press: the fingertip comes in through the panel's face (z, m, in front positive) over a button; again only after
## it came back out RELEASE; a fingertip deeper than BEHIND is a hand round the panel, never a press. HOVER: close over
## a button it glows.
const PRESS_DEPTH := 0.0
const RELEASE := 0.015
const BEHIND := 0.04
const HOVER := 0.05

## The burn's rumble: a pulse of RUMBLE_PULSE every RUMBLE_EVERY (s) at RUMBLE_HZ, its amplitude from RUMBLE_MIN to
## RUMBLE_MAX with the engines' fire (none under RUMBLE_FIRE).
const RUMBLE_EVERY := 0.25
const RUMBLE_PULSE := 0.12
const RUMBLE_HZ := 70.0
const RUMBLE_FIRE := 0.05
const RUMBLE_MIN := 0.08
const RUMBLE_MAX := 0.4
## [amplitude, seconds, Hz]: the stage separation's thump, the countdown's tick (its last TICKS_FROM seconds), a button
## going in (lit), and a dark button (nothing to do now).
const THUMP := [0.85, 0.15, 45.0]
const TICK := [0.3, 0.03, 250.0]
const TICKS_FROM := 3
const CLICK := [0.45, 0.035, 180.0]
const DARK := [0.15, 0.02, 120.0]


static func word(button: StringName) -> String:
	return str(_WORDS.get(button, ""))


## A canvas pixel on the dashboard's quad, in millimetres.
static func mm_per_px() -> float:
	return VrUi.DASHBOARD_WIDTH * 1000.0 / float(VrPanelRules.CANVAS.x)


## The dashboard quad's size (m), as VrUi makes it.
static func quad_size() -> Vector2:
	return Vector2(VrUi.DASHBOARD_WIDTH, VrUi.DASHBOARD_WIDTH * FlightCockpit.DASH_REGION_H / float(VrPanelRules.CANVAS.x))


## The buttons' rectangles (canvas px) on the dashboard band `band`: a row in the middle, over the screens.
static func button_rects(band: Rect2) -> Dictionary:
	var width := BUTTON_PX.x * BUTTONS.size() + GAP_PX * (BUTTONS.size() - 1)
	var bottom := band.end.y - FlightCockpit.DASH_H + 22.0 - ROW_ABOVE   # the screens' top (FlightCockpit._layout)
	var out := {}
	for i in BUTTONS.size():
		out[BUTTONS[i]] = Rect2(Vector2(band.get_center().x - width * 0.5 + i * (BUTTON_PX.x + GAP_PX),
			bottom - BUTTON_PX.y), BUTTON_PX)
	return out


## A point on the quad (the dashboard node's space: x right, y up, the quad's middle at its origin) as a canvas pixel of
## `band`.
static func to_canvas(local: Vector3, band: Rect2) -> Vector2:
	var q := quad_size()
	return band.position + Vector2(local.x / q.x + 0.5, 0.5 - local.y / q.y) * band.size


## The index fingertip of `side`'s hand (VrHandModel's mitten, its trigger curling the finger) gripped at `grip`, the
## hand `size` times as big (Size Magic).
static func fingertip(grip: Transform3D, side: StringName, trigger: float, size := 1.0) -> Vector3:
	var inward := -1.0 if side == VrRules.RIGHT else 1.0
	var base := Vector3(inward * (VrHandModel.PALM.x * 0.5 - VrHandModel.INDEX.x * 0.5), 0.002, -VrHandModel.PALM.z * 0.5)
	var curl := Basis(Vector3.RIGHT, -clampf(trigger, 0.0, 1.0) * VrHandModel.INDEX_CURL)
	var finger := curl * Vector3(0, 0, -VrHandModel.INDEX.z)
	return grip * ((base + finger) * size)


## The button under `at` (canvas px), &"" for none.
static func under(at: Vector2, rects: Dictionary) -> StringName:
	for b: StringName in rects:
		if (rects[b] as Rect2).has_point(at):
			return b
	return &""


## One fingertip's frame: `z` its height over the panel's face (m), `at` where it is on it (canvas px). `state` (the
## call keeps it, one per hand) remembers the last height and whether it came back out. The button pressed now, &"".
static func poke(state: Dictionary, z: float, at: Vector2, rects: Dictionary) -> StringName:
	var was := float(state.get("z", -INF))
	if z > RELEASE:
		state.armed = true
	var pressed := &""
	if bool(state.get("armed", true)) and was > PRESS_DEPTH and z <= PRESS_DEPTH and z > -BEHIND:
		state.armed = false   # in through the face: nothing else until it is out again (sliding on presses nothing)
		pressed = under(at, rects)
	state.z = z
	return pressed


## The button a fingertip `z` over the face at `at` hovers over (it glows), &"".
static func hover(z: float, at: Vector2, rects: Dictionary) -> StringName:
	return under(at, rects) if z > PRESS_DEPTH and z <= HOVER else &""


## The burn's rumble for the engines' `fire` (0..1): 0 under RUMBLE_FIRE.
static func rumble(fire: float) -> float:
	if fire < RUMBLE_FIRE:
		return 0.0
	return lerpf(RUMBLE_MIN, RUMBLE_MAX, clampf((fire - RUMBLE_FIRE) / (1.0 - RUMBLE_FIRE), 0.0, 1.0))
