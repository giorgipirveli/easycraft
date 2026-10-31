class_name RealBuilderSite
extends LifeRoom
## Owner #116, #117 (docs/superpowers/plans/2026-10-16-vr-round4.md "Round 4b"): Real Builder's practice building site,
## true to scale, on Life L1's room framework (LifeRoom: targets, views with VR spots, the glow, events). Little: a
## little wall of big concrete blocks on a footing; Middle: a garden shed on a slab; Big: a small house with a door, a
## window and a roof. Every wall is a BrickBond plan; the child lays their own pieces (a course at a time, snapped to
## their places: never free physics), the team lays the rest in the same bond as the run goes on (time-lapses).
## - **The engine opts in by the room:** a target with a work frame (work_frame: x along the work, y out of its surface)
##   is used with a real motion (ToolRoomHost feeds ToolMotion there); one without is pressed as in any Life room.
## - **Laying:** a course's pieces glow one at a time (a see-through brick, never on the Expert try's `glow: false`).
##   Flat: a tap lays the free piece nearest the finger (aim_point, from the host). VR: take a brick from the pallet (a
##   VrGrabbable), carry it near its place (its ghost shows), let go: it is laid there (`placed`); elsewhere it goes back.
## - **Events:** the high block and its tap down, the coach's test wall and its split, the team's courses and the
##   time-lapses' rise, lintels, the scaffold, rafters, tiles, the mixer's drum and mix, goggles off, a gentle sawdust
##   puff (owner #118's safe mistake, shown away from any face), the finish.
## Distances are metres; the yard's floor is y = 0; the child starts looking along -Z.

signal placed(target: String)

const BRICK_RED := Color("b5543c")
const BRICK_DARK := Color("9c4632")
const BLOCK_GREY := Color("b9bcc0")
const BLOCK_DARK := Color("a6aaaf")
const MORTAR := Color("d8d2c4")
const CONCRETE := Color("9aa0a6")
const TIMBER := Color("c79a5b")
const TILE := Color("b8562f")
const GROUND := Color("bfae8c")
const GHOST := Color(1.0, 0.86, 0.3, 0.35)
const GOOD := Color(0.35, 0.9, 0.45, 0.28)
const DUST := Color(0.92, 0.86, 0.72, 0.6)
## A brick in the hand snaps to a free place within this (m).
const SNAP := 0.15
## The high piece sits this much proud of the line until it is tapped down (m).
const HIGH := 0.018
const PITCH := deg_to_rad(35.0)

## The build: BrickBond's plan.
var plan := {}
## The coach's test wall (Little, Middle): no stagger.
var test_bricks: Array[Dictionary] = []
## Placement target -> the child's piece ids, in the order they glow.
var mine := {}
## Piece id -> laid.
var laid := {}
## The team's pieces show up to this course (-1: none).
var team_upto := -1
## Each lintel's id -> laid.
var lintels_laid := {}
var rafters_laid := 0
var tiles_laid := 0
var rafter_count := 0
var tile_rows := 0
## The step now (its glow, its placements).
var step := {}
## The flat finger's point on the work (global), for the nearest piece; INF none.
var aim_point := Vector3.INF
var split := false
var drum_turning := false

var _origin := Vector3.ZERO
var _pieces := {}   # id -> piece
var _frames := {}   # target -> Transform3D (local)
var _bricks_a: BoxBatch
var _bricks_b: BoxBatch
var _mortar: BoxBatch
var _test_a: BoxBatch
var _test_mortar: BoxBatch
var _lintels: BoxBatch
var _rafters: BoxBatch
var _tiles: BoxBatch
var _ghost: MeshInstance3D
var _high := ""
var _high_up := false
var _rise_from := -1
var _rise_to := -1
var _dirty := true
var _hand: Node3D
var _hand_grab: VrGrabbable
var _hand_home := Transform3D.IDENTITY
var _gear := {}   # gear id -> its model
var _props := {}   # tool id -> ToolProp
var _test_wall: Node3D
var _scaffold: Node3D
var _roof_frame: Node3D
var _drum: Node3D
var _mix: MeshInstance3D
var _reading: Label3D
var _hop_ups: Node3D
var _goggles_hook := Vector3.ZERO
var _lintel_targets := {}   # target -> lintel id


func _init(room_track: String = "little") -> void:
	super(room_track)
	name = "RealBuilderSite"


func _ready() -> void:
	env = LifeRoomKit.environment(Color("9fd0f2"), Color("eef6fb"), 0.6)
	super()


func build() -> void:
	_common()
	match track:
		"middle":
			_shed()
		"big":
			_house()
		_:
			_little_wall()
	_batches()
	_ghost = LifeRoomKit.box(self, "PlaceGhost", Vector3.ONE, Vector3.ZERO, GHOST)
	_ghost.material_override = LifeRoomKit.material(GHOST, true)
	_ghost.visible = false
	_reading = LifeRoomKit.sign(self, "Reading", "", Vector3.ZERO, 0.0035, Color("fff4c2"))
	_reading.visible = false
	_rebuild()


# --- The yard, the bench, the pallet ------------------------------------------------------------------------------

func _common() -> void:
	LifeRoomKit.box(self, "Ground", Vector3(18, 0.1, 16), Vector3(0, -0.05, -2.5), GROUND)
	LifeRoomKit.box(self, "Hoarding", Vector3(18, 1.8, 0.05), Vector3(0, 0.9, -7.5), Color("4f6d8f"))
	LifeRoomKit.sign(self, "SiteSign", "PRACTICE BUILDING SITE", Vector3(0, 2.3, -7.4), 0.006, Color("ffe08a"))
	LifeRoomKit.light(self, Vector3(-2, 3.5, 2), 0.9, 10.0)
	LifeRoomKit.light(self, Vector3(2.5, 3.5, -1), 0.7, 10.0)


## The bench at `at` (its middle on the floor), the tools and gear of the track on it.
func _bench(at: Vector3, tools: Array[String], gear: Array[String]) -> void:
	var b := Node3D.new()
	b.name = "Bench"
	b.position = at
	add_child(b)
	LifeRoomKit.box(b, "Top", Vector3(0.5, 0.04, 1.1), Vector3(0, 0.7, 0), TIMBER)
	for x: float in [-0.21, 0.21]:
		for z: float in [-0.5, 0.5]:
			LifeRoomKit.box(b, "Leg", Vector3(0.04, 0.68, 0.04), Vector3(x, 0.34, z), TIMBER.darkened(0.2))
	var z := -0.42
	for g in gear:
		var built := ToolModels.build(g)
		var m: Node3D = built.model
		m.name = "Gear_" + g
		m.position = at + Vector3(-0.08, 0.76, z)
		add_child(m)
		_gear[g] = m
		add_spot_target(g, self, m.position + Vector3(0, 0.04, 0), 0.12)
		z += 0.28
	z = -0.42
	for t in tools:
		var p := ToolProp.new(t)
		p.position = at + Vector3(0.12, 0.79, z)
		p.rotation.y = PI   # the handles towards the child
		add_child(p)
		_props[t] = p
		add_target("tool_" + t, p, 0.12)   # it glows when the job wants it (VR)
		z += 0.2


