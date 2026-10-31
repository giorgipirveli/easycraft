extends VoxelGeneratorScript
## Throwaway spike generator: noise heightmap, stone with a grass top.

const CHANNEL := VoxelBuffer.CHANNEL_TYPE
const GRASS := 1
const STONE := 2

var _noise := FastNoiseLite.new()


func _init() -> void:
	_noise.seed = 1234
	_noise.frequency = 0.01


func _get_used_channels_mask() -> int:
	return 1 << CHANNEL


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	for z in size.z:
		for x in size.x:
			var h := int(30.0 + 12.0 * _noise.get_noise_2d(origin.x + x, origin.z + z))
			var top_local := h - 1 - origin.y
			if top_local < 0:
				continue
			if top_local >= size.y:
				out_buffer.fill_area(STONE, Vector3i(x, 0, z), Vector3i(x + 1, size.y, z + 1), CHANNEL)
			else:
				if top_local > 0:
					out_buffer.fill_area(STONE, Vector3i(x, 0, z), Vector3i(x + 1, top_local, z + 1), CHANNEL)
				out_buffer.set_voxel(GRASS, x, top_local, z, CHANNEL)
