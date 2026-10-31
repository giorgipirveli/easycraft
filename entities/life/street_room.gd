class_name StreetRoom
extends LifeRoom
## Owner #112 (docs/design/life-skills.md §5 #4, §6): Safe Streets' practice street. A real-sized town street (two 3 m
## lanes, pavements with kerbs, houses, trees, a lay-by with parked cars) with real-sized cars from the cars (#109:
## CarModels, the off-roader, the pickup, the race car, the bus) moving at real town speeds on the region's side
## (LifeTraffic, scripted: never the world's cars). Their engines hum (VehicleSounds' loop, positional), so a child can
## listen as well as look. Calm and clearly practice: a car that a child steps out in front of stops gently before the
## crossing (LifeTraffic.stop_for_child), never a crash.
## - Little: Gus the grown-up buddy holds the child's hand; stop at the kerb, look, listen, cross on a big gap; the
##   family car in the lay-by: the back seat, the booster, the belt.
## - Middle: the van parked in the lay-by (step out only to its edge), the button crossing (the button, WAIT, the red and
##   the green man, the cars' lights), night (light clothes, a shiny band, a torch), Pip-pop's bike helmet.
## - Big: a cut-away practice car "on rollers" in the near lane at the crossing's stop line: its belt, brake and
##   accelerator, its speedometer; only the far lane drives (oncoming); the cars' light, people crossing, a phone, a ball.
## The street runs along x, the crossing at x = 0, the child's pavement on +z (LifeTraffic's frame).

const ROAD := Color("4a5160")
const LINE := Color("eef2f5")
const PAVEMENT := Color("c9ced6")
const KERB := Color("aab3bf")
const GRASS := Color("8cc56a")
const HOUSE_COLOURS: Array[Color] = [Color("f1e4cc"), Color("dfe7f5"), Color("f6d6c8"), Color("e2f0d2"), Color("fbe9a8")]
const LAMP_OFF := Color("dfe3ea")
const LAMP_ON := Color(1.0, 0.92, 0.6)
const RED_ON := Color(1.0, 0.35, 0.3)
const AMBER_ON := Color(1.0, 0.72, 0.2)
const GREEN_ON := Color(0.3, 0.95, 0.45)
const UNLIT := Color("2b2f38")
const KERB_Z := 3.0
const BAY_Z := 5.0
const BAY: Vector2 = Vector2(-26.0, -8.0)
const VAN_X := -14.0
const VAN_EDGE_X := -11.0
const FAMILY_CAR_X := -22.0
const HELMET_X := 10.0

var traffic: LifeTraffic
var near_dir := 1
var cars := {}   # id -> {node, engine}
var gus: LifeBuddy
var pip: LifeBuddy
var walker: LifeBuddy
var van: Node3D
var family_car: Node3D
var car_door: Node3D
var belt_view: MeshInstance3D
var ego: Node3D
var speedo: Label3D
var phone_screen: MeshInstance3D
var ball: MeshInstance3D
var band: MeshInstance3D
var torch_light: OmniLight3D
var lamps: Array[MeshInstance3D] = []
var ped_red: Array[MeshInstance3D] = []
var ped_green: Array[MeshInstance3D] = []
var car_heads: Array[Array] = []   # [red, amber, green] per head
var wait_light: MeshInstance3D
var night := false
var current := {}
var _lights_shown := ""
var _ped_shown := ""
var _hidden_engine: AudioStreamPlayer3D


func build() -> void:
	name = "StreetRoom"
	near_dir = 1 if str(vars.get("drive", "right")) == "right" else -1
	env = LifeRoomKit.environment(Color("8ec5f0"), Color("e9f3fb"), 0.65)
	start_view = "driver" if track == "big" else ("van" if track == "middle" else "pavement")
	var only: Array[int] = []
	if track == "big":
		only.append(LifeTraffic.FAR)
	traffic = LifeTraffic.new(int(vars.get("seed", 0)), str(vars.get("drive", "right")), only)
	_street()
	_houses()
	if track != "big":
		_lay_by()
	if track != "little":
		_crossing()
	match track:
		"little":
			_gus()
			_family_car()
		"middle":
			_van()
			_night_things()
			_helmet()
		"big":
			_ego_car()
			_walker()
	_targets()
	_street_look()   # the rooms' look (2026-10-18)
	_views()
	_sync_cars()


# --- The street ------------------------------------------------------------------------------------------------------

