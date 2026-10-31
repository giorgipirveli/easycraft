class_name QuestGiver
extends Node3D
## A quest giver standing by a world's spawn (owner #45a, spec §14.17): Zara the explorer (desert), Bram the
## ranger (Frostpeak), Mimi the baker (Candy Kingdom), and Tilly in a Sandbox (her Survivor self is the
## trader at her stall). Every game places its own from the seed (QuestRules.giver_for_world), so nothing is
## sent over the network. A picture bubble floats over the head: "!" when a story waits for this game's
## child, "?" when the child's step is "come back to me" (QuestDirector sets it). A tap opens the giver's
## card (QuestGiver.find, like Trader.find). Cheap: two shared vertex-coloured meshes with WeaponModels'
## one material, two labels and one small static body on the world layer.

const TAP_REACH := 6.0
const CHEST_HEIGHT := 1.1
const TAP_RADIUS := 0.8
const GREET_DISTANCE := 8.0
const LOOK_EVERY := 0.25
const BUBBLE_Y := 2.75
const ARM_SHOULDER := Vector3(0.4, 1.3, 0.0)
const BUBBLE_NEW := "!"
const BUBBLE_BACK := "?"

const _SKIN := Color("f1c27d")
const _DARK := Color("1b1b1b")
const _CHEEK := Color("ff9aa2")
## Each giver's colours: [shirt, trousers, hat, hat band / hood trim, extra].
const LOOKS := {
	&"tilly": [Color("8e44ad"), Color("2e4a5a"), Color("e8c872"), Color("e04b3c"), Color("f4efe6")],
	&"zara": [Color("c9a86a"), Color("6d4c41"), Color("e3cfa3"), Color("6d4c41"), Color("8d6e63")],
	&"bram": [Color("2e7d32"), Color("4e342e"), Color("8d6e63"), Color("fff8e1"), Color("37474f")],
	&"mimi": [Color("f48fb1"), Color("ad1457"), Color("ffffff"), Color("f8bbd0"), Color("ffffff")],
	&"nell": [Color("26a69a"), Color("5d4037"), Color("26a69a"), Color("ff9800"), Color("8d6e63")],   # owner #39's realm
	&"mira": [Color("5c6bc0"), Color("3e2723"), Color("3f51b5"), Color("8ff7e8"), Color("8d6e63")],   # universe 6
}

static var _meshes := {}

var giver_id: StringName = &""
var bubble := Label3D.new()
var _body := Node3D.new()
var _arm := Node3D.new()
var _time := 0.0
var _look_timer := 0.0
var _turn_target := 0.0
var _greeting := false


## data = {id: giver id (QuestRules.GIVERS), pos: Vector3 (feet), yaw: float (facing -Z turned by yaw)}
func setup(data: Dictionary) -> void:
	giver_id = StringName(data.id)
	name = "Giver_%s" % giver_id
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	add_to_group(&"quest_givers")
	Progress.counted.connect(_on_progress_counted)   # owner #94: a jump for joy at the child's quest step near here
	add_child(_body)
	_add_mesh(_body, StringName("body_%s" % giver_id))
	_arm.position = ARM_SHOULDER
	_body.add_child(_arm)
	_add_mesh(_arm, StringName("arm_%s" % giver_id))
	var g := QuestRules.giver(giver_id)
	var label := Label3D.new()
	label.text = "%s\n%s" % [str(g.get("name", "")), str(g.get("what", ""))]
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.25, 0)
	add_child(label)
	bubble.text = ""
	bubble.font_size = 110
	bubble.outline_size = 22
	bubble.pixel_size = 0.006
	bubble.modulate = Color("ffd23f")
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true   # seen over the hills between the spawn and the giver
	bubble.position = Vector3(0, BUBBLE_Y, 0)
	bubble.visible = false
	add_child(bubble)
	_add_collision()


## "!" (a story waits), "?" (come back to me) or "" (nothing): this game's child only.
func show_bubble(text: String) -> void:
	bubble.text = text
	bubble.visible = text != ""


func bubble_text() -> String:
	return bubble.text if bubble.visible else ""


