class_name BuildOutline
extends MeshInstance3D
## The glow around a picked build (M4 Wave 3, agent I; BuildPicker, and M3 Task 8's Build-and-Wear):
## a thin golden skin over every face of the build that is open to the air, one mesh, drawn with ONE
## shared material for every outline in the game (unshaded, see-through, gently pulsing). Also the
## frame of an area (the showcase): its twelve edges as thin bars in the same material.

const LIFT := 0.03            # the skin floats this far off the faces
const BAR := 0.08             # an area frame's bar thickness
const _SIDES: Array[Vector3i] = [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP, Vector3i.DOWN, Vector3i.BACK, Vector3i.FORWARD]

static var _material: StandardMaterial3D
static var _tween: Tween


## The one material every outline shares.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.albedo_color = Color(1.0, 0.86, 0.25, 0.42)
		_material.no_depth_test = false
		_material.render_priority = 1
	return _material


func _ready() -> void:
	material_override = material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pulse()


## Shows the outline of these blocks ({world cell: id}); an empty dictionary hides it. How many faces.
func show_blocks(blocks: Dictionary) -> int:
	var verts := PackedVector3Array()
	var faces := 0
	for cell: Vector3i in blocks:
		for side in _SIDES:
			if blocks.has(cell + side):
				continue
			_face(verts, Vector3(cell), side)
			faces += 1
	_set_mesh(verts)
	return faces


## Shows the frame of the box [origin, origin + size) (a showcase's area).
func show_box(origin: Vector3i, size: Vector3i) -> void:
	var verts := PackedVector3Array()
	var o := Vector3(origin)
	var s := Vector3(size)
	for a in 3:
		var b := (a + 1) % 3
		var c := (a + 2) % 3
		for i in 2:
			for j in 2:
				var start := o
				start[b] += s[b] * i
				start[c] += s[c] * j
				var end := start
				end[a] += s[a]
				_bar(verts, start, end, a)
	_set_mesh(verts)


func clear() -> void:
	mesh = null


func _set_mesh(verts: PackedVector3Array) -> void:
	if verts.is_empty():
		mesh = null
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = m


## One face of the cell at `c` on `side`, lifted off it.
static func _face(verts: PackedVector3Array, c: Vector3, side: Vector3i) -> void:
	var n := Vector3(side)
	var axis := 0 if side.x != 0 else (1 if side.y != 0 else 2)
	var u := Vector3.ZERO
	var v := Vector3.ZERO
	u[(axis + 1) % 3] = 1.0
	v[(axis + 2) % 3] = 1.0
	var base := c + Vector3(0.5, 0.5, 0.5) + n * (0.5 + LIFT) - (u + v) * 0.5
	var p0 := base
	var p1 := base + u
	var p2 := base + u + v
	var p3 := base + v
	verts.append_array([p0, p1, p2, p0, p2, p3])


## A thin square bar from `a` to `b` along axis `axis`.
static func _bar(verts: PackedVector3Array, a: Vector3, b: Vector3, axis: int) -> void:
	var u := Vector3.ZERO
	var v := Vector3.ZERO
	u[(axis + 1) % 3] = BAR
	v[(axis + 2) % 3] = BAR
	var corners := [a - u - v, a + u - v, a + u + v, a - u + v]
	var d := b - a
	for k in 4:
		var p: Vector3 = corners[k]
		var q: Vector3 = corners[(k + 1) % 4]
		verts.append_array([p, q, q + d, p, q + d, p + d])


## One gentle pulse for the shared material (every outline breathes together).
func _pulse() -> void:
	if _tween != null and _tween.is_valid():
		return
	_tween = create_tween().set_loops()
	_tween.tween_property(_material, "albedo_color:a", 0.62, 0.6).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_material, "albedo_color:a", 0.3, 0.6).set_trans(Tween.TRANS_SINE)
