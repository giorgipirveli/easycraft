class_name RocketPlan
extends RefCounted
## Owner #98 (spec §21d, §25): Mission Control's plan, a rocket that flies, for every mission (MissionRules) and every
## crew of 1 to 4 astronauts. The table (PLANS) holds only each stage from the bottom: its engine kind, how many engines,
## how many fuel tanks. The rest follows from the rules: 3 fins round the first stage's engines, one stage separator
## under each next stage, and the lander's parts (lander: a capsule and a service module for each astronaut, 3 landing
## legs round its engine, a solar array, a heat shield and a parachute where there is air, a heat shield to skim a thin
## air, a nose cone on top).
##
## The table is made by tools/make_rocket_plans.gd (run headless; it searches the cheapest plans with the check's own
## sums, lays each one out here, and keeps only what passes the REAL RocketCheck for its mission and crew with every
## part bought, one piece on the pad inside 9 × 9 and MAX_LAYERS, at least MARGIN km/s over the need). Regenerate it
## whenever RocketParts, RocketCheck or MissionRules change; test_rocket_plan.gd guards it.
##
## cells() lays a plan out like a rocket a child knows: every stage centred on the pad's middle column, its engines in
## its bottom layer, its tanks in round layers above them (never wider than the stage below), the separator in the middle
## under the next stage's engines, the legs round the lander's engine, then the service modules with the solar array on
## their side, the heat shield and parachute, the capsules and the nose cone. Cells are relative to the pad's corner, y
## up (LaunchSite.corner, RocketCheck's frame). Also here: what BUILD IT FOR ME does with what stands on the pad (diff),
## what a Survivor bag still lacks (bag_short), the words. Pure: no nodes.

const E := BlockIds.ROCKET_ENGINE
const V := BlockIds.SPACE_ENGINE
const MAX_CREW := 4
const MAX_LAYERS := 24
const MARGIN := 0.05   # km/s over the mission's need: a plan never flies on a rounding
const MID := 4         # the pad's middle column (RocketCheck.PAD 9)
## Round layers: the middle, then whole rings round it (a plus, a 3 × 3 square, …, the whole 9 × 9).
const ROUND: Array[int] = [1, 5, 9, 13, 21, 25, 29, 37, 45, 49, 57, 61, 69, 77, 81]

