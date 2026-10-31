class_name MotionBuffer
extends RefCounted
## Where to show a remote body between its syncs (M4 Wave 2 A2, spec §17.0). Players sync 20 times a
## second and creatures 10 (SyncPace), so remote bodies moved in steps. This keeps the last SIZE
## synced places (and turns) with the time each arrived, and shows the body where it was `delay`
## seconds ago, between the two syncs around that moment: movement is smooth as long as the next
## sync arrives within `delay`. It never guesses ahead (a late sync holds the body at the newest
## place), jumps on a teleport (SNAP_DISTANCE), and after a rest (a creature that stands still sends
## nothing) it starts moving from where it rested. Fixed-size packed arrays: no allocation per frame.

const SIZE := 8
const SNAP_DISTANCE := 8.0
## A gap longer than this many intervals means the body rested (it sent nothing).
const REST_GAP := 2.5

## The place and turn (yaw) to show, after sample().
var position := Vector3.ZERO
var yaw := 0.0

var _interval: float
var _delay: float
var _times := PackedFloat64Array()
var _places := PackedVector3Array()
var _yaws := PackedFloat32Array()
var _count := 0
var _newest := -1   # ring index of the newest sync


## interval: seconds between the sender's syncs; delay: how far behind the newest the body is shown.
func _init(interval: float, delay: float) -> void:
	_interval = interval
	_delay = delay
	_times.resize(SIZE)
	_places.resize(SIZE)
	_yaws.resize(SIZE)


func is_empty() -> bool:
	return _count == 0


func count() -> int:
	return _count


func clear() -> void:
	_count = 0
	_newest = -1


## A sync arrived at time t (seconds, the receiver's clock).
func push(t: float, place: Vector3, turn: float) -> void:
	if not place.is_finite() or not is_finite(turn):
		return
	if _count > 0:
		var last_t := _times[_newest]
		var last_place := _places[_newest]
		if place.distance_to(last_place) > SNAP_DISTANCE:
			clear()
		else:
			t = maxf(t, last_t + 0.001)
			if t - last_t > _interval * REST_GAP:
				_add(t - _interval, last_place, _yaws[_newest])   # it rested there until just before
	_add(t, place, turn)


## Sets position and yaw to what to show at time `now`.
func sample(now: float) -> void:
	if _count == 0:
		return
	var at := now - _delay
	var newer := _newest
	if at >= _times[newer]:
		position = _places[newer]
		yaw = _yaws[newer]
		return
	for k in range(1, _count):
		var older := (_newest - k + SIZE) % SIZE
		if at >= _times[older]:
			var f := (at - _times[older]) / (_times[newer] - _times[older])
			position = _places[older].lerp(_places[newer], f)
			yaw = lerp_angle(_yaws[older], _yaws[newer], f)
			return
		newer = older
	position = _places[newer]   # older than the oldest: the oldest
	yaw = _yaws[newer]


func _add(t: float, place: Vector3, turn: float) -> void:
	_newest = (_newest + 1) % SIZE
	_times[_newest] = t
	_places[_newest] = place
	_yaws[_newest] = turn
	_count = mini(_count + 1, SIZE)
