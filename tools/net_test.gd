extends Node
## Two-instance multiplayer check over LAN or the Nakama relay (developer tool, --net-test user arg;
## M4 early spike). tools/net_test.sh starts both instances. main.gd adds this node as /root/NetTest
## on both, so it outlives the world scene and its RPCs have the same path everywhere.
##   host:  places C (blue) as soon as it stands in its world; the guest must see it (the guest
##          generates its world from the seed and gets the host's edits: M4 Wave 1 A); walks +X,
##          waits, walks back, once the guest says it is in the world (a starved guest saw a short
##          walk too late).
##   both:  the host places A (purple), the guest B (red); each waits to see both; each undoes its
##          own (the host after the guest has seen both); both must see A and B back to what was
##          there before (air, or a tree's leaves: undo restores), and C stay.
##   guest: RPC round trips to the host (ping) while its world streams in and again at the end,
##          its own edit's round trip, the host walking, and the blocks around the spawn equal the
##          host's (a checksum the host sends).
## Then (M4 Wave 1 A) the guest plays PLAY_SECONDS (walks a circle; the host places a block now and
## then) and the host reports what it sent the guest meanwhile. With --net-test-fly the guest then
## flies FLY_SECONDS along +X and the host reports the same: the cost of the world for a moving guest.
## With --net-test-drop=close|dead (online) the guest's link drops after the checks: `close` closes it
## (the server sees the guest go at once), `dead` abandons it open (the server still has the old
## connection when the guest comes back: the host swaps it). The guest must rejoin within
## RejoinRules.WINDOW at the place its player waited, and see the block D the host placed meanwhile.
## With --net-test-drop=never (M4 Wave 2 A2) the guest's link closes and it never gets back in (its
## tries do nothing): after the window it must give up, show the goodbye words and reach the menu;
## the host must let its player go. Times are wall-clock (a long frame is clamped in `delta`).
## The guest prints its join time broken down (ms since its sandbox started: signed in, socket open,
## joined the match, world info, its world made, its player arrived from the host, standing), for the
## first join and for a rejoin.
## With --net-test-crew (spec §21d.9, crew flights) the checks above give way to a crew flight: the host's LAUNCH with
## the crew rocket on its pad, the guest's seat, both flights, both in the host's Moon world, the guest's mission and
## badge, HOME together (and with --net-test-drop=close the guest's link drops mid-flight: back on board). See _crew_*.
## Prints NETTEST <role> <event> lines (and every refusal and undo step the host sends), then
## NETTEST <role> result PASS|FAIL <reasons>, and quits with exit code 0 (pass) or 1. It prints the
## traffic too: the relay's (NakamaLink.stats: Godot packets) or ENet's (bytes on the wire).

const TIMEOUT := 180.0
const SETTLE := 3.0           # after both players stand in the world, before the edits
const PINGS := 20
const BOX := Vector3i(24, 16, 24)   # the checksum box around the spawn column
const FLY_SECONDS := 10.0
const FLY_SPEED := 15.0             # m/s: between normal flight (Player.FLY_SPEED 11) and a giant's (18.7)
const PLAY_SECONDS := 10.0

var _host := true          # decided when the world scene appears (Game.net_mode is set later)
var _role := "?"
var _t := 0.0
var _done := {}          # check name -> true once it passed
var _both_since := -1.0
var _placed := false
## A and B cell -> its block before the edits (what undo must bring back). The host reads them when
## the guest arrives, before anyone places, and sends them (a guest's chunks may not be there yet).
var _before := {}
var _place_ms := 0
var _undone := false
var _guest_saw_both := false
var _c_placed := false
var _walk_t := -1.0
var _remote_first := Vector3.INF
var _remote_moved := 0.0
var _pings_sent := 0
var _next_ping := 0.0
var _rtts: Array[float] = []          # while the guest's world streams in, just after joining
var _rtts_steady: Array[float] = []   # at the end, with little else on the wire
var _host_sum := -1
var _asked_sum := -1.0
var _guest_finished := false
var _guest_here := false
var _worst_frame_ms := 0.0
var _finished := false
var _relay_stats := {}   # NakamaLink.stats (the same Dictionary, kept after the link is gone)
var _lan_sent := 0       # ENet bytes on the wire (HOST_TOTAL_*_DATA, summed: pop_statistic resets)
var _lan_received := 0
var _fly := OS.get_cmdline_user_args().has("--net-test-fly")
var _fly_t := -1.0
var _fly_y := 0.0
var _fly_from_bytes := 0
var _fly_from_ms := 0
var _guest_id := 0          # host: the guest's peer id
var _play_t := -1.0
var _drop := ""             # "", "close", "dead" or "never" (both games get the argument)
var _invite := ""           # --net-test-invite=<name>: the host invites this friend into its match (a real server)
var _dropped_ms := -1
var _gave_up_ms := -1
## --net-test-remove (spec §17.3): after playing, the host removes the guest; the guest must hear the host's words and
## reach the menu without a rejoin, and the host must let its player go at once.
var _remove := OS.get_cmdline_user_args().has("--net-test-remove")
## Owner #92 ("when my friend joins … the server shuts down"): the host builds a big world first (BIG_SIDE × BIG_SIDE
## blocks, BIG_LAYERS thick, round the spawn), so the join has a real built world to send.
var _big := OS.get_cmdline_user_args().has("--net-test-big")
var _big_done := false
## Owner #92: the guest's game freezes FREEZE_MS right after both players are in (a phone loading a world): it must
## not give up on the host (RejoinRules: its own freeze is not the host's silence).
var _freeze := OS.get_cmdline_user_args().has("--net-test-freeze")
const FREEZE_MS := 12000
const BIG_SIDE := 96
const BIG_LAYERS := 3
## --net-test-crew (spec §21d.6 phase 2, crew flights): the host builds the crew rocket (2 seats) on its Launch Site's
## pad and LAUNCHes; the guest takes its seat; both fly (the host like a child who presses what is asked, then SKIP to
## the landing; the guest's flight follows); both stand in the host's Moon world; the guest's own mission counts (the
## Moon flown, a crew badge); the host's HOME brings both home. With --net-test-drop=close the guest's link drops
## mid-flight: it must come back on board (or land with the crew) without a hang.
var _crew := OS.get_cmdline_user_args().has("--net-test-crew")
const CREW_TIMEOUT := 330.0
const CREW_SKIP_AFTER := FlightPlan.ORBIT   # the host skips to the landing once in orbit (the jump the crew follows)
var _crew_step := 0
var _crew_t := 0.0
var _crew_scene := 0            # the sandbox the current step began in
var _crew_reports := {}         # host: what the guest reported
var _crew_max_step := -1        # guest: the farthest step of the pilot's flight its own flight reached
var _crew_steps := 0
var _crew_dropped := false
const CREW_CHAT := "Look!"   # a quick phrase the guest says on the way (the chat works in the rocket)
var _removed_ms := -1
var _removed_guest := false
var _join := {}             # guest: event -> ms since its sandbox started (one sandbox at a time)
var _join_scene := 0        # the sandbox those are for
var _joins := 0
var _pos_before_drop := Vector3.INF
var _dead_ws: WebSocketPeer   # (keeps an abandoned socket open)
var _away_ids: Array[int] = []
var _away_ms := 0
var _motion := {"last": Vector3.ZERO}   # host: the guest's body frame by frame while it plays
var _back_ids: Array[int] = []
var _d_placed := false
var _place_again_at := 0.0
var _sync_stats := {}       # WorldSync.stats of this game's world (kept after the world is gone)
## Owner #101 (P4, tools/net_test.sh --vr=host|guest): the other game plays in a simulated headset (--vr-preview
## --vr-wave: its head nods and turns, its right hand waves); this one must see it: the remote player's vr_pose decoded
## nodding, turning and waving, its VrBody's hands showing, the VR mark on its name tag ("vr body").
var _see_vr := OS.get_cmdline_user_args().has("--net-test-see-vr") and not OS.get_cmdline_user_args().has(Player.OLD_PEER_ARG)
## --old=...: this game stands in for an older build (no VrPoseLink): it must play as before and never see a pose.
var _old_peer := OS.get_cmdline_user_args().has(Player.OLD_PEER_ARG)
var _vr_range := {"pitch": Vector2(INF, -INF), "yaw": Vector2(INF, -INF), "hand": Vector2(INF, -INF)}
var _vr_frames := 0      # frames the remote player was watched, and with a pose
var _vr_posed := 0
var _vr_size := 0