# BEGIN PLANS (made by tools/make_rocket_plans.gd: do not edit by hand)
## mission id -> [crew 1, crew 2, crew 3, crew 4]: each the stages from the bottom, [engine, engines, tanks], or [] for
## no plan.
const PLANS := {
	&"moon": [
		[[E, 7, 9], [V, 2, 4], [V, 1, 1]],
		[[E, 9, 10], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
		[[E, 10, 7], [V, 5, 10], [V, 2, 3], [V, 1, 1]],
		[[E, 12, 5], [V, 7, 15], [V, 2, 4], [V, 1, 1]],
	],
	&"mars": [
		[[E, 8, 5], [V, 4, 9], [V, 1, 1], [V, 1, 1]],
		[[E, 12, 15], [V, 4, 9], [V, 1, 1], [V, 1, 1]],
		[[E, 13, 8], [V, 7, 15], [V, 2, 4], [V, 1, 1]],
		[[E, 17, 14], [V, 8, 17], [V, 2, 4], [V, 1, 1]],
	],
	&"europa": [
		[[E, 14, 10], [V, 7, 15], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 21, 20], [V, 9, 18], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
		[[E, 26, 23], [V, 12, 23], [V, 4, 6], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 35, 40], [V, 13, 26], [V, 4, 6], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
	],
	&"io": [
		[[E, 16, 12], [V, 8, 18], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 24, 20], [V, 11, 24], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
		[[E, 31, 30], [V, 13, 26], [V, 4, 6], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 36, 24], [V, 19, 41], [V, 5, 9], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
	],
	&"titan": [
		[[E, 11, 11], [V, 5, 9], [V, 2, 3], [V, 1, 1]],
		[[E, 15, 9], [V, 8, 18], [V, 2, 4], [V, 1, 1]],
		[[E, 20, 20], [V, 8, 18], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 23, 18], [V, 11, 24], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
	],
	&"mercury": [
		[[E, 53, 44], [V, 25, 56], [V, 6, 12], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 75, 68], [V, 33, 71], [V, 9, 15], [V, 4, 6], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[],
		[],
	],
	&"venus": [
		[[E, 4, 3], [V, 2, 4], [V, 1, 1]],
		[[E, 6, 8], [V, 2, 4], [V, 1, 1]],
		[[E, 8, 8], [V, 3, 6], [V, 1, 2]],
		[[E, 9, 8], [V, 4, 9], [V, 1, 2]],
	],
	&"rings": [
		[[E, 18, 16], [V, 8, 18], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 26, 22], [V, 12, 27], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
		[[E, 32, 27], [V, 15, 29], [V, 5, 9], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 44, 51], [V, 16, 35], [V, 4, 6], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
	],
	&"pluto": [
		[[E, 14, 7], [V, 8, 18], [V, 2, 4], [V, 1, 1]],
		[[E, 21, 23], [V, 8, 18], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 26, 25], [V, 11, 24], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
		[[E, 29, 20], [V, 15, 32], [V, 4, 6], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
	],
	&"triton": [
		[[E, 12, 6], [V, 7, 15], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 20, 24], [V, 7, 15], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 26, 31], [V, 9, 18], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
		[[E, 31, 30], [V, 13, 30], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
	],
	&"ganymede": [
		[[E, 9, 5], [V, 5, 10], [V, 2, 3], [V, 1, 1]],
		[[E, 14, 9], [V, 7, 15], [V, 2, 4], [V, 1, 1]],
		[[E, 17, 11], [V, 9, 21], [V, 2, 3], [V, 1, 1], [V, 1, 1]],
		[[E, 22, 18], [V, 10, 21], [V, 3, 6], [V, 1, 1], [V, 1, 1]],
	],
}
# END PLANS

static var _order: Array[Vector2i] = []   # every cell of the square, nearest the middle first, then round by angle
static var _rings: Array = []             # [[cells of one ring, round by angle], …], nearest first


## The plan's stages for `mission` and `crew` (bottom first, [engine, engines, tanks]), or [] when there is none.
static func stages_for(mission: Dictionary, crew: int) -> Array:
	var row: Array = PLANS.get(StringName(str(mission.get("id", ""))), [])
	var i := clampi(crew, 1, MAX_CREW) - 1
	return (row[i] as Array).duplicate(true) if i < row.size() else []


static func has_plan(mission: Dictionary, crew: int) -> bool:
	return not stages_for(mission, crew).is_empty()


## The lander's own parts besides its engines and tanks ({id: count}).
static func lander(mission: Dictionary, crew: int) -> Dictionary:
	var n := clampi(crew, 1, MAX_CREW)
	var out := {BlockIds.CREW_CAPSULE: n, BlockIds.SERVICE_MODULE: n, BlockIds.LANDING_LEGS: RocketCheck.LEGS_NEEDED,
		BlockIds.SOLAR_ARRAY: 1, BlockIds.NOSE_CONE: 1}
	if bool(mission.get("air", false)):
		out[BlockIds.HEAT_SHIELD] = 1
		out[BlockIds.PARACHUTE_PACK] = 1
	elif bool(mission.get("skim", false)):
		out[BlockIds.HEAT_SHIELD] = 1
	return out


## The plan's cells ({Vector3i from the pad's corner, y up: id}), or {} when there is none.
static func cells(mission: Dictionary, crew: int) -> Dictionary:
	return layout(stages_for(mission, crew), mission, crew)


static func gold(mission: Dictionary, crew: int) -> int:
	return RocketParts.cost(RocketParts.count(cells(mission, crew)))


static func size(mission: Dictionary, crew: int) -> int:
	return cells(mission, crew).size()


## The mission card's line: "Mission Control's plan: 33 parts, 470 gold." ("" for no plan: no_plan_words says so).
static func card_words(mission: Dictionary, crew: int) -> String:
	var c := cells(mission, crew)
	if c.is_empty():
		return no_plan_words(mission, crew)
	return "Mission Control's plan: %d parts, %d gold." % [c.size(), RocketParts.cost(RocketParts.count(c))]


## Plain words when a mission × crew has no plan ("" when it has one).
static func no_plan_words(mission: Dictionary, crew: int) -> String:
	if has_plan(mission, crew):
		return ""
	var who := "one astronaut" if crew <= 1 else "a crew of %d" % crew
	return "Mission Control has no plan for %s to %s yet: a rocket that big doesn't fit on the pad. Try fewer astronauts!" \
		% [who, str(mission.get("place", "there"))]


# --- The layout ------------------------------------------------------------------------------------------------------

## Lays `stages` out as cells, or {} when they don't fit (the generator tries plans until one fits). The tanks of each
## stage go in about 3 round layers, the separators each alone in their own layer; a plan too tall for MAX_LAYERS has
## them in fewer, wider layers, then the separators in the middle of their stage's top tank layer.
static func layout(stages: Array, mission: Dictionary, crew: int) -> Dictionary:
	if stages.is_empty():
		return {}
	for own_layer: bool in [true, false]:
		for per in [3, 2, 1]:
			var c := _layout(stages, mission, crew, per, own_layer)
			if not c.is_empty() and _height(c) <= MAX_LAYERS:
				return c
	return {}


static func _layout(stages: Array, mission: Dictionary, crew: int, per: int, own_layer: bool) -> Dictionary:
	_ensure()
	var out := {}
	var y := 0
	var below := 81
	var n := clampi(crew, 1, MAX_CREW)
	for i in stages.size():
		var st: Array = stages[i]
		var engine := int(st[0])
		var engines := int(st[1])
		var tanks := int(st[2])
		var top := i == stages.size() - 1
		if engines < 1 or tanks < 1 or engines > 81:
			return {}
		var bottom := _spread(engines)
		for p in bottom:
			out[Vector3i(p.x, y, p.y)] = engine
		if i == 0 and not _around(out, bottom, y, RocketCheck.FINS_NEEDED, BlockIds.ROCKET_FINS):
			return {}
		if top and not _around(out, bottom, y, RocketCheck.LEGS_NEEDED, BlockIds.LANDING_LEGS):
			return {}
		y += 1
		var shared := not top and not own_layer   # the separator in the middle of the stage's top tank layer
		var rest := tanks + (1 if shared else 0)
		var width := _width(ceili(float(rest) / per), below)
		below = width
		while rest > 0:
			var layer := mini(rest, width)
			var spots := _spread(layer) if layer == width else _compact(layer)   # the middle first either way
			var sep := shared and layer == rest   # the last layer: the separator in the middle, tanks round it
			for k in spots.size():
				out[Vector3i(spots[k].x, y, spots[k].y)] = BlockIds.STAGE_SEPARATOR if sep and k == 0 else BlockIds.FUEL_TANK
			rest -= layer
			y += 1
		if not top:
			if own_layer:
				out[Vector3i(MID, y, MID)] = BlockIds.STAGE_SEPARATOR
				y += 1
			continue
		var modules := _compact(n)
		for p in modules:
			out[Vector3i(p.x, y, p.y)] = BlockIds.SERVICE_MODULE
		if not _around(out, modules, y, 1, BlockIds.SOLAR_ARRAY):
			return {}
		y += 1
		var low: Array[int] = []
		if bool(mission.get("air", false)):
			low = [BlockIds.HEAT_SHIELD, BlockIds.PARACHUTE_PACK]
		elif bool(mission.get("skim", false)):
			low = [BlockIds.HEAT_SHIELD]
		if not low.is_empty():
			var spots := _compact(low.size())
			for k in low.size():
				out[Vector3i(spots[k].x, y, spots[k].y)] = low[k]
			y += 1
		for p in _compact(n):
			out[Vector3i(p.x, y, p.y)] = BlockIds.CREW_CAPSULE
		y += 1
		out[Vector3i(MID, y, MID)] = BlockIds.NOSE_CONE
	return out


static func _height(c: Dictionary) -> int:
	var top := -1
	for p: Vector3i in c:
		top = maxi(top, p.y)
	return top + 1


## The smallest round layer of at least `want` cells, never wider than `cap`.
static func _width(want: int, cap: int) -> int:
	var best := 1
	for k in ROUND:
		if k <= cap:
			best = k
		if k >= want and k <= cap:
			return k
	return best


static func _ensure() -> void:
	if not _order.is_empty():
		return
	var by := {}
	for x in RocketCheck.PAD:
		for z in RocketCheck.PAD:
			var d2 := (x - MID) * (x - MID) + (z - MID) * (z - MID)
			if not by.has(d2):
				by[d2] = []
			(by[d2] as Array).append(Vector2i(x, z))
	var keys := by.keys()
	keys.sort()
	for d2: int in keys:
		var ring: Array = by[d2]
		ring.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _angle(a) < _angle(b))
		_rings.append(ring)
		for p: Vector2i in ring:
			_order.append(p)


static func _angle(p: Vector2i) -> float:
	return fposmod(atan2(float(p.y - MID), float(p.x - MID)), TAU)


## n cells round the middle: whole rings first, the last ring's cells spread evenly round it (always holds the middle).
static func _spread(n: int) -> Array[Vector2i]:
	_ensure()
	var out: Array[Vector2i] = []
	for ring: Array in _rings:
		var need := n - out.size()
		if need <= 0:
			break
		if need >= ring.size():
			for p: Vector2i in ring:
				out.append(p)
		else:
			var step := float(ring.size()) / need
			for k in need:
				out.append(ring[int(k * step)])
	return out


## The n cells nearest the middle.
static func _compact(n: int) -> Array[Vector2i]:
	_ensure()
	return _order.slice(0, clampi(n, 0, _order.size()))


## k free cells of layer y touching `layer` side to side, spread round it (fins, legs, a solar array); false if no room.
static func _around(out: Dictionary, layer: Array[Vector2i], y: int, k: int, id: int) -> bool:
	var taken := {}
	for p in layer:
		taken[p] = true
	var seen := {}
	var spots: Array[Vector2i] = []
	for p in layer:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := p + d
			if q.x < 0 or q.y < 0 or q.x >= RocketCheck.PAD or q.y >= RocketCheck.PAD or taken.has(q) or seen.has(q) \
					or out.has(Vector3i(q.x, y, q.y)):
				continue
			seen[q] = true
			spots.append(q)
	if spots.size() < k:
		return false
	spots.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var aa := _angle(a)
		var ab := _angle(b)
		if not is_equal_approx(aa, ab):
			return aa < ab
		return (a - Vector2i(MID, MID)).length_squared() > (b - Vector2i(MID, MID)).length_squared())
	for i in k:
		var q: Vector2i = spots[int(i * spots.size() / k)]
		out[Vector3i(q.x, y, q.y)] = id
	return true


