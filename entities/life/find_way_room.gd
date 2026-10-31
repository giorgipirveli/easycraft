class_name FindWayRoom
extends LifeRoom
## Owner #112, #118 (docs/design/life-skills.md §5 row 10, §14 row 14; Life L3c): Find Your Way's practice places, built
## for the track: the practice market (Little, Middle: the stalls, Gus who gets separated and comes back, the safe
## grown-ups: the shop worker with her name badge, a mum with her children, a police officer; and a man who says "Come
## with me!", an ordinary figure who only ever stands where he is: never shown grabbing or following), the practice
## school (Little, Middle: the classroom, the teacher at the door, the line, the fire drill's bell, the meeting point
## outside; a fire drill only, never a lockdown), the practice metro (Middle, Big: the map with the green line and the
## red line meeting at CENTRAL, the ticket gates, the platform with its yellow line, the train, a help point) and the
## practice park (Middle, Big: the compass, the map's key and grid squares, three flags for a bearing, landmarks).
## The game's own metro, named plainly (the region's own metro is in the coach's words: LifeRegion.metro_words).
## The safe mistakes' gentle pictures (on_mistake, still): a see-through figure a few steps off towards the market's way
## out, soft footprints behind it, the man still where he stood ("WALKING AWAY MAKES YOU HARDER TO FIND"); the train frozen
## coming in, soft wind arrows along the edge and a see-through figure at it ("TRAINS COME IN FAST AND CLOSE").

const PAVING := Color("d8d2c4")
const GRASS := Color("7cc46a")
const WOOD := Color("a8642a")
const INK := Color("1f2a4a")
const WHITE := Color("f4f6f8")
const WARM := Color("ffd23f")
const GREEN_LINE := Color("2fae4e")
const RED_LINE := Color("e8544e")
const GHOST := Color(0.12, 0.65, 0.63, 0.45)
const SCHOOL := Vector3(30, 0, 0)
const METRO := Vector3(-30, 0, 0)
const PARK := Vector3(0, 0, 40)
## The child's spot at the market (the start view's VR feet).
const CHILD := Vector3(0, 0, 2.2)
## The train's stop (x along the platform) and where it starts coming in from.
const TRAIN_STOP := 10.0
const TRAIN_FROM := 26.0
const TRAIN_SPEED := 6.0

var gus: LifeBuddy
var worker: LifeBuddy
var stranger: LifeBuddy
var stranger_words: Label3D
var train: Node3D
var train_moving := false
var gate_flap: MeshInstance3D
var group: Array[LifeBuddy] = []
var bell: MeshInstance3D
var _t := 0.0


func build() -> void:
	name = "FindWayRoom"
	env = LifeRoomKit.environment(Color("cfe6f7"), Color("f3f6f9"), 0.8)
	start_view = "metro_map" if track == "big" else "market"
	if track != "big":
		_market()
		_school()
	if track != "little":
		_metro()
		_park()
	_places_look()   # the rooms' look (2026-10-18)
	_views()


# --- The practice market ---------------------------------------------------------------------------------------------------

