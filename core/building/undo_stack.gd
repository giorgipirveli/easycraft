class_name UndoStack
extends RefCounted
## Bounded LIFO of block edits; the oldest entry is dropped when full. A batch (mirror pair,
## stamp) is one entry {batch: [{pos, old_id, new_id}, ...]} and undoes in one step (M3 Task 8: a building
## tool's step also says {via: &"tool"}).

var _capacity: int
var _entries: Array[Dictionary] = []


func _init(capacity: int = 20) -> void:
	_capacity = capacity


func push(pos: Vector3i, old_id: int, new_id: int) -> void:
	_entries.append({"pos": pos, "old_id": old_id, "new_id": new_id})
	if _entries.size() > _capacity:
		_entries.pop_front()


## `via` (M3 Task 8): &"tool" for a step of the building tools, undone through Session.request_build_tool.
func push_batch(changes: Array, via: StringName = &"") -> void:
	if changes.is_empty():
		return
	_entries.append({"batch": changes, "via": via} if via != &"" else {"batch": changes})
	if _entries.size() > _capacity:
		_entries.pop_front()


## Returns {} when empty, else {pos, old_id, new_id} or {batch: [...]}.
func pop() -> Dictionary:
	if _entries.is_empty():
		return {}
	return _entries.pop_back()


func size() -> int:
	return _entries.size()


func clear() -> void:
	_entries.clear()
