extends Node
## The steps of tools/prospecting_space_smoke.gd (spec §26.5), on real terrain through the real systems: SpaceGenerator's
## deposits, the sandbox's ProspectDirector (Gemma's space camp found on a worker, her board, the quest's walking steps
## done by the player's feet, the planet guide's compass), the board's School exercises answered right, MY MAP, the
## world's save; in a Mars Survivor world the ground ice in the generated crater and living off the land at the
## machines through Session's crafting.

const TIMEOUT := 540.0
const SEED := 12345

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _scene: Node
var _gold_before := 0
var _deposit := {}
var _target := Vector3.INF
var _worst_ms := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: String in [ModeRules.slot(ModeRules.SANDBOX, SpaceRules.MOON), ModeRules.slot(ModeRules.SURVIVOR, SpaceRules.MARS)]:
		WorldSaves.delete(slot)
	Profile.data.prospect = ProspectData.new()
	Profile.data.survivor_gold = 500
	Profile.data.settings.keys_seen = true
	Profile.data.missions.fly(SpaceRules.MOON)   # on the route (tools/mission_smoke.gd flies a mission)
	Profile.data.missions.fly(SpaceRules.MARS)
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, SpaceRules.MOON)
	print("PROSPECT_SPACE_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if sandbox != _scene:
		_scene = sandbox
		_wait = 1.5   # a new world: let it settle
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var pd: ProspectDirector = sandbox.get("prospecting")
	match _step:
		0:
			_check(Game.slot() == ModeRules.slot(ModeRules.SANDBOX, SpaceRules.MOON), "a new Moon Sandbox world (%s)" % Game.slot())
			_check(pd != null and pd.deposits != null, "the Moon has prospecting and the generator's deposits")
			if pd == null:
				_finish()
				return
			_next(0.0)
		1:
			if not pd.camp_at.is_finite():
				if _step_t > 60.0:
					_check(false, "Gemma's space camp stands")
					_finish()
				return
			var sp := p.world.spawn_column()
			var shape := pd.shape as SpaceShape
			_check(true, "Gemma's space camp stands %.0f blocks from the landing pad (%.1f s)" % [Vector2(pd.camp_at.x - sp.x,
				pd.camp_at.z - sp.y).length(), _step_t])
			_check(not shape.colony.covers(floori(pd.camp_at.x), floori(pd.camp_at.z), 4), "off the colony's ground")
			_check(pd.camp != null and pd.camp.space, "Gemma wears her spacesuit")
			_check(pd.camp.bubble.visible and pd.camp.bubble.text == "!", "her bubble says a quest waits")
			_check(sandbox.dig_button != null, "DIG in MORE")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.spawn_at(pd.camp_at + Vector3(1.5, 0.2, -1.0))
			_next(0.5)
		2:
			if not pd.board.visible:
				if _step_t > 10.0:
					_check(false, "walking up to Gemma opens her board")
					_finish()
				return
			_check(pd.board.view == ProspectBoard.QUESTS, "her quests' cards")
			_check(pd.board.title_label.text == "Gemma the space geologist", "Gemma the space geologist")
			_check(pd.board.cards.size() == 5, "a card for each of the Moon's riches (%d)" % pd.board.cards.size())
			var ice := pd.board.find_child("Quest_moon_ice", true, false) as Button
			_check(ice != null and not ice.disabled, "the ice quest can start here")
			ice.pressed.emit()
			_next(0.0)
		3:
			if pd.board.view != ProspectBoard.STEP:
				if _step_t > 30.0:
					_check(false, "the quest starts (its deposit found on a worker)")
					_finish()
				return
			_deposit = pd.deposit_of(DepositKinds.MOON_ICE)
			var a: Vector3i = _deposit.get("anchor", Vector3i.ZERO)
			_check(not _deposit.is_empty(), "the quest leads to %s, %.0f m from the camp (%.1f s)" % [_deposit.get("id"),
				Vector2(a.x - pd.camp_at.x, a.z - pd.camp_at.z).length(), _step_t])
			var t0 := Time.get_ticks_usec()
			var map := pd.board.exercise.find_child("QuestMap", true, false) if pd.board.exercise else null
			_check(map != null, "the map step shows the Moon's map (%.1f ms to draw the step)" % ((Time.get_ticks_usec() - t0) / 1000.0))
			_answer(pd.board.exercise)
			_next(0.3)
		4:
			var s := pd.current_step(DepositKinds.MOON_ICE)
			_check(s.get("type") == ProspectQuests.REACH, "next: walk to the crater's rim (%s)" % s.get("words"))
			_check(pd.board.action_button != null and pd.board.action_button.name == "LetsGo", "LET'S GO")
			pd.board.action_button.pressed.emit()
			_check(not pd.board.visible, "the board closes for the walk")
			var guide: Dictionary = sandbox.hud.compass.guide.call(p.global_position)
			_target = ProspectQuests.target(s, _deposit)
			_check(guide.get("chest") == Vector3i(_target.floor()), "the compass (the planet guide's) points to the rim")
			p.spawn_at(_target + Vector3(0, 3, 0))
			_next(0.0)
		5:
			_worst_ms = maxf(_worst_ms, get_process_delta_time() * 1000.0)
			var s := pd.current_step(DepositKinds.MOON_ICE)
			if s.get("type") != ProspectQuests.SIGN:
				if _step_t > 40.0:
					_check(false, "walking to the rim (%s)" % s.get("words"))
					_finish()
				return
			_check(true, "at the rim; next: %s" % s.get("words"))
			var cell: Vector3i = _deposit.signs[1][0]
			p.spawn_at(Vector3(cell) + Vector3(0.5, 1.5, 0.5))
			_next(0.0)
		6:
			_worst_ms = maxf(_worst_ms, get_process_delta_time() * 1000.0)
			var cell: Vector3i = _deposit.signs[1][0]
			if not p.world.is_editable(cell) or pd.current_step(DepositKinds.MOON_ICE).get("type") == ProspectQuests.SIGN:
				if _step_t > 40.0:
					_check(false, "down in the crater, the icy dust loads and is found")
					_finish()
				return
			_check(p.world.get_block(cell) == BlockIds.ICY_REGOLITH, "icy regolith in the generated crater's floor at %s (%s)" %
				[cell, BlockIds.display_name(p.world.get_block(cell))])
			var label: Variant = sandbox.hud.get("_toast_label")
			var said: String = (label as Label).text if label is Label else ""
			_check(said.contains("crashed into a dark crater"), "the ice is found: \"%s\"" % said.substr(0, 80))
			print("PROSPECT_SPACE_SMOKE worst frame while the crater's region loaded: %.1f ms (headless)" % _worst_ms)
			_next(0.0)
		7:
			if not pd.board.visible or pd.board.exercise == null:
				if _step_t > 10.0:
					_check(false, "the board opens on the problem")
					_finish()
				return
			_answer(pd.board.exercise)   # the problem, the clue, the quiz's three
			if pd.current_step(DepositKinds.MOON_ICE).get("type") == ProspectQuests.MARK:
				_check(true, "the problem, the clue and Gemma's quiz answered")
				_next(0.3)
		8:
			_gold_before = Profile.data.survivor_gold
			_check(pd.board.action_button != null and pd.board.action_button.name == "MarkIt", "MARK IT")
			pd.board.action_button.pressed.emit()
			_check(Profile.data.survivor_gold == _gold_before + EarnRules.PROSPECT_QUEST_GOLD, "+%d gold (%d -> %d)" %
				[EarnRules.PROSPECT_QUEST_GOLD, _gold_before, Profile.data.survivor_gold])
			_check(Profile.data.prospect.has_done(DepositKinds.MOON_ICE), "the profile keeps the quest done")
			var marks: Array = sandbox.places_director.marks
			_check(marks.any(func(m: Dictionary) -> bool: return m.id == "deposit_" + str(_deposit.id)), "MY MAP shows the ice crater")
			_check(ProspectState.from_dict(sandbox.meta.prospect).is_found(_deposit.id), "the world's save keeps the find")
			var said := ""
			for l: Label in pd.board.find_children("*", "Label", true, false):
				said += l.text + " "
			_check(pd.board.view == ProspectBoard.DONE and said.contains("Hydrogen Fuel"), "the find's card: ice to water to rocket fuel")
			pd.board.close()
			sandbox.save_world()
			Game.new_world_seed = SEED
			Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.COZY, SpaceRules.MARS)
			_next(0.0)
		9:
			if Game.slot() != ModeRules.slot(ModeRules.SURVIVOR, SpaceRules.MARS) or pd == null:
				if _step_t > 60.0:
					_check(false, "a Survivor world on Mars (%s)" % Game.slot())
					_finish()
				return
			_check(true, "a new Mars Survivor world")
			var cards := pd.quest_cards()
			_check(cards.size() == 5 and cards[0].kind == DepositKinds.MARS_ICE, "Mars tells its own five")
			_check(pd.start(DepositKinds.MARS_ICE), "the ice quest starts")
			_next(0.0)
		10:
			if not pd.state.has_quest(DepositKinds.MARS_ICE):
				if _step_t > 30.0:
					_check(false, "the ice quest finds its crater")
					_finish()
				return
			_deposit = pd.deposit_of(DepositKinds.MARS_ICE)
			pd.state.quests["mars_ice"].step = pd.steps_of(DepositKinds.MARS_ICE).size() - 1   # the walk is the Moon's test
			_gold_before = Profile.data.survivor_gold
			pd.mark(DepositKinds.MARS_ICE)
			_check(Profile.data.survivor_gold == _gold_before + EarnRules.PROSPECT_QUEST_GOLD, "the ice quest pays through the wallet")
			pd.board.close()
			var cell: Vector3i = _deposit.signs[1][0]
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			p.spawn_at(Vector3(cell) + Vector3(0.5, 1.5, 0.5))
			_next(0.5)
		11:
			var cell: Vector3i = _deposit.signs[1][0]
			if not p.world.is_editable(cell):
				if _step_t > 40.0:
					_check(false, "the crater's ground loads")
					_finish()
				return
			_check(p.world.get_block(cell) == BlockIds.GROUND_ICE, "bright ground ice in the generated crater at %s (%s)" %
				[cell, BlockIds.display_name(p.world.get_block(cell))])
			var bag := Session.inventory_of(p.peer_id)
			bag.add(BlockIds.GROUND_ICE, 4)
			bag.add(BlockIds.TITANIUM, 1)
			var at := Vector3i(p.global_position.floor())
			p.world.set_block(at + Vector3i(2, 0, 0), BlockIds.ICE_MELTER)
			p.world.set_block(at + Vector3i(-2, 0, 0), BlockIds.OXYGEN_MAKER)
			p.world.set_block(at + Vector3i(0, 0, 2), BlockIds.CRAFTING_TABLE)
			_next(0.3)
		12:
			var bag := Session.inventory_of(p.peer_id)
			var near := Session.craft_stations_near(p.eye_position(), CraftRules.REACH)
			_check(bool(near.get(Recipes.MELTER, false)) and bool(near.get(Recipes.OXYGEN_MAKER, false)),
				"the Ice Melter and the Oxygen Maker are near")
			var said := [""]
			Session.craft_done.connect(func(_ok: bool, text: String, _id: int, _n: int) -> void: said[0] = text)
			Session.request_craft(&"melt_mars_ice")
			Session.request_craft(&"melt_mars_ice")
			_check(bag.count(BlockIds.WATER_TANK) == 2, "melted: 2 water tanks (%s)" % said[0])
			Session.request_craft(&"split_fuel")
			_check(bag.count(BlockIds.HYDROGEN_FUEL) == 1, "split: hydrogen fuel (%s)" % said[0])
			_check(str(said[0]).contains("rocket fuel"), "the split's fact")
			var wallet := Wallet.new(Profile.data.survivor_gold)
			var r := ShopRules.sell(BlockIds.HYDROGEN_FUEL, 1, wallet, bag, Game.universe)
			_check(bool(r.ok) and int(r.gold) == RefiningRules.SELL[BlockIds.HYDROGEN_FUEL],
				"Tilly buys the fuel made on Mars (%d gold: for the next rocket's tanks)" % int(r.gold))
			r = ShopRules.sell(BlockIds.TITANIUM, 1, wallet, bag, Game.universe)
			_check(bool(r.ok) and int(r.gold) == RefiningRules.SELL[BlockIds.TITANIUM], "Tilly buys titanium (%d gold)" % int(r.gold))
			_finish()


## Answers the exercise on screen right, then NEXT.
func _answer(panel: ExercisePanel) -> void:
	if panel == null:
		_check(false, "an exercise is on the board")
		return
	var ex := panel.ex
	match str(ex.type):
		"choice":
			panel.answer_widget.choose(int(ex.answer))
		"truefalse":
			panel.answer_widget.choose(0 if bool(ex.answer) else 1)
		"number":
			for ch in str(ex.answer):
				panel.answer_widget.press(ch)
			panel.check_button.pressed.emit()
		"order":
			for i: int in ex.answer:
				panel.answer_widget.tap(i)
			panel.check_button.pressed.emit()
	_check(panel.state == ExercisePanel.RIGHT, "answered right: %s" % str(ex.prompt).substr(0, 60))
	panel.next_button.pressed.emit()


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("PROSPECT_SPACE_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("PROSPECT_SPACE_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
