class_name LifeTownBuildings
extends Node3D
## Owner #112 (docs/design/life-skills.md §7, Life Town; Life L2): Life Town's six places as models (nobody can break
## them; nothing stamped): the practice house with its red roof and its smoke alarm, the clinic with its green cross, the
## market stall under a striped awning, the kitchen house with its chimney, a short street with a crossing and its
## lollipop sign, and the park bench under a tree. Each stands on the highest ground under its own footprint with a
## stone plinth down to lower ground (LifeTown), its sign over the door (a billboard, readable from anywhere, in VR too)
## and a soft green ring on the ground where to walk up. One merged vertex-colour mesh (WeaponModels' material: warmed)
## and one static body on the world layer. Life L3b (owner #118, #115): the second row's seven (_second_row). Life L3c
## (owner #112, #118): the third row's three (_third_row). Local space: the site's middle cell's centre at the site's
## height, +Z towards the spawn (LifeTown's frame, turned by `facing`).

const LAYER := 1
const STONE := Color("9aa3ad")
const PAVING := Color("d8d2c4")
const RING := Color("6fcf7a")
const ROAD := Color("4a5160")
const WHITE := Color("f4f6f8")

var site := {}
var floors := {}   # place -> its floor (m, from the site's height)
var parts: Array = []
var solids: Array[AABB] = []
var signs: Array[Label3D] = []
var _ground := Callable()


## Stands the places on `site`; `ground` (x, z) -> the first empty y there (the generator's; flat at the site's y when
## none).
func setup(town_site: Dictionary, ground: Callable = Callable()) -> void:
	site = town_site
	_ground = ground
	name = "LifeTownBuildings"
	var p: Vector3i = site.pos
	position = Vector3(p.x + 0.5, p.y, p.z + 0.5)
	rotation = Vector3(0, int(site.facing) * PI / 2.0, 0)
	for id: String in LifeTown.SPOTS:
		floors[id] = _floor_of(id, ground)
	_house()
	_clinic()
	_market()
	_kitchen()
	_street()
	_bench()
	_site()
	_pool()
	_cupboard()
	_hut()
	_second_row()   # Life L3b (owner #118, #115)
	_third_row()   # Life L3c (owner #112, #118)
	for id: String in LifeTown.SPOTS:   # a soft green ring where to walk up, on the ground there
		var door: Vector2 = LifeTown.SPOTS[id].door
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


## A place's floor: the highest ground under its footprint (m from the site's height).
func _floor_of(id: String, ground: Callable) -> float:
	if not ground.is_valid():
		return 0.0
	var s: Dictionary = LifeTown.SPOTS[id]
	var hi := -INF
	for lx in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):
		for lz in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
			var w := LifeTown.to_world(site, Vector2i(lx, lz))
			hi = maxf(hi, float(ground.call(w.x, w.y)))
	return hi - float((site.pos as Vector3i).y)


## The ground (m from the site's height) at a local cell.
func _ground_at(local: Vector2i) -> float:
	if not _ground.is_valid():
		return 0.0
	var w := LifeTown.to_world(site, local)
	return float(_ground.call(w.x, w.y)) - float((site.pos as Vector3i).y)


## A box between two local corners (m; y from the place's floor), solid (in the body) or not.
func _box(id: String, lo: Vector3, hi: Vector3, colour: Color, solid: bool = true) -> void:
	var f := Vector3(0, float(floors[id]), 0)
	var a := lo + f
	var b := hi + f
	parts.append([(a + b) * 0.5, b - a, colour])
	if solid:
		solids.append(AABB(a, b - a))


## A plinth under a footprint down to lower ground, and the footprint's paving.
func _base(id: String) -> void:
	var s: Dictionary = LifeTown.SPOTS[id]
	var mn := Vector2(s.min) - Vector2(0.5, 0.5)
	var mx := Vector2(s.max) + Vector2(0.5, 0.5)
	_box(id, Vector3(mn.x, -LifeTown.PLINTH_DEPTH, mn.y), Vector3(mx.x, 0.0, mx.y), STONE, false)
	_box(id, Vector3(mn.x, 0.0, mn.y), Vector3(mx.x, 0.06, mx.y), PAVING, false)


