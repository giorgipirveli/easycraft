extends SceneTree
## Generates data/blocks/pages/frost.png: block atlas page 2 (Frostpeak, M3 Task 3), an 8 x 8 grid of
## 16 x 16 pixel-art tiles in the style of tools/make_atlas.gd (original work).
## Run: godot --headless --path . --script res://tools/make_frost_atlas.gd
## Tile coordinates must match world/universes/frost_blocks.gd TILES. Append new tiles at the end of
## _init (with their own RNG), so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/frost.png"

const SNOW := Color("f4f8fc")
const SNOW_SHADE := Color("d8e4f0")
const PACKED := Color("e2ebf4")
const PACKED_SHADE := Color("c3d2e2")
const ICE := Color("a9d4f2")
const ICE_DARK := Color("7fb6e0")
const BLUE_ICE := Color("5b9fe6")
const BLUE_ICE_DARK := Color("3d7fcc")
const DIRT := Color("8a6446")
const DIRT_DARK := Color("6e4d35")
const BARK := Color("5b4030")
const BARK_DARK := Color("3f2c20")
const NEEDLES := Color("2f6b45")
const NEEDLES_DARK := Color("1f4d31")
const STONE := Color("8d949c")
const CRYSTAL := Color("8fe9ff")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260925
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_snow(Vector2i(0, 0))
	_snowy_grass_side(Vector2i(1, 0))
	_dirt(Vector2i(2, 0))
	_packed_snow(Vector2i(3, 0))
	_ice(Vector2i(4, 0), ICE, ICE_DARK)
	_ice(Vector2i(5, 0), BLUE_ICE, BLUE_ICE_DARK)
	_pine_side(Vector2i(6, 0))
	_pine_top(Vector2i(7, 0))
	_needles(Vector2i(0, 1), false)
	_needles(Vector2i(1, 1), true)
	_frozen_ore(Vector2i(2, 1))
	_snow_brick(Vector2i(3, 1))
	_lantern_side(Vector2i(4, 1))
	_lantern_top(Vector2i(5, 1))
	_frosted_glass(Vector2i(6, 1))
	_fake_snow(Vector2i(7, 1))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("FROST_ATLAS saved err=", err)
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


## Fresh snow: nearly white with soft blue-grey hollows and a few sparkles.
func _snow(t: Vector2i) -> void:
	_noise_tile(t, SNOW, 0.02)
	for i in 9:
		var x := rng.randi_range(0, 14)
		var y := rng.randi_range(0, 15)
		_px(t, x, y, SNOW_SHADE)
		_px(t, x + 1, y, SNOW_SHADE.lerp(SNOW, 0.5))
	for i in 4:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## Frozen dirt with a thick lip of snow over the top, dripping down unevenly.
func _snowy_grass_side(t: Vector2i) -> void:
	_dirt(t)
	for x in TILE:
		var lip := 4 + (1 if rng.randf() < 0.45 else 0) + (1 if x % 5 == 2 else 0)
		for y in lip:
			_px(t, x, y, _vary(SNOW if y < lip - 1 else SNOW_SHADE, 0.02))


func _dirt(t: Vector2i) -> void:
	_noise_tile(t, DIRT, 0.04)
	for i in 14:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), DIRT_DARK)
	for i in 5:                            # little frost specks
		_px(t, rng.randi_range(0, 15), rng.randi_range(4, 15), Color("c9d6e0"))


## Packed snow: smooth and a little greyer, with pressed-in lines.
func _packed_snow(t: Vector2i) -> void:
	_noise_tile(t, PACKED, 0.02)
	for y in [4, 11]:
		for x in TILE:
			if rng.randf() < 0.8:
				_px(t, x, y, _vary(PACKED_SHADE, 0.02))


## Clear ice: a pale (or deep) blue with white streaks and darker cracks: children see it is slippery.
func _ice(t: Vector2i, base: Color, dark: Color) -> void:
	for y in TILE:
		for x in TILE:
			var band := sin((x + y * 0.6) * 0.7) * 0.04
			_px(t, x, y, _vary(Color(base.r + band, base.g + band, base.b + band), 0.015))
	for i in 3:                            # white shine streaks
		var sx := rng.randi_range(0, 10)
		var sy := rng.randi_range(3, 15)
		for k in 5:
			if sy - k >= 0:
				_px(t, sx + k, sy - k, Color(1, 1, 1).lerp(base, 0.25))
	var x := rng.randi_range(3, 12)        # a crack
	for y in range(2, 14):
		_px(t, clampi(x, 0, 15), y, dark)
		if y % 3 == 0:
			x += rng.randi_range(-1, 1)