## The pallet of bricks (or blocks) at `at`, with the one to take in VR on top.
func _pallet(at: Vector3, piece_size: Vector3, colour: Color) -> void:
	var p := Node3D.new()
	p.name = "Pallet"
	p.position = at
	add_child(p)
	LifeRoomKit.box(p, "Boards", Vector3(0.8, 0.12, 0.8), Vector3(0, 0.06, 0), TIMBER.darkened(0.15))
	LifeRoomKit.box(p, "Stack", Vector3(0.66, 0.48, 0.66), Vector3(0, 0.36, 0), colour)
	LifeRoomKit.sign(p, "Label", "BRICKS" if piece_size.x < 0.3 else "BLOCKS", Vector3(0, 0.95, 0), 0.0035)
	_hand = Node3D.new()
	_hand.name = "HandPiece"
	_hand.position = at + Vector3(0, 0.6 + piece_size.y * 0.5, 0)
	add_child(_hand)
	_hand_home = _hand.transform
	LifeRoomKit.box(_hand, "Piece", piece_size, Vector3.ZERO, colour)
	_hand_grab = VrGrabbable.new()
	_hand_grab.name = "VrGrabbable"
	_hand_grab.kind = &"hold"
	_hand_grab.throwable = false
	_hand_grab.radius = 0.12
	_hand.add_child(_hand_grab)
	_hand_grab.released.connect(func(_side: StringName, _v: Vector3) -> void: _let_go_piece())


func _plinth(name_: String, size: Vector3, at: Vector3) -> void:
	LifeRoomKit.box(self, name_, size, at, CONCRETE)


func _batches() -> void:
	var dark := BLOCK_DARK if str(plan.get("kind", "")) == "block" else BRICK_DARK
	var light := BLOCK_GREY if str(plan.get("kind", "")) == "block" else BRICK_RED
	_bricks_a = BoxBatch.new("BricksA", light)
	_bricks_b = BoxBatch.new("BricksB", dark)
	_mortar = BoxBatch.new("Mortar", MORTAR)
	_lintels = BoxBatch.new("Lintels", CONCRETE.lightened(0.15))
	for b: BoxBatch in [_bricks_a, _bricks_b, _mortar, _lintels]:
		add_child(b)
	if not test_bricks.is_empty():
		_test_a = BoxBatch.new("TestBricks", light)
		_test_mortar = BoxBatch.new("TestMortar", MORTAR)
		_test_wall.add_child(_test_a)
		_test_wall.add_child(_test_mortar)


# --- Little: a little wall of big blocks --------------------------------------------------------------------------

func _little_wall() -> void:
	_origin = Vector3(-0.67, 0.35, 0.0)
	_plinth("Footing", Vector3(1.6, 0.35, 0.32), Vector3(0, 0.175, -0.05))
	plan = BrickBond.plan({"kind": "block", "shape": "wall", "length": 3, "courses": 3, "origin": _origin})
	_index_pieces()
	for c in 3:
		mine["course_%d" % (c + 1)] = _ids(func(p: Dictionary) -> bool: return int(p.course) == c)
	_high = str(mine.course_1[1])
	_bench(Vector3(-1.45, 0, 0.75), ["trowel", "spirit_level"], ["hard_hat", "gloves"])
	_pallet(Vector3(1.35, 0, 0.75), BrickBond.unit("block").size, BLOCK_GREY)
	LifeRoomKit.box(self, "MortarBoard", Vector3(0.5, 0.03, 0.5), Vector3(0.75, 0.5, 0.55), TIMBER)
	LifeRoomKit.sphere(self, "MortarHeap", 0.14, Vector3(0.75, 0.55, 0.55), MORTAR)
	_test_wall = Node3D.new()
	_test_wall.name = "TestWall"
	_test_wall.visible = false
	add_child(_test_wall)
	var test_origin := Vector3(-2.05, 0.35, 0.0)
	LifeRoomKit.box(_test_wall, "TestFooting", Vector3(1.1, 0.35, 0.32), Vector3(-1.605, 0.175, -0.05), CONCRETE)
	test_bricks = BrickBond.stacked_wall("block", 2, 3, test_origin)
	_wall_targets(1.34, 0.225, 3)
	add_spot_target("push_test_wall", self, Vector3(-1.605, 0.69, 0.0), 0.3, 0.45)
	add_spot_target("push_my_wall", self, Vector3(0, 0.69, 0.0), 0.3, 0.67)
	_frames.push_test_wall = _face_frame(Vector3(-1.605, 0.69, 0.0))
	_frames.push_my_wall = _face_frame(Vector3(0, 0.69, 0.0))
	add_view("site", Vector3(0.4, 1.9, 3.3), Vector3(-0.2, 0.6, -0.2), Vector3(0, 0, 0.6), 0.0)
	add_view("bench", Vector3(-0.5, 1.45, 2.0), Vector3(-1.45, 0.75, 0.75), Vector3(-0.85, 0, 0.75), PI / 2.0)
	add_view("wall", Vector3(0, 1.2, 1.55), Vector3(0, 0.55, 0), Vector3(0, 0, 0.5), 0.0)
	add_view("test", Vector3(-0.8, 1.3, 2.0), Vector3(-0.8, 0.6, 0), Vector3(-0.8, 0, 0.55), 0.0)
	add_view("done", Vector3(1.4, 1.5, 2.6), Vector3(-0.2, 0.6, 0), Vector3(0.5, 0, 0.9), 0.0)
	start_view = "site"


# --- Middle: a garden shed ------------------------------------------------------------------------------------------

