extends SceneTree
## Draws the Seven Natural Wonders' pixel tiles (owner #78, spec §24, the third tour) into rows 1-3 of
## data/blocks/pages/wonders4.png (page 37; world/universes/wonders_blocks.gd TILES_NATURE), keeping its row 0 (the New
## Seven's: tools/make_wonders_new_page.gd draws it; run this one after that one). 16 x 16 tiles in the style of the other
## wonders' pages (original work, its own RNG seed; our own look, spec §3c: nothing copied from any photo, painting or
## other game). What nature made them of, drawn plainly: the Grand Canyon's rock layers (the pale Kaibab limestone with
## its bedding, the Coconino sandstone's slanting lines of old dunes, the Supai's thin red beds, the Redwall's grey
## limestone streaked red from above, the green-grey shale, the dark Vishnu schist with pink granite veins), a trilobite
## fossil in grey limestone, the reef's brain coral, staghorn coral and sea fan, Parícutin's red-black cinders and a corn
## plant, a string of prayer flags in five colours, and the falls' spray (drops, see-through).
## Its realistic twin is tools/make_wonders_nature_realistic.py (the same layout).
## Run: godot --headless --path . --script res://tools/make_wonders_nature_page.gd   (then godot --headless --path . --import)

const TILE := 16
const PAGE := "res://data/blocks/pages/wonders4.png"
const SEED := 20261001

const KAIBAB := Color("c9c0a6")
const KAIBAB_LIGHT := Color("dcd4bd")
const KAIBAB_DARK := Color("a99f88")
const COCONINO := Color("e4d0a2")
const COCONINO_LINE := Color("c7ad80")
const COCONINO_LIGHT := Color("f0e2c0")
const SUPAI := Color("b5533a")
const SUPAI_DARK := Color("8e3e2c")
const SUPAI_LIGHT := Color("c9704f")
const SUPAI_PALE := Color("d89a76")
const REDWALL := Color("9a948e")
const REDWALL_STAIN := Color("b0654a")
const SHALE := Color("8d9a85")
const SHALE_DARK := Color("6f7a67")
const SHALE_LIGHT := Color("a6b09b")
const SCHIST := Color("3b3b44")
const SCHIST_SHEEN := Color("5d5d6a")
const VEIN := Color("e0a190")
const LIME := Color("9b9890")
const LIME_LIGHT := Color("b6b2a8")
const FOSSIL := Color("6e6a62")
const FOSSIL_LIGHT := Color("c4bfb3")
const BRAIN := Color("b9b142")
const BRAIN_GROOVE := Color("777722")
const BRAIN_LIGHT := Color("d9d273")
const STAG_BASE := Color("8a3a6a")
const STAG := Color("ef8fb0")
const STAG_TIP := Color("ffd2e2")
const FAN_BASE := Color("4a2a6a")
const FAN := Color("b070e0")
const FAN_LIGHT := Color("d2a2f2")
const CINDER := Color("3a2622")
const CINDER_RED := Color("5c3028")
const CINDER_HOLE := Color("1a1210")
const CINDER_BIT := Color("7a3a28")
const STALK := Color("5aa040")
const LEAF := Color("4a8a30")
const LEAF_LIGHT := Color("7ac050")
const COB := Color("e8c840")
const HUSK := Color("8ac060")
const TASSEL := Color("d8c070")
const STRING := Color("4a3a2a")
const FLAG_COLOURS: Array[Color] = [Color("2f6fd0"), Color("f4f4f0"), Color("d03a30"), Color("3aa040"), Color("f0d030")]
const DROP := Color("f4fbff")
const DROP_BLUE := Color("d6ebff")
const CLEAR := Color(0, 0, 0, 0)

var img: Image
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = SEED
	img = Image.load_from_file(ProjectSettings.globalize_path(PAGE))
	img.convert(Image.FORMAT_RGBA8)
	for y in range(TILE, img.get_height()):   # rows 1-7: nature's (row 0 is the New Seven's)
		for x in img.get_width():
			img.set_pixel(x, y, CLEAR)
	_kaibab()
	_coconino()
	_supai()
	_redwall()
	_shale()
	_schist()
	_fossil()
	_brain_coral()
	_staghorn()
	_sea_fan()
	_cinder()
	_corn()
	_prayer_flags()
	_spray()
	var err := img.save_png(ProjectSettings.globalize_path(PAGE))
	print("WONDERS_NATURE_PAGE saved err=%d" % err)
	quit()


func _px(t: Vector2i, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TILE and y < TILE:
		img.set_pixel(t.x * TILE + x, t.y * TILE + y, c)


func _vary(c: Color, amount: float) -> Color:
	if amount <= 0.0:
		return c
	var k := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + k, 0, 1), clampf(c.g + k, 0, 1), clampf(c.b + k, 0, 1), c.a)


func _fill(t: Vector2i, c: Color, vary: float) -> void:
	for y in TILE:
		for x in TILE:
			_px(t, x, y, _vary(c, vary))


