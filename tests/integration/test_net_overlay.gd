extends GutTest
## Plain words on the screen for network problems (M4 Wave 1 A, spec §17.0): "The internet went away.
## Trying again…" covers the game while a guest rejoins, news like "You're back!" shows for a moment
## without getting in the way, and the words on the way back to the menu stay until the game leaves.

var overlay: NetOverlay


func before_each() -> void:
	overlay = NetOverlay.new()
	add_child_autofree(overlay)


func after_each() -> void:
	Session.a_clear_notice()


func test_it_starts_hidden_and_lets_taps_through() -> void:
	assert_false(overlay.visible)
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(overlay.process_mode, Node.PROCESS_MODE_ALWAYS, "it works while the world is stopped")


func test_a_lost_link_covers_the_game_with_trying_again() -> void:
	Session.net_notice.emit(NetWords.LINK_LOST, NetWords.text(NetWords.LINK_LOST))
	assert_true(overlay.visible)
	assert_eq(overlay.mode(), NetOverlay.REJOINING)
	assert_string_contains(overlay.words(), "Trying again")
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "the game underneath takes no taps")


func test_being_back_is_a_short_note_that_goes_away() -> void:
	Session.net_notice.emit(NetWords.LINK_LOST, NetWords.text(NetWords.LINK_LOST))
	Session.net_notice.emit(NetWords.BACK, NetWords.text(NetWords.BACK))
	assert_eq(overlay.mode(), NetOverlay.NOTE)
	assert_eq(overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a note never takes a tap")
	overlay.note_seconds = 0.2
	Session.net_notice.emit(NetWords.BACK, NetWords.text(NetWords.BACK))
	await wait_seconds(0.5)
	assert_false(overlay.visible)


func test_the_goodbye_words_stay_until_the_game_leaves() -> void:
	overlay.goodbye(NetWords.text(NetWords.GAVE_UP))
	assert_true(overlay.visible)
	assert_eq(overlay.mode(), NetOverlay.GOODBYE)
	assert_string_contains(overlay.words(), "menu")
	Session.net_notice.emit(NetWords.BACK, NetWords.text(NetWords.BACK))
	assert_eq(overlay.mode(), NetOverlay.GOODBYE, "nothing replaces the goodbye")


func test_a_new_overlay_shows_trying_again_when_session_is_rejoining() -> void:
	var r := RejoinRules.new()
	r.lost(Time.get_ticks_msec() / 1000.0)
	Session._rejoin = r
	var fresh := NetOverlay.new()
	add_child_autofree(fresh)
	assert_eq(fresh.mode(), NetOverlay.REJOINING, "the guest's fresh scene keeps the words up")
	Session._rejoin = RejoinRules.new()
