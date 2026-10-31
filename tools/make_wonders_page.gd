extends SceneTree
## Generates the world's wonders' pixel block pages (owner #78, spec §24): data/blocks/pages/wonders.png (page 33) and
## wonders2.png (page 34) (world/universes/wonders_blocks.gd TILES, TILES_MORE), 8 x 8 grids of 16 x 16 tiles in the style
## of tools/make_prospect_page.gd (original work, its own RNG seed; our own look, spec §3c: nothing copied from any
## photo, painting or other game). What the ancient wonders were built of, drawn plainly: the pyramid's golden limestone
## in big stones, its smooth white casing, pink granite with black and white specks, white marble with grey veins, a
## fluted column and its top with two scrolls, a carved band with a key pattern, shiny bronze, creamy ivory, gold leaf
## with folds, black ebony, Babylon's yellow bricks in dark bitumen and its blue glazed bricks with a flower; the
## Lighthouse's fire and white stone, the tour's paving, the wonder plaque (a bronze plate on a stone), a wooden water
## screw and silvery olive leaves (cut out). The fake stones are their stone with a faint crack.
## Its realistic twin is tools/make_wonders_realistic.py (the same layout).
## Run: godot --headless --path . --script res://tools/make_wonders_page.gd   (then godot --headless --path . --import)

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/wonders.png"
const OUT_MORE := "res://data/blocks/pages/wonders2.png"
const SEED := 20260933

const LIME := Color("dcc58f")
const LIME_LIGHT := Color("ead7a6")
const LIME_DARK := Color("b9a06a")
const JOINT := Color("8f7a50")
const CASING := Color("f3ecdc")
const CASING_SHADE := Color("e4dac4")
const GRANITE := Color("c9837a")
const GRANITE_DARK := Color("9e5f58")
const GRANITE_BLACK := Color("3a3032")
const GRANITE_WHITE := Color("efe3dc")
const MARBLE := Color("f1f0ec")
const MARBLE_SHADE := Color("dcdad4")
const VEIN := Color("b7b7b8")
const VEIN_DARK := Color("9d9ea3")
const CRACK := Color("8f8a80")
const BRONZE := Color("c98f3c")
const BRONZE_LIGHT := Color("efc06a")
const BRONZE_DARK := Color("8f5f25")
const IVORY := Color("f4e8cc")
const IVORY_SHADE := Color("e2d2ae")
const GOLD := Color("f2c53d")
const GOLD_LIGHT := Color("ffe88a")
const GOLD_DARK := Color("c08f1f")
const EBONY := Color("2c2522")
const EBONY_LIGHT := Color("463a33")
const EBONY_DARK := Color("1b1614")
const BRICK := Color("d8b56a")
const BRICK_LIGHT := Color("e6c883")
const BRICK_DARK := Color("b9954f")
const BITUMEN := Color("3d342c")
const GLAZE := Color("2457b8")
const GLAZE_LIGHT := Color("4f86e0")
const GLAZE_DARK := Color("173d86")
const FLOWER := Color("f6e27a")
const FLOWER_WHITE := Color("fbf6e6")
const FIRE := Color("ff9a1f")
const FIRE_LIGHT := Color("ffd23f")
const FIRE_WHITE := Color("fff6c8")
const FIRE_DARK := Color("e0621a")
const WHITE_STONE := Color("f0ede4")
const WHITE_JOINT := Color("c8c2b3")
const PAVE := Color("d8cfbd")
const PAVE_LIGHT := Color("e6ddcb")
const PAVE_DARK := Color("aea38c")
const STONE := Color("a9a8a2")
const STONE_DARK := Color("85847e")
const WOOD := Color("a4733f")
const WOOD_LIGHT := Color("c28d52")
const WOOD_DARK := Color("74502b")
const OLIVE := Color("8fa77a")
const OLIVE_LIGHT := Color("b8c9a2")
const OLIVE_DARK := Color("5f7650")
const OLIVE_FRUIT := Color("3f4a2c")
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED
	img = _page()
	_limestone()
	_casing()
	_granite()
	_marble()
	_column()
	_capital()
	_frieze()
	_bronze()
	_ivory()
	_gold_leaf()
	_ebony()
	_babylon_brick()
	_glazed_brick()
	_fakes()
	var err := img.save_png(OUT)
	img = _page()
	_beacon_fire()
	_white_brick()
	_paving()
	_plaque()
	_screw()
	_olive()
	var err2 := img.save_png(OUT_MORE)
	print("WONDERS_PAGE saved err=%d err2=%d" % [err, err2])
	quit()


