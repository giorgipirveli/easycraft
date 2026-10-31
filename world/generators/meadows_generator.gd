class_name MeadowsGenerator
extends VoxelGeneratorScript
## Endless Green Meadows terrain for VoxelTerrain (runs on worker threads).
## All shape decisions live in MeadowsShape and CaveShape; this class only writes them into voxel
## buffers, fast: whole-column fills, and caves carved per 4³ cell with an exact skip test. Secrets
## (SecretRules, M2 Task 16) are written last, box by box, clipped to the chunk.
## reference_block() is the slow one-block-at-a-time rule the fast path must match.

const CH := VoxelBuffer.CHANNEL_TYPE
const TREE_REACH := 2   # leaves extend 2 blocks from the trunk
const TREE_TOP_MARGIN := 10

@export var world_seed := 0:
	set(value):
		world_seed = value
		_shape = _make_shape(value)
		_caves = CaveShape.new(value)
		_ores = OreRules.new(value)
		_secrets = _make_secrets(value, _shape)
		_deposits = DepositRules.for_world(value, _shape, _secrets, get(&"places"))   # spec §26: prospecting
## Off only for the generator bench's before/after comparison.
var secrets_enabled := true
## Spec §26 (prospecting): the rich deposits (gold, iron and coal here; the desert's copper, oil and salt), written with
## the secrets, before them. Off only for the bench's before/after comparison.
var deposits_enabled := true

var _shape := MeadowsShape.new(0)
var _caves := CaveShape.new(0)
var _ores := OreRules.new(0)
var _secrets := SecretRules.new(0, _shape)
var _deposits: DepositRules = null


func _get_used_channels_mask() -> int:
	return 1 << CH


## The terrain rules and the secrets for a seed: Green Meadows'. Another universe's generator (M3 Task 2,
## DesertGenerator) makes its own.
func _make_shape(value: int) -> MeadowsShape:
	return MeadowsShape.new(value)


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return SecretRules.new(value, shape)


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var size := out_buffer.get_size()
	if origin.y >= MeadowsShape.MAX_HEIGHT + TREE_TOP_MARGIN:
		_place_secrets(out_buffer, origin)   # sky islands can float up here
		return
	var surface := origin.y + size.y > 0
	# Ground heights: needed for the surface layers and for the cave crust near the top.
	var heights := PackedInt32Array()
	if origin.y + size.y > MeadowsShape.MIN_HEIGHT - CaveShape.WATER_CRUST:
		heights.resize(size.x * size.z)
		for z in size.z:
			for x in size.x:
				heights[x + z * size.x] = _shape.height_at(origin.x + x, origin.z + z)
	var ground_top := MeadowsShape.SEA_LEVEL
	for h in heights:
		ground_top = maxi(ground_top, h)
	if surface and origin.y >= ground_top:
		pass                   # all sky: only trees (below) can reach into it
	elif not surface and origin.y > MeadowsShape.WORLD_BOTTOM + 3:
		out_buffer.fill(BlockIds.DEEPSTONE, CH)
	else:
		for z in size.z:
			for x in size.x:
				_write_column(out_buffer, origin, x, z, heights[x + z * size.x] if surface else 0, surface)
	if not surface or origin.y < ground_top:
		var dry_caves := _carve(out_buffer, origin, heights)
		_place_ores(out_buffer, origin)
		_place_crystals(out_buffer, origin, dry_caves)
	if surface:
		for tz in range(origin.z - TREE_REACH, origin.z + size.z + TREE_REACH):
			for tx in range(origin.x - TREE_REACH, origin.x + size.x + TREE_REACH):
				if _shape.tree_at(tx, tz):
					_write_tree(out_buffer, origin, size, tx, tz)
	_place_secrets(out_buffer, origin)