## The crew rocket (--net-test-crew; tests/unit/test_crew_flight_rules.gd): owner #98, Mission Control's plan for two
## astronauts to the Moon (RocketPlan: two capsules and a service module for each). It passes the check for two.
static func crew_rocket() -> Dictionary:
	return RocketPlan.cells(MissionRules.for_world(SpaceRules.MOON), 2)


func _ready() -> void:
	if _crew:
		Session.chat_received.connect(func(from: String, text: String, _kind: StringName) -> void:
			if _host and text == CREW_CHAT and _crew_step in [2, 3] and not _done.has("crew chat"):
				_pass("crew chat", "\"%s\" from %s on the way" % [text, from]))
	Session.magic_feedback.connect(func(text: String) -> void: _event("feedback: %s" % text))
	Session.edit_rejected.connect(func(pos: Vector3i, id: int) -> void:
		_event("edit rejected %s id=%d" % [pos, id])
		if id == BlockIds.RED and not _host:
			_retry_place())
	Session.undo_step_received.connect(func(step: Array) -> void: _event("undo step %s" % [step]))
	multiplayer.peer_disconnected.connect(func(id: int) -> void: _event("peer %d disconnected" % id))
	multiplayer.peer_connected.connect(func(id: int) -> void: _event("peer %d connected" % id))
	Session.client_ready.connect(func(id: int) -> void: _event("client ready %d" % id))
	Session.peer_away.connect(func(id: int) -> void:
		_away_ids.append(id)
		_away_ms = Time.get_ticks_msec()
		_event("guest %d away (its player stays)" % id))
	Session.peer_back.connect(func(id: int) -> void:
		_back_ids.append(id)
		_event("guest %d back" % id))
	Session.net_notice.connect(func(code: StringName, _words: String) -> void:
		_event("notice %s" % code)
		if code == NetWords.REMOVED:
			_removed_ms = Time.get_ticks_msec()
		if code == NetWords.GAVE_UP:
			_gave_up_ms = Time.get_ticks_msec())
	multiplayer.connected_to_server.connect(func() -> void: _join_event("joined"))
	Session.world_info_received.connect(func(_s: int, _p: Vector3) -> void: _join_event("world_info"))
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--net-test-drop="):
			_drop = a.trim_prefix("--net-test-drop=")
		elif a.begins_with("--net-test-invite="):
			_invite = a.trim_prefix("--net-test-invite=")
	if _invite != "":
		Session.online_match_ready.connect(_invite_guest)
	if OS.get_cmdline_user_args().has("--net-test-no-smooth"):
		Session.a_smoother().enabled = false   # remote bodies step between syncs, as before M4 A2


## --net-test-invite (tools/net_test.sh --invite): a real server lets only invited friends into a match (M4 consent
## gates), so the host invites the guest as HOST MY WORLD's INVITE does; they became friends first
## (tools/net_test_friends.gd). The script starts the guest once it reads "invited <name> ok".
func _invite_guest(match_id: String) -> void:
	var service := Session.online_service()
	var end := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < end:
		if service.status == OnlineService.ONLINE:
			await service.refresh_friends()
			for f: Dictionary in service.friends:
				if f.username == _invite and f.state == OnlineRules.FRIEND:
					var err: String = await service.invite(str(f.id), match_id, "NetTest")
					_event("invited %s %s" % [_invite, "ok" if err == "" else err])
					if err == "":
						return
		await get_tree().create_timer(1.0).timeout
	_event("invite failed: %s is not a friend here" % _invite)


