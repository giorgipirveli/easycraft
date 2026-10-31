class_name Scene3DBuilds
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): a `blocks` model's named builds, the game's own places as the child sees
## them, meshed like the world (the voxel mesher with the world's block library: its materials, its corner shade):
## - launch_tower: a Launch Site (LaunchSite.pad_changes: the concrete plaza, the pad's ring of stripes) with its tower,
##   Mission Control and the Mission Board (LaunchBuildings' own mesh); the pad's middle is 0, its floor y 0;
## - colony: the Moon's colony under its domes (the Moon's own generator: its ground, the domes, the gardens, the rocket
##   on its pad), its Great Dome's middle at 0 on the ground;
## - venus_city: Venus's cloud city (its own generator: the decks on their float hulls, the bridges, the homes and the
##   garden over the yellow clouds), the landing deck's middle at 0 on the deck;
## - wonder: one of the Seven Wonders as world 41 builds it (its generator: the wonder, its park, its ground), in the tour's
##   own places round the landing square (0 on the ground), so a flyover goes from one to the next where they stand;
## - anything else: its `cells` and (round 2) its `fill` of shapes (StudioShapes: a volcano, a pyramid's courses, a tank).
## A world's region is generated chunk by chunk with that world's generator and meshed once (kept for the run): seconds of
## work, for a rendered reel (tools/reel_render.gd); a live reel on a phone uses the light models.

const CH := VoxelBuffer.CHANNEL_TYPE
const CHUNK := 16
const TILE := 32
## The worlds' seed the reels are made from (any seed makes a whole world: this one's Moon colony and Venus city look good).
const SEED := 20261001

static var _cache := {}
## Round 2: shape meshes kept by their shapes ({key: {mesh, offset}}), the last SHAPES_KEPT (swiping back to a reel
## shows its blocks at once).
const SHAPES_KEPT := 24
static var _shapes := {}
static var _shape_order: Array = []
static var _reaping: Array[int] = []


## The meshes of a named `blocks` build (in its own space); a model's own cells and shapes are shape_mesh's.
static func meshes(data: Dictionary) -> Array[Mesh]:
	var out: Array[Mesh] = []
	match str(data.get("build", "")):
		"launch_tower":
			out.append(Scene3DModels.cells_mesh(plaza_cells(), Vector3(0.5, 0.0, 0.5)))
			out.append(LaunchBuildings.shared_mesh())
		"colony":
			out.append_array(colony())
		"venus_city":
			out.append_array(venus_city())
		"wonder":
			out.append_array(wonder(StringName(str(data.get("wonder", "pyramid")))))
	return out


## Round 2: a blocks model's own cells and shapes (StudioShapes) meshed like the world's blocks: {mesh, offset} (the
## mesh's 0 sits at `offset` in the model's space), {} for nothing. Main thread (a live stage fills the buffer on a
## worker and meshes it here: Scene3DModels.BlocksBuilt).
static func shape_mesh(data: Dictionary) -> Dictionary:
	return mesh_of(StudioShapes.buffer(data))


## StudioShapes.buffer's {buffer, lo} meshed: {mesh, offset}, {} for nothing.
static func mesh_of(made: Dictionary) -> Dictionary:
	if made.is_empty():
		return {}
	var mesh: Mesh = Scene3DModels.mesher().build_mesh(made.buffer, [], {})
	if mesh == null or mesh.get_surface_count() == 0:
		return {}
	return {"mesh": mesh, "offset": Vector3(made.lo as Vector3i) - Vector3(0.5, 0.0, 0.5) + Scene3DModels.MESHER_SHIFT}


## The key a model's shapes are kept by.
static func shape_key(data: Dictionary) -> int:
	return hash([data.get("fill", []), data.get("cells", [])])


## A kept shape mesh ({} when not kept).
static func kept(key: int) -> Dictionary:
	return _shapes.get(key, {})


static func keep(key: int, made: Dictionary) -> void:
	if made.is_empty() or _shapes.has(key):
		return
	_shapes[key] = made
	_shape_order.append(key)
	while _shape_order.size() > SHAPES_KEPT:
		_shapes.erase(_shape_order.pop_front())


## A worker task whose stage went away: waited for once it is done (the pool wants every task waited).
static func reap(task: int) -> void:
	_reaping.append(task)
	if _reaping.size() == 1:
		_reap_next()


static func _reap_next() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.process_frame.connect(func() -> void:
		var left: Array[int] = []
		for t in _reaping:
			if WorkerThreadPool.is_task_completed(t):
				WorkerThreadPool.wait_for_task_completion(t)
			else:
				left.append(t)
		_reaping = left
		if not _reaping.is_empty():
			_reap_next(), CONNECT_ONE_SHOT)


