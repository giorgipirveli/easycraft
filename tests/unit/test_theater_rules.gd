extends GutTest
## M3 Task 17 (spec §5.12, §6, §16 H6): who may watch what in the Shorts Theater, which screen it
## shows, and the page that holds the official embedded player. Owner #89: the made-for-kids settings for
## everyone (only videos made for kids, no TikTok, nothing starts by itself), the real list plays on phones and in
## the browser, and the Referer names the app it runs in.

const KID := AgeBand.UNDER_13
const TEEN := AgeBand.TEEN_PLUS

var sample: Dictionary
var bundled: Dictionary


func before_all() -> void:
	sample = TheaterChannels.load_path(TheaterChannels.SAMPLE_PATH)
	bundled = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)


func _with(list: Dictionary, extra: Dictionary) -> Dictionary:
	var out := list.duplicate(true)
	out.merge(extra, true)
	return out


func _ids(list: Dictionary, band: StringName) -> Array:
	var out: Array = []
	for c: Dictionary in TheaterRules.channels_for(list, band):
		for v: Dictionary in c.videos:
			out.append(v.id)
	return out


# --- What everyone may watch ---------------------------------------------------------------------

func test_everyone_sees_only_made_for_kids_videos() -> void:
	for band: StringName in [KID, TEEN]:
		var channels := TheaterRules.channels_for(sample, band)
		assert_gt(channels.size(), 0)
		for c: Dictionary in channels:
			assert_gt(c.videos.size(), 0, "%s keeps its kids' videos" % c.id)
			for v: Dictionary in c.videos:
				assert_true(v.made_for_kids, "%s: %s / %s is made for kids" % [band, c.id, v.id])
		assert_does_not_have(_ids(sample, band), "aqz-KE-bpKQ", "%s: a video not made for kids is hidden" % band)
		assert_does_not_have(_ids(sample, band), "AnimalSmpl3")


func test_nobody_gets_tiktok() -> void:
	for band: StringName in [KID, TEEN]:
		for c: Dictionary in TheaterRules.channels_for(sample, band):
			assert_ne(c.platform, TheaterChannels.TIKTOK, "%s: TikTok has no made-for-kids setting" % band)
	var list := TheaterChannels.parse(JSON.stringify({"enabled": true, "channels": [
		{"id": "tt", "title": "T", "platform": "tiktok", "videos": [{"id": "7000000000000000001", "title": "x", "made_for_kids": true}]}]}))
	assert_eq(TheaterRules.channels_for(list, KID), [])
	assert_eq(TheaterRules.channels_for(list, TEEN), [])


func test_a_channel_with_nothing_for_kids_is_left_out() -> void:
	var list := TheaterChannels.parse(JSON.stringify({"enabled": true, "channels": [
		{"id": "grown", "title": "G", "platform": "youtube", "videos": [{"id": "GrownVideo1", "title": "x", "made_for_kids": false}]},
		{"id": "kids", "title": "K", "platform": "youtube", "videos": [{"id": "KidsVideo01", "title": "x", "made_for_kids": true}]}]}))
	for band: StringName in [KID, TEEN]:
		assert_eq(TheaterRules.channels_for(list, band).map(func(c: Dictionary) -> String: return c.id), ["kids"])


func test_the_bundled_list_shows_whole_to_everyone() -> void:
	for band: StringName in [KID, TEEN]:
		var channels := TheaterRules.channels_for(bundled, band)
		assert_eq(channels.size(), bundled.channels.size(), String(band))
		for i in channels.size():
			assert_eq(channels[i].videos.size(), bundled.channels[i].videos.size(), "%s %s" % [band, channels[i].id])


func test_easycraft_tv_stays_first_for_everyone() -> void:
	for band: StringName in [KID, TEEN]:
		assert_eq(TheaterRules.channels_for(sample, band)[0].id, TheaterChannels.EASYCRAFT_TV, String(band))


func test_an_unknown_band_gets_the_child_rules() -> void:
	for band: StringName in [&"", &"adult", &"13+"]:
		assert_eq(TheaterRules.end_card_after(band), TheaterRules.END_CARD_AFTER_KIDS, String(band))
		assert_false(TheaterRules.is_allowed(band, TheaterRules.SWITCH_AUTO), String(band))


func test_the_end_card_comes_after_5_videos_for_a_child() -> void:
	assert_eq(TheaterRules.END_CARD_AFTER_KIDS, 5)
	assert_eq(TheaterRules.end_card_after(KID), 5)
	assert_gt(TheaterRules.end_card_after(TEEN), 5, "13+ gets a later stopping point")


