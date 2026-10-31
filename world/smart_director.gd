class_name SmartDirector
extends Node
## Smart blocks in a world, Sandbox and Survivor alike (M3 Task 7, spec §14.4). The sandbox adds one on every
## peer, always named "Smart", so its RPCs line up across the network. Host:
## - Power (PowerRules, one step): a checked tap (Session.smart_tap_requested) switches a button, lever or
##   light switch; the blocks touching a source follow it at once (a doorway as one, never closing on
##   someone: Session.power_set_blocks); a pressed button pops up after BUTTON_TIME; a pressure plate powers
##   while a player or a bot friend stands on it (their feet, looked at CHECK_EVERY). Block changes near power
##   (note_block) are looked at again, at most FLUSH_PER_TICK cells a tick. Only near players: power only
##   changes where somebody tapped, stood or built.
## - Teleport pads (TeleportLinks): a checked touch (Session.smart_touch_requested) sends that player's own
##   game out on top of the partner pad (never into a wall), with a sparkle and a whoosh at both ends; the pad
##   they arrive on waits until they step off it. A lone pad or a blocked partner is said kindly.
## - Saved (WorldMeta.smart): the pad pairs, and the cells to look at again after loading (buttons still
##   pressed, plates stood on).
## Every peer: the clicks, door sounds and sparkles (RPCs). Nothing here makes or removes a block.

## Host: a player went through a pad (tests).
signal teleported(peer_id: int, from_pad: Vector3i, to_pad: Vector3i)

const CHECK_EVERY := 0.1
const FLUSH_PER_TICK := 64
const TELEPORT_COOLDOWN := 1.0
const LONE_PAD := "Place a second teleport pad to link with this one!"
const PAD_BLOCKED := "The other teleport pad is blocked!"
const SPARKLE := Color("5ee7ff")
const PLATE_EDGE := 0.21          # a foot on a plate's edge presses it (a body's radius × 0.7)

enum Sound { CLICK, DOOR_OPEN, DOOR_CLOSE, LAMP }

## Host: block_at(cell: Vector3i) -> int (tests use stubs).
var block_at: Callable = _world_block
## Host: area_ready(cell: Vector3i) -> bool: the blocks there are loaded.
var area_ready: Callable = func(_cell: Vector3i) -> bool: return true
## Host: power's changes (Session.power_set_blocks): returns the cells that must wait (someone in a doorway).
var set_blocks: Callable = func(changes: Array) -> Array[Vector3i]: return Session.power_set_blocks(changes)
## Host: tell(peer_id, text): a message for that player.
var tell: Callable = func(peer_id: int, text: String) -> void: Session.send_feedback(peer_id, text)
## Host: arrive(peer_id, exit): that player's own game comes out at `exit` (an RPC for a guest).
var arrive: Callable = _send_arrive
var links := TeleportLinks.new()

var _dirty := {}          # cell -> true: its consumer follows its power at the next flush
var _pressed := {}        # plate cell -> true: someone stands on it
var _buttons := {}        # pressed button cell -> seconds before it pops up
var _arrived := {}        # peer -> the pad they came out on (it waits until they step off)
var _cool := {}           # peer -> seconds before their next trip
var _check_t := 0.0
var _plate_memo := {}     # a body's quarter-block spot -> the plate under it (or null)


func _world_block(cell: Vector3i) -> int:
	return Session.world.get_block(cell) if Session.world else BlockIds.AIR


# --- Host: start, save ---------------------------------------------------------------------------------

## Host: a world's saved smart state (WorldMeta.smart); listens to the host's checked taps and touches.
func start(saved: Dictionary) -> void:
	links = TeleportLinks.from_save(saved.get("teleports"))
	for cell in SmartState.cells(saved.get("power")):
		if block_at.call(cell) == BlockIds.BUTTON_ON:
			_buttons[cell] = 0.0          # saved while pressed: it pops up at the first tick
		_mark_around(cell)
	if not Session.smart_tap_requested.is_connected(tap):
		Session.smart_tap_requested.connect(tap)
	if not Session.smart_touch_requested.is_connected(_on_touch):
		Session.smart_touch_requested.connect(_on_touch)


## {"teleports": pad pairs, "power": cells to look at again after loading}.
func to_save() -> Dictionary:
	var power: Array[Vector3i] = []
	for cell: Vector3i in _buttons:
		power.append(cell)
	for cell: Vector3i in _pressed:
		power.append(cell)
	return {"teleports": links.to_save(), "power": power}


func pressed_plates() -> Dictionary:
	return _pressed


# --- Host: power ---------------------------------------------------------------------------------------

