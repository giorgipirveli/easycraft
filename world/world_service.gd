class_name WorldService
extends Node3D
## The only way game code touches voxels. Wraps VoxelTerrain + VoxelTool.
## set_block is host-only: clients go through Session.request_set_block.

signal block_changed(pos: Vector3i, old_id: int, new_id: int)

const MIN_Y := -64
const MAX_Y := 192
const REALISTIC_SKY := "res://assets/sky/kloofendal_48d_partly_cloudy_puresky_1k.hdr"
## The visuals brief (docs/devlog/parts/visuals.md): the fog starts at this share of the view and is full at its end
## (the chunk edge hides in it), so far hills are soft and bluish, near ones clear.
const FOG_BEGIN := 0.45

static var _library: VoxelBlockyLibrary
## P5 (the research's P5 row): in a headset session a label drawn over everything (no_depth_test: a trader's sign, a quest
## bubble, seen over the hills) ends this far away (m): farther, the two eyes' depth fights the hill in front of it.
const VR_LABEL_FAR := 32.0


func _enter_tree() -> void:
	if GraphicsPreset.vr_session:   # P5: every label of the scene, now and while this world lives
		get_tree().node_added.connect(_on_node_added_vr)
		for l: Node in get_tree().root.find_children("*", "Label3D", true, false):
			vr_label_range(l as Label3D)


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added_vr):
		get_tree().node_added.disconnect(_on_node_added_vr)


func _on_node_added_vr(n: Node) -> void:
	if n is Label3D:
		vr_label_range.call_deferred(n)   # once its maker has set it up (no_depth_test is often set after add_child)


## P5: a no_depth_test label ends at VR_LABEL_FAR (a nearer range stays).
static func vr_label_range(l: Label3D) -> void:
	if not is_instance_valid(l) or not l.no_depth_test:
		return
	if l.visibility_range_end <= 0.0 or l.visibility_range_end > VR_LABEL_FAR:
		l.visibility_range_end = VR_LABEL_FAR


## The shared block model library (also used to mesh living buddies).
static func library() -> VoxelBlockyLibrary:
	if _library == null:
		_library = BlockLibrary.build()
	return _library

## The open-air look that Ambience starts from: sun and ambient energy, fog colour and distances.
var ambience_base := {}
## World sync by edits (M4 Wave 1 A): sends a host's edits to its guests, or puts the host's edits
## into a guest's world.
var sync: WorldSync
## The universe this world belongs to (M3 Task 5).
var universe := 1
## Universe 6 (the Glow Caves): the mood under a ceiling (UniverseRegistry.cave_mood; {} for the meadows' caves and
## Monster Wave's arena). Ambience applies it (GlowRules.mood); SkyCycle then leaves the ambient colour to Ambience.
var cave_mood := {}
## Owner #45b: the terrain version (WorldMeta.terrain), set before setup(); 1 = the old meadows.
var terrain_version := 1

var _terrain: VoxelTerrain
var _tool: VoxelTool
var _shape: MeadowsShape
var _blocky_sky: Material
## The style this world was asked for (M7: REALISTIC may wait for its pictures, RealisticPack).
var _style := ""
## P5: the child's graphics preset (apply_graphics): in a headset session `vr` shows blocky, `vr_plus` the child's style.
var _graphics := ""


