class_name GlowWonders
extends RefCounted
## Universe 6, the Glow Caves: where the Cave Wonders stand and what the generator builds for them (owner #122; the
## plays are GlowWonderRules', run by GlowWondersDirector). One wonder in each SecretRules.AREA square that has room for
## it, its kind in turn: GlowWonderRules.KINDS[(ax + 2 az) mod 5] (the nine areas round any spot hold all five kinds:
## every kind is near the spawn, and they come back mixed further out). Each stands on open, dry, flat cavern floor
## under a ceiling high enough for it (never in a wall, a shaft or a lake), inside its area and off the spawn clearing;
## GlowSecretRules keeps every secret off it, and the generator grows no plant and hangs no stalactite on it. A wonder
## is a Dictionary: id ("wonder_<kind>_<ax>_<az>"), kind, area, anchor (the floor cell it is built round), dir, boxes
## ([lo, hi exclusive, block id], written in order like a secret's; none reaches into a ceiling), lo / hi (their
## bounds) and its kind's cells:
## - grotto: a dark round floor (no moss) under a plain rock ceiling (the director's worms light it), a listening stone
##   (FLOWSTONE) in the middle, a ring of stalagmites; `ceiling` (the lowest over it), `radius`;
## - drip: a stalactite (`tip`) over a flowstone stump the drops land on (`land`: the cell over the stump), a flowstone
##   pillar with cave pearls on it (`pearls`); `steps`: the cells each step will grow into (nothing built there now);
## - echo: a rounded mound of cave stone with three tunnels in its face (`mouths`, `lengths`: GlowWonderRules.echo_order),
##   its first steps glowing with moss and a selenite crystal to tap on the ground in front of it (`markers`), the long one
##   plugged (`plug`: two cave stone cells) before a pocket with a glow-worm ceiling and cave pearls (`pearls`); the bat
##   roost's stone in front (`roost`);
## - rain: a granite boulder with a two-block pale limestone door (`limestone`; `granite`: the door's neighbours), a pocket
##   behind with cave pearls (`pearls`), and a basin of rainwater in front (`basin`) under a stalactite;
## - lake: a round pool cut into the floor, two blocks of water over lake stone, a cave pearl on its bottom (`pearl`), a
##   lamp stone with a spore lamp (`lamp`: the lamp's cell) and a ripple stone at the water's edge (`ripple`).
## Read-only apart from a small cache behind a mutex (the generator's threads share it).

const W := preload("res://core/rules/glow_wonder_rules.gd")
const AREA := SecretRules.AREA
const MARGIN := 18
const TRIES := 24
const CACHE_LIMIT := 256
const FLAT := 1                   # the floor under a wonder may rise or fall this much
const FIT_STEP := 2
const GROTTO_R := 5
const GROTTO_CLEAR := 7           # a grotto's ceiling is at least this high over its floor
const LAKE_R := 3
const ECHO_SIDES: Array[int] = [-3, 0, 3]   # the three tunnels across the mound's face
const ECHO_LONG := 16             # the mound's length along its way
const NONE := 0x7fffffff

var seed: int
var shape: GlowShape
var spawn: Vector2i

var _cache := {}
var _mutex := Mutex.new()


func _init(world_seed: int, terrain: GlowShape = null) -> void:
	seed = world_seed
	shape = terrain if terrain != null else GlowShape.new(world_seed)
	spawn = shape.spawn_column()


static func kind_of_area(area: Vector2i) -> StringName:
	return W.KINDS[posmod(area.x + 2 * area.y, W.KINDS.size())]


## The wonder of one area ({} when none fits there); shared: never change the returned dictionary.
func wonder_in_area(area: Vector2i) -> Dictionary:
	_mutex.lock()
	var got: Variant = _cache.get(area)
	_mutex.unlock()
	if got != null:
		return got
	var w := _place(area)
	_mutex.lock()
	if _cache.size() >= CACHE_LIMIT:
		_cache.clear()
	_cache[area] = w
	_mutex.unlock()
	return w