## Host: every block change in the world (WorldService.block_changed).
func note_block(pos: Vector3i, old_id: int, new_id: int) -> void:
	if new_id == BlockIds.TELEPORT_PAD:
		links.add(pos)
	elif old_id == BlockIds.TELEPORT_PAD:
		links.remove(pos)
	if old_id == BlockIds.BUTTON_ON and new_id != BlockIds.BUTTON_ON:
		_buttons.erase(pos)
	if old_id == BlockIds.PRESSURE_PLATE and new_id != BlockIds.PRESSURE_PLATE:
		_pressed.erase(pos)
	if old_id == BlockIds.PRESSURE_PLATE or new_id == BlockIds.PRESSURE_PLATE:
		_plate_memo.clear()
	if PowerRules.matters(old_id, new_id):
		_mark_around(pos)


## Host (Session.smart_tap_requested, already checked): a tap on the switch at `cell`.
func tap(_peer_id: int, cell: Vector3i) -> bool:
	var id := int(block_at.call(cell))
	if not PowerRules.is_switch(id):
		return false
	var now := PowerRules.tapped(id)
	if now != id:
		set_blocks.call([[cell, now]])
	if now == BlockIds.BUTTON_ON:
		_buttons[cell] = PowerRules.BUTTON_TIME     # pressed again: its second starts again
	_mark_around(cell)
	flush()
	_rpc_sound.rpc(Vector3(cell) + Vector3(0.5, 0.5, 0.5), Sound.CLICK)
	return true


## Host: the consumers that may have lost or gained power follow it (at most `limit` cells).
func flush(limit: int = FLUSH_PER_TICK) -> void:
	if _dirty.is_empty():
		return
	var cells: Array = _dirty.keys().slice(0, limit)
	for cell: Vector3i in cells:
		_dirty.erase(cell)
		if not area_ready.call(cell):
			continue
		var changes := PowerRules.consumer_changes(cell, block_at, _pressed)
		if changes.is_empty():
			continue
		var waiting: Array[Vector3i] = set_blocks.call(changes)
		for w in waiting:
			_dirty[w] = true              # someone in the doorway: try again next tick
		if waiting.size() < changes.size():
			_play_change(changes)


func _mark_around(cell: Vector3i) -> void:
	_dirty[cell] = true
	for d in PowerRules.FACES:
		_dirty[cell + d] = true


func _play_change(changes: Array) -> void:
	var first: Array = changes[0]
	var at := Vector3(first[0]) + Vector3(0.5, 0.5, 0.5)
	match int(first[1]):
		BlockIds.POWERED_DOOR_OPEN:
			_rpc_sound.rpc(at, Sound.DOOR_OPEN)
		BlockIds.POWERED_DOOR:
			_rpc_sound.rpc(at, Sound.DOOR_CLOSE)
		BlockIds.LAMP_ON:
			_rpc_sound.rpc(at, Sound.LAMP)


func _process(delta: float) -> void:
	tick(delta)


## Host: buttons pop up, plates are looked at, trips cool down, and the dirty cells follow their power.
func tick(delta: float) -> void:
	if not multiplayer.is_server():
		return
	for cell: Vector3i in _buttons.keys():
		_buttons[cell] = float(_buttons[cell]) - delta
		if _buttons[cell] <= 0.0:
			_buttons.erase(cell)
			if block_at.call(cell) == BlockIds.BUTTON_ON:
				set_blocks.call([[cell, BlockIds.BUTTON]])
				_mark_around(cell)
	for peer: int in _cool.keys():
		_cool[peer] = float(_cool[peer]) - delta
		if _cool[peer] <= 0.0:
			_cool.erase(peer)
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = CHECK_EVERY
		_look_at_plates()
		_look_at_arrivals()
	flush()


## Host: the plates under every player's and bot friend's feet; a plate pressed or let go wakes its faces.
func _look_at_plates() -> void:
	var now := {}
	for feet in _standing_feet():
		var plate: Variant = _plate_under(feet)
		if plate != null:
			now[plate] = true
	for cell: Vector3i in now:
		if not _pressed.has(cell):
			_mark_around(cell)
	for cell: Vector3i in _pressed:
		if not now.has(cell):
			_mark_around(cell)
	_pressed = now


## Players (spawned, not knocked out) and bot friends that are up.
func _standing_feet() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and p.is_spawned() and not p.knocked_out and p.physics_mode != PhysicsMode.Mode.GHOST:
			out.append(p.global_position)
	for n in get_tree().get_nodes_in_group(&"bots"):
		var b := n as Node3D
		if b and not b.is_queued_for_deletion():
			out.append(b.global_position)
	return out


