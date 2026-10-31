extends GutTest
## M7 (owner 2026-09-28: "when user start playing, they should get shortcut on the app so next time they just click and
## open it"): when the main menu shows the "Add EasyCraft to this device" card and SETTINGS its ADD TO THIS DEVICE.
## In a browser only, when the page can add the game (web/shell.html's window.easycraftApp) and it is not added yet;
## the card only after some play, at most once a run, 3 days after an answer, never again after 3 NOT NOWs.

const IPHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_IOS: true, PlatformRules.TOUCH_SCREEN: true}
const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
const MAC_SAFARI := {PlatformRules.WEB: true, PlatformRules.WEB_MACOS: true}
const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}
const DESKTOP := {}
const CAN := {"can_install": true, "needs_guide": false, "installed": false}
const NOW := 1_790_000_000
const DAY := 86_400


func _fresh() -> Dictionary:
	return ProfileData.new().settings


func _due(f: Dictionary, state: Dictionary = CAN, played := true, settings: Dictionary = _fresh(), now := NOW,
		shown := false) -> bool:
	return InstallOffer.card_due(f, state, played, settings, now, shown)


func test_a_browser_that_can_add_the_game_offers_it_after_some_play() -> void:
	assert_true(_due(PHONE_BROWSER))
	assert_true(_due(MAC_SAFARI, {"can_install": true, "needs_guide": true, "installed": false}), "Safari: the guide")


func test_never_outside_a_browser() -> void:
	assert_false(_due(ANDROID), "the phone game is an app already")
	assert_false(_due(DESKTOP))
	assert_false(InstallOffer.can_offer(ANDROID, CAN))
	assert_false(InstallOffer.can_offer(DESKTOP, CAN))


func test_not_when_the_page_cannot_add_it_or_it_is_added() -> void:
	assert_false(_due(PHONE_BROWSER, {"can_install": false, "needs_guide": false, "installed": false}), "Firefox")
	assert_false(_due(PHONE_BROWSER, {"can_install": true, "needs_guide": false, "installed": true}), "added")
	assert_false(_due(PHONE_BROWSER, {}), "a page without window.easycraftApp")
	assert_false(InstallOffer.can_offer(PHONE_BROWSER, {"can_install": false, "installed": false}))
	assert_false(InstallOffer.can_offer(PHONE_BROWSER, {"can_install": true, "installed": true}))
	assert_true(InstallOffer.can_offer(PHONE_BROWSER, CAN))


func test_only_after_the_child_has_played() -> void:
	assert_false(_due(PHONE_BROWSER, CAN, false), "a first visit: play first")


func test_at_most_once_a_run() -> void:
	assert_false(_due(PHONE_BROWSER, CAN, true, _fresh(), NOW, true))


func test_not_now_waits_three_days() -> void:
	var s := _fresh()
	InstallOffer.note_not_now(s, NOW)
	assert_eq(int(s.install_not_now), 1)
	assert_eq(int(s.install_asked_at), NOW)
	assert_false(_due(PHONE_BROWSER, CAN, true, s, NOW + DAY), "a day later")
	assert_false(_due(PHONE_BROWSER, CAN, true, s, NOW + 3 * DAY - 1), "just under 3 days")
	assert_true(_due(PHONE_BROWSER, CAN, true, s, NOW + 3 * DAY), "3 days later")


func test_three_not_nows_leave_it_to_settings() -> void:
	var s := _fresh()
	for i in 3:
		InstallOffer.note_not_now(s, NOW + i * 4 * DAY)
	assert_eq(int(s.install_not_now), 3)
	assert_false(_due(PHONE_BROWSER, CAN, true, s, NOW + 100 * DAY), "the menu stops offering")
	assert_true(InstallOffer.can_offer(PHONE_BROWSER, CAN), "SETTINGS still has it")


func test_add_waits_three_days_too_but_is_no_not_now() -> void:
	var s := _fresh()
	InstallOffer.note_add(s, NOW)
	assert_eq(int(s.install_not_now), 0, "not counted")
	assert_eq(int(s.install_asked_at), NOW)
	assert_false(_due(PHONE_BROWSER, CAN, true, s, NOW + DAY), "the prompt may have been turned down: not again at once")
	assert_true(_due(PHONE_BROWSER, CAN, true, s, NOW + 3 * DAY))


func test_a_clock_set_back_never_locks_it_away() -> void:
	var s := _fresh()
	InstallOffer.note_not_now(s, NOW + 400 * DAY)
	assert_true(_due(PHONE_BROWSER, CAN, true, s, NOW), "answered 'in the future': offered again")


## Owner #59: "for iphone users … we should remind them from time to time, to play with full experience you should add
## game to homescreen". Where only the Home Screen gives full screen (Safari's guide: iPhone, iPad), the card comes back
## about once a day and never stops after NOT NOWs.
func test_on_an_iphone_the_reminder_comes_back_daily_and_never_stops() -> void:
	var iphone_state := {"can_install": true, "needs_guide": true, "installed": false}
	var settings := {}
	for i in 5:
		InstallOffer.note_not_now(settings, 1000)
	assert_false(InstallOffer.card_due(IPHONE_BROWSER, iphone_state, true, settings, 1000 + 3600, false), "not the same hour")
	assert_true(InstallOffer.card_due(IPHONE_BROWSER, iphone_state, true, settings, 1000 + InstallOffer.GUIDE_WAIT_SECONDS, false),
		"a day later, even after five NOT NOWs")
