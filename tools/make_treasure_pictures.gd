extends SceneTree
## Generates data/secrets/treasure_pictures.png (owner feedback #42): 8 × 3 tiles of 16 px, the treasure pack's
## pictures (ids TreasureRules.FIRST_PICTURE + tile: a kind per tile for the Secret Book and banners, then the
## riddles' pictures). Original pixel art, drawn without randomness, in the style of make_secret_pictures.gd.
## Run: godot --headless --path . --script res://tools/make_treasure_pictures.gd

const TILE := 16
const COLUMNS := 8
const ROWS := 3
const OUT := "res://data/secrets/treasure_pictures.png"
const OUTLINE := Color("2a2230")
const CLEAR := Color(0, 0, 0, 0)

var img: Image


func _init() -> void:
	img = Image.create(TILE * COLUMNS, TILE * ROWS, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	var draw := [_shipwreck, _sunken, _mineshaft, _vault, _waterfall, _hollow_tree, _rainbow, _well, _cove, _ruins,
		_haunted, _camp, _anchor, _crown, _gem, _coin, _pickaxe, _lever, _waves, _fire, _ghost, _drop]
	for i in draw.size():
		(draw[i] as Callable).call(Vector2i(i % COLUMNS, i / COLUMNS))
	var err := img.save_png(OUT)
	print("TREASURE_PICTURES saved err=", err)
	quit()


func _px(t: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE and y < TILE:
		img.set_pixel(t.x * TILE + x, t.y * TILE + y, c)


func _rect(t: Vector2i, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(t, x, y, c)


func _disc(t: Vector2i, cx: float, cy: float, r: float, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				_px(t, x, y, c)


func _poly(t: Vector2i, points: PackedVector2Array, c: Color) -> void:
	for y in TILE:
		for x in TILE:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_px(t, x, y, c)


## A dark outline around everything drawn in the tile.
func _outline(t: Vector2i) -> void:
	var filled := {}
	for y in TILE:
		for x in TILE:
			if img.get_pixel(t.x * TILE + x, t.y * TILE + y).a > 0.5:
				filled[Vector2i(x, y)] = true
	for y in TILE:
		for x in TILE:
			if filled.has(Vector2i(x, y)):
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if filled.has(Vector2i(x, y) + d):
					_px(t, x, y, OUTLINE)
					break


# --- The kinds (the Secret Book's "Treasure Hunt" page) ---

func _shipwreck(t: Vector2i) -> void:
	_rect(t, 0, 13, 15, 15, Color("3a8ee8"))                # the sea
	_poly(t, PackedVector2Array([Vector2(1, 9), Vector2(15, 7), Vector2(13, 13), Vector2(3, 13)]), Color("8a5a2e"))
	_rect(t, 4, 10, 11, 10, Color("b8834a"))                # a plank
	_rect(t, 7, 1, 7, 9, Color("6e4522"))                   # the mast, leaning
	_poly(t, PackedVector2Array([Vector2(8, 2), Vector2(13, 5), Vector2(8, 7)]), Color("e8403a"))   # a torn sail
	_px(t, 10, 5, CLEAR)
	_outline(t)


func _sunken(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, Color("2c6fc2"))                 # deep water
	_rect(t, 0, 13, 15, 15, Color("e0c27a"))                # the seabed
	_rect(t, 4, 8, 11, 13, Color("9c6b34"))                 # a chest
	_rect(t, 4, 8, 11, 9, Color("b8834a"))
	_rect(t, 7, 10, 8, 11, Color("f2c230"))
	for p: Vector2i in [Vector2i(3, 5), Vector2i(5, 2), Vector2i(12, 4), Vector2i(10, 1)]:
		_px(t, p.x, p.y, Color("bfe6ff"))                   # bubbles
	_outline(t)


func _mineshaft(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, Color("5a5048"))                 # a tunnel's dark
	_rect(t, 1, 1, 2, 15, Color("8a5a2e"))                  # posts and a beam
	_rect(t, 13, 1, 14, 15, Color("8a5a2e"))
	_rect(t, 1, 1, 14, 2, Color("b8834a"))
	_rect(t, 7, 3, 8, 4, Color("ffd23f"))                   # a lantern
	_rect(t, 3, 14, 12, 14, Color("b8834a"))                # rails
	_rect(t, 4, 8, 11, 12, Color("7d848c"))                 # a cart
	_rect(t, 5, 7, 10, 8, Color("f2c230"))                  # gold in it
	_rect(t, 5, 13, 5, 13, OUTLINE)
	_rect(t, 10, 13, 10, 13, OUTLINE)
	_outline(t)


func _vault(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, Color("8e949b"))                 # a stone wall
	_rect(t, 4, 3, 11, 15, Color("f2c230"))                 # the golden door
	_rect(t, 5, 2, 10, 2, Color("f2c230"))
	_rect(t, 7, 7, 8, 9, Color("2a2230"))                   # a keyhole
	for x in [1, 13]:
		_rect(t, x, 6, x + 1, 7, Color("6e4522"))           # levers
		_rect(t, x + 1, 3, x + 1, 5, Color("c9ced4"))
	_outline(t)


func _waterfall(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, Color("7d848c"))                 # a rock
	_rect(t, 0, 0, 15, 1, Color("5bc236"))                  # moss on top
	_rect(t, 5, 0, 10, 13, Color("6fc3ff"))                 # falling water
	for y in [2, 5, 8, 11]:
		_rect(t, 6, y, 7, y, Color("e6f6ff"))
	_rect(t, 6, 9, 9, 13, Color("1c2230"))                  # the cave behind it
	_rect(t, 0, 14, 15, 15, Color("3a8ee8"))                # the pool
	_outline(t)


func _hollow_tree(t: Vector2i) -> void:
	_disc(t, 8, 5, 5.6, Color("3fa535"))
	_rect(t, 4, 7, 11, 15, Color("8a5a2e"))                 # a thick trunk
	_rect(t, 6, 10, 9, 15, Color("2a1a10"))                 # its doorway
	_rect(t, 7, 12, 8, 13, Color("f2c230"))                 # treasure inside
	_outline(t)


func _rainbow(t: Vector2i) -> void:
	var bands := [Color("ff4b4b"), Color("ff9a3c"), Color("ffe14a"), Color("5fd35b"), Color("4aa3ff"), Color("9b6bff")]
	for y in TILE:
		for x in TILE:
			var d := Vector2(x + 0.5 - 8, y + 0.5 - 13).length()
			var b := int(7.5 - d)
			if y < 12 and b >= 0 and b < bands.size() and d >= 1.5:
				_px(t, x, y, bands[5 - b])
	_rect(t, 12, 13, 15, 15, Color("2b2b33"))               # a pot at its end
	_rect(t, 12, 12, 15, 12, Color("f2c230"))
	_outline(t)


func _well(t: Vector2i) -> void:
	_rect(t, 2, 1, 13, 3, Color("b8834a"))                  # a little roof
	_rect(t, 3, 4, 3, 9, Color("6e4522"))                   # posts
	_rect(t, 12, 4, 12, 9, Color("6e4522"))
	_rect(t, 2, 9, 13, 15, Color("9aa0a6"))                 # the stone rim
	_rect(t, 4, 10, 11, 11, Color("3a8ee8"))                # water
	_rect(t, 7, 5, 8, 7, Color("9c6b34"))                   # the bucket
	_outline(t)


func _cove(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(0, 15.5), Vector2(0, 7), Vector2(6, 3), Vector2(12, 5), Vector2(16, 10), Vector2(16, 15.5)]), Color("7d848c"))
	_disc(t, 8, 15, 5.2, Color("1c2230"))                   # the cave's mouth
	_rect(t, 3, 14, 12, 15, Color("3a8ee8"))                # the lagoon
	_rect(t, 6, 0, 6, 4, Color("6e4522"))                   # a flag
	_rect(t, 7, 0, 10, 2, Color("e8403a"))
	_px(t, 8, 1, Color("ffd23f"))
	_outline(t)


func _ruins(t: Vector2i) -> void:
	_rect(t, 0, 13, 15, 15, Color("9aa0a6"))                # a broken floor
	_rect(t, 2, 3, 4, 12, Color("c9ced4"))                  # a standing pillar
	_rect(t, 1, 2, 5, 3, Color("b0b6bd"))
	_rect(t, 11, 8, 13, 12, Color("c9ced4"))                # a broken one
	_rect(t, 6, 11, 11, 12, Color("b0b6bd"))                # a fallen one
	_rect(t, 7, 13, 8, 13, Color("5bc236"))                 # grass in the cracks
	_outline(t)


func _haunted(t: Vector2i) -> void:
	_rect(t, 2, 7, 13, 15, Color("6e4522"))
	_poly(t, PackedVector2Array([Vector2(0.5, 7.5), Vector2(8, 1), Vector2(15.5, 7.5)]), Color("4a3326"))
	_rect(t, 7, 11, 8, 15, Color("2a1a10"))                 # the door
	_rect(t, 4, 9, 5, 10, Color("fff3a8"))                  # glowing windows
	_rect(t, 10, 9, 11, 10, Color("fff3a8"))
	_disc(t, 13, 2.5, 2.4, Color("f4f7ff"))                 # a little ghost peeking out
	_rect(t, 11, 3, 15, 5, Color("f4f7ff"))
	_px(t, 12, 2, OUTLINE)
	_px(t, 14, 2, OUTLINE)
	_outline(t)


func _camp(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(1, 13), Vector2(6, 3), Vector2(11, 13)]), Color("e8403a"))   # a tent
	_poly(t, PackedVector2Array([Vector2(4, 13), Vector2(6, 8), Vector2(8, 13)]), Color("ffd23f"))
	_rect(t, 11, 12, 15, 13, Color("8a5a2e"))               # logs
	_poly(t, PackedVector2Array([Vector2(11.5, 12), Vector2(13, 7), Vector2(14.5, 12)]), Color("ff9a3c"))   # a fire
	_px(t, 13, 10, Color("ffe14a"))
	_rect(t, 0, 14, 15, 15, Color("5bc236"))
	_outline(t)