## The wonder of `area` when it was worked out already ({} for none there), else null (nothing is placed).
func known(area: Vector2i) -> Variant:
	_mutex.lock()
	var got: Variant = _cache.get(area)
	_mutex.unlock()
	return got


## How many areas' wonders are worked out (and remembered) now.
func known_areas() -> int:
	_mutex.lock()
	var n := _cache.size()
	_mutex.unlock()
	return n


## Wonders whose anchor is within `radius` blocks of `pos` (sideways).
func wonders_near(pos: Vector3, radius: float) -> Array:
	var out: Array = []
	var a0 := SecretRules.area_of(floori(pos.x - radius), floori(pos.z - radius))
	var a1 := SecretRules.area_of(floori(pos.x + radius), floori(pos.z + radius))
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			var w := wonder_in_area(Vector2i(ax, az))
			if not w.is_empty():
				var at: Vector3i = w.anchor
				if Vector2(at.x + 0.5 - pos.x, at.z + 0.5 - pos.z).length() <= radius:
					out.append(w)
	return out


## The wonder with this id, or {}.
func find(id: String) -> Dictionary:
	var parts := id.split("_")
	if parts.size() != 4 or parts[0] != "wonder" or not parts[2].is_valid_int() or not parts[3].is_valid_int():
		return {}
	var w := wonder_in_area(Vector2i(int(parts[2]), int(parts[3])))
	return w if not w.is_empty() and w.id == id else {}


## The block a wonder puts at p, or -1 where none puts anything (the generator's reference).
func block_at(p: Vector3i) -> int:
	var w := wonder_in_area(SecretRules.area_of(p.x, p.z))
	if w.is_empty() or not SecretRules._contains(w.lo, w.hi, p):
		return -1
	var boxes: Array = w.boxes
	for i in range(boxes.size() - 1, -1, -1):
		if SecretRules._contains(boxes[i][0], boxes[i][1], p):
			return boxes[i][2]
	return -1


## Writes the wonders' boxes that reach into `buf` at `origin` (the generator, after the secrets).
func write(buf: VoxelBuffer, origin: Vector3i) -> void:
	var end := origin + buf.get_size()
	var a0 := SecretRules.area_of(origin.x, origin.z)
	var a1 := SecretRules.area_of(end.x - 1, end.z - 1)
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			var w := wonder_in_area(Vector2i(ax, az))
			if w.is_empty():
				continue
			var lo: Vector3i = w.lo
			var hi: Vector3i = w.hi
			if hi.x <= origin.x or hi.y <= origin.y or hi.z <= origin.z or lo.x >= end.x or lo.y >= end.y or lo.z >= end.z:
				continue
			for b: Array in w.boxes:
				var bl: Vector3i = (b[0] as Vector3i).max(origin) - origin
				var bh: Vector3i = (b[1] as Vector3i).min(end) - origin
				if bl.x < bh.x and bl.y < bh.y and bl.z < bh.z:
					buf.fill_area(b[2], bl, bh, VoxelBuffer.CHANNEL_TYPE)


## The sideways footprint (x, z, x end, z end) of the wonder of `area`, or an empty Rect2i.
func footprint(area: Vector2i) -> Rect2i:
	var w := wonder_in_area(area)
	if w.is_empty():
		return Rect2i()
	var lo: Vector3i = w.lo
	var hi: Vector3i = w.hi
	return Rect2i(lo.x, lo.z, hi.x - lo.x, hi.z - lo.z)


# --- Placement --------------------------------------------------------------------------------------------------

