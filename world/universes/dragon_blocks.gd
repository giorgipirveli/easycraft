class_name DragonBlocks
extends RefCounted
## The Dragon Realm's blocks on block atlas page 11 (owner feedback #39, spec §14.2a; ids in BlockIds 224-238, 239
## free). The pixel page is drawn by tools/make_dragon_atlas.gd, its realistic twin by tools/make_dragon_realistic.py
## (CC0 ambientCG textures), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every
## library, icon and break particle has it.

const PAGE := 11
const FILES := ["res://data/blocks/pages/dragon.png", "res://data/blocks/pages/dragon_albedo.png",
	"res://data/blocks/pages/dragon_normal.png"]
## Starglass's transparency index: 1-5 are taken (leaves, glass, water, the desert's glass, frosted and sugar glass).
const STARGLASS_TRANSPARENCY := 6

## id -> [top, side, bottom, kind, extras] (BlockLibrary.register_page; extras: walk_through, transparency).
const TILES := {
	BlockIds.SKY_GRASS: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.FLOATSTONE: [Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.DEEP_FLOATSTONE: [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), &"opaque"],
	BlockIds.CRYSTAL_SPIRE: [Vector2i(5, 0), Vector2i(4, 0), Vector2i(5, 0), &"glow"],
	BlockIds.MUSHROOM_STEM: [Vector2i(7, 0), Vector2i(6, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.GLOW_CAP: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), &"glow"],
	BlockIds.DRAGON_SCALE: [Vector2i(3, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.EMBER_SCALE: [Vector2i(4, 1), Vector2i(4, 1), Vector2i(4, 1), &"opaque"],
	BlockIds.STARGLASS: [Vector2i(5, 1), Vector2i(5, 1), Vector2i(5, 1), &"cutout", {"transparency": STARGLASS_TRANSPARENCY}],
	BlockIds.MOON_LAMP: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"glow"],
	BlockIds.CLOUD: [Vector2i(0, 2), Vector2i(0, 2), Vector2i(0, 2), &"cutout", {"walk_through": true}],
	BlockIds.NEST: [Vector2i(1, 2), Vector2i(2, 2), Vector2i(2, 2), &"opaque"],
	BlockIds.FLOATSTONE_BRICK: [Vector2i(3, 2), Vector2i(3, 2), Vector2i(3, 2), &"opaque"],
	BlockIds.DRAGON_GOLD: [Vector2i(4, 2), Vector2i(4, 2), Vector2i(4, 2), &"glow"],
	BlockIds.FAKE_FLOATSTONE: [Vector2i(2, 0), Vector2i(5, 2), Vector2i(2, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