func _market() -> void:
	# the rooms' look: a sunny town square (its paving where the paving was), the way out's corner kept open
	decor().town_square(Rect2(-7, -6, 14, 12), [Rect2(-7.0, 2.2, 2.6, 2.6)], false)
	LifeRoomKit.sign(self, "MarketSign", "PRACTICE MARKET", Vector3(0, 3.2, -4.5), 0.006, Color("2f7f6a"))
	LifeRoomKit.light(self, Vector3(0, 3.0, 0), 0.8, 12.0)
	_stall(Vector3(0, 0, -2.6), Color("e8544e"), "TOYS")
	_stall(Vector3(-2.2, 0, -1.4), Color("2fae4e"), "FRUIT")
	_stall(Vector3(2.6, 0, -1.8), Color("3a7be8"), "BREAD")
	for i in 3:
		LifeRoomKit.box(scenery(), "Kite", Vector3(0.25, 0.25, 0.02), Vector3(-0.4 + i * 0.4, 1.7, -2.4),
			[Color("e85a9a"), Color("ffd23f"), Color("5aa8e6")][i]).rotation.z = PI / 4
	LifeRoomKit.box(scenery(), "WayOut", Vector3(0.2, 2.4, 0.2), Vector3(-5.4, 1.2, 3.4), WOOD)
	LifeRoomKit.sign(self, "WayOutSign", "WAY OUT", Vector3(-5.4, 2.7, 3.4), 0.004, INK)
	# the shop worker behind her stall, with her name badge
	worker = _grown_up(Color("3fbf5a"), "Worker", Vector3(-2.2, 0, -2.0), 0.0)
	LifeRoomKit.box(worker.hips, "Badge", Vector3(0.1, 0.06, 0.02), Vector3(0.08, 0.32, 0.12), WHITE)
	LifeRoomKit.sign(worker, "BadgeWords", "STAFF", Vector3(0.05, 1.05, 0.25), 0.002, INK)
	_target_on(worker, "worker")
	# a mum with her children, and a police officer
	var mum := _grown_up(Color("e85a9a"), "Mum", Vector3(2.4, 0, 0.4), -0.9)
	_target_on(mum, "parent_kids")
	for i in 2:
		var kid := LifeBuddy.new([Color("ffb347"), Color("5aa8e6")][i], "Kid")
		kid.scale = Vector3.ONE * 0.75
		kid.position = Vector3(2.9 + i * 0.4, 0, 0.7 + i * 0.3)
		kid.rotation.y = -0.9
		add_child(kid)
	var police := _grown_up(Color("2b3a66"), "Police", Vector3(3.6, 0, -3.4), -0.5)
	LifeRoomKit.box(police.head, "Hat", Vector3(0.36, 0.08, 0.34), Vector3(0, 0.34, 0), Color("1f2a4a"))
	LifeRoomKit.box(police.hips, "Badge", Vector3(0.08, 0.08, 0.02), Vector3(-0.08, 0.32, 0.12), WARM)
	_target_on(police, "police")
	# a man who says "Come with me!": an ordinary figure, standing where he is
	stranger = _grown_up(Color("8a9a7a"), "Stranger", Vector3(-2.8, 0, 1.6), 1.2)
	_target_on(stranger, "come_with")
	stranger_words = LifeRoomKit.sign(self, "ComeWith", "\"COME WITH ME!\"", Vector3(-2.8, 2.25, 1.6), 0.004, INK)
	stranger_words.visible = false
	# Gus, your grown-up today, beside you at first
	gus = _grown_up(Color("7b5cd6"), "Gus", CHILD + Vector3(0.8, 0, 0.2), 0.0)


func _stall(at: Vector3, colour: Color, words: String) -> void:
	LifeRoomKit.box(scenery(), "Counter", Vector3(1.6, 0.9, 0.6), at + Vector3(0, 0.45, 0), WOOD)
	LifeRoomKit.box(scenery(), "Awning", Vector3(1.8, 0.08, 0.9), at + Vector3(0, 2.2, -0.1), colour)
	for x: float in [-0.8, 0.8]:
		LifeRoomKit.box(scenery(), "Pole", Vector3(0.06, 2.2, 0.06), at + Vector3(x, 1.1, 0.25), Color("6b4a2a"))
	LifeRoomKit.sign(self, "StallSign", words, at + Vector3(0, 2.5, 0), 0.004, INK)


func _grown_up(colour: Color, buddy_name: String, at: Vector3, yaw: float) -> LifeBuddy:
	var b := LifeBuddy.new(colour, buddy_name)
	b.scale = Vector3.ONE * 1.5
	b.position = at
	b.rotation.y = yaw
	add_child(b)
	return b


func _target_on(b: LifeBuddy, target_name: String) -> void:
	var m := Node3D.new()
	m.name = "T_" + target_name
	m.position = Vector3(0, 0.63, 0.1)
	b.add_child(m)
	add_target(target_name, m, 0.45)


# --- The practice school (a fire drill) -------------------------------------------------------------------------------------

