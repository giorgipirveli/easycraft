class_name DropDirector
extends Node
## Surprise drops in a world (M3 Task 14b, spec §13.5). The sandbox adds one on every peer, always named
## "Drops", so its spawner and effects line up across the network (like the MonsterDirector).
## Host: counts play time (only while a player is in the world) and, once DropRules says so, lets a Party
## Piñata float down near a player (8-30 blocks, on dry ground that is loaded; never two at once) and tells
## the children near; in Survivor waves from wave 3 one supply balloon drifts in over the Totem and waits
## beside it until popped or the wave ends. It counts every hit (PartyPinata.hit: anything that hits monsters
## hits drops): 3 burst a piñata, 1 pops a balloon, into supplies for every player near (Survivor: blocks, a
## potion, ammo; never gold; Sandbox: the fun only). A piñata left 5 minutes on the ground floats away.
## Every game sees the drop (spawner, synced place), its swing on a hit and its burst. Nothing here changes
## a block. World access is injected, so tests drive the host with stubs.

const TICK := 0.5
const TELL_RADIUS := 40.0         # players this close hear that a piñata is coming
const BURST_PINATA := 0
const BURST_BALLOON := 1
const BURST_AWAY := 2

var world_seed := 0
var universe := 1
var survivor := false             # Survivor: supplies count; balloons come in waves
# Host side, injected by the sandbox (tests use stubs).
var stand_spot: Callable          # (x: int, z: int) -> Vector3 feet on the surface, or INF
var is_ready: Callable            # (pos: Vector3) -> bool: terrain loaded there
var wave_now: Callable            # () -> int: the Totem wave running now (0: none)
var totem_pos: Callable           # () -> Vector3: the Totem's feet (INF: none)
var give: Callable = _give        # (peer, loot, kind) -> void

var _list := Node3D.new()
var _spawner := MultiplayerSpawner.new()
var _clock := 0.0                 # host: seconds of play since the last piñata came
var _count := 0                   # host: piñatas so far in this world
var _time := 0.0                  # host: seconds (hit gaps)
var _tick_t := 0.0
var _wave_t := -1.0               # host: seconds into the running wave (-1: none)
var _balloon_done := false        # host: this wave's balloon came
var _next_id := 1
var running := false              # host: its clocks go (start())


func _ready() -> void:
	_list.name = "List"
	add_child(_list)
	_spawner.name = "DropSpawner"
	add_child(_spawner)
	_spawner.spawn_path = _spawner.get_path_to(_list)
	_spawner.spawn_function = _make_drop


## Host: begin (the sandbox calls it once the world and the callables are in place).
func start() -> void:
	running = true


func _process(delta: float) -> void:
	if running:
		advance(delta)


func drops() -> Array[PartyPinata]:
	var out: Array[PartyPinata] = []
	for n in _list.get_children():
		if n is PartyPinata and not n.is_queued_for_deletion():
			out.append(n)
	return out


func pinata() -> PartyPinata:
	for d in drops():
		if d.kind == PartyPinata.PINATA:
			return d
	return null


func _balloons() -> Array[PartyPinata]:
	var out: Array[PartyPinata] = []
	for d in drops():
		if d.kind == PartyPinata.BALLOON:
			out.append(d)
	return out


# --- Host -------------------------------------------------------------------------------------------------

## Host: `delta` seconds of the world (drops move every call; the clocks every TICK).
func advance(delta: float) -> void:
	_time += delta
	for d in drops():
		d.advance(delta)
	_tick_t += delta
	if _tick_t >= TICK:
		var dt := _tick_t
		_tick_t = 0.0
		tick(dt)


func tick(dt: float) -> void:
	var players := Monster.players_now(get_tree())
	var pin := pinata()
	if pin == null:
		if not players.is_empty():
			_clock += dt
			if DropRules.pinata_due(_clock, world_seed, _count, false):
				spawn_pinata_now()
	elif pin.landed and pin.ground_time() > DropRules.PINATA_STAY:
		_away(pin)                          # nobody came: it floats off (the clock goes on)
	_tick_balloons(dt)


## Host: a piñata floats down near one of the players now (the next one each time). False when there is
## no player or no loaded, dry spot for it yet (it tries again next tick).
func spawn_pinata_now() -> bool:
	var players := Monster.players_now(get_tree())
	if players.is_empty() or pinata() != null:
		return false
	var near: Vector3 = players[_count % players.size()].global_position
	for attempt in DropRules.PINATA_TRIES:
		var xz := DropRules.pinata_spot(world_seed, _count, near, attempt)
		var feet: Vector3 = stand_spot.call(floori(xz.x), floori(xz.y)) if stand_spot.is_valid() else Vector3.INF
		if not feet.is_finite() or (is_ready.is_valid() and not is_ready.call(feet)):
			continue
		var top := feet + Vector3(0, DropRules.PINATA_HEIGHT, 0)
		_spawner.spawn({"id": _new_id(), "kind": PartyPinata.PINATA, "pos": top, "ground": feet.y, "serial": _count})
		_count += 1
		_clock = 0.0
		_rpc_fx.rpc(top, BURST_AWAY)
		for p in players:
			if p.global_position.distance_to(feet) <= TELL_RADIUS:
				Session.send_feedback(p.peer_id, "A Party Piñata is floating down! Hit it 3 times!")
		return true
	return false


