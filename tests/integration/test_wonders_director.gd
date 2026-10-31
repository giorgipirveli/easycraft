extends GutTest
## Owner #78 (spec §24): the tour in world 41 for this game's own player (WondersDirector): every wonder on MY MAP from
## the landing (and the landing spot); walking up to a wonder, into it or onto it says its real fact once per world
## (WonderSights), stamps the Wonders Passport the first time (then how many, and which is next); the explorer's card
## lists the seven; the compass points to the nearest wonder not reached; the names float over the signposts and
## plaques; a plaque's tap opens the wonder's card, and QUIZ (once stamped) asks its questions, a right first answer
## paying once.

var director: WondersDirector
var at := Vector3.INF
var said: Array[String] = []
var marks: Array[Dictionary] = []
var paid: Array[int] = []
var book := WonderData.new()
var clock := DayCycle.NOON


func before_each() -> void:
	said.clear()
	marks.clear()
	paid.clear()
	book = WonderData.new()
	at = Vector3.INF
	director = WondersDirector.new()
	director.auto_tick = false
	director.found = {}
	director.player_position = func() -> Vector3: return at
	director.toast = func(text: String, _s: float) -> void: said.append(text)
	director.mark = func(entry: Dictionary) -> void: marks.append(entry)
	director.pay = func(gold: int) -> void: paid.append(gold)
	director.data = func() -> WonderData: return book
	director.save = func() -> void: pass
	add_child_autofree(director)
	director.setup()


func after_each() -> void:
	UniverseRegistry.reset()


func _go(id: StringName, local: Vector3i) -> void:
	var q := WonderTour.to_world(id, Vector2i(local.x, local.z))
	at = Vector3(q.x + 0.5, WonderTour.BASE_Y + local.y, q.y + 0.5)


func test_every_wonder_and_the_landing_spot_are_on_my_map() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	for id in WonderTour.ids():
		assert_has(ids, "sight_" + String(id))
	assert_has(ids, WondersDirector.LANDING_ID)
	var pyramid: Dictionary = marks[ids.find("sight_pyramid")]
	assert_eq(pyramid.name, "Great Pyramid of Giza")
	assert_eq(pyramid.kind, &"sight")


func test_reaching_a_wonder_says_its_fact_once_and_stamps_the_passport() -> void:
	_go(&"pyramid", Vector3i(0, 0, -40))
	director.sights.tick()
	assert_true(said.is_empty(), "far in front of it: nothing yet")
	_go(&"pyramid", Vector3i(0, 0, -24))
	director.sights.tick()
	assert_eq(said.size(), 1, "at its foot")
	assert_string_contains(said[0], "only one of the Seven Ancient Wonders still standing")
	assert_true(director.found.has("sight:pyramid"))
	assert_true(book.stamped(&"pyramid"), "the passport's stamp")
	director.sights.tick()
	_go(&"pyramid", Vector3i(0, 11, 5))   # in the King's Chamber
	director.sights.tick()
	assert_eq(said.size(), 1, "once per world")


func test_climbing_or_walking_into_each_wonder_counts() -> void:
	var inside := {&"gardens": Vector3i(0, 16, 0), &"artemis": Vector3i(0, 3, 0), &"zeus": Vector3i(-5, 10, 0),
		&"mausoleum": Vector3i(0, 9, 0), &"colossus": Vector3i(0, 7, -3), &"lighthouse": Vector3i(0, WonderBuilds.LIGHTHOUSE_TOP, 1)}
	for id: StringName in inside:
		_go(id, inside[id])
		director.sights.tick()
		assert_true(director.found.has("sight:" + String(id)), "%s reached at %s" % [id, at])
		assert_true(book.stamped(id))
	assert_eq(said.size(), inside.size())
	assert_string_contains(said[0], "no one knows for sure")


func test_the_explorers_card_and_the_compass() -> void:
	var card := director.guide_card()
	add_child_autofree(card)
	assert_eq(card.lines.size(), 21, "every tour's wonders listed")
	var text := ReadAloud.words_of(card)
	assert_string_contains(text, "EXPLORE THE WONDERS OF THE WORLD")
	assert_string_contains(text, "only the Great Pyramid still stands")
	assert_string_contains(text, "The New Seven Wonders", "the second tour's heading")
	assert_string_contains(text, "The Seven Natural Wonders", "the third tour's heading")
	assert_string_contains(text, "Nature Trail")
	var longest := 0
	for l in card.lines:
		longest = maxi(longest, l.text.length())
	assert_lte(longest, 32, "short names: three columns fit a phone's screen")
	var near := director.compass_target(Vector3.ZERO)
	assert_false(near.is_empty())
	var first := PlanetGuideRules.next(director.checklist(Vector3.ZERO), Vector3.ZERO)
	assert_eq(near.chest, Vector3i(first.pos))
	for id in WonderTour.ids():
		director.found["sight:" + String(id)] = true
	assert_eq(director.compass_target(Vector3.ZERO), {}, "all reached: no arrow")


