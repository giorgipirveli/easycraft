extends GutTest
## Water sounds (M2 Task 14, owner feedback #17): splashes, swim strokes, bubbles and wet footsteps,
## original procedural work from tools/make_water_sfx.py; and every sound muffled under water.

const WATER_SOUNDS: Array[StringName] = [&"splash", &"splash_small", &"swim", &"bubbles", &"step_wet"]


func after_each() -> void:
	Audio.set_muffled(false)


func test_water_sounds_are_registered_and_load() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for key in WATER_SOUNDS:
		assert_true(sounds.has(key), str(key))
		for path: String in sounds.get(key, []):
			assert_not_null(load(path), path)


func test_the_generator_and_the_credits_are_in_the_project() -> void:
	assert_true(FileAccess.file_exists("res://tools/make_water_sfx.py"))
	var credits := FileAccess.get_file_as_string("res://assets/CREDITS.md")
	assert_string_contains(credits, "make_water_sfx.py")


func test_under_water_every_sound_is_muffled() -> void:
	assert_false(Audio.is_muffled())
	Audio.set_muffled(true)
	assert_true(Audio.is_muffled())
	var effect := AudioServer.get_bus_effect(0, Audio.muffle_index())
	assert_true(effect is AudioEffectLowPassFilter, "a low-pass on the Master bus")
	assert_lt((effect as AudioEffectLowPassFilter).cutoff_hz, 1500.0)
	Audio.set_muffled(false)
	assert_false(Audio.is_muffled())


func test_the_view_under_water_muffles_the_sound() -> void:
	assert_true(AmbienceRules.muffled(1.0))
	assert_true(AmbienceRules.muffled(0.6))
	assert_false(AmbienceRules.muffled(0.3))
	assert_false(AmbienceRules.muffled(0.0))
