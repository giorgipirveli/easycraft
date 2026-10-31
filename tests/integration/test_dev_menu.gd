extends GutTest
## The developer menu (debug builds only; triple-tap the version label) on the emulator's
## 2400×1080 screen. The lead drives it by tapping screen positions (AUTOPILOT BLOCKY at x 891,
## AUTOPILOT REALISTIC at x 1479), so the AUTOPILOT TOUR button must not move any other control.
## The panel has no room for a row below AUTOPILOT 10 BUDDIES, so the tour button sits to its right.

const SCREEN := Vector2i(2400, 1080)
const TAP_X := {"AUTOPILOT BLOCKY": 891.0, "AUTOPILOT REALISTIC": 1479.0}

var menu: Node
var _window_size: Vector2i


func before_all() -> void:
	_window_size = get_window().size


func before_each() -> void:
	get_window().size = SCREEN
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)
	menu.call("_show_dev")
	await wait_frames(4)


func after_all() -> void:
	get_window().size = _window_size


func _button(text: String) -> Button:
	for b in menu.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


## A control's rectangle in screen pixels.
func _screen_rect(c: Control) -> Rect2:
	var scale := float(get_window().size.y) / get_viewport().get_visible_rect().size.y
	var r := c.get_global_rect()
	return Rect2(r.position * scale, r.size * scale)


func _button_rects(except: Button) -> Dictionary:
	var rects := {}
	for b in menu.find_children("*", "Button", true, false):
		if b != except and (b as Button).is_visible_in_tree():
			rects[(b as Button).text] = _screen_rect(b)
	return rects


func test_the_screen_is_the_emulators() -> void:
	assert_eq(get_window().size, SCREEN)


func test_the_tour_button_moves_no_other_button() -> void:
	var tour := _button("AUTOPILOT TOUR")
	assert_not_null(tour, "AUTOPILOT TOUR button")
	if tour == null:
		return
	var survivor := _button("SURVIVOR TOUR")   # M2 Task 12: its twin on the left keeps 10 BUDDIES centred
	assert_not_null(survivor, "SURVIVOR TOUR button")
	if survivor == null:
		return
	var with_tour := _button_rects(tour)
	with_tour.erase(survivor.text)
	tour.visible = false
	survivor.visible = false
	await wait_frames(3)
	assert_eq(_button_rects(tour), with_tour, "the same buttons in the same places without the two tours")


func test_the_autopilot_buttons_stay_under_the_leads_taps() -> void:
	for text: String in TAP_X:
		var b := _button(text)
		assert_not_null(b, text)
		if b:
			var r := _screen_rect(b)
			assert_between(TAP_X[text], r.position.x, r.end.x, "%s spans x %d..%d" % [text, r.position.x, r.end.x])


func test_the_tour_button_is_on_screen_right_of_ten_buddies() -> void:
	var tour := _button("AUTOPILOT TOUR")
	var buddies := _button("AUTOPILOT 10 BUDDIES")
	assert_not_null(tour, "AUTOPILOT TOUR button")
	assert_not_null(buddies, "AUTOPILOT 10 BUDDIES button")
	if tour == null or buddies == null:
		return
	var r := _screen_rect(tour)
	var b := _screen_rect(buddies)
	assert_true(Rect2(Vector2.ZERO, Vector2(SCREEN)).encloses(r), "on screen: %s" % r)
	assert_almost_eq(r.get_center().y, b.get_center().y, 0.5, "in the 10 BUDDIES row")
	assert_gt(r.position.x, b.end.x, "right of 10 BUDDIES")
	for text: String in _button_rects(tour):
		assert_false(_button_rects(tour)[text].intersects(r), "does not cover %s" % text)
	gut.p("AUTOPILOT TOUR centre on a 2400x1080 screen: %s (10 BUDDIES: %s)" % [r.get_center(), b.get_center()])


