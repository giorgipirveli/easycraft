class_name ItemIds
extends RefCounted
## Magic items that can sit in hotbar slots next to blocks. Ids start at 100 so they never
## collide with block ids.

const WAND := 100
const STAMP_HOUSE := 101
const STAMP_TOWER := 102
const STAMP_BRIDGE := 103
const STAMP_TREE := 104
const STAMP_RAINBOW := 105
# Weapons and tools (M1b Task 11; stats in core/rules/weapon_rules.gd) and placeable targets.
const SWORD := 110
const BOW := 111
const BOOMERANG := 112
const HAMMER := 113
const AXE := 114
const PICKAXE := 115
const DUMMY := 116       # places a practice dummy
const BULLSEYE := 117    # places an archery target
# Spear and mace (M2 Task 6, owner feedback #22, spec §13.1): the wood tier; the others are below.
const SPEAR := 118
const MACE := 119
# Tool tiers (M2 §12.6; behaviour in Task 6): the M1b sword, bow, pickaxe and axe are the wood tier.
const SWORD_STONE := 121
const SWORD_IRON := 122
const SWORD_CRYSTAL := 123
const SWORD_COSMIC := 124
const BOW_STONE := 126
const BOW_IRON := 127
const BOW_CRYSTAL := 128
const BOW_COSMIC := 129
const PICKAXE_STONE := 131
const PICKAXE_IRON := 132
const PICKAXE_CRYSTAL := 133
const PICKAXE_COSMIC := 134
const AXE_STONE := 136
const AXE_IRON := 137
const AXE_CRYSTAL := 138
const AXE_COSMIC := 139
const SHIELD_WOOD := 140
const SHIELD_STONE := 141
const SHIELD_IRON := 142
const SHIELD_CRYSTAL := 143
const SHIELD_COSMIC := 144
# Potions (M2 §12.6; one use): Moon Jump, Invisibility, Speed.
const POTION_JUMP := 150
const POTION_INVIS := 151
const POTION_SPEED := 152
# Spear and mace tiers (M2 Task 6).
const SPEAR_STONE := 161
const SPEAR_IRON := 162
const SPEAR_CRYSTAL := 163
const SPEAR_COSMIC := 164
const MACE_STONE := 166
const MACE_IRON := 167
const MACE_CRYSTAL := 168
const MACE_COSMIC := 169

# Secrets and treasures (M2 Task 16): only ever found (in chests or from the Wanderer), never in the palette
# or a shop. The decorations are the blocks BlockIds.TROPHY and GOLD_LAMP themselves; the item ids 171 and
# 172 allocated for them stay unused (ruling in docs/devlog/parts/m2-task-16.md).
const TREASURE_MAP := 170   # while held, a compass arrow points to the nearest unopened buried treasure
# M4 Wave 3, agent I: gift stamps, a friend's build in this device's GiftStampBook (one id per slot, 460-479;
# M3 owns 400-450). Not catalogue items (not in ALL): never given, sold or listed in the MAGIC row.
const GIFT_STAMP_FIRST := 460
const GIFT_STAMP_SLOTS := 20
# M3 Task 20b: My Stamps, the child's own saved builds (MyStampBook, one id per slot, 495-499). Not catalogue items
# (not in ALL): never given, sold or listed in the MAGIC row; the palette's STAMPS page.
const MY_STAMP_FIRST := 495
const MY_STAMP_SLOTS := 5
# M3 Task 11: pet treats (430-434; PetRules). Every pet likes every treat; each kind has a favourite.
const TREAT_BISCUIT := 430   # dogs' favourite
const TREAT_FISH := 431      # cats'
const TREAT_BERRIES := 432   # foxes'
const TREAT_SEEDS := 433     # parrots'
const TREAT_BOLT := 434      # Pip the robot's: a shiny bolt

