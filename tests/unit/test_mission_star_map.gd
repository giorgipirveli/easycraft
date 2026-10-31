extends GutTest
## Missions (spec §21d.5): on the Star Map a real planet not reached yet says "Mission needed: build a rocket at the
## Launch Site" (its card and facts stay free to see); one on the child's route says LAND; Boing and Rainbow stay
## reachable by flying up. Without a route (tools and tests of the map alone) every built world lands, as before.

const OPEN: Array[int] = [16, 17, 18, 19, 20]


func after_each() -> void:
	UniverseRegistry.reset()


func test_a_planet_off_the_route_needs_a_mission() -> void:
	var s := StarMap.states(1, 1, OPEN, 1, [SpaceRules.MARS] as Array[int])
	assert_eq(s[&"moon"], StarMap.MISSION)
	assert_eq(s[&"mars"], StarMap.LAND, "Mars is on the route")
	assert_eq(s[&"europa"], StarMap.MISSION)
	assert_eq(s[&"boing"], StarMap.LAND, "our own planets: fly up")
	assert_eq(s[&"rainbow"], StarMap.LAND)
	assert_eq(s[&"io"], StarMap.COMING_SOON, "not built here: coming soon, mission or not")
	assert_eq(s[&"green_meadows"], StarMap.HERE)
	assert_eq(StarMap.action_words(StarMap.MISSION), "Mission needed: build a rocket at the Launch Site")


func test_from_a_space_world_the_route_holds_too_and_home_always_works() -> void:
	var s := StarMap.states(SpaceRules.MOON, 2, OPEN, 2, [SpaceRules.MOON] as Array[int])
	assert_eq(s[&"moon"], StarMap.HERE)
	assert_eq(s[&"mars"], StarMap.MISSION)
	assert_eq(s[&"sandstorm_desert"], StarMap.HOME)


func test_without_a_route_every_built_world_lands() -> void:
	var s := StarMap.states(1, 1, OPEN, 1)
	assert_eq(s[&"moon"], StarMap.LAND)
	assert_eq(s[&"mars"], StarMap.LAND)


func test_the_panel_shows_the_mission_words_and_no_land_button() -> void:
	var panel := SpacePanel.new()
	add_child_autofree(panel)
	panel.open(1, 1, OPEN, 1, [] as Array[int])
	panel.select(&"moon")
	assert_false(panel.action_button.visible, "no LAND before a mission")
	assert_eq(panel.card_state_words(), StarMap.action_words(StarMap.MISSION))
	assert_eq(panel.card_facts().size(), 3, "the facts stay free to see")
	panel.select(&"boing")
	assert_true(panel.action_button.visible)
	assert_eq(panel.action_button.text, "LAND")
	panel.close()


func test_the_space_director_asks_for_the_route() -> void:
	var d := SpaceDirector.new()
	add_child_autofree(d)
	d.setup_panel(self)
	d.available = func() -> Array[int]: return OPEN
	d.route = func() -> Variant: return [SpaceRules.MOON] as Array[int]
	d.open_picker()
	d.panel.select(&"moon")
	assert_true(d.panel.action_button.visible, "the Moon is on the route")
	d.panel.select(&"mars")
	assert_false(d.panel.action_button.visible)
	d.panel.close()
	d.panel.queue_free()
