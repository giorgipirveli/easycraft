class_name MeadowsBiomeGenerator
extends MeadowsGenerator
## The wild meadows' terrain for VoxelTerrain (owner feedback #45b, spec §14.18: Green Meadows' terrain version 2,
## new worlds only; runs on worker threads like its parent). MeadowsBiomeShape decides every column (biomes,
## rivers, islands, snowy tops, flowers, lily pads) and its trees (oaks, birches, dark oaks); the caves, ores and
## crystals are the old meadows' (the parent's carving), with the cave regions on top: a mushroom region's deep
## caves get a mud floor, glowing caps and giant mushrooms, a lake region's are flooded higher up. The places of
## MeadowsPlaces (villages, windmills, ...) and then the secrets are written last.
##
## Cost: a chunk column's heights and biomes are worked out once for its whole stack of chunks
## (MeadowsBiomeShape.chunk_columns), which pays for the new biomes (tools/bench_generator.gd -- --biomes).

const WILD_TREE_REACH := 3      # a dark oak's crown reaches 3 blocks from its trunk
const LAKE_Y := -22             # a lake region's caves are water below this (the old meadows: -40)
const GLOW_PER_MILLE := 160     # a mushroom cave's floor and ceiling blocks that glow
const GIANT_PER_MILLE := 60     # floor cells of a mushroom cave that grow a giant mushroom (when it fits)
const GIANT_STEM := 2
const LEAVES_OF := {MeadowsBiomeShape.OAK: BlockIds.LEAVES, MeadowsBiomeShape.BIRCH_TREE: BlockIds.BIRCH_LEAVES,
	MeadowsBiomeShape.DARK_TREE: BlockIds.DARK_LEAVES}
const LOGS_OF := {MeadowsBiomeShape.OAK: BlockIds.LOG, MeadowsBiomeShape.BIRCH_TREE: BlockIds.BIRCH_LOG,
	MeadowsBiomeShape.DARK_TREE: BlockIds.DARK_LOG}

## Off only for the benchmark's cold numbers and a test (the cache changes nothing).
var columns_cached := true
## Off only for the reference test (giant mushrooms are like trees: not in reference_block).
var giant_mushrooms := true
## The places (villages, landmarks), written after the trees; null writes none.
var places: MeadowsPlaces

var _wild: MeadowsBiomeShape
var _crowns := _crown_layers()


func _init() -> void:
	world_seed = 0


func _make_shape(value: int) -> MeadowsShape:
	_wild = MeadowsBiomeShape.new(value)
	return _wild


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	var rules := SecretRules.new(value, shape)
	places = MeadowsPlaces.new(value, shape as MeadowsBiomeShape, rules)
	if rules.tiny != null:
		rules.tiny.share_places(places)   # M3 Task 21c: the mouse villages keep off the places (worked out once)
	return rules


func wild_shape() -> MeadowsBiomeShape:
	return _wild


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	if size.x != 16 or size.z != 16 or posmod(origin.x, 16) != 0 or posmod(origin.z, 16) != 0:
		_generate_by_chunks(out_buffer, origin, size)
		return
	if origin.y >= MeadowsShape.MAX_HEIGHT + TREE_TOP_MARGIN:
		_place_secrets(out_buffer, origin)
		return
	var surface := origin.y + size.y > 0
	var heights := PackedInt32Array()
	var info := PackedInt32Array()
	var top := MeadowsShape.SEA_LEVEL
	if origin.y + size.y > MeadowsShape.MIN_HEIGHT - CaveShape.WATER_CRUST:
		var cols := _chunk_columns(origin.x, origin.z)
		heights = cols[0]
		info = cols[1]
		top = maxi(top, int(cols[2]))
	if surface and origin.y > top:
		pass                   # all sky: only trees, places and secrets can reach into it
	elif not surface and origin.y > MeadowsShape.WORLD_BOTTOM + 3:
		out_buffer.fill(BlockIds.DEEPSTONE, CH)
	else:
		for z in size.z:
			for x in size.x:
				_write_wild_column(out_buffer, origin, x, z, heights, info, surface)
	if not surface or origin.y < top:
		var dry := _carve(out_buffer, origin, heights)
		_place_ores(out_buffer, origin)
		match _wild.cave_region(origin.x, origin.z):
			MeadowsBiomeShape.MUSHROOM_CAVES:
				_mushroom_caves(out_buffer, origin, dry)
			MeadowsBiomeShape.LAKE_CAVES:
				_place_crystals(out_buffer, origin, _flood(out_buffer, origin, dry))
			_:
				_place_crystals(out_buffer, origin, dry)
	if surface:
		_wild_trees(out_buffer, origin, size, heights, info)
	if places != null:
		places.write(out_buffer, origin)
	_place_secrets(out_buffer, origin)


