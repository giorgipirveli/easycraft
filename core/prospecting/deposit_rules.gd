class_name DepositRules
extends RefCounted
## Where a world hides its rich deposits (spec §26.1, owner #80), as pure rules of the seed and the terrain: every
## 512 × 512 region of Green Meadows holds at most one deposit of gold, iron and coal, and every region of the Sandstorm
## Desert one of copper, oil and salt, each in the setting real geology gives it and with its telltale sign on top:
## - gold: flakes of gold in the gravel where a river (or a lake's shore) runs below a hill (GOLD_GRAVEL, a placer), and
##   a white quartz vein with gold in the hillside above (GOLD_QUARTZ, the lode it washed out of);
## - iron: rusty rock on a hilltop (RUSTY_ROCK, the gossan) over a lens of banded iron (BANDED_IRON);
## - coal: a seam three blocks thick running into a hillside (COAL), under two layers of fern shale (FERN_SHALE);
## - copper: a green-stained mesa edge (MALACHITE) over a body of copper ore (COPPER_ORE) inside the mesa;
## - oil: a patch of oil seep (OIL_SEEP) on the flank of a buried dome on the open desert floor; the oil itself lies
##   far down (depth_m: what the echo survey finds) and is pumped, never dug;
## - salt: a salt flat on level desert ground (SALT_CRUST) over rock salt (ROCK_SALT).
## Spec §26.5: the Moon's and Mars's regions hold their own five kinds each (SpaceDepositSites: ice in dark craters,
## ilmenite and helium-3 in the dark seas, KREEP on a crater's rim, meteorites; Mars's ground ice, hematite, dark sand,
## salt and meteorites), never on the colony's ground (spec §21c: ColonyLayout.near_box).
## Never within MIN_FROM_SPAWN of the world spawn (finding one is an adventure), never on a secret, a mouse village or
## a wild-meadows place (GAP apart), two deposits of a region APART from each other. A deposit writes only over the
## world's own ground (GROUND) and clears only plants (PLANTS): a cave stays a cave, a river's water stays. A cell of a
## negative id stands on the ground: it fills only AIR (a meteorite's lump lying on the plain).
##
## A deposit: {id ("gold:rx:rz"), kind, region, anchor (Vector3i: its middle, the MY MAP mark), spots (Array of
## Vector3i: where a quest leads, in order: gold has the gravel then the vein, oil the seep then the dome's top), signs
## (per spot: Array of Vector3i, the sign's cells a child sees; [] at a spot with no sign), lo, hi (the bounds of its cells, hi exclusive), cells ({chunk key: PackedInt32Array of
## x, y, z, id; a negative id stands in the air}), count (ore cells), depth_m and drums (oil)}. Read-only once made; a
## small cache behind a mutex: the generator's threads share one (MeadowsGenerator writes them with the secrets, `write`).

const REGION := 512
const MARGIN := 48                # candidates this far inside their region (every cell stays inside it)
const STEP := 16                  # the coarse look at a region's ground
const MIN_FROM_SPAWN := 128.0
const APART := 64.0
const GAP := 4
const CACHE_LIMIT := 64
const SEA := MeadowsShape.SEA_LEVEL
const CH := VoxelBuffer.CHANNEL_TYPE
## The world's own ground: what a deposit may turn into ore or a sign.
const GROUND := {BlockIds.GRASS: true, BlockIds.DIRT: true, BlockIds.STONE: true, BlockIds.DEEPSTONE: true,
	BlockIds.SAND: true, BlockIds.SNOW: true, BlockIds.MUD: true, BlockIds.SANDSTONE: true, BlockIds.RED_SANDSTONE: true,
	BlockIds.RED_SAND: true, BlockIds.COAL: true, BlockIds.IRON: true, BlockIds.GOLD: true,
	BlockIds.MOON_DUST: true, BlockIds.MOON_ROCK: true, BlockIds.DEEP_MOON_ROCK: true,   # spec §26.5: the Moon's
	BlockIds.MARS_DUST: true, BlockIds.MARS_REGOLITH: true, BlockIds.BASALT: true, BlockIds.DEEP_BASALT: true,   # Mars's
	BlockIds.MARS_SEDIMENT: true}
