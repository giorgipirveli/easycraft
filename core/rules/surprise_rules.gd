class_name SurpriseRules
extends RefCounted
## The secrets that happen while playing (M2 Task 16, spec §12.16), as pure rules: the Wanderer at dusk,
## shooting stars at night, golden animals, a temple's pressure plates, the secret chime and the treasure
## map's compass. Everything is decided from the world seed and a count (the n-th dusk, the n-th night) or
## an id, so a world plays the same way every time and the host can check it.

const WANDERER_EVERY := 3            # about one dusk in 3 brings the Wanderer (the first dusk always)
const WANDERER_MIN_DISTANCE := 6.0   # he appears this far from a player (sideways)
const WANDERER_MAX_DISTANCE := 9.0
const WANDERER_STAY := 240.0         # seconds before he leaves, unless someone answers his riddle first
const WANDERER_MEET := 5.0           # a player this close has met him (the Secret Book)
const WANDERER_REACH := 6.0          # answers count only from this close (checked by the host)
const WANDERER_TRIES := 8            # directions tried for a spot at the player's level
const WANDERER_LEVEL := 2.5          # blocks up or down from the player's feet
const STAR_EVERY := 2                # about one night in 2 (the first night always)
const STAR_MIN_DISTANCE := 20.0
const STAR_MAX_DISTANCE := 40.0
const STAR_DELAY := Vector2(20.0, 100.0)   # seconds after nightfall
const STAR_FALL_TIME := 2.2          # seconds from the sky to the ground
const STAR_REACH := 5.0              # a player this close has found the fallen star
## What a meteor may land in: air and natural ground (it never smashes a build, water or a tree trunk).
const METEOR_REPLACES: Array[int] = [BlockIds.AIR, BlockIds.GRASS, BlockIds.DIRT, BlockIds.SAND, BlockIds.STONE,
	BlockIds.LEAVES, BlockIds.DEEPSTONE, BlockIds.SANDSTONE, BlockIds.RED_SAND, BlockIds.RED_SANDSTONE,   # + BlockIds.DESERT_GROUND
	BlockIds.SNOW, BlockIds.SNOWY_GRASS, BlockIds.ICE, BlockIds.PINE_NEEDLES,   # + BlockIds.FROST_GROUND (M3 Task 3)
	BlockIds.FROSTING, BlockIds.CAKE, BlockIds.CHOCOLATE, BlockIds.GUMDROP, BlockIds.RED_GUMDROP, BlockIds.CREAM,
	BlockIds.JAM, BlockIds.SPRINKLES, BlockIds.COTTON_CANDY,   # + BlockIds.CANDY_GROUND and cotton candy (M3 Task 4)
	BlockIds.SKY_GRASS, BlockIds.FLOATSTONE, BlockIds.DEEP_FLOATSTONE, BlockIds.CLOUD,   # + BlockIds.DRAGON_GROUND and clouds (owner 39)
	BlockIds.MUD, BlockIds.FLOWERS, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LEAVES,   # + the wild meadows' (owner #45b)
	BlockIds.MOON_DUST, BlockIds.MOON_ROCK, BlockIds.DEEP_MOON_ROCK, BlockIds.MOON_CRYSTAL,   # + BlockIds.SPACE_GROUND (owner #55)
	BlockIds.BOING_MOSS, BlockIds.BOING_SOIL, BlockIds.BOING_ROCK, BlockIds.JELLY, BlockIds.PRISM_GRASS, BlockIds.RAINBOW_RED,
	BlockIds.RAINBOW_ORANGE, BlockIds.RAINBOW_YELLOW, BlockIds.RAINBOW_GREEN, BlockIds.RAINBOW_BLUE, BlockIds.RAINBOW_VIOLET,
	BlockIds.MARS_DUST, BlockIds.MARS_REGOLITH, BlockIds.BASALT, BlockIds.DEEP_BASALT, BlockIds.MARS_SEDIMENT,   # cosmos: Mars
	BlockIds.POLAR_ICE, BlockIds.DRY_ICE, BlockIds.GYPSUM,
	BlockIds.EUROPA_ICE, BlockIds.LINEA_ICE, BlockIds.BAND_ICE, BlockIds.DEEP_ICE, BlockIds.EUROPA_ROCK,   # cosmos: Europa
	BlockIds.GLOW_ICE, BlockIds.SALT,
	BlockIds.SULPHUR, BlockIds.ORANGE_SULPHUR, BlockIds.SULPHUR_FROST, BlockIds.RED_SULPHUR, BlockIds.IO_ROCK,   # cosmos: Io
	BlockIds.BLACK_LAVA, BlockIds.LAVA_CRUST, BlockIds.SULPHUR_CRYSTAL,
	BlockIds.TITAN_SOIL, BlockIds.ICE_PEBBLES, BlockIds.DUNE_SAND, BlockIds.WET_SHORE, BlockIds.ICY_ROCK,   # cosmos: Titan
	BlockIds.SHORE_CRYSTAL,
	BlockIds.MERCURY_DUST, BlockIds.MERCURY_ROCK, BlockIds.DARK_DUST, BlockIds.RAY_DUST, BlockIds.SHADOW_ICE,   # Mercury
	BlockIds.ICE_CRYSTAL,
	BlockIds.VENUS_CLOUD, BlockIds.DEEP_CLOUD, BlockIds.CLOUD_DECK, BlockIds.FLOAT_HULL, BlockIds.SKY_TURF,   # Venus's city
	BlockIds.CLOUD_CRYSTAL,
	BlockIds.RING_ICE, BlockIds.RING_FROST, BlockIds.DUSTY_ICE, BlockIds.RING_ROCK, BlockIds.MOONLET_ICE,   # Saturn's rings
	BlockIds.RIDGE_DUST, BlockIds.RING_CRYSTAL,
	BlockIds.NITROGEN_ICE, BlockIds.CELL_EDGE, BlockIds.WATER_ICE, BlockIds.PLUTO_FROST, BlockIds.THOLIN_DUST,   # Pluto
	BlockIds.RED_ICE, BlockIds.METHANE_SNOW, BlockIds.FROST_CRYSTAL,
	BlockIds.TRITON_FROST, BlockIds.PINK_ICE, BlockIds.MOTTLED_ICE, BlockIds.GEYSER_DUST, BlockIds.CANTALOUPE_ICE,   # Triton
	BlockIds.RIDGE_ICE, BlockIds.ICE_LAVA, BlockIds.NITROGEN_CRYSTAL,
	BlockIds.GROOVED_ICE, BlockIds.TROUGH_ICE, BlockIds.DARK_ICE, BlockIds.OLD_ICE, BlockIds.RAY_ICE,   # Ganymede
	BlockIds.POLAR_FROST, BlockIds.AURORA_CRYSTAL,
	BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS, BlockIds.LAKE_STONE, BlockIds.FLOWSTONE,   # + BlockIds.GLOW_GROUND (universe 6)
	BlockIds.STALAGMITE]
