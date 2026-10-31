extends GutTest
## The Google Play build (owner feedback #46): its own preset, "Android Play", makes a signed Android App
## Bundle (.aab, Godot's Gradle build) with the store's package name. The package can never change after the
## first upload, so a test holds it. The upload key's path and password come from the environment
## (GODOT_ANDROID_KEYSTORE_RELEASE_*: docs/store/play-console.md) and never sit in export_presets.cfg.

const PRESET := "Android Play"
const PACKAGE := "com.giorgi.easycraft"


func _play() -> Dictionary:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	for section: String in presets.get_sections():
		if not section.ends_with(".options") and presets.get_value(section, "name", "") == PRESET:
			var out := {"platform": presets.get_value(section, "platform", "")}
			var opts := section + ".options"
			for key: String in presets.get_section_keys(opts):
				out[key] = presets.get_value(opts, key)
			return out
	return {}


func test_the_play_preset_builds_a_bundle_with_the_store_package() -> void:
	var p := _play()
	assert_false(p.is_empty(), "a preset named Android Play")
	assert_eq(p.get("platform"), "Android")
	assert_eq(p.get("package/unique_name"), PACKAGE, "never changes after the first upload")
	assert_true(p.get("gradle_build/use_gradle_build", false), "a bundle needs the Gradle build")
	assert_eq(int(p.get("gradle_build/export_format", 0)), 1, "1 = Android App Bundle (.aab)")
	assert_true(p.get("architectures/arm64-v8a", false), "Google Play's 64-bit phones")
	assert_eq(p.get("package/name"), "EasyCraft")


func test_no_signing_secret_is_in_the_presets_file() -> void:
	var p := _play()
	for key in ["keystore/release", "keystore/release_user", "keystore/release_password"]:
		assert_eq(str(p.get(key, "")), "", key + " comes from the environment")
	assert_false(FileAccess.get_file_as_string("res://export_presets.cfg").contains("easycraft-upload"),
		"not even the upload key's name")
