class_name PowerRules
extends RefCounted
## Smart blocks' power (M3 Task 7, spec §14.4), kid-simple: power is ONE step. A source — a pressed button
## (for BUTTON_TIME), a lever or light switch that is on, a pressure plate someone stands on — powers the
## blocks touching its six faces. A powered door opens while powered (its whole stack of up to
## MAX_DOOR_STACK, like M2's doorways), a lamp lights. Nothing a source powers passes power on: no chains,
## no wires, no logic. Pure: the host's SmartDirector applies what these rules say.

const BUTTON_TIME := 1.0
const MAX_DOOR_STACK := 3
const MAX_TOGGLES_PER_SECOND := 5
const FACES: Array[Vector3i] = [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP, Vector3i.DOWN, Vector3i.BACK,
	Vector3i.FORWARD]

## What a tap does to a switch.
const _TAPPED := {BlockIds.BUTTON: BlockIds.BUTTON_ON, BlockIds.BUTTON_ON: BlockIds.BUTTON_ON,
	BlockIds.LEVER: BlockIds.LEVER_ON, BlockIds.LEVER_ON: BlockIds.LEVER,
	BlockIds.LIGHT_SWITCH: BlockIds.LIGHT_SWITCH_ON, BlockIds.LIGHT_SWITCH_ON: BlockIds.LIGHT_SWITCH}
const _SOURCES: Array[int] = [BlockIds.BUTTON_ON, BlockIds.LEVER_ON, BlockIds.LIGHT_SWITCH_ON]
## consumer -> [off, on]
const _CONSUMERS := {BlockIds.POWERED_DOOR: [BlockIds.POWERED_DOOR, BlockIds.POWERED_DOOR_OPEN],
	BlockIds.POWERED_DOOR_OPEN: [BlockIds.POWERED_DOOR, BlockIds.POWERED_DOOR_OPEN],
	BlockIds.LAMP: [BlockIds.LAMP, BlockIds.LAMP_ON], BlockIds.LAMP_ON: [BlockIds.LAMP, BlockIds.LAMP_ON]}
## An on state is the same item as its plain block (what breaking it gives, what an undo gives back).
const _ITEM_OF := {BlockIds.BUTTON_ON: BlockIds.BUTTON, BlockIds.LEVER_ON: BlockIds.LEVER,
	BlockIds.LIGHT_SWITCH_ON: BlockIds.LIGHT_SWITCH, BlockIds.LAMP_ON: BlockIds.LAMP,
	BlockIds.POWERED_DOOR_OPEN: BlockIds.POWERED_DOOR}


## A block a tap switches (buttons, levers, light switches).
static func is_switch(id: int) -> bool:
	return _TAPPED.has(id)


## The block a tap makes of `id` (itself when a tap does nothing).
static func tapped(id: int) -> int:
	return _TAPPED.get(id, id)


## Does a block of `id` give power? `pressed`: a plate someone stands on.
static func gives_power(id: int, pressed: bool) -> bool:
	return _SOURCES.has(id) or (id == BlockIds.PRESSURE_PLATE and pressed)


static func is_consumer(id: int) -> bool:
	return _CONSUMERS.has(id)


static func is_door(id: int) -> bool:
	return id == BlockIds.POWERED_DOOR or id == BlockIds.POWERED_DOOR_OPEN


## The item a block is (an on state is its plain block's item).
static func item_of(id: int) -> int:
	return _ITEM_OF.get(id, id)


## A change from `old` to `new` can change what is powered around it.
static func matters(old: int, new: int) -> bool:
	for id in [old, new]:
		if is_consumer(id) or _SOURCES.has(id) or id == BlockIds.PRESSURE_PLATE:
			return true
	return false


## Does one of `cell`'s six faces touch a source giving power? pressed: {plate cell: true}.
static func is_powered(cell: Vector3i, block_at: Callable, pressed: Dictionary) -> bool:
	for d in FACES:
		var n := cell + d
		if gives_power(int(block_at.call(n)), pressed.has(n)):
			return true
	return false


## The powered doors stacked with the one at `pos`, bottom up (at most MAX_DOOR_STACK, always holding it).
static func door_stack(pos: Vector3i, block_at: Callable) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if not is_door(int(block_at.call(pos))):
		return out
	var bottom := pos
	while pos.y - bottom.y < MAX_DOOR_STACK - 1 and is_door(int(block_at.call(bottom + Vector3i.DOWN))):
		bottom += Vector3i.DOWN
	var cell := bottom
	while out.size() < MAX_DOOR_STACK and is_door(int(block_at.call(cell))):
		out.append(cell)
		cell += Vector3i.UP
	return out


## What makes the consumer at `cell` (a doorway: all of it) follow its power: [[cell, id], ...] (empty when
## it already does, or when `cell` holds no consumer).
static func consumer_changes(cell: Vector3i, block_at: Callable, pressed: Dictionary) -> Array:
	var id := int(block_at.call(cell))
	if not is_consumer(id):
		return []
	var cells: Array[Vector3i] = [cell]
	if is_door(id):
		cells = door_stack(cell, block_at)
	var on := false
	for c in cells:
		if is_powered(c, block_at, pressed):
			on = true
			break
	var out := []
	for c in cells:
		var now := int(block_at.call(c))
		var want: int = _CONSUMERS[now][1 if on else 0]
		if want != now:
			out.append([c, want])
	return out


## At most `limit` accepted taps in any second, per player (the host keeps one per player).
class TapLimiter:
	extends RefCounted
	var limit := MAX_TOGGLES_PER_SECOND
	var _times: Array[int] = []

	func _init(per_second: int = MAX_TOGGLES_PER_SECOND) -> void:
		limit = per_second

	## True (and counted) when a tap at `now_ms` is allowed.
	func allow(now_ms: int) -> bool:
		while not _times.is_empty() and now_ms - _times[0] >= 1000:
			_times.pop_front()
		if _times.size() >= limit:
			return false
		_times.append(now_ms)
		return true
