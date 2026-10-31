class_name ArenaGenerator
extends VoxelGeneratorScript
## Monster Wave's arena terrain for VoxelTerrain (owner feedback #44, spec §12.20; runs on worker threads): the
## flat layers of ArenaShape as whole-slab fills, then its cover column by column. ArenaShape.block_at is the
## reference this must match (tested chunk by chunk).

const CH := VoxelBuffer.CHANNEL_TYPE

@export var world_seed := 0:
	set(value):
		world_seed = value
		_shape = ArenaShape.new(value, universe)
@export var universe := 1:
	set(value):
		universe = value
		_shape = ArenaShape.new(world_seed, value)

var _shape := ArenaShape.new(0, 1)


func _get_used_channels_mask() -> int:
	return 1 << CH


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	if origin.y >= ArenaShape.FLOOR + ArenaShape.COVER_HIGH:
		return   # sky
	var bed := ArenaShape.FLOOR - ArenaShape.DEPTH
	if origin.y + size.y <= bed:
		out_buffer.fill(BlockIds.STONE, CH)   # deep under the arena: solid, never seen
		return
	for y in range(maxi(origin.y, bed - 1), mini(origin.y + size.y, ArenaShape.FLOOR)):
		var id := _shape.column_block(y, ArenaShape.FLOOR, bed)
		var ly := y - origin.y
		out_buffer.fill_area(id, Vector3i(0, ly, 0), Vector3i(size.x, ly + 1, size.z), CH)
	if origin.y < bed - 1:   # under the bedrock: stone (the loop above began at bed - 1)
		out_buffer.fill_area(BlockIds.STONE, Vector3i.ZERO, Vector3i(size.x, bed - 1 - origin.y, size.z), CH)
	var y0 := maxi(origin.y, ArenaShape.FLOOR)
	var y1 := mini(origin.y + size.y, ArenaShape.FLOOR + ArenaShape.COVER_HIGH)
	if y0 >= y1:
		return
	for z in size.z:
		for x in size.x:
			var c := _shape.cover_at(origin.x + x, origin.z + z)
			if c == BlockIds.AIR:
				continue
			for y in range(y0, y1):
				out_buffer.set_voxel(c, x, y - origin.y, z, CH)
