class_name ProspectPage
extends RefCounted
## Prospecting on Earth (spec §26, owner #80): the riches' blocks on block atlas page 35 (ids 608-623 in BlockIds; past
## page 32's rocket parts and pages 33-34, the world's wonders'). The pixel page is drawn by
## tools/make_prospect_page.gd, its realistic twin by tools/make_prospect_realistic.py (CC0 ambientCG textures), both in
## the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library, icon and break particle has
## it. Every block is a solid cube: ten found in the ground (DepositRules puts them where real geology does), five that
## refining makes (RefiningRules) and the Refinery, a station like the Clay Oven. Never painted (PaintRules.JOB_PAGES).

const PAGE := 35
const FILES := ["res://data/blocks/pages/prospect.png", "res://data/blocks/pages/prospect_albedo.png",
	"res://data/blocks/pages/prospect_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.GOLD_QUARTZ: [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.GOLD_GRAVEL: [Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.COPPER_ORE: [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.MALACHITE: [Vector2i(6, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.BANDED_IRON: [Vector2i(0, 1), Vector2i(7, 0), Vector2i(0, 1), &"opaque"],
	BlockIds.RUSTY_ROCK: [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.FERN_SHALE: [Vector2i(4, 1), Vector2i(3, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.OIL_SEEP: [Vector2i(5, 1), Vector2i(6, 1), Vector2i(6, 1), &"opaque"],
	BlockIds.ROCK_SALT: [Vector2i(7, 1), Vector2i(7, 1), Vector2i(7, 1), &"opaque"],
	BlockIds.SALT_CRUST: [Vector2i(0, 2), Vector2i(1, 2), Vector2i(7, 1), &"opaque"],
	BlockIds.COPPER: [Vector2i(2, 2), Vector2i(3, 2), Vector2i(2, 2), &"opaque"],
	BlockIds.TABLE_SALT: [Vector2i(4, 2), Vector2i(5, 2), Vector2i(4, 2), &"opaque"],
	BlockIds.CRUDE_OIL: [Vector2i(6, 2), Vector2i(7, 2), Vector2i(6, 2), &"opaque"],
	BlockIds.KEROSENE: [Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 3), &"opaque"],
	BlockIds.PLASTIC: [Vector2i(2, 3), Vector2i(2, 3), Vector2i(2, 3), &"opaque"],
	BlockIds.REFINERY: [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), &"opaque"],
}

## Found in the ground (the deposits' ore bodies and signs), in the order the page draws them.
const FOUND: Array[int] = [BlockIds.GOLD_QUARTZ, BlockIds.GOLD_GRAVEL, BlockIds.COPPER_ORE, BlockIds.MALACHITE,
	BlockIds.BANDED_IRON, BlockIds.RUSTY_ROCK, BlockIds.FERN_SHALE, BlockIds.OIL_SEEP, BlockIds.ROCK_SALT, BlockIds.SALT_CRUST]
## What refining makes.
const REFINED: Array[int] = [BlockIds.COPPER, BlockIds.TABLE_SALT, BlockIds.CRUDE_OIL, BlockIds.KEROSENE, BlockIds.PLASTIC]


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
