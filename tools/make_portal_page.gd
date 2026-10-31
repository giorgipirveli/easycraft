extends SceneTree
## Generates data/blocks/pages/portals.png (M3 Task 5): block atlas page 5, an 8 x 8 grid of 16 x 16
## pixel-art tiles. Its realistic twin is tools/make_portal_page.py (same layout).
## Run: godot --headless --path . --script res://tools/make_portal_page.gd
## Tile coordinates must match data/blocks/portal_page.gd TILES:
##   Owner #43 (our own look, spec §3c): portals are golden and rainbow, never purple swirls in dark frames:
##   (0, 0) portal frame side: golden blocks with a column of rainbow gems down the middle
##   (1, 0) portal frame top/bottom: the same gold, a ring of rainbow gems
##   (2, 0) portal core side: a rainbow swirl gem in a golden setting (drawn unshaded in the game)
##   (3, 0) portal core top/bottom: a four-pointed star on rainbow gold
##   Row 6 (spec §12.19, drawn by _crafting_tiles with its own RNG, so the tiles above stay the same; owner #43: our
##   own Workbench and Clay Oven, not a crafting table and a furnace):
##   (0, 6) Workbench top: a wooden rim round a teal painted mat with a golden star stamp and three paint pots;
##   (1, 6) its side: a teal band, paint drips and two drawers with round brass knobs; (2, 6) planks (its
##   underside, unchanged); (3, 6) Clay Oven top and bottom: terracotta tiles round a chimney hole; (4, 6) its side:
##   a clay dome front with a round window of fire.
## M3 Task 14a (drawn after the portal tiles, with their own RNG seed, so the tiles above stay the same):
##   (4, 0) zipline post side: a wooden post, a yellow-and-black band, a little pulley wheel
##   (5, 0) zipline post top/bottom: the post's end grain under a round metal cap
##   (6, 0) launch pad top: orange chevrons pointing up on a dark plate (drawn unshaded in the game)
##   (7, 0) launch pad side/bottom: a dark metal side with orange and black hazard stripes
## Free tiles: the rest (page 10, ids 208-223: M3 Tasks 5, 14a, 20a, 21b, 21c).
##   (0, 2) saddle top (M3 Task 20a): a brown leather seat with a pommel in front, stitching and gold rivets
##   (1, 2) saddle side and bottom: a leather flap with a strap, a gold buckle and a stirrup
## Owner 39 (drawn last, with their own RNG seed): the universe portal cores, each the core's gem in its universe's
##   colours (CrystalRules.SWIRLS): side (the gem in a golden setting) then top (a star): 212 meadows (0, 1)/(1, 1),
##   213 desert (2, 1)/(3, 1), 214 frost (4, 1)/(5, 1), 215 candy (6, 1)/(7, 1), 222 dragon (4, 3)/(5, 3).
## M3 Task 21b (drawn last, with their own RNG seed): 217 trophy shelf side (2, 2) (a wooden frame round two open,
##   see-through shelves) and top (3, 2) (planks); 218 bookshelf side (4, 2) (the frame full of books) and top (5, 2).
## Free tiles: the rest (page 10, ids 208-223). Owners draw their tiles after the others' (the RNG stays in
## step): two tiles per id, tile index 2 × (id − 208), so SADDLE 216 has (0, 2) and (1, 2).

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/pages/portals.png"
# Owner #43: gold and rainbow (the frame's blocks, the cores' settings; STONE_* keep their old names)
const STONE := Color("e2a933")
const STONE_DARK := Color("a8701a")
const STONE_LIGHT := Color("ffd764")
const GEM_HEART := Color("fffbe8")
## The rainbow's gems, in order (no purple: the portals' old colour).
const RAINBOW: Array[Color] = [Color("ff5a5a"), Color("ffa23a"), Color("ffe14d"), Color("5ad66a"), Color("4aa8ff"),
	Color("ff7ac8")]

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260925
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_frame_side(Vector2i(0, 0))
	_frame_top(Vector2i(1, 0))
	_core_side(Vector2i(2, 0))
	_core_top(Vector2i(3, 0))
	_crafting_tiles()   # spec §12.19: row 6
	rng.seed = 20260926   # M3 Task 14a's tiles
	_post_side(Vector2i(4, 0))
	_post_top(Vector2i(5, 0))
	_pad_top(Vector2i(6, 0))
	_pad_side(Vector2i(7, 0))
	_saddle_top(Vector2i(0, 2))    # M3 Task 20a
	_saddle_side(Vector2i(1, 2))
	_universe_cores()   # owner 39: the universe portal cores (their own seed)
	_book_tiles()   # M3 Task 21b: the trophy shelf and the bookshelf (their own seed)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(ProjectSettings.globalize_path(OUT))
	print("PORTAL_PAGE saved %s err=%d" % [OUT, err])
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## Golden blocks in two courses: darker joints, a lighter top edge on each block (owner #43).
func _stone(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var course := y / 8
			var shift := 4 if course == 1 else 0
			var mortar := y % 8 == 7 or (x + shift) % 8 == 7
			var c := STONE_DARK if mortar else (STONE_LIGHT if y % 8 == 0 else STONE)
			_px(t, x, y, _vary(c, 0.035))


## A round gem of 2 x 2 pixels with a light corner (a rainbow gem set in the gold).
func _gem(t: Vector2i, x: int, y: int, c: Color) -> void:
	_px(t, x, y, c.lightened(0.45))
	_px(t, x + 1, y, c)
	_px(t, x, y + 1, c)
	_px(t, x + 1, y + 1, c.darkened(0.25))


func _frame_side(t: Vector2i) -> void:
	_stone(t)
	for i in 6:                                                   # a column of rainbow gems down the middle
		_gem(t, 7, 1 + i * 2 + i / 3, RAINBOW[i])


func _frame_top(t: Vector2i) -> void:
	_stone(t)
	for i in 12:                                                  # a ring of rainbow gems
		var a := TAU * i / 12.0
		_px(t, 7 + roundi(cos(a) * 4.5), 7 + roundi(sin(a) * 4.5), RAINBOW[i % RAINBOW.size()])
	_px(t, 7, 7, GEM_HEART)
	_px(t, 8, 8, GEM_HEART)


## The plain portal's core: a swirl gem whose arms run through the rainbow, in a golden setting.
func _core_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			_px(t, x, y, _vary(STONE_DARK if edge else STONE, 0.03))
	var center := Vector2(7.5, 7.5)
	for y in range(2, 14):
		for x in range(2, 14):
			var d := Vector2(x, y) - center
			if d.length() > 5.6:
				continue
			var a := atan2(d.y, d.x) + d.length() * 0.65                 # the arms wind in
			var hue := RAINBOW[posmod(int(floor(a / TAU * RAINBOW.size() * 2.0)), RAINBOW.size())]
			var c := hue.lerp(GEM_HEART, clampf(0.35 - d.length() * 0.05, 0.0, 0.35))
			if d.length() < 1.8:
				c = GEM_HEART
			_px(t, x, y, c)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:   # white rivets
		_px(t, p.x, p.y, GEM_HEART)


func _core_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(STONE_LIGHT, 0.04))
	for i in range(-6, 7):                                        # a four-pointed star, rainbow at its tips
		var w := 6 - absi(i)
		_px(t, 7 + i, 7, GEM_HEART if w > 3 else RAINBOW[(i + 6) % RAINBOW.size()])
		_px(t, 7, 7 + i, GEM_HEART if w > 3 else RAINBOW[(i + 9) % RAINBOW.size()])
	for i in range(-2, 3):
		_px(t, 7 + i, 7 + i, GEM_HEART)
		_px(t, 7 + i, 7 - i, GEM_HEART)
	for x in TILE:                                                # a golden rim
		_px(t, x, 0, STONE_DARK)
		_px(t, x, TILE - 1, STONE_DARK)
		_px(t, 0, x, STONE_DARK)
		_px(t, TILE - 1, x, STONE_DARK)

