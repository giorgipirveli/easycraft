class_name LifeTown
extends RefCounted
## Owner #112 (docs/design/life-skills.md §7, "Life Town"; Life L2): a small district a short walk from the spawn of
## every home world, placed like the Launch Site (LaunchSite: the seed turns the search round the spawn; flat, dry
## ground with no tree near; its doors facing the spawn; the save keeps it), never on the Theater or the Launch Site's
## plaza and never hiding behind them (or them behind it) seen from the spawn. Its six places: the practice house (Fire
## Escape), the clinic (Little Lifesaver), the market stall (My Money Stall), the street with its crossing (Safe
## Streets), the kitchen house (The Kitchen), the park bench (Calm Corner), the building site (Real Builder, owner #116),
## and Life L3a's practice pool (Water Safety), poisons cupboard house and weather hut (owner #118). Life L3b (owner #118,
## #115) added a second row nearest the spawn, its fronts facing it: the power hut (Electricity Safety), the animal corner
## (Safe with Animals), the first aid hut (Medical Emergencies) and Success S2's four (the goal board, the talk tent, the
## village board, the story stage). Life L3c (owner #112, #118) added a short third row in front of the second: the web
## café (Online City), the metro entrance (Find Your Way), the helper's house (Home Helper). Walking up to one starts its
## Experience (LifeTownDirector opens Life on it, like the Launch Site's Mission Board); every door is more than two
## reaches from every other.
##
## Unlike the Launch Site nothing is stamped into the world: the buildings are models (LifeTownBuildings), each on the
## highest ground under its own footprint with a plinth down to lower ground, so the town fits rolling meadows (no
## common slab: the ground between the places stays the world's, its trees too). Like the Launch Site's stamp, the host
## clears the trees and plants in and right round the places once (clear_changes: ordinary world edits) on a site the
## search could only find among trees (meadows are wooded). A child's build in the way (natural: only the world's
## ground, trees, plants and air in the box) moves the town elsewhere before it stands.
##
## A site: {pos: Vector3i(the plaza's middle x, the highest ground's first empty y, z), facing: 0..3}; local cells with
## +Z towards the spawn, turned by `facing` (LaunchSite's frame).

