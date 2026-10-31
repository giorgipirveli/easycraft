class_name MeadowsPlaces
extends RefCounted
## Places to find in the wild meadows (owner feedback #45b, spec §14.18), as pure rules: windmills, villages (a
## plaza with a well, houses, paths, a wheat farm, villagers), lookout towers, lighthouses, ships at a pier, castle
## ruins and towns. At most one place in each REGION x REGION region, decided from the seed, the region and the
## terrain alone (MeadowsBiomeShape), so the same world always has the same places:
## - rarer farther away: each kind starts at a distance from the world spawn (RARITY), and the chance of a place
##   in a region grows with its distance, so going farther always finds something new;
## - never within CLEAR_OF_SPAWN of the world spawn (like the treasure pack: Tilly, the Totem, the hub circle, the
##   Theater, the quest givers and the ways between them), never on a secret's ground (the secrets never move for
##   a place: a place gives way), always inside its region;
## - never cutting into water or cliffs: the ground under a building rises and falls at most SLOPE blocks, is dry
##   and off the rivers; pads fill the dips and cut the bumps.
## A place is a Dictionary: id ("<kind>_<rx>_<rz>", a valid node name), kind, name, region, anchor (its centre at
## floor level: where it counts as found), radius (the find circle), boxes ([lo, hi exclusive, block id], filled
## in order, later ones win), lo/hi (their bounds), and per kind: doors ([the open cell at the feet, the cell in
## front]), stairs (the steps in order, a tower's and a lighthouse's), houses (a village's: [lo, hi, floor]),
## villagers ([position, yaw]), pier (a ship's), clearing (where no tree grows: in_clearing). The generator writes the
## boxes clipped per chunk (write); the
## host's PlacesDirector finds them near players. Read-only apart from a small cache behind a mutex (the
## generator threads share it); height lookups are memoised per build, never shared.

const REGION := 256
const CLEAR_OF_SPAWN := 60.0
const GAP := 4                    # blocks between a place and a secret
const SLOPE := 3                  # a building's ground rises and falls at most this much
const CLEAR := 12                 # air over a building's pad (trees and bumps go)
const PAD_DEPTH := 6              # dirt under a pad (it fills dips)
const TRIES := 8                  # spots tried per region, in a fixed order
const CACHE_LIMIT := 256
const SEA := MeadowsShape.SEA_LEVEL
const CLEARING := 4               # no tree stands this near a place (a crown reaches 3 blocks from its trunk)
## Where windmills are built: open land (not in a forest's shade, a swamp or on a mountain) ...
const OPEN_LAND: Array[int] = [MeadowsBiomeShape.MEADOW, MeadowsBiomeShape.FLOWERS, MeadowsBiomeShape.BIRCH,
	MeadowsBiomeShape.ISLAND]
## ... and villages and towns: open land, or a clearing in a dark forest (a place's ground is free of trees).
const VILLAGE_LAND: Array[int] = [MeadowsBiomeShape.MEADOW, MeadowsBiomeShape.FLOWERS, MeadowsBiomeShape.BIRCH,
	MeadowsBiomeShape.ISLAND, MeadowsBiomeShape.DARK]

const WINDMILL := &"windmill"
const VILLAGE := &"village"
const TOWER := &"tower"
const LIGHTHOUSE := &"lighthouse"
const SHIP := &"ship"
const CASTLE := &"castle"
const TOWN := &"town"
## Every kind, from the most common to the rarest. No name has an "_" (ids are "<kind>_<rx>_<rz>").
const KINDS: Array[StringName] = [WINDMILL, VILLAGE, TOWER, LIGHTHOUSE, SHIP, CASTLE, TOWN]
## Where each kind starts (blocks from the world spawn), its weight among the kinds possible there, how far inside
## its region its centre is drawn (it fits whole), and whether it needs the sea.
const RARITY := {
	WINDMILL: {"from": 60, "weight": 22, "margin": 12},
	VILLAGE: {"from": 150, "weight": 34, "margin": 30},
	TOWER: {"from": 250, "weight": 18, "margin": 10},
	LIGHTHOUSE: {"from": 250, "weight": 26, "margin": 22, "coast": true},
	SHIP: {"from": 400, "weight": 22, "margin": 24, "coast": true},
	CASTLE: {"from": 700, "weight": 14, "margin": 16},
	TOWN: {"from": 1200, "weight": 12, "margin": 44},
}
const CHANCE_NEAR := 0.4          # a region's chance of a place by the spawn ...
const CHANCE_FAR := 0.85          # ... and from FAR_AWAY on
const FAR_AWAY := 2500.0
const FIND_RADIUS := {WINDMILL: 14.0, VILLAGE: 28.0, TOWER: 12.0, LIGHTHOUSE: 14.0, SHIP: 16.0, CASTLE: 18.0, TOWN: 40.0}

const NAME_A: Array[String] = ["Maple", "Honey", "Willow", "Clover", "Sunny", "Apple", "Berry", "Pebble", "Daisy",
	"Acorn", "Mossy", "Rosy", "Misty", "Button", "Cherry", "Bramble", "Robin", "Thistle", "Puddle", "Hazel"]
const NAME_B: Array[String] = ["brook", "field", "wood", "dale", "vale", "hill", "meadow", "ford", "ridge", "haven",
	"burrow", "glen", "bottom", "stead"]
const SHIP_NAMES: Array[String] = ["the Sea Otter", "the Jolly Jay", "the Bluebell", "the Happy Haddock",
	"the Little Puffin", "the Star Seeker", "the Dizzy Dolphin", "the Sunny Sail"]
## Stair steps round a 3 x 3 inside (a tower's and a lighthouse's), from the door's left, climbing one a step.
const RING: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0)]

var seed: int
var shape: MeadowsBiomeShape
var secrets: SecretRules
var spawn: Vector2i

var _cache := {}
var _mutex := Mutex.new()


func _init(world_seed: int, terrain: MeadowsBiomeShape, secret_rules: SecretRules = null) -> void:
	seed = world_seed
	shape = terrain if terrain != null else MeadowsBiomeShape.new(world_seed)
	secrets = secret_rules if secret_rules != null else SecretRules.new(world_seed, shape)
	spawn = shape.spawn_column()


static func is_kind(kind: StringName) -> bool:
	return KINDS.has(kind)


## "<kind>_<rx>_<rz>" with a known kind.
static func is_place_id(id: String) -> bool:
	var parts := id.split("_")
	return parts.size() == 3 and is_kind(StringName(parts[0])) and parts[1].is_valid_int() and parts[2].is_valid_int() \
		and id.length() <= 40


static func region_of(x: int, z: int) -> Vector2i:
	return Vector2i(floori(x / float(REGION)), floori(z / float(REGION)))


