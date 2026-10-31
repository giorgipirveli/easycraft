class_name ProspectSpacePage
extends RefCounted
## Prospecting on the Moon and Mars (spec §26.5, owner #80): the riches of space on block atlas page 39 (ids 672-687 in
## BlockIds; past Venus's page 38; pages 36-37 are the New Seven Wonders'). The pixel page is drawn by
## tools/make_prospect_space_page.gd, its realistic twin by tools/make_prospect_space_realistic.py (CC0 ambientCG
## textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library, icon and
## break particle has it. Every block is a solid cube: ten found in the ground (DepositRules puts them where real
## geology does), five that in-situ resource use makes (RefiningRules) and the Solar Oven, a station. Never painted
## (PaintRules.JOB_PAGES).

const PAGE := 39
const FILES := ["res://data/blocks/pages/prospect_space.png", "res://data/blocks/pages/prospect_space_albedo.png",
	"res://data/blocks/pages/prospect_space_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.ICY_REGOLITH: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.MARE_DUST: [Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.ILMENITE: [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.KREEP_ROCK: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.IRON_METEORITE: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.GROUND_ICE: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.BLUEBERRY_SOIL: [Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.HEMATITE: [Vector2i(5, 1), Vector2i(4, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.DARK_SAND: [Vector2i(6, 1), Vector2i(7, 1), Vector2i(7, 1), &"opaque"],
	BlockIds.MARS_SALT: [Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.OXYGEN_TANK: [Vector2i(3, 2), Vector2i(2, 2), Vector2i(3, 2), &"opaque"],
	BlockIds.HYDROGEN_FUEL: [Vector2i(5, 2), Vector2i(4, 2), Vector2i(5, 2), &"opaque"],
	BlockIds.TITANIUM: [Vector2i(6, 2), Vector2i(7, 2), Vector2i(6, 2), &"opaque"],
	BlockIds.RARE_EARTHS: [Vector2i(0, 3), Vector2i(1, 3), Vector2i(1, 3), &"opaque"],
	BlockIds.HELIUM_3: [Vector2i(3, 3), Vector2i(2, 3), Vector2i(3, 3), &"opaque"],
	BlockIds.SOLAR_OVEN: [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), &"opaque"],
}

## Found in the ground (the deposits' ore bodies and signs), in the order the page draws them.
const FOUND: Array[int] = [BlockIds.ICY_REGOLITH, BlockIds.MARE_DUST, BlockIds.ILMENITE, BlockIds.KREEP_ROCK,
	BlockIds.IRON_METEORITE, BlockIds.GROUND_ICE, BlockIds.BLUEBERRY_SOIL, BlockIds.HEMATITE, BlockIds.DARK_SAND,
	BlockIds.MARS_SALT]
## What in-situ resource use makes of them.
const MADE: Array[int] = [BlockIds.OXYGEN_TANK, BlockIds.HYDROGEN_FUEL, BlockIds.TITANIUM, BlockIds.RARE_EARTHS,
	BlockIds.HELIUM_3]


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
