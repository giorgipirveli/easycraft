class_name EarthRoom
extends LifeRoom
## Owner #118 (docs/design/life-skills.md §14, the catalogue's row 9: nature and weather; Life L3a): Earth and Weather's
## practice places: the practice room (a strong table to shelter under, the window, an inside wall, the door to the
## garden, a hanging lamp and a shelf that sway while it shakes: the view itself never shakes, for comfort), the garden's
## open ground, the park (a lone tree on a hill; storms with soft grey clouds, gentle rain and distant thunder; a hot day
## with shade), the flooded path (Middle), the woods where a child practises staying put, the shelf of the emergency bag
## (Big) and the school's playground (Big, the Expert try). The safe mistake's gentle picture (on_mistake): roof tiles and
## glass frozen in the air by a doorway, where a figure ran out (never anyone hurt). The shaking runs at the room's own
## time (slow on the first tries); "more real" (a grown-up's choice, Big) sways things a little more and the thunder is
## a little nearer.

const FLOOR := Color("e8d8c0")
const WALL := Color("f3efe6")
const WOOD := Color("a8642a")
const GRASS := Color("7cc46a")
const TILE := Color("b5553a")
const PARK := Vector3(20, 0, 0)
const PATH := Vector3(40, 0, 0)
const WOODS := Vector3(-20, 0, 0)
const BAG := Vector3(8, 0, 0)
const STREET := Vector3(-40, 0, 0)

var lamp: Node3D
var shelf: Node3D
var swayers: Array[Node3D] = []
var table: Node3D
var shaking := false
var storm: Node3D
var rain: Array[Node3D] = []
var flood_foam: Array[Node3D] = []
var gus: LifeBuddy
var hot: Node3D
var _shake_t := 0.0
var _rain_t := 0.0
var _thunder_t := 0.0
var _flood_t := 0.0
var _flood := false


func build() -> void:
	name = "EarthRoom"
	env = LifeRoomKit.environment(Color("a9d4f0"), Color("eef6fb"), 0.75)
	start_view = "bag" if track == "big" else "room"
	_room()
	_garden()
	_park()
	_woods()
	if track == "middle":
		_path()
	if track == "big":
		_bag()
		_street()
	_places_look()   # the rooms' look (2026-10-18)
	_views()


# --- The practice room -------------------------------------------------------------------------------------------------

