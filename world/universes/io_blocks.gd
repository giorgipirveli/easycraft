class_name IoBlocks
extends RefCounted
## Io's blocks on block atlas page 21 (cosmos, spec §21b.2; ids in BlockIds 384-398, 399 free; the last page under the
## items' ids). The pixel page is drawn by tools/make_space_atlas.gd, its realistic twin by tools/make_space_realistic.py
## (CC0 ambientCG textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every
## library, icon and break particle has it. The landing pad and star gold are the Moon's (every space world's). The
## volcano vent and hot lava are pads (PadRules): a plume throws a child up, hot lava bounces them out (never hurts).

const PAGE := 21
const FILES := ["res://data/blocks/pages/io.png", "res://data/blocks/pages/io_albedo.png",
	"res://data/blocks/pages/io_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.SULPHUR: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), &"opaque"],
	BlockIds.ORANGE_SULPHUR: [Vector2i(2, 0), Vector2i(3, 0), Vector2i(0, 1), &"opaque"],
	BlockIds.SULPHUR_FROST: [Vector2i(4, 0), Vector2i(5, 0), Vector2i(0, 1), &"opaque"],
	BlockIds.RED_SULPHUR: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(0, 1), &"opaque"],
	BlockIds.IO_ROCK: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1), &"opaque"],
	BlockIds.BLACK_LAVA: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.LAVA_CRUST: [Vector2i(2, 1), Vector2i(3, 1), Vector2i(1, 1), &"glow"],
	BlockIds.HOT_LAVA: [Vector2i(4, 1), Vector2i(5, 1), Vector2i(5, 1), &"glow"],
	BlockIds.VOLCANO_VENT: [Vector2i(6, 1), Vector2i(7, 1), Vector2i(1, 1), &"glow"],
	BlockIds.SULPHUR_CRYSTAL: [Vector2i(1, 2), Vector2i(0, 2), Vector2i(1, 2), &"glow"],
	BlockIds.HEAT_TILE: [Vector2i(2, 2), Vector2i(2, 2), Vector2i(2, 2), &"opaque"],
	BlockIds.LANDER_LEG: [Vector2i(4, 2), Vector2i(3, 2), Vector2i(4, 2), &"opaque"],
	BlockIds.HEAT_CAMERA: [Vector2i(6, 2), Vector2i(5, 2), Vector2i(6, 2), &"glow"],
	BlockIds.SULPHUR_BRICK: [Vector2i(7, 2), Vector2i(7, 2), Vector2i(7, 2), &"opaque"],
	BlockIds.FAKE_IO_ROCK: [Vector2i(0, 1), Vector2i(0, 3), Vector2i(0, 1), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
