extends SceneTree
## Generates the colony's pixel block page (owner #77, spec §21c): data/blocks/pages/colony.png, page 31
## (world/colony/colony_blocks.gd TILES), an 8 x 8 grid of 16 x 16 tiles in the style of tools/make_rocket_page.gd
## (original work, its own RNG seed). Our own look (spec §3c): clear dome glass with a thin white frame, white habitat
## panels with the brand's teal, light floor tiles, dark greenhouse soil with sprouts, pink grow lamps (red and blue
## LEDs), a warm light, leaves with oranges, a tank of blue water, an ice melter with a warm glow, an oxygen maker with
## bubbling tubes, screens with graphs, a big map with a globe, teal-and-white airlock stripes, shiny rocket steel, printed
## regolith in layers and a white table (cut out: its legs).
## Its realistic twin is tools/make_colony_realistic.py (the same layout).
## Run: godot --headless --path . --script res://tools/make_colony_page.gd   (then godot --headless --path . --import)

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/colony.png"
const SEED := 20260931

const WHITE := Color("f4f6f8")
const WHITE_SHADE := Color("d3dae3")
const FRAME := Color("e8f6ff")
const SILVER := Color("b9c2cc")
const SILVER_LIGHT := Color("dfe5ec")
const SILVER_DARK := Color("8b95a2")
const DARK := Color("3b404b")
const DARKER := Color("262a33")
const TEAL := Color("139e9b")            # the brand's teal (spec §3c)
const TEAL_DARK := Color("0c7876")
const TEAL_LIGHT := Color("5fd3cf")
const FLOOR := Color("c9ced6")
const FLOOR_LINE := Color("a8aeb8")
const FLOOR_SIDE := Color("9aa1ab")
const SOIL := Color("4a3226")
const SOIL_LIGHT := Color("6b4a36")
const SPROUT := Color("6fcf4a")
const LAMP_RED := Color("ff3d6e")
const LAMP_BLUE := Color("5a6bff")
const LAMP_GLOW := Color("e05ad8")
const WARM := Color("fff3d6")
const WARM_EDGE := Color("ffd98a")
const LEAF := Color("57a83d")
const LEAF_DARK := Color("2f6f25")
const LEAF_LIGHT := Color("7cc451")
const ORANGE := Color("ff9f1c")
const ORANGE_LIGHT := Color("ffd07a")
const WATER := Color("3f8fe0")
const WATER_DEEP := Color("2a6fc0")
const GLASS_TINT := Color("d6efff")
const ICE := Color("d8f0ff")
const ICE_SHADE := Color("a9d8f5")
const COIL := Color("ff8a3c")
const COIL_HOT := Color("ffd23f")
const SCREEN := Color("0f3a4a")
const GRAPH := Color("7be08a")
const YELLOW := Color("ffd23f")
const SKY := Color("6ec6ff")
const MAP_BG := Color("10204a")
const RED := Color("e0413a")
const REGOLITH := Color("aba69d")
const REGOLITH_DARK := Color("948e84")
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	_glass()
	_panel()
	_floor()
	_soil()
	_grow_lamp()
	_light()
	_fruit_leaves()
	_water_tank()
	_ice_melter()
	_oxygen_maker()
	_screens()
	_airlock()
	_hull()
	_regolith()
	_table()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/blocks/pages/"))
	var err := img.save_png(OUT)
	print("COLONY_PAGE saved err=%d" % err)
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


func _border(t: Vector2i, c: Color) -> void:
	for i in TILE:
		_px(t, i, 0, c)
		_px(t, i, TILE - 1, c)
		_px(t, 0, i, c)
		_px(t, TILE - 1, i, c)


# --- Row 0 ---

## Dome glass: clear, a thin white frame on two edges (two panes side by side draw one line between them) and a glint
## (cut out: the sky and the garden show through).
func _glass() -> void:
	var t := Vector2i(0, 0)
	for i in TILE:
		_px(t, i, 0, FRAME)
		_px(t, 0, i, FRAME)
	for i in 4:
		_px(t, 3 + i, 6 - i, Color.WHITE)
	_px(t, 4, 7, Color.WHITE)
	_px(t, 11, 12, Color(1, 1, 1))
	_px(t, 12, 11, Color(1, 1, 1))


