class_name ThoughtPictures
extends RefCounted
## The thought bubbles' pictures (M2 Task 18): data/minds/thoughts.png, 8 × 1 tiles of 32 px drawn by
## tools/make_thought_pictures.gd (ids: Thought). One quad and one material per picture, made once
## and kept for the whole game, shared by every bubble (a material made per bubble would free its
## shader with the bubble and compile it again for the next: a 100+ ms frame on the emulator, see Fx).
## The material has the same setup as the secrets' picture plates (Pictures.material), so the two
## share one shader.

const ATLAS_PATH := "res://data/minds/thoughts.png"
const COLUMNS := 8
const TILE := 32
const SIZE := 0.8                 # a bubble is this wide in the world

static var _atlas: Texture2D
static var _quad: QuadMesh
static var _materials := {}


static func atlas() -> Texture2D:
	if _atlas == null:
		_atlas = load(ATLAS_PATH)
	return _atlas


static func quad() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2(SIZE, SIZE)
	return _quad


## Unshaded and alpha-cut, showing picture `id` of the atlas on a quad (UV 0..1).
static func material(id: int) -> StandardMaterial3D:
	if not _materials.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_texture = atlas()
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.uv1_scale = Vector3(1.0 / COLUMNS, 1.0, 1.0)
		m.uv1_offset = Vector3(float(id % COLUMNS) / COLUMNS, 0.0, 0.0)
		_materials[id] = m
	return _materials[id]


static func material_count() -> int:
	return _materials.size()
