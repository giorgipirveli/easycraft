class_name TheaterWebView
extends RefCounted
## The game's side of the Android player plugin `EasyCraftWebView` (android/plugins/easycraft_webview,
## packaged by addons/easycraft_webview; M3 Task 17). create() returns null when this build has no
## plugin (desktop, headless, and Android APKs built without Gradle): the Theater then shows its
## placeholder or "Coming soon". TheaterPanel calls these methods; the browser's player (TheaterWebPlayer) has the
## same ones, and tests pass a fake with the same methods and signals.
##
## Owner #89: the made-for-kids settings for everyone (the plugin's "child" flag: no third-party cookies, and the
## WebView needs a tap on YouTube's own play button), and the Referer is the package the game runs as.

signal ended
signal failed(code: String)
@warning_ignore("unused_signal")
signal stopped   # the browser's CLOSE; Android has none (EXIT, CLOSE and walking out are the game's)

const SINGLETON := "EasyCraftWebView"

var _plugin: Object
var _referer := TheaterRules.referer()


static func create() -> TheaterWebView:
	if not Engine.has_singleton(SINGLETON):
		return null
	var w := TheaterWebView.new()
	w._plugin = Engine.get_singleton(SINGLETON)
	w._plugin.connect("video_ended", w.ended.emit)
	w._plugin.connect("video_failed", w.failed.emit)
	return w


## Shows `video` (TheaterSession.current()) in one player at `rect` (screen pixels), replacing whatever it showed
## before. `autoplay`: the child picked it. `_close`: where the game's CLOSE is (the browser's player puts its own
## there; the WebView leaves it to the game).
func play(video: Dictionary, autoplay: bool, rect: Rect2i, _close: Rect2i) -> void:
	var html := TheaterEmbed.page(video.get("platform", &""), str(video.get("id", "")), autoplay, _referer)
	if html == "":
		return
	_plugin.call("show_page", html, TheaterEmbed.base_url(_referer), ",".join(TheaterEmbed.hosts()), true, autoplay,
		rect.position.x, rect.position.y, rect.size.x, rect.size.y)


func set_rect(rect: Rect2i, _close: Rect2i) -> void:
	_plugin.call("set_rect", rect.position.x, rect.position.y, rect.size.x, rect.size.y)


## Pauses and hides the player (a menu is over the middle of the screen).
func hide() -> void:
	_plugin.call("hide")


func reveal() -> void:
	_plugin.call("reveal")


## Stops the video and frees the player.
func close() -> void:
	_plugin.call("close")
