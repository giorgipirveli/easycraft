class_name ElectricRoom
extends LifeRoom
## Owner #118 (docs/design/life-skills.md §14, the catalogue's row 7: electricity; Life L3b): Electricity Safety's
## practice places, built for the track: the practice house (the bath corner with its towel, the hair dryer and the shelf
## far from the water; the sockets, one overloaded with an adaptor in an adaptor; the lamp with its frayed cable; the
## toaster; the window with the power lines and a kite outside; Gus; on Big the hall's fuse box with its main switch and
## RCD, and the hall table's phone), the practice park (Middle: two poles and their lines, the open field, the tree under
## the lines, the substation's fence with its DANGER sign and a ball inside) and the park's path after a storm (Big: a
## fallen line on the ground, the safe place far away, Mo coming along the path). Calm: electricity is never seen as a
## flash: a stuck Gus has a soft yellow glow and a worried face, nothing else. The safe mistakes' gentle pictures
## (on_mistake): a small yellow zigzag on the wet dryer, a second figure frozen holding Gus's arm (now two are stuck),
## soft yellow rings on the ground round the fallen line.

const FLOOR := Color("d9c3a0")
const WALL := Color("f3efe6")
const TILE := Color("dfe9f2")
const WOOD := Color("a8642a")
const WHITE := Color("f4f6f8")
const INK := Color("1f2a4a")
const SPARK := Color(1.0, 0.86, 0.3, 0.9)
const GRASS := Color("7cc46a")
const PATH := Color("c9b68a")
const PARK := Vector3(30, 0, 0)
const STORM := Vector3(-30, 0, 0)
const HALL_X := 6.8

var gus: LifeBuddy
var mo: LifeBuddy
var dryer: Node3D
var kite: Node3D
var main_switch: MeshInstance3D
var rcd_lever: MeshInstance3D
var lamp_cable: Node3D
var phone: Node3D
var phone_screen: Label3D
var line_sparks: Array[MeshInstance3D] = []
var _glow: MeshInstance3D
var _t := 0.0


func build() -> void:
	name = "ElectricRoom"
	env = LifeRoomKit.environment(Color("cfe3f2"), Color("f3f6f9"), 0.75)
	start_view = "home"
	_house()
	if track == "middle":
		_park()
	if track == "big":
		_hall()
		_storm()
	_buddies()
	_home_look()   # the rooms' look (2026-10-18)
	_views()
	if track == "big":
		var held := view("phone")
		var feet: Vector3 = held.feet
		phone_screen = make_held_phone(Transform3D(Basis(Vector3.UP, float(held.yaw)),
			feet + Vector3(0, EYE, 0) + Basis(Vector3.UP, float(held.yaw)) * Vector3(0, -0.15, -0.45)))


# --- The practice house -------------------------------------------------------------------------------------------------