# --- Owner feedback #39: universe crystals (items 480-489; 485-489 kept for universes 6-10; CrystalRules) ---
## A crystal of each universe, earned by reaching it: placed in a portal frame's core slot it opens a portal to its
## universe. In ALL (a name and an icon, drawn in code: CrystalIcons); the Sandbox palette's PORTALS row lists the
## ones the child reached (CrystalRules.sandbox_crystals).
const CRYSTAL_MEADOWS := 480
const CRYSTAL_DESERT := 481
const CRYSTAL_FROST := 482
const CRYSTAL_CANDY := 483
const CRYSTAL_DRAGON := 484
const CRYSTAL_GLOW := 485         # universe 6, the Glow Caves
const CRYSTALS: Array[int] = [CRYSTAL_MEADOWS, CRYSTAL_DESERT, CRYSTAL_FROST, CRYSTAL_CANDY, CRYSTAL_DRAGON, CRYSTAL_GLOW]

# Survivor games and crafting (owner feedback #34, spec §12.19): things only ever crafted (ids 451-459, more in 490;
# 460-479 are M4 I's gift stamps, 480-489 universe crystals, 495-499 My Stamps (M3 Task 20b)).
const STICK := 451

# Blasters and their ammo (M3 Task 14b, spec §13.4): cartoon toy blasters, never real-world guns. One
# blaster per rarity (common to legendary); rules in core/rules/blaster_rules.gd. 425-429 stay free.
const FOAM_BLASTER := 415
const SNOWBALL_LAUNCHER := 416
const PAINT_SPLATTER := 417
const BUBBLE_CANNON := 418
const CONFETTI_ROCKET := 419
const FOAM_DARTS := 420
const SNOWBALLS := 421
const PAINT_BLOBS := 422
const BUBBLE_SOAP := 423
const PARTY_ROCKETS := 424

# The action kit's gadgets (M3 Task 14a, spec §13.3; our own designs): rules in core/rules/gadget_rules.gd.
# The glider works while it is owned (Survivor: in the bag; Sandbox: always); the rest are used from the hand.
# The zipline post and the launch pad are blocks (BlockIds 210-211). 408-411 are M3 Task 8's building tools;
# 412-414 stay free.
const GLIDER := 400
const GRAPPLE := 401         # the grappling hook
const BUILD_WALL := 402      # instant builds: one tap puts a build in front of you
const BUILD_FLOOR := 403
const BUILD_RAMP := 404
const BUILD_FORT := 405
const IMPULSE_ORB := 406     # thrown: a burst that pushes monsters away (and bounces players, never hurting them)
const DANCE_ORB := 407       # thrown: monsters in its bubble dance and don't attack

# M3 Task 8 (building tools, spec §14.5): the Sandbox power tools and Build Rewind, in the palette's BUILD tab.
# Ids 408-411 are the gadgets' free ids (M3 Task 14a left 408-414 free; the M3 plan gives Task 8 only 435-450,
# which the 16 paints fill: ruling in docs/devlog/parts/m3-task-8.md). Rules: core/building/power_tools.gd.
const LINE_TOOL := 408      # two taps: a straight line of the block held last
const FILL_TOOL := 409      # two taps: the box between them (at most 4,096 blocks), one undo
const COPY_TOOL := 410      # two taps copy a box (at most 16 on a side); then each tap pastes it, turned your way
const REWIND := 411         # records your building around a spot; tap again to watch it as a time-lapse
# M3 Task 8: the paint bucket's 16 tints (PaintRules): a tap paints a plain block (it becomes a painted block,
# BlockIds 240-255). Free in Sandbox and Survivor.
const PAINT_WHITE := 435
const PAINT_SILVER := 436
const PAINT_GREY := 437
const PAINT_BLACK := 438
const PAINT_BROWN := 439
const PAINT_RED := 440
const PAINT_ORANGE := 441
const PAINT_YELLOW := 442
const PAINT_LIME := 443
const PAINT_GREEN := 444
const PAINT_TEAL := 445
const PAINT_SKY := 446
const PAINT_BLUE := 447
const PAINT_PURPLE := 448
const PAINT_MAGENTA := 449
const PAINT_PINK := 450