## Owner #89: a video starts when the child picks it; nothing starts by itself (walking in, the end of a video).
func test_nothing_starts_by_itself() -> void:
	assert_false(TheaterRules.STARTS_ON_OPEN, "walking in shows the player, still")
	assert_false(TheaterRules.PLAYS_NEXT_BY_ITSELF, "the end of a video waits for NEXT")
	assert_true(TheaterRules.PICKED_VIDEO_STARTS, "a tab, a card, NEXT, BACK or PLAY starts that video")


# --- The parent switch -------------------------------------------------------------------------

func test_the_parent_switch() -> void:
	assert_false(TheaterRules.is_allowed(KID, TheaterRules.SWITCH_AUTO), "off for children until a grown-up opens it")
	assert_true(TheaterRules.is_allowed(KID, TheaterRules.SWITCH_ON))
	assert_false(TheaterRules.is_allowed(KID, TheaterRules.SWITCH_OFF))
	assert_true(TheaterRules.is_allowed(TEEN, TheaterRules.SWITCH_AUTO))
	assert_true(TheaterRules.is_allowed(TEEN, TheaterRules.SWITCH_ON))
	assert_false(TheaterRules.is_allowed(TEEN, TheaterRules.SWITCH_OFF), "a parent can switch it off for anyone")
	assert_eq(TheaterRules.valid_switch(&"on"), TheaterRules.SWITCH_ON)
	assert_eq(TheaterRules.valid_switch(&"banana"), TheaterRules.SWITCH_AUTO)


# --- Which screen ------------------------------------------------------------------------------

func test_the_kill_switch_hides_everything() -> void:
	for list: Dictionary in [sample, bundled]:
		var off := _with(list, {"enabled": false})
		for band: StringName in [KID, TEEN]:
			for mobile: bool in [false, true]:
				assert_eq(TheaterRules.screen(off, band, TheaterRules.SWITCH_ON, mobile, true, true), TheaterRules.SCREEN_HIDDEN)


func test_a_child_without_the_parent_switch_is_asked_to_get_a_grown_up() -> void:
	assert_eq(TheaterRules.screen(sample, KID, TheaterRules.SWITCH_AUTO, false, false, false), TheaterRules.SCREEN_ASK_PARENT)
	assert_eq(TheaterRules.screen(bundled, TEEN, TheaterRules.SWITCH_OFF, true, true, false), TheaterRules.SCREEN_ASK_PARENT)


func test_desktop_plays_the_list_with_placeholders() -> void:
	assert_eq(TheaterRules.screen(sample, TEEN, TheaterRules.SWITCH_AUTO, false, false, false), TheaterRules.SCREEN_PLAY)
	assert_eq(TheaterRules.screen(bundled, KID, TheaterRules.SWITCH_ON, false, false, false), TheaterRules.SCREEN_PLAY)


func test_phones_and_browsers_play_a_real_list_with_a_player() -> void:
	assert_eq(TheaterRules.screen(sample, TEEN, TheaterRules.SWITCH_AUTO, true, true, false), TheaterRules.SCREEN_COMING_SOON,
		"the sample list is not real content")
	for real: Dictionary in [bundled, _with(sample, {"source": TheaterChannels.SOURCE_SERVER})]:
		assert_eq(TheaterRules.screen(real, TEEN, TheaterRules.SWITCH_AUTO, true, false, false), TheaterRules.SCREEN_COMING_SOON,
			"a build without a player (an APK without the WebView plugin) can't play")
		assert_eq(TheaterRules.screen(real, TEEN, TheaterRules.SWITCH_AUTO, true, true, false), TheaterRules.SCREEN_PLAY)
	assert_eq(TheaterRules.screen(sample, TEEN, TheaterRules.SWITCH_AUTO, true, true, true), TheaterRules.SCREEN_PLAY,
		"the live check build plays the sample through the plugin")


func test_nothing_to_watch_says_so() -> void:
	var grown_only := TheaterChannels.parse(JSON.stringify({"enabled": true, "channels": [
		{"id": "grown", "title": "G", "platform": "youtube", "videos": [{"id": "GrownVideo1", "title": "x", "made_for_kids": false}]}]}))
	for band: StringName in [KID, TEEN]:
		assert_eq(TheaterRules.screen(grown_only, band, TheaterRules.SWITCH_ON, false, false, false), TheaterRules.SCREEN_EMPTY)


# --- The Referer: the app the player runs in -------------------------------------------------------

func test_the_default_referer_is_the_debug_package() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var package := str(presets.get_value("preset.0.options", "package/unique_name", ""))
	assert_ne(package, "")
	assert_eq(TheaterRules.REFERER, "https://" + package, "the Referer identifies the app (update both together)")


