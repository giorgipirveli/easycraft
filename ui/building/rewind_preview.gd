class_name RewindPreview
extends Node3D
## Build Rewind's stage (M3 Task 8): the cells of a RewindLog as they were after any number of its edits, one
## MultiMeshInstance3D per block id (that block's cube from WearMesh, in its own shared block material), so an edit
## moves one instance (a swap with the last one: O(1)) and nothing is ever remeshed. It lives in RewindView's own
## world: the game's world is never touched. Cells sit at their offset from the recording's spot.
## Chosen over a second small VoxelTerrain by cost (docs/devlog/parts/m3-task-8.md): no streaming, no voxel
## threads, one draw call per block id in the build, and every step of the replay is a few transform writes.

var record: RewindLog
## How many edits are shown.
var shown := 0

var _multis := {}   # id -> MultiMesh
var _slots := {}    # id -> Array of cells, by instance index
var _index := {}    # cell -> instance index
var _where := {}    # cell -> id
var _bounds := AABB()
var _start := {}    # the recording's cells before its first edit (blocks_after(0), read once)


## Builds the stage for a recording (at its start: before any edit).
func setup(r: RewindLog) -> void:
	for c in get_children():
		remove_child(c)
		c.free()
	record = r
	_multis.clear()
	_slots.clear()
	var need := {}   # id -> the most instances it can ever show: at the start, plus every edit making one
	var first := true
	var start := r.blocks_after(0)
	_start = start
	for pos: Vector3i in start:
		need[start[pos]] = int(need.get(start[pos], 0)) + 1
	for i in r.size():
		var e := r.edit(i)
		if e.new != BlockIds.AIR:
			need[e.new] = int(need.get(e.new, 0)) + 1
		var cell := Vector3(e.pos - r.center)
		_bounds = AABB(cell, Vector3.ONE) if first else _bounds.merge(AABB(cell, Vector3.ONE))
		first = false
	for id: int in need:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = WearMesh.cube(id)
		mm.instance_count = need[id]
		mm.visible_instance_count = 0
		var mi := MultiMeshInstance3D.new()
		mi.name = "Block_%d" % id
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_multis[id] = mm
		_slots[id] = []
	_reset()


## Shows the cells after the first `n` edits (forwards edit by edit; backwards from the start again).
func seek(n: int) -> void:
	if record == null:
		return
	n = clampi(n, 0, record.size())
	if n < shown:
		_reset()
	while shown < n:
		_apply(record.edit(shown))
		shown += 1


## {cell (from the recording's spot): id} of what shows now.
func visible_cells() -> Dictionary:
	return _where.duplicate()


## The block ids on the stage.
func ids() -> Array:
	return _multis.keys()


## The box every recorded cell fits in (the camera looks at its middle).
func bounds() -> AABB:
	return _bounds


func _reset() -> void:
	for id: int in _multis:
		(_multis[id] as MultiMesh).visible_instance_count = 0
		(_slots[id] as Array).clear()
	_index.clear()
	_where.clear()
	shown = 0
	for pos: Vector3i in _start:
		_add(pos - record.center, _start[pos])


func _apply(e: Dictionary) -> void:
	var cell: Vector3i = e.pos - record.center
	_remove(cell)
	if e.new != BlockIds.AIR:
		_add(cell, e.new)


func _add(cell: Vector3i, id: int) -> void:
	if not _multis.has(id):
		return
	var mm: MultiMesh = _multis[id]
	var i := mm.visible_instance_count
	if i >= mm.instance_count:
		return
	mm.set_instance_transform(i, Transform3D(Basis(), Vector3(cell)))
	mm.visible_instance_count = i + 1
	(_slots[id] as Array).append(cell)
	_index[cell] = i
	_where[cell] = id


func _remove(cell: Vector3i) -> void:
	if not _where.has(cell):
		return
	var id: int = _where[cell]
	var mm: MultiMesh = _multis[id]
	var slots: Array = _slots[id]
	var i: int = _index[cell]
	var last := mm.visible_instance_count - 1
	if i != last:
		var moved: Vector3i = slots[last]
		mm.set_instance_transform(i, mm.get_instance_transform(last))
		slots[i] = moved
		_index[moved] = i
	slots.pop_back()
	mm.visible_instance_count = last
	_index.erase(cell)
	_where.erase(cell)
