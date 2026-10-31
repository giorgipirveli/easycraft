class_name SpaceSecretRules
extends SecretRules
## Where the space worlds hide their secrets (owner feedback #55, spec §21.2), as pure rules on SpaceShape. The Secret
## Book's M2 kinds (buried treasure, hidden rooms, puzzle temples, geodes) are Green Meadows' own shapes built in the
## planet's blocks (PALETTES: each kind's Meadows blocks swapped for the planet's), and the planet's **landmark** is the
## world's one ISLAND secret (the Dragon Realm made ISLAND its nests the same way), a short walk from the landing pad:
## the Moon Base (a silver dome, its door toward the pad), the Boing Tower (bouncy pads spiralling up to a platform) or
## the Rainbow Arch (six stripes, steps up to its top), each with a golden chest (found by walking in, or up). No sky
## islands, no treasure pack and no mouse villages in space (ruling: their Meadows look would clash).
## Mars (cosmos, spec §21b.2): gypsum crystals mark buried treasure, the hidden room is an explorers' room of basalt
## behind a fake basalt door, the puzzle temple is an old lander (gold foil and rover panels: friendly and made up,
## never a real mission), the geodes are gypsum, and the landmark is a six-wheeled rover with its tracks behind it.
## Europa (cosmos, spec §21b.2): salt crystals mark buried treasure, the hidden room is deep ice behind a fake deep-ice
## door, the puzzle temple is the explorers' ice station (ice bricks: friendly and made up), the geodes are salt crystals
## deep in the seafloor rock, the landmark is the Ice Lander with its melt probe; no secret is built into the ocean well
## or a plume's mound (_fits).
## Io (cosmos, spec §21b.2): sulphur crystals mark buried treasure, the hidden room is a warm room of black lava rock
## (like a lava tube) behind a fake Io-rock door, lit by glowing lava crust, the puzzle temple is the explorers' station
## (sulphur bricks: friendly and made up), the geodes are sulphur crystals, the landmark is the Volcano Lander with its
## heat camera; no secret is built into the big lava lake or onto a volcano (_fits).
## Titan (cosmos, spec §21b.2): shore crystals mark buried treasure, the hidden room is an ice room of icy rock behind a
## fake icy-rock door, lit by shore crystals, the puzzle temple is the explorers' station (station bricks, probe lamps:
## friendly and made up), the geodes are shore crystals in the icy rock, the landmark is the Landing Probe with its
## parachute (a probe really landed on Titan, under a parachute; the game's is made up and named by no mission); no
## secret is built into the methane (a lake, the sea) or on their shores (_fits).
## Mercury (cosmos, spec §21b.2): ice crystals mark buried treasure, the hidden room is Mercury rock behind a fake rock
## door, the puzzle temple is the explorers' station (explorer bricks and lamps: friendly and made up), the geodes are ice
## crystals in the rock, the landmark is the Sunshade Lander with its big white sunshade on its sunny side (spacecraft
## really carry sunshades to Mercury; the game's lander is made up and named by no mission); no secret is built on a long
## cliff's face or into a big crater (_fits).
## Venus's cloud city (cosmos, spec §21b.2): every secret is drawn onto one of the city's platforms in its area
## (VenusTerrain.secret_spot) and held by it (VenusTerrain.holds: never on a bridge or over the clouds, never on the camp
## or show decks, clear of the built parts, a hull under what goes down into a deck): glowing cloud crystals mark buried
## treasure in a deck, the hidden room is in a float hull behind a fake hull door, the puzzle temple is the explorers'
## station (home panels, cloud lamps: friendly and made up), the geodes are cloud crystal inside a hull (never deep down:
## the clouds hold no rock), and the landmark is the Research Blimp moored at the airship dock (scientists have imagined
## airships in Venus's clouds and robot balloons really floated there; the game's blimp is made up and named by no
## mission).
## Saturn's rings (cosmos, spec §21b.2): every secret is drawn onto one of the big chunks in its area
## (RingsTerrain.secret_spot) and held by it (RingsTerrain.holds: never over open space, a lump or Pan, never on the
## camp's or show's chunk, clear of the built parts, the chunk's ice under what goes down into it): glowing ring crystals
## mark buried treasure, the hidden room is in the ice behind a fake ice door, the puzzle temple is the explorers'
## station (station panels and lamps: friendly and made up), the geodes are ring crystal inside a chunk, and the landmark
## is the Ring Explorer resting on its own chunk (a spacecraft really dived between Saturn and its rings 22 times; the
## game's is made up and named by no mission).
## Pluto (cosmos, spec §21b.2): glowing frost crystals mark buried treasure, the hidden room is water ice (as hard as rock
## at Pluto's cold) behind a fake water-ice door, lit by frost crystals, the puzzle temple is the explorers' station (frost
## bricks, warm lamps: friendly and made up), the geodes are frost crystals in the water ice, the landmark is the Balloon
## Lander with its drag balloon spread out behind it (scientists have studied landing on Pluto slowed by a giant balloon
## in its thin air; the game's lander is made up and named by no mission); no secret is built on the ice mountains or
## among the plain's floating hills (_fits).
## Triton (cosmos, spec §21b.2): glowing nitrogen crystals mark buried treasure, the hidden room is pink ice behind a fake
## pink-ice door, lit by nitrogen crystals, the puzzle temple is the explorers' station (pale pink cap bricks, blue
## beacons: friendly and made up), the geodes are nitrogen crystals in the water ice, the landmark is the Hopper Lander
## (its white tank of nitrogen, a rocket nozzle underneath, a scoop arm, the scorched rings of its last hops behind it:
## scientists have designed a lander that hops across Triton on its own nitrogen ice, heated into rocket fuel; the game's
## is made up and named by no mission); no secret is built on the frozen lake, the crater or a geyser (_fits).
## Ganymede (cosmos, spec §21b.2): glowing aurora crystals mark buried treasure, the hidden room is grooved ice behind a
## fake grooved-ice door, lit by aurora crystals, the puzzle temple is the explorers' station (pale groove bricks, aurora
## lamps: friendly and made up), the geodes are aurora crystals in the water ice, the landmark is the Solar Wing Lander
## (two giant solar wings: sunlight out at Jupiter is about 25 times weaker than at Earth, so a real spacecraft on its way
## there carries huge ones; a magnetometer on a long boom; the game's lander is made up and named by no mission); no
## secret is built on the ray crater or a built part (the Jupiter Lookout, the Aurora Watch, the ocean drill: _fits).

const ATTEMPTS_SPACE := [[TREASURE, 0.8], [TREASURE, 0.5], [ROOM, 0.6], [TEMPLE, 0.35], [GEODE, 0.5]]
const LANDMARK_DISTANCE := Vector2i(44, 56)   # blocks from the spawn
const LANDMARK_MARGIN := 14                   # the landmark keeps this far inside its area
const DOME_RADIUS := 6