func _page() -> Image:
	var i := Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	i.fill(CLEAR)
	return i


func _px(t: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE and y < TILE:
		img.set_pixel(t.x * TILE + x, t.y * TILE + y, c)


func _pixel(t: Vector2i, x: int, y: int) -> Color:
	return img.get_pixel(t.x * TILE + x, t.y * TILE + y)


func _rect(t: Vector2i, x0: int, y0: int, x1: int, y1: int, c: Color, vary := 0.0) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(t, x, y, _vary(c, vary))


func _vary(c: Color, amount: float) -> Color:
	if amount <= 0.0:
		return c
	var k := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + k, 0, 1), clampf(c.g + k, 0, 1), clampf(c.b + k, 0, 1), c.a)


func _copy(from: Vector2i, to: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(to, x, y, _pixel(from, x, y))


## A round part's side: light a little left of the middle, darker to the edges.
func _round_shade(c: Color, x: int) -> Color:
	var u := (float(x) + 0.5) / 16.0
	var k := 1.0 - 0.32 * pow(absf(u - 0.42) * 2.0, 2.0)
	return Color(c.r * k, c.g * k, c.b * k, c.a)


# --- Page 33 ---

## Big rough stones in two courses with dark joints (the pyramid's core): the side (0,0) and the top (1,0).
func _limestone() -> void:
	var side := Vector2i(0, 0)
	_rect(side, 0, 0, 15, 15, LIME, 0.035)
	for x in 16:
		_px(side, x, 7, JOINT)
		_px(side, x, 15, JOINT.lightened(0.1))
	for y in range(0, 7):
		_px(side, 5, y, JOINT)
	for y in range(8, 15):
		_px(side, 11, y, JOINT)
	for i in 16:   # weathered pits and lighter chips
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		if _pixel(side, x, y) != JOINT:
			_px(side, x, y, LIME_DARK if rng.randf() < 0.6 else LIME_LIGHT)
	var top := Vector2i(1, 0)
	_rect(top, 0, 0, 15, 15, LIME_LIGHT, 0.03)
	for i in 16:
		_px(top, i, 8, JOINT.lightened(0.15))
		_px(top, 8, i, JOINT.lightened(0.15))
	for i in 10:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), LIME_DARK)


func _casing() -> void:
	var t := Vector2i(2, 0)
	_rect(t, 0, 0, 15, 15, CASING, 0.012)
	for x in 16:
		_px(t, x, 15, CASING_SHADE)   # a fine joint: the casing stones fitted tightly
	for i in 5:
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 14), CASING_SHADE)


func _granite() -> void:
	var t := Vector2i(3, 0)
	_rect(t, 0, 0, 15, 15, GRANITE, 0.04)
	for i in 30:
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		var c: Color = [GRANITE_BLACK, GRANITE_BLACK, GRANITE_WHITE, GRANITE_DARK][rng.randi_range(0, 3)]
		_px(t, x, y, c)
		if rng.randf() < 0.3:
			_px(t, x + 1, y, c)


## White marble with soft grey veins (5,0).
func _marble() -> void:
	var t := Vector2i(5, 0)
	_marble_field(t)


