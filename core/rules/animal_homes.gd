class_name AnimalHomes
extends RefCounted
## Where each kind of animal lives (owner feedback #41, spec §14.19), as pure rules: its biomes (the places of
## its universe where it fits) and how often it is picked there. Each universe's descriptor names its animals
## (UniverseRegistry.animals); AnimalRules.spawns_for_cell picks among them with these rules.
## Green Meadows keeps M1b's farm herds (AnimalRules' weights) and M3 Task 11's foxes and parrots; about half of
## its herds become one of the new kinds that fits the herd's place (pack_at: a seeded roll of its own, so every
## other herd keeps its species and spots). The other universes' herds are all their own kinds (pick_at).

# Green Meadows
const MEADOW := &"meadow"         # open grass
const SHORE := &"shore"           # land with water (sea level or a river) within SHORE_LOOK
const WOODS := &"woods"           # a tree within WOODS_LOOK
const HILLS := &"hills"           # ground HILL_RISE or more above the sea
# The Sandstorm Desert
const SAND := &"sand"             # the open desert and its mesas
const OASIS := &"oasis"           # an oasis's grassy banks
# Frostpeak
const SNOW := &"snow"             # the snowy valleys and peaks
const ICE := &"ice"               # on a frozen lake's ice
const LAKESIDE := &"lakeside"     # snow by a frozen lake (within LAKE_LOOK)
# The Candy Kingdom
const FROSTING := &"frosting"     # the frosting plains and gumdrop hills
const CANDY_WOODS := &"candy_woods"   # a candy-cane forest
# Space (owner #55)
const SPACE := &"space"           # a space world's open ground

## Each universe's open land; the other biomes are places of their own, whose kinds come first (_weighted).
const OPEN: Array[StringName] = [MEADOW, SAND, SNOW, FROSTING, SPACE]

const SHORE_LOOK := 8
const LOWLAND := 5                # ground this little above the sea counts as the shore too
const WOODS_LOOK := 5
const HILL_RISE := 16
const LAKE_LOOK := 6
## Green Meadows: this share of the herds becomes one of the new kinds (owner #41).
const PACK_CHANCE := 0.5

## Every wild kind: where it lives and how often it is picked among the kinds that fit a place. The farm
## animals, fish, foxes and parrots keep M1b's and M3 Task 11's own rules (AnimalRules); `pack` marks Green
## Meadows' new kinds (they take a herd's place through pack_at).
const HOMES := {
	&"dog": {"biomes": [MEADOW]}, &"cat": {"biomes": [MEADOW]}, &"pig": {"biomes": [MEADOW]},
	&"cow": {"biomes": [MEADOW]}, &"sheep": {"biomes": [MEADOW]}, &"chicken": {"biomes": [MEADOW]},
	&"rabbit": {"biomes": [MEADOW]}, &"fish": {"biomes": [&"water"]}, &"fox": {"biomes": [WOODS]},
	&"parrot": {"biomes": [SHORE]},
	# owner #41: Green Meadows
	&"horse": {"biomes": [MEADOW], "weight": 10, "pack": true},
	&"donkey": {"biomes": [MEADOW], "weight": 7, "pack": true},
	&"hedgehog": {"biomes": [MEADOW], "weight": 6, "pack": true},
	&"goat": {"biomes": [HILLS], "weight": 10, "pack": true},
	&"deer": {"biomes": [WOODS], "weight": 10, "pack": true},
	&"squirrel": {"biomes": [WOODS], "weight": 9, "pack": true},
	&"owl": {"biomes": [WOODS], "weight": 6, "pack": true},
	&"duck": {"biomes": [SHORE], "weight": 10, "pack": true},
	&"frog": {"biomes": [SHORE], "weight": 8, "pack": true},
	&"turtle": {"biomes": [SHORE], "weight": 6, "pack": true},
	# the Sandstorm Desert
	&"camel": {"biomes": [SAND, OASIS], "weight": 10},
	&"lizard": {"biomes": [SAND], "weight": 10},
	&"fennec": {"biomes": [SAND, OASIS], "weight": 7},
	# Frostpeak
	&"penguin": {"biomes": [ICE, LAKESIDE, SNOW], "weight": 6},
	&"seal": {"biomes": [ICE], "weight": 8},
	&"polar_bear": {"biomes": [SNOW, LAKESIDE], "weight": 4},
	&"arctic_fox": {"biomes": [SNOW], "weight": 8},
	# the Candy Kingdom
	&"gummy_bunny": {"biomes": [FROSTING], "weight": 10},
	&"candy_bird": {"biomes": [CANDY_WOODS], "weight": 10},
	# space (owner #55): the Moon's own; the planets' visitors (frogs, goats, candy birds, horses) keep their biomes
	&"moon_bunny": {"biomes": [SPACE], "weight": 10},
}

const _AROUND: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]


static func biomes(species: StringName) -> Array:
	return HOMES.get(species, {}).get("biomes", [])


static func weight(species: StringName) -> int:
	return int(HOMES.get(species, {}).get("weight", 0))


static func is_pack(species: StringName) -> bool:
	return bool(HOMES.get(species, {}).get("pack", false))


