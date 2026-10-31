extends GutTest
## M4 Task 10 review: RelayBridge gathers a frame's small packets for one target and sends them at the end of the
## frame. When that target left the match in between (its leave came before the end of the frame), the run was
## sent with no presences, which Nakama relays to EVERY other player: a packet the host meant for one guest (its
## inventory, its gold, where it comes back) reached the others, whose games ran it as the host's. A run for a
## player who is gone is dropped instead. No server: a bridge on a socket that never connects, its match state set
## by hand.

const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."

var adapter: NakamaSocketAdapter
var bridge: RelayBridge


func before_each() -> void:
	adapter = NakamaSocketAdapter.new()
	add_child_autofree(adapter)
	bridge = RelayBridge.new(NakamaSocket.new(adapter, "127.0.0.1", 7350, "ws"))
	bridge._match_state = NakamaMultiplayerBridge.MatchState.CONNECTED
	bridge._match_id = MATCH
	bridge._my_peer_id = 1
	for p: Array in [["s-host", "u-host", 1], ["s-ann", "u-ann", 2], ["s-bob", "u-bob", 3]]:
		var presence := NakamaRTAPI.UserPresence.new()
		presence.session_id = p[0]
		presence.user_id = p[1]
		var user := NakamaMultiplayerBridge.User.new(presence)
		user.peer_id = p[2]
		bridge._users[p[0]] = user
		bridge._id_map[p[2]] = p[0]
	bridge._my_session_id = "s-host"


## The bridge's own end-of-frame flush is still due (call_deferred) when a test ends: the bridge goes first, so it
## never reaches the socket's adapter, which the test frees (a live bridge would read the freed adapter's socket).
func after_each() -> void:
	bridge._nakama_socket = null   # its flush stops at "no socket"
	bridge = null


func _leaves(session_id: String, user_id: String) -> void:
	var event := NakamaRTAPI.MatchPresenceEvent.create(NakamaRTAPI, {"match_id": MATCH, "joins": [],
		"leaves": [{"session_id": session_id, "user_id": user_id}]})
	bridge._on_nakama_socket_received_match_presence(event)


func _queued() -> Array[Dictionary]:
	return bridge._queue._items


func test_a_frames_packets_for_a_guest_who_left_meanwhile_go_to_nobody() -> void:
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([1, 2, 3]))   # for Ann only
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([4, 5]))
	_leaves("s-ann", "u-ann")   # Ann's phone drops before the end of the frame
	bridge._end_of_frame()
	for m in _queued():
		assert_not_null(m.targets, "never sent to everyone (Bob would run Ann's packets as the host's)")
	assert_eq(_queued().size(), 0, "Ann is gone: her packets go nowhere")


func test_a_frames_packets_for_a_guest_still_here_go_to_that_guest_only() -> void:
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([1, 2, 3]))
	_leaves("s-bob", "u-bob")   # someone else leaves
	bridge._end_of_frame()
	assert_eq(_queued().size(), 1)
	assert_not_null(_queued()[0].targets, "Ann's packet names Ann")
	var json: Dictionary = JSON.parse_string((_queued()[0].bytes as PackedByteArray).get_string_from_utf8())
	assert_eq(str(json.match_data_send.presences[0].session_id), "s-ann")


func test_packets_for_everyone_still_go_to_everyone() -> void:
	bridge._on_multiplayer_peer_packet_generated(0, PackedByteArray([7]))
	_leaves("s-ann", "u-ann")
	bridge._end_of_frame()
	assert_eq(_queued().size(), 1)
	assert_null(_queued()[0].targets)


# --- The M4 Task 10 review's finding H: the "only other player" shortcut and a join ---
# A packet for the only other player goes without presences (about 300 bytes saved: Nakama relays it to everyone
# else, the same player). When a third player joins while such a message still waits (this frame's run, or the
# RelayQueue while flow control holds it), the host tells the newcomer who is who at once (the addon's
# _host_add_peer writes straight to the socket), so the waiting message goes after that and reaches the newcomer
# too: its game would run a packet meant for Ann (her inventory, gold, rejoin spot) as the host's. Now a join first
# names the players such waiting messages were made for.

## The socket for these tests: the addon's own messages to a joining player (CLAIM_HOST, ASSIGN_PEER_ID) are recorded
## instead of written to a WebSocket that never connected.
class RecordingSocket:
	extends NakamaSocket
	var sent: Array[Dictionary] = []

	func send_match_state_async(p_match_id, p_op_code: int, p_data: String, p_presences = null):
		sent.append({"match_id": p_match_id, "op": p_op_code, "data": p_data, "presences": p_presences})


