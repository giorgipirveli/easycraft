class_name PhotoOrbit
extends RefCounted
## Photo mode's free camera around the player (M3 §14.14): orbit, zoom and pan, each with limits that
## grow with Size Magic. It walks the block grid from the player's head, so it never passes through a
## block (no peeking into closed rooms in Survivor) and never ends inside or right against one.

const PITCH_MIN := -1.45          # looking straight down from above
const PITCH_MAX := 1.3            # looking up from below (the ground usually stops it first)
const MIN_DISTANCE := 0.8
const MAX_DISTANCE := 12.0
const DEFAULT_DISTANCE := 3.5     # from first person: step back so the player is in the picture
const MAX_PAN := 6.0              # how far the look point may move from the player's head
const ORBIT_SENSITIVITY := 0.006  # radians per pixel, as CameraRig.TOUCH_SENSITIVITY
const PAN_SPEED := 0.002          # blocks per pixel, per block of distance (about a finger's worth)
const MARGIN := 0.3               # the camera stops this far before the first block on its way
const PROBE := 0.2                # and keeps this far from blocks beside it (the near plane)
const BACK_STEP := 0.1
const PROBES: Array[Vector3] = [Vector3(PROBE, 0, 0), Vector3(-PROBE, 0, 0), Vector3(0, PROBE, 0),
	Vector3(0, -PROBE, 0), Vector3(0, 0, PROBE), Vector3(0, 0, -PROBE), Vector3.ZERO]

var yaw := 0.0
var pitch := 0.0
var distance := DEFAULT_DISTANCE
var pan := Vector3.ZERO
var size_scale := 1.0


## Starts where the game camera is, so opening photo mode doesn't jump: its yaw and pitch (Node3D's
## YXZ order, as CameraRig sets them) and its distance from the head. From first person it steps back.
static func from_camera(cam: Transform3D, head: Vector3, size: float) -> PhotoOrbit:
	var o := PhotoOrbit.new()
	o.size_scale = size
	var e := cam.basis.orthonormalized().get_euler()
	o.pitch = clampf(e.x, PITCH_MIN, PITCH_MAX)
	o.yaw = e.y
	var d := cam.origin.distance_to(head)
	o.distance = clampf(d, o.min_distance(), o.max_distance()) if d >= o.min_distance() else DEFAULT_DISTANCE * _factor(size)
	return o


static func _factor(size: float) -> float:
	return clampf(size, 0.4, 3.0)


func min_distance() -> float:
	return MIN_DISTANCE * _factor(size_scale)


func max_distance() -> float:
	return MAX_DISTANCE * _factor(size_scale)


func max_pan() -> float:
	return MAX_PAN * _factor(size_scale)


## Turns around the look point, like CameraRig.look.
func orbit(delta_px: Vector2, sensitivity: float = ORBIT_SENSITIVITY) -> void:
	yaw = wrapf(yaw - delta_px.x * sensitivity, -PI, PI)
	pitch = clampf(pitch - delta_px.y * sensitivity, PITCH_MIN, PITCH_MAX)


## factor < 1 comes closer (fingers spread apart), > 1 moves away.
func zoom(factor: float) -> void:
	if not is_finite(factor) or factor <= 0.0:
		return
	distance = clampf(distance * factor, min_distance(), max_distance())


## Drags the picture with the fingers: the look point moves the other way, in the screen's plane.
func pan_by(delta_px: Vector2) -> void:
	var b := basis()
	pan += (-b.x * delta_px.x + b.y * delta_px.y) * PAN_SPEED * distance
	pan = pan.limit_length(max_pan())


func basis() -> Basis:
	return Basis.from_euler(Vector3(pitch, yaw, 0.0))


## The camera for a head position: the look point (head + pan), and the camera behind it, each
## stopped in front of the first block on its way.
func place(head: Vector3, is_solid: Callable) -> Transform3D:
	var focus := clear_point(head, head + pan, is_solid)
	var b := basis()
	return Transform3D(b, clear_point(focus, focus + b * Vector3(0, 0, distance), is_solid))


## The farthest point from `from` towards `to` that no block blocks: MARGIN before the first solid
## cell on the way (GridRay), then back until no block is within PROBE of it.
static func clear_point(from: Vector3, to: Vector3, is_solid: Callable) -> Vector3:
	var seg := to - from
	var length := seg.length()
	if length < 0.001:
		return from
	var dir := seg / length
	var reach := length
	var hit := GridRay.cast(from, dir, length + MARGIN, is_solid)
	if hit:
		reach = minf(reach, hit.distance - MARGIN)
	reach = maxf(reach, 0.0)
	while reach > 0.0 and near_block(from + dir * reach, is_solid):
		reach = maxf(reach - BACK_STEP, 0.0)
	return from + dir * reach


static func near_block(p: Vector3, is_solid: Callable) -> bool:
	for o in PROBES:
		if is_solid.call(Vector3i((p + o).floor())):
			return true
	return false