func _house() -> void:
	var d := decor()   # the rooms' look: planks, the bath corner's tiles, the wall
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(12.0, 0.1, 5.4), Vector3(2.0, -0.05, 0.2), Color("f2dcc0"), 0.75)
	d.box("BackWall", Vector3(12.0, 2.6, 0.1), Vector3(2.0, 1.3, -2.45), WALL, 0.0, LifeRoomDecor.SHELL)
	d.tiled("BathFloor", LifeRoomDecor.TILE, Vector3(3.0, 0.02, 2.6), Vector3(-2.6, 0.01, -1.1), Color("e4f0f8"), 0.4)
	var sc := scenery()
	# painted on the wall right of the short wall (turned to the eye, it sank into the wall; further left the bath
	# corner's short wall stood through it)
	var room_sign := LifeRoomKit.sign(self, "RoomSign", "PRACTICE HOUSE", Vector3(0.4, 2.35, -2.35), 0.005, Color("2f7f6a"))
	room_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	LifeRoomKit.light(self, Vector3(1.0, 2.4, 0.0), 0.9, 9.0)
	# the bath corner: the bath, its water, the towel, the shelf far from the water, the hair dryer on the bath's edge
	LifeRoomKit.box(scenery(), "Bath", Vector3(1.7, 0.55, 0.8), Vector3(-3.0, 0.275, -1.95), WHITE)
	LifeRoomKit.box(self, "BathWater", Vector3(1.5, 0.04, 0.6), Vector3(-3.0, 0.5, -1.95), Color(0.45, 0.75, 0.95, 0.6))
	LifeRoomKit.box(scenery(), "TowelRail", Vector3(0.5, 0.03, 0.03), Vector3(-3.6, 1.15, -2.38), Color("9aa7b5"))
	var towel := LifeRoomKit.box(self, "Towel", Vector3(0.42, 0.45, 0.04), Vector3(-3.6, 0.92, -2.36), Color("f6b5a8"))
	add_target("towel", towel, 0.2)
	var shelf := LifeRoomKit.box(self, "Shelf", Vector3(0.5, 0.04, 0.25), Vector3(-1.3, 1.0, -2.3), WOOD)
	add_target("far_shelf", shelf, 0.2)
	add_spot_target("bath_edge", self, Vector3(-3.1, 0.58, -1.5), 0.18)
	dryer = Node3D.new()
	dryer.name = "HairDryer"
	dryer.position = Vector3(-2.3, 0.6, -1.52)
	add_child(dryer)
	LifeRoomKit.box(dryer, "Body", Vector3(0.18, 0.08, 0.08), Vector3.ZERO, Color("e85a9a"))
	LifeRoomKit.box(dryer, "Handle", Vector3(0.05, 0.14, 0.05), Vector3(0.04, -0.08, 0), Color("e85a9a").darkened(0.2))
	if track == "little":
		add_target("hz_dryer_bath", dryer, 0.18)
	elif track == "middle":
		add_target("hair_dryer", dryer, 0.16)
	# the dryer's socket outside the bath corner, its plug and cable
	_socket(Vector3(-0.6, 0.35, -2.39))
	var plug := LifeRoomKit.box(self, "DryerPlug", Vector3(0.07, 0.08, 0.06), Vector3(-0.6, 0.35, -2.34), WHITE)
	var cable := LifeRoomKit.box(self, "DryerCable", Vector3(0.02, 0.02, 0.5), Vector3(-0.6, 0.06, -2.1), Color("e8e3da"))
	if track == "middle":
		add_target("plug_head", plug, 0.09)
		add_spot_target("cable", self, Vector3(-0.6, 0.06, -1.9), 0.1)
	cable.visible = track != "big"
	# the living room's sockets: one with an adaptor in an adaptor; a drink by another; a toy key by a third
	_socket(Vector3(1.2, 0.35, -2.39))
	var adaptor := LifeRoomKit.box(self, "Adaptor", Vector3(0.12, 0.12, 0.08), Vector3(1.2, 0.35, -2.32), WHITE)
	var adaptor2 := LifeRoomKit.box(adaptor, "Adaptor2", Vector3(0.12, 0.12, 0.08), Vector3(0.0, 0.0, 0.08), WHITE)
	for i in 4:
		LifeRoomKit.box(adaptor2, "Plug", Vector3(0.05, 0.05, 0.05), Vector3(-0.04 + (i % 2) * 0.08, 0.04 - (i / 2) * 0.08, 0.06),
			INK)
	if track == "little":
		add_target("hz_overload", adaptor, 0.16)
	_socket(Vector3(2.4, 0.35, -2.39))
	LifeRoomKit.box(scenery(), "LowTable", Vector3(0.6, 0.4, 0.4), Vector3(2.4, 0.2, -2.05), WOOD)
	var cup := LifeRoomKit.cylinder(self, "Cup", 0.04, 0.1, Vector3(2.45, 0.45, -2.18), Color("ffb02e"))
	_socket(Vector3(0.2, 0.3, -2.39))
	var key := LifeRoomKit.box(self, "ToyKey", Vector3(0.08, 0.02, 0.03), Vector3(0.28, 0.32, -2.34), Color("ffd23f"))
	if track == "little":
		add_target("hz_drink_socket", cup, 0.14)
		add_target("hz_socket_toy", key, 0.14)
	# the lamp and its cable (frayed: the coloured wires showing)
	LifeRoomKit.cylinder(sc, "LampPole", 0.025, 1.3, Vector3(3.7, 0.65, -1.7), Color("9aa7b5"))
	LifeRoomKit.cylinder(sc, "LampShade", 0.18, 0.22, Vector3(3.7, 1.35, -1.7), Color("ffe08a"))
	lamp_cable = Node3D.new()
	lamp_cable.name = "LampCable"
	lamp_cable.position = Vector3(3.3, 0.03, -1.25)
	add_child(lamp_cable)
	LifeRoomKit.box(lamp_cable, "Cable", Vector3(0.7, 0.025, 0.025), Vector3(0.0, 0.0, 0.0), INK)
	for i in 3:
		LifeRoomKit.box(lamp_cable, "Wire", Vector3(0.1, 0.012, 0.012), Vector3(0.02 * i - 0.02, 0.012, 0.015 * (i - 1)),
			[Color("c0563a"), Color("3a7be8"), Color("e8c84a")][i])
	if track == "little":
		add_target("hz_frayed", lamp_cable, 0.2)
	elif track == "middle":
		add_target("frayed_cable", lamp_cable, 0.2)
	# the kitchen corner's toaster (a fork in it, for Little's hunt)
	LifeRoomKit.box(scenery(), "Counter", Vector3(1.6, 0.9, 0.6), Vector3(5.0, 0.45, -2.1), Color("7fb8d6"))
	var toaster := LifeRoomKit.box(self, "Toaster", Vector3(0.26, 0.18, 0.16), Vector3(4.7, 0.99, -2.05), Color("c9ced6"))
	if track == "little":
		var fork := LifeRoomKit.box(toaster, "Fork", Vector3(0.015, 0.2, 0.015), Vector3(0.05, 0.12, 0.0), Color("c9ced6"))
		fork.rotation.z = 0.3
		add_target("hz_fork_toaster", toaster, 0.18)
	# the window: the power lines outside, and (Little) a kite caught in them
	d.window("Window", Vector3(3.2, 1.65, -2.39), 1.3, 0.8, 0.0)
	for y: float in [1.82, 1.9]:
		LifeRoomKit.box(sc, "LineOutside", Vector3(1.28, 0.012, 0.01), Vector3(3.2, y, -2.35), INK)
	if track == "little":
		var k := LifeRoomKit.box(self, "KiteOutside", Vector3(0.14, 0.14, 0.01), Vector3(3.35, 1.84, -2.34), Color("e85a9a"))
		k.rotation.z = PI / 4
		add_target("hz_kite", k, 0.15)


