class_name PoisonsRoom
extends LifeRoom
## Owner #118 (docs/design/life-skills.md §14, the catalogue's row 5: poisons and chemicals; Life L3a): The Poisons
## Cupboard's practice house: the kitchen (the open cupboard under the sink and the worktop with bottles, the dangerous
## ones wearing the red-diamond warning signs; the high cupboard with its child lock), the bucket by the sink, the sofa
## corner where a remote's button battery fell out, a table with medicine that looks like sweets, the garden's berries and
## mushrooms, the garage (Middle: antifreeze, weed killer, paint thinner) and the hall with its carbon monoxide alarm and
## the front garden (Big: the night drill and the call from outside). Gus is the grown-up; Mo has ideas. The safe
## mistake's gentle picture (on_mistake "fumes"): a soft grey-green cloud frozen over the bucket, never a person hurt.

const FLOOR := Color("e8d8c0")
const WALL := Color("f3efe6")
const WOOD := Color("a8642a")
const DIAMOND_RED := Color("e8544e")
const MARK := Color("1f2a4a")
const KITCHEN_GUS := Vector3(-1.3, 0, -0.85)
const HALL := Vector3(16.0, 0, 0)
const OUTSIDE := Vector3(24.0, 0, 0)

var gus: LifeBuddy
var mo: LifeBuddy
var bottles := {}
var latch: MeshInstance3D
var co_light: MeshInstance3D
var phone: Node3D
var phone_screen: Label3D
var _alarm := false
var _alarm_t := 0.0
var _beep_t := -1.0


func build() -> void:
	name = "PoisonsRoom"
	env = LifeRoomKit.environment(Color("cfe3f2"), Color("f3f6f9"), 0.75)
	start_view = "hall" if track == "big" else "kitchen"
	_kitchen()
	_corner()
	_garden()
	if track == "middle":
		_garage()
	if track == "big":
		_hall()
		_outside()
	_buddies()
	_home_look()   # the rooms' look (2026-10-18)
	_views()
	if track == "big":
		var held := view("phone_out")
		var feet: Vector3 = held.feet
		phone_screen = make_held_phone(Transform3D(Basis(Vector3.UP, float(held.yaw)),
			feet + Vector3(0, EYE, 0) + Basis(Vector3.UP, float(held.yaw)) * Vector3(0, -0.15, -0.45)))


# --- The kitchen -------------------------------------------------------------------------------------------------------

