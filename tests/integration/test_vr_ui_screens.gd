extends GutTest
## Owner #101 (VR on the Meta Quest), the panel side, screen by screen: the loading card goes to the eye panel with the
## loading room round the child; the autoloads' toasts (Music's "Now playing", Session's invites) are in the VR canvas
## while VR runs; SETTINGS has a VR COMFORT page only in a headset (turning, the comfort view, text size, RECENTER);
## TEXT SIZE is BIG by default in a headset; the vr_* settings are in the profile, checked when read, and stay on their
## device (a phone's backup never resets the headset's comfort); the HUD's "+" never shows in VR (the laser aims); the
## TV (YouTube in a WebView or the page's player) shows its sign in VR and the Shorts play; the world's colour tint (a
## flat screen's underwater blue) is not drawn on the panel.

var _old_pad: PadFocus
var _saved := {}


class Owner:
	extends Node


class FakeSpawner:
	extends Node
	signal spawned


func before_each() -> void:
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	for key: String in ["text_size", TextSize.VR_KEY, VrRules.TURN, VrRules.VIGNETTE]:
		_saved[key] = Profile.data.settings.get(key)


func after_each() -> void:
	Vr.simulate(false)
	PadFocus.instance = _old_pad
	for key: String in _saved:
		if _saved[key] == null:
			Profile.data.settings.erase(key)
		else:
			Profile.data.settings[key] = _saved[key]


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func test_a_loading_world_shows_its_card_on_the_eye_panel_in_the_loading_room() -> void:
	Vr.simulate(true)
	var world := Owner.new()
	add_child_autofree(world)
	var spawner := FakeSpawner.new()
	add_child_autofree(spawner)
	var layer := LoadingCard.cover(world, spawner, ModeRules.SANDBOX, 1)
	assert_eq(layer.get_parent(), Vr.ui_viewport(), "the card is on the panel")
	await _frames(2)
	var ui := VrUi.instance
	assert_eq(ui.panel.place, VrPanelRules.EYE, "in front of the child while the world loads")
	assert_true(ui.room.visible, "never a black void: the loading room")
	spawner.spawned.emit()   # the child stands in the world: the card fades
	await get_tree().create_timer(LoadingCard.FADE_TIME + 0.2).timeout
	await _frames(2)
	assert_false(ui.room.visible, "the room goes with the card")
	assert_eq(ui.panel.place, VrPanelRules.HIDDEN, "playing: the HUD waits for the raised forearm (owner #127)")


func test_the_autoloads_toasts_are_on_the_panel_while_vr_runs() -> void:
	var invite := Session.invite_toast()
	var music_layer := Music.get("_toast_layer") as CanvasLayer
	Vr.simulate(true)
	assert_eq(invite.get_viewport(), Vr.ui_viewport(), "an invite pops up on the panel")
	assert_eq(music_layer.get_parent(), Vr.ui_viewport(), "\"Now playing\" too")
	assert_eq(music_layer.process_mode, Node.PROCESS_MODE_ALWAYS, "still running while paused, as under Music")
	Vr.simulate(false)
	assert_eq(music_layer.get_parent(), Music)
	assert_eq(invite.get_viewport(), get_tree().root)


func _settings() -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass   # never the shared profile file
	box.add_child(s)
	add_child_autofree(box)
	return s


func test_vr_comfort_is_a_settings_page_only_in_a_headset() -> void:
	var flat := _settings()
	await _frames(1)
	assert_null(flat.find_child("Page_vr", true, false), "no VR page on a phone or a PC")
	Vr.simulate(true)
	var s := _settings()
	await _frames(1)
	var page := s.find_child("Page_vr", true, false) as Button
	assert_not_null(page)
	if page == null:
		return
	page.pressed.emit()
	var smooth := s.find_child("VrTurn_smooth", true, false) as Button
	assert_true(smooth.is_visible_in_tree())
	assert_true((s.find_child("VrTurn_snap45", true, false) as Button).button_pressed, "snap 45 first (ruling 3)")
	smooth.pressed.emit()
	assert_eq(Profile.data.settings[VrRules.TURN], "smooth")
	(s.find_child("VrVignette_strong", true, false) as Button).pressed.emit()
	assert_eq(Profile.data.settings[VrRules.VIGNETTE], "strong")
	(s.find_child("VrText_normal", true, false) as Button).pressed.emit()
	assert_eq(Profile.data.settings[TextSize.VR_KEY], "normal")
	var comfort := s.find_child("VrComfortPage", true, false) as VrComfortPage
	var recentred := [0]
	comfort.recenter = func() -> void: recentred[0] += 1
	(s.find_child("VrRecenter", true, false) as Button).pressed.emit()
	assert_eq(recentred[0], 1, "RECENTER puts the world in front again")
	var height := (s.get_parent() as Control).get_combined_minimum_size().y
	assert_lte(height, 720.0, "the page fits the canvas")
	(s.find_child("Page_game", true, false) as Button).pressed.emit()
	assert_false(smooth.is_visible_in_tree(), "one page at a time")