## Call once, right after instancing and before the first frame.
## An empty world_dir means nothing is saved (menu backdrop, guests).
## A guest (is_client) generates the terrain from the seed like the host and gets only the host's
## edits (WorldSync; M4 Wave 1 A, spec §17.0).
## world_universe (M3 Task 5): the terrain's rules and generator come from that universe's descriptor
## (UniverseRegistry; Green Meadows' for universe 1 or a universe without one).
## arena (owner feedback #44, spec §12.20): Monster Wave's flat arena of that universe instead (ArenaShape,
## ArenaGenerator), for the host and its guests alike.
func setup(world_dir: String, world_seed: int, is_client: bool = false, world_universe: int = 1, arena: bool = false) -> void:
	universe = UniverseRules.valid(world_universe)
	_shape = ArenaShape.new(world_seed, universe) if arena else UniverseRegistry.shape_for(universe, world_seed, terrain_version)
	var mesher := VoxelMesherBlocky.new()
	mesher.library = library()
	mesher.occlusion_darkness = 0.75
	var generator := _arena_generator(world_seed) if arena else UniverseRegistry.generator_for(universe, world_seed, terrain_version)
	_terrain = SyncedTerrain.new()
	_terrain.name = "Terrain"
	_terrain.mesher = mesher
	var overlay: EditOverlay = null
	if is_client:
		overlay = EditOverlay.new()
		var edited := EditedGenerator.new()
		edited.base = generator
		edited.overlay = overlay
		_terrain.generator = edited
	else:
		_terrain.generator = generator
	if world_dir != "":
		var stream := VoxelStreamSQLite.new()
		DirAccess.make_dir_recursive_absolute(world_dir)
		stream.database_path = ProjectSettings.globalize_path(world_dir.path_join("voxels.sqlite"))
		_terrain.stream = stream
	_terrain.max_view_distance = 256
	# owner #101 (P5: 16 in a headset too, the vr preset; the menu's backdrop, no save folder and not a guest's: 32)
	_terrain.mesh_block_size = GraphicsPreset.mesh_block_size(world_dir == "" and not is_client)
	_terrain.bounds = AABB(Vector3(-536870000, MIN_Y, -536870000), Vector3(1073740000, MAX_Y - MIN_Y, 1073740000))
	add_child(_terrain)
	_tool = _terrain.get_voxel_tool()
	_tool.channel = VoxelBuffer.CHANNEL_TYPE
	# The scene's Environment (with its Sky) is one shared resource for every world instance. Each
	# world takes its own deep copy, so one world's cave mood, style or time of day never leaks into
	# the menu or the next world (found on the emulator: the menu's REALISTIC sky reached a BLOCKY game).
	var world_env: WorldEnvironment = $WorldEnvironment
	world_env.environment = world_env.environment.duplicate(true)
	var env := environment()
	_blocky_sky = env.sky.sky_material
	ambience_base = {"sun": sun().light_energy, "ambient": env.ambient_light_energy,
		"fog_color": env.fog_light_color, "fog_begin": env.fog_depth_begin, "fog_end": env.fog_depth_end,
		"ambient_color": env.ambient_light_color, "sky_share": env.ambient_light_sky_contribution}
	cave_mood = {} if arena else UniverseRegistry.cave_mood(universe)   # universe 6: the Glow Caves' dark
	if not is_client:   # the host simulates flowing water; guests receive the blocks
		var flow := WaterFlow.new()
		flow.name = "WaterFlow"
		flow.world = self
		add_child(flow)
	sync = WorldSync.new()
	sync.name = "WorldSync"
	sync.setup(self, is_client, generator, overlay)
	add_child(sync)


## Freeing a world while it streams blocked for 6-13 s on the desktop (M4 Wave 2 A2): Voxel Tools
## waits for every queued generation task (4,700 at a view distance of 128). Without viewers the
## queue is dropped within about 150 ms: stop_viewers(scene), await drain(), then free the world.
## Removes every VoxelViewer under root (freed at the end of the frame; nothing may use them
## afterwards); how many.
static func stop_viewers(root: Node) -> int:
	var viewers := root.find_children("*", "VoxelViewer", true, false)
	for v in viewers:
		v.queue_free()
	return viewers.size()


