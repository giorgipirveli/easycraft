extends SceneTree
## Generates data/blocks/pages/dragon.png: block atlas page 11 (the Dragon Realm, owner feedback #39), an 8 x 8 grid
## of 16 x 16 pixel-art tiles in the style of tools/make_atlas.gd (original work).
## Owner #43 (our own look, spec §3c): the realm is a sunrise over a sea of clouds, never black and purple: coral
## moss, pearl-white and apricot floatstone, golden crystal spires, a coral starglass frame (only colours changed:
## the RNG draws stay the same, so every other tile is byte-identical).
## Run: godot --headless --path . --script res://tools/make_dragon_atlas.gd
## Tile coordinates must match world/universes/dragon_blocks.gd TILES. Append new tiles at the end of
## _init (with their own RNG), so the tiles above stay byte-identical.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/dragon.png"

const MOSS := Color("f28b82")            # sky grass: sunrise coral moss (owner #43; was violet-blue)
const MOSS_DARK := Color("d66a6a")
const MOSS_LIGHT := Color("ffb3a1")
const SPARKLE := Color("eef8ff")
const FLOAT := Color("f3e2dc")           # floatstone: pearl-white rock with a blush (owner #43; was lavender)
const FLOAT_DARK := Color("dcc0b6")
const FLOAT_LIGHT := Color("fff4ef")
const DEEP := Color("e3a37f")            # deep floatstone: apricot (was dark violet)
const DEEP_DARK := Color("c47c5c")
const DEEP_LIGHT := Color("f2c1a3")
const AMETHYST := Color("ffc94d")        # crystal spires: golden sun crystals (was amethyst)
const AMETHYST_DARK := Color("e0982a")
const AMETHYST_LIGHT := Color("fff3c4")
const STEM := Color("eee4cf")            # mushroom stems
const STEM_DARK := Color("d2c3a3")
const CAP := Color("35cfc0")             # glowing mushroom caps
const CAP_DARK := Color("1f9c93")
const CAP_SPOT := Color("d4fff8")
const EMERALD := Color("1fa36a")         # dragon scales
const EMERALD_DARK := Color("0f6b44")
const EMERALD_LIGHT := Color("63dba0")
const EMBER := Color("e2552a")           # ember scales
const EMBER_DARK := Color("a1301a")
const EMBER_LIGHT := Color("ffa45c")
const STAR := Color("fff4c2")
const MOON := Color("dfeaff")
const MOON_DEEP := Color("9fb6ff")
const SILVER := Color("b9b4d6")
const CLOUD := Color("f7f5ff")
const CLOUD_SHADE := Color("dcd5f2")
const TWIG := Color("c39646")            # dragon nests
const TWIG_DARK := Color("8e6427")
const TWIG_LIGHT := Color("e6c375")
const GOLD := Color("f5c542")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260939
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_sky_grass_top(Vector2i(0, 0))
	_sky_grass_side(Vector2i(1, 0))
	_floatstone(Vector2i(2, 0))
	_deep_floatstone(Vector2i(3, 0))
	_spire_side(Vector2i(4, 0))
	_spire_top(Vector2i(5, 0))
	_stem_side(Vector2i(6, 0))
	_stem_top(Vector2i(7, 0))
	_cap_top(Vector2i(0, 1))
	_cap_side(Vector2i(1, 1))
	_cap_gills(Vector2i(2, 1))
	_scales(Vector2i(3, 1), EMERALD, EMERALD_DARK, EMERALD_LIGHT)
	_scales(Vector2i(4, 1), EMBER, EMBER_DARK, EMBER_LIGHT)
	_starglass(Vector2i(5, 1))
	_moon_lamp_side(Vector2i(6, 1))
	_moon_lamp_top(Vector2i(7, 1))
	_cloud(Vector2i(0, 2))
	_nest_top(Vector2i(1, 2))
	_nest_side(Vector2i(2, 2))
	_float_brick(Vector2i(3, 2))
	_dragon_gold(Vector2i(4, 2))
	_fake_floatstone(Vector2i(5, 2))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("DRAGON_ATLAS saved err=", err)
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _pixel(tile: Vector2i, x: int, y: int) -> Color:
	return img.get_pixel(tile.x * TILE + x, tile.y * TILE + y)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _noise_tile(t: Vector2i, base: Color, amount: float) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(base, amount))


## Sunrise coral moss, soft clumps, and a few twinkling sparkles.
func _sky_grass_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var clump := sin(x * 1.3 + y * 0.4) + cos(y * 1.1 - x * 0.6)
			var c := MOSS_LIGHT if clump > 1.2 else (MOSS_DARK if clump < -1.3 else MOSS)
			_px(t, x, y, _vary(c, 0.03))
	for i in 5:
		var x := rng.randi_range(1, 14)
		var y := rng.randi_range(1, 14)
		_px(t, x, y, SPARKLE)
		if i % 2 == 0:
			_px(t, x + 1, y, SPARKLE.lerp(MOSS_LIGHT, 0.5))
			_px(t, x - 1, y, SPARKLE.lerp(MOSS_LIGHT, 0.5))