## The secrets' boxes that reach into this buffer (every secret stays inside its own 128-block area, so
## a 16-block chunk usually looks at one area's few secrets).
func _place_secrets(buf: VoxelBuffer, origin: Vector3i) -> void:
	if deposits_enabled and _deposits != null:
		_deposits.write(buf, origin)   # spec §26: over the world's own ground only; the secrets come after
	if not secrets_enabled:
		return
	var end := origin + buf.get_size()
	var a0 := SecretRules.area_of(origin.x, origin.z)
	var a1 := SecretRules.area_of(end.x - 1, end.z - 1)
	for az in range(a0.y, a1.y + 1):
		for ax in range(a0.x, a1.x + 1):
			for s: Dictionary in _secrets.secrets_in_area(Vector2i(ax, az)) + _secrets.tiny_in_area(Vector2i(ax, az)):   # M3 Task 21c
				var lo: Vector3i = s.lo
				var hi: Vector3i = s.hi
				if hi.x <= origin.x or hi.y <= origin.y or hi.z <= origin.z or lo.x >= end.x or lo.y >= end.y or lo.z >= end.z:
					continue
				for b: Array in s.boxes:
					var bl: Vector3i = (b[0] as Vector3i).max(origin) - origin
					var bh: Vector3i = (b[1] as Vector3i).min(end) - origin
					if bl.x < bh.x and bl.y < bh.y and bl.z < bh.z:
						buf.fill_area(b[2], bl, bh, CH)


## One column: bedrock floor, deep stone below y = 0, stone, then the surface layers and water.
## `surface` is false for chunks entirely below y = 0 (no need to ask for the ground height).
func _write_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, h: int, surface: bool) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var bed := _shape.bedrock_top(wx, wz)
	_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
	if not surface:
		_fill_y(buf, origin, x, z, bed + 1, 0x7fffffff, BlockIds.DEEPSTONE)
		return
	var stone_top := h - 4
	_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.DEEPSTONE)
	_fill_y(buf, origin, x, z, 0, stone_top, BlockIds.STONE)
	var top := maxi(h, MeadowsShape.SEA_LEVEL)
	for wy in range(maxi(stone_top, origin.y), mini(top, origin.y + buf.get_size().y)):
		buf.set_voxel(_shape.column_block(wy, h, bed), x, wy - origin.y, z, CH)


## Carves tunnels, caverns and flooded deep caves. Noise is sampled on the world-aligned 4-block
## grid only; a 4³ cell is skipped when CaveShape proves nothing inside it can be a cave, and the
## rest is interpolated with exactly the operations of CaveShape.interpolate (so the result equals
## reference_block bit for bit — tested). heights: ground height per column, or empty when the
## chunk lies far below every crust. Where crystals can grow, decisions also cover one layer below
## and above the buffer (not written): returns the dry cave blocks (local coordinates, y may be -1
## or size.y) low enough to grow crystals next to.
func _carve(buf: VoxelBuffer, origin: Vector3i, heights: PackedInt32Array) -> Array[Vector3i]:
	var dry: Array[Vector3i] = []
	var cell_size := CaveShape.CELL
	var size := buf.get_size()
	if origin.y + size.y - 1 <= MeadowsShape.WORLD_BOTTOM + 3:
		return dry
	# Per column: carving is allowed below this height (the crusts under ground and water).
	var limits := PackedInt32Array()
	limits.resize(size.x * size.z)
	var top := 0x3fffffff
	if heights.is_empty():
		limits.fill(0x3fffffff)
	else:
		top = -0x3fffffff
		for i in heights.size():
			var h := heights[i]
			var limit := h - CaveShape.WATER_CRUST
			if not CaveShape.is_near_water(h):
				limit = h if _caves.entrance_open(origin.x + i % size.x, origin.z + i / size.x) else h - CaveShape.LAND_CRUST
			limits[i] = limit
			top = maxi(top, limit)
		if origin.y >= top:
			return dry
	var pad := 1 if origin.y < OreRules.CRYSTAL_MAX_Y else 0     # crystals need the neighbours
	var first := origin - Vector3i(0, pad, 0)
	var last := origin + size - Vector3i.ONE + Vector3i(0, pad, 0)
	var g0 := Vector3i(first.x - posmod(first.x, cell_size), first.y - posmod(first.y, cell_size), first.z - posmod(first.z, cell_size))
	var n := (last - g0) / cell_size + Vector3i(2, 2, 2)      # grid points per axis
	var grid := PackedVector3Array()
	grid.resize(n.x * n.y * n.z)
	for k in n.z:
		for j in n.y:
			for i in n.x:
				grid[i + n.x * (j + n.y * k)] = _caves.sample(g0.x + i * cell_size, g0.y + j * cell_size, g0.z + k * cell_size)
	var thresholds := PackedFloat64Array()                    # cavern threshold per padded row
	thresholds.resize(size.y + 2)
	for ly in range(-1, size.y + 1):
		thresholds[ly + 1] = _caves.cavern_threshold(origin.y + ly)
	var corners := PackedVector3Array()
	corners.resize(8)
	for k in n.z - 1:
		for j in n.y - 1:
			var cy := g0.y + j * cell_size
			if cy >= top:
				continue
			var t_bottom := _caves.cavern_threshold(cy)
			var t_top := _caves.cavern_threshold(cy + cell_size - 1)
			for i in n.x - 1:
				for c in 8:
					corners[c] = grid[(i + (c & 1)) + n.x * ((j + ((c >> 1) & 1)) + n.y * (k + ((c >> 2) & 1)))]
				if not CaveShape.cell_may_carve(corners, t_bottom, t_top):
					continue
				_carve_cell(buf, origin, g0 + Vector3i(i, j, k) * cell_size, corners, limits, thresholds, pad, dry)
	return dry


