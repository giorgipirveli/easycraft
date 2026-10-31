extends GutTest
## Owner feedback #43 (a distinct visual identity; spec §3c): no other block game's name, creature or place
## appears in what players, parents and store reviewers read. Scanned: the store drafts (docs/store/, the
## listing and its keywords), the release notes that go to the store (docs/playtests/whats-new-*.md), the
## public web pages (server/deploy/site/), the game's data files and every
## string literal in the game's code (comments are skipped; the word filters in core/validation/ are never shown). The words themselves live
## only here, so the docs can say "no other game's name" without naming it.

const TEXT_DIRS: Array[String] = ["res://docs/store", "res://server/deploy/site"]
const NOTES_DIR := "res://docs/playtests"
const CODE_DIRS: Array[String] = ["res://autoloads", "res://core", "res://entities", "res://scenes", "res://ui",
	"res://world"]
const DATA_DIR := "res://data"
const FILTER_DIRS: Array[String] = ["res://core/validation/"]

## Whole words, matched case-insensitively (English and the Georgian spellings children use).
const BANNED: Array[String] = ["minecraft", "mojang", "creeper", "creepers", "enderman", "endermen", "ender dragon",
	"ender pearl", "nether", "netherite", "herobrine", "redstone", "steve", "mooshroom", "piglin", "ghast", "elytra",
	"roblox", "robux", "bloxburg", "obby", "noob", "მაინკრაფტ", "მაინქრაფტ", "რობლოქს", "რობლოკს"]

var _literal := RegEx.create_from_string("\"(?:[^\"\\\\\\n]|\\\\.)*\"")
var _patterns: Array[RegEx] = []


func before_all() -> void:
	for word in BANNED:
		# \b does not know Georgian letters: a word edge is "not a letter". A Georgian word takes endings
		# (მაინკრაფტი, მაინკრაფტში), so only its start must be a word's start.
		var georgian := word.unicode_at(0) > 127
		_patterns.append(RegEx.create_from_string("(?<![\\p{L}\\p{N}])" + word + ("" if georgian else "(?![\\p{L}\\p{N}])")))


func _banned_in(text: String) -> String:
	var lower := text.to_lower()
	for i in BANNED.size():
		if _patterns[i].search(lower):
			return BANNED[i]
	return ""


func _files(dir: String, exts: Array[String], out: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		if exts.has(f.get_extension()):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_files(dir.path_join(d), exts, out)


## The string literals of one line of code, stopping at a comment outside any string.
func _strings(line: String) -> Array[String]:
	var out: Array[String] = []
	var pos := 0
	for m in _literal.search_all(line):
		var hash := line.find("#", pos)
		if hash != -1 and hash < m.get_start():
			break
		out.append(m.get_string().substr(1, m.get_string().length() - 2))
		pos = m.get_end()
	return out


func _scan_text(paths: Array[String]) -> Array[String]:
	var found: Array[String] = []
	for path in paths:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			var hit := _banned_in(lines[i])
			if hit != "":
				found.append("%s:%d (%s)" % [path, i + 1, hit])
	return found


func test_the_checker_finds_whole_words_in_both_languages() -> void:
	assert_eq(_banned_in("Just like MINECRAFT!"), "minecraft")
	assert_eq(_banned_in("a creeper sneaks"), "creeper")
	assert_eq(_banned_in("ვითამაშოთ მაინკრაფტი"), "მაინკრაფტ", "a Georgian ending is still the word")
	assert_eq(_banned_in("The candy sneaker"), "", "our own monster")
	assert_eq(_banned_in("Stevenson Street"), "", "whole words only")
	assert_eq(_banned_in("render the nethermost"), "", "whole words only")
	assert_eq(_strings("\tl.text = \"Build!\"   # \"minecraft\" in a comment"), ["Build!"] as Array[String])


func test_the_store_drafts_and_public_pages_never_name_another_game() -> void:
	var paths: Array[String] = []
	for d in TEXT_DIRS:
		_files(d, ["md", "html", "txt"] as Array[String], paths)
	for f in DirAccess.get_files_at(NOTES_DIR):
		if f.begins_with("whats-new-") and f.ends_with(".md"):
			paths.append(NOTES_DIR.path_join(f))
	assert_true(paths.has("res://docs/store/listing.md"), "the listing was found")
	assert_gt(paths.size(), 8)
	var found := _scan_text(paths)
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_no_game_text_or_data_names_another_game() -> void:
	var files: Array[String] = []
	for d in CODE_DIRS:
		_files(d, ["gd"] as Array[String], files)
	assert_gt(files.size(), 50, "the game's code was found")
	var found: Array[String] = []
	for path in files:
		if FILTER_DIRS.any(func(d: String) -> bool: return path.begins_with(d)):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for i in lines.size():
			if lines[i].strip_edges().begins_with("#"):
				continue
			for s in _strings(lines[i]):
				var hit := _banned_in(s)
				if hit != "":
					found.append("%s:%d \"%s\" (%s)" % [path, i + 1, s, hit])
	var data: Array[String] = []
	_files(DATA_DIR, ["json", "txt", "csv"] as Array[String], data)
	found.append_array(_scan_text(data))
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_the_app_and_every_android_build_are_called_easycraft() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), "EasyCraft")
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	for section in presets.get_sections():
		if not section.ends_with(".options") or not presets.has_section_key(section, "package/name"):
			continue
		var preset := section.trim_suffix(".options")
		if str(presets.get_value(preset, "custom_features", "")).contains("spike"):
			continue   # the M0 voxel spike: a developer build, never installed by players
		assert_eq(presets.get_value(section, "package/name"), "EasyCraft", section)


func test_the_listing_leads_with_our_own_magic_and_asks_for_a_trademark_search() -> void:
	var listing := FileAccess.get_file_as_string("res://docs/store/listing.md")
	assert_string_contains(listing, "## Art direction")
	var art := listing.substr(listing.find("## Art direction")).to_lower()
	for must in ["living buddies", "size magic", "universes", "never a plain grass"]:
		assert_string_contains(art, must)
	assert_string_contains(listing, "trademark search for \"EasyCraft\"")
