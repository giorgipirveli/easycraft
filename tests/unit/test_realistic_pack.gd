extends GutTest
## M7 (owner 2026-09-28: "make sure it loads fast, load any unnessesary data later"): in a browser the REALISTIC style's
## pictures (every block page's realistic twin and the HDRI sky, about 30 MB of the 44 MB main pack) are left out of
## the first download and come in the "realistic" pack after the start (WebContent). RealisticPack knows which files
## those are and whether they are here; the phone and desktop builds have them from the start.
## RealisticPack.exists_check pretends files are missing.

## Every page the game registers, with its [pixel, realistic albedo, realistic normal] files.
const PAGE_FILES := [BlockLibrary.PAGE_0_FILES, DesertBlocks.FILES, FrostBlocks.FILES, CandyBlocks.FILES,
	DragonBlocks.FILES, PortalPage.FILES, SmartPage.FILES, PaintPage.FILES, MeadowsBlocks.FILES, TinyPage.FILES,
	MoonBlocks.FILES, BoingBlocks.FILES, RainbowBlocks.FILES, MarsBlocks.FILES, EuropaBlocks.FILES,
	LabPage.FILES,   # spec §23: the Science Lab's bench
	IoBlocks.FILES,   # cosmos: Io's page 21
	TitanBlocks.FILES,   # cosmos: Titan's page 29
	MercuryBlocks.FILES,   # cosmos: Mercury's page 30
	RocketPage.FILES,   # spec §21d: the rocket parts' page 32
	ProspectPage.FILES,   # spec §26: prospecting's riches, page 35
	ProspectSpacePage.FILES,   # spec §26.5: the riches of the Moon and Mars, page 39
	ColonyBlocks.FILES,   # spec §21c: the colonies' page 31
	WondersBlocks.FILES, WondersBlocks.FILES_MORE,   # owner #78: the wonders' pages 33-34
	WondersBlocks.FILES_NEW, WondersBlocks.FILES_NEW_MORE,   # owner #78: the New Seven Wonders' pages 36-37
	VenusBlocks.FILES,   # cosmos: Venus's cloud city's page 38
	RingsBlocks.FILES,   # cosmos: Saturn's rings' page 40
	PlutoBlocks.FILES,   # cosmos: Pluto's page 41
	TritonBlocks.FILES,   # cosmos: Triton's page 42
	GanymedeBlocks.FILES,   # cosmos: Ganymede's page 43
	MusicPage.FILES,   # owner #110: the music blocks' page 44
	GlowBlocks.FILES]   # universe 6: the Glow Caves' page 45


func before_all() -> void:
	WorldService.library()   # the pages a world registers (SmartPage) too


func after_each() -> void:
	RealisticPack.exists_check = Callable()


func test_the_pack_is_every_realistic_twin_and_the_sky() -> void:
	var files := RealisticPack.files()
	for page: Array in PAGE_FILES:
		assert_has(files, page[1], "the realistic albedo")
		assert_has(files, page[2], "the realistic normal map")
		assert_does_not_have(files, page[0], "never a pixel page: the blocky style needs it at once")
	assert_has(files, WorldService.REALISTIC_SKY)
	assert_eq(files.size(), PAGE_FILES.size() * 2 + 1, "nothing else: %s" % [files])


func test_a_phone_or_computer_build_has_every_realistic_picture() -> void:
	for f: String in RealisticPack.files():
		assert_true(ResourceLoader.exists(f), f)
	assert_true(RealisticPack.present())


func test_one_picture_missing_is_not_here_yet() -> void:
	RealisticPack.exists_check = func(path: String) -> bool: return path != WorldService.REALISTIC_SKY
	assert_false(RealisticPack.present(), "the sky is not here")
	RealisticPack.exists_check = func(path: String) -> bool: return path != TinyPage.FILES[2]
	assert_false(RealisticPack.present(), "a normal map is not here")
	RealisticPack.exists_check = func(_path: String) -> bool: return true
	assert_true(RealisticPack.present())


func test_the_pack_has_its_own_name() -> void:
	assert_eq(RealisticPack.PACK, "realistic", "packs.json's name (tools/export_web.sh)")
	assert_ne(RealisticPack.PACK, Music.PACK)


# --- the export (export_presets.cfg, tools/export_web.sh) ------------------------------------------------------------

## The patterns that move the realistic pictures out of the browser's main packs and into the realistic packs. They catch
## pages added later too (data/blocks/pages/<name>_albedo.png, _normal.png; another HDRI sky) and nothing else.
const PATTERNS := ["data/blocks/*_albedo.png", "data/blocks/*_normal.png", "assets/sky/*.hdr"]
## The browser's game presets (one per texture format) and the realistic pack of the same format.
const WEB_GAME := {"Web": "Web Realistic", "Web Mobile": "Web Realistic Mobile"}


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
func _caught(path: String, patterns: Array) -> bool:
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


func test_the_patterns_catch_every_realistic_picture_and_nothing_else() -> void:
	var files := RealisticPack.files()
	for f: String in files:
		assert_true(_caught(f, PATTERNS), "caught: %s" % f)
	var caught := _project_files().filter(func(f: String) -> bool: return _caught(f, PATTERNS))
	assert_gt(caught.size(), 0)
	for f: String in caught:
		assert_has(files, f, "only the realistic style's pictures move (never a pixel page): %s" % f)


func test_the_browser_game_leaves_the_realistic_pictures_out() -> void:
	var presets := _presets()
	for game: String in WEB_GAME:
		assert_true(presets.has(game), game)
		var excluded := _patterns(presets[game].exclude_filter)
		for p: String in PATTERNS:
			assert_has(excluded, p, "%s leaves %s out" % [game, p])


func test_each_realistic_pack_takes_exactly_the_realistic_pictures_in_its_games_format() -> void:
	var presets := _presets()
	for game: String in WEB_GAME:
		var pack_name: String = WEB_GAME[game]
		assert_true(presets.has(pack_name), pack_name)
		if not presets.has(pack_name):
			continue
		var pack: Dictionary = presets[pack_name]
		assert_eq(pack.platform, "Web")
		assert_eq(pack.export_filter, "resources", "chosen files only, not the whole game")
		assert_eq(Array(pack.export_files), [], "the patterns choose: a page added later comes along")
		assert_eq(_patterns(pack.include_filter), PATTERNS)
		assert_eq(pack.exclude_filter, "")
		for key: String in ["vram_texture_compression/for_desktop", "vram_texture_compression/for_mobile"]:
			assert_eq(pack.options.get(key), presets[game].options.get(key), "%s: %s as %s" % [pack_name, key, game])


func test_phones_and_computers_keep_every_realistic_picture() -> void:
	var presets := _presets()
	var checked := 0
	for preset_name: String in presets:
		if presets[preset_name].platform != "Android":
			continue
		checked += 1
		for f: String in RealisticPack.files():
			assert_false(_caught(f, _patterns(presets[preset_name].exclude_filter)), "%s keeps %s" % [preset_name, f])
	assert_gt(checked, 3)
