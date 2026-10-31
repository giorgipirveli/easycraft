class_name GoalRoom
extends LifeRoom
## Owner #115 (docs/design/success-skills.md §2.6): the Goal Board's practice room, a bright playroom. The Goal Board on
## the back wall (the dream's rocket, the GOAL and PLAN spaces, the step cards: in a mixed order on the board, so the
## child thinks which comes first; a card touched moves to its place in the plan's row), Bobo's blocks on a mat (they
## stack, wobble down gently and stack again), the saving jar on a little table (each coin lands in it), the habit plant
## by the window with its watering can (it grows on every kept day, never shrinks), the week's calendar on the wall
## (Wednesday's cloud: the day forgotten), and on the Big track the time jar (the big rocks first, then pebbles, then
## sand). Everything is soft and calm; nothing falls hard.

const WALL := Color("f4ecdc")
const FLOOR := Color("e8d8c0")
const BOARD := Color("c9a063")
const PAPER := Color("fdf6e3")
## The block's floor spots and its place in the tower.
const BLOCKS := {"block_big": [Vector3(0.45, 0.16, -0.85), 0.32, Color("e8544e")],
	"block_mid": [Vector3(1.05, 0.12, -0.7), 0.24, Color("3a7be8")],
	"block_small": [Vector3(1.25, 0.09, -1.1), 0.18, Color("ffc93c")]}
const TOWER_AT := Vector3(0.8, 0.0, -1.3)
const JAR_AT := Vector3(-0.9, 0.97, -1.1)
const PLANT_AT := Vector3(-1.6, 0.86, -1.6)
## The board's step cards: [id, words, x on the board] (mixed on purpose).
const MIDDLE_CARDS := [["card_build", "BUILD THE ROCKET", -0.9], ["card_learn", "LEARN A LESSON", -0.3],
	["card_buy", "BUY THE PARTS", 0.3], ["card_save", "SAVE GOLD", 0.9]]
const BIG_CARDS := [["card_plan", "PLAN", -0.9], ["card_wish", "WISH", -0.3], ["card_obstacle", "OBSTACLE", 0.3],
	["card_outcome", "OUTCOME", 0.9]]
const BOARD_Z := -2.36
const CARD_Y := 1.12
const ROW_Y := 0.76

var bobo: LifeBuddy
var blocks := {}
var jar_coins: Array[MeshInstance3D] = []
var plant: Node3D
var plant_stage := 0
var days := {}
var cards := {}
var rocks := {}
var slots := {}
var cloud: Label3D


func build() -> void:
	name = "GoalRoom"
	env = LifeRoomKit.environment(Color("cfe6f7"), Color("f6f1e6"), 0.75)
	start_view = "board" if track != "little" else "room"
	_room_look()   # the rooms' look (2026-10-18): a bright playroom
	LifeRoomKit.light(self, Vector3(0, 2.6, -0.6), 0.55, 8.0)
	sun(Color(1.0, 0.95, 0.86), 0.8)   # indoors: a softer key light
	# high on the back wall, smaller (lower it sat half under the HUD's bar in the board's view)
	var room_sign := LifeRoomKit.sign(self, "RoomSign", "THE GOAL ROOM", Vector3(-1.3, 2.82, -2.38), 0.0034, Color("2f7f6a"))
	room_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on the wall (turned to the eye, it sank into the wall)
	_board()
	_jar()
	_plant()
	_calendar()
	if track == "little":
		_blocks()
	if track == "big":
		_time_jar()
	add_view("room", Vector3(0, 1.5, 1.0), Vector3(0, 1.0, -1.8), Vector3(0, 0, 0), 0.0)
	add_view("board", Vector3(0, 1.5, 0.5), Vector3(0, 1.38, -2.4), Vector3(0, 0, -0.6), 0.0)
	add_view("blocks", Vector3(0.3, 1.3, 0.4), Vector3(0.9, 0.25, -1.2), Vector3(0.35, 0, -0.25), atan2(-0.55, 1.0))
	add_view("jar", Vector3(-0.45, 1.35, 0.2), Vector3(-0.9, 0.95, -1.1), Vector3(-0.5, 0, -0.35), atan2(0.4, 0.75))
	add_view("plant", Vector3(-0.7, 1.4, -0.2), Vector3(-1.55, 0.95, -1.6), Vector3(-1.05, 0, -0.85), atan2(0.55, 0.75))
	add_view("calendar", Vector3(0.9, 1.45, 0.3), Vector3(2.4, 1.35, -1.0), Vector3(1.3, 0, -0.95), -PI / 2)
	add_view("time_jar", Vector3(0.5, 1.35, 0.15), Vector3(0.9, 0.9, -1.2), Vector3(0.55, 0, -0.4), atan2(-0.35, 0.8))