## Floatstone with a moss band over its top edge that hangs down in tufts.
func _sky_grass_side(t: Vector2i) -> void:
	_floatstone(t)
	for x in TILE:
		var hang := 3 + (2 if x % 5 == 1 else 0) + (1 if x % 3 == 0 else 0) + rng.randi_range(0, 1)
		for y in hang:
			_px(t, x, y, _vary(MOSS_LIGHT if y == 0 else (MOSS_DARK if y == hang - 1 else MOSS), 0.03))
	_px(t, 4, 1, SPARKLE)
	_px(t, 11, 0, SPARKLE)


## Pearl-white rock with a blush, soft cracks and light speckles.
func _floatstone(t: Vector2i) -> void:
	_noise_tile(t, FLOAT, 0.035)
	for i in 10:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), FLOAT_LIGHT)
	for i in 3:
		var x := rng.randi_range(1, 13)
		var y := rng.randi_range(2, 13)
		for k in rng.randi_range(2, 4):
			_px(t, clampi(x + k, 0, 15), clampi(y + (k % 2), 0, 15), FLOAT_DARK)


## Apricot rock with deep streaks (the tapering undersides of the islands).
func _deep_floatstone(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var streak := sin(y * 0.9 + sin(x * 0.5) * 1.5)
			_px(t, x, y, _vary(DEEP_DARK if streak > 0.8 else DEEP, 0.035))
	for i in 8:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), DEEP_LIGHT)


## A glowing golden crystal pillar: tall facets, bright edges, a light core.
func _spire_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := x % 5
			var c := AMETHYST
			if facet == 0:
				c = AMETHYST_LIGHT
			elif facet == 4:
				c = AMETHYST_DARK
			elif (x + y * 2) % 11 == 0:
				c = AMETHYST_LIGHT.lerp(AMETHYST, 0.4)
			_px(t, x, y, _vary(c, 0.02))


## The spire's end: a faceted gem, a star of light in its middle.
func _spire_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5)
			var ring := int(maxf(absf(d.x), absf(d.y)))
			var c := AMETHYST_DARK if ring >= 7 else (AMETHYST if ring % 3 != 0 else AMETHYST_LIGHT.lerp(AMETHYST, 0.5))
			_px(t, x, y, _vary(c, 0.02))
	for i in range(5, 11):
		_px(t, i, 7, AMETHYST_LIGHT)
		_px(t, 7, i, AMETHYST_LIGHT)


## A mushroom's pale stalk with long fibres.
func _stem_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var fibre := (x * 7 + int(y * 0.3)) % 5 == 0
			_px(t, x, y, _vary(STEM_DARK if fibre else STEM, 0.025))


## The cut stalk: soft rings.
func _stem_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var r := Vector2(x - 7.5, y - 7.5).length()
			var c := STEM_DARK if int(r) % 3 == 0 else STEM
			if r > 7.3:
				c = STEM_DARK.darkened(0.1)
			_px(t, x, y, _vary(c, 0.02))


## A glowing turquoise cap with pale spots.
func _cap_top(t: Vector2i) -> void:
	_noise_tile(t, CAP, 0.03)
	var spots: Array[Vector3] = [Vector3(4, 4, 2.2), Vector3(11, 5, 1.8), Vector3(7, 11, 2.4), Vector3(13, 12, 1.5),
		Vector3(2, 12, 1.3)]
	for y in TILE:
		for x in TILE:
			for s: Vector3 in spots:
				if Vector2(x - s.x, y - s.y).length() <= s.z:
					_px(t, x, y, _vary(CAP_SPOT, 0.02))


## The cap's rim: spots over the top, a darker lip at the bottom.
func _cap_side(t: Vector2i) -> void:
	_noise_tile(t, CAP, 0.03)
	for y in range(12, 16):
		for x in TILE:
			_px(t, x, y, _vary(CAP_DARK, 0.02))
	for s: Vector2i in [Vector2i(3, 4), Vector2i(4, 4), Vector2i(3, 5), Vector2i(10, 2), Vector2i(11, 2), Vector2i(10, 3),
			Vector2i(13, 7), Vector2i(7, 8), Vector2i(8, 8)]:
		_px(t, s.x, s.y, CAP_SPOT)


