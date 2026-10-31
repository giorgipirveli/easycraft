class_name OnlineRoom
extends LifeRoom
## Owner #112, #118 (docs/design/life-skills.md §5 row 7, §14 row 14; Life L3c): Online City's practice room: a calm living
## room with a sofa, a window, a clock and Gus, and the play tablet on the low table. On the tablet is Online City, a
## pretend town of games, chats, news and a shop: **nothing real** (no real sites, apps, brands or people), **nothing the
## child types** (every answer is a button or a picture), **nothing kept or sent**. Each step names its tablet `page`
## (step_started shows it): the town's map, a new game, chats, a pop-up, the Photo Wall, a break, a stranger in a game's
## chat (SEND PHOTO, BLOCK, REPORT), a mean post, the password page, the free gold scam, the News Stand with its three
## checks, a pretend profile's cards, a friend request, a phishing message, a changed picture, a group chat.
## Picked up (`pick`), the tablet is held (LifeRoom.held): flat, in front of the view; in VR in the off hand, its buttons
## pressed by the other hand or the laser. A stranger is only a grey "?" on the screen, never a face. The safe mistakes'
## gentle pictures (on_mistake, still, on the tablet): a photo card frozen on its way to a grey "?" far off ("ONCE IT'S
## SENT, YOU CAN'T TAKE IT BACK"); a fishing hook frozen over the password card ("IT'S A TRICK TO TAKE YOUR ACCOUNT").

const FLOOR := Color("d9c3a0")
const WALL := Color("f3efe6")
const WOOD := Color("a8642a")
const INK := Color("1f2a4a")
const SCREEN := Color("bfe4ff")
const BUTTON := Color("3a7be8")
const SOFT := Color("6b7a99")
const KIND := Color("2fae4e")
const WARM := Color("ffd23f")
## The tablet's size (m): a big play tablet, its buttons a fingertip's size at reading distance.
const SIZE := Vector2(0.42, 0.3)
## The child's feet and eye in the room (the start view's VR spot); the tablet is held 0.42 m in front, a little low.
const FEET := Vector3(0, 0, 1.2)
const HELD_AT := Vector3(0, 0.92, 0.78)
const PAGES: Array[String] = ["home", "new_game", "chat_name", "chat_photo", "sad", "popup", "kind", "break", "stranger",
	"chat", "mean", "password", "gold", "news", "profile", "photos", "request", "phish", "photo_changed", "group"]
const CHAT_PAGES: Array[String] = ["stranger", "mean"]
const CLOSE_PAGES: Array[String] = ["popup", "gold"]

var gus: LifeBuddy
var tablet: Node3D
var page := ""
var pages := {}
var chat_bar: Node3D
var close_bar: Node3D
var headline: Label3D
var news_answers := {}
var _pick_spot: Node3D
var _flash: MeshInstance3D
var _t := 0.0


func build() -> void:
	name = "OnlineRoom"
	env = LifeRoomKit.environment(Color("d6e8f5"), Color("f3f6f9"), 0.8)
	start_view = "room"
	_living_room()
	_tablet()
	_views()


# --- The living room ----------------------------------------------------------------------------------------------------

