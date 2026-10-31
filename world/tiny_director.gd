class_name TinyDirector
extends Node
## The Tiny world and the chest mimic in a world (M3 Task 21c). The SecretDirector adds one on every peer as its child
## "Tiny" (so its RPCs and things line up) and calls it from its own checks; it uses the director's spawner, things,
## state and world access.
## Host:
## - a TINY child whose feet are in a mouse village's room finds it (the director's banner, chime and Secret Book);
##   the village's tiny chest comes with the director's chests, the mouse family (MouseFamily) from here;
## - the chest mimic (Session.tiny_wake_chest_requested): the wand on an opened chest within reach wakes it (once
##   per chest, at most WakeKinds.MAX_MIMICS at once): a ChestMimic hops after the child who woke it
##   (WakeKinds.mimic_hop on the ground next to it, one hop every HOP_EVERY, looked at ten times a second from the
##   director's plate tick), giggles, gives a small present (never gold) and hops back to sleep. It never hurts
##   anyone: it is a tap-only thing nobody bumps into.
## Every game: its own player, not tiny, standing in a mouse village's room (dug in, or grown there) is shown out to
## the door (a big child never gets stuck in the mice's home).

const FIND_LOOK := 16.0           # villages this near a player are looked at
const LOCAL_TICK := 0.5           # seconds between this game's looks for its own big player in a room
const HOPPING := 0
const GIVING := 1

var secrets: SecretDirector
var _mimics := {}                 # mimic name -> {peer, turns, t, phase, at, secret, key}
var _local_t := 0.0


func _ready() -> void:
	Session.tiny_wake_chest_requested.connect(_on_wake_chest)


func _process(delta: float) -> void:
	if secrets == null or not secrets.auto_tick:
		return
	_local_t += delta
	if _local_t >= LOCAL_TICK:
		_local_t = 0.0
		local_tick()


## Host (SecretDirector.host_tick): tiny children in a village's room find it.
func host_tick(players: Array[Player]) -> void:
	if secrets.rules == null:
		return
	for p in players:
		if p.size_mode != SizeMagic.Mode.TINY:
			continue
		var feet := Vector3i(p.global_position.floor())
		for s: Dictionary in secrets.rules.tiny_near(p.global_position, FIND_LOOK):
			if not secrets.state.found.has(s.id) and SecretRules._contains(s.room[0], s.room[1], feet):
				secrets._mark_found(s, p.peer_id)


## Host (SecretDirector._spawn_things): a village's mouse family.
func spawn_things(s: Dictionary) -> void:
	if s.kind != MouseVillages.KIND:
		return
	var family_name := "mice_" + str(s.id)
	if secrets.thing(family_name) == null:
		secrets._spawner.spawn({"kind": "mice", "id": family_name, "secret": s.id,
			"pos": Vector3(s.anchor as Vector3i) + Vector3(0.5, 0, 0.5), "yaw": float(s.yaw)})


## The things only the Tiny world spawns (the director's spawn function asks here).
static func make_thing(kind: String) -> SecretThing:
	match kind:
		"mice":
			return MouseFamily.new()
		"mimic":
			return ChestMimic.new()
	return null


## Every game: its own player, not tiny (and not a ghost flying through), standing in a village's room is shown out.
func local_tick() -> void:
	if secrets == null or secrets.rules == null or not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p == null or not p.is_local or not p.is_spawned() or p.size_mode == SizeMagic.Mode.TINY \
				or p.physics_mode == PhysicsMode.Mode.GHOST:
			continue
		var feet := Vector3i(p.global_position.floor())
		for s: Dictionary in secrets.rules.tiny_near(p.global_position, FIND_LOOK):
			if SecretRules._contains(s.room[0], s.room[1], feet):
				p.global_position = Vector3(s.visit as Vector3i) + Vector3(0.5, 0.0, 0.5)
				p.velocity = Vector3.ZERO
				Session.magic_feedback.emit(MouseVillages.TOO_BIG)
				break

# --- Host: the chest mimic -----------------------------------------------------------------------------------------

