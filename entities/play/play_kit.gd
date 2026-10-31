class_name PlayKit
extends RefCounted
## Owner #122 (G0): the play arena's building blocks on top of Life's room kit (LifeRoomKit: boxes, cylinders, spheres,
## billboard signs, lights; only shaders the warm-up already holds). Cards are the things a child acts with: a thick
## card with its words (a billboard that always faces the child, wrapped to the card) or its picture (PlayBoard).

## A card's words: big enough on a phone (about 24 px a line from the flat view) and in a headset; a long text gets a
## smaller font (to CARD_FONT_LEAST) so it stays within CARD_LINES lines, and its card grows to hold them.
const CARD_PIXEL := 0.0013
const CARD_FONT := 54
const CARD_FONT_LEAST := 40
const CARD_LINES := 3
const CARD_WIDTH_PX := 330
const SIGN_PIXEL := 0.0016
const WOOD := Color("b98a57")
const WOOD_DARK := Color("8a6239")
const PAPER := Color("fdf6e3")
const INK := Color("1f2a4a")


## A card leans back this far (rad), so its face (and the words in front of it) turn up towards the child and the flat
## view looking down at the table: its own box never hides its words.
const LEAN := 0.6


## A thing to act with at `at` (under `parent`): a card of `size` (its face towards the child, +Z, leaning back), its
## words over it or its picture on it; the words' size fits the card's width (its longest word on one line). Returns the
## card's root (its "Words" label or "Picture" board below it).
static func card(parent: Node3D, card_name: String, item: Dictionary, at: Vector3, colour: Color,
		size: Vector3 = Vector3(0.44, 0.15, 0.05), lean: float = LEAN) -> Node3D:
	var root := Node3D.new()
	root.name = card_name
	root.position = at
	root.rotation.x = -lean
	parent.add_child(root)
	var pic: Variant = item.get("picture")
	var text := str(item.get("text", ""))
	if text != "" and not pic is Dictionary:   # the card holds its words: as tall as their lines
		var width_px := maxf(size.x - 0.02, 0.1) / CARD_PIXEL
		var font := card_font(text, width_px)
		size.y = maxf(size.y, lines_of(text, width_px, font) * font * CARD_PIXEL * 1.2 + 0.03)
	LifeRoomKit.box(root, "Card", size, Vector3.ZERO, colour)
	if pic is Dictionary:
		var board := PlayBoard.new(pic, Vector2(size.x * 0.94, size.y * 0.9), Vector2i(240, 140))
		board.name = "Picture"
		board.position = Vector3(0, 0, size.z * 0.5 + 0.004)
		root.add_child(board)
	if text != "":
		var l := words(root, "Words", text, Vector3(0, size.y * 0.5 + 0.05 if pic is Dictionary else 0.0, size.z * 0.5 + 0.02))
		l.width = maxf(size.x - 0.02, 0.1) / CARD_PIXEL   # wrapped to the card's own width
		l.font_size = card_font(text, l.width)
	return root


## The biggest font (to `most`) at which the longest word of `text` fits `width_px` on one line (a capital is about 0.72
## of the font's size wide; never under 24).
static func fit_font(text: String, width_px: float, most: int) -> int:
	var longest := 1
	for w in text.split(" ", false):
		longest = maxi(longest, w.length())
	return clampi(floori(width_px / (longest * 0.72)), 24, most)


## A card's font: its longest word on one line, and the text within CARD_LINES lines when it can (to CARD_FONT_LEAST).
static func card_font(text: String, width_px: float) -> int:
	var font := fit_font(text, width_px, CARD_FONT)
	while font > CARD_FONT_LEAST and lines_of(text, width_px, font) > CARD_LINES:
		font -= 2
	return font


## About how many lines `text` wraps to at `font` in `width_px` (a letter about 0.55 of the font wide, word by word).
static func lines_of(text: String, width_px: float, font: int) -> int:
	var per_line := maxi(1, floori(width_px / (font * 0.55)))
	var lines := 1
	var used := 0
	for w in text.split(" ", false):
		var n := w.length()
		if used > 0 and used + 1 + n > per_line:
			lines += 1
			used = n
		else:
			used += (1 if used > 0 else 0) + n
	return lines


## Wrapped billboard words (the animals' tags' settings: warmed).
static func words(parent: Node3D, label_name: String, text: String, at: Vector3, pixel: float = CARD_PIXEL,
		font: int = CARD_FONT, colour: Color = Color.WHITE) -> Label3D:
	var l := LifeRoomKit.sign(parent, label_name, text, at, pixel, colour)
	l.font_size = font
	l.outline_size = 10
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = CARD_WIDTH_PX
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## A big round button on a post (the world's test: RUN THE MACHINE, WALK ACROSS): its words over it.
static func go_button(parent: Node3D, text: String, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Go"
	root.position = at
	parent.add_child(root)
	LifeRoomKit.cylinder(root, "Post", 0.035, at.y, Vector3(0, -at.y * 0.5, 0), Color("6b7a99"))
	LifeRoomKit.cylinder(root, "Base", 0.09, 0.05, Vector3(0, 0, 0), Color("39445e"))
	LifeRoomKit.cylinder(root, "Button", 0.075, 0.05, Vector3(0, 0.045, 0), Color("2fae4e"))
	if not PlayVoice.on():   # owner #133: with the voice on, the big green button is the test (its words are spoken)
		words(root, "Words", text, Vector3(0, 0.17, 0), 0.0011, 46, Color("eaffea"))
	return root


## A wooden table (its top at `top` above the floor, centred at `at`).
static func table(parent: Node3D, at: Vector3, size: Vector2, top: float = 0.72) -> void:
	LifeRoomKit.box(parent, "TableTop", Vector3(size.x, 0.05, size.y), Vector3(at.x, top - 0.025, at.z), WOOD)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			LifeRoomKit.box(parent, "Leg", Vector3(0.05, top - 0.05, 0.05),
				Vector3(at.x + sx * (size.x * 0.5 - 0.06), (top - 0.05) * 0.5, at.z + sz * (size.y * 0.5 - 0.06)), WOOD_DARK)
