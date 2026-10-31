extends GutTest
## Prospecting on the Moon and Mars (spec §26.5; ProspectDirector in a space world): Gemma's space camp by the landing
## pad (a spacesuit, a little habitat; never on the colony's ground), her board telling the planet's own five quests,
## a whole quest from START to MARK IT (the rim, down into the crater, the ice; the find's card follows the ice to
## hydrogen fuel, gold for a rocket's tanks), MY MAP's picture, the compass's quest target for the planet guide, and the map's colours of the
## planet.

var director: ProspectDirector
var ui: Control
var toasts: Array[String] = []
var marks: Array[Dictionary] = []
var paid: Array[int] = []
var feet := Vector3.INF
var meta: WorldMeta
var data: ProspectData
var shape: SpaceShape


func _make(universe: int) -> void:
	toasts.clear()
	marks.clear()
	paid.clear()
	feet = Vector3.INF
	meta = WorldMeta.new()
	data = ProspectData.new()
	shape = SpaceShape.new(12345, SpaceShape.MARS if universe == SpaceRules.MARS else SpaceShape.MOON)
	var rules := DepositRules.for_world(12345, shape, SpaceSecretRules.new(12345, shape))
	ui = Control.new()
	add_child_autofree(ui)
	director = ProspectDirector.new()
	director.universe = universe
	director.search_later = false
	director.auto_tick = false
	director.player_position = func() -> Vector3: return feet
	director.toast = func(t: String) -> void: toasts.append(t)
	director.mark_map = func(e: Dictionary) -> void: marks.append(e)
	director.pay = func(g: int) -> void: paid.append(g)
	director.save_profile = func() -> void: pass
	director.today = func() -> int: return 20400
	director.has_detector = func() -> bool: return false
	director.has_ice_finder = func() -> bool: return false
	director.beep = func() -> void: pass
	add_child_autofree(director)
	director.setup(shape, rules, meta, data, ui, Vector3.INF)
	await wait_process_frames(1)


func test_gemmas_space_camp_stands_by_the_landing_off_the_colony() -> void:
	for u: int in [SpaceRules.MOON, SpaceRules.MARS]:
		await _make(u)
		assert_true(director.camp_at.is_finite(), "%d: the camp stands" % u)
		var sp := shape.spawn_column()
		var d := Vector2(director.camp_at.x - sp.x, director.camp_at.z - sp.y).length()
		assert_between(d, 20.0, 28.0, "%d: a short walk from the landing pad (%.1f)" % [u, d])
		assert_false(shape.colony.covers(floori(director.camp_at.x), floori(director.camp_at.z), 4), "%d: off the colony" % u)
		var landmark: Dictionary = SpaceSecretRules.new(12345, shape).landmark()
		assert_gt(Vector2(director.camp_at.x - landmark.anchor.x, director.camp_at.z - landmark.anchor.z).length(), 7.0,
			"%d: clear of the landmark" % u)
		var aliens := ProspectCamp.alien_camp(12345, shape, landmark)
		assert_false(aliens.is_empty(), "%d: the aliens camp here" % u)
		assert_gt(Vector2(director.camp_at.x - aliens.pos.x, director.camp_at.z - aliens.pos.z).length(), 11.0,
			"%d: clear of the aliens' camp" % u)
		var theater := TheaterSite.pick_for(shape)
		if not theater.is_empty():
			var t: Vector3i = theater.pos
			assert_gt(Vector2(director.camp_at.x - t.x, director.camp_at.z - t.z).length(), 11.0, "%d: clear of the Theater" % u)
		assert_true(director.camp.space, "%d: Gemma wears her spacesuit" % u)
		assert_eq(director.camp.bubble.text, "!", "a quest waits")
		feet = director.camp_at + Vector3(1.5, 0, 1.0)
		director.tick()
		assert_true(director.board.visible, "walking up to Gemma opens her board")
		assert_eq(director.board.title_label.text, "Gemma the space geologist")
		director.board.close()


func test_each_planets_board_tells_its_own_quests() -> void:
	await _make(SpaceRules.MOON)
	var cards := director.quest_cards()
	assert_eq(cards.map(func(c: Dictionary) -> StringName: return c.kind), [DepositKinds.MOON_ICE, DepositKinds.ILMENITE,
		DepositKinds.HELIUM_3, DepositKinds.KREEP, DepositKinds.MOON_METEORITE])
	assert_true(cards.all(func(c: Dictionary) -> bool: return bool(c.here)), "all told here")
	director.board.open_quests()
	assert_eq(director.board.cards.size(), 5)
	assert_string_contains(director.board.words(), "Moon")
	await _make(SpaceRules.MARS)
	assert_eq(director.quest_cards().map(func(c: Dictionary) -> StringName: return c.kind), [DepositKinds.MARS_ICE,
		DepositKinds.HEMATITE, DepositKinds.DARK_SAND, DepositKinds.MARS_SALT, DepositKinds.MARS_METEORITE])
	assert_false(director.start(DepositKinds.MOON_ICE), "the Moon's quest is the Moon's")


