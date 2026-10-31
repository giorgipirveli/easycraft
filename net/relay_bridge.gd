class_name RelayBridge
extends NakamaMultiplayerBridge
## NakamaMultiplayerBridge for our relayed matches (M4 early spike, M4 Wave 1 A). The addon stays
## unmodified: this overrides the bridge's packet handlers (its _init connects them by name) and two
## helpers of its peer ids.
## - Big packets go in pieces (spike): Nakama closes a session that sends one message over
##   socket.max_message_size_bytes. Packets up to RelayPieces.PIECE_BYTES go as they are; bigger ones
##   go as RelayPieces on their own op code and the receiving bridge puts them back together.
## - Flow control (Wave 1 A): every outgoing message waits in a RelayQueue and the WebSocket gets
##   only what fits in its buffer, in order; the socket's answer is checked (Godot's WebSocketPeer
##   refuses a message that does not fit, and the client's _send_async ignored that: the message was
##   lost). A refused message stays first in line. NakamaLink flushes the queue every frame.
##   Messages are written here as the client would (a match_data_send envelope, without a request id:
##   nothing answers them), which also skips the client's per-message debug string (spike risk 3).
## - Batches (Wave 1 A): every relay message carries a JSON envelope of about 300 bytes (match id, op
##   code, the target's presence), several times a position update. Consecutive small packets for the
##   same target within one frame go as one RelayBatch message (sent at the end of the frame, so no
##   packet waits longer than that frame); a packet for the only other
##   player in the match goes without the presence (to everyone else: the same player). Order is kept:
##   a packet for another target, or a big one, ends the run first. (M4 Task 10 review H) A join first names the
##   players every waiting "everyone else" message was made for, so the newcomer never gets one meant for another.
## - Rejoin (Wave 1 A): the host gives a player who comes back (the same Nakama account) the peer id
##   it had, so the host's game goes on with the same player; a new connection of a player whose old
##   one the server has not dropped yet replaces it (the old one's late leave then changes nothing).

const PIECE_OP_CODE := 9003   # the bridge's own op codes are 9001 (meta) and 9002 (packets)
const BATCH_OP_CODE := 9004
const BATCH_BYTES := 16 * 1024

## Counters shared with NakamaLink.stats: wire_bytes (JSON as sent), messages (relay messages sent),
## refused (sends the socket refused).
var stats := {"wire_bytes": 0, "messages": 0, "refused": 0}
## Tests: free bytes in the socket's buffer (default: the WebSocket's own).
var room_of: Callable

var _assembler := RelayPieces.Assembler.new()
var _queue := RelayQueue.new()
var _peer_of_user := {}   # user id -> the peer id that account had in this match
var _run := PackedByteArray()   # RelayBatch of the packets waiting for the tick
var _run_count := 0
var _run_target := -1           # their target: a peer id, 0 = everyone else, -1 = no run
var _flush_pending := false
var _presence_json := {}  # peer id -> its presence, serialized once


func _on_multiplayer_peer_packet_generated(peer_id: int, buffer: PackedByteArray) -> void:
	if match_state != MatchState.CONNECTED:
		super(peer_id, buffer)   # (its error: sent while not connected)
		return
	if peer_id > 0 and not _id_map.has(peer_id):
		push_error("RelayBridge: a packet for unknown peer %d" % peer_id)
		return
	var target := peer_id if peer_id > 0 and not _only_other(peer_id) else 0
	if buffer.size() > RelayPieces.PIECE_BYTES:
		_end_run()
		var targets: Variant = _targets(target) if target > 0 else null
		for piece in RelayPieces.split(buffer):
			_enqueue(PIECE_OP_CODE, piece, targets)
		flush()
		return
	if target != _run_target or _run.size() + buffer.size() + 2 > BATCH_BYTES:
		_end_run()
		_run_target = target
	_run = RelayBatch.add(_run, buffer)
	_run_count += 1
	if not _flush_pending:
		_flush_pending = true
		_end_of_frame.call_deferred()


## At the end of the frame the packets of the last run go, and the socket gets what fits.
func _end_of_frame() -> void:
	_flush_pending = false
	_end_run()
	flush()


## Hands the socket what fits (NakamaLink calls it every frame too).
func flush() -> void:
	if _queue.size() == 0 or _nakama_socket == null:
		return
	var ws: WebSocketPeer = _nakama_socket._adapter._ws
	_queue.flush(_room if not room_of.is_valid() else room_of, _send_now, ws.outbound_buffer_size)


## Bytes waiting here and in the WebSocket's buffer.
func backlog() -> int:
	var ws: WebSocketPeer = _nakama_socket._adapter._ws if _nakama_socket != null else null
	return _run.size() + _queue.held_bytes() + (ws.get_current_outbound_buffered_amount() if ws != null else 0)


## The packets of this tick go into the queue: one alone as it is, several as one batch.
func _end_run() -> void:
	# M4 Task 10 review: a run for a player who left before the end of the frame goes nowhere. Without presences
	# Nakama relays a message to every other player, whose games would run that player's packets as the host's.
	if _run_count > 0 and _run_target > 0 and not _id_map.has(_run_target):
		_run_count = 0
	if _run_count > 0:
		var targets: Variant = _targets(_run_target) if _run_target > 0 else null
		if _run_count == 1:
			_enqueue(rpc_op_code, _run.slice(2), targets)
		else:
			_enqueue(BATCH_OP_CODE, _run, targets)
	_run = PackedByteArray()
	_run_count = 0
	_run_target = -1


