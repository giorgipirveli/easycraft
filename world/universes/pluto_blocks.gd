class_name PlutoBlocks
extends RefCounted
## Pluto's blocks on block atlas page 41 (cosmos, spec §21b.2; ids in BlockIds 704-716, 717-719 free). The pixel page is
## drawn by tools/make_space_atlas.gd, its realistic twin by tools/make_space_realistic.py (CC0 ambientCG textures), both
## in the same 8 x 8 layout (three rows). BlockLibrary registers the page when it loads, so every library, icon and break
## particle has it. The landing pad and star gold are the Moon's (every space world's); the Balloon Lander's gold foil is
## Mars's, its radio dish, power pack, truss and lamps are the rings' and the Charon Lookout's telescope is Venus's.

const PAGE := 41
const FILES := ["res://data/blocks/pages/pluto.png", "res://data/blocks/pages/pluto_albedo.png",
	"res://data/blocks/pages/pluto_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.NITROGEN_ICE: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.CELL_EDGE: [Vector2i(2, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.WATER_ICE: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.PLUTO_FROST: [Vector2i(4, 0), Vector2i(5, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.THOLIN_DUST: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.RED_ICE: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1), &"opaque"],
	BlockIds.METHANE_SNOW: [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 0), &"opaque"],
	BlockIds.FROST_CRYSTAL: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"glow"],
	BlockIds.DRAG_BALLOON: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.CHARON_GLOBE: [Vector2i(6, 1), Vector2i(5, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.HEART_BEACON: [Vector2i(0, 2), Vector2i(7, 1), Vector2i(0, 2), &"glow"],
	BlockIds.FROST_BRICK: [Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.FAKE_WATER_ICE: [Vector2i(3, 0), Vector2i(2, 2), Vector2i(3, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
