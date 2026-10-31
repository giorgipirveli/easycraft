class_name GadgetIcons
extends RefCounted
## The gadgets' 16 px icons (M3 Task 14a), drawn in code from little pixel maps (no atlas file, so no
## shared picture to merge): a striped glider, a three-pronged hook on its rope, the quick builds in planks
## (wall, floor, ramp, fort), the blue Boing Orb with its spring and the pink Dance Orb with a note.
## BlockIcons.icon turns each into a texture once. The zipline post and the launch pad are blocks: their
## icons come from their page's tiles (PortalPage).

const COLORS := {
	"K": Color("2b2f3a"), "R": Color("e8403a"), "Y": Color("ffd23f"), "w": Color("8a5a2e"),
	"G": Color("c3cbd4"), "g": Color("5f6b78"), "B": Color("b0875a"), "C": Color("56c8ff"), "c": Color("1f5fa8"),
	"W": Color("ffffff"), "P": Color("ff7ad9"), "p": Color("8a2f8f"), "O": Color("d9a066"), "o": Color("a86f3a"),
	"D": Color("4a3020"),
}

const PICTURES := {
	ItemIds.GLIDER: [
		"................", "................", "......KKKK......", "....KKRRYYKK....",
		"..KKRRYYRRYYKK..", ".KRRYYRRYYRRYYK.", "KRRYYRRYYRRYYRRK", "KKKKKKKKKKKKKKKK",
		"..K..........K..", "...K........K...", "....K......K....", ".....K....K.....",
		"......KwwK......", "......wwww......", "................", "................"],
	ItemIds.GRAPPLE: [
		"................", "..G....G....G...", "..Gg...G...gG...", "...Gg..G..gG....",
		"....GggGggG.....", ".......G........", ".......G........", ".......G........",
		".......G........", ".......gg.......", "........B.......", ".......B........",
		"......B.........", ".....BBB........", "....B...B.......", ".....BBB........"],
	ItemIds.BUILD_WALL: [
		"................", "..............Y.", "...KKKKKKKKKK.Y.", "...KOOOOOOOOK...",
		"...KooooooooK...", "...KOOOOOOOOK...", "...KOOOoOOOOK...", "...KooooooooK...",
		"...KOOOOOOOOK...", "...KOoOOOOOOK...", "...KooooooooK...", "...KOOOOOoOOK...",
		"...KOOOOOOOOK...", "...KKKKKKKKKK...", "................", "................"],
	ItemIds.BUILD_FLOOR: [
		"................", "..............Y.", "..............Y.", "................",
		".......KK.......", ".....KKOOKK.....", "...KKOOooOOKK...", ".KKOOooOOooOOKK.",
		"KOOooOOooOOooOOK", ".KKOOooOOooOOKK.", "...KKOOooOOKK...", ".....KKOOKK.....",
		".......KK.......", "................", "................", "................"],
	ItemIds.BUILD_RAMP: [
		"................", ".Y..............", ".Y..........KKK.", "...........KOOK.",
		"...........KooK.", "........KKKKOOK.", "........KOOOOOK.", "........KoooooK.",
		".....KKKKOOOOOK.", ".....KOOOOOOOOK.", ".....KooooooooK.", "..KKKKOOOOOOOOK.",
		"..KOOOOOOOOOOOK.", "..KoooooooooooK.", "..KKKKKKKKKKKKK.", "................"],
	ItemIds.BUILD_FORT: [
		"................", "..O.O.O..O.O.O..", "..OOOOO..OOOOO..", "..OoOOO..OOOoO..",
		"..OOOOOOOOOOOO..", "..OOOoOOOOoOOO..", "..OOOOOOOOOOOO..", "..OoOOODDOOOoO..",
		"..OOOODDDDOOOO..", "..OOOODDDDOOOO..", "..OOOODDDDOOOO..", "..OOOODDDDOOOO..",
		"..oooooooooooo..", "................", "..............Y.", "..............Y."],
	ItemIds.IMPULSE_ORB: [
		"................", ".....cccccc.....", "...ccCCCCCCcc...", "..cCCWWCCCCCCc..",
		"..cCWWCCCCCCCc..", ".cCCCCCCCCCCCCc.", ".cCCCWWWWWWCCCc.", ".cCCWCCCCCCWCCc.",
		".cCCCWWWWWWCCCc.", ".cCCWCCCCCCWCCc.", ".cCCCWWWWWWCCCc.", "..cCCCCCCCCCCc..",
		"..cCCCCCCCCCCc..", "...ccCCCCCCcc...", ".....cccccc.....", "................"],
	ItemIds.DANCE_ORB: [
		"................", ".....pppppp.....", "...ppPPPPPPpp...", "..pPPPPPPWWWPp..",
		"..pPPPPPPWPWPp..", ".pPPPPPPPWPWPPp.", ".pPPPPPPPWPWPPp.", ".pPPPPPPPWPWPPp.",
		".pPPPPWWWWPWPPp.", ".pPPPWWWWWWWPPp.", ".pPPPWWWWWWWPPp.", "..pPPPWWPPWWPp..",
		"..pPPPPPPPPPPp..", "...ppPPPPPPpp...", ".....pppppp.....", "................"],
}


## The 16 x 16 picture of a gadget (a blank image for anything else).
static func image(id: int) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rows: Array = PICTURES.get(id, [])
	for y in rows.size():
		var row: String = rows[y]
		for x in mini(row.length(), 16):
			var c: Variant = COLORS.get(row[x])
			if c != null:
				img.set_pixel(x, y, c)
	return img
