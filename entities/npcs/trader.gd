class_name Trader
extends Node3D
## Tilly the trader (M2 Task 7, spec §12.7): a friendly shopkeeper behind the counter of a small
## stall with a striped awning and a gold-coin sign, near the world spawn in Survivor worlds. The
## host spawns her for everyone (the sandbox's TraderSpawner) from WorldMeta; she never moves.
## Cheap: three shared vertex-coloured meshes (stall, body, waving arm) with WeaponModels' one
## material, a name label and one static body on the world layer, so players and animals bump into
## the counter. She turns to the nearest player and waves; a tap opens the shop (Trader.find). A
## one-time hint arrow bobs over the stall until the player's first visit (the lead's note).

const GREET_DISTANCE := 8.0
const LOOK_EVERY := 0.25        # seconds between looks for the nearest player
const MAX_TURN := 1.0           # radians she turns from the counter's front towards a player
const HINT_Y := 4.3
const ARM_SHOULDER := Vector3(0.4, 1.3, 0.0)

const _WOOD := Color("a0703f")
const _WOOD_DARK := Color("6e4526")
const _WOOD_LIGHT := Color("c8995c")
const _RED := Color("e04b3c")
const _WHITE := Color("fbf3e4")
const _GOLD := Color("ffd23f")
const _GOLD_DARK := Color("c99a12")
const _SKIN := Color("f1c27d")
const _DRESS := Color("8e44ad")
const _APRON := Color("f4efe6")
const _HAIR := Color("6b3e26")
const _STRAW := Color("e8c872")
const _DARK := Color("1b1b1b")

static var _meshes := {}

var _body := Node3D.new()
var _arm := Node3D.new()
var _hint := Node3D.new()
var _time := 0.0
var _look_timer := 0.0
var _turn_target := 0.0
var _greeting := false
var _hop: Tween


## data = {pos: Vector3 (her feet), yaw: float (the counter's front faces -Z), hint: bool}
func setup(data: Dictionary) -> void:
	name = "Tilly"
	position = data.pos
	rotation.y = float(data.yaw)
	add_to_group(&"traders")
	_add_mesh(self, &"stall")
	add_child(_body)
	_add_mesh(_body, &"body")
	_arm.position = ARM_SHOULDER
	_body.add_child(_arm)
	_add_mesh(_arm, &"arm")
	var label := Label3D.new()
	label.text = "Tilly"
	label.font_size = 48
	label.outline_size = 12
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.4, 0)
	add_child(label)
	_build_hint()
	show_hint(bool(data.get("hint", false)))
	_add_collision()


## The trader a tap ray (from, unit dir) hits, within TraderRules.TAP_REACH of `eye` and not behind a
## block: blocked(from, dir, distance) -> bool (BlockInteractor asks the voxel world).
static func find(tree: SceneTree, from: Vector3, dir: Vector3, eye: Vector3, blocked: Callable = Callable()) -> Trader:
	for n in tree.get_nodes_in_group(&"traders"):
		var t := n as Trader
		if t == null or t.is_queued_for_deletion() or not TraderRules.in_reach(eye, t.global_position, TraderRules.TAP_REACH):
			continue
		var d := TraderRules.ray_hit(from, dir, t.global_position)
		if d >= 0.0 and not (blocked.is_valid() and blocked.call(from, dir, d)):
			return t
	return null


func show_hint(on: bool) -> void:
	_hint.visible = on


func hint_visible() -> bool:
	return _hint.visible


func hint_node() -> Node3D:
	return _hint


## A happy little hop (a trade went through).
func cheer() -> void:
	if _hop and _hop.is_valid():
		_hop.kill()
	_body.position.y = 0.0
	_hop = create_tween()
	_hop.tween_property(_body, "position:y", 0.25, 0.12).set_ease(Tween.EASE_OUT)
	_hop.tween_property(_body, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)


