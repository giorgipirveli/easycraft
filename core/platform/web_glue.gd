class_name WebGlue
extends RefCounted
## M7 (spec §20.3): the only place the game talks to the page's JavaScript. Every call checks OS.has_feature("web")
## first (JavaScriptBridge does nothing elsewhere) and is a quiet no-op off the web. The rules that decide when these
## are called are PlatformRules, WebStorage and InstallOffer, tested headless; what the scripts do is checked in a
## browser (docs/devlog/parts/m7-web-code.md, m7-install-offer.md).

## The browser's main pointer is a finger: a phone or a tablet, also an iPad whose Safari says "Macintosh". Not
## DisplayServer.is_touchscreen_available(): with input_devices/pointing/emulate_touch_from_mouse on (this project) the
## engine says yes on every desktop too.
const COARSE_POINTER_JS := """(function () {
	try { return window.matchMedia('(pointer: coarse)').matches; } catch (e) { return false; }
})()"""
## Asks the browser once to keep the site's storage (IndexedDB: the worlds and the profile) under storage pressure;
## Chrome decides by itself (installed web app, engagement), Firefox asks the player, Safari keeps a Home Screen app's.
const PERSIST_JS := """(function () {
	if (!(navigator.storage && navigator.storage.persist && navigator.storage.persisted)) { return false; }
	navigator.storage.persisted().then(function (kept) {
		if (kept) { console.log('EasyCraft: storage persisted = true (already)'); return; }
		navigator.storage.persist().then(function (granted) { console.log('EasyCraft: storage persisted = ' + granted); });
	});
	return true;
})()"""
## The page's offer to add the game to the device (web/shell.html's window.easycraftApp): its three answers as JSON, ""
## on a page without it. canInstall: the browser's install prompt is waiting, or Safari (iPhone/iPad Home Screen, Mac
## Dock: steps only); needsGuide: install() opens the page's picture guide (Safari); isInstalled: running as the app,
## or added in this visit.
const INSTALL_STATE_JS := """(function () {
	var app = window.easycraftApp;
	if (!app) { return ''; }
	try {
		return JSON.stringify({can_install: app.canInstall() === true, needs_guide: app.needsGuide() === true,
			installed: app.isInstalled() === true});
	} catch (e) { return ''; }
})()"""
## Starts the browser's install prompt, or opens the page's guide. Browsers allow the prompt only shortly after a tap:
## call it from the button's pressed signal.
const INSTALL_JS := """(function () {
	var app = window.easycraftApp;
	if (!app) { return false; }
	try { return app.install() === true; } catch (e) { return false; }
})()"""

## The texture format of the main pack the page chose by the GPU (web/shell.html's pickPack: "s3tc" for index.pck,
## "etc2" for index.mobile.pck); later packs of pictures must be the same (WebContent.gpu).
const TEXTURE_FORMAT_JS := "(function () { return typeof window.easycraftGpu === 'string' ? window.easycraftGpu : ''; })()"
## The formats a page can name.
const TEXTURE_FORMATS := ["s3tc", "etc2"]


## The shader warm-up's progress (0..1) for the page's loading screen (web/shell.html's window.easycraftWarmup).
static func warmup_js(fraction: float) -> String:
	return "window.easycraftWarmup && window.easycraftWarmup(%.3f)" % clampf(fraction, 0.0, 1.0)


## Shows the shader warm-up's progress on the loading page. False off the web.
static func warmup_progress(fraction: float) -> bool:
	if not OS.has_feature("web"):
		return false
	JavaScriptBridge.eval(warmup_js(fraction), true)
	return true


## Owner #95: the browser's navigator.onLine (ReconnectWatch tries at once when it turns true); true off the web.
static func browser_online() -> bool:
	if not OS.has_feature("web"):
		return true
	return JavaScriptBridge.eval("navigator.onLine !== false", true) != false


static func coarse_pointer() -> bool:
	if not OS.has_feature("web"):
		return false
	return JavaScriptBridge.eval(COARSE_POINTER_JS, true) == true


