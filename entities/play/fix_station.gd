class_name FixStation
extends PlacingStation
## Owner #122 (G0), Fix it (design §5.1): the picture (any SchoolPicture) stands on a board on the shelf, tilted back
## towards the child, with its numbered pins; its labels lie on the table as tags. The child puts each tag on its pin
## (flat: tap the tag, tap the pin, or drag it; VR: carry it), then starts it: right, the board's lights come on; not
## yet, the tags fall back onto the table (as the School's label answer cleared).

## The board's face: ExerciseCheck.LABEL_BOX's shape (the pins are fractions of it), close enough for the hands.
const FACE := Vector2(1.04, 0.5)
const AT := Vector3(0, SHELF_TOP + 0.3, BACK_Z + 0.06)
const TILT := 0.42

var face: Node3D
var picture_board: PlayBoard
var lights: Array[MeshInstance3D] = []


func board_picture() -> Dictionary:
	return {}   # the station's own board: the pins sit on it


func build_place() -> void:
	spot_prefix = "pin"
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	shelf()
	face = Node3D.new()
	face.name = "Face"
	face.position = AT
	face.rotation.x = -TILT
	add_child(face)
	picture_board = PlayBoard.new(ex.get("picture", {}), FACE, Vector2i(ExerciseCheck.LABEL_BOX))
	face.add_child(picture_board)
	for p: Variant in ex.get("spots", []):
		var k := spots.size()
		var spot := Node3D.new()
		spot.name = "Pin%d" % k
		spot.position = _on_face(Vector2(float(p[0]), float(p[1]))) + Vector3(0, 0, 0.03)
		face.add_child(spot)
		LifeRoomKit.sphere(spot, "Head", 0.028, Vector3.ZERO, Color("d6475a"))
		PlayKit.words(spot, "Number", str(k + 1), Vector3(0, 0, 0.035), 0.0009, 40, Color.WHITE)
		if (p as Array).size() == 4:   # a pin beside the drawing, with a line to its part
			var to := _on_face(Vector2(float(p[2]), float(p[3]))) + Vector3(0, 0, 0.02)
			var length := spot.position.distance_to(to)
			if length > 0.01:
				var line := LifeRoomKit.box(face, "Line%d" % k, Vector3(0.008, 0.008, 1.0), Vector3.ZERO, Color("d6475a"))
				var dir := (to - spot.position).normalized()
				line.transform = Transform3D(Basis.looking_at(dir, Vector3.FORWARD if absf(dir.y) > 0.99 else Vector3.UP),
					(spot.position + to) * 0.5)
				line.scale = Vector3(1, 1, length)
		spots.append(spot)
		add("%s_%d" % [spot_prefix, k], spot, 0.07)
	for x: float in [-0.6, 0.6]:
		lights.append(LifeRoomKit.sphere(face, "Light", 0.04, Vector3(x, FACE.y * 0.5 + 0.05, 0), Color("4a4f60")))


func make_thing(i: int) -> Node3D:
	var labels: Array = ex.get("labels", [])
	return PlayKit.card(self, "Tag%d" % i, {"text": str(labels[i])}, things_at(labels.size())[i], Color("f6f2ea"),
		Vector3(0.34, 0.08, 0.04))


func thing_radius() -> float:
	return 0.11


func placed_scale() -> float:
	return 0.6


## A tag hangs just under its pin, on the board.
func at_spot(_i: int, p: int, _k: int) -> Vector3:
	return to_local(spots[p].global_position + face.global_basis * Vector3(0, -0.05, 0.03))


## A spot's [x, y] (fractions of LABEL_BOX, y down) on the board's face (from its middle).
func _on_face(f: Vector2) -> Vector3:
	return Vector3((f.x - 0.5) * FACE.x, (0.5 - f.y) * FACE.y, 0)


func celebrate() -> void:
	for l in lights:
		l.material_override = LifeRoomKit.material(Color("ffe066"), true)
	super()
