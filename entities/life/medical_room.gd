class_name MedicalRoom
extends LifeRoom
## Owner #118 (docs/design/life-skills.md §14, the catalogue's row 10: medical emergencies; Life L3b): Medical
## Emergencies' practice places, built for the track: the practice room (Middle: Bobo on the bench with a nosebleed, Kiki
## on her chair with asthma, the table with the trainer inhaler and its spacer; Big: the floor mat where Bobo pretends to
## have a seizure, with the hard things round him, the sofa's cushion, a spoon on the side table and the stopwatch), the
## practice playground (Little and Middle: the slide where Lulu bumps her head, the tree's shade, a water bottle, Gus) and
## the picnic (Little: Mo's lips swell, the play phone; Big: Mo's allergy signs and the table with the trainer pen and its
## practice pad). Calm: no blood, never an injury: a nosebleed is a small soft red dot, an allergy a soft pink puffiness
## and rash, a seizure a gentle jerking of a buddy who is clearly pretending (his eyes shut, then sleepy). The safe
## mistakes' gentle pictures (on_mistake): a ghost of Bobo frozen with his head tipped back and a soft arrow down his
## throat; a spoon frozen near his mouth.

const FLOOR := Color("e8d8c0")
const WALL := Color("f3efe6")
const WOOD := Color("a8642a")
const WHITE := Color("f4f6f8")
const INK := Color("1f2a4a")
const GRASS := Color("8cc56a")
const SOFT_RED := Color(0.95, 0.55, 0.5, 0.9)
const PLAY := Vector3(30, 0, 0)
const PICNIC := Vector3(-30, 0, 0)

var bobo: LifeBuddy
var kiki: LifeBuddy
var lulu: LifeBuddy
var pip: LifeBuddy
var mo: LifeBuddy
var gus: LifeBuddy
var inhaler: Node3D
var spacer: Node3D
var bottle: MeshInstance3D
var pen_cap: MeshInstance3D
var cushion: MeshInstance3D
var phone: Node3D
var phone_screen: Label3D
var hard := {}
var seizing := false
var _t := 0.0


func build() -> void:
	name = "MedicalRoom"
	env = LifeRoomKit.environment(Color("cfe3f2"), Color("f3f6f9"), 0.75)
	start_view = "playground" if track == "little" else ("room" if track == "middle" else "picnic")
	_room()
	if track == "middle":
		_bench()
		_asthma()
	if track == "big":
		_seizure_corner()
	if track != "big":
		_playground()
	if track != "middle":
		_picnic()
	_places_look()   # the rooms' look (2026-10-18)
	_views()
	if track == "little":
		var held := view("phone")
		var feet: Vector3 = held.feet
		phone_screen = make_held_phone(Transform3D(Basis(Vector3.UP, float(held.yaw)),
			feet + Vector3(0, EYE, 0) + Basis(Vector3.UP, float(held.yaw)) * Vector3(0, -0.15, -0.45)))


# --- The practice room -------------------------------------------------------------------------------------------------

func _room() -> void:
	var d := decor()   # the rooms' look: a light plank floor, the wall
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(8.0, 0.1, 6.0), Vector3(0, -0.05, 0.2), Color("f2dcc0"), 0.75)
	d.box("BackWall", Vector3(8.0, 2.6, 0.1), Vector3(0, 1.3, -2.6), WALL, 0.0, LifeRoomDecor.SHELL)
	# lower, smaller (high on the wall it sat half under the HUD's bar)
	LifeRoomKit.sign(self, "RoomSign", "PRACTICE ROOM", Vector3(-1.8, 1.95, -2.5), 0.004, Color("2f7f6a"))
	LifeRoomKit.box(scenery(), "Cross", Vector3(0.3, 0.1, 0.02), Vector3(2.4, 2.1, -2.54), Color("3fbf5a"))
	LifeRoomKit.box(scenery(), "Cross2", Vector3(0.1, 0.3, 0.02), Vector3(2.4, 2.1, -2.54), Color("3fbf5a"))
	LifeRoomKit.light(self, Vector3(0, 2.4, 0), 0.9, 9.0)


