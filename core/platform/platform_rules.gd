class_name PlatformRules
extends RefCounted
## M7 Task 4 (spec §20.3): one rule for what differs between the Android game, the developer's desktop and the browser.
## Every rule is a pure function of a features dictionary (the engine's feature tags plus two of our own), so tests can
## be a phone browser, a desktop browser, Android or the desktop; current() reads this device once.
## In a browser OS.has_feature("mobile") and "android" are false; phones say web_android or web_ios, and an iPad's
## Safari says web_macos, so a finger pointer (TOUCH_SCREEN, WebGlue.coarse_pointer) makes it a tablet.

const WEB := "web"
const WEB_ANDROID := "web_android"
const WEB_IOS := "web_ios"
const WEB_MACOS := "web_macos"
const WEB_WINDOWS := "web_windows"
const WEB_LINUXBSD := "web_linuxbsd"
const MOBILE := "mobile"
const ANDROID := "android"
## Web only: the browser's main pointer is a finger (a phone or a tablet).
const TOUCH_SCREEN := "touch_screen"
## The developer arg --touch: the touch HUD on the desktop.
const TOUCH_ARG := "touch_arg"
## The OpenGL (Compatibility) renderer draws: every browser (WebGL), and an Android phone or a desktop without Vulkan.
const OPENGL := "opengl"
## Owner #101 (VR on the Meta Quest): the native Quest APK's export feature tag (presets "Quest" and "Quest GL"), and
## the Web VR export's (served at /vr/, for the Quest's browser). Both are headsets: no touch HUD, no pointer lock, no
## phone buzz; phones and the web build at /play/ never have either tag, so they stay exactly as before.
const QUEST := "quest"
const WEBXR := "webxr"

## Where the shutter's photo goes (photo_save).
const PHOTO_GALLERY := &"gallery"     # Android: the phone's gallery (PhotoFiles)
const PHOTO_DOWNLOAD := &"download"   # a browser: kept in the game; DOWNLOAD offers it as a file (PhotoMode)
const PHOTO_FOLDER := &"folder"       # the desktop (and anything else): user://photos


## Tests: a platform to pretend to be ({} = this device).
static var simulated := {}
static var _detected := {}


## This device's features (or the tests' `simulated` one).
static func current() -> Dictionary:
	if not simulated.is_empty():
		return simulated
	if _detected.is_empty():
		_detected = detect()
	return _detected


static func detect() -> Dictionary:
	var f := {}
	for tag: String in [WEB, WEB_ANDROID, WEB_IOS, WEB_MACOS, WEB_WINDOWS, WEB_LINUXBSD, MOBILE, ANDROID, QUEST, WEBXR]:
		f[tag] = OS.has_feature(tag)
	f[TOUCH_SCREEN] = bool(f[WEB]) and WebGlue.coarse_pointer()
	f[TOUCH_ARG] = OS.get_cmdline_user_args().has("--touch")
	f[OPENGL] = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	return f


static func is_web(f: Dictionary) -> bool:
	return f.get(WEB, false) == true


## Owner #101: a headset build (the Quest APK, or the Web VR build).
static func vr_build(f: Dictionary) -> bool:
	return f.get(QUEST, false) == true or f.get(WEBXR, false) == true


## Owner #101: the session starts by itself at launch (the Quest APK); a browser waits for a tap on ENTER VR.
static func starts_vr(f: Dictionary) -> bool:
	return f.get(QUEST, false) == true


## A phone or a tablet: the phone game, or a browser on one.
static func touch_device(f: Dictionary) -> bool:
	if vr_build(f):
		return false   # owner #101: an Android to the engine, but no finger touches a headset
	if f.get(MOBILE, false) == true:
		return true
	return is_web(f) and (f.get(WEB_ANDROID, false) == true or f.get(WEB_IOS, false) == true
		or f.get(TOUCH_SCREEN, false) == true)


## The touch HUD (thumb stick, buttons) instead of keyboard and mouse.
static func touch_ui(f: Dictionary) -> bool:
	return touch_device(f) or f.get(TOUCH_ARG, false) == true


## A click captures the mouse for looking around, and panels free it again (never on a finger: a phone browser
## would ask for pointer lock on every tap).
static func captures_mouse(f: Dictionary) -> bool:
	return not touch_device(f) and not vr_build(f)   # owner #101: a headset has no mouse (a laser click is no lock)


## Owner #84: a PC (a desktop browser, or the desktop game) is a PC game: the keyboard first (a text box takes the
## typing at once, the KEYS card, no "Simple controls?" question). The --touch arg plays the phone on the desktop.
static func keyboard_first(f: Dictionary) -> bool:
	return not touch_ui(f) and not vr_build(f)   # owner #101: a headset has no keyboard; its canvas stays 1280 × 720