func _room() -> void:
	var d := decor()   # the rooms' look: a plank floor
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(6.2, 0.1, 5.2), Vector3(0, -0.05, 0), Color("f2dcc0"), 0.75)
	var sc := scenery()
	LifeRoomKit.box(sc, "BackWallL", Vector3(1.5, 2.7, 0.1), Vector3(-2.35, 1.35, -2.55), WALL)   # the door's gap at x -2.2
	LifeRoomKit.box(sc, "BackWallM", Vector3(3.4, 2.7, 0.1), Vector3(0.0, 1.35, -2.55), WALL)
	LifeRoomKit.box(sc, "BackWallR", Vector3(1.1, 2.7, 0.1), Vector3(2.55, 1.35, -2.55), WALL)
	LifeRoomKit.box(sc, "LeftWall", Vector3(0.1, 2.7, 5.2), Vector3(-3.1, 1.35, 0), WALL.darkened(0.04))
	var door := LifeRoomKit.box(self, "Door", Vector3(0.9, 2.0, 0.06), Vector3(-2.2, 1.0, -2.47), Color("8a5a34"))
	add_target("door_out", door, 0.5)
	d.window("Window", Vector3(1.8, 1.45, -2.49), 1.0, 0.95, 0.0)
	add_spot_target("inside_wall", self, Vector3(-2.8, 0.45, -0.6), 0.45)
	# high on the back wall, smaller (lower it sat half under the HUD's bar)
	LifeRoomKit.sign(self, "RoomSign", "PRACTICE ROOM", Vector3(0.2, 2.6, -2.45), 0.0036, Color("2f7f6a"))
	LifeRoomKit.light(self, Vector3(0, 2.4, 0), 0.9, 8.0)
	table = Node3D.new()
	table.name = "StrongTable"
	table.position = Vector3(-0.4, 0, -1.2)
	add_child(table)
	LifeRoomKit.box(table, "Top", Vector3(1.4, 0.08, 0.9), Vector3(0, 0.96, 0), WOOD)
	for p: Vector2 in [Vector2(-0.62, -0.38), Vector2(0.6, -0.38), Vector2(-0.62, 0.4), Vector2(0.6, 0.4)]:
		LifeRoomKit.box(table, "Leg", Vector3(0.09, 0.92, 0.09), Vector3(p.x, 0.46, p.y), WOOD.darkened(0.2))
	add_spot_target("table", self, Vector3(-0.4, 0.5, -0.75), 0.5)
	add_spot_target("table_leg", self, Vector3(0.2, 0.5, -0.8), 0.16)
	lamp = Node3D.new()
	lamp.name = "Lamp"
	lamp.position = Vector3(0.6, 2.6, 0.2)
	add_child(lamp)
	LifeRoomKit.box(lamp, "Cord", Vector3(0.02, 0.6, 0.02), Vector3(0, -0.3, 0), Color("3b3f4a"))
	LifeRoomKit.sphere(lamp, "Shade", 0.16, Vector3(0, -0.66, 0), Color(1.0, 0.92, 0.7))
	shelf = Node3D.new()
	shelf.name = "Shelf"
	shelf.position = Vector3(-2.95, 0, 1.4)
	add_child(shelf)
	LifeRoomKit.box(shelf, "Frame", Vector3(0.3, 1.6, 1.0), Vector3(0, 0.8, 0), WOOD)
	for i in 3:
		var books := LifeRoomKit.box(shelf, "Books", Vector3(0.22, 0.25, 0.7), Vector3(0.05, 0.45 + i * 0.45, 0),
			[Color("3a7be8"), Color("e8544e"), Color("ffd23f")][i])
		swayers.append(books)
	var frame := LifeRoomKit.box(self, "Picture", Vector3(0.5, 0.4, 0.03), Vector3(-0.4, 1.7, -2.48), Color("ffb02e"))
	swayers.append(frame)
	var shoes := Node3D.new()
	shoes.name = "Shoes"
	shoes.position = Vector3(0.45, 0, -0.35)
	add_child(shoes)
	for x: float in [-0.07, 0.07]:
		LifeRoomKit.box(shoes, "Shoe", Vector3(0.1, 0.08, 0.22), Vector3(x, 0.04, 0), Color("3a7be8"))
	add_target("shoes", shoes, 0.2)
	if track != "big":
		shoes.visible = false


# --- Outside: the garden's open ground ---------------------------------------------------------------------------------

func _garden() -> void:
	decor().tiled("Lawn", LifeRoomDecor.GRASS, Vector3(16, 0.1, 13), Vector3(0, -0.06, -9.0), Color("dcefc8"), 1.0)
	var sc := scenery()
	LifeRoomKit.box(sc, "Tree", Vector3(0.3, 2.4, 0.3), Vector3(3.5, 1.2, -5.5), Color("8a5a34"))
	LifeRoomKit.sphere(sc, "Leaves", 1.1, Vector3(3.5, 2.8, -5.5), Color("4f9a3e"))
	for x: float in [-7.0, 7.0]:
		LifeRoomKit.box(sc, "Pole", Vector3(0.14, 5.0, 0.14), Vector3(x, 2.5, -12.0), Color("8a5a34"))
	LifeRoomKit.box(sc, "Wire", Vector3(14, 0.02, 0.02), Vector3(0, 4.7, -12.0), Color("3b3f4a"))
	add_spot_target("open_ground", self, Vector3(-2.2, 0.05, -9.0), 0.7)
	LifeRoomKit.sign(self, "OpenSign", "OPEN GROUND", Vector3(-2.2, 1.2, -9.4), 0.004, Color("2f7f6a"))
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55   # a grown-up
	gus.position = Vector3(-1.4, 0, -3.6)
	gus.visible = false
	add_child(gus)


# --- The park: storms and a hot day ------------------------------------------------------------------------------------

