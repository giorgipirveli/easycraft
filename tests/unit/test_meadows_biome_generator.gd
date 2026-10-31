extends GutTest
## Owner feedback #45b (spec §14.18): the wild meadows' generator (terrain version 2). It writes MeadowsBiomeShape's
## columns (biomes, rivers, islands, snowy tops, flowers, lily pads), the old caves and ores with the new cave
## regions (glowing mushroom caves, underground lakes), the biomes' trees and the secrets; a chunk column's
## heights and biomes are worked out once for its whole stack of chunks. reference_block is its slow one-block
## rule; chunks meet without seams; it costs no more per chunk than the old meadows.

const CH := VoxelBuffer.CHANNEL_TYPE
const SEED := 12345

var gen: MeadowsBiomeGenerator
var shape: MeadowsBiomeShape


func before_all() -> void:
	gen = MeadowsBiomeGenerator.new()
	gen.world_seed = SEED
	shape = gen.wild_shape()


func _generate(g: MeadowsGenerator, origin: Vector3i) -> VoxelBuffer:
	var buf := VoxelBuffer.new()
	buf.create(16, 16, 16)
	g._generate_block(buf, origin, 0)
	return buf


func _tree_near(x: int, z: int) -> bool:
	var r := MeadowsBiomeGenerator.WILD_TREE_REACH
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if shape.tree_at(x + dx, z + dz):
				return true
	return false


## A column of `biome` near the origin (searched on a grid), or (0, -9999).
func _find(biome: int, flag: int = 0, from: int = 0) -> Vector2i:
	for r in range(from, 3000, 24):
		for a in 16:
			var p := Vector2i(roundi(cos(TAU * a / 16.0) * r), roundi(sin(TAU * a / 16.0) * r))
			var c := shape.column(p.x, p.y)
			if c.y == biome and (flag == 0 or c.z & flag):
				return p
	return Vector2i(0, -9999)


func _chunk_at(x: int, y: int, z: int) -> Vector3i:
	return Vector3i(floori(x / 16.0), floori(y / 16.0), floori(z / 16.0)) * 16


func _count(buf: VoxelBuffer, ids: Array) -> int:
	var n := 0
	for y in 16:
		for z in 16:
			for x in 16:
				if buf.get_voxel(x, y, z, CH) in ids:
					n += 1
	return n


# --- The fast path is the reference ---

## The fast path (whole columns, the column cache, the old carving, the cave regions) equals the slow
## per-block reference everywhere trees don't reach (giant mushrooms are left out, like trees).
func test_chunks_match_the_reference_block_rule() -> void:
	gen.giant_mushrooms = false
	var origins: Array[Vector3i] = [Vector3i(0, -48, 0), Vector3i(32, -16, -48), Vector3i(-64, -64, 16), Vector3i(16, 16, 16),
		Vector3i(0, 48, 0), Vector3i(-32, 32, 64)]
	for biome in [MeadowsBiomeShape.SWAMP, MeadowsBiomeShape.MOUNTAIN, MeadowsBiomeShape.FLOWERS, MeadowsBiomeShape.ISLAND,
			MeadowsBiomeShape.RIVER]:
		var p := _find(biome)
		assert_ne(p.y, -9999, MeadowsBiomeShape.BIOME_NAMES[biome])
		origins.append(_chunk_at(p.x, shape.height_at(p.x, p.y) - 1, p.y))
	for kind in [MeadowsBiomeShape.MUSHROOM_CAVES, MeadowsBiomeShape.LAKE_CAVES]:
		var region := _region(kind)
		for y in [-48, -32]:
			origins.append(Vector3i(region.x, y, region.y))
	var bad := 0
	for origin: Vector3i in origins:
		var buf := _generate(gen, origin)
		for z in 16:
			for x in 16:
				if _tree_near(origin.x + x, origin.z + z):
					continue
				for y in 16:
					var w := origin + Vector3i(x, y, z)
					var want := gen.reference_block(w.x, w.y, w.z)
					if buf.get_voxel(x, y, z, CH) != want:
						bad += 1
						if bad < 4:
							assert_eq(buf.get_voxel(x, y, z, CH), want, "block at %s" % w)
	assert_eq(bad, 0, "blocks that differ from the reference")
	gen.giant_mushrooms = true


## The first chunk-aligned corner (x, z) of a region of the cave kind.
func _region(kind: int) -> Vector2i:
	for r in 40:
		for rx in range(-r, r + 1):
			for rz in [-r, r]:
				var p := Vector2i(rx, rz) * MeadowsBiomeShape.CAVE_REGION
				if shape.cave_region(p.x, p.y) == kind:
					return p + Vector2i(48, 48)
	return Vector2i.ZERO