func _living_room() -> void:
	_living_look()   # the rooms' look (2026-10-18): the floor, the walls, the windows, the lamp
	var sc := scenery()
	LifeRoomKit.box(sc, "Rug", Vector3(2.2, 0.01, 1.6), Vector3(0, 0.005, 0.4), Color("e9b8c8"))
	LifeRoomKit.box(sc, "RugMiddle", Vector3(1.9, 0.012, 1.3), Vector3(0, 0.007, 0.4), Color("f3cfdb"))
	var room_sign := LifeRoomKit.sign(self, "RoomSign", "PRACTICE LIVING ROOM", Vector3(0, 2.3, -2.35), 0.005, Color("2f7f6a"))
	room_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on the wall (turned to the eye, it sank into the wall)
	LifeRoomKit.light(self, Vector3(0, 2.4, 0.6), 0.55, 8.0)
	sun(Color(1.0, 0.95, 0.86), 0.8)   # indoors: a softer key light
	# the sofa behind the child, the low table in front with the tablet on it
	LifeRoomKit.box(sc, "Sofa", Vector3(2.0, 0.45, 0.8), Vector3(0, 0.225, 2.1), Color("5aa8e6"))
	LifeRoomKit.box(sc, "SofaBack", Vector3(2.0, 0.5, 0.2), Vector3(0, 0.7, 2.45), Color("4a8fcf"))
	for x: float in [-1.05, 1.05]:
		LifeRoomKit.box(sc, "SofaArm", Vector3(0.18, 0.62, 0.8), Vector3(x, 0.31, 2.1), Color("4a8fcf"))
	for x: float in [-0.55, 0.55]:
		LifeRoomKit.box(sc, "Cushion", Vector3(0.42, 0.36, 0.12), Vector3(x, 0.62, 2.3), Color("ffd23f") if x < 0 else Color("e85a9a"))
	LifeRoomKit.box(sc, "LowTable", Vector3(0.8, 0.44, 0.5), Vector3(0, 0.22, 0.2), WOOD)
	_pick_spot = add_spot_target("tablet_rest", self, Vector3(0, 0.47, 0.2), 0.2)
	# the window, a plant, the bookshelf and the clock (time online)
	decor().window("Window", Vector3(-1.4, 1.5, -2.39), 1.3, 0.85, 0.0)
	LifeRoomKit.box(sc, "Shelf", Vector3(0.9, 1.4, 0.3), Vector3(1.8, 0.7, -2.25), WOOD.darkened(0.15))
	for i in 6:
		LifeRoomKit.box(sc, "Book", Vector3(0.08, 0.26, 0.2), Vector3(1.45 + i * 0.12, 1.15, -2.2),
			[Color("e8544e"), Color("3a7be8"), Color("ffd23f"), Color("2fae4e"), Color("e85a9a"), Color("7b5cd6")][i])
	LifeRoomKit.cylinder(sc, "Pot", 0.14, 0.26, Vector3(-2.4, 0.13, -1.9), Color("c0563a"))
	LifeRoomKit.sphere(sc, "Leaves", 0.28, Vector3(-2.4, 0.5, -1.9), Color("4f9a3e"))
	LifeRoomKit.cylinder(sc, "Clock", 0.18, 0.04, Vector3(0.4, 1.9, -2.38), Color("fdfdf8")).rotation.x = PI / 2
	# Gus, standing by the sofa's end: the grown-up to ask and to tell
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55
	gus.position = Vector3(-0.95, 0, 0.5)
	gus.rotation.y = 0.94
	add_child(gus)
	var m := Node3D.new()
	m.name = "T_gus"
	m.position = Vector3(0, 0.63, 0.1)
	gus.add_child(m)
	add_target("gus", m, 0.45)
	LifeRoomPeople.merge_person(gus, true)   # the Quest's draws: Gus never changes pose


# --- The play tablet and its pretend pages --------------------------------------------------------------------------------

func _tablet() -> void:
	tablet = Node3D.new()
	tablet.name = "PlayTablet"
	add_child(tablet)
	tablet.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2), Vector3(0, 0.455, 0.2))   # lying on the table, face up
	held = tablet
	var eye := FEET + Vector3(0, EYE, 0)
	held_rest = Transform3D(Basis.looking_at(-(eye - HELD_AT), Vector3.UP), HELD_AT)
	LifeRoomKit.box(tablet, "Frame", Vector3(SIZE.x, SIZE.y, 0.02), Vector3.ZERO, INK)
	LifeRoomKit.box(tablet, "Screen", Vector3(SIZE.x - 0.03, SIZE.y - 0.03, 0.004), Vector3(0, 0, 0.011), SCREEN)
	for p in PAGES:
		var n := Node3D.new()
		n.name = "Page_" + p
		n.visible = false
		tablet.add_child(n)
		pages[p] = n
	_page_home()
	_page_words("new_game", "NEW GAME: BLOCK RACE", "A pretend racing game. Ask a grown-up first!", WARM)
	_page_chat("chat_name", "?: What's your name? Where do you live?")
	_page_chat("chat_photo", "?: Send me a photo of you!")
	_page_sad()
	_page_popup()
	_page_wall("kind", "MO'S ROCKET", Color("e85a9a"))
	_page_break()
	_page_chat("stranger", "?: You're good! Send me a photo of you. Where do you live?")
	var send := _button(pages.stranger, "SEND PHOTO", Vector2(-0.11, -0.03), SOFT, Vector2(0.15, 0.05))
	add_target("send_photo", send, 0.045)
	_page_chat("chat", "Online friend: Let's meet at the park, just us!")
	_page_chat("mean", "Player 7: you're bad at this game")
	_page_password()
	_page_gold()
	_page_news()
	_page_profile()
	_page_wall("photos", "MY SILLY PHOTO", Color("5aa8e6"))
	_page_chat("request", "FRIEND REQUEST: Hi, I'm 12 too, from your school! Add me?")
	_page_chat("phish", "ONLINE CITY TEAM?: Your account will close today! Log in at this link.")
	_page_wall("photo_changed", "A CAT AS BIG AS A BUS!", Color("ffb347"))
	_page_chat("group", "Group chat: ha ha, Bobo's dance! Add a joke!")
	# the chat pages' BLOCK and REPORT, the pop-ups' X: one each, shown with their pages
	chat_bar = Node3D.new()
	chat_bar.name = "ChatBar"
	chat_bar.visible = false
	tablet.add_child(chat_bar)
	add_target("block", _button(chat_bar, "BLOCK", Vector2(0.05, -0.09), SOFT), 0.045)
	add_target("report", _button(chat_bar, "REPORT", Vector2(0.15, -0.09), BUTTON), 0.045)
	close_bar = Node3D.new()
	close_bar.name = "CloseBar"
	close_bar.visible = false
	tablet.add_child(close_bar)
	add_target("close_x", _button(close_bar, "X", Vector2(0.165, 0.105), Color("dfe3ea"), Vector2(0.05, 0.045)), 0.04)