func test_names_float_over_the_signposts_and_plaques() -> void:
	assert_eq(director.labels.size(), 21 * 2 + 3 + 2 + 2,
		"every signpost and plaque, the tours' plaques, the Wonders Road's and the Nature Trail's signs")
	var texts: Array = director.labels.map(func(l: Label3D) -> String: return l.text)
	assert_has(texts, "Great Pyramid of Giza")
	assert_has(texts, WonderFacts.TOUR_TITLE)
	assert_has(texts, WonderFacts.NATURE_TOUR_TITLE)
	assert_has(texts, "The Seven Natural Wonders (Nature Trail)", "the trail's sign on the landing square")
	assert_has(texts, "The Seven Ancient Wonders (Nature Trail)", "and on the nature square")
	assert_has(texts, "The New Seven Wonders (Wonders Road)")
	for l in director.labels:
		assert_eq(l.billboard, BaseMaterial3D.BILLBOARD_ENABLED, "the traders' look (one material)")
	var spawn := Vector3(0.5, WonderTour.BASE_Y + 1.6, 0.5)
	var drawn := director.labels.filter(func(l: Label3D) -> bool:
		return l.visibility_range_end <= 0.0 or l.position.distance_to(spawn) < l.visibility_range_end)
	assert_lte(drawn.size(), 10, "from the landing spot only the square's own names show (the spawn view stays light)")
	for id in WonderTour.ids():
		var p := Vector3(WonderTour.plaque(id))
		assert_gt(p.distance_to(spawn), WondersDirector.PLAQUE_LABEL_RANGE, "%s's plaque name is hidden from the landing spot" % id)


func test_the_compass_asks_nothing_heavy_every_frame() -> void:
	var here := Vector3(-200, WonderTour.BASE_Y, 3)
	var want := PlanetGuideRules.next(director.checklist(here), here)
	assert_eq(director.compass_target(here), {"chest": Vector3i(want.pos)}, "the nearest wonder not reached")
	director.found["sight:" + String(want.id)] = true
	var next := PlanetGuideRules.next(director.checklist(here), here)
	assert_eq(director.compass_target(here), {"chest": Vector3i(next.pos)}, "then the next")


func test_a_plaque_opens_its_wonders_card_and_its_quiz_pays_once() -> void:
	assert_false(director.open_plaque(Vector3i(1, 2, 3)), "no plaque there")
	assert_true(director.open_plaque(WonderTour.plaque(&"colossus")))
	var card := director.card
	add_child_autofree(card)
	assert_string_contains(ReadAloud.words_of(card), "Colossus of Rhodes")
	assert_string_contains(card.facts.text, "33 m")
	assert_false(card.quiz_button.visible, "visit it first")
	book.stamp(&"colossus")
	director.open_plaque(WonderTour.plaque(&"colossus"))
	card = director.card
	add_child_autofree(card)
	assert_true(card.quiz_button.visible)
	card.quiz_button.pressed.emit()
	assert_true(card.quiz.visible)
	assert_false(card.facts.visible)
	var q: Dictionary = WondersPassportRules.questions(&"colossus")[0]
	card.quiz.pick(int(q.right))
	assert_eq(paid, [EarnRules.FACT_QUIZ_GOLD], "right the first time: paid")
	card.quiz.next_button.pressed.emit()
	card.quiz.pick(0 if int(WondersPassportRules.questions(&"colossus")[1].right) != 0 else 1)
	assert_eq(paid.size(), 1, "a wrong answer pays nothing")
	card.quiz.next_button.pressed.emit()
	assert_false(card.visible, "DONE closes the card")


func test_the_third_tour_on_my_map_its_wonders_reached_and_its_plaques_cards() -> void:
	var ids: Array = marks.map(func(m: Dictionary) -> String: return str(m.id))
	assert_has(ids, WondersDirector.NATURE_SQUARE_ID, "MY MAP marks the nature square")
	var reach := {&"grand_canyon": Vector3i(0, 12, -30), &"barrier_reef": Vector3i(0, -6, -20),
		&"rio_harbour": Vector3i(-18, 0, -22), &"everest": Vector3i(28, 0, -68), &"northern_lights": Vector3i(0, 1, -5),
		&"paricutin": Vector3i(0, 0, -40), &"victoria_falls": Vector3i(0, 0, -6)}
	for id: StringName in reach:
		_go(id, reach[id])
		director.sights.tick()
		assert_true(director.found.has("sight:" + String(id)), "%s reached at %s" % [id, at])
		assert_true(book.stamped(id))
	assert_string_contains(said[0], "Colorado River")
	assert_true(director.open_plaque(WonderTour.plaque(&"paricutin")))
	var card := director.card
	add_child_autofree(card)
	var text := ReadAloud.words_of(card)
	assert_string_contains(text, "born in 1943")
	assert_string_contains(text, "Quiet since 1952")
	assert_true(card.quiz_button.visible, "stamped: its quiz")
	assert_true(director.open_plaque(WonderTour.tour_plaque(&"nature")))
	card = director.card
	add_child_autofree(card)
	assert_string_contains(ReadAloud.words_of(card), "1997", "the nature square's plaque tells the tour")


