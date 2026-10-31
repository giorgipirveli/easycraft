class_name SortStation
extends PlacingStation
## Owner #122 (G0), Sort it (design §5.1): the things wait on the sorting machine's belt (the table's front); on the
## shelf behind stand the bins, each with its group's name. The child carries each thing into its bin (flat: tap it, tap
## the bin, or drag it there; VR: pick it up and drop it in), then runs the machine: right, the bins light up; not yet,
## everything slides back onto the belt.

const BIN_COLOURS: Array[Color] = [Color("3a7be8"), Color("f08a1c"), Color("2fae4e")]
const BIN := Vector3(0.46, 0.18, 0.32)

var lamps: Array[MeshInstance3D] = []


func build_place() -> void:
	spot_prefix = "bin"
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	LifeRoomKit.box(self, "Belt", Vector3(1.6, 0.02, 0.5), Vector3(0, TABLE_TOP + 0.01, FRONT_Z - 0.1), Color("39445e"))
	shelf()
	var groups: Array = ex.get("groups", [])
	var xs := spread(groups.size(), 0.5)
	for g in groups.size():
		var bin := Node3D.new()
		bin.name = "Bin%d" % g
		bin.position = Vector3(xs[g], SHELF_TOP + BIN.y * 0.5, BACK_Z)
		add_child(bin)
		LifeRoomKit.box(bin, "Box", BIN, Vector3.ZERO, BIN_COLOURS[g % BIN_COLOURS.size()])
		lamps.append(LifeRoomKit.box(bin, "Lamp", Vector3(BIN.x, 0.03, 0.04), Vector3(0, BIN.y * 0.5 + 0.02, BIN.z * 0.5),
			Color("39445e")))
		var name_label := PlayKit.words(bin, "Name", str(groups[g]).to_upper(), Vector3(0, BIN.y * 0.5 + 0.2, 0), 0.0014, 54,
			Color("fff4b0"))
		name_label.width = BIN.x / 0.0014
		add_spot(bin, 0.26)


func make_thing(i: int) -> Node3D:
	var items: Array = ex.get("items", [])
	var item: Variant = items[i]
	var d: Dictionary = item if item is Dictionary else {"text": str(item)}
	return PlayKit.card(self, "Thing%d" % i, d, things_at(items.size())[i], PlayKit.PAPER.darkened(0.1))


func at_spot(_i: int, p: int, k: int) -> Vector3:
	return spots[p].position + Vector3(-0.11 + 0.22 * (k % 2), BIN.y * 0.5 + 0.06 + 0.05 * (k / 2), 0.04 - 0.05 * (k / 2))


func celebrate() -> void:
	for l in lamps:
		l.material_override = LifeRoomKit.material(Color("8dff8a"), true)
	super()


func placed_scale() -> float:
	return 0.48   # two to a row in a bin