func _process(delta: float) -> void:
	if _finished:
		return
	_t += delta
	var link: Variant = Session.online_link()
	if link != null:
		_relay_stats = link.stats
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet != null and enet.host != null:
		_lan_sent += enet.host.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
		_lan_received += enet.host.pop_statistic(ENetConnection.HOST_TOTAL_RECEIVED_DATA)
	if _t > 1.0:
		_worst_frame_ms = maxf(_worst_frame_ms, delta * 1000.0)
	if _t > (CREW_TIMEOUT if _crew else TIMEOUT):
		_finish(false, "timeout (crew step %d)" % _crew_step if _crew else "timeout")
		return
	var sandbox := get_tree().current_scene
	var in_world := sandbox != null and "world" in sandbox
	if in_world and _role == "?":
		_host = Game.net_mode != &"client"
		_role = "host" if _host else "guest"
	if in_world and Game.net_mode == &"client":
		_watch_join(sandbox)
	if _role != "?" and not in_world and sandbox != null:
		if _remove and not _host and _removed_ms >= 0:
			_pass("removed", "the menu %.1f s after the host's words (%s)" % [(Time.get_ticks_msec() - _removed_ms) / 1000.0,
				"no rejoin" if not Session.a_rejoining() else "REJOINING"])
			_finish(not Session.a_rejoining(), "" if not Session.a_rejoining() else "it tried to rejoin")
		elif _drop == "never" and not _host and _gave_up_ms >= 0:
			_pass("gave up", "the menu %.1f s after the drop, %.1f s after giving up (goodbye words: %.0f s)" % [
				(Time.get_ticks_msec() - _dropped_ms) / 1000.0, (Time.get_ticks_msec() - _gave_up_ms) / 1000.0,
				NetOverlay.GOODBYE_SECONDS])
			_finish(true, "")
		else:
			_finish(false, "back in the menu (disconnected)")
		return
	if not in_world or not is_instance_valid(sandbox.world) or not is_instance_valid(sandbox.player) \
			or not sandbox.player.is_spawned():
		return
	var world: WorldService = sandbox.world
	var player: Player = sandbox.player
	if world.sync != null:
		_sync_stats = world.sync.stats
	if _crew:
		_crew_process(sandbox, world, player, delta)
		return
	var spawn := world.spawn_column()
	var base := Vector3i(spawn.x, maxi(world.surface_height(spawn.x, spawn.y), MeadowsShape.SEA_LEVEL) + 3, spawn.y)
	var a := base + Vector3i(3, 0, 0)
	var b := base + Vector3i(-2, 0, 2)
	var c := base + Vector3i(0, 0, -3)
	if _host and _big and not _big_done:
		_big_done = true
		var t0 := Time.get_ticks_msec()
		var n := 0
		for dx in range(-BIG_SIDE / 2, BIG_SIDE / 2):
			for dz in range(-BIG_SIDE / 2, BIG_SIDE / 2):
				for dy in BIG_LAYERS:
					world.set_block(base + Vector3i(dx, 8 + dy, dz), [BlockIds.STONE, BlockIds.PLANKS, BlockIds.GLASS][dy])
					n += 1
		_event("built a big world: %d blocks in %d ms" % [n, Time.get_ticks_msec() - t0])
	if _host and not _c_placed and Session.world != null:
		_c_placed = Session.request_set_block(c, BlockIds.BLUE)
		_event("placed C ok=%s" % _c_placed)
	var players := get_tree().get_nodes_in_group(&"players")
	_watch_remote(player, players)
	if players.size() < 2:
		if _host and _both_since >= 0.0 and not _guest_finished:
			if _remove and _removed_guest:
				if _done.has("removed guest"):   # the host's own call has answered too
					_pass("let go removed", "the removed guest's player left at once")
					_finish(true, "")
			elif _drop == "never" and not _away_ids.is_empty():
				_pass("let go", "the guest's player left %.1f s after its link dropped" % [
					(Time.get_ticks_msec() - _away_ms) / 1000.0])
				_finish(true, "")
			else:
				_finish(false, "the guest left early")
		return
	if _host and _guest_id == 0:
		for p: Player in players:
			if p != player:
				_guest_id = p.peer_id
	if _host and not _away_ids.is_empty() and not _d_placed:
		_d_placed = true
		_event("placed D while the guest is away ok=%s" % Session.request_set_block(base + Vector3i(1, 1, 1), BlockIds.YELLOW))
	if _both_since < 0.0:
		_both_since = _t
		_event("both players in the world")
		if _freeze and not _host:
			_event("freezing for %d ms like a phone loading a world" % FREEZE_MS)
			OS.delay_msec(FREEZE_MS)
		if _host:
			_before = {a: world.get_block(a), b: world.get_block(b)}
			_rpc_before.rpc(_before)
	if not _host:
		if not _done.has("here"):
			_done["here"] = true
			_rpc_guest_here.rpc_id(1)
		_ping_host()
	if _host and _guest_here:
		_walk(player, delta)
	if _t - _both_since < SETTLE:
		return
	if not _placed and _t >= _place_again_at:
		_placed = true
		_place_ms = Time.get_ticks_msec()
		var ok := Session.request_set_block(a if _host else b, BlockIds.PURPLE if _host else BlockIds.RED)
		_event("placed %s ok=%s" % ["A" if _host else "B", ok])
		if not ok:
			_retry_place()   # e.g. "Someone is standing there!": the host's walk crossed A's cell
	var own := a if _host else b
	var own_id := BlockIds.PURPLE if _host else BlockIds.RED
	if not _done.has("own edit") and world.get_block(own) == own_id:
		_pass("own edit", "round_trip_ms=%d" % (Time.get_ticks_msec() - _place_ms))
	if not _host and not _done.has("saw C") and world.get_block(c) == BlockIds.BLUE:
		_pass("saw C", "the host's edit reached this world")
	var both := world.get_block(a) == BlockIds.PURPLE and world.get_block(b) == BlockIds.RED
	if both and not _done.has("saw A and B"):
		_pass("saw A and B")
		if not _host:
			_rpc_guest_saw_both.rpc_id(1)
	var interactor: BlockInteractor = player.get_node("BlockInteractor")
	# The undo step is the host's RPC; over the relay the block can show up a frame before it.
	if _done.has("saw A and B") and not _undone and (not _host or _guest_saw_both) and interactor.undo_size() > 0:
		_undone = true
		_event("undo own block, steps=%d ok=%s" % [interactor.undo_size(), interactor.undo()])
	if _undone and not _done.has("undo seen") and not _before.is_empty() and world.get_block(a) == _before[a] \
			and world.get_block(b) == _before[b]:
		if world.get_block(c) == BlockIds.BLUE:
			_pass("undo seen", "A and B back to %d and %d, C stays" % [_before[a], _before[b]])
		else:
			_finish(false, "undo removed C too")
			return
	if _host:
		if _done.has("undo seen") and _guest_finished:
			_finish(true, "")
		return
	if _done.has("undo seen") and not _done.has("same world"):
		_check_world_sum(world, base)
	if _done.has("same world"):
		_ping_host()
	var checked := _done.has("same world") and _done.has("saw C") and _done.has("host moved") and _done.has("ping steady")
	if checked and _drop != "" and not _done.has("rejoin") and not _done.has("gave up"):
		_drop_and_rejoin(world, player, base)
		return
	if checked and not _done.has("play"):
		_play(player, delta)
		return
	if checked and _fly and not _done.has("flight"):
		_fly_along(player, delta)
		return
	if checked and _remove:
		if not _done.has("asked to be removed"):
			_done["asked to be removed"] = true
			_rpc_remove_me.rpc_id(1)
		return   # the host removes this game; the menu check above passes it
	if checked:
		_rpc_guest_finished.rpc_id(1)
		_finish(true, "")