func _socket(at: Vector3) -> void:
	LifeRoomKit.box(scenery(), "Socket", Vector3(0.12, 0.12, 0.02), at, WHITE.darkened(0.05))
	for x: float in [-0.025, 0.025]:
		LifeRoomKit.box(scenery(), "Hole", Vector3(0.012, 0.03, 0.01), at + Vector3(x, 0, 0.012), INK)


# --- The hall's fuse box and the phone (Big) ----------------------------------------------------------------------------

func _hall() -> void:
	LifeRoomKit.box(scenery(), "HallWall", Vector3(0.1, 2.6, 2.6), Vector3(5.95, 1.3, -1.1), WALL.darkened(0.03))
	LifeRoomKit.box(scenery(), "FuseBox", Vector3(0.6, 0.4, 0.12), Vector3(HALL_X, 1.45, -2.34), WHITE)
	add_spot_target("fuse_box", self, Vector3(HALL_X, 1.45, -2.27), 0.26)   # its cover: gone once touched (the RCD's
	# button is on it: a hand at the button would touch the bigger cover first, the smoke found)
	LifeRoomKit.sign(self, "FuseSign", "FUSE BOX", Vector3(HALL_X, 1.78, -2.3), 0.003, INK)
	main_switch = LifeRoomKit.box(self, "MainSwitch", Vector3(0.07, 0.12, 0.04), Vector3(HALL_X - 0.18, 1.47, -2.26), Color("e8544e"))
	add_spot_target("main_switch", self, Vector3(HALL_X - 0.18, 1.47, -2.24), 0.08)
	LifeRoomKit.box(scenery(), "RcdBody", Vector3(0.1, 0.16, 0.04), Vector3(HALL_X + 0.05, 1.45, -2.27), Color("dfe3ea"))
	var test := LifeRoomKit.box(self, "RcdTest", Vector3(0.035, 0.035, 0.03), Vector3(HALL_X + 0.05, 1.5, -2.24), Color("3a7be8"))
	add_target("rcd_test", test, 0.06)
	rcd_lever = LifeRoomKit.box(self, "RcdSwitch", Vector3(0.04, 0.05, 0.03), Vector3(HALL_X + 0.05, 1.41, -2.24), INK)
	add_spot_target("rcd_switch", self, Vector3(HALL_X + 0.05, 1.4, -2.23), 0.06)
	for i in 3:
		LifeRoomKit.box(scenery(), "Breaker", Vector3(0.04, 0.1, 0.03), Vector3(HALL_X + 0.15 + i * 0.05, 1.45, -2.26), INK.lightened(0.3))
	LifeRoomKit.box(scenery(), "HallTable", Vector3(0.6, 0.72, 0.4), Vector3(5.4, 0.36, -1.0), WOOD)
	phone = Node3D.new()
	phone.name = "Phone"
	phone.position = Vector3(5.4, 0.74, -1.0)
	add_child(phone)
	LifeRoomKit.box(phone, "Body", Vector3(0.16, 0.03, 0.28), Vector3.ZERO, INK)
	add_target("phone", phone, 0.18)


