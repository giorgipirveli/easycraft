class_name PracticeHouse
extends LifeRoom
## Owner #112 (docs/design/life-skills.md §5 #2, §6): Fire Escape's practice house: a bedroom, a living room with its
## kitchen corner, and the garden with the meeting point (the big tree) where both ways out lead. Calm and clearly
## practice: the smoke alarm beeps softly, the smoke is a soft grey haze under the ceiling, no fire is ever shown inside;
## the Big track's small fire is a cartoon flame in a metal bin, outside, with the way out behind the child.
## Little: the hazard hunt (12 things that could start a fire: each found gets a green tick) and a simple drill. Middle and
## Big: the night escape from the bedroom (a door to check with the back of the hand, warm on the Expert try), the garden
## phone, stop, drop and roll; Big: PASS on the bin fire.

const WALL := Color("f1e4cc")
const BEDROOM := Color("dfe7f5")
const FLOOR := Color("c9a273")
const GRASS := Color("8cc56a")
const WOOD := Color("a8642a")
const DOOR := Color("8a5a34")
const H := 2.6
const TREE := Vector3(3, 0, -5.5)
const BIN := Vector3(7.5, 0, -1.5)

var smoke: MeshInstance3D
var alarm_light: MeshInstance3D
var doors := {}   # name -> {pivot: Node3D, panel: MeshInstance3D, open: float}
var ticks := {}
var phone: Node3D
var phone_screen: Label3D
var flame: Node3D
var spray: MeshInstance3D
var extinguisher: Node3D
var boxes: Node3D
## Life L3b (owner #118): Gus (Little: tell a grown-up about matches) and the campfire (Middle).
var gus: LifeBuddy
var camp: Node3D
var camp_flame: Node3D
var _alarm := false
var _alarm_t := 0.0
const CAMP := Vector3(8.0, 0, -5.2)


func build() -> void:
	name = "PracticeHouse"
	env = LifeRoomKit.environment(Color("8ec5f0"), Color("e9f3fb"), 0.6)
	start_view = "room" if track == "little" else "bed"
	_garden()
	_house()
	_doors()
	_furniture()
	if track == "little":
		_hazards()
	_phone()
	if track == "big":
		_bin()
	if track == "little":
		_gus()
	if track == "middle":
		_campfire()
	smoke = LifeRoomKit.box(self, "Smoke", Vector3(8.8, 0.9, 3.9), Vector3(-0.5, 2.1, 0), Color(0.6, 0.62, 0.68, 0.5))
	smoke.visible = false
	_house_look()   # the rooms' look (2026-10-18)
	if gus != null:
		LifeRoomPeople.merge_person(gus, true)   # the Quest's draws: Gus never changes pose
	_views()
	var held := view("phone_garden")
	var feet: Vector3 = held.feet
	phone_screen = make_held_phone(Transform3D(Basis(Vector3.UP, float(held.yaw)),
		feet + Vector3(0, EYE, 0) + Basis(Vector3.UP, float(held.yaw)) * Vector3(0, -0.15, -0.45)))


func _garden() -> void:
	var d := decor()   # the rooms' look: the garden in the game's grass, hedges, the big meeting tree
	d.tiled("Grass", LifeRoomDecor.GRASS, Vector3(22, 0.1, 18), Vector3(2, -0.06, -1), Color("dcefc8"), 1.0)
	d.ground_around("Field", Rect2(-9, -10, 22, 18), 80.0, -0.04, Color("86c063"))
	for p: Vector3 in [Vector3(-8, 0, -6), Vector3(11, 0, -7), Vector3(11, 0, 6), Vector3(-8, 0, 6)]:
		d.tiled("Hedge", LifeRoomDecor.HEDGE, Vector3(2.0, 1.0, 0.8), p + Vector3(0, 0.5, 0), Color.WHITE, 0.9)
	d.cylinder("Trunk", 0.22, 2.0, TREE + Vector3(0, 1.0, 0), Color("8a5a34"), 0.17, 8)
	d.ball("Crown", 1.3, TREE + Vector3(0, 2.6, 0), Color("4f9a3e"), Vector3(1.0, 0.85, 1.0))
	d.ball("Crown2", 0.85, TREE + Vector3(0.55, 3.25, 0.2), Color("5aa548"))
	# out from the trunk, clear of the crown (turned to the eye, it sank into the trunk; from above the crown hid it)
	LifeRoomKit.sign(self, "MeetSign", "MEETING POINT", TREE + Vector3(0, 0.95, 1.5), 0.005)
	add_spot_target("meeting_point", self, TREE + Vector3(0.8, 0.05, 1.0), 0.6)
	LifeRoomKit.cylinder(self, "MeetRing", 0.55, 0.02, TREE + Vector3(0.8, 0.01, 1.0), Color(1, 1, 1, 0.7))
	LifeRoomKit.light(self, Vector3(3, 5, -2), 0.8, 14.0)


