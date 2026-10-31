extends SceneTree
## Generates data/items/item_icons.png (M2 Task 6): the item icon atlas, 8 x 8 tiles of 16 px.
## Run: godot --headless --path . --script res://tools/make_item_icons.gd   (then --import)
## Deterministic pixel art, no RNG. It is imported as an Image (item_icons.png.import), so the game
## reads its pixels on every renderer.
##
## Rows (plan allocations): 0-3 Task 6, 4 Task 16 (secrets), 5 Task 15 (bots), 6-7 free.
## - Row 0: one picture per tiered kind (ui/hud/block_icons.gd KIND_TILES): sword, bow, pickaxe,
##   axe, spear, mace, shield. Their metal is drawn in pure greys (r = g = b): BlockIcons tints
##   exactly those pixels in the tier's rarity colour, then adds the rarity rim and 1-5 tier pips.
##   The band x < 13, y < 3 stays empty for the pips.
## - Row 1: the potions (POTION_TILES): Moon Jump, Invisibility, Speed.

const TILE := 16
const GRID := 8
const OUT := "res://data/items/item_icons.png"

# Metal: pure greys only (they take the tier's colour).
const METAL_LIGHT := Color(0.93, 0.93, 0.93)
const METAL := Color(0.66, 0.66, 0.66)
const METAL_DARK := Color(0.42, 0.42, 0.42)
const SHINE := Color(1, 1, 1)
# Everything else keeps its colour (never a pure grey).
const WOOD := Color("8a5a2e")
const WOOD_DARK := Color("6e4522")
const GRIP := Color("7a4a24")
const LEATHER := Color("5a3a1e")
const GOLD := Color("f2b632")
const GOLD_DARK := Color("b07d18")
const STRING := Color("f3efe6")
const SHAFT := Color("c8b28a")
const RED := Color("e8403a")
const CORK := Color("b5835a")
const GLASS := Color("cfeefe")
const GLASS_EDGE := Color("9fd4ee")

var img: Image


func _init() -> void:
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_sword(Vector2i(0, 0))
	_bow(Vector2i(1, 0))
	_pickaxe(Vector2i(2, 0))
	_axe(Vector2i(3, 0))
	_spear(Vector2i(4, 0))
	_mace(Vector2i(5, 0))
	_shield(Vector2i(6, 0))
	_potion(Vector2i(0, 1), Color("4fa8ff"), &"moon")
	_potion(Vector2i(1, 1), Color("b9a2ff"), &"sparkle")
	_potion(Vector2i(2, 1), Color("ff9a1a"), &"bolt")
	var err := img.save_png(OUT)
	print("ITEM_ICONS saved err=", err)
	quit()