const STAMPS: Array[int] = [STAMP_HOUSE, STAMP_TOWER, STAMP_BRIDGE, STAMP_TREE, STAMP_RAINBOW]
const MAGIC: Array[int] = [WAND, STAMP_HOUSE, STAMP_TOWER, STAMP_BRIDGE, STAMP_TREE, STAMP_RAINBOW]
const TOOLS: Array[int] = [SWORD, BOW, BOOMERANG, HAMMER, AXE, PICKAXE, DUMMY, BULLSEYE]
const TARGETS: Array[int] = [DUMMY, BULLSEYE]
const TIERED: Array[int] = [SWORD_STONE, SWORD_IRON, SWORD_CRYSTAL, SWORD_COSMIC, BOW_STONE, BOW_IRON,
	BOW_CRYSTAL, BOW_COSMIC, PICKAXE_STONE, PICKAXE_IRON, PICKAXE_CRYSTAL, PICKAXE_COSMIC, AXE_STONE, AXE_IRON,
	AXE_CRYSTAL, AXE_COSMIC, SHIELD_WOOD, SHIELD_STONE, SHIELD_IRON, SHIELD_CRYSTAL, SHIELD_COSMIC,
	SPEAR_STONE, SPEAR_IRON, SPEAR_CRYSTAL, SPEAR_COSMIC, MACE_STONE, MACE_IRON, MACE_CRYSTAL, MACE_COSMIC]
const POTIONS: Array[int] = [POTION_JUMP, POTION_INVIS, POTION_SPEED]
## M3 Task 11: pet treats (the palette's PETS page).
const TREATS: Array[int] = [TREAT_BISCUIT, TREAT_FISH, TREAT_BERRIES, TREAT_SEEDS, TREAT_BOLT]
## The palette's ARMORY page (M2 Task 6): every tier item that is not in the TOOLS row (the wood
## sword, bow, pickaxe and axe are), then the potions. Its rows come from WeaponRules.TIERS.
const ARMORY: Array[int] = [SPEAR, MACE, SWORD_STONE, SWORD_IRON, SWORD_CRYSTAL, SWORD_COSMIC, BOW_STONE, BOW_IRON,
	BOW_CRYSTAL, BOW_COSMIC, PICKAXE_STONE, PICKAXE_IRON, PICKAXE_CRYSTAL, PICKAXE_COSMIC, AXE_STONE, AXE_IRON,
	AXE_CRYSTAL, AXE_COSMIC, SHIELD_WOOD, SHIELD_STONE, SHIELD_IRON, SHIELD_CRYSTAL, SHIELD_COSMIC,
	SPEAR_STONE, SPEAR_IRON, SPEAR_CRYSTAL, SPEAR_COSMIC, MACE_STONE, MACE_IRON, MACE_CRYSTAL, MACE_COSMIC,
	POTION_JUMP, POTION_INVIS, POTION_SPEED]
## M3 Task 14b: the blasters (the ARMORY page's BLASTERS column, by rarity) and their ammo (Survivor only:
## bought from Tilly or found; Sandbox blasters never need any, so ammo has no palette row).
const BLASTERS: Array[int] = [FOAM_BLASTER, SNOWBALL_LAUNCHER, PAINT_SPLATTER, BUBBLE_CANNON, CONFETTI_ROCKET]
const AMMO: Array[int] = [FOAM_DARTS, SNOWBALLS, PAINT_BLOBS, BUBBLE_SOAP, PARTY_ROCKETS]
## M3 Task 14a: the gadgets (the ARMORY page's GADGETS box, with the zipline post and the launch pad).
const GADGETS: Array[int] = [GLIDER, GRAPPLE, IMPULSE_ORB, DANCE_ORB, BUILD_WALL, BUILD_FLOOR, BUILD_RAMP, BUILD_FORT]
## M3 Task 8: the power tools and Build Rewind (the palette's BUILD tab; Survivor gets REWIND) and the 16 paints.
const BUILD_TOOLS: Array[int] = [LINE_TOOL, FILL_TOOL, COPY_TOOL, REWIND]
const PAINTS: Array[int] = [PAINT_WHITE, PAINT_SILVER, PAINT_GREY, PAINT_BLACK, PAINT_BROWN, PAINT_RED, PAINT_ORANGE, PAINT_YELLOW,
	PAINT_LIME, PAINT_GREEN, PAINT_TEAL, PAINT_SKY, PAINT_BLUE, PAINT_PURPLE, PAINT_MAGENTA, PAINT_PINK]