func _house() -> void:
	var d := decor()   # the rooms' look: plank floors, the bedroom's carpet
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(9, 0.05, 4), Vector3(-0.5, 0.0, 0), Color("f3dcc0"), 0.75)
	d.box("BedFloor", Vector3(3.9, 0.06, 3.9), Vector3(-3, 0.005, 0), BEDROOM.darkened(0.15), 0.0, LifeRoomDecor.SHELL)
	var sc := scenery()
	LifeRoomKit.box(sc, "CeilingBed", Vector3(4, 0.1, 4), Vector3(-3, H + 0.05, 0), Color("fbf8f2"))
	if track != "little":   # the hazard hunt's living room is a cut-away doll's house: seen whole from above
		LifeRoomKit.box(sc, "CeilingLiving", Vector3(5, 0.1, 4), Vector3(1.5, H + 0.05, 0), Color("fbf8f2"))
	# the bedroom (x -5..-1) and the living room (x -1..4)
	LifeRoomKit.box(sc, "WallW", Vector3(0.1, H, 4), Vector3(-5, H / 2, 0), BEDROOM)
	LifeRoomKit.box(sc, "WallBedS", Vector3(4, H, 0.1), Vector3(-3, H / 2, 2), BEDROOM)
	LifeRoomKit.box(sc, "WallBedN1", Vector3(1.5, H, 0.1), Vector3(-4.25, H / 2, -2), BEDROOM)
	LifeRoomKit.box(sc, "WallBedN2", Vector3(1.5, H, 0.1), Vector3(-1.75, H / 2, -2), BEDROOM)
	LifeRoomKit.box(sc, "WallBedNTop", Vector3(1.0, 0.5, 0.1), Vector3(-3.0, H - 0.25, -2), BEDROOM)
	LifeRoomKit.box(sc, "WallMid1", Vector3(0.1, H, 1.5), Vector3(-1, H / 2, -1.25), WALL)
	LifeRoomKit.box(sc, "WallMid2", Vector3(0.1, H, 1.5), Vector3(-1, H / 2, 1.25), WALL)
	LifeRoomKit.box(sc, "WallMidTop", Vector3(0.1, 0.5, 1.0), Vector3(-1, H - 0.25, 0), WALL)
	LifeRoomKit.box(sc, "WallLivN", Vector3(5, H, 0.1), Vector3(1.5, H / 2, -2), WALL)
	if track != "little":
		LifeRoomKit.box(sc, "WallLivS", Vector3(5, H, 0.1), Vector3(1.5, H / 2, 2), WALL)
	LifeRoomKit.box(sc, "WallE1", Vector3(0.1, H, 1.5), Vector3(4, H / 2, -1.25), WALL)
	LifeRoomKit.box(sc, "WallE2", Vector3(0.1, H, 1.5), Vector3(4, H / 2, 1.25), WALL)
	LifeRoomKit.box(sc, "WallETop", Vector3(0.1, 0.5, 1.0), Vector3(4, H - 0.25, 0), WALL)
	LifeRoomKit.light(self, Vector3(1.5, 2.3, 0), 1.0, 6.0)
	LifeRoomKit.light(self, Vector3(-3, 2.3, 0), 0.8, 5.0)
	var alarm := LifeRoomKit.cylinder(self, "Alarm", 0.1, 0.05, Vector3(1.5, H - 0.03, 0) if track != "little"
		else Vector3(0.8, 1.85, -1.92), Color.WHITE)
	if track == "little":
		alarm.rotation.x = PI / 2   # on the wall: there is no ceiling in the doll's house
	alarm_light = LifeRoomKit.sphere(alarm, "AlarmLight", 0.02, Vector3(0.05, -0.03, 0.04), Color("4a5468"))
	if track == "little":
		add_target("hz_alarm", alarm, 0.2)
	# lower, over the front door, smaller (higher up it sat half under the HUD's bar in every first view)
	LifeRoomKit.sign(self, "PracticeSign", "PRACTICE HOUSE", Vector3(4.3, 2.22, 0), 0.0042, Color.WHITE, PI / 2)


