class_name SecretRules
extends RefCounted
## Where Green Meadows hides its secrets (M2 Task 16, spec §12.16), as pure rules. Every 128 × 128 area
## holds a few (buried treasure, a hidden room, a puzzle temple, a sky island, a crystal geode), chosen from
## the world seed and the area alone, so the same world always has the same ones: never in water, never in
## the spawn clearing, never on top of each other.
##
## A secret is a Dictionary: id (also a valid node name), kind, area, anchor (where it counts as found and
## chimes), boxes ([lo, hi exclusive, block id], filled in order, later ones win), lo/hi (their bounds),
## and per kind: chest + chest_kind + yaw, note {cell, text, pictures, yaw}, fake_wall, plates + symbols +
## order + vault + locked (temples), inside [lo, hi) (standing there finds it), radius (geodes).
## Every box stays inside its own area, so a chunk only looks at the area it lies in, and chunks meet
## without seams. Read-only apart from a small cache behind a mutex: the generator's threads share one.

const AREA := 128
const MARGIN := 24                # anchors are drawn this far inside their area
const SPAWN_CLEARING := 24.0      # blocks around the world spawn that stay free of secrets
const GAP := 4                    # blocks between two secrets' ground
const CACHE_LIMIT := 256          # remembered areas
const NEAR_RINGS := 2             # how many areas around a point the treasure map searches

const TREASURE := &"treasure"
const ROOM := &"room"
const ISLAND := &"island"
const GOLDEN := &"golden"
const TEMPLE := &"temple"
const WANDERER := &"wanderer"
const STAR := &"star"
const GEODE := &"geode"
## Every kind of secret, in the Secret Book's order (spec §12.16's list).
const KINDS: Array[StringName] = [TREASURE, ROOM, ISLAND, GOLDEN, TEMPLE, WANDERER, STAR, GEODE]
## The kinds the terrain generator builds; the others happen while playing (SurpriseRules).
const PLACED: Array[StringName] = [TREASURE, ROOM, ISLAND, TEMPLE, GEODE]
## [kind, chance] per attempt, in a fixed order. Each attempt draws its random numbers up front, so the
## sequence never depends on the terrain checks.
const ATTEMPTS := [[TREASURE, 0.8], [TREASURE, 0.5], [ROOM, 0.5], [TEMPLE, 0.35], [ISLAND, 0.25], [GEODE, 0.6]]
const DIRS: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0), Vector3i(0, 0, -1)]
## The "X" over a buried treasure: its middle and two cells along each diagonal.
const X_CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(-1, -1), Vector2i(-2, -2),
	Vector2i(1, -1), Vector2i(2, -2), Vector2i(-1, 1), Vector2i(-2, 2)]
const ROOM_DEPTH := 9             # a hidden room's floor lies this far under the ground
const ROOM_STEPS := 24            # the stairs up must reach the ground within this many steps
const ISLAND_MIN_TOP := 72
const ISLAND_MAX_TOP := 160
const GEODE_TOP := -28            # geode centres are at or below this

var seed: int
var shape: MeadowsShape
var spawn: Vector2i               # the world spawn column (MeadowsShape.spawn_column)
## The treasure pack's places (owner feedback #42), built after these kinds; null without the pack.
var more: TreasurePlaces
## M3 Task 21c: the Tiny world's mouse villages (tiny_in_area; never in secrets_in_area, so no secret and no place
## moves for them); null without them.
var tiny: MouseVillages

var _cache := {}
var _mutex := Mutex.new()


func _init(world_seed: int, terrain: MeadowsShape = null, treasure_pack: bool = true, tiny_world: bool = true) -> void:
	seed = world_seed
	shape = terrain if terrain != null else MeadowsShape.new(world_seed)
	spawn = shape.spawn_column()
	if treasure_pack:
		more = TreasurePlaces.new(shape, spawn)
	if tiny_world and MouseVillages.fits_terrain(shape):
		tiny = MouseVillages.new(self)   # M3 Task 21c


## A kind of secret the Secret Book knows: the M2 kinds and the treasure pack's (owner feedback #42).
static func is_kind(kind: StringName) -> bool:
	return KINDS.has(kind) or TreasurePlaces.is_kind(kind) or kind == MouseVillages.KIND   # M3 Task 21c


static func area_of(x: int, z: int) -> Vector2i:
	return Vector2i(floori(x / float(AREA)), floori(z / float(AREA)))