func _marble_field(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, MARBLE, 0.015)
	for v in 3:
		var y0 := rng.randf_range(-4.0, 14.0)
		var slope := rng.randf_range(0.3, 0.9)
		for x in 16:
			var y := int(y0 + x * slope + sin(x * 0.8 + v) * 1.4)
			_px(t, x, y, VEIN if v > 0 else VEIN_DARK)
			if rng.randf() < 0.3:
				_px(t, x, y + 1, MARBLE_SHADE)


## A fluted column: the side (6,0) with its grooves, the top (7,0) a round section.
func _column() -> void:
	var side := Vector2i(6, 0)
	for y in 16:
		for x in 16:
			var groove := x % 4 == 0
			var c := MARBLE_SHADE if groove else MARBLE
			if x % 4 == 1:
				c = VEIN
			_px(side, x, y, _vary(_round_shade(c, x), 0.01))
	var top := Vector2i(7, 0)
	_rect(top, 0, 0, 15, 15, MARBLE_SHADE, 0.012)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.0:
				var notch := d > 6.0 and int(atan2(y - 7.5, x - 7.5) / TAU * 16.0 + 16.0) % 2 == 0
				_px(top, x, y, _vary(VEIN if notch else MARBLE, 0.012))


## A column's top (0,1): a flat slab, two scrolls (volutes) and the flutes starting below.
func _capital() -> void:
	var t := Vector2i(0, 1)
	_rect(t, 0, 0, 15, 15, MARBLE, 0.012)
	_rect(t, 0, 0, 15, 1, MARBLE_SHADE)
	for x in 16:
		_px(t, x, 2, VEIN)
	for c: Vector2 in [Vector2(3.0, 6.0), Vector2(12.0, 6.0)]:
		for y in range(2, 11):
			for x in 16:
				var d := Vector2(x - c.x, y - c.y).length()
				if d < 3.3:
					var a := atan2(y - c.y, x - c.x)
					var spiral := fposmod(d - a / TAU * 2.2, 2.2) < 0.9
					_px(t, x, y, VEIN_DARK if spiral else MARBLE)
	for x in range(5, 11):   # the egg-and-dart band between the scrolls
		_px(t, x, 7, VEIN if x % 2 else MARBLE_SHADE)
	for y in range(11, 16):
		for x in 16:
			_px(t, x, y, _round_shade(MARBLE_SHADE if x % 4 == 0 else MARBLE, x))


## A carved band (1,1): a key pattern between two lines.
func _frieze() -> void:
	var t := Vector2i(1, 1)
	_rect(t, 0, 0, 15, 15, MARBLE, 0.012)
	for x in 16:
		_px(t, x, 2, VEIN_DARK)
		_px(t, x, 13, VEIN_DARK)
	# the key (meander): a hook every 8 pixels
	var key := ["########", "#......#", "#.####.#", "#.#..#.#", "#.#.##.#", "#.#....#", "#.######", "#......."]
	for y in 8:
		for x in 16:
			if key[y][x % 8] == "#":
				_px(t, x, 4 + y, VEIN)


func _bronze() -> void:
	var t := Vector2i(3, 1)
	for y in 16:
		for x in 16:
			var c := BRONZE
			var shine := absf(x - 5 - y * 0.25)
			if shine < 1.5:
				c = BRONZE_LIGHT
			elif shine < 3.0:
				c = BRONZE.lerp(BRONZE_LIGHT, 0.4)
			elif x > 12:
				c = BRONZE_DARK
			_px(t, x, y, _vary(c, 0.02))
	for i in 10:   # the hammered plates' dents
		_px(t, rng.randi_range(0, 15), rng.randi_range(0, 15), BRONZE_DARK.lightened(0.1))


func _ivory() -> void:
	var t := Vector2i(4, 1)
	_rect(t, 0, 0, 15, 15, IVORY, 0.01)
	for i in 4:   # its fine grain
		var y := rng.randi_range(1, 14)
		for x in 16:
			if rng.randf() < 0.6:
				_px(t, x, y + int(sin(x * 0.5 + i) * 0.8), IVORY_SHADE)