## Middle: Bobo on the bench (a nosebleed): help him lean forward (his shoulder), not tip his head back (his forehead);
## pinch the soft part of his nose.
func _bench() -> void:
	LifeRoomKit.box(scenery(), "Bench", Vector3(1.0, 0.45, 0.45), Vector3(-2.0, 0.225, -1.6), WOOD)
	bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
	bobo.position = Vector3(-2.0, 0, -1.6)
	add_child(bobo)
	bobo.pose("sit")
	LifeRoomPeople.feel(bobo, "worried")
	add_target("lean_forward", bobo.mark("shoulder"), 0.11)
	var fore := Node3D.new()
	fore.name = "Mark_forehead"
	fore.position = Vector3(0, 0.27, 0.16)
	bobo.head.add_child(fore)
	add_target("head_back", fore, 0.08)
	var nose := Node3D.new()
	nose.name = "Mark_nose"
	nose.position = Vector3(0, 0.13, 0.17)
	bobo.head.add_child(nose)
	add_target("nose_soft", nose, 0.07)


## Middle: Kiki on her chair (asthma), and the table with the trainer inhaler and its spacer.
func _asthma() -> void:
	LifeRoomKit.box(scenery(), "Chair", Vector3(0.5, 0.45, 0.5), Vector3(1.8, 0.225, -1.9), Color("7fb8d6"))
	kiki = LifeBuddy.new(Color("5aa8e6"), "Kiki")
	kiki.position = Vector3(1.8, 0, -1.9)
	add_child(kiki)
	kiki.pose("sit")
	LifeRoomPeople.feel(kiki, "worried")
	kiki.hips.rotation.x = 0.35   # hunched over, before she sits up straight
	add_target("kiki_sit", kiki.mark("shoulder"), 0.12)
	LifeRoomKit.box(scenery(), "Table", Vector3(0.9, 0.74, 0.6), Vector3(0.4, 0.37, -1.25), WOOD.lightened(0.2))
	inhaler = Node3D.new()
	inhaler.name = "Inhaler"
	inhaler.position = Vector3(0.18, 0.82, -1.15)
	add_child(inhaler)
	LifeRoomKit.box(inhaler, "Body", Vector3(0.05, 0.11, 0.04), Vector3.ZERO, Color("3a7be8"))
	LifeRoomKit.box(inhaler, "Mouth", Vector3(0.05, 0.03, 0.05), Vector3(0, -0.06, 0.03), Color("3a7be8").darkened(0.2))
	add_target("inhaler", inhaler, 0.09)
	var top := Node3D.new()
	top.name = "Top"
	top.position = Vector3(0, 0.07, 0)
	inhaler.add_child(top)
	add_target("inhaler_top", top, 0.06)
	spacer = Node3D.new()
	spacer.name = "Spacer"
	spacer.position = Vector3(0.55, 0.8, -1.15)
	add_child(spacer)
	var tube := LifeRoomKit.cylinder(spacer, "Tube", 0.05, 0.3, Vector3.ZERO, Color(0.8, 0.88, 0.96, 0.8))
	tube.rotation.z = PI / 2
	LifeRoomKit.box(spacer, "Mouthpiece", Vector3(0.05, 0.04, 0.04), Vector3(0.18, 0, 0), INK.lightened(0.3))
	var end := Node3D.new()
	end.name = "End"
	end.position = Vector3(-0.16, 0, 0)
	spacer.add_child(end)
	add_target("spacer", end, 0.07)
	var mouth := Node3D.new()
	mouth.name = "MouthEnd"
	mouth.position = Vector3(0.2, 0, 0)
	spacer.add_child(mouth)
	add_target("spacer_mouth", mouth, 0.07)
	LifeRoomKit.sign(self, "Trainer", "TRAINER: NO MEDICINE", Vector3(0.4, 1.05, -1.4), 0.003, INK)