func _shed() -> void:
	_origin = Vector3(-0.895, 0.3, 0.0)
	_plinth("Slab", Vector3(2.3, 0.3, 1.9), Vector3(0, 0.15, -0.62))
	plan = BrickBond.plan({"kind": "brick", "shape": "box", "length": 8, "depth": 6, "courses": 24, "origin": _origin,
		"openings": [{"run": "front", "from": 3, "width": 3, "sill": 0, "height": 22}]})
	_index_pieces()
	for c in 2:
		mine["course_%d" % (c + 1)] = _ids(func(p: Dictionary) -> bool: return str(p.run) == "front" and int(p.course) == c)
	_high = str(mine.course_1[1])
	team_upto = 0
	_bench(Vector3(-1.7, 0, 0.75), ["trowel", "spirit_level", "tape", "plumb_line", "saw", "hammer"],
		["hard_hat", "gloves", "goggles"])
	_pallet(Vector3(1.55, 0, 0.75), BrickBond.unit("brick").size, BRICK_RED)
	_test_wall = Node3D.new()
	_test_wall.name = "TestWall"
	_test_wall.visible = false
	add_child(_test_wall)
	var test_origin := Vector3(-2.25, 0.3, 0.0)
	LifeRoomKit.box(_test_wall, "TestPlinth", Vector3(1.05, 0.3, 0.3), Vector3(-1.805, 0.15, -0.05), CONCRETE)
	test_bricks = BrickBond.stacked_wall("brick", 4, 5, test_origin)
	add_spot_target("push_test_wall", self, Vector3(-1.805, 0.5, 0.0), 0.25, 0.45)
	add_spot_target("push_my_wall", self, Vector3(-0.6, 0.38, 0.0), 0.2, 0.3)
	_frames.push_test_wall = _face_frame(Vector3(-1.805, 0.5, 0.0))
	_frames.push_my_wall = _face_frame(Vector3(-0.6, 0.38, 0.0))
	_wall_targets(1.79, 0.075, 2)
	_measure_targets(1.79)
	_building_extras(1.79, 24, ["lintel_front_22"], {"lintel_front_22": "lintel_door"})
	_mixer(Vector3(1.95, 0, -0.45))
	_saw_station(Vector3(-2.05, 0, -1.1))
	_roof(1.79, 1.34, 24, 3, 4)
	add_view("site", Vector3(1.6, 2.4, 4.0), Vector3(-0.1, 1.0, -0.6), Vector3(0, 0, 0.9), 0.0)
	add_view("bench", Vector3(-0.8, 1.45, 2.0), Vector3(-1.7, 0.75, 0.75), Vector3(-1.1, 0, 0.75), PI / 2.0)
	add_view("tape", Vector3(0, 1.3, 1.6), Vector3(0, 0.3, 0), Vector3(-0.5, 0, 0.45), 0.0)
	add_view("tape_end", Vector3(0, 1.3, 1.6), Vector3(0, 0.3, 0), Vector3(0.65, 0, 0.45), 0.0)
	add_view("mixer", Vector3(1.4, 1.4, 1.1), Vector3(1.95, 0.6, -0.45), Vector3(1.75, 0, 0.3), 0.0)
	add_view("wall", Vector3(0, 1.1, 1.35), Vector3(0, 0.35, 0), Vector3(-0.3, 0, 0.45), 0.0)
	add_view("test", Vector3(-1.1, 1.3, 1.9), Vector3(-1.2, 0.45, 0), Vector3(-1.2, 0, 0.5), 0.0)
	add_view("corner", Vector3(-0.3, 1.9, 1.7), Vector3(-0.85, 1.5, 0), Vector3(-0.65, 0.3, 0.45), 0.0)
	add_view("door", Vector3(0.1, 1.9, 1.9), Vector3(0.1, 1.6, 0), Vector3(0.1, 0.3, 0.5), 0.0)
	add_view("saw", Vector3(-1.75, 1.3, -0.35), Vector3(-2.05, 0.62, -1.1), Vector3(-2.05, 0, -0.6), 0.0)
	add_view("scaffold", Vector3(0.4, 2.9, 1.6), Vector3(0, 2.25, -0.6), Vector3(0, 0.95, 0.5), 0.0)
	add_view("done", Vector3(2.4, 2.2, 3.4), Vector3(0, 1.2, -0.6), Vector3(1.4, 0, 1.4), -0.5)
	start_view = "site"
	_make_hop_ups()


# --- Big: a small house -----------------------------------------------------------------------------------------------

func _house() -> void:
	_origin = Vector3(-1.57, 0.3, 0.0)
	_plinth("Slab", Vector3(3.8, 0.3, 2.9), Vector3(0, 0.15, -1.07))
	plan = BrickBond.plan({"kind": "brick", "shape": "box", "length": 14, "depth": 10, "courses": 28, "origin": _origin,
		"openings": [{"run": "front", "from": 2, "width": 4, "sill": 0, "height": 26},
			{"run": "front", "from": 8, "width": 4, "sill": 12, "height": 12}]})
	_index_pieces()
	for c in 3:
		mine["course_%d" % (c + 1)] = _ids(func(p: Dictionary) -> bool:
			return str(p.run) == "front" and int(p.course) == c and float(p.u1) <= 0.44 + 0.001)
	team_upto = 0
	_bench(Vector3(-2.45, 0, 0.75), ["trowel", "spirit_level", "tape", "plumb_line", "saw", "hammer"],
		["hard_hat", "gloves", "goggles"])
	_pallet(Vector3(2.4, 0, 0.8), BrickBond.unit("brick").size, BRICK_RED)
	_wall_targets(0.44, 0.075, 3)
	_measure_targets(3.14)
	var sq_from := _origin + Vector3(0.6, 0.02, 0.0)
	var sq_to := _origin + Vector3(0.0, 0.02, -0.8)
	LifeRoomKit.box(self, "PegA", Vector3(0.03, 0.12, 0.03), sq_from + Vector3(0, 0.04, 0), Color("e8d8b0"))
	LifeRoomKit.box(self, "PegB", Vector3(0.03, 0.12, 0.03), sq_to + Vector3(0, 0.04, 0), Color("e8d8b0"))
	add_spot_target("square_diag", self, (sq_from + sq_to) * 0.5, 0.2, 0.5)
	_frames.square_diag = ToolSample.work_frame(sq_from, sq_to - sq_from, Vector3.UP)
	_building_extras(3.14, 28, ["lintel_front_24", "lintel_front_26"],
		{"lintel_front_24": "lintel_window", "lintel_front_26": "lintel_door"})
	var window: Dictionary = (plan.openings as Array)[1]
	var wl: Dictionary = _lintel_piece("lintel_front_24")
	var reveal := Vector3(_origin.x + float(window.u_a), _origin.y + int(window.c1) * 0.075 + 0.005, _origin.z + 0.03)
	add_spot_target("bearing", self, reveal + Vector3(-0.1, 0, 0), 0.15, 0.15)
	_frames.bearing = ToolSample.work_frame(reveal, Vector3.LEFT, Vector3.BACK)
	if not wl.is_empty():
		LifeRoomKit.box(self, "BearingMark", Vector3(0.006, 0.08, 0.006), reveal, Color("2f6bd9"))
	add_spot_target("inside", self, _front_point(0.895, 12) + Vector3(0, 0, 0.05), 0.35, 0.4)
	_mixer(Vector3(2.55, 0, -0.5))
	_saw_station(Vector3(-2.75, 0, -1.2))
	_roof(3.14, 2.24, 28, 4, 5)
	add_view("site", Vector3(2.3, 3.0, 5.2), Vector3(0, 1.3, -1.0), Vector3(0, 0, 1.0), 0.0)
	add_view("bench", Vector3(-1.5, 1.45, 2.0), Vector3(-2.45, 0.75, 0.75), Vector3(-1.85, 0, 0.75), PI / 2.0)
	add_view("tape", Vector3(-0.6, 1.4, 1.9), Vector3(-0.3, 0.3, 0), Vector3(-1.2, 0, 0.45), 0.0)
	add_view("tape_end", Vector3(0.6, 1.4, 1.9), Vector3(0.6, 0.3, 0), Vector3(1.2, 0, 0.45), 0.0)
	add_view("square", Vector3(-0.6, 1.5, 1.2), Vector3(-1.25, 0.3, -0.35), Vector3(-1.1, 0.3, -0.1), PI / 4.0)
	add_view("mixer", Vector3(2.0, 1.4, 1.1), Vector3(2.55, 0.6, -0.5), Vector3(2.35, 0, 0.3), 0.0)
	add_view("pier", Vector3(-1.3, 1.0, 1.25), Vector3(-1.35, 0.4, 0), Vector3(-1.35, 0, 0.45), 0.0)
	add_view("corner", Vector3(-0.8, 2.4, 1.8), Vector3(-1.45, 1.9, 0), Vector3(-1.3, 0.45, 0.45), 0.0)
	add_view("window", Vector3(0.67, 2.3, 2.0), Vector3(0.67, 1.8, 0), Vector3(0.67, 0.45, 0.45), 0.0)
	add_view("door", Vector3(-0.67, 2.2, 2.2), Vector3(-0.67, 1.6, 0), Vector3(-0.67, 0.45, 0.45), 0.0)
	add_view("saw", Vector3(-2.45, 1.3, -0.45), Vector3(-2.75, 0.62, -1.2), Vector3(-2.75, 0, -0.7), 0.0)
	add_view("scaffold", Vector3(0.5, 3.3, 1.9), Vector3(0, 2.7, -0.9), Vector3(0, 1.25, 0.5), 0.0)
	add_view("inside", Vector3(-0.9, 1.5, -1.8), Vector3(0.67, 1.3, 0), Vector3(-0.6, 0.3, -1.3), PI)
	add_view("done", Vector3(3.2, 2.6, 4.4), Vector3(0, 1.4, -1.0), Vector3(2.0, 0, 1.8), -0.5)
	start_view = "site"
	_make_hop_ups()


