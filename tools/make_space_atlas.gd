extends SceneTree
## Generates the pixel block pages of space (owner feedback #55, spec §21.2): 8 x 8 grids of 16 x 16 pixel-art tiles in
## the style of tools/make_atlas.gd (original work), each page with its own RNG seed (a page never changes another):
##   data/blocks/pages/moon.png     page 15, the Moon (world/universes/moon_blocks.gd TILES)
##   data/blocks/pages/boing.png    page 16, Planet Boing (world/universes/boing_blocks.gd TILES)
##   data/blocks/pages/rainbow.png  page 17, Rainbow Planet (world/universes/rainbow_blocks.gd TILES)
##   data/blocks/pages/mars.png     page 18, Mars (world/universes/mars_blocks.gd TILES; cosmos, spec §21b.2)
##   data/blocks/pages/europa.png   page 20, Europa (world/universes/europa_blocks.gd TILES; cosmos, spec §21b.2)
##   data/blocks/pages/io.png       page 21, Io (world/universes/io_blocks.gd TILES; cosmos, spec §21b.2)
##   data/blocks/pages/titan.png    page 29, Titan (world/universes/titan_blocks.gd TILES; cosmos, spec §21b.2)
##   data/blocks/pages/mercury.png  page 30, Mercury (world/universes/mercury_blocks.gd TILES; cosmos, spec §21b.2)
##   data/blocks/pages/venus.png    page 38, Venus's cloud city (world/universes/venus_blocks.gd TILES; cosmos, §21b.2)
##   data/blocks/pages/rings.png    page 40, Saturn's rings (world/universes/rings_blocks.gd TILES; cosmos, §21b.2)
##   data/blocks/pages/pluto.png    page 41, Pluto (world/universes/pluto_blocks.gd TILES; cosmos, spec §21b.2)
##   data/blocks/pages/triton.png   page 42, Triton (world/universes/triton_blocks.gd TILES; cosmos, spec §21b.2)
##   data/blocks/pages/ganymede.png page 43, Ganymede (world/universes/ganymede_blocks.gd TILES; cosmos, spec §21b.2)
## Our own look (spec §3c): bright and friendly — silvery dust with sparkles, pale blue crystals, the brand's teal on the
## landing pad with a golden star.
## Run: godot --headless --path . --script res://tools/make_space_atlas.gd   (then godot --headless --path . --import)
## Only some pages: ... --script res://tools/make_space_atlas.gd -- mars   (page names without .png; none: every page)
## Append new tiles at the end of a page's function (the RNG stays in step for the tiles above).

const TILE := 16
const GRID := 8
const DIR := "res://data/blocks/pages/"

# The Moon
const DUST := Color("cdd1dc")
const DUST_DARK := Color("aeb3c2")
const DUST_LIGHT := Color("e9ecf3")
const SPARKLE := Color("ffffff")
const ROCK := Color("9ea4b5")
const ROCK_DARK := Color("7d8396")
const ROCK_LIGHT := Color("b9bfcd")
const DEEP := Color("737a91")
const DEEP_DARK := Color("5a6076")
const CRYSTAL := Color("8fdcff")
const CRYSTAL_DARK := Color("58b4e8")
const CRYSTAL_LIGHT := Color("e2f7ff")
const CHEESE := Color("ffd45e")
const CHEESE_DARK := Color("e7b33a")
const CHEESE_HOLE := Color("d49a2a")
const PANEL := Color("e7ecf4")
const PANEL_DARK := Color("c3cbd8")
const RIVET := Color("9aa5b7")
const WINDOW := Color("ffe39a")
const WINDOW_LIGHT := Color("fff6d6")
const TEAL := Color("139e9b")            # the brand's teal (spec §3c)
const TEAL_DARK := Color("0c7876")
const STAR := Color("ffd23f")
const GOLD := Color("f5c542")
const GOLD_LIGHT := Color("fff0a8")
const GOLD_DARK := Color("c99416")
const LAMP := Color("d8f1ff")

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	_page("moon.png", 20260955, _moon)
	_page("boing.png", 20260956, _boing)
	_page("rainbow.png", 20260957, _rainbow)
	_page("mars.png", 20260919, _mars)
	_page("europa.png", 20260920, _europa)
	_page("io.png", 20260921, _io)
	_page("titan.png", 20260922, _titan)
	_page("mercury.png", 20260923, _mercury)
	_page("venus.png", 20260924, _venus)
	_page("rings.png", 20260925, _rings)
	_page("pluto.png", 20260926, _pluto)
	_page("triton.png", 20260927, _triton)
	_page("ganymede.png", 20260928, _ganymede)
	quit()


func _page(file: String, seed: int, draw: Callable) -> void:
	var only := OS.get_cmdline_user_args()
	if not only.is_empty() and not only.has(file.get_basename()):
		return
	rng.seed = seed
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	draw.call()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var err := img.save_png(DIR + file)
	print("SPACE_ATLAS %s saved err=%d" % [file, err])


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _noise_tile(t: Vector2i, base: Color, amount: float) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(base, amount))


# --- Page 15: the Moon -----------------------------------------------------------------------------

func _moon() -> void:
	_dust_top(Vector2i(0, 0))
	_dust_side(Vector2i(1, 0))
	_rock(Vector2i(2, 0), ROCK, ROCK_DARK, ROCK_LIGHT)
	_rock(Vector2i(3, 0), DEEP, DEEP_DARK, ROCK_DARK)
	_crystal_side(Vector2i(4, 0))
	_crystal_top(Vector2i(5, 0))
	_cheese(Vector2i(6, 0))
	_cheese(Vector2i(7, 0))
	_panel(Vector2i(0, 1))
	_porthole(Vector2i(1, 1))
	_pad_top(Vector2i(2, 1))
	_pad_side(Vector2i(3, 1))
	_star_gold(Vector2i(4, 1))
	_rock(Vector2i(5, 1), ROCK, ROCK_DARK, ROCK_LIGHT)   # fake moon rock: the rock with a hairline door
	for y in range(3, 16):
		_px(Vector2i(5, 1), 3, y, ROCK_DARK.darkened(0.08))
		_px(Vector2i(5, 1), 12, y, ROCK_DARK.darkened(0.08))
	_lamp_side(Vector2i(6, 1))
	_lamp_top(Vector2i(7, 1))


## Fine silvery dust, a few tiny craters and white sparkles.
func _dust_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ripple := sin(x * 0.7 + y * 1.1) + cos(y * 0.5 - x * 0.9)
			_px(t, x, y, _vary(DUST_LIGHT if ripple > 1.3 else (DUST_DARK if ripple < -1.4 else DUST), 0.025))
	for c: Vector3i in [Vector3i(4, 5, 2), Vector3i(11, 10, 2), Vector3i(12, 3, 1)]:
		for y in TILE:
			for x in TILE:
				var d := Vector2(x - c.x, y - c.y).length()
				if d <= c.z:
					_px(t, x, y, _vary(DUST_DARK, 0.02))
				elif d <= c.z + 1.0 and y < c.y:
					_px(t, x, y, DUST_LIGHT)
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), SPARKLE)


## Moon rock with a soft band of dust over its top edge.
func _dust_side(t: Vector2i) -> void:
	_rock(t, ROCK, ROCK_DARK, ROCK_LIGHT)
	for x in TILE:
		var deep := 3 + (1 if x % 4 == 1 else 0) + rng.randi_range(0, 1)
		for y in deep:
			_px(t, x, y, _vary(DUST_LIGHT if y == 0 else DUST, 0.02))
	_px(t, 5, 1, SPARKLE)
	_px(t, 12, 0, SPARKLE)


## Rock: speckles, a few little round pits with a light rim.
func _rock(t: Vector2i, base: Color, dark: Color, light: Color) -> void:
	_noise_tile(t, base, 0.035)
	for i in 10:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), light)
	for i in 3:
		var cx := rng.randi_range(2, 13)
		var cy := rng.randi_range(2, 13)
		_px(t, cx, cy, dark)
		_px(t, cx + 1, cy, dark)
		_px(t, cx, cy + 1, dark.lerp(base, 0.4))
		_px(t, cx, cy - 1, light)


## A pale blue crystal: long facets with bright edges.
func _crystal_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := x % 4
			var c := CRYSTAL_LIGHT if facet == 0 else (CRYSTAL_DARK if facet == 3 else CRYSTAL)
			if (x * 2 + y) % 9 == 0:
				c = CRYSTAL_LIGHT.lerp(CRYSTAL, 0.4)
			_px(t, x, y, _vary(c, 0.02))


## The crystal's end: a gem with a star of light.
func _crystal_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(CRYSTAL_DARK if ring >= 7 else (CRYSTAL if ring % 3 != 0 else CRYSTAL_LIGHT), 0.02))
	for i in range(5, 11):
		_px(t, i, 7, CRYSTAL_LIGHT)
		_px(t, 7, i, CRYSTAL_LIGHT)


## Moon cheese: golden, with round holes.
func _cheese(t: Vector2i) -> void:
	_noise_tile(t, CHEESE, 0.025)
	for i in 5:
		var cx := rng.randi_range(2, 13)
		var cy := rng.randi_range(2, 13)
		var r := rng.randf_range(1.6, 2.6)
		for y in TILE:
			for x in TILE:
				var d := Vector2(x - cx, y - cy).length()
				if d <= r:
					_px(t, x, y, CHEESE_HOLE)
				elif d <= r + 0.9 and y < cy:
					_px(t, x, y, CHEESE_DARK)


## A silver panel with a seam and rivets.
func _panel(t: Vector2i) -> void:
	_noise_tile(t, PANEL, 0.018)
	for i in TILE:
		_px(t, i, 0, PANEL_DARK)
		_px(t, 0, i, PANEL_DARK)
		_px(t, i, 8, PANEL_DARK)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13), Vector2i(2, 10), Vector2i(13, 10)]:
		_px(t, p.x, p.y, RIVET)


## A round window with a warm light inside, in a silver panel.
func _porthole(t: Vector2i) -> void:
	_panel(t)
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d <= 5.2:
				_px(t, x, y, _vary(WINDOW_LIGHT if d < 2.5 else WINDOW, 0.02))
			elif d <= 6.6:
				_px(t, x, y, RIVET)
	_px(t, 5, 5, Color.WHITE)
	_px(t, 6, 5, Color.WHITE)


## The landing pad: the brand's teal with a golden star in a ring.
func _pad_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := TEAL
			if d >= 6.5 and d <= 7.5:
				c = STAR
			elif d > 7.5:
				c = TEAL_DARK
			_px(t, x, y, _vary(c, 0.015))
	for y in TILE:
		for x in TILE:
			var p := Vector2(x - 7.5, y - 7.5)
			var a := atan2(p.y, p.x) + PI * 0.5
			var r := p.length()
			var spike := 0.5 + 0.5 * cos(a * 5.0)
			if r <= 1.8 + 3.2 * spike:
				_px(t, x, y, _vary(STAR, 0.02))


## The pad's side: teal with a golden stripe.
func _pad_side(t: Vector2i) -> void:
	_noise_tile(t, TEAL_DARK, 0.02)
	for x in TILE:
		_px(t, x, 1, STAR)
		_px(t, x, 2, STAR)
	for x in range(0, TILE, 4):
		for y in range(5, 15):
			_px(t, x, y, TEAL)


## Star gold: golden with little stars.
func _star_gold(t: Vector2i) -> void:
	_noise_tile(t, GOLD, 0.03)
	for p: Vector2i in [Vector2i(4, 4), Vector2i(11, 5), Vector2i(7, 11), Vector2i(12, 12), Vector2i(3, 12)]:
		_px(t, p.x, p.y, GOLD_LIGHT)
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_px(t, clampi(p.x + d.x, 0, 15), clampi(p.y + d.y, 0, 15), GOLD_LIGHT.lerp(GOLD, 0.4))
	for i in TILE:
		_px(t, i, 15, GOLD_DARK)
		_px(t, 15, i, GOLD_DARK)


## A soft white-blue lamp in a silver frame.
func _lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			_px(t, x, y, _vary(PANEL_DARK if edge else LAMP, 0.02))
	for x in range(3, 13):
		_px(t, x, 7, Color.WHITE)


func _lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(Color.WHITE if d < 3.0 else (LAMP if d < 6.5 else PANEL_DARK), 0.02))


# --- Page 16: Planet Boing ---------------------------------------------------------------------------

const MOSS := Color("9be34a")
const MOSS_DARK := Color("6fbf2a")
const MOSS_LIGHT := Color("c8f57e")
const SOIL := Color("2bb3a0")
const SOIL_DARK := Color("1d8a7b")
const PURPLE := Color("8a5cc9")
const PURPLE_DARK := Color("6a3fa6")
const PURPLE_LIGHT := Color("a984dd")
const JELLY := Color("ff7ab8")
const JELLY_DARK := Color("e0569a")
const JELLY_SHINE := Color("ffd1e8")
const STEM := Color("f5f0e6")
const COIL := Color("a8d8ff")
const CAP := Color("ff9f3a")
const CAP_DARK := Color("d9771c")
const CAP_SPOT := Color("fff07a")
const GILL := Color("f3e2c0")
const BULB := Color("d9ff6b")
const BULB_LIGHT := Color("f7ffd0")
const LILAC := Color("c7a6f2")
const LILAC_DARK := Color("9f7fd6")


func _boing() -> void:
	_moss_top(Vector2i(0, 0))
	_moss_side(Vector2i(1, 0))
	_noise_tile(Vector2i(2, 0), SOIL, 0.035)
	_rock(Vector2i(3, 0), PURPLE, PURPLE_DARK, PURPLE_LIGHT)
	_jelly(Vector2i(4, 0))
	_stem_side(Vector2i(5, 0))
	_stem_top(Vector2i(6, 0))
	_cap_top(Vector2i(7, 0))
	_cap_side(Vector2i(0, 1))
	_cap_gills(Vector2i(1, 1))
	_bulb(Vector2i(2, 1))
	_bricks(Vector2i(3, 1), LILAC, LILAC_DARK)
	_rock(Vector2i(4, 1), PURPLE, PURPLE_DARK, PURPLE_LIGHT)   # fake boing rock: the rock with a hairline door
	for y in range(3, 16):
		_px(Vector2i(4, 1), 3, y, PURPLE_DARK.darkened(0.1))
		_px(Vector2i(4, 1), 12, y, PURPLE_DARK.darkened(0.1))


## Springy lime moss with little curls.
func _moss_top(t: Vector2i) -> void:
	_noise_tile(t, MOSS, 0.03)
	for c: Vector2i in [Vector2i(4, 4), Vector2i(11, 3), Vector2i(7, 10), Vector2i(13, 12), Vector2i(2, 12)]:
		for a in 10:
			var ang := a * 0.7
			var r := 0.4 + a * 0.22
			_px(t, clampi(c.x + roundi(cos(ang) * r), 0, 15), clampi(c.y + roundi(sin(ang) * r), 0, 15), MOSS_DARK)
		_px(t, c.x, c.y, MOSS_LIGHT)


func _moss_side(t: Vector2i) -> void:
	_noise_tile(t, SOIL, 0.035)
	for x in TILE:
		var deep := 3 + (1 if x % 3 == 0 else 0) + rng.randi_range(0, 1)
		for y in deep:
			_px(t, x, y, _vary(MOSS_LIGHT if y == 0 else MOSS, 0.03))


## Glossy pink jelly with round shines.
func _jelly(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 5, y - 5).length()
			_px(t, x, y, _vary(JELLY_SHINE if d < 2.2 else (JELLY if (x + y) % 11 != 0 else JELLY_DARK), 0.02))
	_px(t, 11, 11, JELLY_SHINE)
	_px(t, 12, 11, JELLY_SHINE)


## A white stalk with a pale blue coil round it.
func _stem_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(COIL if posmod(x + y * 2, 8) < 2 else STEM, 0.02))