func _gold_leaf() -> void:
	var t := Vector2i(5, 1)
	for y in 16:
		for x in 16:
			var fold := int(x + y * 0.5) % 6
			var c := GOLD
			if fold == 0:
				c = GOLD_DARK
			elif fold == 1:
				c = GOLD_LIGHT
			_px(t, x, y, _vary(c, 0.02))


func _ebony() -> void:
	var side := Vector2i(6, 1)
	for y in 16:
		for x in 16:
			var c := EBONY
			if (x + int(sin(y * 0.4) * 1.5)) % 5 == 0:
				c = EBONY_LIGHT
			elif (x + y) % 11 == 0:
				c = EBONY_DARK
			_px(side, x, y, _vary(c, 0.012))
	var top := Vector2i(7, 1)
	for y in 16:
		for x in 16:
			var ring := int(Vector2(x - 7.5, y - 7.5).length() * 1.2) % 3
			_px(top, x, y, _vary(EBONY_LIGHT if ring == 0 else EBONY, 0.012))


## Babylon's baked bricks (0,2): yellow bricks in a running bond, set in dark bitumen.
func _babylon_brick() -> void:
	var t := Vector2i(0, 2)
	_bricks(t, BRICK, BRICK_LIGHT, BRICK_DARK, BITUMEN)


func _bricks(t: Vector2i, body: Color, light: Color, dark: Color, joint: Color) -> void:
	for y in 16:
		for x in 16:
			var row := y / 4
			var off := 4 if row % 2 else 0
			var c := body
			if y % 4 == 3 or (x + off) % 8 == 7:
				c = joint
			elif y % 4 == 0:
				c = light
			elif (x + off) % 8 == 6:
				c = dark
			_px(t, x, y, _vary(c, 0.025))


## Blue glazed bricks: the side (1,2) with a flower in the middle, the top (2,2) plain.
func _glazed_brick() -> void:
	var side := Vector2i(1, 2)
	_bricks(side, GLAZE, GLAZE_LIGHT, GLAZE_DARK, GLAZE_DARK.darkened(0.3))
	for p: Vector2i in [Vector2i(7, 5), Vector2i(9, 7), Vector2i(7, 9), Vector2i(5, 7)]:   # four petals
		_px(side, p.x, p.y, FLOWER)
		_px(side, p.x + (1 if p.x < 7 else (-1 if p.x > 7 else 0)), p.y + (1 if p.y < 7 else (-1 if p.y > 7 else 0)),
			FLOWER_WHITE)
	_px(side, 7, 7, FLOWER_WHITE)
	var top := Vector2i(2, 2)
	_bricks(top, GLAZE, GLAZE_LIGHT, GLAZE_DARK, GLAZE_DARK.darkened(0.3))


## The fake stones: their stone's side with a faint crack (a sharp eye finds it).
func _fakes() -> void:
	for pair: Array in [[Vector2i(0, 0), Vector2i(4, 0)], [Vector2i(5, 0), Vector2i(2, 1)], [Vector2i(0, 2), Vector2i(3, 2)]]:
		_copy(pair[0], pair[1])
		var t: Vector2i = pair[1]
		var x := 6
		for y in range(3, 13):
			x += rng.randi_range(-1, 1)
			_px(t, clampi(x, 3, 12), y, CRACK)


# --- Page 34 ---

## The Lighthouse's fire: its side (0,0) flames, its top (1,0) a bright heart.
func _beacon_fire() -> void:
	var side := Vector2i(0, 0)
	for y in 16:
		for x in 16:
			var tongue := sin(x * 1.1) * 2.5 + sin(x * 2.3 + 1.0) * 1.2
			var h := 15.0 - y
			var c := FIRE_DARK
			if h < 9.0 + tongue:
				c = FIRE
			if h < 5.0 + tongue * 0.6:
				c = FIRE_LIGHT
			if h < 2.0:
				c = FIRE_WHITE
			_px(side, x, y, _vary(c, 0.02))
	var top := Vector2i(1, 0)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := FIRE_WHITE if d < 3.0 else (FIRE_LIGHT if d < 5.5 else FIRE)
			_px(top, x, y, _vary(c, 0.02))


