class_name VrLensCloseups
extends RefCounted
## Owner #110 (VR round 4, VR-WONDER, idea 2; docs/devlog/parts/vr-r4-wonder.md): the magnifier's close-up pictures, our
## own work, drawn in code (procedural, a fixed seed each: the same picture every time; credited in assets/CREDITS.md).
## What a magnifying glass shows that the eye can't: sand's grains, a leaf's veins, a trunk's rings, snow's six-sided
## crystals, the crystals in stone, gold flecks in rock... LensRules.PICTURES lists them; each is SIZE pixels, made on its
## first look and kept.

const SIZE := 96

static var _cache := {}


## The close-up `picture` as a texture (made once).
static func texture(picture: StringName) -> Texture2D:
	if not _cache.has(picture):
		var img := image(picture)
		img.generate_mipmaps()
		_cache[picture] = ImageTexture.create_from_image(img)
	return _cache[picture]


## The close-up `picture` (SIZE x SIZE, RGBA8); an unknown one is plain grey.
static func image(picture: StringName) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(picture)) & 0x7fffffff
	match picture:
		&"grass":
			_grass(img, rng)
		&"soil":
			_soil(img, rng)
		&"sand":
			_grains(img, rng, Color("cdb27a"), [Color("e8d3a0"), Color("d9b77a"), Color("f4ece0"), Color("a99a86"),
				Color("c48d5a")], 4.0, 8.0)
		&"stone":
			_crystals(img, rng, [Color("8d8f93"), Color("a7a9ad"), Color("6e7074"), Color("c7b9ae"), Color("2f3236")], 44)
		&"rings":
			_rings(img, rng)
		&"grain":
			_fibres(img, rng)
		&"leaf":
			_leaf(img, rng)
		&"snow":
			_snow(img, rng)
		&"ice":
			_ice(img, rng)
		&"coal":
			_crystals(img, rng, [Color("6f7276"), Color("8a8c90"), Color("1b1c1f"), Color("111214"), Color("25272b")], 40)
			_flecks(img, rng, Color(0.9, 0.92, 1.0), 24, 1.0)
		&"iron_ore":
			_crystals(img, rng, [Color("8d8f93"), Color("a2a4a8"), Color("767073"), Color("9b9da1")], 40)
			_flecks(img, rng, Color("b4552a"), 60, 2.5)
			_flecks(img, rng, Color("d8874a"), 30, 1.5)
		&"gold_ore":
			_crystals(img, rng, [Color("8d8f93"), Color("a7a9ad"), Color("e6e2da"), Color("7a7c80")], 40)
			_flecks(img, rng, Color("e8b923"), 40, 2.5)
			_flecks(img, rng, Color("fff2a6"), 20, 1.0)
		&"diamond":
			_crystals(img, rng, [Color("3b3d42"), Color("4a4c52"), Color("2b2d31")], 30)
			_diamond(img)
		&"cactus":
			_cactus(img, rng)
		&"glass":
			_glass(img, rng)
		&"brick":
			_grains(img, rng, Color("b4532f"), [Color("c76a3e"), Color("9c4426"), Color("d98a5a"), Color("7d3519")], 2.0, 4.0)
			_flecks(img, rng, Color("4a1d0e"), 50, 1.2)
		&"petal":
			_petal(img, rng)
		_:
			img.fill(Color(0.5, 0.5, 0.5))
	return img

# --- The pictures ---

static func _grass(img: Image, rng: RandomNumberGenerator) -> void:
	img.fill(Color("2f6b2a"))
	for i in 34:   # blades from the bottom up, each with its middle vein and parallel veins
		var x := rng.randf_range(-4.0, SIZE + 4.0)
		var w := rng.randf_range(4.0, 8.0)
		var lean := rng.randf_range(-0.25, 0.25)
		var col := Color("4f9a3a").lerp(Color("7cc456"), rng.randf())
		for y in SIZE:
			var cx := x + lean * (SIZE - y)
			for dx in range(int(-w), int(w) + 1):
				var px := int(cx) + dx
				if px < 0 or px >= SIZE:
					continue
				var edge := absf(dx) / w
				var c := col.darkened(0.25 * edge)
				if absi(dx) <= 0 or absi(dx) == int(w * 0.5):
					c = c.lightened(0.25)   # the veins run along the blade
				img.set_pixel(px, y, c)