# --- Survivor games and crafting (spec §12.19): the crafting table and the furnace, row 6 ----------------

const WOOD := Color("a0703c")
const WOOD_DARK := Color("6b4724")
const WOOD_LIGHT := Color("c28a52")
const FIRE := Color("ff9a2e")
const FIRE_HOT := Color("ffd23f")
const FIRE_DEEP := Color("c2410c")
const SOOT := Color("3a1c12")
# Owner #43: the Workbench's paint and the Clay Oven's terracotta
const MAT := Color("1fb5ae")
const MAT_DARK := Color("13857f")
const STAR := Color("ffd23f")
const KNOB := Color("f2b632")
const PAINTS: Array[Color] = [Color("e8403a"), Color("f7d23e"), Color("3a7be8")]
const CLAY := Color("c9653c")
const CLAY_DARK := Color("9c4526")
const CLAY_LIGHT := Color("e58a5c")

var craft_rng := RandomNumberGenerator.new()
var ident_rng := RandomNumberGenerator.new()


func _crafting_tiles() -> void:
	craft_rng.seed = 20260934
	ident_rng.seed = 20260943   # owner #43: the Workbench and the Clay Oven
	_table_top(Vector2i(0, 6))
	_table_side(Vector2i(1, 6))
	for i in 560:               # the old table's draws, so the planks under it stay the same tile
		craft_rng.randf()
	_planks(Vector2i(2, 6))
	_oven_top(Vector2i(3, 6))
	_oven_side(Vector2i(4, 6))


