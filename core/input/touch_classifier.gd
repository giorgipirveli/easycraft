class_name TouchClassifier
extends RefCounted
## Classifies one touch at a time on the look/build area: moving past the threshold is a DRAG
## (look), a quick release is a TAP (place), and staying still for HOLD_TIME is a HOLD (break).
## Touches with other indices (e.g. the joystick thumb) are ignored.

enum Gesture { NONE, TAP, HOLD, DRAG }

const DRAG_THRESHOLD_PX := 12.0
const HOLD_TIME := 0.25

var _index := -1
var _start_pos := Vector2.ZERO
var _start_time := 0.0
var _dragging := false
var _hold_fired := false


func down(index: int, pos: Vector2, time: float) -> void:
	if _index != -1:
		return
	_index = index
	_start_pos = pos
	_start_time = time
	_dragging = false
	_hold_fired = false


func move(index: int, pos: Vector2, _time: float) -> int:
	if index != _index:
		return Gesture.NONE
	if not _dragging and not _hold_fired and pos.distance_to(_start_pos) > DRAG_THRESHOLD_PX:
		_dragging = true
	return Gesture.DRAG if _dragging else Gesture.NONE


func update(time: float) -> int:
	if _index == -1 or _dragging or _hold_fired:
		return Gesture.NONE
	if time - _start_time >= HOLD_TIME:
		_hold_fired = true
		return Gesture.HOLD
	return Gesture.NONE


## How far a finger holding still is towards a HOLD (0..1), for the break ring (M2 Task 3); -1 when
## no finger is holding still (none, a drag, or the HOLD already fired).
func hold_progress(time: float) -> float:
	if _index == -1 or _dragging or _hold_fired:
		return -1.0
	return clampf((time - _start_time) / HOLD_TIME, 0.0, 1.0)


## canceled: the system took the touch away (a notification shade, a palm) — never a TAP.
func up(index: int, _pos: Vector2, time: float, canceled: bool = false) -> int:
	if index != _index:
		return Gesture.NONE
	var quick := time - _start_time < HOLD_TIME
	var result := Gesture.TAP if quick and not _dragging and not _hold_fired and not canceled else Gesture.NONE
	_index = -1
	return result


func owns(index: int) -> bool:
	return _index != -1 and index == _index


## Forgets the current touch without a gesture (the game paused under the finger).
func cancel() -> void:
	_index = -1
