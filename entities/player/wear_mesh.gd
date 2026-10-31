class_name WearMesh
extends RefCounted
## Blocks as small meshes (M3 Task 8): a built wearable (Build-and-Wear: HAT, BACKPACK, WINGS) baked into one small
## mesh, and single blocks for Build Rewind's preview. Only the faces open to the air are made; each face shows
## its block's own tile and uses the block's own material from the shared block library (the page materials), so
## a wearable looks like its blocks in both styles and follows the style switch by itself, and no material is ever
## made for one. Meshes are cached (per code and side, per block id) for the whole game.
##
## A wearable's code keeps its blocks as the child saw them (WearRules): x to the child's right, z away from them,
## so its front is z = 0. Worn: a hat sits on the head with its front forward; a backpack hangs on the back with
## its front facing out behind; wings are the build as the right wing and its mirror image as the left (nodes "R"
## and "L", which AvatarModel flaps).

const HAT_SCALE := 0.1       # five blocks are the blocky head's width
const BACK_SCALE := 0.08
const WING_SCALE := 0.1
const HEAD_TOP := 0.25       # the blocky head's top in its anchor's space (AvatarParts)
const WING_GAP := 0.04       # between the back and a wing's inner edge
const SHADE := {Vector3i.UP: 1.0, Vector3i.DOWN: 0.55, Vector3i.LEFT: 0.8, Vector3i.RIGHT: 0.8,
	Vector3i.FORWARD: 0.9, Vector3i.BACK: 0.9}
const _SIDES: Array[Vector3i] = [Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]

static var _meshes := {}      # "slot|side|code" -> ArrayMesh
static var _cubes := {}       # block id -> ArrayMesh
static var _faces := {}       # Vector3i normal -> [4 corners (unit cube around 0), 6 indices]


## The wearable of `code` in `slot`, as a node for its anchor (null for a bad code or slot). Wings: "R" and "L".
static func build(slot: StringName, code: String) -> Node3D:
	if not WearRules.is_slot(slot) or not WearRules.valid(code):
		return null
	var root := Node3D.new()
	root.name = "built_%s" % slot
	if slot == WearRules.WINGS:
		for side: String in ["R", "L"]:
			var wing := Node3D.new()
			wing.name = side
			root.add_child(wing)
			wing.add_child(_instance(mesh_for(slot, code, side == "L")))
	else:
		root.add_child(_instance(mesh_for(slot, code, false)))
	return root


## The cached mesh of a wearable (`left`: the mirrored left wing).
static func mesh_for(slot: StringName, code: String, left: bool) -> ArrayMesh:
	var key := "%s|%s|%s" % [slot, left, code]
	if _meshes.has(key):
		return _meshes[key]
	var blocks := WearRules.blocks_of(code)
	var size := Vector3i.ONE
	for p: Vector3i in blocks:
		size = size.max(p + Vector3i.ONE)
	var place := func(p: Vector3i) -> Vector3: return _worn(slot, p, size, left)
	var mesh := blocks_mesh(blocks, place, _scale(slot))
	_meshes[key] = mesh
	return mesh


## One block's whole cube (Build Rewind's preview), 1 m, from (0, 0, 0) to (1, 1, 1).
static func cube(id: int) -> ArrayMesh:
	if not _cubes.has(id):
		_cubes[id] = blocks_mesh({Vector3i.ZERO: id}, func(p: Vector3i) -> Vector3: return Vector3(p) + Vector3(0.5, 0.5, 0.5), 1.0)
	return _cubes[id]


## A mesh of `blocks` ({cell: id}): each block a cube of `scale` centred at place(cell), only the faces open to the
## air, one surface per material (the block library's). place() maps the cells without mirroring the cubes
## themselves: a face keeps its winding, and its normal follows the cell grid through place().
static func blocks_mesh(blocks: Dictionary, place: Callable, scale: float) -> ArrayMesh:
	var lib := WorldService.library()
	var surfaces := {}   # material -> {v, n, uv, c, i}
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		if id <= BlockIds.AIR or id >= lib.models.size():
			continue
		var model := lib.models[id] as VoxelBlockyModelCube
		if model == null:
			continue
		var mat := model.get_material_override(0)
		if not surfaces.has(mat):
			surfaces[mat] = {"v": [], "n": [], "uv": [], "c": [], "i": []}
		var centre: Vector3 = place.call(p)
		for side in _SIDES:
			if blocks.has(p + side):
				continue
			var out: Vector3 = place.call(p + side) - centre   # the face's direction where it is worn
			_face(surfaces[mat], _nearest_side(out), centre, scale, model)
	var mesh := ArrayMesh.new()
	for mat: Material in surfaces:
		var s: Dictionary = surfaces[mat]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(s.v)
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(s.n)
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(s.uv)
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray(s.c)
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(s.i)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	return mesh