func _park() -> void:
	var p := Node3D.new()
	p.name = "Park"
	p.position = PARK
	add_child(p)
	LifeRoomKit.box(p, "Grass", Vector3(14, 0.1, 12), Vector3(0, -0.05, -3), GRASS)
	LifeRoomKit.box(p, "Hill", Vector3(5, 1.2, 4), Vector3(3.5, 0.6, -7), GRASS.darkened(0.12))
	LifeRoomKit.box(p, "LoneTree", Vector3(0.3, 2.2, 0.3), Vector3(3.5, 2.3, -7), Color("8a5a34"))
	LifeRoomKit.sphere(p, "LoneLeaves", 1.0, Vector3(3.5, 3.8, -7), Color("4f9a3e"))
	LifeRoomKit.box(p, "Clubhouse", Vector3(3.0, 2.4, 2.2), Vector3(-3.5, 1.2, -6.0), Color("f1e4cc"))
	LifeRoomKit.box(p, "ClubDoor", Vector3(0.8, 1.8, 0.05), Vector3(-3.5, 0.9, -4.88), Color("8a5a34"))
	for x: float in [-0.9, 0.9]:
		LifeRoomKit.box(p, "GoalPost", Vector3(0.08, 1.2, 0.08), Vector3(x, 0.6, -3.0), Color.WHITE)
	LifeRoomKit.box(p, "GoalBar", Vector3(1.9, 0.08, 0.08), Vector3(0, 1.2, -3.0), Color.WHITE)
	storm = Node3D.new()
	storm.name = "Storm"
	storm.visible = false
	p.add_child(storm)
	for i in 6:
		LifeRoomKit.sphere(storm, "Cloud", 1.2 + 0.2 * (i % 3), Vector3(-5 + i * 2.2, 6.5 + 0.4 * (i % 2), -9), Color(0.55, 0.58, 0.66))
	for i in 14:
		var drop := LifeRoomKit.box(storm, "Rain", Vector3(0.015, 0.35, 0.015), Vector3(-4 + (i * 0.63), 4.0, -1.5 - (i % 5) * 1.2),
			Color(0.75, 0.85, 1.0, 0.7))
		rain.append(drop)
	hot = Node3D.new()
	hot.name = "HotDay"
	hot.visible = false
	p.add_child(hot)
	LifeRoomKit.sphere(hot, "Sun", 0.8, Vector3(-4, 6, -10), Color(1.0, 0.92, 0.5))
	LifeRoomKit.box(hot, "Shade", Vector3(2.6, 0.02, 2.6), Vector3(3.5, 1.22, -7), Color(0.2, 0.35, 0.2, 0.4))
	LifeRoomKit.box(hot, "WaterBottle", Vector3(0.08, 0.22, 0.08), Vector3(0.6, 0.11, -1.2), Color(0.7, 0.88, 1.0, 0.9))


func _path() -> void:
	var p := Node3D.new()
	p.name = "FloodPath"
	p.position = PATH
	add_child(p)
	LifeRoomKit.box(p, "Grass", Vector3(12, 0.1, 12), Vector3(0, -0.05, -3), GRASS)
	LifeRoomKit.box(p, "Path", Vector3(1.4, 0.02, 10), Vector3(0, 0.01, -3), Color("d8d2c4"))
	LifeRoomKit.box(p, "Flood", Vector3(10, 0.18, 2.2), Vector3(0, 0.08, -3.4), Color(0.48, 0.55, 0.62, 0.75))
	for i in 5:
		var foam := LifeRoomKit.box(p, "Foam", Vector3(0.9, 0.04, 0.12), Vector3(-4 + i * 2.0, 0.19, -3.4 + (i % 2) * 0.6), Color(1, 1, 1, 0.8))
		flood_foam.append(foam)
	LifeRoomKit.box(p, "OtherWay", Vector3(1.2, 0.02, 4), Vector3(-2.6, 0.012, 0.0), Color("d8d2c4"))
	LifeRoomKit.sign(p, "FloodSign", "FLOOD: TURN AROUND", Vector3(1.2, 1.4, -1.8), 0.004, Color("ffd23f"))
	p.visible = false


