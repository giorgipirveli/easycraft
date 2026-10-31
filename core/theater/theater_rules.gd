class_name TheaterRules
extends RefCounted
## Who may watch what in the Shorts Theater, and which screen it shows (spec §5.12, §6, §16 H6; M3 Task 17;
## owner #89). Pure rules; `TheaterSession` walks the videos and `TheaterPanel` shows them.
##
## - Everyone gets the made-for-kids settings (owner #89: the game is for children): only videos made for kids,
##   no TikTok (it has no such setting), the privacy-enhanced player without third-party cookies, and nothing
##   starts by itself: a video starts when the child picks it (a tab, a card, NEXT, BACK, PLAY), never when the
##   Theater opens or the video before it ends. Never an endless feed: "That's the show!" comes after 5 videos
##   (a child) or 10 (13+), and the list ends.
## - Under 13 (and any profile without a valid band; only while AgeBand.restrictions is on): the Theater is off
##   until a grown-up switches it on behind the parent gate. A parent can switch it off for anyone.
## - The list's kill-switch hides the whole Theater. Phones and browsers play a real list (bundled or the
##   server's) where there is a player (the Android WebView plugin, the web page's block); an APK without the
##   plugin says "Coming soon". Desktop plays the list as placeholders.

## Identifies the app to the embedded players: the page's base URL and so its Referer, `https://<package>`. The
## debug builds' package (`export_presets.cfg` preset 0; a test checks it); referer_for reads the package the game
## really runs as (the Play build is com.giorgi.easycraft).
const REFERER := "https://com.giorgi.game"
const MIN_PLAYER_PX := 200
const END_CARD_AFTER_KIDS := 5
const END_CARD_AFTER_TEENS := 10

## Owner #89: nothing starts by itself (research H6), for everyone.
const STARTS_ON_OPEN := false          # walking in shows the player, still
const PLAYS_NEXT_BY_ITSELF := false    # the end of a video lights NEXT up and waits
const PICKED_VIDEO_STARTS := true      # a tab, a card, NEXT, BACK or PLAY starts that video at once

## The parent switch (ProfileData.theater_switch): AUTO = on for 13+, off for children.
const SWITCH_AUTO := &"auto"
const SWITCH_ON := &"on"
const SWITCH_OFF := &"off"
const SWITCHES: Array[StringName] = [SWITCH_AUTO, SWITCH_ON, SWITCH_OFF]

const SCREEN_HIDDEN := &"hidden"             # the kill-switch: no Theater at all
const SCREEN_ASK_PARENT := &"ask_parent"     # the parent switch is off for this player
const SCREEN_COMING_SOON := &"coming_soon"   # a phone without a real list or a player
const SCREEN_EMPTY := &"empty"               # nothing this player may watch
const SCREEN_PLAY := &"play"

static var _package := RegEx.create_from_string("^/data/(?:user/[0-9]+|data)/([a-z][a-z0-9_]*(?:\\.[a-z][a-z0-9_]*)+)/")


static func valid_switch(s: StringName) -> StringName:
	return s if SWITCHES.has(s) else SWITCH_AUTO


## Only a profile that is surely 13+ gets the 13+ rules (the panel passes AgeBand.effective's band).
static func is_child(band: StringName) -> bool:
	return band != AgeBand.TEEN_PLUS


static func is_allowed(band: StringName, switch: StringName) -> bool:
	match valid_switch(switch):
		SWITCH_ON:
			return true
		SWITCH_OFF:
			return false
	return not is_child(band)


## The channels anyone may see, each with only its videos made for kids. EasyCraft TV stays first (the list keeps
## it there). `band` is kept for the day a 13+ rule comes back; today it changes nothing here.
static func channels_for(list: Dictionary, _band: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c: Dictionary in list.get("channels", []):
		if c.platform != TheaterChannels.YOUTUBE:
			continue
		var videos := videos_for(c)
		if videos.is_empty():
			continue
		var copy := c.duplicate()
		copy.videos = videos
		out.append(copy)
	return out


static func videos_for(channel: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if channel.get("platform") != TheaterChannels.YOUTUBE:
		return out
	for v: Dictionary in channel.get("videos", []):
		if v.made_for_kids == true:
			out.append(v)
	return out


## After this many videos, "That's the show!" (a natural stopping point, spec §6).
static func end_card_after(band: StringName) -> int:
	return END_CARD_AFTER_KIDS if is_child(band) else END_CARD_AFTER_TEENS


static func screen(list: Dictionary, band: StringName, switch: StringName, is_mobile: bool, has_player: bool,
		live: bool) -> StringName:
	if list.get("enabled") != true:
		return SCREEN_HIDDEN
	if not is_allowed(band, switch):
		return SCREEN_ASK_PARENT
	if channels_for(list, band).is_empty():
		return SCREEN_EMPTY
	if is_mobile and (not has_player or (not TheaterChannels.is_real(list) and not live)):
		return SCREEN_COMING_SOON
	return SCREEN_PLAY


## The Referer for the app whose data folder is `data_dir` (OS.get_user_data_dir(): /data/user/<n>/<package>/files
## on Android): `https://<package>`, else REFERER. Only a real package name, so nothing else reaches the page.
static func referer_for(data_dir: String) -> String:
	var m := _package.search(data_dir)
	return "https://" + m.get_string(1) if m else REFERER


## This run's Referer.
static func referer() -> String:
	return referer_for(OS.get_user_data_dir() + "/")


## A canvas rectangle in screen pixels (`xf`: the canvas item's screen transform).
static func pixel_rect(rect: Rect2, xf: Transform2D) -> Rect2i:
	var a := (xf * rect.position).round()
	var b := (xf * rect.end).round()
	return Rect2i(Vector2i(a), Vector2i(b - a))


## The embedded players' minimum size.
static func is_big_enough(px: Rect2i) -> bool:
	return px.size.x >= MIN_PLAYER_PX and px.size.y >= MIN_PLAYER_PX