func _sign(id: String, at: Vector3) -> void:
	var l := LifeRoomKit.sign(self, "Sign_" + id, str(LifeTown.SPOTS[id].sign), at + Vector3(0, float(floors[id]), 0), 0.012)
	signs.append(l)


func _house() -> void:
	_base("house")
	_box("house", Vector3(-11.5, 0.06, -6.5), Vector3(-6.5, 3.0, -1.5), Color("f1e4cc"))
	_box("house", Vector3(-11.8, 3.0, -6.8), Vector3(-6.2, 3.5, -1.2), Color("c0563a"), false)
	_box("house", Vector3(-9.4, 0.06, -1.53), Vector3(-8.6, 2.1, -1.47), Color("8a5a34"), false)
	for x: float in [-10.4, -7.6]:
		_box("house", Vector3(x - 0.3, 1.4, -1.53), Vector3(x + 0.3, 2.2, -1.47), Color("9fd8ff"), false)
	_box("house", Vector3(-9.1, 2.45, -1.53), Vector3(-8.9, 2.6, -1.47), WHITE, false)   # its smoke alarm
	_sign("house", Vector3(-9.0, 4.2, -1.3))


func _clinic() -> void:
	_base("clinic")
	_box("clinic", Vector3(-5.5, 0.06, -6.5), Vector3(-1.5, 2.8, -1.5), WHITE)
	_box("clinic", Vector3(-5.7, 2.8, -6.7), Vector3(-1.3, 3.0, -1.3), Color("3fbf5a"), false)
	_box("clinic", Vector3(-3.9, 0.06, -1.53), Vector3(-3.1, 2.1, -1.47), Color("9fd8ff"), false)
	_box("clinic", Vector3(-3.6, 2.2, -1.53), Vector3(-3.4, 2.6, -1.47), Color("3fbf5a"), false)   # the green cross
	_box("clinic", Vector3(-3.7, 2.3, -1.53), Vector3(-3.3, 2.5, -1.47), Color("3fbf5a"), false)
	_sign("clinic", Vector3(-3.5, 3.8, -1.3))


func _market() -> void:
	_base("market")
	_box("market", Vector3(0.6, 0.06, -3.4), Vector3(3.4, 0.95, -2.6), Color("b07a46"))
	for x: float in [0.6, 3.4]:
		_box("market", Vector3(x - 0.05, 0.06, -3.05), Vector3(x + 0.05, 2.3, -2.95), Color("6b4a2a"))
	for i in 6:
		var x := 0.5 + i * 0.5
		_box("market", Vector3(x, 2.3, -5.5), Vector3(x + 0.5, 2.4, -2.5), Color("e8544e") if i % 2 == 0 else WHITE, false)
	_box("market", Vector3(1.3, 0.95, -3.1), Vector3(1.6, 1.15, -2.9), Color("d99a4e"), false)   # bread
	_box("market", Vector3(2.2, 0.95, -3.1), Vector3(2.4, 1.05, -2.9), Color("ffc93c"), false)   # coins
	_sign("market", Vector3(2.0, 3.1, -2.6))


func _kitchen() -> void:
	_base("kitchen")
	_box("kitchen", Vector3(5.5, 0.06, -6.5), Vector3(10.5, 3.0, -1.5), Color("fbe9a8"))
	_box("kitchen", Vector3(5.2, 3.0, -6.8), Vector3(10.8, 3.5, -1.2), Color("7fb8d6"), false)
	_box("kitchen", Vector3(9.0, 3.5, -5.0), Vector3(9.4, 4.4, -4.6), Color("c0563a"), false)   # the chimney
	_box("kitchen", Vector3(7.6, 0.06, -1.53), Vector3(8.4, 2.1, -1.47), Color("8a5a34"), false)
	_box("kitchen", Vector3(6.4, 1.3, -1.53), Vector3(7.1, 2.1, -1.47), Color("9fd8ff"), false)
	_sign("kitchen", Vector3(8.0, 4.2, -1.3))


