class_name BoxBatch
extends MeshInstance3D
## Owner #116 (Real Builder): many boxes (bricks, their mortar, tiles) drawn as one mesh in one colour: a whole house is
## a few draws, not hundreds (the Quest's budget: VR P5, about 100 in play). Built in code from {centre, size, yaw}
## boxes, lit with the practice rooms' warmed material (LifeRoomKit.material), no shadows.

var colour := Color.WHITE
var count := 0


func _init(batch_name: String = "Boxes", batch_colour: Color = Color.WHITE) -> void:
	name = batch_name
	colour = batch_colour
	material_override = LifeRoomKit.material(colour)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Every box: {centre (Vector3, the parent's space), size (Vector3), yaw (radians round +Y), tilt (radians round its own
## X, a roof's slope), grow (Vector3 added to its size: a mortar joint)}.
func set_boxes(boxes: Array) -> void:
	count = boxes.size()
	if boxes.is_empty():
		mesh = null
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b: Variant in boxes:
		var d: Dictionary = b
		var size: Vector3 = (d.size as Vector3) + (d.get("grow", Vector3.ZERO) as Vector3)
		var basis := Basis(Vector3.UP, float(d.get("yaw", 0.0))) * Basis(Vector3.RIGHT, float(d.get("tilt", 0.0)))
		_box(st, Transform3D(basis, d.centre as Vector3), size * 0.5)
	mesh = st.commit()


## One box's six faces, outward normals.
static func _box(st: SurfaceTool, t: Transform3D, h: Vector3) -> void:
	var faces := [
		[Vector3.RIGHT, Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)],
		[Vector3.LEFT, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3.UP, Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3.DOWN, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)],
		[Vector3.BACK, Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)],
		[Vector3.FORWARD, Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
	]
	for f: Array in faces:
		var n: Vector3 = t.basis * (f[0] as Vector3)
		var p: Array = [t * (f[1] as Vector3), t * (f[2] as Vector3), t * (f[3] as Vector3), t * (f[4] as Vector3)]
		for i: int in [0, 2, 1, 0, 3, 2]:
			st.set_normal(n)
			st.add_vertex(p[i])
