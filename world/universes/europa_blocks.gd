class_name EuropaBlocks
extends RefCounted
## Europa's blocks on block atlas page 20 (cosmos, spec §21b.2; ids in BlockIds 368-380, 381-383 free). The pixel page
## is drawn by tools/make_space_atlas.gd, its realistic twin by tools/make_space_realistic.py (CC0 ambientCG textures),
## both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library, icon and break
## particle has it. The landing pad and star gold are the Moon's (every space world's). The geyser vent is a pad
## (PadRules): a water plume throws a child up.

const PAGE := 20
const FILES := ["res://data/blocks/pages/europa.png", "res://data/blocks/pages/europa_albedo.png",
	"res://data/blocks/pages/europa_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.EUROPA_ICE: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 0), &"opaque"],
	BlockIds.LINEA_ICE: [Vector2i(2, 0), Vector2i(3, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.BAND_ICE: [Vector2i(4, 0), Vector2i(5, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.DEEP_ICE: [Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0), &"opaque"],
	BlockIds.EUROPA_ROCK: [Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.GLOW_ICE: [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1), &"glow"],
	BlockIds.SALT: [Vector2i(3, 1), Vector2i(2, 1), Vector2i(3, 1), &"glow"],
	BlockIds.GEYSER_VENT: [Vector2i(4, 1), Vector2i(5, 1), Vector2i(4, 1), &"glow"],
	BlockIds.PROBE_PANEL: [Vector2i(6, 1), Vector2i(6, 1), Vector2i(6, 1), &"opaque"],
	BlockIds.MELT_PROBE: [Vector2i(0, 2), Vector2i(7, 1), Vector2i(0, 2), &"opaque"],
	BlockIds.PROBE_LIGHT: [Vector2i(2, 2), Vector2i(1, 2), Vector2i(2, 2), &"glow"],
	BlockIds.ICE_BRICK: [Vector2i(3, 2), Vector2i(3, 2), Vector2i(3, 2), &"opaque"],
	BlockIds.FAKE_DEEP_ICE: [Vector2i(6, 0), Vector2i(4, 2), Vector2i(6, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
