extends GutTest
## M7 Task 4 (spec §20.3): one platform rule for what differs between the Android game, the developer's desktop and
## the browser (web_android / web_ios phones, iPads that call themselves Macs, desktop browsers). Each platform here is
## the features dictionary PlatformRules.current() reads from the engine.

const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}
const DESKTOP := {}
const DESKTOP_TOUCH_ARG := {PlatformRules.TOUCH_ARG: true}   # the developer arg --touch
const ANDROID_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
const IPHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_IOS: true, PlatformRules.TOUCH_SCREEN: true}
## Safari on an iPad says "Macintosh" (web_macos): only its finger pointer tells it is a tablet.
const IPAD_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_MACOS: true, PlatformRules.TOUCH_SCREEN: true}
const DESKTOP_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}


func after_each() -> void:
	PlatformRules.simulated = {}


func test_phones_and_tablets_get_the_touch_hud_desktops_keyboard_and_mouse() -> void:
	assert_true(PlatformRules.touch_ui(ANDROID), "the Android game")
	assert_true(PlatformRules.touch_ui(ANDROID_BROWSER), "Chrome on an Android phone")
	assert_true(PlatformRules.touch_ui(IPHONE_BROWSER), "Safari on an iPhone")
	assert_true(PlatformRules.touch_ui(IPAD_BROWSER), "Safari on an iPad")
	assert_false(PlatformRules.touch_ui(DESKTOP_BROWSER), "a desktop browser")
	assert_false(PlatformRules.touch_ui(DESKTOP), "the developer's desktop")
	assert_true(PlatformRules.touch_ui(DESKTOP_TOUCH_ARG), "--touch shows the touch HUD on the desktop, as before")


func test_a_phone_browser_counts_even_before_its_pointer_is_known() -> void:
	assert_true(PlatformRules.touch_ui({PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true}), "web_android alone")
	assert_true(PlatformRules.touch_ui({PlatformRules.WEB: true, PlatformRules.WEB_IOS: true}), "web_ios alone")


func test_only_devices_with_a_mouse_capture_it() -> void:
	assert_true(PlatformRules.captures_mouse(DESKTOP))
	assert_true(PlatformRules.captures_mouse(DESKTOP_BROWSER))
	assert_true(PlatformRules.captures_mouse(DESKTOP_TOUCH_ARG), "--touch on the desktop still captures the mouse, as before")
	assert_false(PlatformRules.captures_mouse(ANDROID))
	assert_false(PlatformRules.captures_mouse(ANDROID_BROWSER), "a tap on a phone browser must not ask for pointer lock")
	assert_false(PlatformRules.captures_mouse(IPAD_BROWSER))


func test_home_wifi_play_is_not_in_the_browser() -> void:
	assert_true(PlatformRules.lan_available(ANDROID))
	assert_true(PlatformRules.lan_available(DESKTOP))
	for web: Dictionary in [ANDROID_BROWSER, IPHONE_BROWSER, IPAD_BROWSER, DESKTOP_BROWSER]:
		assert_false(PlatformRules.lan_available(web), "no ENet or UDP in a browser: %s" % [web])


func test_a_browser_tab_has_no_quit() -> void:
	assert_true(PlatformRules.can_quit(ANDROID))
	assert_true(PlatformRules.can_quit(DESKTOP))
	assert_false(PlatformRules.can_quit(ANDROID_BROWSER))
	assert_false(PlatformRules.can_quit(DESKTOP_BROWSER))


func test_photos_go_to_the_gallery_a_download_or_the_folder() -> void:
	assert_eq(PlatformRules.photo_save(ANDROID), PlatformRules.PHOTO_GALLERY)
	assert_eq(PlatformRules.photo_save(DESKTOP), PlatformRules.PHOTO_FOLDER)
	assert_eq(PlatformRules.photo_save(ANDROID_BROWSER), PlatformRules.PHOTO_DOWNLOAD)
	assert_eq(PlatformRules.photo_save(IPHONE_BROWSER), PlatformRules.PHOTO_DOWNLOAD)
	assert_eq(PlatformRules.photo_save(DESKTOP_BROWSER), PlatformRules.PHOTO_DOWNLOAD)


