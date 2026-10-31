class_name WondersShape
extends MeadowsShape
## The ground of world 41, Wonders of the World (owner #78, spec §24), as pure rules: Earth's own green land. Round the
## landing spot (WonderTour) a flat park at the tour's ground level out to WonderTour.FLAT_R, so every wonder stands
## level and is seen from far: grass, Giza's sand round the pyramid, a sandy beach sloping into a sea to the north-east
## (the sea floor at WonderTour.SEA_FLOOR, the water at MeadowsShape.SEA_LEVEL), the Lighthouse's island with a rocky
## rim and the raised causeway out to it. The second tour, the New Seven Wonders, has its own region round
## WonderTour.NEW_SQUARE out to NEW_R, at the end of the Wonders Road (NewSevenGround: flat, with the Great Wall's ridge,
## Corcovado and Huayna Picchu; Petra's sand). The third tour, the Seven Natural Wonders, has its own region round
## WonderTour.NATURE_SQUARE out to NATURE_R, at the end of the Nature Trail (NatureGround: the canyon's plateau, the
## volcano, the snowy valley, the mountains, the falls, the bay, the sea and the reef; its own trees: pines in the snow, a
## rainforest facing the falls). Past them (over WonderTour.BLEND) the ground blends into Green
## Meadows' own endless land (MeadowsShape: hills, rivers, seas), the same for every world seed out there as at home.
## No cave opens under the tours (WondersGenerator), trees keep off the wonders, the paths, the road and the squares
## (olive trees to the west of the first park, palms on its sand and by Babylon, oaks elsewhere), and every spawner's
## "dry land" keeps off the wonders' footprints and the rivers (is_river). Read-only after construction.

const TOUR_TREES_PER_MILLE := 7    # a park: half the meadows' trees
const CLEAR_MARGIN := 5            # trees keep this far from a wonder
const PATH_CLEAR := 3.0            # ... and from a path's middle

var _clear: Array[Rect2i] = []     # no trees here
var _built: Array[Rect2i] = []     # the wonders' footprints and the river: no animal, stall or secret
var _paths: Array[PackedVector2Array] = []
var _nature_clear: Array[Rect2i] = []   # the nature region's own clearings and paths (its trees look only at these)
var _nature_paths: Array[PackedVector2Array] = []
## The nature region's columns (NatureGround.sample: height and kind), worked out a chunk column at a time and kept: the
## generator asks a column many times (every chunk of its stack, its write, the trees and flowers round it). Its
## threads share it behind the mutex; it forgets everything when it grows past NATURE_CACHE chunk columns.
const NATURE_CACHE := 1024
var _nature_cache := {}            # Vector2i (chunk column) -> PackedInt32Array: [height, kind] for its 16 x 16 columns
var _nature_mutex := Mutex.new()


func _init(world_seed: int) -> void:
	super(world_seed)
	for id: StringName in WonderTour.ids():
		var f := WonderTour.reach(id)
		if WonderFacts.tour_of(id) != &"nature":   # nature's own trees grow round its wonders (NatureGround), but
			_clear.append(f.grow(CLEAR_MARGIN))    # never on its builds (WonderBuildsNature.CLEAR)
		_built.append(f.grow(1))
		var ends := WonderTour.path(id)
		_paths.append(PackedVector2Array([Vector2(ends[0]), Vector2(ends[1])]))
	for id: StringName in WonderBuildsNature.CLEAR:
		for r: Rect2i in WonderBuildsNature.CLEAR[id]:
			var p := WonderTour.to_world(id, r.position)
			var q := WonderTour.to_world(id, r.end - Vector2i.ONE)
			var world := Rect2i(p.min(q), (p.max(q) - p.min(q)) + Vector2i.ONE).grow(2)
			_clear.append(world)
			_nature_clear.append(world)
	for id: StringName in WonderFacts.tour_ids(&"nature"):
		var ends := WonderTour.path(id)
		_nature_paths.append(PackedVector2Array([Vector2(ends[0]), Vector2(ends[1])]))
	_clear.append(WonderTour.WORKSHOP.grow(3))
	_built.append(WonderTour.WORKSHOP.grow(1))
	_clear.append(WonderTour.RIVER.grow(2))
	_built.append(WonderTour.RIVER.grow(1))
	_clear.append(WonderTour.CAUSEWAY.grow(2))
	_clear.append(WonderTour.PETRA_SAND)   # owner #78's second tour: Petra's desert
	var road := WonderTour.road()
	_paths.append(PackedVector2Array([Vector2(road[0]), Vector2(road[1])]))
	var trail := WonderTour.trail()
	_paths.append(PackedVector2Array([Vector2(trail[0]), Vector2(trail[1])]))
	_nature_paths.append(PackedVector2Array([Vector2(trail[0]), Vector2(trail[1])]))


## The landing spot: the middle of the landing square.
func spawn_column() -> Vector2i:
	return Vector2i.ZERO