func _woods() -> void:
	var w := Node3D.new()
	w.name = "Woods"
	w.position = WOODS
	add_child(w)
	LifeRoomKit.box(w, "Ground", Vector3(12, 0.1, 12), Vector3(0, -0.05, -2), Color("6b8f4e"))
	for t: Vector3 in [Vector3(0, 0, -0.55), Vector3(-2.5, 0, -2.5), Vector3(2.4, 0, -3.0), Vector3(-1.0, 0, -5.0), Vector3(3.5, 0, 0.5),
			Vector3(-3.6, 0, 0.2), Vector3(1.2, 0, -6.5)]:
		LifeRoomKit.box(w, "Trunk", Vector3(0.36, 2.6, 0.36), t + Vector3(0, 1.3, 0), Color("8a5a34"))
		LifeRoomKit.sphere(w, "Crown", 1.1, t + Vector3(0, 3.2, 0), Color("3f8a3a"))
	add_spot_target("tree_trunk", w, Vector3(0, 0.9, -0.55), 0.26)
	LifeRoomKit.box(w, "Bag", Vector3(0.4, 0.3, 0.25), Vector3(0.45, 0.15, -0.35), Color("e8544e"))
	var jacket := LifeRoomKit.box(w, "BrightJacket", Vector3(0.3, 0.06, 0.25), Vector3(0.55, 0.25, -0.45), Color("ffd23f"))
	add_target("bright_jacket", jacket, 0.2)
	var whistle := LifeRoomKit.box(w, "Whistle", Vector3(0.08, 0.04, 0.04), Vector3(0.3, 0.3, -0.25), Color("e8544e"))
	add_target("whistle", whistle, 0.13)
	if track != "big":
		jacket.visible = false
		whistle.visible = false


func _bag() -> void:
	var b := Node3D.new()
	b.name = "BagShelf"
	b.position = BAG
	add_child(b)
	LifeRoomKit.box(b, "Floor", Vector3(4, 0.1, 4), Vector3(0, -0.05, 0), FLOOR)
	LifeRoomKit.box(b, "Wall", Vector3(4, 2.6, 0.1), Vector3(0, 1.3, -1.35), WALL)
	for y: float in [0.85, 1.15]:
		LifeRoomKit.box(b, "Board", Vector3(1.9, 0.04, 0.35), Vector3(0, y, -1.05), WOOD)
	var items := [["water_bottles", Vector2(-0.7, 1.25), Color(0.7, 0.88, 1.0, 0.9)], ["torch", Vector2(-0.25, 1.25), Color("3a3f4a")],
		["bag_whistle", Vector2(0.2, 1.25), Color("e8544e")], ["first_aid_kit", Vector2(0.65, 1.25), Color("3fbf5a")],
		["warm_layers", Vector2(-0.7, 0.95), Color("7b5cd6")], ["food_tins", Vector2(-0.25, 0.95), Color("c9ced6")],
		["games", Vector2(0.2, 0.95), Color("3a7be8")], ["big_teddy", Vector2(0.65, 0.95), Color("a8642a")]]
	for it: Array in items:
		var at: Vector2 = it[1]
		var n := LifeRoomKit.box(b, "Item_" + str(it[0]), Vector3(0.22, 0.18, 0.2), Vector3(at.x, at.y - 0.06, -1.0), it[2])
		add_target(str(it[0]), n, 0.14)
	LifeRoomKit.box(b, "Bench", Vector3(0.9, 0.42, 0.4), Vector3(0, 0.21, -0.55), WOOD.darkened(0.1))
	var bag := LifeRoomKit.box(b, "EmergencyBag", Vector3(0.45, 0.32, 0.28), Vector3(0, 0.6, -0.55), Color("e8544e"))
	LifeRoomKit.sign(bag, "BagWord", "EMERGENCY BAG", Vector3(0, 0.26, 0.15), 0.0025)
	add_target("till", bag, 0.22)
	# higher, smaller (it sat half under the HUD's bar in the first view)
	LifeRoomKit.sign(b, "ShelfSign", "BE READY", Vector3(0, 2.32, -1.25), 0.0038, Color("2f7f6a"))


