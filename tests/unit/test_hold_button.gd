extends GutTest
## The hold-to-confirm button of the grown-up area (M4 Task 8b, agent G): it acts only after being
## held down for its whole time (3 s), so one stray tap can't delete an online account. Letting go
## early, hiding it or disabling it starts it over.

var b: HoldButton


func before_each() -> void:
	b = HoldButton.new()
	b.text = "HOLD TO DELETE"
	b.size = Vector2(420, 90)
	add_child_autofree(b)
	b.set_process(false)   # the test steps it by hand


func test_it_acts_only_after_three_seconds_held() -> void:
	watch_signals(b)
	assert_eq(b.hold_seconds, 3.0)
	b.button_down.emit()
	b.step(1.0)
	b.step(1.0)
	assert_almost_eq(b.progress, 2.0 / 3.0, 0.001)
	assert_signal_not_emitted(b, "held")
	b.step(1.0)
	assert_signal_emit_count(b, "held", 1)
	b.step(1.0)
	assert_signal_emit_count(b, "held", 1, "once per hold")


func test_a_tap_or_letting_go_early_does_nothing_and_starts_over() -> void:
	watch_signals(b)
	b.button_down.emit()
	b.step(2.9)
	b.button_up.emit()
	assert_eq(b.progress, 0.0, "back to the start")
	b.step(5.0)
	assert_signal_not_emitted(b, "held", "not held any more")
	b.pressed.emit()
	assert_signal_not_emitted(b, "held", "a tap is never enough")


func test_hidden_or_disabled_lets_go() -> void:
	watch_signals(b)
	b.button_down.emit()
	b.step(2.0)
	b.hide()
	b.show()
	assert_eq(b.progress, 0.0, "hidden (another page) lets go")
	b.step(5.0)
	b.disabled = true
	b.button_down.emit()
	b.step(5.0)
	assert_signal_not_emitted(b, "held", "a disabled button never acts")


func test_it_is_big_enough_to_hold() -> void:
	var fresh := HoldButton.new()
	add_child_autofree(fresh)
	assert_gte(fresh.custom_minimum_size.x, OnlineUi.MIN_WIDTH)
	assert_gte(fresh.custom_minimum_size.y, OnlineUi.MIN_HEIGHT)