# --- Shared parts of a build ----------------------------------------------------------------------------------------

func _index_pieces() -> void:
	for p: Dictionary in plan.bricks:
		_pieces[str(p.id)] = p
	for l: Dictionary in plan.lintels:
		_pieces[str(l.id)] = l


func _ids(keep: Callable) -> Array[String]:
	var out: Array[String] = []
	for p: Dictionary in plan.bricks:
		if keep.call(p):
			out.append(str(p.id))
	return out


## The child's beds, courses and level checks on the front run (or the wall): `length` of it from its start.
func _wall_targets(length: float, course_h: float, courses: int) -> void:
	var run_id := "wall" if plan.runs.has("wall") else "front"
	var run: Dictionary = plan.runs[run_id]
	var dir: Vector3 = run.dir
	var from: Vector3 = run.from
	var top_y := float(_origin.y)
	for c in courses:
		var bed_y := top_y + c * course_h
		var bed_from := from + Vector3(0, bed_y - from.y, 0)
		add_spot_target("bed_%d" % (c + 1), self, bed_from + dir * length * 0.5 + Vector3(0, 0.01, 0), maxf(length * 0.5, 0.2),
			length * 0.5)
		_frames["bed_%d" % (c + 1)] = ToolSample.work_frame(bed_from, dir, Vector3.UP)
		var centre := bed_from + dir * length * 0.5 + Vector3(0, course_h * 0.5, 0)
		add_spot_target("course_%d" % (c + 1), self, centre, maxf(length * 0.5, 0.2), length * 0.5)
		var top := bed_from + dir * length * 0.5 + Vector3(0, course_h, 0)
		add_spot_target("level_%d" % (c + 1), self, top + Vector3(0, 0.02, 0), maxf(length * 0.4, 0.15), length * 0.4)
		_frames["level_%d" % (c + 1)] = ToolSample.work_frame(top, dir, Vector3.UP)
	var high: Dictionary = _pieces.get(_high, {})
	if not high.is_empty():
		var at: Vector3 = (high.centre as Vector3) + Vector3(0, (high.size as Vector3).y * 0.5 + HIGH, 0)
		var target := "block_high" if str(plan.kind) == "block" else "brick_high"
		add_spot_target(target, self, at, 0.1)
		_frames[target] = ToolSample.work_frame(at, dir, Vector3.UP)


## The tape's line along the front, from the left corner peg (its hook) to the right one.
func _measure_targets(length: float) -> void:
	var from := _origin + Vector3(0, 0.02, 0.06)
	LifeRoomKit.box(self, "ChalkLine", Vector3(length, 0.004, 0.01), from + Vector3(length * 0.5, -0.016, -0.06), Color.WHITE)
	for x: float in [0.0, length]:
		LifeRoomKit.box(self, "Peg", Vector3(0.03, 0.12, 0.03), from + Vector3(x, 0.04, 0), Color("e8d8b0"))
	add_spot_target("tape_front", self, from + Vector3(length * 0.5, 0, 0), maxf(length * 0.5, 0.3), length * 0.5)
	_frames.tape_front = ToolSample.work_frame(from, Vector3.RIGHT, Vector3.UP)


