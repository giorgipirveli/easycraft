class_name ToolPowers
extends RefCounted
## Tool block powers as pure rules (M1b Task 11). Each returns EditBatch input, [[Vector3i, AIR], ...],
## which the player sends through Session.request_set_blocks, so the host checks every cell like any
## build (reach, bedrock). Empty cells, water and unbreakable blocks are never included.
## block_at(pos: Vector3i) -> int.

const MAX_TREE_BLOCKS := 400    # the axe never fells more than this at once (logs first)
const MAX_TRUNK := 64
const LEAF_RADIUS := 4          # leaves this far (sideways) from the trunk belong to the tree
const LEAF_ABOVE := 4           # ... and up to this high above its top log
const MAX_TRUNK_COLUMNS := 4    # a trunk wider than 2 x 2 is a log wall (a cabin), not a tree
## A natural tree stands on the ground: at least one trunk log sits on one of these.
const GROUND: Array[int] = [BlockIds.GRASS, BlockIds.DIRT, BlockIds.SAND, BlockIds.RED_SAND, BlockIds.SANDSTONE,
	BlockIds.SNOW, BlockIds.SNOWY_GRASS,   # M3 Task 3: Frostpeak's pines
	BlockIds.FROSTING, BlockIds.CAKE, BlockIds.SPRINKLES,   # M3 Task 4: the Candy Kingdom's lollipop trees
	BlockIds.SKY_GRASS, BlockIds.FLOATSTONE,   # owner 39: the Dragon Realm's giant mushrooms
	BlockIds.MUD,   # owner #45b: a swamp's dark trees
	BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS]   # universe 6: the Glow Caves' giant glowshrooms
## A tree's leaves by its log: Meadows trees, the desert's palms, Frostpeak's pines and the Candy Kingdom's
## lollipop trees (M3).
const LEAVES_OF := {BlockIds.LOG: BlockIds.LEAVES, BlockIds.PALM_LOG: BlockIds.PALM_LEAVES,
	BlockIds.PINE_LOG: BlockIds.PINE_NEEDLES,
	BlockIds.CANDY_CANE: BlockIds.LOLLIPOP,   # M3 Task 4: a lollipop tree (a striped stick, a swirly top)
	BlockIds.MUSHROOM_STEM: BlockIds.GLOW_CAP,   # owner 39: a giant mushroom (a stalk, a glowing cap)
	BlockIds.BIRCH_LOG: BlockIds.BIRCH_LEAVES, BlockIds.DARK_LOG: BlockIds.DARK_LEAVES,   # owner #45b
	BlockIds.SHROOM_STEM: BlockIds.BLUE_SHROOM}   # universe 6: a giant glowshroom (a pale stalk, a glowing cap)
const _NEIGHBOURS: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


## What tapping block `hit` (on the face with normal `face`) with a tool does: the axe fells the
## tree (or chops just that one block when it is not a tree), the pickaxe digs a step, the hammer
## smashes the ground. [] for anything else, or when there is nothing to break.
static func for_tool(item: int, hit: Vector3i, face: Vector3i, feet_y: int, block_at: Callable) -> Array:
	match WeaponRules.stats(item).get("power", &""):
		WeaponRules.POWER_FELL:
			var tree := fell_tree(hit, block_at)
			return tree if not tree.is_empty() else _breakable([hit], block_at)
		WeaponRules.POWER_TUNNEL:
			return tunnel(hit, face, feet_y, block_at)
		WeaponRules.POWER_SMASH:
			return smash(hit, block_at)
	return []


