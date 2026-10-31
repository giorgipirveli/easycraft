extends SceneTree
## Generates data/blocks/pages/desert.png: block atlas page 1 (the Sandstorm Desert, M3 Task 2), an
## 8 x 8 grid of 16 x 16 pixel-art tiles in the style of tools/make_atlas.gd (original work).
## Run: godot --headless --path . --script res://tools/make_desert_atlas.gd
## Tile coordinates must match world/universes/desert_blocks.gd TILES. Append new tiles at the end of
## _init (with their own RNG), so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/desert.png"

const SAND := Color("f2d98c")          # page 0's sand (tools/make_atlas.gd), for the trap sand's lid
const SANDSTONE := Color("e6c77f")
const SANDSTONE_DARK := Color("c9a55c")
const SANDSTONE_LIGHT := Color("f3dca0")
const RED_SAND := Color("d9793e")
const RED_ROCK := Color("b8552c")
const CACTUS := Color("4f9a3c")
const CACTUS_DARK := Color("36722a")
const GOLD := Color("f7c52b")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260924
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_sandstone_top(Vector2i(0, 0))
	_sandstone_side(Vector2i(1, 0))
	_sandstone_bottom(Vector2i(2, 0))
	_cut_sandstone(Vector2i(3, 0))
	_chiseled_side(Vector2i(4, 0))
	_noise_tile(Vector2i(5, 0), RED_SAND, 0.06)                   # red sand
	_red_sandstone_side(Vector2i(6, 0))
	_noise_tile(Vector2i(7, 0), RED_ROCK.lightened(0.08), 0.05)   # red sandstone top
	_cactus_top(Vector2i(0, 1))
	_cactus_side(Vector2i(1, 1))
	_cactus_bottom(Vector2i(2, 1))
	_dead_bush(Vector2i(3, 1))
	_desert_glass(Vector2i(4, 1))
	_palm_side(Vector2i(5, 1))
	_palm_top(Vector2i(6, 1))
	_palm_leaves(Vector2i(7, 1))
	_pyramid_gold(Vector2i(0, 2))
	_lamp_side(Vector2i(1, 2))
	_lamp_top(Vector2i(2, 2))
	_arrow_slit(Vector2i(3, 2))
	_trap_sand(Vector2i(4, 2))
	_fake_sandstone(Vector2i(5, 2))
	_chiseled_top(Vector2i(6, 2))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("DESERT_ATLAS saved err=", err)
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


func _sandstone_top(t: Vector2i) -> void:
	_noise_tile(t, SANDSTONE_LIGHT, 0.04)
	for i in 6:                            # a few darker grains
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), SANDSTONE_DARK)


## Layers of sandstone: light and dark bands, a smooth rim on top.
func _sandstone_side(t: Vector2i) -> void:
	for y in TILE:
		var band := SANDSTONE_LIGHT if y < 3 else (SANDSTONE if (y / 3) % 2 == 1 else SANDSTONE.lerp(SANDSTONE_DARK, 0.35))
		for x in TILE:
			_px(t, x, y, _vary(band, 0.035))
	for x in TILE:
		_px(t, x, 3, _vary(SANDSTONE_DARK, 0.03))


func _sandstone_bottom(t: Vector2i) -> void:
	_noise_tile(t, SANDSTONE.lerp(SANDSTONE_DARK, 0.3), 0.05)


## Big smooth sandstone bricks with dark joints.
func _cut_sandstone(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var joint := y == 0 or y == 8 or (x == 0 and y < 8) or (x == 8 and y >= 8)
			_px(t, x, y, _vary(SANDSTONE_DARK if joint else SANDSTONE, 0.03))


## A carved face: a frame and a big eye (the pyramids' pictures).
func _chiseled_side(t: Vector2i) -> void:
	_noise_tile(t, SANDSTONE, 0.03)
	var dark := SANDSTONE_DARK.darkened(0.15)
	for i in TILE:
		for p: Vector2i in [Vector2i(i, 1), Vector2i(i, 14), Vector2i(1, i), Vector2i(14, i)]:
			_px(t, p.x, p.y, dark)
	for x in range(4, 12):                 # the eye
		var h := 2 - absi(x - 7) / 2 if x <= 7 else 2 - absi(x - 8) / 2
		_px(t, x, 8 - h, dark)
		_px(t, x, 8 + h, dark)
	for y in range(7, 10):
		for x in range(7, 9):
			_px(t, x, y, dark)
	for y in range(10, 13):                # the tear line
		_px(t, 6 - (y - 10), y, dark)


func _chiseled_top(t: Vector2i) -> void:
	_noise_tile(t, SANDSTONE_LIGHT, 0.03)
	var dark := SANDSTONE_DARK
	for i in range(3, 13):
		for p: Vector2i in [Vector2i(i, 3), Vector2i(i, 12), Vector2i(3, i), Vector2i(12, i)]:
			_px(t, p.x, p.y, dark)
	for y in range(6, 10):
		for x in range(6, 10):
			_px(t, x, y, dark)


## Red sandstone in the stripes of a mesa's cliffs.
func _red_sandstone_side(t: Vector2i) -> void:
	var bands: Array[Color] = [RED_ROCK, RED_SAND, Color("e0a15a"), RED_ROCK.darkened(0.15)]
	for y in TILE:
		var c := bands[(y / 4) % bands.size()]
		for x in TILE:
			_px(t, x, y, _vary(c, 0.03))


func _cactus_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var rib := x % 4 == 1
			_px(t, x, y, _vary(CACTUS_DARK if rib else CACTUS, 0.03))
	for i in 7:                            # little white spines (they only push)
		_px(t, rng.randi_range(0, 3) * 4 + 3, rng.randi_range(1, 14), Color("f6f1d8"))


func _cactus_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(CACTUS.lightened(0.1) if d < 5.0 else CACTUS, 0.03))
	for p: Vector2i in [Vector2i(7, 7), Vector2i(8, 8), Vector2i(7, 8), Vector2i(8, 7)]:
		_px(t, p.x, p.y, Color("ff7aa8"))  # a pink flower


