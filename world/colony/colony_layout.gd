class_name ColonyLayout
extends RefCounted
## A colony under domes on the Moon or Mars (owner #77, spec §21c.2) as pure rules: where it stands and every block of
## it, as boxes the terrain generator writes into its chunks (like the planets' landmarks: SpaceSecretRules), read-only
## after construction (the generator's threads share it).
## Where: DISTANCE from the landing pad, the Moon's on the side away from its landmark, Mars's north or south of the pad
## so its ice mine faces an ice cap (SpaceShape decides which places are calm). The ground is flat at the landing pad's
## height within R_FLAT of its middle and blends back into the planet's own over BLEND (SpaceShape.ground_at).
## What, in the colony's own frame (a: toward the pad, b: across; `dir`, `side`): the Great Dome (glass, GREAT_R, 21
## across: grass, a greenhouse garden in rows under pink grow lamps, a pond four deep, two fruit trees, flowers, warm
## lights), the airlock in front (two striped doors in a row, open: pretend), five smaller domes joined by glass tunnels
## (the homes under a shield of printed regolith with windows, the lab with two Lab Benches and samples, the water plant
## melting the planet's ice into tanks, the oxygen maker, the control room with screens and a big map), and outside the
## solar panel field, the big rocket on its own pad, the rover garage with a rover, and the ice mine (a pit in terraces
## one block each, ice in its floor and walls; the Moon's a crater with a rim) with its drill. Every doorway is open;
## every step is one block; the colony is always lit. Painted in order: a later box wins (block_at, write).

const CH := VoxelBuffer.CHANNEL_TYPE
const CHUNK := 16
const STRIDE := 7                 # ints per box: lo x y z, hi x y z (exclusive), id

const DISTANCE := 40              # the Great Dome's middle from the landing pad's
const R_FLAT := 44                # flat ground this far round the middle ...
const BLEND := 12                 # ... blending back into the planet's own over this
const GREAT_R := 10
const SMALL_R := 5
## The smaller domes' middles (a, b).
const DOMES := {
	ColonyRules.HOMES: Vector2i(0, -18), ColonyRules.LAB: Vector2i(0, 18), ColonyRules.CONTROL: Vector2i(-18, 0),
	ColonyRules.WATER: Vector2i(-18, -18), ColonyRules.OXYGEN: Vector2i(-18, 18),
}
## The glass tunnels: [from, to] (along a straight line of a or b).
const TUNNELS := [[ColonyRules.DOME, ColonyRules.HOMES], [ColonyRules.DOME, ColonyRules.LAB],
	[ColonyRules.DOME, ColonyRules.CONTROL], [ColonyRules.CONTROL, ColonyRules.WATER], [ColonyRules.CONTROL, ColonyRules.OXYGEN]]
const AIRLOCK := Vector2i(9, 15)  # the airlock runs along a from its first to its last
const DOORS: Array[int] = [11, 14]   # its two doors' frames
const PATH_END := 22              # a floor path from the airlock toward the pad
const ROWS: Array[int] = [-7, -5, -3]   # the garden's rows (a), b from 2 to 5 each side of the middle path
const GARDEN_A := Vector2i(-8, -2)
const POND := Vector2i(4, 4)
const POND_R := 3.5
const POND_DEEP := 4              # fish need room: in a pond two deep they bump its walls every step (costly frames)
const TREES: Array[Vector2i] = [Vector2i(4, -4), Vector2i(2, -6)]
const FLOWERS: Array[Vector2i] = [Vector2i(7, -3), Vector2i(6, -6), Vector2i(2, -3), Vector2i(1, 8), Vector2i(7, 6),
	Vector2i(-1, 8), Vector2i(8, 3)]
const SOLAR_A := Vector2i(-10, 10)
const SOLAR_ROWS: Array[int] = [28, 31, 34, 37]
const SOLAR_RECT := [Vector2i(-11, 26), Vector2i(11, 38)]
const GARAGE_LO := Vector2i(0, -34)
const GARAGE_HI := Vector2i(8, -26)
const ROCKET := Vector2i(-33, 15)
const PAD_R := 6
const ROCKET_TOP := 30            # the light on its tip, over the ground
const MINE := Vector2i(-33, -11)
const MINE_R := 6
## The Great Dome's animals stand here (a, b) on the grass; fish swim in the pond.
const LAND_SPOTS: Array[Vector2i] = [Vector2i(-2, 3), Vector2i(7, -1), Vector2i(6, -3), Vector2i(-1, 6), Vector2i(-1, -4),
	Vector2i(0, 7), Vector2i(8, 1), Vector2i(1, -8)]
const FISH_SPOTS: Array[Vector2i] = [Vector2i(4, 4), Vector2i(3, 5), Vector2i(5, 3)]

