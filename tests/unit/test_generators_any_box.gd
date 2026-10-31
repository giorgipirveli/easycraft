extends GutTest
## Found by the acceptance smoke runs (2026-09-25): VoxelTool.copy over ground that is not loaded yet (WorldService
## .copy_box: the stealth light, a bot's look around, COPY) asks a world's generator for a box of any size and place.
## Every universe's generator gives each cell of such a box exactly what its chunk has, with no script error.

const CH := VoxelBuffer.CHANNEL_TYPE
const BOXES: Array = [[Vector3i(-5, 20, 7), Vector3i(9, 9, 9)], [Vector3i(3, -40, -21), Vector3i(33, 7, 5)],
	[Vector3i(-17, 2, -3), Vector3i(5, 30, 18)]]


func _generators() -> Array:
	var out: Array = []
	for g: VoxelGenerator in [MeadowsGenerator.new(), MeadowsBiomeGenerator.new(), DesertGenerator.new(),
			FrostGenerator.new(), CandyGenerator.new(), DragonGenerator.new()]:
		g.set("world_seed", 777)
		out.append(g)
	return out


func test_every_generator_fills_any_box_like_its_chunks() -> void:
	for g: VoxelGenerator in _generators():
		for box: Array in BOXES:
			var origin: Vector3i = box[0]
			var size: Vector3i = box[1]
			var buf := VoxelBuffer.new()
			buf.create(size.x, size.y, size.z)
			g.call("_generate_block", buf, origin, 0)
			var chunks := {}
			var wrong := 0
			for z in size.z:
				for y in size.y:
					for x in size.x:
						var p := origin + Vector3i(x, y, z)
						var key := Vector3i(floori(p.x / 16.0) * 16, origin.y, floori(p.z / 16.0) * 16)
						if not chunks.has(key):
							var c := VoxelBuffer.new()
							c.create(16, size.y, 16)
							g.call("_generate_block", c, key, 0)
							chunks[key] = c
						if buf.get_voxel(x, y, z, CH) != (chunks[key] as VoxelBuffer).get_voxel(p.x - key.x, y, p.z - key.z, CH):
							wrong += 1
			assert_eq(wrong, 0, "%s: a %s box at %s" % [g.get_script().get_global_name(), size, origin])
	assert_eq(get_errors().size(), 0, "no script errors")
