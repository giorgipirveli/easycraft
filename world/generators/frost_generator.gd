class_name FrostGenerator
extends MeadowsGenerator
## Frostpeak's terrain for VoxelTerrain (M3 Task 3; runs on worker threads like its parent). FrostShape
## decides every column (valleys, peaks, frozen lakes), its pines and its igloos; FrostSecretRules the
## secrets (rooms under igloos, ice temples, ...). Caves, ores and crystals are Green Meadows' (the
## parent's carving, exactly as reference_block says). Each column is worked out once per chunk and filled
## in runs, so a chunk costs no more than a Meadows one (tools/bench_generator.gd -- --frost).

const PLANT_REACH := 2            # a pine's needles reach 2 blocks from the trunk (TREE_REACH)

var _frost: FrostShape
## A pine's needles around the cell above its trunk: a tip, then layers that widen and narrow down the
## trunk (cells a log fills are left to the log).
var _crown: Array[Vector3i] = []


func _init() -> void:
	world_seed = 0
	for dy in [1, 0, -1, -2, -3, -4]:
		var r: int = {1: 0, 0: 1, -1: 1, -2: 2, -3: 1, -4: 2}[dy]
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dy == 0 and absi(dx) + absi(dz) > 1:
					continue                  # a plus near the top
				if r == 2 and absi(dx) == 2 and absi(dz) == 2:
					continue                  # rounded layers
				_crown.append(Vector3i(dx, dy, dz))


func _make_shape(value: int) -> MeadowsShape:
	_frost = FrostShape.new(value)
	return _frost


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return FrostSecretRules.new(value, shape)


func frost_shape() -> FrostShape:
	return _frost


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	if origin.y >= MeadowsShape.MAX_HEIGHT + TREE_TOP_MARGIN:
		_place_secrets(out_buffer, origin)
		return
	var surface := origin.y + size.y > 0
	var sky := origin.y >= FrostShape.TOP   # above every ground: no columns, no caves
	# Every column once: (height, kind, frozen ore), three ints each; the heights alone for the caves. Under
	# y = 0 the caves need no heights: Frostpeak's lowest crust limit (a lake's bed, 19, minus the water
	# crust) is far above those chunks (the reference test holds it).
	var heights := PackedInt32Array()
	var cols := PackedInt32Array()
	if surface and not sky:
		heights.resize(size.x * size.z)
		cols.resize(size.x * size.z * 3)
	var ground_top := MeadowsShape.SEA_LEVEL
	var stone_under := 0x7fffffff   # the lowest top of plain stone in the chunk's columns
	if not heights.is_empty():
		var i := 0
		var lakes := {}                 # each LAKE_CELL cell's lake, looked up once
		for z in size.z:
			for x in size.x:
				var cell := Vector2i(floori((origin.x + x) / float(FrostShape.LAKE_CELL)), floori((origin.z + z) / float(FrostShape.LAKE_CELL)))
				if not lakes.has(cell):
					lakes[cell] = _frost.lake_of_cell(cell.x, cell.y)
				var c := _frost.column_near(origin.x + x, origin.z + z, lakes[cell])
				heights[i] = c.x
				cols[i * 3] = c.x
				cols[i * 3 + 1] = c.y
				cols[i * 3 + 2] = c.z
				ground_top = maxi(ground_top, c.x)
				stone_under = mini(stone_under, _frost.stone_top(c) if c.z == FrostShape.NO_ORE else mini(_frost.stone_top(c), c.z))
				i += 1
	if sky or (surface and origin.y >= ground_top):
		pass                   # all sky: only pines and igloos (below) reach into it
	elif not surface and origin.y > MeadowsShape.WORLD_BOTTOM + 3:
		out_buffer.fill(BlockIds.DEEPSTONE, CH)
	elif surface and origin.y >= 0 and origin.y + size.y <= stone_under:
		out_buffer.fill(BlockIds.STONE, CH)   # all plain stone: one fill (then caves and ores)
	else:
		for z in size.z:
			for x in size.x:
				var i := (x + z * size.x) * 3
				var col := Vector3i(cols[i], cols[i + 1], cols[i + 2]) if surface else Vector3i.ZERO
				_write_frost_column(out_buffer, origin, x, z, col, surface)
	if not surface or (not sky and origin.y < ground_top):
		var dry_caves := _carve(out_buffer, origin, heights)
		_place_ores(out_buffer, origin)
		_place_crystals(out_buffer, origin, dry_caves)
	if surface and origin.y < FrostShape.TREE_LINE + FrostShape.PINE_TOP:
		var sd := _frost.seed * 982451653    # FrostShape.pine_base's first roll, inlined (400 columns a chunk)
		for tz in range(origin.z - PLANT_REACH, origin.z + size.z + PLANT_REACH):
			var zp := (tz * 5 - 2) * 668265263 + sd
			for tx in range(origin.x - PLANT_REACH, origin.x + size.x + PLANT_REACH):
				var roll := (tx * 3 + 1) * 374761393 + zp
				roll = (roll ^ (roll >> 13)) * 1274126177
				if absi(roll ^ (roll >> 16)) % 1000 >= FrostShape.FOREST_PER_MILLE:
					continue
				var base := _frost.pine_base(tx, tz)
				if base != FrostShape.NO_PINE and base < origin.y + size.y and base + FrostShape.PINE_TOP > origin.y:
					_write_pine(out_buffer, origin, size, tx, tz, base)
	_place_igloos(out_buffer, origin)
	_place_secrets(out_buffer, origin)


