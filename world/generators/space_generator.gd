class_name SpaceGenerator
extends MeadowsGenerator
## The space worlds' terrain for VoxelTerrain (owner feedback #55, spec §21.2; runs on worker threads): SpaceShape's
## ground for `planet` (set before world_seed), the landing pad, ore veins in the planet's rock, its features and
## SpaceSecretRules' secrets, written fast: whole-column fills, no caves, no water. reference_block() is the slow
## one-block rule the tests compare the fast path against (features and secrets included). Mars (cosmos, spec §21b.2):
## each column's region (MarsTerrain's kind, worked out with its ground in the stack) picks its layers; Europa, Io, Titan
## and Mercury the same with their own terrain (Io: IoTerrain's kinds, its rock in layers of black lava; Mercury:
## MercuryTerrain's kinds over its grey rock). Spec §21c: the Moon's and Mars's colony under domes (ColonyLayout's boxes)
## over the terrain, the ores and the features. Venus's cloud city (cosmos, spec §21b.2): the clouds far below in every
## column, the platforms' hulls and decks and the bridges over them (VenusTerrain's columns), its features (lamp posts,
## flowers, little trees) and its built parts (VenusTerrain.write); no ores (no rock in the clouds). Saturn's rings
## (cosmos, spec §21b.2): open space everywhere (no bedrock, no deep rock), the chunks' spans of ice over it
## (RingsTerrain's columns), the built parts (RingsTerrain.write) and the secrets; no features, no ores. Pluto (cosmos,
## spec §21b.2): PlutoTerrain's kinds over its water ice (the plain's nitrogen ice filling its basin, a floating hill's
## water ice reaching down into it, the red-brown lands' tholins over red ice), ores in the water ice, its features and
## the Charon Lookout by the pad (PlutoTerrain.write, with the colonies' flag). Triton (cosmos, spec §21b.2):
## TritonTerrain's kinds over its icy mantle of water ice (the band's frost over a crust of nitrogen ice, the cap's pink
## ice, the geysers' dust and vents, the cantaloupe terrain's ice, the frozen lake's layers of ice lava), ores in the water
## ice, its features and the Neptune Lookout by the pad (TritonTerrain.write, with the colonies' flag). Ganymede (cosmos,
## spec §21b.2): GanymedeTerrain's kinds over its icy crust of water ice (the plain's and the grooves' bright ice, the
## grooves' floors, the dark terrain's dark ice over old ice, the ray crater's fresh ice, the poles' frost), ores in the
## water ice, its features and its built parts (GanymedeTerrain.write, with the colonies' flag: the Jupiter Lookout, the
## Aurora Watch, the ocean drill and its shaft). Spec §26.5: the
## Moon's and Mars's rich deposits (DepositRules, SpaceDepositSites) with the secrets (MeadowsGenerator._place_secrets),
## over the planet's own ground; reference_block applies them the same way (deposit_over).

const SKY_TOP := 144             # nothing but secrets (the landmarks' tops) reaches this high

## The planet (SpaceShape.MOON, …); set before world_seed (setting it remakes the rules).
var planet: StringName = SpaceShape.MOON:
	set(value):
		planet = value
		world_seed = world_seed

var _rock := PackedInt32Array()
## Spec §21c: off, the colony's boxes are not written (its ground stays flat): the generator bench's "without".
var colony_enabled := true


func _init() -> void:
	world_seed = 0


func space_shape() -> SpaceShape:
	return _shape as SpaceShape


func _make_shape(value: int) -> MeadowsShape:
	var s := SpaceShape.new(value, planet)
	_rock = PackedInt32Array(s.rock_ids())
	_stack_mutex.lock()
	_stacks.clear()   # another seed or planet: other stacks
	_stack_mutex.unlock()
	return s


func _make_secrets(value: int, shape: MeadowsShape) -> SecretRules:
	return SpaceSecretRules.new(value, shape)