## Treasure-only items: in ALL (hotbars and inventories hold them) but in no palette row.
const TREASURES: Array[int] = [TREASURE_MAP]
## Crafted-only things (spec §12.19): in ALL, in no palette row (Sandbox has everything already).
const CRAFTED: Array[int] = [STICK]
## Every usable item (each has a name and an icon; all but TREASURES have a palette row).
const ALL: Array[int] = [WAND, STAMP_HOUSE, STAMP_TOWER, STAMP_BRIDGE, STAMP_TREE, STAMP_RAINBOW,
	SWORD, BOW, BOOMERANG, HAMMER, AXE, PICKAXE, DUMMY, BULLSEYE,
	# M2 Task 6: tiers, spear, mace, shields and potions (their icons are in data/items/item_icons.png)
	SPEAR, MACE, SWORD_STONE, SWORD_IRON, SWORD_CRYSTAL, SWORD_COSMIC, BOW_STONE, BOW_IRON, BOW_CRYSTAL, BOW_COSMIC,
	PICKAXE_STONE, PICKAXE_IRON, PICKAXE_CRYSTAL, PICKAXE_COSMIC, AXE_STONE, AXE_IRON, AXE_CRYSTAL, AXE_COSMIC,
	SHIELD_WOOD, SHIELD_STONE, SHIELD_IRON, SHIELD_CRYSTAL, SHIELD_COSMIC,
	SPEAR_STONE, SPEAR_IRON, SPEAR_CRYSTAL, SPEAR_COSMIC, MACE_STONE, MACE_IRON, MACE_CRYSTAL, MACE_COSMIC,
	POTION_JUMP, POTION_INVIS, POTION_SPEED,
	# M2 Task 16: treasure-only
	TREASURE_MAP,
	# Survivor games and crafting: crafted-only
	STICK,
	# M3 Task 14b: blasters and ammo (their icons are drawn in code, BlasterIcons)
	FOAM_BLASTER, SNOWBALL_LAUNCHER, PAINT_SPLATTER, BUBBLE_CANNON, CONFETTI_ROCKET,
	FOAM_DARTS, SNOWBALLS, PAINT_BLOBS, BUBBLE_SOAP, PARTY_ROCKETS,

	# M3 Task 14a: gadgets (their icons: GadgetIcons)
	GLIDER, GRAPPLE, IMPULSE_ORB, DANCE_ORB, BUILD_WALL, BUILD_FLOOR, BUILD_RAMP, BUILD_FORT,
	# M3 Task 11: pet treats
	TREAT_BISCUIT, TREAT_FISH, TREAT_BERRIES, TREAT_SEEDS, TREAT_BOLT,
	# M3 Task 8: building tools and paints (their icons: BuildToolIcons)
	LINE_TOOL, FILL_TOOL, COPY_TOOL, REWIND,
	PAINT_WHITE, PAINT_SILVER, PAINT_GREY, PAINT_BLACK, PAINT_BROWN, PAINT_RED, PAINT_ORANGE, PAINT_YELLOW,
	PAINT_LIME, PAINT_GREEN, PAINT_TEAL, PAINT_SKY, PAINT_BLUE, PAINT_PURPLE, PAINT_MAGENTA, PAINT_PINK,
	# Owner feedback #39: universe crystals
	CRYSTAL_MEADOWS, CRYSTAL_DESERT, CRYSTAL_FROST, CRYSTAL_CANDY, CRYSTAL_DRAGON, CRYSTAL_GLOW]

