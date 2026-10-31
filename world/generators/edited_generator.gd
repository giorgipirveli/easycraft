class_name EditedGenerator
extends VoxelGeneratorScript
## A guest's terrain generator (M4 Wave 1 A, spec §17.0): the host's generator for the same seed,
## then the host's edits (EditOverlay) written over it. Runs on worker threads like the base.

var base: VoxelGenerator
var overlay: EditOverlay


func _get_used_channels_mask() -> int:
	return 1 << VoxelBuffer.CHANNEL_TYPE


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	base.generate_block(out_buffer, origin, lod)
	if lod == 0 and overlay != null:
		overlay.apply(out_buffer, origin)
