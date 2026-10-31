class_name TheaterBuilding
extends Node3D
## The Shorts Theater's building (M3 Task 17): a small cinema of 9 × 9 blocks, with cream walls, a
## purple roof, a red "THEATER" sign with bulbs over a 3-block-wide door, seats and a dark screen
## inside, on a stone plinth. It is not made of voxels, so nobody can break it and the kill-switch
## can leave it out. One shared mesh with vertex colours (one draw call, built once) and one static
## body on the world layer; the room itself is free, and walking in opens the video panel
## (TheaterDirector). Local space: the floor's centre is the origin, the door looks down +Z.

const LAYER := 1
const WALL := Color("f4e3b2")
const TRIM := Color("7b4bd6")
const SIGN := Color("d9463b")
const BULB := Color("ffd23f")
const STONE := Color("8a8f99")
const CARPET := Color("b3263a")
const SCREEN := Color("15151f")
const SEAT := Color("8e1d2c")

const _H := TheaterSite.HALF + 0.5          # the outer walls' faces
const _IN := TheaterSite.HALF - 0.5         # the room's walls
const _TOP := float(TheaterSite.WALL_HEIGHT)
const _DOOR_HALF := 1.5
const _DOOR_TOP := 4.0

static var _mesh: ArrayMesh
static var _material: StandardMaterial3D


## The solid parts (local AABBs): plinth, walls around the door, lintel, roof.
static func solid_boxes() -> Array[AABB]:
	return [
		_box(Vector3(-_H, -TheaterSite.PLINTH_DEPTH, -_H), Vector3(_H, 0.0, _H)),   # plinth and floor
		_box(Vector3(-_H, 0.0, -_H), Vector3(_H, _TOP, -_IN)),                 # back wall
		_box(Vector3(-_H, 0.0, -_IN), Vector3(-_IN, _TOP, _IN)),               # left wall
		_box(Vector3(_IN, 0.0, -_IN), Vector3(_H, _TOP, _IN)),                 # right wall
		_box(Vector3(-_H, 0.0, _IN), Vector3(-_DOOR_HALF, _TOP, _H)),          # front, left of the door
		_box(Vector3(_DOOR_HALF, 0.0, _IN), Vector3(_H, _TOP, _H)),            # front, right of the door
		_box(Vector3(-_DOOR_HALF, _DOOR_TOP, _IN), Vector3(_DOOR_HALF, _TOP, _H)),   # over the door
		_box(Vector3(-_H - 0.5, _TOP, -_H - 0.5), Vector3(_H + 0.5, _TOP + 1.0, _H + 0.5)),   # roof
	]


static func shared_mesh() -> ArrayMesh:
	if _mesh == null:
		_mesh = _build_mesh()
	return _mesh


## Stands the building on `site` ({pos: Vector3i, facing}, TheaterSite).
func setup(site: Dictionary) -> void:
	var p: Vector3i = site.pos
	position = Vector3(p.x + 0.5, p.y, p.z + 0.5)
	rotation = Vector3(0, int(site.facing) * PI / 2.0, 0)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = shared_mesh()
	add_child(mesh)
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
	_add_label("THEATER", Vector3(0, 4.9, _H + 0.32), 0.022, BULB)
	_add_label("EasyCraft TV", Vector3(0, 3.1, -_IN + 0.12), 0.012, Color.WHITE)


func _add_label(text: String, pos: Vector3, pixel: float, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.pixel_size = pixel
	l.font_size = 64
	l.outline_size = 12
	l.modulate = color
	l.outline_modulate = Color(0.1, 0.05, 0.1)
	add_child(l)


static func _box(a: Vector3, b: Vector3) -> AABB:
	return AABB(a, b - a)


static func _build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var parts: Array = [
		[solid_boxes()[0], STONE],
	]
	for i in range(1, 7):
		parts.append([solid_boxes()[i], WALL])
	parts.append([solid_boxes()[7], TRIM])
	parts.append([_box(Vector3(-_IN, 0.0, -_IN), Vector3(_IN, 0.04, _IN)), CARPET])
	parts.append([_box(Vector3(-2.6, 1.3, -_IN), Vector3(2.6, 4.5, -_IN + 0.08)), SCREEN])
	parts.append([_box(Vector3(-2.6, 4.2, _H), Vector3(2.6, 5.6, _H + 0.3)), SIGN])            # the sign
	parts.append([_box(Vector3(-_DOOR_HALF - 0.2, 0.0, _H), Vector3(-_DOOR_HALF, _DOOR_TOP, _H + 0.12)), TRIM])
	parts.append([_box(Vector3(_DOOR_HALF, 0.0, _H), Vector3(_DOOR_HALF + 0.2, _DOOR_TOP, _H + 0.12)), TRIM])
	for i in 6:
		var x := -2.3 + i * 0.92
		parts.append([_box(Vector3(x - 0.1, 5.62, _H + 0.05), Vector3(x + 0.1, 5.82, _H + 0.25)), BULB])
		parts.append([_box(Vector3(x - 0.1, 3.98, _H + 0.05), Vector3(x + 0.1, 4.18, _H + 0.25)), BULB])
	for row in 2:
		for i in 5:
			var x := -2.0 + i
			var z := 0.4 + row * 1.6
			parts.append([_box(Vector3(x - 0.38, 0.0, z - 0.3), Vector3(x + 0.38, 0.5, z + 0.3)), SEAT])
			parts.append([_box(Vector3(x - 0.38, 0.5, z + 0.18), Vector3(x + 0.38, 1.1, z + 0.3)), SEAT])
	for part: Array in parts:
		_add_box(st, part[0], part[1])
	st.set_material(_shared_material())
	return st.commit()


static func _shared_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.9
	return _material


## Six outward faces of `b`, coloured `c` (the sides a little darker, like the blocks).
static func _add_box(st: SurfaceTool, b: AABB, c: Color) -> void:
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
		var n: Vector3 = f[0]
		var q: Array = f[1]
		var shade: Color = c * float(f[2])
		shade.a = 1.0
		# Godot's front faces wind clockwise as seen from outside.
		var order: Array[int] = [0, 1, 2, 0, 2, 3]
		if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for i: int in order:
			st.set_color(shade)
			st.set_normal(n)
			st.add_vertex(q[i])