## A box that is not one 16×16 chunk: VoxelTool.copy over ground that is not loaded yet (WorldService.copy_box: the
## stealth light, a bot's look around, COPY) asks for any size and place. The columns, caves and trees here work per
## 16×16 chunk, so each chunk the box touches is made through the normal path and its part is copied in: every cell is
## the one its chunk has (the acceptance smoke runs found _carve's SCRIPT ERRORs, 2026-09-25).
func _generate_by_chunks(out_buffer: VoxelBuffer, origin: Vector3i, size: Vector3i) -> void:
	var chunk := VoxelBuffer.new()
	chunk.create(16, size.y, 16)
	var z0 := floori(origin.z / 16.0) * 16
	while z0 < origin.z + size.z:
		var x0 := floori(origin.x / 16.0) * 16
		while x0 < origin.x + size.x:
			chunk.fill(BlockIds.AIR, CH)
			var at := Vector3i(x0, origin.y, z0)
			_generate_block(chunk, at, 0)
			var lo := Vector3i(maxi(x0, origin.x), origin.y, maxi(z0, origin.z))
			var hi := Vector3i(mini(x0 + 16, origin.x + size.x), origin.y + size.y, mini(z0 + 16, origin.z + size.z))
			out_buffer.copy_channel_from_area(chunk, lo - at, hi - at, lo - origin, CH)
			x0 += 16
		z0 += 16


func _chunk_columns(x0: int, z0: int) -> Array:
	if columns_cached:
		return _wild.chunk_columns(x0, z0)
	var heights := PackedInt32Array()
	var info := PackedInt32Array()
	heights.resize(256)
	info.resize(256)
	var top := -0x7fffffff
	var i := 0
	for z in 16:
		for x in 16:
			var c := _wild.column(x0 + x, z0 + z)
			heights[i] = c.x
			info[i] = c.y | (c.z << 8)
			top = maxi(top, c.x)
			i += 1
	return [heights, info, top, 0]


## One column: the bedrock floor, deep stone below y = 0, stone, then the biome's layers, the water, a flower
## on the ground or a lily pad on the water (MeadowsBiomeShape.block_in_column, in runs: this runs 256 times a
## chunk).
func _write_wild_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, heights: PackedInt32Array,
		info: PackedInt32Array, surface: bool) -> void:
	var bed := _shape.bedrock_top(origin.x + x, origin.z + z)
	_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
	if not surface:
		_fill_y(buf, origin, x, z, bed + 1, 0x7fffffff, BlockIds.DEEPSTONE)
		return
	var i := x + z * 16
	var h := heights[i]
	var flags := info[i] >> 8
	var y0 := origin.y
	var y1 := origin.y + buf.get_size().y
	_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.DEEPSTONE)
	if h - 4 > y0:
		_fill_y(buf, origin, x, z, 0, h - 4, BlockIds.STONE)
	var sea := MeadowsShape.SEA_LEVEL
	if h - 4 >= y1 or maxi(h, sea) < y0:
		return                 # the chunk ends under the top layers, or starts above the water and the flowers
	var c := MeadowsBiomeShape.unpack(h, info[i])
	var top := BlockIds.GRASS
	var under := BlockIds.DIRT
	match MeadowsBiomeShape.layers(c):
		&"snow":
			top = BlockIds.SNOW
			under = BlockIds.STONE
		&"rock":
			top = BlockIds.STONE
			under = BlockIds.STONE
		&"sand":
			top = BlockIds.SAND
			under = BlockIds.SAND
		&"mud":
			top = BlockIds.MUD
	_fill_y(buf, origin, x, z, maxi(h - 4, bed + 1), h - 1, under)
	_fill_y(buf, origin, x, z, maxi(h - 1, bed + 1), h, top)
	if h < sea:
		_fill_y(buf, origin, x, z, h, sea, BlockIds.WATER)
		if flags & MeadowsBiomeShape.F_LILY and sea >= y0 and sea < y1:
			buf.set_voxel(BlockIds.LILY_PAD, x, sea - y0, z, CH)
	elif flags & MeadowsBiomeShape.F_FLOWER and h >= y0 and h < y1:
		buf.set_voxel(BlockIds.FLOWERS, x, h - y0, z, CH)


