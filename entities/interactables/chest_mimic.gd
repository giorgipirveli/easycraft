class_name ChestMimic
extends SecretThing
## The chest mimic (M3 Task 21c): an opened treasure chest the Magic Wand woke. It peeks out with googly eyes,
## giggles, hops after the child who woke it (the host's TinyDirector decides each hop and sends it to every game:
## hop_to), opens wide with its tongue out for a small present (present), then hops back to sleep (sleep_away):
## the still chest it stood in for shows again. Never scary, never harmful: a tap-only thing on the secret things'
## layer (nobody bumps into it), never in the group "monsters", no attacks. Shared meshes (the chest's, and one
## face mesh for every mimic).

const LID_PEEK := -0.35           # the lid lifted a little while it hops
const LID_WIDE := -1.6
const HOP_HEIGHT := 0.55

static var _meshes := {}

## The still chest it stands in for (a sibling among the director's things), hidden while this one is awake.
var chest_name := ""

var _body := Node3D.new()
var _lid := Node3D.new()
var _tongue: MeshInstance3D
var _landing := Vector3.ZERO
var _hop: Tween
var _t := 0.0


## data = {id, pos, yaw, secret, chest, golden, scale}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.8, 0.7, 0.55), Vector3(0, 0.33, 0))
	chest_name = str(data.get("chest", ""))
	var golden := bool(data.get("golden", false))
	scale = Vector3.ONE * clampf(float(data.get("scale", 1.0)), 0.2, 1.0)
	add_child(_body)
	_mesh(InteractableModels.chest_base(golden), _body)
	_mesh(_face_mesh(), _body)
	_lid.position = InteractableModels.LID_PIVOT
	_body.add_child(_lid)
	_mesh(InteractableModels.chest_lid(golden), _lid)
	_tongue = _mesh(_tongue_mesh(), _body)
	_tongue.visible = false
	_lid.rotation.x = LID_PEEK
	_landing = position


func _ready() -> void:
	var chest := _chest()
	if chest:
		chest.visible = false
	Audio.play(&"giggle", global_position + Vector3(0, 0.4, 0), -4.0, 1.35)
	Fx.burst(get_tree().root, global_position + Vector3(0, 0.5, 0), Color("ffe27a"), 14, 2.5, 0.08, 0.7, 2.0)


func _exit_tree() -> void:
	var chest := _chest()
	if chest:
		chest.visible = true


func _chest() -> Node3D:
	var parent := get_parent()
	return parent.get_node_or_null(NodePath(chest_name)) as Node3D if parent and chest_name != "" else null


## Where it lands (or landed) last.
func landing() -> Vector3:
	return _landing


func _process(delta: float) -> void:
	_t += delta
	if not (_hop and _hop.is_valid()):   # a little wiggle while it waits
		_body.rotation.z = sin(_t * 6.0) * 0.06


## Every game: a hop to `to` (the host decided it): an arc, a clop and a squash when it lands.
@rpc("authority", "call_local", "reliable")
func hop_to(to: Vector3) -> void:
	_landing = to
	if not is_inside_tree():
		position = to
		return
	var d := to - position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)
	if _hop and _hop.is_valid():
		_hop.kill()
	_hop = create_tween()
	_hop.tween_property(self, "position", to, WakeKinds.HOP_TIME)
	_hop.parallel().tween_method(_arc, 0.0, 1.0, WakeKinds.HOP_TIME)
	_hop.tween_callback(_landed)


func _arc(k: float) -> void:
	_body.position.y = sin(k * PI) * HOP_HEIGHT


func _landed() -> void:
	_body.position.y = 0.0
	Audio.play(&"mimic_hop", global_position, -6.0)
	var squash := create_tween()
	squash.tween_property(_body, "scale", Vector3(1.15, 0.8, 1.15), 0.06)
	squash.tween_property(_body, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK)


## Every game: it opens wide, tongue out, giggles and throws out its present.
@rpc("authority", "call_local", "reliable")
func present() -> void:
	_tongue.visible = true
	if not is_inside_tree():
		_lid.rotation.x = LID_WIDE
		return
	var open := create_tween()
	open.tween_property(_lid, "rotation:x", LID_WIDE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.play(&"giggle", global_position + Vector3(0, 0.4, 0), -2.0, 1.2)
	var top := global_position + Vector3(0, 0.7, 0)
	Fx.burst(get_tree().root, top, Color("ff6fb5"), 16, 4.0, 0.1, 1.0, 5.0)
	Fx.burst(get_tree().root, top, Color("ffd23f"), 16, 3.5, 0.1, 1.1, 4.0)


## Every game: back to sleep in a puff of sparkles (the host frees it next).
@rpc("authority", "call_local", "reliable")
func sleep_away() -> void:
	if is_inside_tree():
		Fx.burst(get_tree().root, global_position + Vector3(0, 0.4, 0), Color("fff3a8"), 20, 2.5, 0.08, 0.9, 1.0)
		Audio.play(&"sparkle", global_position)


## Two googly eyes on the front, above the lock (the chest faces -Z).
static func _face_mesh() -> Mesh:
	if not _meshes.has("face"):
		_meshes["face"] = WeaponModels.build([
			[Vector3(-0.2, 0.39, -0.262), Vector3(0.16, 0.14, 0.02), Color("ffffff")],
			[Vector3(0.2, 0.39, -0.262), Vector3(0.16, 0.14, 0.02), Color("ffffff")],
			[Vector3(-0.18, 0.37, -0.275), Vector3(0.07, 0.07, 0.01), Color("231f20")],
			[Vector3(0.22, 0.37, -0.275), Vector3(0.07, 0.07, 0.01), Color("231f20")],
		])
	return _meshes["face"]


static func _tongue_mesh() -> Mesh:
	if not _meshes.has("tongue"):
		_meshes["tongue"] = WeaponModels.build([
			[Vector3(0, 0.47, -0.3), Vector3(0.22, 0.03, 0.2), Color("ff6f91")],
		])
	return _meshes["tongue"]