## Doors hinge open on their pivot; their target is the panel's middle (a forgiving radius: a door is big).
func _doors() -> void:
	_door("door_hall", Vector3(-1, 0, -0.5), -PI / 2, true)
	_door("door_garden", Vector3(-3.5, 0, -2), 0.0, false)
	_door("door_front", Vector3(4, 0, -0.5), -PI / 2, false)
	add_spot_target("front_door", self, Vector3(3.4, 0.05, 0), 0.55)
	LifeRoomKit.cylinder(self, "FrontRing", 0.45, 0.02, Vector3(3.4, 0.03, 0), Color(0.3, 0.85, 0.4, 0.6))
	if track == "little":
		add_spot_target("garden_door", self, Vector3(-3, 0.05, -1.4), 0.55)
		LifeRoomKit.cylinder(self, "GardenRing", 0.45, 0.02, Vector3(-3, 0.03, -1.4), Color(0.3, 0.85, 0.4, 0.6))
	boxes = Node3D.new()
	boxes.name = "Boxes"
	boxes.visible = false
	add_child(boxes)
	for i in 3:
		LifeRoomKit.box(boxes, "Box", Vector3(0.6, 0.5, 0.6), Vector3(3.5 - i * 0.1, 0.25 + i * 0.5, -0.1 + i * 0.15), Color("c9a063"))


func _door(door_name: String, hinge: Vector3, yaw: float, is_target: bool) -> void:
	var pivot := Node3D.new()
	pivot.name = door_name
	pivot.position = hinge
	pivot.rotation.y = yaw
	add_child(pivot)
	var panel := LifeRoomKit.box(pivot, "Panel", Vector3(1.0, 2.05, 0.06), Vector3(0.5, 1.03, 0), DOOR)
	LifeRoomKit.sphere(panel, "Knob", 0.04, Vector3(0.38, 0.0, 0.05), Color("ffc93c"))
	doors[door_name] = {"pivot": pivot, "panel": panel, "yaw": yaw}
	if is_target or door_name == "door_garden":
		add_target(door_name, panel, 0.5)


func _furniture() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "Bed", Vector3(1.0, 0.45, 2.0), Vector3(-4.3, 0.23, 0.6), Color("7b8ed6"))
	LifeRoomKit.box(sc, "Pillow", Vector3(0.7, 0.12, 0.35), Vector3(-4.3, 0.52, -0.2), Color.WHITE)
	LifeRoomKit.box(sc, "Sofa", Vector3(1.8, 0.45, 0.8), Vector3(1.0, 0.23, 1.5), Color("d9437a").darkened(0.15))
	LifeRoomKit.box(sc, "SofaBack", Vector3(1.8, 0.45, 0.2), Vector3(1.0, 0.68, 1.85), Color("d9437a").darkened(0.25))
	LifeRoomKit.box(sc, "Table", Vector3(1.0, 0.45, 0.6), Vector3(1.0, 0.23, 0.2), WOOD)
	LifeRoomKit.box(sc, "Worktop", Vector3(2.4, 0.9, 0.6), Vector3(2.5, 0.45, -1.65), Color("e2e6ea"))
	LifeRoomKit.box(sc, "Hob", Vector3(0.6, 0.03, 0.5), Vector3(3.2, 0.915, -1.65), Color("3b3f4a"))
	LifeRoomKit.box(sc, "Curtain", Vector3(0.9, 1.6, 0.05), Vector3(-0.3, 1.4, -1.9), Color("e8b04a"))
	LifeRoomKit.box(sc, "Heater", Vector3(0.9, 0.6, 0.12), Vector3(-0.3, 0.4, 1.9), Color("f6f2ea"))