## A refused placement (someone stood in the cell) is tried again a second later.
func _retry_place() -> void:
	_placed = false
	_place_again_at = _t + 1.0


# --- Guest: pings, the host's walk, the world checksum -----------------------------------------

## PINGS round trips right after joining, and PINGS more once the checks are done.
func _ping_host() -> void:
	var allowed := PINGS * 2 if _done.has("same world") else PINGS
	if _pings_sent < allowed and _t >= _next_ping:
		_next_ping = _t + 0.1
		_pings_sent += 1
		_rpc_ping.rpc_id(1, Time.get_ticks_usec())


func _watch_remote(player: Player, players: Array[Node]) -> void:
	for p: Player in players:
		if p == player or not p.is_spawned():
			continue
		if _remote_first == Vector3.INF:
			_remote_first = p.global_position
		_remote_moved = maxf(_remote_moved, p.global_position.distance_to(_remote_first))
		if not _host and _remote_moved > 1.5 and not _done.has("host moved"):
			_pass("host moved", "%.1f m" % _remote_moved)
		if _motion.has("frames"):   # host, while the guest plays: how its body moves here, frame by frame
			var step := p.global_position.distance_to(_motion.last)
			_motion.frames += 1
			_motion.moving += 1 if step > 0.0005 else 0
			_motion.biggest = maxf(_motion.biggest, step)
		_motion.last = p.global_position
		if _see_vr and not _done.has("vr body"):
			_watch_vr(p)


## Owner #101 (P4): the remote VR player as this game shows it.
func _watch_vr(p: Player) -> void:
	var pose := VrPoseRules.decode(p.vr_pose, CameraRig.HEAD_HEIGHT * p.size_scale(), p.size_scale())
	_vr_frames += 1
	_vr_size = p.vr_pose.size()
	if pose.is_empty():
		return
	_vr_posed += 1
	var e := (pose.head as Transform3D).basis.get_euler()
	var hand_y := (pose.right as Transform3D).origin.y
	var look := wrapf(p.avatar.rotation.y + e.y, -PI, PI)   # the body faces the head's way (Avatar:rotation), plus the rest
	for k: Array in [["pitch", e.x], ["yaw", look], ["hand", hand_y]]:
		var r: Vector2 = _vr_range[k[0]]
		_vr_range[k[0]] = Vector2(minf(r.x, k[1]), maxf(r.y, k[1]))
	var spread := func(k: String) -> float: return (_vr_range[k] as Vector2).y - (_vr_range[k] as Vector2).x
	var body := p.get_node_or_null("VrBody") as VrBody
	var tag := p.get_node_or_null("NameTag") as Label3D
	var hands_shown := body != null and body.hands.has(VrRules.RIGHT) and (body.hands[VrRules.RIGHT] as Node3D).visible
	if spread.call("pitch") > 0.3 and spread.call("yaw") > 0.3 and spread.call("hand") > 0.2 and hands_shown \
			and (tag == null or tag.text == "" or tag.text.contains(NameTag.VR_MARK.strip_edges())):
		_pass("vr body", "nod %.2f rad, look round %.2f rad, wave %.2f m, %d bytes a pose" % [spread.call("pitch"),
			spread.call("yaw"), spread.call("hand"), p.vr_pose.size()])


func _check_world_sum(world: WorldService, base: Vector3i) -> void:
	var origin := base - Vector3i(BOX.x / 2, BOX.y / 2, BOX.z / 2)
	if _host_sum < 0:
		if _t - _asked_sum > 2.0:
			_asked_sum = _t
			_rpc_sum_request.rpc_id(1, origin)
		return
	var own := box_sum(world, origin)
	if own == _host_sum:
		_pass("same world", "checksum=%d over %s blocks" % [own, BOX.x * BOX.y * BOX.z])
	elif _t - _asked_sum > 2.0:
		_host_sum = -1   # chunks may still be arriving: ask again


