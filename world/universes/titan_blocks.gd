class_name TitanBlocks
extends RefCounted
## Titan's blocks on block atlas page 29 (cosmos, spec §21b.2; ids in BlockIds 512-522, 523-527 free; the first page
## past the items' ids 400-511). The pixel page is drawn by tools/make_space_atlas.gd, its realistic twin by
## tools/make_space_realistic.py (CC0 ambientCG textures), both in the same 8 x 8 layout. BlockLibrary registers the page
## when it loads, so every library, icon and break particle has it. The landing pad and star gold are the Moon's (every
## space world's). Titan's lakes and sea are the game's WATER shown as liquid methane (BlockLibrary.set_liquid): they
## swim like water, with no block of their own.

const PAGE := 29
const FILES := ["res://data/blocks/pages/titan.png", "res://data/blocks/pages/titan_albedo.png",
	"res://data/blocks/pages/titan_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.TITAN_SOIL: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.ICE_PEBBLES: [Vector2i(2, 0), Vector2i(3, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.DUNE_SAND: [Vector2i(4, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.WET_SHORE: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.ICY_ROCK: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1), &"opaque"],
	BlockIds.SHORE_CRYSTAL: [Vector2i(2, 1), Vector2i(1, 1), Vector2i(2, 1), &"glow"],
	BlockIds.PROBE_SHELL: [Vector2i(4, 1), Vector2i(3, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.PARACHUTE: [Vector2i(5, 1), Vector2i(5, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.PROBE_LAMP: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"glow"],
	BlockIds.TITAN_BRICK: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"opaque"],
	BlockIds.FAKE_ICY_ROCK: [Vector2i(0, 1), Vector2i(1, 2), Vector2i(0, 1), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
