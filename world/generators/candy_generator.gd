class_name CandyGenerator
extends MeadowsGenerator
## The Candy Kingdom's terrain for VoxelTerrain (M3 Task 4; runs on worker threads like its parent).
## CandyShape decides every column (frosting plains, chocolate rivers and banks, gumdrop hills, cake
## mountains) and its plants (candy canes, lollipop trees, cotton candy); CandySecretRules the gingerbread
## houses and the other secrets. Caves, ores and crystals are Green Meadows' (the parent's carving, exactly
## as reference_block says). Each column is worked out once per chunk and filled in runs, so a chunk costs no
## more than a Meadows one (tools/bench_generator.gd -- --candy).

var _candy: CandyShape


func _init() -> void:
	world_seed = 0


func _make_shape(value: int) -> MeadowsShape:
	_candy = CandyShape.new(value)
	return _candy


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return CandySecretRules.new(value, shape)


func candy_shape() -> CandyShape:
	return _candy


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	if origin.y >= MeadowsShape.MAX_HEIGHT + TREE_TOP_MARGIN:
		_place_secrets(out_buffer, origin)
		return
	var surface := origin.y + size.y > 0
	var sky := origin.y >= CandyShape.TOP   # above every ground: no columns, no caves
	# Every column once: (height, kind, floor), three ints each; the heights alone for the caves. Under
	# y = 0 the caves need no heights: the kingdom's lowest crust limit (a river's bed, 20, minus the water
	# crust) is far above those chunks (the reference test holds it).
	var heights := PackedInt32Array()
	var cols := PackedInt32Array()
	if surface and not sky:
		heights.resize(size.x * size.z)
		cols.resize(size.x * size.z * 3)
	var ground_top := MeadowsShape.SEA_LEVEL
	var stone_under := 0x7fffffff   # the lowest stone top of the chunk's columns (CandyShape.stone_top)
	if not heights.is_empty():
		var i := 0
		var features := _candy.features_in(origin.x, origin.z, origin.x + size.x, origin.z + size.z)
		for z in size.z:
			for x in size.x:
				var c := _candy.column_among(origin.x + x, origin.z + z, features)
				heights[i] = c.x
				cols[i * 3] = c.x
				cols[i * 3 + 1] = c.y
				cols[i * 3 + 2] = c.z
				ground_top = maxi(ground_top, c.x)
				stone_under = mini(stone_under, c.z - CandyShape.CHOCOLATE_DEPTH)
				i += 1
	if sky or (surface and origin.y >= ground_top):
		pass                   # all sky: only plants (below) reach into it
	elif not surface and origin.y > MeadowsShape.WORLD_BOTTOM + 3:
		out_buffer.fill(BlockIds.DEEPSTONE, CH)
	elif surface and origin.y >= 0 and origin.y + size.y <= stone_under:
		out_buffer.fill(BlockIds.STONE, CH)   # all under the chocolate: one fill (then caves and ores)
	else:
		for z in size.z:
			for x in size.x:
				var i := (x + z * size.x) * 3
				var col := Vector3i(cols[i], cols[i + 1], cols[i + 2]) if surface else Vector3i.ZERO
				_write_candy_column(out_buffer, origin, x, z, col, surface)
	if not surface or (not sky and origin.y < ground_top):
		var dry_caves := _carve(out_buffer, origin, heights)
		_place_ores(out_buffer, origin)
		_place_crystals(out_buffer, origin, dry_caves)
	if surface and origin.y < CandyShape.TOP + CandyShape.PLANT_TOP:
		var reach := CandyShape.PLANT_REACH
		for tz in range(origin.z - reach, origin.z + size.z + reach):
			for tx in range(origin.x - reach, origin.x + size.x + reach):
				var plant := _candy.plant_at(tx, tz)
				if plant != CandyShape.NO_PLANT:
					_write_plant(out_buffer, origin, size, tx, tz, plant)
	_place_secrets(out_buffer, origin)


