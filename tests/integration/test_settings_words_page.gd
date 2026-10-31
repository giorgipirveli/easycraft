extends GutTest
## M3 Task 21a: SETTINGS has a second page, HELP (the first page was full: 711 of 720 px): "Read to me" and
## SIMPLE / CLASSIC controls (owner #52 took its LANGUAGE out: English only). Both pages fit a 1280 × 720 screen. The panel's saver is a no-op here (the profile file is shared by every worktree).

const SCREEN := Vector2(1280, 720)
const KEYS := ["read_to_me", "simple_controls", "simple_asked"]

var _saved := {}
var _locale := ""


func before_each() -> void:
	for key: String in KEYS:
		_saved[key] = Profile.data.settings[key]
	_locale = TranslationServer.get_locale()


func after_each() -> void:
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]
	TranslationServer.set_locale(_locale)


func _panel() -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass
	box.add_child(s)
	add_child_autofree(box)
	return s


func _fits(s: SettingsPanel, what: String) -> void:
	var size := (s.get_parent() as Control).get_combined_minimum_size()
	gut.p("%s: %s" % [what, size])
	assert_lte(size.y, SCREEN.y, "%s height %d" % [what, size.y])
	assert_lte(size.x, SCREEN.x, "%s width %d" % [what, size.x])


func test_both_pages_fit_the_screen() -> void:
	var s := _panel()
	_fits(s, "the game page")
	s.show_page(SettingsPanel.WORDS)
	_fits(s, "the help page")


func test_the_game_page_shows_first_and_the_second_page_holds_the_new_settings() -> void:
	var s := _panel()
	var read := s.find_child("ReadToMeToggle", true, false) as CheckButton
	var simple := s.find_child("SimpleButton", true, false) as Button
	assert_not_null(read)
	assert_not_null(simple)
	if read == null or simple == null:
		return
	assert_null(s.find_child("LanguageButtons", true, false), "owner #52: no language choice")
	assert_false(read.is_visible_in_tree(), "the game page first")
	assert_true((s.find_child("MusicSlider", true, false) as Control).is_visible_in_tree())
	assert_true(simple.is_visible_in_tree(), "owner #66: SIMPLE / CLASSIC on the first page")
	s.show_page(SettingsPanel.WORDS)
	assert_true(read.is_visible_in_tree())
	assert_false((s.find_child("MusicSlider", true, false) as Control).is_visible_in_tree())


func test_read_to_me_and_simple_controls_show_and_change_their_settings() -> void:
	Profile.data.settings.read_to_me = true
	Profile.data.settings.simple_controls = false
	var s := _panel()
	var read := s.find_child("ReadToMeToggle", true, false) as CheckButton
	var simple := s.find_child("SimpleButton", true, false) as Button
	var classic := s.find_child("ClassicButton", true, false) as Button
	assert_true(read.button_pressed)
	assert_false(simple.button_pressed)
	assert_true(classic.button_pressed)
	read.button_pressed = false
	assert_false(Profile.data.settings.read_to_me)
	simple.pressed.emit()
	assert_true(Profile.data.settings.simple_controls)
	assert_true(Profile.data.settings.simple_asked, "choosing in SETTINGS counts as asked")
	assert_true(simple.button_pressed)
	assert_false(classic.button_pressed)
	classic.pressed.emit()
	assert_false(Profile.data.settings.simple_controls)


func test_coming_back_from_the_grown_ups_page_keeps_the_page() -> void:
	var s := _panel()
	s.show_page(SettingsPanel.WORDS)
	s._show_gate()
	assert_false((s.find_child("ReadToMeToggle", true, false) as Control).is_visible_in_tree())
	s._back_to_settings()
	assert_true((s.find_child("ReadToMeToggle", true, false) as Control).is_visible_in_tree())
	assert_false((s.find_child("MusicSlider", true, false) as Control).is_visible_in_tree(), "not both pages at once")


## Seen on emulator-5554 (2026-09-25 18:48): GAME and HELP were the same blue, so nobody could tell which page was
## open. The open page's button is bright blue; the other one is dark, even under a finger (touch leaves "hover").
func test_the_open_pages_button_stands_out() -> void:
	var s := _panel()
	var game := s.find_child("Page_game", true, false) as Button
	var help := s.find_child("Page_words", true, false) as Button
	for step: Array in [[SettingsPanel.GAME, game, help], [SettingsPanel.WORDS, help, game]]:
		s.show_page(step[0])
		var open: Button = step[1]
		var shut: Button = step[2]
		assert_true(open.button_pressed and not shut.button_pressed, str(step[0]))
		var bright := minf(_bg(open, "pressed").get_luminance(), _bg(open, "hover_pressed").get_luminance())
		var dim := maxf(_bg(shut, "normal").get_luminance(), _bg(shut, "hover").get_luminance())
		assert_gt(bright - dim, 0.15, "%s: the open page's button %.2f, the other %.2f" % [step[0], bright, dim])


func _bg(b: Button, style: String) -> Color:
	var box := b.get_theme_stylebox(style) as StyleBoxFlat
	return box.bg_color if box != null else Color.BLACK


## Owner #66 (2026-09-28): "player should be able to choose anytime and change classic or simple". The choice was on the
## HELP page, where the owner did not find it: now beside the style on the GAME page, the one SETTINGS opens on (in the
## menu and in the pause menu, so any time), in the same row so the page still fits the screen.
func test_simple_and_classic_are_on_the_first_page_beside_the_style() -> void:
	var s := _panel()
	var simple := s.find_child("SimpleButton", true, false) as Button
	var classic := s.find_child("ClassicButton", true, false) as Button
	var blocky := s.find_child("StyleButton_blocky", true, false) as Button
	assert_not_null(blocky, "the style buttons have names")
	if simple == null or classic == null or blocky == null:
		return
	assert_true(simple.is_visible_in_tree() and classic.is_visible_in_tree(), "the game page, shown first")
	assert_eq(simple.get_parent(), blocky.get_parent(), "in the style's row")
	_fits(s, "the game page with the controls")