func _generate_block(out_buffer: VoxelBuffer, origin: Vector3i, lod: int) -> void:
	if lod != 0:
		return
	var shape := _shape as SpaceShape
	var size := out_buffer.get_size()
	if origin.y >= SKY_TOP:
		_place_secrets(out_buffer, origin)
		return
	if shape.planet == SpaceShape.RINGS:   # open space round the chunks: nothing under them
		_generate_rings(out_buffer, origin, shape)
		return
	if origin.y + size.y <= 0:   # under y 0: deep rock, bedrock at the bottom, ores
		if origin.y > MeadowsShape.WORLD_BOTTOM + 3:
			out_buffer.fill(shape.deep_block(), CH)
		else:
			for z in size.z:
				for x in size.x:
					var bed := shape.bedrock_top(origin.x + x, origin.z + z)
					_fill_y(out_buffer, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
					_fill_y(out_buffer, origin, x, z, bed + 1, 0x7fffffff, shape.deep_block())
		_place_space_ores(out_buffer, origin)
		if shape.planet == SpaceShape.EUROPA:
			_carve_europa_well(out_buffer, origin, shape)   # the ocean's deepest water is under y 0
		_place_secrets(out_buffer, origin)
		return
	var stack := _stack(origin.x, origin.z, size, shape)
	if shape.planet == SpaceShape.VENUS:
		_generate_venus(out_buffer, origin, shape, stack)
		return
	if origin.y >= int(stack.top):   # above the ground and every feature: only the colony's tall parts and secrets
		_place_colony(out_buffer, origin, shape)
		_place_secrets(out_buffer, origin)
		return
	var grounds: PackedInt32Array = stack.grounds
	if origin.y < int(stack.ground):
		if shape.planet == SpaceShape.MARS:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # rock in every column up to here
			if solid > y0:
				_fill_mars_layers(out_buffer, origin, y0, solid)
				for i: int in stack.volcanic:
					_fill_y(out_buffer, origin, i % size.x, i / size.x, y0, solid, BlockIds.BASALT)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_mars_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape, rock_from)
		elif shape.planet == SpaceShape.EUROPA:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # layered ice in every column up to here
			if solid > y0:
				_fill_europa_layers(out_buffer, origin, y0, solid)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_europa_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape, rock_from)
		elif shape.planet == SpaceShape.IO:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # layered rock in every column up to here
			if solid > y0:
				_fill_io_layers(out_buffer, origin, y0, solid)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_io_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape, rock_from)
		elif shape.planet == SpaceShape.TITAN:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # icy rock in every column up to here
			if solid > y0:
				out_buffer.fill_area(BlockIds.ICY_ROCK, Vector3i(0, y0 - origin.y, 0), Vector3i(size.x, solid - origin.y, size.z), CH)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_titan_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape,
						rock_from)
		elif shape.planet == SpaceShape.MERCURY:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # grey rock in every column up to here
			if solid > y0:
				out_buffer.fill_area(BlockIds.MERCURY_ROCK, Vector3i(0, y0 - origin.y, 0), Vector3i(size.x, solid - origin.y,
					size.z), CH)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_mercury_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape,
						rock_from)
		elif shape.planet == SpaceShape.PLUTO:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # water ice in every column up to here
			if solid > y0:
				out_buffer.fill_area(BlockIds.WATER_ICE, Vector3i(0, y0 - origin.y, 0), Vector3i(size.x, solid - origin.y,
					size.z), CH)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_pluto_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape,
						rock_from)
		elif shape.planet == SpaceShape.TRITON:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # the icy mantle in every column up to here
			if solid > y0:
				out_buffer.fill_area(BlockIds.WATER_ICE, Vector3i(0, y0 - origin.y, 0), Vector3i(size.x, solid - origin.y,
					size.z), CH)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_triton_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape,
						rock_from)
		elif shape.planet == SpaceShape.GANYMEDE:
			var kinds: PackedByteArray = stack.kinds
			var y0 := maxi(origin.y, 0)
			var solid := mini(int(stack.rock_floor), origin.y + size.y)   # the icy crust in every column up to here
			if solid > y0:
				out_buffer.fill_area(BlockIds.WATER_ICE, Vector3i(0, y0 - origin.y, 0), Vector3i(size.x, solid - origin.y,
					size.z), CH)
			var rock_from := maxi(solid, y0)
			for z in size.z:
				for x in size.x:
					_write_ganymede_column(out_buffer, origin, x, z, grounds[x + z * size.x], kinds[x + z * size.x], shape,
						rock_from)
		else:
			for z in size.z:
				for x in size.x:
					_write_space_column(out_buffer, origin, x, z, grounds[x + z * size.x], shape)
		_place_space_ores(out_buffer, origin)
		if shape.planet == SpaceShape.EUROPA:
			_carve_europa_well(out_buffer, origin, shape)
	_place_features(out_buffer, origin, size, shape, stack.trees)
	_place_colony(out_buffer, origin, shape)
	_place_secrets(out_buffer, origin)


## Spec §21c: the colony under domes (the Moon's, Mars's) where its boxes reach into this buffer, over the terrain, its
## ores and features (none grow there), under the secrets (none are there). Pluto: the Charon Lookout by the pad, the same
## way; Triton: the Neptune Lookout; Ganymede: the Jupiter Lookout, the Aurora Watch and the ocean drill.
func _place_colony(buf: VoxelBuffer, origin: Vector3i, shape: SpaceShape) -> void:
	if colony_enabled and shape.colony != null:
		shape.colony.write(buf, origin)
	if colony_enabled and shape.pluto != null:
		shape.pluto.write(buf, origin)
	if colony_enabled and shape.triton != null:
		shape.triton.write(buf, origin)
	if colony_enabled and shape.ganymede != null:
		shape.ganymede.write(buf, origin)


# --- A chunk column's stack, worked out once for all its chunks ------------------------------------------

const STACK_CACHE := 1024
var _stacks := {}
var _stack_mutex := Mutex.new()


