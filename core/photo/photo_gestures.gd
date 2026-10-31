class_name PhotoGestures
extends RefCounted
## Photo mode's touch gestures (M3 §14.14): one finger turns the camera around the player; two fingers
## pinch to zoom and move together to pan. Fingers are tracked by touch index; a third is ignored.

const NONE := {"orbit": Vector2.ZERO, "zoom": 1.0, "pan": Vector2.ZERO}

var _points := {}   # touch index -> last position, in the order the fingers came down


func press(index: int, pos: Vector2) -> void:
	_points[index] = pos


func release(index: int) -> void:
	_points.erase(index)


func cancel() -> void:
	_points.clear()


func count() -> int:
	return _points.size()


func owns(index: int) -> bool:
	return _points.has(index)


## A finger moved. Returns {"orbit": Vector2 (pixels), "zoom": float (1 = none, < 1 = closer),
## "pan": Vector2 (pixels the middle of two fingers moved)}.
func move(index: int, pos: Vector2) -> Dictionary:
	if not _points.has(index):
		return NONE.duplicate()
	var keys := _points.keys()
	var before: Dictionary = _points.duplicate()
	_points[index] = pos
	if keys.size() == 1:
		return {"orbit": pos - (before[index] as Vector2), "zoom": 1.0, "pan": Vector2.ZERO}
	var a: int = keys[0]
	var b: int = keys[1]
	if index != a and index != b:
		return NONE.duplicate()
	var a0: Vector2 = before[a]
	var b0: Vector2 = before[b]
	var a1: Vector2 = _points[a]
	var b1: Vector2 = _points[b]
	var d0 := a0.distance_to(b0)
	var d1 := a1.distance_to(b1)
	var zoom := d0 / d1 if d0 > 1.0 and d1 > 1.0 else 1.0
	return {"orbit": Vector2.ZERO, "zoom": zoom, "pan": (a1 + b1) * 0.5 - (a0 + b0) * 0.5}
