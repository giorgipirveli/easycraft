class_name VrPoseRules
extends RefCounted
## Owner #101 (VR on the Meta Quest, P4): a VR player's head and both hands in SIZE bytes (Player.vr_pose, sent by its
## VrPoseLink 20 times a second to the games that ask), so other games show its head turning and its hands floating.
## Pure.
## Everything is in the body's space: the origin at the feet, turned by the avatar's synced yaw (Avatar:rotation), and
## divided by the size's scale (a giant's reach fits the same bytes). The layout (VERSION 1):
##   [0] VERSION
##   [1..3] the head's Euler angles (YXZ: pitch ±90°, yaw ±180°, roll ±90°), int8 each
##   [4..6] the head's place from the eye point (0, eye height, 0), ±0.5 m, int8 each (4 mm)
##   [7..9] the left hand's place from the eye point, ±1.27 m, int8 each (1 cm)
##   [10..12] the left hand's turn: a quaternion's x, y, z (w kept positive and worked out), int8 each
##   [13] the left hand's grip (high 4 bits) and trigger (low 4 bits), 0..15
##   [14..20] the right hand, the same way
## Empty (a phone, the web, a game not in VR), too short or another VERSION decodes to {} (no pose: never an error, never
## a misread); more bytes after a known layout are left alone (a later version may add some).

const VERSION := 1
const SIZE := 21
const HZ := SyncPace.PLAYER_HZ
const HEAD_RANGE := 0.5
const HAND_RANGE := 1.27


static func encode(head: Transform3D, left: Transform3D, right: Transform3D, grips: Vector4, eye_height: float,
		scale: float) -> PackedByteArray:
	var s := maxf(scale, 0.01)
	var eye := Vector3(0.0, eye_height, 0.0)
	var b := PackedByteArray()
	b.resize(SIZE)
	b[0] = VERSION
	var e := head.basis.orthonormalized().get_euler()
	_put(b, 1, e.x / (PI * 0.5))
	_put(b, 2, e.y / PI)
	_put(b, 3, e.z / (PI * 0.5))
	_put_vec(b, 4, (head.origin - eye) / s / HEAD_RANGE)
	_put_hand(b, 7, left, eye, s, grips.x, grips.y)
	_put_hand(b, 14, right, eye, s, grips.z, grips.w)
	return b


## {head, left, right (Transform3D in the body's space), left_grip, left_trigger, right_grip, right_trigger} or {}.
static func decode(bytes: PackedByteArray, eye_height: float, scale: float) -> Dictionary:
	if bytes.size() < SIZE or bytes[0] != VERSION:
		return {}
	var s := maxf(scale, 0.01)
	var eye := Vector3(0.0, eye_height, 0.0)
	var e := Vector3(_read(bytes, 1) * PI * 0.5, _read(bytes, 2) * PI, _read(bytes, 3) * PI * 0.5)
	var out := {"head": Transform3D(Basis.from_euler(e), eye + _read_vec(bytes, 4) * HEAD_RANGE * s)}
	for side: Array in [["left", 7], ["right", 14]]:
		var at: int = side[1]
		var q := Vector3(_read(bytes, at + 3), _read(bytes, at + 4), _read(bytes, at + 5))
		var w := sqrt(maxf(0.0, 1.0 - q.length_squared()))
		var rot := Quaternion(q.x, q.y, q.z, w).normalized()
		out[side[0]] = Transform3D(Basis(rot), eye + _read_vec(bytes, at) * HAND_RANGE * s)
		var gt := bytes[at + 6]
		out[str(side[0]) + "_grip"] = float(gt >> 4) / 15.0
		out[str(side[0]) + "_trigger"] = float(gt & 15) / 15.0
	return out


static func _put_hand(b: PackedByteArray, at: int, hand: Transform3D, eye: Vector3, s: float, grip: float,
		trigger: float) -> void:
	_put_vec(b, at, (hand.origin - eye) / s / HAND_RANGE)
	var q := Quaternion(hand.basis.orthonormalized()).normalized()
	if q.w < 0.0:
		q = -q
	_put(b, at + 3, q.x)
	_put(b, at + 4, q.y)
	_put(b, at + 5, q.z)
	b[at + 6] = (clampi(roundi(grip * 15.0), 0, 15) << 4) | clampi(roundi(trigger * 15.0), 0, 15)


static func _put_vec(b: PackedByteArray, at: int, v: Vector3) -> void:
	_put(b, at, v.x)
	_put(b, at + 1, v.y)
	_put(b, at + 2, v.z)


## -1..1 as a signed byte (clamped: never wrapped round).
static func _put(b: PackedByteArray, at: int, v: float) -> void:
	var i := clampi(roundi(v * 127.0), -127, 127) if is_finite(v) else 0
	b[at] = i & 0xFF


static func _read(b: PackedByteArray, at: int) -> float:
	var i := int(b[at])
	if i > 127:
		i -= 256
	return clampf(float(i) / 127.0, -1.0, 1.0)


static func _read_vec(b: PackedByteArray, at: int) -> Vector3:
	return Vector3(_read(b, at), _read(b, at + 1), _read(b, at + 2))
