extends GutTest
## Owner #101 (VR on the Meta Quest, P2): the whole VR COMFORT page (turning, the comfort view, walking where the head
## or the hand points, teleport, the eye's height, the break card's time, text size, RECENTER; every choice one of the
## profile's vr_* settings) and the break card: after vr_break_minutes in the headset (30 first; never when 0) a card on
## the eye panel says it is time for a rest, the game waits behind it, and I'M BACK starts the time again.

var _old_pad: PadFocus
var _saved := {}


func before_each() -> void:
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	for key: String in VrComfortPage.ROWS_KEYS:
		_saved[key] = Profile.data.settings.get(key)


func after_each() -> void:
	Vr.simulate(false)
	get_tree().paused = false
	PadFocus.instance = _old_pad
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _settings() -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass
	box.add_child(s)
	add_child_autofree(box)
	return s


func test_every_comfort_choice_is_on_the_page_and_stored() -> void:
	Vr.simulate(true)
	var s := _settings()
	await _frames(1)
	(s.find_child("Page_vr", true, false) as Button).pressed.emit()
	await _frames(1)
	var picks := {VrRules.TURN: ["VrTurn_snap30", "snap30"], VrRules.VIGNETTE: ["VrVignette_off", "off"],
		VrRules.WALK_DIR: ["VrWalk_hand", "hand"], VrRules.TELEPORT: ["VrTeleport_false", false],
		VrRules.HEIGHT: ["VrHeight_real", "real"], VrRules.BREAK_MINUTES: ["VrBreak_60", 60],
		TextSize.VR_KEY: ["VrText_normal", "normal"]}
	for key: String in picks:
		var b := s.find_child(picks[key][0], true, false) as Button
		assert_not_null(b, picks[key][0])
		if b == null:
			continue
		assert_true(b.is_visible_in_tree(), "%s shows" % b.name)
		b.pressed.emit()
		assert_eq(Profile.data.settings[key], picks[key][1], key)
		assert_eq(typeof(Profile.data.settings[key]), typeof(VrRules.DEFAULTS.get(key, "normal")), "%s keeps its type" % key)
	await _frames(2)
	var height := (s.get_parent() as Control).get_combined_minimum_size().y
	gut.p("SETTINGS with VR COMFORT: %d px tall" % height)
	assert_lte(height, 720.0, "the whole page fits the canvas (its words 24 px or more)")


func test_a_choice_the_game_does_not_know_reads_its_default() -> void:
	assert_eq(VrComfortPage.value_of({VrRules.WALK_DIR: "feet"}, VrRules.WALK_DIR), VrRules.WALK_DIR_DEFAULT)
	assert_eq(VrComfortPage.value_of({VrRules.TELEPORT: "yes"}, VrRules.TELEPORT), VrRules.TELEPORT_DEFAULT)
	assert_eq(VrComfortPage.value_of({VrRules.BREAK_MINUTES: 45}, VrRules.BREAK_MINUTES), VrRules.BREAK_MINUTES_DEFAULT,
		"only the page's own times")
	assert_eq(VrComfortPage.value_of({VrRules.BREAK_MINUTES: 0}, VrRules.BREAK_MINUTES), 0, "never")
	var p := ProfileData.from_json(JSON.stringify({"settings": {VrRules.HEIGHT: "tall", VrRules.BREAK_MINUTES: 999}}))
	assert_eq(p.settings[VrRules.HEIGHT], VrRules.HEIGHT_DEFAULT)
	assert_eq(p.settings[VrRules.BREAK_MINUTES], VrRules.BREAK_MINUTES_DEFAULT)


func test_the_break_rule() -> void:
	assert_false(VrBreakCard.due(29.0 * 60.0, 30, 0.0))
	assert_true(VrBreakCard.due(30.0 * 60.0, 30, 0.0), "30 minutes in the headset")
	assert_false(VrBreakCard.due(50.0 * 60.0, 30, 30.0 * 60.0), "30 minutes after the last card")
	assert_true(VrBreakCard.due(60.0 * 60.0, 30, 30.0 * 60.0))
	assert_false(VrBreakCard.due(500.0 * 60.0, 0, 0.0), "never when the child turned it off")


func test_after_the_time_a_break_card_waits_on_the_eye_panel() -> void:
	Profile.data.settings[VrRules.BREAK_MINUTES] = 30
	Vr.simulate(true)
	Vr.ui_viewport()
	var ui := VrUi.instance
	var card := ui.break_card
	assert_false(card.visible)
	ui.worn = 30.0 * 60.0 - 0.1
	ui.step(0.0)
	assert_false(card.visible, "not yet")
	ui.step(0.2)
	assert_true(card.visible, "30 minutes in the headset")
	assert_true(get_tree().paused, "the game waits behind it")
	assert_eq(ui.panel.place, VrPanelRules.EYE)
	assert_string_contains(card.words.text, "30 minutes")
	card.back_button.pressed.emit()
	ui.step(0.016)
	assert_false(card.visible)
	assert_false(get_tree().paused, "I'M BACK: the game goes on")
	ui.worn += 29.0 * 60.0
	ui.step(0.0)
	assert_false(card.visible, "the next card is 30 minutes after this one")


func test_no_break_card_when_the_child_turned_it_off() -> void:
	Profile.data.settings[VrRules.BREAK_MINUTES] = 0
	Vr.simulate(true)
	Vr.ui_viewport()
	var ui := VrUi.instance
	ui.worn = 600.0 * 60.0
	ui.step(1.0)
	assert_false(ui.break_card.visible)