# --- Riddles' pictures ---

func _anchor(t: Vector2i) -> void:
	var c := Color("7d848c")
	_disc(t, 8, 3, 2.2, c)
	_disc(t, 8, 3, 0.9, CLEAR)
	_rect(t, 7, 5, 8, 14, c)                                # the shank
	_rect(t, 4, 7, 11, 7, c)                                # the stock
	_rect(t, 2, 11, 3, 13, c)                               # the arms
	_rect(t, 12, 11, 13, 13, c)
	_rect(t, 3, 13, 12, 14, c)
	_outline(t)


func _crown(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(1, 13), Vector2(1, 4), Vector2(5, 8), Vector2(8, 2), Vector2(11, 8), Vector2(15, 4), Vector2(15, 13)]), Color("f2c230"))
	_rect(t, 1, 11, 14, 13, Color("d9a520"))
	_px(t, 4, 11, Color("e8403a"))                          # jewels
	_px(t, 8, 11, Color("3a7be8"))
	_px(t, 11, 11, Color("3cc45a"))
	_outline(t)


func _gem(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(3, 5), Vector2(6, 2), Vector2(10, 2), Vector2(13, 5), Vector2(8, 14)]), Color("3fd6e8"))
	_poly(t, PackedVector2Array([Vector2(3, 5), Vector2(13, 5), Vector2(8, 14)]), Color("22a9c9"))
	_rect(t, 6, 3, 7, 4, Color("d6fbff"))                   # a shine
	_outline(t)