static func _soil(img: Image, rng: RandomNumberGenerator) -> void:
	img.fill(Color("5b3b22"))
	_flecks(img, rng, Color("3a2414"), 120, 3.0)
	_flecks(img, rng, Color("7a5434"), 120, 2.5)
	_flecks(img, rng, Color("cdbb98"), 30, 1.5)   # sand grains in it
	var p := Vector2(0.0, rng.randf_range(20.0, 40.0))
	for i in 140:   # a thin root wandering through
		p += Vector2(0.8, rng.randf_range(-0.9, 1.0))
		_dot(img, p, 1.6, Color("c9a77a"))


## Rounded grains packed together, each with a dark rim and a light side.
static func _grains(img: Image, rng: RandomNumberGenerator, gap: Color, colours: Array, rmin: float, rmax: float) -> void:
	img.fill(gap)
	var n := int(SIZE * SIZE / (rmax * rmax * 1.6))
	for i in n:
		var c := Vector2(rng.randf() * SIZE, rng.randf() * SIZE)
		var r := rng.randf_range(rmin, rmax)
		var col: Color = colours[rng.randi() % colours.size()]
		var squash := rng.randf_range(0.7, 1.0)
		for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
			for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
				if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
					continue
				var d := Vector2((x - c.x), (y - c.y) / squash).length() / r
				if d <= 1.0:
					var shade := col.darkened(0.35) if d > 0.82 else col.lightened(0.18 * (1.0 - d) * float(x < c.x))
					img.set_pixel(x, y, shade)


## Tightly packed crystals: a jittered grid of seeds (`count` of them, about), each pixel takes its nearest seed's
## colour (only the 3 x 3 cells round it are asked: cheap), with fine dark joins.
static func _crystals(img: Image, rng: RandomNumberGenerator, colours: Array, count: int) -> void:
	var g := maxi(int(ceil(sqrt(float(count)))), 2)
	var cell := float(SIZE) / g
	var seeds: Array[Vector2] = []
	var cols: Array[Color] = []
	for cy in g:
		for cx in g:
			seeds.append(Vector2((cx + rng.randf_range(0.1, 0.9)) * cell, (cy + rng.randf_range(0.1, 0.9)) * cell))
			cols.append(colours[rng.randi() % colours.size()])
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x, y)
			var best := INF
			var second := INF
			var k := 0
			var hx := int(x / cell)
			var hy := int(y / cell)
			for oy in range(maxi(hy - 1, 0), mini(hy + 2, g)):
				for ox in range(maxi(hx - 1, 0), mini(hx + 2, g)):
					var i := oy * g + ox
					var d := p.distance_squared_to(seeds[i])
					if d < best:
						second = best
						best = d
						k = i
					elif d < second:
						second = d
			var c := cols[k]
			if sqrt(second) - sqrt(best) < 1.0:
				c = c.darkened(0.45)
			img.set_pixel(x, y, c.lightened(0.06 * sin(x * 0.7 + y * 0.3)))


static func _rings(img: Image, rng: RandomNumberGenerator) -> void:
	var c := Vector2(SIZE * 0.42, SIZE * 0.55)
	for y in SIZE:
		for x in SIZE:
			var v := Vector2(x, y) - c
			var r := v.length() + 1.5 * sin(v.angle() * 5.0) + 1.0 * sin(v.angle() * 11.0 + 1.0)
			var band := fposmod(r, 7.0) / 7.0
			var col := Color("d2a56b") if band < 0.7 else Color("8a5a2f")
			if r > SIZE * 0.62:
				col = Color("5a3a20").darkened(0.2 * rng.randf())   # the bark
			img.set_pixel(x, y, col.lightened(0.05 * rng.randf()))


