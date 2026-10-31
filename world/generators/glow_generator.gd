class_name GlowGenerator
extends MeadowsGenerator
## Universe 6, the Glow Caves' terrain for VoxelTerrain (spec §5.1; runs on worker threads like its parent). GlowShape
## decides every column (GlowShape.layers: the rock, the floor's top block, a lake's water, the ceiling's block, the
## rock over it and the roof's meadow) and its plants (giant and small glowshrooms, stalagmites, flowstone columns,
## selenite beams, stalactites); GlowSecretRules the secrets, GlowWonders the Cave Wonders (written after the secrets;
## nothing grows or hangs on a secret or a wonder). A chunk stack's columns are worked out once into runs
## (RUNS heights a column) and its plants with their heights (a cache of COLUMN_CACHE stacks behind a mutex, cleared
## with a new seed); a chunk then fills only the runs that reach into it and the plants that do. Chunks deep under every
## floor are one fill of stone (and the meadows' ore veins); chunks under the caves' bedrock and over every roof are
## empty (secrets aside). Bench: tools/bench_generator.gd -- --glow. reference_block() is the slow one-block rule the
## fast path must match (plants aside).

const COLUMN_CACHE := 512
const RUNS := 12                  # heights a column: bedrock, deep stone, stone, cave stone, top, water, air, ceiling,
                                  # cave stone, dirt, grass (11 runs between 12 heights)
const MAX_ROOF := GlowShape.ROOF_MID + int(GlowShape.ROOF_SWING) + 1
## Each run's block (-1: the floor's top block, -2: the ceiling's, from the column).
const RUN_IDS: Array[int] = [BlockIds.BEDROCK, BlockIds.DEEPSTONE, BlockIds.STONE, BlockIds.CAVE_STONE, -1,
	BlockIds.WATER, BlockIds.AIR, -2, BlockIds.CAVE_STONE, BlockIds.DIRT, BlockIds.GRASS]
const PLANT_STRIDE := 5           # per plant: x, z, kind, base, highest y

var _glow: GlowShape
var _stacks := {}
var _stacks_mutex := Mutex.new()


func _init() -> void:
	world_seed = 0


func _make_shape(value: int) -> MeadowsShape:
	_glow = GlowShape.new(value)
	_stacks_mutex.lock()
	_stacks.clear()   # a new seed: new columns
	_stacks_mutex.unlock()
	return _glow


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return GlowSecretRules.new(value, shape)


func glow_shape() -> GlowShape:
	return _glow


func wonders() -> GlowWonders:
	return (_secrets as GlowSecretRules).wonders if _secrets is GlowSecretRules else null


## The secrets, then the Cave Wonders over them.
func _place_secrets(buf: VoxelBuffer, origin: Vector3i) -> void:
	super(buf, origin)
	if secrets_enabled and _secrets is GlowSecretRules:
		(_secrets as GlowSecretRules).wonders.write(buf, origin)


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	var y0 := origin.y
	var y1 := origin.y + size.y
	if y1 <= GlowShape.BED_BOTTOM:
		return                 # nothing under the caves' bedrock (no secret goes down here)
	if y0 >= MAX_ROOF:
		_place_secrets(out_buffer, origin)   # nothing of the caves reaches over the roof
		return
	var stack := _stack(origin.x, origin.z, size)
	var runs: PackedInt32Array = stack[0]
	if y1 <= int(stack[3]) and y0 > GlowShape.BED_BOTTOM + 3:
		out_buffer.fill(BlockIds.STONE if y0 >= 0 else BlockIds.DEEPSTONE, CH)   # under every floor: plain rock
		_place_ores(out_buffer, origin)
		_place_secrets(out_buffer, origin)
		return
	var ids: PackedInt32Array = stack[4]
	var stone := false
	var col := 0
	for z in size.z:
		for x in size.x:
			var b := col * RUNS
			for r in RUNS - 1:
				var e := runs[b + r + 1]
				if e <= y0:
					continue
				var a := runs[b + r]
				if a >= y1:
					break
				if e <= a:
					continue
				var id := RUN_IDS[r]
				if id < 0:
					id = ids[col * 2 + (0 if id == -1 else 1)]
				if id == BlockIds.AIR:
					continue
				if r == 1 or r == 2:
					stone = true
				out_buffer.fill_area(id, Vector3i(x, maxi(a, y0) - y0, z), Vector3i(x + 1, mini(e, y1) - y0, z + 1), CH)
			col += 1
	if stone:
		_place_ores(out_buffer, origin)
	var plants: PackedInt32Array = stack[1]
	var beams: Dictionary = stack[5]
	for k in range(0, plants.size(), PLANT_STRIDE):
		if plants[k + 4] < y0 or plants[k + 3] >= y1:
			continue
		_write_plant(out_buffer, origin, size, plants[k], plants[k + 1], plants[k + 2], plants[k + 3], beams)
	var hangs: PackedInt32Array = stack[2]
	for k in range(0, hangs.size(), 4):
		if hangs[k + 3] <= y0 or hangs[k + 3] - hangs[k + 2] >= y1:
			continue
		_write_hang(out_buffer, origin, size, hangs[k], hangs[k + 1], hangs[k + 2], hangs[k + 3])
	var tops: PackedInt32Array = stack[6]
	for k in range(0, tops.size(), 3):   # the roof's flowers
		if tops[k + 2] >= y0 and tops[k + 2] < y1:
			_set_inside(out_buffer, origin, size, Vector3i(tops[k], tops[k + 2], tops[k + 1]), BlockIds.FLOWERS)
	_place_secrets(out_buffer, origin)


