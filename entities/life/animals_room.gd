class_name AnimalsRoom
extends LifeRoom
## Owner #118 (docs/design/life-skills.md §14, the catalogue's row 8: animals; Life L3b): Safe with Animals' practice
## places, built for the track: the practice park (Biscuit the dog with his owner, a sleeping dog under the bench, a dog
## without its owner who comes running, the path home), the dog park (Middle: three dogs, one relaxed, one in a play bow,
## one saying "leave me alone": their places vary with the seed), the farm (a horse in its paddock, cows with a calf),
## the picnic (bees, a wasp on a sandwich) and the practice hills (Middle: a snake on the path; Big: the group on the
## path, a bear far across the valley, a fox at the picnic spot, a flock of sheep guarded by big shepherd dogs). Calm:
## friendly blocky animals; a warning dog shows its signs, never a bite or a sound of one; a running dog stops a little
## way off, sniffs and trots back. The safe mistakes' gentle pictures (on_mistake): a figure frozen hugging Biscuit round
## the neck while he turns his head away; a figure frozen running with the dog frozen bounding after it.

const GRASS := Color("8cc56a")
const PATH := Color("d8c9a3")
const WOOD := Color("a8642a")
const WHITE := Color("f4f6f8")
const DOGS_X := -12.0
const DOG_SPOTS: Array[float] = [-1.6, 0.0, 1.6]
const FARM := Vector3(30, 0, 0)
const PICNIC := Vector3(-30, 0, 0)
const HILLS := Vector3(0, 0, -40)
## The running dog stops this far in front of the child (m) and runs at this speed (m/s of the room's time).
const STOP_SHORT := 1.3
const RUN_SPEED := 2.2

var owner_buddy: LifeBuddy
var biscuit: LifeDog
var sleeper: LifeDog
var runner: LifeDog
var guard: LifeDog
var dogs := {}
var horse: Node3D
var cows: Node3D
var bee: MeshInstance3D
var wasp: MeshInstance3D
var snake: Node3D
var fox: Node3D
var bear: Node3D
var mo: LifeBuddy
var phone: Node3D
var phone_screen: Label3D
var warning_x := 0.0
var _run_from := Vector3.ZERO
var _run_to := Vector3.ZERO
var _run_t := -1.0
var _run_back := false
var _runner_dog: LifeDog
var _t := 0.0
var _mood_was := "relaxed"


func build() -> void:
	name = "AnimalsRoom"
	env = LifeRoomKit.environment(Color("a9d6f2"), Color("eef7fc"), 0.75)
	start_view = "hills" if track == "big" else "park"
	if track != "big":
		_park()
		_farm()
		_picnic()
	if track == "middle":
		_dog_park()
	if track != "little":
		_hills()
	_places_look()   # the rooms' look (2026-10-18)
	_views()
	if track == "big":
		var held := view("phone")
		var feet: Vector3 = held.feet
		phone_screen = make_held_phone(Transform3D(Basis(Vector3.UP, float(held.yaw)),
			feet + Vector3(0, EYE, 0) + Basis(Vector3.UP, float(held.yaw)) * Vector3(0, -0.15, -0.45)))


# --- The practice park --------------------------------------------------------------------------------------------------

