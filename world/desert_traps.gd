class_name DesertTraps
extends Node
## The Sandstorm Desert's hazards in a world (M3 Task 2; rules in DesertRules). The sandbox adds one on
## every peer, named "DesertTraps", in a world whose universe has traps (the desert's descriptor).
## Host, ten times a second: a player who walks into a cactus is pushed away a little (their own game moves
## them: Session.send_knockback; never hurt); an arrow slit of a pyramid near a player whose lane the
## player stands in clicks (a puff of dust, a sound: the signal) and DesertRules.DART_DELAY later shoots a
## dart across the corridor: whoever is still in the lane is hurt a little (Session.hurt_player). A slit a
## child broke never shoots. Every game: the click, the dart's flight, the cactus's poke.
## Nothing here changes a block: it only reads the world through block_at.

const TICK := 0.1
const TRAP_RADIUS := 24.0         # slits of pyramids this close to a player are looked at
const DUST := Color("dcb877")
const DART := Color("6b4a2a")

var host := false
## Host: block_at(cell) -> id (the world, read only); traps_near(pos) -> [{cell, dir}] (the pyramids' slits
## near a spot; the sandbox takes them from the world's secret rules).
var block_at: Callable
var traps_near: Callable

var _t := 0.0
var _cactus_cool := {}            # peer -> seconds until the next push
var _trap_cool := {}              # slit cell -> seconds until it may shoot again
var _pending: Array = []          # [seconds until the dart, trap]

static var _dart_mesh: ArrayMesh


func start_host() -> void:
	host = true


func _process(delta: float) -> void:
	if not host:
		return
	_t += delta
	if _t >= TICK:
		tick(_t)
		_t = 0.0


## Host: one look (tests call it with any step).
func tick(dt: float) -> void:
	if block_at.is_null():
		return
	for key: Variant in _cactus_cool.keys():
		_cactus_cool[key] = float(_cactus_cool[key]) - dt
	for key: Variant in _trap_cool.keys():
		_trap_cool[key] = float(_trap_cool[key]) - dt
	var players := Monster.players_now(get_tree())
	_shoot_due(dt, players)
	for p in players:
		if p.knocked_out or p.is_hiding():
			continue
		_cactus(p)
		if traps_near.is_valid():
			for trap: Dictionary in traps_near.call(p.global_position):
				_arm(trap, p)


func _cactus(p: Player) -> void:
	if float(_cactus_cool.get(p.peer_id, 0.0)) > 0.0:
		return
	var push := DesertRules.cactus_push(p.global_position, block_at)
	if push == Vector3.ZERO:
		return
	_cactus_cool[p.peer_id] = DesertRules.CACTUS_COOLDOWN
	Session.send_knockback(p.peer_id, push)
	_rpc_poke.rpc(p.global_position + Vector3(0, 1.0, 0))


## A slit whose lane the player stands in clicks, and shoots a moment later.
func _arm(trap: Dictionary, p: Player) -> void:
	var cell: Vector3i = trap.cell
	if float(_trap_cool.get(cell, 0.0)) > 0.0 or block_at.call(cell) != BlockIds.ARROW_SLIT:
		return
	if not DesertRules.in_lane(trap, p.global_position):
		return
	_trap_cool[cell] = DesertRules.DART_COOLDOWN
	_pending.append([DesertRules.DART_DELAY, trap])
	_rpc_click.rpc(Vector3(cell) + Vector3(0.5, 0.5, 0.5) + Vector3(trap.dir) * 0.55)


func _shoot_due(dt: float, players: Array[Player]) -> void:
	for d: Array in _pending.duplicate():
		d[0] -= dt
		if d[0] > 0.001:   # (sums of ticks land a hair above 0)
			continue
		_pending.erase(d)
		var trap: Dictionary = d[1]
		if block_at.call(trap.cell) != BlockIds.ARROW_SLIT:
			continue                  # broken meanwhile
		var from := Vector3(trap.cell) + Vector3(0.5, 0.5, 0.5) + Vector3(trap.dir) * 0.55
		_rpc_dart.rpc(from, from + Vector3(trap.dir) * float(DesertRules.LANE))
		for p in players:
			if not p.knocked_out and not p.is_hiding() and DesertRules.in_lane(trap, p.global_position):
				Session.hurt_player(p.peer_id, DesertRules.DART_DAMAGE, from)


# --- Every game: the effects ---------------------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _rpc_click(at: Vector3) -> void:
	Audio.play(&"trap_click", at)
	Fx.burst(get_tree().root, at, DUST, 8, 1.5, 0.1, 0.5, 4.0, 40.0)


@rpc("authority", "call_local", "reliable")
func _rpc_dart(from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	Audio.play(&"dart", from)
	var dart := MeshInstance3D.new()
	dart.mesh = dart_mesh()
	dart.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dart.top_level = true
	add_child(dart)
	dart.global_position = from
	dart.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	var tw := dart.create_tween()
	tw.tween_property(dart, "global_position", to, from.distance_to(to) / DesertRules.DART_SPEED)
	tw.tween_callback(dart.queue_free)


@rpc("authority", "call_local", "reliable")
func _rpc_poke(at: Vector3) -> void:
	Audio.play(&"hit", at, -10.0)


## The dart: a thin shaft with a pale tip (shared; the animals' material, pointing -Z like every model).
static func dart_mesh() -> ArrayMesh:
	if _dart_mesh == null:
		_dart_mesh = BlockyAnimal._build([
			[Vector3(0, 0, 0.1), Vector3(0.05, 0.05, 0.5), DART],
			[Vector3(0, 0, -0.2), Vector3(0.08, 0.08, 0.12), Color("e8e0c8")],
		])
	return _dart_mesh