## The columns of the chunk stack at (ox, oz): {grounds (the solid ground), ground (the top of every column, a pool's
## jelly too), trees ([tx, tz, …] of every feature within reach), top (above the ground and every feature), and on Mars
## kinds (each column's region), rock_floor (the rock's top in the lowest column: under it every column is rock) and
## volcanic (the columns whose rock is all basalt)}, cached (a stack's 16 chunks share it; the terrain's threads too).
func _stack(ox: int, oz: int, size: Vector3i, shape: SpaceShape) -> Dictionary:
	var key := Vector2i(ox, oz)
	_stack_mutex.lock()
	var got: Variant = _stacks.get(key)
	_stack_mutex.unlock()
	if got != null:
		return got
	var kinds := PackedByteArray()
	var grounds: PackedInt32Array
	if shape.planet == SpaceShape.MARS:
		var cols := shape.mars_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.EUROPA:   # the ice's tops (the well is cut after the layers)
		var cols := shape.europa_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.IO:
		var cols := shape.io_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.TITAN:
		var cols := shape.titan_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.MERCURY:
		var cols := shape.mercury_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.PLUTO:
		var cols := shape.pluto_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.TRITON:
		var cols := shape.triton_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.GANYMEDE:
		var cols := shape.ganymede_columns(ox, oz, size.x, size.z)
		grounds = cols[0]
		kinds = cols[1]
	elif shape.planet == SpaceShape.VENUS:
		var s := _venus_stack(ox, oz, size, shape)
		_stack_mutex.lock()
		if _stacks.size() >= STACK_CACHE:
			_stacks.clear()
		_stacks[key] = s
		_stack_mutex.unlock()
		return s
	else:
		grounds = shape.grounds(ox, oz, size.x, size.z)
	var ground := -0x7fffffff
	for g in grounds:
		ground = maxi(ground, shape.top_of(g))
	var top := ground
	var trees := PackedInt32Array()
	var r := shape.feature_reach()
	for tz in range(oz - r, oz + size.z + r):
		for tx in range(ox - r, ox + size.x + r):
			if shape.tree_at(tx, tz):
				trees.append_array([tx, tz])
				top = maxi(top, shape.height_at(tx, tz) + shape.feature_top(tx, tz) + 1)
	var s := {"grounds": grounds, "ground": ground, "trees": trees, "top": top, "kinds": kinds}
	if shape.planet == SpaceShape.MARS:
		var rock_floor := 0x7fffffff
		var volcanic := PackedInt32Array()
		for i in grounds.size():
			rock_floor = mini(rock_floor, grounds[i] - 1 - MarsTerrain.sub_depth(kinds[i], grounds[i]))
			if MarsTerrain.is_volcanic(kinds[i]):
				volcanic.append(i)
		s.rock_floor = rock_floor
		s.volcanic = volcanic
	elif shape.planet == SpaceShape.EUROPA:
		var rock_floor := 0x7fffffff
		for g in grounds:
			rock_floor = mini(rock_floor, g - 1 - EuropaTerrain.SUB_DEPTH)
		s.rock_floor = rock_floor
	elif shape.planet == SpaceShape.IO:
		var rock_floor := 0x7fffffff
		for i in grounds.size():
			rock_floor = mini(rock_floor, grounds[i] - 1 - IoTerrain.sub_depth(kinds[i]))
		s.rock_floor = rock_floor
	elif shape.planet == SpaceShape.TITAN:
		var rock_floor := 0x7fffffff
		for i in grounds.size():
			rock_floor = mini(rock_floor, grounds[i] - 1 - TitanTerrain.sub_depth(kinds[i]))
		s.rock_floor = rock_floor
	elif shape.planet == SpaceShape.MERCURY:
		var rock_floor := 0x7fffffff
		for i in grounds.size():
			rock_floor = mini(rock_floor, grounds[i] - 1 - MercuryTerrain.sub_depth(kinds[i]))
		s.rock_floor = rock_floor
	elif shape.planet == SpaceShape.PLUTO:
		var rock_floor := 0x7fffffff
		for i in grounds.size():
			rock_floor = mini(rock_floor, grounds[i] - 1 - PlutoTerrain.sub_depth(kinds[i], grounds[i]))
		s.rock_floor = rock_floor
	elif shape.planet == SpaceShape.TRITON:
		var rock_floor := 0x7fffffff
		for i in grounds.size():
			rock_floor = mini(rock_floor, grounds[i] - 1 - TritonTerrain.sub_depth(kinds[i]))
		s.rock_floor = rock_floor
	elif shape.planet == SpaceShape.GANYMEDE:
		var rock_floor := 0x7fffffff
		for i in grounds.size():
			rock_floor = mini(rock_floor, grounds[i] - 1 - GanymedeTerrain.SUB_DEPTH)
		s.rock_floor = rock_floor
	_stack_mutex.lock()
	if _stacks.size() >= STACK_CACHE:
		_stacks.clear()
	_stacks[key] = s
	_stack_mutex.unlock()
	return s


## Saturn's rings: a chunk stack's columns ({tops, kinds, bottoms, top (over every chunk), bottom (under every chunk;
## past `top` when there is none)}), cached like the others.
func _rings_stack(ox: int, oz: int, size: Vector3i, shape: SpaceShape) -> Dictionary:
	var key := Vector2i(ox, oz)
	_stack_mutex.lock()
	var got: Variant = _stacks.get(key)
	_stack_mutex.unlock()
	if got != null:
		return got
	var cols := shape.rings.columns(ox, oz, size.x, size.z)
	var tops: PackedInt32Array = cols[0]
	var kinds: PackedByteArray = cols[1]
	var bottoms: PackedInt32Array = cols[2]
	var top := -0x7fffffff
	var bottom := 0x7fffffff
	for i in tops.size():
		if kinds[i] != RingsTerrain.VOID:
			top = maxi(top, tops[i])
			bottom = mini(bottom, bottoms[i])
	var s := {"tops": tops, "kinds": kinds, "bottoms": bottoms, "top": top, "bottom": bottom}
	_stack_mutex.lock()
	if _stacks.size() >= STACK_CACHE:
		_stacks.clear()
	_stacks[key] = s
	_stack_mutex.unlock()
	return s


