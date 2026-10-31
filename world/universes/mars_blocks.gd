class_name MarsBlocks
extends RefCounted
## Mars's blocks on block atlas page 18 (cosmos, spec §21b.2; ids in BlockIds 336-349, 350-351 free). The pixel page is
## drawn by tools/make_space_atlas.gd, its realistic twin by tools/make_space_realistic.py (CC0 ambientCG textures),
## both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library, icon and break
## particle has it. The landing pad and star gold are the Moon's (every space world's).

const PAGE := 18
const FILES := ["res://data/blocks/pages/mars.png", "res://data/blocks/pages/mars_albedo.png",
	"res://data/blocks/pages/mars_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.MARS_DUST: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.MARS_REGOLITH: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.BASALT: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.DEEP_BASALT: [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.MARS_SEDIMENT: [Vector2i(5, 0), Vector2i(6, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.POLAR_ICE: [Vector2i(7, 0), Vector2i(0, 1), Vector2i(7, 0), &"opaque"],
	BlockIds.DRY_ICE: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.GYPSUM: [Vector2i(3, 1), Vector2i(2, 1), Vector2i(3, 1), &"glow"],
	BlockIds.ROVER_PANEL: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.ROVER_WHEEL: [Vector2i(5, 1), Vector2i(6, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.SOLAR_PANEL: [Vector2i(7, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.LANDER_FOIL: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"opaque"],
	BlockIds.FAKE_BASALT: [Vector2i(3, 0), Vector2i(1, 2), Vector2i(3, 0), &"opaque"],
	BlockIds.ROVER_LIGHT: [Vector2i(3, 2), Vector2i(2, 2), Vector2i(3, 2), &"glow"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