func _kitchen() -> void:
	var d := decor()   # the rooms' look: tiles, a splashback, a painted window
	d.tiled("Floor", LifeRoomDecor.TILE, Vector3(7.0, 0.1, 5.4), Vector3(0, -0.05, 0.4), Color("e8c9a8"), 0.5)
	d.box("BackWall", Vector3(7.0, 2.6, 0.1), Vector3(0, 1.3, -2.3), WALL, 0.0, LifeRoomDecor.SHELL)
	d.tiled("Splashback", LifeRoomDecor.TILE, Vector3(4.0, 0.45, 0.02), Vector3(0, 1.13, -2.245), Color("d6ecf2"), 0.2)
	d.window("Window", Vector3(-0.1, 1.72, -2.245), 0.9, 0.55, 0.0)
	var sc := scenery()
	LifeRoomKit.box(scenery(), "Top", Vector3(4.0, 0.05, 0.62), Vector3(0, 0.875, -1.9), Color("d7d2c8"))
	LifeRoomKit.box(scenery(), "CabinetL", Vector3(1.5, 0.85, 0.6), Vector3(-1.25, 0.425, -1.9), Color("7fb8d6"))
	LifeRoomKit.box(scenery(), "CabinetR", Vector3(1.4, 0.85, 0.6), Vector3(1.3, 0.425, -1.9), Color("7fb8d6"))
	LifeRoomKit.box(scenery(), "SinkBack", Vector3(1.1, 0.85, 0.05), Vector3(0.05, 0.425, -2.18), Color("5d7f94"))
	LifeRoomKit.box(scenery(), "SinkFloor", Vector3(1.1, 0.04, 0.6), Vector3(0.05, 0.02, -1.9), Color("5d7f94"))
	for x: float in [-0.55, 0.65]:   # the cupboard's doors stand open: nobody locked it
		var door := LifeRoomKit.box(sc, "OpenDoor", Vector3(0.04, 0.8, 0.55), Vector3(x, 0.42, -1.35), Color("8fc4de"))
		door.rotation.y = 0.3 if x < 0 else -0.3
	LifeRoomKit.sign(self, "RoomSign", "PRACTICE KITCHEN", Vector3(-2.2, 2.3, -2.2), 0.005, Color("2f7f6a"))
	LifeRoomKit.light(self, Vector3(0, 2.4, 0), 0.9, 8.0)
	# the dangerous ones (their warning signs), and the safe ones. Little finds the bottles; Middle finds the signs
	# themselves (one target per thing: a tap goes to the nearest)
	var whole := track != "middle"
	_bottle("bleach", Vector3(-0.15, 0.0, -1.75), Color("f4f6f8"), Color("3a7be8"), "harmful", false, whole)
	_bottle("drain_cleaner", Vector3(0.35, 0.0, -1.75), Color("6b4fa8"), Color("ffd23f"), "corrosive", false, whole)
	_bottle("oven_cleaner", Vector3(-1.4, 0.9, -1.9), Color("3a3f4a"), Color("e8544e"), "flammable", false, whole)
	if track == "middle":   # a pest killer wears the toxic sign (the skull)
		_bottle("pest_killer", Vector3(-0.9, 0.9, -1.9), Color("6d8a1f"), Color("3a3f4a"), "toxic", false, false)
	else:
		_bottle("washing_tabs", Vector3(-0.9, 0.9, -1.9), Color("3fbf5a"), Color("f4f6f8"), "harmful", true, whole)
	_bottle("water_bottle", Vector3(-1.75, 0.9, -1.9), Color(0.7, 0.88, 1.0, 0.9), Color("3a7be8"), "")
	_bottle("juice", Vector3(1.0, 0.9, -1.9), Color("ffb02e"), Color("3fbf5a"), "")
	_bottle("milk", Vector3(1.45, 0.9, -1.9), Color("fdfdf8"), Color("3a7be8"), "")
	var hidden := _bottle("juice_cleaner", Vector3(0.65, 0.9, -1.9), Color("ffb02e"), Color("3fbf5a"), "", false, whole)
	hidden.visible = false   # Little's Expert try: a cleaner poured into a juice bottle
	var plain := _bottle("no_label", Vector3(0.65, 0.9, -1.9), Color("b9c2cc"), Color("6b7a99"), "")
	plain.visible = false
	if track == "middle":
		add_target("sym_harmful", bottles.bleach.get_node("Diamond") as Node3D, 0.12)
		add_target("sym_corrosive", bottles.drain_cleaner.get_node("Diamond") as Node3D, 0.12)
		add_target("sym_flammable", bottles.oven_cleaner.get_node("Diamond") as Node3D, 0.12)
		add_target("sym_toxic", bottles.pest_killer.get_node("Diamond") as Node3D, 0.12)
	# the high cupboard with its child lock
	LifeRoomKit.box(scenery(), "HighCupboard", Vector3(1.0, 0.7, 0.35), Vector3(1.4, 1.9, -2.07), Color("7fb8d6"))
	var door := LifeRoomKit.box(self, "HighDoor", Vector3(0.96, 0.66, 0.03), Vector3(1.4, 1.9, -1.885), Color("8fc4de"))
	add_target("cupboard_door", door, 0.16)
	latch = LifeRoomKit.box(self, "ChildLock", Vector3(0.12, 0.06, 0.04), Vector3(1.4, 1.6, -1.86), Color("e8544e"))
	add_target("child_lock", latch, 0.11)
	# the bucket by the sink: Mo's "super cleaner" idea
	LifeRoomKit.cylinder(sc, "Bucket", 0.17, 0.3, Vector3(0.2, 0.15, -1.25), Color("3a7be8"))
	add_spot_target("mix_bucket", self, Vector3(0.2, 0.17, -1.25), 0.22)
	_bottle("bucket_bleach", Vector3(0.5, 0.0, -1.15), Color("f4f6f8"), Color("3a7be8"), "harmful")
	_bottle("toilet_cleaner", Vector3(-0.1, 0.0, -1.1), Color("3a7be8"), Color("ffd23f"), "corrosive")
	add_spot_target("one_bottle", self, Vector3(-0.1, 0.18, -1.1), 0.16)


