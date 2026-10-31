class_name PartyPinata
extends StaticBody3D
## A surprise drop (M3 Task 14b, spec §13.5): a Party Piñata floating down on its parachute, or a supply
## balloon drifting over the Totem with a crate of supplies. The DropDirector spawns it (every peer gets it
## from its spawn data) and moves it on the host (DropRules' paths); its place is synced to guests. It is in
## the group "monsters" with take_hit / hit_center / hit_radius / size, so everything that hits monsters hits
## it (swords, arrows, the spear, blasters, fists, bot friends' swings, spike traps) and a tap aims at it (the
## animals' layer); the host's DropDirector counts the hits and bursts it into supplies. Its looks are
## box-built meshes shared by every drop of its kind (BlockyAnimal's material: nothing new to compile).

## Host: something hit it (from: where the hit came from).
signal hit(drop: PartyPinata, from: Vector3)

const PINATA := 0
const BALLOON := 1
const STRIPES: Array[Color] = [Color("ef5350"), Color("ffee58"), Color("66bb6a"), Color("42a5f5"), Color("ab47bc")]

var kind := PINATA
var serial := 0                   # the world's piñata number (its supplies are fixed by it)
var hits := 0                     # host
var last_hit := -1.0              # host: DropDirector time of the last hit that counted
## Synced on change: on the ground (the parachute folds away).
var landed := false

var _t := 0.0
var _top := Vector3.ZERO
var _ground := 0.0
var _path := {}
var _ground_t := 0.0
var _body := Node3D.new()
var _chute: MeshInstance3D
var _wobble: Tween
var _spin := 0.0

static var _meshes := {}


## data = {id, kind, pos (a piñata's top, a balloon's start), ground (piñata: the ground's height), path
## (balloon: DropRules.balloon_path), serial}
func setup(data: Dictionary) -> void:
	name = str(data.id)
	kind = BALLOON if int(data.get("kind", PINATA)) == BALLOON else PINATA
	serial = int(data.get("serial", 0))
	_top = data.pos
	position = _top
	_ground = float(data.get("ground", _top.y))
	var path: Variant = data.get("path", {})
	_path = path if path is Dictionary and (path as Dictionary).has("start") else {"start": _top, "over": _top, "rest": _top}
	_build()