## planet -> {kind or &"all": {Meadows block: the planet's}} (a kind's own map first, then &"all").
const PALETTES := {
	SpaceShape.MOON: {
		&"all": {BlockIds.STONE: BlockIds.MOON_ROCK, BlockIds.PLANKS: BlockIds.BASE_PANEL,
			BlockIds.BRICK: BlockIds.MOON_ROCK, BlockIds.LIGHT: BlockIds.BASE_LIGHT, BlockIds.FAKE_WALL: BlockIds.FAKE_MOON_ROCK,
			BlockIds.SAND: BlockIds.MOON_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.MOON_CRYSTAL,
			BlockIds.GRASS: BlockIds.MOON_DUST, BlockIds.DIRT: BlockIds.MOON_ROCK},
		ROOM: {BlockIds.STONE: BlockIds.MOON_CHEESE},   # the Moon IS made of cheese
		TEMPLE: {BlockIds.STONE: BlockIds.BASE_PANEL},  # a silver star temple
	},
	SpaceShape.BOING: {
		&"all": {BlockIds.STONE: BlockIds.BOING_ROCK, BlockIds.PLANKS: BlockIds.BOING_BRICK,
			BlockIds.BRICK: BlockIds.BOING_BRICK, BlockIds.LIGHT: BlockIds.BOING_GLOW, BlockIds.FAKE_WALL: BlockIds.FAKE_BOING_ROCK,
			BlockIds.SAND: BlockIds.SPRING_CAP, BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.BOING_GLOW,
			BlockIds.GRASS: BlockIds.BOING_MOSS, BlockIds.DIRT: BlockIds.BOING_SOIL},
		TEMPLE: {BlockIds.STONE: BlockIds.BOING_BRICK},
	},
	SpaceShape.RAINBOW: {
		&"all": {BlockIds.STONE: BlockIds.RAINBOW_BLUE, BlockIds.PLANKS: BlockIds.PRISM_BRICK,
			BlockIds.BRICK: BlockIds.PRISM_BRICK, BlockIds.LIGHT: BlockIds.PRISM_LAMP, BlockIds.FAKE_WALL: BlockIds.FAKE_RAINBOW,
			BlockIds.SAND: BlockIds.PRISM_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.PRISM_CRYSTAL,
			BlockIds.GRASS: BlockIds.PRISM_GRASS, BlockIds.DIRT: BlockIds.RAINBOW_RED},
		TEMPLE: {BlockIds.STONE: BlockIds.PRISM_BRICK},
	},
	SpaceShape.MARS: {
		&"all": {BlockIds.STONE: BlockIds.BASALT, BlockIds.PLANKS: BlockIds.ROVER_PANEL,
			BlockIds.BRICK: BlockIds.ROVER_PANEL, BlockIds.LIGHT: BlockIds.ROVER_LIGHT, BlockIds.FAKE_WALL: BlockIds.FAKE_BASALT,
			BlockIds.SAND: BlockIds.GYPSUM, BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.GYPSUM,
			BlockIds.GRASS: BlockIds.MARS_DUST, BlockIds.DIRT: BlockIds.MARS_REGOLITH},
		TEMPLE: {BlockIds.STONE: BlockIds.LANDER_FOIL},   # an old lander of gold foil and white panels
	},
	SpaceShape.EUROPA: {
		&"all": {BlockIds.STONE: BlockIds.DEEP_ICE, BlockIds.PLANKS: BlockIds.ICE_BRICK,
			BlockIds.BRICK: BlockIds.ICE_BRICK, BlockIds.LIGHT: BlockIds.GLOW_ICE, BlockIds.FAKE_WALL: BlockIds.FAKE_DEEP_ICE,
			BlockIds.SAND: BlockIds.SALT, BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.SALT,
			BlockIds.GRASS: BlockIds.EUROPA_ICE, BlockIds.DIRT: BlockIds.EUROPA_ICE},
		TEMPLE: {BlockIds.STONE: BlockIds.ICE_BRICK, BlockIds.LIGHT: BlockIds.PROBE_LIGHT},   # the explorers' ice station
		GEODE: {BlockIds.STONE: BlockIds.EUROPA_ROCK},   # deep in the seafloor rock
	},
	SpaceShape.IO: {
		&"all": {BlockIds.STONE: BlockIds.IO_ROCK, BlockIds.PLANKS: BlockIds.HEAT_TILE,
			BlockIds.BRICK: BlockIds.SULPHUR_BRICK, BlockIds.LIGHT: BlockIds.HEAT_CAMERA, BlockIds.FAKE_WALL: BlockIds.FAKE_IO_ROCK,
			BlockIds.SAND: BlockIds.SULPHUR_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.SULPHUR_CRYSTAL,
			BlockIds.GRASS: BlockIds.SULPHUR, BlockIds.DIRT: BlockIds.IO_ROCK},
		ROOM: {BlockIds.STONE: BlockIds.BLACK_LAVA, BlockIds.LIGHT: BlockIds.LAVA_CRUST},   # a warm room, like a lava tube
		TEMPLE: {BlockIds.STONE: BlockIds.SULPHUR_BRICK},   # the explorers' station
	},
	SpaceShape.TITAN: {
		&"all": {BlockIds.STONE: BlockIds.ICY_ROCK, BlockIds.PLANKS: BlockIds.TITAN_BRICK,
			BlockIds.BRICK: BlockIds.TITAN_BRICK, BlockIds.LIGHT: BlockIds.PROBE_LAMP, BlockIds.FAKE_WALL: BlockIds.FAKE_ICY_ROCK,
			BlockIds.SAND: BlockIds.SHORE_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.SHORE_CRYSTAL,
			BlockIds.GRASS: BlockIds.TITAN_SOIL, BlockIds.DIRT: BlockIds.TITAN_SOIL},
		ROOM: {BlockIds.LIGHT: BlockIds.SHORE_CRYSTAL},   # an ice room lit by glowing shore crystals
		TEMPLE: {BlockIds.STONE: BlockIds.TITAN_BRICK},   # the explorers' station
	},
	SpaceShape.MERCURY: {
		&"all": {BlockIds.STONE: BlockIds.MERCURY_ROCK, BlockIds.PLANKS: BlockIds.HEAT_BLANKET,
			BlockIds.BRICK: BlockIds.EXPLORER_BRICK, BlockIds.LIGHT: BlockIds.EXPLORER_LAMP,
			BlockIds.FAKE_WALL: BlockIds.FAKE_MERCURY_ROCK, BlockIds.SAND: BlockIds.ICE_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD,
			BlockIds.CRYSTAL: BlockIds.ICE_CRYSTAL, BlockIds.GRASS: BlockIds.MERCURY_DUST, BlockIds.DIRT: BlockIds.MERCURY_ROCK},
		TEMPLE: {BlockIds.STONE: BlockIds.EXPLORER_BRICK},   # the explorers' station
	},
	SpaceShape.VENUS: {
		&"all": {BlockIds.STONE: BlockIds.FLOAT_HULL, BlockIds.PLANKS: BlockIds.CLOUD_DECK,
			BlockIds.BRICK: BlockIds.HOME_PANEL, BlockIds.LIGHT: BlockIds.CLOUD_LAMP,
			BlockIds.FAKE_WALL: BlockIds.FAKE_FLOAT_HULL, BlockIds.SAND: BlockIds.CLOUD_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD,
			BlockIds.CRYSTAL: BlockIds.CLOUD_CRYSTAL, BlockIds.GRASS: BlockIds.CLOUD_DECK, BlockIds.DIRT: BlockIds.FLOAT_HULL},
		TEMPLE: {BlockIds.STONE: BlockIds.HOME_PANEL},   # the explorers' station
	},
	SpaceShape.RINGS: {
		&"all": {BlockIds.STONE: BlockIds.RING_ICE, BlockIds.PLANKS: BlockIds.STATION_PANEL,
			BlockIds.BRICK: BlockIds.STATION_PANEL, BlockIds.LIGHT: BlockIds.STATION_LAMP,
			BlockIds.FAKE_WALL: BlockIds.FAKE_RING_ICE, BlockIds.SAND: BlockIds.RING_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD,
			BlockIds.CRYSTAL: BlockIds.RING_CRYSTAL, BlockIds.GRASS: BlockIds.RING_FROST, BlockIds.DIRT: BlockIds.RING_ICE},
		TEMPLE: {BlockIds.STONE: BlockIds.STATION_PANEL},   # the explorers' station
	},
	SpaceShape.PLUTO: {
		&"all": {BlockIds.STONE: BlockIds.WATER_ICE, BlockIds.PLANKS: BlockIds.FROST_BRICK,
			BlockIds.BRICK: BlockIds.FROST_BRICK, BlockIds.LIGHT: BlockIds.STATION_LAMP,
			BlockIds.FAKE_WALL: BlockIds.FAKE_WATER_ICE, BlockIds.SAND: BlockIds.FROST_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD,
			BlockIds.CRYSTAL: BlockIds.FROST_CRYSTAL, BlockIds.GRASS: BlockIds.PLUTO_FROST, BlockIds.DIRT: BlockIds.WATER_ICE},
		ROOM: {BlockIds.LIGHT: BlockIds.FROST_CRYSTAL},   # a water-ice room lit by glowing frost crystals
		TEMPLE: {BlockIds.STONE: BlockIds.FROST_BRICK},   # the explorers' station
	},
	SpaceShape.TRITON: {
		&"all": {BlockIds.STONE: BlockIds.WATER_ICE, BlockIds.PLANKS: BlockIds.CAP_BRICK,
			BlockIds.BRICK: BlockIds.CAP_BRICK, BlockIds.LIGHT: BlockIds.STATION_LAMP,
			BlockIds.FAKE_WALL: BlockIds.FAKE_PINK_ICE, BlockIds.SAND: BlockIds.NITROGEN_CRYSTAL, BlockIds.GOLD: BlockIds.STAR_GOLD,
			BlockIds.CRYSTAL: BlockIds.NITROGEN_CRYSTAL, BlockIds.GRASS: BlockIds.TRITON_FROST, BlockIds.DIRT: BlockIds.NITROGEN_ICE},
		ROOM: {BlockIds.STONE: BlockIds.PINK_ICE, BlockIds.LIGHT: BlockIds.NITROGEN_CRYSTAL},   # a pink-ice room, crystal-lit
		TEMPLE: {BlockIds.STONE: BlockIds.CAP_BRICK, BlockIds.LIGHT: BlockIds.BLUE_BEACON},   # the explorers' station
	},
	SpaceShape.GANYMEDE: {
		&"all": {BlockIds.STONE: BlockIds.WATER_ICE, BlockIds.PLANKS: BlockIds.GROOVE_BRICK,
			BlockIds.BRICK: BlockIds.GROOVE_BRICK, BlockIds.LIGHT: BlockIds.STATION_LAMP,
			BlockIds.FAKE_WALL: BlockIds.FAKE_GROOVED_ICE, BlockIds.SAND: BlockIds.AURORA_CRYSTAL,
			BlockIds.GOLD: BlockIds.STAR_GOLD, BlockIds.CRYSTAL: BlockIds.AURORA_CRYSTAL,
			BlockIds.GRASS: BlockIds.GROOVED_ICE, BlockIds.DIRT: BlockIds.GROOVED_ICE},
		ROOM: {BlockIds.STONE: BlockIds.GROOVED_ICE, BlockIds.LIGHT: BlockIds.AURORA_CRYSTAL},   # grooved ice, crystal-lit
		TEMPLE: {BlockIds.STONE: BlockIds.GROOVE_BRICK, BlockIds.LIGHT: BlockIds.AURORA_LAMP},   # the explorers' station
	},
}
const TOWER := 14                              # the Boing Tower's platform above its foot
const ARCH := 11                               # the Rainbow Arch's outer (red) radius
const TRACKS := Vector2i(7, 12)                # the rover's tracks run this far behind its middle
const SUNNY := Vector3i(0, 0, 1)               # Mercury: the sunshade's side, where the Sun is at noon (DayCycle.TILT: +z)
## Venus: the big secrets first (a platform holds only a few), and how far inside its platform's rim each kind is drawn
## (VenusTerrain.secret_spot: the rooms and geodes near a hull's deep middle).
const ATTEMPTS_VENUS := [[TEMPLE, 0.45], [ROOM, 0.7], [GEODE, 0.6], [TREASURE, 0.8], [TREASURE, 0.5]]
const VENUS_INNER := {TREASURE: 4, ROOM: 10, TEMPLE: 8, GEODE: 9}
const GEODE_R := 4                             # Venus: a cloud crystal geode's radius, in a hull
const HULL_ROOM_DEPTH := 6                     # Venus: a hidden room's floor this far under the deck (in its hull)
## Venus: the Research Blimp beside the dock (along the dock's way out from the pad: VenusTerrain.north()).
const GANGWAY := 5                             # the gangway's length from the dock's rim to the gondola's door
const GONDOLA_HALF := Vector2i(3, 2)           # the gondola: 7 long (east-west), 5 deep
const ENVELOPE := Vector3(12.5, 5.5, 5.5)      # the envelope's half length, half height and half width
const ENVELOPE_UP := 11                        # its middle this far over the gondola's floor
## Saturn's rings: the big secrets first (a chunk holds only a few), and how far inside its chunk's rim each kind is drawn
## (RingsTerrain.secret_spot: the rooms and geodes near a chunk's deep middle).
const ATTEMPTS_RINGS := [[TEMPLE, 0.45], [ROOM, 0.7], [GEODE, 0.6], [TREASURE, 0.8], [TREASURE, 0.5]]
const RINGS_INNER := {TREASURE: 3, ROOM: 8, TEMPLE: 7, GEODE: 8}
const RING_GEODE_R := 3                        # the rings: a ring crystal geode's radius, in a chunk
## The Ring Explorer's dish: its radius, on a truss over the body's roof.
const DISH_R := 3
const BOOM := 9                                # its boom reaches this far out from the body
## Pluto: the Balloon Lander's drag balloon, spread out on the ground behind it (its radius, how far behind its middle).
const BALLOON_R := 6
const BALLOON_BACK := 11
## Triton: the Hopper Lander's last hops, scorched rings on the ground behind it (how far behind its middle, their radius).
const HOPS: Array[int] = [-8, -13]
const HOP_R := 1.6
## Ganymede: the Solar Wing Lander's wings, out to both sides (from, to: blocks sideways from its middle; half their
## length along it), and its magnetometer's boom out of its back.
const WING := Vector2i(6, 11)
const WING_HALF := 2
const BOOM_OUT := 8