func test_the_tour_button_is_wired() -> void:
	var tour := _button("AUTOPILOT TOUR")
	assert_not_null(tour)
	if tour:
		assert_gt(tour.pressed.get_connections().size(), 1, "the click sound and the tour")


## M2 Task 12 (acceptance row 13): NIGHT RUN at the end of the LAN row makes the next autopilot run at
## night with monsters; the autopilot and tour buttons stay where the lead taps (the tests above).
func test_a_night_run_toggle_sets_the_autopilot_at_night() -> void:
	Game.autopilot_night = false
	var night := _button("NIGHT RUN: OFF")
	assert_not_null(night, "NIGHT RUN toggle")
	if night == null:
		return
	night.pressed.emit()
	assert_true(Game.autopilot_night, "on")
	assert_eq(night.text, "NIGHT RUN: ON")
	night.pressed.emit()
	assert_false(Game.autopilot_night, "off again")
	var r := _screen_rect(night)
	assert_true(Rect2(Vector2.ZERO, Vector2(SCREEN)).encloses(r), "on screen: %s" % r)
	for text: String in _button_rects(night):
		assert_false(_button_rects(night)[text].intersects(r), "does not cover %s" % text)
	gut.p("NIGHT RUN centre on a 2400x1080 screen: %s" % r.get_center())


## M3 acceptance (Task 18): the autopilot in every universe. WORLD beside the address field cycles the
## universes that exist, then the space worlds (UniverseRegistry.autopilot_worlds); past Green Meadows the autopilot buttons start a
## new Survivor world there. The buttons the lead taps don't move (the tests above).
func test_a_world_toggle_picks_the_autopilots_universe() -> void:
	Game.autopilot_universe = 1
	var world := _button("WORLD: " + UniverseRegistry.display_name(1).to_upper())
	assert_not_null(world, "WORLD toggle")
	if world == null:
		return
	var seen: Array[int] = [Game.autopilot_universe]
	for i in UniverseRegistry.autopilot_worlds().size():
		world.pressed.emit()
		seen.append(Game.autopilot_universe)
		assert_eq(world.text, "WORLD: " + UniverseRegistry.display_name(Game.autopilot_universe).to_upper())
	assert_eq(seen.back(), 1, "round the universes and the space worlds back to Green Meadows: %s" % [seen])
	for u in seen:
		assert_has(UniverseRegistry.autopilot_worlds(), u, "only worlds that exist")
	var r := _screen_rect(world)
	assert_true(Rect2(Vector2.ZERO, Vector2(SCREEN)).encloses(r), "on screen: %s" % r)
	for text: String in _button_rects(world):
		assert_false(_button_rects(world)[text].intersects(r), "does not cover %s" % text)
	gut.p("WORLD centre on a 2400x1080 screen: %s" % r.get_center())
	Game.autopilot_universe = 1


func test_the_next_universe_goes_round_the_ones_that_exist() -> void:
	var avail := UniverseRegistry.available()
	assert_eq(UniverseRegistry.next_available(avail.back()), avail[0])
	assert_eq(UniverseRegistry.next_available(99), avail[0], "an unknown one starts over")
	if avail.size() > 1:
		assert_eq(UniverseRegistry.next_available(avail[0]), avail[1])


## Cosmos: the autopilot measures the space worlds too (WORLD goes on from the ladder to the Moon, Mars, Europa …),
## so a new world's frame rate is checked on the emulator like every universe's.
func test_the_autopilot_world_goes_on_to_the_space_worlds() -> void:
	var worlds := UniverseRegistry.autopilot_worlds()
	for u in UniverseRegistry.available():
		assert_has(worlds, u)
	for u in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.EUROPA]:
		assert_has(worlds, u, "world %d" % u)
	assert_eq(UniverseRegistry.next_autopilot(worlds.back()), worlds[0], "round again")
	assert_eq(UniverseRegistry.next_autopilot(UniverseRegistry.available().back()), SpaceRules.MOON,
		"after the last universe, the Moon")

