class_name VrPanelRules
extends RefCounted
## VR on the Meta Quest (owner #101; docs/superpowers/plans/2026-10-15-vr-quest.md), the panel side: where the VR canvas
## (the game's 1280×720 of 2D UI, Vr.ui_viewport()) shows in the world and how a hand's ray lands on it. Pure.
##
## - **EYE** (a menu, a board, the pause menu, a world loading): 1.6 × 0.9 m, 1.4 m ahead of the head's yaw and a little
##   below the eyes, never tilted with the head; world-fixed, re-centred only when the head turns past 50° (nothing is
##   pinned to the face: comfort, docs/devlog/parts/vr-research.md "Comfort risks").
## - **TRAY** (playing: the HUD): the same canvas 1 m wide, 0.9 m away and 35° below the eyes, tilted to face them,
##   following the head's yaw lazily (a glance aside leaves it; a turn brings it round).
## At 1.4 m the eye panel is about 21 canvas pixels a degree: about one canvas pixel per Quest 2 pixel (20 a degree).

const CANVAS := Vector2i(1280, 720)
const EYE_SIZE := Vector2(1.6, 0.9)
const EYE_DISTANCE := 1.4
## The eye panel's middle this far below the eyes (looking a little down is the restful way).
const EYE_DROP := 0.1
const RECENTRE_DEGREES := 50.0
const TRAY_SIZE := Vector2(1.0, 0.5625)
const TRAY_DISTANCE := 0.9
const TRAY_DOWN_DEGREES := 35.0
## The tray stays where it is while the head turns less than this from it.
const TRAY_SLACK_DEGREES := 25.0
## How fast the tray catches up once it follows (per second, exponential).
const TRAY_FOLLOW := 4.0
## It rests again within this of the head's yaw.
const TRAY_REST_DEGREES := 2.0

const HIDDEN := &"hidden"
const EYE := &"eye"
const TRAY := &"tray"
## Owner #127 (2026-10-17, on the Quest 3: "the menu i see always on the screen should be shows not always, only when i
## raise my elbow like covering a shield"): while playing in a headset the HUD is not in view all the time any more; it
## shows on the forearm of the hand that does not point when that forearm is raised in front of the face like a shield
## (shield_up), on a small panel just above the hand facing the eyes (shield_transform). The desktop preview keeps TRAY.
const SHIELD := &"shield"
const SHIELD_SIZE := Vector2(0.5, 0.28125)   # the tray's canvas at half its distance: the same size to the eyes
## The raised forearm, the hand seen in the head's yaw frame: SHIELD_AHEAD metres ahead of the eyes, SHIELD_BELOW below
## them (a negative minimum: a little above is fine), at most SHIELD_ASIDE to either side, and the hand's line (the
## index finger's, the grip's -Z) across the body: |its flat direction · the head's right| at least SHIELD_ACROSS. Once
## up, SHIELD_SLACK more room and a looser line, so it never flickers at an edge.
const SHIELD_AHEAD := Vector2(0.12, 0.7)
const SHIELD_BELOW := Vector2(-0.15, 0.5)
const SHIELD_ASIDE := 0.45
const SHIELD_ACROSS := 0.5
const SHIELD_SLACK := 0.08
const SHIELD_LIFT := 0.12   # the panel's middle this far above the hand

## The visual layers every VR panel, beam and room is drawn on: the world's, and the rocket flight's space set
## (RocketFlight.LAYER: in a flight the head draws only the flight camera's layers, Vr.view_like).
const LAYERS := 1 | RocketFlight.LAYER

## No hit: hit() returns this (u, v, distance).
const MISS := Vector3(-1, -1, -1)


## The yaw of where the head looks (radians, Godot's: 0 looks along -Z, +90° along -X). Looking straight down or up, the
## head's top says it.
static func head_yaw(head: Transform3D) -> float:
	var forward := -head.basis.z
	var flat := Vector3(forward.x, 0.0, forward.z)
	if flat.length_squared() < 0.0004:   # within about 1° of straight down or up
		var up := head.basis.y if forward.y < 0.0 else -head.basis.y
		flat = Vector3(up.x, 0.0, up.z)
	return atan2(-flat.x, -flat.z)


## The eye panel's place for `head` (its front, +Z, faces the child).
static func eye_transform(head: Transform3D) -> Transform3D:
	var b := Basis(Vector3.UP, head_yaw(head))
	return Transform3D(b, head.origin + b * Vector3(0.0, -EYE_DROP, -EYE_DISTANCE))