const PLAZA_MIN := Vector2i(-12, -7)
## Life L3b (owner #118, #115): the plaza grew a second row nearest the spawn (z 9..12, doors at 13.2 facing the spawn).
## Life L3c (owner #112, #118): and a short third row in front of it (z 15..16, doors at 17.2), its three in the middle.
const PLAZA_MAX := Vector2i(12, 18)
const SECOND_ROW_Z := 9
const THIRD_ROW_Z := 15
const PLINTH_DEPTH := 6
const CLEAR_UP := 10          # the natural check looks this far over the plaza
## Each place: its Experience, its walk-up spot (local, from the middle cell's centre: where its door or sign is), the
## words on its sign, its footprint (local cells, min and max) for the model and its body.
const SPOTS := {
	"house": {"experience": "fire_escape", "door": Vector2(-9.0, -1.0), "sign": "PRACTICE HOUSE: FIRE ESCAPE",
		"min": Vector2i(-11, -6), "max": Vector2i(-7, -2)},
	"clinic": {"experience": "little_lifesaver", "door": Vector2(-3.5, -1.0), "sign": "CLINIC: LITTLE LIFESAVER",
		"min": Vector2i(-5, -6), "max": Vector2i(-2, -2)},
	"market": {"experience": "money_stall", "door": Vector2(2.0, -1.2), "sign": "MARKET: MY MONEY STALL",
		"min": Vector2i(1, -5), "max": Vector2i(3, -3)},
	"kitchen": {"experience": "kitchen", "door": Vector2(8.0, -1.0), "sign": "THE KITCHEN",
		"min": Vector2i(6, -6), "max": Vector2i(10, -2)},
	"street": {"experience": "safe_streets", "door": Vector2(-1.0, 1.8), "sign": "SAFE STREETS",
		"min": Vector2i(-5, 2), "max": Vector2i(3, 4)},
	"bench": {"experience": "calm_corner", "door": Vector2(9.0, 4.4), "sign": "CALM CORNER",
		"min": Vector2i(8, 5), "max": Vector2i(10, 6)},
	# Owner #116 (round 4b; the lead): Real Builder's building site, the plaza's free front corner
	"site": {"experience": "real_builder", "door": Vector2(-9.5, 5.8), "sign": "BUILDING SITE: REAL BUILDER",
		"min": Vector2i(-11, 2), "max": Vector2i(-8, 5)},
	# Owner #118 (Life L3a): the practice pool (Water Safety) in the front row between the street and the bench, the
	# poisons cupboard's little house at the back row's end, the weather hut between the site and the street. The plaza
	# is full after these (the next wave gets a second row).
	"pool": {"experience": "water_safety", "door": Vector2(5.2, 2.0), "sign": "PRACTICE POOL: WATER SAFETY",
		"min": Vector2i(4, 3), "max": Vector2i(7, 6)},
	"cupboard": {"experience": "poisons_cupboard", "door": Vector2(12.0, -0.4), "sign": "THE POISONS CUPBOARD",
		"min": Vector2i(11, -6), "max": Vector2i(12, -2)},
	"hut": {"experience": "earth_weather", "door": Vector2(-6.5, 2.0), "sign": "EARTH AND WEATHER",
		"min": Vector2i(-7, 3), "max": Vector2i(-6, 6)},
	# Life L3b (owner #118, #115): the second row, nearest the spawn, its doors facing it 3.7 m apart: the power hut
	# (Electricity Safety), the animal corner (Safe with Animals), the first aid hut (Medical Emergencies), and Success S2's
	# four: the goal board, the talk tent, the village board, the story stage.
	"power": {"experience": "electricity", "door": Vector2(-11.1, 13.2), "sign": "ELECTRICITY SAFETY",
		"min": Vector2i(-12, 9), "max": Vector2i(-10, 12)},
	"pets": {"experience": "animals", "door": Vector2(-7.4, 13.2), "sign": "SAFE WITH ANIMALS",
		"min": Vector2i(-9, 9), "max": Vector2i(-6, 12)},
	"firstaid": {"experience": "medical", "door": Vector2(-3.7, 13.2), "sign": "MEDICAL EMERGENCIES",
		"min": Vector2i(-5, 9), "max": Vector2i(-3, 12)},
	"goals": {"experience": "goal_board", "door": Vector2(0.0, 13.2), "sign": "THE GOAL BOARD",
		"min": Vector2i(-1, 9), "max": Vector2i(1, 12)},
	"talk": {"experience": "talk_deal", "door": Vector2(3.7, 13.2), "sign": "TALK & DEAL",
		"min": Vector2i(3, 9), "max": Vector2i(5, 12)},
	"village": {"experience": "connections", "door": Vector2(7.4, 13.2), "sign": "THE CONNECTIONS BOOK",
		"min": Vector2i(6, 9), "max": Vector2i(9, 12)},
	"stage": {"experience": "success_stories", "door": Vector2(11.1, 13.2), "sign": "SUCCESS STORIES",
		"min": Vector2i(10, 9), "max": Vector2i(12, 12)},
	# Life L3c (owner #112, #118): the third row, in front of the second, its doors facing the spawn 5 m apart: the
	# little web café with its big play tablet (Online City), the metro entrance with its map (Find Your Way), the helper's
	# house with its washing line and recycling bins (Home Helper).
	"online": {"experience": "online_city", "door": Vector2(-5.0, 17.2), "sign": "ONLINE CITY",
		"min": Vector2i(-6, 15), "max": Vector2i(-4, 16)},
	"wayfinder": {"experience": "find_way", "door": Vector2(0.0, 17.2), "sign": "FIND YOUR WAY",
		"min": Vector2i(-1, 15), "max": Vector2i(1, 16)},
	"helper": {"experience": "home_helper", "door": Vector2(5.0, 17.2), "sign": "HOME HELPER",
		"min": Vector2i(4, 15), "max": Vector2i(6, 16)},
}
## Walking up this close (m, across the ground) to a spot opens it; feet this far above or below the plaza still count.
const REACH := 1.8
const HEIGHT := 3.0
const RADII: Array[int] = [34, 30, 38, 42, 46, 50, 54]
const ANGLES := 48
## The search's tiers: [the ground under a place may differ this much (its plinth fills it), trees allowed (cleared)].
const TIERS: Array = [[2, false], [3, false], [3, true]]
const PLAZA_STEP := 7              # and the ground under the whole town this much (no town on a cliff)
const TREE_MARGIN := 2             # no tree this close to a place's footprint
const MIN_EDGE_FROM_SPAWN := 20
const MAX_FROM_SPAWN := 58.0
const CLEAR := 6              # blocks between the Theater's walls (or the Launch Site's plaza) and the town's plaza
const SIGHT_GAP := 28.0       # degrees between the town and each landmark, seen from the spawn
## Owner #115 (S3): the Market Square, a second plaza near the town (MarketPlaza), keeps this far round from the town's
## middle, seen from the spawn (beside it, never hidden behind it), and its places CLEAR blocks off the town's plaza.
## Small and low, it may stand closer round to the Theater and the Launch Site than the town (PLAZA_SIGHT_GAP; their
## CLEAR blocks unchanged): with the town's 28 degrees, two of six real towns had no room beside them.
const TOWN_GAP := 30.0
const PLAZA_SIGHT_GAP := 20.0


