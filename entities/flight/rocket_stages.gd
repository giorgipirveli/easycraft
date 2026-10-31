class_name RocketStages
extends RefCounted
## The rocket a mission hands the flight (owner #79, spec §25.3, §21d.4), as pure rules. The missions' RocketCheck gives
## {"destination": int (a world), "cells": {Vector3i (relative to the pad's corner, y up): block id}, "stages":
## [[Vector3i, …] (bottom stage first), …], "seats": int}; normalize() makes a clean copy the flight can always draw:
## bad keys and air go, a stage cell with no block goes, a block in no stage joins the stage nearest to it, empty stages
## go, the stages are ordered by their lowest block (bottom first), no stages at all is one stage of everything, a rocket
## too big is cut from the top (MAX_CELLS), at least one seat, the Moon when no one says where.
## Where the child sits (seat), where each stage's engines fire (nozzles), what flies on after a stage falls away
## (flying_after) and what lands (lander: the top stage) are read from the blocks alone: the flight never needs to know
## which block is which part (the missions' parts, page 32, may not exist yet: RocketMesh draws unknown ids too).

const MAX_CELLS := 4096
## The missions' rocket parts (block page 32, ids 560-575): the developer's test rockets can use them as plain numbers.
const PART_IDS_FIRST := 560


## A clean copy of `rocket` (see the class notes): {"destination", "cells", "stages" (Array of Array[Vector3i], bottom
## first), "seats"}.
static func normalize(rocket: Dictionary) -> Dictionary:
	var cells := {}
	var given: Variant = rocket.get("cells", {})
	if given is Dictionary:
		for k: Variant in given:
			var id: Variant = given[k]
			if k is Vector3i and (id is int or id is float) and int(id) > 0:
				cells[k] = int(id)
	if cells.size() > MAX_CELLS:
		cells = _cut(cells)
	var stages: Array = []
	var owned := {}
	var list: Variant = rocket.get("stages", [])
	if list is Array:
		for s: Variant in list:
			if not s is Array:
				continue
			var stage: Array[Vector3i] = []
			for c: Variant in s:
				if c is Vector3i and cells.has(c) and not owned.has(c):
					stage.append(c)
					owned[c] = true
			if not stage.is_empty():
				stages.append(stage)
	if stages.is_empty() and not cells.is_empty():
		var all: Array[Vector3i] = []
		all.assign(cells.keys())
		stages.append(all)
	else:
		for c: Vector3i in cells:
			if not owned.has(c):
				(stages[_nearest(stages, c)] as Array).append(c)
	stages.sort_custom(func(a: Array, b: Array) -> bool: return _low(a) < _low(b))
	for s: Array in stages:
		s.sort()
	var dest: Variant = rocket.get("destination", SpaceRules.MOON)
	return {"destination": int(dest) if (dest is int or dest is float) and int(dest) > 0 else SpaceRules.MOON,
		"cells": cells, "stages": stages, "seats": maxi(int(rocket.get("seats", 1)), 1)}


static func is_empty(r: Dictionary) -> bool:
	return (r.get("cells", {}) as Dictionary).is_empty()


static func stage_count(r: Dictionary) -> int:
	return (r.get("stages", []) as Array).size()


## Stage i's blocks {cell: id} (0 the bottom stage).
static func stage_cells(r: Dictionary, i: int) -> Dictionary:
	var out := {}
	var stages: Array = r.get("stages", [])
	if i < 0 or i >= stages.size():
		return out
	for c: Vector3i in stages[i]:
		out[c] = r.cells[c]
	return out


## What still flies once the stages under `first` have fallen away: stages first … top.
static func flying_after(r: Dictionary, first: int) -> Dictionary:
	var out := {}
	for i in range(maxi(first, 0), stage_count(r)):
		out.merge(stage_cells(r, i))
	return out


## What lands (and stands by the landing pad afterwards): the top stage.
static func lander(r: Dictionary) -> Dictionary:
	return stage_cells(r, stage_count(r) - 1)


## The box the blocks fill, in block units (a cell c fills c … c + 1). AABB() for none.
static func bounds(cells: Dictionary) -> AABB:
	if cells.is_empty():
		return AABB()
	var lo := Vector3i(1 << 30, 1 << 30, 1 << 30)
	var hi := -lo
	for c: Vector3i in cells:
		lo = lo.min(c)
		hi = hi.max(c)
	return AABB(Vector3(lo), Vector3(hi - lo + Vector3i.ONE))


## The rocket's axis at its bottom: the middle of its footprint, at its lowest block's floor.
static func pivot(cells: Dictionary) -> Vector3:
	var b := bounds(cells)
	return Vector3(b.get_center().x, b.position.y, b.get_center().z)


## Where the child sits (a point in cell space): on the rocket's axis, in the top stage's layer under its nose (its top
## layer when it is one block tall), in the middle of that layer's block.
static func seat(r: Dictionary) -> Vector3:
	var top := lander(r)
	if top.is_empty():
		return Vector3.ZERO
	var b := bounds(top)
	var axis := pivot(r.cells)
	var layer := b.end.y - (2.0 if b.size.y >= 2.0 else 1.0)
	return Vector3(axis.x, layer + 0.5, axis.z)


## Stage i's lowest layer: its engines fire from there.
static func nozzles(r: Dictionary, i: int) -> Array[Vector3i]:
	var cells := stage_cells(r, i)
	var out: Array[Vector3i] = []
	if cells.is_empty():
		return out
	var low := int(bounds(cells).position.y)
	for c: Vector3i in cells:
		if c.y == low:
			out.append(c)
	return out