## The places of one region (shared: never change the returned dictionaries).
func places_in_region(region: Vector2i) -> Array:
	_mutex.lock()
	var cached: Variant = _cache.get(region)
	_mutex.unlock()
	if cached != null:
		return cached
	var list := _place(region)
	_mutex.lock()
	if _cache.size() >= CACHE_LIMIT:
		_cache.clear()
	_cache[region] = list
	_mutex.unlock()
	return list


## The place with this id, or {}.
func find(id: String) -> Dictionary:
	if not is_place_id(id):
		return {}
	var parts := id.split("_")
	for p: Dictionary in places_in_region(Vector2i(int(parts[1]), int(parts[2]))):
		if p.id == id:
			return p
	return {}


## Places whose anchor is within `radius` blocks (sideways) of `pos`.
func places_near(pos: Vector3, radius: float) -> Array:
	var out: Array = []
	var r0 := region_of(floori(pos.x - radius), floori(pos.z - radius))
	var r1 := region_of(floori(pos.x + radius), floori(pos.z + radius))
	for rz in range(r0.y, r1.y + 1):
		for rx in range(r0.x, r1.x + 1):
			for p: Dictionary in places_in_region(Vector2i(rx, rz)):
				var a: Vector3i = p.anchor
				if Vector2(a.x + 0.5 - pos.x, a.z + 0.5 - pos.z).length() <= radius:
					out.append(p)
	return out


## The nearest place (of `kind`, or any) within `rings` regions around `from`, or {}.
func nearest(from: Vector3, kind: StringName = &"", rings: int = 3) -> Dictionary:
	var r := region_of(floori(from.x), floori(from.z))
	var best := {}
	var best_d := INF
	for rz in range(r.y - rings, r.y + rings + 1):
		for rx in range(r.x - rings, r.x + rings + 1):
			for p: Dictionary in places_in_region(Vector2i(rx, rz)):
				if kind != &"" and p.kind != kind:
					continue
				var a: Vector3i = p.anchor
				var d := Vector2(a.x + 0.5 - from.x, a.z + 0.5 - from.z).length_squared()
				if d < best_d:
					best_d = d
					best = p
	return best


## A village's (or a town's) centre: the middle of its plaza, by the well, at floor level (quest givers, §14.17).
static func village_centre(place: Dictionary) -> Vector3:
	var a: Vector3i = place.get("anchor", Vector3i.ZERO)
	return Vector3(a.x + 0.5, a.y, a.z + 0.5)


## The block a place puts at p, or -1 where no place puts anything (the generator's reference).
func block_at(p: Vector3i) -> int:
	for place: Dictionary in places_in_region(region_of(p.x, p.z)):
		if not _contains(place.lo, place.hi, p):
			continue
		var boxes: Array = place.boxes
		for i in range(boxes.size() - 1, -1, -1):
			if _contains(boxes[i][0], boxes[i][1], p):
				return boxes[i][2]
	return -1


## Writes the places' boxes that reach into this chunk (every place stays inside its region, and a region is a
## whole number of chunks: a chunk looks at one region).
func write(buf: VoxelBuffer, origin: Vector3i) -> void:
	var end := origin + buf.get_size()
	for place: Dictionary in places_in_region(region_of(origin.x, origin.z)):
		var lo: Vector3i = place.lo
		var hi: Vector3i = place.hi
		if hi.x <= origin.x or hi.y <= origin.y or hi.z <= origin.z or lo.x >= end.x or lo.y >= end.y or lo.z >= end.z:
			continue
		for b: Array in place.boxes:
			var bl: Vector3i = (b[0] as Vector3i).max(origin) - origin
			var bh: Vector3i = (b[1] as Vector3i).min(end) - origin
			if bl.x < bh.x and bl.y < bh.y and bl.z < bh.z:
				buf.fill_area(b[2], bl, bh, VoxelBuffer.CHANNEL_TYPE)


static func _contains(lo: Vector3i, hi: Vector3i, p: Vector3i) -> bool:
	return p.x >= lo.x and p.y >= lo.y and p.z >= lo.z and p.x < hi.x and p.y < hi.y and p.z < hi.z


# --- Rarity ---

## A region's chance of holding a place, by its centre's distance from the spawn.
static func chance_at(distance: float) -> float:
	return lerpf(CHANCE_NEAR, CHANCE_FAR, clampf(distance / FAR_AWAY, 0.0, 1.0))


## The kinds a place `distance` blocks from the spawn may be.
static func kinds_at(distance: float) -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in KINDS:
		if distance >= float(RARITY[k].from):
			out.append(k)
	return out


# --- Placement ---