## Saturn's rings' chunk: each column's span of ice (its top block on top, the landing pad on the pad) where it reaches
## into the buffer, the built parts, the secrets. Everything else stays open space (the buffer's air).
func _generate_rings(buf: VoxelBuffer, origin: Vector3i, shape: SpaceShape) -> void:
	var size := buf.get_size()
	var end_y := origin.y + size.y
	if end_y > RingsTerrain.LIFT_Y - 16 and origin.y < RingsTerrain.TOP_BASE + 16:
		var stack := _rings_stack(origin.x, origin.z, size, shape)
		if end_y > int(stack.bottom) and origin.y < int(stack.top):
			var kinds: PackedByteArray = stack.kinds
			var tops: PackedInt32Array = stack.tops
			var bottoms: PackedInt32Array = stack.bottoms
			for z in size.z:
				for x in size.x:
					var i := x + z * size.x
					var k := kinds[i]
					if k == RingsTerrain.VOID:
						continue
					var t := tops[i]
					_fill_y(buf, origin, x, z, bottoms[i], t - 1, RingsTerrain.under_block(k))
					if t - 1 >= origin.y and t - 1 < end_y:
						var id := BlockIds.LANDING_PAD if shape.pad_at(origin.x + x, origin.z + z) else RingsTerrain.top_block(k)
						buf.set_voxel(id, x, t - 1 - origin.y, z, CH)
	if colony_enabled:
		shape.rings.write(buf, origin)
	_place_secrets(buf, origin)


## Venus: a chunk stack's columns ({tops, kinds, bottoms, clouds, ground (the highest top), top (over every feature and
## built part), trees ([tx, tz, feature, …]), cloud_floor (the lowest cloud top: under it every column is deep cloud),
## cloud_top (over every cloud top), deck_floor (the lowest platform or bridge block; INF: none)}).
func _venus_stack(ox: int, oz: int, size: Vector3i, shape: SpaceShape) -> Dictionary:
	var v := shape.venus
	var cols := v.columns(ox, oz, size.x, size.z)
	var tops: PackedInt32Array = cols[0]
	var kinds: PackedByteArray = cols[1]
	var bottoms: PackedInt32Array = cols[2]
	var clouds: PackedInt32Array = cols[3]
	var ground := -0x7fffffff
	var cloud_floor := 0x7fffffff
	var cloud_top := -0x7fffffff
	var deck_floor := 0x7fffffff
	for i in tops.size():
		ground = maxi(ground, tops[i])
		cloud_floor = mini(cloud_floor, clouds[i])
		cloud_top = maxi(cloud_top, clouds[i])
		if kinds[i] != VenusTerrain.CLOUD:
			deck_floor = mini(deck_floor, bottoms[i])
	var r := shape.feature_reach()
	var trees := v.features(ox - r, oz - r, size.x + 2 * r, size.z + 2 * r, SpaceShape.BLEND_RADIUS)
	var top := ground
	for i in range(0, trees.size(), 3):
		top = maxi(top, VenusTerrain.DECK_Y + VenusTerrain.feature_height(trees[i + 2]) + 1)
	return {"tops": tops, "kinds": kinds, "bottoms": bottoms, "clouds": clouds, "ground": ground, "top": top,
		"trees": trees, "cloud_floor": cloud_floor, "cloud_top": cloud_top, "deck_floor": deck_floor}


## Venus's chunk: the clouds in every column (deep clouds under their yellow tops), the platforms' float hulls and decks
## and the bridges' keels and planks over them (the landing pad on the pad), the features, the city's built parts, the
## secrets. Under y 0 the generic deep path fills the deep clouds (deep_block).
func _generate_venus(buf: VoxelBuffer, origin: Vector3i, shape: SpaceShape, stack: Dictionary) -> void:
	var size := buf.get_size()
	var end_y := origin.y + size.y
	var cloud_floor: int = stack.cloud_floor
	var solid := mini(cloud_floor - 1, end_y)   # every column is deep cloud under its top block up to here
	if solid > origin.y:
		buf.fill_area(BlockIds.DEEP_CLOUD, Vector3i.ZERO, Vector3i(size.x, solid - origin.y, size.z), CH)
	if origin.y < int(stack.cloud_top) and end_y > cloud_floor - 1:
		var clouds: PackedInt32Array = stack.clouds
		var from := maxi(origin.y, cloud_floor - 1)
		for z in size.z:
			for x in size.x:
				var c := clouds[x + z * size.x]
				_fill_y(buf, origin, x, z, from, c - 1, BlockIds.DEEP_CLOUD)
				if c - 1 >= origin.y and c - 1 < end_y:
					buf.set_voxel(BlockIds.VENUS_CLOUD, x, c - 1 - origin.y, z, CH)
	if end_y > int(stack.deck_floor) and origin.y < VenusTerrain.DECK_Y:
		var kinds: PackedByteArray = stack.kinds
		var tops: PackedInt32Array = stack.tops
		var bottoms: PackedInt32Array = stack.bottoms
		for z in size.z:
			for x in size.x:
				var i := x + z * size.x
				var k := kinds[i]
				if k == VenusTerrain.CLOUD:
					continue
				var t := tops[i]
				_fill_y(buf, origin, x, z, bottoms[i], t - 1, VenusTerrain.under_block(k))
				if t - 1 >= origin.y and t - 1 < end_y:
					var id := BlockIds.LANDING_PAD if shape.pad_at(origin.x + x, origin.z + z) else VenusTerrain.top_block(k)
					buf.set_voxel(id, x, t - 1 - origin.y, z, CH)
	if origin.y < int(stack.top):
		_place_venus_features(buf, origin, size, stack.trees)
	if colony_enabled:
		shape.venus.write(buf, origin)
	_place_secrets(buf, origin)