func _school() -> void:
	var s := SCHOOL
	decor().tiled("SchoolFloor", LifeRoomDecor.PLANKS, Vector3(8, 0.1, 6), s + Vector3(0, -0.05, 0), Color("f2dcc0"), 0.75)
	decor().box("SchoolWall", Vector3(8, 2.8, 0.1), s + Vector3(0, 1.4, -3.0), Color("f6efe0"), 0.0, LifeRoomDecor.SHELL)
	LifeRoomKit.box(scenery(), "Board", Vector3(2.4, 1.0, 0.04), s + Vector3(1.0, 1.6, -2.93), Color("2f5a4a"))
	LifeRoomKit.sign(self, "SchoolSign", "PRACTICE SCHOOL", s + Vector3(1.0, 2.5, -2.9), 0.005, Color("2f7f6a"))
	bell = LifeRoomKit.cylinder(self, "Bell", 0.14, 0.06, s + Vector3(-1.2, 2.3, -2.92), Color("e8544e"))
	bell.rotation.x = PI / 2
	for i in 3:
		LifeRoomKit.box(scenery(), "Desk", Vector3(1.0, 0.7, 0.6), s + Vector3(-1.4 + i * 1.6, 0.35, 0.4), WOOD)
	LifeRoomKit.box(scenery(), "Bag", Vector3(0.3, 0.3, 0.15), s + Vector3(0.2, 0.85, 0.5), Color("e8544e"))
	LifeRoomKit.box(scenery(), "Drawing", Vector3(0.3, 0.01, 0.2), s + Vector3(-0.2, 0.71, 0.4), Color("fdfdf8"))
	LifeRoomKit.box(scenery(), "Doorway", Vector3(0.1, 2.2, 1.0), s + Vector3(-3.95, 1.1, -1.6), Color("8a5a34"))
	var teacher := _grown_up(Color("7b5cd6"), "Teacher", s + Vector3(-3.2, 0, -1.6), PI / 2)
	teacher.name = "Teacher"
	add_spot_target("line_spot", self, s + Vector3(-1.8, 0.05, -1.6), 0.5)
	LifeRoomKit.cylinder(self, "LineMark", 0.45, 0.02, s + Vector3(-1.8, 0.02, -1.6), Color(0.3, 0.85, 0.4, 0.6))
	for i in 2:
		var kid := LifeBuddy.new([Color("ffb347"), Color("5aa8e6")][i], "Classmate")
		kid.position = s + Vector3(-2.6 + i * 0.4, 0, -1.6)
		kid.rotation.y = PI / 2
		add_child(kid)
	# outside: the playground's meeting point
	decor().tiled("Playground", LifeRoomDecor.GRASS, Vector3(10, 0.1, 8), s + Vector3(-9, -0.06, -3), Color("dcefc8"), 1.0)
	add_spot_target("meeting_point", self, s + Vector3(-9.0, 0.05, -4.0), 0.7)
	LifeRoomKit.cylinder(self, "MeetMark", 0.65, 0.02, s + Vector3(-9.0, 0.02, -4.0), Color(0.3, 0.85, 0.4, 0.6))
	LifeRoomKit.box(scenery(), "MeetPost", Vector3(0.1, 2.0, 0.1), s + Vector3(-9.0, 1.0, -5.0), Color("6b4a2a"))
	LifeRoomKit.box(scenery(), "MeetBoard", Vector3(1.2, 0.5, 0.05), s + Vector3(-9.0, 2.0, -5.0), Color("2fae4e"))
	LifeRoomKit.sign(self, "MeetSign", "MEETING POINT", s + Vector3(-9.0, 2.0, -4.9), 0.004, WHITE)


# --- The practice metro ---------------------------------------------------------------------------------------------------

const STATIONS := {
	"station_park": ["PARK", Vector2(-1.0, 0.0)], "station_market": ["MARKET", Vector2(-0.5, 0.0)],
	"station_central": ["CENTRAL", Vector2(0.0, 0.0)], "station_school": ["SCHOOL", Vector2(0.55, 0.0)],
	"station_hill": ["HILL", Vector2(0.0, 0.45)], "station_zoo": ["ZOO", Vector2(0.0, -0.3)],
	"station_river": ["RIVER", Vector2(0.0, -0.55)],
}


