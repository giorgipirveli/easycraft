extends GutTest
## Owner feedback #55 (spec §21.1) and #72/#74 (spec §21b.1): crossing the space line opens the Star Map over the
## stars: our solar system in its real order with its moons, far away the game's own planets and every universe. A tap
## on a body opens its card: its name, three real facts (read aloud) and what can happen: LAND on a built space world,
## HOME, or honest words (coming soon, no ground, locked). From a space world HOME also sits by STAY HERE. While the map
## shows, a game played alone holds still and the world and the HUD never hear a touch.

const OPEN: Array[int] = [16, 17, 18]

var _asked: Array[int] = []
var _home := 0
var _stay := 0


func before_each() -> void:
	_asked.clear()
	_home = 0
	_stay = 0


func after_each() -> void:
	get_tree().paused = false
	UniverseRegistry.reset()


func _panel() -> SpacePanel:
	var p := SpacePanel.new()
	p.size = Vector2(1280, 720)
	add_child_autofree(p)
	p.travel_requested.connect(func(u: int) -> void: _asked.append(u))
	p.home_requested.connect(func() -> void: _home += 1)
	p.stay_requested.connect(func() -> void: _stay += 1)
	return p


func _centre(b: Control) -> Vector2:
	return b.global_position + b.size * 0.5


func test_it_opens_the_star_map_of_every_body() -> void:
	var p := _panel()
	assert_false(p.visible, "hidden until the child crosses the line")
	p.open(1, 1, OPEN, 2)
	await wait_process_frames(2)
	assert_true(p.visible)
	assert_eq(p.title_text(), "Where shall we land?")
	assert_eq(p.bodies.size(), StarMap.bodies().size())
	for id: StringName in [&"sun", &"earth", &"moon", &"mars", &"jupiter", &"io", &"saturn", &"pluto", &"boing",
			&"green_meadows", &"universe_6"]:
		assert_not_null(p.body_for(id), str(id))
	for b in p.bodies:
		assert_gte(b.size.x, 64.0, "%s: a child's finger" % b.body_id)
		assert_gte(b.size.y, 64.0, "%s: a child's finger" % b.body_id)
		assert_true(Rect2(Vector2.ZERO, p.size).encloses(Rect2(b.global_position - p.global_position, b.size)),
			"%s is on the screen" % b.body_id)
	assert_eq(p.stay_button.text, "STAY HERE")
	assert_false(p.home_button.visible, "home is where the child is")
	assert_false(p.card_open(), "the map first")


## Owner #91: "we need animation, movements, cyrcle as it is in reality". The planets go round the Sun on orbits in
## their real order, each on its own orbit, where they really are today, the inner ones faster at their real years'
## ratios (an Earth year is SpacePanel.EARTH_YEAR_SECONDS); the moons go round their planets; a card open holds them.
func test_the_planets_circle_the_sun_in_their_real_order_and_the_moons_their_planets() -> void:
	var p := _panel()
	p.open(1, 1, OPEN, 2)
	await wait_process_frames(2)
	var order: Array[StringName] = [&"mercury", &"venus", &"earth", &"mars", &"jupiter", &"saturn", &"uranus",
		&"neptune", &"pluto"]
	for i in order.size() - 1:
		assert_lt(p.orbit_size(order[i]).x, p.orbit_size(order[i + 1]).x, "%s's orbit, then %s's" % [order[i],
			order[i + 1]])
	var sun := _centre(p.body_for(&"sun"))
	for id: StringName in order:
		var o := p.orbit_size(id)
		var d := _centre(p.body_for(id)) - sun
		assert_almost_eq(pow(d.x / o.x, 2) + pow(d.y / o.y, 2), 1.0, 0.08, "%s is on its orbit" % id)
	for moon: StringName in [&"moon", &"io", &"europa", &"ganymede", &"callisto", &"titan", &"triton"]:
		var parent: StringName = StarMap.body(moon).parent
		assert_lt(_centre(p.body_for(moon)).distance_to(_centre(p.body_for(parent))), 130.0, "%s by %s" % [moon, parent])
	assert_lt(_centre(p.body_for(&"boing")).y, _centre(p.body_for(&"earth")).y, "the far worlds are up in the sky")
	assert_lt(_centre(p.body_for(&"green_meadows")).y, _centre(p.body_for(&"jupiter")).y)
	var before := {}
	for id: StringName in [&"mercury", &"earth", &"jupiter"]:
		before[id] = p.angle_of(id)
	p.advance(2.0)
	var turned := {}
	for id: StringName in before:
		turned[id] = angle_difference(before[id], p.angle_of(id))
	assert_gt(turned[&"mercury"], turned[&"earth"], "Mercury is the fastest")
	assert_gt(turned[&"earth"], turned[&"jupiter"])
	assert_almost_eq(turned[&"mercury"] / turned[&"earth"], StarMap.year_days(&"earth") / StarMap.year_days(&"mercury"),
		0.05, "their real years' ratio")
	assert_almost_eq(turned[&"earth"], TAU * 2.0 / SpacePanel.EARTH_YEAR_SECONDS, 0.001)
	p.select(&"mars")
	var held := p.angle_of(&"mercury")
	p.advance(2.0)
	assert_eq(p.angle_of(&"mercury"), held, "a card open holds the planets still (easy to tap)")


