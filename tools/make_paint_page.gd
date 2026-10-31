extends SceneTree
## Generates data/blocks/pages/paint.png (M3 Task 8): block atlas page 12, an 8 x 8 grid of 16 x 16 pixel-art tiles
## for the 16 painted blocks (smooth painted plaster: the tint with a soft, fine grain and a bevel, so each block
## reads on its own in a painted wall). Its realistic twin is tools/make_paint_page.py (same layout).
## Run: godot --headless --path . --script res://tools/make_paint_page.gd
## Tile coordinates must match data/blocks/paint_page.gd (PaintPage.tile_of): tint t at (t % 8, t / 8), so row 0
## holds White ... Yellow and row 1 Lime ... Pink (PaintRules.TINTS). Free tiles: rows 2-7.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/paint.png"
const TINTS := [
	Color("f2f0ea"), Color("b8bec6"), Color("6d747c"), Color("2a2c31"), Color("875634"), Color("d8363d"),
	Color("f08622"), Color("f6cf36"), Color("8dd13d"), Color("37984a"), Color("24b3ab"), Color("6cc4f0"),
	Color("3462d4"), Color("8a4dd0"), Color("d24cc0"), Color("f498bd"),
]

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260927
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for t in TINTS.size():
		_plaster(Vector2i(t % 8, t / 8), TINTS[t])
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("wrote ", OUT)
	quit()


## Painted plaster: the tint, a fine grain (a little lighter or darker per pixel, stronger on dark tints so black
## still shows its grain), a light top-left edge and a darker bottom-right edge.
func _plaster(tile: Vector2i, c: Color) -> void:
	var grain := 0.035 if c.get_luminance() > 0.35 else 0.06
	for y in TILE:
		for x in TILE:
			var p := c
			var n := rng.randf_range(-grain, grain)
			if rng.randf() < 0.06:
				n -= grain * 1.5   # a tiny pit in the plaster
			p = p.lightened(n) if n > 0.0 else p.darkened(-n)
			if x == 0 or y == 0:
				p = p.lightened(0.14)
			elif x == TILE - 1 or y == TILE - 1:
				p = p.darkened(0.2)
			elif x == 1 or y == 1:
				p = p.lightened(0.05)
			p.a = 1.0
			img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, p)
