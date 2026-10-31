class_name FirstAidRoom
extends LifeRoom
## Owner #112 (docs/design/life-skills.md §5 #1, §6): Little Lifesaver's practice room: a bright training room with soft
## blue mats, a low training table, a side table with the play phone and the first aid kit, a sink, and a green-cross
## poster. Little: Bobo the buddy sits on the floor after a slip, the play phone's big keys dial the region's number,
## and a helper buddy comes in at the end. Middle: Bobo sits on a stool with two soft "ouch" spots (never a wound),
## goes to the sink for the burn's cool water, and lies on the table for the recovery position. Big: Max, the training
## dummy, lies on the table (CPR), an AED arrives on the Expert try, and Lulu the buddy practises choking.
## The child stands on the +Z side facing -Z.

const WALL := Color("f3ead8")
const FLOOR := Color("c9d6e3")
const MAT := Color("5a8fd6")
const TABLE := Color("d9c6a5")
const WOOD := Color("a8642a")
const KIT := Color("2fae4e")
const HELD := Vector3(0, 1.0, 0.95)   # the phone in front of the child, big

var bobo: LifeBuddy
var lulu: LifeBuddy
var helper: LifeBuddy
var max_dummy: LifeDummy
var phone: Node3D
var phone_screen: Label3D
var water: MeshInstance3D
var aed: Node3D
var cough_words: Label3D


func build() -> void:
	name = "FirstAidRoom"
	env = LifeRoomKit.environment(Color("9fd0f2"), Color("eef6fc"), 0.65)
	_shell()
	_tables()
	_phone()
	match track:
		"middle":
			_middle()
		"big":
			_big()
		_:
			_little()
	for b: LifeBuddy in [bobo, lulu]:   # the Quest's draws: Bobo and Lulu move their arms and legs, so part by part
		if b != null:
			LifeRoomPeople.merge_person(b)
	if helper != null:
		LifeRoomPeople.merge_person(helper, true)
	add_view("room", Vector3(0, 1.25, 1.7), Vector3(0, 0.5, -0.5), Vector3(0, 0, 1.2), 0.0)
	if track == "middle":   # Bobo on the stool, to the left
		add_view("buddy", Vector3(-0.3, 1.0, 0.75), Vector3(-0.6, 0.6, -0.3), Vector3(-0.45, 0, 0.25), 0.0)
	else:   # Bobo sitting on the floor
		add_view("buddy", Vector3(0, 0.95, 0.85), Vector3(0, 0.45, -0.3), Vector3(0, 0, 0.2), 0.0)
	add_view("phone", Vector3(0, 1.15, 1.8), Vector3(0, 1.0, 0.95), Vector3(0, 0, 1.4), 0.0)
	add_view("sink", Vector3(1.0, 1.3, -0.1), Vector3(2.3, 0.9, -1.6), Vector3(1.85, 0, -1.15), atan2(-0.6, 0.45))
	add_view("mat", Vector3(0, 1.35, 0.55), Vector3(0, 0.45, -0.7), Vector3(0, 0, 0.05), 0.0)
	add_view("dummy", Vector3(0, 1.35, 0.6), Vector3(0, 0.45, -0.7), Vector3(0, 0, 0.05), 0.0)
	add_view("chest", Vector3(0.25, 1.05, 0.15), Vector3(-0.05, 0.55, -0.7), Vector3(0, 0, 0.05), 0.0)
	add_view("lulu", Vector3(0.5, 1.2, 0.95), Vector3(1.4, 0.75, -0.6), Vector3(1.4, 0, 0.15), 0.0)


func _shell() -> void:
	_room_look()   # the rooms' look (2026-10-18): the floor, the walls, the windows, the shelves and plants
	var sc := scenery()
	LifeRoomKit.box(sc, "Door", Vector3(1.0, 2.1, 0.06), Vector3(0, 1.05, 3.02), WOOD)
	LifeRoomKit.box(sc, "Mat", Vector3(2.6, 0.04, 1.8), Vector3(0, 0.02, -0.6), MAT)
	LifeRoomKit.box(sc, "Poster", Vector3(1.0, 1.0, 0.03), Vector3(-1.2, 1.6, -2.94), KIT)
	LifeRoomKit.box(sc, "PosterV", Vector3(0.18, 0.6, 0.035), Vector3(-1.2, 1.6, -2.93), Color.WHITE)
	LifeRoomKit.box(sc, "PosterH", Vector3(0.6, 0.18, 0.035), Vector3(-1.2, 1.6, -2.93), Color.WHITE)
	# painted high on the back wall like a banner, smaller (bigger and lower the first views cut it)
	var practice := LifeRoomKit.sign(self, "Practice", "PRACTICE ROOM", Vector3(1.0, 2.2, -2.93), 0.0034, Color("2f7f6a"))
	practice.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	practice.outline_size = 0
	LifeRoomKit.light(self, Vector3(0, 2.3, 0), 1.3, 8.0)
	LifeRoomKit.light(self, Vector3(1.8, 2.2, -1.8), 0.7, 5.0)


