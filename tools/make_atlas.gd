extends SceneTree
## Generates data/blocks/atlas.png: an 8x8 grid of 16x16 pixel-art tiles.
## Run: godot --headless --path . --script res://tools/make_atlas.gd
## Tile coordinates must match world/block_library.gd TILES.

const TILE := 16
const GRID := 8
const OUT := "res://data/blocks/atlas.png"

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20260923
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_noise_tile(Vector2i(0, 0), Color("5bc236"), 0.08)          # grass top
	_grass_side(Vector2i(1, 0))
	_noise_tile(Vector2i(2, 0), Color("8b5a2b"), 0.10)          # dirt
	_stone(Vector2i(3, 0))
	_noise_tile(Vector2i(4, 0), Color("f2d98c"), 0.06)          # sand
	_log_side(Vector2i(5, 0))
	_log_top(Vector2i(6, 0))
	_planks(Vector2i(7, 0))
	_leaves(Vector2i(0, 1))
	_glass(Vector2i(1, 1))
	_brick(Vector2i(2, 1))
	_light(Vector2i(3, 1))
	_water(Vector2i(4, 1))
	_toy(Vector2i(5, 1), Color("e8403a"))                        # red
	_toy(Vector2i(6, 1), Color("f7d23e"))                        # yellow
	_toy(Vector2i(7, 1), Color("3cc45a"))                        # green
	_toy(Vector2i(0, 2), Color("3a7be8"))                        # blue
	_toy(Vector2i(1, 2), Color("9b4de0"))                        # purple
	# Item icons (row 3) — see ui/hud/block_icons.gd ITEM_TILES
	_icon_wand(Vector2i(0, 3))
	_icon_house(Vector2i(1, 3))
	_icon_tower(Vector2i(2, 3))
	_icon_bridge(Vector2i(3, 3))
	_icon_tree(Vector2i(4, 3))
	_icon_rainbow(Vector2i(5, 3))
	# World v2 (M1b): underground blocks. Appended last so the tiles above stay identical.
	_deepstone(Vector2i(2, 2))
	_bedrock(Vector2i(3, 2))
	_ore(Vector2i(4, 2), Color("1e1e22"), Color("3a3a40"))     # coal
	_ore(Vector2i(5, 2), Color("d8a27a"), Color("f1c7a3"))     # iron
	_ore(Vector2i(6, 2), Color("f7c52b"), Color("fff08a"))     # gold
	_ore(Vector2i(7, 2), Color("35e0e0"), Color("b9fff8"))     # diamond
	_crystal(Vector2i(6, 3))
	# Beds (M1b Task 10): row 4. They use their own RNG, so they never shift anybody else's tiles.
	_bed_top(Vector2i(0, 4))
	_bed_side(Vector2i(1, 4))
	_bed_bottom(Vector2i(2, 4))

	# Weapons, tools and targets (M1b Task 11): row 5, see ui/hud/block_icons.gd ITEM_TILES.
	# Drawn without the RNG, so tiles appended by other tasks keep their own random sequence.
	_icon_sword(Vector2i(0, 5))
	_icon_bow(Vector2i(1, 5))
	_icon_boomerang(Vector2i(2, 5))
	_icon_hammer(Vector2i(3, 5))
	_icon_axe(Vector2i(4, 5))
	_icon_pickaxe(Vector2i(5, 5))
	_icon_dummy(Vector2i(6, 5))
	_icon_bullseye(Vector2i(7, 5))
	# Hiding spots (M2 Task 5): row 6, tiles (0..5, 6). Their own RNG, like the beds.
	_bush_side(Vector2i(0, 6))
	_bush_top(Vector2i(1, 6))
	_barrel_side(Vector2i(2, 6))
	_barrel_top(Vector2i(3, 6))
	_closet_front(Vector2i(4, 6))
	_closet_top(Vector2i(5, 6))
	# Secrets and treasures (M2 Task 16): (6..7, 6) and row 7. Drawn after everything else, with their own
	# RNG, so no other tile changes.
	_fake_wall(Vector2i(6, 6))
	_plate_top(Vector2i(7, 6))
	_plate_side(Vector2i(0, 7))
	_trophy_side(Vector2i(1, 7))
	_trophy_top(Vector2i(2, 7))
	_gold_lamp(Vector2i(3, 7))
	_icon_map(Vector2i(4, 7))
	# Defenses (M2 Task 8): (3..7, 4) and (7, 3). Their own RNG, so other tasks' tiles never shift.
	_defenses()
	# Owner #43: the grass side and the ores redrawn over their old tiles, last, with their own RNG.
	_identity_pass()
	var err := img.save_png(OUT)
	print("ATLAS saved err=", err)
	quit()


func _px(tile: Vector2i, x: int, y: int, c: Color) -> void:
	img.set_pixel(tile.x * TILE + x, tile.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _noise_tile(t: Vector2i, base: Color, amount: float) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(base, amount))


func _grass_side(t: Vector2i) -> void:
	_noise_tile(t, Color("8b5a2b"), 0.10)
	for x in TILE:
		var depth := 3 + rng.randi_range(0, 2)
		for y in depth:
			_px(t, x, y, _vary(Color("5bc236"), 0.08))


func _stone(t: Vector2i) -> void:
	_noise_tile(t, Color("8e949b"), 0.07)
	for i in 10:
		var x := rng.randi_range(0, TILE - 3)
		var y := rng.randi_range(0, TILE - 1)
		for k in rng.randi_range(1, 3):
			_px(t, x + k, y, Color("6c7178"))