## The secrets of one area (shared: never change the returned dictionaries).
func secrets_in_area(area: Vector2i) -> Array:
	_mutex.lock()
	var cached: Variant = _cache.get(area)
	_mutex.unlock()
	if cached != null:
		return cached
	var list := _place(area)
	_mutex.lock()
	if _cache.size() >= CACHE_LIMIT:
		_cache.clear()
	_cache[area] = list
	_mutex.unlock()
	return list


## The secret with this id, or {}.
func find(id: String) -> Dictionary:
	var parts := id.split("_")
	if parts.size() != 4 or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return {}
	if MouseVillages.is_id(id):   # M3 Task 21c
		for s: Dictionary in tiny_in_area(Vector2i(int(parts[1]), int(parts[2]))):
			if s.id == id:
				return s
		return {}
	for s: Dictionary in secrets_in_area(Vector2i(int(parts[1]), int(parts[2]))):
		if s.id == id:
			return s
	return {}


## Secrets whose anchor is within `radius` blocks of `pos` (sideways).
func secrets_near(pos: Vector3, radius: float) -> Array:
	var out: Array = []
	var a0 := area_of(floori(pos.x - radius), floori(pos.z - radius))
	var a1 := area_of(floori(pos.x + radius), floori(pos.z + radius))
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			for s: Dictionary in secrets_in_area(Vector2i(ax, az)):
				var at: Vector3i = s.anchor
				if Vector2(at.x + 0.5 - pos.x, at.z + 0.5 - pos.z).length() <= radius:
					out.append(s)
	return out


## The block the secrets put at p, or -1 where they put nothing (the generator's reference).
func block_at(p: Vector3i) -> int:
	for s: Dictionary in secrets_in_area(area_of(p.x, p.z)):
		if not _contains(s.lo, s.hi, p):
			continue
		var boxes: Array = s.boxes
		for i in range(boxes.size() - 1, -1, -1):
			if _contains(boxes[i][0], boxes[i][1], p):
				return boxes[i][2]
	return tiny.block_at(p) if tiny != null else -1   # M3 Task 21c: the mouse villages


## The nearest buried treasure (sideways) to `from` whose id is not in `opened`, within NEAR_RINGS areas
## around it, or {}. The treasure map's arrow, and a hook for a pet dog that digs towards treasure; `kinds`:
## the kinds of chests looked for (owner 42: pets sniff out every unlocked kind, TreasureRules.SNIFF_KINDS).
func nearest_buried(from: Vector3, opened: Dictionary = {}, rings: int = NEAR_RINGS,
		kinds: Array[StringName] = [TREASURE]) -> Dictionary:
	var a := area_of(floori(from.x), floori(from.z))
	var best := {}
	var best_d := INF
	for az in range(a.y - rings, a.y + rings + 1):
		for ax in range(a.x - rings, a.x + rings + 1):
			for s: Dictionary in secrets_in_area(Vector2i(ax, az)):
				if not kinds.has(s.kind) or not s.has("chest") or opened.has(s.id):
					continue
				var c: Vector3i = s.chest
				var d := Vector2(c.x + 0.5 - from.x, c.z + 0.5 - from.z).length_squared()
				if d < best_d:
					best_d = d
					best = s
	return best


## A block a knock opens: the stone fake wall, the desert's fake sandstone (M3 Task 2), Frostpeak's fake
## packed snow (M3 Task 3), the Candy Kingdom's fake chocolate (M3 Task 4) or the Dragon Realm's fake
## floatstone (owner 39).
static func is_fake_wall(id: int) -> bool:
	return id == BlockIds.FAKE_WALL or id == BlockIds.FAKE_SANDSTONE or id == BlockIds.FAKE_SNOW \
		or id == BlockIds.FAKE_CHOCOLATE or id == BlockIds.FAKE_FLOATSTONE or id == BlockIds.FAKE_MOON_ROCK \
		or id == BlockIds.FAKE_BOING_ROCK or id == BlockIds.FAKE_RAINBOW \
		or id == BlockIds.FAKE_BASALT or id == BlockIds.FAKE_DEEP_ICE \
		or id == BlockIds.FAKE_IO_ROCK or id == BlockIds.FAKE_ICY_ROCK \
		or id == BlockIds.FAKE_MERCURY_ROCK or id == BlockIds.FAKE_LIMESTONE \
		or id == BlockIds.FAKE_MARBLE or id == BlockIds.FAKE_BABYLON_BRICK \
		or id == BlockIds.FAKE_WALL_BRICK or id == BlockIds.FAKE_TRAVERTINE or id == BlockIds.FAKE_MAYA_STONE \
		or id == BlockIds.FAKE_INCA_STONE or id == BlockIds.FAKE_WHITE_BRICK or id == BlockIds.FAKE_FLOAT_HULL \
		or id == BlockIds.FAKE_RING_ICE or id == BlockIds.FAKE_WATER_ICE or id == BlockIds.FAKE_PINK_ICE \
		or id == BlockIds.FAKE_GROOVED_ICE or id == BlockIds.FAKE_CAVE_STONE
	# owner #55: space; cosmos; #78: the wonders (the ancient seven's, then the New Seven's); cosmos: Venus, Saturn's rings,
	# Pluto, Triton, Ganymede