## Does column (x, z) of `shape` belong to `biome`?
static func fits(shape: MeadowsShape, biome: StringName, x: int, z: int) -> bool:
	if shape is SpaceShape:
		return _fits_space(shape as SpaceShape, biome, x, z)
	match biome:
		MEADOW:
			return true
		SHORE:
			if shape.height_at(x, z) <= MeadowsShape.SEA_LEVEL + LOWLAND:
				return true                # the low meadows just above the water line
			return _near(shape, x, z, SHORE_LOOK, func(ax: int, az: int) -> bool:
				return shape.height_at(ax, az) <= MeadowsShape.SEA_LEVEL or shape.is_river(ax, az))
		WOODS:
			return _near(shape, x, z, WOODS_LOOK, func(ax: int, az: int) -> bool: return shape.tree_at(ax, az))
		HILLS:
			return shape.height_at(x, z) >= MeadowsShape.SEA_LEVEL + HILL_RISE
		SAND:
			return shape is DesertShape and (shape as DesertShape).terrain_at(x, z) != DesertShape.OASIS
		OASIS:
			return shape is DesertShape and (shape as DesertShape).terrain_at(x, z) == DesertShape.OASIS
		SNOW:
			return shape is FrostShape and (shape as FrostShape).terrain_at(x, z) != FrostShape.LAKE
		ICE:
			return on_ice(shape, x, z)
		LAKESIDE:
			return shape is FrostShape and near_lake(shape, x, z) and not on_ice(shape, x, z)
		FROSTING:
			return shape is CandyShape and not (shape as CandyShape).forest_at(x, z)
		CANDY_WOODS:
			return shape is CandyShape and (shape as CandyShape).forest_at(x, z)
	return false


## Owner #55: a space world's places — its open ground (SPACE, and the meadow kinds' MEADOW), the woods (its features:
## crystals, spring mushrooms, prism spires) for WOODS and CANDY_WOODS kinds, high ground for HILLS, a jelly pool's edge
## for SHORE (SpaceShape.near_pool).
static func _fits_space(shape: SpaceShape, biome: StringName, x: int, z: int) -> bool:
	match biome:
		SPACE, MEADOW:
			return true
		HILLS:
			return shape.height_at(x, z) >= MeadowsShape.SEA_LEVEL + HILL_RISE
		WOODS, CANDY_WOODS:
			return _near(shape, x, z, WOODS_LOOK, func(ax: int, az: int) -> bool: return shape.tree_at(ax, az))
		SHORE:
			return shape.near_pool(x, z)
	return false


## A frozen lake's ice under column (x, z) (Frostpeak: water under one layer of ice at sea level).
static func on_ice(shape: MeadowsShape, x: int, z: int) -> bool:
	return shape is FrostShape and (shape as FrostShape).terrain_at(x, z) == FrostShape.LAKE \
		and shape.height_at(x, z) < MeadowsShape.SEA_LEVEL


## A frozen lake within LAKE_LOOK of column (x, z) (or under it).
static func near_lake(shape: MeadowsShape, x: int, z: int) -> bool:
	if not shape is FrostShape:
		return false
	var frost := shape as FrostShape
	if frost.terrain_at(x, z) == FrostShape.LAKE:
		return true
	return _near(shape, x, z, LAKE_LOOK, func(ax: int, az: int) -> bool: return frost.terrain_at(ax, az) == FrostShape.LAKE)


## Green Meadows (owner #41): now and then (PACK_CHANCE, from a hash of its own) the herd of area `cell` at
## `center`, whose species the farm weights and the wild pets picked, becomes one of the new kinds among
## `kinds` that fits the place. Fish stay fish; foxes and parrots stay.
static func pack_at(shape: MeadowsShape, cell: Vector2i, center: Vector2i, picked: StringName, kinds: Array) -> StringName:
	if picked == &"fish" or picked == &"fox" or picked == &"parrot":
		return picked
	var h := AnimalRules._mix(shape.seed ^ 0x41a7, cell.x, cell.y)
	if float(h % 10000) / 10000.0 >= PACK_CHANCE:
		return picked
	var choice := _weighted(shape, center, kinds, func(sp: StringName) -> bool: return is_pack(sp), h >> 20)
	return choice if choice != &"" else picked


## Another universe's herd at `center`: one of `kinds` that fits the place, weighted, or &"" (none fits).
static func pick_at(shape: MeadowsShape, center: Vector2i, kinds: Array, rng: RandomNumberGenerator) -> StringName:
	return _weighted(shape, center, kinds, func(sp: StringName) -> bool: return weight(sp) > 0, rng.randi())


## The kinds of a place come first: where a kind's place of its own fits (by the water, the woods, the hills,
## an oasis, a frozen lake, a candy forest), the kinds of the open land (OPEN) are left out, so ducks live by the
## water and horses in the open fields.
static func _weighted(shape: MeadowsShape, center: Vector2i, kinds: Array, allowed: Callable, roll: int) -> StringName:
	var fitting: Array[StringName] = []
	var total := 0
	for open: bool in [false, true]:
		for sp: StringName in kinds:
			if not allowed.call(sp) or weight(sp) <= 0:
				continue
			for b: StringName in biomes(sp):
				if OPEN.has(b) == open and fits(shape, b, center.x, center.y):
					fitting.append(sp)
					total += weight(sp)
					break
		if total > 0:
			break
	if total <= 0:
		return &""
	var pick := absi(roll) % total
	for sp in fitting:
		pick -= weight(sp)
		if pick < 0:
			return sp
	return fitting.back()


static func _near(_shape: MeadowsShape, x: int, z: int, reach: int, test: Callable) -> bool:
	if test.call(x, z):
		return true
	for r in range(1, reach + 1):
		for d in _AROUND:
			if test.call(x + d.x * r, z + d.y * r):
				return true
	return false
