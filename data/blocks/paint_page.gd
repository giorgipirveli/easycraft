class_name PaintPage
extends RefCounted
## Block atlas page 12 (ids 240-255; M3 Task 8): the 16 painted blocks, in both styles. The pixel page is drawn by
## tools/make_paint_page.gd (smooth painted plaster, one tile per tint: rows 0 and 1), its realistic twin by
## tools/make_paint_page.py (CC0 ambientCG plaster, tinted). Registered as BlockLibrary loads and before every
## block library is built, so every world, icon and break particle has them. One page, one shared material:
## all 16 tints together cost a chunk one draw call.

const PAGE := 12
const FILES := ["res://data/blocks/pages/paint.png", "res://data/blocks/pages/paint_albedo.png",
	"res://data/blocks/pages/paint_normal.png"]


## Tint t's tile: row 0 holds tints 0-7, row 1 tints 8-15.
static func tile_of(tint: int) -> Vector2i:
	return Vector2i(tint % 8, tint / 8)


## [top, side, bottom] per painted block: the same tile on every face.
static func tiles() -> Dictionary:
	var out := {}
	for t in PaintRules.COUNT:
		var tile := tile_of(t)
		out[PaintRules.block_of(t)] = [tile, tile, tile]
	return out


## Registers page 12 once (again after a test unregistered it).
static func register() -> void:
	if BlockLibrary.tiles_of(BlockIds.PAINTED_WHITE).is_empty():
		BlockLibrary.register_page(PAGE, FILES, tiles())
