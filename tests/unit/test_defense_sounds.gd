extends GutTest
## Defense sounds (M2 Task 8): a door opening and closing and spikes popping up, original procedural
## work from tools/make_defense_sfx.py, credited.

const DEFENSE_SOUNDS: Array[StringName] = [&"door_open", &"door_close", &"spikes"]


func test_defense_sounds_are_registered_and_load() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for key in DEFENSE_SOUNDS:
		assert_true(sounds.has(key), str(key))
		for path: String in sounds.get(key, []):
			var stream := load(path) as AudioStreamWAV
			assert_not_null(stream, path)
			if stream:
				assert_between(stream.get_length(), 0.05, 0.6, "%s is short" % path)


func test_the_generator_and_the_credits_are_in_the_project() -> void:
	assert_true(FileAccess.file_exists("res://tools/make_defense_sfx.py"))
	assert_string_contains(FileAccess.get_file_as_string("res://assets/CREDITS.md"), "make_defense_sfx.py")