## Carves one 4³ cell. Interpolates like CaveShape.interpolate (x, then y, then z — the same
## Vector3 lerps in the same order), with the x lerps hoisted per column and the y lerps per row.
func _carve_cell(buf: VoxelBuffer, origin: Vector3i, cell: Vector3i, c: PackedVector3Array,
		limits: PackedInt32Array, thresholds: PackedFloat64Array, pad: int, dry: Array[Vector3i]) -> void:
	var cell_size := CaveShape.CELL
	var size := buf.get_size()
	var lo := (cell - origin).max(Vector3i(0, -pad, 0))
	var hi := (cell + Vector3i(cell_size, cell_size, cell_size) - origin).min(size + Vector3i(0, pad, 0))
	var floor_y := MeadowsShape.WORLD_BOTTOM + 3
	for lx in range(lo.x, hi.x):
		var fx := (origin.x + lx - cell.x) / float(cell_size)
		var z0y0 := c[0].lerp(c[1], fx)
		var z0y1 := c[2].lerp(c[3], fx)
		var z1y0 := c[4].lerp(c[5], fx)
		var z1y1 := c[6].lerp(c[7], fx)
		for ly in range(lo.y, hi.y):
			var wy := origin.y + ly
			if wy <= floor_y:
				continue
			var fy := (wy - cell.y) / float(cell_size)
			var near := z0y0.lerp(z0y1, fy)
			var far := z1y0.lerp(z1y1, fy)
			var threshold := thresholds[ly + 1]
			var id := BlockIds.WATER if wy < CaveShape.FLOOD_Y else BlockIds.AIR
			var inside := ly >= 0 and ly < size.y
			for lz in range(lo.z, hi.z):
				if wy >= limits[lx + lz * size.x]:
					continue
				var v := near.lerp(far, (origin.z + lz - cell.z) / float(cell_size))
				if not (absf(v.x) < CaveShape.TUNNEL_WIDTH and absf(v.y) < CaveShape.TUNNEL_WIDTH) and v.z <= threshold:
					continue
				if inside:
					buf.set_voxel(id, lx, ly, lz, CH)
				if id == BlockIds.AIR and wy <= OreRules.CRYSTAL_MAX_Y:
					dry.append(Vector3i(lx, ly, lz))


