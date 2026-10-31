class_name VrRig
extends XROrigin3D
## Owner #101 (VR on the Meta Quest; docs/devlog/parts/vr-rig.md): the child's play space. The origin, the head (an
## XRCamera3D: it is the view, the 3D audio listener and get_camera_3d() for everything that measures distances) and two
## hands (XRController3D), kept by the Vr autoload across scene changes.
##
## The origin follows its anchor and nothing else moves it. It is placed so the tracked head sits at the anchor's eye:
## a player's feet plus the avatar's eye height ("game height": a seated or a small child sees the world as the phone
## shows it; "real height" puts the origin on the feet instead), a menu's spot, a seat. Between physics ticks the place is
## interpolated (the anchor moves at the physics rate, the headset draws at 72 Hz). It turns only round the head
## (turn: snap turn, a portal's facing), so the child turns on the spot.
## Room scale: a child who steps sideways moves the head off the feet; the player walks the body after it
## (Player._vr_room_scale) and body_moved() takes that step back out of the offset, so the view never moves.
## P3: a seat (the rocket's capsule) carries the origin's whole transform every frame (place_seat: its turns are the
## child's frame, capped by the flight); a guest's own mount is followed through a filter (predict); a hiding spot puts
## the eye inside it (eye_override); Size Magic is the origin's world_scale (a giant child's head and eyes 3× apart).

const NEAR := 0.05
const FAR := 300.0   # the player camera's (SkyCycle's stars float at 250)
const FEET := &"feet"
const SEAT := &"seat"

var head: XRCamera3D
## VrRules.LEFT / RIGHT -> XRController3D.
var hands := {}
var comfort: VrComfort

## The origin's turn round the up axis (radians, as CameraRig.yaw; in a seat, round the seat's up).
var yaw := 0.0
## The origin minus the anchor's eye point, in world axes (in a seat: the seat's); its y takes the tracked head's
## height away.
var offset := Vector3.ZERO
## A feet anchor's eye above its feet (CameraRig sets it: the avatar's head height × size × crouch).
var eye_height := CameraRig.HEAD_HEIGHT
## "real" height: a feet anchor puts the origin on the feet (the tracked floor is the ground).
var real_height := false
## The head's rise is eased (VrRules.step_ease: the auto-step's hop) while walking; never while flying.
var ease_steps := true
## A guest's own mount arrives 10-20 times a second: the place is followed through VrRules.alpha_beta (smooth, with the
## mount's speed, so the head never judders on the syncs). Vr sets it while this game's child rides as a guest.
var predict := false
## Where a hiding spot puts the eye (CameraRig.set_peek in VR: the barrel's inside as a little cockpit); INF otherwise.
var eye_override := Vector3.INF
## The origin's speed (m/s) and acceleration (m/s²) over the last ticks (the comfort vignette reads them).
var velocity := Vector3.ZERO
var accel := 0.0

var _prev := Vector3.INF
var _cur := Vector3.INF
var _ease_y := NAN
var _pred_x := Vector3.INF
var _pred_v := Vector3.ZERO


func _init() -> void:
	name = "VrRig"
	head = XRCamera3D.new()
	head.name = "Head"
	head.near = NEAR
	head.far = FAR
	add_child(head)
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var c := XRController3D.new()
		c.name = "LeftHand" if side == VrRules.LEFT else "RightHand"
		c.tracker = tracker_name(side)
		c.pose = &"aim"   # OpenXR names the action map's aim_pose "aim" on the tracker; WebXR sets "aim" too
		add_child(c)
		hands[side] = c
	comfort = VrComfort.new()
	head.add_child(comfort)


static func tracker_name(side: StringName) -> StringName:
	return &"left_hand" if side == VrRules.LEFT else &"right_hand"


## The tracked head in the play space (origin space, world scale applied), read from its tracker at once (a new world
## scale counts before the next pose arrives); the head node's own transform without one.
func head_local() -> Transform3D:
	var t := XRServer.get_tracker(&"head") as XRPositionalTracker
	if t != null and t.has_pose(&"default"):
		var pose := t.get_pose(&"default")
		if pose != null and pose.has_tracking_data:
			return pose.get_adjusted_transform()
	return head.transform


## The anchor's eye point (the place the tracked head is put at).
func eye_point(node: Node3D, kind: StringName) -> Vector3:
	if kind == FEET and eye_override.is_finite():
		return eye_override
	var p := node.global_position
	if kind == FEET and not real_height:
		p.y += eye_height
	return p