func _street() -> void:
	var s: Dictionary = LifeTown.SPOTS.street
	var f := float(floors.street)
	for x in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):   # the road follows the ground, a cell at a time
		var g := -INF
		for z in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
			g = maxf(g, _ground_at(Vector2i(x, z)))
		parts.append([Vector3(x, g - 1.47, 3.0), Vector3(1.0, 3.0, 3.0), STONE])
		parts.append([Vector3(x, g + 0.03, 3.0), Vector3(1.0, 0.06, 3.0), ROAD])
	var gc := -INF
	for z in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
		gc = maxf(gc, _ground_at(Vector2i(-1, z)))
	for i in 5:   # the crossing's stripes
		parts.append([Vector3(-1.0, gc + 0.07, 1.8 + i * 0.6), Vector3(1.6, 0.02, 0.3), WHITE])
	_box("street", Vector3(-1.85, 0.0, 0.95), Vector3(-1.75, 2.4, 1.05), Color("3b3f4a"))   # the lollipop sign's pole
	parts.append([Vector3(-1.8, f + 2.6, 1.0), Vector3(0.7, 0.7, 0.08), Color("ffd23f")])
	_sign("street", Vector3(-1.0, 3.4, 1.0))


func _bench() -> void:
	var f := float(floors.bench)
	_box("bench", Vector3(8.2, 0.0, 5.2), Vector3(9.8, 0.5, 5.6), Color("a8642a"))
	parts.append([Vector3(9.0, f + 0.85, 5.95), Vector3(2.0, 0.5, 0.1), Color("a8642a")])
	_box("bench", Vector3(10.35, 0.0, 5.55), Vector3(10.65, 2.4, 5.85), Color("8a5a34"))   # the tree's trunk
	parts.append([Vector3(10.5, f + 3.0, 5.7), Vector3(2.2, 1.6, 2.2), Color("4f9a3e")])
	_sign("bench", Vector3(9.0, 2.6, 5.0))


## Owner #116 (round 4b; the lead): Real Builder's building site: a half-built wall laid in a staggered bond, the
## scaffold's poles and boards, a pallet of bricks, its sign.
func _site() -> void:
	_base("site")
	var brick := Color("b5553a")
	var mortar_gap := 0.03
	for row in 5:   # a running bond: each row shifted by half a brick
		var y := 0.06 + row * 0.3
		var shift := 0.4 if row % 2 == 1 else 0.0
		var x := -11.3 + shift
		while x + 0.8 <= -8.0 + 0.01:
			_box("site", Vector3(x, y, 3.3), Vector3(x + 0.8 - mortar_gap, y + 0.3 - mortar_gap, 3.7), brick, false)
			x += 0.8
	_box("site", Vector3(-11.3, 0.06, 3.3), Vector3(-8.1, 1.5, 3.7), brick.darkened(0.2))   # the wall's body (solid)
	for p: Vector2 in [Vector2(-11.4, 2.4), Vector2(-8.1, 2.4), Vector2(-11.4, 4.4), Vector2(-8.1, 4.4)]:
		_box("site", Vector3(p.x - 0.05, 0.06, p.y - 0.05), Vector3(p.x + 0.05, 2.6, p.y + 0.05), Color("9aa3ad"), false)
	_box("site", Vector3(-11.5, 2.0, 2.3), Vector3(-8.0, 2.08, 4.5), Color("c9a46a"), false)   # the scaffold's boards
	_box("site", Vector3(-10.2, 0.06, 4.6), Vector3(-9.3, 0.5, 5.2), Color("8a5a34"), false)   # a pallet...
	_box("site", Vector3(-10.1, 0.5, 4.7), Vector3(-9.4, 0.85, 5.1), brick, false)   # ...of bricks
	_sign("site", Vector3(-9.5, 3.1, 5.0))


## Owner #118 (Life L3a): the practice pool: a white rim round blue water, a float on its post, a lifeguard's flags.
func _pool() -> void:
	_base("pool")
	_box("pool", Vector3(3.6, 0.06, 2.6), Vector3(7.4, 0.35, 6.4), WHITE)   # the rim (solid: never a fall in)
	_box("pool", Vector3(3.9, 0.35, 2.9), Vector3(7.1, 0.37, 6.1), Color("5aa8e6"), false)   # the water's face
	_box("pool", Vector3(4.2, 0.35, 2.5), Vector3(4.3, 1.5, 2.6), WHITE)   # the float's post...
	_box("pool", Vector3(4.0, 1.0, 2.45), Vector3(4.5, 1.4, 2.5), Color("ff7a2e"), false)   # ...and its float
	_box("pool", Vector3(7.0, 0.35, 2.7), Vector3(7.08, 2.2, 2.78), Color("3b3f4a"), false)   # the flag's pole
	_box("pool", Vector3(7.08, 1.95, 2.72), Vector3(7.6, 2.2, 2.76), Color("e8544e"), false)
	_box("pool", Vector3(7.08, 1.7, 2.72), Vector3(7.6, 1.95, 2.76), Color("ffd23f"), false)
	_sign("pool", Vector3(5.5, 2.8, 2.6))


