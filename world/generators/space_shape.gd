class_name SpaceShape
extends MeadowsShape
## The space worlds' terrain as pure rules (owner feedback #55, spec §21.2): one class for every planet, chosen by
## `planet`. Every rule is a function of (x, z) (and y for blocks) and the seed, so chunks meet without seams; read-only
## after construction, so the generator's threads share it. Every column is dry land: no seas, no rivers (every
## spawner's "dry land" holds; fish never come). The landing pad: a flat disc of LANDING_PAD at the spawn, the ground
## flattened round it and blended back into the planet's own by BLEND_RADIUS; nothing grows there.
## - The Moon: silvery dust (2 deep) over moon rock, deep moon rock under y 0; gentle swells and round craters (one per
##   CRATER_CELL cell at most, a bowl and a raised rim); moon crystals (1-4 tall, glowing) mostly in the craters.
## - Planet Boing: rolling lime moss hills over teal soil and purple rock; the dips hold flat pools of pink jelly
##   (JELLY_LEVEL); spring mushrooms (a white stalk, a wide orange cap). Moss, jelly and caps are bouncy (CandyRules).
## - Rainbow Planet: terraced hills (flat steps, one block each) of rock in six rainbow stripes (STRIPE_HEIGHT each, by
##   height), pastel prism grass on top; clear prism crystal spires.
## - Mars (cosmos, spec §21b.2): the regions are MarsTerrain's (`mars`): red dust plains with craters (bigger cells,
##   fewer) and dry river valleys, the giant shield volcano, the canyon, the polar caps; basalt boulders on the ground
##   and glowing gypsum crystals where water was (the river beds, the canyon).
## - Europa (cosmos, spec §21b.2): the regions are EuropaTerrain's (`europa`): a smooth white crust of ice, long reddish
##   cracks with stained ridges, the ice cliffs, water plumes in mounds of salt, the ocean well down through the ice to
##   the water (a WELL column's ground is its seafloor or its ramp: the well's blocks are EuropaTerrain.well_block);
##   ice blades (penitentes) on the plains and salt crystals in the cracks.
## - Io (cosmos, spec §21b.2): the regions are IoTerrain's (`io`): yellow sulphur plains with orange patches and white
##   frost, volcanoes (black lava cones with a vent, red sulphur rings), small lava lakes, the big lava lake (a crust,
##   a narrow moat of hot lava fenced by a rim, causeways), the mountain; sulphur crystals and lava boulders on the plains.
## - Titan (cosmos, spec §21b.2): the regions are TitanTerrain's (`titan`): orange-brown soil plains with ice pebbles, the
##   methane sea to the north and small methane lakes (a column whose ground lies under TitanTerrain.LIQUID_TOP is filled
##   with liquid up to it: top_of; is_river says so, so no spawner takes it for dry land), dunes of dark grains to the
##   south, the icy mountains; ice boulders on the plains, shore crystals on the beaches.
## - Mercury (cosmos, spec §21b.2): the regions are MercuryTerrain's (`mercury`): grey dust plains with darker patches,
##   craters everywhere (small bowls, young ones with bright rays; big ones with terraced walls and a central peak), long
##   cliffs (lobate scarps), ice on the floors of the big craters near the poles (the ice crater far to the north); rock
##   boulders on the plains, ice crystals on the ice, and the explorers' thermometer a few steps from the landing pad
##   (thermometer_column: a sight).
## - Venus's cloud city (cosmos, spec §21b.2): VenusTerrain's (`venus`): round platforms joined by bridges, all at one
##   deck height, over the yellow clouds far below (a cloud or a bridge column is no dry land for a spawner: is_river);
##   lamp posts on rims and bridges, flowers and little trees in the gardens (features), the city's built parts written by
##   the generator (VenusTerrain.write), its sights (the cloud scope, the dock, the garden, the homes, the west lookout).
## - Saturn's rings (cosmos, spec §21b.2): RingsTerrain's (`rings`): chunks of ice floating in bands with gaps over open
##   space (no bedrock, nothing under them: a VOID column's height is the sea level, "no ground here", as in the Dragon
##   Realm), flat-topped big chunks (the only dry land for a spawner: is_river on the rest), lumps, Pan in the Encke Gap,
##   the F ring; the built parts (the Ring Station, the Saturn scope, the beacons) written by the generator
##   (RingsTerrain.write), its sights (the scope, the station, the Cassini Division, the C ring, the F ring, Pan).
## - Pluto (cosmos, spec §21b.2): PlutoTerrain's (`pluto`): the heart a walk east of the pad (its west half a flat plain of
##   nitrogen ice in cells, floating hills of water ice on the cells' edges, its east half bright methane snow), the ice
##   mountains along the plain's south-west shore, the red-brown lands to the west (snowy hilltops, craters), peach-tan
##   uplands; water-ice boulders and frost crystals (features); the Charon Lookout a few steps west of the pad
##   (PlutoTerrain.place_lookout, its boxes written by the generator), its sights (the lookout, the heart, the hills, the
##   mountains, the red-brown lands, the bright side).
## - Triton (cosmos, spec §21b.2): TritonTerrain's (`triton`): the bright band of fresh nitrogen frost round the pad, the
##   pink south polar cap to the south with its geysers (vents in rings of dark dust, streaks of dust drawn north-east by
##   the wind: vents_near, SpaceGeysers), the cantaloupe terrain to the north-west (dimples and ridges), a frozen lake of
##   ice lava in a walled plain to the north-east, one of its few craters to the east; water-ice boulders and glowing
##   nitrogen crystals (features); the Neptune Lookout a few steps north-east of the pad (TritonTerrain.place_lookout, its
##   boxes written by the generator), its sights (the lookout, a geyser, a streak, the cap, the cantaloupe terrain, the
##   lake, the crater).
## - Ganymede (cosmos, spec §21b.2): GanymedeTerrain's (`ganymede`): a smooth plain of bright ice round the pad, the bright
##   grooved terrain round it (lanes of long parallel ridges and grooves), the old dark terrain to the west (furrows, old
##   craters), a young bright ray crater with a pit to the east, frost at both poles; water-ice and old-ice boulders, aurora
##   crystals on the frost and in the crater's pit (features); its built parts (GanymedeTerrain.place_parts, their boxes
##   written by the generator: the Jupiter Lookout by the pad, the Aurora Watch on the northern frost, the ocean drill),
##   its sights (the lookout, the grooves, the dark terrain, the crater, the frost, the watch, the drill).
## - The colonies under domes (spec §21c; the Moon and Mars): `colony` (ColonyLayout) a short walk from the landing pad;
##   the ground is flat at the pad's height under it and blends back round it; no feature grows there, Mars's ground there
##   is its plains', and its parts are sights (sight_at: each part; sights(): the colony at its airlock's door).
## ground_at is the solid ground; height_at the top (a pool's jelly on Boing), both after the landing pad.
## Patterns (godot-prompter procedural-generation): seeded 2D noise for the swells, hash-drawn per-cell craters and
## per-column features, quantised noise for terraces; rejected 3D noise (a sample per voxel) and caves (cost; a
## friendly place to explore on top).

const MOON := &"moon"
const BOING := &"boing"
const RAINBOW := &"rainbow"
const MARS := &"mars"
const EUROPA := &"europa"
const IO := &"io"
const TITAN := &"titan"
const MERCURY := &"mercury"
const VENUS := &"venus"
const RINGS := &"rings"
const PLUTO := &"pluto"
const TRITON := &"triton"
const GANYMEDE := &"ganymede"
const PLANETS: Array[StringName] = [MOON, BOING, RAINBOW, MARS, EUROPA, IO, TITAN, MERCURY, VENUS, RINGS, PLUTO, TRITON,
	GANYMEDE]

const PAD_RADIUS := 3
const FLAT_RADIUS := 8
const BLEND_RADIUS := 16
const MIN_GROUND := MeadowsShape.SEA_LEVEL + 6
const MAX_GROUND := 110
const SPAWN_RINGS := 60
const SPAWN_STEP := 16