## The giver a tap ray (from, unit dir) hits, within TAP_REACH of `eye` and not behind a block.
static func find(tree: SceneTree, from: Vector3, dir: Vector3, eye: Vector3, blocked: Callable = Callable()) -> QuestGiver:
	for n in tree.get_nodes_in_group(&"quest_givers"):
		var g := n as QuestGiver
		if g == null or g.is_queued_for_deletion() or not TraderRules.in_reach(eye, g.global_position, TAP_REACH):
			continue
		var d := TraderRules.ray_hit(from, dir, g.global_position)
		if d >= 0.0 and not (blocked.is_valid() and blocked.call(from, dir, d)):
			return g
	return null


func _process(delta: float) -> void:
	_time += delta
	_look_timer -= delta
	if _look_timer <= 0.0:
		_look_timer = LOOK_EVERY
		_look_for_players()
	_body.rotation.y = lerp_angle(_body.rotation.y, _turn_target, clampf(5.0 * delta, 0.0, 1.0))
	var arm := 2.5 + sin(_time * 9.0) * 0.35 if _greeting else 0.08 + sin(_time * 1.6) * 0.04
	_arm.rotation.z = lerpf(_arm.rotation.z, arm, clampf(8.0 * delta, 0.0, 1.0))
	if bubble.visible:
		bubble.position.y = BUBBLE_Y + sin(_time * 3.0) * 0.12


## Faces the nearest player within GREET_DISTANCE and waves.
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
	var was := _greeting
	_greeting = target.is_finite()
	if _greeting:
		var local := to_local(target)
		_turn_target = atan2(-local.x, -local.z)
		if not was:
			AnimGreet.hop(_body)   # owner #94: a hop hello as the child walks up
	else:
		_turn_target = 0.0


## Owner #94: this game's child did a quest step, a story or a board goal: a giver it stands by jumps for joy.
func _on_progress_counted(kind: StringName, _amount: int) -> void:
	if _greeting and AnimGreet.cheers_for(kind):
		AnimGreet.cheer(_body)


func _add_mesh(parent: Node3D, kind: StringName) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh(kind)
	parent.add_child(mi)


func _add_collision() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Player.WORLD_COLLISION_MASK
	body.collision_mask = 0
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 1.9, 0.5)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.95, 0)
	body.add_child(cs)


static func _mesh(kind: StringName) -> Mesh:
	if not _meshes.has(kind):
		var s := String(kind)
		var who := StringName(s.get_slice("_", 1))
		var look: Array = LOOKS.get(who, LOOKS[&"tilly"])
		if s.begins_with("arm_"):
			_meshes[kind] = WeaponModels.build([
				[Vector3(0, -0.26, 0), Vector3(0.18, 0.52, 0.22), look[0]],
				[Vector3(0, -0.58, 0), Vector3(0.16, 0.14, 0.2), _SKIN],
			])
		else:
			_meshes[kind] = WeaponModels.build(_body_parts(who, look))
	return _meshes[kind]