func _label(parent: Node3D, text: String, at: Vector2, pixel: float = 0.0007, colour: Color = INK, width: float = 0.0) -> Label3D:
	var l := LifeRoomKit.sign(parent, "Words", text, Vector3(at.x, at.y, 0.02), pixel, colour)
	l.outline_size = 0
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.width = width / pixel
	return l


func _button(parent: Node3D, text: String, at: Vector2, colour: Color, size := Vector2(0.09, 0.05)) -> MeshInstance3D:
	var b := LifeRoomKit.box(parent, "Button", Vector3(size.x, size.y, 0.01), Vector3(at.x, at.y, 0.016), colour)
	var l := LifeRoomKit.sign(b, "Words", text, Vector3(0, 0, 0.008), 0.0005, Color.WHITE)
	l.outline_size = 0
	return b


func _page_words(p: String, title: String, words: String, colour: Color) -> void:
	LifeRoomKit.box(pages[p], "Banner", Vector3(0.36, 0.06, 0.004), Vector3(0, 0.09, 0.015), colour)
	_label(pages[p], title, Vector2(0, 0.09))
	_label(pages[p], words, Vector2(0, -0.02), 0.0006, INK, 0.34)


func _page_home() -> void:
	var p: Node3D = pages.home
	_label(p, "ONLINE CITY", Vector2(0, 0.115), 0.0008, Color("2f7f6a"))
	LifeRoomKit.box(p, "Road", Vector3(0.36, 0.02, 0.003), Vector3(0, 0.0, 0.014), Color("c9ced6"))
	var places := [["app_game", "GAME PARK", Vector2(-0.13, 0.045), Color("2fae4e")],
		["app_chat", "CHAT SQUARE", Vector2(0.0, 0.045), Color("3a7be8")],
		["app_news", "NEWS STAND", Vector2(0.13, 0.045), Color("e0a400")],
		["app_photos", "PHOTO WALL", Vector2(-0.07, -0.07), Color("e85a9a")],
		["app_shop", "SHOP", Vector2(0.07, -0.07), Color("7b5cd6")]]
	for place: Array in places:
		var b := _button(p, str(place[1]), place[2], place[3], Vector2(0.11, 0.07))
		add_target(str(place[0]), b, 0.05)


func _page_chat(p: String, message: String) -> void:
	_label(pages[p], "CHAT", Vector2(-0.15, 0.115), 0.0006, SOFT)
	LifeRoomKit.sphere(pages[p], "Someone", 0.025, Vector3(-0.16, 0.055, 0.02), Color("b8c2d6"))   # a grey "?", never a face
	_label(pages[p], "?", Vector2(-0.16, 0.055), 0.0007, INK)
	LifeRoomKit.box(pages[p], "Bubble", Vector3(0.28, 0.09, 0.004), Vector3(0.03, 0.05, 0.015), Color("fdfdf8"))
	_label(pages[p], message, Vector2(0.03, 0.05), 0.0005, INK, 0.26)