func _park() -> void:
	decor().tiled("Grass", LifeRoomDecor.GRASS, Vector3(16, 0.1, 14), Vector3(0, -0.05, -2), Color("dcefc8"), 1.0)
	decor().tiled("Path", LifeRoomDecor.SAND, Vector3(16, 0.02, 1.4), Vector3(0, 0.002, 0.9), Color("f2e6cc"), 0.7)
	LifeRoomKit.box(scenery(), "Bench", Vector3(1.4, 0.45, 0.45), Vector3(2.4, 0.225, -3.2), WOOD)
	LifeRoomKit.sign(self, "ParkSign", "PRACTICE PARK", Vector3(-3.0, 2.4, -4.0), 0.006, Color("2f7f6a"))
	LifeRoomKit.light(self, Vector3(0, 4, 0), 0.6, 14.0)
	owner_buddy = LifeBuddy.new(Color("2f9e8f"), "Owner")
	owner_buddy.scale = Vector3.ONE * 1.5
	owner_buddy.position = Vector3(1.45, 0, -1.6)
	owner_buddy.rotation.y = -PI / 2 + 0.5
	owner_buddy.visible = false
	add_child(owner_buddy)
	var om := Node3D.new()
	om.name = "T_owner"
	om.position = Vector3(0, 0.63, 0.1)
	owner_buddy.add_child(om)
	add_target("owner", om, 0.42)
	biscuit = LifeDog.new(LifeDog.COAT, "Biscuit")
	biscuit.position = Vector3(0.35, 0, -1.25)
	biscuit.visible = false
	add_child(biscuit)
	LifeRoomKit.box(self, "Lead", Vector3(0.6, 0.015, 0.015), Vector3(1.0, 0.75, -1.4), Color("e8544e")).visible = false
	add_target("dog_side", biscuit.mark("side"), 0.13)
	add_target("dog_head", biscuit.mark("head"), 0.09)
	add_target("dog_hug", biscuit.mark("neck"), 0.09)
	add_spot_target("hand_low", self, Vector3(0.75, 0.42, -0.95), 0.14)
	sleeper = LifeDog.new(Color("8a6a4a"), "Sleeper")
	sleeper.position = Vector3(2.2, 0, -3.25)
	sleeper.visible = false
	add_child(sleeper)
	sleeper.set_mood("sleep")
	runner = LifeDog.new(Color("9a8f86"), "Runner")
	runner.visible = false
	add_child(runner)
	var home := add_spot_target("run_away", self, Vector3(2.4, 0.05, 0.4), 0.45)
	LifeRoomKit.cylinder(home, "HomeRing", 0.4, 0.02, Vector3(0, -0.03, 0), Color(0.6, 0.62, 0.68, 0.6))
	LifeRoomKit.sign(home, "HomeSign", "RUN HOME", Vector3(0, 0.85, 0), 0.004, Color("6b7a99"))
	home.visible = track != "little"   # Little is told the rule first: no wrong way to try


## Middle: three dogs to read, their places shuffled by the seed (one relaxed, one in a play bow, one saying "leave me
## alone"); the warning one's four signs are targets of their own, shown only for the step that finds them.
func _dog_park() -> void:
	decor().tiled("DogParkGrass", LifeRoomDecor.GRASS, Vector3(7, 0.1, 6), Vector3(DOGS_X, -0.04, -1.8), Color("cfe6b8"), 1.0)
	LifeRoomKit.sign(self, "DogParkSign", "DOG PARK", Vector3(DOGS_X, 1.9, -4.6), 0.005, Color("2f7f6a"))
	var order: Array = range(DOG_SPOTS.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["dogs", int(vars.get("seed", 0))])
	GenKit.shuffle(rng, order)
	var who := [["dog_relaxed", "relaxed", Color("d9a66a")], ["dog_warning", "warning", Color("6b4a32")],
		["dog_play", "play", Color("e3c27a")]]
	for i in who.size():
		var d := LifeDog.new(who[i][2], str(who[i][0]))
		var x := DOGS_X + DOG_SPOTS[int(order[i])]
		d.position = Vector3(x, 0, -2.6)
		d.visible = false
		add_child(d)
		d.set_mood(str(who[i][1]))
		dogs[who[i][0]] = d
		add_spot_target(str(who[i][0]), self, Vector3(x, 0.35, -2.6), 0.32)
		(target_node(str(who[i][0])) as Node3D).visible = false
		if str(who[i][0]) == "dog_warning":
			warning_x = x
	var warn: LifeDog = dogs.dog_warning
	for m: Array in [["sign_body", "body"], ["sign_eyes", "eyes"], ["sign_lips", "lips"], ["sign_tail", "tail"]]:
		var at := _local_of(warn, str(m[1]))
		add_spot_target(str(m[0]), self, at, 0.07)
		(target_node(str(m[0])) as Node3D).visible = false


## A dog's mark in the room's space (the dog stands still: computed once).
func _local_of(dog: LifeDog, mark_name: String) -> Vector3:
	var t := Transform3D.IDENTITY
	var n: Node3D = dog.mark(mark_name)
	while n != null and n != self:
		t = n.transform * t
		n = n.get_parent() as Node3D
		if n == dog:
			t = dog.transform * t
			break
	return t.origin


# --- The farm and the picnic --------------------------------------------------------------------------------------------