## The fake wall blocks joined to `start` (six sides), at most max_cells: they open together with one
## knock. Empty when `start` is not a fake wall. block_at(pos) -> block id.
static func fake_wall_group(start: Vector3i, block_at: Callable, max_cells: int = 16) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var id: int = block_at.call(start)
	if not is_fake_wall(id):
		return out
	var seen := {start: true}
	var queue: Array[Vector3i] = [start]
	while not queue.is_empty() and out.size() < max_cells:
		var p: Vector3i = queue.pop_front()
		out.append(p)
		for d: Vector3i in [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]:
			var n := p + d
			if not seen.has(n) and block_at.call(n) == id:
				seen[n] = true
				queue.append(n)
	return out


# --- M3 Task 21c: the Tiny world ---------------------------------------------------------------

## The mouse villages of one area ([] without them): apart from the secrets, so none of those moves.
func tiny_in_area(area: Vector2i) -> Array:
	return tiny.villages_in_area(area) if tiny != null else []


## Mouse villages whose anchor is within `radius` blocks of `pos` (sideways).
func tiny_near(pos: Vector3, radius: float) -> Array:
	var out: Array = []
	if tiny == null:
		return out
	var a0 := area_of(floori(pos.x - radius), floori(pos.z - radius))
	var a1 := area_of(floori(pos.x + radius), floori(pos.z + radius))
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			for s: Dictionary in tiny.villages_in_area(Vector2i(ax, az)):
				var at: Vector3i = s.anchor
				if Vector2(at.x + 0.5 - pos.x, at.z + 0.5 - pos.z).length() <= radius:
					out.append(s)
	return out


# --- Placement --------------------------------------------------------------------------------

func _place(area: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(area.x, area.y)
	var out: Array = []
	var base := area * AREA
	var attempts := _attempts()
	if more != null:
		attempts = attempts + more.attempts()   # owner 42: after these, so the M2 secrets never move
	for i in attempts.size():
		var kind: StringName = attempts[i][0]
		var roll := rng.randf()
		var x := base.x + rng.randi_range(MARGIN, AREA - MARGIN - 1)
		var z := base.y + rng.randi_range(MARGIN, AREA - MARGIN - 1)
		var v := int(rng.randi() & 0x7fffffff)
		if roll >= float(attempts[i][1]):
			continue
		var s := _build(kind, x, z, v)
		if s.is_empty():
			continue
		_finish(s, kind, area, i)
		if _fits(s, area, out):
			out.append(s)
	return out


## [kind, chance] per attempt (another universe's rules have their own, M3 Task 2).
func _attempts() -> Array:
	return ATTEMPTS


func _build(kind: StringName, x: int, z: int, v: int) -> Dictionary:
	match kind:
		TREASURE:
			return _treasure(x, z, v)
		ROOM:
			return _room(x, z, v)
		TEMPLE:
			return _temple(x, z, v)
		ISLAND:
			return _island(x, z, v)
		GEODE:
			return _geode(x, z, v)
	return more.build(kind, x, z, v) if more != null else {}


func _finish(s: Dictionary, kind: StringName, area: Vector2i, attempt: int) -> void:
	s.id = "%s_%d_%d_%d" % [kind, area.x, area.y, attempt]
	s.kind = kind
	s.area = area
	var lo := Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
	var hi := -lo
	for b: Array in s.boxes:
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	s.lo = lo
	s.hi = hi


## Inside its own area, clear of the spawn, and GAP blocks from every other secret's ground.
func _fits(s: Dictionary, area: Vector2i, others: Array) -> bool:
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	var a0 := area * AREA
	if lo.x < a0.x or lo.z < a0.y or hi.x > a0.x + AREA or hi.z > a0.y + AREA:
		return false
	var dx := maxi(maxi(lo.x - spawn.x, spawn.x - (hi.x - 1)), 0)
	var dz := maxi(maxi(lo.z - spawn.y, spawn.y - (hi.z - 1)), 0)
	if Vector2(dx, dz).length() < SPAWN_CLEARING:
		return false
	for o: Dictionary in others:
		var olo: Vector3i = o.lo
		var ohi: Vector3i = o.hi
		if lo.x - GAP < ohi.x and olo.x < hi.x + GAP and lo.z - GAP < ohi.z and olo.z < hi.z + GAP:
			return false
	return true


func _dry(x: int, z: int, h: int) -> bool:
	return h > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z)


