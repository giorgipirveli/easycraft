extends SceneTree
## Generates data/blocks/pages/meadows.png: block atlas page 13 (the wild meadows, owner feedback #45b), an 8 x 8
## grid of 16 x 16 pixel-art tiles in the style of tools/make_atlas.gd (original work).
## Run: godot --headless --path . --script res://tools/make_meadows_page.gd
## Tile coordinates must match world/universes/meadows_blocks.gd TILES. Append new tiles at the end of _init
## (with their own RNG), so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/meadows.png"

const BIRCH := Color("eeeae0")
const BIRCH_SHADE := Color("d4cfc2")
const BIRCH_MARK := Color("2b2622")
const BIRCH_WOOD := Color("e3cf9a")
const BIRCH_RING := Color("c9b27a")
const BIRCH_LEAF := Color("8fc94a")
const BIRCH_LEAF_DARK := Color("6fae34")
const DARK_BARK := Color("4a3222")
const DARK_BARK_DEEP := Color("33221a")
const DARK_WOOD := Color("7a5536")
const DARK_RING := Color("5c3d26")
const DARK_LEAF := Color("2f6b2a")
const DARK_LEAF_DEEP := Color("21521e")
const STEM := Color("3f8f2f")
const PAD := Color("4fa83a")
const PAD_DARK := Color("3a8a2a")
const MUD := Color("5b4a3a")
const MUD_WET := Color("463829")
const STONE := Color("8c8c8c")
const STONE_LIGHT := Color("a3a3a3")
const MORTAR := Color("5f5f5f")
const MOSS := Color("5d8f2f")
const MOSS_DARK := Color("47741f")
const PLASTER := Color("f2eee4")
const PLASTER_SHADE := Color("e0dbcd")
const ROOF := Color("c4492f")
const ROOF_DARK := Color("953521")
const ROOF_LIGHT := Color("dd6a4a")
const HAY := Color("e3c05a")
const HAY_DARK := Color("c49a38")
const HAY_BAND := Color("9c6b2f")
const WHEAT := Color("e8c35a")
const WHEAT_DARK := Color("c79a36")
const SAIL := Color("f4efe2")
const SAIL_SHADE := Color("ddd6c4")
const GLOW := Color("45e0ff")
const GLOW_LIGHT := Color("c9fbff")
const GLOW_DEEP := Color("1f9fd6")
const PATH := Color("b89a67")
const PATH_LIGHT := Color("cdb384")
const DIRT := Color("8a5a36")
const DIRT_DARK := Color("6e4527")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260925 + 45
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_birch_side(Vector2i(0, 0))
	_rings(Vector2i(1, 0), BIRCH_WOOD, BIRCH_RING, BIRCH)
	_leaves(Vector2i(2, 0), BIRCH_LEAF, BIRCH_LEAF_DARK, 0.2)
	_dark_side(Vector2i(3, 0))
	_rings(Vector2i(4, 0), DARK_WOOD, DARK_RING, DARK_BARK)
	_leaves(Vector2i(5, 0), DARK_LEAF, DARK_LEAF_DEEP, 0.12)
	_flowers(Vector2i(6, 0))
	_lily_pad(Vector2i(7, 0))
	_mud(Vector2i(0, 1))
	_bricks(Vector2i(1, 1), false)
	_bricks(Vector2i(2, 1), true)
	_plaster(Vector2i(3, 1))
	_roof(Vector2i(4, 1))
	_hay_side(Vector2i(5, 1))
	_hay_top(Vector2i(6, 1))
	_wheat(Vector2i(7, 1))
	_sail(Vector2i(0, 2))
	_glow_cap(Vector2i(1, 2))
	_path_top(Vector2i(2, 2))
	_path_side(Vector2i(3, 2))
	_dirt(Vector2i(4, 2))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("MEADOWS_PAGE saved err=", err)
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= TILE or y >= TILE:
		return
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _noise_tile(t: Vector2i, base: Color, amount: float) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(base, amount))


## White bark with black marks across it (the birch's look).
func _birch_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(BIRCH_SHADE if x % 5 == 0 else BIRCH, 0.025))
	for i in 10:
		var y := rng.randi_range(0, 15)
		var x0 := rng.randi_range(0, 11)
		var w := rng.randi_range(2, 5)
		for x in range(x0, x0 + w):
			_px(t, x, y, _vary(BIRCH_MARK, 0.04))
		if rng.randf() < 0.5:
			_px(t, x0 + 1, y + 1, _vary(BIRCH_MARK, 0.04))


## A log's end: rings round the middle, the bark round the edge.
func _rings(t: Vector2i, wood: Color, ring: Color, bark: Color) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := wood
			if d > 6.8:
				c = bark
			elif int(d) % 3 == 1:
				c = ring
			_px(t, x, y, _vary(c, 0.025))


## Leaves with holes (the cut-out material shows the sky through them).
func _leaves(t: Vector2i, light: Color, dark: Color, holes: float) -> void:
	for y in TILE:
		for x in TILE:
			if rng.randf() < holes:
				continue
			_px(t, x, y, _vary(light if rng.randf() > 0.3 else dark, 0.05))


## Dark oak bark: deep brown with vertical grooves.
func _dark_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var groove := (x + (y / 5)) % 4 == 0
			_px(t, x, y, _vary(DARK_BARK_DEEP if groove else DARK_BARK, 0.03))


