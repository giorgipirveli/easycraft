class_name MercuryBlocks
extends RefCounted
## Mercury's blocks on block atlas page 30 (cosmos, spec §21b.2; ids in BlockIds 528-541, 542-543 free; past the items'
## ids 400-511, after Titan's page 29). The pixel page is drawn by tools/make_space_atlas.gd, its realistic twin by
## tools/make_space_realistic.py (CC0 ambientCG textures), both in the same 8 x 8 layout. BlockLibrary registers the page
## when it loads, so every library, icon and break particle has it. The landing pad and star gold are the Moon's (every
## space world's).

const PAGE := 30
const FILES := ["res://data/blocks/pages/mercury.png", "res://data/blocks/pages/mercury_albedo.png",
	"res://data/blocks/pages/mercury_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.MERCURY_DUST: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.MERCURY_ROCK: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.DARK_DUST: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.RAY_DUST: [Vector2i(5, 0), Vector2i(6, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.SHADOW_ICE: [Vector2i(7, 0), Vector2i(0, 1), Vector2i(2, 0), &"opaque"],
	BlockIds.ICE_CRYSTAL: [Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1), &"glow"],
	BlockIds.SUNSHADE: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.HEAT_BLANKET: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.MIRROR_PANEL: [Vector2i(5, 1), Vector2i(6, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.EXPLORER_LAMP: [Vector2i(0, 2), Vector2i(7, 1), Vector2i(0, 2), &"glow"],
	BlockIds.THERMOMETER: [Vector2i(2, 2), Vector2i(1, 2), Vector2i(2, 2), &"opaque"],
	BlockIds.THERMO_BULB: [Vector2i(4, 2), Vector2i(3, 2), Vector2i(4, 2), &"glow"],
	BlockIds.EXPLORER_BRICK: [Vector2i(5, 2), Vector2i(5, 2), Vector2i(5, 2), &"opaque"],
	BlockIds.FAKE_MERCURY_ROCK: [Vector2i(2, 0), Vector2i(6, 2), Vector2i(2, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
