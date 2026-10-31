class_name CandyBlocks
extends RefCounted
## The Candy Kingdom's blocks on block atlas page 8 (M3 Task 4, spec §14.1; ids in BlockIds 176-191).
## The pixel page is drawn by tools/make_candy_atlas.gd, its realistic twin by tools/make_candy_realistic.py
## (CC0 ambientCG textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads,
## so every library, icon and break particle has it.

const PAGE := 8
const FILES := ["res://data/blocks/pages/candy.png", "res://data/blocks/pages/candy_albedo.png",
	"res://data/blocks/pages/candy_normal.png"]

## id -> [top, side, bottom, kind, extras] (BlockLibrary.register_page; extras: walk_through, transparency).
const TILES := {
	BlockIds.FROSTING: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.CAKE: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.CHOCOLATE: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.CANDY_CANE: [Vector2i(5, 0), Vector2i(4, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.LOLLIPOP: [Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0), &"opaque"],
	BlockIds.GUMDROP: [Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.RED_GUMDROP: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1), &"opaque"],
	BlockIds.CREAM: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.JAM: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.SUGAR_GLASS: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"cutout", {"transparency": 5}],
	BlockIds.GINGERBREAD: [Vector2i(5, 1), Vector2i(4, 1), Vector2i(5, 1), &"opaque"],
	BlockIds.CANDY_LAMP: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"glow"],
	BlockIds.COTTON_CANDY: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"cutout", {"walk_through": true}],
	BlockIds.SPRINKLES: [Vector2i(1, 2), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.GOLDEN_CANDY: [Vector2i(2, 2), Vector2i(2, 2), Vector2i(2, 2), &"glow"],
	BlockIds.FAKE_CHOCOLATE: [Vector2i(3, 0), Vector2i(3, 2), Vector2i(3, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
