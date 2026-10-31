extends GutTest
## M7 (owner 2026-09-28: "make sure it loads fast … after refresh i dont need to redownload the data, this is
## important"): every deploy changes index.pck, and 7.9 of its 12.8 MB were media that rarely change. In a browser the
## game's media (the sounds and ambience, the three core music loops, the characters' models and skins: PATTERNS) come
## in their own pack, assets.<hash>.pck, one per texture format like the main pack. The page (web/shell.html) downloads
## it next to index.pck before the engine starts and puts it at PATH in the engine's file system; the service worker
## keeps it by its content, so an update that changes only code downloads only index.pck. The FIRST autoload
## (autoloads/assets_pack.gd) loads it: autoloads are loaded and made one by one, so every later autoload's preload
## (Music's loops) finds its file. Android and the desktop keep everything in their one pack.

const LOADER := "res://autoloads/assets_pack.gd"
## The media that move out of the browser's main packs (source paths, as the exporter matches its filters: Godot's `*`
## crosses `/`). By extension, so an `.import` or a licence text never goes along; a new kind of media file under
## assets/audio or assets/characters makes test_the_patterns_catch_the_media_and_nothing_else fail until it has one.
const PATTERNS := ["assets/audio/*.ogg", "assets/audio/*.wav", "assets/characters/*.png", "assets/characters/*.fbx",
	"assets/music/day.ogg", "assets/music/night.ogg", "assets/music/boss.ogg"]
## The folders whose every resource moves.
const MEDIA_DIRS := ["res://assets/audio/", "res://assets/characters/"]
const MEDIA_EXTENSIONS := ["ogg", "wav", "png", "fbx"]
## The browser's game presets (one per texture format) and the assets pack of the same format.
const WEB_GAME := {"Web": "Web Assets", "Web Mobile": "Web Assets Mobile"}


func _loader() -> GDScript:
	return load(LOADER) if ResourceLoader.exists(LOADER) else null


func _presets() -> Dictionary:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK)
	var out := {}
	for section in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			var options := {}
			for key in cfg.get_section_keys(section + ".options"):
				options[key] = cfg.get_value(section + ".options", key)
			out[str(cfg.get_value(section, "name"))] = {"export_filter": cfg.get_value(section, "export_filter"),
				"include_filter": str(cfg.get_value(section, "include_filter", "")),
				"exclude_filter": str(cfg.get_value(section, "exclude_filter", "")),
				"export_files": cfg.get_value(section, "export_files", PackedStringArray()),
				"platform": cfg.get_value(section, "platform"), "options": options}
	return out


func _patterns(filter: String) -> Array:
	return Array(filter.split(",", false)).map(func(p: String) -> String: return p.strip_edges())


## As Godot's exporter matches a filter: the path with and without "res://".
func _caught(path: String, patterns: Array = PATTERNS) -> bool:
	for p: String in patterns:
		if path.matchn(p) or path.trim_prefix("res://").matchn(p):
			return true
	return false


## Every file of the project an export could see (not in hidden folders or build/).
func _project_files(dir: String = "res://") -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if not d.begins_with(".") and not (dir == "res://" and d == "build"):
			out.append_array(_project_files(dir.path_join(d)))
	return out


# --- the loader (autoloads/assets_pack.gd) ----------------------------------------------------------------------------

func test_the_loader_comes_right_after_the_updater() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK)
	var names := cfg.get_section_keys("autoload")
	assert_gt(names.size(), 2)
	# Owner #123: the Android updater (autoloads/updater.gd, idle in a browser) is first; the media's pack right after.
	assert_eq(names[0], "Updater", "the updater's patch pack comes before every other autoload's script")
	assert_eq(names[1], "AssetsPack", "before every autoload whose preloads need the media: %s" % [names])
	assert_eq(str(cfg.get_value("autoload", names[1])).trim_prefix("*"), LOADER)