## Big: the floor mat where Bobo pretends to have a seizure, the hard things round him, the cushion, the spoon, the
## stopwatch.
func _seizure_corner() -> void:
	LifeRoomKit.box(scenery(), "Mat", Vector3(2.0, 0.03, 1.2), Vector3(0.4, 0.015, -0.7), Color("7fb8d6"))
	bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
	bobo.position = Vector3(0.5, 0.11, -0.7)
	add_child(bobo)
	bobo.pose("lie")
	bobo.visible = true
	add_target("near_arm", bobo.mark("near_arm"), 0.12)
	add_target("far_hand", bobo.mark("far_hand"), 0.12)
	add_target("far_knee", bobo.mark("far_knee"), 0.13)
	var chair := LifeRoomKit.box(self, "HardChair", Vector3(0.45, 0.8, 0.45), Vector3(-0.7, 0.4, -0.2), WOOD)
	add_target("chair", chair, 0.28)
	hard.chair = chair
	var box := LifeRoomKit.box(self, "ToyBox", Vector3(0.5, 0.35, 0.4), Vector3(1.6, 0.175, -0.2), Color("e8544e"))
	add_target("toy_box", box, 0.28)
	hard.toy_box = box
	var lamp := LifeRoomKit.cylinder(self, "FloorLamp", 0.12, 1.1, Vector3(1.4, 0.55, -1.6), Color("9aa7b5"))
	add_target("lamp_hard", lamp, 0.28)
	hard.lamp_hard = lamp
	LifeRoomKit.box(scenery(), "Sofa", Vector3(1.4, 0.45, 0.6), Vector3(-1.6, 0.225, -2.0), Color("7b5cd6"))
	cushion = LifeRoomKit.box(self, "Cushion", Vector3(0.4, 0.12, 0.35), Vector3(-1.4, 0.5, -1.9), Color("e85a9a").lightened(0.3))
	add_target("cushion", cushion, 0.2)
	LifeRoomKit.box(scenery(), "SideTable", Vector3(0.6, 0.72, 0.4), Vector3(-0.2, 0.36, -2.1), WOOD.lightened(0.2))
	var spoon := LifeRoomKit.box(self, "Spoon", Vector3(0.16, 0.015, 0.035), Vector3(-0.35, 0.73, -2.0), Color("c9ced6"))
	add_target("spoon", spoon, 0.1)
	var watch := LifeRoomKit.cylinder(self, "Stopwatch", 0.05, 0.02, Vector3(0.0, 0.74, -2.0), Color("3fbf5a"))
	add_target("stopwatch", watch, 0.09)


# --- The practice playground -----------------------------------------------------------------------------------------

func _playground() -> void:
	var g := Node3D.new()
	g.name = "Playground"
	add_child(g)
	decor().tiled("PlayGrass", LifeRoomDecor.GRASS, Vector3(14, 0.1, 12), PLAY + Vector3(0, -0.05, -1.5), Color("dcefc8"), 1.0)
	LifeRoomKit.box(g, "SlideSteps", Vector3(0.5, 1.4, 0.5), PLAY + Vector3(-2.0, 0.7, -2.6), Color("e8544e"))
	var slide := LifeRoomKit.box(g, "Slide", Vector3(0.5, 0.05, 2.0), PLAY + Vector3(-2.0, 0.7, -1.5), Color("ffd23f"))
	slide.rotation.x = 0.6
	LifeRoomKit.box(g, "TreeTrunk", Vector3(0.3, 2.2, 0.3), PLAY + Vector3(2.4, 1.1, -2.6), WOOD)
	LifeRoomKit.sphere(g, "Crown", 1.3, PLAY + Vector3(2.4, 2.6, -2.6), Color("3f8a3a"))
	LifeRoomKit.box(g, "Shade", Vector3(2.4, 0.01, 2.0), PLAY + Vector3(2.4, 0.01, -2.2), Color(0.2, 0.35, 0.2, 0.35))
	add_spot_target("shade_spot", g, PLAY + Vector3(2.0, 0.05, -1.6), 0.5)
	LifeRoomKit.cylinder(g, "ShadeRing", 0.45, 0.02, PLAY + Vector3(2.0, 0.02, -1.6), Color(0.3, 0.85, 0.4, 0.6))
	LifeRoomKit.box(g, "Bench", Vector3(1.0, 0.45, 0.4), PLAY + Vector3(0.6, 0.225, -0.9), WOOD)
	bottle = LifeRoomKit.cylinder(g, "Bottle", 0.04, 0.2, PLAY + Vector3(0.4, 0.55, -0.9), Color(0.6, 0.85, 1.0, 0.9))
	add_target("water_bottle", bottle, 0.12)
	LifeRoomKit.sign(g, "PlaySign", "PRACTICE PLAYGROUND", PLAY + Vector3(-1.0, 2.6, -3.6), 0.006, Color("2f7f6a"))
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55
	gus.position = PLAY + Vector3(-0.6, 0, -2.4)
	g.add_child(gus)
	LifeRoomPeople.feel(gus, "happy")
	var m := Node3D.new()
	m.name = "T_gus"
	m.position = Vector3(0, 0.63, 0.1)
	gus.add_child(m)
	add_target("gus", m, 0.45)
	lulu = LifeBuddy.new(Color("e8c84a"), "Lulu")
	lulu.position = PLAY + Vector3(-1.5, 0, -0.6)
	lulu.visible = false
	g.add_child(lulu)
	pip = LifeBuddy.new(Color("e85a9a"), "PipPop")
	pip.position = PLAY + Vector3(0.6, 0, -0.2)
	pip.visible = false
	g.add_child(pip)
	if track == "little":   # Little's nosebleed: Bobo on the playground's bench
		bobo = LifeBuddy.new(Color("1fa6a0"), "Bobo")
		bobo.position = PLAY + Vector3(-3.4, 0, -0.9)
		bobo.rotation.y = 0.6
		g.add_child(bobo)
		bobo.pose("sit_floor")
		bobo.visible = false