func _px(t: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < TILE and y >= 0 and y < TILE:
		img.set_pixel(t.x * TILE + x, t.y * TILE + y, c)


func _rect(t: Vector2i, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(t, x, y, c)


## A 45-degree stroke from `a` towards `b`, `width` pixels wide (extending to the right).
func _stroke(t: Vector2i, a: Vector2i, b: Vector2i, c: Color, width: int = 2) -> void:
	var d := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var p := a + d * i
		for w in width:
			_px(t, p.x + w, p.y, c)


## Pixels whose centre lies within `r_out` (and beyond `r_in`) of `center`.
func _ring(t: Vector2i, center: Vector2, r_in: float, r_out: float, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d <= r_out and d > r_in:
				_px(t, x, y, c)


# --- Row 0: tiered kinds -------------------------------------------------------------------------

func _sword(t: Vector2i) -> void:
	_stroke(t, Vector2i(5, 10), Vector2i(12, 3), METAL_LIGHT)                # blade
	_stroke(t, Vector2i(7, 10), Vector2i(13, 4), METAL, 1)                   # blade shade
	_px(t, 13, 2, METAL_LIGHT)
	_px(t, 14, 1, SHINE)                                                     # tip
	_stroke(t, Vector2i(2, 9), Vector2i(6, 13), GOLD, 1)                     # guard
	_stroke(t, Vector2i(3, 9), Vector2i(7, 13), GOLD_DARK, 1)
	_stroke(t, Vector2i(2, 13), Vector2i(3, 12), GRIP)                       # grip
	_px(t, 1, 14, GOLD)                                                      # pommel


func _bow(t: Vector2i) -> void:
	for y in range(3, 15):
		_px(t, 3, y, STRING)                                                 # string
		var x := 3 + roundi(7.0 * sin(PI * (y - 3) / 11.0))
		_px(t, x, y, WOOD)                                                   # limb
		_px(t, x + 1, y, WOOD_DARK)
	_rect(t, 3, 3, 4, 3, METAL)                                              # limb tips
	_rect(t, 3, 14, 4, 14, METAL)
	_rect(t, 10, 8, 11, 9, LEATHER)                                          # grip
	_rect(t, 2, 9, 12, 9, SHAFT)                                             # arrow shaft
	_rect(t, 13, 8, 13, 10, METAL)                                           # arrow head
	_px(t, 14, 9, SHINE)
	_px(t, 1, 8, RED)                                                        # fletching
	_px(t, 1, 10, RED)


func _pickaxe(t: Vector2i) -> void:
	_stroke(t, Vector2i(2, 14), Vector2i(10, 6), WOOD)                       # handle
	for k in range(-5, 5):                                                   # curved head
		var x := 9 + k
		var y := 9 + k - roundi((25 - k * k) * 0.2)
		_px(t, x, y, METAL_LIGHT)
		_px(t, x, y + 1, METAL_DARK if absi(k) > 1 else METAL)
	_px(t, 9, 4, SHINE)


func _axe(t: Vector2i) -> void:
	for y in TILE:                                                           # half-moon blade
		for x in TILE:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(8.0, 8.0))
			if d <= 4.6 and x + y <= 14:
				_px(t, x, y, METAL_LIGHT if d > 3.4 else METAL)
	_stroke(t, Vector2i(2, 14), Vector2i(11, 5), WOOD)                       # handle
	_px(t, 12, 4, WOOD_DARK)
	_px(t, 9, 9, METAL_DARK)                                                 # the blade's socket
	_px(t, 10, 8, METAL_DARK)


func _spear(t: Vector2i) -> void:
	_stroke(t, Vector2i(2, 14), Vector2i(10, 6), WOOD, 1)                    # shaft
	_stroke(t, Vector2i(3, 14), Vector2i(11, 6), WOOD_DARK, 1)
	_rect(t, 4, 11, 5, 12, LEATHER)                                          # grip wrap
	_px(t, 11, 5, METAL_DARK)                                                # socket
	_stroke(t, Vector2i(11, 4), Vector2i(13, 2), METAL_LIGHT, 1)             # leaf head
	_stroke(t, Vector2i(12, 5), Vector2i(14, 3), METAL, 1)
	_px(t, 12, 3, METAL)
	_px(t, 13, 4, METAL_DARK)
	_px(t, 14, 1, SHINE)                                                     # tip
	_px(t, 14, 2, METAL_LIGHT)


func _mace(t: Vector2i) -> void:
	_stroke(t, Vector2i(2, 14), Vector2i(8, 8), WOOD)                        # handle
	_rect(t, 2, 13, 3, 14, LEATHER)
	var c := Vector2(10.5, 6.5)
	for y in TILE:                                                           # ball head, lit from the top left
		for x in TILE:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= 3.2:
				var lit := (p - c).dot(Vector2(-1, -1).normalized())
				_px(t, x, y, METAL_LIGHT if lit > 1.2 else (METAL_DARK if lit < -1.2 else METAL))
	for s in [Vector2i(14, 6), Vector2i(14, 7), Vector2i(10, 10), Vector2i(11, 10), Vector2i(13, 3), Vector2i(7, 4),
			Vector2i(13, 9), Vector2i(10, 3)]:                               # spikes
		_px(t, s.x, s.y, SHINE)


func _shield(t: Vector2i) -> void:
	var c := Vector2(8.0, 9.0)
	for y in TILE:                                                           # wooden planks
		for x in TILE:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= 4.5:
				_px(t, x, y, WOOD_DARK if x % 3 == 0 else WOOD)
	_ring(t, c, 4.5, 5.7, METAL)                                             # metal rim
	_ring(t, c + Vector2(-0.6, -0.6), 4.6, 5.3, METAL_LIGHT)
	_ring(t, c, 5.2, 5.7, METAL_DARK)
	_ring(t, c, 0.0, 1.7, METAL)                                             # boss
	_px(t, 7, 8, SHINE)


# --- Row 1: potions ------------------------------------------------------------------------------

## A round bottle with a cork, `liquid` in the lower two thirds and a symbol on it.
func _potion(t: Vector2i, liquid: Color, symbol: StringName) -> void:
	var c := Vector2(8.0, 10.0)
	_rect(t, 7, 1, 8, 2, CORK)
	_rect(t, 7, 3, 8, 5, GLASS)
	_px(t, 6, 3, GLASS_EDGE)
	_px(t, 9, 3, GLASS_EDGE)
	for y in TILE:
		for x in TILE:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= 4.9:
				var inside := d <= 4.0
				var col := GLASS_EDGE if not inside else (liquid if y >= 8 else GLASS)
				if inside and y >= 8 and x >= 9:
					col = liquid.darkened(0.2)
				_px(t, x, y, col)
	_px(t, 5, 8, Color.WHITE)                                                # glint
	_px(t, 5, 9, Color.WHITE)
	var mark := Color("fff1a8")
	match symbol:
		&"moon":                                                             # a crescent
			for y in range(8, 14):
				for x in range(5, 11):
					var q := Vector2(x + 0.5, y + 0.5)
					if q.distance_to(Vector2(7.6, 11.0)) <= 2.3 and q.distance_to(Vector2(8.8, 10.2)) > 1.9:
						_px(t, x, y, mark)
		&"sparkle":
			for p in [Vector2i(8, 9), Vector2i(8, 10), Vector2i(8, 11), Vector2i(7, 10), Vector2i(9, 10), Vector2i(10, 12), Vector2i(6, 12)]:
				_px(t, p.x, p.y, Color.WHITE)
		&"bolt":
			for p in [Vector2i(9, 8), Vector2i(8, 9), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10), Vector2i(8, 11), Vector2i(7, 12)]:
				_px(t, p.x, p.y, mark)