## A checksum of every block id in the box at origin (both games compute it the same way).
static func box_sum(world: WorldService, origin: Vector3i) -> int:
	var read := world.box_reader(origin, BOX)
	var ids := PackedByteArray()
	ids.resize(BOX.x * BOX.y * BOX.z)
	var i := 0
	for x in BOX.x:
		for y in BOX.y:
			for z in BOX.z:
				ids[i] = read.call(origin + Vector3i(x, y, z))
				i += 1
	return hash(ids)


## Guest: flies FLY_SECONDS along +X, 20 m up; the host measures what it sends meanwhile.
func _fly_along(player: Player, delta: float) -> void:
	if _fly_t < 0.0:
		_fly_t = 0.0
		_fly_y = player.global_position.y + 20.0
		_rpc_fly.rpc_id(1, true)
	_fly_t += delta
	var p := player.global_position
	player.global_position = Vector3(p.x + FLY_SPEED * delta, _fly_y, p.z)
	player.velocity = Vector3.ZERO
	if _fly_t >= FLY_SECONDS:
		_rpc_fly.rpc_id(1, false)
		_pass("flight", "%.0f m in %.1f s" % [FLY_SPEED * _fly_t, _fly_t])


## Guest: drops its link once, then waits to be back: at the place its player waited, with the block
## the host placed meanwhile, in the same world.
func _drop_and_rejoin(world: WorldService, player: Player, base: Vector3i) -> void:
	if _dropped_ms < 0:
		_dropped_ms = Time.get_ticks_msec()
		_pos_before_drop = player.global_position
		var link: Variant = Session.online_link()
		if link == null:
			_finish(false, "--net-test-drop needs an online game")
			return
		_event("dropping the link (%s) at %s" % [_drop, _pos_before_drop])
		if _drop == "never":
			Session.a_rejoin_try = func() -> void: pass   # every try fails: it has to give up
		if _drop == "dead":
			var adapter: Node = link.socket._adapter
			_dead_ws = adapter._ws        # stays open, never read again: the server keeps the old link
			adapter._ws = WebSocketPeer.new()
		else:
			link.socket.close()
		return
	if Session.a_rejoining() or not player.is_spawned():
		return
	var d := base + Vector3i(1, 1, 1)
	var since := (Time.get_ticks_msec() - _dropped_ms) / 1000.0
	if world.get_block(d) != BlockIds.YELLOW:
		if since > RejoinRules.WINDOW + 20.0:
			_finish(false, "rejoined but never saw D")
		return
	_host_sum = -1
	_pass("rejoin", "back in %.1f s, %.1f m from where it was, D seen" % [since,
		player.global_position.distance_to(_pos_before_drop)])
	_done.erase("same world")   # checked again in the new scene


## Guest: plays PLAY_SECONDS (walks a small circle); the host counts what it sends meanwhile.
func _play(player: Player, delta: float) -> void:
	if _play_t < 0.0:
		_play_t = 0.0
		_rpc_play.rpc_id(1, true)
	_play_t += delta
	var a := _play_t * 0.8
	player.velocity = Vector3.ZERO
	player.global_position += Vector3(cos(a), 0.0, sin(a)) * delta * 2.0
	if _play_t >= PLAY_SECONDS:
		_rpc_play.rpc_id(1, false)
		_pass("play", "%.0f s" % _play_t)


func _sent_bytes() -> int:
	if not _relay_stats.is_empty():   # the bytes sent to the guest (a packet to everyone counts too)
		return int((_relay_stats.get("sent_to", {}) as Dictionary).get(_guest_id, 0))
	return _lan_sent


# --- Guest: join time ---------------------------------------------------------------------------

## Sign-in, socket and standing are looked at every frame (joined and world info come by signal).
func _watch_join(sandbox: Node) -> void:
	if sandbox.get_instance_id() != _join_scene:
		_join_scene = sandbox.get_instance_id()
		_join = {"start": int(sandbox.get("_start_ms"))}
	if _join.has("done"):
		return
	var link: Variant = Session.online_link()
	if link != null:
		if link.session != null and not _join.has("sign_in"):
			_join_event("sign_in")
		if link.bridge != null and not _join.has("socket"):
			_join_event("socket")
	if Session.world != null and not _join.has("world"):
		_join_event("world")
	var p: Variant = sandbox.get("player")
	if p != null and is_instance_valid(p) and not _join.has("player"):
		_join_event("player")   # the host's spawn of this game's player arrived
	if p != null and is_instance_valid(p) and (p as Player).is_spawned():
		_join_event("standing")
		_join["done"] = true
		_joins += 1
		var parts: Array[String] = []
		for k: String in ["sign_in", "socket", "joined", "world_info", "world", "player", "standing"]:
			if _join.has(k):
				parts.append("%s=%d" % [k, int(_join[k])])
		_event("%s ms since the sandbox started: %s%s" % ["join" if _joins == 1 else "rejoin", " ".join(parts),
			" (the drop was %d ms before the sandbox)" % (int(_join.start) - _dropped_ms) if _dropped_ms >= 0 else ""])


func _join_event(what: String) -> void:
	if _join.has("start") and not _join.has(what):
		_join[what] = Time.get_ticks_msec() - int(_join.start)


# --- Host: walking -----------------------------------------------------------------------------

func _walk(player: Player, delta: float) -> void:
	if _walk_t < 0.0:
		_walk_t = 0.0
	if _walk_t < 5.0:
		_walk_t += delta
		if _walk_t < 2.0 or _walk_t >= 3.0:   # out 3 m, a second's rest, back
			player.global_position.x += delta * 1.5 * (1.0 if _walk_t < 2.0 else -1.0)


# --- RPCs ------------------------------------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func _rpc_ping(sent_usec: int) -> void:
	_rpc_pong.rpc_id(multiplayer.get_remote_sender_id(), sent_usec)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_pong(sent_usec: int) -> void:
	var rtt := (Time.get_ticks_usec() - sent_usec) / 1000.0
	var series := _rtts if _rtts.size() < PINGS else _rtts_steady
	series.append(rtt)
	if series.size() == PINGS:
		var sorted := series.duplicate()
		sorted.sort()
		var total := 0.0
		for r in series:
			total += r
		_pass("ping" if is_same(series, _rtts) else "ping steady", "rtt_ms avg=%.1f median=%.1f max=%.1f n=%d" % [
			total / series.size(), sorted[sorted.size() / 2], sorted[-1], series.size()])


