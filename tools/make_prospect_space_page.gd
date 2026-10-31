extends SceneTree
## Generates the riches of space's pixel block page (spec §26.5, owner #80): data/blocks/pages/prospect_space.png, page
## 39 (data/blocks/prospect_space_page.gd TILES), an 8 x 8 grid of 16 x 16 tiles in the style of
## tools/make_prospect_page.gd (original work, its own RNG seed). What a child learns to read, drawn plainly: the Moon's
## icy regolith (grey dust with white frost glints), mare dust (the dark seas' bluish-grey dust), ilmenite (black glossy
## crystals), KREEP rock (pale rock with brown and dark specks), an iron meteorite (a shiny cut face with crossing lines,
## a dark crust with "thumbprints"); Mars's ground ice (white ice with red dust), blueberry soil (red dust strewn with
## grey spheres), hematite (layered rock full of spheres), dark sand, the pale salt crust; then what is made: an oxygen
## tank (white, a teal band), hydrogen fuel (a frosty pale-blue tank, an orange band), titanium bars, a tray of rare
## earths' pastel powders, a silver flask of helium-3 (a "3" on it) and the Solar Oven (a dish of mirrors, a warm window:
## never fire, never scary). Its realistic twin is tools/make_prospect_space_realistic.py (the same layout).
## Run: godot --headless --path . --script res://tools/make_prospect_space_page.gd   (then godot --headless --path . --import)

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/prospect_space.png"
const SEED := 20260939

const MOON_GREY := Color("8e929c")
const MOON_DARK := Color("6c7079")
const MOON_LIGHT := Color("b4b8c0")
const FROST := Color("eef6ff")
const FROST_BLUE := Color("cfe4f7")
const MARE := Color("4a4f5c")
const MARE_DARK := Color("3a3e49")
const MARE_LIGHT := Color("5d6372")
const ILMENITE := Color("1c1d22")
const ILMENITE_SHINE := Color("6b6f7e")
const BASALT := Color("3c3f46")
const KREEP := Color("b9ad98")
const KREEP_DARK := Color("8e8272")
const KREEP_BROWN := Color("9a6a44")
const KREEP_SPECK := Color("3e3a36")
const METAL := Color("a9adb4")
const METAL_LIGHT := Color("d7dade")
const METAL_DARK := Color("7d828b")
const CRUST := Color("3a2f2a")
const CRUST_LIGHT := Color("5a4a40")
const CRUST_DARK := Color("241d1a")
const MARS_DUST := Color("c46a3c")
const MARS_DUST_LIGHT := Color("d98a58")
const MARS_DUST_DARK := Color("9c4f2c")
const MARS_ICE := Color("f2f5f8")
const MARS_ICE_SHADE := Color("d9e3ec")
const BERRY := Color("5b5f6b")
const BERRY_LIGHT := Color("8b90a0")
const BERRY_DARK := Color("3e414a")
const HEMATITE_ROCK := Color("a86a52")
const HEMATITE_LAYER := Color("8e5644")
const HEMATITE_PALE := Color("c8977e")
const DARK_SAND := Color("2c2a2c")
const DARK_SAND_LIGHT := Color("454247")
const DARK_SAND_GLINT := Color("8a8a96")
const SALT := Color("f0e6e2")
const SALT_PINK := Color("e5cfc8")
const SALT_CRACK := Color("c9aea4")
const TANK_WHITE := Color("eef1f4")
const TANK_SHADE := Color("c9cfd6")
const TEAL := Color("139e9b")            # the brand's teal (spec §3c)
const TEAL_DARK := Color("0c7876")
const H_BLUE := Color("bfe0f5")
const H_BLUE_LIGHT := Color("e3f3fc")
const H_BLUE_DARK := Color("8fbfe0")
const ORANGE := Color("f08a1c")
const TITANIUM := Color("9ea3ab")
const TITANIUM_LIGHT := Color("c8ccd3")
const TITANIUM_DARK := Color("6e737c")
const TRAY := Color("dfe3e8")
const TRAY_EDGE := Color("a9b0b9")
const POWDERS: Array[Color] = [Color("c9b6e4"), Color("f2c5d0"), Color("cfe7c4"), Color("f4e3a6"), Color("a9c8ec"),
	Color("e7e2da")]