# The Moon
const MOON_BASE := 44.0
const DUST_DEPTH := 2
const CRATER_CELL := 40
const CRATER_CHANCE := 55        # of 100 cells
const CRATER_MIN := 6
const CRATER_MAX := 15
const CRATER_DEPTH := 0.45       # × the radius
const RIM_OUT := 1.35            # the rim runs out to this × the radius
const CRYSTAL_IN_CRATER := 60    # per mille of crater columns
const CRYSTAL_ELSEWHERE := 3     # per mille of other columns
# Planet Boing
const BOING_BASE := 41.0
const JELLY_LEVEL := 37          # the pools' flat top (the first empty y above them)
const SOIL_DEPTH := 4            # moss and soil down to here
const SPRING_PER_MILLE := 12
# Rainbow Planet
const RAINBOW_BASE := 44.0
const TERRACE := 4               # a step every TERRACE of the hills' height: half flat, half one-block steps
const STRIPE_HEIGHT := 2
const SPIRE_PER_MILLE := 8
# Mars (its regions: MarsTerrain)
const MARS_CRATER_CELL := 48
const MARS_CRATER_CHANCE := 30   # of 100 cells
const MARS_CRATER_MIN := 5
const MARS_CRATER_MAX := 13
const BOULDER_PER_MILLE := 6     # basalt boulders wherever there is ground
const GYPSUM_PER_MILLE := 26     # ... and from here up to this, gypsum crystals in the river beds and the canyon
# Europa (its regions: EuropaTerrain)
const SALT_PER_MILLE := 18       # salt crystals in the cracks ...
const BLADE_PER_MILLE := 70      # ... and from here up to this, ice blades in their fields on the plains
# Io (its regions: IoTerrain)
const LAVA_BOULDER_PER_MILLE := 2    # black lava boulders on the plains and the red rings ...
const SULPHUR_CRYSTAL_PER_MILLE := 8    # ... and from here up to this, sulphur crystals on the plains
# Titan (its regions: TitanTerrain)
const ICE_BOULDER_PER_MILLE := 2        # ice boulders on the plains ...
const SHORE_CRYSTAL_PER_MILLE := 40     # ... and from here up to this, shore crystals on a beach by the methane
# Mercury (its regions: MercuryTerrain)
const ROCK_BOULDER_PER_MILLE := 3       # rock boulders on the plains ...
const ICE_CRYSTAL_PER_MILLE := 40       # ... and from here up to this, ice crystals on a polar crater's ice
const THERMOMETER_DISTANCE := 11        # the explorers' thermometer: this far from the pad's middle ...
const THERMOMETER_H := 7                # ... this tall (a plinth, the bulb, the tube)
const THERMOMETER_REACH := 2            # standing this close to it (either way) is its sight
# Pluto (its regions: PlutoTerrain)
const WATER_BOULDER_PER_MILLE := 2      # water-ice boulders on the uplands and the red-brown lands ...
const FROST_CRYSTAL_PER_MILLE := 8      # ... and from here up to this, frost crystals on the heart's bright side
const LOOKOUT_DISTANCE := 12            # the Charon Lookout: this far west of the pad's middle (towards Charon)
const LOOKOUT_REACH := 3                # standing this close to its middle (either way) is its sight
# Triton (its regions: TritonTerrain)
const SNOW_BOULDER_PER_MILLE := 2       # water-ice boulders on the band and the cantaloupe terrain ...
const N2_CRYSTAL_PER_MILLE := 6         # ... and from here up to this, nitrogen crystals on the cap's pink ice
const NEPTUNE_LOOKOUT := 9              # the Neptune Lookout: this far east and north of the pad's middle (towards Neptune)
# Ganymede (its regions: GanymedeTerrain)
const ICE_ROCK_PER_MILLE := 2           # water-ice boulders on the bright ground, old-ice ones on the dark terrain ...
const AURORA_CRYSTAL_PER_MILLE := 7     # ... and from here up to this, aurora crystals on the poles' frost ...
const PIT_CRYSTAL_PER_MILLE := 120      # ... and in the ray crater's pit

var planet: StringName = MOON
## Mars's regions (null on the other planets).
var mars: MarsTerrain
## Europa's regions (null on the other planets).
var europa: EuropaTerrain
## Io's regions (null on the other planets).
var io: IoTerrain
## Titan's regions (null on the other planets).
var titan: TitanTerrain
## Mercury's regions (null on the other planets).
var mercury: MercuryTerrain
## Venus's cloud city (null on the other planets).
var venus: VenusTerrain
## Saturn's rings (null on the other planets).
var rings: RingsTerrain
## Pluto's regions (null on the other planets).
var pluto: PlutoTerrain
## Triton's regions (null on the other planets).
var triton: TritonTerrain
## Ganymede's regions (null on the other planets).
var ganymede: GanymedeTerrain
## Spec §21c: the colony under domes (the Moon's and Mars's; null on the other planets).
var colony: ColonyLayout
var _swell := FastNoiseLite.new()
var _fine := FastNoiseLite.new()
var _peaks := FastNoiseLite.new()
var _spawn := Vector2i.ZERO
var _spawn_h := 0
var _thermometer := Vector2i(0x7fffffff, 0x7fffffff)


func _init(world_seed: int, which: StringName = MOON) -> void:
	super(world_seed)
	planet = which if PLANETS.has(which) else MOON
	_swell.seed = world_seed + 55
	_swell.frequency = {MOON: 0.005, BOING: 0.013, RAINBOW: 0.008, MARS: 0.006, EUROPA: 0.003, IO: 0.004, TITAN: 0.004,
		MERCURY: 0.004, VENUS: 0.004, RINGS: 0.004, PLUTO: 0.004, TRITON: 0.004, GANYMEDE: 0.004}[planet]
	_swell.fractal_octaves = 2 if planet == BOING else 3
	_fine.seed = world_seed + 56
	_fine.frequency = 0.05
	_peaks.seed = world_seed + 57
	_peaks.frequency = 0.004
	if planet == MARS:
		mars = MarsTerrain.new(world_seed)
	elif planet == EUROPA:
		europa = EuropaTerrain.new(world_seed)
	elif planet == IO:
		io = IoTerrain.new(world_seed)
	elif planet == TITAN:
		titan = TitanTerrain.new(world_seed)
	elif planet == MERCURY:
		mercury = MercuryTerrain.new(world_seed)
	elif planet == VENUS:
		venus = VenusTerrain.new(world_seed)
	elif planet == RINGS:
		rings = RingsTerrain.new(world_seed)
	elif planet == PLUTO:
		pluto = PlutoTerrain.new(world_seed)
	elif planet == TRITON:
		triton = TritonTerrain.new(world_seed)
	elif planet == GANYMEDE:
		ganymede = GanymedeTerrain.new(world_seed)
	_spawn = _find_spawn()
	_spawn_h = _raw_height(_spawn.x, _spawn.y)
	if planet == PLUTO:   # the Charon Lookout by the pad, built before any generator thread starts
		pluto.place_lookout(_spawn + Vector2i(-LOOKOUT_DISTANCE, 0), ground_at)
	if planet == TRITON:   # the Neptune Lookout by the pad, built before any generator thread starts
		triton.place_lookout(_spawn + Vector2i(NEPTUNE_LOOKOUT, -NEPTUNE_LOOKOUT), ground_at)
	if planet == GANYMEDE:   # the Jupiter Lookout, the Aurora Watch and the ocean drill, before any generator thread starts
		ganymede.place_parts(_spawn, ground_at)
	colony = ColonyLayout.place(planet, world_seed, _spawn, _spawn_h, _colony_calm)   # spec §21c (after the pad)
	if planet == MERCURY:
		var a := float(absi(_hash(world_seed + 23, 5)) % 360) / 360.0 * TAU
		_thermometer = _spawn + Vector2i(roundi(cos(a) * THERMOMETER_DISTANCE), roundi(sin(a) * THERMOMETER_DISTANCE))


## The solid ground at (x, z) (the first empty y above it; under a Boing pool's jelly).
func ground_at(x: int, z: int) -> int:
	if venus != null:   # a deck or a bridge (all at one height: nothing to blend), else the clouds' top far below
		return venus.top_at(x, z)
	if rings != null:   # a chunk's top (the landing chunk is flat round the pad), else "no ground here"
		return rings.top_at(x, z)
	var d2 := (x - _spawn.x) * (x - _spawn.x) + (z - _spawn.y) * (z - _spawn.y)
	if d2 > BLEND_RADIUS * BLEND_RADIUS:
		return _raw_height(x, z)
	if d2 <= FLAT_RADIUS * FLAT_RADIUS:
		return _spawn_h
	return _blend(d2, _raw_height(x, z))


## Height of the ground at (x, z): the first empty y above the top solid block (a pool's jelly counts).
func height_at(x: int, z: int) -> int:
	return top_of(ground_at(x, z))


## The top over solid ground g: Planet Boing's dips fill with jelly up to JELLY_LEVEL; Titan's lakes and sea with liquid
## methane up to TitanTerrain.LIQUID_TOP.
func top_of(g: int) -> int:
	if planet == BOING:
		return maxi(g, JELLY_LEVEL)
	if planet == TITAN:
		return maxi(g, TitanTerrain.LIQUID_TOP)
	return g


## The solid ground of sx × sz columns from (x0, z0) (index x + z * sx), exactly ground_at's, fast: the craters of the
## block are looked up once (the generator's path; ground_at is its reference).
func grounds(x0: int, z0: int, sx: int, sz: int) -> PackedInt32Array:
	if planet == MARS:
		return mars_columns(x0, z0, sx, sz)[0]
	if planet == EUROPA:   # the well's columns: their real ground (europa_columns has the ice's top there)
		var cols := europa_columns(x0, z0, sx, sz)
		var g: PackedInt32Array = cols[0]
		var k: PackedByteArray = cols[1]
		for i in g.size():
			if k[i] == EuropaTerrain.WELL:
				g[i] = europa.well_ground(x0 + i % sx, z0 + i / sx, g[i])
		return g
	if planet == IO:
		return io_columns(x0, z0, sx, sz)[0]
	if planet == TITAN:
		return titan_columns(x0, z0, sx, sz)[0]
	if planet == MERCURY:
		return mercury_columns(x0, z0, sx, sz)[0]
	if planet == VENUS:
		return venus.columns(x0, z0, sx, sz)[0]
	if planet == RINGS:
		return rings.columns(x0, z0, sx, sz)[0]
	if planet == PLUTO:
		return pluto_columns(x0, z0, sx, sz)[0]
	if planet == TRITON:
		return triton_columns(x0, z0, sx, sz)[0]
	if planet == GANYMEDE:
		return ganymede_columns(x0, z0, sx, sz)[0]
	var out := PackedInt32Array()
	out.resize(sx * sz)
	var craters := _craters_near(x0, z0, x0 + sx - 1, z0 + sz - 1) if planet == MOON else PackedInt32Array()
	for z in sz:
		for x in sx:
			var wx := x0 + x
			var wz := z0 + z
			var d2 := (wx - _spawn.x) * (wx - _spawn.x) + (wz - _spawn.y) * (wz - _spawn.y)
			var h := _spawn_h
			if d2 > BLEND_RADIUS * BLEND_RADIUS:
				h = _raw_from(wx, wz, craters)
			elif d2 > FLAT_RADIUS * FLAT_RADIUS:
				h = _blend(d2, _raw_from(wx, wz, craters))
			out[x + z * sx] = h
	return out


