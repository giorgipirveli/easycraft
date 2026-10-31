extends SceneTree
## Generates data/blocks/pages/tiny.png: block atlas page 14 (M3 Task 21c, the wonder pack), an 8 x 8 grid of
## 16 x 16 pixel-art tiles in the style of tools/make_atlas.gd (original work): the pumpkin, the jack-o-lantern,
## the snowman's head and the mice's tiny cheese.
## Run: godot --headless --path . --script res://tools/make_tiny_page.gd
## Tile coordinates must match data/blocks/tiny_page.gd TILES. Append new tiles at the end of _init (with their own
## RNG), so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/tiny.png"

const ORANGE := Color("f08a24")
const ORANGE_DARK := Color("c4661a")
const ORANGE_DEEP := Color("9c4a12")
const ORANGE_LIGHT := Color("ffae4f")
const STEM := Color("6b8f2a")
const STEM_DARK := Color("4a6a1c")
const CARVED := Color("ffd23f")
const CARVED_HOT := Color("fff3a8")
const CARVED_EDGE := Color("e0892a")
const SNOW := Color("f4f8fc")
const SNOW_SHADE := Color("dde6f0")
const COAL := Color("25262b")
const COAL_LIGHT := Color("45474f")
const CARROT := Color("ff7a1f")
const CARROT_DARK := Color("d35a10")
const HAT := Color("2a2a30")
const HAT_TOP := Color("3b3c44")
const HAT_BAND := Color("d63a3a")
const CHEESE := Color("ffd04a")
const CHEESE_LIGHT := Color("ffe27a")
const CHEESE_HOLE := Color("d9a21e")
const CHEESE_RIND := Color("f2b82e")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260925 + 21
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_pumpkin_top(Vector2i(0, 0), false)
	_pumpkin_side(Vector2i(1, 0))
	_pumpkin_bottom(Vector2i(2, 0))
	_pumpkin_top(Vector2i(3, 0), true)
	_pumpkin_side(Vector2i(4, 0))
	_carve_face(Vector2i(4, 0))
	_snow_hat(Vector2i(5, 0))
	_snow(Vector2i(7, 0))
	_snow(Vector2i(6, 0))
	_snow_face(Vector2i(6, 0))
	_cheese_top(Vector2i(0, 1))
	_cheese_side(Vector2i(1, 1))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("TINY_PAGE saved err=", err)
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= TILE or y >= TILE:
		return
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## Orange ribs from top to bottom: darker grooves, a light stripe on each bulge.
func _pumpkin_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var groove := x == 0 or x == 5 or x == 10 or x == 15
			var shine := x == 2 or x == 7 or x == 12
			var c := ORANGE_DARK if groove else (ORANGE_LIGHT if shine and y > 2 and y < 13 else ORANGE)
			if y == 0 or y == 15:
				c = ORANGE_DEEP if groove else ORANGE_DARK
			_px(t, x, y, _vary(c, 0.03))


## Seen from above: the ribs run to the middle, where the green stem stands (a jack-o-lantern's lid is cut round
## it).
func _pumpkin_top(t: Vector2i, lid: bool) -> void:
	for y in TILE:
		for x in TILE:
			var dx := x - 7.5
			var dy := y - 7.5
			var a := atan2(dy, dx)
			var rib := absf(fposmod(a * 4.0 / PI, 1.0) - 0.5) < 0.1
			var c := ORANGE_DARK if rib else ORANGE
			if lid and absf(sqrt(dx * dx + dy * dy) - 4.5) < 0.6:
				c = ORANGE_DEEP   # the lid's cut
			_px(t, x, y, _vary(c, 0.03))
	for y in range(6, 10):
		for x in range(6, 10):
			_px(t, x, y, _vary(STEM_DARK if x == 6 or y == 9 else STEM, 0.03))
	_px(t, 10, 6, _vary(STEM, 0.02))   # a curly bit of the stem
	_px(t, 11, 5, _vary(STEM, 0.02))


func _pumpkin_bottom(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var dx := x - 7.5
			var dy := y - 7.5
			var c := ORANGE_DARK if sqrt(dx * dx + dy * dy) > 6.0 else ORANGE
			_px(t, x, y, _vary(c, 0.03))


## A friendly carved face that glows: triangle eyes, a triangle nose and a wide smile with two teeth-gaps.
func _carve_face(t: Vector2i) -> void:
	for eye_x in [4, 11]:
		for row in 3:
			for dx in range(-row, row + 1):
				_px(t, eye_x + dx, 4 + row, CARVED_HOT if row == 2 and dx == 0 else CARVED)
	_px(t, 7, 8, CARVED)
	_px(t, 8, 8, CARVED)
	for x in range(3, 13):
		var y := 11 if x > 3 and x < 12 else 10
		_px(t, x, y, CARVED_HOT)
		if x > 4 and x < 11:
			_px(t, x, 12, CARVED if x != 6 and x != 9 else CARVED_EDGE)
	for x in [3, 12]:
		_px(t, x, 9, CARVED_EDGE)


func _snow(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(SNOW_SHADE if rng.randf() < 0.18 else SNOW, 0.02))


## Coal eyes, a carrot nose and a smile of coal pebbles.
func _snow_face(t: Vector2i) -> void:
	for p: Vector2i in [Vector2i(4, 4), Vector2i(5, 4), Vector2i(4, 5), Vector2i(5, 5),
			Vector2i(10, 4), Vector2i(11, 4), Vector2i(10, 5), Vector2i(11, 5)]:
		_px(t, p.x, p.y, COAL if (p.x + p.y) % 2 == 0 else COAL_LIGHT)
	for p: Vector2i in [Vector2i(7, 7), Vector2i(8, 7), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8)]:
		_px(t, p.x, p.y, CARROT)
	_px(t, 10, 8, CARROT_DARK)
	for p: Vector2i in [Vector2i(4, 10), Vector2i(5, 11), Vector2i(7, 12), Vector2i(8, 12), Vector2i(10, 11),
			Vector2i(11, 10)]:
		_px(t, p.x, p.y, COAL)


## A snowman's top hat seen from above: a black brim round a crown with a red band.
func _snow_hat(t: Vector2i) -> void:
	_snow(t)
	for y in range(2, 14):
		for x in range(2, 14):
			_px(t, x, y, _vary(HAT, 0.02))
	for y in range(4, 12):
		for x in range(4, 12):
			var band := x == 4 or x == 11 or y == 4 or y == 11
			_px(t, x, y, HAT_BAND if band else _vary(HAT_TOP, 0.02))


func _cheese_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(CHEESE_LIGHT if (x + y) % 7 == 0 else CHEESE, 0.02))
	_holes(t, [Vector2i(4, 4), Vector2i(11, 6), Vector2i(6, 11), Vector2i(12, 12)])


func _cheese_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(CHEESE_RIND if y < 2 else CHEESE, 0.02))
	_holes(t, [Vector2i(3, 6), Vector2i(10, 4), Vector2i(7, 11), Vector2i(13, 12)])


func _holes(t: Vector2i, spots: Array[Vector2i]) -> void:
	for c: Vector2i in spots:
		for p: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_px(t, c.x + p.x, c.y + p.y, CHEESE_HOLE)
		_px(t, c.x - 1, c.y, CHEESE_RIND)
