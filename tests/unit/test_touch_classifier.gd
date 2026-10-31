extends GutTest

var tc: TouchClassifier


func before_each() -> void:
	tc = TouchClassifier.new()


func test_quick_release_is_tap() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_eq(tc.up(1, Vector2(102, 101), 0.1), TouchClassifier.Gesture.TAP)


func test_slow_release_without_hold_update_is_not_tap() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_eq(tc.up(1, Vector2(100, 100), 0.4), TouchClassifier.Gesture.NONE)


func test_hold_fires_once() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_eq(tc.update(0.1), TouchClassifier.Gesture.NONE)
	assert_eq(tc.update(0.3), TouchClassifier.Gesture.HOLD)
	assert_eq(tc.update(0.5), TouchClassifier.Gesture.NONE)
	assert_eq(tc.up(1, Vector2(100, 100), 0.6), TouchClassifier.Gesture.NONE)


func test_drag_beats_tap() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_eq(tc.move(1, Vector2(105, 100), 0.02), TouchClassifier.Gesture.NONE, "small wobble is not a drag")
	assert_eq(tc.move(1, Vector2(130, 100), 0.05), TouchClassifier.Gesture.DRAG)
	assert_eq(tc.up(1, Vector2(130, 100), 0.1), TouchClassifier.Gesture.NONE)
	assert_eq(tc.update(0.5), TouchClassifier.Gesture.NONE, "dragging never becomes hold")


func test_drag_keeps_reporting_after_threshold() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	tc.move(1, Vector2(130, 100), 0.05)
	assert_eq(tc.move(1, Vector2(131, 100), 0.06), TouchClassifier.Gesture.DRAG)


func test_ignores_touch_indices_it_does_not_own() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_false(tc.owns(0))
	assert_true(tc.owns(1))
	assert_eq(tc.move(0, Vector2(300, 100), 0.02), TouchClassifier.Gesture.NONE)
	assert_eq(tc.up(0, Vector2(100, 100), 0.05), TouchClassifier.Gesture.NONE)
	assert_eq(tc.up(1, Vector2(100, 100), 0.05), TouchClassifier.Gesture.TAP)
	assert_false(tc.owns(1))


## Deferred M1 minor: a touch the system cancels (e.g. a notification shade or a palm) must never
## place a block.
func test_cancelled_touch_is_not_a_tap() -> void:
	tc.down(0, Vector2(100, 100), 0.0)
	assert_eq(tc.up(0, Vector2(100, 100), 0.05, true), TouchClassifier.Gesture.NONE)
	assert_false(tc.owns(0), "and the touch is released")


## Deferred M1 minor: the HUD pauses with the game, so a finger lifted during the pause menu is never
## seen. Pausing cancels the touch: no late HOLD breaks a block after RESUME, and the next finger works.
func test_cancel_forgets_the_touch_without_a_gesture() -> void:
	tc.down(0, Vector2(100, 100), 0.0)
	tc.cancel()
	assert_false(tc.owns(0))
	assert_eq(tc.update(1.0), TouchClassifier.Gesture.NONE, "no late HOLD")
	assert_eq(tc.up(0, Vector2(100, 100), 1.1), TouchClassifier.Gesture.NONE)
	tc.down(1, Vector2(200, 100), 2.0)
	assert_true(tc.owns(1), "the next finger is tracked")


## The break ring (M2 Task 3): how far a still finger is towards breaking, 0..1; -1 when no finger
## is holding still (none, a drag, or the break already happened).
func test_hold_progress_fills_while_a_finger_holds_still() -> void:
	assert_eq(tc.hold_progress(0.0), -1.0, "no finger")
	tc.down(1, Vector2(100, 100), 1.0)
	assert_almost_eq(tc.hold_progress(1.0), 0.0, 0.001)
	assert_almost_eq(tc.hold_progress(1.0 + TouchClassifier.HOLD_TIME * 0.4), 0.4, 0.001)
	assert_eq(tc.hold_progress(5.0), 1.0, "never past full")
	assert_eq(tc.update(1.0 + TouchClassifier.HOLD_TIME), TouchClassifier.Gesture.HOLD)
	assert_eq(tc.hold_progress(1.0 + TouchClassifier.HOLD_TIME), -1.0, "broken: the ring goes")


func test_hold_progress_stops_for_a_drag_and_a_lifted_finger() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	tc.move(1, Vector2(140, 100), 0.05)
	assert_eq(tc.hold_progress(0.1), -1.0, "looking around, not breaking")
	tc.up(1, Vector2(140, 100), 0.12)
	tc.down(2, Vector2(10, 10), 1.0)
	tc.up(2, Vector2(10, 10), 1.1)
	assert_eq(tc.hold_progress(1.1), -1.0, "lifted")
