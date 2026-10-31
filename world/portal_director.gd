class_name PortalDirector
extends Node
## Portal frames and cores in a world, Sandbox and Survivor alike (M3 Task 5, spec §14.2). The sandbox
## adds one on every peer, always named "PortalFrames", so its RPCs line up across the network.
## Host:
## - Follows the world's block changes (note_block): a Portal Core placed joins the links (PortalLinks:
##   pairs in placing order), one broken leaves them; a change near a core rechecks its frame
##   (PortalRules.find, at most once per core per tick, so a big stamp costs one check).
## - Ten times a second it looks where every player stands, from its own positions: walking into a doorway
##   whose partner's frame is whole sends that player's own game to the partner's exit (never into a
##   wall), with a whoosh at both ends; a lone frame, a broken partner or a walled-in exit is said kindly,
##   once. After a trip the player must step out of any doorway, and a moment pass, before the next.
## - The links and frames are saved (to_save, WorldMeta.portals); a far end that isn't loaded is trusted as
##   saved (blocks only change where they are loaded, and this director sees every change).
## Every peer: the doorways of working pairs swirl (one shared material and quad, PortalSwirl), from the
## host's list (_rpc_active). Nothing here changes a block.
## Owner feedback #39: universe portals (PortalGates, WorldMeta.gates): a frame whose core slot holds a universe
## crystal's core needs no partner; it swirls in its universe's colours, and walking in asks `travel` (the
## sandbox's travel_through_gate, solo only) to go to that universe, or says kindly why not.

## Host: a player went through (tests; the sandbox could count trips).
signal traveled(peer_id: int, from_core: Vector3i, to_core: Vector3i)

const CHECK_EVERY := 0.1
const RECHECKS_PER_TICK := 8
const NEEDS_PARTNER := "Build a second portal to link with this one!"
const BROKEN := "The other portal's frame is broken!"
const BLOCKED := "The other portal is blocked!"
const SPARKLE := Color("c38bff")

## Host: block_at(cell: Vector3i) -> int (tests use stubs).
var block_at: Callable = _world_block
## Host: area_ready(cell: Vector3i) -> bool: the blocks around there are loaded (a frame can be read).
var area_ready: Callable = func(_cell: Vector3i) -> bool: return true
## Host: tell(peer_id, text): a message for that player.
var tell: Callable = func(peer_id: int, text: String) -> void: Session.send_feedback(peer_id, text)
var links := PortalLinks.new()
## Owner 39: the world's universe portals.
var gates := PortalGates.new()
## Owner 39, host: (universe) -> String: travels there, or why not ("" = on the way). Solo only.
var travel: Callable = func(_u: int) -> String: return ""
## Owner 39, host: the universe of this world ("You are here!").
var here := 1

var _dirty := {}          # core -> true: recheck its frame at the next tick
var _inside := {}         # peer -> the core whose doorway they stand in (or arrived at)
var _cool := {}           # peer -> seconds before their next trip
var _check_t := 0.0
var _sent: Array = []     # the working doorways every peer was told
var _holder := Node3D.new()
var _swirls: Array[MeshInstance3D] = []


func _ready() -> void:
	_holder.name = "Swirls"
	_holder.top_level = true
	add_child(_holder)


func _world_block(cell: Vector3i) -> int:
	return Session.world.get_block(cell) if Session.world else BlockIds.AIR


# --- Host: links and frames -------------------------------------------------------------------------

## Host: a world's saved links and frames (WorldMeta.portals); the working doorways swirl at once.
func start(saved: Variant) -> void:
	links = PortalLinks.from_save(saved)
	_broadcast()


func to_save() -> Array:
	return links.to_save()


## Owner 39, host: a world's saved universe portals (WorldMeta.gates).
func start_gates(saved: Variant) -> void:
	gates = PortalGates.from_save(saved)
	_broadcast()


func gates_to_save() -> Array:
	return gates.to_save()


