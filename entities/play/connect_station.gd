class_name ConnectStation
extends PlacingStation
## Owner #122 (G0), Connect it (design §5.1): a lamp board. Each pair's first half is a plug on a wire at the table's
## front; the second halves are sockets under dark lamps on the shelf behind. The child takes each plug to its partner's
## socket (flat: tap the plug, tap the socket, or drag it; VR: carry the plug, its wire follows), then switches on: right,
## every lamp lights; not yet, the plugs spring back to their posts (as the School's match answer cleared).

const SOCKET := Vector3(0.34, 0.13, 0.05)
const GAP := 0.37

var posts: Array[Vector3] = []
var wires: Array[MeshInstance3D] = []
var lamps: Array[MeshInstance3D] = []


func build_place() -> void:
	spot_prefix = "socket"
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	shelf()
	var matches: Array = ex.get("matches", [])
	var xs := spread(matches.size(), GAP)
	for m in matches.size():
		var socket := Node3D.new()
		socket.name = "Socket%d" % m
		socket.position = Vector3(xs[m], SHELF_TOP + 0.12, BACK_Z + 0.1)
		add_child(socket)
		var item: Variant = matches[m]
		var d: Dictionary = item if item is Dictionary else {"text": str(item)}
		PlayKit.card(socket, "Face", d, Vector3.ZERO, Color("39445e"), SOCKET)
		lamps.append(LifeRoomKit.sphere(socket, "Lamp", 0.045, Vector3(0, 0.13, -0.03), Color("4a4f60")))
		add_spot(socket, 0.18)


func make_thing(i: int) -> Node3D:
	var items: Array = ex.get("items", [])
	var at := things_at(items.size())[i]
	posts.append(at)
	LifeRoomKit.box(self, "Post%d" % i, Vector3(0.05, at.y - TABLE_TOP, 0.05),
		Vector3(at.x, (at.y + TABLE_TOP) * 0.5 - 0.05, at.z + 0.04), Color("6b7a99"))
	var item: Variant = items[i]
	var d: Dictionary = item if item is Dictionary else {"text": str(item)}
	var plug := PlayKit.card(self, "Plug%d" % i, d, at, Color("e0a325"))
	var wire := LifeRoomKit.box(self, "Wire%d" % i, Vector3(0.015, 0.015, 1.0), at, Color("1f2a4a"))
	wire.visible = false
	wires.append(wire)
	return plug


func placed_scale() -> float:
	return 0.72


func at_spot(_i: int, p: int, _k: int) -> Vector3:
	return spots[p].position + Vector3(0, -0.16, 0.16)


## Each placed plug's wire runs from its post to its socket.
func placed_changed() -> void:
	for i in wires.size():
		var p := placing.at[i]
		wires[i].visible = p >= 0
		if p < 0:
			continue
		var from := posts[i] + Vector3(0, -0.06, 0.04)
		var to := at_spot(i, p, 0)
		var length := from.distance_to(to)
		if length < 0.01:
			continue
		var dir := (to - from).normalized()
		wires[i].transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD),
			(from + to) * 0.5)
		wires[i].scale = Vector3(1, 1, length)


func celebrate() -> void:
	for l in lamps:
		l.material_override = LifeRoomKit.material(Color("ffe066"), true)
	super()