static func _fibres(img: Image, rng: RandomNumberGenerator) -> void:
	for y in SIZE:
		var base := Color("c08c55").lerp(Color("9a6a3a"), 0.5 + 0.5 * sin(y * 0.9 + sin(y * 0.13) * 3.0))
		for x in SIZE:
			img.set_pixel(x, y, base.darkened(0.08 * rng.randf()))
	for i in 18:   # long fibres along the grain
		var y := rng.randf() * SIZE
		var drift := rng.randf_range(-0.05, 0.05)
		for x in SIZE:
			_dot(img, Vector2(x, y + drift * x + sin(x * 0.08 + i) * 1.5), 0.6, Color("7a4c24"))


static func _leaf(img: Image, rng: RandomNumberGenerator) -> void:
	img.fill(Color("3f8f34"))
	_flecks(img, rng, Color("4ea43f"), 200, 2.0)
	var a := Vector2(0, SIZE)
	var b := Vector2(SIZE, 0)
	_line(img, a, b, 2.4, Color("c9e7a4"))   # the middle vein
	for i in range(1, 9):   # side veins, then their little branches (the vein net)
		var t := i / 9.0
		var on := a.lerp(b, t)
		for side: float in [-1.0, 1.0]:
			var end := on + Vector2(side * 26.0, side * 26.0).rotated(-0.6 * side) + Vector2(-8.0, -8.0)
			_line(img, on, end, 1.2, Color("a8d982"))
			for k in 3:
				var mid := on.lerp(end, (k + 1) / 4.0)
				_line(img, mid, mid + Vector2(rng.randf_range(-9, 9), rng.randf_range(-9, 9)), 0.6, Color("8cc56a"))


static func _snow(img: Image, rng: RandomNumberGenerator) -> void:
	for y in SIZE:
		for x in SIZE:
			img.set_pixel(x, y, Color("1f3f78").lerp(Color("4c79b8"), float(y) / SIZE))
	for f: Array in [[Vector2(30, 32), 22.0], [Vector2(70, 64), 18.0], [Vector2(22, 76), 12.0]]:
		var c: Vector2 = f[0]
		var r: float = f[1]
		for k in 6:   # six arms, each with its little branches
			var dir := Vector2.RIGHT.rotated(TAU * k / 6.0 + 0.3)
			_line(img, c, c + dir * r, 1.3, Color(0.95, 0.98, 1.0))
			for t: float in [0.45, 0.7]:
				var at := c + dir * r * t
				for s: float in [-1.0, 1.0]:
					_line(img, at, at + dir.rotated(s * 1.05) * r * 0.28, 0.9, Color(0.9, 0.95, 1.0))
	_flecks(img, rng, Color(1, 1, 1, 0.8), 25, 0.8)


static func _ice(img: Image, rng: RandomNumberGenerator) -> void:
	for y in SIZE:
		for x in SIZE:
			img.set_pixel(x, y, Color("bfe4f5").lerp(Color("8fc8e6"), 0.5 + 0.5 * sin(x * 0.05 + y * 0.08)))
	for i in 26:   # trapped air bubbles
		var c := Vector2(rng.randf() * SIZE, rng.randf() * SIZE)
		var r := rng.randf_range(1.5, 6.0)
		_ring(img, c, r, Color("eef8fd"))
		_dot(img, c + Vector2(-r * 0.35, -r * 0.35), maxf(r * 0.25, 0.7), Color.WHITE)


