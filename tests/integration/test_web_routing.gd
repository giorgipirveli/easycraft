extends GutTest
## M7 Task 4 (spec §20.3): the game's platform checks go through PlatformRules, so a browser gets what its device is:
## Android phone browsers buzz (navigator.vibrate) and iPhones don't; a browser never shows the desktop's stand-ins
## (the Theater's placeholder player). Android and the desktop stay as they were.

const ANDROID_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
const IPHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_IOS: true, PlatformRules.TOUCH_SCREEN: true}
const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}

var _vibration: Variant


func before_each() -> void:
	_vibration = Profile.data.settings.get("vibration", true)
	Profile.data.settings.vibration = true   # nothing here saves the shared profile file


func after_each() -> void:
	PlatformRules.simulated = {}
	Profile.data.settings.vibration = _vibration


func test_android_phones_buzz_in_the_game_and_in_the_browser() -> void:
	PlatformRules.simulated = ANDROID
	assert_gt(Feel.buzz_ms(40), 0, "the Android game")
	PlatformRules.simulated = ANDROID_BROWSER
	assert_gt(Feel.buzz_ms(40), 0, "Chrome on Android")


func test_iphones_and_desktops_never_buzz() -> void:
	PlatformRules.simulated = IPHONE_BROWSER
	assert_eq(Feel.buzz_ms(40), 0, "Safari has no vibration")
	PlatformRules.simulated = {}
	assert_eq(Feel.buzz_ms(40), 0, "this desktop")


func test_the_vibration_setting_still_decides() -> void:
	PlatformRules.simulated = ANDROID_BROWSER
	Profile.data.settings.vibration = false
	assert_eq(Feel.buzz_ms(40), 0)


func test_a_browser_never_plays_the_theaters_stand_in() -> void:
	PlatformRules.simulated = ANDROID_BROWSER
	var web := TheaterPanel.new()
	assert_true(web.is_mobile, "no webview in a browser: 'coming soon', as a phone without one")
	web.free()
	PlatformRules.simulated = {}
	var desktop := TheaterPanel.new()
	assert_false(desktop.is_mobile, "the developer's desktop keeps its placeholder player")
	desktop.free()