func _street() -> void:
	var s := Node3D.new()
	s.name = "Playground"
	s.position = STREET
	add_child(s)
	LifeRoomKit.box(s, "Ground", Vector3(14, 0.1, 12), Vector3(1, -0.05, 4), Color("c9ced6"))
	LifeRoomKit.box(s, "School", Vector3(10, 3.4, 0.4), Vector3(0, 1.7, -0.2), Color("f1e4cc"))
	for x: float in [-3.0, 3.5]:
		LifeRoomKit.box(s, "Roof", Vector3(2.5, 0.12, 0.6), Vector3(x, 3.45, 0.1), TILE)
	var door := LifeRoomKit.box(s, "SchoolDoor", Vector3(1.0, 2.0, 0.06), Vector3(1.4, 1.0, 0.03), Color("3a7be8"))
	add_target("door_in", door, 0.55)
	LifeRoomKit.box(s, "Tree", Vector3(0.3, 2.4, 0.3), Vector3(5.5, 1.2, 1.5), Color("8a5a34"))
	LifeRoomKit.sphere(s, "Leaves", 1.0, Vector3(5.5, 2.8, 1.5), Color("4f9a3e"))
	add_spot_target("clear_space", s, Vector3(3.0, 0.05, 5.2), 0.7)
	LifeRoomKit.sign(s, "ClearSign", "CLEAR SPACE", Vector3(3.0, 1.1, 5.4), 0.004, Color("2f7f6a"))
	LifeRoomKit.sign(s, "SchoolSign", "PRACTICE SCHOOL", Vector3(0, 3.8, 0.1), 0.006, Color("2f7f6a"))


func _views() -> void:
	add_view("room", Vector3(0.3, 1.5, 2.4), Vector3(-0.4, 0.6, -1.3), Vector3(0.2, 0, 1.0), 0.0)
	add_view("window", Vector3(2.4, 1.45, -1.9), Vector3(-0.6, 0.5, -1.0), Vector3(1.6, 0, -1.7), 1.81)
	add_view("under_table", Vector3(-0.3, 1.1, 0.4), Vector3(-0.1, 0.45, -1.0), Vector3(-0.4, 0, -1.05), 0.0)
	add_view("wall", Vector3(-1.4, 1.2, 0.2), Vector3(-2.8, 0.4, -0.6), Vector3(-2.4, 0, -0.6), PI / 2)
	add_view("door", Vector3(-2.2, 1.55, -2.5), Vector3(-2.0, 0.2, -8.5), Vector3(-2.2, 0, -3.3), 0.0)
	add_view("open", Vector3(-2.2, 1.5, -7.6), Vector3(-2.2, 0.4, -13.0), Vector3(-2.2, 0, -8.6), 0.0)
	add_view("park", PARK + Vector3(0, 1.6, 2.4), PARK + Vector3(0.5, 0.8, -4.0), PARK + Vector3(0, 0, 1.0), 0.0)
	add_view("path", PATH + Vector3(0, 1.5, 2.2), PATH + Vector3(0, 0.2, -4.0), PATH + Vector3(0, 0, 1.0), 0.0)
	add_view("woods", WOODS + Vector3(0.3, 1.4, 1.0), WOODS + Vector3(0.1, 0.6, -1.0), WOODS, 0.0)
	add_view("bag", BAG + Vector3(0, 1.35, 1.3), BAG + Vector3(0, 1.0, -1.2), BAG + Vector3(0, 0, 0.3), 0.0)
	add_view("street", STREET + Vector3(-2.5, 1.5, 2.6), STREET + Vector3(3.0, 0.4, 2.6), STREET + Vector3(-1.3, 0, 2.6), -PI / 2)
	add_view("clear", STREET + Vector3(3.0, 1.5, 6.4), STREET + Vector3(3.0, 0.3, 2.0), STREET + Vector3(3.0, 0, 5.2), 0.0)