## Owner #115 (S3): a plaza's layout {min, max, spots} (local cells, +Z towards the spawn): Life Town's own unless a
## caller gives another (the Market Square's, MarketPlaza.LAYOUT), for the search, the natural check, the trees cleared,
## the doors and walking up.
static func town_layout() -> Dictionary:
	return {"min": PLAZA_MIN, "max": PLAZA_MAX, "spots": SPOTS}


static func _lay(layout: Dictionary) -> Dictionary:
	return layout if not layout.is_empty() else town_layout()


## The first good site round `spawn`, or {}. height_at(x, z) -> the first empty y; is_dry(x, z); has_tree(x, z) a trunk
## there; theater and launch: their sites ({} for none).
## Owner #115 (S3): with another `layout` and the `town`'s site, the same search places that plaza near the town: the
## same rings' cells, the nearest to the town first (each with every tier: a near site with trees to clear beats a far
## one), never on the town's plaza nor behind it.
## Owner #132 (W1): `avoid` lists more plazas already placed ([site, layout] each: the town's and the Market Square's
## for the Discovery Academy): the site keeps off each one's plaza (CLEAR blocks) and PLAZA_SIGHT_GAP round from it.
static func pick(spawn: Vector2i, world_seed: int, height_at: Callable, is_dry: Callable, has_tree: Callable,
		theater: Dictionary = {}, launch: Dictionary = {}, rejected: Array = [], layout: Dictionary = {},
		town: Dictionary = {}, avoid: Array = []) -> Dictionary:
	if not town.is_empty():
		return _pick_near(spawn, height_at, is_dry, has_tree, theater, launch, rejected, _lay(layout), town)
	var start := _start_angle(world_seed)
	for tier: Array in TIERS:
		for r in RADII:
			for i in ANGLES:
				var a := TAU * float((start + i) % ANGLES) / ANGLES
				var c := spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
				if _rejected(c, rejected) or _avoided(c, spawn, avoid):
					continue
				var site := _try(c, spawn, height_at, is_dry, has_tree, theater, launch, int(tier[0]), bool(tier[1]),
					_lay(layout), {}, avoid)
				if not site.is_empty():
					return site
	return {}


## Owner #132 (W1): the cell `c` is within PLAZA_SIGHT_GAP round of one of the `avoid` plazas, seen from the spawn.
static func _avoided(c: Vector2i, spawn: Vector2i, avoid: Array) -> bool:
	for e: Array in avoid:
		var other: Dictionary = e[0]
		if other.is_empty():
			continue
		var o := Vector2i((other.pos as Vector3i).x, (other.pos as Vector3i).z)
		if rad_to_deg(absf(Vector2(c - spawn).angle_to(Vector2(o - spawn)))) < PLAZA_SIGHT_GAP:
			return true
	return false


static func _rejected(c: Vector2i, rejected: Array) -> bool:
	for j: Variant in rejected:
		if j is Vector2i and Vector2(c - (j as Vector2i)).length() < 30.0:
			return true
	return false


## Owner #115 (S3): the rings' cells by their distance to the town's middle (then by ring and angle: the same order
## every time), each tried with every tier.
static func _pick_near(spawn: Vector2i, height_at: Callable, is_dry: Callable, has_tree: Callable, theater: Dictionary,
		launch: Dictionary, rejected: Array, lay: Dictionary, town: Dictionary) -> Dictionary:
	var t := Vector2i((town.pos as Vector3i).x, (town.pos as Vector3i).z)
	var cells: Array = []
	for ri in RADII.size():
		for i in ANGLES:
			var a := TAU * float(i) / ANGLES
			var c := spawn + Vector2i(roundi(cos(a) * RADII[ri]), roundi(sin(a) * RADII[ri]))
			cells.append([Vector2(c - t).length_squared(), ri * ANGLES + i, c])
	cells.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0] or (p[0] == q[0] and p[1] < q[1]))
	for e: Array in cells:
		var c: Vector2i = e[2]
		if _rejected(c, rejected):
			continue
		for tier: Array in TIERS:
			var site := _try(c, spawn, height_at, is_dry, has_tree, theater, launch, int(tier[0]), bool(tier[1]), lay, town)
			if not site.is_empty():
				return site
	return {}