## Mars: [grounds (as grounds()), kinds (PackedByteArray, MarsTerrain's)] of sx × sz columns from (x0, z0), in one
## pass (the generator's path; ground_at and mars_kind are its reference).
func mars_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var out := PackedInt32Array()
	out.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	var craters := _craters_near(x0, z0, x0 + sx - 1, z0 + sz - 1)
	for z in sz:
		for x in sx:
			var wx := x0 + x
			var wz := z0 + z
			var c := mars.column(wx, wz, _crater_sum(wx, wz, craters))
			var h := c >> 4
			var kind := c & 15
			if colony != null:   # spec §21c: flat under the colony, its plains' ground
				h = colony.flatten(wx, wz, h)
				if colony.covers(wx, wz):
					kind = MarsTerrain.PLAINS
			var d2 := (wx - _spawn.x) * (wx - _spawn.x) + (wz - _spawn.y) * (wz - _spawn.y)
			if d2 <= FLAT_RADIUS * FLAT_RADIUS:
				h = _spawn_h
			elif d2 <= BLEND_RADIUS * BLEND_RADIUS:
				h = _blend(d2, h)
			out[x + z * sx] = h
			kinds[x + z * sx] = kind
	return [out, kinds]


## Europa: [tops (the ice's top, after the landing pad: a WELL column's is its rim's), kinds (PackedByteArray,
## EuropaTerrain's)] of sx × sz columns from (x0, z0), in one pass (the generator's path; the reference is
## _europa_block_at).
func europa_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var out := PackedInt32Array()
	out.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	for z in sz:
		for x in sx:
			var c := europa.column(x0 + x, z0 + z)
			out[x + z * sx] = _europa_top(x0 + x, z0 + z, c >> 4)
			kinds[x + z * sx] = c & 15
	return [out, kinds]


## Io: [grounds (after the landing pad), kinds (PackedByteArray, IoTerrain's)] of sx × sz columns from (x0, z0), in one
## pass (the generator's path; ground_at and io_kind are its reference).
func io_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var out := PackedInt32Array()
	out.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	for z in sz:
		for x in sx:
			var c := io.column(x0 + x, z0 + z)
			out[x + z * sx] = _pad_blend(x0 + x, z0 + z, c >> 4)
			kinds[x + z * sx] = c & 15
	return [out, kinds]


## Io: the region of the column at (x, z) (IoTerrain.PLAINS, …); -1 on the other planets.
func io_kind(x: int, z: int) -> int:
	return io.column(x, z) & 15 if io != null else -1


## Titan: [grounds (after the landing pad), kinds (PackedByteArray, TitanTerrain's)] of sx × sz columns from (x0, z0), in
## one pass (the generator's path; ground_at and titan_kind are its reference).
func titan_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var out := PackedInt32Array()
	out.resize(sx * sz)
	var kinds := PackedByteArray()
	kinds.resize(sx * sz)
	for z in sz:
		for x in sx:
			var c := titan.column(x0 + x, z0 + z)
			out[x + z * sx] = _pad_blend(x0 + x, z0 + z, c >> 4)
			kinds[x + z * sx] = c & 15
	return [out, kinds]


## Titan: the region of the column at (x, z) (TitanTerrain.PLAINS, …); -1 on the other planets.
func titan_kind(x: int, z: int) -> int:
	return titan.column(x, z) & 15 if titan != null else -1


## Mercury: [grounds (after the landing pad), kinds (PackedByteArray, MercuryTerrain's)] of sx × sz columns from (x0, z0),
## the features near them drawn once (the generator's path; ground_at and mercury_kind are its reference).
func mercury_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var cols := mercury.columns(x0, z0, sx, sz)
	var out: PackedInt32Array = cols[0]
	for i in out.size():
		out[i] = _pad_blend(x0 + i % sx, z0 + i / sx, out[i])
	return [out, cols[1]]


## Mercury: the region of the column at (x, z) (MercuryTerrain.PLAINS, …); -1 on the other planets.
func mercury_kind(x: int, z: int) -> int:
	return mercury.column(x, z) & 15 if mercury != null else -1


## Venus: [tops, kinds, bottoms, clouds] of sx × sz columns from (x0, z0) (VenusTerrain.columns: the generator's path;
## ground_at and venus_kind are its reference).
func venus_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	return venus.columns(x0, z0, sx, sz)


## Venus: the kind of the column at (x, z) (VenusTerrain.CLOUD, DECK, …); -1 on the other planets.
func venus_kind(x: int, z: int) -> int:
	return venus.kind_at(x, z) if venus != null else -1


## Saturn's rings: [tops, kinds, bottoms] of sx × sz columns from (x0, z0) (RingsTerrain.columns: the generator's path;
## ground_at and rings_kind are its reference).
func rings_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	return rings.columns(x0, z0, sx, sz)


## Saturn's rings: the kind of the column at (x, z) (RingsTerrain.VOID, ICE_FLAT, …); -1 on the other planets.
func rings_kind(x: int, z: int) -> int:
	return rings.kind_at(x, z) if rings != null else -1


## Pluto: [grounds (after the landing pad), kinds (PackedByteArray, PlutoTerrain's)] of sx × sz columns from (x0, z0), in
## one pass (the generator's path; ground_at and pluto_kind are its reference).
func pluto_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var cols := pluto.columns(x0, z0, sx, sz)
	var out: PackedInt32Array = cols[0]
	for i in out.size():
		out[i] = _pad_blend(x0 + i % sx, z0 + i / sx, out[i])
	return [out, cols[1]]


## Pluto: the region of the column at (x, z) (PlutoTerrain.UPLANDS, …); -1 on the other planets.
func pluto_kind(x: int, z: int) -> int:
	return pluto.column(x, z) & 15 if pluto != null else -1


## Triton: [grounds (after the landing pad), kinds (PackedByteArray, TritonTerrain's)] of sx × sz columns from (x0, z0),
## in one pass (the generator's path; ground_at and triton_kind are its reference).
func triton_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var cols := triton.columns(x0, z0, sx, sz)
	var out: PackedInt32Array = cols[0]
	for i in out.size():
		out[i] = _pad_blend(x0 + i % sx, z0 + i / sx, out[i])
	return [out, cols[1]]


## Triton: the region of the column at (x, z) (TritonTerrain.FROST, …); -1 on the other planets.
func triton_kind(x: int, z: int) -> int:
	return triton.column(x, z) & 15 if triton != null else -1


## Ganymede: [grounds (after the landing pad), kinds (PackedByteArray, GanymedeTerrain's)] of sx × sz columns from
## (x0, z0), in one pass (the generator's path; ground_at and ganymede_kind are its reference).
func ganymede_columns(x0: int, z0: int, sx: int, sz: int) -> Array:
	var cols := ganymede.columns(x0, z0, sx, sz)
	var out: PackedInt32Array = cols[0]
	for i in out.size():
		out[i] = _pad_blend(x0 + i % sx, z0 + i / sx, out[i])
	return [out, cols[1]]


## Ganymede: the region of the column at (x, z) (GanymedeTerrain.SMOOTH, …); -1 on the other planets.
func ganymede_kind(x: int, z: int) -> int:
	return ganymede.column(x, z) & 15 if ganymede != null else -1


## Mercury: the explorers' thermometer's column, a few steps from the landing pad (a far-off column elsewhere).
func thermometer_column() -> Vector2i:
	return _thermometer


## Pluto: (x, z) is at the Charon Lookout (its sight); Triton: at the Neptune Lookout.
func _by_lookout(x: int, z: int) -> bool:
	var lk := pluto.lookout if pluto != null else triton.lookout
	return absi(x - lk.x) <= LOOKOUT_REACH and absi(z - lk.y) <= LOOKOUT_REACH


## Mercury: (x, z) is by the thermometer (its sight).
func _by_thermometer(x: int, z: int) -> bool:
	return mercury != null and absi(x - _thermometer.x) <= THERMOMETER_REACH \
		and absi(z - _thermometer.y) <= THERMOMETER_REACH


## A column's own ground `h` after the landing pad (flat on the pad, blended round it).
func _pad_blend(x: int, z: int, h: int) -> int:
	var d2 := (x - _spawn.x) * (x - _spawn.x) + (z - _spawn.y) * (z - _spawn.y)
	if d2 <= FLAT_RADIUS * FLAT_RADIUS:
		return _spawn_h
	if d2 <= BLEND_RADIUS * BLEND_RADIUS:
		return _blend(d2, h)
	return h


## Cosmos: the vents within `radius` of (x, z) whose plumes blow (Europa's water plumes, Io's volcanoes, Triton's
## nitrogen geysers; SpaceGeysers).
func vents_near(x: int, z: int, radius: float) -> Array[Vector2i]:
	if europa != null:
		return europa.vents_near(x, z, radius)
	if io != null:
		return io.vents_near(x, z, radius)
	if triton != null:
		return triton.vents_near(x, z, radius)
	return [] as Array[Vector2i]


## Cosmos: the planet has vents whose plumes blow (SpaceGeysers).
func has_vents() -> bool:
	return europa != null or io != null or triton != null


## Europa: the region of the column at (x, z) (EuropaTerrain.PLAINS, …); -1 on the other planets.
func europa_kind(x: int, z: int) -> int:
	return europa.column(x, z) & 15 if europa != null else -1