## One column: the bedrock floor, deep stone below y = 0, stone, then the kingdom's layers (CandyShape):
## chocolate, cake and frosting on the plains; chocolate banks and beds under the chocolate river; a
## gumdrop hill's jelly; a cake mountain's layers of sponge, jam and cream with its icing on top. Each run
## is filled at once, and only runs that reach into this chunk are touched (this runs 256 times a chunk).
func _write_candy_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, col: Vector3i, surface: bool) -> void:
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
	var f := col.z
	var from := f - CandyShape.CHOCOLATE_DEPTH
	_run(buf, x, z, y0, y1, 0, from, BlockIds.STONE)
	if from >= y1 or maxi(h, MeadowsShape.SEA_LEVEL) <= y0:
		return                 # the chunk ends below the chocolate, or starts above the ground
	match col.y:
		CandyShape.RIVER, CandyShape.BANK:
			_run(buf, x, z, y0, y1, from, h, BlockIds.CHOCOLATE)
			if h < MeadowsShape.SEA_LEVEL:
				_run(buf, x, z, y0, y1, h, MeadowsShape.SEA_LEVEL, BlockIds.WATER)
			return
		CandyShape.PLAINS:
			_under(buf, x, z, y0, y1, f)
			_run(buf, x, z, y0, y1, h - 1, h, BlockIds.FROSTING)
		CandyShape.GREEN_HILL, CandyShape.RED_HILL:
			_under(buf, x, z, y0, y1, f)
			_run(buf, x, z, y0, y1, f - 1, h,
				BlockIds.GUMDROP if col.y == CandyShape.GREEN_HILL else BlockIds.RED_GUMDROP)
		CandyShape.CAKE_MOUNTAIN:
			_under(buf, x, z, y0, y1, f)
			var bottom := f - 1
			var t := 0
			while bottom + t * CandyShape.TIER_H < h - 1:
				var tier_y := bottom + t * CandyShape.TIER_H
				if tier_y < y1 and tier_y + CandyShape.TIER_H > y0:
					for l: Array in CandyShape.LAYERS:
						_run(buf, x, z, y0, y1, tier_y + int(l[0]), mini(tier_y + int(l[1]), h - 1), l[2])
				t += 1
			_run(buf, x, z, y0, y1, h - 1, h,
				BlockIds.SPRINKLES if h - f >= CandyShape.TIERS * CandyShape.TIER_H else BlockIds.CREAM)


## Fills world heights [a, b) of column (x, z) with `id`, clipped to the chunk's [y0, y1).
static func _run(buf: VoxelBuffer, x: int, z: int, y0: int, y1: int, a: int, b: int, id: int) -> void:
	var lo := maxi(a, y0)
	var hi := mini(b, y1)
	if hi > lo:
		buf.fill_area(id, Vector3i(x, lo - y0, z), Vector3i(x + 1, hi - y0, z + 1), CH)


## The chocolate and the cake under a column whose ground (or a hill's or a cake's floor) is `f`.
static func _under(buf: VoxelBuffer, x: int, z: int, y0: int, y1: int, f: int) -> void:
	var cake := f - 1 - CandyShape.CAKE_DEPTH
	_run(buf, x, z, y0, y1, f - CandyShape.CHOCOLATE_DEPTH, cake, BlockIds.CHOCOLATE)
	_run(buf, x, z, y0, y1, cake, f - 1, BlockIds.CAKE)


## A candy cane (a striped pole and its hook), a lollipop tree (a striped stick with a round lollipop on top,
## facing one way) or a cotton candy bush.
func _write_plant(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int, plant: int) -> void:
	var base := _candy.height_at(tx, tz)
	var tall := _candy.plant_height(tx, tz)
	match plant:
		CandyShape.COTTON:
			for y in range(base, base + tall):
				_set_if_air(buf, origin, size, Vector3i(tx, y, tz), BlockIds.COTTON_CANDY)
		CandyShape.CANE:
			var way := _candy.plant_dir(tx, tz)
			for c: Vector3i in cane_cells(Vector3i(tx, base, tz), tall, way):
				_set_inside(buf, origin, size, c, BlockIds.CANDY_CANE)
		CandyShape.LOLLIPOP_TREE:
			var top := Vector3i(tx, base + tall + 1, tz)
			for c: Vector3i in lollipop_cells(top, _candy.plant_dir(tx, tz)):
				_set_if_air(buf, origin, size, c, BlockIds.LOLLIPOP)
			for y in range(base, top.y + 1):   # the stick goes up into the lollipop's middle
				_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.CANDY_CANE)


## A candy cane standing at `foot`: a pole `tall` high, then a hook bending over towards `way`.
static func cane_cells(foot: Vector3i, tall: int, way: Vector2i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for y in tall:
		out.append(foot + Vector3i(0, y, 0))
	var top := foot + Vector3i(0, tall + 1, 0)
	var w := Vector3i(way.x, 0, way.y)
	for c: Vector3i in [top + Vector3i.DOWN, top, top + w, top + w * 2, top + w * 2 + Vector3i.DOWN]:
		out.append(c)
	return out


## A round lollipop 5 blocks across around `middle`, upright, facing along `way` (flat across it).
static func lollipop_cells(middle: Vector3i, way: Vector2i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var across := Vector3i(-way.y, 0, way.x)
	for dy in range(-2, 3):
		for s in range(-2, 3):
			if absi(dy) == 2 and absi(s) == 2:
				continue
			out.append(middle + across * s + Vector3i(0, dy, 0))
	return out


## The slow one-block reference of everything above except plants (tests and tools).
func reference_block(x: int, y: int, z: int) -> int:
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	var col := _candy.column(x, z)
	var h := col.x
	var near_water := CaveShape.is_near_water(h)
	var entrance := _caves.entrance_open(x, z)
	var cave := _caves.decide(_caves.value_at(x, y, z), y, h, near_water, entrance)
	if cave >= 0:
		return cave
	var id := _candy.block_in_column(y, col, _shape.bedrock_top(x, z))
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