## pick() with a home world's terrain (its first spawn), its Theater and its Launch Site.
static func pick_for(shape: MeadowsShape, theater: Dictionary = {}, launch: Dictionary = {}, rejected: Array = [],
		layout: Dictionary = {}, town: Dictionary = {}, avoid: Array = [], world_seed: int = -1) -> Dictionary:
	return pick(shape.spawn_column(), shape.seed if world_seed == -1 else world_seed, shape.height_at,
		func(x: int, z: int) -> bool: return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) \
			and not TheaterSite.on_colony(shape, x, z),
		shape.tree_at, theater, launch, rejected, layout, town, avoid)


static func to_world(site: Dictionary, local: Vector2i) -> Vector2i:
	return LaunchSite.to_world(site, local)


static func to_world_point(site: Dictionary, local: Vector2, y: float) -> Vector3:
	return LaunchSite.to_world_point(site, local, y)


## A place's walk-up spot in the world: on the ground there (`ground`: (x, z) -> the first empty y), else at the
## site's height.
static func door_position(site: Dictionary, spot: String, ground: Callable = Callable(), layout: Dictionary = {}) -> Vector3:
	var spots: Dictionary = _lay(layout).spots
	if site.is_empty() or not spots.has(spot):
		return Vector3.INF
	var at := to_world_point(site, spots[spot].door, (site.pos as Vector3i).y)
	if ground.is_valid():
		at.y = float(ground.call(floori(at.x), floori(at.z)))
	return at


## The place whose spot feet at `feet` stand at ("" for none): the nearest within REACH.
static func near(site: Dictionary, feet: Vector3, ground: Callable = Callable(), layout: Dictionary = {}) -> String:
	if site.is_empty() or not feet.is_finite():
		return ""
	var best := ""
	var best_d := REACH
	for id: String in _lay(layout).spots:
		var d := door_position(site, id, ground, layout)
		var flat := Vector2(feet.x - d.x, feet.z - d.z).length()
		if flat <= best_d and absf(feet.y - d.y) <= HEIGHT:
			best = id
			best_d = flat
	return best


static func experience_at(site: Dictionary, feet: Vector3, ground: Callable = Callable(), layout: Dictionary = {}) -> String:
	var id := near(site, feet, ground, layout)
	return str(_lay(layout).spots[id].experience) if id != "" else ""


## Owner #115 (S3): whether the world cell lies on the plaza of `other` (a site of `layout`: the town's by default) or
## within CLEAR of it.
static func on_plaza(other: Dictionary, cell: Vector2i, layout: Dictionary = {}) -> bool:
	if other.is_empty():
		return false
	var lay := _lay(layout)
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for c: Vector2i in [lay.min, lay.max, Vector2i(lay.min.x, lay.max.y), Vector2i(lay.max.x, lay.min.y)]:
		var w := to_world(other, c)
		lo = Vector2i(mini(lo.x, w.x), mini(lo.y, w.y))
		hi = Vector2i(maxi(hi.x, w.x), maxi(hi.y, w.y))
	return cell.x >= lo.x - CLEAR and cell.x <= hi.x + CLEAR and cell.y >= lo.y - CLEAR and cell.y <= hi.y + CLEAR


## Whether the world cell (x, z) lies on the Launch Site's plaza (or within CLEAR of it).
static func on_launch_site(launch: Dictionary, cell: Vector2i) -> bool:
	if launch.is_empty():
		return false
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for c: Vector2i in [LaunchSite.PLAZA_MIN, LaunchSite.PLAZA_MAX, Vector2i(LaunchSite.PLAZA_MIN.x, LaunchSite.PLAZA_MAX.y),
			Vector2i(LaunchSite.PLAZA_MAX.x, LaunchSite.PLAZA_MIN.y)]:
		var w := LaunchSite.to_world(launch, c)
		lo = Vector2i(mini(lo.x, w.x), mini(lo.y, w.y))
		hi = Vector2i(maxi(hi.x, w.x), maxi(hi.y, w.y))
	return cell.x >= lo.x - CLEAR and cell.x <= hi.x + CLEAR and cell.y >= lo.y - CLEAR and cell.y <= hi.y + CLEAR