var planet: StringName
## The Great Dome's middle (x, z).
var centre := Vector2i.ZERO
## Toward the landing pad, along x or z; `side` is a quarter turn from it.
var dir := Vector2i(1, 0)
var side := Vector2i(0, 1)
## The flat ground's height (the first empty y: the landing pad's).
var ground := 0

var _boxes := PackedInt32Array()
var _index := {}                  # Vector3i chunk -> PackedInt32Array of box numbers (ascending)
var _lo := Vector3i.ZERO
var _hi := Vector3i.ZERO


func _init(which: StringName, middle: Vector2i, toward_pad: Vector2i, flat_y: int) -> void:
	planet = which
	centre = middle
	dir = toward_pad
	side = Vector2i(-dir.y, dir.x)
	ground = flat_y
	_build()
	_make_index()


# --- Where it stands -------------------------------------------------------------------------------------------------

## The colony of a Moon's or Mars's shape (null on the other planets): the first calm place among candidates(),
## `calm(middle: Vector2i) -> bool` (SpaceShape's), else the first.
static func place(which: StringName, world_seed: int, spawn: Vector2i, flat_y: int, calm: Callable) -> ColonyLayout:
	if not ColonyRules.has_colony(which):
		return null
	var list := candidates(which, world_seed, spawn)
	var at: Vector2i = list[0]
	for c in list:
		if calm.call(c):
			at = c
			break
	return ColonyLayout.new(which, at, frame(at, spawn), flat_y)


## Where the Great Dome's middle may go, best first: DISTANCE from the pad in 16 directions, the Moon's nearest the
## opposite of its landmark first (the landmark's first try: SpaceSecretRules._make_landmark), Mars's due north, then due
## south of the pad first (its mine then faces an ice cap), then the rest.
static func candidates(which: StringName, world_seed: int, spawn: Vector2i) -> Array[Vector2i]:
	var away := landmark_angle(world_seed, spawn) + PI
	var steps: Array[int] = []   # sixteenths of a turn (x east, z south: 4 is south, 12 north)
	for k in 16:
		steps.append(k)
	steps.sort_custom(func(a: int, b: int) -> bool:
		return absf(angle_difference(a * TAU / 16.0, away)) < absf(angle_difference(b * TAU / 16.0, away)))
	if which == SpaceShape.MARS:
		steps.erase(12)
		steps.erase(4)
		steps.push_front(4)
		steps.push_front(12)
	var out: Array[Vector2i] = []
	for k in steps:
		var a := k * TAU / 16.0
		var c := spawn + Vector2i(roundi(cos(a) * DISTANCE), roundi(sin(a) * DISTANCE))
		if not out.has(c):
			out.append(c)
	return out


## The angle the planet's landmark tries first round the pad (SpaceSecretRules._make_landmark: SecretRules._mix).
static func landmark_angle(world_seed: int, spawn: Vector2i) -> float:
	var h := absi(_mix(world_seed, spawn.x + 101, spawn.y - 77))
	return float(h % 3600) / 3600.0 * TAU


static func _mix(world_seed: int, x: int, z: int) -> int:
	var h := x * 668265263 ^ z * 374761393 ^ world_seed * 2246822519 ^ 0x27d4eb2f
	h = (h ^ (h >> 15)) * 2654435761
	return (h ^ (h >> 13)) & 0x7fffffffffffffff


## The axis from `middle` toward the pad.
static func frame(middle: Vector2i, spawn: Vector2i) -> Vector2i:
	var to := spawn - middle
	return Vector2i(signi(to.x), 0) if absi(to.x) >= absi(to.y) else Vector2i(0, signi(to.y))


# --- The ground ------------------------------------------------------------------------------------------------------

## The ground `raw` at (x, z) after the colony's flattening.
func flatten(x: int, z: int, raw: int) -> int:
	var d2 := (x - centre.x) * (x - centre.x) + (z - centre.y) * (z - centre.y)
	if d2 > (R_FLAT + BLEND) * (R_FLAT + BLEND):
		return raw
	if d2 <= R_FLAT * R_FLAT:
		return ground
	var k := smoothstep(float(R_FLAT), float(R_FLAT + BLEND), sqrt(float(d2)))
	return roundi(lerpf(float(ground), float(raw), k))


## (x, z) within the flat ground and `margin` more.
func covers(x: int, z: int, margin: int = 0) -> bool:
	var r := R_FLAT + margin
	return (x - centre.x) * (x - centre.x) + (z - centre.y) * (z - centre.y) <= r * r


## A box [lo, hi) of the world comes within `margin` of the flattened ground (the flat and its blend).
func near_box(lo: Vector3i, hi: Vector3i, margin: int) -> bool:
	var p := Vector2(clampi(centre.x, lo.x, hi.x - 1), clampi(centre.y, lo.z, hi.z - 1))
	return p.distance_to(Vector2(centre)) <= R_FLAT + BLEND + margin