func _stem_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var r := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(COIL if int(r) % 3 == 0 else STEM, 0.02))


## An orange cap with yellow spots.
func _cap_top(t: Vector2i) -> void:
	_noise_tile(t, CAP, 0.03)
	for s: Vector3 in [Vector3(4, 4, 2.2), Vector3(11, 5, 1.8), Vector3(7, 11, 2.4), Vector3(13, 12, 1.5), Vector3(2, 12, 1.3)]:
		for y in TILE:
			for x in TILE:
				if Vector2(x - s.x, y - s.y).length() <= s.z:
					_px(t, x, y, _vary(CAP_SPOT, 0.02))


func _cap_side(t: Vector2i) -> void:
	_noise_tile(t, CAP, 0.03)
	for y in range(12, 16):
		for x in TILE:
			_px(t, x, y, _vary(CAP_DARK, 0.02))
	for s: Vector2i in [Vector2i(3, 4), Vector2i(4, 4), Vector2i(3, 5), Vector2i(10, 2), Vector2i(11, 2), Vector2i(10, 3),
			Vector2i(13, 7), Vector2i(7, 8), Vector2i(8, 8)]:
		_px(t, s.x, s.y, CAP_SPOT)


func _cap_gills(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var a := atan2(y - 7.5, x - 7.5)
			var gill := posmod(int(floor(a / TAU * 20.0)), 2) == 0
			_px(t, x, y, _vary(GILL if gill else GILL.darkened(0.15), 0.02))
	for y in range(6, 10):
		for x in range(6, 10):
			_px(t, x, y, STEM)


## A glowing bulb in a dark lilac frame.
func _bulb(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := LILAC_DARK
			if d < 6.5:
				c = BULB_LIGHT if d < 3.0 else BULB
			_px(t, x, y, _vary(c, 0.02))


## Bricks in rows, each row half a brick over.
func _bricks(t: Vector2i, base: Color, mortar: Color) -> void:
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var edge := y % 4 == 3 or posmod(x + (4 if row % 2 == 1 else 0), 8) == 7
			_px(t, x, y, _vary(mortar if edge else base, 0.025))


# --- Page 17: Rainbow Planet -------------------------------------------------------------------------

const PRISM := Color("aaeec4")        # a clear pastel mint (d8f7e2 washed out to white under the haze)
const PRISM_DARK := Color("88dca8")
const PALE := Color("f4eef8")
const STRIPE_COLORS: Array[Color] = [Color("ff6b6b"), Color("ffa94d"), Color("ffe066"), Color("69db7c"), Color("4dabf7"),
	Color("b197fc")]
const GLASS := Color("f7fbff")


func _rainbow() -> void:
	_prism_top(Vector2i(0, 0))
	_prism_side(Vector2i(1, 0))
	for i in 6:
		var c: Color = STRIPE_COLORS[i]
		_rock(Vector2i(2 + i, 0), c, c.darkened(0.18), c.lightened(0.25))
	_prism_crystal_side(Vector2i(0, 1))
	_prism_crystal_top(Vector2i(1, 1))
	_bricks(Vector2i(2, 1), Color.WHITE, Color("e3d6f5"))
	_prism_lamp_side(Vector2i(3, 1))
	_prism_lamp_top(Vector2i(4, 1))
	var blue: Color = STRIPE_COLORS[4]
	_rock(Vector2i(5, 1), blue, blue.darkened(0.18), blue.lightened(0.25))   # fake blue stripe: a hairline door
	for y in range(3, 16):
		_px(Vector2i(5, 1), 3, y, blue.darkened(0.3))
		_px(Vector2i(5, 1), 12, y, blue.darkened(0.3))


## Pastel mint grass with tiny sparkles in every colour of the rainbow.
func _prism_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(PRISM_DARK if (x * 3 + y * 5) % 7 == 0 else PRISM, 0.02))
	for i in 9:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), STRIPE_COLORS[i % 6])


## The grass's side: a thin mint lip over the six rainbow bands (2 pixels each, red at the top), so every terrace step
## shows a rainbow (the lead's look, 2026-09-29: one-block steps of pale sides hid the planet's stripes). The pale
## noise is drawn first as before, so the page's random numbers stay in step and every other tile is unchanged.
func _prism_side(t: Vector2i) -> void:
	_noise_tile(t, PALE, 0.025)
	for y in range(4, TILE):
		var c: Color = STRIPE_COLORS[(y - 4) / 2 % 6]
		for x in TILE:
			_px(t, x, y, c.darkened(0.06) if (x + y * 3) % 5 == 0 else c)
	for x in TILE:
		var deep := 3 + (1 if x % 4 == 2 else 0) + rng.randi_range(0, 1)
		for y in deep:
			_px(t, x, y, _vary(PRISM if y > 0 else PRISM.lightened(0.3), 0.02))
	_px(t, 5, 1, STRIPE_COLORS[0])
	_px(t, 11, 2, STRIPE_COLORS[4])


## A clear crystal with rainbow facet edges.
func _prism_crystal_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := x % 5
			var c := GLASS if facet != 0 else STRIPE_COLORS[(x / 5 + y / 4) % 6]
			_px(t, x, y, _vary(c, 0.015))


func _prism_crystal_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(STRIPE_COLORS[ring % 6] if ring % 2 == 0 else GLASS, 0.015))


## A white lamp with rainbow bands.
func _prism_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14
			_px(t, x, y, _vary(STRIPE_COLORS[y / 3 % 6].lightened(0.35) if not edge else Color("e3d6f5"), 0.015))


func _prism_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(Color.WHITE if d < 3.5 else (STRIPE_COLORS[int(d) % 6].lightened(0.3) if d < 7.0 else Color("e3d6f5")), 0.015))


# --- Page 18: Mars (cosmos, spec §21b.2) ------------------------------------------------------------

const MARS_DUST := Color("c8643a")        # iron oxide: rust-red
const MARS_DUST_DARK := Color("a54e2b")
const MARS_DUST_LIGHT := Color("de8456")
const REGOLITH := Color("8f4328")
const REGOLITH_DARK := Color("6e321f")
const REGOLITH_LIGHT := Color("b35f3c")
const BASALT := Color("47403f")
const BASALT_DARK := Color("332d2d")
const BASALT_LIGHT := Color("5e5553")
const DEEP_BASALT := Color("363032")
const DEEP_BASALT_DARK := Color("262224")
const SEDIMENT := Color("d9b48f")
const SEDIMENT_DARK := Color("c2966d")
const SEDIMENT_LIGHT := Color("ecd2b3")
const POLAR := Color("f2f6fb")
const POLAR_SHADE := Color("d9e6f2")
const POLAR_DUST := Color("d8b89c")
const DRY := Color("e2eefc")
const DRY_BLUE := Color("b9d4f2")
const GYP := Color("fff1dc")
const GYP_PEACH := Color("f5d3b0")
const ROVER := Color("eef0f2")
const ROVER_SEAM := Color("c4c9cf")
const BOLT := Color("9aa2ab")
const WHEEL := Color("3b3f45")
const WHEEL_LIGHT := Color("9aa0a8")
const HUB := Color("c9ced4")
const SOLAR := Color("24479a")
const SOLAR_LINE := Color("c0c8d4")
const SOLAR_SHINE := Color("4d74c9")
const FOIL := Color("e8b53a")
const FOIL_LIGHT := Color("ffe28a")
const FOIL_DARK := Color("b4841c")
const ROVER_LAMP := Color("fff4d6")
const LAMP_FRAME := Color("8d949c")


func _mars() -> void:
	_mars_dust_top(Vector2i(0, 0))
	_mars_dust_side(Vector2i(1, 0))
	_regolith(Vector2i(2, 0))
	_rock(Vector2i(3, 0), BASALT, BASALT_DARK, BASALT_LIGHT)
	_rock(Vector2i(4, 0), DEEP_BASALT, DEEP_BASALT_DARK, BASALT)
	_sediment_top(Vector2i(5, 0))
	_sediment_side(Vector2i(6, 0))
	_polar_top(Vector2i(7, 0))
	_polar_side(Vector2i(0, 1))
	_dry_ice(Vector2i(1, 1))
	_gypsum_side(Vector2i(2, 1))
	_gypsum_top(Vector2i(3, 1))
	_rover_panel(Vector2i(4, 1))
	_wheel_tread(Vector2i(5, 1))
	_wheel_hub(Vector2i(6, 1))
	_solar(Vector2i(7, 1))
	_foil(Vector2i(0, 2))
	_rock(Vector2i(1, 2), BASALT, BASALT_DARK, BASALT_LIGHT)   # fake basalt: the basalt with a hairline door
	for y in range(3, 16):
		_px(Vector2i(1, 2), 3, y, BASALT_DARK.darkened(0.12))
		_px(Vector2i(1, 2), 12, y, BASALT_DARK.darkened(0.12))
	_rover_lamp_side(Vector2i(2, 2))
	_rover_lamp_top(Vector2i(3, 2))


## Rust-red dust with wind ripples and a few dark pebbles.
func _mars_dust_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ripple := sin(x * 0.55 + y * 0.9 + sin(y * 0.4) * 1.5)
			_px(t, x, y, _vary(MARS_DUST_LIGHT if ripple > 0.82 else (MARS_DUST_DARK if ripple < -0.9 else MARS_DUST), 0.025))
	for i in 5:
		var p := Vector2i(rng.randi_range(1, 14), rng.randi_range(1, 14))
		_px(t, p.x, p.y, REGOLITH_DARK)
		_px(t, p.x + 1, p.y, REGOLITH)


## Regolith with a band of red dust over its top edge.
func _mars_dust_side(t: Vector2i) -> void:
	_regolith(t)
	for x in TILE:
		var deep := 3 + (1 if x % 5 == 2 else 0) + rng.randi_range(0, 1)
		for y in deep:
			_px(t, x, y, _vary(MARS_DUST_LIGHT if y == 0 else MARS_DUST, 0.025))


## Rusty broken rock: darker red-brown with pebbles.
func _regolith(t: Vector2i) -> void:
	_noise_tile(t, REGOLITH, 0.035)
	for i in 9:
		var p := Vector2i(rng.randi_range(0, 14), rng.randi_range(0, 14))
		var c := REGOLITH_LIGHT if i % 2 == 0 else REGOLITH_DARK
		_px(t, p.x, p.y, c)
		_px(t, p.x + 1, p.y, c)
		_px(t, p.x, p.y + 1, c.darkened(0.1))


## Pale layered rock seen from above: cracked like a dry mud bed.
func _sediment_top(t: Vector2i) -> void:
	_noise_tile(t, SEDIMENT, 0.02)
	for c: Array in [[Vector2i(0, 5), Vector2i(1, 0)], [Vector2i(9, 0), Vector2i(0, 1)], [Vector2i(9, 9), Vector2i(1, 0)],
			[Vector2i(4, 5), Vector2i(0, 1)]]:
		var p: Vector2i = c[0]
		for i in 7:
			_px(t, clampi(p.x, 0, 15), clampi(p.y, 0, 15), SEDIMENT_DARK)
			p += c[1] + (Vector2i(0, 1) if c[1].x == 1 and i % 3 == 2 else Vector2i.ZERO)


## Its side: thin layers in three shades (the canyon's walls are made of them).
func _sediment_side(t: Vector2i) -> void:
	for y in TILE:
		var band := SEDIMENT_LIGHT if y % 5 == 0 else (SEDIMENT_DARK if y % 5 == 3 else SEDIMENT)
		for x in TILE:
			var wobble := int(sin(x * 0.7 + y) * 0.6)
			_px(t, x, y, _vary(band if wobble == 0 else SEDIMENT, 0.02))


## White water ice with faint blue cracks.
func _polar_top(t: Vector2i) -> void:
	_noise_tile(t, POLAR, 0.015)
	for i in 3:
		var p := Vector2(rng.randi_range(0, 15), rng.randi_range(0, 15))
		var dir := Vector2.from_angle(rng.randf() * TAU)
		for k in 8:
			_px(t, clampi(roundi(p.x), 0, 15), clampi(roundi(p.y), 0, 15), POLAR_SHADE)
			p += dir


## Its side: layers of ice with thin dusty stripes (the caps' layered deposits).
func _polar_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var dusty := y % 5 == 2 or (y % 5 == 3 and (x + y) % 4 == 0)
			_px(t, x, y, _vary(POLAR_DUST if dusty else (POLAR_SHADE if y % 5 == 4 else POLAR), 0.015))


## Frosty blue-white dry ice with feathery frost and sparkles.
func _dry_ice(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var fern := absi((x + y) % 6 - 3) == 0 or absi((x - y + 16) % 7 - 3) == 0
			_px(t, x, y, _vary(DRY_BLUE if fern else DRY, 0.015))
	for i in 7:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## A gypsum crystal: long pale facets, peach and white.
func _gypsum_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := x % 5
			var c := Color.WHITE if facet == 0 else (GYP_PEACH if facet == 4 else GYP)
			if (x + y * 3) % 11 == 0:
				c = GYP_PEACH.lerp(Color.WHITE, 0.5)
			_px(t, x, y, _vary(c, 0.015))


## The crystal's end: a pale gem with a bright star.
func _gypsum_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(GYP_PEACH if ring >= 7 else (GYP if ring % 3 != 0 else Color.WHITE), 0.015))
	for i in range(5, 11):
		_px(t, i, 7, Color.WHITE)
		_px(t, 7, i, Color.WHITE)


## The rover's white panel with seams and bolts.
func _rover_panel(t: Vector2i) -> void:
	_noise_tile(t, ROVER, 0.015)
	for i in TILE:
		_px(t, i, 0, ROVER_SEAM)
		_px(t, 0, i, ROVER_SEAM)
		_px(t, 8, i, ROVER_SEAM)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(6, 2), Vector2i(10, 2), Vector2i(14, 2), Vector2i(2, 13), Vector2i(6, 13),
			Vector2i(10, 13), Vector2i(14, 13)]:
		_px(t, p.x, p.y, BOLT)


## A wheel's tread: dark with light chevron cleats.
func _wheel_tread(t: Vector2i) -> void:
	_noise_tile(t, WHEEL, 0.02)
	for y in TILE:
		for x in TILE:
			if posmod(y - absi(x - 7), 5) == 0:
				_px(t, x, y, _vary(WHEEL_LIGHT, 0.02))


