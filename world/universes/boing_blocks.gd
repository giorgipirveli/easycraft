class_name BoingBlocks
extends RefCounted
## Planet Boing's blocks on block atlas page 16 (owner feedback #55, spec §21.2; ids in BlockIds 304-312, 313-319
## free). Drawn by tools/make_space_atlas.gd (pixel) and tools/make_space_realistic.py (its realistic twin). BlockLibrary
## registers the page when it loads. Boing moss, jelly and spring caps are bouncy (CandyRules.is_gumdrop).

const PAGE := 16
const FILES := ["res://data/blocks/pages/boing.png", "res://data/blocks/pages/boing_albedo.png",
	"res://data/blocks/pages/boing_normal.png"]
## Landing on these from a fall bounces you back up (the Candy Kingdom's gumdrop rule).
const BOUNCY: Array[int] = [BlockIds.BOING_MOSS, BlockIds.JELLY, BlockIds.SPRING_CAP]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.BOING_MOSS: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.BOING_SOIL: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.BOING_ROCK: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.JELLY: [Vector2i(4, 0), Vector2i(4, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.SPRING_STEM: [Vector2i(6, 0), Vector2i(5, 0), Vector2i(6, 0), &"opaque"],
	BlockIds.SPRING_CAP: [Vector2i(7, 0), Vector2i(0, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.BOING_GLOW: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1), &"glow"],
	BlockIds.BOING_BRICK: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.FAKE_BOING_ROCK: [Vector2i(3, 0), Vector2i(4, 1), Vector2i(3, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