# --- The picnic --------------------------------------------------------------------------------------------------------

func _picnic() -> void:
	var g := Node3D.new()
	g.name = "Picnic"
	add_child(g)
	decor().tiled("PicnicGrass", LifeRoomDecor.GRASS, Vector3(10, 0.1, 9), PICNIC + Vector3(0, -0.05, -1.5), Color("dcefc8"), 1.0)
	LifeRoomKit.box(g, "Blanket", Vector3(1.6, 0.02, 1.2), PICNIC + Vector3(-0.3, 0.01, -1.4), Color("e8544e"))
	LifeRoomKit.box(g, "Biscuits", Vector3(0.2, 0.04, 0.14), PICNIC + Vector3(0.1, 0.04, -1.2), Color("d99a4e"))
	mo = LifeBuddy.new(Color("ffb347"), "Mo")
	mo.position = PICNIC + Vector3(-0.6, 0, -1.6)
	mo.rotation.y = 0.3
	g.add_child(mo)
	mo.pose("sit_floor")
	LifeRoomPeople.feel(mo, "happy")
	if track == "little":
		phone = Node3D.new()
		phone.name = "Phone"
		phone.position = PICNIC + Vector3(0.45, 0.04, -0.9)
		g.add_child(phone)
		LifeRoomKit.box(phone, "Body", Vector3(0.16, 0.03, 0.28), Vector3.ZERO, INK)
		add_target("phone", phone, 0.18)
		return
	# Big: the allergy's signs on Mo (calm: a soft pink puffiness and a light rash, never a wound), and the pen's table
	var lips := Node3D.new()
	lips.name = "Mark_lips"
	lips.position = Vector3(0, 0.1, 0.16)
	mo.head.add_child(lips)
	add_target("sign_lips", lips, 0.07)
	var rash := Node3D.new()
	rash.name = "Mark_rash"
	rash.position = Vector3(0, -0.18, 0.06)
	mo.arm_near.add_child(rash)
	add_target("sign_rash", rash, 0.08)
	var breath := Node3D.new()
	breath.name = "Mark_breath"
	breath.position = Vector3(0, 0.38, 0.13)
	mo.hips.add_child(breath)
	add_target("sign_breath", breath, 0.08)
	LifeRoomKit.box(g, "PenTable", Vector3(0.8, 0.7, 0.5), PICNIC + Vector3(1.7, 0.35, -1.2), WOOD.lightened(0.2))
	var pen := Node3D.new()
	pen.name = "TrainerPen"
	pen.position = PICNIC + Vector3(1.5, 0.74, -1.1)
	g.add_child(pen)
	LifeRoomKit.box(pen, "Body", Vector3(0.16, 0.035, 0.035), Vector3.ZERO, WHITE)
	LifeRoomKit.box(pen, "Orange", Vector3(0.03, 0.035, 0.035), Vector3(0.09, 0, 0), Color("ff7a2e"))
	pen_cap = LifeRoomKit.box(pen, "BlueCap", Vector3(0.03, 0.035, 0.035), Vector3(-0.09, 0, 0), Color("3a7be8"))
	add_target("pen_blue", pen_cap, 0.07)
	var pad := LifeRoomKit.box(g, "PracticePad", Vector3(0.18, 0.12, 0.34), PICNIC + Vector3(1.85, 0.76, -1.2), Color("e8b48a"))
	add_target("pad_thigh", pad, 0.11)
	LifeRoomKit.sign(g, "TrainerSign", "TRAINER: NO NEEDLE, NO MEDICINE", PICNIC + Vector3(1.7, 1.05, -1.4), 0.003, INK)