## A bottle (or a tub) standing at `at` (its foot), its warning sign on the front: a red-edged white diamond with the
## sign's own mark ("" for a safe one). With `target`, its whole body is the target of the same name.
func _bottle(id: String, at: Vector3, body: Color, cap: Color, sign: String, tub: bool = false, target: bool = false) -> Node3D:
	var b := Node3D.new()
	b.name = "Bottle_" + id
	b.position = at
	add_child(b)
	var size := Vector3(0.16, 0.14, 0.16) if tub else Vector3(0.1, 0.26, 0.08)
	LifeRoomKit.box(b, "Body", size, Vector3(0, size.y * 0.5, 0), body)
	LifeRoomKit.box(b, "Cap", Vector3(0.05, 0.05, 0.05) if not tub else Vector3(0.17, 0.02, 0.17),
		Vector3(0, size.y + 0.02, 0) if not tub else Vector3(0, size.y + 0.01, 0), cap)
	if sign != "":
		var d := Node3D.new()
		d.name = "Diamond"
		d.position = Vector3(0, size.y * 0.55, size.z * 0.5 + 0.006)
		b.add_child(d)
		var red := LifeRoomKit.box(d, "Edge", Vector3(0.075, 0.075, 0.004), Vector3.ZERO, DIAMOND_RED)
		red.rotation.z = PI / 4
		var white := LifeRoomKit.box(d, "Inside", Vector3(0.058, 0.058, 0.004), Vector3(0, 0, 0.002), Color.WHITE)
		white.rotation.z = PI / 4
		match sign:
			"harmful":
				LifeRoomKit.box(d, "Mark", Vector3(0.008, 0.026, 0.004), Vector3(0, 0.006, 0.004), MARK)
				LifeRoomKit.box(d, "Dot", Vector3(0.008, 0.008, 0.004), Vector3(0, -0.017, 0.004), MARK)
			"corrosive":
				for x: float in [-0.012, 0.012]:
					LifeRoomKit.box(d, "Drop", Vector3(0.008, 0.016, 0.004), Vector3(x, 0.01, 0.004), MARK)
				LifeRoomKit.box(d, "Surface", Vector3(0.04, 0.006, 0.004), Vector3(0, -0.014, 0.004), MARK)
			"flammable":
				LifeRoomKit.sphere(d, "Flame", 0.012, Vector3(0, 0.004, 0.004), Color("ff9d2e"))
				LifeRoomKit.box(d, "Base", Vector3(0.034, 0.006, 0.004), Vector3(0, -0.016, 0.004), MARK)
			"toxic":
				LifeRoomKit.sphere(d, "Skull", 0.011, Vector3(0, 0.008, 0.004), MARK)
				for s: float in [-0.7, 0.7]:
					var bone := LifeRoomKit.box(d, "Bone", Vector3(0.03, 0.005, 0.004), Vector3(0, -0.012, 0.004), MARK)
					bone.rotation.z = s
	if target:
		add_target(id, b, maxf(size.y, size.x) * 0.75)
	bottles[id] = b
	return b