func _metro() -> void:
	var m := METRO
	decor().tiled("HallFloor", LifeRoomDecor.SLABS, Vector3(20, 0.1, 8), m + Vector3(6, -0.05, -0.5), Color("e6e8ec"), 1.0)
	decor().tiled("HallWall", LifeRoomDecor.TILE, Vector3(20, 3.0, 0.1), m + Vector3(6, 1.5, -3.1), Color("f4f6f8"), 0.5)
	LifeRoomKit.light(self, m + Vector3(4, 2.8, 0), 0.9, 14.0)
	# beside the map, smaller (high on the left the map's view cut it at the edge)
	LifeRoomKit.sign(self, "MetroSign", "PRACTICE METRO", m + Vector3(2.15, 1.95, -2.98), 0.002, INK)
	LifeRoomKit.box(scenery(), "MSign", Vector3(0.4, 0.4, 0.05), m + Vector3(-2.2, 2.0, -3.0), Color("e8544e"))
	LifeRoomKit.sign(self, "M", "M", m + Vector3(-2.2, 2.0, -2.95), 0.006, WHITE)
	# the map: the green line across, the red line up and down, meeting at CENTRAL
	var board := m + Vector3(0, 1.5, -3.0)
	LifeRoomKit.box(scenery(), "MapBoard", Vector3(2.6, 1.5, 0.04), board + Vector3(0, 0, 0.02), WHITE)
	LifeRoomKit.box(self, "GreenLine", Vector3(1.75, 0.05, 0.02), board + Vector3(-0.22, 0, 0.05), GREEN_LINE)
	LifeRoomKit.box(self, "RedLine", Vector3(0.05, 1.1, 0.02), board + Vector3(0, -0.05, 0.05), RED_LINE)
	for id: String in STATIONS:
		var at: Vector2 = STATIONS[id][1]
		var dot := LifeRoomKit.sphere(self, "Station", 0.05, board + Vector3(at.x, at.y, 0.07), WHITE if id != "station_central" else WARM)
		add_target(id, dot, 0.13)
		LifeRoomKit.sign(self, "StationName", str(STATIONS[id][0]), board + Vector3(at.x + 0.05, at.y + 0.11, 0.08), 0.0028, INK)
	LifeRoomKit.sign(self, "Lines", "GREEN LINE   RED LINE", board + Vector3(0, 0.66, 0.08), 0.003, INK)
	# the ticket gates
	var g := m + Vector3(4.5, 0, -1.0)
	for x: float in [-0.5, 0.5]:
		LifeRoomKit.box(scenery(), "GatePost", Vector3(0.3, 1.0, 0.8), g + Vector3(x, 0.5, 0), Color("6b7a99"))
	var reader := LifeRoomKit.box(self, "Reader", Vector3(0.16, 0.03, 0.16), g + Vector3(-0.5, 1.02, 0.15), WARM)
	add_target("gate_reader", reader, 0.11)
	gate_flap = LifeRoomKit.box(self, "Flap", Vector3(0.7, 0.4, 0.04), g + Vector3(0, 0.75, 0), Color("e8544e"))
	# the platform, its yellow line, the edge and the track
	var pf := m + Vector3(TRAIN_STOP, 0, 0)
	LifeRoomKit.box(scenery(), "Platform", Vector3(16, 0.4, 3.0), pf + Vector3(0, 0.2, 0.3), Color("dfe3ea"))
	LifeRoomKit.box(scenery(), "YellowLine", Vector3(16, 0.01, 0.12), pf + Vector3(0, 0.41, -0.65), WARM)
	LifeRoomKit.box(scenery(), "Track", Vector3(40, 0.05, 1.6), pf + Vector3(8, -0.4, -2.0), Color("4a5160"))
	add_spot_target("behind_line", self, pf + Vector3(0, 0.45, 0.4), 0.55)
	LifeRoomKit.cylinder(self, "BehindMark", 0.5, 0.02, pf + Vector3(0, 0.42, 0.4), Color(0.3, 0.85, 0.4, 0.6))
	add_spot_target("platform_edge", self, pf + Vector3(1.6, 0.45, -1.05), 0.4)
	LifeRoomKit.cylinder(self, "EdgeMark", 0.35, 0.02, pf + Vector3(1.6, 0.42, -1.05), Color(0.6, 0.62, 0.68, 0.6))
	train = Node3D.new()
	train.name = "Train"
	train.position = METRO + Vector3(TRAIN_FROM, 0, -2.0)
	train.visible = false   # it waits out of sight in its tunnel (its waiting place is in the market square) until it comes
	add_child(train)
	LifeRoomKit.box(train, "Body", Vector3(8.0, 2.4, 1.5), Vector3(0, 0.85, 0), RED_LINE)
	for i in 4:
		LifeRoomKit.box(train, "Window", Vector3(1.0, 0.6, 0.02), Vector3(-3.0 + i * 2.0, 1.3, 0.76), Color("9fd8ff"))
	# the help point on a pillar
	LifeRoomKit.box(scenery(), "Pillar", Vector3(0.4, 3.0, 0.4), pf + Vector3(3.0, 1.5, 1.6), Color("eef1f4"))
	var hp := LifeRoomKit.box(self, "HelpPoint", Vector3(0.22, 0.32, 0.06), pf + Vector3(3.0, 1.35, 1.38), Color("3a7be8"))
	LifeRoomKit.sign(hp, "Help", "HELP", Vector3(0, 0.22, 0.04), 0.003, WHITE)
	add_target("help_point", hp, 0.12)
	if track == "big":   # your group on the platform (they go on without you, for practice)
		for i in 3:
			var b := LifeBuddy.new([Color("ffb347"), Color("5aa8e6"), Color("e85a9a")][i], "Group")
			b.position = pf + Vector3(-2.0 - i * 0.6, 0.4, 0.8)
			add_child(b)
			group.append(b)


# --- The practice park: the compass, the map, the flags --------------------------------------------------------------------

