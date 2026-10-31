extends SceneTree
## Generates prospecting's pixel block page (spec §26, owner #80): data/blocks/pages/prospect.png, page 35
## (data/blocks/prospect_page.gd TILES), an 8 x 8 grid of 16 x 16 tiles in the style of tools/make_rocket_page.gd
## (original work, its own RNG seed). What a child learns to read, drawn plainly: white quartz with gold specks, river
## gravel with gold flakes, grey copper ore with brassy specks, green malachite, banded iron's red and silver stripes,
## rusty rock, grey shale with a fern print, a black oil seep, pink-white rock salt, a white salt crust with cracks; then
## what refining makes: copper bars, a sack of table salt, drums of crude oil (black) and kerosene (blue), plastic pellets
## and the Refinery (a clean silver tower with blue valves: no fire, never scary).
## Its realistic twin is tools/make_prospect_realistic.py (the same layout).
## Run: godot --headless --path . --script res://tools/make_prospect_page.gd   (then godot --headless --path . --import)

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/prospect.png"
const SEED := 20260935

const QUARTZ := Color("ece9e1")
const QUARTZ_SHADE := Color("cfcac0")
const GOLD := Color("f5c542")
const GOLD_LIGHT := Color("ffe98a")
const GOLD_DARK := Color("c9922a")
const ROCK := Color("8a8c8e")
const ROCK_DARK := Color("6a6c70")
const ROCK_LIGHT := Color("a7a9ab")
const BRASS := Color("d4a93c")
const GREEN := Color("2f9a5c")
const GREEN_LIGHT := Color("5fcf8a")
const GREEN_DARK := Color("1d6b40")
const IRON_RED := Color("a63a28")
const IRON_RED_DARK := Color("7a2a1e")
const IRON_SILVER := Color("8d9098")
const IRON_BLACK := Color("3b3c44")
const RUST := Color("b95a2c")
const RUST_LIGHT := Color("d77a3c")
const RUST_DARK := Color("86401f")
const SHALE := Color("5f6368")
const SHALE_LIGHT := Color("767a80")
const SHALE_DARK := Color("4a4d52")
const FERN := Color("3b3e42")
const OIL := Color("1c1714")
const OIL_BROWN := Color("2e231c")
const OIL_SHINE := Color("6b5a4a")
const SAND := Color("dcc48e")
const SAND_DARK := Color("b9a06c")
const SALT := Color("f4ecec")
const SALT_PINK := Color("e6cccc")
const SALT_EDGE := Color("cdb3b3")
const CRUST := Color("f7f6f2")
const CRUST_CRACK := Color("d9d3c8")
const COPPER := Color("d9803a")
const COPPER_LIGHT := Color("f4a867")
const COPPER_DARK := Color("a65a26")
const SACK := Color("f1ede4")
const SACK_SHADE := Color("d6d0c2")
const LABEL_BLUE := Color("2f6fd0")
const DRUM_BLACK := Color("2a2b30")
const DRUM_BLACK_LIGHT := Color("45474e")
const DRUM_BAND := Color("7a4a24")
const KERO := Color("2f6fd0")
const KERO_LIGHT := Color("5a93ea")
const KERO_DARK := Color("1f4f9e")
const WHITE := Color("f4f6f8")
const STEEL := Color("b9c2cc")
const STEEL_LIGHT := Color("dfe5ec")
const STEEL_DARK := Color("7d8793")
const VALVE := Color("2a7fd4")
const TEAL := Color("139e9b")            # the brand's teal (spec §3c)
const PELLET_COLORS: Array[Color] = [Color("139e9b"), Color("f4f6f8"), Color("ffd23f"), Color("e0413a"), Color("5aa9f0")]
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	_gold_quartz()
	_gold_gravel()
	_copper_ore()
	_malachite()
	_banded_iron()
	_rusty_rock()
	_fern_shale()
	_oil_seep()
	_rock_salt()
	_salt_crust()
	_copper()
	_table_salt()
	_drum(Vector2i(6, 2), Vector2i(7, 2), DRUM_BLACK, DRUM_BLACK_LIGHT, DRUM_BAND)
	_drum(Vector2i(0, 3), Vector2i(1, 3), KERO, KERO_LIGHT, WHITE)
	_plastic()
	_refinery()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/blocks/pages/"))
	var err := img.save_png(OUT)
	print("PROSPECT_PAGE saved err=%d" % err)
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


