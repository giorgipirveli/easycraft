extends GutTest
## Owner #123 (2026-10-17): an old phone app and the new web game played in one online world and saw different things:
## nothing checked that both run the same game. Now each game sends its version on the relayed match (its own op code,
## outside Godot's remote calls, which line up only between identical builds) until it hears the other's: the same
## online fingerprint (BuildInfo's `net`) plays; a different one is NEWER or OLDER by the build's date (the guest then
## leaves with plain words); a game that never answers is an old one (UNKNOWN: a gentle warning, nobody is sent away,
## since phones on the store's old version can't update yet). A developer's run ("" net) plays with anyone.

const NEW := {"net": "aaaaaaaa1111", "version": "1.0.6", "date": "2026-10-17T23:00:00+04:00"}
const OLD := {"net": "bbbbbbbb2222", "version": "1.0.5", "date": "2026-10-16T07:40:00+04:00"}
const DEV := {"net": "", "version": "1.0.6", "date": ""}


func test_the_payload_round_trips_and_bad_ones_are_dropped() -> void:
	var c := NetVersionCheck.new(NEW, false)
	assert_eq(NetVersionCheck.parse(c.payload()), NEW)
	assert_eq(NetVersionCheck.parse("nonsense"), {})
	assert_eq(NetVersionCheck.parse('{"net": 5}'), {})
	assert_eq(NetVersionCheck.parse('{"net": "<b>", "version": "1.0.6"}'), {}, "a net is hex")
	assert_eq(NetVersionCheck.parse('{"net": "", "version": "1.0.6"}'), {"net": "", "version": "1.0.6", "date": ""},
		"a developer's run")


func test_the_same_fingerprint_plays_and_a_different_one_is_newer_or_older_by_date() -> void:
	assert_eq(NetVersionCheck.compare(NEW, NEW), NetVersionCheck.SAME)
	assert_eq(NetVersionCheck.compare(OLD, NEW), NetVersionCheck.NEWER, "theirs is newer than mine")
	assert_eq(NetVersionCheck.compare(NEW, OLD), NetVersionCheck.OLDER)
	assert_eq(NetVersionCheck.compare(DEV, OLD), NetVersionCheck.SAME, "a developer's run plays with anyone")
	assert_eq(NetVersionCheck.compare(OLD, DEV), NetVersionCheck.SAME)
	var undated := {"net": "cccccccc3333", "version": "1.0.7", "date": ""}
	assert_eq(NetVersionCheck.compare(OLD, undated), NetVersionCheck.NEWER, "no date: the version's numbers decide")


func test_a_guest_sends_until_it_hears_the_host_then_decides_once() -> void:
	var c := NetVersionCheck.new(OLD, false)
	c.met("host")
	assert_true(c.tick(0.0), "sends at once")
	assert_false(c.tick(0.5), "not again so soon")
	assert_true(c.tick(NetVersionCheck.RESEND_SEC), "again until it hears")
	assert_eq(c.heard("host", JSON.stringify(NEW)), NetVersionCheck.NEWER)
	assert_eq(c.heard("host", JSON.stringify(NEW)), &"", "decided once")
	assert_false(c.tick(NetVersionCheck.RESEND_SEC), "it heard: no more sends")
	assert_eq(c.overdue(), [], "nothing left to wait for")


func test_a_host_that_never_answers_is_an_old_game_a_warning_once() -> void:
	var c := NetVersionCheck.new(NEW, false)
	c.met("host")
	c.tick(0.0)
	c.tick(NetVersionCheck.WAIT_SEC - 0.1)
	assert_eq(c.overdue(), [])
	c.tick(0.2)
	assert_eq(c.overdue(), ["host"])
	assert_eq(c.overdue(), [], "told once")
	assert_false(c.tick(NetVersionCheck.RESEND_SEC), "it stops asking")


func test_a_host_judges_each_guest_on_its_own() -> void:
	var c := NetVersionCheck.new(NEW, true)
	c.met("ann")
	c.met("bo")
	assert_eq(c.heard("ann", JSON.stringify(NEW)), NetVersionCheck.SAME)
	assert_eq(c.heard("bo", JSON.stringify(OLD)), NetVersionCheck.OLDER)
	assert_eq(c.heard("zed", JSON.stringify(OLD)), NetVersionCheck.OLDER, "a message before its presence still counts")
	c.left("bo")
	c.tick(NetVersionCheck.WAIT_SEC + 1.0)
	assert_eq(c.overdue(), [])


func test_a_guest_ignores_other_guests_messages() -> void:
	var c := NetVersionCheck.new(NEW, false)
	c.met("host")
	assert_eq(c.heard("other_guest", JSON.stringify(OLD)), &"", "only the host's version matters to a guest")
	assert_eq(c.heard("host", JSON.stringify(NEW)), NetVersionCheck.SAME)


## What a verdict does (Session acts on it): a guest in a world of another version leaves with words saying which game
## is behind; the host is told a friend couldn't join; an old game that never answered gets a gentle warning only.
func test_what_each_verdict_does_for_a_guest_and_for_a_host() -> void:
	assert_eq(NetVersionCheck.action(NetVersionCheck.SAME, false), {})
	assert_eq(NetVersionCheck.action(NetVersionCheck.SAME, true), {})
	assert_eq(NetVersionCheck.action(NetVersionCheck.NEWER, false), {"leave": true, "reason": "version: newer"})
	assert_eq(NetVersionCheck.action(NetVersionCheck.OLDER, false), {"leave": true, "reason": "version: older"})
	assert_eq(NetVersionCheck.action(NetVersionCheck.NEWER, true), {"leave": false, "notice": NetWords.FRIEND_DIFFERENT})
	assert_eq(NetVersionCheck.action(NetVersionCheck.OLDER, true), {"leave": false, "notice": NetWords.FRIEND_DIFFERENT})
	assert_eq(NetVersionCheck.action(NetVersionCheck.UNKNOWN, false), {"leave": false, "notice": NetWords.MAYBE_DIFFERENT})
	assert_eq(NetVersionCheck.action(NetVersionCheck.UNKNOWN, true), {"leave": false, "notice": NetWords.MAYBE_DIFFERENT})