@rpc("any_peer", "call_remote", "reliable")
func _rpc_fly(starting: bool) -> void:
	_measure("flight streaming", starting)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_play(starting: bool) -> void:
	_measure("play streaming", starting)
	if starting:
		_motion["frames"] = 0
		_motion["moving"] = 0
		_motion["biggest"] = 0.0
	elif _motion.has("frames"):   # M4 A2: smoothed, the guest's body moves in most frames, in small steps
		_event("guest's body here while it played: moved in %d of %d frames, biggest step %.2f m" % [
			_motion.moving, _motion.frames, _motion.biggest])
		_motion.erase("frames")
	if starting:   # a few edits while the guest plays: they reach it as single changes
		for i in 3:
			var sandbox := get_tree().current_scene
			var w: WorldService = sandbox.world
			var c := w.spawn_column()
			var base := Vector3i(c.x, maxi(w.surface_height(c.x, c.y), MeadowsShape.SEA_LEVEL) + 3, c.y)
			Session.request_set_block(base + Vector3i(-1, 2 + i, -1), BlockIds.GREEN)


## Host: what it sent the guest between start and end (relay: Godot packets to it, and the JSON on
## the wire for the whole game; LAN: ENet bytes on the wire).
var _measure_from := {}


func _measure(check: String, starting: bool) -> void:
	if starting:
		_measure_from[check] = [_sent_bytes(), Time.get_ticks_msec(), int(_relay_stats.get("wire_bytes", 0))]
		return
	var from: Array = _measure_from.get(check, [0, Time.get_ticks_msec(), 0])
	var secs := (Time.get_ticks_msec() - int(from[1])) / 1000.0
	var sent := _sent_bytes() - int(from[0])
	var wire := int(_relay_stats.get("wire_bytes", 0)) - int(from[2])
	_pass(check, "sent=%d bytes in %.1f s = %.1f kbit/s to the guest (%s)%s" % [sent, secs, sent * 8.0 / 1000.0 / maxf(secs, 0.001),
		"relay: Godot packets" if not _relay_stats.is_empty() else "ENet: on the wire",
		"; wire %.1f kbit/s" % (wire * 8.0 / 1000.0 / maxf(secs, 0.001)) if not _relay_stats.is_empty() else ""])


@rpc("authority", "call_remote", "reliable")
func _rpc_before(before: Dictionary) -> void:
	_before = before


@rpc("any_peer", "call_remote", "reliable")
func _rpc_guest_here() -> void:
	_guest_here = true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_guest_saw_both() -> void:
	_guest_saw_both = true


## Host (--net-test-remove): the guest has played; the host removes it, as REMOVE on its card does.
@rpc("any_peer", "call_remote", "reliable")
func _rpc_remove_me() -> void:
	if not _host:
		return
	var who := multiplayer.get_remote_sender_id()
	_removed_guest = true
	var err: String = await Session.host_remove_guest(who)
	_event("removed guest %d %s" % [who, "ok" if err == "" else err])
	if err == "":
		_done["removed guest"] = true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_guest_finished() -> void:
	_guest_finished = true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_sum_request(origin: Vector3i) -> void:
	var sandbox := get_tree().current_scene
	if sandbox != null and "world" in sandbox and is_instance_valid(sandbox.world):
		_rpc_sum_reply.rpc_id(multiplayer.get_remote_sender_id(), box_sum(sandbox.world, origin))


@rpc("any_peer", "call_remote", "reliable")
func _rpc_sum_reply(sum: int) -> void:
	_host_sum = sum


# --- Output ----------------------------------------------------------------------------------

func _event(text: String) -> void:
	print("NETTEST %s t=%.1f %s" % [_role, _t, text])


func _pass(check: String, detail: String = "") -> void:
	_done[check] = true
	_event("PASS %s %s" % [check, detail])


# --- Crew flights (--net-test-crew; spec §21d.6 phase 2) -------------------------------------------------------------

func _crew_next(step: int, sandbox: Node) -> void:
	_crew_step = step
	_crew_t = 0.0
	_crew_scene = sandbox.get_instance_id()


func _crew_process(sandbox: Node, world: WorldService, player: Player, delta: float) -> void:
	_crew_t += delta
	var players := get_tree().get_nodes_in_group(&"players")
	if _host:
		_crew_host(sandbox, world, players)
	else:
		_crew_guest(sandbox, player)