## Habitat panels: white with seams and rivets, a teal stripe on the side; the top a panel grid.
func _panel() -> void:
	var side := Vector2i(1, 0)
	_rect(side, 0, 0, 15, 15, WHITE, 0.02)
	for x in 16:
		_px(side, x, 0, WHITE_SHADE)
		_px(side, x, 15, WHITE_SHADE)
		_px(side, x, 11, TEAL)
		_px(side, x, 12, TEAL_DARK)
	for y in 16:
		_px(side, 0, y, WHITE_SHADE)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 8), Vector2i(13, 8)]:
		_px(side, p.x, p.y, SILVER)
	var top := Vector2i(2, 0)
	_rect(top, 0, 0, 15, 15, WHITE, 0.02)
	for i in 16:
		_px(top, i, 7, WHITE_SHADE)
		_px(top, 7, i, WHITE_SHADE)
		_px(top, i, 0, WHITE_SHADE)
		_px(top, 0, i, WHITE_SHADE)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(12, 2), Vector2i(2, 12), Vector2i(12, 12)]:
		_px(top, p.x, p.y, SILVER)


## Floor tiles: light grey squares with lines and little grip dots; the side a tile's edge.
func _floor() -> void:
	var top := Vector2i(3, 0)
	_rect(top, 0, 0, 15, 15, FLOOR, 0.02)
	for i in 16:
		_px(top, i, 0, FLOOR_LINE)
		_px(top, i, 8, FLOOR_LINE)
		_px(top, 0, i, FLOOR_LINE)
		_px(top, 8, i, FLOOR_LINE)
	for y in [3, 5, 11, 13]:
		for x in [3, 5, 11, 13]:
			_px(top, x, y, FLOOR_LINE)
	var side := Vector2i(4, 0)
	_rect(side, 0, 0, 15, 1, FLOOR, 0.02)
	_rect(side, 0, 2, 15, 15, FLOOR_SIDE, 0.025)
	for x in range(0, 16, 8):
		for y in range(2, 16):
			_px(side, x, y, FLOOR_LINE)


## Greenhouse soil: dark rich crumbs with little sprouts on top; the side a white planter's rim over the soil.
func _soil() -> void:
	var top := Vector2i(5, 0)
	_rect(top, 0, 0, 15, 15, SOIL, 0.04)
	for i in 30:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), SOIL_LIGHT)
	for s: Vector2i in [Vector2i(3, 4), Vector2i(10, 3), Vector2i(6, 11), Vector2i(12, 12)]:
		_px(top, s.x, s.y, SPROUT)
		_px(top, s.x + 1, s.y, SPROUT)
		_px(top, s.x, s.y - 1, SPROUT.darkened(0.2))
	var side := Vector2i(6, 0)
	_rect(side, 0, 0, 15, 15, SOIL, 0.04)
	for i in 20:
		_px(side, rng.randi_range(0, 15), rng.randi_range(4, 15), SOIL_LIGHT)
	_rect(side, 0, 0, 15, 2, WHITE, 0.02)
	for x in 16:
		_px(side, x, 3, WHITE_SHADE)
		_px(side, x, 1, TEAL)


## A grow lamp: a dark frame round a pink glow of red and blue lights (plants use red and blue light the most).
func _grow_lamp() -> void:
	var t := Vector2i(7, 0)
	_rect(t, 0, 0, 15, 15, LAMP_GLOW, 0.03)
	_border(t, DARK)
	for y in range(2, 14, 3):
		for x in range(2, 14, 3):
			var c := LAMP_RED if (x + y) % 2 == 0 else LAMP_BLUE
			_px(t, x, y, c)
			_px(t, x + 1, y, c)
			_px(t, x, y + 1, c)
			_px(t, x + 1, y + 1, c.lightened(0.3))


# --- Row 1 ---

## A warm light panel: bright warm white in the middle, golden to its edges, a thin frame.
func _light() -> void:
	var t := Vector2i(0, 1)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length() / 10.6
			_px(t, x, y, WARM.lerp(WARM_EDGE, clampf(d, 0.0, 1.0)))
	_border(t, SILVER_LIGHT)


## Fruit leaves: green leaf clumps with gaps (cut out) and ripe oranges.
func _fruit_leaves() -> void:
	var t := Vector2i(1, 1)
	for y in 16:
		for x in 16:
			var roll := rng.randf()
			if roll < 0.14:
				continue   # a gap: the sky shows through
			_px(t, x, y, LEAF_DARK if roll < 0.35 else (LEAF_LIGHT if roll > 0.85 else LEAF))
	for o: Vector2i in [Vector2i(2, 3), Vector2i(10, 2), Vector2i(6, 9), Vector2i(12, 11)]:
		_px(t, o.x, o.y, ORANGE)
		_px(t, o.x + 1, o.y, ORANGE)
		_px(t, o.x, o.y + 1, ORANGE.darkened(0.1))
		_px(t, o.x + 1, o.y + 1, ORANGE)
		_px(t, o.x, o.y, ORANGE_LIGHT)


