class_name CameraRig
extends Node3D
## Third-person orbit camera (spring arm, never clips through blocks) with a first-person toggle.
## Top-level so it follows the player smoothly instead of inheriting the body's rotation.

const TOUCH_SENSITIVITY := 0.006   # radians per pixel of finger drag
const MOUSE_SENSITIVITY := 0.003
const THIRD_PERSON_DISTANCE := 4.5
const HEAD_HEIGHT := 1.55
const PITCH_MIN := -1.4
const PITCH_MAX := 1.2
const FOLLOW_SHARPNESS := 18.0

var yaw := 0.0
var pitch := -0.35
var first_person := false
var size_scale := 1.0
var _target: Node3D
var _shake_strength := 0.0        # M2 Task 11: the view wobble (Feel.shake), FeelRules decides its size
var _shake_time := 0.0
var _shake_elapsed := 0.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	top_level = true
	arm.spring_length = THIRD_PERSON_DISTANCE


func set_target(target: Node3D) -> void:
	_target = target
	global_position = _head_position()


func look(delta_px: Vector2, sensitivity: float) -> void:
	if vr_mode():
		return   # owner #101: in VR only the child's own head turns the view (a stick, a finger, a mouse never do)
	_looked_at = Time.get_ticks_msec()   # M3 Task 21a: Simple controls' camera waits after the child turns it
	yaw -= delta_px.x * sensitivity
	pitch = clampf(pitch - delta_px.y * sensitivity, PITCH_MIN, PITCH_MAX)


func toggle_first_person() -> void:
	if vr_mode():
		return   # owner #101: VR is first person only (a trailing camera is a strong sickness trigger)
	first_person = not first_person
	arm.spring_length = 0.0 if first_person or peek_from.is_finite() else _third_person_distance()


func set_size_scale(s: float) -> void:
	size_scale = s
	if vr_mode():
		Vr.set_world_scale(s)   # owner #101 (P3): a giant child feels giant (the play space's scale), behind a blink
	if not first_person and not peek_from.is_finite():
		arm.spring_length = _third_person_distance()


func _third_person_distance() -> float:
	return THIRD_PERSON_DISTANCE * maxf(size_scale, 0.4)


## Horizontal forward direction the camera is facing.
func forward_flat() -> Vector3:
	return Basis(Vector3.UP, yaw) * Vector3.FORWARD


func snap_to_target() -> void:
	if vr_mode():
		Vr.blink()   # owner #101: every jump in place (a spawn, a rescue, a portal, home) is a black blink in VR
		return
	global_position = _head_position()


## A short view wobble of `strength` metres easing out to nothing over `seconds` (Feel.shake calls it
## on the local camera, which checks the settings). A weaker shake never cuts a stronger one short.
func shake(strength: float, seconds: float) -> void:
	if vr_mode():
		return   # owner #101: never a camera move the child did not make
	if strength > shake_amplitude():
		_shake_strength = strength
		_shake_time = seconds
		_shake_elapsed = 0.0


func shake_amplitude() -> float:
	return FeelRules.shake_amplitude(_shake_strength, _shake_time, _shake_elapsed)


## Moves the view (the camera's offsets, so the spring arm and aiming are untouched); back to 0 at the end.
func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		return
	_shake_elapsed += delta
	var off := FeelRules.shake_offset(shake_amplitude(), _shake_elapsed)
	camera.h_offset = off.x
	camera.v_offset = off.y
	if _shake_elapsed >= _shake_time:
		_shake_time = 0.0


func _process(delta: float) -> void:
	if vr_mode():
		_vr_process()
		return
	if _vr_on:
		_vr_off()
	_update_shake(delta)
	if _target == null:
		return
	var goal := _head_position()
	if first_person or peek_from.is_finite():
		global_position = goal
	else:
		global_position = global_position.lerp(goal, clampf(FOLLOW_SHARPNESS * delta, 0.0, 1.0))
	rotation = Vector3(pitch, yaw, 0.0)


func _head_position() -> Vector3:
	if peek_from.is_finite():
		return peek_from
	return _target.global_position + Vector3(0, HEAD_HEIGHT * size_scale * height_factor, 0)

# --- M2 Task 5: crouching and hiding ---

## Crouching lowers the camera to this share of the head height (StealthRules.CROUCH_EYE).
var height_factor := 1.0
## Inside a barrel or closet the camera looks out from here, close up (no spring arm); INF otherwise.
var peek_from := Vector3.INF


func set_peek(at: Vector3) -> void:
	peek_from = at
	if vr_mode() and Vr.rig != null:
		Vr.rig.eye_override = at   # owner #101 (P3): the eye inside the barrel or closet, looking out
		Vr.set_head_blocked(0.0)
		Vr.blink()
	arm.spring_length = 0.0 if first_person or at.is_finite() else _third_person_distance()
	if _target:
		snap_to_target()

# --- M3 Task 21a: Simple controls ---

var _looked_at := -100000


## Seconds since the child last turned the camera (Simple controls follow only after a rest).
func since_look() -> float:
	return (Time.get_ticks_msec() - _looked_at) / 1000.0

# --- Owner #101: VR on the Meta Quest (docs/devlog/parts/vr-rig.md) ---

var _vr_on := false
var _vr_last_yaw := 0.0
var _vr_eye := NAN


## This rig's player is the one the headset follows: the view is the head's (first person, no spring arm, no shake).
func vr_mode() -> bool:
	return _target != null and Vr.active() and Vr.anchor_node() == _target


## Gameplay keeps reading yaw and pitch: in VR they are the head's. A yaw the game writes (a portal's arrival, a world's
## saved facing) turns the origin round the head instead (behind the spawn's or the portal's fade). The rig's own camera
## stays where the head is, so everything that asks the player's camera sees the head; the XR camera is the one drawn.
func _vr_process() -> void:
	if not _vr_on:
		_vr_on = true
		Vr.set_world_scale(size_scale)   # a child already giant or tiny when the headset starts
		Vr.face(yaw)   # the head looks where the player looked
	elif absf(angle_difference(_vr_last_yaw, yaw)) > 0.0001:
		Vr.turn(angle_difference(_vr_last_yaw, yaw))
	var head := Vr.head_transform()
	yaw = VrRules.yaw_of(head.basis)
	pitch = clampf(VrRules.pitch_of(head.basis), PITCH_MIN, PITCH_MAX)
	_vr_last_yaw = yaw
	_shake_time = 0.0
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	arm.spring_length = 0.0
	global_position = head.origin
	rotation = Vector3(pitch, yaw, 0.0)
	_vr_eye_height(HEAD_HEIGHT * size_scale * height_factor)


## The avatar's eye height for the headset ("game height"); a big change (a crouch, a size change) blinks.
func _vr_eye_height(eye: float) -> void:
	if Vr.rig == null:
		return
	if not is_nan(_vr_eye) and VrRules.needs_height_fade(_vr_eye, eye):
		Vr.rig.eye_height = eye
		Vr.blink()
	else:
		Vr.rig.eye_height = eye
	_vr_eye = eye


## The headset is off again: the spring arm comes back as the child had it.
func _vr_off() -> void:
	_vr_on = false
	_vr_eye = NAN
	arm.spring_length = 0.0 if first_person or peek_from.is_finite() else _third_person_distance()
