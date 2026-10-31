class_name VenusBlocks
extends RefCounted
## Venus's cloud city's blocks on block atlas page 38 (cosmos, spec §21b.2; ids in BlockIds 656-671, the whole page;
## after the New Seven Wonders' pages 36-37). The pixel page is drawn by tools/make_space_atlas.gd, its realistic twin by
## tools/make_space_realistic.py (CC0 ambientCG textures), both in the same 8 x 8 layout (three rows). BlockLibrary
## registers the page when it loads, so every library, icon and break particle has it. The landing pad and star gold
## are the Moon's (every space world's).

const PAGE := 38
const FILES := ["res://data/blocks/pages/venus.png", "res://data/blocks/pages/venus_albedo.png",
	"res://data/blocks/pages/venus_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.VENUS_CLOUD: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.DEEP_CLOUD: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.CLOUD_DECK: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.FLOAT_HULL: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.SKY_TURF: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.SKY_BRIDGE: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), &"opaque"],
	BlockIds.CLOUD_LAMP: [Vector2i(2, 1), Vector2i(3, 1), Vector2i(2, 1), &"glow"],
	BlockIds.SKY_FRAME: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.HOME_PANEL: [Vector2i(5, 1), Vector2i(5, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.BLIMP_SKIN: [Vector2i(6, 1), Vector2i(6, 1), Vector2i(6, 1), &"opaque"],
	BlockIds.BLIMP_STRIPE: [Vector2i(7, 1), Vector2i(7, 1), Vector2i(7, 1), &"opaque"],
	BlockIds.GONDOLA: [Vector2i(5, 0), Vector2i(0, 2), Vector2i(5, 0), &"opaque"],
	BlockIds.SOLAR_FILM: [Vector2i(1, 2), Vector2i(2, 2), Vector2i(5, 0), &"opaque"],
	BlockIds.CLOUD_CRYSTAL: [Vector2i(3, 2), Vector2i(3, 2), Vector2i(3, 2), &"glow"],
	BlockIds.TELESCOPE: [Vector2i(4, 2), Vector2i(4, 2), Vector2i(4, 2), &"opaque"],
	BlockIds.FAKE_FLOAT_HULL: [Vector2i(5, 0), Vector2i(5, 2), Vector2i(5, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
