class_name PlaydateDirector
extends Node
## Buddy playdates (M4 Wave 3, agent I; research T4, spec §3a "Buddies meet friends' buddies"): node
## "Playdates" of the world scene on every game. The host decides at most 10 times a second
## (PlaydateRules): it tells each buddy in a playdate where to walk (Buddy.playdate_target; the buddies'
## own sync carries where they go), and sends every game the two moments to show, the wave and the
## dance, by one reliable RPC each (rare events, never a stream). Nothing is saved.

## The world scene's buddies (their parent).
var buddies_root: Node
var rules := PlaydateRules.new()
## Seconds since the world started (the rules' clock).
var clock := 0.0
## Moments shown on this game (tests): [kind, a, b].
var shown: Array = []

var _since := 0.0


func _physics_process(delta: float) -> void:
	clock += delta
	if not multiplayer.is_server() or buddies_root == null:
		return
	_since += delta
	if _since + 0.0001 < PlaydateRules.TICK:
		return
	_since = 0.0
	step()


## Host: one decision (the rules' step) for every buddy now.
func step() -> void:
	var list: Array = []
	var nodes := {}
	for b in buddies_root.get_children():
		if b is Buddy and not b.is_queued_for_deletion() and not (b as Buddy).visiting \
				and (b as Buddy).rider_peer == 0:   # M3 Task 20a: a ridden buddy carries its rider
			list.append({"name": String(b.name), "owner": (b as Buddy).owner_peer, "pos": (b as Buddy).global_position})
			nodes[String(b.name)] = b
	var r := rules.step(list, clock)
	for n: String in nodes:
		(nodes[n] as Buddy).playdate_target = r.targets.get(n, Vector3.INF)
	for e: Array in r.events:
		_rpc_moment.rpc(e[0], e[1], e[2])


@rpc("authority", "call_local", "reliable")
func _rpc_moment(kind: String, a: String, b: String) -> void:
	shown.append([kind, a, b])
	if buddies_root == null:
		return
	var ba := buddies_root.get_node_or_null(a) as Buddy
	var bb := buddies_root.get_node_or_null(b) as Buddy
	if ba == null or bb == null:
		return
	ba.face(bb.global_position)
	bb.face(ba.global_position)
	for buddy: Buddy in [ba, bb]:
		if kind == "dance":
			buddy.dance()
		else:
			buddy.wave()
