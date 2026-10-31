class_name WondersGenerator
extends MeadowsGenerator
## World 41's terrain (owner #78, spec §24): Green Meadows' generator on WondersShape's ground, with the wonders built
## in (WonderBuilds, chunk by chunk from its buckets) after the ground and the trees and before the secrets
## (WondersSecretRules: the hidden rooms carve into them). No caves under the tour (none opens under a wonder or the
## sea; cheaper too), sand on Giza's plateau, the beach and the island, wild flowers in the park, olive trees and palms
## where they grow. The second tour's region (the New Seven Wonders, round WonderTour.NEW_SQUARE) the same: no caves,
## Petra's sand, flowers. The third tour's region (the Seven Natural Wonders, round WonderTour.NATURE_SQUARE) writes its
## columns from NatureGround's kinds (_write_nature_column: the canyon's rock layers, the snow, the beach and the sea,
## the volcano's cinders and its lava field, the falls' basalt, river and pool, the frozen lake), then its decorations
## (_place_nature: the corn, the coral heads, the falls' spray) and pines in the snow. Out past the tours it is Green
## Meadows' own generator (caves, ores, trees, secrets).

const NO_CAVES_R := WonderTour.BLEND_R + 16
const NO_CAVES_NEW_R := WonderTour.NEW_R + WonderTour.BLEND + 16
const NO_CAVES_NATURE_R := WonderTour.NATURE_R + WonderTour.BLEND + 16
const STONE_UNDER := 4                 # blocks of a column's top layers over the stone (dirt, sand, cinders, lava)


func _make_shape(value: int) -> MeadowsShape:
	return WondersShape.new(value)


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return WondersSecretRules.new(value, shape)


func wonders_shape() -> WondersShape:
	return _shape as WondersShape


## No caves under the tours: a chunk whose every column is within NO_CAVES_R (or NO_CAVES_NEW_R of the New Seven's
## square) keeps its rock whole.
func _carve(buf: VoxelBuffer, origin: Vector3i, heights: PackedInt32Array) -> Array[Vector3i]:
	var size := buf.get_size()
	var far := Vector2(maxf(absf(origin.x), absf(origin.x + size.x)), maxf(absf(origin.z), absf(origin.z + size.z)))
	if far.length() <= NO_CAVES_R:
		return [] as Array[Vector3i]
	var c := WonderTour.NEW_SQUARE
	var far_new := Vector2(maxf(absf(origin.x - c.x), absf(origin.x + size.x - c.x)),
		maxf(absf(origin.z - c.y), absf(origin.z + size.z - c.y)))
	if far_new.length() <= NO_CAVES_NEW_R:
		return [] as Array[Vector3i]
	var n := WonderTour.NATURE_SQUARE
	var far_nat := Vector2(maxf(absf(origin.x - n.x), absf(origin.x + size.x - n.x)),
		maxf(absf(origin.z - n.y), absf(origin.z + size.z - n.y)))
	if far_nat.length() <= NO_CAVES_NATURE_R:
		return [] as Array[Vector3i]
	return super(buf, origin, heights)


## One column as Green Meadows writes it, then sand on top where the tour is sandy; the nature region's its own way.
func _write_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, h: int, surface: bool) -> void:
	if surface and WonderTour.in_nature_region(origin.x + x, origin.z + z):
		_write_nature_column(buf, origin, x, z, (_shape as WondersShape).nature_sample(origin.x + x, origin.z + z))
		return
	super(buf, origin, x, z, h, surface)
	if surface and h > MeadowsShape.SEA_LEVEL + 1 and (_shape as WondersShape).sandy(origin.x + x, origin.z + z):
		_fill_y(buf, origin, x, z, h - 4, h, BlockIds.SAND)