## One column: the bedrock floor, deep stone below y = 0, stone, then Frostpeak's layers (FrostShape: snow
## on a peak with its frozen ore, snowy grass and dirt in a valley, a lake's bed, water and ice). Each run is
## filled at once, and only runs that reach into this chunk are touched (this runs 256 times a chunk).
func _write_frost_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, col: Vector3i, surface: bool) -> void:
	var y0 := origin.y
	var y1 := origin.y + buf.get_size().y
	if y0 <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := _shape.bedrock_top(origin.x + x, origin.z + z)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0 if surface else 0x7fffffff, BlockIds.DEEPSTONE)
	elif y0 < 0:
		_run(buf, x, z, y0, y1, y0, 0, BlockIds.DEEPSTONE)
	if not surface:
		return
	var h := col.x
	var from := _frost.stone_top(col)
	_run(buf, x, z, y0, y1, 0, from, BlockIds.STONE)
	if col.z >= y0 and col.z < y1:                   # a peak's frozen ore, in the stone under its snow
		buf.set_voxel(BlockIds.FROZEN_ORE, x, col.z - y0, z, CH)
	if from >= y1 or maxi(h, MeadowsShape.SEA_LEVEL) <= y0:
		return                 # the chunk ends below the layers, or starts above the ground
	if col.y == FrostShape.PEAK:
		_run(buf, x, z, y0, y1, from, h, BlockIds.SNOW)
	elif col.y == FrostShape.LAKE and h < MeadowsShape.SEA_LEVEL:
		_run(buf, x, z, y0, y1, from, h, BlockIds.DIRT)
		_run(buf, x, z, y0, y1, h, MeadowsShape.SEA_LEVEL - 1, BlockIds.WATER)
		_run(buf, x, z, y0, y1, MeadowsShape.SEA_LEVEL - 1, MeadowsShape.SEA_LEVEL, BlockIds.ICE)
	else:
		_run(buf, x, z, y0, y1, from, h - 1, BlockIds.DIRT)
		_run(buf, x, z, y0, y1, h - 1, h, BlockIds.SNOWY_GRASS)


## Fills world heights [a, b) of column (x, z) with `id`, clipped to the chunk's [y0, y1).
static func _run(buf: VoxelBuffer, x: int, z: int, y0: int, y1: int, a: int, b: int, id: int) -> void:
	var lo := maxi(a, y0)
	var hi := mini(b, y1)
	if hi > lo:
		buf.fill_area(id, Vector3i(x, lo - y0, z), Vector3i(x + 1, hi - y0, z + 1), CH)


## A pine standing on `base`: a trunk of 5-8 logs in a cone of needles.
func _write_pine(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int, base: int) -> void:
	var top := base + _frost.pine_height(tx, tz)
	for d: Vector3i in _crown:
		_set_if_air(buf, origin, size, Vector3i(tx, top, tz) + d, BlockIds.PINE_NEEDLES)
	for y in range(base, top):
		_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.PINE_LOG)


## The igloos' boxes that reach into this buffer (each stays inside its own IGLOO_CELL cell).
func _place_igloos(buf: VoxelBuffer, origin: Vector3i) -> void:
	var end := origin + buf.get_size()
	if origin.y >= FrostShape.SNOW_LINE + 4 or end.y <= MeadowsShape.SEA_LEVEL - 3:
		return                 # igloos stand in the valleys
	var c0 := Vector2i(floori(origin.x / float(FrostShape.IGLOO_CELL)), floori(origin.z / float(FrostShape.IGLOO_CELL)))
	var c1 := Vector2i(floori((end.x - 1) / float(FrostShape.IGLOO_CELL)), floori((end.z - 1) / float(FrostShape.IGLOO_CELL)))
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var ig := _frost.igloo_in_cell(Vector2i(cx, cz))
			if ig.is_empty():
				continue
			var lo: Vector3i = ig.lo
			var hi: Vector3i = ig.hi
			if hi.x <= origin.x or hi.y <= origin.y or hi.z <= origin.z or lo.x >= end.x or lo.y >= end.y or lo.z >= end.z:
				continue
			for b: Array in ig.boxes:
				var bl: Vector3i = (b[0] as Vector3i).max(origin) - origin
				var bh: Vector3i = (b[1] as Vector3i).min(end) - origin
				if bl.x < bh.x and bl.y < bh.y and bl.z < bh.z:
					buf.fill_area(b[2], bl, bh, CH)


## The slow one-block reference of everything above except pines (tests and tools).
func reference_block(x: int, y: int, z: int) -> int:
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	var igloo := _frost.igloo_block_at(Vector3i(x, y, z))
	if igloo >= 0:
		return igloo
	var col := _frost.column(x, z)
	var h := col.x
	var near_water := CaveShape.is_near_water(h)
	var entrance := _caves.entrance_open(x, z)
	var cave := _caves.decide(_caves.value_at(x, y, z), y, h, near_water, entrance)
	if cave >= 0:
		return cave
	var id := _frost.block_in_column(y, col, _shape.bedrock_top(x, z))
	if id != BlockIds.STONE and id != BlockIds.DEEPSTONE:
		return id
	var ore := _ores.ore_at(Vector3i(x, y, z))
	if ore >= 0:
		return ore
	if _ores.crystal_chance(Vector3i(x, y, z)):
		for dy in [1, -1]:
			if _caves.decide(_caves.value_at(x, y + dy, z), y + dy, h, near_water, entrance) == BlockIds.AIR:
				return BlockIds.CRYSTAL
	return id
