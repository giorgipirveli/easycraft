extends SceneTree
## Generates data/blocks/pages/smart.png (M3 Task 7): block atlas page 9, an 8 x 8 grid of 16 x 16 pixel-art
## tiles for the smart blocks and Game Blocks. Its realistic twin is tools/make_smart_page.py (same layout).
## Run: godot --headless --path . --script res://tools/make_smart_page.gd
## Tile coordinates must match data/blocks/smart_page.gd TILES:
##   (0, 0) button side, (1, 0) button top, (2, 0) pressed button side, (3, 0) pressed button top (lit)
##   (4, 0) lever side (down), (5, 0) lever top, (6, 0) lever side (up, lit), (7, 0) lever top (lit)
##   (0, 1) powered door (a steel door with a lightning bolt), (1, 1) open powered door (a cut-out frame)
##   (2, 1) lamp (dark glass in a cage), (3, 1) lit lamp
##   (4, 1) light switch (down), (5, 1) light switch (up, lit)
##   (6, 1) teleport pad top (a cyan swirl), (7, 1) teleport pad side
##   (0, 2) START top (a white arrow on green), (1, 2) START side (green and white stripes)
##   (2, 2) checkpoint top (a flag on blue), (3, 2) checkpoint side
##   (4, 2) FINISH top (a chequered flag board), (5, 2) FINISH side (a chequered band)
##   (6, 2) coin (a golden coin with a star, cut out), (7, 2) bounce pad top (a trampoline)
##   (0, 3) bounce pad side (springs), (1, 3) the metal base plate
## Free tiles: the rest.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/smart.png"
const METAL := Color("5d6776")
const METAL_DARK := Color("3a414c")
const METAL_LIGHT := Color("8b97a7")
const RED := Color("e5484d")
const RED_DARK := Color("9e2a2f")
const GREEN := Color("4ade80")
const GREEN_DARK := Color("1f9d55")
const WOOD := Color("b07a3a")
const WOOD_DARK := Color("7a5124")
const GOLD := Color("ffd23f")
const GOLD_DARK := Color("c9971e")
const WHITE := Color("f4f6f8")
const CYAN := Color("5ee7ff")
const CYAN_DARK := Color("1d3b4a")
const BLUE := Color("3b82f6")
const BLUE_DARK := Color("1e4fae")
const START_GREEN := Color("3fbf5f")
const START_DARK := Color("23823b")
const BLACK := Color("1c1f24")
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260926
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	_button(Vector2i(0, 0), Vector2i(1, 0), RED, RED_DARK, false)
	_button(Vector2i(2, 0), Vector2i(3, 0), GREEN, GREEN_DARK, true)
	_lever_side(Vector2i(4, 0), false)
	_lever_top(Vector2i(5, 0), false)
	_lever_side(Vector2i(6, 0), true)
	_lever_top(Vector2i(7, 0), true)
	_door(Vector2i(0, 1))
	_open_door(Vector2i(1, 1))
	_lamp(Vector2i(2, 1), false)
	_lamp(Vector2i(3, 1), true)
	_switch(Vector2i(4, 1), false)
	_switch(Vector2i(5, 1), true)
	_teleport_top(Vector2i(6, 1))
	_teleport_side(Vector2i(7, 1))
	_start_top(Vector2i(0, 2))
	_stripes(Vector2i(1, 2), START_GREEN, WHITE)
	_checkpoint_top(Vector2i(2, 2))
	_stripes(Vector2i(3, 2), BLUE, WHITE)
	_finish_top(Vector2i(4, 2))
	_finish_side(Vector2i(5, 2))
	_coin(Vector2i(6, 2))
	_bounce_top(Vector2i(7, 2))
	_bounce_side(Vector2i(0, 3))
	_plate(Vector2i(1, 3))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(ProjectSettings.globalize_path(OUT))
	print("SMART_PAGE saved %s err=%d" % [OUT, err])
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE and y < TILE:
		img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _rect(t: Vector2i, from: Vector2i, to: Vector2i, c: Color) -> void:
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			_px(t, x, y, c)