## The corner's plumb line, the lintels' places, the hop-ups, the scaffold.
func _building_extras(width: float, courses: int, lintel_ids: Array[String], targets: Dictionary) -> void:
	var top := _origin.y + courses * 0.075
	var corner_top := Vector3(_origin.x + 0.05, _origin.y + (courses - 4) * 0.075, _origin.z)
	add_spot_target("plumb_corner", self, corner_top + Vector3(0, 0, 0.04), 0.15)
	_frames.plumb_corner = ToolSample.work_frame(corner_top, Vector3.DOWN, Vector3.BACK)
	for id in lintel_ids:
		var l := _lintel_piece(id)
		if l.is_empty():
			continue
		add_spot_target(str(targets[id]), self, (l.centre as Vector3) + Vector3(0, 0, 0.06), 0.25, (l.size as Vector3).x * 0.5)
		_lintel_targets[str(targets[id])] = id
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	_scaffold.visible = false
	add_child(_scaffold)
	var deck_y := top - 1.15
	LifeRoomKit.box(_scaffold, "Deck", Vector3(width + 0.6, 0.05, 0.7), Vector3(0, deck_y - 0.025, 0.5), TIMBER)
	LifeRoomKit.box(_scaffold, "Rail", Vector3(width + 0.6, 0.04, 0.04), Vector3(0, deck_y + 0.95, 0.85), Color("e0e4ea"))
	for x: float in [-(width * 0.5 + 0.28), width * 0.5 + 0.28]:
		for z: float in [0.17, 0.83]:
			LifeRoomKit.box(_scaffold, "Pole", Vector3(0.05, deck_y + 1.0, 0.05), Vector3(x, (deck_y + 1.0) * 0.5, z),
				Color("c9ced6"))


## A builder's hop-up (a low, wide platform) under each raised spot by the wall: the corner, the door, the window.
func _make_hop_ups() -> void:
	_hop_ups = Node3D.new()
	_hop_ups.name = "HopUps"
	_hop_ups.visible = false
	add_child(_hop_ups)
	for v: String in ["corner", "door", "window"]:
		if not views.has(v):
			continue
		var feet: Vector3 = views[v].feet
		if feet.y > 0.05:
			LifeRoomKit.box(_hop_ups, "HopUp", Vector3(0.6, feet.y, 0.45), feet - Vector3(0, feet.y * 0.5, 0), TIMBER.darkened(0.1))


func _lintel_piece(id: String) -> Dictionary:
	for l: Dictionary in plan.lintels:
		if str(l.id) == id:
			return l
	return {}


## A point on the front's outer face (the site's space) at `u` along it, at course `c`'s middle.
func _front_point(u: float, c: int) -> Vector3:
	return Vector3(_origin.x + u, _origin.y + c * 0.075 + 0.0425, _origin.z)


## A wall face's frame for a push: y out of the face towards the child.
func _face_frame(at: Vector3) -> Transform3D:
	return ToolSample.work_frame(at, Vector3.RIGHT, Vector3.BACK)


func _mixer(at: Vector3) -> void:
	var m := Node3D.new()
	m.name = "Mixer"
	m.position = at
	add_child(m)
	LifeRoomKit.box(m, "Stand", Vector3(0.5, 0.5, 0.4), Vector3(0, 0.25, 0), Color("e05a2a"))
	_drum = Node3D.new()
	_drum.name = "Drum"
	_drum.position = Vector3(0, 0.75, 0)
	_drum.rotation.x = -0.6
	m.add_child(_drum)
	LifeRoomKit.cylinder(_drum, "Shell", 0.26, 0.45, Vector3.ZERO, Color("f08a1c"))
	LifeRoomKit.box(_drum, "Fin", Vector3(0.3, 0.05, 0.05), Vector3(0, 0.1, 0.25), Color("c96f12"))
	_mix = LifeRoomKit.cylinder(_drum, "Mix", 0.2, 0.06, Vector3(0, 0.2, 0), MORTAR.darkened(0.1))
	_mix.visible = false
	add_spot_target("mixer", self, at + Vector3(0, 0.8, 0.1), 0.35)
	var sw := LifeRoomKit.box(m, "Switch", Vector3(0.12, 0.12, 0.06), Vector3(-0.3, 0.55, 0.22), Color("2fae4e"))
	add_target("mixer_switch", sw, 0.1)
	var bucket := LifeRoomKit.cylinder(self, "WaterBucket", 0.12, 0.25, at + Vector3(0.45, 0.125, 0.35), Color("3a7be8"))
	add_target("mixer_water", bucket, 0.15)
	var sand := LifeRoomKit.sphere(self, "SandPile", 0.2, at + Vector3(0.5, 0.08, -0.35), Color("e3c27a"))
	add_target("mixer_sand", sand, 0.2)
	var bag := LifeRoomKit.box(self, "CementBag", Vector3(0.35, 0.15, 0.25), at + Vector3(-0.45, 0.075, 0.3), Color("cfd3d8"))
	LifeRoomKit.sign(bag, "Label", "CEMENT", Vector3(0, 0.15, 0), 0.0025, Color("3b4252"))
	add_target("mixer_cement", bag, 0.18)


func _saw_station(at: Vector3) -> void:
	var s := Node3D.new()
	s.name = "SawStation"
	s.position = at
	add_child(s)
	for z: float in [-0.4, 0.4]:
		LifeRoomKit.box(s, "Trestle", Vector3(0.5, 0.55, 0.06), Vector3(0, 0.275, z), TIMBER.darkened(0.25))
	LifeRoomKit.box(s, "Rafter", Vector3(0.1, 0.05, 1.2), Vector3(0, 0.575, 0), TIMBER)
	LifeRoomKit.box(s, "PencilLine", Vector3(0.1, 0.002, 0.004), Vector3(0, 0.601, 0), Color("3b4252"))
	add_spot_target("rafter_cut", s, Vector3(0, 0.61, 0), 0.12, 0.1)
	_frames.rafter_cut = Transform3D(Basis(), at + Vector3(0, 0.6, 0))
	_goggles_hook = at + Vector3(0.3, 0.6, 0.45)


## The roof: gables, wall plates, rafter pairs and tile rows, shown as the run reaches them.
func _roof(width: float, depth: float, courses: int, rafters: int, rows: int) -> void:
	rafter_count = rafters
	tile_rows = rows
	var top := _origin.y + courses * 0.075
	var half := depth * 0.5
	var rise := half * tan(PITCH)
	_roof_frame = Node3D.new()
	_roof_frame.name = "RoofFrame"
	_roof_frame.visible = false
	add_child(_roof_frame)
	for z: float in [-0.05, -depth + 0.05]:
		LifeRoomKit.box(_roof_frame, "WallPlate", Vector3(width, 0.05, 0.1), Vector3(0, top + 0.025, _origin.z + z), TIMBER)
	for x: float in [_origin.x + 0.05, _origin.x + width - 0.05]:
		var g := MeshInstance3D.new()
		g.name = "Gable"
		g.mesh = _prism(depth, rise, 0.04)
		g.material_override = LifeRoomKit.material(TIMBER.lightened(0.1))
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.position = Vector3(x, top + 0.05, _origin.z - half)
		_roof_frame.add_child(g)
	_rafters = BoxBatch.new("Rafters", TIMBER)
	_tiles = BoxBatch.new("Tiles", TILE)
	add_child(_rafters)
	add_child(_tiles)
	var slope_mid := Vector3(0, top + 0.05 + rise * 0.5, _origin.z - half * 0.5)
	add_spot_target("rafters", self, slope_mid + Vector3(0, 0.1, 0), maxf(width * 0.3, 0.3), width * 0.4)
	add_spot_target("tiles", self, slope_mid + Vector3(0, 0.12, 0), maxf(width * 0.3, 0.3), width * 0.4)
	var foot := Vector3(_rafter_x(rafters / 2), top + 0.1, _origin.z - 0.06)   # the middle pair, in front of the child
	add_spot_target("nail_1", self, foot + Vector3(0, 0.02, 0), 0.08)
	_frames.nail_1 = ToolSample.work_frame(foot + Vector3(0, 0.03, 0), Vector3.RIGHT, Vector3.UP)


