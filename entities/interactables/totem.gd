class_name Totem
extends Node3D
## The Monster Totem (M2 Task 9, spec §12.8): a carved pole of three monster heads (a goblin, a slime
## and a horned one with glowing eyes) on a stone plinth, 20 blocks from the world spawn in every world.
## The host spawns it for everyone (the WaveDirector's TotemSpawner) from WorldMeta; it never moves.
## A tap within reach asks for its panel (Totem.find; the HUD's TotemPanel), except while a wave runs,
## when a tap is a swing. While a wave counts down or runs (and while the boss fights) a ring of
## glowing stones and a floating crystal light up around it. A short line over it says what is going on
## ("Wave 3", "5", "7 left", "Try again?").
## Cheap: three shared meshes (the pole with WeaponModels' material; the eyes and the glow with one
## shared glowing material, which the eyes keep compiled, so lighting up never compiles a shader),
## one label and one static body on the world layer. Nothing is made per Totem or per wave.

const LABEL_Y := 4.35
const CRYSTAL_Y := 4.0
const SPIN := 1.2                 # radians per second, the glow ring while it shows
const PULSE := 3.0
const GLOW := Color(0.72, 0.42, 1.0)   # magic purple

const _STONE := Color("8d8f96")
const _STONE_DARK := Color("62646b")
const _GOBLIN := Color("5d7a3a")
const _SLIME := Color("3fae9a")
const _HORNED := Color("5b3f8c")
const _WOOD := Color("8a5a2b")
const _BONE := Color("efe6d2")
const _DARK := Color("1b1b1b")
const _WHITE := Color("fbf3e4")
const _EYE := Color("ffe27a")

static var _meshes := {}
static var _glow_material: StandardMaterial3D

var busy := false                 # a wave (or the boss) is on: taps pass through to weapons
var _glow := Node3D.new()
var _label := Label3D.new()
var _time := 0.0


## data = {pos: Vector3 (feet), yaw: float (its face, -Z, looks at the world spawn)}
func setup(data: Dictionary) -> void:
	name = "Totem"
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	add_to_group(&"totems")
	_add_mesh(self, &"pole")
	_add_mesh(self, &"eyes")
	_glow.name = "Glow"
	_glow.visible = false
	add_child(_glow)
	_add_mesh(_glow, &"glow")
	_label.font_size = 64
	_label.outline_size = 14
	_label.pixel_size = 0.006
	_label.modulate = Color("ffd23f")
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, LABEL_Y, 0)
	_label.text = "Wave 1"
	add_child(_label)
	_add_collision()


## The Totem a tap ray (from, unit dir) hits, within WaveRules.TAP_REACH of `eye` and not behind a
## block (blocked(from, dir, distance) -> bool, the voxel world), and not while its wave runs.
static func find(tree: SceneTree, from: Vector3, dir: Vector3, eye: Vector3, blocked: Callable = Callable()) -> Totem:
	for n in tree.get_nodes_in_group(&"totems"):
		var t := n as Totem
		if t == null or t.busy or t.is_queued_for_deletion() or not WaveRules.in_reach(eye, t.global_position, WaveRules.TAP_REACH):
			continue
		var d := WaveRules.ray_hit(from, dir, t.global_position)
		if d >= 0.0 and not (blocked.is_valid() and blocked.call(from, dir, d)):
			return t
	return null


## The wave state (WaveDirector.state()) on this game: the glow and the line over the Totem.
func show_state(state: Dictionary) -> void:
	var phase := int(state.get("phase", WaveDirector.Phase.IDLE))
	busy = phase != WaveDirector.Phase.IDLE
	set_glow(busy)
	var text := line_for(state)
	if _label.text != text:
		_label.text = text


func set_glow(on: bool) -> void:
	if _glow.visible != on:
		_glow.visible = on


func glowing() -> bool:
	return _glow.visible


func label_text() -> String:
	return _label.text


## The short line over the Totem for a wave state.
static func line_for(state: Dictionary) -> String:
	match int(state.get("phase", WaveDirector.Phase.IDLE)):
		WaveDirector.Phase.COUNTDOWN:
			return str(int(state.get("count", 0)))
		WaveDirector.Phase.RUNNING:
			return Lang.t("%d left") % int(state.get("left", 0))
		WaveDirector.Phase.BOSS:
			return "The Stone Golem!"
	if int(state.get("lost", 0)) > 0:
		return "Try again?"
	var next := int(state.get("next", 1))
	return Lang.t("Wave %d or the Golem!") % next if bool(state.get("boss", false)) else Lang.t("Wave %d") % next


func _process(delta: float) -> void:
	if not _glow.visible:
		return
	_time += delta
	_glow.rotation.y = _time * SPIN
	_glow.position.y = sin(_time * PULSE) * 0.06


## The one glowing material the Totem's eyes, runes and glow share (never one per Totem or wave).
static func glow_material() -> StandardMaterial3D:
	if _glow_material == null:
		_glow_material = StandardMaterial3D.new()
		_glow_material.vertex_color_use_as_albedo = true
		_glow_material.roughness = 0.7
		_glow_material.emission_enabled = true
		_glow_material.emission = GLOW
		_glow_material.emission_energy_multiplier = 0.9
	return _glow_material


func _add_mesh(parent: Node3D, kind: StringName) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh(kind)
	parent.add_child(mi)


func _add_collision() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Player.WORLD_COLLISION_MASK
	body.collision_mask = 0
	add_child(body)
	for b: Array in [[Vector3(0, 0.2, 0), Vector3(1.9, 0.4, 1.9)], [Vector3(0, 1.8, 0), Vector3(1.0, 2.8, 1.0)]]:
		var shape := BoxShape3D.new()
		shape.size = b[1]
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position = b[0]
		body.add_child(cs)