## Host: every block change in the world (WorldService.block_changed).
func note_block(pos: Vector3i, old_id: int, new_id: int) -> void:
	if new_id == BlockIds.PORTAL_CORE and links.add(pos):
		_dirty[pos] = true
	elif old_id == BlockIds.PORTAL_CORE and links.has(pos):
		links.remove(pos)
		_dirty.erase(pos)
		_broadcast()
	if CrystalRules.is_universe_core(old_id) and gates.has(pos) and old_id != new_id:   # owner 39
		gates.remove(pos)
		_dirty.erase(pos)
		_broadcast()
	if CrystalRules.is_universe_core(new_id) and gates.add(pos, CrystalRules.universe_of_core(new_id)):
		_dirty[pos] = true
	for core in links.order + gates.order:
		if PortalRules.watches(core, pos):
			_dirty[core] = true


## Host: rechecks the frames that may have changed (tick does it; tests call it).
func flush(limit: int = PortalLinks.MAX) -> void:
	if _dirty.is_empty():
		return
	for core: Vector3i in _dirty.keys().slice(0, limit):
		_dirty.erase(core)
		recheck(core)
	_broadcast()


## Host: reads the frame round `core` again (when its blocks are loaded; else the saved frame stands).
func recheck(core: Vector3i) -> void:
	if not (links.has(core) or gates.has(core)) or not area_ready.call(core):
		return
	var p := PortalRules.find(core, block_at)
	if not p.is_empty():
		p.exit = PortalRules.exit_spot(p, block_at)
	if gates.has(core):
		gates.set_shape(core, p)   # owner 39
	else:
		links.set_shape(core, p)


## Host -> a peer that just joined: the doorways that swirl.
func send_to(peer_id: int) -> void:
	if multiplayer.is_server() and peer_id != multiplayer.get_unique_id():
		_rpc_active.rpc_id(peer_id, _sent)


func _broadcast() -> void:
	var list := _active_list()
	if list == _sent:
		return
	_sent = list
	if multiplayer.is_server():
		_rpc_active.rpc(list)


func _active_list() -> Array:
	var out := []
	for p in links.active():
		out.append([p.lo, p.size, p.axis])
	for p in gates.active():   # owner 39: [lo, size, axis, universe]: its swirl in the universe's colours
		out.append([p.lo, p.size, p.axis, int(p.universe)])
	return out


# --- Host: travelling ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not multiplayer.is_server():
		return
	for peer: int in _cool.keys():
		_cool[peer] = float(_cool[peer]) - delta
		if _cool[peer] <= 0.0:
			_cool.erase(peer)
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	flush(RECHECKS_PER_TICK)
	if links.order.is_empty() and gates.order.is_empty():
		return
	for p in Monster.players_now(get_tree()):
		if not is_instance_valid(p) or not p.is_spawned() or p.knocked_out:
			continue
		var core: Variant = _doorway_of(p.global_position)
		if core == null:
			_inside.erase(p.peer_id)
		elif _inside.get(p.peer_id) != core:
			_inside[p.peer_id] = core
			if not _cool.has(p.peer_id):
				_enter(p, core)


## The core whose doorway `feet` stand in, or null.
func _doorway_of(feet: Vector3) -> Variant:
	for core in links.order:
		if PortalRules.in_opening(feet, links.shape_of(core)):
			return core
	for core in gates.order:   # owner 39
		if PortalRules.in_opening(feet, gates.shape_of(core)):
			return core
	return null


## Host: `p` walked into the doorway of `core`: through to its partner, or kind words why not.
func _enter(p: Player, core: Vector3i) -> void:
	if gates.has(core):
		_enter_gate(p, core)   # owner 39: a universe portal
		return
	var to: Variant = links.partner_of(core)
	if to == null:
		tell.call(p.peer_id, NEEDS_PARTNER)
		return
	recheck(to)   # validated now when its blocks are loaded
	var dest := links.shape_of(to)
	if dest.is_empty():
		_broadcast()
		tell.call(p.peer_id, BROKEN)
		return
	var exit: Vector3 = dest.get("exit", Vector3.INF)
	if not exit.is_finite():
		tell.call(p.peer_id, BLOCKED)
		return
	var yaw := PortalRules.exit_yaw(dest, exit)
	_cool[p.peer_id] = PortalRules.COOLDOWN   # a guest's position reaches the host late: no second trip meanwhile
	if p.peer_id == multiplayer.get_unique_id():
		_rpc_arrive(exit, yaw)
	else:
		_rpc_arrive.rpc_id(p.peer_id, exit, yaw)
	_rpc_whoosh.rpc(PortalRules.center(links.shape_of(core)), exit)
	traveled.emit(p.peer_id, core, to)


