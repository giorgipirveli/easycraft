extends GutTest
## The host keeps an online guest's player while the guest's link is down (M4 Wave 1 A, spec §17.0):
## its player stays in the world for RejoinRules.WINDOW seconds (peer_away), a guest that comes back
## with its peer id finds it there (peer_back, and the host tells it where it stands), and one that
## never comes back is let go (peer_left). LAN and solo let go at once, as before.

var remote: Player
var left: Array[int] = []
var away: Array[int] = []
var back: Array[int] = []


func before_each() -> void:
	left = []
	away = []
	back = []
	remote = load("res://entities/player/player.tscn").instantiate()
	remote.name = "7"   # a guest's body on this (host) game
	add_child_autofree(remote)
	Session.peer_left.connect(_on_left)
	Session.peer_away.connect(_on_away)
	Session.peer_back.connect(_on_back)


func after_each() -> void:
	Session.peer_left.disconnect(_on_left)
	Session.peer_away.disconnect(_on_away)
	Session.peer_back.disconnect(_on_back)
	if Session._link is Node and not (Session._link as Node).is_inside_tree():
		(Session._link as Node).free()
	Session._link = null
	Session._away = RejoinRules.Away.new()


func _on_left(id: int) -> void:
	left.append(id)


func _on_away(id: int) -> void:
	away.append(id)


func _on_back(id: int) -> void:
	back.append(id)


func _pretend_online() -> void:
	Session._link = Node.new()   # is_online(): the relay; this game is the host (offline peer = server)


func test_on_lan_a_guest_that_leaves_is_let_go_at_once() -> void:
	Session._a_peer_disconnected(7)
	assert_eq(left, [7])
	assert_eq(away, [])


func test_online_a_guest_whose_link_drops_keeps_its_player_for_the_window() -> void:
	_pretend_online()
	Session._a_peer_disconnected(7)
	assert_eq(away, [7])
	assert_eq(left, [], "its player stays in the world")
	var now := Time.get_ticks_msec() / 1000.0
	Session._a_tick(now + RejoinRules.WINDOW - 1.0)
	assert_eq(left, [], "still waiting")
	Session._a_tick(now + RejoinRules.WINDOW + 1.0)
	assert_eq(left, [7], "it never came back: let go")


func test_online_a_guest_that_comes_back_in_time_is_back() -> void:
	_pretend_online()
	Session._a_peer_disconnected(7)
	Session._a_peer_connected(7)
	assert_eq(back, [7])
	Session._a_tick(Time.get_ticks_msec() / 1000.0 + RejoinRules.WINDOW + 1.0)
	assert_eq(left, [], "back in time: nobody is let go")


func test_a_guest_without_a_player_yet_is_let_go_at_once() -> void:
	_pretend_online()
	Session._a_peer_disconnected(8)
	assert_eq(left, [8])


func test_when_the_host_goes_offline_away_guests_are_let_go() -> void:
	_pretend_online()
	Session._a_peer_disconnected(7)
	(Session._link as Node).free()
	Session._link = null
	Session._a_tick(Time.get_ticks_msec() / 1000.0)
	assert_eq(left, [7])


func test_failures_get_the_right_words_for_host_and_guest() -> void:
	var got: Array[StringName] = []
	var on_notice := func(code: StringName, _w: String) -> void: got.append(code)
	Session.net_notice.connect(on_notice)
	Session._a_on_failed("the connection to the server closed")   # this game is the host here
	Session._a_on_failed("match: Match not found")
	Session.net_notice.disconnect(on_notice)
	assert_eq(got, [NetWords.SERVER_GONE, NetWords.NO_WORLD])
	assert_eq(Session.a_last_notice(), NetWords.NO_WORLD)
	Session.a_clear_notice()


## M4 Wave 2 A2 (the net test's rejoin froze the guest for about 7 s): the old scene's world was freed
## while it still streamed, and Voxel Tools waited for thousands of queued tasks. Now its viewers go
## first, the queue drains, and only then does the scene reload; no try to join starts meanwhile.
func test_a_rejoin_lets_the_old_world_stop_streaming_before_the_scene_reloads() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 20260924, true)
	add_child_autofree(w)
	var v := VoxelViewer.new()
	v.view_distance = 128
	add_child(v)
	v.position = Vector3(16, 40, 0)
	await wait_seconds(0.5)
	assert_gt(WorldService.voxel_tasks(), 0, "streaming")
	var reloads: Array[int] = []
	var tried: Array[int] = []
	Session.a_reload_scene = func() -> void: reloads.append(WorldService.voxel_tasks())
	Session.a_rejoin_try = func() -> void: tried.append(1)
	Session._rejoin.lost(Time.get_ticks_msec() / 1000.0)
	Session._a_reload_scene(self)
	assert_true(Session.a_reloading())
	Session._a_try_if_due(Time.get_ticks_msec() / 1000.0)
	assert_eq(tried, [], "no try while the old scene is still going")
	await wait_until(func() -> bool: return not reloads.is_empty(), 5.0, "the scene reloads")
	await wait_frames(2)
	assert_false(is_instance_valid(v), "the viewer went first")
	assert_eq(reloads, [0], "after the queue was dropped")
	assert_false(Session.a_reloading())
	Session._a_try_if_due(Time.get_ticks_msec() / 1000.0)
	assert_eq(tried, [1], "then it tries")
	Session._rejoin = RejoinRules.new()
	Session.a_reload_scene = Callable()
	Session.a_rejoin_try = Callable()


## M4 Wave 2 A2 (the net test's --drop=never): a guest that gave up still had the "connecting" relay
## peer, and going back to the menu closed it: an engine error (NakamaMultiplayerPeer has no _close).
func test_giving_up_leaves_a_peer_the_menu_can_close() -> void:
	Session.online_config = {"role": OnlineConfig.JOIN, "match_id": "x"}
	multiplayer.multiplayer_peer = (load(Session.NAKAMA_LINK_SCRIPT) as GDScript).waiting_peer()
	Session._rejoin.lost(Time.get_ticks_msec() / 1000.0)
	Session._a_give_up()
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "back to solo at once")
	Session.close()   # what the menu does
	Session.online_config = {}
	Session._rejoin = RejoinRules.new()
	Session.a_clear_notice()