static func mesh_count() -> int:
	return _meshes.size()


## Appends one face (normal n, a unit cube's face around `centre`, scaled) with its block's tile and shade.
static func _face(s: Dictionary, n: Vector3i, centre: Vector3, scale: float, model: VoxelBlockyModelCube) -> void:
	var f := _face_of(n)
	var side := VoxelBlockyModel.SIDE_POSITIVE_Y if n == Vector3i.UP else (VoxelBlockyModel.SIDE_NEGATIVE_Y
		if n == Vector3i.DOWN else VoxelBlockyModel.SIDE_POSITIVE_X)
	var tile := model.get_tile(side)
	var tiles := Vector2(model.atlas_size_in_tiles)
	var shade: float = SHADE[n]
	var base: int = (s.v as Array).size()
	var tangent := Vector3(n).cross(Vector3.UP) if n.y == 0 else Vector3.RIGHT
	for corner: Vector3 in f[0]:
		(s.v as Array).append(centre + corner * scale)
		(s.n as Array).append(Vector3(n))
		var u := tangent.dot(corner) + 0.5
		var v := (0.5 - corner.y) if n.y == 0 else (corner.z + 0.5)
		(s.uv as Array).append((Vector2(tile) + Vector2(clampf(u, 0.0, 1.0), clampf(v, 0.0, 1.0))) / tiles)
		(s.c as Array).append(Color(shade, shade, shade, 1.0))
	for i: int in f[1]:
		(s.i as Array).append(base + i)


## A unit cube's face with normal n (from BoxMesh, so its winding faces out): [4 corners, 6 indices].
static func _face_of(n: Vector3i) -> Array:
	if _faces.is_empty():
		var arrays := BoxMesh.new().get_mesh_arrays()
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for k in range(0, index.size(), 3):
			var side := Vector3i(normals[index[k]].round())
			if not _faces.has(side):
				_faces[side] = [[], [], {}]
			var face: Array = _faces[side]
			for j in 3:
				var vi := index[k + j]
				if not face[2].has(vi):
					face[2][vi] = (face[0] as Array).size()
					(face[0] as Array).append(verts[vi])
				(face[1] as Array).append(face[2][vi])
	return _faces[n]


static func _nearest_side(d: Vector3) -> Vector3i:
	var a := d.abs()
	if a.x >= a.y and a.x >= a.z:
		return Vector3i(signi(roundi(d.x * 1000.0)), 0, 0)
	if a.y >= a.z:
		return Vector3i(0, signi(roundi(d.y * 1000.0)), 0)
	return Vector3i(0, 0, signi(roundi(d.z * 1000.0)))


static func _scale(slot: StringName) -> float:
	match slot:
		WearRules.BACK:
			return BACK_SCALE
		WearRules.WINGS:
			return WING_SCALE
	return HAT_SCALE


## Where cell p of a build of `size` sits when worn in `slot` (its anchor's space).
static func _worn(slot: StringName, p: Vector3i, size: Vector3i, left: bool) -> Vector3:
	var s := _scale(slot)
	var c := Vector3(p) + Vector3(0.5, 0.5, 0.5)
	match slot:
		WearRules.BACK:   # the front faces out behind; the top at the shoulders, hanging down
			return Vector3(c.x - size.x * 0.5, c.y - size.y, size.z - c.z) * s
		WearRules.WINGS:   # the right wing reaches out along +X from the back, the left one along -X
			var x := WING_GAP + c.x * s
			return Vector3(-x if left else x, (c.y - size.y * 0.5) * s + 0.05, c.z * s + 0.02)
	# a hat: its front forward (-Z), standing on the top of the head
	return Vector3(-(c.x - size.x * 0.5) * s, c.y * s + HEAD_TOP, (c.z - size.z * 0.5) * s)


static func _instance(mesh: ArrayMesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # small pieces: no extra shadow pass (like AvatarParts)
	return mi
