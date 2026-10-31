extends GutTest
## The version shows on the main menu and in the store; the owner's phone takes an APK only if its
## version code is higher. project.godot and every export preset must agree (M2 Task 12: 0.3.0, code 5;
## raise both with every APK the owner receives: docs/DEVELOPMENT.md).

const VERSION := "1.0.9"   # 2026-10-18: a patch over the 1.0.7 base: every practice room dressed, Inside a Leaf playable (the first deep game), the Academy's look, Balance Altar's rules
const CODE := 19


func test_the_game_and_every_preset_carry_this_releases_version() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/version"), VERSION)
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var seen := 0
	for section: String in presets.get_sections():
		if section.ends_with(".options") and presets.has_section_key(section, "version/name"):
			seen += 1
			assert_eq(presets.get_value(section, "version/name"), VERSION, section)
			assert_eq(int(presets.get_value(section, "version/code")), CODE, section)
	assert_gt(seen, 0, "the Android presets")
