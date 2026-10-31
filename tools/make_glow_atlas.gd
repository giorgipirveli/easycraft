extends SceneTree
## Generates data/blocks/pages/glow.png: block atlas page 45 (universe 6, the Glow Caves), an 8 x 8 grid of 16 x 16
## pixel-art tiles in the style of tools/make_atlas.gd (original work; three rows used). Calm, never scary (spec §3c):
## lilac-grey limestone, soft teal glow moss, pastel glowshroom caps (teal and rose), a glow-worm ceiling's tiny blue
## lights on silk threads, milky selenite, cream-and-orange flowstone, dripstone cones, pebbled lake stone.
## Glowing tiles are drawn for an unshaded material (they shine as drawn): dark grounds with bright points, never a flat
## neon slab; the moss's stone side is drawn pre-shaded so it sits beside the lit cave stone.
## Run: godot --headless --path . --script res://tools/make_glow_atlas.gd
## Tile coordinates must match world/universes/glow_blocks.gd TILES. Append new tiles at the end of _init (with their
## own RNG), so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/glow.png"

const STONE := Color("8d92ab")           # limestone: cool lilac grey
const STONE_DARK := Color("6d7290")
const STONE_LIGHT := Color("aab0c8")
const CALCITE := Color("dcdfeb")
const MOSS := Color("1f6e64")            # glow moss: deep teal under bright glowing tufts
const MOSS_DARK := Color("174f4c")
const MOSS_GLOW := Color("7dffd6")
const MOSS_BRIGHT := Color("d4fff1")
const STEM := Color("ece6f2")            # glowshroom stems: pale cream with a lilac blush
const STEM_DARK := Color("cbc0d9")
const STEM_LIGHT := Color("fbf8ff")
const BLUE := Color("39b9d9")            # the blue glowshroom's cap
const BLUE_DARK := Color("1f82a8")
const BLUE_SPOT := Color("d2fbff")
const BLUE_GILL := Color("8fe3f0")
const ROSE := Color("f283b8")            # the rose glowshroom's cap
const ROSE_DARK := Color("c3558f")
const ROSE_SPOT := Color("ffe6f3")
const ROSE_GILL := Color("ffb8da")
const CEILING := Color("1c2038")         # the glow-worms' dark rock
const CEILING_DARK := Color("141729")
const WORM := Color("74dcff")            # a glow-worm's blue-green light
const WORM_BRIGHT := Color("d6f6ff")
const THREAD := Color("3d4f7f")          # their silk threads
const SELENITE := Color("d9e7f4")        # selenite: milky, pale blue
const SELENITE_DARK := Color("aec3dc")
const SELENITE_LIGHT := Color("ffffff")
const FLOW := Color("e7cd9f")            # flowstone: cream and orange bands
const FLOW_ORANGE := Color("d79c63")
const FLOW_LIGHT := Color("f6e8c8")
const DRIP := Color("e3d3b3")            # dripstone cones
const DRIP_DARK := Color("b9a27e")
const DRIP_LIGHT := Color("f6ecd6")
const DROP := Color("a8e8ff")
const PEBBLE := Color("55607b")          # lake stone
const PEBBLE_LIGHT := Color("7f8ca8")
const PEBBLE_GAP := Color("2f364a")
const PLANK := Color("9d7c9c")           # fungus planks: mauve mushroom wood
const PLANK_DARK := Color("715673")
const PLANK_LIGHT := Color("c0a2be")
const LAMP_FRAME := Color("5c4560")
const LAMP_GLOW := Color("ffe7a3")
const LAMP_CORE := Color("fff8dc")
const SPORE := Color("b6fff0")
const PEARL := Color("f6f1e8")
const PEARL_SHEEN := Color("ffd9e6")
const POOL := Color("3c7ea6")
const POOL_LIGHT := Color("7fc3e3")
const GOLD := Color("f5c542")
const GOLD_LIGHT := Color("fff0a6")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20261017
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_cave_stone(Vector2i(0, 0))
	_moss_top(Vector2i(1, 0))
	_moss_side(Vector2i(2, 0))
	_stem_side(Vector2i(3, 0))
	_stem_top(Vector2i(4, 0))
	_cap_top(Vector2i(5, 0), BLUE, BLUE_DARK, BLUE_SPOT)
	_cap_side(Vector2i(6, 0), BLUE, BLUE_DARK, BLUE_SPOT)
	_cap_gills(Vector2i(7, 0), BLUE_DARK, BLUE_GILL)
	_cap_top(Vector2i(0, 1), ROSE, ROSE_DARK, ROSE_SPOT)
	_cap_side(Vector2i(1, 1), ROSE, ROSE_DARK, ROSE_SPOT)
	_cap_gills(Vector2i(2, 1), ROSE_DARK, ROSE_GILL)
	_worms_bottom(Vector2i(3, 1))
	_worms_side(Vector2i(4, 1))
	_selenite(Vector2i(5, 1))
	_flowstone(Vector2i(6, 1))
	_stalactite(Vector2i(7, 1))
	_stalagmite(Vector2i(0, 2))
	_lake_stone(Vector2i(1, 2))
	_planks(Vector2i(2, 2))
	_lamp_side(Vector2i(3, 2))
	_lamp_top(Vector2i(4, 2))
	_pearls(Vector2i(5, 2))
	_cave_gold(Vector2i(6, 2))
	_fake_stone(Vector2i(7, 2))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("GLOW_ATLAS saved err=", err)
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE and y < TILE:
		img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _pixel(tile: Vector2i, x: int, y: int) -> Color:
	return img.get_pixel(tile.x * TILE + x, tile.y * TILE + y)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## Limestone: soft mottling, a few pale calcite flecks and a fine bedding line or two.
