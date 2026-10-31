extends SceneTree
## Generates the New Seven Wonders' pixel block pages (owner #78, spec §24, the second tour): data/blocks/pages/wonders3.png
## (page 36) and wonders4.png (page 37) (world/universes/wonders_blocks.gd TILES_NEW, TILES_NEW_MORE), 8 x 8 grids of
## 16 x 16 tiles in the style of tools/make_wonders_page.gd (original work, its own RNG seed; our own look, spec §3c:
## nothing copied from any photo, painting or other game). What the New Seven were built of, drawn plainly: the Great
## Wall's long grey bricks (their tops the walkway), Petra's rose rock with its swirling bands, its smooth carved stone
## and a rose column, the Colosseum's cream travertine full of tiny holes, Chichen Itza's pale Maya stone, a carved step
## pattern, the feathered serpent's head with open jaws and the red jaguar throne with jade spots, Machu Picchu's grey
## Inca stones fitted like a puzzle, Christ the Redeemer's small pale soapstone tiles, the Taj Mahal's white marble with
## a flower of coloured stones set in it; page 37 the Taj Mahal's gate of red sandstone with white marble lines, and a
## white stone copied from page 34's (tools/make_wonders_page.gd) for the pedestal's fake door. The fake stones are their
## stone with a faint crack.
## Its realistic twin is tools/make_wonders_new_realistic.py (the same layout). Page 37's rows 1-3 are the third tour's
## (the Seven Natural Wonders): this tool writes a fresh page 37, so run tools/make_wonders_nature_page.gd after it.
## Run: godot --headless --path . --script res://tools/make_wonders_new_page.gd   (then godot --headless --path . --import)

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/wonders3.png"
const OUT_MORE := "res://data/blocks/pages/wonders4.png"
const WHITE_FROM := "res://data/blocks/pages/wonders2.png"   # page 34: its white stone (2, 0)
const SEED := 20260936

const WALL := Color("8f9296")
const WALL_LIGHT := Color("a7aaae")
const WALL_DARK := Color("73767b")
const MORTAR := Color("c3c1ba")
const ROSE := Color("c9786a")
const ROSE_LIGHT := Color("e2a08c")
const ROSE_DARK := Color("9c4f47")
const ROSE_CREAM := Color("ecc9a8")
const ROSE_PLUM := Color("8a4a5a")
const ROSE_SMOOTH := Color("d48d78")
const TRAV := Color("e6d9bc")
const TRAV_LIGHT := Color("f1e8d2")
const TRAV_DARK := Color("c9b894")
const PIT := Color("9c8a66")
const MAYA := Color("cfc9bd")
const MAYA_LIGHT := Color("e0dbd0")
const MAYA_DARK := Color("a39d91")
const LICHEN := Color("8f8c78")
const GROOVE := Color("7f7a70")
const SERPENT_EYE := Color("2f2a26")
const MOUTH := Color("b8453a")
const FANG := Color("f4efe2")
const JAGUAR := Color("b8322a")
const JAGUAR_DARK := Color("8f231d")
const JADE := Color("3fae7a")
const JADE_LIGHT := Color("7fd6a6")
const INCA := Color("9d9c96")
const INCA_LIGHT := Color("b6b5af")
const INCA_DARK := Color("6f6e69")
const INCA_JOINT := Color("4f4e4a")
const SOAP := Color("c8cbbc")
const SOAP_LIGHT := Color("d9dccf")
const SOAP_DARK := Color("a9ad9c")
const MARBLE := Color("f4f2ec")
const MARBLE_SHADE := Color("e2dfd6")
const INLAY_RED := Color("c0392b")
const INLAY_GREEN := Color("2e8b57")
const INLAY_YELLOW := Color("e1b12c")
const INLAY_BLUE := Color("2c5f9e")
const RED_STONE := Color("a8452f")
const RED_LIGHT := Color("bf5a40")
const RED_DARK := Color("843424")
const CRACK := Color("6f6a60")
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED
	img = _page()
	_wall_brick()
	_rose_rock()
	_rose_stone()
	_rose_column()
	_travertine()
	_maya_stone()
	_maya_carving()
	_serpent_head()
	_jaguar()
	_inca_stone()
	_soapstone()
	_inlaid_marble()
	_fakes()
	var err := img.save_png(OUT)
	img = _page()
	_mughal_red()
	_white_stone()
	var err2 := img.save_png(OUT_MORE)
	print("WONDERS_NEW_PAGE saved err=%d err2=%d" % [err, err2])
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


func _crack(t: Vector2i) -> void:
	var x := 6
	for y in range(3, 13):
		x += rng.randi_range(-1, 1)
		_px(t, clampi(x, 3, 12), y, CRACK)


