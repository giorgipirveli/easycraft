class_name RainbowBlocks
extends RefCounted
## Rainbow Planet's blocks on block atlas page 17 (owner feedback #55, spec §21.2; ids in BlockIds 320-330, 331-335
## free). Drawn by tools/make_space_atlas.gd (pixel) and tools/make_space_realistic.py (its realistic twin). BlockLibrary
## registers the page when it loads.

const PAGE := 17
const FILES := ["res://data/blocks/pages/rainbow.png", "res://data/blocks/pages/rainbow_albedo.png",
	"res://data/blocks/pages/rainbow_normal.png"]
## The hills' rock, bottom stripe first (each STRIPE_HEIGHT blocks tall, SpaceShape).
const STRIPES: Array[int] = [BlockIds.RAINBOW_RED, BlockIds.RAINBOW_ORANGE, BlockIds.RAINBOW_YELLOW,
	BlockIds.RAINBOW_GREEN, BlockIds.RAINBOW_BLUE, BlockIds.RAINBOW_VIOLET]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.PRISM_GRASS: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.RAINBOW_RED: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.RAINBOW_ORANGE: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.RAINBOW_YELLOW: [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.RAINBOW_GREEN: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.RAINBOW_BLUE: [Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0), &"opaque"],
	BlockIds.RAINBOW_VIOLET: [Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.PRISM_CRYSTAL: [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1), &"glow"],
	BlockIds.PRISM_BRICK: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.PRISM_LAMP: [Vector2i(4, 1), Vector2i(3, 1), Vector2i(4, 1), &"glow"],
	BlockIds.FAKE_RAINBOW: [Vector2i(6, 0), Vector2i(5, 1), Vector2i(6, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