func _street() -> void:
	var half := LifeTraffic.ENTER_X + 6.0
	var d := decor()   # the rooms' look: asphalt, paving slabs, the game's grass
	d.tiled("Road", LifeRoomDecor.ASPHALT, Vector3(half * 2.0, 0.1, KERB_Z * 2.0), Vector3(0, -0.05, 0), Color("c8ccd4"), 1.0)
	var sc := scenery()
	for i in int(half * 2.0 / 4.0):
		LifeRoomKit.box(sc, "CentreLine", Vector3(2.0, 0.02, 0.12), Vector3(-half + 1.0 + i * 4.0, 0.005, 0), LINE)
	for side: float in [1.0, -1.0]:
		d.tiled("Pavement", LifeRoomDecor.SLABS, Vector3(half * 2.0, 0.24, 4.0), Vector3(0, 0.0, side * (KERB_Z + 2.0)),
			Color("eef0f2"), 1.0)
		LifeRoomKit.box(sc, "Kerb", Vector3(half * 2.0, 0.26, 0.18), Vector3(0, 0.0, side * (KERB_Z + 0.09)), KERB)
		d.tiled("Verge", LifeRoomDecor.GRASS, Vector3(half * 2.0, 0.1, 6.0), Vector3(0, -0.05, side * (KERB_Z + 7.0)), Color("dcefc8"),
			1.0)
	for x: float in [-30.0, -4.0, 22.0, 40.0]:
		for side: float in [1.0, -1.0]:
			var tx := x + side * 3.0
			if side > 0.0 and absf(tx) < 2.5:
				tx -= 3.5   # the rooms' look: never over the child's first view, on the pavement by the crossing
			_tree(Vector3(tx, 0, side * 7.4))
	for x: float in [-20.0, 6.0, 30.0]:
		for side: float in [1.0, -1.0]:
			LifeRoomKit.box(sc, "LampPost", Vector3(0.12, 4.2, 0.12), Vector3(x, 2.1, side * (KERB_Z + 0.5)), Color("6b7380"))
			lamps.append(LifeRoomKit.sphere(self, "Lamp", 0.22, Vector3(x, 4.3, side * (KERB_Z + 0.5)), LAMP_OFF))
	# across the street, lower (on the near pavement the driver's view had it half under the HUD's bar)
	LifeRoomKit.sign(self, "PracticeSign", "PRACTICE STREET", Vector3(-6.0, 2.2, -KERB_Z - 3.6), 0.005)
	LifeRoomKit.box(sc, "LimitPole", Vector3(0.08, 2.2, 0.08), Vector3(-near_dir * 12.0, 1.1, KERB_Z + 0.4), Color("6b7380"))
	var limit := LifeRoomKit.cylinder(sc, "LimitSign", 0.3, 0.04, Vector3(-near_dir * 12.0, 2.3, KERB_Z + 0.4), Color.WHITE)
	limit.rotation.x = PI / 2
	var number := LifeRoomKit.sign(self, "LimitNumber", str(vars.get("speed_limit", 30)),
		Vector3(-near_dir * 12.0, 2.3, KERB_Z + 0.46), 0.005, Color("1f2a4a"))
	number.outline_size = 0
	LifeRoomKit.light(self, Vector3(0, 6, 2), 0.45, 30.0)   # the room's sun is the key light now


func _tree(at: Vector3) -> void:
	LifeRoomKit.box(scenery(), "Trunk", Vector3(0.3, 2.0, 0.3), at + Vector3(0, 1.0, 0), Color("a8642a"))
	LifeRoomKit.sphere(scenery(), "Crown", 1.2, at + Vector3(0, 2.7, 0), Color("4f9a3e"))


func _houses() -> void:
	var i := 0
	for x in range(-44, 48, 11):
		for side: float in [1.0, -1.0]:
			var c: Color = HOUSE_COLOURS[i % HOUSE_COLOURS.size()]
			i += 1
			var z := side * 11.5
			# the rooms' look: the kit's house (a pitched roof, windows, a door) where the boxes stood, facing the street
			decor().house("House", Vector3(x, 0, z), Vector3(8.0, 5.0, 4.0), PI if side > 0.0 else 0.0, c,
				[Color("c0563a"), Color("b5583f"), Color("8f5a4a")][i % 3], Color("8a5a34"), 2)


## The lay-by: a parking bay beside the near pavement (its kerb further back), where the van and the family car park.
func _lay_by() -> void:
	var w := BAY.y - BAY.x
	var mid := (BAY.x + BAY.y) * 0.5
	decor().tiled("Bay", LifeRoomDecor.ASPHALT, Vector3(w, 0.1, BAY_Z - KERB_Z), Vector3(mid, -0.045, (KERB_Z + BAY_Z) * 0.5),
		Color("d4d8de"), 1.0)
	LifeRoomKit.box(scenery(), "BayKerb", Vector3(w, 0.27, 0.18), Vector3(mid, 0.0, BAY_Z + 0.09), KERB)
	for x: float in [BAY.x, BAY.x + 9.0, BAY.y]:
		LifeRoomKit.box(scenery(), "BayLine", Vector3(0.12, 0.02, BAY_Z - KERB_Z), Vector3(x, 0.006, (KERB_Z + BAY_Z) * 0.5), LINE)