## Plants a deposit's AIR cells clear (a cactus on a salt flat, flowers on rusty rock).
const PLANTS := {BlockIds.FLOWERS: true, BlockIds.CACTUS: true, BlockIds.DEAD_BUSH: true}
## The oil's depth under its dome, in metres (the echo survey: SurveyRules.echo_seconds).
const OIL_DEPTHS: Array[int] = [1000, 1500, 2000, 2500, 3000]
## Drums of crude oil an oil well gives before it runs dry (a deposit is finite; new quests find more).
const OIL_DRUMS := 40
const HILL := 10                  # gold: a hill this far over the sea by the water
const IRON_HILL := 14             # iron: a hilltop at least this far over the sea
const COAL_RISE := 8              # coal: the ground rises this much over one STEP (a hillside)
## How big the rich bodies are (tuned with RefiningRules' prices: a deposit is worth a few hundred gold in Survivor,
## about a day of learning, never more than the School: spec §25.1).
const VEIN_BELOW := 2             # gold: the quartz vein from 2 under the outcrop's top block ...
const VEIN_ABOVE := 2             # ... to 1 over it (4 tall), 3 wide, 11 long into the hill
const SEAM := 2                   # coal: a seam 2 thick under one layer of fern shale, 7 wide, 13 long
const SALT_LAYERS := 2            # salt: rock salt 2 deep under the crust
## Spec §26.5: Mars's ground ice lies this far or more from the equator (the canyon's line: MarsTerrain.canyon_z), in the
## cooler mid-latitudes, as the real shallow ice does.
const MARS_ICE_LATITUDE := 250

var seed: int
var shape: MeadowsShape
var kinds: Array[StringName] = []
var spawn: Vector2i
var secrets: SecretRules
var places: MeadowsPlaces
var desert := false
## Spec §26.5: the Moon's or Mars's terrain (null on Earth).
var space: SpaceShape

var _cache := {}
var _mutex := Mutex.new()


func _init(world_seed: int, terrain: MeadowsShape, which: Array[StringName], secret_rules: SecretRules = null,
		wild_places: MeadowsPlaces = null) -> void:
	seed = world_seed
	shape = terrain
	kinds = which
	secrets = secret_rules
	places = wild_places
	desert = terrain is DesertShape
	space = terrain as SpaceShape if terrain is SpaceShape else null
	spawn = secret_rules.spawn if secret_rules != null else terrain.spawn_column()


## The deposits of a world with this terrain (null for a terrain without any: Frostpeak, the Candy Kingdom, the
## Dragon Realm, the arena, the planets but the Moon and Mars).
static func for_world(world_seed: int, terrain: MeadowsShape, secret_rules: SecretRules = null,
		wild_places: MeadowsPlaces = null) -> DepositRules:
	var k := kinds_for(terrain)
	return DepositRules.new(world_seed, terrain, k, secret_rules, wild_places) if not k.is_empty() else null


## The deposit kinds of a terrain: the desert's, the meadows' (old or wild), the Moon's, Mars's, or none.
static func kinds_for(terrain: MeadowsShape) -> Array[StringName]:
	if terrain == null:
		return []
	if terrain is SpaceShape:   # spec §26.5
		match (terrain as SpaceShape).planet:
			SpaceShape.MOON:
				return DepositKinds.in_universe(SpaceRules.MOON)
			SpaceShape.MARS:
				return DepositKinds.in_universe(SpaceRules.MARS)
		return []
	if terrain is DesertShape:
		return DepositKinds.in_universe(2)
	if terrain is MeadowsBiomeShape or terrain.get_script() == MeadowsShape:
		return DepositKinds.in_universe(1)
	return []


static func region_of(x: int, z: int) -> Vector2i:
	return Vector2i(floori(x / float(REGION)), floori(z / float(REGION)))


static func chunk_key(p: Vector3i) -> Vector3i:
	return Vector3i(floori(p.x / 16.0), floori(p.y / 16.0), floori(p.z / 16.0))


static func is_id(id: String) -> bool:
	var parts := id.split(":")
	return parts.size() == 3 and DepositKinds.is_kind(StringName(parts[0])) and parts[1].is_valid_int() \
		and parts[2].is_valid_int()


## The deposits of one region (shared: never change the returned dictionaries).
func deposits_in_region(region: Vector2i) -> Array:
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