## Venus's features ([tx, tz, feature, …]), standing on the decks and bridges (all at VenusTerrain.DECK_Y), into the
## buffer's air only.
func _place_venus_features(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, trees: PackedInt32Array) -> void:
	var base := VenusTerrain.DECK_Y
	for i in range(0, trees.size(), 3):
		var tx := trees[i]
		var tz := trees[i + 1]
		var f := trees[i + 2]
		var y0 := maxi(base, origin.y)
		var y1 := mini(base + VenusTerrain.feature_height(f), origin.y + size.y)
		for y in range(y0, y1):
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var p := Vector3i(tx + dx, y, tz + dz)
					var l := p - origin
					if l.x < 0 or l.z < 0 or l.x >= size.x or l.z >= size.z:
						continue
					var id := VenusTerrain.feature_block(f, tx, tz, base, p)
					if id >= 0 and buf.get_voxel(l.x, l.y, l.z, CH) == BlockIds.AIR:
						buf.set_voxel(id, l.x, l.y, l.z, CH)


## One column over solid ground g: bedrock, deep rock under y 0, the planet's rock (Rainbow Planet: its stripes) and
## surface layers, the top block (the landing pad on the pad), a Boing pool's jelly (SpaceShape.block_at's rule).
func _write_space_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, shape: SpaceShape) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	var h := shape.top_of(g)
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, shape.deep_block())
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, shape.deep_block())
	if shape.planet == SpaceShape.RAINBOW:
		var y := maxi(0, origin.y)
		var end := mini(g - 1, top)
		while y < end:   # stripe by stripe
			var seg := mini((floori(y / float(SpaceShape.STRIPE_HEIGHT)) + 1) * SpaceShape.STRIPE_HEIGHT, end)
			_fill_y(buf, origin, x, z, y, seg, SpaceShape.stripe(y))
			y = seg
	else:
		var rock_top := g - shape.surface_depth()
		if rock_top > origin.y and top > 0:
			_fill_y(buf, origin, x, z, 0, rock_top, shape.rock_block())
		for wy in range(maxi(maxi(rock_top, 0), origin.y), mini(g - 1, top)):
			buf.set_voxel(shape.ground_block(wy, g, h), x, wy - origin.y, z, CH)
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else shape.ground_block(ty, g, h), x, ty - origin.y, z, CH)
	if h > g:
		_fill_y(buf, origin, x, z, g, h, BlockIds.JELLY)


## Mars's rock between world heights y0 and y1 across the whole buffer, layer by layer (5 of basalt, 2 of layered rock:
## MarsTerrain.rock_block), in a few fills instead of a few per column (the bench: 1.62 -> 1.04 ms per surface chunk).
func _fill_mars_layers(buf: VoxelBuffer, origin: Vector3i, y0: int, y1: int) -> void:
	var size := buf.get_size()
	var y := y0
	while y < y1:
		var k := posmod(y, 7)
		var seg := mini(y + (7 - k if k >= 5 else 5 - k), y1)
		buf.fill_area(BlockIds.MARS_SEDIMENT if k >= 5 else BlockIds.BASALT, Vector3i(0, y - origin.y, 0),
			Vector3i(size.x, seg - origin.y, size.z), CH)
		y = seg


## A Mars column over ground g of region `kind` (MarsTerrain.block's rule): bedrock, deep basalt under y 0, the rock
## (the volcano's basalt, elsewhere basalt with pale layers: 2 in every 7) from `rock_from` up (the buffer's layers
## below it are filled already), the region's own layers, the top block (the landing pad on the pad).
func _write_mars_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.DEEP_BASALT)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.DEEP_BASALT)
	var rock_top := g - 1 - MarsTerrain.sub_depth(kind, g)
	if rock_top > rock_from and top > 0:
		if MarsTerrain.is_volcanic(kind):
			_fill_y(buf, origin, x, z, rock_from, rock_top, BlockIds.BASALT)
		else:
			var y := rock_from
			var end := mini(rock_top, top)
			while y < end:   # layer by layer: 5 of basalt, 2 of layered rock
				var k := posmod(y, 7)
				var seg := mini(y + (7 - k if k >= 5 else 5 - k), end)
				_fill_y(buf, origin, x, z, y, seg, BlockIds.MARS_SEDIMENT if k >= 5 else BlockIds.BASALT)
				y = seg
	var from := maxi(maxi(rock_top, 0), origin.y)
	if MarsTerrain.is_cap(kind):   # a cap's ice in runs between its dust layers (every 5 blocks, under the top two)
		var y := from
		var end := mini(g - 1, top)
		while y < end:
			if posmod(y, 5) == 0 and y < g - 2:
				buf.set_voxel(BlockIds.MARS_DUST, x, y - origin.y, z, CH)
				y += 1
				continue
			var next := y + 5 - posmod(y, 5)
			var seg := end if next >= g - 2 else mini(next, end)
			_fill_y(buf, origin, x, z, y, seg, BlockIds.POLAR_ICE)
			y = seg
	else:
		for wy in range(from, mini(g - 1, top)):
			buf.set_voxel(MarsTerrain.sub_block(kind, wy, g), x, wy - origin.y, z, CH)
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else MarsTerrain.top_block(kind, g), x, ty - origin.y, z, CH)