# --- Cave regions ---

## A lake region: the dry cave cells below LAKE_Y are water. Returns the cells that stay dry.
func _flood(buf: VoxelBuffer, origin: Vector3i, dry: Array[Vector3i]) -> Array[Vector3i]:
	var kept: Array[Vector3i] = []
	var size_y := buf.get_size().y
	for a in dry:
		if origin.y + a.y < LAKE_Y:
			if a.y >= 0 and a.y < size_y:
				buf.set_voxel(BlockIds.WATER, a.x, a.y, a.z, CH)
		else:
			kept.append(a)
	return kept


## A mushroom region: stone under a dry cave cell becomes a mud floor (now and then a glowing cap), stone over one
## glows now and then (instead of the crystals); then giant mushrooms on the floor where one fits in the chunk.
func _mushroom_caves(buf: VoxelBuffer, origin: Vector3i, dry: Array[Vector3i]) -> void:
	var size := buf.get_size()
	var floors: Array[Vector3i] = []
	for a in dry:
		var fl := a.y - 1
		if fl >= 0 and fl < size.y:
			var cur := buf.get_voxel(a.x, fl, a.z, CH)
			if cur == BlockIds.STONE or cur == BlockIds.DEEPSTONE:
				var p := origin + Vector3i(a.x, fl, a.z)
				buf.set_voxel(BlockIds.GLOW_MUSHROOM if glow_chance(p) else BlockIds.MUD, a.x, fl, a.z, CH)
				if a.y >= 0 and a.y < size.y:
					floors.append(a)
		var ce := a.y + 1
		if ce >= 0 and ce < size.y:
			var cur := buf.get_voxel(a.x, ce, a.z, CH)
			if (cur == BlockIds.STONE or cur == BlockIds.DEEPSTONE) and glow_chance(origin + Vector3i(a.x, ce, a.z)):
				buf.set_voxel(BlockIds.GLOW_MUSHROOM, a.x, ce, a.z, CH)
	if giant_mushrooms:
		for a in floors:
			if _giant_chance(origin + a):
				_giant_mushroom(buf, a)


func glow_chance(p: Vector3i) -> bool:
	return absi(_wild._hash(p.x * 13 + p.y * 7 + 3, p.z * 11 - p.y * 5 + 1)) % 1000 < GLOW_PER_MILLE


func _giant_chance(p: Vector3i) -> bool:
	return absi(_wild._hash(p.x * 5 - p.y * 3 + 17, p.z * 3 + p.y * 7 - 23)) % 1000 < GIANT_PER_MILLE