## Europa: a column's ice top `h` after the landing pad (flat on the pad, blended round it).
func _europa_top(x: int, z: int, h: int) -> int:
	var d2 := (x - _spawn.x) * (x - _spawn.x) + (z - _spawn.y) * (z - _spawn.y)
	if d2 <= FLAT_RADIUS * FLAT_RADIUS:
		return _spawn_h
	if d2 <= BLEND_RADIUS * BLEND_RADIUS:
		return _blend(d2, h)
	return h


## Mars: the region of the column at (x, z) (MarsTerrain.PLAINS, …; under the colony its plains); -1 on the other planets.
func mars_kind(x: int, z: int) -> int:
	if mars == null:
		return -1
	if colony != null and colony.covers(x, z):
		return MarsTerrain.PLAINS
	return mars.column(x, z, crater_depth(x, z)) & 15


## Mars: the sight a child standing at (x, z) is at (MarsTerrain.sight: &"volcano", &"canyon", …), &"" for none (and
## on the other planets).
func sight_at(x: int, z: int) -> StringName:
	if _by_thermometer(x, z):
		return &"thermometer"
	if venus != null:   # the cloud scope stands by the pad: before the spawn's clearing
		return venus.sight_at(x, z)
	if rings != null:   # the Saturn scope and the station stand by the pad: before the spawn's clearing
		return rings.sight_at(x, z)
	if (pluto != null or triton != null) and _by_lookout(x, z):   # the Charon (or Neptune) Lookout stands by the pad:
		return &"lookout"                                          # before the spawn's clearing
	if ganymede != null:   # the Jupiter Lookout (by the pad), the Aurora Watch, the ocean drill
		var part := ganymede.part_sight(x, z)
		if part != &"":
			return part
	if colony != null and colony.covers(x, z):   # spec §21c: the colony's parts (none on the ground between them)
		return colony.part_at(x, z)
	if _near_spawn(x, z):
		return &""
	if europa != null:
		return europa.sight(x, z, europa.column(x, z))
	if io != null:
		return io.sight(x, z, io.column(x, z))
	if titan != null:
		return titan.sight(x, z, titan.column(x, z))
	if mercury != null:
		return mercury.sight(x, z, mercury.column(x, z))
	if pluto != null:
		return pluto.sight(x, z, pluto.column(x, z))
	if triton != null:
		return triton.sight(x, z, triton.column(x, z))
	if ganymede != null:
		return ganymede.sight(x, z, ganymede.column(x, z))
	if mars == null:
		return &""
	return mars.sight(x, z, mars.column(x, z, crater_depth(x, z)))


## Mars: the big sights MY MAP shows from the landing, {id, pos (on the ground)}: the volcano's caldera, the canyon
## south of the pad, the north cap and the south cap straight north and south of it. [] on the other planets.
func sights() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if europa != null:   # the ocean in the well, the ice cliffs' plateau, the plume nearest the pad
		var spots: Array = [[&"ocean", europa.well_centre()], [&"cliffs", europa.mesa_centre()]]
		var vent := europa.nearest_vent(_spawn)
		if vent != EuropaTerrain.NONE:
			spots.append([&"plume", vent])
		for e: Array in spots:
			var p: Vector2i = e[1]
			out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if io != null:   # the big lava lake, the mountain's top, the volcano nearest the pad
		var spots: Array = [[&"lake", io.lake_centre()], [&"mountain", io.peak_centre()]]
		var vent := io.nearest_vent(_spawn)
		if vent != IoTerrain.NONE:
			spots.append([&"plume", vent])
		for e: Array in spots:
			var p: Vector2i = e[1]
			out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if titan != null:   # the sea's beach on the way to it, the first dune south of the pad, the mountains' top
		var spots: Array = [[&"sea", titan.sea_beach_toward(_spawn)], [&"dunes", titan.first_dune_south_of(_spawn)],
			[&"mountain", titan.peak_centre()]]
		for e: Array in spots:
			var p: Vector2i = e[1]
			if p != TitanTerrain.NONE:
				out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if rings != null:   # the Saturn scope, the station, the Cassini Division, the C ring, the F ring, Pan
		for e: Array in rings.sight_spots():
			var p: Vector2i = e[1]
			out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if venus != null:   # the cloud scope, the dock, the sky garden, the cloud homes, the west lookout
		for e: Array in venus.sight_spots():
			var p: Vector2i = e[1]
			out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if pluto != null:   # the lookout by the pad, the heart's shore, a hill, the peak, the red-brown lands, the bright side
		var spots: Array = [[&"lookout", pluto.lookout], [&"heart", pluto.plain_shore_toward(_spawn)],
			[&"hills", pluto.nearest_hill(_spawn)], [&"mountains", pluto.peak_centre()],
			[&"dark", pluto.first_dark_west_of(_spawn)], [&"bright", pluto.bright_centre()]]
		for e: Array in spots:
			var p: Vector2i = e[1]
			if p != PlutoTerrain.NONE:
				out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if triton != null:   # the lookout by the pad, the first geyser and its streak, the cap, the cantaloupe terrain, the lake,
		var spots: Array = [[&"lookout", triton.lookout]]   # the crater
		spots.append_array(triton.sight_spots(_spawn))
		for e: Array in spots:
			var p: Vector2i = e[1]
			if p != TritonTerrain.NONE:
				out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if ganymede != null:   # the lookout, the grooves, the dark terrain, the crater, the frost, the watch, the drill
		for e: Array in ganymede.sight_spots(_spawn):
			var p: Vector2i = e[1]
			if p != GanymedeTerrain.NONE:
				out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if mercury != null:   # the thermometer by the pad, the great cliff's face, the nearest big crater, the ice crater
		var spots: Array = [[&"thermometer", _thermometer], [&"scarp", mercury.great_face_toward(_spawn)],
			[&"crater", mercury.nearest_crater(_spawn)], [&"ice", mercury.ice_centre()]]
		for e: Array in spots:
			var p: Vector2i = e[1]
			if p != MercuryTerrain.NONE:
				out.append({"id": e[0], "pos": Vector3(p.x + 0.5, height_at(p.x, p.y), p.y + 0.5)})
		return out
	if mars == null:
		_colony_sight(out)
		return out
	var vc := mars.volcano_centre()
	var cz := roundi(mars.canyon_z(_spawn.x))
	for e: Array in [[&"volcano", vc], [&"canyon", Vector2i(_spawn.x, cz)],
			[&"north_cap", Vector2i(_spawn.x, mars.north_edge() - 40)], [&"south_cap", Vector2i(_spawn.x, mars.south_edge() + 40)]]:
		var at: Vector2i = e[1]
		out.append({"id": e[0], "pos": Vector3(at.x + 0.5, height_at(at.x, at.y), at.y + 0.5)})
	_colony_sight(out)
	return out


## Spec §21c: the colony is a big sight (MY MAP, the explorer's checklist) at its Great Dome's middle (the dome's own
## sight: walking in finds it); its other parts are small sights found by walking in (is_part_sight).
func _colony_sight(out: Array[Dictionary]) -> void:
	if colony == null:
		return
	var at := colony.part_centre(ColonyRules.DOME)
	out.append({"id": ColonyRules.DOME, "pos": Vector3(at.x + 0.5, height_at(at.x, at.y), at.y + 0.5)})


## Spec §21c: a colony's part other than the Great Dome (found by walking in; never marked on MY MAP by itself).
func is_part_sight(id: StringName) -> bool:
	return colony != null and ColonyRules.is_small_part(id)


## A column between the flat pad and the planet's own ground.
func _blend(d2: int, raw: int) -> int:
	var k := smoothstep(float(FLAT_RADIUS), float(BLEND_RADIUS), sqrt(float(d2)))
	return roundi(lerpf(float(_spawn_h), float(raw), k))


## Titan: liquid methane at the top (a lake or the sea): never dry land for a spawner. Venus: the clouds far below and
## the bridges (every spawner keeps to the platforms). Saturn's rings: open space, the lumps and Pan (every spawner keeps
## to the big chunks). Every other planet: none.
func is_river(x: int, z: int) -> bool:
	if rings != null:
		return rings.is_open(x, z)
	if venus != null:
		var k := venus.kind_at(x, z)
		return k == VenusTerrain.CLOUD or k == VenusTerrain.BRIDGE
	return titan != null and ground_at(x, z) < TitanTerrain.LIQUID_TOP


func spawn_column() -> Vector2i:
	return _spawn


## By a pool's edge or in it (the animals' SHORE in space): Planet Boing's jelly pools; none elsewhere.
func near_pool(x: int, z: int) -> bool:
	return planet == BOING and ground_at(x, z) <= JELLY_LEVEL + 1


## The landing pad's disc (its top is LANDING_PAD).
func pad_at(x: int, z: int) -> bool:
	return (x - _spawn.x) * (x - _spawn.x) + (z - _spawn.y) * (z - _spawn.y) <= PAD_RADIUS * PAD_RADIUS + PAD_RADIUS


## The block of the planet's ground at (x, y, z) (no features, no secrets): the generator's slow reference.
func block_at(x: int, y: int, z: int) -> int:
	if planet == RINGS:   # no bedrock: open space under the rings
		return _rings_block_at(x, y, z)
	if y <= bedrock_top(x, z):
		return BlockIds.BEDROCK
	if planet == EUROPA:
		return _europa_block_at(x, y, z)
	if planet == IO:
		return _io_block_at(x, y, z)
	if planet == TITAN:
		return _titan_block_at(x, y, z)
	if planet == MERCURY:
		return _mercury_block_at(x, y, z)
	if planet == VENUS:
		return _venus_block_at(x, y, z)
	if planet == PLUTO:
		return _pluto_block_at(x, y, z)
	if planet == TRITON:
		return _triton_block_at(x, y, z)
	if planet == GANYMEDE:
		return _ganymede_block_at(x, y, z)
	var g := ground_at(x, z)
	var h := top_of(g)
	if y >= h:
		return BlockIds.AIR
	if y >= g:
		return BlockIds.JELLY
	if y < 0:
		return deep_block()
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	if planet == MARS:
		return MarsTerrain.block(y, g, mars_kind(x, z))
	return ground_block(y, g, h)


