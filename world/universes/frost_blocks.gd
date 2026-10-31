class_name FrostBlocks
extends RefCounted
## Frostpeak's blocks on block atlas page 2 (M3 Task 3, spec §14.1; ids in BlockIds 80-95). The pixel
## page is drawn by tools/make_frost_atlas.gd, its realistic twin by tools/make_frost_realistic.py (CC0
## ambientCG textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so
## every library, icon and break particle has it. Ice and blue ice are slippery (FrostRules.grip).

const PAGE := 2
const FILES := ["res://data/blocks/pages/frost.png", "res://data/blocks/pages/frost_albedo.png",
	"res://data/blocks/pages/frost_normal.png"]

## id -> [top, side, bottom, kind, extras] (BlockLibrary.register_page; extras: walk_through, transparency).
const TILES := {
	BlockIds.SNOW: [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), &"opaque"],
	BlockIds.SNOWY_GRASS: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.PACKED_SNOW: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.ICE: [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.BLUE_ICE: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.PINE_LOG: [Vector2i(7, 0), Vector2i(6, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.PINE_NEEDLES: [Vector2i(1, 1), Vector2i(0, 1), Vector2i(0, 1), &"cutout", {"transparency": 1}],
	BlockIds.FROZEN_ORE: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.SNOW_BRICK: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.ICE_LANTERN: [Vector2i(5, 1), Vector2i(4, 1), Vector2i(5, 1), &"glow"],
	BlockIds.FROSTED_GLASS: [Vector2i(6, 1), Vector2i(6, 1), Vector2i(6, 1), &"cutout", {"transparency": 5}],
	BlockIds.FAKE_SNOW: [Vector2i(7, 1), Vector2i(7, 1), Vector2i(3, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