func test_the_northern_lights_shine_on_dark_nights_near_the_valley_and_a_rainbow_by_day_at_the_falls() -> void:
	var sky := director.nature_sky
	assert_not_null(sky)
	sky.sky_time = func() -> float: return clock
	var valley := WonderTour.WONDERS[&"northern_lights"].centre as Vector2i
	at = Vector3(valley.x, WonderTour.BASE_Y, valley.y)
	clock = DayCycle.NOON
	sky.look()
	assert_false(sky.aurora.visible, "not by day: the sky must be dark to see them")
	clock = DayCycle.MIDNIGHT
	sky.look()
	assert_true(sky.aurora.visible, "at night, over the valley")
	assert_eq(sky.curtains.size(), NatureSky.CURTAINS.size())
	at = Vector3(0, WonderTour.BASE_Y, 0)
	sky.look()
	assert_false(sky.aurora.visible, "never drawn from the landing spot (its view stays light)")
	var falls := WonderTour.WONDERS[&"victoria_falls"].centre as Vector2i
	at = Vector3(falls.x, WonderTour.BASE_Y, falls.y - 6)
	clock = DayCycle.NOON
	sky.look()
	assert_true(sky.rainbow.visible, "a rainbow in the spray by day")
	clock = DayCycle.MIDNIGHT
	sky.look()
	assert_false(sky.rainbow.visible, "not at night")
	for m: MeshInstance3D in sky.curtains + [sky.rainbow]:
		var mat := (m.mesh as ArrayMesh).surface_get_material(0) as StandardMaterial3D
		assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "the night sky's settings: no new shader")
		assert_true(mat.vertex_color_use_as_albedo and mat.disable_fog)
		assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
		assert_eq(m.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var top := sky.aurora.position.y
	assert_gt(top, WonderTour.BASE_Y + NatureGround.EVEREST_TOP, "high over everything")


func test_the_tour_plaque_tells_the_tour() -> void:
	assert_true(director.open_plaque(WonderTour.tour_plaque()))
	var card := director.card
	add_child_autofree(card)
	var text := ReadAloud.words_of(card)
	assert_string_contains(text, WonderFacts.TOUR_TITLE)
	assert_string_contains(text, "No one knows for sure the Hanging Gardens")
	assert_false(card.quiz_button.visible)


func test_the_passport_page_shows_stamps_and_its_quiz() -> void:
	var page := WondersPassportPage.new()
	page.data = func() -> WonderData: return book
	add_child_autofree(page)
	assert_eq(page.tiles().size(), 21)
	assert_eq(page.tile_words(0), "???")
	assert_false(page.tile_stamped(0))
	book.stamp(&"pyramid")
	page.refresh()
	assert_eq(page.tile_words(0), "Great Pyramid")
	assert_true(page.tile_stamped(0))
	assert_eq(page.count_label.text, "1 of 21 stamps")
	assert_eq(page.heading(&"ancient"), "The Seven Ancient Wonders · 1 of 7")
	assert_eq(page.heading(&"new"), "The New Seven Wonders · 0 of 7")
	assert_eq(page.heading(&"nature"), "The Seven Natural Wonders · 0 of 7")
	var everest := WonderFacts.ORDER.find(&"everest")
	page.tiles()[everest].pressed.emit()
	assert_string_contains(page.detail_where.text, "pushed up over millions of years", "how nature made it")
	assert_string_contains(page.detail_where.text, "A wonder of nature")
	assert_string_contains(page.detail_facts.text, "Nature Trail", "where to get its stamp")
	page.close_card()
	page.tiles()[0].pressed.emit()
	assert_string_contains(page.detail_facts.text, "Khufu")
	assert_string_contains(page.detail_where.text, "Still standing")
	assert_true(page.quiz_button.visible)
	var paid_before := Profile.data.survivor_gold
	page.quiz.pay = func(gold: int) -> void: paid.append(gold)
	page.quiz.save = func() -> void: pass
	page.quiz_button.pressed.emit()
	page.quiz.pick(int(WondersPassportRules.questions(&"pyramid")[0].right))
	assert_eq(paid, [EarnRules.FACT_QUIZ_GOLD])
	assert_eq(Profile.data.survivor_gold, paid_before, "the test's own wallet, never the real profile")
	page.tiles()[1].pressed.emit()
	assert_string_contains(page.detail_facts.text, "Star Map", "where to get the gardens' stamp")
	assert_false(page.quiz_button.visible)
	page.close_card()
	assert_false(page.is_queued_for_deletion())
