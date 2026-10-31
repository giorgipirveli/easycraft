extends GutTest
## Getting back in after the internet drops (M4 Wave 1 A, spec §17.0): a guest tries to rejoin the
## same world for 30 s ("The internet went away. Trying again…"), then goes back to the menu; the
## host keeps the guest's player in the world for those 30 s.


func test_a_guest_plays_until_the_link_is_lost() -> void:
	var r := RejoinRules.new()
	assert_eq(r.state, RejoinRules.PLAYING)
	r.lost(10.0)
	assert_eq(r.state, RejoinRules.REJOINING)
	assert_almost_eq(r.seconds_left(12.0), RejoinRules.WINDOW - 2.0, 0.001)


func test_long_silence_from_the_host_counts_as_a_lost_link() -> void:
	var r := RejoinRules.new()
	r.heard(1.0)
	assert_false(r.silent_too_long(1.0 + RejoinRules.SILENCE - 0.1))
	assert_true(r.silent_too_long(1.0 + RejoinRules.SILENCE + 0.1))
	r.heard(20.0)
	assert_false(r.silent_too_long(21.0))


func test_the_first_try_is_at_once_then_they_space_out() -> void:
	var r := RejoinRules.new()
	r.lost(0.0)
	assert_true(r.should_try(0.0))
	r.trying(0.0)
	assert_false(r.should_try(0.5), "one try at a time")
	r.failed(1.0)
	var waits: Array[float] = []
	var t := 1.0
	for i in 4:
		var next := t
		while not r.should_try(next):
			next += 0.25
		waits.append(next - t)
		r.trying(next)
		t = next + 0.5
		r.failed(t)
	for i in range(1, waits.size()):
		assert_gte(waits[i], waits[i - 1], "never faster than before")
	assert_lte(waits[-1], RejoinRules.MAX_WAIT + 0.25)


func test_a_successful_try_is_back_in_the_game() -> void:
	var r := RejoinRules.new()
	r.lost(0.0)
	r.trying(0.0)
	r.joined()
	assert_eq(r.state, RejoinRules.PLAYING)
	r.heard(3.0)
	assert_false(r.silent_too_long(4.0))


func test_after_the_window_the_guest_gives_up_even_while_trying() -> void:
	var r := RejoinRules.new()
	r.lost(5.0)
	assert_eq(r.tick(5.0 + RejoinRules.WINDOW - 0.1), RejoinRules.REJOINING)
	r.trying(5.0 + RejoinRules.WINDOW - 0.05)
	assert_eq(r.tick(5.0 + RejoinRules.WINDOW + 0.01), RejoinRules.GAVE_UP)
	assert_false(r.should_try(40.0))


func test_losing_the_link_twice_does_not_restart_the_clock() -> void:
	var r := RejoinRules.new()
	r.lost(0.0)
	r.lost(20.0)
	assert_almost_eq(r.seconds_left(20.0), RejoinRules.WINDOW - 20.0, 0.001)


func test_the_host_keeps_an_away_guest_for_the_window() -> void:
	var away := RejoinRules.Away.new()
	away.went(7, 100.0)
	assert_true(away.has(7))
	assert_eq(away.expired(100.0 + RejoinRules.WINDOW - 1.0), [])
	assert_true(away.back(7), "it came back in time")
	assert_false(away.has(7))
	assert_false(away.back(7), "only once")


func test_an_away_guest_who_never_comes_back_is_let_go() -> void:
	var away := RejoinRules.Away.new()
	away.went(7, 100.0)
	away.went(9, 110.0)
	assert_eq(away.expired(100.0 + RejoinRules.WINDOW + 1.0), [7])
	assert_false(away.has(7))
	assert_true(away.has(9))
	assert_eq(away.expired(200.0), [9])


## Owner #92 ("when my friend joins … the server shuts down and the game is not accessible"): a phone or a browser
## freezes for seconds while a world loads or a new player first appears. The guest's own frozen time is never the
## host's silence (a long frame moves the last word on by that frame), and the host gets SILENCE ≥ 15 s before a
## guest gives up on it, inside a WINDOW long enough to get back in.
func test_the_guest_s_own_freeze_is_never_the_host_s_silence() -> void:
	assert_gte(RejoinRules.SILENCE, 15.0)
	assert_gte(RejoinRules.WINDOW, RejoinRules.SILENCE + 25.0, "time to get back in after deciding")
	var r := RejoinRules.new()
	r.heard(10.0)
	r.frame(40.0, 30.0)   # a 30 s frame: the world loading on a phone
	assert_false(r.silent_too_long(40.0), "the guest was frozen, not the host silent")
	assert_false(r.silent_too_long(40.0 + RejoinRules.SILENCE - 0.5), "the clock starts after the freeze")
	assert_true(r.silent_too_long(40.0 + RejoinRules.SILENCE + 0.5), "real silence still counts")
	var q := RejoinRules.new()
	q.heard(10.0)
	q.frame(10.5, 0.016)   # ordinary frames move nothing
	assert_true(q.silent_too_long(10.0 + RejoinRules.SILENCE + 0.1))


## Owner #92: a host streams the world round each friend (the friend's own terrain comes from the host). On a weak
## phone host (LOW: it sees 64 blocks itself) a friend's 128 was four times the ground in memory at the moment the
## friend arrived; a host streams round a friend no further than round itself.
func test_a_host_streams_round_a_friend_no_further_than_round_itself() -> void:
	var low := ProfileData.DEFAULT_SETTINGS.duplicate()
	low.graphics = "low"
	assert_eq(Player.remote_view_distance(low), GraphicsPreset.view_distance(low))
	assert_lte(Player.remote_view_distance(low), 64)
	var usual := ProfileData.DEFAULT_SETTINGS.duplicate()
	assert_eq(Player.remote_view_distance(usual), mini(Player.REMOTE_VIEW, GraphicsPreset.view_distance(usual)))
	assert_eq(Player.REMOTE_VIEW, 128, "never more than before")