func _farm() -> void:
	var f := Node3D.new()
	f.name = "Farm"
	add_child(f)
	decor().tiled("FarmGrass", LifeRoomDecor.GRASS, Vector3(18, 0.1, 14), FARM + Vector3(2, -0.05, -2), Color("dcefc8"), 1.0)
	for x: float in [-3.0, 3.0]:
		LifeRoomKit.box(f, "Rail", Vector3(0.08, 0.9, 4.0), FARM + Vector3(x, 0.45, -3.0), WOOD)
	LifeRoomKit.box(f, "BackRail", Vector3(6.0, 0.9, 0.08), FARM + Vector3(0, 0.45, -5.0), WOOD)
	horse = Node3D.new()
	horse.name = "Horse"
	horse.position = FARM + Vector3(0.6, 0, -2.4)
	f.add_child(horse)
	var coat := Color("8a5a34")
	LifeRoomKit.box(horse, "Body", Vector3(1.5, 0.6, 0.5), Vector3(0, 1.2, 0), coat)
	LifeRoomKit.box(horse, "Neck", Vector3(0.3, 0.7, 0.3), Vector3(-0.75, 1.6, 0), coat)
	LifeRoomKit.box(horse, "Head", Vector3(0.55, 0.25, 0.25), Vector3(-1.0, 1.95, 0), coat.lightened(0.1))
	for e: float in [-0.09, 0.09]:
		LifeRoomKit.box(horse, "Eye", Vector3(0.04, 0.04, 0.02), Vector3(-1.05, 2.0, e * 1.4), Color("1f2a4a"))
	for x: float in [-0.55, 0.55]:
		for z: float in [-0.18, 0.18]:
			LifeRoomKit.box(horse, "Leg", Vector3(0.12, 0.9, 0.12), Vector3(x, 0.45, z), coat.darkened(0.15))
	LifeRoomKit.box(horse, "Tail", Vector3(0.1, 0.6, 0.1), Vector3(0.8, 1.05, 0), Color("3a2a1a"))
	add_spot_target("horse_side", f, FARM + Vector3(-0.2, 0.05, -1.35), 0.42)
	LifeRoomKit.cylinder(f, "SideRing", 0.38, 0.02, FARM + Vector3(-0.2, 0.02, -1.35), Color(0.3, 0.85, 0.4, 0.6))
	add_spot_target("horse_back", f, FARM + Vector3(1.9, 0.05, -2.4), 0.42)
	LifeRoomKit.cylinder(f, "BackRing", 0.38, 0.02, FARM + Vector3(1.9, 0.02, -2.4), Color(0.6, 0.62, 0.68, 0.6))
	LifeRoomKit.sign(f, "FarmSign", "PRACTICE FARM", FARM + Vector3(-2.0, 2.6, -5.0), 0.006, Color("2f7f6a"))
	cows = Node3D.new()
	cows.name = "Cows"
	cows.visible = false
	f.add_child(cows)
	for c: Array in [[FARM + Vector3(5.5, 0, -3.0), 1.0], [FARM + Vector3(7.0, 0, -2.2), 1.0], [FARM + Vector3(6.2, 0, -1.4), 0.55]]:
		var cow := Node3D.new()
		cow.position = c[0]
		cow.scale = Vector3.ONE * float(c[1])
		cows.add_child(cow)
		LifeRoomKit.box(cow, "Body", Vector3(1.3, 0.6, 0.55), Vector3(0, 0.95, 0), WHITE)
		LifeRoomKit.box(cow, "Patch", Vector3(0.4, 0.3, 0.57), Vector3(0.2, 1.0, 0), Color("2b2f38"))
		LifeRoomKit.box(cow, "Head", Vector3(0.35, 0.3, 0.3), Vector3(-0.75, 1.1, 0), WHITE)
		for x: float in [-0.45, 0.45]:
			LifeRoomKit.box(cow, "Leg", Vector3(0.12, 0.65, 0.12), Vector3(x, 0.33, 0.15), Color("2b2f38"))


