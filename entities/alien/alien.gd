class_name Alien
extends SpaceCreature
## A friendly alien (owner #86, spec §21f): an explorer or a trader at a travelling camp, a chief or a villager in a
## village (CreatureWords.ALIENS: its name, colours, words; AlienModels: its look). It turns to a child who comes near
## and waves; a villager strolls round its village (a little walk, a pause, never far) and hops for joy when the song of
## Echo is played. Never hurts anyone: no collision, nothing it does touches the child. The director hears its taps.

const GREET_DISTANCE := 7.0
const WANDER_R := 7.0             # a villager strolls this far from its home spot
const WALK_SPEED := 1.3

## (x, z) -> float: the ground's top at a column (a villager walks on it).
var ground_y: Callable
var role: StringName = &""
var home := Vector3.ZERO          # a villager's spot (the village square's side)
var arm := Node3D.new()
var _greeting := false
var _walk_to := Vector3.INF
var _rest := 0.0
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _col := Vector2i(0x7fffffff, 0)
var _col_y := NAN


## data = {id: StringName, pos: Vector3 (feet), yaw: float}
func setup(data: Dictionary) -> void:
	creature_id = StringName(data.id)
	var a := CreatureWords.alien(creature_id)
	name = "Alien_%s" % creature_id
	display_name = str(a.get("name", "Alien"))
	role = a.get("role", &"villager")
	position = data.pos
	home = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	tap_height = 0.9
	tap_radius = 0.75
	robot = false
	voice = &"pet" if role == &"villager" else &"giver"
	voice_size = 1.4
	_rng.seed = hash(String(creature_id))
	_rest = _rng.randf_range(0.5, 3.0)
	CreatureLook.add(body, AlienModels.body(creature_id), CreatureLook.CAMP_RANGE, "Look")
	arm.name = "Arm"
	arm.position = AlienModels.SHOULDER
	body.add_child(arm)
	CreatureLook.add(arm, AlienModels.arm(creature_id), CreatureLook.CAMP_RANGE, "ArmMesh")
	var tag := Label3D.new()
	tag.name = "NameTag"
	tag.text = display_name
	tag.font_size = 40
	tag.outline_size = 10
	tag.pixel_size = 0.005
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.05, 0)
	tag.visibility_range_end = 40.0
	add_child(tag)
	bubble.position = Vector3(0, 2.6, 0)


func _ready() -> void:
	super()
	home = global_position   # a villager strolls round where it first stood (in the world)


func greeting() -> bool:
	return _greeting


func think() -> void:
	var child := nearest_player(GREET_DISTANCE)
	var was := _greeting
	_greeting = child.is_finite()
	if _greeting:
		_walk_to = Vector3.INF
		face(child)
		if not was:
			AnimGreet.hop(body)   # owner #94: a hop hello as the child walks up
		return
	if role != &"villager":
		face(Vector3.INF)
		return
	if not _walk_to.is_finite():   # a villager strolls: a pause, then somewhere near its spot
		_rest -= LOOK_EVERY
		if _rest <= 0.0:
			var a := _rng.randf() * TAU
			var r := _rng.randf_range(1.5, WANDER_R)
			_walk_to = home + Vector3(cos(a) * r, 0.0, sin(a) * r)


func ease_frame(delta: float) -> void:
	_t += delta
	var wave := 2.5 + sin(_t * 9.0) * 0.35 if _greeting else 0.08
	ease_to(arm, ^"rotation:z", wave, 8.0 * delta)
	if not _walk_to.is_finite():
		return
	var at := global_position
	var d := Vector3(_walk_to.x - at.x, 0.0, _walk_to.z - at.z)
	if d.length() < 0.3:
		_walk_to = Vector3.INF
		_rest = _rng.randf_range(1.5, 4.0)
		return
	var step := d.normalized() * minf(WALK_SPEED * delta, d.length())
	_turn_target = atan2(-d.x, -d.z) - global_rotation.y
	var next := at + step
	next.y = lerpf(at.y, _ground(next), clampf(10.0 * delta, 0.0, 1.0))
	body.position.y = absf(sin(_t * 9.0)) * 0.08   # a bouncy little walk
	global_position = next


## The ground under `p`, looked up once per column it walks onto (a block read is a locked read).
func _ground(p: Vector3) -> float:
	var col := Vector2i(floori(p.x), floori(p.z))
	if col != _col and ground_y.is_valid():
		_col = col
		_col_y = float(ground_y.call(col.x, col.y))
	return _col_y if not is_nan(_col_y) else p.y