# --- Events ------------------------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"shake_on", "aftershock", "shake_outside":
			shaking = true
			_shake_t = 0.0
			if is_inside_tree():
				Audio.play(&"serpent_rumble", Vector3.INF, -6.0 if more_real() else -14.0)
		"shake_off":
			shaking = false
			_settle()
		"storm_on":
			storm.visible = true
			hot.visible = false
			env.background_color = Color("8a97ab")
			env.ambient_light_energy = 0.6
		"hot_day":
			storm.visible = false
			hot.visible = true
			env.background_color = Color("bfe3ff")
			env.ambient_light_energy = 0.85
		"flood_on":
			_flood = true
			(get_node("FloodPath") as Node3D).visible = true
		"no_table":
			table.visible = false
			target_node("table").visible = false
			target_node("table_leg").visible = false
		"woods", "name_called":
			pass


func step_started(step: Dictionary) -> void:
	var v := str(step.get("view", start_view))
	gus.visible = v in ["door", "open"] and track == "little"


## Things stop swaying when the shaking stops.
func _settle() -> void:
	lamp.rotation = Vector3.ZERO
	for s in swayers:
		s.rotation = Vector3.ZERO


func _process(delta: float) -> void:
	super(delta)
	var dt := sim_delta(delta)   # the room's own time: slow at a danger step's moment on the first tries
	if shaking:
		_shake_t += dt
		var k := 1.6 if more_real() else 1.0
		lamp.rotation.z = 0.18 * k * sin(_shake_t * 7.0)
		lamp.rotation.x = 0.1 * k * sin(_shake_t * 5.3)
		for i in swayers.size():
			swayers[i].rotation.z = 0.05 * k * sin(_shake_t * (9.0 + i))
	if storm != null and storm.visible:
		_rain_t += dt
		for i in rain.size():
			rain[i].position.y = 4.0 - fmod(_rain_t * 6.0 + i * 0.37, 4.0)
		_thunder_t += dt
		if _thunder_t >= 6.0:
			_thunder_t = 0.0
			if is_inside_tree():
				Audio.play(&"thud", Vector3.INF, -8.0 if more_real() else -16.0)   # distant thunder, soft
	if _flood:
		_flood_t += dt
		for i in flood_foam.size():   # the flood water flows fast across the path
			flood_foam[i].position.x = -4.5 + fmod(i * 2.0 + _flood_t * 2.5, 9.0)


# --- The safe mistake's gentle picture ---------------------------------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if not on or not event in ["falling_tiles", "falling_tiles_in"]:
		return
	var holder := mistake_holder()
	var at := Vector3(-2.2, 0, -2.75) if event == "falling_tiles" else STREET + Vector3(1.4, 0, 0.6)
	var figure := LifeBuddy.new(Color(0.18, 0.5, 0.42, 1.0), "RunningOut")
	figure.position = at
	holder.add_child(figure)
	figure.face("worried")
	for i in 5:   # tiles and a little glass, frozen in the air by the doorway
		var tile := LifeRoomKit.box(holder, "Tile", Vector3(0.28, 0.03, 0.18), at + Vector3(-0.5 + i * 0.25, 1.7 + 0.25 * (i % 3), 0.2),
			TILE)
		tile.rotation = Vector3(0.4 * (i % 2), 0.3 * i, 0.5)
	for i in 3:
		var glass := LifeRoomKit.box(holder, "Glass", Vector3(0.12, 0.12, 0.01), at + Vector3(0.4 - i * 0.3, 1.25 + 0.2 * i, 0.35),
			Color(0.75, 0.9, 1.0, 0.6))
		glass.rotation.z = 0.6 * i
	if event == "falling_tiles":   # the door stands open where the figure ran
		(target_node("door_out") as Node3D).visible = false
	LifeRoomKit.sign(holder, "Falling", "THINGS FALL BY DOORS", at + Vector3(0, 2.6, 0.3), 0.004, Color("ffd23f"))