## Up to TRIES spots of the area (drawn from the seed), each in four ways for the kinds that have one; the first that
## fits (the columns it looks at are remembered for this call only: areas are placed on several threads at once).
func _place(area: Vector2i) -> Dictionary:
	var memo := {}
	var kind := kind_of_area(area)
	var base := area * AREA
	var turns := 1 if kind == W.GROTTO else 4
	for i in TRIES:
		var h := _mix(area.x * 31 + i, area.y * 17 - i * 7)
		var x := base.x + MARGIN + h % (AREA - 2 * MARGIN)
		var z := base.y + MARGIN + (h >> 8) % (AREA - 2 * MARGIN)
		if Vector2(x - spawn.x, z - spawn.y).length() < SecretRules.SPAWN_CLEARING:
			continue
		var c := _col(memo, x, z)
		if c.x == c.y or c.x <= GlowShape.LAKE_LEVEL + 1 or shape.in_shaft(x, z):
			continue
		var v := (h >> 16) & 0x7fff
		for turn in turns:
			var dir := SecretRules.DIRS[(v + turn) % 4]
			var w := _build(memo, kind, Vector3i(x, c.x, z), dir, v, c.y)
			if w.is_empty():
				continue
			_finish(w, kind, area)
			if _fits(memo, w, area):
				return w
	return {}


func _build(memo: Dictionary, kind: StringName, c: Vector3i, dir: Vector3i, v: int, ceil_y: int) -> Dictionary:
	match kind:
		W.GROTTO:
			return _grotto(memo, c, ceil_y)
		W.DRIP:
			return _drip(memo, c, dir, ceil_y)
		W.ECHO:
			return _echo(c, dir, v)
		W.RAIN:
			return _rain(memo, c, dir, ceil_y)
		W.LAKE:
			return _lake(c, dir)
	return {}


func _finish(w: Dictionary, kind: StringName, area: Vector2i) -> void:
	w.id = "wonder_%s_%d_%d" % [kind, area.x, area.y]
	w.kind = kind
	w.area = area
	var lo := Vector3i(NONE, NONE, NONE)
	var hi := -lo
	for b: Array in w.boxes:
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	w.lo = lo
	w.hi = hi


## Inside its area, off the spawn clearing, and every box over open, dry floor (outside the shafts, within FLAT of the
## wonder's floor) and under its columns' ceiling (looked at every FIT_STEP-th column and the far edges).
func _fits(memo: Dictionary, w: Dictionary, area: Vector2i) -> bool:
	var lo: Vector3i = w.lo
	var hi: Vector3i = w.hi
	var a0 := area * AREA
	if lo.x < a0.x or lo.z < a0.y or hi.x > a0.x + AREA or hi.z > a0.y + AREA:
		return false
	var dx := maxi(maxi(lo.x - spawn.x, spawn.x - (hi.x - 1)), 0)
	var dz := maxi(maxi(lo.z - spawn.y, spawn.y - (hi.z - 1)), 0)
	if Vector2(dx, dz).length() < SecretRules.SPAWN_CLEARING:
		return false
	var f: int = (w.anchor as Vector3i).y
	for b: Array in w.boxes:
		var blo: Vector3i = b[0]
		var bhi: Vector3i = b[1]
		for z in GlowSecretRules._steps(blo.z, bhi.z - 1):
			for x in GlowSecretRules._steps(blo.x, bhi.x - 1):
				var c := _col(memo, x, z)
				if c.x == c.y or c.x <= GlowShape.LAKE_LEVEL + 1 or absi(c.x - f) > FLAT or bhi.y > c.y:
					return false
				if c.w != 0:
					return false   # a shaft's column
	return true


## Column (x, z) as (floor, ceiling, roof, 1 in a shaft else 0), remembered while one area is placed.
func _col(memo: Dictionary, x: int, z: int) -> Vector4i:
	var key := Vector2i(x, z)
	var got: Variant = memo.get(key)
	if got != null:
		return got
	var c := shape.column(x, z)
	var out := Vector4i(c.x, c.y, c.z, 1 if shape.in_shaft(x, z) else 0)
	memo[key] = out
	return out