## Pine bark: dark vertical furrows.
func _pine_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var furrow := x % 4 == 0 or (x % 4 == 2 and (y + x) % 5 == 0)
			_px(t, x, y, _vary(BARK_DARK if furrow else BARK, 0.03))


## A pine log's end: pale wood rings, snow dusted at the rim.
func _pine_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := BARK if d > 6.5 else (Color("b98a5c") if int(d) % 3 == 0 else Color("d2a676"))
			_px(t, x, y, _vary(c, 0.03))


## Pine needles: dense dark-green clusters with gaps (cutout); the top has snow lying on it.
func _needles(t: Vector2i, snowy: bool) -> void:
	for y in TILE:
		for x in TILE:
			var needle := (x * 3 + y * 5) % 7 < 5
			if not needle and rng.randf() < 0.7:
				continue
			var c := NEEDLES_DARK if (x + y) % 3 == 0 else NEEDLES
			if snowy and (rng.randf() < 0.55 or (x / 4 + y / 4) % 2 == 0):
				c = SNOW if rng.randf() < 0.7 else SNOW_SHADE
			_px(t, x, y, _vary(c, 0.035))


## Stone with glittering ice crystals in it.
func _frozen_ore(t: Vector2i) -> void:
	_noise_tile(t, STONE, 0.05)
	for i in 5:
		var cx := rng.randi_range(2, 13)
		var cy := rng.randi_range(2, 13)
		for p: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			_px(t, cx + p.x, cy + p.y, _vary(CRYSTAL if p != Vector2i.ZERO else Color.WHITE, 0.03))


## Snow bricks: big white bricks with blue-grey joints.
func _snow_brick(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var joint := y % 8 == 0 or (x == 0 and y < 8) or (x == 8 and y >= 8)
			_px(t, x, y, _vary(PACKED_SHADE if joint else SNOW, 0.02))


## An ice lantern: a cold blue-white glow in a frame of packed snow.
func _lantern_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frame := x < 2 or x > 13 or y < 2 or y > 13
			var glow := Color("e8fbff").lerp(Color("7fd8ff"), clampf(Vector2(x - 7.5, y - 7.5).length() / 7.0, 0, 1))
			_px(t, x, y, _vary(PACKED_SHADE, 0.02) if frame else glow)


func _lantern_top(t: Vector2i) -> void:
	_noise_tile(t, PACKED_SHADE, 0.02)
	for y in range(5, 11):
		for x in range(5, 11):
			_px(t, x, y, Color("c8f4ff"))


## Frosted glass: a white frame, a frosty haze in the corners, clear in the middle.
func _frosted_glass(t: Vector2i) -> void:
	var frame := Color("e8f2fa")
	for i in TILE:
		_px(t, i, 0, frame)
		_px(t, i, TILE - 1, frame)
		_px(t, 0, i, frame)
		_px(t, TILE - 1, i, frame)
	for y in range(1, 15):
		for x in range(1, 15):
			var corner := minf(minf(x, 15 - x), minf(y, 15 - y))
			if corner < 3 and rng.randf() < 0.8 - corner * 0.2:
				_px(t, x, y, Color(0.92, 0.96, 1.0, 0.85))
	for i in 4:
		_px(t, 5 + i, 9 - i, Color(1, 1, 1, 0.9))


## Packed snow with a faint crack (a hidden way down: Frostpeak's fake wall).
func _fake_snow(t: Vector2i) -> void:
	_packed_snow(t)
	var crack := PACKED_SHADE.darkened(0.12)
	var x := 5
	for y in range(3, 14):
		_px(t, x, y, crack)
		if y % 3 == 0:
			x += 1 if y % 2 == 0 else -1
	for k in 4:
		_px(t, 5 + k, 8, crack)
