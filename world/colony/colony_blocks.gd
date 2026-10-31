class_name ColonyBlocks
extends RefCounted
## The colony's blocks on block atlas page 31 (owner #77, spec §21c; ids 544-559 in BlockIds, the whole page). The pixel
## page is drawn by tools/make_colony_page.gd, its realistic twin by tools/make_colony_realistic.py (CC0 ambientCG
## textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library, icon and
## break particle has it. The domes' glass is one clear sheet (its own transparency index, culling the faces between two
## panes); the fruit leaves are leaves like every tree's; the table is cut out (its legs).

const PAGE := 31
const FILES := ["res://data/blocks/pages/colony.png", "res://data/blocks/pages/colony_albedo.png",
	"res://data/blocks/pages/colony_normal.png"]
## Dome glass's transparency index: 1-6 are taken (leaves, glass, water, the desert's glass, frosted and sugar glass,
## starglass).
const GLASS_TRANSPARENCY := 7

## id -> [top, side, bottom, kind, extras] (BlockLibrary.register_page; extras: transparency, culls).
const TILES := {
	BlockIds.DOME_GLASS: [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), &"cutout",
		{"transparency": GLASS_TRANSPARENCY, "culls": true}],
	BlockIds.COLONY_PANEL: [Vector2i(2, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.COLONY_FLOOR: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.GREENHOUSE_SOIL: [Vector2i(5, 0), Vector2i(6, 0), Vector2i(6, 0), &"opaque"],
	BlockIds.GROW_LAMP: [Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), &"glow"],
	BlockIds.COLONY_LIGHT: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1), &"glow"],
	BlockIds.FRUIT_LEAVES: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), &"cutout", {"transparency": 1}],
	BlockIds.WATER_TANK: [Vector2i(3, 1), Vector2i(2, 1), Vector2i(3, 1), &"glow"],
	BlockIds.ICE_MELTER: [Vector2i(5, 1), Vector2i(4, 1), Vector2i(5, 1), &"glow"],
	BlockIds.OXYGEN_MAKER: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"glow"],
	BlockIds.CONTROL_SCREEN: [Vector2i(1, 2), Vector2i(0, 2), Vector2i(1, 2), &"glow"],
	BlockIds.COLONY_MAP: [Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 2), &"glow"],
	BlockIds.AIRLOCK_FRAME: [Vector2i(4, 2), Vector2i(3, 2), Vector2i(4, 2), &"opaque"],
	BlockIds.ROCKET_HULL: [Vector2i(6, 2), Vector2i(5, 2), Vector2i(6, 2), &"opaque"],
	BlockIds.PRINTED_REGOLITH: [Vector2i(0, 3), Vector2i(7, 2), Vector2i(7, 2), &"opaque"],   # its layers seen from inside
	BlockIds.COLONY_TABLE: [Vector2i(2, 3), Vector2i(1, 3), Vector2i(3, 3), &"cutout"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
