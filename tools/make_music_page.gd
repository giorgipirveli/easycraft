extends SceneTree
## Draws block atlas page 44 (owner #110, VR round 4 idea 7; data/blocks/music_page.gd TILES), our own work, no
## third-party art:
## - data/blocks/pages/music.png: 8 x 8 tiles of 16 px in the style of tools/make_atlas.gd. The xylophone's top: eight
##   bars in MusicBlockRules.BAR_COLORS across a dark wooden frame (bar i in columns 2i and 2i+1, its darker edge), C5's
##   the longest on the west (left) end, C6's the shortest on the east, two rails under them with a nail in each bar;
##   its side: the bars' coloured ends over a honey wooden frame on two legs; the bottom (both blocks'): planks. The
##   bongos' top: a big cream skin on the west half and a small one on the east, each in a dark hoop with brass tacks,
##   on red lacquer; their side: two red shells with brass bands, a wooden block between them.
## - its realistic twin, music_albedo.png and music_normal.png: each pixel tile painted at 240 px (smoothly enlarged,
##   with wood grain along the bars and the planks, a fine grain on the skins, soft edges) in an 8 px continuation border
##   (256 px a tile), one row kept, no alpha (both blocks are solid: tools/make_realistic_atlas.py's save_page rules); the
##   normal map from the painting's light (a height from its brightness and its edges).
## Run: godot --headless --path . --script res://tools/make_music_page.gd   (then godot --headless --path . --import;
## python3 tools/copy_page_import.py ganymede music; godot --headless --path . --import)

const TILE := 16
const GRID := 8
const REAL := 256
const BORDER := 8
const INNER := REAL - 2 * BORDER
const OUT := "res://data/blocks/pages/music.png"
const OUT_ALBEDO := "res://data/blocks/pages/music_albedo.png"
const OUT_NORMAL := "res://data/blocks/pages/music_normal.png"
const SEED := 20261044

const FRAME := Color("4a2c1a")
const FRAME_DARK := Color("2e1a10")
const RAIL := Color("6b4428")
const NAIL := Color("c9a45a")
const HONEY := Color("b9824a")
const HONEY_DARK := Color("8f5f33")
const HONEY_LIGHT := Color("d9a56a")
const PLANK := Color("a8763f")
const PLANK_DARK := Color("7d5530")
const SKIN := Color("efe0bf")
const SKIN_DARK := Color("d8c39a")
const HOOP := Color("3b2416")
const BRASS := Color("e2b84e")
const LACQUER := Color("b8322b")
const LACQUER_DARK := Color("8a221d")
const LACQUER_LIGHT := Color("d9534a")

var img: Image
var rng := RandomNumberGenerator.new()
## Where each tile is wood with grain along x (the bars and the planks) or a skin (fine grain): tile -> per-pixel kind.
var _kind := {}


