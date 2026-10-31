class_name RelayQueue
extends RefCounted
## Flow control for the relay (M4 Wave 1 A, spec §17.0). Godot's WebSocketPeer refuses a message that
## does not fit its outbound buffer, and the Nakama client ignores that error, so the message was lost
## without a word (the spike's risk 4; with RelayPieces a lost piece loses its packet, and every packet
## is a reliable RPC or sync: a desync). RelayBridge puts every outgoing message here and flush() hands
## the socket only what fits, in order: a message that does not fit, or that the socket refuses, stays
## first in line for the next frame. Nothing is dropped and nothing overtakes.

var refused := 0   # sends the socket refused (kept and tried again)
var _items: Array[Dictionary] = []   # {op, bytes, targets, wire}
var _held := 0


## Bytes a message of n payload bytes takes in the socket: base64 inside a JSON envelope.
static func wire_size(n: int, envelope: int) -> int:
	return 4 * ((n + 2) / 3) + envelope


## `extra`: more keys for the item (RelayBridge keeps what it needs to name a message's players later).
func push(op: int, bytes: PackedByteArray, targets: Variant, wire: int, extra: Dictionary = {}) -> void:
	var item := {"op": op, "bytes": bytes, "targets": targets, "wire": wire}
	item.merge(extra)
	_items.append(item)
	_held += wire


## The M4 Task 10 review H: every waiting message without targets ("everyone else") gets `rename.call(item)`: a
## {"bytes", "targets", "wire"} to send instead (order kept), or {} to drop it.
func retarget_everyone(rename: Callable) -> void:
	var kept: Array[Dictionary] = []
	for m in _items:
		if m.targets != null:
			kept.append(m)
			continue
		var r: Dictionary = rename.call(m)
		_held -= int(m.wire)
		if r.is_empty():
			continue
		m.bytes = r.bytes
		m.targets = r.targets
		m.wire = int(r.wire)
		_held += int(m.wire)
		kept.append(m)
	_items = kept


## Sends what fits: room() -> free bytes in the socket's buffer; send(message) -> whether the socket
## took it. capacity: the buffer's whole size, so one message bigger than it goes into an empty
## buffer (-1: unknown). Returns how many went.
func flush(room: Callable, send: Callable, capacity: int = -1) -> int:
	var n := 0
	while not _items.is_empty():
		var m: Dictionary = _items[0]
		var free: int = room.call()
		if int(m.wire) > free and not (capacity > 0 and free >= capacity):
			break
		if not send.call(m):
			refused += 1
			break
		_items.pop_front()
		_held -= int(m.wire)
		n += 1
	return n


func size() -> int:
	return _items.size()


## Bytes waiting here (estimated as on the wire).
func held_bytes() -> int:
	return _held


func clear() -> void:
	_items.clear()
	_held = 0
