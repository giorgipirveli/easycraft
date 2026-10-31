class_name CalmRoom
extends LifeRoom
## Owner #112 (docs/design/life-skills.md §5 #6, §6): Calm Corner's quiet room: soft lilac walls, a big round rug, floor
## cushions, a window with slow clouds, a lamp, a plant, books, a sleepy cat, a clock, a fish in its bowl (the five things
## to see), the balloon for balloon breathing (it grows as the child breathes in and shrinks as they breathe out), the
## worry box on a low table, the calm toolbox's picture cards, and a tablet on a stand for the online stories. Bobo, Mo
## and Pip-pop act the stories with their faces (LifeBuddy.face): never a scary face, never a word of unkindness shown
## (the tablet says "a mean comment", not the comment). Nothing the child picks changes anything kept.

const WALL := Color("dcd0f2")
const RUG := Color("b9a6e8")
const FLOOR := Color("e8d8c0")
const TOOLS: Array[String] = ["tool_breathe", "tool_count", "tool_walk", "tool_talk", "tool_draw", "tool_music"]
const TOOL_WORDS := {"tool_breathe": "BREATHE", "tool_count": "COUNT TO 10", "tool_walk": "A WALK", "tool_talk": "TALK",
	"tool_draw": "DRAW", "tool_music": "MUSIC"}

var bobo: LifeBuddy
var mo: LifeBuddy
var pip: LifeBuddy
var balloon: MeshInstance3D
var tower: Node3D
var ball: MeshInstance3D
var screen: Label3D
var worry_card: MeshInstance3D
var found_rings := {}
var toolbox: Node3D
var tablet_stand: Node3D
var _cloud_t := 0.0
var clouds: Array[MeshInstance3D] = []


func build() -> void:
	name = "CalmRoom"
	env = LifeRoomKit.environment(Color("cfd8f0"), Color("f5f0fb"), 0.6)
	start_view = "rug"
	_room()
	_things()
	_buddies()
	_breathing()
	_worry_box()
	_toolbox()
	_tablet()
	_calm_look()   # the rooms' look (2026-10-18)
	for b: LifeBuddy in [bobo, mo, pip]:   # the Quest's draws: none changes pose; faces through feel
		LifeRoomPeople.merge_person(b, true)
	_views()


func _room() -> void:
	var d := decor()   # the rooms' look: a soft plank floor, lilac walls with a rail and a skirting
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(6.0, 0.1, 5.4), Vector3(0, -0.05, 0.0), Color("f6e6d2"), 0.75)
	var sc := scenery()
	LifeRoomKit.cylinder(sc, "Rug", 1.6, 0.02, Vector3(0, 0.01, 0.4), RUG)
	LifeRoomKit.cylinder(sc, "RugRim", 1.68, 0.012, Vector3(0, 0.006, 0.4), RUG.darkened(0.15))
	d.box("BackWall", Vector3(6.0, 2.8, 0.1), Vector3(0, 1.4, -2.5), WALL, 0.0, LifeRoomDecor.SHELL)
	for x: float in [-3.0, 3.0]:
		d.box("SideWall", Vector3(0.1, 2.8, 5.4), Vector3(x, 1.4, 0.0), WALL.darkened(0.03), 0.0, LifeRoomDecor.SHELL)
	for c: Vector3 in [Vector3(-1.1, 0.12, 0.9), Vector3(1.2, 0.12, 1.0), Vector3(-0.4, 0.12, -0.9)]:
		LifeRoomKit.box(sc, "Cushion", Vector3(0.6, 0.22, 0.6), c, Color("f6c2d6"))
	LifeRoomKit.light(self, Vector3(0, 2.4, 0.4), 0.55, 7.0, Color(1, 0.95, 0.88))
	sun(Color(1.0, 0.95, 0.88), 0.75)   # indoors and calm: a softer key light
	# painted high on the back wall, smaller (bigger it sat half under the HUD's bar)
	var room_sign := LifeRoomKit.sign(self, "RoomSign", "CALM CORNER", Vector3(1.75, 2.42, -2.44), 0.0036, Color("6b5aa8"))
	room_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	room_sign.outline_size = 0