# --- The sofa corner and the medicine table ---------------------------------------------------------------------------

func _corner() -> void:
	LifeRoomKit.box(scenery(), "Sofa", Vector3(1.6, 0.45, 0.7), Vector3(-3.5, 0.225, -1.5), Color("7b5cd6"))
	LifeRoomKit.box(scenery(), "SofaBack", Vector3(1.6, 0.5, 0.2), Vector3(-3.5, 0.7, -1.85), Color("6a4fc4"))
	LifeRoomKit.box(scenery(), "Remote", Vector3(0.05, 0.02, 0.16), Vector3(-2.9, 0.02, -0.75), Color("1f2a4a"))
	var battery := LifeRoomKit.cylinder(self, "ButtonBattery", 0.02, 0.006, Vector3(-2.7, 0.01, -0.6), Color("c9ced6"))
	add_target("battery", battery, 0.13)
	LifeRoomKit.box(scenery(), "Table", Vector3(0.8, 0.05, 0.6), Vector3(2.8, 0.68, -0.6), WOOD)
	LifeRoomKit.box(scenery(), "TableLeg", Vector3(0.08, 0.66, 0.08), Vector3(2.8, 0.33, -0.6), WOOD.darkened(0.2))
	LifeRoomKit.box(scenery(), "PillBottle", Vector3(0.07, 0.11, 0.07), Vector3(2.7, 0.765, -0.6), Color("ffb02e"))
	for i in 5:
		LifeRoomKit.sphere(scenery(), "Pill", 0.016, Vector3(2.85 + i * 0.035, 0.72, -0.5 - (i % 2) * 0.04),
			[Color("e85a9a"), Color("3a7be8"), Color("ffd23f"), Color("3fbf5a"), Color("ff9d2e")][i])


func _garden() -> void:
	var g := Node3D.new()
	g.name = "Garden"
	g.position = Vector3(8, 0, 0)
	add_child(g)
	LifeRoomKit.box(g, "Grass", Vector3(5, 0.1, 5), Vector3(0, -0.05, 0), Color("7cc46a"))
	LifeRoomKit.sphere(g, "Bush", 0.45, Vector3(0.3, 0.4, -1.2), Color("3f8a3a"))
	for i in 8:
		LifeRoomKit.sphere(g, "Berry", 0.035, Vector3(0.05 + (i % 4) * 0.15, 0.3 + (i / 4) * 0.25, -0.8), Color("e8544e"))
	for m: Vector3 in [Vector3(-0.5, 0, -0.7), Vector3(-0.3, 0, -0.9), Vector3(-0.7, 0, -1.0)]:
		LifeRoomKit.box(g, "Stem", Vector3(0.03, 0.08, 0.03), m + Vector3(0, 0.04, 0), Color("f4efe2"))
		LifeRoomKit.sphere(g, "Cap", 0.06, m + Vector3(0, 0.09, 0), Color("f4f0e8"))
	LifeRoomKit.sign(g, "GardenSign", "GARDEN", Vector3(1.6, 1.4, -1.6), 0.005, Color("2f7f6a"))