func _craft_vary(c: Color, amount: float) -> Color:
	var d := craft_rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _ident_vary(c: Color, amount: float) -> Color:
	var d := ident_rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## Four boards of four rows, darker seams, each board a little lighter or darker, the grain along x.
func _planks(t: Vector2i) -> void:
	for y in TILE:
		var board := y / 4
		var shade: float = [0.0, 0.04, -0.03, 0.02][board]
		for x in TILE:
			var c := WOOD_DARK if y % 4 == 3 else WOOD
			if y % 4 == 0:
				c = WOOD_LIGHT
			if (x + board * 5) % 11 == 0 and y % 4 != 3:
				c = WOOD_DARK   # a board's end
			_px(t, x, y, _craft_vary(Color(c.r + shade, c.g + shade, c.b + shade), 0.03))


## The Workbench's top: a wooden rim round a teal painted mat, a golden star stamp in the middle, three paint pots
## along the back edge (owner #43: our own motif).
func _table_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var rim := x <= 1 or y <= 1 or x >= TILE - 2 or y >= TILE - 2
			var outer := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			var c := MAT
			if rim:
				c = WOOD_DARK if outer else WOOD_LIGHT
			elif (x + y) % 7 == 0:
				c = MAT_DARK   # brush strokes
			_px(t, x, y, _ident_vary(c, 0.025))
	for p: Vector2i in [Vector2i(7, 5), Vector2i(8, 5), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6),
			Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 7), Vector2i(10, 7),
			Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(6, 9), Vector2i(9, 9),
			Vector2i(5, 10), Vector2i(10, 10)]:
		_px(t, p.x, p.y, STAR)                                    # the star stamp
	_px(t, 7, 6, STAR.lightened(0.5))
	for i in PAINTS.size():                                       # paint pots at the back
		var x := 3 + i * 4
		for p: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_px(t, x + p.x, 2 + p.y, PAINTS[i] if p.y == 0 else PAINTS[i].darkened(0.3))
		_px(t, x, 2, PAINTS[i].lightened(0.4))


## The Workbench's side: warm planks, a teal band along the top with paint drips, two drawers with round knobs.
func _table_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := WOOD_LIGHT if y % 5 == 0 else WOOD
			if (x * 3 + y) % 13 == 0:
				c = WOOD_DARK
			_px(t, x, y, _ident_vary(c, 0.03))
	for x in TILE:
		_px(t, x, 0, _ident_vary(MAT_DARK, 0.02))
		_px(t, x, 1, _ident_vary(MAT, 0.02))
	for d: Vector2i in [Vector2i(3, 2), Vector2i(4, 3), Vector2i(10, 2), Vector2i(12, 2), Vector2i(12, 3)]:
		_px(t, d.x, d.y, PAINTS[(d.x + d.y) % PAINTS.size()])      # paint drips
	for drawer: int in [4, 10]:                                    # two drawers, one over the other
		for y in range(drawer, drawer + 5):
			for x in range(2, 14):
				var edge := y == drawer or y == drawer + 4 or x == 2 or x == 13
				_px(t, x, y, _ident_vary(WOOD_DARK if edge else WOOD_LIGHT, 0.02))
		_px(t, 7, drawer + 2, KNOB)
		_px(t, 8, drawer + 2, KNOB.darkened(0.2))
		_px(t, 7, drawer + 1, KNOB.lightened(0.3))


