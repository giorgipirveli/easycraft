extends GutTest
## M3 Task 10: the Gold Farm's panel (a tap on the barn): what the farm makes and holds as pictures and short
## words, the rule in one line, and two big buttons, FASTER and BIGGER, with their fixed prices (BEST! at the
## top); the owner's only (a guest sees the farm, no buttons). A choice asks the host; the host's answer shows
## inside the panel. It fits the screen and closes with X, a tap outside, Back, or walking away.

const SCREEN := Vector2(1280, 720)

var _gold_before := 0
var _asked: Array = []


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	Profile.data.survivor_gold = 250
	_asked.clear()
	Session.farm_upgrade_requested.connect(_on_asked)


func after_each() -> void:
	Profile.data.survivor_gold = _gold_before
	Session.farm_upgrade_requested.disconnect(_on_asked)


func _on_asked(peer_id: int, kind: StringName) -> void:
	_asked.append([peer_id, kind])


func _panel(farm: Dictionary, owner := true) -> FarmPanel:
	var p := FarmPanel.new()
	p.is_owner = func() -> bool: return owner
	add_child_autofree(p)
	p.open(null, farm)
	return p


func _farm(rate := 0, cap := 0) -> Dictionary:
	return FarmRules.new_farm(Vector3i(0, 30, 0), 0, rate, cap)


func test_it_shows_what_the_farm_makes_and_holds() -> void:
	var p := _panel(_farm())
	assert_true(p.visible)
	assert_eq(p.rate_text(), "20 an hour")
	assert_eq(p.cap_text(), "Holds 12 hours")
	assert_eq(p.workers_shown(), 1)
	assert_string_contains(p.rule_text(), "Stand on your farm")


func test_the_buttons_show_the_next_levels_fixed_prices() -> void:
	var p := _panel(_farm())
	assert_true(p.faster_button.visible)
	assert_true(p.bigger_button.visible)
	assert_string_contains(p.faster_button.text, "200")
	assert_string_contains(p.bigger_button.text, "150")
	assert_false(p.faster_button.disabled, "250 gold is enough")
	Profile.data.survivor_gold = 100
	p.show_farm(_farm())
	assert_true(p.faster_button.disabled, "not enough gold yet: grey, never hidden")


func test_at_the_top_it_says_best() -> void:
	var p := _panel(_farm(3, 3))
	assert_string_contains(p.faster_button.text, "BEST")
	assert_true(p.faster_button.disabled)
	assert_string_contains(p.bigger_button.text, "BEST")
	assert_eq(p.rate_text(), "50 an hour")
	assert_eq(p.cap_text(), "Holds 24 hours")
	assert_eq(p.workers_shown(), 3)


func test_a_choice_asks_the_host_and_its_answer_shows_inside() -> void:
	var p := _panel(_farm())
	p.faster_button.pressed.emit()
	assert_eq(_asked, [[multiplayer.get_unique_id(), FarmRules.RATE]])
	Session.magic_feedback.emit("Faster farm! 30 gold an hour.")
	assert_eq(p.answer_text(), "Faster farm! 30 gold an hour.")
	p.show_farm(_farm(1))
	assert_eq(p.rate_text(), "30 an hour", "the host's new farm")
	assert_eq(p.workers_shown(), 2)
	p.bigger_button.pressed.emit()
	assert_eq(_asked.back(), [multiplayer.get_unique_id(), FarmRules.CAP])


func test_a_guest_sees_the_farm_but_no_buttons() -> void:
	var p := _panel(_farm(), false)
	assert_false(p.faster_button.visible)
	assert_false(p.bigger_button.visible)
	assert_eq(p.rate_text(), "20 an hour")
	assert_string_contains(p.rule_text(), "owner")


func test_it_fits_the_screen_and_closes_with_its_x() -> void:
	var p := _panel(_farm())
	var r := p.panel_rect(SCREEN)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(r), str(r))
	var content := (p.find_children("*", "PanelContainer", false, false)[0] as Control).get_combined_minimum_size()
	assert_lte(content.y, FarmPanel.PANEL_SIZE.y + 0.5, "everything fits the panel's height")
	assert_lte(content.x, FarmPanel.PANEL_SIZE.x + 0.5)
	for b: Button in [p.faster_button, p.bigger_button, p.close_button]:
		assert_gte(b.custom_minimum_size.y, 84.0, "big enough for a child's finger")
	p.close_button.pressed.emit()
	assert_false(p.visible)


func test_it_closes_when_the_player_walks_away() -> void:
	var b := FarmBuilding.new()
	add_child_autofree(b)
	b.setup(_farm())
	var feet := [Vector3(0, 30, 6)]
	var p := FarmPanel.new()
	p.is_owner = func() -> bool: return true
	p.player_feet = func() -> Vector3: return feet[0]
	add_child_autofree(p)
	p.open(b, _farm())
	p.check_reach()
	assert_true(p.visible, "near the barn")
	feet[0] = Vector3(0, 30, 40)
	p.check_reach()
	assert_false(p.visible, "walked away")


func test_the_owner_can_move_the_farm_and_a_guest_can_not() -> void:
	var moved: Array = []
	var ask := func(peer_id: int) -> void: moved.append(peer_id)
	Session.farm_move_requested.connect(ask)
	var p := _panel(_farm())
	assert_true(p.move_button.visible)
	assert_gte(p.move_button.custom_minimum_size.x, 135.0)
	p.move_button.pressed.emit()
	assert_eq(moved, [multiplayer.get_unique_id()], "asks the host")
	assert_false(p.visible, "the panel closes: the farm goes back in the bag")
	var guest := _panel(_farm(), false)
	assert_false(guest.move_button.visible)
	Session.farm_move_requested.disconnect(ask)