## This game's player: out at the other doorway (the terrain there may still be streaming in).
@rpc("authority", "call_remote", "reliable")
func _rpc_arrive(exit: Vector3, yaw: float) -> void:
	if not exit.is_finite() or not is_finite(yaw):
		return
	for p in Monster.players_now(get_tree()):
		if p.is_local:
			p.spawn_at(exit)
			p.rig.yaw = yaw
			return


@rpc("authority", "call_local", "reliable")
func _rpc_whoosh(from: Vector3, to: Vector3) -> void:
	var root := get_tree().root
	for at: Vector3 in [from, to]:
		if at.is_finite():
			Audio.play(&"portal_whoosh", at)
			Fx.portal(root, at + Vector3(0, 1.0, 0))   # M5 Task 2: rainbow-gold, the portals' own burst


# --- Every peer: the swirls -----------------------------------------------------------------------------

## The working doorways, [[lo: Vector3i, size: Vector2i, axis: int], ...]: a swirl fills each.
@rpc("authority", "call_local", "reliable")
func _rpc_active(list: Variant) -> void:
	var shown: Array = []
	if list is Array:
		for e: Variant in list:
			if e is Array and (e as Array).size() in [3, 4] and e[0] is Vector3i and e[1] is Vector2i \
					and typeof(e[2]) == TYPE_INT and shown.size() < PortalLinks.MAX + PortalGates.MAX:
				var size: Vector2i = e[1]
				var u: int = int(e[3]) if (e as Array).size() == 4 and typeof(e[3]) == TYPE_INT else 0   # owner 39
				if size.x >= PortalRules.MIN_WIDTH and size.x <= PortalRules.MAX_WIDTH \
						and size.y >= PortalRules.MIN_HEIGHT and size.y <= PortalRules.MAX_HEIGHT:
					shown.append({"lo": e[0], "size": size, "axis": e[2], "universe": u})
	while _swirls.size() > shown.size():
		_swirls.pop_back().free()
	while _swirls.size() < shown.size():
		_swirls.append(PortalSwirl.surface(_holder, Vector2.ONE))
	for i in shown.size():
		var p: Dictionary = shown[i]
		var s := _swirls[i]
		s.material_override = PortalSwirl.material_for(int(p.universe))   # owner 39: its universe's colours
		var size: Vector2i = p.size
		s.position = PortalRules.center(p)
		s.rotation = Vector3(0, PI * 0.5 if int(p.axis) == PortalRules.AXIS_Z else 0.0, 0)
		s.scale = Vector3(size.x, size.y, 1.0)


func swirls() -> Array[MeshInstance3D]:
	return _swirls

# --- Owner feedback #39: universe portals ------------------------------------------------------------------

## Host: `p` walked into a universe portal: to its universe (the sandbox travels: solo only), or kind words why not.
func _enter_gate(p: Player, core: Vector3i) -> void:
	var u := gates.universe_of(core)
	_cool[p.peer_id] = PortalRules.COOLDOWN
	if u == here:
		tell.call(p.peer_id, UniverseRules.travel_message("here"))
		return
	if not multiplayer.get_peers().is_empty() or p.peer_id != multiplayer.get_unique_id():
		tell.call(p.peer_id, UniverseRules.travel_message("friends"))
		return
	var why: String = travel.call(u)
	if why != "":
		tell.call(p.peer_id, why)
		return
	gate_entered.emit(u)


## Host: this game's player went through a universe portal to `universe` (tests; the sandbox is travelling).
signal gate_entered(universe: int)
