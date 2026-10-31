class_name GatherRules
extends RefCounted
## Survivor gathering (M2 §12.2): what breaking a block gives, which pickaxe it needs, and what one
## cell change costs or gives back. Pure rules; GatherLedger applies them to a player's Inventory.

## Pickaxe tiers (spec §12.6): none, then wood -> cosmic. The M1b pickaxe is the wood tier.
const NONE := 0
const WOOD := 1
const STONE := 2
const IRON := 3
const CRYSTAL := 4
const COSMIC := 5
const PICKAXE_TIERS := {ItemIds.PICKAXE: WOOD, ItemIds.PICKAXE_STONE: STONE, ItemIds.PICKAXE_IRON: IRON,
	ItemIds.PICKAXE_CRYSTAL: CRYSTAL, ItemIds.PICKAXE_COSMIC: COSMIC}
## Ores and the pickaxe tier they need; every other block breaks by hand.
const NEEDS_TIER := {BlockIds.COAL: WOOD, BlockIds.IRON: WOOD, BlockIds.GOLD: IRON, BlockIds.DIAMOND: IRON,
	BlockIds.CRYSTAL: IRON, BlockIds.FROZEN_ORE: WOOD,
	# Spec §26 (prospecting): a rich deposit's ore needs the pickaxe its plain ore needs; rock salt and shale are rock.
	BlockIds.GOLD_QUARTZ: IRON, BlockIds.COPPER_ORE: WOOD, BlockIds.MALACHITE: WOOD, BlockIds.BANDED_IRON: WOOD,
	BlockIds.ROCK_SALT: WOOD, BlockIds.FERN_SHALE: WOOD,
	# Spec §26.5: space's ores need a pickaxe like iron's (the meteorite is iron; frozen icy dust is hard as rock); mare
	# dust, blueberry soil, dark sand and the salt crust come by hand.
	BlockIds.ICY_REGOLITH: WOOD, BlockIds.ILMENITE: WOOD, BlockIds.KREEP_ROCK: WOOD, BlockIds.IRON_METEORITE: WOOD,
	BlockIds.GROUND_ICE: WOOD, BlockIds.HEMATITE: WOOD}
## What breaking gives when it is not the block itself (AIR: nothing).
const DROPS := {BlockIds.GRASS: BlockIds.DIRT, BlockIds.LEAVES: BlockIds.AIR, BlockIds.WATER: BlockIds.AIR,
	BlockIds.BEDROCK: BlockIds.AIR, BlockIds.DOOR_OPEN: BlockIds.DOOR,
	BlockIds.FAKE_WALL: BlockIds.STONE,   # secrets are stone (M2 Task 16)
	# M3 Task 7: a pressure plate is a smart block a child buys and places, so it gives a plate back (a
	# temple's plates too: Tilly never buys them); a smart block's on state is its plain block.
	BlockIds.BUTTON_ON: BlockIds.BUTTON, BlockIds.LEVER_ON: BlockIds.LEVER, BlockIds.LIGHT_SWITCH_ON: BlockIds.LIGHT_SWITCH,
	BlockIds.LAMP_ON: BlockIds.LAMP, BlockIds.POWERED_DOOR_OPEN: BlockIds.POWERED_DOOR,
	# M3 Task 2: the desert's secret-built blocks give what they look like; palm fronds are leaves
	BlockIds.TRAP_SAND: BlockIds.SAND, BlockIds.FAKE_SANDSTONE: BlockIds.SANDSTONE,
	BlockIds.ARROW_SLIT: BlockIds.CUT_SANDSTONE, BlockIds.PALM_LEAVES: BlockIds.AIR,
	# M3 Task 3: Frostpeak's secret floor is packed snow; snowy grass is grass; pine needles are leaves
	BlockIds.FAKE_SNOW: BlockIds.PACKED_SNOW, BlockIds.SNOWY_GRASS: BlockIds.DIRT, BlockIds.PINE_NEEDLES: BlockIds.AIR,
	BlockIds.FAKE_CHOCOLATE: BlockIds.CHOCOLATE,   # M3 Task 4: the Candy Kingdom's hidden door is chocolate
	# owner 39: the Dragon Realm's hidden door is floatstone; its moss is floatstone underneath (like grass)
	BlockIds.FAKE_FLOATSTONE: BlockIds.FLOATSTONE, BlockIds.SKY_GRASS: BlockIds.FLOATSTONE,
	BlockIds.BIRCH_LEAVES: BlockIds.AIR, BlockIds.DARK_LEAVES: BlockIds.AIR,   # owner #45b: leaves, like oak leaves
	BlockIds.FAKE_MOON_ROCK: BlockIds.MOON_ROCK,   # owner #55: the Moon's hidden door is moon rock
	BlockIds.FAKE_BOING_ROCK: BlockIds.BOING_ROCK, BlockIds.FAKE_RAINBOW: BlockIds.RAINBOW_BLUE,   # the planets' doors
	BlockIds.BOING_MOSS: BlockIds.BOING_SOIL,   # boing moss is soil underneath (like grass)
	BlockIds.FAKE_BASALT: BlockIds.BASALT,   # cosmos: Mars's hidden door is basalt
	BlockIds.FAKE_DEEP_ICE: BlockIds.DEEP_ICE,   # cosmos: Europa's hidden door is deep ice
	BlockIds.FAKE_IO_ROCK: BlockIds.IO_ROCK,   # cosmos: Io's hidden door is Io rock
	BlockIds.FAKE_ICY_ROCK: BlockIds.ICY_ROCK,   # cosmos: Titan's hidden door is icy rock
	BlockIds.FAKE_MERCURY_ROCK: BlockIds.MERCURY_ROCK,   # cosmos: Mercury's hidden door is Mercury rock
	BlockIds.FAKE_FLOAT_HULL: BlockIds.FLOAT_HULL,   # cosmos: Venus's hidden door is a float hull
	BlockIds.FAKE_RING_ICE: BlockIds.RING_ICE,   # cosmos: the rings' hidden door is ring ice
	BlockIds.FAKE_WATER_ICE: BlockIds.WATER_ICE,   # cosmos: Pluto's hidden door is water ice
	BlockIds.FAKE_PINK_ICE: BlockIds.PINK_ICE,   # cosmos: Triton's hidden door is pink ice
	BlockIds.FAKE_GROOVED_ICE: BlockIds.GROOVED_ICE,   # cosmos: Ganymede's hidden door is grooved ice
	BlockIds.FAKE_CAVE_STONE: BlockIds.CAVE_STONE,   # universe 6: the Glow Caves' hidden door is cave stone
	BlockIds.FAKE_LIMESTONE: BlockIds.LIMESTONE, BlockIds.FAKE_MARBLE: BlockIds.MARBLE,   # owner #78: the wonders'
	BlockIds.FAKE_BABYLON_BRICK: BlockIds.BABYLON_BRICK, BlockIds.OLIVE_LEAVES: BlockIds.AIR,   # doors; leaves
	BlockIds.FAKE_WALL_BRICK: BlockIds.WALL_BRICK, BlockIds.FAKE_TRAVERTINE: BlockIds.TRAVERTINE,   # the New Seven's doors
	BlockIds.FAKE_MAYA_STONE: BlockIds.MAYA_STONE, BlockIds.FAKE_INCA_STONE: BlockIds.INCA_STONE,
	BlockIds.FAKE_WHITE_BRICK: BlockIds.WHITE_BRICK}