const _NAMES := {
	WAND: "Magic Wand", STAMP_HOUSE: "House", STAMP_TOWER: "Tower",
	STAMP_BRIDGE: "Bridge", STAMP_TREE: "Big Tree", STAMP_RAINBOW: "Rainbow",
	SWORD: "Sword", BOW: "Bow", BOOMERANG: "Boomerang", HAMMER: "Hammer", AXE: "Axe", PICKAXE: "Pickaxe",
	DUMMY: "Practice Dummy", BULLSEYE: "Bullseye",
	SWORD_STONE: "Stone Sword", SWORD_IRON: "Iron Sword", SWORD_CRYSTAL: "Crystal Sword", SWORD_COSMIC: "Cosmic Sword",
	BOW_STONE: "Stone Bow", BOW_IRON: "Iron Bow", BOW_CRYSTAL: "Crystal Bow", BOW_COSMIC: "Cosmic Bow",
	PICKAXE_STONE: "Stone Pickaxe", PICKAXE_IRON: "Iron Pickaxe", PICKAXE_CRYSTAL: "Crystal Pickaxe",
	PICKAXE_COSMIC: "Cosmic Pickaxe", AXE_STONE: "Stone Axe", AXE_IRON: "Iron Axe", AXE_CRYSTAL: "Crystal Axe",
	AXE_COSMIC: "Cosmic Axe", SHIELD_WOOD: "Wooden Shield", SHIELD_STONE: "Stone Shield", SHIELD_IRON: "Iron Shield",
	SHIELD_CRYSTAL: "Crystal Shield", SHIELD_COSMIC: "Cosmic Shield",
	POTION_JUMP: "Moon Jump Potion", POTION_INVIS: "Invisibility Potion", POTION_SPEED: "Speed Potion",
	SPEAR: "Spear", MACE: "Mace", SPEAR_STONE: "Stone Spear", SPEAR_IRON: "Iron Spear", SPEAR_CRYSTAL: "Crystal Spear",
	SPEAR_COSMIC: "Cosmic Spear", MACE_STONE: "Stone Mace", MACE_IRON: "Iron Mace", MACE_CRYSTAL: "Crystal Mace",
	MACE_COSMIC: "Cosmic Mace",
	TREASURE_MAP: "Treasure Map",
	STICK: "Stick",
	FOAM_BLASTER: "Foam Blaster", SNOWBALL_LAUNCHER: "Snowball Launcher", PAINT_SPLATTER: "Paint Splatter",
	BUBBLE_CANNON: "Bubble Cannon", CONFETTI_ROCKET: "Confetti Rocket", FOAM_DARTS: "Foam Darts",
	SNOWBALLS: "Snowballs", PAINT_BLOBS: "Paint Blobs", BUBBLE_SOAP: "Bubble Soap", PARTY_ROCKETS: "Party Rockets",
	GLIDER: "Glider", GRAPPLE: "Grappling Hook", BUILD_WALL: "Quick Wall", BUILD_FLOOR: "Quick Floor",
	BUILD_RAMP: "Quick Ramp", BUILD_FORT: "Quick Fort", IMPULSE_ORB: "Boing Orb", DANCE_ORB: "Dance Orb",
	TREAT_BISCUIT: "Dog Biscuit", TREAT_FISH: "Fish Snack", TREAT_BERRIES: "Berries", TREAT_SEEDS: "Seed Cracker",
	TREAT_BOLT: "Shiny Bolt",
	LINE_TOOL: "Line", FILL_TOOL: "Fill", COPY_TOOL: "Copy", REWIND: "Rewind",
	PAINT_WHITE: "White Paint", PAINT_SILVER: "Silver Paint", PAINT_GREY: "Grey Paint", PAINT_BLACK: "Black Paint",
	PAINT_BROWN: "Brown Paint", PAINT_RED: "Red Paint", PAINT_ORANGE: "Orange Paint", PAINT_YELLOW: "Yellow Paint",
	PAINT_LIME: "Lime Paint", PAINT_GREEN: "Green Paint", PAINT_TEAL: "Teal Paint", PAINT_SKY: "Sky Blue Paint",
	PAINT_BLUE: "Blue Paint", PAINT_PURPLE: "Purple Paint", PAINT_MAGENTA: "Magenta Paint", PAINT_PINK: "Pink Paint",
	CRYSTAL_MEADOWS: "Meadows Crystal", CRYSTAL_DESERT: "Desert Crystal", CRYSTAL_FROST: "Frost Crystal",   # owner 39
	CRYSTAL_CANDY: "Candy Crystal", CRYSTAL_DRAGON: "Dragon Crystal", CRYSTAL_GLOW: "Glow Crystal",
	TELESCOPE: "Telescope", MAGNIFIER: "Magnifier",   # owner #110 (VR-WONDER)
}