## A water tank: a steel frame round glass, clean blue water with bubbles under a light top; its lid a round hatch.
func _water_tank() -> void:
	var side := Vector2i(2, 1)
	_rect(side, 0, 0, 15, 15, GLASS_TINT)
	for y in range(4, 16):
		for x in 16:
			_px(side, x, y, WATER.lerp(WATER_DEEP, (y - 4) / 11.0))
	for x in 16:
		_px(side, x, 4, WATER.lightened(0.35) if x % 4 < 2 else WATER.lightened(0.15))
	for b: Vector2i in [Vector2i(4, 12), Vector2i(5, 9), Vector2i(4, 6), Vector2i(10, 13), Vector2i(11, 10)]:
		_px(side, b.x, b.y, Color.WHITE)
	_border(side, SILVER_DARK)
	for y in [0, 1, 14, 15]:
		_px(side, 7, y, SILVER)
	var top := Vector2i(3, 1)
	_rect(top, 0, 0, 15, 15, SILVER, 0.02)
	_border(top, SILVER_DARK)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 5.0:
				_px(top, x, y, SILVER_DARK)
			if d < 3.8:
				_px(top, x, y, WATER)
	_px(top, 6, 6, WATER.lightened(0.4))


## An ice melter: a white casing with a window: ice over a warm orange coil; on top a grate with ice under it.
func _ice_melter() -> void:
	var side := Vector2i(4, 1)
	_rect(side, 0, 0, 15, 15, WHITE, 0.02)
	_border(side, WHITE_SHADE)
	_rect(side, 3, 3, 12, 12, DARK)
	_rect(side, 4, 4, 11, 8, ICE, 0.03)
	for x in range(4, 12, 3):
		_px(side, x, 8, ICE_SHADE)
		_px(side, x + 1, 7, ICE_SHADE)
	_px(side, 6, 9, WATER)
	_px(side, 9, 9, WATER)
	for x in range(4, 12):
		_px(side, x, 10, COIL if x % 2 == 0 else COIL_HOT)
		_px(side, x, 11, COIL)
	for x in 16:
		_px(side, x, 14, TEAL)
	var top := Vector2i(5, 1)
	_rect(top, 0, 0, 15, 15, ICE, 0.04)
	for i in 12:
		_px(top, rng.randi_range(1, 14), rng.randi_range(1, 14), ICE_SHADE)
	for x in range(0, 16, 3):
		for y in 16:
			_px(top, x, y, DARK)
	_border(top, SILVER_DARK)


## An oxygen maker: white with the brand's teal, two glass tubes full of rising bubbles; on top two teal valves.
func _oxygen_maker() -> void:
	var side := Vector2i(6, 1)
	_rect(side, 0, 0, 15, 15, WHITE, 0.02)
	_border(side, WHITE_SHADE)
	for tube: int in [3, 9]:
		_rect(side, tube, 2, tube + 3, 12, SKY.lightened(0.35))
		_rect(side, tube, 2, tube, 12, SILVER)
		_rect(side, tube + 3, 2, tube + 3, 12, SILVER)
	for b: Vector2i in [Vector2i(5, 11), Vector2i(4, 8), Vector2i(5, 5), Vector2i(4, 3), Vector2i(11, 10), Vector2i(10, 7),
			Vector2i(11, 4)]:
		_px(side, b.x, b.y, Color.WHITE)
	_rect(side, 0, 13, 15, 15, TEAL, 0.02)
	_px(side, 7, 14, GRAPH)
	var top := Vector2i(7, 1)
	_rect(top, 0, 0, 15, 15, WHITE, 0.02)
	_border(top, WHITE_SHADE)
	for c: Vector2i in [Vector2i(4, 5), Vector2i(11, 10)]:
		for y in 16:
			for x in 16:
				var d := Vector2(x - c.x, y - c.y).length()
				if d < 3.0:
					_px(top, x, y, TEAL if d > 1.2 else TEAL_LIGHT)
	for i in range(6, 10):
		_px(top, i, i, SILVER_DARK)


# --- Row 2 ---

