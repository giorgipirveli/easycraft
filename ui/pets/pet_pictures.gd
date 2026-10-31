class_name PetPictures
extends RefCounted
## Pictures for pets (M3 Task 11), drawn in code like the gift box (no texture files, no atlas rows shared
## with other tasks): the five treats' 16 x 16 icons (shown 32 px like the tier icons), each made once.

const OUTLINE := Color("2a1d14")

static var _icons := {}


## The icon of treat `id` (ItemIds.TREATS), made once; null for anything else.
static func treat_icon(id: int) -> Texture2D:
	if not ItemIds.TREATS.has(id):
		return null
	if not _icons.has(id):
		_icons[id] = ImageTexture.create_from_image(treat_image(id))
	return _icons[id]


static func treat_image(id: int) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	match id:
		ItemIds.TREAT_BISCUIT:   # a bone-shaped dog biscuit
			var bone := Color("e8c48a")
			_rect(img, 4, 6, 12, 10, bone)
			for c: Vector2i in [Vector2i(3, 5), Vector2i(3, 10), Vector2i(12, 5), Vector2i(12, 10)]:
				_disc(img, c, 2, bone)
			_dots(img, [Vector2i(6, 8), Vector2i(9, 7)], bone.darkened(0.3))
		ItemIds.TREAT_FISH:   # a little fish snack
			var fish := Color("ff8a3d")
			_disc(img, Vector2i(7, 8), 4, fish)
			_rect(img, 11, 5, 14, 12, fish.darkened(0.15))
			_dots(img, [Vector2i(5, 7)], OUTLINE)
			_dots(img, [Vector2i(8, 9), Vector2i(9, 7)], Color("ffe08a"))
		ItemIds.TREAT_BERRIES:   # three berries and a leaf
			_disc(img, Vector2i(5, 10), 3, Color("c2185b"))
			_disc(img, Vector2i(10, 10), 3, Color("7b1fa2"))
			_disc(img, Vector2i(8, 6), 3, Color("d32f2f"))
			_rect(img, 8, 1, 12, 3, Color("3fae4b"))
			_dots(img, [Vector2i(7, 5), Vector2i(4, 9), Vector2i(9, 9)], Color(1, 1, 1, 0.8))
		ItemIds.TREAT_SEEDS:   # a round seed cracker
			_disc(img, Vector2i(8, 8), 6, Color("d9a441"))
			_dots(img, [Vector2i(5, 6), Vector2i(9, 5), Vector2i(11, 9), Vector2i(7, 10), Vector2i(8, 7), Vector2i(5, 10)],
				Color("7a5020"))
		ItemIds.TREAT_BOLT:   # a shiny bolt (Pip's favourite)
			var metal := Color("b9c3cf")
			_rect(img, 4, 2, 12, 6, metal.darkened(0.1))
			_rect(img, 6, 6, 10, 15, metal)
			for y in range(7, 15, 2):
				_rect(img, 6, y, 10, y + 1, metal.darkened(0.3))
			_dots(img, [Vector2i(13, 1), Vector2i(14, 2), Vector2i(12, 2), Vector2i(13, 3), Vector2i(5, 3)], Color.WHITE)
	_outline(img)
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return img


static func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			img.set_pixel(x, y, color)


static func _disc(img: Image, c: Vector2i, r: int, color: Color) -> void:
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			if x >= 0 and y >= 0 and x < 16 and y < 16 and Vector2(x - c.x, y - c.y).length() <= r + 0.3:
				img.set_pixel(x, y, color)


static func _dots(img: Image, dots: Array, color: Color) -> void:
	for d: Vector2i in dots:
		img.set_pixel(d.x, d.y, color)


## A dark edge round the drawing, so a treat reads on any slot colour.
static func _outline(img: Image) -> void:
	var edge: Array[Vector2i] = []
	for y in 16:
		for x in 16:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n := Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < 16 and n.y < 16 and img.get_pixel(n.x, n.y).a > 0.5 \
						and img.get_pixel(n.x, n.y) != OUTLINE:
					edge.append(Vector2i(x, y))
					break
	for p in edge:
		img.set_pixel(p.x, p.y, OUTLINE)