## The deposit with this id, or {}.
func find(id: String) -> Dictionary:
	if not is_id(id):
		return {}
	var parts := id.split(":")
	for d: Dictionary in deposits_in_region(Vector2i(int(parts[1]), int(parts[2]))):
		if d.id == id:
			return d
	return {}


## The nearest deposit of `kind` to `from` (sideways, by its anchor) whose id is not in `skip`, within `rings` regions
## around it, or {}. A quest's target: the next one is always farther on (the game never ends, #71).
func nearest(kind: StringName, from: Vector3, skip: Array = [], rings: int = 2) -> Dictionary:
	var r := region_of(floori(from.x), floori(from.z))
	var best := {}
	var best_d := INF
	for rz in range(r.y - rings, r.y + rings + 1):
		for rx in range(r.x - rings, r.x + rings + 1):
			for d: Dictionary in deposits_in_region(Vector2i(rx, rz)):
				if d.kind != kind or skip.has(d.id):
					continue
				var a: Vector3i = d.anchor
				var dist := Vector2(a.x + 0.5 - from.x, a.z + 0.5 - from.z).length_squared()
				if dist < best_d:
					best_d = dist
					best = d
	return best


# --- The generator's side ------------------------------------------------------------------------------------------

## Writes the deposits' cells that fall in this buffer (any box; a chunk usually looks at one region's few deposits):
## ore and signs only over the world's own ground, AIR only over plants.
func write(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	var end := origin + size
	var r0 := region_of(origin.x, origin.z)
	var r1 := region_of(end.x - 1, end.z - 1)
	for rz in range(r0.y, r1.y + 1):
		for rx in range(r0.x, r1.x + 1):
			for d: Dictionary in deposits_in_region(Vector2i(rx, rz)):
				var lo: Vector3i = d.lo
				var hi: Vector3i = d.hi
				if hi.x <= origin.x or hi.y <= origin.y or hi.z <= origin.z or lo.x >= end.x or lo.y >= end.y or lo.z >= end.z:
					continue
				var k0 := chunk_key(origin.max(lo))
				var k1 := chunk_key((end - Vector3i.ONE).min(hi - Vector3i.ONE))
				var cells: Dictionary = d.cells
				for ky in range(k0.y, k1.y + 1):
					for kz in range(k0.z, k1.z + 1):
						for kx in range(k0.x, k1.x + 1):
							var packed: Variant = cells.get(Vector3i(kx, ky, kz))
							if packed != null:
								_write_cells(buf, origin, size, packed)


static func _write_cells(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, packed: PackedInt32Array) -> void:
	for i in range(0, packed.size(), 4):
		var lx := packed[i] - origin.x
		var ly := packed[i + 1] - origin.y
		var lz := packed[i + 2] - origin.z
		if lx < 0 or ly < 0 or lz < 0 or lx >= size.x or ly >= size.y or lz >= size.z:
			continue
		var id := packed[i + 3]
		var cur := buf.get_voxel(lx, ly, lz, CH)
		if id == BlockIds.AIR:
			if PLANTS.has(cur):
				buf.set_voxel(BlockIds.AIR, lx, ly, lz, CH)
		elif id < 0:   # it stands on the ground: into the air only
			if cur == BlockIds.AIR:
				buf.set_voxel(-id, lx, ly, lz, CH)
		elif GROUND.has(cur):
			buf.set_voxel(id, lx, ly, lz, CH)


## The generator's reference: what a deposit puts at p over the world's own block `natural` there (ore or a sign over
## its ground, AIR over a plant, a lump standing on the ground over the air), or -1.
func block_at(p: Vector3i, natural: int) -> int:
	var ground := GROUND.has(natural)
	var air := natural == BlockIds.AIR
	if not ground and not air and not PLANTS.has(natural):
		return -1
	for d: Dictionary in deposits_in_region(region_of(p.x, p.z)):
		var lo: Vector3i = d.lo
		var hi: Vector3i = d.hi
		if p.x < lo.x or p.y < lo.y or p.z < lo.z or p.x >= hi.x or p.y >= hi.y or p.z >= hi.z:
			continue
		var packed: Variant = d.cells.get(chunk_key(p))
		if packed == null:
			continue
		var cells: PackedInt32Array = packed
		for i in range(0, cells.size(), 4):
			if cells[i] == p.x and cells[i + 1] == p.y and cells[i + 2] == p.z:
				var id := cells[i + 3]
				if id < 0:
					return -id if air else -1
				if air:
					return -1
				return id if (id == BlockIds.AIR) != ground else -1
	return -1


## Every cell of a deposit ({Vector3i: block id}; a cell standing on the ground has its block's id too; tests, tools).
static func cells_of(d: Dictionary) -> Dictionary:
	var out := {}
	for key: Vector3i in d.cells:
		var packed: PackedInt32Array = d.cells[key]
		for i in range(0, packed.size(), 4):
			out[Vector3i(packed[i], packed[i + 1], packed[i + 2])] = absi(packed[i + 3])
	return out


# --- Placing a region's deposits -----------------------------------------------------------------------------------

func _place(region: Vector2i) -> Array:
	var out: Array = []
	var cols: SpaceDepositSites.Cols = SpaceDepositSites.Cols.new(space) if space != null else null   # spec §26.5
	var samples := _survey(region, cols)
	var by := {}
	for s: Array in samples:
		by[Vector2i(s[0], s[1])] = s
	var taken: Array[Vector2i] = []
	for kind in kinds:
		var d := _site(kind, region, samples, by, taken, cols)
		if not d.is_empty():
			out.append(d)
			taken.append(Vector2i(d.anchor.x, d.anchor.z))
	return out


## The region's ground seen coarsely: [x, z, height, kind or river flag, floor] every STEP blocks inside the margin (on
## the Moon and Mars [x, z, height, Mars's region, crater flag] from the region's columns `cols`).
func _survey(region: Vector2i, cols: SpaceDepositSites.Cols = null) -> Array:
	var out: Array = []
	var base := region * REGION
	var n := (REGION - 2 * MARGIN) / STEP + 1
	for j in n:
		for i in n:
			var x := base.x + MARGIN + i * STEP
			var z := base.y + MARGIN + j * STEP
			var c := _column(x, z) if cols == null else cols.sample(x, z)
			out.append([x, z, c.x, c.y, c.z])
	return out


## (height, desert kind or river flag, floor) of a column.
func _column(x: int, z: int) -> Vector3i:
	if desert:
		return (shape as DesertShape).column(x, z)
	var c: Vector2i = shape._column(x, z)
	return Vector3i(c.x, c.y, c.x)


func _h(x: int, z: int) -> int:
	return shape.height_at(x, z)


## A deterministic number for this world, region, kind and salt.
func _roll(region: Vector2i, kind: StringName, salt: int) -> int:
	var h := region.x * 73856093 ^ region.y * 19349663 ^ hash(kind) * 83492791 ^ salt * 2654435761 ^ seed * 40503
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


func _far_from_spawn(x: int, z: int) -> bool:
	return Vector2(x - spawn.x, z - spawn.y).length() >= MIN_FROM_SPAWN


func _far_from(taken: Array[Vector2i], x: int, z: int) -> bool:
	for t in taken:
		if Vector2(x - t.x, z - t.y).length() < APART:
			return false
	return true


## The samples in a scrambled order (the same for a seed), so a region's deposit is not always in its first corner:
## from a start, a stride that shares no factor with the count visits each sample once (no sort: this runs on the
## generator's threads).
func _order(samples: Array, region: Vector2i, kind: StringName) -> Array:
	var n := samples.size()
	var roll := _roll(region, kind, 1)
	var stride := 1 + roll % maxi(n - 1, 1)
	while _gcd(stride, n) != 1:
		stride += 1
	var start := (roll >> 12) % maxi(n, 1)
	var out: Array = []
	out.resize(n)
	for i in n:
		out[i] = samples[(start + i * stride) % n]
	return out


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return a


func _site(kind: StringName, region: Vector2i, samples: Array, by: Dictionary, taken: Array[Vector2i],
		cols: SpaceDepositSites.Cols = null) -> Dictionary:
	if space != null:   # spec §26.5: the Moon's and Mars's kinds
		return SpaceDepositSites.site(self, kind, region, samples, by, taken, cols)
	for s: Array in _order(samples, region, kind):
		var x: int = s[0]
		var z: int = s[1]
		if not _far_from_spawn(x, z) or not _far_from(taken, x, z):
			continue
		var d := {}
		match kind:
			DepositKinds.GOLD:
				d = _gold(s, by)
			DepositKinds.IRON:
				d = _iron(s, by)
			DepositKinds.COAL:
				d = _coal(s, by)
			DepositKinds.COPPER:
				d = _copper(s, by)
			DepositKinds.OIL:
				d = _oil(s, by, region)
			DepositKinds.SALT:
				d = _salt(s, by)
		if d.is_empty():
			continue
		var box := _bounds(d.raw)
		if _fits(box[0], box[1], d.anchor, region):
			_finish(d, kind, region)
			return d
	return {}


## [lo, hi exclusive] of a deposit's cells.
static func _bounds(raw: Dictionary) -> Array:
	var lo := Vector3i(0x3fffffff, 0x3fffffff, 0x3fffffff)
	var hi := -lo
	for p: Vector3i in raw:
		lo = lo.min(p)
		hi = hi.max(p + Vector3i.ONE)
	return [lo, hi]


## Inside its region's margin, clear of the spawn, GAP from every secret, mouse village and wild-meadows place.
func _fits(lo: Vector3i, hi: Vector3i, a: Vector3i, region: Vector2i) -> bool:
	var r0 := region * REGION
	if lo.x < r0.x + 8 or lo.z < r0.y + 8 or hi.x > r0.x + REGION - 8 or hi.z > r0.y + REGION - 8:
		return false
	if not _far_from_spawn(a.x, a.z):
		return false
	if space != null and space.colony != null and space.colony.near_box(lo, hi, GAP):
		return false   # spec §21c: never on the colony's ground (nor the blend round it)
	if secrets != null:
		var a0 := SecretRules.area_of(lo.x - GAP, lo.z - GAP)
		var a1 := SecretRules.area_of(hi.x + GAP, hi.z + GAP)
		for az in range(a0.y, a1.y + 1):
			for ax in range(a0.x, a1.x + 1):
				var list: Array = secrets.secrets_in_area(Vector2i(ax, az))
				if secrets.tiny != null:
					list = list + secrets.tiny_in_area(Vector2i(ax, az))
				for s: Dictionary in list:
					if _overlaps(lo, hi, s.lo, s.hi):
						return false
	if places != null:
		var mid := Vector3((lo.x + hi.x) * 0.5, 0.0, (lo.z + hi.z) * 0.5)
		for p: Dictionary in places.places_near(mid, 96.0):
			if _overlaps(lo, hi, p.lo, p.hi):
				return false
	return true


static func _overlaps(lo: Vector3i, hi: Vector3i, slo: Vector3i, shi: Vector3i) -> bool:
	return lo.x - GAP < shi.x and slo.x < hi.x + GAP and lo.z - GAP < shi.z and slo.z < hi.z + GAP \
		and lo.y - GAP < shi.y and slo.y < hi.y + GAP


## Packs a deposit's cells by chunk and works out its bounds, id and ore count.
func _finish(d: Dictionary, kind: StringName, region: Vector2i) -> void:
	d.id = "%s:%d:%d" % [kind, region.x, region.y]
	d.kind = kind
	d.region = region
	var raw: Dictionary = d.raw
	var cells := {}
	var lo := Vector3i(0x3fffffff, 0x3fffffff, 0x3fffffff)
	var hi := -lo
	var ore := int(DepositKinds.data(kind).get("ore", BlockIds.AIR))
	var count := 0
	for p: Vector3i in raw:
		var key := chunk_key(p)
		var packed: PackedInt32Array = cells.get(key, PackedInt32Array())
		packed.append_array([p.x, p.y, p.z, int(raw[p])])
		cells[key] = packed
		lo = lo.min(p)
		hi = hi.max(p + Vector3i.ONE)
		if absi(int(raw[p])) == ore and ore != BlockIds.AIR:
			count += 1
	d.erase("raw")
	d.cells = cells
	d.lo = lo
	d.hi = hi
	d.count = count


## Every column within `r` of (cx, cz), each (x, z) once, rounded by a wobble of the seed.
func _blob(cx: int, cz: int, r: float, salt: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var ri := ceili(r) + 1
	for dz in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var ang := atan2(float(dz), float(dx))
			var wob := r * (0.8 + 0.25 * sin(ang * 3.0 + float(salt % 7)))
			if Vector2(dx, dz).length() <= wob:
				out.append(Vector2i(cx + dx, cz + dz))
	return out


## Gold: a water sample with a hill sample beside it. The gravel straddles the water's edge (the bed under the water,
## the top of the low bank); the quartz vein runs level into the hill where its slope rises past the sea by 6.
func _gold(s: Array, by: Dictionary) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	if int(s[2]) >= SEA:
		return {}
	var hill := Vector2i.ZERO
	var best := -1
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 0),
			Vector2i(0, 2), Vector2i(0, -2)]:
		var o: Variant = by.get(Vector2i(x + d.x * STEP, z + d.y * STEP))
		if o != null and int(o[2]) >= SEA + HILL and int(o[2]) > best:
			best = int(o[2])
			hill = Vector2i(o[0], o[1])
	if best < 0:
		return {}
	var water := Vector2(x, z)
	var dir := (Vector2(hill) - water).normalized()
	# The water's edge: the last water column walking from the water sample towards the hill.
	var edge := Vector2i(x, z)
	var steps := int(Vector2(hill).distance_to(water))
	for i in steps:
		var p := water + dir * i
		var c := Vector2i(roundi(p.x), roundi(p.y))
		if _h(c.x, c.y) >= SEA:
			break
		edge = c
	# The vein's outcrop: the first column past the edge whose ground stands 6 over the sea.
	var foot := Vector2i(-1, -1)
	var found := false
	for i in range(1, steps + 8):
		var p := Vector2(edge) + dir * i
		var c := Vector2i(roundi(p.x), roundi(p.y))
		if _h(c.x, c.y) >= SEA + 6:
			foot = c
			found = true
			break
	if not found or Vector2(foot).distance_to(Vector2(edge)) > 40.0:
		return {}
	var raw := {}
	var gravel: Array[Vector3i] = []
	for c in _blob(edge.x, edge.y, 2.6, x ^ z):
		var h := _h(c.x, c.y)
		if h > SEA + 2:
			continue   # only the low bank and the bed
		raw[Vector3i(c.x, h - 1, c.y)] = BlockIds.GOLD_GRAVEL
		raw[Vector3i(c.x, h - 2, c.y)] = BlockIds.GOLD_GRAVEL
		if h >= SEA:
			gravel.append(Vector3i(c.x, h - 1, c.y))
			raw[Vector3i(c.x, h, c.y)] = BlockIds.AIR   # a flower off the gravel
		else:
			gravel.append(Vector3i(c.x, h - 1, c.y))
	var y0 := _h(foot.x, foot.y) - 1
	var side := Vector2(-dir.y, dir.x)
	var vein: Array[Vector3i] = []
	for i in 11:
		for w in range(-1, 2):
			var p := Vector2(foot) + dir * i + side * w
			var c := Vector2i(roundi(p.x), roundi(p.y))
			var top := _h(c.x, c.y) - 1
			for y in range(y0 - VEIN_BELOW, y0 + VEIN_ABOVE):
				raw[Vector3i(c.x, y, c.y)] = BlockIds.GOLD_QUARTZ
			if top >= y0 - VEIN_BELOW and top < y0 + VEIN_ABOVE:
				vein.append(Vector3i(c.x, top, c.y))
	if gravel.is_empty() or vein.is_empty():
		return {}
	return {"anchor": Vector3i(foot.x, y0, foot.y), "spots": [gravel[0], Vector3i(foot.x, y0, foot.y)],
		"signs": [gravel, vein], "raw": raw}


