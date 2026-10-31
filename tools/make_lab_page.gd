extends SceneTree
## Generates data/blocks/pages/lab.png: block atlas page 19 (spec §23, the Science Lab), an 8 x 8 grid of 16 x 16
## pixel-art tiles in the style of tools/make_atlas.gd (original work): the lab bench, a white bench with our teal
## knobs, a glass flask of green liquid and a tiny burner with a blue flame on the shelf above its worktop (the side),
## the flask and the burner seen from above on the white worktop (the top), and a plain panel (the bottom).
## Run: godot --headless --path . --script res://tools/make_lab_page.gd
## Tile coordinates must match data/blocks/lab_page.gd TILES. Append new tiles at the end of _init (with their own RNG),
## so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/lab.png"

const WHITE := Color("f4f6f8")
const WHITE_SHADE := Color("dfe5ec")
const EDGE := Color("aab6c4")
const WORKTOP := Color("2f3a4a")
const WORKTOP_HI := Color("4a5a70")
const TEAL := Color("139e9b")         # the brand's teal (spec §3c)
const TEAL_HI := Color("5fd3cf")
const BACK := Color("35506b")         # the shelf's back wall
const BACK_DARK := Color("2b4258")
const GLASS := Color("d6f1fb")
const GLASS_EDGE := Color("8fc7dc")
const LIQUID := Color("3fd46a")
const LIQUID_HI := Color("93f2ad")
const CORK := Color("b07a44")
const FLAME := Color("3a8ef0")
const FLAME_HI := Color("a8dcff")
const METAL := Color("8a95a3")
const METAL_DARK := Color("5b6572")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260929 + 23
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_top(Vector2i(0, 0))
	_side(Vector2i(1, 0))
	_bottom(Vector2i(2, 0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("LAB_PAGE saved err=", err)
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= TILE or y >= TILE:
		return
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _rect(t: Vector2i, x0: int, y0: int, x1: int, y1: int, c: Color, vary: float = 0.0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(t, x, y, _vary(c, vary) if vary > 0.0 else c)


## The worktop from above: white with a soft speckle and a grey edge; a round flask (glass ring, green liquid, a cork)
## and a burner (a metal ring round a blue flame).
func _top(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, WHITE, 0.02)
	for i in 16:
		_px(t, i, 0, EDGE)
		_px(t, i, 15, EDGE)
		_px(t, 0, i, EDGE)
		_px(t, 15, i, EDGE)
	var c := Vector2(5.5, 5.5)
	for y in 16:
		for x in 16:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= 0.8:
				_px(t, x, y, CORK)
			elif d <= 2.6:
				_px(t, x, y, LIQUID_HI if x + y < 10 else LIQUID)
			elif d <= 3.6:
				_px(t, x, y, GLASS_EDGE if x + y > 11 else GLASS)
	var b := Vector2(11.0, 11.0)
	for y in 16:
		for x in 16:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(b)
			if d <= 1.1:
				_px(t, x, y, FLAME_HI)
			elif d <= 1.9:
				_px(t, x, y, FLAME)
			elif d <= 2.9:
				_px(t, x, y, METAL if x + y < 22 else METAL_DARK)
	# a teal label strip at the front edge
	_rect(t, 2, 13, 7, 13, TEAL)


## The bench's front: a white frame, the shelf above the worktop with the flask and the burner, the dark worktop's
## edge, and a white cabinet with two doors and teal knobs.
func _side(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, WHITE, 0.015)
	_rect(t, 1, 1, 14, 7, BACK)
	for x in range(1, 15):
		_px(t, x, 1, BACK_DARK)   # the shelf's top in shadow
	# the flask: a cork, a narrow neck, a cone-shaped body with green liquid
	_rect(t, 5, 1, 6, 1, CORK)
	_rect(t, 5, 2, 6, 3, GLASS)
	var widths := {4: [4, 7], 5: [3, 8], 6: [3, 8], 7: [2, 9]}
	for y: int in widths:
		var w: Array = widths[y]
		for x in range(int(w[0]), int(w[1]) + 1):
			var edge := x == int(w[0]) or x == int(w[1])
			var c := GLASS_EDGE if edge else (LIQUID if y >= 5 else GLASS)
			if not edge and y == 5 and x < 6:
				c = LIQUID_HI
			_px(t, x, y, c)
	# the burner: a blue flame on a little metal stand
	_px(t, 11, 3, FLAME_HI)
	_rect(t, 11, 4, 12, 4, FLAME)
	_px(t, 12, 3, FLAME)
	_rect(t, 11, 5, 12, 5, METAL)
	_rect(t, 10, 6, 13, 6, METAL)
	_rect(t, 10, 7, 13, 7, METAL_DARK)
	# the worktop's edge
	_rect(t, 0, 8, 15, 8, WORKTOP_HI)
	_rect(t, 0, 9, 15, 9, WORKTOP)
	# the cabinet: two doors, a gap between them, teal knobs, a shadowed foot
	_rect(t, 7, 10, 8, 14, EDGE)
	for y in range(10, 15):
		_px(t, 0, y, WHITE_SHADE)
		_px(t, 15, y, WHITE_SHADE)
	_px(t, 6, 12, TEAL)
	_px(t, 9, 12, TEAL)
	_px(t, 6, 11, TEAL_HI)
	_px(t, 9, 11, TEAL_HI)
	_rect(t, 0, 15, 15, 15, EDGE)


## A plain light panel with a grey border.
func _bottom(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, WHITE_SHADE, 0.02)
	for i in 16:
		_px(t, i, 0, EDGE)
		_px(t, i, 15, EDGE)
		_px(t, 0, i, EDGE)
		_px(t, 15, i, EDGE)