## Owner #118 (Life L3a): the poisons cupboard's little house: white, a big red-diamond warning sign, a locked door.
func _cupboard() -> void:
	_base("cupboard")
	_box("cupboard", Vector3(10.9, 0.06, -6.5), Vector3(12.5, 2.6, -1.5), Color("f4f6f8"))
	_box("cupboard", Vector3(10.8, 2.6, -6.6), Vector3(12.6, 2.8, -1.4), Color("6b7a99"), false)
	_box("cupboard", Vector3(11.3, 0.06, -1.53), Vector3(12.1, 1.9, -1.47), Color("7fb8d6"), false)   # its door
	_box("cupboard", Vector3(11.6, 1.0, -1.56), Vector3(11.8, 1.1, -1.44), Color("3fbf5a"), false)   # the child lock
	_box("cupboard", Vector3(11.45, 2.0, -1.53), Vector3(11.95, 2.5, -1.47), Color("e8544e"), false)   # the warning sign
	_box("cupboard", Vector3(11.55, 2.1, -1.55), Vector3(11.85, 2.4, -1.45), WHITE, false)
	_sign("cupboard", Vector3(11.7, 3.4, -1.3))


## Owner #118 (Life L3a): the weather hut: a sturdy wooden hut with a strong table inside its open front, a wind vane and
## a little rain cloud on its roof.
func _hut() -> void:
	_base("hut")
	_box("hut", Vector3(-7.5, 0.06, 4.6), Vector3(-5.5, 2.4, 6.5), Color("c9a46a"))   # its back half (solid)
	_box("hut", Vector3(-7.5, 0.06, 2.6), Vector3(-7.4, 2.4, 4.6), Color("c9a46a"), false)   # the open front's sides
	_box("hut", Vector3(-5.6, 0.06, 2.6), Vector3(-5.5, 2.4, 4.6), Color("c9a46a"), false)
	_box("hut", Vector3(-7.7, 2.4, 2.4), Vector3(-5.3, 2.6, 6.7), Color("8a5a34"), false)   # the roof
	_box("hut", Vector3(-7.0, 0.75, 3.4), Vector3(-6.0, 0.82, 4.2), Color("a8642a"), false)   # the strong table
	for x: float in [-6.9, -6.1]:
		_box("hut", Vector3(x, 0.06, 3.5), Vector3(x + 0.08, 0.75, 3.58), Color("8a5a34"), false)
	_box("hut", Vector3(-6.55, 2.6, 4.5), Vector3(-6.45, 3.4, 4.6), Color("3b3f4a"), false)   # the wind vane
	_box("hut", Vector3(-6.9, 3.3, 4.52), Vector3(-6.1, 3.38, 4.58), Color("e8544e"), false)
	_box("hut", Vector3(-7.3, 2.75, 5.4), Vector3(-6.3, 3.2, 6.2), Color(0.62, 0.66, 0.74), false)   # a little cloud
	_sign("hut", Vector3(-6.5, 3.8, 2.6))


