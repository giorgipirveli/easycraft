class_name PlayArena
extends LifeRoom
## Owner #122 (G0; docs/devlog/parts/play-g0.md §1): the one small place where every unit of the School is played. It is
## a Life room (LifeRoom: targets with forgiving radii, the flat view and the VR spot, the glow, Life's kit: only shaders
## the warm-up already holds), outdoors on a little meadow far above the menu's world, with its own calm sky. Each
## challenge builds its mechanic's station here (`show_challenge`: PlayStations.make), replacing the one before with all
## its things; an exercise's picture shows on the board behind it (PlayBoard). The child stands at VIEW in VR (in front
## of the table, facing -Z); the flat camera looks over their shoulder at the table, the places and the board.

const VIEW := "station"
## The picture board's target (a tap shows the picture big).
const BOARD := "board"
## Where the child stands in VR (the room's floor is y = 0; LifeRoom.EYE above it).
const FEET := Vector3(0, 0, 0.9)
const GRASS := Color("7cc35a")
const GRASS_DARK := Color("5e9e43")

var station: PlayStation
var board: PlayBoard
var colour := Color("3a7be8")


func _init(subject_colour: Color = Color("3a7be8")) -> void:
	super("middle")
	name = "PlayArena"
	colour = subject_colour
	start_view = VIEW


func build() -> void:
	env = LifeRoomKit.environment(Color("9fd3f5"), Color("e9f3fb"), 0.62)
	_garden()   # the rooms' look (2026-10-18): a meadow garden round the table, its one warm sun, a soft sky
	_set_view(Vector3(0, 1.5, 1.7), Vector3(0, 1.1, 0.0))


## The rooms' look (docs/devlog/parts/rooms-look.md): the little meadow in the game's grass, a patio of slabs under the
## table and where the child stands, stepping stones to a big friendly tree at the back with a picnic rug under it, a
## picket fence with flower beds, a potting bench and a tool shed to the left, a bench to the right, far trees and hills;
## drawn as a handful of meshes (LifeRoomDecor), clear of every station's things (the stations stand within x ±2.5,
## z -2 .. 1: test_room_look_play.gd). The place's one light is its sun (the play budget: one light).
func _garden() -> void:
	sun(Color(1.0, 0.95, 0.86), 1.05, -48.0, -24.0)
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.ground_around("Grass", Rect2(-3.5, -3.5, 7.0, 6.0), 70.0, -0.02, Color("86c063"))
	d.tiled("Meadow", LifeRoomDecor.GRASS, Vector3(7.0, 0.2, 6.0), Vector3(0, -0.1, -0.5), Color("d9ecc6"), 1.0)
	d.tiled("Patio", LifeRoomDecor.SLABS, Vector3(3.4, 0.03, 2.3), Vector3(0, -0.006, 0.55), Color("f1e3c8"), 0.85)
	for i in 4:   # stepping stones towards the tree
		d.cylinder("Stone", 0.24, 0.03, Vector3(0.12 * (i % 2) - 0.06, 0.004, -0.95 - i * 0.62), Color("aaa396"), -1.0, 9,
			LifeRoomDecor.SHELL)
	# the big tree at the back, a rug and a basket under it
	d.tree("Oak", Vector3(0.9, 0, -5.1), 1.55, Color("4f9a3e"))
	d.rug("Picnic", Vector3(-0.4, 0, -4.4), Vector2(1.4, 1.0), Color("f6c9b4"), Color("e8544e"), 0.3)
	d.cylinder("Basket", 0.16, 0.18, Vector3(-0.1, 0.09, -4.5), Color("c9a063"))
	d.tree("Tree", Vector3(-3.3, 0, -3.3), 0.85, Color("5aa548"))
	d.tree("Tree", Vector3(3.4, 0, -3.0), 0.8)
	# the fence along the back with a gap for the stones, flower beds inside it
	d.fence("Fence", Vector3(-3.5, 0, -3.55), Vector3(-0.7, 0, -3.55), Color("fdfaf2"), 0.75)
	d.fence("Fence", Vector3(0.7, 0, -3.55), Vector3(3.5, 0, -3.55), Color("fdfaf2"), 0.75)
	for p: Array in [[-2.5, Color("e85a9a")], [-1.5, Color("ffc93c")], [1.5, Color("b03cc0")], [2.5, Color("f39a3c")]]:
		d.bush("Flowers", Vector3(float(p[0]), 0, -3.15), 0.9, Color("5aa548"), p[1])
	# to the left: a potting bench and a little tool shed; to the right: a bench under the tree
	d.house("Shed", Vector3(-5.2, 0, 1.2), Vector3(1.8, 2.0, 1.6), PI / 2, Color("cfe0ee"), Color("6b7a99"), Color("8a6239"), 1)
	d.box("PottingBench", Vector3(1.2, 0.06, 0.5), Vector3(-3.9, 0.82, 0.6), PlayKit.WOOD, PI / 2)
	for z: float in [0.12, 1.08]:
		d.box("PottingLeg", Vector3(0.45, 0.8, 0.06), Vector3(-3.9, 0.4, z), PlayKit.WOOD_DARK, PI / 2)
	for k in 3:
		d.plant("Pot", Vector3(-3.9, 0.85, 0.3 + k * 0.32), 0.55, Color("d9774a"), Color("5aa548").lightened(0.1 * k))
	d.bench("Bench", Vector3(3.9, 0, 0.5), -PI / 2)
	# far round the meadow: trees and hedges
	for at: Vector3 in [Vector3(-7.5, 0, -7.0), Vector3(7.0, 0, -8.0), Vector3(-9.0, 0, 2.0), Vector3(9.5, 0, 1.0), Vector3(-2.5, 0, 7.5),
			Vector3(3.5, 0, 8.0)]:
		d.tree("FarTree", at, 1.1 + 0.1 * absf(at.x) / 9.0, Color("4f9a3e") if int(at.x) % 2 == 0 else Color("5aa548"))
	for at: Vector3 in [Vector3(-6.0, 0, -4.5), Vector3(6.5, 0, -4.0), Vector3(-6.5, 0, 4.0)]:
		d.bush("Hedge", at, 1.6)


