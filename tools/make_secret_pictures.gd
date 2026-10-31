extends SceneTree
## Generates data/secrets/pictures.png (M2 Task 16): 8 × 4 tiles of 16 px, the pictures of riddles, temple
## plates and the Secret Book (ids: core/rules/riddles.gd). Original pixel art, drawn without randomness.
## Run: godot --headless --path . --script res://tools/make_secret_pictures.gd

const TILE := 16
const COLUMNS := 8
const ROWS := 4
const OUT := "res://data/secrets/pictures.png"
const OUTLINE := Color("2a2230")

var img: Image


func _init() -> void:
	img = Image.create(TILE * COLUMNS, TILE * ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var draw := [_sun, _moon, _star, _clock, _tree, _fish, _apple, _cloud, _key, _cat, _house, _ball, _flower,
		_heart, _chest, _map_x, _door, _island, _golden, _temple, _wanderer, _geode, _note, _question]
	for i in draw.size():
		(draw[i] as Callable).call(Vector2i(i % COLUMNS, i / COLUMNS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var err := img.save_png(OUT)
	print("PICTURES saved err=", err)
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


## A dark outline around everything drawn in the tile (reads well on any background).
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


func _star_points(cx: float, cy: float, r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		var r := r_out if i % 2 == 0 else r_in
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts


func _sun(t: Vector2i) -> void:
	for i in 8:
		var a := i * PI / 4
		for k in range(5, 8):
			_px(t, roundi(7.5 + cos(a) * k - 0.5), roundi(7.5 + sin(a) * k - 0.5), Color("ff9f1c"))
	_disc(t, 8, 8, 4.6, Color("ffd23f"))
	_disc(t, 6.8, 6.8, 1.6, Color("fff3a8"))
	_outline(t)


func _moon(t: Vector2i) -> void:
	_disc(t, 8, 8, 6.2, Color("f7f0c6"))
	_disc(t, 11, 5.5, 5.2, Color(0, 0, 0, 0))               # the bite (clear pixels)
	_px(t, 5, 9, Color("d9cf9a"))
	_px(t, 6, 12, Color("d9cf9a"))
	_outline(t)


func _star(t: Vector2i) -> void:
	_poly(t, _star_points(8, 8.5, 7.5, 3.2), Color("ffd23f"))
	_poly(t, _star_points(7.5, 8, 3.5, 1.5), Color("fff3a8"))
	_outline(t)


func _clock(t: Vector2i) -> void:
	_disc(t, 8, 8, 6.8, Color("e8403a"))
	_disc(t, 8, 8, 5.6, Color("fbfbf5"))
	_rect(t, 7, 4, 8, 8, Color("2a2230"))                   # hands: 12 o'clock
	_rect(t, 8, 7, 11, 8, Color("2a2230"))                  # and 3 o'clock
	for p: Vector2i in [Vector2i(7, 3), Vector2i(12, 7), Vector2i(7, 12), Vector2i(3, 7)]:
		_px(t, p.x, p.y, Color("8a8a96"))
	_outline(t)


func _tree(t: Vector2i) -> void:
	_rect(t, 7, 10, 8, 15, Color("8a5a2e"))
	_disc(t, 8, 6.5, 5.8, Color("3fa535"))
	_disc(t, 6.5, 5, 2.2, Color("6fd05a"))
	_outline(t)


func _fish(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(11, 8), Vector2(16, 3.5), Vector2(16, 12.5)]), Color("f08a1c"))
	for y in TILE:
		for x in TILE:
			if pow((x + 0.5 - 6.5) / 6.0, 2) + pow((y + 0.5 - 8) / 4.0, 2) <= 1.0:
				_px(t, x, y, Color("ff8a3d"))
	_rect(t, 4, 6, 4, 6, Color("2a2230"))                   # eye
	_rect(t, 7, 9, 9, 9, Color("ffe08a"))                   # belly stripe
	_outline(t)


func _apple(t: Vector2i) -> void:
	_disc(t, 6, 9, 5.2, Color("e8403a"))
	_disc(t, 10, 9, 5.2, Color("e8403a"))
	_rect(t, 7, 1, 8, 4, Color("7a4a24"))                   # stem
	_poly(t, PackedVector2Array([Vector2(9, 3), Vector2(14, 1), Vector2(12, 5)]), Color("3cc45a"))
	_disc(t, 5, 7, 1.4, Color("ffb3a8"))                    # shine
	_outline(t)


func _cloud(t: Vector2i) -> void:
	_disc(t, 5, 9.5, 3.8, Color("f4f8ff"))
	_disc(t, 9, 7.5, 4.6, Color("f4f8ff"))
	_disc(t, 12.5, 10, 3.2, Color("f4f8ff"))
	_rect(t, 4, 11, 13, 13, Color("f4f8ff"))
	_rect(t, 4, 13, 13, 13, Color("c9d8ee"))
	_outline(t)


func _key(t: Vector2i) -> void:
	_disc(t, 5, 6, 4.2, Color("f2c230"))
	_disc(t, 5, 6, 1.8, Color(0, 0, 0, 0))                  # the ring's hole
	_rect(t, 8, 5, 14, 7, Color("f2c230"))                  # shaft
	_rect(t, 12, 8, 12, 10, Color("f2c230"))                # teeth
	_rect(t, 14, 8, 14, 9, Color("f2c230"))
	_rect(t, 9, 5, 13, 5, Color("ffe27a"))
	_outline(t)


func _cat(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(2, 1), Vector2(7, 5), Vector2(2, 7)]), Color("e8a24a"))
	_poly(t, PackedVector2Array([Vector2(14, 1), Vector2(9, 5), Vector2(14, 7)]), Color("e8a24a"))
	_disc(t, 8, 9, 6.2, Color("e8a24a"))
	_rect(t, 5, 8, 5, 9, Color("2a2230"))                   # eyes
	_rect(t, 10, 8, 10, 9, Color("2a2230"))
	_rect(t, 7, 11, 8, 11, Color("f28cb1"))                 # nose
	_rect(t, 1, 11, 3, 11, Color("fbe9d0"))                 # whiskers
	_rect(t, 12, 11, 14, 11, Color("fbe9d0"))
	_outline(t)