## A wheel from the side: a round tyre, a silver hub and spokes.
func _wheel_hub(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var p := Vector2(x - 7.5, y - 7.5)
			var d := p.length()
			var c := WHEEL
			if d < 2.2:
				c = HUB
			elif d < 5.5:
				c = WHEEL_LIGHT if posmod(int(floor(atan2(p.y, p.x) / TAU * 12.0)), 2) == 0 else WHEEL.lightened(0.15)
			elif d < 6.3:
				c = HUB.darkened(0.2)
			_px(t, x, y, _vary(c, 0.02))


## Solar cells: deep blue squares in a silver grid, with a shine.
func _solar(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var line := x % 4 == 0 or y % 4 == 0
			var shine := (x + y) % 9 == 0 and not line
			_px(t, x, y, _vary(SOLAR_LINE if line else (SOLAR_SHINE if shine else SOLAR), 0.015))


## Crinkled gold foil: facets of light and shadow.
func _foil(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var n := sin(x * 1.3 + y * 0.4) + sin(y * 1.1 - x * 0.6) + sin((x + y) * 0.7)
			_px(t, x, y, _vary(FOIL_LIGHT if n > 1.2 else (FOIL_DARK if n < -1.0 else FOIL), 0.03))


## The rover's light: a warm lamp in a grey frame.
func _rover_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			_px(t, x, y, _vary(LAMP_FRAME if edge else ROVER_LAMP, 0.02))
	for x in range(4, 12):
		_px(t, x, 6, Color.WHITE)


## A round lens: a camera's eye.
func _rover_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(Color.WHITE if d < 2.5 else (ROVER_LAMP if d < 5.8 else LAMP_FRAME), 0.02))


# --- Page 20: Europa (cosmos, spec §21b.2) -----------------------------------------------------------

const E_ICE := Color("f2f4f8")            # the smooth white crust
const E_ICE_SHADE := Color("dde7f1")
const E_ICE_CREAM := Color("f5efe3")
const LINEA := Color("a65f40")            # reddish-brown: salts and sulphur in the cracks
const LINEA_DARK := Color("874a31")
const LINEA_LIGHT := Color("c07a57")
const BAND := Color("dcbca4")             # the ridges' stained ice
const BAND_LIGHT := Color("ecd8c7")
const BAND_DARK := Color("c7a087")
const DEEP_ICE := Color("8cb4e2")          # blue deep ice
const DEEP_ICE_DARK := Color("6f98cb")
const DEEP_ICE_LIGHT := Color("b6d3f2")
const SEAFLOOR := Color("5b5652")          # the rocky seafloor under the ice
const SEAFLOOR_DARK := Color("46423f")
const SEAFLOOR_LIGHT := Color("716a63")
const GLOW_ICE := Color("9fe8ff")          # glowing blue ice
const GLOW_ICE_LIGHT := Color("e8fcff")
const GLOW_ICE_DARK := Color("72cff3")
const SALT_WHITE := Color("fff5d6")        # sea salt crystals
const SALT_YELLOW := Color("f3dd9c")
const VENT_DEEP := Color("1f5aa0")         # a plume's vent: deep water under a frosty ring
const VENT_FROST := Color("d4f1ff")
const LANDER := Color("f1f4f8")
const LANDER_SEAM := Color("c8d0da")
const LANDER_BLUE := Color("3f7fd8")
const PROBE := Color("9aa3ad")
const PROBE_DARK := Color("6f7780")
const PROBE_BAND := Color("ffb13b")
const LANDER_LAMP := Color("e6f6ff")
const ICE_BRICK := Color("d3e6f8")
const ICE_MORTAR := Color("a9c7e7")


func _europa() -> void:
	_europa_ice_top(Vector2i(0, 0))
	_europa_ice_side(Vector2i(1, 0))
	_linea_top(Vector2i(2, 0))
	_linea_side(Vector2i(3, 0))
	_band_top(Vector2i(4, 0))
	_band_side(Vector2i(5, 0))
	_deep_ice(Vector2i(6, 0))
	_rock(Vector2i(7, 0), SEAFLOOR, SEAFLOOR_DARK, SEAFLOOR_LIGHT)
	_glow_ice_side(Vector2i(0, 1))
	_glow_ice_top(Vector2i(1, 1))
	_salt_side(Vector2i(2, 1))
	_salt_top(Vector2i(3, 1))
	_vent_top(Vector2i(4, 1))
	_vent_side(Vector2i(5, 1))
	_lander_panel(Vector2i(6, 1))
	_probe_side(Vector2i(7, 1))
	_probe_top(Vector2i(0, 2))
	_lander_lamp_side(Vector2i(1, 2))
	_lander_lamp_top(Vector2i(2, 2))
	_bricks(Vector2i(3, 2), ICE_BRICK, ICE_MORTAR)
	_deep_ice(Vector2i(4, 2))   # fake deep ice: the deep ice with a hairline door
	for y in range(3, 16):
		_px(Vector2i(4, 2), 3, y, DEEP_ICE_DARK.darkened(0.1))
		_px(Vector2i(4, 2), 12, y, DEEP_ICE_DARK.darkened(0.1))


## Smooth white ice with faint blue hairline cracks and a sparkle or two.
func _europa_ice_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var soft := sin(x * 0.4 + y * 0.25) + cos(y * 0.35 - x * 0.2)
			_px(t, x, y, _vary(E_ICE_CREAM if soft > 1.2 else E_ICE, 0.012))
	for i in 2:
		var p := Vector2(rng.randi_range(0, 15), rng.randi_range(0, 15))
		var dir := Vector2.from_angle(rng.randf() * TAU)
		for k in 10:
			_px(t, posmod(roundi(p.x), 16), posmod(roundi(p.y), 16), E_ICE_SHADE)
			p += dir
	for i in 4:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## Its side: white ice with a faint blue layer near the bottom.
func _europa_ice_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := E_ICE_SHADE if y == 11 or (y == 12 and (x + y) % 3 == 0) else E_ICE
			_px(t, x, y, _vary(c, 0.012))
	_px(t, 4, 1, Color.WHITE)


## A crack's reddish-brown ice, streaked along the crack.
func _linea_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var streak := sin(x * 0.25 + y * 1.3)
			_px(t, x, y, _vary(LINEA_LIGHT if streak > 0.75 else (LINEA_DARK if streak < -0.8 else LINEA), 0.025))


## Its side: the stain soaked into the ice, darker at the top.
func _linea_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := LINEA_DARK if y < 3 else (LINEA if y < 11 else LINEA.lerp(BAND, 0.5))
			if (x * 3 + y) % 11 == 0:
				c = LINEA_LIGHT
			_px(t, x, y, _vary(c, 0.025))


## The ridges' stained ice: pale tan-pink with soft blotches.
func _band_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var blot := sin(x * 0.6) + cos(y * 0.7 + x * 0.2)
			_px(t, x, y, _vary(BAND_LIGHT if blot > 1.1 else (BAND_DARK if blot < -1.2 else BAND), 0.02))


## Its side: stained on top, white ice underneath.
func _band_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var stain := 4 + (1 if x % 5 == 2 else 0)
			_px(t, x, y, _vary(BAND if y < stain else (BAND_LIGHT if y == stain else E_ICE_SHADE), 0.018))


## Blue deep ice in thin layers, with bubbles caught in it.
func _deep_ice(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.5) * 1.2), 5)
			_px(t, x, y, _vary(DEEP_ICE_LIGHT if layer == 0 else (DEEP_ICE_DARK if layer == 3 else DEEP_ICE), 0.02))
	for i in 5:
		_px(t, rng.randi_range(1, 14), rng.randi_range(1, 14), DEEP_ICE_LIGHT.lightened(0.3))


## Glowing blue ice: bright facets with white edges.
func _glow_ice_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := (x + y / 2) % 5
			_px(t, x, y, _vary(GLOW_ICE_LIGHT if facet == 0 else (GLOW_ICE_DARK if facet == 4 else GLOW_ICE), 0.015))


## Its top: rings of light round a bright middle.
func _glow_ice_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(GLOW_ICE_LIGHT if ring < 2 or ring % 3 == 0 else GLOW_ICE, 0.015))


## Sea salt: little cubes, white and pale yellow.
func _salt_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var cube := (x / 4 + y / 4) % 2 == 0
			var edge := x % 4 == 0 or y % 4 == 0
			_px(t, x, y, _vary(SALT_YELLOW if edge else (SALT_WHITE if cube else SALT_WHITE.lerp(SALT_YELLOW, 0.4)), 0.015))


## Its top: a cube seen from above, a bright corner.
func _salt_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(SALT_YELLOW if ring >= 7 or ring == 3 else SALT_WHITE, 0.015))
	for i in range(3, 7):
		_px(t, i, 3, Color.WHITE)


## A plume's vent: deep blue water in the middle, a frosty ring, salt at the rim.
func _vent_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := VENT_DEEP.lerp(GLOW_ICE, clampf((d - 1.5) / 3.5, 0.0, 1.0)) if d < 5.0 else (VENT_FROST if d < 6.5 else SALT_WHITE)
			_px(t, x, y, _vary(c, 0.015))


## Its side: a salt crust over frosty blue ice.
func _vent_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := SALT_WHITE if y < 3 else (VENT_FROST if y < 8 else GLOW_ICE)
			_px(t, x, y, _vary(c, 0.015))


## The Ice Lander's panel: white, a blue stripe, seams and bolts.
func _lander_panel(t: Vector2i) -> void:
	_noise_tile(t, LANDER, 0.012)
	for i in TILE:
		_px(t, i, 0, LANDER_SEAM)
		_px(t, 0, i, LANDER_SEAM)
		_px(t, i, 7, LANDER_BLUE)
		_px(t, i, 8, LANDER_BLUE)
	for p: Vector2i in [Vector2i(3, 3), Vector2i(12, 3), Vector2i(3, 12), Vector2i(12, 12)]:
		_px(t, p.x, p.y, PROBE)


## The melt probe's side (and the legs): a metal tube with bright orange bands.
func _probe_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := PROBE_DARK if x <= 1 or x >= 14 else (PROBE.lightened(0.2) if x == 5 else PROBE)
			if y % 8 == 2 or y % 8 == 3:
				c = PROBE_BAND
			_px(t, x, y, _vary(c, 0.015))


## Its end: a round metal cap.
func _probe_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(PROBE.lightened(0.25) if d < 3.0 else (PROBE if d < 6.5 else PROBE_DARK), 0.015))


## The lander's light: a cool lamp in a grey frame.
func _lander_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			_px(t, x, y, _vary(PROBE if edge else LANDER_LAMP, 0.015))
	for x in range(4, 12):
		_px(t, x, 6, Color.WHITE)


## Its lens.
func _lander_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(Color.WHITE if d < 2.5 else (LANDER_LAMP if d < 5.8 else PROBE), 0.015))


# --- Page 21: Io (cosmos, spec §21b.2) ---------------------------------------------------------------

const SULPHUR := Color("f2dc4c")          # yellow sulphur: the plains
const SULPHUR_LIGHT := Color("fbef8e")
const SULPHUR_DARK := Color("d9bb2e")
const SULPHUR_ORANGE := Color("eb9a3a")    # orange sulphur
const SULPHUR_ORANGE_DARK := Color("cf7a24")
const SULPHUR_ORANGE_LIGHT := Color("f6b965")
const IO_FROST := Color("f4f2e6")          # white frost: frozen sulphur dioxide
const IO_FROST_SHADE := Color("e2e3da")
const RED_S := Color("c9452e")             # red sulphur: a plume's ring
const RED_S_DARK := Color("a8331f")
const RED_S_LIGHT := Color("dd6a45")
const IO_ROCK := Color("8c7c68")           # Io's rock
const IO_ROCK_DARK := Color("6d5f4f")
const IO_ROCK_LIGHT := Color("a6977f")
const BLACK_LAVA := Color("2b2726")        # black lava rock
const BLACK_LAVA_DARK := Color("1c1a1a")
const BLACK_LAVA_LIGHT := Color("48413d")
const CRUST := Color("1f1b1a")             # a lava lake's black crust ...
const CRACK := Color("ff9a2a")             # ... and its glowing cracks
const CRACK_HOT := Color("ffd35a")
const LAVA := Color("ff8a1e")              # hot lava
const LAVA_HOT := Color("ffd84a")
const LAVA_WHITE := Color("fff3b0")
const LAVA_RED := Color("f2581a")
const HEAT_TILE := Color("eef0f2")         # the lander's heat tiles
const HEAT_SEAM := Color("b9bec6")
const HEAT_GOLD := Color("e8b43a")
const LEG := Color("9aa0a8")
const LEG_DARK := Color("6c727a")
const CAMERA_LENS := Color("ff6a3a")       # the heat camera's warm lens
const CAMERA_GLOW := Color("ffc07a")


func _io() -> void:
	_sulphur_top(Vector2i(0, 0), SULPHUR, SULPHUR_DARK, SULPHUR_LIGHT)
	_sulphur_side(Vector2i(1, 0), SULPHUR, SULPHUR_DARK, SULPHUR_LIGHT)
	_sulphur_top(Vector2i(2, 0), SULPHUR_ORANGE, SULPHUR_ORANGE_DARK, SULPHUR_ORANGE_LIGHT)
	_sulphur_side(Vector2i(3, 0), SULPHUR_ORANGE, SULPHUR_ORANGE_DARK, SULPHUR_ORANGE_LIGHT)
	_frost_top(Vector2i(4, 0))
	_coated_side(Vector2i(5, 0), IO_FROST, IO_FROST_SHADE)
	_sulphur_top(Vector2i(6, 0), RED_S, RED_S_DARK, RED_S_LIGHT)
	_coated_side(Vector2i(7, 0), RED_S, RED_S_DARK)
	_io_rock(Vector2i(0, 1))
	_rock(Vector2i(1, 1), BLACK_LAVA, BLACK_LAVA_DARK, BLACK_LAVA_LIGHT)
	_crust_top(Vector2i(2, 1))
	_crust_side(Vector2i(3, 1))
	_lava_top(Vector2i(4, 1))
	_lava_side(Vector2i(5, 1))
	_io_vent_top(Vector2i(6, 1))
	_io_vent_side(Vector2i(7, 1))
	_sulphur_crystal_side(Vector2i(0, 2))
	_sulphur_crystal_top(Vector2i(1, 2))
	_heat_tile(Vector2i(2, 2))
	_leg_side(Vector2i(3, 2))
	_leg_top(Vector2i(4, 2))
	_camera_side(Vector2i(5, 2))
	_camera_top(Vector2i(6, 2))
	_bricks(Vector2i(7, 2), SULPHUR, SULPHUR_ORANGE_DARK)
	_io_rock(Vector2i(0, 3))   # fake Io rock: the rock with a hairline door
	for y in range(3, 16):
		_px(Vector2i(0, 3), 3, y, IO_ROCK_DARK.darkened(0.12))
		_px(Vector2i(0, 3), 12, y, IO_ROCK_DARK.darkened(0.12))


## Sulphur powder: soft blotches, a few lighter and darker grains.
func _sulphur_top(t: Vector2i, base: Color, dark: Color, light: Color) -> void:
	for y in TILE:
		for x in TILE:
			var blot := sin(x * 0.55 + y * 0.3) + cos(y * 0.6 - x * 0.35)
			_px(t, x, y, _vary(light if blot > 1.25 else (dark if blot < -1.3 else base), 0.02))
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), light.lightened(0.2))
	for i in 4:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), dark)


## Its side: the powder in thin layers, brighter at the top.
func _sulphur_side(t: Vector2i, base: Color, dark: Color, light: Color) -> void:
	for y in TILE:
		for x in TILE:
			var c := light if y < 2 else (dark if posmod(y + int(sin(x * 0.7) * 1.2), 6) == 0 else base)
			_px(t, x, y, _vary(c, 0.02))


## White frost: faint feathery lines, sparkles.
func _frost_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var fern := absi((x + y) % 7 - 3) == 0 or absi((x - y + 16) % 9 - 4) == 0
			_px(t, x, y, _vary(IO_FROST_SHADE if fern else IO_FROST, 0.012))
	for i in 5:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## A thin coat (frost, red sulphur) over yellow sulphur.
func _coated_side(t: Vector2i, coat: Color, coat_dark: Color) -> void:
	for y in TILE:
		for x in TILE:
			var edge := 4 + (1 if x % 5 == 2 else 0) - (1 if x % 7 == 4 else 0)
			var c := coat if y < edge else (coat_dark if y == edge else (SULPHUR_DARK if posmod(y, 6) == 0 else SULPHUR))
			_px(t, x, y, _vary(c, 0.018))


## Io's rock: warm grey-brown with pale grains and dark pits.
func _io_rock(t: Vector2i) -> void:
	_rock(t, IO_ROCK, IO_ROCK_DARK, IO_ROCK_LIGHT)
	for x in TILE:
		if x % 5 != 3:
			_px(t, x, 10, _vary(IO_ROCK_DARK, 0.02))