func _tables() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "Table", Vector3(1.6, 0.4, 0.8), Vector3(0, 0.2, -0.7), TABLE)
	LifeRoomKit.box(sc, "SideTable", Vector3(0.8, 0.7, 0.5), Vector3(-1.5, 0.35, -0.3), TABLE.darkened(0.08))
	LifeRoomKit.box(sc, "Cabinet", Vector3(0.8, 0.8, 0.6), Vector3(2.4, 0.4, -1.6), Color("e2e6ea"))
	LifeRoomKit.box(sc, "Basin", Vector3(0.6, 0.06, 0.45), Vector3(2.4, 0.83, -1.6), Color("b9c4cf"))
	var tap := LifeRoomKit.cylinder(self, "Tap", 0.03, 0.22, Vector3(2.62, 0.97, -1.6), Color("9aa7b5"))
	LifeRoomKit.box(tap, "Spout", Vector3(0.16, 0.03, 0.03), Vector3(-0.08, 0.1, 0), Color("9aa7b5"))
	add_target("tap", tap, 0.09)
	water = LifeRoomKit.cylinder(self, "Water", 0.025, 0.14, Vector3(2.48, 0.95, -1.6), Color(0.55, 0.8, 1.0, 0.6))
	water.visible = false
	add_target("water", water, 0.12)


func _phone() -> void:
	phone = Node3D.new()
	phone.name = "Phone"
	phone.position = Vector3(-1.45, 0.72, -0.3)
	add_child(phone)
	LifeRoomKit.box(phone, "Body", Vector3(0.16, 0.03, 0.28), Vector3.ZERO, Color("1f2a4a"))
	LifeRoomKit.box(phone, "Glass", Vector3(0.13, 0.035, 0.22), Vector3(0, 0.002, 0), Color("9fd8ff"))
	add_target("phone", phone, 0.15)
	if track == "little":
		phone_screen = make_held_phone(Transform3D(Basis(), HELD))


## The play phone up in front of the child, big, its keys facing them, ready to dial (built hidden in _phone).
func _hold_phone() -> void:
	phone.visible = false
	(get_node("HeldPhone") as Node3D).visible = true


func _little() -> void:
	bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
	bobo.position = Vector3(0, 0, -0.2)
	add_child(bobo)
	bobo.pose("sit_floor")
	add_target("buddy_shoulder", bobo.mark("shoulder"), 0.13)
	add_target("buddy_hand", bobo.mark("near_hand"), 0.12)
	helper = LifeBuddy.new(Color("2f7f6a"), "Helper")
	helper.position = Vector3(0.4, 0, 2.6)
	helper.visible = false
	add_child(helper)


func _middle() -> void:
	LifeRoomKit.box(scenery(), "Stool", Vector3(0.4, 0.44, 0.4), Vector3(-0.6, 0.22, -0.3), WOOD)
	bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
	bobo.position = Vector3(-0.6, 0, -0.3)
	add_child(bobo)
	bobo.pose("sit")
	bobo.show_ouch("cut")
	bobo.show_ouch("cut2")
	bobo.show_ouch("near_hand")
	var kit := Vector3(-1.5, 0.72, -0.3)
	add_target("gloves", LifeRoomKit.box(self, "Gloves", Vector3(0.14, 0.06, 0.1), kit + Vector3(-0.25, 0.03, 0), Color("8fd3ff")), 0.12)
	add_target("cloth", LifeRoomKit.box(self, "Cloth", Vector3(0.16, 0.03, 0.14), kit + Vector3(0, 0.015, 0.12), Color.WHITE), 0.12)
	add_target("plaster", LifeRoomKit.box(self, "Plaster", Vector3(0.12, 0.02, 0.05), kit + Vector3(0.25, 0.01, 0.1), Color("f3d2a8")), 0.11)
	add_target("cling_film", LifeRoomKit.cylinder(self, "ClingFilm", 0.035, 0.22, Vector3(2.1, 0.89, -1.35), Color(0.85, 0.95, 1.0, 0.9)), 0.12)
	LifeRoomKit.box(scenery(), "KitBox", Vector3(0.2, 0.12, 0.14), kit + Vector3(0.05, 0.06, -0.12), KIT)
	add_target("cut", bobo.mark("cut"), 0.09)
	add_target("cut2", bobo.mark("cut2"), 0.09)
	add_target("near_arm", bobo.mark("near_arm"), 0.12)
	add_target("far_hand", bobo.mark("far_hand"), 0.12)
	add_target("far_knee", bobo.mark("far_knee"), 0.13)
	add_target("chin", bobo.mark("chin"), 0.1)