## A blocky friend facing -Z: legs, body, the left arm (the right one waves on its own), a head with a face
## and what each wears (Tilly's straw hat and apron, Zara's explorer hat and backpack, Bram's fur hood and
## scarf, Mimi's baker's hat and apron, Nell's headband with dragon horns).
static func _body_parts(who: StringName, look: Array) -> Array:
	var face := -0.241
	var parts: Array = [
		[Vector3(-0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), look[1]],
		[Vector3(0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), look[1]],
		[Vector3(0, 0.95, 0), Vector3(0.6, 0.7, 0.32), look[0]],
		[Vector3(-0.4, 1.04, 0), Vector3(0.18, 0.52, 0.22), look[0]],
		[Vector3(-0.4, 0.72, 0), Vector3(0.16, 0.14, 0.2), _SKIN],
		[Vector3(0, 1.55, 0), Vector3(0.48, 0.48, 0.48), _SKIN],
		[Vector3(-0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), _DARK],
		[Vector3(0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), _DARK],
		[Vector3(0, 1.46, face), Vector3(0.18, 0.04, 0.01), _DARK],
		[Vector3(-0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), _CHEEK],
		[Vector3(0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), _CHEEK],
	]
	match who:
		&"tilly":
			parts.append_array([
				[Vector3(0, 0.85, -0.17), Vector3(0.46, 0.6, 0.02), look[4]],       # apron
				[Vector3(0, 1.82, 0.02), Vector3(0.52, 0.12, 0.52), Color("6b3e26")],
				[Vector3(0, 1.9, 0), Vector3(0.8, 0.04, 0.8), look[2]],             # straw hat
				[Vector3(0, 1.94, 0), Vector3(0.52, 0.05, 0.52), look[3]],
				[Vector3(0, 2.02, 0), Vector3(0.5, 0.14, 0.5), look[2]],
			])
		&"zara":
			parts.append_array([
				[Vector3(0, 0.95, 0.24), Vector3(0.46, 0.5, 0.18), look[4]],        # backpack
				[Vector3(0, 1.86, 0), Vector3(0.84, 0.04, 0.84), look[2]],          # explorer's hat
				[Vector3(0, 1.92, 0), Vector3(0.5, 0.06, 0.5), look[3]],
				[Vector3(0, 2.02, 0), Vector3(0.46, 0.16, 0.46), look[2]],
			])
		&"bram":
			parts.append_array([
				[Vector3(0, 1.58, 0.04), Vector3(0.58, 0.6, 0.56), look[2]],        # fur hood round the face
				[Vector3(0, 1.58, -0.26), Vector3(0.5, 0.5, 0.02), look[3]],
				[Vector3(0, 1.58, -0.275), Vector3(0.42, 0.42, 0.02), _SKIN],
				[Vector3(-0.1, 1.62, -0.29), Vector3(0.07, 0.09, 0.01), _DARK],
				[Vector3(0.1, 1.62, -0.29), Vector3(0.07, 0.09, 0.01), _DARK],
				[Vector3(0, 1.48, -0.29), Vector3(0.18, 0.04, 0.01), _DARK],
				[Vector3(0, 1.26, 0), Vector3(0.64, 0.12, 0.36), Color("c62828")],   # scarf
				[Vector3(-0.13, 0.06, 0), Vector3(0.26, 0.12, 0.3), look[4]],       # boots
				[Vector3(0.13, 0.06, 0), Vector3(0.26, 0.12, 0.3), look[4]],
			])
		&"mimi":
			parts.append_array([
				[Vector3(0, 0.85, -0.17), Vector3(0.46, 0.6, 0.02), look[4]],       # apron
				[Vector3(0, 1.86, 0), Vector3(0.52, 0.1, 0.52), look[2]],           # baker's hat
				[Vector3(0, 2.06, 0), Vector3(0.6, 0.3, 0.6), look[2]],
				[Vector3(0, 1.0, -0.19), Vector3(0.12, 0.12, 0.02), look[3]],       # a pocket heart
			])
		&"nell":
			parts.append_array([
				[Vector3(0, 1.74, 0), Vector3(0.5, 0.08, 0.5), look[2]],            # headband
				[Vector3(-0.14, 1.9, -0.04), Vector3(0.08, 0.2, 0.08), look[3]],    # two little dragon horns
				[Vector3(0.14, 1.9, -0.04), Vector3(0.08, 0.2, 0.08), look[3]],
				[Vector3(-0.4, 0.72, 0), Vector3(0.2, 0.16, 0.24), look[4]],        # a keeper's glove
				[Vector3(0, 0.95, 0.2), Vector3(0.3, 0.3, 0.12), Color("ffd54f")],   # an egg pouch on the back
			])
		&"mira":
			parts.append_array([
				[Vector3(0, 1.82, 0), Vector3(0.54, 0.2, 0.54), look[2]],          # an explorer's helmet
				[Vector3(0, 1.84, -0.28), Vector3(0.14, 0.12, 0.06), look[3]],     # its glowing lamp
				[Vector3(0, 0.95, 0.2), Vector3(0.32, 0.36, 0.14), Color("8d6e63")],   # a backpack of maps
				[Vector3(0.4, 0.72, -0.05), Vector3(0.12, 0.2, 0.12), Color("ffe7a3")],   # a little spore lamp
			])
	return parts