func show_mistake(event: String, on: bool) -> void:
	super(event, on)
	if not on and has_target("door_out"):
		(target_node("door_out") as Node3D).visible = true


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## Earth and Weather's places dressed: the practice room's skirting, a rug and a plant; the garden's fence and flowers; the
## park's path, benches and bushes; more trees in the woods; the playground's markings, benches and fence; one grassy land
## under all of them and a soft sky. Each place's own boxes drawn as one mesh (the Quest's draws).
func _places_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Land", Vector3(120, 0.1, 80), Vector3(0, -0.14, -4.0), Color("86c063"), 0.0, LifeRoomDecor.SHELL)
	# the practice room
	d.skirting("Skirting", Vector3(-3.04, 0, -2.5), Vector3(-3.04, 0, 2.6), Color("c89a62"))
	d.rug("Rug", Vector3(0.9, 0.0, 0.7), Vector2(1.6, 1.1), Color("f6c9b4"), Color("e8544e"))
	d.plant("Plant", Vector3(2.75, 0, -2.15), 1.0)
	# the garden
	d.fence("Fence", Vector3(-8.0, 0, -15.4), Vector3(8.0, 0, -15.4), Color("fdfaf2"), 0.8)
	for x: float in [-6.0, -4.5, 5.5, 6.8]:
		d.bush("Flowers", Vector3(x, 0, -14.8), 0.8, Color("5aa548"), Color("e85a9a") if x < 0 else Color("ffc93c"))
	# the park
	d.tiled("ParkPath", LifeRoomDecor.DIRT, Vector3(1.2, 0.02, 9.0), PARK + Vector3(-1.6, 0.012, -3.0), Color("e6d2b0"), 1.0)
	d.bench("ParkBench", PARK + Vector3(-5.8, 0, -1.0), PI / 2)
	d.bush("ParkBush", PARK + Vector3(5.8, 0, 1.5), 1.2)
	d.bush("ParkBush", PARK + Vector3(-6.2, 0, -8.4), 1.4)
	# the woods: more trees round the clearing
	for t: Vector3 in [Vector3(-5.2, 0, -5.5), Vector3(5.0, 0, -6.0), Vector3(-5.5, 0, 3.0), Vector3(5.6, 0, 3.4), Vector3(0.0, 0, -8.5)]:
		d.tree("WoodsTree", WOODS + t, 1.1 + 0.1 * absf(t.x) / 5.0, Color("3f8a3a"))
	for m: Vector3 in [Vector3(-1.4, 0, 1.6), Vector3(1.8, 0, 2.2)]:
		d.cylinder("MushroomStem", 0.04, 0.12, WOODS + m + Vector3(0, 0.06, 0), Color("f3ede4"))
		d.cylinder("MushroomCap", 0.11, 0.07, WOODS + m + Vector3(0, 0.15, 0), Color("e8544e"), 0.02)
	if track == "big":
		# the bag's corner of the house: planks, a wainscot, a window
		d.tiled("BagFloor", LifeRoomDecor.PLANKS, Vector3(4.0, 0.012, 3.0), BAG + Vector3(0, 0.006, 0.45), Color("f2dcc0"), 0.75)
		d.box("BagWainscot", Vector3(4.0, 0.8, 0.02), BAG + Vector3(0, 0.4, -1.29), Color("cfe0ee"), 0.0, LifeRoomDecor.SHELL)
		d.window("BagWindow", BAG + Vector3(-1.45, 1.55, -1.29), 0.7, 0.7, 0.0)
		# the playground: markings, a bench, a fence
		for i in 4:
			d.box("Hopscotch", Vector3(0.5, 0.012, 0.5), STREET + Vector3(-3.5, 0.006, 3.2 + i * 0.55), Color("fdfdf8"), 0.0,
				LifeRoomDecor.SHELL)
		d.bench("PlayBench", STREET + Vector3(6.6, 0, 6.0), -PI / 2)
		d.fence("PlayFence", STREET + Vector3(-6.0, 0, 9.8), STREET + Vector3(8.0, 0, 9.8), Color("3a7be8"), 0.9)
	for n: String in ["Park", "Woods", "FloodPath", "BagShelf", "Playground"]:
		var place := get_node_or_null(n) as Node3D
		if place != null:
			LifeRoomPeople.merge_parts(self, place)
	if gus != null:
		LifeRoomPeople.merge_person(gus, true)