## [runs: RUNS heights per column of the chunk (z, then x), plants: PLANT_STRIDE ints each within reach (its base and
## highest y), stalactites: (x, z, length, ceiling) of the chunk's columns, the lowest stone top, the columns' (floor
## top, ceiling) blocks, the beams' cells by their foot, the roof's flowers (x, z, roof)]; worked out once for all the
## stack's chunks.
func _stack(ox: int, oz: int, size: Vector3i) -> Array:
	var key := Vector4i(ox, oz, size.x, size.z)
	_stacks_mutex.lock()
	var got: Variant = _stacks.get(key)
	_stacks_mutex.unlock()
	if got != null:
		return got
	var runs := PackedInt32Array()
	runs.resize(size.x * size.z * RUNS)
	var ids := PackedInt32Array()
	ids.resize(size.x * size.z * 2)
	var hangs := PackedInt32Array()
	var tops := PackedInt32Array()
	var lowest := 0x7fffffff
	var clear := _kept_clear(ox, oz, size)
	var col := 0
	for z in size.z:
		for x in size.x:
			var l := _glow.layers(ox + x, oz + z)
			_column_runs(l, runs, col * RUNS)
			ids[col * 2] = l[3]
			ids[col * 2 + 1] = l[4]
			lowest = mini(lowest, l[6])
			var hang := _glow.hang_at(ox + x, oz + z)
			if hang > 0 and _clear_of(clear, ox + x, oz + z, 0):
				hangs.append_array([ox + x, oz + z, hang, l[1]])
			if l[1] < l[2] and _glow.flower_spot(ox + x, oz + z):   # grass on the roof (not a shaft's sky)
				tops.append_array([ox + x, oz + z, l[2]])
			col += 1
	var plants := PackedInt32Array()
	var beams := {}
	var feet: Array[Vector2i] = []
	var reach := GlowShape.PLANT_REACH
	for tz in range(oz - reach, oz + size.z + reach):
		for tx in range(ox - reach, ox + size.x + reach):
			feet.append(Vector2i(tx, tz))
	var far := GlowShape.BEAM_REACH
	var n := GlowShape.BEAM_BLOCK
	for bz in range(floori((oz - far) / float(n)), floori((oz + size.z + far - 1) / float(n)) + 1):
		for bx in range(floori((ox - far) / float(n)), floori((ox + size.x + far - 1) / float(n)) + 1):
			var foot := _glow.beam_foot(bx, bz)
			if foot.x != 0x7fffffff and not (foot.x >= ox - reach and foot.x < ox + size.x + reach \
					and foot.y >= oz - reach and foot.y < oz + size.z + reach):
				feet.append(foot)   # a beam's foot further out than the other plants reach
	for foot: Vector2i in feet:
		var tx := foot.x
		var tz := foot.y
		var plant := _glow.plant_at(tx, tz)
		if plant == GlowShape.NO_PLANT:
			continue
		if not clear.is_empty() and not _clear_of(clear, tx, tz, reach if plant != GlowShape.BEAM else 0):
			continue   # a giant's cap reaches PLANT_REACH; a beam's cells are looked at one by one below
		var c := _glow.column(tx, tz)
		var top := c.x
		match plant:
			GlowShape.BLUE_GIANT, GlowShape.ROSE_GIANT:
				top = c.x + _glow.plant_height(tx, tz, plant) + 2
			GlowShape.BLUE_SMALL, GlowShape.ROSE_SMALL, GlowShape.STALAGMITE:
				top = c.x + _glow.plant_height(tx, tz, plant)
			GlowShape.COLUMN:
				top = c.y - 1
			GlowShape.BEAM:
				var cells := _glow.beam_cells(tx, tz)
				if cells.is_empty() or not _cells_clear(clear, cells):
					continue
				beams[Vector2i(tx, tz)] = cells
				for cell: Vector3i in cells:
					top = maxi(top, cell.y)
		plants.append_array([tx, tz, plant, c.x, top])
	var stack := [runs, plants, hangs, lowest, ids, beams, tops]
	_stacks_mutex.lock()
	if _stacks.size() >= COLUMN_CACHE:
		_stacks.clear()
	_stacks[key] = stack
	_stacks_mutex.unlock()
	return stack