func _big() -> void:
	phone.position = Vector3(0.62, 0.42, -0.42)   # beside Max: the phone on speaker, hands free
	max_dummy = LifeDummy.new()
	max_dummy.position = Vector3(0.05, 0.4, -0.7)
	add_child(max_dummy)
	add_target("dummy_shoulders", max_dummy.mark("shoulders"), 0.18)
	add_target("dummy_face", max_dummy.mark("face"), 0.16)
	add_target("chest", max_dummy.mark("chest"), 0.14)
	lulu = LifeBuddy.new(Color("e85a9a"), "Lulu")
	lulu.position = Vector3(1.4, 0, -0.6)
	lulu.rotation.y = PI   # the back to the child
	lulu.visible = false
	add_child(lulu)
	add_target("lulu_back", lulu.mark("back"), 0.15)
	add_target("lulu_tummy", lulu.mark("tummy"), 0.15)
	aed = Node3D.new()
	aed.name = "AED"
	aed.position = Vector3(0.7, 0.42, -0.2)
	aed.visible = false
	add_child(aed)
	LifeRoomKit.box(aed, "Case", Vector3(0.26, 0.08, 0.2), Vector3(0, 0.04, 0), KIT)
	var word := LifeRoomKit.sign(aed, "Word", "AED", Vector3(0, 0.1, 0.0), 0.003, Color.WHITE, 0.0)
	word.rotation.x = -PI / 2


func on_event(event: String) -> void:
	match event:
		"buddy_fallen":
			if bobo:
				bobo.pose("sit_floor")
		"helper_comes":
			if helper:
				helper.visible = true
				if is_inside_tree() and not UiMotion.calm():
					var tw := create_tween()
					tw.tween_property(helper, "position", Vector3(0.6, 0, 0.4), 1.2)
					tw.tween_callback(helper.nod)
				else:
					helper.position = Vector3(0.6, 0, 0.4)
		"buddy_sitting":
			if bobo:
				bobo.basis = Basis()
				bobo.position = Vector3(-0.6, 0, -0.3)
				bobo.pose("sit")
		"to_sink":
			if bobo:
				bobo.pose("stand")
				bobo.position = Vector3(1.95, 0, -1.05)
				bobo.rotation.y = -PI * 0.75
				bobo.arm_near.rotation = Vector3(-1.2, 0, 0)
		"buddy_lying":
			if bobo:
				bobo.show_ouch("")
				bobo.rotation = Vector3.ZERO
				bobo.position = Vector3(0.5, 0.51, -0.7)
				bobo.pose("lie")
		"arm_out":
			bobo.arm_out()
		"hand_cheek":
			bobo.hand_cheek()
		"knee_up":
			bobo.knee_up()
		"roll_side":
			bobo.roll_side()
		"head_tilt":
			bobo.head_tilt()
		"aed_arrives":
			if aed:
				aed.visible = true
		"lulu_coughing":
			if lulu:
				lulu.visible = true
				_cough(true)
		"lulu_stuck":
			if lulu:
				_cough(false)
				lulu.arm_near.rotation = Vector3(-2.4, 0, 0.3)
				lulu.arm_far.rotation = Vector3(-2.4, 0, -0.3)
		"lulu_clear":
			if lulu:
				lulu.arm_near.rotation = Vector3.ZERO
				lulu.arm_far.rotation = Vector3.ZERO
				lulu.nod()


