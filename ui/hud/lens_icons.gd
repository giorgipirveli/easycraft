class_name LensIcons
extends RefCounted
## Owner #110 (VR round 4, VR-WONDER, idea 2; docs/devlog/parts/vr-r4-wonder.md): the telescope's and the magnifier's
## icons, drawn in code (16 x 16 pixels shown at 32, like the other items drawn in code): our own pictures.

static var _cache := {}


static func icon(id: int) -> Texture2D:
	if not _cache.has(id):
		_cache[id] = ImageTexture.create_from_image(image(id))
	return _cache[id]


static func image(id: int) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	if id == ItemIds.TELESCOPE:
		_telescope(img)
	else:
		_magnifier(img)
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return img


## A brass telescope lying from the bottom left up to the top right: three tubes, wider to the front, a blue glint.
static func _telescope(img: Image) -> void:
	var brass := Color("d9a441")
	var dark := Color("8a5f1c")
	var light := Color("f6d98a")
	var glass := Color("7fd3ff")
	for i in 14:
		var x := 1 + i
		var y := 14 - i
		var half := 1 if i < 5 else (2 if i < 10 else 3)   # the eyepiece, the middle tube, the big front tube
		for k in range(-half, half + 1):
			var px := x + k
			var py := y + k
			if px < 0 or px > 15 or py < 0 or py > 15:
				continue
			img.set_pixel(px, py, dark if absi(k) == half else (light if k == -half + 1 else brass))
	for p: Vector2i in [Vector2i(14, 1), Vector2i(15, 2), Vector2i(13, 0), Vector2i(15, 0), Vector2i(14, 0),
			Vector2i(15, 1)]:
		img.set_pixel(p.x, p.y, glass)
	for p: Vector2i in [Vector2i(5, 10), Vector2i(10, 5)]:   # the rings where the tubes meet
		img.set_pixel(p.x, p.y, dark)


## A round magnifying glass at the top left (a silver rim, pale blue glass with a shine) on a wooden handle.
static func _magnifier(img: Image) -> void:
	var rim := Color("c9cfd8")
	var rim_dark := Color("7d8694")
	var glass := Color(0.62, 0.86, 1.0, 0.85)
	var shine := Color(1, 1, 1, 0.95)
	var wood := Color("a8702f")
	var wood_dark := Color("6e461c")
	var c := Vector2(6.0, 6.0)
	for y in 16:
		for x in 16:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c + Vector2(0.5, 0.5))
			if d <= 4.2:
				img.set_pixel(x, y, glass)
			elif d <= 5.6:
				img.set_pixel(x, y, rim if x + y < 12 else rim_dark)
	for p: Vector2i in [Vector2i(4, 4), Vector2i(5, 4), Vector2i(4, 5)]:
		img.set_pixel(p.x, p.y, shine)
	for i in 6:   # the handle, down to the bottom right
		var x := 10 + i
		var y := 10 + i
		if x <= 15 and y <= 15:
			img.set_pixel(x, y, wood)
			if x - 1 >= 0:
				img.set_pixel(x - 1, y, wood_dark)
			if y - 1 >= 0 and x <= 15:
				img.set_pixel(x, y - 1, wood)