## The sideways footprints of the secrets and wonders whose areas reach within BEAM_REACH of a stack (none with the
## secrets off: the bench's comparison).
func _kept_clear(ox: int, oz: int, size: Vector3i) -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	if not secrets_enabled or not _secrets is GlowSecretRules:
		return out
	var far := GlowShape.BEAM_REACH
	var a0 := SecretRules.area_of(ox - far, oz - far)
	var a1 := SecretRules.area_of(ox + size.x + far, oz + size.z + far)
	var near := Rect2i(ox - far, oz - far, size.x + 2 * far, size.z + 2 * far)
	var rules := _secrets as GlowSecretRules
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			var area := Vector2i(ax, az)
			var w := rules.wonders.footprint(area)
			if w.size != Vector2i.ZERO and w.intersects(near):
				out.append(w)
			for s: Dictionary in rules.secrets_in_area(area):
				var lo: Vector3i = s.lo
				var hi: Vector3i = s.hi
				var r := Rect2i(lo.x, lo.z, hi.x - lo.x, hi.z - lo.z)
				if r.intersects(near):
					out.append(r)
	return out


## Column (x, z) is `pad` or more blocks off every footprint.
static func _clear_of(rects: Array[Rect2i], x: int, z: int, pad: int) -> bool:
	for r: Rect2i in rects:
		if x >= r.position.x - pad and x < r.end.x + pad and z >= r.position.y - pad and z < r.end.y + pad:
			return false
	return true


static func _cells_clear(rects: Array[Rect2i], cells: Array[Vector3i]) -> bool:
	if rects.is_empty():
		return true
	for c: Vector3i in cells:
		if not _clear_of(rects, c.x, c.z, 0):
			return false
	return true


## A column's RUNS heights from its layers (GlowShape.layers); a wall or a shaft has empty runs where it has nothing.
static func _column_runs(l: PackedInt32Array, out: PackedInt32Array, at: int) -> void:
	var floor_y := l[0]
	var ceil_y := l[1]
	var roof := l[2]
	var stone_top := l[6]
	var bed := l[7]
	var soil := roof - 1 - GlowShape.SOIL
	out[at] = GlowShape.BED_BOTTOM
	out[at + 1] = bed + 1
	out[at + 2] = maxi(mini(0, stone_top), bed + 1)
	out[at + 3] = maxi(stone_top, bed + 1)
	if floor_y == ceil_y:                     # a wall: cave stone up to the meadow's soil
		for k in range(4, 9):
			out[at + k] = soil
	else:
		out[at + 4] = floor_y - 1
		out[at + 5] = floor_y
		out[at + 6] = maxi(l[5], floor_y)
		if ceil_y >= roof:                    # a shaft: open to the sky
			for k in range(7, 12):
				out[at + k] = roof
			return
		out[at + 7] = ceil_y
		out[at + 8] = ceil_y + 1
	out[at + 9] = soil
	out[at + 10] = roof - 1
	out[at + 11] = roof