## A lava lake's crust: black plates with glowing orange cracks between them.
func _crust_top(t: Vector2i) -> void:
	var seeds: Array[Vector2] = []
	for i in 4:
		seeds.append(Vector2(rng.randf_range(0, 16), rng.randf_range(0, 16)))
	for y in TILE:
		for x in TILE:
			var p := Vector2(x + 0.5, y + 0.5)
			var d1 := INF
			var d2 := INF
			for s in seeds:
				for o: Vector2 in [Vector2.ZERO, Vector2(16, 0), Vector2(-16, 0), Vector2(0, 16), Vector2(0, -16)]:
					var d := p.distance_to(s + o)
					if d < d1:
						d2 = d1
						d1 = d
					elif d < d2:
						d2 = d
			var gap := d2 - d1
			var c := CRUST
			if gap < 0.45:
				c = CRACK_HOT
			elif gap < 0.95:
				c = CRACK
			elif (x * 7 + y * 3) % 13 == 0:
				c = BLACK_LAVA_LIGHT
			_px(t, x, y, _vary(c, 0.015))


## Its side: the black crust on top, glowing lava under it.
func _crust_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := 5 + (1 if x % 4 == 1 else 0)
			var c := CRUST if y < edge else (CRACK_HOT if y == edge else (LAVA_HOT if (x + y) % 5 == 0 else LAVA))
			_px(t, x, y, _vary(c, 0.015))


## Hot lava: bright swirls of yellow and orange.
func _lava_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var swirl := sin(x * 0.6 + sin(y * 0.5) * 2.0) + cos(y * 0.45 - x * 0.2)
			var c := LAVA_WHITE if swirl > 1.5 else (LAVA_HOT if swirl > 0.4 else (LAVA_RED if swirl < -1.3 else LAVA))
			_px(t, x, y, _vary(c, 0.015))


## Its side: glowing bands.
func _lava_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var band := posmod(y + int(sin(x * 0.6) * 1.5), 5)
			_px(t, x, y, _vary(LAVA_HOT if band == 0 else (LAVA_RED if band == 3 else LAVA), 0.015))


## A volcano's vent: a glowing throat ringed with black lava and yellow sulphur.
func _io_vent_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := LAVA_WHITE if d < 1.8 else (LAVA_HOT if d < 3.2 else (LAVA if d < 4.5 else (BLACK_LAVA if d < 6.3 else SULPHUR)))
			_px(t, x, y, _vary(c, 0.015))


## Its side: black lava rock, glowing where the heat comes up.
func _io_vent_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := SULPHUR if y < 2 else (BLACK_LAVA if y < 8 else (LAVA if (x + y) % 3 != 0 else LAVA_HOT))
			_px(t, x, y, _vary(c, 0.015))


## A sulphur crystal: long yellow facets with bright edges.
func _sulphur_crystal_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := (x + y / 3) % 4
			_px(t, x, y, _vary(SULPHUR_LIGHT.lightened(0.2) if facet == 0 else (SULPHUR_DARK if facet == 3 else SULPHUR_LIGHT), 0.015))


## Its tip: a bright gem.
func _sulphur_crystal_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(SULPHUR_DARK if ring >= 7 else (SULPHUR_LIGHT if ring % 3 != 0 else Color.WHITE), 0.015))


## The lander's heat tiles: white squares with grey seams and a gold stripe.
func _heat_tile(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var seam := x % 8 == 0 or y % 8 == 0
			var c := HEAT_SEAM if seam else HEAT_TILE
			if y == 11 or y == 12:
				c = HEAT_GOLD
			_px(t, x, y, _vary(c, 0.012))


## A leg: a metal strut with dark bands.
func _leg_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := LEG_DARK if x <= 2 or x >= 13 else (LEG.lightened(0.2) if x == 6 else LEG)
			if y % 8 == 4:
				c = LEG_DARK
			_px(t, x, y, _vary(c, 0.015))


## Its end: a round foot.
func _leg_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(LEG.lightened(0.2) if d < 3.0 else (LEG if d < 6.5 else LEG_DARK), 0.015))


## The heat camera: a warm glowing lens in a grey frame.
func _camera_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := LEG if d >= 6.0 else (CAMERA_GLOW if d < 2.0 else CAMERA_LENS)
			if x <= 0 or x >= 15 or y <= 0 or y >= 15:
				c = LEG_DARK
			_px(t, x, y, _vary(c, 0.015))


## Its top: a lamp.
func _camera_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			_px(t, x, y, _vary(LEG if edge else CAMERA_GLOW, 0.015))
	for x in range(4, 12):
		_px(t, x, 6, Color.WHITE)


# --- Page 29: Titan (cosmos, spec §21b.2) ------------------------------------------------------------

const T_SOIL := Color("c07a3c")            # orange-brown soil under the orange haze
const T_SOIL_DARK := Color("a1622e")
const T_SOIL_LIGHT := Color("d6955a")
const T_PEBBLE := Color("e8e4dc")          # rounded pebbles of water ice
const T_PEBBLE_SHADE := Color("bdb7ad")
const T_PEBBLE_LIGHT := Color("fbf9f4")
const T_DUNE := Color("4a3526")            # the dunes' dark grains
const T_DUNE_DARK := Color("35251a")
const T_DUNE_LIGHT := Color("634935")
const T_SHORE := Color("6e4a2c")           # the dark wet shore
const T_SHORE_DARK := Color("563820")
const T_SHORE_GLINT := Color("c9a06a")
const T_ICE := Color("b9c6cf")             # icy rock: water ice as hard as stone
const T_ICE_DARK := Color("93a3af")
const T_ICE_LIGHT := Color("dbe4ea")
const T_CRYSTAL := Color("fff4dc")         # the bright crystals a drying lake leaves
const T_CRYSTAL_SHADE := Color("f1dcb2")
const T_FOIL := Color("e3b23c")            # the probe's gold foil ...
const T_FOIL_DARK := Color("b8861d")
const T_SHELL := Color("f1f2f4")           # ... and white shell
const T_SHELL_SEAM := Color("b9bec6")
const T_CHUTE := Color("ff7a1f")           # the parachute's orange ...
const T_CHUTE_WHITE := Color("fbf7f0")     # ... and white stripes
const T_LAMP := Color("fff1c9")
const T_LAMP_FRAME := Color("8d949c")
const T_BRICK := Color("e8c08a")           # the explorers' station: orange-cream bricks
const T_BRICK_MORTAR := Color("b4834c")


func _titan() -> void:
	_titan_soil_top(Vector2i(0, 0))
	_titan_soil_side(Vector2i(1, 0))
	_pebbles_top(Vector2i(2, 0))
	_pebbles_side(Vector2i(3, 0))
	_dune_top(Vector2i(4, 0))
	_dune_side(Vector2i(5, 0))
	_shore_top(Vector2i(6, 0))
	_shore_side(Vector2i(7, 0))
	_icy_rock(Vector2i(0, 1))
	_shore_crystal_side(Vector2i(1, 1))
	_shore_crystal_top(Vector2i(2, 1))
	_probe_shell_side(Vector2i(3, 1))
	_probe_shell_top(Vector2i(4, 1))
	_parachute(Vector2i(5, 1))
	_probe_lamp_side(Vector2i(6, 1))
	_probe_lamp_top(Vector2i(7, 1))
	_bricks(Vector2i(0, 2), T_BRICK, T_BRICK_MORTAR)
	_icy_rock(Vector2i(1, 2))   # fake icy rock: the rock with a hairline door
	for y in range(3, 16):
		_px(Vector2i(1, 2), 3, y, T_ICE_DARK.darkened(0.12))
		_px(Vector2i(1, 2), 12, y, T_ICE_DARK.darkened(0.12))


## Titan's soil: fine orange-brown grains, soft blotches, a few tiny pale flecks of ice.
func _titan_soil_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var blot := sin(x * 0.5 + y * 0.35) + cos(y * 0.55 - x * 0.4)
			_px(t, x, y, _vary(T_SOIL_LIGHT if blot > 1.35 else (T_SOIL_DARK if blot < -1.35 else T_SOIL), 0.025))
	for i in 5:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), T_PEBBLE_SHADE)


## Its side: the soil in thin layers, lighter at the top.
func _titan_soil_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := T_SOIL_LIGHT if y < 2 else (T_SOIL_DARK if posmod(y + int(sin(x * 0.6) * 1.3), 5) == 0 else T_SOIL)
			_px(t, x, y, _vary(c, 0.022))


## One rounded pebble of ice at (cx, cy), radius r: lit from the top left, a shade at the bottom right.
func _pebble(t: Vector2i, cx: float, cy: float, r: float) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x + 0.5 - cx, (y + 0.5 - cy) * 1.25)
			if d.length() > r:
				continue
			var lit := (-d.x - d.y) / r
			_px(t, x, y, _vary(T_PEBBLE_LIGHT if lit > 0.55 else (T_PEBBLE_SHADE if lit < -0.45 else T_PEBBLE), 0.012))


## Ice pebbles on the soil (rounded like river stones).
func _pebbles_top(t: Vector2i) -> void:
	_titan_soil_top(t)
	for p: Vector3 in [Vector3(3.5, 3.5, 3.0), Vector3(10.5, 3.0, 2.6), Vector3(7.0, 8.5, 3.4), Vector3(13.0, 10.0, 2.8),
			Vector3(3.0, 12.0, 2.8), Vector3(9.5, 14.0, 2.2), Vector3(14.5, 5.5, 1.8)]:
		_pebble(t, p.x, p.y, p.z)


## Its side: the soil with pebbles at the top.
func _pebbles_side(t: Vector2i) -> void:
	_titan_soil_side(t)
	for p: Vector3 in [Vector3(2.5, 2.0, 2.4), Vector3(7.5, 2.5, 2.8), Vector3(12.5, 1.8, 2.4), Vector3(5.0, 6.0, 1.6)]:
		_pebble(t, p.x, p.y, p.z)


## The dunes' dark grains: wind ripples running across, a few lighter grains.
func _dune_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ripple := posmod(int(y + 1.6 * sin(x * 0.45)), 4)
			_px(t, x, y, _vary(T_DUNE_LIGHT if ripple == 0 else (T_DUNE_DARK if ripple == 2 else T_DUNE), 0.02))
	for i in 8:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), T_DUNE_LIGHT.lightened(0.15))


## Its side: sloping layers of grains.
func _dune_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var bed := posmod(y + x / 3, 5)
			_px(t, x, y, _vary(T_DUNE_DARK if bed == 0 else (T_DUNE_LIGHT if bed == 3 else T_DUNE), 0.02))


## The wet shore: dark damp soil with a few glints.
func _shore_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var blot := sin(x * 0.7 + y * 0.2) + cos(y * 0.8 - x * 0.3)
			_px(t, x, y, _vary(T_SHORE_DARK if blot < -1.2 else T_SHORE, 0.02))
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), T_SHORE_GLINT)


## Its side: a dark wet band over the soil.
func _shore_side(t: Vector2i) -> void:
	_titan_soil_side(t)
	for y in 5:
		for x in TILE:
			_px(t, x, y, _vary(T_SHORE_DARK if y == 4 else T_SHORE, 0.02))


## Icy rock: pale grey-blue ice, speckles, a few hairline cracks.
func _icy_rock(t: Vector2i) -> void:
	_rock(t, T_ICE, T_ICE_DARK, T_ICE_LIGHT)
	for i in 6:
		_px(t, 4 + i, 6 + i / 2, T_ICE_DARK)
		_px(t, 12 - i / 2, 11 + i / 3, T_ICE_DARK)


## A shore crystal: long cream facets with bright edges.
func _shore_crystal_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := (x + y / 3) % 4
			_px(t, x, y, _vary(Color.WHITE if facet == 0 else (T_CRYSTAL_SHADE if facet == 3 else T_CRYSTAL), 0.012))


## Its tip: a bright gem.
func _shore_crystal_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(T_CRYSTAL_SHADE if ring >= 7 else (T_CRYSTAL if ring % 3 != 0 else Color.WHITE), 0.012))


## The probe's shell from the side: white with a band of gold foil and rivets.
func _probe_shell_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := T_SHELL
			if y >= 6 and y <= 10:
				c = T_FOIL if (x + y) % 5 != 0 else T_FOIL_DARK
			elif y == 5 or y == 11:
				c = T_SHELL_SEAM
			_px(t, x, y, _vary(c, 0.012))
	for x in range(1, 16, 5):
		_px(t, x, 2, T_SHELL_SEAM)
		_px(t, x, 13, T_SHELL_SEAM)


## Its top: rings of white and gold round a middle.
func _probe_shell_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := T_SHELL if d < 3.0 else (T_FOIL if d < 5.0 else (T_SHELL_SEAM if d < 5.8 else T_SHELL))
			_px(t, x, y, _vary(c, 0.012))


## The parachute's cloth: wide orange and white stripes.
func _parachute(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var stripe := posmod(x + y, 8) < 4
			_px(t, x, y, _vary(T_CHUTE if stripe else T_CHUTE_WHITE, 0.012))


## A probe lamp: a warm light in a grey frame.
func _probe_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(T_LAMP_FRAME if edge else (Color.WHITE if d < 2.5 else T_LAMP), 0.012))


## Its top: the lamp's round glass.
func _probe_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(T_LAMP_FRAME if d > 6.8 else (Color.WHITE if d < 2.2 else T_LAMP), 0.012))


# --- Page 30: Mercury (cosmos, spec §21b.2) ------------------------------------------------------------

const M_DUST := Color("8e8a85")            # Mercury's grey dust (a warmer, darker grey than the Moon's silver)
const M_DUST_DARK := Color("77736e")
const M_DUST_LIGHT := Color("a4a09a")
const M_ROCK := Color("76726d")            # its grey rock
const M_ROCK_DARK := Color("5f5b57")
const M_ROCK_LIGHT := Color("8b8782")
const M_DARK := Color("575e6a")            # patches of darker, blue-grey dust
const M_DARK_DARK := Color("484e59")
const M_DARK_LIGHT := Color("68707c")
const M_RAY := Color("dcd9d3")             # a young crater's bright rays
const M_RAY_LIGHT := Color("f0eee9")
const M_RAY_SHADE := Color("c6c2bb")
const M_ICE := Color("e3f2fa")             # the ice in the shadowed craters
const M_ICE_SHADE := Color("c4dfee")
const M_ICE_LIGHT := Color("f7fcff")
const M_CRYSTAL := Color("bfeaff")         # glowing ice crystals
const M_CRYSTAL_DARK := Color("86cdef")
const M_CRYSTAL_LIGHT := Color("eefaff")
const M_SHADE := Color("f4f1ea")           # the sunshade's white ceramic cloth
const M_SHADE_SEAM := Color("d9d3c6")
const M_BLANKET := Color("cfd4da")         # the lander's silvery heat blanket
const M_BLANKET_DARK := Color("a9b0b9")
const M_BLANKET_LIGHT := Color("eef1f4")
const M_MIRROR := Color("c9dff0")          # mirror panels ...
const M_MIRROR_LIGHT := Color("f2f9ff")
const M_CELL := Color("2f4f86")            # ... with a few solar cells between them
const M_FRAME := Color("8d949c")
const M_LAMP := Color("fff4d6")
const M_BOARD := Color("f2f0ea")           # the thermometer's white board ...
const M_RED := Color("e8352b")             # ... its red line ...
const M_MARK := Color("2b2b2f")            # ... its marks ...
const M_GLASS := Color("dfe9ee")           # ... its glass tube and silver cap
const M_CAP := Color("b8bec6")
const M_BULB := Color("ff4b3a")            # the glowing red bulb
const M_BULB_LIGHT := Color("ffb3a8")
const M_BULB_DARK := Color("d8321f")
const M_BRICK := Color("d6ccbd")           # the explorers' warm grey bricks
const M_BRICK_MORTAR := Color("9e968a")