func test_the_column_cache_changes_nothing() -> void:
	var cold := MeadowsBiomeGenerator.new()
	cold.world_seed = SEED
	cold.columns_cached = false
	for origin: Vector3i in [Vector3i(0, 16, 0), Vector3i(-48, 32, 80), Vector3i(160, 0, -32), Vector3i(0, -32, 0)]:
		var a := _generate(gen, origin)
		var b := _generate(cold, origin)
		for y in 16:
			for z in 16:
				for x in 16:
					if a.get_voxel(x, y, z, CH) != b.get_voxel(x, y, z, CH):
						assert_eq(a.get_voxel(x, y, z, CH), b.get_voxel(x, y, z, CH), "%s" % (origin + Vector3i(x, y, z)))
						return


## Chunks overlapping by half a chunk agree on every block, trees and flowers included (a tree next to a chunk's
## edge is written by both chunks alike).
func test_chunks_meet_without_seams() -> void:
	gen.giant_mushrooms = false
	var p := _find(MeadowsBiomeShape.DARK)
	var y := shape.height_at(p.x, p.y)
	for pair: Array in [[_chunk_at(p.x, y, p.y), Vector3i(8, 0, 0)], [_chunk_at(p.x, y, p.y), Vector3i(0, 0, 8)],
			[_chunk_at(p.x, y, p.y), Vector3i(0, 8, 0)], [Vector3i(0, -32, 0), Vector3i(8, 8, 0)]]:
		var o: Vector3i = pair[0]
		var d: Vector3i = pair[1]
		var a := _generate(gen, o)
		var b := _generate(gen, o + d)
		for yy in range(d.y, 16):
			for z in range(d.z, 16):
				for x in range(d.x, 16):
					if a.get_voxel(x, yy, z, CH) != b.get_voxel(x - d.x, yy - d.y, z - d.z, CH):
						assert_eq(a.get_voxel(x, yy, z, CH), b.get_voxel(x - d.x, yy - d.y, z - d.z, CH), "at %s" % (o + Vector3i(x, yy, z)))
						gen.giant_mushrooms = true
						return
	gen.giant_mushrooms = true


# --- What the biomes look like in the chunks ---

func test_the_biomes_are_in_the_chunks() -> void:
	var want := {
		MeadowsBiomeShape.BIRCH: [BlockIds.BIRCH_LOG, BlockIds.BIRCH_LEAVES],
		MeadowsBiomeShape.DARK: [BlockIds.DARK_LOG, BlockIds.DARK_LEAVES],
		MeadowsBiomeShape.FLOWERS: [BlockIds.FLOWERS],
		MeadowsBiomeShape.SWAMP: [BlockIds.MUD],
		MeadowsBiomeShape.BEACH: [BlockIds.SAND],
	}
	for biome: int in want:
		var p := _find(biome)
		var found := 0
		for d: Vector2i in [Vector2i.ZERO, Vector2i(16, 0), Vector2i(0, 16), Vector2i(-16, 0), Vector2i(0, -16)]:
			var q := p + d
			var h := shape.height_at(q.x, q.y)
			for dy in [-16, 0, 16]:
				found += _count(_generate(gen, _chunk_at(q.x, h + dy, q.y)), want[biome])
		assert_gt(found, 0, "%s: %s" % [MeadowsBiomeShape.BIOME_NAMES[biome], want[biome]])
	var snowy := Vector2i(0, -9999)
	for r in range(0, 4000, 16):
		for a in 24:
			var q := Vector2i(roundi(cos(TAU * a / 24.0) * r), roundi(sin(TAU * a / 24.0) * r))
			if shape.height_at(q.x, q.y) >= MeadowsBiomeShape.SNOW_LINE + 3:
				snowy = q
				break
		if snowy.y != -9999:
			break
	assert_ne(snowy.y, -9999, "a snowy top near the spawn")
	var top := shape.height_at(snowy.x, snowy.y) - 1
	assert_gt(_count(_generate(gen, _chunk_at(snowy.x, top, snowy.y)), [BlockIds.SNOW]), 0, "snow on the top")
	var pads := 0
	var swamp := _find(MeadowsBiomeShape.SWAMP, MeadowsBiomeShape.F_LILY)
	assert_ne(swamp.y, -9999, "a lily pad near the spawn")
	pads += _count(_generate(gen, _chunk_at(swamp.x, MeadowsShape.SEA_LEVEL, swamp.y)), [BlockIds.LILY_PAD])
	assert_gt(pads, 0, "lily pads on the swamp's pools")


