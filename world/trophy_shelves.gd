class_name TrophyShelves
extends Node3D
## The trophy shelves near this game's player (M3 Task 21b; research C3): every TROPHY_SHELF block (217) within
## TrophyRules.SHOW_RADIUS shows the world owner's badges as small trophies (TrophyRules.layout: a few on each, the
## top row first). Shelves are found through a BlockIndex (chunks copied once, a few a look; the host's edits reach
## it at once, a guest looks again every CACHE_SECONDS). Each shelf is one MeshInstance3D with a mesh cached per
## content (its two wooden shelves and its trophies baked together on BlockyAnimal's shared material): one draw
## call a shelf, at most TrophyRules.MAX_SHELVES, nothing made while nothing changes. A look every LOOK_EVERY.

const LOOK_EVERY := 0.5
const SCANS_PER_LOOK := 3
## A guest's world announces no edits, so its chunks are copied again after this long, one a look (a box copy can wait
## on the voxel threads while terrain streams: DEVELOPMENT §8); the host hears every edit and never copies again.
const CACHE_SECONDS := 10.0
const GUEST_SCANS_PER_LOOK := 1

var scans_per_look := SCANS_PER_LOOK

static var _meshes := {}   # content key -> ArrayMesh

var index := BlockIndex.new([BlockIds.TROPHY_SHELF])
## () -> Vector3: this game's player's position (INF while there is none).
var center: Callable = func() -> Vector3: return Vector3.INF
## The world owner's badges, in the order they came.
var badges: Array[String] = []

var _shown := {}   # cell -> MeshInstance3D
var _t := 0.0


func _ready() -> void:
	name = "TrophyShelves"
	top_level = true


func _process(delta: float) -> void:
	index.advance(delta)
	_t += delta
	if _t >= LOOK_EVERY:
		_t = 0.0
		refresh()


## Looks again: the shelves near the player and what each shows.
func refresh() -> void:
	var at: Vector3 = center.call()
	var cells: Array[Vector3i] = []
	if at.is_finite():
		cells = index.near(at, TrophyRules.SHOW_RADIUS, [scans_per_look])
		if cells.size() > TrophyRules.MAX_SHELVES:
			cells.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
				return Vector3(a).distance_squared_to(at) < Vector3(b).distance_squared_to(at))
			cells.resize(TrophyRules.MAX_SHELVES)
	var layout := TrophyRules.layout(cells, badges)
	for cell: Vector3i in _shown.keys():
		if not layout.has(cell):
			(_shown[cell] as MeshInstance3D).queue_free()
			_shown.erase(cell)
	for cell: Vector3i in layout:
		var on: Array[String] = []
		on.assign(layout[cell])
		var m: MeshInstance3D = _shown.get(cell)
		if m == null:
			m = MeshInstance3D.new()
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.position = Vector3(cell)
			add_child(m)
			_shown[cell] = m
		var mesh := mesh_for(on)
		if m.mesh != mesh:
			m.mesh = mesh
			m.set_meta(&"badges", on)


## One shelf's content as one mesh, made once per content.
static func mesh_for(on: Array[String]) -> ArrayMesh:
	var key := TrophyRules.key(on)
	if not _meshes.has(key):
		_meshes[key] = BlockyAnimal._build(TrophyRules.boxes(on))
	return _meshes[key]


## Shelf cell -> the badges it shows now (tests).
func shown() -> Dictionary:
	var out := {}
	for cell: Vector3i in _shown:
		out[cell] = (_shown[cell] as MeshInstance3D).get_meta(&"badges", [])
	return out