func _column(x: int, z: int) -> Vector2i:
	var r2 := x * x + z * z
	if r2 <= WonderTour.FLAT_R * WonderTour.FLAT_R:
		return Vector2i(tour_height(x, z), 0)
	var n := WonderTour.new_distance(x, z)
	if n <= WonderTour.NEW_R:
		return Vector2i(NewSevenGround.height(x, z), 0)   # the New Seven's region
	var m := WonderTour.nature_distance(x, z)
	if m <= WonderTour.NATURE_R:
		return Vector2i(nature_sample(x, z).x, 0)   # the Seven Natural Wonders' region
	var d_old := sqrt(float(r2)) - WonderTour.FLAT_R
	var d_new := n - WonderTour.NEW_R
	var d_nat := m - WonderTour.NATURE_R
	var d_two := minf(d_old, d_new)
	if minf(d_two, d_nat) >= WonderTour.BLEND:
		return super._column(x, z)
	var meadows := super._column(x, z)
	var designed := 0
	if d_nat < d_two:
		designed = nature_sample(x, z).x
	elif d_old <= d_new:
		designed = tour_height(x, z)
	else:
		designed = NewSevenGround.height(x, z)
	# between the first park and the nature region (both level there, the Nature Trail crossing): the blends multiply,
	# so the gap stays level; elsewhere only the nearest region's blend counts (as before the third tour)
	var t := smoothstep(0.0, float(WonderTour.BLEND), d_two) * smoothstep(0.0, float(WonderTour.BLEND), d_nat)
	var h := roundi(lerpf(designed, meadows.x, t))
	return Vector2i(clampi(h, MIN_HEIGHT, MAX_HEIGHT), meadows.y if t > 0.95 else 0)


## NatureGround.sample(x, z) (height, kind), from the chunk column's kept samples (worked out on the first ask).
func nature_sample(x: int, z: int) -> Vector2i:
	var key := Vector2i(x >> 4, z >> 4)
	_nature_mutex.lock()
	var cols: PackedInt32Array = _nature_cache.get(key, PackedInt32Array())
	_nature_mutex.unlock()
	if cols.is_empty():
		cols.resize(512)
		var x0 := key.x << 4
		var z0 := key.y << 4
		for j in 16:
			for i in 16:
				var s := NatureGround.sample(x0 + i, z0 + j)
				cols[(j * 16 + i) * 2] = s.x
				cols[(j * 16 + i) * 2 + 1] = s.y
		_nature_mutex.lock()
		if _nature_cache.size() >= NATURE_CACHE:
			_nature_cache.clear()
		_nature_cache[key] = cols
		_nature_mutex.unlock()
	var k := ((z & 15) * 16 + (x & 15)) * 2
	return Vector2i(cols[k], cols[k + 1])


## The tour's ground at (x, z): flat at WonderTour.BASE_Y, the beach and the sea to the north-east, the island and the
## causeway at the tour's level.
func tour_height(x: int, z: int) -> int:
	var c := WonderTour.CAUSEWAY
	if x >= c.position.x and x < c.end.x and z >= c.position.y and z < c.end.y:
		return WonderTour.BASE_Y
	var d := WonderTour.coast_distance(x, z)
	if d <= -WonderTour.BEACH_IN:
		return WonderTour.BASE_Y
	var t := clampf((d + WonderTour.BEACH_IN) / (WonderTour.BEACH_IN + 8.0), 0.0, 1.0)
	var h := roundi(lerpf(WonderTour.BASE_Y, WonderTour.SEA_FLOOR, t))
	var r := Vector2(x - WonderTour.ISLAND.x, z - WonderTour.ISLAND.y).length()
	if r <= WonderTour.ISLAND_R + WonderTour.ISLAND_RIM:
		var rim := clampf((r - WonderTour.ISLAND_R) / WonderTour.ISLAND_RIM, 0.0, 1.0)
		h = maxi(h, roundi(lerpf(WonderTour.BASE_Y, WonderTour.SEA_FLOOR, rim)))
	return h


## Sand on top here (Giza's sand, the beach, the island; Petra's desert), not grass. (The nature region's columns are
## NatureGround's kinds: WondersGenerator writes them itself.)
func sandy(x: int, z: int) -> bool:
	if WonderTour.in_nature_region(x, z):
		var k := nature_sample(x, z).y
		return k == NatureGround.BEACH or k == NatureGround.SEA_FLOOR or k == NatureGround.REEF
	if WonderTour.PETRA_SAND.has_point(Vector2i(x, z)):
		return true
	if x * x + z * z > WonderTour.BLEND_R * WonderTour.BLEND_R:
		return false
	if WonderTour.DESERT.has_point(Vector2i(x, z)):
		return true
	return WonderTour.coast_distance(x, z) > -WonderTour.BEACH_IN


## True on the wonders' footprints and the river (and in Green Meadows' river channels out past the tour): every
## spawner's "dry land" (animals, Tilly's stall, the Totem, the stone circle, secrets) keeps off them.
func is_river(x: int, z: int) -> bool:
	return is_built(x, z) or super.is_river(x, z)