func _park() -> void:
	var p := PARK
	decor().tiled("ParkGrass", LifeRoomDecor.GRASS, Vector3(30, 0.1, 30), p + Vector3(0, -0.05, -6), Color("dcefc8"), 1.0)
	LifeRoomKit.sign(self, "ParkSign", "PRACTICE PARK", p + Vector3(-4, 2.6, -2), 0.006, Color("2f7f6a"))
	# the compass on its stand, its face tilted up to the child: N, E, S, W and the dial
	var c := Node3D.new()
	c.name = "Compass"
	c.position = p + Vector3(0, 0.92, 0.75)
	c.rotation.x = -1.0
	add_child(c)
	LifeRoomKit.box(scenery(), "CompassStand", Vector3(0.05, 0.9, 0.05), p + Vector3(0, 0.45, 0.75), Color("6b7380"))
	LifeRoomKit.box(c, "Base", Vector3(0.3, 0.3, 0.02), Vector3.ZERO, Color("dfe7f5"))
	LifeRoomKit.box(c, "Arrow", Vector3(0.03, 0.12, 0.012), Vector3(0, 0.16, 0.0), RED_LINE)
	LifeRoomKit.cylinder(c, "Dial", 0.12, 0.012, Vector3(0, 0, 0.016), WHITE).rotation.x = PI / 2
	LifeRoomKit.box(c, "Needle", Vector3(0.016, 0.16, 0.01), Vector3(0, 0.0, 0.03), RED_LINE)
	add_spot_target("compass_dial", c, Vector3(-0.1, -0.06, 0.03), 0.05)
	for d: Array in [["rose_n", "N", Vector2(0, 0.095)], ["rose_e", "E", Vector2(0.095, 0)], ["rose_s", "S", Vector2(0, -0.095)],
			["rose_w", "W", Vector2(-0.095, 0)]]:
		var at: Vector2 = d[2]
		var n := add_spot_target(str(d[0]), c, Vector3(at.x, at.y, 0.035), 0.04)
		LifeRoomKit.sign(n, "Letter", str(d[1]), Vector3.ZERO, 0.0012, INK)
	# the flags: north (red), north-east (blue), east (yellow), from the child's spot
	for f: Array in [["flag_north", Vector3(0, 0, -5.8), RED_LINE], ["flag_ne", Vector3(5.0, 0, -3.8), Color("3a7be8")],
			["flag_east", Vector3(7.0, 0, 1.2), WARM]]:
		var at: Vector3 = p + (f[1] as Vector3)
		LifeRoomKit.box(scenery(), "FlagPole", Vector3(0.06, 2.0, 0.06), at + Vector3(0, 1.0, 0), Color("6b4a2a"))
		LifeRoomKit.box(scenery(), "Flag", Vector3(0.6, 0.4, 0.02), at + Vector3(0.32, 1.75, 0), f[2])
		add_spot_target(str(f[0]), self, at + Vector3(0, 1.2, 0), 0.6)
	# the landmarks: the red bridge over a stream, a big oak, the fountain
	LifeRoomKit.box(scenery(), "Stream", Vector3(14, 0.02, 1.2), p + Vector3(-6, 0.01, -9), Color("5aa8e6"))
	LifeRoomKit.box(scenery(), "Bridge", Vector3(1.4, 0.3, 1.8), p + Vector3(-6, 0.3, -9), RED_LINE)
	LifeRoomKit.box(scenery(), "Oak", Vector3(0.5, 3.0, 0.5), p + Vector3(-8, 1.5, -4), WOOD)
	LifeRoomKit.sphere(scenery(), "OakCrown", 1.6, p + Vector3(-8, 3.6, -4), Color("3f8a3a"))
	LifeRoomKit.cylinder(scenery(), "Fountain", 0.8, 0.5, p + Vector3(-3, 0.25, -6), Color("c9ced6"))
	# the park's map with its key and grid squares
	var m := p + Vector3(-2.6, 1.3, -0.4)
	LifeRoomKit.box(scenery(), "MapPost", Vector3(0.08, 1.3, 0.08), m + Vector3(0, -0.65, 0), Color("6b4a2a"))
	LifeRoomKit.box(scenery(), "ParkMap", Vector3(1.6, 1.2, 0.04), m + Vector3(0, 0.15, 0), Color("dff0d0"))
	for i in 5:
		LifeRoomKit.box(scenery(), "GridV", Vector3(0.01, 0.8, 0.01), m + Vector3(-0.75 + i * 0.2, 0.15, 0.03), INK)
		LifeRoomKit.box(scenery(), "GridH", Vector3(0.8, 0.01, 0.01), m + Vector3(-0.35, -0.25 + i * 0.2, 0.03), INK)
	for i in 4:
		LifeRoomKit.sign(self, "Col", "ABCD"[i], m + Vector3(-0.65 + i * 0.2, -0.32, 0.04), 0.0022, INK)
		LifeRoomKit.sign(self, "Row", str(i + 1), m + Vector3(-0.82, -0.15 + i * 0.2, 0.04), 0.0022, INK)
	add_spot_target("grid_c2", self, m + Vector3(-0.25, 0.05, 0.04), 0.08)
	LifeRoomKit.cylinder(scenery(), "FountainSym", 0.04, 0.01, m + Vector3(-0.25, 0.05, 0.035), Color("5aa8e6")).rotation.x = PI / 2
	add_spot_target("grid_b3", self, m + Vector3(-0.45, 0.25, 0.04), 0.08)
	# the key: the metro's M, first aid's cross, a wood's trees
	LifeRoomKit.sign(self, "Key", "KEY", m + Vector3(0.45, 0.6, 0.04), 0.0025, INK)
	var sm := add_spot_target("sym_metro", self, m + Vector3(0.45, 0.35, 0.04), 0.08)
	LifeRoomKit.box(sm, "Box", Vector3(0.1, 0.1, 0.01), Vector3.ZERO, RED_LINE)
	LifeRoomKit.sign(sm, "M", "M", Vector3(0, 0, 0.01), 0.002, WHITE)
	var sa := add_spot_target("sym_aid", self, m + Vector3(0.45, 0.12, 0.04), 0.08)
	LifeRoomKit.box(sa, "Green", Vector3(0.1, 0.1, 0.01), Vector3.ZERO, Color("2fae4e"))
	LifeRoomKit.box(sa, "CrossA", Vector3(0.06, 0.02, 0.012), Vector3(0, 0, 0.004), WHITE)
	LifeRoomKit.box(sa, "CrossB", Vector3(0.02, 0.06, 0.012), Vector3(0, 0, 0.004), WHITE)
	var sw := add_spot_target("sym_woods", self, m + Vector3(0.45, -0.11, 0.04), 0.08)
	for x: float in [-0.03, 0.03]:
		LifeRoomKit.box(sw, "Tree", Vector3(0.04, 0.07, 0.01), Vector3(x, 0, 0), Color("3f8a3a"))