func _round_shade(c: Color, x: int) -> Color:
	var u := (float(x) + 0.5) / 16.0
	var k := 1.0 - 0.32 * pow(absf(u - 0.42) * 2.0, 2.0)
	return Color(c.r * k, c.g * k, c.b * k, c.a)


# --- Page 36 ---

## The Great Wall's bricks: the side (0,0) long grey bricks in a running bond with pale lime mortar; the top (1,0) the
## walkway, bricks laid flat and worn smooth by feet.
func _wall_brick() -> void:
	var side := Vector2i(0, 0)
	for y in 16:
		for x in 16:
			var row := y / 4
			var off := 4 if row % 2 else 0
			var c := WALL
			if y % 4 == 3 or (x + off) % 8 == 7:
				c = MORTAR
			elif y % 4 == 0:
				c = WALL_LIGHT
			elif (x + off) % 8 == 6:
				c = WALL_DARK
			_px(side, x, y, _vary(c, 0.03))
	var top := Vector2i(1, 0)
	for y in 16:
		for x in 16:
			var col := x / 4
			var off := 4 if col % 2 else 0
			var c := WALL_LIGHT.lerp(WALL, 0.4)
			if x % 4 == 3 or (y + off) % 8 == 7:
				c = MORTAR.darkened(0.08)
			_px(top, x, y, _vary(c, 0.03))


## Petra's rock: the side (3,0) swirling bands of rose, red, cream and plum; the top (4,0) rosy grains.
func _rose_rock() -> void:
	var side := Vector2i(3, 0)
	var bands: Array[Color] = [ROSE, ROSE_LIGHT, ROSE_DARK, ROSE_CREAM, ROSE, ROSE_PLUM, ROSE_LIGHT, ROSE]
	for y in 16:
		for x in 16:
			var w := y + sin(x * TAU / 16.0) * 1.6 + sin(x * TAU / 8.0 + 1.3) * 0.8   # (the bands meet across blocks)
			var b := bands[posmod(int(floor(w / 2.0)), bands.size())]
			_px(side, x, y, _vary(b, 0.025))
	var top := Vector2i(4, 0)
	_rect(top, 0, 0, 15, 15, ROSE, 0.04)
	for i in 24:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), [ROSE_LIGHT, ROSE_DARK, ROSE_CREAM][rng.randi_range(0, 2)])


## Smooth carved rose stone (5,0): the chisel's fine strokes and a faint band.
func _rose_stone() -> void:
	var t := Vector2i(5, 0)
	for y in 16:
		for x in 16:
			var c := ROSE_SMOOTH
			if (x + y * 2) % 7 == 0:
				c = ROSE_SMOOTH.darkened(0.06)
			if y == 5 or y == 11:
				c = ROSE_SMOOTH.lerp(ROSE_CREAM, 0.3)
			_px(t, x, y, _vary(c, 0.015))


## A rose column: the side (6,0) round and shaded, a leafy top band; the top (7,0) its round section.
func _rose_column() -> void:
	var side := Vector2i(6, 0)
	for y in 16:
		for x in 16:
			var c := ROSE_SMOOTH
			if y < 3:
				c = ROSE_LIGHT if (x + y) % 3 == 0 else ROSE_SMOOTH.darkened(0.1)   # the carved leaves at its top
			_px(side, x, y, _vary(_round_shade(c, x), 0.015))
	var top := Vector2i(7, 0)
	_rect(top, 0, 0, 15, 15, ROSE_DARK, 0.02)
	for y in 16:
		for x in 16:
			if Vector2(x - 7.5, y - 7.5).length() < 7.0:
				_px(top, x, y, _vary(ROSE_SMOOTH, 0.02))


## The Colosseum's travertine: the side (0,1) cream blocks with tiny holes and a joint; the top (1,1) cream with pits.
func _travertine() -> void:
	var side := Vector2i(0, 1)
	for y in 16:
		for x in 16:
			var c := TRAV
			if y % 8 == 7 or (x + (8 if y >= 8 else 0)) % 16 == 15:
				c = TRAV_DARK
			elif y % 3 == 0 and rng.randf() < 0.4:
				c = TRAV_LIGHT   # its layers
			_px(side, x, y, _vary(c, 0.02))
	for i in 18:   # the tiny holes travertine is full of
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		_px(side, x, y, PIT)
		if rng.randf() < 0.4:
			_px(side, x + 1, y, PIT.lightened(0.2))
	var top := Vector2i(1, 1)
	_rect(top, 0, 0, 15, 15, TRAV_LIGHT.lerp(TRAV, 0.5), 0.02)
	for i in 14:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), PIT)


