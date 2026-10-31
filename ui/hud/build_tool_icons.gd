class_name BuildToolIcons
extends RefCounted
## The building tools' 16 px icons (M3 Task 8), drawn in code from little pixel maps (no atlas file, like
## GadgetIcons): LINE (a staircase of blocks between two golden taps), FILL (a box of bricks between two golden
## corners), COPY (a build and its copy), REWIND (a turning-back arrow round a play button) and a paint bucket in
## each of the 16 tints (P is the tint, p its shade). BlockIcons.icon turns each into a texture once.

const COLORS := {
	"K": Color("2b2f3a"), "Y": Color("ffd23f"), "O": Color("d9a066"), "o": Color("a86f3a"), "B": Color("c8674a"),
	"b": Color("8e3f2c"), "C": Color("56c8ff"), "c": Color("1f5fa8"), "W": Color("ffffff"), "G": Color("c3cbd4"),
	"g": Color("7d8894"), "R": Color("e8403a"),
}

const LINE := [
	"................", "............KKKK", "............KYYK", "............KYYK",
	"..........KKKKK.", "..........KOoK..", "........KKKKK...", "........KOoK....",
	"......KKKKK.....", "......KOoK......", "....KKKKK.......", "....KOoK........",
	"KKKKKK..........", "KYYK............", "KYYK............", "KKKK............"]
const FILL := [
	"YY..............", "YYKKKKKKKKKKKK..", "..KBBBbBBBBbBK..", "..KbbbbbbbbbbK..",
	"..KBbBBBBbBBBK..", "..KbbbbbbbbbbK..", "..KBBBbBBBBbBK..", "..KbbbbbbbbbbK..",
	"..KBbBBBBbBBBK..", "..KbbbbbbbbbbK..", "..KBBBbBBBBbBK..", "..KbbbbbbbbbbK..",
	"..KBbBBBBbBBBK..", "..KKKKKKKKKKKKYY", "..............YY", "................"]
const COPY := [
	"................", ".KKKKKKKK.......", ".KOOOOOOK.......", ".KOooOOoK.......",
	".KOOOOOOK.......", ".KOoOOooKKKKKKK.", ".KOOOOOKCCCCCCK.", ".KOooOOKCccCCcK.",
	".KKKKKKKCCCCCCK.", ".......KCcCCccK.", ".......KCCCCCCK.", ".......KCccCCcK.",
	".......KCCCCCCK.", ".......KKKKKKKK.", "................", "................"]
const REWIND := [
	"................", ".....KKKKKK.....", "...KKYYYYYYKK...", "..KYYKKKKKKYYK..",
	".KYYK......KYYK.", "KKKK...KK...KYK.", "KYYYK..KWK..KYYK", ".KYK...KWWK..KYK",
	"..K....KWWWK.KYK", ".......KWWK..KYK", ".KK....KWK..KYYK", ".KYK...KK...KYK.",
	"..KYYK.....KYYK.", "...KKYYYYYYKK...", ".....KKKKKK.....", "................"]
const BUCKET := [
	"......KKKK......", ".....K....K.....", "....K......K....", "..KKKKKKKKKKKK..",
	"..KPPPPPPPPPPK..", "..KpPPPPPPPPpK..", "..KgGGGGGGGGgK..", "..KgGWGGGGGGgK..",
	"..KgGWGPGGGGgK..", "...KGWGPGGGGK...", "...KGGGPGGGGK...", "...KgGGPGGGgK...",
	"....KgGGGGgK....", "....KKKKKKKK....", ".......PP.......", ".......PP......."]


## Build-and-Wear's choices (WearCard): wake it up (a buddy's googly-eyed face), a hat, a backpack, wings.
const CHOICES := {
	&"wake": [
		"................", "..KKKKKKKKKKKK..", "..KBBBBBBBBBBK..", "..KBWWWBBWWWBK..",
		"..KBWKWBBWKWBK..", "..KBWWWBBWWWBK..", "..KBBBBBBBBBBK..", "..KBBKBBBBKBBK..",
		"..KBBBKKKKBBBK..", "..KBBBBBBBBBBK..", "..KKKKKKKKKKKK..", "....KK....KK....",
		"....KK....KK....", "................", "................", "................"],
	&"hat": [
		"................", "................", "....KKKKKKKK....", "....KRRRRRRK....",
		"....KRRRRRRK....", "....KRRRRRRK....", "....KRRRRRRK....", "....KYYYYYYK....",
		"....KRRRRRRK....", "..KKKKKKKKKKKK..", "..KRRRRRRRRRRK..", "..KKKKKKKKKKKK..",
		"................", "................", "................", "................"],
	&"back": [
		"................", ".....KKKKKK.....", "....K......K....", "...KKKKKKKKKK...",
		"...KOOOOOOOOK...", "...KOOOOOOOOK...", "...KKKKKKKKKK...", "...KOoOOOOoOK...",
		"...KOoOOOOoOK...", "...KOKKKKKKOK...", "...KOKOOOOKOK...", "...KOKKKKKKOK...",
		"...KOOOOOOOOK...", "...KKKKKKKKKK...", "................", "................"],
	&"wings": [
		"................", "KK............KK", "KCK..........KCK", "KCCK........KCCK",
		"KCCCK......KCCCK", ".KCCCK.KK.KCCCK.", ".KCCCCKGGKCCCCK.", "..KCCCKGGKCCCK..",
		"..KCCCKGGKCCCK..", "...KCCKGGKCCK...", "....KKKGGKKK....", "......KKKK......",
		"................", "................", "................", "................"],
}


## A choice's picture, 64 px (WearCard's buttons).
static func choice_picture(choice: StringName) -> ImageTexture:
	var img := _draw(CHOICES.get(choice, CHOICES[&"wake"]), {})
	img.resize(64, 64, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


static func has(id: int) -> bool:
	return PaintRules.is_paint(id) or ItemIds.BUILD_TOOLS.has(id)


static func image(id: int) -> Image:
	match id:
		ItemIds.LINE_TOOL:
			return _draw(LINE, {})
		ItemIds.FILL_TOOL:
			return _draw(FILL, {})
		ItemIds.COPY_TOOL:
			return _draw(COPY, {})
		ItemIds.REWIND:
			return _draw(REWIND, {})
	var tint := PaintRules.color(PaintRules.tint_of_item(id))
	return _draw(BUCKET, {"P": tint, "p": tint.darkened(0.3)})


static func _draw(rows: Array, extra: Dictionary) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if extra.has(ch):
				img.set_pixel(x, y, extra[ch])
			elif COLORS.has(ch):
				img.set_pixel(x, y, COLORS[ch])
	return img
