extends GutTest
## Owner #88: "what should i do after i land on mercury, there should be some guides". A planet with sights (Mars,
## Europa, Io, Titan, Mercury) gives the child an explorer's checklist on landing (its places by name), the compass
## points to the nearest place not found yet, and each find says how many are found and which is next.

const SIGHTS: Array[Dictionary] = [
	{"id": &"thermometer", "pos": Vector3(11, 40, 0)},
	{"id": &"cliff", "pos": Vector3(0, 40, 160)},
	{"id": &"crater", "pos": Vector3(-300, 40, 0)},
]
const NAMES := {&"thermometer": {"name": "The thermometer"}, &"cliff": {"name": "The long cliff"},
	&"crater": {"name": "A big crater"}, &"river": {"name": "A dry river"}}


func test_the_checklist_lists_the_big_sights_nearest_first() -> void:
	var list := PlanetGuideRules.checklist(SIGHTS, NAMES, {}, Vector3.ZERO)
	assert_eq(list.map(func(e: Dictionary) -> StringName: return e.id), [&"thermometer", &"cliff", &"crater"])
	assert_eq(str(list[1].name), "The long cliff")
	assert_false(bool(list[0].found))
	var found := {"sight:thermometer": true}
	list = PlanetGuideRules.checklist(SIGHTS, NAMES, found, Vector3.ZERO)
	assert_true(bool(list[0].found), "found ones are ticked (sights keep their finds as \"sight:<id>\")")
	var none := PlanetGuideRules.checklist([] as Array[Dictionary], NAMES, {}, Vector3.ZERO)
	assert_eq(none, [] as Array[Dictionary], "a planet without sights has no guide")


func test_the_compass_points_to_the_nearest_place_not_found() -> void:
	var list := PlanetGuideRules.checklist(SIGHTS, NAMES, {"sight:thermometer": true}, Vector3.ZERO)
	var next := PlanetGuideRules.next(list, Vector3(0, 40, 100))
	assert_eq(next.id, &"cliff", "the thermometer is found; the cliff is nearer than the crater")
	for e: Dictionary in list:
		e.found = true
	assert_eq(PlanetGuideRules.next(list, Vector3.ZERO), {}, "all found: nothing to point to")


func test_its_words() -> void:
	var list := PlanetGuideRules.checklist(SIGHTS, NAMES, {}, Vector3.ZERO)
	var intro := PlanetGuideRules.intro("Mercury", list)
	assert_string_contains(intro, "Mercury")
	assert_string_contains(intro, "3 places")
	assert_string_contains(intro, "arrow")
	list[0].found = true
	var after := PlanetGuideRules.progress_words(list, Vector3.ZERO)
	assert_string_contains(after, "1 of 3")
	assert_string_contains(after, "The long cliff", "the next one by name")
	for e: Dictionary in list:
		e.found = true
	assert_string_contains(PlanetGuideRules.progress_words(list, Vector3.ZERO), "all 3", "all explored")


## The HUD's compass: a treasure map in hand points to the treasure (as before); otherwise, on a planet with a guide,
## to the guide's next place.
func test_the_compass_follows_the_guide_when_no_map_is_held() -> void:
	var c := TreasureCompass.new()
	autofree(c)
	assert_eq(c.current_target(Vector3.ZERO), {}, "no map, no guide: nothing")
	c.guide = func(_from: Vector3) -> Dictionary: return {"chest": Vector3i(0, 40, 160)}
	assert_eq(c.current_target(Vector3.ZERO), {"chest": Vector3i(0, 40, 160)})
	assert_true(c.guided(), "it shows for the guide")


func test_the_landing_card_lists_the_places_and_fits_a_phone() -> void:
	var list := PlanetGuideRules.checklist(SIGHTS, NAMES, {"sight:cliff": true}, Vector3.ZERO)
	var card := PlanetGuideCard.new("Mercury", list)
	add_child_autofree(card)
	await wait_frames(2)
	assert_eq(card.lines.size(), 3)
	assert_string_contains(card.lines[1].text, "(found!)", "the long cliff is found")
	assert_string_contains(card.lines[0].text, "The thermometer")
	var need := card.get_combined_minimum_size()
	assert_lte(need.x, 1240.0, "width %s" % need)
	assert_lte(need.y, 700.0, "height %s" % need)
	card.go_button.pressed.emit()
	assert_false(card.visible)