func _views() -> void:
	add_view("room", Vector3(0, 1.6, 2.6), Vector3(0, 0.5, -1.2), Vector3(0, 0, 1.4), 0.0)
	add_view("bench", Vector3(-2.0, 1.25, -0.35), Vector3(-2.0, 0.8, -1.6), Vector3(-2.0, 0, -0.75), 0.0)
	add_view("asthma", Vector3(1.4, 1.3, -0.3), Vector3(1.7, 0.6, -1.9), Vector3(1.5, 0, -0.9), 0.0)
	add_view("table", Vector3(0.4, 1.35, 0.1), Vector3(0.38, 0.78, -1.15), Vector3(0.4, 0, -0.35), 0.0)
	add_view("mat", Vector3(0.1, 1.35, 0.55), Vector3(0.2, 0.15, -0.7), Vector3(0.1, 0, 0.05), 0.0)
	add_view("playground", PLAY + Vector3(0, 1.6, 3.2), PLAY + Vector3(0, 0.6, -1.6), PLAY + Vector3(0, 0, 1.8), 0.0)
	add_view("picnic", PICNIC + Vector3(0.2, 1.5, 1.6), PICNIC + Vector3(0.2, 0.4, -1.4), PICNIC + Vector3(0.2, 0, 0.6), 0.0)
	add_view("pen", PICNIC + Vector3(1.6, 1.35, 0.0), PICNIC + Vector3(1.7, 0.75, -1.2), PICNIC + Vector3(1.6, 0, -0.45), 0.0)
	add_view("phone", PICNIC + Vector3(0.2, 1.15, 1.1), PICNIC + Vector3(0.2, 1.0, -0.2), PICNIC + Vector3(0.2, 0, 0.6), 0.0)


# --- Events ------------------------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"lulu_bump":
			if lulu:
				lulu.visible = true
				LifeRoomPeople.feel(lulu, "calm")
		"bobo_nose":
			if bobo:
				bobo.visible = true
				LifeRoomPeople.feel(bobo, "worried")
				var dot := LifeRoomKit.sphere(bobo.head, "NoseDot", 0.02, Vector3(0, 0.11, 0.17), SOFT_RED)
				dot.name = "NoseDot"
		"pip_hot":
			if pip:
				pip.visible = true
				LifeRoomPeople.feel(pip, "worried")
		"mo_lips":
			LifeRoomPeople.feel(mo, "worried")
			LifeRoomKit.box(mo.head, "Puffy", Vector3(0.12, 0.04, 0.02), Vector3(0, 0.1, 0.165), Color(0.98, 0.7, 0.72, 0.9))
		"mo_allergy":
			LifeRoomPeople.feel(mo, "worried")
			LifeRoomKit.box(mo.head, "Puffy", Vector3(0.13, 0.045, 0.02), Vector3(0, 0.1, 0.165), Color(0.98, 0.7, 0.72, 0.9))
			for i in 4:
				LifeRoomKit.sphere(mo.arm_near, "Rash", 0.012, Vector3(0.02 * (i % 2), -0.14 - 0.03 * i, 0.06), Color(0.98, 0.62, 0.66, 0.9))
		"kiki_wheeze":
			if kiki:
				LifeRoomPeople.feel(kiki, "worried")
		"bobo_seizure":
			seizing = true
			LifeRoomPeople.feel(bobo, "calm")   # eyes shut: pretending
		"seizure_stops":
			seizing = false
			bobo.pose("lie")
			LifeRoomPeople.feel(bobo, "calm")
		"cushion_under":
			cushion.position = bobo.position + Vector3(-0.62, -0.06, 0.0)
		"arm_out":
			bobo.arm_out()
		"hand_cheek":
			bobo.hand_cheek()
		"knee_up":
			bobo.knee_up()
		"roll_side":
			bobo.roll_side()


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"nose":
			if bobo:
				bobo.hips.rotation.x = 0.35   # leaning forward
		"ten":
			if bobo and bobo.head.get_node_or_null("NoseDot"):
				bobo.head.get_node("NoseDot").queue_free()
			if bobo:
				LifeRoomPeople.feel(bobo, "happy")
		"sit":
			if kiki:
				kiki.hips.rotation.x = 0.0
		"spacer":
			if inhaler and spacer:
				inhaler.position = spacer.position + Vector3(-0.2, 0.05, 0)
		"breathe":
			if kiki:
				LifeRoomPeople.feel(kiki, "calm")
		"hot", "heat":
			if pip:
				pip.position = PLAY + Vector3(2.0, 0, -1.9)
		"drink", "cool":
			if bottle and pip:
				bottle.position = pip.position + Vector3(0.25, 0.55, 0.15)
		"cap":
			if pen_cap:
				pen_cap.visible = false
		"phone":
			if phone:
				phone.visible = false
				(get_node("HeldPhone") as Node3D).visible = true
		"dial":
			if phone_screen:
				phone_screen.text = "CALLING..."
		"after":
			if track == "big":
				mo.pose("lie")


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			for f: Variant in state.get("found", []):
				var t := str(f)
				if hard.has(t):   # a hard thing moved away from him
					var n: Node3D = hard[t]
					if n.get_meta("moved", false) == false:
						n.set_meta("moved", true)
						n.position += Vector3(-0.8 if n.position.x < 0.5 else 0.9, 0, 0.5)
				elif has_target(t) and target_node(t).get_node_or_null("Found") == null:
					LifeRoomKit.sphere(target_node(t), "Found", 0.025, Vector3(0, 0.05, 0.03), Color(0.3, 0.85, 0.4, 0.9))
		"sequence":
			if phone_screen:
				phone_screen.text = LifeRoom.dialled(step, state)