# --- Found in the ground (rows 0-2) ---

func _gold_quartz() -> void:
	for t: Vector2i in [Vector2i(0, 0), Vector2i(1, 0)]:
		_rect(t, 0, 0, 15, 15, QUARTZ, 0.04)
		for i in 5:   # milky streaks
			var y := rng.randi_range(0, 15)
			for x in 16:
				if rng.randf() < 0.55:
					_px(t, x, clampi(y + (x / 5), 0, 15), _vary(QUARTZ_SHADE, 0.03))
		for i in 3:   # bits of the grey host rock
			var cx := rng.randi_range(0, 15)
			var cy := rng.randi_range(0, 15)
			_rect(t, cx, cy, mini(cx + 1, 15), mini(cy + 1, 15), ROCK, 0.04)
		_specks(t, 9, GOLD, GOLD_LIGHT)
		_specks(t, 3, GOLD_DARK, GOLD)


func _gold_gravel() -> void:
	for t: Vector2i in [Vector2i(2, 0), Vector2i(3, 0)]:
		_rect(t, 0, 0, 15, 15, SAND_DARK, 0.04)
		for i in 22:   # rounded pebbles
			var cx := rng.randi_range(0, 15)
			var cy := rng.randi_range(0, 15)
			var c: Color = [ROCK, ROCK_LIGHT, ROCK_DARK, Color("9a7a58"), Color("c2ab86")][rng.randi_range(0, 4)]
			var r := rng.randi_range(1, 2)
			for y in range(cy - r, cy + r + 1):
				for x in range(cx - r, cx + r + 1):
					if Vector2(x - cx, y - cy).length() <= r + 0.2:
						_px(t, x, y, _vary(c, 0.04))
		_specks(t, 6 if t.x == 2 else 4, GOLD, GOLD_LIGHT)   # flakes of gold


func _copper_ore() -> void:
	var t := Vector2i(4, 0)
	_rect(t, 0, 0, 15, 15, ROCK, 0.05)
	for i in 6:
		var cx := rng.randi_range(0, 14)
		var cy := rng.randi_range(0, 14)
		_rect(t, cx, cy, cx + 1, cy, ROCK_DARK, 0.03)
	for i in 7:   # brassy chalcopyrite
		var cx := rng.randi_range(1, 13)
		var cy := rng.randi_range(1, 13)
		_rect(t, cx, cy, cx + 1, cy + 1, BRASS, 0.05)
		_px(t, cx, cy, GOLD_LIGHT)
	_specks(t, 3, GREEN, GREEN_LIGHT)


func _malachite() -> void:
	var side := Vector2i(5, 0)
	_rect(side, 0, 0, 15, 15, ROCK, 0.05)
	for y in 16:   # green bands flowing over the rock
		for x in 16:
			var w := sin((x + y * 0.6) * 0.9) + 0.6 * sin(y * 1.7 + x * 0.3)
			if w > -0.1:
				var c := GREEN if w < 0.6 else (GREEN_LIGHT if w > 1.1 else GREEN_DARK)
				_px(side, x, y, _vary(c, 0.03))
	var top := Vector2i(6, 0)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var ring := int(d * 1.3) % 3
			var c := [GREEN_DARK, GREEN, GREEN_LIGHT][ring] as Color
			_px(top, x, y, _vary(c, 0.03))


func _banded_iron() -> void:
	var side := Vector2i(7, 0)
	var band := [IRON_RED, IRON_RED, IRON_SILVER, IRON_BLACK, IRON_RED_DARK, IRON_RED, IRON_SILVER, IRON_SILVER]
	for y in 16:
		for x in 16:
			var k := (y + int(sin(x * 0.5) * 1.2)) / 2
			_px(side, x, y, _vary(band[posmod(k, band.size())], 0.035))
	var top := Vector2i(0, 1)
	_rect(top, 0, 0, 15, 15, IRON_RED, 0.05)
	for i in 14:
		var cx := rng.randi_range(0, 14)
		var cy := rng.randi_range(0, 14)
		_rect(top, cx, cy, cx + 1, cy, [IRON_SILVER, IRON_BLACK, IRON_RED_DARK][rng.randi_range(0, 2)], 0.03)