const GOLDEN_ONE_IN := 20            # herds whose first animal is golden
const GOLDEN_FLEE := 7.0             # a golden animal runs from any player this close
const GOLDEN_SPEED := 1.4            # × its species' speed while running ...
const GOLDEN_MAX_SPEED := 5.0        # ... but slower than a walking child (Player.WALK_SPEED 6)
const GOLDEN_SLIME_ONE_IN := 20      # Survivor night slimes that come golden (§12.16 #4)
const CHIME_DISTANCE := 12.0         # a secret this close chimes, once (a hint, not a pointer)
const _NO_SPOT := {}


## Does the Wanderer visit on the world's n-th dusk (counted from 1)?
static func wanderer_visits(world_seed: int, dusk: int) -> bool:
	return dusk == 1 or _mix(world_seed, dusk, 1) % WANDERER_EVERY == 0


## Which of Riddles.WANDERER_RIDDLES he asks on that dusk.
static func wanderer_riddle(world_seed: int, dusk: int) -> int:
	return _mix(world_seed, dusk, 2) % Riddles.WANDERER_RIDDLES.size()


## Where he might appear (x, z) around a player at `near`; each try is another direction.
static func wanderer_spot(world_seed: int, dusk: int, near: Vector3, attempt: int = 0) -> Vector2:
	var a := (_mix(world_seed, dusk, 3) % 3600) / 3600.0 * TAU + attempt * TAU / WANDERER_TRIES
	var d := lerpf(WANDERER_MIN_DISTANCE, WANDERER_MAX_DISTANCE, (_mix(world_seed, dusk, 4) % 1000) / 1000.0)
	return Vector2(near.x + cos(a) * d, near.z + sin(a) * d)


## Where he appears: the first try whose ground (standing_y(x, z): where feet stand in that column) is
## about as high as the player's feet and that the player can see (sees(eye, head) -> bool, when given),
## so he is never on a roof or behind a wall. {"pos": feet position} or {} when no try fits.
static func wanderer_place(world_seed: int, dusk: int, near: Vector3, standing_y: Callable,
		sees: Callable = Callable()) -> Dictionary:
	for attempt in WANDERER_TRIES:
		var spot := wanderer_spot(world_seed, dusk, near, attempt)
		var x := floori(spot.x)
		var z := floori(spot.y)
		var y: int = standing_y.call(x, z)
		var pos := Vector3(x + 0.5, y, z + 0.5)
		if absf(y - near.y) <= WANDERER_LEVEL \
				and (sees.is_null() or sees.call(near + Vector3(0, 1.5, 0), pos + Vector3(0, 1.5, 0))):
			return {"pos": pos}
	return {}


static func is_right_answer(riddle: int, choice: int) -> bool:
	return choice >= 0 and choice < 3 and choice == int(Riddles.wanderer_riddle(riddle).answer)


## Does a star fall on the world's n-th night (counted from 1)?
static func star_falls(world_seed: int, night: int) -> bool:
	return night == 1 or _mix(world_seed, night, 5) % STAR_EVERY == 0


## Seconds after nightfall that it falls.
static func star_delay(world_seed: int, night: int) -> float:
	return lerpf(STAR_DELAY.x, STAR_DELAY.y, (_mix(world_seed, night, 6) % 1000) / 1000.0)