func _process(delta: float) -> void:
	_time += delta
	_look_timer -= delta
	if _look_timer <= 0.0:
		_look_timer = LOOK_EVERY
		_look_for_players()
	_body.rotation.y = lerp_angle(_body.rotation.y, _turn_target, clampf(5.0 * delta, 0.0, 1.0))
	var arm := 2.5 + sin(_time * 9.0) * 0.35 if _greeting else 0.08 + sin(_time * 1.6) * 0.04
	_arm.rotation.z = lerpf(_arm.rotation.z, arm, clampf(8.0 * delta, 0.0, 1.0))
	if _hint.visible:
		_hint.position.y = HINT_Y + sin(_time * 3.0) * 0.18
		_hint.rotation.y = _time * 1.5


## Faces the nearest player within GREET_DISTANCE (never turning her back on the counter) and waves.
func _look_for_players() -> void:
	var nearest := GREET_DISTANCE
	var target := Vector3.INF
	for p in get_tree().get_nodes_in_group(&"players"):
		var body := p as Node3D
		if body == null or not body.visible:
			continue
		var d := body.global_position.distance_to(global_position)
		if d < nearest:
			nearest = d
			target = body.global_position
	_greeting = target.is_finite()
	if _greeting:
		var local := to_local(target)
		_turn_target = clampf(atan2(-local.x, -local.z), -MAX_TURN, MAX_TURN)
	else:
		_turn_target = 0.0


func _add_mesh(parent: Node3D, kind: StringName) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh(kind)
	parent.add_child(mi)


func _build_hint() -> void:
	_hint.name = "Hint"
	_hint.position = Vector3(0, HINT_Y, -0.4)
	add_child(_hint)
	_add_mesh(_hint, &"arrow")
	var label := Label3D.new()
	label.text = "SHOP"
	label.font_size = 64
	label.outline_size = 14
	label.pixel_size = 0.007
	label.modulate = _GOLD
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true   # seen over the hills between the spawn and the stall
	label.position = Vector3(0, 0.95, 0)
	_hint.add_child(label)


func _add_collision() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Player.WORLD_COLLISION_MASK
	body.collision_mask = 0
	add_child(body)
	var boxes := [[Vector3(0, 0.55, -0.85), Vector3(2.6, 1.1, 0.7)], [Vector3(0, 0.95, 0), Vector3(0.6, 1.9, 0.5)]]
	for x: float in [-1.33, 1.33]:
		for z: float in [-1.2, 0.55]:
			boxes.append([Vector3(x, 1.4, z), Vector3(0.14, 2.8, 0.14)])
	for b: Array in boxes:
		var shape := BoxShape3D.new()
		shape.size = b[1]
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position = b[0]
		body.add_child(cs)


static func _mesh(kind: StringName) -> Mesh:
	if not _meshes.has(kind):
		match kind:
			&"stall":
				_meshes[kind] = WeaponModels.build(_stall_parts())
			&"body":
				_meshes[kind] = WeaponModels.build(_body_parts())
			&"arm":
				_meshes[kind] = WeaponModels.build([
					[Vector3(0, -0.26, 0), Vector3(0.18, 0.52, 0.22), _DRESS],
					[Vector3(0, -0.58, 0), Vector3(0.16, 0.14, 0.2), _SKIN],
				])
			&"arrow":   # a shaft and two crossed diamond heads, so it reads as an arrow while it spins
				var head := Basis(Vector3.BACK, PI / 4.0)
				_meshes[kind] = WeaponModels.build([
					[Vector3(0, 0.5, 0), Vector3(0.2, 0.6, 0.2), _GOLD],
					[Vector3(0, 0.0, 0), Vector3(0.5, 0.5, 0.18), _GOLD, head],
					[Vector3(0, 0.0, 0), Vector3(0.5, 0.5, 0.18), _GOLD, Basis(Vector3.UP, PI / 2.0) * head],
				])
	return _meshes[kind]