var space: SpaceShape
var _landmark := {}


func _init(world_seed: int, terrain: MeadowsShape = null) -> void:
	space = terrain as SpaceShape if terrain is SpaceShape else SpaceShape.new(world_seed)
	super(world_seed, space, false, false)
	_landmark = _make_landmark()


func _attempts() -> Array:
	if space.rings != null:
		return ATTEMPTS_RINGS
	return ATTEMPTS_VENUS if space.venus != null else ATTEMPTS_SPACE


func _build(kind: StringName, x: int, z: int, v: int) -> Dictionary:
	if space.rings != null:   # onto one of the big chunks in its area
		var at := space.rings.secret_spot(area_of(x, z), v, int(RINGS_INNER.get(kind, 3)))
		if at == RingsTerrain.NONE:
			return {}
		x = at.x
		z = at.y
		if kind == GEODE or kind == ROOM:
			var mine := _ring_geode(x, z, v) if kind == GEODE else _hull_room(x, z, v)
			if not mine.is_empty():
				_paint(mine, kind)
			return mine
	if space.venus != null:   # onto one of the city's platforms in its area
		var spot := space.venus.secret_spot(area_of(x, z), v, int(VENUS_INNER.get(kind, 4)))
		if spot == VenusTerrain.NONE:
			return {}
		x = spot.x
		z = spot.y
		if kind == GEODE or kind == ROOM:
			var own := _cloud_geode(x, z, v) if kind == GEODE else _hull_room(x, z, v)
			if not own.is_empty():
				_paint(own, kind)
			return own
	var s := super(kind, x, z, v)
	if not s.is_empty():
		_paint(s, kind)
	return s


## The planet's landmark (the world's one ISLAND secret): {id, kind, anchor, chest, chest_kind, inside, dir, boxes, lo,
## hi, area, name}.
func landmark() -> Dictionary:
	return _landmark


func _place(area: Vector2i) -> Array:
	var out := super(area)
	if _landmark.is_empty() or _landmark.area != area:
		return out
	var kept: Array = []
	for s: Dictionary in out:
		if not _touches(s, _landmark):
			kept.append(s)   # the landmark wins its place
	kept.append(_landmark)
	return kept