static func _cactus(img: Image, rng: RandomNumberGenerator) -> void:
	for y in SIZE:
		for x in SIZE:
			var rib := 0.5 + 0.5 * cos(x * TAU / 24.0)
			img.set_pixel(x, y, Color("2e7d32").lerp(Color("5fae4f"), rib))
	for col in 4:   # the areoles on the ribs, each with its spines (the cactus's leaves)
		for row in 5:
			var c := Vector2(col * 24.0 + 12.0 + rng.randf_range(-1, 1), row * 20.0 + 8.0 + (col % 2) * 10.0)
			_dot(img, c, 2.2, Color("e9e2c8"))
			for k in 5:
				var dir := Vector2.UP.rotated(rng.randf_range(-1.4, 1.4) + PI * float(k % 2))
				_line(img, c, c + dir * rng.randf_range(6, 11), 0.6, Color("fbf7ea"))


static func _glass(img: Image, rng: RandomNumberGenerator) -> void:
	for y in SIZE:
		for x in SIZE:
			var ripple := 0.5 + 0.5 * sin(y * 0.22 + sin(x * 0.07) * 2.0)
			img.set_pixel(x, y, Color("dff3fb").lerp(Color("c6e8f6"), ripple))
	for i in 8:
		var c := Vector2(rng.randf() * SIZE, rng.randf() * SIZE)
		_ring(img, c, rng.randf_range(1.0, 2.5), Color("f7fdff"))


static func _petal(img: Image, rng: RandomNumberGenerator) -> void:
	for y in SIZE:
		for x in SIZE:
			img.set_pixel(x, y, Color("f3a6c8").lerp(Color("e57aa8"), 0.5 + 0.5 * sin(x * 0.12 + y * 0.03)))
	for i in 22:   # pollen grains: little spiky yellow balls
		var c := Vector2(rng.randf() * SIZE, rng.randf() * SIZE)
		var r := rng.randf_range(3.0, 5.0)
		for k in 10:
			var dir := Vector2.RIGHT.rotated(TAU * k / 10.0)
			_line(img, c, c + dir * (r + 1.8), 0.6, Color("d9a300"))
		_dot(img, c, r, Color("ffd23f"))
		_dot(img, c + Vector2(-1.2, -1.2), r * 0.35, Color("fff2a6"))


## The diamond: a clear crystal in the rock, its facets catching the light.
static func _diamond(img: Image) -> void:
	var c := Vector2(SIZE * 0.5, SIZE * 0.5)
	var r := SIZE * 0.3
	for y in SIZE:
		for x in SIZE:
			var v := Vector2(x, y) - c
			if absf(v.x) + absf(v.y) <= r:
				var facet := int(v.x > 0.0) + 2 * int(v.y > 0.0)
				var col: Color = [Color("bff3ff"), Color("8fe0f5"), Color("e8fbff"), Color("6fcbe6")][facet]
				if absf(absf(v.x) + absf(v.y) - r) < 1.2 or absf(v.x) < 0.6 or absf(v.y) < 0.6:
					col = Color.WHITE
				img.set_pixel(x, y, col)

# --- Drawing helpers ---

static func _flecks(img: Image, rng: RandomNumberGenerator, col: Color, count: int, r: float) -> void:
	for i in count:
		_dot(img, Vector2(rng.randf() * SIZE, rng.randf() * SIZE), r * rng.randf_range(0.6, 1.2), col)


static func _dot(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in range(int(floor(c.y - r)), int(ceil(c.y + r)) + 1):
		for x in range(int(floor(c.x - r)), int(ceil(c.x + r)) + 1):
			if x >= 0 and y >= 0 and x < SIZE and y < SIZE and Vector2(x, y).distance_to(c) <= r:
				img.set_pixel(x, y, col if col.a >= 1.0 else img.get_pixel(x, y).lerp(Color(col, 1.0), col.a))


static func _ring(img: Image, c: Vector2, r: float, col: Color) -> void:
	for i in 24:
		var p := c + Vector2.RIGHT.rotated(TAU * i / 24.0) * r
		_dot(img, p, 0.7, col)


static func _line(img: Image, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var steps := maxi(int(a.distance_to(b)), 1)
	for i in steps + 1:
		_dot(img, a.lerp(b, float(i) / steps), w, col)