func _init() -> void:
	rng.seed = SEED
	img = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_xylophone_top(Vector2i(0, 0))
	_xylophone_side(Vector2i(1, 0))
	_planks(Vector2i(2, 0))
	_drum_top(Vector2i(3, 0))
	_drum_side(Vector2i(4, 0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	print("MUSIC_PAGE pixel err=", img.save_png(OUT))
	var tiles: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
	var pair := _realistic(tiles)
	print("MUSIC_PAGE albedo err=", (pair[0] as Image).save_png(OUT_ALBEDO), " normal err=",
		(pair[1] as Image).save_png(OUT_NORMAL))
	quit()


func _px(t: Vector2i, x: int, y: int, c: Color, kind := &"wood") -> void:
	if x < 0 or y < 0 or x >= TILE or y >= TILE:
		return
	img.set_pixel(t.x * TILE + x, t.y * TILE + y, Color(c, 1.0))
	if not _kind.has(t):
		_kind[t] = {}
	(_kind[t] as Dictionary)[Vector2i(x, y)] = kind


func _vary(c: Color, amount: float) -> Color:
	var d := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)


func _rect(t: Vector2i, x0: int, y0: int, x1: int, y1: int, c: Color, vary := 0.0, kind := &"wood") -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(t, x, y, _vary(c, vary) if vary > 0.0 else c, kind)


## The xylophone from above: the dark frame (its rails at rows 3 and 12, the hollow between them darker), the eight
## bars over it, each a flat colour in its column 2i and a darker edge in 2i+1, a nail where it crosses a rail.
func _xylophone_top(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, FRAME, 0.03)
	_rect(t, 0, 5, 15, 10, FRAME_DARK, 0.02)
	_rect(t, 0, 3, 15, 3, RAIL, 0.03)
	_rect(t, 0, 12, 15, 12, RAIL, 0.03)
	for bar in MusicBlockRules.BARS:
		var length := roundi(lerpf(15.0, 9.0, bar / 7.0))
		var y0 := 8 - length / 2
		var y1 := y0 + length - 1
		var c: Color = MusicBlockRules.BAR_COLORS[bar]
		for y in range(y0, y1 + 1):
			_px(t, bar * 2, y, c, &"bar")
			_px(t, bar * 2 + 1, y, c.darkened(0.28), &"bar")
		_px(t, bar * 2, y0, c.lightened(0.3), &"bar")       # the bar's rounded end catching the light
		_px(t, bar * 2 + 1, 3, NAIL, &"metal")
		_px(t, bar * 2 + 1, 12, NAIL, &"metal")


## The xylophone from the side: the bars' coloured ends along the top, a rail, the honey frame and two legs.
func _xylophone_side(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, FRAME_DARK, 0.02)
	for bar in MusicBlockRules.BARS:
		var c: Color = MusicBlockRules.BAR_COLORS[bar]
		_px(t, bar * 2, 0, c.lightened(0.15), &"bar")
		_px(t, bar * 2, 1, c, &"bar")
		_px(t, bar * 2 + 1, 0, c.darkened(0.2), &"bar")
		_px(t, bar * 2 + 1, 1, c.darkened(0.35), &"bar")
	_rect(t, 0, 2, 15, 2, RAIL, 0.02)
	_rect(t, 0, 3, 15, 7, HONEY, 0.03)
	_rect(t, 0, 3, 15, 3, HONEY_LIGHT, 0.02)
	_rect(t, 0, 7, 15, 7, HONEY_DARK, 0.02)
	for leg: int in [1, 13]:
		_rect(t, leg, 8, leg + 1, 15, HONEY, 0.03)
		_px(t, leg, 8, HONEY_LIGHT)
		_rect(t, leg + 1, 9, leg + 1, 15, HONEY_DARK, 0.02)
	_rect(t, 3, 11, 12, 11, HONEY_DARK, 0.02)   # the legs' crossbar
	_px(t, 4, 5, NAIL, &"metal")
	_px(t, 11, 5, NAIL, &"metal")


## Plain planks (both blocks' bottoms).
func _planks(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, PLANK, 0.04)
	for y: int in [3, 7, 11, 15]:
		_rect(t, 0, y, 15, y, PLANK_DARK, 0.02)
	for p: Array in [[5, 0, 2], [11, 4, 6], [3, 8, 10], [9, 12, 14]]:
		_rect(t, p[0], p[1], p[0], p[2], PLANK_DARK, 0.02)


## The bongos from above: red lacquer, the big skin (west half: low) and the small one (east half: high), each in a
## dark hoop with brass tacks.
func _drum_top(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, LACQUER, 0.03, &"lacquer")
	_rect(t, 7, 0, 8, 15, HONEY_DARK, 0.02)   # the wooden block that joins them
	for drum: Array in [[Vector2(4.0, 8.0), 4.3], [Vector2(12.0, 8.0), 3.4]]:
		var c: Vector2 = drum[0]
		var r: float = drum[1]
		for y in 16:
			for x in 16:
				var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
				if d <= r - 0.9:
					var shade := SKIN.lerp(SKIN_DARK, clampf((d / r) * 0.8 + (y - c.y) * 0.03, 0.0, 1.0))
					_px(t, x, y, _vary(shade, 0.015), &"skin")
				elif d <= r + 0.3:
					_px(t, x, y, HOOP, &"wood")
		for a in 4:
			var at := c + Vector2.from_angle(a * PI * 0.5 + PI * 0.25) * r
			_px(t, floori(at.x), floori(at.y), BRASS, &"metal")


## The bongos from the side: two red shells (the big one on the left), brass bands round their tops and feet, the
## wooden block between them.
func _drum_side(t: Vector2i) -> void:
	_rect(t, 0, 0, 15, 15, FRAME_DARK, 0.02)
	for shell: Array in [[0, 7, 1], [9, 15, 4]]:   # [x0, x1, the top row]
		var x0: int = shell[0]
		var x1: int = shell[1]
		var top: int = shell[2]
		for y in range(top, 16):
			for x in range(x0, x1 + 1):
				var edge := minf(x - x0, x1 - x) / maxf((x1 - x0) * 0.5, 1.0)
				_px(t, x, y, _vary(LACQUER_DARK.lerp(LACQUER_LIGHT, clampf(edge * 1.2, 0.0, 1.0)), 0.02), &"lacquer")
		_rect(t, x0, top, x1, top, SKIN_DARK, 0.0, &"skin")
		_rect(t, x0, top + 1, x1, top + 1, BRASS, 0.02, &"metal")
		_rect(t, x0, 14, x1, 14, BRASS, 0.02, &"metal")
	_rect(t, 8, 6, 8, 11, HONEY_DARK, 0.02)   # the block between them


# --- The realistic twin ------------------------------------------------------------------------------------------

## [albedo, normal] of one row of REAL px tiles: each pixel tile enlarged smoothly to INNER px, grain by kind, and the
## border continuing the tile (wrapped) so mipmaps never bleed.
func _realistic(tiles: Array[Vector2i]) -> Array:
	var albedo := Image.create(GRID * REAL, REAL, false, Image.FORMAT_RGB8)
	var normal := Image.create(GRID * REAL, REAL, false, Image.FORMAT_RGB8)
	albedo.fill(Color(0.5, 0.5, 0.5))
	normal.fill(Color(0.5, 0.5, 1.0))
	var grain := FastNoiseLite.new()
	grain.seed = SEED
	grain.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	grain.frequency = 0.05
	var fine := FastNoiseLite.new()
	fine.seed = SEED + 1
	fine.frequency = 0.35
	for t: Vector2i in tiles:
		var small := img.get_region(Rect2i(t * TILE, Vector2i(TILE, TILE)))
		var big := small.duplicate() as Image
		big.resize(INNER, INNER, Image.INTERPOLATE_CUBIC)
		var crisp := small.duplicate() as Image
		crisp.resize(INNER, INNER, Image.INTERPOLATE_NEAREST)
		var kinds: Dictionary = _kind.get(t, {})
		var paint := Image.create(INNER, INNER, false, Image.FORMAT_RGB8)
		var height := PackedFloat32Array()
		height.resize(INNER * INNER)
		for y in INNER:
			for x in INNER:
				var cell := Vector2i(x * TILE / INNER, y * TILE / INNER)
				var kind: StringName = kinds.get(cell, &"wood")
				var c := crisp.get_pixel(x, y).lerp(big.get_pixel(x, y), 0.45)
				var gx := float(t.x * INNER + x)
				var gy := float(t.y * INNER + y)
				var g := 0.0
				match kind:
					&"wood", &"bar":   # grain along the bars and planks (long in x, wavy across)
						g = grain.get_noise_2d(gx * 0.25, gy * 3.0) * 0.07 + fine.get_noise_2d(gx, gy) * 0.02
					&"skin":
						g = fine.get_noise_2d(gx, gy) * 0.035
					&"lacquer":
						g = fine.get_noise_2d(gx * 0.5, gy * 0.5) * 0.02
					&"metal":
						g = 0.06 * (1.0 - float(y % 15) / 15.0)
				c = Color(clampf(c.r + g, 0, 1), clampf(c.g + g, 0, 1), clampf(c.b + g, 0, 1))
				paint.set_pixel(x, y, c)
				height[y * INNER + x] = c.get_luminance() + (g * 2.0 if kind != &"metal" else 0.15)
		var nmap := _normals(height)
		for y in REAL:
			for x in REAL:
				var sx := posmod(x - BORDER, INNER)
				var sy := posmod(y - BORDER, INNER)
				albedo.set_pixel(t.x * REAL + x, t.y * REAL + y, paint.get_pixel(sx, sy))
				normal.set_pixel(t.x * REAL + x, t.y * REAL + y, nmap.get_pixel(sx, sy))
	return [albedo, normal]


## An OpenGL-style normal map (+Y up) of a height field INNER x INNER (wrapped at the edges).
func _normals(h: PackedFloat32Array) -> Image:
	var out := Image.create(INNER, INNER, false, Image.FORMAT_RGB8)
	var strength := 3.0
	for y in INNER:
		for x in INNER:
			var l := h[y * INNER + posmod(x - 1, INNER)]
			var r := h[y * INNER + posmod(x + 1, INNER)]
			var u := h[posmod(y - 1, INNER) * INNER + x]
			var d := h[posmod(y + 1, INNER) * INNER + x]
			var n := Vector3((l - r) * strength, (d - u) * strength, 1.0).normalized()
			out.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	return out