# --- On the pad ------------------------------------------------------------------------------------------------------

## The cells in layers, bottom first: [[[Vector3i, id], …] for y 0, 1, …], each layer from the middle out.
static func layers(plan: Dictionary) -> Array:
	_ensure()
	var top := _height(plan)
	var out: Array = []
	for y in top:
		var layer: Array = []
		for p in _order:
			var at := Vector3i(p.x, y, p.y)
			if plan.has(at):
				layer.append([at, plan[at]])
		out.append(layer)
	return out


## The top layer (y) of each stage, bottom first.
static func stage_tops(plan: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for st: Array in RocketCheck.stages_of(RocketCheck.find_rocket(plan)):
		var top := -1
		for p: Vector3i in st:
			top = maxi(top, p.y)
		out.append(top)
	return out


## A line for each stage, bottom first (the caption and the spoken line as BUILD IT FOR ME builds it):
## "Stage 1: 8 rocket engines and 10 fuel tanks lift everything."
static func stage_words(plan: Dictionary) -> Array[String]:
	var stages := RocketCheck.stages_of(RocketCheck.find_rocket(plan))
	var out: Array[String] = []
	for i in stages.size():
		var parts := {}
		for p: Vector3i in stages[i]:
			parts[plan[p]] = int(parts.get(plan[p], 0)) + 1
		var push := {}
		for id: int in [E, V, BlockIds.FUEL_TANK]:
			if parts.has(id):
				push[id] = parts[id]
		var go := RocketParts.list_words(push)
		if i == stages.size() - 1 and stages.size() > 1:
			var crew := {}
			for id: int in [BlockIds.CREW_CAPSULE, BlockIds.SERVICE_MODULE, BlockIds.LANDING_LEGS, BlockIds.SOLAR_ARRAY,
					BlockIds.HEAT_SHIELD, BlockIds.PARACHUTE_PACK]:
				if parts.has(id):
					crew[id] = parts[id]
			out.append("Stage %d, the lander: %s land the crew; %s keep them safe, under a nose cone." % [i + 1, go,
				RocketParts.list_words(crew)])
		elif i == 0:
			out.append("Stage 1: %s lift everything." % go)
		else:
			out.append("Stage %d: %s fire when stage %d drops away." % [i + 1, go, i])
	return out


## What building `plan` on a pad holding `pad` ({Vector3i from the corner: id, non-air}) does: {place: [[Vector3i, id]]
## (bottom up, the middle first), keep: cells already right, clear: [[Vector3i, old id]] (every other rocket part in the
## build box: it would join the rocket), blocked: [Vector3i] (a child's other blocks where the rocket goes: never
## broken, they must be moved first)}. Water counts as empty.
static func diff(plan: Dictionary, pad: Dictionary) -> Dictionary:
	var place: Array = []
	var keep := 0
	var blocked: Array = []
	for layer: Array in layers(plan):
		for c: Array in layer:
			var at: Vector3i = c[0]
			var now := int(pad.get(at, BlockIds.AIR))
			if now == int(c[1]):
				keep += 1
			elif now == BlockIds.AIR or now == BlockIds.WATER or RocketParts.is_part(now):
				place.append(c)
			else:
				blocked.append(at)
	var clear: Array = []
	for at: Vector3i in pad:
		var id := int(pad[at])
		if RocketParts.is_part(id) and RocketCheck.in_square(at) and int(plan.get(at, BlockIds.AIR)) != id:
			clear.append([at, id])
	clear.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector3i).y > (b[0] as Vector3i).y)
	return {"place": place, "keep": keep, "clear": clear, "blocked": blocked}


## Survivor: the parts ({id: count}) a bag still lacks to build `plan` on `pad`; have(id) -> int is the bag's count. The
## parts cleared off the pad go back into the bag first.
static func bag_short(plan: Dictionary, pad: Dictionary, have: Callable) -> Dictionary:
	var d := diff(plan, pad)
	var need := {}
	for c: Array in d.place:
		need[int(c[1])] = int(need.get(int(c[1]), 0)) + 1
	var back := {}
	for c: Array in d.clear:
		back[int(c[1])] = int(back.get(int(c[1]), 0)) + 1
	var out := {}
	for id: int in need:
		var short := int(need[id]) - int(back.get(id, 0)) - int(have.call(id))
		if short > 0:
			out[id] = short
	return out


## "Move 3 blocks off the pad first: Mission Control never breaks your blocks."
static func blocked_words(n: int) -> String:
	return "%s stand%s where the rocket goes: move %s off the pad first. Mission Control never breaks your blocks." % [
		"1 block" if n == 1 else "%d blocks" % n, "s" if n == 1 else "", "it" if n == 1 else "them"]
