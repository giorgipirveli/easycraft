class_name ShowcaseArea
extends RefCounted
## "My showcase" (M4 Wave 3, agent I; spec §17.5, research T3): the one build area a child shows to
## friends, as a read-only snapshot on the server (publish_showcase). The area is SIDE x HEIGHT x SIDE
## around where the child stands, from BELOW blocks under the feet (a build a little downhill comes too)
## up; everything in it comes, the ground too. Its layer GROUND_LAYER is the ground the child stood on:
## the visit world lays that layer on its own grass. A buddy of the child standing inside waves for
## visitors (its blocks and its place; no name travels, the game names it from its blocks).

const SIDE := 32
const HALF := 16          # SIDE / 2
const HEIGHT := 32
const BELOW := 8          # layers under the feet
const GROUND_LAYER := BELOW - 1   # the layer the child stood on


## {"origin": lowest corner, "size"} of the area around feet (inside the world's height).
static func box_around(feet: Vector3) -> Dictionary:
	var f := Vector3i(feet.floor())
	var y := clampi(f.y - BELOW, WorldService.MIN_Y, WorldService.MAX_Y - HEIGHT)
	return {"origin": Vector3i(f.x - HALF, y, f.z - HALF), "size": Vector3i(SIDE, HEIGHT, SIDE)}


## The area's build text, read cell by cell through block_at(pos) -> id (items and bedrock are air).
static func snapshot(origin: Vector3i, size: Vector3i, block_at: Callable) -> String:
	var cells := PackedInt32Array()
	cells.resize(size.x * size.y * size.z)
	var i := 0
	for y in size.y:
		for z in size.z:
			for x in size.x:
				cells[i] = int(block_at.call(origin + Vector3i(x, y, z)))
				i += 1
	return BuildCodec.encode_cells(size, cells)


## The same from one bulk copy of the area (WorldService.copy_box): the game's way. Reads the copy's
## bytes (16-bit little-endian, index y + sy * (x + sx * z)), not a call per cell; safe on a worker thread
## (the copy is the caller's own).
static func snapshot_buffer(buf: VoxelBuffer) -> String:
	var size := buf.get_size()
	var cells := PackedInt32Array()
	cells.resize(size.x * size.y * size.z)
	if buf.is_uniform(VoxelBuffer.CHANNEL_TYPE):
		cells.fill(buf.get_voxel(0, 0, 0, VoxelBuffer.CHANNEL_TYPE))
		return BuildCodec.encode_cells(size, cells)
	buf.decompress_channel(VoxelBuffer.CHANNEL_TYPE)
	var bytes := buf.get_channel_as_byte_array(VoxelBuffer.CHANNEL_TYPE)
	var wide := buf.get_channel_depth(VoxelBuffer.CHANNEL_TYPE) == VoxelBuffer.DEPTH_16_BIT
	var i := 0
	for y in size.y:
		for z in size.z:
			for x in size.x:
				var v := y + size.y * (x + size.x * z)
				cells[i] = (bytes[v * 2] | (bytes[v * 2 + 1] << 8)) if wide else bytes[v]
				i += 1
	return BuildCodec.encode_cells(size, cells)


## "" when the server will take it, else "too_detailed" (over its text cap) or "empty".
static func problem(text: String) -> String:
	if text.length() > int(BuildCodec.SHOWCASE.max_text):
		return "too_detailed"
	return "" if BuildCodec.count_of(text) > 0 else "empty"


## The snapshot of the area off the main thread (a 32^3 copy read cell by cell costs about 100 ms here,
## several times that on a phone): the copy is made now, the reading on a worker; awaits the text.
static func snapshot_async(tree: SceneTree, buf: VoxelBuffer) -> String:
	var out := [""]
	var task := WorkerThreadPool.add_task(func() -> void: out[0] = snapshot_buffer(buf))
	while not WorkerThreadPool.is_task_completed(task):
		await tree.process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	return out[0]


## A buddy standing at `pos` (its feet, the middle of its bottom) inside the area, as the server keeps
## it: {"build", "at": [x, y, z] in the area}; {} when it is outside or too big.
static func buddy_entry(blocks: Dictionary, pos: Vector3, origin: Vector3i, size: Vector3i) -> Dictionary:
	var at := Vector3i(pos.floor()) - origin
	if at.x < 0 or at.y < 0 or at.z < 0 or at.x >= size.x or at.y >= size.y or at.z >= size.z:
		return {}
	var text := BuildCodec.encode(blocks)
	if BuildCodec.decode(text, BuildCodec.BUDDY).is_empty():
		return {}
	return {"build": text, "at": [at.x, at.y, at.z]}


## The entry of the buddy nearest `center` among [{"blocks", "pos"}] inside the area, or {}.
static func nearest_buddy(buddies: Array, center: Vector3, box: Dictionary) -> Dictionary:
	var best := {}
	var best_d := INF
	for b: Dictionary in buddies:
		var entry := buddy_entry(b.blocks, b.pos, box.origin, box.size)
		var d := (b.pos as Vector3).distance_squared_to(center)
		if not entry.is_empty() and d < best_d:
			best = entry
			best_d = d
	return best


static func message(code: String) -> String:
	match code:
		"too_detailed":
			return "So many tiny details! Stand somewhere with a little less around you."
		"empty":
			return "There is nothing here to show yet. Build something first!"
	return ""