func test_phones_and_tablets_in_the_browser_start_on_low() -> void:
	assert_true(PlatformRules.starts_low_graphics(ANDROID_BROWSER))
	assert_true(PlatformRules.starts_low_graphics(IPHONE_BROWSER))
	assert_true(PlatformRules.starts_low_graphics(IPAD_BROWSER))
	assert_false(PlatformRules.starts_low_graphics(DESKTOP_BROWSER), "a desktop browser: the device decides, as elsewhere")
	assert_false(PlatformRules.starts_low_graphics(ANDROID), "the Android game: its memory and cores decide (M5 Task 3)")
	assert_false(PlatformRules.starts_low_graphics(DESKTOP))


func test_only_android_phones_buzz() -> void:
	assert_true(PlatformRules.can_vibrate(ANDROID))
	assert_true(PlatformRules.can_vibrate(ANDROID_BROWSER), "Chrome on Android has navigator.vibrate")
	assert_false(PlatformRules.can_vibrate(IPHONE_BROWSER), "Safari has no vibration")
	assert_false(PlatformRules.can_vibrate(DESKTOP_BROWSER))
	assert_false(PlatformRules.can_vibrate(DESKTOP))


func test_the_display_safe_area_is_read_in_the_phone_game_only() -> void:
	assert_true(PlatformRules.reads_safe_area(ANDROID))
	assert_false(PlatformRules.reads_safe_area(ANDROID_BROWSER), "the page keeps its canvas inside the safe area")
	assert_false(PlatformRules.reads_safe_area(DESKTOP))


func test_the_browser_pushes_its_saves_to_storage() -> void:
	assert_true(PlatformRules.syncs_storage(ANDROID_BROWSER))
	assert_true(PlatformRules.syncs_storage(DESKTOP_BROWSER))
	assert_false(PlatformRules.syncs_storage(ANDROID))
	assert_false(PlatformRules.syncs_storage(DESKTOP))


## Owner 2026-09-28 "from time to time when playing it freezes": every browser save also copies the world's database
## into the browser's storage, a stall a phone feels, and the world already saves whenever the tab loses focus (a
## locked phone, another tab: sandbox.gd's NOTIFICATION_APPLICATION_FOCUS_OUT). So a browser saves as often as a phone.
func test_the_browser_saves_as_often_as_a_phone() -> void:
	assert_eq(PlatformRules.autosave_seconds(ANDROID, 60.0), 60.0)
	assert_eq(PlatformRules.autosave_seconds(DESKTOP, 60.0), 60.0)
	assert_eq(PlatformRules.autosave_seconds(ANDROID_BROWSER, 60.0), 60.0)
	assert_eq(PlatformRules.autosave_seconds(DESKTOP_BROWSER, 5.0), 5.0, "never less often than asked")


func test_only_the_developers_desktop_shows_stand_ins() -> void:
	assert_true(PlatformRules.shows_stand_ins(DESKTOP), "the Theater's placeholder player")
	assert_false(PlatformRules.shows_stand_ins(ANDROID))
	assert_false(PlatformRules.shows_stand_ins(ANDROID_BROWSER), "players in a browser never see a stand-in")
	assert_false(PlatformRules.shows_stand_ins(DESKTOP_BROWSER))


func test_this_test_run_is_a_desktop() -> void:
	var here := PlatformRules.current()
	assert_false(PlatformRules.is_web(here))
	assert_true(PlatformRules.lan_available(here))
	assert_true(PlatformRules.can_quit(here))
	assert_eq(PlatformRules.photo_save(here), PlatformRules.PHOTO_FOLDER)
	assert_false(PlatformRules.touch_ui(here), "no --touch in a test run")
	assert_false(bool(here.get(PlatformRules.TOUCH_SCREEN, false)),
		"a touch screen is a browser's finger pointer only: emulate_touch_from_mouse makes the engine say yes everywhere")


func test_tests_can_pretend_to_be_a_phone_browser() -> void:
	PlatformRules.simulated = ANDROID_BROWSER
	assert_eq(PlatformRules.current(), ANDROID_BROWSER)
	assert_true(PlatformRules.touch_ui(PlatformRules.current()))
	PlatformRules.simulated = {}
	assert_false(PlatformRules.is_web(PlatformRules.current()), "and back")


