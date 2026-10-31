extends GutTest
## The settings panel (menu and pause menu). M2 Task 11 adds the music volume, Vibration and Reduce
## motion. The panel only reads the settings here: changing one saves the shared profile file
## (user://profile.json is the same for every worktree), which tests must not do.

const SCREEN := Vector2(1280, 720)

var _saved := {}


func before_each() -> void:
	for key: String in ["music_volume", "vibration", "reduce_motion", "sfx_volume", "music_style", "song_names"]:
		_saved[key] = Profile.data.settings[key]
	_saved["build_notes"] = Profile.data.settings.get("build_notes", true)   # M3 Task 21c


func after_each() -> void:
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]


func _panel() -> SettingsPanel:
	var box := PanelContainer.new()        # as the menus show it: themed, in a panel
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	box.add_child(s)
	add_child_autofree(box)
	return s


## Everything must be reachable on a 1280 × 720 landscape screen (it was 725 px tall before M2 Task 11).
func test_settings_fit_on_the_screen() -> void:
	var s := _panel()
	var size := (s.get_parent() as Control).get_combined_minimum_size()
	gut.p("settings panel %s on a %s screen" % [size, SCREEN])
	assert_lte(size.y, SCREEN.y, "height %d" % size.y)
	assert_lte(size.x, SCREEN.x, "width %d" % size.x)


func test_music_volume_slider_shows_the_setting() -> void:
	Profile.data.settings.music_volume = 0.35
	var slider := _panel().find_child("MusicSlider", true, false) as HSlider
	assert_not_null(slider)
	if slider:
		assert_eq(slider.value, 35.0)
		assert_eq(slider.min_value, 0.0)
		assert_eq(slider.max_value, 100.0)


func test_vibration_and_reduce_motion_toggles_show_the_settings() -> void:
	Profile.data.settings.vibration = false
	Profile.data.settings.reduce_motion = true
	var s := _panel()
	var vibration := s.find_child("VibrationToggle", true, false) as CheckButton
	var reduce := s.find_child("ReduceMotionToggle", true, false) as CheckButton
	assert_not_null(vibration)
	assert_not_null(reduce)
	if vibration and reduce:
		assert_false(vibration.button_pressed)
		assert_true(reduce.button_pressed)


## The audio pass (owner feedback #27, #31): a SOUND EFFECTS slider beside the music one, the MUSIC style
## (one button that steps GAME -> CLASSICAL -> MIX) and a Song names toggle, all on existing rows.
func test_sound_effects_slider_shows_the_setting() -> void:
	Profile.data.settings.sfx_volume = 0.45
	var slider := _panel().find_child("SfxSlider", true, false) as HSlider
	assert_not_null(slider)
	if slider:
		assert_eq(slider.value, 45.0)
		assert_eq(slider.max_value, 100.0)


func test_the_music_style_button_shows_the_setting() -> void:
	for style: String in ["game", "classical", "mix"]:
		Profile.data.settings.music_style = style
		var b := _panel().find_child("MusicStyleButton", true, false) as Button
		assert_not_null(b)
		if b:
			assert_eq(b.text, SettingsPanel.MUSIC_STYLE_WORDS[style])


func test_the_music_style_steps_through_the_three_styles() -> void:
	assert_eq(SettingsPanel.next_music_style("game"), "classical")
	assert_eq(SettingsPanel.next_music_style("classical"), "mix")
	assert_eq(SettingsPanel.next_music_style("mix"), "game")
	assert_eq(SettingsPanel.next_music_style("jazz"), "game")


func test_the_song_names_toggle_shows_the_setting() -> void:
	Profile.data.settings.song_names = false
	var t := _panel().find_child("SongNamesToggle", true, false) as CheckButton
	assert_not_null(t)
	if t:
		assert_false(t.button_pressed)


## M3 Task 21c: "Block music" (every placed block sings a note; off: the plain pop) on HELP beside Reduce motion (the
## pages fit the screen: test_settings_words_page).
func test_the_block_music_toggle_shows_the_setting() -> void:
	Profile.data.settings.build_notes = false
	var t := _panel().find_child("BlockMusicToggle", true, false) as CheckButton
	assert_not_null(t)
	if t:
		assert_false(t.button_pressed)
		assert_eq(t.text, "Block music")
		var reduce := t.get_parent().find_child("ReduceMotionToggle", false, false)
		assert_not_null(reduce, "beside Reduce motion")
	Profile.data.settings.build_notes = true
	var on := _panel().find_child("BlockMusicToggle", true, false) as CheckButton
	if on:
		assert_true(on.button_pressed)


## 2026-09-28 (the lead in the emulator's Chrome, a 20:9 phone): the main menu's SETTINGS ran off the bottom of the
## screen, BACK with it, so a child could not leave it (the 711 px panel is centred in the room under the name). Every
## button of the panel, BACK first, is on the screen at 16:9 and 20:9 (the game keeps 720 px of height; wider phones
## only add width).
func test_in_the_menu_every_settings_button_is_on_the_screen() -> void:
	var window := get_window().size
	for screen_px: Vector2i in [Vector2i(1280, 720), Vector2i(2400, 1080)]:
		get_window().size = screen_px
		var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
		add_child_autofree(menu)
		await wait_frames(3)
		menu.call("_show_settings")
		await wait_seconds(0.4)   # the panel pops in (a 0.18 s tween)
		var panel: SettingsPanel = null
		for n in menu.find_children("*", "", true, false):
			if n is SettingsPanel:
				panel = n
		assert_not_null(panel)
		if panel == null:
			continue
		var screen := get_viewport().get_visible_rect()
		for b in panel.find_children("*", "Button", true, false):
			if (b as Control).is_visible_in_tree():
				assert_true(screen.encloses((b as Control).get_global_rect()), "%s: %s on the screen %s" % [
					screen_px, (b as Button).text, (b as Control).get_global_rect()])
		menu.queue_free()
		await wait_frames(1)
	get_window().size = window


## The same in a world (PAUSE → SETTINGS), where the panel is centred on the whole screen.
func test_in_the_pause_menu_every_settings_button_is_on_the_screen() -> void:
	var window := get_window().size
	for screen_px: Vector2i in [Vector2i(1280, 720), Vector2i(2400, 1080)]:
		get_window().size = screen_px
		var pause := PauseMenu.new()
		add_child_autofree(pause)
		await wait_frames(2)
		pause.open()
		pause.call("_show_settings")
		await wait_frames(3)
		var screen := get_viewport().get_visible_rect()
		var buttons := pause.find_children("*", "Button", true, false).filter(
			func(b: Node) -> bool: return (b as Control).is_visible_in_tree())
		assert_gt(buttons.size(), 5, "the settings show")
		for b: Node in buttons:
			assert_true(screen.encloses((b as Control).get_global_rect()), "%s: %s on the screen %s" % [
				screen_px, (b as Button).text, (b as Control).get_global_rect()])
		pause.close()   # it paused the tree
		pause.queue_free()
		await wait_frames(1)
	get_tree().paused = false
	get_window().size = window