func _stone_ground(t: Vector2i, shade: float = 1.0) -> void:
	for y in TILE:
		for x in TILE:
			var m := sin(x * 0.9 + y * 0.35) * 0.5 + cos(y * 0.8 - x * 0.45) * 0.5
			var c := STONE_LIGHT if m > 0.62 else (STONE_DARK if m < -0.6 else STONE)
			if y == 5 or y == 11:
				c = c.lerp(STONE_DARK, 0.35)
			_px(t, x, y, _vary(c, 0.025) * Color(shade, shade, shade))
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), CALCITE * Color(shade, shade, shade))


func _cave_stone(t: Vector2i) -> void:
	_stone_ground(t)


## Glow moss from above: deep teal tufts, glowing tips in little clusters.
func _moss_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var clump := sin(x * 1.25 + y * 0.5) + cos(y * 1.15 - x * 0.7)
			_px(t, x, y, _vary(MOSS if clump > -0.8 else MOSS_DARK, 0.02))
	for i in 14:
		var x := rng.randi_range(1, 14)
		var y := rng.randi_range(1, 14)
		_px(t, x, y, MOSS_GLOW)
		if i % 3 == 0:
			_px(t, x, y, MOSS_BRIGHT)
			_px(t, x + 1, y, MOSS_GLOW.lerp(MOSS, 0.4))
			_px(t, x, y + 1, MOSS_GLOW.lerp(MOSS, 0.4))


## Its side: a glowing fringe of moss over limestone (drawn pre-shaded: the material is unshaded).
func _moss_side(t: Vector2i) -> void:
	_stone_ground(t, 0.42)
	for x in TILE:
		var hang := 2 + int(absf(sin(x * 1.7)) * 3.0) + rng.randi_range(0, 1)
		for y in hang:
			_px(t, x, y, _vary(MOSS if y < hang - 1 else MOSS_DARK, 0.02))
		if x % 3 == 1:
			_px(t, x, hang - 1, MOSS_GLOW)
	for x in [2, 7, 12]:
		_px(t, x, 0, MOSS_BRIGHT)


## A glowshroom's stalk: pale fibres running up, a soft blush in its grooves.
func _stem_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := STEM
			if x % 4 == 1:
				c = STEM_DARK
			elif x % 4 == 3:
				c = STEM_LIGHT
			_px(t, x, y, _vary(c, 0.02))
	for i in 4:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(2, 13)
		_px(t, x, y, STEM_DARK)
		_px(t, x, y + 1, STEM_DARK)


## The stalk cut across: growth rings round a pale heart.
func _stem_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := STEM_LIGHT if int(d) % 3 == 0 else STEM
			if d > 7.0:
				c = STEM_DARK
			_px(t, x, y, _vary(c, 0.02))


## A cap from above: round soft spots on a pastel dome, darker towards its rim.
func _cap_top(t: Vector2i, base: Color, dark: Color, spot: Color) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := base.lerp(dark, clampf((d - 5.0) / 6.0, 0.0, 0.7))
			_px(t, x, y, _vary(c, 0.02))
	for s: Vector2i in [Vector2i(3, 3), Vector2i(10, 2), Vector2i(7, 7), Vector2i(12, 9), Vector2i(4, 11), Vector2i(9, 13)]:
		_px(t, s.x, s.y, spot)
		_px(t, s.x + 1, s.y, spot)
		_px(t, s.x, s.y + 1, spot)
		_px(t, s.x + 1, s.y + 1, spot.lerp(base, 0.3))