func _rusty_rock() -> void:
	for t: Vector2i in [Vector2i(1, 1), Vector2i(2, 1)]:
		_rect(t, 0, 0, 15, 15, RUST, 0.06)
		for i in 18:
			var cx := rng.randi_range(0, 15)
			var cy := rng.randi_range(0, 15)
			_px(t, cx, cy, [RUST_LIGHT, RUST_DARK, Color("9c7b52")][rng.randi_range(0, 2)])
		if t.x == 2:
			for x in 16:   # a darker crust near the top, then rock
				_px(t, x, 0, _vary(RUST_DARK, 0.03))


func _fern_shale() -> void:
	var side := Vector2i(3, 1)
	for y in 16:
		var c := SHALE if y % 3 != 0 else SHALE_LIGHT
		for x in 16:
			_px(side, x, y, _vary(c, 0.025))
	# a fern print: a curved stem with leaflets on both sides
	for i in 12:
		var y := 13 - i
		var x := 4 + int(i * 0.55)
		_px(side, x, y, FERN)
		if i > 1 and i % 2 == 0:
			for d in range(1, 4 - i / 5):
				_px(side, x - d, y + 1 - (d / 2), FERN)
				_px(side, x + d, y + 1 - (d / 2), FERN)
	var top := Vector2i(4, 1)
	for y in 16:
		for x in 16:
			var c := SHALE_DARK if (x + y * 2) % 7 == 0 else SHALE
			_px(top, x, y, _vary(c, 0.03))


func _oil_seep() -> void:
	var top := Vector2i(5, 1)
	for y in 16:
		for x in 16:
			var w := sin(x * 0.7 + y * 0.3) + cos(y * 0.9 - x * 0.2)
			var c := OIL if w < 0.9 else OIL_BROWN
			_px(top, x, y, _vary(c, 0.02))
	for i in 5:   # glossy highlights
		var cx := rng.randi_range(2, 12)
		var cy := rng.randi_range(2, 12)
		_px(top, cx, cy, OIL_SHINE)
		_px(top, cx + 1, cy, OIL_BROWN)
	_px(top, 1, 1, SAND_DARK)
	_px(top, 14, 13, SAND_DARK)
	var side := Vector2i(6, 1)
	for y in 16:
		for x in 16:
			var dark := y > 1 + int(1.5 + sin(x * 0.8) * 1.2)
			_px(side, x, y, _vary(OIL_BROWN if dark else OIL, 0.03))
	for i in 8:
		_px(side, rng.randi_range(0, 15), rng.randi_range(4, 15), OIL_SHINE.darkened(0.3))


func _rock_salt() -> void:
	var t := Vector2i(7, 1)
	_rect(t, 0, 0, 15, 15, SALT, 0.03)
	for cube: Vector2i in [Vector2i(1, 1), Vector2i(8, 2), Vector2i(3, 8), Vector2i(10, 9), Vector2i(6, 12)]:
		var s := rng.randi_range(3, 5)
		for y in range(cube.y, cube.y + s):
			for x in range(cube.x, cube.x + s):
				var edge := x == cube.x or y == cube.y or x == cube.x + s - 1 or y == cube.y + s - 1
				_px(t, x, y, SALT_EDGE if edge else _vary(SALT_PINK, 0.03))
		_px(t, cube.x + 1, cube.y + 1, Color.WHITE)


func _salt_crust() -> void:
	var top := Vector2i(0, 2)
	_rect(top, 0, 0, 15, 15, CRUST, 0.015)
	# polygon cracks (a dry lake's crust)
	for p: Array in [[0, 5, 6, 3], [6, 3, 11, 6], [11, 6, 15, 4], [6, 3, 5, 10], [5, 10, 0, 12], [5, 10, 11, 13],
			[11, 6, 11, 13], [11, 13, 15, 14], [11, 13, 9, 15]]:
		var a := Vector2(p[0], p[1])
		var b := Vector2(p[2], p[3])
		for i in 17:
			var q := a.lerp(b, i / 16.0)
			_px(top, int(q.x), int(q.y), CRUST_CRACK)
	var side := Vector2i(1, 2)
	for y in 16:
		for x in 16:
			var c := CRUST if y < 3 else (SALT_PINK if (x + y) % 5 else SALT_EDGE)
			_px(side, x, y, _vary(c, 0.025))