## The host: the pad, the rocket, LAUNCH, the flight (a child pressing what is asked, then SKIP), the Moon world with
## the guest in it, HOME with the guest.
func _crew_host(sandbox: Node, world: WorldService, players: Array[Node]) -> void:
	var crew: CrewFlights = sandbox.get("crew")
	match _crew_step:
		0:   # both in the home world
			if players.size() >= 2 and _guest_here:
				_event("both players in the world")
				_crew_next(1, sandbox)
		1:   # the pad, the crew rocket, LAUNCH
			var launch: LaunchDirector = sandbox.get("launch_site")
			if launch == null or launch.board == null:
				_finish(false, "no Launch Site in the host's world")
				return
			if not launch.stamped:
				if _crew_t > 120.0:
					_finish(false, "the Launch Site's pad was never stamped")
				return
			var corner := LaunchSite.corner(launch.site)
			var rocket := crew_rocket()
			var changes: Array = []
			for c: Vector3i in rocket:
				changes.append([corner + c, rocket[c]])
			world.set_blocks(changes)
			var parts := RocketParts.count(rocket)
			for id: int in parts:
				Profile.data.missions.add_part(id, int(parts[id]))
			launch.board.choose(SpaceRules.MOON)
			var r: Dictionary = launch.board.result
			if not bool(r.get("ok", false)) or int(r.get("seats", 0)) != 2:
				_finish(false, "the crew rocket does not pass the check: %s" % [r.get("lines", [])])
				return
			_pass("crew rocket", "%d parts in %d stages, %d seats, %.2f km/s" % [(r.cells as Dictionary).size(),
				(r.stages as Array).size(), int(r.seats), float(r.dv)])
			var why := launch.board.press_launch()
			if why != "" or crew.call == null:
				_finish(false, "LAUNCH did not call the crew: %s" % why)
				return
			_pass("crew call", "calling %s" % [crew.call.friends])
			_crew_next(2, sandbox)
		2:   # the guest takes its seat: the flight starts
			var f: Node = sandbox.get("flight")
			if f != null and is_instance_valid(f) and f.is_active():
				_pass("crew launched", "with the crew %s" % [crew.crew_peers()])
				_crew_next(3, sandbox)
			elif _crew_t > 30.0:
				_finish(false, "the crew never launched (call state %s)" % [crew.call.state if crew.call else "none"])
		3:   # the flight, then the Moon world
			if sandbox.get_instance_id() != _crew_scene:
				if Game.universe != SpaceRules.MOON:
					_finish(false, "the host landed in world %d" % Game.universe)
					return
				_event("the host stands in its Moon world (%.1f s after the landing started)" % _crew_t)
				_crew_next(4, sandbox)
				return
			var f: Node = sandbox.get("flight")
			if f == null or not is_instance_valid(f) or not f.is_active():
				return
			_play_child(f)
			if not _done.has("crew wave") and crew.seats != null and is_instance_valid(crew.seats):
				for p: int in crew.crew_peers():
					if crew.seats.waving(p):
						_pass("crew wave", "the guest waves from its seat on the pilot's cockpit")
			var run: FlightRun = f.get("run")
			if run.phase() == CREW_SKIP_AFTER and not f.get("skippable"):
				f.set("skippable", true)
				f.call("skip")
				_event("SKIP to the landing from step %d" % run.index)
			if _crew_t > 200.0:
				_finish(false, "the host's flight never landed")
		4:   # the guest in the Moon world too
			if players.size() >= 2 and _crew_reports.has("followed"):
				_pass("crew landed together", "both players in the host's Moon world (%d), %.1f s after the host" % [
					Game.universe, _crew_t])
				_crew_next(5, sandbox)
			elif _crew_t > 90.0:
				_finish(false, "the guest never came into the Moon world")
		5:   # the guest's mission counted: HOME
			if _crew_reports.has("counts") and _crew_t > 3.0:
				var why: String = sandbox.go_home_from_space()
				_event("HOME: %s" % ("on the way" if why == "" else why))
				if why != "":
					_finish(false, "HOME refused: %s" % why)
					return
				_crew_next(6, sandbox)
			elif _crew_t > 60.0:
				_finish(false, "the guest's mission never counted")
		6:   # home, with the guest
			if sandbox.get_instance_id() == _crew_scene:
				return
			if Game.universe != UniverseRules.FIRST:
				_finish(false, "HOME went to world %d" % Game.universe)
				return
			if players.size() >= 2 and _crew_reports.has("home"):
				_pass("home together", "both players back in Green Meadows")
				_finish(true, "")
			elif _crew_t > 90.0:
				_finish(false, "the guest never came home with the host")


## The guest: the call's card (TAKE MY SEAT), its flight following the pilot's (and a drop with --drop), the Moon world,
## its mission counted, home with the host.
func _crew_guest(sandbox: Node, player: Player) -> void:
	if not _done.has("here"):
		_done["here"] = true
		_rpc_guest_here.rpc_id(1)
	var crew: CrewFlights = sandbox.get("crew")
	var f: Node = sandbox.get("flight")
	if f != null and is_instance_valid(f) and f.get("crew_follow") and f.get("run") != null:
		var run: FlightRun = f.get("run")
		_crew_max_step = maxi(_crew_max_step, run.index)
		_crew_steps = run.steps.size()
	match _crew_step:
		0:   # the call's card
			if crew.card != null and is_instance_valid(crew.card) and crew.card.mode == CrewCallCard.ASK:
				_pass("crew card", "\"%s\" (%s, %s)" % [crew.card.words.text, crew.card.take_button.text,
					crew.card.stay_button.text])
				crew.card.take_button.pressed.emit()
				_crew_next(1, sandbox)
		1:   # on board
			if f != null and is_instance_valid(f) and f.get("crew_follow"):
				var cockpit: FlightCockpit = f.get("cockpit")
				var no_controls := not cockpit.lever.visible and not cockpit.skip_button.visible
				var chat: ChatPanel = (sandbox.get("hud") as Hud).chat
				var lent: bool = chat.get_parent() != sandbox.get("hud") and chat.get_index() > cockpit.get_index()
				_pass("crew flying", "seat %d of %d, the pilot %s, controls hidden: %s, seats shown: %s, the chat over the cockpit: %s" % [
					int(f.get("seat")), int(f.get("crew_size")), f.get("pilot"), no_controls,
					crew.seats != null and is_instance_valid(crew.seats), lent])
				if not no_controls or not lent:
					_finish(false, "a crew member's cockpit has the pilot's controls, or no chat")
					return
				crew.seats.wave_button.pressed.emit()   # WAVE from the seat
				Session.request_chat(CREW_CHAT)
				_crew_next(2, sandbox)
			elif _crew_t > 40.0:
				_finish(false, "never on board")
		2:   # following the pilot (a drop mid-flight with --drop), then the Moon world
			if sandbox.get_instance_id() != _crew_scene and Game.universe == SpaceRules.MOON:
				if _crew_dropped and not _done.has("crew back on board"):
					_pass("crew back on board", "straight into the Moon world, %.1f s after the drop" % (
						(Time.get_ticks_msec() - _dropped_ms) / 1000.0))
				_pass("crew followed", "into the host's Moon world; its flight reached step %d of %d%s" % [
					_crew_max_step, _crew_steps, " (after the drop)" if _crew_dropped else ""])
				_rpc_crew_report.rpc_id(1, "followed")
				_crew_next(3, sandbox)
				return
			if _drop != "" and not _crew_dropped and f != null and is_instance_valid(f) and f.get("run") != null \
					and (f.get("run") as FlightRun).phase() == FlightPlan.ASCENT:
				_crew_dropped = true
				_dropped_ms = Time.get_ticks_msec()
				var link: Variant = Session.online_link()
				if link == null:
					_finish(false, "--drop needs an online game")
					return
				_event("dropping the link (%s) mid-flight" % _drop)
				link.socket.close()
			if _crew_dropped and not _done.has("crew back on board") and not Session.a_rejoining() \
					and sandbox.get_instance_id() != _crew_scene and f != null and is_instance_valid(f) and f.get("crew_follow"):
				_pass("crew back on board", "%.1f s after the drop" % ((Time.get_ticks_msec() - _dropped_ms) / 1000.0))
				_crew_scene = sandbox.get_instance_id()
			if _crew_t > 240.0:
				_finish(false, "never came into the Moon world")
		3:   # its own mission counted
			if Profile.data.missions.flown.has(SpaceRules.MOON) and not Profile.data.missions.crews.is_empty():
				_pass("crew counts", "the Moon on its route, badge \"%s\"" % Profile.data.missions.crews.words()[0])
				_rpc_crew_report.rpc_id(1, "counts")
				_crew_next(4, sandbox)
			elif _crew_t > 30.0:
				_finish(false, "its mission never counted")
		4:   # home with the host
			if sandbox.get_instance_id() != _crew_scene and Game.universe == UniverseRules.FIRST:
				_pass("crew home", "back in the host's Green Meadows world")
				_rpc_crew_report.rpc_id(1, "home")
				_finish(true, "")
			elif _crew_t > 90.0:
				_finish(false, "never came home")