## Europa's block at (x, y, z) over the bedrock: the well's own blocks, else the column's layers under its ice top.
func _europa_block_at(x: int, y: int, z: int) -> int:
	var c := europa.column(x, z)
	var kind := c & 15
	var g := _europa_top(x, z, c >> 4)
	if kind == EuropaTerrain.WELL:
		var w := europa.well_block(x, y, z, g)
		if w >= 0:
			return w
	if y >= g:
		return BlockIds.AIR
	if y < 0:
		return BlockIds.EUROPA_ROCK
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return EuropaTerrain.block(y, g, kind)


## Io's block at (x, y, z) over the bedrock: its rock under y 0, the column's layers under its ground.
func _io_block_at(x: int, y: int, z: int) -> int:
	var c := io.column(x, z)
	var g := _pad_blend(x, z, c >> 4)
	if y >= g:
		return BlockIds.AIR
	if y < 0:
		return BlockIds.IO_ROCK
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return IoTerrain.block(y, g, c & 15)


## Titan's block at (x, y, z) over the bedrock: icy rock under y 0, the column's layers under its ground, liquid methane
## (WATER) over a lake's or the sea's bed up to TitanTerrain.LIQUID_TOP.
func _titan_block_at(x: int, y: int, z: int) -> int:
	var c := titan.column(x, z)
	var g := _pad_blend(x, z, c >> 4)
	if y >= top_of(g):
		return BlockIds.AIR
	if y >= g:
		return BlockIds.WATER
	if y < 0:
		return BlockIds.ICY_ROCK
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return TitanTerrain.block(y, g, c & 15)


## Mercury's block at (x, y, z) over the bedrock: its rock under y 0, the column's layers under its ground.
func _mercury_block_at(x: int, y: int, z: int) -> int:
	var c := mercury.column(x, z)
	var g := _pad_blend(x, z, c >> 4)
	if y >= g:
		return BlockIds.AIR
	if y < 0:
		return BlockIds.MERCURY_ROCK
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return MercuryTerrain.block(y, g, c & 15)


## Pluto's block at (x, y, z) over the bedrock: water ice under y 0, the column's layers under its ground.
func _pluto_block_at(x: int, y: int, z: int) -> int:
	var c := pluto.column(x, z)
	var g := _pad_blend(x, z, c >> 4)
	if y >= g:
		return BlockIds.AIR
	if y < 0:
		return BlockIds.WATER_ICE
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return PlutoTerrain.block(y, g, c & 15)


## Triton's block at (x, y, z) over the bedrock: water ice (its icy mantle) under y 0, the column's layers under its
## ground.
func _triton_block_at(x: int, y: int, z: int) -> int:
	var c := triton.column(x, z)
	var g := _pad_blend(x, z, c >> 4)
	if y >= g:
		return BlockIds.AIR
	if y < 0:
		return BlockIds.WATER_ICE
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return TritonTerrain.block(y, g, c & 15)


## Ganymede's block at (x, y, z) over the bedrock: water ice (its icy crust) under y 0, the column's layers under its
## ground.
func _ganymede_block_at(x: int, y: int, z: int) -> int:
	var c := ganymede.column(x, z)
	var g := _pad_blend(x, z, c >> 4)
	if y >= g:
		return BlockIds.AIR
	if y < 0:
		return BlockIds.WATER_ICE
	if y == g - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return GanymedeTerrain.block(y, g, c & 15)


## Venus's block at (x, y, z) over the bedrock: a platform's or a bridge's (the landing pad on the pad), else the clouds.
func _venus_block_at(x: int, y: int, z: int) -> int:
	var c := venus.column(x, z)
	if c[0] != VenusTerrain.CLOUD and y == c[1] - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return VenusTerrain.block(y, c)


## Saturn's rings' block at (x, y, z): a chunk's (the landing pad on the pad), else open space.
func _rings_block_at(x: int, y: int, z: int) -> int:
	var c := rings.column(x, z)
	if c[0] != RingsTerrain.VOID and y == c[1] - 1 and pad_at(x, z):
		return BlockIds.LANDING_PAD
	return RingsTerrain.block(y, c)


## The rock under y 0.
func deep_block() -> int:
	match planet:
		BOING:
			return BlockIds.BOING_ROCK
		RAINBOW:
			return BlockIds.RAINBOW_VIOLET
		MARS:
			return BlockIds.DEEP_BASALT
		EUROPA:
			return BlockIds.EUROPA_ROCK
		IO:
			return BlockIds.IO_ROCK
		TITAN:
			return BlockIds.ICY_ROCK
		MERCURY:
			return BlockIds.MERCURY_ROCK
		VENUS:   # the deep clouds
			return BlockIds.DEEP_CLOUD
		RINGS:   # open space
			return BlockIds.AIR
		PLUTO, TRITON, GANYMEDE:   # water ice, as hard as rock (Triton's icy mantle, Ganymede's icy crust)
			return BlockIds.WATER_ICE
	return BlockIds.DEEP_MOON_ROCK


## The rock ores may replace.
func rock_ids() -> Array[int]:
	match planet:
		BOING:
			return [BlockIds.BOING_ROCK]
		RAINBOW:
			return RainbowBlocks.STRIPES.duplicate()
		MARS:
			return [BlockIds.BASALT, BlockIds.DEEP_BASALT]
		EUROPA:   # the seafloor rock under the ice (never the ice)
			return [BlockIds.EUROPA_ROCK]
		IO:   # Io's rock (never its black lava layers)
			return [BlockIds.IO_ROCK]
		TITAN:   # its icy rock
			return [BlockIds.ICY_ROCK]
		MERCURY:   # its grey rock
			return [BlockIds.MERCURY_ROCK]
		VENUS:   # no rock in the clouds: no ores
			return []
		RINGS:   # ice (and a few lumps of rock): no ore veins
			return []
		PLUTO, TRITON, GANYMEDE:   # the water-ice bedrock (never the nitrogen ice or the frosts)
			return [BlockIds.WATER_ICE]
	return [BlockIds.MOON_ROCK, BlockIds.DEEP_MOON_ROCK]


## The rock between y 0 and the surface layers (Rainbow Planet: stripe(y)).
func rock_block() -> int:
	match planet:
		BOING:
			return BlockIds.BOING_ROCK
		MARS:
			return BlockIds.BASALT
		EUROPA:
			return BlockIds.DEEP_ICE
		IO:
			return BlockIds.IO_ROCK
		TITAN:
			return BlockIds.ICY_ROCK
		MERCURY:
			return BlockIds.MERCURY_ROCK
		VENUS:
			return BlockIds.DEEP_CLOUD
		RINGS:
			return BlockIds.RING_ICE
		PLUTO, TRITON, GANYMEDE:
			return BlockIds.WATER_ICE
	return BlockIds.MOON_ROCK


## Rainbow Planet's rock at height y: six stripes of STRIPE_HEIGHT, red at the bottom.
static func stripe(y: int) -> int:
	return RainbowBlocks.STRIPES[posmod(floori(y / float(STRIPE_HEIGHT)), RainbowBlocks.STRIPES.size())]


## A column's block at y (0 <= y < g, not the pad) under solid ground g and top h.
func ground_block(y: int, g: int, h: int) -> int:
	match planet:
		BOING:
			if y == g - 1:
				return BlockIds.BOING_MOSS if g == h else BlockIds.BOING_SOIL
			return BlockIds.BOING_SOIL if y >= g - SOIL_DEPTH else BlockIds.BOING_ROCK
		RAINBOW:
			return BlockIds.PRISM_GRASS if y == g - 1 else stripe(y)
		MARS:   # the plains' layers (a column's own: MarsTerrain.block)
			return MarsTerrain.block(y, g, MarsTerrain.PLAINS)
		EUROPA:
			return EuropaTerrain.block(y, g, EuropaTerrain.PLAINS)
		IO:
			return IoTerrain.block(y, g, IoTerrain.PLAINS)
		TITAN:
			return TitanTerrain.block(y, g, TitanTerrain.PLAINS)
		MERCURY:
			return MercuryTerrain.block(y, g, MercuryTerrain.PLAINS)
		VENUS:
			return BlockIds.VENUS_CLOUD if y == g - 1 else BlockIds.DEEP_CLOUD
		RINGS:
			return BlockIds.RING_FROST if y == g - 1 else BlockIds.RING_ICE
		PLUTO:
			return PlutoTerrain.block(y, g, PlutoTerrain.UPLANDS)
		TRITON:
			return TritonTerrain.block(y, g, TritonTerrain.FROST)
		GANYMEDE:
			return GanymedeTerrain.block(y, g, GanymedeTerrain.SMOOTH)
	return BlockIds.MOON_DUST if y >= g - DUST_DEPTH else BlockIds.MOON_ROCK