## Iron: a hilltop sample higher than its neighbours, far from water. Rusty rock caps it; the banded iron lens lies
## under the rusty rock.
func _iron(s: Array, by: Dictionary) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	var h: int = s[2]
	if h < SEA + IRON_HILL or int(s[3]) != 0:
		return {}
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var o: Variant = by.get(Vector2i(x + d.x * STEP, z + d.y * STEP))
		if o != null and (int(o[2]) > h or int(o[2]) < SEA + 2):
			return {}
	var raw := {}
	var rust: Array[Vector3i] = []
	for c in _blob(x, z, 4.2, x * 3 + z):
		var top := _h(c.x, c.y)
		if absi(top - h) > 4:
			continue
		raw[Vector3i(c.x, top - 1, c.y)] = BlockIds.RUSTY_ROCK
		raw[Vector3i(c.x, top - 2, c.y)] = BlockIds.RUSTY_ROCK
		raw[Vector3i(c.x, top, c.y)] = BlockIds.AIR
		rust.append(Vector3i(c.x, top - 1, c.y))
	var mid := Vector3i(x, h - 5, z)
	for dy in range(-2, 3):
		for dz in range(-4, 5):
			for dx in range(-4, 5):
				if Vector3(dx / 4.0, dy / 2.0, dz / 4.0).length() <= 1.0:
					var p := mid + Vector3i(dx, dy, dz)
					if not raw.has(p) and p.y < _h(p.x, p.z) - 2:
						raw[p] = BlockIds.BANDED_IRON
	if rust.size() < 12:
		return {}
	return {"anchor": Vector3i(x, h - 1, z), "spots": [Vector3i(x, h - 1, z)], "signs": [rust], "raw": raw}