## Buried treasure: an X of pebbles (sand) on the grass, and room for a chest 2 to 4 blocks under it.
func _treasure(x: int, z: int, v: int) -> Dictionary:
	var h := shape.height_at(x, z)
	if not _dry(x, z, h) or shape.tree_at(x, z):
		return {}
	var boxes: Array = []
	for c in X_CELLS:
		var hc := shape.height_at(x + c.x, z + c.y)
		if hc <= MeadowsShape.SEA_LEVEL + 1:
			return {}
		var cell := Vector3i(x + c.x, hc - 1, z + c.y)
		_box(boxes, cell, cell, BlockIds.SAND)
	var chest := Vector3i(x, h - 3 - v % 3, z)
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"anchor": chest, "chest": chest, "chest_kind": &"buried", "yaw": _yaw(DIRS[(v >> 2) % 4]), "boxes": boxes}


## A hidden room: a stone room with a wooden floor, a lamp in every corner and a chest, ROOM_DEPTH under the
## ground. Stone stairs lead down to it from the grass and end at a fake wall (two blocks, a door's size).
func _room(x: int, z: int, v: int) -> Dictionary:
	var h := shape.height_at(x, z)
	if not _dry(x, z, h):
		return {}
	var f := h - ROOM_DEPTH
	for c: Vector2i in [Vector2i(-3, -3), Vector2i(3, -3), Vector2i(-3, 3), Vector2i(3, 3)]:
		if shape.height_at(x + c.x, z + c.y) < f + 7:
			return {}            # the room would poke out of the ground
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, c + Vector3i(-3, 0, -3), c + Vector3i(3, 4, 3), BlockIds.STONE)
	_box(boxes, c + Vector3i(-2, 0, -2), c + Vector3i(2, 0, 2), BlockIds.PLANKS)
	_box(boxes, c + Vector3i(-2, 1, -2), c + Vector3i(2, 3, 2), BlockIds.AIR)
	for lamp: Vector3i in [Vector3i(-2, 4, -2), Vector3i(2, 4, -2), Vector3i(-2, 4, 2), Vector3i(2, 4, 2)]:
		_box(boxes, c + lamp, c + lamp, BlockIds.LIGHT)
	var fake: Array[Vector3i] = [c + dir * 3 + Vector3i(0, 1, 0), c + dir * 3 + Vector3i(0, 2, 0)]
	_box(boxes, fake[0], fake[1], BlockIds.FAKE_WALL)
	var top := Vector3i.ZERO
	var k := 1
	while true:
		var col := c + dir * (3 + k)
		var fy := f if k <= 2 else f + k - 2
		var hc := shape.height_at(col.x, col.z)
		if fy >= hc:
			break                # out in the open: the stairs are done
		if k > ROOM_STEPS or hc <= MeadowsShape.SEA_LEVEL + 1 or shape.is_river(col.x, col.z):
			return {}            # a hill in the way, or the stairs would open into water
		_box(boxes, Vector3i(col.x, fy, col.z) - side, Vector3i(col.x, mini(fy + 4, hc - 1), col.z) + side, BlockIds.STONE)
		_box(boxes, Vector3i(col.x, fy + 1, col.z), Vector3i(col.x, fy + 3, col.z), BlockIds.AIR)
		top = Vector3i(col.x, fy, col.z)
		k += 1
	var s := {"anchor": c + Vector3i(0, 1, 0), "chest": c + Vector3i(0, 1, 0) - dir * 2, "chest_kind": &"room",
		"yaw": _yaw(dir), "boxes": boxes, "fake_wall": fake, "stairs_top": top, "dir": dir,
		"inside": [c + Vector3i(-2, 1, -2), c + Vector3i(3, 4, 3)]}
	if (v >> 2) % 2 == 0:
		var note := Riddles.room_note(v >> 3)
		s.note = {"cell": c + Vector3i(0, 1, 0) - dir * 2 + side * 2, "text": note.text, "pictures": note.pictures,
			"yaw": _yaw(dir)}
	return s


