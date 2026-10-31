class_name FarmBuilding
extends Node3D
## The Gold Farm (M3 Task 10): a small cosy red barn with white trim, a gold coin on its gable and a stone
## plinth, a yard in front of its door, and a field of wheat, carrots and pumpkins beside it, with 1-3 little
## farmers at work (FarmWorker). Not made of voxels, like Tilly's stall and the Theater: nobody can mine it for
## blocks, break it or stamp over it, and it looks the same in both styles. One shared mesh with WeaponModels'
## vertex-colour material (built once), a cached mesh of gold piles per cap level (a bigger barn holds more),
## and one static body on the world layer (walls with a doorway, a flat roof, a hay bale inside). Local space
## is FarmSite's: the centre cell's middle is the origin on the floor, the door looks down +Z.

const LAYER := 1
const SHOW_WORKERS_WITHIN := 72.0        # workers and crops beyond this are not drawn
const TAP_REACH := 8.0                  # a tap on the barn opens its panel from this close (eye to barn)

const RED := Color("c8312b")
const RED_DARK := Color("a02621")
const TRIM := Color("f4efe4")
const ROOF := Color("5a3a24")
const STONE := Color("8a8f99")
const SOIL := Color("6b4a2f")
const WHEAT := Color("e8c65a")
const LEAF := Color("4f9a3a")
const CARROT := Color("ee7b2a")
const PUMPKIN := Color("e9861f")
const HAY := Color("e3c160")
const GOLD := Color("ffd23f")
const GOLD_DARK := Color("d9a520")
const DOOR_DARK := Color("3b1f16")

const BARN_LO := Vector3(-4.5, 0.0, -3.5)   # the barn's outside (x, z) and floor
const BARN_HI := Vector3(0.5, 3.2, 1.5)     # ... its wall tops
const WALL := 0.3
const PEAK := 5.0
const DOOR_X := Vector2(-3.0, -1.0)
const DOOR_TOP := 2.4
const RIDGE_X := -2.0

static var _mesh: ArrayMesh
static var _gold_meshes := {}

var farm: Dictionary = {}
var workers: Array[FarmWorker] = []
var working := false
var _gold := MeshInstance3D.new()


## Stands the farm ({pos, facing, rate, cap}, FarmRules) with its workers.
func setup(f: Dictionary) -> void:
	name = "FarmBuilding"
	add_to_group(&"farms")
	var p: Vector3i = f.pos
	position = Vector3(p.x + 0.5, p.y, p.z + 0.5)
	rotation = Vector3(0, int(f.facing) * PI / 2.0, 0)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = shared_mesh()
	add_child(mesh)
	_gold.name = "Gold"
	add_child(_gold)
	var body := StaticBody3D.new()
	body.name = "Walls"
	body.collision_layer = LAYER
	body.collision_mask = 0
	for b: AABB in solid_boxes():
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = b.size
		shape.shape = box
		shape.position = b.get_center()
		body.add_child(shape)
	add_child(body)
	show_levels(f)


## The farm's levels changed (an upgrade): the workers and the gold piles follow.
func show_levels(f: Dictionary) -> void:
	farm = f
	_gold.mesh = gold_mesh(int(f.get("cap", 0)))
	var want := FarmRules.workers(int(f.get("rate", 0)))
	while workers.size() > want:
		workers.pop_back().free()
	while workers.size() < want:
		var w := FarmWorker.new()
		add_child(w)
		w.setup(workers.size())
		workers.append(w)
	set_working(working)


## Workers move only while a player is near (FarmDirector asks a few times a second).
func set_working(on: bool) -> void:
	working = on
	for w in workers:
		w.set_process(on)


## The barn a tap ray (from, unit dir) hits within TAP_REACH of `eye`, not behind a block
## (blocked(from, dir, distance) -> bool), or null.
static func find(tree: SceneTree, from: Vector3, dir: Vector3, eye: Vector3, blocked: Callable = Callable()) -> FarmBuilding:
	for n in tree.get_nodes_in_group(&"farms"):
		var b := n as FarmBuilding
		if b == null or b.is_queued_for_deletion() or not b.is_inside_tree():
			continue
		var d := b.ray_hit(from, dir)
		if d >= 0.0 and eye.distance_to(from + dir * d) <= TAP_REACH \
				and not (blocked.is_valid() and blocked.call(from, dir, d)):
			return b
	return null