func _disc(t: Vector2i, center: Vector2, r: float, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= r:
				_px(t, x, y, c)


## Brushed metal with a darker rim and four rivets.
func _plate(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var rim := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			var c := METAL_DARK if rim else (METAL_LIGHT if y == 1 or x == 1 else METAL)
			_px(t, x, y, _vary(c, 0.025))
	for p: Vector2i in [Vector2i(3, 3), Vector2i(12, 3), Vector2i(3, 12), Vector2i(12, 12)]:
		_px(t, p.x, p.y, METAL_LIGHT)
		_px(t, p.x + 1, p.y + 1, METAL_DARK)


## A big round button on a plate: the side shows it from the front, the top from above.
func _button(side: Vector2i, top: Vector2i, c: Color, dark: Color, lit: bool) -> void:
	for t in [side, top]:
		_plate(t)
		_disc(t, Vector2(8, 8), 5.6, dark)
		_disc(t, Vector2(8, 7.4 if not lit else 8.0), 4.6, c)
		_disc(t, Vector2(6.6, 6.0), 1.4, c.lightened(0.45))
		if lit:
			for p: Vector2i in [Vector2i(8, 1), Vector2i(8, 14), Vector2i(1, 8), Vector2i(14, 8)]:
				_px(t, p.x, p.y, GOLD)


## A lever: a wooden handle pointing down-left (off) or up-right (on, a green knob).
func _lever_side(t: Vector2i, on: bool) -> void:
	_plate(t)
	_rect(t, Vector2i(5, 11), Vector2i(10, 13), METAL_DARK)          # the pivot base
	var knob := GREEN if on else RED
	for i in 7:
		var x := 7 + (i if on else -i) / 2
		var y := 11 - i
		_px(t, x, y, WOOD)
		_px(t, x + 1, y, WOOD_DARK)
	var kx := 10 if on else 4
	_disc(t, Vector2(kx + 0.5, 4.5), 2.0, knob)
	_px(t, kx, 3, knob.lightened(0.5))


func _lever_top(t: Vector2i, on: bool) -> void:
	_plate(t)
	_rect(t, Vector2i(6, 4), Vector2i(9, 11), METAL_DARK)             # the slot
	_disc(t, Vector2(8, 5.5 if on else 10.5), 2.2, GREEN if on else RED)


## A steel door with a yellow lightning bolt (it opens with power).
func _door(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var frame := x <= 1 or x >= 14 or y <= 1 or y >= 14
			var panel := (y == 7 or y == 8) and not frame
			_px(t, x, y, _vary(METAL_DARK if frame else (METAL if not panel else METAL_LIGHT), 0.02))
	for p: Vector2i in [Vector2i(8, 3), Vector2i(7, 4), Vector2i(6, 5), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6),
			Vector2i(8, 7), Vector2i(7, 8), Vector2i(8, 9), Vector2i(9, 9), Vector2i(8, 10), Vector2i(7, 11), Vector2i(6, 12)]:
		_px(t, p.x, p.y, GOLD)
	_px(t, 12, 8, GOLD_DARK)                                         # the handle


## The open door: steel posts and a lintel round an empty middle (drawn cut out).
func _open_door(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			if x <= 1 or x >= 14 or y <= 1:
				_px(t, x, y, _vary(METAL_DARK if x == 0 or x == 15 or y == 0 else METAL, 0.02))
	_px(t, 7, 1, GOLD)
	_px(t, 8, 1, GOLD)


## A lamp: glass in a dark cage, grey (off) or bright yellow with a white heart (on, drawn unshaded).
func _lamp(t: Vector2i, on: bool) -> void:
	var glass := Color("fff0a0") if on else Color("6f7c86")
	var heart := WHITE if on else Color("8a98a3")
	for y in TILE:
		for x in TILE:
			var cage := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1 or x == 5 or x == 10 or y == 5 or y == 10
			_px(t, x, y, METAL_DARK if cage else _vary(glass, 0.03))
	_disc(t, Vector2(8, 8), 2.2, heart)


## A light switch: a white plate with a toggle down (off) or up and a warm glow (on).
func _switch(t: Vector2i, on: bool) -> void:
	_plate(t)
	_rect(t, Vector2i(4, 2), Vector2i(11, 13), WHITE)
	_rect(t, Vector2i(6, 5), Vector2i(9, 10), Color("c7ccd3"))
	if on:
		_rect(t, Vector2i(6, 5), Vector2i(9, 7), GOLD)
	else:
		_rect(t, Vector2i(6, 8), Vector2i(9, 10), Color("8a929c"))


## A teleport pad: a cyan ring of light swirling on a dark disc.
func _teleport_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x + 0.5, y + 0.5) - Vector2(8, 8)
			var swirl := sin(atan2(d.y, d.x) * 3.0 + d.length() * 1.1)
			var c := CYAN_DARK.lerp(CYAN, clampf(swirl * 0.5 + 0.5, 0, 1) * clampf(1.0 - absf(d.length() - 5.0) / 3.0, 0, 1))
			_px(t, x, y, c)
	_disc(t, Vector2(8, 8), 1.6, WHITE)


func _teleport_side(t: Vector2i) -> void:
	_plate(t)
	_rect(t, Vector2i(0, 0), Vector2i(15, 3), CYAN_DARK)
	for x in range(1, 15, 3):
		_px(t, x, 1, CYAN)
		_px(t, x + 1, 2, CYAN)


## START: a big white arrow on green.
func _start_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var rim := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			_px(t, x, y, _vary(START_DARK if rim else START_GREEN, 0.02))
	for y in range(3, 13):                                            # a triangle pointing right
		var w := 6 - absi(y - 8)
		for x in range(4, 4 + maxi(w, 0) * 2):
			_px(t, x, y, WHITE)


## Two-colour diagonal stripes (the side of START and CHECKPOINT).
func _stripes(t: Vector2i, a: Color, b: Color) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(a if ((x + y) / 4) % 2 == 0 else b, 0.02))
	for x in TILE:
		_px(t, x, 0, a.darkened(0.3))
		_px(t, x, TILE - 1, a.darkened(0.3))


## CHECKPOINT: a white flag on a pole, on blue.
func _checkpoint_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var rim := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			_px(t, x, y, _vary(BLUE_DARK if rim else BLUE, 0.02))
	_rect(t, Vector2i(4, 2), Vector2i(4, 13), WHITE)
	for y in range(2, 8):
		for x in range(5, 5 + 7 - absi(y - 5)):
			_px(t, x, y, GOLD)


## FINISH: a chequered board.
func _finish_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, BLACK if ((x / 4) + (y / 4)) % 2 == 0 else WHITE)