# --- Frames, parts, places -------------------------------------------------------------------------------------------

## The world column (x, z) of the colony's (a, b).
func world(a: int, b: int) -> Vector2i:
	return centre + dir * a + side * b


## The colony's (a, b) of world column (x, z).
func local(x: int, z: int) -> Vector2i:
	var d := Vector2i(x, z) - centre
	return Vector2i(d.x * dir.x + d.y * dir.y, d.x * side.x + d.y * side.y)


## The airlock's outside door (world x, z), where MY MAP puts the colony.
func entrance() -> Vector2i:
	return world(AIRLOCK.y + 1, 0)


## The part a child standing at (x, z) is in (ColonyRules' ids), &"" for none (a tunnel, the ground between).
func part_at(x: int, z: int) -> StringName:
	var l := local(x, z)
	if l.x >= AIRLOCK.x and l.x <= AIRLOCK.y and absi(l.y) <= 2:
		return ColonyRules.AIRLOCK
	if Vector2(l).length() <= GREAT_R - 0.5:
		return ColonyRules.GARDEN if l.x >= GARDEN_A.x and l.x <= GARDEN_A.y else ColonyRules.DOME
	for part: StringName in DOMES:
		if Vector2(l - (DOMES[part] as Vector2i)).length() <= SMALL_R - 0.5:
			return part
	var sl: Vector2i = SOLAR_RECT[0]
	var sh: Vector2i = SOLAR_RECT[1]
	if l.x >= sl.x and l.x <= sh.x and l.y >= sl.y and l.y <= sh.y:
		return ColonyRules.SOLAR
	if l.x >= GARAGE_LO.x and l.x <= GARAGE_HI.x and l.y >= GARAGE_LO.y and l.y <= GARAGE_HI.y:
		return ColonyRules.GARAGE
	if Vector2(l - ROCKET).length() <= PAD_R + 0.5:
		return ColonyRules.ROCKET
	if Vector2(l - MINE).length() <= MINE_R + 1.5:
		return ColonyRules.MINE
	return &""


## A column a child can stand in inside each part (world x, z): the smoke run and the tests walk there.
func part_centre(part: StringName) -> Vector2i:
	match part:
		ColonyRules.DOME:
			return world(0, 0)
		ColonyRules.GARDEN:
			return world(-6, 3)
		ColonyRules.AIRLOCK:
			return world(12, 0)
		ColonyRules.SOLAR:
			return world(0, 29)
		ColonyRules.ROCKET:
			return world(ROCKET.x, ROCKET.y + 5)
		ColonyRules.GARAGE:
			return world(7, -30)
		ColonyRules.MINE:
			return world(MINE.x, MINE.y)
	var d: Vector2i = DOMES.get(part, Vector2i.ZERO)
	return world(d.x, d.y)


## (x, z) is under the Great Dome, clear of its glass (the animals' home).
func in_great_dome(x: int, z: int) -> bool:
	return Vector2(local(x, z)).length() <= GREAT_R - 1.5


## The Great Dome's middle on its floor.
func great_middle() -> Vector3:
	return Vector3(centre.x + 0.5, ground, centre.y + 0.5)


## Where the Great Dome's animals stand: [{species, pos (feet, world)}] for ColonyRules.HERD, land animals on the grass,
## fish in the pond.
func animal_spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var land := 0
	var fish := 0
	for e: Dictionary in ColonyRules.HERD:
		for i in int(e.count):
			var at: Vector2i
			var y := ground
			if e.species == &"fish":
				at = FISH_SPOTS[fish % FISH_SPOTS.size()]
				fish += 1
				y = ground - 2
			else:
				at = LAND_SPOTS[land % LAND_SPOTS.size()]
				land += 1
			var w := world(at.x, at.y)
			out.append({"species": e.species, "pos": Vector3(w.x + 0.5, y, w.y + 0.5), "slot": out.size()})
	return out


## The highest y any of the colony's blocks reaches, plus one.
func top() -> int:
	return _hi.y


# --- The blocks ------------------------------------------------------------------------------------------------------

## The block the colony puts at p, or -1 where it puts nothing (the generator's reference; later boxes win).
func block_at(p: Vector3i) -> int:
	var list: Variant = _index.get(Vector3i(floori(p.x / float(CHUNK)), floori(p.y / float(CHUNK)), floori(p.z / float(CHUNK))))
	if list == null:
		return -1
	var ids: PackedInt32Array = list
	for j in range(ids.size() - 1, -1, -1):
		var k := ids[j] * STRIDE
		if p.x >= _boxes[k] and p.y >= _boxes[k + 1] and p.z >= _boxes[k + 2] and p.x < _boxes[k + 3] \
				and p.y < _boxes[k + 4] and p.z < _boxes[k + 5]:
			return _boxes[k + 6]
	return -1