func _build() -> void:
	add_to_group(&"monsters")
	add_to_group(&"drops")
	collision_layer = Monster.LAYER       # taps aim at it; nothing collides with it
	collision_mask = 0
	add_child(_body)
	var mi := MeshInstance3D.new()
	mi.mesh = body_mesh(kind)
	_body.add_child(mi)
	if kind == PINATA:
		_chute = MeshInstance3D.new()
		_chute.name = "Chute"
		_chute.mesh = chute_mesh()
		_chute.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_chute)
	var box := BoxShape3D.new()
	box.size = size()
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0, size().y * 0.5, 0)
	add_child(shape)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	cfg.add_property(NodePath(".:position"))
	cfg.add_property(NodePath(".:landed"))
	cfg.property_set_replication_mode(NodePath(".:landed"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


## Host: `delta` seconds further along its way.
func advance(delta: float) -> void:
	_t += delta
	if kind == PINATA:
		position = DropRules.pinata_point(_top, _ground, _t)
		var down := DropRules.pinata_landed(_top, _ground, _t)
		if down != landed:
			landed = down
		if landed:
			_ground_t += delta
	else:
		position = DropRules.balloon_point(_path, _t)


## Seconds it has been on the ground (host).
func ground_time() -> float:
	return _ground_t


func chute_open() -> bool:
	return kind == PINATA and not landed


func size() -> Vector3:
	return Vector3(1.0, 1.3, 0.7) if kind == PINATA else Vector3(1.0, 2.6, 1.0)


func hit_center() -> Vector3:
	return global_position + Vector3(0, 0.65 if kind == PINATA else 1.3, 0)


## Generous, like a monster's: children aim loosely.
func hit_radius() -> float:
	return 0.8 if kind == PINATA else 1.0


## Anything that hits monsters hits it; the host's DropDirector counts it.
func take_hit(_damage: int, from: Vector3, _knockback: Vector3) -> void:
	if multiplayer.is_server() and not is_queued_for_deletion():
		hit.emit(self, from)


## Every game: a hit makes it swing.
func wobble() -> void:
	if not is_inside_tree():
		return
	if _wobble and _wobble.is_valid():
		_wobble.kill()
	_wobble = create_tween()
	_wobble.tween_property(_body, "rotation:z", 0.45, 0.08)
	_wobble.tween_property(_body, "rotation:z", -0.3, 0.12)
	_wobble.tween_property(_body, "rotation:z", 0.0, 0.2)


func _process(delta: float) -> void:
	if _chute and _chute.visible != chute_open():
		_chute.visible = chute_open()
	if kind == BALLOON:
		_spin += delta * 0.6
		_body.rotation.y = _spin


# --- Looks (shared meshes) ---

## A striped paper donkey with a paper tail (a piñata), or a big red balloon with a supply crate.
static func body_mesh(k: int) -> ArrayMesh:
	if not _meshes.has(k):
		var boxes: Array = []
		if k == PINATA:
			for i in STRIPES.size():
				boxes.append([Vector3(-0.36 + i * 0.18, 0.62, 0), Vector3(0.18, 0.42, 0.38), STRIPES[i]])   # body in stripes
			for x in [-0.28, 0.28]:
				for z in [-0.11, 0.11]:
					boxes.append([Vector3(x, 0.22, z), Vector3(0.12, 0.44, 0.12), STRIPES[(roundi(x * 10) + 5) % 5]])   # legs
			boxes.append_array([
				[Vector3(0.44, 0.92, 0), Vector3(0.18, 0.38, 0.18), STRIPES[1]],        # neck
				[Vector3(0.56, 1.1, 0), Vector3(0.32, 0.2, 0.2), STRIPES[3]],           # head
				[Vector3(0.5, 1.26, -0.06), Vector3(0.05, 0.16, 0.05), STRIPES[0]],     # ears
				[Vector3(0.5, 1.26, 0.06), Vector3(0.05, 0.16, 0.05), STRIPES[4]],
				[Vector3(0.64, 1.14, -0.105), Vector3(0.05, 0.05, 0.02), Color("1c1c20")],   # eyes
				[Vector3(0.64, 1.14, 0.105), Vector3(0.05, 0.05, 0.02), Color("1c1c20")],
				[Vector3(-0.5, 0.66, 0), Vector3(0.14, 0.05, 0.05), STRIPES[2]],        # a paper tail
				[Vector3(-0.58, 0.58, 0), Vector3(0.06, 0.14, 0.04), STRIPES[0]],
			])
		else:
			var red := Color("e8403a")
			boxes = [
				[Vector3(0, 0.22, 0), Vector3(0.5, 0.44, 0.5), Color("a0622d")],          # the supply crate
				[Vector3(0, 0.22, -0.255), Vector3(0.12, 0.34, 0.02), Color("fbfbfb")],  # a white cross on it
				[Vector3(0, 0.22, -0.255), Vector3(0.34, 0.12, 0.02), Color("fbfbfb")],
				[Vector3(0, 0.9, 0), Vector3(0.02, 0.9, 0.02), Color("fbfbfb")],          # string
				[Vector3(0, 1.4, 0), Vector3(0.12, 0.12, 0.12), red.darkened(0.3)],       # knot
				[Vector3(0, 1.95, 0), Vector3(0.9, 0.9, 0.9), red],                       # the balloon
				[Vector3(0, 1.95, 0), Vector3(1.0, 0.7, 0.7), red],
				[Vector3(0, 1.95, 0), Vector3(0.7, 0.7, 1.0), red],
				[Vector3(0, 2.4, 0), Vector3(0.7, 0.12, 0.7), red],
				[Vector3(0.18, 2.15, -0.46), Vector3(0.16, 0.2, 0.04), Color("ffb3a8")], # its shine
			]
		_meshes[k] = BlockyAnimal._build(boxes)
	return _meshes[k]


## The parachute: a striped canopy on four strings.
static func chute_mesh() -> ArrayMesh:
	if not _meshes.has(&"chute"):
		var boxes: Array = [
			[Vector3(0, 2.4, 0), Vector3(1.7, 0.1, 1.7), Color("fbfbfb")],
			[Vector3(0, 2.5, 0), Vector3(1.2, 0.12, 1.2), Color("ef5350")],
			[Vector3(0, 2.6, 0), Vector3(0.6, 0.1, 0.6), Color("fbfbfb")],
		]
		for x in [-0.75, 0.75]:
			for z in [-0.75, 0.75]:
				boxes.append([Vector3(x * 0.6, 1.8, z * 0.6), Vector3(0.02, 1.1, 0.02), Color("e6e6e6")])
		_meshes[&"chute"] = BlockyAnimal._build(boxes)
	return _meshes[&"chute"]