## A column of the nature region (NatureGround: its height and kind): the bedrock and deep stone as everywhere, then
## its own layers and water.
func _write_nature_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, s: Vector2i) -> void:
	var h := s.x
	var bed := _shape.bedrock_top(origin.x + x, origin.z + z)
	_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
	_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.DEEPSTONE)
	var top := h - STONE_UNDER
	match s.y:
		NatureGround.CANYON, NatureGround.PLATEAU:   # the rock layers, the oldest at the bottom
			var layers := NatureGround.STRATA
			for i in layers.size():
				var to := layers[i + 1].x if i + 1 < layers.size() else 0x7fffffff
				_fill_y(buf, origin, x, z, maxi(layers[i].x, 0), mini(to, h), layers[i].y)
			if s.y == NatureGround.PLATEAU:
				_fill_y(buf, origin, x, z, h - 2, h - 1, BlockIds.DIRT)
				_fill_y(buf, origin, x, z, h - 1, h, BlockIds.GRASS)
			elif h <= NatureGround.RIVER_BED:
				_fill_y(buf, origin, x, z, h, NatureGround.CANYON_WATER_TOP, BlockIds.WATER)
			elif h == NatureGround.CANYON_WATER_TOP:
				_fill_y(buf, origin, x, z, h - 1, h, BlockIds.SAND)   # the river's banks
		NatureGround.MOUNTAIN:
			_fill_y(buf, origin, x, z, 0, h, BlockIds.STONE)
			if h - WonderTour.BASE_Y >= NatureGround.SNOW_LINE:
				_fill_y(buf, origin, x, z, h - 1, h, BlockIds.SNOW)
			elif h - WonderTour.BASE_Y <= 2:
				_fill_y(buf, origin, x, z, h - 1, h, BlockIds.SNOWY_GRASS)
		NatureGround.CINDER:
			_fill_y(buf, origin, x, z, 0, h - 6, BlockIds.STONE)
			_fill_y(buf, origin, x, z, h - 6, h, BlockIds.CINDER)
		NatureGround.LAVA:
			_fill_y(buf, origin, x, z, 0, top, BlockIds.STONE)
			_fill_y(buf, origin, x, z, top, h, BlockIds.BLACK_LAVA)
		NatureGround.CHASM:   # basalt, a pool at the bottom
			_fill_y(buf, origin, x, z, 0, h, BlockIds.BLACK_LAVA)
			_fill_y(buf, origin, x, z, h, NatureGround.POOL_TOP, BlockIds.WATER)
		NatureGround.RIVER:
			_fill_y(buf, origin, x, z, 0, h - 1, BlockIds.BLACK_LAVA)
			_fill_y(buf, origin, x, z, h - 1, h, BlockIds.SAND)
			_fill_y(buf, origin, x, z, h, NatureGround.RIVER_TOP, BlockIds.WATER)
		NatureGround.BASALT_LAND:
			_fill_y(buf, origin, x, z, 0, h - 2, BlockIds.BLACK_LAVA)
			_fill_y(buf, origin, x, z, h - 2, h - 1, BlockIds.DIRT)
			_fill_y(buf, origin, x, z, h - 1, h, BlockIds.GRASS)
		NatureGround.ROCK:
			_fill_y(buf, origin, x, z, 0, h, BlockIds.STONE)
			_fill_y(buf, origin, x, z, h, MeadowsShape.SEA_LEVEL, BlockIds.WATER)
		NatureGround.BEACH, NatureGround.SEA_FLOOR, NatureGround.REEF:
			_fill_y(buf, origin, x, z, 0, top, BlockIds.STONE)
			_fill_y(buf, origin, x, z, top, h, BlockIds.SAND)
			_fill_y(buf, origin, x, z, h, MeadowsShape.SEA_LEVEL, BlockIds.WATER)
		NatureGround.LAKE_ICE:   # ice over water over the lake's bed
			_fill_y(buf, origin, x, z, 0, top, BlockIds.STONE)
			_fill_y(buf, origin, x, z, top, h - 3, BlockIds.DIRT)
			_fill_y(buf, origin, x, z, h - 3, h - 1, BlockIds.WATER)
			_fill_y(buf, origin, x, z, h - 1, h, BlockIds.ICE)
		NatureGround.SNOW:
			_fill_y(buf, origin, x, z, 0, top, BlockIds.STONE)
			_fill_y(buf, origin, x, z, top, h - 1, BlockIds.DIRT)
			_fill_y(buf, origin, x, z, h - 1, h, BlockIds.SNOWY_GRASS)
		_:   # the park's grass and the cornfield
			_fill_y(buf, origin, x, z, 0, top, BlockIds.STONE)
			_fill_y(buf, origin, x, z, top, h - 1, BlockIds.DIRT)
			_fill_y(buf, origin, x, z, h - 1, h, BlockIds.GRASS)


## The wonders, then the secrets (which may carve into them).
func _place_secrets(buf: VoxelBuffer, origin: Vector3i) -> void:
	_place_wonders(buf, origin)
	super(buf, origin)


