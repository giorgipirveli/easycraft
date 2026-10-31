class_name BlockIcons
extends RefCounted
## 16x16 atlas icons for blocks (the side tile, which reads best at small sizes) and magic items.
## M2 Task 6: tier items (sword, bow, pickaxe, axe, spear, mace, shield; wood to cosmic) are made
## once each from their kind's picture in the item icon atlas: the metal takes the tier's rarity
## colour, a rim in that colour goes around, and 1-5 white pips in the top-left corner count the
## tier (colour is never the only sign). Potions come from the same atlas.

## Block atlas tiles of the M1b items. The sword, bow, axe and pickaxe (the wood tier) now show
## their tier icon; their row-5 pictures stay in the block atlas.
const ITEM_TILES := {
	ItemIds.WAND: Vector2i(0, 3), ItemIds.STAMP_HOUSE: Vector2i(1, 3), ItemIds.STAMP_TOWER: Vector2i(2, 3),
	ItemIds.STAMP_BRIDGE: Vector2i(3, 3), ItemIds.STAMP_TREE: Vector2i(4, 3), ItemIds.STAMP_RAINBOW: Vector2i(5, 3),
	ItemIds.SWORD: Vector2i(0, 5), ItemIds.BOW: Vector2i(1, 5), ItemIds.BOOMERANG: Vector2i(2, 5),
	ItemIds.HAMMER: Vector2i(3, 5), ItemIds.AXE: Vector2i(4, 5), ItemIds.PICKAXE: Vector2i(5, 5),
	ItemIds.DUMMY: Vector2i(6, 5), ItemIds.BULLSEYE: Vector2i(7, 5),
	ItemIds.TREASURE_MAP: Vector2i(4, 7),   # M2 Task 16 (block atlas row 7 until the item icon atlas, Task 6)
}

# --- Item icon atlas (M2 Task 6; tools/make_item_icons.gd) ---

## Imported as an Image (item_icons.png.import), so its pixels can be read on every renderer.
const ITEM_ATLAS: Image = preload("res://data/items/item_icons.png")
const ITEM_TILE := 16
## One picture per tiered kind (row 0) and the potions (row 1).
const KIND_TILES := {
	ItemIds.SWORD: Vector2i(0, 0), ItemIds.BOW: Vector2i(1, 0), ItemIds.PICKAXE: Vector2i(2, 0),
	ItemIds.AXE: Vector2i(3, 0), ItemIds.SPEAR: Vector2i(4, 0), ItemIds.MACE: Vector2i(5, 0),
	ItemIds.SHIELD_WOOD: Vector2i(6, 0),
}
const POTION_TILES := {
	ItemIds.POTION_JUMP: Vector2i(0, 1), ItemIds.POTION_INVIS: Vector2i(1, 1), ItemIds.POTION_SPEED: Vector2i(2, 1),
}
const TIER_SCALE := 2            # tier icons are 32 px: room for a fine rim and the pips
const PIP_SIZE := 4
const PIP_PITCH := 5
const PIP_COLOR := Color(1, 1, 1, 1)
const PIP_EDGE := Color("1d2430")
const METAL_MID := 0.5           # this grey takes exactly the rarity colour; lighter greys go paler (the rim stays the strongest)

static var _cache := {}