## The Clay Oven's top: rows of rounded terracotta tiles round a dark chimney hole.
func _oven_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var sx := (x + (2 if row % 2 == 1 else 0)) % 4
			var c := CLAY
			if y % 4 == 3:
				c = CLAY_DARK
			elif y % 4 == 0 and sx >= 1 and sx <= 2:
				c = CLAY_LIGHT
			elif sx == 0:
				c = CLAY.darkened(0.12)
			_px(t, x, y, _ident_vary(c, 0.03))
	for y in range(5, 11):
		for x in range(5, 11):
			var d := Vector2(x, y).distance_to(Vector2(7.5, 7.5))
			if d <= 2.9:
				_px(t, x, y, SOOT if d < 2.0 else CLAY_DARK.darkened(0.2))


## The Clay Oven's side: a warm clay dome front (its top corners rounded off), a round window of fire with a dark
## rim, and a clay ledge at its foot.
func _oven_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := CLAY
			if y < 3 and (x + y) % 5 == 0:
				c = CLAY_LIGHT
			elif (x * 2 + y * 3) % 11 == 0:
				c = CLAY.darkened(0.1)
			_px(t, x, y, _ident_vary(c, 0.03))
	for y in range(0, 3):                                          # the dome's rounded shoulders
		for x in range(0, 3 - y):
			_px(t, x, y, CLAY_DARK)
			_px(t, TILE - 1 - x, y, CLAY_DARK)
	var center := Vector2(7.5, 8.0)
	for y in range(3, 14):
		for x in range(2, 14):
			var d := Vector2(x, y).distance_to(center)
			if d > 4.6:
				continue
			var c := SOOT
			if d <= 3.7:
				c = FIRE_HOT if d < 1.6 else (FIRE if d < 2.8 else FIRE_DEEP)
			_px(t, x, y, c)
	for x in TILE:                                                  # the ledge
		_px(t, x, 14, CLAY_LIGHT)
		_px(t, x, 15, CLAY_DARK)

# --- M3 Task 14a: the zipline post and the launch pad ---

const POST_WOOD := Color("9a6a3a")
const POST_WOOD_DARK := Color("6e4824")
const POST_WOOD_LIGHT := Color("b98550")
const HAZARD_Y := Color("ffd23f")
const HAZARD_K := Color("2b2f3a")
const GADGET_METAL := Color("aeb7c2")
const GADGET_METAL_DARK := Color("5f6b78")
const PAD := Color("33384a")
const PAD_DARK := Color("222634")
const ARROW := Color("ff8a1c")
const ARROW_LIGHT := Color("ffd28a")


## A wooden post: vertical grain, a hazard band near the top, a pulley wheel painted on it.
func _post_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var grain := POST_WOOD_DARK if (x * 7 + y / 5) % 5 == 0 else (POST_WOOD_LIGHT if x % 5 == 2 else POST_WOOD)
			_px(t, x, y, _vary(grain, 0.03))
	for y in range(2, 5):                                          # the band
		for x in TILE:
			_px(t, x, y, HAZARD_Y if ((x + y) / 2) % 2 == 0 else HAZARD_K)
	var c := Vector2(7.5, 9.5)                                     # the wheel
	for y in range(6, 14):
		for x in range(4, 12):
			var d := Vector2(x, y).distance_to(c)
			if d <= 3.6:
				_px(t, x, y, GADGET_METAL_DARK if d > 2.6 or d < 1.0 else GADGET_METAL)


## The top: end grain rings under a round metal cap.
func _post_top(t: Vector2i) -> void:
	var c := Vector2(7.5, 7.5)
	for y in TILE:
		for x in TILE:
			var d := Vector2(x, y).distance_to(c)
			var ring := POST_WOOD_DARK if int(d) % 3 == 0 else POST_WOOD_LIGHT
			_px(t, x, y, _vary(ring, 0.03))
			if d <= 4.2:
				_px(t, x, y, GADGET_METAL_DARK if d > 3.2 else GADGET_METAL)


## The launch pad's top: three orange chevrons pointing up (away from the side you step on).
func _pad_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			_px(t, x, y, _vary(PAD_DARK if edge else PAD, 0.02))
	for k in 3:
		var top := 2 + k * 4
		for i in range(0, 6):
			for w in 2:
				var y := top + i + w
				if y >= TILE - 1:
					continue
				_px(t, 7 - i, y, ARROW if w == 0 else ARROW_LIGHT)
				_px(t, 8 + i, y, ARROW if w == 0 else ARROW_LIGHT)


## The side: dark metal with a band of orange and black stripes.
func _pad_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(PAD if y % 5 != 0 else PAD_DARK, 0.02))
	for y in range(5, 11):
		for x in TILE:
			_px(t, x, y, ARROW if ((x + y) / 3) % 2 == 0 else HAZARD_K)