## The glow-worm grotto: a dark round floor (moss cleared, dips filled, bumps cut), the listening stone in its middle
## and a ring of stalagmites; only under a ceiling with no glow-worm patch of its own (the director's worms are the
## grotto's lights) and at least GROTTO_CLEAR high everywhere over it.
func _grotto(memo: Dictionary, c: Vector3i, ceil_y: int) -> Dictionary:
	var r := GROTTO_R
	if ceil_y - c.y < GROTTO_CLEAR:
		return {}
	var low := ceil_y
	for dz in range(-r, r + 1, FIT_STEP):
		for dx in range(-r, r + 1, FIT_STEP):
			if dx * dx + dz * dz > (r + 0.5) * (r + 0.5):
				continue
			var col := _col(memo, c.x + dx, c.z + dz)
			low = mini(low, col.y)
			if low - c.y < GROTTO_CLEAR or shape.worms_at(c.x + dx, c.z + dz):
				return {}
	var boxes: Array = []
	SecretRules._disc(boxes, Vector3i(c.x, c.y - 1, c.z), r, BlockIds.CAVE_STONE)
	SecretRules._disc(boxes, c, r, BlockIds.AIR)
	SecretRules._box(boxes, c, c, BlockIds.FLOWSTONE)
	for i in 8:
		var a := TAU * i / 8.0
		var p := c + Vector3i(roundi(cos(a) * r), 0, roundi(sin(a) * r))
		SecretRules._box(boxes, p, p, BlockIds.STALAGMITE)
	return {"anchor": c, "dir": Vector3i(1, 0, 0), "boxes": boxes, "radius": r, "ceiling": low}


## The drip stone: a stalactite hanging from the ceiling over a flowstone stump; a pillar with pearls on top STEPS + 1
## along its way; the steps between grow as drops are caught (the director). Only on a level line (every column of it
## at the stump's floor) under a ceiling between 7 and 16 high.
func _drip(memo: Dictionary, c: Vector3i, dir: Vector3i, ceil_y: int) -> Dictionary:
	var clear := ceil_y - c.y
	if clear < 7 or clear > 16:
		return {}
	var n := clampi(clear - 4, 3, W.STEPS)
	for k in range(-1, n + 2):
		var p := c + dir * k
		if _col(memo, p.x, p.z).x != c.y:
			return {}
	var boxes: Array = []
	SecretRules._box(boxes, c, c, BlockIds.FLOWSTONE)                                         # the stump
	SecretRules._box(boxes, Vector3i(c.x, ceil_y - 2, c.z), Vector3i(c.x, ceil_y - 1, c.z), BlockIds.FLOWSTONE)
	var tip := Vector3i(c.x, ceil_y - 3, c.z)
	SecretRules._box(boxes, tip, tip, BlockIds.STALACTITE)
	var pillar := c + dir * (n + 1)
	SecretRules._box(boxes, pillar, pillar + Vector3i(0, n, 0), BlockIds.FLOWSTONE)
	var pearls := pillar + Vector3i(0, n + 1, 0)
	SecretRules._box(boxes, pearls, pearls, BlockIds.CAVE_PEARL)
	var steps: Array = []
	for k in range(1, n + 1):
		var cells: Array[Vector3i] = []
		for y in k:
			cells.append(c + dir * k + Vector3i(0, y, 0))
		steps.append(cells)
	return {"anchor": c, "dir": dir, "boxes": boxes, "tip": tip, "land": c + Vector3i.UP, "steps": steps,
		"pearls": pearls}