const FLASK := Color("c3c8cf")
const FLASK_LIGHT := Color("e6e9ed")
const FLASK_DARK := Color("8d939c")
const MIRROR := Color("dfe9f2")
const MIRROR_DARK := Color("9fb3c4")
const MIRROR_BRIGHT := Color("ffffff")
const OVEN_WHITE := Color("eceff2")
const OVEN_FRAME := Color("aeb6bf")
const GLOW := Color("ffb347")
const GLOW_LIGHT := Color("ffe29a")
const STEEL_DARK := Color("7d8793")
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	_icy_regolith()
	_mare_dust()
	_ilmenite()
	_kreep()
	_meteorite()
	_ground_ice()
	_blueberry_soil()
	_hematite()
	_dark_sand()
	_mars_salt()
	_tank(Vector2i(3, 2), Vector2i(2, 2), TANK_WHITE, TANK_SHADE, TEAL)
	_tank(Vector2i(5, 2), Vector2i(4, 2), H_BLUE, H_BLUE_DARK, ORANGE)
	_frost_on(Vector2i(4, 2))
	_titanium()
	_rare_earths()
	_helium_3()
	_solar_oven()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/blocks/pages/"))
	var err := img.save_png(OUT)
	print("PROSPECT_SPACE_PAGE saved err=%d" % err)
	quit()


func _px(t: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE and y < TILE:
		img.set_pixel(t.x * TILE + x, t.y * TILE + y, c)


func _rect(t: Vector2i, x0: int, y0: int, x1: int, y1: int, c: Color, vary := 0.0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(t, x, y, _vary(c, vary))


func _vary(c: Color, amount: float) -> Color:
	if amount <= 0.0:
		return c
	var k := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + k, 0, 1), clampf(c.g + k, 0, 1), clampf(c.b + k, 0, 1), c.a)


## Scattered specks of `c` (each one pixel, sometimes with a lit neighbour).
func _specks(t: Vector2i, n: int, c: Color, light: Color) -> void:
	for i in n:
		var x := rng.randi_range(1, 14)
		var y := rng.randi_range(1, 14)
		_px(t, x, y, c)
		if rng.randf() < 0.5:
			_px(t, x + 1, y, light)


## A round part's side: light in the middle, darker to the edges.
func _round_shade(c: Color, x: int) -> Color:
	var u := (float(x) + 0.5) / 16.0
	var k := 1.0 - 0.3 * pow(absf(u - 0.42) * 2.0, 2.0)
	return Color(c.r * k, c.g * k, c.b * k, c.a)


## A little ball of `c` with a lit top-left pixel.
func _ball(t: Vector2i, cx: int, cy: int, r: int, c: Color, light: Color, dark: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var d := Vector2(x - cx, y - cy).length()
			if d <= r + 0.25:
				_px(t, x, y, dark if (x - cx) + (y - cy) > r * 0.9 else c)
	_px(t, cx - (1 if r > 0 else 0), cy - (1 if r > 0 else 0), light)


# --- Found on the Moon (row 0) ---

## Grey dust in the dark crater's floor, frozen with ice: white frost glints on top, pale veins of ice in the side.
func _icy_regolith() -> void:
	var top := Vector2i(0, 0)
	_rect(top, 0, 0, 15, 15, MOON_DARK, 0.05)
	for i in 30:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), MOON_GREY)
	for i in 26:   # frost
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		_px(top, x, y, FROST)
		if rng.randf() < 0.6:
			_px(top, x + 1, y, FROST_BLUE)
		if rng.randf() < 0.4:
			_px(top, x, y + 1, FROST_BLUE)
	var side := Vector2i(1, 0)
	_rect(side, 0, 0, 15, 15, MOON_DARK, 0.05)
	for y in 16:   # veins of ice between the grains
		for x in 16:
			var w := sin(x * 0.8 + y * 0.35) + 0.7 * sin(y * 1.3 - x * 0.4)
			if w > 1.05:
				_px(side, x, y, _vary(FROST_BLUE, 0.03))
			elif w > 0.8:
				_px(side, x, y, _vary(MOON_LIGHT, 0.03))
	_specks(side, 8, FROST, FROST_BLUE)


