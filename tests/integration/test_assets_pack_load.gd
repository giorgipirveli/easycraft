extends GutTest
## M7: the browser's assets pack on real files (tests/unit/test_assets_pack.gd has the rules). The first autoload
## (autoloads/assets_pack.gd) loads a real pack (made here with PCKPacker) into res:// and never lets it replace a file
## the game has; tools/pck_tool.py cuts an exported content pack down to its own files (the exporter adds the autoload
## scripts, project.binary, the caches, the icon and the splash to every pack: a code change would rename the pack and
## every returning visitor would download it again), and what it writes is still a pack the engine loads.
## Every file made here is under a folder named after this process: loaded packs stay in res:// for the whole run.

const LOADER := "res://autoloads/assets_pack.gd"
var DIR := "user://test_assets_pack_%d/" % OS.get_process_id()
var INSIDE := "res://assets_pack_test_%d/" % OS.get_process_id()


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR + f)
	DirAccess.remove_absolute(DIR)


func _pack(pck: String, files: Dictionary) -> void:
	var packer := PCKPacker.new()
	assert_eq(packer.pck_start(pck), OK)
	for target: String in files:
		var data: Variant = files[target]
		assert_eq(packer.add_file_from_buffer(target, data if data is PackedByteArray else str(data).to_utf8_buffer()), OK)
	assert_eq(packer.flush(), OK)


func test_in_a_browser_the_packs_files_join_the_game() -> void:
	var loader: GDScript = load(LOADER)
	var pck := DIR + "assets.pck"
	_pack(pck, {INSIDE + "beep.txt": "a sound"})
	assert_false(FileAccess.file_exists(INSIDE + "beep.txt"), "not in the game before")
	assert_true(loader.load_pack(ProjectSettings.globalize_path(pck), true))
	assert_true(FileAccess.file_exists(INSIDE + "beep.txt"), "in res:// once the pack is loaded")
	assert_eq(FileAccess.get_file_as_string(INSIDE + "beep.txt"), "a sound")


func test_the_games_own_files_win() -> void:
	var loader: GDScript = load(LOADER)
	_pack(DIR + "first.pck", {INSIDE + "same.txt": "the game's"})
	assert_true(ProjectSettings.load_resource_pack(DIR + "first.pck", false))
	_pack(DIR + "second.pck", {INSIDE + "same.txt": "an older pack's"})
	assert_true(loader.load_pack(ProjectSettings.globalize_path(DIR + "second.pck"), true))
	assert_eq(FileAccess.get_file_as_string(INSIDE + "same.txt"), "the game's", "a file already there stays")


func _strip(source: String, out: String, keep: String) -> int:
	var output: Array = []
	var code := OS.execute("python3", [ProjectSettings.globalize_path("res://tools/pck_tool.py"), "strip",
		ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(out), "--keep", keep], output, true)
	gut.p("pck_tool: %s" % "".join(output).strip_edges())
	return code


func test_a_stripped_pack_keeps_only_its_own_files_and_still_loads() -> void:
	var tag := "strip_%d" % OS.get_process_id()
	var imported := "res://.godot/imported/%s-beep.wav-0123.sample" % tag
	var other := "res://.godot/imported/%s-elsewhere.png-4567.ctex" % tag
	_pack(DIR + "exported.pck", {
		"res://%s/sfx/beep.wav.import" % tag: "[remap]\n\nimporter=\"wav\"\ntype=\"AudioStreamWAV\"\nuid=\"uid://b%s\"\npath=\"%s\"\n" % [tag, imported],
		imported: "the sample's bytes",
		"res://%s/sfx/notes.txt" % tag: "a plain file the filter names",
		"res://%s/code/autoload.gdc" % tag: "a script the exporter adds",
		"res://%s/code/autoload.gd.remap" % tag: "[remap]\n\npath=\"res://%s/code/autoload.gdc\"\n" % tag,
		"res://%s/brand/splash.png" % tag: "the boot splash, raw",
		other: "an imported file no kept .import names",
	})
	var out := DIR + "stripped.pck"
	assert_eq(_strip(DIR + "exported.pck", out, "%s/sfx/*.wav, %s/sfx/*.txt" % [tag, tag]), 0)
	assert_true(FileAccess.file_exists(out))
	assert_true(ProjectSettings.load_resource_pack(out, false), "the engine reads what the tool wrote")
	assert_eq(FileAccess.get_file_as_string("res://%s/sfx/beep.wav.import" % tag).get_slice("\n", 0), "[remap]")
	assert_eq(FileAccess.get_file_as_string(imported), "the sample's bytes", "the imported data its .import names")
	assert_eq(FileAccess.get_file_as_string("res://%s/sfx/notes.txt" % tag), "a plain file the filter names")
	for gone: String in ["res://%s/code/autoload.gdc" % tag, "res://%s/code/autoload.gd.remap" % tag,
			"res://%s/brand/splash.png" % tag, other]:
		assert_false(FileAccess.file_exists(gone), "left out: %s" % gone)


func test_the_same_pack_strips_to_the_same_bytes() -> void:
	var tag := "same_%d" % OS.get_process_id()
	_pack(DIR + "a.pck", {"res://%s/x.ogg.import" % tag: "[remap]\n\npath=\"res://.godot/imported/%s-x.oggvorbisstr\"\n" % tag,
		"res://.godot/imported/%s-x.oggvorbisstr" % tag: "ogg", "res://project.binary": "settings"})
	assert_eq(_strip(DIR + "a.pck", DIR + "one.pck", "%s/*.ogg" % tag), 0)
	assert_eq(_strip(DIR + "a.pck", DIR + "two.pck", "%s/*.ogg" % tag), 0)
	assert_eq(FileAccess.get_sha256(DIR + "one.pck"), FileAccess.get_sha256(DIR + "two.pck"),
		"its name is its content's hash: the same media, the same name")


func test_a_pack_with_nothing_to_keep_is_refused() -> void:
	_pack(DIR + "code.pck", {"res://project.binary": "settings", "res://x/autoload.gdc": "code"})
	assert_ne(_strip(DIR + "code.pck", DIR + "empty.pck", "nothing/*.wav"), 0, "a wrong filter is an error, not an empty pack")
	assert_false(FileAccess.file_exists(DIR + "empty.pck"))
