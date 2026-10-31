class_name TinyPictures
extends RefCounted
## The Tiny world's pictures (M3 Task 21c), for the Secret Book and the banners: a mouse's face (a mouse village
## found) and a tiny door in a hill (the book's picture riddle until then). 16 px pictures drawn in code as text rows
## (no atlas file to share with other tasks), made once into a small atlas; Pictures.texture(id) and
## Pictures.material(id) pick it for ids from FIRST on (the M2 atlas holds 0-31, the treasure pack's 32-55).

const FIRST := 64
const MOUSE := 64
const DOOR := 65
const TILE := 16

const PALETTE := {
	"g": Color("9a8f88"), "d": Color("6e635d"), "p": Color("ffb3c1"), "k": Color("231f20"), "w": Color("ffffff"),
	"n": Color("ff7a9a"), "G": Color("5fae3a"), "L": Color("3f8f2a"), "b": Color("7a4a24"), "y": Color("ffd23f"),
	"o": Color("c8995c"),
}
const PICTURES := [
	[   # MOUSE: a mouse's face with round pink ears
		"................", ".ggg......ggg...", "gpppg....gpppg..", "gpppg....gpppg..",
		"gpppgggggppppg..", ".gggggggggggg...", "..ggggggggggg...", "..ggkwggggkwg...",
		"..ggkkggggkkg...", "..ggggggggggg...", "...gggnnggggg...", "k..ggggggggg..k.",
		".kk.ggggggg.kk..", "......ggg.......", "................", "................"],
	[   # DOOR: a tiny round door at the foot of a green hill, a pumpkin by it
		"................", "................", ".....GGGGGG.....", "...GGLGGGGLGG...",
		"..GGGGGGGGGGGG..", ".GGLGGGGGGGGLGG.", ".GGGGGbbbbGGGGG.", "GGGGGbooobGGGGGG",
		"GGLGGbooobGGGLGG", "GGGGGbooybGGGGGG", "GGGGGbooobGGGGGG", "GGGGGbooobGGGyGG",
		"dddddbooobdddyyd", "dddddddddddddddd", "................", "................"],
]

static var _atlas: Texture2D


## The pictures' atlas (a row of tiles), made once.
static func atlas() -> Texture2D:
	if _atlas == null:
		var img := Image.create(TILE * PICTURES.size(), TILE, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for i in PICTURES.size():
			var rows: Array = PICTURES[i]
			for y in rows.size():
				var row: String = rows[y]
				for x in mini(row.length(), TILE):
					var c: String = row[x]
					if PALETTE.has(c):
						img.set_pixel(i * TILE + x, y, PALETTE[c])
		_atlas = ImageTexture.create_from_image(img)
	return _atlas


static func has(id: int) -> bool:
	return id >= FIRST and id < FIRST + PICTURES.size()


## Picture `id`'s tile in the atlas.
static func tile(id: int) -> Vector2i:
	return Vector2i(clampi(id - FIRST, 0, PICTURES.size() - 1), 0)