## A wonder (or the workshop, or the river) stands on (x, z).
func is_built(x: int, z: int) -> bool:
	if x * x + z * z > WonderTour.FLAT_R * WonderTour.FLAT_R and WonderTour.new_distance(x, z) > WonderTour.NEW_R \
			and WonderTour.nature_distance(x, z) > WonderTour.NATURE_R:
		return false
	var p := Vector2i(x, z)
	for r in _built:
		if r.has_point(p):
			return true
	return false


func tree_at(x: int, z: int) -> bool:
	# The generator asks every column round every chunk of a stack: most go no further than this roll (no ground here
	# grows more than NatureGround.TREES_MOST in a thousand: the park 7, Green Meadows 14, the rainforest 60).
	var roll := absi(_hash(x, z)) % 1000
	if roll >= NatureGround.TREES_MOST:
		return false
	var r2 := x * x + z * z
	if WonderTour.in_nature_region(x, z):
		return _nature_tree(x, z, roll)
	if r2 > WonderTour.BLEND_R * WonderTour.BLEND_R \
			and WonderTour.new_distance(x, z) > WonderTour.NEW_R + WonderTour.BLEND \
			and WonderTour.nature_distance(x, z) > WonderTour.NATURE_R + WonderTour.BLEND:
		return super.tree_at(x, z)
	if roll >= TOUR_TREES_PER_MILLE:
		return false
	if height_at(x, z) <= SEA_LEVEL + 1 or _on_a_square(x, z, 5):
		return false
	return _clear_of_paths(x, z)


## A tree of the nature region at (x, z): as many as NatureGround says grow on its kind of ground, never on a square, a
## path, the trail or a build.
func _nature_tree(x: int, z: int, roll: int) -> bool:
	if roll >= NatureGround.TREES_OUTSIDE_FOREST and not NatureGround.in_rainforest(x, z):
		return false   # (most columns: no ground to look at)
	var s := nature_sample(x, z)
	var per_mille := NatureGround.tree_per_mille(x, z, s.x, s.y)
	if roll >= per_mille:
		return false
	var sq := WonderTour.NATURE_SQUARE
	var r := WonderTour.PLAZA_R + 5
	if (x - sq.x) * (x - sq.x) + (z - sq.y) * (z - sq.y) <= r * r:
		return false
	var p := Vector2i(x, z)
	for c in _nature_clear:
		if c.has_point(p):
			return false
	for seg in _nature_paths:
		if WonderTour.segment_distance(Vector2(x, z), seg[0], seg[1]) <= PATH_CLEAR:
			return false
	return true


func _clear_of_paths(x: int, z: int) -> bool:
	var p := Vector2i(x, z)
	for r in _clear:
		if r.has_point(p):
			return false
	for seg in _paths:
		if WonderTour.segment_distance(Vector2(x, z), seg[0], seg[1]) <= PATH_CLEAR:
			return false
	return true


## The tree growing at (x, z): &"olive" (Greece, to the west of the first park), &"palm" (its sand, Egypt and
## Babylon), &"pine" (the nature region's snow and the canyon's plateau), &"oak" (elsewhere, and round the New Seven).
func tree_kind(x: int, z: int) -> StringName:
	if WonderTour.in_nature_region(x, z):
		return NatureGround.tree_kind(nature_sample(x, z).y)
	if x * x + z * z > WonderTour.BLEND_R * WonderTour.BLEND_R:
		return &"oak"
	if sandy(x, z) or (x > 30 and z > 20):
		return &"palm"
	if x < -40:
		return &"olive"
	return &"oak"


## Wild flowers dot the park's grass (one column in FLOWER_EVERY).
const FLOWER_EVERY := 45


func flower_at(x: int, z: int) -> bool:
	var nature := WonderTour.in_nature_region(x, z)
	if x * x + z * z > WonderTour.FLAT_R * WonderTour.FLAT_R and WonderTour.new_distance(x, z) > WonderTour.NEW_R \
			and not nature:
		return false
	if absi(_hash(z * 3 + 1, x * 5 - 2)) % FLOWER_EVERY != 0:
		return false
	if nature:   # on the nature region's grass (not its snow, sand, rock or fields)
		var s := nature_sample(x, z)
		if s.x != WonderTour.BASE_Y or (s.y != NatureGround.LAND and s.y != NatureGround.BASALT_LAND):
			return false
		return not tree_at(x, z) and _clear_of_tour(x, z)
	return not tree_at(x, z) and height_at(x, z) == WonderTour.BASE_Y and not sandy(x, z) and _clear_of_tour(x, z)


## (x, z) is on a tour's square or within `margin` of it.
func _on_a_square(x: int, z: int, margin: int) -> bool:
	var r := WonderTour.PLAZA_R + margin
	for c: Vector2i in WonderTour.SQUARES.values():
		if (x - c.x) * (x - c.x) + (z - c.y) * (z - c.y) <= r * r:
			return true
	return false


func _clear_of_tour(x: int, z: int) -> bool:
	if _on_a_square(x, z, 3):
		return false
	var p := Vector2i(x, z)
	for r in _clear:
		if r.has_point(p):
			return false
	for seg in _paths:
		if WonderTour.segment_distance(Vector2(x, z), seg[0], seg[1]) <= PATH_CLEAR:
			return false
	return true