## Writes the colony's boxes that reach into the buffer (the generator's fast path; equal to block_at).
func write(buf: VoxelBuffer, origin: Vector3i) -> void:
	var end := origin + buf.get_size()
	if end.x <= _lo.x or end.y <= _lo.y or end.z <= _lo.z or origin.x >= _hi.x or origin.y >= _hi.y or origin.z >= _hi.z:
		return
	var c0 := Vector3i(floori(origin.x / float(CHUNK)), floori(origin.y / float(CHUNK)), floori(origin.z / float(CHUNK)))
	var c1 := Vector3i(floori((end.x - 1) / float(CHUNK)), floori((end.y - 1) / float(CHUNK)), floori((end.z - 1) / float(CHUNK)))
	var ids := PackedInt32Array()
	if c0 == c1:
		var one: Variant = _index.get(c0)
		if one == null:
			return
		ids = one
	else:   # a buffer over several chunks: every box once, in painting order
		var seen := {}
		for cz in range(c0.z, c1.z + 1):
			for cy in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					var l: Variant = _index.get(Vector3i(cx, cy, cz))
					if l != null:
						for i: int in (l as PackedInt32Array):
							seen[i] = true
		ids = PackedInt32Array(seen.keys())
		ids.sort()
	for i in ids:
		var k := i * STRIDE
		var bl := Vector3i(maxi(_boxes[k], origin.x), maxi(_boxes[k + 1], origin.y), maxi(_boxes[k + 2], origin.z)) - origin
		var bh := Vector3i(mini(_boxes[k + 3], end.x), mini(_boxes[k + 4], end.y), mini(_boxes[k + 5], end.z)) - origin
		if bl.x < bh.x and bl.y < bh.y and bl.z < bh.z:
			buf.fill_area(_boxes[k + 6], bl, bh, CH)


## How many boxes the colony is painted with (the bench's and the notes' number).
func box_count() -> int:
	return _boxes.size() / STRIDE


func _make_index() -> void:
	_lo = Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
	_hi = -_lo
	for i in box_count():
		var k := i * STRIDE
		var lo := Vector3i(_boxes[k], _boxes[k + 1], _boxes[k + 2])
		var hi := Vector3i(_boxes[k + 3], _boxes[k + 4], _boxes[k + 5])
		_lo = _lo.min(lo)
		_hi = _hi.max(hi)
		for cz in range(floori(lo.z / float(CHUNK)), floori((hi.z - 1) / float(CHUNK)) + 1):
			for cy in range(floori(lo.y / float(CHUNK)), floori((hi.y - 1) / float(CHUNK)) + 1):
				for cx in range(floori(lo.x / float(CHUNK)), floori((hi.x - 1) / float(CHUNK)) + 1):
					var key := Vector3i(cx, cy, cz)
					var l: PackedInt32Array = _index.get(key, PackedInt32Array())
					l.append(i)
					_index[key] = l


# --- Painting (the colony's frame: a toward the pad, b across; dy over the ground) ---------------------------------------

## A box between two corners (a, b, dy), inclusive, of block `id`.
func _box(a0: int, b0: int, dy0: int, a1: int, b1: int, dy1: int, id: int) -> void:
	var p := world(a0, b0)
	var q := world(a1, b1)
	_boxes.append_array([mini(p.x, q.x), ground + mini(dy0, dy1), mini(p.y, q.y),
		maxi(p.x, q.x) + 1, ground + maxi(dy0, dy1) + 1, maxi(p.y, q.y) + 1, id])


func _cell(a: int, b: int, dy: int, id: int) -> void:
	_box(a, b, dy, a, b, dy, id)


## A flat disc of radius r round (a, b), from dy0 to dy1 (rows along b).
func _disc(c: Vector2i, r: float, dy0: int, dy1: int, id: int) -> void:
	var n := ceili(r)
	for da in range(-n, n + 1):
		var rest := r * r - da * da
		if rest < 0.0:
			continue
		var hw := int(sqrt(rest))
		_box(c.x + da, c.y - hw, dy0, c.x + da, c.y + hw, dy1, id)


## The rows dy0..dy1 of a half ball of radius r standing on the ground round (a, b) (the Moon Base's way).
func _dome(c: Vector2i, r: int, dy0: int, dy1: int, id: int) -> void:
	for dy in range(dy0, dy1 + 1):
		for da in range(-r, r + 1):
			var rest := (r + 0.5) * (r + 0.5) - dy * dy - da * da
			if rest < 0.0:
				continue
			var hw := int(sqrt(rest))
			_box(c.x + da, c.y - hw, dy, c.x + da, c.y + hw, dy, id)


