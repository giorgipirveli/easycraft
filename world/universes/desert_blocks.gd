class_name DesertBlocks
extends RefCounted
## The Sandstorm Desert's blocks on block atlas page 1 (M3 Task 2, spec §14.1; ids in BlockIds 64-79).
## The pixel page is drawn by tools/make_desert_atlas.gd, its realistic twin by
## tools/make_desert_realistic.py (CC0 ambientCG textures), both in the same 8 x 8 layout.
## BlockLibrary registers the page when it loads, so every library, icon and break particle has it.

const PAGE := 1
const FILES := ["res://data/blocks/pages/desert.png", "res://data/blocks/pages/desert_albedo.png",
	"res://data/blocks/pages/desert_normal.png"]

## id -> [top, side, bottom, kind, extras] (BlockLibrary.register_page; extras: walk_through, transparency).
const TILES := {
	BlockIds.SANDSTONE: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.CUT_SANDSTONE: [Vector2i(0, 0), Vector2i(3, 0), Vector2i(0, 0), &"opaque"],
	BlockIds.CHISELED_SANDSTONE: [Vector2i(6, 2), Vector2i(4, 0), Vector2i(6, 2), &"opaque"],
	BlockIds.RED_SAND: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.RED_SANDSTONE: [Vector2i(7, 0), Vector2i(6, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.CACTUS: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.DEAD_BUSH: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"cutout", {"walk_through": true}],
	BlockIds.DESERT_GLASS: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"cutout", {"transparency": 4}],
	BlockIds.PALM_LOG: [Vector2i(6, 1), Vector2i(5, 1), Vector2i(6, 1), &"opaque"],
	BlockIds.PALM_LEAVES: [Vector2i(7, 1), Vector2i(7, 1), Vector2i(7, 1), &"cutout", {"transparency": 1, "sway": true}],
	BlockIds.PYRAMID_GOLD: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"glow"],
	BlockIds.DESERT_LAMP: [Vector2i(2, 2), Vector2i(1, 2), Vector2i(2, 2), &"glow"],
	BlockIds.ARROW_SLIT: [Vector2i(0, 0), Vector2i(3, 2), Vector2i(0, 0), &"opaque"],
	BlockIds.TRAP_SAND: [Vector2i(4, 2), Vector2i(4, 2), Vector2i(4, 2), &"opaque", {"walk_through": true}],
	BlockIds.FAKE_SANDSTONE: [Vector2i(0, 0), Vector2i(5, 2), Vector2i(2, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