## Only the host and Ann in the match, the bridge on a recording socket.
func _host_and_ann() -> RecordingSocket:
	var socket := RecordingSocket.new(adapter, "127.0.0.1", 7350, "ws")
	var users: Dictionary = bridge._users
	var ids: Dictionary = bridge._id_map
	bridge = RelayBridge.new(socket)
	bridge._match_state = NakamaMultiplayerBridge.MatchState.CONNECTED
	bridge._match_id = MATCH
	bridge._my_peer_id = 1
	bridge._my_session_id = "s-host"
	for s: String in ["s-host", "s-ann"]:
		bridge._users[s] = users[s]
		bridge._id_map[(users[s] as NakamaMultiplayerBridge.User).peer_id] = s
	assert_true(bridge._only_other(2), "Ann is the only other player")
	return socket


func _joins(session_id: String, user_id: String) -> void:
	var event := NakamaRTAPI.MatchPresenceEvent.create(NakamaRTAPI, {"match_id": MATCH, "leaves": [],
		"joins": [{"session_id": session_id, "user_id": user_id}]})
	bridge._on_nakama_socket_received_match_presence(event)


func _presence_sessions(m: Dictionary) -> Array:
	var json: Dictionary = JSON.parse_string((m.bytes as PackedByteArray).get_string_from_utf8())
	var out: Array = []
	for p: Dictionary in json.match_data_send.get("presences", []):
		out.append(str(p.session_id))
	return out


func test_a_frames_packets_for_the_only_other_player_stay_hers_when_someone_joins() -> void:
	var socket := _host_and_ann()
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([1, 2, 3]))   # for Ann: no presences (the shortcut)
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([4, 5]))
	_joins("s-bob", "u-bob")   # Bob joins before the end of the frame
	assert_false(socket.sent.is_empty(), "the host told Bob who is who at once, before the frame's packets")
	bridge._end_of_frame()
	assert_eq(_queued().size(), 1)
	assert_not_null(_queued()[0].targets, "Ann's packets name Ann: Bob would run them as the host's")
	assert_eq(_presence_sessions(_queued()[0]), ["s-ann"])
	assert_string_contains((_queued()[0].bytes as PackedByteArray).get_string_from_utf8(),
		"\"op_code\":%d" % RelayBridge.BATCH_OP_CODE, "still one batch")


func test_messages_held_for_the_only_other_player_stay_hers_when_someone_joins() -> void:
	_host_and_ann()
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([1, 2, 3]))
	bridge._end_of_frame()   # queued: the socket's buffer has no room (flow control holds it)
	assert_eq(_queued().size(), 1)
	assert_null(_queued()[0].targets, "while Ann is the only other player it needs no presence")
	_joins("s-bob", "u-bob")
	assert_eq(_queued().size(), 1)
	assert_not_null(_queued()[0].targets, "it names Ann before Bob could get it")
	assert_eq(_presence_sessions(_queued()[0]), ["s-ann"])
	var text := (_queued()[0].bytes as PackedByteArray).get_string_from_utf8()
	assert_string_contains(text, "\"op_code\":%d" % bridge.rpc_op_code, "the same op code, as a whole number")
	var json: Dictionary = JSON.parse_string(text)
	assert_eq(Marshalls.base64_to_raw(str(json.match_data_send.data)), PackedByteArray([1, 2, 3]), "the same packet")
	assert_eq(int(_queued()[0].wire), (_queued()[0].bytes as PackedByteArray).size(), "its size on the wire")
	assert_eq(bridge._queue.held_bytes(), int(_queued()[0].wire), "the held count follows")


func test_after_a_join_new_packets_name_their_player() -> void:
	_host_and_ann()
	_joins("s-bob", "u-bob")
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([9]))
	bridge._end_of_frame()
	assert_eq(_presence_sessions(_queued().back()), ["s-ann"], "three players: no shortcut")


func test_a_held_message_whose_players_all_left_goes_to_nobody_at_a_join() -> void:
	_host_and_ann()
	bridge._on_multiplayer_peer_packet_generated(2, PackedByteArray([1, 2, 3]))
	bridge._end_of_frame()
	_leaves("s-ann", "u-ann")
	_joins("s-bob", "u-bob")
	for m in _queued():
		assert_not_null(m.targets, "never to everyone: only Bob is left, and it was not for him")
	assert_eq(_queued().size(), 0)