## [lowest corner, size] of the box the natural check reads: the plaza, from the plinth's bottom to CLEAR_UP over it.
static func natural_box(site: Dictionary, layout: Dictionary = {}) -> Array:
	var p: Vector3i = site.pos
	var lay := _lay(layout)
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for c: Vector2i in [lay.min, lay.max, Vector2i(lay.min.x, lay.max.y), Vector2i(lay.max.x, lay.min.y)]:
		var w := to_world(site, c)
		lo = Vector2i(mini(lo.x, w.x), mini(lo.y, w.y))
		hi = Vector2i(maxi(hi.x, w.x), maxi(hi.y, w.y))
	var bottom := p.y - PLINTH_DEPTH
	return [Vector3i(lo.x, bottom, lo.y), Vector3i(hi.x - lo.x + 1, p.y + CLEAR_UP - bottom + 1, hi.y - lo.y + 1)]


## The plaza's box holds only the world's own ground, trees, plants and air: never a child's build.
static func natural(site: Dictionary, read: Callable, layout: Dictionary = {}) -> bool:
	var box := natural_box(site, layout)
	var lo: Vector3i = box[0]
	var size: Vector3i = box[1]
	for x in range(lo.x, lo.x + size.x):
		for z in range(lo.z, lo.z + size.z):
			for y in range(lo.y, lo.y + size.y):
				var id: int = read.call(Vector3i(x, y, z))
				if id != BlockIds.AIR and not BotRules.NATURAL.has(id) and not LaunchSite.TREE_KINDS.has(id):
					return false
	return true


## [[Vector3i, AIR], …]: the trees and plants in and right round the places (TREE_MARGIN), in the natural box, that the
## host clears once before the buildings stand (read: one bulk copy of natural_box on a worker is fine).
static func clear_changes(site: Dictionary, read: Callable, layout: Dictionary = {}) -> Array:
	var box := natural_box(site, layout)
	var lo: Vector3i = box[0]
	var size: Vector3i = box[1]
	var out: Array = []
	var seen := {}
	var spots: Dictionary = _lay(layout).spots
	for id: String in spots:
		var s: Dictionary = spots[id]
		for lx in range((s.min as Vector2i).x - TREE_MARGIN, (s.max as Vector2i).x + TREE_MARGIN + 1):
			for lz in range((s.min as Vector2i).y - TREE_MARGIN, (s.max as Vector2i).y + TREE_MARGIN + 1):
				var k := to_world(site, Vector2i(lx, lz))
				if seen.has(k):
					continue
				seen[k] = true
				for y in range(lo.y, lo.y + size.y):
					var at := Vector3i(k.x, y, k.y)
					if LaunchSite.TREE_KINDS.has(int(read.call(at))):
						out.append([at, BlockIds.AIR])
	return out


## Owner #115 (S3): the town's [x, y, z, facing], then its Market Square's four once that stands (site.market): the
## world's save (WorldMeta.life_town) keeps both in one list.
static func to_save(site: Dictionary) -> Array:
	if site.is_empty():
		return []
	var p: Vector3i = site.pos
	var out := [p.x, p.y, p.z, int(site.facing)]
	var m: Variant = site.get("market")
	if m is Dictionary and not (m as Dictionary).is_empty():
		var q: Vector3i = m.pos
		out.append_array([q.x, q.y, q.z, int(m.facing)])
	return out


static func from_save(v: Variant) -> Dictionary:
	if v is Array and (v as Array).size() == 8:   # owner #115 (S3): the town and its Market Square
		var town := TheaterSite.from_save((v as Array).slice(0, 4))
		var market := TheaterSite.from_save((v as Array).slice(4, 8))
		if not town.is_empty() and not market.is_empty():
			town.market = market
		return town
	return TheaterSite.from_save(v)


static func _start_angle(world_seed: int) -> int:
	var h := world_seed * 40503 + 1013
	h = h ^ (h >> 11)
	return posmod(h, ANGLES)