func _views() -> void:
	if track != "big":
		add_view("market", CHILD + Vector3(0.6, 2.0, 3.2), Vector3(0, 0.9, -0.8), CHILD, 0.0)
		add_view("school", SCHOOL + Vector3(1.6, 2.2, 3.4), SCHOOL + Vector3(-1.6, 0.8, -1.4), SCHOOL + Vector3(0.2, 0, 1.4), 0.0)
		add_view("line_spot", SCHOOL + Vector3(-1.0, 2.6, 2.4), SCHOOL + Vector3(-6.5, 0.4, -3.6), SCHOOL + Vector3(-1.8, 0, -1.6),
			PI / 2)
		add_view("meeting_point", SCHOOL + Vector3(-6.4, 2.0, -0.6), SCHOOL + Vector3(-9.0, 1.0, -4.6), SCHOOL + Vector3(-9.0, 0, -3.4),
			0.0)
	if track != "little":
		var m := METRO
		add_view("metro_map", m + Vector3(0, 1.55, -0.7), m + Vector3(0, 1.45, -3.0), m + Vector3(0, 0, -1.6), 0.0)
		add_view("gates", m + Vector3(4.0, 1.7, 1.0), m + Vector3(4.2, 0.9, -1.0), m + Vector3(4.0, 0, -0.1), 0.0)
		add_view("platform", m + Vector3(TRAIN_STOP - 2.5, 2.2, 2.6), m + Vector3(TRAIN_STOP + 1.0, 0.4, -0.6),
			m + Vector3(TRAIN_STOP - 1.0, 0.4, 1.0), -0.4)
		add_view("behind_line", m + Vector3(TRAIN_STOP - 1.5, 2.0, 2.6), m + Vector3(TRAIN_STOP + 1.5, 0.8, -1.2),
			m + Vector3(TRAIN_STOP, 0.4, 0.4), -0.3)
		add_view("help_point", m + Vector3(TRAIN_STOP + 2.4, 1.7, -0.4), m + Vector3(TRAIN_STOP + 3.0, 1.3, 1.38),
			m + Vector3(TRAIN_STOP + 2.8, 0.4, 0.6), PI)
		add_view("compass", PARK + Vector3(0, 1.3, 1.2), PARK + Vector3(0, 0.88, 0.7), PARK + Vector3(0, 0, 1.2), 0.0)
		add_view("flags", PARK + Vector3(-1.6, 1.9, 4.2), PARK + Vector3(3.2, 1.2, -2.0), PARK + Vector3(0, 0, 1.2), 0.0)
		add_view("flag_east", PARK + Vector3(5.0, 1.6, 3.0), PARK + Vector3(7.0, 1.2, 1.2), PARK + Vector3(6.4, 0, 1.6), -PI / 2)
		add_view("flag_ne", PARK + Vector3(3.5, 1.6, -1.6), PARK + Vector3(5.0, 1.2, -3.8), PARK + Vector3(4.5, 0, -3.2), -0.8)
		add_view("park_map", PARK + Vector3(-2.2, 1.45, 1.0), PARK + Vector3(-2.4, 1.4, -0.4), PARK + Vector3(-2.4, 0, 0.4), 0.0)