## The host name of the page ("" off the web).
static func page_host() -> String:
	if not OS.has_feature("web"):
		return ""
	var host: Variant = JavaScriptBridge.eval("window.location.hostname", true)
	return host if host is String else ""


## Offers `bytes` to the player as a file download named `file_name`. False when nothing was offered.
static func download(bytes: PackedByteArray, file_name: String, mime: String) -> bool:
	if not OS.has_feature("web") or bytes.is_empty():
		return false
	JavaScriptBridge.download_buffer(bytes, file_name, mime)
	return true


## navigator.storage.persist(), when the browser has it and the storage is not kept yet. False off the web.
static func ask_persistent_storage() -> bool:
	if not OS.has_feature("web"):
		return false
	return JavaScriptBridge.eval(PERSIST_JS, true) == true


## Whether the page can add the game to this device (InstallOffer): {can_install, needs_guide, installed}, all false
## off the web or on a page without the offer.
static func install_state() -> Dictionary:
	if not OS.has_feature("web"):
		return parse_install_state("")
	return parse_install_state(JavaScriptBridge.eval(INSTALL_STATE_JS, true))


## INSTALL_STATE_JS's answer as a dictionary: only a real true is true.
static func parse_install_state(answer: Variant) -> Dictionary:
	var state := {"can_install": false, "needs_guide": false, "installed": false}
	var json := JSON.new()
	if not answer is String or json.parse(answer) != OK or not json.data is Dictionary:
		return state
	for key: String in state:
		var v: Variant = (json.data as Dictionary).get(key)
		state[key] = typeof(v) == TYPE_BOOL and v
	return state


## The browser's install prompt, or Safari's picture guide over the game. False off the web or when the page has no
## offer.
static func request_install() -> bool:
	if not OS.has_feature("web"):
		return false
	return JavaScriptBridge.eval(INSTALL_JS, true) == true


## Owner #123: a new version of the game has downloaded while this one plays (web/shell.html sets
## window.ecUpdateReady when the new version's worker takes over after the start). False off the web.
static func update_ready() -> bool:
	if not OS.has_feature("web"):
		return false
	return JavaScriptBridge.eval("window.ecUpdateReady === true", true) == true


## Loads the page again: the new version starts (owner #123). Nothing off the web.
static func reload_page() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.reload()", true)


## The page's address (window.location.href; "" off the web). WebContent fetches packs.json from its folder.
static func page_url() -> String:
	if not OS.has_feature("web"):
		return ""
	var href: Variant = JavaScriptBridge.eval("window.location.href", true)
	return href if href is String else ""


## The texture format this GPU reads, as the page chose it ("s3tc" or "etc2"); WebContent.DEFAULT_GPU off the web or on
## a page that did not say.
static func texture_format() -> String:
	if not OS.has_feature("web"):
		return WebContent.DEFAULT_GPU
	return parse_texture_format(JavaScriptBridge.eval(TEXTURE_FORMAT_JS, true))


## TEXTURE_FORMAT_JS's answer: a format the page can name, else WebContent.DEFAULT_GPU.
static func parse_texture_format(answer: Variant) -> String:
	return answer if answer is String and answer in TEXTURE_FORMATS else WebContent.DEFAULT_GPU


# --- Owner #79: the invite link's code and the browser's share sheet (spec §25.2) ---

## The code the page's address brought (web/shell.html keeps ?invite= as window.easycraftInvite, even across its
## redirect to the server's copy): shown as typed (InviteRules.code_from_query), "" off the web or without one.
const INVITE_JS := """(function () {
	return typeof window.easycraftInvite === 'string' ? '?invite=' + window.easycraftInvite : window.location.search;
})()"""


static func invite_code() -> String:
	if not OS.has_feature("web"):
		return ""
	var q: Variant = JavaScriptBridge.eval(INVITE_JS, true)
	return InviteRules.code_from_query(q) if q is String else ""