## Under the cap: gills running out from the middle.
func _cap_gills(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var a := atan2(y - 7.5, x - 7.5)
			var gill := posmod(int(floor(a / TAU * 24.0)), 2) == 0
			_px(t, x, y, _vary(CAP_DARK if gill else CAP_DARK.lerp(CAP, 0.5), 0.02))
	for y in range(6, 10):
		for x in range(6, 10):
			_px(t, x, y, STEM)


## Overlapping round scales in rows (each row half a scale over from the last), a dark arc under each and a
## light shine on its top.
func _scales(t: Vector2i, base: Color, dark: Color, light: Color) -> void:
	var depth: Array[int] = [1, 2, 3, 3, 3, 3, 2, 1]   # where each column's arc runs, row by row
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var sx := posmod(x + (4 if row % 2 == 1 else 0), 8)
			var ly := y % 4
			var c := base
			if ly == depth[sx]:
				c = dark
			elif ly > depth[sx]:
				c = dark.lerp(base, 0.45)
			elif ly == 0 and sx >= 2 and sx <= 5:
				c = light
			_px(t, x, y, _vary(c, 0.02))


## Clear glass in a coral frame, with tiny stars inside.
func _starglass(t: Vector2i) -> void:
	var frame := Color("e89a7e")   # owner #43: a coral frame (was violet)
	for i in TILE:
		_px(t, i, 0, frame)
		_px(t, i, TILE - 1, frame)
		_px(t, 0, i, frame)
		_px(t, TILE - 1, i, frame)
	for p: Vector2i in [Vector2i(4, 4), Vector2i(11, 6), Vector2i(6, 11), Vector2i(12, 12), Vector2i(3, 9)]:
		_px(t, p.x, p.y, STAR)
		if p.x % 2 == 0:
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_px(t, p.x + d.x, p.y + d.y, Color(STAR.r, STAR.g, STAR.b, 0.75))
	for i in 4:
		_px(t, 2 + i, 6 - i, Color(1, 1, 1, 0.7))


## A silver frame round a pale moonlight with a crescent moon.
func _moon_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frame := x < 2 or x > 13 or y < 2 or y > 13
			var glow := MOON.lerp(MOON_DEEP, clampf(Vector2(x - 7.5, y - 7.5).length() / 7.0, 0, 1))
			_px(t, x, y, _vary(SILVER, 0.02) if frame else glow)
	for y in TILE:
		for x in TILE:
			var outer := Vector2(x - 7.5, y - 7.5).length() <= 3.6
			var inner := Vector2(x - 9.0, y - 6.5).length() <= 3.0
			if outer and not inner:
				_px(t, x, y, Color("fffbe6"))


func _moon_lamp_top(t: Vector2i) -> void:
	_noise_tile(t, SILVER, 0.02)
	for y in range(4, 12):
		for x in range(4, 12):
			_px(t, x, y, MOON.lerp(MOON_DEEP, clampf(Vector2(x - 7.5, y - 7.5).length() / 5.0, 0, 1)))


## Soft white puffs with a few gaps at the edges (a cloud you walk through).
func _cloud(t: Vector2i) -> void:
	var puffs: Array[Vector3] = [Vector3(4, 5, 5.0), Vector3(11, 4, 5.0), Vector3(8, 9, 6.0), Vector3(3, 12, 4.4),
		Vector3(12, 12, 4.4), Vector3(8, 2, 3.5)]
	for y in TILE:
		for x in TILE:
			for p: Vector3 in puffs:
				var d := Vector2(x - p.x, y - p.y).length()
				if d <= p.z:
					var c := CLOUD if d < p.z * 0.7 else CLOUD_SHADE
					_px(t, x, y, _vary(c, 0.015))
					break


## A woven bowl of golden twigs seen from above, a few scales tucked in.
func _nest_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5)
			var a := atan2(d.y, d.x)
			var weave := posmod(int(floor(a / TAU * 16.0 + d.length() * 0.8)), 3)
			var c := TWIG if weave == 0 else (TWIG_LIGHT if weave == 1 else TWIG_DARK)
			if d.length() < 3.5:
				c = TWIG_DARK.darkened(0.2)   # the soft hollow an egg lies in
			_px(t, x, y, _vary(c, 0.025))
	for p: Vector2i in [Vector2i(2, 3), Vector2i(12, 11), Vector2i(3, 12)]:
		_px(t, p.x, p.y, EMERALD_LIGHT)
		_px(t, p.x + 1, p.y, EMERALD)


## Twigs woven round and round (the nest's side).
func _nest_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var band := (y + (x / 4) % 2) % 3
			var c := TWIG if band == 0 else (TWIG_LIGHT if band == 1 else TWIG_DARK)
			if (x + y * 3) % 13 == 0:
				c = TWIG_DARK.darkened(0.15)
			_px(t, x, y, _vary(c, 0.025))


## Blush-white bricks with pale mortar (the realm's sky shrines).
func _float_brick(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var mortar := y % 4 == 3 or (x + (4 if row % 2 == 1 else 0)) % 8 == 7
			_px(t, x, y, _vary(FLOAT_LIGHT.lightened(0.1) if mortar else FLOAT_DARK, 0.025))


## Shining gold with a scale pattern pressed in (the realm's treasure).
func _dragon_gold(t: Vector2i) -> void:
	_scales(t, GOLD, GOLD.darkened(0.25), GOLD.lightened(0.35))
	for i in 3:
		_px(t, rng.randi_range(2, 13), rng.randi_range(2, 13), Color(1, 1, 0.9))


## Floatstone with a faint crack down it (a hidden door: the realm's fake wall).
func _fake_floatstone(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _pixel(Vector2i(2, 0), x, y))
	var crack := FLOAT_DARK.darkened(0.2)
	var x := 8
	for y in range(2, 15):
		_px(t, x, y, crack)
		if y % 3 == 0:
			x += 1 if y % 2 == 0 else -1