## The hazard hunt's twelve things, each with its own target; a found one gets a green tick (progress).
func _hazards() -> void:
	var at := {
		"hz_pan": Vector3(3.3, 1.0, -1.45), "hz_cooker_towel": Vector3(2.75, 0.96, -1.5),
		"hz_toaster": Vector3(1.9, 1.02, -1.7), "hz_candle": Vector3(-0.1, 0.62, -1.6),
		"hz_heater": Vector3(-0.3, 0.75, 1.85), "hz_plugs": Vector3(3.9, 0.35, 1.2),
		"hz_iron": Vector3(1.2, 0.5, 0.2), "hz_matches": Vector3(0.75, 0.47, 0.25),
		"hz_lighter": Vector3(0.6, 0.48, 1.4), "hz_lamp": Vector3(2.4, 1.2, 1.6), "hz_charger": Vector3(1.6, 0.5, 1.45)}
	var pan := LifeRoomKit.cylinder(self, "Pan", 0.14, 0.08, at.hz_pan, Color("4a5468"))
	LifeRoomKit.box(pan, "Handle", Vector3(0.3, 0.03, 0.04), Vector3(0.0, 0.02, 0.2), Color("2b2f38"), PI / 2)
	add_target("hz_pan", pan, 0.25)
	add_target("hz_cooker_towel", LifeRoomKit.box(self, "TeaTowel", Vector3(0.25, 0.02, 0.35), at.hz_cooker_towel,
		Color("e8544e").lightened(0.3)), 0.22)
	var toaster := LifeRoomKit.box(self, "Toaster", Vector3(0.25, 0.2, 0.15), at.hz_toaster, Color("c0c8d2"))
	LifeRoomKit.box(toaster, "Paper", Vector3(0.2, 0.25, 0.01), Vector3(0.0, 0.05, 0.1), Color.WHITE)
	add_target("hz_toaster", toaster, 0.22)
	var candle := LifeRoomKit.cylinder(self, "Candle", 0.04, 0.2, at.hz_candle, Color.WHITE)
	LifeRoomKit.sphere(candle, "Flame", 0.03, Vector3(0, 0.13, 0), Color(1.0, 0.75, 0.25))
	LifeRoomKit.box(scenery(), "Shelf", Vector3(0.5, 0.05, 0.25), at.hz_candle + Vector3(0, -0.12, 0), WOOD)
	add_target("hz_candle", candle, 0.2)
	add_target("hz_heater", LifeRoomKit.box(self, "Towel", Vector3(0.6, 0.35, 0.05), at.hz_heater, Color("3a7be8")), 0.3)
	var socket := LifeRoomKit.box(self, "Socket", Vector3(0.05, 0.12, 0.3), at.hz_plugs, Color.WHITE)
	for i in 4:
		LifeRoomKit.box(socket, "Plug", Vector3(0.06, 0.06, 0.06), Vector3(-0.05, 0.08 - i * 0.05, -0.1 + i * 0.07), Color("2b2f38"))
	add_target("hz_plugs", socket, 0.25)
	add_target("hz_iron", LifeRoomKit.box(self, "Iron", Vector3(0.22, 0.1, 0.1), at.hz_iron, Color("8fd3ff")), 0.2)
	add_target("hz_matches", LifeRoomKit.box(self, "Matches", Vector3(0.1, 0.03, 0.06), at.hz_matches, Color("e8544e")), 0.18)
	add_target("hz_lighter", LifeRoomKit.box(self, "Lighter", Vector3(0.04, 0.1, 0.03), at.hz_lighter, Color("ffc93c")), 0.18)
	var lamp := LifeRoomKit.cylinder(self, "LampPole", 0.03, 1.1, at.hz_lamp - Vector3(0, 0.55, 0), Color("9aa7b5"))
	LifeRoomKit.box(lamp, "Cloth", Vector3(0.4, 0.05, 0.4), Vector3(0, 0.6, 0), Color("b03cc0"))
	add_target("hz_lamp", lamp.get_child(0) as Node3D, 0.28)
	add_target("hz_charger", LifeRoomKit.box(self, "Charger", Vector3(0.08, 0.02, 0.14), at.hz_charger, Color("1f2a4a")), 0.2)
	LifeRoomKit.box(scenery(), "SofaPillow", Vector3(0.4, 0.12, 0.35), at.hz_charger + Vector3(0, 0.07, 0), Color.WHITE)


func _phone() -> void:
	LifeRoomKit.box(scenery(), "GardenTable", Vector3(0.8, 0.7, 0.6), TREE + Vector3(1.6, 0.35, 0.6), WOOD.lightened(0.2))
	phone = Node3D.new()
	phone.name = "Phone"
	phone.position = TREE + Vector3(1.6, 0.73, 0.6)
	add_child(phone)
	LifeRoomKit.box(phone, "Body", Vector3(0.16, 0.03, 0.28), Vector3.ZERO, Color("1f2a4a"))
	add_target("phone", phone, 0.16)


## The garden phone up in front of the child at the meeting point, big, its keys facing them (built hidden).
func _hold_phone() -> void:
	phone.visible = false
	(get_node("HeldPhone") as Node3D).visible = true


func _bin() -> void:
	LifeRoomKit.cylinder(scenery(), "Bin", 0.22, 0.5, BIN + Vector3(0, 0.25, 0), Color("9aa7b5"))
	flame = Node3D.new()
	flame.name = "Flame"
	flame.position = BIN + Vector3(0, 0.5, 0)
	flame.visible = false
	add_child(flame)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.18
	cone.height = 0.4
	var f := MeshInstance3D.new()
	f.mesh = cone
	f.position = Vector3(0, 0.2, 0)
	f.material_override = LifeRoomKit.material(Color(1.0, 0.6, 0.18), true)
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.add_child(f)
	LifeRoomKit.sphere(flame, "Core", 0.1, Vector3(0, 0.1, 0), Color(1.0, 0.86, 0.3))
	add_spot_target("fire_base", self, BIN + Vector3(0, 0.55, 0), 0.3, 0.3)
	add_spot_target("spot_bin", self, BIN + Vector3(-0.9, 0.05, 0.9), 0.55)
	LifeRoomKit.cylinder(self, "BinRing", 0.45, 0.02, BIN + Vector3(-0.9, 0.03, 0.9), Color(0.3, 0.85, 0.4, 0.6))
	extinguisher = Node3D.new()
	extinguisher.name = "Extinguisher"
	extinguisher.position = BIN + Vector3(-0.75, 0, 0.45)
	add_child(extinguisher)
	LifeRoomKit.cylinder(extinguisher, "Body", 0.09, 0.5, Vector3(0, 0.25, 0), Color("d9463b"))
	var handle := LifeRoomKit.box(extinguisher, "Handle", Vector3(0.16, 0.04, 0.05), Vector3(0, 0.56, 0), Color("2b2f38"))
	var pin := LifeRoomKit.cylinder(extinguisher, "Pin", 0.012, 0.1, Vector3(0.05, 0.6, 0.04), Color("ffc93c"))
	add_target("ext_handle", handle, 0.13)
	add_target("ext_pin", pin, 0.1)
	spray = LifeRoomKit.box(self, "Spray", Vector3(0.12, 0.12, 0.9), Vector3.ZERO, Color(1, 1, 1, 0.55))
	spray.visible = false


