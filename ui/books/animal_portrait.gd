class_name AnimalPortrait
extends Control
## An animal's picture for the Animal Book (M3 Task 21b), drawn from its own box model (BlockyAnimal's boxes,
## so every kind in the species table has one, owner #41's too): each box's three faces seen from the side,
## a little above and in front (the head on the right, its face showing), nearest last. `dim`: a kind not met
## yet, drawn as a dark silhouette. UI draw calls only: no textures, meshes or materials.

## Towards the viewer (the painter's order) and how a step towards it moves on the page.
const TOWARD := Vector3(1.0, 0.25, -0.3)
const MARGIN := 0.08

var species: StringName = &"":
	set(value):
		species = value
		_polys.clear()
		queue_redraw()
## Owner #51: a monster kind (MonsterRules.KINDS) drawn the same way from MonsterModels' boxes (the palette's MOBS
## tab); set instead of `species`.
var monster: StringName = &"":
	set(value):
		monster = value
		_polys.clear()
		queue_redraw()
var dim := false:
	set(value):
		dim = value
		queue_redraw()

var _polys: Array = []   # [PackedVector2Array (unit space), shade (0 side, 1 top, 2 front), Color]
var _bounds := Rect2()


func _init(sp: StringName = &"", px: float = 96.0) -> void:
	species = sp
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


static func project(p: Vector3) -> Vector2:
	return Vector2(-p.z - 0.3 * p.x, -p.y + 0.25 * p.x)


## The kind's box faces on the page, farthest first, and their bounds.
static func faces(sp: StringName) -> Array:
	if not AnimalRules.SPECIES.has(sp):
		return []
	return _faces_of(BlockyAnimal._boxes(sp))


## Owner #51: a monster's faces at level 1 (its body and spikes; the yeti's wind-up snowball left out).
static func monster_faces(kind: StringName) -> Array:
	if not MonsterRules.KINDS.has(kind):
		return []
	return _faces_of(MonsterModels.boxes(kind, 1).filter(func(b: Array) -> bool:
		return b.size() < 4 or b[3] != MonsterModels.BALL))


static func _faces_of(list: Array) -> Array:
	var boxes: Array = list.duplicate()
	boxes.sort_custom(func(a: Array, b: Array) -> bool:
		return (a[0] as Vector3).dot(TOWARD) < (b[0] as Vector3).dot(TOWARD))
	var out: Array = []
	for b: Array in boxes:
		var c: Vector3 = b[0]
		var h: Vector3 = (b[1] as Vector3) * 0.5
		var col: Color = b[2]
		out.append([_quad(c, h, Vector3.RIGHT), 0, col])
		out.append([_quad(c, h, Vector3.UP), 1, col])
		out.append([_quad(c, h, Vector3.FORWARD), 2, col])
	return out


static func _quad(c: Vector3, h: Vector3, n: Vector3) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners: Array[Vector3] = []
	if n == Vector3.RIGHT:
		corners = [Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z)]
	elif n == Vector3.UP:
		corners = [Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	else:   # the front (-Z): the face
		corners = [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)]
	for k in corners:
		pts.append(project(c + k))
	return pts


func _draw() -> void:
	if _polys.is_empty():
		_polys = monster_faces(monster) if monster != &"" else faces(species)
		_bounds = Rect2()
		var first := true
		for f: Array in _polys:
			for p: Vector2 in (f[0] as PackedVector2Array):
				if first:
					_bounds = Rect2(p, Vector2.ZERO)
					first = false
				else:
					_bounds = _bounds.expand(p)
	if _polys.is_empty() or _bounds.size.x <= 0.0 or _bounds.size.y <= 0.0:
		return
	var room := size * (1.0 - 2.0 * MARGIN)
	var k := minf(room.x / _bounds.size.x, room.y / _bounds.size.y)
	var offset := (size - _bounds.size * k) * 0.5 - _bounds.position * k
	var shadow := Color(0.18, 0.13, 0.1, 0.85)
	for f: Array in _polys:
		var pts := PackedVector2Array()
		for p: Vector2 in (f[0] as PackedVector2Array):
			pts.append(offset + p * k)
		var col: Color = f[2]
		match int(f[1]):
			1:
				col = col.lightened(0.18)
			2:
				col = col.darkened(0.12)
		var c := shadow if dim else col
		draw_primitive(pts, PackedColorArray([c, c, c, c]), PackedVector2Array())   # a quad: no triangulation to fail