func _mercury() -> void:
	_merc_dust_top(Vector2i(0, 0))
	_merc_dust_side(Vector2i(1, 0))
	_rock(Vector2i(2, 0), M_ROCK, M_ROCK_DARK, M_ROCK_LIGHT)
	_merc_dark_top(Vector2i(3, 0))
	_merc_dark_side(Vector2i(4, 0))
	_merc_ray_top(Vector2i(5, 0))
	_merc_ray_side(Vector2i(6, 0))
	_shadow_ice_top(Vector2i(7, 0))
	_shadow_ice_side(Vector2i(0, 1))
	_ice_crystal_side(Vector2i(1, 1))
	_ice_crystal_top(Vector2i(2, 1))
	_sunshade(Vector2i(3, 1))
	_heat_blanket(Vector2i(4, 1))
	_mirror_top(Vector2i(5, 1))
	_mirror_side(Vector2i(6, 1))
	_explorer_lamp_side(Vector2i(7, 1))
	_explorer_lamp_top(Vector2i(0, 2))
	_thermo_tube(Vector2i(1, 2))
	_thermo_cap(Vector2i(2, 2))
	_bulb_side(Vector2i(3, 2))
	_bulb_top(Vector2i(4, 2))
	_bricks(Vector2i(5, 2), M_BRICK, M_BRICK_MORTAR)
	_rock(Vector2i(6, 2), M_ROCK, M_ROCK_DARK, M_ROCK_LIGHT)   # fake Mercury rock: the rock with a hairline door
	for y in range(3, 16):
		_px(Vector2i(6, 2), 3, y, M_ROCK_DARK.darkened(0.12))
		_px(Vector2i(6, 2), 12, y, M_ROCK_DARK.darkened(0.12))


## Mercury's dust: fine grey grains, a few tiny craters with a lit rim, pale flecks.
func _merc_dust_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ripple := sin(x * 0.6 + y * 0.9) + cos(y * 0.45 - x * 0.8)
			_px(t, x, y, _vary(M_DUST_LIGHT if ripple > 1.35 else (M_DUST_DARK if ripple < -1.35 else M_DUST), 0.022))
	for c: Vector3i in [Vector3i(4, 4, 2), Vector3i(11, 11, 2), Vector3i(12, 4, 1), Vector3i(4, 12, 1)]:
		for y in TILE:
			for x in TILE:
				var d := Vector2(x - c.x, y - c.y).length()
				if d <= c.z:
					_px(t, x, y, _vary(M_DUST_DARK, 0.02))
				elif d <= c.z + 1.0 and y < c.y:
					_px(t, x, y, M_DUST_LIGHT)
	for i in 4:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), M_DUST_LIGHT.lightened(0.15))


## Its side: grey rock with a band of dust over its top edge.
func _merc_dust_side(t: Vector2i) -> void:
	_rock(t, M_ROCK, M_ROCK_DARK, M_ROCK_LIGHT)
	for x in TILE:
		var deep := 3 + (1 if x % 5 == 2 else 0) + rng.randi_range(0, 1)
		for y in deep:
			_px(t, x, y, _vary(M_DUST_LIGHT if y == 0 else M_DUST, 0.02))


## Darker, blue-grey dust in soft blotches.
func _merc_dark_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var blot := sin(x * 0.5 + y * 0.3) + cos(y * 0.6 - x * 0.35)
			_px(t, x, y, _vary(M_DARK_LIGHT if blot > 1.3 else (M_DARK_DARK if blot < -1.3 else M_DARK), 0.02))
	for i in 3:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), M_DARK_LIGHT.lightened(0.1))


## Its side: the rock under a dark dust band.
func _merc_dark_side(t: Vector2i) -> void:
	_rock(t, M_ROCK, M_ROCK_DARK, M_ROCK_LIGHT)
	for x in TILE:
		var deep := 3 + rng.randi_range(0, 1)
		for y in deep:
			_px(t, x, y, _vary(M_DARK_LIGHT if y == 0 else M_DARK, 0.02))


## A young crater's bright rays: pale dust in long streaks.
func _merc_ray_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var streak := posmod(x * 2 + y, 7)
			_px(t, x, y, _vary(M_RAY_LIGHT if streak == 0 else (M_RAY_SHADE if streak == 4 else M_RAY), 0.015))


## Its side: the rock under a bright dust band.
func _merc_ray_side(t: Vector2i) -> void:
	_rock(t, M_ROCK, M_ROCK_DARK, M_ROCK_LIGHT)
	for x in TILE:
		var deep := 3 + rng.randi_range(0, 1)
		for y in deep:
			_px(t, x, y, _vary(M_RAY_LIGHT if y == 0 else M_RAY, 0.015))


## The shadowed craters' ice: pale blue-white, frosty sparkles and faint cracks.
func _shadow_ice_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frost := sin(x * 0.8 + y * 0.4) + cos(y * 0.7 - x * 0.5)
			_px(t, x, y, _vary(M_ICE_LIGHT if frost > 1.2 else (M_ICE_SHADE if frost < -1.4 else M_ICE), 0.012))
	for i in 5:
		_px(t, 2 + i * 2, 9 - i, M_ICE_SHADE)
		_px(t, 12 - i, 3 + i * 2, M_ICE_SHADE)
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## Its side: layers of ice, a faint blue line in each.
func _shadow_ice_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.5) * 1.2), 5)
			_px(t, x, y, _vary(M_ICE_SHADE if layer == 0 else (M_ICE_LIGHT if layer == 2 else M_ICE), 0.012))


## An ice crystal: long pale-blue facets with bright edges.
func _ice_crystal_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := (x + y / 4) % 4
			_px(t, x, y, _vary(M_CRYSTAL_LIGHT if facet == 0 else (M_CRYSTAL_DARK if facet == 3 else M_CRYSTAL), 0.015))


## Its tip: a gem with a star of light.
func _ice_crystal_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ring := int(maxf(absf(x - 7.5), absf(y - 7.5)))
			_px(t, x, y, _vary(M_CRYSTAL_DARK if ring >= 7 else (M_CRYSTAL if ring % 3 != 0 else M_CRYSTAL_LIGHT), 0.015))
	for i in range(5, 11):
		_px(t, i, 7, M_CRYSTAL_LIGHT)
		_px(t, 7, i, M_CRYSTAL_LIGHT)


## The sunshade: white ceramic cloth quilted in squares.
func _sunshade(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var seam := x % 4 == 0 or y % 4 == 0
			var puff := 1.0 - 0.02 * (absf(x % 4 - 2.0) + absf(y % 4 - 2.0))
			var c := M_SHADE_SEAM if seam else Color(M_SHADE.r * puff, M_SHADE.g * puff, M_SHADE.b * puff)
			_px(t, x, y, _vary(c, 0.01))


## The heat blanket: silvery, crinkled foil.
func _heat_blanket(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var crinkle := sin(x * 1.3 + y * 0.7) * cos(y * 1.1 - x * 0.5)
			_px(t, x, y, _vary(M_BLANKET_LIGHT if crinkle > 0.45 else (M_BLANKET_DARK if crinkle < -0.45 else M_BLANKET),
				0.015))
	for i in TILE:
		_px(t, i, 15, M_BLANKET_DARK)
		_px(t, 15, i, M_BLANKET_DARK)


## A mirror panel from above: rows of mirror tiles with a few solar cells between them (most of it mirrors).
func _mirror_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x % 4 == 3 or y % 4 == 3
			var cell := (x / 4) % 3 == 1
			var c := M_FRAME if edge else (M_CELL if cell else (M_MIRROR_LIGHT if x % 4 == 0 and y % 4 == 0 else M_MIRROR))
			_px(t, x, y, _vary(c, 0.012))


## Its edge: a thin frame with the panel's face.
func _mirror_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := M_FRAME
			if y >= 6 and y <= 9:
				c = M_MIRROR if (x / 4) % 3 != 1 else M_CELL
			_px(t, x, y, _vary(c, 0.012))


## An explorer lamp: a warm light in a grey frame.
func _explorer_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(M_FRAME if edge else (Color.WHITE if d < 2.5 else M_LAMP), 0.012))


## Its top: the lamp's round glass.
func _explorer_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(M_FRAME if d > 6.8 else (Color.WHITE if d < 2.2 else M_LAMP), 0.012))


## The thermometer's tube: a white board, a glass tube with the red line up it, marks on both sides.
func _thermo_tube(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := M_CAP
			if x >= 2 and x <= 13:
				c = M_BOARD
				if x >= 6 and x <= 9:
					c = M_RED if x == 7 or x == 8 else M_GLASS
				elif (x == 4 or x == 11) and y % 3 == 1:
					c = M_MARK
				elif (x == 3 or x == 12) and y % 6 == 1:
					c = M_MARK
			_px(t, x, y, _vary(c, 0.01))


## Its cap: a silver disc round the tube's red top.
func _thermo_cap(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(M_RED if d < 1.6 else (M_GLASS if d < 3.0 else M_CAP), 0.01))


## The bulb: a round red glow with a bright highlight.
func _bulb_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 8.5).length()
			var c := M_BULB if d < 6.5 else M_BULB_DARK
			if Vector2(x - 5.0, y - 5.5).length() < 1.8:
				c = M_BULB_LIGHT
			_px(t, x, y, _vary(c, 0.012))


## Its top: red glass in a silver ring.
func _bulb_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(M_CAP if d > 6.8 else (M_BULB_LIGHT if d < 2.0 else M_BULB), 0.012))


# --- Page 38: Venus's cloud city (cosmos, spec §21b.2) -------------------------------------------------------

const V_CLOUD := Color("f4df8e")           # the tops of Venus's yellow clouds far below
const V_CLOUD_LIGHT := Color("fdf2c4")
const V_CLOUD_SHADE := Color("e3c76e")
const V_DEEP := Color("d6a954")            # the deeper ochre clouds under them
const V_DEEP_DARK := Color("bf913d")
const V_DEEP_LIGHT := Color("e3bd6c")
const V_DECK := Color("f4efe3")            # the city's cream decks ...
const V_DECK_SEAM := Color("d9d1c0")
const V_DECK_LIGHT := Color("fbf8f1")
const V_HULL := Color("e3e8ef")            # ... over silvery float hulls
const V_HULL_RIB := Color("c1c9d4")
const V_HULL_LIGHT := Color("f5f7fa")
const V_TURF := Color("69bd48")            # the sky gardens' turf
const V_TURF_DARK := Color("55a33a")
const V_TURF_LIGHT := Color("8bd765")
const V_PLANK := Color("dca55b")           # the bridges' honey planks
const V_PLANK_DARK := Color("b07a3a")
const V_PLANK_LIGHT := Color("ecc07a")
const V_LAMP := Color("ffe6a0")            # the warm lamps
const V_LAMP_CORE := Color("fffaf0")
const V_FRAME := Color("d8dee6")           # white metal frames
const V_FRAME_DARK := Color("a9b2be")
const V_FRAME_LIGHT := Color("f0f3f7")
const V_HOME := Color("f6c9a9")            # the homes' peach panels
const V_HOME_DARK := Color("e5b08c")
const V_HOME_LIGHT := Color("fbdcc4")
const V_SKIN := Color("f1f3f6")            # the Research Blimp's white skin ...
const V_SKIN_SEAM := Color("d3d9e0")
const V_ORANGE := Color("f28c28")          # ... the brand's orange line in its teal stripe
const V_GONDOLA := Color("f6f7f9")         # the gondola's white wall ...
const V_WINDOW := Color("7cc6f0")          # ... its round window
const V_WINDOW_LIGHT := Color("c9ecff")
const V_WINDOW_FRAME := Color("aeb6c2")
const V_CELL := Color("2f4f86")            # solar cells
const V_CELL_LIGHT := Color("4a6fae")
const V_CELL_LINE := Color("8d949c")
const V_CRYSTAL := Color("ffe7a0")         # glowing cloud crystals
const V_CRYSTAL_DARK := Color("f3c95a")
const V_CRYSTAL_LIGHT := Color("fff8dc")
const V_BRASS := Color("cc9a44")           # the telescopes' brass
const V_BRASS_DARK := Color("94692a")
const V_BRASS_LIGHT := Color("e8bf6e")


func _venus() -> void:
	_venus_cloud_top(Vector2i(0, 0))
	_venus_cloud_side(Vector2i(1, 0))
	_deep_cloud(Vector2i(2, 0))
	_deck_top(Vector2i(3, 0))
	_deck_side(Vector2i(4, 0))
	_float_hull(Vector2i(5, 0))
	_turf_top(Vector2i(6, 0))
	_turf_side(Vector2i(7, 0))
	_plank_top(Vector2i(0, 1))
	_plank_side(Vector2i(1, 1))
	_cloud_lamp_top(Vector2i(2, 1))
	_cloud_lamp_side(Vector2i(3, 1))
	_sky_frame(Vector2i(4, 1))
	_home_panel(Vector2i(5, 1))
	_blimp_skin(Vector2i(6, 1))
	_blimp_stripe(Vector2i(7, 1))
	_gondola_side(Vector2i(0, 2))
	_solar_top(Vector2i(1, 2))
	_solar_side(Vector2i(2, 2))
	_cloud_crystal(Vector2i(3, 2))
	_telescope(Vector2i(4, 2))
	_float_hull(Vector2i(5, 2))   # a fake float hull: the hull with a hairline door
	for y in range(3, 16):
		_px(Vector2i(5, 2), 3, y, V_HULL_RIB.darkened(0.12))
		_px(Vector2i(5, 2), 12, y, V_HULL_RIB.darkened(0.12))


## The cloud tops: soft yellow puffs, lit on top, a little shade between them.
func _venus_cloud_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var puff := sin(x * 0.55 + y * 0.35) + cos(y * 0.6 - x * 0.3) + 0.5 * sin(x * 1.3 - y * 0.9)
			_px(t, x, y, _vary(V_CLOUD_LIGHT if puff > 1.2 else (V_CLOUD_SHADE if puff < -1.3 else V_CLOUD), 0.015))


## Their side: round puffs along the top edge, lit above and shaded below, fading into the deeper clouds.
func _venus_cloud_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var bump := 2.5 + 2.0 * absf(sin(x * 0.45 + 0.7))
			var c := V_CLOUD_LIGHT if y < bump else (V_CLOUD if y < 10 else V_CLOUD_SHADE)
			if y > 12:
				c = V_CLOUD_SHADE.lerp(V_DEEP_LIGHT, 0.5)
			_px(t, x, y, _vary(c, 0.015))


