class_name TritonBlocks
extends RefCounted
## Triton's blocks on block atlas page 42 (cosmos, spec §21b.2; ids in BlockIds 720-733, 734-735 free). The pixel page is
## drawn by tools/make_space_atlas.gd, its realistic twin by tools/make_space_realistic.py (CC0 ambientCG textures), both
## in the same 8 x 8 layout (three rows). BlockLibrary registers the page when it loads, so every library, icon and break
## particle has it. Under its frost Triton shares Pluto's nitrogen ice and water ice (page 41: both came from the Kuiper
## Belt); the landing pad and star gold are the Moon's (every space world's); the Hopper Lander's gold foil is Mars's,
## its radio dish, power pack, truss and lamps are the rings' and the Neptune Lookout's telescope is Venus's.

const PAGE := 42
const FILES := ["res://data/blocks/pages/triton.png", "res://data/blocks/pages/triton_albedo.png",
	"res://data/blocks/pages/triton_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.TRITON_FROST: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.PINK_ICE: [Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.MOTTLED_ICE: [Vector2i(4, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.GEYSER_DUST: [Vector2i(5, 0), Vector2i(6, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.NITROGEN_GEYSER: [Vector2i(7, 0), Vector2i(0, 1), Vector2i(3, 0), &"glow"],
	BlockIds.CANTALOUPE_ICE: [Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.RIDGE_ICE: [Vector2i(3, 1), Vector2i(2, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.ICE_LAVA: [Vector2i(4, 1), Vector2i(5, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.NITROGEN_CRYSTAL: [Vector2i(6, 1), Vector2i(6, 1), Vector2i(6, 1), &"glow"],
	BlockIds.NITROGEN_TANK: [Vector2i(0, 2), Vector2i(7, 1), Vector2i(0, 2), &"opaque"],
	BlockIds.NEPTUNE_GLOBE: [Vector2i(2, 2), Vector2i(1, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.BLUE_BEACON: [Vector2i(4, 2), Vector2i(3, 2), Vector2i(4, 2), &"glow"],
	BlockIds.CAP_BRICK: [Vector2i(5, 2), Vector2i(5, 2), Vector2i(5, 2), &"opaque"],
	BlockIds.FAKE_PINK_ICE: [Vector2i(2, 0), Vector2i(6, 2), Vector2i(3, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
