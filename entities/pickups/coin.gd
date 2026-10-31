class_name Coin
extends Node3D
## A gold coin from a defeated monster (M2 Task 4, spec §12.4). The host spawns it for everyone with a
## little pop; every peer flies the same arc and lands it on the blocks. Ten times a second the host
## looks for the nearest player within MonsterRules.COIN_PICKUP: the coin flies to that player (the
## synced `collector`) and the host gives its gold exactly once (Session.gold_add), then it is gone.
## A coin nobody takes vanishes after LIFETIME. It is one shared mesh (MonsterModels.coin_mesh) and
## no physics body; the MonsterDirector keeps at most MAX_COINS.

signal collected(coin: Coin, peer_id: int)

const GRAVITY := 16.0
const FLY_SPEED := 11.0
const CATCH := 0.45               # this close to the player's chest it is caught
const LIFETIME := 60.0
const CHECK_EVERY := 0.1          # host: looks for a player ten times a second
const POP_TIME := 0.35            # it pops out for a moment before it can fly to someone
const HOVER := 0.25               # its centre above the ground once landed
const SPIN := 3.0

var value := 1
var coin_id := ""
var collector := 0                # the peer it flies to (0: lying there); synced on change
## block_at(pos: Vector3i) -> int, read only (landing).
var block_at: Callable

var _vel := Vector3.ZERO
var _landed := false
var _age := 0.0
var _check := POP_TIME
var _given := false
var _mesh := MeshInstance3D.new()


## data = {id, pos, vel, value}
func setup(data: Dictionary) -> void:
	coin_id = str(data.id)
	name = coin_id
	position = data.pos
	var v: Variant = data.get("vel", Vector3.ZERO)
	_vel = v if v is Vector3 and (v as Vector3).is_finite() else Vector3.ZERO
	value = maxi(int(data.get("value", 1)), 1)
	add_to_group(&"coins")
	_mesh.mesh = MonsterModels.coin_mesh()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	cfg.add_property(NodePath(".:collector"))
	cfg.property_set_replication_mode(NodePath(".:collector"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


func is_landed() -> bool:
	return _landed


func _physics_process(delta: float) -> void:
	_age += delta
	if collector != 0:
		_fly(delta)
	elif not _landed:
		_fall(delta)
	if not multiplayer.is_server() or is_queued_for_deletion():
		return
	if _age >= LIFETIME or global_position.y < SpawnRules.FALL_LIMIT_Y:
		queue_free()
		return
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	if collector != 0:
		if _collector_player() == null:   # that player left: it drops where it is
			collector = 0
			_landed = false
		return
	var i := MonsterRules.collector(global_position, Monster.player_spots(get_tree()))
	if i >= 0:
		collector = Monster.players_now(get_tree())[i].peer_id


func _fall(delta: float) -> void:
	_vel.y -= GRAVITY * delta
	var next := global_position + _vel * delta
	if block_at.is_valid():
		if BlockIds.is_solid(block_at.call(Vector3i(Vector3(next.x, global_position.y, next.z).floor()))):
			next.x = global_position.x      # a wall: it drops straight down
			next.z = global_position.z
			_vel.x = 0.0
			_vel.z = 0.0
		if _vel.y <= 0.0 and BlockIds.is_solid(block_at.call(Vector3i((next - Vector3(0, HOVER, 0)).floor()))):
			next.y = floorf(next.y - HOVER) + 1.0 + HOVER
			_vel = Vector3.ZERO
			_landed = true
	global_position = next


func _fly(delta: float) -> void:
	var p := _collector_player()
	if p == null:
		return
	var to := p.global_position + Vector3(0, 0.9 * p.size_scale(), 0) - global_position
	if to.length() <= maxf(CATCH, FLY_SPEED * delta):
		_arrive()
	else:
		global_position += to.normalized() * FLY_SPEED * delta


## Caught: the ding on every peer, the gold from the host, once.
func _arrive() -> void:
	if _given:
		return
	_given = true
	visible = false
	Audio.play(&"coin", global_position, -4.0)
	if multiplayer.is_server():
		Session.gold_add(collector, value, "coin")
		collected.emit(self, collector)
		queue_free()


func _collector_player() -> Player:
	for p in Monster.players_now(get_tree()):
		if p.peer_id == collector:
			return p
	return null


func _process(delta: float) -> void:
	_mesh.rotation.y += SPIN * delta
	if _landed and collector == 0:
		_mesh.position.y = sin(_age * 3.0) * 0.06
