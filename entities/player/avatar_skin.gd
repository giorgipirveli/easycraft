class_name AvatarSkin
extends RefCounted
## The realistic avatar's recoloured skin (M3 Task 9): one ShaderMaterial per (skin texture, look
## colours) pair, made on first use and kept for the whole game, so wearing a look again (another
## player, a style swap, the editor's preview) reuses it and the shader compiles once (DEVELOPMENT.md
## §8). The shader is avatar_skin.gdshader; the masks and references come from
## tools/make_avatar_masks.py.

const SHADER := preload("res://entities/player/avatar_skin.gdshader")
## Region masks, in RealisticAvatar.SKINS order.
const MASKS: Array[String] = [
	"res://assets/characters/avatar_masks/humanMaleA_regions.png",
	"res://assets/characters/avatar_masks/humanFemaleA_regions.png",
]
## Per skin texture (tools/make_avatar_masks.py prints them): the typical linear brightness of hair,
## shirt, pants and shoes, and the painted skin's linear colour.
const REFERENCES := [
	{"hair": 0.04, "shirt": 0.6254, "pants": 0.1348, "shoes": 0.5972, "skin": Vector3(0.6795, 0.3663, 0.2542)},
	{"hair": 0.04, "shirt": 0.6317, "pants": 0.1676, "shoes": 0.5972, "skin": Vector3(0.7305, 0.4397, 0.3185)},
]
## Hair styles that wear the long-haired texture (the realistic hair is painted; Owner 48's girl styles add
## round "_real" shapes over it: AvatarParts).
const LONG_HAIR: Array[StringName] = [&"long", &"bun", &"curly", &"bangs", &"ponytail", &"pigtails", &"braid",
	&"buns", &"bob"]
## Owner 48: where the painted face's cheeks and eyes are in the 256 px layout (UV), per skin texture:
## [left cheek, right cheek, left eye, right eye]. The shader paints rosy cheeks and cartoon lashes there.
const FACE_SPOTS := [
	[Vector2(67, 61), Vector2(91, 61), Vector2(71.5, 54.7), Vector2(86.7, 54.7)],
	[Vector2(66, 62), Vector2(92, 62), Vector2(70, 54.7), Vector2(88.3, 54.7)],
]

static var _materials := {}


## The skin texture for a look: the long-haired, smooth-faced one for long hair and (Owner 48) for a face
## with eyelashes; the short-haired one otherwise.
static func variant_for(hair: StringName, lashes: bool = false) -> int:
	return 1 if LONG_HAIR.has(hair) or lashes else 0


## The material for a resolved look (AvatarLook.resolve) on skin texture `variant`.
static func material(variant: int, r: Dictionary) -> ShaderMaterial:
	var v := clampi(variant, 0, MASKS.size() - 1)
	var lashes := 1.0 if r.get("lashes", false) else 0.0
	var blush := 1.0 if r.get("blush", false) else 0.0
	var key := "%d|%s|%s|%s|%s|%s|%d|%s|%d%d" % [v, r.skin_id, (r.hair_color as Color).to_html(), (r.shirt as Color).to_html(),
		(r.pants as Color).to_html(), (r.shoes as Color).to_html(), r.pattern, (r.pattern_color as Color).to_html(),
		int(lashes), int(blush)]
	if _materials.has(key):
		return _materials[key]
	var ref: Dictionary = REFERENCES[v]
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("albedo_tex", load(RealisticAvatar.SKINS[v]))
	mat.set_shader_parameter("region_mask", load(MASKS[v]))
	mat.set_shader_parameter("skin_tint", skin_tint(v, r.skin_id))
	mat.set_shader_parameter("hair_color", r.hair_color)
	mat.set_shader_parameter("shirt_color", r.shirt)
	mat.set_shader_parameter("pants_color", r.pants)
	mat.set_shader_parameter("shoe_color", r.shoes)
	mat.set_shader_parameter("pattern", r.pattern)
	mat.set_shader_parameter("pattern_color", r.pattern_color)
	mat.set_shader_parameter("glow", 1.5 if r.pattern == AvatarCatalog.PATTERN_STARS else 0.0)
	mat.set_shader_parameter("region_gain", Vector4(1.0 / ref.hair, 1.0 / ref.shirt, 1.0 / ref.pants, 1.0 / ref.shoes))
	# Owner 48: cartoon eyelashes and rosy cheeks, nothing more
	var spots: Array = FACE_SPOTS[v]
	mat.set_shader_parameter("lashes", lashes)
	mat.set_shader_parameter("blush", blush)
	mat.set_shader_parameter("cheeks", Vector4(spots[0].x, spots[0].y, spots[1].x, spots[1].y) / 256.0)
	mat.set_shader_parameter("eyes", Vector4(spots[2].x, spots[2].y, spots[3].x, spots[3].y) / 256.0)
	_materials[key] = mat
	return mat


## How much to multiply the painted skin (linear) by for a skin tone: 1 for "classic" (the texture's
## own tone: the blocky yellow would look ill on a person), else the tone over the painted skin.
static func skin_tint(variant: int, skin_id: StringName) -> Vector3:
	if skin_id == &"classic" or not AvatarCatalog.SKIN_TONES.has(skin_id):
		return Vector3.ONE
	var target := (AvatarCatalog.SKIN_TONES[skin_id] as Color).srgb_to_linear()
	var ref: Vector3 = REFERENCES[clampi(variant, 0, REFERENCES.size() - 1)].skin
	return Vector3(target.r / ref.x, target.g / ref.y, target.b / ref.z).clampf(0.0, 3.0)


static func material_count() -> int:
	return _materials.size()
