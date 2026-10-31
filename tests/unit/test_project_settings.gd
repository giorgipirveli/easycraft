extends GutTest
## Project-wide settings that gameplay depends on.


## Owner feedback #9: Godot's default 3D physics spent up to 220 ms a frame on big bodies overlapping
## the voxel terrain; Jolt handled the same scene in 44 ms. Animals and projectiles rely on this too.
func test_project_uses_jolt_physics() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK)
	assert_eq(cfg.get_value("physics", "3d/physics_engine", "DEFAULT"), "Jolt Physics")


## Deferred from M1, needed for LAN play and chat between phones: Android must be allowed to use the
## network (Godot writes no permission at all unless it is turned on in the preset).
func test_android_game_presets_can_use_the_network() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK)
	for section: String in ["preset.0", "preset.2"]:
		var opts := section + ".options"
		assert_true(cfg.get_value(opts, "permissions/internet", false), "%s internet" % cfg.get_value(section, "name"))
		assert_true(cfg.get_value(opts, "permissions/access_network_state", false), "%s network state" % cfg.get_value(section, "name"))


## M2 Task 11: Input.vibrate_handheld needs Android's VIBRATE permission in the game presets (Feel).
func test_android_game_presets_may_vibrate() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK)
	for section: String in ["preset.0", "preset.2"]:
		assert_true(cfg.get_value(section + ".options", "permissions/vibrate", false), "%s vibrate" % cfg.get_value(section, "name"))


## M2 Task 11: the music and feel autoloads start after the ones they use (Profile, Game, Session).
func test_music_and_feel_autoloads_come_after_what_they_use() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK)
	var names := Array(cfg.get_section_keys("autoload"))
	for n: String in ["Music", "Feel"]:
		assert_has(names, n)
		for used: String in ["Profile", "Game", "Session"]:
			assert_gt(names.find(n), names.find(used), "%s after %s" % [n, used])
