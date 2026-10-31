extends GutTest
## M5 Task 1 (spec §15.1a): TEXT SIZE, NORMAL or BIG (×1.25), for the words a child reads while playing: the toasts,
## the name, banners, first-time picture hints, notes and riddles, the knock-out tip, the chat's lines and bar. A
## change in SETTINGS reaches a HUD that is up at once; BIG words still fit a 1280 × 720 screen.

var _saved := {}


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func before_each() -> void:
	_saved = {"text_size": Profile.data.settings.text_size}


func after_each() -> void:
	Profile.data.settings.text_size = _saved.text_size
	HudLayout.reset()


func _hud() -> Hud:
	var w := AirWorld.new()
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	var hud := Hud.new()
	view.add_child(hud)
	hud.setup(p, "Kid", true, false)
	hud.add_health_controls()
	hud.add_revive_controls()
	hud.add_secret_controls(null)
	await wait_process_frames(2)
	return hud


func _size(c: Control) -> int:
	return c.get_theme_font_size(&"normal_font_size" if c is RichTextLabel else &"font_size")


## The words that follow TEXT SIZE, with their NORMAL sizes.
func _words(hud: Hud) -> Dictionary:
	return {"toast": [hud._toast_label, 26], "name": [hud.username_label, 28], "banner": [hud.banner.label, 32],
		"hint": [hud.picture_hint.label, 26], "note": [hud.riddle_panel.text_label, 34],
		"knock-out tip": [hud.knockout_overlay._tip_label, 32], "chat line": [hud.chat._labels[0], ChatPanel.LINE_FONT],
		"chat bar": [hud.chat._field, 28]}


func test_normal_or_big_and_nothing_else() -> void:
	assert_eq(TextSize.factor({"text_size": "normal"}), 1.0)
	assert_eq(TextSize.factor({"text_size": "big"}), 1.25)
	assert_eq(TextSize.factor({"text_size": "huge"}), 1.0)
	assert_eq(ProfileData.new().settings.text_size, "normal")


func test_big_makes_the_playing_words_bigger_at_once() -> void:
	Profile.data.settings.text_size = "normal"
	var hud := await _hud()
	var words := _words(hud)
	for key: String in words:
		assert_eq(_size(words[key][0]), int(words[key][1]), "%s at NORMAL" % key)
	Profile.data.settings.text_size = "big"
	Game.settings_applied.emit(Profile.data.settings)
	await wait_process_frames(2)
	for key: String in words:
		assert_eq(_size(words[key][0]), roundi(int(words[key][1]) * 1.25), "%s at BIG" % key)
	Profile.data.settings.text_size = "normal"
	Game.settings_applied.emit(Profile.data.settings)
	await wait_process_frames(2)
	for key: String in words:
		assert_eq(_size(words[key][0]), int(words[key][1]), "%s back to NORMAL" % key)


func test_a_hud_made_with_big_text_starts_big() -> void:
	Profile.data.settings.text_size = "big"
	var hud := await _hud()
	assert_eq(_size(hud._toast_label), roundi(26 * 1.25))
	assert_eq(_size(hud.chat._labels[0]), roundi(ChatPanel.LINE_FONT * 1.25))


func test_big_words_still_fit_the_screen() -> void:
	Profile.data.settings.text_size = "big"
	var hud := await _hud()
	var view := hud.get_viewport_rect()
	hud.toast("Shiny ores need an IRON pickaxe! Tilly the trader sells one at her stall.")
	hud.show_banner("You found a secret treasure chest!")
	hud.riddle_panel.show_riddle("I have hands but I can't clap. I tell you when it's time for bed. What am I?", [0, 1, 2],
		func(_i: int) -> void: pass)
	await wait_process_frames(3)
	for c: Control in [hud._toast_panel, hud.banner, hud.riddle_panel._panel]:
		assert_true(view.encloses(c.get_global_rect()), "%s fits (%s)" % [c.name, c.get_global_rect()])
	hud.riddle_panel.visible = false
	hud.knockout_overlay.knock_out("You were knocked out!", KnockoutRules.TIPS[0])
	hud.get_up_button.visible = true
	await wait_process_frames(3)
	var words := hud.knockout_overlay.words_rect()
	assert_lte(words.end.y, hud.get_up_button.get_global_rect().position.y, "the knock-out words stay above GET UP")
	assert_true(view.encloses(words))


func test_the_chat_measures_its_lines_at_the_size_it_shows() -> void:
	Profile.data.settings.text_size = "big"
	var hud := await _hud()
	for i in 8:
		hud.chat.add_line("A long line from the game that wraps at the big text size, number %d." % i)
	await wait_process_frames(2)
	var area: Rect2 = hud.chat._history_area()
	var used := 0.0
	for l: Label in hud.chat._labels:
		if l.visible:
			used += l.get_global_rect().size.y
	assert_lte(used, area.size.y + 1.0, "the shown lines fit their area")