func _page_sad() -> void:
	var p: Node3D = pages.sad
	LifeRoomKit.box(p, "Grey", Vector3(SIZE.x - 0.04, SIZE.y - 0.04, 0.003), Vector3(0, 0, 0.014), Color("b8c2d6"))
	LifeRoomKit.sphere(p, "SadFace", 0.06, Vector3(0, 0.01, 0.02), Color("fdfdf8"))
	LifeRoomKit.box(p, "Mouth", Vector3(0.05, 0.008, 0.01), Vector3(0, -0.02, 0.078), INK)
	_label(p, "Something here doesn't feel right", Vector2(0, -0.09), 0.0005)


func _page_popup() -> void:
	var p: Node3D = pages.popup
	LifeRoomKit.box(p, "Box", Vector3(0.34, 0.22, 0.004), Vector3(0, 0.0, 0.015), Color("fdfdf8"))
	_label(p, "YOUR TABLET IS SLOW! DOWNLOAD THIS NOW!", Vector2(-0.01, 0.05), 0.0005, INK, 0.26)
	var d := _button(p, "DOWNLOAD", Vector2(0, -0.05), Color("ff7a2e"), Vector2(0.14, 0.06))
	add_target("download", d, 0.05)
	_flash = d


func _page_wall(p: String, title: String, colour: Color) -> void:
	_label(pages[p], "PHOTO WALL", Vector2(-0.12, 0.115), 0.0006, SOFT)
	LifeRoomKit.box(pages[p], "Picture", Vector3(0.16, 0.12, 0.004), Vector3(-0.07, 0.01, 0.015), colour)
	_label(pages[p], title, Vector2(-0.07, -0.08), 0.0005)
	LifeRoomKit.box(pages[p], "Comments", Vector3(0.12, 0.14, 0.004), Vector3(0.12, 0.0, 0.015), Color("fdfdf8"))


func _page_break() -> void:
	var p: Node3D = pages["break"]
	LifeRoomKit.cylinder(p, "Clock", 0.05, 0.004, Vector3(-0.1, 0.03, 0.016), Color("fdfdf8")).rotation.x = PI / 2
	_label(p, "You've played for a while.", Vector2(0.06, 0.06), 0.0005, INK, 0.2)
	add_target("take_break", _button(p, "TAKE A BREAK", Vector2(0.06, -0.05), KIND, Vector2(0.16, 0.06)), 0.05)


func _page_password() -> void:
	var p: Node3D = pages.password
	_label(p, "MAKE A PASSWORD", Vector2(0, 0.1), 0.0007, Color("2f7f6a"))
	LifeRoomKit.box(p, "Lock", Vector3(0.06, 0.05, 0.01), Vector3(-0.12, 0.0, 0.018), KIND)
	LifeRoomKit.box(p, "Field", Vector3(0.22, 0.05, 0.004), Vector3(0.05, 0.0, 0.015), Color("fdfdf8"))
	_label(p, "* * * * * * *", Vector2(0.05, 0.0), 0.0006)
	_label(p, "Never tell anyone your password. Not even a friend.", Vector2(0, -0.08), 0.00045, INK, 0.34)


func _page_gold() -> void:
	var p: Node3D = pages.gold
	LifeRoomKit.box(p, "Box", Vector3(0.34, 0.22, 0.004), Vector3(0, 0.0, 0.015), Color("fff4c2"))
	for i in 3:
		LifeRoomKit.cylinder(p, "Coin", 0.018, 0.004, Vector3(-0.12 + i * 0.03, 0.06, 0.02), Color("ffc93c")).rotation.x = PI / 2
	_label(p, "FREE GOLD! 1000 GOLD FOR YOU! SEND YOUR PASSWORD", Vector2(0.03, 0.05), 0.00045, INK, 0.22)
	var card := LifeRoomKit.box(p, "PasswordCard", Vector3(0.09, 0.04, 0.004), Vector3(0.1, -0.05, 0.018), Color("fdfdf8"))
	card.name = "PasswordCard"
	add_target("get_gold", _button(p, "GET GOLD", Vector2(-0.07, -0.05), Color("ff7a2e"), Vector2(0.13, 0.06)), 0.05)