## How many blocks down from the top the surface layers reach (the rest is rock).
func surface_depth() -> int:
	match planet:
		BOING:
			return SOIL_DEPTH
		RAINBOW:
			return 1
		MARS:
			return 4
		EUROPA:
			return EuropaTerrain.SUB_DEPTH + 1
		IO:
			return IoTerrain.sub_depth(IoTerrain.PLAINS) + 1
		TITAN:
			return TitanTerrain.sub_depth(TitanTerrain.PLAINS) + 1
		MERCURY:
			return MercuryTerrain.sub_depth(MercuryTerrain.PLAINS) + 1
		VENUS, RINGS:
			return 1
		PLUTO:
			return PlutoTerrain.SUB_DEPTH + 1
		TRITON:
			return TritonTerrain.FROST_DEPTH + 1
		GANYMEDE:
			return GanymedeTerrain.SUB_DEPTH + 1
	return DUST_DEPTH


# --- Features (the planets' "trees") --------------------------------------------------------------------

## How far a feature reaches sideways from its column.
func feature_reach() -> int:
	match planet:
		BOING:
			return 2
		RAINBOW, EUROPA, IO, TITAN, MERCURY, RINGS, PLUTO, TRITON, GANYMEDE:
			return 0
		VENUS:   # a little tree's crown
			return 1
	return 1


func tree_at(x: int, z: int) -> bool:
	if colony != null and colony.covers(x, z, 2):   # spec §21c: nothing grows on the colony's ground
		return false
	var roll := absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000
	match planet:
		BOING:
			return roll < SPRING_PER_MILLE and not _near_spawn(x, z) and ground_at(x, z) > JELLY_LEVEL + 1
		RAINBOW:
			return roll < SPIRE_PER_MILLE and not _near_spawn(x, z)
		MARS:   # a boulder anywhere on the ground; a gypsum crystal only where water was
			if roll >= GYPSUM_PER_MILLE or _near_spawn(x, z):
				return false
			var kind := mars_kind(x, z)
			if roll < BOULDER_PER_MILLE:
				return not MarsTerrain.is_cap(kind)
			return kind == MarsTerrain.VALLEY or kind == MarsTerrain.CANYON
		EUROPA:   # a salt crystal in a crack; an ice blade in a blade field on the plains or the cliffs' top
			if roll >= BLADE_PER_MILLE or _near_spawn(x, z):
				return false
			var kind := europa_kind(x, z)
			if roll < SALT_PER_MILLE:
				return kind == EuropaTerrain.LINEA or kind == EuropaTerrain.RIDGE
			return (kind == EuropaTerrain.PLAINS or kind == EuropaTerrain.CLIFF_TOP) and europa.blade_field(x, z)
		IO:   # a lava boulder on the plains or a red ring; a sulphur crystal on the plains
			if roll >= SULPHUR_CRYSTAL_PER_MILLE or _near_spawn(x, z):
				return false
			var kind := io_kind(x, z)
			if roll < LAVA_BOULDER_PER_MILLE:
				return IoTerrain.is_plains(kind) or kind == IoTerrain.RED_RING
			return IoTerrain.is_plains(kind)
		TITAN:   # an ice boulder on the plains; a shore crystal on a beach, by the methane
			if roll >= SHORE_CRYSTAL_PER_MILLE or _near_spawn(x, z):
				return false
			var c := titan.column(x, z)
			if roll < ICE_BOULDER_PER_MILLE:
				return TitanTerrain.is_plains(c & 15)
			return TitanTerrain.is_shore(c & 15) and c >> 4 == TitanTerrain.LIQUID_TOP
		MERCURY:   # the thermometer by the pad; a rock boulder on the plains; an ice crystal on a polar crater's ice
			if x == _thermometer.x and z == _thermometer.y:
				return true
			if roll >= ICE_CRYSTAL_PER_MILLE or _near_spawn(x, z):
				return false
			var k := mercury.column(x, z) & 15
			if roll < ROCK_BOULDER_PER_MILLE:
				return MercuryTerrain.is_plains(k)
			return k == MercuryTerrain.ICE
		VENUS:   # lamp posts on rims and bridges, flowers and little trees in the gardens (VenusTerrain.feature_at)
			return not _near_spawn(x, z) and venus.feature_at(x, z) != VenusTerrain.NO_FEATURE
		RINGS:   # nothing grows on ice: the built parts' ground only (Tilly, the Totem and secrets keep off it)
			return rings.kept(x, z, 1)
		PLUTO:   # the lookout's ground (kept); a water-ice boulder on the uplands or the red-brown lands; a frost crystal
			if pluto.on_lookout(x, z, 1):   # on the heart's bright side
				return true
			if roll >= FROST_CRYSTAL_PER_MILLE or _near_spawn(x, z):
				return false
			var k := pluto.column(x, z) & 15
			if roll < WATER_BOULDER_PER_MILLE:
				return PlutoTerrain.is_plains(k) or PlutoTerrain.is_dark(k)
			return k == PlutoTerrain.BRIGHT
		TRITON:   # the lookout's ground (kept); a water-ice boulder on the band or the cantaloupe terrain; a nitrogen
			if triton.on_lookout(x, z, 1):   # crystal on the cap's pink ice
				return true
			if roll >= N2_CRYSTAL_PER_MILLE or _near_spawn(x, z):
				return false
			var k := triton.column(x, z) & 15
			if roll < SNOW_BOULDER_PER_MILLE:
				return TritonTerrain.is_plains(k) or TritonTerrain.is_melon(k)
			return k == TritonTerrain.CAP or k == TritonTerrain.MOTTLE
		GANYMEDE:   # the built parts' ground (kept); a boulder on the plains, the grooves or the dark terrain; an aurora
			if ganymede.on_part(x, z, 1):   # crystal on the poles' frost or in the ray crater's pit
				return true
			if roll >= PIT_CRYSTAL_PER_MILLE or _near_spawn(x, z):
				return false
			if roll >= AURORA_CRYSTAL_PER_MILLE:   # only the pit's crystals are this many
				return ganymede.in_pit(x, z)
			var k := ganymede.column(x, z) & 15
			if k == GanymedeTerrain.PIT:
				return true
			if roll < ICE_ROCK_PER_MILLE:
				return k == GanymedeTerrain.SMOOTH or GanymedeTerrain.is_grooved(k) or GanymedeTerrain.is_dark(k)
			return k == GanymedeTerrain.FROST
	if roll >= CRYSTAL_IN_CRATER:
		return false
	if _near_spawn(x, z):
		return false
	return roll < CRYSTAL_ELSEWHERE or crater_depth(x, z) < -1.0


## The Moon's crystal height, Boing's stalk, Rainbow's spire.
func tree_height(x: int, z: int) -> int:
	var h := absi(_hash(z * 7 - 3, x * 11 + 5))
	match planet:
		BOING:
			return 3 + h % 4
		RAINBOW:
			return 3 + h % 5
		MARS:
			return 1 + h % (2 if _boulder(x, z) else 3)
		EUROPA:
			return 1 + h % 2 if _salt(x, z) else 2 + h % 3
		IO:
			return 1 + h % 2 if _lava_boulder(x, z) else 1 + h % 3
		TITAN:
			return 1 + h % 2
		MERCURY:
			return THERMOMETER_H if x == _thermometer.x and z == _thermometer.y else 1 + h % 2
		VENUS:
			return VenusTerrain.feature_height(venus.feature_at(x, z))
		RINGS:   # the built parts are the generator's (RingsTerrain.write), never a feature
			return 0
		PLUTO:   # the lookout is the generator's (PlutoTerrain.write), never a feature
			return 0 if pluto.on_lookout(x, z, 1) else 1 + h % 2
		TRITON:   # the lookout is the generator's (TritonTerrain.write), never a feature
			return 0 if triton.on_lookout(x, z, 1) else 1 + h % 2
		GANYMEDE:   # the built parts are the generator's (GanymedeTerrain.write), never a feature
			return 0 if ganymede.on_part(x, z, 1) else 1 + h % 2
	return 1 + h % 4


## How far above its column's ground the feature on (x, z) reaches (and one block below: the Moon's little crystals).
func feature_top(x: int, z: int) -> int:
	return tree_height(x, z) + (2 if planet == BOING else 0)


## The feature block at (x, y, z) from any feature within reach, or -1 (slow: the generator's reference).
func feature_at(x: int, y: int, z: int) -> int:
	var r := feature_reach()
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if not tree_at(x + dx, z + dz):
				continue
			var id := feature_block(x + dx, z + dz, Vector3i(x, y, z))
			if id >= 0:
				return id
	return -1