## Inside its own area, clear of the spawn, the others and a colony's ground (spec §21c), and on Europa clear of the
## ocean well and the plumes' mounds
## (a room dug into the well's wall or a temple on a vent would spoil both); on Io clear of the big lava lake and the
## volcanoes' cones; on Titan clear of the methane and its shores; on Mercury clear of the long cliffs' faces and the
## big craters.
func _fits(s: Dictionary, area: Vector2i, others: Array) -> bool:
	if not super(s, area, others):
		return false
	if space.colony != null and space.colony.near_box(s.lo, s.hi, GAP):   # spec §21c: off the colony's ground
		return false
	if space.io != null:
		return _io_fits(s.lo, s.hi)
	if space.titan != null:
		return _titan_fits(s.lo, s.hi)
	if space.mercury != null:
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		var half := Vector2(hi.x - lo.x, hi.z - lo.z).length() * 0.5 + 2.0
		return not space.mercury.steep_near((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5, half)
	if space.pluto != null:   # off the ice mountains and the plain's floating hills
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		var half := Vector2(hi.x - lo.x, hi.z - lo.z).length() * 0.5 + 2.0
		return not space.pluto.steep_near((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5, half)
	if space.triton != null:   # off the frozen lake, the crater and the geysers
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		var half := Vector2(hi.x - lo.x, hi.z - lo.z).length() * 0.5 + 2.0
		return not space.triton.steep_near((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5, half)
	if space.ganymede != null:   # off the ray crater and the built parts
		var lo: Vector3i = s.lo
		var hi: Vector3i = s.hi
		var half := Vector2(hi.x - lo.x, hi.z - lo.z).length() * 0.5 + 2.0
		return not space.ganymede.steep_near((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5, half)
	if space.venus != null:   # held by a platform; a hidden room's stairs come up through its deck
		if s.has("stairs_top") and (s.stairs_top as Vector3i).y != VenusTerrain.DECK_Y - 1:
			return false
		return space.venus.holds(s.boxes, s.lo, s.hi, GAP)
	if space.rings != null:   # held by a chunk; a hidden room's stairs come up through its top
		if s.has("stairs_top"):
			var st: Vector3i = s.stairs_top
			if st.y != space.height_at(st.x, st.z) - 1:
				return false
		return space.rings.holds(s.boxes, s.lo, s.hi, GAP)
	if space.europa == null:
		return true
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	var e := space.europa
	var wc := e.well_centre()
	if _gap(lo, hi, wc) <= EuropaTerrain.BELL + GAP:
		return false
	for v: Vector2i in e.vents_near((lo.x + hi.x) / 2, (lo.z + hi.z) / 2, AREA):
		if _gap(lo, hi, v) <= EuropaTerrain.MOUND_R + GAP:
			return false
	return true


## Io: a secret's box [lo, hi) keeps clear of the big lava lake (its rim and moat) and every volcano's cone and skirt.
func _io_fits(lo: Vector3i, hi: Vector3i) -> bool:
	var io := space.io
	if _gap(lo, hi, io.lake_centre()) <= IoTerrain.LAKE_R + IoTerrain.RIM_W + GAP:
		return false
	for v: Vector2i in io.vents_near((lo.x + hi.x) / 2, (lo.z + hi.z) / 2, AREA):
		if _gap(lo, hi, v) <= IoTerrain.CONE_R + IoTerrain.SKIRT + GAP:
			return false
	return true


## Titan: a secret's box [lo, hi) and the ring of columns round it keep off the methane (a lake's or the sea's bed) and
## their shores. Only a box near a basin looks at its columns one by one.
func _titan_fits(lo: Vector3i, hi: Vector3i) -> bool:
	var t := space.titan
	var mid := Vector2((lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5)
	var half := Vector2(hi.x - lo.x, hi.z - lo.z).length() * 0.5 + 2.0
	var sea := TitanTerrain.SEA_R + TitanTerrain.SEA_WOBBLE + TitanTerrain.BEACH + TitanTerrain.COAST + half
	if mid.distance_to(Vector2(t.sea_centre())) >= sea and not t.lake_near(roundi(mid.x), roundi(mid.y), half):
		return true
	for z in range(lo.z - 1, hi.z + 1):
		for x in range(lo.x - 1, hi.x + 1):
			var k := t.column(x, z) & 15
			if TitanTerrain.is_bed(k) or TitanTerrain.is_shore(k):
				return false
	return true


## How far column p is from a secret's box [lo, hi) sideways (0 inside it).
static func _gap(lo: Vector3i, hi: Vector3i, p: Vector2i) -> float:
	return Vector2(clampi(p.x, lo.x, hi.x - 1) - p.x, clampi(p.y, lo.z, hi.z - 1) - p.y).length()


## Swaps a secret's Meadows blocks for the planet's.
func _paint(s: Dictionary, kind: StringName) -> void:
	var p: Dictionary = PALETTES.get(space.planet, PALETTES[SpaceShape.MOON])
	var own: Dictionary = p.get(kind, {})
	var all: Dictionary = p.get(&"all", {})
	for b: Array in s.boxes:
		var id: int = b[2]
		if own.has(id):
			b[2] = own[id]
		elif all.has(id):
			b[2] = all[id]


static func _touches(a: Dictionary, b: Dictionary) -> bool:
	var alo: Vector3i = a.lo
	var ahi: Vector3i = a.hi
	var blo: Vector3i = b.lo
	var bhi: Vector3i = b.hi
	return alo.x - GAP < bhi.x and blo.x < ahi.x + GAP and alo.z - GAP < bhi.z and blo.z < ahi.z + GAP


# --- The landmark ------------------------------------------------------------------------------------------

func _make_landmark() -> Dictionary:
	if space.rings != null:   # resting on its own chunk: where it is is the rings'
		var probe := _ring_explorer()
		var anchor: Vector3i = probe.anchor
		_finish(probe, ISLAND, area_of(anchor.x, anchor.z), 99)
		return probe
	if space.venus != null:   # moored at the dock: where it is is the city's
		var blimp := _research_blimp()
		var anchor: Vector3i = blimp.anchor
		_finish(blimp, ISLAND, area_of(anchor.x, anchor.z), 99)
		return blimp
	var sp := space.spawn_column()
	var h := absi(_mix(sp.x + 101, sp.y - 77))
	var dist := LANDMARK_DISTANCE.x + (h >> 12) % (LANDMARK_DISTANCE.y - LANDMARK_DISTANCE.x + 1)
	var c := Vector2i.ZERO
	for i in 24:   # the drawn way round first; the first spot well inside its own area
		var a := float(h % 3600) / 3600.0 * TAU + i * TAU / 24.0
		c = Vector2i(roundi(sp.x + cos(a) * dist), roundi(sp.y + sin(a) * dist))
		var inner := Vector2i(posmod(c.x, AREA), posmod(c.y, AREA))
		var clear := space.colony == null or Vector2(c - space.colony.centre).length() \
			> ColonyLayout.R_FLAT + ColonyLayout.BLEND + LANDMARK_MARGIN   # spec §21c: clear of the colony
		if inner.x >= LANDMARK_MARGIN and inner.y >= LANDMARK_MARGIN and inner.x < AREA - LANDMARK_MARGIN \
				and inner.y < AREA - LANDMARK_MARGIN and clear:
			break
	var area := area_of(c.x, c.y)
	var a0 := area * AREA
	c = c.clamp(a0 + Vector2i(LANDMARK_MARGIN, LANDMARK_MARGIN), a0 + Vector2i(AREA - LANDMARK_MARGIN - 1, AREA - LANDMARK_MARGIN - 1))
	var to_pad := Vector2(sp.x - c.x, sp.y - c.y)
	var dir := Vector3i(signi(roundi(to_pad.x)), 0, 0) if absf(to_pad.x) >= absf(to_pad.y) else Vector3i(0, 0, signi(roundi(to_pad.y)))
	var s: Dictionary
	match space.planet:
		SpaceShape.BOING:
			s = _boing_tower(c, dir)
		SpaceShape.RAINBOW:
			s = _rainbow_arch(c, dir)
		SpaceShape.MARS:
			s = _mars_rover(c, dir)
		SpaceShape.EUROPA:
			s = _ice_lander(c, dir)
		SpaceShape.IO:
			s = _volcano_lander(c, dir)
		SpaceShape.TITAN:
			s = _landing_probe(c, dir)
		SpaceShape.MERCURY:
			s = _sunshade_lander(c, dir)
		SpaceShape.PLUTO:
			s = _balloon_lander(c, dir)
		SpaceShape.TRITON:
			s = _hopper_lander(c, dir)
		SpaceShape.GANYMEDE:
			s = _solar_wing_lander(c, dir)
		_:
			s = _moon_base(c, dir)
	_finish(s, ISLAND, area, 99)
	return s


## The lowest and highest ground over `points` round c (offsets).
func _ground_span(c: Vector2i, points: Array) -> Vector2i:
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for d: Vector2i in points:
		var gh := space.height_at(c.x + d.x, c.y + d.y)
		lo = mini(lo, gh)
		hi = maxi(hi, gh)
	return Vector2i(lo, hi)


## The Boing Tower: a spring stalk on a brick plinth, four bouncy spring-cap pads spiralling up round it (3 blocks
## apart: jump and bounce from one to the next), a brick platform on top with glowing bulbs at its corners and a
## golden chest in the middle.
func _boing_tower(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var span := _ground_span(c2, [Vector2i.ZERO, Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3),
		Vector2i(3, 3), Vector2i(-3, 3), Vector2i(3, -3), Vector2i(-3, -3)])
	var c := Vector3i(c2.x, span.y, c2.y)
	var side := Vector3i(-dir.z, 0, dir.x)
	var boxes: Array = []
	_box(boxes, c + Vector3i(-3, span.x - c.y - 2, -3), c + Vector3i(3, -2, 3), BlockIds.BOING_ROCK)   # foundation
	_box(boxes, c + Vector3i(-3, -1, -3), c + Vector3i(3, -1, 3), BlockIds.BOING_BRICK)                 # the plinth
	_box(boxes, c + Vector3i(-3, 0, -3), c + Vector3i(3, TOWER + 3, 3), BlockIds.AIR)                    # room round it
	_box(boxes, c, c + Vector3i(0, TOWER - 1, 0), BlockIds.SPRING_STEM)
	var turns: Array[Vector3i] = [dir, side, -dir, -side]
	for i in 4:
		var pad := c + turns[i] * 2 + Vector3i(0, 2 + 3 * i, 0)
		_box(boxes, pad - Vector3i(1, 0, 1), pad + Vector3i(1, 0, 1), BlockIds.SPRING_CAP)
	_box(boxes, c + Vector3i(-2, TOWER, -2), c + Vector3i(2, TOWER, 2), BlockIds.BOING_BRICK)
	for d: Vector3i in [Vector3i(-2, 0, -2), Vector3i(2, 0, -2), Vector3i(-2, 0, 2), Vector3i(2, 0, 2)]:
		_box(boxes, c + d + Vector3i(0, TOWER + 1, 0), c + d + Vector3i(0, TOWER + 1, 0), BlockIds.BOING_GLOW)
	var chest := c + Vector3i(0, TOWER + 1, 0)
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(-dir), "dir": dir, "boxes": boxes,
		"inside": [c + Vector3i(-2, TOWER + 1, -2), c + Vector3i(3, TOWER + 4, 3)], "name": "Boing Tower"}


## The Rainbow Arch: six rings of the rainbow's stripes (red outside) standing on the terraces, two blocks thick, facing
## the landing pad; a flight of prism-brick steps up one side to the golden chest on its top; prism lamps at its feet.
func _rainbow_arch(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in range(-ARCH - 1, ARCH + 2, 4):
		samples.append(Vector2i(side.x * a, side.z * a))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, t: int, y: int) -> Vector3i: return c + side * a - dir * t + Vector3i(0, y, 0)
	var boxes: Array = []
	for a0: int in [-ARCH - 1, ARCH - 5]:   # a brick foundation under each leg
		_box(boxes, at.call(a0, -1, span.x - c.y - 2), at.call(a0 + 6, 1, -1), BlockIds.PRISM_BRICK)
	for k in RainbowBlocks.STRIPES.size():
		var r := ARCH - k
		for y in range(0, r + 1):
			for a in range(-r, r + 1):
				if roundi(sqrt(float(a * a + y * y))) == r:
					_box(boxes, at.call(a, 0, y), at.call(a, 1, y), RainbowBlocks.STRIPES[k])
	for i in ARCH + 1:   # the steps: from beside the red leg's foot up to the top
		var step: Vector3i = at.call(-ARCH - 1 + i, -1, 1 + i)
		_box(boxes, step, step, BlockIds.PRISM_BRICK)
	for a: int in [-ARCH - 1, ARCH + 1]:
		_box(boxes, at.call(a, 0, 0), at.call(a, 0, 1), BlockIds.PRISM_LAMP)
	var chest: Vector3i = at.call(0, 0, ARCH + 1)
	_box(boxes, chest, chest + Vector3i(0, 2, 0), BlockIds.AIR)
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [c + Vector3i(-2, ARCH + 1, -2), c + Vector3i(3, ARCH + 5, 3)], "name": "Rainbow Arch"}


## The Mars Rover (Mars's landmark, like the real ones: six wheels, a deck of solar panels, a camera mast), facing the
## landing pad: rocker arms over its wheels, a white body, the deck on top with a golden chest (climb up the wheels:
## each step is one Mars jump), the mast's head with two glowing camera eyes, an antenna, and two lines of wheel
## tracks in the dust behind it. It stands on a foundation where the ground dips.
func _mars_rover(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [-5, 0, 5]:
		for b in [-4, 0, 4]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, y: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, y, 0)
	var boxes: Array = []
	_box(boxes, at.call(-5, -4, span.x - c.y - 2), at.call(5, 4, -2), BlockIds.MARS_REGOLITH)   # foundation ...
	_box(boxes, at.call(-5, -4, -1), at.call(5, 4, -1), BlockIds.MARS_DUST)                     # ... dusty on top
	_box(boxes, at.call(-6, -5, 0), at.call(6, 5, 9), BlockIds.AIR)                             # room round it
	for a: int in [-4, -1, 2]:   # six wheels, two long and two tall
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a + 1, b, 1), BlockIds.ROVER_WHEEL)
	for b: int in [-3, 3]:
		_box(boxes, at.call(-4, b, 2), at.call(3, b, 2), BlockIds.ROVER_PANEL)   # the rocker arms over the wheels
	_box(boxes, at.call(-3, -2, 2), at.call(2, 2, 3), BlockIds.ROVER_PANEL)       # the body
	_box(boxes, at.call(-4, -3, 4), at.call(3, 3, 4), BlockIds.SOLAR_PANEL)       # the deck
	_box(boxes, at.call(2, 0, 5), at.call(2, 0, 7), BlockIds.ROVER_PANEL)         # the mast ...
	_box(boxes, at.call(2, -1, 8), at.call(2, 1, 8), BlockIds.ROVER_PANEL)        # ... its head ...
	for b: int in [-1, 1]:
		var eye: Vector3i = at.call(3, b, 8)
		_box(boxes, eye, eye, BlockIds.ROVER_LIGHT)                               # ... and its two eyes, forward
	_box(boxes, at.call(-3, 2, 5), at.call(-3, 2, 6), BlockIds.ROVER_PANEL)       # the antenna
	for k in range(TRACKS.x, TRACKS.y + 1):   # the tracks behind it, in each column's dust
		for b: int in [-3, 3]:
			var p: Vector3i = at.call(-k, b, 0)
			var g := space.height_at(p.x, p.z)
			_box(boxes, Vector3i(p.x, g - 1, p.z), Vector3i(p.x, g - 1, p.z), BlockIds.MARS_REGOLITH)
	var chest: Vector3i = at.call(-1, 0, 5)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-4, -3, 5).min(at.call(3, 3, 5)), at.call(-4, -3, 5).max(at.call(3, 3, 5)) + Vector3i(1, 4, 1)],
		"name": "Mars Rover"}


