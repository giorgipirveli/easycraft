class_name TutorialProps
extends RefCounted
## The playground's cells (M3 Task 15, spec §14.9), pure: what to change in the world for a site (a level pad with
## the holes, the wall, the bushes and Pip's Workbench) and how to put everything back. Nothing is ever kept: every
## changed cell is recorded as [x, y, z, what it held, what the course put there] (WorldMeta.tutorial_props, saved
## the moment the course goes in), and clearing puts back what it held; a block the child built into a recorded
## cell goes back to their bag. Only natural ground and plants may be built over (a child's build: another site).
## block_at(Vector3i) -> int reads the world.

## Plants and trees count as nature too (they come back when the course goes).
const NATURE: Array[int] = [BlockIds.LOG, BlockIds.LEAVES, BlockIds.BUSH, BlockIds.DEAD_BUSH, BlockIds.FLOWERS,
	BlockIds.CACTUS, BlockIds.PALM_LOG, BlockIds.PALM_LEAVES, BlockIds.PINE_LOG, BlockIds.PINE_NEEDLES,
	BlockIds.BIRCH_LOG, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LOG, BlockIds.DARK_LEAVES, BlockIds.CANDY_CANE,
	BlockIds.LOLLIPOP, BlockIds.COTTON_CANDY, BlockIds.PACKED_SNOW]
## The most cells a record may hold (the course changes about 400-900).
const MAX_CELLS := 4096


static func is_natural(id: int) -> bool:
	return not CaptureRules.is_capturable(id) or NATURE.has(id)


## Every cell of the course's volume holds natural ground, plants or air.
static func natural(site: Dictionary, block_at: Callable) -> bool:
	var y0 := TutorialCourse.level(site)
	for c: Vector2i in TutorialCourse.footprint(site):
		for y in range(y0 - TutorialCourse.FILL_DOWN - 1, y0 + TutorialCourse.CLEAR_UP):
			if not is_natural(int(block_at.call(Vector3i(c.x, y, c.y)))):
				return false
	return true


## The course's record for `site` over the world as it is: [x, y, z, held, placed] for each cell that changes.
static func plan(site: Dictionary, block_at: Callable) -> Array:
	var want := {}
	var y0 := TutorialCourse.level(site)
	var home := _ground(site, block_at, TutorialCourse.START.x, TutorialCourse.START.y, [BlockIds.GRASS, BlockIds.DIRT])
	for a in range(TutorialCourse.A_MIN, TutorialCourse.A_MAX + 1):
		for s in range(-TutorialCourse.S_HALF, TutorialCourse.S_HALF + 1):
			var g := _ground(site, block_at, a, s, home)
			for dy in range(0, TutorialCourse.CLEAR_UP):
				want[TutorialCourse.cell(site, a, s, dy)] = BlockIds.AIR
			for dy in range(-TutorialCourse.FILL_DOWN, 0):
				var p := TutorialCourse.cell(site, a, s, dy)
				if dy == -1:
					want[p] = g[0]   # the top of the pad: the ground's own top (grass, sand, snow ...)
				elif not BlockIds.is_solid(int(block_at.call(p))):
					want[p] = g[1]
			var pit := (a >= TutorialCourse.GAP_FROM and a <= TutorialCourse.GAP_TO) \
				or (a >= TutorialCourse.BRIDGE_FROM and a <= TutorialCourse.BRIDGE_TO)
			if pit:
				for dy in range(-TutorialCourse.PIT_DEPTH, 0):
					want[TutorialCourse.cell(site, a, s, dy)] = BlockIds.AIR
				var floor_cell := TutorialCourse.cell(site, a, s, -TutorialCourse.PIT_DEPTH - 1)
				if not BlockIds.is_solid(int(block_at.call(floor_cell))):
					want[floor_cell] = g[1]
			if a == TutorialCourse.WALL_A:
				for dy in TutorialCourse.WALL_HIGH:
					want[TutorialCourse.cell(site, a, s, dy)] = g[1]
	for b: Vector2i in TutorialCourse.BUSHES:
		want[TutorialCourse.cell(site, b.x, b.y, 0)] = BlockIds.BUSH
	want[TutorialCourse.bench(site)] = BlockIds.CRAFTING_TABLE
	var record: Array = []
	for p: Vector3i in want:
		var held := int(block_at.call(p))
		if held != int(want[p]):
			record.append([p.x, p.y, p.z, held, int(want[p])])
	return record