## The block the feature standing on column (tx, tz) puts at cell p, or -1.
func feature_block(tx: int, tz: int, p: Vector3i) -> int:
	var base := height_at(tx, tz)
	var tall := tree_height(tx, tz)
	var dx := p.x - tx
	var dz := p.z - tz
	match planet:
		BOING:   # a stalk, a wide cap (5 × 5 without its corners) and a small dome on it
			if dx == 0 and dz == 0 and p.y >= base and p.y < base + tall:
				return BlockIds.SPRING_STEM
			if p.y == base + tall and absi(dx) <= 2 and absi(dz) <= 2 and not (absi(dx) == 2 and absi(dz) == 2):
				return BlockIds.SPRING_CAP
			if p.y == base + tall + 1 and absi(dx) <= 1 and absi(dz) <= 1 and not (absi(dx) == 1 and absi(dz) == 1):
				return BlockIds.SPRING_CAP
			return -1
		RAINBOW:
			return BlockIds.PRISM_CRYSTAL if dx == 0 and dz == 0 and p.y >= base and p.y < base + tall else -1
		MARS:   # a boulder (two tall ones have small stones round their foot) or a gypsum crystal
			var boulder := _boulder(tx, tz)
			if dx == 0 and dz == 0 and p.y >= base and p.y < base + tall:
				return BlockIds.BASALT if boulder else BlockIds.GYPSUM
			if boulder and absi(dx) + absi(dz) == 1 and tall >= 2 and p.y >= base - 1 and p.y <= base \
					and p.y == height_at(p.x, p.z):
				return BlockIds.BASALT
			return -1
		EUROPA:   # a salt crystal or an ice blade, one column wide
			if dx == 0 and dz == 0 and p.y >= base and p.y < base + tall:
				return BlockIds.SALT if _salt(tx, tz) else BlockIds.EUROPA_ICE
			return -1
		IO:   # a lava boulder or a sulphur crystal, one column wide
			if dx == 0 and dz == 0 and p.y >= base and p.y < base + tall:
				return BlockIds.BLACK_LAVA if _lava_boulder(tx, tz) else BlockIds.SULPHUR_CRYSTAL
			return -1
		TITAN:   # an ice boulder or a shore crystal, one column wide
			if dx == 0 and dz == 0 and p.y >= base and p.y < base + tall:
				return BlockIds.ICY_ROCK if _ice_boulder(tx, tz) else BlockIds.SHORE_CRYSTAL
			return -1
		MERCURY:   # the thermometer (a plinth, its red bulb, its tube), a rock boulder or an ice crystal, one column wide
			if dx != 0 or dz != 0 or p.y < base or p.y >= base + tall:
				return -1
			if tx == _thermometer.x and tz == _thermometer.y:
				if p.y == base:
					return BlockIds.EXPLORER_BRICK
				return BlockIds.THERMO_BULB if p.y == base + 1 else BlockIds.THERMOMETER
			return BlockIds.MERCURY_ROCK if _rock_boulder(tx, tz) else BlockIds.ICE_CRYSTAL
		VENUS:   # a lamp post, a flower or a little tree (a trunk and a crown)
			return VenusTerrain.feature_block(venus.feature_at(tx, tz), tx, tz, base, p)
		RINGS:   # none
			return -1
		PLUTO:   # a water-ice boulder or a frost crystal, one column wide (none on the lookout's ground)
			if dx != 0 or dz != 0 or p.y < base or p.y >= base + tall:
				return -1
			return BlockIds.WATER_ICE if _water_boulder(tx, tz) else BlockIds.FROST_CRYSTAL
		TRITON:   # a water-ice boulder or a nitrogen crystal, one column wide (none on the lookout's ground)
			if dx != 0 or dz != 0 or p.y < base or p.y >= base + tall:
				return -1
			return BlockIds.WATER_ICE if _snow_boulder(tx, tz) else BlockIds.NITROGEN_CRYSTAL
		GANYMEDE:   # a boulder (old ice on the dark terrain, water ice elsewhere) or an aurora crystal, one column wide
			if dx != 0 or dz != 0 or p.y < base or p.y >= base + tall:
				return -1
			var k := ganymede.column(tx, tz) & 15
			if k == GanymedeTerrain.FROST or k == GanymedeTerrain.PIT:
				return BlockIds.AURORA_CRYSTAL
			return BlockIds.OLD_ICE if GanymedeTerrain.is_dark(k) else BlockIds.WATER_ICE
	if dx == 0 and dz == 0 and p.y >= base and p.y < base + tall:
		return BlockIds.MOON_CRYSTAL
	if absi(dx) + absi(dz) == 1 and tall >= 3 and p.y >= base - 1 and p.y <= base and p.y == height_at(p.x, p.z):
		return BlockIds.MOON_CRYSTAL   # a big crystal's little ones round its foot
	return -1


## Triton: a feature's kind from its roll alone (tree_at chose it; not the lookout): a boulder, else a nitrogen crystal.
func _snow_boulder(x: int, z: int) -> bool:
	return absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000 < SNOW_BOULDER_PER_MILLE


## Pluto: a feature's kind from its roll alone (tree_at chose it; not the lookout): a boulder, else a frost crystal.
func _water_boulder(x: int, z: int) -> bool:
	return absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000 < WATER_BOULDER_PER_MILLE


## Mercury: a feature's kind from its roll alone (tree_at chose it; not the thermometer): a boulder, else an ice crystal.
func _rock_boulder(x: int, z: int) -> bool:
	return absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000 < ROCK_BOULDER_PER_MILLE


## Titan: a feature's kind from its roll alone (tree_at chose it): an ice boulder, else a shore crystal.
func _ice_boulder(x: int, z: int) -> bool:
	return absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000 < ICE_BOULDER_PER_MILLE


## Io: a feature's kind from its roll alone (tree_at chose it): a lava boulder, else a sulphur crystal.
func _lava_boulder(x: int, z: int) -> bool:
	return absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000 < LAVA_BOULDER_PER_MILLE


## Europa: a feature's kind from its roll alone (tree_at chose it): a salt crystal, else an ice blade.
func _salt(x: int, z: int) -> bool:
	return absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000 < SALT_PER_MILLE


## Mars: a feature's kind from its roll alone (tree_at chose it): a boulder, else a gypsum crystal.
func _boulder(x: int, z: int) -> bool:
	return absi(_hash(x * 3 + 17, z * 5 - 29)) % 1000 < BOULDER_PER_MILLE


# --- The Moon's and Mars's craters -------------------------------------------------------------------------

## The craters' cell size (Mars: bigger cells, fewer craters).
func _crater_cell() -> int:
	return MARS_CRATER_CELL if planet == MARS else CRATER_CELL


## The crater of cell (x, z / its cell size): {center: Vector2i, radius: float}, or {} (no crater there).
func crater_in_cell(cell: Vector2i) -> Dictionary:
	var h := absi(_hash(cell.x * 7 + 11, cell.y * 13 - 5))
	var mars_craters := planet == MARS
	if h % 100 >= (MARS_CRATER_CHANCE if mars_craters else CRATER_CHANCE):
		return {}
	var size := _crater_cell()
	var lo := MARS_CRATER_MIN if mars_craters else CRATER_MIN
	var hi := MARS_CRATER_MAX if mars_craters else CRATER_MAX
	var margin := 6
	var cx := cell.x * size + margin + (h >> 8) % (size - 2 * margin)
	var cz := cell.y * size + margin + (h >> 16) % (size - 2 * margin)
	return {"center": Vector2i(cx, cz), "radius": float(lo + (h >> 24) % (hi - lo + 1))}


## The craters' change to the ground at (x, z): a bowl (negative) inside one, a raised rim round it (0 off the Moon).
## Craters reach at most CRATER_MAX × RIM_OUT (≈ 20) from a centre drawn at least 6 inside its cell: only the 3 × 3
## cells round a column's own can touch it. Summed in (cell z, cell x) order, as _craters_near's lists are.
func crater_depth(x: int, z: int) -> float:
	if planet != MOON and planet != MARS:
		return 0.0
	var size := float(_crater_cell())
	var cell := Vector2i(floori(x / size), floori(z / size))
	var total := 0.0
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var c := crater_in_cell(cell + Vector2i(dx, dz))
			if not c.is_empty():
				total = _crater_add(total, x, z, (c.center as Vector2i).x, (c.center as Vector2i).y, c.radius)
	return total


## `total` with the crater at (cx, cz) of radius r added at column (x, z).
static func _crater_add(total: float, x: int, z: int, cx: int, cz: int, r: float) -> float:
	var ox := float(x - cx)
	var oz := float(z - cz)
	var d2 := (ox * ox + oz * oz) / (r * r)
	if d2 >= RIM_OUT * RIM_OUT:
		return total
	if d2 < 1.0:
		return total - r * CRATER_DEPTH * (1.0 - d2)
	return total + maxf(1.0, r * 0.16) * (RIM_OUT - sqrt(d2)) / (RIM_OUT - 1.0)