static func _try(c: Vector2i, spawn: Vector2i, height_at: Callable, is_dry: Callable, has_tree: Callable,
		theater: Dictionary, launch: Dictionary, max_step: int, trees_ok: bool, lay: Dictionary = {},
		town: Dictionary = {}, avoid: Array = []) -> Dictionary:
	if lay.is_empty():
		lay = town_layout()
	var plaza_min: Vector2i = lay.min
	var plaza_max: Vector2i = lay.max
	var spots: Dictionary = lay.spots
	var facing := TheaterSite.facing_towards(c, spawn)
	var site := {"pos": Vector3i(c.x, 0, c.y), "facing": facing}
	var gap := SIGHT_GAP if town.is_empty() else PLAZA_SIGHT_GAP   # owner #115 (S3)
	for other: Dictionary in [theater, launch]:
		if other.is_empty():
			continue
		var o := Vector2i((other.pos as Vector3i).x, (other.pos as Vector3i).z)
		if rad_to_deg(absf(Vector2(c - spawn).angle_to(Vector2(o - spawn)))) < gap:
			return {}
	if not town.is_empty():   # owner #115 (S3): beside the town, never behind it
		var t := Vector2i((town.pos as Vector3i).x, (town.pos as Vector3i).z)
		if rad_to_deg(absf(Vector2(c - spawn).angle_to(Vector2(t - spawn)))) < TOWN_GAP:
			return {}
	var corners: Array[Vector2i] = []
	for k: Vector2i in [plaza_min, plaza_max, Vector2i(plaza_min.x, plaza_max.y), Vector2i(plaza_max.x, plaza_min.y)]:
		corners.append(to_world(site, k))
	for k in corners:
		var d := Vector2(k - spawn).length()
		if d < MIN_EDGE_FROM_SPAWN or d > MAX_FROM_SPAWN:
			return {}
	if not theater.is_empty():   # Life L3c: the whole plaza clear of the Theater, its empty corners too (its edge's cells)
		var t := Vector2i((theater.pos as Vector3i).x, (theater.pos as Vector3i).z)
		for lx in range(plaza_min.x, plaza_max.x + 1):
			for lz: int in [plaza_min.y, plaza_max.y]:
				if TheaterSite.edge_distance(t, to_world(site, Vector2i(lx, lz))) < CLEAR:
					return {}
		for lz in range(plaza_min.y, plaza_max.y + 1):
			for lx: int in [plaza_min.x, plaza_max.x]:
				if TheaterSite.edge_distance(t, to_world(site, Vector2i(lx, lz))) < CLEAR:
					return {}
	var lo := 1 << 30
	var hi := -(1 << 30)
	for id: String in spots:   # each place (and its door) on dry, near-level ground with no tree in it or right round it
		var s: Dictionary = spots[id]
		var f_lo := 1 << 30
		var f_hi := -(1 << 30)
		var door := Vector2i((s.door as Vector2).floor())
		var mn := Vector2i(mini((s.min as Vector2i).x, door.x), mini((s.min as Vector2i).y, door.y))
		var mx := Vector2i(maxi((s.max as Vector2i).x, door.x), maxi((s.max as Vector2i).y, door.y))
		for lx in range(mn.x - TREE_MARGIN, mx.x + TREE_MARGIN + 1):
			for lz in range(mn.y - TREE_MARGIN, mx.y + TREE_MARGIN + 1):
				var k := to_world(site, Vector2i(lx, lz))
				if not trees_ok and has_tree.call(k.x, k.y):
					return {}
				if lx < mn.x or lx > mx.x or lz < mn.y or lz > mx.y:
					continue
				if Vector2(k - spawn).length() < MIN_EDGE_FROM_SPAWN or not is_dry.call(k.x, k.y):
					return {}
				if not theater.is_empty() and TheaterSite.edge_distance(Vector2i((theater.pos as Vector3i).x,
						(theater.pos as Vector3i).z), k) < CLEAR:
					return {}
				if on_launch_site(launch, k) or on_plaza(town, k):   # owner #115 (S3): and off the town's plaza
					return {}
				for e: Array in avoid:   # owner #132 (W1): and off the other plazas (the town's, the Market Square's)
					if on_plaza(e[0], k, e[1]):
						return {}
				var h: int = height_at.call(k.x, k.y)
				f_lo = mini(f_lo, h)
				f_hi = maxi(f_hi, h)
				lo = mini(lo, h)
				hi = maxi(hi, h)
				if f_hi - f_lo > max_step or hi - lo > PLAZA_STEP:
					return {}
	hi = height_at.call(c.x, c.y)
	site.pos = Vector3i(c.x, hi, c.y)
	return site
