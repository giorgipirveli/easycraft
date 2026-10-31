extends GutTest
## M2 Task 7: the gold counter (top-right under the username): a coin and the player's Survivor gold
## in short numbers, ∞ in Sandbox; it updates when the host changes the gold, with a bounce and a
## floating "+12".

const SCREEN := Vector2(1280, 720)

var _mode_before: StringName
var _gold_before := 0


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold


func after_each() -> void:
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func _counter() -> GoldCounter:
	var c := GoldCounter.new()
	add_child_autofree(c)
	c.refresh()
	return c


func test_sandbox_shows_infinity() -> void:
	Game.mode = ModeRules.SANDBOX
	var c := _counter()
	assert_eq(c.shown_text(), "∞")
	assert_true(ThemeDB.fallback_font.has_char("∞".unicode_at(0)), "the font can draw it")
	Session.gold_changed.emit(50)
	assert_eq(c.shown_text(), "∞", "Sandbox gold never changes")


func test_survivor_shows_the_gold_and_follows_the_host() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 30
	var c := _counter()
	assert_eq(c.shown_text(), "30")
	assert_false(c.popup_visible(), "no change yet")
	Session.gold_changed.emit(42)
	assert_eq(c.shown_text(), "42")
	assert_true(c.popup_visible())
	assert_eq(c.popup_text(), "+12")
	Session.gold_changed.emit(41)
	assert_eq(c.popup_text(), "-1", "a flight charge")
	Session.gold_changed.emit(1250)
	assert_eq(c.shown_text(), "1.2K", "short numbers")


func test_a_change_bounces_and_then_settles() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 5
	var c := _counter()
	Session.gold_changed.emit(10)
	await wait_process_frames(2)
	assert_gt(c.scale.x, 1.0, "a little bounce")
	await wait_seconds(GoldCounter.POPUP_TIME + 0.2)
	assert_almost_eq(c.scale.x, 1.0, 0.001)
	assert_false(c.popup_visible())


func test_the_counter_sits_top_right_under_the_username_clear_of_the_buttons() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	var gold := _rect(hud.gold_counter)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(gold), "on screen")
	assert_gte(gold.position.y, _rect(hud.username_label).end.y, "under the username")
	assert_gt(gold.get_center().x, SCREEN.x * 0.6, "on the right")
	for other: Control in [hud.physics_button, hud.more_button, hud.pause_button, hud.fps_label, hud.username_label]:
		assert_false(gold.intersects(_rect(other)), "clear of %s" % other.get_class())