func _finish_side(t: Vector2i) -> void:
	_plate(t)
	for y in range(2, 10):
		for x in TILE:
			_px(t, x, y, BLACK if ((x / 2) + (y / 2)) % 2 == 0 else WHITE)


## A golden coin with a star, floating (the rest of the tile is cut out).
func _coin(t: Vector2i) -> void:
	_disc(t, Vector2(8, 8), 6.2, GOLD_DARK)
	_disc(t, Vector2(8, 8), 5.0, GOLD)
	for p: Vector2i in [Vector2i(8, 4), Vector2i(8, 5), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6), Vector2i(5, 7),
			Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 7), Vector2i(10, 7), Vector2i(11, 7), Vector2i(6, 8),
			Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8), Vector2i(7, 9), Vector2i(9, 9), Vector2i(6, 10),
			Vector2i(10, 10)]:
		_px(t, p.x, p.y, WHITE.lerp(GOLD, 0.25))
	_px(t, 5, 5, WHITE)


## A trampoline: a dark springy net inside a red and blue rim.
func _bounce_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var rim := x <= 1 or y <= 1 or x >= TILE - 2 or y >= TILE - 2
			var c := (RED if ((x + y) / 3) % 2 == 0 else BLUE) if rim else (BLACK if (x + y) % 2 == 0 else Color("2c313a"))
			_px(t, x, y, c)
	_disc(t, Vector2(8, 8), 1.5, Color("4a525e"))


## The trampoline's side: a red frame on zig-zag springs.
func _bounce_side(t: Vector2i) -> void:
	_plate(t)
	_rect(t, Vector2i(0, 0), Vector2i(15, 3), RED)
	for x in TILE:
		_px(t, x, 4 + (x % 4 if x % 8 < 4 else 3 - x % 4) * 2, METAL_LIGHT)
		_px(t, x, 5 + (x % 4 if x % 8 < 4 else 3 - x % 4) * 2, METAL_LIGHT)
	_rect(t, Vector2i(0, 13), Vector2i(15, 15), METAL_DARK)