func _coin(t: Vector2i) -> void:
	_disc(t, 8, 8, 6.4, Color("f2c230"))
	_disc(t, 8, 8, 4.4, Color("ffd23f"))
	_rect(t, 7, 5, 8, 11, Color("d9a520"))                  # a mark
	_disc(t, 6, 6, 1.1, Color("fff3a8"))
	_outline(t)


func _pickaxe(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(1, 5), Vector2(8, 1), Vector2(15, 5), Vector2(14, 6), Vector2(8, 3), Vector2(2, 6)]), Color("9aa0a6"))
	for i in 10:
		_px(t, 7 + (i / 5), 3 + i, Color("8a5a2e"))          # the handle
		_px(t, 8 + (i / 5), 3 + i, Color("8a5a2e"))
	_outline(t)


func _lever(t: Vector2i) -> void:
	_rect(t, 3, 11, 12, 14, Color("7d848c"))                # the base
	for i in 8:
		_px(t, 7 + i / 2, 10 - i, Color("c9ced4"))          # the handle
		_px(t, 8 + i / 2, 10 - i, Color("c9ced4"))
	_disc(t, 11.5, 2.5, 2.0, Color("e8403a"))               # its knob
	_outline(t)


func _waves(t: Vector2i) -> void:
	for row in 3:
		for x in TILE:
			var y := 4 + row * 4 + roundi(sin(x * 0.8) * 1.2)
			_rect(t, x, y, x, y + 1, Color("3a8ee8") if row != 1 else Color("6fc3ff"))
	_outline(t)


func _fire(t: Vector2i) -> void:
	_rect(t, 2, 13, 13, 14, Color("8a5a2e"))                # logs
	_poly(t, PackedVector2Array([Vector2(3, 13), Vector2(5, 6), Vector2(8, 1), Vector2(11, 6), Vector2(13, 13)]), Color("ff7a1c"))
	_poly(t, PackedVector2Array([Vector2(5, 13), Vector2(8, 5), Vector2(11, 13)]), Color("ffd23f"))
	_outline(t)


func _ghost(t: Vector2i) -> void:
	_disc(t, 8, 6.5, 5.5, Color("f4f7ff"))
	_rect(t, 3, 7, 13, 13, Color("f4f7ff"))
	for x in [3, 6, 9, 12]:
		_rect(t, x, 14, x + 1, 14, Color("f4f7ff"))         # a wavy hem
	_rect(t, 5, 5, 6, 7, OUTLINE)                           # eyes
	_rect(t, 9, 5, 10, 7, OUTLINE)
	_rect(t, 7, 10, 8, 10, OUTLINE)                          # a little smile
	_px(t, 6, 9, OUTLINE)
	_px(t, 9, 9, OUTLINE)
	_px(t, 4, 9, Color("ff9fc2"))                           # cheeks
	_px(t, 11, 9, Color("ff9fc2"))
	_outline(t)


func _drop(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(8, 1), Vector2(12, 8), Vector2(4, 8)]), Color("4aa3ff"))
	_disc(t, 8, 10, 4.4, Color("4aa3ff"))
	_disc(t, 6.5, 9, 1.2, Color("d6f0ff"))
	_outline(t)
