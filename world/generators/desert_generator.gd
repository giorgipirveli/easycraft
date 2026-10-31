class_name DesertGenerator
extends MeadowsGenerator
## The Sandstorm Desert's terrain for VoxelTerrain (M3 Task 2; runs on worker threads like its parent).
## DesertShape decides every column (dunes, mesas, oases) and its plants (cacti, dry bushes, palms);
## DesertSecretRules the pyramids and the other secrets. Caves, ores and crystals are Green Meadows'
## (the parent's carving, exactly as reference_block says). Each column is worked out once per chunk
## and filled in runs, so a chunk costs no more than a Meadows one (tools/bench_generator.gd -- --desert).

const PLANT_REACH := 2            # palm fronds reach 2 blocks from the trunk (TREE_REACH)

var _desert: DesertShape


func _init() -> void:
	world_seed = 0


func _make_shape(value: int) -> MeadowsShape:
	_desert = DesertShape.new(value)
	return _desert


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return DesertSecretRules.new(value, shape)


func desert_shape() -> DesertShape:
	return _desert


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	if origin.y >= MeadowsShape.MAX_HEIGHT + TREE_TOP_MARGIN:
		_place_secrets(out_buffer, origin)
		return
	var surface := origin.y + size.y > 0
	var sky := origin.y >= DesertShape.TOP   # above every ground: no columns, no caves
	# Every column once: (height, kind, floor), three ints each; the heights alone for the caves. Under
	# y = 0 the caves need no heights: the desert's lowest crust limit (a pond's floor, 21, minus the
	# water crust) is far above those chunks (the reference test holds it).
	var heights := PackedInt32Array()
	var cols := PackedInt32Array()
	if surface and not sky:
		heights.resize(size.x * size.z)
		cols.resize(size.x * size.z * 3)
	var ground_top := MeadowsShape.SEA_LEVEL
	var stone_under := 0x7fffffff   # the lowest stone top of the chunk's columns (DesertShape.stone_top)
	if not heights.is_empty():
		var i := 0
		for z in size.z:
			for x in size.x:
				var c := _desert.column(origin.x + x, origin.z + z)
				heights[i] = c.x
				cols[i * 3] = c.x
				cols[i * 3 + 1] = c.y
				cols[i * 3 + 2] = c.z
				ground_top = maxi(ground_top, c.x)
				stone_under = mini(stone_under, mini(c.z, c.x) - DesertShape.SANDSTONE_DEPTH if c.y == DesertShape.OASIS \
					else c.z - DesertShape.SANDSTONE_DEPTH)
				i += 1
	if sky or (surface and origin.y >= ground_top):
		pass                   # all sky: only plants (below) reach into it
	elif not surface and origin.y > MeadowsShape.WORLD_BOTTOM + 3:
		out_buffer.fill(BlockIds.DEEPSTONE, CH)
	elif surface and origin.y >= 0 and origin.y + size.y <= stone_under:
		out_buffer.fill(BlockIds.STONE, CH)   # all under the sandstone: one fill (then caves and ores)
	else:
		for z in size.z:
			for x in size.x:
				var i := (x + z * size.x) * 3
				var col := Vector3i(cols[i], cols[i + 1], cols[i + 2]) if surface else Vector3i.ZERO
				_write_desert_column(out_buffer, origin, x, z, col, surface)
	if not surface or (not sky and origin.y < ground_top):
		var dry_caves := _carve(out_buffer, origin, heights)
		_place_ores(out_buffer, origin)
		_place_crystals(out_buffer, origin, dry_caves)
	if surface and origin.y < DesertShape.TOP + DesertShape.PLANT_TOP:
		for tz in range(origin.z - PLANT_REACH, origin.z + size.z + PLANT_REACH):
			for tx in range(origin.x - PLANT_REACH, origin.x + size.x + PLANT_REACH):
				var plant := _desert.plant_at(tx, tz)
				if plant != DesertShape.NO_PLANT:
					_write_plant(out_buffer, origin, size, tx, tz, plant)
	_place_secrets(out_buffer, origin)