## Europa's deep ice between world heights y0 and y1 across the whole buffer, band by band (EuropaTerrain.rock_block:
## blue deep ice with a white band every RING_EVERY blocks), in a few fills instead of a few per column.
func _fill_europa_layers(buf: VoxelBuffer, origin: Vector3i, y0: int, y1: int) -> void:
	var size := buf.get_size()
	var every := EuropaTerrain.RING_EVERY
	var y := y0
	while y < y1:
		var k := posmod(y, every)
		var seg := mini(y + (1 if k == 0 else every - k), y1)
		buf.fill_area(BlockIds.EUROPA_ICE if k == 0 else BlockIds.DEEP_ICE, Vector3i(0, y - origin.y, 0),
			Vector3i(size.x, seg - origin.y, size.z), CH)
		y = seg


## A Europa column whose ice top is g, of region `kind` (EuropaTerrain.block's rule): bedrock, the seafloor rock under
## y 0, the layered deep ice from `rock_from` up (the buffer's layers below it are filled already), the white layers
## under the top, the top block (the landing pad on the pad). The ocean well is cut afterwards (_carve_europa_well).
func _write_europa_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.EUROPA_ROCK)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.EUROPA_ROCK)
	var rock_top := g - 1 - EuropaTerrain.SUB_DEPTH
	if rock_top > rock_from and top > 0:
		var every := EuropaTerrain.RING_EVERY
		var y := rock_from
		var end := mini(rock_top, top)
		while y < end:   # band by band: a white band, then deep ice
			var k := posmod(y, every)
			var seg := mini(y + (1 if k == 0 else every - k), end)
			_fill_y(buf, origin, x, z, y, seg, BlockIds.EUROPA_ICE if k == 0 else BlockIds.DEEP_ICE)
			y = seg
	for wy in range(maxi(maxi(rock_top, 0), origin.y), mini(g - 1, top)):
		buf.set_voxel(EuropaTerrain.sub_block(kind, wy, g), x, wy - origin.y, z, CH)
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else EuropaTerrain.top_block(kind), x, ty - origin.y, z, CH)


## Io's rock between world heights y0 and y1 across the whole buffer, layer by layer (IoTerrain.rock_block: Io's rock
## with a layer of black lava every LAYER_EVERY blocks), in a few fills instead of a few per column.
func _fill_io_layers(buf: VoxelBuffer, origin: Vector3i, y0: int, y1: int) -> void:
	var size := buf.get_size()
	var every := IoTerrain.LAYER_EVERY
	var y := y0
	while y < y1:
		var k := posmod(y, every)
		var seg := mini(y + (1 if k == 0 else every - k), y1)
		buf.fill_area(BlockIds.BLACK_LAVA if k == 0 else BlockIds.IO_ROCK, Vector3i(0, y - origin.y, 0),
			Vector3i(size.x, seg - origin.y, size.z), CH)
		y = seg


## An Io column over ground g of region `kind` (IoTerrain.block's rule): bedrock, Io's rock under y 0, the layered rock
## from `rock_from` up (the buffer's layers below it are filled already), the region's own layers (sulphur, hot lava
## under a lake's crust, black lava), the top block (the landing pad on the pad).
func _write_io_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.IO_ROCK)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.IO_ROCK)
	var rock_top := g - 1 - IoTerrain.sub_depth(kind)
	if rock_top > rock_from and top > 0:
		var every := IoTerrain.LAYER_EVERY
		var y := rock_from
		var end := mini(rock_top, top)
		while y < end:   # layer by layer: a layer of black lava, then Io's rock
			var k := posmod(y, every)
			var seg := mini(y + (1 if k == 0 else every - k), end)
			_fill_y(buf, origin, x, z, y, seg, BlockIds.BLACK_LAVA if k == 0 else BlockIds.IO_ROCK)
			y = seg
	var from := maxi(maxi(rock_top, 0), origin.y)
	if from < mini(g - 1, top):
		_fill_y(buf, origin, x, z, from, mini(g - 1, top), IoTerrain.sub_block(kind))
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else IoTerrain.top_block(kind), x, ty - origin.y, z, CH)