## A ball of radius r round (a, b, dy).
func _ball(c: Vector2i, dyc: int, r: int, id: int) -> void:
	for dy in range(-r, r + 1):
		for da in range(-r, r + 1):
			var rest := (r + 0.5) * (r + 0.5) - dy * dy - da * da
			if rest < 0.0:
				continue
			var hw := int(sqrt(rest))
			_box(c.x + da, c.y - hw, dyc + dy, c.x + da, c.y + hw, dyc + dy, id)


func _build() -> void:
	var great := Vector2i.ZERO
	# 1. The floors (the ground's top, dy -1).
	_disc(great, GREAT_R + 0.5, -1, -1, BlockIds.COLONY_PANEL)
	_disc(great, GREAT_R - 0.5, -1, -1, BlockIds.GRASS)
	for part: StringName in DOMES:
		_disc(DOMES[part], SMALL_R + 0.5, -1, -1, BlockIds.COLONY_PANEL)
		_disc(DOMES[part], SMALL_R - 0.5, -1, -1, BlockIds.COLONY_FLOOR)
	_box(AIRLOCK.x, -2, -1, AIRLOCK.y, 2, -1, BlockIds.COLONY_FLOOR)
	_box(AIRLOCK.y + 1, -1, -1, PATH_END, 1, -1, BlockIds.COLONY_FLOOR)
	_box(GARAGE_LO.x, GARAGE_LO.y, -1, GARAGE_HI.x, GARAGE_HI.y, -1, BlockIds.COLONY_FLOOR)
	_disc(ROCKET, PAD_R + 0.5, -1, -1, BlockIds.PAD_STRIPE)
	_disc(ROCKET, PAD_R - 0.5, -1, -1, BlockIds.PAD_CONCRETE)
	# 2. The ice mine: a pit in terraces of one block, the planet's ice in its floor and walls (under the ground).
	_mine()
	# 3. The domes' shells: a white base ring, then glass (the homes: printed regolith, a shield from the Sun's rays).
	_dome(great, GREAT_R, 0, 1, BlockIds.COLONY_PANEL)
	_dome(great, GREAT_R, 2, GREAT_R, BlockIds.DOME_GLASS)
	for part: StringName in DOMES:
		_dome(DOMES[part], SMALL_R, 0, 1, BlockIds.COLONY_PANEL)
		_dome(DOMES[part], SMALL_R, 2, SMALL_R, BlockIds.PRINTED_REGOLITH if part == ColonyRules.HOMES else BlockIds.DOME_GLASS)
	# 4. Room inside them.
	_dome(great, GREAT_R - 1, 0, GREAT_R - 1, BlockIds.AIR)
	for part: StringName in DOMES:
		_dome(DOMES[part], SMALL_R - 1, 0, SMALL_R - 1, BlockIds.AIR)
	# 5. The glass tunnels and the airlock (their doorways cut through the shells).
	for t: Array in TUNNELS:
		_tunnel(t[0], t[1])
	_airlock()
	# 6. What is inside.
	_great_dome()
	_homes()
	_lab()
	_water_plant()
	_oxygen_maker()
	_control_room()
	# 7. Outside.
	_solar_field()
	_garage()
	_rocket()
	_drill()


## The middle and radius of a dome (the Great Dome's or a smaller one's).
func _dome_of(part: StringName) -> Array:
	if part == ColonyRules.DOME:
		return [Vector2i.ZERO, GREAT_R]
	return [DOMES[part], SMALL_R]


## A glass tunnel between two domes on one line: a floor, glass walls and roof with white ribs, room 3 wide and 3 tall,
## its doorways cut through both shells.
func _tunnel(from: StringName, to: StringName) -> void:
	var p: Array = _dome_of(from)
	var q: Array = _dome_of(to)
	var pc: Vector2i = p[0]
	var qc: Vector2i = q[0]
	var along := Vector2i(signi(qc.x - pc.x), signi(qc.y - pc.y))
	var across := Vector2i(-along.y, along.x)
	var length := absi(qc.x - pc.x) + absi(qc.y - pc.y)
	var s0: int = p[1]
	var s1: int = length - int(q[1])
	for s in range(s0, s1 + 1):
		var m := pc + along * s
		var l := m - across * 2
		var r := m + across * 2
		var rib := (s - s0) % 3 == 0
		_box(l.x, l.y, -1, r.x, r.y, -1, BlockIds.COLONY_FLOOR)
		_box(l.x, l.y, 0, l.x, l.y, 2, BlockIds.COLONY_PANEL if rib else BlockIds.DOME_GLASS)
		_box(r.x, r.y, 0, r.x, r.y, 2, BlockIds.COLONY_PANEL if rib else BlockIds.DOME_GLASS)
		_box(l.x, l.y, 3, r.x, r.y, 3, BlockIds.COLONY_PANEL if rib else BlockIds.DOME_GLASS)
	var a := pc + along * (s0 - 1) - across
	var b := pc + along * (s1 + 1) + across
	_box(a.x, a.y, 0, b.x, b.y, 2, BlockIds.AIR)


