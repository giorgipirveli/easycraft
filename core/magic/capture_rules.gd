class_name CaptureRules
extends RefCounted
## Magic Wand capture: the connected build around a tapped block (6-neighbour flood fill).
## Natural ground (grass, dirt, stone, sand, water, the underground and its ores) never comes
## alive; trees and crystals can.

const MAX_BLOCKS := 200
const MAX_RADIUS := 8
const GROUND: Array[int] = [BlockIds.GRASS, BlockIds.DIRT, BlockIds.STONE, BlockIds.SAND, BlockIds.WATER,
	BlockIds.DEEPSTONE, BlockIds.BEDROCK, BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND,
	BlockIds.SANDSTONE, BlockIds.RED_SAND, BlockIds.RED_SANDSTONE, BlockIds.TRAP_SAND,   # M3 Task 2: the desert's ground
	BlockIds.SNOW, BlockIds.SNOWY_GRASS, BlockIds.ICE, BlockIds.FAKE_SNOW,   # M3 Task 3: Frostpeak's ground (+ its secret floor)
	BlockIds.FROSTING, BlockIds.CAKE, BlockIds.CHOCOLATE, BlockIds.GUMDROP, BlockIds.RED_GUMDROP, BlockIds.CREAM,
	BlockIds.JAM, BlockIds.SPRINKLES, BlockIds.FAKE_CHOCOLATE,   # M3 Task 4: the Candy Kingdom's (BlockIds.CANDY_GROUND)
	BlockIds.SKY_GRASS, BlockIds.FLOATSTONE, BlockIds.DEEP_FLOATSTONE, BlockIds.FAKE_FLOATSTONE,
	BlockIds.CLOUD,   # owner 39: the Dragon Realm's ground (BlockIds.DRAGON_GROUND), its secret door and clouds
	BlockIds.MUD, BlockIds.PATH,   # owner #45b: the wild meadows' ground (BlockIds.MEADOWS_GROUND)
	BlockIds.MOON_DUST, BlockIds.MOON_ROCK, BlockIds.DEEP_MOON_ROCK, BlockIds.FAKE_MOON_ROCK,   # owner #55: space (BlockIds.SPACE_GROUND)
	BlockIds.BOING_MOSS, BlockIds.BOING_SOIL, BlockIds.BOING_ROCK, BlockIds.JELLY, BlockIds.FAKE_BOING_ROCK, BlockIds.PRISM_GRASS,
	BlockIds.RAINBOW_RED, BlockIds.RAINBOW_ORANGE, BlockIds.RAINBOW_YELLOW, BlockIds.RAINBOW_GREEN, BlockIds.RAINBOW_BLUE,
	BlockIds.RAINBOW_VIOLET, BlockIds.FAKE_RAINBOW,
	BlockIds.MARS_DUST, BlockIds.MARS_REGOLITH, BlockIds.BASALT, BlockIds.DEEP_BASALT, BlockIds.MARS_SEDIMENT,   # cosmos: Mars
	BlockIds.POLAR_ICE, BlockIds.DRY_ICE, BlockIds.FAKE_BASALT,
	BlockIds.EUROPA_ICE, BlockIds.LINEA_ICE, BlockIds.BAND_ICE, BlockIds.DEEP_ICE, BlockIds.EUROPA_ROCK,   # cosmos: Europa
	BlockIds.FAKE_DEEP_ICE,
	BlockIds.SULPHUR, BlockIds.ORANGE_SULPHUR, BlockIds.SULPHUR_FROST, BlockIds.RED_SULPHUR, BlockIds.IO_ROCK,   # cosmos: Io
	BlockIds.BLACK_LAVA, BlockIds.FAKE_IO_ROCK,
	BlockIds.TITAN_SOIL, BlockIds.ICE_PEBBLES, BlockIds.DUNE_SAND, BlockIds.WET_SHORE, BlockIds.ICY_ROCK,   # cosmos: Titan
	BlockIds.FAKE_ICY_ROCK,
	BlockIds.MERCURY_DUST, BlockIds.MERCURY_ROCK, BlockIds.DARK_DUST, BlockIds.RAY_DUST, BlockIds.SHADOW_ICE,   # Mercury
	BlockIds.FAKE_MERCURY_ROCK,
	BlockIds.VENUS_CLOUD, BlockIds.DEEP_CLOUD, BlockIds.CLOUD_DECK, BlockIds.FLOAT_HULL, BlockIds.SKY_TURF,   # Venus's city
	BlockIds.FAKE_FLOAT_HULL,
	BlockIds.RING_ICE, BlockIds.RING_FROST, BlockIds.DUSTY_ICE, BlockIds.RING_ROCK, BlockIds.MOONLET_ICE,   # Saturn's rings
	BlockIds.RIDGE_DUST, BlockIds.FAKE_RING_ICE,
	BlockIds.NITROGEN_ICE, BlockIds.CELL_EDGE, BlockIds.WATER_ICE, BlockIds.PLUTO_FROST, BlockIds.THOLIN_DUST,   # Pluto
	BlockIds.RED_ICE, BlockIds.METHANE_SNOW, BlockIds.FAKE_WATER_ICE,
	BlockIds.TRITON_FROST, BlockIds.PINK_ICE, BlockIds.MOTTLED_ICE, BlockIds.GEYSER_DUST, BlockIds.CANTALOUPE_ICE,   # Triton
	BlockIds.RIDGE_ICE, BlockIds.ICE_LAVA, BlockIds.FAKE_PINK_ICE,
	BlockIds.GROOVED_ICE, BlockIds.TROUGH_ICE, BlockIds.DARK_ICE, BlockIds.OLD_ICE, BlockIds.RAY_ICE,   # Ganymede
	BlockIds.POLAR_FROST, BlockIds.FAKE_GROOVED_ICE,
	BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS, BlockIds.LAKE_STONE, BlockIds.FLOWSTONE,   # universe 6 (BlockIds.GLOW_GROUND)
	BlockIds.FAKE_CAVE_STONE, BlockIds.STALACTITE, BlockIds.STALAGMITE,   # its hidden door, its dripstone
	BlockIds.FAKE_LIMESTONE, BlockIds.FAKE_MARBLE, BlockIds.FAKE_BABYLON_BRICK,   # owner #78: the wonders' hidden doors
	BlockIds.FAKE_WALL_BRICK, BlockIds.FAKE_TRAVERTINE, BlockIds.FAKE_MAYA_STONE, BlockIds.FAKE_INCA_STONE,   # the New Seven's
	BlockIds.FAKE_WHITE_BRICK,
	BlockIds.PAD_CONCRETE, BlockIds.PAD_STRIPE,   # spec §21d: a Launch Site's pad (a rocket on it wakes alone)
	BlockIds.GOLD_QUARTZ, BlockIds.GOLD_GRAVEL, BlockIds.COPPER_ORE, BlockIds.MALACHITE, BlockIds.BANDED_IRON,   # spec §26:
	BlockIds.RUSTY_ROCK, BlockIds.FERN_SHALE, BlockIds.OIL_SEEP, BlockIds.ROCK_SALT, BlockIds.SALT_CRUST,   # the riches' ground
	BlockIds.ICY_REGOLITH, BlockIds.MARE_DUST, BlockIds.ILMENITE, BlockIds.KREEP_ROCK, BlockIds.IRON_METEORITE,   # §26.5:
	BlockIds.GROUND_ICE, BlockIds.BLUEBERRY_SOIL, BlockIds.HEMATITE, BlockIds.DARK_SAND, BlockIds.MARS_SALT]   # space's