## The button crossing at x = 0: two dashed lines across, a pole each side with the red and the green man facing
## across, the button with its WAIT light on the near pole, and the cars' lights at each direction's stop line.
func _crossing() -> void:
	for x: float in [-1.6, 1.6]:
		for i in 6:
			LifeRoomKit.box(scenery(), "CrossLine", Vector3(0.12, 0.02, 0.6), Vector3(x, 0.006, -KERB_Z + 0.5 + i * 1.0), LINE)
	for side: float in [1.0, -1.0]:
		var at := Vector3(1.8 * side, 0, side * (KERB_Z + 0.35))
		LifeRoomKit.box(scenery(), "CrossPole", Vector3(0.1, 2.6, 0.1), at + Vector3(0, 1.3, 0), Color("3b3f4a"))
		var head := LifeRoomKit.box(self, "WalkHead", Vector3(0.36, 0.7, 0.2), at + Vector3(0, 2.4, -side * 0.1), Color("1f2a4a"))
		ped_red.append(_figure(head, Vector3(0, 0.15, -side * 0.11), RED_ON))
		ped_green.append(_figure(head, Vector3(0, -0.17, -side * 0.11), GREEN_ON))
	var box := LifeRoomKit.box(self, "ButtonBox", Vector3(0.18, 0.26, 0.14), Vector3(0.9, 1.0, KERB_Z + 0.3), Color("ffd23f"))
	var push := LifeRoomKit.sign(box, "Push", "PUSH", Vector3(0, -0.06, -0.08), 0.0022, Color("1f2a4a"))
	push.outline_size = 0
	wait_light = LifeRoomKit.box(box, "Wait", Vector3(0.12, 0.05, 0.02), Vector3(0, 0.08, -0.075), UNLIT)
	add_target("button", box, 0.16)
	for dir: int in [1, -1]:   # each direction's lights, just past the crossing (seen from the stop line), facing its cars
		var lane_z := LifeTraffic.lane_z(LifeTraffic.NEAR if dir == near_dir else LifeTraffic.FAR)
		var at := Vector3(dir * 2.5, 0, signf(lane_z) * (KERB_Z + 0.35))
		LifeRoomKit.box(scenery(), "LightPole", Vector3(0.12, 3.0, 0.12), at + Vector3(0, 1.5, 0), Color("3b3f4a"))
		var head := LifeRoomKit.box(self, "LightHead", Vector3(0.3, 0.8, 0.3), at + Vector3(0, 3.2, 0), Color("1f2a4a"))
		var lamps3: Array = []
		for i in 3:
			lamps3.append(LifeRoomKit.sphere(head, "Light%d" % i, 0.09, Vector3(-dir * 0.16, 0.25 - i * 0.25, 0), UNLIT))
		car_heads.append(lamps3)


## A little standing figure (the red or the green man) on a signal head.
func _figure(head: Node3D, at: Vector3, colour: Color) -> MeshInstance3D:
	var body := LifeRoomKit.box(head, "Figure", Vector3(0.08, 0.14, 0.02), at, UNLIT)
	body.set_meta(&"on", colour)
	return body


func _gus() -> void:
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55   # a grown-up
	gus.position = Vector3(0.65, 0.12, 6.0)
	add_child(gus)


func _family_car() -> void:
	family_car = Node3D.new()
	family_car.name = "FamilyCar"
	family_car.position = Vector3(FAMILY_CAR_X, 0, 4.0)
	add_child(family_car)
	var blue := Color("3a7be8")
	LifeRoomKit.box(family_car, "Floor", Vector3(4.0, 0.25, 1.8), Vector3(0, 0.35, 0), blue.darkened(0.2))
	LifeRoomKit.box(family_car, "Bonnet", Vector3(1.0, 0.45, 1.8), Vector3(1.5, 0.7, 0), blue)
	LifeRoomKit.box(family_car, "Boot", Vector3(0.7, 0.45, 1.8), Vector3(-1.65, 0.7, 0), blue)
	LifeRoomKit.box(family_car, "FarSide", Vector3(2.6, 0.45, 0.08), Vector3(-0.2, 0.7, -0.86), blue)
	LifeRoomKit.box(family_car, "Roof", Vector3(2.2, 0.08, 1.8), Vector3(-0.3, 1.5, 0), blue)
	for x: float in [0.8, -1.4]:
		LifeRoomKit.box(family_car, "Pillar", Vector3(0.08, 0.7, 0.08), Vector3(x, 1.15, 0.86), blue.darkened(0.1))
	LifeRoomKit.box(family_car, "FrontSeat", Vector3(0.5, 0.6, 1.4), Vector3(0.35, 0.8, 0), Color("4a4038"))
	LifeRoomKit.box(family_car, "BackSeat", Vector3(0.6, 0.35, 1.6), Vector3(-0.7, 0.65, 0), Color("4a4038"))
	LifeRoomKit.box(family_car, "BackRest", Vector3(0.15, 0.7, 1.6), Vector3(-1.05, 1.0, 0), Color("4a4038"))
	for c: Vector3 in [Vector3(1.3, 0.3, 0.9), Vector3(-1.3, 0.3, 0.9), Vector3(1.3, 0.3, -0.9), Vector3(-1.3, 0.3, -0.9)]:
		var w := LifeRoomKit.cylinder(family_car, "Wheel", 0.3, 0.2, c, Color("26282e"))
		w.rotation.x = PI / 2
	var booster := LifeRoomKit.box(family_car, "Booster", Vector3(0.42, 0.14, 0.42), Vector3(-0.6, 0.88, 0.25), Color("e8544e"))
	add_target("booster", booster, 0.25)
	car_door = Node3D.new()
	car_door.name = "BackDoor"
	car_door.position = Vector3(-1.3, 0, 0.9)
	family_car.add_child(car_door)
	LifeRoomKit.box(car_door, "Panel", Vector3(1.0, 0.9, 0.06), Vector3(0.5, 0.85, 0), blue)
	add_spot_target("belt_top", family_car, Vector3(-0.75, 1.0, 0.55), 0.09)
	add_spot_target("belt_buckle", family_car, Vector3(-0.45, 0.62, -0.1), 0.09)
	belt_view = LifeRoomKit.box(family_car, "Belt", Vector3(0.05, 0.62, 0.02), Vector3(-0.6, 0.82, 0.22), Color("2b2f3a"))
	belt_view.rotation = Vector3(0.6, 0, 0)
	belt_view.visible = false