## A cap's side: the dome's spotted skin over a rim, the gills' glow peeking under it.
func _cap_side(t: Vector2i, base: Color, dark: Color, spot: Color) -> void:
	for y in TILE:
		for x in TILE:
			var c := base if y < 11 else dark
			if y == 11:
				c = dark.lerp(base, 0.3)
			if y >= 14:
				c = spot.lerp(base, 0.55)
			_px(t, x, y, _vary(c, 0.02))
	for s: Vector2i in [Vector2i(2, 3), Vector2i(8, 2), Vector2i(12, 6), Vector2i(5, 7), Vector2i(10, 9)]:
		_px(t, s.x, s.y, spot)
		_px(t, s.x + 1, s.y, spot)
		_px(t, s.x, s.y + 1, spot.lerp(base, 0.3))


## Under a cap: glowing gills running out from the middle.
func _cap_gills(t: Vector2i, dark: Color, gill: Color) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5)
			var a := atan2(d.y, d.x)
			var line := absf(sin(a * 8.0)) > 0.75
			var c := gill if line else dark.lerp(gill, 0.3)
			if d.length() < 2.0:
				c = STEM
			_px(t, x, y, _vary(c, 0.02))


## The glow-worms' ceiling seen from below: dark rock, tiny blue-green lights, their silk threads hanging down.
func _worms_bottom(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(CEILING if (x * 7 + y * 3) % 11 != 0 else CEILING_DARK, 0.015))
	for i in 18:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		_px(t, x, y, WORM if i % 4 != 0 else WORM_BRIGHT)
		if i % 5 == 0:
			_px(t, x + 1, y, WORM.lerp(CEILING, 0.5))


## Its side: dark rock with silk threads and a few lights near the bottom edge.
func _worms_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(CEILING.lerp(STONE_DARK, 0.25 * (1.0 - y / 15.0)), 0.015))
	for x in [1, 4, 6, 9, 12, 14]:
		var length := rng.randi_range(4, 9)
		for y in range(TILE - length, TILE):
			_px(t, x, y, THREAD)
		_px(t, x, TILE - 1, WORM_BRIGHT if x % 3 == 0 else WORM)
	for i in 4:
		_px(t, rng.randi_range(0, 15), rng.randi_range(10, 14), WORM)


