extends GutTest
## Crew flights (spec §21d.6 phase 2, the brief's item 3: "the crew follows into the host's new world automatically (no
## menu, no invite, no code: the session carries them)"): Session's side. The host's world moves without closing the
## session (crew_move), and every guest's hello waits until the new world stands (crew_world_ready); a guest leaves its
## link without a word to the scene and is "following" for CrewFlightRules.FOLLOW_SECONDS; closing the session forgets
## it all. (tools/net_test.sh --crew plays it for real over LAN and the relay.)


func after_each() -> void:
	Session.crew_reset()


func test_a_hello_is_answered_at_once_when_nothing_moves() -> void:
	assert_false(Session.crew_moving())
	assert_false(Session.crew_hold_hello(5))


func test_while_the_world_moves_hellos_wait_for_the_new_one() -> void:
	Session.crew_move(SpaceRules.MOON, false, [] as Array[int])
	assert_true(Session.crew_moving(), "the host keeps hosting: its next world does not host again")
	assert_true(Session.crew_hold_hello(5))
	assert_true(Session.crew_hold_hello(5), "a second hello waits too (once)")
	assert_eq(Session._crew_held, [5] as Array[int])
	Session.crew_world_ready()
	assert_false(Session.crew_moving(), "the new world stands")
	assert_eq(Session._crew_held, [] as Array[int], "(peer 5 left meanwhile: nobody to answer)")
	assert_false(Session.crew_hold_hello(5), "hellos are answered at once again")


func test_a_guest_follows_for_a_while_then_stands_or_gives_up() -> void:
	assert_false(Session.crew_following())
	Session.crew_follow_leave()
	assert_true(Session.crew_following())
	assert_null(Session.world, "the old world is let go")
	assert_almost_eq(Session.crew_follow_seconds_left(), CrewFlightRules.FOLLOW_SECONDS, 1.0)
	assert_true(multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "(no link here: nothing to leave)")
	Session.crew_follow_done()
	assert_false(Session.crew_following())
	assert_eq(Session.crew_follow_seconds_left(), 0.0)


func test_closing_the_session_forgets_every_move_and_follow() -> void:
	Session.crew_move(SpaceRules.MOON, false, [] as Array[int])
	Session.crew_hold_hello(4)
	Session.crew_follow_leave()
	Session.close()
	assert_false(Session.crew_moving())
	assert_false(Session.crew_following())
	assert_eq(Session._crew_held, [] as Array[int])


func test_only_the_host_moves_its_world() -> void:
	assert_true(Session.is_host(), "(solo: this game hosts)")
	Session.crew_move(SpaceRules.MARS, true, [2] as Array[int])
	assert_true(Session.crew_moving())