const _NEIGHBOURS: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]


static func is_capturable(id: int) -> bool:
	return id != BlockIds.AIR and BlockIds.is_valid(id) and not GROUND.has(id)


## Returns {"blocks": {Vector3i: id}} or {"error": "not_a_build" | "too_big"}.
## get_block: func(pos: Vector3i) -> int.
static func capture(start: Vector3i, get_block: Callable) -> Dictionary:
	if not is_capturable(get_block.call(start)):
		return {"error": "not_a_build"}
	var blocks := {}
	var queue: Array[Vector3i] = [start]
	blocks[start] = get_block.call(start)
	while not queue.is_empty():
		var p: Vector3i = queue.pop_back()
		for n in _NEIGHBOURS:
			var q: Vector3i = p + n
			if blocks.has(q):
				continue
			var id: int = get_block.call(q)
			if not is_capturable(id):
				continue
			var d := q - start
			if maxi(absi(d.x), maxi(absi(d.y), absi(d.z))) > MAX_RADIUS:
				return {"error": "too_big"}
			blocks[q] = id
			if blocks.size() > MAX_BLOCKS:
				return {"error": "too_big"}
			queue.append(q)
	return {"blocks": blocks}


static func message(code: String) -> String:
	match code:
		"not_a_build":
			return "Build something first, then tap it with the wand!"
		"too_big":
			return Lang.t("Too big for the magic! Try something smaller (max %d blocks).") % MAX_BLOCKS
		_:
			return ""