## The station for `ex` (its mechanic's, or the unit's signature `game`'s when it expresses `ex`), built fresh in the
## place; the old one goes with its things and board.
func show_challenge(ex: Dictionary, seed: int, params: Dictionary = {}, game: String = "") -> PlayStation:
	clear_station()
	station = PlayStations.make(ex, game)
	station.setup(ex, seed, params, self)
	add_child(station)
	station.build()
	_set_view(station.view_cam(), station.view_look())
	var pic := station.board_picture()
	if not pic.is_empty():
		board = PlayBoard.new(pic, station.board_size())
		board.position = station.board_at()
		add_child(board)
		add_target(BOARD, board, 0.3)   # a tap on the board shows the picture big (the host's)
		face_board(to_global(view(VIEW).cam))
	return station


## The board turns to face whoever looks at it (the flat camera, or the child's eyes in VR), upright.
## Owner #133 (rule 0): the words on each visible label in the place (a card, a bin, a button), for the tests and the
## smoke run: every one a short name.
func label_words() -> Array[int]:
	var out: Array[int] = []
	for n in find_children("*", "Label3D", true, false):
		var l := n as Label3D
		if l.is_visible_in_tree() and l.text.strip_edges() != "":
			out.append(PlayReadless.words(l.text))
	return out


func face_board(viewer: Vector3) -> void:
	if board == null or not board.is_inside_tree():
		return
	var at := board.global_position
	var to := viewer - at
	if to.length() < 0.01:
		return
	board.global_transform = Transform3D(Basis.looking_at(-to.normalized(), Vector3.UP), at)


func clear_station() -> void:
	glow([] as Array[String])
	if station != null:
		for t in station.owned():
			targets.erase(t)
		remove_child(station)
		station.queue_free()
		station = null
	if board != null:
		targets.erase(BOARD)
		remove_child(board)
		board.queue_free()
		board = null


func _set_view(cam: Vector3, look: Vector3) -> void:
	add_view(VIEW, cam, look, FEET, 0.0)