func _on_wake_chest(peer: int, chest_name: String) -> void:
	if not multiplayer.is_server() or secrets == null:
		return
	var chest := secrets.thing(chest_name) as TreasureChest
	var requester := Session._player_for_peer(peer)
	if chest == null or requester == null:
		return
	if not PlacementRules.in_reach(requester.eye_position(), chest.cell(), PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		Session.send_feedback(peer, "Too far away!")
		return
	if not (chest.opened or secrets.state.opened.has(chest.secret_id)):
		Session.send_feedback(peer, WakeKinds.MIMIC_CLOSED)
		return
	var key := mimic_key(chest.secret_id)
	if secrets.state.solved.has(key):
		Session.send_feedback(peer, WakeKinds.MIMIC_AGAIN)
		return
	var mimic_name := "mimic_" + chest.secret_id
	if secrets.thing(mimic_name) != null:
		Session.send_feedback(peer, WakeKinds.MIMIC_BUSY)
		return
	if _mimics.size() >= WakeKinds.MAX_MIMICS:
		Session.send_feedback(peer, WakeKinds.MIMIC_SLEEPY)
		return
	secrets._spawner.spawn({"kind": "mimic", "id": mimic_name, "secret": chest.secret_id, "pos": chest.position,
		"yaw": chest.rotation.y, "chest": chest_name, "golden": chest.golden, "scale": chest.scale.x})
	_mimics[mimic_name] = {"peer": peer, "turns": 0, "t": WakeKinds.HOP_EVERY, "phase": HOPPING, "at": chest.position,
		"secret": chest.secret_id, "key": LootRules.chest_key(secrets.world_seed, chest.cell())}
	Session.send_feedback(peer, WakeKinds.MIMIC_WAKE)
	Session.progress_tell(peer, LevelRules.BUDDY)   # waking a chest counts as waking a buddy (M3 Task 12)


## The key in SecretState.solved that says a chest's mimic already gave its present.
static func mimic_key(secret_id: String) -> String:
	return "mimic:" + secret_id


func mimics_awake() -> int:
	return _mimics.size()


## Host, ten times a second (SecretDirector.plate_tick): the mimics hop, give and go back to sleep.
func fast_tick(delta: float) -> void:
	for mimic_name: String in _mimics.keys():
		var m: Dictionary = _mimics[mimic_name]
		var node := secrets.thing(mimic_name) as ChestMimic
		if node == null:
			_mimics.erase(mimic_name)
			continue
		m.t = float(m.t) - delta
		if float(m.t) > 0.0:
			continue
		if int(m.phase) == GIVING:
			_sleep(mimic_name, node, m)
			continue
		m.turns = int(m.turns) + 1
		m.t = WakeKinds.HOP_EVERY
		var p := Session._player_for_peer(int(m.peer))
		if p == null:
			_sleep(mimic_name, node, m)
			continue
		var at: Vector3 = m.at
		var y := at.y
		var solid := func(c: Vector3i) -> bool: return BlockIds.is_solid(int(secrets.block_at.call(c)))
		var ground := func(x: int, z: int) -> float: return WakeKinds.feet_near(x, z, y, solid)
		var next := WakeKinds.mimic_hop(at, p.global_position, ground)
		if next != at:
			m.at = next
			node.hop_to.rpc(next)
		if int(m.turns) >= WakeKinds.MIMIC_HOPS:
			m.phase = GIVING
			m.t = WakeKinds.PRESENT_TIME
			node.present.rpc()
			var gift := WakeKinds.mimic_present(int(m.key), Game.universe)
			gift["title"] = Lang.t(WakeKinds.MIMIC_PRESENT)
			gift["picture"] = Riddles.CHEST
			secrets._give(int(m.peer), gift)


func _sleep(mimic_name: String, node: ChestMimic, m: Dictionary) -> void:
	if int(m.phase) == GIVING:   # M3 Task 19: only a present given uses the chest up (its child may have left before)
		secrets.state.solved[mimic_key(str(m.secret))] = true
	node.sleep_away.rpc()
	node.queue_free()
	_mimics.erase(mimic_name)
