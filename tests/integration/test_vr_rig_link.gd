extends GutTest
## Owner #101 (VR on the Meta Quest), P4: VrPoseLink, how a VR player's pose reaches the other games by RPC (never the
## player's sync, which an older build cannot read). Two games in one process, each its own fake MultiplayerAPI (the
## RPCs it makes are delivered to the same node path in the other game, as from that peer; a path the other game does
## not have is what an older build without the link is). The ENet side is the LAN net test's (tools/net_test.sh --vr,
## --old). Game A (peer 1) owns the player; game B (peer 7) shows it.

class FakeNet:
	extends MultiplayerAPIExtension
	var me := 1
	var peers: Array[int] = []
	var other: FakeNet
	var root: Node
	var sender := 0
	## [peer, method, args] of every RPC this game made.
	var sent: Array = []
	var _peer := OfflineMultiplayerPeer.new()

	func _get_multiplayer_peer() -> MultiplayerPeer:
		return _peer

	func _set_multiplayer_peer(_p: MultiplayerPeer) -> void:
		pass

	func _get_unique_id() -> int:
		return me

	func _get_peer_ids() -> PackedInt32Array:
		return PackedInt32Array(peers)

	func _get_remote_sender_id() -> int:
		return sender

	func _poll() -> Error:
		return OK

	func _object_configuration_add(_object: Object, _config: Variant) -> Error:
		return OK

	func _object_configuration_remove(_object: Object, _config: Variant) -> Error:
		return OK

	func _rpc(peer: int, object: Object, method: StringName, arguments: Array) -> Error:
		sent.append([peer, method, arguments.duplicate()])
		if other == null or peer != other.me or not peers.has(peer):
			return OK
		var there := other.root.get_node_or_null(root.get_path_to(object as Node))
		if there == null:
			return OK   # the other game has no such node (an older build)
		other.sender = me
		there.callv(method, arguments)
		other.sender = 0
		return OK

	func count(method: StringName) -> int:
		var n := 0
		for s: Array in sent:
			if s[1] == method:
				n += 1
		return n


var net_a: FakeNet
var net_b: FakeNet
var game_a: Node
var game_b: Node
var player_a: Player   # the player on its own game
var player_b: Player   # the same player shown on game B
var link_a: VrPoseLink
var link_b: VrPoseLink


func before_each() -> void:
	game_a = _game("GameA")
	game_b = _game("GameB")
	net_a = _net(game_a, 1, 7)
	net_b = _net(game_b, 7, 1)
	net_a.other = net_b
	net_b.other = net_a
	player_a = autofree(Player.new())
	player_b = autofree(Player.new())
	for p: Player in [player_a, player_b]:
		p.set_multiplayer_authority(1)
	link_a = _link(game_a, player_a)
	link_b = _link(game_b, player_b)


func after_each() -> void:
	get_tree().set_multiplayer(null, game_a.get_path())
	get_tree().set_multiplayer(null, game_b.get_path())


func _game(n: String) -> Node:
	var g := Node.new()
	g.name = n
	add_child_autofree(g)
	return g


func _net(game: Node, me: int, peer: int) -> FakeNet:
	var n := FakeNet.new()
	n.me = me
	n.peers = [peer]
	n.root = game
	get_tree().set_multiplayer(n, game.get_path())
	return n


func _link(game: Node, p: Player) -> VrPoseLink:
	var l := VrPoseLink.new(p)
	game.add_child(l)
	l.set_multiplayer_authority(1)
	l.set_process(false)
	return l


static func _pose(nod: float) -> PackedByteArray:
	return VrPoseRules.encode(Transform3D(Basis.from_euler(Vector3(nod, 0.0, 0.0)), Vector3(0, 1.6, 0)),
		Transform3D(Basis(), Vector3(-0.3, 1.1, -0.3)), Transform3D(Basis(), Vector3(0.3, 1.1, -0.3)), Vector4.ZERO,
		CameraRig.HEAD_HEIGHT, 1.0)