## A puzzle temple: an 11 × 11 stone hall on a foundation, with a brick floor, three pressure plates painted
## with a sun, a moon and a star, a note showing the order to step on them, and a vault behind a golden door.
func _temple(x: int, z: int, v: int) -> Dictionary:
	var h := shape.height_at(x, z)
	var lo := h
	var hi := h
	for dz in [-5, 0, 5]:
		for dx in [-5, 0, 5]:
			var hc := shape.height_at(x + dx, z + dz)
			if not _dry(x + dx, z + dz, hc):
				return {}
			lo = mini(lo, hc)
			hi = maxi(hi, hc)
	if hi - lo > 5:
		return {}                # too steep
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var f := h - 1
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, Vector3i(x - 5, lo - 3, z - 5), Vector3i(x + 5, f + 5, z + 5), BlockIds.STONE)   # foundation, walls, roof
	_box(boxes, Vector3i(x - 5, f + 6, z - 5), Vector3i(x + 5, f + 9, z + 5), BlockIds.AIR)      # nothing on the roof
	_box(boxes, Vector3i(x - 4, f + 6, z - 4), Vector3i(x + 4, f + 6, z + 4), BlockIds.STONE)    # a stepped roof ...
	_box(boxes, Vector3i(x - 2, f + 7, z - 2), Vector3i(x + 2, f + 7, z + 2), BlockIds.STONE)
	_box(boxes, Vector3i(x, f + 8, z), Vector3i(x, f + 8, z), BlockIds.GOLD)                     # ... with a golden top
	_box(boxes, Vector3i(x - 4, f, z - 4), Vector3i(x + 4, f, z + 4), BlockIds.BRICK)
	_box(boxes, Vector3i(x - 4, f + 1, z - 4), Vector3i(x + 4, f + 4, z + 4), BlockIds.AIR)
	_box(boxes, _at(c, dir, side, -2, -4, 1), _at(c, dir, side, -2, 4, 4), BlockIds.BRICK)      # the vault's wall
	var vault: Array[Vector3i] = [_at(c, dir, side, -2, 0, 1), _at(c, dir, side, -2, 0, 2)]
	_box(boxes, vault[0], vault[1], BlockIds.YELLOW)   # a bright "golden" door (gold ore would be worth mining)
	_box(boxes, _at(c, dir, side, 5, -1, 1), _at(c, dir, side, 7, 1, 4), BlockIds.AIR)          # door and way in
	for lamp: Vector3i in [_at(c, dir, side, 4, -4, 5), _at(c, dir, side, 4, 4, 5), _at(c, dir, side, -1, -4, 5),
			_at(c, dir, side, -1, 4, 5), _at(c, dir, side, -3, 0, 5), _at(c, dir, side, 5, -2, 3), _at(c, dir, side, 5, 2, 3)]:
		_box(boxes, lamp, lamp, BlockIds.LIGHT)
	var plates: Array[Vector3i] = []
	for s: int in [-2, 0, 2]:
		var p := _at(c, dir, side, 1, s, 1)
		_box(boxes, p, p, BlockIds.PRESSURE_PLATE)
		plates.append(p)
	var symbols := _permutation(Riddles.TEMPLE_SYMBOLS, v >> 2)
	var order := _permutation([0, 1, 2], v >> 5)
	var pictures: Array[int] = [symbols[order[0]], symbols[order[1]], symbols[order[2]]]
	return {"anchor": c + Vector3i(0, 1, 0), "chest": _at(c, dir, side, -3, 0, 1), "chest_kind": &"temple",
		"locked": true, "yaw": _yaw(dir), "boxes": boxes, "plates": plates, "symbols": symbols, "order": order,
		"vault": vault, "dir": dir,
		"note": {"cell": _at(c, dir, side, 3, -3, 1), "text": Riddles.TEMPLE_TEXT, "pictures": pictures, "yaw": _yaw(dir)},
		"inside": [Vector3i(x - 4, f + 1, z - 4), Vector3i(x + 5, f + 5, z + 5)]}


