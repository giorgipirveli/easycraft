extends GutTest
## Owner feedback #52 (2026-09-25 17:57): "please dont build game in georgian, i didnt ask it. remove it from game and
## never include". The game is English only: no translation, no language choice, no Georgian command names or bot
## words. The one exception is not a translation: owner #49's chat shows whatever letters a player types, so the
## chat's font fallback names the phone's own Georgian font file and a sample of its letters (UiKit.SCRIPT_FONTS).

## Folders of the game itself (the tests may type any letters).
const GAME_DIRS: Array[String] = ["res://core", "res://ui", "res://scenes", "res://world", "res://entities",
	"res://autoloads", "res://net", "res://data", "res://tools", "res://i18n"]
const TEXT_ENDS: Array[String] = [".gd", ".json", ".tscn", ".tres", ".cfg", ".txt", ".po", ".py"]
## Owner #49: typed chat letters are drawn with the phone's font (not a translation).
const ALLOWED: Array[String] = ["res://ui/theme/ui_kit.gd"]


func test_no_translation_is_registered() -> void:
	var list: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations",
		PackedStringArray())
	assert_eq(list.size(), 0, "no translations: %s" % list)


func test_no_translation_files() -> void:
	assert_false(FileAccess.file_exists("res://i18n/ka.po"))
	assert_false(DirAccess.dir_exists_absolute("res://i18n"), "no i18n folder")


func test_the_first_launch_asks_no_language() -> void:
	PlatformRules.simulated = {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}   # a phone (owner #84: a PC skips it)
	assert_eq(WelcomeCards.due({}), [WelcomeCards.CONTROLS] as Array[StringName], "only the Simple controls card")
	PlatformRules.simulated = {}


func test_the_game_speaks_english() -> void:
	Lang.apply()
	assert_eq(Lang.current(), "en")


func test_no_georgian_letters_in_the_game() -> void:
	var georgian := RegEx.create_from_string("[\\x{10A0}-\\x{10FF}\\x{1C90}-\\x{1CBF}\\x{2D00}-\\x{2D2F}]")
	var found: Array[String] = []
	for dir in GAME_DIRS:
		_scan(dir, georgian, found)
	assert_eq(found, [] as Array[String], "Georgian in: %s" % ", ".join(found))


func _scan(dir: String, georgian: RegEx, found: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		if not sub.begins_with("."):
			_scan(dir.path_join(sub), georgian, found)
	for f in d.get_files():
		if not TEXT_ENDS.any(func(e: String) -> bool: return f.ends_with(e)):
			continue
		var path := dir.path_join(f)
		if ALLOWED.has(path):
			continue
		if georgian.search(FileAccess.get_file_as_string(path)) != null:
			found.append(path)
