class_name GlowBlocks
extends RefCounted
## Universe 6's blocks, the Glow Caves', on block atlas page 45 (spec §5.1; ids in BlockIds 768-783, all used). The
## pixel page is drawn by tools/make_glow_atlas.gd, its realistic twin by tools/make_glow_realistic.py (CC0 ambientCG
## textures from the cache, recoloured, and our own drawing), both in the same 8 x 8 layout (three rows). BlockLibrary
## registers the page when it loads, so every library, icon and break particle has it. The glow is the blocks' own
## (the page's unshaded "glow" material): no real light per mushroom. Universe 6's portal core is page 10's (223).

const PAGE := 45
const FILES := ["res://data/blocks/pages/glow.png", "res://data/blocks/pages/glow_albedo.png",
	"res://data/blocks/pages/glow_normal.png"]
## Dripstone: two crossed pictures that never sway (they are stone); a stalactite's hang from the block above.
const STILL := {"cross": true, "still": true}
const HANGING := {"cross": true, "still": true, "hang": true}

## id -> [top, side, bottom, kind, extras] (BlockLibrary.register_page).
const TILES := {
	BlockIds.CAVE_STONE: [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), &"opaque"],
	BlockIds.GLOW_MOSS: [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 0), &"glow"],
	BlockIds.SHROOM_STEM: [Vector2i(4, 0), Vector2i(3, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.BLUE_SHROOM: [Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), &"glow"],
	BlockIds.ROSE_SHROOM: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), &"glow"],
	BlockIds.GLOW_WORMS: [Vector2i(0, 0), Vector2i(4, 1), Vector2i(3, 1), &"glow"],
	BlockIds.SELENITE: [Vector2i(5, 1), Vector2i(5, 1), Vector2i(5, 1), &"glow"],
	BlockIds.FLOWSTONE: [Vector2i(6, 1), Vector2i(6, 1), Vector2i(6, 1), &"opaque"],
	BlockIds.STALACTITE: [Vector2i(7, 1), Vector2i(7, 1), Vector2i(7, 1), &"cutout", HANGING],
	BlockIds.STALAGMITE: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"cutout", STILL],
	BlockIds.LAKE_STONE: [Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.FUNGUS_PLANKS: [Vector2i(2, 2), Vector2i(2, 2), Vector2i(2, 2), &"opaque"],
	BlockIds.SPORE_LAMP: [Vector2i(4, 2), Vector2i(3, 2), Vector2i(4, 2), &"glow"],
	BlockIds.CAVE_PEARL: [Vector2i(5, 2), Vector2i(5, 2), Vector2i(5, 2), &"glow"],
	BlockIds.CAVE_GOLD: [Vector2i(6, 2), Vector2i(6, 2), Vector2i(6, 2), &"glow"],
	BlockIds.FAKE_CAVE_STONE: [Vector2i(0, 0), Vector2i(7, 2), Vector2i(0, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