## The five things to see (and two more), round the room in front of the child.
func _things() -> void:
	var lamp := LifeRoomKit.sphere(self, "Lamp", 0.2, Vector3(-2.1, 1.5, -0.6), Color(1.0, 0.92, 0.7))
	LifeRoomKit.box(scenery(), "LampStand", Vector3(0.05, 1.3, 0.05), Vector3(-2.1, 0.65, -0.6), Color("9aa7b5"))
	add_target("lamp", lamp, 0.3)
	var plant := LifeRoomKit.sphere(self, "Plant", 0.3, Vector3(-1.5, 0.55, -1.6), Color("4f9a3e"))
	LifeRoomKit.cylinder(scenery(), "Pot", 0.18, 0.3, Vector3(-1.5, 0.15, -1.6), Color("c0563a"))
	add_target("plant", plant, 0.35)
	var window := LifeRoomKit.box(self, "Window", Vector3(1.4, 1.0, 0.05), Vector3(0, 1.6, -2.44), Color("9fd8ff"))
	add_target("window", window, 0.55)
	for i in 3:
		clouds.append(LifeRoomKit.sphere(window, "Cloud", 0.12 + i * 0.03, Vector3(-0.4 + i * 0.4, 0.15 - i * 0.12, 0.04),
			Color.WHITE))
	var books := LifeRoomKit.box(self, "Books", Vector3(0.7, 0.3, 0.25), Vector3(1.4, 1.1, -1.7), Color("3a7be8"))
	LifeRoomKit.box(scenery(), "Shelf", Vector3(0.9, 0.04, 0.3), Vector3(1.4, 0.93, -1.7), Color("a8642a"))
	add_target("books", books, 0.35)
	var cat := LifeRoomKit.box(self, "Cat", Vector3(0.4, 0.2, 0.25), Vector3(2.0, 0.35, -0.4), Color("f0a050"))
	LifeRoomKit.box(cat, "Ears", Vector3(0.12, 0.08, 0.2), Vector3(0.16, 0.13, 0), Color("f0a050"))
	LifeRoomKit.box(scenery(), "CatBed", Vector3(0.6, 0.2, 0.45), Vector3(2.0, 0.1, -0.4), Color("8b6fd6"))
	add_target("cat", cat, 0.3)
	var clock := LifeRoomKit.cylinder(self, "Clock", 0.2, 0.04, Vector3(0.95, 2.0, -2.44), Color.WHITE)
	clock.rotation.x = PI / 2
	add_target("clock", clock, 0.28)
	var fish := LifeRoomKit.sphere(self, "FishBowl", 0.16, Vector3(-0.9, 0.95, -1.9), Color(0.75, 0.9, 1.0, 0.6))
	LifeRoomKit.box(fish, "Fish", Vector3(0.08, 0.04, 0.02), Vector3(0.02, 0, 0), Color("ff8a3d"))
	LifeRoomKit.box(scenery(), "FishTable", Vector3(0.4, 0.8, 0.4), Vector3(-0.9, 0.4, -1.9), Color("a8642a"))
	add_target("fish", fish, 0.28)


func _buddies() -> void:
	bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
	bobo.position = Vector3(0, 0, -0.2)
	add_child(bobo)
	mo = LifeBuddy.new(Color("ffb347"), "Mo")
	mo.position = Vector3(-0.85, 0, -0.5)
	mo.rotation.y = 0.4
	mo.visible = false
	add_child(mo)
	pip = LifeBuddy.new(Color("e85a9a"), "PipPop")
	pip.position = Vector3(1.3, 0, -0.9)
	pip.rotation.y = -0.4
	pip.visible = false
	add_child(pip)
	tower = Node3D.new()
	tower.name = "Tower"
	tower.position = Vector3(0.45, 0, -0.1)
	add_child(tower)
	for i in 4:
		LifeRoomKit.box(tower, "Block", Vector3(0.14, 0.14, 0.14), Vector3(0, 0.07 + i * 0.14, 0), [Color("e8544e"),
			Color("ffd23f"), Color("3fbf5a"), Color("3a7be8")][i])
	ball = LifeRoomKit.sphere(self, "Ball", 0.13, Vector3(-0.4, 0.13, -0.35), Color("ffb02e"))
	ball.visible = false


func _breathing() -> void:
	balloon = LifeRoomKit.sphere(self, "Balloon", 0.14, Vector3(0.32, 1.0, 0.85), Color("8b6fd6"))
	LifeRoomKit.box(scenery(), "BalloonString", Vector3(0.006, 0.4, 0.006), Vector3(0.32, 0.7, 0.85), Color("1f2a4a"))
	add_target("balloon", balloon, 0.2)