static func icon(id: int) -> Texture2D:
	if ItemIds.is_gift_stamp(id):
		return gift_icon()   # M4 I: one gift box for every friend's build
	if ItemIds.is_my_stamp(id):
		return my_stamp_icon()   # M3 Task 20b: one rubber stamp for every stamp of the child's own
	if PetRules.is_treat(id):
		return PetPictures.treat_icon(id)   # M3 Task 11: pet treats, drawn in code
	if id == ItemIds.FARM:
		return farm_icon()   # M3 Task 10: a red barn with a gold coin, drawn in code
	if CrystalRules.is_crystal(id):
		return CrystalIcons.icon(id)   # owner 39: universe crystals, drawn in code
	if ItemIds.is_lens(id):
		return LensIcons.icon(id)   # owner #110 (VR-WONDER): the telescope and the magnifier, drawn in code
	if _cache.has(id):
		return _cache[id]
	var tex: Texture2D = null
	var tier := WeaponRules.tier_of(id)
	if tier >= 0 and KIND_TILES.has(WeaponRules.base_of(id)):
		tex = ImageTexture.create_from_image(tier_image(WeaponRules.base_of(id), tier))
	elif POTION_TILES.has(id):
		tex = ImageTexture.create_from_image(item_picture(POTION_TILES[id]))
	elif CraftIcons.has(id):   # crafted things (spec §12.19), drawn in code
		tex = ImageTexture.create_from_image(CraftIcons.image(id))
	elif BlasterIcons.PICTURES.has(id):   # M3 Task 14b: blasters and ammo, drawn in code
		tex = ImageTexture.create_from_image(BlasterIcons.image(id))
	elif BuildToolIcons.has(id):   # M3 Task 8: the building tools and the paint buckets, drawn in code
		tex = ImageTexture.create_from_image(BuildToolIcons.image(id))
	elif GadgetIcons.PICTURES.has(id):   # M3 Task 14a: the gadgets, drawn in code
		tex = ImageTexture.create_from_image(GadgetIcons.image(id))
	else:
		var tile := Vector2i(-1, -1)
		if ITEM_TILES.has(id):
			tile = ITEM_TILES[id]
		else:
			var tiles: Array = BlockLibrary.tiles_of(id)   # its page's tiles (M3 Task 1)
			if tiles.is_empty():
				return null
			tile = tiles[1]
		var atlas := AtlasTexture.new()
		atlas.atlas = BlockLibrary.ATLAS if ITEM_TILES.has(id) else BlockLibrary.pixel_atlas_of(id)
		atlas.region = Rect2(tile.x * 16, tile.y * 16, 16, 16)
		atlas.filter_clip = true
		tex = atlas
	_cache[id] = tex
	return tex


## A copy of one 16 px tile of the item icon atlas.
static func item_picture(tile: Vector2i) -> Image:
	var img := ITEM_ATLAS.get_region(Rect2i(tile * ITEM_TILE, Vector2i(ITEM_TILE, ITEM_TILE)))
	img.convert(Image.FORMAT_RGBA8)
	return img


## The icon of `kind` (its wood-tier id) at `tier`: 32 px, metal in the rarity colour (the wood tier
## keeps it steel), a rim in the rarity colour, and tier + 1 pips.
static func tier_image(kind: int, tier: int) -> Image:
	var pic := item_picture(KIND_TILES[kind])
	var rarity := ItemRarity.of_tier(tier)
	var colour := ItemRarity.color(rarity)
	if rarity > ItemRarity.COMMON:
		for y in ITEM_TILE:
			for x in ITEM_TILE:
				var c := pic.get_pixel(x, y)
				if c.a > 0.5 and c.r8 == c.g8 and c.g8 == c.b8:
					pic.set_pixel(x, y, _tint(c.r, colour))
	var out := pic.duplicate() as Image
	for y in ITEM_TILE:                 # the rim: one atlas pixel around the picture
		for x in ITEM_TILE:
			if pic.get_pixel(x, y).a <= 0.5 and _near_opaque(pic, x, y):
				out.set_pixel(x, y, colour)
	out.resize(ITEM_TILE * TIER_SCALE, ITEM_TILE * TIER_SCALE, Image.INTERPOLATE_NEAREST)
	for i in tier + 1:
		var o := Vector2i(1 + i * PIP_PITCH, 1)
		out.fill_rect(Rect2i(o - Vector2i.ONE, Vector2i(PIP_SIZE + 2, PIP_SIZE + 2)), PIP_EDGE)
	for i in tier + 1:
		out.fill_rect(Rect2i(Vector2i(1 + i * PIP_PITCH, 1), Vector2i(PIP_SIZE, PIP_SIZE)), PIP_COLOR)
	return out


## The middle of pip i (0..4) in a tier icon.
static func pip_center(i: int) -> Vector2i:
	return Vector2i(1 + i * PIP_PITCH + PIP_SIZE / 2, 1 + PIP_SIZE / 2)


## A metal grey g (0..1) in `colour`: the mid grey is the colour itself, lighter greys go paler.
static func _tint(g: float, colour: Color) -> Color:
	var k := g / METAL_MID
	if k <= 1.0:
		return Color(colour.r * k, colour.g * k, colour.b * k, 1.0)
	return colour.lerp(Color.WHITE, clampf((k - 1.0) * 1.3, 0.0, 0.8))


static func _near_opaque(img: Image, x: int, y: int) -> bool:
	var size := img.get_width()
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var px := x + dx
			var py := y + dy
			if px >= 0 and py >= 0 and px < size and py < size and img.get_pixel(px, py).a > 0.5:
				return true
	return false


# --- M4 Wave 3, agent I: the gift box (every gift stamp's icon), drawn in code ---

const GIFT_ICON := -460   # the cache key of the gift box (never an id)