## The dark "seas" of the Moon: fine bluish-grey dust, darker than the highlands' dust.
func _mare_dust() -> void:
	var top := Vector2i(2, 0)
	_rect(top, 0, 0, 15, 15, MARE, 0.04)
	for i in 40:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), [MARE_DARK, MARE_LIGHT][rng.randi_range(0, 1)])
	for i in 3:   # a few black ilmenite grains
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), ILMENITE)
	var side := Vector2i(3, 0)
	for y in 16:
		var c := MARE if y % 5 != 4 else MARE_DARK
		for x in 16:
			_px(side, x, y, _vary(c, 0.04))
	_specks(side, 5, ILMENITE, MARE_LIGHT)


## Ilmenite: black, glossy, blade-like crystals packed in dark basalt.
func _ilmenite() -> void:
	var t := Vector2i(4, 0)
	_rect(t, 0, 0, 15, 15, BASALT, 0.04)
	for i in 14:   # the crystals: short dark blades
		var cx := rng.randi_range(0, 13)
		var cy := rng.randi_range(0, 13)
		var horizontal := rng.randf() < 0.5
		var n := rng.randi_range(2, 4)
		for k in n:
			_px(t, cx + (k if horizontal else 0), cy + (0 if horizontal else k), ILMENITE)
		_px(t, cx, cy, ILMENITE_SHINE)   # a glint of metal lustre
	_specks(t, 4, ILMENITE, ILMENITE)


## KREEP rock: a pale, speckled rock (potassium, rare earths, phosphorus), rusty-brown and dark bits in it.
func _kreep() -> void:
	var t := Vector2i(5, 0)
	_rect(t, 0, 0, 15, 15, KREEP, 0.04)
	for i in 10:
		var cx := rng.randi_range(0, 14)
		var cy := rng.randi_range(0, 14)
		_rect(t, cx, cy, cx + 1, cy, KREEP_DARK, 0.03)
	for i in 8:
		var cx := rng.randi_range(1, 13)
		var cy := rng.randi_range(1, 13)
		_rect(t, cx, cy, cx + 1, cy + 1, KREEP_BROWN, 0.04)
	_specks(t, 10, KREEP_SPECK, KREEP_DARK)


## An iron meteorite: a cut, polished face with crossing lines (they only grow as metal cools for millions of years),
## and its dark crust with "thumbprints" melted into it on the way down.
func _meteorite() -> void:
	var top := Vector2i(6, 0)
	_rect(top, 0, 0, 15, 15, METAL, 0.03)
	for y in 16:
		for x in 16:
			if (x + y) % 5 == 0 or (x - y + 32) % 6 == 0:
				_px(top, x, y, _vary(METAL_DARK, 0.02))
			elif (x * 2 + y) % 9 == 0:
				_px(top, x, y, METAL_LIGHT)
	for x in 16:   # the dark rind round the cut face
		_px(top, x, 0, CRUST)
		_px(top, x, 15, CRUST)
		_px(top, 0, x, CRUST)
		_px(top, 15, x, CRUST)
	var side := Vector2i(7, 0)
	_rect(side, 0, 0, 15, 15, CRUST, 0.03)
	for c: Vector2i in [Vector2i(3, 3), Vector2i(10, 4), Vector2i(6, 9), Vector2i(12, 12), Vector2i(2, 12)]:
		for y in range(c.y - 2, c.y + 3):
			for x in range(c.x - 2, c.x + 3):
				var d := Vector2(x - c.x, y - c.y).length()
				if d <= 2.2:   # a shallow pit: dark in, its far rim lit
					_px(side, x, y, CRUST_DARK if d < 1.5 else (CRUST_LIGHT if x + y > c.x + c.y else CRUST))
	_specks(side, 4, METAL_DARK, METAL)