## The echo fork: a rounded mound of cave stone, three tunnels in its face (their lengths in turn, their first steps
## mossy), a crystal to tap in front of each mouth, the long tunnel plugged before a pocket of pearls under glow-worms;
## the bat roost's stone in front.
func _echo(c: Vector3i, dir: Vector3i, v: int) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var lengths := W.echo_order(v)
	var long := W.longest(lengths)
	var boxes: Array = []
	SecretRules._box(boxes, SecretRules._at(c, dir, side, -4, -5, -1), SecretRules._at(c, dir, side, -1, 5, -1),
		BlockIds.CAVE_STONE)   # the ground in front, level
	SecretRules._box(boxes, SecretRules._at(c, dir, side, -4, -5, 0), SecretRules._at(c, dir, side, -1, 5, 2), BlockIds.AIR)
	_mound(boxes, c, dir, side, ECHO_LONG - 1, 5, -1, 4, BlockIds.CAVE_STONE)
	for across: int in ECHO_SIDES:   # each mouth's first steps glow: an entrance, never an eye
		SecretRules._box(boxes, SecretRules._at(c, dir, side, 0, across, -1), SecretRules._at(c, dir, side, 1, across, -1),
			BlockIds.GLOW_MOSS)
	var mouths: Array[Vector3i] = []
	var markers: Array[Vector3i] = []
	var plug: Array[Vector3i] = []
	var pearls := Vector3i.ZERO
	for i in 3:
		var across: int = ECHO_SIDES[i]
		var l := int(lengths[i])
		SecretRules._box(boxes, SecretRules._at(c, dir, side, 0, across, 0), SecretRules._at(c, dir, side, l - 1, across, 1),
			BlockIds.AIR)
		mouths.append(SecretRules._at(c, dir, side, 0, across, 0))
		var marker := SecretRules._at(c, dir, side, -1, across, 0)   # on the ground in front of its mouth
		SecretRules._box(boxes, marker, marker, BlockIds.SELENITE)
		markers.append(marker)
		if i == long:
			plug = [SecretRules._at(c, dir, side, l, across, 0), SecretRules._at(c, dir, side, l, across, 1)]
			SecretRules._box(boxes, SecretRules._at(c, dir, side, l + 1, across - 1, 0),
				SecretRules._at(c, dir, side, l + 3, across + 1, 2), BlockIds.AIR)
			SecretRules._box(boxes, SecretRules._at(c, dir, side, l + 1, across - 1, 3),
				SecretRules._at(c, dir, side, l + 3, across + 1, 3), BlockIds.GLOW_WORMS)
			pearls = SecretRules._at(c, dir, side, l + 2, across, 0)
			SecretRules._box(boxes, pearls, pearls, BlockIds.CAVE_PEARL)
	var roost := SecretRules._at(c, dir, side, -2, 0, 0)
	SecretRules._box(boxes, roost, roost, BlockIds.FLOWSTONE)
	return {"anchor": c, "dir": dir, "boxes": boxes, "lengths": lengths, "long": long, "mouths": mouths,
		"markers": markers, "plug": plug, "pearls": pearls, "roost": roost}


## The rain carver: a granite boulder with a two-block pale limestone door in its face and a pocket of pearls behind it; in
## front, a basin of rainwater under a stalactite (rain seeping through the rock drips into it).
func _rain(memo: Dictionary, c: Vector3i, dir: Vector3i, ceil_y: int) -> Dictionary:
	if ceil_y - c.y < 6:
		return {}
	var side := Vector3i(-dir.z, 0, dir.x)
	var boxes: Array = []
	SecretRules._box(boxes, SecretRules._at(c, dir, side, -5, -4, 0), SecretRules._at(c, dir, side, -1, 4, 2), BlockIds.AIR)
	_mound(boxes, c, dir, side, 4, 3, -1, 3, BlockIds.GRANITE)   # a granite boulder ...
	SecretRules._box(boxes, SecretRules._at(c, dir, side, 1, -1, 0), SecretRules._at(c, dir, side, 3, 1, 2), BlockIds.AIR)
	var door: Array[Vector3i] = [SecretRules._at(c, dir, side, 0, 0, 0), SecretRules._at(c, dir, side, 0, 0, 1)]
	SecretRules._box(boxes, door[0], door[1], BlockIds.LIMESTONE)   # ... with a pale limestone door
	var pearls := SecretRules._at(c, dir, side, 3, 0, 0)
	SecretRules._box(boxes, pearls, pearls, BlockIds.CAVE_PEARL)
	var granite: Array[Vector3i] = [SecretRules._at(c, dir, side, 0, -1, 0), SecretRules._at(c, dir, side, 0, 1, 0),
		SecretRules._at(c, dir, side, 0, -1, 1), SecretRules._at(c, dir, side, 0, 1, 1), SecretRules._at(c, dir, side, 0, 0, 2)]
	var basin := SecretRules._at(c, dir, side, -3, 0, 0)
	SecretRules._box(boxes, basin + Vector3i(-1, -1, -1), basin + Vector3i(1, 0, 1), BlockIds.LAKE_STONE)
	SecretRules._box(boxes, basin, basin, BlockIds.WATER)
	var drip_ceil := _col(memo, basin.x, basin.z).y
	if drip_ceil - basin.y >= 5:
		var hang := Vector3i(basin.x, drip_ceil - 1, basin.z)
		SecretRules._box(boxes, hang, hang, BlockIds.FLOWSTONE)
		SecretRules._box(boxes, hang + Vector3i.DOWN, hang + Vector3i.DOWN, BlockIds.STALACTITE)
	return {"anchor": c, "dir": dir, "boxes": boxes, "limestone": door, "granite": granite, "basin": basin,
		"pearls": pearls}