func _picnic() -> void:
	var g := Node3D.new()
	g.name = "Picnic"
	add_child(g)
	decor().tiled("PicnicGrass", LifeRoomDecor.GRASS, Vector3(10, 0.1, 9), PICNIC + Vector3(0, -0.05, -1.5), Color("dcefc8"), 1.0)
	LifeRoomKit.box(g, "Blanket", Vector3(1.6, 0.02, 1.2), PICNIC + Vector3(0, 0.01, -1.4), Color("e8544e"))
	LifeRoomKit.box(g, "Sandwich", Vector3(0.18, 0.05, 0.12), PICNIC + Vector3(-0.2, 0.05, -1.3), Color("e8c48c"))
	for i in 6:
		LifeRoomKit.sphere(g, "Flower", 0.06, PICNIC + Vector3(1.6 + (i % 3) * 0.25, 0.3, -2.6 - (i / 3) * 0.25),
			[Color("ffd23f"), Color("e85a9a"), Color("9b7fd6")][i % 3])
	bee = LifeRoomKit.sphere(g, "Bee", 0.035, PICNIC + Vector3(0.2, 0.5, -1.4), Color("ffd23f"))
	bee.visible = false
	wasp = LifeRoomKit.box(g, "Wasp", Vector3(0.05, 0.03, 0.03), PICNIC + Vector3(-0.2, 0.1, -1.3), Color("ffd23f"))
	wasp.visible = false
	for b: Array in [["Bobo", Color("1fa6a0"), PICNIC + Vector3(-0.9, 0, -1.6)], ["PipPop", Color("e85a9a"), PICNIC + Vector3(0.7, 0, -1.9)]]:
		var buddy := LifeBuddy.new(b[1], str(b[0]))
		buddy.position = b[2]
		buddy.rotation.y = 0.4 if str(b[0]) == "Bobo" else -0.4
		g.add_child(buddy)
		buddy.pose("sit_floor")
		LifeRoomPeople.feel(buddy, "happy")
	LifeRoomKit.sign(g, "PicnicSign", "PICNIC", PICNIC + Vector3(-2.0, 1.8, -3.0), 0.005, Color("2f7f6a"))


# --- The practice hills (Middle: the snake; Big: the walk) --------------------------------------------------------------

