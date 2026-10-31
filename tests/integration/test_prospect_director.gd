extends GutTest
## Prospecting in a played world (spec §26; ProspectDirector): Gemma's camp by the spawn (her board opens when a child
## walks up), a quest from START to MARK IT (the map, the walk the compass points along, the sign found up close, the
## problem, the quiz), its gold paid once (then a little for each later find), the deposit on MY MAP and in the world's
## save, an oil well whose pump jack fills a Survivor bag's drums, the Metal Detector's beeps, a LAN guest who only looks.

var director: ProspectDirector
var ui: Control
var toasts: Array[String] = []
var marks: Array[Dictionary] = []
var paid: Array[int] = []
var bag := {}
var feet := Vector3.INF
var meta: WorldMeta
var data: ProspectData


func _make(universe: int, host := true, survivor := false) -> void:
	toasts.clear()
	marks.clear()
	paid.clear()
	bag.clear()
	feet = Vector3.INF
	meta = WorldMeta.new()
	data = ProspectData.new()
	var shape: MeadowsShape = DesertShape.new(12345) if universe == 2 else MeadowsBiomeShape.new(12345)
	var secrets: SecretRules = DesertSecretRules.new(12345, shape) if universe == 2 else SecretRules.new(12345, shape)
	var rules := DepositRules.for_world(12345, shape, secrets)
	ui = Control.new()
	add_child_autofree(ui)
	director = ProspectDirector.new()
	director.universe = universe
	director.host = host
	director.survivor = survivor
	director.search_later = false
	director.auto_tick = false
	director.player_position = func() -> Vector3: return feet
	director.toast = func(t: String) -> void: toasts.append(t)
	director.mark_map = func(e: Dictionary) -> void: marks.append(e)
	director.pay = func(g: int) -> void: paid.append(g)
	director.give = func(id: int, n: int) -> bool:
		bag[id] = int(bag.get(id, 0)) + n
		return true
	director.save_profile = func() -> void: pass
	director.today = func() -> int: return 20400
	director.has_detector = func() -> bool: return false
	director.beep = func() -> void: pass
	add_child_autofree(director)
	director.setup(shape, rules, meta, data, ui, Vector3.INF)
	await wait_process_frames(1)


func test_gemmas_camp_stands_by_the_spawn() -> void:
	await _make(1)
	assert_true(director.camp_at.is_finite(), "the camp stands")
	var sp := director.deposits.spawn
	var d := Vector2(director.camp_at.x - sp.x, director.camp_at.z - sp.y).length()
	assert_between(d, 20.0, 28.0, "a short walk from the spawn (%.1f)" % d)
	assert_not_null(director.camp)
	assert_eq(director.camp.bubble.text, "!", "a quest waits")
	var again := ProspectCamp.spot_for_world(12345, director.shape, sp, 1, Vector3.INF)
	assert_eq(again.pos, director.camp_at, "the same place for the same seed")
	feet = director.camp_at + Vector3(1.5, 0, 1.0)
	director.tick()
	assert_true(director.board.visible, "walking up to Gemma opens her board")
	assert_eq(director.board.view, ProspectBoard.QUESTS)
	director.board.close()
	director.tick()
	assert_false(director.board.visible, "after X it stays closed while the child stays")
	feet = director.camp_at + Vector3(12, 0, 0)
	director.tick()
	feet = director.camp_at + Vector3(1, 0, 1)
	director.tick()
	assert_true(director.board.visible, "walking away and back opens it again")


func test_a_whole_gold_quest() -> void:
	await _make(1)
	var cards := director.quest_cards()
	assert_eq(cards.size(), 6)
	assert_eq(cards.slice(0, 3).map(func(c: Dictionary) -> StringName: return c.kind),
		[DepositKinds.GOLD, DepositKinds.IRON, DepositKinds.COAL], "this world's quests first")
	assert_true(director.start(DepositKinds.GOLD))
	assert_eq(director.state.active, DepositKinds.GOLD)
	assert_true(director.board.visible)
	assert_eq(director.board.view, ProspectBoard.STEP)
	var d := director.deposit_of(DepositKinds.GOLD)
	assert_false(d.is_empty())
	var steps := director.steps_of(DepositKinds.GOLD)
	var guard := 0
	while director.state.has_quest(DepositKinds.GOLD) and guard < 20:
		guard += 1
		var s := director.current_step(DepositKinds.GOLD)
		match s.type:
			ProspectQuests.REACH, ProspectQuests.SIGN:
				var target := ProspectQuests.target(s, d)
				assert_eq(director.compass_target(Vector3.ZERO), {"chest": Vector3i(target.floor())}, "the compass points there")
				feet = target + Vector3(40, 0, 0)
				assert_false(director.arrive_check(feet), "not there yet")
				feet = target + Vector3(1.0, 0.5, 1.0)
				director.tick()
			ProspectQuests.MARK:
				assert_eq(director.mark(DepositKinds.GOLD), EarnRules.PROSPECT_QUEST_GOLD)
			_:
				director.answered(DepositKinds.GOLD, director.state.step_of(DepositKinds.GOLD))
	assert_lt(guard, 20)
	assert_false(director.state.has_quest(DepositKinds.GOLD), "the quest is done")
	assert_true(director.state.is_found(d.id))
	assert_eq(paid, [EarnRules.PROSPECT_QUEST_GOLD], "paid once")
	assert_true(data.has_done(DepositKinds.GOLD))
	assert_eq(marks.size(), 1)
	assert_eq(marks[0].id, "deposit_" + d.id)
	assert_eq(marks[0].kind, &"deposit_gold")
	assert_true(WorldMapPanel.knows_picture(marks[0].kind), "MY MAP draws a nugget for it")
	assert_eq(ProspectState.from_dict(meta.prospect).found, [d.id] as Array[String], "the world's save keeps the find")
	assert_true(toasts.any(func(t: String) -> bool: return t.contains("heavier than water")), "the sign's fact")
	assert_eq(director.board.view, ProspectBoard.DONE)
	assert_eq(director.compass_target(Vector3.ZERO), {}, "nothing to point at now")
	assert_eq(steps.size(), 7)
	# The same quest again leads farther on and pays a little.
	assert_true(director.start(DepositKinds.GOLD))
	var next := director.deposit_of(DepositKinds.GOLD)
	assert_ne(next.id, d.id, "the next gold is another deposit")