func _van() -> void:
	van = Node3D.new()
	van.name = "Van"
	van.position = Vector3(VAN_X, 0, (KERB_Z + BAY_Z) * 0.5)
	add_child(van)
	LifeRoomKit.box(van, "Body", Vector3(5.0, 2.0, 1.9), Vector3(0, 1.25, 0), Color.WHITE)
	LifeRoomKit.box(van, "Cab", Vector3(1.0, 1.2, 1.9), Vector3(2.9, 0.85, 0), Color("eef2f5"))
	LifeRoomKit.box(van, "Windscreen", Vector3(0.05, 0.5, 1.6), Vector3(3.4, 1.15, 0), Color("9fd8ff"))
	for c: Vector3 in [Vector3(2.4, 0.35, 0.95), Vector3(-1.8, 0.35, 0.95), Vector3(2.4, 0.35, -0.95), Vector3(-1.8, 0.35, -0.95)]:
		var w := LifeRoomKit.cylinder(van, "Wheel", 0.35, 0.22, c, Color("26282e"))
		w.rotation.x = PI / 2
	var words := LifeRoomKit.sign(van, "VanSign", "PARKED VAN", Vector3(0, 1.6, 0.98), 0.005, Color("1f2a4a"))
	words.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on its side (turned to the eye, half of it sank into the van)


func _night_things() -> void:
	var bench_at := Vector3(1.2, 0.12, 4.5)
	LifeRoomKit.box(scenery(), "Bench", Vector3(1.2, 0.45, 0.4), bench_at + Vector3(0, 0.22, 0), Color("a8642a"))
	band = LifeRoomKit.box(self, "ShinyBand", Vector3(0.3, 0.05, 0.12), bench_at + Vector3(-0.25, 0.48, 0), Color("c8ff6a"))
	add_target("band", band, 0.16)
	var torch := LifeRoomKit.cylinder(self, "Torch", 0.04, 0.22, bench_at + Vector3(0.3, 0.5, 0), Color("3a7be8"))
	torch.rotation.z = PI / 2
	add_target("torch", torch, 0.15)
	torch_light = LifeRoomKit.light(self, Vector3(0.4, 1.0, 4.2), 0.0, 6.0, Color(1, 0.96, 0.8))


func _helmet() -> void:
	pip = LifeBuddy.new(Color("e85a9a"), "PipPop")
	pip.position = Vector3(HELMET_X, 0.12, 4.9)
	add_child(pip)
	var helmet := LifeRoomKit.sphere(pip.head, "Helmet", 0.21, Vector3(0, 0.27, 0), Color("3a7be8"))
	helmet.scale = Vector3(1.0, 0.7, 1.05)
	var bike := Node3D.new()
	bike.name = "Bike"
	bike.position = Vector3(HELMET_X + 1.0, 0.12, 4.7)
	add_child(bike)
	for x: float in [-0.5, 0.5]:
		var w := LifeRoomKit.cylinder(bike, "BikeWheel", 0.32, 0.05, Vector3(x, 0.32, 0), Color("26282e"))
		w.rotation.x = PI / 2
	LifeRoomKit.box(bike, "Frame", Vector3(1.0, 0.06, 0.05), Vector3(0, 0.55, 0), Color("e8544e"))
	LifeRoomKit.box(bike, "Bars", Vector3(0.05, 0.05, 0.5), Vector3(0.45, 0.9, 0), Color("2b2f38"))
	add_spot_target("helmet_brow", pip.head, Vector3(0, 0.24, 0.18), 0.07)
	add_spot_target("strap_left", pip.head, Vector3(0.17, 0.1, 0.06), 0.06)
	add_spot_target("strap_right", pip.head, Vector3(-0.17, 0.1, 0.06), 0.06)
	add_spot_target("helmet_buckle", pip.head, Vector3(0, -0.02, 0.13), 0.06)
	add_spot_target("chin_strap", pip.head, Vector3(0.04, 0.0, 0.16), 0.06)