## The deeper clouds: ochre swirls.
func _deep_cloud(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var swirl := sin(x * 0.4 + y * 0.7) + cos(y * 0.35 - x * 0.8)
			_px(t, x, y, _vary(V_DEEP_LIGHT if swirl > 1.2 else (V_DEEP_DARK if swirl < -1.2 else V_DEEP), 0.018))


## The deck: cream panels in a grid, a small teal rivet at each panel's corner.
func _deck_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var seam := x % 8 == 0 or y % 8 == 0
			var shine := (x % 8 == 1 or y % 8 == 1) and not seam
			_px(t, x, y, _vary(V_DECK_SEAM if seam else (V_DECK_LIGHT if shine else V_DECK), 0.01))
	for c: Vector2i in [Vector2i(2, 2), Vector2i(10, 2), Vector2i(2, 10), Vector2i(10, 10)]:
		_px(t, c.x, c.y, TEAL)


## Its edge: a cream lip, the brand's teal trim, the hull's silver below.
func _deck_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := V_HULL
			if y < 2:
				c = V_DECK_LIGHT
			elif y < 4:
				c = TEAL if y == 2 else TEAL_DARK
			elif x % 4 == 0:
				c = V_HULL_RIB
			_px(t, x, y, _vary(c, 0.01))


## A float hull: silvery balloon cloth with ribs and a soft highlight.
func _float_hull(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := V_HULL_RIB if x % 4 == 0 else (V_HULL_LIGHT if (x + y / 3) % 7 == 2 else V_HULL)
			_px(t, x, y, _vary(c, 0.01))


## The garden turf: short grass with a few tiny flowers.
func _turf_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var blade := sin(x * 1.7 + y * 0.9) + cos(y * 1.3 - x * 0.7)
			_px(t, x, y, _vary(V_TURF_LIGHT if blade > 1.2 else (V_TURF_DARK if blade < -1.2 else V_TURF), 0.02))
	for c: Vector2i in [Vector2i(3, 4), Vector2i(11, 3), Vector2i(7, 11), Vector2i(13, 12)]:
		_px(t, c.x, c.y, Color("fff6c9") if c.x % 2 == 1 else Color("ff9ecb"))


## Its side: a grass fringe over the planter's cream wall.
func _turf_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var fringe := 3 + (1 if x % 3 == 0 else 0)
			var c := V_TURF if y < fringe else (V_DECK_SEAM if y == fringe or y == 15 else V_DECK)
			if y == 0:
				c = V_TURF_LIGHT
			_px(t, x, y, _vary(c, 0.015))


## The bridge planks from above: honey boards with dark gaps and grain.
func _plank_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var gap := y % 4 == 3
			var grain := (x * 3 + y * 7) % 11 == 0
			_px(t, x, y, _vary(V_PLANK_DARK if gap else (V_PLANK_LIGHT if grain else V_PLANK), 0.02))


## Their edge: the boards' ends over a white frame beam.
func _plank_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := V_PLANK if y < 6 else V_FRAME
			if y == 6 or (y < 6 and x % 5 == 0):
				c = V_PLANK_DARK
			elif y == 15:
				c = V_FRAME_DARK
			_px(t, x, y, _vary(c, 0.015))


## A cloud lamp's top: round warm glass in a white frame.
func _cloud_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(V_FRAME if d > 6.8 else (V_LAMP_CORE if d < 2.4 else V_LAMP), 0.01))


## Its side: a warm glowing pane in a thin white frame.
func _cloud_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(V_FRAME if edge else (V_LAMP_CORE if d < 3.0 else V_LAMP), 0.01))


## The white metal frame: a bevelled beam with rivets.
func _sky_frame(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := V_FRAME
			if x <= 1 or y <= 1:
				c = V_FRAME_LIGHT
			elif x >= 14 or y >= 14:
				c = V_FRAME_DARK
			_px(t, x, y, _vary(c, 0.01))
	for c: Vector2i in [Vector2i(4, 4), Vector2i(11, 4), Vector2i(4, 11), Vector2i(11, 11)]:
		_px(t, c.x, c.y, V_FRAME_DARK)


## A home's peach panels: smooth siding boards.
func _home_panel(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := V_HOME_DARK if y % 5 == 4 else (V_HOME_LIGHT if y % 5 == 0 else V_HOME)
			_px(t, x, y, _vary(c, 0.012))


## The blimp's skin: white cloth in long gores, a soft shade on every seam.
func _blimp_skin(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := V_SKIN_SEAM if y % 8 == 7 else V_SKIN
			_px(t, x, y, _vary(c, 0.01))


## Its stripe: the brand's teal with a thin orange line.
func _blimp_stripe(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := TEAL
			if y == 7 or y == 8:
				c = V_ORANGE
			elif y == 0 or y == 15:
				c = TEAL_DARK
			_px(t, x, y, _vary(c, 0.012))


## The gondola's side: a white wall with a round blue window.
func _gondola_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.0).length()
			var c := V_GONDOLA if d > 5.6 else (V_WINDOW_FRAME if d > 4.4 else V_WINDOW)
			if d <= 4.4 and Vector2(x - 6.0, y - 5.5).length() < 1.6:
				c = V_WINDOW_LIGHT
			if y >= 14:
				c = V_FRAME_DARK
			_px(t, x, y, _vary(c, 0.01))


## Solar film from above: dark blue cells in a light grid.
func _solar_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var line := x % 4 == 0 or y % 4 == 0
			var shine := x % 4 == 1 and y % 4 == 1
			_px(t, x, y, _vary(V_CELL_LINE if line else (V_CELL_LIGHT if shine else V_CELL), 0.012))


## Its edge: a thin frame with a row of cells.
func _solar_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var cell := y >= 4 and y <= 11 and x % 4 != 0
			_px(t, x, y, _vary(V_CELL if cell else V_CELL_LINE, 0.012))


## A cloud crystal: pale golden facets with bright edges.
func _cloud_crystal(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := (x + y / 3) % 4
			_px(t, x, y, _vary(V_CRYSTAL_LIGHT if facet == 0 else (V_CRYSTAL_DARK if facet == 3 else V_CRYSTAL), 0.012))


## A telescope: a round brass tube (lit above, shaded below) with two dark rings.
func _telescope(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := V_BRASS_LIGHT if y < 4 else (V_BRASS if y < 11 else V_BRASS_DARK)
			if x == 2 or x == 3 or x == 12 or x == 13:
				c = V_BRASS_DARK if y >= 2 else V_BRASS
			if y == 2 and x > 4 and x < 11:
				c = Color.WHITE.lerp(V_BRASS_LIGHT, 0.5)
			_px(t, x, y, _vary(c, 0.012))


# --- Page 40: Saturn's rings (cosmos, spec §21b.2) -------------------------------------------------------------------
# Real colours (NASA: "chunks of ice and rock"; NSSDC: the B and A rings bright, albedo 0.4-0.6; the C ring and the
# Cassini Division darker, 0.12-0.4): clean water ice white with a cool tint, frost brighter still, the dusty ice grey-tan,
# rock bits darker; Pan's ice pale cream, the dust on its ridge; our own friendly station (spec §3c).

const R_ICE := Color("e6eff8")             # clean water ice ...
const R_ICE_DARK := Color("c9d8e8")
const R_ICE_LIGHT := Color("f7fbff")
const R_ICE_BLUE := Color("b5cde6")        # ... its cracks, a cool blue
const R_FROST := Color("f5f9ff")           # the frosty tops
const R_SPARKLE := Color("ffffff")
const R_DUSTY := Color("a9a39a")           # the C ring's dusty ice
const R_DUSTY_DARK := Color("8d877f")
const R_DUSTY_LIGHT := Color("c2bcb2")
const R_ROCK := Color("6e665f")            # rock bits
const R_ROCK_DARK := Color("554e48")
const R_ROCK_LIGHT := Color("877f76")
const R_MOONLET := Color("ebe3d2")         # Pan's pale ice
const R_MOONLET_DARK := Color("d3c9b4")
const R_RIDGE := Color("d9ccb0")           # the ring dust on its ridge
const R_RIDGE_DARK := Color("bfae8c")
const R_CRYSTAL := Color("bfe8ff")         # glowing ring crystals
const R_CRYSTAL_DARK := Color("8fd0f5")
const R_CRYSTAL_LIGHT := Color("eefaff")
const R_PANEL := Color("eef2f5")           # the station's white panels
const R_PANEL_SEAM := Color("cfd6dd")
const R_WINDOW := Color("5aa7e0")
const R_WINDOW_LIGHT := Color("bfe3ff")
const R_LAMP := Color("ffe9b0")            # its warm lamps
const R_LAMP_CORE := Color("fffbf0")
const R_DISH := Color("f4f6f8")            # the radio dish
const R_DISH_SHADE := Color("d5dbe2")
const R_POWER := Color("ff9c4a")           # the glowing power pack's fins
const R_POWER_CORE := Color("ffd27a")
const R_POWER_DARK := Color("d9642a")
const R_TRUSS := Color("4a525c")           # dark metal struts
const R_TRUSS_LIGHT := Color("6b747f")
const R_TRUSS_DARK := Color("333a42")
const R_BEACON := Color("3fd6cf")          # the teal beacon's light
const R_BEACON_CORE := Color("c8fffb")
const R_BAND := Color("ead7a4")            # Saturn's pale gold zones ...
const R_BAND_BELT := Color("c9a46a")       # ... and tan belts
const R_BAND_LIGHT := Color("f6e9c4")


func _rings() -> void:
	_ring_frost_top(Vector2i(0, 0))
	_ring_ice(Vector2i(1, 0))
	_ring_frost_side(Vector2i(2, 0))
	_dusty_top(Vector2i(3, 0))
	_dusty_side(Vector2i(4, 0))
	_rock(Vector2i(5, 0), R_ROCK, R_ROCK_DARK, R_ROCK_LIGHT)
	_moonlet_top(Vector2i(6, 0))
	_moonlet_side(Vector2i(7, 0))
	_ridge_top(Vector2i(0, 1))
	_ridge_side(Vector2i(1, 1))
	_ring_crystal(Vector2i(2, 1))
	_station_panel(Vector2i(3, 1))
	_station_window(Vector2i(4, 1))
	_station_lamp_side(Vector2i(5, 1))
	_station_lamp_top(Vector2i(6, 1))
	_dish_top(Vector2i(7, 1))
	_dish_side(Vector2i(0, 2))
	_power_side(Vector2i(1, 2))
	_power_top(Vector2i(2, 2))
	_truss(Vector2i(3, 2))
	_beacon_side(Vector2i(4, 2))
	_beacon_top(Vector2i(5, 2))
	_saturn_band(Vector2i(6, 2))
	_ring_ice(Vector2i(7, 2))   # a fake ring ice: the ice with a hairline door
	for y in range(3, 16):
		_px(Vector2i(7, 2), 3, y, R_ICE_BLUE.darkened(0.1))
		_px(Vector2i(7, 2), 12, y, R_ICE_BLUE.darkened(0.1))


## Frost on a chunk's top: bright white grains, a few blue shadows and white sparkles.
func _ring_frost_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var grain := sin(x * 1.1 + y * 0.7) + cos(y * 1.3 - x * 0.5)
			_px(t, x, y, _vary(R_ICE_LIGHT if grain > 0.6 else (R_ICE if grain < -1.4 else R_FROST), 0.015))
	for i in 9:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), R_SPARKLE)


## Clean water ice: white with a cool tint, soft facets and a few thin blue cracks.
func _ring_ice(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := sin(x * 0.5 + y * 0.9) + 0.6 * cos(x * 1.2 - y * 0.4)
			_px(t, x, y, _vary(R_ICE_LIGHT if facet > 1.1 else (R_ICE_DARK if facet < -1.1 else R_ICE), 0.012))
	for c: Array in [[2, 3, 1, 1, 5], [9, 10, 1, -1, 4], [11, 2, 0, 1, 3]]:
		for k in int(c[4]):
			_px(t, clampi(int(c[0]) + int(c[2]) * k, 0, 15), clampi(int(c[1]) + int(c[3]) * k + k / 2, 0, 15), R_ICE_BLUE)


## A frosty chunk's side: the ice with a white rim of frost along its top.
func _ring_frost_side(t: Vector2i) -> void:
	_ring_ice(t)
	for x in TILE:
		var rim := 2 + int(absf(sin(x * 0.8 + 0.3)) * 2.0)
		for y in rim:
			_px(t, x, y, _vary(R_FROST, 0.012))
	for i in 4:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 1), R_SPARKLE)


## The C ring's dusty ice from above: grey-tan grains, darker specks.
func _dusty_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var grain := sin(x * 0.9 + y * 1.3) + cos(y * 0.7 - x * 1.1)
			_px(t, x, y, _vary(R_DUSTY_LIGHT if grain > 1.3 else (R_DUSTY_DARK if grain < -1.3 else R_DUSTY), 0.02))
	for i in 7:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), R_ROCK_LIGHT)


## Its side: dusty ice in soft layers.
func _dusty_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := (y + int(sin(x * 0.5) * 1.5)) % 5
			_px(t, x, y, _vary(R_DUSTY_DARK if layer == 0 else R_DUSTY, 0.02))


## Pan's pale ice from above: creamy, a few soft dimples.
func _moonlet_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(R_MOONLET, 0.018))
	for c: Vector3i in [Vector3i(4, 4, 2), Vector3i(11, 9, 2), Vector3i(6, 12, 1)]:
		for y in TILE:
			for x in TILE:
				if Vector2(x - c.x, y - c.y).length() <= c.z:
					_px(t, x, y, _vary(R_MOONLET_DARK, 0.015))


## Its side: pale ice with faint bands.
func _moonlet_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(R_MOONLET_DARK if (y + x / 5) % 6 == 0 else R_MOONLET, 0.018))


## The ring dust piled on Pan's ridge: soft powdery ripples.
func _ridge_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var ripple := sin(x * 0.9 + y * 0.3)
			_px(t, x, y, _vary(R_RIDGE_DARK if ripple > 0.8 else R_RIDGE, 0.018))


## Its side: dust over the moonlet's ice.
func _ridge_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var dust := 5 + int(absf(sin(x * 0.6)) * 3.0)
			_px(t, x, y, _vary(R_RIDGE if y < dust else R_MOONLET, 0.018))


## A ring crystal: pale blue facets with bright edges.
func _ring_crystal(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := (x + y / 3) % 4
			_px(t, x, y, _vary(R_CRYSTAL_LIGHT if facet == 0 else (R_CRYSTAL_DARK if facet == 3 else R_CRYSTAL), 0.012))


## The station's white panels: seams, rivets and a thin teal trim along the bottom.
func _station_panel(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := R_PANEL_SEAM if x % 8 == 0 or y == 0 else R_PANEL
			if y >= 14:
				c = TEAL
			_px(t, x, y, _vary(c, 0.01))
	for c: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 11), Vector2i(13, 11)]:
		_px(t, c.x, c.y, R_PANEL_SEAM)


## A station panel with a round blue window.
func _station_window(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.0).length()
			var c := R_PANEL if d > 5.6 else (R_PANEL_SEAM if d > 4.4 else R_WINDOW)
			if d <= 4.4 and Vector2(x - 6.0, y - 5.5).length() < 1.6:
				c = R_WINDOW_LIGHT
			if y >= 14:
				c = TEAL
			_px(t, x, y, _vary(c, 0.01))


## A station lamp's side: a warm glowing pane in a thin white frame.
func _station_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or x == 15 or y == 0 or y == 15
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(R_PANEL if edge else (R_LAMP_CORE if d < 3.5 else R_LAMP), 0.01))


## Its top: a round warm light.
func _station_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(R_PANEL if d > 7.0 else (R_LAMP_CORE if d < 3.0 else R_LAMP), 0.01))


## The radio dish's face: white rings round a grey feed in the middle.
func _dish_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := R_DISH if int(d) % 3 != 2 else R_DISH_SHADE
			if d < 1.6:
				c = R_TRUSS_LIGHT
			_px(t, x, y, _vary(c, 0.01))


## Its edge: a white rim over a shaded back.
func _dish_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(R_DISH if y < 6 else R_DISH_SHADE, 0.012))


## The power pack's side: glowing orange fins round its warm core.
func _power_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := R_POWER_DARK if x % 4 == 0 else (R_POWER_CORE if x % 4 == 2 else R_POWER)
			if y == 0 or y == 15:
				c = R_TRUSS
			_px(t, x, y, _vary(c, 0.012))


## Its top: a glowing round core in a dark ring.
func _power_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(R_TRUSS if d > 6.5 else (R_POWER_CORE if d < 3.0 else R_POWER), 0.012))


## A dark metal truss: a frame with a cross brace.
func _truss(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := R_TRUSS
			if x <= 1 or y <= 1:
				c = R_TRUSS_LIGHT
			elif x >= 14 or y >= 14:
				c = R_TRUSS_DARK
			elif x == y or x == 15 - y:
				c = R_TRUSS_LIGHT
			_px(t, x, y, _vary(c, 0.012))


## The beacon's side: a teal light in a white frame.
func _beacon_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(R_PANEL if edge else (R_BEACON_CORE if d < 2.5 else R_BEACON), 0.01))


