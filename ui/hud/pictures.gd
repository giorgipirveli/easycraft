class_name Pictures
extends RefCounted
## The secrets' pictures (M2 Task 16): data/secrets/pictures.png, 8 × 4 tiles of 16 px drawn by
## tools/make_secret_pictures.gd (ids: Riddles). Riddle answers, the temple's plates and note and the Secret
## Book's slots show them, so children who can't read yet can play. Textures (UI) and materials (flat
## quads in the world) are made once and shared.
## Owner 42: the treasure pack's pictures live in their own atlas, data/secrets/treasure_pictures.png (8 × 3,
## tools/make_treasure_pictures.gd; ids from TreasureRules.FIRST_PICTURE on), so the M2 atlas never changes.

const ATLAS_PATH := "res://data/secrets/pictures.png"
const PACK_ATLAS_PATH := "res://data/secrets/treasure_pictures.png"
const COLUMNS := 8
const ROWS := 4
const PACK_ROWS := 3
const TILE := 16

static var _atlas: Texture2D
static var _pack_atlas: Texture2D
static var _textures := {}
static var _materials := {}


static func atlas() -> Texture2D:
	if _atlas == null:
		_atlas = load(ATLAS_PATH)
	return _atlas


static func pack_atlas() -> Texture2D:
	if _pack_atlas == null:
		_pack_atlas = load(PACK_ATLAS_PATH)
	return _pack_atlas


## Picture `id`'s atlas, its tile there and that atlas's rows.
static func _where(id: int) -> Array:
	if TinyPictures.has(id):   # M3 Task 21c: the Tiny world's pictures (drawn in code)
		return [TinyPictures.atlas(), TinyPictures.tile(id), 1]
	if id >= TreasureRules.FIRST_PICTURE:
		var k := id - TreasureRules.FIRST_PICTURE
		return [pack_atlas(), Vector2i(k % COLUMNS, k / COLUMNS), PACK_ROWS]
	return [atlas(), Vector2i(id % COLUMNS, id / COLUMNS), ROWS]


static func texture(id: int) -> AtlasTexture:
	if not _textures.has(id):
		var w := _where(id)
		var t := AtlasTexture.new()
		t.atlas = w[0]
		t.region = Rect2(Vector2(w[1] as Vector2i) * TILE, Vector2(TILE, TILE))
		t.filter_clip = true
		_textures[id] = t
	return _textures[id]


## An unshaded, alpha-cut material showing picture `id` on a quad (UV 0..1): painted on a temple's plates.
static func material(id: int) -> StandardMaterial3D:
	if not _materials.has(id):
		var w := _where(id)
		var tile: Vector2i = w[1]
		var rows: int = w[2]
		var m := StandardMaterial3D.new()
		m.albedo_texture = w[0]
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.uv1_scale = Vector3(1.0 / COLUMNS, 1.0 / rows, 1.0)
		m.uv1_offset = Vector3(float(tile.x) / COLUMNS, float(tile.y) / rows, 0.0)
		_materials[id] = m
	return _materials[id]