## Life L3b (owner #118, #115): the second row, nearest the spawn, every front facing it: the power hut with its fuse box
## and a small yellow sign (Electricity Safety), the animal corner's kennel and a friendly dog (Safe with Animals), the
## first aid hut with its green cross (Medical Emergencies), and Success S2's four: the goal board on its posts with a
## calendar and a saving jar, the striped talk tent with two stools, the village board with picture cards and a bench, the
## little story stage with its curtains and a star.
func _second_row() -> void:
	# the power hut
	_base("power")
	_box("power", Vector3(-12.4, 0.06, 9.4), Vector3(-9.6, 2.4, 12.4), Color("dfe3ea"))
	_box("power", Vector3(-12.6, 2.4, 9.2), Vector3(-9.4, 2.6, 12.6), Color("6b7a99"), false)
	_box("power", Vector3(-11.5, 0.06, 12.4), Vector3(-10.7, 2.0, 12.46), Color("8a5a34"), false)   # its door
	_box("power", Vector3(-10.3, 1.2, 12.4), Vector3(-9.9, 1.55, 12.47), WHITE, false)   # the fuse box
	_box("power", Vector3(-11.35, 2.05, 12.4), Vector3(-10.85, 2.35, 12.47), Color("ffd23f"), false)   # the yellow sign
	_box("power", Vector3(-11.15, 2.1, 12.47), Vector3(-11.05, 2.3, 12.5), Color("1f2a4a"), false)
	_box("power", Vector3(-10.0, 2.6, 10.8), Vector3(-9.9, 3.8, 10.9), Color("8a5a34"), false)   # a little pole and its line
	_box("power", Vector3(-12.3, 3.7, 10.83), Vector3(-9.9, 3.73, 10.87), Color("1f2a4a"), false)
	_sign("power", Vector3(-11.1, 3.4, 12.7))
	# the animal corner: a kennel and a friendly dog
	_base("pets")
	_box("pets", Vector3(-8.9, 0.06, 9.5), Vector3(-6.1, 2.0, 12.0), Color("c0563a"))
	_box("pets", Vector3(-9.1, 2.0, 9.3), Vector3(-5.9, 2.25, 12.2), Color("8a5a34"), false)
	_box("pets", Vector3(-7.8, 0.06, 12.0), Vector3(-7.0, 1.4, 12.06), Color("4a3a2a"), false)   # its round-ish door
	var coat := Color("c98a4a")
	_box("pets", Vector3(-6.75, 0.3, 12.1), Vector3(-6.25, 0.5, 12.32), coat, false)   # the dog's body...
	_box("pets", Vector3(-6.3, 0.45, 12.12), Vector3(-6.1, 0.63, 12.3), coat.lightened(0.1), false)   # ...its head
	for x: float in [-6.7, -6.35]:
		_box("pets", Vector3(x, 0.06, 12.15), Vector3(x + 0.06, 0.3, 12.27), coat.darkened(0.1), false)
	_box("pets", Vector3(-6.85, 0.42, 12.18), Vector3(-6.75, 0.6, 12.24), coat.darkened(0.15), false)   # a low, relaxed tail
	_sign("pets", Vector3(-7.4, 3.0, 12.6))
	# the first aid hut
	_base("firstaid")
	_box("firstaid", Vector3(-4.9, 0.06, 9.4), Vector3(-3.1, 2.4, 12.4), WHITE)
	_box("firstaid", Vector3(-5.1, 2.4, 9.2), Vector3(-2.9, 2.6, 12.6), Color("3fbf5a"), false)
	_box("firstaid", Vector3(-4.1, 0.06, 12.4), Vector3(-3.3, 2.0, 12.46), Color("9fd8ff"), false)
	_box("firstaid", Vector3(-4.7, 1.6, 12.4), Vector3(-4.3, 1.75, 12.47), Color("3fbf5a"), false)   # the green cross
	_box("firstaid", Vector3(-4.575, 1.475, 12.4), Vector3(-4.425, 1.875, 12.47), Color("3fbf5a"), false)
	_sign("firstaid", Vector3(-3.7, 3.4, 12.7))
	# the goal board, its calendar and the saving jar
	_base("goals")
	for x: float in [-0.85, 0.85]:
		_box("goals", Vector3(x - 0.05, 0.06, 11.9), Vector3(x + 0.05, 2.3, 12.0), Color("8a5a34"))
	_box("goals", Vector3(-0.9, 1.0, 12.0), Vector3(0.9, 2.2, 12.06), Color("f4efe2"), false)
	for i in 7:   # the week's calendar: seven squares, most of them ticked
		_box("goals", Vector3(-0.75 + i * 0.21, 1.15, 12.06), Vector3(-0.58 + i * 0.21, 1.32, 12.09),
			Color("3fbf5a") if i != 3 else Color("dfe3ea"), false)
	_box("goals", Vector3(-0.5, 1.5, 12.06), Vector3(0.5, 2.0, 12.09), Color("ffd23f"), false)   # the goal's picture
	_box("goals", Vector3(0.45, 0.06, 12.2), Vector3(0.75, 0.75, 12.5), Color("a8642a"))   # the jar's stand...
	_box("goals", Vector3(0.5, 0.75, 12.25), Vector3(0.7, 1.0, 12.45), Color(0.8, 0.9, 1.0, 0.6), false)   # ...and the jar
	_box("goals", Vector3(0.53, 0.76, 12.28), Vector3(0.67, 0.86, 12.42), Color("ffc93c"), false)
	_sign("goals", Vector3(0.0, 2.9, 12.4))
	# the talk tent
	_base("talk")
	for i in 6:
		var x := 3.1 + i * 0.3
		_box("talk", Vector3(x, 2.0, 9.4), Vector3(x + 0.3, 2.15, 12.2), Color("3a7be8") if i % 2 == 0 else WHITE, false)
	for c: Vector2 in [Vector2(3.15, 9.45), Vector2(4.85, 9.45), Vector2(3.15, 12.15), Vector2(4.85, 12.15)]:
		_box("talk", Vector3(c.x - 0.05, 0.06, c.y - 0.05), Vector3(c.x + 0.05, 2.0, c.y + 0.05), Color("6b4a2a"))
	_box("talk", Vector3(3.1, 0.06, 9.4), Vector3(4.9, 2.0, 9.5), Color("dfe7f5"), false)   # its back
	for x: float in [3.5, 4.5]:
		_box("talk", Vector3(x - 0.2, 0.06, 10.8), Vector3(x + 0.2, 0.45, 11.2), Color("e8b04a"))   # two stools
	_sign("talk", Vector3(3.7, 2.8, 12.5))
	# the village board and its bench
	_base("village")
	for x: float in [6.3, 8.7]:
		_box("village", Vector3(x - 0.05, 0.06, 10.4), Vector3(x + 0.05, 2.2, 10.5), Color("8a5a34"))
	_box("village", Vector3(6.2, 1.0, 10.5), Vector3(8.8, 2.1, 10.56), Color("c9a46a"), false)
	for i in 6:   # picture cards of the village's people
		_box("village", Vector3(6.4 + (i % 3) * 0.8, 1.15 + (i / 3) * 0.5, 10.56), Vector3(6.9 + (i % 3) * 0.8, 1.55 + (i / 3) * 0.5,
			10.59), [Color("e85a9a"), Color("5aa8e6"), Color("3fbf5a"), Color("ffd23f"), Color("9b7fd6"), Color("ff9d2e")][i], false)
	_box("village", Vector3(6.8, 0.06, 11.6), Vector3(8.2, 0.5, 12.0), Color("a8642a"))   # the bench
	_sign("village", Vector3(7.4, 2.8, 12.5))
	# the story stage
	_base("stage")
	_box("stage", Vector3(10.1, 0.06, 9.4), Vector3(11.9, 0.45, 12.2), Color("a8642a"))
	_box("stage", Vector3(10.1, 0.45, 9.4), Vector3(11.9, 2.4, 9.5), Color("7b5cd6"), false)   # its back curtain
	for x: float in [10.1, 11.6]:
		_box("stage", Vector3(x, 0.45, 9.5), Vector3(x + 0.3, 2.4, 9.8), Color("c0304a"), false)   # the side curtains
	_box("stage", Vector3(10.85, 1.9, 9.52), Vector3(11.15, 2.2, 9.55), Color("ffd23f"), false)   # a star
	_sign("stage", Vector3(11.1, 3.0, 12.5))