func _rafter_x(i: int) -> float:
	var width := float(plan.length)
	return _origin.x + 0.2 + (width - 0.4) * float(i) / maxf(rafter_count - 1, 1)


## A triangle of boards (a gable end): `base` along z, `rise` high, `thick` along x.
static func _prism(base: float, rise: float, thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := base * 0.5
	var t := thick * 0.5
	var a := [Vector3(-t, 0, h), Vector3(-t, 0, -h), Vector3(-t, rise, 0)]
	var b := [Vector3(t, 0, h), Vector3(t, 0, -h), Vector3(t, rise, 0)]
	for tri: Array in [[a[0], a[2], a[1], Vector3.LEFT], [b[0], b[1], b[2], Vector3.RIGHT]]:
		for i in 3:
			st.set_normal(tri[3])
			st.add_vertex(tri[i])
	mesh_quad(st, b[0], a[0], a[2], b[2])
	mesh_quad(st, a[1], b[1], b[2], a[2])
	mesh_quad(st, a[0], b[0], b[1], a[1])
	return st.commit()


static func mesh_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> void:
	var n := (p2 - p0).cross(p1 - p0).normalized()
	for p: Vector3 in [p0, p2, p1, p0, p3, p2]:
		st.set_normal(n)
		st.add_vertex(p)


# --- The engine's frames --------------------------------------------------------------------------------------------

## The target is a work a tool (or a hand) is used on with a real motion (the engine opts in here).
func has_work(target: String) -> bool:
	return _frames.has(target)


## The work's frame (global): x along the work, y out of its surface.
func work_frame(target: String) -> Transform3D:
	return global_transform * (_frames.get(target, Transform3D.IDENTITY) as Transform3D)


## The room runs this device's controls (the engine's device model opts in here): the mixer, where it stands.
func has_device(id: String) -> bool:
	return id == "mixer" and has_target("mixer")


## The tool props on the bench (tool id -> ToolProp).
func props() -> Dictionary:
	return _props


## Where a worn piece of gear goes back (goggles off: on the saw station's hook).
func gear_off(id: String) -> void:
	var m: Node3D = _gear.get(id)
	if m == null:
		return
	m.visible = true
	if id == "goggles" and _goggles_hook != Vector3.ZERO:
		m.position = _goggles_hook
		if has_target(id):
			target_node(id).position = _goggles_hook + Vector3(0, 0.04, 0)


func gear_on(id: String) -> void:
	var m: Node3D = _gear.get(id)
	if m != null:
		m.visible = false


## A reading to show beside the work (the tape's 1.35 m), "" hides it.
func show_reading(text: String, at: Vector3) -> void:
	_reading.text = text
	_reading.visible = text != ""
	if text != "":
		_reading.global_position = at + Vector3(0, 0.12, 0)


## The mixer shows what the device shows (the drum turning, the mix).
func device_shows(displays: Dictionary) -> void:
	if _mix == null:
		return
	drum_turning = str(displays.get("drum", "")) == "turning"
	var mix := str(displays.get("mix", "empty"))
	_mix.visible = mix != "empty"
	var colours := {"wet": Color("8fb3d9"), "sandy": Color("e3c27a"), "grey": Color("9aa0a6"), "mortar": MORTAR.darkened(0.1)}
	if colours.has(mix):
		_mix.material_override = LifeRoomKit.material(colours[mix])


# --- Laying -------------------------------------------------------------------------------------------------------

## A placement target: its pieces are laid, not pressed (courses), or it lays one thing (a lintel), or a count (the
## roof's rafters and tiles).
func is_placement(target: String) -> bool:
	return mine.has(target) or target.begins_with("lintel_") or target == "rafters" or target == "tiles"


## The child's free pieces of a placement target, in glow order.
func free_pieces(target: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in mine.get(target, []):
		if not laid.has(id):
			out.append(_pieces[id])
	return out


func laid_count(target: String) -> int:
	match target:
		"rafters":
			return rafters_laid
		"tiles":
			return tiles_laid
	if target.begins_with("lintel_"):
		return 1 if lintels_laid.has(_lintel_of(target)) else 0
	var n := 0
	for id: String in mine.get(target, []):
		if laid.has(id):
			n += 1
	return n


## Lays a piece of `target` (the free one nearest `near`, else the next); its id ("" when none is left).
func lay(target: String, near: Vector3 = Vector3.INF) -> String:
	match target:
		"rafters":
			if rafters_laid >= rafter_count:
				return ""
			rafters_laid += 1
			_dirty = true
			return "rafter_%d" % rafters_laid
		"tiles":
			if tiles_laid >= tile_rows:
				return ""
			tiles_laid += 1
			_dirty = true
			return "tiles_%d" % tiles_laid
	if target.begins_with("lintel_"):
		var lid := _lintel_of(target)
		if lid == "" or lintels_laid.has(lid):
			return ""
		lintels_laid[lid] = true
		_dirty = true
		return lid
	var free := free_pieces(target)
	if free.is_empty():
		return ""
	var pick: Dictionary = free[0]
	if near.is_finite():
		var local := to_local(near)
		var i := BrickBond.nearest(free, local, INF)
		if i >= 0:
			pick = free[i]
	laid[str(pick.id)] = true
	_dirty = true
	return str(pick.id)


func _lintel_of(target: String) -> String:
	return str(_lintel_targets.get(target, ""))


## Every piece laid by the child and the team now: {id: piece}.
func visible_pieces() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var child := {}
	for t: String in mine:
		for id: String in mine[t]:
			child[id] = true
	for p: Dictionary in plan.get("bricks", []):
		var id := str(p.id)
		if laid.has(id) or (not child.has(id) and int(p.course) <= team_upto):
			out.append(p)
	return out


# --- LifeRoom's hooks -----------------------------------------------------------------------------------------------

func step_started(s: Dictionary) -> void:
	step = s
	aim_point = Vector3.INF
	var t := str(s.get("target", ""))
	_hand.visible = mine.has(t) or t.begins_with("lintel_")
	_hand_grab.enabled = _hand.visible
	_hand_reset()
	_show_targets(s)
	if str(s.get("kind", "")) != "touch" or str(s.get("motion", "")) != "measure":
		show_reading("", Vector3.ZERO)
	if _hop_ups != null and (t.begins_with("lintel_") or str(s.get("view", "")) in ["corner", "door", "window"]):
		_hop_ups.visible = true


## Only the step's own things (and the gear, the device's controls) can be touched or tapped: one thing at a time.
func _show_targets(s: Dictionary) -> void:
	var wanted := {}
	for t in LifeCheck.targets_of(s):
		wanted[t] = true
	if str(s.get("device", "")) != "":
		for t in target_names():
			if t.begins_with(str(s.device) + "_"):
				wanted[t] = true
	for g: String in _gear:
		wanted[g] = true
	for t in target_names():
		var n := target_node(t)
		if n != null and n.name.begins_with("T_"):
			n.visible = wanted.has(t)


func progress(s: Dictionary, state: Dictionary) -> void:
	var t := str(s.get("target", ""))
	match str(s.get("kind", "")):
		"taps":
			while is_placement(t) and laid_count(t) < int(state.get("t", 0)):
				if lay(t, aim_point) == "":
					break
			aim_point = Vector3.INF
		"find":
			for g: Variant in state.get("found", []):
				gear_on(str(g))
		"timelapse":
			if _rise_to >= 0:
				var f := clampf(float(state.get("t", 0.0)) / float(s.get("seconds", 6.0)), 0.0, 1.0)
				var upto := _rise_from + int(round(f * float(_rise_to - _rise_from)))
				if upto != team_upto:
					team_upto = upto
					_dirty = true


func step_done(s: Dictionary) -> void:
	var t := str(s.get("target", ""))
	if t.begins_with("lintel_") and laid_count(t) == 0:
		lay(t)
	if str(s.get("kind", "")) == "taps":
		while is_placement(t) and not free_pieces(t).is_empty() and laid_count(t) < int(s.get("count", 0)):
			lay(t)
	if _rise_to >= 0 and str(s.get("kind", "")) == "timelapse":
		team_upto = _rise_to
		_rise_to = -1
		_dirty = true
	_hand.visible = false
	_ghost.visible = false


func on_event(event: String) -> void:
	match event:
		"high_block", "high_brick":
			_high_up = true
		"block_down", "brick_down":
			_high_up = false
		"test_wall":
			if _test_wall != null:
				_test_wall.visible = true
		"split":
			split = true
		"holds":
			_flash(Vector3(0, 0.69, -0.05) if track == "little" else Vector3(-0.6, 0.38, -0.05))
		"team_course_2":
			team_upto = maxi(team_upto, 1)
		"rise_to_lintel":
			_rise(21)
		"rise_to_window":
			_rise(23)
		"rise_to_door":
			_rise(25)
		"rise_to_top":
			_rise(int(plan.get("courses", 1)) - 1)
			if _roof_frame != null:
				_roof_frame.visible = true
				_scaffold.visible = true
		"goggles_off":
			gear_off("goggles")
		"sawdust":
			_puff(work_frame("rafter_cut").origin)
		"finished":
			LifeRoomKit.sign(self, "WellDone", "WELL BUILT!", Vector3(0, float(plan.get("height", 0.7)) + _origin.y + 0.8, 0.2),
				0.006, Color("ffe08a"))
	_dirty = true


func _rise(to_course: int) -> void:
	_rise_from = maxi(team_upto, 0)
	_rise_to = to_course
	# the child's own pieces are all down by now; the team's courses rise during the time-lapse (progress)
	for t: String in mine:
		for id: String in mine[t]:
			laid[id] = true


## The one next thing glows: a placement's next place as a see-through brick (never with `glow: false`), anything else
## as Life's glow.
func glow(names: Array[String]) -> void:
	var others: Array[String] = []
	_ghost.visible = false
	for n in names:
		if is_placement(n):
			if bool(step.get("glow", true)):
				_ghost_at(n)
		else:
			others.append(n)
	super.glow(others)


func _ghost_at(target: String) -> void:
	var box := {}
	if mine.has(target):
		var free := free_pieces(target)
		if free.is_empty():
			return
		box = free[0]
	elif target.begins_with("lintel_"):
		box = _pieces.get(_lintel_of(target), {})
	elif target in ["rafters", "tiles"]:
		var boxes := _rafter_boxes(rafters_laid + 1) if target == "rafters" else _tile_boxes(tiles_laid + 1)
		if boxes.is_empty():
			return
		box = boxes[-1]
	if box.is_empty():
		return
	_ghost.visible = true
	var basis := Basis(Vector3.UP, float(box.get("yaw", 0.0))) * Basis(Vector3.RIGHT, float(box.get("tilt", 0.0)))
	_ghost.transform = Transform3D(basis * Basis.from_scale(box.size as Vector3 + Vector3.ONE * 0.012), box.centre as Vector3)


# --- Every frame ------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	super(delta)
	if drum_turning and _drum != null:
		_drum.rotate_object_local(Vector3.UP, delta * 2.5)
	if _hand != null and _hand_grab.held_by() != &"":
		var t := str(step.get("target", ""))
		var i := _snap(t, _hand.global_position)
		if i != "":
			var p: Dictionary = _pieces[i]
			_ghost.visible = true
			_ghost.transform = Transform3D(Basis(Vector3.UP, float(p.yaw)) * Basis.from_scale((p.size as Vector3) \
				+ Vector3.ONE * 0.012), p.centre as Vector3)
		elif not bool(step.get("glow", true)):
			_ghost.visible = false
	if _dirty:
		_rebuild()


## The free piece of `target` within SNAP of a held piece at `at` (global), "" none.
func _snap(target: String, at: Vector3) -> String:
	if target.begins_with("lintel_"):
		var lid := _lintel_of(target)
		var l: Dictionary = _pieces.get(lid, {})
		if l.is_empty() or lintels_laid.has(lid):
			return ""
		return lid if to_local(at).distance_to(l.centre as Vector3) <= SNAP * 2.0 else ""
	var free := free_pieces(target)
	var i := BrickBond.nearest(free, to_local(at), SNAP)
	return str(free[i].id) if i >= 0 else ""


## A VR hand let go of the brick: laid at its place if it was near one, else back to the pallet.
func _let_go_piece() -> void:
	var t := str(step.get("target", ""))
	var id := _snap(t, _hand.global_position)
	if id != "":
		if t.begins_with("lintel_"):
			lintels_laid[id] = true
		else:
			laid[id] = true
		_dirty = true
		placed.emit(t)
	_hand_reset()


func _hand_reset() -> void:
	if _hand == null:
		return
	_hand.transform = _hand_home
	var t := str(step.get("target", ""))
	var size: Vector3 = BrickBond.unit(str(plan.get("kind", "brick"))).size
	if t.begins_with("lintel_"):
		var l: Dictionary = _pieces.get(_lintel_of(t), {})
		if not l.is_empty():
			size = l.size
	elif mine.has(t) and not free_pieces(t).is_empty():
		size = free_pieces(t)[0].size
	var piece := _hand.get_node_or_null(^"Piece") as MeshInstance3D
	if piece != null:
		(piece.mesh as BoxMesh).size = size
		piece.material_override = LifeRoomKit.material(CONCRETE.lightened(0.15) if t.begins_with("lintel_")
			else (BLOCK_GREY if str(plan.kind) == "block" else BRICK_RED))


func _rebuild() -> void:
	_dirty = false
	var a: Array = []
	var b: Array = []
	var mortar: Array = []
	var i := 0
	for p: Dictionary in visible_pieces():
		var box := {"centre": p.centre, "size": p.size, "yaw": p.yaw}
		if str(p.id) == _high and _high_up:
			box.centre = (p.centre as Vector3) + Vector3(0, HIGH, 0)
		(a if (hash(p.id) % 3) != 0 else b).append(box)
		mortar.append({"centre": (p.centre as Vector3) + Vector3(0, -0.004, 0), "size": p.size, "yaw": p.yaw,
			"grow": Vector3(0.009, 0.008, -0.012)})
		i += 1
	_bricks_a.set_boxes(a)
	_bricks_b.set_boxes(b)
	_mortar.set_boxes(mortar)
	var lin: Array = []
	for lid: String in lintels_laid:
		var l: Dictionary = _pieces[lid]
		lin.append({"centre": l.centre, "size": l.size, "yaw": l.yaw})
	_lintels.set_boxes(lin)
	if _rafters != null:
		_rafters.set_boxes(_rafter_boxes(rafters_laid))
		_tiles.set_boxes(_tile_boxes(tiles_laid))
	if _test_a != null:
		var tb: Array = []
		var tm: Array = []
		for p: Dictionary in test_bricks:
			var c: Vector3 = p.centre
			if split and float(p.u0) > 0.2:
				c += Vector3(0.025, 0.0, 0.0) + Vector3(0, 0, 0.004 * int(p.course))
			tb.append({"centre": c, "size": p.size, "yaw": p.yaw})
			if not split or float(p.u0) < 0.2:
				tm.append({"centre": c + Vector3(0, -0.004, 0), "size": p.size, "yaw": p.yaw, "grow": Vector3(0.009, 0.008, -0.012)})
		_test_a.set_boxes(tb)
		_test_mortar.set_boxes(tm)


## The first `n` rafter pairs (front and back), leaning together at the ridge.
func _rafter_boxes(n: int) -> Array:
	var out: Array = []
	if rafter_count == 0:
		return out
	var depth := float(plan.depth)
	var top := _origin.y + float(plan.courses) * 0.075 + 0.05
	var half := depth * 0.5
	var length := half / cos(PITCH) + 0.15
	for i in mini(n, rafter_count):
		var x := _rafter_x(i)
		for side: float in [1.0, -1.0]:
			var mid := Vector3(x, top + half * tan(PITCH) * 0.5, _origin.z - half + side * half * 0.5)
			out.append({"centre": mid + Vector3(0, 0.04, side * 0.04), "size": Vector3(0.05, 0.1, length),
				"tilt": PITCH * side})
	return out


## The first `n` rows of tiles on both slopes, from the eaves up, each overlapping the one below.
func _tile_boxes(n: int) -> Array:
	var out: Array = []
	if tile_rows == 0:
		return out
	var depth := float(plan.depth)
	var width := float(plan.length)
	var top := _origin.y + float(plan.courses) * 0.075 + 0.05
	var half := depth * 0.5
	var slope := half / cos(PITCH) + 0.15
	var row := slope / tile_rows * 1.25
	for k in mini(n, tile_rows):
		var s := (float(k) + 0.5) / tile_rows * slope - 0.15
		for side: float in [1.0, -1.0]:
			var along := Vector3(0, sin(PITCH), -cos(PITCH) * side)
			var eave := Vector3(_origin.x + width * 0.5, top + 0.12, _origin.z - half + side * half)
			var c := eave + along * s + Vector3(0, 0.012 * k, 0)   # each row over the top of the one below
			out.append({"centre": c, "size": Vector3(width + 0.2, 0.025, row), "tilt": PITCH * side})
	return out


func _flash(at: Vector3) -> void:
	var m := LifeRoomKit.box(self, "Holds", Vector3(1.0, 0.7, 0.2), at, GOOD)
	m.material_override = LifeRoomKit.material(GOOD, true)
	if is_inside_tree():
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_callback(m.queue_free)


## Owner #118 (Life L3b): the saw used before the goggles, frozen in time: a still puff of sawdust over the work, a few
## chips frozen on their way up, and calm words (never anything at anyone's face).
func on_mistake(event: String, on: bool) -> void:
	if not on or event != "sawdust":
		return
	var holder := mistake_holder()
	var at := to_local(work_frame("rafter_cut").origin)
	for i in 7:
		var m := LifeRoomKit.box(holder, "Chip", Vector3(0.025, 0.025, 0.025),
			at + Vector3(0.04 * (i - 3), 0.08 + 0.05 * (i % 3), -0.03 * (i % 2)), DUST)
		m.material_override = LifeRoomKit.material(DUST, true)
	LifeRoomKit.sign(holder, "Why", "SAWDUST FLIES UP: GOGGLES FIRST", at + Vector3(0, 0.45, 0), 0.0035, Color("ffd23f"))


## Owner #118: a soft puff of sawdust over the work, drifting up and away (never at anyone's face), then gone.
func _puff(at_global: Vector3) -> void:
	var puff := Node3D.new()
	puff.name = "Sawdust"
	add_child(puff)
	for i in 5:
		var m := LifeRoomKit.box(puff, "Dust", Vector3(0.02, 0.02, 0.02), to_local(at_global) + Vector3(0.03 * (i - 2), 0.02, 0.0), DUST)
		m.material_override = LifeRoomKit.material(DUST, true)
		if is_inside_tree():
			var tw := create_tween()
			tw.tween_property(m, "position", m.position + Vector3(0.04 * (i - 2), 0.25, -0.1), 0.9)
			tw.tween_callback(m.queue_free)
	if is_inside_tree():
		get_tree().create_timer(1.2).timeout.connect(puff.queue_free)