## Every crater that may touch the columns x0..x1, z0..z1: [cx, cz, r × 100] triples in (cell z, cell x) order.
func _craters_near(x0: int, z0: int, x1: int, z1: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var size := float(_crater_cell())
	var c0 := Vector2i(floori(x0 / size) - 1, floori(z0 / size) - 1)
	var c1 := Vector2i(floori(x1 / size) + 1, floori(z1 / size) + 1)
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var c := crater_in_cell(Vector2i(cx, cz))
			if not c.is_empty():
				out.append_array([(c.center as Vector2i).x, (c.center as Vector2i).y, roundi(float(c.radius) * 100.0)])
	return out


## _raw_height with the craters of `craters` (_craters_near's list round the column; empty off the Moon and Mars).
func _raw_from(x: int, z: int, craters: PackedInt32Array) -> int:
	return _height_from(x, z, _crater_sum(x, z, craters))


## crater_depth(x, z) from `craters` (_craters_near's list round the column), in the same order, so it is equal.
func _crater_sum(x: int, z: int, craters: PackedInt32Array) -> float:
	var total := 0.0
	var size := float(_crater_cell())
	var cell := Vector2i(floori(x / size), floori(z / size))
	for i in range(0, craters.size(), 3):
		var cx := craters[i]
		var cz := craters[i + 1]
		if absi(floori(cx / size) - cell.x) > 1 or absi(floori(cz / size) - cell.y) > 1:
			continue   # only the 3 × 3 cells round the column, like crater_depth
		total = _crater_add(total, x, z, cx, cz, craters[i + 2] / 100.0)
	return total


# --- Helpers -----------------------------------------------------------------------------------------------

## The planet's own ground height at (x, z), before the landing pad.
func _raw_height(x: int, z: int) -> int:
	return _height_from(x, z, crater_depth(x, z))


## The planet's own ground at (x, z) (`crater`: the Moon's or Mars's craters' change there), flat under a colony.
func _height_from(x: int, z: int, crater: float) -> int:
	if colony != null:
		return colony.flatten(x, z, _own_height(x, z, crater))
	return _own_height(x, z, crater)


## The planet's own ground at (x, z) before any colony.
func _own_height(x: int, z: int, crater: float) -> int:
	if planet == MARS:
		return mars.column(x, z, crater) >> 4
	if planet == EUROPA:   # a well column's real ground (its seafloor or its ramp)
		var c := europa.column(x, z)
		return europa.well_ground(x, z, c >> 4) if (c & 15) == EuropaTerrain.WELL else c >> 4
	if planet == IO:
		return io.column(x, z) >> 4
	if planet == TITAN:
		return titan.column(x, z) >> 4
	if planet == MERCURY:
		return mercury.column(x, z) >> 4
	if planet == VENUS:
		return venus.top_at(x, z)
	if planet == RINGS:
		return rings.top_at(x, z)
	if planet == PLUTO:
		return pluto.column(x, z) >> 4
	if planet == TRITON:
		return triton.column(x, z) >> 4
	if planet == GANYMEDE:
		return ganymede.column(x, z) >> 4
	var h := 0.0
	match planet:
		BOING:   # round rolling hills; the dips go under JELLY_LEVEL
			h = BOING_BASE + 9.0 * _swell.get_noise_2d(x, z) + 1.0 * _fine.get_noise_2d(x, z)
		RAINBOW:   # terraced hills: every TERRACE, half the step flat and half a one-block climb
			var v := RAINBOW_BASE + 12.0 * _swell.get_noise_2d(x, z) + 16.0 * maxf(_peaks.get_noise_2d(x, z), 0.0)
			var step := floorf(v / TERRACE) * TERRACE
			h = step + floorf(clampf(v - step - TERRACE * 0.5, 0.0, TERRACE * 0.5 - 0.001) * 2.0)
		_:
			h = MOON_BASE + 6.0 * _swell.get_noise_2d(x, z) + 1.5 * _fine.get_noise_2d(x, z) + crater
	return clampi(roundi(h), MIN_GROUND, MAX_GROUND)


func _near_spawn(x: int, z: int) -> bool:
	return (x - _spawn.x) * (x - _spawn.x) + (z - _spawn.y) * (z - _spawn.y) <= BLEND_RADIUS * BLEND_RADIUS


## A calm spot near the middle for the landing pad (rings outward from the origin): no crater (the Moon), no pool
## (Boing) within the blend. Venus: the landing deck's middle. Saturn's rings: the landing chunk's middle.
func _find_spawn() -> Vector2i:
	if planet == VENUS:
		return venus.spawn()
	if planet == RINGS:
		return rings.spawn()
	for ring in SPAWN_RINGS:
		var n := maxi(ring * 6, 1)
		for i in n:
			var a := TAU * i / n
			var c := Vector2i(roundi(cos(a) * ring * SPAWN_STEP), roundi(sin(a) * ring * SPAWN_STEP))
			if _calm(c):
				return c
	return Vector2i.ZERO


func _calm(c: Vector2i) -> bool:
	if planet == RAINBOW:
		return true
	if planet == MARS:
		return _mars_calm(c)
	if planet == EUROPA:
		return _europa_calm(c)
	if planet == IO:
		return _io_calm(c)
	if planet == TITAN:
		return _titan_calm(c)
	if planet == MERCURY:
		return _mercury_calm(c)
	if planet == PLUTO:
		return _pluto_calm(c)
	if planet == TRITON:
		return _triton_calm(c)
	if planet == GANYMEDE:
		return _ganymede_calm(c)
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		if planet == BOING:
			if _raw_height(c.x + d.x, c.y + d.y) <= JELLY_LEVEL + 2:
				return false
		elif absf(crater_depth(c.x + d.x, c.y + d.y)) > 0.01:
			return false
	return true


## Mars: the landing pad on quiet plains, a walk from the volcano, the canyon and the caps; no river or crater on it.
func _mars_calm(c: Vector2i) -> bool:
	if Vector2(c - mars.volcano_centre()).length() < MarsTerrain.VOLCANO_RADIUS + 60.0:
		return false
	if absf(c.y - mars.canyon_z(c.x)) < 90.0 or c.y < mars.north_edge() + 200 or c.y > mars.south_edge() - 200:
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		var p := c + d
		if absf(crater_depth(p.x, p.y)) > 0.01 or not mars.calm(p.x, p.y) or mars_kind(p.x, p.y) != MarsTerrain.PLAINS:
			return false
	return true


## Europa: the landing pad on calm plains, a walk from the ocean well, the ice cliffs and the plumes (the landmark a short
## walk from it stays clear of them all); no crack on it.
func _europa_calm(c: Vector2i) -> bool:
	if Vector2(c - europa.well_centre()).length() < 120.0:
		return false
	if Vector2(c - europa.mesa_centre()).length() < EuropaTerrain.MESA_RADIUS + EuropaTerrain.MESA_WOBBLE + 80.0:
		return false
	if not europa.vents_near(c.x, c.y, 80.0).is_empty():
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		var p := c + d
		if not europa.calm(p.x, p.y) or europa_kind(p.x, p.y) != EuropaTerrain.PLAINS:
			return false
	return true


## Io: the landing pad on calm sulphur plains, a walk from the big lava lake, the mountain and the volcanoes (the
## landmark a short walk from it stays clear of them all); no small lava lake near it.
func _io_calm(c: Vector2i) -> bool:
	if Vector2(c - io.lake_centre()).length() < 120.0:
		return false
	if io.near_mountain(float(c.x), float(c.y), 80.0):
		return false
	if not io.vents_near(c.x, c.y, 80.0).is_empty() or io.patera_near(c.x, c.y, 64.0):
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		if not IoTerrain.is_plains(io_kind(c.x + d.x, c.y + d.y)):
			return false
	return true


## Titan: the landing pad on calm plains, a walk from the methane sea, north of the dunes, clear of the icy mountains and
## of every lake (the landmark a short walk from it stays clear of them all).
func _titan_calm(c: Vector2i) -> bool:
	var t := titan
	if Vector2(c - t.sea_centre()).length() < TitanTerrain.SEA_R + TitanTerrain.SEA_WOBBLE + TitanTerrain.BEACH \
			+ TitanTerrain.COAST + 90.0:
		return false
	if c.y > t.dune_edge() - 80 or t.near_mountain(float(c.x), float(c.y), 70.0) or t.lake_near(c.x, c.y, 64.0):
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		if not TitanTerrain.is_plains(titan_kind(c.x + d.x, c.y + d.y)):
			return false
	return true


## Spec §21c: a calm place for a colony whose Great Dome's middle is c. The Moon: anywhere (its craters are flattened
## under it). Mars: the plains (dry river beds may cross its blend) all round, clear of the volcano, the canyon, the caps
## and their frost (looked at every 8 blocks over the flat ground and its blend).
func _colony_calm(c: Vector2i) -> bool:
	if planet != MARS:
		return true
	var reach := ColonyLayout.R_FLAT + ColonyLayout.BLEND + 8
	for dz in range(-reach, reach + 1, 8):
		for dx in range(-reach, reach + 1, 8):
			if dx * dx + dz * dz > reach * reach:
				continue
			var k := mars.column(c.x + dx, c.y + dz, crater_depth(c.x + dx, c.y + dz)) & 15
			if k != MarsTerrain.PLAINS and k != MarsTerrain.VALLEY:
				return false
	return true


## Mercury: the landing pad on calm plains, a walk from every long cliff and big crater (the landmark a short walk from it
## and the thermometer by it stay clear of them all); no small crater on it.
func _mercury_calm(c: Vector2i) -> bool:
	var m := mercury
	if m.scarp_near(float(c.x), float(c.y), 90.0) or m.big_near(float(c.x), float(c.y), 70.0):
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		var p := c + d
		if m.small_crater_at(p.x, p.y) or not MercuryTerrain.is_plains(mercury_kind(p.x, p.y)):
			return false
	return true


## Pluto: the landing pad on calm uplands a walk west of the heart's plain, clear of the ice mountains and a walk east of
## the red-brown lands (the landmark a short walk from it and the lookout by it stay clear of them all).
func _pluto_calm(c: Vector2i) -> bool:
	var p := pluto
	if p.plain_sd(c.x, c.y) < 55.0 or p.near_mountain(float(c.x), float(c.y), 70.0):
		return false
	if float(c.x) - p.dark_edge(float(c.y)) < 70.0:
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		if not PlutoTerrain.is_plains(pluto_kind(c.x + d.x, c.y + d.y)):
			return false
	return true


## Triton: the landing pad on the calm band of frost, a walk north of the cap, clear of the cantaloupe terrain, the frozen
## lake and the crater (the landmark a short walk from it and the lookout by it stay clear of them all).
func _triton_calm(c: Vector2i) -> bool:
	if not triton.calm(c.x, c.y):
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		if not TritonTerrain.is_plains(triton_kind(c.x + d.x, c.y + d.y)):
			return false
	return true


## Ganymede: the landing pad on the smooth plain of bright ice, far from the dark terrain, the ray crater and the poles'
## frost (the lookout by it and the landmark a short walk from it stay on calm ground).
func _ganymede_calm(c: Vector2i) -> bool:
	if not ganymede.calm(c.x, c.y):
		return false
	for d: Vector2i in [Vector2i.ZERO, Vector2i(BLEND_RADIUS, 0), Vector2i(-BLEND_RADIUS, 0), Vector2i(0, BLEND_RADIUS),
			Vector2i(0, -BLEND_RADIUS), Vector2i(11, 11), Vector2i(-11, 11), Vector2i(11, -11), Vector2i(-11, -11)]:
		if not GanymedeTerrain.is_plains(ganymede_kind(c.x + d.x, c.y + d.y)):
			return false
	return true
