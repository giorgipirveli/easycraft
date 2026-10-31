extends SceneTree
## Generates the rocket parts' pixel block page (spec §21d.2; owner #78, #79): data/blocks/pages/rockets.png, page 32
## (data/blocks/rocket_page.gd TILES), an 8 x 8 grid of 16 x 16 tiles in the style of tools/make_space_atlas.gd
## (original work, its own RNG seed). Our own look (spec §3c): white and silver parts with the brand's teal bands, a red
## nose and fins, golden space-engine bells, blue solar cells, a concrete pad with yellow-and-black stripes. Engines, the
## nose cone, the capsule, the legs and the fins are cut out (their shapes: a bell, a cone, a leg, a fin).
## Its realistic twin is tools/make_rocket_realistic.py (the same layout).
## Run: godot --headless --path . --script res://tools/make_rocket_page.gd   (then godot --headless --path . --import)

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/rockets.png"
const SEED := 20260932

const WHITE := Color("f4f6f8")
const WHITE_SHADE := Color("d3dae3")
const SILVER := Color("b9c2cc")
const SILVER_LIGHT := Color("dfe5ec")
const SILVER_DARK := Color("8b95a2")
const DARK := Color("3b404b")
const DARKER := Color("262a33")
const RED := Color("e0413a")
const RED_DARK := Color("b12e29")
const ORANGE := Color("f08a1c")
const YELLOW := Color("ffd23f")
const TEAL := Color("139e9b")            # the brand's teal (spec §3c)
const TEAL_DARK := Color("0c7876")
const GOLD := Color("f0cf7a")
const GOLD_DARK := Color("c99a3c")
const GOLD_LIGHT := Color("fff0bf")
const GLASS := Color("5aa9f0")
const GLASS_LIGHT := Color("d6efff")
const CELL := Color("2b4c9b")
const CELL_LIGHT := Color("4a78d8")
const SHIELD := Color("5b3a28")
const SHIELD_LIGHT := Color("7a5038")
const CONCRETE := Color("b9b8b1")
const CONCRETE_DARK := Color("9a9992")
const BLACK := Color("25262b")
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	_engines()
	_tank()
	_nose()
	_capsule()
	_service_module()
	_heat_shield()
	_legs()
	_fins()
	_separator()
	_solar()
	_parachute()
	_pad()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/blocks/pages/"))
	var err := img.save_png(OUT)
	print("ROCKET_PAGE saved err=%d" % err)
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


## A round part's side: light in the middle, darker to the edges (x from 0 to 15 across the width).
func _round_shade(c: Color, x: int, x0: int, x1: int) -> Color:
	var w := maxf(float(x1 - x0), 1.0)
	var u := (float(x - x0) + 0.5) / (w + 1.0)
	var k := 1.0 - 0.28 * pow(absf(u - 0.42) * 2.0, 2.0)
	return Color(c.r * k, c.g * k, c.b * k, c.a)


# --- Engines (row 0) ---

func _engines() -> void:
	# kerosene engine: a dark plate on top with bolts
	var top := Vector2i(0, 0)
	_rect(top, 0, 0, 15, 15, SILVER_DARK, 0.03)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 6.5:
				_px(top, x, y, _vary(DARK, 0.03))
			if d < 2.5:
				_px(top, x, y, SILVER)
	for b: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		_px(top, b.x, b.y, DARKER)
	_bell(Vector2i(1, 0), 4, 3, DARK, SILVER, SILVER_DARK)
	_nozzle(Vector2i(2, 0), DARK, DARKER, SILVER_DARK)
	# space engine: a small housing and a very wide golden bell
	var stop := Vector2i(3, 0)
	_rect(stop, 0, 0, 15, 15, GOLD_DARK, 0.03)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 6.5:
				_px(stop, x, y, _vary(GOLD, 0.03))
			if d < 2.5:
				_px(stop, x, y, SILVER)
	_bell(Vector2i(4, 0), 2, 2, GOLD, SILVER_LIGHT, GOLD_DARK)
	_nozzle(Vector2i(5, 0), GOLD, DARKER, GOLD_DARK)