func _tick_balloons(dt: float) -> void:
	var w: int = int(wave_now.call()) if wave_now.is_valid() else 0
	if w <= 0:
		_wave_t = -1.0
		_balloon_done = false
		for b in _balloons():
			_away(b)                        # it leaves with the wave
		return
	_wave_t = 0.0 if _wave_t < 0.0 else _wave_t + dt
	if _balloon_done or not DropRules.balloon_released(w, survivor) or _wave_t < DropRules.BALLOON_DELAY:
		return
	var totem: Vector3 = totem_pos.call() if totem_pos.is_valid() else Vector3.INF
	if not totem.is_finite():
		return
	_balloon_done = true
	var angle := float(SurpriseRules._mix(world_seed, w, 21) % 3600) / 3600.0 * TAU
	var path := DropRules.balloon_path(totem, angle)
	_spawner.spawn({"id": _new_id(), "kind": PartyPinata.BALLOON, "pos": path.start, "path": path, "serial": w})
	for p in Monster.players_now(get_tree()):
		if p.global_position.distance_to(totem) <= TELL_RADIUS:
			Session.send_feedback(p.peer_id, "A supply balloon! Pop it for ammo and a potion!")


func _new_id() -> String:
	_next_id += 1
	return "Drop%d" % (_next_id - 1)


func _make_drop(data: Variant) -> Node:
	var d := PartyPinata.new()
	d.setup(data)
	if multiplayer.is_server():
		d.hit.connect(_on_hit)
	return d


## Host: a hit on a drop (at most one every DropRules.HIT_GAP): it swings for everyone; enough hits burst it.
func _on_hit(d: PartyPinata, _from: Vector3) -> void:
	if not is_instance_valid(d) or d.is_queued_for_deletion() or not DropRules.hit_counts(d.last_hit, _time):
		return
	d.last_hit = _time
	d.hits += 1
	_rpc_wobble.rpc(d.name)
	if d.hits >= (DropRules.PINATA_HITS if d.kind == PartyPinata.PINATA else DropRules.BALLOON_HITS):
		_burst(d)


## Host: the drop bursts; every player near it gets the same supplies (fixed by the world and the drop).
func _burst(d: PartyPinata) -> void:
	var at := d.hit_center()
	var key := LootRules.chest_key(world_seed, Vector3i(d.serial, d.kind, 14))
	var loot := DropRules.pinata_loot(key, universe, survivor) if d.kind == PartyPinata.PINATA else DropRules.balloon_loot(key)
	var radius := DropRules.SHARE_RADIUS if d.kind == PartyPinata.PINATA else DropRules.BALLOON_SHARE
	for p in Monster.players_now(get_tree()):
		if p.global_position.distance_to(at) <= radius:
			give.call(p.peer_id, loot, d.kind)
	_rpc_fx.rpc(at, BURST_PINATA if d.kind == PartyPinata.PINATA else BURST_BALLOON)
	d.queue_free()


## Supplies into the player's bag (Survivor) and a line saying what they are; Sandbox has everything already.
func _give(peer: int, loot: Dictionary, kind: int) -> void:
	var what := "Party Piñata!" if kind == PartyPinata.PINATA else "Supply balloon!"
	if survivor:
		var inv := Session.inventory_of(peer)
		for e: Array in loot.get("items", []):
			inv.add(int(e[0]), int(e[1]))
		Session.send_feedback(peer, "%s %s" % [what, LootRules.describe(loot)])
	else:
		Session.send_feedback(peer, tr("%s Hooray!") % what)


func _away(d: PartyPinata) -> void:
	_rpc_fx.rpc(d.hit_center(), BURST_AWAY)
	d.queue_free()


## Everyone: a drop swings (a hit that counted).
@rpc("authority", "call_local", "unreliable")
func _rpc_wobble(drop_name: String) -> void:
	var d := _list.get_node_or_null(NodePath(drop_name)) as PartyPinata
	if d:
		d.wobble()


## Everyone: a piñata bursts (confetti, candy-coloured paper, a party sound), a balloon pops, or a drop comes
## or goes (a sparkle and a toot).
@rpc("authority", "call_local", "unreliable")
func _rpc_fx(pos: Vector3, what: int) -> void:
	if not is_inside_tree() or not pos.is_finite():
		return
	var root := get_tree().root
	match what:
		BURST_PINATA:
			Celebration.confetti(root, pos, 1.3)
			for c in PartyPinata.STRIPES:
				Fx.burst(root, pos, c, 6, 4.5, 0.12, 0.9, 9.0)
			Audio.play(&"pinata_burst", pos)
		BURST_BALLOON:
			Celebration.confetti(root, pos + Vector3(0, 0.8, 0), 0.8)
			Audio.play(&"bubble_pop", pos)
			Audio.play(&"pop", pos, -4.0)
		_:
			Fx.burst(root, pos, Color("ffd23f"), 12, 2.5, 0.1, 0.8, -1.0)
			Audio.play(&"party_horn", pos, -4.0)


# --- Saving (host) ------------------------------------------------------------------------------------------

## WorldMeta.drops: the piñata clock and count (a drop in the air is not saved: the clock goes on).
func to_save() -> Dictionary:
	return {"clock": _clock, "count": _count}


func restore(saved: Dictionary) -> void:
	var s := DropRules.clean_save(saved)
	_clock = float(s.clock)
	_count = int(s.count)