## Life L3b (owner #118): Gus in the living room, for Little's "matches are a grown-up's job: tell a grown-up".
func _gus() -> void:
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55
	gus.position = Vector3(2.6, 0, 0.7)
	gus.rotation.y = PI * 0.15
	gus.visible = false
	add_child(gus)
	gus.face("happy")
	var m := Node3D.new()
	m.name = "T_gus"
	m.position = Vector3(0, 0.63, 0.1)
	gus.add_child(m)
	add_target("gus", m, 0.45)


## Life L3b (owner #118, design §14 row 3): the campfire in the practice garden (Middle): a ring of stones on bare ground,
## a tent and a tree nearby (the wrong places), a bucket of water ready, a small cartoon fire once lit, the ashes.
func _campfire() -> void:
	camp = Node3D.new()
	camp.name = "Camp"
	camp.visible = false
	add_child(camp)
	LifeRoomKit.cylinder(camp, "Bare", 0.8, 0.02, CAMP + Vector3(0, 0.01, 0), Color("b9a07a"))
	for i in 10:
		var a := TAU * i / 10.0
		LifeRoomKit.box(camp, "Stone", Vector3(0.14, 0.1, 0.12), CAMP + Vector3(cos(a) * 0.45, 0.05, sin(a) * 0.45), Color("8a8f99"))
	LifeRoomKit.cylinder(camp, "Ashes", 0.3, 0.04, CAMP + Vector3(0, 0.03, 0), Color("4a4f5a"))
	add_spot_target("fire_ring", camp, CAMP + Vector3(0, 0.08, 0), 0.4)
	add_spot_target("ashes", camp, CAMP + Vector3(0, 0.35, 0.1), 0.25, 0.3)
	add_spot_target("ashes_feel", camp, CAMP + Vector3(0, 0.45, 0.2), 0.15)
	add_spot_target("bucket_pour", camp, CAMP + Vector3(0.0, 0.6, 0.2), 0.16)
	LifeRoomKit.box(camp, "TreeTrunk", Vector3(0.3, 2.0, 0.3), CAMP + Vector3(-1.7, 1.0, -1.6), WOOD)
	LifeRoomKit.sphere(camp, "TreeCrown", 1.1, CAMP + Vector3(-1.7, 2.4, -1.6), Color("4f9a3e"))
	add_spot_target("under_tree", camp, CAMP + Vector3(-1.5, 0.05, -1.2), 0.4)
	var tent := LifeRoomKit.box(camp, "Tent", Vector3(1.2, 0.9, 1.0), CAMP + Vector3(1.6, 0.45, -1.0), Color("3fbf5a"))
	tent.rotation.y = 0.3
	add_spot_target("by_tent", camp, CAMP + Vector3(1.3, 0.05, -0.3), 0.4)
	var bucket := LifeRoomKit.cylinder(camp, "Bucket", 0.14, 0.26, CAMP + Vector3(-0.8, 0.13, 0.8), Color("3a7be8"))
	add_target("water_bucket", bucket, 0.18)
	camp_flame = Node3D.new()
	camp_flame.name = "CampFlame"
	camp_flame.position = CAMP + Vector3(0, 0.05, 0)
	camp_flame.visible = false
	camp.add_child(camp_flame)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.16
	cone.height = 0.32
	cone.radial_segments = 10
	var f := MeshInstance3D.new()
	f.mesh = cone
	f.position = Vector3(0, 0.16, 0)
	f.material_override = LifeRoomKit.material(Color(1.0, 0.6, 0.18), true)
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	camp_flame.add_child(f)
	for x: float in [-0.12, 0.12]:
		var stick := LifeRoomKit.box(camp, "Stick", Vector3(0.3, 0.04, 0.04), CAMP + Vector3(x, 0.06, 0), WOOD)
		stick.rotation.y = 0.6 if x < 0 else -0.6