func _log_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var stripe := (x % 4 == 0) or (x % 7 == 3)
			_px(t, x, y, _vary(Color("6e4522") if stripe else Color("8a5a2e"), 0.04))


func _log_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var edge := d > 7.0
			var ring := int(d) % 3 == 0
			var c := Color("8a5a2e") if edge else (Color("b0824a") if ring else Color("c79a5b"))
			_px(t, x, y, _vary(c, 0.03))


func _planks(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var seam := (x + row * 5) % 16 == 0
			var line := y % 4 == 3
			_px(t, x, y, _vary(Color("9c6b34") if (line or seam) else Color("c8924e"), 0.04))


func _leaves(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			if rng.randf() < 0.18:
				continue
			_px(t, x, y, _vary(Color("3fa535") if rng.randf() > 0.25 else Color("2e8a28"), 0.05))


func _glass(t: Vector2i) -> void:
	var frame := Color("e8f6ff")
	for i in TILE:
		_px(t, i, 0, frame)
		_px(t, i, TILE - 1, frame)
		_px(t, 0, i, frame)
		_px(t, TILE - 1, i, frame)
	for i in 4:
		_px(t, 3 + i, 6 - i, Color(1, 1, 1, 0.9))
		_px(t, 9 + i, 12 - i, Color(1, 1, 1, 0.9))


func _brick(t: Vector2i) -> void:
	var mortar := Color("d9cfc0")
	for y in TILE:
		for x in TILE:
			var row := y / 4
			var joint := (x + (4 if row % 2 == 1 else 0)) % 8 == 0
			var c := mortar if (y % 4 == 3 or joint) else _vary(Color("b5452f"), 0.05)
			_px(t, x, y, c)


func _light(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := Color("e8b84a") if edge else Color("fff7d6").lerp(Color("ffe08a"), clampf(d / 8.0, 0, 1))
			_px(t, x, y, c)


func _water(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var wave := (x + y * 2) % 7 == 0
			var c := Color("7cc0ff") if wave else _vary(Color("3a8ee6"), 0.03)
			c.a = 0.72
			_px(t, x, y, c)


## Bright plastic "toy brick" look: lighter top-left bevel, darker bottom-right, soft centre.
func _toy(t: Vector2i, base: Color) -> void:
	for y in TILE:
		for x in TILE:
			var c := base
			if x == 0 or y == 0:
				c = base.lightened(0.35)
			elif x == TILE - 1 or y == TILE - 1:
				c = base.darkened(0.3)
			elif x == 1 or y == 1:
				c = base.lightened(0.15)
			_px(t, x, y, c)


func _rect(t: Vector2i, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(t, x, y, c)


func _icon_wand(t: Vector2i) -> void:
	for i in 9:
		_px(t, 2 + i, 13 - i, Color("8a5a2e"))
		_px(t, 3 + i, 13 - i, Color("6e4522"))
	var gold := Color("ffd23f")
	for p in [Vector2i(12, 3), Vector2i(11, 3), Vector2i(13, 3), Vector2i(12, 2), Vector2i(12, 4),
			Vector2i(10, 3), Vector2i(14, 3), Vector2i(12, 1), Vector2i(12, 5), Vector2i(11, 2), Vector2i(13, 4),
			Vector2i(11, 4), Vector2i(13, 2)]:
		_px(t, p.x, p.y, gold)
	_px(t, 12, 3, Color.WHITE)
	for p in [Vector2i(8, 1), Vector2i(15, 6), Vector2i(14, 0), Vector2i(9, 5)]:
		_px(t, p.x, p.y, Color("fff7c2"))


func _icon_house(t: Vector2i) -> void:
	_rect(t, 3, 8, 12, 14, Color("c8924e"))
	for i in 7:
		_rect(t, 1 + i, 7 - i, 14 - i, 7 - i, Color("d9463b"))
	_rect(t, 7, 11, 8, 14, Color("6e4522"))
	_rect(t, 4, 9, 5, 10, Color("bfe6ff"))
	_rect(t, 10, 9, 11, 10, Color("bfe6ff"))


func _icon_tower(t: Vector2i) -> void:
	_rect(t, 4, 3, 11, 15, Color("8e949b"))
	for x in [4, 6, 8, 10]:
		_rect(t, x, 1, x, 2, Color("8e949b"))
	_rect(t, 7, 6, 8, 8, Color("2b2f36"))
	_rect(t, 7, 12, 8, 15, Color("6e4522"))


func _icon_bridge(t: Vector2i) -> void:
	_rect(t, 0, 9, 15, 10, Color("c8924e"))
	_rect(t, 0, 5, 15, 5, Color("8a5a2e"))
	for x in [1, 5, 10, 14]:
		_rect(t, x, 5, x, 9, Color("8a5a2e"))
	_rect(t, 0, 11, 15, 15, Color("3a8ee6"))


func _icon_tree(t: Vector2i) -> void:
	_rect(t, 7, 9, 8, 15, Color("8a5a2e"))
	for y in 10:
		for x in 16:
			if Vector2(x - 7.5, y - 5.0).length() < 5.5:
				_px(t, x, y, Color("3fa535") if (x + y) % 3 else Color("2e8a28"))


func _icon_rainbow(t: Vector2i) -> void:
	var colors := [Color("e8403a"), Color("f08a1c"), Color("f7d23e"), Color("3cc45a"), Color("3a7be8"), Color("9b4de0")]
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 14.0).length()
			var band := int(8.5 - d)
			if d <= 8.5 and d >= 2.5 and band >= 0 and band < colors.size():
				_px(t, x, y, colors[band])


func _deepstone(t: Vector2i) -> void:
	_noise_tile(t, Color("4b4f5a"), 0.05)
	for i in 10:                                                  # darker cracks
		var x := rng.randi_range(0, TILE - 3)
		var y := rng.randi_range(0, TILE - 1)
		for dx in 3:
			_px(t, x + dx, y, Color("33363f"))


func _bedrock(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var v := rng.randf()
			var c := Color("1c1c20") if v < 0.35 else (Color("5c5c63") if v > 0.8 else Color("37373d"))
			_px(t, x, y, c)


## Deep stone with 5 clusters of ore specks (dark rim + bright highlight).
func _ore(t: Vector2i, ore: Color, shine: Color) -> void:
	_noise_tile(t, Color("6f747c"), 0.06)
	for i in 5:
		var cx := rng.randi_range(2, TILE - 4)
		var cy := rng.randi_range(2, TILE - 4)
		for dy in 2:
			for dx in 3:
				if rng.randf() < 0.85:
					_px(t, cx + dx, cy + dy, _vary(ore, 0.05))
		_px(t, cx, cy, shine)


func _crystal(t: Vector2i) -> void:
	_noise_tile(t, Color("7d4ff0"), 0.05)
	for i in 6:                                                   # bright facets
		var x := rng.randi_range(1, TILE - 3)
		var y := rng.randi_range(1, TILE - 5)
		for dy in 4:
			_px(t, x + (1 if dy % 2 == 0 else 0), y + dy, Color("d9c7ff"))
	_rect(t, 0, 0, TILE - 1, 0, Color("b89cff"))
	_rect(t, 0, 0, 0, TILE - 1, Color("b89cff"))


# --- Beds (M1b Task 10) -----------------------------------------------------------------------

const BED_WOOD := Color("b07a40")
const BED_WOOD_DARK := Color("7a5028")
const BLANKET := Color("d9463b")
const BLANKET_DARK := Color("b5352c")
const SHEET := Color("f1ede4")
const PILLOW := Color("fbf8f0")
const PILLOW_SHADE := Color("d8d1c2")

var bed_rng := RandomNumberGenerator.new()


func _bed_vary(c: Color, amount: float) -> Color:
	var d := bed_rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## Seen from above: a wooden rim, the pillow at the top of the tile (the +Z end of the block), the
## turned-down sheet, and a quilted red blanket.
func _bed_top(t: Vector2i) -> void:
	bed_rng.seed = 2026092410
	for y in TILE:
		for x in TILE:
			var c := _bed_vary(BLANKET, 0.03)
			if (x - 1) % 5 == 0 or (y - 7) % 4 == 0:
				c = _bed_vary(BLANKET_DARK, 0.02)             # quilting seams
			if y <= 4:
				c = _bed_vary(SHEET.darkened(0.08), 0.02)     # mattress under the pillow
			if y >= 5 and y <= 6:
				c = _bed_vary(SHEET, 0.02)                    # the sheet folded over the blanket
			_px(t, x, y, c)
	for y in range(1, 5):                                 # pillow with rounded corners
		for x in range(2, 14):
			if (x == 2 or x == 13) and (y == 1 or y == 4):
				continue
			_px(t, x, y, PILLOW_SHADE if y == 4 else (PILLOW if y > 1 else PILLOW.lightened(0.5)))
	for i in TILE:                                        # the wooden rim
		_px(t, i, 0, BED_WOOD_DARK)
		_px(t, i, TILE - 1, BED_WOOD_DARK)
		_px(t, 0, i, BED_WOOD_DARK)
		_px(t, TILE - 1, i, BED_WOOD_DARK)


## The block is 0.5625 high, so a side face shows only the tile's bottom 9 rows: blanket, mattress
## and the wooden frame. The rows above only show in the hotbar icon: a headboard and a pillow, and
## otherwise clear.
func _bed_side(t: Vector2i) -> void:
	bed_rng.seed = 2026092411
	for y in TILE:
		for x in TILE:
			var c := Color(BLANKET, 0.0)
			if y == 7:
				c = _bed_vary(BLANKET.lightened(0.15), 0.02)
			elif y >= 8 and y <= 9:
				c = _bed_vary(BLANKET if y == 8 else BLANKET_DARK, 0.03)
			elif y >= 10 and y <= 11:
				c = _bed_vary(SHEET if y == 10 else SHEET.darkened(0.12), 0.02)
			elif y >= 12:
				var leg := (x <= 1 or x >= TILE - 2) and y >= 13
				c = _bed_vary(BED_WOOD.lightened(0.12) if y == 12 else (BED_WOOD_DARK if leg else BED_WOOD), 0.03)
			_px(t, x, y, c)
	_rect(t, 0, 2, 2, 6, BED_WOOD_DARK)                    # headboard (icon only)
	_rect(t, 1, 3, 1, 6, BED_WOOD)
	_rect(t, 3, 5, 6, 6, PILLOW)                           # pillow (icon only)
	_rect(t, 3, 6, 6, 6, PILLOW_SHADE)


## Underneath: planks with dark seams and four legs.
func _bed_bottom(t: Vector2i) -> void:
	bed_rng.seed = 2026092412
	for y in TILE:
		for x in TILE:
			var seam := x % 4 == 3
			_px(t, x, y, _bed_vary(BED_WOOD_DARK if seam else BED_WOOD, 0.04))
	for leg in [Vector2i(0, 0), Vector2i(13, 0), Vector2i(0, 13), Vector2i(13, 13)]:
		_rect(t, leg.x, leg.y, leg.x + 2, leg.y + 2, BED_WOOD_DARK.darkened(0.25))

# --- Weapons, tools and targets (M1b Task 11) ---

## A 45-degree stroke from `a` towards `b`, `width` pixels wide (extending to the right).
func _stroke(t: Vector2i, a: Vector2i, b: Vector2i, c: Color, width: int = 2) -> void:
	var d := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var p := a + d * i
		for w in width:
			if p.x + w < TILE:
				_px(t, p.x + w, p.y, c)


func _icon_sword(t: Vector2i) -> void:
	_stroke(t, Vector2i(5, 10), Vector2i(13, 2), Color("e9eef3"))            # blade
	_stroke(t, Vector2i(7, 10), Vector2i(14, 3), Color("9aa6b2"), 1)         # blade shade
	_px(t, 14, 1, Color("ffffff"))                                           # tip
	_stroke(t, Vector2i(2, 9), Vector2i(6, 13), Color("f2b632"), 1)          # guard
	_stroke(t, Vector2i(3, 9), Vector2i(7, 13), Color("b07d18"), 1)
	_stroke(t, Vector2i(2, 13), Vector2i(3, 12), Color("7a4a24"))            # grip
	_px(t, 1, 14, Color("f2b632"))                                           # pommel


func _icon_bow(t: Vector2i) -> void:
	for y in range(1, 15):
		_px(t, 3, y, Color("f3efe6"))                                        # string
		var x := 3 + roundi(7.0 * sin(PI * (y - 1) / 13.0))
		_px(t, x, y, Color("a0622d"))                                        # limb
		_px(t, x + 1, y, Color("6e4522"))
	_rect(t, 1, 8, 13, 8, Color("c8b28a"))                                   # arrow shaft
	_rect(t, 14, 7, 14, 9, Color("d9dee4"))                                  # arrow head
	_px(t, 15, 8, Color("ffffff"))
	_rect(t, 0, 7, 1, 7, Color("e8403a"))                                    # fletching
	_rect(t, 0, 9, 1, 9, Color("e8403a"))


func _icon_boomerang(t: Vector2i) -> void:
	_stroke(t, Vector2i(1, 3), Vector2i(8, 10), Color("f08a1c"), 3)
	_stroke(t, Vector2i(8, 10), Vector2i(14, 4), Color("f08a1c"), 2)
	_stroke(t, Vector2i(9, 10), Vector2i(15, 4), Color("b85e0c"), 1)
	_stroke(t, Vector2i(1, 2), Vector2i(7, 8), Color("ffc27a"), 1)           # light edge
	for p in [Vector2i(3, 5), Vector2i(6, 8), Vector2i(12, 7)]:              # painted dots
		_px(t, p.x, p.y, Color("3a7be8"))


func _icon_hammer(t: Vector2i) -> void:
	_stroke(t, Vector2i(2, 14), Vector2i(9, 7), Color("8a5a2e"))             # handle
	_rect(t, 6, 1, 14, 7, Color("7d848c"))                                   # head
	_rect(t, 6, 1, 14, 1, Color("b9c0c8"))
	_rect(t, 6, 1, 6, 7, Color("b9c0c8"))
	_rect(t, 7, 7, 14, 7, Color("4c5157"))
	_rect(t, 14, 2, 14, 7, Color("4c5157"))


func _icon_axe(t: Vector2i) -> void:
	for y in TILE:                                                           # half-moon blade
		for x in TILE:
			var d := Vector2(x - 8.0, y - 4.0).length()
			if d <= 4.8 and x + y <= 14:
				_px(t, x, y, Color("e9eef3") if d > 3.6 else Color("8e949b"))
	_stroke(t, Vector2i(1, 14), Vector2i(11, 4), Color("8a5a2e"))            # handle
	_px(t, 12, 3, Color("6e4522"))


func _icon_pickaxe(t: Vector2i) -> void:
	for k in range(-5, 6):                                                   # curved head
		var x := 10 + k
		var y := 5 + k - roundi((25 - k * k) * 0.18)
		for dy in 2:
			if x >= 0 and x < TILE and y + dy >= 0 and y + dy < TILE:
				_px(t, x, y + dy, Color("9aa6b2") if dy == 0 else Color("5f6770"))
	_stroke(t, Vector2i(1, 14), Vector2i(9, 6), Color("8a5a2e"))             # handle


func _icon_dummy(t: Vector2i) -> void:
	_rect(t, 7, 10, 8, 15, Color("6e4522"))                                  # post
	_rect(t, 2, 6, 13, 7, Color("c8924e"))                                   # arms
	_rect(t, 5, 5, 10, 11, Color("e0c38c"))                                  # straw body
	_rect(t, 6, 1, 9, 4, Color("f0dcae"))                                    # head
	_px(t, 6, 2, Color("3b2f2a"))
	_px(t, 9, 2, Color("3b2f2a"))
	_rect(t, 7, 7, 8, 8, Color("e8403a"))                                    # target spot
	_rect(t, 5, 9, 10, 9, Color("a0622d"))                                   # rope belt


func _icon_bullseye(t: Vector2i) -> void:
	var rings := [Color("f7d23e"), Color("e8403a"), Color("f7f5ef"), Color("e8403a"), Color("f7f5ef"), Color("3a7be8")]
	for y in TILE:
		for x in TILE:
			var ring := int(Vector2(x - 7.5, y - 7.5).length() / 1.35)
			if ring < rings.size():
				_px(t, x, y, rings[ring])


# --- Secrets and treasures (M2 Task 16) ---

const GOLD_LIGHT := Color("ffe27a")
const GOLD_MID := Color("f2c230")
const GOLD_DARK := Color("b8860b")

var secret_rng := RandomNumberGenerator.new()


## The stone tile, copied, with a faint crack only sharp eyes notice.
func _fake_wall(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, img.get_pixel(3 * TILE + x, y))
	for p in [Vector2i(9, 2), Vector2i(8, 3), Vector2i(8, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(8, 7),
			Vector2i(8, 8), Vector2i(7, 9), Vector2i(6, 10), Vector2i(6, 11), Vector2i(7, 12)]:
		_px(t, p.x, p.y, img.get_pixel(t.x * TILE + p.x, t.y * TILE + p.y).darkened(0.22))


## Seen from above: a square stone plate with a raised rim.
func _plate_top(t: Vector2i) -> void:
	secret_rng.seed = 2026092416
	for y in TILE:
		for x in TILE:
			var edge := x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1
			var rim := x == 1 or y == 1 or x == TILE - 2 or y == TILE - 2
			var c := Color("6c7178") if edge else (Color("c3c8ce") if rim else Color("a3a9b0"))
			var d := secret_rng.randf_range(-0.03, 0.03)
			_px(t, x, y, Color(c.r + d, c.g + d, c.b + d))


## The plate is 1/8 high, so a side face shows only the tile's bottom 2 rows: the plate's edge.
func _plate_side(t: Vector2i) -> void:
	for x in TILE:
		_px(t, x, TILE - 2, Color("c3c8ce"))
		_px(t, x, TILE - 1, Color("6c7178"))
	_rect(t, 2, 10, 13, 13, Color("a3a9b0"))                 # hotbar icon only: a flat plate
	_rect(t, 2, 10, 13, 10, Color("c3c8ce"))


## Shiny gold with a trophy cup in relief.
func _trophy_side(t: Vector2i) -> void:
	_gold_plate(t)
	var cup := GOLD_DARK
	_rect(t, 4, 3, 11, 3, cup)                                # rim
	_rect(t, 5, 4, 10, 7, cup)                                # bowl
	_rect(t, 6, 8, 9, 8, cup)
	_rect(t, 2, 4, 3, 4, cup)                                 # handles
	_rect(t, 2, 5, 2, 6, cup)
	_rect(t, 12, 4, 13, 4, cup)
	_rect(t, 13, 5, 13, 6, cup)
	_rect(t, 7, 9, 8, 10, cup)                                # stem
	_rect(t, 5, 11, 10, 12, cup)                              # base
	_rect(t, 6, 4, 6, 6, GOLD_LIGHT)                          # shine on the bowl


func _trophy_top(t: Vector2i) -> void:
	_gold_plate(t)
	_rect(t, 5, 5, 10, 10, GOLD_DARK)
	_rect(t, 6, 6, 9, 9, GOLD_MID.darkened(0.15))


## A gold square with a light top-left bevel and a dark bottom-right one.
func _gold_plate(t: Vector2i) -> void:
	secret_rng.seed = 2026092417
	for y in TILE:
		for x in TILE:
			var c := GOLD_MID
			if x == 0 or y == 0:
				c = GOLD_LIGHT
			elif x == TILE - 1 or y == TILE - 1:
				c = GOLD_DARK
			var d := secret_rng.randf_range(-0.03, 0.03)
			_px(t, x, y, Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1)))


## A glowing lamp panel: warm light behind golden bars.
func _gold_lamp(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			_px(t, x, y, Color("fffbe0").lerp(Color("ffc93c"), clampf(d / 9.0, 0, 1)))
	for i in TILE:
		for p in [Vector2i(i, 0), Vector2i(i, TILE - 1), Vector2i(0, i), Vector2i(TILE - 1, i), Vector2i(i, 7), Vector2i(7, i)]:
			_px(t, p.x, p.y, GOLD_DARK)
	for p in [Vector2i(1, 1), Vector2i(14, 1), Vector2i(1, 14), Vector2i(14, 14)]:
		_px(t, p.x, p.y, GOLD_LIGHT)


## A parchment map with a dotted path to a red X.
func _icon_map(t: Vector2i) -> void:
	var paper := Color("ecdcae")
	_rect(t, 1, 2, 14, 13, paper)
	_rect(t, 1, 2, 14, 2, Color("c8b27c"))                    # rolled edges
	_rect(t, 1, 13, 14, 13, Color("c8b27c"))
	_rect(t, 0, 1, 0, 14, Color("a58a52"))
	_rect(t, 15, 1, 15, 14, Color("a58a52"))
	for p in [Vector2i(3, 11), Vector2i(4, 10), Vector2i(6, 10), Vector2i(7, 9), Vector2i(8, 7), Vector2i(9, 6)]:
		_px(t, p.x, p.y, Color("7a5a3a"))                    # the path
	for i in 4:                                               # the X
		_px(t, 10 + i, 3 + i, Color("d9302a"))
		_px(t, 13 - i, 3 + i, Color("d9302a"))
	_rect(t, 3, 4, 4, 5, Color("5aa04a"))                     # a little tree

# --- Hiding spots (M2 Task 5) -----------------------------------------------------------------

const BUSH_GREENS: Array[Color] = [Color("2e8a28"), Color("3fa535"), Color("4cb843"), Color("267a22")]
const BERRY := Color("e8403a")
const STAVE := Color("b07a40")
const STAVE_DARK := Color("8a5a2e")
const HOOP := Color("6f767e")
const HOOP_SHINE := Color("b9c0c8")
const CLOSET_WOOD := Color("9c6b34")
const CLOSET_PANEL := Color("c8924e")
const CLOSET_DARK := Color("5e3b1c")
const KNOB := Color("f2b632")

var hide_rng := RandomNumberGenerator.new()


func _hide_vary(c: Color, amount: float) -> Color:
	var d := hide_rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## A round, leafy shrub (cutout: a few gaps show through) with red berries. The top corners are cut
## round, so a row of bushes reads as bushes, not as a hedge of leaf blocks.
func _bush_side(t: Vector2i) -> void:
	hide_rng.seed = 2026092451
	for y in TILE:
		for x in TILE:
			var corner := y < 4 and Vector2(minf(x, TILE - 1 - x) - 3.5, y - 3.5).length() > 3.9 and minf(x, TILE - 1 - x) < 4
			if corner or hide_rng.randf() < 0.07:
				continue
			_px(t, x, y, _hide_vary(BUSH_GREENS[hide_rng.randi_range(0, BUSH_GREENS.size() - 1)], 0.04))
	for i in 6:
		var p := Vector2i(hide_rng.randi_range(2, TILE - 3), hide_rng.randi_range(4, TILE - 3))
		_px(t, p.x, p.y, BERRY)
		_px(t, p.x, p.y - 1, BERRY.lightened(0.35))


func _bush_top(t: Vector2i) -> void:
	hide_rng.seed = 2026092452
	for y in TILE:
		for x in TILE:
			if hide_rng.randf() < 0.07:
				continue
			_px(t, x, y, _hide_vary(BUSH_GREENS[hide_rng.randi_range(0, BUSH_GREENS.size() - 1)], 0.04))
	for i in 5:
		_px(t, hide_rng.randi_range(1, TILE - 2), hide_rng.randi_range(1, TILE - 2), BERRY)


## Wooden staves with dark seams, two iron hoops, darker at the edges (it bulges).
func _barrel_side(t: Vector2i) -> void:
	hide_rng.seed = 2026092453
	for y in TILE:
		for x in TILE:
			var c := STAVE_DARK if x % 4 == 0 else _hide_vary(STAVE if (x / 4) % 2 == 0 else STAVE.darkened(0.08), 0.03)
			if x <= 1 or x >= TILE - 2:
				c = c.darkened(0.2)
			if y == 3 or y == 12:
				c = HOOP_SHINE
			elif y == 4 or y == 13:
				c = HOOP
			_px(t, x, y, c)


## The lid: planks inside an iron rim, a dark bung.
func _barrel_top(t: Vector2i) -> void:
	hide_rng.seed = 2026092454
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := _hide_vary(STAVE if (y / 4) % 2 == 0 else STAVE.darkened(0.08), 0.03)
			if y % 4 == 0:
				c = STAVE_DARK
			if d > 7.6:
				c = STAVE_DARK.darkened(0.15)          # the staves' ends in the corners
			elif d > 6.2:
				c = HOOP if d > 6.9 else HOOP_SHINE
			_px(t, x, y, c)
	_rect(t, 10, 6, 11, 7, Color("3b2a1a"))


## A wardrobe's front: a dark frame, two doors with raised panels, gold knobs and little air slits at
## the top (you can peek out).
func _closet_front(t: Vector2i) -> void:
	hide_rng.seed = 2026092455
	for y in TILE:
		for x in TILE:
			var c := _hide_vary(CLOSET_WOOD, 0.03)
			var frame := x == 0 or x == TILE - 1 or y == 0 or y == TILE - 1
			var gap := x == 7 or x == 8
			var px := x - 1 if x < 7 else x - 9
			var panel := not frame and not gap and px >= 1 and px <= 4 and y >= 2 and y <= 13 and not (y == 7 or y == 8)
			if panel:
				c = _hide_vary(CLOSET_PANEL, 0.03)
			if frame:
				c = CLOSET_DARK
			elif gap:
				c = CLOSET_DARK if x == 7 else CLOSET_WOOD.darkened(0.2)
			_px(t, x, y, c)
	for x in [2, 4, 11, 13]:                                # air slits
		_rect(t, x, 3, x, 4, CLOSET_DARK)
	_px(t, 6, 9, KNOB)
	_px(t, 9, 9, KNOB)
	_px(t, 6, 8, KNOB.lightened(0.4))
	_px(t, 9, 8, KNOB.lightened(0.4))


func _closet_top(t: Vector2i) -> void:
	hide_rng.seed = 2026092456
	for y in TILE:
		for x in TILE:
			var c := _hide_vary(CLOSET_WOOD, 0.03)
			if y % 5 == 0:
				c = CLOSET_WOOD.darkened(0.18)
			if x == 0 or x == TILE - 1 or y == 0 or y == TILE - 1:
				c = CLOSET_DARK
			_px(t, x, y, c)

# --- Defenses (M2 Task 8): door, open door, spike trap, lantern ----------------------------------
# Tiles: door side (3, 4) (its top and bottom are planks), lantern top and bottom (4, 4), open door
# (5, 4, cut out), spike trap top (6, 4) and side (7, 4), lantern side (7, 3). The lantern tiles are
# drawn with the unshaded "glow" material, so their warm glass shines at night.

const DOOR_WOOD := Color("b5793f")
const DOOR_WOOD_LIGHT := Color("cf9656")
const DOOR_WOOD_DARK := Color("6e4522")
const IRON := Color("4a4f57")
const IRON_LIGHT := Color("9aa3ad")
const IRON_DARK := Color("2b2f36")
const BRASS := Color("f2c037")
const BRASS_DARK := Color("a8801c")
const HAZARD := Color("f7c52b")
const HAZARD_DARK := Color("1d2430")
const GLOW_CORE := Color("fff7d6")
const GLOW_EDGE := Color("f0a030")

var def_rng := RandomNumberGenerator.new()


func _def_vary(c: Color, amount: float) -> Color:
	var d := def_rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _defenses() -> void:
	def_rng.seed = 2026092480
	_door(Vector2i(3, 4))
	_lantern_top(Vector2i(4, 4))
	_door_open(Vector2i(5, 4))
	_spike_top(Vector2i(6, 4))
	_spike_side(Vector2i(7, 4))
	_lantern_side(Vector2i(7, 3))


## Three vertical planks in a dark frame, two iron bands with rivets and a brass knob on the right.
## Two doors stacked read as one tall door with four bands.
func _door(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := _def_vary(DOOR_WOOD if (x / 5) % 2 == 0 else DOOR_WOOD_LIGHT, 0.03)
			if x == 5 or x == 10:
				c = _def_vary(DOOR_WOOD_DARK.lightened(0.15), 0.02)      # seams between planks
			elif def_rng.randf() < 0.08:
				c = c.darkened(0.12)                                    # grain
			if x == 0 or x == TILE - 1:
				c = DOOR_WOOD_DARK
			_px(t, x, y, c)
	for band in [2, 12]:
		_rect(t, 1, band, TILE - 2, band + 1, IRON)
		_rect(t, 1, band, TILE - 2, band, IRON_LIGHT)
		for rx in [3, 12]:
			_px(t, rx, band + 1, IRON_LIGHT.lightened(0.3))
	_rect(t, 11, 6, 13, 9, IRON)                                        # knob plate
	_px(t, 12, 7, BRASS.lightened(0.3))
	_px(t, 12, 8, BRASS)
	_px(t, 13, 7, BRASS)
	_px(t, 13, 8, BRASS_DARK)


## An open door is a frame you walk through: the posts at both edges and the door leaf, swung open,
## seen edge-on along the left post. Everything else is clear (cut out).
func _door_open(t: Vector2i) -> void:
	for y in TILE:
		for x in [0, 1, TILE - 2, TILE - 1]:
			_px(t, x, y, DOOR_WOOD_DARK if x == 0 or x == TILE - 1 else _def_vary(DOOR_WOOD_DARK.lightened(0.12), 0.02))
		for x in [2, 3, 4]:
			_px(t, x, y, _def_vary(DOOR_WOOD_LIGHT if x == 3 else DOOR_WOOD, 0.03))
	for band in [2, 12]:
		_rect(t, 2, band, 4, band + 1, IRON)
		_rect(t, 2, band, 4, band, IRON_LIGHT)


## Seen from above: an iron plate with a yellow and black warning border and nine spike tips.
func _spike_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := _def_vary(Color("3a3f47"), 0.03)
			if x < 2 or x > TILE - 3 or y < 2 or y > TILE - 3:
				c = HAZARD if ((x + y) / 2) % 2 == 0 else HAZARD_DARK
			_px(t, x, y, c)
	for sy in [4, 8, 12]:
		for sx in [4, 8, 12]:
			_px(t, sx + 1, sy + 1, IRON_DARK)                          # shadow
			_px(t, sx - 1, sy, IRON_LIGHT)
			_px(t, sx, sy - 1, IRON_LIGHT)
			_px(t, sx + 1, sy, Color("5f6770"))
			_px(t, sx, sy + 1, Color("5f6770"))
			_px(t, sx, sy, Color("f1f5f9"))                            # the sharp tip


## From the side: three silver spikes over a warning band and an iron base with rivets.
func _spike_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var c := _def_vary(Color("23272e"), 0.02)
			if y >= 7 and y <= 9:
				c = HAZARD if ((x + y) / 2) % 2 == 0 else HAZARD_DARK
			elif y >= 10:
				c = _def_vary(IRON, 0.03)
			_px(t, x, y, c)
	for cx: float in [2.5, 7.5, 12.5]:
		for y in range(1, 7):
			var half := 0.35 + (y - 1) * 0.42
			for x in TILE:
				var dx := x - cx
				if absf(dx) <= half:
					_px(t, x, y, Color("c8d0d8") if dx < 0.0 else Color("7d848c"))
		_px(t, int(cx), 1, Color("f1f5f9"))
	_rect(t, 0, TILE - 1, TILE - 1, TILE - 1, IRON_DARK)
	for rx in [2, 13]:
		_px(t, rx, 12, IRON_LIGHT)


## A lantern: an iron cap and base, a dark frame with two bars, warm glass glowing round a flame.
func _lantern_side(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, (y - 8.0) * 0.8).length()
			var c := GLOW_CORE.lerp(GLOW_EDGE, clampf(d / 6.5, 0.0, 1.0))
			if x == 0 or x == TILE - 1 or x == 5 or x == 10:
				c = IRON_DARK
			if y <= 2 or y >= 13:
				c = _def_vary(IRON, 0.03)
			_px(t, x, y, c)
	_rect(t, 1, 2, TILE - 2, 2, IRON_LIGHT)                            # cap rim
	_rect(t, 1, 13, TILE - 2, 13, IRON_LIGHT)                          # base rim
	_rect(t, 7, 0, 8, 0, IRON_DARK)                                     # handle
	for p in [Vector2i(7, 7), Vector2i(8, 7), Vector2i(7, 8), Vector2i(8, 8)]:
		_px(t, p.x, p.y, Color.WHITE)                                   # the flame's heart
	for p in [Vector2i(7, 6), Vector2i(8, 9), Vector2i(7, 9)]:
		_px(t, p.x, p.y, Color("ffd060"))


## The lantern from above or below: an iron plate with rivets round a glowing round opening.
func _lantern_top(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x - 7.5, y - 7.5).length()
			var c := _def_vary(IRON, 0.03)
			if d < 4.0:
				c = GLOW_CORE.lerp(GLOW_EDGE, clampf(d / 4.0, 0.0, 1.0))
			elif d < 5.0:
				c = IRON_LIGHT
			if x == 0 or y == 0 or x == TILE - 1 or y == TILE - 1:
				c = IRON_DARK
			_px(t, x, y, c)
	for p in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
		_px(t, p.x, p.y, IRON_LIGHT.lightened(0.3))

# --- Owner #43 (our own look, spec §3c): the grass side and the ores, redrawn last with their own RNG ---------------
# The old drawings above still run first (so every other tile's random draws stay the same), then these draw over
# them: a soft, rounded cap of grass with little flowers (not a ragged fringe) and chunky round gems with a glint
# (not specks). Nothing else changes.

var ident_rng := RandomNumberGenerator.new()
const GRASS := Color("5bc236")
const GRASS_DARK := Color("3f9a2a")
const GRASS_LIGHT := Color("8fe05a")
const DIRT := Color("8b5a2b")
const PEBBLE := Color("a87a4a")
## How deep the cap hangs in each column: rounded scallops, never a jump of more than one pixel.
const CAP: Array[int] = [4, 5, 6, 6, 5, 4, 4, 5, 6, 6, 5, 4, 4, 5, 5, 4]


func _identity_pass() -> void:
	ident_rng.seed = 20260943
	_grass_side_round(Vector2i(1, 0))
	_gems(Vector2i(4, 2), Color("26262b"), Color("0e0e10"))     # coal: black lumps
	_gems(Vector2i(5, 2), Color("d8a27a"), Color("8a5a3a"))     # iron: peachy nuggets
	_gems(Vector2i(6, 2), Color("f7c52b"), Color("a8740f"))     # gold
	_gems(Vector2i(7, 2), Color("35e0e0"), Color("15888f"))     # diamond


func _ident_vary(c: Color, amount: float) -> Color:
	var d := ident_rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


## Dirt with a few round pebbles, under a rounded cap of grass: a light top row, a darker lip along its scalloped
## edge, two tiny flowers in it.
func _grass_side_round(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _ident_vary(DIRT, 0.06))
	for p: Vector2i in [Vector2i(3, 10), Vector2i(11, 12), Vector2i(7, 14), Vector2i(13, 8)]:
		_px(t, p.x, p.y, PEBBLE)
		_px(t, p.x + 1, p.y, PEBBLE.lightened(0.15))
		_px(t, p.x, p.y + 1, DIRT.darkened(0.25))
		_px(t, p.x + 1, p.y + 1, DIRT.darkened(0.25))
	for x in TILE:
		var depth := CAP[x]
		for y in depth:
			var c := GRASS
			if y == 0:
				c = GRASS_LIGHT
			elif y == depth - 1:
				c = GRASS_DARK
			_px(t, x, y, _ident_vary(c, 0.04))
	_px(t, 2, 2, Color("ff7ac8"))     # a pink flower
	_px(t, 2, 1, Color("ffd1ea"))
	_px(t, 9, 3, Color("ffe14d"))     # a yellow one
	_px(t, 9, 2, Color("fff6b0"))


## Stone with three chunky round gems: a dark rim, the gem's colour, a lighter face and a white glint.
func _gems(t: Vector2i, gem: Color, rim: Color) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _ident_vary(Color("6f747c"), 0.05))
	for g: Vector3 in [Vector3(4.0, 4.0, 2.7), Vector3(11.0, 5.5, 2.4), Vector3(6.5, 11.5, 2.9)]:
		for y in TILE:
			for x in TILE:
				var d := Vector2(x, y).distance_to(Vector2(g.x, g.y))
				if d > g.z:
					continue
				var c := rim if d > g.z - 0.9 else gem
				if d < g.z - 0.9 and x < g.x and y < g.y:
					c = gem.lightened(0.3)   # the lit face
				_px(t, x, y, c)
		_px(t, int(g.x) - 1, int(g.y) - 1, Color.WHITE)   # the glint