func _cactus_bottom(t: Vector2i) -> void:
	_noise_tile(t, CACTUS_DARK, 0.03)


## A dry tumbleweed-like bush: brown twigs on see-through.
func _dead_bush(t: Vector2i) -> void:
	var twig := Color("8a5a2e")
	for stem in 5:
		var x := 4 + stem * 2
		var y := 15
		var dx := rng.randi_range(-1, 1)
		for k in rng.randi_range(8, 13):
			_px(t, clampi(x, 0, 15), clampi(y, 0, 15), _vary(twig, 0.06))
			y -= 1
			if k % 3 == 2:
				x += dx
	for i in 10:
		_px(t, rng.randi_range(2, 13), rng.randi_range(3, 10), _vary(Color("a8743e"), 0.05))


## Sandy, slightly yellow glass with a warm frame.
func _desert_glass(t: Vector2i) -> void:
	var frame := Color("f0d9a0")
	for i in TILE:
		_px(t, i, 0, frame)
		_px(t, i, TILE - 1, frame)
		_px(t, 0, i, frame)
		_px(t, TILE - 1, i, frame)
	for y in range(1, 15):
		for x in range(1, 15):
			if rng.randf() < 0.06:
				_px(t, x, y, Color(1.0, 0.9, 0.6, 0.7))
	for i in 4:
		_px(t, 3 + i, 6 - i, Color(1, 1, 1, 0.9))
		_px(t, 9 + i, 12 - i, Color(1, 1, 1, 0.9))


## A palm trunk: rings of bark.
func _palm_side(t: Vector2i) -> void:
	for y in TILE:
		var ring := y % 4 == 0
		for x in TILE:
			var edge := x == 0 or x == 15
			_px(t, x, y, _vary(Color("7a5a36") if ring or edge else Color("a47c4a"), 0.03))


func _palm_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(Color("7a5a36") if d > 6.5 else (Color("c89a60") if int(d) % 3 == 0 else Color("d8ae72")), 0.03))


## Long palm fronds: stripes of green leaves with gaps.
func _palm_leaves(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frond := (x + y) % 5 < 3
			if not frond and rng.randf() < 0.75:
				continue
			_px(t, x, y, _vary(Color("5fb33a") if (x + y) % 5 != 1 else Color("3f8a2a"), 0.05))


## The pyramid's golden tip: shiny gold with a bright edge.
func _pyramid_gold(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == 15 or y == 15
			var shine := (x + y) % 7 == 0
			_px(t, x, y, _vary(GOLD.lightened(0.25) if shine else (GOLD.darkened(0.15) if edge else GOLD), 0.03))


## A clay lamp: a warm glowing window in a sandstone frame.
func _lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frame := x < 2 or x > 13 or y < 2 or y > 13
			var glow := Color("ffd27a").lerp(Color("ff9a3a"), clampf(Vector2(x - 7.5, y - 7.5).length() / 7.0, 0, 1))
			_px(t, x, y, _vary(SANDSTONE_DARK, 0.03) if frame else glow)


func _lamp_top(t: Vector2i) -> void:
	_noise_tile(t, SANDSTONE_DARK, 0.03)
	for y in range(5, 11):
		for x in range(5, 11):
			_px(t, x, y, Color("ffd27a"))


## A cut sandstone face with a dark slit in the middle (the trap's darts fly out of it).
func _arrow_slit(t: Vector2i) -> void:
	_cut_sandstone(t)
	for y in range(3, 13):
		_px(t, 7, y, Color("2a1d10"))
		_px(t, 8, y, Color("3a2a18"))


## Page 0's sand, with faint ripples a sharp-eyed child can spot.
func _trap_sand(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ripple := (x + y * 2) % 7 == 0
			_px(t, x, y, _vary(SAND.darkened(0.05) if ripple else SAND, 0.05))


## Sandstone with a faint crack (a hidden door; the fake wall of the desert).
func _fake_sandstone(t: Vector2i) -> void:
	_sandstone_side(t)
	var crack := SANDSTONE_DARK.darkened(0.1)
	var x := 6
	for y in range(4, 15):
		_px(t, x, y, crack)
		if y % 3 == 0:
			x += 1 if y % 2 == 0 else -1
