extends GutTest
## M5 Task 3 (spec §15.3: start under 5 s on the emulator): what the game loads at start. Audio loaded every take of
## every sound (about 330 files) in its _ready: 55-75 ms of the desktop's start, and more on a phone reading them out
## of the APK. A sound's takes now load the first time it plays (the loader keeps them).

const SOUND := &"coin"


func after_all() -> void:
	Audio.stop_all()


func test_a_sounds_takes_load_the_first_time_it_plays() -> void:
	Audio._streams.erase(SOUND)
	assert_false(Audio._streams.has(SOUND), "not loaded before it plays")
	Audio.play(SOUND)
	assert_true(Audio._streams.has(SOUND), "loaded when it plays")
	assert_eq((Audio._streams[SOUND] as Array).size(), (Audio.SOUNDS[SOUND] as Array).size(), "every take")
	assert_eq(Audio.last_sound, SOUND, "and it played")


func test_an_unknown_sound_plays_nothing() -> void:
	var before: int = Audio.played
	Audio.play(&"no_such_sound")
	assert_eq(Audio.played, before)


func test_the_menu_says_when_it_is_ready() -> void:
	assert_true(FileAccess.get_file_as_string("res://ui/menus/menu.gd").contains("MENU ready_ms="),
		"a MENU ready_ms line for logcat (the lead's startup measurement on the emulator)")
