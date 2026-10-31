class_name RemoteSmoother
extends Node
## Remote bodies shown smoothly between syncs (M4 Wave 2 A2, spec §17.0). Players sync 20 times a
## second and creatures 10 (SyncPace), so remote players, animals, monsters, buddies and bot friends
## moved in visible steps. Session keeps one of these and follows every MultiplayerSynchronizer that
## syncs its body's place (track): when a sync arrives on a game that does not simulate the body
## (synchronized / delta_synchronized fire only there), the synced place and turn go into the body's
## MotionBuffer and the body is put back where it is shown; every frame (step) it is shown a little
## behind, between the last syncs. Only the turn around the vertical axis is smoothed. Code on this
## game that moves the body itself (a hiding spot, a teleport) wins: the body starts again from the
## next sync. The game that simulates a body never receives its syncs, so nothing changes there.
## One loop for every body, fixed buffers: nothing is allocated per frame.

## Tests: the clock in seconds (default: the engine's).
var now: Callable
## Off: track() follows nothing new (tests that follow bodies with their own smoother).
var enabled := true

var _motions: Array[Motion] = []


class Motion:
	extends RefCounted
	var sync: MultiplayerSynchronizer
	var on_sync: Callable
	var root: Node
	var body_path: NodePath   # the node whose position is synced (relative to root)
	var turn_path: NodePath   # the node whose rotation is synced (empty: none)
	var body: Node3D
	var turn: Node3D          # (looked up again when replaced: a player's Avatar changes with the style)
	var buffer: MotionBuffer
	var started := false   # a sync arrived since the last restart
	var shown_place := Vector3.ZERO
	var shown_yaw := 0.0
	var synced_place := Vector3.ZERO
	var synced_yaw := 0.0


## Follows `sync` if it syncs a place; interval and delay default to SyncPace's for its body.
func track(sync: MultiplayerSynchronizer, interval: float = -1.0, delay: float = -1.0) -> void:
	var cfg := sync.replication_config
	var root := sync.get_node_or_null(sync.root_path)
	if not enabled or cfg == null or root == null:
		return
	var m := Motion.new()
	m.sync = sync
	m.root = root
	for path: NodePath in cfg.get_properties():
		match str(path.get_concatenated_subnames()):
			"position":
				m.body_path = NodePath(path.get_concatenated_names())
			"rotation":
				m.turn_path = NodePath(path.get_concatenated_names())
	if m.body_path.is_empty() or not _resolve(m):
		return
	if interval < 0.0:
		interval = SyncPace.interval_for(root)
	if delay < 0.0:
		delay = SyncPace.smoothing_delay(root)
	m.buffer = MotionBuffer.new(interval, delay)
	m.on_sync = _on_sync.bind(m)
	sync.synchronized.connect(m.on_sync)
	sync.delta_synchronized.connect(m.on_sync)
	sync.tree_exiting.connect(_untrack.bind(m), CONNECT_ONE_SHOT)
	_motions.append(m)


func count() -> int:
	return _motions.size()


func _process(_delta: float) -> void:
	step()


## Shows every followed body where its buffer says, now.
func step() -> void:
	var t := _now()
	for m: Motion in _motions:
		if not m.started or not _resolve(m):
			continue
		if m.body.position != m.shown_place or (m.turn != null and m.turn.rotation.y != m.shown_yaw):
			_restart(m)   # moved by code on this game
			continue
		m.buffer.sample(t)
		if m.buffer.position != m.shown_place:
			m.body.position = m.buffer.position
			m.shown_place = m.body.position
		if m.turn != null and m.buffer.yaw != m.shown_yaw:
			m.turn.rotation.y = m.buffer.yaw
			m.shown_yaw = m.turn.rotation.y


## A sync arrived: the multiplayer API has just written the values it carried.
func _on_sync(m: Motion) -> void:
	if not _resolve(m):
		return
	var place := m.body.position
	var yaw := m.turn.rotation.y if m.turn != null else 0.0
	if not m.started:
		m.started = true
		m.synced_place = place
		m.synced_yaw = yaw
		m.shown_place = place
		m.shown_yaw = yaw
		m.buffer.push(_now(), place, yaw)
		return
	if place != m.shown_place:   # (a delta sync without the place leaves the shown one there)
		m.synced_place = place
	if yaw != m.shown_yaw:
		m.synced_yaw = yaw
	m.buffer.push(_now(), m.synced_place, m.synced_yaw)
	m.body.position = m.shown_place
	if m.turn != null:
		m.turn.rotation.y = m.shown_yaw


func _restart(m: Motion) -> void:
	m.buffer.clear()
	m.started = false


func _untrack(m: Motion) -> void:
	_motions.erase(m)
	if is_instance_valid(m.sync) and m.sync.synchronized.is_connected(m.on_sync):
		m.sync.synchronized.disconnect(m.on_sync)
		m.sync.delta_synchronized.disconnect(m.on_sync)
	m.on_sync = Callable()   # (it holds the Motion: no cycle left behind)


func _exit_tree() -> void:
	for m: Motion in _motions.duplicate():
		_untrack(m)


## The body (and the turning node) as they are now: false when the body is gone.
static func _resolve(m: Motion) -> bool:
	if not is_instance_valid(m.root):
		return false
	if not is_instance_valid(m.body) or not m.body.is_inside_tree():
		m.body = m.root.get_node_or_null(m.body_path) as Node3D
	if not m.turn_path.is_empty() and (not is_instance_valid(m.turn) or not m.turn.is_inside_tree()):
		m.turn = m.root.get_node_or_null(m.turn_path) as Node3D
	return m.body != null


func _now() -> float:
	return now.call() if now.is_valid() else Time.get_ticks_usec() / 1000000.0