## The Ice Lander (Europa's landmark; real scientists design landers whose probe melts down through the ice to the
## ocean, spec §21b.2: "a lander", never a mission's name), facing the landing pad: four legs of metal, a white body with
## lights at its corners and an antenna, the golden chest on its deck (one Europa jump up, or the two steps on its
## front), and under it the melt probe going down into a hole in the ice that glows blue. It stands on a foundation of
## deep ice where the ground dips.
func _ice_lander(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [-5, 0, 5]:
		for b in [-5, 0, 5]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, y: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, y, 0)
	var boxes: Array = []
	_box(boxes, at.call(-5, -5, span.x - c.y - 2), at.call(5, 5, -2), BlockIds.DEEP_ICE)   # foundation ...
	_box(boxes, at.call(-5, -5, -1), at.call(5, 5, -1), BlockIds.EUROPA_ICE)                # ... level ice on top
	_box(boxes, at.call(-6, -6, 0), at.call(6, 6, 11), BlockIds.AIR)                        # room round it
	_box(boxes, at.call(-1, -1, -1), at.call(1, 1, -1), BlockIds.GLOW_ICE)                  # the melt hole glows ...
	_box(boxes, at.call(0, 0, -6), at.call(0, 0, 2), BlockIds.MELT_PROBE)                   # ... round the probe
	for a: int in [-3, 3]:   # four legs
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a, b, 2), BlockIds.MELT_PROBE)
	_box(boxes, at.call(-3, -3, 3), at.call(3, 3, 5), BlockIds.PROBE_PANEL)                 # the body and its deck
	for a: int in [-3, 3]:   # a light on each corner of the deck
		for b: int in [-3, 3]:
			var lamp: Vector3i = at.call(a, b, 6)
			_box(boxes, lamp, lamp, BlockIds.PROBE_LIGHT)
	_box(boxes, at.call(-2, 2, 6), at.call(-2, 2, 8), BlockIds.PROBE_PANEL)                 # the antenna ...
	var tip: Vector3i = at.call(-2, 2, 9)
	_box(boxes, tip, tip, BlockIds.PROBE_LIGHT)                                             # ... and its light
	_box(boxes, at.call(5, -1, 0), at.call(5, 1, 0), BlockIds.PROBE_PANEL)                  # two steps up its front
	_box(boxes, at.call(4, -1, 0), at.call(4, 1, 2), BlockIds.PROBE_PANEL)
	var chest: Vector3i = at.call(0, 0, 6)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-3, -3, 6).min(at.call(3, 3, 6)), at.call(-3, -3, 6).max(at.call(3, 3, 6)) + Vector3i(1, 4, 1)],
		"name": "Ice Lander"}


## The Volcano Lander (Io's landmark; spacecraft watch Io's volcanoes with heat cameras, spec §21b.2: "a lander", never
## a mission's name), facing the landing pad: four metal legs, a body of white heat tiles with lights at its deck's
## corners, the golden chest on its deck (one Io jump up, or the two steps on its front), a mast with the heat camera
## looking out the way it faces, a dish on a short mast, and a heat probe going down into the ground under it. It
## stands on a foundation of Io rock where the ground dips, sulphur on top.
func _volcano_lander(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [-5, 0, 5]:
		for b in [-5, 0, 5]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, y: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, y, 0)
	var boxes: Array = []
	_box(boxes, at.call(-5, -5, span.x - c.y - 2), at.call(5, 5, -2), BlockIds.IO_ROCK)   # foundation ...
	_box(boxes, at.call(-5, -5, -1), at.call(5, 5, -1), BlockIds.SULPHUR)                 # ... sulphur on top
	_box(boxes, at.call(-6, -6, 0), at.call(6, 6, 11), BlockIds.AIR)                      # room round it
	_box(boxes, at.call(0, 0, -5), at.call(0, 0, 2), BlockIds.LANDER_LEG)                 # the heat probe, into the ground
	for a: int in [-3, 3]:   # four legs
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a, b, 2), BlockIds.LANDER_LEG)
	_box(boxes, at.call(-3, -3, 3), at.call(3, 3, 5), BlockIds.HEAT_TILE)                 # the body and its deck
	for a: int in [-3, 3]:   # a light on each corner of the deck
		for b: int in [-3, 3]:
			var lamp: Vector3i = at.call(a, b, 6)
			_box(boxes, lamp, lamp, BlockIds.HEAT_CAMERA)
	_box(boxes, at.call(2, 0, 6), at.call(2, 0, 8), BlockIds.LANDER_LEG)                  # the camera's mast ...
	var eye: Vector3i = at.call(3, 0, 8)
	_box(boxes, eye, eye, BlockIds.HEAT_CAMERA)                                            # ... the heat camera, looking out
	_box(boxes, at.call(-2, 2, 6), at.call(-2, 2, 7), BlockIds.LANDER_LEG)                # the dish's mast ...
	_box(boxes, at.call(-3, 1, 8), at.call(-1, 3, 8), BlockIds.HEAT_TILE)                 # ... and its dish
	_box(boxes, at.call(5, -1, 0), at.call(5, 1, 0), BlockIds.HEAT_TILE)                  # two steps up its front
	_box(boxes, at.call(4, -1, 0), at.call(4, 1, 2), BlockIds.HEAT_TILE)
	var chest: Vector3i = at.call(-1, 0, 6)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-3, -3, 6).min(at.call(3, 3, 6)), at.call(-3, -3, 6).max(at.call(3, 3, 6)) + Vector3i(1, 4, 1)],
		"name": "Volcano Lander"}


## The Landing Probe (Titan's landmark; a probe really landed on Titan in 2005, under a parachute, spec §21b.2: "a
## probe", never a mission's name), facing the landing pad: a round shell of gold foil and white (a disc, a wider rim with
## four lamps, a top), the golden chest on top (one Titan jump up, or the step on its front), a little mast with a lamp,
## and its striped parachute lying flat on the ground behind it. It stands on a foundation of icy rock where the ground
## dips, soil on top.
func _landing_probe(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [-12, -6, 0, 5]:
		for b in [-5, 0, 5]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, y: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, y, 0)
	var boxes: Array = []
	_box(boxes, at.call(-13, -6, span.x - c.y - 2), at.call(6, 6, -2), BlockIds.ICY_ROCK)   # foundation ...
	_box(boxes, at.call(-13, -6, -1), at.call(6, 6, -1), BlockIds.TITAN_SOIL)               # ... soil on top
	_box(boxes, at.call(-14, -7, 0), at.call(7, 7, 8), BlockIds.AIR)                        # room round it
	var mid: Vector3i = at.call(1, 0, 0)
	_disc(boxes, mid, 2, BlockIds.PROBE_SHELL)                                              # the shell: its foot ...
	_disc(boxes, mid + Vector3i.UP, 3, BlockIds.PROBE_SHELL)                                # ... its wide rim ...
	_disc(boxes, mid + Vector3i(0, 2, 0), 2, BlockIds.PROBE_SHELL)                          # ... and its top
	for d: Vector3i in [dir * 3, -dir * 3, side * 3, -side * 3]:   # a lamp on each side of the rim
		var lamp := mid + Vector3i.UP + d
		_box(boxes, lamp, lamp, BlockIds.PROBE_LAMP)
	_box(boxes, at.call(-1, 1, 3), at.call(-1, 1, 4), BlockIds.PROBE_SHELL)                 # a little mast ...
	var tip: Vector3i = at.call(-1, 1, 5)
	_box(boxes, tip, tip, BlockIds.PROBE_LAMP)                                             # ... and its lamp
	_box(boxes, at.call(5, -1, 0), at.call(5, 1, 0), BlockIds.PROBE_SHELL)                  # a step up its front
	_disc(boxes, at.call(-8, 0, 0), 4, BlockIds.PARACHUTE)                                  # the parachute behind it
	var chest: Vector3i = at.call(1, 0, 3)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-1, -2, 3).min(at.call(3, 2, 3)), at.call(-1, -2, 3).max(at.call(3, 2, 3)) + Vector3i(1, 4, 1)],
		"name": "Landing Probe"}


## The Sunshade Lander (Mercury's landmark; spacecraft visiting Mercury really hide behind big sunshades, spec §21b.2:
## "a lander", never a mission's name), facing the landing pad: four legs, a body wrapped in a silvery heat blanket,
## mirror panels out to both sides, a lamp on each corner of its deck and one on a little mast, the golden chest on its
## deck (two steps up its front: one Mercury jump each), and its big white sunshade standing on its sunny side (SUNNY: the
## south, where the Sun is at noon), a little curved, held out on two struts past the mirror panels. It stands on a
## foundation of Mercury rock where the ground dips, dust on top.
func _sunshade_lander(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [-6, 0, 6]:
		for b in [-6, 0, 6]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, y: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, y, 0)
	var across := Vector3i(SUNNY.z, 0, -SUNNY.x)   # along the sunshade
	var boxes: Array = []
	_box(boxes, at.call(-6, -6, span.x - c.y - 2), at.call(6, 6, -2), BlockIds.MERCURY_ROCK)   # foundation ...
	_box(boxes, at.call(-6, -6, -1), at.call(6, 6, -1), BlockIds.MERCURY_DUST)                 # ... dust on top
	_box(boxes, at.call(-7, -7, 0), at.call(7, 7, 12), BlockIds.AIR)                           # room round it ...
	_box(boxes, c - across * 6 + SUNNY * 4, c + across * 6 + SUNNY * 10 + Vector3i(0, 11, 0), BlockIds.AIR)   # ... and the shade
	for a: int in [-3, 3]:   # four legs
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a, b, 2), BlockIds.HEAT_BLANKET)
	_box(boxes, at.call(-3, -3, 3), at.call(3, 3, 5), BlockIds.HEAT_BLANKET)                   # the body and its deck
	for b: int in [-7, 4]:   # the mirror panels, out to both sides
		_box(boxes, at.call(-1, b, 4), at.call(1, b + 3, 4), BlockIds.MIRROR_PANEL)
	for a: int in [-3, 3]:   # a lamp on each corner of the deck
		for b: int in [-3, 3]:
			var lamp: Vector3i = at.call(a, b, 6)
			_box(boxes, lamp, lamp, BlockIds.EXPLORER_LAMP)
	_box(boxes, at.call(-2, 2, 6), at.call(-2, 2, 7), BlockIds.HEAT_BLANKET)                   # a little mast ...
	var tip: Vector3i = at.call(-2, 2, 8)
	_box(boxes, tip, tip, BlockIds.EXPLORER_LAMP)                                              # ... and its lamp
	_box(boxes, at.call(5, -1, 0), at.call(5, 1, 0), BlockIds.HEAT_BLANKET)                    # two steps up its front
	_box(boxes, at.call(4, -1, 0), at.call(4, 1, 2), BlockIds.HEAT_BLANKET)
	for k: int in [-3, 3]:   # two struts from the body out to the sunshade
		_box(boxes, c + across * k + SUNNY * 4 + Vector3i(0, 5, 0), c + across * k + SUNNY * 8 + Vector3i(0, 5, 0),
			BlockIds.HEAT_BLANKET)
	for k in range(-5, 6):   # the sunshade: 11 wide, 9 tall, its ends bent a little round the lander
		var out := 8 if absi(k) >= 4 else 9
		_box(boxes, c + across * k + SUNNY * out + Vector3i(0, 2, 0), c + across * k + SUNNY * out + Vector3i(0, 10, 0),
			BlockIds.SUNSHADE)
	var chest: Vector3i = at.call(-1, 0, 6)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-3, -3, 6).min(at.call(3, 3, 6)), at.call(-3, -3, 6).max(at.call(3, 3, 6)) + Vector3i(1, 4, 1)],
		"name": "Sunshade Lander"}