## A sky island: a round floating island (grass, dirt, a stone cone with gold) with a golden chest on top.
func _island(x: int, z: int, v: int) -> Dictionary:
	var r := 4 + v % 3
	var ground := shape.height_at(x, z)
	for c: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		ground = maxi(ground, shape.height_at(x + c.x, z + c.y))
	var top := maxi(ground + 24, ISLAND_MIN_TOP) + (v >> 2) % 8
	if top > ISLAND_MAX_TOP:
		return {}
	var boxes: Array = []
	for k in r + 2:
		var id := BlockIds.GRASS if k == 0 else (BlockIds.DIRT if k <= 2 else BlockIds.STONE)
		_disc(boxes, Vector3i(x, top - k, z), r if k <= 1 else r - (k - 1), id)
	var gz := z + (v >> 5) % 3 - 1
	_box(boxes, Vector3i(x - 1, top - 3, gz), Vector3i(x - 1, top - 3, gz), BlockIds.GOLD)
	_box(boxes, Vector3i(x + 1, top - 4, gz), Vector3i(x + 1, top - 4, gz), BlockIds.GOLD)
	var chest := Vector3i(x, top + 1, z)
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(DIRS[(v >> 8) % 4]), "boxes": boxes,
		"inside": [Vector3i(x - r, top + 1, z - r), Vector3i(x + r + 1, top + 5, z + r + 1)]}


## A crystal geode: a hollow ball of glowing crystal with a few diamonds in its shell, deep underground.
func _geode(x: int, z: int, v: int) -> Dictionary:
	var r := 4 + v % 2
	var c := Vector3i(x, GEODE_TOP - (v >> 1) % 8, z)
	var boxes: Array = []
	_ball(boxes, c, r, BlockIds.CRYSTAL)
	_ball(boxes, c, r - 1, BlockIds.AIR)
	var axes: Array[Vector3i] = [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r),
		Vector3i(0, -r, 0), Vector3i(0, r, 0)]
	for i in 3:
		var stud := c + axes[(v >> (4 + i * 3)) % axes.size()]
		_box(boxes, stud, stud, BlockIds.DIAMOND)
	return {"anchor": c, "radius": r, "boxes": boxes,
		"inside": [c - Vector3i(r - 2, r - 2, r - 2), c + Vector3i(r - 1, r - 1, r - 1)]}


# --- Helpers ----------------------------------------------------------------------------------

## A box between two corner cells (inclusive, any order).
static func _box(boxes: Array, a: Vector3i, b: Vector3i, id: int) -> void:
	boxes.append([a.min(b), a.max(b) + Vector3i.ONE, id])


## A flat round disc of radius r (rows of boxes).
static func _disc(boxes: Array, center: Vector3i, r: int, id: int) -> void:
	for dz in range(-r, r + 1):
		var hw := int(sqrt((r + 0.5) * (r + 0.5) - dz * dz))
		_box(boxes, center + Vector3i(-hw, 0, dz), center + Vector3i(hw, 0, dz), id)


## A ball of radius r (rows of boxes).
static func _ball(boxes: Array, center: Vector3i, r: int, id: int) -> void:
	for dy in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var rest := (r + 0.5) * (r + 0.5) - dy * dy - dz * dz
			if rest < 0.0:
				continue
			var hw := int(sqrt(rest))
			_box(boxes, center + Vector3i(-hw, dy, dz), center + Vector3i(hw, dy, dz), id)


## The cell `along` blocks in `dir`, `across` blocks to the side and `up` blocks above c.
static func _at(c: Vector3i, dir: Vector3i, side: Vector3i, along: int, across: int, up: int) -> Vector3i:
	return c + dir * along + side * across + Vector3i(0, up, 0)


## Yaw that turns a model facing -Z towards `dir`.
static func _yaw(dir: Vector3i) -> float:
	return atan2(-float(dir.x), -float(dir.z))


## The n-th ordering of `items` (n wraps).
static func _permutation(items: Array, n: int) -> Array[int]:
	var pool := items.duplicate()
	var out: Array[int] = []
	var k := n
	for i in range(pool.size(), 0, -1):
		out.append(pool.pop_at(k % i))
		k /= i
	return out


static func _contains(lo: Vector3i, hi: Vector3i, p: Vector3i) -> bool:
	return p.x >= lo.x and p.y >= lo.y and p.z >= lo.z and p.x < hi.x and p.y < hi.y and p.z < hi.z


func _mix(x: int, z: int) -> int:
	var h := x * 668265263 ^ z * 374761393 ^ seed * 2246822519 ^ 0x27d4eb2f
	h = (h ^ (h >> 15)) * 2654435761
	return (h ^ (h >> 13)) & 0x7fffffffffffffff
