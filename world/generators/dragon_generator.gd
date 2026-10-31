class_name DragonGenerator
extends MeadowsGenerator
## The Dragon Realm's terrain for VoxelTerrain (owner feedback #39; runs on worker threads like its parent).
## DragonShape decides every column (an island's sky grass, floatstone and deep floatstone, or the void), its clouds,
## its ores and its plants (giant mushrooms, crystal spires); DragonSecretRules the dragon nests and the other
## secrets. No caves, no bedrock, no water. Chunks under every island (the void) are air at once, chunks over every
## island hold only plants and secrets; a chunk's columns are worked out once and filled in runs, so a chunk costs
## no more than a Meadows one (tools/bench_generator.gd -- --dragon). reference_block() is the slow one-block rule
## the fast path must match (plants aside).

## Chunk columns worked out once for every chunk of their stack (the islands span several chunks up and down): at
## most COLUMN_CACHE stacks are kept, behind a mutex (the generator's threads share it).
const COLUMN_CACHE := 1024
const STRIDE := 5                 # per column: top, bottom, deep top, cloud base, cloud top

var _dragon: DragonShape
var _stacks := {}
var _stacks_mutex := Mutex.new()


func _init() -> void:
	world_seed = 0


func _make_shape(value: int) -> MeadowsShape:
	_dragon = DragonShape.new(value)
	_stacks_mutex.lock()
	_stacks.clear()   # a new seed: new columns
	_stacks_mutex.unlock()
	return _dragon


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return DragonSecretRules.new(value, shape)


func dragon_shape() -> DragonShape:
	return _dragon


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	var y0 := origin.y
	var y1 := origin.y + size.y
	if y1 <= DragonShape.MIN_BOTTOM:
		return                 # the void under every island: air (no secret goes down here)
	var islands := y0 < DragonShape.TOP
	var clouds := y0 < DragonShape.CLOUD_HIGH and y1 > DragonShape.CLOUD_LOW
	var plants := y0 < DragonShape.TOP + DragonShape.PLANT_TOP
	if not (islands or clouds or plants):
		_place_secrets(out_buffer, origin)
		return
	var stack := _stack(origin.x, origin.z, size)
	var cols: PackedInt32Array = stack[0]
	if islands or clouds:
		var any_rock := false
		var i := 0
		for z in size.z:
			for x in size.x:
				var top := cols[i]
				var bottom := cols[i + 1]
				if clouds:
					_run(out_buffer, x, z, y0, y1, cols[i + 3], cols[i + 4], BlockIds.CLOUD)
				if islands and top > bottom and top > y0 and bottom < y1:
					any_rock = true
					var deep := cols[i + 2]
					_run(out_buffer, x, z, y0, y1, bottom, deep, BlockIds.DEEP_FLOATSTONE)
					_run(out_buffer, x, z, y0, y1, deep, top - 1, BlockIds.FLOATSTONE)
					_run(out_buffer, x, z, y0, y1, top - 1, top, BlockIds.SKY_GRASS)
				i += STRIDE
		if any_rock:
			_place_dragon_ores(out_buffer, origin)
	if plants:
		var list: PackedInt32Array = stack[1]
		for k in range(0, list.size(), 3):
			_write_plant(out_buffer, origin, size, list[k], list[k + 1], list[k + 2])
	_place_secrets(out_buffer, origin)


## [columns: STRIDE ints per column of the chunk (z, then x), plants: (x, z, kind) per plant within reach], for the
## chunk stack at (ox, oz); worked out once for all its chunks.
func _stack(ox: int, oz: int, size: Vector3i) -> Array:
	var key := Vector4i(ox, oz, size.x, size.z)
	_stacks_mutex.lock()
	var got: Variant = _stacks.get(key)
	_stacks_mutex.unlock()
	if got != null:
		return got
	var cols := PackedInt32Array()
	cols.resize(size.x * size.z * STRIDE)
	var i := 0
	for z in size.z:
		for x in size.x:
			var c := _dragon.column(ox + x, oz + z)
			var cl := _dragon.cloud_at(ox + x, oz + z)
			cols[i] = c.x
			cols[i + 1] = c.y
			cols[i + 2] = c.z
			cols[i + 3] = cl.x
			cols[i + 4] = cl.y
			i += STRIDE
	var plants := PackedInt32Array()
	var reach := DragonShape.PLANT_REACH
	for tz in range(oz - reach, oz + size.z + reach):
		for tx in range(ox - reach, ox + size.x + reach):
			var plant := _dragon.plant_at(tx, tz)
			if plant != DragonShape.NO_PLANT:
				plants.append_array([tx, tz, plant])
	var stack := [cols, plants]
	_stacks_mutex.lock()
	if _stacks.size() >= COLUMN_CACHE:
		_stacks.clear()
	_stacks[key] = stack
	_stacks_mutex.unlock()
	return stack