# --- Found on Mars (rows 1-2) ---

## Mars's ground ice: white ice, a little red dust smudged on it; the side shows ice layers with dusty bands.
func _ground_ice() -> void:
	var top := Vector2i(0, 1)
	_rect(top, 0, 0, 15, 15, MARS_ICE, 0.02)
	for i in 10:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), MARS_ICE_SHADE)
	for i in 6:   # red dust blown over it
		var cx := rng.randi_range(0, 14)
		var cy := rng.randi_range(0, 14)
		_px(top, cx, cy, MARS_DUST_LIGHT)
		if rng.randf() < 0.5:
			_px(top, cx + 1, cy, MARS_DUST)
	var side := Vector2i(1, 1)
	for y in 16:
		for x in 16:
			var band := (y + int(sin(x * 0.6) * 0.8)) % 6
			var c := MARS_ICE if band < 4 else (MARS_ICE_SHADE if band == 4 else MARS_DUST_LIGHT)
			_px(side, x, y, _vary(c, 0.025))


## Red dust strewn with little grey balls of hematite, the "blueberries" (they look blue-grey against the red).
func _blueberry_soil() -> void:
	var top := Vector2i(2, 1)
	_rect(top, 0, 0, 15, 15, MARS_DUST, 0.05)
	for i in 14:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), [MARS_DUST_DARK, MARS_DUST_LIGHT][rng.randi_range(0, 1)])
	for b: Vector2i in [Vector2i(2, 2), Vector2i(7, 1), Vector2i(12, 3), Vector2i(4, 7), Vector2i(10, 8), Vector2i(1, 12),
			Vector2i(6, 12), Vector2i(13, 13), Vector2i(8, 5)]:
		_ball(top, b.x, b.y, 1, BERRY, BERRY_LIGHT, BERRY_DARK)
	var side := Vector2i(3, 1)
	_rect(side, 0, 0, 15, 15, MARS_DUST_DARK, 0.05)
	for x in 16:
		_px(side, x, 0, MARS_DUST)
		_px(side, x, 1, _vary(MARS_DUST, 0.03))
	for b: Vector2i in [Vector2i(3, 5), Vector2i(11, 7), Vector2i(6, 12), Vector2i(13, 13)]:
		_ball(side, b.x, b.y, 1, BERRY, BERRY_LIGHT, BERRY_DARK)


## Hematite rock: layered, pale-red rock with grey spheres of hematite grown inside it by water long ago.
func _hematite() -> void:
	var side := Vector2i(4, 1)
	for y in 16:
		for x in 16:
			var k := (y + int(sin(x * 0.4) * 1.0)) % 4
			var c := HEMATITE_ROCK if k < 2 else (HEMATITE_LAYER if k == 2 else HEMATITE_PALE)
			_px(side, x, y, _vary(c, 0.03))
	for b: Vector2i in [Vector2i(3, 3), Vector2i(10, 2), Vector2i(7, 8), Vector2i(2, 12), Vector2i(12, 11)]:
		_ball(side, b.x, b.y, 1, BERRY, BERRY_LIGHT, BERRY_DARK)
	var top := Vector2i(5, 1)
	_rect(top, 0, 0, 15, 15, HEMATITE_ROCK, 0.04)
	for b: Vector2i in [Vector2i(2, 3), Vector2i(8, 2), Vector2i(13, 5), Vector2i(5, 8), Vector2i(11, 11), Vector2i(3, 13),
			Vector2i(9, 14)]:
		_ball(top, b.x, b.y, 1, BERRY, BERRY_LIGHT, BERRY_DARK)