## Life L3c (owner #112, #118): the third row, in front of the second, every front facing the spawn: the little web café
## with its big play tablet on the front (Online City), the metro entrance with its red M and the two-line map (Find Your
## Way), the helper's house with its washing line and four recycling bins (Home Helper).
func _third_row() -> void:
	# the web café: a white kiosk, its big play tablet on the front with pretend app squares
	_base("online")
	_box("online", Vector3(-6.4, 0.06, 14.6), Vector3(-3.6, 2.3, 16.3), WHITE)
	_box("online", Vector3(-6.6, 2.3, 14.4), Vector3(-3.4, 2.5, 16.5), Color("3a7be8"), false)
	_box("online", Vector3(-5.6, 0.9, 16.3), Vector3(-4.4, 1.9, 16.36), Color("1f2a4a"), false)   # the tablet's frame
	_box("online", Vector3(-5.5, 1.0, 16.36), Vector3(-4.5, 1.8, 16.4), Color("9fd8ff"), false)   # its screen
	var apps := [Color("2fae4e"), Color("3a7be8"), Color("e0a400"), Color("e85a9a")]
	for i in 4:
		var x := -5.35 + (i % 2) * 0.5
		var y := 1.15 + (i / 2) * 0.35
		_box("online", Vector3(x, y, 16.4), Vector3(x + 0.3, y + 0.22, 16.43), apps[i], false)
	_box("online", Vector3(-3.95, 0.06, 16.0), Vector3(-3.6, 0.45, 16.4), Color("a8642a"), false)   # a little stool
	_sign("online", Vector3(-5.0, 3.0, 16.6))
	# the metro entrance: a low wall round the stairs down, a red M on its post, the two-line map
	_base("wayfinder")
	_box("wayfinder", Vector3(-1.4, 0.06, 14.6), Vector3(1.4, 0.9, 14.8), Color("9aa3ad"))
	_box("wayfinder", Vector3(-1.4, 0.06, 14.8), Vector3(-1.2, 0.9, 16.3), Color("9aa3ad"))
	_box("wayfinder", Vector3(1.2, 0.06, 14.8), Vector3(1.4, 0.9, 16.3), Color("9aa3ad"))
	_box("wayfinder", Vector3(-1.2, 0.0, 14.8), Vector3(1.2, 0.08, 16.0), Color("3b3f4a"), false)   # the way down
	for i in 4:
		_box("wayfinder", Vector3(-1.1, 0.08 - i * 0.02, 15.0 + i * 0.25), Vector3(1.1, 0.1 - i * 0.02, 15.2 + i * 0.25),
			Color("c9ced6"), false)
	_box("wayfinder", Vector3(1.55, 0.06, 16.1), Vector3(1.65, 2.4, 16.2), Color("3b3f4a"))   # the M's post
	_box("wayfinder", Vector3(1.35, 2.4, 16.1), Vector3(1.85, 2.9, 16.2), Color("e8544e"), false)
	_box("wayfinder", Vector3(1.45, 2.5, 16.2), Vector3(1.75, 2.8, 16.22), WHITE, false)
	_box("wayfinder", Vector3(-1.2, 0.9, 14.62), Vector3(0.2, 1.8, 14.66), WHITE, false)   # the map board
	_box("wayfinder", Vector3(-1.1, 1.33, 14.66), Vector3(0.1, 1.37, 14.68), Color("2fae4e"), false)   # the green line
	_box("wayfinder", Vector3(-0.52, 0.98, 14.66), Vector3(-0.48, 1.72, 14.68), Color("e8544e"), false)   # the red line
	_sign("wayfinder", Vector3(0.0, 3.2, 16.6))
	# the helper's house: yellow walls, a red roof, a washing line and four recycling bins
	_base("helper")
	_box("helper", Vector3(3.6, 0.06, 14.6), Vector3(6.4, 2.2, 15.6), Color("fbe9a8"))
	_box("helper", Vector3(3.4, 2.2, 14.4), Vector3(6.6, 2.5, 15.8), Color("c0563a"), false)
	_box("helper", Vector3(4.6, 0.06, 15.6), Vector3(5.4, 1.9, 15.66), Color("8a5a34"), false)   # its door
	for x: float in [3.7, 6.3]:   # the washing line's posts
		_box("helper", Vector3(x - 0.04, 0.06, 16.3), Vector3(x + 0.04, 1.8, 16.38), Color("6b4a2a"))
	_box("helper", Vector3(3.7, 1.75, 16.32), Vector3(6.3, 1.77, 16.36), Color("1f2a4a"), false)
	var clothes := [Color("e8544e"), WHITE, Color("3a7be8"), Color("ffd23f")]
	for i in 4:
		var x := 3.95 + i * 0.6
		_box("helper", Vector3(x, 1.3, 16.32), Vector3(x + 0.4, 1.74, 16.36), clothes[i], false)
	var bins := [Color("3a7be8"), Color("f2c230"), Color("2fae4e"), Color("8a5a34")]
	for i in 4:
		var x := 3.65 + i * 0.36
		_box("helper", Vector3(x, 0.06, 15.62), Vector3(x + 0.3, 0.6, 15.92), bins[i])
	_sign("helper", Vector3(5.0, 3.0, 16.6))

