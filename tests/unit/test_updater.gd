extends GutTest
## Owner #123: the Android apps take the newest game from our server (docs/devlog/parts/same-version.md). The updater
## (autoloads/updater.gd) is the FIRST autoload: the engine loads and makes the autoloads one by one, so its _init loads
## a verified patch pack before any later autoload's script is loaded (the spike: they then come from the pack). For that
## the updater and its own scripts (UpdateRules, UpdateFlow, UpdateFetch) name nothing else of the game: whatever they
## loaded would be the app's own copy for the whole run. Off Android it is idle (the editor, the tests, the web, a PC),
## unless a developer names a folder (--update-dir) to try a base pack on this PC.

const UPDATER := "res://autoloads/updater.gd"
const OWN_SET := ["res://autoloads/updater.gd", "res://core/platform/update_rules.gd",
	"res://core/platform/update_flow.gd", "res://core/platform/update_fetch.gd"]
const OWN_CLASSES := ["UpdateRules", "UpdateFlow", "UpdateFetch"]
## The only other files the set reads: the app's own build's identity and settings, before any pack is in.
const READS := ["res://data/build_info.json", "res://project.binary"]


func _code(path: String) -> String:
	return "\n".join(Array(FileAccess.get_file_as_string(path).split("\n")).filter(
		func(line: String) -> bool: return not line.strip_edges().begins_with("#")))


func test_the_updater_is_the_first_autoload() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK)
	var names := cfg.get_section_keys("autoload")
	assert_eq(names[0], "Updater", "before every autoload whose script a pack may change: %s" % [names])
	assert_eq(str(cfg.get_value("autoload", "Updater")), "*" + UPDATER)
	assert_eq(names[1], "AssetsPack", "the browser's media pack right after (the updater is idle there)")


func test_the_updater_and_its_scripts_load_nothing_else_of_the_game() -> void:
	for path: String in OWN_SET:
		assert_true(ResourceLoader.exists(path), path)
		for dep: String in ResourceLoader.get_dependencies(path):
			assert_has(OWN_SET, dep.get_slice("::", 2) if dep.contains("::") else dep, "%s depends on %s" % [path, dep])
		var code := _code(path)
		var paths := RegEx.create_from_string("res://[A-Za-z0-9_./-]+").search_all(code).map(
			func(m: RegExMatch) -> String: return m.get_string())
		for p: String in paths:
			assert_true(OWN_SET.has(p) or READS.has(p), "%s names %s" % [path, p])
		assert_false(code.contains("uid://"), "%s: no uid of the game" % path)
		var used: Array = []
		for c: Dictionary in ProjectSettings.get_global_class_list():
			if OWN_CLASSES.has(c["class"]):
				continue
			if RegEx.create_from_string("\\b%s\\b" % c["class"]).search(code):
				used.append(c["class"])
		assert_eq(used, [], "%s uses no class of the game" % path)
	assert_false(_code(UPDATER).contains("class_name"), "the autoload has no global name of its own")


func test_it_is_idle_off_android_unless_a_developer_names_a_folder() -> void:
	var u: GDScript = load(UPDATER)
	assert_false(u.setup_from(PackedStringArray(), false, false).enabled, "the editor, the tests, the web, a PC")
	var dev: Dictionary = u.setup_from(PackedStringArray(["--update-dir=/tmp/x", "--update-source=/tmp/y"]), false, false)
	assert_true(dev.enabled)
	assert_eq([dev.kind, dev.dir, dev.source], ["phone", "/tmp/x", "/tmp/y"])
	var dev_quest: Dictionary = u.setup_from(PackedStringArray(["--update-dir=/tmp/x", "--update-kind=quest"]), false, false)
	assert_eq([dev_quest.kind, dev_quest.source], ["quest", ""])
	var phone: Dictionary = u.setup_from(PackedStringArray(), true, false)
	assert_eq([phone.enabled, phone.kind, phone.dir, phone.source], [true, "phone", "user://update", ""])
	var quest: Dictionary = u.setup_from(PackedStringArray(["--update-source=/tmp/y"]), true, true)
	assert_eq([quest.kind, quest.source], ["quest", ""], "on Android the server is always ours")


func test_in_this_run_it_is_idle() -> void:
	var updater: Node = get_tree().root.get_node_or_null("Updater")
	assert_not_null(updater)
	if updater == null:
		return
	assert_false(updater.enabled)
	assert_false(updater.has_ready())
	assert_eq(updater.running, {}, "the app's own build")
	updater.menu_shown()
	assert_false(updater.enabled, "the menu changes nothing for an idle updater")