func _place(region: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(region.x, region.y)
	var base := region * REGION
	var middle := Vector2(base.x + REGION * 0.5, base.y + REGION * 0.5)
	var dist := middle.distance_to(Vector2(spawn))
	var roll := rng.randf()
	var pick := rng.randf()
	var spots: Array = []
	for i in TRIES:
		spots.append([rng.randf(), rng.randf(), int(rng.randi() & 0x7fffffff)])
	var shuffle := int(rng.randi() & 0x7fffffff)
	if roll >= chance_at(dist):
		return []
	var kinds := kinds_at(dist)
	var memo := {}
	var coast: Array = []
	if kinds.any(func(k: StringName) -> bool: return RARITY[k].get("coast", false)):
		coast = _coast_spots(memo, base, shuffle)
		if coast.is_empty():   # an inland region: no lighthouse and no ship
			kinds = kinds.filter(func(k: StringName) -> bool: return not RARITY[k].get("coast", false))
	if kinds.is_empty():
		return []
	var kind := _weighted(kinds, pick)
	var land_kinds: Array[StringName] = kinds.filter(func(k: StringName) -> bool: return not RARITY[k].get("coast", false) and k != TOWN)
	var order: Array[StringName] = [kind]
	if not land_kinds.is_empty() and not land_kinds.has(kind):   # the coast (or a town) didn't fit: a land kind
		order.append(_weighted(land_kinds, pick))
	for k: StringName in order:
		var margin: int = RARITY[k].margin
		var tries: Array = []
		if RARITY[k].get("coast", false):
			for c: Array in coast:
				if c[0] == k:
					tries.append([c[1], c[2], int(c[3])])
		else:
			for sp: Array in spots:
				tries.append([base.x + margin + int(float(sp[0]) * (REGION - 2 * margin)),
					base.y + margin + int(float(sp[1]) * (REGION - 2 * margin)), int(sp[2])])
		var best := {}
		for t: Array in tries.slice(0, TRIES * 2):
			var place := _build(k, int(t[0]), int(t[1]), int(t[2]))
			if place.is_empty():
				continue
			_finish(place, k, region)
			if not _fits(place, region):
				continue
			if k == TOWER:   # a lookout wants the highest spot of the tries
				if best.is_empty() or (place.anchor as Vector3i).y > (best.anchor as Vector3i).y:
					best = place
				continue
			return [place]
		if not best.is_empty():
			return [best]
	return []


## The region's coast, sampled every COAST_STEP blocks: [kind, x, z, v] spots for a lighthouse (dry land next to
## water, moved towards it) and a ship (water at least 3 deep next to land, moved towards it), in a shuffled but
## fixed order. Empty for a region without a coast.
func _coast_spots(memo: Dictionary, base: Vector2i, shuffle: int) -> Array:
	var step := 16
	var lo := 24
	var n := (REGION - 2 * lo) / step + 1
	var heights := PackedInt32Array()
	heights.resize(n * n)
	for j in n:
		for i in n:
			heights[i + j * n] = _h(memo, base.x + lo + i * step, base.y + lo + j * step)
	var out: Array = []
	var v := shuffle
	for j in n:
		for i in n:
			var h := heights[i + j * n]
			for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var i2 := i + d.x
				var j2 := j + d.y
				if i2 < 0 or j2 < 0 or i2 >= n or j2 >= n:
					continue
				var h2 := heights[i2 + j2 * n]
				var a := Vector2i(base.x + lo + i * step, base.y + lo + j * step)
				v = (v * 1103515245 + 12345) & 0x7fffffff
				if h > SEA + 1 and h2 < SEA - 1:          # land here, water there: a lighthouse on the shore
					var toward := a + d * (step / 2)
					out.append([LIGHTHOUSE, toward.x, toward.y, v])
					out.append([LIGHTHOUSE, a.x, a.y, v >> 3])
				elif h <= SEA - 3 and h2 > SEA + 1:       # deep water here, land there: a ship by the shore
					var toward := a + d * (step / 3)
					out.append([SHIP, toward.x, toward.y, v])
					out.append([SHIP, a.x, a.y, v >> 3])
	# a fixed shuffle: sort by a hash of each spot
	out.sort_custom(func(p: Array, q: Array) -> bool: return (int(p[3]) & 0xffff) < (int(q[3]) & 0xffff))
	return out


static func _weighted(kinds: Array[StringName], pick: float) -> StringName:
	var total := 0
	for k: StringName in kinds:
		total += int(RARITY[k].weight)
	var at := pick * total
	for k: StringName in kinds:
		at -= int(RARITY[k].weight)
		if at < 0.0:
			return k
	return kinds[kinds.size() - 1]


func _build(kind: StringName, x: int, z: int, v: int) -> Dictionary:
	var memo := {}
	match kind:
		WINDMILL:
			return _windmill(memo, x, z, v)
		VILLAGE:
			return _village(memo, x, z, v, false)
		TOWN:
			return _village(memo, x, z, v, true)
		TOWER:
			return _tower(memo, x, z, v, false)
		LIGHTHOUSE:
			return _lighthouse(memo, x, z, v)
		SHIP:
			return _ship(memo, x, z, v)
		CASTLE:
			return _castle(memo, x, z, v)
	return {}


func _finish(p: Dictionary, kind: StringName, region: Vector2i) -> void:
	p.id = "%s_%d_%d" % [kind, region.x, region.y]
	p.kind = kind
	p.region = region
	p.radius = FIND_RADIUS[kind]
	var lo := Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
	var hi := -lo
	for b: Array in p.boxes:
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	p.lo = lo
	p.hi = hi
	p.clearing = Rect2i(lo.x - CLEARING, lo.z - CLEARING, hi.x - lo.x + 2 * CLEARING, hi.z - lo.z + 2 * CLEARING)


## True where a place keeps its ground free of trees (the generator skips a tree whose trunk is there).
func in_clearing(x: int, z: int) -> bool:
	var lx := posmod(x, REGION)
	var lz := posmod(z, REGION)
	if lx >= CLEARING and lz >= CLEARING and lx < REGION - CLEARING and lz < REGION - CLEARING:
		for p: Dictionary in places_in_region(region_of(x, z)):   # well inside a region: its own places only
			if (p.clearing as Rect2i).has_point(Vector2i(x, z)):
				return true
		return false
	var seen: Array[Vector2i] = []
	for d: Vector2i in [Vector2i.ZERO, Vector2i(-CLEARING, -CLEARING), Vector2i(CLEARING, -CLEARING),
			Vector2i(-CLEARING, CLEARING), Vector2i(CLEARING, CLEARING)]:
		var r := region_of(x + d.x, z + d.y)
		if seen.has(r):
			continue
		seen.append(r)
		for p: Dictionary in places_in_region(r):
			if (p.clearing as Rect2i).has_point(Vector2i(x, z)):
				return true
	return false


## Inside its region, clear of the spawn, and GAP blocks from every secret.
func _fits(p: Dictionary, region: Vector2i) -> bool:
	var lo: Vector3i = p.lo
	var hi: Vector3i = p.hi
	var r0 := region * REGION
	if lo.x < r0.x or lo.z < r0.y or hi.x > r0.x + REGION or hi.z > r0.y + REGION:
		return false
	var dx := maxi(maxi(lo.x - spawn.x, spawn.x - (hi.x - 1)), 0)
	var dz := maxi(maxi(lo.z - spawn.y, spawn.y - (hi.z - 1)), 0)
	if Vector2(dx, dz).length() < CLEAR_OF_SPAWN:
		return false
	var a := Vector2(p.anchor.x, p.anchor.z).distance_to(Vector2(spawn))
	if a < float(RARITY[p.kind].from):
		return false
	var a0 := SecretRules.area_of(lo.x - GAP, lo.z - GAP)
	var a1 := SecretRules.area_of(hi.x + GAP, hi.z + GAP)
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			for s: Dictionary in secrets.secrets_in_area(Vector2i(ax, az)):
				var slo: Vector3i = s.lo
				var shi: Vector3i = s.hi
				if lo.x - GAP < shi.x and slo.x < hi.x + GAP and lo.z - GAP < shi.z and slo.z < hi.z + GAP \
						and lo.y - GAP < shi.y and slo.y < hi.y + GAP:
					return false
	return true


func _name(v: int) -> String:
	return NAME_A[v % NAME_A.size()] + NAME_B[(v / NAME_A.size()) % NAME_B.size()]


# --- Terrain lookups (memoised per build) ---

func _col(memo: Dictionary, x: int, z: int) -> Vector3i:
	var k := Vector2i(x, z)
	var got: Variant = memo.get(k)
	if got != null:
		return got
	var c := shape.column(x, z)
	memo[k] = c
	return c


func _h(memo: Dictionary, x: int, z: int) -> int:
	return _col(memo, x, z).x


## Dry, off the rivers, not a swamp pool or the sea.
func _dry(memo: Dictionary, x: int, z: int) -> bool:
	var c := _col(memo, x, z)
	return c.x > SEA + 1 and c.z & MeadowsBiomeShape.F_RIVER == 0 and c.y != MeadowsBiomeShape.SEA


## The floor for a building over the world rect [x0, x1) x [z0, z1) (sampled every 2 blocks and at its edges):
## the rounded middle of its ground, or -1 when any of it is wet or it rises and falls more than SLOPE.
func _floor(memo: Dictionary, x0: int, z0: int, x1: int, z1: int, slope: int = SLOPE) -> int:
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	var xs: Array[int] = []
	var zs: Array[int] = []
	for x in range(x0, x1, 2):
		xs.append(x)
	xs.append(x1 - 1)
	for z in range(z0, z1, 2):
		zs.append(z)
	zs.append(z1 - 1)
	for z in zs:
		for x in xs:
			if not _dry(memo, x, z):
				return -1
			var h := _h(memo, x, z)
			lo = mini(lo, h)
			hi = maxi(hi, h)
	if hi - lo > slope:
		return -1
	return (lo + hi + 1) / 2


# --- Building helpers ---

## Boxes in a building's own frame: local (0, 0, 0) is `at` (floor level), local +z its front; facing turns it a
## quarter at a time.
class Sketch:
	var at: Vector3i
	var facing := 0
	var boxes: Array = []

	func _init(anchor: Vector3i, turn: int) -> void:
		at = anchor
		facing = posmod(turn, 4)

	func w(p: Vector3i) -> Vector3i:
		match facing:
			1:
				return at + Vector3i(-p.z, p.y, p.x)
			2:
				return at + Vector3i(-p.x, p.y, -p.z)
			3:
				return at + Vector3i(p.z, p.y, -p.x)
		return at + p

	## A box from local lo to local hi (exclusive), in the world.
	func box(lo: Vector3i, hi: Vector3i, id: int) -> void:
		if hi.x <= lo.x or hi.y <= lo.y or hi.z <= lo.z:
			return
		var a := w(lo)
		var b := w(hi - Vector3i.ONE)
		boxes.append([a.min(b), a.max(b) + Vector3i.ONE, id])

	## A pad under local [x0, x1) x [z0, z1): air CLEAR high over it, dirt under it, `top` on it.
	func pad(x0: int, z0: int, x1: int, z1: int, top: int) -> void:
		box(Vector3i(x0, 0, z0), Vector3i(x1, CLEAR, z1), BlockIds.AIR)
		box(Vector3i(x0, -PAD_DEPTH, z0), Vector3i(x1, -1, z1), BlockIds.DIRT)
		box(Vector3i(x0, -1, z0), Vector3i(x1, 0, z1), top)

	func world_yaw(local_yaw: float) -> float:
		return local_yaw - facing * PI * 0.5

	func wf(p: Vector3) -> Vector3:
		var c := w(Vector3i(floori(p.x), floori(p.y), floori(p.z)))
		return Vector3(c.x + p.x - floorf(p.x), c.y + p.y - floorf(p.y), c.z + p.z - floorf(p.z))


## The world rect a local rect covers.
static func _world_rect(s: Sketch, x0: int, z0: int, x1: int, z1: int) -> Rect2i:
	var a := s.w(Vector3i(x0, 0, z0))
	var b := s.w(Vector3i(x1 - 1, 0, z1 - 1))
	var lo := Vector2i(mini(a.x, b.x), mini(a.z, b.z))
	var hi := Vector2i(maxi(a.x, b.x), maxi(a.z, b.z)) + Vector2i.ONE
	return Rect2i(lo, hi - lo)


## A small house: plaster or plank walls on log corners, a gabled roof of tiles, glass windows, an open door, a
## lantern and a barrel inside. Local: centred on (0, 0), door at +z. half_w x half_d are the walls' half sizes.
## `lab` (spec §23): a lab bench against the back wall, under its window (some village houses have one).
static func _house(s: Sketch, half_w: int, half_d: int, wall: int, post: int, lab: bool = false) -> void:
	s.pad(-half_w - 1, -half_d - 1, half_w + 2, half_d + 2, BlockIds.GRASS)
	s.box(Vector3i(-half_w, -1, -half_d), Vector3i(half_w + 1, 0, half_d + 1), BlockIds.PLANKS)   # the floor
	s.box(Vector3i(-half_w, 0, -half_d), Vector3i(half_w + 1, 3, half_d + 1), wall)
	s.box(Vector3i(-half_w + 1, 0, -half_d + 1), Vector3i(half_w, 3, half_d), BlockIds.AIR)
	for cx in [-half_w, half_w]:
		for cz in [-half_d, half_d]:
			s.box(Vector3i(cx, 0, cz), Vector3i(cx + 1, 3, cz + 1), post)
	s.box(Vector3i(0, 0, half_d), Vector3i(1, 2, half_d + 1), BlockIds.DOOR_OPEN)
	s.box(Vector3i(-half_w, 1, 0), Vector3i(-half_w + 1, 2, 1), BlockIds.GLASS)
	s.box(Vector3i(half_w, 1, 0), Vector3i(half_w + 1, 2, 1), BlockIds.GLASS)
	s.box(Vector3i(0, 1, -half_d), Vector3i(1, 2, -half_d + 1), BlockIds.GLASS)
	s.box(Vector3i(-half_w + 1, 0, -half_d + 1), Vector3i(-half_w + 2, 1, -half_d + 2), BlockIds.LANTERN)
	s.box(Vector3i(half_w - 1, 0, -half_d + 1), Vector3i(half_w, 1, -half_d + 2), BlockIds.BARREL)
	if lab:   # spec §23: the Science Lab's bench
		s.box(Vector3i(0, 0, -half_d + 1), Vector3i(1, 1, -half_d + 2), BlockIds.LAB_BENCH)
	# the roof: two slopes stepping in one block a layer, the gable ends filled with the wall
	var k := 0
	while true:
		var left := -half_w - 1 + k
		var right := half_w + 1 - k
		if left > right:
			break
		if right - left <= 2:   # the ridge
			s.box(Vector3i(left, 3 + k, -half_d - 1), Vector3i(right + 1, 4 + k, half_d + 2), BlockIds.ROOF_TILES)
			break
		s.box(Vector3i(left, 3 + k, -half_d - 1), Vector3i(left + 2, 4 + k, half_d + 2), BlockIds.ROOF_TILES)
		s.box(Vector3i(right - 1, 3 + k, -half_d - 1), Vector3i(right + 1, 4 + k, half_d + 2), BlockIds.ROOF_TILES)
		if right - left > 3:
			for gz in [-half_d, half_d]:
				s.box(Vector3i(left + 2, 3 + k, gz), Vector3i(right - 1, 4 + k, gz + 1), wall)
		k += 1


## A spiral stair up a 3 x 3 inside round a middle post, from local height 0 to `steps` - 1, starting on the ring
## at `first`; returns the steps' world cells in order.
static func _stair(s: Sketch, steps: int, first: int, post: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	s.box(Vector3i(0, 0, 0), Vector3i(1, steps + 1, 1), post)
	for i in steps:
		var c: Vector2i = RING[(first + i) % RING.size()]
		s.box(Vector3i(c.x, i, c.y), Vector3i(c.x + 1, i + 1, c.y + 1), BlockIds.PLANKS)
		out.append(s.w(Vector3i(c.x, i, c.y)))
	return out


# --- The kinds ---

## A windmill: a stone base with a door, a white plaster body, a roof of tiles and four sails on its front.
func _windmill(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var turn := v % 4
	if not _col(memo, x, z).y in OPEN_LAND:
		return {}
	var f := _floor(memo, x - 3, z - 3, x + 4, z + 4)
	if f < 0:
		return {}
	var s := Sketch.new(Vector3i(x, f, z), turn)
	s.pad(-3, -3, 4, 4, BlockIds.GRASS)
	s.box(Vector3i(-3, 0, -3), Vector3i(4, CLEAR, 5), BlockIds.AIR)   # the sails' room in front
	s.box(Vector3i(-2, -1, -2), Vector3i(3, 0, 3), BlockIds.PLANKS)
	s.box(Vector3i(-2, 0, -2), Vector3i(3, 4, 3), BlockIds.STONE_BRICK)
	s.box(Vector3i(-1, 0, -1), Vector3i(2, 3, 2), BlockIds.AIR)
	s.box(Vector3i(0, 0, 2), Vector3i(1, 2, 3), BlockIds.DOOR_OPEN)
	s.box(Vector3i(-1, 0, -1), Vector3i(0, 1, 0), BlockIds.HAY)
	s.box(Vector3i(1, 0, -1), Vector3i(2, 2, 0), BlockIds.HAY)
	s.box(Vector3i(-1, 2, 1), Vector3i(0, 3, 2), BlockIds.LANTERN)
	s.box(Vector3i(-2, 4, -2), Vector3i(3, 10, 3), BlockIds.PLASTER)
	for cx in [-2, 2]:
		for cz in [-2, 2]:
			s.box(Vector3i(cx, 4, cz), Vector3i(cx + 1, 10, cz + 1), BlockIds.AIR)   # rounded corners
	s.box(Vector3i(-2, 10, -2), Vector3i(3, 11, 3), BlockIds.ROOF_TILES)
	s.box(Vector3i(-1, 11, -1), Vector3i(2, 12, 2), BlockIds.ROOF_TILES)
	s.box(Vector3i(0, 12, 0), Vector3i(1, 13, 1), BlockIds.ROOF_TILES)
	s.box(Vector3i(-1, 5, 2), Vector3i(0, 6, 3), BlockIds.GLASS)
	# the sails: a hub on the front and four arms turning round it (a spar and a sail cloth beside it)
	var hub := Vector3i(0, 8, 3)
	s.box(hub, hub + Vector3i.ONE, BlockIds.LOG)
	s.box(Vector3i(0, 9, 3), Vector3i(1, 14, 4), BlockIds.PLANKS)
	s.box(Vector3i(1, 10, 3), Vector3i(2, 14, 4), BlockIds.SAIL)
	s.box(Vector3i(1, 8, 3), Vector3i(6, 9, 4), BlockIds.PLANKS)
	s.box(Vector3i(2, 7, 3), Vector3i(6, 8, 4), BlockIds.SAIL)
	s.box(Vector3i(0, 3, 3), Vector3i(1, 8, 4), BlockIds.PLANKS)
	s.box(Vector3i(-1, 3, 3), Vector3i(0, 7, 4), BlockIds.SAIL)
	s.box(Vector3i(-5, 8, 3), Vector3i(0, 9, 4), BlockIds.PLANKS)
	s.box(Vector3i(-5, 9, 3), Vector3i(-1, 10, 4), BlockIds.SAIL)
	return {"boxes": s.boxes, "anchor": Vector3i(x, f, z), "name": _name(v >> 2) + " Mill",
		"doors": [[s.w(Vector3i(0, 0, 2)), s.w(Vector3i(0, 0, 3))]], "villagers": [[s.wf(Vector3(1.5, 0, 3.5)), s.world_yaw(0.0)]]}


## A village (or a town): a plaza of paths round a well, houses round it with their doors to the plaza, paths to
## them, a wheat farm with hay; a town is bigger (two rings of houses, market stalls on its plaza).
func _village(memo: Dictionary, x: int, z: int, v: int, town: bool) -> Dictionary:
	var plaza := 6 if town else 4
	if not _col(memo, x, z).y in VILLAGE_LAND:
		return {}
	var f := _floor(memo, x - plaza, z - plaza, x + plaza + 1, z + plaza + 1)
	if f < 0:
		return {}
	var s := Sketch.new(Vector3i(x, f, z), 0)
	s.pad(-plaza, -plaza, plaza + 1, plaza + 1, BlockIds.PATH)
	# the well
	s.box(Vector3i(-1, -4, -1), Vector3i(2, 1, 2), BlockIds.STONE_BRICK)
	s.box(Vector3i(0, -3, 0), Vector3i(1, 1, 1), BlockIds.WATER)
	for c: Vector2i in [Vector2i(-1, -1), Vector2i(1, 1)]:
		s.box(Vector3i(c.x, 1, c.y), Vector3i(c.x + 1, 3, c.y + 1), BlockIds.LOG)
	s.box(Vector3i(-1, 3, -1), Vector3i(2, 4, 2), BlockIds.ROOF_TILES)
	var villagers: Array = [[Vector3(x + 2.5, f, z + 0.5), -PI * 0.5], [Vector3(x - 1.5, f, z + 2.5), PI]]
	if town:   # market stalls in the plaza's corners
		for c: Vector2i in [Vector2i(-4, -4), Vector2i(4, -4), Vector2i(-4, 4), Vector2i(4, 4)]:
			_stall(s, c, (v >> (c.x + 8)) & 3)
		villagers.append([Vector3(x - 3.5, f, z - 2.5), 0.0])
		villagers.append([Vector3(x + 4.5, f, z + 2.5), PI])
	var houses: Array = []
	var doors: Array = []
	var rings: Array = [[plaza + 9, 8]] + ([[plaza + 21, 12]] if town else [])
	var farm_done := false
	var wall := BlockIds.PLASTER if v % 2 == 0 else BlockIds.PLANKS
	var post := _post_for(_col(memo, x, z).y)
	for ring: Array in rings:
		var radius: int = ring[0]
		var slots: int = ring[1]
		var turn0 := float(v % 97) / 97.0 * TAU
		var lab_slot := (v >> 7) % slots   # spec §23: the house with a lab bench (none when that slot has no house)
		for i in slots:
			var a := turn0 + TAU * i / slots
			var hx := x + roundi(cos(a) * radius)
			var hz := z + roundi(sin(a) * radius)
			var facing := _facing_to(hx, hz, x, z)
			var hs := 2 + (v >> (i + 3)) % 2   # half width 2 or 3
			var hd := 2 + (v >> (i + 5)) % 2
			var r := maxi(hs, hd) + 1
			if not farm_done and i == slots / 2 and not _overlaps(houses, Rect2i(hx - 5, hz - 5, 11, 11)):
				var ff := _farm(memo, s, hx, hz, facing)
				if ff >= 0:
					farm_done = true
					houses.append([Vector3i(hx - 5, ff, hz - 5), Vector3i(hx + 6, ff, hz + 6), ff])
					villagers.append([Vector3(hx + 0.5, ff, hz + 0.5), 0.0])
					continue
			var hf := _floor(memo, hx - r - 1, hz - r - 1, hx + r + 2, hz + r + 2)
			if hf < 0 or _overlaps(houses, Rect2i(hx - r, hz - r, 2 * r + 1, 2 * r + 1)):
				continue
			var hsk := Sketch.new(Vector3i(hx, hf, hz), facing)
			_house(hsk, hs, hd, wall if i % 3 != 2 else BlockIds.PLANKS, post, i == lab_slot)
			s.boxes.append_array(hsk.boxes)
			var door := hsk.w(Vector3i(0, 0, hd))
			var front := hsk.w(Vector3i(0, 0, hd + 1))
			doors.append([door, front])
			houses.append([Vector3i(hx - r, hf, hz - r), Vector3i(hx + r + 1, hf, hz + r + 1), hf])
			_path(memo, s, front, Vector3i(x, f, z), plaza, houses)
			if i % 2 == 0:
				villagers.append([hsk.wf(Vector3(0.5, 0, hd + 1.5)), hsk.world_yaw(0.0)])
	var built := houses.size() - (1 if farm_done else 0)
	if built < (6 if town else 3):
		return {}
	var name := _name(v >> 3)
	return {"boxes": s.boxes, "anchor": Vector3i(x, f, z), "name": name + " Town" if town else name,
		"houses": houses, "doors": doors, "villagers": villagers}


## Which way (Sketch facing) a building at (hx, hz) turns so its front (+z) looks at (tx, tz).
static func _facing_to(hx: int, hz: int, tx: int, tz: int) -> int:
	var d := Vector2(tx - hx, tz - hz)
	if absf(d.x) > absf(d.y):
		return 3 if d.x > 0 else 1
	return 0 if d.y > 0 else 2


static func _overlaps(houses: Array, r: Rect2i) -> bool:
	for h: Array in houses:
		var lo: Vector3i = h[0]
		var hi: Vector3i = h[1]
		if Rect2i(Vector2i(lo.x, lo.z), Vector2i(hi.x - lo.x, hi.z - lo.z)).grow(1).intersects(r):
			return true
	return false


## The logs of the village's trees: birch in a birch forest, dark wood in a dark forest or a swamp, oak elsewhere.
static func _post_for(biome: int) -> int:
	match biome:
		MeadowsBiomeShape.BIRCH:
			return BlockIds.BIRCH_LOG
		MeadowsBiomeShape.DARK, MeadowsBiomeShape.SWAMP:
			return BlockIds.DARK_LOG
	return BlockIds.LOG


## A dirt path from `from` (the cell in front of a door) to the plaza's edge, on the ground as it lies (the path
## replaces its top block), never across a house.
func _path(memo: Dictionary, s: Sketch, from: Vector3i, centre: Vector3i, plaza: int, houses: Array) -> void:
	var p := Vector2i(from.x, from.z)
	var goal := Vector2i(centre.x, centre.z)
	for step in 60:
		if absi(p.x - goal.x) <= plaza and absi(p.y - goal.y) <= plaza:
			return
		var d := goal - p
		p += Vector2i(signi(d.x), 0) if absi(d.x) > absi(d.y) else Vector2i(0, signi(d.y))
		if _inside_house(houses, p):
			continue
		if not _dry(memo, p.x, p.y):
			return
		var h := _h(memo, p.x, p.y)
		s.boxes.append([Vector3i(p.x, h - 1, p.y), Vector3i(p.x + 1, h, p.y + 1), BlockIds.PATH])


static func _inside_house(houses: Array, p: Vector2i) -> bool:
	for h: Array in houses:
		var lo: Vector3i = h[0]
		var hi: Vector3i = h[1]
		if p.x >= lo.x and p.x < hi.x and p.y >= lo.z and p.y < hi.z:
			return true
	return false


## A wheat farm: 7 x 5 of wheat on dirt with a water channel down its middle, hay bales at its end. Its floor, or
## -1 where it doesn't fit.
func _farm(memo: Dictionary, s: Sketch, hx: int, hz: int, facing: int) -> int:
	var ff := _floor(memo, hx - 4, hz - 4, hx + 5, hz + 5)
	if ff < 0:
		return -1
	var k := Sketch.new(Vector3i(hx, ff, hz), facing)
	k.pad(-4, -3, 5, 4, BlockIds.GRASS)
	k.box(Vector3i(-3, -1, -2), Vector3i(4, 0, 3), BlockIds.DIRT)
	k.box(Vector3i(-3, 0, -2), Vector3i(4, 1, 3), BlockIds.WHEAT)
	k.box(Vector3i(-3, -1, 0), Vector3i(4, 0, 1), BlockIds.WATER)
	k.box(Vector3i(-3, 0, 0), Vector3i(4, 1, 1), BlockIds.AIR)
	k.box(Vector3i(4, 0, -2), Vector3i(5, 1, 0), BlockIds.HAY)
	k.box(Vector3i(4, 1, -2), Vector3i(5, 2, -1), BlockIds.HAY)
	s.boxes.append_array(k.boxes)
	return ff


## A market stall on a town's plaza: four posts, a cloth roof, goods on a counter.
static func _stall(s: Sketch, c: Vector2i, goods: int) -> void:
	for d: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		s.box(Vector3i(c.x + d.x, 0, c.y + d.y), Vector3i(c.x + d.x + 1, 3, c.y + d.y + 1), BlockIds.LOG)
	s.box(Vector3i(c.x - 1, 3, c.y - 1), Vector3i(c.x + 2, 4, c.y + 2), BlockIds.SAIL if goods % 2 == 0 else BlockIds.RED)
	s.box(Vector3i(c.x, 0, c.y), Vector3i(c.x + 1, 1, c.y + 1),
		[BlockIds.HAY, BlockIds.BARREL, BlockIds.WHEAT, BlockIds.FLOWERS][goods])


## A lookout tower: stone bricks, a spiral stair inside to a battlemented top with a flag (a view far over the
## land); a lighthouse is `light` (see _lighthouse).
func _tower(memo: Dictionary, x: int, z: int, v: int, light: bool) -> Dictionary:
	var turn := v % 4
	var f := _floor(memo, x - 3, z - 3, x + 4, z + 4)
	if f < 0:
		return {}
	var s := Sketch.new(Vector3i(x, f, z), turn)
	var height := 14 + (v >> 2) % 4
	_tower_body(s, height, BlockIds.STONE_BRICK, BlockIds.MOSSY_BRICK if (v >> 4) % 2 == 0 else BlockIds.STONE_BRICK)
	var stairs := _stair(s, height, 6, BlockIds.STONE_BRICK)
	# the top: a floor with the stair's way up, battlements, a flag
	s.box(Vector3i(-2, height, -2), Vector3i(3, height + 1, 3), BlockIds.PLANKS)
	_open_over_stair(s, stairs, height)
	for c: Vector2i in [Vector2i(-2, -2), Vector2i(0, -2), Vector2i(2, -2), Vector2i(-2, 0), Vector2i(2, 0), Vector2i(-2, 2),
			Vector2i(2, 2)]:
		s.box(Vector3i(c.x, height + 1, c.y), Vector3i(c.x + 1, height + 2, c.y + 1), BlockIds.STONE_BRICK)
	s.box(Vector3i(2, height + 2, -2), Vector3i(3, height + 5, -1), BlockIds.LOG)
	s.box(Vector3i(1, height + 3, -2), Vector3i(2, height + 5, -1), BlockIds.RED if (v >> 5) % 2 == 0 else BlockIds.BLUE)
	return {"boxes": s.boxes, "anchor": Vector3i(x, f, z), "name": _name(v >> 6) + " Lookout",
		"doors": [[s.w(Vector3i(0, 0, 2)), s.w(Vector3i(0, 0, 3))]], "stairs": stairs, "top": s.w(Vector3i(0, height + 1, 0))}


## A tower's 5 x 5 round body (the corners cut) `height` high, hollow, with an open door at +z and window slits.
static func _tower_body(s: Sketch, height: int, wall: int, band: int) -> void:
	s.pad(-3, -3, 4, 4, BlockIds.GRASS)
	s.box(Vector3i(-2, 0, -2), Vector3i(3, height, 3), wall)
	for y in range(3, height, 4):
		s.box(Vector3i(-2, y, -2), Vector3i(3, y + 1, 3), band)
	for cx in [-2, 2]:
		for cz in [-2, 2]:
			s.box(Vector3i(cx, 0, cz), Vector3i(cx + 1, height, cz + 1), BlockIds.AIR)
	s.box(Vector3i(-1, 0, -1), Vector3i(2, height, 2), BlockIds.AIR)
	s.box(Vector3i(0, 0, 2), Vector3i(1, 2, 3), BlockIds.DOOR_OPEN)
	for y in range(5, height - 1, 4):
		s.box(Vector3i(-2, y, 0), Vector3i(-1, y + 1, 1), BlockIds.GLASS)
		s.box(Vector3i(2, y, 0), Vector3i(3, y + 1, 1), BlockIds.GLASS)


## The floor at the stair's top has no block over its last three steps (a head fits through).
static func _open_over_stair(s: Sketch, stairs: Array[Vector3i], height: int) -> void:
	for i in range(maxi(stairs.size() - 3, 0), stairs.size()):
		var c := stairs[i]
		var top := Vector3i(c.x, s.at.y + height, c.z)
		s.boxes.append([top, top + Vector3i.ONE, BlockIds.AIR])


## A lighthouse on a coast: a white tower with red bands, a spiral stair to a glass lamp room with a glowing lamp,
## its door to the land and the sea within reach on the other side.
func _lighthouse(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var f := _floor(memo, x - 3, z - 3, x + 4, z + 4)
	if f < 0:
		return {}
	var sea := -1
	for turn in 4:   # the sea behind it (local -z), within 14 blocks
		var s0 := Sketch.new(Vector3i(x, f, z), turn)
		for d in range(5, 20):
			var p := s0.w(Vector3i(0, 0, -d))
			if _h(memo, p.x, p.z) < SEA - 1 and shape.coast_share(p.x, p.z) < 0.9:
				sea = turn
				break
		if sea >= 0:
			break
	if sea < 0:
		return {}
	var s := Sketch.new(Vector3i(x, f, z), sea)
	var height := 16 + (v >> 2) % 4
	_tower_body(s, height, BlockIds.PLASTER, BlockIds.RED)
	var stairs := _stair(s, height, 6, BlockIds.PLASTER)
	s.box(Vector3i(-2, height, -2), Vector3i(3, height + 1, 3), BlockIds.STONE_BRICK)
	_open_over_stair(s, stairs, height)
	# the lamp room: glass walls round the top, the lamp in the middle, a red roof
	s.box(Vector3i(-2, height + 1, -2), Vector3i(3, height + 3, 3), BlockIds.GLASS)
	s.box(Vector3i(-1, height + 1, -1), Vector3i(2, height + 3, 2), BlockIds.AIR)
	for cx in [-2, 2]:
		for cz in [-2, 2]:
			s.box(Vector3i(cx, height + 1, cz), Vector3i(cx + 1, height + 3, cz + 1), BlockIds.PLASTER)
	s.box(Vector3i(0, height + 1, 0), Vector3i(1, height + 2, 1), BlockIds.GOLD_LAMP)
	for y in [height + 3]:
		s.box(Vector3i(-2, y, -2), Vector3i(3, y + 1, 3), BlockIds.RED)
	s.box(Vector3i(-1, height + 4, -1), Vector3i(2, height + 5, 2), BlockIds.RED)
	s.box(Vector3i(0, height + 5, 0), Vector3i(1, height + 6, 1), BlockIds.LIGHT)
	return {"boxes": s.boxes, "anchor": Vector3i(x, f, z), "name": _name(v >> 6) + " Lighthouse",
		"doors": [[s.w(Vector3i(0, 0, 2)), s.w(Vector3i(0, 0, 3))]], "stairs": stairs, "top": s.w(Vector3i(0, height + 1, 1))}


## A ship moored at a pier: a plank hull (air inside, in deep enough water), a deck, two masts with sails, a
## cabin at the stern, and a pier from its side to the shore.
func _ship(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	for turn in 4:
		var s := Sketch.new(Vector3i(x, SEA, z), (v + turn) % 4)
		var deep := true
		for lz in range(-7, 8, 2):
			for lx in [-2, 0, 2]:
				var p := s.w(Vector3i(lx, 0, lz))
				if _h(memo, p.x, p.z) > SEA - 3:
					deep = false
		if not deep:
			continue
		var pier := -1   # the shore along local +x from the hull's middle
		for d in range(4, 15):
			var p := s.w(Vector3i(d, 0, 0))
			if _dry(memo, p.x, p.z) and _h(memo, p.x, p.z) <= SEA + 3:
				pier = d
				break
		if pier < 0:
			continue
		var land := s.w(Vector3i(pier, 0, 0))
		var lh := _h(memo, land.x, land.z)
		var deck := 1                     # the deck's blocks at SEA + 1: its top is the pier's
		s.box(Vector3i(-2, -3, -7), Vector3i(3, deck + 6, 8), BlockIds.AIR)   # nothing in the way (the air over the water)
		s.box(Vector3i(-2, -3, -7), Vector3i(3, 0, 8), BlockIds.WATER)
		# the hull
		s.box(Vector3i(-1, -3, -5), Vector3i(2, -2, 6), BlockIds.LOG)
		s.box(Vector3i(-2, -2, -6), Vector3i(3, deck + 1, 7), BlockIds.PLANKS)
		s.box(Vector3i(-1, -2, -7), Vector3i(2, deck + 1, 8), BlockIds.PLANKS)
		s.box(Vector3i(-1, -2, -5), Vector3i(2, deck, 6), BlockIds.AIR)
		s.box(Vector3i(-1, deck, -6), Vector3i(2, deck + 1, 7), BlockIds.PLANKS)
		s.box(Vector3i(-2, deck + 1, -6), Vector3i(-1, deck + 2, 7), BlockIds.LOG)   # the rails
		s.box(Vector3i(2, deck + 1, -6), Vector3i(3, deck + 2, 7), BlockIds.LOG)
		s.box(Vector3i(2, deck + 1, -1), Vector3i(3, deck + 2, 2), BlockIds.AIR)     # the way to the pier
		# the masts and sails
		for m: Array in [[-3, 9], [2, 7]]:
			var mz: int = m[0]
			var mh: int = m[1]
			s.box(Vector3i(0, deck + 1, mz), Vector3i(1, deck + 1 + mh, mz + 1), BlockIds.LOG)
			s.box(Vector3i(-2, deck + 4, mz + 1), Vector3i(3, deck + mh, mz + 2), BlockIds.SAIL)
		s.box(Vector3i(-1, deck + 10, -3), Vector3i(0, deck + 11, -2), BlockIds.RED)   # a pennant
		# the cabin at the stern
		s.box(Vector3i(-1, deck + 1, 4), Vector3i(2, deck + 3, 7), BlockIds.PLANKS)
		s.box(Vector3i(0, deck + 1, 5), Vector3i(1, deck + 3, 6), BlockIds.AIR)
		s.box(Vector3i(0, deck + 1, 4), Vector3i(1, deck + 3, 5), BlockIds.DOOR_OPEN)
		s.box(Vector3i(-1, deck + 3, 4), Vector3i(2, deck + 4, 7), BlockIds.ROOF_TILES)
		s.box(Vector3i(-1, deck + 1, 6), Vector3i(0, deck + 2, 7), BlockIds.BARREL)
		# the pier to the shore, on posts
		s.box(Vector3i(3, deck, -1), Vector3i(pier + 1, deck + 1, 2), BlockIds.PLANKS)
		s.box(Vector3i(3, deck + 1, -1), Vector3i(pier + 1, deck + 4, 2), BlockIds.AIR)
		for px in range(4, pier, 3):
			s.box(Vector3i(px, -4, 2), Vector3i(px + 1, deck, 3), BlockIds.LOG)
		s.box(Vector3i(pier, lh - SEA - 1, -1), Vector3i(pier + 1, deck, 2), BlockIds.PLANKS)   # down to the shore
		var anchor := s.w(Vector3i(0, deck + 1, 0))
		return {"boxes": s.boxes, "anchor": anchor, "name": SHIP_NAMES[(v >> 4) % SHIP_NAMES.size()],
			"doors": [[s.w(Vector3i(0, deck + 1, 4)), s.w(Vector3i(0, deck + 1, 3))]],
			"pier": [s.w(Vector3i(3, deck, 0)), land], "villagers": [[s.wf(Vector3(0.5, deck + 1, -0.5)), s.world_yaw(PI)]]}
	return {}


## Castle ruins: a courtyard of grass inside broken walls of stone and mossy bricks (each piece its own height, some
## gone), four hollow corner towers of different heights, a gate, and the stumps of a keep in the middle.
func _castle(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	if _col(memo, x, z).y == MeadowsBiomeShape.SWAMP:
		return {}
	var f := _floor(memo, x - 11, z - 11, x + 12, z + 12, SLOPE + 1)
	if f < 0:
		return {}
	var s := Sketch.new(Vector3i(x, f, z), v % 4)
	s.pad(-11, -11, 12, 12, BlockIds.GRASS)
	var rng := RandomNumberGenerator.new()
	rng.seed = v
	# the walls, in pieces of three
	for side in 4:
		var w := Sketch.new(Vector3i(x, f, z), (v + side) % 4)
		for i in range(-7, 8, 3):
			var h := rng.randi_range(0, 5)
			var brick := BlockIds.MOSSY_BRICK if rng.randf() < 0.4 else BlockIds.STONE_BRICK
			if side == 0 and i == -1:
				w.box(Vector3i(i, 3, 9), Vector3i(i + 3, 5, 10), brick)   # the gate's arch
				continue
			w.box(Vector3i(i, 0, 9), Vector3i(i + 3, h, 10), brick)
		s.boxes.append_array(w.boxes)
	# the corner towers
	for c: Vector2i in [Vector2i(-10, -10), Vector2i(8, -10), Vector2i(-10, 8), Vector2i(8, 8)]:
		var th := rng.randi_range(4, 9)
		var brick := BlockIds.MOSSY_BRICK if rng.randf() < 0.5 else BlockIds.STONE_BRICK
		s.box(Vector3i(c.x, 0, c.y), Vector3i(c.x + 3, th, c.y + 3), brick)
		s.box(Vector3i(c.x + 1, 0, c.y + 1), Vector3i(c.x + 2, th, c.y + 2), BlockIds.AIR)
		s.box(Vector3i(c.x + 1, 0, c.y + (0 if c.y > 0 else 2)), Vector3i(c.x + 2, 2, c.y + (1 if c.y > 0 else 3)), BlockIds.AIR)
	# the keep's stumps
	for side in 4:
		var k := Sketch.new(Vector3i(x, f, z), side)
		k.box(Vector3i(-3, 0, 3), Vector3i(4, rng.randi_range(1, 6), 4), BlockIds.MOSSY_BRICK if side % 2 == 0 else BlockIds.STONE_BRICK)
		s.boxes.append_array(k.boxes)
	s.box(Vector3i(0, 0, 3), Vector3i(1, 2, 4), BlockIds.AIR)   # the keep's doorway, facing the gate
	s.box(Vector3i(-2, -1, -2), Vector3i(3, 0, 3), BlockIds.MOSSY_BRICK)   # its broken floor
	s.box(Vector3i(0, 0, 0), Vector3i(1, 1, 1), BlockIds.LANTERN)
	return {"boxes": s.boxes, "anchor": Vector3i(x, f, z), "name": _name(v >> 5) + " Castle",
		"doors": [[s.w(Vector3i(0, 0, 9)), s.w(Vector3i(0, 0, 10))]]}


func _mix(x: int, z: int) -> int:
	var h := x * 668265263 + z * 374761393 + seed * 1597334677 + 4545
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)