func _house(t: Vector2i) -> void:
	_rect(t, 3, 8, 12, 14, Color("c8924e"))
	_poly(t, PackedVector2Array([Vector2(0.5, 8.5), Vector2(8, 1), Vector2(15.5, 8.5)]), Color("d9463b"))
	_rect(t, 7, 11, 8, 14, Color("6e4522"))
	_rect(t, 4, 9, 5, 10, Color("bfe6ff"))
	_rect(t, 10, 9, 11, 10, Color("bfe6ff"))
	_outline(t)


func _ball(t: Vector2i) -> void:
	_disc(t, 8, 8, 6.6, Color("3a7be8"))
	for y in TILE:
		for x in TILE:
			if Vector2(x + 0.5 - 8, y + 0.5 - 8).length() <= 6.6 and absi(x - y) <= 1:
				_px(t, x, y, Color("fbfbf5"))
	_disc(t, 5.5, 5.5, 1.3, Color("a9c9ff"))
	_outline(t)


func _flower(t: Vector2i) -> void:
	_rect(t, 7, 9, 8, 15, Color("3cc45a"))
	_rect(t, 9, 12, 11, 13, Color("3cc45a"))                # a leaf
	for i in 5:
		var a := -PI / 2 + i * TAU / 5
		_disc(t, 8 + cos(a) * 3.6, 6 + sin(a) * 3.6, 2.4, Color("f26bb5"))
	_disc(t, 8, 6, 2.0, Color("ffd23f"))
	_outline(t)


func _heart(t: Vector2i) -> void:
	_disc(t, 5, 6, 3.8, Color("e8403a"))
	_disc(t, 11, 6, 3.8, Color("e8403a"))
	_poly(t, PackedVector2Array([Vector2(1.4, 7.5), Vector2(14.6, 7.5), Vector2(8, 14.5)]), Color("e8403a"))
	_disc(t, 4.5, 5, 1.2, Color("ffb3a8"))
	_outline(t)


func _chest(t: Vector2i) -> void:
	_rect(t, 1, 5, 14, 14, Color("9c6b34"))
	_rect(t, 1, 3, 14, 7, Color("b8834a"))                  # lid
	_rect(t, 1, 8, 14, 8, Color("f2c230"))                  # gold band
	_rect(t, 3, 3, 3, 14, Color("f2c230"))
	_rect(t, 12, 3, 12, 14, Color("f2c230"))
	_rect(t, 7, 7, 8, 10, Color("ffe27a"))                  # lock
	_rect(t, 7, 9, 8, 9, Color("2a2230"))
	_outline(t)


func _map_x(t: Vector2i) -> void:
	_rect(t, 1, 2, 14, 13, Color("ecdcae"))
	_rect(t, 1, 2, 14, 2, Color("c8b27c"))
	_rect(t, 1, 13, 14, 13, Color("c8b27c"))
	for p: Vector2i in [Vector2i(3, 11), Vector2i(4, 10), Vector2i(6, 10), Vector2i(7, 9), Vector2i(8, 8)]:
		_px(t, p.x, p.y, Color("7a5a3a"))
	for i in 5:
		_px(t, 9 + i, 3 + i, Color("d9302a"))
		_px(t, 13 - i, 3 + i, Color("d9302a"))
	_outline(t)