# --- M3 Task 20a: the saddle ---

const LEATHER := Color("8b5a2b")
const LEATHER_DARK := Color("5e3a1a")
const LEATHER_LIGHT := Color("a8743d")
const STITCH := Color("e6c48a")
const BRASS := Color("ffd23f")
const STEEL := Color("b8bcc8")


func _leather(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			_px(t, x, y, _vary(LEATHER_DARK if edge else LEATHER, 0.03))


func _saddle_top(t: Vector2i) -> void:
	_leather(t)
	for i in range(2, TILE - 2):                                  # stitching, every other pixel, inside the rim
		if i % 2 == 0:
			for p: Vector2i in [Vector2i(i, 1), Vector2i(i, TILE - 2), Vector2i(1, i), Vector2i(TILE - 2, i)]:
				_px(t, p.x, p.y, STITCH)
	for y in range(2, 6):                                         # the pommel at the front (top of the tile)
		for x in range(6, 10):
			_px(t, x, y, _vary(LEATHER_LIGHT, 0.03))
	_px(t, 7, 2, STITCH)
	_px(t, 8, 2, STITCH)
	for y in range(8, 13):                                        # the seat's dip
		for x in range(4, 12):
			if absi(x * 2 - 15) + (y - 8) * 2 < 11:
				_px(t, x, y, _vary(LEATHER_DARK, 0.02))
	for p: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:   # gold rivets
		_px(t, p.x, p.y, BRASS)


func _saddle_side(t: Vector2i) -> void:
	_leather(t)
	for x in range(2, TILE - 2):                                  # a stitched hem along the top and bottom
		if x % 2 == 1:
			_px(t, x, 2, STITCH)
			_px(t, x, TILE - 3, STITCH)
	for y in range(1, 9):                                         # the strap down the middle
		_px(t, 7, y, LEATHER_DARK)
		_px(t, 8, y, LEATHER_DARK)
	for x in range(6, 10):                                        # a gold buckle on it
		_px(t, x, 5, BRASS)
		_px(t, x, 7, BRASS)
	_px(t, 6, 6, BRASS)
	_px(t, 9, 6, BRASS)
	for p: Vector2i in [Vector2i(6, 9), Vector2i(9, 9), Vector2i(5, 10), Vector2i(10, 10), Vector2i(5, 11),
			Vector2i(10, 11), Vector2i(5, 12), Vector2i(10, 12), Vector2i(6, 13), Vector2i(7, 13), Vector2i(8, 13),
			Vector2i(9, 13), Vector2i(7, 9), Vector2i(8, 9)]:            # the stirrup, a steel loop
		_px(t, p.x, p.y, STEEL)

# --- Owner feedback #39: the universe portal cores ---
## [side tile, top tile, deep, bright] per universe (the colours are CrystalRules.SWIRLS').
const UNIVERSE_CORES := [
	[Vector2i(0, 1), Vector2i(1, 1), Color("14521f"), Color("a8ff9e")],   # 212 Green Meadows
	[Vector2i(2, 1), Vector2i(3, 1), Color("7a3a0a"), Color("ffd27a")],   # 213 the Sandstorm Desert
	[Vector2i(4, 1), Vector2i(5, 1), Color("173c78"), Color("c6efff")],   # 214 Frostpeak
	[Vector2i(6, 1), Vector2i(7, 1), Color("7a1f5a"), Color("ffc2e5")],   # 215 the Candy Kingdom
	[Vector2i(4, 3), Vector2i(5, 3), Color("d9546e"), Color("ffe7b8")],   # 222 the Dragon Realm (owner #43: sunrise)
	[Vector2i(6, 3), Vector2i(7, 3), Color("0f4c5c"), Color("8ff7e8")],   # 223 the Glow Caves (teal glow, never purple)
]


func _universe_cores() -> void:
	rng.seed = 20260939
	for c: Array in UNIVERSE_CORES:
		_ucore_side(c[0], c[2], c[3])
		_ucore_top(c[1], c[2], c[3])


## The core's side (a swirl gem in a golden setting, rivets), in a universe's colours.
func _ucore_side(t: Vector2i, deep: Color, bright: Color) -> void:
	var gem := deep.lerp(bright, 0.45)
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			_px(t, x, y, _vary(STONE_DARK if edge else STONE, 0.03))
	var center := Vector2(7.5, 7.5)
	for y in range(2, 14):
		for x in range(2, 14):
			var d := Vector2(x, y) - center
			if d.length() > 5.6:
				continue
			var swirl := sin(atan2(d.y, d.x) * 2.0 + d.length() * 1.3)
			var c := gem.lerp(bright, clampf(swirl * 0.5 + 0.5, 0.0, 1.0))
			if d.length() < 1.8:
				c = bright.lightened(0.6)
			_px(t, x, y, c)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		_px(t, p.x, p.y, bright)


## The core's top and bottom: a four-pointed star of light on the gem, a golden rim.
func _ucore_top(t: Vector2i, deep: Color, bright: Color) -> void:
	var gem := deep.lerp(bright, 0.35)
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(gem, 0.04))
	for i in range(-6, 7):
		var w := 6 - absi(i)
		var c := bright.lightened(0.6) if w > 3 else bright
		_px(t, 7 + i, 7, c)
		_px(t, 7, 7 + i, c)
	for i in range(-2, 3):
		_px(t, 7 + i, 7 + i, bright)
		_px(t, 7 + i, 7 - i, bright)
	for x in TILE:
		_px(t, x, 0, STONE_DARK)
		_px(t, x, TILE - 1, STONE_DARK)
		_px(t, 0, x, STONE_DARK)
		_px(t, TILE - 1, x, STONE_DARK)

