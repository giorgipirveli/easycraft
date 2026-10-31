extends GutTest
## M3 Task 19 (the whole-branch review), found by a LAN run (host in Survivor, a guest joining; the host's test ended
## first): once the host is gone, the guest shows the goodbye for 3 s with its world still registered, and every
## physics frame Session asked is_host() of a closed ENet peer: "The multiplayer instance isn't currently active",
## 175 engine errors on the guest (fly_tick, the building tools' and the trades' ticks run only on a host).


class StubWorld:
	extends WorldService


func test_a_guest_whose_host_left_runs_no_host_ticks_and_logs_nothing() -> void:
	var saved_peer := multiplayer.multiplayer_peer
	var saved_world := Session.world
	var gone := ENetMultiplayerPeer.new()
	assert_eq(gone.create_client("127.0.0.1", 24599), OK, "a guest's link (nobody answers on this port)")
	var w := StubWorld.new()
	Session.world = w
	multiplayer.multiplayer_peer = gone
	gone.close()   # the host went away: the guest's peer is closed, its world still registered
	assert_eq(gone.get_connection_status(), MultiplayerPeer.CONNECTION_DISCONNECTED)
	Session._physics_process(1.0 / 60.0)
	multiplayer.multiplayer_peer = saved_peer
	Session.world = saved_world
	w.free()
	assert_eq(get_errors().size(), 0, "no engine error on a closed peer")


func test_the_host_still_runs_its_ticks() -> void:
	var saved_world := Session.world
	var w := StubWorld.new()
	Session.world = w
	Session.tool_slowest_slice_ms = 0.0
	Session._physics_process(1.0 / 60.0)   # solo: this game is the host (fly_tick and the rest run, nothing to do)
	Session.world = saved_world
	w.free()
	assert_true(Session.is_host())
