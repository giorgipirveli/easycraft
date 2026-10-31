class_name BlockHit
extends RefCounted
## A targeted block: the block cell hit and the empty cell just before it (where a new block goes).

var position: Vector3i
var previous_position: Vector3i
var distance: float


func _init(hit: Vector3i, before: Vector3i, dist: float) -> void:
	position = hit
	previous_position = before
	distance = dist
