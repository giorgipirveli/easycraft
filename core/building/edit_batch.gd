class_name EditBatch
extends RefCounted
## Host-side cleanup of a batch of edits from the network: [[Vector3i, id], ...].
## Malformed entries are dropped (never crash the host) and the batch is capped.

const MAX_BATCH := 1600   # the biggest stamp, mirrored, fits (see test_water_and_batches.gd)


static func sanitize(changes: Array, max_count: int = MAX_BATCH) -> Array:
	var clean: Array = []
	for entry: Variant in changes:
		if clean.size() >= max_count:
			break
		if not entry is Array or (entry as Array).size() != 2:
			continue
		var pos: Variant = entry[0]
		var id: Variant = entry[1]
		if typeof(pos) != TYPE_VECTOR3I or typeof(id) != TYPE_INT:
			continue
		if id != BlockIds.AIR and not BlockIds.is_valid(id):
			continue
		clean.append([pos, id])
	return clean