func test_the_world_save_brings_the_finds_back() -> void:
	await _make(1)
	director.start(DepositKinds.COAL)
	var d := director.deposit_of(DepositKinds.COAL)
	director.state.quests["coal"].step = director.steps_of(DepositKinds.COAL).size() - 1
	director.mark(DepositKinds.COAL)
	var saved := meta.to_json()
	var meta2 := WorldMeta.from_json(saved)
	var again := ProspectDirector.new()
	again.search_later = false
	again.auto_tick = false
	var marks2: Array[Dictionary] = []
	again.mark_map = func(e: Dictionary) -> void: marks2.append(e)
	add_child_autofree(again)
	again.setup(director.shape, director.deposits, meta2, ProspectData.new(), null)
	assert_eq(marks2.size(), 1, "MY MAP shows the find in the next game")
	assert_eq(marks2[0].id, "deposit_" + d.id)


func test_an_oil_quest_stands_a_well_that_fills_a_survivor_bag() -> void:
	await _make(2, true, true)
	assert_true(director.start(DepositKinds.OIL))
	var d := director.deposit_of(DepositKinds.OIL)
	director.state.quests["oil"].step = director.steps_of(DepositKinds.OIL).size() - 1
	director.mark(DepositKinds.OIL)
	assert_true(director.wells.has(d.id), "an oil well stands on the dome")
	var well: OilWell = director.wells[d.id]
	feet = well.position + OilWell.JACK_AT + Vector3(1, 0, 0)
	director.tick()
	assert_eq(bag.get(BlockIds.CRUDE_OIL, 0), 1, "walking up to the pump jack pumps a drum")
	director.tick()
	assert_eq(bag.get(BlockIds.CRUDE_OIL, 0), 1, "one drum each time the child walks up")
	feet = Vector3.INF
	director.tick()
	feet = well.position + OilWell.JACK_AT
	director.tick()
	assert_eq(bag.get(BlockIds.CRUDE_OIL, 0), 2)
	assert_eq(director.state.drums_left(d.id), DepositRules.OIL_DRUMS - 2)
	assert_true(ProspectState.from_dict(meta.prospect).drums_left(d.id) == DepositRules.OIL_DRUMS - 2, "saved")


func test_the_sandbox_well_only_shows_how_it_works() -> void:
	await _make(2, true, false)
	director.start(DepositKinds.OIL)
	director.state.quests["oil"].step = director.steps_of(DepositKinds.OIL).size() - 1
	director.mark(DepositKinds.OIL)
	var id: String = director.wells.keys()[0]
	assert_false(director.pump(id))
	assert_true(bag.is_empty())
	assert_true(toasts.any(func(t: String) -> bool: return t.contains("Survivor")))


func test_a_quest_of_the_other_world_is_not_started_here() -> void:
	await _make(1)
	assert_false(director.start(DepositKinds.OIL), "oil is the desert's")
	assert_eq(director.state.active, &"")


func test_a_lan_guest_looks_but_prospects_at_home() -> void:
	await _make(1, false)
	assert_false(director.start(DepositKinds.GOLD))
	assert_true(toasts.any(func(t: String) -> bool: return t.contains("your own world")))
	assert_true(director.board.guest)
	assert_true(meta.prospect.is_empty(), "a guest never writes the host's save")


func test_the_metal_detector_hears_metal_near() -> void:
	await _make(1)
	var beeps := [0]
	director.beep = func() -> void: beeps[0] += 1
	director.has_detector = func() -> bool: return true
	var d := director.deposits.nearest(DepositKinds.IRON, director.camp_at)
	var sign: Vector3i = d.signs[0][0]
	feet = Vector3(sign) + Vector3(20, 1, 0)
	var m := ProspectGear.nearest_metal(director.deposits, feet)
	assert_false(m.is_empty(), "it hears the rusty rock's iron 20 m away")
	assert_eq(director.compass_target(feet), {"chest": Vector3i((m.pos as Vector3).floor())}, "the compass points to it")
	director._beep_step(1.0)
	assert_eq(beeps[0], 1)
	director._beep_step(0.1)
	assert_eq(beeps[0], 1, "at 20 m it beeps twice a second, not every frame")
	feet = Vector3(sign) + Vector3(200, 1, 0)
	assert_true(ProspectGear.nearest_metal(director.deposits, feet).is_empty(), "too far to hear")


func test_the_journal_opens_the_step_or_the_quests() -> void:
	await _make(1)
	director.open_journal()
	assert_eq(director.board.view, ProspectBoard.QUESTS)
	director.open_journal()
	assert_false(director.board.visible, "J again closes it")
	director.start(DepositKinds.IRON)
	director.board.close()
	director.open_journal()
	assert_eq(director.board.view, ProspectBoard.STEP)
	assert_eq(director.board.kind, DepositKinds.IRON)
	assert_true(InputMap.has_action("prospect"), "J (the input map's prospect)")
	assert_eq(KeysRules.key_text("prospect"), "J")