func _hills() -> void:
	var h := Node3D.new()
	h.name = "Hills"
	add_child(h)
	decor().tiled("Meadow", LifeRoomDecor.GRASS, Vector3(30, 0.1, 26), HILLS + Vector3(2, -0.05, -6), Color("e2f0cc"), 1.0)
	decor().tiled("HillPath", LifeRoomDecor.SAND, Vector3(1.4, 0.02, 14), HILLS + Vector3(0, 0.002, -4), Color("f2e6cc"), 0.7)
	for m: Array in [[Vector3(-10, 3, -18), Vector3(14, 6, 6)], [Vector3(8, 4.5, -24), Vector3(16, 9, 6)], [Vector3(-2, 6, -30), Vector3(20, 12, 6)]]:
		LifeRoomKit.box(h, "Hillside", m[1], HILLS + m[0], Color("7aa36a").darkened(0.1 * (m[0] as Vector3).y / 6.0))
	# lower, smaller (higher it sat half under the HUD's bar in the first view)
	LifeRoomKit.sign(h, "HillsSign", "PRACTICE HILLS", HILLS + Vector3(-2.0, 1.85, -2.0), 0.0045, Color("2f7f6a"))
	snake = Node3D.new()
	snake.name = "Snake"
	snake.position = HILLS + (Vector3(3.4, 0.03, -7.0) if track == "big" else Vector3(0.0, 0.03, -3.0))
	snake.visible = false
	h.add_child(snake)
	for i in 7:
		LifeRoomKit.box(snake, "Bit", Vector3(0.12, 0.06, 0.08), Vector3(-0.36 + i * 0.12, 0.0, 0.07 * (1 if i % 2 == 0 else -1)),
			Color("6d8a1f"))
	add_target("snake", snake, 0.35)
	var back := HILLS + (Vector3(1.8, 0.05, -5.6) if track == "big" else Vector3(-1.6, 0.05, -1.6))
	add_spot_target("step_back", h, back, 0.45)
	LifeRoomKit.cylinder(h, "RoundRing", 0.4, 0.02, back + Vector3(0, -0.03, 0), Color(0.3, 0.85, 0.4, 0.6))
	LifeRoomKit.sign(h, "RoundSign", "GO ROUND", back + Vector3(0, 0.9, 0), 0.004, Color("2fae4e"))
	if track != "big":
		return
	for b: Array in [["Gus", Color("7b5cd6"), Vector3(1.2, 0, -1.2), 1.55], ["PipPop", Color("e85a9a"), Vector3(-0.9, 0, -1.6), 1.0],
			["Bobo", Color("1fa6a0"), Vector3(1.9, 0, -2.4), 1.0]]:
		var buddy := LifeBuddy.new(b[1], str(b[0]))
		buddy.position = HILLS + (b[2] as Vector3)
		buddy.scale = Vector3.ONE * float(b[3])
		h.add_child(buddy)
		LifeRoomPeople.feel(buddy, "happy")
	add_spot_target("clap", h, HILLS + Vector3(0.0, 1.0, 0.0), 0.25)
	bear = Node3D.new()
	bear.name = "Bear"
	bear.position = HILLS + Vector3(8, 6.1, -24)
	bear.visible = false
	h.add_child(bear)
	LifeRoomKit.box(bear, "Body", Vector3(1.6, 0.9, 0.8), Vector3(0, 0.6, 0), Color("6b4a32"))
	LifeRoomKit.box(bear, "Head", Vector3(0.5, 0.45, 0.45), Vector3(-0.95, 0.85, 0), Color("6b4a32").lightened(0.1))
	# the picnic spot in the hills
	var camp := HILLS + Vector3(-8, 0, 2)
	LifeRoomKit.box(h, "Blanket", Vector3(1.6, 0.02, 1.2), camp + Vector3(0, 0.01, -1.2), Color("3a7be8"))
	LifeRoomKit.box(h, "Food", Vector3(0.3, 0.08, 0.2), camp + Vector3(-0.3, 0.05, -1.1), Color("e8c48c"))
	mo = LifeBuddy.new(Color("ffb347"), "Mo")
	mo.position = camp + Vector3(-0.7, 0, -1.4)
	mo.rotation.y = 0.5
	h.add_child(mo)
	mo.pose("sit_floor")
	LifeRoomPeople.feel(mo, "happy")
	phone = Node3D.new()
	phone.name = "Phone"
	phone.position = camp + Vector3(0.45, 0.04, -0.9)
	h.add_child(phone)
	LifeRoomKit.box(phone, "Body", Vector3(0.16, 0.03, 0.28), Vector3.ZERO, Color("1f2a4a"))
	add_target("phone", phone, 0.18)
	fox = Node3D.new()
	fox.name = "Fox"
	fox.position = camp + Vector3(1.6, 0, -1.8)
	fox.visible = false
	h.add_child(fox)
	LifeRoomKit.box(fox, "Body", Vector3(0.5, 0.2, 0.18), Vector3(0, 0.3, 0), Color("ff7a2e"))
	LifeRoomKit.box(fox, "Head", Vector3(0.18, 0.15, 0.15), Vector3(-0.3, 0.38, 0), Color("ff7a2e"))
	LifeRoomKit.box(fox, "Tail", Vector3(0.3, 0.1, 0.1), Vector3(0.38, 0.32, 0), Color("fdfdf8"))
	# the flock and its shepherd dogs
	var flock := HILLS + Vector3(8.5, 0, -8.5)
	for i in 7:
		LifeRoomKit.box(h, "Sheep", Vector3(0.6, 0.4, 0.35), flock + Vector3(-1.2 + (i % 4) * 0.8, 0.45, -0.6 + (i / 4) * 0.9),
			Color("f2efe6"))
	for d: Array in [[flock + Vector3(-1.6, 0, 0.9), "Guard"], [flock + Vector3(1.8, 0, -1.0), "Guard2"]]:
		var dog := LifeDog.new(Color("eae4d6"), str(d[1]), 1.5)
		dog.position = d[0]
		dog.rotation.y = PI * 0.8
		h.add_child(dog)
		if guard == null:
			guard = dog
	add_spot_target("flock_near", h, HILLS + Vector3(7.4, 0.05, -6.4), 0.5)
	LifeRoomKit.cylinder(h, "NearRing", 0.45, 0.02, HILLS + Vector3(7.4, 0.02, -6.4), Color(0.6, 0.62, 0.68, 0.6))
	add_spot_target("flock_far", h, HILLS + Vector3(2.6, 0.05, -7.5), 0.5)
	LifeRoomKit.cylinder(h, "FarRing", 0.45, 0.02, HILLS + Vector3(2.6, 0.02, -7.5), Color(0.3, 0.85, 0.4, 0.6))
	add_spot_target("run_away", h, HILLS + Vector3(4.4, 0.05, -3.4), 0.45)
	LifeRoomKit.cylinder(h, "RunRing", 0.4, 0.02, HILLS + Vector3(4.4, 0.02, -3.4), Color(0.6, 0.62, 0.68, 0.6))
	LifeRoomKit.sign(h, "RunSign", "RUN", HILLS + Vector3(4.4, 0.9, -3.4), 0.004, Color("6b7a99"))
	add_spot_target("back_away", h, HILLS + Vector3(3.4, 0.05, -4.6), 0.45)
	LifeRoomKit.cylinder(h, "BackRing", 0.4, 0.02, HILLS + Vector3(3.4, 0.02, -4.6), Color(0.3, 0.85, 0.4, 0.6))


