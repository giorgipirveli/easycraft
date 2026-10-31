class_name TinyPage
extends RefCounted
## Block atlas page 14 (ids 272-287; M3 Task 21c, the wonder pack): the pumpkin, the glowing jack-o-lantern and the
## snowman's head (things the Magic Wand wakes, WakeKinds) and the mice's tiny cheese (a mouse village's treasure).
## The pixel page is drawn by tools/make_tiny_page.gd, its realistic twin by tools/make_tiny_page.py (painted from
## the pixel designs with CC0 ambientCG grain), both in the same 8 x 8 layout. BlockLibrary registers the page when
## it loads, so every library, icon and break particle has it (a child carries these blocks anywhere).

const PAGE := 14
const FILES := ["res://data/blocks/pages/tiny.png", "res://data/blocks/pages/tiny_albedo.png",
	"res://data/blocks/pages/tiny_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page). Every side of a jack-o-lantern and of a snowman's
## head shows the face (the page has one side tile per block).
const TILES := {
	BlockIds.PUMPKIN: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.JACK_O_LANTERN: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(2, 0), &"glow"],
	BlockIds.SNOWMAN_HEAD: [Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), &"opaque"],
	BlockIds.CHEESE: [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 1), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