## Dark sand of Mars's dunes: nearly black, iron-rich grains with a few glints.
func _dark_sand() -> void:
	var top := Vector2i(6, 1)
	for y in 16:
		for x in 16:
			var ripple := int(y + sin(x * 0.5) * 1.5) % 5 == 0
			_px(top, x, y, _vary(DARK_SAND_LIGHT if ripple else DARK_SAND, 0.03))
	_specks(top, 7, DARK_SAND_GLINT, DARK_SAND_LIGHT)
	var side := Vector2i(7, 1)
	_rect(side, 0, 0, 15, 15, DARK_SAND, 0.04)
	_specks(side, 6, DARK_SAND_GLINT, DARK_SAND_LIGHT)
	for x in 16:
		_px(side, x, 15, _vary(MARS_DUST_DARK, 0.03))


## Mars salt: a pale crust with cracks where an old lake dried; its side shows the salt over the red ground.
func _mars_salt() -> void:
	var top := Vector2i(0, 2)
	_rect(top, 0, 0, 15, 15, SALT, 0.015)
	for p: Array in [[0, 4, 5, 6], [5, 6, 10, 3], [10, 3, 15, 5], [5, 6, 6, 11], [6, 11, 0, 13], [6, 11, 12, 12],
			[10, 3, 12, 12], [12, 12, 15, 14]]:
		var a := Vector2(p[0], p[1])
		var b := Vector2(p[2], p[3])
		for i in 17:
			var q := a.lerp(b, i / 16.0)
			_px(top, int(q.x), int(q.y), SALT_CRACK)
	var side := Vector2i(1, 2)
	for y in 16:
		for x in 16:
			var c := SALT if y < 5 else (SALT_PINK if y < 9 else MARS_DUST_DARK)
			if y == 5 and (x % 4 == 0):
				c = SALT_CRACK
			_px(side, x, y, _vary(c, 0.025))


# --- What is made (rows 2-3) ---

## A gas tank: a round white (or frosty blue) body with a coloured band, and its lid with a valve.
func _tank(top: Vector2i, side: Vector2i, body: Color, shade: Color, band: Color) -> void:
	for y in 16:
		for x in 16:
			var c := _round_shade(body, x)
			if y <= 1 or y >= 14:
				c = _round_shade(shade, x)
			elif y >= 6 and y <= 8:
				c = _round_shade(band, x)
			_px(side, x, y, _vary(c, 0.012))
	_rect(top, 0, 0, 15, 15, shade, 0.015)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.2:
				_px(top, x, y, _vary(shade if d > 6.2 else body, 0.015))
	_rect(top, 6, 6, 9, 9, STEEL_DARK)   # the valve
	_rect(top, 7, 7, 8, 8, band)


## Frost on a cold tank of liquid hydrogen (it is colder than -250 °C).
func _frost_on(side: Vector2i) -> void:
	for i in 18:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(9, 15)
		_px(side, x, y, H_BLUE_LIGHT)


## Titanium: silvery grey bars (strong and light), stacked.
func _titanium() -> void:
	var top := Vector2i(6, 2)
	for y in 16:
		for x in 16:
			var bar := y % 4
			var c := TITANIUM_LIGHT if bar == 0 else (TITANIUM_DARK if bar == 3 else TITANIUM)
			_px(top, x, y, _vary(c, 0.02))
	var side := Vector2i(7, 2)
	for y in 16:
		for x in 16:
			var row := y / 4
			var off := 4 if row % 2 else 0
			var bx := (x + off) % 8
			var c := TITANIUM
			if y % 4 == 0 or bx == 0:
				c = TITANIUM_DARK
			elif y % 4 == 1:
				c = TITANIUM_LIGHT
			_px(side, x, y, _vary(c, 0.015))