## Coal: a hillside (the ground rises COAL_RISE over one STEP). The seam lies level just over the foot's ground and
## runs into the hill, so the slope shows it as a black stripe with grey fern shale over it.
func _coal(s: Array, by: Dictionary) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	var h: int = s[2]
	if h < SEA + 3 or int(s[3]) != 0:
		return {}
	var up := Vector2i.ZERO
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var o: Variant = by.get(Vector2i(x + d.x * STEP, z + d.y * STEP))
		if o != null and int(o[2]) - h >= COAL_RISE and int(o[3]) == 0:
			up = d
			break
	if up == Vector2i.ZERO:
		return {}
	# The foot: walking up the slope, the first column 2 over the sample's ground.
	var foot := Vector2i(x, z)
	for i in STEP:
		var c := Vector2i(x, z) + up * i
		if _h(c.x, c.y) >= h + 2:
			foot = c
			break
	var y0 := h + 1
	var side := Vector2i(-up.y, up.x)
	var raw := {}
	var seam: Array[Vector3i] = []
	for i in range(-1, 12):
		for w in range(-3, 4):
			var c := foot + up * i + side * w
			var top := _h(c.x, c.y) - 1
			for y in range(y0, y0 + SEAM):
				raw[Vector3i(c.x, y, c.y)] = BlockIds.COAL
			raw[Vector3i(c.x, y0 + SEAM, c.y)] = BlockIds.FERN_SHALE
			if top >= y0 and top <= y0 + SEAM:
				seam.append(Vector3i(c.x, top, c.y))
	if seam.size() < 6:
		return {}
	var a := foot + up * 2
	return {"anchor": Vector3i(a.x, y0 + 1, a.y), "spots": [Vector3i(foot.x, y0, foot.y)], "signs": [seam], "raw": raw}


