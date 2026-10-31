class_name MarketPlazaBuildings
extends Node3D
## Owner #115 (S3): the Market Square's two places as models beside Life Town (like LifeTownBuildings: nothing stamped,
## nobody can break them): the bakery (My Business's shop: cream walls, a red and white striped awning, a big window
## with loaves, its door) and the market (three little stalls under striped awnings with their goods, and the Price Board
## on its legs with its rows and arrows). Each stands on the highest ground under its own footprint with a stone plinth
## down to lower ground, its sign over the door (a billboard, readable from anywhere, in VR too) and a soft green ring on
## the ground where to walk up. One merged vertex-colour mesh (WeaponModels' material: warmed) and one static body on the
## world layer. Local space: the site's middle cell's centre at its height, +Z towards the spawn (MarketPlaza's frame).

const LAYER := 1
const STONE := Color("9aa3ad")
const PAVING := Color("d8d2c4")
const RING := Color("6fcf7a")
const WHITE := Color("f4f6f8")
const RED := Color("e8544e")
const WOOD := Color("a8642a")

var site := {}
var floors := {}
var parts: Array = []
var solids: Array[AABB] = []
var signs: Array[Label3D] = []
var _ground := Callable()


func setup(plaza: Dictionary, ground: Callable = Callable()) -> void:
	site = plaza
	_ground = ground
	name = "MarketPlazaBuildings"
	var p: Vector3i = site.pos
	position = Vector3(p.x + 0.5, p.y, p.z + 0.5)
	rotation = Vector3(0, int(site.facing) * PI / 2.0, 0)
	for id: String in MarketPlaza.SPOTS:
		floors[id] = _floor_of(id)
	_bakery()
	_market()
	for id: String in MarketPlaza.SPOTS:
		var door: Vector2 = MarketPlaza.SPOTS[id].door
		parts.append([Vector3(door.x, _ground_at(Vector2i(door.floor())) + 0.04, door.y), Vector3(1.4, 0.04, 1.4), RING])
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = WeaponModels.build(parts)
	mesh.material_override = WeaponModels.material()
	add_child(mesh)
	var body := StaticBody3D.new()
	body.name = "Walls"
	body.collision_layer = LAYER
	body.collision_mask = 0
	for b in solids:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = b.size
		shape.shape = box
		shape.position = b.get_center()
		body.add_child(shape)
	add_child(body)


func _floor_of(id: String) -> float:
	if not _ground.is_valid():
		return 0.0
	var s: Dictionary = MarketPlaza.SPOTS[id]
	var hi := -INF
	for lx in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):
		for lz in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
			var w := MarketPlaza.to_world(site, Vector2i(lx, lz))
			hi = maxf(hi, float(_ground.call(w.x, w.y)))
	return hi - float((site.pos as Vector3i).y)


func _ground_at(local: Vector2i) -> float:
	if not _ground.is_valid():
		return 0.0
	var w := MarketPlaza.to_world(site, local)
	return float(_ground.call(w.x, w.y)) - float((site.pos as Vector3i).y)


func _box(id: String, lo: Vector3, hi: Vector3, colour: Color, solid: bool = true) -> void:
	var f := Vector3(0, float(floors[id]), 0)
	var a := lo + f
	var b := hi + f
	parts.append([(a + b) * 0.5, b - a, colour])
	if solid:
		solids.append(AABB(a, b - a))


func _base(id: String) -> void:
	var s: Dictionary = MarketPlaza.SPOTS[id]
	var mn := Vector2(s.min) - Vector2(0.5, 0.5)
	var mx := Vector2(s.max) + Vector2(0.5, 0.5)
	_box(id, Vector3(mn.x, -LifeTown.PLINTH_DEPTH, mn.y), Vector3(mx.x, 0.0, mx.y), STONE, false)
	_box(id, Vector3(mn.x, 0.0, mn.y), Vector3(mx.x, 0.06, mx.y), PAVING, false)


func _sign(id: String, at: Vector3) -> void:
	var l := LifeRoomKit.sign(self, "Sign_" + id, str(MarketPlaza.SPOTS[id].sign), at + Vector3(0, float(floors[id]), 0), 0.012)
	signs.append(l)


## The bakery: My Business's shop.
func _bakery() -> void:
	_base("bakery")
	_box("bakery", Vector3(-7.4, 0.06, -3.4), Vector3(-1.6, 3.0, 0.8), Color("fbefd8"))
	for i in 8:
		var x := -7.6 + i * 0.775
		_box("bakery", Vector3(x, 2.6, 0.8), Vector3(x + 0.775, 2.75, 1.7), RED if i % 2 == 0 else WHITE, false)
	_box("bakery", Vector3(-6.6, 0.9, 0.8), Vector3(-4.6, 2.2, 0.86), Color("cfe7ff"), false)   # the big window
	for i in 3:
		_box("bakery", Vector3(-6.3 + i * 0.6, 1.0, 0.86), Vector3(-5.9 + i * 0.6, 1.25, 0.95), Color("d99a4e"), false)
	_box("bakery", Vector3(-4.0, 0.06, 0.8), Vector3(-3.0, 2.1, 0.86), Color("8a5a34"), false)   # its door
	_box("bakery", Vector3(-7.6, 3.0, -3.6), Vector3(-1.4, 3.3, 1.0), Color("c0563a"), false)   # the roof
	_sign("bakery", Vector3(-4.5, 4.0, 1.0))


## The market: three little stalls with their goods and the Price Board.
func _market() -> void:
	_base("square")
	var goods := [Color("e8544e"), Color("f4ecd8"), Color("e8b04a")]
	for i in 3:
		var x := 1.4 + i * 1.6
		_box("square", Vector3(x, 0.06, -0.2), Vector3(x + 1.2, 0.95, 0.5), WOOD)
		for k in 4:
			_box("square", Vector3(x + k * 0.3, 2.2, -0.6), Vector3(x + k * 0.3 + 0.3, 2.3, 0.7), RED if k % 2 == 0 else WHITE, false)
		for px: float in [x + 0.05, x + 1.1]:
			_box("square", Vector3(px, 0.06, 0.4), Vector3(px + 0.06, 2.2, 0.46), Color("6b4a2a"))
		for k in 3:
			_box("square", Vector3(x + 0.15 + k * 0.35, 0.95, 0.0), Vector3(x + 0.4 + k * 0.35, 1.12, 0.25), goods[i], false)
	_box("square", Vector3(2.4, 1.0, -2.8), Vector3(6.2, 3.0, -2.6), Color("2f4a3d"))   # the Price Board
	for x: float in [2.6, 5.9]:
		_box("square", Vector3(x, 0.06, -2.75), Vector3(x + 0.12, 1.0, -2.65), Color("6b4a2a"))
	for k in 4:
		var y := 2.6 - k * 0.42
		_box("square", Vector3(2.7, y, -2.6), Vector3(4.0, y + 0.08, -2.56), WHITE, false)
		_box("square", Vector3(4.3, y, -2.6), Vector3(4.6, y + 0.12, -2.56), Color("ffc93c"), false)
		_box("square", Vector3(5.0, y - 0.04, -2.6), Vector3(5.12, y + 0.16, -2.56), Color("4fbf6a") if k % 2 == 0 else Color("3a7be8"),
			false)
	_sign("square", Vector3(4.0, 3.9, 0.6))
