class_name VrPoseLink
extends Node
## Owner #101 (VR on the Meta Quest, P4): how a VR player's pose (Player.vr_pose, VrPoseRules' 21 bytes) reaches the
## other games, without touching the player's sync. Every Player has one, named "VrPoseLink", on every game.
## A game that shows another player asks that player's own game for its poses once (listen: a reliable RPC to the
## player's authority); the owner sends its pose to those who asked, 20 times a second while it changes and a keepalive
## each second (an unreliable ordered RPC), and one empty pose when the headset goes. An older build has no such node
## and never asks, so it is never sent anything it could misread (the old-peer net test: a sync property added to the
## Player broke every packet an older game sent to a newer one: "Invalid packet received. Size too small").

const NODE_NAME := "VrPoseLink"
const MAX_BYTES := 64
const KEEPALIVE := 1.0
## One 0 byte: "no pose" (VrPoseRules.decode reads it as none).
const NO_POSE_BYTE := 0

var player: Player
## The peers that asked for this player's poses (on its own game).
var listeners := {}
## Poses sent and received (tests, the net test's bandwidth).
var sent := 0
var received := 0

var _t := 0.0
var _last_sent := PackedByteArray()
var _since := 0.0
var _asked := false


func _init(p: Player = null) -> void:
	name = NODE_NAME
	player = p


func _ready() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.peer_disconnected.connect(_on_peer_gone)


func _process(delta: float) -> void:
	step(delta)


## One frame: a shown player's game asks once; the owner's game sends to whoever asked.
func step(delta: float) -> void:
	if not is_instance_valid(player) or not multiplayer.has_multiplayer_peer():
		return
	var owner_id := player.get_multiplayer_authority()
	var me := multiplayer.get_unique_id()
	if owner_id != me:
		if not _asked and owner_id in multiplayer.get_peers():
			_asked = true
			_listen.rpc_id(owner_id)
		return
	_t += delta
	_since += delta
	if listeners.is_empty() or _t < 1.0 / VrPoseRules.HZ:
		return
	_t = 0.0
	var pose := player.vr_pose
	if pose == _last_sent and (pose.is_empty() or _since < KEEPALIVE):
		return
	_last_sent = pose
	_since = 0.0
	var peers := multiplayer.get_peers()
	# never an empty array (Godot's RPC encoding sent it as no argument at all: "expected 1 argument(s), but called
	# with 0" on the receiving game); one 0 byte says "no pose"
	var out := pose if not pose.is_empty() else PackedByteArray([NO_POSE_BYTE])
	for id: int in listeners.keys():
		if id in peers:
			_pose.rpc_id(id, out)
			sent += 1
		else:
			listeners.erase(id)


@rpc("any_peer", "call_remote", "reliable")
func _listen() -> void:
	if is_instance_valid(player) and player.get_multiplayer_authority() == multiplayer.get_unique_id():
		listeners[multiplayer.get_remote_sender_id()] = true
		_last_sent = PackedByteArray([255])   # the newcomer gets the pose at once


@rpc("authority", "call_remote", "unreliable_ordered")
func _pose(bytes: PackedByteArray) -> void:
	if not is_instance_valid(player) or bytes.size() > MAX_BYTES:
		return
	received += 1
	player.vr_pose = bytes if bytes.size() >= VrPoseRules.SIZE else PackedByteArray()


func _on_peer_gone(id: int) -> void:
	listeners.erase(id)
