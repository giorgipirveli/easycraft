class_name BotRealisticAvatar
extends RealisticAvatar
## A bot friend's body in the REALISTIC style (M2 Task 15): the Kenney person (CC0) with a shirt dyed
## in the bot's colour (tools/make_bot_skins.py, one texture per look in BotRules.LOOKS), so friends
## never look like clones of the player. One shared material per look.

const SKIN_DIR := "res://assets/characters/bot_skins/"

## Which of BotRules.LOOKS to wear; set before adding to the tree.
var bot_look := 0   # BotRules.LOOKS index (AvatarModel.look() is the player look)

static var _bot_materials := {}   # look -> StandardMaterial3D


func _ready() -> void:
	skin_index = int(BotRules.LOOKS[posmod(bot_look, BotRules.LOOKS.size())].base)
	if not _look_applied:   # Owner 48: its girl or boy hair shapes and clothes, dressed by super()
		_look = BotRules.avatar_look(bot_look)
		_look_applied = true
	super()
	var mesh := body_mesh()
	var mat := bot_material(bot_look)
	if mesh and mat:
		mesh.set_surface_override_material(0, mat)


## The look's parts in this bot's own colours (like BotBlockyAvatar).
func _resolved() -> Dictionary:
	var c: Dictionary = BotRules.LOOKS[posmod(bot_look, BotRules.LOOKS.size())]
	return _look.resolve_in(c.torso, c.legs, c.skin)


## The dyed skin stays (tools/make_bot_skins.py); without it, the recolour shader as for players.
func _color_body(r: Dictionary) -> void:
	if bot_material(bot_look) == null:
		super(r)


static func skin_path(bot_look: int) -> String:
	return SKIN_DIR + "bot_%d.png" % posmod(bot_look, BotRules.LOOKS.size())


## The shared material of a look, or null when its skin is missing (the plain skin stays on).
static func bot_material(bot_look: int) -> StandardMaterial3D:
	var i := posmod(bot_look, BotRules.LOOKS.size())
	if not _bot_materials.has(i):
		if not ResourceLoader.exists(skin_path(i)):
			return null
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load(skin_path(i))
		# Like the player's skins: the OpenGL (Compatibility) renderer needs the sRGB decode forced.
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mat.roughness = 0.85
		_bot_materials[i] = mat
	return _bot_materials[i]
