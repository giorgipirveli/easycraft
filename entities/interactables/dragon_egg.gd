class_name DragonEgg
extends SecretThing
## A dragon egg in a Dragon Realm nest (owner feedback #39, spec §14.2a): a speckled egg that rocks now and then and
## glows softly. A tap asks the host (Session.request_hatch); the host's DragonNests hatches it into the tapper's pet
## dragon (once per world) and every game sees it crack (hatch_fx). One shared mesh and the shared glow quad.

const ROCK_EVERY := 3.0           # seconds between its little rocks
const ROCK_ANGLE := 0.18

static var _mesh_cache: ArrayMesh

var _body := Node3D.new()
var _t := 0.0


## data = {id, pos (the nest's egg cell, bottom middle), secret}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.6, 0.7, 0.6), Vector3(0, 0.35, 0))
	add_child(_body)
	_mesh(egg_mesh(), _body)
	var glow := _mesh(InteractableModels.glow_quad())
	glow.material_override = InteractableModels.glow_material(LootRules.EPIC)
	glow.position = Vector3(0, 0.35, 0)
	glow.scale = Vector3.ONE * 0.6
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_t = float(absi(hash(name)) % 100) / 100.0 * ROCK_EVERY


## A tap: ask the host to hatch it.
func use_tap(_hud: Node) -> bool:
	Session.request_hatch(String(name))
	return true


func _process(delta: float) -> void:
	_t += delta
	var phase := fmod(_t, ROCK_EVERY)
	_body.rotation.z = sin(phase * TAU * 2.0) * ROCK_ANGLE * (1.0 - phase / 0.6) if phase < 0.6 else 0.0


## Every game: the shell cracks, bits of shell fly and a sparkle rises (the host frees the egg after).
@rpc("authority", "call_local", "reliable")
func hatch_fx() -> void:
	var root := get_tree().root
	var at := global_position + Vector3(0, 0.4, 0)
	Audio.play(&"egg_crack", at)
	Fx.burst(root, at, Color("f3e6c8"), 16, 3.5, 0.1, 0.7, 8.0)
	Fx.burst(root, at, Color("7ff0d8"), 20, 4.0, 0.08, 0.9, -1.0)


## One egg for every nest: cream with teal and violet speckles, a band of scales (models face -Z).
static func egg_mesh() -> ArrayMesh:
	if _mesh_cache == null:
		var shell := Color("f3e6c8")
		var teal := Color("3fbf9f")
		var violet := Color("9a6bd8")
		_mesh_cache = InteractableModels._build([
			[Vector3(0, 0.08, 0), Vector3(0.36, 0.16, 0.36), shell],
			[Vector3(0, 0.3, 0), Vector3(0.44, 0.3, 0.44), shell],
			[Vector3(0, 0.52, 0), Vector3(0.34, 0.16, 0.34), shell],
			[Vector3(0, 0.64, 0), Vector3(0.2, 0.08, 0.2), shell],
			[Vector3(0, 0.3, 0), Vector3(0.45, 0.06, 0.45), teal],                 # a band of scales
			[Vector3(-0.1, 0.44, -0.176), Vector3(0.06, 0.06, 0.02), violet],     # speckles
			[Vector3(0.12, 0.2, -0.226), Vector3(0.06, 0.06, 0.02), violet],
			[Vector3(0.226, 0.4, 0.05), Vector3(0.02, 0.06, 0.06), teal],
			[Vector3(-0.226, 0.18, -0.08), Vector3(0.02, 0.06, 0.06), violet],
			[Vector3(0.05, 0.56, 0.176), Vector3(0.06, 0.06, 0.02), teal],
		])
	return _mesh_cache