## An engine's side: a housing (rows 0 … housing-1), a throat `throat` px wide each side of the middle, then the bell
## flaring to the full width at the bottom row; the rest is cut out.
func _bell(t: Vector2i, housing: int, throat: int, bell: Color, box: Color, band: Color) -> void:
	for y in housing:
		for x in 16:
			var c := box if y > 0 else SILVER_LIGHT
			if x % 5 == 2:
				c = band   # pipes down the housing
			_px(t, x, y, _vary(c, 0.03))
	for y in range(housing, 16):
		var k := float(y - housing) / float(15 - housing)
		var half := lerpf(float(throat), 8.0, pow(k, 1.6))
		var x0 := int(round(7.5 - half + 0.5))
		var x1 := int(round(7.5 + half - 0.5))
		for x in range(x0, x1 + 1):
			var c := _round_shade(bell, x, x0, x1)
			if (x - x0) % 3 == 0 and y < 15:
				c = c.darkened(0.12)   # the cooling tubes
			if y == 15:
				c = band.lightened(0.15)   # the bell's rim
			_px(t, x, y, _vary(c, 0.02))


## An engine seen from below: the bell's round mouth, dark inside.
func _nozzle(t: Vector2i, rim: Color, inside: Color, ring: Color) -> void:
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 8.0:
				_px(t, x, y, _vary(rim, 0.03))
			if d < 6.5:
				_px(t, x, y, ring)
			if d < 5.5:
				_px(t, x, y, _vary(inside, 0.02))


# --- The tank (row 0) ---

func _tank() -> void:
	var top := Vector2i(6, 0)
	_rect(top, 0, 0, 15, 15, WHITE_SHADE, 0.02)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.5:
				var k := 1.0 - 0.12 * d / 7.5
				_px(top, x, y, _vary(Color(WHITE.r * k, WHITE.g * k, WHITE.b * k), 0.015))
			if d < 1.6:
				_px(top, x, y, SILVER_DARK)
	var side := Vector2i(7, 0)
	for y in 16:
		for x in 16:
			var c := _round_shade(WHITE, x, 0, 15)
			if y == 0 or y == 15:
				c = WHITE_SHADE
			elif y == 11 or y == 12:
				c = _round_shade(TEAL, x, 0, 15)   # the brand's band
			elif y == 5 and x % 4 == 1:
				c = SILVER_DARK   # a seam's rivets
			_px(side, x, y, _vary(c, 0.012))


# --- The nose cone and the capsule (row 1) ---

func _nose() -> void:
	var side := Vector2i(0, 1)
	for y in 16:
		var half := lerpf(0.9, 8.0, float(y) / 15.0)
		var x0 := int(round(7.5 - half + 0.5))
		var x1 := int(round(7.5 + half - 0.5))
		for x in range(x0, x1 + 1):
			var c := _round_shade(RED if y < 5 else WHITE, x, x0, x1)
			if y == 5:
				c = RED_DARK
			_px(side, x, y, _vary(c, 0.015))
	var top := Vector2i(1, 1)
	for y in 16:
		for x in 16:
			if Vector2(x - 7.5, y - 7.5).length() < 1.8:
				_px(top, x, y, RED)
	_rect(Vector2i(2, 1), 0, 0, 15, 15, WHITE_SHADE, 0.02)