func _worry_box() -> void:
	LifeRoomKit.box(scenery(), "LowTable", Vector3(0.5, 0.4, 0.4), Vector3(0.5, 0.2, 0.6), Color("a8642a"))
	var box := LifeRoomKit.box(self, "WorryBox", Vector3(0.28, 0.2, 0.22), Vector3(0.5, 0.5, 0.6), Color("e8b04a"))
	LifeRoomKit.box(box, "Slot", Vector3(0.14, 0.01, 0.03), Vector3(0, 0.1, 0), Color("6b4a2a"))
	LifeRoomKit.sign(box, "WorryWord", "WORRY BOX", Vector3(0, 0.2, 0.12), 0.0022)
	add_target("worry_box", box, 0.18)
	worry_card = LifeRoomKit.box(self, "WorryCard", Vector3(0.12, 0.01, 0.08), Vector3(0.3, 0.72, 0.85), Color.WHITE)
	worry_card.visible = false


## The calm toolbox's picture cards on a low shelf (shown only for its step: it stands in front of the stories).
func _toolbox() -> void:
	toolbox = Node3D.new()
	toolbox.name = "Toolbox"
	toolbox.visible = false
	add_child(toolbox)
	LifeRoomKit.box(toolbox, "ToolShelf", Vector3(1.7, 0.05, 0.3), Vector3(0, 0.62, 0.55), Color("a8642a"))
	for i in TOOLS.size():
		var at := Vector3(-0.7 + i * 0.28, 0.75, 0.55)
		var card := LifeRoomKit.box(toolbox, TOOLS[i], Vector3(0.22, 0.22, 0.02), at, Color("fdfdf8"))
		card.rotation.x = -0.4
		var word := LifeRoomKit.sign(card, "Word", str(TOOL_WORDS[TOOLS[i]]), Vector3(0, 0, 0.02), 0.0016, Color("1f2a4a"))
		word.outline_size = 0
		add_target(TOOLS[i], card, 0.12)


## The tablet on its stand (shown only for its steps, like the toolbox).
func _tablet() -> void:
	tablet_stand = Node3D.new()
	tablet_stand.name = "TabletStand"
	tablet_stand.visible = false
	add_child(tablet_stand)
	LifeRoomKit.box(tablet_stand, "Stand", Vector3(0.05, 0.6, 0.05), Vector3(0, 0.62, 0.62), Color("6b7380"))
	var tablet := LifeRoomKit.box(tablet_stand, "Tablet", Vector3(0.62, 0.42, 0.03), Vector3(0, 1.08, 0.62), Color("1f2a4a"))
	tablet.rotation.x = -0.25
	screen = LifeRoomKit.sign(tablet, "Screen", "", Vector3(0, 0.06, 0.03), 0.0018)
	var block := LifeRoomKit.box(tablet, "Block", Vector3(0.16, 0.07, 0.02), Vector3(-0.15, -0.14, 0.02), Color("6b7a99"))
	var block_word := LifeRoomKit.sign(block, "Word", "BLOCK", Vector3(0, 0, 0.02), 0.0016)
	block_word.outline_size = 6
	add_target("block", block, 0.09)
	var report := LifeRoomKit.box(tablet, "Report", Vector3(0.16, 0.07, 0.02), Vector3(0.15, -0.14, 0.02), Color("3a7be8"))
	var report_word := LifeRoomKit.sign(report, "Word", "REPORT", Vector3(0, 0, 0.02), 0.0016)
	report_word.outline_size = 6
	add_target("report", report, 0.09)


func _views() -> void:
	add_view("rug", Vector3(0, 1.25, 2.3), Vector3(0, 0.7, -0.2), Vector3(0, 0, 1.4), 0.0)
	add_view("balloon", Vector3(0, 1.3, 2.15), Vector3(0.25, 0.95, 0.5), Vector3(0, 0, 1.4), 0.0)
	add_view("room", Vector3(0, 1.5, 2.6), Vector3(0, 1.0, -1.0), Vector3(0, 0, 1.4), 0.0)
	add_view("worry", Vector3(0.1, 1.2, 1.9), Vector3(0.45, 0.55, 0.6), Vector3(0, 0, 1.4), 0.0)
	add_view("toolbox", Vector3(0, 1.3, 1.85), Vector3(0, 0.7, 0.45), Vector3(0, 0, 1.4), 0.0)
	add_view("tablet", Vector3(0, 1.3, 1.75), Vector3(0, 1.0, 0.55), Vector3(0, 0, 1.4), 0.0)


