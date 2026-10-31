class_name TheaterWebPlayer
extends RefCounted
## The Theater's player in the browser (owner #89; spec §5.12, §20): the page's own block (web/shell.html,
## window.easycraftTv) shows YouTube's embedded player (youtube-nocookie.com, the made-for-kids settings) exactly
## over the panel's screen, and a big CLOSE over the game's CLOSE. The same methods and signals as the Android
## player (TheaterWebView), so TheaterPanel treats them alike. Everything goes through WebGlue; the page's events
## arrive by poll() (the panel calls it a few times a second while a video is on screen).
##
## Safari and Firefox can't show another site's player inside the game's page (its thread headers: COOP/COEP; only
## Chromium has credentialless iframes): there the page shows a WATCH button in the same place, which opens the
## server's player page (server/deploy/site/tv/) in a new tab with its own CLOSE back to the game.

signal ended
signal failed(code: String)
signal stopped   # the page's CLOSE

var _video_id := ""
var _rect := Rect2i()
var _close := Rect2i()


## The browser's player, or null off the web or on a page without the block.
static func create() -> TheaterWebPlayer:
	if not WebGlue.tv_available():
		return null
	return TheaterWebPlayer.new()


func play(video: Dictionary, autoplay: bool, rect: Rect2i, close_rect: Rect2i) -> void:
	if video.get("platform") != TheaterChannels.YOUTUBE:
		return
	_video_id = str(video.get("id", ""))
	_rect = rect
	_close = close_rect
	WebGlue.tv_show(_video_id, rect, close_rect, autoplay)


## The same video, moved (the screen was resized): the page only moves it.
func set_rect(rect: Rect2i, close_rect: Rect2i) -> void:
	_rect = rect
	_close = close_rect
	if _video_id != "":
		WebGlue.tv_show(_video_id, rect, close_rect, false)


func hide() -> void:
	WebGlue.tv_hide()


## Back after a menu: the page shows the paused player again (the same id is only shown, never reloaded).
func reveal() -> void:
	if _video_id != "":
		WebGlue.tv_show(_video_id, _rect, _close, false)


func close() -> void:
	_video_id = ""
	WebGlue.tv_close()


## The page's events since the last poll.
func poll() -> void:
	for i in 4:
		var e := WebGlue.tv_event()
		if e == "":
			return
		if e == "ended":
			ended.emit()
		elif e == "closed":
			_video_id = ""
			stopped.emit()
		elif e.begins_with("failed:"):
			failed.emit(e.trim_prefix("failed:"))