## How far along a ray (world) it meets the barn, or -1.
func ray_hit(from: Vector3, dir: Vector3) -> float:
	var inv := global_transform.affine_inverse()
	var o := inv * from
	var d := inv.basis * dir
	var box := AABB(BARN_LO, Vector3(BARN_HI.x, PEAK, BARN_HI.z) - BARN_LO)
	var hit: Variant = box.intersects_ray(o, d)
	if hit == null:
		return -1.0
	return (hit as Vector3).distance_to(o)


## The solid parts (local AABBs): plinth, walls round the doorway, the lintel, a flat roof, a hay bale.
static func solid_boxes() -> Array[AABB]:
	var lo := BARN_LO
	var hi := BARN_HI
	return [
		_box(Vector3(lo.x, -1.0, lo.z), Vector3(hi.x, 0.0, hi.z)),                        # plinth
		_box(Vector3(lo.x, 0.0, lo.z), Vector3(hi.x, hi.y, lo.z + WALL)),                  # back wall
		_box(Vector3(lo.x, 0.0, lo.z + WALL), Vector3(lo.x + WALL, hi.y, hi.z - WALL)),    # left wall
		_box(Vector3(hi.x - WALL, 0.0, lo.z + WALL), Vector3(hi.x, hi.y, hi.z - WALL)),    # right wall
		_box(Vector3(lo.x, 0.0, hi.z - WALL), Vector3(DOOR_X.x, hi.y, hi.z)),              # front, left of the door
		_box(Vector3(DOOR_X.y, 0.0, hi.z - WALL), Vector3(hi.x, hi.y, hi.z)),              # front, right of the door
		_box(Vector3(DOOR_X.x, DOOR_TOP, hi.z - WALL), Vector3(DOOR_X.y, hi.y, hi.z)),     # over the door
		_box(Vector3(lo.x - 0.25, hi.y, lo.z - 0.25), Vector3(hi.x + 0.25, hi.y + 0.3, hi.z + 0.25)),   # roof
		_box(Vector3(lo.x + WALL, 0.0, lo.z + WALL), Vector3(lo.x + 1.5, 0.8, lo.z + 1.3)),  # hay bale
	]


static func shared_mesh() -> ArrayMesh:
	if _mesh == null:
		_mesh = _build_mesh()
	return _mesh


## Gold piles in the barn: one more with each cap level (a bigger barn holds more), made once per level.
static func gold_mesh(cap_level: int) -> ArrayMesh:
	var n := clampi(cap_level, 0, FarmRules.MAX_LEVEL) + 1
	if not _gold_meshes.has(n):
		var st := _begin()
		for i in n:
			var c := Vector3(-0.6 - (i % 2) * 0.9, 0.0, -2.6 + (i / 2) * 1.0)
			_add_box(st, AABB(c + Vector3(-0.35, 0, -0.35), Vector3(0.7, 0.18, 0.7)), GOLD_DARK)
			_add_box(st, AABB(c + Vector3(-0.25, 0.18, -0.25), Vector3(0.5, 0.14, 0.5)), GOLD)
			_add_box(st, AABB(c + Vector3(-0.12, 0.32, -0.12), Vector3(0.24, 0.1, 0.24)), GOLD)
		_gold_meshes[n] = st.commit()
	return _gold_meshes[n]


static func _box(a: Vector3, b: Vector3) -> AABB:
	return AABB(a, b - a)


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(WeaponModels.material())
	return st


static func _build_mesh() -> ArrayMesh:
	var st := _begin()
	var boxes := solid_boxes()
	_add_box(st, boxes[0], STONE)
	for i in range(1, 7):
		_add_box(st, boxes[i], RED)
	_add_box(st, boxes[8], HAY)
	_add_box(st, _box(Vector3(BARN_LO.x + WALL, 0.0, BARN_LO.z + WALL), Vector3(BARN_HI.x - WALL, 0.03, BARN_HI.z - WALL)),
		Color("9c7a4c"))   # the barn's plank floor
	_barn_trim(st)
	_roof(st)
	_field(st)
	_sign(st)
	return st.commit()