## Copper: a mesa sample with open desert beside it. The copper ore lies in the mesa by its edge; malachite stains the
## cliff face and the mesa's top there.
func _copper(s: Array, by: Dictionary) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	if int(s[3]) != DesertShape.MESA:
		return {}
	var out := Vector2i.ZERO
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var o: Variant = by.get(Vector2i(x + d.x * STEP, z + d.y * STEP))
		if o != null and int(o[3]) == DesertShape.DESERT:
			out = d
			break
	if out == Vector2i.ZERO:
		return {}
	# The cliff's foot: walking out of the mesa, the last mesa column.
	var edge := Vector2i(x, z)
	for i in STEP + 1:
		var c := Vector2i(x, z) + out * i
		if (shape as DesertShape).terrain_at(c.x, c.y) != DesertShape.MESA:
			break
		edge = c
	var floor_y := (shape as DesertShape).floor_at(edge.x, edge.y)
	var raw := {}
	var mid := Vector3i(edge.x - out.x * 4, floor_y + 4, edge.y - out.y * 4)
	for dy in range(-3, 4):
		for dz in range(-4, 5):
			for dx in range(-4, 5):
				if Vector3(dx / 4.0, dy / 3.0, dz / 4.0).length() <= 1.0:
					raw[mid + Vector3i(dx, dy, dz)] = BlockIds.COPPER_ORE
	var green: Array[Vector3i] = []
	var side := Vector2i(-out.y, out.x)
	for w in range(-5, 6):
		for i in range(0, 5):
			var c := edge - out * i + side * w
			if (shape as DesertShape).terrain_at(c.x, c.y) != DesertShape.MESA:
				continue
			var top := _h(c.x, c.y) - 1
			for y in range(floor_y + 1, top + 1):
				if (_roll(Vector2i(c.x, c.y), DepositKinds.COPPER, y) % 100) < 55 or y == top:
					raw[Vector3i(c.x, y, c.y)] = BlockIds.MALACHITE
			green.append(Vector3i(c.x, top, c.y))
	if green.size() < 10:
		return {}
	return {"anchor": Vector3i(edge.x, _h(edge.x, edge.y) - 1, edge.y),
		"spots": [Vector3i(edge.x + out.x * 2, floor_y, edge.y + out.y * 2)], "signs": [green], "raw": raw}