func test_mushroom_caves_glow_and_lake_caves_are_flooded() -> void:
	var glow := 0
	var mud := 0
	var giants := 0
	var region := _region(MeadowsBiomeShape.MUSHROOM_CAVES)
	for cx in range(-2, 3):
		for cz in range(-2, 3):
			for y in [-64, -48, -32]:
				var buf := _generate(gen, Vector3i(region.x + cx * 16, y, region.y + cz * 16))
				glow += _count(buf, [BlockIds.GLOW_MUSHROOM])
				mud += _count(buf, [BlockIds.MUD])
				giants += _count(buf, [BlockIds.PLASTER])
	gut.p("a mushroom region's caves: %d glowing caps, %d mud, %d stem blocks" % [glow, mud, giants])
	assert_gt(glow, 20, "glowing caps")
	assert_gt(mud, 100, "a mud floor")
	assert_gt(giants, 0, "giant mushrooms")
	var lake := _region(MeadowsBiomeShape.LAKE_CAVES)
	var water := 0
	var crystals_in_lakes := 0
	for cx in range(-2, 3):
		for cz in range(-2, 3):
			var buf := _generate(gen, Vector3i(lake.x + cx * 16, -32, lake.y + cz * 16))   # y -32..-17
			for y in range(0, MeadowsBiomeGenerator.LAKE_Y + 32):
				for z in 16:
					for x in 16:
						if buf.get_voxel(x, y, z, CH) == BlockIds.WATER:
							water += 1
			crystals_in_lakes += _count(buf, [BlockIds.GLOW_MUSHROOM])
	assert_gt(water, 50, "the deep caverns of a lake region are flooded above the old flood line (-40)")
	assert_eq(crystals_in_lakes, 0, "no glowing caps outside mushroom regions")
	for y in [-48, -32]:
		assert_eq(_count(_generate(gen, Vector3i(0, y, 0)), [BlockIds.GLOW_MUSHROOM]) if shape.cave_region(0, 0) != MeadowsBiomeShape.MUSHROOM_CAVES else 0, 0)


func test_secret_structures_are_generated_in_the_wild_meadows() -> void:
	var rules := SecretRules.new(SEED, shape)
	var checked := 0
	for az in range(-2, 2):
		for ax in range(-2, 2):
			for s: Dictionary in rules.secrets_in_area(Vector2i(ax, az)):
				if s.kind != SecretRules.TEMPLE and s.kind != SecretRules.ROOM:
					continue
				var cell: Vector3i = s.chest if s.has("chest") else s.anchor
				var origin := _chunk_at(cell.x, cell.y, cell.z)
				var buf := _generate(gen, origin)
				var want := rules.block_at(cell)
				if want >= 0:
					assert_eq(buf.get_voxel(cell.x - origin.x, cell.y - origin.y, cell.z - origin.z, CH), want, s.id)
					checked += 1
	assert_gt(checked, 0, "secrets in the wild meadows")


# --- The old meadows stay as they were ---

func test_the_old_generator_is_untouched() -> void:
	var old := MeadowsGenerator.new()
	old.world_seed = SEED
	assert_false(old is MeadowsBiomeGenerator)
	assert_true(old._shape.get_script() == MeadowsShape)
	var a := _generate(old, Vector3i(0, 16, 0))
	var b := _generate(gen, Vector3i(0, 16, 0))
	var differs := 0
	for y in 16:
		for z in 16:
			for x in 16:
				if a.get_voxel(x, y, z, CH) != b.get_voxel(x, y, z, CH):
					differs += 1
	assert_gt(differs, 0, "the wild meadows are a new terrain")


# --- Cost ---

## The wild meadows cost no more per chunk than the old meadows (the brief's bar), on the same chunks, the two
## generators alternating chunk by chunk (a busy PC slows both alike): whole stacks of chunk columns, the way a
## world generates them. tools/bench_generator.gd -- --biomes measures it in full.
func test_a_chunk_costs_no_more_than_the_old_meadows() -> void:
	var old := MeadowsGenerator.new()
	old.world_seed = SEED + 7
	var wild := MeadowsBiomeGenerator.new()
	wild.world_seed = SEED + 7
	var best := INF
	for round in 3:
		var t_old := 0
		var t_wild := 0
		var n := 0
		for cx in range(round * 3, round * 3 + 3):
			for cz in range(-1, 2):
				for cy in range(-4, 8):
					var origin := Vector3i(cx, cy, cz) * 16 + Vector3i(4000, 0, 0)
					for which in ([old, wild] if n % 2 == 0 else [wild, old]):
						var buf := VoxelBuffer.new()
						buf.create(16, 16, 16)
						var t := Time.get_ticks_usec()
						which._generate_block(buf, origin, 0)
						if which == old:
							t_old += Time.get_ticks_usec() - t
						else:
							t_wild += Time.get_ticks_usec() - t
					n += 1
		best = minf(best, t_wild / float(maxi(t_old, 1)))
		gut.p("round %d: old %.2f ms, wild %.2f ms per chunk" % [round, t_old / 1000.0 / n, t_wild / 1000.0 / n])
		if best <= 1.0:
			break
	assert_lte(best, 1.0, "the wild meadows / the old meadows per chunk: %.2f" % best)