## A plant on the floor (`base`) of column (tx, tz).
func _write_plant(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int, plant: int, base: int,
		beams: Dictionary) -> void:
	match plant:
		GlowShape.BLUE_GIANT, GlowShape.ROSE_GIANT:
			var tall := _glow.plant_height(tx, tz, plant)
			_cap(buf, origin, size, Vector3i(tx, base + tall, tz), BlockIds.BLUE_SHROOM if plant == GlowShape.BLUE_GIANT \
				else BlockIds.ROSE_SHROOM)
			_pillar(buf, origin, size, tx, tz, base, base + tall, BlockIds.SHROOM_STEM)
		GlowShape.BLUE_SMALL, GlowShape.ROSE_SMALL:
			var tall := _glow.plant_height(tx, tz, plant)
			_pillar(buf, origin, size, tx, tz, base, base + tall, BlockIds.SHROOM_STEM)
			_set_inside(buf, origin, size, Vector3i(tx, base + tall, tz),
				BlockIds.BLUE_SHROOM if plant == GlowShape.BLUE_SMALL else BlockIds.ROSE_SHROOM)
		GlowShape.STALAGMITE:
			var tall := _glow.plant_height(tx, tz, plant)
			_pillar(buf, origin, size, tx, tz, base, base + tall, BlockIds.FLOWSTONE)
			_set_inside(buf, origin, size, Vector3i(tx, base + tall, tz), BlockIds.STALAGMITE)
		GlowShape.COLUMN:
			_pillar(buf, origin, size, tx, tz, base, _glow.column(tx, tz).y, BlockIds.FLOWSTONE)
		GlowShape.BEAM:
			for c: Vector3i in beams.get(Vector2i(tx, tz), []):
				_set_if_air(buf, origin, size, c, BlockIds.SELENITE)


## Heights [a, b) of column (x, z) inside the chunk set to `id` (one fill).
static func _pillar(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, x: int, z: int, a: int, b: int, id: int) -> void:
	var lx := x - origin.x
	var lz := z - origin.z
	if lx < 0 or lz < 0 or lx >= size.x or lz >= size.z:
		return
	var lo := maxi(a, origin.y)
	var hi := mini(b, origin.y + size.y)
	if hi > lo:
		buf.fill_area(id, Vector3i(lx, lo - origin.y, lz), Vector3i(lx + 1, hi - origin.y, lz + 1), CH)


## A giant glowshroom's cap round the top of its stalk at `top` (DragonGenerator.cap_cells' shape: a disc 7 across, its
## rim drooping one lower, a smaller layer on top and its crown), written into air only.
func _cap(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, top: Vector3i, id: int) -> void:
	var l := top - origin
	if l.x < -3 or l.z < -3 or l.x > size.x + 2 or l.z > size.z + 2 or l.y < -2 or l.y > size.y + 1:
		return
	for dz in range(-3, 4):
		var z := l.z + dz
		if z < 0 or z >= size.z:
			continue
		for dx in range(-3, 4):
			var x := l.x + dx
			if x < 0 or x >= size.x:
				continue
			var d := dx * dx + dz * dz
			if d > 12:
				continue
			_air_to(buf, x, l.y, z, size.y, id)
			if d > 6:
				_air_to(buf, x, l.y - 1, z, size.y, id)
			else:
				_air_to(buf, x, l.y + 1, z, size.y, id)
				if d <= 1:
					_air_to(buf, x, l.y + 2, z, size.y, id)


static func _air_to(buf: VoxelBuffer, x: int, y: int, z: int, height: int, id: int) -> void:
	if y >= 0 and y < height and buf.get_voxel(x, y, z, CH) == BlockIds.AIR:
		buf.set_voxel(id, x, y, z, CH)


## A stalactite of `length` hanging from the ceiling `ceil_y` of column (tx, tz): flowstone, its tip the picture.
func _write_hang(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int, length: int, ceil_y: int) -> void:
	_pillar(buf, origin, size, tx, tz, ceil_y - length + 1, ceil_y, BlockIds.FLOWSTONE)
	_set_inside(buf, origin, size, Vector3i(tx, ceil_y - length, tz), BlockIds.STALACTITE)


## The slow one-block reference of everything above except plants (tests and tools).
func reference_block(x: int, y: int, z: int) -> int:
	if secrets_enabled and _secrets is GlowSecretRules:
		var wonder := (_secrets as GlowSecretRules).wonders.block_at(Vector3i(x, y, z))
		if wonder >= 0:
			return wonder
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	var l := _glow.layers(x, z)
	if y == l[2] and l[1] < l[2] and _glow.flower_spot(x, z):
		return BlockIds.FLOWERS   # the roof's flowers
	var id := GlowShape.block_in_layers(y, l)
	if id == BlockIds.STONE or id == BlockIds.DEEPSTONE:
		var cell := Vector3i(floori(x / 16.0), floori(y / 16.0), floori(z / 16.0))
		for vein: Dictionary in _ores.veins_in_cell(cell):
			if (vein.blocks as Array).has(Vector3i(x, y, z)):
				return vein.ore
	return id