## A white stem and a 3 x 3 glowing cap on the floor cell `a`, only when all of it is cave air inside this chunk
## (so every chunk decides alike, and no mushroom is ever cut in half).
func _giant_mushroom(buf: VoxelBuffer, a: Vector3i) -> void:
	var size := buf.get_size()
	var cap_y := a.y + GIANT_STEM
	if a.x < 1 or a.z < 1 or a.x > size.x - 2 or a.z > size.z - 2 or cap_y + 1 >= size.y:
		return
	for y in range(a.y, cap_y):
		if buf.get_voxel(a.x, y, a.z, CH) != BlockIds.AIR:
			return
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if buf.get_voxel(a.x + dx, cap_y, a.z + dz, CH) != BlockIds.AIR:
				return
	for y in range(a.y, cap_y):
		buf.set_voxel(BlockIds.PLASTER, a.x, y, a.z, CH)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			buf.set_voxel(BlockIds.GLOW_MUSHROOM, a.x + dx, cap_y, a.z + dz, CH)
	if buf.get_voxel(a.x, cap_y + 1, a.z, CH) == BlockIds.AIR:
		buf.set_voxel(BlockIds.GLOW_MUSHROOM, a.x, cap_y + 1, a.z, CH)


# --- Trees ---

## The trees whose trunk or crown reaches into this chunk: oaks (the old meadows'), birches (tall and slim) and
## dark oaks (a wide, flat crown). Candidates are rolled first (one hash), then their column is looked up.
func _wild_trees(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, _heights: PackedInt32Array,
		_info: PackedInt32Array) -> void:
	var reach := WILD_TREE_REACH
	var y1 := origin.y + size.y
	var lo := Vector2i(origin.x - reach, origin.z - reach)
	var hi := Vector2i(origin.x + size.x + reach, origin.z + size.z + reach)
	# the trees of the 3 x 3 chunk columns round this one, each column's in its own order (the same in every chunk)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var x0 := origin.x + dx * 16
			var z0 := origin.z + dz * 16
			var trees := _wild.chunk_columns(x0, z0)[4] as PackedInt32Array if columns_cached \
				else _wild.trees_of(x0, z0, lo, hi)
			for i in range(0, trees.size(), 3):
				var packed := trees[i]
				var tx := x0 + (packed & 0xff)
				var tz := z0 + ((packed >> 8) & 0xff)
				if tx < lo.x or tz < lo.y or tx >= hi.x or tz >= hi.y:
					continue
				var base := trees[i + 1]
				var trunk := trees[i + 2]
				if base > y1 or base + trunk + 3 < origin.y:
					continue
				if places != null and places.in_clearing(tx, tz):   # a place's ground stays free of trees
					continue
				_write_wild_tree(buf, origin, size, packed >> 16, tx, tz, base, trunk)


func _write_wild_tree(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, kind: int, tx: int, tz: int, base: int,
		trunk: int) -> void:
	var top := base + trunk
	var lx := tx - origin.x
	var lz := tz - origin.z
	var leaf: int = LEAVES_OF[kind]
	for layer: Array in _crowns[kind]:
		var y: int = top + int(layer[0]) - origin.y
		if y < 0 or y >= size.y:
			continue
		for d: Vector2i in layer[1]:
			var x := lx + d.x
			var z := lz + d.y
			if x < 0 or z < 0 or x >= size.x or z >= size.z:
				continue
			if buf.get_voxel(x, y, z, CH) == BlockIds.AIR:
				buf.set_voxel(leaf, x, y, z, CH)
	if lx >= 0 and lz >= 0 and lx < size.x and lz < size.z:
		var a := clampi(base - origin.y, 0, size.y)
		var b := clampi(top - origin.y, 0, size.y)
		if b > a:
			buf.fill_area(LOGS_OF[kind], Vector3i(lx, a, lz), Vector3i(lx + 1, b, lz + 1), CH)