## Chichen Itza's stone: the side (3,1) pale blocks with dark weathering and lichen; the top (4,1).
func _maya_stone() -> void:
	var side := Vector2i(3, 1)
	for y in 16:
		for x in 16:
			var c := MAYA
			if y % 5 == 4 or (x + (5 if (y / 5) % 2 else 0)) % 10 == 9:
				c = MAYA_DARK
			elif y % 5 == 0:
				c = MAYA_LIGHT
			_px(side, x, y, _vary(c, 0.025))
	for i in 10:
		_px(side, rng.randi_range(0, 15), rng.randi_range(0, 15), LICHEN)
	var top := Vector2i(4, 1)
	_rect(top, 0, 0, 15, 15, MAYA_LIGHT.lerp(MAYA, 0.5), 0.025)
	for i in 10:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), MAYA_DARK)


## A carved Maya band (5,1): a step-and-hook pattern cut into the stone between two lines.
func _maya_carving() -> void:
	var t := Vector2i(5, 1)
	_rect(t, 0, 0, 15, 15, MAYA, 0.02)
	for x in 16:
		_px(t, x, 1, GROOVE)
		_px(t, x, 14, GROOVE)
	var fret := ["........", ".######.", ".#....#.", ".#.##.#.", ".#.#..#.", ".#.####.", ".#......", "##......"]
	for y in 8:
		for x in 16:
			if fret[y][x % 8] == "#":
				_px(t, x, 4 + y, GROOVE)


## The feathered serpent's head (7,1): big round eyes, feathers over them, open jaws with fangs and a red mouth.
func _serpent_head() -> void:
	var t := Vector2i(7, 1)
	_rect(t, 0, 0, 15, 15, MAYA, 0.02)
	for x in 16:   # feathers over the brow
		_px(t, x, 1 + (1 if x % 3 == 0 else 0), MAYA_DARK)
	for e: Vector2i in [Vector2i(3, 5), Vector2i(12, 5)]:
		for y in range(e.y - 1, e.y + 2):
			for x in range(e.x - 1, e.x + 2):
				_px(t, x, y, FANG)
		_px(t, e.x, e.y, SERPENT_EYE)
	_rect(t, 2, 9, 13, 13, MOUTH)   # the open jaws
	for x: int in [3, 6, 9, 12]:
		_px(t, x, 9, FANG)
		_px(t, x, 10, FANG)
		_px(t, x, 13, FANG)
		_px(t, x, 12, FANG)
	_rect(t, 7, 11, 8, 11, MOUTH.darkened(0.3))   # the tongue
	for x in 16:
		_px(t, x, 14, MAYA_DARK)


## The red jaguar throne: the side (0,2) red with jade spots and a snarl of white fangs; the top (1,2) red with spots.
func _jaguar() -> void:
	var side := Vector2i(0, 2)
	_rect(side, 0, 0, 15, 15, JAGUAR, 0.025)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(7, 3), Vector2i(12, 2), Vector2i(4, 7), Vector2i(10, 7), Vector2i(2, 12),
			Vector2i(13, 11), Vector2i(7, 12)]:
		_px(side, p.x, p.y, JADE)
		_px(side, p.x + 1, p.y, JADE_LIGHT)
		_px(side, p.x, p.y + 1, JADE)
		_px(side, p.x + 1, p.y + 1, JADE)
	for x in range(4, 12, 2):
		_px(side, x, 15, FANG)
	var top := Vector2i(1, 2)
	_rect(top, 0, 0, 15, 15, JAGUAR.lerp(JAGUAR_DARK, 0.3), 0.025)
	for i in 9:
		var x := rng.randi_range(1, 13)
		var y := rng.randi_range(1, 13)
		_px(top, x, y, JADE)
		_px(top, x + 1, y, JADE_LIGHT)


## Machu Picchu's stone: the side (2,2) grey granite blocks of many shapes fitted tightly (thin dark joints, rounded
## faces); the top (3,2).
func _inca_stone() -> void:
	var side := Vector2i(2, 2)
	_rect(side, 0, 0, 15, 15, INCA, 0.03)
	# the joints of a few blocks of different sizes, drawn as a puzzle
	var joints := [[0, 5, 16, 5], [0, 11, 16, 11], [6, 0, 6, 5], [11, 5, 13, 11], [4, 11, 3, 16], [10, 11, 10, 16],
		[2, 5, 1, 11]]
	for j: Array in joints:
		var a := Vector2(j[0], j[1])
		var b := Vector2(j[2], j[3])
		for k in 24:
			var p := a.lerp(b, k / 23.0)
			_px(side, int(p.x), int(p.y), INCA_JOINT)
	for y in 16:   # light on the top of each block, shade at its foot
		for x in 16:
			if _pixel(side, x, y) == INCA_JOINT:
				continue
			if y > 0 and _pixel(side, x, y - 1) == INCA_JOINT:
				_px(side, x, y, INCA_LIGHT)
			elif y < 15 and _pixel(side, x, y + 1) == INCA_JOINT:
				_px(side, x, y, INCA_DARK)
	var top := Vector2i(3, 2)
	_rect(top, 0, 0, 15, 15, INCA_LIGHT.lerp(INCA, 0.5), 0.03)
	for k in 16:
		_px(top, k, 8 + int(sin(k * 0.6) * 1.5), INCA_JOINT)
		_px(top, 7 + int(sin(k * 0.8) * 1.2), k, INCA_JOINT)