## Rare earths: a tray of pastel powders (their oxides really are white, pink, lilac, pale green, pale yellow).
func _rare_earths() -> void:
	var top := Vector2i(0, 3)
	_rect(top, 0, 0, 15, 15, TRAY_EDGE)
	for i in 6:
		var cx := 1 + (i % 3) * 5
		var cy := 1 + (i / 3) * 7
		var c := POWDERS[i]
		_rect(top, cx, cy, cx + 3, cy + 5, c, 0.02)
		_px(top, cx + 1, cy + 1, c.lightened(0.3))
	var side := Vector2i(1, 3)
	_rect(side, 0, 0, 15, 15, TRAY, 0.015)
	for y in [0, 15]:
		for x in 16:
			_px(side, x, y, TRAY_EDGE)
	for i in 3:   # jars of powder in the crate's window
		var x0 := 1 + i * 5
		_rect(side, x0, 4, x0 + 3, 12, Color("f4f7fa"))
		_rect(side, x0, 7, x0 + 3, 12, POWDERS[i * 2], 0.02)
		_rect(side, x0, 3, x0 + 3, 3, STEEL_DARK)


## Helium-3: a silver flask with a teal band and a "3" on it; its top a round cap.
func _helium_3() -> void:
	var side := Vector2i(2, 3)
	for y in 16:
		for x in 16:
			var c := _round_shade(FLASK, x)
			if y <= 1:
				c = _round_shade(FLASK_DARK, x)
			elif y >= 3 and y <= 4:
				c = _round_shade(TEAL, x)
			elif x == 6:
				c = FLASK_LIGHT
			_px(side, x, y, _vary(c, 0.01))
	for p: Vector2i in [Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 8), Vector2i(7, 9), Vector2i(8, 9),
			Vector2i(9, 10), Vector2i(6, 11), Vector2i(7, 11), Vector2i(8, 11)]:   # a "3"
		_px(side, p.x, p.y, TEAL_DARK)
	var top := Vector2i(3, 3)
	_rect(top, 0, 0, 15, 15, FLASK_DARK, 0.015)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.2:
				_px(top, x, y, _vary(FLASK if d > 3.0 else FLASK_LIGHT, 0.015))
	_rect(top, 7, 7, 8, 8, TEAL)


## The Solar Oven: a dish of mirrors on top (sunlight to one bright spot), a white box with a warm window, a grey base.
func _solar_oven() -> void:
	var top := Vector2i(4, 3)
	_rect(top, 0, 0, 15, 15, OVEN_FRAME)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.4:
				var seg := int((atan2(y - 7.5, x - 7.5) + PI) / TAU * 8.0) % 2
				_px(top, x, y, _vary(MIRROR if seg == 0 else MIRROR_DARK, 0.02))
			if d < 1.6:
				_px(top, x, y, MIRROR_BRIGHT)
	var side := Vector2i(5, 3)
	_rect(side, 0, 0, 15, 15, OVEN_WHITE, 0.015)
	for i in 16:
		_px(side, i, 0, OVEN_FRAME)
		_px(side, i, 15, OVEN_FRAME)
		_px(side, 0, i, OVEN_FRAME)
		_px(side, 15, i, OVEN_FRAME)
	_rect(side, 3, 5, 12, 11, STEEL_DARK)   # the window's frame
	_rect(side, 4, 6, 11, 10, GLOW)          # warm light inside: sunlight, never fire
	_rect(side, 5, 7, 7, 8, GLOW_LIGHT)
	_rect(side, 5, 13, 10, 13, TEAL)         # the brand's teal plate
	var bottom := Vector2i(6, 3)
	_rect(bottom, 0, 0, 15, 15, STEEL_DARK, 0.03)
	for b: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		_px(bottom, b.x, b.y, CRUST_DARK)