## `seconds` of both games' frames at 72 a second; `each(i)` before each frame.
func _run(seconds: float, each: Callable = Callable()) -> void:
	var frames := int(round(seconds * 72.0))
	for i in frames:
		if each.is_valid():
			each.call(i)
		for l: Variant in [link_a, link_b]:
			if is_instance_valid(l):   # (an older build's game has none)
				(l as VrPoseLink).step(1.0 / 72.0)


func test_the_showing_game_asks_once_and_gets_the_pose_20_times_a_second_while_it_changes() -> void:
	_run(1.0, func(i: int) -> void: player_a.vr_pose = _pose(0.01 * float(i)))
	assert_eq(net_b.count(&"_listen"), 1, "B asked A once")
	assert_true(link_a.listeners.has(7), "A knows B listens")
	assert_eq(net_a.count(&"_listen"), 0, "the owner never asks")
	assert_between(link_b.received, VrPoseRules.HZ - 2, VrPoseRules.HZ + 1, "20 a second while it changes")
	assert_eq(player_b.vr_pose, link_a._last_sent, "B shows A's last pose")
	assert_eq(player_b.vr_pose.size(), VrPoseRules.SIZE)


func test_a_still_pose_is_sent_once_then_a_keepalive_each_second() -> void:
	player_a.vr_pose = _pose(0.2)
	_run(3.0)
	assert_eq(player_b.vr_pose, player_a.vr_pose, "the newcomer gets it at once")
	assert_between(link_b.received, 3, 4, "then once a second (the keepalive)")


func test_the_headset_off_is_one_zero_byte_never_an_empty_array() -> void:
	player_a.vr_pose = _pose(0.2)
	_run(0.5)
	player_a.vr_pose = PackedByteArray()
	_run(2.0)
	assert_true(player_b.vr_pose.is_empty(), "B's copy has no pose: its VR body goes")
	var empties := 0
	var zero_bytes := 0
	for s: Array in net_a.sent:
		if s[1] == &"_pose":
			var bytes: PackedByteArray = (s[2] as Array)[0]
			empties += 1 if bytes.is_empty() else 0
			zero_bytes += 1 if bytes == PackedByteArray([VrPoseLink.NO_POSE_BYTE]) else 0
	assert_eq(empties, 0, "an empty array arrives as no argument at all: never sent")
	assert_eq(zero_bytes, 1, "one 'no pose', then quiet")


func test_an_older_game_without_the_link_is_never_sent_a_pose() -> void:
	link_b.free()   # B is an older build: no VrPoseLink under its player
	player_a.vr_pose = _pose(0.2)
	_run(2.0)
	assert_true(link_a.listeners.is_empty(), "nobody asked")
	assert_eq(net_a.count(&"_pose"), 0, "so nothing goes out")


func test_an_older_owner_is_asked_once_and_that_is_all() -> void:
	link_a.free()   # A (the owner) is an older build: B's one ask finds no node there
	_run(2.0)
	assert_eq(net_b.count(&"_listen"), 1, "asked once, never again")
	assert_true(player_b.vr_pose.is_empty())


func test_a_listener_that_left_is_dropped() -> void:
	player_a.vr_pose = _pose(0.2)
	_run(0.5)
	assert_true(link_a.listeners.has(7))
	net_a.peers = []   # B left
	player_a.vr_pose = _pose(0.4)
	_run(0.5)
	assert_false(link_a.listeners.has(7), "dropped at the next send")
	link_a.listeners[9] = true
	link_a._on_peer_gone(9)
	assert_false(link_a.listeners.has(9), "and when a peer goes")


func test_odd_bytes_are_never_a_pose() -> void:
	var long := PackedByteArray()
	long.resize(VrPoseLink.MAX_BYTES + 1)
	long.fill(7)
	link_b._pose(long)
	assert_true(player_b.vr_pose.is_empty(), "too long: dropped")
	link_b._pose(PackedByteArray([1, 2, 3]))
	assert_true(player_b.vr_pose.is_empty(), "too short to be a pose: none")
	link_b._pose(_pose(0.3))
	assert_eq(player_b.vr_pose.size(), VrPoseRules.SIZE)
