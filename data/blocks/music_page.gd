class_name MusicPage
extends RefCounted
## Block atlas page 44 (owner #110, VR round 4 idea 7): the music blocks, ids 752-753 (754-767 kept for more instruments
## on this page). The xylophone: eight bars in a child's xylophone's rainbow (MusicBlockRules.BAR_COLORS), C5 to C6 from the
## west end, longer bars lower; the bongos: a big low skin on the west half and a small high one on the east half, on red
## shells. A tap plays them; in VR mallets play them (MusicDirector). The pixel page and its realistic twin (painted
## from the pixel design, our own work) are drawn by tools/make_music_page.gd in the same 8 x 8 layout; BlockLibrary
## registers the page when it loads, so every library, icon and break particle has it.

const PAGE := 44
const FILES := ["res://data/blocks/pages/music.png", "res://data/blocks/pages/music_albedo.png",
	"res://data/blocks/pages/music_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.XYLOPHONE: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
	BlockIds.DRUM: [Vector2i(3, 0), Vector2i(4, 0), Vector2i(2, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