## One column: the bedrock floor, deep stone below y = 0, stone, then the desert's layers (DesertShape:
## sandstone, sand, a mesa's stripes, an oasis' banks or pond). Each run is filled at once, and only runs
## that reach into this chunk are touched (this runs 256 times a chunk).
func _write_desert_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, col: Vector3i, surface: bool) -> void:
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
	var from := _desert.stone_top(col)
	_run(buf, x, z, y0, y1, 0, from, BlockIds.STONE)
	if from >= y1 or maxi(h, MeadowsShape.SEA_LEVEL) <= y0:
		return                 # the chunk ends below the sandstone, or starts above the ground
	match col.y:
		DesertShape.MESA:
			_run(buf, x, z, y0, y1, from, col.z - 1, BlockIds.SANDSTONE)
			var y := col.z - 1
			while y < h - 1:
				var k := posmod(y, DesertShape.MESA_STRIPE)
				var light := k < DesertShape.MESA_STRIPE_LIGHT
				var end := mini(y - k + (DesertShape.MESA_STRIPE_LIGHT if light else DesertShape.MESA_STRIPE), h - 1)
				_run(buf, x, z, y0, y1, y, end, BlockIds.SANDSTONE if light else BlockIds.RED_SANDSTONE)
				y = end
			_run(buf, x, z, y0, y1, h - 1, h, BlockIds.RED_SAND)
		DesertShape.OASIS:
			if h <= MeadowsShape.SEA_LEVEL:
				_run(buf, x, z, y0, y1, from, h - 3, BlockIds.SANDSTONE)
				_run(buf, x, z, y0, y1, h - 3, h, BlockIds.SAND)
				_run(buf, x, z, y0, y1, h, MeadowsShape.SEA_LEVEL, BlockIds.WATER)
			else:
				_run(buf, x, z, y0, y1, from, h - 4, BlockIds.SANDSTONE)
				_run(buf, x, z, y0, y1, h - 4, h - 1, BlockIds.DIRT)
				_run(buf, x, z, y0, y1, h - 1, h, BlockIds.GRASS)
		_:
			var sand := mini(h - DesertShape.SAND_DEPTH, col.z - 2)
			_run(buf, x, z, y0, y1, from, sand, BlockIds.SANDSTONE)
			_run(buf, x, z, y0, y1, sand, h, BlockIds.SAND)


## Fills world heights [a, b) of column (x, z) with `id`, clipped to the chunk's [y0, y1).
static func _run(buf: VoxelBuffer, x: int, z: int, y0: int, y1: int, a: int, b: int, id: int) -> void:
	var lo := maxi(a, y0)
	var hi := mini(b, y1)
	if hi > lo:
		buf.fill_area(id, Vector3i(x, lo - y0, z), Vector3i(x + 1, hi - y0, z + 1), CH)


## A cactus (1-3 blocks), a dry bush, or a palm (a trunk and fronds that droop at their tips).
func _write_plant(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int, plant: int) -> void:
	var base := _desert.height_at(tx, tz)
	var tall := _desert.plant_height(tx, tz)
	match plant:
		DesertShape.CACTUS:
			for y in range(base, base + tall):
				_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.CACTUS)
		DesertShape.BUSH:
			_set_if_air(buf, origin, size, Vector3i(tx, base, tz), BlockIds.DEAD_BUSH)
		DesertShape.PALM:
			var top := base + tall
			for d: Vector3i in PALM_FRONDS:
				_set_if_air(buf, origin, size, Vector3i(tx, top, tz) + d, BlockIds.PALM_LEAVES)
			for y in range(base, top):
				_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.PALM_LOG)


## A palm's crown around the cell above its trunk: a cross of fronds 2 long, the tips a block lower,
## and short diagonal fronds.
const PALM_FRONDS: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1),
	Vector3i(0, 0, -1), Vector3i(2, -1, 0), Vector3i(-2, -1, 0), Vector3i(0, -1, 2), Vector3i(0, -1, -2),
	Vector3i(1, 0, 1), Vector3i(-1, 0, 1), Vector3i(1, 0, -1), Vector3i(-1, 0, -1), Vector3i(0, 1, 0)]


## The slow one-block reference of everything above except plants (tests and tools).
func reference_block(x: int, y: int, z: int) -> int:
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	return deposit_over(x, y, z, _natural_ref(x, y, z))   # spec §26: the desert's copper, oil and salt


func _natural_ref(x: int, y: int, z: int) -> int:
	var col := _desert.column(x, z)
	var h := col.x
	var near_water := CaveShape.is_near_water(h)
	var entrance := _caves.entrance_open(x, z)
	var cave := _caves.decide(_caves.value_at(x, y, z), y, h, near_water, entrance)
	if cave >= 0:
		return cave
	var id := _desert.block_in_column(y, col, _shape.bedrock_top(x, z))
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
