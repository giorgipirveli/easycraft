class_name RingsBlocks
extends RefCounted
## Saturn's rings' blocks on block atlas page 40 (cosmos, spec §21b.2; ids in BlockIds 688-703, the whole page; page 39,
## ids 672-687, is the riches of the Moon and Mars). The pixel page is drawn by tools/make_space_atlas.gd, its realistic
## twin by tools/make_space_realistic.py (CC0 ambientCG textures), both in the same 8 x 8 layout (three rows).
## BlockLibrary registers the page when it loads, so every library, icon and break particle has it. The landing pad and
## star gold are the Moon's (every space world's); the Saturn scope is Venus's telescope, the Ring Explorer's wrap Mars's
## gold foil.

const PAGE := 40
const FILES := ["res://data/blocks/pages/rings.png", "res://data/blocks/pages/rings_albedo.png",
	"res://data/blocks/pages/rings_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.RING_ICE: [Vector2i(1, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.RING_FROST: [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.DUSTY_ICE: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.RING_ROCK: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.MOONLET_ICE: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.RIDGE_DUST: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(7, 0), &"opaque"],
	BlockIds.RING_CRYSTAL: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1), &"glow"],
	BlockIds.STATION_PANEL: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.STATION_WINDOW: [Vector2i(3, 1), Vector2i(4, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.STATION_LAMP: [Vector2i(6, 1), Vector2i(5, 1), Vector2i(6, 1), &"glow"],
	BlockIds.RADIO_DISH: [Vector2i(7, 1), Vector2i(0, 2), Vector2i(3, 1), &"opaque"],
	BlockIds.POWER_PACK: [Vector2i(2, 2), Vector2i(1, 2), Vector2i(2, 2), &"glow"],
	BlockIds.TRUSS: [Vector2i(3, 2), Vector2i(3, 2), Vector2i(3, 2), &"opaque"],
	BlockIds.RING_BEACON: [Vector2i(5, 2), Vector2i(4, 2), Vector2i(5, 2), &"glow"],
	BlockIds.SATURN_BAND: [Vector2i(6, 2), Vector2i(6, 2), Vector2i(6, 2), &"opaque"],
	BlockIds.FAKE_RING_ICE: [Vector2i(1, 0), Vector2i(7, 2), Vector2i(1, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