## The counter, posts, a back shelf with potions, the striped awning and the gold-coin sign.
static func _stall_parts() -> Array:
	var parts: Array = [
		[Vector3(0, 0.5, -0.85), Vector3(2.6, 1.0, 0.7), _WOOD],
		[Vector3(0, 0.33, -1.205), Vector3(2.62, 0.06, 0.02), _WOOD_DARK],
		[Vector3(0, 0.68, -1.205), Vector3(2.62, 0.06, 0.02), _WOOD_DARK],
		[Vector3(0, 1.04, -0.85), Vector3(2.8, 0.08, 0.86), _WOOD_LIGHT],
		[Vector3(0, 1.5, 0.55), Vector3(2.4, 0.08, 0.3), _WOOD_LIGHT],
		[Vector3(0.8, 1.11, -0.85), Vector3(0.22, 0.06, 0.22), _GOLD],   # a pile of coins
		[Vector3(0.83, 1.17, -0.82), Vector3(0.2, 0.06, 0.2), _GOLD_DARK],
		[Vector3(-0.8, 1.2, -0.85), Vector3(0.14, 0.24, 0.14), _DRESS],  # a potion on the counter
		[Vector3(-0.8, 1.35, -0.85), Vector3(0.06, 0.06, 0.06), _WOOD_DARK],
	]
	var potions := [Color("3fbf5f"), Color("3a7be8"), Color("ff7eb6"), Color("ffd23f")]
	for i in potions.size():
		parts.append([Vector3(-0.75 + i * 0.5, 1.66, 0.55), Vector3(0.14, 0.24, 0.14), potions[i]])
	for x: float in [-1.33, 1.33]:
		for z: float in [-1.2, 0.55]:
			parts.append([Vector3(x, 1.4, z), Vector3(0.14, 2.8, 0.14), _WOOD_DARK])
	for i in 6:
		var stripe := _RED if i % 2 == 0 else _WHITE
		var x := -1.25 + i * 0.5
		parts.append([Vector3(x, 2.85, -0.325), Vector3(0.5, 0.08, 2.25), stripe])
		parts.append([Vector3(x, 2.68, -1.47), Vector3(0.5, 0.26, 0.05), stripe])   # the front valance
	parts.append({"center": Vector3(0, 3.25, -1.47), "rings": [[0.0, 0.28, _GOLD], [0.28, 0.36, _GOLD_DARK]],
		"thickness": 0.06, "back": _GOLD_DARK})
	return parts


## Tilly: a blocky shopkeeper in a purple dress, white apron and straw hat, facing -Z. Her right arm
## is its own mesh (it waves).
static func _body_parts() -> Array:
	var face := -0.241
	return [
		[Vector3(-0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), Color("2e4a5a")],
		[Vector3(0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), Color("2e4a5a")],
		[Vector3(0, 0.95, 0), Vector3(0.6, 0.7, 0.32), _DRESS],
		[Vector3(0, 0.85, -0.17), Vector3(0.46, 0.6, 0.02), _APRON],
		[Vector3(-0.4, 1.04, 0), Vector3(0.18, 0.52, 0.22), _DRESS],   # left arm
		[Vector3(-0.4, 0.72, 0), Vector3(0.16, 0.14, 0.2), _SKIN],
		[Vector3(0, 1.55, 0), Vector3(0.48, 0.48, 0.48), _SKIN],
		[Vector3(0, 1.82, 0.02), Vector3(0.52, 0.12, 0.52), _HAIR],
		[Vector3(0, 1.55, 0.23), Vector3(0.52, 0.45, 0.08), _HAIR],
		[Vector3(-0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), _DARK],   # eyes
		[Vector3(0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), _DARK],
		[Vector3(0, 1.46, face), Vector3(0.18, 0.04, 0.01), _DARK],     # smile
		[Vector3(-0.1, 1.48, face), Vector3(0.04, 0.05, 0.01), _DARK],
		[Vector3(0.1, 1.48, face), Vector3(0.04, 0.05, 0.01), _DARK],
		[Vector3(-0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), Color("ff9aa2")],   # cheeks
		[Vector3(0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), Color("ff9aa2")],
		[Vector3(0, 1.9, 0), Vector3(0.8, 0.04, 0.8), _STRAW],          # straw hat
		[Vector3(0, 1.94, 0), Vector3(0.52, 0.05, 0.52), _RED],
		[Vector3(0, 2.02, 0), Vector3(0.5, 0.14, 0.5), _STRAW],
	]