func _door(t: Vector2i) -> void:
	_rect(t, 0, 1, 15, 15, Color("8e949b"))                 # a stone wall
	for p: Vector2i in [Vector2i(2, 3), Vector2i(12, 5), Vector2i(3, 12), Vector2i(13, 13)]:
		_rect(t, p.x, p.y, p.x + 1, p.y, Color("6c7178"))
	_rect(t, 5, 5, 10, 15, Color("7a4a24"))                 # a wooden door ...
	_rect(t, 6, 4, 9, 4, Color("7a4a24"))                   # ... with a round top
	_rect(t, 7, 6, 8, 15, Color("9c6b34"))
	_px(t, 9, 10, Color("ffd23f"))                          # knob
	_outline(t)


func _island(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(1, 7), Vector2(15, 7), Vector2(9, 15), Vector2(7, 15)]), Color("8a5a2e"))
	_rect(t, 1, 6, 14, 7, Color("5bc236"))
	_rect(t, 6, 10, 7, 11, Color("f2c230"))                 # gold in the rock
	_rect(t, 9, 3, 12, 5, Color("9c6b34"))                  # a chest on top
	_rect(t, 9, 4, 12, 4, Color("f2c230"))
	_outline(t)


func _golden(t: Vector2i) -> void:
	for y in TILE:
		for x in TILE:
			if pow((x + 0.5 - 7) / 6.0, 2) + pow((y + 0.5 - 10) / 3.6, 2) <= 1.0:
				_px(t, x, y, Color("f2c230"))
	_disc(t, 12.5, 6.5, 3.0, Color("f2c230"))               # head
	_rect(t, 12, 2, 12, 4, Color("f2c230"))                 # ears
	_rect(t, 14, 2, 14, 4, Color("f2c230"))
	_rect(t, 3, 13, 3, 15, Color("d9a520"))                 # legs
	_rect(t, 9, 13, 9, 15, Color("d9a520"))
	_px(t, 13, 6, Color("2a2230"))
	_rect(t, 4, 8, 7, 8, Color("ffe27a"))                   # shine
	_outline(t)
	_px(t, 1, 2, Color("fff7c2"))                           # sparkles
	_px(t, 2, 1, Color("fff7c2"))
	_px(t, 2, 3, Color("fff7c2"))
	_px(t, 3, 2, Color("fff7c2"))


func _temple(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(0.5, 5.5), Vector2(8, 0.5), Vector2(15.5, 5.5)]), Color("b8bec6"))
	_rect(t, 1, 5, 14, 6, Color("9aa0a6"))
	for x in [2, 6, 9, 13]:
		_rect(t, x, 7, x, 13, Color("d6dbe0"))              # columns
	_rect(t, 0, 14, 15, 15, Color("9aa0a6"))
	_rect(t, 7, 9, 8, 13, Color("f2c230"))                  # the golden vault
	_outline(t)


func _wanderer(t: Vector2i) -> void:
	_poly(t, PackedVector2Array([Vector2(8, 1), Vector2(13, 6), Vector2(14, 15.5), Vector2(2, 15.5), Vector2(3, 6)]), Color("5b3f8c"))
	_disc(t, 8, 6.5, 3.0, Color("1c1628"))                  # the dark hood
	_px(t, 7, 6, Color("9ff3ff"))                           # glowing eyes
	_px(t, 9, 6, Color("9ff3ff"))
	_rect(t, 14, 2, 14, 15, Color("8a5a2e"))                # staff ...
	_rect(t, 13, 1, 15, 1, Color("ffd23f"))                 # ... with a star
	_rect(t, 14, 0, 14, 2, Color("ffd23f"))
	_rect(t, 5, 10, 11, 10, Color("7a5bb0"))                # belt
	_outline(t)


func _geode(t: Vector2i) -> void:
	_disc(t, 8, 8, 7.0, Color("7d848c"))
	_disc(t, 8, 8, 4.8, Color("7d4ff0"))
	for p: Vector2i in [Vector2i(6, 6), Vector2i(9, 5), Vector2i(10, 9), Vector2i(6, 10), Vector2i(8, 8)]:
		_px(t, p.x, p.y, Color("e3d6ff"))
	_rect(t, 7, 7, 8, 7, Color("b89cff"))
	_outline(t)


func _note(t: Vector2i) -> void:
	_rect(t, 3, 1, 13, 14, Color("fbf6e4"))
	for y in [4, 7, 10]:
		_rect(t, 5, y, 11, y, Color("8a8a96"))
	_rect(t, 5, 12, 8, 12, Color("8a8a96"))
	_rect(t, 11, 1, 13, 3, Color("d8d1c2"))                 # a folded corner
	_outline(t)


func _question(t: Vector2i) -> void:
	_disc(t, 8, 8, 7.4, Color("4b3f6b"))
	var q := Color("fbfbf5")
	_rect(t, 5, 3, 10, 4, q)
	_rect(t, 10, 4, 11, 7, q)
	_rect(t, 7, 7, 10, 8, q)
	_rect(t, 7, 8, 8, 10, q)
	_rect(t, 7, 12, 8, 13, q)
	_outline(t)
