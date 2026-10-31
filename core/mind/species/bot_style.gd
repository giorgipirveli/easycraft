class_name BotStyle
extends RefCounted
## What a bot friend has learned about its child (M2 Task 18, spec §12.17), next to its Mind: the
## child's favourite blocks (from the blocks the child places) and shapes (towers or walls), how
## much space the child likes (it keeps walking away → more), and the side monsters come from
## (a fighter guards it). Saved with the friend in WorldMeta.bots.

const MAX_FAVOURITES := 8
const MAX_SPACE := 6.0            # blocks added to the friend's comfortable distance, at most
const SPACE_UP := 1.0
const SPACE_DOWN := 0.5
const SIDES := 8                  # compass sectors around the child
const FADE := 0.97                # older placements count a little less with each new one
const NO_CELL := Vector3i(-2147483648, -2147483648, -2147483648)
## Blocks that make a design the child's own; lights and leaves are the design's (a lamp, a planter).
const KEEP: Array[int] = [BlockIds.LIGHT, BlockIds.LEAVES]
const NOT_BUILD_BLOCKS: Array[int] = [BlockIds.WATER, BlockIds.BED, BlockIds.LIGHT]

var favourites := {}              # block id -> weight
var tall := 0.0                   # placements on top of the one before
var wide := 0.0                   # placements beside the one before
var space := 0.0
var sides := PackedFloat32Array()


func _init() -> void:
	sides.resize(SIDES)


static func is_build_block(id: int) -> bool:
	return BlockIds.PLACEABLE.has(id) and not NOT_BUILD_BLOCKS.has(id)


## The child placed `id` at `cell`; `prev` is the child's block before it (NO_CELL: none).
func saw_block(id: int, cell: Vector3i, prev: Vector3i) -> void:
	if not is_build_block(id):
		return
	for k: int in favourites.keys():
		favourites[k] = float(favourites[k]) * FADE
	favourites[id] = float(favourites.get(id, 0.0)) + 1.0
	if favourites.size() > MAX_FAVOURITES:
		var weakest := -1
		for k: int in favourites:
			if k != id and (weakest < 0 or favourites[k] < favourites[weakest]):
				weakest = k
		favourites.erase(weakest)
	if prev == NO_CELL:
		return
	var d := cell - prev
	if d.x == 0 and d.z == 0 and absi(d.y) == 1:
		tall = tall * FADE + 1.0
		wide *= FADE
	elif d.y == 0 and absi(d.x) + absi(d.z) == 1:
		wide = wide * FADE + 1.0
		tall *= FADE


## The child's favourite build blocks, most used first (only ones used at least twice lately).
func favourite_blocks(n := 3) -> Array[int]:
	var ids: Array[int] = []
	for k: int in favourites:
		if float(favourites[k]) >= 1.5:
			ids.append(k)
	ids.sort_custom(func(a: int, b: int) -> bool: return favourites[a] > favourites[b])
	return ids.slice(0, n)


## (tall, wide): how much of the child's building goes up and how much goes sideways, 0..1.
func shape() -> Vector2:
	var total := tall + wide + 2.0
	return Vector2(tall / total, wide / total)


## `design` ([[offset, id], ...]) in the child's favourite blocks: each of the design's own blocks
## becomes the child's (the first kind the favourite, the next the second...); lights and leaves stay.
func style_design(design: Array) -> Array:
	var fav := favourite_blocks()
	if fav.is_empty():
		return design
	var ranks := {}
	var out: Array = []
	for cell: Array in design:
		var id: int = cell[1]
		if not KEEP.has(id):
			if not ranks.has(id):
				ranks[id] = ranks.size()
			id = fav[int(ranks[id]) % fav.size()]
		out.append([cell[0], id])
	return out


## The child walked away soon after the friend came close: more space next time.
func walked_away() -> void:
	space = minf(space + SPACE_UP, MAX_SPACE)


## The child came up close to the friend: a little less.
func came_close() -> void:
	space = maxf(space - SPACE_DOWN, 0.0)


## A monster showed up at `angle` (radians, atan2(dz, dx) from the child).
func note_danger(angle: float) -> void:
	if not is_finite(angle):
		return
	for i in SIDES:
		sides[i] *= 0.9
	sides[posmod(roundi(angle / TAU * SIDES), SIDES)] += 1.0


## The side monsters mostly come from (the middle of its sector), or NAN when there is none yet.
func guard_angle() -> float:
	var best := 0
	for i in SIDES:
		if sides[i] > sides[best]:
			best = i
	var second := 0.0
	for i in SIDES:
		if i != best:
			second = maxf(second, sides[i])
	if sides[best] < 1.5 or sides[best] < second * 1.5:
		return NAN
	return float(best) / SIDES * TAU


func to_save() -> Dictionary:
	var f := {}
	for k: int in favourites:
		f[str(k)] = snappedf(favourites[k], 0.01)
	return {"f": f, "t": snappedf(tall, 0.01), "w": snappedf(wide, 0.01), "sp": space,
		"si": Array(sides).map(func(v: float) -> float: return snappedf(v, 0.01))}


static func from_save(d: Variant) -> BotStyle:
	var s := BotStyle.new()
	if not d is Dictionary:
		return s
	var e: Dictionary = d
	if e.get("f") is Dictionary:
		for k: Variant in e.f:
			var key := str(k)
			var v: Variant = e.f[k]
			if key.is_valid_int() and is_build_block(key.to_int()) and _num(v) and s.favourites.size() < MAX_FAVOURITES:
				s.favourites[key.to_int()] = clampf(float(v), 0.0, 100.0)
	s.tall = clampf(float(e.t), 0.0, 100.0) if _num(e.get("t")) else 0.0
	s.wide = clampf(float(e.w), 0.0, 100.0) if _num(e.get("w")) else 0.0
	s.space = clampf(float(e.sp), 0.0, MAX_SPACE) if _num(e.get("sp")) else 0.0
	var si: Variant = e.get("si")
	if si is Array and (si as Array).size() == SIDES and (si as Array).all(_num):
		for i in SIDES:
			s.sides[i] = clampf(float(si[i]), 0.0, 100.0)
	return s


static func _num(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))