## Christ the Redeemer's soapstone (5,2): small pale triangular tiles, each a little different.
func _soapstone() -> void:
	var t := Vector2i(5, 2)
	for y in 16:
		for x in 16:
			var cell := Vector2i(x / 4, y / 4)
			var lower := (x % 4) > (y % 4)
			var shade: Color = [SOAP, SOAP_LIGHT, SOAP_DARK][absi(cell.x * 7 + cell.y * 3 + (1 if lower else 0)) % 3]
			var c: Color = shade
			if x % 4 == 0 or y % 4 == 0 or (x % 4) == (y % 4):
				c = SOAP_DARK.darkened(0.08)
			_px(t, x, y, _vary(c, 0.015))


## The Taj Mahal's inlaid marble: the side (6,2) white with a flower of red, green, yellow and blue stones set in it and a
## thin border; the top (7,2) white with the border.
func _inlaid_marble() -> void:
	var side := Vector2i(6, 2)
	_rect(side, 0, 0, 15, 15, MARBLE, 0.012)
	for i in 16:
		_px(side, i, 1, MARBLE_SHADE)
		_px(side, i, 14, MARBLE_SHADE)
		_px(side, 1, i, MARBLE_SHADE)
		_px(side, 14, i, MARBLE_SHADE)
	for y in range(9, 13):   # the stem and two leaves
		_px(side, 8, y, INLAY_GREEN)
	for p: Vector2i in [Vector2i(6, 10), Vector2i(5, 11), Vector2i(10, 10), Vector2i(11, 9)]:
		_px(side, p.x, p.y, INLAY_GREEN)
	for p: Vector2i in [Vector2i(8, 4), Vector2i(7, 5), Vector2i(9, 5), Vector2i(6, 6), Vector2i(10, 6), Vector2i(7, 7),
			Vector2i(9, 7)]:
		_px(side, p.x, p.y, INLAY_RED)
	_px(side, 8, 6, INLAY_YELLOW)
	_px(side, 8, 5, INLAY_YELLOW)
	for p: Vector2i in [Vector2i(4, 4), Vector2i(12, 4)]:
		_px(side, p.x, p.y, INLAY_BLUE)
	var top := Vector2i(7, 2)
	_rect(top, 0, 0, 15, 15, MARBLE, 0.012)
	for i in 16:
		_px(top, i, 2, INLAY_GREEN)
		_px(top, i, 13, INLAY_GREEN)


## The fake stones: their stone's side with a faint crack (a sharp eye finds it).
func _fakes() -> void:
	for pair: Array in [[Vector2i(0, 0), Vector2i(2, 0)], [Vector2i(0, 1), Vector2i(2, 1)], [Vector2i(3, 1), Vector2i(6, 1)],
			[Vector2i(2, 2), Vector2i(4, 2)]]:
		_copy(pair[0], pair[1])
		_crack(pair[1])


# --- Page 37 ---

## The Taj Mahal's gate: red sandstone, the side (0,0) with white marble lines (a frame and a star), the top (1,0).
func _mughal_red() -> void:
	var side := Vector2i(0, 0)
	_rect(side, 0, 0, 15, 15, RED_STONE, 0.025)
	for i in range(1, 15):
		_px(side, i, 1, MARBLE)
		_px(side, i, 14, MARBLE)
		_px(side, 1, i, MARBLE)
		_px(side, 14, i, MARBLE)
	for i in range(-3, 4):   # a white star of lines in the middle
		_px(side, 7 + i, 7 + i, MARBLE)
		_px(side, 8 - i, 7 + i, MARBLE)
		_px(side, 7 + i, 7, MARBLE_SHADE)
	var top := Vector2i(1, 0)
	for y in 16:
		for x in 16:
			var c := RED_STONE if (x + y / 3) % 5 else RED_DARK
			if y % 6 == 0:
				c = RED_LIGHT
			_px(top, x, y, _vary(c, 0.02))


## The pedestal's white stone: page 34's white stone (2,0) copied, and its side with a crack (3,0).
func _white_stone() -> void:
	var from := Image.load_from_file(ProjectSettings.globalize_path(WHITE_FROM))
	for y in TILE:
		for x in TILE:
			_px(Vector2i(2, 0), x, y, from.get_pixel(2 * TILE + x, y))
	_copy(Vector2i(2, 0), Vector2i(3, 0))
	_crack(Vector2i(3, 0))