func _process(delta: float) -> void:
	super(delta)
	_cloud_t += delta
	for i in clouds.size():
		clouds[i].position.x = -0.5 + fmod(_cloud_t * 0.03 + i * 0.4, 1.0)


# --- Events and progress ---------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"bobo_sad":
			LifeRoomPeople.feel(bobo, "sad")
			_tumble_tower()
		"bobo_calm":
			LifeRoomPeople.feel(bobo, "calm")
		"story_left_out":
			_show_story([bobo, mo], "happy")
			ball.visible = true
			pip.visible = true
			LifeRoomPeople.feel(pip, "sad")
		"pip_joins":
			pip.visible = true
			_move(pip, Vector3(0.45, 0, -0.45))
			for b: LifeBuddy in [bobo, mo, pip]:
				LifeRoomPeople.feel(b, "happy")
		"story_cant_play":
			_show_story([mo], "cross")
			mo.rotation.y = 0.0
		"story_quarrel":
			_show_story([bobo, mo], "cross")
			ball.visible = true
			ball.position = Vector3(-0.42, 0.13, -0.3)
		"quarrel_solved":
			LifeRoomPeople.feel(bobo, "happy")
			LifeRoomPeople.feel(mo, "happy")
		"story_unkind":
			_show_story([mo], "cross")
			pip.visible = true
			LifeRoomPeople.feel(pip, "sad")
		"tablet_unkind":
			screen.text = "NEW MESSAGE\n(a mean comment)\n:("
		"story_pressure":
			screen.text = "\"Share this photo of Mo!\"\n[ a silly photo ]\nSHARE?"
		"group_laughs":
			screen.text = "GROUP CHAT\nhaha  haha  haha\n\"add a joke!\""
		"worry_in":
			worry_card.visible = false


func _show_story(who: Array, feeling: String) -> void:
	for b: LifeBuddy in [bobo, mo, pip]:
		b.visible = who.has(b) or b == bobo
	for b: LifeBuddy in who:
		b.visible = true
		LifeRoomPeople.feel(b, feeling)


func _tumble_tower() -> void:
	var i := 0
	for block: Node in tower.get_children():
		(block as Node3D).position = Vector3(-0.1 + i * 0.16, 0.07, 0.1 * (i % 2))
		(block as Node3D).rotation.y = 0.4 * i
		i += 1


func _move(b: Node3D, to: Vector3) -> void:
	if is_inside_tree() and not UiMotion.calm():
		create_tween().tween_property(b, "position", to, 0.9).set_trans(Tween.TRANS_SINE)
	else:
		b.position = to


