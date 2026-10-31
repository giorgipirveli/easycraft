class_name PaintRules
extends RefCounted
## The paint bucket (M3 Task 8, spec §14.5): 16 tints. Voxel Tools' blocky mesher colours by model, so a tint
## is a block id: a plain block a child paints turns into one of 16 painted blocks (BlockIds 240-255, block atlas
## page 12: PaintPage), painted by one of 16 paint items (ItemIds 435-450). One page is one shared material, so a
## chunk with any painted blocks costs one draw call more (measured: docs/devlog/parts/m3-task-8.md).
##
## Painting is a host-checked edit and an undo step (Session section "M3 Task 8"). Blocks with a job (doors,
## beds, lights and glowing blocks, hiding spots, pads, portals, stations, smart and Game Blocks, gadget blocks,
## secrets' blocks, slippery ice, bouncy gumdrops, cacti) are never painted: paint would switch the job off.
## Survivor: paint costs nothing, and a precious block (an ore or gem: it needs a pickaxe or Tilly buys it) is
## never painted, so a diamond is never lost to paint; a painted block drops as itself and is worth no gold, so
## paint is no way to farm either.

const COUNT := 16
const FIRST_ITEM := ItemIds.PAINT_WHITE
const FIRST_BLOCK := BlockIds.PAINTED_FIRST
## [name, colour] per tint, in the palette's order.
const TINTS := [
	["White", Color("f2f0ea")], ["Silver", Color("b8bec6")], ["Grey", Color("6d747c")], ["Black", Color("2a2c31")],
	["Brown", Color("875634")], ["Red", Color("d8363d")], ["Orange", Color("f08622")], ["Yellow", Color("f6cf36")],
	["Lime", Color("8dd13d")], ["Green", Color("37984a")], ["Teal", Color("24b3ab")], ["Sky Blue", Color("6cc4f0")],
	["Blue", Color("3462d4")], ["Purple", Color("8a4dd0")], ["Magenta", Color("d24cc0")], ["Pink", Color("f498bd")],
]

const CANT := "cant"            # a block with a job (or no block at all)
const PRECIOUS := "precious"    # Survivor: an ore or a gem
const SAME := "same"            # already that colour: nothing to do
const NOT_PAINT := "not_paint"  # the new id is not a painted block

## Blocks with a job: painting would switch it off (besides whole pages: smart blocks, page 10's).
const JOBS: Array[int] = [
	BlockIds.BED, BlockIds.DOOR, BlockIds.DOOR_OPEN, BlockIds.SPIKE_TRAP, BlockIds.LANTERN, BlockIds.LIGHT,
	BlockIds.CRYSTAL, BlockIds.BUSH, BlockIds.BARREL, BlockIds.CLOSET, BlockIds.FAKE_WALL, BlockIds.PRESSURE_PLATE,
	BlockIds.TROPHY, BlockIds.GOLD_LAMP, BlockIds.JUMP_PAD, BlockIds.SPEED_PAD,
	BlockIds.CACTUS, BlockIds.DEAD_BUSH, BlockIds.PYRAMID_GOLD, BlockIds.DESERT_LAMP, BlockIds.ARROW_SLIT,
	BlockIds.TRAP_SAND, BlockIds.FAKE_SANDSTONE,
	BlockIds.ICE, BlockIds.BLUE_ICE, BlockIds.ICE_LANTERN, BlockIds.FAKE_SNOW,
	BlockIds.GUMDROP, BlockIds.RED_GUMDROP, BlockIds.CANDY_LAMP, BlockIds.COTTON_CANDY, BlockIds.GOLDEN_CANDY,
	BlockIds.FAKE_CHOCOLATE,
	BlockIds.LAB_BENCH,   # spec §23: a tap opens the Science Lab
	BlockIds.XYLOPHONE, BlockIds.DRUM,   # owner #110: the music blocks (a painted one would hide its bars and skins)
]
## Whole pages of blocks with jobs: smart and Game Blocks (page 9) and portals, gadget blocks, the saddle and the
## crafting stations (page 10); spec §21d: the rocket parts and the launch pad (page 32: a part painted would hide
## what it is); spec §26: prospecting's riches and the Refinery (page 35: painted gold quartz would hide its gold), and
## space's riches and the Solar Oven (page 39, spec §26.5).
const JOB_PAGES: Array[int] = [9, 10, 32, 35, 39]


static func item_of(tint: int) -> int:
	return FIRST_ITEM + tint if tint >= 0 and tint < COUNT else 0


static func block_of(tint: int) -> int:
	return FIRST_BLOCK + tint if tint >= 0 and tint < COUNT else BlockIds.AIR


static func is_paint(id: int) -> bool:
	return id >= FIRST_ITEM and id < FIRST_ITEM + COUNT


static func is_painted(id: int) -> bool:
	return id >= FIRST_BLOCK and id < FIRST_BLOCK + COUNT


## The tint of a paint item (-1 for anything else).
static func tint_of_item(id: int) -> int:
	return id - FIRST_ITEM if is_paint(id) else -1


## The tint of a painted block (-1 for anything else).
static func tint_of_block(id: int) -> int:
	return id - FIRST_BLOCK if is_painted(id) else -1


## The painted block a paint item makes (AIR for anything that is not paint).
static func painted_by(item: int) -> int:
	return block_of(tint_of_item(item))


static func tint_name(tint: int) -> String:
	return String(TINTS[tint][0]) if tint >= 0 and tint < COUNT else ""


static func color(tint: int) -> Color:
	return TINTS[tint][1] if tint >= 0 and tint < COUNT else Color.WHITE


## A plain block paint may turn into a painted block (painted blocks are painted again).
static func paintable(id: int) -> bool:
	if not BlockIds.is_valid(id) or not BlockIds.is_solid(id) or JOBS.has(id):
		return false
	return not JOB_PAGES.has(BlockLibrary.page_of(id))


## An ore or a gem: it needs a pickaxe, or Tilly buys it. Survivor never paints one.
static func precious(id: int) -> bool:
	return GatherRules.NEEDS_TIER.has(id) or ShopRules.SELL_PRICES.has(id)


## Why `old` can't become `painted` ("" = it can): NOT_PAINT, SAME, CANT or (Survivor) PRECIOUS.
static func refusal(old: int, painted: int, survivor: bool) -> String:
	if not is_painted(painted):
		return NOT_PAINT
	if old == painted:
		return SAME
	if not paintable(old):
		return CANT
	if survivor and precious(old):
		return PRECIOUS
	return ""


## What the child is told ("" for SAME: nothing happens, nothing to say).
static func message(code: String, old: int) -> String:
	match code:
		CANT:
			if old == BlockIds.AIR:
				return "Tap a block to paint it!"
			var name := BlockIds.display_name(old)
			if name == "" or old in [BlockIds.WATER, BlockIds.BEDROCK]:
				return "That can't be painted!"
			return Lang.t("%s can't be painted!") % (name if name.ends_with("s") else name + "s")
		PRECIOUS:
			return Lang.t("%s is too precious to paint!") % Lang.t(BlockIds.display_name(old))
		NOT_PAINT:
			return "Pick a paint colour first!"
	return ""