func _process(delta: float) -> void:
	super(delta)
	_t += sim_delta(delta)
	if seizing and bobo:   # a gentle, pretend jerking: small and slow, the face calm
		var k := 0.18 * sin(_t * 9.0)
		bobo.arm_near.rotation.x = k
		bobo.arm_far.rotation.x = -k
		bobo.leg_near.rotation.x = -k * 0.6
		bobo.leg_far.rotation.x = k * 0.6


# --- The safe mistakes' gentle pictures ---------------------------------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if not on:
		return
	var holder := mistake_holder()
	match event:
		"throat":   # a ghost of Bobo frozen with his head tipped back, a soft arrow down his throat
			var ghost := LifeBuddy.new(Color(0.12, 0.65, 0.63, 0.55), "HeadBack")
			ghost.position = bobo.position + Vector3(0.55, 0, 0.1)
			holder.add_child(ghost)
			ghost.pose("sit")
			ghost.head.rotation.x = -0.7
			LifeRoomPeople.feel(ghost, "worried")
			var arrow := LifeRoomKit.box(holder, "DownThroat", Vector3(0.03, 0.22, 0.03), ghost.position + Vector3(0, 0.82, 0.1),
				Color(1.0, 0.86, 0.3, 0.9))
			arrow.material_override = LifeRoomKit.material(Color(1.0, 0.86, 0.3, 0.9), true)
			LifeRoomKit.sign(holder, "Why", "IT RUNS DOWN THE THROAT", ghost.position + Vector3(0, 1.45, 0), 0.0035, Color("ffd23f"))
		"spoon_mouth":   # a spoon frozen near his mouth, a soft "no"
			var at := bobo.position + Vector3(-0.55, 0.2, 0.15)
			var spoon := LifeRoomKit.box(holder, "Spoon", Vector3(0.16, 0.015, 0.035), at, Color("c9ced6"))
			spoon.rotation.z = 0.5
			for s: float in [-0.7, 0.7]:
				var bar := LifeRoomKit.box(holder, "No", Vector3(0.22, 0.02, 0.02), at + Vector3(0, 0.12, 0), Color("6b7a99"))
				bar.rotation.z = s
			LifeRoomKit.sign(holder, "Why", "NOTHING IN THE MOUTH", at + Vector3(0, 0.55, 0), 0.0035, Color("ffd23f"))


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The practice room as a calm first aid room (side walls, a skirting, a window, the first aid cabinet under its green
## cross, a poster, a plant, a ceiling with its light), the playground's sandpit, swings, fence and flowers, the picnic's
## trees, flowers and basket, one grassy land under all of them and a soft sky. Each place's own boxes in one mesh, the
## people in few.
func _places_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Land", Vector3(120, 0.1, 60), Vector3(0, -0.14, 0), Color("86c063"), 0.0, LifeRoomDecor.SHELL)
	# the practice room
	for x: float in [-4.0, 4.0]:
		d.box("SideWall", Vector3(0.1, 2.6, 6.0), Vector3(x, 1.3, 0.2), WALL.darkened(0.03), 0.0, LifeRoomDecor.SHELL)
	d.box("Wainscot", Vector3(8.0, 0.9, 0.02), Vector3(0, 0.45, -2.54), Color("cfe8dc"), 0.0, LifeRoomDecor.SHELL)
	d.skirting("Skirting", Vector3(-4.0, 0, -2.53), Vector3(4.0, 0, -2.53), Color("8fbfa8"))
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(8.0, 0.1, 6.0), Vector3(0, 2.65, 0.2), Color("fbf8f2"), 0.8)
	d.ceiling_light("Light", Vector3(0, 2.58, -0.4), 0.32)
	d.window("Window", Vector3(-3.94, 1.55, -0.6), 1.2, 0.9, PI / 2)
	d.box("Cabinet", Vector3(0.7, 0.55, 0.22), Vector3(2.4, 1.6, -2.44), Color("fdfdf8"))
	d.box("CabinetLine", Vector3(0.02, 0.5, 0.01), Vector3(2.4, 1.6, -2.325), Color("cfd6dc"))
	d.picture("Poster", Vector3(-0.2, 1.65, -2.54), Vector2(0.5, 0.65), 0.0, Color("3fbf5a"), Color("fdfdf8"), 2)
	d.plant("Plant", Vector3(3.6, 0, -2.2), 1.1)
	if track != "big":
		# the playground: a sandpit, swings, a fence, flowers
		d.tiled("Sandpit", LifeRoomDecor.SAND, Vector3(2.0, 0.06, 1.6), PLAY + Vector3(-4.8, 0.03, -3.0), Color("fff2d6"), 1.0)
		d.box("SandEdge", Vector3(2.2, 0.12, 0.1), PLAY + Vector3(-4.8, 0.06, -2.15), Color("c89a62"))
		for x: float in [3.6, 5.6]:
			d.box("SwingPost", Vector3(0.1, 2.1, 0.1), PLAY + Vector3(x, 1.05, -4.6), Color("3a7be8"))
		d.box("SwingBar", Vector3(2.2, 0.1, 0.1), PLAY + Vector3(4.6, 2.1, -4.6), Color("3a7be8"))
		for x: float in [4.1, 5.1]:
			d.box("SwingRope", Vector3(0.02, 1.5, 0.02), PLAY + Vector3(x, 1.35, -4.6), Color("8a6239"))
			d.box("SwingSeat", Vector3(0.4, 0.04, 0.2), PLAY + Vector3(x, 0.6, -4.6), Color("e8544e"))
		d.fence("PlayFence", PLAY + Vector3(-7.0, 0, -7.4), PLAY + Vector3(7.0, 0, -7.4), Color("fdfaf2"), 0.8)
		for x: float in [-5.5, 5.8]:
			d.bush("PlayFlowers", PLAY + Vector3(x, 0, 2.6), 0.9, Color("5aa548"), Color("ffc93c") if x < 0 else Color("e85a9a"))
	if track != "middle":
		# the picnic: trees, flowers, a basket
		for t: Vector3 in [Vector3(-3.8, 0, -4.6), Vector3(3.6, 0, -5.0), Vector3(-4.6, 0, 1.4)]:
			d.tree("PicnicTree", PICNIC + t, 1.3)
		d.bush("PicnicFlowers", PICNIC + Vector3(3.2, 0, 1.4), 0.9, Color("5aa548"), Color("e85a9a"))
		d.box("Basket", Vector3(0.36, 0.22, 0.26), PICNIC + Vector3(-1.0, 0.11, -1.9), Color("c89a62"))
		d.box("BasketLid", Vector3(0.38, 0.03, 0.28), PICNIC + Vector3(-1.0, 0.235, -1.9), Color("a8743a"))
	for place: Node3D in [get_node_or_null("Playground") as Node3D, get_node_or_null("Picnic") as Node3D]:
		if place != null:
			LifeRoomPeople.merge_parts(self, place)
	for b: LifeBuddy in [bobo, kiki, mo]:   # they sit up, lean, lie down and roll on their side
		if b != null:
			LifeRoomPeople.merge_person(b)
	for b: LifeBuddy in [gus, lulu, pip]:
		if b != null:
			LifeRoomPeople.merge_person(b, true)
