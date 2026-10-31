class_name VisitGenerator
extends VoxelGeneratorScript
## The small world of a showcase visit (M4 Wave 3, agent I; spec §17.5, research T3): a flat grass
## island (ISLAND blocks around the middle, a ring of sand) in a calm sea, with the friend's showcase
## standing in the middle: its ground layer (ShowcaseArea.GROUND_LAYER, what the friend stood on) lies on
## the island's grass layer; at and under it, where the showcase has air, the island's own ground stays
## (a showcase never leaves a hole in the island). Everything is a function of the cell, so it runs on
## Voxel Tools' worker threads; nothing is ever saved or edited.

const GROUND_TOP := 30          # the grass layer's y (above MeadowsShape.SEA_LEVEL, as the player expects)
const ISLAND := 40              # grass within this many blocks of the middle
const BEACH := 4                # then sand
const DEPTH := 6                # dirt under the grass, then stone, down to GROUND_TOP - DEPTH - 4

## The showcase: its cells (BuildCodec's order: x fastest, then z, then y) and where its lowest corner
## sits (the middle of the island, its bottom layer at GROUND_TOP).
var cells := PackedInt32Array()
var size := Vector3i.ZERO
var origin := Vector3i.ZERO


## The showcase of a build text (a broken one leaves the island empty).
func setup(build: String) -> void:
	var blocks := BuildCodec.decode(build, BuildCodec.SHOWCASE)
	size = BuildCodec.size_of(build) if not blocks.is_empty() else Vector3i.ZERO
	cells = PackedInt32Array()
	cells.resize(size.x * size.y * size.z)
	cells.fill(BlockIds.AIR)
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		cells[p.x + size.x * (p.z + size.z * p.y)] = id if BlockIds.is_valid(id) else BlockIds.AIR
	origin = Vector3i(-floori(size.x / 2.0), GROUND_TOP - ground_layer(), -floori(size.z / 2.0))


func _get_used_channels_mask() -> int:
	return 1 << VoxelBuffer.CHANNEL_TYPE


func _generate_block(out_buffer: VoxelBuffer, at: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var n := out_buffer.get_size()
	if at.y > origin.y + maxi(size.y, 1) or at.y + n.y <= mini(origin.y, GROUND_TOP - DEPTH - 4):
		return   # sky or deep below: air
	for z in n.z:
		for x in n.x:
			var wx := at.x + x
			var wz := at.z + z
			for y in n.y:
				var id := block_at(Vector3i(wx, at.y + y, wz))
				if id != BlockIds.AIR:
					out_buffer.set_voxel(id, x, y, z, VoxelBuffer.CHANNEL_TYPE)


## The island's block at `p` (the showcase included): the pure rule the terrain is made of.
func block_at(p: Vector3i) -> int:
	var l := p - origin
	if l.x >= 0 and l.y >= 0 and l.z >= 0 and l.x < size.x and l.y < size.y and l.z < size.z:
		var id := cells[l.x + size.x * (l.z + size.z * l.y)]
		if id != BlockIds.AIR or l.y > ground_layer():
			return id
	return ground_at(p)


static func ground_at(p: Vector3i) -> int:
	var d := maxi(absi(p.x), absi(p.z))
	if p.y > GROUND_TOP or p.y < GROUND_TOP - DEPTH - 4:
		return BlockIds.AIR
	if d > ISLAND + BEACH:
		return BlockIds.WATER if p.y == GROUND_TOP else BlockIds.SAND
	if d > ISLAND:
		return BlockIds.SAND
	if p.y == GROUND_TOP:
		return BlockIds.GRASS
	return BlockIds.DIRT if p.y > GROUND_TOP - DEPTH else BlockIds.STONE


## The showcase's layer that lies on the island's grass: ShowcaseArea's ground layer (a showcase lower
## than that, a small test build, lies with its bottom layer on the grass).
func ground_layer() -> int:
	return ShowcaseArea.GROUND_LAYER if size.y > ShowcaseArea.GROUND_LAYER else 0
