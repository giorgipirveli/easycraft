class_name LabPage
extends RefCounted
## Block atlas page 19 (ids 352-367; spec §23, the Science Lab): the lab bench, a white bench with a glass flask and a
## tiny burner (our own look, spec §3c). A tap on it opens the Lab (BlockInteractor.lab_bench_tapped). The pixel page is
## drawn by tools/make_lab_page.gd, its realistic twin by tools/make_lab_page.py (painted from the pixel design with CC0
## ambientCG grain), both in the same 8 x 8 layout. BlockLibrary registers the page when it loads, so every library,
## icon and break particle has it (a child carries a bench anywhere).

const PAGE := 19
const FILES := ["res://data/blocks/pages/lab.png", "res://data/blocks/pages/lab_albedo.png",
	"res://data/blocks/pages/lab_normal.png"]

## id -> [top, side, bottom, kind] (BlockLibrary.register_page).
const TILES := {
	BlockIds.LAB_BENCH: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), &"opaque"],
}


static func register() -> void:
	BlockLibrary.register_page(PAGE, FILES, TILES)