## The Big track's practice car: cut away (a low dashboard, no roof), on rollers in the near lane at the stop line.
func _ego_car() -> void:
	ego = Node3D.new()
	ego.name = "PracticeCar"
	ego.position = Vector3(-near_dir * (LifeTraffic.STOP_X + 2.6), 0, LifeTraffic.LANE_Z)
	ego.rotation.y = -near_dir * PI / 2   # its front (-Z) along the near lane's way
	add_child(ego)
	var c := Color("ffb02e")
	LifeRoomKit.box(ego, "Floor", Vector3(1.8, 0.12, 4.0), Vector3(0, 0.3, 0), Color("3b3f4a"))
	LifeRoomKit.box(ego, "Bonnet", Vector3(1.8, 0.5, 1.2), Vector3(0, 0.6, -1.5), c)
	LifeRoomKit.box(ego, "Boot", Vector3(1.8, 0.5, 0.7), Vector3(0, 0.6, 1.65), c)
	for side: float in [-1.0, 1.0]:
		LifeRoomKit.box(ego, "Side", Vector3(0.08, 0.35, 2.2), Vector3(side * 0.88, 0.55, 0.2), c)
	LifeRoomKit.box(ego, "Dash", Vector3(1.7, 0.06, 0.35), Vector3(0, 0.88, -0.65), Color("2b2f38"))
	for x: float in [-0.45, 0.45]:   # the driver's side is the one nearer the road's middle (LifeTraffic: z 1.1)
		LifeRoomKit.box(ego, "Seat", Vector3(0.5, 0.45, 0.5), Vector3(x, 0.55, 0.15), Color("4a4038"))
		LifeRoomKit.box(ego, "SeatBack", Vector3(0.5, 0.7, 0.12), Vector3(x, 1.0, 0.42), Color("4a4038"))
	for z: float in [-1.4, 1.4]:
		var roller := LifeRoomKit.cylinder(ego, "Roller", 0.25, 2.0, Vector3(0, 0.12, z), Color("9aa7b5"))
		roller.rotation.z = PI / 2
	LifeRoomKit.sign(ego, "Rollers", "PRACTICE CAR ON ROLLERS", Vector3(0, 1.25, -2.2), 0.004)
	var seat := _driver_seat_local()
	var wheel := LifeRoomKit.cylinder(ego, "Wheel", 0.17, 0.03, seat + Vector3(0, 0.0, -0.45), Color("2b2f38"))
	wheel.rotation.x = PI / 2.4
	# beside the wheel on the car's middle side (behind it, the wheel hid half the words from the driver's eye)
	speedo = LifeRoomKit.sign(ego, "Speed", "0 %s" % vars.get("speed_unit", "km/h"),
		seat + Vector3(-signf(seat.x) * 0.52, -0.2, -0.62), 0.0028)
	phone_screen = LifeRoomKit.box(ego, "Phone", Vector3(0.08, 0.02, 0.15), Vector3(-seat.x, 0.79, 0.1), Color("1f2a4a"))
	add_spot_target("driver_belt_top", ego, seat + Vector3(signf(seat.x) * 0.25, -0.15, 0.12), 0.09)   # the outer shoulder
	add_spot_target("driver_buckle", ego, seat + Vector3(-signf(seat.x) * 0.25, -0.55, 0.0), 0.09)   # the inner hip
	var pedal_z := -0.6
	var brake := LifeRoomKit.box(ego, "Brake", Vector3(0.1, 0.05, 0.12), seat + Vector3(-0.1, -0.93, pedal_z), Color("6b7380"))
	var accel := LifeRoomKit.box(ego, "Accelerator", Vector3(0.07, 0.05, 0.16), seat + Vector3(0.12, -0.93, pedal_z), Color("9aa7b5"))
	add_target("brake", brake, 0.1)
	add_target("accelerator", accel, 0.1)
	ball = LifeRoomKit.sphere(self, "Ball", 0.13, Vector3(0, 0.13, -KERB_Z - 1.0), Color("ffb02e"))
	ball.visible = false


## The driver's seat in the practice car's own space: the car's left where cars drive on the right (a left-hand drive),
## its right where they drive on the left; either way the side nearer the road's middle.
func _driver_seat_local() -> Vector3:
	return Vector3(-0.45 * near_dir, 1.15, 0.12)


func _walker() -> void:
	walker = LifeBuddy.new(Color("1fa6a0"), "Walker")
	walker.position = Vector3(0, 0.12, KERB_Z + 1.2)
	walker.rotation.y = PI
	walker.visible = false
	add_child(walker)


func _targets() -> void:
	add_spot_target("look_left", self, Vector3(-7, 1.0, 3.0), 0.3)
	add_spot_target("look_right", self, Vector3(7, 1.0, 3.0), 0.3)
	if track == "big":
		return
	add_spot_target("kerb", self, Vector3(0, 0.15, KERB_Z + 0.55), 0.55)
	LifeRoomKit.cylinder(self, "KerbRing", 0.45, 0.02, Vector3(0, 0.13, KERB_Z + 0.55), Color(0.3, 0.85, 0.4, 0.6))
	add_spot_target("far_kerb", self, Vector3(0, 0.15, -KERB_Z - 0.6), 0.6)
	LifeRoomKit.cylinder(self, "FarRing", 0.5, 0.02, Vector3(0, 0.13, -KERB_Z - 0.6), Color(0.3, 0.85, 0.4, 0.6))
	if track == "middle":
		add_spot_target("van_edge", self, Vector3(VAN_EDGE_X, 0.05, (KERB_Z + BAY_Z) * 0.5), 0.5)
		LifeRoomKit.cylinder(self, "EdgeRing", 0.4, 0.02, Vector3(VAN_EDGE_X, 0.03, (KERB_Z + BAY_Z) * 0.5),
			Color(0.3, 0.85, 0.4, 0.6))
		add_spot_target("far_kerb_van", self, Vector3(VAN_EDGE_X, 0.15, -KERB_Z - 0.6), 0.6)
	if track == "little":
		add_spot_target("gus_hand", gus.arm_near, Vector3(0, -0.34, 0), 0.12)