# --- The practice park and the substation (Middle) ----------------------------------------------------------------------

func _park() -> void:
	var park := Node3D.new()
	park.name = "Park"
	add_child(park)
	decor().tiled("ParkGrass", LifeRoomDecor.GRASS, Vector3(26, 0.1, 16), PARK + Vector3(2, -0.05, -1), Color("dcefc8"), 1.0)
	for x: float in [24.0, 36.0]:
		LifeRoomKit.box(park, "Pole", Vector3(0.22, 7.0, 0.22), PARK + Vector3(x - 30.0, 3.5, -5.0), WOOD)
		LifeRoomKit.box(park, "Arm", Vector3(1.4, 0.12, 0.12), PARK + Vector3(x - 30.0, 6.8, -5.0), WOOD)
	for z: float in [-5.0]:
		for dx: float in [-0.6, 0.6]:
			LifeRoomKit.box(park, "Line", Vector3(12.0, 0.03, 0.03), PARK + Vector3(dx * 0.0, 6.85, z + dx * 0.1), INK)
	add_spot_target("near_lines", park, PARK + Vector3(2.0, 0.05, -3.5), 0.7)
	LifeRoomKit.cylinder(park, "NearMark", 0.6, 0.02, PARK + Vector3(2.0, 0.02, -3.5), Color(0.6, 0.62, 0.68, 0.6))
	add_spot_target("open_field", park, PARK + Vector3(-3.0, 0.05, 1.0), 0.7)
	LifeRoomKit.cylinder(park, "FieldMark", 0.6, 0.02, PARK + Vector3(-3.0, 0.02, 1.0), Color(0.3, 0.85, 0.4, 0.6))
	LifeRoomKit.box(park, "TreeTrunk", Vector3(0.35, 3.6, 0.35), PARK + Vector3(4.0, 1.8, -5.6), WOOD)
	LifeRoomKit.sphere(park, "TreeCrown", 1.4, PARK + Vector3(4.0, 4.6, -5.6), Color("3f8a3a"))
	kite = Node3D.new()
	kite.name = "Kite"
	kite.position = PARK + Vector3(1.0, 6.6, -5.0)
	kite.visible = false
	add_child(kite)
	var diamond := LifeRoomKit.box(kite, "Diamond", Vector3(0.5, 0.5, 0.04), Vector3.ZERO, Color("e85a9a"))
	diamond.rotation.z = PI / 4
	LifeRoomKit.box(kite, "Tail", Vector3(0.03, 1.2, 0.03), Vector3(0, -0.9, 0), Color("ffd23f"))
	LifeRoomKit.sign(park, "ParkSign", "PRACTICE PARK", PARK + Vector3(-4.0, 2.6, -2.0), 0.006, Color("2f7f6a"))
	# the substation: a fence, its DANGER sign, the ball inside
	var sub := PARK + Vector3(10.0, 0, -3.0)
	for side: Array in [[Vector3(4.0, 2.0, 0.06), Vector3(0, 1.0, 2.0)], [Vector3(4.0, 2.0, 0.06), Vector3(0, 1.0, -2.0)],
			[Vector3(0.06, 2.0, 4.0), Vector3(-2.0, 1.0, 0)], [Vector3(0.06, 2.0, 4.0), Vector3(2.0, 1.0, 0)]]:
		LifeRoomKit.box(park, "Fence", side[0], sub + side[1], Color(0.62, 0.66, 0.72, 0.55))
	LifeRoomKit.box(park, "Transformer", Vector3(1.4, 1.4, 1.0), sub + Vector3(0.3, 0.7, -0.4), Color("6b7a99"))
	var sign := LifeRoomKit.box(park, "DangerSign", Vector3(0.6, 0.45, 0.03), sub + Vector3(0.0, 1.3, 2.05), Color("ffd23f"))
	LifeRoomKit.sign(sign, "Danger", "DANGER", Vector3(0, 0.0, 0.03), 0.0025, INK)
	LifeRoomKit.sphere(park, "Ball", 0.12, sub + Vector3(-1.2, 0.12, 1.0), Color("e85a9a"))
	add_spot_target("substation_gate", park, sub + Vector3(-1.2, 0.8, 2.05), 0.35)


