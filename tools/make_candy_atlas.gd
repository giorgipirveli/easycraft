extends SceneTree
## Generates data/blocks/pages/candy.png: block atlas page 8 (the Candy Kingdom, M3 Task 4), an 8 x 8 grid
## of 16 x 16 pixel-art tiles in the style of tools/make_atlas.gd (original work).
## Run: godot --headless --path . --script res://tools/make_candy_atlas.gd
## Tile coordinates must match world/universes/candy_blocks.gd TILES. Append new tiles at the end of
## _init (with their own RNG), so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/candy.png"

const PINK := Color("ff9ec8")          # strawberry frosting
const PINK_DARK := Color("ec78ad")
const PINK_LIGHT := Color("ffc6e0")
const SPONGE := Color("f2c46d")
const SPONGE_DARK := Color("d6a24a")
const CHOCO := Color("6b3a1f")
const CHOCO_DARK := Color("47230f")
const CHOCO_LIGHT := Color("8c5230")
const CANE_RED := Color("e8283c")
const CANE_WHITE := Color("fff4f4")
const GUM_GREEN := Color("46c24a")
const GUM_RED := Color("ff4f6d")
const CREAM := Color("fff7ea")
const CREAM_SHADE := Color("eadcc5")
const JAM := Color("d61f3c")
const JAM_DARK := Color("a1122a")
const GINGER := Color("b86b2e")
const GINGER_DARK := Color("8c4d1c")
const ICING := Color("ffffff")
const GOLD := Color("f7c52b")
const SPRINKLE_COLORS: Array[Color] = [Color("ff3b5c"), Color("ffd23f"), Color("3fb5ff"), Color("5ee05e"),
	Color("ffffff"), Color("b57bff"), Color("ff8a3d")]

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260925
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_frosting_top(Vector2i(0, 0))
	_frosting_side(Vector2i(1, 0))
	_sponge(Vector2i(2, 0))
	_chocolate(Vector2i(3, 0))
	_cane_side(Vector2i(4, 0))
	_cane_top(Vector2i(5, 0))
	_lollipop(Vector2i(6, 0))
	_gumdrop(Vector2i(7, 0), GUM_GREEN)
	_gumdrop(Vector2i(0, 1), GUM_RED)
	_cream(Vector2i(1, 1))
	_jam(Vector2i(2, 1))
	_sugar_glass(Vector2i(3, 1))
	_gingerbread_side(Vector2i(4, 1))
	_gingerbread_top(Vector2i(5, 1))
	_lamp_side(Vector2i(6, 1))
	_lamp_top(Vector2i(7, 1))
	_cotton_candy(Vector2i(0, 2))
	_sprinkles_top(Vector2i(1, 2))
	_golden_candy(Vector2i(2, 2))
	_fake_chocolate(Vector2i(3, 2))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("CANDY_ATLAS saved err=", err)
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _noise_tile(t: Vector2i, base: Color, amount: float) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(base, amount))


## Pink icing: smooth, with a soft shine in swirls.
func _frosting_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var swirl := sin((x + y * 0.6) * 0.8) + cos((y - x * 0.4) * 0.7)
			_px(t, x, y, _vary(PINK_LIGHT if swirl > 1.3 else PINK, 0.02))


## Cake sponge with a thick layer of pink icing on top that drips down a little.
func _frosting_side(t: Vector2i) -> void:
	_sponge(t)
	for x in TILE:
		var drip := 4 + (2 if x % 5 == 2 else 0) + (1 if x % 7 == 4 else 0) + rng.randi_range(0, 1)
		for y in drip:
			_px(t, x, y, _vary(PINK_LIGHT if y == 0 else (PINK_DARK if y == drip - 1 else PINK), 0.02))


## Golden sponge with little air holes.
func _sponge(t: Vector2i) -> void:
	_noise_tile(t, SPONGE, 0.03)
	for i in 14:
		var x := rng.randi_range(0, 14)
		var y := rng.randi_range(0, 15)
		_px(t, x, y, SPONGE_DARK)
		if rng.randf() < 0.5:
			_px(t, x + 1, y, SPONGE_DARK.darkened(0.08))


## A chocolate bar: four squares with light top-left bevels and dark grooves.
func _chocolate(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var gx := x % 8
			var gy := y % 8
			var c := CHOCO
			if gx == 7 or gy == 7:
				c = CHOCO_DARK
			elif gx == 0 or gy == 0:
				c = CHOCO_LIGHT
			_px(t, x, y, _vary(c, 0.015))


## Red and white stripes going round the cane (diagonal on its side).
func _cane_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var band := posmod(x + y, 8)
			var c := CANE_RED if band < 3 else CANE_WHITE
			if band == 3 or band == 7:
				c = c.darkened(0.08)
			_px(t, x, y, _vary(c, 0.015))


## The cane's end: white with a red spiral.
func _cane_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5)
			var a := atan2(d.y, d.x)
			var spiral := posmod(int(floor((a / TAU) * 6.0 + d.length() * 0.45)), 2) == 0
			var rim := d.length() > 7.2
			_px(t, x, y, _vary(CANE_RED.darkened(0.15) if rim else (CANE_RED if spiral else CANE_WHITE), 0.015))


## A swirly lollipop: pink, white and yellow bands turning round the middle.
func _lollipop(t: Vector2i) -> void:
	var bands: Array[Color] = [Color("ff5ca8"), CANE_WHITE, Color("ffd23f"), CANE_WHITE, Color("5cc8ff"), CANE_WHITE]
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5)
			var a := atan2(d.y, d.x)
			var k := posmod(int(floor((a / TAU) * 6.0 + d.length() * 0.55)), bands.size())
			_px(t, x, y, _vary(bands[k], 0.015))
	for p: Vector2i in [Vector2i(4, 3), Vector2i(5, 3), Vector2i(3, 4)]:
		_px(t, p.x, p.y, Color(1, 1, 1))   # a shine