## Ore veins from every 16³ ore cell the buffer touches; they replace only stone and deep stone.
func _place_ores(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	var c0 := Vector3i(floori(origin.x / 16.0), floori(origin.y / 16.0), floori(origin.z / 16.0))
	var c1 := Vector3i(floori((origin.x + size.x - 1) / 16.0), floori((origin.y + size.y - 1) / 16.0), floori((origin.z + size.z - 1) / 16.0))
	for cy in range(c0.y, c1.y + 1):
		if cy * 16 > OreRules.DEPTH[BlockIds.COAL].y or cy * 16 + 15 < OreRules.DEPTH[BlockIds.GOLD].x:
			continue
		for cz in range(c0.z, c1.z + 1):
			for cx in range(c0.x, c1.x + 1):
				for vein: Dictionary in _ores.veins_in_cell(Vector3i(cx, cy, cz)):
					for p: Vector3i in vein.blocks:
						var l := p - origin
						if l.x < 0 or l.y < 0 or l.z < 0 or l.x >= size.x or l.y >= size.y or l.z >= size.z:
							continue
						var cur := buf.get_voxel(l.x, l.y, l.z, CH)
						if cur == BlockIds.STONE or cur == BlockIds.DEEPSTONE:
							buf.set_voxel(vein.ore, l.x, l.y, l.z, CH)


## Glowing crystals on stone right above or below a dry cave, deep down.
func _place_crystals(buf: VoxelBuffer, origin: Vector3i, dry_caves: Array[Vector3i]) -> void:
	var size_y := buf.get_size().y
	for a in dry_caves:
		for dy in [-1, 1]:
			var ly: int = a.y + dy
			if ly < 0 or ly >= size_y:
				continue
			var cur := buf.get_voxel(a.x, ly, a.z, CH)
			if (cur == BlockIds.STONE or cur == BlockIds.DEEPSTONE) and _ores.crystal_chance(origin + Vector3i(a.x, ly, a.z)):
				buf.set_voxel(BlockIds.CRYSTAL, a.x, ly, a.z, CH)


## The slow one-block reference of everything above except trees (used by tests and tools).
func reference_block(x: int, y: int, z: int) -> int:
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	return deposit_over(x, y, z, _natural_ref(x, y, z))


## Spec §26: a deposit's block over the world's own block at (x, y, z) (the fast path writes deposits after the terrain,
## the caves, the ores and the places, and before the secrets).
func deposit_over(x: int, y: int, z: int, natural: int) -> int:
	if deposits_enabled and _deposits != null:
		var dep := _deposits.block_at(Vector3i(x, y, z), natural)
		if dep >= 0:
			return dep
	return natural


## The terrain, caves, ores and crystals at (x, y, z), before deposits and secrets.
func _natural_ref(x: int, y: int, z: int) -> int:
	var h := _shape.height_at(x, z)
	var near_water := CaveShape.is_near_water(h)
	var entrance := _caves.entrance_open(x, z)
	var cave := _caves.decide(_caves.value_at(x, y, z), y, h, near_water, entrance)
	if cave >= 0:
		return cave
	var id := _shape.column_block(y, h, _shape.bedrock_top(x, z))
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


## Fills world heights [y0, y1) of column (x, z), clipped to the buffer.
func _fill_y(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, y0: int, y1: int, id: int) -> void:
	var a := clampi(y0 - origin.y, 0, buf.get_size().y)
	var b := clampi(y1 - origin.y, 0, buf.get_size().y)
	if b > a:
		buf.fill_area(id, Vector3i(x, a, z), Vector3i(x + 1, b, z + 1), CH)


func _write_tree(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int) -> void:
	var base := _shape.height_at(tx, tz)
	var trunk := _shape.tree_height(tx, tz)
	var top := base + trunk
	for dy in range(-2, 2):
		var radius := 2 if dy < 0 else 1
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if radius == 2 and absi(dx) == 2 and absi(dz) == 2:
					continue
				if dy == 1 and absi(dx) + absi(dz) > 1:
					continue
				_set_if_air(buf, origin, size, Vector3i(tx + dx, top + dy, tz + dz), BlockIds.LEAVES)
	for y in range(base, top):
		_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.LOG)


func _set_if_air(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, world: Vector3i, id: int) -> void:
	var l := world - origin
	if l.x < 0 or l.y < 0 or l.z < 0 or l.x >= size.x or l.y >= size.y or l.z >= size.z:
		return
	if buf.get_voxel(l.x, l.y, l.z, CH) == BlockIds.AIR:
		buf.set_voxel(id, l.x, l.y, l.z, CH)


func _set_inside(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, world: Vector3i, id: int) -> void:
	var l := world - origin
	if l.x < 0 or l.y < 0 or l.z < 0 or l.x >= size.x or l.y >= size.y or l.z >= size.z:
		return
	buf.set_voxel(id, l.x, l.y, l.z, CH)


## Spec §26: this world's deposits (null in a terrain without any).
func deposits() -> DepositRules:
	return _deposits