## The airlock: a white chamber in front of the Great Dome with two striped doors in a row, both open (pretend: a real
## one keeps one shut), a light in its roof, and a floor path on toward the pad.
func _airlock() -> void:
	_box(GREAT_R, -2, 0, AIRLOCK.y, -2, 2, BlockIds.COLONY_PANEL)
	_box(GREAT_R, 2, 0, AIRLOCK.y, 2, 2, BlockIds.COLONY_PANEL)
	_box(GREAT_R, -2, 3, AIRLOCK.y, 2, 3, BlockIds.COLONY_PANEL)
	for a in DOORS:
		_box(a, -2, 0, a, -2, 3, BlockIds.AIRLOCK_FRAME)
		_box(a, 2, 0, a, 2, 3, BlockIds.AIRLOCK_FRAME)
		_box(a, -2, 3, a, 2, 3, BlockIds.AIRLOCK_FRAME)
	_box(DOORS[0] + 1, 0, 3, DOORS[1] - 1, 0, 3, BlockIds.COLONY_LIGHT)
	_box(AIRLOCK.x, -1, 0, AIRLOCK.y, 1, 2, BlockIds.AIR)


## Under the Great Dome: grass, the greenhouse garden (rows of soil with wheat, berry bushes, pumpkins and flowers under
## bars of pink grow lamps on white posts; a floor path down the middle), the pond four deep (fish swim in it), two
## fruit trees, flowers, warm lights under the top and round the base.
func _great_dome() -> void:
	_box(GARDEN_A.x - 1, -1, -1, -1, 1, -1, BlockIds.COLONY_FLOOR)   # the path from the back door to the middle
	for a in ROWS:
		for s: int in [-1, 1]:
			_box(a, 2 * s, -1, a, 5 * s, -1, BlockIds.GREENHOUSE_SOIL)
			for b in range(2, 5):
				var crop := BlockIds.WHEAT
				if a == ROWS[1]:
					crop = BlockIds.BUSH
				elif a == ROWS[2]:
					crop = BlockIds.PUMPKIN if b % 2 == 0 else BlockIds.FLOWERS
				_cell(a, b * s, 0, crop)
			_box(a, 5 * s, 0, a, 5 * s, 2, BlockIds.COLONY_PANEL)   # the lamp's post at the row's end
			_box(a, 2 * s, 3, a, 5 * s, 3, BlockIds.GROW_LAMP)
	_disc(POND, POND_R + 0.9, -POND_DEEP - 1, -POND_DEEP - 1, BlockIds.SAND)
	_disc(POND, POND_R, -POND_DEEP, -1, BlockIds.WATER)   # no lily pads: fish nosing under one cost frames (the notes)
	for t in TREES:
		_ball(t, 4, 2, BlockIds.FRUIT_LEAVES)
		_box(t.x, t.y, 0, t.x, t.y, 3, BlockIds.LOG)
	for f in FLOWERS:
		_cell(f.x, f.y, 0, BlockIds.FLOWERS)
	_cell(0, 0, GREAT_R - 1, BlockIds.COLONY_LIGHT)
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		_cell(d.x, d.y, GREAT_R - 1, BlockIds.COLONY_LIGHT)
	for d: Vector2i in [Vector2i(7, 7), Vector2i(7, -7), Vector2i(-7, 7), Vector2i(-7, -7)]:
		_cell(d.x, d.y, 1, BlockIds.COLONY_LIGHT)


## A smaller dome's warm light under its top and two on its far wall (`far`: the side away from its door).
func _small_lights(c: Vector2i, far: Vector2i) -> void:
	_cell(c.x, c.y, SMALL_R - 1, BlockIds.COLONY_LIGHT)
	var across := Vector2i(-far.y, far.x)
	for s: int in [-1, 1]:
		var at := c + far * 3 + across * 4 * s
		_cell(at.x, at.y, 1, BlockIds.COLONY_LIGHT)


## The homes (their door toward the Great Dome): three beds along the far wall, a table, a bookshelf, windows in the
## printed regolith shield.
func _homes() -> void:
	var c: Vector2i = DOMES[ColonyRules.HOMES]
	for u in [-2, 0, 2]:
		_cell(c.x + u, c.y - 3, 0, BlockIds.BED)
	_box(c.x + 2, c.y, 0, c.x + 2, c.y + 1, 0, BlockIds.COLONY_TABLE)
	_cell(c.x - 3, c.y, 0, BlockIds.BOOKSHELF)
	for w: Vector2i in [Vector2i(5, 0), Vector2i(-5, 0), Vector2i(0, -5), Vector2i(3, -4), Vector2i(-3, -4)]:
		_cell(c.x + w.x, c.y + w.y, 2, BlockIds.DOME_GLASS)
	_small_lights(c, Vector2i(0, -1))