func test_text_is_big_by_default_in_a_headset() -> void:
	Profile.data.settings.text_size = "normal"
	Profile.data.settings.erase(TextSize.VR_KEY)
	assert_eq(TextSize.factor(), 1.0, "a phone: the child's own choice")
	Vr.simulate(true)
	assert_eq(TextSize.factor(), 1.25, "a headset: BIG unless the child chose NORMAL there")
	Profile.data.settings[TextSize.VR_KEY] = "normal"
	assert_eq(TextSize.factor(), 1.0)


func test_the_vr_settings_are_in_the_profile_and_checked() -> void:
	var p := ProfileData.new()
	for key: String in VrRules.DEFAULTS:
		assert_eq(p.settings.get(key), VrRules.DEFAULTS[key], "%s starts at the plan's default" % key)
	assert_eq(p.settings.get(TextSize.VR_KEY), "big")
	var back := ProfileData.from_json(JSON.stringify({"settings": {VrRules.TURN: "spin", VrRules.VIGNETTE: "off",
		TextSize.VR_KEY: "huge"}}))
	assert_eq(back.settings[VrRules.TURN], "snap45", "an unknown turn reads the default")
	assert_eq(back.settings[VrRules.VIGNETTE], "off", "a known choice is kept")
	assert_eq(back.settings[TextSize.VR_KEY], "big")


func test_a_phones_backup_never_resets_the_headsets_comfort() -> void:
	for key: String in VrRules.DEFAULTS:
		assert_has(ProfileBackup.DEVICE_ONLY_SETTINGS, key, "%s stays on its device" % key)
	assert_has(ProfileBackup.DEVICE_ONLY_SETTINGS, TextSize.VR_KEY)


func test_the_huds_cross_never_shows_in_vr() -> void:
	assert_true(Hud.shows_crosshair(true, false), "a PC's captured mouse, a pad: the cross")
	assert_true(Hud.shows_crosshair(false, true), "a drawn bow")
	assert_false(Hud.shows_crosshair(false, false))
	Vr.simulate(true)
	assert_false(Hud.shows_crosshair(true, true), "in a headset the hand's laser aims")


func test_the_tv_shows_its_sign_in_vr_and_the_shorts_play() -> void:
	Vr.simulate(true)
	var fake := TheaterFakePlayer.new()
	var panel := TheaterPanel.new()
	panel.list = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)
	var p := ProfileData.new()
	p.username = "Mia"
	p.age_band = AgeBand.TEEN_PLUS
	panel.profile = p
	panel.save_profile = func() -> void: pass
	panel.is_mobile = true
	panel.backend = fake
	panel.frees_mouse = false
	panel.opens_on_shorts = false
	add_child_autofree(panel)
	await _frames(2)
	panel.open()
	await _frames(2)
	assert_false(fake.played, "no YouTube player in a headset (an Android view is not in the VR frame)")
	assert_eq(panel.view, TheaterPanel.VIEW_VR_TV)
	assert_string_contains(panel.card_label.text, VrWords.TV_SIGN)
	var shorts := panel.card_button(TheaterPanel.WATCH_SHORTS)
	assert_not_null(shorts)
	if shorts:
		shorts.pressed.emit()
		assert_eq(panel.view, TheaterPanel.VIEW_SHORTS, "EasyCraft Shorts play in VR")


class TheaterFakePlayer:
	extends RefCounted
	signal ended
	signal failed(code: String)
	var played := false

	func play(_video: Dictionary, _autoplay: bool, _rect: Rect2i, _close: Rect2i) -> void:
		played = true

	func set_rect(_rect: Rect2i, _close: Rect2i) -> void:
		pass

	func hide() -> void:
		pass

	func reveal() -> void:
		pass

	func close() -> void:
		pass


func test_the_worlds_colour_tint_is_not_drawn_on_the_panel() -> void:
	assert_true(Ambience.shows_tint(Color(0.1, 0.3, 0.8, 0.3)), "a flat screen: underwater blue")
	assert_false(Ambience.shows_tint(Color(0, 0, 0, 0)))
	Vr.simulate(true)
	assert_false(Ambience.shows_tint(Color(0.1, 0.3, 0.8, 0.3)), "a headset: the fog and the light carry the mood")