## Selenite: a milky crystal with long straight facets catching the light.
func _selenite(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var band := (x + y * 2) % 9
			var c := SELENITE
			if band == 0:
				c = SELENITE_LIGHT
			elif band == 4 or band == 5:
				c = SELENITE_DARK
			_px(t, x, y, _vary(c, 0.015))
	for i in 3:
		var x := rng.randi_range(2, 13)
		var y := rng.randi_range(2, 13)
		_px(t, x, y, SELENITE_LIGHT)
		_px(t, x - 1, y + 1, SELENITE_LIGHT.lerp(SELENITE, 0.4))


## Flowstone: wavy cream and orange bands laid down by flowing water.
func _flowstone(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var wave := y + sin(x * 0.7) * 1.4
			var band := int(floor(wave)) % 5
			var c := FLOW
			if band == 1:
				c = FLOW_ORANGE
			elif band == 3:
				c = FLOW_LIGHT
			_px(t, x, y, _vary(c, 0.02))


## A stalactite (two crossed pictures): a cone from the roof down to a point with a drop at its tip.
func _stalactite(t: Vector2i) -> void:
	for y in 14:
		var half := 5.5 * (1.0 - y / 14.0) + 0.6
		for x in TILE:
			var dx := x - 7.5
			if absf(dx) <= half:
				var c := DRIP
				if dx < -half * 0.35:
					c = DRIP_DARK
				elif dx > half * 0.4:
					c = DRIP_LIGHT
				if y % 4 == 2 and absf(dx) < half - 0.5:
					c = c.lerp(DRIP_DARK, 0.25)
				_px(t, x, y, _vary(c, 0.02))
	_px(t, 7, 14, DROP)
	_px(t, 8, 14, DROP)
	_px(t, 7, 15, DROP.lerp(Color.WHITE, 0.4))


## A stalagmite (crossed pictures): a rounded cone rising from the floor where the drops land.
func _stalagmite(t: Vector2i) -> void:
	for y in range(3, TILE):
		var k := (y - 3) / 12.0
		var half := 6.5 * sqrt(k) + 0.6
		for x in TILE:
			var dx := x - 7.5
			if absf(dx) <= half:
				var c := DRIP
				if dx < -half * 0.35:
					c = DRIP_DARK
				elif dx > half * 0.4:
					c = DRIP_LIGHT
				if y % 4 == 1 and absf(dx) < half - 0.5:
					c = c.lerp(FLOW_ORANGE, 0.2)
				_px(t, x, y, _vary(c, 0.02))
	_px(t, 7, 3, DRIP_LIGHT)
	_px(t, 8, 3, DRIP_LIGHT)


## The lakes' pebbles: rounded stones with a soft highlight, dark gaps between.
func _lake_stone(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(PEBBLE_GAP, 0.02))
	for p: Vector3i in [Vector3i(3, 3, 3), Vector3i(10, 2, 3), Vector3i(6, 8, 3), Vector3i(13, 9, 2), Vector3i(2, 12, 2),
			Vector3i(9, 13, 3), Vector3i(14, 14, 2), Vector3i(1, 7, 2), Vector3i(14, 4, 2)]:
		for y in range(p.y - p.z, p.y + p.z + 1):
			for x in range(p.x - p.z, p.x + p.z + 1):
				var d := Vector2(x - p.x, y - p.y).length()
				if d <= p.z + 0.4:
					var c := PEBBLE_LIGHT if (x - p.x < 0 and y - p.y < 0) else PEBBLE
					_px(t, posmod(x, TILE), posmod(y, TILE), _vary(c, 0.02))


## Fungus planks: mauve mushroom wood, three planks with their seams and a few soft pores.
func _planks(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := PLANK
			if y % 5 == 4:
				c = PLANK_DARK
			elif (x + y * 3) % 7 == 0:
				c = PLANK_LIGHT
			_px(t, x, y, _vary(c, 0.025))
	for i in 5:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), PLANK_DARK)


## The spore lamp's side: a mushroom-wood frame round a warm glowing heart, spores twinkling in it.
func _lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frame := x < 2 or x > 13 or y < 2 or y > 13
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := LAMP_FRAME if frame else LAMP_GLOW.lerp(LAMP_CORE, clampf(1.0 - d / 5.0, 0.0, 1.0))
			_px(t, x, y, _vary(c, 0.015))
	for p: Vector2i in [Vector2i(4, 4), Vector2i(10, 5), Vector2i(6, 10), Vector2i(11, 11), Vector2i(8, 7)]:
		_px(t, p.x, p.y, SPORE)
	for x in [5, 10]:
		for y in range(2, 14):
			_px(t, x, y, LAMP_FRAME.lerp(LAMP_GLOW, 0.25))


func _lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x < 2 or x > 13 or y < 2 or y > 13
			_px(t, x, y, _vary(LAMP_FRAME if edge else PLANK_DARK, 0.02))
	for y in range(5, 11):
		for x in range(5, 11):
			_px(t, x, y, LAMP_GLOW)
	_px(t, 7, 7, LAMP_CORE)
	_px(t, 8, 8, LAMP_CORE)


## Cave pearls: round pale stones, a pink sheen, in a shallow blue drip pool.
func _pearls(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(POOL if (x + y) % 6 != 0 else POOL_LIGHT, 0.02))
	for p: Vector3i in [Vector3i(4, 4, 2), Vector3i(11, 4, 2), Vector3i(7, 9, 3), Vector3i(3, 12, 1), Vector3i(12, 12, 2)]:
		for y in range(p.y - p.z, p.y + p.z + 1):
			for x in range(p.x - p.z, p.x + p.z + 1):
				if Vector2(x - p.x, y - p.y).length() <= p.z + 0.35:
					_px(t, x, y, PEARL_SHEEN if x - p.x > 0 and y - p.y > 0 else PEARL)
		_px(t, p.x - 1, p.y - 1, Color.WHITE)


## Cave gold: gold nuggets set in milky selenite.
func _cave_gold(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(SELENITE if (x + y * 2) % 7 != 0 else SELENITE_DARK, 0.02))
	for p: Vector2i in [Vector2i(3, 3), Vector2i(10, 4), Vector2i(6, 9), Vector2i(12, 12), Vector2i(3, 13)]:
		for dy in 2:
			for dx in 3:
				_px(t, p.x + dx, p.y + dy, GOLD)
		_px(t, p.x, p.y, GOLD_LIGHT)


## The hidden door: cave stone with a faint crack where a knock sounds hollow.
func _fake_stone(t: Vector2i) -> void:
	_stone_ground(t)
	var x := 7
	for y in range(2, 14):
		_px(t, x, y, STONE_DARK.darkened(0.15))
		if y % 3 == 0:
			x += 1 if y % 2 == 0 else -1