func _views() -> void:
	add_view("pavement", Vector3(0, 1.4, 7.6), Vector3(0, 0.5, -1), Vector3(0, 0.12, 6.0), 0.0)
	add_view("kerb", Vector3(0, 1.3, 5.0), Vector3(0, 0.55, -3), Vector3(0, 0.12, KERB_Z + 0.7), 0.0)
	add_view("far_side", Vector3(0, 1.4, -3.4), Vector3(0, 0.8, -9), Vector3(0, 0.12, -KERB_Z - 1.4), 0.0)
	add_view("night", Vector3(0.2, 1.4, 6.4), Vector3(1.1, 0.5, 4.0), Vector3(0.2, 0.12, 5.3), 0.0)
	add_view("van", Vector3(VAN_X - 0.4, 1.35, 7.6), Vector3(VAN_X + 1.5, 0.8, 3.0), Vector3(VAN_X - 0.4, 0.12, 6.2), 0.0)
	add_view("van_edge", Vector3(VAN_EDGE_X, 1.3, 5.2), Vector3(VAN_EDGE_X, 0.5, -3), Vector3(VAN_EDGE_X, 0, 4.0), 0.0)
	add_view("far_side_van", Vector3(VAN_EDGE_X, 1.4, -3.4), Vector3(VAN_EDGE_X, 0.8, -9), Vector3(VAN_EDGE_X, 0.12, -KERB_Z - 1.4), 0.0)
	add_view("helmet", Vector3(HELMET_X + 0.3, 1.35, 6.3), Vector3(HELMET_X, 1.0, 4.9), Vector3(HELMET_X, 0.12, 5.85), 0.0)
	add_view("car_back", Vector3(FAMILY_CAR_X - 0.3, 1.4, 6.9), Vector3(FAMILY_CAR_X - 0.6, 0.8, 4.2),
		Vector3(FAMILY_CAR_X - 0.3, 0.12, 5.8), 0.0)
	add_view("in_car", Vector3(FAMILY_CAR_X - 0.4, 1.45, 5.8), Vector3(FAMILY_CAR_X - 0.6, 0.75, 4.1),
		Vector3(FAMILY_CAR_X - 0.6, 0.0, 4.25), -PI / 2)
	if track == "big":
		var eye := ego.transform * _driver_seat_local()
		var ahead := Vector3(near_dir, 0, 0)
		var feet := Vector3(eye.x, 0.0, eye.z)
		add_view("driver", eye - ahead * 0.55 + Vector3(0, 0.45, 0), eye + ahead * 3.0 + Vector3(0, -0.5, 0), feet,
			ego.rotation.y)
		add_view("pedals", eye - ahead * 0.35 + Vector3(0, 0.25, 0), eye + ahead * 0.6 + Vector3(0, -0.75, 0), feet,
			ego.rotation.y)
		add_view("seat", eye + ahead * 0.8 + Vector3(0, 0.15, 0), eye + Vector3(0, -0.35, 0) - ahead * 0.05, feet,
			ego.rotation.y)   # the belt, seen from the dashboard


# --- Every frame: the traffic, the lights ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	super(delta)
	traffic.step(delta)
	_sync_cars()
	_show_lights()
	if current.get("kind", "") == "cross" and str(current.get("rule", "")) == "green" and traffic.lights == "go":
		traffic.press_button()   # the button stays pressed while the child waits at a button crossing


func _sync_cars() -> void:
	var alive := {}
	for c: Dictionary in traffic.cars:
		var id := int(c.id)
		alive[id] = true
		if not cars.has(id):
			cars[id] = _make_car(c)
		var n := cars[id].node as Node3D
		n.position = Vector3(float(c.x), 0.0, LifeTraffic.lane_z(int(c.lane)))
	for id: int in cars.keys():
		if not alive.has(id):
			(cars[id].node as Node3D).queue_free()
			cars.erase(id)


func _make_car(c: Dictionary) -> Dictionary:
	var kind: StringName = c.kind
	var n := Node3D.new()
	n.name = "Car%d" % int(c.id)
	n.rotation.y = -int(c.dir) * PI / 2   # a car's model fronts along -Z
	add_child(n)
	var body := MeshInstance3D.new()
	body.mesh = _car_mesh(kind, int(c.colour))   # the rooms' look: its body and wheels in one (the Quest's draws)
	body.material_override = WeaponModels.material()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(body)
	var engine: AudioStreamPlayer3D = null
	var stream := VehicleSounds.engine(kind)
	if stream != null:
		engine = AudioStreamPlayer3D.new()
		engine.name = "Engine"
		engine.stream = stream
		engine.bus = Audio.BUS
		engine.unit_size = 4.0
		engine.max_distance = 45.0
		engine.volume_db = -8.0
		engine.pitch_scale = 0.8 + float(c.top) / 30.0
		n.add_child(engine)
		if is_inside_tree():
			engine.play()
	return {"node": n, "engine": engine}


## A car of `kind` in `colour`: its body and its wheels (where CarKinds puts them, their faces outwards) in one mesh, made
## once per kind and colour. The wheels never turned: the car glides, as before.
static var _car_meshes := {}


static func _car_mesh(kind: StringName, colour: int) -> Mesh:
	var key := [kind, colour]
	if _car_meshes.has(key):
		return _car_meshes[key]
	var body := CarModels.body(kind, colour)
	var wheel := CarModels.wheel(kind)
	var st := SurfaceTool.new()
	for i in body.get_surface_count():
		st.append_from(body, i, Transform3D.IDENTITY)
	if wheel != null:
		for w: Vector3 in CarKinds.wheels(kind):
			var xf := Transform3D(Basis(Vector3.UP, PI / 2 if w.x > 0.0 else -PI / 2), w)
			for i in wheel.get_surface_count():
				st.append_from(wheel, i, xf)
	var mesh := st.commit()
	_car_meshes[key] = mesh
	return mesh


