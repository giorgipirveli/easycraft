class_name ShotPool
extends Node3D
## A fixed pool of flying shots (M3 Task 14b): the blasters' darts, snowballs, paint blobs, bubbles and
## rockets, and the goblin archers' arrows. SIZE mesh instances are made once; a shot only takes a free slot
## (the oldest when all are busy), so shooting never adds a node or a material. Every peer flies the same
## shots from the same start (WeaponRules.arrow_step, the arrow's flight), so nothing is sent while they fly.
## A shot stops at the first solid block (never through a wall): a dart or an arrow sticks there for a
## moment, anything else bursts at once (`landed`). Only the host checks what else a shot meets
## (hit_check), then ends it here and on every guest (end).

## A shot ended on this game by itself: it hit a block (blocked) or flew its whole life; vel: its last
## velocity (where it came from).
signal landed(id: int, look: StringName, pos: Vector3, blocked: bool, vel: Vector3)

const SIZE := 40
const STICK_TIME := 0.8           # a dart stuck in a block stays this long
const ARROW_STICK_TIME := 2.0

## is_solid(cell: Vector3i) -> bool, the world (read only).
var is_solid: Callable
## Host only: hit_check(id, from, to) -> bool; true when the shot hit something on the way (the checker
## ends it).
var hit_check: Callable

var _meshes: Array[MeshInstance3D] = []
var _ids := PackedInt32Array()     # 0: a free slot
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _grav := PackedFloat32Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _stuck := PackedFloat32Array() # < 0 flying; else seconds it has been stuck
var _born := PackedInt32Array()    # spawn order (the oldest makes room)
var _looks: Array[StringName] = []
var _by_id := {}                   # shot id -> slot
var _count := 0
var _newest := 0


func _ready() -> void:
	top_level = true
	for i in SIZE:
		var mi := MeshInstance3D.new()
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_meshes.append(mi)
	_ids.resize(SIZE)
	_pos.resize(SIZE)
	_vel.resize(SIZE)
	_grav.resize(SIZE)
	_age.resize(SIZE)
	_life.resize(SIZE)
	_stuck.resize(SIZE)
	_born.resize(SIZE)
	_looks.resize(SIZE)


func active() -> int:
	return _count


func newest_id() -> int:
	return _newest


func has_shot(id: int) -> bool:
	return _by_id.has(id)


func shot_position(id: int) -> Vector3:
	return _pos[_by_id[id]] if _by_id.has(id) else Vector3.INF


func shot_velocity(id: int) -> Vector3:
	return _vel[_by_id[id]] if _by_id.has(id) else Vector3.ZERO


func shot_look(id: int) -> StringName:
	return _looks[_by_id[id]] if _by_id.has(id) else &""


## A new shot `id` (never 0) with its look (BlasterModels), from `origin` at `velocity`, falling with
## `gravity`, gone after `life` seconds.
func spawn(id: int, look: StringName, origin: Vector3, velocity: Vector3, gravity: float, life: float) -> void:
	if id == 0 or _by_id.has(id) or not origin.is_finite() or not velocity.is_finite():
		return
	var slot := _ids.find(0)
	if slot < 0:
		slot = _oldest()
		_free(slot)
	_ids[slot] = id
	_pos[slot] = origin
	_vel[slot] = velocity
	_grav[slot] = gravity
	_age[slot] = 0.0
	_life[slot] = life
	_stuck[slot] = -1.0
	_born[slot] = _newest_order()
	_looks[slot] = look
	_by_id[id] = slot
	_count += 1
	_newest = id
	var mi := _meshes[slot]
	mi.mesh = BlasterModels.shot_mesh(look)
	mi.visible = true
	_place(slot)


## Ends a shot on this game (a hit the host decided); returns where it was.
func end(id: int) -> Vector3:
	if not _by_id.has(id):
		return Vector3.INF
	var slot: int = _by_id[id]
	var at := _pos[slot]
	_free(slot)
	return at


func clear() -> void:
	for slot in SIZE:
		if _ids[slot] != 0:
			_free(slot)


## Every shot one step further: stuck ones wait, flying ones move (the host checks what they meet first).
func step(delta: float) -> void:
	if _count == 0:
		return
	var solid := is_solid if is_solid.is_valid() else func(_c: Vector3i) -> bool: return false
	for slot in SIZE:
		var id := _ids[slot]
		if id == 0:
			continue
		if _stuck[slot] >= 0.0:
			_stuck[slot] += delta
			if _stuck[slot] >= _stick_time(_looks[slot]):
				_free(slot)
			continue
		_age[slot] += delta
		var s := WeaponRules.arrow_step(_pos[slot], _vel[slot], delta, solid, _grav[slot])
		if hit_check.is_valid() and hit_check.call(id, _pos[slot], s.pos):
			continue                     # the host's checker ended it
		if _ids[slot] != id:
			continue
		_pos[slot] = s.pos
		_vel[slot] = s.vel
		if s.stuck:
			var look := _looks[slot]
			var at := _pos[slot]
			var v := _vel[slot]
			if _stick_time(look) > 0.0:
				_stuck[slot] = 0.0
				_place(slot)
			else:
				_free(slot)
			landed.emit(id, look, at, true, v)
		elif _age[slot] >= _life[slot]:
			var look := _looks[slot]
			var at := _pos[slot]
			var v := _vel[slot]
			_free(slot)
			landed.emit(id, look, at, false, v)
		else:
			_place(slot)


func _stick_time(look: StringName) -> float:
	match look:
		BlasterModels.DART:
			return STICK_TIME
		BlasterModels.GOBLIN_ARROW:
			return ARROW_STICK_TIME
	return 0.0


func _place(slot: int) -> void:
	var mi := _meshes[slot]
	var v := _vel[slot]
	var b := Basis.IDENTITY
	if v.length() > 0.001:
		var d := v.normalized()
		b = Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.99 else Vector3.RIGHT)
	mi.transform = Transform3D(b, _pos[slot])


func _free(slot: int) -> void:
	var id := _ids[slot]
	if id == 0:
		return
	_by_id.erase(id)
	_ids[slot] = 0
	_meshes[slot].visible = false
	_count -= 1


func _oldest() -> int:
	var best := 0
	for slot in SIZE:
		if _ids[slot] != 0 and _born[slot] < _born[best]:
			best = slot
	return best


var _order := 0


func _newest_order() -> int:
	_order += 1
	return _order
