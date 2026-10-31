class_name NakamaLink
extends Node
## One game's connection to the Nakama server (M4 early spike, spec §7.1-7.3). It signs in with
## this install's device id, opens the realtime socket, then creates or joins a relayed match. The
## match's NakamaMultiplayerBridge is an ordinary MultiplayerPeer, so Session runs the whole game
## over it unchanged: the host is still peer 1 and decides everything, and Nakama only relays.
## Every step returns "" or why it failed, and gives up after TIMEOUT_SEC.
##
## Uses the official client in addons/com.heroiclabs.nakama without its autoload: the Nakama.gd
## factory (and the HTTP and socket adapters it makes) live under this node, so nothing of Nakama
## loads or runs unless a game goes online. Session loads this script with load(), never by name.

## The realtime socket closed: the server went away, the network dropped, or leave() ran.
signal closed
## Owner #123: the online version check judged another game in the match (NetVersionCheck: SAME, NEWER, OLDER, or
## UNKNOWN when it never answered); Session acts on it (NetVersionCheck.action).
signal version_verdict(verdict: StringName, session_id: String)

const FACTORY_SCRIPT := "res://addons/com.heroiclabs.nakama/Nakama.gd"
const TIMEOUT_SEC := 5
## Godot's WebSocketPeer buffers are 64 KiB by default, for everything queued, and a message that
## does not fit is lost without a word (the socket adapter ignores send()'s error). The host queues a
## joining guest's whole world in one frame: 537 KB of pieces, 4/3 of that as base64 in JSON.
const SOCKET_BUFFER_BYTES := 4 << 20

## The WebSocket's buffers (set before sign_in; tests use small ones).
var socket_buffer_bytes := SOCKET_BUFFER_BYTES
var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var bridge: RelayBridge
## Relay traffic of this game: Godot packets (before pieces and base64) sent, in all and to each
## peer (sent_to: peer id -> bytes; a packet to everyone counts for each), the JSON bytes the socket
## took (wire_bytes), sends it refused (refused: kept and tried again), and match messages received
## (pieces count one each), for measurements.
var stats := {"sent": 0, "sent_bytes": 0, "max_sent": 0, "received": 0, "received_bytes": 0, "max_received": 0,
	"sent_to": {}, "wire_bytes": 0, "messages": 0, "refused": 0, "by_kind": {}}
## SceneMultiplayer's packet commands (the low 3 bits of a packet's first byte), for stats.by_kind.
const KINDS: Array[String] = ["rpc", "path", "path_ok", "raw", "spawn", "despawn", "sync", "sys"]

var _factory: Node
## Owner #123: this game's version for the check (NetVersionCheck.own_info(); Session may set another for a test run).
var own_version := {}
## The check, once this game has created or joined a match (null before).
var version_check: NetVersionCheck


## The HTTP status of the last failed sign-in (0: none): 404 is "no account has this device id" (owner #105).
var sign_in_status := 0


## Signs in (a new account the first time this device id is seen, unless `create` is false: owner #105, a device that
## had an account never makes a new one quietly) and opens the realtime socket.
func sign_in(server: Dictionary, device_id: String, create: bool = true) -> String:
	if not DeviceId.is_valid(device_id):
		return "sign-in: not a device id"
	_factory = (load(FACTORY_SCRIPT) as GDScript).new()
	_factory.name = "Nakama"
	add_child(_factory)
	client = _factory.create_client(OnlineConfig.key_for(server), server.host, int(server.port), server.scheme,   # the release server has its own key (M4 D)
		TIMEOUT_SEC, NakamaLogger.LOG_LEVEL.ERROR)
	session = await client.authenticate_device_async(device_id, null, create)
	await _settle()
	if session.is_exception():
		sign_in_status = session.get_exception().status_code
		return "sign-in: %s" % session.get_exception().message
	socket = _factory.create_socket_from(client)
	var ws: WebSocketPeer = socket._adapter._ws
	ws.inbound_buffer_size = socket_buffer_bytes
	ws.outbound_buffer_size = socket_buffer_bytes
	var res: NakamaAsyncResult = await socket.connect_async(session, false, TIMEOUT_SEC)
	await _settle()
	if res.is_exception():
		return "socket: %s" % res.get_exception().message
	# Over TLS each message's header and body go out apart and the body waited ~40 ms for the server's
	# ack (Nagle): steady ping 103 -> 21 ms (M4 D). It only takes effect once the socket is open. In a browser the
	# browser owns the socket ("not supported in Web export").
	if not OS.has_feature("web"):
		ws.set_no_delay(true)
	socket.closed.connect(closed.emit)
	socket.received_match_state.connect(_count_received)
	bridge = RelayBridge.new(socket)   # pieces, flow control, rejoin (net/relay_bridge.gd)
	bridge.stats = stats
	bridge.multiplayer_peer.packet_generated.connect(_count_sent)
	return ""


## A peer that is "connecting" and never connects: a guest uses it while it signs in, so it is
## never mistaken for the host (Session.is_host) before the relay is ready.
static func waiting_peer() -> MultiplayerPeer:
	var p := NakamaMultiplayerPeer.new()
	p.set_connection_status(MultiplayerPeer.CONNECTION_CONNECTING)
	return p


## Host: a new relayed match; this game becomes peer 1. Its id is match_id().
func create_match() -> String:
	if bridge == null:
		return "not signed in"
	var err: String = await _enter(bridge.create_match)
	if err == "":
		_start_version_check(true)
	return err


## Guest: joins the host's match; done when the host has given this game its peer id.
func join_match(id: String) -> String:
	if not OnlineConfig.is_match_id(id):
		return "join: not a match id"
	if bridge == null:
		return "not signed in"
	var err: String = await _enter(bridge.join_match.bind(id))
	if err == "":
		_start_version_check(false)
	return err