## The pressure plate under `feet` (a foot on its edge counts), or null. Remembered per quarter block (a
## plate placed or broken forgets), so a body standing still reads no blocks.
func _plate_under(feet: Vector3) -> Variant:
	var key := Vector3i(floori(feet.x * 4.0), floori(feet.y - 0.05), floori(feet.z * 4.0))
	if _plate_memo.has(key):
		return _plate_memo[key]
	if _plate_memo.size() > 256:
		_plate_memo.clear()
	var found: Variant = _find_plate(feet)
	_plate_memo[key] = found
	return found


func _find_plate(feet: Vector3) -> Variant:
	var y := floori(feet.y - 0.05)
	for c: Vector2 in [Vector2.ZERO, Vector2(PLATE_EDGE, PLATE_EDGE), Vector2(-PLATE_EDGE, PLATE_EDGE),
			Vector2(PLATE_EDGE, -PLATE_EDGE), Vector2(-PLATE_EDGE, -PLATE_EDGE)]:
		var cell := Vector3i(floori(feet.x + c.x), y, floori(feet.z + c.y))
		if block_at.call(cell) == BlockIds.PRESSURE_PLATE:
			return cell
	return null


# --- Host: teleport pads -------------------------------------------------------------------------------

func _on_touch(peer_id: int, id: int, cell: Vector3i, _left: bool) -> void:
	if id == BlockIds.TELEPORT_PAD:
		touch_pad(peer_id, cell)


## Host (a checked touch): `peer_id` stepped on the pad at `cell`: out on its partner, or kind words why not.
func touch_pad(peer_id: int, cell: Vector3i) -> bool:
	if _cool.has(peer_id) or _arrived.get(peer_id) == cell:
		return false
	var to: Variant = links.partner_of(cell)
	if to == null:
		tell.call(peer_id, LONE_PAD)
		return false
	if area_ready.call(to):
		if block_at.call(to) != BlockIds.TELEPORT_PAD:
			links.remove(to)              # gone without a word to this director (never expected)
			tell.call(peer_id, LONE_PAD)
			return false
		for dy in [1, 2]:
			if BlockIds.is_solid(int(block_at.call(to + Vector3i(0, dy, 0)))):
				tell.call(peer_id, PAD_BLOCKED)
				return false
	var exit := CourseRules.top_of(to)
	_arrived[peer_id] = to
	_cool[peer_id] = TELEPORT_COOLDOWN   # a guest's position reaches the host late: no second trip meanwhile
	arrive.call(peer_id, exit)
	_rpc_zap.rpc(CourseRules.top_of(cell), exit)
	teleported.emit(peer_id, cell, to)
	return true


## Host: someone who arrived on a pad and has stepped off it may use it again (after the cooldown).
func _look_at_arrivals() -> void:
	for peer: int in _arrived.keys():
		if _cool.has(peer):
			continue
		var p := Session._player_for_peer(peer)
		if p == null or not _on_pad(p.global_position, _arrived[peer]):
			_arrived.erase(peer)


static func _on_pad(feet: Vector3, pad: Vector3i) -> bool:
	return floori(feet.y - 0.05) == pad.y and Vector2(feet.x - pad.x - 0.5, feet.z - pad.z - 0.5).length() < 1.0


func _send_arrive(peer_id: int, exit: Vector3) -> void:
	if peer_id == multiplayer.get_unique_id():
		_rpc_arrive(exit)
	else:
		_rpc_arrive.rpc_id(peer_id, exit)


## This game's player: out on the other pad (the terrain there may still be streaming in).
@rpc("authority", "call_remote", "reliable")
func _rpc_arrive(exit: Vector3) -> void:
	if not exit.is_finite():
		return
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and p.is_local and p.peer_id == multiplayer.get_unique_id():
			p.spawn_at(exit)
			return


@rpc("authority", "call_local", "reliable")
func _rpc_zap(from: Vector3, to: Vector3) -> void:
	var root := get_tree().root
	for at: Vector3 in [from, to]:
		if at.is_finite():
			Audio.play(&"portal_whoosh", at, -3.0)
			Fx.burst(root, at + Vector3(0, 0.6, 0), SPARKLE, 16, 3.5, 0.1, 0.7, -1.0)


@rpc("authority", "call_local", "unreliable")
func _rpc_sound(at: Vector3, sound: int) -> void:
	if not at.is_finite():
		return
	match sound:
		Sound.CLICK:
			Audio.play(&"plate_click", at)
		Sound.DOOR_OPEN:
			Audio.play(&"door_open", at)
		Sound.DOOR_CLOSE:
			Audio.play(&"door_close", at)
		Sound.LAMP:
			Audio.play(&"ding", at, -10.0)