## Whether this browser has a share sheet (navigator.share: phones and tablets mostly).
static func can_share() -> bool:
	if not OS.has_feature("web"):
		return false
	return JavaScriptBridge.eval("!!(navigator.share)", true) == true


## Opens the browser's share sheet with the invite words and link (call it from a button's pressed signal: browsers allow
## it only just after a tap). False off the web or without one. The words carry only the code and the link.
static func share(text: String, url: String) -> bool:
	if not can_share():
		return false
	JavaScriptBridge.eval("navigator.share({title: 'EasyCraft', text: %s, url: %s}).catch(function () {})" % [
		JSON.stringify(text), JSON.stringify(url)], true)
	return true


# --- Owner #89: the Theater's player in the browser (web/shell.html's window.easycraftTv; TheaterWebPlayer) ---------
# The page shows YouTube's own embedded player exactly over the Theater's screen and its big CLOSE over the game's
# CLOSE (both rects in the canvas's pixels). What reaches the page is a checked video id and numbers, nothing else
# from the channel list. The page answers with events the game takes one at a time: "ended", "closed" (its CLOSE),
# "failed:<YouTube's error code>".

const TV_READY_JS := "(function () { return typeof window.easycraftTv === 'object' && window.easycraftTv !== null; })()"
const TV_HIDE_JS := "window.easycraftTv && window.easycraftTv.hide()"
const TV_CLOSE_JS := "window.easycraftTv && window.easycraftTv.close()"
const TV_EVENT_JS := "(function () { try { return window.easycraftTv ? String(window.easycraftTv.take()) : ''; } catch (e) { return ''; } })()"

static var _tv_event := RegEx.create_from_string("^(ended|closed|failed:[0-9]{1,6})$")


## The page's call that shows video `video_id` at `player`, its CLOSE at `close`; "" when the id is not a YouTube id
## or the player would be under YouTube's 200 × 200 minimum.
static func tv_show_js(video_id: String, player: Rect2i, close: Rect2i, autoplay: bool) -> String:
	if not TheaterChannels.is_video_id(TheaterChannels.YOUTUBE, video_id) or not TheaterRules.is_big_enough(player):
		return ""
	return "window.easycraftTv && window.easycraftTv.show('%s', %d, %d, %d, %d, %d, %d, %d, %d, %s)" % [video_id,
		player.position.x, player.position.y, player.size.x, player.size.y,
		close.position.x, close.position.y, close.size.x, close.size.y, "true" if autoplay else "false"]


## The page has the Theater's player block. False off the web.
static func tv_available() -> bool:
	if not OS.has_feature("web"):
		return false
	return JavaScriptBridge.eval(TV_READY_JS, true) == true


## Shows (or moves) the player; the same id again only moves it. False off the web or for a bad id.
static func tv_show(video_id: String, player: Rect2i, close: Rect2i, autoplay: bool) -> bool:
	var js := tv_show_js(video_id, player, close, autoplay)
	if not OS.has_feature("web") or js == "":
		return false
	JavaScriptBridge.eval(js, true)
	return true


## Pauses and hides the player (a menu covers the middle of the screen); tv_show brings it back.
static func tv_hide() -> bool:
	if not OS.has_feature("web"):
		return false
	JavaScriptBridge.eval(TV_HIDE_JS, true)
	return true


## Stops the video and removes the player.
static func tv_close() -> bool:
	if not OS.has_feature("web"):
		return false
	JavaScriptBridge.eval(TV_CLOSE_JS, true)
	return true


## The page's next event ("" when there is none, or off the web).
static func tv_event() -> String:
	if not OS.has_feature("web"):
		return ""
	return parse_tv_event(JavaScriptBridge.eval(TV_EVENT_JS, true))


## TV_EVENT_JS's answer: only an event the page can name.
static func parse_tv_event(answer: Variant) -> String:
	return answer if answer is String and _tv_event.search(answer) != null else ""