## Where it lands near a player at `near`: {"ground": the first air cell above dry ground}, or {} when
## every try is water. height_at(x, z) -> the ground height there (the generator's).
static func star_spot(world_seed: int, night: int, near: Vector3, height_at: Callable) -> Dictionary:
	var a0 := (_mix(world_seed, night, 7) % 3600) / 3600.0 * TAU
	var d := lerpf(STAR_MIN_DISTANCE, STAR_MAX_DISTANCE, (_mix(world_seed, night, 8) % 1000) / 1000.0)
	for i in 8:
		var a := a0 + i * TAU / 8.0
		var x := floori(near.x + cos(a) * d)
		var z := floori(near.z + sin(a) * d)
		var h: int = height_at.call(x, z)
		if h > MeadowsShape.SEA_LEVEL + 1:
			return {"ground": Vector3i(x, h, z)}
	return _NO_SPOT


## The fallen star: a lump of dark rock with glowing crystals in a scorched patch, around `ground` (the
## first air cell above the ground). [[cell, block id], ...]
static func meteor_blocks(ground: Vector3i) -> Array:
	var out: Array = []
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			out.append([ground + Vector3i(dx, -1, dz), BlockIds.DEEPSTONE])
	out.append([ground, BlockIds.CRYSTAL])
	for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		out.append([ground + d, BlockIds.DEEPSTONE])
	out.append([ground + Vector3i(1, 0, 1), BlockIds.CRYSTAL])
	out.append([ground + Vector3i(-1, 0, -1), BlockIds.CRYSTAL])
	out.append([ground + Vector3i.UP, BlockIds.CRYSTAL])
	return out


## May a meteor's block go where `id` is? Only into air and natural ground, never into a build.
static func meteor_may_replace(id: int) -> bool:
	return METEOR_REPLACES.has(id)


## Is the animal with this id golden? Only the first animal of a wild herd (AnimalRules ids "a<x>_<z>_0"),
## about one herd in GOLDEN_ONE_IN; never a summoned animal or a pet.
static func is_golden(world_seed: int, animal_id: String) -> bool:
	if not animal_id.begins_with("a") or not animal_id.ends_with("_0"):
		return false
	return _mix(world_seed, hash(animal_id), 9) % GOLDEN_ONE_IN == 0


## Where a golden animal at `at` runs: away from the nearest player within GOLDEN_FLEE, or ZERO.
static func golden_flee(at: Vector3, players: Array[Vector3]) -> Vector3:
	var best := GOLDEN_FLEE
	var away := Vector3.ZERO
	for p in players:
		var d := Vector3(at.x - p.x, 0.0, at.z - p.z)
		if d.length() < best and d.length() > 0.001:
			best = d.length()
			away = d.normalized()
	return away


static func golden_speed(species_speed: float) -> float:
	return minf(species_speed * GOLDEN_SPEED, GOLDEN_MAX_SPEED)


## A step on plate `plate` of a temple whose riddle says `order`; progress: the plates stepped on in the
## right order so far. {"progress": the new progress, "result": &"ok", &"wrong" or &"solved"}.
## A wrong step makes the plates pop back up; if it was the first plate of the order, it counts again.
static func press_plate(progress: Array[int], plate: int, order: Array) -> Dictionary:
	var next: Array[int] = progress.duplicate()
	if next.size() < order.size() and plate == int(order[next.size()]):
		next.append(plate)
		return {"progress": next, "result": &"solved" if next.size() == order.size() else &"ok"}
	var restart: Array[int] = []
	if not order.is_empty() and plate == int(order[0]):
		restart.append(plate)
	return {"progress": restart, "result": &"wrong"}


## Does a player at `pos` hear the secret at `anchor` chime?
static func should_chime(pos: Vector3, anchor: Vector3i) -> bool:
	return pos.distance_to(Vector3(anchor) + Vector3(0.5, 0.5, 0.5)) <= CHIME_DISTANCE


## The treasure map's arrow: {"angle": radians from straight ahead (positive to the right), "distance":
## whole blocks sideways} from `from` to `to` for a camera turned to `yaw` (yaw 0 looks along -Z).
static func compass(from: Vector3, to: Vector3, yaw: float) -> Dictionary:
	var d := Vector2(to.x - from.x, to.z - from.z)
	var forward := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(cos(yaw), -sin(yaw))
	return {"angle": atan2(d.dot(right), d.dot(forward)), "distance": roundi(d.length())}


static func _mix(world_seed: int, n: int, salt: int) -> int:
	var h := world_seed * 2654435761 ^ n * 40503 ^ salt * 2246822519 ^ 0x6c8e9cf5
	h = (h ^ (h >> 15)) * 2246822519
	h = (h ^ (h >> 13)) * 3266489917
	return (h ^ (h >> 16)) & 0x7fffffffffffffff


## Is a Survivor night slime golden, for a random `roll`? About one in GOLDEN_SLIME_ONE_IN; Sandbox has
## golden animals instead.
static func golden_slime(roll: int, survivor: bool) -> bool:
	return survivor and posmod(roll, GOLDEN_SLIME_ONE_IN) == 0