func _show_lights() -> void:
	if not car_heads.is_empty() and traffic.lights != _lights_shown:
		_lights_shown = traffic.lights
		var lit := {"go": 2, "wait": 2, "amber": 1, "stop": 0}.get(traffic.lights, 2) as int
		var colours: Array[Color] = [RED_ON, AMBER_ON, GREEN_ON]
		for head: Array in car_heads:
			for i in 3:
				(head[i] as MeshInstance3D).material_override = LifeRoomKit.material(colours[i] if i == lit else UNLIT, i == lit)
	if ped_red.is_empty():
		return
	var flashing := traffic.green_flashing() and fmod(traffic.clock, 0.8) < 0.4
	var ped := "green" if traffic.green_man() and not flashing else ("off" if traffic.green_man() else "red")
	if ped != _ped_shown:
		_ped_shown = ped
		for m in ped_red:
			m.material_override = LifeRoomKit.material(RED_ON if ped == "red" else UNLIT, ped == "red")
		for m in ped_green:
			m.material_override = LifeRoomKit.material(GREEN_ON if ped == "green" else UNLIT, ped == "green")
	if wait_light:
		var waiting := traffic.waiting_for_green()
		wait_light.material_override = LifeRoomKit.material(AMBER_ON if waiting else UNLIT, waiting)


## Safe to cross now: the green man and the cars stopped at a button crossing, else a big gap at that place.
func safe_now(step: Dictionary) -> bool:
	if str(step.get("rule", "")) == "green":
		return traffic.safe_green()
	return traffic.safe_gap(cross_x(step))


## Where along the street a cross step crosses (its far kerb's x).
func cross_x(step: Dictionary) -> float:
	return VAN_EDGE_X if str(step.get("target", "")) == "far_kerb_van" else 0.0


# --- Steps and events ------------------------------------------------------------------------------------------------

func step_started(step: Dictionary) -> void:
	current = step
	if str(step.get("kind", "")) == "look":   # the ways to look go with the spot the child stands at
		var feet: Vector3 = view(str(step.get("view", start_view))).feet
		target_node("look_left").position = feet + Vector3(-7.0, 1.0, -0.8)
		target_node("look_right").position = feet + Vector3(7.0, 1.0, -0.8)


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"kerb":
			_walk(gus, Vector3(0.65, 0.12, KERB_Z + 0.7))
		"cross":
			_walk(gus, Vector3(0.65, 0.12, -KERB_Z - 1.4))
		"sit":
			if gus:
				gus.visible = false
	if str(step.get("kind", "")) == "sequence" and belt_view and str(step.id) == "belt":
		belt_view.visible = true


func progress(step: Dictionary, state: Dictionary) -> void:
	if str(step.get("kind", "")) == "steady" and speedo:
		speedo.text = "%d %s" % [roundi(float(state.get("value", 0.0))), vars.get("speed_unit", "km/h")]


func on_event(event: String) -> void:
	match event:
		"gus_here":
			if gus:
				gus.visible = true
		"car_stops":
			traffic.stop_for_child(cross_x(current))
		"car_hidden":
			_hidden_car_sound()
		"ball_rolls":
			_roll_ball()
		"car_door_open":
			if car_door:
				_turn(car_door, 1.2)
		"button_pressed":
			traffic.press_button()
		"green_flashing":
			traffic.flash_next = true
			traffic.press_button()
		"night_on":
			_night(true)
		"day_on":
			_night(false)
		"band_on":
			if band:
				band.visible = false
		"torch_on":
			if torch_light:
				torch_light.light_energy = 1.4
		"light_red":
			traffic.turn_red()
		"light_green":
			traffic.release_red()
		"buddy_crosses":
			_buddy_crosses()
		"phone_buzz":
			if phone_screen:
				phone_screen.material_override = LifeRoomKit.material(Color("9fd8ff"), true)


func _walk(b: LifeBuddy, to: Vector3) -> void:
	if b == null:
		return
	if is_inside_tree() and not UiMotion.calm():
		create_tween().tween_property(b, "position", to, 1.2).set_trans(Tween.TRANS_SINE)
	else:
		b.position = to


func _turn(n: Node3D, yaw: float) -> void:
	if is_inside_tree() and not UiMotion.calm():
		create_tween().tween_property(n, "rotation:y", yaw, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		n.rotation.y = yaw


## A car the child can hear but not see yet: an engine from the first way to look, far along the street, and soft rings
## for a child who can't hear it.
func _hidden_car_sound() -> void:
	var at := Vector3(-near_dir * 40.0, 0.6, LifeTraffic.LANE_Z)
	for i in 3:
		var ring := LifeRoomKit.cylinder(self, "SoundRing", 0.6 + i * 0.5, 0.02, at + Vector3(near_dir * 6.0, 1.2, 0),
			Color(1, 1, 1, 0.5))
		ring.rotation.z = PI / 2
		if is_inside_tree():
			var tw := create_tween()
			tw.tween_property(ring, "scale", Vector3.ONE * 2.5, 2.0 + i * 0.4)
			tw.tween_callback(ring.queue_free)
	var stream := VehicleSounds.engine(&"pickup")
	if stream == null or not is_inside_tree():
		return
	_hidden_engine = AudioStreamPlayer3D.new()
	_hidden_engine.stream = stream
	_hidden_engine.bus = Audio.BUS
	_hidden_engine.unit_size = 10.0
	_hidden_engine.max_distance = 80.0
	_hidden_engine.position = at
	add_child(_hidden_engine)
	_hidden_engine.play()
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		if is_instance_valid(_hidden_engine):
			_hidden_engine.queue_free())