func test_the_loader_uses_nothing_of_the_game() -> void:
	# It is loaded before the pack is in: a preload, a path or another script of the game in it would be loaded first.
	assert_not_null(_loader(), LOADER)
	assert_eq(Array(ResourceLoader.get_dependencies(LOADER)), [], "no dependencies")
	var code := "\n".join(Array(FileAccess.get_file_as_string(LOADER).split("\n")).filter(
		func(line: String) -> bool: return not line.strip_edges().begins_with("#")))
	assert_false(code.contains("preload("), "no preload")
	assert_false(code.contains("res://") or code.contains("uid://"), "no path of the game")
	assert_false(code.contains("class_name"), "no global name of its own")
	var used: Array = []
	for c: Dictionary in ProjectSettings.get_global_class_list():
		var re := RegEx.create_from_string("\\b%s\\b" % c["class"])
		if re.search(code):
			used.append(c["class"])
	assert_eq(used, [], "no class of the game")


func test_the_pack_is_in_the_engines_own_file_system() -> void:
	var loader := _loader()
	assert_not_null(loader)
	if loader == null:
		return
	var path: String = loader.PATH
	assert_true(path.begins_with("/") and path.ends_with(".pck"), "an absolute path the page writes to: %s" % path)
	assert_false(path.begins_with("res://") or path.begins_with("user://"))


func test_off_the_web_it_loads_nothing() -> void:
	var loader := _loader()
	assert_not_null(loader)
	if loader == null:
		return
	assert_false(loader.load_pack("res://project.godot", false), "a phone or a computer has everything already")
	assert_false(loader.load_pack(loader.PATH, false))


func test_a_page_that_brought_no_pack_loads_nothing() -> void:
	var loader := _loader()
	assert_not_null(loader)
	if loader == null:
		return
	assert_false(loader.load_pack("/no_such_folder_%d/assets.pck" % OS.get_process_id(), true))


func test_the_page_puts_the_pack_where_the_game_reads_it() -> void:
	var loader := _loader()
	assert_not_null(loader)
	if loader == null:
		return
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	assert_string_contains(shell, "engine.preloadFile(assets, '%s')" % loader.PATH, "the same place")
	assert_string_contains(shell, "const EC_ASSETS = '@EC_ASSETS@';", "the export names the packs there")
	assert_string_contains(FileAccess.get_file_as_string("res://tools/export_web.sh"), "'@EC_ASSETS@'")


# --- the export (export_presets.cfg, tools/export_web.sh) ------------------------------------------------------------

func test_the_patterns_catch_the_media_and_nothing_else() -> void:
	var files := _project_files()
	var caught := files.filter(func(f: String) -> bool: return _caught(f))
	assert_gt(caught.size(), 300, "the sounds, the loops and the characters")
	for f: String in caught:
		assert_has(MEDIA_EXTENSIONS, f.get_extension().to_lower(), "only media: %s" % f)
		assert_true(FileAccess.file_exists(f + ".import"), "an imported file: %s" % f)
	for f: String in files:
		if MEDIA_DIRS.any(func(d: String) -> bool: return f.begins_with(d)) and FileAccess.file_exists(f + ".import"):
			assert_true(_caught(f), "every resource of %s moves (a new kind needs a pattern): %s" % [MEDIA_DIRS, f])
	for stream: AudioStream in Music.STREAMS.values():
		assert_true(_caught(stream.resource_path), "Music's core loop: %s" % stream.resource_path)


func test_the_patterns_leave_the_other_packs_files_alone() -> void:
	var presets := _presets()
	for f: String in Array(presets["Web Music"].export_files):
		assert_false(_caught(f), "the music pack's: %s" % f)
	for f: String in RealisticPack.files():
		assert_false(_caught(f), "the realistic pack's: %s" % f)
	for f: String in _project_files("res://assets/brand/"):
		assert_false(_caught(f), "the brand pictures stay (the boot splash): %s" % f)


func test_nothing_the_engine_opens_before_the_autoloads_moves() -> void:
	# The project's own files the engine reads before the first autoload's _init: every path in the project settings
	# (the icon, the boot splash, the main scene, the autoload scripts, a theme, a font, a bus layout …) and the
	# GDExtensions. (project.binary and the .godot caches the exporter writes are never a source file.)
	var early: Array[String] = []
	for p: Dictionary in ProjectSettings.get_property_list():
		var value: Variant = ProjectSettings.get_setting(p["name"], null)
		if value is String or value is StringName:
			var s := str(value).trim_prefix("*")
			if s.begins_with("uid://"):
				s = ResourceUID.get_id_path(ResourceUID.text_to_id(s))
			if s.begins_with("res://"):
				early.append(s)
	for f: String in _project_files():
		if f.get_extension() == "gdextension":
			early.append(f)
	for must: String in [str(ProjectSettings.get_setting("application/config/icon")),
			str(ProjectSettings.get_setting("application/boot_splash/image")), LOADER]:
		assert_has(early, must)
	for f: String in early:
		assert_false(_caught(f), "stays in the main pack: %s" % f)