## The Balloon Lander (Pluto's landmark; scientists have studied a lander that slows down from its fast trip in Pluto's
## thin, tall air under a giant, light drag balloon: "a lander", never a study's or a mission's name), facing the landing
## pad: four legs of dark truss, a body wrapped in gold foil, a white deck with a lamp on each corner and the golden chest
## (one Pluto jump up, or the steps on its front), a glowing power pack on an arm at its back (sunlight out here is about
## 1/900 of Earth's: real probes this far out make their electricity from heat), a radio dish on a mast, and its silvery
## drag balloon lying spread out and crumpled on the ground behind it. It stands on a foundation of water ice where the
## ground dips, frost on top.
func _balloon_lander(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [-BALLOON_BACK - BALLOON_R, -BALLOON_BACK, -5, 0, 5]:
		for b in [-BALLOON_R, 0, BALLOON_R]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, up: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, up, 0)
	var back := -BALLOON_BACK - BALLOON_R - 1
	var boxes: Array = []
	_box(boxes, at.call(back, -BALLOON_R - 1, span.x - c.y - 2), at.call(6, BALLOON_R + 1, -2), BlockIds.WATER_ICE)
	_box(boxes, at.call(back, -BALLOON_R - 1, -1), at.call(6, BALLOON_R + 1, -1), BlockIds.PLUTO_FROST)   # frost on top
	_box(boxes, at.call(back - 1, -BALLOON_R - 2, 0), at.call(7, BALLOON_R + 2, 11), BlockIds.AIR)        # room round it
	for a: int in [-3, 3]:   # four legs
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a, b, 1), BlockIds.TRUSS)
	_box(boxes, at.call(-2, -2, 2), at.call(2, 2, 4), BlockIds.LANDER_FOIL)      # the body in gold foil
	_box(boxes, at.call(-3, -3, 5), at.call(3, 3, 5), BlockIds.STATION_PANEL)    # its white deck
	for a: int in [-3, 3]:   # a lamp on each corner of the deck
		for b: int in [-3, 3]:
			var lamp: Vector3i = at.call(a, b, 6)
			_box(boxes, lamp, lamp, BlockIds.STATION_LAMP)
	_box(boxes, at.call(-3, 0, 3), at.call(-3, 0, 3), BlockIds.TRUSS)             # an arm at its back ...
	_box(boxes, at.call(-4, 0, 2), at.call(-4, 0, 3), BlockIds.POWER_PACK)        # ... and the glowing power pack
	_box(boxes, at.call(1, 2, 6), at.call(1, 2, 7), BlockIds.TRUSS)               # the dish's mast ...
	_box(boxes, at.call(0, 1, 8), at.call(2, 3, 8), BlockIds.RADIO_DISH)          # ... and its dish
	_box(boxes, at.call(5, -1, 0), at.call(5, 1, 0), BlockIds.STATION_PANEL)      # two steps up its front
	_box(boxes, at.call(4, -1, 0), at.call(4, 1, 2), BlockIds.STATION_PANEL)
	for a in range(-BALLOON_R, BALLOON_R + 1):   # the drag balloon, spread out behind it, crumpled in folds
		for b in range(-BALLOON_R, BALLOON_R + 1):
			var d := Vector2(a, b).length()
			if d > BALLOON_R + 0.4:
				continue
			var p: Vector3i = at.call(-BALLOON_BACK + a, b, 0)
			_box(boxes, p, p, BlockIds.DRAG_BALLOON)
			if d < BALLOON_R - 1.5 and posmod(a + 2 * b, 5) == 0:
				_box(boxes, p + Vector3i.UP, p + Vector3i.UP, BlockIds.DRAG_BALLOON)   # a fold
	for b: int in [-2, 2]:   # its tethers back to the body
		_box(boxes, at.call(-BALLOON_BACK + BALLOON_R + 1, b, 0), at.call(-3, b, 0), BlockIds.TRUSS)
	var chest: Vector3i = at.call(0, 0, 6)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-2, -2, 6).min(at.call(2, 2, 6)), at.call(-2, -2, 6).max(at.call(2, 2, 6)) + Vector3i(1, 4, 1)],
		"name": "Balloon Lander"}


## Triton: the Hopper Lander, facing the pad: four legs, a body in gold foil with a rocket nozzle under it, a white deck
## with a lamp on each corner and the golden chest, a big white tank of nitrogen in the deck's middle (its fuel: it scoops
## Triton's nitrogen ice, heats it and hops), a scoop arm down to a heap of frost at its side, a glowing power pack on an
## arm at its back (its heater), a radio dish on a mast, two steps up its front, and the scorched rings of its last hops
## on the ground behind it.
func _hopper_lander(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [HOPS[1] - 2, HOPS[0], -4, 0, 5]:
		for b in [-5, 0, 5]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, up: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, up, 0)
	var back := HOPS[1] - 3
	var boxes: Array = []
	_box(boxes, at.call(back, -6, span.x - c.y - 2), at.call(6, 6, -2), BlockIds.NITROGEN_ICE)
	_box(boxes, at.call(back, -6, -1), at.call(6, 6, -1), BlockIds.TRITON_FROST)   # frost on top
	_box(boxes, at.call(back - 1, -7, 0), at.call(7, 7, 10), BlockIds.AIR)          # room round it
	for h: int in HOPS:   # the scorched rings of its last hops
		for a in range(-2, 3):
			for b in range(-2, 3):
				var d := Vector2(a, b).length()
				if d <= HOP_R + 0.5 and d >= HOP_R - 1.0:
					var p: Vector3i = at.call(h + a, b, -1)
					_box(boxes, p, p, BlockIds.GEYSER_DUST)
	for a: int in [-3, 3]:   # four legs
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a, b, 1), BlockIds.TRUSS)
	_box(boxes, at.call(0, 0, 1), at.call(0, 0, 1), BlockIds.SPACE_ENGINE)       # its rocket nozzle, pointing down
	_box(boxes, at.call(-2, -2, 2), at.call(2, 2, 3), BlockIds.LANDER_FOIL)      # the body in gold foil
	_box(boxes, at.call(-3, -3, 4), at.call(3, 3, 4), BlockIds.STATION_PANEL)    # its white deck
	_box(boxes, at.call(-1, -1, 5), at.call(1, 1, 7), BlockIds.NITROGEN_TANK)    # the big tank of nitrogen
	for a: int in [-3, 3]:   # a lamp on each corner of the deck
		for b: int in [-3, 3]:
			var lamp: Vector3i = at.call(a, b, 5)
			_box(boxes, lamp, lamp, BlockIds.STATION_LAMP)
	_box(boxes, at.call(0, -3, 2), at.call(0, -4, 2), BlockIds.TRUSS)             # the scoop arm ...
	_box(boxes, at.call(0, -5, 0), at.call(0, -5, 1), BlockIds.TRUSS)
	_box(boxes, at.call(-1, -6, 0), at.call(1, -6, 0), BlockIds.TRITON_FROST)     # ... at a heap of frost
	_box(boxes, at.call(-3, 0, 3), at.call(-3, 0, 3), BlockIds.TRUSS)             # an arm at its back ...
	_box(boxes, at.call(-4, 0, 2), at.call(-4, 0, 3), BlockIds.POWER_PACK)        # ... and the glowing power pack
	_box(boxes, at.call(-2, 2, 5), at.call(-2, 2, 6), BlockIds.TRUSS)             # the dish's mast ...
	_box(boxes, at.call(-3, 1, 7), at.call(-1, 3, 7), BlockIds.RADIO_DISH)        # ... and its dish
	_box(boxes, at.call(5, -1, 0), at.call(5, 1, 0), BlockIds.STATION_PANEL)      # two steps up its front
	_box(boxes, at.call(4, -1, 0), at.call(4, 1, 2), BlockIds.STATION_PANEL)
	var chest: Vector3i = at.call(2, 0, 5)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-3, -3, 5).min(at.call(3, 3, 5)), at.call(-3, -3, 5).max(at.call(3, 3, 5)) + Vector3i(1, 4, 1)],
		"name": "Hopper Lander"}