func test_a_whole_moon_ice_quest() -> void:
	await _make(SpaceRules.MOON)
	assert_true(director.start(DepositKinds.MOON_ICE))
	var d := director.deposit_of(DepositKinds.MOON_ICE)
	assert_false(d.is_empty())
	var guard := 0
	var walked: Array[int] = []
	while director.state.has_quest(DepositKinds.MOON_ICE) and guard < 20:
		guard += 1
		var s := director.current_step(DepositKinds.MOON_ICE)
		match s.type:
			ProspectQuests.REACH, ProspectQuests.SIGN:
				var target := ProspectQuests.target(s, d)
				assert_eq(director.quest_target(Vector3.ZERO), {"chest": Vector3i(target.floor())}, "the compass points there")
				walked.append(int(s.spot))
				feet = target + Vector3(0.8, 0.5, 0.8)
				director.tick()
			ProspectQuests.MARK:
				assert_eq(director.mark(DepositKinds.MOON_ICE), EarnRules.PROSPECT_QUEST_GOLD)
			_:
				director.answered(DepositKinds.MOON_ICE, director.state.step_of(DepositKinds.MOON_ICE))
	assert_lt(guard, 20)
	assert_eq(walked, [0, 1] as Array[int], "the rim, then down into the crater")
	assert_eq(paid, [EarnRules.PROSPECT_QUEST_GOLD], "paid once")
	assert_true(data.has_done(DepositKinds.MOON_ICE))
	assert_eq(marks.size(), 1)
	assert_eq(marks[0].kind, &"deposit_moon_ice")
	assert_true(WorldMapPanel.knows_picture(marks[0].kind), "MY MAP draws the ice crater")
	assert_true(toasts.any(func(t: String) -> bool: return t.contains("crashed into a dark crater")), "the sign's fact")
	assert_eq(director.board.view, ProspectBoard.DONE)
	var said := ""
	for l: Label in director.board.find_children("*", "Label", true, false):
		said += l.text + "\n"
	assert_string_contains(said, "Hydrogen Fuel", "the find's card follows the ice to rocket fuel")
	assert_eq(director.quest_target(Vector3.ZERO), {}, "nothing to point at now")


## Every space kind has its picture on the board and on MY MAP.
func test_every_space_kind_has_a_picture() -> void:
	for kind in DepositKinds.ALL:
		assert_true(ProspectPictures.knows(ProspectPictures.map_kind(kind)), str(kind))
		var c := Control.new()
		add_child_autofree(c)
		c.draw.connect(func() -> void: assert_true(ProspectPictures.draw(c, kind, Rect2(0, 0, 40, 40)), str(kind)))
		c.queue_redraw()
	await wait_process_frames(2)


## The quest map is the planet seen from above: the Moon grey, darker in its craters' bowls; Mars red, its caps white.
func test_the_map_colours_the_planet() -> void:
	var moon := SpaceShape.new(12345, SpaceShape.MOON)
	var sp := moon.spawn_column()
	var plain := ProspectMap.terrain_colour(moon, sp.x + 300.5, sp.y + 300.5)
	assert_lt(plain.s, 0.15, "the Moon is grey (%s)" % plain)
	var bowl := Vector2i.ZERO
	for cz in range(0, 20):
		var c := moon.crater_in_cell(Vector2i(3, cz))
		if not c.is_empty() and float(c.radius) >= 10.0:
			bowl = c.center
			break
	if bowl != Vector2i.ZERO:
		var in_bowl := ProspectMap.terrain_colour(moon, bowl.x + 0.5, bowl.y + 0.5)
		var rim := ProspectMap.terrain_colour(moon, bowl.x + 60.5, bowl.y + 0.5)
		assert_lt(in_bowl.v, rim.v, "a crater's bowl is darker")
	var mars := SpaceShape.new(12345, SpaceShape.MARS)
	var m := mars.spawn_column()
	var red := ProspectMap.terrain_colour(mars, m.x + 300.5, m.y + 0.5)
	assert_gt(red.r, red.b + 0.2, "Mars is red (%s)" % red)
	var cap := ProspectMap.terrain_colour(mars, m.x + 0.5, mars.mars.north_edge() - 100.5)
	assert_gt(cap.v, 0.85, "its cap is white (%s)" % cap)
	assert_lt(cap.s, 0.2)