## A Titan column over ground g of region `kind` (TitanTerrain.block's rule): bedrock, icy rock under y 0 and from
## `rock_from` up (the buffer's rock below it is filled already), the region's own layers (soil, dune grains), the top
## block (the landing pad on the pad), and liquid methane (WATER) over a lake's or the sea's bed up to its top.
func _write_titan_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.ICY_ROCK)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.ICY_ROCK)
	var rock_top := g - 1 - TitanTerrain.sub_depth(kind)
	if rock_top > rock_from and top > 0:
		_fill_y(buf, origin, x, z, rock_from, rock_top, BlockIds.ICY_ROCK)
	var from := maxi(maxi(rock_top, 0), origin.y)
	if from < mini(g - 1, top):
		_fill_y(buf, origin, x, z, from, mini(g - 1, top), TitanTerrain.sub_block(kind))
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else TitanTerrain.top_block(kind), x, ty - origin.y, z, CH)
	if g < TitanTerrain.LIQUID_TOP:
		_fill_y(buf, origin, x, z, g, TitanTerrain.LIQUID_TOP, BlockIds.WATER)


## A Mercury column over ground g of region `kind` (MercuryTerrain.block's rule): bedrock, grey rock under y 0 and from
## `rock_from` up (the buffer's rock below it is filled already), the region's own layers (dust, or ice under a polar
## crater's ice), the top block (the landing pad on the pad).
func _write_mercury_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.MERCURY_ROCK)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.MERCURY_ROCK)
	var rock_top := g - 1 - MercuryTerrain.sub_depth(kind)
	if rock_top > rock_from and top > 0:
		_fill_y(buf, origin, x, z, rock_from, rock_top, BlockIds.MERCURY_ROCK)
	var from := maxi(maxi(rock_top, 0), origin.y)
	if from < mini(g - 1, top):
		_fill_y(buf, origin, x, z, from, mini(g - 1, top), MercuryTerrain.sub_block(kind))
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else MercuryTerrain.top_block(kind), x, ty - origin.y,
			z, CH)


## A Pluto column over ground g of region `kind` (PlutoTerrain.block's rule): bedrock, water ice under y 0 and from
## `rock_from` up (the buffer's water ice below it is filled already), the region's own layers in runs (the plain's
## nitrogen ice, a floating hill's water ice then nitrogen ice under it, tholin dust over red ice, frost, snow), the top
## block (the landing pad on the pad).
func _write_pluto_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.WATER_ICE)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.WATER_ICE)
	var rock_top := g - 1 - PlutoTerrain.sub_depth(kind, g)
	if rock_top > rock_from and top > 0:
		_fill_y(buf, origin, x, z, rock_from, rock_top, BlockIds.WATER_ICE)
	var y := maxi(maxi(rock_top, 0), origin.y)
	var end := mini(g - 1, top)
	while y < end:   # the layers under the top, a run of one block at a time
		var id := PlutoTerrain.sub_block(kind, y, g)
		var run := y + 1
		while run < end and PlutoTerrain.sub_block(kind, run, g) == id:
			run += 1
		_fill_y(buf, origin, x, z, y, run, id)
		y = run
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else PlutoTerrain.top_block(kind), x, ty - origin.y, z, CH)


## A Triton column over ground g of region `kind` (TritonTerrain.block's rule): bedrock, water ice (the icy mantle) under y 0
## and from `rock_from` up (the buffer's water ice below it is filled already), the region's own layers in runs (frost
## over a crust of nitrogen ice, pink ice over nitrogen ice, the cantaloupe terrain's ice, the lake's ice lava), the top
## block (the landing pad on the pad).
func _write_triton_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.WATER_ICE)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.WATER_ICE)
	var rock_top := g - 1 - TritonTerrain.sub_depth(kind)
	if rock_top > rock_from and top > 0:
		_fill_y(buf, origin, x, z, rock_from, rock_top, BlockIds.WATER_ICE)
	var y := maxi(maxi(rock_top, 0), origin.y)
	var end := mini(g - 1, top)
	while y < end:   # the layers under the top, a run of one block at a time
		var id := TritonTerrain.sub_block(kind, y, g)
		var run := y + 1
		while run < end and TritonTerrain.sub_block(kind, run, g) == id:
			run += 1
		_fill_y(buf, origin, x, z, y, run, id)
		y = run
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else TritonTerrain.top_block(kind), x, ty - origin.y, z, CH)


## A Ganymede column over ground g of region `kind` (GanymedeTerrain.block's rule): bedrock, water ice (the icy crust)
## under y 0 and from `rock_from` up (the buffer's water ice below it is filled already), the region's own layers in runs
## (bright ice, old ice, the crater's fresh ice), the top block (the landing pad on the pad).
func _write_ganymede_column(buf: VoxelBuffer, origin: Vector3i, x: int, z: int, g: int, kind: int, shape: SpaceShape,
		rock_from: int) -> void:
	var wx := origin.x + x
	var wz := origin.z + z
	var top := origin.y + buf.get_size().y
	if origin.y <= MeadowsShape.WORLD_BOTTOM + 3:
		var bed := shape.bedrock_top(wx, wz)
		_fill_y(buf, origin, x, z, -0x7fffffff, bed + 1, BlockIds.BEDROCK)
		_fill_y(buf, origin, x, z, bed + 1, 0, BlockIds.WATER_ICE)
	elif origin.y < 0:
		_fill_y(buf, origin, x, z, origin.y, 0, BlockIds.WATER_ICE)
	var rock_top := g - 1 - GanymedeTerrain.SUB_DEPTH
	if rock_top > rock_from and top > 0:
		_fill_y(buf, origin, x, z, rock_from, rock_top, BlockIds.WATER_ICE)
	var y := maxi(maxi(rock_top, 0), origin.y)
	var end := mini(g - 1, top)
	while y < end:   # the layers under the top, a run of one block at a time
		var id := GanymedeTerrain.sub_block(kind, y, g)
		var run := y + 1
		while run < end and GanymedeTerrain.sub_block(kind, run, g) == id:
			run += 1
		_fill_y(buf, origin, x, z, y, run, id)
		y = run
	var ty := g - 1
	if ty >= maxi(origin.y, 0) and ty < top:
		buf.set_voxel(BlockIds.LANDING_PAD if shape.pad_at(wx, wz) else GanymedeTerrain.top_block(kind), x, ty - origin.y, z,
			CH)