func _roll_ball() -> void:
	if ball == null:
		ball = LifeRoomKit.sphere(self, "Ball", 0.13, Vector3.ZERO, Color("ffb02e"))
	var from := Vector3(near_dir * 4.0, 0.25, -KERB_Z - 1.0) if track == "big" else Vector3(2.0, 0.25, -KERB_Z - 1.0)
	ball.position = from
	ball.visible = true
	var to := from + Vector3(0, -0.12, 2.6)
	if is_inside_tree() and not UiMotion.calm():
		create_tween().tween_property(ball, "position", to, 1.6).set_trans(Tween.TRANS_SINE)
	else:
		ball.position = to


func _buddy_crosses() -> void:
	if walker == null:
		return
	walker.visible = true
	walker.position = Vector3(0, 0.12, KERB_Z + 1.2)
	if is_inside_tree() and not UiMotion.calm():
		var tw := create_tween()
		tw.tween_property(walker, "position", Vector3(0, 0.12, -KERB_Z - 1.2), 5.0)
		tw.tween_property(walker, "visible", false, 0.0)
	else:
		walker.position = Vector3(0, 0.12, -KERB_Z - 1.2)


## Dusk: a calm deep blue, the street lamps glowing (never dark and scary).
func _night(on: bool) -> void:
	night = on
	env.background_color = Color("2a3a66") if on else Color("8ec5f0")
	env.ambient_light_energy = 0.32 if on else 0.65
	nightfall(on)   # the rooms' look: the sky's dome deepens, the sun turns to moonlight
	for l in lamps:
		l.material_override = LifeRoomKit.material(LAMP_ON if on else LAMP_OFF, on)


# --- Life L3b (owner #118, design §14): the crossing's safe mistakes, pictured gently -------------------------------

## The wrong moment tried (Middle): a figure frozen at the road's edge where the child would have stepped out, a soft
## amber strip on the near lane showing the road a car needs to stop, and calm words. The real cars stand still too
## (the freeze); nobody is ever hit, nothing moves.
func on_mistake(event: String, on: bool) -> void:
	if not on or event not in ["step_out_van", "step_out_red", "step_out_gap"]:
		return
	var holder := mistake_holder()
	var x := VAN_EDGE_X if event == "step_out_van" else 0.0
	var figure := LifeBuddy.new(Color(0.18, 0.5, 0.42, 1.0), "SteppingOut")
	figure.position = Vector3(x, 0.0, LifeTraffic.LANE_Z + 0.9)
	holder.add_child(figure)
	LifeRoomPeople.feel(figure, "worried")
	var from := -float(traffic.near_dir())   # the near lane's cars come from this side
	var strip := LifeRoomKit.box(holder, "StoppingRoad", Vector3(12.0, 0.02, 1.4),
		Vector3(x + from * 6.5, 0.03, LifeTraffic.LANE_Z), Color(1.0, 0.82, 0.3, 0.55))
	strip.name = "StoppingRoad"
	var words := {"step_out_van": "THE DRIVER CAN'T SEE YOU BEHIND THE VAN", "step_out_red": "THE CARS STILL HAVE GREEN",
		"step_out_gap": "A CAR NEEDS THIS MUCH ROAD TO STOP"}
	LifeRoomKit.sign(holder, "Why", str(words[event]), Vector3(x + from * 3.0, 1.6, LifeTraffic.LANE_Z), 0.005,
		Color("ffd23f"))


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The street's look beyond its houses and pavements: front gardens with hedges and flowers before the houses, low walls,
## one grassy land and a soft sky. The family car, the van, the bike and the practice car one mesh each (their moving
## parts, targets and screens their own); Gus a head and limbs (his hand is held), the others one body each.
func _street_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Land", Vector3(140, 0.1, 80), Vector3(0, -0.16, 0), Color("86c063"), 0.0, LifeRoomDecor.SHELL)
	for x in range(-44, 48, 11):
		for side: float in [1.0, -1.0]:
			d.bush("Hedge", Vector3(x - 2.6, 0, side * 9.0), 0.9, Color("4f8a3e"))
			d.bush("Flowers", Vector3(x + 2.6, 0, side * 9.0), 0.8, Color("5aa548"), [Color("e85a9a"), Color("ffc93c"),
				Color("9b7fd6")][absi(x) % 3])
	for place: Node3D in [family_car, van, get_node_or_null("Bike") as Node3D, ego]:
		if place != null:
			LifeRoomPeople.merge_parts(self, place)
	if gus != null:
		LifeRoomPeople.merge_person(gus)
	for b: LifeBuddy in [pip, walker]:
		if b != null:
			LifeRoomPeople.merge_person(b, true)