func _garage() -> void:
	var g := Node3D.new()
	g.name = "Garage"
	g.position = Vector3(-9, 0, 0)
	add_child(g)
	LifeRoomKit.box(g, "Floor", Vector3(5, 0.1, 5), Vector3(0, -0.05, 0), Color("b9c2cc"))
	LifeRoomKit.box(g, "Wall", Vector3(5, 2.4, 0.1), Vector3(0, 1.2, -2.1), Color("d7dde3"))
	LifeRoomKit.box(g, "CarFront", Vector3(1.8, 0.7, 1.2), Vector3(1.6, 0.45, 0.8), Color("3a7be8"))
	LifeRoomKit.box(g, "LowShelf", Vector3(1.0, 0.04, 0.35), Vector3(0.8, 0.4, -1.6), WOOD)
	LifeRoomKit.box(g, "HighCabinet", Vector3(1.0, 0.6, 0.35), Vector3(-0.4, 1.85, -1.9), Color("6b7a99"))
	var anti := _bottle("antifreeze", g.position + Vector3(-0.8, 0.0, -1.3), Color("3fd0c0"), Color("f4f6f8"), "harmful",
		false, true)
	anti.scale = Vector3(1.4, 1.1, 1.4)
	_bottle("weed_killer", g.position + Vector3(0.0, 0.0, -1.4), Color("6d8a1f"), Color("ffd23f"), "harmful", false, true)
	_bottle("paint_thinner", g.position + Vector3(0.8, 0.42, -1.55), Color("c0563a"), Color("3a3f4a"), "flammable", false,
		true)
	LifeRoomKit.sign(g, "GarageSign", "PRACTICE GARAGE", Vector3(0, 2.6, -2.0), 0.005, Color("2f7f6a"))


# --- The hall and the front garden (Big) -------------------------------------------------------------------------------

func _hall() -> void:
	LifeRoomKit.box(scenery(), "HallFloor", Vector3(5, 0.1, 5), HALL + Vector3(0, -0.05, 0), FLOOR)
	LifeRoomKit.box(scenery(), "HallWall", Vector3(5, 2.6, 0.1), HALL + Vector3(0, 1.3, -2.05), WALL)
	LifeRoomKit.box(scenery(), "Boiler", Vector3(0.5, 0.7, 0.3), HALL + Vector3(1.4, 1.5, -1.85), Color("f4f6f8"))
	var alarm := LifeRoomKit.cylinder(self, "CoAlarm", 0.09, 0.04, HALL + Vector3(0.4, 1.45, -1.97), Color("fdfdf8"))
	alarm.rotation.x = PI / 2
	var co_word := LifeRoomKit.sign(self, "CoWord", "CO", HALL + Vector3(0.4, 1.58, -1.93), 0.003, MARK)
	co_word.outline_size = 0
	co_light = LifeRoomKit.sphere(self, "CoLight", 0.018, HALL + Vector3(0.46, 1.45, -1.93), Color("3fbf5a"))
	add_spot_target("co_test", self, HALL + Vector3(0.4, 1.42, -1.9), 0.1)
	LifeRoomKit.box(scenery(), "HallSofa", Vector3(1.4, 0.45, 0.7), HALL + Vector3(1.6, 0.225, -1.4), Color("7b5cd6"))
	var door := LifeRoomKit.box(self, "FrontDoor", Vector3(0.9, 2.0, 0.06), HALL + Vector3(-1.2, 1.0, -1.98), Color("8a5a34"))
	add_target("front_door", door, 0.5)
	# over the front door, smaller (high on the wall it sat half under the HUD's bar in the first view)
	LifeRoomKit.sign(self, "HallSign", "PRACTICE HOUSE", HALL + Vector3(-1.2, 2.2, -1.95), 0.003, Color("2f7f6a"))


func _outside() -> void:
	LifeRoomKit.box(scenery(), "FrontGarden", Vector3(6, 0.1, 6), OUTSIDE + Vector3(0, -0.05, 4.5), Color("7cc46a"))
	LifeRoomKit.box(scenery(), "HouseFront", Vector3(6, 3.0, 0.2), OUTSIDE + Vector3(0, 1.5, 1.6), Color("f1e4cc"))
	LifeRoomKit.box(scenery(), "GardenWall", Vector3(1.6, 0.85, 0.3), OUTSIDE + Vector3(0.6, 0.425, 4.4), Color("c9a46a"))
	phone = Node3D.new()
	phone.name = "Phone"
	phone.position = OUTSIDE + Vector3(0.5, 0.88, 4.4)
	add_child(phone)
	LifeRoomKit.box(phone, "Body", Vector3(0.16, 0.03, 0.28), Vector3.ZERO, MARK)
	add_target("phone", phone, 0.18)