## The Kaibab limestone: the side (0,1) pale beds with thin dark bedding lines and specks of shell; the top (1,1).
func _kaibab() -> void:
	var side := Vector2i(0, 1)
	for y in TILE:
		for x in TILE:
			var c := KAIBAB
			if y % 5 == 4:
				c = KAIBAB_DARK
			elif y % 5 == 0:
				c = KAIBAB_LIGHT
			_px(side, x, y, _vary(c, 0.025))
	for i in 7:
		_px(side, rng.randi_range(0, 15), rng.randi_range(0, 15), KAIBAB_DARK.darkened(0.15))
	var top := Vector2i(1, 1)
	_fill(top, KAIBAB_LIGHT.lerp(KAIBAB, 0.5), 0.03)
	for i in 10:
		_px(top, rng.randi_range(0, 15), rng.randi_range(0, 15), KAIBAB_DARK)


## The Coconino sandstone: the side (2,1) cream with sets of slanting lines (the old dunes' layers); the top (3,1).
func _coconino() -> void:
	var side := Vector2i(2, 1)
	for y in TILE:
		for x in TILE:
			var c := COCONINO
			var set_y := y / 8
			var slant := (x + y * 2 + set_y * 5) % 6
			if y % 8 == 7:
				c = COCONINO_LINE.darkened(0.08)   # a set's base
			elif slant == 0:
				c = COCONINO_LINE
			elif slant == 3:
				c = COCONINO_LIGHT
			_px(side, x, y, _vary(c, 0.02))
	var top := Vector2i(3, 1)
	_fill(top, COCONINO, 0.035)


## The Supai beds: the side (4,1) thin layers of red sandstone and darker mudstone, a pale streak; the top (5,1).
func _supai() -> void:
	var side := Vector2i(4, 1)
	var rows: Array[Color] = [SUPAI, SUPAI, SUPAI_DARK, SUPAI_LIGHT, SUPAI, SUPAI_DARK, SUPAI, SUPAI_PALE]
	for y in TILE:
		for x in TILE:
			var c := rows[(y / 2) % rows.size()]
			_px(side, x, y, _vary(c, 0.025))
	var top := Vector2i(5, 1)
	_fill(top, SUPAI_LIGHT.lerp(SUPAI, 0.5), 0.03)


## The Redwall limestone: the side (6,1) grey stone streaked red from the beds above (more at the top); the top (7,1).
func _redwall() -> void:
	var side := Vector2i(6, 1)
	var streaks: Array[int] = []
	for i in 6:
		streaks.append(rng.randi_range(0, 15))
	for y in TILE:
		for x in TILE:
			var stain := 0.55 - y * 0.02
			if streaks.has(x):
				stain += 0.35
			var c := REDWALL.lerp(REDWALL_STAIN, clampf(stain, 0.0, 0.9))
			if y % 8 == 7:
				c = c.darkened(0.12)
			_px(side, x, y, _vary(c, 0.02))
	var top := Vector2i(7, 1)
	_fill(top, REDWALL.lerp(REDWALL_STAIN, 0.45), 0.03)


## The Bright Angel Shale: the side (0,2) thin green-grey flaky layers; the top (1,2).
func _shale() -> void:
	var side := Vector2i(0, 2)
	for y in TILE:
		for x in TILE:
			var c := SHALE if y % 3 != 2 else SHALE_DARK
			if y % 3 == 0 and (x + y) % 5 == 0:
				c = SHALE_LIGHT
			_px(side, x, y, _vary(c, 0.02))
	var top := Vector2i(1, 2)
	_fill(top, SHALE, 0.03)


## The Vishnu schist: the side (2,2) dark, wavy and shiny, cut by pink granite veins; the top (3,2).
func _schist() -> void:
	for t: Vector2i in [Vector2i(2, 2), Vector2i(3, 2)]:
		for y in TILE:
			for x in TILE:
				var w := y + sin(x * 0.7) * 1.5
				var c := SCHIST_SHEEN if int(floor(w)) % 4 == 0 else SCHIST
				_px(t, x, y, _vary(c, 0.02))
		var vx := rng.randi_range(3, 10)
		for y in TILE:   # a granite vein across it
			vx += rng.randi_range(-1, 1)
			_px(t, clampi(vx, 0, 15), y, VEIN)
			_px(t, clampi(vx + 1, 0, 15), y, VEIN.darkened(0.1))


## A sea fossil: the side (4,2) grey limestone with a trilobite (its head, its three-lobed body in segments, its tail);
## the top (6,3) plain grey limestone.
func _fossil() -> void:
	var side := Vector2i(4, 2)
	_fill(side, LIME, 0.025)
	for y in range(3, 14):
		for x in range(4, 12):
			var u := (x - 7.5) / 4.0
			var v := (y - 8.0) / 5.5
			if u * u + v * v > 1.0:
				continue
			var c := FOSSIL
			if absf(x - 7.5) < 1.2:
				c = FOSSIL.darkened(0.15)   # the middle lobe
			if y % 2 == 0 and y > 5:
				c = c.lightened(0.15)   # its segments
			if y <= 5:
				c = FOSSIL.lightened(0.05)   # its head
			_px(side, x, y, c)
	for y in range(3, 14):   # its outline
		for x in range(3, 13):
			var u := (x - 7.5) / 4.0
			var v := (y - 8.0) / 5.5
			var d := u * u + v * v
			if d > 1.0 and d < 1.5:
				_px(side, x, y, FOSSIL_LIGHT)
	_fill(Vector2i(6, 3), LIME_LIGHT.lerp(LIME, 0.5), 0.025)