func _board() -> void:
	LifeRoomKit.box(scenery(), "Board", Vector3(2.7, 1.6, 0.05), Vector3(0, 1.45, BOARD_Z - 0.02), BOARD)
	LifeRoomKit.sign(self, "BoardSign", "MY GOAL BOARD", Vector3(0, 2.38, BOARD_Z + 0.05), 0.004, Color.WHITE)
	var rocket := Node3D.new()
	rocket.name = "Dream"
	rocket.position = Vector3(0, 1.9, BOARD_Z + 0.04)
	add_child(rocket)
	LifeRoomKit.box(rocket, "Body", Vector3(0.12, 0.3, 0.04), Vector3.ZERO, Color.WHITE)
	LifeRoomKit.box(rocket, "Nose", Vector3(0.08, 0.08, 0.04), Vector3(0, 0.19, 0), Color("e8544e"))
	LifeRoomKit.sign(self, "DreamSign", "DREAM", Vector3(0, 1.62, BOARD_Z + 0.06), 0.0028, Color("1f2a4a"))
	rocket.visible = track != "little"
	for s: Array in [["slot_goal", "GOAL", -0.75], ["slot_plan", "PLAN", 0.75]]:
		var slot := LifeRoomKit.box(self, str(s[0]), Vector3(0.62, 0.36, 0.02), Vector3(float(s[2]), 1.78, BOARD_Z + 0.03),
			Color(1, 1, 1, 0.45))
		LifeRoomKit.sign(slot, "Label", str(s[1]), Vector3(0, 0.0, 0.02), 0.0032, Color("1f2a4a"))
		var card := LifeRoomKit.box(slot, "Card", Vector3(0.58, 0.32, 0.02), Vector3(0, 0, 0.02), PAPER)
		card.visible = false
		slots[s[0]] = card
		add_target(str(s[0]), slot, 0.3)
	var list: Array = MIDDLE_CARDS if track == "middle" else (BIG_CARDS if track == "big" else [])
	for c: Array in list:
		var card := LifeRoomKit.box(self, str(c[0]), Vector3(0.5, 0.26, 0.03), Vector3(float(c[2]), CARD_Y, BOARD_Z + 0.04), PAPER)
		var l := LifeRoomKit.sign(card, "Words", LifeRoomLook.two_lines(str(c[1])), Vector3(0, 0, 0.017), 0.0015, Color("1f2a4a"))
		l.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on the card (a billboard's words ran over its neighbours)
		l.outline_size = 0
		cards[c[0]] = card
		add_target(str(c[0]), card, 0.22)
	if not list.is_empty():
		LifeRoomKit.box(scenery(), "Row", Vector3(2.4, 0.03, 0.03), Vector3(0, ROW_Y - 0.17, BOARD_Z + 0.03), Color("6b4a2a"))


func _jar() -> void:
	LifeRoomKit.box(scenery(), "JarTable", Vector3(0.6, 0.8, 0.5), Vector3(JAR_AT.x, 0.4, JAR_AT.z), Color("a8642a"))
	var jar := LifeRoomKit.cylinder(self, "Jar", 0.12, 0.28, JAR_AT, Color(0.8, 0.92, 1.0, 0.6))
	LifeRoomKit.sign(jar, "Goal", "KITE" if track == "little" else "ROCKET", Vector3(0, 0.0, 0.13), 0.0024, Color("1f2a4a"))
	add_target("jar", jar, 0.18)


func _plant() -> void:
	LifeRoomKit.box(scenery(), "PlantTable", Vector3(0.6, 0.8, 0.5), Vector3(PLANT_AT.x, 0.4, PLANT_AT.z), Color("a8642a"))
	LifeRoomKit.cylinder(scenery(), "Pot", 0.12, 0.16, PLANT_AT + Vector3(0, 0.0, 0), Color("c0563a"))
	plant = Node3D.new()
	plant.name = "Plant"
	plant.position = PLANT_AT + Vector3(0, 0.08, 0)
	add_child(plant)
	add_spot_target("plant", self, PLANT_AT + Vector3(0, 0.12, 0), 0.22)
	var can := LifeRoomKit.box(self, "WateringCan", Vector3(0.16, 0.12, 0.1), PLANT_AT + Vector3(0.22, 0.02, 0.12), Color("5aa8e6"))
	LifeRoomKit.box(can, "Spout", Vector3(0.14, 0.03, 0.03), Vector3(0.12, 0.04, 0), Color("5aa8e6"))
	_grow(0)


## The plant at `stage` (SuccessHabits' stages: a seed ... a flower); it only ever grows.
func _grow(stage: int) -> void:
	plant_stage = maxi(plant_stage, stage)
	for c in plant.get_children():
		c.queue_free()
	if plant_stage <= 0:
		LifeRoomKit.sphere(plant, "Seed", 0.025, Vector3(0, 0.0, 0), Color("8b5a2b"))
		return
	var h := 0.05 + plant_stage * 0.045
	LifeRoomKit.cylinder(plant, "Stem", 0.012, h, Vector3(0, h * 0.5, 0), Color("4f9a3e"))
	for i in mini(plant_stage, 5):
		var side := -1.0 if i % 2 == 0 else 1.0
		LifeRoomKit.sphere(plant, "Leaf", 0.035, Vector3(side * 0.04, 0.04 + i * 0.045, 0), Color("62b04e"))
	if plant_stage >= 6:
		LifeRoomKit.sphere(plant, "Bud" if plant_stage == 6 else "Flower", 0.04 if plant_stage == 6 else 0.06,
			Vector3(0, h + 0.03, 0), Color("e85a9a") if plant_stage >= 7 else Color("7cc46a"))


func _calendar() -> void:
	LifeRoomKit.box(scenery(), "CalendarBoard", Vector3(0.04, 0.7, 1.8), Vector3(2.39, 1.4, -1.0), Color.WHITE)
	# painted on the wall at the calendar's far end (over its middle the first views' right edge cut it)
	var title := LifeRoomKit.sign(self, "CalendarSign", "MY WEEK", Vector3(2.35, 1.88, -1.86), 0.0021, Color("e8544e"))
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	title.rotation.y = -PI / 2
	var letters := ["M", "T", "W", "T", "F", "S", "S"]
	for i in 7:
		var at := Vector3(2.36, 1.38, -1.7 + i * 0.235)
		var d := LifeRoomKit.box(self, "day_%d" % (i + 1), Vector3(0.03, 0.2, 0.2), at, Color("e6e9ef"))
		# a little off the wall, a little smaller (bigger and closer, turned to the eye, it sank into the side wall)
		LifeRoomKit.sign(d, "Letter", letters[i], Vector3(-0.04, 0.15, 0), 0.0022, Color("1f2a4a"))
		days["day_%d" % (i + 1)] = d
		add_target("day_%d" % (i + 1), d, 0.12)
	cloud = LifeRoomKit.sign(self, "Cloud", "~", Vector3(2.33, 1.38, -1.7 + 2 * 0.235), 0.006, Color("9aa7b5"))
	cloud.visible = false


func _blocks() -> void:
	LifeRoomKit.box(scenery(), "Mat", Vector3(1.6, 0.02, 1.2), Vector3(0.85, 0.01, -1.05), Color("b9a6e8"))
	for id: String in BLOCKS:
		var b: Array = BLOCKS[id]
		var m := LifeRoomKit.box(self, id, Vector3.ONE * float(b[1]), b[0], b[2])
		blocks[id] = m
		add_target(id, m, maxf(float(b[1]) * 0.75, 0.16))
	bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
	bobo.position = Vector3(1.6, 0, -1.6)
	bobo.rotation.y = atan2(-1.2, 1.3)
	add_child(bobo)
	LifeRoomKit.sign(bobo, "Name", "BOBO", Vector3(0, 1.3, 0), SuccessCast.SIGN_PIXEL)
	LifeRoomPeople.merge_person(bobo, true)   # the Quest's draws: he never changes pose; faces through feel


func _time_jar() -> void:
	LifeRoomKit.box(scenery(), "JarTable2", Vector3(0.8, 0.8, 0.5), Vector3(0.9, 0.4, -1.2), Color("a8642a"))
	LifeRoomKit.cylinder(self, "TimeJar", 0.13, 0.32, Vector3(0.9, 0.96, -1.25), Color(0.8, 0.92, 1.0, 0.55))
	LifeRoomKit.sign(self, "TimeJarSign", "MY WEEK", Vector3(0.9, 1.22, -1.15), 0.0026, Color("1f2a4a"))
	for r: Array in [["rock_big", Vector3(0.6, 0.88, -1.05), 0.08, Color("7d8a99")],
			["rock_pebbles", Vector3(1.2, 0.86, -1.05), 0.05, Color("9aa7b5")],
			["rock_sand", Vector3(0.9, 0.84, -0.98), 0.045, Color("e8d39a")]]:
		var m := LifeRoomKit.sphere(self, str(r[0]), float(r[2]), r[1], r[3])
		rocks[r[0]] = m
		add_target(str(r[0]), m, 0.12)


func on_event(event: String) -> void:
	match event:
		"tower_falls":
			var i := 0
			for id: String in blocks:
				var m := blocks[id] as MeshInstance3D
				var at: Vector3 = BLOCKS[id][0] + Vector3(0.1 * (i - 1), 0, 0.12)
				_move(m, at, Vector3(0, 0.4 * (i - 1), 0.3))
				i += 1
			if bobo:
				LifeRoomPeople.feel(bobo, "sad")
		"tower_reset":
			for id: String in blocks:
				_move(blocks[id], BLOCKS[id][0], Vector3.ZERO)
			if bobo:
				LifeRoomPeople.feel(bobo, "calm")
		"bobo_dream":
			if bobo:
				LifeRoomPeople.feel(bobo, "happy")
				bobo.nod()
		"goal_pinned", "plan_pinned":
			var slot := "slot_goal" if event == "goal_pinned" else "slot_plan"
			(slots[slot] as Node3D).visible = true
		"plant_shows":
			_grow(1)
		"plant_watered":
			_grow(2)
		"days_pass":
			_grow(4)
			cloud.visible = true
		"week_starts":
			cloud.visible = true
			for id: String in days:
				(days[id] as MeshInstance3D).material_override = LifeRoomKit.material(Color("e6e9ef"))
		"month_passes":
			_grow(7)
			cloud.visible = true
			for i in 7:
				if i != 2:
					(days["day_%d" % (i + 1)] as MeshInstance3D).material_override = LifeRoomKit.material(Color("7cc46a"))


func progress(step: Dictionary, state: Dictionary) -> void:
	var kind := str(step.get("kind", ""))
	var id := str(step.get("id", ""))
	if kind == "sequence":
		var done := int(state.get("i", 0))
		var list: Array = step.get("targets", [])
		var y := 0.0
		for i in done:
			var t := str(list[i])
			if blocks.has(t):
				var size := float(BLOCKS[t][1])
				_move(blocks[t], TOWER_AT + Vector3(0, y + size * 0.5, 0), Vector3.ZERO)
				y += size
			elif cards.has(t):
				_move(cards[t], Vector3(-0.9 + i * 0.6, ROW_Y, BOARD_Z + 0.05), Vector3.ZERO)
			elif rocks.has(t):
				_move(rocks[t], Vector3(0.9, 0.86 + i * 0.07, -1.25), Vector3.ZERO)
	elif kind == "taps" and str(step.get("target", "")) == "jar":
		while jar_coins.size() < int(state.get("t", 0)):
			jar_coins.append(LifeRoomKit.cylinder(self, "Coin", 0.03, 0.012,
				JAR_AT + Vector3(0, -0.12 + jar_coins.size() * 0.014, 0), Color("ffc93c")))
	elif kind == "find" and id == "week":
		var found: Array = state.get("found", [])
		for d: Variant in found:
			if days.has(str(d)):
				(days[str(d)] as MeshInstance3D).material_override = LifeRoomKit.material(Color("7cc46a"))
		_grow(1 + found.size())


func step_done(step: Dictionary) -> void:
	if str(step.get("kind", "")) == "hold" and str(step.get("target", "")) == "plant":
		_grow(2)


func _move(n: Node3D, to: Vector3, rot: Vector3) -> void:
	if not is_instance_valid(n):
		return
	if UiMotion.calm() or not is_inside_tree():
		n.position = to
		n.rotation = rot
		return
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position", to, 0.4)
	tw.tween_property(n, "rotation", rot, 0.4)


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A bright playroom: a plank floor with a rug, warm walls with a rail and a skirting, a window over the garden, a ceiling
## with its lights, a toy shelf, beanbags and a plant, a front wall with its door behind
## the child. Never on the board, the blocks, the jar, the plant, the calendar or a view's line.
func _room_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Garden", Vector3(70, 0.1, 70), Vector3(0, -0.16, -0.4), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(6.0, 0.1, 5.6), Vector3(0, -0.05, -0.4), Color("f6e2c6"), 0.75)
	d.box("BackWall", Vector3(6.0, 3.0, 0.1), Vector3(0, 1.5, -2.45), WALL, 0.0, LifeRoomDecor.SHELL)
	for x: float in [-2.45, 2.45]:
		d.box("SideWall", Vector3(0.1, 3.0, 5.6), Vector3(x, 1.5, -0.4), WALL.darkened(0.03), 0.0, LifeRoomDecor.SHELL)
	d.box("Wainscot", Vector3(4.8, 0.9, 0.02), Vector3(0, 0.45, -2.395), Color("cfe0ee"), 0.0, LifeRoomDecor.SHELL)
	for x: float in [-2.395, 2.395]:
		d.box("Wainscot", Vector3(0.02, 0.9, 5.4), Vector3(x, 0.45, -0.3), Color("cfe0ee"), 0.0, LifeRoomDecor.SHELL)
		d.box("Rail", Vector3(0.03, 0.04, 5.4), Vector3(x, 0.92, -0.3), Color("fdfdf8"), 0.0, LifeRoomDecor.SHELL)
	d.box("Rail", Vector3(4.8, 0.04, 0.03), Vector3(0, 0.92, -2.39), Color("fdfdf8"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(6.0, 0.1, 5.7), Vector3(0, 3.05, -0.4), Color("fbf8f2"), 0.8)
	d.ceiling_light("Light", Vector3(-0.8, 2.98, -0.9), 0.3)
	d.ceiling_light("Light", Vector3(0.8, 2.98, -0.9), 0.3)
	d.window("Window", Vector3(-2.39, 1.6, -1.5), 1.0, 1.0, PI / 2)
	d.rug("Rug", Vector3(0, 0.0, 0.1), Vector2(2.2, 1.4), Color("f6e7a8"), Color("e8b04a"))
	d.shelf("ToyShelf", Vector3(1.85, 0, 0.9), 0.9, 0.9, -PI / 2, Color("c89a62"), 2)
	d.ball("Beanbag", 0.38, Vector3(-1.8, 0.27, 0.9), Color("3a7be8"), Vector3(1.0, 0.7, 1.0))
	d.plant("Plant", Vector3(-2.05, 0, -2.1), 1.1, Color("e8544e"))
	d.box("FrontWall", Vector3(1.9, 3.0, 0.1), Vector3(-1.5, 1.5, 2.45), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("FrontWall", Vector3(1.9, 3.0, 0.1), Vector3(1.5, 1.5, 2.45), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("FrontWallTop", Vector3(1.1, 0.95, 0.1), Vector3(0, 2.52, 2.45), WALL, 0.0, LifeRoomDecor.SHELL)
	d.box("Door", Vector3(1.0, 2.0, 0.05), Vector3(0, 1.0, 2.48), Color("c89a62"))