## Ganymede: the Solar Wing Lander, facing the pad: four legs, a body in gold foil, a white deck with a lamp on each
## corner and the golden chest, two giant solar wings on trusses out to both sides (sunlight at Jupiter is about 25 times
## weaker than at Earth), a magnetometer far out on a boom at its back, a radio dish on a mast, two steps up its front.
func _solar_wing_lander(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var samples: Array = []
	for a in [-BOOM_OUT, -4, 0, 5]:
		for b in [-WING.y, -5, 0, 5, WING.y]:
			samples.append(Vector2i(dir.x * a + side.x * b, dir.z * a + side.z * b))
	var span := _ground_span(c2, samples)
	var c := Vector3i(c2.x, span.y, c2.y)
	var at := func(a: int, b: int, up: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, up, 0)
	var boxes: Array = []
	_box(boxes, at.call(-5, -5, span.x - c.y - 2), at.call(6, 5, -2), BlockIds.GROOVED_ICE)   # level ground under it
	_box(boxes, at.call(-5, -5, -1), at.call(6, 5, -1), BlockIds.GROOVED_ICE)
	_box(boxes, at.call(-BOOM_OUT - 1, -WING.y - 1, 0), at.call(7, WING.y + 1, 9), BlockIds.AIR)   # room round it
	for a: int in [-3, 3]:   # four legs
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a, b, 1), BlockIds.TRUSS)
	_box(boxes, at.call(-2, -2, 2), at.call(2, 2, 3), BlockIds.LANDER_FOIL)      # the body in gold foil
	_box(boxes, at.call(-3, -3, 4), at.call(3, 3, 4), BlockIds.STATION_PANEL)    # its white deck
	for a: int in [-3, 3]:   # a lamp on each corner of the deck
		for b: int in [-3, 3]:
			var lamp: Vector3i = at.call(a, b, 5)
			_box(boxes, lamp, lamp, BlockIds.STATION_LAMP)
	for s: int in [-1, 1]:   # the wings: an arm out of each side, a giant panel of solar cells on it
		_box(boxes, at.call(0, s * 4, 4), at.call(0, s * (WING.x - 1), 4), BlockIds.TRUSS)
		_box(boxes, at.call(-WING_HALF, s * WING.x, 4), at.call(WING_HALF, s * WING.y, 4), BlockIds.SOLAR_PANEL)
	_box(boxes, at.call(-4, 0, 3), at.call(-BOOM_OUT + 1, 0, 3), BlockIds.TRUSS)   # the boom out of its back ...
	var sensor: Vector3i = at.call(-BOOM_OUT, 0, 3)
	_box(boxes, sensor, sensor, BlockIds.MAGNETOMETER)                          # ... and its magnetometer
	_box(boxes, at.call(-1, 2, 5), at.call(-1, 2, 6), BlockIds.TRUSS)             # the dish's mast ...
	_box(boxes, at.call(-2, 1, 7), at.call(0, 3, 7), BlockIds.RADIO_DISH)        # ... and its dish
	_box(boxes, at.call(5, -1, 0), at.call(5, 1, 0), BlockIds.STATION_PANEL)      # two steps up its front
	_box(boxes, at.call(4, -1, 0), at.call(4, 1, 2), BlockIds.STATION_PANEL)
	var chest: Vector3i = at.call(2, 0, 5)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(dir), "dir": dir, "boxes": boxes,
		"inside": [at.call(-3, -3, 5).min(at.call(3, 3, 5)), at.call(-3, -3, 5).max(at.call(3, 3, 5)) + Vector3i(1, 4, 1)],
		"name": "Solar Wing Lander"}


## Venus: a geode of cloud crystal inside a float hull at (x, z): a hollow ball GEODE_R round, its top two blocks under
## the deck, a few diamonds in its shell (Venus's clouds hold no rock: never deep down).
func _cloud_geode(x: int, z: int, v: int) -> Dictionary:
	var r := GEODE_R
	var c := Vector3i(x, VenusTerrain.DECK_Y - 2 - r, z)
	var boxes: Array = []
	_ball(boxes, c, r, BlockIds.CRYSTAL)
	_ball(boxes, c, r - 1, BlockIds.AIR)
	var axes: Array[Vector3i] = [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r),
		Vector3i(0, -r, 0), Vector3i(0, r, 0)]
	for i in 3:
		var stud := c + axes[(v >> (4 + i * 3)) % axes.size()]
		_box(boxes, stud, stud, BlockIds.DIAMOND)
	return {"anchor": c, "radius": r, "boxes": boxes,
		"inside": [c - Vector3i(r - 2, r - 2, r - 2), c + Vector3i(r - 1, r - 1, r - 1)]}


## Venus: a hidden room in a float hull at (x, z) (SecretRules' room, HULL_ROOM_DEPTH under the deck instead of
## ROOM_DEPTH under the ground: a hull is not as deep as a hill): walls of hull, a deck floor, a lamp in every corner and
## a chest, stairs up through the hull to the deck from a fake hull door.
func _hull_room(x: int, z: int, v: int) -> Dictionary:
	var h := shape.height_at(x, z)
	if not _dry(x, z, h):
		return {}
	var f := h - HULL_ROOM_DEPTH
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, c + Vector3i(-3, 0, -3), c + Vector3i(3, 4, 3), BlockIds.STONE)
	_box(boxes, c + Vector3i(-2, 0, -2), c + Vector3i(2, 0, 2), BlockIds.PLANKS)
	_box(boxes, c + Vector3i(-2, 1, -2), c + Vector3i(2, 3, 2), BlockIds.AIR)
	for lamp: Vector3i in [Vector3i(-2, 4, -2), Vector3i(2, 4, -2), Vector3i(-2, 4, 2), Vector3i(2, 4, 2)]:
		_box(boxes, c + lamp, c + lamp, BlockIds.LIGHT)
	var fake: Array[Vector3i] = [c + dir * 3 + Vector3i(0, 1, 0), c + dir * 3 + Vector3i(0, 2, 0)]
	_box(boxes, fake[0], fake[1], BlockIds.FAKE_WALL)
	var top := Vector3i.ZERO
	var k := 1
	while true:
		var col := c + dir * (3 + k)
		var fy := f if k <= 2 else f + k - 2
		var hc := shape.height_at(col.x, col.z)
		if fy >= hc:
			break                # out on the deck: the stairs are done
		if k > ROOM_STEPS or shape.is_river(col.x, col.z):
			return {}            # off the platform
		_box(boxes, Vector3i(col.x, fy, col.z) - side, Vector3i(col.x, mini(fy + 4, hc - 1), col.z) + side, BlockIds.STONE)
		_box(boxes, Vector3i(col.x, fy + 1, col.z), Vector3i(col.x, fy + 3, col.z), BlockIds.AIR)
		top = Vector3i(col.x, fy, col.z)
		k += 1
	var s := {"anchor": c + Vector3i(0, 1, 0), "chest": c + Vector3i(0, 1, 0) - dir * 2, "chest_kind": &"room",
		"yaw": _yaw(dir), "boxes": boxes, "fake_wall": fake, "stairs_top": top, "dir": dir,
		"inside": [c + Vector3i(-2, 1, -2), c + Vector3i(3, 4, 3)]}
	if (v >> 2) % 2 == 0:
		var note := Riddles.room_note(v >> 3)
		s.note = {"cell": c + Vector3i(0, 1, 0) - dir * 2 + side * 2, "text": note.text, "pictures": note.pictures,
			"yaw": _yaw(dir)}
	return s


## The Research Blimp (Venus's landmark; scientists have imagined airships floating in Venus's clouds, and two robot
## balloons really floated there for two days in 1985: "a blimp", never a mission's name), moored beside the airship
## dock, its door toward the pad: a gangway of bridge planks from the dock's rim to the gondola (white walls with round
## windows, a deck floor, lamps at its corners and in its ceiling, the golden chest inside), struts up to the envelope (a
## long white ellipsoid lying east-west, a teal stripe along each side, solar film along its back, a lamp on its nose,
## tail fins on its other end). The floor is at deck height: the walk from the pad into the gondola is level.
func _research_blimp() -> Dictionary:
	var v := space.venus
	var dock := v.centre(VenusTerrain.DOCK)
	var r := int(v.platform(VenusTerrain.DOCK)[3])
	var n := Vector3i(v.north().x, 0, v.north().y)
	var e := Vector3i(1, 0, 0)
	var y := VenusTerrain.DECK_Y
	var d0 := Vector3i(dock.x, y, dock.y)
	var near := r + GANGWAY                       # the gondola's near wall, out from the dock's middle
	var gc := d0 + n * (near + GONDOLA_HALF.y)    # the gondola's middle, on its floor's level
	var at := func(a: int, b: int, up: int) -> Vector3i: return gc + e * a + n * b + Vector3i(0, up, 0)
	var hx := GONDOLA_HALF.x
	var hz := GONDOLA_HALF.y
	var boxes: Array = []
	_box(boxes, d0 + n * r + e * -1 + Vector3i.DOWN, d0 + n * (near - 1) + e + Vector3i.DOWN, BlockIds.SKY_BRIDGE)   # gangway
	_box(boxes, at.call(-hx, -hz, -1), at.call(hx, hz, -1), BlockIds.CLOUD_DECK)       # the gondola's floor ...
	_box(boxes, at.call(-hx, -hz, 0), at.call(hx, hz, 2), BlockIds.GONDOLA)            # ... its walls ...
	_box(boxes, at.call(-hx + 1, -hz + 1, 0), at.call(hx - 1, hz - 1, 2), BlockIds.AIR)   # ... room inside ...
	_box(boxes, at.call(0, -hz, 0), at.call(0, -hz, 1), BlockIds.AIR)                  # ... its door toward the dock ...
	_box(boxes, at.call(-hx, -hz, 3), at.call(hx, hz, 3), BlockIds.GONDOLA)            # ... its roof
	for a: int in [-hx, hx]:   # a lamp on each corner of the roof, one in its ceiling
		for b: int in [-hz, hz]:
			var lamp: Vector3i = at.call(a, b, 3)
			_box(boxes, lamp, lamp, BlockIds.CLOUD_LAMP)
	_box(boxes, at.call(0, 0, 3), at.call(0, 0, 3), BlockIds.CLOUD_LAMP)
	for a: int in [-2, 2]:   # two struts up to the envelope
		_box(boxes, at.call(a, 0, 4), at.call(a, 0, ENVELOPE_UP - int(ENVELOPE.y)), BlockIds.SKY_FRAME)
	var mid: Vector3i = at.call(0, 0, ENVELOPE_UP)
	var hy := int(ENVELOPE.y)
	var hw := int(ENVELOPE.z)
	for dy in range(-hy, hy + 1):   # the envelope, row by row along its length ...
		for dn in range(-hw, hw + 1):
			var rest := 1.0 - pow(dy / ENVELOPE.y, 2.0) - pow(dn / ENVELOPE.z, 2.0)
			if rest < 0.0:
				continue
			var half := int(ENVELOPE.x * sqrt(rest))
			var row := mid + n * dn + Vector3i(0, dy, 0)
			var id := BlockIds.BLIMP_SKIN
			if (dy == 0 or dy == -1) and absi(dn) == hw:
				id = BlockIds.BLIMP_STRIPE   # ... a teal stripe along each side ...
			elif dy >= hy - 1 and absi(dn) <= 1:
				id = BlockIds.SOLAR_FILM     # ... solar film along its back
			_box(boxes, row - e * half, row + e * half, id)
	var tail := int(ENVELOPE.x)
	_box(boxes, mid + e * -(tail + 1) + Vector3i(0, 3, 0), mid + e * -(tail - 2) + Vector3i(0, 7, 0), BlockIds.BLIMP_STRIPE)
	_box(boxes, mid + e * -(tail + 1) + Vector3i(0, -7, 0), mid + e * -(tail - 2) + Vector3i(0, -3, 0), BlockIds.BLIMP_STRIPE)
	for k: int in [-1, 1]:   # the tail fins, up, down and to both sides
		_box(boxes, mid + e * -(tail + 1) + n * (4 * k), mid + e * -(tail - 2) + n * (7 * k), BlockIds.BLIMP_STRIPE)
	var nose := mid + e * (tail + 1)
	_box(boxes, nose, nose, BlockIds.CLOUD_LAMP)
	var chest: Vector3i = at.call(2, 0, 0)
	var lo: Vector3i = at.call(-hx + 1, -hz + 1, 0)
	var hi: Vector3i = at.call(hx - 1, hz - 1, 0)
	return {"anchor": gc, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(-n), "dir": -n, "boxes": boxes,
		"inside": [lo.min(hi), lo.max(hi) + Vector3i(1, 3, 1)], "name": "Research Blimp"}