## The target is the only other player in the match: sending to everyone else is the same, and the
## message needs no presence.
func _only_other(peer_id: int) -> bool:
	return _users.size() == 2 and _id_map.has(peer_id) and _users.has(_id_map[peer_id])


## A message for "everyone else" (no targets) remembers who that was and its packet, so a join can name them.
func _enqueue(op: int, bytes: PackedByteArray, targets: Variant) -> void:
	var json := _envelope(op, bytes, targets)
	_queue.push(op, json, targets, json.size(), {"payload": bytes, "audience": _others()} if targets == null else {})


func _envelope(op: int, bytes: PackedByteArray, targets: Variant) -> PackedByteArray:
	var body := {"match_id": _match_id, "op_code": op, "data": Marshalls.raw_to_base64(bytes)}
	if targets != null:
		body["presences"] = targets
	return JSON.stringify({"match_data_send": body}).to_utf8_buffer()


## The other players' peer ids in the match now.
func _others() -> Array[int]:
	var out: Array[int] = []
	for pid: int in _id_map:
		if pid != _my_peer_id and pid > 0:
			out.append(pid)
	return out


## The M4 Task 10 review H: before a join, this frame's packets go into the queue and every waiting message for
## "everyone else" names the players it was made for (those still here; nobody left: it goes nowhere). Such a
## message was made while fewer players were here, often by the only-other-player shortcut, and the addon tells the
## newcomer who is who straight away (_host_add_peer skips this queue), so it would reach the newcomer after that and
## its game would run a packet meant for someone else.
func _name_everyone_waiting() -> void:
	_end_run()
	_queue.retarget_everyone(func(m: Dictionary) -> Dictionary:
		var targets: Array = []
		for pid: int in m.get("audience", []):
			if _id_map.has(pid) and _users.has(_id_map[pid]):
				targets.append((_targets(pid) as Array)[0])
		if targets.is_empty():
			return {}
		var json := _envelope(int(m.op), m.payload, targets)
		return {"bytes": json, "targets": targets, "wire": json.size()})


func _room() -> int:
	var ws: WebSocketPeer = _nakama_socket._adapter._ws
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return 0
	return ws.outbound_buffer_size - ws.get_current_outbound_buffered_amount()


func _send_now(m: Dictionary) -> bool:
	if _nakama_socket._adapter.send(m.bytes) != OK:
		stats.refused += 1
		return false
	stats.wire_bytes += int(m.wire)
	stats.messages += 1
	return true


func _targets(peer_id: int) -> Array:
	if not _presence_json.has(peer_id):
		_presence_json[peer_id] = [NakamaSerializer.serialize(_users[_id_map[peer_id]].presence)]
	return _presence_json[peer_id]


func _on_nakama_socket_received_match_state(data: Variant) -> void:
	if data.op_code != PIECE_OP_CODE and data.op_code != BATCH_OP_CODE:
		super(data)
		return
	if match_state == MatchState.DISCONNECTED or data.match_id != _match_id:
		return
	var from: String = data.presence.session_id
	if not _users.has(from) or _users[from].peer_id == 0:
		return
	if data.op_code == BATCH_OP_CODE:
		for packet in RelayBatch.split(data.binary_data):
			_multiplayer_peer.deliver_packet(packet, _users[from].peer_id)
		return
	var whole := _assembler.add(from, data.binary_data)
	if not whole.is_empty():
		_multiplayer_peer.deliver_packet(whole, _users[from].peer_id)


func _on_nakama_socket_received_match_presence(event: Variant) -> void:
	if match_state != MatchState.DISCONNECTED and event.match_id == _match_id:
		if not event.joins.is_empty() and match_state == MatchState.CONNECTED:
			_name_everyone_waiting()   # M4 Task 10 review H: before the addon greets the newcomer
		for presence: Variant in event.leaves:
			_assembler.forget(presence.session_id)
			if _users.has(presence.session_id):
				_presence_json.erase(_users[presence.session_id].peer_id)
				_drop_unread(_users[presence.session_id].peer_id)
	super(event)


## Host: a player who comes back gets the peer id its account had.
func _generate_id(session_id: String) -> int:
	var user := _user_of(session_id)
	if user != "" and _peer_of_user.has(user):
		var old: int = _peer_of_user[user]
		var holder: Variant = _id_map.get(old)
		if holder == null or _user_of(holder) == user:
			return old
	return super(session_id)


## A peer id given to a new connection of the same player: the old connection is gone for good.
func _map_id_to_session(peer_id: int, session_id: String) -> void:
	var holder: Variant = _id_map.get(peer_id)
	if holder != null and holder != session_id and _users.has(holder):
		_users.erase(holder)
		_assembler.forget(holder)
		_presence_json.erase(peer_id)
		_drop_unread(peer_id)
		_multiplayer_peer.peer_disconnected.emit(peer_id)
	super(peer_id, session_id)
	var user := _user_of(session_id)
	if user != "":
		_peer_of_user[user] = peer_id


func _user_of(session_id: Variant) -> String:
	if session_id == null or not _users.has(session_id) or _users[session_id].presence == null:
		return ""
	return str(_users[session_id].presence.user_id)


## A leaving peer's packets that the multiplayer API has not read yet go with it; it would read them
## from a peer it no longer knows ("!connected_peers.has(sender)" errors on the host). ENet drops a
## gone peer's packets itself.
func _drop_unread(peer_id: int) -> void:
	var queue: Array = _multiplayer_peer._incoming_packets
	for i in range(queue.size() - 1, -1, -1):
		if queue[i].from == peer_id:
			queue.remove_at(i)