func _capsule() -> void:
	var side := Vector2i(3, 1)
	for y in 16:
		var half := lerpf(4.0, 8.0, float(y) / 15.0)
		var x0 := int(round(7.5 - half + 0.5))
		var x1 := int(round(7.5 + half - 0.5))
		for x in range(x0, x1 + 1):
			var c := _round_shade(SILVER_LIGHT, x, x0, x1)
			if y >= 14:
				c = SHIELD   # the heat shield's edge under it
			elif y == 2:
				c = TEAL
			_px(side, x, y, _vary(c, 0.015))
	for y in 16:   # the round window
		for x in 16:
			var d := Vector2(x - 7.5, y - 8.0).length()
			if d < 3.2:
				_px(side, x, y, SILVER_DARK)
			if d < 2.3:
				_px(side, x, y, GLASS)
	_px(side, 6, 7, GLASS_LIGHT)
	_px(side, 7, 7, GLASS_LIGHT)
	_px(side, 6, 8, GLASS_LIGHT)
	var top := Vector2i(4, 1)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 4.2:
				_px(top, x, y, _vary(SILVER_LIGHT, 0.02))
			if d < 2.6 and d > 1.6:
				_px(top, x, y, SILVER_DARK)   # the hatch
	_rect(Vector2i(5, 1), 0, 0, 15, 15, SHIELD, 0.03)


func _service_module() -> void:
	var side := Vector2i(6, 1)
	for y in 16:
		for x in 16:
			var c := _round_shade(SILVER, x, 0, 15)
			if y <= 1:
				c = _round_shade(TEAL, x, 0, 15)
			elif x % 4 == 1 and y > 3 and y < 14:
				c = c.lightened(0.18)   # radiator panels
			elif y == 15:
				c = SILVER_DARK
			_px(side, x, y, _vary(c, 0.015))
	for q: Vector2i in [Vector2i(3, 6), Vector2i(12, 6)]:   # the little steering thrusters
		_rect(side, q.x - 1, q.y - 1, q.x + 1, q.y + 1, DARK)
	var top := Vector2i(7, 1)
	_rect(top, 0, 0, 15, 15, SILVER_DARK, 0.02)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			if d < 7.5:
				_px(top, x, y, _vary(SILVER, 0.02))
			if d < 5.0 and int(round(atan2(y - 7.5, x - 7.5) * 4.0 / PI)) % 2 == 0 and d > 4.0:
				_px(top, x, y, DARK)


# --- The heat shield, legs, fins and separator (row 2) ---

func _heat_shield() -> void:
	var side := Vector2i(0, 2)
	for y in 16:
		for x in 16:
			var c := SHIELD
			if y <= 3:
				c = _round_shade(SILVER, x, 0, 15)
			elif (x + y) % 4 == 0 or posmod(x - y, 4) == 0:
				c = SHIELD_LIGHT   # the tiles' lattice
			_px(side, x, y, _vary(c, 0.02))
	var face := Vector2i(1, 2)
	for y in 16:
		for x in 16:
			var c := SHIELD
			if (x + y) % 4 == 0 or posmod(x - y, 4) == 0:
				c = SHIELD_LIGHT
			if Vector2(x - 7.5, y - 7.5).length() > 7.2:
				c = SHIELD.darkened(0.2)
			_px(face, x, y, _vary(c, 0.02))


func _legs() -> void:
	var side := Vector2i(2, 2)
	_rect(side, 0, 0, 3, 2, DARK)   # the hinge on the lander
	for i in 13:   # the strut, from the hinge down and out
		var x := 1 + i
		var y := 2 + i
		for w in [-1, 0]:
			_px(side, x + w, y, _round_shade(SILVER_LIGHT, w + 1, 0, 1))
	_rect(side, 6, 7, 8, 9, SILVER_DARK)   # the shock absorber
	_rect(side, 9, 14, 15, 15, GOLD)   # the footpad
	_rect(side, 10, 13, 14, 13, GOLD_DARK)
	var top := Vector2i(3, 2)
	_rect(top, 1, 7, 14, 8, SILVER)
	_rect(top, 11, 6, 14, 9, GOLD)