static func gift_icon() -> Texture2D:
	if not _cache.has(GIFT_ICON):
		_cache[GIFT_ICON] = ImageTexture.create_from_image(gift_image())
	return _cache[GIFT_ICON]


## A 16 x 16 present (red box, golden ribbon and bow), shown 32 px like the tier icons.
static func gift_image() -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var box := Color("e0413c")
	var dark := Color("9c2226")
	var gold := Color("ffd23f")
	for y in range(5, 15):
		for x in range(2, 14):
			img.set_pixel(x, y, dark if x == 2 or x == 13 or y == 14 else box)
	for x in range(1, 15):
		for y in range(5, 7):
			img.set_pixel(x, y, dark.lerp(box, 0.6))
	for y in range(5, 15):
		img.set_pixel(7, y, gold)
		img.set_pixel(8, y, gold)
	for p: Vector2i in [Vector2i(5, 2), Vector2i(6, 3), Vector2i(6, 4), Vector2i(4, 3), Vector2i(10, 2), Vector2i(9, 3),
			Vector2i(9, 4), Vector2i(11, 3), Vector2i(7, 4), Vector2i(8, 4)]:
		img.set_pixel(p.x, p.y, gold)
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return img

# --- M3 Task 10: the Gold Farm's icon (a red barn with a gold coin), drawn in code ---

const FARM_ICON := -491   # the cache key (never an id)


static func farm_icon() -> Texture2D:
	if not _cache.has(FARM_ICON):
		_cache[FARM_ICON] = ImageTexture.create_from_image(farm_image())
	return _cache[FARM_ICON]


## A 16 x 16 red barn (white trim, a dark door, a roof) with a gold coin on its gable, shown 32 px.
static func farm_image() -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var red := Color("c8312b")
	var dark := Color("8e1f1b")
	var trim := Color("f4efe4")
	var roof := Color("5a3a24")
	var gold := Color("ffd23f")
	for y in range(7, 15):
		for x in range(2, 14):
			img.set_pixel(x, y, dark if x == 2 or x == 13 or y == 14 else red)
	for i in 7:   # the roof: a gable from (1, 7) up to (7..8, 1) and down to (14, 7)
		for x in range(1 + i, 15 - i):
			img.set_pixel(x, 7 - i, roof if x == 1 + i or x == 14 - i else red)
	for x in range(2, 14):
		img.set_pixel(x, 8, trim)
	for y in range(10, 15):   # the door with its white cross
		for x in range(6, 10):
			img.set_pixel(x, y, trim if x - 6 == y - 10 or 9 - x == y - 10 or x == 6 or x == 9 or y == 10 else dark)
	for p: Vector2i in [Vector2i(7, 3), Vector2i(8, 3), Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4),
			Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5), Vector2i(7, 6), Vector2i(8, 6)]:
		img.set_pixel(p.x, p.y, gold)
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return img

# --- M3 Task 20b: My Stamps' icon (a rubber stamp with a star), drawn in code ---

const MY_STAMP_ICON := -495   # the cache key (never an id)


static func my_stamp_icon() -> Texture2D:
	if not _cache.has(MY_STAMP_ICON):
		_cache[MY_STAMP_ICON] = ImageTexture.create_from_image(my_stamp_image())
	return _cache[MY_STAMP_ICON]


## A 16 x 16 rubber stamp: a wooden handle, a purple pad and a golden star printed under it; shown 32 px.
static func my_stamp_image() -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var wood := Color("b07a45")
	var dark := Color("7a4f28")
	var pad := Color("7b4bd6")
	var gold := Color("ffd23f")
	for y in range(1, 5):
		for x in range(6, 10):
			img.set_pixel(x, y, dark if x == 6 or y == 1 else wood)   # the knob
	for y in range(5, 8):
		img.set_pixel(7, y, wood)
		img.set_pixel(8, y, wood)
	for y in range(8, 11):
		for x in range(3, 13):
			img.set_pixel(x, y, dark if y == 8 else pad)   # the pad
	for p: Vector2i in [Vector2i(7, 11), Vector2i(8, 11), Vector2i(5, 12), Vector2i(6, 12), Vector2i(7, 12),
			Vector2i(8, 12), Vector2i(9, 12), Vector2i(10, 12), Vector2i(6, 13), Vector2i(7, 13), Vector2i(8, 13),
			Vector2i(9, 13), Vector2i(6, 14), Vector2i(9, 14)]:
		img.set_pixel(p.x, p.y, gold)   # the star it prints
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return img
