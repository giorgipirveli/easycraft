class_name MeadowsBlocks
extends RefCounted
## The wild meadows' blocks on block atlas page 13 (owner feedback #45b, spec §14.18; ids in BlockIds 256-271):
## birch and dark trees, flowers, lily pads, mud, and what villages and landmarks are built of. The pixel page
## is drawn by tools/make_meadows_page.gd, its realistic twin by tools/make_meadows_realistic.py (CC0 ambientCG
## textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library,
## icon and break particle has it (in every world: a child can carry these blocks anywhere).

const PAGE := 13
const FILES := ["res://data/blocks/pages/meadows.png", "res://data/blocks/pages/meadows_albedo.png",
	"res://data/blocks/pages/meadows_normal.png"]
## A lily pad's height: a thin pad lying on the water (you can stand on it).
const PAD_HEIGHT := 0.0625

## id -> [top, side, bottom, kind, extras] (BlockLibrary.register_page; extras: transparency, walk_through, and
## this page's own: "cross" (two crossed pictures, walked through: flowers, wheat) and "height" (the lily pad)).
const TILES := {
	BlockIds.BIRCH_LOG: [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.BIRCH_LEAVES: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"cutout", {"transparency": 1, "sway": true}],
	BlockIds.DARK_LOG: [Vector2i(4, 0), Vector2i(3, 0), Vector2i(4, 0), &"opaque"],
	BlockIds.DARK_LEAVES: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"cutout", {"transparency": 1, "sway": true}],
	BlockIds.FLOWERS: [Vector2i(6, 0), Vector2i(6, 0), Vector2i(6, 0), &"pass", {"cross": true}],
	BlockIds.LILY_PAD: [Vector2i(7, 0), Vector2i(7, 0), Vector2i(7, 0), &"cutout", {"height": PAD_HEIGHT}],
	BlockIds.MUD: [Vector2i(0, 1), Vector2i(0, 1), Vector2i(0, 1), &"opaque"],
	BlockIds.STONE_BRICK: [Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1), &"opaque"],
	BlockIds.MOSSY_BRICK: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1), &"opaque"],
	BlockIds.PLASTER: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.ROOF_TILES: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.HAY: [Vector2i(6, 1), Vector2i(5, 1), Vector2i(6, 1), &"opaque"],
	BlockIds.WHEAT: [Vector2i(7, 1), Vector2i(7, 1), Vector2i(7, 1), &"pass", {"cross": true}],
	BlockIds.SAIL: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"opaque"],
	BlockIds.GLOW_MUSHROOM: [Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 2), &"glow"],
	BlockIds.PATH: [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