## Oil: open desert with low dunes and no mesa or oasis near. The well stands on the dome's top (the anchor); the
## seep is a patch of dark sand on its flank, six to eight blocks away.
func _oil(s: Array, by: Dictionary, region: Vector2i) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	if int(s[3]) != DesertShape.DESERT or int(s[2]) - int(s[4]) > 2:
		return {}
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1)]:
		var o: Variant = by.get(Vector2i(x + d.x * STEP, z + d.y * STEP))
		if o != null and int(o[3]) != DesertShape.DESERT:
			return {}
	var roll := _roll(region, DepositKinds.OIL, 7)
	var ang := float(roll % 360) * PI / 180.0
	var seep := Vector2i(x + roundi(cos(ang) * 7.0), z + roundi(sin(ang) * 7.0))
	var raw := {}
	var dark: Array[Vector3i] = []
	var h0 := _h(seep.x, seep.y)
	for c in _blob(seep.x, seep.y, 2.6, roll):
		var col := (shape as DesertShape).column(c.x, c.y)
		if col.y != DesertShape.DESERT or absi(col.x - h0) > 1:
			continue
		raw[Vector3i(c.x, col.x - 1, c.y)] = BlockIds.OIL_SEEP
		raw[Vector3i(c.x, col.x - 2, c.y)] = BlockIds.OIL_SEEP
		raw[Vector3i(c.x, col.x, c.y)] = BlockIds.AIR   # nothing grows in the oily sand
		raw[Vector3i(c.x, col.x + 1, c.y)] = BlockIds.AIR
		dark.append(Vector3i(c.x, col.x - 1, c.y))
	# Room for the derrick and the pump jack: no cactus on the well's square.
	var hw := _h(x, z)
	for dz in range(-4, 5):
		for dx in range(-4, 8):   # the derrick, and the pump jack beside it (OilWell.JACK_AT)
			for y in range(hw - 1, hw + 5):
				var p := Vector3i(x + dx, y, z + dz)
				if not raw.has(p):
					raw[p] = BlockIds.AIR
	if dark.size() < 8:
		return {}
	return {"anchor": Vector3i(x, hw - 1, z), "spots": [Vector3i(seep.x, h0 - 1, seep.y), Vector3i(x, hw - 1, z)],
		"signs": [dark, []], "raw": raw,
		"depth_m": OIL_DEPTHS[roll % OIL_DEPTHS.size()], "drums": OIL_DRUMS}