func _buddies() -> void:
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55   # a grown-up
	gus.position = KITCHEN_GUS
	gus.rotation.y = 0.6
	add_child(gus)
	var m := Node3D.new()   # his middle, wherever he is (he moves with the step's place)
	m.name = "T_gus"
	m.position = Vector3(0, 0.63, 0.1)
	gus.add_child(m)
	add_target("gus", m, 0.45)
	mo = LifeBuddy.new(Color("ffb347"), "Mo")
	mo.position = Vector3(0.95, 0, -1.0)
	mo.rotation.y = -PI / 2
	mo.visible = false
	add_child(mo)


func _views() -> void:
	add_view("kitchen", Vector3(0.0, 1.45, 1.3), Vector3(0.0, 0.65, -1.9), Vector3(0, 0, -0.5), 0.0)
	add_view("sink", Vector3(0.4, 1.4, 0.9), Vector3(0.0, 0.5, -1.6), Vector3(0.3, 0, -0.4), 0.0)
	add_view("bath", Vector3(0.4, 1.4, 0.9), Vector3(0.0, 0.5, -1.6), Vector3(0.3, 0, -0.4), 0.0)
	add_view("cupboard", Vector3(1.0, 1.25, 0.2), Vector3(1.35, 1.6, -1.9), Vector3(1.3, 0, -1.2), 0.0)
	add_view("table", Vector3(1.9, 1.3, 0.9), Vector3(2.8, 0.7, -0.6), Vector3(2.2, 0, 0.2), 0.6)
	add_view("floor", Vector3(-2.2, 1.35, 1.1), Vector3(-3.0, 0.3, -0.8), Vector3(-2.4, 0, 0.3), 0.4)
	add_view("garden", Vector3(8, 1.4, 2.6), Vector3(8.2, 0.3, -1.0), Vector3(8, 0, 1.4), 0.0)
	add_view("garage", Vector3(-9, 1.5, 1.6), Vector3(-9, 0.45, -1.6), Vector3(-9, 0, 0.6), 0.0)
	add_view("hall", HALL + Vector3(0.2, 1.45, 1.4), HALL + Vector3(0.2, 1.0, -1.9), HALL + Vector3(0.2, 0, -1.0), 0.0)
	add_view("outside", OUTSIDE + Vector3(0, 1.5, 6.8), OUTSIDE + Vector3(0.3, 0.8, 3.8), OUTSIDE + Vector3(0, 0, 5.5), 0.0)
	add_view("phone_out", OUTSIDE + Vector3(0, 1.15, 6.35), OUTSIDE + Vector3(0, 1.0, 5.05), OUTSIDE + Vector3(0, 0, 5.5), 0.0)


# --- Events ------------------------------------------------------------------------------------------------------------

## Gus stands where the step happens (the kitchen, the sofa corner, asleep in the hall, outside).
func _place_gus(v: String) -> void:
	match v:
		"floor":
			gus.position = Vector3(-3.6, 0, -0.4)
			gus.rotation.y = 0.8
		"hall":
			if not events.has("gus_up"):
				gus.position = HALL + Vector3(1.6, -0.26, -1.3)   # asleep on the sofa
				gus.rotation.y = 0.0
				gus.pose("sit")
				LifeRoomPeople.feel(gus, "calm")
		"outside", "phone_out":
			gus.position = OUTSIDE + Vector3(1.2, 0, 4.9)
			gus.rotation.y = -0.4
			gus.pose("stand")
			LifeRoomPeople.feel(gus, "happy")
		_:
			gus.position = KITCHEN_GUS
			gus.rotation.y = 0.6


func step_started(step: Dictionary) -> void:
	_place_gus(str(step.get("view", start_view)))


