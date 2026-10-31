extends GutTest
## Weapon sounds and controls (M1b Task 11).

const WEAPON_SOUNDS: Array[StringName] = [&"swing", &"bow", &"hit", &"thud", &"smash", &"whirr", &"ding"]


func test_weapon_sounds_are_registered_and_load() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for key in WEAPON_SOUNDS:
		assert_true(sounds.has(key), str(key))
		for path: String in sounds.get(key, []):
			assert_not_null(load(path), path)


func test_every_weapon_sound_exists() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for id in WeaponRules.WEAPONS:
		assert_true(sounds.has(WeaponRules.stats(id).sound), ItemIds.display_name(id))


func test_attack_is_on_r_in_the_project_and_the_input_tool() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://project.godot"), OK)
	var action: Variant = cfg.get_value("input", "attack", null)
	assert_not_null(action, "project.godot has the attack action")
	if action == null:
		return
	var keys: Array[int] = []
	for e: Variant in (action as Dictionary).events:
		if e is InputEventKey:
			keys.append((e as InputEventKey).physical_keycode)
	assert_eq(keys, [KEY_R])
	var tool_keys: Dictionary = load("res://tools/setup_input_map.gd").KEYS
	assert_eq(tool_keys.get("attack"), [KEY_R], "tools/setup_input_map.gd writes the same binding")