# --- The park's path after a storm (Big) --------------------------------------------------------------------------------

func _storm() -> void:
	var s := Node3D.new()
	s.name = "Storm"
	add_child(s)
	LifeRoomKit.box(s, "Grass", Vector3(22, 0.1, 18), STORM + Vector3(0, -0.06, -3), GRASS.darkened(0.08))
	LifeRoomKit.box(s, "Path", Vector3(2.0, 0.02, 16), STORM + Vector3(0.5, 0.0, -3), PATH)
	var pole := LifeRoomKit.box(s, "LeaningPole", Vector3(0.22, 6.0, 0.22), STORM + Vector3(7.0, 2.8, -9.0), WOOD)
	pole.rotation.z = 0.25
	var line := LifeRoomKit.box(s, "FallenLine", Vector3(0.04, 0.04, 4.4), STORM + Vector3(6.0, 0.03, -6.6), INK)
	line.rotation.y = 0.25
	for i in 3:
		line_sparks.append(LifeRoomKit.sphere(s, "Spark", 0.06, STORM + Vector3(5.45 + i * 0.05, 0.08, -4.5 + i * 0.03), SPARK))
		line_sparks[i].material_override = LifeRoomKit.material(SPARK, true)
	s.visible = false
	add_spot_target("near_line", s, STORM + Vector3(3.5, 0.05, -4.5), 0.6)
	LifeRoomKit.cylinder(s, "NearMark", 0.55, 0.02, STORM + Vector3(3.5, 0.02, -4.5), Color(0.6, 0.62, 0.68, 0.6))
	add_spot_target("far_spot", s, STORM + Vector3(-5.0, 0.05, -5.0), 0.7)
	LifeRoomKit.cylinder(s, "FarMark", 0.6, 0.02, STORM + Vector3(-5.0, 0.02, -5.0), Color(0.3, 0.85, 0.4, 0.6))
	LifeRoomKit.sign(s, "FarSign", "SAFE PLACE: FAR AWAY", STORM + Vector3(-5.0, 1.4, -5.0), 0.004, Color("2fae4e"))


func _buddies() -> void:
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55   # a grown-up
	gus.position = Vector3(1.8, 0, -0.7)
	add_child(gus)
	var m := Node3D.new()
	m.name = "T_gus"
	m.position = Vector3(0, 0.63, 0.1)
	gus.add_child(m)
	if track != "big":
		add_target("gus", m, 0.45)
	else:
		add_target("gus_stuck", m, 0.45)
	if track == "middle":
		var g2 := LifeBuddy.new(Color("7b5cd6"), "GusPark")
		g2.scale = Vector3.ONE * 1.55
		g2.position = PARK + Vector3(7.5, 0, 0.6)
		g2.rotation.y = -0.6
		add_child(g2)
		var m2 := Node3D.new()
		m2.name = "T_gus_park"
		m2.position = Vector3(0, 0.63, 0.1)
		g2.add_child(m2)
		add_target("gus_park", m2, 0.45)
	if track == "big":
		mo = LifeBuddy.new(Color("ffb347"), "Mo")
		mo.position = STORM + Vector3(0.0, 0, -1.0)
		mo.rotation.y = -0.5
		mo.visible = false
		add_child(mo)
		var mm := Node3D.new()
		mm.name = "T_mo"
		mm.position = Vector3(0, 0.6, 0.1)
		mo.add_child(mm)
		add_target("mo_walker", mm, 0.45)