func _page_news() -> void:
	var p: Node3D = pages.news
	_label(p, "NEWS STAND", Vector2(-0.12, 0.115), 0.0006, SOFT)
	headline = _label(p, "BIG NEWS!", Vector2(0, 0.065), 0.0006, INK, 0.34)
	var checks := [["news_who", "WHO MADE IT?", -0.13, "NOBODY KNOWS"], ["news_when", "WHEN?", 0.0, "NO DATE"],
		["news_others", "ANYONE ELSE?", 0.13, "NO ONE ELSE SAYS SO"]]
	for c: Array in checks:
		add_target(str(c[0]), _button(p, str(c[1]), Vector2(float(c[2]), -0.02), BUTTON, Vector2(0.11, 0.05)), 0.045)
		var a := _label(p, str(c[3]), Vector2(float(c[2]), -0.085), 0.0004, SOFT, 0.11)
		a.visible = false
		news_answers[c[0]] = a


func _page_profile() -> void:
	var p: Node3D = pages.profile
	_label(p, "MY PRETEND PROFILE", Vector2(0, 0.115), 0.0006, Color("2f7f6a"))
	var cards := [["", "PICTURE NAME: FOX", Vector2(-0.13, 0.04)], ["", "FAVOURITE COLOUR: BLUE", Vector2(0.0, 0.04)],
		["card_school", "MY SCHOOL", Vector2(0.13, 0.04)], ["card_address", "MY ADDRESS", Vector2(-0.13, -0.06)],
		["card_photo", "PHOTO OF ME", Vector2(0.0, -0.06)], ["card_password", "MY PASSWORD", Vector2(0.13, -0.06)]]
	for c: Array in cards:
		var b := _button(p, str(c[1]), c[2], Color("dfe7f5") if str(c[0]) == "" else Color("ffb347"), Vector2(0.115, 0.075))
		(b.get_node("Words") as Label3D).modulate = INK
		if str(c[0]) != "":
			add_target(str(c[0]), b, 0.05)


func _views() -> void:
	add_view("room", Vector3(0.7, 1.75, 2.9), Vector3(-0.3, 0.6, 0.0), FEET, 0.0)
	var n := held_rest.basis.z   # the held tablet's face points to the eye
	var c := held_rest.origin + Vector3(0, 0.035, 0)
	add_view("tablet", c + n * 0.36, c, FEET, 0.0)


# --- Steps and events -----------------------------------------------------------------------------------------------------

func show_page(p: String) -> void:
	page = p
	for k: String in pages:
		(pages[k] as Node3D).visible = k == p
	chat_bar.visible = CHAT_PAGES.has(p)
	close_bar.visible = CLOSE_PAGES.has(p)
	if p == "news":
		for a: Label3D in news_answers.values():
			a.visible = false


func step_started(step: Dictionary) -> void:
	if str(step.get("page", "")) != "":
		show_page(str(step.page))
	if step.has("headline") and headline:
		headline.text = str(step.headline)


func step_done(step: Dictionary) -> void:
	if str(step.get("id", "")) == "pick":
		holding = true
		_pick_spot.visible = false   # the table's spot goes once the tablet is in the hand
		tablet.transform = held_rest
		show_page("home")


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"sequence":
			for i in int(state.get("i", 0)):
				var t := str((step.targets as Array)[i])
				if news_answers.has(t):
					(news_answers[t] as Label3D).visible = true
		"find":
			for f: Variant in state.get("found", []):
				var t := str(f)
				if has_target(t) and target_node(t).get_node_or_null("Found") == null:
					var lock := LifeRoomKit.box(target_node(t), "Found", Vector3(0.025, 0.022, 0.01), Vector3(0.04, 0.025, 0.01),
						Color(0.3, 0.85, 0.4, 1.0))
					lock.name = "Found"


func _process(delta: float) -> void:
	super(delta)
	_t += sim_delta(delta)
	if is_instance_valid(_flash):   # the pop-up's button flashes gently (still while frozen)
		_flash.scale = Vector3.ONE * (1.0 + 0.05 * sin(_t * 5.0))


