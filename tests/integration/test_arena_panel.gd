extends GutTest
## Monster Wave's result panel (spec §12.20): after a run, "What a run!" with the time, the waves and the gold (and
## "A new best!"), PLAY AGAIN and LEAVE as equal big buttons; after the raid boss, "You beat the raid boss!" with
## NEXT UNIVERSE (when there is one to go to) and STAY. Kind words, big buttons, a tap hides it.


func _panel() -> ArenaPanel:
	var p := ArenaPanel.new()
	add_child_autofree(p)
	return p


func _result(won: bool, next: int = 0, new_best: bool = false) -> Dictionary:
	return {"seconds": 204.0, "cleared": 10 if won else 5, "gold": 45, "won": won, "new_best": new_best, "next": next,
		"best": {"best_time": 204.0, "best_wave": 5}}


func test_after_a_run_play_again_or_leave() -> void:
	var p := _panel()
	assert_false(p.visible)
	p.show_result(_result(false, 0, true))
	assert_true(p.visible)
	assert_eq(p.title_text(), "What a run!")
	assert_eq(p.line_text(), ArenaRules.result_line(204.0, 5, 45))
	assert_eq(p.best_text(), "A new best!")
	assert_eq(p.button_words(), [ArenaRules.AGAIN_WORD, ArenaRules.LEAVE_WORD] as Array[String])


func test_after_the_raid_boss_next_universe_or_stay() -> void:
	var p := _panel()
	p.show_result(_result(true, 2))
	assert_eq(p.title_text(), "You beat the raid boss!")
	assert_eq(p.button_words(), [ArenaRules.NEXT_WORD, ArenaRules.STAY_WORD] as Array[String])
	p.show_result(_result(true, 0))
	assert_eq(p.button_words(), [ArenaRules.STAY_WORD] as Array[String], "no next universe yet: STAY only")
	assert_eq(p.note_text(), "The next universe is coming soon!")


func test_the_buttons_are_big_and_equal_and_say_what_they_do() -> void:
	var p := _panel()
	p.show_result(_result(false))
	await wait_process_frames(2)
	var buttons := p.buttons()
	assert_eq(buttons.size(), 2)
	for b in buttons:
		assert_gte(b.size.y, 110.0)
		assert_eq(b.size, buttons[0].size, "equal buttons: no choice is pushed")
	var said: Array[String] = []
	p.again_pressed.connect(func() -> void: said.append("again"))
	p.leave_pressed.connect(func() -> void: said.append("leave"))
	p.next_pressed.connect(func() -> void: said.append("next"))
	buttons[0].pressed.emit()
	assert_eq(said, ["again"] as Array[String])
	assert_false(p.visible, "a tap hides it")
	p.show_result(_result(false))
	p.buttons()[1].pressed.emit()
	assert_eq(said.back(), "leave")
	p.show_result(_result(true, 2))
	p.buttons()[0].pressed.emit()
	assert_eq(said.back(), "next")
	p.show_result(_result(true, 2))
	p.buttons()[1].pressed.emit()
	assert_eq(said.back(), "again", "STAY plays again here")


func test_every_word_is_kind() -> void:
	var p := _panel()
	for r in [_result(false), _result(true, 2), _result(true, 0), _result(false, 0, true)]:
		p.show_result(r)
		for text in [p.title_text(), p.line_text(), p.best_text(), p.note_text()]:
			for word in ["die", "dead", "lost", "fail", "hurry", "loser"]:
				assert_false(text.to_lower().contains(word), "%s: %s" % [text, word])