func _views() -> void:
	add_view("home", Vector3(1.0, 2.6, 4.2), Vector3(1.0, 0.6, -1.4), Vector3(1.0, 0, 2.0), 0.0)
	add_view("bath", Vector3(-1.5, 1.5, 0.7), Vector3(-2.5, 0.6, -1.8), Vector3(-1.9, 0, -0.2), 0.4)
	add_view("sockets", Vector3(0.4, 1.3, 0.9), Vector3(0.4, 0.4, -2.2), Vector3(0.4, 0, -0.6), 0.0)
	add_view("lamp", Vector3(3.1, 1.5, 1.1), Vector3(3.0, 0.4, -1.4), Vector3(3.0, 0, 0.0), 0.0)
	add_view("hall", Vector3(6.3, 1.5, 0.4), Vector3(HALL_X, 1.45, -2.3), Vector3(6.6, 0, -1.4), 0.0)
	add_view("stuck", Vector3(5.2, 1.6, 1.6), Vector3(5.0, 1.0, -1.8), Vector3(5.0, 0, 0.3), 0.0)
	add_view("phone", Vector3(5.0, 1.15, 1.1), Vector3(5.0, 1.0, -0.2), Vector3(5.0, 0, 0.3), 0.0)
	add_view("park", PARK + Vector3(0.0, 1.6, 5.0), PARK + Vector3(0.5, 1.2, -3.0), PARK + Vector3(0.0, 0, 3.0), 0.0)
	add_view("kite", PARK + Vector3(0.0, 1.5, 4.0), PARK + Vector3(1.5, 4.2, -5.0), PARK + Vector3(0.0, 0, 3.0), 0.0)
	add_view("substation", PARK + Vector3(8.6, 1.5, 4.2), PARK + Vector3(9.4, 0.9, -1.5), PARK + Vector3(8.6, 0, 2.6), 0.0)
	add_view("storm", STORM + Vector3(0.0, 1.6, 2.0), STORM + Vector3(0.0, 0.3, -5.0), STORM + Vector3(0.0, 0, 0.5), 0.0)
	add_view("far", STORM + Vector3(-5.6, 1.5, -3.4), STORM + Vector3(-1.0, 0.6, -4.0), STORM + Vector3(-5.0, 0, -5.0), -1.45)


# --- Events -------------------------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"kite_stuck":
			if kite:
				kite.visible = true
		"rcd_off":
			rcd_lever.position.y = 1.38
			if is_inside_tree():
				Audio.play(&"plate_click")
		"rcd_on":
			rcd_lever.position.y = 1.41
		"gus_stuck":
			gus.position = Vector3(3.35, 0, -1.25)
			gus.rotation.y = PI * 0.75
			LifeRoomPeople.feel(gus, "worried")
			gus.arm_near.rotation = Vector3(-1.2, 0, 0)
			_glow = LifeRoomKit.sphere(gus.arm_near, "Glow", 0.12, Vector3(0, -0.34, 0), SPARK)
			_glow.material_override = LifeRoomKit.material(Color(1.0, 0.86, 0.3, 0.45), true)
		"line_down":
			(get_node("Storm") as Node3D).visible = true
		"mo_walks":
			if mo:
				mo.visible = true
				mo.position = STORM + Vector3(0.6, 0, -2.5)


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"fuse_box":
			target_node("fuse_box").visible = false
		"far":
			dryer.position = Vector3(-1.3, 1.07, -2.3)
		"frayed":
			lamp_cable.visible = false   # Gus switched it off, unplugged it and put it away to be mended
		"stuck":
			main_switch.position.y = 1.42   # off
			if is_instance_valid(_glow):
				_glow.queue_free()
			gus.arm_near.rotation = Vector3.ZERO
			LifeRoomPeople.feel(gus, "calm")
		"phone":
			phone.visible = false
			(get_node("HeldPhone") as Node3D).visible = true
		"dial":
			if phone_screen:
				phone_screen.text = "CALLING..."
		"warn":
			if mo:
				LifeRoomPeople.feel(mo, "happy")
				mo.position = STORM + Vector3(-2.0, 0, 0.5)


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			for f: Variant in state.get("found", []):
				var t := str(f)
				if has_target(t) and target_node(t).get_node_or_null("Found") == null:
					LifeRoomKit.sphere(target_node(t), "Found", 0.035, Vector3(0, 0.2, 0), Color(0.3, 0.85, 0.4, 0.9))
		"sequence":
			if phone_screen:
				phone_screen.text = LifeRoom.dialled(step, state)