# --- Events -----------------------------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"gus_gone":
			if gus:
				gus.visible = false
		"gus_back":
			if gus:
				gus.visible = true
				gus.position = CHILD + Vector3(-0.9, 0, 0.6)
				LifeRoomPeople.feel(gus, "happy")
		"come_with":
			if stranger_words:
				stranger_words.visible = true
		"drill_bell":
			if is_inside_tree():
				Audio.play(&"chime", Vector3.INF, -12.0)   # a calm bell: practice
		"gate_open":
			if gate_flap:
				gate_flap.visible = false
		"train_coming":
			train_moving = true
			if train:
				train.position.x = METRO.x + TRAIN_FROM
				train.visible = true
		"group_gone":
			for b in group:
				b.visible = false


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"ask", "come_with":
			if stranger_words:
				stranger_words.visible = false
		"platform":
			if train:   # the train is in and stops
				train_moving = false
				train.position.x = METRO.x + TRAIN_STOP
				train.visible = true


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find", "sequence":
			var done: Array = state.get("found", []) if step.kind == "find" else (step.targets as Array).slice(0, int(state.get("i", 0)))
			for f: Variant in done:
				var t := str(f)
				if has_target(t) and target_node(t).get_node_or_null("Found") == null:
					var above := 0.62 if t in ["worker", "parent_kids", "police"] else 0.1   # over a head, or a map's symbol
					var dot := LifeRoomKit.sphere(target_node(t), "Found", 0.04, Vector3(0, above, 0), Color(0.3, 0.85, 0.4, 0.9))
					dot.name = "Found"


func _process(delta: float) -> void:
	super(delta)
	var d := sim_delta(delta)   # the room's own time: slow on a danger moment's first tries, still while frozen
	_t += d
	if train_moving and train:
		train.position.x = maxf(train.position.x - TRAIN_SPEED * d, METRO.x + TRAIN_STOP)
		if train.position.x <= METRO.x + TRAIN_STOP + 0.01:
			train_moving = false