## Presses what the flight asks for at once (like tools/flight_smoke_steps.gd's child).
func _play_child(flight: Node) -> void:
	var run: FlightRun = flight.get("run")
	var cockpit: FlightCockpit = flight.get("cockpit")
	if run == null or cockpit == null:
		return
	var waiting := run.waiting_for()
	cockpit.lever.held = waiting in [FlightPlan.THROTTLE, FlightPlan.BURN, FlightPlan.DESCEND]   # owner #106: the descent too
	cockpit.lever.value = run.test_throttle() if cockpit.lever.held else 0.0
	if run.descent != null and run.descent.held():
		run.descent.release()   # GO on the first try's hint card
	if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
		cockpit.action_pressed.emit()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_crew_report(what: String) -> void:
	_crew_reports[what] = true
	_event("the guest reports: %s" % what)



func _finish(ok: bool, reason: String) -> void:
	_finished = true
	if not _relay_stats.is_empty():
		var s := _relay_stats
		_event("relay sent=%d packets %d bytes (max %d) received=%d packets %d bytes (max %d)" % [
			s.sent, s.sent_bytes, s.max_sent, s.received, s.received_bytes, s.max_received])
		_event("relay sent_to=%s wire_bytes=%d refused=%d by_kind=%s" % [s.get("sent_to", {}), s.get("wire_bytes", 0),
			s.get("refused", 0), s.get("by_kind", {})])
	if not _sync_stats.is_empty():
		_event("world sync %s" % [_sync_stats])
	if _lan_sent > 0 or _lan_received > 0:
		_event("enet sent=%d bytes received=%d bytes (on the wire) in %.1f s: %.0f B/s sent" % [_lan_sent, _lan_received, _t,
			_lan_sent / maxf(_t, 0.001)])
	_event("worst_frame_ms=%.1f" % _worst_frame_ms)
	var expected := ["own edit", "saw A and B", "undo seen"]
	if _crew:
		expected = ["crew rocket", "crew call", "crew launched", "crew wave", "crew landed together", "home together"] \
			if _host else ["crew card", "crew flying", "crew followed", "crew counts", "crew home"]
		if _host and multiplayer.multiplayer_peer is ENetMultiplayerPeer:   # (online, the test accounts' chat is the
			expected.append("crew chat")                                   # server's to allow: LAN shows it)
		if _drop != "" and not _host:
			expected.append("crew back on board")
	elif not _host:
		expected.append_array(["saw C", "host moved", "ping", "same world", "ping steady"])
		if _drop == "never":
			expected.append("gave up")
		else:
			expected.append("play")
			if _remove:
				expected.append("removed")
			if _drop != "":
				expected.append("rejoin")
	elif not _crew:
		expected.append("let go" if _drop == "never" else "play streaming")
		if _remove:
			expected.append_array(["removed guest", "let go removed"])
	if _fly and not _crew:
		expected.append("flight" if not _host else "flight streaming")
	if _see_vr and not _crew:
		expected.append("vr body")   # owner #101 (P4)
		_event("vr watched %d frames, %d with a pose (%d bytes), ranges %s" % [_vr_frames, _vr_posed, _vr_size, _vr_range])
	if _old_peer:   # owner #101 (P4): an older build never hears a pose
		var posed := get_tree().get_nodes_in_group(&"players").filter(func(n: Node) -> bool: return not (n as Player).vr_pose.is_empty())
		_event("old peer: %d players with a pose here (no VrPoseLink)" % posed.size())
		if not posed.is_empty():
			ok = false
			reason += " an older build got a pose"
	var missing := expected.filter(func(c: String) -> bool: return not _done.has(c))
	if not missing.is_empty():
		ok = false
		reason = (reason + " " if reason != "" else "") + "missing: %s" % ", ".join(missing)
	_event("result %s %s" % ["PASS" if ok else "FAIL", reason])
	await get_tree().create_timer(0.5).timeout   # lets the last RPC go out
	get_tree().quit(0 if ok else 1)