func _cough(on: bool) -> void:
	if cough_words == null and lulu != null:
		cough_words = LifeRoomKit.sign(self, "Cough", "cough, cough", lulu.position + Vector3(0, 1.35, 0.2), 0.004,
			Color("fdfdf8"))
	if cough_words:
		cough_words.visible = on


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"phone":
			if track == "little":
				_hold_phone()
			elif phone_screen == null:
				phone_screen = LifeRoomKit.sign(phone, "Speaker", "SPEAKER ON", Vector3(0, 0.08, 0), 0.0025)
		"tap":
			water.visible = true
		"dial":
			if phone_screen:
				phone_screen.text = "CALLING..."
		"press", "press2", "plaster":
			if bobo:
				bobo.nod()


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"sequence":
			if phone_screen:
				phone_screen.text = LifeRoom.dialled(step, state)
		"rhythm":
			if max_dummy:
				max_dummy.push()
		"taps":
			if lulu:
				lulu.nod()


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A bright training room: a pale plank floor, walls of soft mint below a rail and warm cream above with a skirting, the
## ceiling with its lights, two windows on the left wall over a garden, a bookshelf and plants in the corners, a clock,
## pictures, a bench and coat hooks by the door; a sky outside the windows. Never near the mats, the tables, the sink or
## a view's line.
func _room_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Garden", Vector3(70, 0.1, 70), Vector3(0, -0.16, 0), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(6, 0.1, 6), Vector3(0, -0.05, 0), Color("f7e9d6"), 0.75)
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(6, 0.1, 6), Vector3(0, 2.65, 0), Color("fbf8f2"), 0.75)
	for w: Array in [[Vector3(6, 0, 0.1), Vector3(0, 0, -3)], [Vector3(0.1, 0, 6), Vector3(-3, 0, 0)],
			[Vector3(0.1, 0, 6), Vector3(3, 0, 0)], [Vector3(2.5, 0, 0.1), Vector3(-1.75, 0, 3)], [Vector3(2.5, 0, 0.1), Vector3(1.75, 0, 3)]]:
		var size: Vector3 = w[0]
		var at: Vector3 = w[1]
		d.box("WallLow", Vector3(size.x, 1.0, size.z), at + Vector3(0, 0.5, 0), Color("cfe9df"), 0.0, LifeRoomDecor.SHELL)
		d.box("Wall", Vector3(size.x, 1.6, size.z), at + Vector3(0, 1.8, 0), WALL, 0.0, LifeRoomDecor.SHELL)
		d.box("Rail", Vector3(size.x + 0.03, 0.05, size.z + 0.03), at + Vector3(0, 1.02, 0), Color("fdfdf8"), 0.0, LifeRoomDecor.SHELL)
		d.box("Skirting", Vector3(size.x + 0.03, 0.1, size.z + 0.03), at + Vector3(0, 0.05, 0), Color("b98450"), 0.0, LifeRoomDecor.SHELL)
	d.ceiling_light("Light", Vector3(-0.9, 2.57, -0.6), 0.3)
	d.ceiling_light("Light", Vector3(0.9, 2.57, -0.6), 0.3)
	d.ceiling_light("Light", Vector3(0, 2.57, 1.6), 0.3)
	d.window("Window", Vector3(-2.93, 1.55, -1.6), 1.0, 1.0, PI / 2)
	d.window("Window", Vector3(-2.93, 1.55, 1.4), 1.0, 1.0, PI / 2)
	d.shelf("Shelf", Vector3(-2.2, 0, -2.78), 1.0, 1.5, 0.0, Color("c89a62"), 3)
	d.plant("Plant", Vector3(-2.65, 0, 2.55), 1.4)
	d.plant("Plant", Vector3(2.6, 0, 2.55), 1.2, Color("3a7be8"))
	d.plant("Plant", Vector3(2.65, 0, -2.65), 1.1, Color("e8b04a"))
	d.picture("Picture", Vector3(2.93, 1.65, 0.4), Vector2(0.7, 0.5), -PI / 2, Color("8a6239"), Color("fff6e0"), 0)
	d.picture("Picture", Vector3(2.93, 1.6, 1.6), Vector2(0.5, 0.6), -PI / 2, Color("3a7be8"), Color("fff6e0"), 1)
	d.box("Clock", Vector3(0.36, 0.36, 0.04), Vector3(-0.6, 2.15, -2.93), Color("fdfdf8"))   # clear of PRACTICE ROOM
	d.box("ClockRim", Vector3(0.42, 0.42, 0.03), Vector3(-0.6, 2.15, -2.95), Color("3a7be8"))
	d.box("ClockHand", Vector3(0.02, 0.14, 0.01), Vector3(-0.6, 2.2, -2.9), Color("1f2a4a"))
	d.box("ClockHand", Vector3(0.1, 0.02, 0.01), Vector3(-0.56, 2.15, -2.9), Color("1f2a4a"))
	d.bench("Bench", Vector3(2.5, 0, 1.2), -PI / 2, 1.2, Color("c89a62"))
	for x: float in [-1.0, -0.75]:
		d.box("Hook", Vector3(0.05, 0.05, 0.12), Vector3(x, 1.7, 2.9), Color("8a6239"))
	d.box("Coat", Vector3(0.28, 0.5, 0.08), Vector3(-1.0, 1.42, 2.88), Color("e8544e"))