## Its top: a teal glow.
func _beacon_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(R_BEACON_CORE if d < 3.0 else R_BEACON, 0.01))


## Saturn's clouds: pale gold zones and tan belts, a little wavy.
func _saturn_band(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var w := y + int(sin(x * 0.7) * 1.2)
			var band := posmod(w, 8)
			var c := R_BAND_BELT if band >= 5 else (R_BAND_LIGHT if band == 0 else R_BAND)
			_px(t, x, y, _vary(c, 0.012))


# --- Page 41: Pluto (cosmos, spec §21b.2) -----------------------------------------------------------------------------
# Real colours (New Horizons, 2015): the heart's bright, creamy nitrogen ice with darker edges between its churning cells,
# the uplands' peach-tan frost, the dark red-brown tholins and the red-stained ice under them, bright methane snow, water
# ice as a pale blue-grey rock; Charon grey with its red cap; our own friendly pink heart beacons (spec §3c).

const P_N2 := Color("f3ece0")              # the heart's nitrogen ice ...
const P_N2_DARK := Color("e2d8c6")
const P_N2_LIGHT := Color("fbf7ef")
const P_EDGE := Color("b8a792")            # ... and the darker edges between its cells
const P_EDGE_DARK := Color("98866f")
const P_WATER := Color("aab9c9")           # water ice, as hard as rock
const P_WATER_DARK := Color("8b9bae")
const P_WATER_LIGHT := Color("c7d3df")
const P_FROST := Color("d6a888")           # the uplands' peach-tan frost
const P_FROST_DARK := Color("c29372")
const P_FROST_LIGHT := Color("e6c3a4")
const P_THOLIN := Color("7a3f2c")          # tholins: dark red-brown
const P_THOLIN_DARK := Color("5e2f21")
const P_THOLIN_LIGHT := Color("94533b")
const P_RED_ICE := Color("b9846f")         # water ice stained red
const P_RED_ICE_DARK := Color("9d6a57")
const P_SNOW := Color("f8f9fb")            # methane snow
const P_SNOW_SHADE := Color("e6ebf2")
const P_CRYSTAL := Color("c8ecff")         # glowing frost crystals
const P_CRYSTAL_DARK := Color("9fd9f7")
const P_CRYSTAL_LIGHT := Color("f0fbff")
const P_BALLOON := Color("dde2ea")         # the drag balloon's silvery film
const P_BALLOON_FOLD := Color("b9c0cc")
const P_BALLOON_SHINE := Color("fbfcfe")
const P_BALLOON_SEAM := Color("e7c35a")
const P_CHARON := Color("9b9894")          # Charon's grey ...
const P_CHARON_DARK := Color("85827e")
const P_CAP := Color("8e4a33")             # ... and its red cap
const P_SPACE := Color("1c2233")
const P_HEART := Color("ff7fbf")           # the pink heart beacon
const P_HEART_CORE := Color("ffe0ef")
const P_HEART_GLOW := Color("ffb3d9")
const P_BRICK := Color("e9e4dc")           # the explorers' frost bricks
const P_MORTAR := Color("cbc2b4")


func _pluto() -> void:
	_n2_top(Vector2i(0, 0))
	_n2_side(Vector2i(1, 0))
	_cell_edge(Vector2i(2, 0))
	_water_ice(Vector2i(3, 0))
	_pluto_frost_top(Vector2i(4, 0))
	_pluto_frost_side(Vector2i(5, 0))
	_tholin_top(Vector2i(6, 0))
	_tholin_side(Vector2i(7, 0))
	_red_ice(Vector2i(0, 1))
	_methane_snow_top(Vector2i(1, 1))
	_methane_snow_side(Vector2i(2, 1))
	_frost_crystal(Vector2i(3, 1))
	_drag_balloon(Vector2i(4, 1))
	_charon_side(Vector2i(5, 1))
	_charon_top(Vector2i(6, 1))
	_heart_side(Vector2i(7, 1))
	_heart_top(Vector2i(0, 2))
	_bricks(Vector2i(1, 2), P_BRICK, P_MORTAR)
	_water_ice(Vector2i(2, 2))   # a fake water ice: the ice with a hairline door
	for y in range(3, 16):
		_px(Vector2i(2, 2), 3, y, P_WATER_DARK.darkened(0.12))
		_px(Vector2i(2, 2), 12, y, P_WATER_DARK.darkened(0.12))


## The heart's nitrogen ice from above: creamy and smooth, with faint swirls of the slowly flowing ice.
func _n2_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var swirl := sin(x * 0.45 + sin(y * 0.6) * 1.4) + 0.5 * cos(y * 0.35 - x * 0.2)
			_px(t, x, y, _vary(P_N2_LIGHT if swirl > 1.05 else (P_N2_DARK if swirl < -1.1 else P_N2), 0.01))


## Its side: nitrogen ice in faint layers.
func _n2_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.4) * 1.5), 6)
			_px(t, x, y, _vary(P_N2_DARK if layer == 0 else P_N2, 0.012))


## A cell's edge from above: grey-tan ice with dark streaks running along it.
func _cell_edge(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var streak := sin(x * 0.35 + y * 1.3) + 0.4 * sin(x * 1.7)
			_px(t, x, y, _vary(P_EDGE_DARK if streak > 0.9 else P_EDGE, 0.02))


## Water ice as hard as rock: pale blue-grey with facets and a few darker cracks.
func _water_ice(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := sin(x * 0.6 + y * 0.8) + 0.6 * cos(x * 1.1 - y * 0.5)
			_px(t, x, y, _vary(P_WATER_LIGHT if facet > 1.0 else (P_WATER_DARK if facet < -1.0 else P_WATER), 0.015))
	for c: Array in [[2, 4, 1, 1, 5], [10, 2, -1, 1, 5], [12, 11, 1, 0, 3]]:
		for k in int(c[4]):
			_px(t, clampi(int(c[0]) + int(c[2]) * k, 0, 15), clampi(int(c[1]) + int(c[3]) * k, 0, 15), P_WATER_DARK.darkened(0.1))


## The uplands' frost from above: peach-tan grains and paler specks.
func _pluto_frost_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var grain := sin(x * 1.2 + y * 0.8) + cos(y * 1.1 - x * 0.6)
			_px(t, x, y, _vary(P_FROST_LIGHT if grain > 1.3 else (P_FROST_DARK if grain < -1.3 else P_FROST), 0.02))
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), P_FROST_LIGHT)


## Its side: a crust of frost over pale water ice.
func _pluto_frost_side(t: Vector2i) -> void:
	_water_ice(t)
	for x in TILE:
		var crust := 3 + int(absf(sin(x * 0.7 + 0.4)) * 2.0)
		for y in crust:
			_px(t, x, y, _vary(P_FROST, 0.02))


## Tholin dust from above: dark red-brown grains with lighter specks.
func _tholin_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var grain := sin(x * 0.9 + y * 1.4) + cos(y * 0.8 - x * 1.2)
			_px(t, x, y, _vary(P_THOLIN_LIGHT if grain > 1.3 else (P_THOLIN_DARK if grain < -1.3 else P_THOLIN), 0.02))
	for i in 5:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), P_THOLIN_LIGHT.lightened(0.1))


## Its side: dark dust in soft layers.
func _tholin_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.5) * 1.5), 5)
			_px(t, x, y, _vary(P_THOLIN_DARK if layer == 0 else P_THOLIN, 0.02))


## Water ice stained red by tholins: reddish facets, a few pale blue cracks.
func _red_ice(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := sin(x * 0.7 + y * 0.6) + 0.5 * cos(x * 1.3 - y * 0.4)
			_px(t, x, y, _vary(P_RED_ICE_DARK if facet < -0.9 else P_RED_ICE, 0.018))
	for c: Array in [[3, 2, 1, 1, 4], [11, 9, -1, 1, 4]]:
		for k in int(c[4]):
			_px(t, clampi(int(c[0]) + int(c[2]) * k, 0, 15), clampi(int(c[1]) + int(c[3]) * k, 0, 15), P_WATER_LIGHT)


## Methane snow from above: bright white with soft blue shades and sparkles.
func _methane_snow_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var drift := sin(x * 0.8 + y * 0.5) + cos(y * 0.9 - x * 0.3)
			_px(t, x, y, _vary(P_SNOW_SHADE if drift < -1.4 else P_SNOW, 0.01))
	for i in 7:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## Its side: a white cap of snow over pale water ice.
func _methane_snow_side(t: Vector2i) -> void:
	_water_ice(t)
	for x in TILE:
		var cap := 4 + int(absf(sin(x * 0.9 + 0.2)) * 3.0)
		for y in cap:
			_px(t, x, y, _vary(P_SNOW, 0.01))


## A frost crystal: pale blue facets with bright edges.
func _frost_crystal(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := posmod(x + y / 3, 4)
			_px(t, x, y, _vary(P_CRYSTAL_LIGHT if facet == 0 else (P_CRYSTAL_DARK if facet == 3 else P_CRYSTAL), 0.012))


## The drag balloon's film: silvery folds with shiny ridges and a gold seam.
func _drag_balloon(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var fold := sin(x * 0.9 + y * 0.35)
			var c := P_BALLOON_SHINE if fold > 0.85 else (P_BALLOON_FOLD if fold < -0.8 else P_BALLOON)
			if y == 7 or y == 8 and x % 4 == 0:
				c = P_BALLOON_SEAM
			_px(t, x, y, _vary(c, 0.01))


## A globe of Charon: a grey ball with craters and its red cap on top, on a dark stand of space.
func _charon_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := P_SPACE
			if d <= 7.2:
				c = P_CAP if y <= 3 else P_CHARON
				for crater: Vector3 in [Vector3(5, 9, 1.6), Vector3(10, 11, 1.2), Vector3(9, 6, 1.1)]:
					if Vector2(x - crater.x, y - crater.y).length() <= crater.z and y > 3:
						c = P_CHARON_DARK
			_px(t, x, y, _vary(c, 0.012))


## Its top: the red cap in a grey ring.
func _charon_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(P_SPACE if d > 7.2 else (P_CAP if d < 4.5 else P_CHARON), 0.012))


## The heart beacon's side: a glowing pink heart on a pale pink pane.
func _heart_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var u := (x - 7.5) / 6.0
			var v := (8.5 - y) / 6.0
			var inside := pow(u * u + v * v - 1.0, 3.0) - u * u * v * v * v <= 0.0
			var c := P_HEART_GLOW
			if inside:
				c = P_HEART_CORE if Vector2(x - 5.5, y - 5.5).length() < 1.5 else P_HEART
			_px(t, x, y, _vary(c, 0.01))


## Its top: a pink glow.
func _heart_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(P_HEART_CORE if d < 3.0 else (P_HEART if d < 6.0 else P_HEART_GLOW), 0.01))


# --- Page 42: Triton (cosmos, spec §21b.2) ----------------------------------------------------------------------------
# Real colours (Voyager 2, 1989): the bright, bluish band of fresh nitrogen frost, the south polar cap's pinkish ices
# (sunlight turns their methane pink) mottled with darker patches, the geysers' dark dust in streaks over them, the
# greyish-green cantaloupe terrain (dimples and ridges), the smooth pale ice lava of the walled plains; Neptune deep blue
# with its dark spot; our own friendly blue beacons and glowing pink-white crystals (spec §3c).

const TR_FROST := Color("eef3fb")           # the band's fresh nitrogen frost
const TR_FROST_DARK := Color("dce5f2")
const TR_FROST_LIGHT := Color("fbfdff")
const TR_PINK := Color("f0c9c6")            # the polar cap's pink ice
const TR_PINK_DARK := Color("e0b0ae")
const TR_PINK_LIGHT := Color("f8dcd8")
const TR_MOTTLE := Color("cf9f9b")          # its darker patches
const TR_DUST := Color("6a5f63")            # a geyser's dark dust
const TR_DUST_DARK := Color("564c50")
const TR_DUST_LIGHT := Color("7d7276")
const TR_HOLE := Color("2b2a33")            # a vent's dark throat ...
const TR_GLINT := Color("cfd8ff")           # ... with a glint of rising frost
const TR_MELON := Color("b3b79a")           # the cantaloupe terrain's ice
const TR_MELON_DARK := Color("9ea283")
const TR_MELON_LIGHT := Color("c9ccb0")
const TR_RIDGE := Color("d2d4bf")           # its paler ridges
const TR_LAVA := Color("c5d0da")            # frozen ice lava
const TR_LAVA_DARK := Color("a9b6c3")
const TR_LAVA_LIGHT := Color("dbe3ea")
const TR_CRYSTAL := Color("fbe7ef")         # glowing nitrogen crystals
const TR_CRYSTAL_DARK := Color("f3cfdc")
const TR_TANK := Color("eef1f5")            # the Hopper Lander's white tank
const TR_TANK_SHADE := Color("d3d9e2")
const TR_TANK_BAND := Color("4a78c8")
const TR_NEPTUNE := Color("3f63e0")         # Neptune's deep blue ...
const TR_NEPTUNE_BAND := Color("5b7ff0")
const TR_NEPTUNE_SPOT := Color("1d2a6e")    # ... its dark spot ...
const TR_NEPTUNE_CLOUD := Color("e6ecff")   # ... and its bright white clouds
const TR_BEACON := Color("8fb8ff")          # the blue beacon
const TR_BEACON_CORE := Color("e0ecff")
const TR_BEACON_RIM := Color("3f6fe0")
const TR_BRICK := Color("f2e1de")           # the explorers' pale pink cap bricks
const TR_MORTAR := Color("d8c2be")


func _triton() -> void:
	_triton_frost_top(Vector2i(0, 0))
	_triton_frost_side(Vector2i(1, 0))
	_pink_top(Vector2i(2, 0))
	_pink_side(Vector2i(3, 0))
	_mottle_top(Vector2i(4, 0))
	_dust_streak_top(Vector2i(5, 0))
	_dust_streak_side(Vector2i(6, 0))
	_geyser_top(Vector2i(7, 0))
	_geyser_side(Vector2i(0, 1))
	_melon_top(Vector2i(1, 1))
	_melon_side(Vector2i(2, 1))
	_melon_ridge(Vector2i(3, 1))
	_ice_lava_top(Vector2i(4, 1))
	_ice_lava_side(Vector2i(5, 1))
	_nitrogen_crystal(Vector2i(6, 1))
	_tank_side(Vector2i(7, 1))
	_tank_top(Vector2i(0, 2))
	_neptune_side(Vector2i(1, 2))
	_neptune_top(Vector2i(2, 2))
	_blue_beacon_side(Vector2i(3, 2))
	_blue_beacon_top(Vector2i(4, 2))
	_bricks(Vector2i(5, 2), TR_BRICK, TR_MORTAR)
	_pink_side(Vector2i(6, 2))   # a fake pink ice: the ice with a hairline door
	for y in range(3, 16):
		_px(Vector2i(6, 2), 3, y, TR_PINK_DARK.darkened(0.14))
		_px(Vector2i(6, 2), 12, y, TR_PINK_DARK.darkened(0.14))


## The band's fresh nitrogen frost from above: bright, faintly bluish grains with white sparkles.
func _triton_frost_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var grain := sin(x * 1.1 + y * 0.7) + cos(y * 1.3 - x * 0.5)
			_px(t, x, y, _vary(TR_FROST_DARK if grain < -1.3 else (TR_FROST_LIGHT if grain > 1.3 else TR_FROST), 0.01))
	for i in 8:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## Its side: a crust of frost over creamy nitrogen ice (Pluto's: Triton's crust is frozen nitrogen).
func _triton_frost_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.4) * 1.5), 6)
			_px(t, x, y, _vary(P_N2_DARK if layer == 0 else P_N2, 0.012))
	for x in TILE:
		var crust := 3 + int(absf(sin(x * 0.8 + 0.3)) * 2.0)
		for y in crust:
			_px(t, x, y, _vary(TR_FROST, 0.01))


