class_name LaunchBuildings
extends Node3D
## The Launch Site's buildings (spec §21d.1): the service tower beside the pad (a lattice of orange and white steel with
## platforms and two short arms over the pad's stripes, never over its build square), Mission Control (a white building
## with a teal roof, a window band, a door facing the spawn and a dish on its roof) and the Mission Board in front of
## it (a big board on two posts, its face towards the spawn: walking up to it opens the board, LaunchDirector). Models,
## not voxels: nobody can break them. One shared mesh with vertex colours (one draw call, built once) and one static
## body on the world layer. Local space: the pad's middle cell's centre on the plaza's floor is the origin, +Z looks
## towards the spawn (LaunchSite's local cells: cell c spans c - 0.5 … c + 0.5).

const LAYER := 1
const WHITE := Color("f2f4f6")
const GREY := Color("c9ced6")
const ORANGE := Color("e8612c")
const TEAL := Color("139e9b")
const TEAL_DARK := Color("0c7876")
const WINDOW := Color("2d4f73")
const WINDOW_LIGHT := Color("8fd3ff")
const BOARD := Color("17324d")
const BOARD_EDGE := Color("ffd23f")
const DOOR := Color("5a6472")
const DISH := Color("e8ecf1")

const TOWER_HEIGHT := 24.0
const CONTROL_HEIGHT := 5.0

static var _mesh: ArrayMesh
static var _material: StandardMaterial3D


## The tower's corner posts' lows and highs (local AABB corners), in LaunchSite's cells.
static func _tower_box() -> AABB:
	var lo := Vector2(LaunchSite.TOWER_MIN) - Vector2(0.5, 0.5)
	var hi := Vector2(LaunchSite.TOWER_MAX) + Vector2(0.5, 0.5)
	return AABB(Vector3(lo.x, 0.0, lo.y), Vector3(hi.x - lo.x, TOWER_HEIGHT, hi.y - lo.y))


static func _control_box() -> AABB:
	var lo := Vector2(LaunchSite.CONTROL_MIN) - Vector2(0.5, 0.5)
	var hi := Vector2(LaunchSite.CONTROL_MAX) + Vector2(0.5, 0.5)
	return AABB(Vector3(lo.x, 0.0, lo.y), Vector3(hi.x - lo.x, CONTROL_HEIGHT, hi.y - lo.y))


static func _board_box() -> AABB:
	var b := LaunchSite.BOARD_AT
	return AABB(Vector3(b.x - 1.6, 1.3, b.y - 0.25), Vector3(3.2, 2.0, 0.25))


## The solid parts (local AABBs): the tower's four posts and its platforms, Mission Control, the board and its posts.
static func solid_boxes() -> Array[AABB]:
	var out: Array[AABB] = []
	var t := _tower_box()
	for corner: Vector2 in [Vector2(t.position.x, t.position.z), Vector2(t.end.x - 0.3, t.position.z),
			Vector2(t.position.x, t.end.z - 0.3), Vector2(t.end.x - 0.3, t.end.z - 0.3)]:
		out.append(AABB(Vector3(corner.x, 0.0, corner.y), Vector3(0.3, TOWER_HEIGHT, 0.3)))
	for y in [6.0, 12.0, 18.0, TOWER_HEIGHT]:
		out.append(AABB(Vector3(t.position.x, y - 0.25, t.position.z), Vector3(t.size.x, 0.25, t.size.z)))
	out.append(_control_box())
	var b := _board_box()
	out.append(b)
	for x in [b.position.x + 0.2, b.end.x - 0.4]:
		out.append(AABB(Vector3(x, 0.0, b.position.z), Vector3(0.2, b.position.y, 0.2)))
	return out


static func shared_mesh() -> ArrayMesh:
	if _mesh == null:
		_mesh = _build_mesh()
	return _mesh


## Stands the buildings on `site` ({pos: Vector3i, facing}: LaunchSite).
func setup(site: Dictionary) -> void:
	var p: Vector3i = site.pos
	position = Vector3(p.x + 0.5, p.y + 1, p.z + 0.5)
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
	var c := _control_box()
	var board := _board_box()
	_add_label("MISSION CONTROL", Vector3(c.get_center().x, CONTROL_HEIGHT - 0.9, c.end.z + 0.05), 0.012, Color.WHITE)
	_add_label("MISSION BOARD", Vector3(board.get_center().x, board.end.y - 0.35, board.end.z + 0.03), 0.009, BOARD_EDGE)
	_add_label("Walk up to me!", Vector3(board.get_center().x, board.position.y + 0.8, board.end.z + 0.03), 0.007,
		Color.WHITE)
	_add_label("LAUNCH PAD", Vector3(0.0, 0.03, LaunchSite.PAD_HALF + 1.0), 0.012, Color("25262b"), true)   # on the plaza
	# owner #94: the tower's warning light blinks and a flag waves on Mission Control's roof (world/life)
	var t := _tower_box()
	var blink := Blinker.new(Vector3.ONE * 0.6)
	blink.position = Vector3(t.get_center().x, TOWER_HEIGHT + 3.25, t.get_center().z)
	add_child(blink)
	var flag := WavingFlag.new(_shared_material())
	flag.position = Vector3(c.end.x - 0.4, CONTROL_HEIGHT + 0.4, c.position.z + 0.4)
	add_child(flag)