func _fins() -> void:
	var side := Vector2i(4, 2)
	for y in range(2, 16):
		var half := lerpf(0.8, 8.0, float(y - 2) / 13.0)
		var x0 := int(round(7.5 - half + 0.5))
		var x1 := int(round(7.5 + half - 0.5))
		for x in range(x0, x1 + 1):
			var c := RED if y < 14 else RED_DARK
			if x == x0 or x == x1:
				c = WHITE   # the edge stripe
			_px(side, x, y, _vary(c, 0.02))
	var top := Vector2i(5, 2)
	_rect(top, 0, 7, 15, 8, RED)
	_rect(top, 7, 0, 8, 15, RED)


func _separator() -> void:
	var side := Vector2i(6, 2)
	for y in 16:
		for x in 16:
			var c := _round_shade(SILVER, x, 0, 15)
			if y >= 6 and y <= 9:
				c = YELLOW if ((x + y) / 2) % 2 == 0 else BLACK   # the ring's warning stripes
			elif (y == 3 or y == 12) and x % 3 == 1:
				c = DARK   # bolts
			_px(side, x, y, _vary(c, 0.015))
	var top := Vector2i(7, 2)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := SILVER_DARK
			if d < 7.6:
				c = SILVER
			if d < 5.4:
				c = DARK
			if d < 5.4 and d > 4.4:
				c = YELLOW
			_px(top, x, y, _vary(c, 0.015))


# --- Solar array, parachute, the pad (row 3) ---

func _solar() -> void:
	for t: Vector2i in [Vector2i(0, 3), Vector2i(1, 3)]:
		var light := t.x == 1
		for y in 16:
			for x in 16:
				var c := CELL_LIGHT if light else CELL
				if x % 5 == 0 or y % 5 == 0:
					c = DARKER   # the cells' lines
				if x == 0 or y == 0 or x == 15 or y == 15:
					c = GOLD
				_px(t, x, y, _vary(c, 0.02))
		_px(t, 3, 3, GLASS_LIGHT)
		_px(t, 8, 8, GLASS_LIGHT)


func _parachute() -> void:
	var side := Vector2i(2, 3)
	for y in 16:
		for x in 16:
			var c := _round_shade(WHITE, x, 0, 15)
			if y <= 2:
				c = _round_shade(SILVER, x, 0, 15)
			elif y >= 4 and y <= 12:
				c = _round_shade(ORANGE if (x / 2) % 2 == 0 else WHITE, x, 0, 15)
			_px(side, x, y, _vary(c, 0.015))
	var top := Vector2i(3, 3)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := SILVER_DARK
			if d < 7.6:
				var wedge := int(floor((atan2(y - 7.5, x - 7.5) + PI) / (PI / 4.0)))
				c = ORANGE if wedge % 2 == 0 else WHITE
			if d < 1.5:
				c = SILVER
			_px(top, x, y, _vary(c, 0.015))


func _pad() -> void:
	var concrete := Vector2i(4, 3)
	for y in 16:
		for x in 16:
			var c := _vary(CONCRETE, 0.035)
			if x == 15 or y == 15:
				c = CONCRETE_DARK   # the slabs' joints
			_px(concrete, x, y, c)
	var stripe := Vector2i(5, 3)
	for y in 16:
		for x in 16:
			_px(stripe, x, y, _vary(YELLOW if ((x + y) / 4) % 2 == 0 else BLACK, 0.02))
	var stripe_side := Vector2i(6, 3)
	for y in 16:
		for x in 16:
			var c := _vary(CONCRETE, 0.035)
			if y <= 3:
				c = _vary(YELLOW if ((x + y) / 4) % 2 == 0 else BLACK, 0.02)
			_px(stripe_side, x, y, c)
	var base := Vector2i(7, 3)
	for y in 16:
		for x in 16:
			var c := _vary(CONCRETE_DARK if y > 11 else CONCRETE, 0.035)
			if x == 15:
				c = CONCRETE_DARK
			_px(base, x, y, c)
