class_name WaterFlow
extends Node
## Host-side flowing water. Listens to WorldService.block_changed and runs WaterFlowRules a few
## cells per tick (it looks like water pouring and keeps remeshing cheap). Clients see the result
## through the terrain sync. Unloaded terrain counts as closed; each flood stops at MAX_FLOOD.

const TICK := 0.15
const CELLS_PER_TICK := 12

var world: WorldService

var _queue: Array[Vector4i] = []
var _flood_left := WaterFlowRules.MAX_FLOOD
var _t := 0.0
var _filling := false


func _ready() -> void:
	world.block_changed.connect(_on_block_changed)


func is_flowing() -> bool:
	return not _queue.is_empty()


func _on_block_changed(pos: Vector3i, old_id: int, new_id: int) -> void:
	if _filling or not multiplayer.is_server():
		return
	if _queue.is_empty():
		_flood_left = WaterFlowRules.MAX_FLOOD
	_queue.append_array(WaterFlowRules.sources_for_change(pos, old_id, new_id, _block_at))


func _physics_process(delta: float) -> void:
	if _queue.is_empty():
		return
	_t += delta
	if _t < TICK:
		return
	_t = 0.0
	var r := WaterFlowRules.step(_queue, _block_at, CELLS_PER_TICK, _flood_left)
	_queue = r.queue
	_filling = true   # our own fills must not start new floods
	for c: Vector4i in r.fill:
		world.set_block(Vector3i(c.x, c.y, c.z), BlockIds.WATER)
	_filling = false
	_flood_left -= (r.fill as Array).size()
	if _flood_left <= 0:
		_queue.clear()


func _block_at(p: Vector3i) -> int:
	return world.get_block(p) if world.is_editable(p) else -1