func on_event(event: String) -> void:
	match event:
		"juice_cleaner":
			bottles.juice_cleaner.visible = true
		"no_label":
			bottles.no_label.visible = true
		"bottles_up":   # Gus puts the dangerous ones up high, in the cupboard
			var i := 0
			for id: String in ["bleach", "drain_cleaner", "oven_cleaner", "washing_tabs", "pest_killer", "juice_cleaner"]:
				if bottles.has(id):
					(bottles[id] as Node3D).position = Vector3(1.05 + i * 0.17, 1.58, -2.1)
					i += 1
		"lock_click":
			latch.material_override = LifeRoomKit.material(Color("3fbf5a"))
			if is_inside_tree():
				Audio.play(&"plate_click")
		"mo_mix_idea":
			mo.visible = true
			LifeRoomPeople.feel(mo, "happy")
		"stain":
			LifeRoomKit.box(self, "Stain", Vector3(0.5, 0.01, 0.35), Vector3(-0.6, 0.006, -0.9), Color("b08d5a"))
		"battery_away":
			target_node("battery").visible = false
		"co_test_beep":
			_beep_t = 0.0
			if is_inside_tree():
				Audio.play(&"beep")
		"co_alarm_on":
			_alarm = true
			env.background_color = Color("2a3a5a")   # night
			env.ambient_light_energy = 0.45
		"gus_up":
			gus.pose("stand")
			LifeRoomPeople.feel(gus, "happy")
			gus.position = HALL + Vector3(1.0, 0, -0.9)


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"battery":
			target_node("battery").visible = false
		"phone":
			phone.visible = false
			(get_node("HeldPhone") as Node3D).visible = true
		"dial":
			if phone_screen:
				phone_screen.text = "CALLING..."
		"out":
			_alarm = false
			co_light.material_override = LifeRoomKit.material(Color("3fbf5a"))


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			for f: Variant in state.get("found", []):
				var t := str(f)
				if has_target(t) and target_node(t).get_node_or_null("Found") == null:
					LifeRoomKit.sphere(target_node(t), "Found", 0.035, Vector3(0, 0.32, 0), Color(0.3, 0.85, 0.4, 0.9))
		"sequence":
			if phone_screen:
				phone_screen.text = LifeRoom.dialled(step, state)


func _process(delta: float) -> void:
	super(delta)
	if _beep_t >= 0.0:
		_beep_t += delta
		co_light.material_override = LifeRoomKit.material(Color("ff8a5c") if fmod(_beep_t, 0.4) < 0.2 else Color("3fbf5a"),
			fmod(_beep_t, 0.4) < 0.2)
		if _beep_t > 1.2:
			_beep_t = -1.0
			co_light.material_override = LifeRoomKit.material(Color("3fbf5a"))
	if not _alarm:
		return
	_alarm_t += delta
	var on := fmod(_alarm_t, 1.2) < 0.25
	co_light.material_override = LifeRoomKit.material(Color("ff8a5c") if on else Color("4a5468"), on)
	if on and fmod(_alarm_t, 1.2) < delta + 0.001 and is_inside_tree():
		Audio.play(&"beep", Vector3.INF, -2.0 if more_real() else -8.0)   # the gentle default plays it softer