## The polar cap's pink ice from above: soft pink with paler swirls.
func _pink_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var swirl := sin(x * 0.5 + sin(y * 0.55) * 1.3) + 0.5 * cos(y * 0.4 - x * 0.25)
			_px(t, x, y, _vary(TR_PINK_LIGHT if swirl > 1.0 else (TR_PINK_DARK if swirl < -1.1 else TR_PINK), 0.012))


## Its side: pink ice in faint layers.
func _pink_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.45) * 1.4), 5)
			_px(t, x, y, _vary(TR_PINK_DARK if layer == 0 else TR_PINK, 0.012))


## The cap's mottled patches: pink ice with irregular darker blotches.
func _mottle_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var blot := sin(x * 0.7 + y * 0.3) + sin(y * 0.8 - x * 0.45) + 0.5 * cos(x * 1.4 + y * 1.1)
			_px(t, x, y, _vary(TR_MOTTLE if blot > -0.3 else TR_PINK_DARK, 0.015))


## Geyser dust from above: dark grey-brown powder with lighter specks, streaked the way the wind blew it.
func _dust_streak_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var streak := sin((x - y) * 0.55) + 0.4 * sin(x * 1.6 + y * 0.2)
			_px(t, x, y, _vary(TR_DUST_LIGHT if streak > 1.0 else (TR_DUST_DARK if streak < -0.9 else TR_DUST), 0.02))
	for i in 5:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), TR_DUST_LIGHT.lightened(0.15))


## Its side: a thin skin of dark dust over pink ice.
func _dust_streak_side(t: Vector2i) -> void:
	_pink_side(t)
	for x in TILE:
		var skin := 2 + int(absf(sin(x * 0.9 + 0.5)) * 2.0)
		for y in skin:
			_px(t, x, y, _vary(TR_DUST, 0.02))


## A geyser's vent from above: a dark throat in a ring of dust, a glint of rising frost in its middle.
func _geyser_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := TR_HOLE if d < 5.0 else (TR_DUST_DARK if d < 6.5 else TR_DUST)
			if d < 1.6:
				c = TR_GLINT
			_px(t, x, y, _vary(c, 0.015))


## Its side: dark dust over pink ice, a dark throat going down the middle.
func _geyser_side(t: Vector2i) -> void:
	_dust_streak_side(t)
	for y in range(2, TILE):
		for x in range(6, 10):
			_px(t, x, y, _vary(TR_HOLE if x > 6 and x < 9 else TR_DUST_DARK, 0.015))


## The cantaloupe terrain from above: greyish-green ice in little round dimples with pale rims, like a melon's rind.
func _melon_top(t: Vector2i) -> void:
	var dimples: Array[Vector3] = [Vector3(4, 4, 3.2), Vector3(12, 3, 2.8), Vector3(8, 10, 3.5), Vector3(2, 12, 2.6),
		Vector3(14, 12, 2.6)]
	for y in TILE:
		for x in TILE:
			var c := TR_MELON
			for dm in dimples:
				var d := Vector2(x - dm.x, y - dm.y).length()
				if d < dm.z - 0.8:
					c = TR_MELON_DARK
				elif d < dm.z + 0.4:
					c = TR_MELON_LIGHT
			_px(t, x, y, _vary(c, 0.015))


## Its side: greyish-green ice in soft layers.
func _melon_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.5) * 1.2), 5)
			_px(t, x, y, _vary(TR_MELON_DARK if layer == 0 else TR_MELON, 0.015))


## A ridge between the dimples: pale ice with two raised seams (a double ridge).
func _melon_ridge(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var seam := x == 4 or x == 11
			_px(t, x, y, _vary(TR_MELON_LIGHT.lightened(0.12) if seam else TR_RIDGE, 0.012))


## Frozen ice lava from above: smooth pale blue-grey with faint flow lines.
func _ice_lava_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var flow := sin(y * 0.6 + sin(x * 0.3) * 2.0)
			_px(t, x, y, _vary(TR_LAVA_LIGHT if flow > 0.92 else TR_LAVA, 0.01))


## Its side: the layers of lava that flowed and froze one on another.
func _ice_lava_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.35) * 1.2), 4)
			_px(t, x, y, _vary(TR_LAVA_DARK if layer == 0 else TR_LAVA, 0.012))


## A nitrogen crystal: pale pink-white facets with bright edges.
func _nitrogen_crystal(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := posmod(x / 2 + y, 5)
			_px(t, x, y, _vary(Color.WHITE if facet == 0 else (TR_CRYSTAL_DARK if facet == 4 else TR_CRYSTAL), 0.01))


## The Hopper Lander's tank from the side: white, shaded round its edges, a blue band and a little gauge.
func _tank_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := TR_TANK_SHADE if x <= 1 or x >= 14 else TR_TANK
			if y == 7 or y == 8:
				c = TR_TANK_BAND
			_px(t, x, y, _vary(c, 0.01))
	for y in range(11, 14):
		for x in range(9, 12):
			_px(t, x, y, Color("2f3440") if y == 12 and x == 10 else Color("f5c542"))


## Its top: a white dome with a blue valve in the middle.
func _tank_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(TR_TANK_BAND if d < 1.8 else (TR_TANK if d < 6.0 else TR_TANK_SHADE), 0.01))


## A globe of Neptune: a deep blue ball with paler bands, its dark spot and white clouds, on a dark stand of space.
func _neptune_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := P_SPACE
			if d <= 7.2:
				c = TR_NEPTUNE_BAND if posmod(y, 5) == 1 else TR_NEPTUNE
				if Vector2((x - 9.0) / 2.6, (y - 9.0) / 1.5).length() < 1.0:
					c = TR_NEPTUNE_SPOT
				if y == 11 and x >= 7 and x <= 11:
					c = TR_NEPTUNE_CLOUD
			_px(t, x, y, _vary(c, 0.01))


## Its top: deep blue in a ring of paler blue.
func _neptune_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(P_SPACE if d > 7.2 else (TR_NEPTUNE if d < 5.0 else TR_NEPTUNE_BAND), 0.01))


## The blue beacon's side: a glowing blue lamp in a darker blue frame.
func _blue_beacon_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(TR_BEACON_RIM if edge else (TR_BEACON_CORE if d < 3.0 else TR_BEACON), 0.01))


## Its top: a blue glow.
func _blue_beacon_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(TR_BEACON_CORE if d < 3.0 else (TR_BEACON if d < 6.5 else TR_BEACON_RIM), 0.01))


# --- Page 43: Ganymede (cosmos, spec §21b.2) --------------------------------------------------------------------------
# Real colours (spacecraft pictures, 1979-2021): the bright grooved terrain's pale, slightly bluish ice with darker
# blue-grey groove floors, the old dark terrain's brownish-grey ice mixed with dust, a young crater's brilliant fresh ice,
# the poles' white frost with a violet tint; Jupiter's cream zones, brown belts and Great Red Spot; our own friendly
# aurora lamps and glowing red and green aurora crystals (Ganymede's auroras glow red and green from oxygen: spec §3c).

const GA_GROOVED := Color("cfd2d8")         # the bright terrain's pale ice (grey enough that fresh rays and frost show)
const GA_GROOVED_DARK := Color("bec2c9")
const GA_GROOVED_LIGHT := Color("dde0e5")
const GA_TROUGH := Color("aab1bc")          # the grooves' blue-grey floors
const GA_TROUGH_DARK := Color("99a1ad")
const GA_DARK := Color("6f6559")            # the old dark terrain
const GA_DARK_DARK := Color("5d544a")
const GA_DARK_LIGHT := Color("82786b")
const GA_OLD := Color("948a7e")             # old, dusty ice
const GA_OLD_DARK := Color("82786d")
const GA_RAY := Color("f7f9fc")             # a young crater's fresh ice
const GA_RAY_GLINT := Color("ffffff")
const GA_RAY_BLUE := Color("e6edf6")
const GA_FROST := Color("eeebf8")           # the poles' frost, a violet tint
const GA_FROST_DARK := Color("ddd7ef")
const GA_AURORA_GREEN := Color("8affb8")    # an aurora crystal's green ...
const GA_AURORA_PINK := Color("ff9ccc")     # ... and red-pink
const GA_AURORA_CORE := Color("f2fff6")
const GA_ZONE := Color("efe2c4")            # Jupiter's cream zones ...
const GA_BELT := Color("b0714a")            # ... its brown belts ...
const GA_RED_SPOT := Color("d4573a")        # ... and its Great Red Spot
const GA_LAMP := Color("6df2a2")            # the aurora lamp
const GA_LAMP_CORE := Color("e6fff0")
const GA_LAMP_RIM := Color("2f9e6a")
const GA_SENSOR := Color("eef1f5")          # the magnetometer's white box ...
const GA_SENSOR_SHADE := Color("cfd5de")
const GA_COPPER := Color("c87533")          # ... and its copper coil
const GA_BRICK := Color("e6e3dc")           # the explorers' pale groove bricks
const GA_MORTAR := Color("c8c3b8")


func _ganymede() -> void:
	_grooved_top(Vector2i(0, 0))
	_grooved_side(Vector2i(1, 0))
	_trough_top(Vector2i(2, 0))
	_dark_ice_top(Vector2i(3, 0))
	_dark_ice_side(Vector2i(4, 0))
	_old_ice(Vector2i(5, 0))
	_ray_ice_top(Vector2i(6, 0))
	_ray_ice_side(Vector2i(7, 0))
	_polar_frost_top(Vector2i(0, 1))
	_polar_frost_side(Vector2i(1, 1))
	_aurora_crystal(Vector2i(2, 1))
	_jupiter_side(Vector2i(3, 1))
	_jupiter_top(Vector2i(4, 1))
	_aurora_lamp_side(Vector2i(5, 1))
	_aurora_lamp_top(Vector2i(6, 1))
	_magnetometer_side(Vector2i(7, 1))
	_magnetometer_top(Vector2i(0, 2))
	_bricks(Vector2i(1, 2), GA_BRICK, GA_MORTAR)
	_grooved_side(Vector2i(2, 2))   # a fake grooved ice: the ice with a hairline door
	for y in range(3, 16):
		_px(Vector2i(2, 2), 3, y, GA_GROOVED_DARK.darkened(0.16))
		_px(Vector2i(2, 2), 12, y, GA_GROOVED_DARK.darkened(0.16))


## The grooved terrain's pale ice from above: long fine parallel grooves (a bright ridge's crest across the tile).
func _grooved_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var g := posmod(x + y / 6, 5)
			var c := GA_GROOVED_LIGHT if g == 0 else (GA_GROOVED_DARK if g == 3 else GA_GROOVED)
			_px(t, x, y, _vary(c, 0.012))


## Its side: pale ice in faint layers (the crust).
func _grooved_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.4) * 1.3), 5)
			_px(t, x, y, _vary(GA_GROOVED_DARK if layer == 0 else GA_GROOVED, 0.012))


## A groove's floor from above: blue-grey ice with soft grains, a fainter groove line.
func _trough_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var g := posmod(x + y / 6, 5)
			_px(t, x, y, _vary(GA_TROUGH_DARK if g == 2 else GA_TROUGH, 0.015))


## The dark terrain from above: brownish-grey ice mixed with dust, darker and lighter specks.
func _dark_ice_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var n := sin(x * 0.9 + y * 0.4) + cos(y * 1.1 - x * 0.6)
			_px(t, x, y, _vary(GA_DARK_DARK if n < -1.1 else (GA_DARK_LIGHT if n > 1.2 else GA_DARK), 0.02))
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), GA_GROOVED_DARK)


## Its side: a dark skin over old, dusty ice.
func _dark_ice_side(t: Vector2i) -> void:
	_old_ice(t)
	for x in TILE:
		var skin := 3 + int(absf(sin(x * 0.7 + 0.4)) * 2.0)
		for y in skin:
			_px(t, x, y, _vary(GA_DARK, 0.02))


## Old, dusty ice: grey-brown, in faint layers.
func _old_ice(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var layer := posmod(y + int(sin(x * 0.5) * 1.2), 4)
			_px(t, x, y, _vary(GA_OLD_DARK if layer == 0 else GA_OLD, 0.018))


## A young crater's fresh ice from above: brilliant white with glints.
func _ray_ice_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var n := sin(x * 1.3 + y * 0.8) + cos(y * 1.2 - x * 0.7)
			_px(t, x, y, _vary(GA_RAY_BLUE if n < -1.3 else GA_RAY, 0.008))
	for i in 10:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), GA_RAY_GLINT)


## Its side: fresh ice over the pale crust.
func _ray_ice_side(t: Vector2i) -> void:
	_grooved_side(t)
	for x in TILE:
		var skin := 3 + int(absf(sin(x * 0.8)) * 2.0)
		for y in skin:
			_px(t, x, y, _vary(GA_RAY, 0.008))


## The poles' frost from above: white with a violet tint, soft drifts.
func _polar_frost_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var drift := sin(x * 0.6 + sin(y * 0.5) * 1.4)
			_px(t, x, y, _vary(GA_FROST_DARK if drift < -0.85 else GA_FROST, 0.01))
	for i in 6:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), Color.WHITE)


## Its side: a skin of frost over the pale crust.
func _polar_frost_side(t: Vector2i) -> void:
	_grooved_side(t)
	for x in TILE:
		var skin := 3 + int(absf(sin(x * 0.6 + 0.2)) * 2.0)
		for y in skin:
			_px(t, x, y, _vary(GA_FROST, 0.01))


## An aurora crystal: facets glowing green low down and red-pink higher up (an aurora's colours), bright edges.
func _aurora_crystal(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var facet := posmod(x / 2 + y, 5)
			var c := GA_AURORA_GREEN.lerp(GA_AURORA_PINK, smoothstep(11.0, 3.0, float(y)))
			if facet == 0:
				c = GA_AURORA_CORE
			elif facet == 4:
				c = c.darkened(0.08)
			_px(t, x, y, _vary(c, 0.01))


## A globe of Jupiter: cream zones and brown belts, its Great Red Spot, on a dark stand of space.
func _jupiter_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := P_SPACE
			if d <= 7.2:
				c = GA_BELT if posmod(y, 4) == 1 or posmod(y, 4) == 2 and y > 8 else GA_ZONE
				if Vector2((x - 10.0) / 2.2, (y - 10.0) / 1.3).length() < 1.0:
					c = GA_RED_SPOT
			_px(t, x, y, _vary(c, 0.01))


## Its top: cream in a ring of brown.
func _jupiter_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(P_SPACE if d > 7.2 else (GA_ZONE if d < 4.5 else GA_BELT), 0.01))


## The aurora lamp's side: a glowing green lamp in a darker green frame.
func _aurora_lamp_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x <= 1 or x >= 14 or y <= 1 or y >= 14
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(GA_LAMP_RIM if edge else (GA_LAMP_CORE if d < 3.0 else GA_LAMP), 0.01))


## Its top: a green glow.
func _aurora_lamp_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(GA_LAMP_CORE if d < 3.0 else (GA_LAMP if d < 6.5 else GA_LAMP_RIM), 0.01))


## The magnetometer from the side: a white sensor box, shaded at its edges, a copper coil wound round its middle.
func _magnetometer_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := GA_SENSOR_SHADE if x <= 1 or x >= 14 or y <= 1 or y >= 14 else GA_SENSOR
			if y >= 5 and y <= 10 and x >= 3 and x <= 12:
				c = GA_COPPER if posmod(y, 2) == 0 else GA_COPPER.lightened(0.25)
			_px(t, x, y, _vary(c, 0.01))


## Its top: a white lid with a copper ring.
func _magnetometer_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, _vary(GA_COPPER if d > 3.5 and d < 5.0 else (GA_SENSOR if d < 7.0 else GA_SENSOR_SHADE), 0.01))