func _views() -> void:
	add_view("park", Vector3(0, 1.6, 3.6), Vector3(0, 0.6, -2.0), Vector3(0, 0, 2.0), 0.0)
	add_view("dog", Vector3(0.5, 1.3, 0.45), Vector3(0.55, 0.4, -1.25), Vector3(0.5, 0, -0.35), 0.0)
	add_view("dogs", Vector3(DOGS_X, 1.4, 1.2), Vector3(DOGS_X, 0.4, -2.6), Vector3(DOGS_X, 0, 0.4), 0.0)
	add_view("warning", Vector3(warning_x - 0.1, 0.95, -1.3), Vector3(warning_x, 0.38, -2.6), Vector3(warning_x, 0, -1.7), 0.0)
	add_view("farm", FARM + Vector3(0, 1.6, 2.6), FARM + Vector3(0.6, 0.7, -2.4), FARM + Vector3(0, 0, 1.2), 0.0)
	add_view("picnic", PICNIC + Vector3(0, 1.5, 1.6), PICNIC + Vector3(0, 0.3, -1.6), PICNIC + Vector3(0, 0, 0.6), 0.0)
	add_view("hills", HILLS + Vector3(0, 1.6, 1.6), HILLS + Vector3(0, 0.6, -4.0), HILLS + Vector3(0, 0, 0.6), 0.0)
	var back := HILLS + (Vector3(1.8, 0, -5.6) if track == "big" else Vector3(-1.6, 0, -1.6))
	var ahead := HILLS + (Vector3(3.2, 0.3, -8.4) if track == "big" else Vector3(-0.4, 0.3, -4.0))
	add_view("step_back", back + Vector3(0, 1.5, 1.0), ahead, back, 0.0)
	add_view("ridge", HILLS + Vector3(0, 1.7, 0.8), HILLS + Vector3(6.0, 3.6, -20.0), HILLS + Vector3(0, 0, 0.6), 0.0)
	add_view("camp", HILLS + Vector3(-8, 1.5, 3.8), HILLS + Vector3(-7.6, 0.3, 0.6), HILLS + Vector3(-8, 0, 3.0), 0.0)
	add_view("phone", HILLS + Vector3(-8, 1.15, 3.8), HILLS + Vector3(-8, 1.0, 2.5), HILLS + Vector3(-8, 0, 3.0), 0.0)
	add_view("flock", HILLS + Vector3(6.0, 1.6, -1.0), HILLS + Vector3(6.0, 0.5, -8.0), HILLS + Vector3(6.0, 0, -2.2), 0.0)
	add_view("back_away", HILLS + Vector3(3.4, 1.5, -3.6), HILLS + Vector3(3.5, 0.3, -8.0), HILLS + Vector3(3.4, 0, -4.6), 0.0)


# --- Events -------------------------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"dog_with_owner":
			owner_buddy.visible = true
			biscuit.visible = true
			biscuit.set_mood("relaxed")
			(get_node("Lead") as Node3D).visible = true
		"dog_sleeping":
			sleeper.visible = true
		"loose_dog":
			_run(runner, Vector3(-3.0, 0, -3.0), Vector3(0, 0, 2.0 - STOP_SHORT))
		"dog_leaves":
			_run_home()
		"three_dogs":
			for id: String in dogs:
				(dogs[id] as Node3D).visible = true
				target_node(id).visible = true
		"cows":
			cows.visible = true
		"bee_buzz":
			bee.visible = true
		"wasp_buzz":
			wasp.visible = true
		"snake_on_path":
			snake.visible = true
		"bear_far":
			bear.visible = true
		"fox_near":
			fox.visible = true
		"guard_dog_comes":
			_run(guard, guard.position, HILLS + Vector3(6.5, 0, -2.2 - STOP_SHORT))
		"guard_dog_comes_r":
			_run(guard, HILLS + Vector3(2.2, 0, -6.0), HILLS + Vector3(5.4, 0, -2.2 - STOP_SHORT))
		"guard_dog_back":
			_run_home()
		"mo_stung":
			if mo:
				LifeRoomPeople.feel(mo, "worried")


