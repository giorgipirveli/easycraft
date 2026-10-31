class_name FindStation
extends PlayStation
## Owner #122 (G0), Find it (design §5.1): the School's coordinate grid is a treasure map on an easel, its axes numbered,
## its given points marked. A tap on a crossing (VR: a hand or the laser) puts the spade there; DIG HERE: right, the
## treasure chest comes up; not yet, the spade stays to be moved. ExerciseCheck's response is the crossing (x, y).

const FACE := Vector2(0.86, 0.7)
const AT := Vector3(0, SHELF_TOP + 0.31, BACK_Z + 0.1)
const TILT := 0.42

var grid: Dictionary
var map: Node3D
var chosen := Vector2i(-1, -1)
var spade: Node3D
var chest: Node3D
var step := Vector2i.ONE
var lines := Vector2i.ONE


func build() -> void:
	grid = ex.get("grid", {})
	step = GridCheck.step(grid)
	lines = GridCheck.lines(grid)
	PlayKit.table(self, Vector3(0, 0, FRONT_Z), Vector2(TABLE_SIZE.x, 0.3), TABLE_TOP)
	shelf()
	map = Node3D.new()   # the treasure map on its easel, leaning back towards the child
	map.name = "Map"
	map.position = AT
	map.rotation.x = -TILT
	add_child(map)
	LifeRoomKit.box(map, "Paper", Vector3(FACE.x + 0.14, FACE.y + 0.14, 0.02), Vector3(0, 0, -0.02), Color("f3e2b3"))
	var x_max := int(grid.get("x_max", 1))
	var y_max := int(grid.get("y_max", 1))
	for i in lines.x + 1:
		LifeRoomKit.box(map, "LineX", Vector3(0.004, FACE.y, 0.004), _at(Vector2i(i * step.x, 0)) + Vector3(0, FACE.y * 0.5, 0),
			Color("8a6239"))
		PlayKit.words(map, "NumberX", str(i * step.x), _at(Vector2i(i * step.x, 0)) + Vector3(0, -0.035, 0.01), 0.0008, 36,
			Color("1f2a4a"))
	for j in lines.y + 1:
		LifeRoomKit.box(map, "LineY", Vector3(FACE.x, 0.004, 0.004), _at(Vector2i(0, j * step.y)) + Vector3(FACE.x * 0.5, 0, 0),
			Color("8a6239"))
		PlayKit.words(map, "NumberY", str(j * step.y), _at(Vector2i(0, j * step.y)) + Vector3(-0.04, 0, 0.01), 0.0008, 36,
			Color("1f2a4a"))
	for p: Variant in grid.get("points", []):
		var at := _at(Vector2i(int(p.x), int(p.y)))
		LifeRoomKit.sphere(map, "Point", 0.014, at + Vector3(0, 0, 0.01), Color("d6475a"))
		if str(p.get("label", "")) != "":
			PlayKit.words(map, "Label", str(p.label), at + Vector3(0.03, 0.03, 0.01), 0.0009, 40, Color("1f2a4a"))
	for i in lines.x + 1:
		for j in lines.y + 1:
			var c := Vector2i(i * step.x, j * step.y)
			if c.x > x_max or c.y > y_max:
				continue
			var spot := Node3D.new()
			spot.name = "Crossing_%d_%d" % [c.x, c.y]
			spot.position = _at(c) + Vector3(0, 0, 0.012)
			map.add_child(spot)
			add("pt_%d_%d" % [c.x, c.y], spot, minf(FACE.x / maxf(lines.x, 1.0), FACE.y / maxf(lines.y, 1.0)) * 0.45)
	spade = Node3D.new()
	spade.name = "Spade"
	spade.visible = false
	map.add_child(spade)
	LifeRoomKit.box(spade, "Handle", Vector3(0.008, 0.06, 0.008), Vector3(0, 0.04, 0.02), PlayKit.WOOD_DARK)
	LifeRoomKit.box(spade, "Blade", Vector3(0.03, 0.025, 0.006), Vector3(0, 0.005, 0.02), Color("8a93a6"))
	chest = Node3D.new()
	chest.name = "Chest"
	chest.visible = false
	map.add_child(chest)
	LifeRoomKit.box(chest, "Box", Vector3(0.06, 0.04, 0.03), Vector3(0, 0, 0.03), Color("c98d4f"))
	add(GO, PlayKit.go_button(self, go_words(), GO_AT), 0.11)


## A grid point on the map's face (the map's own frame, from its middle).
func _at(c: Vector2i) -> Vector3:
	var x_max := maxf(float(grid.get("x_max", 1)), 1.0)
	var y_max := maxf(float(grid.get("y_max", 1)), 1.0)
	return Vector3(-FACE.x * 0.5 + FACE.x * c.x / x_max, -FACE.y * 0.5 + FACE.y * c.y / y_max, 0.005)


func press(t: String) -> void:
	if not t.begins_with("pt_"):
		return
	chosen = Vector2i(int(t.get_slice("_", 1)), int(t.get_slice("_", 2)))
	spade.position = _at(chosen)
	spade.visible = true
	changed.emit()


func is_ready() -> bool:
	return chosen.x >= 0


func response() -> Variant:
	return chosen


func ghost() -> Array[String]:
	var want: Variant = GridCheck.point(ex.get("answer"))
	if want == null or chosen == want:
		return [] as Array[String]
	return ["pt_%d_%d" % [(want as Vector2i).x, (want as Vector2i).y]] as Array[String]


## One dig answers it: showing it first would answer it (owner #133).
func demo_kind() -> String:
	return DEMO_NONE


func show_answer() -> void:
	var want: Variant = GridCheck.point(ex.get("answer"))
	if want is Vector2i:
		press("pt_%d_%d" % [(want as Vector2i).x, (want as Vector2i).y])
		_dig()


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			_dig()
		PlayLoop.NOT_YET, PlayLoop.GHOST:
			shake(spade)
		PlayLoop.SHOWN:
			show_answer()


func _dig() -> void:
	chest.position = _at(chosen) + Vector3(0, 0.03, 0)
	chest.visible = true
	hop(chest)