static func _mesh(kind: StringName) -> Mesh:
	if not _meshes.has(kind):
		match kind:
			&"pole":
				_meshes[kind] = WeaponModels.build(_pole_parts())
			&"eyes":
				var eyes := WeaponModels.build(_eye_parts())
				eyes.surface_set_material(0, glow_material())
				_meshes[kind] = eyes
			&"glow":
				var glow := WeaponModels.build(_glow_parts())
				glow.surface_set_material(0, glow_material())
				_meshes[kind] = glow
	return _meshes[kind]


## The plinth, three stacked heads (goblin, slime, horned), two wooden arms and bone horns. Faces -Z.
static func _pole_parts() -> Array:
	var f := -0.505   # the goblin's face
	var parts: Array = [
		[Vector3(0, 0.15, 0), Vector3(1.9, 0.3, 1.9), _STONE],
		[Vector3(0, 0.35, 0), Vector3(1.5, 0.1, 1.5), _STONE_DARK],
		# the goblin: pointy ears, dark eyes, a toothy grin
		[Vector3(0, 0.9, 0), Vector3(1.0, 1.0, 1.0), _GOBLIN],
		[Vector3(-0.62, 1.05, 0), Vector3(0.24, 0.16, 0.14), _GOBLIN],
		[Vector3(0.62, 1.05, 0), Vector3(0.24, 0.16, 0.14), _GOBLIN],
		[Vector3(0, 0.62, f), Vector3(0.62, 0.14, 0.02), _DARK],
		[Vector3(-0.2, 0.72, f - 0.005), Vector3(0.08, 0.08, 0.02), _WHITE],
		[Vector3(0.2, 0.72, f - 0.005), Vector3(0.08, 0.08, 0.02), _WHITE],
		# the slime: a wide smile
		[Vector3(0, 1.85, 0), Vector3(0.9, 0.85, 0.9), _SLIME],
		[Vector3(0, 1.62, -0.455), Vector3(0.4, 0.07, 0.02), _DARK],
		[Vector3(-0.22, 1.66, -0.455), Vector3(0.07, 0.07, 0.02), _DARK],
		[Vector3(0.22, 1.66, -0.455), Vector3(0.07, 0.07, 0.02), _DARK],
		[Vector3(-0.2, 1.95, -0.455), Vector3(0.18, 0.18, 0.02), _WHITE],
		[Vector3(0.2, 1.95, -0.455), Vector3(0.18, 0.18, 0.02), _WHITE],
		[Vector3(-0.2, 1.93, -0.465), Vector3(0.08, 0.1, 0.02), _DARK],
		[Vector3(0.2, 1.93, -0.465), Vector3(0.08, 0.1, 0.02), _DARK],
		# wooden arms
		[Vector3(-0.72, 1.9, 0), Vector3(0.55, 0.22, 0.3), _WOOD],
		[Vector3(0.72, 1.9, 0), Vector3(0.55, 0.22, 0.3), _WOOD],
		[Vector3(-1.02, 2.05, 0), Vector3(0.14, 0.4, 0.3), _WOOD],
		[Vector3(1.02, 2.05, 0), Vector3(0.14, 0.4, 0.3), _WOOD],
		# the horned head, with a frown and bone horns
		[Vector3(0, 2.75, 0), Vector3(1.1, 0.9, 1.1), _HORNED],
		[Vector3(0, 2.55, -0.555), Vector3(0.5, 0.08, 0.02), _DARK],
		[Vector3(0, 3.02, -0.555), Vector3(0.7, 0.08, 0.02), _DARK],
		[Vector3(-0.62, 3.35, 0), Vector3(0.18, 0.6, 0.18), _BONE, Basis(Vector3.BACK, 0.45)],
		[Vector3(0.62, 3.35, 0), Vector3(0.18, 0.6, 0.18), _BONE, Basis(Vector3.BACK, -0.45)],
	]
	return parts


## What always glows a little: the horned head's eyes and three runes on the plinth.
static func _eye_parts() -> Array:
	return [
		[Vector3(-0.25, 2.82, -0.56), Vector3(0.22, 0.13, 0.02), _EYE],
		[Vector3(0.25, 2.82, -0.56), Vector3(0.22, 0.13, 0.02), _EYE],
		[Vector3(-0.5, 0.2, -0.955), Vector3(0.16, 0.12, 0.02), _EYE],
		[Vector3(0, 0.2, -0.955), Vector3(0.16, 0.12, 0.02), _EYE],
		[Vector3(0.5, 0.2, -0.955), Vector3(0.16, 0.12, 0.02), _EYE],
	]


## What lights up while a wave runs: eight standing stones around the plinth and a crystal above.
static func _glow_parts() -> Array:
	var parts: Array = []
	for i in 8:
		var a := TAU * i / 8.0
		parts.append([Vector3(cos(a) * 1.35, 0.2, sin(a) * 1.35), Vector3(0.2, 0.4, 0.2), Color("c9a6ff")])
	var diamond := Basis(Vector3.BACK, PI / 4.0)
	parts.append([Vector3(0, CRYSTAL_Y, 0), Vector3(0.36, 0.36, 0.36), Color("e8d8ff"), diamond])
	parts.append([Vector3(0, CRYSTAL_Y, 0), Vector3(0.36, 0.36, 0.36), Color("e8d8ff"), Basis(Vector3.UP, PI / 4.0) * diamond])
	return parts
