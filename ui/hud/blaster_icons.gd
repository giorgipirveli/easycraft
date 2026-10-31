class_name BlasterIcons
extends RefCounted
## Icons of the blasters and their ammo (M3 Task 14b), drawn in code (no atlas tiles to share with other
## tasks): a 16 px picture per item, then the tier icons' frame (BlockIcons): a rim in the rarity colour
## (§13.2), doubled to 32 px, and rarity + 1 white pips top-left (colour is never the only sign). Rows 0-2
## of a picture stay empty for the pips. Built once per item (BlockIcons caches the texture).

const PALETTE := {
	"y": Color("ffd23f"), "b": Color("2f86f0"), "d": Color("2b3140"), "o": Color("ff7a1a"),
	"w": Color("f4fbff"), "i": Color("8fd3ff"), "m": Color("ff2fa0"), "p": Color("ff9ad5"), "v": Color("7b2f8f"),
	"a": Color("3fd2c7"), "l": Color("dffbff"), "r": Color("e8403a"), "g": Color("66bb6a"), "c": Color("42a5f5"),
	"k": Color("8a5a2e"),
}

const PICTURES := {
	ItemIds.FOAM_BLASTER: [
		"................", "................", "................", "................",
		".bbbbbbbbbb.....", ".byyyyyyyyybbboo", ".byyyyyyyyybbboo", ".bbbbbbbbbbb....",
		"..dd.bbbb.......", "..dd..d.........", "..dd.dd.........", "..dd............",
		".ddd............", "................", "................", "................"],
	ItemIds.SNOWBALL_LAUNCHER: [
		"................", "................", "................", "....ww..........",
		"...wwww.........", "..wwwwww........", ".iiiiiiiiiiiiioo", ".iiiiiiiiiiiiioo",
		".iiiiiiiiiii....", "..dd..d.........", "..dd.dd.........", "..dd............",
		".ddd............", "................", "................", "................"],
	ItemIds.PAINT_SPLATTER: [
		"................", "................", "................", "..ppp...........",
		".ppmpp..........", ".pmmmp..........", ".pmmmpvvvvvvvmoo", ".ppppvvvvvvvvmoo",
		"..vvvvvvvvvv....", "..dd..d..m......", "..dd.dd..m......", "..dd............",
		".ddd.....m......", "................", "................", "................"],
	ItemIds.BUBBLE_CANNON: [
		"................", "................", "................", "...........ll...",
		"...ll.....l..l..", "..l..l.....ll...", ".aaaaaaaaaaalloo", ".aaaaaaaaaaalloo",
		".aaaaaaaaaaaa...", "..dd..d.........", "..dd.dd.........", "..dd............",
		".ddd............", "................", "................", "................"],
	ItemIds.CONFETTI_ROCKET: [
		"................", "................", "................", "................",
		".y.rrrrrrrrrrrr.", "yyyrrrrrrrrrrooo", "yyyrgcyrgcyrrooo", "yyyrrrrrrrrrrooo",
		".y.rrrrrrrrrrrr.", ".....dd.........", ".....dd.........", "....ddd.........",
		"................", "................", "................", "................"],
	ItemIds.FOAM_DARTS: [
		"................", "................", "................", "................",
		"..o.............", "..bbbbbbbby.....", "................", "....o...........",
		"....bbbbbbbby...", "................", "......o.........", "......bbbbbbbby.",
		"................", "................", "................", "................"],
	ItemIds.SNOWBALLS: [
		"................", "................", "................", "................",
		"...www..........", "..wwwww.........", "..wwiww...www...", "..wwwww..wwwww..",
		"...www...wwiww..", ".........wwwww..", "..........www...", "................",
		"................", "................", "................", "................"],
	ItemIds.PAINT_BLOBS: [
		"................", "................", "................", "................",
		"....m...........", "...mmm......m...", "..mmpmm....mmm..", "..mmmmm...mmpmm.",
		"...mmm....mmmmm.", "...........mmm..", ".....m..........", "....mmm.........",
		"....mmm.........", "................", "................", "................"],
	ItemIds.BUBBLE_SOAP: [
		"................", "................", "................", "..........ll....",
		"....aa....l..l..", "....aa.....ll...", "...aaaa.........", "..aallaa...l.l..",
		"..aallaa....l...", "..aaaaaa........", "..aaaaaa........", "..aaaaaa........",
		"................", "................", "................", "................"],
	ItemIds.PARTY_ROCKETS: [
		"................", "................", "................", "................",
		"...y.......y....", "..rrr.....rrr...", "..rgr.....rcr...", "..rcr.....rgr...",
		"..rrr.....rrr...", ".rrrrr...rrrrr..", "..ooo.....ooo...", "...o.......o....",
		"................", "................", "................", "................"],
}


## The 32 px icon of a blaster or an ammo item, or null.
static func image(id: int) -> Image:
	if not PICTURES.has(id):
		return null
	return framed(picture(id), BlasterRules.rarity(id))


## The 16 px picture.
static func picture(id: int) -> Image:
	var img := Image.create(BlockIcons.ITEM_TILE, BlockIcons.ITEM_TILE, false, Image.FORMAT_RGBA8)
	var rows: Array = PICTURES[id]
	for y in rows.size():
		var row: String = rows[y]
		for x in mini(row.length(), BlockIcons.ITEM_TILE):
			var ch := row[x]
			if PALETTE.has(ch):
				img.set_pixel(x, y, PALETTE[ch])
	return img


## A picture in its rarity's frame, like BlockIcons.tier_image: a rim, 32 px, rarity + 1 pips.
static func framed(pic: Image, rarity: int) -> Image:
	var colour := ItemRarity.color(rarity)
	var size := BlockIcons.ITEM_TILE
	var out := pic.duplicate() as Image
	for y in size:
		for x in size:
			if pic.get_pixel(x, y).a <= 0.5 and BlockIcons._near_opaque(pic, x, y):
				out.set_pixel(x, y, colour)
	out.resize(size * BlockIcons.TIER_SCALE, size * BlockIcons.TIER_SCALE, Image.INTERPOLATE_NEAREST)
	for i in rarity + 1:
		var o := Vector2i(1 + i * BlockIcons.PIP_PITCH, 1)
		out.fill_rect(Rect2i(o - Vector2i.ONE, Vector2i(BlockIcons.PIP_SIZE + 2, BlockIcons.PIP_SIZE + 2)), BlockIcons.PIP_EDGE)
	for i in rarity + 1:
		out.fill_rect(Rect2i(Vector2i(1 + i * BlockIcons.PIP_PITCH, 1), Vector2i(BlockIcons.PIP_SIZE, BlockIcons.PIP_SIZE)), BlockIcons.PIP_COLOR)
	return out