func step_started(step: Dictionary) -> void:
	if str(step.get("id", "")) == "signs":   # the warning dog's four signs: targets for this step only
		target_node("dog_warning").visible = false
		for t: String in ["sign_body", "sign_eyes", "sign_lips", "sign_tail"]:
			target_node(t).visible = true


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"read":
			for id: String in dogs:
				target_node(id).visible = false
		"signs":
			for t: String in ["sign_body", "sign_eyes", "sign_lips", "sign_tail"]:
				target_node(t).visible = false
		"stroke":
			biscuit.wag = 1.0
		"bees", "wasp":
			bee.visible = false
			wasp.visible = false
		"snake":
			if snake:
				snake.position += Vector3(-1.5, 0, -1.2)   # it slides off into the grass
		"phone":
			phone.visible = false
			(get_node("HeldPhone") as Node3D).visible = true
		"dial":
			if phone_screen:
				phone_screen.text = "CALLING..."
		"fox":
			if fox:
				fox.position += Vector3(3.0, 0, -2.0)


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			for f: Variant in state.get("found", []):
				var t := str(f)
				if has_target(t) and target_node(t).get_node_or_null("Found") == null:
					LifeRoomKit.sphere(target_node(t), "Found", 0.03, Vector3(0, 0.1, 0), Color(0.3, 0.85, 0.4, 0.9))
		"sequence":
			if phone_screen:
				phone_screen.text = LifeRoom.dialled(step, state)


## A dog runs from `from` to `to` by the room's own time (slow on a danger moment's first tries), then sniffs.
func _run(dog: LifeDog, from: Vector3, to: Vector3) -> void:
	if dog == null:
		return
	_runner_dog = dog
	_run_from = from
	_run_to = to
	_run_t = 0.0
	_run_back = false
	dog.visible = true
	dog.position = from
	dog.rotation.y = -Vector2(to.x - from.x, to.z - from.z).angle()
	dog.set_mood("relaxed")


## It got bored: back to where it came from, trotting.
func _run_home() -> void:
	if _runner_dog == null:
		return
	var at := _runner_dog.position
	_run_to = _run_from
	_run_from = at
	_run_t = 0.0
	_run_back = true
	_runner_dog.set_mood("relaxed")
	_runner_dog.rotation.y = -Vector2(_run_to.x - at.x, _run_to.z - at.z).angle()


func _process(delta: float) -> void:
	super(delta)
	var dt := sim_delta(delta)
	_t += dt
	if biscuit and biscuit.visible:
		biscuit.wag_tail(_t)
	if bee and bee.visible:
		bee.position = PICNIC + Vector3(0.2 + 0.25 * cos(_t * 2.0), 0.5 + 0.05 * sin(_t * 5.0), -1.4 + 0.25 * sin(_t * 2.0))
	if _run_t >= 0.0 and _runner_dog != null:
		var length := maxf(_run_from.distance_to(_run_to), 0.01)
		_run_t = minf(_run_t + dt * RUN_SPEED * (0.6 if _run_back else 1.0) / length, 1.0)
		_runner_dog.position = _run_from.lerp(_run_to, _run_t)
		_runner_dog.wag_tail(_t)
		if _run_t >= 1.0:
			_run_t = -1.0
			if _run_back:
				_runner_dog.visible = _runner_dog == guard
			else:
				_runner_dog.set_mood("sniff")