## The developer's test rocket (the developer menu, --fly-moon) to `destination`: `stages` stages of blocks every world
## has (a booster, a middle stage, the lander with its capsule, legs and nose), 5 x 5 with its fins, from the pad's
## corner. `part_ids`: the same shape in the missions' part ids (560-575) as plain numbers, which no page may draw yet.
static func test_rocket(destination: int, stages: int = 2, part_ids: bool = false) -> Dictionary:
	var ids := {
		&"engine": BlockIds.LANDER_LEG, &"tank": BlockIds.ROVER_PANEL, &"stripe": BlockIds.RED,
		&"separator": BlockIds.LANDER_FOIL, &"fin": BlockIds.BLUE, &"service": BlockIds.HEAT_TILE,
		&"capsule": BlockIds.PORTHOLE, &"panel": BlockIds.BASE_PANEL, &"nose": BlockIds.RED, &"leg": BlockIds.LANDER_LEG,
	}
	if part_ids:
		var n := 0
		for k: StringName in ids:
			ids[k] = PART_IDS_FIRST + n
			n += 1
	var cells := {}
	var list: Array = []
	var y := 0
	var count := clampi(stages, 1, 3)
	for s in count:
		var stage: Array[Vector3i] = []
		var top := s == count - 1
		_layer(cells, stage, y, ids.engine, false)
		if s == 0:   # fins round the booster's foot
			for f: Vector3i in [Vector3i(0, 0, 2), Vector3i(4, 0, 2), Vector3i(2, 0, 0), Vector3i(2, 0, 4)]:
				for dy in 2:
					_put(cells, stage, f + Vector3i(0, y + dy, 0), ids.fin)
		if top:   # the lander's legs, out at its corners
			for l: Vector3i in [Vector3i(0, 0, 0), Vector3i(4, 0, 0), Vector3i(0, 0, 4), Vector3i(4, 0, 4)]:
				_put(cells, stage, l + Vector3i(0, y, 0), ids.leg)
		y += 1
		var tanks := (2 if count > 1 else 4) if top else 3
		for t in tanks:
			_layer(cells, stage, y, ids.stripe if (not top and t == 1) else (ids.service if top else ids.tank), false)
			y += 1
		if top:
			_layer(cells, stage, y, ids.panel, false)
			for c: Vector3i in [Vector3i(2, y, 1), Vector3i(1, y, 2), Vector3i(3, y, 2), Vector3i(2, y, 3), Vector3i(2, y, 2)]:
				cells[c] = ids.capsule   # the windows
			y += 1
			_layer(cells, stage, y, ids.nose, true)
			y += 1
		else:
			_layer(cells, stage, y, ids.separator, false)
			y += 1
		list.append(stage)
	return normalize({"destination": destination, "cells": cells, "stages": list, "seats": 1})


## The lander a landing on its own flies (owner #87: the Star Map's LAND, RocketFlight.land): one stage, 3 x 3 on legs, a
## service module, the capsule with its windows and a nose, from the pad's corner.
static func default_lander(destination: int) -> Dictionary:
	var cells := {}
	var stage: Array[Vector3i] = []
	for l: Vector3i in [Vector3i(0, 0, 0), Vector3i(4, 0, 0), Vector3i(0, 0, 4), Vector3i(4, 0, 4)]:
		_put(cells, stage, l, BlockIds.LANDER_LEG)
	_layer(cells, stage, 0, BlockIds.LANDER_LEG, false)
	_layer(cells, stage, 1, BlockIds.HEAT_TILE, false)
	_layer(cells, stage, 2, BlockIds.BASE_PANEL, false)
	for c: Vector3i in [Vector3i(2, 2, 1), Vector3i(1, 2, 2), Vector3i(3, 2, 2), Vector3i(2, 2, 3), Vector3i(2, 2, 2)]:
		cells[c] = BlockIds.PORTHOLE
	_layer(cells, stage, 3, BlockIds.RED, true)
	return normalize({"destination": destination, "cells": cells, "stages": [stage], "seats": 1})


## A 3 x 3 layer on the axis (x, z 1 … 3) at height y; `plus`: only its middle and four sides (a nose).
static func _layer(cells: Dictionary, stage: Array[Vector3i], y: int, id: int, plus: bool) -> void:
	for x in range(1, 4):
		for z in range(1, 4):
			if plus and x != 2 and z != 2:
				continue
			_put(cells, stage, Vector3i(x, y, z), id)


static func _put(cells: Dictionary, stage: Array[Vector3i], c: Vector3i, id: int) -> void:
	if not cells.has(c):
		stage.append(c)
	cells[c] = id


static func _low(stage: Array) -> int:
	var low := 1 << 30
	for c: Vector3i in stage:
		low = mini(low, c.y)
	return low


static func _nearest(stages: Array, c: Vector3i) -> int:
	var best := 0
	var best_d := 1 << 30
	for i in stages.size():
		for s: Vector3i in stages[i]:
			var d := absi(s.y - c.y) * 4 + absi(s.x - c.x) + absi(s.z - c.z)
			if d < best_d:
				best_d = d
				best = i
	return best


## The lowest MAX_CELLS blocks (a rocket is cut from its top).
static func _cut(cells: Dictionary) -> Dictionary:
	var keys := cells.keys()
	keys.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.y < b.y or (a.y == b.y and a < b))
	var out := {}
	for i in MAX_CELLS:
		out[keys[i]] = cells[keys[i]]
	return out