## Bytes on their way to the server: what RelayBridge holds back and the WebSocket still holds.
func backlog() -> int:
	return bridge.backlog() if bridge != null else 0


## The relay's flow control hands the socket what fits, every frame; the version check sends and judges.
func _process(delta: float) -> void:
	if bridge != null:
		bridge.flush()
	_version_tick(delta)


# --- Owner #123: the online version check (NetVersionCheck) ---------------------------------------------------------

func _start_version_check(hosting: bool) -> void:
	version_check = NetVersionCheck.new(own_version if not own_version.is_empty() else NetVersionCheck.own_info(),
		hosting)
	socket.received_match_state.connect(_version_heard)
	socket.received_match_presence.connect(_version_presence)
	if hosting:
		for id: String in bridge._users:   # anyone already in the match (none for a new one)
			if id != bridge._my_session_id:
				version_check.met(id)
	else:
		var host_session: Variant = bridge._id_map.get(1)
		if host_session is String:
			version_check.met(host_session)


func _version_tick(delta: float) -> void:
	if version_check == null or socket == null or not socket.is_connected_to_host() \
			or bridge.match_state != NakamaMultiplayerBridge.MatchState.CONNECTED:
		return
	if version_check.tick(delta):
		socket.send_match_state_async(bridge.match_id, NetVersionCheck.OP_CODE, version_check.payload())
	for id: String in version_check.overdue():
		version_verdict.emit(NetVersionCheck.UNKNOWN, id)


func _version_heard(data: NakamaRTAPI.MatchData) -> void:
	if version_check == null or data.op_code != NetVersionCheck.OP_CODE or data.match_id != bridge.match_id \
			or data.presence == null:
		return
	var verdict := version_check.heard(data.presence.session_id, data.data)
	if verdict != &"":
		version_verdict.emit(verdict, data.presence.session_id)


func _version_presence(event: NakamaRTAPI.MatchPresenceEvent) -> void:
	if version_check == null or event.match_id != bridge.match_id:
		return
	for p: NakamaRTAPI.UserPresence in event.joins:
		if version_check.hosting and p.session_id != bridge._my_session_id:
			version_check.met(p.session_id)
	for p: NakamaRTAPI.UserPresence in event.leaves:
		version_check.left(p.session_id)


func match_id() -> String:
	return bridge.match_id if bridge else ""


func peer() -> MultiplayerPeer:
	return bridge.multiplayer_peer if bridge else null


## Calls a server RPC (server/modules): its JSON answer as a Dictionary, or {"error": ...}.
func call_rpc(id: String, payload: String = "") -> Dictionary:
	var r: NakamaAPI.ApiRpc = await client.rpc_async(session, id, payload)
	await _settle()
	if r.is_exception():
		return {"error": r.get_exception().message}
	var json := JSON.new()
	if json.parse(r.payload) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"error": "not a JSON object: %s" % r.payload}
	return json.data


## Leaves the match, closes the socket and frees this node. NakamaMultiplayerPeer has no _close()
## (Godot 4.7 requires one: MultiplayerPeer.close() on it is an engine error), so the multiplayer
## API must already use another peer.
func leave() -> void:
	if bridge != null and bridge.match_state == NakamaMultiplayerBridge.MatchState.CONNECTED \
			and socket.is_connected_to_host():   # (sending on a closed socket is an engine error)
		bridge.leave()   # tells the match; closing the socket would also end this presence
	if is_inside_tree():
		await get_tree().create_timer(0.2).timeout   # lets the leave message go out first
	if socket != null:
		socket.close()
	queue_free()


## Starts a join or create and waits for match_joined, match_join_error or the timeout.
func _enter(start: Callable) -> String:
	var state := {"done": false, "error": ""}
	var on_joined := func() -> void: state.done = true
	var on_error := func(e: Variant) -> void:
		state.error = str(e.message) if e is NakamaException else str(e)
		state.done = true
	bridge.match_joined.connect(on_joined)
	bridge.match_join_error.connect(on_error)
	start.call()
	var give_up := Time.get_ticks_msec() + TIMEOUT_SEC * 1000
	while not state.done and Time.get_ticks_msec() < give_up and is_inside_tree():
		await get_tree().process_frame
	if bridge != null:
		bridge.match_joined.disconnect(on_joined)
		bridge.match_join_error.disconnect(on_error)
	if not state.done:
		return "no answer from the match in %d s" % TIMEOUT_SEC
	return "match: %s" % state.error if state.error != "" else ""


## The client's awaits resume inside its HTTPRequest's or socket's signal; one frame later the
## caller may free this node at once (freeing it inside that signal is an engine error).
func _settle() -> void:
	if is_inside_tree():
		await get_tree().process_frame


func _count_sent(peer_id: int, buffer: PackedByteArray) -> void:
	stats.sent += 1
	stats.sent_bytes += buffer.size()
	stats.max_sent = maxi(stats.max_sent, buffer.size())
	if buffer.size() > 0:   # SceneMultiplayer's command in the first byte (rpc, spawn, sync, ...)
		var kind: String = KINDS[buffer[0] & 7]
		stats.by_kind[kind] = int(stats.by_kind.get(kind, 0)) + buffer.size()
	var to: Dictionary = stats.sent_to
	var mine := bridge.multiplayer_peer.get_unique_id()
	for id: int in ([peer_id] if peer_id > 0 else bridge._id_map.keys()):
		if id != mine:
			to[id] = int(to.get(id, 0)) + buffer.size()


func _count_received(data: NakamaRTAPI.MatchData) -> void:
	var size := data.base64_data.length() * 3 / 4
	stats.received += 1
	stats.received_bytes += size
	stats.max_received = maxi(stats.max_received, size)
