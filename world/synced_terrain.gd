class_name SyncedTerrain
extends VoxelTerrain
## The world's VoxelTerrain (M4 Wave 1 A, spec §17.0). On the host it says when a chunk (a 16³ data
## block) comes into a guest's view: the host streams data around each guest's player with a
## VoxelViewer that carries the guest's peer id and asks for block notifications (Player._ready),
## and WorldSync then sends the guest that chunk's edits. `edited` is Voxel Tools' own flag: the
## chunk was changed this session or loaded from the save (so it may differ from the generator).

signal chunk_entered(peer_id: int, chunk: Vector3i, edited: bool)


func _on_data_block_entered(info: VoxelDataBlockEnterInfo) -> void:
	var peer := info.get_network_peer_id()
	if peer > 1 and info.get_lod_index() == 0:
		chunk_entered.emit(peer, info.get_position(), info.are_voxels_edited())