# --- M3 Task 21b: the trophy shelf (217) and the bookshelf (218) ---
## (2, 2) trophy shelf side: a wooden frame (two posts, a top rail, a middle shelf, a bottom rail) round two
## open, see-through shelves (alpha 0: the trophies stand inside); (3, 2) its top and bottom: planks in a dark rim;
## (4, 2) bookshelf side: the same frame full of books of many colours; (5, 2) its top and bottom: planks.
const BOOK_COLORS: Array[Color] = [Color("c62828"), Color("1565c0"), Color("2e7d32"), Color("f9a825"),
	Color("6a1b9a"), Color("ef6c00"), Color("00838f"), Color("ad1457")]

var book_rng := RandomNumberGenerator.new()


func _book_tiles() -> void:
	book_rng.seed = 20260941
	_shelf_side(Vector2i(2, 2), false)
	_shelf_top(Vector2i(3, 2))
	_shelf_side(Vector2i(4, 2), true)
	_shelf_top(Vector2i(5, 2))


func _book_vary(c: Color, amount: float) -> Color:
	var d := book_rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## The cabinet's frame, and inside it nothing (the trophy shelf: see-through) or two rows of books.
func _shelf_side(t: Vector2i, books: bool) -> void:
	for y in TILE:
		for x in TILE:
			var post := x <= 1 or x >= TILE - 2
			var rail := y <= 1 or y == 7 or y == 8 or y >= TILE - 2
			if post or rail:
				var c := WOOD_DARK if post else (WOOD_LIGHT if y == 0 or y == 7 or y == TILE - 2 else WOOD)
				_px(t, x, y, _book_vary(c, 0.03))
			else:
				_px(t, x, y, Color(0, 0, 0, 0))
	if not books:
		return
	for row: Array in [[2, 6], [9, 13]]:   # a row of books between rails, each 1-2 px wide, a few shorter
		var x := 2
		while x < TILE - 2:
			var w := 1 + book_rng.randi_range(0, 1)
			var col := BOOK_COLORS[book_rng.randi_range(0, BOOK_COLORS.size() - 1)]
			var top: int = int(row[0]) + book_rng.randi_range(0, 1)
			for bx in range(x, mini(x + w, TILE - 2)):
				for y in range(top, int(row[1]) + 1):
					var c := col.lightened(0.35) if y == top + 1 else col
					_px(t, bx, y, _book_vary(c, 0.03))
				for y in range(int(row[0]), top):
					_px(t, bx, y, WOOD_DARK.darkened(0.3))   # the dark back of the case above a short book
			x += w


func _shelf_top(t: Vector2i) -> void:
	for y in TILE:
		var board := y / 4
		for x in TILE:
			var edge := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			var c := WOOD_DARK if edge or y % 4 == 3 else (WOOD_LIGHT if y % 4 == 0 else WOOD)
			if not edge and (x + board * 5) % 11 == 0 and y % 4 != 3:
				c = WOOD_DARK
			_px(t, x, y, _book_vary(c, 0.03))