## Screens: a dark bezel round a screen with a green graph and bars; the top a grey casing with vents. The big map: a
## globe with its grid and a red "you are here" dot.
func _screens() -> void:
	var s := Vector2i(0, 2)
	_rect(s, 0, 0, 15, 15, DARKER)
	_rect(s, 1, 1, 14, 11, SCREEN)
	var line := [9, 8, 8, 6, 7, 5, 5, 3, 4, 4, 2, 3]
	for i in line.size():
		_px(s, 2 + i, line[i], GRAPH)
	for b in 4:
		_rect(s, 3 + b * 3, 11 - (b + 1), 4 + b * 3, 10, [YELLOW, SKY, GRAPH, TEAL_LIGHT][b])
	_rect(s, 2, 13, 13, 14, SILVER_DARK)
	_px(s, 12, 13, GRAPH)
	_px(s, 13, 13, RED)
	var top := Vector2i(1, 2)
	_rect(top, 0, 0, 15, 15, SILVER_DARK, 0.02)
	for y in range(3, 13, 3):
		_rect(top, 3, y, 12, y, DARK)
	_border(top, DARK)
	var m := Vector2i(2, 2)
	_rect(m, 0, 0, 15, 15, MAP_BG)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5)
			if d.length() < 6.5:
				var lat := absf(y - 7.5) < 0.6 or absf(absf(y - 7.5) - 3.5) < 0.5
				var lon := absf(x - 7.5) < 0.6 or absf(absf(x - 7.5) - sqrt(maxf(42.25 - d.y * d.y, 0.0)) * 0.55) < 0.5
				_px(m, x, y, SKY if lat or lon else Color("1f4a8a"))
			elif d.length() < 7.2:
				_px(m, x, y, SKY)
	_px(m, 9, 5, RED)
	_px(m, 10, 5, RED)
	_px(m, 9, 6, RED)
	for i in 4:
		_px(m, 2 + i * 2, 13 - i, YELLOW)
	_border(m, DARKER)


## Airlock frames: white with teal-and-white chevrons and a green light; the top the stripes straight.
func _airlock() -> void:
	var side := Vector2i(3, 2)
	for y in 16:
		for x in 16:
			_px(side, x, y, TEAL if posmod(x + y, 8) < 4 else WHITE)
	_rect(side, 0, 0, 15, 1, SILVER_DARK)
	_rect(side, 0, 14, 15, 15, SILVER_DARK)
	_rect(side, 6, 0, 9, 1, GRAPH)
	var top := Vector2i(4, 2)
	for y in 16:
		for x in 16:
			_px(top, x, y, TEAL if posmod(x, 8) < 4 else WHITE)
	_border(top, SILVER_DARK)


## Rocket steel: shiny, lit in the middle, with panel seams and rivets; its top a round seam.
func _hull() -> void:
	var side := Vector2i(5, 2)
	for y in 16:
		for x in 16:
			var k := 1.0 - 0.2 * pow(absf((x + 0.5) / 16.0 - 0.42) * 2.0, 2.0)
			var c := SILVER.lerp(SILVER_LIGHT, 0.45)
			_px(side, x, y, _vary(Color(c.r * k, c.g * k, c.b * k), 0.015))
	for x in 16:
		_px(side, x, 0, SILVER_DARK)
		_px(side, x, 8, SILVER_DARK)
		if x % 4 == 2:
			_px(side, x, 2, SILVER_DARK)
			_px(side, x, 10, SILVER_DARK)
	_rect(side, 11, 3, 11, 6, Color.WHITE)
	var top := Vector2i(6, 2)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(top, x, y, _vary(SILVER_LIGHT if d < 4.0 else SILVER, 0.015))
			if absf(d - 6.0) < 0.5:
				_px(top, x, y, SILVER_DARK)


## Printed regolith: planet dust printed in layers (a robot's work), a warm grey; its top the printer's round path.
func _regolith() -> void:
	var side := Vector2i(7, 2)
	for y in 16:
		for x in 16:
			var band := (y / 2) % 2 == 0
			_px(side, x, y, _vary(REGOLITH if band else REGOLITH_DARK, 0.03))
		if y % 2 == 1:
			for x in 16:
				if rng.randf() < 0.3:
					_px(side, x, y, REGOLITH_DARK.darkened(0.1))
	var top := Vector2i(0, 3)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(top, x, y, _vary(REGOLITH if int(d) % 2 == 0 else REGOLITH_DARK, 0.03))


# --- Row 3 ---

## A table: a white top on two silver legs (cut out between them); its top white with a teal edge; underneath the legs.
func _table() -> void:
	var side := Vector2i(1, 3)
	_rect(side, 0, 0, 15, 2, WHITE, 0.02)
	for x in 16:
		_px(side, x, 2, WHITE_SHADE)
		_px(side, x, 0, TEAL)
	for leg: int in [1, 13]:
		_rect(side, leg, 3, leg + 1, 15, SILVER)
		_rect(side, leg, 3, leg, 15, SILVER_LIGHT)
	var top := Vector2i(2, 3)
	_rect(top, 0, 0, 15, 15, WHITE, 0.02)
	_border(top, TEAL)
	var under := Vector2i(3, 3)
	_rect(under, 0, 0, 15, 15, WHITE_SHADE, 0.02)
	for c: Vector2i in [Vector2i(1, 1), Vector2i(13, 1), Vector2i(1, 13), Vector2i(13, 13)]:
		_rect(under, c.x, c.y, c.x + 1, c.y + 1, SILVER)