## [top, under] of the ground at (a, s): the column's highest solid block within the pad's reach and the one under it.
static func _ground(site: Dictionary, block_at: Callable, a: int, s: int, fallback: Array) -> Array:
	var y0 := TutorialCourse.level(site)
	for dy in range(TutorialCourse.CLEAR_UP - 1, -TutorialCourse.FILL_DOWN - 2, -1):
		var id := int(block_at.call(TutorialCourse.cell(site, a, s, dy)))
		if BlockIds.is_solid(id) and not NATURE.has(id):
			var under := int(block_at.call(TutorialCourse.cell(site, a, s, dy - 1)))
			return [id, under if BlockIds.is_solid(under) and not NATURE.has(under) else id]
	return fallback


## What the record puts into the world: [[Vector3i, id], ...].
static func changes_of(record: Array) -> Array:
	var out: Array = []
	for e: Array in record:
		out.append([Vector3i(e[0], e[1], e[2]), int(e[4])])
	return out


## Putting everything back: {"changes": [[Vector3i, id], ...], "returns": {block id: n}, "theirs": n} — the blocks the
## child built into recorded cells, which the clearing takes away, go back to their bag. A cell holding what the course
## put there or what it held before (not written yet: the course goes in a batch a tick) is nobody's block. The first
## `theirs` changes are the cells whose blocks go back: they must leave the world in the same frame (M5 Task 6 review:
## a game closed while the rest went back a batch a tick found them still there and gave them back twice).
static func clear(record: Array, block_at: Callable) -> Dictionary:
	var theirs: Array = []
	var changes: Array = []
	var returns := {}
	for e: Array in record:
		var p := Vector3i(e[0], e[1], e[2])
		var now := int(block_at.call(p))
		if now == int(e[3]):
			continue
		if now != int(e[4]) and now != BlockIds.AIR and now != BlockIds.WATER:
			var back := GatherRules.cost(now)
			if Inventory.ownable(back):
				returns[back] = int(returns.get(back, 0)) + 1
				theirs.append([p, int(e[3])])
				continue
		changes.append([p, int(e[3])])
	return {"changes": theirs + changes, "returns": returns, "theirs": theirs.size()}


## A child whose feet are at `feet` would be in the way: a recorded cell is inside their body or right under it
## (a hole under the feet, a wall through them). `radius`: the body's half width, a little generous.
static func touches(record: Array, feet: Vector3, radius: float = 0.6) -> bool:
	var lo := Vector3i(floori(feet.x - radius), floori(feet.y) - 1, floori(feet.z - radius))
	var hi := Vector3i(floori(feet.x + radius), floori(feet.y) + 2, floori(feet.z + radius))
	for e: Array in record:
		if int(e[0]) >= lo.x and int(e[0]) <= hi.x and int(e[1]) >= lo.y and int(e[1]) <= hi.y \
				and int(e[2]) >= lo.z and int(e[2]) <= hi.z:
			return true
	return false


## The box around every recorded cell (to know when that part of the world is loaded).
static func box(record: Array) -> AABB:
	if record.is_empty():
		return AABB()
	var lo := Vector3(record[0][0], record[0][1], record[0][2])
	var hi := lo
	for e: Array in record:
		var p := Vector3(e[0], e[1], e[2])
		lo = lo.min(p)
		hi = hi.max(p)
	return AABB(lo, hi - lo + Vector3.ONE)


## A record read from a save: well-formed entries only (five whole numbers, real block ids), at most MAX_CELLS.
static func clean(v: Variant) -> Array:
	var out: Array = []
	if not v is Array:
		return out
	for e: Variant in v:
		if out.size() >= MAX_CELLS:
			break
		if not e is Array or (e as Array).size() != 5:
			continue
		var ok := true
		var nums: Array = []
		for n: Variant in e:
			if not typeof(n) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)) or float(n) != floorf(float(n)) \
					or absf(float(n)) > 1e7:
				ok = false
				break
			nums.append(int(n))
		if ok and _block(nums[3]) and _block(nums[4]):
			out.append(nums)
	return out


static func _block(id: int) -> bool:
	return id == BlockIds.AIR or BlockIds.is_block_id(id)   # never an item's id (BlockIds.RESERVED_FIRST …)