## True when the head has turned so far from the panel (yaws in radians) that it comes round in front again.
static func needs_recentre(panel_yaw: float, yaw: float) -> bool:
	return absf(angle_difference(panel_yaw, yaw)) > deg_to_rad(RECENTRE_DEGREES)


## The tray's place below the eyes at `head_pos` along `yaw`, tilted so its front faces the eyes.
static func tray_transform(head_pos: Vector3, yaw: float) -> Transform3D:
	var down := deg_to_rad(TRAY_DOWN_DEGREES)
	var b := Basis(Vector3.UP, yaw)
	var at := head_pos + b * (Vector3(0.0, -sin(down), -cos(down)) * TRAY_DISTANCE)
	return Transform3D(b * Basis(Vector3.RIGHT, -down), at)


## One step of the tray's lazy yaw towards the head's: [yaw, following]. It starts following past the slack and rests
## once it is in front again.
static func tray_yaw(current: float, target: float, following: bool, delta: float) -> Array:
	var diff := angle_difference(current, target)
	if not following and absf(diff) <= deg_to_rad(TRAY_SLACK_DEGREES):
		return [current, false]
	var yaw := wrapf(current + diff * (1.0 - exp(-TRAY_FOLLOW * delta)), -PI, PI)
	return [yaw, absf(angle_difference(yaw, target)) > deg_to_rad(TRAY_REST_DEGREES)]


## Owner #127: is the forearm of `hand` (the hand that does not point, in the world) raised in front of `head` like a
## shield? `was_up`: it was a frame ago (then the edges give a little).
static func shield_up(head: Transform3D, hand: Transform3D, was_up: bool) -> bool:
	var frame := Basis(Vector3.UP, head_yaw(head))
	var rel := frame.inverse() * (hand.origin - head.origin)
	var slack := SHIELD_SLACK if was_up else 0.0
	var ahead := -rel.z
	var below := -rel.y
	if ahead < SHIELD_AHEAD.x - slack or ahead > SHIELD_AHEAD.y + slack:
		return false
	if below < SHIELD_BELOW.x - slack or below > SHIELD_BELOW.y + slack or absf(rel.x) > SHIELD_ASIDE + slack:
		return false
	var line := -hand.basis.z
	line.y = 0.0
	if line.length() < 0.2:
		return was_up   # the hand's line points up or down: no change
	return absf(line.normalized().dot(frame * Vector3.RIGHT)) >= SHIELD_ACROSS - (0.15 if was_up else 0.0)


## Owner #127: the shield panel just above `hand`, its front (+Z) facing the eyes at `head_pos`.
static func shield_transform(head_pos: Vector3, hand: Transform3D) -> Transform3D:
	var at := hand.origin + Vector3(0.0, SHIELD_LIFT, 0.0)
	var z := head_pos - at
	z = z.normalized() if z.length() > 0.001 else Vector3.BACK
	var x := Vector3.UP.cross(z)
	x = x.normalized() if x.length() > 0.001 else Vector3.RIGHT
	return Transform3D(Basis(x, z.cross(x), z), at)


## Where a ray (`origin`, `dir`) lands on a panel at `panel` of `size` metres: Vector3(u, v, distance), u and v from the
## canvas's top-left (0..1); MISS when it passes by, points away or comes from behind (only the front takes a pointer).
static func hit(panel: Transform3D, size: Vector2, origin: Vector3, dir: Vector3) -> Vector3:
	var normal := panel.basis.z.normalized()
	var facing := normal.dot(dir)
	if facing > -0.00001:
		return MISS
	var t := normal.dot(panel.origin - origin) / facing
	if t < 0.0:
		return MISS
	var local := panel.affine_inverse() * (origin + dir * t)
	var u := local.x / size.x + 0.5
	var v := 0.5 - local.y / size.y
	if u < 0.0 or u > 1.0 or v < 0.0 or v > 1.0:
		return MISS
	return Vector3(u, v, t)


## The canvas pixel at (u, v).
static func pixel(uv: Vector2, canvas: Vector2i = CANVAS) -> Vector2:
	return (uv * Vector2(canvas)).round()


## The eye panel while something wants the child's attention (a panel has the pad, the game is paused, a world loads),
## else the tray with the HUD.
static func place_for(menu_up: bool, paused: bool, loading: bool) -> StringName:
	return EYE if menu_up or paused or loading else TRAY