## Where the origin goes for the anchor now.
func target(node: Node3D, kind: StringName) -> Vector3:
	var e := eye_point(node, kind)
	if kind == FEET and real_height and not eye_override.is_finite():
		return Vector3(e.x + offset.x, e.y, e.z + offset.z)
	return e + offset


## Puts the tracked head on the anchor's eye; `face` (radians; NAN keeps the turn) also turns it to look that way.
func recenter(node: Node3D, kind: StringName, face: float = NAN) -> void:
	if kind == SEAT:
		recenter_seat()
		place_seat(node.global_transform)
		return
	var h := head_local()
	if not is_nan(face):
		yaw = face - VrRules.yaw_of(h.basis)
	var hr := Basis(Vector3.UP, yaw) * h.origin
	offset = Vector3(-hr.x, -h.origin.y, -hr.z)
	reset_history(target(node, kind))


## Starts the interpolation over at `p` (a jump in place: never glide across it).
func reset_history(p: Vector3) -> void:
	_prev = p
	_cur = p
	_ease_y = NAN
	_pred_x = Vector3.INF
	velocity = Vector3.ZERO
	accel = 0.0
	_place(p)


## A physics tick (`dt` s long): the anchor's new origin place, interpolated towards by follow(). True when it jumped
## further than a child moves (VrRules.JUMP_FADE_METRES: a teleport the safety net blinks for; never glided across).
func record(p: Vector3, dt: float = 1.0 / 60.0) -> bool:
	var jumped := _cur.is_finite() and _cur.distance_to(p) > VrRules.JUMP_FADE_METRES
	if predict and not jumped:
		if not _pred_x.is_finite():
			_pred_x = p
			_pred_v = Vector3.ZERO
		var f := VrRules.alpha_beta(_pred_x, _pred_v, p, dt)
		_pred_x = f[0]
		_pred_v = f[1]
		p = _pred_x
	else:
		_pred_x = Vector3.INF
	if not _cur.is_finite() or jumped:
		_prev = p
		_ease_y = NAN
		velocity = Vector3.ZERO
		accel = 0.0
	else:
		_prev = _cur
		if dt > 0.0:
			var v := (p - _cur) / dt
			accel = lerpf(accel, (v - velocity).length() / dt, 0.2)
			velocity = velocity.lerp(v, 0.5)
	_cur = p
	return jumped


## A drawn frame: between the last two ticks (`fraction`: Engine.get_physics_interpolation_fraction()).
func follow(fraction: float, delta: float) -> void:
	if not _cur.is_finite():
		return
	var p := _prev.lerp(_cur, clampf(fraction, 0.0, 1.0))
	_ease_y = VrRules.step_ease(_ease_y, p.y, delta) if ease_steps else p.y
	p.y = _ease_y
	_place(p)


func _place(p: Vector3) -> void:
	global_transform = Transform3D(Basis(Vector3.UP, yaw), p)


## Turns the child on the spot by `radians` (round the head).
func turn(radians: float) -> void:
	var before := global_transform
	var turned := VrRules.turn_about(before, before * head_local().origin, radians)
	var d := turned.origin - before.origin
	d.y = 0.0
	yaw += radians
	offset += d
	if _prev.is_finite():
		_prev += d
		_cur += d
	global_transform = Transform3D(Basis(Vector3.UP, yaw), before.origin + d)


## The tracked head's place from the feet anchor's, sideways only (world axes; this tick, not interpolated).
func head_offset() -> Vector3:
	var hr := Basis(Vector3.UP, yaw) * head_local().origin
	return Vector3(offset.x + hr.x, 0.0, offset.z + hr.z)


## The body walked `moved` after the head (room scale): the origin stays where it is.
func body_moved(moved: Vector3) -> void:
	offset.x -= moved.x
	offset.z -= moved.z

# --- P3: a seat (the rocket's capsule): the origin rides the seat's whole transform, every frame ---

## The head over the seat's middle, looking along the seat's forward (seat space).
func recenter_seat() -> void:
	var h := head_local()
	yaw = -VrRules.yaw_of(h.basis)
	offset = -(Basis(Vector3.UP, yaw) * h.origin)


## The origin for a seat at `seat` (its turns included: the capsule's frame is the child's).
func place_seat(seat: Transform3D) -> void:
	global_transform = seat * Transform3D(Basis(Vector3.UP, yaw), offset)


## Turns the seated child on the spot (round the head, in the seat's frame).
func turn_in_seat(radians: float, seat: Transform3D) -> void:
	var local := Transform3D(Basis(Vector3.UP, yaw), offset)
	var turned := VrRules.turn_about(local, local * head_local().origin, radians)
	yaw += radians
	offset = turned.origin
	place_seat(seat)