func test_a_tap_opens_the_card_with_its_facts_and_land() -> void:
	var p := _panel()
	p.open(1, 1, OPEN, 2)
	await wait_process_frames(2)
	p.body_for(&"moon").pressed.emit()
	assert_true(p.card_open())
	assert_eq(p.card_title(), "The Moon")
	assert_eq(p.card_facts(), StarMap.body(&"moon").facts)
	assert_true(p.action_button.visible)
	assert_eq(p.action_button.text, "LAND")
	p.action_button.pressed.emit()
	assert_eq(_asked, [16] as Array[int])
	p.say("Space trips work when you play alone.")
	assert_eq(p.hint(), "Space trips work when you play alone.")
	assert_true(p.visible, "stays open to try again")


## The Space Book learns each card the child opens (spec §21b.2).
func test_opening_a_card_says_the_body_was_seen() -> void:
	var p := _panel()
	var seen: Array[StringName] = []
	p.body_seen.connect(func(id: StringName) -> void: seen.append(id))
	p.open(1, 1, OPEN, 2)
	p.body_for(&"saturn").pressed.emit()
	p.body_for(&"io").pressed.emit()
	assert_eq(seen, [&"saturn", &"io"] as Array[StringName])


func test_a_planet_still_to_build_and_a_gas_giant_say_so() -> void:
	var p := _panel()
	p.open(1, 1, OPEN, 2)
	await wait_process_frames(2)
	p.body_for(&"mars").pressed.emit()
	assert_eq(p.card_title(), "Mars")
	assert_false(p.action_button.visible, "nothing to land on yet")
	assert_eq(p.card_state_words(), "Coming soon: explorers are building it!")
	assert_eq(p.card_facts().size(), 3, "its facts are there to learn now")
	p.body_for(&"jupiter").pressed.emit()
	assert_eq(p.card_title(), "Jupiter")
	assert_false(p.action_button.visible)
	assert_eq(p.card_state_words(), "No ground to land on here.")
	p.body_for(&"frostpeak").pressed.emit()
	assert_eq(p.card_state_words(), StarMap.action_words(StarMap.LOCKED))
	p.body_for(&"sandstorm_desert").pressed.emit()
	assert_eq(p.card_state_words(), StarMap.action_words(StarMap.PORTAL))
	assert_true(_asked.is_empty())


func test_back_to_the_map() -> void:
	var p := _panel()
	p.open(1, 1, OPEN, 2)
	await wait_process_frames(2)
	p.body_for(&"saturn").pressed.emit()
	assert_true(p.card_open())
	p.map_button.pressed.emit()
	assert_false(p.card_open())
	assert_true(p.visible)


func test_from_the_moon_home_is_by_stay_here_and_on_the_map() -> void:
	var p := _panel()
	p.open(16, 3, OPEN, 3)
	await wait_process_frames(2)
	assert_true(p.home_button.visible)
	assert_eq(p.home_button.text, "HOME")
	p.home_button.pressed.emit()
	assert_eq(_home, 1)
	p.body_for(&"frostpeak").pressed.emit()
	assert_eq(p.action_button.text, "HOME", "Frostpeak, where the trip started")
	p.action_button.pressed.emit()
	assert_eq(_home, 2)
	p.body_for(&"moon").pressed.emit()
	assert_false(p.action_button.visible)
	assert_eq(p.card_state_words(), "You are here!")
	assert_true(_asked.is_empty(), "HOME is not a landing")


func test_stay_here_closes_it() -> void:
	var p := _panel()
	var closed := [0]
	p.closed.connect(func() -> void: closed[0] += 1)
	p.open(1, 1, OPEN, 1)
	p.stay_button.pressed.emit()
	assert_eq(_stay, 1)
	assert_false(p.visible)
	assert_eq(closed[0], 1)


func test_played_alone_the_game_holds_still_while_it_shows() -> void:
	var p := _panel()
	assert_eq(p.process_mode, Node.PROCESS_MODE_ALWAYS, "it works while the game holds still")
	p.hold = true
	p.open(1, 1, OPEN, 1)
	assert_true(get_tree().paused, "the flyer does not keep climbing (or paying) while choosing")
	p.close()
	assert_false(get_tree().paused)
	p.hold = false
	p.open(1, 1, OPEN, 1)
	assert_false(get_tree().paused, "with friends the game goes on")


func test_opening_again_starts_on_the_map_with_no_old_words() -> void:
	var p := _panel()
	p.open(1, 1, OPEN, 1)
	p.body_for(&"boing").pressed.emit()
	p.say("Space trips work when you play alone.")
	p.close()
	p.open(17, 1, OPEN, 1)
	assert_false(p.card_open())
	assert_eq(p.hint(), "", "an old refusal is gone")
	assert_true(p.home_button.visible)


func test_it_blocks_the_world_and_draws_the_planet_below() -> void:
	var p := _panel()
	p.open(1, 4, OPEN, 4)
	assert_has(p.blockers(), p)
	assert_eq(p.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(p.planet_colors().ground, UniverseRegistry.card_colors(1).ground, "Green Meadows below")
	p.close()
	p.open(16, 2, OPEN, 2)
	assert_eq(p.planet_colors().ground, UniverseRegistry.card_colors(16).ground, "the Moon below when leaving it")
