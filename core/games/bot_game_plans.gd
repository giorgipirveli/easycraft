class_name BotGamePlans
extends RefCounted
## Bot friends in the co-op games, as pure choices (M4 Wave 3, agent H; spec §17.5). Hiding: a free
## hiding spot within HIDE_RADIUS of the counting spot (a barrel or closet before a bush, never one taken,
## never closer than MIN_HIDE), else a place the counting spot can't see, crouched. Seeking (fair: a bot
## never knows where anyone hides): the spots it knows, nearest first, at SEEK_SPEED (a little slower than
## a child), looking into each one for LOOK_TIME from SPOT_STOP away. Storm Run: the nearest star no other
## bot is after.

const NO_CELL := Vector3i(0, -100000, 0)
const HIDE_RADIUS := 30.0
const MIN_HIDE := 6.0
const HIDE_SPEED := 6.5           # running to hide while the seeker counts
const SEEK_SPEED := 4.0           # a child walks at 6
const STAR_SPEED := 5.5
const LOOK_TIME := 1.2
const SPOT_STOP := 2.0
const OPEN_PLACES := 10           # places tried when no hiding spot is free
const INSIDE_SPOTS: Array[int] = [BlockIds.BARREL, BlockIds.CLOSET]
const HIDING_SPOTS: Array[int] = [BlockIds.BARREL, BlockIds.CLOSET, BlockIds.BUSH]


## The hiding spot a bot goes for: `spots` is {cell: block id} around `base`; `taken` the cells someone
## is in (or going to). NO_CELL: none fits.
static func hide_choice(spots: Dictionary, taken: Array[Vector3i], base: Vector3, roll: int) -> Vector3i:
	var inside: Array[Vector3i] = []
	var bushes: Array[Vector3i] = []
	for cell: Vector3i in spots:
		var d := Vector2(cell.x + 0.5 - base.x, cell.z + 0.5 - base.z).length()
		if taken.has(cell) or d < MIN_HIDE or d > HIDE_RADIUS:
			continue
		if INSIDE_SPOTS.has(int(spots[cell])):
			inside.append(cell)
		elif int(spots[cell]) == BlockIds.BUSH:
			bushes.append(cell)
	var pool := inside if not inside.is_empty() else bushes
	if pool.is_empty():
		return NO_CELL
	pool.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return _key(a) < _key(b))   # the same on every run
	return pool[posmod(roll, pool.size())]


static func _key(c: Vector3i) -> String:
	return "%08d%08d%08d" % [c.x + 50000000, c.y + 50000000, c.z + 50000000]


## Flat places (x, z) to hide in the open: around `base`, between MIN_HIDE and HIDE_RADIUS away.
static func open_places(base: Vector3, roll: int) -> Array[Vector2]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([roll, "open"])
	var out: Array[Vector2] = []
	for i in OPEN_PLACES:
		var angle := (float(i) + rng.randf()) / float(OPEN_PLACES) * TAU
		var d := rng.randf_range(MIN_HIDE + 2.0, HIDE_RADIUS - 2.0)
		out.append(Vector2(base.x, base.z) + Vector2.from_angle(angle) * d)
	return out


## Of the places a bot could stand (`seen[i]`: the counting spot sees place i), one it can't be seen at;
## any when all are seen; INF for none.
static func open_choice(places: Array[Vector3], seen: Array[bool], roll: int) -> Vector3:
	var covered: Array[Vector3] = []
	for i in places.size():
		if i < seen.size() and not seen[i]:
			covered.append(places[i])
	var pool := covered if not covered.is_empty() else places
	return pool[posmod(roll, pool.size())] if not pool.is_empty() else Vector3.INF


## The order a seeking bot visits the spots it knows: one of the two nearest first (by `roll`), then
## always the nearest one left.
static func search_route(spots: Array[Vector3], from: Vector3, roll: int) -> Array[Vector3]:
	var left := spots.duplicate()
	var route: Array[Vector3] = []
	if left.is_empty():
		return route
	left.sort_custom(func(a: Vector3, b: Vector3) -> bool: return from.distance_squared_to(a) < from.distance_squared_to(b))
	var first: Vector3 = left[posmod(roll, mini(2, left.size()))]
	left.erase(first)
	route.append(first)
	while not left.is_empty():
		var here := route[-1]
		var best := 0
		for i in left.size():
			if here.distance_squared_to(left[i]) < here.distance_squared_to(left[best]):
				best = i
		route.append(left[best])
		left.remove_at(best)
	return route


## The nearest star (id -> centre) no other bot is after; -1 when there is none.
static func star_target(stars: Dictionary, from: Vector3, claimed: Array[int]) -> int:
	var best := -1
	var best_d := INF
	for id: int in stars:
		if claimed.has(id):
			continue
		var d := from.distance_squared_to(stars[id])
		if d < best_d:
			best_d = d
			best = id
	return best