## A tuft of flowers on stems, on nothing (two crossed pictures in the world).
func _flowers(t: Vector2i) -> void:
	var blooms: Array[Color] = [Color("ff4f6d"), Color("ffd23f"), Color("5cc8ff"), Color("ffffff"), Color("c77dff")]
	var stems := [[2, 7], [5, 4], [8, 8], [11, 5], [13, 9]]
	for i in stems.size():
		var sx: int = stems[i][0]
		var top: int = stems[i][1]
		for y in range(top, 16):
			_px(t, sx, y, _vary(STEM, 0.04))
		if i % 2 == 0:
			_px(t, sx + 1, top + 4, _vary(STEM.lightened(0.15), 0.03))   # a leaf
		var c := blooms[i % blooms.size()]
		for d: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			_px(t, sx + d.x, top - 1 + d.y, _vary(c, 0.03))
		_px(t, sx, top - 1, Color("ffe066") if c != Color("ffd23f") else Color("e07a1f"))
	for x in range(0, 16, 3):   # grass at the foot
		_px(t, x, 15, _vary(STEM, 0.05))
		_px(t, x + 1, 14, _vary(STEM, 0.05))


## A round lily pad with a notch and a little pink flower, on nothing.
func _lily_pad(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5)
			if d.length() > 7.2:
				continue
			if d.x > 0.5 and absf(d.y) < d.x * 0.35:
				continue   # the notch
			var vein := absi(x - 7) == 0 or absi(y - 7) == 0 or absi(x - y) == 0
			_px(t, x, y, _vary(PAD_DARK if vein else PAD, 0.03))
	for p: Vector2i in [Vector2i(4, 5), Vector2i(5, 4), Vector2i(4, 4), Vector2i(3, 4), Vector2i(4, 3)]:
		_px(t, p.x, p.y, Color("ff9ecb"))
	_px(t, 4, 4, Color("ffe066"))


## Wet brown mud with darker puddles.
func _mud(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var wet := sin(x * 0.7 + y * 0.3) + cos(y * 0.9 - x * 0.2) > 1.1
			_px(t, x, y, _vary(MUD_WET if wet else MUD, 0.03))


## Grey stone bricks in a running bond; mossy ones have green patches.
func _bricks(t: Vector2i, mossy: bool) -> void:
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var off := 4 if row % 2 == 1 else 0
			var mortar := y % 4 == 3 or (x + off) % 8 == 7
			var c := MORTAR if mortar else (STONE_LIGHT if y % 4 == 0 else STONE)
			_px(t, x, y, _vary(c, 0.03))
	if mossy:
		for i in 9:
			var cx := rng.randi_range(0, 15)
			var cy := rng.randi_range(0, 15)
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if dx * dx + dy * dy <= rng.randi_range(2, 5):
						_px(t, cx + dx, cy + dy, _vary(MOSS if rng.randf() > 0.3 else MOSS_DARK, 0.04))


## White plaster with a soft trowel texture.
func _plaster(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var swirl := sin(x * 0.6 + sin(y * 0.5) * 2.0) > 0.85
			_px(t, x, y, _vary(PLASTER_SHADE if swirl else PLASTER, 0.012))


## Red clay roof tiles in overlapping rows, each with a light top and a dark bottom edge.
func _roof(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var off := 2 if row % 2 == 1 else 0
			var edge := (x + off) % 4 == 3
			var c := ROOF_DARK if y % 4 == 3 or edge else (ROOF_LIGHT if y % 4 == 0 else ROOF)
			_px(t, x, y, _vary(c, 0.03))


## A hay bale's side: golden stalks and a string round it.
func _hay_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := HAY_DARK if (x * 3 + y) % 7 == 0 else HAY
			if y == 4 or y == 11:
				c = HAY_BAND
			_px(t, x, y, _vary(c, 0.04))


## Its top: stalks every way.
func _hay_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := HAY_DARK if (x + y * 2) % 5 == 0 or (x * 2 - y) % 7 == 0 else HAY
			_px(t, x, y, _vary(c, 0.04))


## Wheat stalks with golden ears, on nothing.
func _wheat(t: Vector2i) -> void:
	for sx in [1, 4, 7, 10, 13]:
		var top := rng.randi_range(1, 4)
		for y in range(top, 16):
			_px(t, sx, y, _vary(WHEAT_DARK if y > 9 else WHEAT, 0.04))
		for y in range(top, top + 5):
			_px(t, sx - 1 if y % 2 == 0 else sx + 1, y, _vary(WHEAT, 0.04))
		_px(t, sx, top - 1, _vary(WHEAT.lightened(0.1), 0.03))


## Sail cloth: off-white canvas with a weave and a seam.
func _sail(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var weave := (x + y) % 2 == 0
			var seam := y == 7 or y == 8
			_px(t, x, y, _vary(SAIL_SHADE if seam else (SAIL if weave else SAIL.darkened(0.03)), 0.01))


## A giant mushroom's glowing cap: bright blue with light spots.
func _glow_cap(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := GLOW if (x * 7 + y * 3) % 11 != 0 else GLOW_DEEP
			_px(t, x, y, _vary(c, 0.03))
	for s: Vector2i in [Vector2i(3, 3), Vector2i(10, 4), Vector2i(6, 10), Vector2i(12, 12), Vector2i(2, 12)]:
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_px(t, s.x + d.x, s.y + d.y, GLOW_LIGHT)


## A trodden dirt path: light and packed, with pebbles.
func _path_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(PATH_LIGHT if (x * 5 + y * 3) % 13 == 0 else PATH, 0.03))
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color("9b9488"))


## Its side: dirt with the path's light top.
func _path_side(t: Vector2i) -> void:
	_dirt(t)
	for x in TILE:
		for y in 3:
			_px(t, x, y, _vary(PATH if y < 2 else PATH.darkened(0.12), 0.03))


func _dirt(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(DIRT_DARK if rng.randf() < 0.15 else DIRT, 0.03))