## Salt: level desert floor (no dune) round a sample. The crust covers the level columns of an oval; rock salt lies
## three deep under it; cacti and dry bushes go.
func _salt(s: Array, by: Dictionary) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	var h: int = s[2]
	if int(s[3]) != DesertShape.DESERT or h - int(s[4]) > 0:
		return {}
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var o: Variant = by.get(Vector2i(x + d.x * STEP, z + d.y * STEP))
		if o == null or int(o[3]) != DesertShape.DESERT or absi(int(o[2]) - h) > 2:
			return {}
	var raw := {}
	var crust: Array[Vector3i] = []
	for c in _blob(x, z, 10.0, x - z):
		var col := (shape as DesertShape).column(c.x, c.y)
		if col.y != DesertShape.DESERT or absi(col.x - h) > 1 or col.x - col.z > 1:
			continue
		raw[Vector3i(c.x, col.x - 1, c.y)] = BlockIds.SALT_CRUST
		for y in range(col.x - 1 - SALT_LAYERS, col.x - 1):
			raw[Vector3i(c.x, y, c.y)] = BlockIds.ROCK_SALT
		for y in range(col.x, col.x + 4):
			raw[Vector3i(c.x, y, c.y)] = BlockIds.AIR
		crust.append(Vector3i(c.x, col.x - 1, c.y))
	if crust.size() < 120:
		return {}
	return {"anchor": Vector3i(x, h - 1, z), "spots": [Vector3i(x, h - 1, z)], "signs": [crust], "raw": raw}