## Owner #84: PC-sized menus and HUD: the canvas is PC_CANVAS (everything 80 % as big on the same screen); phones and
## tablets keep the project's 1280 × 720 (their fingers' sizes). Set once at the start (main.gd) as the window's
## content scale factor.
const PHONE_CANVAS := Vector2(1280, 720)
const PC_CANVAS := Vector2(1600, 900)


static func ui_scale(f: Dictionary) -> float:
	return PHONE_CANVAS.y / PC_CANVAS.y if keyboard_first(f) else 1.0


static func canvas_size(f: Dictionary) -> Vector2:
	return PC_CANVAS if keyboard_first(f) else PHONE_CANVAS


## Sets `window`'s content scale for this platform (main.gd, once at the start).
static func apply_ui_scale(window: Window, f: Dictionary) -> void:
	window.content_scale_factor = ui_scale(f)


## Home Wi-Fi play (ENet, LAN): a browser can't open that kind of connection. Online play works everywhere.
static func lan_available(f: Dictionary) -> bool:
	return not is_web(f)


## Quitting the app: a browser tab is closed by the browser.
static func can_quit(f: Dictionary) -> bool:
	return not is_web(f)


static func photo_save(f: Dictionary) -> StringName:
	if f.get(ANDROID, false) == true:
		return PHOTO_GALLERY
	if is_web(f):
		return PHOTO_DOWNLOAD
	return PHOTO_FOLDER


## A new profile starts on LOW (phones and tablets in a browser; only the first start's default, never a saved choice).
static func starts_low_graphics(f: Dictionary) -> bool:
	return is_web(f) and touch_device(f)


static func can_vibrate(f: Dictionary) -> bool:
	if vr_build(f):
		return false   # owner #101: the controllers buzz (Vr.haptic), not a phone's motor
	return f.get(ANDROID, false) == true or (is_web(f) and f.get(WEB_ANDROID, false) == true)


## The HUD keeps clear of the display's notch and corners (the phone game; a page keeps its canvas inside them).
static func reads_safe_area(f: Dictionary) -> bool:
	return f.get(MOBILE, false) == true and not vr_build(f)


## Saves are pushed to the browser's storage (WebStorage).
static func syncs_storage(f: Dictionary) -> bool:
	return is_web(f)


## How often a world saves itself: `usual`, in a browser too (owner 2026-09-28, freezes: each browser save also copies
## the world's database into the browser's storage; the world saves whenever the tab loses focus anyway).
static func autosave_seconds(_f: Dictionary, usual: float) -> float:
	return usual


## The developer's desktop shows stand-ins for parts only a phone has (the Theater's placeholder player); players, on
## a phone or in a browser, never see one.
static func shows_stand_ins(f: Dictionary) -> bool:
	return f.get(MOBILE, false) != true and not is_web(f)


## An iPhone or iPad browser keeps big optional packs until they are wanted (WebContent.later): every start copies all the
## saved files into the tab's memory, and Safari reloads a tab that uses too much (2026-09-28: the realistic pictures).
static func holds_big_packs(f: Dictionary) -> bool:
	return is_web(f) and (f.get(WEB_IOS, false) == true
		or (f.get(WEB_MACOS, false) == true and f.get(TOUCH_SCREEN, false) == true))


## The first download leaves some content out (the music pack), fetched after the start (WebContent).
static func fetches_packs(f: Dictionary) -> bool:
	return is_web(f)


## The OpenGL renderer compiles a material's shader the first time it is drawn, on the main thread (a browser froze
## for seconds at a new world): ShaderWarmup compiles them before the menu. Vulkan compiles its pipelines when a
## material is loaded, in the background (docs/devlog/parts/m7-shader-warmup.md).
static func warms_shaders(f: Dictionary) -> bool:
	return shader_warmup and needs_shader_warmup(f)


## Whether this renderer compiles shaders on first sight (WebGL, or the OpenGL fallback).
static func needs_shader_warmup(f: Dictionary) -> bool:
	return is_web(f) or f.get(OPENGL, false) == true


## On (2026-09-28, the rework: docs/devlog/parts/m7-shader-warmup.md). The lead's ruling at 09:15 kept it off while it
## held the emulator's loading page 44 s on every start; now only what the menu shows holds the page (its progress on
## it) and the rest is spread over the idle menu and the loading card. The one switch to turn it off again.
static var shader_warmup := true