## Waits until Voxel Tools has no queued tasks, at most max_seconds.
static func drain(tree: SceneTree, max_seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while voxel_tasks() > 0 and Time.get_ticks_msec() < until:
		await tree.process_frame


## Tasks waiting in Voxel Tools' thread pool (generation, meshing, saving).
static func voxel_tasks() -> int:
	var pools: Dictionary = VoxelEngine.get_stats().get("thread_pools", {})
	return int((pools.get("general", {}) as Dictionary).get("tasks", 0))


func terrain() -> VoxelTerrain:
	return _terrain


func environment() -> Environment:
	return ($WorldEnvironment as WorldEnvironment).environment


func sun() -> DirectionalLight3D:
	return $Sun


func get_block(pos: Vector3i) -> int:
	return _tool.get_voxel(pos)


## A block_at(pos) -> int over one copy of the box [origin, origin + size): a single bulk read
## instead of one locked get_voxel per cell (the bed scan's 196 cells cost 3-7 ms per scan on the
## desktop that way; M1b acceptance run 1). Cells outside the box read as AIR; cells in blocks not
## loaded yet may read as generated terrain (get_block reads AIR there), never as a placed block.
func box_reader(origin: Vector3i, size: Vector3i) -> Callable:
	var buf := VoxelBuffer.new()
	buf.create(size.x, size.y, size.z)
	_tool.copy(origin, buf, 1 << VoxelBuffer.CHANNEL_TYPE)
	return func(p: Vector3i) -> int:
		var l := p - origin
		if l.x < 0 or l.y < 0 or l.z < 0 or l.x >= size.x or l.y >= size.y or l.z >= size.z:
			return BlockIds.AIR
		return buf.get_voxel(l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)


func set_block(pos: Vector3i, id: int) -> void:
	if not is_editable(pos):
		return   # not loaded: nothing would be written, so nothing may be announced
	var old := _tool.get_voxel(pos)
	if old == id:
		return
	_tool.set_voxel(pos, id)
	block_changed.emit(pos, old, id)


## Guest: a block the host changed (WorldSync). Not a game edit: nothing is announced.
func put_block(pos: Vector3i, id: int) -> void:
	_tool.set_voxel(pos, id)


func is_editable(pos: Vector3i) -> bool:
	return _tool.is_area_editable(AABB(Vector3(pos), Vector3.ONE))


## Cosmos (spec §21b.2): false for a world with its own sky (Mars): the realistic style keeps the painted sky, the
## photo sky being Earth's blue with white clouds (UniverseRegistry.photo_sky). Set before apply_style.
var photo_sky := true


## Graphics style: BLOCKY (pixel art, soft painted sky) or REALISTIC (CC0 photo textures with
## bumps, a real sky, glow and animated water). Instant: no remeshing.
## M7: REALISTIC before its pictures are in (a browser before the realistic pack) looks BLOCKY, and the world turns
## realistic by itself when they land (realistic_pictures_arrived).
func apply_style(style: String) -> void:
	_style = style
	add_to_group(RealisticPack.GROUP)
	style = GraphicsPreset.style_in_use(style, _graphics)   # owner #101: `vr` blocky; P5: `vr_plus` the child's
	BlockLibrary.set_style(style)
	var realistic := BlockLibrary.style == "realistic"
	var env := environment()
	if realistic and photo_sky:
		if not env.sky.sky_material is PanoramaSkyMaterial:   # a new sky re-bakes its radiance map
			var sky := PanoramaSkyMaterial.new()
			sky.panorama = load(REALISTIC_SKY)
			env.sky.sky_material = sky
	else:
		env.sky.sky_material = _blocky_sky
	env.glow_enabled = realistic and GraphicsPreset.glow_allowed(_graphics)   # P5: never in a headset (not stereo-safe)
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05


## M7: the realistic pack is in (RealisticPack.on_pack_loaded): a world that wants REALISTIC shows it now; a BLOCKY one
## changes nothing.
func realistic_pictures_arrived() -> void:
	if _style == "realistic":
		apply_style(_style)


## First block a tap ray stops at: water counts from above (build on it, remove it), but a ray
## that starts in water passes through water (build and dig underwater).
func raycast(origin: Vector3, dir: Vector3, max_dist: float) -> BlockHit:
	var from_water := get_block(Vector3i(origin.floor())) == BlockIds.WATER
	return GridRay.cast(origin, dir, max_dist, func(p: Vector3i) -> bool: return GridRay.stops_ray(get_block(p), from_water))


## The first-spawn column of a fresh world: dry land near the origin.
func spawn_column() -> Vector2i:
	return _shape.spawn_column()


## The generator's terrain rules (animal spawning uses them).
func generator_shape() -> MeadowsShape:
	return _shape


## Ground height from the generator (ignores player edits and trees).
func surface_height(x: int, z: int) -> int:
	return _shape.height_at(x, z)


## The height of the open sky's ground over (x, z): the roof's meadow in a roofed universe (universe 6, the Glow Caves:
## GlowShape.roof_at), else the ground. The caves' mood and stealth measure how deep under it a head is, so every
## cavern under the roof is underground however high its ceiling (Ambience, StealthDirector).
func sky_height(x: int, z: int) -> int:
	if _shape is GlowShape:
		return (_shape as GlowShape).roof_at(x, z)
	return _shape.height_at(x, z)


## Lowest y at (x, z), from the generated surface up, with room for a 2-block-tall player.
## Only meaningful once the column is loaded.
func find_standing_y(x: int, z: int) -> int:
	var start := maxi(surface_height(x, z), MeadowsShape.SEA_LEVEL)
	return SpawnRules.first_free_y(start, func(y: int) -> bool: return BlockIds.is_solid(get_block(Vector3i(x, y, z))), MAX_Y)


func is_area_ready(center: Vector3) -> bool:
	return _terrain.is_area_meshed(AABB(center - Vector3(8, 8, 8), Vector3(16, 16, 16)))


## Saves edited blocks (written in the background). M7: in a browser, WebStorage pushes them to the browser's storage
## once they are written (the SQLite stream's own writes don't).
func save() -> void:
	if _terrain and _terrain.stream:
		WebStorage.sync_when_written(_terrain.save_modified_blocks())


## Saves edited blocks and waits (up to timeout_s) until they are written (M7: then pushes them, in a browser).
func save_and_wait(timeout_s: float = 3.0) -> void:
	if _terrain == null or _terrain.stream == null:
		return
	var tracker := _terrain.save_modified_blocks()
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while tracker and not tracker.is_complete() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	WebStorage.sync()


## Shadows (graphics preset) and fog distance (view distance) from the profile settings.
func apply_graphics(settings: Dictionary) -> void:
	_graphics = str(settings.get("graphics", "medium"))
	var preset := GraphicsPreset.params(_graphics)
	var env := environment()
	sun().shadow_enabled = preset.shadows
	sun().directional_shadow_max_distance = maxf(preset.shadow_distance, 1.0)
	BlockLibrary.set_simple_water(bool(preset.simple_water))   # M5 Task 3: LOW
	if BlockLibrary.set_sway(GraphicsPreset.sways(settings)):   # the visuals brief: HIGH's leaves sway ...
		_library = null   # ... in the next world meshed (this one keeps its library)
	var view := GraphicsPreset.view_distance(settings)   # M5 Task 3: LOW sees 64 blocks at most
	env.fog_depth_begin = view * FOG_BEGIN
	env.fog_depth_end = float(view)
	ambience_base.fog_begin = env.fog_depth_begin
	ambience_base.fog_end = env.fog_depth_end

# --- M2 Task 15 ---

## One bulk copy of the box [origin, origin + size) (block ids), for searches of its bytes
## (BotRules.find_in_buffer): an explorer friend's look around costs one copy, not a call per cell.
func copy_box(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(size.x, size.y, size.z)
	if _tool:   # no terrain yet (or a stand-in world): an empty box, all air
		_tool.copy(origin, buf, 1 << VoxelBuffer.CHANNEL_TYPE)
	return buf


# --- M3 Task 2: the world's universe --------------------------------------------------------------------

## This world's universe descriptor (world/universes/<name>.gd, UniverseRegistry), null for Green Meadows:
## the sandbox's "M3 Task 2" section reads a universe's own monsters, boss, secrets, weather and traps.
func descriptor() -> Object:
	return UniverseRegistry.descriptor(universe) if universe > 1 else null

# --- M4 Wave 3, agent I: a friend's showcase to visit ---

## A world made by `generator` alone (a showcase visit: VisitGenerator), `half` blocks around the middle:
## nothing is saved, no WorldSync, no water flow; the visit never registers it with Session, so no edit
## request reaches it (read-only). Call once, right after instancing, instead of setup().
func setup_visit(generator: VoxelGenerator, shape: MeadowsShape, half: int) -> void:
	universe = 1
	_shape = shape
	var mesher := VoxelMesherBlocky.new()
	mesher.library = library()
	mesher.occlusion_darkness = 0.75
	_terrain = VoxelTerrain.new()
	_terrain.name = "Terrain"
	_terrain.mesher = mesher
	_terrain.generator = generator
	_terrain.max_view_distance = 256
	_terrain.mesh_block_size = GraphicsPreset.mesh_block_size()   # owner #101 (P5: 16 in a headset too, the vr preset)
	_terrain.bounds = AABB(Vector3(-half, MIN_Y, -half), Vector3(half * 2, MAX_Y - MIN_Y, half * 2))
	add_child(_terrain)
	_tool = _terrain.get_voxel_tool()
	_tool.channel = VoxelBuffer.CHANNEL_TYPE
	var world_env: WorldEnvironment = $WorldEnvironment
	world_env.environment = world_env.environment.duplicate(true)
	var env := environment()
	_blocky_sky = env.sky.sky_material
	ambience_base = {"sun": sun().light_energy, "ambient": env.ambient_light_energy,
		"fog_color": env.fog_light_color, "fog_begin": env.fog_depth_begin, "fog_end": env.fog_depth_end}

# --- Monster Wave (owner feedback #44, spec §12.20) --------------------------------------------------------

func _arena_generator(world_seed: int) -> ArenaGenerator:
	var g := ArenaGenerator.new()
	g.universe = universe
	g.world_seed = world_seed
	return g

# --- M3 Task 8: many cells at once (the building tools) ---------------------------------------------------------
# A cell read or written through the VoxelTool takes the voxel data's lock once; while the terrain meshes around the
# player (right after a big edit) each lock waited up to 40 µs in the building tools' smoke run, so a 4,096-block
# fill read and written cell by cell took 1.5-5 s. Cells that fill their box well enough are read with one copy and
# written with one copy and one paste instead; every changed cell is still announced (block_changed).

## A box is read or written whole when it holds at most this many cells per cell asked for (and at most BULK_MAX).
const BULK_SPREAD := 8
const BULK_MAX := 65536


## The blocks of `cells` ([Vector3i, ...]), in order.
func blocks_at(cells: Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(cells.size())
	var box := _bulk_box(cells)
	if box.is_empty():
		for i in cells.size():
			out[i] = get_block(cells[i])
		return out
	var lo: Vector3i = box[0]
	var buf := copy_box(lo, box[1])
	for i in cells.size():
		var l: Vector3i = cells[i] - lo
		out[i] = buf.get_voxel(l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)
	return out


## Writes [[pos, id], ...] and announces every cell that changed; returns them as [[pos, old, new], ...].
func set_blocks(changes: Array) -> Array:
	var out: Array = []
	var cells: Array = changes.map(func(c: Array) -> Vector3i: return c[0])
	var box := _bulk_box(cells)
	if box.is_empty() or not _tool.is_area_editable(AABB(Vector3(box[0]), Vector3(box[1]))):
		for c: Array in changes:
			var old := get_block(c[0])
			set_block(c[0], c[1])
			if old != c[1] and get_block(c[0]) == c[1]:
				out.append([c[0], old, c[1]])
		return out
	var lo: Vector3i = box[0]
	var buf := copy_box(lo, box[1])
	for c: Array in changes:
		var l: Vector3i = c[0] - lo
		var old := buf.get_voxel(l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)
		if old != c[1]:
			buf.set_voxel(c[1], l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)
			out.append([c[0], old, c[1]])
	if not out.is_empty():
		_tool.paste(lo, buf, 1 << VoxelBuffer.CHANNEL_TYPE)
		for e: Array in out:
			block_changed.emit(e[0], e[1], e[2])
	return out


## [lowest corner, size] of the box `cells` fill well enough to be read or written whole; [] for cell by cell (no
## terrain: a stand-in world in tests reads its own cells).
func _bulk_box(cells: Array) -> Array:
	if _tool == null or cells.size() < 2:
		return []
	var lo: Vector3i = cells[0]
	var hi: Vector3i = cells[0]
	for c: Vector3i in cells:
		lo = lo.min(c)
		hi = hi.max(c)
	var size := hi - lo + Vector3i.ONE
	var volume := size.x * size.y * size.z
	if volume > BULK_MAX or volume > cells.size() * BULK_SPREAD:
		return []
	return [lo, size]