func _process(delta: float) -> void:
	super(delta)
	_t += sim_delta(delta)   # the room's own time: slow on a danger moment's first tries, still while frozen
	if is_instance_valid(_glow):
		_glow.scale = Vector3.ONE * (1.0 + 0.15 * sin(_t * 4.0))
	for i in line_sparks.size():
		line_sparks[i].visible = fmod(_t * 2.0 + i * 0.33, 1.0) < 0.5


# --- The safe mistakes' gentle pictures ---------------------------------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if not on:
		return
	var holder := mistake_holder()
	match event:
		"wet_spark":   # wet hands on the dryer: drops on it and a small yellow zigzag, still
			for i in 4:
				LifeRoomKit.sphere(holder, "Drop", 0.02, dryer.position + Vector3(-0.08 + i * 0.05, 0.06, 0.05),
					Color(0.45, 0.75, 0.95, 0.85))
			_zigzag(holder, dryer.position + Vector3(0, 0.18, 0.04))
			LifeRoomKit.sign(holder, "Why", "WATER LETS ELECTRICITY THROUGH", dryer.position + Vector3(0, 0.55, 0.1), 0.0035,
				Color("ffd23f"))
		"current_through":   # a helper frozen holding Gus's arm: both softly glowing, worried, never hurt
			var helper := LifeBuddy.new(Color(0.18, 0.5, 0.42, 1.0), "Helper")
			helper.position = gus.position + Vector3(0.55, 0, 0.45)
			helper.rotation.y = gus.rotation.y
			holder.add_child(helper)
			LifeRoomPeople.feel(helper, "worried")
			helper.arm_near.rotation = Vector3(-1.3, 0, 0)
			var g := LifeRoomKit.sphere(holder, "Glow", 0.5, helper.position + Vector3(0, 0.6, 0), SPARK)
			g.material_override = LifeRoomKit.material(Color(1.0, 0.86, 0.3, 0.3), true)
			LifeRoomKit.sign(holder, "Why", "NOW TWO ARE STUCK", gus.position + Vector3(0.3, 2.0, 0.3), 0.0045, Color("ffd23f"))
		"ground_live":   # soft yellow rings on the ground round the line, reaching a figure who walked up to look
			var at := STORM + Vector3(5.6, 0.02, -4.7)
			for r: float in [1.2, 2.2, 3.2]:
				var ring := LifeRoomKit.cylinder(holder, "Ring", r, 0.01, at, Color(1.0, 0.86, 0.3, 0.28))
				ring.material_override = LifeRoomKit.material(Color(1.0, 0.86, 0.3, 0.28), true)
			var figure := LifeBuddy.new(Color(0.18, 0.5, 0.42, 1.0), "Looking")
			figure.position = STORM + Vector3(3.5, 0, -4.5)
			figure.rotation.y = -PI / 2
			holder.add_child(figure)
			LifeRoomPeople.feel(figure, "worried")
			LifeRoomKit.sign(holder, "Why", "THE GROUND NEAR IT CAN BE LIVE", STORM + Vector3(3.5, 1.9, -4.5), 0.0045,
				Color("ffd23f"))