# --- The safe mistakes' gentle pictures -------------------------------------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if not on:
		return
	var holder := mistake_holder()
	match event:
		"walk_off":   # a see-through figure a few steps off towards the way out; the man still where he stood
			var ghost := LifeBuddy.new(GHOST, "WalkingOff")
			ghost.position = CHILD + Vector3(-1.7, 0, 0.5)
			ghost.rotation.y = -PI / 2
			holder.add_child(ghost)
			for i in 4:
				LifeRoomKit.cylinder(holder, "Step", 0.06, 0.01, CHILD + Vector3(-0.3 - i * 0.35, 0.02, 0.1 + i * 0.1),
					Color(0.6, 0.62, 0.68, 0.7))
			LifeRoomKit.sign(holder, "Why", "WALKING AWAY MAKES YOU HARDER TO FIND", CHILD + Vector3(-1.2, 2.4, 0.4), 0.0045, WARM)
		"edge_wind":   # the train frozen coming in, soft wind arrows along the edge, a see-through figure at it
			var edge := METRO + Vector3(TRAIN_STOP + 1.6, 0.4, -1.05)
			var ghost := LifeBuddy.new(GHOST, "AtTheEdge")
			ghost.position = edge
			ghost.rotation.y = PI
			holder.add_child(ghost)
			for i in 3:
				var arrow := LifeRoomKit.box(holder, "Wind", Vector3(0.9, 0.03, 0.03), edge + Vector3(-0.8 - i * 0.3, 0.6 + i * 0.35, -0.3),
					Color(1, 1, 1, 0.55))
				arrow.rotation.z = 0.15
			LifeRoomKit.sign(holder, "Why", "TRAINS COME IN FAST AND CLOSE", edge + Vector3(-0.6, 2.3, 0), 0.0045, WARM)


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The market as a sunny town square; the school's windows, shelf, clock, rug and side wall, its playground's fence and
## trees; the metro's tiled hall with a ceiling and its light strips, benches and rails along the track; the park's
## paths, benches and flowers; one grassy land under every place and a soft sky. The train and the compass one mesh
## each, every person one body (they keep their pose), a head that still nods and changes its face.
func _places_look() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Land", Vector3(150, 0.1, 140), Vector3(0, -0.2, 10), Color("86c063"), 0.0, LifeRoomDecor.SHELL)
	if track != "big":
		var s := SCHOOL
		d.box("SchoolSide", Vector3(0.1, 2.8, 6.0), s + Vector3(4.0, 1.4, 0), Color("f0e8d8"), 0.0, LifeRoomDecor.SHELL)
		d.skirting("Skirting", s + Vector3(-4.0, 0, -2.94), s + Vector3(4.0, 0, -2.94), Color("c89a62"))
		d.window("SchoolWindow", s + Vector3(3.94, 1.6, -0.6), 1.4, 1.0, -PI / 2)
		d.window("SchoolWindow", s + Vector3(-2.6, 1.7, -2.94), 0.9, 0.8, 0.0)
		d.shelf("SchoolShelf", s + Vector3(3.2, 0, -2.75), 1.0, 1.2)
		d.box("Clock", Vector3(0.3, 0.3, 0.04), s + Vector3(-0.6, 2.25, -2.93), Color("fdfdf8"))
		d.rug("SchoolRug", s + Vector3(2.6, 0.0, 1.6), Vector2(1.4, 1.0), Color("f6e7a8"), Color("3a7be8"))
		d.fence("PlayFence", s + Vector3(-14.0, 0, -7.2), s + Vector3(-4.2, 0, -7.2), Color("fdfaf2"), 0.8)
		for t: Vector3 in [Vector3(-13.0, 0, -5.8), Vector3(-12.6, 0, 0.4)]:
			d.tree("PlayTree", s + t, 1.2)
	if track != "little":
		var m := METRO
		d.skirting("HallSkirting", m + Vector3(-4.0, 0, -3.04), m + Vector3(16.0, 0, -3.04), Color("9aa7b5"))
		d.box("HallCeiling", Vector3(18.4, 0.1, 9.0), m + Vector3(5.8, 3.05, -0.5), Color("e8ecf0"), 0.0, LifeRoomDecor.SHELL)
		for x: float in [-1.0, 4.0, 9.0, 13.0]:
			d.glow_box("LightStrip", Vector3(2.4, 0.04, 0.2), m + Vector3(x, 2.99, 0.2), Color("fff6dc"))
		d.box("HallEnd", Vector3(0.1, 3.0, 8.0), m + Vector3(-3.4, 1.5, -0.5), Color("eef1f4"), 0.0, LifeRoomDecor.SHELL)
		# the far end: the tunnel's mouth over the track, where the train comes in
		d.box("HallEnd", Vector3(0.1, 3.0, 4.6), m + Vector3(15.0, 1.5, 1.2), Color("eef1f4"), 0.0, LifeRoomDecor.SHELL)
		d.box("HallEnd", Vector3(0.1, 3.0, 1.6), m + Vector3(15.0, 1.5, -3.7), Color("eef1f4"), 0.0, LifeRoomDecor.SHELL)
		d.box("TunnelTop", Vector3(0.1, 0.75, 2.0), m + Vector3(15.0, 2.62, -2.0), Color("eef1f4"), 0.0, LifeRoomDecor.SHELL)
		d.box("TunnelDark", Vector3(0.6, 2.65, 1.9), m + Vector3(15.6, 0.925, -2.0), Color("2a2f3a"), 0.0, LifeRoomDecor.SHELL)
		d.bench("PlatformBench", m + Vector3(TRAIN_STOP + 5.5, 0.4, 1.3), PI, 1.4, Color("3a7be8"))
		for z: float in [-2.45, -1.55]:
			d.box("Rail", Vector3(40, 0.06, 0.08), m + Vector3(TRAIN_STOP + 8, -0.34, z), Color("9aa7b5"))
		var p := PARK
		d.tiled("ParkPath", LifeRoomDecor.SAND, Vector3(1.4, 0.02, 10.0), p + Vector3(-1.2, 0.002, -4.0), Color("f2e6cc"), 0.7)
		d.bench("ParkBench", p + Vector3(-5.5, 0, 0.8), PI / 2)
		for t: Vector3 in [Vector3(9.0, 0, -9.0), Vector3(-11.0, 0, -12.0), Vector3(10.5, 0, 4.0)]:
			d.tree("ParkTree", p + t, 1.3)
		d.bush("ParkFlowers", p + Vector3(-5.0, 0, -2.6), 0.9, Color("5aa548"), Color("e85a9a"))
	for place: Node3D in [train, get_node_or_null("Compass") as Node3D]:
		if place != null:
			LifeRoomPeople.merge_parts(self, place)
	for n: Node in find_children("*", "Node3D", true, false):
		if n is LifeBuddy:
			LifeRoomPeople.merge_person(n as LifeBuddy, true)
