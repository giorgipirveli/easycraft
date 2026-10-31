extends GutTest
## Owner #96 (spec §5.12b, the Reel Studio): how the rendered reels reach a child. Phones and computers have every video
## in the game (the APK: under ReelPack.ANDROID_CAP together); the browser leaves them out of its first download and
## fetches the reels pack in the background (WebContent, packs.json's "reels"), an iPhone only once the Shorts are open.

const WEB_GAME: Array[String] = ["Web", "Web Mobile"]
const PATTERN := "assets/reels/*.ogv"


func after_each() -> void:
	ReelPack.exists_check = Callable()
	ReelPack.wanted = false


func _presets() -> Dictionary:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK)
	var out := {}
	for section in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			out[str(cfg.get_value(section, "name"))] = {"platform": str(cfg.get_value(section, "platform")),
				"export_filter": str(cfg.get_value(section, "export_filter")),
				"export_files": cfg.get_value(section, "export_files", PackedStringArray()),
				"include_filter": str(cfg.get_value(section, "include_filter", "")),
				"exclude_filter": str(cfg.get_value(section, "exclude_filter", ""))}
	return out


static func _patterns(s: String) -> Array[String]:
	var out: Array[String] = []
	for p in s.split(",", false):
		out.append(p.strip_edges())
	return out


func test_the_browser_leaves_the_videos_for_the_reels_pack() -> void:
	var presets := _presets()
	for game in WEB_GAME:
		assert_has(_patterns(presets[game].exclude_filter), PATTERN, "%s: the first download stays small" % game)
	var pack: Dictionary = presets.get("Web Reels", {})
	assert_false(pack.is_empty(), "the Web Reels preset")
	assert_eq(pack.platform, "Web")
	assert_eq(pack.export_filter, "resources")
	assert_eq(Array(pack.export_files), [], "the pattern chooses: a new reel comes along")
	assert_eq(_patterns(pack.include_filter), [PATTERN])
	assert_eq(pack.exclude_filter, "")
	var script := FileAccess.get_file_as_string("res://tools/export_web.sh")
	assert_string_contains(script, "--export-pack \"Web Reels\"")
	assert_string_contains(script, "{\"name\": \"reels\", \"file\": reels")


func test_phones_keep_every_video() -> void:
	var checked := 0
	var presets := _presets()
	for name: String in presets:
		if presets[name].platform != "Android":
			continue
		checked += 1
		assert_eq(presets[name].export_filter, "all_resources", name)
		assert_does_not_have(_patterns(presets[name].exclude_filter), PATTERN, "%s ships the videos" % name)
	assert_gt(checked, 3)
	for f in DirAccess.get_files_at(ReelPack.DIR):
		if f.ends_with(".ogv"):
			assert_true(ReelPack.present(f.get_basename()), "%s is in the game" % f)


func test_the_reels_pack_is_heard_and_an_iphone_waits_for_the_shorts() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	var root := Node.new()
	add_child_autofree(root)
	var web: WebContent = main.call(&"start_packs", root, {PlatformRules.WEB: true})
	assert_true(web.pack_loaded.is_connected(ReelPack.on_pack_loaded), "the videos' views look again when it lands")
	assert_false(web.later.call(ReelPack.PACK), "a computer's or an Android phone's browser fetches it after the music")
	var iphone := {PlatformRules.WEB: true, PlatformRules.WEB_IOS: true, PlatformRules.TOUCH_SCREEN: true}
	var ios: WebContent = main.call(&"start_packs", root, iphone)
	assert_true(ios.later.call(ReelPack.PACK), "an iPhone keeps its memory until the Shorts are opened")
	ReelPack.wanted = true
	assert_false(ios.later.call(ReelPack.PACK), "then it comes")
	assert_false(ios.later.call("music"), "the music is never held")


func test_opening_the_shorts_wants_the_reels() -> void:
	var v := ShortsView.new()
	v.profile = ProfileData.new()
	v.save_profile = func() -> void: pass
	add_child_autofree(v)
	assert_false(ReelPack.wanted)
	v.open()
	assert_true(ReelPack.wanted)
	v.leave()