func step_started(step: Dictionary) -> void:
	var v := str(step.get("view", start_view))
	toolbox.visible = v == "toolbox"
	tablet_stand.visible = v == "tablet"
	if str(step.get("id", "")) == "box":
		worry_card.visible = true   # the worry, picked, in the child's hand to put away


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"breathe":   # the balloon grows on the breath in and shrinks on the breath out
			var t := float(state.get("t", 0.0))
			var s := 1.0
			match str(state.get("phase", "")):
				"in":
					s = 1.0 + 0.8 * clampf(t / float(step.get("in", 3.0)), 0.0, 1.0)
				"out":
					s = 1.8 - 0.8 * clampf(t / float(step.get("out", 3.0)), 0.0, 1.0)
			balloon.scale = Vector3.ONE * s
		"find":
			for f: Variant in state.get("found", []):
				if found_rings.has(f) or not has_target(str(f)):
					continue
				found_rings[f] = LifeRoomKit.sphere(self, "Seen", 0.06, to_local(target_position(str(f))) + Vector3(0, 0.32, 0),
					Color(0.3, 0.85, 0.4, 0.9))


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A quiet, cosy room: a white rail and a skirting round the lilac walls, a ceiling with a soft round light, warm little
## lights along the back wall, an armchair with a blanket and a beanbag in the corners, a second plant, calm pictures,
## stars on the side wall, a front wall with its door behind the child. Never over the five things to see, the rug, the
## worry box or a view's line.
func _calm_look() -> void:
	var d := decor()
	d.sky(Color("8fb8e6"), Color("e6eefa"), Color("9cc87a"))
	d.box("Garden", Vector3(70, 0.1, 70), Vector3(0, -0.16, 0), Color("9cc87a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(6.0, 0.1, 5.5), Vector3(0, 2.85, 0.0), Color("f8f4fc"), 0.8)
	d.ceiling_light("Light", Vector3(0, 2.78, 0.4), 0.34)
	for w: Array in [[Vector3(-3.0, 0, -2.45), Vector3(3.0, 0, -2.45)], [Vector3(-2.94, 0, -2.5), Vector3(-2.94, 0, 2.7)],
			[Vector3(2.94, 0, -2.5), Vector3(2.94, 0, 2.7)]]:
		d.skirting("Skirting", w[0], w[1], Color("fdfdf8"), 0.1)
	d.box("Rail", Vector3(6.0, 0.04, 0.03), Vector3(0, 0.95, -2.44), Color("fdfdf8"), 0.0, LifeRoomDecor.SHELL)
	d.box("Wainscot", Vector3(6.0, 0.93, 0.02), Vector3(0, 0.47, -2.445), Color("c7b6ea"), 0.0, LifeRoomDecor.SHELL)
	for x: float in [-2.945, 2.945]:
		d.box("Wainscot", Vector3(0.02, 0.93, 5.2), Vector3(x, 0.47, 0.1), Color("c7b6ea"), 0.0, LifeRoomDecor.SHELL)
	for x: float in [-2.94, 2.94]:
		d.box("Rail", Vector3(0.03, 0.04, 5.2), Vector3(x, 0.95, 0.1), Color("fdfdf8"), 0.0, LifeRoomDecor.SHELL)
	# warm little lights along the back wall's top
	for i in 15:
		var x := -2.8 + i * 0.4
		if absf(x - 1.75) < 1.05:
			continue   # never over CALM CORNER's words
		d.glow_box("FairyLight", Vector3(0.05, 0.05, 0.05), Vector3(x, 2.55 - 0.06 * sin(i * 1.3) - 0.04 * float(i % 2), -2.42),
			Color("ffe4a0") if i % 3 else Color("ffc6d8"))
	# the corners: an armchair with a blanket (left front), a beanbag (right front)
	d.box("ArmchairSeat", Vector3(0.8, 0.4, 0.75), Vector3(-2.4, 0.2, 1.4), Color("8fc7b8"))
	d.box("ArmchairBack", Vector3(0.18, 0.7, 0.75), Vector3(-2.75, 0.65, 1.4), Color("7fb8a8"))
	for z: float in [1.0, 1.8]:
		d.box("ArmchairArm", Vector3(0.8, 0.25, 0.14), Vector3(-2.4, 0.5, z), Color("7fb8a8"))
	d.box("Blanket", Vector3(0.5, 0.05, 0.6), Vector3(-2.3, 0.43, 1.4), Color("ffc93c"))
	d.ball("Beanbag", 0.42, Vector3(2.35, 0.3, 1.5), Color("f39a3c"), Vector3(1.0, 0.7, 1.0))
	d.plant("Plant", Vector3(2.6, 0, -2.15), 1.2, Color("8b6fd6"))
	for side: int in [-1, 1]:   # a frame and a sill round the window (its clouds drift by)
		d.box("WindowFrame", Vector3(0.07, 1.12, 0.06), Vector3(side * 0.735, 1.6, -2.42), Color("fdfdf8"))
		d.box("WindowFrame", Vector3(1.54, 0.07, 0.06), Vector3(0, 1.6 + side * 0.535, -2.42), Color("fdfdf8"))
	d.box("WindowSill", Vector3(1.7, 0.05, 0.16), Vector3(0, 1.03, -2.38), Color("f3ede4"))
	d.picture("Picture", Vector3(-2.94, 1.7, -0.9), Vector2(0.6, 0.45), PI / 2, Color("b9a6e8"), Color("fff6e0"), 2)
	d.picture("Picture", Vector3(2.94, 1.65, 0.3), Vector2(0.5, 0.6), -PI / 2, Color("8fc7b8"), Color("fff6e0"), 1)
	for k in 5:   # stars on the right wall
		d.glow_box("Star", Vector3(0.02, 0.08, 0.08), Vector3(2.94, 2.1 + 0.15 * sin(k * 2.1), -1.4 + k * 0.42), Color("fff1b8"))
	d.box("FrontWall", Vector3(2.4, 2.8, 0.1), Vector3(-1.8, 1.4, 2.75), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("FrontWall", Vector3(2.4, 2.8, 0.1), Vector3(1.8, 1.4, 2.75), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("FrontWallTop", Vector3(1.2, 0.7, 0.1), Vector3(0, 2.45, 2.75), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("Door", Vector3(1.0, 2.05, 0.05), Vector3(0, 1.03, 2.78), Color("c89a62"))