## Each tree's crown as layers [dy from the trunk's top, the (dx, dz) cells]: the old meadows' oak (its
## _write_tree's shape), a slim birch (a small top, two rounded layers of radius 2, one of radius 1 under them) and
## a dark oak's wide, flat crown (radius 3, then 2 over it). Worked out once.
static func _crown_layers() -> Dictionary:
	var out := {}
	for kind in [MeadowsBiomeShape.OAK, MeadowsBiomeShape.BIRCH_TREE, MeadowsBiomeShape.DARK_TREE]:
		var layers: Array = []
		var dys: Array = range(-2, 2) if kind == MeadowsBiomeShape.OAK else (range(-3, 2) if kind == MeadowsBiomeShape.BIRCH_TREE else range(-1, 2))
		for dy: int in dys:
			var cells: Array[Vector2i] = []
			var radius := 0
			match kind:
				MeadowsBiomeShape.OAK:
					radius = 2 if dy < 0 else 1
				MeadowsBiomeShape.BIRCH_TREE:
					radius = 1 if dy == -3 or dy >= 0 else 2
				_:
					radius = 3 if dy < 1 else 2
			for dz in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					match kind:
						MeadowsBiomeShape.OAK:
							if radius == 2 and absi(dx) == 2 and absi(dz) == 2:
								continue
							if dy == 1 and absi(dx) + absi(dz) > 1:
								continue
						MeadowsBiomeShape.BIRCH_TREE:
							if radius == 2 and absi(dx) == 2 and absi(dz) == 2:
								continue
							if dy == 1 and absi(dx) + absi(dz) > 0:
								continue
						_:
							if absi(dx) + absi(dz) > radius + 1:
								continue
					cells.append(Vector2i(dx, dz))
			layers.append([dy, cells])
		out[kind] = layers
	return out


# --- The slow reference ---

## The slow one-block reference of everything above except trees and giant mushrooms (tests, tools).
func reference_block(x: int, y: int, z: int) -> int:
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	var place := places.block_at(Vector3i(x, y, z)) if places != null else -1
	if place >= 0:
		return place
	return deposit_over(x, y, z, _natural_ref(x, y, z))   # spec §26: gold, iron and coal


func _natural_ref(x: int, y: int, z: int) -> int:
	var c := _wild.column(x, z)
	var cave := _cave_ref(x, y, z, c.x)
	if cave >= 0:
		return cave
	var id := _wild.block_in_column(y, c, _shape.bedrock_top(x, z))
	if id != BlockIds.STONE and id != BlockIds.DEEPSTONE:
		return id
	var p := Vector3i(x, y, z)
	var ore := _ores.ore_at(p)
	if ore >= 0:
		return ore
	var region := _wild.cave_region(x, z)
	var up_dry := _dry_ref(x, y + 1, z, c.x, region)
	var down_dry := _dry_ref(x, y - 1, z, c.x, region)
	if region == MeadowsBiomeShape.MUSHROOM_CAVES:
		if up_dry:
			return BlockIds.GLOW_MUSHROOM if glow_chance(p) else BlockIds.MUD
		if down_dry and glow_chance(p):
			return BlockIds.GLOW_MUSHROOM
		return id
	if _ores.crystal_chance(p) and (up_dry or down_dry):
		return BlockIds.CRYSTAL
	return id


## What the caves make of (x, y, z) in a column of height h: AIR, WATER or -1 (solid); a lake region floods
## its deep caves higher up.
func _cave_ref(x: int, y: int, z: int, h: int) -> int:
	var cave := _caves.decide(_caves.value_at(x, y, z), y, h, CaveShape.is_near_water(h), _caves.entrance_open(x, z))
	if cave == BlockIds.AIR and y < LAKE_Y and _wild.cave_region(x, z) == MeadowsBiomeShape.LAKE_CAVES:
		return BlockIds.WATER
	return cave


## A dry cave cell deep enough for crystals, glowing caps and mud floors (the generator's `dry` list).
func _dry_ref(x: int, y: int, z: int, h: int, region: int) -> bool:
	if y > OreRules.CRYSTAL_MAX_Y:
		return false
	var cave := _caves.decide(_caves.value_at(x, y, z), y, h, CaveShape.is_near_water(h), _caves.entrance_open(x, z))
	if cave != BlockIds.AIR:
		return false
	return not (region == MeadowsBiomeShape.LAKE_CAVES and y < LAKE_Y)