## The Launch Site's plaza as blocks: its floor's top at y 0, the pad's middle cell's centre at x = z = 0.5 (moved to
## 0 by the mesh: cells_mesh's origin), stripes round the build square.
static func plaza_cells() -> Dictionary:
	var out := {}
	for change: Array in LaunchSite.pad_changes({"pos": Vector3i(0, -1, 0), "facing": 0}, func(_x: int, _z: int) -> int: return -3):
		out[change[0]] = change[1]
	return out


## The Moon's colony: its region round the Great Dome.
static func colony() -> Array[Mesh]:
	var shape := UniverseRegistry.shape_for(SpaceRules.MOON, SEED) as SpaceShape
	if shape == null or shape.colony == null:
		return []
	var c := shape.colony.centre
	var g := shape.colony.ground
	return region(SpaceRules.MOON, Vector3i(c.x - 72, g - 8, c.y - 72), Vector3i(c.x + 72, shape.colony.top() + 2, c.y + 72),
		Vector3(c.x, g, c.y))


## Venus's cloud city: the landing deck and the ring of decks round it, over the clouds.
static func venus_city() -> Array[Mesh]:
	var shape := UniverseRegistry.shape_for(24, SEED) as SpaceShape
	if shape == null or shape.venus == null:
		return []
	var s := shape.venus.spawn()
	var top := VenusTerrain.DECK_Y + 18
	return region(24, Vector3i(s.x - 96, VenusTerrain.CLOUD_LOW - 2, s.y - 96), Vector3i(s.x + 96, top, s.y + 96),
		Vector3(s.x, VenusTerrain.DECK_Y, s.y))


## Wonder `id` of world 41, where the tour stands it (the tour's square at 0, its ground at y 0).
static func wonder(id: StringName) -> Array[Mesh]:
	var b := WonderBuilds.bounds(id)
	if b.is_empty():
		return []
	var lo: Vector3i = b[0]
	var hi: Vector3i = b[1]
	var margin := 8
	return region(EarthRules.WONDERS, Vector3i(lo.x - margin, WonderTour.BASE_Y - 6, lo.z - margin),
		Vector3i(hi.x + margin, hi.y + 2, hi.z + margin), Vector3(0, WonderTour.BASE_Y, 0))


## World `u`'s blocks from `lo` to `hi` (exclusive) as its generator makes them, meshed; `origin` (world space) is the
## meshes' 0. Kept for the run.
static func region(u: int, lo: Vector3i, hi: Vector3i, origin: Vector3) -> Array[Mesh]:
	var key := "%d:%s:%s" % [u, lo, hi]
	if _cache.has(key):
		return _cache[key]
	var gen := UniverseRegistry.generator_for(u, SEED)
	var c0 := Vector3i(floori(lo.x / float(CHUNK)), floori(lo.y / float(CHUNK)), floori(lo.z / float(CHUNK)))
	var c1 := Vector3i(floori((hi.x - 1) / float(CHUNK)), floori((hi.y - 1) / float(CHUNK)), floori((hi.z - 1) / float(CHUNK)))
	var base := c0 * CHUNK - Vector3i.ONE   # the big buffer's first voxel (one of padding)
	var size := (c1 - c0 + Vector3i.ONE) * CHUNK + Vector3i(2, 2, 2)
	var big := VoxelBuffer.new()
	big.create(size.x, size.y, size.z)
	var chunk := VoxelBuffer.new()
	chunk.create(CHUNK, CHUNK, CHUNK)
	for cx in range(c0.x, c1.x + 1):
		for cy in range(c0.y, c1.y + 1):
			for cz in range(c0.z, c1.z + 1):
				var at := Vector3i(cx, cy, cz) * CHUNK
				chunk.fill(0, CH)
				gen.generate_block(chunk, at, 0)
				big.copy_channel_from_area(chunk, Vector3i.ZERO, Vector3i(CHUNK, CHUNK, CHUNK), at - base, CH)
	var out: Array[Mesh] = []
	var inner := size - Vector3i(2, 2, 2)
	var tile := VoxelBuffer.new()
	tile.create(TILE + 2, TILE + 2, TILE + 2)
	for tx in range(0, inner.x, TILE):
		for ty in range(0, inner.y, TILE):
			for tz in range(0, inner.z, TILE):
				tile.fill(0, CH)
				var from := Vector3i(tx, ty, tz)
				var to := (from + Vector3i(TILE + 2, TILE + 2, TILE + 2)).min(size)
				tile.copy_channel_from_area(big, from, to, Vector3i.ZERO, CH)
				var mesh := Scene3DModels.mesher().build_mesh(tile, [], {})
				if mesh != null and mesh.get_surface_count() > 0:
					out.append(Scene3DModels._moved(mesh, Vector3(base + Vector3i.ONE + from) - origin))
	_cache[key] = out
	return out