# --- Places (MeadowsPlaces) ---

## Every block a place puts somewhere is in the generated chunks, whichever chunk it falls in: one place of each
## kind, written piece by piece without seams.
func test_places_are_generated_without_seams() -> void:
	var done := {}
	for r in 9:
		for rz in range(-r, r + 1):
			for rx in range(-r, r + 1):
				if maxi(absi(rx), absi(rz)) != r:
					continue
				for p: Dictionary in gen.places.places_in_region(Vector2i(rx, rz)):
					if done.has(p.kind):
						continue
					done[p.kind] = true
					_check_place(p)
	assert_eq(done.size(), MeadowsPlaces.KINDS.size(), "one of each kind checked: %s" % str(done.keys()))


func _check_place(p: Dictionary) -> void:
	var lo: Vector3i = p.lo
	var hi: Vector3i = p.hi
	var c0 := Vector3i(floori(lo.x / 16.0), floori(lo.y / 16.0), floori(lo.z / 16.0))
	var c1 := Vector3i(floori((hi.x - 1) / 16.0), floori((hi.y - 1) / 16.0), floori((hi.z - 1) / 16.0))
	var checked := 0
	var bad := 0
	var leaves := 0
	for cz in range(c0.z, c1.z + 1):
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var origin := Vector3i(cx, cy, cz) * 16
				var buf := _generate(gen, origin)
				var a := lo.max(origin)
				var b := hi.min(origin + Vector3i(16, 16, 16))
				for z in range(a.z, b.z):
					for y in range(a.y, b.y):
						for x in range(a.x, b.x):
							var got := buf.get_voxel(x - origin.x, y - origin.y, z - origin.z, CH)
							if got in [BlockIds.LEAVES, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LEAVES]:
								leaves += 1
							var want := gen.places.block_at(Vector3i(x, y, z))
							if want < 0 or gen._secrets.block_at(Vector3i(x, y, z)) >= 0:
								continue
							checked += 1
							if buf.get_voxel(x - origin.x, y - origin.y, z - origin.z, CH) != want:
								bad += 1
								if bad < 3:
									assert_eq(buf.get_voxel(x - origin.x, y - origin.y, z - origin.z, CH), want, "%s at %s" % [p.id, Vector3i(x, y, z)])
	assert_gt(checked, 0, p.id)
	assert_eq(bad, 0, p.id)
	assert_eq(leaves, 0, "%s: no tree grows on a place's ground" % p.id)


## Found by the acceptance smoke runs (2026-09-25): VoxelTool.copy over ground that is not loaded yet (copy_box: the
## stealth light, a bot's look around, COPY) asks the generator for a box of any size and place. The wild meadows'
## generator assumed one 16×16 chunk: SCRIPT ERRORs in _carve and caves from the wrong columns. Any box is now made
## chunk by chunk through the normal path, so each cell is the one its chunk would have.
func test_a_box_of_any_size_and_place_matches_the_chunks() -> void:
	for box: Array in [[Vector3i(-5, 20, 7), Vector3i(9, 9, 9)], [Vector3i(3, -40, -21), Vector3i(33, 7, 5)]]:
		var origin: Vector3i = box[0]
		var size: Vector3i = box[1]
		var buf := VoxelBuffer.new()
		buf.create(size.x, size.y, size.z)
		gen._generate_block(buf, origin, 0)
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
						gen._generate_block(c, key, 0)
						chunks[key] = c
					var want := (chunks[key] as VoxelBuffer).get_voxel(p.x - key.x, y, p.z - key.z, CH)
					if buf.get_voxel(x, y, z, CH) != want:
						wrong += 1
		assert_eq(wrong, 0, "a %s box at %s" % [size, origin])
	assert_eq(get_errors().size(), 0, "no script errors")