## Brain coral: the side (5,2) and the top (6,2): gold-green with winding grooves.
func _brain_coral() -> void:
	for t: Vector2i in [Vector2i(5, 2), Vector2i(6, 2)]:
		for y in TILE:
			for x in TILE:
				var w := sin(x * 0.9 + sin(y * 0.6) * 2.0) + cos(y * 0.8 + sin(x * 0.5) * 1.5)
				var c := BRAIN
				if absf(w) < 0.35:
					c = BRAIN_GROOVE
				elif w > 1.2:
					c = BRAIN_LIGHT
				_px(t, x, y, _vary(c, 0.02))


## Staghorn coral (7,2): pink branches like antlers, pale tips, over darker coral.
func _staghorn() -> void:
	var t := Vector2i(7, 2)
	_fill(t, STAG_BASE, 0.03)
	for b in 4:
		var x := 2.0 + b * 3.8
		var y := 15.0
		var dir := rng.randf_range(-0.4, 0.4)
		while y > 1.0:
			_px(t, roundi(x), roundi(y), STAG)
			_px(t, roundi(x) + 1, roundi(y), STAG.darkened(0.1))
			if rng.randf() < 0.25:   # a branch off it
				var bx := x
				var by := y
				var side := 1.0 if rng.randf() < 0.5 else -1.0
				for k in 4:
					bx += side
					by -= 1.0
					_px(t, roundi(bx), roundi(by), STAG)
				_px(t, roundi(bx), roundi(by), STAG_TIP)
			x += dir
			y -= 1.0
		_px(t, roundi(x), 1, STAG_TIP)


## A sea fan (0,3): a lacy purple net of branches.
func _sea_fan() -> void:
	var t := Vector2i(0, 3)
	_fill(t, FAN_BASE, 0.03)
	for y in TILE:
		for x in TILE:
			var a := (x + y) % 4 == 0
			var b := (x - y + 16) % 4 == 0
			if a or b:
				_px(t, x, y, FAN if (x + y) % 3 else FAN_LIGHT)
	for y in range(12, 16):   # its stem
		_px(t, 7, y, FAN.darkened(0.3))
		_px(t, 8, y, FAN.darkened(0.3))


## Parícutin's cinders: the side (1,3) red-black bits of lava full of holes; the top (2,3).
func _cinder() -> void:
	for t: Vector2i in [Vector2i(1, 3), Vector2i(2, 3)]:
		for y in TILE:
			for x in TILE:
				var r := rng.randf()
				var c := CINDER
				if r < 0.12:
					c = CINDER_HOLE
				elif r < 0.3:
					c = CINDER_RED
				elif r < 0.36:
					c = CINDER_BIT
				_px(t, x, y, c)


## A corn plant (3,3), drawn on clear: its stalk, long leaves, a yellow cob in its green husk, a tassel at the top.
func _corn() -> void:
	var t := Vector2i(3, 3)
	for y in range(2, 16):
		_px(t, 7, y, STALK)
		_px(t, 8, y, STALK.darkened(0.1))
	for leaf: Array in [[13, -1], [10, 1], [7, -1], [4, 1]]:
		var y: int = leaf[0]
		var d: int = leaf[1]
		for k in 6:
			_px(t, 7 + d * (k + 1), y - k / 2, LEAF if k % 2 else LEAF_LIGHT)
	for y in range(6, 11):   # the cob
		_px(t, 10, y, COB)
		_px(t, 11, y, COB.darkened(0.1))
		_px(t, 12, y, HUSK)
	_px(t, 10, 5, HUSK)
	for x in range(5, 11):   # the tassel
		_px(t, x, 1 if x % 2 else 0, TASSEL)


## A string of prayer flags (4,3): a cord near the top and five small flags hanging from it, blue, white, red, green
## and yellow; clear elsewhere (its top and bottom, (7,3), are clear).
func _prayer_flags() -> void:
	var t := Vector2i(4, 3)
	for x in TILE:
		_px(t, x, 3 + (1 if x in [5, 6, 7, 8, 9, 10] else 0), STRING)
	for i in 5:
		var x0 := 1 + i * 3
		var c: Color = FLAG_COLOURS[i]
		for y in range(5, 11):
			for x in range(x0, x0 + 2):
				_px(t, x, y, _vary(c, 0.02))


## The falls' spray (5,3): drops scattered on clear, white and pale blue.
func _spray() -> void:
	var t := Vector2i(5, 3)
	for y in TILE:
		for x in TILE:
			if rng.randf() < 0.28:
				_px(t, x, y, DROP if rng.randf() < 0.6 else DROP_BLUE)