const NEED_PICKAXE_MESSAGE := "You need a pickaxe for this!"
const NEED_IRON_MESSAGE := "You need an iron pickaxe for this!"


## The tier of a pickaxe item (NONE for anything else).
static func tier_of(item_id: int) -> int:
	return PICKAXE_TIERS.get(item_id, NONE)


## The best pickaxe in the inventory (NONE without one).
static func pickaxe_tier(inv: Inventory) -> int:
	var best := NONE
	for id: int in PICKAXE_TIERS:
		if inv.count(id) > 0:
			best = maxi(best, PICKAXE_TIERS[id])
	return best


## Why a player whose best pickaxe is `tier` can't break block_id ("" = they can).
static func refusal(block_id: int, tier: int) -> String:
	var need: int = NEEDS_TIER.get(block_id, NONE)
	if tier >= need:
		return ""
	return NEED_IRON_MESSAGE if need >= IRON else NEED_PICKAXE_MESSAGE


static func can_break(block_id: int, tier: int) -> bool:
	return refusal(block_id, tier) == ""


## What breaking block_id gives: a block id, or AIR for nothing (also when the pickaxe is too weak).
static func drop(block_id: int, tier: int) -> int:
	if block_id == BlockIds.AIR or not can_break(block_id, tier):
		return BlockIds.AIR
	if CrystalRules.is_universe_core(block_id):
		return CrystalRules.item_for_core(block_id)   # owner 39: a universe core gives its crystal back
	return DROPS.get(block_id, block_id)


## What placing block_id uses up (an open door is a door; M3 Task 7: a smart block's on state is its plain block).
static func cost(block_id: int) -> int:
	if CrystalRules.is_universe_core(block_id):
		return CrystalRules.item_for_core(block_id)   # owner 39: placing a universe core uses its crystal
	return BlockIds.DOOR if block_id == BlockIds.DOOR_OPEN else PowerRules.item_of(block_id)


## What changing one cell from `old` to `new` does to the player's blocks: {id: +given / -taken}.
## An edit breaks `old` (it gives its drop) and places `new` (it uses one). An undo is the exact
## reverse of the edit it undoes: the block it removes comes back as itself (never as its drop, and
## no pickaxe needed), and a block it puts back costs what breaking that block gave.
## The pickaxe gate is not checked here (see refusal).
static func change(old: int, new: int, is_undo: bool, tier: int) -> Dictionary:
	var delta := {}
	if old == new:
		return delta
	if old != BlockIds.AIR:
		_add(delta, cost(old) if is_undo else drop(old, tier), 1)
	if new != BlockIds.AIR:
		_add(delta, drop(new, COSMIC) if is_undo else cost(new), -1)
	return delta


static func _add(delta: Dictionary, id: int, n: int) -> void:
	if id == BlockIds.AIR:
		return
	var sum: int = delta.get(id, 0) + n
	if sum == 0:
		delta.erase(id)
	else:
		delta[id] = sum
