extends Node
## The steps of tools/prospecting_smoke.gd (spec §26), on real terrain through the real systems: the generator's
## deposits, the sandbox's ProspectDirector (Gemma's camp found on a worker, her board, the quest's walking steps done by
## the player's feet), the board's School exercises answered right, MY MAP, the world's save; in a desert Survivor world
## the oil well's pump jack, a Refinery and Tilly.

const TIMEOUT := 480.0
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
var _last_view := &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: String in ["sandbox_1", "survivor_u2"]:
		WorldSaves.delete(slot)
	Profile.data.prospect = ProspectData.new()
	Profile.data.survivor_gold = 500
	Profile.data.settings.keys_seen = true
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("PROSPECT_SMOKE begin")


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
			_check(Game.slot() == "sandbox_1", "a new Green Meadows Sandbox world (%s)" % Game.slot())
			_check(pd != null and pd.deposits != null, "the world has prospecting and the generator's deposits")
			if pd == null:
				_finish()
				return
			_next(0.0)
		1:
			if not pd.camp_at.is_finite():
				if _step_t > 60.0:
					_check(false, "Gemma's camp stands")
					_finish()
				return
			var sp := p.world.spawn_column()
			_check(true, "Gemma's camp stands %.0f blocks from the spawn (%.1f s)" % [Vector2(pd.camp_at.x - sp.x,
				pd.camp_at.z - sp.y).length(), _step_t])
			_check(pd.camp != null and pd.camp.bubble.visible and pd.camp.bubble.text == "!", "her bubble says a quest waits")
			_check(sandbox.dig_button != null, "DIG in MORE")
			_check(InputMap.has_action("prospect"), "J opens the journal on a PC")
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
			_check(pd.board.cards.size() == 6, "a card for each resource (%d)" % pd.board.cards.size())
			var gold := pd.board.find_child("Quest_gold", true, false) as Button
			_check(gold != null and not gold.disabled, "the gold quest can start here")
			gold.pressed.emit()
			_next(0.0)
		3:
			if pd.board.view != ProspectBoard.STEP:
				if _step_t > 30.0:
					_check(false, "the quest starts (its deposit found on a worker)")
					_finish()
				return
			_deposit = pd.deposit_of(DepositKinds.GOLD)
			var a: Vector3i = _deposit.get("anchor", Vector3i.ZERO)
			_check(not _deposit.is_empty(), "the quest leads to %s, %.0f m from the camp (%.1f s)" % [_deposit.get("id"),
				Vector2(a.x - pd.camp_at.x, a.z - pd.camp_at.z).length(), _step_t])
			var map := pd.board.exercise.find_child("QuestMap", true, false) if pd.board.exercise else null
			_check(map != null, "the map step shows this world's map")
			_answer(pd.board.exercise)
			_next(0.3)
		4:
			var s := pd.current_step(DepositKinds.GOLD)
			_check(s.get("type") == ProspectQuests.REACH, "next: walk to the river (%s)" % s.get("words"))
			_check(pd.board.action_button != null and pd.board.action_button.name == "LetsGo", "LET'S GO")
			pd.board.action_button.pressed.emit()
			_check(not pd.board.visible, "the board closes for the walk")
			var guide: Dictionary = sandbox.hud.compass.guide.call(p.global_position)
			_target = ProspectQuests.target(s, _deposit)
			_check(guide.get("chest") == Vector3i(_target.floor()), "the compass points to the river's gravel")
			p.spawn_at(_target + Vector3(0, 3, 0))
			_next(0.0)
		5:
			var cell: Vector3i = _deposit.signs[0][0]
			if not p.world.is_editable(cell):
				if _step_t > 40.0:
					_check(false, "the river's ground loads")
					_finish()
				return
			_check(p.world.get_block(cell) == BlockIds.GOLD_GRAVEL, "gold gravel in the generated river bed at %s (%s)" %
				[cell, BlockIds.display_name(p.world.get_block(cell))])
			_next(0.0)
		6:
			if pd.current_step(DepositKinds.GOLD).get("type") != ProspectQuests.PROBLEM:
				if _step_t > 30.0:
					_check(false, "walking there finds the gravel (%s)" % pd.current_step(DepositKinds.GOLD).get("words"))
					_finish()
				return
			var label: Variant = sandbox.hud.get("_toast_label")
			var said: String = (label as Label).text if label is Label else ""
			_check(said.contains("heavier than water"), "the gravel is found: \"%s\"" % said.substr(0, 80))
			_next(0.0)
		7:
			if not pd.board.visible:
				if _step_t > 10.0:
					_check(false, "the board opens on the problem")
					_finish()
				return
			_check(pd.board.view == ProspectBoard.STEP and pd.board.exercise != null, "the flakes' problem on the board")
			_answer(pd.board.exercise)
			_next(0.3)
		8:
			var s := pd.current_step(DepositKinds.GOLD)
			_check(s.get("type") == ProspectQuests.SIGN and int(s.get("spot", -1)) == 1, "next: the quartz vein uphill")
			pd.board.close()
			var cell: Vector3i = _deposit.signs[1][0]
			p.spawn_at(Vector3(cell) + Vector3(0.5, 1.5, 0.5))
			_next(0.0)
		9:
			var cell: Vector3i = _deposit.signs[1][0]
			if not p.world.is_editable(cell) or pd.current_step(DepositKinds.GOLD).get("type") != ProspectQuests.QUIZ:
				if _step_t > 30.0:
					_check(false, "finding the vein (%s)" % pd.current_step(DepositKinds.GOLD).get("words"))
					_finish()
				return
			_check(p.world.get_block(cell) == BlockIds.GOLD_QUARTZ, "the white quartz stripe in the hill (%s)" %
				BlockIds.display_name(p.world.get_block(cell)))
			_next(0.5)
		10:
			if not pd.board.visible or pd.board.exercise == null:
				if _step_t > 10.0:
					_check(false, "the quiz opens")
					_finish()
				return
			_answer(pd.board.exercise)
			if pd.current_step(DepositKinds.GOLD).get("type") == ProspectQuests.MARK:
				_check(true, "Gemma's quiz answered")
				_next(0.3)
		11:
			_gold_before = Profile.data.survivor_gold
			_check(pd.board.action_button != null and pd.board.action_button.name == "MarkIt", "MARK IT")
			pd.board.action_button.pressed.emit()
			_check(Profile.data.survivor_gold == _gold_before + EarnRules.PROSPECT_QUEST_GOLD, "+%d gold (%d -> %d)" %
				[EarnRules.PROSPECT_QUEST_GOLD, _gold_before, Profile.data.survivor_gold])
			_check(Profile.data.prospect.has_done(DepositKinds.GOLD), "the profile keeps the quest done")
			var marks: Array = sandbox.places_director.marks
			_check(marks.any(func(m: Dictionary) -> bool: return m.id == "deposit_" + str(_deposit.id)), "MY MAP shows the gold vein")
			_check(sandbox.map_button.visible, "the MAP button shows")
			_check(ProspectState.from_dict(sandbox.meta.prospect).is_found(_deposit.id), "the world's save keeps the find")
			_check(pd.board.view == ProspectBoard.DONE, "the find's card: how it is dug and refined")
			pd.board.close()
			pd.open_journal()
			_check(pd.board.visible and pd.board.view == ProspectBoard.QUESTS, "the journal opens on the quests")
			pd.board.close()
			sandbox.save_world()
			Profile.data.universe_unlocked = maxi(Profile.data.universe_unlocked, 2)
			Game.new_world_seed = SEED
			Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.COZY, 2)
			_next(0.0)
		12:
			if Game.slot() != ModeRules.slot(ModeRules.SURVIVOR, 2) or pd == null:
				if _step_t > 60.0:
					_check(false, "a Survivor world in the desert (%s)" % Game.slot())
					_finish()
				return
			_check(true, "a new desert Survivor world")
			var cards := pd.quest_cards()
			_check(cards[0].kind == DepositKinds.COPPER and bool(cards[0].here), "the desert tells copper, oil and salt")
			_check(pd.start(DepositKinds.OIL), "the oil quest starts")
			_next(0.0)
		13:
			if not pd.state.has_quest(DepositKinds.OIL):
				if _step_t > 30.0:
					_check(false, "the oil quest finds its dome")
					_finish()
				return
			_deposit = pd.deposit_of(DepositKinds.OIL)
			pd.state.quests["oil"].step = pd.steps_of(DepositKinds.OIL).size() - 1   # the walk is the gold quest's test
			_gold_before = Profile.data.survivor_gold
			pd.mark(DepositKinds.OIL)
			_check(Profile.data.survivor_gold == _gold_before + EarnRules.PROSPECT_QUEST_GOLD, "the oil quest pays through the wallet")
			_check(pd.wells.has(_deposit.id), "an oil well stands on the dome (%s m down)" % _deposit.get("depth_m"))
			pd.board.close()
			var well: OilWell = pd.wells[_deposit.id]
			p.spawn_at(well.position + OilWell.JACK_AT + Vector3(1.5, 1.0, 0))
			_next(0.5)
		14:
			var bag := Session.inventory_of(p.peer_id)
			if bag.count(BlockIds.CRUDE_OIL) < 1:
				if _step_t > 20.0:
					_check(false, "walking up to the pump jack fills a drum")
					_finish()
				return
			_check(true, "a drum of crude oil in the bag (%d left in the well)" % pd.state.drums_left(_deposit.id))
			var at := Vector3i(p.global_position.floor()) + Vector3i(2, 0, 0)
			p.world.set_block(at, BlockIds.REFINERY)
			_next(0.3)
		15:
			var bag := Session.inventory_of(p.peer_id)
			var near := Session.craft_stations_near(p.eye_position(), CraftRules.REACH)
			_check(bool(near.get(Recipes.REFINERY, false)), "the Refinery is near")
			var said := [""]
			Session.craft_done.connect(func(_ok: bool, text: String, _id: int, _n: int) -> void: said[0] = text, CONNECT_ONE_SHOT)
			Session.request_craft(&"kerosene")
			_check(bag.count(BlockIds.KEROSENE) == 1, "kerosene from the crude oil")
			_check(str(said[0]).contains("rockets"), "the refinery's fact: %s" % said[0])
			var wallet := Wallet.new(Profile.data.survivor_gold)
			var r := ShopRules.sell(BlockIds.KEROSENE, 1, wallet, bag, Game.universe)
			_check(bool(r.ok) and int(r.gold) == UniverseRules.price(RefiningRules.SELL[BlockIds.KEROSENE], Game.universe),
				"Tilly buys kerosene (%d gold)" % int(r.gold))
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
	print("PROSPECT_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("PROSPECT_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().paused = false
	Music.reset()
	Music.use_tracks({})
	var code := 1 if not _fails.is_empty() else 0
	get_tree().create_timer(0.3).timeout.connect(func() -> void: get_tree().quit(code))