func _white_brick() -> void:
	var t := Vector2i(2, 0)
	for y in 16:
		for x in 16:
			var row := y / 8
			var off := 8 if row % 2 else 0
			var c := WHITE_STONE
			if y % 8 == 7 or (x + off) % 16 == 15:
				c = WHITE_JOINT
			_px(t, x, y, _vary(c, 0.018))


func _paving() -> void:
	var top := Vector2i(3, 0)
	_rect(top, 0, 0, 15, 15, PAVE, 0.025)
	for i in 16:   # three slabs: one long, two square
		_px(top, i, 9, PAVE_DARK)
		_px(top, 15, i, PAVE_DARK)
		if i < 9:
			_px(top, 7, i, PAVE_DARK)
	for i in 8:
		_px(top, rng.randi_range(0, 14), rng.randi_range(0, 14), PAVE_LIGHT)
	var side := Vector2i(4, 0)
	_rect(side, 0, 0, 15, 15, PAVE_DARK.lerp(PAVE, 0.5), 0.025)
	for x in 16:
		_px(side, x, 0, PAVE_LIGHT)
		_px(side, x, 15, PAVE_DARK)
	for y in 16:
		_px(side, 15, y, PAVE_DARK)


## The wonder plaque: a grey stone (6,0) with a bronze plate on its sides (5,0), its lines of writing and a star.
func _plaque() -> void:
	var side := Vector2i(5, 0)
	_rect(side, 0, 0, 15, 15, STONE, 0.03)
	_rect(side, 2, 2, 13, 13, BRONZE_DARK)
	_rect(side, 3, 3, 12, 12, BRONZE, 0.02)
	for y: int in [8, 10]:
		for x in range(4, 12):
			_px(side, x, y, BRONZE_DARK if x % 3 != 2 else BRONZE)
	for p: Vector2i in [Vector2i(7, 4), Vector2i(8, 4), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5),
			Vector2i(7, 6), Vector2i(8, 6)]:
		_px(side, p.x, p.y, BRONZE_LIGHT)
	var top := Vector2i(6, 0)
	_rect(top, 0, 0, 15, 15, STONE, 0.03)
	for x in 16:
		_px(top, x, 0, STONE_DARK)
		_px(top, x, 15, STONE_DARK)


## A wooden water screw: its side (7,0) a helical band round a wooden drum, its end (0,1) a round of wood.
func _screw() -> void:
	var side := Vector2i(7, 0)
	for y in 16:
		for x in 16:
			var band := int(x + y * 1.3) % 6 < 2
			_px(side, x, y, _vary(_round_shade(WOOD_DARK if band else WOOD, x), 0.02))
	var top := Vector2i(0, 1)
	_rect(top, 0, 0, 15, 15, WOOD_DARK, 0.02)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.0:
				var arm := fposmod(atan2(y - 7.5, x - 7.5) / TAU * 3.0 + d * 0.25, 1.0) < 0.3
				_px(top, x, y, _vary(WOOD_DARK if arm else WOOD_LIGHT, 0.02))


## Olive leaves (1,1), cut out: narrow silvery-green leaves with gaps, and a few olives.
func _olive() -> void:
	var t := Vector2i(1, 1)
	for i in 60:
		var cx := rng.randi_range(0, 15)
		var cy := rng.randi_range(0, 15)
		var dir := 1 if rng.randf() < 0.5 else -1
		var c: Color = [OLIVE, OLIVE_LIGHT, OLIVE_DARK][rng.randi_range(0, 2)]
		for k in 3:   # a narrow leaf: three pixels on a slant
			_px(t, cx + k * dir, cy + k / 2, _vary(c, 0.02))
	for i in 5:
		var x := rng.randi_range(1, 14)
		var y := rng.randi_range(1, 14)
		_px(t, x, y, OLIVE_FRUIT)