## Fills world heights [a, b) of column (x, z) with `id`, clipped to the chunk's [y0, y1).
static func _run(buf: VoxelBuffer, x: int, z: int, y0: int, y1: int, a: int, b: int, id: int) -> void:
	var lo := maxi(a, y0)
	var hi := mini(b, y1)
	if hi > lo:
		buf.fill_area(id, Vector3i(x, lo - y0, z), Vector3i(x + 1, hi - y0, z + 1), CH)


## The ore veins of every ore cell in this chunk (the cells are aligned to it: none reaches out); an ore only replaces
## floatstone, and the first vein wins (DragonShape.ore_at).
func _place_dragon_ores(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	var n := DragonShape.ORE_CELL
	var c0 := Vector3i(floori(origin.x / float(n)), floori(origin.y / float(n)), floori(origin.z / float(n)))
	var c1 := Vector3i(floori((origin.x + size.x - 1) / float(n)), floori((origin.y + size.y - 1) / float(n)),
		floori((origin.z + size.z - 1) / float(n)))
	for cy in range(c0.y, c1.y + 1):
		for cz in range(c0.z, c1.z + 1):
			for cx in range(c0.x, c1.x + 1):
				for vein: Dictionary in _dragon.veins_in_cell(Vector3i(cx, cy, cz)):
					for p: Vector3i in vein.blocks:
						var l := p - origin
						if l.x < 0 or l.y < 0 or l.z < 0 or l.x >= size.x or l.y >= size.y or l.z >= size.z:
							continue
						var cur := buf.get_voxel(l.x, l.y, l.z, CH)
						var id := DragonShape.ore_in(cur, vein.ore)
						if id != cur:
							buf.set_voxel(id, l.x, l.y, l.z, CH)


## A giant mushroom (a pale stalk under a round glowing cap) or a crystal spire (a tall amethyst pillar with a shorter
## one beside it).
func _write_plant(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int, plant: int) -> void:
	var base := _dragon.height_at(tx, tz)
	var tall := _dragon.plant_height(tx, tz)
	match plant:
		DragonShape.MUSHROOM:
			for c: Vector3i in cap_cells(Vector3i(tx, base + tall, tz)):
				_set_if_air(buf, origin, size, c, BlockIds.GLOW_CAP)
			for y in range(base, base + tall):
				_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.MUSHROOM_STEM)
		DragonShape.SPIRE:
			for y in range(base, base + tall):
				_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.CRYSTAL_SPIRE)
			var way := _dragon.plant_dir(tx, tz)
			var sx := tx + way.x
			var sz := tz + way.y
			var side := _dragon.column(sx, sz)
			if side.x > side.y:
				for y in range(side.x, side.x + maxi(tall / 2, 2)):
					_set_if_air(buf, origin, size, Vector3i(sx, y, sz), BlockIds.CRYSTAL_SPIRE)


## A giant mushroom's cap round the top of its stalk at `top` (the cell over the stalk's last block): a round disc
## 7 across, a rim drooping one lower, and two smaller layers on top.
static func cap_cells(top: Vector3i) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var d := dx * dx + dz * dz
			if d <= 12:
				out.append(top + Vector3i(dx, 0, dz))
			if d > 6 and d <= 12:
				out.append(top + Vector3i(dx, -1, dz))
			if d <= 6:
				out.append(top + Vector3i(dx, 1, dz))
			if d <= 1:
				out.append(top + Vector3i(dx, 2, dz))
	return out


## The slow one-block reference of everything above except plants (tests and tools).
func reference_block(x: int, y: int, z: int) -> int:
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	var id := _dragon.block_in_column(y, _dragon.column(x, z), _dragon.cloud_at(x, z))
	if id == BlockIds.FLOATSTONE or id == BlockIds.DEEP_FLOATSTONE:
		var ore := _dragon.ore_at(Vector3i(x, y, z))
		if ore >= 0:
			return ore
	return id