## White corner posts and trim, the dark doorway's X brace, the gold coin on the gable.
static func _barn_trim(st: SurfaceTool) -> void:
	var lo := BARN_LO
	var hi := BARN_HI
	for x: float in [lo.x - 0.03, hi.x - 0.22]:
		for z: float in [lo.z - 0.03, hi.z - 0.22]:
			_add_box(st, AABB(Vector3(x, 0.0, z), Vector3(0.25, hi.y, 0.25)), TRIM)
	_add_box(st, AABB(Vector3(lo.x - 0.03, hi.y - 0.2, hi.z - 0.02), Vector3(hi.x - lo.x + 0.06, 0.2, 0.08)), TRIM)
	_add_box(st, AABB(Vector3(DOOR_X.x - 0.15, 0.0, hi.z - 0.02), Vector3(0.15, DOOR_TOP + 0.15, 0.08)), TRIM)
	_add_box(st, AABB(Vector3(DOOR_X.y, 0.0, hi.z - 0.02), Vector3(0.15, DOOR_TOP + 0.15, 0.08)), TRIM)
	_add_box(st, AABB(Vector3(DOOR_X.x - 0.15, DOOR_TOP, hi.z - 0.02), Vector3(DOOR_X.y - DOOR_X.x + 0.3, 0.15, 0.08)), TRIM)
	# The open barn doors, folded back against the front wall on each side.
	_add_box(st, AABB(Vector3(DOOR_X.x - 1.1, 0.0, hi.z), Vector3(0.95, DOOR_TOP - 0.1, 0.08)), RED_DARK)
	_add_box(st, AABB(Vector3(DOOR_X.y + 0.15, 0.0, hi.z), Vector3(0.95, DOOR_TOP - 0.1, 0.08)), RED_DARK)
	for d: float in [DOOR_X.x - 1.1, DOOR_X.y + 0.15]:
		_add_box(st, AABB(Vector3(d, 0.05, hi.z + 0.08), Vector3(0.95, 0.12, 0.04)), TRIM)
		_add_box(st, AABB(Vector3(d, DOOR_TOP - 0.3, hi.z + 0.08), Vector3(0.95, 0.12, 0.04)), TRIM)
	# The gables: red triangles front and back under the roof, seen from outside and from inside.
	for z: float in [lo.z, hi.z]:
		for n: Vector3 in [Vector3.BACK, Vector3.FORWARD]:
			_add_tri(st, Vector3(lo.x, hi.y, z), Vector3(hi.x, hi.y, z), Vector3(RIDGE_X, PEAK, z), n, RED)
	# A hay door and the gold coin on the front gable.
	_add_box(st, AABB(Vector3(RIDGE_X - 0.45, hi.y + 0.1, hi.z), Vector3(0.9, 0.7, 0.05)), DOOR_DARK)
	_coin(st, Vector3(RIDGE_X, hi.y + 1.25, hi.z + 0.05), 0.42)


## The roof: two dark slabs meeting at the ridge (along z), overhanging a little.
static func _roof(st: SurfaceTool) -> void:
	var half := (BARN_HI.x - BARN_LO.x) * 0.5 + 0.25
	var rise := PEAK - BARN_HI.y
	var angle := atan2(rise, half)
	var length := sqrt(half * half + rise * rise) + 0.15
	var depth := BARN_HI.z - BARN_LO.z + 0.5
	var mid_z := (BARN_HI.z + BARN_LO.z) * 0.5
	for side: float in [-1.0, 1.0]:
		var center := Vector3(RIDGE_X + side * half * 0.5, BARN_HI.y + rise * 0.5 + 0.1, mid_z)
		_add_box(st, AABB(-Vector3(length, 0.2, depth) * 0.5, Vector3(length, 0.2, depth)), ROOF,
			Transform3D(Basis(Vector3.BACK, -side * angle), center))
	_add_box(st, AABB(Vector3(RIDGE_X - 0.15, PEAK - 0.05, BARN_LO.z - 0.25), Vector3(0.3, 0.2, depth)), TRIM)


## Four rows of crops on raised soil (wheat, carrots, wheat, pumpkins), with a soil slab under the field that
## fills a dip.
static func _field(st: SurfaceTool) -> void:
	var hz := FarmSite.HALF_D + 0.5
	_add_box(st, _box(Vector3(0.5, -1.0, -hz), Vector3(FarmSite.HALF_W + 0.5, -0.02, hz)), SOIL)
	for row in 4:
		var x := 1.0 + row
		_add_box(st, _box(Vector3(x - 0.3, 0.0, -hz + 0.2), Vector3(x + 0.3, 0.12, hz - 0.2)), SOIL)
		for i in 7:
			var z := -3.0 + i
			match row:
				1:
					_add_box(st, AABB(Vector3(x - 0.08, 0.12, z - 0.08), Vector3(0.16, 0.1, 0.16)), CARROT)
					_add_box(st, AABB(Vector3(x - 0.12, 0.22, z - 0.05), Vector3(0.24, 0.3, 0.1)), LEAF)
				3:
					_add_box(st, AABB(Vector3(x - 0.24, 0.12, z - 0.24), Vector3(0.48, 0.36, 0.48)), PUMPKIN)
					_add_box(st, AABB(Vector3(x - 0.04, 0.48, z - 0.04), Vector3(0.08, 0.1, 0.08)), LEAF)
				_:
					_add_box(st, AABB(Vector3(x - 0.06, 0.12, z - 0.06), Vector3(0.12, 0.55, 0.12)), LEAF.lerp(WHEAT, 0.6))
					_add_box(st, AABB(Vector3(x - 0.1, 0.62, z - 0.1), Vector3(0.2, 0.26, 0.2)), WHEAT)