## Europa's ocean well cut into this buffer where it reaches it (EuropaTerrain.well_block: the water, the open middle,
## the ramp, the glowing rings); nothing elsewhere. After the ores (the water takes their cells), before the features.
func _carve_europa_well(buf: VoxelBuffer, origin: Vector3i, shape: SpaceShape) -> void:
	var e := shape.europa
	var box := e.well_box()
	var size := buf.get_size()
	var lo := (box[0] as Vector3i).max(origin)
	var hi := (box[1] as Vector3i).min(origin + size)
	if lo.x >= hi.x or lo.y >= hi.y or lo.z >= hi.z:
		return
	var top := e.well_top()
	for z in range(lo.z, hi.z):
		for x in range(lo.x, hi.x):
			if not e.in_well(x, z):
				continue
			for y in range(lo.y, hi.y):
				var id := e.well_block(x, y, z, top)
				if id >= 0:
					buf.set_voxel(id, x - origin.x, y - origin.y, z - origin.z, CH)


## Ore veins (OreRules, as in Green Meadows) that replace only the planet's rock (none where it has none: Venus).
func _place_space_ores(buf: VoxelBuffer, origin: Vector3i) -> void:
	if _rock.is_empty():
		return
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
						if _rock.has(buf.get_voxel(l.x, l.y, l.z, CH)):
							buf.set_voxel(vein.ore, l.x, l.y, l.z, CH)


## Every feature (the planet's "trees") standing within reach of this buffer (`trees`: [tx, tz, …] in (z, x) order),
## into its air only.
func _place_features(buf: VoxelBuffer, origin: Vector3i, size: Vector3i, shape: SpaceShape, trees: PackedInt32Array) -> void:
	var r := shape.feature_reach()
	for i in range(0, trees.size(), 2):
		var tx := trees[i]
		var tz := trees[i + 1]
		var base := shape.height_at(tx, tz)
		var y0 := maxi(base - 1, origin.y)
		var y1 := mini(base + shape.feature_top(tx, tz) + 1, origin.y + size.y)
		for y in range(y0, y1):
			for dz in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var p := Vector3i(tx + dx, y, tz + dz)
					var l := p - origin
					if l.x < 0 or l.z < 0 or l.x >= size.x or l.z >= size.z:
						continue
					var id := shape.feature_block(tx, tz, p)
					if id >= 0 and buf.get_voxel(l.x, l.y, l.z, CH) == BlockIds.AIR:
						buf.set_voxel(id, l.x, l.y, l.z, CH)


## The slow one-block reference of everything above.
func reference_block(x: int, y: int, z: int) -> int:
	var secret := _secrets.block_at(Vector3i(x, y, z)) if secrets_enabled else -1
	if secret >= 0:
		return secret
	var shape := _shape as SpaceShape
	if colony_enabled and shape.colony != null:   # spec §21c
		var built := shape.colony.block_at(Vector3i(x, y, z))
		if built >= 0:
			return built
	if colony_enabled and shape.venus != null:   # Venus's city's built parts
		var built := shape.venus.built_at(Vector3i(x, y, z))
		if built >= 0:
			return built
	if colony_enabled and shape.rings != null:   # the rings' built parts (the station, the scope, the beacons)
		var built := shape.rings.built_at(Vector3i(x, y, z))
		if built >= 0:
			return built
	if colony_enabled and shape.pluto != null:   # Pluto's Charon Lookout
		var built := shape.pluto.built_at(Vector3i(x, y, z))
		if built >= 0:
			return built
	if colony_enabled and shape.triton != null:   # Triton's Neptune Lookout
		var built := shape.triton.built_at(Vector3i(x, y, z))
		if built >= 0:
			return built
	if colony_enabled and shape.ganymede != null:   # Ganymede's Jupiter Lookout, Aurora Watch and ocean drill
		var built := shape.ganymede.built_at(Vector3i(x, y, z))
		if built >= 0:
			return built
	var id := shape.block_at(x, y, z)
	if id == BlockIds.AIR:
		var f := shape.feature_at(x, y, z)
		return deposit_over(x, y, z, f if f >= 0 else BlockIds.AIR)   # spec §26.5: a meteorite's lump in the air
	if _rock.has(id):
		var ore := _ores.ore_at(Vector3i(x, y, z))
		if ore >= 0:
			return deposit_over(x, y, z, ore)
	return deposit_over(x, y, z, id)   # spec §26.5: the Moon's and Mars's deposits over the planet's own ground