func test_nothing_names_a_moved_file_by_its_uid() -> void:
	# The main pack's uid cache only knows its own files: a scene or script that named a moved file by uid would
	# fall back to the path with a warning (and a `load("uid://…")` would fail).
	var uids := {}
	for f: String in _project_files():
		if _caught(f):
			var cfg := ConfigFile.new()
			if cfg.load(f + ".import") == OK and cfg.has_section_key("remap", "uid"):
				uids[str(cfg.get_value("remap", "uid"))] = f
	assert_gt(uids.size(), 300)
	var re := RegEx.create_from_string("uid://[a-z0-9]+")
	for f: String in _project_files():
		if not f.get_extension() in ["gd", "tscn", "tres", "cfg", "godot"] or f.begins_with("res://tests/"):
			continue
		for m in re.search_all(FileAccess.get_file_as_string(f)):
			assert_false(uids.has(m.get_string()), "%s names %s by uid" % [f, uids.get(m.get_string(), "")])


func test_the_browser_game_leaves_the_media_out() -> void:
	var presets := _presets()
	for game: String in WEB_GAME:
		assert_true(presets.has(game), game)
		var excluded := _patterns(presets[game].exclude_filter)
		for p: String in PATTERNS:
			assert_has(excluded, p, "%s leaves %s out" % [game, p])


func test_each_assets_pack_takes_exactly_the_media_in_its_games_format() -> void:
	var presets := _presets()
	for game: String in WEB_GAME:
		var pack_name: String = WEB_GAME[game]
		assert_true(presets.has(pack_name), pack_name)
		if not presets.has(pack_name):
			continue
		var pack: Dictionary = presets[pack_name]
		assert_eq(pack.platform, "Web")
		assert_eq(pack.export_filter, "resources", "chosen files only, not the whole game")
		assert_eq(Array(pack.export_files), [], "the patterns choose: a new sound comes along")
		assert_eq(_patterns(pack.include_filter), PATTERNS)
		assert_eq(pack.exclude_filter, "")
		for key: String in ["vram_texture_compression/for_desktop", "vram_texture_compression/for_mobile"]:
			assert_eq(pack.options.get(key), presets[game].options.get(key), "%s: %s as %s" % [pack_name, key, game])


func test_the_browsers_code_is_left_for_brotli_to_pack() -> void:
	# What an update downloads is now mostly compiled scripts. Compressed one by one (mode 2, zstd) the web's index.pck
	# was 5.1 MB and brotli could take little off (4.7 MB); as plain binary tokens (mode 1) it is 15.9 MB raw but
	# brotli -q 11 packs it to 2.6 MB over the whole pack (GitHub Pages' gzip: 4.8 MB either way). Phones keep mode 2.
	var presets := _presets()
	for game: String in WEB_GAME:
		assert_eq(_script_mode(game), 1, "%s: binary tokens, not compressed" % game)
	for preset_name: String in presets:
		if presets[preset_name].platform == "Android":
			assert_eq(_script_mode(preset_name), 2, "%s: unchanged" % preset_name)


func _script_mode(preset_name: String) -> int:
	var cfg := ConfigFile.new()
	cfg.load("res://export_presets.cfg")
	for section in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options") \
				and str(cfg.get_value(section, "name")) == preset_name:
			return int(cfg.get_value(section, "script_export_mode", -1))
	return -1


func test_phones_and_computers_keep_the_media() -> void:
	var presets := _presets()
	var media := _project_files().filter(func(f: String) -> bool: return _caught(f))
	var checked := 0
	for preset_name: String in presets:
		if presets[preset_name].platform != "Android":
			continue
		checked += 1
		var excluded := _patterns(presets[preset_name].exclude_filter)
		for f: String in media:
			assert_false(_caught(f, excluded), "%s keeps %s" % [preset_name, f])
	assert_gt(checked, 3)