## Axe: the logs connected to `start` and the leaves of that tree, or [] if `start` is not the log
## of a tree (a tree stands on the ground, has leaves and a trunk at most 2 x 2 thick; a log
## pillar or a log-cabin wall is not a tree).
## Planks and everything else a player built stay. Leaves nearer to another tree's trunk stay with
## that tree, so touching canopies are felled one tree at a time.
static func fell_tree(start: Vector3i, block_at: Callable) -> Array:
	var log_id: int = block_at.call(start)
	if not LEAVES_OF.has(log_id):
		return []
	var leaf_id: int = LEAVES_OF[log_id]
	var trunk := _connected(start, block_at, log_id, MAX_TRUNK)
	var rooted := false
	var top := start.y
	var bottom := start.y
	for p: Vector3i in trunk:
		top = maxi(top, p.y)
		bottom = mini(bottom, p.y)
		if GROUND.has(block_at.call(p + Vector3i.DOWN)):
			rooted = true
	if not rooted:
		return []
	var columns := {}
	for p: Vector3i in trunk:
		columns[Vector2i(p.x, p.z)] = true
	if columns.size() > MAX_TRUNK_COLUMNS:
		return []
	var foreign := {}                        # trunk columns of other trees next to these leaves
	var leaves: Array[Vector3i] = []
	var seen := {}
	var queue: Array[Vector3i] = []
	for p: Vector3i in trunk:
		seen[p] = true
	for p: Vector3i in trunk:
		for n in _NEIGHBOURS:
			var q := p + n
			if not seen.has(q) and block_at.call(q) == leaf_id and _in_crown(q, columns, bottom, top):
				seen[q] = true
				queue.append(q)
	while not queue.is_empty():
		var p: Vector3i = queue.pop_front()
		leaves.append(p)
		for n in _NEIGHBOURS:
			var q := p + n
			if seen.has(q):
				continue
			var id: int = block_at.call(q)
			if id == log_id:
				foreign[Vector2i(q.x, q.z)] = true
			elif id == leaf_id and _in_crown(q, columns, bottom, top):
				seen[q] = true
				queue.append(q)
	if leaves.is_empty():
		return []
	var out: Array = []
	for p: Vector3i in trunk:
		out.append([p, BlockIds.AIR])
	for p in leaves:
		if out.size() >= MAX_TREE_BLOCKS:
			break
		if _column_distance(p, columns) <= _column_distance(p, foreign):
			out.append([p, BlockIds.AIR])
	return out


## Pickaxe: a player-sized step (1 wide, 2 tall) into the tapped block. `face` is the tapped face's
## normal (towards the player). Tapped at the feet or the head: the step lines up with the feet so
## the player can walk in; tapped on the floor: a 2-deep hole; on a ceiling: 2 up.
static func tunnel(hit: Vector3i, face: Vector3i, feet_y: int, block_at: Callable) -> Array:
	var cells: Array[Vector3i] = []
	if face.y > 0:
		cells = [hit, hit + Vector3i.DOWN]
	elif face.y < 0:
		cells = [hit, hit + Vector3i.UP]
	else:
		var base := feet_y if hit.y == feet_y or hit.y == feet_y + 1 else hit.y
		cells = [Vector3i(hit.x, base, hit.z), Vector3i(hit.x, base + 1, hit.z)]
	return _breakable(cells, block_at)


## Hammer ground smash: the 3x3 patch around the tapped block, on its level.
static func smash(center: Vector3i, block_at: Callable) -> Array:
	var cells: Array[Vector3i] = []
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			cells.append(center + Vector3i(dx, 0, dz))
	return _breakable(cells, block_at)


static func _breakable(cells: Array[Vector3i], block_at: Callable) -> Array:
	var out: Array = []
	for c in cells:
		var id: int = block_at.call(c)
		if id != BlockIds.AIR and id != BlockIds.WATER and BlockIds.is_breakable(id):
			out.append([c, BlockIds.AIR])
	return out


## Blocks of `id` connected to start (6 neighbours), at most `limit`.
static func _connected(start: Vector3i, block_at: Callable, id: int, limit: int) -> Array[Vector3i]:
	var found: Array[Vector3i] = [start]
	var seen := {start: true}
	var i := 0
	while i < found.size() and found.size() < limit:
		var p := found[i]
		i += 1
		for n in _NEIGHBOURS:
			var q := p + n
			if not seen.has(q) and block_at.call(q) == id:
				seen[q] = true
				found.append(q)
				if found.size() >= limit:
					break
	return found


static func _in_crown(p: Vector3i, columns: Dictionary, bottom: int, top: int) -> bool:
	return p.y >= bottom and p.y <= top + LEAF_ABOVE and _column_distance(p, columns) <= LEAF_RADIUS


## Sideways (Chebyshev) distance from p to the nearest trunk column; INF-like if there are none.
static func _column_distance(p: Vector3i, columns: Dictionary) -> int:
	var best := 1 << 30
	for c: Vector2i in columns:
		best = mini(best, maxi(absi(p.x - c.x), absi(p.z - c.y)))
	return best