func _zigzag(parent: Node3D, at: Vector3) -> void:
	for i in 3:
		var bar := LifeRoomKit.box(parent, "Zig", Vector3(0.015, 0.07, 0.01), at + Vector3(0.02 * (i % 2), 0.05 * i, 0), SPARK)
		bar.rotation.z = 0.6 if i % 2 == 0 else -0.6
		bar.material_override = LifeRoomKit.material(SPARK, true)


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## A home with its bath corner, living room and kitchen corner (and on Big the hall): planks and tiles, a tiled wall by
## the bath, a short wall between the bath corner and the living room, end walls, a skirting, a splashback, a rug, a
## picture, a plant, an armchair, a garden all round under a soft sky; the park's path, benches and trees (Middle); the
## storm's path's hedges (Big). The places' own boxes drawn in one mesh each, the people in few.
func _home_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Land", Vector3(130, 0.1, 70), Vector3(0, -0.14, 0), Color("86c063"), 0.0, LifeRoomDecor.SHELL)
	# the house
	d.tiled("BathWall", LifeRoomDecor.TILE, Vector3(2.9, 1.4, 0.02), Vector3(-2.55, 0.7, -2.39), Color("d6ecf2"), 0.3)
	d.box("ShortWall", Vector3(0.1, 2.6, 0.45), Vector3(-1.0, 1.3, -2.18), WALL.darkened(0.04), 0.0, LifeRoomDecor.SHELL)
	for x: float in [-4.0, 8.0]:
		d.box("EndWall", Vector3(0.1, 2.6, 5.4), Vector3(x, 1.3, 0.2), WALL.darkened(0.03), 0.0, LifeRoomDecor.SHELL)
	d.skirting("Skirting", Vector3(-0.95, 0, -2.39), Vector3(8.0, 0, -2.39), Color("c89a62"))
	d.tiled("Splashback", LifeRoomDecor.TILE, Vector3(1.6, 0.45, 0.02), Vector3(5.0, 1.13, -2.385), Color("d6ecf2"), 0.2)
	d.rug("Rug", Vector3(1.0, 0.0, 0.6), Vector2(2.2, 1.4), Color("cfe0ee"), Color("3a7be8"))
	d.picture("Picture", Vector3(1.9, 1.6, -2.39), Vector2(0.5, 0.4), 0.0, Color("8a6239"), Color("fff6e0"), 0)
	d.plant("Plant", Vector3(7.55, 0, -1.95), 1.0)
	d.box("Armchair", Vector3(0.8, 0.42, 0.75), Vector3(7.3, 0.21, 1.9), Color("e8b04a"))
	d.box("ArmchairBack", Vector3(0.8, 0.5, 0.18), Vector3(7.3, 0.67, 2.2), Color("d69a3a"))
	if track == "middle":
		d.tiled("ParkPath", LifeRoomDecor.DIRT, Vector3(1.4, 0.02, 12.0), PARK + Vector3(-1.4, 0.012, -1.0), Color("e6d2b0"), 1.0)
		d.bench("ParkBench", PARK + Vector3(-6.4, 0, -2.0), PI / 2)
		for t: Vector3 in [Vector3(-9.0, 0, -7.0), Vector3(-6.0, 0, -8.0), Vector3(14.5, 0, -7.0), Vector3(-9.5, 0, 3.0)]:
			d.tree("ParkTree", PARK + t, 1.3)
		d.bush("ParkBush", PARK + Vector3(6.0, 0, 2.6), 1.1)
	if track == "big":
		d.rug("HallRug", Vector3(6.9, 0.0, -1.2), Vector2(0.9, 1.6), Color("e8b04a"), Color("c0563a"))
		for z: float in [-8.0, 2.0]:
			d.bush("StormBush", STORM + Vector3(-2.2, 0, z), 1.2, Color("4f8a3e"))
	for place: Node3D in [get_node_or_null("Park") as Node3D, get_node_or_null("Storm") as Node3D, kite]:
		if place != null:
			LifeRoomPeople.merge_parts(self, place)
	LifeRoomPeople.merge_person(gus)   # his arm comes up when he is stuck
	var g2 := get_node_or_null("GusPark") as LifeBuddy
	if g2 != null:
		LifeRoomPeople.merge_person(g2, true)
	if mo != null:
		LifeRoomPeople.merge_person(mo, true)