## The lab (its door toward the Great Dome): two Lab Benches (the Science Lab opens there), a screen, the planet's rock
## and crystal as samples on tables.
func _lab() -> void:
	var c: Vector2i = DOMES[ColonyRules.LAB]
	_cell(c.x - 1, c.y + 3, 0, BlockIds.LAB_BENCH)
	_cell(c.x + 1, c.y + 3, 0, BlockIds.LAB_BENCH)
	_cell(c.x, c.y + 4, 0, BlockIds.COLONY_TABLE)
	_cell(c.x, c.y + 4, 1, BlockIds.CONTROL_SCREEN)
	_cell(c.x + 3, c.y + 1, 0, BlockIds.COLONY_TABLE)
	_cell(c.x + 3, c.y + 1, 1, ColonyRules.block(planet, "rock"))
	_cell(c.x - 3, c.y + 1, 0, BlockIds.COLONY_TABLE)
	_cell(c.x - 3, c.y + 1, 1, ColonyRules.block(planet, "crystal"))
	_small_lights(c, Vector2i(0, 1))


## The water plant (its door toward the control room): ice melters with the planet's ice on top, tanks of water.
func _water_plant() -> void:
	var c: Vector2i = DOMES[ColonyRules.WATER]
	_box(c.x - 1, c.y - 3, 0, c.x + 1, c.y - 3, 0, BlockIds.ICE_MELTER)
	_box(c.x - 1, c.y - 3, 1, c.x + 1, c.y - 3, 1, ColonyRules.block(planet, "ice"))
	for u: int in [-3, 3]:
		_box(c.x + u, c.y - 1, 0, c.x + u, c.y + 1, 1, BlockIds.WATER_TANK)
	_small_lights(c, Vector2i(0, -1))


## The oxygen maker (its door toward the control room): makers two tall fed by tanks of water.
func _oxygen_maker() -> void:
	var c: Vector2i = DOMES[ColonyRules.OXYGEN]
	_box(c.x - 1, c.y + 3, 0, c.x + 1, c.y + 3, 1, BlockIds.OXYGEN_MAKER)
	for u: int in [-3, 3]:
		_box(c.x + u, c.y + 1, 0, c.x + u, c.y + 1, 1, BlockIds.WATER_TANK)
	_small_lights(c, Vector2i(0, 1))


## The control room (doors to the Great Dome, the water plant and the oxygen maker): the big map (3 x 2) on desks, and
## screens on two more desks.
func _control_room() -> void:
	var c: Vector2i = DOMES[ColonyRules.CONTROL]
	_box(c.x - 3, c.y - 1, 0, c.x - 3, c.y + 1, 0, BlockIds.COLONY_TABLE)
	_box(c.x - 3, c.y - 1, 1, c.x - 3, c.y + 1, 2, BlockIds.COLONY_MAP)
	for v: int in [-3, 3]:
		_cell(c.x - 2, c.y + v, 0, BlockIds.COLONY_TABLE)
		_cell(c.x - 2, c.y + v, 1, BlockIds.CONTROL_SCREEN)
	_cell(c.x, c.y, SMALL_R - 1, BlockIds.COLONY_LIGHT)
	for v: int in [-4, 4]:
		_cell(c.x - 3, c.y + v, 1, BlockIds.COLONY_LIGHT)


## Rows of solar panels on white posts (lanes between them to walk).
func _solar_field() -> void:
	for b in SOLAR_ROWS:
		for a in range(SOLAR_A.x, SOLAR_A.y + 1, 4):
			_cell(a, b, 0, BlockIds.COLONY_PANEL)
		_box(SOLAR_A.x, b, 1, SOLAR_A.y, b, 1, BlockIds.SOLAR_PANEL)


## The rover garage: white walls and roof, open toward the pad under a striped beam, a light, a rover inside facing out.
func _garage() -> void:
	var lo := GARAGE_LO
	var hi := GARAGE_HI
	_box(lo.x, lo.y, 0, lo.x, hi.y, 3, BlockIds.COLONY_PANEL)
	_box(lo.x, lo.y, 0, hi.x, lo.y, 3, BlockIds.COLONY_PANEL)
	_box(lo.x, hi.y, 0, hi.x, hi.y, 3, BlockIds.COLONY_PANEL)
	_box(lo.x, lo.y, 4, hi.x, hi.y, 4, BlockIds.COLONY_PANEL)
	_box(hi.x, lo.y + 1, 3, hi.x, hi.y - 1, 3, BlockIds.AIRLOCK_FRAME)
	var mid := (lo.y + hi.y) / 2
	_cell((lo.x + hi.x) / 2, mid, 4, BlockIds.COLONY_LIGHT)
	for a: int in [2, 6]:
		for b: int in [mid - 2, mid + 2]:
			_cell(a, b, 0, BlockIds.ROVER_WHEEL)
	_box(2, mid - 1, 1, 6, mid + 1, 1, BlockIds.ROVER_PANEL)
	_box(3, mid - 1, 2, 5, mid + 1, 2, BlockIds.SOLAR_PANEL)
	_cell(6, mid, 2, BlockIds.ROVER_PANEL)
	_cell(6, mid, 3, BlockIds.ROVER_LIGHT)