# --- The safe mistake's gentle picture ---------------------------------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if not on or event != "fumes":
		return
	var holder := mistake_holder()
	for b: String in ["bucket_bleach", "toilet_cleaner"]:   # the two bottles, tipped over the bucket, still
		var ghost := LifeRoomKit.box(holder, "Pour_" + b, Vector3(0.1, 0.26, 0.08), Vector3.ZERO,
			Color(1, 1, 1, 0.55) if b == "bucket_bleach" else Color(0.23, 0.48, 0.91, 0.55))
		ghost.position = Vector3(0.2 + (0.12 if b == "bucket_bleach" else -0.12), 0.55, -1.25)
		ghost.rotation.z = 1.2 if b == "bucket_bleach" else -1.2
	for i in 7:   # a soft grey-green cloud, frozen over the bucket
		var a := TAU * i / 7.0
		LifeRoomKit.sphere(holder, "Cloud", 0.12 + 0.03 * (i % 3), Vector3(0.2 + cos(a) * 0.16, 0.5 + 0.08 * (i % 3), -1.25 + sin(a) * 0.12),
			Color(0.62, 0.72, 0.58, 0.55))
	LifeRoomKit.sign(holder, "Gas", "A HARMFUL GAS", Vector3(0.2, 0.95, -1.25), 0.004, Color("ffd23f"))


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A home's kitchen, sitting corner, garden, garage, hall and front: skirting, a ceiling and its lights, a plant, a rug,
## pictures, the hall's rug and coat hooks, the house front's windows and door frame, a flower bed, a soft sky; every
## bottle and its warning sign drawn in two meshes, each place's own boxes in one (the Quest's draws).
func _home_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Land", Vector3(80, 0.1, 60), Vector3(8, -0.14, 0), Color("86c063"), 0.0, LifeRoomDecor.SHELL)
	d.skirting("Skirting", Vector3(-3.5, 0, -2.24), Vector3(3.5, 0, -2.24), Color("c89a62"))
	d.tiled("Ceiling", LifeRoomDecor.TILE, Vector3(7.0, 0.1, 5.4), Vector3(0, 2.65, 0.4), Color("fbf8f2"), 0.8)
	d.ceiling_light("Light", Vector3(-1.2, 2.58, -0.4), 0.28)
	d.ceiling_light("Light", Vector3(1.2, 2.58, -0.4), 0.28)
	d.rug("Rug", Vector3(-3.4, 0.0, -0.75), Vector2(1.6, 1.0), Color("cfe0ee"), Color("7b5cd6"))
	d.picture("Picture", Vector3(-3.4, 1.65, -2.24), Vector2(0.6, 0.45), 0.0, Color("8a6239"), Color("fff6e0"), 0)
	d.plant("Plant", Vector3(3.2, 0, -1.9), 1.0)
	if track == "big":
		d.rug("HallRug", HALL + Vector3(-0.2, 0.0, -0.4), Vector2(1.0, 1.8), Color("e8b04a"), Color("c0563a"))
		for x: float in [-2.2, -1.95]:
			d.box("Hook", Vector3(0.04, 0.04, 0.1), HALL + Vector3(x, 1.65, -1.95), Color("8a6239"))
		d.box("Coat", Vector3(0.26, 0.5, 0.08), HALL + Vector3(-2.1, 1.35, -1.94), Color("3a7be8"))
		for x: float in [-1.8, 1.8]:
			d.window("FrontWindow", OUTSIDE + Vector3(x, 1.55, 1.71), 0.9, 0.8, 0.0, Color("fdfdf8"), Color("ffe9b8"), Color("fff6dc"),
				Color("f3c98a"))
		d.box("DoorFrame", Vector3(1.2, 2.2, 0.04), OUTSIDE + Vector3(0, 1.1, 1.71), Color("8a5a34"))
		d.box("FrontDoor", Vector3(0.95, 2.0, 0.04), OUTSIDE + Vector3(0, 1.0, 1.73), Color("3a7be8"))
		d.bush("FlowerBed", OUTSIDE + Vector3(-2.4, 0, 2.3), 1.0, Color("5aa548"), Color("e85a9a"))
	for id: String in bottles:   # a bottle, its cap and its warning sign never come apart
		LifeRoomPeople.merge_whole(bottles[id] as Node3D)
	for n: String in ["Garden", "Garage"]:
		var place := get_node_or_null(n) as Node3D
		if place != null:
			LifeRoomPeople.merge_parts(self, place)
	if mo != null:
		LifeRoomPeople.merge_person(mo, true)
	if gus != null:
		LifeRoomPeople.merge_person(gus)   # he sits on the hall's sofa and stands again