# --- Refined (rows 2-3) ---

func _copper() -> void:
	var top := Vector2i(2, 2)
	for y in 16:
		for x in 16:
			var bar := y % 5
			var c := COPPER_LIGHT if bar == 0 else (COPPER_DARK if bar == 4 else COPPER)
			_px(top, x, y, _vary(c, 0.025))
	var side := Vector2i(3, 2)
	for y in 16:
		for x in 16:
			var row := y / 4
			var off := 4 if row % 2 else 0
			var bx := (x + off) % 8
			var c := COPPER
			if y % 4 == 0 or bx == 0:
				c = COPPER_DARK
			elif y % 4 == 1:
				c = COPPER_LIGHT
			_px(side, x, y, _vary(c, 0.02))


func _table_salt() -> void:
	var top := Vector2i(4, 2)
	_rect(top, 0, 0, 15, 15, SACK_SHADE, 0.02)
	for y in 16:
		for x in 16:
			if Vector2(x - 7.5, y - 7.5).length() < 7.0:
				_px(top, x, y, _vary(SACK, 0.02))
	_rect(top, 6, 6, 9, 9, Color("c9b28a"))   # the tie
	var side := Vector2i(5, 2)
	for y in 16:
		for x in 16:
			var c := SACK if x > 0 and x < 15 else SACK_SHADE
			if y >= 6 and y <= 10:
				c = LABEL_BLUE
			_px(side, x, y, _vary(c, 0.02))
	for x in [5, 7, 9]:   # white salt grains on the label
		_px(side, x, 8, Color.WHITE)


## A drum: its side (ribs, a band) and its lid (two bungs).
func _drum(top: Vector2i, side: Vector2i, body: Color, light: Color, band: Color) -> void:
	for y in 16:
		for x in 16:
			var c := _round_shade(body, x)
			if y == 3 or y == 12:
				c = _round_shade(light, x)   # the rolling ribs
			elif y >= 6 and y <= 9:
				c = _round_shade(band, x)
			_px(side, x, y, _vary(c, 0.015))
	_rect(top, 0, 0, 15, 15, body.darkened(0.2), 0.015)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.2:
				_px(top, x, y, _vary(light if d > 6.2 else body, 0.015))
	_rect(top, 3, 4, 4, 5, STEEL)
	_rect(top, 10, 10, 11, 11, STEEL)


func _plastic() -> void:
	var t := Vector2i(2, 3)
	_rect(t, 0, 0, 15, 15, Color("e9f3f3"), 0.02)
	for i in 34:   # little round pellets
		var cx := rng.randi_range(0, 15)
		var cy := rng.randi_range(0, 15)
		var c := PELLET_COLORS[rng.randi_range(0, PELLET_COLORS.size() - 1)]
		_px(t, cx, cy, c)
		_px(t, cx + 1, cy, c.darkened(0.15))


func _refinery() -> void:
	var top := Vector2i(3, 3)
	_rect(top, 0, 0, 15, 15, STEEL_DARK, 0.02)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 6.5:
				_px(top, x, y, STEEL if (x + y) % 3 else STEEL_DARK)   # a grating over the column
	_px(top, 7, 7, VALVE)
	var side := Vector2i(4, 3)
	for y in 16:
		for x in 16:
			var c := STEEL_DARK
			if x >= 4 and x <= 11:
				c = _round_shade(STEEL_LIGHT, x)   # the tall column
				if y % 4 == 0:
					c = STEEL   # its trays' rings
			elif x == 1 or x == 14:
				c = STEEL   # pipes down the sides
			_px(side, x, y, _vary(c, 0.015))
	for v: Vector2i in [Vector2i(1, 4), Vector2i(14, 9), Vector2i(1, 12)]:   # blue valves on the pipes
		_rect(side, v.x - 1, v.y, v.x + 1, v.y + 1, VALVE)
	_rect(side, 6, 13, 9, 14, TEAL)   # the brand's teal plate
	var bottom := Vector2i(5, 3)
	_rect(bottom, 0, 0, 15, 15, STEEL_DARK, 0.03)
	for b: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		_px(bottom, b.x, b.y, IRON_BLACK)