# --- The safe mistakes' gentle pictures ---------------------------------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if event == "dog_uneasy" and biscuit:
		if on:
			_mood_was = biscuit.mood
			biscuit.set_mood("uneasy")
		else:
			biscuit.set_mood(_mood_was)
	if not on:
		return
	var holder := mistake_holder()
	match event:
		"dog_uneasy":   # a figure frozen hugging Biscuit round the neck: he turns his head away, ears flat
			var hugger := LifeBuddy.new(Color(0.18, 0.5, 0.42, 1.0), "Hugger")
			hugger.position = biscuit.position + Vector3(0.45, 0, 0.35)
			hugger.rotation.y = PI * 0.8
			holder.add_child(hugger)
			LifeRoomPeople.feel(hugger, "happy")
			hugger.arm_near.rotation = Vector3(-1.4, 0, 0)
			hugger.arm_far.rotation = Vector3(-1.4, 0, 0)
			LifeRoomKit.sign(holder, "Why", "A HUG CAN FEEL LIKE A TRAP", biscuit.position + Vector3(0.3, 1.4, 0), 0.004,
				Color("ffd23f"))
		"dog_chase":   # a figure frozen mid-run, a dog frozen bounding after it, like a game of chase
			var at: Vector3 = target_position("run_away") - global_position
			var runner_fig := LifeBuddy.new(Color(0.18, 0.5, 0.42, 1.0), "Running")
			runner_fig.position = at + Vector3(0, 0, 0)
			runner_fig.rotation.y = -PI / 2
			holder.add_child(runner_fig)
			LifeRoomPeople.feel(runner_fig, "worried")
			runner_fig.arm_near.rotation = Vector3(0.6, 0, 0)
			runner_fig.arm_far.rotation = Vector3(-0.6, 0, 0)
			var chaser := LifeDog.new(Color("9a8f86") if track != "big" else Color("eae4d6"), "Chaser", 1.0 if track != "big" else 1.5)
			chaser.position = at + Vector3(-1.2, 0, -0.3)
			holder.add_child(chaser)
			chaser.set_mood("play")
			LifeRoomKit.sign(holder, "Why", "RUNNING MAKES IT CHASE", at + Vector3(-0.5, 1.6, 0), 0.0045, Color("ffd23f"))


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The park's trees, flower beds and fence; the dog park's fence and water bowl (Middle); the farm's barn, hay and trees;
## the picnic's trees; the hills' trees and rocks; one grassy land under every place and a soft sky. The places' own
## boxes, the horse, the cows, the snake, the fox and the bear in one mesh each, every dog in few, the people in few.
func _places_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Land", Vector3(140, 0.1, 130), Vector3(0, -0.14, -20), Color("86c063"), 0.0, LifeRoomDecor.SHELL)
	if track != "big":
		# the park
		for t: Vector3 in [Vector3(-6.5, 0, -6.5), Vector3(5.8, 0, -6.8), Vector3(-7.2, 0, -1.8), Vector3(7.0, 0, -2.6)]:
			d.tree("ParkTree", t, 1.3)
		d.bush("ParkFlowers", Vector3(-4.4, 0, -4.6), 0.9, Color("5aa548"), Color("e85a9a"))
		d.bush("ParkFlowers", Vector3(4.6, 0, -5.0), 0.9, Color("5aa548"), Color("ffc93c"))
		d.fence("ParkFence", Vector3(-8.0, 0, -8.8), Vector3(8.0, 0, -8.8), Color("fdfaf2"), 0.8)
		# the farm
		d.house("Barn", FARM + Vector3(-5.5, 0, -6.5), Vector3(3.6, 2.6, 3.0), 0.0, Color("c0563a"), Color("8a3a2a"), Color("fdfaf2"), 0)
		for i in 3:
			d.cylinder("Hay", 0.45, 0.8, FARM + Vector3(4.2 + i * 1.0, 0.45, -6.4), Color("e8c84a"), -1.0, 14)
		for t: Vector3 in [Vector3(8.5, 0, -7.5), Vector3(-7.0, 0, -1.0)]:
			d.tree("FarmTree", FARM + t, 1.4)
		# the picnic
		for t: Vector3 in [Vector3(-3.8, 0, -4.6), Vector3(3.8, 0, -5.0), Vector3(-4.4, 0, 1.6)]:
			d.tree("PicnicTree", PICNIC + t, 1.3)
	if track == "middle":
		d.fence("DogParkFence", Vector3(DOGS_X - 3.5, 0, -4.8), Vector3(DOGS_X + 3.5, 0, -4.8), Color("8a6239"), 0.9)
		d.cylinder("DogBowl", 0.14, 0.08, Vector3(DOGS_X + 2.6, 0.04, -3.6), Color("3a7be8"), 0.11)
	if track != "little":
		# the hills: trees and rocks by the path
		for t: Vector3 in [Vector3(-4.5, 0, -6.0), Vector3(-6.5, 0, -11.0), Vector3(12.5, 0, -12.0), Vector3(-11.0, 0, -4.0)]:
			d.tree("HillTree", HILLS + t, 1.4, Color("4f9a3e"))
		for r: Vector3 in [Vector3(-2.2, 0, -8.5), Vector3(5.0, 0, -12.5)]:
			d.ball("Rock", 0.45, HILLS + r + Vector3(0, 0.2, 0), Color("a8a39a"), Vector3(1.3, 0.7, 1.0))
	for place: Node3D in [get_node_or_null("Farm") as Node3D, get_node_or_null("Picnic") as Node3D,
			get_node_or_null("Hills") as Node3D, horse, snake, fox, bear]:
		if place != null:
			LifeRoomPeople.merge_parts(self, place)
	if cows != null:
		LifeRoomPeople.merge_whole(cows)   # three cows that only come into view together
	var moving: Array = [biscuit, runner, guard]   # they wag, run and change mood; the others keep the mood they were given
	for n: Node in find_children("*", "Node3D", true, false):
		if n is LifeDog:
			LifeRoomPeople.merge_dog(n as LifeDog, not moving.has(n))
		elif n is LifeBuddy:
			LifeRoomPeople.merge_person(n as LifeBuddy, true)   # they stand or sit as built; their faces still change