## Saturn's rings: a geode of ring crystal inside a chunk at (x, z): a hollow ball RING_GEODE_R round, its top two blocks
## under the chunk's top, a few diamonds in its shell.
func _ring_geode(x: int, z: int, v: int) -> Dictionary:
	var r := RING_GEODE_R
	var c := Vector3i(x, space.height_at(x, z) - 2 - r, z)
	var boxes: Array = []
	_ball(boxes, c, r, BlockIds.CRYSTAL)
	_ball(boxes, c, r - 1, BlockIds.AIR)
	var axes: Array[Vector3i] = [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r),
		Vector3i(0, -r, 0), Vector3i(0, r, 0)]
	for i in 3:
		var stud := c + axes[(v >> (4 + i * 3)) % axes.size()]
		_box(boxes, stud, stud, BlockIds.DIAMOND)
	return {"anchor": c, "radius": r, "boxes": boxes,
		"inside": [c - Vector3i(r - 2, r - 2, r - 2), c + Vector3i(r - 1, r - 1, r - 1)]}


## The Ring Explorer (the rings' landmark; a spacecraft really dived between Saturn and its rings 22 times in 2017:
## "a spacecraft", never a mission's name), resting on its own chunk, its door toward the pad: a body wrapped in gold
## foil with a white deck on top, the golden chest inside, a big white radio dish on a truss over the deck with a lamp
## on its feed, three glowing power packs on arms (far from the Sun, sunlight is too weak for big solar panels: real
## probes out here make their electricity from heat), a long boom out to one side, four little feet.
func _ring_explorer() -> Dictionary:
	var rt := space.rings
	var ctr := rt.centre(RingsTerrain.EXPLORER)
	var y := int(rt.fixed(RingsTerrain.EXPLORER)[4])
	var c := Vector3i(ctr.x, y, ctr.y)
	var sp := space.spawn_column()
	var to_pad := Vector2(sp.x - c.x, sp.y - c.z)
	var dir := Vector3i(signi(roundi(to_pad.x)), 0, 0) if absf(to_pad.x) >= absf(to_pad.y) \
		else Vector3i(0, 0, signi(roundi(to_pad.y)))
	var side := Vector3i(-dir.z, 0, dir.x)
	var at := func(a: int, b: int, up: int) -> Vector3i: return c + dir * a + side * b + Vector3i(0, up, 0)
	var boxes: Array = []
	_box(boxes, at.call(-2, -2, 0), at.call(2, 2, 3), BlockIds.LANDER_FOIL)                  # the body ...
	_box(boxes, at.call(-1, -1, 0), at.call(1, 1, 2), BlockIds.AIR)                          # ... room inside ...
	_box(boxes, at.call(2, 0, 0), at.call(2, 0, 1), BlockIds.AIR)                            # ... its door toward the pad
	_box(boxes, at.call(-2, -2, 3), at.call(2, 2, 3), BlockIds.STATION_PANEL)                 # ... a white deck on top
	_box(boxes, at.call(0, 0, 2), at.call(0, 0, 2), BlockIds.STATION_LAMP)                   # a lamp in its ceiling
	for a: int in [-3, 3]:   # four little feet
		for b: int in [-3, 3]:
			_box(boxes, at.call(a, b, 0), at.call(a, b, 0), BlockIds.TRUSS)
	_box(boxes, at.call(0, 0, 4), at.call(0, 0, 4), BlockIds.TRUSS)                          # the dish's truss ...
	for da in range(-DISH_R, DISH_R + 1):   # ... the dish: a round white bowl, its rim a block higher
		for db in range(-DISH_R, DISH_R + 1):
			var d := Vector2(da, db).length()
			if d > DISH_R + 0.4:
				continue
			var up := 6 if d > DISH_R - 0.8 else 5
			var p: Vector3i = at.call(da, db, up)
			_box(boxes, p, p, BlockIds.RADIO_DISH)
	_box(boxes, at.call(0, 0, 6), at.call(0, 0, 7), BlockIds.TRUSS)                          # ... its feed ...
	_box(boxes, at.call(0, 0, 8), at.call(0, 0, 8), BlockIds.STATION_LAMP)                   # ... and its lamp
	for e: Vector3i in [Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(-1, 0, 0)]:   # three power packs on arms
		var arm: Vector3i = at.call(e.x * 3, e.y * 3, 2)
		_box(boxes, arm, arm, BlockIds.TRUSS)
		var pack: Vector3i = at.call(e.x * 4, e.y * 4, 1)
		_box(boxes, pack, pack + Vector3i(0, 1, 0), BlockIds.POWER_PACK)
	_box(boxes, at.call(-1, 3, 3), at.call(-1, 2 + BOOM, 3), BlockIds.TRUSS)                 # the long boom ...
	var tip: Vector3i = at.call(-1, 3 + BOOM, 3)
	_box(boxes, tip, tip, BlockIds.STATION_PANEL)                                            # ... and its sensor
	var chest: Vector3i = at.call(-1, 0, 0)
	var lo: Vector3i = at.call(-1, -1, 0)
	var hi: Vector3i = at.call(1, 1, 0)
	return {"anchor": c, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(-dir), "dir": dir, "boxes": boxes,
		"inside": [lo.min(hi), lo.max(hi) + Vector3i(1, 3, 1)], "name": "Ring Explorer"}


## The Moon Base: a silver dome on a foundation, a floor, round portholes, a light at the top and an antenna, the door
## toward the landing pad, a golden chest in the middle.
func _moon_base(c2: Vector2i, dir: Vector3i) -> Dictionary:
	var r := DOME_RADIUS
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for d: Vector2i in [Vector2i.ZERO, Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r), Vector2i(4, 4),
			Vector2i(-4, 4), Vector2i(4, -4), Vector2i(-4, -4)]:
		var gh := space.height_at(c2.x + d.x, c2.y + d.y)
		lo = mini(lo, gh)
		hi = maxi(hi, gh)
	var c := Vector3i(c2.x, hi, c2.y)
	var boxes: Array = []
	_box(boxes, Vector3i(c.x - r, lo - 2, c.z - r), Vector3i(c.x + r, c.y - 2, c.z + r), BlockIds.MOON_ROCK)   # foundation
	_disc(boxes, c + Vector3i.DOWN, r, BlockIds.BASE_PANEL)                                                 # the floor
	_dome(boxes, c, r, BlockIds.BASE_PANEL)
	_dome(boxes, c, r - 1, BlockIds.AIR)
	var side := Vector3i(-dir.z, 0, dir.x)
	for w: Vector3i in [side, -side, -dir]:   # round windows in the dome's wall, left, right and back
		var at := c + w * r + Vector3i(0, 2, 0)
		_box(boxes, at, at, BlockIds.PORTHOLE)
	_box(boxes, c + Vector3i(0, r - 1, 0), c + Vector3i(0, r - 1, 0), BlockIds.BASE_LIGHT)                   # the ceiling light
	_box(boxes, c + Vector3i(0, r, 0), c + Vector3i(0, r + 2, 0), BlockIds.BASE_PANEL)                       # the antenna ...
	_box(boxes, c + Vector3i(0, r + 3, 0), c + Vector3i(0, r + 3, 0), BlockIds.BASE_LIGHT)                   # ... and its light
	_box(boxes, c + dir * (r - 1), c + dir * (r + 2) + Vector3i.UP, BlockIds.AIR)                              # the door and a way out
	_box(boxes, c + dir * (r - 1) + Vector3i.DOWN, c + dir * (r + 2) + Vector3i.DOWN, BlockIds.BASE_PANEL)    # its step
	return {"anchor": c, "chest": c, "chest_kind": &"sky", "yaw": _yaw(-dir), "dir": dir, "boxes": boxes,
		"inside": [c - Vector3i(r - 2, 0, r - 2), c + Vector3i(r - 1, 3, r - 1)], "name": "Moon Base"}


## The upper half of a ball of radius r standing on `center`'s level (rows of boxes).
static func _dome(boxes: Array, center: Vector3i, r: int, id: int) -> void:
	for dy in range(0, r + 1):
		for dz in range(-r, r + 1):
			var rest := (r + 0.5) * (r + 0.5) - dy * dy - dz * dz
			if rest < 0.0:
				continue
			var hw := int(sqrt(rest))
			_box(boxes, center + Vector3i(-hw, dy, dz), center + Vector3i(hw, dy, dz), id)