## Sugar-coated jelly: its colour, sugar crystals, a light shine at the top.
func _gumdrop(t: Vector2i, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			var shade := c.lightened(0.18) if y < 4 else (c.darkened(0.15) if y > 12 else c)
			_px(t, x, y, _vary(shade, 0.025))
	for i in 22:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color(1, 1, 1, 1).lerp(c, rng.randf_range(0.0, 0.35)))


## Whipped cream: white with soft shaded swirls.
func _cream(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var swirl := sin(x * 0.9 + sin(y * 0.7) * 2.0)
			_px(t, x, y, _vary(CREAM_SHADE if swirl > 0.75 else CREAM, 0.015))


## Strawberry jam: glossy red with little seeds.
func _jam(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var gloss := sin(x * 0.5 + y * 0.3) > 0.8
			_px(t, x, y, _vary(JAM.lightened(0.2) if gloss else (JAM_DARK if (x * 3 + y) % 11 == 0 else JAM), 0.02))
	for i in 9:
		_px(t, rng.randi_range(1, 14), rng.randi_range(1, 14), Color("f7d36b"))


## Clear pink candy glass with a sugary frame and two shines.
func _sugar_glass(t: Vector2i) -> void:
	var frame := Color("ffb8dc")
	for i in TILE:
		_px(t, i, 0, frame)
		_px(t, i, TILE - 1, frame)
		_px(t, 0, i, frame)
		_px(t, TILE - 1, i, frame)
	for y in range(1, 15):
		for x in range(1, 15):
			if rng.randf() < 0.05:
				_px(t, x, y, Color(1.0, 0.8, 0.92, 0.7))
	for i in 5:
		_px(t, 3 + i, 8 - i, Color(1, 1, 1, 0.9))
		_px(t, 9 + i, 13 - i, Color(1, 1, 1, 0.8))


## Gingerbread with a white icing zigzag round its edge and two buttons.
func _gingerbread_side(t: Vector2i) -> void:
	_noise_tile(t, GINGER, 0.03)
	for x in TILE:
		var zig := 1 + (x % 4 if x % 4 < 2 else 3 - x % 4)
		_px(t, x, zig, ICING)
		_px(t, x, TILE - 1 - zig, ICING)
	for p: Vector2i in [Vector2i(7, 6), Vector2i(8, 6), Vector2i(7, 9), Vector2i(8, 9)]:
		_px(t, p.x, p.y, Color("ff4f6d"))


func _gingerbread_top(t: Vector2i) -> void:
	_noise_tile(t, GINGER, 0.03)
	for i in 8:
		_px(t, rng.randi_range(1, 14), rng.randi_range(1, 14), GINGER_DARK)
	for i in TILE:
		_px(t, i, 0, ICING)
		_px(t, i, 15, ICING)


## A glowing gumdrop lamp: a warm light in a pink sugar frame.
func _lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frame := x < 2 or x > 13 or y < 2 or y > 13
			var glow := Color("fff3a0").lerp(Color("ffb347"), clampf(Vector2(x - 7.5, y - 7.5).length() / 7.0, 0, 1))
			_px(t, x, y, _vary(Color("ff7ab8"), 0.02) if frame else glow)


func _lamp_top(t: Vector2i) -> void:
	_noise_tile(t, Color("ff7ab8"), 0.02)
	for y in range(5, 11):
		for x in range(5, 11):
			_px(t, x, y, Color("fff3a0"))


## Fluffy pink cotton candy: soft round puffs on see-through (a bush you walk through).
func _cotton_candy(t: Vector2i) -> void:
	var puffs: Array[Vector3] = [Vector3(5, 9, 4.2), Vector3(10, 8, 4.6), Vector3(8, 4, 3.8), Vector3(4, 13, 2.8),
		Vector3(12, 13, 2.8), Vector3(8, 11, 3.5)]
	for y in TILE:
		for x in TILE:
			for p: Vector3 in puffs:
				var d := Vector2(x - p.x, y - p.y).length()
				if d <= p.z:
					var c := Color("ffd6ec") if d < p.z * 0.5 else Color("ffb3dc")
					if (x + y) % 5 == 0:
						c = Color("f58cc4")
					_px(t, x, y, _vary(c, 0.02))
					break


## Pink frosting covered in rainbow sprinkles.
func _sprinkles_top(t: Vector2i) -> void:
	_noise_tile(t, PINK, 0.02)
	for i in 16:
		var x := rng.randi_range(0, 14)
		var y := rng.randi_range(0, 14)
		var c := SPRINKLE_COLORS[i % SPRINKLE_COLORS.size()]
		_px(t, x, y, c)
		if i % 2 == 0:
			_px(t, x + 1, y, c)
		else:
			_px(t, x, y + 1, c)


## A golden wrapped sweet: shiny gold with a bright twist at each side.
func _golden_candy(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == 15 or y == 15
			var shine := (x + y) % 6 == 0
			_px(t, x, y, _vary(GOLD.lightened(0.3) if shine else (GOLD.darkened(0.2) if edge else GOLD), 0.02))
	for y in range(5, 11):
		_px(t, 2, y, GOLD.lightened(0.45))
		_px(t, 13, y, GOLD.lightened(0.45))


## Chocolate with a faint crack down it (a hidden door: the Candy Kingdom's fake wall).
func _fake_chocolate(t: Vector2i) -> void:
	_chocolate(t)
	var crack := CHOCO_DARK.darkened(0.25)
	var x := 7
	for y in range(3, 15):
		_px(t, x, y, crack)
		if y % 3 == 0:
			x += 1 if y % 2 == 0 else -1