static func is_item(id: int) -> bool:
	return ALL.has(id) or id == FARM or LENSES.has(id)   # M3 Task 10: the farm; owner #110: the lenses (VR's)


static func is_stamp(id: int) -> bool:
	return STAMPS.has(id) or is_gift_stamp(id) or is_my_stamp(id)   # M3 Task 20b: My Stamps


## A friend's build as a stamp (M4 I): GiftStampBook's slot id - GIFT_STAMP_FIRST.
static func is_gift_stamp(id: int) -> bool:
	return id >= GIFT_STAMP_FIRST and id < GIFT_STAMP_FIRST + GIFT_STAMP_SLOTS


## The child's own stamp (M3 Task 20b): MyStampBook's slot id - MY_STAMP_FIRST.
static func is_my_stamp(id: int) -> bool:
	return id >= MY_STAMP_FIRST and id < MY_STAMP_FIRST + MY_STAMP_SLOTS


## Items that place a practice target (dummy, bullseye) instead of a block.
static func is_target(id: int) -> bool:
	return TARGETS.has(id)


static func display_name(id: int) -> String:
	if id == FARM:
		return FARM_NAME   # M3 Task 10
	if is_gift_stamp(id):
		return GiftStampBook.current().name_of(id - GIFT_STAMP_FIRST)   # M4 I
	if is_my_stamp(id):
		return MyStampBook.name_of(id - MY_STAMP_FIRST)   # M3 Task 20b
	return _NAMES.get(id, BlockIds.display_name(id))


## M3 Task 8: what every Survivor uses without owning one (the paints and REWIND: never counted or faded).
static func is_free_tool(id: int) -> bool:
	return PAINTS.has(id) or id == REWIND or LENSES.has(id)   # owner #110: the lenses, learning tools


## Anything a hotbar slot may hold: a placeable block or a magic item.
static func is_hotbar_valid(id: int) -> bool:
	return BlockIds.is_valid(id) or is_item(id) or is_gift_stamp(id) or is_my_stamp(id)   # M4 I: gift stamps; M3 Task 20b

# --- Owner #110 (VR round 4, VR-WONDER, idea 2; docs/devlog/parts/vr-r4-wonder.md): the lenses (ids 500-501; 502-511
# stay free). A telescope and a magnifier: in a headset the one in the hotbar is in the hand (VrLens), its zoom only
# inside its lens. VR only for now: not in ALL (no palette row, chest or shop off VR; the VR palette offers them: the
# SMART page's LOOK row, Survivor's owned view), free tools (never counted), never a block. Off VR a later small task. ---
const TELESCOPE := 500
const MAGNIFIER := 501
const LENSES: Array[int] = [TELESCOPE, MAGNIFIER]


static func is_lens(id: int) -> bool:
	return LENSES.has(id)

# --- M3 Task 10: the Gold Farm (item ids 491-494 are the farm's; 492-494 unused) ---
## Bought from Tilly in a Survivor world and placed like a stamp (FarmSite, FarmDirector). Not in ALL: no
## palette row, no /give (Sandbox has no farm); is_item and display_name know it.
const FARM := 491
const FARM_NAME := "Gold Farm"
