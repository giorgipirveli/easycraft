class_name HubCircle
extends Node3D
## The portal hub's stone circle (M3 Task 5, spec §14.1) by a Survivor world's spawn: HubRules.STONES
## standing stones round a swirling floor. Not blocks (it never changes the world): one shared stone
## mesh drawn as one MultiMesh, the floor a quad with the portals' one swirl material. Every game of a
## world builds it from the seed (UniverseHub); walking into it opens the hub.

const FLOOR_SIZE := 3.0
const FLOOR_LIFT := 0.06

static var _stone: ArrayMesh

var _heights: Array[float] = []
var _stones := MultiMeshInstance3D.new()
var _floor: MeshInstance3D


## center: the middle on the ground; heights: each stone's ground height relative to the middle.
func setup(center: Vector3, yaw: float, heights: Array[float]) -> void:
	name = "HubCircle"
	position = center
	rotation.y = yaw
	_heights = heights


func _ready() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = stone_mesh()
	mm.instance_count = HubRules.STONES
	for i in HubRules.STONES:
		var a := TAU * i / HubRules.STONES
		var at := Vector3(cos(a), 0.0, sin(a)) * HubRules.STONE_RING
		at.y = _heights[i] if i < _heights.size() else 0.0
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, PI * 0.5 - a), at))   # the rune faces the middle
	_stones.multimesh = mm
	_stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_stones)
	_floor = PortalSwirl.surface(self, Vector2(FLOOR_SIZE, FLOOR_SIZE))
	_floor.rotation.x = -PI * 0.5
	_floor.position.y = FLOOR_LIFT


func stone_count() -> int:
	return _stones.multimesh.instance_count if _stones.multimesh else 0


func floor_material() -> Material:
	return _floor.material_override if _floor else null


## A standing stone: grey, a darker cap, moss and a glowing-blue rune line (vertex colours on
## BlockyAnimal's shared material), made once.
static func stone_mesh() -> ArrayMesh:
	if _stone == null:
		_stone = BlockyAnimal._build([
			[Vector3(0, 0.85, 0), Vector3(0.62, 1.7, 0.5), GolemModels.STONE],
			[Vector3(0, 1.78, 0), Vector3(0.74, 0.18, 0.6), GolemModels.STONE_DARK],
			[Vector3(0, 0.1, 0), Vector3(0.78, 0.2, 0.64), GolemModels.STONE_DARK],
			[Vector3(0.02, 1.1, -0.26), Vector3(0.12, 0.7, 0.04), GolemModels.RUNE],
			[Vector3(-0.2, 0.45, 0.2), Vector3(0.3, 0.12, 0.14), GolemModels.MOSS],
		])
	return _stone