## The big rocket on its own pad (our own design): four legs and four fins, five engines, a round silver body 22 tall
## with two teal bands and the crew's windows, a pointed nose with a light on its tip.
func _rocket() -> void:
	var k := ROCKET
	for d: Vector2i in [Vector2i(3, 3), Vector2i(3, -3), Vector2i(-3, 3), Vector2i(-3, -3)]:
		_box(k.x + d.x, k.y + d.y, 0, k.x + d.x, k.y + d.y, 2, BlockIds.ROCKET_HULL)
		_cell(k.x + d.x - signi(d.x), k.y + d.y - signi(d.y), 3, BlockIds.ROCKET_HULL)
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		_box(k.x + d.x * 3, k.y + d.y * 3, 1, k.x + d.x * 3, k.y + d.y * 3, 6, BlockIds.ROCKET_HULL)
		_box(k.x + d.x * 4, k.y + d.y * 4, 1, k.x + d.x * 4, k.y + d.y * 4, 3, BlockIds.ROCKET_HULL)
		_cell(k.x + d.x, k.y + d.y, 2, BlockIds.ROCKET_ENGINE)
	_cell(k.x, k.y, 2, BlockIds.ROCKET_ENGINE)
	_disc(k, sqrt(5.0), 3, 24, BlockIds.ROCKET_HULL)
	_disc(k, sqrt(5.0), 8, 8, BlockIds.AIRLOCK_FRAME)
	_disc(k, sqrt(5.0), 18, 18, BlockIds.AIRLOCK_FRAME)
	for d: Vector2i in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
		_cell(k.x + d.x, k.y + d.y, 21, BlockIds.DOME_GLASS)
	_disc(k, sqrt(2.0), 25, 26, BlockIds.ROCKET_HULL)
	_disc(k, 1.0, 27, 28, BlockIds.ROCKET_HULL)
	_cell(k.x, k.y, 29, BlockIds.ROCKET_HULL)
	_cell(k.x, k.y, ROCKET_TOP, BlockIds.COLONY_LIGHT)


## The ice mine: a round pit in terraces (1, 2, 3 and 4 deep toward its middle: every step one block), the planet's ice
## in its floor and walls, a rim of dug-out ground (the Moon's crater rim).
func _mine() -> void:
	_disc(MINE, MINE_R + 1.5, 0, 0, ColonyRules.block(planet, "rim"))
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:   # four ways in
		var at := MINE + d * (MINE_R + 1)
		var across := Vector2i(-d.y, d.x)
		_box(at.x - across.x, at.y - across.y, 0, at.x + across.x, at.y + across.y, 0, BlockIds.AIR)
	var ice := ColonyRules.block(planet, "ice")
	for ring: Array in [[MINE_R + 0.5, 1], [4.5, 2], [3.0, 3], [1.5, 4]]:
		var r: float = ring[0]
		var k: int = ring[1]
		_disc(MINE, r, -k - 3, -k - 1, ice)
		_disc(MINE, r, -k, 0, BlockIds.AIR)
	_cell(MINE.x + 2, MINE.y - 2, -3, ColonyRules.block(planet, "glint"))   # a glint of the planet's own crystal


## The mine's drill: a white tower by the pit with a striped cap and a light, an arm over the pit, the drill hanging into
## it; a few blocks of ice waiting to go to the water plant.
func _drill() -> void:
	var t := MINE + Vector2i(0, 8)
	_box(t.x, t.y, 0, t.x, t.y, 4, BlockIds.COLONY_PANEL)
	_cell(t.x, t.y, 5, BlockIds.AIRLOCK_FRAME)
	_cell(t.x, t.y, 6, BlockIds.COLONY_LIGHT)
	_box(t.x, t.y - 1, 5, t.x, MINE.y + 3, 5, BlockIds.COLONY_PANEL)
	_box(MINE.x, MINE.y + 3, -2, MINE.x, MINE.y + 3, 4, BlockIds.ROCKET_HULL)
	_box(MINE.x + 6, MINE.y + 5, 0, MINE.x + 7, MINE.y + 5, 0, ColonyRules.block(planet, "ice"))
