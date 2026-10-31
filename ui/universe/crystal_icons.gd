class_name CrystalIcons
extends RefCounted
## The universe crystals' pictures (owner feedback #39), drawn in code like the pet treats (no texture files, no atlas
## rows shared with other tasks): a cut gem in its universe's colours (CrystalRules.swirl_colors), a bright facet
## and a sparkle; 16 x 16, made once each.

const OUTLINE := Color("1d1430")

static var _icons := {}


## The icon of crystal `id` (null for anything that is not a crystal).
static func icon(id: int) -> Texture2D:
	if not CrystalRules.is_crystal(id):
		return null
	if not _icons.has(id):
		_icons[id] = ImageTexture.create_from_image(image(id))
	return _icons[id]


static func image(id: int) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var colors := CrystalRules.swirl_colors(CrystalRules.universe_of(id))
	var deep: Color = colors[0]
	var bright: Color = colors[1]
	var body: Color = deep.lerp(bright, 0.55)
	# A gem: a flat top (rows 3-5 widening), a point at the bottom (rows 6-14 narrowing).
	for y in range(3, 15):
		var half := 2 + (y - 3) if y <= 6 else 5 - (y - 6) * 5 / 8
		for x in range(8 - half - 1, 8 + half + 1):
			if x < 0 or x > 15:
				continue
			var edge := x == 8 - half - 1 or x == 8 + half or y == 3 or y == 14
			var c := OUTLINE if edge else body
			if not edge:
				if y <= 5:
					c = bright                                  # the table facet shines
				elif x < 8:
					c = body.lerp(bright, 0.35)                 # the left side catches the light
				else:
					c = body.lerp(deep, 0.35)
			img.set_pixel(x, y, c)
	for p: Vector2i in [Vector2i(6, 4), Vector2i(7, 7), Vector2i(6, 8)]:   # glints
		img.set_pixel(p.x, p.y, Color(1, 1, 1, 0.95))
	for p: Vector2i in [Vector2i(13, 1), Vector2i(12, 2), Vector2i(14, 2), Vector2i(13, 3)]:   # a sparkle
		img.set_pixel(p.x, p.y, bright.lightened(0.5))
	return img