# --- The safe mistakes' gentle pictures (on the tablet, still) ---------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if not on:
		return
	var holder := mistake_holder()
	holder.transform = tablet.transform   # the picture sits on the tablet, wherever it is held
	match event:
		"photo_sent":   # the photo card frozen on its way to a grey "?" far off: once sent, it can't come back
			var photo := LifeRoomKit.box(holder, "Photo", Vector3(0.07, 0.06, 0.005), Vector3(0.12, 0.2, 0.08), Color("fdfdf8"))
			LifeRoomKit.sphere(photo, "Face", 0.014, Vector3(0, 0.005, 0.004), LifeBuddy.SKIN)
			for i in 3:
				LifeRoomKit.sphere(holder, "Trail", 0.006, Vector3(0.18 + i * 0.07, 0.26 + i * 0.05, 0.1 + i * 0.03), SOFT)
			LifeRoomKit.sphere(holder, "Someone", 0.05, Vector3(0.45, 0.42, 0.2), Color("b8c2d6"))
			LifeRoomKit.sign(holder, "Who", "?", Vector3(0.45, 0.42, 0.26), 0.0015, INK)
			LifeRoomKit.sign(holder, "Why", "ONCE IT'S SENT, YOU CAN'T TAKE IT BACK", Vector3(0, 0.3, 0.1), 0.0011, WARM)
		"scam_hook":   # a little fishing hook frozen over the password card
			LifeRoomKit.box(holder, "Line", Vector3(0.003, 0.25, 0.003), Vector3(0.1, 0.1, 0.06), INK)
			LifeRoomKit.box(holder, "Hook", Vector3(0.03, 0.006, 0.006), Vector3(0.11, -0.025, 0.06), Color("9aa3ad"))
			LifeRoomKit.box(holder, "Barb", Vector3(0.006, 0.02, 0.006), Vector3(0.124, -0.015, 0.06), Color("9aa3ad"))
			LifeRoomKit.sign(holder, "Why", "IT'S A TRICK TO TAKE YOUR ACCOUNT", Vector3(0, 0.26, 0.08), 0.0011, WARM)


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A calm family living room: a plank floor, warm walls on three sides and behind the sofa with a skirting, a second
## window, a ceiling with its light, a floor lamp, pictures, a plant, a sideboard; a garden outside. Never on the tablet,
## its table, Gus or a view's line.
func _living_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Garden", Vector3(70, 0.1, 70), Vector3(0, -0.16, 0), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(6.0, 0.1, 5.8), Vector3(0, -0.05, 0.35), Color("f2dcc0"), 0.75)
	d.box("BackWall", Vector3(6.0, 2.6, 0.1), Vector3(0, 1.3, -2.45), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("Wallpaper", Vector3(6.0, 1.6, 0.02), Vector3(0, 1.8, -2.395), Color("e8f0f6"), 0.0, LifeRoomDecor.SHELL)
	for x: float in [-3.0, 3.0]:
		d.box("SideWall", Vector3(0.1, 2.6, 5.8), Vector3(x, 1.3, 0.35), WALL.darkened(0.03), 0.0, LifeRoomDecor.SHELL)
		d.skirting("Skirting", Vector3(x * 0.98, 0, -2.4), Vector3(x * 0.98, 0, 3.2), Color("c89a62"))
	d.box("SofaWall", Vector3(6.0, 2.6, 0.1), Vector3(0, 1.3, 3.25), WALL, 0.0, LifeRoomDecor.SHELL)
	d.skirting("Skirting", Vector3(-3.0, 0, -2.39), Vector3(3.0, 0, -2.39), Color("c89a62"))
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(6.0, 0.1, 5.8), Vector3(0, 2.65, 0.35), Color("fbf8f2"), 0.8)
	d.ceiling_light("Light", Vector3(0, 2.58, 0.4), 0.32)
	d.window("Window2", Vector3(2.94, 1.5, -0.4), 1.1, 0.9, -PI / 2)
	d.lamp("FloorLamp", Vector3(1.6, 0, 2.6), 1.45)
	d.picture("Picture", Vector3(-2.94, 1.6, 0.9), Vector2(0.7, 0.5), PI / 2, Color("8a6239"), Color("fff6e0"), 0)
	d.picture("Picture", Vector3(0.0, 1.55, 3.19), Vector2(0.9, 0.55), PI, Color("3a7be8"), Color("fff6e0"), 2)
	d.box("Sideboard", Vector3(0.45, 0.7, 1.4), Vector3(-2.7, 0.35, -0.6), Color("c89a62"))
	d.plant("SideboardPlant", Vector3(-2.7, 0.7, -0.9), 0.6, Color("3a7be8"))
	d.box("Vase", Vector3(0.12, 0.25, 0.12), Vector3(-2.7, 0.82, -0.2), Color("e85a9a"))
