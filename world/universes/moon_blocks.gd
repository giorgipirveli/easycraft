class_name MoonBlocks
extends RefCounted
## The Moon's blocks on block atlas page 15 (owner feedback #55, spec §21.2; ids in BlockIds 288-298, 299-303 free).
## The pixel page is drawn by tools/make_space_atlas.gd, its realistic twin by tools/make_space_realistic.py (CC0
## ambientCG textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library,
## icon and break particle has it.

const PAGE := 15
const FILES := ["res://data/blocks/pages/moon.png", "res://data/blocks/pages/moon_albedo.png",
	"res://data/blocks/pages/moon_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.MOON_DUST: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.MOON_ROCK: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.DEEP_MOON_ROCK: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.MOON_CRYSTAL: [Vector2i(5, 0), Vector2i(4, 0), Vector2i(5, 0), &"glow"],
	BlockIds.MOON_CHEESE: [Vector2i(7, 0), Vector2i(6, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.BASE_PANEL: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1), &"opaque"],
	BlockIds.PORTHOLE: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), &"glow"],
	BlockIds.LANDING_PAD: [Vector2i(2, 1), Vector2i(3, 1), Vector2i(0, 1), &"glow"],
	BlockIds.STAR_GOLD: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"glow"],
	BlockIds.FAKE_MOON_ROCK: [Vector2i(2, 0), Vector2i(5, 1), Vector2i(2, 0), &"opaque"],
	BlockIds.BASE_LIGHT: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"glow"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
