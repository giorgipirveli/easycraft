class_name GanymedeBlocks
extends RefCounted
## Ganymede's blocks on block atlas page 43 (cosmos, spec §21b.2; ids in BlockIds 736-747, 748-751 free). The pixel page
## is drawn by tools/make_space_atlas.gd, its realistic twin by tools/make_space_realistic.py (CC0 ambientCG textures),
## both in the same 8 x 8 layout (three rows). BlockLibrary registers the page when it loads, so every library, icon and
## break particle has it. Under its ground Ganymede's crust is Pluto's water ice (page 41: as hard as rock in the cold);
## the landing pad and star gold are the Moon's (every space world's); the Solar Wing Lander's gold foil and solar panels
## are Mars's, its radio dish, truss and lamps the rings', the Jupiter Lookout's telescope Venus's and the ocean drill's
## deep blue ice and glow ice Europa's.

const PAGE := 43
const FILES := ["res://data/blocks/pages/ganymede.png", "res://data/blocks/pages/ganymede_albedo.png",
	"res://data/blocks/pages/ganymede_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.GROOVED_ICE: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.TROUGH_ICE: [Vector2i(2, 0), Vector2i(1, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.DARK_ICE: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.OLD_ICE: [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), &"opaque"],
	BlockIds.RAY_ICE: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(1, 0), &"opaque"],
	BlockIds.POLAR_FROST: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), &"opaque"],
	BlockIds.AURORA_CRYSTAL: [Vector2i(2, 1), Vector2i(2, 1), Vector2i(2, 1), &"glow"],
	BlockIds.JUPITER_GLOBE: [Vector2i(4, 1), Vector2i(3, 1), Vector2i(3, 1), &"opaque"],
	BlockIds.AURORA_LAMP: [Vector2i(6, 1), Vector2i(5, 1), Vector2i(6, 1), &"glow"],
	BlockIds.MAGNETOMETER: [Vector2i(0, 2), Vector2i(7, 1), Vector2i(0, 2), &"opaque"],
	BlockIds.GROOVE_BRICK: [Vector2i(1, 2), Vector2i(1, 2), Vector2i(1, 2), &"opaque"],
	BlockIds.FAKE_GROOVED_ICE: [Vector2i(0, 0), Vector2i(2, 2), Vector2i(1, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