func _views() -> void:
	add_view("room", Vector3(1.5, 3.7, 3.6), Vector3(1.6, 0.5, -0.3), Vector3(1.6, 0, 1.4), 0.0)
	add_view("bed", Vector3(-2.2, 1.3, 1.3), Vector3(-1.0, 1.0, 0), Vector3(-1.7, 0, 0.3), -PI / 2)
	add_view("bed_garden", Vector3(-2.3, 1.3, 0.8), Vector3(-3.0, 1.0, -2.0), Vector3(-3.0, 0, -1.3), 0.0)
	add_view("hall", Vector3(0.7, 1.2, 0.7), Vector3(-1.0, 1.0, 0), Vector3(-0.3, 0, 0.3), PI / 2)
	add_view("hall_out", Vector3(-0.2, 1.15, 0.6), Vector3(3.5, 0.6, 0), Vector3(0.3, 0, 0.3), -PI / 2)
	add_view("front_door", Vector3(5.3, 1.35, 0.6), TREE + Vector3(0, 1.0, 0), Vector3(5.0, 0, 0.0), atan2(2.0, 5.5))
	add_view("garden_door", Vector3(-3.0, 1.3, -2.8), TREE + Vector3(0, 1.0, 0), Vector3(-3.0, 0, -2.9), atan2(-6.0, 2.6))
	add_view("garden_path", Vector3(-2.4, 1.3, -3.8), Vector3(-3.0, 1.0, -2.0), Vector3(-3.0, 0, -3.2), PI)
	add_view("garden", Vector3(5.4, 1.45, -1.6), TREE + Vector3(0, 1.0, 0), Vector3(4.6, 0, -2.6), atan2(1.6, 2.9))
	add_view("meeting_point", Vector3(4.6, 1.3, -3.4), TREE + Vector3(1.4, 0.6, 0.6), TREE + Vector3(0.8, 0, 1.0), atan2(-0.8, 0.4))
	add_view("phone_garden", TREE + Vector3(0.8, 1.15, 1.85), TREE + Vector3(0.8, 1.0, 0.55), TREE + Vector3(0.8, 0, 1.0), 0.0)
	add_view("spot_bin", BIN + Vector3(-1.4, 1.3, 1.6), BIN + Vector3(0, 0.45, 0), BIN + Vector3(-0.9, 0, 0.9), -PI / 4)
	add_view("to_bin", Vector3(5.2, 1.45, -3.2), BIN + Vector3(-0.5, 0.3, 0.6), Vector3(4.8, 0, -3.0), atan2(-2.2, -2.1))
	add_view("bin", BIN + Vector3(-1.3, 1.25, 1.4), BIN + Vector3(0, 0.45, 0), BIN + Vector3(-0.9, 0, 0.9), -PI / 4)
	add_view("campfire", CAMP + Vector3(0, 1.6, 3.6), CAMP + Vector3(0, 0.2, -0.2), CAMP + Vector3(0, 0, 2.6), 0.0)   # Life L3b
	add_view("campfire_close", CAMP + Vector3(0, 1.35, 1.3), CAMP + Vector3(0, 0.1, 0), CAMP + Vector3(0, 0, 0.7), 0.0)


func on_event(event: String) -> void:
	match event:
		"alarm_on":
			_alarm = true
		"alarm_off":
			_alarm = false
			alarm_light.material_override = LifeRoomKit.material(Color("4a5468"))
		"smoke_on":
			smoke.visible = true
		"door_hall_open":
			_swing("door_hall", 1.4)
		"door_hall_shut":
			_swing("door_hall", 0.0)
		"door_garden_open":
			_swing("door_garden", -1.4)
		"door_garden_shut":
			_swing("door_garden", 0.0)
		"door_warm":
			(doors.door_hall.panel as MeshInstance3D).material_override = LifeRoomKit.material(Color("d98a4a"))
		"front_blocked":
			boxes.visible = true
		"bin_fire":
			if flame:
				flame.visible = true
				flame.scale = Vector3.ONE
		"spray_on":
			if spray:
				spray.visible = true
				_aim_spray(0.0)
		"fire_out":
			if flame:
				flame.visible = false
		"spray_off":
			if spray:
				spray.visible = false
		"gus_here":   # Life L3b: a grown-up to tell about the matches
			if gus:
				gus.visible = true
		"camp_on":
			if camp:
				camp.visible = true
		"camp_lit":
			if camp_flame:
				camp_flame.visible = true
				camp_flame.scale = Vector3.ONE
		"camp_out":
			if camp:
				(camp.get_node("Ashes") as MeshInstance3D).material_override = LifeRoomKit.material(Color("8a8f99"))