## 2026-09-28: an iPhone or iPad browser holds big optional packs (the realistic pictures) until they are wanted: every
## start copies all the saved files into the tab's memory, and Safari reloads a tab that uses too much.
func test_apple_browsers_hold_big_packs_until_wanted() -> void:
	assert_true(PlatformRules.holds_big_packs(IPHONE_BROWSER), "an iPhone")
	assert_true(PlatformRules.holds_big_packs({PlatformRules.WEB: true, PlatformRules.WEB_MACOS: true,
		PlatformRules.TOUCH_SCREEN: true}), "an iPad (its Safari says macOS)")
	assert_false(PlatformRules.holds_big_packs({PlatformRules.WEB: true, PlatformRules.WEB_MACOS: true}), "a Mac")
	assert_false(PlatformRules.holds_big_packs({PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true,
		PlatformRules.TOUCH_SCREEN: true}), "an Android phone's browser")
	assert_false(PlatformRules.holds_big_packs({PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}), "a PC")
	assert_false(PlatformRules.holds_big_packs({PlatformRules.ANDROID: true, PlatformRules.MOBILE: true}),
		"the Android app has everything already")


## M7 (docs/devlog/parts/m7-shader-warmup.md): the OpenGL renderer (every browser, and an Android phone or a desktop that
## fell back to OpenGL) compiles a material's shader the first time it is drawn, on the main thread: the game compiles
## them before the menu (ShaderWarmup). Vulkan (the Android app, the desktop) does not wait for them.
func test_the_opengl_renderer_warms_its_shaders_before_the_menu() -> void:
	assert_true(PlatformRules.warms_shaders(ANDROID_BROWSER), "a phone browser (WebGL)")
	assert_true(PlatformRules.warms_shaders(IPHONE_BROWSER), "an iPhone browser (WebGL)")
	assert_true(PlatformRules.warms_shaders(DESKTOP_BROWSER), "a desktop browser (WebGL)")
	assert_false(PlatformRules.warms_shaders(ANDROID), "the Android app on Vulkan")
	assert_false(PlatformRules.warms_shaders(DESKTOP), "the developer's desktop on Vulkan")
	assert_true(PlatformRules.warms_shaders(ANDROID.merged({PlatformRules.OPENGL: true})),
		"an Android phone without Vulkan (the OpenGL fallback)")
	assert_false(PlatformRules.warms_shaders(PlatformRules.current()), "this test run (no OpenGL window)")


## The lead's ruling (2026-09-28 09:15) kept the warm-up off while it held the emulator's loading page 44 s on every
## start. Reworked (docs/devlog/parts/m7-shader-warmup.md, "The rework"): only what the menu shows holds the page, with
## its progress on it; a first world's draws come behind the idle menu and the loading card, the rest never in play.
## On in every browser; `shader_warmup` stays the one switch to turn it off.
func test_the_shader_warm_up_is_on_in_every_browser_since_its_rework() -> void:
	assert_true(PlatformRules.shader_warmup, "on by default")
	assert_true(PlatformRules.warms_shaders(ANDROID_BROWSER), "a phone browser warms its shaders")
	assert_true(PlatformRules.needs_shader_warmup(ANDROID_BROWSER))
	assert_false(PlatformRules.warms_shaders(ANDROID), "never the Android app (Vulkan)")


## Owner #84: in a PC browser (and on the desktop) the game is a PC game: keyboard first (a text box takes the typing
## at once, the KEYS card), and PC-sized menus and HUD (the canvas is 1600 × 900 instead of the phone's 1280 × 720, so
## everything is 80 % as big on the same screen). Phones and tablets keep their big fingers' sizes.
func test_a_pc_is_keyboard_first_with_pc_sized_menus() -> void:
	for f: Dictionary in [DESKTOP_BROWSER, DESKTOP]:
		assert_true(PlatformRules.keyboard_first(f), str(f))
		assert_almost_eq(PlatformRules.ui_scale(f), 0.8, 0.001, "PC-sized: %s" % f)
	for f: Dictionary in [ANDROID, ANDROID_BROWSER, IPHONE_BROWSER, IPAD_BROWSER, DESKTOP_TOUCH_ARG]:
		assert_false(PlatformRules.keyboard_first(f), str(f))
		assert_eq(PlatformRules.ui_scale(f), 1.0, "a finger's size: %s" % f)
	assert_eq(PlatformRules.canvas_size(DESKTOP_BROWSER), Vector2(1600, 900))
	assert_eq(PlatformRules.canvas_size(ANDROID), Vector2(1280, 720))