func _add_label(text: String, pos: Vector3, pixel: float, color: Color, lying := false) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.pixel_size = pixel
	l.font_size = 64
	l.outline_size = 10
	l.modulate = color
	l.outline_modulate = Color(0.05, 0.08, 0.14)
	if lying:
		l.rotation = Vector3(-PI / 2.0, 0, 0)   # painted on the plaza in front of the pad
		l.outline_size = 0
	add_child(l)


static func _build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var parts: Array = []
	var t := _tower_box()
	var boxes := solid_boxes()
	for i in 4:
		parts.append([boxes[i], ORANGE])
	for i in range(4, 8):
		parts.append([boxes[i], WHITE if i % 2 == 0 else GREY])
	for y in range(0, int(TOWER_HEIGHT), 3):   # the lattice's cross beams, orange and white by turns
		var c := ORANGE if (y / 3) % 2 == 0 else WHITE
		parts.append([AABB(Vector3(t.position.x, y + 1.4, t.position.z), Vector3(t.size.x, 0.12, 0.12)), c])
		parts.append([AABB(Vector3(t.position.x, y + 1.4, t.end.z - 0.12), Vector3(t.size.x, 0.12, 0.12)), c])
		parts.append([AABB(Vector3(t.position.x, y + 2.9, t.position.z), Vector3(0.12, 0.12, t.size.z)), c])
		parts.append([AABB(Vector3(t.end.x - 0.12, y + 2.9, t.position.z), Vector3(0.12, 0.12, t.size.z)), c])
	for arm_y in [10.0, 18.0]:   # two short arms towards the pad, over its stripes only
		parts.append([AABB(Vector3(LaunchSite.SQUARE_HALF + 0.6, arm_y, t.position.z + 1.2),
			Vector3(t.position.x - LaunchSite.SQUARE_HALF - 0.6, 0.35, 0.6)), ORANGE])
	parts.append([AABB(Vector3(t.get_center().x - 0.1, TOWER_HEIGHT, t.get_center().z - 0.1), Vector3(0.2, 3.0, 0.2)), WHITE])
	parts.append([AABB(Vector3(t.get_center().x - 0.25, TOWER_HEIGHT + 3.0, t.get_center().z - 0.25), Vector3(0.5, 0.5, 0.5)),
		Color("ff4a3a")])   # the warning light on its top
	var c := _control_box()
	parts.append([c, WHITE])
	parts.append([AABB(Vector3(c.position.x - 0.3, CONTROL_HEIGHT, c.position.z - 0.3), Vector3(c.size.x + 0.6, 0.4, c.size.z + 0.6)), TEAL])
	parts.append([AABB(Vector3(c.position.x - 0.05, 2.2, c.position.z + 0.4), Vector3(c.size.x + 0.1, 1.1, c.size.z - 0.8)), WINDOW])
	parts.append([AABB(Vector3(c.position.x + 0.4, 2.2, c.end.z - 0.05), Vector3(c.size.x - 0.8, 1.1, 0.1)), WINDOW_LIGHT])
	parts.append([AABB(Vector3(c.get_center().x - 0.7, 0.0, c.end.z), Vector3(1.4, 2.0, 0.08)), DOOR])
	parts.append([AABB(Vector3(c.position.x, 0.0, c.end.z), Vector3(c.size.x, 0.35, 0.1)), TEAL_DARK])
	parts.append([AABB(Vector3(c.position.x + 1.0, CONTROL_HEIGHT + 0.4, c.position.z + 1.2), Vector3(0.2, 1.4, 0.2)), GREY])
	parts.append([AABB(Vector3(c.position.x + 0.3, CONTROL_HEIGHT + 1.8, c.position.z + 0.5), Vector3(1.6, 1.0, 0.25)), DISH])
	var b := _board_box()
	parts.append([b, BOARD])
	parts.append([AABB(b.position - Vector3(0.1, 0.1, 0.02), Vector3(b.size.x + 0.2, 0.1, 0.3)), BOARD_EDGE])
	parts.append([AABB(Vector3(b.position.x - 0.1, b.end.y, b.position.z - 0.02), Vector3(b.size.x + 0.2, 0.1, 0.3)), BOARD_EDGE])
	for i in range(boxes.size() - 2, boxes.size()):
		parts.append([boxes[i], GREY])
	for i in 3:   # the planets painted on the board: the Moon, Mars, a far one
		var at := Vector3(b.position.x + 0.6 + i * 1.0, b.position.y + 0.7, b.end.z)
		parts.append([AABB(at, Vector3(0.45, 0.45, 0.04)), [Color("c9ccd6"), Color("c1440e"), Color("e0a44a")][i]])
	for part: Array in parts:
		_add_box(st, part[0], part[1])
	st.set_material(_shared_material())
	return st.commit()


static func _shared_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.9   # the Theater's material: its shaders are warmed already
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
		var order: Array[int] = [0, 1, 2, 0, 2, 3]
		if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for i: int in order:
			st.set_color(shade)
			st.set_normal(n)
			st.add_vertex(q[i])