func _swing(door_name: String, by: float) -> void:
	var d: Dictionary = doors[door_name]
	var to := float(d.yaw) + by
	var pivot := d.pivot as Node3D
	if is_inside_tree() and not UiMotion.calm():
		create_tween().tween_property(pivot, "rotation:y", to, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		pivot.rotation.y = to


func _aim_spray(u: float) -> void:
	var from: Vector3 = extinguisher.position + Vector3(0.1, 0.6, -0.1)
	var to: Vector3 = BIN + Vector3(u * 0.25, 0.55, 0)
	spray.position = (from + to) * 0.5
	if is_inside_tree():
		spray.look_at_from_position(spray.position, to, Vector3.UP)
	spray.scale = Vector3(1, 1, from.distance_to(to) / 0.9)


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"phone":
			_hold_phone()
		"dial":
			if phone_screen:
				phone_screen.text = "CALLING..."
		"pin":
			var pin := target_node("ext_pin")
			if pin:
				pin.visible = false


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			for t: Variant in state.get("found", []):
				if not ticks.has(t) and has_target(str(t)):
					ticks[t] = LifeRoomKit.sphere(self, "Tick", 0.07, to_local(target_position(str(t))) + Vector3(0, 0.25, 0),
						Color(0.3, 0.85, 0.4, 0.9))
		"sequence":
			if phone_screen:
				phone_screen.text = LifeRoom.dialled(step, state)
		"sweep":
			if flame:
				var left := 1.0 - LifeCheck.fraction(step, state)
				flame.scale = Vector3.ONE * maxf(left, 0.15)
				_aim_spray(float(state.get("side", 0)) * 0.8)
		"pour":   # Life L3b: the campfire drowned: the flame goes down as the water goes on
			if camp_flame:
				var left := 1.0 - LifeCheck.fraction(step, state)
				camp_flame.scale = Vector3.ONE * maxf(left, 0.05)
				camp_flame.visible = left > 0.12


func _process(delta: float) -> void:
	super(delta)
	if not _alarm:
		return
	_alarm_t += delta
	var on := fmod(_alarm_t, 1.5) < 0.2
	alarm_light.material_override = LifeRoomKit.material(Color("ff8a5c") if on else Color("4a5468"), on)
	if on and fmod(_alarm_t, 1.5) < delta + 0.001 and is_inside_tree():
		Audio.play(&"beep")


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A home: skirting along the walls, windows inside and out over the garden, a rug under the living room's table, a
## bookshelf, plants, pictures, a bedside table with its lamp, a wardrobe and a quilt; outside, a roof (but over the
## hazard hunt's open doll's house), stepping stones from the front door, flower beds, a fence along the garden's back
## and a soft sky. Never on a hazard, a door, a ring, a view's line or where the child stands.
func _house_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	var skirt := Color("c89a62")
	for w: Array in [[Vector3(-4.94, 0, -2), Vector3(-4.94, 0, 2)], [Vector3(-5, 0, 1.94), Vector3(-1, 0, 1.94)],
			[Vector3(-5, 0, -1.94), Vector3(-3.5, 0, -1.94)], [Vector3(-2.5, 0, -1.94), Vector3(-1, 0, -1.94)],
			[Vector3(-1, 0, -1.94), Vector3(4, 0, -1.94)], [Vector3(3.94, 0, -2), Vector3(3.94, 0, -1.0)],
			[Vector3(3.94, 0, 1.0), Vector3(3.94, 0, 2)]]:
		d.skirting("Skirting", w[0], w[1], skirt)
	# windows: the bedroom's west wall and the living room's north wall, inside and out
	d.window("Window", Vector3(-4.94, 1.45, -0.9), 0.9, 0.9, PI / 2, Color("fdfdf8"))
	d.window("Window", Vector3(-5.06, 1.45, -0.9), 0.9, 0.9, -PI / 2, Color("fdfdf8"), Color("ffe9b8"), Color("fff6dc"), Color("f3c98a"))
	d.window("Window", Vector3(-0.3, 1.5, -1.94), 0.8, 0.8, 0.0, Color("fdfdf8"))
	d.window("Window", Vector3(-0.3, 1.5, -2.06), 0.8, 0.8, PI, Color("fdfdf8"), Color("ffe9b8"), Color("fff6dc"), Color("f3c98a"))
	d.window("Window", Vector3(2.6, 1.75, -2.06), 0.9, 0.6, PI, Color("fdfdf8"), Color("ffe9b8"), Color("fff6dc"), Color("f3c98a"))
	# the bedroom
	d.rug("Rug", Vector3(-2.6, 0.01, 0.9), Vector2(1.3, 0.9), Color("f6c9b4"), Color("e8544e"))
	d.box("Quilt", Vector3(1.04, 0.06, 1.3), Vector3(-4.3, 0.48, 0.95), Color("ffc93c"))
	d.box("BedHead", Vector3(1.04, 0.7, 0.08), Vector3(-4.3, 0.35, -0.42), Color("8a6239"))
	d.box("BedsideTable", Vector3(0.4, 0.45, 0.35), Vector3(-4.6, 0.225, -1.2), Color("c89a62"))
	d.lamp("BedsideLamp", Vector3(-4.6, 0.45, -1.2), 0.25, Color("fff1c8"))
	d.box("Wardrobe", Vector3(1.0, 1.9, 0.5), Vector3(-2.0, 0.95, 1.7), Color("c89a62"))
	d.box("WardrobeLine", Vector3(0.02, 1.7, 0.02), Vector3(-2.0, 0.95, 1.44), Color("8a6239"))
	d.picture("BedPicture", Vector3(-3.0, 1.7, 1.93), Vector2(0.6, 0.45), PI, Color("3a7be8"), Color("fff6e0"), 2)
	d.picture("DoorPicture", Vector3(-1.06, 1.55, 1.25), Vector2(0.45, 0.55), -PI / 2, Color("e8544e"), Color("fff6e0"), 1)
	d.box("Switch", Vector3(0.02, 0.12, 0.08), Vector3(-1.06, 1.05, 0.68), Color("fdfdf8"))
	d.box("NightLight", Vector3(0.03, 0.08, 0.08), Vector3(-1.06, 0.3, 1.6), Color("fdfdf8"))
	d.glow_box("NightLightGlow", Vector3(0.02, 0.05, 0.05), Vector3(-1.08, 0.3, 1.6), Color("ffd98a"))
	d.ceiling_light("BedLight", Vector3(-3.0, H - 0.04, 0.0), 0.26)
	# the living room
	d.rug("Rug", Vector3(1.0, 0.03, 0.55), Vector2(1.8, 1.3), Color("cfe0ee"), Color("3a7be8"))
	d.box("ToyBox", Vector3(0.5, 0.36, 0.38), Vector3(-1.6, 0.18, -1.55), Color("3a7be8"))
	d.box("ToyBoxLid", Vector3(0.54, 0.05, 0.42), Vector3(-1.6, 0.385, -1.55), Color("ffc93c"))
	d.ball("Ball", 0.1, Vector3(-1.45, 0.5, -1.55), Color("e8544e"))
	d.plant("Plant", Vector3(-1.3, 0, 1.62), 1.0)
	d.picture("Picture", Vector3(-0.94, 1.7, -0.8), Vector2(0.5, 0.4), PI / 2, Color("8a6239"), Color("fff6e0"), 1)
	if track != "little":   # a roof over the house (the hazard hunt's doll's house stays open to the view from above)
		_roof(d)
	# the garden
	for i in 5:
		d.cylinder("Stone", 0.26, 0.03, Vector3(4.6 + i * 0.55, 0.0, -0.3 - i * 0.95), Color("aaa396"), -1.0, 9, LifeRoomDecor.SHELL)
	for x: float in [-4.0, -2.0, 0.6]:
		d.bush("FlowerBed", Vector3(x, 0, -2.75), 0.8, Color("5aa548"), Color("e85a9a") if x < -1.0 else Color("ffc93c"))
	d.fence("Fence", Vector3(-9.0, 0, -10.0), Vector3(13.0, 0, -10.0), Color("fdfaf2"), 0.8)
	d.tree("FarTree", Vector3(-6.5, 0, -8.5), 1.1, Color("5aa548"))
	d.tree("FarTree", Vector3(12.0, 0, 2.5), 1.0)
	d.tree("FarTree", Vector3(-7.0, 0, 4.0), 0.9)


## A pitched roof over the house and its gables (Middle and Big: the escape's views are inside, under the ceilings).
func _roof(d: LifeRoomDecor) -> void:
	var pitch := 0.5
	var half := 2.35
	var slope := half / cos(pitch)
	for side: int in [-1, 1]:
		d.box_basis("Roof", Vector3(9.6, 0.12, slope), Transform3D(Basis(Vector3.RIGHT, side * pitch),
			Vector3(-0.5, H + 0.1 + sin(pitch) * slope * 0.5, side * half * 0.5)), Color("c8553d"), LifeRoomDecor.SHELL)
	for end: float in [-5.0, 4.0]:
		for k in 3:
			var h := (k + 0.5) * sin(pitch) * slope / 3.0
			d.box("Gable", Vector3(0.1, sin(pitch) * slope / 3.0, 4.0 * (1.0 - (k + 0.5) / 3.0)), Vector3(end, H + 0.1 + h, 0),
				WALL.darkened(0.05), 0.0, LifeRoomDecor.SHELL)
