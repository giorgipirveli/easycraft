class_name PortalPage
extends RefCounted
## Block atlas page 10 (ids 208-223; M3 Task 1's pages; M3 Task 5's blocks): the portal frame and the portal core, in
## both styles (M3 Task 14a: its zipline post and launch pad; M3 Task 20a: the saddle); its row 6 holds the crafting table and the furnace (spec §12.19, CRAFT_TILES). The pixel page is drawn by tools/make_portal_page.gd, its realistic twin by
## tools/make_portal_page.py (CC0 ambientCG stone). Registered before every block library is built
## (BlockLibrary.build), so every world, Sandbox too, has portals.

const PAGE := 10
const FILES := ["res://data/blocks/pages/portals.png", "res://data/blocks/pages/portals_albedo.png",
	"res://data/blocks/pages/portals_normal.png"]
## [top, side, bottom, kind]: the frame is carved stone with a rune; the core glows (unshaded).
const TILES := {
	BlockIds.PORTAL_FRAME: [Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0)],
	BlockIds.PORTAL_CORE: [Vector2i(3, 0), Vector2i(2, 0), Vector2i(3, 0), &"glow"],
	# M3 Task 14a: the zipline post (a wooden post with a pulley) and the launch pad (glows: orange chevrons).
	BlockIds.ZIPLINE_POST: [Vector2i(5, 0), Vector2i(4, 0), Vector2i(5, 0)],
	BlockIds.LAUNCH_PAD: [Vector2i(6, 0), Vector2i(7, 0), Vector2i(7, 0), &"glow"],
	# M3 Task 20a: the saddle (two tiles per id on this page: tile index 2 × (id − 208))
	BlockIds.SADDLE: [Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 2)],
}


## Registers page 10 once (again after a test unregistered it), with every task's tiles on it.
static func register() -> void:
	if BlockLibrary.tiles_of(BlockIds.PORTAL_CORE).is_empty():
		BlockLibrary.register_page(PAGE, FILES, all_tiles())


## Every block of the page: the portals' and the other tasks' (merged, so no task's tiles replace another's).
static func all_tiles() -> Dictionary:
	return TILES.merged(CRAFT_TILES).merged(CORE_TILES).merged(BOOK_TILES)

# --- M3 Task 21b: the trophy shelf and the bookshelf (two tiles per id at index 2 × (id − 208): side, then top) ---
## The trophy shelf is an open cabinet (cut out: its two shelves' trophies show through every side, TrophyShelves);
## the bookshelf is a full case of books (a tap opens the books). tools/make_portal_page.gd and .py draw them after
## the others' tiles with their own seed.
const BOOK_TILES := {
	BlockIds.TROPHY_SHELF: [Vector2i(3, 2), Vector2i(2, 2), Vector2i(3, 2), &"cutout"],
	BlockIds.BOOKSHELF: [Vector2i(5, 2), Vector2i(4, 2), Vector2i(5, 2)],
}

# --- Owner feedback #39: the universe portal cores (a crystal in a frame's core slot) --------------------------
## Each is the portal core's gem in its universe's colour (side: the gem in a violet setting; top: a star); both
## glow. Two tiles per id at index 2 × (id − 208): side first, then top (tools/make_portal_page.gd and .py draw
## them after the others' tiles with their own seed).
const CORE_TILES := {
	BlockIds.CORE_MEADOWS: [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1), &"glow"],
	BlockIds.CORE_DESERT: [Vector2i(3, 1), Vector2i(2, 1), Vector2i(3, 1), &"glow"],
	BlockIds.CORE_FROST: [Vector2i(5, 1), Vector2i(4, 1), Vector2i(5, 1), &"glow"],
	BlockIds.CORE_CANDY: [Vector2i(7, 1), Vector2i(6, 1), Vector2i(7, 1), &"glow"],
	BlockIds.CORE_DRAGON: [Vector2i(5, 3), Vector2i(4, 3), Vector2i(5, 3), &"glow"],
	BlockIds.CORE_GLOW: [Vector2i(7, 3), Vector2i(6, 3), Vector2i(7, 3), &"glow"],   # universe 6: the Glow Caves
}

# --- Survivor games and crafting (spec §12.19): row 6 of the page --------------------------------------
## The crafting table: a work top with a grid and tools, plank sides with a saw and a hammer, planks under it;
## the furnace: cobbled stone with a glowing mouth on its sides, a stone top (tools/make_portal_page.gd and
## .py draw them with their own seeds, so the other tiles stay the same).
const CRAFT_TILES := {
	BlockIds.CRAFTING_TABLE: [Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6)],
	BlockIds.FURNACE: [Vector2i(3, 6), Vector2i(4, 6), Vector2i(3, 6)],
}