## The blind fish lake: a round pool cut into the floor (two blocks of water over lake stone, a flowstone rim), a cave
## pearl on its bottom, a lamp stone (a spore lamp on a flowstone block) and a ripple stone at the water's edge.
func _lake(c: Vector3i, dir: Vector3i) -> Dictionary:
	var r := LAKE_R
	var boxes: Array = []
	SecretRules._disc(boxes, c, r + 2, BlockIds.AIR)
	SecretRules._disc(boxes, Vector3i(c.x, c.y - 1, c.z), r + 1, BlockIds.FLOWSTONE)
	SecretRules._disc(boxes, Vector3i(c.x, c.y - 3, c.z), r, BlockIds.LAKE_STONE)
	SecretRules._disc(boxes, Vector3i(c.x, c.y - 2, c.z), r, BlockIds.WATER)
	SecretRules._disc(boxes, Vector3i(c.x, c.y - 1, c.z), r, BlockIds.WATER)
	var pearl := Vector3i(c.x, c.y - 3, c.z)
	SecretRules._box(boxes, pearl, pearl, BlockIds.CAVE_PEARL)
	var stone := c + dir * (r + 1)
	SecretRules._box(boxes, stone, stone, BlockIds.FLOWSTONE)
	var lamp := stone + Vector3i.UP
	SecretRules._box(boxes, lamp, lamp, BlockIds.SPORE_LAMP)
	var ripple := c - dir * (r + 1)
	SecretRules._box(boxes, ripple, ripple, BlockIds.FLOWSTONE)
	return {"anchor": c, "dir": dir, "boxes": boxes, "pearl": pearl, "lamp": lamp, "ripple": ripple, "surface": c.y - 1}


## A mound of `id` from along 0 to `length` (its face at 0), `half` blocks to each side, from `y0` to `y1` over c's floor:
## no box: every layer's corners are cut, and its top is a block smaller all round (its corners cut twice).
static func _mound(boxes: Array, c: Vector3i, dir: Vector3i, side: Vector3i, length: int, half: int, y0: int, y1: int,
		id: int) -> void:
	for y in range(y0, y1 + 1):
		var i := 1 if y == y1 else 0
		SecretRules._box(boxes, SecretRules._at(c, dir, side, i, -half + 1 + i, y),
			SecretRules._at(c, dir, side, length - i, half - 1 - i, y), id)
		SecretRules._box(boxes, SecretRules._at(c, dir, side, 1 + i, -half + i, y),
			SecretRules._at(c, dir, side, length - 1 - i, half - i, y), id)


func _mix(x: int, z: int) -> int:
	var h := x * 668265263 ^ z * 374761393 ^ seed * 2246822519 ^ 0x5bd1e995
	h = (h ^ (h >> 15)) * 2654435761
	return (h ^ (h >> 13)) & 0x7fffffffffffffff