func _place_wonders(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	var end := origin + size
	if origin.y <= WonderTour.BASE_Y and WonderTour.BASE_Y < end.y:
		_place_flowers(buf, origin)
	_place_nature(buf, origin)
	var cx := floori(origin.x / 16.0)
	var cz := floori(origin.z / 16.0)
	if size.x == 16 and size.z == 16 and posmod(origin.x, 16) == 0 and posmod(origin.z, 16) == 0:
		_fill_boxes(buf, origin, end, WonderBuilds.column_boxes(cx, cz))
		return
	var seen := {}
	for bz in range(cz, floori((end.z - 1) / 16.0) + 1):
		for bx in range(cx, floori((end.x - 1) / 16.0) + 1):
			for box: Array in WonderBuilds.column_boxes(bx, bz):
				if not seen.has(box):
					seen[box] = true
					_fill_boxes(buf, origin, end, [box])


## The nature region's decorations in this buffer: the corn in Parícutin's field (two tall), the coral heads on the
## reef flat (in the water), the falls' spray (the plume over the chasm, the mist over the pool). Each only where its
## box meets the buffer, and only into air (or the reef's water).
func _place_nature(buf: VoxelBuffer, origin: Vector3i) -> void:
	var end := origin + buf.get_size()
	var p := NatureGround.PARICUTIN_C
	var r := int(NatureGround.FARM_R)
	var y := WonderTour.BASE_Y
	if origin.y <= y + 1 and y < end.y and _meets(origin, end, p.x - r, p.y - r, p.x + r, p.y + r):
		for z in range(maxi(origin.z, p.y - r), mini(end.z, p.y + r + 1)):
			for x in range(maxi(origin.x, p.x - r), mini(end.x, p.x + r + 1)):
				if NatureGround.corn_at(x, z):
					for dy in 2:
						_set_into(buf, origin, Vector3i(x, y + dy, z), BlockIds.CORN, BlockIds.AIR)
	var k := NatureGround.REEF_C
	var kr := int(NatureGround.REEF_R)
	var floor_y := NatureGround.REEF_FLOOR
	if origin.y <= floor_y + 2 and floor_y < end.y and _meets(origin, end, k.x - kr, k.y - kr, k.x + kr, k.y + kr):
		for z in range(maxi(origin.z, k.y - kr), mini(end.z, k.y + kr + 1)):
			for x in range(maxi(origin.x, k.x - kr), mini(end.x, k.x + kr + 1)):
				var head := NatureGround.coral_at(x, z)
				if not head.is_empty():
					for dy in int(head[1]):
						_set_into(buf, origin, Vector3i(x, floor_y + dy, z), head[0], BlockIds.WATER)
	var f := NatureGround.FALLS_C
	if origin.y <= NatureGround.SPRAY_HIGH and end.y > NatureGround.POOL_TOP \
			and _meets(origin, end, f.x - 24, f.y - 2, f.x + 24, f.y + 2):
		for z in range(maxi(origin.z, f.y - 2), mini(end.z, f.y + 3)):
			for x in range(maxi(origin.x, f.x - 24), mini(end.x, f.x + 25)):
				for wy in range(maxi(origin.y, NatureGround.POOL_TOP), mini(end.y, NatureGround.SPRAY_HIGH + 1)):
					if NatureGround.spray_at(x, wy, z):
						_set_into(buf, origin, Vector3i(x, wy, z), BlockIds.SPRAY, BlockIds.AIR)


## The box [x0, x1] x [z0, z1] (inclusive) meets the buffer's columns.
static func _meets(origin: Vector3i, end: Vector3i, x0: int, z0: int, x1: int, z1: int) -> bool:
	return x1 >= origin.x and x0 < end.x and z1 >= origin.z and z0 < end.z


## Sets world cell p to `id` if it is in the buffer and holds `over` now.
func _set_into(buf: VoxelBuffer, origin: Vector3i, p: Vector3i, id: int, over: int) -> void:
	var l := p - origin
	var size := buf.get_size()
	if l.x < 0 or l.y < 0 or l.z < 0 or l.x >= size.x or l.y >= size.y or l.z >= size.z:
		return
	if buf.get_voxel(l.x, l.y, l.z, CH) == over:
		buf.set_voxel(id, l.x, l.y, l.z, CH)


## Wild flowers dot the park's grass (the chunk that holds the tour's ground level).
func _place_flowers(buf: VoxelBuffer, origin: Vector3i) -> void:
	var size := buf.get_size()
	var far := WonderTour.FLAT_R + 16
	var c := WonderTour.NEW_SQUARE
	var far_new := WonderTour.NEW_R + 16
	var n := WonderTour.NATURE_SQUARE
	var far_nat := WonderTour.NATURE_R + 16
	if (absi(origin.x) > far or absi(origin.z) > far) and (absi(origin.x - c.x) > far_new or absi(origin.z - c.y) > far_new) \
			and (absi(origin.x - n.x) > far_nat or absi(origin.z - n.y) > far_nat):
		return
	var shape := _shape as WondersShape
	var ly := WonderTour.BASE_Y - origin.y
	for z in size.z:
		for x in size.x:
			if shape.flower_at(origin.x + x, origin.z + z) and buf.get_voxel(x, ly, z, CH) == BlockIds.AIR:
				buf.set_voxel(BlockIds.FLOWERS, x, ly, z, CH)


func _fill_boxes(buf: VoxelBuffer, origin: Vector3i, end: Vector3i, boxes: Array) -> void:
	for b: Array in boxes:
		var lo: Vector3i = b[0]
		var hi: Vector3i = b[1]
		if hi.y <= origin.y or lo.y >= end.y or hi.x <= origin.x or lo.x >= end.x or hi.z <= origin.z or lo.z >= end.z:
			continue
		buf.fill_area(b[2], lo.max(origin) - origin, hi.min(end) - origin, CH)


## Olive trees to the west, palms on the sand and by Babylon, pines in the nature region's snow and on the canyon's
## plateau, Green Meadows' oaks elsewhere.
func _write_tree(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int) -> void:
	match (_shape as WondersShape).tree_kind(tx, tz):
		&"palm":
			_write_palm(buf, origin, size, tx, tz)
		&"olive":
			_write_olive(buf, origin, size, tx, tz)
		&"pine":
			_write_pine(buf, origin, size, tx, tz)
		_:
			super(buf, origin, size, tx, tz)


## A pine: a trunk in a cone of needles, as Frostpeak's (its crown's layers), 5 to 7 logs tall.
func _write_pine(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int) -> void:
	var base := _shape.height_at(tx, tz)
	var top := base + _shape.tree_height(tx, tz) + 1
	if base >= origin.y + size.y or top + 2 <= origin.y:
		return   # (the chunk's other stacks: nothing of this tree in them)
	for dy: int in [1, 0, -1, -2, -3, -4]:
		var r: int = {1: 0, 0: 1, -1: 1, -2: 2, -3: 1, -4: 2}[dy]
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if (dy == 0 and absi(dx) + absi(dz) > 1) or (r == 2 and absi(dx) == 2 and absi(dz) == 2):
					continue
				_set_if_air(buf, origin, size, Vector3i(tx + dx, top + dy, tz + dz), BlockIds.PINE_NEEDLES)
	for y in range(base, top):
		_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.PINE_LOG)


func _write_palm(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int) -> void:
	var base := _shape.height_at(tx, tz)
	var top := base + _shape.tree_height(tx, tz) + 1
	for y in range(base, top):
		_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.PALM_LOG)
	for d in range(-2, 3):
		_set_if_air(buf, origin, size, Vector3i(tx + d, top, tz), BlockIds.PALM_LEAVES)
		_set_if_air(buf, origin, size, Vector3i(tx, top, tz + d), BlockIds.PALM_LEAVES)
	_set_if_air(buf, origin, size, Vector3i(tx, top + 1, tz), BlockIds.PALM_LEAVES)


## An olive tree: a short, thick trunk and a wide, low crown of silvery leaves.
func _write_olive(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, tx: int, tz: int) -> void:
	var base := _shape.height_at(tx, tz)
	var top := base + 3
	for dy in range(0, 2):
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if absi(dx) + absi(dz) > (3 if dy == 0 else 2):
					continue
				_set_if_air(buf, origin, size, Vector3i(tx + dx, top + dy, tz + dz), BlockIds.OLIVE_LEAVES)
	for y in range(base, top + 1):
		_set_inside(buf, origin, size, Vector3i(tx, y, tz), BlockIds.DARK_LOG)