## Owner #89: the Play build is com.giorgi.easycraft, the debug builds com.giorgi.game: the Referer is read from the
## app's own data folder (/data/user/0/<package>/files), so each identifies itself.
func test_the_referer_names_the_package_the_game_runs_as() -> void:
	var presets := ConfigFile.new()
	presets.load("res://export_presets.cfg")
	var packages := {}
	for section: String in presets.get_sections():
		if presets.has_section_key(section, "package/unique_name"):
			packages[str(presets.get_value(section, "package/unique_name"))] = true
	assert_has(packages, "com.giorgi.easycraft", "the Play build's package")
	for package: String in packages:
		assert_eq(TheaterRules.referer_for("/data/user/0/%s/files" % package), "https://" + package, package)
		assert_eq(TheaterRules.referer_for("/data/data/%s/files" % package), "https://" + package, package)
		assert_eq(TheaterRules.referer_for("/data/user/10/%s/files" % package), "https://" + package, "another Android user")
	for other: String in ["", "/home/giorgi/.local/share/godot/app_userdata/EasyCraft", "/data/user/0/Bad Name/files",
			"/data/user/0/nodots/files", "/data/user/0/com.x.y'onload=1/files", "C:\\Users\\kid\\AppData"]:
		assert_eq(TheaterRules.referer_for(other), TheaterRules.REFERER, "not an Android app folder: %s" % other)


# --- The embedded player's page (Android) ----------------------------------------------------------

func test_the_youtube_page_uses_the_official_player() -> void:
	var page := TheaterEmbed.page(TheaterChannels.YOUTUBE, "aqz-KE-bpKQ", true, "https://com.giorgi.easycraft")
	assert_string_contains(page, "https://www.youtube.com/iframe_api", "the official IFrame player API")
	assert_string_contains(page, "videoId:'aqz-KE-bpKQ'")
	assert_string_contains(page, "https://www.youtube-nocookie.com", "privacy-enhanced mode")
	assert_string_contains(page, "origin:'https://com.giorgi.easycraft'", "the app it runs in")
	assert_string_contains(page, "autoplay:1", "a picked video starts")
	assert_string_contains(page, "rel:0", "no suggestions from other channels")
	assert_string_contains(page, "EasyCraft.ended", "the page reports the end of a video")
	assert_eq(TheaterEmbed.base_url("https://com.giorgi.easycraft"), "https://com.giorgi.easycraft/")


func test_a_page_opened_by_walking_in_waits() -> void:
	var page := TheaterEmbed.page(TheaterChannels.YOUTUBE, "ECtvSample1", false, TheaterRules.REFERER)
	assert_string_contains(page, "autoplay:0")
	assert_false(page.contains("autoplay:1"))


func test_the_page_has_nothing_over_the_player() -> void:
	var page := TheaterEmbed.page(TheaterChannels.YOUTUBE, "aqz-KE-bpKQ", true, TheaterRules.REFERER)
	var body := page.get_slice("<body>", 1).get_slice("<script", 0)
	var tags := 0
	for tag: String in ["<div", "<iframe", "<img", "<button", "<a ", "<p", "<span", "<video", "<canvas"]:
		tags += body.count(tag)
	assert_eq(tags, 1, "one element, the player, and nothing drawn over it: %s" % body)
	assert_string_contains(page, "width:100%", "the player fills the panel")


func test_no_page_for_a_bad_id_a_bad_referer_or_tiktok() -> void:
	assert_eq(TheaterEmbed.page(TheaterChannels.YOUTUBE, "x'});alert(1);//", true, TheaterRules.REFERER), "", "no script injection")
	assert_eq(TheaterEmbed.page(TheaterChannels.YOUTUBE, "aqz-KE-bpKQ", true, "https://x.y'});alert(1)//"), "",
		"a Referer that is not a package name never goes into the page")
	assert_eq(TheaterEmbed.page(TheaterChannels.TIKTOK, "7000000000000000001", true, TheaterRules.REFERER), "", "no TikTok")
	assert_eq(TheaterEmbed.page(&"vimeo", "12345678901", true, TheaterRules.REFERER), "")


func test_the_player_may_only_load_from_youtubes_hosts() -> void:
	var yt := TheaterEmbed.hosts()
	assert_has(yt, "youtube-nocookie.com")
	assert_has(yt, "youtube.com")
	assert_does_not_have(yt, "tiktok.com")


# --- The panel's size on screen ----------------------------------------------------------------

func test_the_player_rect_in_screen_pixels() -> void:
	var xf := Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2.ZERO)   # 1600 x 720 viewport on 2400 x 1080
	var r := TheaterRules.pixel_rect(Rect2(560, 152, 480, 270), xf)
	assert_eq(r, Rect2i(840, 228, 720, 405))
	assert_true(TheaterRules.is_big_enough(r))


func test_the_player_must_be_at_least_200_by_200_pixels() -> void:
	assert_false(TheaterRules.is_big_enough(Rect2i(0, 0, 199, 400)))
	assert_false(TheaterRules.is_big_enough(Rect2i(0, 0, 400, 199)))
	assert_true(TheaterRules.is_big_enough(Rect2i(0, 0, 200, 200)))