## A little post by the yard with a coin sign.
static func _sign(st: SurfaceTool) -> void:
	var at := Vector3(0.1, 0.0, FarmSite.HALF_D + 0.2)
	_add_box(st, AABB(at + Vector3(-0.07, 0, -0.07), Vector3(0.14, 1.4, 0.14)), Color("8a5a2e"))
	_add_box(st, AABB(at + Vector3(-0.45, 1.1, -0.04), Vector3(0.9, 0.55, 0.08)), Color("b07a45"))
	_coin(st, at + Vector3(0, 1.375, 0.06), 0.2)


## A gold coin facing +Z: a dark rim, a bright face, a raised middle.
static func _coin(st: SurfaceTool, center: Vector3, r: float) -> void:
	_add_box(st, AABB(center + Vector3(-r, -r, -0.03), Vector3(2 * r, 2 * r, 0.06)), GOLD_DARK,
		Transform3D(Basis(Vector3.BACK, PI / 4.0), Vector3.ZERO), center)
	_add_box(st, AABB(center + Vector3(-r * 0.85, -r * 0.85, -0.02), Vector3(1.7 * r, 1.7 * r, 0.08)), GOLD)
	_add_box(st, AABB(center + Vector3(-r * 0.35, -r * 0.35, 0.0), Vector3(0.7 * r, 0.7 * r, 0.08)), GOLD_DARK)


## Six outward faces of `b` (optionally moved by `xform` about `pivot`), coloured `c`, sides a little darker.
static func _add_box(st: SurfaceTool, b: AABB, c: Color, xform := Transform3D.IDENTITY, pivot := Vector3.ZERO) -> void:
	var lo := b.position
	var hi := b.end
	var faces := [
		[Vector3.UP, [Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z)], 1.0],
		[Vector3.DOWN, [Vector3(lo.x, lo.y, hi.z), Vector3(hi.x, lo.y, hi.z), Vector3(hi.x, lo.y, lo.z), Vector3(lo.x, lo.y, lo.z)], 0.6],
		[Vector3.FORWARD, [Vector3(hi.x, lo.y, lo.z), Vector3(lo.x, lo.y, lo.z), Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z)], 0.85],
		[Vector3.BACK, [Vector3(lo.x, lo.y, hi.z), Vector3(hi.x, lo.y, hi.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z)], 0.85],
		[Vector3.LEFT, [Vector3(lo.x, lo.y, lo.z), Vector3(lo.x, lo.y, hi.z), Vector3(lo.x, hi.y, hi.z), Vector3(lo.x, hi.y, lo.z)], 0.75],
		[Vector3.RIGHT, [Vector3(hi.x, lo.y, hi.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z)], 0.75],
	]
	for f: Array in faces:
		var q: Array = []
		for v: Vector3 in f[1]:
			q.append(pivot + xform * (v - pivot))
		var n: Vector3 = (xform.basis * (f[0] as Vector3)).normalized()
		var shade: Color = c * float(f[2])
		shade.a = 1.0
		_emit(st, q, n, shade)


## One flat triangle facing `n`.
static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, color: Color) -> void:
	_emit(st, [a, b, c], n, color * 0.85)


## Emits a quad (4 corners) or a triangle wound so its front faces `n` (Godot's front faces wind clockwise).
static func _emit(st: SurfaceTool, q: Array, n: Vector3, c: Color) -> void:
	var flip: bool = ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0]).dot(n) > 0.0
	var order: Array = [0, 1, 2]
	if q.size() == 4:
		order = [0, 2, 1, 0, 3, 2] if flip else [0, 1, 2, 0, 2, 3]
	elif flip:
		order = [0, 2, 1]
	var shade := c
	shade.a = 1.0
	for i: int in order:
		st.set_color(shade)
		st.set_normal(n)
		st.add_vertex(q[i])
